-- Golden Spoon — allow the dedicated E2E service account as an app admin
--
-- Keeps the existing local-part rule for the personal admin and additionally
-- matches the full lowercased email of the Playwright service account so QA
-- Mode RPCs and admin tools work without using a personal login in tests.

create or replace function public.is_app_admin(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from auth.users u
    where u.id = p_user_id
      and (
        split_part(lower(u.email), '@', 1) = 'bswanson107'
        or lower(u.email) = 'gs-e2e-admin@gs-e2e-admin.com'
      )
  );
$$;
