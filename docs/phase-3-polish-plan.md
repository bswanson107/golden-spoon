# Phase 3: Family-Ready Polish

## Goal

Make Golden Spoon feel like a finished product for family members who are not
tech-savvy and may check it only once a week. Phase 3 covers three areas:
(1) in-app rules and onboarding so nobody asks "how does scoring work?",
(2) pick grid UX improvements that make secrecy and missing picks legible at a
glance, and (3) a lightweight pick reminder flow so the commissioner doesn't
have to text everyone on Sunday morning.

None of Phase 3 requires new migrations. All writes use existing tables and RLS
policies.

---

## Architecture

```
All Phase 3 features are pure frontend additions or lightweight Supabase
Database reads. No new Edge Functions or RPCs are required.

New routes:
  /league/[id]/rules       ← in-app rules page (static + league-specific config)
  /account                 ← display name edit (reads/writes profiles table)

Enhanced components:
  PicksGrid.svelte          ← distinguish hidden vs no-pick states
  +page.svelte (league)    ← "make your pick" CTA + deadline context
```

---

## Scope

| Task | Description |
|------|-------------|
| **TASK 1** | `src/routes/account/+page.svelte` — display name edit |
| **TASK 2** | `src/routes/league/[id]/rules/+page.svelte` — in-app rules page |
| **TASK 3** | "Make your pick" CTA with deadline context on the league page |
| **TASK 4** | Pick grid secrecy UX — distinguish hidden vs no-pick |
| **TASK 5** | Week navigator on the league page for live season |
| **TASK 6** | Commissioner reminder list — "players who haven't picked" |

---

## New Files

```
src/routes/
  account/
    +page.svelte              ← display name + account settings

  league/[id]/
    rules/
      +page.svelte            ← rules page

src/lib/
  components/
    league/
      PickReminderPanel.svelte  ← Task 6: missing-picks list for commissioner
```

---

## Task Breakdown

---

### TASK 1 — Display name edit: `src/routes/account/+page.svelte`

**Why**: Profiles are seeded with `split_part(email, '@', 1)` as the display
name (see migration 001). Most family members won't recognise each other's
email prefixes — Grandma wants to see "Grandma" in the standings.

**DB**: `profiles` table has `display_name text`. The `profiles_update_own`
RLS policy already allows a user to update their own row. No migration needed.

**UI**:
- Single text input: "Your display name"
- Save button
- Success / error message
- Pre-populated with current value from `auth.user` or `profiles` row

**Data flow**:
```ts
// Read
const { data: profile } = await supabase
  .from('profiles')
  .select('display_name')
  .eq('id', auth.user.id)
  .single();

// Write
const { error } = await supabase
  .from('profiles')
  .update({ display_name: newName.trim() })
  .eq('id', auth.user.id);
```

**Navigation**: Add an **Account** link in the app header / nav (currently not
present). A simple user icon → dropdown with "Account" and "Sign out" is
sufficient for Phase 3.

**Acceptance**: User changes display name; standings and picks grid immediately
show the new name for all leagues (the `league_standings` view joins
`profiles.display_name` dynamically).

---

### TASK 2 — In-app rules page: `src/routes/league/[id]/rules/+page.svelte`

**Why**: Family members will ask "what is an underdog?" and "what happens if I
miss a pick?". A rules page in the app, linked from the league page, is cleaner
than sharing a PDF.

**Content** (derived from `docs/mvp-rules.md`):
- **Scoring**: Win = 1 pt; Underdog win = 2 pts; Loss = 0 pts; Tie = 0.5 pts;
  No pick = 0 pts
- **Underdog definition**: Team with win probability ≤ 33% at kickoff
- **Pick deadline**: Before the picked team's game kicks off (not midnight Sunday)
- **Pick secrecy**: Your pick is hidden until your game kicks off
- **Team reuse**: Each team can only be picked once per season
- **Missed picks**: Automatically recorded as 0 pts after the week's last kickoff
- **Tiebreaker**: Lower cumulative season wins of your picked teams wins the tie
  (rewards picking weaker teams)
- **Postponed games**: Original pick stands; scored when played
- **Season scope**: Regular season only (Weeks 1–18)

**League-specific values** (read from `leagues` table):
- Underdog threshold (`underdog_threshold_pct`) — show the actual configured %
- Season year

**Format**: Structured HTML with `<section>` and `<details>` elements.
No dynamic data except the league's underdog threshold. Keep it scannable
with bolded key terms.

**Navigation**: Add a **Rules** link in the league page nav alongside
Standings / Picks.

---

### TASK 3 — "Make your pick" CTA with deadline context

**Why**: The league page currently shows standings and the picks grid but no
prominent call-to-action for users who haven't submitted this week's pick.

**Where**: `src/routes/league/[id]/+page.svelte`, near the top of the page for
live leagues, below the league header.

**Logic**:
1. Determine the current week (already available from `getCurrentWeekFromDate`
   in `src/lib/season.ts` after Phase 1).
2. Check if the current user has a non-superseded pick for that week in this
   league (from `picks` already loaded for the standings/grid).
3. Find the **first game kickoff** of that week (from games data) — that is the
   pick deadline for Thursday games.

**Display**:
- **No pick yet**: Prominent banner/card: `"Week {N} · pick before {day} {time} ET"`
  with a **Make your pick →** button linking to `/league/{id}/pick`.
- **Pick submitted**: Subtle confirmation: `"Week {N} pick submitted ✓"` with
  the team name (if the game has kicked off and pick is visible, or "pick
  locked in" if not yet).
- **All games kicked off**: No CTA — week is closed.

**Deadline format helper** (add to `src/lib/gameKickoff.ts` or a new util):
```ts
/** "Thu Sep 11 · 8:20 PM ET" */
export function formatPickDeadline(kickoffIso: string): string {
  return new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/New_York',
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(kickoffIso)) + ' ET';
}
```

**Acceptance**: A user who hasn't picked sees the deadline banner. A user who
has picked sees confirmation. The CTA disappears once the week's first game
kicks off.

---

### TASK 4 — Pick grid secrecy UX

**Why**: The current picks grid shows an empty cell for both "no pick yet" and
"pick hidden until kickoff". These are meaningfully different states and family
members find the empty grid confusing.

**Current behaviour** (from `PicksGrid.svelte`): Hidden picks show nothing;
missing picks show nothing.

**Target behaviour**:

| State | Display |
|-------|---------|
| Pick submitted, game not kicked off yet | Lock icon (🔒) or greyed "locked" text |
| Pick submitted, game kicked off | Team abbreviation / logo (existing) |
| No pick submitted, deadline not passed | Empty cell (existing) |
| No pick submitted, deadline passed (missed) | `—` or "missed" label in muted red |
| Commissioner override | Small ✎ badge on the cell |

**Implementation notes**:
- The `league_picks` query already returns `outcome` and `is_missed` per pick.
- Kickoff times for the displayed week are already loaded for the picks grid
  (or can be loaded alongside).
- Use a derived map of `gameId → kickoffAt` to determine whether a game has
  kicked off yet.
- A pick where `superseded_by_pick_id is null` and the game hasn't kicked off
  is "locked in but hidden". This requires knowing the game's kickoff time —
  the grid currently shows picks without game context. Load game kickoffs
  alongside picks.

**Acceptance**: Commissioner can distinguish at a glance who has picked
(locked), who hasn't (empty), and who missed (missed label). Players can see
their own pick is locked in without seeing others' picks.

---

### TASK 5 — Week navigator on the league page

**Why**: During the season the league page defaults to showing all picks, but
family members want to quickly check "what happened in Week 3?".

This task is marked **optional** in the prompt — implement after Tasks 1–4 are
stable.

**Where**: The week navigator component (`WeekNavigator.svelte`) already exists
and is used on the pick page. Wire it up on the league page to filter the picks
grid and standings display by week.

**Behaviour**:
- Default to the current week (from `getCurrentWeekFromDate`).
- Navigating to a previous week shows that week's picks grid and the standings
  *as they stood after that week* (cumulative points through that week).
- "All weeks" / "Season" view remains as the default for standings.

**Implementation notes**:
- `fetchLeaguePicks` already accepts a week filter in some form — check the
  existing query in `src/lib/standings.ts` and add a `weekNumber` parameter if
  not present.
- Season-to-date standings always show full cumulative totals regardless of
  which week is selected in the grid.

---

### TASK 6 — Commissioner reminder list

**Why**: The single most common failure mode in family pools is someone
forgetting to pick. The commissioner needs a quick way to see who hasn't picked
this week and nudge them (via text, family group chat, etc.).

**Where**: Add to `src/routes/league/[id]/admin/+page.svelte` (Phase 2 admin
page) as a new panel, or as a standalone card visible to the commissioner on
the main league page.

**Data**: Derived from existing picks + league members:

```ts
/** Returns members who have no active pick for the given week. */
export function getMissingPickers(
  members: StandingRow[],     // all league members with display_name
  picks: LeaguePick[],        // all active picks for the league
  weekNumber: number
): StandingRow[] {
  const pickedUserIds = new Set(
    picks
      .filter((p) => p.week_number === weekNumber && p.superseded_by_pick_id === null && !p.is_missed)
      .map((p) => p.user_id)
  );
  return members.filter((m) => !pickedUserIds.has(m.user_id));
}
```

**UI** (`PickReminderPanel.svelte`):
- Heading: `"Week {N} — {N} player(s) haven't picked yet"`
- List of display names
- A **Copy names** button that copies the list to the clipboard (for pasting
  into a group chat)
- Only visible to the commissioner; only shown before the week's last kickoff

**Acceptance**: Commissioner opens the league page (or admin page), sees who is
missing a pick for the current week, and can copy names to send a nudge.

---

## Known Open Questions

| # | Question | Recommendation |
|---|----------|----------------|
| 1 | Should the rules page be league-specific (shows configured underdog %) or generic? | League-specific — fetch `underdog_threshold_pct` from the league row on load. |
| 2 | Account page: scope to display name only, or add email change / password reset? | Display name only for Phase 3; auth flows (email/password change) are Supabase Auth UI territory and out of scope. |
| 3 | Pick grid: should locked picks show a team logo or just a lock icon? | Lock icon only — showing any indicator that reveals team identity before kickoff would break secrecy rules. |
| 4 | Reminder: email vs in-app list? | In-app list (copy-to-clipboard) is zero infrastructure. Email requires a sending service (Resend, SendGrid, etc.) — Phase 4. |
| 5 | Week navigator on league page: filter standings too, or grid only? | Grid only in Phase 3 — filtered standings require cumulative aggregation through a week boundary, which is more complex. |

---

## What Is Explicitly Out of Scope for Phase 3

- Email or push notifications (infrastructure required; Phase 4)
- Postponed-game repick UI (requires pick mutation flow)
- Playoff support (regular season only per mvp-rules.md)
- PWA / install prompt
- Automated test suite

---

## Execution Order

```
TASK 1  →  /account page (display name) — highest family friction, do first
TASK 2  →  /league/[id]/rules — content is all static, fast to ship
TASK 3  →  "Make your pick" CTA on league page
TASK 4  →  Pick grid secrecy UX (hidden vs missing vs missed)
TASK 5  →  Week navigator on league page (optional, after Tasks 1–4 stable)
TASK 6  →  Commissioner reminder list (add to Phase 2 admin page)
```
