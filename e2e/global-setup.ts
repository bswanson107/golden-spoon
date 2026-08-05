import { chromium, type FullConfig } from '@playwright/test';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { config as loadEnv } from 'dotenv';
import { loginAs } from './helpers/auth';
import { openQa, resetSeason, resetToLive, runProcessing, selectSeasonWeek } from './helpers/qa';
import { SEASON_YEAR } from './helpers/seedData';
import { pauseSyncNflWorkflow } from './helpers/syncWorkflow';

const root = path.dirname(fileURLToPath(import.meta.url));
loadEnv({ path: path.resolve(root, '../.env.e2e') });
loadEnv({ path: path.resolve(root, '../.env') });

export default async function globalSetup(_config: FullConfig): Promise<void> {
	await pauseSyncNflWorkflow();

	const baseURL = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:5173';
	const browser = await chromium.launch();
	const context = await browser.newContext({ baseURL });
	await context.addInitScript(() => {
		localStorage.setItem('golden-spoon-admin-mode', 'true');
	});
	await context.route('**/functions/v1/sync-nfl-data', async (route) => {
		await route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify({
				skipped: true,
				inProgress: false,
				lastSyncAt: null,
				gamesUpdated: 0,
				oddsUpdated: 0,
				kickoffLocksApplied: 0,
				missedPicksInserted: 0,
				error: null
			})
		});
	});

	const page = await context.newPage();
	try {
		await loginAs(page, 'admin');
		await openQa(page);
		await resetSeason(page, SEASON_YEAR);
		await selectSeasonWeek(page, SEASON_YEAR, 1);
		await runProcessing(page);
		await resetToLive(page);
	} finally {
		await context.close();
		await browser.close();
	}
}
