import {
	DEFAULT_PICK_VISIBILITY,
	DEFAULT_TIEBREAKER_MODE,
	DEFAULT_UNDERDOG_THRESHOLD,
	type PickVisibility,
	type TiebreakerMode
} from '$lib/leagueRules';
import { getSupabase } from '$lib/supabase';
import type { League, LeagueWithRole } from '$lib/types/league';

export type CreateLeagueRules = {
	inviteCode: string;
	underdogThresholdPct?: number;
	tiebreakerMode?: TiebreakerMode;
	pickVisibility?: PickVisibility;
};

const LEAGUE_SELECT =
	'id, name, season_year, commissioner_id, invite_code, is_active, is_public_demo, created_at, underdog_threshold_pct, tiebreaker_mode, pick_visibility';

/** Seeded 2025 Scaglione Family Pool — public demo, no invite required. */
export const PUBLIC_DEMO_LEAGUE_ID = 'b0000001-0000-4000-8000-000000000001';

/** Normalize for storage/lookup: trim + lowercase. */
export function normalizeInviteCode(raw: string): string {
	return raw.trim().toLowerCase();
}

/** Client-side invite code rules (mirrors normalize_invite_code in SQL). */
export function validateInviteCode(raw: string): string | null {
	const code = normalizeInviteCode(raw);
	if (!code) return 'Invite code is required.';
	if (code.length < 3) return 'Invite code must be at least 3 characters.';
	if (code.length > 32) return 'Invite code must be at most 32 characters.';
	if (!/^[a-z0-9-]+$/.test(code)) {
		return 'Invite code can only use letters, numbers, and hyphens.';
	}
	return null;
}

function mapInviteError(message: string): string {
	if (/already in use/i.test(message) || /unique|duplicate/i.test(message)) {
		return 'That invite code is already in use. Pick a different one.';
	}
	if (/only use letters/i.test(message) || /at least 3/i.test(message) || /at most 32/i.test(message)) {
		return message;
	}
	return message;
}

function mapMembership(row: {
	league_id: string;
	joined_at: string;
	leagues: League | League[] | null;
}, userId: string): LeagueWithRole | null {
	const league = Array.isArray(row.leagues) ? row.leagues[0] : row.leagues;
	if (!league) return null;

	return {
		...league,
		is_commissioner: league.commissioner_id === userId,
		joined_at: row.joined_at
	};
}

export async function ensurePublicDemoMemberships(): Promise<{ error: string | null }> {
	const supabase = getSupabase();

	// Historical RPC name — after migration 029 this is a no-op (demo is view-only).
	const { error } = await supabase.rpc('ensure_public_demo_memberships');

	if (error) {
		const missingRpc =
			error.code === 'PGRST202' ||
			error.message.includes('ensure_public_demo_memberships') ||
			error.message.includes('Could not find the function') ||
			error.message.includes('is_public_demo');

		if (missingRpc) {
			return {
				error:
					'Public demo league is not set up on the database yet. Run migration 026 (and 029) in Supabase SQL Editor, or locally: npm run db:apply-public-demo-league then npm run db:apply-lock-public-demo (requires SUPABASE_DB_URL in .env).'
			};
		}
		return { error: error.message };
	}

	return { error: null };
}

function asLeagueWithRole(league: League, userId: string, joinedAt: string): LeagueWithRole {
	return {
		...league,
		is_public_demo: Boolean(league.is_public_demo),
		is_commissioner: league.commissioner_id === userId,
		joined_at: joinedAt
	};
}

export async function fetchMyLeagues(userId: string): Promise<{
	leagues: LeagueWithRole[];
	error: string | null;
}> {
	const supabase = getSupabase();

	const demoSetup = await ensurePublicDemoMemberships();
	if (demoSetup.error && !demoSetup.error.includes('not set up on the database yet')) {
		return { leagues: [], error: demoSetup.error };
	}

	const { data, error } = await supabase
		.from('league_members')
		.select(
			`
			league_id,
			joined_at,
			leagues (
				${LEAGUE_SELECT}
			)
		`
		)
		.eq('user_id', userId)
		.order('joined_at', { ascending: false });

	if (error) {
		// Older DBs without is_public_demo still work if the column select fails —
		// surface the original error so migration messaging is clear.
		if (error.message.includes('is_public_demo') && demoSetup.error) {
			return { leagues: [], error: demoSetup.error };
		}
		return { leagues: [], error: error.message };
	}

	const leagues = (data ?? [])
		.map((row) => mapMembership(row, userId))
		.filter((league): league is LeagueWithRole => league !== null)
		.map((league) => ({
			...league,
			is_public_demo: Boolean(league.is_public_demo)
		}));

	// Public demo is listed for every signed-in user without adding them as members.
	const { data: publicDemos, error: demoError } = await supabase
		.from('leagues')
		.select(LEAGUE_SELECT)
		.eq('is_public_demo', true)
		.eq('is_active', true);

	if (demoError && demoError.message.includes('is_public_demo') && demoSetup.error) {
		return { leagues: [], error: demoSetup.error };
	}

	const byId = new Map(leagues.map((league) => [league.id, league]));
	for (const row of publicDemos ?? []) {
		const league = row as League;
		if (byId.has(league.id)) continue;
		byId.set(
			league.id,
			asLeagueWithRole(league, userId, league.created_at)
		);
	}

	const merged = [...byId.values()].sort((a, b) => {
		// Keep public demos easy to find at the top.
		if (a.is_public_demo !== b.is_public_demo) {
			return a.is_public_demo ? -1 : 1;
		}
		return new Date(b.joined_at).getTime() - new Date(a.joined_at).getTime();
	});

	return { leagues: merged, error: null };
}

/** After sign-in: land on the sole real league, or the list when there are zero or many. Public demo does not count. */
export async function getPostAuthPath(userId: string, basePath: string): Promise<string> {
	const { leagues } = await fetchMyLeagues(userId);
	const playable = leagues.filter((league) => !league.is_public_demo);
	if (playable.length === 1) {
		return `${basePath}/league/${playable[0].id}`;
	}
	return `${basePath}/leagues`;
}

export async function createLeague(
	name: string,
	seasonYear: number,
	rules: CreateLeagueRules
): Promise<{ league: League | null; error: string | null }> {
	const supabase = getSupabase();
	const trimmedName = name.trim();

	if (!trimmedName) {
		return { league: null, error: 'League name is required.' };
	}

	const inviteError = validateInviteCode(rules.inviteCode);
	if (inviteError) {
		return { league: null, error: inviteError };
	}

	const {
		data: { session }
	} = await supabase.auth.getSession();

	if (!session) {
		return { league: null, error: 'Session expired. Please sign in again.' };
	}

	const { data, error } = await supabase.rpc('create_league', {
		p_name: trimmedName,
		p_season_year: seasonYear,
		p_invite_code: normalizeInviteCode(rules.inviteCode),
		p_underdog_threshold_pct: rules.underdogThresholdPct ?? DEFAULT_UNDERDOG_THRESHOLD,
		p_tiebreaker_mode: rules.tiebreakerMode ?? DEFAULT_TIEBREAKER_MODE,
		p_pick_visibility: rules.pickVisibility ?? DEFAULT_PICK_VISIBILITY
	});

	if (error) {
		if (error.message.includes('create_league') && error.code === 'PGRST202') {
			return {
				league: null,
				error:
					'Create function missing. Run supabase/migrations/023_custom_invite_codes.sql in Supabase.'
			};
		}
		return { league: null, error: mapInviteError(error.message) };
	}

	return { league: { ...(data as League), is_public_demo: Boolean((data as League).is_public_demo) }, error: null };
}

export async function updateLeagueInviteCode(
	leagueId: string,
	inviteCode: string
): Promise<{ inviteCode: string | null; error: string | null }> {
	const inviteError = validateInviteCode(inviteCode);
	if (inviteError) {
		return { inviteCode: null, error: inviteError };
	}

	const { data, error } = await getSupabase().rpc('update_league_invite_code', {
		p_league_id: leagueId,
		p_invite_code: normalizeInviteCode(inviteCode)
	});

	if (error) {
		if (error.code === 'PGRST202' || error.message.includes('update_league_invite_code')) {
			return {
				inviteCode: null,
				error:
					'Invite update is not set up yet. Run supabase/migrations/023_custom_invite_codes.sql in Supabase.'
			};
		}
		return { inviteCode: null, error: mapInviteError(error.message) };
	}

	const league = data as League;
	return { inviteCode: league.invite_code, error: null };
}

export async function joinLeagueByInvite(
	inviteCode: string
): Promise<{ leagueId: string | null; error: string | null }> {
	const supabase = getSupabase();
	const code = normalizeInviteCode(inviteCode);

	if (!code) {
		return { leagueId: null, error: 'Invite code is required.' };
	}

	const { data, error } = await supabase.rpc('join_league_by_invite', {
		p_invite_code: code
	});

	if (error) {
		if (error.message.includes('join_league_by_invite')) {
			return {
				leagueId: null,
				error: 'Join function missing. Run supabase/migrations/002_league_helpers.sql in Supabase.'
			};
		}
		return { leagueId: null, error: error.message };
	}

	return { leagueId: data as string, error: null };
}

export async function adminKickLeagueMember(
	leagueId: string,
	userId: string
): Promise<{ error: string | null }> {
	const supabase = getSupabase();

	const { error } = await supabase.rpc('admin_kick_league_member', {
		p_league_id: leagueId,
		p_user_id: userId
	});

	if (error) {
		const missingRpc =
			error.code === 'PGRST202' ||
			error.message.includes('admin_kick_league_member') ||
			error.message.includes('Could not find the function');

		if (missingRpc) {
			return {
				error:
					'Remove is not set up on the database yet. Run migration 006 in Supabase SQL Editor, or locally: npm run db:apply-admin-kick (requires SUPABASE_DB_URL in .env).'
			};
		}
		return { error: error.message };
	}

	return { error: null };
}

export async function adminDeleteLeague(
	leagueId: string
): Promise<{ error: string | null }> {
	const supabase = getSupabase();

	const { error } = await supabase.rpc('admin_delete_league', {
		p_league_id: leagueId
	});

	if (error) {
		const missingRpc =
			error.code === 'PGRST202' ||
			error.message.includes('admin_delete_league') ||
			error.message.includes('Could not find the function');

		if (missingRpc) {
			return {
				error:
					'Delete league is not set up on the database yet. Run migration 025 in Supabase SQL Editor, or locally: npm run db:apply-admin-delete-league (requires SUPABASE_DB_URL in .env).'
			};
		}
		return { error: error.message };
	}

	return { error: null };
}

export async function fetchLeague(
	leagueId: string,
	userId: string
): Promise<{ league: LeagueWithRole | null; error: string | null }> {
	const supabase = getSupabase();

	// Keep RPC for setup detection; after 029 it no longer inserts memberships.
	await ensurePublicDemoMemberships();

	const { data, error } = await supabase
		.from('leagues')
		.select(LEAGUE_SELECT)
		.eq('id', leagueId)
		.single();

	if (error || !data) {
		return { league: null, error: error?.message ?? 'League not found.' };
	}

	const league = data as League;
	const isPublicDemo = Boolean(league.is_public_demo);

	const { data: membership } = await supabase
		.from('league_members')
		.select('joined_at')
		.eq('league_id', leagueId)
		.eq('user_id', userId)
		.maybeSingle();

	if (!membership && !isPublicDemo) {
		return { league: null, error: 'League not found.' };
	}

	return {
		league: asLeagueWithRole(
			league,
			userId,
			membership?.joined_at ?? league.created_at
		),
		error: null
	};
}

export function currentNflSeasonYear(): number {
	const now = new Date();
	// NFL season spans two calendar years; Jan–Feb belongs to prior season's playoffs.
	if (now.getMonth() < 2) {
		return now.getFullYear() - 1;
	}
	return now.getFullYear();
}
