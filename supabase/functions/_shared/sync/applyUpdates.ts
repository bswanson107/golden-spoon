import type { SupabaseClient } from '@supabase/supabase-js';
import type { GameSyncRow } from './types.ts';

type DbGameUpsert = {
	season_year: number;
	week_number: number;
	home_team_id: string;
	away_team_id: string;
	kickoff_at: string;
	status: string;
	home_score: number | null;
	away_score: number | null;
	is_tie: boolean;
	winner_team_id: string | null;
	home_win_pct: number | null;
	away_win_pct: number | null;
	win_pct_source: string | null;
	win_pct_updated_at: string | null;
	espn_event_id: string;
};

function toDbRow(game: GameSyncRow): DbGameUpsert {
	const hasWinPct = game.homeWinPct !== null && game.awayWinPct !== null;
	return {
		season_year: game.season,
		week_number: game.week,
		home_team_id: game.homeTeam,
		away_team_id: game.awayTeam,
		kickoff_at: game.kickoffAtUtc,
		status: game.status,
		home_score: game.homeScore,
		away_score: game.awayScore,
		is_tie: game.isTie,
		winner_team_id: game.winner,
		home_win_pct: game.homeWinPct,
		away_win_pct: game.awayWinPct,
		win_pct_source: hasWinPct ? (game.winPctSource ?? 'moneyline') : null,
		win_pct_updated_at: hasWinPct
			? (game.winPctUpdatedAt ?? new Date().toISOString())
			: null,
		espn_event_id: game.espnEventId
	};
}

export async function upsertGames(
	adminClient: SupabaseClient,
	games: GameSyncRow[]
): Promise<number> {
	if (games.length === 0) return 0;

	const rows = games.map(toDbRow);
	const { error } = await adminClient.from('nfl_games').upsert(rows, {
		onConflict: 'espn_event_id'
	});

	if (error) throw new Error(`upsertGames failed: ${error.message}`);
	return rows.length;
}

export async function updateTeamRecords(
	adminClient: SupabaseClient,
	seasonYear: number,
	games: GameSyncRow[]
): Promise<void> {
	const records = new Map<
		string,
		{ wins: number; losses: number; ties: number; points_for: number; points_against: number }
	>();

	for (const game of games) {
		if (game.status !== 'final') continue;
		if (game.awayScore === null || game.homeScore === null) continue;

		for (const teamId of [game.awayTeam, game.homeTeam]) {
			if (!records.has(teamId)) {
				records.set(teamId, {
					wins: 0,
					losses: 0,
					ties: 0,
					points_for: 0,
					points_against: 0
				});
			}
		}

		const away = records.get(game.awayTeam)!;
		const home = records.get(game.homeTeam)!;

		away.points_for += game.awayScore;
		away.points_against += game.homeScore;
		home.points_for += game.homeScore;
		home.points_against += game.awayScore;

		if (game.isTie) {
			away.ties += 1;
			home.ties += 1;
		} else if (game.winner === game.awayTeam) {
			away.wins += 1;
			home.losses += 1;
		} else if (game.winner === game.homeTeam) {
			home.wins += 1;
			away.losses += 1;
		}
	}

	if (records.size === 0) return;

	const now = new Date().toISOString();
	const rows = [...records.entries()].map(([team_id, rec]) => ({
		season_year: seasonYear,
		team_id,
		wins: rec.wins,
		losses: rec.losses,
		ties: rec.ties,
		points_for: rec.points_for,
		points_against: rec.points_against,
		updated_at: now
	}));

	const { error } = await adminClient
		.from('season_team_records')
		.upsert(rows, { onConflict: 'season_year,team_id' });

	if (error) throw new Error(`updateTeamRecords failed: ${error.message}`);
}
