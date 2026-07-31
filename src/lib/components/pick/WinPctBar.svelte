<script lang="ts">
	import { formatWinPct } from '$lib/demo';
	import { getTeamName, getTeamTileGradient } from '$lib/data/nflTeams';

	let {
		awayTeamCode,
		homeTeamCode,
		awayTeamName,
		homeTeamName,
		awayWinPct = null,
		homeWinPct = null,
		pickedTeamCode = null
	}: {
		awayTeamCode: string;
		homeTeamCode: string;
		awayTeamName?: string;
		homeTeamName?: string;
		awayWinPct?: number | null;
		homeWinPct?: number | null;
		pickedTeamCode?: string | null;
	} = $props();

	const split = $derived.by(() => {
		const away = awayWinPct ?? 50;
		const home = homeWinPct ?? 50;
		const total = away + home;
		return {
			away: total > 0 ? (away / total) * 100 : 50,
			home: total > 0 ? (home / total) * 100 : 50
		};
	});

	const awayGradient = $derived(getTeamTileGradient(awayTeamCode));
	const homeGradient = $derived(getTeamTileGradient(homeTeamCode));
	const awayPicked = $derived(pickedTeamCode === awayTeamCode);
	const homePicked = $derived(pickedTeamCode === homeTeamCode);
	const hasPick = $derived(awayPicked || homePicked);

	function teamLabel(code: string, override?: string): string {
		const full = override?.trim() || getTeamName(code);
		if (!full || full === code) return code;
		const parts = full.split(' ');
		return parts[parts.length - 1] ?? full;
	}

	const awayLabel = $derived(teamLabel(awayTeamCode, awayTeamName));
	const homeLabel = $derived(teamLabel(homeTeamCode, homeTeamName));
</script>

<div class="win-pct">
	<div class="win-pct-values" aria-hidden="true">
		<span class="team-pct away-pct">{awayLabel} - {formatWinPct(awayWinPct)}</span>
		<span class="team-pct home-pct">{formatWinPct(homeWinPct)} - {homeLabel}</span>
	</div>

	<div class="win-pct-track-shell">
		<div class="win-pct-track" class:has-pick={hasPick} aria-hidden="true">
			<div
				class="segment away"
				class:picked={awayPicked}
				class:jets-light={awayTeamCode === 'NYJ'}
				style:flex-grow={split.away}
				style:background={awayGradient}
			></div>
			{#if !hasPick}
				<div class="divider"></div>
			{/if}
			<div
				class="segment home"
				class:picked={homePicked}
				class:jets-light={homeTeamCode === 'NYJ'}
				style:flex-grow={split.home}
				style:background={homeGradient}
			></div>
		</div>
	</div>

	<p class="win-pct-label">Win %</p>
</div>

<style>
	.win-pct {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.win-pct-label {
		margin: 0.1rem 0 0;
		font-size: 0.72rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-muted);
		text-align: center;
	}

	.win-pct-values {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		gap: 0.5rem;
		min-height: 1.15rem;
	}

	.team-pct {
		font-size: 0.88rem;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
		color: var(--text);
		line-height: 1.25;
		white-space: nowrap;
	}

	.away-pct {
		text-align: left;
	}

	.home-pct {
		text-align: right;
	}

	.win-pct-track-shell {
		position: relative;
		padding: 0.2rem 0;
		overflow: visible;
	}

	.win-pct-track {
		display: flex;
		align-items: stretch;
		height: 1.1rem;
		border: 1px solid var(--border);
		border-radius: 999px;
		background: var(--bg);
		box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.18);
		overflow: visible;
	}

	.segment {
		flex: 1 1 0;
		min-width: 0;
		height: 100%;
		transition: flex-grow 0.2s ease;
	}

	.segment.away {
		border-radius: 999px 0 0 999px;
	}

	.segment.home {
		border-radius: 0 999px 999px 0;
	}

	.win-pct-track.has-pick .segment.picked {
		height: 1.75rem;
		align-self: center;
		z-index: 1;
	}

	.divider {
		flex-shrink: 0;
		width: 4px;
		align-self: center;
		height: calc(1.1rem + 0.5rem);
		margin-block: -0.25rem;
		background: var(--shadow-color);
		z-index: 2;
	}

	:global([data-theme='light']) .segment.jets-light {
		box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.18);
	}
</style>
