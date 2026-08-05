import { chromium, type FullConfig } from '@playwright/test';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { config as loadEnv } from 'dotenv';
import { loginAs } from './helpers/auth';
import { openQa, resetSeason, resetToLive } from './helpers/qa';
import { sweepE2eLeagues } from './helpers/league';
import { SEASON_YEAR } from './helpers/seedData';
import { resumeSyncNflWorkflow } from './helpers/syncWorkflow';

const root = path.dirname(fileURLToPath(import.meta.url));
loadEnv({ path: path.resolve(root, '../.env.e2e') });
loadEnv({ path: path.resolve(root, '../.env') });

export default async function globalTeardown(_config: FullConfig): Promise<void> {
	const baseURL = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:5173';
	const browser = await chromium.launch();
	const context = await browser.newContext({ baseURL });
	await context.addInitScript(() => {
		localStorage.setItem('golden-spoon-admin-mode', 'true');
	});
	const page = await context.newPage();
	try {
		await loginAs(page, 'admin');
		await sweepE2eLeagues(page);
		await openQa(page);
		await resetSeason(page, SEASON_YEAR);
		await resetToLive(page);
	} catch (err) {
		console.warn('globalTeardown warning:', err);
	} finally {
		await context.close();
		await browser.close();
		await resumeSyncNflWorkflow();
	}
}
