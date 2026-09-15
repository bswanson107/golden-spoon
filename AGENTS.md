# AGENTS.md

## Cursor Cloud specific instructions

Golden Spoon is a SvelteKit 2 / Svelte 5 SPA (Vite) that talks directly to a
Supabase backend (Postgres + Auth + RLS). For local development in Cloud we run
a **local Supabase stack** (via the Supabase CLI + Docker) instead of the shared
hosted project. Standard scripts live in `package.json`; the README covers the
generic SvelteKit commands. The notes below are the non-obvious bits.

### Services

| Service | Command | URL / Port | Required |
| --- | --- | --- | --- |
| SvelteKit dev server (the app) | `npm run dev` | http://localhost:5173 | Yes |
| Local Supabase (Postgres/Auth/PostgREST/Studio/Mailpit) | `supabase start` | API http://127.0.0.1:54321, Studio :54323, Mailpit :54324 | Yes |
| NFL data sync (nflverse) | `npm run sync:nfl` | — | No (seed migrations already load 2025/2026 games) |

### Startup sequence (nothing auto-starts on boot)

The update script only refreshes npm deps. Docker, Supabase, and the dev server
must be started manually each session:

1. **Start Docker** (the daemon is not running on boot; Docker/Supabase CLI and
   the pulled images are already installed):
   `sudo dockerd > /tmp/dockerd.log 2>&1 &` then `sudo chmod 666 /var/run/docker.sock`.
   `/etc/docker/daemon.json` is preconfigured for `fuse-overlayfs` with
   `containerd-snapshotter` disabled (required for Docker 29 in this VM).
2. **Start Supabase:** run `supabase start` from the repo root. On a fresh
   database it auto-applies every file in `supabase/migrations/` in order.
3. **Create `.env`** (gitignored, so may be missing on a fresh checkout) with the
   local Supabase URL + anon key, then run `npm run dev`:
   ```
   PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
   PUBLIC_SUPABASE_ANON_KEY=<ANON_KEY from `supabase status`>
   ```
   The local anon key is the fixed Supabase demo JWT and is stable across
   restarts. `supabase status -o env` prints the current values.

### Non-obvious gotchas

- **Two bootstrap migrations exist for fresh Supabase stacks** and are NOT part
  of the original hosted schema:
  - `000_profiles_bootstrap.sql` — creates `public.profiles`. Migration `001`
    assumes it already exists "from setup" (the hosted project created it via the
    Supabase "User Management" starter before the numbered migrations).
  - `028_grant_api_roles.sql` — grants `public`-schema access to `anon` /
    `authenticated`. Modern Supabase (CLI 2.x / PG 17) does not auto-grant DML to
    the API roles; without this every query fails with
    `permission denied for table ...`. RLS (enabled in `001`) is still the
    gatekeeper. Both files are idempotent and inert on the existing hosted DB.
- **Seed data:** migrations `004`/`007` seed 2025/2026 NFL games and `005` seeds a
  demo "Scag" pool (join code `scag2025`). New leagues default to season 2026;
  Week 1 2026 games have win probabilities set, so picks work without running the
  NFL sync.
- **Picks require win probability + a future kickoff.** The `enforce_pick_rules`
  DB trigger rejects a pick if the picked team's win % is null or the game has
  kicked off. Only games with `home_win_pct`/`away_win_pct` populated are pickable.
- **Auth:** local email confirmations are disabled, so signups log in immediately
  (no email step). Any confirmation/magic-link emails are captured by Mailpit at
  http://127.0.0.1:54324 (nothing is sent externally).
- **New users land on the public demo league** after signup (see
  `026_public_demo_league.sql`); go to `/leagues` to manage your own leagues.
- **Resetting DB state:** `supabase db reset` re-applies all migrations from
  scratch. Existing auth sessions in the browser become invalid afterward — clear
  site data / sign out to avoid stale `league_members_user_id_fkey` errors from a
  now-deleted user.
- **Migrations affect production** (hosted project is shared). Apply new
  migrations to the hosted DB manually; the deploy workflow does not run them.
- **Lint/check:** `npm run check` (svelte-check). Build: `npm run build`
  (static SPA output to `build/`).
