import { getSupabase } from '$lib/supabase';

export const LEAGUE_CHAT_PAGE_SIZE = 30;
export const LEAGUE_CHAT_MAX_LENGTH = 500;

export type LeagueChatMessage = {
	id: string;
	user_id: string;
	display_name: string;
	avatar_key: string | null;
	body: string;
	created_at: string;
};

function missingRpcMessage(fn: string): string {
	return `${fn} is not set up on the database yet. Run migration 037 in the Supabase SQL Editor, or locally: npm run db:apply-league-chat (requires SUPABASE_DB_URL in .env).`;
}

function isMissingRpc(error: { code?: string; message: string }, fn: string): boolean {
	return (
		error.code === 'PGRST202' ||
		error.message.includes(fn) ||
		error.message.includes('Could not find the function')
	);
}

function mapMessage(row: LeagueChatMessage): LeagueChatMessage {
	return {
		id: row.id,
		user_id: row.user_id,
		display_name: row.display_name || 'Unknown',
		avatar_key: row.avatar_key ?? null,
		body: row.body,
		created_at: row.created_at
	};
}

export async function fetchLeagueMessages(
	leagueId: string,
	options: { before?: string } = {}
): Promise<{ messages: LeagueChatMessage[]; hasMore: boolean; error: string | null }> {
	const { data, error } = await getSupabase().rpc('league_list_messages', {
		p_league_id: leagueId,
		p_before: options.before ?? null,
		p_limit: LEAGUE_CHAT_PAGE_SIZE + 1
	});

	if (error) {
		if (isMissingRpc(error, 'league_list_messages')) {
			return { messages: [], hasMore: false, error: missingRpcMessage('league_list_messages') };
		}
		return { messages: [], hasMore: false, error: error.message };
	}

	const rows = ((data ?? []) as LeagueChatMessage[]).map(mapMessage);
	const hasMore = rows.length > LEAGUE_CHAT_PAGE_SIZE;
	const page = hasMore ? rows.slice(0, LEAGUE_CHAT_PAGE_SIZE) : rows;
	// RPC returns newest-first; UI wants oldest at the top.
	return { messages: page.reverse(), hasMore, error: null };
}

export async function sendLeagueMessage(
	leagueId: string,
	userId: string,
	body: string
): Promise<{ message: LeagueChatMessage | null; error: string | null }> {
	const trimmed = body.trim();
	if (!trimmed) {
		return { message: null, error: 'Message cannot be empty.' };
	}
	if (trimmed.length > LEAGUE_CHAT_MAX_LENGTH) {
		return { message: null, error: `Message must be ${LEAGUE_CHAT_MAX_LENGTH} characters or fewer.` };
	}

	const { data, error } = await getSupabase()
		.from('league_messages')
		.insert({ league_id: leagueId, user_id: userId, body: trimmed })
		.select('id, user_id, body, created_at')
		.single();

	if (error) {
		if (error.message.includes('league_messages') && error.message.includes('does not exist')) {
			return { message: null, error: missingRpcMessage('league_list_messages') };
		}
		return { message: null, error: error.message };
	}

	if (!data) {
		return { message: null, error: 'Could not send message.' };
	}

	return {
		message: {
			id: data.id,
			user_id: data.user_id,
			display_name: '',
			avatar_key: null,
			body: data.body,
			created_at: data.created_at
		},
		error: null
	};
}

export async function deleteLeagueMessage(messageId: string): Promise<{ error: string | null }> {
	const { error } = await getSupabase().from('league_messages').delete().eq('id', messageId);

	if (error) {
		return { error: error.message };
	}

	return { error: null };
}

export async function fetchLeagueChatUnreadCount(
	leagueId: string
): Promise<{ count: number; error: string | null }> {
	const { data, error } = await getSupabase().rpc('league_chat_unread_count', {
		p_league_id: leagueId
	});

	if (error) {
		if (isMissingRpc(error, 'league_chat_unread_count')) {
			return { count: 0, error: missingRpcMessage('league_chat_unread_count') };
		}
		return { count: 0, error: error.message };
	}

	return { count: Number(data ?? 0), error: null };
}

export async function markLeagueChatRead(leagueId: string): Promise<{ error: string | null }> {
	const { error } = await getSupabase().rpc('league_chat_mark_read', {
		p_league_id: leagueId
	});

	if (error) {
		if (isMissingRpc(error, 'league_chat_mark_read')) {
			return { error: missingRpcMessage('league_chat_mark_read') };
		}
		return { error: error.message };
	}

	return { error: null };
}
