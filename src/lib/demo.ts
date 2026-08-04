import { browser } from '$app/environment';
import {
	compareTiebreaker,
	DEFAULT_TIEBREAKER_MODE,
	DEFAULT_UNDERDOG_THRESHOLD,
	type TiebreakerMode,
	parseTiebreakerMode
} from '$lib/leagueRules';
import { isDemoSeason } from '$lib/season';
import type { DemoPick, DemoState, ScoredDemoPick } from '$lib/types/demo';
import type { WeekGame } from '$lib/types/game';
import type { LeaguePick, PickOutcome, StandingRow } from '$lib/types/standings';

const STORAGE_PREFIX = 'golden-spoon-demo';

export { DEFAULT_UNDERDOG_THRESHOLD };

export function demoStorageKey(leagueId: string, userId: string): string {
	return `${STORAGE_PREFIX}:${leagueId}:${userId}`;
}

export const MIN_SIMULATED_WEEK = 1;
export const MAX_SIMULATED_WEEK = 18;

export function createEmptyDemoState(simulatedWeek: number = MIN_SIMULATED_WEEK): DemoState {
	return {
		enabled: false,
		simulatedWeek: clampSimulatedWeek(simulatedWeek),
		picks: {}
	};
}

export function loadDemoState(leagueId: string, userId: string, seasonYear?: number): DemoState {
	if (!browser) return createEmptyDemoState();

	const demoDefaultWeek =
		seasonYear !== undefined && isDemoSeason(seasonYear) ? MAX_SIMULATED_WEEK : MIN_SIMULATED_WEEK;

	try {
		const raw = localStorage.getItem(demoStorageKey(leagueId, userId));
		if (!raw) {
			return seasonYear !== undefined && isDemoSeason(seasonYear)
				? { ...createEmptyDemoState(demoDefaultWeek), enabled: true }
				: createEmptyDemoState();
		}
		const parsed = JSON.parse(raw) as DemoState;
		const state: DemoState = {
			enabled: Boolean(parsed.enabled),
			simulatedWeek: clampSimulatedWeek(Number(parsed.simulatedWeek) || demoDefaultWeek),
			picks: parsed.picks ?? {}
		};
		if (seasonYear !== undefined && isDemoSeason(seasonYear)) {
			state.enabled = true;
		} else if (seasonYear !== undefined && !isDemoSeason(seasonYear)) {
			state.enabled = false;
		}
		return state;
	} catch {
		return seasonYear !== undefined && isDemoSeason(seasonYear)
			? { ...createEmptyDemoState(demoDefaultWeek), enabled: true }
			: createEmptyDemoState();
	}
}

export function saveDemoState(leagueId: string, userId: string, state: DemoState): void {
	if (!browser) return;
	localStorage.setItem(demoStorageKey(leagueId, userId), JSON.stringify(state));
}

export function resetDemoPicks(state: DemoState): DemoState {
	return {
		...state,
		picks: {}
	};
}

export function hasDemoPicks(state: DemoState): boolean {
	return Object.keys(state.picks).length > 0;
}

export function clampSimulatedWeek(week: number): number {
	return Math.min(MAX_SIMULATED_WEEK, Math.max(MIN_SIMULATED_WEEK, week));
}

export function getActivePickWeek(simulatedWeek: number): number {
	return clampSimulatedWeek(simulatedWeek);
}

export function canPickWeek(week: number, simulatedWeek: number): boolean {
	return getActivePickWeek(simulatedWeek) === week;
}

export function resultsVisibleForWeek(week: number, simulatedWeek: number): boolean {
	return simulatedWeek > week;
}

export function getUsedTeamIds(picks: Record<number, DemoPick>): Set<string> {
	return new Set(Object.values(picks).map((pick) => pick.team_id));
}

export function isUnderdog(winPct: number, threshold = DEFAULT_UNDERDOG_THRESHOLD): boolean {
	return winPct <= threshold;
}

export function resolveOutcome(teamId: string, game: WeekGame): PickOutcome {
	if (game.status === 'cancelled') return 'void';
	if (game.status !== 'final') return 'pending';
	if (game.is_tie) return 'tie';
	if (game.winner_team_id === teamId) return 'win';
	return 'loss';
}

export function pointsForOutcome(outcome: PickOutcome, isUnderdogPick: boolean): number {
	switch (outcome) {
		case 'win':
			return isUnderdogPick ? 2 : 1;
		case 'tie':
			return 0.5;
		default:
			return 0;
	}
}

export function scoreDemoPick(
	weekNumber: number,
	pick: DemoPick,
	game: WeekGame | null,
	simulatedWeek: number
): ScoredDemoPick | null {
	if (!resultsVisibleForWeek(weekNumber, simulatedWeek) || !game) {
		return null;
	}

	const outcome = resolveOutcome(pick.team_id, game);
	const points_awarded = pointsForOutcome(outcome, pick.is_underdog_at_pick);

	return {
		...pick,
		week_number: weekNumber,
		outcome,
		points_awarded
	};
}

export function getTeamWinPct(game: WeekGame, teamId: string): number | null {
	if (teamId === game.home.id) return game.home_win_pct;
	if (teamId === game.away.id) return game.away_win_pct;
	return null;
}

export function buildDemoPick(
	game: WeekGame,
	teamId: string,
	threshold = DEFAULT_UNDERDOG_THRESHOLD,
	allowMissingWinPct = false
): DemoPick | null {
	const team = teamId === game.home.id ? game.home : teamId === game.away.id ? game.away : null;
	const winPct = getTeamWinPct(game, teamId);
	if (!team || (winPct === null && !allowMissingWinPct)) return null;

	const effectiveWinPct = winPct ?? 50;

	return {
		game_id: game.id,
		team_id: team.id,
		team_abbreviation: team.abbreviation,
		team_name: team.name,
		win_pct_at_pick: effectiveWinPct,
		is_underdog_at_pick: isUnderdog(effectiveWinPct, threshold)
	};
}

export function simulatedWeekLabel(simulatedWeek: number): string {
	return `Week ${clampSimulatedWeek(simulatedWeek)}`;
}

export function getLatestScoredPick(
	state: DemoState,
	gamesByWeek: Map<number, WeekGame[]>
): ScoredDemoPick | null {
	const weeks = Object.keys(state.picks)
		.map(Number)
		.filter((week) => resultsVisibleForWeek(week, state.simulatedWeek))
		.sort((a, b) => b - a);

	for (const week of weeks) {
		const pick = state.picks[week];
		const games = gamesByWeek.get(week) ?? [];
		const game = games.find((g) => g.id === pick.game_id) ?? null;
		const scored = scoreDemoPick(week, pick, game, state.simulatedWeek);
		if (scored) return scored;
	}

	return null;
}

export function outcomeLabel(outcome: PickOutcome): string {
	switch (outcome) {
		case 'win':
			return 'Win';
		case 'loss':
			return 'Loss';
		case 'tie':
			return 'Tie';
		case 'missed':
			return 'Missed';
		case 'void':
			return 'Void';
		default:
			return 'Pending';
	}
}

export function formatPoints(points: number): string {
	return Number.isInteger(points) ? String(points) : points.toFixed(1);
}

export function formatWinPct(pct: number | null): string {
	if (pct === null) return '—';
	return `${Math.round(pct)}%`;
}

/** Latest week whose picks/results appear on the league page while time traveling. */
export function getMaxVisibleWeek(simulatedWeek: number): number {
	const week = clampSimulatedWeek(simulatedWeek);
	return Math.max(0, week - 1);
}

function recordFromPicksForStandings(
	picks: LeaguePick[]
): Pick<StandingRow, 'wins' | 'losses' | 'ties'> {
	let wins = 0;
	let losses = 0;
	let ties = 0;

	for (const pick of picks) {
		if (pick.outcome === 'win') wins += 1;
		else if (pick.outcome === 'tie') ties += 1;
		else if (pick.outcome === 'loss' || pick.outcome === 'missed') losses += 1;
	}

	return { wins, losses, ties };
}

function demoPickToLeaguePick(
	week: number,
	pick: DemoPick,
	scored: ScoredDemoPick | null,
	userId: string,
	displayName: string,
	game: WeekGame | null
): LeaguePick {
	return {
		id: `demo-${userId}-${week}`,
		user_id: userId,
		display_name: displayName,
		week_number: week,
		team_id: pick.team_id,
		team_abbreviation: pick.team_abbreviation,
		team_name: pick.team_name,
		win_pct_at_pick: pick.win_pct_at_pick,
		is_underdog_at_pick: pick.is_underdog_at_pick,
		outcome: scored?.outcome ?? 'pending',
		points_awarded: scored?.points_awarded ?? 0,
		team_season_wins_at_pick: 0,
		game_id: pick.game_id,
		kickoff_at: game?.kickoff_at ?? new Date(0).toISOString(),
		is_missed: false,
		is_commissioner_override: false
	};
}

function buildStandingsFromPicks(
	picks: LeaguePick[],
	baseStandings: StandingRow[],
	userId: string,
	displayName: string,
	tiebreakerMode: TiebreakerMode = DEFAULT_TIEBREAKER_MODE,
	includeViewer = true
): StandingRow[] {
	const picksByUser = new Map<string, LeaguePick[]>();
	for (const pick of picks) {
		const list = picksByUser.get(pick.user_id) ?? [];
		list.push(pick);
		picksByUser.set(pick.user_id, list);
	}

	const namesByUser = new Map(baseStandings.map((row) => [row.user_id, row.display_name]));
	if (includeViewer && !namesByUser.has(userId)) {
		namesByUser.set(userId, displayName);
	}

	const userIds = new Set([...namesByUser.keys(), ...picksByUser.keys()]);
	if (!includeViewer) {
		userIds.delete(userId);
	}

	const rows: StandingRow[] = [...userIds].map((uid) => {
		const userPicks = picksByUser.get(uid) ?? [];
		const total_points = userPicks.reduce((sum, pick) => sum + Number(pick.points_awarded), 0);
		const pending_picks = userPicks.filter((pick) => pick.outcome === 'pending').length;
		const tiebreaker_picked_team_wins = userPicks.reduce(
			(sum, pick) => sum + (pick.team_season_wins_at_pick ?? 0),
			0
		);

		return {
			user_id: uid,
			display_name: namesByUser.get(uid) ?? displayName,
			total_points,
			tiebreaker_picked_team_wins,
			pending_picks,
			standing_rank: 0,
			...recordFromPicksForStandings(userPicks)
		};
	});

	rows.sort(
		(a, b) =>
			b.total_points - a.total_points ||
			compareTiebreaker(
				a.tiebreaker_picked_team_wins,
				b.tiebreaker_picked_team_wins,
				tiebreakerMode
			) ||
			a.display_name.localeCompare(b.display_name)
	);

	let rank = 1;
	return rows.map((row, index) => {
		if (index > 0) {
			const prev = rows[index - 1];
			const tied =
				row.total_points === prev.total_points &&
				row.tiebreaker_picked_team_wins === prev.tiebreaker_picked_team_wins;
			if (!tied) rank = index + 1;
		}
		return { ...row, standing_rank: rank };
	});
}

export function mergeDemoLeagueView(
	dbPicks: LeaguePick[],
	dbStandings: StandingRow[],
	demoState: DemoState,
	gamesByWeek: Map<number, WeekGame[]>,
	userId: string,
	displayName: string,
	tiebreakerMode: TiebreakerMode | string = DEFAULT_TIEBREAKER_MODE,
	includeViewer = true
): { picks: LeaguePick[]; standings: StandingRow[]; maxVisibleWeek: number } {
	const resolvedTiebreaker = parseTiebreakerMode(tiebreakerMode);
	if (!demoState.enabled) {
		return { picks: dbPicks, standings: dbStandings, maxVisibleWeek: 18 };
	}

	const maxVisibleWeek = getMaxVisibleWeek(demoState.simulatedWeek);

	const mergedPicks = dbPicks.filter(
		(pick) =>
			pick.week_number <= maxVisibleWeek && (includeViewer || pick.user_id !== userId)
	);

	if (includeViewer) {
		for (const [weekKey, demoPick] of Object.entries(demoState.picks)) {
			const week = Number(weekKey);
			if (week > maxVisibleWeek) continue;

			const games = gamesByWeek.get(week) ?? [];
			const game = games.find((g) => g.id === demoPick.game_id) ?? null;

			if (!resultsVisibleForWeek(week, demoState.simulatedWeek)) {
				continue;
			}

			const scored = scoreDemoPick(week, demoPick, game, demoState.simulatedWeek);
			mergedPicks.push(demoPickToLeaguePick(week, demoPick, scored, userId, displayName, game));
		}
	}

	const standings = buildStandingsFromPicks(
		mergedPicks,
		dbStandings,
		userId,
		displayName,
		resolvedTiebreaker,
		includeViewer
	);

	return { picks: mergedPicks, standings, maxVisibleWeek };
}
