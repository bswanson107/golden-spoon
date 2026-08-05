import { expect, type Page } from '@playwright/test';

export type GridCell = {
	state: 'empty' | 'hidden' | 'visible' | 'missed';
	team: string | null;
	auto: boolean;
};

export async function readGridCell(
	page: Page,
	userId: string,
	week: number
): Promise<GridCell> {
	const cell = page.locator(
		`[data-testid="pick-cell"][data-user="${userId.toLowerCase()}"][data-week="${week}"]`
	);
	await expect(cell).toBeVisible({ timeout: 20_000 });
	const state = (await cell.getAttribute('data-state')) as GridCell['state'];
	const team = (await cell.getAttribute('data-team')) || null;
	const auto = (await cell.getAttribute('data-auto')) === 'true';
	return { state, team: team || null, auto };
}

export async function expectGridCell(
	page: Page,
	userId: string,
	week: number,
	expected: Partial<GridCell>
): Promise<void> {
	await expect
		.poll(async () => readGridCell(page, userId, week), { timeout: 30_000 })
		.toMatchObject(expected);
}

export async function readStandings(
	page: Page
): Promise<Array<{ userId: string; name: string; points: string; record: string }>> {
	const rows = page.locator('[data-testid="standings-row"]');
	await expect(rows.first()).toBeVisible({ timeout: 30_000 });
	const count = await rows.count();
	const out: Array<{ userId: string; name: string; points: string; record: string }> = [];
	for (let i = 0; i < count; i++) {
		const row = rows.nth(i);
		out.push({
			userId: ((await row.getAttribute('data-user')) ?? '').toLowerCase(),
			name: ((await row.locator('.name-text').textContent()) ?? '').replace(/\s+/g, ' ').trim(),
			points: ((await row.locator('[data-testid="standings-points"]').textContent()) ?? '').trim(),
			record: ((await row.locator('td.num').nth(2).textContent()) ?? '').trim()
		});
	}
	return out;
}

function namesMatch(rowName: string, displayName: string): boolean {
	const name = rowName.toLowerCase();
	const needle = displayName.trim().toLowerCase();
	if (!needle) return false;
	return name === needle || name.startsWith(needle) || name.includes(needle);
}

/** Current signed-in member from the highlighted standings row. */
export async function currentUserIdFromStandings(page: Page): Promise<string> {
	const me = page.locator('[data-testid="standings-row"].me');
	await expect(me).toBeVisible({ timeout: 30_000 });
	const userId = await me.getAttribute('data-user');
	if (!userId) throw new Error('Standings row .me is missing data-user');
	return userId.toLowerCase();
}

/**
 * Resolve the current user and another member. Prefer the `.me` row for the
 * viewer; match the other player by display name when provided.
 */
export async function resolveLeagueUserIds(
	page: Page,
	otherDisplayName?: string
): Promise<{ me: string; other: string }> {
	const rows = await readStandings(page);
	const me = await currentUserIdFromStandings(page);
	const others = rows.filter((r) => r.userId.toLowerCase() !== me.toLowerCase());
	if (others.length === 0) {
		throw new Error(
			`Expected another standings row besides current user. Found: ${rows.map((r) => r.name).join(', ') || '(none)'}`
		);
	}
	if (otherDisplayName) {
		const match = others.find((r) => namesMatch(r.name, otherDisplayName));
		if (!match?.userId) {
			throw new Error(
				`No standings row for "${otherDisplayName}". Found: ${rows.map((r) => `"${r.name}"`).join(', ')}`
			);
		}
		return { me, other: match.userId };
	}
	return { me, other: others[0].userId };
}

export async function userIdByDisplayName(page: Page, displayName: string): Promise<string> {
	const rows = await readStandings(page);
	const match = rows.find((r) => namesMatch(r.name, displayName));
	if (!match?.userId) {
		throw new Error(
			`No standings row for display name "${displayName}". Found: ${rows.map((r) => `"${r.name}"`).join(', ') || '(none)'}`
		);
	}
	return match.userId;
}

export async function expectStandingsPoints(
	page: Page,
	userId: string,
	points: string
): Promise<void> {
	await expect
		.poll(async () => {
			const rows = await readStandings(page);
			return rows.find((r) => r.userId.toLowerCase() === userId.toLowerCase())?.points ?? null;
		})
		.toBe(points);
}
