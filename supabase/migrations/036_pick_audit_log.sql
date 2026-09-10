-- Pick audit log: append-only history of every pick selection, change, and clear.
-- App admin can browse per league via admin_list_pick_audit_log.

create table public.pick_audit_log (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  pick_id uuid references public.picks (id) on delete set null,
  season_year integer not null,
  week_number integer not null,
  action text not null check (action in ('picked', 'changed', 'cleared')),
  team_id text references public.nfl_teams (id),
  previous_team_id text references public.nfl_teams (id),
  game_id uuid references public.nfl_games (id),
  created_at timestamptz not null default now()
);

create index pick_audit_log_league_created_idx
  on public.pick_audit_log (league_id, created_at desc);

create index pick_audit_log_league_week_idx
  on public.pick_audit_log (league_id, week_number, created_at desc);

alter table public.pick_audit_log enable row level security;

-- ---------------------------------------------------------------------------
-- Triggers: log pick, change, clear
-- ---------------------------------------------------------------------------
create or replace function public.log_pick_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.pick_audit_log (
      league_id,
      user_id,
      pick_id,
      season_year,
      week_number,
      action,
      team_id,
      game_id,
      created_at
    )
    values (
      new.league_id,
      new.user_id,
      new.id,
      new.season_year,
      new.week_number,
      'picked',
      new.team_id,
      new.game_id,
      coalesce(new.submitted_at, now())
    );
    return new;
  elsif tg_op = 'UPDATE' then
    if (new.team_id is distinct from old.team_id)
      or (new.game_id is distinct from old.game_id) then
      insert into public.pick_audit_log (
        league_id,
        user_id,
        pick_id,
        season_year,
        week_number,
        action,
        team_id,
        previous_team_id,
        game_id,
        created_at
      )
      values (
        new.league_id,
        new.user_id,
        new.id,
        new.season_year,
        new.week_number,
        'changed',
        new.team_id,
        old.team_id,
        new.game_id,
        now()
      );
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    insert into public.pick_audit_log (
      league_id,
      user_id,
      pick_id,
      season_year,
      week_number,
      action,
      team_id,
      game_id,
      created_at
    )
    values (
      old.league_id,
      old.user_id,
      old.id,
      old.season_year,
      old.week_number,
      'cleared',
      old.team_id,
      old.game_id,
      now()
    );
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists picks_audit_log_insert on public.picks;
create trigger picks_audit_log_insert
  after insert on public.picks
  for each row
  execute function public.log_pick_audit();

drop trigger if exists picks_audit_log_update on public.picks;
create trigger picks_audit_log_update
  after update on public.picks
  for each row
  execute function public.log_pick_audit();

drop trigger if exists picks_audit_log_delete on public.picks;
create trigger picks_audit_log_delete
  before delete on public.picks
  for each row
  execute function public.log_pick_audit();

-- Seed one "picked" row per existing pick so history is not empty before this migration.
insert into public.pick_audit_log (
  league_id,
  user_id,
  pick_id,
  season_year,
  week_number,
  action,
  team_id,
  game_id,
  created_at
)
select
  p.league_id,
  p.user_id,
  p.id,
  p.season_year,
  p.week_number,
  'picked',
  p.team_id,
  p.game_id,
  coalesce(p.submitted_at, p.created_at, now())
from public.picks p;

-- ---------------------------------------------------------------------------
-- Admin RPC
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_pick_audit_log(p_league_id uuid)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  week_number integer,
  season_year integer,
  action text,
  team_id text,
  team_abbreviation text,
  team_name text,
  previous_team_id text,
  previous_team_abbreviation text,
  previous_team_name text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  if not exists (select 1 from public.leagues l where l.id = p_league_id) then
    raise exception 'League not found';
  end if;

  return query
  select
    pal.id,
    pal.user_id,
    coalesce(pr.display_name, 'Unknown') as display_name,
    pal.week_number,
    pal.season_year,
    pal.action,
    pal.team_id,
    coalesce(t.abbreviation, pal.team_id) as team_abbreviation,
    coalesce(t.name, pal.team_id) as team_name,
    pal.previous_team_id,
    prev.abbreviation as previous_team_abbreviation,
    prev.name as previous_team_name,
    pal.created_at
  from public.pick_audit_log pal
  join public.profiles pr on pr.id = pal.user_id
  left join public.nfl_teams t on t.id = pal.team_id
  left join public.nfl_teams prev on prev.id = pal.previous_team_id
  where pal.league_id = p_league_id
  order by pal.created_at desc;
end;
$$;

grant execute on function public.admin_list_pick_audit_log(uuid) to authenticated;
