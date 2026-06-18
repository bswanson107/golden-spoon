-- Configurable league rules (v1): underdog threshold, tiebreaker mode, pick visibility

create type public.tiebreaker_mode as enum ('fewest_wins', 'most_wins');
create type public.pick_visibility as enum ('hidden_until_kickoff', 'open');

alter table public.leagues
  add column if not exists tiebreaker_mode public.tiebreaker_mode not null default 'fewest_wins',
  add column if not exists pick_visibility public.pick_visibility not null default 'hidden_until_kickoff';

-- Ranked standings respect league tiebreaker mode
create or replace view public.league_standings_ranked as
select
  ls.*,
  rank() over (
    partition by ls.league_id
    order by
      ls.total_points desc,
      case
        when l.tiebreaker_mode = 'most_wins' then ls.tiebreaker_picked_team_wins
        else -ls.tiebreaker_picked_team_wins
      end desc,
      ls.user_id
  ) as standing_rank
from public.league_standings ls
join public.leagues l on l.id = ls.league_id;

-- Open leagues: members see all picks immediately; hidden leagues keep kickoff gate
drop policy if exists "picks_select_league_after_kickoff" on public.picks;
create policy "picks_select_league_after_kickoff"
  on public.picks for select
  using (
    public.is_league_member(league_id)
    and (
      exists (
        select 1
        from public.leagues l
        where l.id = picks.league_id
          and l.pick_visibility = 'open'
      )
      or exists (
        select 1
        from public.nfl_games g
        where g.id = picks.game_id
          and g.kickoff_at <= now()
      )
    )
  );

create or replace function public.league_has_started_picking(p_league_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.picks p
    where p.league_id = p_league_id
      and p.superseded_by_pick_id is null
  );
$$;

drop function if exists public.create_league(text, integer);

create or replace function public.create_league(
  p_name text,
  p_season_year integer,
  p_underdog_threshold_pct numeric default 33.00,
  p_tiebreaker_mode public.tiebreaker_mode default 'fewest_wins',
  p_pick_visibility public.pick_visibility default 'hidden_until_kickoff'
)
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league public.leagues;
  v_name text := trim(p_name);
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if v_name is null or v_name = '' then
    raise exception 'League name is required';
  end if;

  if p_underdog_threshold_pct < 0 or p_underdog_threshold_pct > 100 then
    raise exception 'Underdog threshold must be between 0 and 100';
  end if;

  perform public.ensure_profile();

  insert into public.leagues (
    name,
    season_year,
    commissioner_id,
    underdog_threshold_pct,
    tiebreaker_mode,
    pick_visibility
  )
  values (
    v_name,
    p_season_year,
    auth.uid(),
    p_underdog_threshold_pct,
    p_tiebreaker_mode,
    p_pick_visibility
  )
  returning * into v_league;

  insert into public.league_members (league_id, user_id)
  values (v_league.id, auth.uid())
  on conflict (league_id, user_id) do nothing;

  return v_league;
end;
$$;

create or replace function public.update_league_rules(
  p_league_id uuid,
  p_underdog_threshold_pct numeric,
  p_tiebreaker_mode public.tiebreaker_mode,
  p_pick_visibility public.pick_visibility
)
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league public.leagues;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_underdog_threshold_pct < 0 or p_underdog_threshold_pct > 100 then
    raise exception 'Underdog threshold must be between 0 and 100';
  end if;

  if not exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
      and l.commissioner_id = auth.uid()
  ) then
    raise exception 'Only the commissioner can update league rules';
  end if;

  if public.league_has_started_picking(p_league_id) then
    raise exception 'Rules are locked after the first pick is submitted';
  end if;

  update public.leagues
  set
    underdog_threshold_pct = p_underdog_threshold_pct,
    tiebreaker_mode = p_tiebreaker_mode,
    pick_visibility = p_pick_visibility
  where id = p_league_id
  returning * into v_league;

  return v_league;
end;
$$;

grant execute on function public.league_has_started_picking(uuid) to authenticated;
grant execute on function public.create_league(text, integer, numeric, public.tiebreaker_mode, public.pick_visibility) to authenticated;
grant execute on function public.update_league_rules(uuid, numeric, public.tiebreaker_mode, public.pick_visibility) to authenticated;
