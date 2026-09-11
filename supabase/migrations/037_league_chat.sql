-- Light per-league group chat: messages, read cursors, unread count.
-- Members and app admins can read/write. Sender, commissioner, or app admin can delete.

create table public.league_messages (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint league_messages_body_len
    check (char_length(btrim(body)) > 0 and char_length(body) <= 500)
);

create index league_messages_league_created_idx
  on public.league_messages (league_id, created_at desc);

create table public.league_chat_reads (
  league_id uuid not null references public.leagues (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (league_id, user_id)
);

alter table public.league_messages enable row level security;
alter table public.league_chat_reads enable row level security;

create or replace function public.can_use_league_chat(p_league_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_user_id is not null
    and exists (
      select 1
      from public.leagues l
      where l.id = p_league_id
        and coalesce(l.is_public_demo, false) = false
    )
    and (
      public.is_app_admin(p_user_id)
      or public.is_league_member(p_league_id, p_user_id)
    );
$$;

grant execute on function public.can_use_league_chat(uuid, uuid) to authenticated;

drop policy if exists "league_messages_select" on public.league_messages;
create policy "league_messages_select"
  on public.league_messages for select
  to authenticated
  using (public.can_use_league_chat(league_id));

drop policy if exists "league_messages_insert" on public.league_messages;
create policy "league_messages_insert"
  on public.league_messages for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.can_use_league_chat(league_id)
  );

drop policy if exists "league_messages_delete" on public.league_messages;
create policy "league_messages_delete"
  on public.league_messages for delete
  to authenticated
  using (
    public.can_use_league_chat(league_id)
    and (
      user_id = auth.uid()
      or public.is_league_commissioner(league_id)
      or public.is_app_admin()
    )
  );

drop policy if exists "league_chat_reads_select_own" on public.league_chat_reads;
create policy "league_chat_reads_select_own"
  on public.league_chat_reads for select
  to authenticated
  using (user_id = auth.uid() and public.can_use_league_chat(league_id));

drop policy if exists "league_chat_reads_insert_own" on public.league_chat_reads;
create policy "league_chat_reads_insert_own"
  on public.league_chat_reads for insert
  to authenticated
  with check (user_id = auth.uid() and public.can_use_league_chat(league_id));

drop policy if exists "league_chat_reads_update_own" on public.league_chat_reads;
create policy "league_chat_reads_update_own"
  on public.league_chat_reads for update
  to authenticated
  using (user_id = auth.uid() and public.can_use_league_chat(league_id))
  with check (user_id = auth.uid() and public.can_use_league_chat(league_id));

grant select, insert, delete on public.league_messages to authenticated;
grant select, insert, update on public.league_chat_reads to authenticated;

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------
create or replace function public.league_list_messages(
  p_league_id uuid,
  p_before timestamptz default null,
  p_limit integer default 30
)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  avatar_key text,
  body text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_limit integer;
begin
  if not public.can_use_league_chat(p_league_id) then
    raise exception 'Not authorized';
  end if;

  v_limit := least(greatest(coalesce(p_limit, 30), 1), 50);

  return query
  select
    m.id,
    m.user_id,
    coalesce(p.display_name, 'Unknown') as display_name,
    p.avatar_key,
    m.body,
    m.created_at
  from public.league_messages m
  left join public.profiles p on p.id = m.user_id
  where m.league_id = p_league_id
    and (p_before is null or m.created_at < p_before)
  order by m.created_at desc
  limit v_limit;
end;
$$;

grant execute on function public.league_list_messages(uuid, timestamptz, integer) to authenticated;

create or replace function public.league_chat_unread_count(p_league_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_last_read timestamptz;
  v_count integer;
begin
  if not public.can_use_league_chat(p_league_id) then
    raise exception 'Not authorized';
  end if;

  select r.last_read_at
    into v_last_read
  from public.league_chat_reads r
  where r.league_id = p_league_id
    and r.user_id = auth.uid();

  select count(*)::integer
    into v_count
  from public.league_messages m
  where m.league_id = p_league_id
    and m.user_id is distinct from auth.uid()
    and (v_last_read is null or m.created_at > v_last_read);

  return coalesce(v_count, 0);
end;
$$;

grant execute on function public.league_chat_unread_count(uuid) to authenticated;

create or replace function public.league_chat_mark_read(p_league_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_use_league_chat(p_league_id) then
    raise exception 'Not authorized';
  end if;

  insert into public.league_chat_reads (league_id, user_id, last_read_at)
  values (p_league_id, auth.uid(), now())
  on conflict (league_id, user_id) do update
  set last_read_at = now();
end;
$$;

grant execute on function public.league_chat_mark_read(uuid) to authenticated;
