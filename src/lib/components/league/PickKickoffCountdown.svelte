<script lang="ts">
	import { formatPickDeadline } from '$lib/gameKickoff';

	let { kickoffAt }: { kickoffAt: string } = $props();

	const kickoffLabel = $derived(formatPickDeadline(kickoffAt));
</script>

<p class="next-kickoff">
	The next game kicks off at <span class="kickoff-time">{kickoffLabel}</span>
</p>

<style>
	.next-kickoff {
		margin: 0;
		font-size: 0.95rem;
		color: var(--text-muted);
		max-width: 36rem;
	}

	.kickoff-time {
		font-weight: 600;
		font-variant-numeric: tabular-nums;
		color: var(--text);
	}
</style>
