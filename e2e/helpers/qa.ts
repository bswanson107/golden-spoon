import { expect, type Page } from '@playwright/test';
import { SEASON_YEAR } from './seedData';

async function expectQaOk(page: Page, contains?: string | RegExp): Promise<void> {
	const ok = page.locator('.alert.ok');
	const err = page.locator('.alert.err');
	await expect(ok.or(err)).toBeVisible({ timeout: 30_000 });
	if (await err.isVisible()) {
		throw new Error(`QA action failed: ${((await err.textContent()) ?? '').trim()}`);
	}
	if (contains) await expect(ok).toContainText(contains);
}

export async function openQa(page: Page): Promise<void> {
	await page.goto('/qa');
	await expect(page.getByRole('heading', { name: 'QA Mode' })).toBeVisible();
}

export async function selectSeasonWeek(
	page: Page,
	season: number = SEASON_YEAR,
	week: number = 1
): Promise<void> {
	await page.locator('label:has-text("Season") input').fill(String(season));
	await page.locator('label:has-text("Week") select').selectOption(String(week));
	await expect(page.locator('table.games tbody tr').first()).toBeVisible({ timeout: 20_000 });
}

function toLocalInput(ms: number): string {
	const d = new Date(ms);
	const pad = (n: number) => String(n).padStart(2, '0');
	return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export async function setClock(page: Page, when: Date): Promise<void> {
	await openQa(page);
	await page.locator('input[type="datetime-local"]').fill(toLocalInput(when.getTime()));
	await page.getByRole('button', { name: 'Set clock' }).click();
	await expectQaOk(page, /Clock set/);
}

export async function jumpToFirstKickoff(page: Page): Promise<void> {
	await page.getByRole('button', { name: 'Jump to week first kickoff' }).click();
	await expectQaOk(page, /Clock set/);
}

export async function jumpToLastKickoff(page: Page): Promise<void> {
	await page.getByRole('button', { name: 'Jump to last (MNF) kickoff' }).click();
	await expectQaOk(page, /Clock set/);
}

export async function nudgeClock(
	page: Page,
	minutes: 1 | -1 | 15 | -15 | 60 | -60
): Promise<void> {
	const labels: Record<number, string> = {
		[-60]: '-1 hr',
		[-15]: '-15 min',
		[-1]: '-1 min',
		[1]: '+1 min',
		[15]: '+15 min',
		[60]: '+1 hr'
	};
	await page.getByRole('button', { name: labels[minutes], exact: true }).click();
	await expectQaOk(page, /Clock set/);
}

export async function resetToLive(page: Page): Promise<void> {
	await openQa(page);
	await page.getByRole('button', { name: 'Reset to live' }).click();
	await expectQaOk(page, /Clock reset|live/i);
}

export async function setWinPct(
	page: Page,
	matchup: string,
	awayPct: number,
	homePct: number
): Promise<void> {
	const row = page.locator(`tr[data-matchup="${matchup}"]`);
	await expect(row).toBeVisible();
	const inputs = row.locator('input.pct');
	await inputs.nth(0).fill(String(awayPct));
	await inputs.nth(1).fill(String(homePct));
	await row.getByRole('button', { name: 'Set', exact: true }).click();
	await expectQaOk(page);
}

export async function setGameResult(
	page: Page,
	matchup: string,
	result: 'home' | 'away' | 'tie'
): Promise<void> {
	const row = page.locator(`tr[data-matchup="${matchup}"]`);
	const label = result === 'home' ? 'Home' : result === 'away' ? 'Away' : 'Tie';
	await row.getByRole('button', { name: label, exact: true }).click();
	await expectQaOk(page);
}

export async function resetWeek(
	page: Page,
	season: number = SEASON_YEAR,
	week: number = 1
): Promise<void> {
	await openQa(page);
	await selectSeasonWeek(page, season, week);
	await page.getByRole('button', { name: 'Reset week' }).click();
	await expectQaOk(page, /reset/i);
}

export async function resetSeason(page: Page, season: number = SEASON_YEAR): Promise<void> {
	await openQa(page);
	await page.locator('label:has-text("Season") input').fill(String(season));
	// Native confirm() — Playwright dismisses by default, which aborts the reset.
	page.once('dialog', (dialog) => {
		if (/Reset ALL of season/i.test(dialog.message())) void dialog.accept();
		else void dialog.dismiss();
	});
	await page.getByRole('button', { name: 'Reset season' }).click();
	await expectQaOk(page, /reset/i);
}

export async function runProcessing(page: Page): Promise<void> {
	await page
		.getByRole('button', { name: 'Run week processing (kickoff lock + auto-MNF / missed)' })
		.click();
	await expectQaOk(page);
}

/** Reload so hydrateQaClock picks up the simulated clock, then wait for the banner. */
export async function syncClock(page: Page, expectEnabled = true): Promise<void> {
	await page.reload();
	const banner = page.getByTestId('qa-banner');
	if (expectEnabled) {
		await expect(banner).toBeVisible({ timeout: 20_000 });
		await expect(banner).toContainText('QA Mode');
	} else {
		await expect(banner).toHaveCount(0);
	}
}
