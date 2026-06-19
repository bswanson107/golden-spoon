-- Golden Spoon — sync_state table for NFL data sync rate limiting / status

create table if not exists public.sync_state (
  key text primary key,
  last_started_at timestamptz,
  last_completed_at timestamptz,
  last_error text,
  games_updated integer not null default 0,
  odds_updated integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.sync_state (key)
values ('nfl_games')
on conflict (key) do nothing;

alter table public.sync_state enable row level security;

create policy "sync_state_select_authenticated"
  on public.sync_state for select
  to authenticated
  using (true);
