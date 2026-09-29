import type { LeaguePick, PickOutcome, StandingRow } from '$lib/types/standings';

export type PickStreak = { kind: 'W' | 'L'; length: number };

export type RankMove =
	| { direction: 'up' | 'down'; places: number }
	| { direction: 'same' };

const DECIDED: ReadonlySet<PickOutcome> = new Set(['win', 'loss', 'missed', 'tie']);

function userKey(userId: string): string {
	return userId.toLowerCase();
}

function roundPoints(points: number): number {
	return Math.round(points * 10) / 10;
}

/**
 * Current win/loss streak from the most recent decided pick.
 * Misses count as losses. A tie, or no decided picks, is no active streak.
 */
export function streakFromPicks(
	picks: Pick<LeaguePick, 'week_number' | 'outcome' | 'kickoff_at'>[]
): PickStreak | null {
	const decided = picks
		.filter((pick) => DECIDED.has(pick.outcome))
		.sort(
			(a, b) =>
				b.week_number - a.week_number || b.kickoff_at.localeCompare(a.kickoff_at)
		);

	if (decided.length === 0) return null;

	const latest = decided[0].outcome;
	if (latest === 'tie') return null;

	const kind: 'W' | 'L' = latest === 'win' ? 'W' : 'L';
	let length = 0;
	for (const pick of decided) {
		if (pick.outcome === 'tie') break;
		const pickKind: 'W' | 'L' = pick.outcome === 'win' ? 'W' : 'L';
		if (pickKind !== kind) break;
		length += 1;
	}

	return length > 0 ? { kind, length } : null;
}

/**
 * Places moved versus standings before `movementWeek`.
 * Picks in that week and later are this week's results.
 * Week 1 (and earlier) has no previous standing, so every move is null.
 * Equal previous point totals keep the current rank order so a tiebreaker-only
 * swap is not reported as movement.
 */
export function rankMovementByUser(
	standings: Pick<StandingRow, 'user_id' | 'standing_rank'>[],
	picks: Pick<LeaguePick, 'user_id' | 'week_number' | 'points_awarded'>[],
	movementWeek: number
): Map<string, RankMove | null> {
	const result = new Map<string, RankMove | null>();
	if (movementWeek <= 1) {
		for (const row of standings) result.set(userKey(row.user_id), null);
		return result;
	}

	const points = new Map<string, number>();
	for (const row of standings) points.set(userKey(row.user_id), 0);
	for (const pick of picks) {
		if (pick.week_number >= movementWeek) continue;
		const key = userKey(pick.user_id);
		if (!points.has(key)) continue;
		points.set(key, roundPoints((points.get(key) ?? 0) + Number(pick.points_awarded)));
	}

	const ordered = [...standings].sort((a, b) => {
		const diff = (points.get(userKey(b.user_id)) ?? 0) - (points.get(userKey(a.user_id)) ?? 0);
		if (diff !== 0) return diff;
		return a.standing_rank - b.standing_rank || userKey(a.user_id).localeCompare(userKey(b.user_id));
	});

	const previousRank = new Map<string, number>();
	let rank = 1;
	for (let i = 0; i < ordered.length; i++) {
		if (i > 0) {
			const prevPts = points.get(userKey(ordered[i - 1].user_id)) ?? 0;
			const pts = points.get(userKey(ordered[i].user_id)) ?? 0;
			if (pts !== prevPts) rank = i + 1;
		}
		previousRank.set(userKey(ordered[i].user_id), rank);
	}

	for (const row of standings) {
		const key = userKey(row.user_id);
		const prev = previousRank.get(key);
		if (prev === undefined) {
			result.set(key, null);
			continue;
		}
		const delta = prev - row.standing_rank;
		if (delta > 0) result.set(key, { direction: 'up', places: delta });
		else if (delta < 0) result.set(key, { direction: 'down', places: -delta });
		else result.set(key, { direction: 'same' });
	}

	return result;
}
