<script lang="ts">
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import LeagueRulesContent from '$lib/components/league/LeagueRulesContent.svelte';
	import {
		normalizeUnderdogThreshold,
		parsePickVisibility,
		parseTiebreakerMode
	} from '$lib/leagueRules';
	import { fetchLeague } from '$lib/leagues';

	const auth = useAuth();

	let league = $state<Awaited<ReturnType<typeof fetchLeague>>['league']>(null);
	let loading = $state(true);
	let error = $state<string | null>(null);

	const leagueId = $derived($page.params.id);
	const threshold = $derived(normalizeUnderdogThreshold(league?.underdog_threshold_pct));
	const tiebreakerMode = $derived(parseTiebreakerMode(league?.tiebreaker_mode));
	const pickVisibility = $derived(parsePickVisibility(league?.pick_visibility));

	$effect(() => {
		const user = auth.user;
		const id = leagueId;
		if (auth.loading || !user || !id) return;

		loading = true;
		fetchLeague(id, user.id).then((result) => {
			league = result.league;
			error = result.error ?? (result.league ? null : 'League not found.');
			loading = false;
		});
	});
</script>

<main class="page page-rules">
	<div class="back-nav">
		<a href="{base}/league/{leagueId}" class="btn btn-ghost btn-sm">← Back to league</a>
	</div>

	{#if auth.loading || loading}
		<p class="muted">Loading rules…</p>
	{:else if error || !league}
		<p class="auth-error" role="alert">{error ?? 'League not found.'}</p>
	{:else}
		<h1 class="page-title">League rules</h1>
		<p class="page-subtitle">{league.name} · {league.season_year} season</p>

		<div class="rules-card">
			<LeagueRulesContent {threshold} {tiebreakerMode} {pickVisibility} />
		</div>
	{/if}
</main>

<style>
	.page-rules {
		max-width: 40rem;
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.rules-card {
		margin-top: 1rem;
		padding: 1.1rem 1.25rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
	}
</style>
