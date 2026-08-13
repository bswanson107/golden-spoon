<script lang="ts">
	import { browser } from '$app/environment';
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import LeagueFooter from '$lib/components/league/LeagueFooter.svelte';
	import DemoBanner from '$lib/components/pick/DemoBanner.svelte';
	import PickWeekPanel from '$lib/components/pick/PickWeekPanel.svelte';
	import SeasonLongPicksModal from '$lib/components/pick/SeasonLongPicksModal.svelte';
	import { hasDemoPicks, loadDemoState, regularSeasonWeek, resetDemoPicks, saveDemoState } from '$lib/demo';
	import { fetchSeasonWeekCompletion, resolveCurrentWeek } from '$lib/games';
	import { fetchLeague } from '$lib/leagues';
	import { normalizeUnderdogThreshold } from '$lib/leagueRules';
	import { loadViewWeek, saveViewWeek } from '$lib/pickView';
	import { fetchUserLeaguePicks, picksByWeek, saveLeaguePick, type UserLeaguePick } from '$lib/picks';
	import { isDemoSeason } from '$lib/season';
	import { isQaClockEnabled, qaNowDate, qaSimulatedNowMs } from '$lib/qaClock.svelte';
	import { syncSeasonIndicatorForLeague } from '$lib/seasonIndicatorStore.svelte';
	import type { DemoPick, DemoState } from '$lib/types/demo';
	import type { LeagueWithRole } from '$lib/types/league';

	const auth = useAuth();

	const VIEW_MODE_KEY = 'golden-spoon-pick-view';
	type ViewMode = 'card' | 'table';

	function readViewMode(): ViewMode {
		if (!browser) return 'card';
		return localStorage.getItem(VIEW_MODE_KEY) === 'table' ? 'table' : 'card';
	}

	let league = $state<LeagueWithRole | null>(null);
	let demoState = $state<DemoState>({ enabled: false, simulatedWeek: 1, picks: {} });
	let viewWeek = $state(1);
	let viewMode = $state<ViewMode>(readViewMode());
	let userPicks = $state<UserLeaguePick[]>([]);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state<string | null>(null);
	let saveError = $state<string | null>(null);
	let seasonPicksOpen = $state(false);
	let currentWeek = $state(1);

	function setViewMode(mode: ViewMode) {
		viewMode = mode;
		if (browser) localStorage.setItem(VIEW_MODE_KEY, mode);
	}

	const leagueId = $derived($page.params.id);
	const isDemo = $derived(league !== null && isDemoSeason(league.season_year));
	const isPublicDemo = $derived(league?.is_public_demo === true);
	const userPicksByWeek = $derived(picksByWeek(userPicks));
	const underdogThreshold = $derived(normalizeUnderdogThreshold(league?.underdog_threshold_pct));

	const seasonPickedTeamIds = $derived.by(() => {
		if (isPublicDemo) return [];
		if (isDemo) {
			return Object.values(demoState.picks).map((pick) => pick.team_id.toUpperCase());
		}
		return userPicks.filter((pick) => !pick.is_missed).map((pick) => pick.team_id.toUpperCase());
	});

	const seasonPickedWeekByTeam = $derived.by(() => {
		const map: Record<string, number> = {};
		if (isPublicDemo) return map;
		if (isDemo) {
			for (const [week, pick] of Object.entries(demoState.picks)) {
				map[pick.team_id.toUpperCase()] = Number(week);
			}
			return map;
		}
		for (const pick of userPicks) {
			if (pick.is_missed) continue;
			map[pick.team_id.toUpperCase()] = pick.week_number;
		}
		return map;
	});

	const seasonTeamByWeek = $derived.by(() => {
		const map: Record<number, string> = {};
		if (isPublicDemo) return map;
		if (isDemo) {
			for (const [week, pick] of Object.entries(demoState.picks)) {
				map[Number(week)] = pick.team_id.toUpperCase();
			}
			return map;
		}
		for (const pick of userPicks) {
			if (pick.is_missed) continue;
			map[pick.week_number] = pick.team_id.toUpperCase();
		}
		return map;
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

	$effect(() => {
		const user = auth.user;
		const id = leagueId;
		if (auth.loading || !user || !id) return;

		loading = true;
		error = null;

		fetchLeague(id, user.id).then(async (result) => {
			if (result.error || !result.league) {
				league = null;
				error = result.error ?? 'League not found.';
				userPicks = [];
				loading = false;
				return;
			}

			league = result.league;

			if (isDemoSeason(result.league.season_year)) {
				demoState = loadDemoState(id, user.id, result.league.season_year);
				viewWeek = demoState.simulatedWeek;
				userPicks = [];
			} else {
				const seasonYear = result.league.season_year;
				const completion = await fetchSeasonWeekCompletion(seasonYear);
				const liveWeek = completion.error
					? loadViewWeek(id, user.id, seasonYear)
					: resolveCurrentWeek(completion.weeks, qaNowDate(), seasonYear);
				currentWeek = liveWeek;
				const loadedViewWeek = loadViewWeek(id, user.id, seasonYear);
				viewWeek = Math.max(loadedViewWeek, liveWeek);
				saveViewWeek(id, user.id, viewWeek);
				demoState = loadDemoState(id, user.id, seasonYear);
				const picksResult = await fetchUserLeaguePicks(id, user.id);
				if (picksResult.error) {
					error = picksResult.error;
					userPicks = [];
				} else {
					userPicks = picksResult.picks;
				}
			}

			loading = false;
		});
	});

	async function reloadUserPicks() {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id) return;

		const picksResult = await fetchUserLeaguePicks(id, user.id);
		if (!picksResult.error) {
			userPicks = picksResult.picks;
		}
	}

	function persistDemoState(next: DemoState) {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id) return;
		demoState = next;
		saveDemoState(id, user.id, next);
	}

	function handleWeekChange(week: number) {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id || !league) return;

		if (isDemoSeason(league.season_year)) {
			persistDemoState({ ...demoState, simulatedWeek: week });
			viewWeek = week;
		} else {
			viewWeek = week;
			saveViewWeek(id, user.id, week);
		}
	}

	function handleResetDemo() {
		persistDemoState(resetDemoPicks(demoState));
	}

	function handleSaveDemoPick(week: number, pick: DemoPick, options?: { clearWeek?: number }) {
		if (isPublicDemo) return;
		const nextPicks = { ...demoState.picks, [week]: pick };
		if (options?.clearWeek !== undefined) {
			delete nextPicks[options.clearWeek];
		}
		persistDemoState({ ...demoState, picks: nextPicks });
	}

	async function handleSaveLivePick(week: number, pick: DemoPick, options?: { clearWeek?: number }) {
		const id = leagueId;
		const user = auth.user;
		if (!id || !user) return;

		saveError = null;
		saving = true;

		const existingPickId = userPicksByWeek.get(week)?.id ?? null;
		const clearWeekPickId =
			options?.clearWeek !== undefined
				? (userPicksByWeek.get(options.clearWeek)?.id ?? null)
				: null;

		const result = await saveLeaguePick({
			leagueId: id,
			week,
			gameId: pick.game_id,
			teamId: pick.team_id,
			userId: user.id,
			existingPickId,
			clearWeekPickId
		});

		saving = false;

		if (result.error) {
			saveError = result.error;
			return;
		}

		await reloadUserPicks();
	}
</script>

<main class="page page-pick">
	<div class="back-nav">
		<a href="{base}/league/{leagueId}" class="btn btn-ghost btn-sm">← Back to league</a>
	</div>

	{#if auth.loading || loading}
		<p class="muted">Loading…</p>
	{:else if error || !league}
		<p class="auth-error" role="alert">{error ?? 'League not found.'}</p>
	{:else}
		{#if isDemo}
			<DemoBanner seasonYear={league.season_year} />
		{/if}

		<h1 class="page-title">{isPublicDemo ? 'Week matchups' : 'Make your pick'}</h1>
		<div class="pick-view-row">
			<span class="pick-view-label">Pick Selection View:</span>
			<div class="view-toggle" role="group" aria-label="Game display">
				<div class="view-track" class:is-table={viewMode === 'table'}>
					<span class="view-thumb" aria-hidden="true"></span>
					<button
						type="button"
						class="view-option"
						class:active={viewMode === 'card'}
						onclick={() => setViewMode('card')}
						aria-pressed={viewMode === 'card'}
					>Card</button>
					<button
						type="button"
						class="view-option"
						class:active={viewMode === 'table'}
						onclick={() => setViewMode('table')}
						aria-pressed={viewMode === 'table'}
					>Table</button>
				</div>
			</div>
		</div>

		{#if saveError}
			<p class="auth-error pick-error" role="alert">{saveError}</p>
		{/if}

		<section class="pick-section">
			<PickWeekPanel
				mode={isDemo ? 'demo' : 'live'}
				seasonYear={league.season_year}
				viewWeek={isDemo ? demoState.simulatedWeek : viewWeek}
				onWeekChange={handleWeekChange}
				weekNavLabel={isDemo ? 'Simulated time' : 'View week'}
				showWeekReset={isDemo && !isPublicDemo}
				canWeekReset={!isPublicDemo && hasDemoPicks(demoState)}
				onWeekReset={isPublicDemo ? undefined : isDemo ? handleResetDemo : undefined}
				demoState={isDemo ? demoState : null}
				{userPicksByWeek}
				{underdogThreshold}
				{saving}
				{viewMode}
				readOnly={isPublicDemo}
				currentWeek={isDemo ? null : currentWeek}
				onSavePick={isDemo ? handleSaveDemoPick : handleSaveLivePick}
				onOpenSeasonOutlook={isPublicDemo ? undefined : () => (seasonPicksOpen = true)}
			/>
		</section>

		{#if !isPublicDemo}
			<SeasonLongPicksModal
				open={seasonPicksOpen}
				pickedTeamIds={seasonPickedTeamIds}
				pickedWeekByTeam={seasonPickedWeekByTeam}
				teamByWeek={seasonTeamByWeek}
				onClose={() => (seasonPicksOpen = false)}
			/>
		{/if}

		<LeagueFooter
			bind:league
			weekNumber={isDemo ? regularSeasonWeek(demoState.simulatedWeek) : viewWeek}
		/>
	{/if}
</main>

<style>
	.page-pick {
		max-width: var(--app-content-max, 50rem);
		overflow: visible;
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.pick-view-row {
		display: flex;
		align-items: center;
		gap: 0.65rem;
		margin-top: 0.35rem;
		flex-wrap: wrap;
	}

	.pick-view-label {
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--text-muted);
	}

	.view-toggle {
		flex: 0 0 auto;
	}

	.view-track {
		position: relative;
		display: grid;
		grid-template-columns: 1fr 1fr;
		align-items: stretch;
		height: 2rem;
		min-width: 8.5rem;
		padding: 0.2rem;
		border-radius: 999px;
		background: color-mix(in srgb, var(--text-muted) 14%, var(--surface-2));
		box-shadow: inset 0 1px 2px color-mix(in srgb, var(--text) 8%, transparent);
		box-sizing: border-box;
	}

	.view-thumb {
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

	.view-track.is-table .view-thumb {
		transform: translateX(100%);
	}

	.view-option {
		position: relative;
		z-index: 1;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0 0.55rem;
		font-size: 0.72rem;
		font-weight: 600;
		font-family: var(--font-body);
		border: none;
		background: transparent;
		color: var(--text-muted);
		cursor: pointer;
		white-space: nowrap;
		transition: color 0.2s ease;
	}

	.view-option.active {
		color: var(--text);
		font-weight: 700;
	}

	.view-option:not(.active):hover {
		color: var(--text);
	}

	.pick-section {
		margin-top: 0.75rem;
		min-width: 0;
		max-width: 100%;
	}

	.pick-error {
		margin-top: 1rem;
	}
</style>
