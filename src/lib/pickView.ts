import { browser } from '$app/environment';
import { clampSimulatedWeek } from '$lib/demo';
import { qaNowDate } from '$lib/qaClock.svelte';
import { getCurrentWeekFromDate } from '$lib/season';

const VIEW_WEEK_PREFIX = 'golden-spoon-view-week';

function viewWeekKey(leagueId: string, userId: string): string {
	return `${VIEW_WEEK_PREFIX}:${leagueId}:${userId}`;
}

export function loadViewWeek(
	leagueId: string,
	userId: string,
	seasonYear = 2026
): number {
	if (!browser) return getCurrentWeekFromDate(qaNowDate(), seasonYear);

	try {
		const raw = localStorage.getItem(viewWeekKey(leagueId, userId));
		if (!raw) return getCurrentWeekFromDate(qaNowDate(), seasonYear);
		return clampSimulatedWeek(Number(raw) || 1);
	} catch {
		return getCurrentWeekFromDate(qaNowDate(), seasonYear);
	}
}

export function saveViewWeek(leagueId: string, userId: string, week: number): void {
	if (!browser) return;
	localStorage.setItem(viewWeekKey(leagueId, userId), String(clampSimulatedWeek(week)));
}
