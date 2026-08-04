import type { PickVisibility, TiebreakerMode } from '$lib/leagueRules';

export type League = {
	id: string;
	name: string;
	season_year: number;
	commissioner_id: string;
	invite_code: string;
	is_active: boolean;
	is_public_demo: boolean;
	created_at: string;
	underdog_threshold_pct: number;
	tiebreaker_mode: TiebreakerMode;
	pick_visibility: PickVisibility;
};

export type LeagueMembership = {
	league_id: string;
	joined_at: string;
	leagues: League;
};

export type LeagueWithRole = League & {
	is_commissioner: boolean;
	joined_at: string;
};
