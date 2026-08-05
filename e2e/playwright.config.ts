import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { config as loadEnv } from 'dotenv';

const root = path.dirname(fileURLToPath(import.meta.url));
loadEnv({ path: path.resolve(root, '../.env.e2e') });
loadEnv({ path: path.resolve(root, '../.env') });

const baseURL = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:5173';

export default defineConfig({
	testDir: root,
	testMatch: /.*\.spec\.ts/,
	fullyParallel: false,
	workers: 1,
	retries: 0,
	timeout: 120_000,
	expect: { timeout: 20_000 },
	forbidOnly: !!process.env.CI,
	reporter: [['list']],
	globalSetup: path.join(root, 'global-setup.ts'),
	globalTeardown: path.join(root, 'global-teardown.ts'),
	use: {
		baseURL,
		trace: 'retain-on-failure',
		screenshot: 'only-on-failure',
		video: 'off',
		actionTimeout: 15_000,
		navigationTimeout: 30_000
	},
	projects: [
		{
			name: 'chromium',
			use: { ...devices['Desktop Chrome'] }
		}
	],
	webServer: {
		command: 'npm run dev -- --host 127.0.0.1 --port 5173',
		url: baseURL,
		reuseExistingServer: !process.env.CI,
		timeout: 120_000
	}
});
