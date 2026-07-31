<script lang="ts">
	import type { Snippet } from 'svelte';
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import { qaNow } from '$lib/qaClock.svelte';
	import {
		type PickVisibility,
		DEFAULT_PICK_VISIBILITY,
		isOpenPickVisibility,
		parsePickVisibility
	} from '$lib/leagueRules';
	import {
		normalizePickUserId,
		pickSubmissionKey,
		type PickSubmissionsByCell,
		type WeekPickSubmissionStatus
	} from '$lib/standings';
	import type { LeaguePick, PickOutcome } from '$lib/types/standings';

	type CellDisplay = 'empty' | 'hidden' | 'visible' | 'missed';

	let {
		picks,
		standings = [],
		currentUserId = null,
		viewWeek = null,
		maxWeek = null,
		pickSubmissions = {},
		pickVisibility = DEFAULT_PICK_VISIBILITY,
		stickyTop
	}: {
		picks: LeaguePick[];
		standings?: { user_id: string; display_name: string; standing_rank: number }[];
		currentUserId?: string | null;
		viewWeek?: number | null;
		/** When set (and viewWeek is null), show weeks 1..maxWeek inclusive. */
		maxWeek?: number | null;
		/** `${userId}:${weekNumber}` → submission status for hidden picks. */
		pickSubmissions?: PickSubmissionsByCell;
		pickVisibility?: PickVisibility | string;
		stickyTop?: Snippet;
	} = $props();

	const resolvedPickVisibility = $derived(parsePickVisibility(pickVisibility));
	const picksAreOpen = $derived(isOpenPickVisibility(resolvedPickVisibility));

	const LOGO_SIZE = 24;

	const now = $derived(qaNow());
	const normalizedCurrentUserId = $derived(
		currentUserId ? normalizePickUserId(currentUserId) : null
	);

	const rankByUser = $derived(
		new Map(standings.map((s) => [normalizePickUserId(s.user_id), s.standing_rank]))
	);

	const weeks = $derived.by(() => {
		const fromPicks = picks.map((p) => p.week_number);
		const fromSubmissions = Object.keys(pickSubmissions).map((key) => {
			const separator = key.lastIndexOf(':');
			return separator === -1 ? 0 : Number(key.slice(separator + 1));
		});
		const allWeeks = [...new Set([...fromPicks, ...fromSubmissions])]
			.filter((week) => week > 0)
			.sort((a, b) => a - b);

		if (viewWeek !== null && viewWeek > 0) {
			return [viewWeek];
		}

		if (maxWeek !== null && maxWeek > 0) {
			return Array.from({ length: maxWeek }, (_, i) => i + 1);
		}

		return allWeeks;
	});

	const players = $derived.by(() => {
		const byUser = new Map<string, { name: string; picks: Map<number, LeaguePick> }>();

		for (const row of standings) {
			byUser.set(normalizePickUserId(row.user_id), {
				name: row.display_name,
				picks: new Map()
			});
		}

		for (const pick of picks) {
			const userId = normalizePickUserId(pick.user_id);
			let entry = byUser.get(userId);
			if (!entry) {
				entry = { name: pick.display_name, picks: new Map() };
				byUser.set(userId, entry);
			}
			entry.picks.set(pick.week_number, pick);
		}

		return [...byUser.entries()]
			.map(([userId, data]) => ({ userId, ...data }))
			.sort((a, b) => {
				const rankA = rankByUser.get(a.userId) ?? 999;
				const rankB = rankByUser.get(b.userId) ?? 999;
				return rankA - rankB || a.name.localeCompare(b.name);
			});
	});

	const cellDisplays = $derived.by(() => {
		const displays = new Map<string, CellDisplay>();

		for (const player of players) {
			const isOwn = player.userId === normalizedCurrentUserId;
			for (const week of weeks) {
				const key = pickSubmissionKey(player.userId, week);
				const pick = player.picks.get(week);
				const submission = pickSubmissions[key];
				displays.set(key, cellDisplay(pick, submission, resolvedPickVisibility, isOwn));
			}
		}

		return displays;
	});

	function ringClass(outcome: PickOutcome, display: CellDisplay): string {
		if (display === 'missed') return 'ring-missed';
		if (display === 'hidden') return 'ring-hidden';
		if (display === 'empty') return 'ring-empty';

		switch (outcome) {
			case 'win':
				return 'ring-win';
			case 'loss':
				return 'ring-loss';
			case 'tie':
				return 'ring-tie';
			case 'missed':
				return 'ring-missed';
			default:
				return 'ring-pending';
		}
	}

	function cellDisplay(
		pick: LeaguePick | undefined,
		submission: WeekPickSubmissionStatus | undefined,
		visibility: PickVisibility,
		isOwn: boolean
	): CellDisplay {
		if (pick?.is_missed || pick?.outcome === 'missed' || submission === 'missed') return 'missed';

		const hasSubmitted = pick !== undefined || submission === 'submitted';
		if (!hasSubmitted) return 'empty';

		if (pick) {
			// You can always see your own pick.
			if (isOwn) return 'visible';
			if (isOpenPickVisibility(visibility)) return 'visible';
			const kickedOff = new Date(pick.kickoff_at).getTime() <= now;
			if (kickedOff) return 'visible';
		}

		return 'hidden';
	}

	function hiddenPickTitle(userId: string): string {
		return userId === normalizedCurrentUserId
			? 'Your pick is saved — team hidden until kickoff'
			: 'Pick saved — team hidden until kickoff';
	}

	let headerScrollEl = $state<HTMLDivElement | null>(null);
	let bodyScrollEl = $state<HTMLDivElement | null>(null);
	let syncingScroll = false;

	function syncHeaderFromBody() {
		if (syncingScroll || !headerScrollEl || !bodyScrollEl) return;
		syncingScroll = true;
		headerScrollEl.scrollLeft = bodyScrollEl.scrollLeft;
		syncingScroll = false;
	}

	function syncBodyFromHeader() {
		if (syncingScroll || !headerScrollEl || !bodyScrollEl) return;
		syncingScroll = true;
		bodyScrollEl.scrollLeft = headerScrollEl.scrollLeft;
		syncingScroll = false;
	}
</script>

<div class="picks-sticky-bar">
	{#if stickyTop}
		<div class="sticky-top">
			{@render stickyTop()}
		</div>
	{/if}
	<div
		class="picks-header-scroll"
		bind:this={headerScrollEl}
		onscroll={syncBodyFromHeader}
	>
		<table class="picks-grid picks-header-grid" aria-hidden="true">
			<tbody>
				<tr>
					<th class="sticky player-col header-player">Player</th>
					<td class="col-gap"></td>
					{#each weeks as week (week)}
						<td class="week-col">{week}</td>
					{/each}
				</tr>
			</tbody>
		</table>
	</div>
</div>

<div class="grid-wrap" bind:this={bodyScrollEl} onscroll={syncHeaderFromBody}>
	<table class="picks-grid">
		<thead class="sr-only">
			<tr>
				<th scope="col">Player</th>
				<th scope="col"></th>
				{#each weeks as week (week)}
					<th scope="col">Week {week}</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each players as player (player.userId)}
				<tr>
					<th scope="row" class="sticky player-col">{player.name}</th>
					<td class="col-gap"></td>
					{#each weeks as week (week)}
						{@const pick = player.picks.get(week)}
						{@const display =
							cellDisplays.get(pickSubmissionKey(player.userId, week)) ?? 'empty'}
						<td class="pick-cell">
							{#if display === 'hidden'}
								<span class="pick-ring ring-hidden" title={hiddenPickTitle(player.userId)}>
									<span class="ring-icon" aria-hidden="true">🔒</span>
								</span>
							{:else if display === 'missed'}
								<span class="pick-ring ring-missed" title="Missed pick">
									<span class="ring-icon ring-icon-missed" aria-hidden="true">×</span>
								</span>
							{:else if display === 'visible' && pick}
								<span
									class="pick-ring {ringClass(pick.outcome, display)}"
									title="{pick.team_abbreviation}{pick.outcome === 'win' && pick.is_underdog_at_pick
										? ' · Underdawg (2 pts)'
										: ''}{pick.is_commissioner_override ? ' · Commissioner override' : ''}"
								>
									<TeamLogo teamCode={pick.team_id} size={LOGO_SIZE} tile={false} />
									{#if pick.outcome === 'win' && pick.is_underdog_at_pick}
										<span class="chip-badge underdawg" title="Underdawg win (2 pts)">2</span>
									{/if}
									{#if pick.is_commissioner_override}
										<span class="chip-badge override" title="Commissioner override">✎</span>
									{/if}
								</span>
							{/if}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<p class="grid-legend muted">
	<span class="legend-ring ring-win"></span> win ·
	<span class="legend-ring ring-loss"></span> loss ·
	<span class="legend-ring ring-tie"></span> tie ·
	{#if !picksAreOpen}
		<span class="legend-ring ring-hidden"><span class="legend-lock">🔒</span></span> hidden pick ·
	{/if}
	<span class="legend-ring ring-missed"><span class="legend-missed">×</span></span> missed
</p>

<style>
	.picks-sticky-bar {
		--picks-player-w: 7.75rem;
		--picks-gap-w: 2rem;
		--picks-week-w: 2.75rem;
		position: sticky;
		top: var(--app-header-height, 3.75rem);
		z-index: 40;
		margin: -1.1rem -1.25rem 0.15rem;
		padding: 1.1rem 0 0.35rem;
		background: var(--surface);
	}

	.sticky-top {
		padding: 0 1.25rem;
		margin-bottom: 0.55rem;
	}

	.sticky-top :global(.card-title) {
		margin: 0 0 0.35rem;
	}

	.picks-header-scroll {
		overflow-x: auto;
		overflow-y: hidden;
		scrollbar-width: none;
	}

	.picks-header-scroll::-webkit-scrollbar {
		display: none;
	}

	.sr-only {
		position: absolute;
		width: 1px;
		height: 1px;
		padding: 0;
		margin: -1px;
		overflow: hidden;
		clip: rect(0, 0, 0, 0);
		white-space: nowrap;
		border: 0;
	}

	.grid-wrap {
		--picks-player-w: 7.75rem;
		--picks-gap-w: 2rem;
		--picks-week-w: 2.75rem;
		overflow-x: auto;
		/* Bleed to card edges so sticky player col covers the full left edge */
		margin: 0 -1.25rem;
		width: calc(100% + 2.5rem);
		max-width: none;
	}

	.picks-grid {
		border-collapse: separate;
		border-spacing: 0;
		table-layout: fixed;
		font-size: 0.8rem;
		width: max-content;
		margin-right: 1.25rem;
	}

	.picks-header-grid {
		color: var(--text-muted);
		font-weight: 600;
		font-size: 0.7rem;
	}

	th,
	td {
		padding: 0.35rem;
		border: none;
		background: transparent;
		text-align: center;
		vertical-align: middle;
	}

	.sticky {
		position: sticky;
		left: 0;
		z-index: 1;
		background: var(--surface);
	}

	.player-col {
		width: var(--picks-player-w);
		min-width: var(--picks-player-w);
		max-width: var(--picks-player-w);
		text-align: left;
		font-weight: 500;
		color: var(--text);
		padding: 0.35rem;
		padding-left: 1.25rem;
		padding-right: 0.65rem;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		background: var(--surface);
	}

	.header-player {
		z-index: 2;
		font-weight: 600;
		color: var(--text-muted);
	}

	.col-gap {
		width: var(--picks-gap-w);
		min-width: var(--picks-gap-w);
		max-width: var(--picks-gap-w);
		padding: 0;
	}

	.week-col,
	.pick-cell {
		width: var(--picks-week-w);
		min-width: var(--picks-week-w);
		max-width: var(--picks-week-w);
		padding: 0.2rem;
	}

	.pick-cell {
		height: 2.75rem;
	}

	.pick-ring {
		position: relative;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.25rem;
		height: 2.25rem;
		border-radius: 50%;
		background: #ffffff;
		border: 3px solid var(--ring-pending);
		box-sizing: border-box;
		flex-shrink: 0;
	}

	.ring-win {
		border-color: var(--ring-win);
	}

	.ring-loss {
		border-color: var(--ring-loss);
	}

	.ring-tie {
		border-color: var(--ring-tie);
	}

	.ring-pending {
		border-color: var(--ring-pending);
	}

	.ring-missed {
		border-color: var(--ring-loss);
	}

	.ring-hidden {
		border-color: var(--ring-pending);
	}

	.ring-icon {
		font-size: 0.85rem;
		line-height: 1;
	}

	.ring-icon-missed {
		font-size: 1.1rem;
		font-weight: 700;
		color: var(--ring-loss);
	}

	.chip-badge {
		position: absolute;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-width: 0.85rem;
		height: 0.85rem;
		padding: 0 0.15rem;
		border-radius: var(--radius);
		font-size: 0.55rem;
		font-weight: 800;
		line-height: 1;
		box-shadow: var(--shadow-sm);
	}

	.chip-badge.underdawg {
		top: -0.15rem;
		right: -0.2rem;
		background: var(--brand);
		color: var(--brand-text);
	}

	.chip-badge.override {
		bottom: -0.15rem;
		right: -0.2rem;
		background: var(--surface-2);
		color: var(--text-muted);
		font-size: 0.6rem;
	}

	.grid-legend {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.35rem 0.65rem;
		margin: 0.75rem 0 0;
		font-size: 0.78rem;
		line-height: 1.4;
	}

	.legend-ring {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 0.85rem;
		height: 0.85rem;
		border-radius: 50%;
		background: #ffffff;
		border: 2px solid var(--ring-pending);
		vertical-align: middle;
		margin-right: 0.15rem;
	}

	.legend-ring.ring-win {
		border-color: var(--ring-win);
	}

	.legend-ring.ring-loss,
	.legend-ring.ring-missed {
		border-color: var(--ring-loss);
	}

	.legend-ring.ring-tie {
		border-color: var(--ring-tie);
	}

	.legend-ring.ring-pending,
	.legend-ring.ring-hidden {
		border-color: var(--ring-pending);
	}

	.legend-lock {
		font-size: 0.45rem;
		line-height: 1;
	}

	.legend-missed {
		font-size: 0.55rem;
		font-weight: 700;
		color: var(--ring-loss);
		line-height: 1;
	}
</style>
