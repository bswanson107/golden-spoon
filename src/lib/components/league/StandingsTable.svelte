<script lang="ts">
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
		onKickPlayer
	}: {
		standings: StandingRow[];
		currentUserId?: string | null;
		tiebreakerMode?: TiebreakerMode | string;
		adminKickEnabled?: boolean;
		commissionerId?: string | null;
		kickingUserId?: string | null;
		onKickPlayer?: (userId: string, displayName: string) => void;
	} = $props();

	const resolvedTiebreaker = $derived(parseTiebreakerMode(tiebreakerMode));

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

<div class="table-wrap">
	<table class="standings">
		<thead>
			<tr>
				<th scope="col">#</th>
				<th scope="col">Player</th>
				<th scope="col" class="num">Pts</th>
				<th scope="col" class="num">W-L</th>
				<th scope="col" class="num" title={tiebreakerHint(resolvedTiebreaker)}>
					{tiebreakerShortLabel(resolvedTiebreaker)}
				</th>
			</tr>
		</thead>
		<tbody>
			{#each standings as row (row.user_id)}
				<tr
					class:leader={row.standing_rank === 1}
					class:me={currentUserId !== null && row.user_id === currentUserId}
				>
					<td class="num rank">{row.standing_rank}</td>
					<td class="name">
						<span class="name-row">
							<span class="name-text">
								{row.display_name}
								{#if row.standing_rank === 1}
									<span class="crown" aria-label="Leader">👑</span>
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
	.table-wrap {
		overflow-x: auto;
	}

	.standings {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.9rem;
	}

	th,
	td {
		padding: 0.55rem 0.65rem;
		text-align: left;
		border-bottom: 1px solid var(--border);
	}

	th {
		color: var(--text-muted);
		font-weight: 600;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.num {
		text-align: right;
		font-variant-numeric: tabular-nums;
	}

	.rank {
		color: var(--text-muted);
		width: 2rem;
	}

	.name {
		font-weight: 500;
		min-width: 8rem;
	}

	.name-row {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
	}

	.name-text {
		display: inline-flex;
		align-items: center;
		gap: 0.25rem;
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
