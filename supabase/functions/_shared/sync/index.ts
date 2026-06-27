import type { SupabaseClient } from '@supabase/supabase-js';
import { upsertGames, updateTeamRecords } from './applyUpdates.ts';
import { diffGames, type GameDbRow } from './diffGames.ts';
import { lockKickoffWinPcts } from './kickoffLock.ts';
import { markMissedPicks } from './missedPicks.ts';
import { fetchNflverseGames } from './nflverse.ts';
import type { SyncResult } from './types.ts';

export async function runSync(
	adminClient: SupabaseClient,
	seasonYear: number
): Promise<Omit<SyncResult, 'skipped' | 'inProgress'>> {
	const incoming = await fetchNflverseGames(seasonYear);

	const { data: currentRows, error: loadError } = await adminClient
		.from('nfl_games')
		.select(
			'espn_event_id, status, home_score, away_score, winner_team_id, is_tie, home_win_pct, away_win_pct, kickoff_at'
		)
		.eq('season_year', seasonYear);

	if (loadError) {
		throw new Error(`runSync load games failed: ${loadError.message}`);
	}

	const { toUpsert, oddsChanged } = diffGames(incoming, (currentRows ?? []) as GameDbRow[]);

	let gamesUpdated = 0;
	if (toUpsert.length > 0) {
		gamesUpdated = await upsertGames(adminClient, toUpsert);
		await updateTeamRecords(adminClient, seasonYear, incoming);
	}

	const kickoffLocksApplied = await lockKickoffWinPcts(adminClient, seasonYear);
	const missedPicksInserted = await markMissedPicks(adminClient, seasonYear);

	return {
		lastSyncAt: new Date().toISOString(),
		gamesUpdated,
		oddsUpdated: oddsChanged,
		kickoffLocksApplied,
		missedPicksInserted,
		error: null
	};
}

/**
 * QA Mode: run only the time-dependent side effects (kickoff win-% lock and
 * missed-pick generation) against an injected "now", WITHOUT fetching nflverse
 * or upserting games. This lets us exercise the real sync logic over simulated
 * game rows + a simulated clock without the live feed clobbering them.
 */
export async function runSyncSideEffects(
	adminClient: SupabaseClient,
	seasonYear: number,
	nowIso: string
): Promise<Omit<SyncResult, 'skipped' | 'inProgress'>> {
	const kickoffLocksApplied = await lockKickoffWinPcts(adminClient, seasonYear, nowIso);
	const missedPicksInserted = await markMissedPicks(adminClient, seasonYear, nowIso);

	return {
		lastSyncAt: nowIso,
		gamesUpdated: 0,
		oddsUpdated: 0,
		kickoffLocksApplied,
		missedPicksInserted,
		error: null
	};
}

export type { SyncResult } from './types.ts';
export { SYNC_STATE_KEY, DEFAULT_SEASON_YEAR } from './types.ts';
