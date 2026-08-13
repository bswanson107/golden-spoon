import { qaNowDate } from '$lib/qaClock.svelte';

export const DEMO_SEASON_YEAR = 2025;
export const REGULAR_SEASON_WEEKS = 18;

const ET_TIMEZONE = 'America/New_York';

/** Week 1 opener for the 2026 regular season (Wednesday night). */
export const SEASON_2026_WEEK1_START = new Date('2026-09-09T00:20:00.000Z');

/**
 * Tuesday 00:00 America/New_York of 2026 week 1. NFL weeks roll at this
 * weekday/time: week N+1 starts at midnight between that week's Monday and Tuesday.
 */
const SEASON_2026_WEEK1_TUESDAY = { year: 2026, month: 9, day: 8 };

export function isDemoSeason(seasonYear: number): boolean {
	return seasonYear === DEMO_SEASON_YEAR;
}

type EtParts = {
	year: number;
	month: number;
	day: number;
	hour: number;
	minute: number;
};

function getEtParts(date: Date): EtParts {
	const formatter = new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		year: 'numeric',
		month: 'numeric',
		day: 'numeric',
		hour: 'numeric',
		minute: 'numeric',
		hourCycle: 'h23'
	});
	const parts = formatter.formatToParts(date);
	const value = (type: Intl.DateTimeFormatPartTypes) =>
		Number(parts.find((part) => part.type === type)?.value ?? 0);

	return {
		year: value('year'),
		month: value('month'),
		day: value('day'),
		hour: value('hour'),
		minute: value('minute')
	};
}

/** UTC ms for a civil date/time in America/New_York (handles EDT/EST). */
export function etWallTimeToUtcMs(
	year: number,
	month: number,
	day: number,
	hour = 0,
	minute = 0
): number {
	let utc = Date.UTC(year, month - 1, day, hour + 4, minute, 0);
	for (let i = 0; i < 4; i++) {
		const parts = getEtParts(new Date(utc));
		const asIfUtc = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, 0);
		const target = Date.UTC(year, month - 1, day, hour, minute, 0);
		const delta = target - asIfUtc;
		if (delta === 0) break;
		utc += delta;
	}
	return utc;
}

/**
 * Calendar NFL week: week N+1 begins at Tuesday 00:00 ET after week N's Monday.
 * MNF-final can advance the week earlier — see `resolveCurrentWeek` in `$lib/games`.
 */
export function getCurrentWeekFromDate(
	now: Date = qaNowDate(),
	seasonYear = 2026
): number {
	if (seasonYear !== 2026) return 1;

	const week1TuesdayMs = etWallTimeToUtcMs(
		SEASON_2026_WEEK1_TUESDAY.year,
		SEASON_2026_WEEK1_TUESDAY.month,
		SEASON_2026_WEEK1_TUESDAY.day
	);
	if (now.getTime() < week1TuesdayMs) return 1;

	const et = getEtParts(now);
	const todayEtMidnightMs = etWallTimeToUtcMs(et.year, et.month, et.day);
	const days = Math.round((todayEtMidnightMs - week1TuesdayMs) / 86_400_000);
	const week = Math.floor(days / 7) + 1;
	return Math.min(Math.max(week, 1), REGULAR_SEASON_WEEKS);
}
