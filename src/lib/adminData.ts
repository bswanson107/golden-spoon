import { getSupabase } from '$lib/supabase';

export type AdminLeagueRow = {
	id: string;
	name: string;
	season_year: number;
	commissioner_id: string;
	commissioner_name: string;
	member_count: number;
	is_public_demo: boolean;
	is_active: boolean;
	show_profile_pictures: boolean;
	show_parody_sponsorships: boolean;
	created_at: string;
};

export type AdminUserLeague = {
	id: string;
	name: string;
	season_year: number;
	is_commissioner: boolean;
	is_public_demo: boolean;
};

export type AdminPickAuditRow = {
	id: string;
	user_id: string;
	display_name: string;
	week_number: number;
	season_year: number;
	action: 'picked' | 'changed' | 'cleared';
	team_id: string | null;
	team_abbreviation: string | null;
	team_name: string | null;
	previous_team_id: string | null;
	previous_team_abbreviation: string | null;
	previous_team_name: string | null;
	created_at: string;
};

export type AdminUserRow = {
	user_id: string;
	email: string;
	display_name: string;
	avatar_key: string | null;
	can_change_display_name: boolean;
	created_at: string;
	leagues: AdminUserLeague[];
};

function missingRpcMessage(fn: string, applyScript: string): string {
	return `${fn} is not set up on the database yet. Run migration 032 in the Supabase SQL Editor, or locally: npm run ${applyScript} (requires SUPABASE_DB_URL in .env).`;
}

function isMissingRpc(error: { code?: string; message: string }, fn: string): boolean {
	return (
		error.code === 'PGRST202' ||
		error.message.includes(fn) ||
		error.message.includes('Could not find the function')
	);
}

export async function fetchAdminLeagues(): Promise<{
	leagues: AdminLeagueRow[];
	error: string | null;
}> {
	const { data, error } = await getSupabase().rpc('admin_list_leagues');

	if (error) {
		if (isMissingRpc(error, 'admin_list_leagues')) {
			return { leagues: [], error: missingRpcMessage('admin_list_leagues', 'db:apply-admin-directory') };
		}
		return { leagues: [], error: error.message };
	}

	const leagues = ((data ?? []) as AdminLeagueRow[]).map((row) => ({
		...row,
		member_count: Number(row.member_count),
		show_profile_pictures: Boolean(row.show_profile_pictures),
		show_parody_sponsorships: Boolean(row.show_parody_sponsorships)
	}));

	return { leagues, error: null };
}

export async function fetchAdminUsers(): Promise<{
	users: AdminUserRow[];
	error: string | null;
}> {
	const { data, error } = await getSupabase().rpc('admin_list_users');

	if (error) {
		if (isMissingRpc(error, 'admin_list_users')) {
			return { users: [], error: missingRpcMessage('admin_list_users', 'db:apply-admin-directory') };
		}
		return { users: [], error: error.message };
	}

	const users = ((data ?? []) as AdminUserRow[]).map((row) => ({
		...row,
		avatar_key: row.avatar_key ?? null,
		can_change_display_name: row.can_change_display_name !== false,
		leagues: Array.isArray(row.leagues) ? row.leagues : []
	}));

	return { users, error: null };
}

export async function adminUpdateUser(
	userId: string,
	displayName: string,
	canChangeDisplayName: boolean,
	avatarKey: string | null = null
): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('admin_update_user', {
		p_user_id: userId,
		p_display_name: displayName.trim(),
		p_can_change_display_name: canChangeDisplayName,
		p_avatar_key: avatarKey ?? ''
	});

	if (error) {
		if (isMissingRpc(error, 'admin_update_user')) {
			return {
				error: missingRpcMessage('admin_update_user', 'db:apply-avatar-keys')
			};
		}
		return { error: error.message };
	}

	return { error: null };
}

export async function adminSetLeagueProfilePictures(
	leagueId: string,
	enabled: boolean
): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('admin_set_league_profile_pictures', {
		p_league_id: leagueId,
		p_show_profile_pictures: enabled
	});

	if (error) {
		if (isMissingRpc(error, 'admin_set_league_profile_pictures')) {
			return {
				error: missingRpcMessage(
					'admin_set_league_profile_pictures',
					'db:apply-league-profile-pictures'
				)
			};
		}
		return { error: error.message };
	}

	return { error: null };
}

export async function adminSetLeagueParodySponsorships(
	leagueId: string,
	enabled: boolean
): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('admin_set_league_parody_sponsorships', {
		p_league_id: leagueId,
		p_show_parody_sponsorships: enabled
	});

	if (error) {
		if (isMissingRpc(error, 'admin_set_league_parody_sponsorships')) {
			return {
				error: missingRpcMessage(
					'admin_set_league_parody_sponsorships',
					'db:apply-parody-sponsorships'
				)
			};
		}
		return { error: error.message };
	}

	return { error: null };
}

export async function fetchAdminPickAuditLog(leagueId: string): Promise<{
	entries: AdminPickAuditRow[];
	error: string | null;
}> {
	const { data, error } = await getSupabase().rpc('admin_list_pick_audit_log', {
		p_league_id: leagueId
	});

	if (error) {
		if (isMissingRpc(error, 'admin_list_pick_audit_log')) {
			return {
				entries: [],
				error: missingRpcMessage('admin_list_pick_audit_log', 'db:apply-pick-audit-log')
			};
		}
		return { entries: [], error: error.message };
	}

	const entries = ((data ?? []) as AdminPickAuditRow[]).map((row) => ({
		...row,
		week_number: Number(row.week_number),
		season_year: Number(row.season_year)
	}));

	return { entries, error: null };
}

export async function adminDeleteUser(userId: string): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('admin_delete_user', { p_user_id: userId });

	if (error) {
		if (isMissingRpc(error, 'admin_delete_user')) {
			return { error: missingRpcMessage('admin_delete_user', 'db:apply-admin-directory') };
		}
		return { error: error.message };
	}

	return { error: null };
}
