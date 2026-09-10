-- Map profile avatars to static files by filename (e.g. Ben.jpg), tied to user id via avatar_key.

alter table public.profiles
  add column if not exists avatar_key text;

comment on column public.profiles.avatar_key is
  'Filename stem or name under static/avatars/ (e.g. Ben or Ben.jpg). Stable when display_name changes.';

create or replace function public.profiles_guard_self_service_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_app_admin() then
    return new;
  end if;

  if auth.uid() is distinct from old.id then
    return new;
  end if;

  new.avatar_url := old.avatar_url;
  new.avatar_key := old.avatar_key;
  new.can_change_display_name := old.can_change_display_name;
  return new;
end;
$$;

drop function if exists public.get_league_standings(uuid);

create or replace function public.get_league_standings(p_league_id uuid)
returns table (
  user_id uuid,
  display_name text,
  avatar_key text,
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
    p.avatar_key,
    lsr.total_points,
    lsr.tiebreaker_picked_team_wins,
    lsr.pending_picks,
    lsr.standing_rank
  from public.league_standings_ranked lsr
  left join public.profiles p on p.id = lsr.user_id
  where lsr.league_id = p_league_id
    and public.can_view_league(p_league_id)
  order by
    lsr.standing_rank,
    lsr.display_name,
    lsr.user_id;
$$;

grant execute on function public.get_league_standings(uuid) to anon, authenticated;

drop function if exists public.admin_list_users();

create or replace function public.admin_list_users()
returns table (
  user_id uuid,
  email text,
  display_name text,
  avatar_key text,
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
    p.avatar_key,
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

drop function if exists public.admin_update_user(uuid, text, boolean, text);

create or replace function public.admin_update_user(
  p_user_id uuid,
  p_display_name text,
  p_can_change_display_name boolean,
  p_avatar_key text default null
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_display_name text;
  v_avatar_key text;
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

  v_avatar_key := nullif(trim(coalesce(p_avatar_key, '')), '');

  if v_avatar_key is not null then
    if v_avatar_key ~ '[/\\]' or v_avatar_key like '%..%' then
      raise exception 'Avatar file name cannot contain path separators';
    end if;
    if char_length(v_avatar_key) > 120 then
      raise exception 'Avatar file name is too long';
    end if;
  end if;

  insert into public.profiles (id, display_name, can_change_display_name, avatar_key)
  values (
    p_user_id,
    v_display_name,
    coalesce(p_can_change_display_name, true),
    v_avatar_key
  )
  on conflict (id) do update
  set
    display_name = excluded.display_name,
    can_change_display_name = excluded.can_change_display_name,
    avatar_key = excluded.avatar_key,
    updated_at = now();
end;
$$;

grant execute on function public.admin_update_user(uuid, text, boolean, text) to authenticated;
