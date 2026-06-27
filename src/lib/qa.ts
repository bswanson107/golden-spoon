import { getSupabase } from '$lib/supabase';

export type GameResult = 'home' | 'away' | 'tie';

export async function qaSimulateWeek(
	seasonYear: number,
	weekNumber: number,
	result: GameResult = 'home'
): Promise<{ count: number; error: string | null }> {
	const { data, error } = await getSupabase().rpc('qa_simulate_week', {
		p_season_year: seasonYear,
		p_week_number: weekNumber,
		p_result: result
	});
	return { count: (data as number) ?? 0, error: error?.message ?? null };
}

export async function qaSetGameResult(
	gameId: string,
	result: GameResult
): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('qa_set_game_result', {
		p_game_id: gameId,
		p_result: result
	});
	return { error: error?.message ?? null };
}

export async function qaSetGameWinPct(
	gameId: string,
	homeWinPct: number,
	awayWinPct: number
): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('qa_set_game_winpct', {
		p_game_id: gameId,
		p_home_win_pct: homeWinPct,
		p_away_win_pct: awayWinPct
	});
	return { error: error?.message ?? null };
}

export async function qaResetWeek(
	seasonYear: number,
	weekNumber: number
): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('qa_reset_week', {
		p_season_year: seasonYear,
		p_week_number: weekNumber
	});
	return { error: error?.message ?? null };
}

export async function qaResetAll(seasonYear: number): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('qa_reset_all', {
		p_season_year: seasonYear
	});
	return { error: error?.message ?? null };
}

export type QaProcessingResult = {
	kickoffLocksApplied: number;
	autoOrMissedAssigned: number;
};

/**
 * Run the time-dependent side effects (kickoff win-% lock + auto-MNF / missed
 * assignment + scoring) against the simulated clock, entirely in the database.
 * Uses a SQL RPC so it does not depend on the edge function being deployed.
 */
export async function runQaProcessing(
	seasonYear: number
): Promise<{ result: QaProcessingResult | null; error: string | null }> {
	const { data, error } = await getSupabase().rpc('qa_run_processing', {
		p_season_year: seasonYear
	});
	if (error) return { result: null, error: error.message };
	return { result: (data as QaProcessingResult) ?? null, error: null };
}
