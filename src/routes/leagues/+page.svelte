<script lang="ts">
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import { fetchMyLeagues } from '$lib/leagues';
	import { isDemoSeason } from '$lib/season';
	import type { LeagueWithRole } from '$lib/types/league';

	const auth = useAuth();

	let leagues = $state<LeagueWithRole[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);

	function isDemoLeague(league: LeagueWithRole): boolean {
		return league.is_public_demo || isDemoSeason(league.season_year);
	}

	const publicDemoLeagues = $derived(leagues.filter((league) => league.is_public_demo));
	const memberLeagues = $derived(leagues.filter((league) => !league.is_public_demo));

	$effect(() => {
		const user = auth.user;
		if (auth.loading) return;

		if (!user) {
			loading = false;
			return;
		}

		loading = true;
		fetchMyLeagues(user.id).then((result) => {
			leagues = result.leagues;
			error = result.error;
			loading = false;
		});
	});
</script>

<main class="page page-wide">
	<div class="page-header">
		<div>
			<h1 class="page-title">My leagues</h1>
			<p class="page-subtitle">Create a pool, join with an invite code, or try the demo.</p>
		</div>
	</div>

	<div class="actions">
		<a href="{base}/leagues/create" class="btn btn-primary">Create league</a>
		<a href="{base}/leagues/join" class="btn btn-ghost">Join league</a>
	</div>

	{#if auth.loading || loading}
		<p class="muted">Loading leagues…</p>
	{:else if error}
		<p class="auth-error" role="alert">{error}</p>
	{:else}
		{#if publicDemoLeagues.length > 0}
			<ul class="league-list demo-list">
				{#each publicDemoLeagues as league (league.id)}
					<li class="demo-league-block">
						<section class="alert alert-info demo-league-note" role="status">
							<strong>Demo league</strong>
							— Open this pool to preview what a live league looks like, including standings and
							weekly picks from a previous season.
						</section>
						<a href="{base}/league/{league.id}" class="league-card demo-league-card">
							<div class="league-card-main">
								<span class="league-name">{league.name}</span>
								<span class="league-meta">{league.season_year} season</span>
							</div>
							<div class="league-badges">
								<span class="badge badge-demo">Demo</span>
								{#if league.is_commissioner}
									<span class="badge">Commissioner</span>
								{/if}
							</div>
						</a>
					</li>
				{/each}
			</ul>
		{/if}

		{#if memberLeagues.length === 0}
			<div class="empty-card">
				<p>No leagues yet.</p>
				<p class="muted">Create one for the family or ask for an invite code.</p>
			</div>
		{:else}
			<ul class="league-list">
				{#each memberLeagues as league (league.id)}
					<li>
						<a href="{base}/league/{league.id}" class="league-card">
							<div class="league-card-main">
								<span class="league-name">{league.name}</span>
								<span class="league-meta">{league.season_year} season</span>
							</div>
							<div class="league-badges">
								{#if isDemoLeague(league)}
									<span class="badge badge-demo">Demo</span>
								{/if}
								{#if league.is_commissioner}
									<span class="badge">Commissioner</span>
								{/if}
							</div>
						</a>
					</li>
				{/each}
			</ul>
		{/if}
	{/if}
</main>

<style>
	.page-header {
		margin-bottom: 0.5rem;
	}

	.page-header .page-subtitle {
		margin-bottom: 0;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.75rem;
		margin: 1.25rem 0 1.5rem;
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.empty-card {
		padding: 1.25rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
	}

	.empty-card p {
		margin: 0 0 0.35rem;
	}

	.league-list {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.demo-list {
		margin-bottom: 0.75rem;
	}

	.demo-league-block {
		display: flex;
		flex-direction: column;
		border-radius: var(--radius);
		box-shadow: var(--shadow-sm);
		overflow: hidden;
	}

	.demo-league-note {
		margin: 0;
		border-radius: 0;
		box-shadow: none;
	}

	.demo-league-card {
		border-radius: 0;
		box-shadow: none;
		border-top: 1px solid color-mix(in srgb, var(--link) 22%, var(--border));
	}

	.demo-league-block:hover .demo-league-card {
		box-shadow: none;
		background: color-mix(in srgb, var(--link) 6%, var(--surface));
	}

	.league-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 1rem 1.1rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
		text-decoration: none;
		color: inherit;
		transition:
			transform 0.08s ease,
			box-shadow 0.08s ease,
			background 0.08s ease;
	}

	.league-card:hover {
		box-shadow: var(--shadow);
	}

	.league-card-main {
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
		min-width: 0;
	}

	.league-name {
		font-weight: 600;
		color: var(--text);
	}

	.league-meta {
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.league-badges {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: flex-end;
		gap: 0.4rem;
		flex-shrink: 0;
	}

	.badge {
		font-size: 0.75rem;
		font-weight: 600;
		padding: 0.25rem 0.5rem;
		border-radius: var(--radius);
		background: var(--brand-muted);
		color: var(--brand);
		white-space: nowrap;
		box-shadow: var(--shadow-sm);
	}

	.badge-demo {
		background: color-mix(in srgb, var(--link) 18%, var(--surface));
		color: var(--link);
	}

	:global([data-theme='light']) .badge {
		color: var(--text);
	}

	:global([data-theme='light']) .badge-demo {
		color: var(--link);
	}
</style>
