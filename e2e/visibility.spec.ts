import { test, expect } from './fixtures';
import { displayNameFor } from './helpers/auth';
import { expectGridCell, resolveLeagueUserIds } from './helpers/assertions';
import { openLeague, openPickPage, pickTeam, type CreatedLeague } from './helpers/league';
import { provisionLeague, teardownLeague } from './helpers/lifecycle';
import { openQa, resetWeek, selectSeasonWeek, setClock, syncClock } from './helpers/qa';
import { SEASON_YEAR, WEEK1 } from './helpers/seedData';

test.describe.configure({ mode: 'serial' });

let hiddenLeague: CreatedLeague;
let openLeagueCreated: CreatedLeague;
let adminId = '';
let playerId = '';

test.beforeAll(async ({ browser }) => {
	hiddenLeague = await provisionLeague(browser, {
		tag: 'vis-hidden',
		visibility: 'hidden_until_kickoff'
	});
	openLeagueCreated = await provisionLeague(browser, { tag: 'vis-open', visibility: 'open' });
});

test.afterAll(async ({ browser }) => {
	await teardownLeague(browser, hiddenLeague);
	await teardownLeague(browser, openLeagueCreated);
});

async function seedPicksBeforeKickoff(
	adminPage: import('@playwright/test').Page,
	playerPage: import('@playwright/test').Page,
	leagueId: string
) {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await syncClock(adminPage);
	await syncClock(playerPage);

	await openPickPage(adminPage, leagueId, 1);
	await pickTeam(adminPage, WEEK1.sundayChiCar.home); // CAR

	await openPickPage(playerPage, leagueId, 1);
	await pickTeam(playerPage, WEEK1.sundayChiCar.away); // CHI

	await openLeague(adminPage, leagueId);
	const ids = await resolveLeagueUserIds(adminPage, displayNameFor('player2'));
	adminId = ids.me;
	playerId = ids.other;
}

test('hidden league hides opponent teams until kickoff', async ({ adminPage, playerPage }) => {
	await seedPicksBeforeKickoff(adminPage, playerPage, hiddenLeague.id);

	await openLeague(playerPage, hiddenLeague.id);
	await expectGridCell(playerPage, playerId, 1, {
		state: 'visible',
		team: WEEK1.sundayChiCar.away
	});
	await expectGridCell(playerPage, adminId, 1, { state: 'hidden' });

	const gridText = await playerPage.locator('table.picks-grid:not(.picks-header-grid)').innerText();
	expect(gridText).not.toContain(WEEK1.sundayChiCar.home);
});

test('own pick visible and opponent reveals after kickoff', async ({ adminPage, playerPage }) => {
	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.sundayChiCar.kickoff.getTime() + 60_000));
	await syncClock(playerPage);

	await openLeague(playerPage, hiddenLeague.id);
	await expectGridCell(playerPage, adminId, 1, {
		state: 'visible',
		team: WEEK1.sundayChiCar.home
	});
	await expectGridCell(playerPage, playerId, 1, {
		state: 'visible',
		team: WEEK1.sundayChiCar.away
	});
});

test('open league shows opponent pick immediately', async ({ adminPage, playerPage }) => {
	await seedPicksBeforeKickoff(adminPage, playerPage, openLeagueCreated.id);

	await openLeague(playerPage, openLeagueCreated.id);
	await expectGridCell(playerPage, adminId, 1, {
		state: 'visible',
		team: WEEK1.sundayChiCar.home
	});
	await expectGridCell(playerPage, playerId, 1, {
		state: 'visible',
		team: WEEK1.sundayChiCar.away
	});
});
