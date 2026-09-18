-- Golden Spoon — underdawg follows current odds, and the threshold is applied
-- to the *displayed* (rounded) win %.
--
-- Two problems this fixes:
--   1) is_underdog() compared the raw numeric, but every surface renders
--      round(win_pct). At a 33 threshold a team at 33.4% displayed "33%" yet
--      was not an underdawg. Now round() runs first: 33.4 -> 33 (underdawg),
--      33.5 -> 34 (not).
--   2) score_picks_for_game() trusted picks.is_underdog_at_pick, which is only
--      re-snapshotted by the kickoff win-% lock. If that lock had not run for a
--      game before it went final, points were awarded from the odds at
--      selection time instead of the odds at kickoff. Scoring now recomputes
--      from the game's stored win % (frozen at kickoff by the lock) and the
--      league threshold.
--
-- Pre-kickoff pending picks are backfilled against current odds at the bottom.
-- Already-scored picks are intentionally left alone.

create or replace function public.is_underdog(
  p_win_pct numeric,
  p_threshold numeric default 33.00
)
returns boolean
language sql
immutable
as $$
  select round(p_win_pct) <= round(p_threshold);
$$;

comment on function public.is_underdog(numeric, numeric) is
  'Underdawg test on the rounded (displayed) win %, so the badge always matches the number shown.';

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
    is_underdog_at_pick = case
      when p.is_missed then false
      else coalesce(
        public.is_underdog(
          case
            when p.team_id = v_game.home_team_id then v_game.home_win_pct
            else v_game.away_win_pct
          end,
          l.underdog_threshold_pct
        ),
        p.is_underdog_at_pick
      )
    end,
    win_pct_at_pick = case
      when p.is_missed then p.win_pct_at_pick
      else coalesce(
        case
          when p.team_id = v_game.home_team_id then v_game.home_win_pct
          else v_game.away_win_pct
        end,
        p.win_pct_at_pick
      )
    end,
    points_awarded = public.points_for_pick_result(
      public.resolve_pick_outcome(p.team_id, v_game),
      case
        when p.is_missed then false
        else coalesce(
          public.is_underdog(
            case
              when p.team_id = v_game.home_team_id then v_game.home_win_pct
              else v_game.away_win_pct
            end,
            l.underdog_threshold_pct
          ),
          p.is_underdog_at_pick
        )
      end
    ),
    updated_at = now()
  from public.leagues l
  where l.id = p.league_id
    and p.game_id = p_game_id
    and p.superseded_by_pick_id is null
    and p.outcome = 'pending'
    and p.is_commissioner_override = false;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

comment on function public.score_picks_for_game(uuid) is
  'Scores pending picks for a final game, recomputing underdawg from the game win % locked at kickoff.';

-- Backfill: pending picks that have not kicked off follow current odds.
update public.picks p
set
  win_pct_at_pick = coalesce(
    case
      when p.team_id = g.home_team_id then g.home_win_pct
      else g.away_win_pct
    end,
    p.win_pct_at_pick
  ),
  is_underdog_at_pick = coalesce(
    public.is_underdog(
      case
        when p.team_id = g.home_team_id then g.home_win_pct
        else g.away_win_pct
      end,
      l.underdog_threshold_pct
    ),
    p.is_underdog_at_pick
  ),
  updated_at = now()
from public.nfl_games g, public.leagues l
where g.id = p.game_id
  and l.id = p.league_id
  and p.outcome = 'pending'
  and p.is_missed = false
  and p.is_commissioner_override = false
  and p.superseded_by_pick_id is null
  and g.kickoff_at > public.qa_now();

-- Pending picks already past kickoff keep their locked win %, but re-evaluate
-- the flag under the new rounding rule.
update public.picks p
set
  is_underdog_at_pick = public.is_underdog(p.win_pct_at_pick, l.underdog_threshold_pct),
  updated_at = now()
from public.leagues l
where l.id = p.league_id
  and p.outcome = 'pending'
  and p.is_missed = false
  and p.is_commissioner_override = false
  and p.superseded_by_pick_id is null
  and p.is_underdog_at_pick
      is distinct from public.is_underdog(p.win_pct_at_pick, l.underdog_threshold_pct);
