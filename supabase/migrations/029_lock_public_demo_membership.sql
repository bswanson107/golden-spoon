-- Lock the public demo league: viewable by all authenticated users, but no new
-- memberships. Stops ensure_public_demo_memberships from adding every visitor
-- to standings / picks. Other leagues are unchanged.

-- ---------------------------------------------------------------------------
-- Helper: member OR public demo (read-only browse)
-- ---------------------------------------------------------------------------
create or replace function public.can_view_league(p_league_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_league_member(p_league_id, p_user_id)
    or exists (
      select 1
      from public.leagues l
      where l.id = p_league_id
        and l.is_public_demo = true
        and l.is_active = true
    );
$$;

grant execute on function public.can_view_league(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Stop auto-joining visitors to the public demo
-- ---------------------------------------------------------------------------
create or replace function public.ensure_public_demo_memberships()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  -- No-op: public demo is browse-only; never insert league_members for callers.
end;
$$;

grant execute on function public.ensure_public_demo_memberships() to authenticated;

-- ---------------------------------------------------------------------------
-- Block invite / self-join into public demo leagues
-- ---------------------------------------------------------------------------
create or replace function public.join_league_by_invite(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league_id uuid;
  v_is_public_demo boolean;
  v_invite text := lower(trim(coalesce(p_invite_code, '')));
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if v_invite = '' then
    raise exception 'Invite code is required';
  end if;

  select l.id, l.is_public_demo
  into v_league_id, v_is_public_demo
  from public.leagues l
  where l.invite_code = v_invite
    and l.is_active = true;

  if v_league_id is null then
    raise exception 'Invalid invite code';
  end if;

  if coalesce(v_is_public_demo, false) then
    raise exception 'Public demo leagues cannot be joined';
  end if;

  insert into public.league_members (league_id, user_id)
  values (v_league_id, auth.uid())
  on conflict (league_id, user_id) do nothing;

  return v_league_id;
end;
$$;

grant execute on function public.join_league_by_invite(text) to authenticated;

drop policy if exists "league_members_insert_self" on public.league_members;
create policy "league_members_insert_self"
  on public.league_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and not exists (
      select 1
      from public.leagues l
      where l.id = league_id
        and l.is_public_demo = true
    )
  );

-- ---------------------------------------------------------------------------
-- Read access without membership (demo only)
-- ---------------------------------------------------------------------------
drop policy if exists "league_members_select_same_league" on public.league_members;
create policy "league_members_select_same_league"
  on public.league_members for select
  using (public.can_view_league(league_id));

drop policy if exists "profiles_select_public_demo_members" on public.profiles;
create policy "profiles_select_public_demo_members"
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1
      from public.league_members lm
      join public.leagues l on l.id = lm.league_id
      where lm.user_id = profiles.id
        and l.is_public_demo = true
        and l.is_active = true
    )
  );

drop policy if exists "picks_select_league_after_kickoff" on public.picks;
create policy "picks_select_league_after_kickoff"
  on public.picks for select
  using (
    public.can_view_league(league_id)
    and (
      exists (
        select 1
        from public.leagues l
        where l.id = picks.league_id
          and l.pick_visibility = 'open'
      )
      or exists (
        select 1
        from public.leagues l
        where l.id = picks.league_id
          and l.is_public_demo = true
      )
      or exists (
        select 1
        from public.nfl_games g
        where g.id = picks.game_id
          and g.kickoff_at <= public.qa_now()
      )
    )
  );

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
    and public.can_view_league(p_league_id)
  order by
    lsr.standing_rank,
    lsr.display_name,
    lsr.user_id;
$$;

grant execute on function public.get_league_standings(uuid) to authenticated;

create or replace function public.get_league_pick_submissions(p_league_id uuid)
returns table (
  user_id uuid,
  week_number integer,
  status text
)
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.can_view_league(p_league_id) then
    raise exception 'Not a league member';
  end if;

  return query
  select
    p.user_id,
    p.week_number,
    case when p.is_missed then 'missed' else 'submitted' end as status
  from public.picks p
  where p.league_id = p_league_id
    and p.superseded_by_pick_id is null;
end;
$$;

grant execute on function public.get_league_pick_submissions(uuid) to authenticated;

create or replace function public.league_week_pick_status(
  p_league_id uuid,
  p_week_number integer
)
returns table (
  user_id uuid,
  status text
)
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.can_view_league(p_league_id) then
    raise exception 'Not a league member';
  end if;

  return query
  select
    p.user_id,
    case when p.is_missed then 'missed' else 'submitted' end as status
  from public.picks p
  where p.league_id = p_league_id
    and p.week_number = p_week_number
    and p.superseded_by_pick_id is null;
end;
$$;

grant execute on function public.league_week_pick_status(uuid, integer) to authenticated;

-- ---------------------------------------------------------------------------
-- Purge accidental public-demo joiners (keep seeded Scag pool roster only)
-- ---------------------------------------------------------------------------
do $$
declare
  seed_ids uuid[] := array[
    '7439c70c-c73e-4eec-af61-d2c7a0996373'::uuid,
    '56cac38f-d573-482a-a575-6da02e2288cb'::uuid,
    '88ae01d8-7c21-4e95-ad36-1dc27e0e453a'::uuid,
    'e6c9506e-5c35-46d2-a5dc-7cb94194e588'::uuid,
    '5e0d1cac-d616-471c-a1f6-3eef7c39a9af'::uuid,
    'f926ce38-990c-4175-afe9-d3bfec7c0366'::uuid,
    '9a6dd50f-42ab-4e37-a501-fe15f502554b'::uuid,
    'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e'::uuid,
    '4bd4e5d9-2864-4ccb-a873-c549f8249f25'::uuid,
    '85978942-f5a7-4513-ae52-41055b9da732'::uuid,
    '1dca2d73-65a7-4f28-acda-85dd4675e256'::uuid,
    'ebc98f93-b328-402f-a31e-4cf89582ae8e'::uuid,
    '44c8d145-65ef-4987-ac97-88e344d428c9'::uuid,
    '7f865349-1435-488d-aafe-87b0565b8610'::uuid,
    'b58e4217-d5df-498d-a488-c49c73033846'::uuid,
    '0621f100-0b9d-4158-ae0c-40f5455d0b7a'::uuid,
    '2019ef35-f471-4858-a726-89acc2594138'::uuid,
    'c821b559-7cd9-491d-abd3-082c877eeeb8'::uuid
  ];
  demo_id uuid := 'b0000001-0000-4000-8000-000000000001';
begin
  delete from public.picks p
  where p.league_id = demo_id
    and not (p.user_id = any (seed_ids));

  delete from public.league_members lm
  where lm.league_id = demo_id
    and not (lm.user_id = any (seed_ids));
end;
$$;
