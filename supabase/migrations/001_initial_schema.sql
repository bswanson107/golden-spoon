-- Golden Spoon — initial schema (paste into Supabase SQL Editor)
-- Run as a single script. Safe to re-run only on a fresh project; drops are not included.
--
-- Encodes: docs/mvp-rules.md
--   • No team reuse per user per league season
--   • One entry per user per league
--   • Pick locks at picked team's kickoff; missed week = 0 (commissioner can override)
--   • Picks hidden from others until that game's kickoff
--   • Win % at kickoff (≤33% = underdog → 2 pts on win); 1 pt favorite win; 0.5 tie; 0 loss
--   • Standings tiebreaker: lower sum of picked teams' season wins at pick time
--   • Regular season weeks only; repick allowed after postpone until new kickoff

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.game_status as enum (
  'scheduled',
  'in_progress',
  'final',
  'postponed',
  'cancelled'
);

create type public.pick_outcome as enum (
  'pending',
  'win',
  'loss',
  'tie',
  'missed',
  'void'
);

create type public.week_phase as enum (
  'regular',
  'postseason'
);

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users) — table already exists from setup
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists avatar_url text;

alter table public.profiles
  add column if not exists updated_at timestamptz not null default now();

-- Remove starter policies from exploration if present (replaced below)
drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

-- ---------------------------------------------------------------------------
-- NFL reference data
-- ---------------------------------------------------------------------------
create table public.nfl_teams (
  id text primary key,
  espn_team_id integer unique,
  abbreviation text not null,
  name text not null,
  city text,
  conference text,
  division text,
  created_at timestamptz not null default now()
);

-- Season win totals (sync from API; used for tiebreaker snapshot on pick)
create table public.season_team_records (
  season_year integer not null,
  team_id text not null references public.nfl_teams (id),
  wins integer not null default 0,
  losses integer not null default 0,
  ties integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (season_year, team_id)
);

-- ---------------------------------------------------------------------------
-- Leagues & membership
-- ---------------------------------------------------------------------------
create table public.leagues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  season_year integer not null,
  commissioner_id uuid not null references public.profiles (id),
  invite_code text unique default encode(gen_random_bytes(6), 'hex'),
  underdog_threshold_pct numeric(5, 2) not null default 33.00,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint leagues_underdog_threshold_range
    check (underdog_threshold_pct > 0 and underdog_threshold_pct <= 100)
);

create table public.league_members (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (league_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Schedule: weeks & games
-- ---------------------------------------------------------------------------
create table public.nfl_weeks (
  season_year integer not null,
  week_number integer not null,
  phase public.week_phase not null default 'regular',
  label text,
  final_game_kickoff_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (season_year, week_number),
  constraint nfl_weeks_week_number_positive check (week_number > 0)
);

create table public.nfl_games (
  id uuid primary key default gen_random_uuid(),
  season_year integer not null,
  week_number integer not null,
  home_team_id text not null references public.nfl_teams (id),
  away_team_id text not null references public.nfl_teams (id),
  kickoff_at timestamptz not null,
  status public.game_status not null default 'scheduled',
  home_score integer,
  away_score integer,
  is_tie boolean not null default false,
  winner_team_id text references public.nfl_teams (id),
  home_win_pct numeric(5, 2),
  away_win_pct numeric(5, 2),
  win_pct_source text,
  win_pct_updated_at timestamptz,
  espn_event_id text unique,
  postponed_from_game_id uuid references public.nfl_games (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (season_year, week_number)
    references public.nfl_weeks (season_year, week_number),
  constraint nfl_games_different_teams check (home_team_id <> away_team_id),
  constraint nfl_games_win_pct_range
    check (
      (home_win_pct is null or (home_win_pct >= 0 and home_win_pct <= 100))
      and (away_win_pct is null or (away_win_pct >= 0 and away_win_pct <= 100))
    )
);

create index nfl_games_season_week_idx on public.nfl_games (season_year, week_number);
create index nfl_games_kickoff_idx on public.nfl_games (kickoff_at);
create index nfl_games_status_idx on public.nfl_games (status);

-- ---------------------------------------------------------------------------
-- Picks
-- ---------------------------------------------------------------------------
create table public.picks (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  season_year integer not null,
  week_number integer not null,
  game_id uuid not null references public.nfl_games (id),
  team_id text not null references public.nfl_teams (id),
  submitted_at timestamptz not null default now(),
  win_pct_at_pick numeric(5, 2) not null,
  is_underdog_at_pick boolean not null,
  team_season_wins_at_pick integer not null default 0,
  outcome public.pick_outcome not null default 'pending',
  points_awarded numeric(3, 1) not null default 0,
  is_commissioner_override boolean not null default false,
  override_notes text,
  superseded_by_pick_id uuid references public.picks (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (league_id, user_id)
    references public.league_members (league_id, user_id),
  foreign key (season_year, week_number)
    references public.nfl_weeks (season_year, week_number),
  constraint picks_win_pct_range
    check (win_pct_at_pick >= 0 and win_pct_at_pick <= 100),
  constraint picks_points_non_negative check (points_awarded >= 0)
);

-- One active pick per member per week
create unique index picks_one_active_per_week_idx
  on public.picks (league_id, user_id, season_year, week_number)
  where (superseded_by_pick_id is null);

-- No team reuse per member per league season (active picks only)
create unique index picks_no_team_reuse_idx
  on public.picks (league_id, user_id, season_year, team_id)
  where (superseded_by_pick_id is null);

create index picks_league_user_idx on public.picks (league_id, user_id);
create index picks_game_idx on public.picks (game_id);

-- ---------------------------------------------------------------------------
-- Commissioner audit log
-- ---------------------------------------------------------------------------
create table public.commissioner_actions (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues (id) on delete cascade,
  actor_id uuid not null references public.profiles (id),
  action_type text not null,
  target_pick_id uuid references public.picks (id),
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function public.is_league_member(p_league_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.league_members lm
    where lm.league_id = p_league_id
      and lm.user_id = p_user_id
  );
$$;

create or replace function public.is_league_commissioner(p_league_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
      and l.commissioner_id = p_user_id
  );
$$;

create or replace function public.is_underdog(
  p_win_pct numeric,
  p_threshold numeric default 33.00
)
returns boolean
language sql
immutable
as $$
  select p_win_pct <= p_threshold;
$$;

create or replace function public.points_for_pick_result(
  p_outcome public.pick_outcome,
  p_is_underdog boolean
)
returns numeric
language sql
immutable
as $$
  select case p_outcome
    when 'win' then case when p_is_underdog then 2.0 else 1.0 end
    when 'tie' then 0.5
    when 'loss' then 0.0
    when 'missed' then 0.0
    when 'void' then 0.0
    else 0.0
  end;
$$;

-- Resolve outcome from final game + picked team
create or replace function public.resolve_pick_outcome(
  p_team_id text,
  p_game public.nfl_games
)
returns public.pick_outcome
language plpgsql
stable
as $$
begin
  if p_game.status = 'cancelled' then
    return 'void';
  end if;
  if p_game.status <> 'final' then
    return 'pending';
  end if;
  if p_game.is_tie then
    return 'tie';
  end if;
  if p_game.winner_team_id = p_team_id then
    return 'win';
  end if;
  return 'loss';
end;
$$;

-- Apply game result to all pending picks for that game
create or replace function public.score_picks_for_game(p_game_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_game public.nfl_games;
  v_updated integer := 0;
begin
  select * into v_game from public.nfl_games where id = p_game_id;
  if not found or v_game.status <> 'final' then
    return 0;
  end if;

  update public.picks p
  set
    outcome = public.resolve_pick_outcome(p.team_id, v_game),
    points_awarded = public.points_for_pick_result(
      public.resolve_pick_outcome(p.team_id, v_game),
      p.is_underdog_at_pick
    ),
    updated_at = now()
  where p.game_id = p_game_id
    and p.superseded_by_pick_id is null
    and p.outcome = 'pending'
    and p.is_commissioner_override = false;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

-- Standings view (points desc, tiebreaker asc = fewer picked-team wins wins tie)
create or replace view public.league_standings as
select
  lm.league_id,
  lm.user_id,
  p.display_name,
  coalesce(sum(pk.points_awarded), 0)::numeric(6, 1) as total_points,
  coalesce(
    sum(pk.team_season_wins_at_pick) filter (where pk.superseded_by_pick_id is null),
    0
  )::integer as tiebreaker_picked_team_wins,
  count(pk.id) filter (
    where pk.superseded_by_pick_id is null and pk.outcome = 'pending'
  )::integer as pending_picks
from public.league_members lm
join public.profiles p on p.id = lm.user_id
left join public.picks pk
  on pk.league_id = lm.league_id
  and pk.user_id = lm.user_id
  and pk.superseded_by_pick_id is null
group by lm.league_id, lm.user_id, p.display_name;

-- Ranked standings (use in app: order by total_points desc, tiebreaker asc)
create or replace view public.league_standings_ranked as
select
  ls.*,
  rank() over (
    partition by ls.league_id
    order by ls.total_points desc, ls.tiebreaker_picked_team_wins asc, ls.user_id
  ) as standing_rank
from public.league_standings ls;

-- Callable from app; bypasses pick RLS for aggregates only (not pick details)
create or replace function public.get_league_standings(p_league_id uuid)
returns table (
  user_id uuid,
  display_name text,
  total_points numeric,
  tiebreaker_picked_team_wins integer,
  pending_picks integer,
  standing_rank bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    lsr.user_id,
    lsr.display_name,
    lsr.total_points,
    lsr.tiebreaker_picked_team_wins,
    lsr.pending_picks,
    lsr.standing_rank
  from public.league_standings_ranked lsr
  where lsr.league_id = p_league_id
    and public.is_league_member(p_league_id);
$$;

-- Commissioner: override pick outcome/points (missed pick, API correction)
create or replace function public.commissioner_override_pick(
  p_pick_id uuid,
  p_outcome public.pick_outcome,
  p_points numeric,
  p_notes text default null
)
returns public.picks
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pick public.picks;
begin
  select * into v_pick from public.picks where id = p_pick_id;
  if not found then
    raise exception 'Pick not found';
  end if;

  if not public.is_league_commissioner(v_pick.league_id) then
    raise exception 'Only the league commissioner can override picks';
  end if;

  update public.picks
  set
    outcome = p_outcome,
    points_awarded = p_points,
    is_commissioner_override = true,
    override_notes = p_notes,
    updated_at = now()
  where id = p_pick_id
  returning * into v_pick;

  insert into public.commissioner_actions (league_id, actor_id, action_type, target_pick_id, payload)
  values (
    v_pick.league_id,
    auth.uid(),
    'override_pick',
    p_pick_id,
    jsonb_build_object(
      'outcome', p_outcome,
      'points_awarded', p_points,
      'notes', p_notes
    )
  );

  return v_pick;
end;
$$;

-- Repick after postpone: mark old pick superseded, insert new pick in app
create or replace function public.supersede_pick_for_repick(p_pick_id uuid)
returns public.picks
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old public.picks;
  v_game public.nfl_games;
begin
  select * into v_old from public.picks where id = p_pick_id;
  if not found then
    raise exception 'Pick not found';
  end if;

  if v_old.user_id <> auth.uid() and not public.is_league_commissioner(v_old.league_id) then
    raise exception 'Not allowed to supersede this pick';
  end if;

  select * into v_game from public.nfl_games where id = v_old.game_id;
  if v_game.status <> 'postponed' then
    raise exception 'Repick only allowed when game status is postponed';
  end if;

  update public.picks
  set
    outcome = 'void',
    points_awarded = 0,
    updated_at = now()
  where id = p_pick_id
  returning * into v_old;

  return v_old;
end;
$$;

-- ---------------------------------------------------------------------------
-- Pick validation trigger
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
    if v_game.kickoff_at <= now() then
      raise exception 'Pick deadline passed: game has already kicked off';
    end if;
    if v_game.status = 'postponed' and v_game.kickoff_at > now() then
      null; -- allow repick while postponed and before new kickoff
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
    raise exception 'Win %% not available for picked team; sync game odds before picking';
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

create trigger picks_enforce_rules
  before insert or update on public.picks
  for each row
  execute function public.enforce_pick_rules();

-- Re-score picks when game is marked final
create or replace function public.on_game_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'final' and (old.status is distinct from new.status) then
    perform public.score_picks_for_game(new.id);
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger nfl_games_score_picks
  after update of status, winner_team_id, is_tie on public.nfl_games
  for each row
  execute function public.on_game_status_change();

-- Auto-profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- updated_at touch
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger leagues_set_updated_at
  before update on public.leagues
  for each row execute function public.set_updated_at();

create trigger picks_set_updated_at
  before update on public.picks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.nfl_teams enable row level security;
alter table public.season_team_records enable row level security;
alter table public.leagues enable row level security;
alter table public.league_members enable row level security;
alter table public.nfl_weeks enable row level security;
alter table public.nfl_games enable row level security;
alter table public.picks enable row level security;
alter table public.commissioner_actions enable row level security;

-- Profiles
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_league_mates" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_select_league_mates"
  on public.profiles for select
  using (
    exists (
      select 1
      from public.league_members me
      join public.league_members them on them.league_id = me.league_id
      where me.user_id = auth.uid()
        and them.user_id = profiles.id
    )
  );

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

-- Reference tables: readable by authenticated users
create policy "nfl_teams_select_authenticated"
  on public.nfl_teams for select
  to authenticated
  using (true);

create policy "season_team_records_select_authenticated"
  on public.season_team_records for select
  to authenticated
  using (true);

-- Leagues
create policy "leagues_select_members"
  on public.leagues for select
  using (public.is_league_member(id));

create policy "leagues_insert_authenticated"
  on public.leagues for insert
  to authenticated
  with check (commissioner_id = auth.uid());

create policy "leagues_update_commissioner"
  on public.leagues for update
  using (public.is_league_commissioner(id));

-- League members
create policy "league_members_select_same_league"
  on public.league_members for select
  using (public.is_league_member(league_id));

create policy "league_members_insert_self"
  on public.league_members for insert
  to authenticated
  with check (user_id = auth.uid());

-- Schedule (regular season weeks/games visible to authenticated; app filters postseason)
create policy "nfl_weeks_select_authenticated"
  on public.nfl_weeks for select
  to authenticated
  using (phase = 'regular');

create policy "nfl_games_select_authenticated"
  on public.nfl_games for select
  to authenticated
  using (
    exists (
      select 1 from public.nfl_weeks w
      where w.season_year = nfl_games.season_year
        and w.week_number = nfl_games.week_number
        and w.phase = 'regular'
    )
  );

-- Picks: own always; others only after picked game's kickoff
create policy "picks_select_own"
  on public.picks for select
  using (user_id = auth.uid());

create policy "picks_select_league_after_kickoff"
  on public.picks for select
  using (
    public.is_league_member(league_id)
    and exists (
      select 1
      from public.nfl_games g
      where g.id = picks.game_id
        and g.kickoff_at <= now()
    )
  );

create policy "picks_insert_own"
  on public.picks for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.is_league_member(league_id)
  );

create policy "picks_update_own_before_kickoff"
  on public.picks for update
  using (
    user_id = auth.uid()
    and is_commissioner_override = false
    and exists (
      select 1 from public.nfl_games g
      where g.id = picks.game_id
        and g.kickoff_at > now()
        and g.status in ('scheduled', 'postponed')
    )
  );

create policy "picks_update_commissioner"
  on public.picks for update
  using (public.is_league_commissioner(league_id));

-- Commissioner actions
create policy "commissioner_actions_select_members"
  on public.commissioner_actions for select
  using (public.is_league_member(league_id));

create policy "commissioner_actions_insert_commissioner"
  on public.commissioner_actions for insert
  with check (public.is_league_commissioner(league_id) and actor_id = auth.uid());

grant execute on function public.get_league_standings(uuid) to authenticated;
grant execute on function public.commissioner_override_pick(uuid, public.pick_outcome, numeric, text) to authenticated;
grant execute on function public.supersede_pick_for_repick(uuid) to authenticated;
grant execute on function public.score_picks_for_game(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Seed: 32 NFL teams (abbreviations as ids — adjust espn_team_id when syncing)
-- ---------------------------------------------------------------------------
insert into public.nfl_teams (id, abbreviation, name, city, conference, division) values
  ('ARI', 'ARI', 'Cardinals', 'Arizona', 'NFC', 'West'),
  ('ATL', 'ATL', 'Falcons', 'Atlanta', 'NFC', 'South'),
  ('BAL', 'BAL', 'Ravens', 'Baltimore', 'AFC', 'North'),
  ('BUF', 'BUF', 'Bills', 'Buffalo', 'AFC', 'East'),
  ('CAR', 'CAR', 'Panthers', 'Carolina', 'NFC', 'South'),
  ('CHI', 'CHI', 'Bears', 'Chicago', 'NFC', 'North'),
  ('CIN', 'CIN', 'Bengals', 'Cincinnati', 'AFC', 'North'),
  ('CLE', 'CLE', 'Browns', 'Cleveland', 'AFC', 'North'),
  ('DAL', 'DAL', 'Cowboys', 'Dallas', 'NFC', 'East'),
  ('DEN', 'DEN', 'Broncos', 'Denver', 'AFC', 'West'),
  ('DET', 'DET', 'Lions', 'Detroit', 'NFC', 'North'),
  ('GB',  'GB',  'Packers', 'Green Bay', 'NFC', 'North'),
  ('HOU', 'HOU', 'Texans', 'Houston', 'AFC', 'South'),
  ('IND', 'IND', 'Colts', 'Indianapolis', 'AFC', 'South'),
  ('JAX', 'JAX', 'Jaguars', 'Jacksonville', 'AFC', 'South'),
  ('KC',  'KC',  'Chiefs', 'Kansas City', 'AFC', 'West'),
  ('LAC', 'LAC', 'Chargers', 'Los Angeles', 'AFC', 'West'),
  ('LAR', 'LAR', 'Rams', 'Los Angeles', 'NFC', 'West'),
  ('LV',  'LV',  'Raiders', 'Las Vegas', 'AFC', 'West'),
  ('MIA', 'MIA', 'Dolphins', 'Miami', 'AFC', 'East'),
  ('MIN', 'MIN', 'Vikings', 'Minnesota', 'NFC', 'North'),
  ('NE',  'NE',  'Patriots', 'New England', 'AFC', 'East'),
  ('NO',  'NO',  'Saints', 'New Orleans', 'NFC', 'South'),
  ('NYG', 'NYG', 'Giants', 'New York', 'NFC', 'East'),
  ('NYJ', 'NYJ', 'Jets', 'New York', 'AFC', 'East'),
  ('PHI', 'PHI', 'Eagles', 'Philadelphia', 'NFC', 'East'),
  ('PIT', 'PIT', 'Steelers', 'Pittsburgh', 'AFC', 'North'),
  ('SEA', 'SEA', 'Seahawks', 'Seattle', 'NFC', 'West'),
  ('SF',  'SF',  '49ers', 'San Francisco', 'NFC', 'West'),
  ('TB',  'TB',  'Buccaneers', 'Tampa Bay', 'NFC', 'South'),
  ('TEN', 'TEN', 'Titans', 'Tennessee', 'AFC', 'South'),
  ('WAS', 'WAS', 'Commanders', 'Washington', 'NFC', 'East')
on conflict (id) do nothing;
