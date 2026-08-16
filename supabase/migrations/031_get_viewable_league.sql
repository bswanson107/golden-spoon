-- Signed-out demo browse: return a league row when it is a public demo
-- (or the caller is a member). Bypasses table RLS so guests are not blocked
-- by authenticated-only SELECT policies.

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
      (coalesce(l.is_public_demo, false) = true and l.is_active = true)
      or public.is_league_member(l.id)
    );
$$;

grant execute on function public.get_viewable_league(uuid) to anon, authenticated;

-- Re-apply guest read access (safe if 030 already ran).
grant execute on function public.is_league_member(uuid, uuid) to anon, authenticated;
grant execute on function public.can_view_league(uuid, uuid) to anon, authenticated;
grant execute on function public.get_league_standings(uuid) to anon, authenticated;
grant execute on function public.get_league_pick_submissions(uuid) to anon, authenticated;
grant execute on function public.league_week_pick_status(uuid, integer) to anon, authenticated;

drop policy if exists "leagues_select_public_demo" on public.leagues;
create policy "leagues_select_public_demo"
  on public.leagues for select
  to anon, authenticated
  using (is_public_demo = true and is_active = true);
