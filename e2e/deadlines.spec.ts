import { test, expect } from './fixtures';
import { expectGridCell, resolveLeagueUserIds } from './helpers/assertions';
import { openLeague, openPickPage, pickTeam, type CreatedLeague } from './helpers/league';
import { provisionLeague, teardownLeague } from './helpers/lifecycle';
import {
	jumpToFirstKickoff,
	jumpToLastKickoff,
	nudgeClock,
	openQa,
	resetWeek,
	selectSeasonWeek,
	setClock,
	syncClock
} from './helpers/qa';
import { SEASON_YEAR, WEEK1 } from './helpers/seedData';

test.describe.configure({ mode: 'serial' });

let league: CreatedLeague;
let adminId = '';

test.beforeAll(async ({ browser }) => {
	league = await provisionLeague(browser, { tag: 'deadlines', visibility: 'hidden_until_kickoff' });
});

test.afterAll(async ({ browser }) => {
	await teardownLeague(browser, league);
});

test('before first kickoff, games are selectable', async ({ adminPage }) => {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 1);
	await expect(adminPage.locator('.pick-status')).toContainText('Choose a team below');
	await expect(adminPage.locator(`button[data-team-id="${WEEK1.opener.home}"]`)).toBeEnabled();
	await expect(adminPage.locator(`button[data-team-id="${WEEK1.sundayChiCar.home}"]`)).toBeEnabled();

	await pickTeam(adminPage, WEEK1.sundayChiCar.home);
	await expect(adminPage.locator('.pick-status')).toContainText(
		`Current pick · ${WEEK1.sundayChiCar.home}`
	);

	await openLeague(adminPage, league.id);
	adminId = (await resolveLeagueUserIds(adminPage)).me;
});

test('at kickoff boundary, that game locks and later games stay open', async ({ adminPage }) => {
	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await jumpToFirstKickoff(adminPage);
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 1);
	await expect(adminPage.locator(`button[data-team-id="${WEEK1.opener.home}"]`)).toBeDisabled();
	await expect(adminPage.locator(`button[data-team-id="${WEEK1.opener.away}"]`)).toBeDisabled();
	await expect(adminPage.locator(`button[data-team-id="${WEEK1.sundayChiCar.home}"]`)).toBeEnabled();
});

test('after MNF kickoff, week is closed', async ({ adminPage }) => {
	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await jumpToLastKickoff(adminPage);
	await nudgeClock(adminPage, 1);
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 1);
	const teamButtons = adminPage.locator('button[data-team-id]');
	const count = await teamButtons.count();
	expect(count).toBeGreaterThan(0);
	for (let i = 0; i < count; i++) {
		await expect(teamButtons.nth(i)).toBeDisabled();
	}

	await openLeague(adminPage, league.id);
	await expect(adminPage.getByText(/pick window has closed|You're locked in on/i)).toBeVisible();
	if (adminId) {
		await expectGridCell(adminPage, adminId, 1, { state: 'visible' });
	}
});
