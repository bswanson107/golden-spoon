import { test, expect } from './fixtures';
import { displayNameFor } from './helpers/auth';
import {
	expectGridCell,
	expectStandingsPoints,
	resolveLeagueUserIds
} from './helpers/assertions';
import { openLeague, openPickPage, pickTeam, type CreatedLeague } from './helpers/league';
import { provisionLeague, teardownLeague } from './helpers/lifecycle';
import {
	openQa,
	resetWeek,
	runProcessing,
	selectSeasonWeek,
	setClock,
	setGameResult,
	setWinPct,
	syncClock
} from './helpers/qa';
import { SEASON_YEAR, WEEK1 } from './helpers/seedData';

test.describe.configure({ mode: 'serial' });

let league: CreatedLeague;
let adminId = '';
let playerId = '';
const matchup = WEEK1.sundayChiCar.matchup;

test.beforeAll(async ({ browser }) => {
	league = await provisionLeague(browser, { tag: 'scoring', visibility: 'open' });
});

test.afterAll(async ({ browser }) => {
	await teardownLeague(browser, league);
});

async function preparePicks(
	adminPage: import('@playwright/test').Page,
	playerPage: import('@playwright/test').Page,
	awayPct: number,
	homePct: number
) {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await setWinPct(adminPage, matchup, awayPct, homePct);
	await syncClock(adminPage);
	await syncClock(playerPage);

	await openPickPage(adminPage, league.id, 1);
	await pickTeam(adminPage, WEEK1.sundayChiCar.home); // CAR

	await openPickPage(playerPage, league.id, 1);
	await pickTeam(playerPage, WEEK1.sundayChiCar.away); // CHI

	await openLeague(adminPage, league.id);
	const ids = await resolveLeagueUserIds(adminPage, displayNameFor('player2'));
	adminId = ids.me;
	playerId = ids.other;
}

test('favorite win = 1 pt; underdog win = 2 pts', async ({ adminPage, playerPage }) => {
	await preparePicks(adminPage, playerPage, 70, 30);

	await openPickPage(adminPage, league.id, 1);
	await expect(adminPage.getByText('Underdawg · 2 pts').first()).toBeVisible();

	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setGameResult(adminPage, matchup, 'home');
	await syncClock(adminPage);
	await openLeague(adminPage, league.id);

	await expectStandingsPoints(adminPage, adminId, '2.0');
	await expectStandingsPoints(adminPage, playerId, '0.0');
	await expectGridCell(adminPage, adminId, 1, { state: 'visible', team: 'CAR' });
	await expect(adminPage.locator(`[data-testid="pick-cell"][data-user="${adminId}"] .underdawg`)).toBeVisible();

	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setWinPct(adminPage, matchup, 70, 30);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await syncClock(adminPage);
	await syncClock(playerPage);

	await openPickPage(adminPage, league.id, 1);
	await pickTeam(adminPage, WEEK1.sundayChiCar.home);
	await openPickPage(playerPage, league.id, 1);
	await pickTeam(playerPage, WEEK1.sundayChiCar.away);

	await openQa(adminPage);
	await setGameResult(adminPage, matchup, 'away');
	await syncClock(adminPage);
	await openLeague(adminPage, league.id);
	await expectStandingsPoints(adminPage, playerId, '1.0');
	await expectStandingsPoints(adminPage, adminId, '0.0');
});

test('kickoff re-lock flips underdog snapshot', async ({ adminPage, playerPage }) => {
	await openQa(adminPage);
	await resetWeek(adminPage, SEASON_YEAR, 1);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setClock(adminPage, new Date(WEEK1.opener.kickoff.getTime() - 60 * 60_000));
	await setWinPct(adminPage, matchup, 40, 60); // CAR favorite
	await syncClock(adminPage);

	await openPickPage(adminPage, league.id, 1);
	await pickTeam(adminPage, WEEK1.sundayChiCar.home);
	await expect(adminPage.locator('.pick-status')).toContainText('CAR');

	await openQa(adminPage);
	await setWinPct(adminPage, matchup, 70, 30); // CAR now underdog
	await setClock(adminPage, new Date(WEEK1.sundayChiCar.kickoff.getTime() + 60_000));
	await runProcessing(adminPage);
	await setGameResult(adminPage, matchup, 'home');
	await syncClock(adminPage);

	await openLeague(adminPage, league.id);
	adminId = (await resolveLeagueUserIds(adminPage)).me;
	await expectStandingsPoints(adminPage, adminId, '2.0');
	await expect(adminPage.locator(`[data-testid="pick-cell"][data-user="${adminId}"] .underdawg`)).toBeVisible();
	void playerPage;
});

test('tie awards 0.5 to underdog and favorite', async ({ adminPage, playerPage }) => {
	await preparePicks(adminPage, playerPage, 70, 30);

	await openQa(adminPage);
	await selectSeasonWeek(adminPage, SEASON_YEAR, 1);
	await setGameResult(adminPage, matchup, 'tie');
	await syncClock(adminPage);
	await openLeague(adminPage, league.id);

	await expectStandingsPoints(adminPage, adminId, '0.5');
	await expectStandingsPoints(adminPage, playerId, '0.5');
	await expect(adminPage.locator(`[data-testid="pick-cell"][data-user="${adminId}"] .ring-tie`)).toBeVisible();
	await expect(adminPage.locator(`[data-testid="pick-cell"][data-user="${playerId}"] .ring-tie`)).toBeVisible();
	await expect(adminPage.locator(`[data-testid="pick-cell"][data-user="${adminId}"] .underdawg`)).toHaveCount(0);

	const adminRow = adminPage.locator(`[data-testid="standings-row"][data-user="${adminId}"]`);
	await expect(adminRow.locator('td.num').nth(2)).toHaveText('0-0-1');
});
