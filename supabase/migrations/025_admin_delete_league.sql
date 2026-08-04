-- Admin tool: app admin can delete an entire league via RPC.
-- Requires migration 006 (is_app_admin).

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

  if not public.is_league_member(p_league_id) then
    raise exception 'Caller is not a member of this league';
  end if;

  if not exists (
    select 1
    from public.leagues l
    where l.id = p_league_id
  ) then
    raise exception 'League not found';
  end if;

  -- Break self-references between superseded picks before delete.
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
