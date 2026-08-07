<script lang="ts">
	import { base } from '$app/paths';
	import CommissionerModal from '$lib/components/league/CommissionerModal.svelte';
	import LeagueRulesModal from '$lib/components/league/LeagueRulesModal.svelte';
	import { fetchWeekGames } from '$lib/games';
	import { updateLeagueInviteCode } from '$lib/leagues';
	import {
		normalizeUnderdogThreshold,
		parsePickVisibility,
		parseTiebreakerMode
	} from '$lib/leagueRules';
	import { isDemoSeason } from '$lib/season';
	import { fetchLeaguePicks, fetchLeagueStandings } from '$lib/standings';
	import type { WeekGame } from '$lib/types/game';
	import type { LeagueWithRole } from '$lib/types/league';
	import type { LeaguePick, StandingRow } from '$lib/types/standings';

	let {
		league = $bindable(),
		weekNumber,
		standings: standingsProp = undefined,
		picks: picksProp = undefined,
		games: gamesProp = undefined
	}: {
		league: LeagueWithRole;
		weekNumber: number;
		standings?: StandingRow[];
		picks?: LeaguePick[];
		games?: WeekGame[];
	} = $props();

	let rulesOpen = $state(false);
	let commissionerOpen = $state(false);
	let copied = $state(false);
	let editingInvite = $state(false);
	let inviteDraft = $state('');
	let inviteSaving = $state(false);
	let inviteError = $state<string | null>(null);

	let fetchedStandings = $state<StandingRow[]>([]);
	let fetchedPicks = $state<LeaguePick[]>([]);
	let fetchedGames = $state<WeekGame[]>([]);
	let fetchToken = $state(0);

	const isDemo = $derived(isDemoSeason(league.season_year));
	const rulesThreshold = $derived(normalizeUnderdogThreshold(league.underdog_threshold_pct));
	const rulesTiebreakerMode = $derived(parseTiebreakerMode(league.tiebreaker_mode));
	const rulesPickVisibility = $derived(parsePickVisibility(league.pick_visibility));

	const standings = $derived(standingsProp ?? fetchedStandings);
	const picks = $derived(picksProp ?? fetchedPicks);
	const games = $derived(gamesProp ?? fetchedGames);

	$effect(() => {
		if (!commissionerOpen || !league.is_commissioner) return;
		if (standingsProp !== undefined && picksProp !== undefined && gamesProp !== undefined) return;

		const token = ++fetchToken;
		const id = league.id;
		const week = weekNumber;
		const seasonYear = league.season_year;

		void (async () => {
			const [standingsResult, picksResult, gamesResult] = await Promise.all([
				standingsProp === undefined ? fetchLeagueStandings(id) : Promise.resolve(null),
				picksProp === undefined ? fetchLeaguePicks(id) : Promise.resolve(null),
				gamesProp === undefined ? fetchWeekGames(seasonYear, week) : Promise.resolve(null)
			]);
			if (token !== fetchToken) return;
			if (standingsResult && !standingsResult.error) {
				fetchedStandings = standingsResult.standings;
			}
			if (picksResult && !picksResult.error) {
				fetchedPicks = picksResult.picks;
			}
			if (gamesResult && !gamesResult.error) {
				fetchedGames = gamesResult.games;
			}
		})();
	});

	async function copyInviteCode() {
		try {
			await navigator.clipboard.writeText(league.invite_code);
			copied = true;
			setTimeout(() => {
				copied = false;
			}, 2000);
		} catch {
			// fallback: user can select manually
		}
	}

	function startEditInvite() {
		inviteDraft = league.invite_code;
		inviteError = null;
		editingInvite = true;
	}

	function cancelEditInvite() {
		editingInvite = false;
		inviteError = null;
		inviteDraft = '';
	}

	async function saveInviteCode() {
		inviteError = null;
		inviteSaving = true;
		const { inviteCode, error: saveError } = await updateLeagueInviteCode(league.id, inviteDraft);
		inviteSaving = false;
		if (saveError || !inviteCode) {
			inviteError = saveError ?? 'Could not update invite code.';
			return;
		}
		league = { ...league, invite_code: inviteCode };
		editingInvite = false;
		inviteDraft = '';
	}
</script>

<footer class="league-footer">
	{#if league.is_commissioner}
		<button type="button" class="btn btn-ghost btn-sm" onclick={() => (commissionerOpen = true)}>
			Commissioner
		</button>
	{/if}
	<button type="button" class="btn btn-ghost btn-sm" onclick={() => (rulesOpen = true)}>
		Rules
	</button>
	<a href="{base}/leagues" class="btn btn-ghost btn-sm">Other leagues</a>
</footer>

<LeagueRulesModal
	open={rulesOpen}
	leagueName={league.name}
	seasonYear={league.season_year}
	threshold={rulesThreshold}
	tiebreakerMode={rulesTiebreakerMode}
	pickVisibility={rulesPickVisibility}
	onClose={() => (rulesOpen = false)}
/>

{#if league.is_commissioner}
	<CommissionerModal
		open={commissionerOpen}
		leagueId={league.id}
		inviteCode={league.invite_code}
		{isDemo}
		{weekNumber}
		{standings}
		{picks}
		{games}
		{editingInvite}
		bind:inviteDraft
		{inviteSaving}
		{inviteError}
		{copied}
		onClose={() => (commissionerOpen = false)}
		onCopyInvite={copyInviteCode}
		onStartEditInvite={startEditInvite}
		onCancelEditInvite={cancelEditInvite}
		onSaveInvite={saveInviteCode}
	/>
{/if}

<style>
	.league-footer {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 0.75rem;
		margin-top: 2rem;
		padding-top: 1.25rem;
		border-top: 1px solid var(--border);
	}
</style>
