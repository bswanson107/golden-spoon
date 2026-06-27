-- Golden Spoon — QA processing across all active seasons + auto-trigger support
--
-- Makes p_season_year optional: when null, processing runs for every season that
-- has an active league. This lets the QA clock auto-run processing on every time
-- change (see qaClock.setQaClock) without the caller knowing the season, so any
-- closed week always ends up with a value for every member (their pick, the
-- auto-assigned MNF home team, or the missed indicator).

create or replace function public.qa_run_processing(p_season_year integer default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := public.qa_now();
  v_locks integer := 0;
  v_assigned integer := 0;
  v_seasons integer[];
  v_season integer;
  v_week record;
  v_member record;
  v_home_team text;
  v_status public.game_status;
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
    where is_active = true;
  end if;

  foreach v_season in array v_seasons loop
    -- 1) Kickoff win-% lock: refresh win %/underdog snapshot for still-pending
    --    picks whose game has kicked off (per the simulated clock).
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

    -- 2) For each closed week (last kickoff has passed), assign the MNF home team
    --    or a missed indicator to members who have no pick.
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
          -- MNF home team already used → record a true missed pick.
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
          -- Assign the MNF home team as a real, scoring auto pick.
          insert into public.picks (
            league_id, user_id, season_year, week_number, game_id, team_id, is_auto_pick
          )
          values (
            v_member.league_id, v_member.user_id, v_season, v_week.week,
            v_week.last_game_id, v_home_team, true
          );
        end if;

        v_assigned := v_assigned + 1;
      end loop;

      -- Resolve auto picks whose MNF game is already final.
      if v_status = 'final' then
        perform public.score_picks_for_game(v_week.last_game_id);
      end if;
    end loop;
  end loop;

  return jsonb_build_object(
    'kickoffLocksApplied', v_locks,
    'autoOrMissedAssigned', v_assigned
  );
end;
$$;

grant execute on function public.qa_run_processing(integer) to authenticated;
