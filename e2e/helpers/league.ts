import { expect, type Page } from '@playwright/test';
import { SEASON_YEAR, runId } from './seedData';

export type LeagueVisibility = 'hidden_until_kickoff' | 'open';

export type CreatedLeague = {
	id: string;
	name: string;
	inviteCode: string;
};

export async function createLeague(
	page: Page,
	opts: {
		tag: string;
		visibility?: LeagueVisibility;
		threshold?: number;
		seasonYear?: number;
	}
): Promise<CreatedLeague> {
	const idSuffix = runId();
	const name = `E2E ${opts.tag} ${idSuffix}`;
	const inviteCode = `e2e-${opts.tag.toLowerCase().replace(/\s+/g, '-')}-${idSuffix}`.slice(0, 32);
	const visibility = opts.visibility ?? 'hidden_until_kickoff';
	const threshold = opts.threshold ?? 33;
	const seasonYear = opts.seasonYear ?? SEASON_YEAR;

	await page.goto('/leagues/create');
	await page.getByLabel('League name').fill(name);
	await page.getByLabel('Invite code').fill(inviteCode);
	await page.getByLabel('Season year').fill(String(seasonYear));
	await page.getByRole('radio', { name: `${threshold}%` }).click();

	if (visibility === 'open') {
		await page.getByRole('radio', { name: /Open — picks visible/i }).click();
	} else {
		await page.getByRole('radio', { name: /Hidden until kickoff/i }).click();
	}

	await page.getByRole('button', { name: 'Create league' }).click();
	await page.waitForURL(/\/league\/[0-9a-f-]+$/i, { timeout: 30_000 });
	const match = page.url().match(/\/league\/([0-9a-f-]+)/i);
	if (!match) throw new Error(`Could not parse league id from ${page.url()}`);
	return { id: match[1], name, inviteCode };
}

export async function joinLeague(page: Page, inviteCode: string): Promise<string> {
	await page.goto('/leagues/join');
	await page.getByLabel('Invite code').fill(inviteCode);
	await page.getByRole('button', { name: 'Join league' }).click();
	await page.waitForURL(/\/league\/[0-9a-f-]+$/i, { timeout: 30_000 });
	const match = page.url().match(/\/league\/([0-9a-f-]+)/i);
	if (!match) throw new Error(`Could not parse league id from ${page.url()}`);
	return match[1];
}

export async function openLeague(page: Page, leagueId: string): Promise<void> {
	await page.goto(`/league/${leagueId}`);
	await expect(page).toHaveURL(new RegExp(`/league/${leagueId}/?$`));
	await expect(page.locator('h1.page-title')).not.toHaveText('My leagues');
	await expect(page.locator('[data-testid="standings-row"]').first()).toBeVisible({
		timeout: 30_000
	});
}

export async function openPickPage(page: Page, leagueId: string, week?: number): Promise<void> {
	await page.goto(`/league/${leagueId}/pick`);
	await expect(page).toHaveURL(new RegExp(`/league/${leagueId}/pick`));
	await expect(page.getByRole('heading', { name: /Make your pick|Week matchups/ })).toBeVisible();
	if (week !== undefined) {
		await page.getByLabel('View week').selectOption(String(week));
		await expect(page.locator('.pick-status')).toBeVisible({ timeout: 20_000 });
	}
}

export async function pickTeam(page: Page, teamId: string): Promise<void> {
	const button = page.locator(`button[data-team-id="${teamId}"]`);
	await expect(button).toBeEnabled();
	await button.click();
	// Prior-week usage opens a move confirmation (picks survive qa_reset_week).
	const continueBtn = page.getByRole('dialog').getByRole('button', { name: 'Continue' });
	try {
		await continueBtn.click({ timeout: 2_000 });
	} catch {
		/* no reuse dialog */
	}
	await expect(page.locator('.pick-status')).toContainText(teamId, { timeout: 20_000 });
}

export async function deleteLeague(page: Page, leagueId: string): Promise<void> {
	await openLeague(page, leagueId);
	page.once('dialog', (dialog) => {
		if (/Delete league/i.test(dialog.message())) void dialog.accept();
		else void dialog.dismiss();
	});
	await page.getByRole('button', { name: /Delete league/i }).click();
	await page.waitForURL(/\/leagues/, { timeout: 30_000 });
}

/** Sweep leftover E2E leagues from the leagues list (admin mode must be on). */
export async function sweepE2eLeagues(page: Page): Promise<void> {
	await page.goto('/leagues');
	const e2eLinks = page.locator('a.league-card').filter({ has: page.locator('.league-name') });
	const count = await e2eLinks.count();
	const ids: string[] = [];
	for (let i = 0; i < count; i++) {
		const link = e2eLinks.nth(i);
		const name = await link.locator('.league-name').textContent();
		if (name?.startsWith('E2E ')) {
			const href = await link.getAttribute('href');
			const id = href?.match(/\/league\/([^/?#]+)/)?.[1];
			if (id) ids.push(id);
		}
	}
	for (const id of ids) {
		try {
			await deleteLeague(page, id);
		} catch {
			/* best-effort teardown */
		}
	}
}
