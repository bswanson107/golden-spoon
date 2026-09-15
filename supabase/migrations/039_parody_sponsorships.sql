-- Per-league parody sponsorship ads (admin toggled, default off).

alter table public.leagues
  add column if not exists show_parody_sponsorships boolean not null default false;

comment on column public.leagues.show_parody_sponsorships is
  'When true, league pages show rotating, dismissible parody sponsor ads.';

drop function if exists public.admin_list_leagues();

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
  show_profile_pictures boolean,
  show_parody_sponsorships boolean,
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
    l.show_profile_pictures,
    l.show_parody_sponsorships,
    l.created_at
  from public.leagues l
  left join public.profiles p on p.id = l.commissioner_id
  order by member_count desc, l.name asc;
end;
$$;

grant execute on function public.admin_list_leagues() to authenticated;

create or replace function public.admin_set_league_parody_sponsorships(
  p_league_id uuid,
  p_show_parody_sponsorships boolean
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

  if not exists (select 1 from public.leagues l where l.id = p_league_id) then
    raise exception 'League not found';
  end if;

  update public.leagues
  set
    show_parody_sponsorships = coalesce(p_show_parody_sponsorships, false),
    updated_at = now()
  where id = p_league_id;
end;
$$;

grant execute on function public.admin_set_league_parody_sponsorships(uuid, boolean) to authenticated;
