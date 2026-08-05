<script lang="ts">
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import GameKickoffInfo from '$lib/components/pick/GameKickoffInfo.svelte';
	import { getTeamName } from '$lib/data/nflTeams';
	import { isUnderdog, formatWinPct } from '$lib/demo';
	import { qaNow } from '$lib/qaClock.svelte';
	import type { WeekGame } from '$lib/types/game';

	let {
		games,
		selectedTeamId = null,
		isSubmittedPickGameId = null,
		teamUsageByWeek = new Map<string, number>(),
		lockedTeamIds = new Set<string>(),
		activeWeek = 1,
		pickingEnabled = true,
		underdogThreshold = 33,
		onSelectTeam
	}: {
		games: WeekGame[];
		selectedTeamId?: string | null;
		isSubmittedPickGameId?: string | null;
		teamUsageByWeek?: Map<string, number>;
		lockedTeamIds?: Set<string>;
		activeWeek?: number;
		pickingEnabled?: boolean;
		underdogThreshold?: number;
		onSelectTeam?: (game: WeekGame, teamId: string) => void;
	} = $props();

	type TeamState = 'selected' | 'selectable' | 'locked' | 'used-elsewhere' | 'used-locked';

	function teamState(teamId: string, kickoffAt: string): TeamState {
		const kickedOff = new Date(kickoffAt).getTime() <= qaNow();
		if (selectedTeamId === teamId) {
			return pickingEnabled && !kickedOff ? 'selectable' : 'selected';
		}
		if (!pickingEnabled || kickedOff) return 'locked';
		const usedWeek = teamUsageByWeek.get(teamId);
		if (usedWeek !== undefined && usedWeek !== activeWeek) {
			if (lockedTeamIds.has(teamId)) return 'used-locked';
			return 'used-elsewhere';
		}
		return 'selectable';
	}

	function isDisabled(state: TeamState): boolean {
		// `selected` = current pick but no longer changeable (kickoff passed / week closed)
		return state === 'locked' || state === 'used-locked' || state === 'selected';
	}

	function displayName(teamId: string, fallbackName: string): string {
		const fromCatalog = getTeamName(teamId);
		return fromCatalog !== teamId ? fromCatalog : fallbackName;
	}

	function usedWeekFor(teamId: string): number | undefined {
		return teamUsageByWeek.get(teamId);
	}

	function teamTitle(teamId: string): string | undefined {
		const usedWeek = teamUsageByWeek.get(teamId);
		if (usedWeek === undefined || usedWeek === activeWeek) return undefined;
		if (lockedTeamIds.has(teamId)) return `Locked — picked Week ${usedWeek}`;
		return `Already selected — Week ${usedWeek}`;
	}
</script>

<div class="table-wrap">
	<table class="game-table">
		<thead>
			<tr>
				<th scope="col" class="col-pick">Team</th>
				<th scope="col" class="col-kickoff">Kickoff</th>
			</tr>
		</thead>
		<tbody>
			{#each games as game, gi (game.id)}
				{@const isSubmitted = isSubmittedPickGameId === game.id}
				{@const teams = [
					{ team: game.away, side: 'Away', winPct: game.away_win_pct },
					{ team: game.home, side: 'Home', winPct: game.home_win_pct }
				]}
				{#if gi > 0}
					<tr class="game-divider" aria-hidden="true">
						<td colspan="2"></td>
					</tr>
				{/if}
				{#each teams as { team, side, winPct }, ti}
					{@const state = teamState(team.id, game.kickoff_at)}
					{@const isSelected = selectedTeamId === team.id}
					{@const isUD = winPct !== null && isUnderdog(winPct, underdogThreshold)}
					{@const usedWk = usedWeekFor(team.id)}
					{@const stripe = (gi * 2 + ti) % 2 === 0 ? 'stripe-a' : 'stripe-b'}
					{@const fullName = displayName(team.id, team.name)}
					<tr
						class="team-row {state} {stripe}"
						class:is-selected={isSelected}
						class:is-submitted={isSubmitted && isSelected}
						title={teamTitle(team.id)}
						onclick={() => !isDisabled(state) && onSelectTeam?.(game, team.id)}
						role="button"
						tabindex={isDisabled(state) ? -1 : 0}
						aria-pressed={isSelected}
						aria-disabled={isDisabled(state)}
						onkeydown={(e) => {
							if ((e.key === 'Enter' || e.key === ' ') && !isDisabled(state)) {
								e.preventDefault();
								onSelectTeam?.(game, team.id);
							}
						}}
					>
						<td class="col-pick">
							<div class="pick-block">
								<div class="pick-logo">
									<TeamLogo teamCode={team.id} size={32} />
								</div>
								<span class="side-label">{side}</span>
								<div class="team-line-primary">
									<span class="team-name">{fullName}</span>
								</div>
								<div class="team-line-meta">
									{#if isSelected || usedWk !== undefined || isUD}
										<span class="badges">
											{#if isSelected}
												<span class="badge badge-pick">Your pick</span>
											{:else if usedWk !== undefined}
												<span class="badge badge-used">Wk {usedWk}</span>
											{/if}
											{#if isUD}
												<span class="badge badge-ud">Underdawg</span>
											{/if}
										</span>
									{/if}
									<span class="win-pct">{formatWinPct(winPct)}</span>
								</div>
							</div>
						</td>
						{#if ti === 0}
							<td class="col-kickoff" rowspan="2">
								<GameKickoffInfo kickoffAt={game.kickoff_at} layout="stack" align="end" />
							</td>
						{/if}
					</tr>
				{/each}
			{/each}
		</tbody>
	</table>
</div>

<style>
	.table-wrap {
		overflow-x: clip;
		max-width: 100%;
	}

	.game-table {
		width: 100%;
		max-width: 100%;
		border-collapse: collapse;
		font-size: 0.875rem;
		table-layout: fixed;
	}

	thead th {
		padding: 0.3rem 0.45rem;
		text-align: left;
		font-size: 0.68rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-muted);
		border-bottom: none;
		white-space: nowrap;
	}

	.team-row td.col-pick {
		/* 1px height trick: forces the pick-block child to stretch to full row height */
		height: 1px;
		padding: 0;
		border: none;
		background: transparent;
		vertical-align: stretch;
		cursor: pointer;
	}

	.team-row td.col-kickoff {
		padding: 0.45rem 0.45rem;
		vertical-align: middle;
		background: var(--surface-2);
		border: none;
		cursor: default;
	}

	.team-row td.col-kickoff:last-child {
		padding-right: 0.5rem;
	}

	.pick-block {
		box-sizing: border-box;
		height: 100%;
		min-height: 100%;
		display: grid;
		grid-template-columns: auto auto minmax(0, 1fr);
		grid-template-rows: auto auto;
		column-gap: 0.45rem;
		row-gap: 0.2rem;
		align-items: center;
		padding: 0.45rem 0.35rem 0.45rem 0.5rem;
		border: 2px solid transparent;
		background: color-mix(in srgb, var(--text) 3.5%, var(--surface));
		transition: background 0.12s ease;
	}

	.team-row.stripe-b .pick-block {
		background: color-mix(in srgb, var(--text) 8%, var(--surface));
	}

	.team-row.selectable:hover .pick-block,
	.team-row.used-elsewhere:hover .pick-block {
		background: color-mix(in srgb, var(--text) 12%, var(--surface));
	}

	.team-row.locked .pick-block,
	.team-row.used-locked .pick-block {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.team-row.used-elsewhere .pick-block {
		opacity: 0.92;
		border-style: dotted;
		border-color: var(--text-muted);
	}

	.team-row.is-selected .pick-block,
	.team-row.is-submitted .pick-block {
		background: color-mix(in srgb, var(--brand-muted) 70%, var(--surface));
		border-style: solid;
		border-color: var(--brand);
	}

	:global([data-theme='light']) .team-row.is-selected .pick-block,
	:global([data-theme='light']) .team-row.is-submitted .pick-block {
		background: color-mix(in srgb, #d4a72c 22%, var(--surface));
		border-color: #9a7418;
	}

	.game-divider td {
		padding: 0.3rem 0;
		background: transparent;
		border: none;
	}

	.col-pick {
		min-width: 0;
	}

	.col-kickoff {
		width: 5.75rem;
		text-align: right;
		white-space: normal;
		vertical-align: middle;
	}

	.pick-logo {
		grid-column: 1;
		grid-row: 1 / 3;
		align-self: center;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.side-label {
		grid-column: 2;
		grid-row: 1 / 3;
		align-self: center;
		font-size: 0.65rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.07em;
		color: var(--text-muted);
		line-height: 1.1;
	}

	.team-line-primary {
		grid-column: 3;
		grid-row: 1;
		min-width: 0;
		align-self: end;
	}

	.team-line-meta {
		grid-column: 3;
		grid-row: 2;
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: flex-start;
		gap: 0.35rem;
		min-width: 0;
		align-self: start;
	}

	.team-name {
		display: block;
		font-weight: 600;
		color: var(--text);
		line-height: 1.25;
		min-width: 0;
	}

	/* Mobile: win % first (left), then badges inline after it */
	.win-pct {
		order: 1;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
		color: var(--text);
		font-size: 0.82rem;
		flex-shrink: 0;
		text-align: left;
	}

	.badges {
		order: 2;
		display: flex;
		flex-wrap: nowrap;
		gap: 0.3rem;
		align-items: center;
		justify-content: flex-start;
		min-width: 0;
	}

	.badge {
		font-size: 0.58rem;
		font-weight: 800;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		padding: 0.12rem 0.35rem;
		border-radius: var(--radius);
		line-height: 1.3;
		white-space: nowrap;
	}

	.badge-pick {
		background: var(--win-bg);
		color: var(--win-text);
	}

	.badge-used {
		background: var(--tie-bg);
		color: var(--tie-text);
	}

	:global([data-theme='dark']) .badge-used {
		background: #3b82f6;
		color: #fff;
	}

	.badge-ud {
		background: var(--brand);
		color: var(--brand-text);
	}

	/* Desktop: single-row team layout */
	@media (min-width: 640px) {
		.col-kickoff {
			width: 7rem;
		}

		.pick-block {
			grid-template-columns: auto 2.6rem minmax(0, 1fr) auto;
			grid-template-rows: auto;
			column-gap: 0.55rem;
			row-gap: 0;
			align-items: center;
			padding-right: 0.35rem;
		}

		.pick-logo {
			grid-column: auto;
			grid-row: auto;
		}

		.side-label {
			grid-column: auto;
			grid-row: auto;
			font-size: 0.68rem;
		}

		.team-line-primary {
			display: contents;
		}

		/* Keep meta as one trailing flex cell: badges then win % (right-aligned) */
		.team-line-meta {
			grid-column: auto;
			grid-row: auto;
			display: flex;
			flex-wrap: nowrap;
			align-items: center;
			justify-content: flex-end;
			gap: 0.4rem;
			align-self: center;
		}

		.team-name {
			overflow: hidden;
			text-overflow: ellipsis;
			white-space: nowrap;
			align-self: center;
		}

		.badges {
			order: 1;
			justify-content: flex-end;
		}

		.win-pct {
			order: 2;
			font-size: 0.875rem;
			min-width: 2.5rem;
			text-align: right;
		}
	}
</style>
