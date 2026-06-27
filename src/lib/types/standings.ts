export type PickOutcome = 'pending' | 'win' | 'loss' | 'tie' | 'missed' | 'void';

export type StandingRow = {
	user_id: string;
	display_name: string;
	total_points: number;
	tiebreaker_picked_team_wins: number;
	pending_picks: number;
	standing_rank: number;
	wins: number;
	losses: number;
	ties: number;
};

export type LeaguePick = {
	id: string;
	user_id: string;
	display_name: string;
	week_number: number;
	team_id: string;
	team_abbreviation: string;
	team_name: string;
	win_pct_at_pick: number;
	is_underdog_at_pick: boolean;
	outcome: PickOutcome;
	points_awarded: number;
	team_season_wins_at_pick?: number;
	game_id: string;
	kickoff_at: string;
	is_missed: boolean;
	is_auto_pick?: boolean;
	is_commissioner_override: boolean;
};
