import { qaNow } from '$lib/qaClock.svelte';
import type { WeekGame } from '$lib/types/game';
import type { LeaguePick, StandingRow } from '$lib/types/standings';

/** Members with no active non-missed pick for the given week. */
export function getMissingPickers(
	members: StandingRow[],
	picks: LeaguePick[],
	weekNumber: number
): StandingRow[] {
	const pickedUserIds = new Set(
		picks
			.filter((p) => p.week_number === weekNumber && !p.is_missed)
			.map((p) => p.user_id)
	);
	return members.filter((m) => !pickedUserIds.has(m.user_id));
}

/** Earliest kickoff in a week (first pick deadline for Thu games). */
export function getWeekFirstKickoff(games: WeekGame[]): string | null {
	if (games.length === 0) return null;
	return games.reduce(
		(earliest, game) =>
			game.kickoff_at < earliest ? game.kickoff_at : earliest,
		games[0].kickoff_at
	);
}

/** Latest kickoff in a week (week pick window closes). */
export function getWeekLastKickoff(games: WeekGame[]): string | null {
	if (games.length === 0) return null;
	return games.reduce(
		(latest, game) => (game.kickoff_at > latest ? game.kickoff_at : latest),
		games[0].kickoff_at
	);
}

export function hasWeekStarted(games: WeekGame[], now = qaNow()): boolean {
	const first = getWeekFirstKickoff(games);
	return first !== null && new Date(first).getTime() <= now;
}

export function hasWeekClosed(games: WeekGame[], now = qaNow()): boolean {
	const last = getWeekLastKickoff(games);
	return last !== null && new Date(last).getTime() <= now;
}

/** Games whose kickoff has already passed. */
export function getGamesStartedCount(games: WeekGame[], now = qaNow()): number {
	return games.filter((game) => new Date(game.kickoff_at).getTime() <= now).length;
}

/** Earliest kickoff still in the future (next pickable game). */
export function getNextUpcomingKickoff(games: WeekGame[], now = qaNow()): string | null {
	const upcoming = games
		.filter((game) => new Date(game.kickoff_at).getTime() > now)
		.sort((a, b) => a.kickoff_at.localeCompare(b.kickoff_at));

	return upcoming[0]?.kickoff_at ?? null;
}

export function hasPickableGames(games: WeekGame[], now = qaNow()): boolean {
	return getNextUpcomingKickoff(games, now) !== null;
}

export type PickCtaState =
	| { kind: 'hidden' }
	| { kind: 'needs_pick'; week: number; nextKickoff: string; gamesStarted: number }
	| { kind: 'submitted'; week: number; changeable: boolean; teamAbbreviation?: string }
	| { kind: 'closed'; week: number };

export function getPickCtaState(
	weekNumber: number,
	games: WeekGame[],
	userPick: LeaguePick | undefined,
	now = qaNow()
): PickCtaState {
	if (games.length === 0) {
		return { kind: 'hidden' };
	}

	if (userPick) {
		const kickedOff = new Date(userPick.kickoff_at).getTime() <= now;

		return {
			kind: 'submitted',
			week: weekNumber,
			changeable: !kickedOff,
			teamAbbreviation: kickedOff ? userPick.team_abbreviation : undefined
		};
	}

	const nextKickoff = getNextUpcomingKickoff(games, now);
	if (!nextKickoff) {
		return { kind: 'closed', week: weekNumber };
	}

	return {
		kind: 'needs_pick',
		week: weekNumber,
		nextKickoff,
		gamesStarted: getGamesStartedCount(games, now)
	};
}
