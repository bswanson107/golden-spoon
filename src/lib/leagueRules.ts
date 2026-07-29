export type TiebreakerMode = 'fewest_wins' | 'most_wins';
export type PickVisibility = 'hidden_until_kickoff' | 'open';

export const DEFAULT_UNDERDOG_THRESHOLD = 33;
export const UNDERDOG_THRESHOLD_PRESETS = [25, 33, 40, 50] as const;

export const DEFAULT_TIEBREAKER_MODE: TiebreakerMode = 'fewest_wins';
export const DEFAULT_PICK_VISIBILITY: PickVisibility = 'hidden_until_kickoff';

export function normalizeUnderdogThreshold(value: number | null | undefined): number {
	return value != null ? Math.round(Number(value)) : DEFAULT_UNDERDOG_THRESHOLD;
}

export function parseTiebreakerMode(value: string | null | undefined): TiebreakerMode {
	return value === 'most_wins' ? 'most_wins' : 'fewest_wins';
}

export function parsePickVisibility(value: string | null | undefined): PickVisibility {
	return value === 'open' ? 'open' : 'hidden_until_kickoff';
}

export function tiebreakerShortLabel(mode: TiebreakerMode): string {
	return mode === 'most_wins' ? 'Tiebreaker ↑' : 'Tiebreaker ↓';
}

export function tiebreakerHint(mode: TiebreakerMode): string {
	return mode === 'most_wins'
		? 'Tiebreaker: higher cumulative season wins of picked teams ranks higher'
		: 'Tiebreaker: lower cumulative season wins of picked teams ranks higher';
}

export function tiebreakerDescription(mode: TiebreakerMode): string {
	return mode === 'most_wins'
		? 'If tied on points, the player with the higher cumulative season wins of their picked teams ranks higher — rewarding success with stronger teams.'
		: 'If tied on points, the player with the lower cumulative season wins of their picked teams ranks higher — rewarding success with weaker teams.';
}

export function pickVisibilityDescription(mode: PickVisibility): string {
	return mode === 'open'
		? 'Submitted picks are visible to all league members immediately, even before kickoff.'
		: 'Your pick stays hidden from other league members until your game kicks off. After kickoff, everyone can see your selection and result.';
}

export function isOpenPickVisibility(mode: PickVisibility): boolean {
	return mode === 'open';
}

export function compareTiebreaker(aWins: number, bWins: number, mode: TiebreakerMode): number {
	return mode === 'most_wins' ? bWins - aWins : aWins - bWins;
}
