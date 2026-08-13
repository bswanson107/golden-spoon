<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { StandingRow } from '$lib/types/standings';
	import {
		DEFAULT_TIEBREAKER_MODE,
		type TiebreakerMode,
		parseTiebreakerMode,
		tiebreakerHint
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

<div class="standings-wrap">
	<table class="standings">
		<!-- colgroup beats the colspan title row for fixed-layout column widths -->
		<colgroup>
			<col class="c-rank" />
			<col class="c-player" />
			<col class="c-num" />
			<col class="c-num" />
			<col class="c-tb" />
		</colgroup>
		<thead>
			{#if stickyTop}
				<tr class="title-row">
					<th colspan="5" scope="colgroup">
						<div class="sticky-top">
							{@render stickyTop()}
						</div>
					</th>
				</tr>
			{/if}
			<tr class="cols-row">
				<th scope="col" class="col-rank">#</th>
				<th scope="col" class="col-player">Player</th>
				<th scope="col" class="col-num">Pts</th>
				<th scope="col" class="col-num">W-L</th>
				<th scope="col" class="col-num col-tb">
					<span
						class="tb-label"
						title={tiebreakerHint(resolvedTiebreaker)}
						aria-label={tiebreakerHint(resolvedTiebreaker)}
						data-tooltip="Tiebreaker"
						tabindex="0"
					>TB</span>
				</th>
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
					<td class="col-num">{formatRecord(row)}</td>
					<td class="col-num col-tb tb">{row.tiebreaker_picked_team_wins}</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<style>
	.standings-wrap {
		overflow: visible;
		max-width: 100%;
		/* Pull into the card's top padding so it can stick with the header. */
		margin-top: -1.1rem;
	}

	.standings {
		width: 100%;
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

	thead {
		position: sticky;
		top: var(--app-header-height, 3.75rem);
		z-index: 40;
		background: var(--surface);
	}

	.title-row th {
		padding: 1.1rem 0 0.55rem;
		border: none;
		font-weight: inherit;
		text-align: left;
		vertical-align: bottom;
		background: var(--surface);
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

	thead:not(:has(.title-row)) .cols-row th {
		padding-top: calc(1.1rem + 0.35rem);
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
		.c-rank {
			width: 1.6rem;
		}

		.c-num {
			width: 3.1rem;
		}

		.c-tb {
			width: 2.5rem;
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

	.tb-label::after {
		content: attr(data-tooltip);
		position: absolute;
		right: 0;
		bottom: calc(100% + 0.4rem);
		transform: translateY(0.15rem);
		padding: 0.35rem 0.55rem;
		border-radius: var(--radius);
		background: var(--text);
		color: var(--surface);
		font-size: 0.72rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		text-transform: none;
		white-space: nowrap;
		box-shadow: var(--shadow);
		opacity: 0;
		pointer-events: none;
		transition:
			opacity 0.12s ease,
			transform 0.12s ease;
		z-index: 300;
	}

	.tb-label:hover::after,
	.tb-label:focus-visible::after {
		opacity: 1;
		transform: translateY(0);
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
