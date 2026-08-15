-- Allow signed-out visitors to browse public demo leagues (read-only).
-- Private leagues stay authenticated-only.

grant execute on function public.is_league_member(uuid, uuid) to anon, authenticated;
grant execute on function public.can_view_league(uuid, uuid) to anon, authenticated;

drop policy if exists "leagues_select_public_demo" on public.leagues;
create policy "leagues_select_public_demo"
  on public.leagues for select
  to anon, authenticated
  using (is_public_demo = true and is_active = true);

drop policy if exists "profiles_select_public_demo_members" on public.profiles;
create policy "profiles_select_public_demo_members"
  on public.profiles for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.league_members lm
      join public.leagues l on l.id = lm.league_id
      where lm.user_id = profiles.id
        and l.is_public_demo = true
        and l.is_active = true
    )
  );

drop policy if exists "nfl_teams_select_authenticated" on public.nfl_teams;
create policy "nfl_teams_select_authenticated"
  on public.nfl_teams for select
  to anon, authenticated
  using (true);

drop policy if exists "nfl_weeks_select_authenticated" on public.nfl_weeks;
create policy "nfl_weeks_select_authenticated"
  on public.nfl_weeks for select
  to anon, authenticated
  using (phase = 'regular');

drop policy if exists "nfl_games_select_authenticated" on public.nfl_games;
create policy "nfl_games_select_authenticated"
  on public.nfl_games for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.nfl_weeks w
      where w.season_year = nfl_games.season_year
        and w.week_number = nfl_games.week_number
        and w.phase = 'regular'
    )
  );

grant execute on function public.get_league_standings(uuid) to anon, authenticated;

create or replace function public.get_league_pick_submissions(p_league_id uuid)
returns table (
  user_id uuid,
  week_number integer,
  status text
)
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
begin
  if not public.can_view_league(p_league_id) then
    raise exception 'Not a league member';
  end if;

  return query
  select
    p.user_id,
    p.week_number,
    case when p.is_missed then 'missed' else 'submitted' end as status
  from public.picks p
  where p.league_id = p_league_id
    and p.superseded_by_pick_id is null;
end;
$$;

grant execute on function public.get_league_pick_submissions(uuid) to anon, authenticated;

create or replace function public.league_week_pick_status(
  p_league_id uuid,
  p_week_number integer
)
returns table (
  user_id uuid,
  status text
)
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
begin
  if not public.can_view_league(p_league_id) then
    raise exception 'Not a league member';
  end if;

  return query
  select
    p.user_id,
    case when p.is_missed then 'missed' else 'submitted' end as status
  from public.picks p
  where p.league_id = p_league_id
    and p.week_number = p_week_number
    and p.superseded_by_pick_id is null;
end;
$$;

grant execute on function public.league_week_pick_status(uuid, integer) to anon, authenticated;
