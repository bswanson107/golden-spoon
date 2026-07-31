<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { StandingRow } from '$lib/types/standings';
	import {
		DEFAULT_TIEBREAKER_MODE,
		type TiebreakerMode,
		parseTiebreakerMode,
		tiebreakerHint,
		tiebreakerShortLabel
	} from '$lib/leagueRules';

	let {
		standings,
		currentUserId = null,
		tiebreakerMode = DEFAULT_TIEBREAKER_MODE,
		adminKickEnabled = false,
		commissionerId = null,
		kickingUserId = null,
		onKickPlayer,
		stickyTop
	}: {
		standings: StandingRow[];
		currentUserId?: string | null;
		tiebreakerMode?: TiebreakerMode | string;
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
</script>

<div class="standings-sticky-bar">
	{#if stickyTop}
		<div class="sticky-top">
			{@render stickyTop()}
		</div>
	{/if}
	<div class="standings-header-row" aria-hidden="true">
		<span class="h-rank">#</span>
		<span class="h-player">Player</span>
		<span class="h-num">Pts</span>
		<span class="h-num">W-L</span>
		<span class="h-num" title={tiebreakerHint(resolvedTiebreaker)}>
			{tiebreakerShortLabel(resolvedTiebreaker)}
		</span>
	</div>
</div>

<div class="table-wrap">
	<table class="standings">
		<thead class="sr-only">
			<tr>
				<th scope="col">#</th>
				<th scope="col">Player</th>
				<th scope="col">Pts</th>
				<th scope="col">W-L</th>
				<th scope="col">{tiebreakerShortLabel(resolvedTiebreaker)}</th>
			</tr>
		</thead>
		<tbody>
			{#each standings as row (row.user_id)}
				<tr
					class:leader={showLeaderCrowns && row.standing_rank === 1}
					class:me={currentUserId !== null && row.user_id === currentUserId}
				>
					<td class="num rank">{row.standing_rank}</td>
					<td class="name">
						<span class="name-row">
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
					<td class="num points">{row.total_points.toFixed(1)}</td>
					<td class="num">{formatRecord(row)}</td>
					<td class="num tb">{row.tiebreaker_picked_team_wins}</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<style>
	.standings-sticky-bar {
		position: sticky;
		top: var(--app-header-height, 3.75rem);
		z-index: 40;
		margin: -1.1rem -1.25rem 0.15rem;
		padding: 1.1rem 1.25rem 0.45rem;
		background: var(--surface);
	}

	.sticky-top {
		margin-bottom: 0.55rem;
	}

	.sticky-top :global(.card-title) {
		margin: 0 0 0.35rem;
	}

	.sticky-top :global(.muted) {
		margin: 0 0 0.75rem;
	}

	.sticky-top :global(.muted:last-child),
	.sticky-top :global(.auth-error:last-child) {
		margin-bottom: 0;
	}

	.standings-header-row {
		display: grid;
		grid-template-columns: 6% 36% 16% 16% 26%;
		align-items: end;
		gap: 0;
		color: var(--text-muted);
		font-weight: 600;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.h-rank {
		text-align: center;
		padding-right: 0.25rem;
	}

	.h-player {
		text-align: left;
		padding-right: 0.5rem;
	}

	.h-num {
		text-align: right;
		font-variant-numeric: tabular-nums;
		line-height: 1.25;
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

	.table-wrap {
		overflow-x: auto;
		max-width: 100%;
	}

	.standings {
		width: 100%;
		table-layout: fixed;
		border-collapse: collapse;
		font-size: 0.9rem;
	}

	th,
	td {
		padding: 0.5rem 0.5rem;
		text-align: left;
		border-bottom: 1px solid var(--border);
		vertical-align: middle;
	}

	td:first-child {
		padding-left: 0;
	}

	td:last-child {
		padding-right: 0;
	}

	th:nth-child(1),
	td:nth-child(1) {
		width: 6%;
	}

	th:nth-child(2),
	td:nth-child(2) {
		width: 36%;
	}

	th:nth-child(3),
	td:nth-child(3) {
		width: 16%;
	}

	th:nth-child(4),
	td:nth-child(4) {
		width: 16%;
	}

	th:nth-child(5),
	td:nth-child(5) {
		width: 26%;
	}

	.num {
		text-align: right;
		font-variant-numeric: tabular-nums;
		white-space: nowrap;
	}

	.rank {
		color: var(--text-muted);
		text-align: center;
		padding-right: 0.25rem;
	}

	.name {
		font-weight: 500;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		padding-right: 0.5rem;
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
