export type GameStatus = 'scheduled' | 'in_progress' | 'final' | 'postponed' | 'cancelled';

export type GameSyncRow = {
	espnEventId: string;
	season: number;
	week: number;
	gameday: string;
	gametime: string;
	awayTeam: string;
	homeTeam: string;
	awayScore: number | null;
	homeScore: number | null;
	status: GameStatus;
	winner: string | null;
	isTie: boolean;
	awayWinPct: number | null;
	homeWinPct: number | null;
	/**
	 * Provenance of the win %ages above. Only set when they were carried forward
	 * from a previous sync instead of read from this feed pull.
	 */
	winPctSource?: string | null;
	winPctUpdatedAt?: string | null;
	kickoffAtUtc: string;
};

export type SyncResult = {
	skipped: boolean;
	inProgress: boolean;
	lastSyncAt: string | null;
	gamesUpdated: number;
	oddsUpdated: number;
	kickoffLocksApplied: number;
	missedPicksInserted: number;
	error: string | null;
};

export const SYNC_STATE_KEY = 'nfl_games';
export const DEFAULT_SEASON_YEAR = 2026;
