-- Golden Spoon — auto-assigned MNF pick for missed weeks
--
-- When a member fails to pick before the week's slate locks, they are assigned
-- the week's final (MNF) game's HOME team as a real, scoring pick — unless they
-- have already used that team this season, in which case they get a true
-- "missed pick" (0 points). This makes every closed-week cell show a value:
-- their pick, the auto-assigned MNF home team, or the missed indicator.
--
-- Auto picks are inserted by the service-role sync (markMissedPicks). They must
-- bypass the auth + kickoff-deadline checks (the deadline has already passed)
-- but otherwise behave like a normal pick: win %/underdog snapshot + scoring.

alter table public.picks
  add column if not exists is_auto_pick boolean not null default false;

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
  if tg_op in ('INSERT', 'UPDATE') and new.superseded_by_pick_id is null and not v_is_auto then
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

-- Reset must also remove auto-assigned MNF picks (is_auto_pick) so a week can be
-- replayed and a member can "miss" it again cleanly.
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
    and (is_missed = true or is_auto_pick = true);

  update public.picks
  set outcome = 'pending',
      points_awarded = 0,
      updated_at = now()
  where season_year = p_season_year
    and week_number = p_week_number
    and is_missed = false
    and is_auto_pick = false
    and is_commissioner_override = false
    and superseded_by_pick_id is null
    and outcome <> 'pending';
end;
$$;
