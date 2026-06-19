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
	import { getTheme, initTheme, toggleTheme } from '$lib/themeStore.svelte';
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

	onMount(() => {
		initTheme();
		initSeasonIndicator();
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
	<header class="header chrome-bar">
		<a href="{base}/" class="brand">Golden Spoon</a>

		<div class="header-actions">
			{#if seasonTooltip}
				<button type="button" class="season-indicator-wrap" aria-label={seasonLabel}>
					<span class="season-indicator" aria-hidden="true">{seasonLabel}</span>
					<span class="season-tooltip" role="tooltip">{seasonTooltip}</span>
				</button>
			{:else}
				<p class="season-indicator">{seasonLabel}</p>
			{/if}
			<button
				type="button"
				class="icon-btn theme-toggle"
				aria-label={getTheme() === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
				onclick={toggleTheme}
			>
				{#if getTheme() === 'dark'}
					<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">
						<circle cx="12" cy="12" r="4.5" fill="none" stroke="currentColor" stroke-width="1.75" />
						<path
							fill="none"
							stroke="currentColor"
							stroke-width="1.75"
							stroke-linecap="round"
							d="M12 2.5v2.25M12 19.25V21.5M4.5 12H2.25M21.75 12H19.5M5.4 5.4l1.6 1.6M17 17l1.6 1.6M18.6 5.4 17 7M7 17l-1.6 1.6"
						/>
					</svg>
				{:else}
					<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">
						<path
							fill="none"
							stroke="currentColor"
							stroke-width="1.75"
							stroke-linecap="round"
							stroke-linejoin="round"
							d="M20 14.5A7.5 7.5 0 0 1 9.5 4 6.5 6.5 0 1 0 20 14.5Z"
						/>
					</svg>
				{/if}
			</button>

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
							<ul class="menu-list">
								<li>
									<a href="{base}/leagues" class="menu-link" onclick={closeMenu}>Leagues</a>
								</li>
								<li>
									<a href="{base}/account" class="menu-link" onclick={closeMenu}>Account</a>
								</li>
								<li>
									<a href="{base}/design" class="menu-link" onclick={closeMenu}>Design demo</a>
								</li>
								{#if showAdminToggle}
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
							<ul class="menu-list">
								<li>
									<a href="{base}/login" class="menu-link" onclick={closeMenu}>Sign in</a>
								</li>
								<li>
									<a href="{base}/signup" class="menu-link menu-link-primary" onclick={closeMenu}
										>Sign up</a
									>
								</li>
								<li>
									<a href="{base}/design" class="menu-link" onclick={closeMenu}>Design demo</a>
								</li>
							</ul>
						{/if}
					</nav>
				{/if}
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
		--app-header-height: 3.25rem;
	}

	.header {
		position: sticky;
		top: 0;
		z-index: 50;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		min-height: var(--app-header-height);
		padding: 0.75rem 1rem;
	}

	.brand {
		font-family: var(--font-display);
		font-weight: 700;
		color: var(--brand);
		text-decoration: none;
		letter-spacing: -0.02em;
	}

	.header-actions {
		display: flex;
		align-items: center;
		gap: 0.45rem;
	}

	.season-indicator {
		margin: 0;
		margin-right: 0.35rem;
		font-size: 0.85rem;
		font-weight: 700;
		color: var(--text);
		letter-spacing: 0.01em;
		white-space: nowrap;
	}

	.season-indicator-wrap {
		position: relative;
		display: inline-flex;
		margin: 0;
		margin-right: 0.35rem;
		padding: 0;
		border: none;
		background: none;
		font: inherit;
		cursor: help;
		outline: none;
	}

	.season-indicator-wrap .season-indicator {
		margin-right: 0;
	}

	.season-indicator-wrap:focus-visible .season-indicator {
		border-radius: 0.2rem;
		outline: 2px solid var(--brand);
		outline-offset: 2px;
	}

	.season-tooltip {
		position: absolute;
		top: calc(100% + 0.45rem);
		right: 0;
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
		text-align: right;
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

	.brand:hover {
		color: var(--brand);
		filter: brightness(1.05);
	}

	:global([data-theme='light']) .brand {
		color: var(--text);
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
</style>
