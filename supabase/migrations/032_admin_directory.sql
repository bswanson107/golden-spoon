-- App admin: browse any league, list all users/leagues, delete users.
-- Does not require the admin to be a member of the league they inspect.

-- ---------------------------------------------------------------------------
-- View access for app admins (standings, picks, members, league row)
-- ---------------------------------------------------------------------------
create or replace function public.can_view_league(p_league_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_app_admin(p_user_id)
    or public.is_league_member(p_league_id, p_user_id)
    or exists (
      select 1
      from public.leagues l
      where l.id = p_league_id
        and l.is_public_demo = true
        and l.is_active = true
    );
$$;

grant execute on function public.can_view_league(uuid, uuid) to anon, authenticated;

create or replace function public.get_viewable_league(p_league_id uuid)
returns setof public.leagues
language sql
stable
security definer
set search_path = public
as $$
  select l.*
  from public.leagues l
  where l.id = p_league_id
    and (
      public.is_app_admin()
      or (coalesce(l.is_public_demo, false) = true and l.is_active = true)
      or public.is_league_member(l.id)
    );
$$;

grant execute on function public.get_viewable_league(uuid) to anon, authenticated;

drop policy if exists "leagues_select_app_admin" on public.leagues;
create policy "leagues_select_app_admin"
  on public.leagues for select
  to authenticated
  using (public.is_app_admin());

drop policy if exists "profiles_select_app_admin" on public.profiles;
create policy "profiles_select_app_admin"
  on public.profiles for select
  to authenticated
  using (public.is_app_admin());

-- ---------------------------------------------------------------------------
-- Kick / delete league without requiring admin membership
-- ---------------------------------------------------------------------------
create or replace function public.admin_kick_league_member(
  p_league_id uuid,
  p_user_id uuid
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

  if p_user_id = auth.uid() then
    raise exception 'Cannot remove yourself';
  end if;

  if exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
      and l.commissioner_id = p_user_id
  ) then
    raise exception 'Cannot remove the league commissioner';
  end if;

  if not exists (
    select 1
    from public.league_members lm
    where lm.league_id = p_league_id
      and lm.user_id = p_user_id
  ) then
    raise exception 'User is not a member of this league';
  end if;

  update public.picks
  set superseded_by_pick_id = null
  where league_id = p_league_id
    and user_id = p_user_id;

  delete from public.commissioner_actions ca
  where ca.target_pick_id in (
    select p.id
    from public.picks p
    where p.league_id = p_league_id
      and p.user_id = p_user_id
  );

  delete from public.picks
  where league_id = p_league_id
    and user_id = p_user_id;

  delete from public.league_members
  where league_id = p_league_id
    and user_id = p_user_id;
end;
$$;

grant execute on function public.admin_kick_league_member(uuid, uuid) to authenticated;

create or replace function public.admin_delete_league(
  p_league_id uuid
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

  if not exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
  ) then
    raise exception 'League not found';
  end if;

  if exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
      and l.is_public_demo = true
  ) then
    raise exception 'Cannot delete the public demo league';
  end if;

  update public.picks
  set superseded_by_pick_id = null
  where league_id = p_league_id;

  delete from public.commissioner_actions
  where league_id = p_league_id;

  delete from public.picks
  where league_id = p_league_id;

  delete from public.league_members
  where league_id = p_league_id;

  delete from public.leagues
  where id = p_league_id;
end;
$$;

grant execute on function public.admin_delete_league(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Directory RPCs
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_leagues()
returns table (
  id uuid,
  name text,
  season_year integer,
  commissioner_id uuid,
  commissioner_name text,
  member_count bigint,
  is_public_demo boolean,
  is_active boolean,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  return query
  select
    l.id,
    l.name,
    l.season_year,
    l.commissioner_id,
    coalesce(p.display_name, 'Unknown') as commissioner_name,
    (
      select count(*)::bigint
      from public.league_members lm
      where lm.league_id = l.id
    ) as member_count,
    l.is_public_demo,
    l.is_active,
    l.created_at
  from public.leagues l
  left join public.profiles p on p.id = l.commissioner_id
  order by l.is_public_demo desc, l.created_at desc;
end;
$$;

grant execute on function public.admin_list_leagues() to authenticated;

create or replace function public.admin_list_users()
returns table (
  user_id uuid,
  email text,
  display_name text,
  created_at timestamptz,
  leagues jsonb
)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  return query
  select
    u.id as user_id,
    u.email::text,
    coalesce(p.display_name, split_part(u.email::text, '@', 1)) as display_name,
    u.created_at,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', l.id,
            'name', l.name,
            'season_year', l.season_year,
            'is_commissioner', l.commissioner_id = u.id,
            'is_public_demo', l.is_public_demo
          )
          order by l.name
        )
        from public.league_members lm
        join public.leagues l on l.id = lm.league_id
        where lm.user_id = u.id
      ),
      '[]'::jsonb
    ) as leagues
  from auth.users u
  left join public.profiles p on p.id = u.id
  order by u.created_at desc;
end;
$$;

grant execute on function public.admin_list_users() to authenticated;

-- ---------------------------------------------------------------------------
-- Delete a user: kick from every league, drop commissioned leagues, remove auth
-- ---------------------------------------------------------------------------
create or replace function public.admin_delete_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_league_id uuid;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  if p_user_id is null then
    raise exception 'User is required';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'Cannot delete yourself';
  end if;

  if public.is_app_admin(p_user_id) then
    raise exception 'Cannot delete an app admin';
  end if;

  if exists (
    select 1
    from public.leagues l
    where l.commissioner_id = p_user_id
      and coalesce(l.is_public_demo, false) = true
  ) then
    raise exception 'Cannot delete the public demo commissioner';
  end if;

  -- Leagues they commission cannot exist without them.
  for v_league_id in
    select l.id
    from public.leagues l
    where l.commissioner_id = p_user_id
  loop
    update public.picks
    set superseded_by_pick_id = null
    where league_id = v_league_id;

    delete from public.commissioner_actions where league_id = v_league_id;
    delete from public.picks where league_id = v_league_id;
    delete from public.league_members where league_id = v_league_id;
    delete from public.leagues where id = v_league_id;
  end loop;

  update public.picks
  set superseded_by_pick_id = null
  where user_id = p_user_id;

  delete from public.commissioner_actions ca
  where ca.actor_id = p_user_id
     or ca.target_pick_id in (select p.id from public.picks p where p.user_id = p_user_id);

  delete from public.picks where user_id = p_user_id;
  delete from public.league_members where user_id = p_user_id;

  begin
    update public.qa_clock
    set updated_by = null
    where updated_by = p_user_id;
  exception
    when undefined_table or undefined_column then
      null;
  end;

  delete from public.profiles where id = p_user_id;
  delete from auth.users where id = p_user_id;
end;
$$;

grant execute on function public.admin_delete_user(uuid) to authenticated;
