-- Golden Spoon — profiles bootstrap (local/dev)
--
-- Migration 001 assumes `public.profiles` already exists "from setup": in the
-- hosted project it was created by Supabase's "User Management" starter before
-- the numbered migrations were applied. A fresh local stack (`supabase start`
-- / `supabase db reset`) has no such table, so migration 001 fails.
--
-- This migration recreates that minimal starter table. It is idempotent and
-- guarded with `if not exists`, so it is a no-op on any project where
-- `public.profiles` already exists (e.g. production).
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text
);
