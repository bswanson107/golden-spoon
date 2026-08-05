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
	const msPerWeek = 7 * 24 * 60 * 60 * 1000;
	const elapsed = now.getTime() - SEASON_2026_WEEK1_START.getTime();
	if (elapsed < 0) return 1;
	const week = Math.floor(elapsed / msPerWeek) + 1;
	return Math.min(Math.max(week, 1), 18);
}

export function runId(): string {
	return Date.now().toString(36);
}
