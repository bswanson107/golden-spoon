-- Season scoring totals for advanced pick-page stats (PF / PA / PD).

alter table public.season_team_records
  add column if not exists points_for integer not null default 0,
  add column if not exists points_against integer not null default 0;

comment on column public.season_team_records.points_for is
  'Season points scored (PF) from final games.';
comment on column public.season_team_records.points_against is
  'Season points allowed (PA) from final games.';

-- Backfill from existing final games with scores.
with scored as (
  select
    g.season_year,
    g.home_team_id as team_id,
    coalesce(g.home_score, 0) as points_for,
    coalesce(g.away_score, 0) as points_against
  from public.nfl_games g
  where g.status = 'final'
    and g.home_score is not null
    and g.away_score is not null
  union all
  select
    g.season_year,
    g.away_team_id as team_id,
    coalesce(g.away_score, 0) as points_for,
    coalesce(g.home_score, 0) as points_against
  from public.nfl_games g
  where g.status = 'final'
    and g.home_score is not null
    and g.away_score is not null
),
totals as (
  select
    season_year,
    team_id,
    sum(points_for)::integer as points_for,
    sum(points_against)::integer as points_against
  from scored
  group by season_year, team_id
)
update public.season_team_records r
set
  points_for = t.points_for,
  points_against = t.points_against,
  updated_at = now()
from totals t
where r.season_year = t.season_year
  and r.team_id = t.team_id;
