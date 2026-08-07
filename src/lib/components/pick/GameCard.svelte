<script lang="ts">
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import GameKickoffInfo from '$lib/components/pick/GameKickoffInfo.svelte';
	import WinPctBar from '$lib/components/pick/WinPctBar.svelte';
	import { getTeamName, getTeamSurfaceTint } from '$lib/data/nflTeams';
	import { isUnderdog } from '$lib/demo';
	import { qaNow } from '$lib/qaClock.svelte';
	import type { WeekGame } from '$lib/types/game';

	let {
		game,
		selectedTeamId = null,
		isSubmittedPick = false,
		teamUsageByWeek = new Map<string, number>(),
		lockedTeamIds = new Set<string>(),
		activeWeek = 1,
		pickingEnabled = true,
		showResults = false,
		underdogThreshold = 33,
		onSelectTeam
	}: {
		game: WeekGame;
		selectedTeamId?: string | null;
		isSubmittedPick?: boolean;
		teamUsageByWeek?: Map<string, number>;
		/** Teams whose earlier-week pick has already kicked off — not movable. */
		lockedTeamIds?: Set<string>;
		activeWeek?: number;
		pickingEnabled?: boolean;
		showResults?: boolean;
		underdogThreshold?: number;
		onSelectTeam?: (teamId: string) => void;
	} = $props();

	const logoSize = 92;

	type TeamState = 'selected' | 'selectable' | 'locked' | 'used-elsewhere' | 'used-locked';

	const gameKickedOff = $derived(new Date(game.kickoff_at).getTime() <= qaNow());

	function teamState(teamId: string): TeamState {
		if (selectedTeamId === teamId) {
			return pickingEnabled && !gameKickedOff ? 'selectable' : 'selected';
		}
		if (!pickingEnabled || gameKickedOff) return 'locked';
		const usedWeek = teamUsageByWeek.get(teamId);
		if (usedWeek !== undefined && usedWeek !== activeWeek) {
			if (lockedTeamIds.has(teamId)) return 'used-locked';
			return 'used-elsewhere';
		}
		return 'selectable';
	}

	function isDisabled(teamId: string): boolean {
		const state = teamState(teamId);
		// `selected` = current pick but no longer changeable (kickoff passed / week closed)
		return state === 'locked' || state === 'used-locked' || state === 'selected';
	}

	function teamTitle(teamId: string): string | undefined {
		const usedWeek = teamUsageByWeek.get(teamId);
		if (usedWeek === undefined) return undefined;
		if (lockedTeamIds.has(teamId) && usedWeek !== activeWeek) {
			return `Locked — picked Week ${usedWeek}`;
		}
		return `Already selected — Week ${usedWeek}`;
	}

	function displayName(teamId: string, fallbackName: string): string {
		const fromCatalog = getTeamName(teamId);
		return fromCatalog !== teamId ? fromCatalog : fallbackName;
	}

	function handleSelect(teamId: string) {
		if (isDisabled(teamId)) return;
		onSelectTeam?.(teamId);
	}

	function pickBadge(teamId: string): 'current' | 'other' | null {
		if (selectedTeamId === teamId) return 'current';
		if (teamUsageByWeek.has(teamId)) return 'other';
		return null;
	}

	function pickBadgeOtherWeek(teamId: string): number | undefined {
		return teamUsageByWeek.get(teamId);
	}

	function yourPickTooltip(): string {
		return `This is your Week ${activeWeek} pick. You can change it until kickoff.`;
	}

	const underdawgTooltip =
		'Successfully picking an underdawg team awards an additional point.';

	function usedWeekTooltip(teamAbbr: string, usedWeek: number): string {
		return `You already picked ${teamAbbr} in Week ${usedWeek}. Moving your pick to Week ${activeWeek} will remove your previous selection.`;
	}

	function scoreLine(): string | null {
		if (!showResults || game.status !== 'final') return null;
		if (game.home_score === null || game.away_score === null) return null;
		return `${displayName(game.away.id, game.away.name)} ${game.away_score} – ${game.home_score} ${displayName(game.home.id, game.home.name)}`;
	}

	const resultLine = $derived(scoreLine());
</script>

<article class="game-card" class:has-result={resultLine !== null}>
	<GameKickoffInfo kickoffAt={game.kickoff_at} layout="inline" />

	{#if resultLine}
		<p class="final-score">{resultLine}</p>
	{/if}

	<div class="matchup">
		<button
			type="button"
			class="team-side away {teamState(game.away.id)}"
			class:is-picked={selectedTeamId === game.away.id}
			class:is-submitted-pick={isSubmittedPick && selectedTeamId === game.away.id}
			data-team-id={game.away.id}
			style:--team-tint={getTeamSurfaceTint(game.away.id)}
			disabled={isDisabled(game.away.id)}
			title={teamTitle(game.away.id)}
			onclick={() => handleSelect(game.away.id)}
		>
			<span class="side-label">Away</span>
			<div class="logo-wrap">
				<TeamLogo teamCode={game.away.id} size={logoSize} />
			</div>
			<span class="team-name">{displayName(game.away.id, game.away.name)}</span>
			<div class="badges">
				{#if pickBadge(game.away.id) === 'current'}
					<span
						class="pick-marker pick-marker-current"
						data-tooltip={yourPickTooltip()}
						title={yourPickTooltip()}
						tabindex="0"
					>Your pick</span>
				{:else if pickBadge(game.away.id) === 'other'}
					{@const usedWk = pickBadgeOtherWeek(game.away.id)!}
					<span
						class="pick-marker pick-marker-other"
						data-tooltip={usedWeekTooltip(game.away.abbreviation, usedWk)}
						title={usedWeekTooltip(game.away.abbreviation, usedWk)}
						tabindex="0"
					>Picked WK {usedWk}</span>
				{/if}
				{#if game.away_win_pct !== null && isUnderdog(game.away_win_pct, underdogThreshold)}
					<span
						class="underdawg-badge"
						data-tooltip={underdawgTooltip}
						title={underdawgTooltip}
						tabindex="0"
					>Underdawg · 2 pts</span>
				{/if}
			</div>
		</button>

		<button
			type="button"
			class="team-side home {teamState(game.home.id)}"
			class:is-picked={selectedTeamId === game.home.id}
			class:is-submitted-pick={isSubmittedPick && selectedTeamId === game.home.id}
			data-team-id={game.home.id}
			style:--team-tint={getTeamSurfaceTint(game.home.id)}
			disabled={isDisabled(game.home.id)}
			title={teamTitle(game.home.id)}
			onclick={() => handleSelect(game.home.id)}
		>
			<span class="side-label">Home</span>
			<div class="logo-wrap">
				<TeamLogo teamCode={game.home.id} size={logoSize} />
			</div>
			<span class="team-name">{displayName(game.home.id, game.home.name)}</span>
			<div class="badges">
				{#if pickBadge(game.home.id) === 'current'}
					<span
						class="pick-marker pick-marker-current"
						data-tooltip={yourPickTooltip()}
						title={yourPickTooltip()}
						tabindex="0"
					>Your pick</span>
				{:else if pickBadge(game.home.id) === 'other'}
					{@const usedWk = pickBadgeOtherWeek(game.home.id)!}
					<span
						class="pick-marker pick-marker-other"
						data-tooltip={usedWeekTooltip(game.home.abbreviation, usedWk)}
						title={usedWeekTooltip(game.home.abbreviation, usedWk)}
						tabindex="0"
					>Picked WK {usedWk}</span>
				{/if}
				{#if game.home_win_pct !== null && isUnderdog(game.home_win_pct, underdogThreshold)}
					<span
						class="underdawg-badge"
						data-tooltip={underdawgTooltip}
						title={underdawgTooltip}
						tabindex="0"
					>Underdawg · 2 pts</span>
				{/if}
			</div>
		</button>
	</div>

	<WinPctBar
		awayTeamCode={game.away.id}
		homeTeamCode={game.home.id}
		awayTeamName={game.away.name}
		homeTeamName={game.home.name}
		awayWinPct={game.away_win_pct}
		homeWinPct={game.home_win_pct}
		pickedTeamCode={selectedTeamId}
	/>
</article>

<style>
	.game-card {
		display: flex;
		flex-direction: column;
		gap: 0.85rem;
		padding: 1rem 1rem 1.1rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.final-score {
		margin: 0;
		font-size: 0.75rem;
		font-weight: 600;
		color: var(--text-muted);
		text-align: center;
	}

	.matchup {
		display: grid;
		grid-template-columns: 1fr 1fr;
		align-items: stretch;
		gap: 0.65rem;
	}

	.team-side {
		position: relative;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: flex-start;
		gap: 0.55rem;
		min-height: 11.5rem;
		padding: 0.85rem 0.75rem 0.9rem;
		border: none;
		border-radius: var(--radius);
		background: color-mix(in srgb, var(--team-tint, var(--text-muted)) 20%, var(--surface));
		box-shadow: var(--shadow-sm);
		color: var(--text);
		text-align: center;
		cursor: pointer;
		transition:
			background 0.15s ease,
			box-shadow 0.15s ease,
			transform 0.08s ease;
	}

	.team-side.selectable:hover,
	.team-side.used-elsewhere:hover {
		background: color-mix(in srgb, var(--team-tint, var(--text-muted)) 30%, var(--surface));
	}

	.team-side.is-picked,
	.team-side.selected {
		background: color-mix(
			in srgb,
			var(--brand-muted) 50%,
			color-mix(in srgb, var(--team-tint, var(--text-muted)) 25%, var(--surface))
		);
		box-shadow: var(--shadow);
	}

	.team-side.is-submitted-pick {
		border: 2px solid var(--brand);
		box-shadow: var(--shadow);
	}

	:global([data-theme='light']) .team-side.is-submitted-pick {
		border: 3px solid #9a7418;
		background: color-mix(
			in srgb,
			#d4a72c 32%,
			color-mix(in srgb, var(--team-tint, var(--text-muted)) 18%, var(--surface))
		);
		box-shadow: var(--shadow-lg);
	}

	.team-side.used-elsewhere {
		border: 2px dotted var(--text-muted);
		opacity: 0.92;
	}

	.team-side.used-locked,
	.team-side.locked {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.side-label {
		font-size: 0.68rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--text-muted);
	}

	.logo-wrap {
		display: flex;
		align-items: center;
		justify-content: center;
		flex: 0 0 auto;
		width: 100%;
		height: 5.75rem;
		padding: 0.15rem 0;
	}

	.team-name {
		font-size: 0.88rem;
		font-weight: 700;
		line-height: 1.25;
		color: var(--text);
		max-width: 100%;
	}

	.badges {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: center;
		gap: 0.35rem;
		min-height: 1.1rem;
		margin-top: auto;
		width: 100%;
	}

	.underdawg-badge {
		position: relative;
		font-size: 0.65rem;
		font-weight: 700;
		color: var(--brand-text);
		padding: 0.1rem 0.35rem;
		border-radius: var(--radius);
		background: var(--brand);
		box-shadow: var(--shadow-sm);
		cursor: help;
	}

	.pick-marker {
		position: relative;
		font-size: 0.58rem;
		font-weight: 800;
		padding: 0.15rem 0.4rem;
		border-radius: var(--radius);
		box-shadow: var(--shadow-sm);
		text-transform: uppercase;
		letter-spacing: 0.04em;
		line-height: 1.2;
		cursor: help;
	}

	.pick-marker::after,
	.underdawg-badge::after {
		content: attr(data-tooltip);
		position: absolute;
		left: 50%;
		bottom: calc(100% + 0.4rem);
		transform: translateX(-50%) translateY(0.15rem);
		padding: 0.35rem 0.55rem;
		border-radius: var(--radius);
		background: var(--text);
		color: var(--surface);
		font-size: 0.72rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		text-transform: none;
		white-space: normal;
		width: max-content;
		max-width: min(16rem, calc(100vw - 2rem));
		box-shadow: var(--shadow);
		opacity: 0;
		pointer-events: none;
		transition:
			opacity 0.12s ease,
			transform 0.12s ease;
		z-index: 300;
		text-align: left;
		line-height: 1.35;
	}

	.pick-marker:hover::after,
	.pick-marker:focus-visible::after,
	.underdawg-badge:hover::after,
	.underdawg-badge:focus-visible::after {
		opacity: 1;
		transform: translateX(-50%) translateY(0);
	}

	.pick-marker:focus-visible,
	.underdawg-badge:focus-visible {
		outline: 2px solid var(--brand);
		outline-offset: 2px;
	}

	.pick-marker-current {
		color: var(--win-text);
		background: var(--win-bg);
	}

	.pick-marker-other {
		color: #ffffff;
		background: var(--tie-bg);
	}

	:global([data-theme='dark']) .pick-marker-other {
		background: #3b82f6;
	}
</style>
