export type GameBroadcastSlot = 'tnf' | 'snf' | 'mnf' | 'international';

export type GameSpecialEvent =
	| 'season-opener'
	| 'thanksgiving-eve'
	| 'thanksgiving'
	| 'black-friday'
	| 'christmas-eve'
	| 'christmas'
	| 'saturday';

export type GameKickoffBadge = {
	kind: 'broadcast' | 'special';
	id: GameBroadcastSlot | GameSpecialEvent;
	label: string;
	short: string;
};

export type GameKickoffInfo = {
	formatted: string;
	shortFormatted: string;
	badges: GameKickoffBadge[];
	highlightClass: string | null;
};

const BROADCAST_LABELS: Record<GameBroadcastSlot, string> = {
	tnf: 'Thursday Night Football',
	snf: 'Sunday Night Football',
	mnf: 'Monday Night Football',
	international: 'International Game'
};

const BROADCAST_SHORT: Record<GameBroadcastSlot, string> = {
	tnf: 'TNF',
	snf: 'SNF',
	mnf: 'MNF',
	international: 'International'
};

const SPECIAL_LABELS: Record<GameSpecialEvent, string> = {
	'season-opener': 'Season Opener',
	'thanksgiving-eve': 'Thanksgiving Eve',
	thanksgiving: 'Thanksgiving',
	'black-friday': 'Black Friday',
	'christmas-eve': 'Christmas Eve',
	christmas: 'Christmas',
	saturday: 'Saturday Game'
};

const SPECIAL_SHORT: Record<GameSpecialEvent, string> = {
	'season-opener': 'Opener',
	'thanksgiving-eve': 'Thanksgiving Eve',
	thanksgiving: 'Thanksgiving',
	'black-friday': 'Black Friday',
	'christmas-eve': 'Christmas Eve',
	christmas: 'Christmas',
	saturday: 'Saturday'
};

const HIGHLIGHT_PRIORITY: Array<GameBroadcastSlot | GameSpecialEvent> = [
	'christmas',
	'christmas-eve',
	'thanksgiving',
	'thanksgiving-eve',
	'black-friday',
	'season-opener',
	'saturday',
	'snf',
	'mnf',
	'tnf',
	'international'
];

const ET_TIMEZONE = 'America/New_York';

type EasternParts = {
	year: number;
	month: number;
	day: number;
	dayOfWeek: number;
	hour: number;
	minute: number;
};

function getEasternParts(kickoffAt: string): EasternParts {
	const formatter = new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		year: 'numeric',
		month: 'numeric',
		day: 'numeric',
		weekday: 'short',
		hour: 'numeric',
		minute: 'numeric',
		hour12: false
	});

	const parts = formatter.formatToParts(new Date(kickoffAt));
	const dayMap: Record<string, number> = {
		Sun: 0,
		Mon: 1,
		Tue: 2,
		Wed: 3,
		Thu: 4,
		Fri: 5,
		Sat: 6
	};

	const weekday = parts.find((p) => p.type === 'weekday')?.value ?? 'Sun';

	return {
		year: Number(parts.find((p) => p.type === 'year')?.value ?? 0),
		month: Number(parts.find((p) => p.type === 'month')?.value ?? 0),
		day: Number(parts.find((p) => p.type === 'day')?.value ?? 0),
		dayOfWeek: dayMap[weekday] ?? 0,
		hour: Number(parts.find((p) => p.type === 'hour')?.value ?? 0),
		minute: Number(parts.find((p) => p.type === 'minute')?.value ?? 0)
	};
}

function isThanksgiving({ month, dayOfWeek, day }: EasternParts): boolean {
	return month === 11 && dayOfWeek === 4 && day >= 22 && day <= 28;
}

function isThanksgivingEve({ month, dayOfWeek, day }: EasternParts): boolean {
	return month === 11 && dayOfWeek === 3 && day >= 21 && day <= 27;
}

function isBlackFriday({ month, dayOfWeek, day }: EasternParts): boolean {
	return month === 11 && dayOfWeek === 5 && day >= 23 && day <= 29;
}

function isSeasonOpener({ month, dayOfWeek, day }: EasternParts): boolean {
	return month === 9 && dayOfWeek === 3 && day <= 11;
}

export function classifyBroadcastSlot(kickoffAt: string): GameBroadcastSlot | null {
	const { dayOfWeek, hour, minute } = getEasternParts(kickoffAt);

	if (dayOfWeek === 0 && hour === 9 && minute === 30) {
		return 'international';
	}

	if (dayOfWeek === 4 && hour >= 19) {
		return 'tnf';
	}

	if (dayOfWeek === 0 && hour >= 20) {
		return 'snf';
	}

	if (dayOfWeek === 1 && hour >= 19) {
		return 'mnf';
	}

	return null;
}

export function classifySpecialEvents(kickoffAt: string): GameSpecialEvent[] {
	const parts = getEasternParts(kickoffAt);
	const events: GameSpecialEvent[] = [];

	if (isSeasonOpener(parts)) events.push('season-opener');
	if (isThanksgivingEve(parts)) events.push('thanksgiving-eve');
	if (isThanksgiving(parts)) events.push('thanksgiving');
	if (isBlackFriday(parts)) events.push('black-friday');
	if (parts.month === 12 && parts.day === 24) events.push('christmas-eve');
	if (parts.month === 12 && parts.day === 25) events.push('christmas');
	if (parts.dayOfWeek === 6) events.push('saturday');

	return events;
}

/** @deprecated Use getGameKickoffInfo().badges instead */
export function classifyGameSlot(kickoffAt: string): GameBroadcastSlot | null {
	return classifyBroadcastSlot(kickoffAt);
}

export function formatGameKickoff(kickoffAt: string): string {
	return new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		weekday: 'short',
		month: 'short',
		day: 'numeric',
		hour: 'numeric',
		minute: '2-digit',
		timeZoneName: 'short'
	}).format(new Date(kickoffAt));
}

export function formatGameKickoffShort(kickoffAt: string): string {
	return new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		weekday: 'short',
		hour: 'numeric',
		minute: '2-digit',
		timeZoneName: 'short'
	}).format(new Date(kickoffAt));
}

/** Compact table kickoff, e.g. "Thu 8:20 PM" (no timezone). */
export function formatGameKickoffTable(kickoffAt: string): string {
	return new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		weekday: 'short',
		hour: 'numeric',
		minute: '2-digit'
	}).format(new Date(kickoffAt));
}

/** Full weekday in ET, e.g. "Wednesday". */
export function formatGameKickoffWeekday(kickoffAt: string): string {
	return new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		weekday: 'long'
	}).format(new Date(kickoffAt));
}

function dayOrdinal(day: number): string {
	const mod100 = day % 100;
	if (mod100 >= 11 && mod100 <= 13) return `${day}th`;
	switch (day % 10) {
		case 1:
			return `${day}st`;
		case 2:
			return `${day}nd`;
		case 3:
			return `${day}rd`;
		default:
			return `${day}th`;
	}
}

/** Month + ordinal day in ET, e.g. "Sep 9th". */
export function formatGameKickoffDate(kickoffAt: string): string {
	const parts = getEasternParts(kickoffAt);
	const month = new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		month: 'short'
	}).format(new Date(kickoffAt));
	return `${month} ${dayOrdinal(parts.day)}`;
}

/** Time in ET, e.g. "12:00 PM". */
export function formatGameKickoffTime(kickoffAt: string): string {
	return new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		hour: 'numeric',
		minute: '2-digit'
	}).format(new Date(kickoffAt));
}

/** Pick deadline label, e.g. "Thu, Sep 11 · 8:20 PM ET" */
export function formatPickDeadline(kickoffIso: string): string {
	const formatted = new Intl.DateTimeFormat('en-US', {
		timeZone: ET_TIMEZONE,
		weekday: 'short',
		month: 'short',
		day: 'numeric',
		hour: 'numeric',
		minute: '2-digit'
	}).format(new Date(kickoffIso));
	return `${formatted} ET`;
}

function broadcastBadge(slot: GameBroadcastSlot): GameKickoffBadge {
	return {
		kind: 'broadcast',
		id: slot,
		label: BROADCAST_LABELS[slot],
		short: BROADCAST_SHORT[slot]
	};
}

function specialBadge(event: GameSpecialEvent): GameKickoffBadge {
	return {
		kind: 'special',
		id: event,
		label: SPECIAL_LABELS[event],
		short: SPECIAL_SHORT[event]
	};
}

function primaryHighlightClass(badges: GameKickoffBadge[]): string | null {
	const ids = new Set(badges.map((b) => b.id));
	for (const id of HIGHLIGHT_PRIORITY) {
		if (ids.has(id)) return `slot-${id}`;
	}
	return null;
}

export function getGameKickoffInfo(kickoffAt: string): GameKickoffInfo {
	const specialEvents = classifySpecialEvents(kickoffAt);
	const badges: GameKickoffBadge[] = specialEvents.map(specialBadge);

	const broadcast = classifyBroadcastSlot(kickoffAt);
	const skipBroadcast =
		(broadcast === 'tnf' &&
			(specialEvents.includes('thanksgiving') || specialEvents.includes('christmas-eve'))) ||
		(broadcast === 'snf' && specialEvents.includes('christmas'));
	if (broadcast && !skipBroadcast) {
		badges.push(broadcastBadge(broadcast));
	}

	return {
		formatted: formatGameKickoff(kickoffAt),
		shortFormatted: formatGameKickoffShort(kickoffAt),
		badges,
		highlightClass: primaryHighlightClass(badges)
	};
}

export function slotCssClass(slot: GameBroadcastSlot | GameSpecialEvent | null): string | null {
	if (!slot) return null;
	return `slot-${slot}`;
}
