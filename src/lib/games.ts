import { getCurrentWeekFromDate, REGULAR_SEASON_WEEKS } from '$lib/season';
import { qaNowDate } from '$lib/qaClock.svelte';
import { getSupabase } from '$lib/supabase';
import type { GameStatus, NflTeam, WeekGame } from '$lib/types/game';

type TeamRow = {
	id: string;
	abbreviation: string;
	name: string;
	city: string | null;
};

type TeamRecordRow = {
	team_id: string;
	wins: number;
	losses: number;
	ties: number;
	points_for?: number;
	points_against?: number;
};

type TeamRecord = {
	wins: number;
	losses: number;
	ties: number;
	points_for: number;
	points_against: number;
};

type GameQueryRow = {
	id: string;
	week_number: number;
	kickoff_at: string;
	status: GameStatus;
	home_score: number | null;
	away_score: number | null;
	is_tie: boolean;
	winner_team_id: string | null;
	home_win_pct: number | null;
	away_win_pct: number | null;
	home_team: TeamRow | TeamRow[] | null;
	away_team: TeamRow | TeamRow[] | null;
};

function firstRelation<T>(value: T | T[] | null): T | null {
	if (!value) return null;
	return Array.isArray(value) ? (value[0] ?? null) : value;
}

function mapTeam(row: TeamRow | null, record: TeamRecord | undefined): NflTeam | null {
	if (!row) return null;
	return {
		id: row.id,
		abbreviation: row.abbreviation,
		name: row.name,
		city: row.city,
		wins: record?.wins ?? 0,
		losses: record?.losses ?? 0,
		ties: record?.ties ?? 0,
		points_for: record?.points_for ?? 0,
		points_against: record?.points_against ?? 0
	};
}

function mapGameRow(row: GameQueryRow, recordsByTeam: Map<string, TeamRecord>): WeekGame | null {
	const homeRow = firstRelation(row.home_team);
	const awayRow = firstRelation(row.away_team);
	const home = mapTeam(homeRow, homeRow ? recordsByTeam.get(homeRow.id) : undefined);
	const away = mapTeam(awayRow, awayRow ? recordsByTeam.get(awayRow.id) : undefined);
	if (!home || !away) return null;

	return {
		id: row.id,
		week_number: row.week_number,
		kickoff_at: row.kickoff_at,
		status: row.status,
		home_score: row.home_score,
		away_score: row.away_score,
		is_tie: row.is_tie,
		winner_team_id: row.winner_team_id,
		home_win_pct: row.home_win_pct !== null ? Number(row.home_win_pct) : null,
		away_win_pct: row.away_win_pct !== null ? Number(row.away_win_pct) : null,
		home,
		away
	};
}

export async function fetchWeekGames(
	seasonYear: number,
	weekNumber: number
): Promise<{ games: WeekGame[]; error: string | null }> {
	const supabase = getSupabase();

	const [gamesResult, recordsResult] = await Promise.all([
		supabase
			.from('nfl_games')
			.select(
				`
			id,
			week_number,
			kickoff_at,
			status,
			home_score,
			away_score,
			is_tie,
			winner_team_id,
			home_win_pct,
			away_win_pct,
			home_team:nfl_teams!home_team_id ( id, abbreviation, name, city ),
			away_team:nfl_teams!away_team_id ( id, abbreviation, name, city )
		`
			)
			.eq('season_year', seasonYear)
			.eq('week_number', weekNumber)
			.order('kickoff_at'),
		supabase
			.from('season_team_records')
			.select('team_id, wins, losses, ties, points_for, points_against')
			.eq('season_year', seasonYear)
	]);

	if (gamesResult.error) {
		return { games: [], error: gamesResult.error.message };
	}

	let recordRows = (recordsResult.data ?? []) as TeamRecordRow[];
	if (recordsResult.error) {
		// Pre-migration DBs may lack points_for / points_against — fall back to W-L only.
		const fallback = await supabase
			.from('season_team_records')
			.select('team_id, wins, losses, ties')
			.eq('season_year', seasonYear);
		if (!fallback.error) {
			recordRows = (fallback.data ?? []) as TeamRecordRow[];
		}
	}

	const recordsByTeam = new Map<string, TeamRecord>();
	for (const row of recordRows) {
		recordsByTeam.set(row.team_id, {
			wins: Number(row.wins) || 0,
			losses: Number(row.losses) || 0,
			ties: Number(row.ties) || 0,
			points_for: Number(row.points_for) || 0,
			points_against: Number(row.points_against) || 0
		});
	}

	const games = (gamesResult.data ?? [])
		.map((row) => mapGameRow(row as GameQueryRow, recordsByTeam))
		.filter((game): game is WeekGame => game !== null);

	return { games, error: null };
}

/** Season W-L(-T) string for pick UI and standings-style display. */
export function formatTeamRecord(team: Pick<NflTeam, 'wins' | 'losses' | 'ties'>): string {
	if (team.ties > 0) {
		return `${team.wins}-${team.losses}-${team.ties}`;
	}
	return `${team.wins}-${team.losses}`;
}

type WeekStatusQueryRow = {
	week_number: number;
	kickoff_at: string;
	status: GameStatus;
};

export type WeekCompletion = { week: number; complete: boolean };

/** Per-week completion for a season: a week is complete once its last (latest
 * kickoff) game is final or cancelled. */
export async function fetchSeasonWeekCompletion(
	seasonYear: number
): Promise<{ weeks: WeekCompletion[]; error: string | null }> {
	const supabase = getSupabase();

	const { data, error } = await supabase
		.from('nfl_games')
		.select('week_number, kickoff_at, status')
		.eq('season_year', seasonYear)
		.order('kickoff_at', { ascending: true });

	if (error) {
		return { weeks: [], error: error.message };
	}

	const lastByWeek = new Map<number, WeekStatusQueryRow>();
	for (const row of (data ?? []) as WeekStatusQueryRow[]) {
		const week = Number(row.week_number);
		if (!Number.isFinite(week) || week < 1) continue;
		// Ascending kickoff order → last write per week is the latest game (MNF).
		lastByWeek.set(week, { ...row, week_number: week });
	}

	const weeks = [...lastByWeek.entries()]
		.map(([week, row]) => ({
			week,
			complete: row.status === 'final' || row.status === 'cancelled'
		}))
		.sort((a, b) => a.week - b.week);

	return { weeks, error: null };
}

/**
 * Highest week to surface in the season grid from game results alone:
 * consecutive completed weeks (last kickoff final/cancelled) plus the next week.
 * Combine with the Tuesday-midnight calendar rule via `resolveCurrentWeek`.
 */
export function maxVisibleWeek(weeks: WeekCompletion[]): number {
	if (weeks.length === 0) return 1;
	const completeByWeek = new Map(weeks.map((w) => [Number(w.week), w.complete]));
	const lastWeek = Math.max(...weeks.map((w) => Number(w.week)), 1);

	let week = 1;
	while (week < lastWeek && completeByWeek.get(week) === true) {
		week += 1;
	}
	return Math.min(week, REGULAR_SEASON_WEEKS);
}

/** Compact final score, or null if the game is not complete with scores. */
export function formatFinalScore(
	game: WeekGame,
	awayName: string,
	homeName: string
): string | null {
	if (game.status !== 'final') return null;
	if (game.home_score === null || game.away_score === null) return null;
	return `${awayName} ${game.away_score} – ${game.home_score} ${homeName}`;
}

/**
 * Live current week: MNF final (or cancelled) for week N starts week N+1 immediately,
 * otherwise week N+1 starts at Tuesday 00:00 ET — whichever happens first.
 */
export function resolveCurrentWeek(
	completions: WeekCompletion[],
	now: Date = qaNowDate(),
	seasonYear = 2026
): number {
	const calendarWeek = getCurrentWeekFromDate(now, seasonYear);
	const fromGames = maxVisibleWeek(completions);
	return Math.min(REGULAR_SEASON_WEEKS, Math.max(calendarWeek, fromGames));
}
