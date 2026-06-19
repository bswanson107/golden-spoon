-- Golden Spoon — commissioner manual game status/score updates

create or replace function public.update_game_status(
  p_league_id uuid,
  p_game_id uuid,
  p_status text,
  p_home_score integer default null,
  p_away_score integer default null,
  p_winner_team_id text default null,
  p_is_tie boolean default false
)
returns public.nfl_games
language plpgsql
security definer
set search_path = public
as $$
declare
  v_game public.nfl_games;
  v_league public.leagues;
  v_home_score integer;
  v_away_score integer;
  v_winner text;
  v_is_tie boolean;
begin
  if not public.is_league_commissioner(p_league_id) then
    raise exception 'Only the league commissioner can update games';
  end if;

  select * into v_league from public.leagues where id = p_league_id;
  if not found then
    raise exception 'League not found';
  end if;

  select * into v_game from public.nfl_games where id = p_game_id;
  if not found then
    raise exception 'Game not found';
  end if;

  if v_game.season_year <> v_league.season_year then
    raise exception 'Game season does not match league season';
  end if;

  v_home_score := coalesce(p_home_score, v_game.home_score);
  v_away_score := coalesce(p_away_score, v_game.away_score);
  v_winner := coalesce(p_winner_team_id, v_game.winner_team_id);
  v_is_tie := p_is_tie;

  if p_status = 'final' and v_home_score is not null and v_away_score is not null then
    if v_home_score = v_away_score then
      v_is_tie := true;
      v_winner := null;
    elsif v_winner is null then
      if v_home_score > v_away_score then
        v_winner := v_game.home_team_id;
      else
        v_winner := v_game.away_team_id;
      end if;
    end if;
  end if;

  update public.nfl_games
  set
    status = p_status::public.game_status,
    home_score = v_home_score,
    away_score = v_away_score,
    winner_team_id = v_winner,
    is_tie = v_is_tie,
    updated_at = now()
  where id = p_game_id
  returning * into v_game;

  if p_status = 'final' then
    perform public.score_picks_for_game(p_game_id);
  end if;

  return v_game;
end;
$$;

grant execute on function public.update_game_status(uuid, uuid, text, integer, integer, text, boolean)
  to authenticated;
