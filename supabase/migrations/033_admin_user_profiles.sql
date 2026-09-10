-- Admin: sort leagues by member count; manage user display names and self-edit lock.

alter table public.profiles
  add column if not exists can_change_display_name boolean not null default true;

-- Users may only update their profile when not locked by an app admin.
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id and can_change_display_name = true)
  with check (auth.uid() = id and can_change_display_name = true);

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
  order by member_count desc, l.name asc;
end;
$$;

grant execute on function public.admin_list_leagues() to authenticated;

-- Return type adds can_change_display_name; CREATE OR REPLACE cannot change OUT columns.
drop function if exists public.admin_list_users();

create or replace function public.admin_list_users()
returns table (
  user_id uuid,
  email text,
  display_name text,
  can_change_display_name boolean,
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
    coalesce(p.can_change_display_name, true) as can_change_display_name,
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

create or replace function public.admin_update_user(
  p_user_id uuid,
  p_display_name text,
  p_can_change_display_name boolean
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_display_name text;
begin
  if not public.is_app_admin() then
    raise exception 'Not authorized';
  end if;

  if p_user_id is null then
    raise exception 'User is required';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_user_id) then
    raise exception 'User not found';
  end if;

  v_display_name := nullif(trim(p_display_name), '');
  if v_display_name is null then
    raise exception 'Display name cannot be empty';
  end if;

  if char_length(v_display_name) > 40 then
    raise exception 'Display name must be 40 characters or fewer';
  end if;

  insert into public.profiles (id, display_name, can_change_display_name)
  values (p_user_id, v_display_name, coalesce(p_can_change_display_name, true))
  on conflict (id) do update
  set
    display_name = excluded.display_name,
    can_change_display_name = excluded.can_change_display_name,
    updated_at = now();
end;
$$;

grant execute on function public.admin_update_user(uuid, text, boolean) to authenticated;
