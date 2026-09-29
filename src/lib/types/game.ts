export type GameStatus = 'scheduled' | 'in_progress' | 'final' | 'postponed' | 'cancelled';

export type NflTeam = {
	id: string;
	abbreviation: string;
	name: string;
	city: string | null;
	wins: number;
	losses: number;
	ties: number;
	points_for: number;
	points_against: number;
};

export type WeekGame = {
	id: string;
	week_number: number;
	kickoff_at: string;
	status: GameStatus;
	home_score: number | null;
	away_score: number | null;
	is_tie: boolean;
	winner_team_id: string | null;
	home_win_pct: number | null;
	away_win_pct: number | null;
	home: NflTeam;
	away: NflTeam;
};
