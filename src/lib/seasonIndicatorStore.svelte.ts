import { clampSimulatedWeek } from '$lib/demo';
import { qaNowDate } from '$lib/qaClock.svelte';
import { DEMO_SEASON_YEAR, getCurrentWeekFromDate, isDemoSeason } from '$lib/season';

type SeasonIndicator = {
	seasonYear: number;
	week: number;
};

function liveIndicator(seasonYear = 2026): SeasonIndicator {
	return {
		seasonYear,
		week: getCurrentWeekFromDate(qaNowDate(), seasonYear)
	};
}

let indicator = $state<SeasonIndicator>(liveIndicator());

export function formatSeasonWeekLabel(_seasonYear: number, week: number): string {
	return `Week ${week}`;
}

export function getSeasonIndicatorLabel(): string {
	return formatSeasonWeekLabel(indicator.seasonYear, indicator.week);
}

/** Shown on hover when the live season is still in Week 1. */
export function getSeasonIndicatorTooltip(): string | null {
	if (indicator.seasonYear === DEMO_SEASON_YEAR) return null;
	if (indicator.week !== 1) return null;
	return "You're actively in Week 1 until the final Week 1 game has concluded.";
}

export function initSeasonIndicator() {
	indicator = liveIndicator();
}

export function setLiveSeasonIndicator(seasonYear = 2026) {
	indicator = liveIndicator(seasonYear);
}

export function syncSeasonIndicatorForLeague(seasonYear: number, simulatedWeek = 1) {
	if (isDemoSeason(seasonYear)) {
		indicator = {
			seasonYear: DEMO_SEASON_YEAR,
			week: clampSimulatedWeek(simulatedWeek)
		};
		return;
	}

	setLiveSeasonIndicator(seasonYear);
}
