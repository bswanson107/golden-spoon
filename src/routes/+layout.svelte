<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { setContext } from 'svelte';
	import { afterNavigate } from '$app/navigation';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import type { Session } from '@supabase/supabase-js';
	import spoonFavicon from '$lib/assets/spoonFavicon.png';
	import { AUTH_CONTEXT_KEY, ADMIN_CONTEXT_KEY, type AuthStore, type AdminStore } from '$lib/auth';
	import { getSupabase } from '$lib/supabase';
	import { isAppAdmin, loadAdminMode, saveAdminMode } from '$lib/admin';
	import QaBanner from '$lib/components/QaBanner.svelte';
	import { hydrateQaClock } from '$lib/qaClock.svelte';
	import { getTheme, initTheme, setTheme } from '$lib/themeStore.svelte';
	import { fetchMyLeagues } from '$lib/leagues';
	import {
		getSeasonIndicatorLabel,
		getSeasonIndicatorTooltip,
		initSeasonIndicator,
		setLiveSeasonIndicator
	} from '$lib/seasonIndicatorStore.svelte';

	let { children } = $props();

	let session = $state<Session | null>(null);
	let loading = $state(true);
	let signingOut = $state(false);
	let adminModeEnabled = $state(false);
	let menuOpen = $state(false);
	let menuWrap = $state<HTMLDivElement | null>(null);
	/** Fallback league when not already on a league route (most recently joined). */
	let primaryLeagueId = $state<string | null>(null);

	const auth: AuthStore = {
		get session() {
			return session;
		},
		get user() {
			return session?.user ?? null;
		},
		get loading() {
			return loading;
		}
	};

	const admin: AdminStore = {
		get adminModeEnabled() {
			return adminModeEnabled;
		},
		setAdminMode(enabled: boolean) {
			adminModeEnabled = enabled;
			saveAdminMode(enabled);
		}
	};

	setContext(AUTH_CONTEXT_KEY, auth);
	setContext(ADMIN_CONTEXT_KEY, admin);

	const showAdminToggle = $derived(
		!auth.loading && auth.user !== null && isAppAdmin(auth.user.email)
	);

	const publicRoutes = new Set(['/', '/login', '/signup', '/design']);

	const seasonLabel = $derived(getSeasonIndicatorLabel());
	const seasonTooltip = $derived(getSeasonIndicatorTooltip());

	const routeLeagueId = $derived.by(() => {
		const routeId = $page.route.id ?? '';
		const id = $page.params.id;
		if (routeId.startsWith('/league/[id]') && id) return id;
		return null;
	});

	const navLeagueId = $derived(routeLeagueId ?? primaryLeagueId);

	const standingsHref = $derived(
		navLeagueId ? `${base}/league/${navLeagueId}` : `${base}/leagues`
	);
	const pickHref = $derived(
		navLeagueId ? `${base}/league/${navLeagueId}/pick` : `${base}/leagues`
	);

	const standingsActive = $derived(($page.route.id ?? '') === '/league/[id]');
	const pickActive = $derived(($page.route.id ?? '') === '/league/[id]/pick');

	const theme = $derived(getTheme());

	onMount(() => {
		initTheme();
		initSeasonIndicator();
		hydrateQaClock().then(() => initSeasonIndicator());
		adminModeEnabled = loadAdminMode();

		const supabase = getSupabase();

		supabase.auth.getSession().then(({ data: { session: initialSession } }) => {
			session = initialSession;
			loading = false;
		});

		const {
			data: { subscription }
		} = supabase.auth.onAuthStateChange((_event, nextSession) => {
			session = nextSession;
			loading = false;
		});

		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === 'Escape') menuOpen = false;
		};

		window.addEventListener('keydown', onKeyDown);

		return () => {
			subscription.unsubscribe();
			window.removeEventListener('keydown', onKeyDown);
		};
	});

	$effect(() => {
		const user = auth.user;
		if (auth.loading || !user) {
			primaryLeagueId = null;
			return;
		}

		fetchMyLeagues(user.id).then((result) => {
			primaryLeagueId = result.leagues[0]?.id ?? null;
		});
	});

	afterNavigate(({ to }) => {
		const routeId = to?.route.id ?? '';
		if (!routeId.startsWith('/league/[id]')) {
			setLiveSeasonIndicator(2026);
		}
	});

	$effect(() => {
		if (loading) return;

		const routeId = $page.route.id;
		const isPublic = routeId !== null && publicRoutes.has(routeId);

		if (!auth.user && !isPublic) {
			goto(`${base}/login`);
		}
	});

	function closeMenu() {
		menuOpen = false;
	}

	function toggleMenu() {
		menuOpen = !menuOpen;
	}

	$effect(() => {
		if (!menuOpen) return;

		const onPointerDown = (event: PointerEvent) => {
			const target = event.target;
			if (!(target instanceof Node) || !menuWrap?.contains(target)) {
				menuOpen = false;
			}
		};

		const timer = window.setTimeout(() => {
			document.addEventListener('pointerdown', onPointerDown);
		}, 0);

		return () => {
			window.clearTimeout(timer);
			document.removeEventListener('pointerdown', onPointerDown);
		};
	});

	async function signOut() {
		closeMenu();
		signingOut = true;
		await getSupabase().auth.signOut();
		signingOut = false;
		goto(`${base}/`);
	}
</script>

<svelte:head>
	<link rel="icon" href={spoonFavicon} type="image/png" />
</svelte:head>

<div class="app">
	<QaBanner />
	<header class="header chrome-bar">
		<div class="header-inner">
		<div class="brand-block">
			<a href="{base}/" class="brand">
				<span class="brand-line">Golden</span>
				<span class="brand-line">Spoon</span>
			</a>
			{#if seasonTooltip}
				<button type="button" class="season-indicator-wrap" aria-label={seasonLabel}>
					<span class="season-indicator" aria-hidden="true">{seasonLabel}</span>
					<span class="season-tooltip" role="tooltip">{seasonTooltip}</span>
				</button>
			{:else}
				<p class="season-indicator">{seasonLabel}</p>
			{/if}
		</div>

		{#if auth.user}
			<nav class="header-nav" aria-label="Primary">
				<a
					href={standingsHref}
					class="nav-text"
					class:active={standingsActive}
					aria-current={standingsActive ? 'page' : undefined}
				>
					League
				</a>
				<a
					href={pickHref}
					class="nav-text"
					class:active={pickActive}
					aria-current={pickActive ? 'page' : undefined}
				>
					My Picks
				</a>
			</nav>
		{/if}

		<div class="header-actions">
			<div class="menu-wrap" bind:this={menuWrap}>
				<button
					type="button"
					class="icon-btn menu-trigger"
					aria-label="Open menu"
					aria-expanded={menuOpen}
					aria-haspopup="true"
					onclick={toggleMenu}
				>
					<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">
						<path
							fill="none"
							stroke="currentColor"
							stroke-width="1.75"
							stroke-linecap="round"
							d="M4 7h16M4 12h16M4 17h16"
						/>
					</svg>
				</button>

				{#if menuOpen}
					<nav class="menu-panel" aria-label="Site menu">
						{#if auth.loading}
							<p class="menu-muted">Loading…</p>
						{:else if auth.user}
							<p class="menu-user">{auth.user.email}</p>
							<div class="theme-toggle" role="group" aria-label="Color theme">
								<div class="theme-track" class:is-dark={theme === 'dark'}>
									<span class="theme-thumb" aria-hidden="true"></span>
									<button
										type="button"
										class="theme-option"
										class:active={theme === 'light'}
										aria-label="Light mode"
										aria-pressed={theme === 'light'}
										onclick={() => setTheme('light')}
									>
										<svg class="theme-icon" viewBox="0 0 24 24" aria-hidden="true">
											<circle
												cx="12"
												cy="12"
												r="4.5"
												fill="none"
												stroke="currentColor"
												stroke-width="1.75"
											/>
											<path
												fill="none"
												stroke="currentColor"
												stroke-width="1.75"
												stroke-linecap="round"
												d="M12 2.5v2.25M12 19.25V21.5M4.5 12H2.25M21.75 12H19.5M5.4 5.4l1.6 1.6M17 17l1.6 1.6M18.6 5.4 17 7M7 17l-1.6 1.6"
											/>
										</svg>
									</button>
									<button
										type="button"
										class="theme-option"
										class:active={theme === 'dark'}
										aria-label="Dark mode"
										aria-pressed={theme === 'dark'}
										onclick={() => setTheme('dark')}
									>
										<svg class="theme-icon" viewBox="0 0 24 24" aria-hidden="true">
											<path
												fill="none"
												stroke="currentColor"
												stroke-width="1.75"
												stroke-linecap="round"
												stroke-linejoin="round"
												d="M20 14.5A7.5 7.5 0 0 1 9.5 4 6.5 6.5 0 1 0 20 14.5Z"
											/>
										</svg>
									</button>
								</div>
							</div>
							<ul class="menu-list">
								<li>
									<a href="{base}/leagues" class="menu-link" onclick={closeMenu}>Leagues</a>
								</li>
								<li>
									<a href="{base}/account" class="menu-link" onclick={closeMenu}>Account</a>
								</li>
								{#if showAdminToggle}
									<li>
										<a href="{base}/qa" class="menu-link" onclick={closeMenu}>QA Mode</a>
									</li>
									<li class="menu-admin">
										<label class="admin-toggle">
											<input
												type="checkbox"
												checked={adminModeEnabled}
												onchange={(e) =>
													admin.setAdminMode((e.currentTarget as HTMLInputElement).checked)}
											/>
											<span>Admin mode</span>
										</label>
									</li>
								{/if}
								<li>
									<button
										type="button"
										class="menu-link menu-button-item"
										disabled={signingOut}
										onclick={signOut}
									>
										{signingOut ? 'Signing out…' : 'Sign out'}
									</button>
								</li>
							</ul>
						{:else}
							<div class="theme-toggle" role="group" aria-label="Color theme">
								<div class="theme-track" class:is-dark={theme === 'dark'}>
									<span class="theme-thumb" aria-hidden="true"></span>
									<button
										type="button"
										class="theme-option"
										class:active={theme === 'light'}
										aria-label="Light mode"
										aria-pressed={theme === 'light'}
										onclick={() => setTheme('light')}
									>
										<svg class="theme-icon" viewBox="0 0 24 24" aria-hidden="true">
											<circle
												cx="12"
												cy="12"
												r="4.5"
												fill="none"
												stroke="currentColor"
												stroke-width="1.75"
											/>
											<path
												fill="none"
												stroke="currentColor"
												stroke-width="1.75"
												stroke-linecap="round"
												d="M12 2.5v2.25M12 19.25V21.5M4.5 12H2.25M21.75 12H19.5M5.4 5.4l1.6 1.6M17 17l1.6 1.6M18.6 5.4 17 7M7 17l-1.6 1.6"
											/>
										</svg>
									</button>
									<button
										type="button"
										class="theme-option"
										class:active={theme === 'dark'}
										aria-label="Dark mode"
										aria-pressed={theme === 'dark'}
										onclick={() => setTheme('dark')}
									>
										<svg class="theme-icon" viewBox="0 0 24 24" aria-hidden="true">
											<path
												fill="none"
												stroke="currentColor"
												stroke-width="1.75"
												stroke-linecap="round"
												stroke-linejoin="round"
												d="M20 14.5A7.5 7.5 0 0 1 9.5 4 6.5 6.5 0 1 0 20 14.5Z"
											/>
										</svg>
									</button>
								</div>
							</div>
							<ul class="menu-list">
								<li>
									<a href="{base}/login" class="menu-link" onclick={closeMenu}>Sign in</a>
								</li>
								<li>
									<a href="{base}/signup" class="menu-link menu-link-primary" onclick={closeMenu}
										>Sign up</a
									>
								</li>
							</ul>
						{/if}
					</nav>
				{/if}
			</div>
		</div>
		</div>
	</header>

	<div class="content">
		{@render children()}
	</div>
</div>

<style>
	.app {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
		--app-header-height: 3.75rem;
	}

	.header {
		position: sticky;
		top: 0;
		z-index: 50;
		width: 100%;
	}

	.header-inner {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		width: 100%;
		max-width: var(--app-content-max, 50rem);
		min-height: var(--app-header-height);
		margin: 0 auto;
		padding: 0.55rem var(--app-content-gutter, 1rem);
		box-sizing: border-box;
	}

	.brand-block {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: 0.12rem;
		min-width: 0;
	}

	.brand {
		display: flex;
		flex-direction: column;
		font-family: var(--font-display);
		font-size: 0.95rem;
		font-weight: 700;
		line-height: 1.05;
		color: var(--brand);
		text-decoration: none;
		letter-spacing: -0.02em;
	}

	.brand-line {
		display: block;
	}

	.brand:hover {
		color: var(--brand);
		filter: brightness(1.05);
	}

	:global([data-theme='light']) .brand {
		color: var(--text);
	}

	.season-indicator {
		margin: 0;
		font-size: 0.72rem;
		font-weight: 700;
		color: var(--text);
		letter-spacing: 0.02em;
		white-space: nowrap;
		line-height: 1.2;
	}

	.season-indicator-wrap {
		position: relative;
		display: inline-flex;
		margin: 0;
		padding: 0;
		border: none;
		background: none;
		font: inherit;
		cursor: help;
		outline: none;
	}

	.season-indicator-wrap:focus-visible .season-indicator {
		border-radius: 0.2rem;
		outline: 2px solid var(--brand);
		outline-offset: 2px;
	}

	.season-tooltip {
		position: absolute;
		top: calc(100% + 0.45rem);
		left: 0;
		z-index: 60;
		width: max-content;
		max-width: min(16rem, calc(100vw - 2rem));
		padding: 0.45rem 0.6rem;
		border-radius: 0.35rem;
		background: var(--text);
		color: var(--bg);
		font-size: 0.75rem;
		font-weight: 500;
		line-height: 1.35;
		text-align: left;
		white-space: normal;
		pointer-events: none;
		opacity: 0;
		visibility: hidden;
		transition:
			opacity 0.12s ease,
			visibility 0.12s ease;
	}

	.season-indicator-wrap:hover .season-tooltip,
	.season-indicator-wrap:focus-visible .season-tooltip {
		opacity: 1;
		visibility: visible;
	}

	.header-nav {
		position: absolute;
		left: 50%;
		transform: translateX(-50%);
		display: flex;
		align-items: center;
		gap: 0.85rem;
	}

	.nav-text {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.4rem 0.85rem;
		border: none;
		border-radius: var(--radius);
		background: transparent;
		color: var(--text-muted);
		font-family: var(--font-body);
		font-size: 0.88rem;
		font-weight: 600;
		text-decoration: none;
		letter-spacing: 0.01em;
		transition:
			color 0.15s ease,
			background 0.15s ease;
	}

	.nav-text:hover {
		color: var(--text);
	}

	.nav-text.active {
		color: var(--brand-text);
		background: color-mix(in srgb, var(--brand) 55%, transparent);
	}

	:global([data-theme='light']) .nav-text.active {
		color: var(--text);
		background: color-mix(in srgb, var(--brand) 45%, transparent);
	}

	.header-actions {
		display: flex;
		align-items: center;
		gap: 0.45rem;
	}

	.icon-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.25rem;
		height: 2.25rem;
		padding: 0;
		border: none;
		border-radius: var(--radius);
		background: var(--surface-2);
		color: var(--text-muted);
		box-shadow: var(--shadow-sm);
		cursor: pointer;
		transition:
			color 0.15s ease,
			transform 0.08s ease,
			box-shadow 0.08s ease;
	}

	.icon-btn:hover {
		color: var(--text);
	}

	.icon-btn:active {
		transform: translate(1px, 1px);
		box-shadow: var(--shadow-press);
	}

	.icon {
		width: 1.15rem;
		height: 1.15rem;
	}

	.menu-wrap {
		position: relative;
	}

	.menu-panel {
		position: absolute;
		top: calc(100% + 0.45rem);
		right: 0;
		z-index: 70;
		min-width: 12.5rem;
		padding: 0.65rem;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.menu-user {
		margin: 0 0 0.5rem;
		padding: 0.35rem 0.55rem 0.55rem;
		border-bottom: 1px solid var(--border);
		font-size: 0.78rem;
		color: var(--text-muted);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.menu-muted {
		margin: 0;
		padding: 0.35rem 0.55rem;
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.theme-toggle {
		margin: 0 0 0.55rem;
		padding: 0 0.15rem;
	}

	.theme-track {
		position: relative;
		display: grid;
		grid-template-columns: 1fr 1fr;
		padding: 0.2rem;
		border-radius: 999px;
		background: color-mix(in srgb, var(--text-muted) 14%, var(--surface-2));
		box-shadow: inset 0 1px 2px color-mix(in srgb, var(--text) 8%, transparent);
	}

	.theme-thumb {
		position: absolute;
		top: 0.2rem;
		bottom: 0.2rem;
		left: 0.2rem;
		width: calc(50% - 0.2rem);
		border-radius: 999px;
		background: var(--surface);
		box-shadow:
			0 1px 2px color-mix(in srgb, var(--text) 12%, transparent),
			0 1px 4px color-mix(in srgb, var(--text) 8%, transparent);
		transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
		pointer-events: none;
	}

	.theme-track.is-dark .theme-thumb {
		transform: translateX(100%);
	}

	.theme-option {
		position: relative;
		z-index: 1;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.4rem 0.55rem;
		border: none;
		background: transparent;
		color: var(--text-muted);
		cursor: pointer;
		transition: color 0.2s ease;
	}

	.theme-option.active {
		color: var(--text);
	}

	.theme-option:not(.active):hover {
		color: var(--text);
	}

	.theme-icon {
		width: 1.05rem;
		height: 1.05rem;
	}

	.menu-list {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
	}

	.menu-link {
		display: block;
		width: 100%;
		padding: 0.55rem 0.65rem;
		border: none;
		border-radius: var(--radius);
		background: transparent;
		color: var(--text);
		font-size: 0.9rem;
		font-weight: 500;
		font-family: var(--font-body);
		text-align: left;
		text-decoration: none;
		cursor: pointer;
		transition: background 0.12s ease;
	}

	.menu-link:hover {
		background: color-mix(in srgb, var(--text) 6%, var(--surface));
	}

	.menu-link-primary {
		background: var(--brand);
		color: var(--brand-text);
		font-weight: 600;
		box-shadow: var(--shadow-sm);
	}

	.menu-link-primary:hover {
		background: var(--brand);
		filter: brightness(1.05);
	}

	.menu-button-item:disabled {
		opacity: 0.55;
		cursor: not-allowed;
	}

	.menu-admin {
		padding: 0.15rem 0.65rem;
	}

	.admin-toggle {
		display: flex;
		align-items: center;
		gap: 0.45rem;
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--text-muted);
		cursor: pointer;
		user-select: none;
	}

	.admin-toggle input {
		width: 0.9rem;
		height: 0.9rem;
		accent-color: var(--danger);
	}

	.admin-toggle:has(input:checked) {
		color: var(--danger);
	}

	.content {
		flex: 1;
	}

	@media (max-width: 420px) {
		.header-nav {
			gap: 0.45rem;
		}

		.nav-text {
			padding: 0.35rem 0.65rem;
			font-size: 0.82rem;
		}

		.season-indicator {
			font-size: 0.68rem;
		}
	}
</style>
