import { getTeamName } from '$lib/data/nflTeams';
import { easternKickoffToUtcIso, mapTeam } from '$lib/sync/nflverse';
import { normalizedWinPcts } from '$lib/sync/winPct';
import type { NflTeam, WeekGame } from '$lib/types/game';

type Week1Row = {
	game_id: string;
	gameday: string;
	gametime: string;
	away_team: string;
	home_team: string;
	away_moneyline: number;
	home_moneyline: number;
};

/** 2026 Week 1 — sourced from data/games_2026.csv */
const WEEK1_ROWS: Week1Row[] = [
	{ game_id: '2026_01_NE_SEA', gameday: '2026-09-09', gametime: '20:20', away_team: 'NE', home_team: 'SEA', away_moneyline: 170, home_moneyline: -205 },
	{ game_id: '2026_01_SF_LA', gameday: '2026-09-10', gametime: '20:35', away_team: 'SF', home_team: 'LA', away_moneyline: 130, home_moneyline: -155 },
	{ game_id: '2026_01_CHI_CAR', gameday: '2026-09-13', gametime: '13:00', away_team: 'CHI', home_team: 'CAR', away_moneyline: -135, home_moneyline: 114 },
	{ game_id: '2026_01_TB_CIN', gameday: '2026-09-13', gametime: '13:00', away_team: 'TB', home_team: 'CIN', away_moneyline: 164, home_moneyline: -198 },
	{ game_id: '2026_01_NO_DET', gameday: '2026-09-13', gametime: '13:00', away_team: 'NO', home_team: 'DET', away_moneyline: 260, home_moneyline: -325 },
	{ game_id: '2026_01_BUF_HOU', gameday: '2026-09-13', gametime: '13:00', away_team: 'BUF', home_team: 'HOU', away_moneyline: -115, home_moneyline: -105 },
	{ game_id: '2026_01_BAL_IND', gameday: '2026-09-13', gametime: '13:00', away_team: 'BAL', home_team: 'IND', away_moneyline: -192, home_moneyline: 160 },
	{ game_id: '2026_01_CLE_JAX', gameday: '2026-09-13', gametime: '13:00', away_team: 'CLE', home_team: 'JAX', away_moneyline: 240, home_moneyline: -298 },
	{ game_id: '2026_01_ATL_PIT', gameday: '2026-09-13', gametime: '13:00', away_team: 'ATL', home_team: 'PIT', away_moneyline: 145, home_moneyline: -175 },
	{ game_id: '2026_01_NYJ_TEN', gameday: '2026-09-13', gametime: '13:00', away_team: 'NYJ', home_team: 'TEN', away_moneyline: 140, home_moneyline: -166 },
	{ game_id: '2026_01_ARI_LAC', gameday: '2026-09-13', gametime: '16:25', away_team: 'ARI', home_team: 'LAC', away_moneyline: 470, home_moneyline: -650 },
	{ game_id: '2026_01_MIA_LV', gameday: '2026-09-13', gametime: '16:25', away_team: 'MIA', home_team: 'LV', away_moneyline: 145, home_moneyline: -175 },
	{ game_id: '2026_01_GB_MIN', gameday: '2026-09-13', gametime: '16:25', away_team: 'GB', home_team: 'MIN', away_moneyline: -125, home_moneyline: 105 },
	{ game_id: '2026_01_WAS_PHI', gameday: '2026-09-13', gametime: '16:25', away_team: 'WAS', home_team: 'PHI', away_moneyline: 195, home_moneyline: -238 },
	{ game_id: '2026_01_DAL_NYG', gameday: '2026-09-13', gametime: '20:20', away_team: 'DAL', home_team: 'NYG', away_moneyline: -130, home_moneyline: 110 },
	{ game_id: '2026_01_DEN_KC', gameday: '2026-09-14', gametime: '20:15', away_team: 'DEN', home_team: 'KC', away_moneyline: 130, home_moneyline: -155 }
];

function toTeam(abbr: string): NflTeam {
	const code = mapTeam(abbr);
	return {
		id: code,
		abbreviation: code,
		name: getTeamName(code),
		city: null,
		wins: 0,
		losses: 0,
		ties: 0,
		points_for: 0,
		points_against: 0
	};
}

export const week1Games2026: WeekGame[] = WEEK1_ROWS.map((row) => {
	const { away, home } = normalizedWinPcts(row.away_moneyline, row.home_moneyline);
	return {
		id: row.game_id,
		week_number: 1,
		kickoff_at: easternKickoffToUtcIso(row.gameday, row.gametime),
		status: 'scheduled',
		home_score: null,
		away_score: null,
		is_tie: false,
		winner_team_id: null,
		home_win_pct: home,
		away_win_pct: away,
		home: toTeam(row.home_team),
		away: toTeam(row.away_team)
	};
});
