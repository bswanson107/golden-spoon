-- Tiebreaker only includes scored picks (win/loss/tie), not pending future weeks.
-- A week-2 selection made during week 1 must not add that team's wins until
-- the pick is scored.

create or replace view public.league_standings as
select
  lm.league_id,
  lm.user_id,
  p.display_name,
  coalesce(sum(pk.points_awarded), 0)::numeric(6, 1) as total_points,
  coalesce(
    sum(tw.wins) filter (
      where coalesce(pk.is_missed, false) = false
        and pk.outcome in ('win', 'loss', 'tie')
    ),
    0
  )::integer as tiebreaker_picked_team_wins,
  count(pk.id) filter (
    where pk.outcome = 'pending'
  )::integer as pending_picks
from public.league_members lm
join public.profiles p on p.id = lm.user_id
left join public.picks pk
  on pk.league_id = lm.league_id
  and pk.user_id = lm.user_id
  and pk.superseded_by_pick_id is null
left join (
  select
    g.season_year,
    g.winner_team_id as team_id,
    count(*)::integer as wins
  from public.nfl_games g
  where g.status = 'final'
    and g.winner_team_id is not null
    and coalesce(g.is_tie, false) = false
    and g.week_number between 1 and 18
  group by g.season_year, g.winner_team_id
) tw
  on tw.season_year = pk.season_year
 and tw.team_id = pk.team_id
group by lm.league_id, lm.user_id, p.display_name;

comment on view public.league_standings is
  'Per-member points plus live tiebreaker from scored picks only (pending/void/missed excluded).';
