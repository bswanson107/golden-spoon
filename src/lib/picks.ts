import { getSupabase } from '$lib/supabase';
import type { LeaguePick, PickOutcome } from '$lib/types/standings';

export type UserLeaguePick = LeaguePick;

type UserPickQueryRow = {
	id: string;
	user_id: string;
	week_number: number;
	team_id: string;
	game_id: string;
	win_pct_at_pick: number;
	is_underdog_at_pick: boolean;
	outcome: PickOutcome;
	points_awarded: number;
	team_season_wins_at_pick?: number;
	is_missed: boolean;
	is_auto_pick?: boolean;
	is_commissioner_override: boolean;
	nfl_teams: { abbreviation: string; name: string } | { abbreviation: string; name: string }[] | null;
	nfl_games: { kickoff_at: string } | { kickoff_at: string }[] | null;
};

function firstRelation<T>(value: T | T[] | null): T | null {
	if (!value) return null;
	return Array.isArray(value) ? (value[0] ?? null) : value;
}

function mapUserPickRow(row: UserPickQueryRow): UserLeaguePick | null {
	const team = firstRelation(row.nfl_teams);
	const game = firstRelation(row.nfl_games);
	if (!team || !game) return null;

	return {
		id: row.id,
		user_id: row.user_id,
		display_name: '',
		week_number: row.week_number,
		team_id: row.team_id,
		game_id: row.game_id,
		team_abbreviation: team.abbreviation,
		team_name: team.name,
		win_pct_at_pick: row.win_pct_at_pick,
		is_underdog_at_pick: row.is_underdog_at_pick,
		outcome: row.outcome,
		points_awarded: row.points_awarded,
		team_season_wins_at_pick: row.team_season_wins_at_pick ?? 0,
		kickoff_at: game.kickoff_at,
		is_missed: row.is_missed,
		is_auto_pick: row.is_auto_pick ?? false,
		is_commissioner_override: row.is_commissioner_override
	};
}

export async function fetchUserLeaguePicks(
	leagueId: string,
	userId: string
): Promise<{ picks: UserLeaguePick[]; error: string | null }> {
	const supabase = getSupabase();

	const { data, error } = await supabase
		.from('picks')
		.select(
			`
			id,
			user_id,
			week_number,
			team_id,
			game_id,
			win_pct_at_pick,
			is_underdog_at_pick,
			outcome,
			points_awarded,
			team_season_wins_at_pick,
			is_missed,
			is_auto_pick,
			is_commissioner_override,
			nfl_teams ( abbreviation, name ),
			nfl_games ( kickoff_at )
		`
		)
		.eq('league_id', leagueId)
		.eq('user_id', userId)
		.is('superseded_by_pick_id', null)
		.order('week_number', { ascending: true });

	if (error) {
		return { picks: [], error: error.message };
	}

	const picks = (data ?? [])
		.map((row) => mapUserPickRow(row as UserPickQueryRow))
		.filter((pick): pick is UserLeaguePick => pick !== null);

	return { picks, error: null };
}

export async function saveLeaguePick(params: {
	leagueId: string;
	week: number;
	gameId: string;
	teamId: string;
	userId: string;
	existingPickId?: string | null;
	clearWeekPickId?: string | null;
}): Promise<{ error: string | null }> {
	const supabase = getSupabase();

	if (params.clearWeekPickId) {
		const { error } = await supabase.from('picks').delete().eq('id', params.clearWeekPickId);
		if (error) {
			if (error.message.includes('row-level security')) {
				return {
					error:
						'Cannot remove the other pick yet. Run supabase/migrations/008_live_pick_planning.sql in Supabase.'
				};
			}
			return { error: error.message };
		}
	}

	if (params.existingPickId) {
		const { error } = await supabase
			.from('picks')
			.update({ game_id: params.gameId, team_id: params.teamId })
			.eq('id', params.existingPickId)
			.eq('user_id', params.userId);

		return { error: error?.message ?? null };
	}

	const { error } = await supabase.from('picks').insert({
		league_id: params.leagueId,
		user_id: params.userId,
		game_id: params.gameId,
		team_id: params.teamId
	});

	return { error: error?.message ?? null };
}

export function picksByWeek(picks: UserLeaguePick[]): Map<number, UserLeaguePick> {
	return new Map(picks.map((pick) => [pick.week_number, pick]));
}

export function teamUsageByWeek(
	picks: Map<number, { team_id: string }>,
	excludeWeek?: number
): Map<string, number> {
	const exclude = excludeWeek !== undefined ? Number(excludeWeek) : undefined;
	const usage = new Map<string, number>();
	for (const [week, pick] of picks) {
		const weekNum = Number(week);
		if (exclude !== undefined && weekNum === exclude) continue;
		usage.set(pick.team_id, weekNum);
	}
	return usage;
}
