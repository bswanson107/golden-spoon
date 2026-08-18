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
	created_at: string;
};

export type AdminUserLeague = {
	id: string;
	name: string;
	season_year: number;
	is_commissioner: boolean;
	is_public_demo: boolean;
};

export type AdminUserRow = {
	user_id: string;
	email: string;
	display_name: string;
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
		member_count: Number(row.member_count)
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
		leagues: Array.isArray(row.leagues) ? row.leagues : []
	}));

	return { users, error: null };
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
