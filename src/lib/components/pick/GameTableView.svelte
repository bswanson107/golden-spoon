<script lang="ts">
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import { getTeamName, getTeamSurfaceTint } from '$lib/data/nflTeams';
	import { isUnderdog, formatWinPct } from '$lib/demo';
	import { formatGameKickoffTable } from '$lib/gameKickoff';
	import type { WeekGame } from '$lib/types/game';

	let {
		games,
		selectedTeamId = null,
		isSubmittedPickGameId = null,
		teamUsageByWeek = new Map<string, number>(),
		activeWeek = 1,
		pickingEnabled = true,
		underdogThreshold = 33,
		onSelectTeam
	}: {
		games: WeekGame[];
		selectedTeamId?: string | null;
		isSubmittedPickGameId?: string | null;
		teamUsageByWeek?: Map<string, number>;
		activeWeek?: number;
		pickingEnabled?: boolean;
		underdogThreshold?: number;
		onSelectTeam?: (game: WeekGame, teamId: string) => void;
	} = $props();

	function teamState(teamId: string): 'selected' | 'selectable' | 'locked' | 'used-elsewhere' {
		if (selectedTeamId === teamId) return pickingEnabled ? 'selectable' : 'selected';
		if (!pickingEnabled) return 'locked';
		const usedWeek = teamUsageByWeek.get(teamId);
		if (usedWeek !== undefined && usedWeek !== activeWeek) return 'used-elsewhere';
		return 'selectable';
	}

	function displayName(teamId: string, fallbackName: string): string {
		const fromCatalog = getTeamName(teamId);
		return fromCatalog !== teamId ? fromCatalog : fallbackName;
	}

	function usedWeekFor(teamId: string): number | undefined {
		return teamUsageByWeek.get(teamId);
	}
</script>

<div class="table-wrap">
	<table class="game-table">
		<thead>
			<tr>
				<th scope="col" class="col-logo" aria-label="Logo"></th>
				<th scope="col" class="col-side">H/A</th>
				<th scope="col" class="col-name">Team</th>
				<th scope="col" class="col-pct">Win%</th>
				<th scope="col" class="col-status">Status</th>
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
						<td colspan="6"></td>
					</tr>
				{/if}
				{#each teams as { team, side, winPct }, ti}
					{@const state = teamState(team.id)}
					{@const isSelected = selectedTeamId === team.id}
					{@const isUD = winPct !== null && isUnderdog(winPct, underdogThreshold)}
					{@const usedWk = usedWeekFor(team.id)}
					<tr
						class="team-row {state}"
						class:is-selected={isSelected}
						class:is-submitted={isSubmitted && isSelected}
						style:--team-tint={getTeamSurfaceTint(team.id)}
						onclick={() => state !== 'locked' && onSelectTeam?.(game, team.id)}
						role="button"
						tabindex={state === 'locked' ? -1 : 0}
						aria-pressed={isSelected}
						aria-disabled={state === 'locked'}
						onkeydown={(e) => {
							if ((e.key === 'Enter' || e.key === ' ') && state !== 'locked') {
								e.preventDefault();
								onSelectTeam?.(game, team.id);
							}
						}}
					>
						<td class="col-logo">
							<TeamLogo teamCode={team.id} size={32} />
						</td>
						<td class="col-side">
							<span class="side-label">{side}</span>
						</td>
						<td class="col-name">
							<span class="team-name">{displayName(team.id, team.name)}</span>
						</td>
						<td class="col-pct">
							<span class="win-pct">{formatWinPct(winPct)}</span>
						</td>
						<td class="col-status">
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
						</td>
						{#if ti === 0}
							<td class="col-kickoff" rowspan="2">
								<span class="kickoff-text">{formatGameKickoffTable(game.kickoff_at)}</span>
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
		overflow-x: auto;
	}

	.game-table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.875rem;
	}

	thead th {
		padding: 0.3rem 0.5rem;
		text-align: left;
		font-size: 0.68rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-muted);
		border-bottom: 2px solid var(--border);
		white-space: nowrap;
	}

	.team-row td:not(.col-kickoff) {
		padding: 0.4rem 0.5rem;
		vertical-align: middle;
		background: color-mix(in srgb, var(--team-tint) 14%, var(--surface));
		border: none;
		cursor: pointer;
		transition: background 0.12s ease;
	}

	.team-row td.col-kickoff {
		padding: 0.4rem 0.5rem;
		vertical-align: middle;
		background: var(--surface-2);
		border: none;
		cursor: default;
	}

	.team-row td:first-child {
		border-radius: var(--radius) 0 0 var(--radius);
		padding-left: 0.6rem;
	}

	.team-row td:last-child {
		border-radius: 0 var(--radius) var(--radius) 0;
		padding-right: 0.6rem;
	}

	.team-row.selectable:hover td:not(.col-kickoff),
	.team-row.used-elsewhere:hover td:not(.col-kickoff) {
		background: color-mix(in srgb, var(--team-tint) 26%, var(--surface));
	}

	.team-row.locked td:not(.col-kickoff) {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.team-row.used-elsewhere td:not(.col-kickoff) {
		opacity: 0.8;
	}

	.team-row.is-selected td:not(.col-kickoff),
	.team-row.is-submitted td:not(.col-kickoff) {
		background: color-mix(
			in srgb,
			var(--brand-muted) 55%,
			color-mix(in srgb, var(--team-tint) 18%, var(--surface))
		);
		border-top: 2px solid var(--brand);
		border-bottom: 2px solid var(--brand);
	}

	.team-row.is-selected td:not(.col-kickoff):first-child,
	.team-row.is-submitted td:not(.col-kickoff):first-child {
		border-left: 2px solid var(--brand);
	}

	.team-row.is-selected td.col-status,
	.team-row.is-submitted td.col-status {
		border-right: 2px solid var(--brand);
		border-top-right-radius: var(--radius);
		border-bottom-right-radius: var(--radius);
	}

	:global([data-theme='light']) .team-row.is-selected td:not(.col-kickoff),
	:global([data-theme='light']) .team-row.is-submitted td:not(.col-kickoff) {
		background: color-mix(in srgb, #d4a72c 24%, color-mix(in srgb, var(--team-tint) 14%, var(--surface)));
		border-top-color: #9a7418;
		border-bottom-color: #9a7418;
	}

	:global([data-theme='light']) .team-row.is-selected td:not(.col-kickoff):first-child,
	:global([data-theme='light']) .team-row.is-submitted td:not(.col-kickoff):first-child {
		border-left-color: #9a7418;
	}

	:global([data-theme='light']) .team-row.is-selected td.col-status,
	:global([data-theme='light']) .team-row.is-submitted td.col-status {
		border-right-color: #9a7418;
	}

	.game-divider td {
		padding: 0.3rem 0;
		background: transparent;
		border: none;
	}

	.col-logo {
		width: 2.5rem;
		min-width: 2.5rem;
	}

	.col-side {
		width: 2.5rem;
		white-space: nowrap;
	}

	.col-name {
		min-width: 7rem;
	}

	.col-pct {
		width: 3rem;
		text-align: right;
		white-space: nowrap;
	}

	.col-status {
		min-width: 6rem;
	}

	.col-kickoff {
		width: 7rem;
		text-align: right;
		white-space: nowrap;
		vertical-align: middle;
	}

	.side-label {
		font-size: 0.68rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.07em;
		color: var(--text-muted);
	}

	.team-name {
		font-weight: 600;
		color: var(--text);
	}

	.win-pct {
		font-weight: 700;
		font-variant-numeric: tabular-nums;
		color: var(--text);
	}

	.badges {
		display: flex;
		flex-wrap: wrap;
		gap: 0.3rem;
		align-items: center;
	}

	.badge {
		font-size: 0.6rem;
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

	.kickoff-text {
		font-size: 0.75rem;
		font-weight: 600;
		color: var(--text-muted);
		font-variant-numeric: tabular-nums;
	}
</style>
