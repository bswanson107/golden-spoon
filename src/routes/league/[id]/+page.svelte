<script lang="ts">
	import { afterNavigate } from '$app/navigation';
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { useAdmin, useAuth } from '$lib/auth';
	import { isAppAdmin } from '$lib/admin';
	import DemoBanner from '$lib/components/pick/DemoBanner.svelte';
	import WeekNavigator from '$lib/components/pick/WeekNavigator.svelte';
	import PickReminderPanel from '$lib/components/league/PickReminderPanel.svelte';
	import PickDashboard from '$lib/components/league/PickDashboard.svelte';
	import LeagueRulesModal from '$lib/components/league/LeagueRulesModal.svelte';
	import StandingsTable from '$lib/components/league/StandingsTable.svelte';
	import PicksGrid from '$lib/components/league/PicksGrid.svelte';
	import {
		getMaxVisibleWeek,
		hasDemoPicks,
		loadDemoState,
		mergeDemoLeagueView,
		resetDemoPicks,
		saveDemoState,
		simulatedWeekLabel
	} from '$lib/demo';
	import { fetchWeekGames } from '$lib/games';
	import { getPickCtaState, getWeekFirstKickoff } from '$lib/leaguePickStatus';
	import { adminKickLeagueMember, fetchLeague, fetchMyLeagues } from '$lib/leagues';
	import {
		normalizeUnderdogThreshold,
		parsePickVisibility,
		parseTiebreakerMode
	} from '$lib/leagueRules';
	import { fetchLeaguePicks, fetchLeaguePickSubmissions, fetchLeagueStandings, type PickSubmissionsByCell } from '$lib/standings';
	import { getCurrentWeekFromDate, isDemoSeason } from '$lib/season';
	import { syncSeasonIndicatorForLeague } from '$lib/seasonIndicatorStore.svelte';
	import type { DemoState } from '$lib/types/demo';
	import type { WeekGame } from '$lib/types/game';
	import type { LeagueWithRole } from '$lib/types/league';
	import type { LeaguePick, StandingRow } from '$lib/types/standings';

	const auth = useAuth();
	const admin = useAdmin();

	let league = $state<LeagueWithRole | null>(null);
	let standings = $state<StandingRow[]>([]);
	let picks = $state<LeaguePick[]>([]);
	let pickSubmissions = $state<PickSubmissionsByCell>({});
	let demoState = $state<DemoState>({ enabled: false, simulatedWeek: 1, picks: {} });
	let demoGamesByWeek = $state<Map<number, WeekGame[]>>(new Map());
	let liveWeekGames = $state<WeekGame[]>([]);
	let viewWeek = $state(1);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let copied = $state(false);
	let kickingUserId = $state<string | null>(null);
	let kickError = $state<string | null>(null);
	let leagueCount = $state<number | null>(null);
	let rulesOpen = $state(false);

	const leagueId = $derived($page.params.id);

	const adminKickEnabled = $derived(
		isAppAdmin(auth.user?.email) && admin.adminModeEnabled
	);

	const isDemo = $derived(league !== null && isDemoSeason(league.season_year));

	const playerDisplayName = $derived.by(() => {
		const user = auth.user;
		if (!user) return 'You';
		const fromStandings = standings.find((row) => row.user_id === user.id)?.display_name;
		if (fromStandings) return fromStandings;
		const meta = user.user_metadata?.display_name;
		if (typeof meta === 'string' && meta.trim()) return meta.trim();
		return user.email?.split('@')[0] ?? 'You';
	});

	const leagueView = $derived.by(() => {
		const user = auth.user;
		if (!user) {
			return { picks, standings, maxVisibleWeek: 18 as number | null, demoActive: false };
		}

		if (!demoState.enabled) {
			return { picks, standings, maxVisibleWeek: null, demoActive: false };
		}

		if (!isDemoSeason(league?.season_year ?? 0)) {
			return { picks, standings, maxVisibleWeek: null, demoActive: false };
		}

		return {
			...mergeDemoLeagueView(
				picks,
				standings,
				demoState,
				demoGamesByWeek,
				user.id,
				playerDisplayName,
				league?.tiebreaker_mode ?? 'fewest_wins'
			),
			demoActive: true
		};
	});

	const userCurrentWeekPick = $derived.by(() => {
		const user = auth.user;
		if (!user || isDemo) return undefined;
		return picks.find(
			(p) => p.user_id === user.id && p.week_number === viewWeek && !p.is_missed
		);
	});

	const pickCta = $derived.by(() => {
		if (isDemo || !league) return { kind: 'hidden' as const };
		return getPickCtaState(viewWeek, liveWeekGames, userCurrentWeekPick);
	});

	const demoDashboardPick = $derived.by((): LeaguePick | null => {
		const user = auth.user;
		if (!isDemo || !user) return null;

		const demoPick = demoState.picks[demoState.simulatedWeek];
		if (!demoPick) return null;

		const games = demoGamesByWeek.get(demoState.simulatedWeek) ?? [];
		const game = games.find((g) => g.id === demoPick.game_id) ?? null;

		return {
			id: 'demo',
			user_id: user.id,
			display_name: playerDisplayName,
			week_number: demoState.simulatedWeek,
			team_id: demoPick.team_id,
			team_abbreviation: demoPick.team_abbreviation,
			team_name: demoPick.team_name,
			win_pct_at_pick: demoPick.win_pct_at_pick,
			is_underdog_at_pick: demoPick.is_underdog_at_pick,
			outcome: 'pending',
			points_awarded: 0,
			game_id: demoPick.game_id,
			kickoff_at: game?.kickoff_at ?? '',
			is_missed: false,
			is_commissioner_override: false
		};
	});

	const demoPickCta = $derived.by(() => {
		if (!isDemo) return { kind: 'hidden' as const };

		const week = demoState.simulatedWeek;
		const games = demoGamesByWeek.get(week) ?? [];

		if (demoState.picks[week]) {
			return {
				kind: 'submitted' as const,
				week,
				changeable: true,
				teamAbbreviation: demoState.picks[week].team_abbreviation
			};
		}

		const firstKickoff = getWeekFirstKickoff(games);
		return {
			kind: 'needs_pick' as const,
			week,
			deadlineLabel: firstKickoff ?? new Date().toISOString()
		};
	});

	const dashboardPick = $derived(isDemo ? demoDashboardPick : (userCurrentWeekPick ?? null));

	const dashboardCta = $derived(isDemo ? demoPickCta : pickCta);

	const dashboardWeek = $derived(isDemo ? demoState.simulatedWeek : viewWeek);

	const dashboardGame = $derived.by(() => {
		const pick = dashboardPick;
		if (!pick) return null;

		if (isDemo) {
			return (demoGamesByWeek.get(demoState.simulatedWeek) ?? []).find((g) => g.id === pick.game_id) ?? null;
		}

		return liveWeekGames.find((g) => g.id === pick.game_id) ?? null;
	});

	const showMyLeaguesBack = $derived(leagueCount !== null && leagueCount > 1);

	$effect(() => {
		const leagueData = league;
		if (!leagueData) return;

		if (isDemo) {
			syncSeasonIndicatorForLeague(leagueData.season_year, demoState.simulatedWeek);
		} else {
			syncSeasonIndicatorForLeague(leagueData.season_year);
		}
	});

	const rulesThreshold = $derived(normalizeUnderdogThreshold(league?.underdog_threshold_pct));
	const rulesTiebreakerMode = $derived(parseTiebreakerMode(league?.tiebreaker_mode));
	const rulesPickVisibility = $derived(parsePickVisibility(league?.pick_visibility));

	function refreshDemoState() {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id || !league) return;
		demoState = loadDemoState(id, user.id, league.season_year);
	}

	function persistDemoState(next: DemoState) {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id) return;
		demoState = next;
		saveDemoState(id, user.id, next);
	}

	function handleDemoWeekChange(simulatedWeek: number) {
		if (!isDemo) return;
		persistDemoState({ ...demoState, simulatedWeek });
	}

	function handleResetDemo() {
		persistDemoState(resetDemoPicks(demoState));
	}

	async function reloadLeagueData() {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id) return;

		const [standingsResult, picksResult] = await Promise.all([
			fetchLeagueStandings(id),
			fetchLeaguePicks(id)
		]);
		const submissionsResult = await fetchLeaguePickSubmissions(id);

		if (standingsResult.error) {
			error = standingsResult.error;
			standings = [];
		} else {
			standings = standingsResult.standings;
		}

		if (picksResult.error && !error) {
			error = picksResult.error;
			picks = [];
		} else if (!picksResult.error) {
			picks = picksResult.picks;
		}

		if (!submissionsResult.error) {
			pickSubmissions = submissionsResult.byCell;
		}
	}

	async function handleKickPlayer(userId: string, displayName: string) {
		const id = leagueId;
		if (!id || !adminKickEnabled) return;

		const confirmed = confirm(`Remove ${displayName} from this league?`);
		if (!confirmed) return;

		kickError = null;
		kickingUserId = userId;

		const result = await adminKickLeagueMember(id, userId);
		kickingUserId = null;

		if (result.error) {
			kickError = result.error;
			return;
		}

		standings = standings.filter((row) => row.user_id !== userId);
		picks = picks.filter((pick) => pick.user_id !== userId);
		pickSubmissions = Object.fromEntries(
			Object.entries(pickSubmissions).filter(([key]) => !key.startsWith(`${userId.toLowerCase()}:`))
		);

		await reloadLeagueData();
	}

	$effect(() => {
		const user = auth.user;
		const id = leagueId;
		if (auth.loading || !user || !id) return;

		loading = true;
		error = null;

		Promise.all([
			fetchLeague(id, user.id),
			fetchLeagueStandings(id),
			fetchLeaguePicks(id),
			fetchLeaguePickSubmissions(id)
		]).then(([leagueResult, standingsResult, picksResult, submissionsResult]) => {
			if (leagueResult.error || !leagueResult.league) {
				league = null;
				error = leagueResult.error ?? 'League not found.';
				standings = [];
				picks = [];
				pickSubmissions = {};
				demoState = { enabled: false, simulatedWeek: 1, picks: {} };
			} else {
				league = leagueResult.league;
				if (!isDemoSeason(leagueResult.league.season_year)) {
					viewWeek = getCurrentWeekFromDate(
						new Date(),
						leagueResult.league.season_year
					);
				}
				demoState = loadDemoState(id, user.id, leagueResult.league.season_year);
				if (standingsResult.error) {
					error = standingsResult.error;
					standings = [];
				} else {
					standings = standingsResult.standings;
				}
				if (picksResult.error && !error) {
					error = picksResult.error;
					picks = [];
				} else if (!picksResult.error) {
					picks = picksResult.picks;
				}
				if (!submissionsResult.error) {
					pickSubmissions = submissionsResult.byCell;
				} else {
					pickSubmissions = {};
				}
			}
			loading = false;
		});
	});

	$effect(() => {
		const user = auth.user;
		if (auth.loading || !user) return;

		fetchMyLeagues(user.id).then((result) => {
			leagueCount = result.leagues.length;
		});
	});

	$effect(() => {
		const leagueData = league;
		const week = viewWeek;
		if (!leagueData || isDemoSeason(leagueData.season_year)) {
			liveWeekGames = [];
			return;
		}

		fetchWeekGames(leagueData.season_year, week).then((result) => {
			liveWeekGames = result.games;
		});
	});

	$effect(() => {
		const state = demoState;
		const leagueData = league;
		if (!state.enabled || !leagueData) {
			demoGamesByWeek = new Map();
			return;
		}

		const weeks = [
			...new Set([...Object.keys(state.picks).map(Number), state.simulatedWeek])
		];
		if (weeks.length === 0) {
			demoGamesByWeek = new Map();
			return;
		}

		Promise.all(weeks.map((week) => fetchWeekGames(leagueData.season_year, week))).then(
			(results) => {
				const next = new Map<number, WeekGame[]>();
				weeks.forEach((week, index) => {
					next.set(week, results[index]?.games ?? []);
				});
				demoGamesByWeek = next;
			}
		);
	});

	afterNavigate(() => {
		refreshDemoState();
	});

	async function copyInviteCode() {
		if (!league) return;
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
</script>

<main class="page page-league">
	{#if showMyLeaguesBack}
		<div class="back-nav">
			<a href="{base}/leagues" class="btn btn-ghost btn-sm">← My leagues</a>
		</div>
	{/if}

	{#if auth.loading || loading}
		<p class="muted">Loading league…</p>
	{:else if error || !league}
		<p class="auth-error" role="alert">{error ?? 'League not found.'}</p>
	{:else}
		{#if isDemo}
			<DemoBanner />
		{/if}

		<h1 class="page-title">{league.name}</h1>
		<p class="page-subtitle">{league.season_year} season</p>

		{#if isDemo || dashboardCta.kind !== 'hidden'}
			<PickDashboard
				leagueId={league.id}
				week={dashboardWeek}
				pickCta={dashboardCta}
				userPick={dashboardPick}
				game={dashboardGame}
			/>
		{/if}

		{#if isDemo}
			<section class="demo-travel-wrap">
				<WeekNavigator
					viewWeek={demoState.simulatedWeek}
					onWeekChange={handleDemoWeekChange}
					label="Simulated time"
					showReset
					canReset={hasDemoPicks(demoState)}
					onReset={handleResetDemo}
				/>
			</section>
		{/if}

		{#if league.is_commissioner}
			<section class="card commissioner-tools">
				<div class="commissioner-tools-row">
					<div>
						<h2 class="card-title">Commissioner</h2>
						<p class="muted">Override picks, fix scores, and view sync diagnostics.</p>
					</div>
					<a href="{base}/league/{league.id}/admin" class="btn btn-ghost btn-sm">Admin tools</a>
				</div>
				{#if !isDemo}
					<PickReminderPanel
						weekNumber={viewWeek}
						standings={leagueView.standings}
						picks={leagueView.picks}
						games={liveWeekGames}
					/>
				{/if}
			</section>

			<section class="card">
				<h2 class="card-title">Invite family</h2>
				<p class="muted">Share this code so others can join.</p>
				<div class="invite-row">
					<code class="invite-code">{league.invite_code}</code>
					<button type="button" class="btn btn-ghost btn-sm" onclick={copyInviteCode}>
						{copied ? 'Copied!' : 'Copy'}
					</button>
				</div>
			</section>
		{/if}

		<section class="card">
			<h2 class="card-title">Standings</h2>
			{#if leagueView.demoActive}
				{@const visibleThrough = getMaxVisibleWeek(demoState.simulatedWeek)}
				<p class="muted demo-view-note">
					Viewing through {simulatedWeekLabel(demoState.simulatedWeek)}
					{#if visibleThrough > 0}
						(weeks 1–{visibleThrough} only)
					{:else}
						(no completed weeks yet)
					{/if}
				</p>
			{:else}
				<p class="muted">Ranked by total points. TB = sum of picked teams' season wins (lower is better).</p>
			{/if}
			{#if kickError}
				<p class="auth-error" role="alert">{kickError}</p>
			{/if}
			{#if leagueView.standings.length === 0}
				<p class="muted">No standings yet.</p>
			{:else}
				<StandingsTable
					standings={leagueView.standings}
					currentUserId={auth.user?.id ?? null}
					tiebreakerMode={rulesTiebreakerMode}
					adminKickEnabled={adminKickEnabled}
					commissionerId={league.commissioner_id}
					{kickingUserId}
					onKickPlayer={handleKickPlayer}
				/>
			{/if}
		</section>

		<section class="card">
			<h2 class="card-title">Weekly picks</h2>
			<p class="muted">
				Green = win, gray = loss, amber = tie.
				{#if isDemo}
					Gold badge "2" = underdawg win.
				{/if}
			</p>
			{#if leagueView.picks.length === 0 && Object.keys(pickSubmissions).length === 0}
				<p class="muted">No picks yet.</p>
			{:else}
				<PicksGrid
					picks={leagueView.picks}
					standings={leagueView.standings}
					currentUserId={auth.user?.id ?? null}
					viewWeek={null}
					{pickSubmissions}
					pickVisibility={rulesPickVisibility}
				/>
			{/if}
		</section>

		<footer class="league-footer">
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
	{/if}
</main>

<style>
	.page-league {
		max-width: 56rem;
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.9rem;
		margin: 0 0 0.75rem;
	}

	.card {
		margin-top: 1.25rem;
		padding: 1.1rem 1.25rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
	}

	.card-title {
		margin: 0 0 0.35rem;
		font-size: 1rem;
		color: var(--text);
	}

	.invite-row {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-top: 0.75rem;
	}

	.invite-code {
		font-size: 1.25rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		color: var(--brand);
		padding: 0.5rem 0.75rem;
		border-radius: var(--radius);
		background: var(--brand-muted);
		box-shadow: var(--shadow-sm);
	}

	:global([data-theme='light']) .invite-code {
		color: var(--text);
	}

	.commissioner-tools-row {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 1rem;
	}

	.league-footer {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 0.75rem;
		margin-top: 2rem;
		padding-top: 1.25rem;
		border-top: 1px solid var(--border);
	}

	.demo-view-note {
		color: var(--link);
	}

	.demo-travel-wrap {
		margin-top: 1.25rem;
	}
</style>
