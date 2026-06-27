<script lang="ts">
	import { base } from '$app/paths';
	import { isQaClockEnabled, qaSimulatedNowMs } from '$lib/qaClock.svelte';

	const enabled = $derived(isQaClockEnabled());
	const simulatedMs = $derived(qaSimulatedNowMs());

	const label = $derived.by(() => {
		if (simulatedMs === null) return null;
		return new Date(simulatedMs).toLocaleString(undefined, {
			weekday: 'short',
			month: 'short',
			day: 'numeric',
			hour: 'numeric',
			minute: '2-digit',
			timeZoneName: 'short'
		});
	});
</script>

{#if enabled}
	<div class="qa-banner" role="status">
		<span class="qa-dot" aria-hidden="true"></span>
		<span class="qa-text">
			QA Mode — simulated time:{' '}
			<strong>{label ?? 'unset'}</strong>
		</span>
		<a class="qa-link" href="{base}/qa">Open QA panel</a>
	</div>
{/if}

<style>
	.qa-banner {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		padding: 0.4rem 1rem;
		background: var(--danger, #b91c1c);
		color: #fff;
		font-size: 0.8rem;
		font-weight: 600;
	}

	.qa-dot {
		width: 0.55rem;
		height: 0.55rem;
		border-radius: 50%;
		background: #fff;
		box-shadow: 0 0 0 0.18rem rgba(255, 255, 255, 0.3);
		flex-shrink: 0;
	}

	.qa-text {
		flex: 1;
	}

	.qa-link {
		color: #fff;
		text-decoration: underline;
		white-space: nowrap;
	}
</style>
