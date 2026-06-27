import { browser } from '$app/environment';
import { getSupabase } from '$lib/supabase';

/**
 * QA Mode clock — single client-side source of "now".
 *
 * When the QA clock is enabled (set by an app admin on /qa), every business
 * helper that previously read `Date.now()` / `new Date()` reads `qaNow()` /
 * `qaNowDate()` instead, so the whole UI behaves as if it were the simulated
 * minute. The value is mirrored from the DB `qa_clock` row (see migration 018)
 * and cached in localStorage for instant first paint.
 *
 * When disabled, qaNow() falls back to the real wall clock — live behavior is
 * unchanged.
 */

type QaClockState = {
	enabled: boolean;
	simulatedNowMs: number | null;
};

const STORAGE_KEY = 'golden-spoon-qa-clock';

const clock = $state<QaClockState>({ enabled: false, simulatedNowMs: null });

function readCache(): QaClockState | null {
	if (!browser) return null;
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		if (!raw) return null;
		const parsed = JSON.parse(raw) as QaClockState;
		return {
			enabled: !!parsed.enabled,
			simulatedNowMs:
				typeof parsed.simulatedNowMs === 'number' ? parsed.simulatedNowMs : null
		};
	} catch {
		return null;
	}
}

function writeCache(): void {
	if (!browser) return;
	try {
		localStorage.setItem(
			STORAGE_KEY,
			JSON.stringify({ enabled: clock.enabled, simulatedNowMs: clock.simulatedNowMs })
		);
	} catch {
		/* ignore */
	}
}

/** Current "now" in epoch ms — simulated when the QA clock is enabled. */
export function qaNow(): number {
	if (clock.enabled && clock.simulatedNowMs !== null) {
		return clock.simulatedNowMs;
	}
	return Date.now();
}

/** Current "now" as a Date — simulated when the QA clock is enabled. */
export function qaNowDate(): Date {
	return new Date(qaNow());
}

export function isQaClockEnabled(): boolean {
	return clock.enabled;
}

export function qaSimulatedNowMs(): number | null {
	return clock.enabled ? clock.simulatedNowMs : null;
}

function applyState(enabled: boolean, simulatedNowMs: number | null): void {
	clock.enabled = enabled;
	clock.simulatedNowMs = simulatedNowMs;
	writeCache();
}

type QaClockRow = {
	enabled: boolean;
	simulated_now: string | null;
};

function ingestRow(row: QaClockRow | null | undefined): void {
	if (!row) return;
	applyState(
		!!row.enabled,
		row.simulated_now ? new Date(row.simulated_now).getTime() : null
	);
}

/** Load the clock from cache (sync) then the DB (async). Call once on app load. */
export async function hydrateQaClock(): Promise<void> {
	if (!browser) return;

	const cached = readCache();
	if (cached) {
		clock.enabled = cached.enabled;
		clock.simulatedNowMs = cached.simulatedNowMs;
	}

	try {
		const { data, error } = await getSupabase().rpc('qa_get_clock');
		if (error || !data) return;
		const row = (Array.isArray(data) ? data[0] : data) as QaClockRow;
		ingestRow(row);
	} catch {
		/* offline / not signed in — keep cached value */
	}
}

/**
 * Run time-dependent processing (kickoff win-% lock + auto-MNF / missed
 * assignment + scoring) for the simulated clock across all active seasons.
 * Mirrors what the production cron does, so every closed week always has a
 * value for every member. Best-effort: failures here never block the clock.
 */
async function runProcessing(): Promise<void> {
	try {
		await getSupabase().rpc('qa_run_processing', { p_season_year: null });
	} catch {
		/* admin-only / offline — ignore so the clock still updates */
	}
}

/** Push a new simulated time to the DB and update the local store. */
export async function setQaClock(simulatedNow: Date): Promise<{ error: string | null }> {
	const { data, error } = await getSupabase().rpc('qa_set_clock', {
		p_now: simulatedNow.toISOString()
	});
	if (error) return { error: error.message };
	ingestRow((Array.isArray(data) ? data[0] : data) as QaClockRow);
	// Advancing time closes weeks → assign auto-MNF / missed picks for them.
	await runProcessing();
	return { error: null };
}

/** Disable the QA clock (return to live wall-clock time). */
export async function clearQaClock(): Promise<{ error: string | null }> {
	const { data, error } = await getSupabase().rpc('qa_clear_clock');
	if (error) return { error: error.message };
	ingestRow((Array.isArray(data) ? data[0] : data) as QaClockRow);
	return { error: null };
}
