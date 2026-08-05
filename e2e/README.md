# Playwright E2E suite

Lean end-to-end tests against the **live** Supabase project using QA Mode simulated time.

## Prerequisites

1. Apply the E2E admin migration (once):

   ```bash
   npm run db:apply-e2e-admin
   ```

2. Authenticated `gh` CLI for the repo (workflow pause/resume). Global setup
   disables **Sync NFL Data**; teardown re-enables it only if this run disabled it.
   Opt out with `E2E_SKIP_WORKFLOW_PAUSE=1`.

3. Create `.env.e2e` from `.env.e2e.example` with:

   - `E2E_ADMIN_EMAIL` / `E2E_ADMIN_PASSWORD` — `gs-e2e-admin@gs-e2e-admin.com`
   - `E2E_ADMIN_NAME` — that user's `profiles.display_name` (defaults to `gs-e2e-admin` on signup)
   - `E2E_PLAYER2_EMAIL` / `E2E_PLAYER2_PASSWORD` / `E2E_PLAYER2_NAME` — a non-admin test user
   - App keys in `.env` or `.env.e2e`: `PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_ANON_KEY`

4. Install browsers once: `npx playwright install chromium`

## Run

```bash
npm run test:e2e
# or interactive UI
npm run test:e2e:ui
```

The suite starts `vite dev`, pauses the Sync NFL Data cron (via `gh`), stubs the
`sync-nfl-data` edge function in-browser, creates ephemeral `E2E …` leagues per
file, and tears them down afterward.

## Specs

| File | Covers |
|------|--------|
| `deadlines.spec.ts` | Pick deadline locking (§1) |
| `visibility.spec.ts` | Hidden / open pick visibility (§2) |
| `auto-mnf.spec.ts` | Auto-MNF assignment + missed fallback (§3) |
| `scoring.spec.ts` | Underdog points, kickoff re-lock, ties (§4–5) |
| `rules.spec.ts` | Team reuse (move vs locked) + QA banner (§6–7) |
