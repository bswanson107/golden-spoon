<script lang="ts">
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import type { LeagueWithRole } from '$lib/types/league';

	let {
		leagues,
		currentLeague,
		overviewHref,
		picksHref,
		overviewActive,
		picksActive
	}: {
		leagues: LeagueWithRole[];
		currentLeague: LeagueWithRole | null;
		overviewHref: string;
		picksHref: string;
		overviewActive: boolean;
		picksActive: boolean;
	} = $props();

	let menuOpen = $state(false);
	let menuWrap = $state<HTMLDivElement | null>(null);

	const leagueLabel = $derived(currentLeague?.name ?? 'League');

	function closeMenu() {
		menuOpen = false;
	}

	function toggleMenu() {
		menuOpen = !menuOpen;
	}

	$effect(() => {
		void $page.url.pathname;
		menuOpen = false;
	});

	$effect(() => {
		if (!menuOpen) return;

		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === 'Escape') menuOpen = false;
		};

		const onPointerDown = (event: PointerEvent) => {
			const target = event.target;
			if (!(target instanceof Node) || !menuWrap?.contains(target)) {
				menuOpen = false;
			}
		};

		const timer = window.setTimeout(() => {
			document.addEventListener('pointerdown', onPointerDown);
			window.addEventListener('keydown', onKeyDown);
		}, 0);

		return () => {
			window.clearTimeout(timer);
			document.removeEventListener('pointerdown', onPointerDown);
			window.removeEventListener('keydown', onKeyDown);
		};
	});
</script>

<nav class="league-header-nav" aria-label="League">
	<div class="league-switcher" bind:this={menuWrap}>
		<button
			type="button"
			class="league-name-btn"
			class:open={menuOpen}
			title={leagueLabel}
			aria-label="{leagueLabel}. Switch league"
			aria-expanded={menuOpen}
			aria-haspopup="listbox"
			onclick={toggleMenu}
		>
			<span class="league-name">{leagueLabel}</span>
			<svg class="league-chevron" viewBox="0 0 16 16" aria-hidden="true">
				<path
					fill="none"
					stroke="currentColor"
					stroke-width="1.75"
					stroke-linecap="round"
					stroke-linejoin="round"
					d="M4 6l4 4 4-4"
				/>
			</svg>
		</button>

		{#if menuOpen}
			<ul class="league-menu" role="listbox" aria-label="Your leagues">
				{#each leagues as league (league.id)}
					<li role="option" aria-selected={league.id === currentLeague?.id}>
						<a
							href="{base}/league/{league.id}"
							class="league-menu-link"
							class:is-current={league.id === currentLeague?.id}
							onclick={closeMenu}
						>
							{league.name}
						</a>
					</li>
				{/each}
				<li>
					<a
						href="{base}/leagues"
						class="league-menu-link league-menu-create"
						onclick={closeMenu}
					>
						+ Create/Join New League
					</a>
				</li>
			</ul>
		{/if}
	</div>

	<div class="league-tabs">
		<a
			href={overviewHref}
			class="league-tab"
			class:active={overviewActive}
			aria-current={overviewActive ? 'page' : undefined}
		>
			Overview
		</a>
		<a
			href={picksHref}
			class="league-tab"
			class:active={picksActive}
			aria-current={picksActive ? 'page' : undefined}
		>
			My Picks
		</a>
	</div>
</nav>

<style>
	.league-header-nav {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		align-self: stretch;
		flex: 1 1 auto;
		min-width: 0;
		gap: 0.15rem;
	}

	.league-switcher {
		position: relative;
		display: flex;
		justify-content: center;
		max-width: 100%;
	}

	.league-name-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.3rem;
		max-width: 100%;
		margin: 0;
		padding: 0.15rem 0.35rem;
		border: none;
		border-radius: var(--radius);
		background: transparent;
		color: var(--text);
		font-family: var(--font-body);
		font-size: 0.92rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		cursor: pointer;
	}

	.league-name-btn:hover,
	.league-name-btn.open {
		color: var(--text);
	}

	.league-name-btn:focus-visible {
		outline: 2px solid var(--brand);
		outline-offset: 2px;
	}

	.league-name {
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		max-width: min(18rem, calc(100vw - 11rem));
	}

	.league-chevron {
		width: 0.85rem;
		height: 0.85rem;
		flex-shrink: 0;
		color: var(--text-muted);
	}

	.league-name-btn.open .league-chevron {
		transform: rotate(180deg);
	}

	.league-menu {
		position: absolute;
		top: calc(100% + 0.35rem);
		left: 50%;
		transform: translateX(-50%);
		z-index: 60;
		min-width: max(100%, 12rem);
		max-width: min(18rem, calc(100vw - 1.5rem));
		margin: 0;
		padding: 0.35rem;
		list-style: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow);
		border: 1px solid var(--border);
	}

	.league-menu-link {
		display: block;
		padding: 0.5rem 0.65rem;
		border-radius: calc(var(--radius) - 1px);
		color: var(--text);
		font-size: 0.85rem;
		font-weight: 600;
		text-decoration: none;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.league-menu-link:hover {
		background: color-mix(in srgb, var(--text) 8%, var(--surface));
		color: var(--text);
	}

	.league-menu-link.is-current {
		background: color-mix(in srgb, var(--text) 6%, var(--surface));
	}

	.league-menu-create {
		color: var(--brand);
		font-weight: 700;
	}

	:global([data-theme='light']) .league-menu-create {
		color: color-mix(in srgb, var(--brand) 55%, var(--text));
	}

	.league-menu-create:hover {
		background: color-mix(in srgb, var(--brand) 16%, var(--surface));
		color: var(--brand);
	}

	:global([data-theme='light']) .league-menu-create:hover {
		color: color-mix(in srgb, var(--brand) 45%, var(--text));
	}

	.league-tabs {
		display: flex;
		align-items: stretch;
		justify-content: center;
		gap: 0.15rem;
	}

	.league-tab {
		position: relative;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.2rem 0.7rem 0.45rem;
		color: var(--text-muted);
		font-family: var(--font-body);
		font-size: 0.82rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		text-decoration: none;
	}

	.league-tab:hover {
		color: var(--text);
	}

	.league-tab.active {
		color: var(--text);
		font-weight: 700;
	}

	.league-tab.active::after {
		content: '';
		position: absolute;
		left: 0.35rem;
		right: 0.35rem;
		bottom: 0;
		height: 4px;
		border-radius: 0;
		background: var(--brand);
	}

	@media (max-width: 420px) {
		.league-name {
			max-width: min(12rem, calc(100vw - 9.5rem));
			font-size: 0.85rem;
		}

		.league-tab {
			padding: 0.15rem 0.5rem 0.3rem;
			font-size: 0.76rem;
		}
	}
</style>
