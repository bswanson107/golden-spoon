<script lang="ts">
	/**
	 * Mounts SponsorAd only after the page is idle / interactive.
	 * Keeps the ad chunk and logo bytes off the league route's critical path.
	 */
	import { onDestroy, onMount } from 'svelte';
	import type { Component } from 'svelte';

	let SponsorAd = $state<Component | null>(null);
	let cancelled = false;

	onMount(() => {
		const load = () => {
			if (cancelled) return;
			void import('$lib/components/league/SponsorAd.svelte').then((mod) => {
				if (!cancelled) SponsorAd = mod.default;
			});
		};

		if (typeof requestIdleCallback === 'function') {
			const idleId = requestIdleCallback(load, { timeout: 4_000 });
			return () => {
				cancelled = true;
				cancelIdleCallback(idleId);
			};
		}

		const timeoutId = setTimeout(load, 2_000);
		return () => {
			cancelled = true;
			clearTimeout(timeoutId);
		};
	});

	onDestroy(() => {
		cancelled = true;
	});
</script>

{#if SponsorAd}
	<SponsorAd />
{/if}
