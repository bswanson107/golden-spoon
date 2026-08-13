/** Fixed 2026 seed kickoffs (America/New_York) used by the E2E suite. */

export const SEASON_YEAR = 2026;

/** Mirrors src/lib/season.ts */
export const SEASON_2026_WEEK1_START = new Date('2026-09-09T00:20:00.000Z');

export const WEEK1 = {
	opener: {
		matchup: 'NE@SEA',
		away: 'NE',
		home: 'SEA',
		kickoff: new Date('2026-09-09T20:20:00-04:00')
	},
	thursday: {
		matchup: 'SF@LAR',
		away: 'SF',
		home: 'LAR',
		kickoff: new Date('2026-09-10T20:35:00-04:00')
	},
	sundayChiCar: {
		matchup: 'CHI@CAR',
		away: 'CHI',
		home: 'CAR',
		kickoff: new Date('2026-09-13T13:00:00-04:00')
	},
	sundayCleJax: {
		matchup: 'CLE@JAX',
		away: 'CLE',
		home: 'JAX',
		kickoff: new Date('2026-09-13T13:00:00-04:00')
	},
	mnf: {
		matchup: 'DEN@KC',
		away: 'DEN',
		home: 'KC',
		kickoff: new Date('2026-09-14T20:15:00-04:00')
	}
} as const;

export const WEEK2 = {
	sundayCleTb: {
		matchup: 'CLE@TB',
		away: 'CLE',
		home: 'TB',
		kickoff: new Date('2026-09-20T13:00:00-04:00')
	},
	mnf: {
		matchup: 'NYG@LAR',
		away: 'NYG',
		home: 'LAR',
		kickoff: new Date('2026-09-21T20:15:00-04:00')
	}
} as const;

export const WEEK3 = {
	sundayCarCle: {
		matchup: 'CAR@CLE',
		away: 'CAR',
		home: 'CLE',
		kickoff: new Date('2026-09-27T13:00:00-04:00')
	}
} as const;

export function getCurrentWeekFromDate(now: Date = new Date(), seasonYear = SEASON_YEAR): number {
	if (seasonYear !== 2026) return 1;
	// Mirror src/lib/season.ts: week N+1 starts Tuesday 00:00 ET.
	const week1TuesdayMs = Date.parse('2026-09-08T00:00:00-04:00');
	if (now.getTime() < week1TuesdayMs) return 1;
	const et = new Intl.DateTimeFormat('en-US', {
		timeZone: 'America/New_York',
		year: 'numeric',
		month: 'numeric',
		day: 'numeric',
		hourCycle: 'h23'
	}).formatToParts(now);
	const year = Number(et.find((p) => p.type === 'year')?.value ?? 2026);
	const month = Number(et.find((p) => p.type === 'month')?.value ?? 9);
	const day = Number(et.find((p) => p.type === 'day')?.value ?? 8);
	const todayEt = new Date(
		`${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}T00:00:00-04:00`
	);
	// DST-safe enough for the 2026 E2E window (all EDT).
	const days = Math.round((todayEt.getTime() - week1TuesdayMs) / 86_400_000);
	const week = Math.floor(days / 7) + 1;
	return Math.min(Math.max(week, 1), 18);
}

export function runId(): string {
	return Date.now().toString(36);
}
