-- Live standings tiebreaker: sum of current regular-season wins of teams a
-- player has actually picked. Recalculated from completed nfl_games whenever
-- standings are read, so marking a game final immediately updates TB.
-- Unpicked teams (and missed/void picks) do not contribute.

comment on column public.picks.team_season_wins_at_pick is
  'Legacy snapshot of team wins at pick time. Standings tiebreaker uses live season wins from completed games.';

create or replace view public.league_standings as
select
  lm.league_id,
  lm.user_id,
  p.display_name,
  coalesce(sum(pk.points_awarded), 0)::numeric(6, 1) as total_points,
  coalesce(
    sum(tw.wins) filter (
      where coalesce(pk.is_missed, false) = false
        and pk.outcome is distinct from 'void'
        and pk.outcome is distinct from 'missed'
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
  'Per-member points plus live tiebreaker (sum of current regular-season wins of picked teams).';
