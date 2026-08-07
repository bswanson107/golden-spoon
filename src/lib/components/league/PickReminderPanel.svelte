<script lang="ts">
	import { getMissingPickers, hasWeekClosed } from '$lib/leaguePickStatus';
	import type { WeekGame } from '$lib/types/game';
	import type { LeaguePick, StandingRow } from '$lib/types/standings';

	let {
		weekNumber,
		standings,
		picks,
		games
	}: {
		weekNumber: number;
		standings: StandingRow[];
		picks: LeaguePick[];
		games: WeekGame[];
	} = $props();

	let copied = $state(false);

	const missing = $derived(getMissingPickers(standings, picks, weekNumber));
	const weekClosed = $derived(hasWeekClosed(games));

	async function copyNames() {
		const text = missing.map((m) => m.display_name).join('\n');
		try {
			await navigator.clipboard.writeText(text);
			copied = true;
			setTimeout(() => {
				copied = false;
			}, 2000);
		} catch {
			// ignore
		}
	}
</script>

{#if !weekClosed}
	<section class="reminder-panel">
		<h3 class="reminder-title">
			Week {weekNumber} — {missing.length} player{missing.length === 1 ? '' : 's'} haven't picked
			yet
		</h3>
		{#if missing.length === 0}
			<p class="muted">Everyone has submitted a pick for this week.</p>
		{:else}
			<ul class="reminder-list">
				{#each missing as member (member.user_id)}
					<li>{member.display_name}</li>
				{/each}
			</ul>
			<button type="button" class="btn btn-ghost btn-sm" onclick={copyNames}>
				{copied ? 'Copied!' : 'Copy names'}
			</button>
		{/if}
	</section>
{/if}

<style>
	.reminder-panel {
		margin-top: 0.85rem;
		padding-top: 0.85rem;
		border-top: 1px solid var(--border);
	}

	.reminder-title {
		margin: 0 0 0.5rem;
		font-size: 0.95rem;
		color: var(--text);
	}

	.muted {
		margin: 0;
		font-size: 0.9rem;
		color: var(--text-muted);
	}

	.reminder-list {
		margin: 0 0 0.65rem;
		padding-left: 1.25rem;
		font-size: 0.9rem;
	}

	.reminder-list li {
		margin: 0.2rem 0;
	}
</style>
