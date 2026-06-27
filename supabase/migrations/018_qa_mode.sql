-- Golden Spoon — QA Mode: time travel + outcome/odds simulation
--
-- Adds an admin-controlled global clock (`qa_now()`) so pick deadlines and
-- pick visibility can be exercised at any minute, plus RPCs to simulate game
-- outcomes and override win % without running the live nflverse sync.
--
-- All QA RPCs are gated by public.is_app_admin() (migration 006). The clock
-- defaults to DISABLED, so live behavior is unchanged until an admin opts in.

-- ---------------------------------------------------------------------------
-- QA clock: single-row table + qa_now() resolver
-- ---------------------------------------------------------------------------
create table if not exists public.qa_clock (
  id integer primary key default 1,
  enabled boolean not null default false,
  simulated_now timestamptz,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id),
  constraint qa_clock_singleton check (id = 1)
);

insert into public.qa_clock (id, enabled, simulated_now)
values (1, false, null)
on conflict (id) do nothing;

alter table public.qa_clock enable row level security;

drop policy if exists "qa_clock_select_authenticated" on public.qa_clock;
create policy "qa_clock_select_authenticated"
  on public.qa_clock for select
  to authenticated
  using (true);

-- Resolver used by the pick trigger + RLS policies. Security definer so it can
-- read qa_clock regardless of the calling role / RLS context.
create or replace function public.qa_now()
returns timestamptz
language sql
stable
security definer
set search_path = public
as $$
  select case
    when c.enabled and c.simulated_now is not null then c.simulated_now
    else now()
  end
  from public.qa_clock c
  where c.id = 1;
$$;

grant execute on function public.qa_now() to authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- Swap now() -> qa_now() in pick deadline trigger (based on migration 011)
-- ---------------------------------------------------------------------------
create or replace function public.enforce_pick_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_game public.nfl_games;
  v_league public.leagues;
  v_threshold numeric;
  v_team_win_pct numeric;
begin
  if new.is_missed then
    if new.outcome is distinct from 'missed'::public.pick_outcome then
      new.outcome := 'missed';
    end if;
    new.points_awarded := 0;
    new.is_underdog_at_pick := false;
    if new.win_pct_at_pick is null then
      new.win_pct_at_pick := 50.0;
    end if;
    if new.team_season_wins_at_pick is null then
      new.team_season_wins_at_pick := 0;
    end if;
    return new;
  end if;

  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if new.user_id is null then
    new.user_id := auth.uid();
  end if;

  if new.user_id is distinct from auth.uid() then
    raise exception 'Cannot submit pick for another user';
  end if;

  select * into v_league from public.leagues where id = new.league_id;
  if not found then
    raise exception 'League not found';
  end if;

  if not public.is_league_member(new.league_id, new.user_id) then
    raise exception 'User is not a member of this league';
  end if;

  select * into v_game from public.nfl_games where id = new.game_id;
  if not found then
    raise exception 'Game not found';
  end if;

  if v_game.season_year <> v_league.season_year then
    raise exception 'Game season does not match league season';
  end if;

  if new.team_id not in (v_game.home_team_id, v_game.away_team_id) then
    raise exception 'Picked team must play in the selected game';
  end if;

  if tg_op in ('INSERT', 'UPDATE') and new.superseded_by_pick_id is null then
    if v_game.kickoff_at <= public.qa_now() then
      raise exception 'Pick deadline passed: game has already kicked off';
    end if;
    if v_game.status = 'postponed' and v_game.kickoff_at > public.qa_now() then
      null;
    elsif v_game.status not in ('scheduled', 'postponed') then
      raise exception 'Cannot pick for game in status %', v_game.status;
    end if;
  end if;

  v_threshold := v_league.underdog_threshold_pct;

  if new.team_id = v_game.home_team_id then
    v_team_win_pct := v_game.home_win_pct;
  else
    v_team_win_pct := v_game.away_win_pct;
  end if;

  if v_team_win_pct is null then
    v_team_win_pct := 50.0;
  end if;

  new.win_pct_at_pick := v_team_win_pct;
  new.is_underdog_at_pick := public.is_underdog(v_team_win_pct, v_threshold);
  new.season_year := v_game.season_year;
  new.week_number := v_game.week_number;

  select coalesce(str.wins, 0)
  into new.team_season_wins_at_pick
  from public.season_team_records str
  where str.season_year = v_game.season_year
    and str.team_id = new.team_id;

  if new.team_season_wins_at_pick is null then
    new.team_season_wins_at_pick := 0;
  end if;

  if tg_op = 'INSERT' then
    new.points_awarded := 0;
    new.outcome := 'pending';
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Swap now() -> qa_now() in pick RLS policies (visibility / update / delete)
-- ---------------------------------------------------------------------------

-- Visibility: open leagues see all; hidden leagues reveal at kickoff (017)
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
          and g.kickoff_at <= public.qa_now()
      )
    )
  );

-- Update own pick only before its game's kickoff (001)
drop policy if exists "picks_update_own_before_kickoff" on public.picks;
create policy "picks_update_own_before_kickoff"
  on public.picks for update
  using (
    user_id = auth.uid()
    and is_commissioner_override = false
    and exists (
      select 1 from public.nfl_games g
      where g.id = picks.game_id
        and g.kickoff_at > public.qa_now()
        and g.status in ('scheduled', 'postponed')
    )
  );

-- Delete own pick only before its game's kickoff (008)
drop policy if exists "picks_delete_own_before_kickoff" on public.picks;
create policy "picks_delete_own_before_kickoff"
  on public.picks for delete
  to authenticated
  using (
    user_id = auth.uid()
    and is_commissioner_override = false
    and superseded_by_pick_id is null
    and exists (
      select 1
      from public.nfl_games g
      where g.id = picks.game_id
        and g.kickoff_at > public.qa_now()
        and g.status in ('scheduled', 'postponed')
    )
  );

-- ---------------------------------------------------------------------------
-- Clock control RPCs (admin only)
-- ---------------------------------------------------------------------------
create or replace function public.qa_set_clock(p_now timestamptz)
returns public.qa_clock
language plpgsql
security definer
set search_path = public
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

  return v_row;
end;
$$;

create or replace function public.qa_clear_clock()
returns public.qa_clock
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.qa_clock;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  update public.qa_clock
  set enabled = false,
      simulated_now = null,
      updated_at = now(),
      updated_by = auth.uid()
  where id = 1
  returning * into v_row;

  return v_row;
end;
$$;

create or replace function public.qa_get_clock()
returns public.qa_clock
language sql
stable
security definer
set search_path = public
as $$
  select * from public.qa_clock where id = 1;
$$;

grant execute on function public.qa_set_clock(timestamptz) to authenticated;
grant execute on function public.qa_clear_clock() to authenticated;
grant execute on function public.qa_get_clock() to authenticated;

-- ---------------------------------------------------------------------------
-- Outcome / odds simulation RPCs (admin only)
-- ---------------------------------------------------------------------------

-- Internal: mark one game final with the given result. Fires the existing
-- nfl_games_score_picks trigger, which scores pending picks for the game.
-- p_result: 'home' | 'away' | 'tie'
create or replace function public.qa_apply_game_result(p_game_id uuid, p_result text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_game public.nfl_games;
  v_winner text;
  v_is_tie boolean := false;
  v_home_score integer;
  v_away_score integer;
begin
  select * into v_game from public.nfl_games where id = p_game_id;
  if not found then
    raise exception 'Game not found: %', p_game_id;
  end if;

  if p_result = 'home' then
    v_winner := v_game.home_team_id;
    v_home_score := 24;
    v_away_score := 17;
  elsif p_result = 'away' then
    v_winner := v_game.away_team_id;
    v_home_score := 17;
    v_away_score := 24;
  elsif p_result = 'tie' then
    v_winner := null;
    v_is_tie := true;
    v_home_score := 20;
    v_away_score := 20;
  else
    raise exception 'Invalid result %; expected home, away, or tie', p_result;
  end if;

  update public.nfl_games
  set status = 'final',
      home_score = v_home_score,
      away_score = v_away_score,
      winner_team_id = v_winner,
      is_tie = v_is_tie,
      updated_at = now()
  where id = p_game_id;
end;
$$;

-- Simulate every game in a week with a single default result (default: home wins).
create or replace function public.qa_simulate_week(
  p_season_year integer,
  p_week_number integer,
  p_result text default 'home'
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_game_id uuid;
  v_count integer := 0;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  for v_game_id in
    select id from public.nfl_games
    where season_year = p_season_year
      and week_number = p_week_number
    order by kickoff_at
  loop
    perform public.qa_apply_game_result(v_game_id, p_result);
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- Override a single game's result.
create or replace function public.qa_set_game_result(p_game_id uuid, p_result text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  perform public.qa_apply_game_result(p_game_id, p_result);
end;
$$;

-- Override a game's win % (drives underdog classification at kickoff lock).
create or replace function public.qa_set_game_winpct(
  p_game_id uuid,
  p_home_win_pct numeric,
  p_away_win_pct numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  update public.nfl_games
  set home_win_pct = p_home_win_pct,
      away_win_pct = p_away_win_pct,
      win_pct_source = 'qa',
      win_pct_updated_at = now(),
      updated_at = now()
  where id = p_game_id;

  if not found then
    raise exception 'Game not found: %', p_game_id;
  end if;
end;
$$;

-- Reset a week back to "not played": games scheduled, scores cleared, and
-- non-override picks returned to pending so the week can be re-simulated.
-- Also removes auto-generated missed picks for the scope.
create or replace function public.qa_reset_week(
  p_season_year integer,
  p_week_number integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  update public.nfl_games
  set status = 'scheduled',
      home_score = null,
      away_score = null,
      winner_team_id = null,
      is_tie = false,
      updated_at = now()
  where season_year = p_season_year
    and week_number = p_week_number;

  delete from public.picks
  where season_year = p_season_year
    and week_number = p_week_number
    and is_missed = true;

  update public.picks
  set outcome = 'pending',
      points_awarded = 0,
      updated_at = now()
  where season_year = p_season_year
    and week_number = p_week_number
    and is_missed = false
    and is_commissioner_override = false
    and superseded_by_pick_id is null
    and outcome <> 'pending';
end;
$$;

-- Reset an entire season (all regular-season weeks).
create or replace function public.qa_reset_all(p_season_year integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_week integer;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  for v_week in
    select distinct week_number from public.nfl_games
    where season_year = p_season_year
    order by week_number
  loop
    perform public.qa_reset_week(p_season_year, v_week);
  end loop;
end;
$$;

grant execute on function public.qa_simulate_week(integer, integer, text) to authenticated;
grant execute on function public.qa_set_game_result(uuid, text) to authenticated;
grant execute on function public.qa_set_game_winpct(uuid, numeric, numeric) to authenticated;
grant execute on function public.qa_reset_week(integer, integer) to authenticated;
grant execute on function public.qa_reset_all(integer) to authenticated;
-- qa_apply_game_result is internal (called by other security-definer RPCs)
revoke execute on function public.qa_apply_game_result(uuid, text) from public;
