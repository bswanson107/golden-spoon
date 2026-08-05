import { test as base, type Browser, type Page } from '@playwright/test';
import { loginAs, type E2eRole } from './helpers/auth';

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

async function preparePage(browser: Browser, role: E2eRole): Promise<{ page: Page; close: () => Promise<void> }> {
	const context = await browser.newContext();
	if (role === 'admin') {
		await context.addInitScript(() => {
			localStorage.setItem('golden-spoon-admin-mode', 'true');
		});
	}
	await context.route('**/functions/v1/sync-nfl-data', async (route) => {
		await route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify(SYNC_STUB)
		});
	});
	const page = await context.newPage();
	await loginAs(page, role);
	return {
		page,
		close: async () => {
			await context.close();
		}
	};
}

type Fixtures = {
	adminPage: Page;
	playerPage: Page;
};

export const test = base.extend<Fixtures>({
	adminPage: async ({ browser }, use) => {
		const { page, close } = await preparePage(browser, 'admin');
		await use(page);
		await close();
	},
	playerPage: async ({ browser }, use) => {
		const { page, close } = await preparePage(browser, 'player2');
		await use(page);
		await close();
	}
});

export { expect } from '@playwright/test';
