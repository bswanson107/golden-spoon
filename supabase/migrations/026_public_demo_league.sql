-- Public demo league: visible/joinable for every authenticated user without an invite code.

alter table public.leagues
  add column if not exists is_public_demo boolean not null default false;

update public.leagues
set
  is_public_demo = true,
  name = 'Scaglione Family Pool'
where id = 'b0000001-0000-4000-8000-000000000001';

drop policy if exists "leagues_select_public_demo" on public.leagues;
create policy "leagues_select_public_demo"
  on public.leagues for select
  to authenticated
  using (is_public_demo = true);

-- Auto-join the caller to every active public demo league.
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

  insert into public.league_members (league_id, user_id)
  select l.id, auth.uid()
  from public.leagues l
  where l.is_public_demo = true
    and l.is_active = true
  on conflict (league_id, user_id) do nothing;
end;
$$;

grant execute on function public.ensure_public_demo_memberships() to authenticated;
