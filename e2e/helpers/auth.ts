import type { Page } from '@playwright/test';

export type E2eRole = 'admin' | 'player2';

function requireEnv(name: string): string {
	const value = process.env[name];
	if (!value) {
		throw new Error(`Missing required env var ${name}. Copy .env.e2e.example to .env.e2e.`);
	}
	return value;
}

export function credentialsFor(role: E2eRole): { email: string; password: string } {
	if (role === 'admin') {
		return {
			email: requireEnv('E2E_ADMIN_EMAIL'),
			password: requireEnv('E2E_ADMIN_PASSWORD')
		};
	}
	return {
		email: requireEnv('E2E_PLAYER2_EMAIL'),
		password: requireEnv('E2E_PLAYER2_PASSWORD')
	};
}

export function displayNameFor(role: E2eRole): string {
	if (role === 'admin') return requireEnv('E2E_ADMIN_NAME');
	return requireEnv('E2E_PLAYER2_NAME');
}

export async function loginAs(page: Page, role: E2eRole): Promise<void> {
	const { email, password } = credentialsFor(role);
	await page.goto('/login');
	await page.getByLabel('Email').fill(email);
	await page.getByLabel('Password').fill(password);
	await page.getByRole('button', { name: 'Sign in' }).click();
	await page.waitForURL((url) => !url.pathname.endsWith('/login'), { timeout: 30_000 });
}
