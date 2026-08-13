import { isQaClockEnabled } from '$lib/qaClock.svelte';
import { getSupabase } from '$lib/supabase';
import type { SyncResult } from '$lib/sync/types';

const SYNC_FUNCTION = 'sync-nfl-data';

const EMPTY_RESULT: SyncResult = {
	skipped: false,
	inProgress: false,
	lastSyncAt: null,
	gamesUpdated: 0,
	oddsUpdated: 0,
	kickoffLocksApplied: 0,
	missedPicksInserted: 0,
	error: null
};

export async function requestGameSync(): Promise<SyncResult> {
	// QA Mode owns game rows and the simulated clock. A live nflverse pull would
	// clobber simulated scores/status and lock using wall-clock time.
	if (isQaClockEnabled()) {
		return { ...EMPTY_RESULT, skipped: true };
	}

	const supabase = getSupabase();
	const { data, error } = await supabase.functions.invoke<SyncResult>(SYNC_FUNCTION);

	if (error) {
		return { ...EMPTY_RESULT, error: error.message };
	}

	return data ?? { ...EMPTY_RESULT, error: 'Empty sync response' };
}

export async function getLastSyncTime(): Promise<string | null> {
	const supabase = getSupabase();
	const { data } = await supabase
		.from('sync_state')
		.select('last_completed_at')
		.eq('key', 'nfl_games')
		.single();

	return data?.last_completed_at ?? null;
}

export function formatSyncTimeAgo(iso: string | null): string | null {
	if (!iso) return null;
	const ms = Date.now() - new Date(iso).getTime();
	if (ms < 60_000) return 'just now';
	const minutes = Math.floor(ms / 60_000);
	if (minutes < 60) return `${minutes} min ago`;
	const hours = Math.floor(minutes / 60);
	if (hours < 48) return `${hours} hr ago`;
	const days = Math.floor(hours / 24);
	return `${days} day${days === 1 ? '' : 's'} ago`;
}

export type { SyncResult };
