-- Golden Spoon — commissioner-chosen invite codes
--
-- Invite codes are no longer only auto-generated hex. Commissioners set a
-- friendly code at league creation and may change it later. Codes are stored
-- lowercase; uniqueness remains enforced by leagues.invite_code unique.

create or replace function public.normalize_invite_code(p_code text)
returns text
language plpgsql
immutable
as $$
declare
  v_code text := lower(trim(coalesce(p_code, '')));
begin
  if v_code = '' then
    raise exception 'Invite code is required';
  end if;

  if char_length(v_code) < 3 then
    raise exception 'Invite code must be at least 3 characters';
  end if;

  if char_length(v_code) > 32 then
    raise exception 'Invite code must be at most 32 characters';
  end if;

  if v_code !~ '^[a-z0-9-]+$' then
    raise exception 'Invite code can only use letters, numbers, and hyphens';
  end if;

  return v_code;
end;
$$;

drop function if exists public.create_league(text, integer, numeric, public.tiebreaker_mode, public.pick_visibility);

create or replace function public.create_league(
  p_name text,
  p_season_year integer,
  p_invite_code text,
  p_underdog_threshold_pct numeric default 33.00,
  p_tiebreaker_mode public.tiebreaker_mode default 'fewest_wins',
  p_pick_visibility public.pick_visibility default 'hidden_until_kickoff'
)
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league public.leagues;
  v_name text := trim(p_name);
  v_invite text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if v_name is null or v_name = '' then
    raise exception 'League name is required';
  end if;

  if p_underdog_threshold_pct < 0 or p_underdog_threshold_pct > 100 then
    raise exception 'Underdog threshold must be between 0 and 100';
  end if;

  begin
    v_invite := public.normalize_invite_code(p_invite_code);
  exception
    when others then
      raise;
  end;

  if exists (
    select 1 from public.leagues l where l.invite_code = v_invite
  ) then
    raise exception 'That invite code is already in use. Pick a different one.';
  end if;

  perform public.ensure_profile();

  insert into public.leagues (
    name,
    season_year,
    commissioner_id,
    invite_code,
    underdog_threshold_pct,
    tiebreaker_mode,
    pick_visibility
  )
  values (
    v_name,
    p_season_year,
    auth.uid(),
    v_invite,
    p_underdog_threshold_pct,
    p_tiebreaker_mode,
    p_pick_visibility
  )
  returning * into v_league;

  insert into public.league_members (league_id, user_id)
  values (v_league.id, auth.uid())
  on conflict (league_id, user_id) do nothing;

  return v_league;
end;
$$;

create or replace function public.update_league_invite_code(
  p_league_id uuid,
  p_invite_code text
)
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league public.leagues;
  v_invite text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
      and l.commissioner_id = auth.uid()
  ) then
    raise exception 'Only the commissioner can change the invite code';
  end if;

  v_invite := public.normalize_invite_code(p_invite_code);

  if exists (
    select 1
    from public.leagues l
    where l.invite_code = v_invite
      and l.id <> p_league_id
  ) then
    raise exception 'That invite code is already in use. Pick a different one.';
  end if;

  update public.leagues
  set invite_code = v_invite
  where id = p_league_id
  returning * into v_league;

  return v_league;
end;
$$;

-- Join already lowercases; keep using normalize for consistent trim behavior.
create or replace function public.join_league_by_invite(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league_id uuid;
  v_invite text := lower(trim(coalesce(p_invite_code, '')));
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if v_invite = '' then
    raise exception 'Invite code is required';
  end if;

  select l.id into v_league_id
  from public.leagues l
  where l.invite_code = v_invite
    and l.is_active = true;

  if v_league_id is null then
    raise exception 'Invalid invite code';
  end if;

  insert into public.league_members (league_id, user_id)
  values (v_league_id, auth.uid())
  on conflict (league_id, user_id) do nothing;

  return v_league_id;
end;
$$;

grant execute on function public.normalize_invite_code(text) to authenticated;
grant execute on function public.create_league(text, integer, text, numeric, public.tiebreaker_mode, public.pick_visibility) to authenticated;
grant execute on function public.update_league_invite_code(uuid, text) to authenticated;
grant execute on function public.join_league_by_invite(text) to authenticated;
