<script lang="ts">
	import { onMount } from 'svelte';
	import type { Snippet } from 'svelte';
	import MemberAvatar from '$lib/components/MemberAvatar.svelte';
	import type { LeaguePick, StandingRow } from '$lib/types/standings';
	import {
		DEFAULT_TIEBREAKER_MODE,
		type TiebreakerMode,
		parseTiebreakerMode,
		tiebreakerHint
	} from '$lib/leagueRules';
	import { rankMovementByUser, streakFromPicks, type PickStreak, type RankMove } from '$lib/standingStats';

	let {
		standings,
		picks = [],
		movementWeek = 1,
		currentUserId = null,
		tiebreakerMode = DEFAULT_TIEBREAKER_MODE,
		showProfilePictures = false,
		adminKickEnabled = false,
		commissionerId = null,
		kickingUserId = null,
		onKickPlayer,
		stickyTop
	}: {
		standings: StandingRow[];
		/** Picks already limited to the weeks reflected in `standings`. */
		picks?: LeaguePick[];
		/**
		 * Week whose results count as "this week" for +/-.
		 * Previous rank uses picks from earlier weeks only.
		 */
		movementWeek?: number;
		currentUserId?: string | null;
		tiebreakerMode?: TiebreakerMode | string;
		showProfilePictures?: boolean;
		adminKickEnabled?: boolean;
		commissionerId?: string | null;
		kickingUserId?: string | null;
		onKickPlayer?: (userId: string, displayName: string) => void;
		stickyTop?: Snippet;
	} = $props();

	const resolvedTiebreaker = $derived(parseTiebreakerMode(tiebreakerMode));

	/** Hide crowns when every player shares the same points total. */
	const showLeaderCrowns = $derived(
		standings.length > 0 &&
			standings.some((row) => row.total_points !== standings[0].total_points)
	);

	function formatRecord(row: StandingRow): string {
		if (row.ties > 0) {
			return `${row.wins}-${row.losses}-${row.ties}`;
		}
		return `${row.wins}-${row.losses}`;
	}

	function canKickPlayer(row: StandingRow): boolean {
		if (!adminKickEnabled || !onKickPlayer) return false;
		if (currentUserId !== null && row.user_id === currentUserId) return false;
		if (commissionerId !== null && row.user_id === commissionerId) return false;
		return true;
	}

	/** Mobile only; desktop always shows tiebreaker, streak, and +/-. Off by default. */
	let showAdvancedStats = $state(false);
	/**
	 * Matches the mobile CSS breakpoint where the TB column can be toggled off.
	 * Start false to match SSR; onMount syncs to the real viewport.
	 */
	let isMobileViewport = $state(false);
	let scroller = $state<HTMLDivElement | null>(null);
	/** Full content width of the table, mirrored by the top scrollbar. */
	let overflowWidth = $state(0);
	let viewportWidth = $state(0);
	let scrollLeft = $state(0);
	let canScrollX = $state(false);

	const thumbWidth = $derived(
		overflowWidth > 0 ? Math.max(28, (viewportWidth / overflowWidth) * viewportWidth) : 0
	);
	const thumbOffset = $derived.by(() => {
		const max = overflowWidth - viewportWidth;
		const travel = viewportWidth - thumbWidth;
		if (max <= 0 || travel <= 0) return 0;
		return (scrollLeft / max) * travel;
	});

	function updateScrollHint() {
		if (!scroller) return;
		const width = scroller.scrollWidth;
		const view = scroller.clientWidth;
		const overflow = width > view + 1;
		if (width !== overflowWidth) overflowWidth = width;
		if (view !== viewportWidth) viewportWidth = view;
		if (scroller.scrollLeft !== scrollLeft) scrollLeft = scroller.scrollLeft;
		if (overflow !== canScrollX) canScrollX = overflow;
	}

	function onContentScroll() {
		hideTip();
		if (!scroller || scroller.scrollLeft === scrollLeft) return;
		scrollLeft = scroller.scrollLeft;
	}

	function scrollFromPointer(event: PointerEvent, track: HTMLElement) {
		if (!scroller) return;
		const rect = track.getBoundingClientRect();
		const max = scroller.scrollWidth - scroller.clientWidth;
		const travel = Math.max(rect.width - thumbWidth, 1);
		const x = Math.min(Math.max(event.clientX - rect.left - thumbWidth / 2, 0), travel);
		scroller.scrollLeft = (x / travel) * max;
	}

	function onHintPointerDown(event: PointerEvent) {
		const track = event.currentTarget as HTMLElement;
		track.setPointerCapture(event.pointerId);
		scrollFromPointer(event, track);
	}

	function onHintPointerMove(event: PointerEvent) {
		const track = event.currentTarget as HTMLElement;
		if (!track.hasPointerCapture(event.pointerId)) return;
		scrollFromPointer(event, track);
	}

	onMount(() => {
		const mq = window.matchMedia('(max-width: 640px)');
		const sync = () => {
			isMobileViewport = mq.matches;
		};
		sync();
		mq.addEventListener('change', sync);

		const ro = new ResizeObserver(() => updateScrollHint());
		if (scroller) {
			ro.observe(scroller);
			if (scroller.firstElementChild) ro.observe(scroller.firstElementChild);
		}
		updateScrollHint();

		return () => {
			mq.removeEventListener('change', sync);
			ro.disconnect();
		};
	});

	/**
	 * Omit advanced columns when they're toggled off on mobile.
	 * Hiding via CSS (visibility:collapse / display:none on <col>) leaves a
	 * trailing gap in Safari with table-layout:fixed; removing the columns avoids that.
	 */
	const showAdvancedColumns = $derived(!isMobileViewport || showAdvancedStats);

	const streaks = $derived.by(() => {
		const byUser = new Map<string, LeaguePick[]>();
		for (const pick of picks) {
			const key = pick.user_id.toLowerCase();
			const list = byUser.get(key) ?? [];
			list.push(pick);
			byUser.set(key, list);
		}
		const map = new Map<string, PickStreak | null>();
		for (const [key, userPicks] of byUser) {
			map.set(key, streakFromPicks(userPicks));
		}
		return map;
	});

	const movement = $derived(rankMovementByUser(standings, picks, movementWeek));

	function streakFor(userId: string): PickStreak | null {
		return streaks.get(userId.toLowerCase()) ?? null;
	}

	function moveFor(userId: string): RankMove | null {
		return movement.get(userId.toLowerCase()) ?? null;
	}

	let tipText = $state<string | null>(null);
	let tipStyle = $state('');

	function showTip(event: MouseEvent | FocusEvent, text: string) {
		const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
		const maxWidth = Math.min(256, window.innerWidth - 16);
		const pinLeft = rect.right - maxWidth < 8;
		tipText = text;
		tipStyle = pinLeft
			? `top:${rect.bottom + 6}px;left:8px;max-width:${maxWidth}px`
			: `top:${rect.bottom + 6}px;left:${rect.right}px;transform:translateX(-100%);max-width:${maxWidth}px`;
	}

	function hideTip() {
		tipText = null;
	}

	$effect(() => {
		showAdvancedColumns;
		standings.length;
		queueMicrotask(() => updateScrollHint());
	});
</script>

<svelte:window onscroll={hideTip} />

<div
	class="standings-wrap"
	class:show-advanced={showAdvancedStats}
	class:advanced-cols={showAdvancedColumns}
>
	{#if stickyTop}
		<div class="sticky-top">
			<div class="title-with-toggle">
				<div class="title-copy">
					{@render stickyTop()}
				</div>
				<label class="tb-toggle">
					<input
						type="checkbox"
						bind:checked={showAdvancedStats}
						aria-controls={showAdvancedColumns
							? 'standings-tb-col standings-streak-col standings-move-col'
							: undefined}
					/>
					<span>Advanced Stats</span>
				</label>
			</div>
		</div>
	{/if}
	{#if canScrollX}
		<div
			class="scroll-hint"
			aria-hidden="true"
			onpointerdown={onHintPointerDown}
			onpointermove={onHintPointerMove}
		>
			<div
				class="scroll-hint-thumb"
				style:width="{thumbWidth}px"
				style:transform="translateX({thumbOffset}px)"
			></div>
		</div>
	{/if}
	<div class="standings-scroll" bind:this={scroller} onscroll={onContentScroll}>
	<table class="standings">
		<!-- colgroup beats the colspan title row for fixed-layout column widths -->
		<colgroup>
			<col class="c-rank" />
			<col class="c-player" />
			<col class="c-num" />
			<col class="c-num" />
			{#if showAdvancedColumns}
				<col class="c-tb" />
				<col class="c-streak" />
				<col class="c-move" />
			{/if}
		</colgroup>
		<thead>
			<tr class="cols-row">
				<th scope="col" class="col-rank">#</th>
				<th scope="col" class="col-player">Player</th>
				<th scope="col" class="col-num">Pts</th>
				<th scope="col" class="col-num">W-L</th>
				{#if showAdvancedColumns}
					<th scope="col" class="col-num col-advanced col-tb" id="standings-tb-col">
						<span
							class="tb-label"
							tabindex="0"
							onmouseenter={(e) => showTip(e, tiebreakerHint(resolvedTiebreaker))}
							onmouseleave={hideTip}
							onfocus={(e) => showTip(e, tiebreakerHint(resolvedTiebreaker))}
							onblur={hideTip}
						>TB</span>
					</th>
					<th scope="col" class="col-num col-advanced col-streak" id="standings-streak-col">
						<span
							class="tb-label"
							tabindex="0"
							onmouseenter={(e) => showTip(e, 'Consecutive wins or losses')}
							onmouseleave={hideTip}
							onfocus={(e) => showTip(e, 'Consecutive wins or losses')}
							onblur={hideTip}
						>Streak</span>
					</th>
					<th scope="col" class="col-num col-advanced col-move" id="standings-move-col">
						<span
							class="tb-label"
							tabindex="0"
							onmouseenter={(e) => showTip(e, 'Places moved since last week')}
							onmouseleave={hideTip}
							onfocus={(e) => showTip(e, 'Places moved since last week')}
							onblur={hideTip}
						>+/−</span>
					</th>
				{/if}
			</tr>
		</thead>
		<tbody>
			{#each standings as row (row.user_id)}
				<tr
					class:leader={showLeaderCrowns && row.standing_rank === 1}
					class:me={currentUserId !== null && row.user_id === currentUserId}
					data-testid="standings-row"
					data-user={row.user_id.toLowerCase()}
				>
					<td class="col-rank">{row.standing_rank}</td>
					<td class="col-player">
						<span class="name-row">
							{#if showProfilePictures}
								<MemberAvatar name={row.display_name} avatarKey={row.avatar_key} size={26} />
							{/if}
							<span class="name-text">
								{row.display_name}
								{#if showLeaderCrowns && row.standing_rank === 1}
									<span class="crown" aria-label="League leader">👑</span>
								{/if}
							</span>
							{#if canKickPlayer(row)}
								<button
									type="button"
									class="kick-btn"
									title="Remove {row.display_name} from league"
									disabled={kickingUserId === row.user_id}
									aria-label="Remove {row.display_name} from league"
									onclick={() => onKickPlayer?.(row.user_id, row.display_name)}
								>
									{kickingUserId === row.user_id ? '…' : '×'}
								</button>
							{/if}
						</span>
					</td>
					<td class="col-num points" data-testid="standings-points"
						>{row.total_points.toFixed(1)}</td
					>
					<td class="col-num" data-testid="standings-record">{formatRecord(row)}</td>
					{#if showAdvancedColumns}
						{@const streak = streakFor(row.user_id)}
						{@const move = moveFor(row.user_id)}
						<td class="col-num col-advanced col-tb tb" data-testid="standings-tb"
							>{row.tiebreaker_picked_team_wins}</td
						>
						<td class="col-num col-advanced col-streak" data-testid="standings-streak">
							{#if streak}
								<span class:streak-w={streak.kind === 'W'} class:streak-l={streak.kind === 'L'}
									>{streak.kind}{streak.length}</span
								>
							{:else}
								<span class="flat">—</span>
							{/if}
						</td>
						<td class="col-num col-advanced col-move" data-testid="standings-move">
							{#if move && move.direction !== 'same'}
								<span
									class="move"
									class:up={move.direction === 'up'}
									class:down={move.direction === 'down'}
									aria-label={move.direction === 'up'
										? `Up ${move.places} since last week`
										: `Down ${move.places} since last week`}
								>
									<span aria-hidden="true">{move.direction === 'up' ? '↑' : '↓'}</span>{move.places}
								</span>
							{:else}
								<span
									class="flat"
									aria-label={move ? 'No change since last week' : 'No previous week'}
									>—</span
								>
							{/if}
						</td>
					{/if}
				</tr>
			{/each}
		</tbody>
	</table>
	</div>
	{#if tipText}
		<div class="col-tip" style={tipStyle} role="tooltip">{tipText}</div>
	{/if}
</div>

<style>
	.standings-wrap {
		overflow: visible;
		max-width: 100%;
		/* Pull into the card's top padding so it can stick with the header. */
		margin-top: -1.1rem;
	}

	.scroll-hint {
		position: relative;
		height: 6px;
		margin: 0.1rem 0 0.35rem;
		border-radius: 999px;
		background: color-mix(in srgb, var(--text) 12%, transparent);
		cursor: grab;
		touch-action: none;
	}

	.scroll-hint:active {
		cursor: grabbing;
	}

	.scroll-hint-thumb {
		position: absolute;
		top: 0;
		left: 0;
		height: 100%;
		border-radius: 999px;
		background: color-mix(in srgb, var(--text) 42%, transparent);
		pointer-events: none;
	}

	.standings-scroll {
		container-type: inline-size;
		max-width: 100%;
		/* clip on the block axis so horizontal scroll does not force a vertical scrollbar. */
		overflow-x: auto;
		overflow-y: clip;
		overscroll-behavior-x: contain;
		-webkit-overflow-scrolling: touch;
		scrollbar-width: none;
	}

	.standings-scroll::-webkit-scrollbar {
		display: none;
		height: 0;
	}

	.standings {
		width: 100%;
		min-width: 32rem;
		table-layout: fixed;
		border-collapse: collapse;
		font-size: 0.9rem;
	}

	.c-rank {
		width: 2.25rem;
	}

	.c-player {
		width: auto;
	}

	.c-num {
		width: 3.75rem;
	}

	.c-tb {
		width: 3.25rem;
	}

	.c-streak {
		width: 4.5rem;
	}

	.c-move {
		width: 3.75rem;
	}

	thead {
		position: relative;
		z-index: 2;
		background: var(--surface);
	}

	.title-with-toggle {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.75rem;
	}

	.title-copy {
		min-width: 0;
		flex: 1;
	}

	.tb-toggle {
		display: none;
		flex-direction: row;
		align-items: center;
		justify-content: center;
		gap: 0.35rem;
		flex-shrink: 0;
		margin-top: 0.1rem;
		padding: 0.35rem 0.45rem;
		border-radius: var(--radius);
		background: var(--surface-2);
		box-shadow: var(--shadow-sm);
		font-size: 0.68rem;
		font-weight: 600;
		color: var(--text-muted);
		cursor: pointer;
		user-select: none;
		white-space: nowrap;
		margin-right: 3px;
	}

	.tb-toggle input {
		width: 0.9rem;
		height: 0.9rem;
		accent-color: var(--brand);
	}

	.standings-wrap.show-advanced .tb-toggle {
		color: var(--text);
	}

	.sticky-top {
		position: sticky;
		top: var(--app-sticky-top, 3.75rem);
		z-index: 41;
		background: var(--surface);
		padding: 1.1rem 0 0.55rem;
	}

	.sticky-top :global(.card-title) {
		margin: 0;
	}

	.sticky-top :global(.muted) {
		margin: 0.35rem 0 0;
	}

	.sticky-top :global(.muted:last-child),
	.sticky-top :global(.auth-error:last-child) {
		margin-bottom: 0;
	}

	.cols-row th {
		padding: 0.35rem 0.5rem 0.45rem;
		border-bottom: 1px solid var(--border);
		color: var(--text-muted);
		font-weight: 600;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		vertical-align: bottom;
		background: var(--surface);
	}

	td {
		padding: 0.5rem;
		border-bottom: 1px solid var(--border);
		vertical-align: middle;
	}

	tbody tr:nth-child(odd) {
		background: var(--surface);
	}

	tbody tr:nth-child(even) {
		background: var(--stripe-b);
	}

	.col-rank {
		text-align: left;
		padding-left: 0.5rem;
		padding-right: 0;
		color: var(--text-muted);
		font-variant-numeric: tabular-nums;
	}

	.cols-row .col-rank {
		padding-left: 0.5rem;
		padding-right: 0;
	}

	.col-player {
		text-align: left;
		font-weight: 500;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		padding-left: 1rem;
	}

	.cols-row .col-player {
		font-weight: 600;
		padding-left: 1rem;
	}

	.col-num {
		text-align: right;
		font-variant-numeric: tabular-nums;
		white-space: nowrap;
	}

	@media (max-width: 640px) {
		.standings {
			min-width: 0;
		}

		.standings-wrap.show-advanced .standings {
			/* Extra width is the TB + streak + movement columns, so the others keep their spacing. */
			width: calc(100% + 2.5rem + 4.25rem + 3.25rem);
			min-width: calc(100% + 2.5rem + 4.25rem + 3.25rem);
		}

		.tb-toggle {
			display: inline-flex;
		}

		/* Pre-hydration fallback: hide advanced columns until matchMedia removes them. */
		.standings-wrap:not(.show-advanced) .c-tb,
		.standings-wrap:not(.show-advanced) .c-streak,
		.standings-wrap:not(.show-advanced) .c-move,
		.standings-wrap:not(.show-advanced) .col-advanced {
			display: none;
		}

		.c-rank {
			width: 1.6rem;
		}

		.c-num {
			width: 3.1rem;
		}

		.c-tb {
			width: 2.5rem;
		}

		.c-streak {
			width: 4.25rem;
		}

		.c-move {
			width: 3.25rem;
		}

		.col-rank,
		.cols-row .col-rank {
			padding-left: 0.5rem;
			padding-right: 0;
		}

		.col-player,
		.cols-row .col-player {
			padding-left: 0.8rem;
		}

		.col-num {
			padding-left: 0.25rem;
			padding-right: 0.35rem;
		}

		.col-tb {
			padding-left: 0.25rem;
		}
	}

	.tb-label {
		position: relative;
		display: inline-flex;
		cursor: help;
	}

	.col-tip {
		position: fixed;
		z-index: 400;
		width: max-content;
		padding: 0.35rem 0.55rem;
		border-radius: var(--radius);
		background: var(--text);
		color: var(--surface);
		font-size: 0.72rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		line-height: 1.35;
		text-align: left;
		text-transform: none;
		white-space: normal;
		box-shadow: var(--shadow);
		pointer-events: none;
	}

	.tb-label:focus-visible {
		outline: 2px solid var(--brand);
		outline-offset: 2px;
		border-radius: 0.15rem;
	}

	.name-row {
		display: flex;
		align-items: center;
		gap: 0.45rem;
		min-width: 0;
	}

	.name-text {
		display: block;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		min-width: 0;
		flex: 1;
	}

	.kick-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 1.35rem;
		height: 1.35rem;
		padding: 0;
		border: none;
		border-radius: 999px;
		background: color-mix(in srgb, var(--danger) 12%, var(--surface));
		color: var(--danger);
		font-size: 1rem;
		line-height: 1;
		font-weight: 700;
		cursor: pointer;
		box-shadow: var(--shadow-sm);
		flex-shrink: 0;
	}

	.kick-btn:hover:not(:disabled) {
		background: color-mix(in srgb, var(--danger) 20%, var(--surface));
	}

	.kick-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.points {
		font-weight: 700;
		color: var(--brand);
	}

	.tb {
		color: var(--text-muted);
	}

	.streak-w,
	.move.up {
		color: var(--ring-win);
		font-weight: 700;
	}

	.streak-l,
	.move.down {
		color: var(--ring-loss);
		font-weight: 700;
	}

	.flat {
		color: var(--text-muted);
	}

	.leader .name-text {
		color: var(--brand);
	}

	.me {
		background: var(--brand-muted-you);
	}

	:global([data-theme='light']) .points,
	:global([data-theme='light']) .leader .name-text {
		color: var(--text);
	}

	.crown {
		margin-left: 0.1rem;
	}
</style>
