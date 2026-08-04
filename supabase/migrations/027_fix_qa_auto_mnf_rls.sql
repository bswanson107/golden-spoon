-- Golden Spoon — fix QA auto-MNF assignment for other members
--
-- qa_run_processing inserts picks on behalf of every member without a pick.
-- Without `row_security = off`, RLS `picks_insert_own` (user_id = auth.uid())
-- blocks those inserts for anyone except the admin running QA. The RPC then
-- errors, the client swallowed the error, and missed pickers stayed empty.
--
-- Also skip public demo leagues (historical seed — don't auto-fill joiners)
-- and isolate per-member failures so one bad row cannot roll back the week.

create or replace function public.qa_run_processing(p_season_year integer default null)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_now timestamptz := public.qa_now();
  v_locks integer := 0;
  v_assigned integer := 0;
  v_errors integer := 0;
  v_seasons integer[];
  v_season integer;
  v_week record;
  v_member record;
  v_home_team text;
  v_status public.game_status;
  v_err text;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  if p_season_year is not null then
    v_seasons := array[p_season_year];
  else
    select coalesce(array_agg(distinct season_year), '{}')
    into v_seasons
    from public.leagues
    where is_active = true
      and coalesce(is_public_demo, false) = false;
  end if;

  foreach v_season in array v_seasons loop
    -- 1) Kickoff win-% lock
    with upd as (
      update public.picks p
      set win_pct_at_pick = case
            when p.team_id = g.home_team_id then g.home_win_pct
            else g.away_win_pct
          end,
          is_underdog_at_pick = public.is_underdog(
            case when p.team_id = g.home_team_id then g.home_win_pct else g.away_win_pct end,
            l.underdog_threshold_pct
          ),
          updated_at = now()
      from public.nfl_games g, public.leagues l
      where p.game_id = g.id
        and p.league_id = l.id
        and p.season_year = v_season
        and p.outcome = 'pending'
        and p.is_commissioner_override = false
        and p.is_missed = false
        and p.superseded_by_pick_id is null
        and g.kickoff_at <= v_now
        and (case when p.team_id = g.home_team_id then g.home_win_pct else g.away_win_pct end) is not null
      returning 1
    )
    select v_locks + count(*) into v_locks from upd;

    -- 2) Closed weeks (last kickoff — typically MNF — has passed): assign MNF
    --    home team or missed indicator to members with no active pick.
    for v_week in
      select g.week_number as week,
             (array_agg(g.id order by g.kickoff_at desc))[1] as last_game_id
      from public.nfl_games g
      where g.season_year = v_season
      group by g.week_number
      having max(g.kickoff_at) <= v_now
      order by g.week_number
    loop
      select home_team_id, status
      into v_home_team, v_status
      from public.nfl_games
      where id = v_week.last_game_id;

      for v_member in
        select lm.league_id, lm.user_id
        from public.league_members lm
        join public.leagues l on l.id = lm.league_id
        where l.season_year = v_season
          and l.is_active = true
          and coalesce(l.is_public_demo, false) = false
          and not exists (
            select 1
            from public.picks p
            where p.league_id = lm.league_id
              and p.user_id = lm.user_id
              and p.season_year = v_season
              and p.week_number = v_week.week
              and p.superseded_by_pick_id is null
          )
      loop
        begin
          if exists (
            select 1
            from public.picks p
            where p.league_id = v_member.league_id
              and p.user_id = v_member.user_id
              and p.season_year = v_season
              and p.team_id = v_home_team
              and p.superseded_by_pick_id is null
              and p.is_missed = false
          ) then
            insert into public.picks (
              league_id, user_id, season_year, week_number, game_id, team_id,
              outcome, points_awarded, win_pct_at_pick, is_underdog_at_pick,
              team_season_wins_at_pick, is_missed
            )
            values (
              v_member.league_id, v_member.user_id, v_season, v_week.week,
              v_week.last_game_id, v_home_team, 'missed', 0, 50, false, 0, true
            );
          else
            insert into public.picks (
              league_id, user_id, season_year, week_number, game_id, team_id, is_auto_pick
            )
            values (
              v_member.league_id, v_member.user_id, v_season, v_week.week,
              v_week.last_game_id, v_home_team, true
            );
          end if;

          v_assigned := v_assigned + 1;
        exception when others then
          v_errors := v_errors + 1;
          v_err := SQLERRM;
          raise warning 'qa_run_processing assign failed league=% user=% week=%: %',
            v_member.league_id, v_member.user_id, v_week.week, v_err;
        end;
      end loop;

      if v_status = 'final' then
        perform public.score_picks_for_game(v_week.last_game_id);
      end if;
    end loop;
  end loop;

  return jsonb_build_object(
    'kickoffLocksApplied', v_locks,
    'autoOrMissedAssigned', v_assigned,
    'assignErrors', v_errors
  );
end;
$$;

grant execute on function public.qa_run_processing(integer) to authenticated;

-- Run processing whenever the QA clock is set so closed weeks always fill
-- even if the client never calls qa_run_processing separately.
create or replace function public.qa_set_clock(p_now timestamptz)
returns public.qa_clock
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_row public.qa_clock;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  update public.qa_clock
  set enabled = true,
      simulated_now = p_now,
      updated_at = now(),
      updated_by = auth.uid()
  where id = 1
  returning * into v_row;

  begin
    perform public.qa_run_processing(null);
  exception when others then
    raise warning 'qa_set_clock: qa_run_processing failed: %', SQLERRM;
  end;

  return v_row;
end;
$$;
