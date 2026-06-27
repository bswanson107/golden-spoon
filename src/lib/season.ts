import { qaNowDate } from '$lib/qaClock.svelte';

export const DEMO_SEASON_YEAR = 2025;

/** Week 1 opener for the 2026 regular season (Wednesday night). */
export const SEASON_2026_WEEK1_START = new Date('2026-09-09T00:20:00.000Z');

export function isDemoSeason(seasonYear: number): boolean {
	return seasonYear === DEMO_SEASON_YEAR;
}

/**
 * Estimate current NFL regular-season week from calendar date.
 * Used when no saved view week exists for live leagues.
 */
export function getCurrentWeekFromDate(
	now: Date = qaNowDate(),
	seasonYear = 2026
): number {
	if (seasonYear !== 2026) return 1;

	const msPerWeek = 7 * 24 * 60 * 60 * 1000;
	const elapsed = now.getTime() - SEASON_2026_WEEK1_START.getTime();

	if (elapsed < 0) return 1;

	const week = Math.floor(elapsed / msPerWeek) + 1;
	return Math.min(Math.max(week, 1), 18);
}
