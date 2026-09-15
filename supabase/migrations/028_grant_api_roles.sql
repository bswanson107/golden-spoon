-- Golden Spoon — grant public-schema access to the PostgREST API roles (local/dev)
--
-- Newer Supabase stacks (CLI 2.x / Postgres 17) no longer grant DML on new
-- public tables to `anon` / `authenticated` by default — Row Level Security is
-- the gatekeeper, and table-level privileges must be granted explicitly. The
-- hosted project this app was originally built against predates that change, so
-- its tables already carry these grants and the numbered migrations never added
-- them. A freshly provisioned stack (`supabase start` / `supabase db reset`, or
-- a brand-new hosted project) needs them, otherwise every query fails with
-- "permission denied for table ...".
--
-- These are the standard Supabase API-role grants. Every table in this schema
-- has RLS enabled (see 001_initial_schema.sql), so access is still governed by
-- the RLS policies, not by these grants. Idempotent and safe to re-run.
grant usage on schema public to anon, authenticated, service_role;

grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
grant all on all routines in schema public to anon, authenticated, service_role;

alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on routines to anon, authenticated, service_role;
