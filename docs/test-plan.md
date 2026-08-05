# Golden Spoon — QA Mode Test Plan

A checklist of scenarios to run **before any real league is created**, using the
QA Mode harness at `/qa` (admin only). QA Mode lets you freeze "now" to any
minute and simulate game outcomes / win % without the live nflverse feed.

## Automated E2E

A lean Playwright suite lives in [`e2e/`](../e2e/) and covers the highest-value
items below with simulated time. See [`e2e/README.md`](../e2e/README.md).

| Automated | Manual checklist IDs |
|-----------|----------------------|
| Deadlines | 1.1, 1.2, 1.3, 1.4, 1.9 |
| Visibility | 2.1, 2.2 (after reload), 2.3, 2.4 |
| Auto-MNF / missed | 3.1, 3.3, 3.4, 3.6, 3.7 |
| Scoring | 4.1, 4.2, 4.3, 5.3 |
| Rules / clock | 6.1, 6.3, 7.3 (both reuse cases) |

Everything else in this document stays manual exploratory QA.

> Testing happens against the live Supabase project. This is intentional while
> there are no real leagues. The Playwright suite **disables the "Sync NFL Data"
> workflow** in global setup and re-enables it in teardown (requires `gh` auth).
> For manual QA Mode runs, pause it yourself:
>
> - GitHub UI: repo → **Actions** tab → **Sync NFL Data** → **⋯** menu →
>   **Disable workflow**. (Re-enable the same way when you're done.)
> - Or CLI: `gh workflow disable "Sync NFL Data"` (re-enable with
>   `gh workflow enable "Sync NFL Data"`).
>
> Note: this stops the cron only. The pick page also triggers a sync from the
> browser in live mode, which can re-fetch nflverse. While the QA clock is
> enabled, avoid opening a live league's pick page on a non-test league, or
> simulate on a season year your test leagues don't share.

## How QA Mode works (mental model)

- **Clock** — `/qa` writes a `simulated_now` to the `qa_clock` row. `qa_now()`
  (DB) and `qaNow()` (browser) both return it while enabled, so pick deadlines
  (trigger), pick visibility / update / delete (RLS), and all UI week/kickoff
  logic obey the simulated minute. "Reset to live" returns to wall-clock time.
- **Outcomes** — `Simulate week` / per-game `Home/Away/Tie` mark games `final`
  and fire the scoring trigger. Default week simulation is **home team wins**.
- **Win %** — per-game win % override changes underdog classification. Scoring
  uses the snapshot on the pick (`is_underdog_at_pick`), which is set at pick
  time and **re-locked at kickoff** by "Run week processing".
- **Run week processing** — runs the side effects in-database via a SQL RPC
  (`qa_run_processing`): kickoff win-% lock + auto-MNF / missed assignment +
  scoring, against the simulated clock. No edge-function deploy required.
- **Reset week / season** — returns games to `scheduled` and non-override picks
  to `pending`, and deletes auto-assigned + missed picks, so a week can be
  replayed.

## Suggested standing setup

1. Sign in as the app admin; open `/qa`. Confirm the red **QA Mode** banner.
2. Create 2 test leagues for season 2026:
   - League A: `pick_visibility = hidden_until_kickoff`, threshold 33.
   - League B: `pick_visibility = open`, threshold 33.
3. Have at least 2 test users join each league.
4. Pick a target week (e.g. Week 1). Note its first kickoff (TNF) and last
   kickoff (MNF) from the `/qa` games table.

Each scenario lists **Setup → Action → Expected**. Check the box when verified.

---

## 1. Pick deadline locking (time travel)

- [ ] **1.1 Before any kickoff** — Set clock to 1 hour before the week's first
  kickoff. Open the pick page. *Expected:* every game is selectable.
- [ ] **1.2 Exact kickoff minute (boundary)** — Use the game row "Jump to week
  first kickoff" so `qa_now == kickoff_at`. Try to pick that game. *Expected:*
  rejected ("Pick deadline passed"); deadline is `<=`, so the exact minute is
  already locked.
- [ ] **1.3 One minute before** — Set clock to first kickoff minus 1 minute.
  *Expected:* that game is still selectable.
- [ ] **1.4 After TNF kickoff, before it ends** — Set clock to TNF kickoff + 30
  min. *Expected:* the TNF game is locked, but all Sunday/Monday games remain
  selectable; you can still submit a pick on another game.
- [ ] **1.5 Switch between not-started games** — In state 1.4, with no pick yet,
  pick a Sunday game, then change to a different Sunday game. *Expected:*
  allowed.
- [ ] **1.6 Cannot change a pick whose game started** — Pick the TNF game while
  clock is before kickoff, then advance clock past TNF kickoff and try to change
  it. *Expected:* change rejected (update RLS).
- [ ] **1.7 Cannot delete a started pick** — Same as 1.6 but attempt to clear/
  delete the pick. *Expected:* rejected (delete RLS).
- [ ] **1.8 Mid-Sunday** — Set clock between the 1pm and 4pm kickoffs. *Expected:*
  1pm games locked, 4pm + MNF games still selectable.
- [ ] **1.9 After final kickoff** — Set clock to MNF kickoff + 1 min. *Expected:*
  no games selectable; pick CTA shows the week as closed.

## 2. Pick visibility

- [ ] **2.1 Hidden until kickoff** — In League A, two users pick different
  games. With clock before all kickoffs, each user sees only their own pick;
  others show as "submitted/hidden". *Expected:* opponents' teams hidden.
- [ ] **2.2 Reveal at kickoff (reactive)** — Keep the picks grid open and set the
  clock to a picked game's kickoff minute. *Expected:* that pick becomes visible
  without a page reload (PicksGrid reacts to the QA clock).
- [ ] **2.3 Open league** — In League B, a second user's pick is visible
  immediately, even before kickoff.
- [ ] **2.4 Own pick always visible** — In League A (hidden), submit a pick with
  the clock **before** its kickoff, then open the Weekly picks grid. *Expected:*
  your own cell shows your team (never a 🔒 lock), even though opponents' picks
  are hidden.

## 3. Missed picks → auto-assigned MNF home team

When a week's slate locks and a member has no pick, they are **assigned the
week's final (MNF) game home team as a real, scoring pick** — unless they have
already used that team this season, in which case they get a 0-point **missed**
indicator. This runs in **Run week processing** (and the live cron sync).

- [ ] **3.1 Auto-assign MNF home team** — In League A, leave User2 with no pick.
  Set clock to MNF kickoff + 1 min and click **Run week processing**. *Expected:*
  User2's week cell shows the **MNF home team** as a normal visible pick with
  `is_auto_pick` (E2E asserts `data-auto="true"`; there is no separate "A" badge
  in the grid today). Once that game is final, the pick scores like a normal pick
  (win/loss/tie per the MNF result and underdog rules).
- [ ] **3.2 Auto pick scores after the fact** — If you run processing *before*
  simulating the MNF game, the auto pick shows as pending; after you simulate the
  MNF game final it resolves to win/loss/tie with the right points.
- [ ] **3.3 Falls back to missed when team already used** — Have User2 use the
  MNF home team in an earlier week, then miss this week. Run processing.
  *Expected:* User2 gets the **missed ×** indicator (0 points), because the MNF
  home team can't be reused.
- [ ] **3.4 Picker is unaffected** — User1 (who picked) keeps their own pick; no
  auto/missed row is added for them.
- [ ] **3.5 Auto pick consumes the team** — After an auto-assigned MNF pick, the
  same team **cannot** be picked again later in the season (counts as used).
- [ ] **3.6 Idempotent** — Run week processing again. *Expected:* no duplicate
  auto/missed rows for the same member/week.
- [ ] **3.7 Every cell filled when a week is over** — After a week's final game is
  determined and processing has run, **every** player has a value in that week's
  column: their team, the auto-assigned MNF home team (A), or the missed ×.

## 4. Underdog snapshot + kickoff re-lock

- [ ] **4.1 Favorite win = 1 pt** — Override a game so the picked team is 60%.
  Pick it (clock before kickoff). Simulate that game as a win for the picked
  team. *Expected:* outcome win, **1 point**, not flagged underdog.
- [ ] **4.2 Underdog win = 2 pts** — Override a game so the picked team is 28%.
  Pick it; simulate a win. *Expected:* win, **2 points**, flagged underdog.
- [ ] **4.3 Odds flip to underdog after pick (key case)** — Pick a team while it
  is a favorite (e.g. 60%). Then on `/qa` override that game's win % so the
  picked team drops to **30%**. Advance the clock past that game's kickoff and
  click **Run week processing**. *Expected:* the pick's `is_underdog_at_pick`
  flips to **true** (kickoff re-lock). Simulate a win → **2 points**.
- [ ] **4.4 Odds flip to favorite after pick** — Pick an underdog (28%), then
  override win % to 60% and run processing past kickoff. *Expected:* re-locked
  to **not** underdog; a win scores **1 point** (lock uses kickoff-time odds).
- [ ] **4.5 Threshold boundary** — With league threshold 33, override picked
  team to exactly **33.00%**. *Expected:* underdog (rule is `<=`). Override to
  **33.01%** → not underdog.
- [ ] **4.6 Missing win %** — Override both win % to blank/null is not possible
  via UI; instead confirm that a pick on a game with no odds defaults to 50%
  (not underdog at threshold 33).
- [ ] **4.7 Per-league threshold** — Create a league with threshold 40 and one
  with 25. Same 30% team is underdog in the 40 league, not in the 25 league.

## 5. Scoring & replay

- [ ] **5.1 Default home wins** — Reset the week, ensure picks exist on both home
  and away sides, then **Simulate week → Default: home wins**. *Expected:*
  home-pickers `win`, away-pickers `loss`; points and standings update.
- [ ] **5.2 Override to away win** — Use a game row's **Away** button.
  *Expected:* away-pickers win, home-pickers loss for that game.
- [ ] **5.3 Tie = 0.5** — Use **Tie** on a game. *Expected:* both pickers get
  0.5 points.
- [ ] **5.4 Replay without double counting** — **Reset week**, then simulate a
  different result. *Expected:* picks return to pending on reset, then re-score
  cleanly; no stale/doubled points.
- [ ] **5.5 Commissioner override preserved** — In the league admin page,
  override a pick's outcome/points. Re-simulate the week. *Expected:* the
  commissioner-overridden pick is **not** changed by re-scoring.

## 6. Week / season indicator

- [ ] **6.1 Mid-season week** — Set clock into Week 3's date range. *Expected:*
  the header season badge and the default view week show Week 3 (after a
  navigation).
- [ ] **6.2 Before season** — Set clock before the Week 1 opener. *Expected:*
  Week 1.
- [ ] **6.3 Reset to live** — Click "Reset to live". *Expected:* badge returns to
  the real current week and the QA banner disappears.

## 7. Rules lock & team reuse

- [ ] **7.1 Rules editable before first pick** — In a fresh league, edit underdog
  threshold / tiebreaker / visibility. *Expected:* allowed.
- [ ] **7.2 Rules locked after first pick** — Submit one pick, then try to edit
  rules. *Expected:* rejected ("Rules are locked after the first pick").
- [ ] **7.3 Team reuse — unplayed week (move)** — While simulated time is still in
  Week 1, pick Team X in Week 2, then open Week 3 and tap Team X again.
  *Expected:* `Change team selection?` opens; Cancel leaves Week 2 intact;
  Continue moves the pick to Week 3 (Week 2 empty). Team X is used once.
- [ ] **7.3b Team reuse — locked week (refused)** — Pick Team X in Week 1, advance
  the clock past that game's kickoff, then open Week 2 and try Team X.
  *Expected:* the button is disabled (`Locked — picked Week 1`); the dialog does
  **not** open; Week 2 stays empty.

## 8. Weekly picks grid (column reveal)

- [ ] **8a.1 Only the current week early on** — With no week complete, the Weekly
  picks grid shows **only the current week** column.
- [ ] **8a.2 Next column on completion** — Simulate the current week's final
  (MNF) game and reload. *Expected:* the next week's column appears, but no
  columns beyond it.
- [ ] **8a.3 No future columns** — Confirm weeks beyond the first not-yet-complete
  week are never shown (no empty week 5–18 columns early in the season).
- [ ] **8a.4 Completed weeks stay** — All previously completed weeks remain
  visible alongside the current week.

## 9. Multi-league / edge cases

- [ ] **8.1 Member of two leagues** — A user in both League A and B makes
  independent picks; results in one do not affect the other.
- [ ] **8.2 Postponed game** — (If testable) a postponed game with a future
  kickoff remains pickable; repick flow works.
- [ ] **8.3 Disabled clock = live** — With QA clock disabled, confirm the app
  behaves on real wall-clock time (no banner, deadlines use real `now()`).

---

## Teardown

1. On `/qa`: **Reset season** to return all 2026 games to `scheduled` and clear
   simulated picks/outcomes.
2. Click **Reset to live** to disable the QA clock.
3. Remove the test leagues / users if desired.
4. Re-enable the GitHub Actions "Sync NFL Data" workflow before the real season.

## Notes / known behaviors

- `qa_now()` only affects deadline + visibility logic and the UI clock. Audit
  `updated_at` timestamps still use real `now()`.
- Re-simulating a week without resetting first will **not** rescore picks that
  are already `win`/`loss` (the scorer only touches `pending`). Always **Reset
  week** before replaying with a different outcome.
- Changing the clock (Set clock, the jump buttons, ±) **auto-runs processing**
  for every active season, so any week whose last kickoff has passed is closed
  out immediately: pending picks get their kickoff win-%/underdog snapshot, and
  members with no pick get the MNF home team (or the missed indicator). The
  manual "Run week processing" button does the same thing on demand.
- Simulating a game `final` alone does not lock `is_underdog_at_pick`; advancing
  the clock past kickoff (or running processing) does.
- Missed weeks no longer mean an automatic 0: a member with no pick is assigned
  the week's MNF home team as a real scoring pick (`is_auto_pick`; grid has no
  separate "A" badge today), unless they've already used that team this season —
  then it's a 0-point missed (×).
- Team reuse: if the earlier week's game has not kicked off, re-selecting that
  team in a later week opens a move confirmation. If the earlier game has
  kicked off, the team is disabled and cannot be moved.
- `Reset week` / `Reset season` also delete auto-assigned and missed rows for the
  scope so a week can be replayed cleanly.
