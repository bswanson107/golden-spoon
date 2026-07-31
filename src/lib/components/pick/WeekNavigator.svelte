<script lang="ts">
	import {
		clampSimulatedWeek,
		MAX_SIMULATED_WEEK,
		MIN_SIMULATED_WEEK,
		simulatedWeekLabel
	} from '$lib/demo';

	let {
		viewWeek,
		onWeekChange,
		label = 'View week',
		compact = false,
		showReset = false,
		canReset = false,
		onReset
	}: {
		viewWeek: number;
		onWeekChange: (week: number) => void;
		label?: string;
		compact?: boolean;
		showReset?: boolean;
		canReset?: boolean;
		onReset?: () => void;
	} = $props();

	const weekOptions = Array.from(
		{ length: MAX_SIMULATED_WEEK - MIN_SIMULATED_WEEK + 1 },
		(_, i) => MIN_SIMULATED_WEEK + i
	);
	const canStepBack = $derived(viewWeek > MIN_SIMULATED_WEEK);
	const canStepForward = $derived(viewWeek < MAX_SIMULATED_WEEK);

	function stepWeek(delta: number) {
		onWeekChange(clampSimulatedWeek(viewWeek + delta));
	}
</script>

<section class="week-nav" class:compact>
	<div class="week-select">
		<span class="week-select-label">{label}</span>
		<div class="week-controls">
			<button
				type="button"
				class="week-step"
				disabled={!canStepBack}
				aria-label="Previous week"
				onclick={() => stepWeek(-1)}
			>
				←
			</button>
			<select
				value={viewWeek}
				onchange={(e) => onWeekChange(Number((e.currentTarget as HTMLSelectElement).value))}
			>
				{#each weekOptions as week (week)}
					<option value={week}>{simulatedWeekLabel(week)}</option>
				{/each}
			</select>
			<button
				type="button"
				class="week-step"
				disabled={!canStepForward}
				aria-label="Next week"
				onclick={() => stepWeek(1)}
			>
				→
			</button>
		</div>
	</div>

	{#if showReset && onReset}
		<button type="button" class="reset-btn" disabled={!canReset} onclick={onReset}>
			Reset demo picks
		</button>
	{/if}
</section>

<style>
	.week-nav {
		padding: 1rem 1.1rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
	}

	.week-select {
		display: flex;
		flex-direction: column;
		gap: 0.35rem;
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.week-select-label {
		font-size: 0.85rem;
	}

	.week-controls {
		display: flex;
		align-items: center;
		gap: 0.45rem;
	}

	.week-controls select {
		flex: 1;
		min-width: 0;
		height: 2.25rem;
		padding: 0 0.5rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface-2);
		color: var(--text);
		font-size: 0.85rem;
		font-weight: 600;
		font-family: var(--font-body);
		line-height: 1;
		box-shadow: var(--shadow-sm);
		cursor: pointer;
	}

	.week-step {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.25rem;
		height: 2.25rem;
		padding: 0;
		border: none;
		border-radius: var(--radius);
		background: var(--surface-2);
		color: var(--text);
		font-size: 1rem;
		line-height: 1;
		cursor: pointer;
		flex-shrink: 0;
		box-shadow: var(--shadow-sm);
	}

	.week-step:hover:not(:disabled) {
		border-color: var(--link);
		color: var(--link);
	}

	.week-step:disabled {
		opacity: 0.35;
		cursor: not-allowed;
	}

	.reset-btn {
		margin-top: 0.85rem;
		padding: 0.5rem 0.75rem;
		border: none;
		border-radius: var(--radius);
		background: color-mix(in srgb, var(--danger) 12%, var(--surface));
		color: var(--danger);
		font-size: 0.85rem;
		font-weight: 600;
		font-family: var(--font-body);
		cursor: pointer;
		box-shadow: var(--shadow-sm);
		transition: background 0.15s;
	}

	.reset-btn:hover:not(:disabled) {
		background: color-mix(in srgb, var(--danger) 20%, var(--surface));
	}

	.reset-btn:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.week-nav.compact {
		padding: 0;
		border: none;
		border-radius: 0;
		background: transparent;
		box-shadow: none;
		min-width: 0;
	}

	.week-nav.compact .week-select {
		flex-direction: row;
		align-items: center;
		justify-content: space-between;
		gap: 0.5rem;
		min-width: 0;
	}

	.week-nav.compact .week-select-label {
		flex-shrink: 0;
		font-size: 0.78rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.week-nav.compact .week-controls {
		min-width: 0;
	}

	.week-nav.compact .week-controls select {
		height: 2rem;
		padding: 0 0.35rem;
		font-size: 0.8rem;
		max-width: 100%;
		min-width: 0;
	}

	.week-nav.compact .week-step {
		width: 2rem;
		height: 2rem;
		font-size: 0.95rem;
	}

	.week-nav.compact .reset-btn {
		margin-top: 0.55rem;
		padding: 0.4rem 0.65rem;
		font-size: 0.78rem;
	}
</style>
