import { isSeasonEnd, regularSeasonWeek } from '$lib/demo';
import { fetchSeasonWeekCompletion, resolveCurrentWeek } from '$lib/games';
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
let refreshToken = 0;

export function formatSeasonWeekLabel(_seasonYear: number, week: number): string {
	if (isSeasonEnd(week)) return 'Season End';
	return `Week ${week}`;
}

export function getSeasonIndicatorLabel(): string {
	return formatSeasonWeekLabel(indicator.seasonYear, indicator.week);
}

/** Shown on hover when the live season is still in Week 1. */
export function getSeasonIndicatorTooltip(): string | null {
	if (indicator.seasonYear === DEMO_SEASON_YEAR) return null;
	if (indicator.week !== 1) return null;
	return "You're actively in Week 1 until the final Week 1 game has concluded, or Tuesday at midnight — whichever comes first.";
}

async function refreshLiveSeasonIndicator(seasonYear = 2026) {
	if (isDemoSeason(seasonYear)) return;
	const token = ++refreshToken;
	const { weeks, error } = await fetchSeasonWeekCompletion(seasonYear);
	if (token !== refreshToken) return;
	indicator = {
		seasonYear,
		week: error ? getCurrentWeekFromDate(qaNowDate(), seasonYear) : resolveCurrentWeek(weeks, qaNowDate(), seasonYear)
	};
}

export function initSeasonIndicator() {
	indicator = liveIndicator();
	void refreshLiveSeasonIndicator();
}

export function setLiveSeasonIndicator(seasonYear = 2026) {
	indicator = liveIndicator(seasonYear);
	void refreshLiveSeasonIndicator(seasonYear);
}

export function syncSeasonIndicatorForLeague(seasonYear: number, simulatedWeek = 1) {
	if (isDemoSeason(seasonYear)) {
		indicator = {
			seasonYear: DEMO_SEASON_YEAR,
			week: isSeasonEnd(simulatedWeek) ? simulatedWeek : regularSeasonWeek(simulatedWeek)
		};
		return;
	}

	setLiveSeasonIndicator(seasonYear);
}
