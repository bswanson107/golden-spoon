import type { Browser, Page } from '@playwright/test';
import { loginAs } from './auth';
import { createLeague, deleteLeague, joinLeague, type CreatedLeague, type LeagueVisibility } from './league';

const SYNC_STUB = {
	skipped: true,
	inProgress: false,
	lastSyncAt: null,
	gamesUpdated: 0,
	oddsUpdated: 0,
	kickoffLocksApplied: 0,
	missedPicksInserted: 0,
	error: null
};

export async function withAdminPage<T>(
	browser: Browser,
	fn: (page: Page) => Promise<T>
): Promise<T> {
	const context = await browser.newContext();
	await context.addInitScript(() => localStorage.setItem('golden-spoon-admin-mode', 'true'));
	await context.route('**/functions/v1/sync-nfl-data', async (route) => {
		await route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify(SYNC_STUB)
		});
	});
	const page = await context.newPage();
	try {
		await loginAs(page, 'admin');
		return await fn(page);
	} finally {
		await context.close();
	}
}

export async function withPlayerPage<T>(
	browser: Browser,
	fn: (page: Page) => Promise<T>
): Promise<T> {
	const context = await browser.newContext();
	await context.route('**/functions/v1/sync-nfl-data', async (route) => {
		await route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify(SYNC_STUB)
		});
	});
	const page = await context.newPage();
	try {
		await loginAs(page, 'player2');
		return await fn(page);
	} finally {
		await context.close();
	}
}

export async function provisionLeague(
	browser: Browser,
	opts: { tag: string; visibility?: LeagueVisibility }
): Promise<CreatedLeague> {
	const league = await withAdminPage(browser, (page) => createLeague(page, opts));
	await withPlayerPage(browser, (page) => joinLeague(page, league.inviteCode));
	return league;
}

export async function teardownLeague(browser: Browser, league: CreatedLeague | null): Promise<void> {
	if (!league) return;
	await withAdminPage(browser, (page) => deleteLeague(page, league.id));
}
