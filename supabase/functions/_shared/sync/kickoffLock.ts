import type { SupabaseClient } from '@supabase/supabase-js';

type PickRow = {
	id: string;
	team_id: string;
	win_pct_at_pick: number;
	is_underdog_at_pick: boolean;
	game_id: string;
	league_id: string;
};

type GameRow = {
	id: string;
	kickoff_at: string;
	home_team_id: string;
	away_team_id: string;
	home_win_pct: number | null;
	away_win_pct: number | null;
};

type LeagueRow = {
	id: string;
	underdog_threshold_pct: number;
};

export async function lockKickoffWinPcts(
	adminClient: SupabaseClient,
	seasonYear: number,
	nowIso: string = new Date().toISOString()
): Promise<number> {
	const now = nowIso;

	const { data: picks, error: picksError } = await adminClient
		.from('picks')
		.select('id, team_id, win_pct_at_pick, is_underdog_at_pick, game_id, league_id')
		.eq('season_year', seasonYear)
		.eq('outcome', 'pending')
		.eq('is_commissioner_override', false)
		.eq('is_missed', false)
		.is('superseded_by_pick_id', null);

	if (picksError) throw new Error(`lockKickoffWinPcts picks query failed: ${picksError.message}`);
	if (!picks?.length) return 0;

	const gameIds = [...new Set((picks as PickRow[]).map((p) => p.game_id))];
	const leagueIds = [...new Set((picks as PickRow[]).map((p) => p.league_id))];

	const [{ data: games, error: gamesError }, { data: leagues, error: leaguesError }] =
		await Promise.all([
			adminClient
				.from('nfl_games')
				.select('id, kickoff_at, home_team_id, away_team_id, home_win_pct, away_win_pct')
				.in('id', gameIds),
			adminClient.from('leagues').select('id, underdog_threshold_pct').in('id', leagueIds)
		]);

	if (gamesError) throw new Error(`lockKickoffWinPcts games query failed: ${gamesError.message}`);
	if (leaguesError) throw new Error(`lockKickoffWinPcts leagues query failed: ${leaguesError.message}`);

	const gameById = new Map((games as GameRow[]).map((g) => [g.id, g]));
	const leagueById = new Map((leagues as LeagueRow[]).map((l) => [l.id, l]));

	let updated = 0;

	for (const pick of picks as PickRow[]) {
		const game = gameById.get(pick.game_id);
		const league = leagueById.get(pick.league_id);
		if (!game || !league || game.kickoff_at > now) continue;

		const teamWinPct =
			pick.team_id === game.home_team_id ? game.home_win_pct : game.away_win_pct;
		if (teamWinPct === null) continue;

		const threshold = Number(league.underdog_threshold_pct);
		const isUnderdog = teamWinPct <= threshold;

		if (
			Math.abs(Number(pick.win_pct_at_pick) - teamWinPct) < 0.001 &&
			pick.is_underdog_at_pick === isUnderdog
		) {
			continue;
		}

		const { error: updateError } = await adminClient
			.from('picks')
			.update({
				win_pct_at_pick: teamWinPct,
				is_underdog_at_pick: isUnderdog,
				updated_at: new Date().toISOString()
			})
			.eq('id', pick.id);

		if (updateError) {
			throw new Error(`lockKickoffWinPcts update failed: ${updateError.message}`);
		}
		updated += 1;
	}

	return updated;
}
