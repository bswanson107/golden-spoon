<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import { base } from '$app/paths';
	import {
		createSponsorRotation,
		resolveSponsorLogoUrl,
		type Sponsor
	} from '$lib/sponsors';

	const FIRST_DELAY_MS = 60_000;
	const ROTATE_INTERVAL_MS = 210_000;
	const MAX_IMPRESSIONS = 3;
	const MODAL_CHANCE = 0.22;
	const DISMISS_KEY = 'gs-sponsor-ad-dismissed';

	type AdPresentation = 'banner' | 'modal';
	type ActiveAd = {
		sponsor: Sponsor;
		promo: string;
		presentation: AdPresentation;
	};

	let active = $state<ActiveAd | null>(null);
	let impressionCount = $state(0);

	const rotation = createSponsorRotation();
	let timers: ReturnType<typeof setTimeout>[] = [];
	let destroyed = false;

	function clearTimers() {
		for (const id of timers) clearTimeout(id);
		timers = [];
	}

	function schedule(fn: () => void, ms: number) {
		const id = setTimeout(() => {
			timers = timers.filter((t) => t !== id);
			fn();
		}, ms);
		timers.push(id);
	}

	function wasDismissed(slug: string): boolean {
		try {
			const raw = sessionStorage.getItem(DISMISS_KEY);
			if (!raw) return false;
			const list = JSON.parse(raw) as string[];
			return Array.isArray(list) && list.includes(slug);
		} catch {
			return false;
		}
	}

	function markDismissed(slug: string) {
		try {
			const raw = sessionStorage.getItem(DISMISS_KEY);
			const list: string[] = raw ? (JSON.parse(raw) as string[]) : [];
			const next = Array.isArray(list) ? list : [];
			if (!next.includes(slug)) next.push(slug);
			sessionStorage.setItem(DISMISS_KEY, JSON.stringify(next));
		} catch {
			// sessionStorage unavailable — dismiss still works for this page view
		}
	}

	function pickNextAd(): ActiveAd | null {
		if (impressionCount >= MAX_IMPRESSIONS) return null;
		for (let attempt = 0; attempt < 12; attempt += 1) {
			const { sponsor, promo } = rotation.next();
			if (wasDismissed(sponsor.slug)) continue;
			return {
				sponsor,
				promo,
				presentation: Math.random() < MODAL_CHANCE ? 'modal' : 'banner'
			};
		}
		return null;
	}

	function showNext() {
		if (destroyed || document.hidden) {
			schedule(showNext, 5_000);
			return;
		}
		const next = pickNextAd();
		if (!next) {
			active = null;
			return;
		}
		active = next;
		impressionCount += 1;
	}

	function dismiss() {
		if (active) markDismissed(active.sponsor.slug);
		active = null;
		if (impressionCount < MAX_IMPRESSIONS) {
			schedule(showNext, ROTATE_INTERVAL_MS);
		}
	}

	function onVisibility() {
		// No-op beyond showNext's document.hidden check; keeps timer simple.
	}

	onMount(() => {
		document.addEventListener('visibilitychange', onVisibility);
		schedule(showNext, FIRST_DELAY_MS);
		return () => {
			document.removeEventListener('visibilitychange', onVisibility);
		};
	});

	onDestroy(() => {
		destroyed = true;
		clearTimers();
	});
</script>

{#if active}
	{#if active.presentation === 'modal'}
		<div
			class="sponsor-modal-backdrop"
			role="presentation"
			onclick={dismiss}
			onkeydown={(e) => {
				if (e.key === 'Escape') dismiss();
			}}
		>
			<div
				class="sponsor-modal"
				role="dialog"
				aria-modal="true"
				aria-label={`Sponsored message from ${active.sponsor.name}`}
				onclick={(e) => e.stopPropagation()}
			>
				<button type="button" class="sponsor-dismiss" aria-label="Dismiss" onclick={dismiss}>
					×
				</button>
				<img
					src={resolveSponsorLogoUrl(active.sponsor.slug, base, 256)}
					alt=""
					width="96"
					height="96"
					decoding="async"
				/>
				<p class="sponsor-name">{active.sponsor.name}</p>
				<p class="sponsor-copy">{active.promo}</p>
			</div>
		</div>
	{:else}
		<aside
			class="sponsor-banner"
			role="complementary"
			aria-label={`Sponsored message from ${active.sponsor.name}`}
		>
			<img
				src={resolveSponsorLogoUrl(active.sponsor.slug, base, 256)}
				alt=""
				width="56"
				height="56"
				decoding="async"
			/>
			<div class="sponsor-banner-body">
				<p class="sponsor-name">{active.sponsor.name}</p>
				<p class="sponsor-copy">{active.promo}</p>
			</div>
			<button type="button" class="sponsor-dismiss" aria-label="Dismiss" onclick={dismiss}>
				×
			</button>
		</aside>
	{/if}
{/if}

<style>
	.sponsor-banner {
		position: fixed;
		left: 0.75rem;
		right: 0.75rem;
		bottom: 0.75rem;
		z-index: 40;
		display: flex;
		align-items: flex-start;
		gap: 0.75rem;
		padding: 0.75rem 0.85rem;
		max-width: 28rem;
		margin-inline: auto;
		border-radius: 0.75rem;
		border: 1px solid var(--border);
		background: var(--surface, #fff);
		box-shadow: 0 8px 28px rgba(0, 0, 0, 0.14);
	}

	.sponsor-banner img {
		flex-shrink: 0;
		width: 3.5rem;
		height: 3.5rem;
		object-fit: contain;
	}

	.sponsor-banner-body {
		flex: 1;
		min-width: 0;
	}

	.sponsor-modal-backdrop {
		position: fixed;
		inset: 0;
		z-index: 50;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
		background: rgba(0, 0, 0, 0.45);
	}

	.sponsor-modal {
		position: relative;
		width: min(100%, 22rem);
		padding: 1.25rem 1.25rem 1.35rem;
		border-radius: 0.85rem;
		border: 1px solid var(--border);
		background: var(--surface, #fff);
		text-align: center;
		box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
	}

	.sponsor-modal img {
		display: block;
		width: 6rem;
		height: 6rem;
		margin: 0.25rem auto 0.75rem;
		object-fit: contain;
	}

	.sponsor-name {
		margin: 0 0 0.35rem;
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.03em;
		text-transform: uppercase;
		color: var(--text-muted);
	}

	.sponsor-copy {
		margin: 0;
		font-size: 0.92rem;
		line-height: 1.4;
		color: var(--text);
	}

	.sponsor-dismiss {
		flex-shrink: 0;
		width: 1.75rem;
		height: 1.75rem;
		padding: 0;
		border: none;
		border-radius: 999px;
		background: transparent;
		color: var(--text-muted);
		font-size: 1.25rem;
		line-height: 1;
		cursor: pointer;
	}

	.sponsor-modal .sponsor-dismiss {
		position: absolute;
		top: 0.4rem;
		right: 0.45rem;
	}

	.sponsor-dismiss:hover {
		color: var(--text);
		background: color-mix(in srgb, var(--border) 60%, transparent);
	}
</style>
