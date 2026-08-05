import { test, expect } from './fixtures';
import { displayNameFor } from './helpers/auth';
import { expectGridCell, resolveLeagueUserIds } from './helpers/assertions';
import { openLeague, openPickPage, pickTeam, type CreatedLeague } from './helpers/league';
import { provisionLeague, teardownLeague } from './helpers/lifecycle';
import {
	jumpToLastKickoff,
	nudgeClock,
	openQa,
	resetWeek,
	runProcessing,
	selectSeasonWeek,
	setClock,
	syncClock
} from './helpers/qa';
import { SEASON_YEAR, WEEK1, WEEK2 } from './helpers/seedData';

test.describe.configure({ mode: 'serial' });

let league: CreatedLeague;
let adminId = '';
let playerId = '';

test.beforeAll(async ({ browser }) => {
	league = await provisionLeague(browser, { tag: 'automnf', visibility: 'hidden_until_kickoff' });
});

test.afterAll(async ({ browser }) => {
	await teardownLeague(browser, league);
});

test('no pick after MNF gets the MNF home team', async ({ adminPage, playerPage }) => {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await syncClock(adminPage);
	await syncClock(playerPage);

	await openPickPage(adminPage, league.id, 1);
	await pickTeam(adminPage, WEEK1.sundayChiCar.home);

	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await jumpToLastKickoff(adminPage);
	await nudgeClock(adminPage, 1);
	await expect(adminPage.locator('.alert.err')).toHaveCount(0);

	await syncClock(adminPage);
	await syncClock(playerPage);
	await openLeague(adminPage, league.id);
	const ids = await resolveLeagueUserIds(adminPage, displayNameFor('player2'));
	adminId = ids.me;
	playerId = ids.other;

	await expectGridCell(adminPage, playerId, 1, {
		state: 'visible',
		team: WEEK1.mnf.home,
		auto: true
	});
	await expectGridCell(adminPage, adminId, 1, {
		state: 'visible',
		team: WEEK1.sundayChiCar.home,
		auto: false
	});

	await openQa(adminPage);
	await runProcessing(adminPage);
	await syncClock(adminPage);
	await openLeague(adminPage, league.id);
	await expectGridCell(adminPage, playerId, 1, {
		state: 'visible',
		team: WEEK1.mnf.home,
		auto: true
	});
});

test('falls back to missed when MNF home team already used', async ({ adminPage, playerPage }) => {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await resetWeek(adminPage, SEASON_YEAR, 2);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.thursday.kickoff.getTime() - 60 * 60_000));
	await syncClock(playerPage);

	await openPickPage(playerPage, league.id, 1);
	await pickTeam(playerPage, WEEK1.thursday.home); // LAR — also Week 2 MNF home

	// Complete week 1 so the Week 2 grid column appears.
	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await adminPage.getByRole('button', { name: 'Default: home wins' }).click();
	await expect(adminPage.locator('.alert.ok')).toBeVisible();
	await expect(adminPage.locator('.alert.err')).toHaveCount(0);

	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 2);
	await setClock(adminPage, new Date(WEEK2.mnf.kickoff.getTime() + 60_000));
	await syncClock(adminPage);

	await openLeague(adminPage, league.id);
	playerId = (await resolveLeagueUserIds(adminPage, displayNameFor('player2'))).other;
	await expectGridCell(adminPage, playerId, 1, {
		state: 'visible',
		team: WEEK1.thursday.home
	});
	await expectGridCell(adminPage, playerId, 2, { state: 'missed' });
});
