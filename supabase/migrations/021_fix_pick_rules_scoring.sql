-- Golden Spoon — fix enforce_pick_rules blocking post-kickoff system updates
--
-- enforce_pick_rules (BEFORE INSERT OR UPDATE on picks) enforced the kickoff
-- deadline on *every* UPDATE. But picks are legitimately UPDATEd by the system
-- AFTER kickoff:
--   * score_picks_for_game()  — sets outcome/points when a game goes final
--   * lockKickoffWinPcts / qa_run_processing — re-snapshots win %/underdog
--   * superseding a pick       — sets superseded_by_pick_id
-- For those, the deadline check raised "Pick deadline passed", which rolled
-- back the triggering nfl_games update — so a game with any picks on it could
-- never be marked final. (Latent since 001; first hit now that QA mode drives
-- games to final with picks present.)
--
-- Fix: only validate the *selection* (auth, league membership, game/team,
-- deadline, status) and (re)snapshot win %/underdog when the team/game choice
-- is actually being created or changed. Pure mutations of outcome/points/
-- win %/superseded fields pass through untouched, preserving any explicitly
-- locked snapshot. User-initiated updates remain guarded by RLS
-- (picks_update_own_before_kickoff), so this does not loosen pick security.

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
  v_is_auto boolean := coalesce(new.is_auto_pick, false);
  v_selection_changed boolean;
begin
  -- Missed pick (synthetic 0-point row inserted by service role) — short circuit.
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

  -- Only validate + (re)snapshot when the team/game selection is set or changed.
  -- Scoring, win-% locking and superseding leave game_id/team_id untouched and
  -- must pass through after kickoff without re-validation or clobbering.
  v_selection_changed := (tg_op = 'INSERT')
    or (new.game_id is distinct from old.game_id)
    or (new.team_id is distinct from old.team_id);

  if not v_selection_changed then
    return new;
  end if;

  -- Auth applies only to user-submitted picks, not service-role auto picks.
  if not v_is_auto then
    if auth.uid() is null then
      raise exception 'Not authenticated';
    end if;

    if new.user_id is null then
      new.user_id := auth.uid();
    end if;

    if new.user_id is distinct from auth.uid() then
      raise exception 'Cannot submit pick for another user';
    end if;
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

  -- Deadline + status checks apply only to user picks (auto picks are assigned
  -- after the slate locks, so the deadline has intentionally passed).
  if new.superseded_by_pick_id is null and not v_is_auto then
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
