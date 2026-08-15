<script lang="ts">
	import { afterNavigate, goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { useAdmin, useAuth } from '$lib/auth';
	import { isAppAdmin } from '$lib/admin';
	import DemoBanner from '$lib/components/pick/DemoBanner.svelte';
	import WeekNavigator from '$lib/components/pick/WeekNavigator.svelte';
	import PickDashboard from '$lib/components/league/PickDashboard.svelte';
	import LeagueFooter from '$lib/components/league/LeagueFooter.svelte';
	import StandingsTable from '$lib/components/league/StandingsTable.svelte';
	import PicksGrid from '$lib/components/league/PicksGrid.svelte';
	import {
		getMaxVisibleWeek,
		GUEST_DEMO_USER_ID,
		hasDemoPicks,
		loadDemoState,
		mergeDemoLeagueView,
		resetDemoPicks,
		saveDemoState,
		simulatedWeekLabel
	} from '$lib/demo';
	import { fetchSeasonWeekCompletion, fetchWeekGames, resolveCurrentWeek } from '$lib/games';
	import {
		getGamesStartedCount,
		getNextUpcomingKickoff,
		getPickCtaState
	} from '$lib/leaguePickStatus';
	import { subscribeLiveRefresh } from '$lib/liveRefresh';
	import {
		adminDeleteLeague,
		adminKickLeagueMember,
		fetchLeague,
		isPublicDemoLeagueId
	} from '$lib/leagues';
	import {
		parsePickVisibility,
		parseTiebreakerMode
	} from '$lib/leagueRules';
	import {
		isQaClockEnabled,
		qaNow,
		qaNowDate,
		qaSimulatedNowMs
	} from '$lib/qaClock.svelte';
	import { getCurrentWeekFromDate, isDemoSeason, REGULAR_SEASON_WEEKS } from '$lib/season';
	import { syncSeasonIndicatorForLeague } from '$lib/seasonIndicatorStore.svelte';
	import { fetchLeaguePicks, fetchLeaguePickSubmissions, fetchLeagueStandings, type PickSubmissionsByCell } from '$lib/standings';
	import { requestGameSync } from '$lib/syncGames';
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
	let gridMaxWeek = $state<number | null>(1);
	/** Bumped on navigate / focus so week-completion re-fetches after QA changes. */
	let gridRefreshToken = $state(0);
	let viewWeek = $state(1);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let kickingUserId = $state<string | null>(null);
	let kickError = $state<string | null>(null);
	let deletingLeague = $state(false);
	let deleteLeagueError = $state<string | null>(null);

	const leagueId = $derived($page.params.id);

	const adminToolsEnabled = $derived(
		isAppAdmin(auth.user?.email) && admin.adminModeEnabled
	);

	const isDemo = $derived(league !== null && isDemoSeason(league.season_year));
	const isPublicDemo = $derived(league?.is_public_demo === true);

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
		if (!demoState.enabled) {
			return { picks, standings, maxVisibleWeek: null, demoActive: false };
		}

		if (!isDemoSeason(league?.season_year ?? 0)) {
			return { picks, standings, maxVisibleWeek: null, demoActive: false };
		}

		// Public demo: browse historical pool only — never surface the current viewer.
		const sourcePicks = isPublicDemo && user ? picks.filter((pick) => pick.user_id !== user.id) : picks;
		const sourceStandings =
			isPublicDemo && user ? standings.filter((row) => row.user_id !== user.id) : standings;

		return {
			...mergeDemoLeagueView(
				sourcePicks,
				sourceStandings,
				demoState,
				demoGamesByWeek,
				user?.id ?? GUEST_DEMO_USER_ID,
				playerDisplayName,
				league?.tiebreaker_mode ?? 'fewest_wins',
				!isPublicDemo
			),
			demoActive: true
		};
	});

	const visiblePickSubmissions = $derived.by(() => {
		const user = auth.user;
		if (!isPublicDemo || !user) return pickSubmissions;
		const prefix = `${user.id.toLowerCase()}:`;
		return Object.fromEntries(
			Object.entries(pickSubmissions).filter(([key]) => !key.startsWith(prefix))
		);
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
		// Recompute when the QA clock moves (same pattern as the picks grid).
		void qaSimulatedNowMs();
		void isQaClockEnabled();
		void qaNow();
		return getPickCtaState(viewWeek, liveWeekGames, userCurrentWeekPick);
	});

	const demoDashboardPick = $derived.by((): LeaguePick | null => {
		const user = auth.user;
		if (!isDemo || isPublicDemo || !user) return null;

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
		if (!isDemo || isPublicDemo) return { kind: 'hidden' as const };

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

		const nextKickoff = getNextUpcomingKickoff(games) ?? new Date().toISOString();
		return {
			kind: 'needs_pick' as const,
			week,
			nextKickoff,
			gamesStarted: getGamesStartedCount(games)
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

	$effect(() => {
		const leagueData = league;
		if (!leagueData) return;
		void qaSimulatedNowMs();
		void isQaClockEnabled();

		if (isDemo) {
			syncSeasonIndicatorForLeague(leagueData.season_year, demoState.simulatedWeek);
		} else {
			syncSeasonIndicatorForLeague(leagueData.season_year);
		}
	});

	const rulesTiebreakerMode = $derived(parseTiebreakerMode(league?.tiebreaker_mode));
	const rulesPickVisibility = $derived(parsePickVisibility(league?.pick_visibility));

	function refreshDemoState() {
		const id = leagueId;
		if (!id || !league) return;
		demoState = loadDemoState(id, auth.user?.id ?? GUEST_DEMO_USER_ID, league.season_year);
	}

	function persistDemoState(next: DemoState) {
		const id = leagueId;
		if (!id) return;
		demoState = next;
		saveDemoState(id, auth.user?.id ?? GUEST_DEMO_USER_ID, next);
	}

	function handleDemoWeekChange(simulatedWeek: number) {
		if (!isDemo) return;
		persistDemoState({ ...demoState, simulatedWeek });
	}

	function handleResetDemo() {
		persistDemoState(resetDemoPicks(demoState));
	}

	async function reloadLeagueData() {
		const id = leagueId;
		if (!id) return;

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

		const leagueData = league;
		if (!leagueData || isDemoSeason(leagueData.season_year)) return;

		void requestGameSync();
		const [gamesResult, completion] = await Promise.all([
			fetchWeekGames(leagueData.season_year, viewWeek),
			fetchSeasonWeekCompletion(leagueData.season_year)
		]);
		liveWeekGames = gamesResult.games;

		const liveWeek = completion.error
			? getCurrentWeekFromDate(qaNowDate(), leagueData.season_year)
			: resolveCurrentWeek(completion.weeks, qaNowDate(), leagueData.season_year);
		gridMaxWeek = liveWeek;
		if (liveWeek !== viewWeek) {
			viewWeek = liveWeek;
			const nextGames = await fetchWeekGames(leagueData.season_year, liveWeek);
			liveWeekGames = nextGames.games;
		}
	}

	async function handleKickPlayer(userId: string, displayName: string) {
		const id = leagueId;
		if (!id || !adminToolsEnabled) return;

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

	async function handleDeleteLeague() {
		const id = leagueId;
		if (!id || !league || !adminToolsEnabled || deletingLeague) return;

		const confirmed = confirm(
			`Delete league "${league.name}" permanently? This removes all members and picks and cannot be undone.`
		);
		if (!confirmed) return;

		deleteLeagueError = null;
		deletingLeague = true;

		const result = await adminDeleteLeague(id);
		deletingLeague = false;

		if (result.error) {
			deleteLeagueError = result.error;
			return;
		}

		await goto(`${base}/leagues`);
	}

	$effect(() => {
		const user = auth.user;
		const id = leagueId;
		if (auth.loading || !id) return;
		if (!user && !isPublicDemoLeagueId(id)) return;

		loading = true;
		error = null;

		Promise.all([
			fetchLeague(id, user?.id ?? null),
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
						qaNowDate(),
						leagueResult.league.season_year
					);
				}
				demoState = loadDemoState(
					id,
					user?.id ?? GUEST_DEMO_USER_ID,
					leagueResult.league.season_year
				);
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
		const leagueData = league;
		// Re-run when picks reload, QA clock changes, or we explicitly refresh
		// (returning from /qa after simulating results).
		void picks;
		void qaSimulatedNowMs();
		void isQaClockEnabled();
		void gridRefreshToken;
		if (!leagueData || isDemoSeason(leagueData.season_year)) {
			gridMaxWeek = null;
			return;
		}

		let cancelled = false;
		fetchSeasonWeekCompletion(leagueData.season_year).then((result) => {
			if (cancelled) return;
			const liveWeek = result.error
				? getCurrentWeekFromDate(qaNowDate(), leagueData.season_year)
				: resolveCurrentWeek(result.weeks, qaNowDate(), leagueData.season_year);
			gridMaxWeek = liveWeek;
			viewWeek = liveWeek;
		});
		return () => {
			cancelled = true;
		};
	});

	// After QA clock advances, auto-MNF / missed rows may have been inserted —
	// refetch so the grid is not stuck on stale empty cells.
	$effect(() => {
		const clockMs = qaSimulatedNowMs();
		const enabled = isQaClockEnabled();
		const id = leagueId;
		if (!enabled || clockMs === null || !id || !league || isDemoSeason(league.season_year)) {
			return;
		}
		let cancelled = false;
		void reloadLeagueData().then(() => {
			if (!cancelled) gridRefreshToken += 1;
		});
		return () => {
			cancelled = true;
		};
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
		].filter((week) => week >= 1 && week <= REGULAR_SEASON_WEEKS);
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
		gridRefreshToken += 1;
		if (league && !isDemoSeason(league.season_year)) {
			void reloadLeagueData();
		}
	});

	$effect(() => {
		if (typeof document === 'undefined') return;
		const leagueData = league;
		if (!leagueData || isDemoSeason(leagueData.season_year)) return;

		return subscribeLiveRefresh(() => {
			gridRefreshToken += 1;
			void reloadLeagueData();
		});
	});

</script>

<main class="page page-league">
	{#if auth.loading || loading}
		<p class="muted">Loading league…</p>
	{:else if error || !league}
		<p class="auth-error" role="alert">{error ?? 'League not found.'}</p>
	{:else}
		{#if isDemo}
			<DemoBanner seasonYear={league.season_year} />
		{/if}

		<div class="league-title-row">
			<h1 class="page-title">{league.name}</h1>
			{#if adminToolsEnabled}
				<button
					type="button"
					class="delete-league-btn"
					title="Delete league"
					disabled={deletingLeague}
					aria-label="Delete league {league.name}"
					onclick={handleDeleteLeague}
				>
					{deletingLeague ? '…' : '×'}
				</button>
			{/if}
		</div>
		<p class="page-subtitle">{league.season_year} season</p>
		{#if deleteLeagueError}
			<p class="auth-error" role="alert">{deleteLeagueError}</p>
		{/if}

		{#if !isPublicDemo && (isDemo || dashboardCta.kind !== 'hidden')}
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
				<div class="demo-travel-item demo-travel-week">
					{#if isPublicDemo}
						<span
							class="demo-chip"
							data-tooltip="Select a week in the season to preview what the league standings, scores, and picks looked like at this time"
							aria-label="Demo. Select a week in the season to preview what the league standings, scores, and picks looked like at this time"
							tabindex="0"
						>DEMO</span>
					{/if}
					<WeekNavigator
						viewWeek={demoState.simulatedWeek}
						onWeekChange={handleDemoWeekChange}
						label="Simulated time"
						showReset={!isPublicDemo}
						canReset={!isPublicDemo && hasDemoPicks(demoState)}
						onReset={isPublicDemo ? undefined : handleResetDemo}
					/>
				</div>
				{#if isPublicDemo}
					<div class="demo-travel-item demo-travel-picks">
						<a href="{base}/league/{league.id}/pick" class="btn btn-primary demo-picks-link">
							View Pick Selections
						</a>
					</div>
				{/if}
			</section>
		{/if}

		<section class="card">
			{#if leagueView.standings.length === 0}
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
					<p class="muted">Ranked by total points. Tiebreaker = sum of picked teams' season wins (lower is better).</p>
				{/if}
				{#if kickError}
					<p class="auth-error" role="alert">{kickError}</p>
				{/if}
				<p class="muted">No standings yet.</p>
			{:else}
				<StandingsTable
					standings={leagueView.standings}
					currentUserId={isPublicDemo ? null : (auth.user?.id ?? null)}
					tiebreakerMode={rulesTiebreakerMode}
					adminKickEnabled={adminToolsEnabled}
					commissionerId={league.commissioner_id}
					{kickingUserId}
					onKickPlayer={handleKickPlayer}
				>
					{#snippet stickyTop()}
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
							<p class="muted">
								Ranked by total points. Tiebreaker = sum of picked teams' season wins (lower is
								better).
							</p>
						{/if}
						{#if kickError}
							<p class="auth-error" role="alert">{kickError}</p>
						{/if}
					{/snippet}
				</StandingsTable>
			{/if}
		</section>

		<section class="card">
			{#if leagueView.picks.length === 0 && Object.keys(visiblePickSubmissions).length === 0}
				<h2 class="card-title">Weekly picks</h2>
				<p class="muted">No picks yet.</p>
			{:else}
				<PicksGrid
					picks={leagueView.picks}
					standings={leagueView.standings}
					currentUserId={isPublicDemo ? null : (auth.user?.id ?? null)}
					viewWeek={null}
					maxWeek={isDemo ? leagueView.maxVisibleWeek : gridMaxWeek}
					pickSubmissions={visiblePickSubmissions}
					pickVisibility={rulesPickVisibility}
				>
					{#snippet stickyTop()}
						<h2 class="card-title">Weekly picks</h2>
					{/snippet}
				</PicksGrid>
			{/if}
		</section>

		<LeagueFooter
			bind:league
			weekNumber={viewWeek}
			standings={leagueView.standings}
			picks={leagueView.picks}
			games={liveWeekGames}
		/>
	{/if}
</main>

<style>
	.page-league {
		max-width: var(--app-content-max, 50rem);
		overflow: visible;
	}

	.league-title-row {
		display: flex;
		align-items: center;
		gap: 0.55rem;
		min-width: 0;
	}

	.league-title-row .page-title {
		min-width: 0;
	}

	.delete-league-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 1.35rem;
		height: 1.35rem;
		padding: 0;
		border: none;
		border-radius: 999px;
		background: color-mix(in srgb, var(--danger) 12%, var(--surface));
		color: var(--danger);
		font-size: 1rem;
		line-height: 1;
		font-weight: 700;
		cursor: pointer;
		box-shadow: var(--shadow-sm);
		flex-shrink: 0;
	}

	.delete-league-btn:hover:not(:disabled) {
		background: color-mix(in srgb, var(--danger) 20%, var(--surface));
	}

	.delete-league-btn:disabled {
		opacity: 0.55;
		cursor: not-allowed;
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
		box-shadow: var(--shadow);
		overflow: visible;
	}

	.card-title {
		margin: 0 0 0.35rem;
		font-size: 1rem;
		color: var(--text);
	}

	.demo-view-note {
		color: var(--link);
	}

	.demo-travel-wrap {
		margin-top: 1.25rem;
		display: flex;
		flex-direction: row;
		align-items: stretch;
		gap: 0.75rem;
	}

	.demo-travel-item {
		position: relative;
		display: flex;
		min-width: 0;
	}

	.demo-travel-week {
		flex: 7 1 0;
	}

	.demo-travel-picks {
		flex: 3 1 0;
		justify-content: flex-end;
		align-items: flex-start;
	}

	.demo-travel-week :global(.week-nav) {
		flex: 1 1 auto;
		width: 100%;
		min-width: 0;
	}

	.demo-chip {
		position: absolute;
		top: 0.4rem;
		right: 0.4rem;
		z-index: 2;
		padding: 0.15rem 0.4rem;
		border-radius: var(--radius);
		background: color-mix(in srgb, var(--link) 18%, var(--surface));
		color: var(--link);
		font-size: 0.62rem;
		font-weight: 700;
		letter-spacing: 0.06em;
		line-height: 1.2;
		box-shadow: var(--shadow-sm);
		cursor: help;
	}

	.demo-chip::after {
		content: attr(data-tooltip);
		position: absolute;
		top: calc(100% + 0.4rem);
		right: 0;
		z-index: 300;
		width: max-content;
		max-width: min(16.5rem, calc(100vw - 2rem));
		padding: 0.45rem 0.6rem;
		border-radius: var(--radius);
		background: var(--text);
		color: var(--surface);
		font-size: 0.72rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		line-height: 1.35;
		text-transform: none;
		white-space: normal;
		text-align: left;
		box-shadow: var(--shadow);
		opacity: 0;
		pointer-events: none;
		transform: translateY(-0.15rem);
		transition:
			opacity 0.12s ease,
			transform 0.12s ease;
	}

	.demo-chip:hover::after,
	.demo-chip:focus-visible::after {
		opacity: 1;
		transform: translateY(0);
	}

	.demo-picks-link {
		display: inline-flex;
		width: auto;
		max-width: 100%;
	}
</style>
