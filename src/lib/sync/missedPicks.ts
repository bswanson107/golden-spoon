import type { SupabaseClient } from '@supabase/supabase-js';

type WeekGameRow = {
	id: string;
	week_number: number;
	kickoff_at: string;
	home_team_id: string;
	season_year: number;
	status: string;
};

type LeagueRow = {
	id: string;
	season_year: number;
};

type MemberRow = {
	league_id: string;
	user_id: string;
};

type ExistingPickRow = {
	league_id: string;
	user_id: string;
	week_number: number;
	team_id: string;
	is_missed: boolean;
};

/**
 * For every week whose slate has locked (last game has kicked off), make sure
 * each active member has a value for the week:
 *   1. They picked → nothing to do.
 *   2. No pick + the week's MNF (last) game home team is still available
 *      (not used this season) → assign it as a real, scoring auto pick.
 *   3. No pick + that home team was already used → insert a 0-point "missed"
 *      pick as the indicator.
 */
export async function markMissedPicks(
	adminClient: SupabaseClient,
	seasonYear: number,
	nowIso: string = new Date().toISOString()
): Promise<number> {
	const now = nowIso;

	const { data: games, error: gamesError } = await adminClient
		.from('nfl_games')
		.select('id, week_number, kickoff_at, home_team_id, season_year, status')
		.eq('season_year', seasonYear)
		.order('kickoff_at', { ascending: true });

	if (gamesError) throw new Error(`markMissedPicks games query failed: ${gamesError.message}`);

	const gamesByWeek = new Map<number, WeekGameRow[]>();
	for (const game of (games ?? []) as WeekGameRow[]) {
		const list = gamesByWeek.get(game.week_number) ?? [];
		list.push(game);
		gamesByWeek.set(game.week_number, list);
	}

	const closedWeeks: { week: number; lastGame: WeekGameRow }[] = [];
	for (const [week, weekGames] of gamesByWeek) {
		const lastGame = weekGames[weekGames.length - 1];
		if (lastGame.kickoff_at <= now) {
			closedWeeks.push({ week, lastGame });
		}
	}

	if (closedWeeks.length === 0) return 0;

	const { data: leagues, error: leaguesError } = await adminClient
		.from('leagues')
		.select('id, season_year')
		.eq('season_year', seasonYear)
		.eq('is_active', true);

	if (leaguesError) throw new Error(`markMissedPicks leagues query failed: ${leaguesError.message}`);

	const leagueIds = ((leagues ?? []) as LeagueRow[]).map((l) => l.id);
	if (leagueIds.length === 0) return 0;

	const { data: members, error: membersError } = await adminClient
		.from('league_members')
		.select('league_id, user_id')
		.in('league_id', leagueIds);

	if (membersError) throw new Error(`markMissedPicks members query failed: ${membersError.message}`);

	// All active picks for the season — used to (a) skip weeks that already have a
	// pick, and (b) figure out which teams each member has already consumed.
	const { data: activePicks, error: picksError } = await adminClient
		.from('picks')
		.select('league_id, user_id, week_number, team_id, is_missed')
		.in('league_id', leagueIds)
		.eq('season_year', seasonYear)
		.is('superseded_by_pick_id', null);

	if (picksError) throw new Error(`markMissedPicks picks query failed: ${picksError.message}`);

	const hasPick = new Set<string>();
	const usedTeams = new Map<string, Set<string>>();

	for (const row of (activePicks ?? []) as ExistingPickRow[]) {
		hasPick.add(`${row.league_id}:${row.user_id}:${row.week_number}`);
		// Missed placeholder rows do not consume a team (per the no-reuse index).
		if (!row.is_missed) {
			const key = `${row.league_id}:${row.user_id}`;
			const set = usedTeams.get(key) ?? new Set<string>();
			set.add(row.team_id);
			usedTeams.set(key, set);
		}
	}

	type AutoRow = {
		league_id: string;
		user_id: string;
		season_year: number;
		week_number: number;
		game_id: string;
		team_id: string;
		is_auto_pick: true;
	};
	type MissedRow = {
		league_id: string;
		user_id: string;
		season_year: number;
		week_number: number;
		game_id: string;
		team_id: string;
		outcome: 'missed';
		points_awarded: number;
		win_pct_at_pick: number;
		is_underdog_at_pick: boolean;
		team_season_wins_at_pick: number;
		is_missed: true;
	};

	const autoRows: AutoRow[] = [];
	const missedRows: MissedRow[] = [];

	for (const { week, lastGame } of closedWeeks) {
		for (const member of (members ?? []) as MemberRow[]) {
			const weekKey = `${member.league_id}:${member.user_id}:${week}`;
			if (hasPick.has(weekKey)) continue;

			const usageKey = `${member.league_id}:${member.user_id}`;
			const used = usedTeams.get(usageKey) ?? new Set<string>();
			const candidate = lastGame.home_team_id;

			if (used.has(candidate)) {
				// MNF home team already used — record a true missed pick.
				missedRows.push({
					league_id: member.league_id,
					user_id: member.user_id,
					season_year: seasonYear,
					week_number: week,
					game_id: lastGame.id,
					team_id: candidate,
					outcome: 'missed',
					points_awarded: 0,
					win_pct_at_pick: 50,
					is_underdog_at_pick: false,
					team_season_wins_at_pick: 0,
					is_missed: true
				});
			} else {
				// Assign the MNF home team as a real, scoring pick.
				autoRows.push({
					league_id: member.league_id,
					user_id: member.user_id,
					season_year: seasonYear,
					week_number: week,
					game_id: lastGame.id,
					team_id: candidate,
					is_auto_pick: true
				});
				// Reserve the team so a later closed week can't double-assign it.
				used.add(candidate);
				usedTeams.set(usageKey, used);
			}

			hasPick.add(weekKey);
		}
	}

	if (autoRows.length > 0) {
		const { error: autoError } = await adminClient.from('picks').insert(autoRows);
		if (autoError) throw new Error(`markMissedPicks auto-pick insert failed: ${autoError.message}`);

		// Auto picks insert as pending; resolve any whose MNF game is already final.
		const finalGameIds = [
			...new Set(
				closedWeeks
					.filter((w) => w.lastGame.status === 'final')
					.map((w) => w.lastGame.id)
			)
		];
		for (const gameId of finalGameIds) {
			const { error: scoreError } = await adminClient.rpc('score_picks_for_game', {
				p_game_id: gameId
			});
			if (scoreError) {
				throw new Error(`markMissedPicks scoring failed: ${scoreError.message}`);
			}
		}
	}

	if (missedRows.length > 0) {
		const { error: missedError } = await adminClient.from('picks').insert(missedRows);
		if (missedError) {
			throw new Error(`markMissedPicks missed insert failed: ${missedError.message}`);
		}
	}

	return autoRows.length + missedRows.length;
}
