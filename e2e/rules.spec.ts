import { test, expect } from './fixtures';
import { openLeague, openPickPage, pickTeam, type CreatedLeague } from './helpers/league';
import { provisionLeague, teardownLeague } from './helpers/lifecycle';
import { openQa, resetToLive, resetWeek, selectSeasonWeek, setClock, syncClock } from './helpers/qa';
import {
	getCurrentWeekFromDate,
	SEASON_2026_WEEK1_START,
	SEASON_YEAR,
	WEEK1,
	WEEK2,
	WEEK3
} from './helpers/seedData';

test.describe.configure({ mode: 'serial' });

let league: CreatedLeague;

test.beforeAll(async ({ browser }) => {
	league = await provisionLeague(browser, { tag: 'rules', visibility: 'hidden_until_kickoff' });
});

test.afterAll(async ({ browser }) => {
	await teardownLeague(browser, league);
});

test('reuse of an unplayed week is allowed and moves the pick', async ({ adminPage }) => {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await resetWeek(adminPage, SEASON_YEAR, 2);
	await resetWeek(adminPage, SEASON_YEAR, 3);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 2);
	await pickTeam(adminPage, WEEK2.sundayCleTb.away); // CLE
	await expect(adminPage.locator('.pick-status')).toContainText('Current pick · CLE');

	await openPickPage(adminPage, league.id, 3);
	const cle = adminPage.locator(`button[data-team-id="${WEEK3.sundayCarCle.home}"]`);
	await expect(cle).toBeEnabled();
	await expect(cle.getByText(/Picked WK 2/i)).toBeVisible();

	await cle.click();
	const dialog = adminPage.getByRole('dialog');
	await expect(dialog).toContainText('Change team selection?');
	await expect(dialog).toContainText('Week 2');
	await dialog.getByRole('button', { name: 'Cancel' }).click();
	await expect(dialog).toHaveCount(0);

	await openPickPage(adminPage, league.id, 2);
	await expect(adminPage.locator('.pick-status')).toContainText('Current pick · CLE');
	await openPickPage(adminPage, league.id, 3);
	// Week still open → empty pick shows the choose prompt, not the locked "No pick" copy.
	await expect(adminPage.locator('.pick-status')).toContainText('Choose a team below');

	await cle.click();
	await adminPage.getByRole('dialog').getByRole('button', { name: 'Continue' }).click();
	await expect(adminPage.locator('.pick-status')).toContainText('Current pick · CLE');
	await expect(adminPage.locator('p.pick-error')).toHaveCount(0);

	await openPickPage(adminPage, league.id, 2);
	await expect(adminPage.locator('.pick-status')).toContainText('Choose a team below');
});

test('reuse of a locked week is refused with no dialog', async ({ adminPage }) => {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await resetWeek(adminPage, SEASON_YEAR, 2);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 1);
	await pickTeam(adminPage, WEEK1.sundayCleJax.away); // CLE

	await openQa(adminPage);
	await setClock(adminPage, new Date(WEEK1.sundayCleJax.kickoff.getTime() + 60_000));
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 1);
	await expect(adminPage.locator('.pick-status')).toContainText('Pick submitted · CLE');
	await expect(adminPage.locator(`button[data-team-id="CLE"]`)).toBeDisabled();

	await openPickPage(adminPage, league.id, 2);
	const cle = adminPage.locator(`button[data-team-id="CLE"]`);
	await expect(cle).toBeDisabled();
	await expect(cle).toHaveAttribute('title', /Locked — picked Week 1/);

	await cle.click({ force: true });
	await expect(adminPage.getByRole('dialog')).toHaveCount(0);
	await expect(adminPage.locator('.pick-status')).toContainText('Choose a team below');
	await expect(adminPage.locator('p.pick-error')).toHaveCount(0);
});

test('week badge follows simulated clock; banner clears on reset', async ({ adminPage }) => {
	const week3Instant = new Date(SEASON_2026_WEEK1_START.getTime() + 14 * 24 * 60 * 60_000 + 60 * 60_000);
	const expectedWeek = getCurrentWeekFromDate(week3Instant);

	await openQa(adminPage);
	await setClock(adminPage, week3Instant);
	await openLeague(adminPage, league.id);
	await syncClock(adminPage);
	await expect(adminPage.locator('.season-indicator')).toContainText(`Week ${expectedWeek}`);
	await expect(adminPage.getByTestId('qa-banner')).toContainText('QA Mode');

	await openQa(adminPage);
	await resetToLive(adminPage);
	await openLeague(adminPage, league.id);
	await syncClock(adminPage, false);
	await expect(adminPage.getByTestId('qa-banner')).toHaveCount(0);
});
