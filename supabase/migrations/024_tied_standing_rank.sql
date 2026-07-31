-- Golden Spoon — shared standing rank for true ties
--
-- league_standings_ranked previously broke ties with user_id inside rank(), so
-- two players with identical points + tiebreaker never both received rank 1
-- (and thus never both got the crown). Rank only on points + configured
-- tiebreaker; display order can still use name/user_id outside the window.

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
      end desc
  ) as standing_rank
from public.league_standings ls
join public.leagues l on l.id = ls.league_id;

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
    and public.is_league_member(p_league_id)
  order by
    lsr.standing_rank,
    lsr.display_name,
    lsr.user_id;
$$;
