import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { runSync, runSyncSideEffects, SYNC_STATE_KEY } from '../_shared/sync/index.ts';

const COOLDOWN_MS = 5 * 60 * 1000;
const LOCK_TIMEOUT_MS = 2 * 60 * 1000;
const DEFAULT_SEASON = 2026;

const corsHeaders = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

Deno.serve(async (req) => {
	if (req.method === 'OPTIONS') {
		return new Response('ok', { headers: corsHeaders });
	}

	try {
		const supabaseUrl = Deno.env.get('SUPABASE_URL');
		const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
		if (!supabaseUrl || !serviceRoleKey) {
			return Response.json(
				{ error: 'Missing Supabase environment variables' },
				{ status: 500, headers: corsHeaders }
			);
		}

		const adminClient = createClient(supabaseUrl, serviceRoleKey);

		// QA Mode: run only the time-dependent side effects against the simulated
		// clock, skipping the nflverse fetch + cooldown so simulated games survive.
		let reqBody: Record<string, unknown> = {};
		try {
			reqBody = (await req.json()) as Record<string, unknown>;
		} catch {
			reqBody = {};
		}

		if (reqBody?.qa === true) {
			const { data: qaNow, error: qaNowError } = await adminClient.rpc('qa_now');
			if (qaNowError) {
				return Response.json(
					{ error: `qa_now read failed: ${qaNowError.message}` },
					{ status: 500, headers: corsHeaders }
				);
			}

			const nowIso = new Date(qaNow as string).toISOString();
			const seasonYear =
				typeof reqBody.seasonYear === 'number' ? reqBody.seasonYear : DEFAULT_SEASON;

			try {
				const result = await runSyncSideEffects(adminClient, seasonYear, nowIso);
				return Response.json(
					{ skipped: false, inProgress: false, ...result },
					{ headers: corsHeaders }
				);
			} catch (err) {
				const message = err instanceof Error ? err.message : String(err);
				return Response.json(
					{
						skipped: false,
						inProgress: false,
						lastSyncAt: null,
						gamesUpdated: 0,
						oddsUpdated: 0,
						kickoffLocksApplied: 0,
						missedPicksInserted: 0,
						error: message
					},
					{ status: 500, headers: corsHeaders }
				);
			}
		}

		const { data: state, error: stateError } = await adminClient
			.from('sync_state')
			.select('last_started_at, last_completed_at, games_updated, odds_updated')
			.eq('key', SYNC_STATE_KEY)
			.single();

		if (stateError) {
			return Response.json(
				{ error: `sync_state read failed: ${stateError.message}` },
				{ status: 500, headers: corsHeaders }
			);
		}

		const now = Date.now();

		if (state?.last_completed_at) {
			const age = now - new Date(state.last_completed_at).getTime();
			if (age < COOLDOWN_MS) {
				return Response.json(
					{
						skipped: true,
						inProgress: false,
						lastSyncAt: state.last_completed_at,
						gamesUpdated: 0,
						oddsUpdated: 0,
						kickoffLocksApplied: 0,
						missedPicksInserted: 0,
						error: null
					},
					{ headers: corsHeaders }
				);
			}
		}

		if (state?.last_started_at && !state?.last_completed_at) {
			const age = now - new Date(state.last_started_at).getTime();
			if (age < LOCK_TIMEOUT_MS) {
				return Response.json(
					{
						skipped: false,
						inProgress: true,
						lastSyncAt: state.last_completed_at,
						gamesUpdated: 0,
						oddsUpdated: 0,
						kickoffLocksApplied: 0,
						missedPicksInserted: 0,
						error: null
					},
					{ headers: corsHeaders }
				);
			}
		}

		await adminClient
			.from('sync_state')
			.update({
				last_started_at: new Date().toISOString(),
				last_completed_at: null,
				last_error: null,
				updated_at: new Date().toISOString()
			})
			.eq('key', SYNC_STATE_KEY);

		let body: Record<string, unknown>;
		try {
			const result = await runSync(adminClient, DEFAULT_SEASON);
			await adminClient
				.from('sync_state')
				.update({
					last_completed_at: result.lastSyncAt,
					games_updated: result.gamesUpdated,
					odds_updated: result.oddsUpdated,
					last_error: null,
					updated_at: new Date().toISOString()
				})
				.eq('key', SYNC_STATE_KEY);

			body = { skipped: false, inProgress: false, ...result };
		} catch (err) {
			const message = err instanceof Error ? err.message : String(err);
			await adminClient
				.from('sync_state')
				.update({
					last_error: message,
					last_completed_at: new Date().toISOString(),
					updated_at: new Date().toISOString()
				})
				.eq('key', SYNC_STATE_KEY);

			return Response.json(
				{
					skipped: false,
					inProgress: false,
					lastSyncAt: null,
					gamesUpdated: 0,
					oddsUpdated: 0,
					kickoffLocksApplied: 0,
					missedPicksInserted: 0,
					error: message
				},
				{ status: 500, headers: corsHeaders }
			);
		}

		return Response.json(body, { headers: corsHeaders });
	} catch (err) {
		const message = err instanceof Error ? err.message : String(err);
		return Response.json({ error: message }, { status: 500, headers: corsHeaders });
	}
});
