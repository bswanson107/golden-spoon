<script lang="ts">
	import GameCard from '$lib/components/pick/GameCard.svelte';
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import WeekNavigator from '$lib/components/pick/WeekNavigator.svelte';
	import { DEFAULT_UNDERDOG_THRESHOLD } from '$lib/leagueRules';
	import {
		buildDemoPick,
		canPickWeek,
		formatPoints,
		formatWinPct,
		outcomeLabel,
		resultsVisibleForWeek,
		scoreDemoPick
	} from '$lib/demo';
	import { teamUsageByWeek, type UserLeaguePick } from '$lib/picks';
	import { fetchWeekGames } from '$lib/games';
	import { formatSyncTimeAgo, getLastSyncTime, requestGameSync } from '$lib/syncGames';
	import type { DemoPick, DemoState } from '$lib/types/demo';
	import type { WeekGame } from '$lib/types/game';

	type SavePickOptions = { clearWeek?: number };

	let {
		mode,
		seasonYear,
		viewWeek,
		onWeekChange,
		weekNavLabel = 'View week',
		showWeekReset = false,
		canWeekReset = false,
		onWeekReset,
		demoState = null,
		userPicksByWeek = new Map<number, UserLeaguePick>(),
		underdogThreshold = DEFAULT_UNDERDOG_THRESHOLD,
		saving = false,
		onSavePick
	}: {
		mode: 'demo' | 'live';
		seasonYear: number;
		viewWeek: number;
		onWeekChange: (week: number) => void;
		weekNavLabel?: string;
		showWeekReset?: boolean;
		canWeekReset?: boolean;
		onWeekReset?: () => void;
		demoState?: DemoState | null;
		userPicksByWeek?: Map<number, UserLeaguePick>;
		underdogThreshold?: number;
		saving?: boolean;
		onSavePick: (week: number, pick: DemoPick, options?: SavePickOptions) => void | Promise<void>;
	} = $props();

	let games = $state<WeekGame[]>([]);
	let priorWeekGames = $state<WeekGame[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let pendingPick = $state<DemoPick | null>(null);
	let reuseConfirm = $state<{ pick: DemoPick; clearWeek: number } | null>(null);
	let lastSyncAt = $state<string | null>(null);
	let syncNotice = $state<string | null>(null);

	const activeWeek = $derived(viewWeek);

	const demoCurrentPick = $derived(
		mode === 'demo' && demoState ? (demoState.picks[activeWeek] ?? null) : null
	);

	const liveCurrentPick = $derived(userPicksByWeek.get(activeWeek) ?? null);

	const currentPick = $derived(
		mode === 'demo' ? demoCurrentPick : livePickToDemo(liveCurrentPick)
	);

	const weekOpen = $derived(
		mode === 'demo' && demoState ? canPickWeek(activeWeek, demoState.simulatedWeek) : true
	);

	const pickSubmitted = $derived(mode === 'demo' ? demoCurrentPick !== null : liveCurrentPick !== null);

	const canChangeLivePick = $derived.by(() => {
		if (mode !== 'live') return true;
		if (!liveCurrentPick) return true;
		const game = games.find((g) => g.id === liveCurrentPick.game_id);
		if (!game) return true;
		return game.status === 'scheduled' && new Date(game.kickoff_at) > new Date();
	});

	const pickingEnabled = $derived(
		mode === 'demo' ? weekOpen && !pickSubmitted : canChangeLivePick
	);

	const showResults = $derived.by(() => {
		if (mode === 'demo' && demoState) {
			return resultsVisibleForWeek(activeWeek, demoState.simulatedWeek);
		}
		if (!liveCurrentPick) return false;
		const game = games.find((g) => g.id === liveCurrentPick.game_id);
		return game?.status === 'final';
	});

	const displayTeamId = $derived(pendingPick?.team_id ?? currentPick?.team_id ?? null);

	const showSubmitButton = $derived(
		pickingEnabled && games.length > 0 && !(mode === 'live' && liveCurrentPick !== null)
	);

	const usageMap = $derived.by(() => {
		if (mode === 'demo' && demoState) {
			const picksMap = new Map(
				Object.entries(demoState.picks).map(([week, pick]) => [Number(week), pick])
			);
			return teamUsageByWeek(picksMap, viewWeek);
		}
		return teamUsageByWeek(userPicksByWeek, viewWeek);
	});

	const priorWeek = $derived(activeWeek > 1 ? activeWeek - 1 : null);

	const priorPick = $derived.by(() => {
		if (priorWeek === null) return null;
		if (mode === 'demo' && demoState) return demoState.picks[priorWeek] ?? null;
		return livePickToDemo(userPicksByWeek.get(priorWeek) ?? null);
	});

	const priorResultsVisible = $derived.by(() => {
		if (priorWeek === null || !priorPick) return false;
		if (mode === 'demo' && demoState) {
			return resultsVisibleForWeek(priorWeek, demoState.simulatedWeek);
		}
		const livePrior = userPicksByWeek.get(priorWeek);
		if (!livePrior) return false;
		const game = priorWeekGames.find((g) => g.id === livePrior.game_id);
		return game?.status === 'final';
	});

	const priorScored = $derived.by(() => {
		if (!priorPick || !priorWeek || !priorResultsVisible) return null;
		if (mode === 'demo' && demoState) {
			const game = priorWeekGames.find((g) => g.id === priorPick.game_id) ?? null;
			return scoreDemoPick(priorWeek, priorPick, game, demoState.simulatedWeek);
		}
		const livePrior = userPicksByWeek.get(priorWeek);
		if (!livePrior) return null;
		const game = priorWeekGames.find((g) => g.id === livePrior.game_id) ?? null;
		if (!game || game.status !== 'final') return null;
		return livePickToScored(livePrior, game);
	});

	const currentScored = $derived.by(() => {
		if (!currentPick || !showResults) return null;
		if (mode === 'demo' && demoState) {
			const game = games.find((g) => g.id === currentPick.game_id) ?? null;
			return scoreDemoPick(activeWeek, currentPick, game, demoState.simulatedWeek);
		}
		if (!liveCurrentPick) return null;
		const game = games.find((g) => g.id === liveCurrentPick.game_id) ?? null;
		if (!game || game.status !== 'final') return null;
		return livePickToScored(liveCurrentPick, game);
	});

	function livePickToDemo(pick: UserLeaguePick | null | undefined): DemoPick | null {
		if (!pick) return null;
		return {
			game_id: pick.game_id,
			team_id: pick.team_id,
			team_abbreviation: pick.team_abbreviation,
			team_name: pick.team_name,
			win_pct_at_pick: pick.win_pct_at_pick,
			is_underdog_at_pick: pick.is_underdog_at_pick
		};
	}

	function livePickToScored(pick: UserLeaguePick, game: WeekGame) {
		return {
			...livePickToDemo(pick)!,
			week_number: pick.week_number,
			outcome: pick.outcome,
			points_awarded: pick.points_awarded
		};
	}

	$effect(() => {
		activeWeek;
		pendingPick = null;
		reuseConfirm = null;
	});

	$effect(() => {
		if (mode === 'demo') {
			JSON.stringify(demoState?.picks ?? {});
		} else {
			userPicksByWeek;
		}
		pendingPick = null;
	});

	const syncTimeLabel = $derived(formatSyncTimeAgo(lastSyncAt));

	async function loadWeekGames(week: number, prevWeek: number | null, hasPriorPick: boolean) {
		const fetches = [fetchWeekGames(seasonYear, week)];
		if (prevWeek !== null && hasPriorPick) {
			fetches.push(fetchWeekGames(seasonYear, prevWeek));
		}

		const results = await Promise.all(fetches);
		const [weekResult, priorResult] = results;

		if (weekResult.error) {
			error = weekResult.error;
			games = [];
		} else {
			games = weekResult.games;
		}

		if (priorResult?.error) {
			priorWeekGames = [];
		} else if (priorResult) {
			priorWeekGames = priorResult.games;
		} else {
			priorWeekGames = [];
		}
	}

	$effect(() => {
		if (mode === 'demo' && !demoState?.enabled) {
			games = [];
			priorWeekGames = [];
			loading = false;
			error = null;
			return;
		}

		const week = activeWeek;
		const prevWeek = priorWeek;
		const hasPriorPick = priorPick !== null;
		loading = true;
		error = null;
		syncNotice = null;

		void (async () => {
			if (mode === 'live') {
				const [syncResult, syncTime] = await Promise.all([
					requestGameSync(),
					getLastSyncTime()
				]);

				lastSyncAt = syncResult.lastSyncAt ?? syncTime;

				if (syncResult.error) {
					syncNotice = 'Could not refresh odds — showing last saved data.';
				} else if (syncResult.skipped) {
					syncNotice = null;
				} else if (syncResult.inProgress) {
					syncNotice = 'Updating odds in the background…';
				} else if (syncResult.gamesUpdated > 0 || syncResult.oddsUpdated > 0) {
					syncNotice = 'Odds and scores updated.';
				}
			}

			await loadWeekGames(week, prevWeek, hasPriorPick);
			loading = false;
		})();
	});

	function applyPendingPick(pick: DemoPick, clearWeek: number | null) {
		const options = clearWeek !== null ? { clearWeek } : undefined;
		void onSavePick(activeWeek, pick, options);
		pendingPick = null;
		reuseConfirm = null;
	}

	function handleSelectTeam(game: WeekGame, teamId: string) {
		if (!pickingEnabled) return;
		const pick = buildDemoPick(game, teamId, underdogThreshold, mode === 'live');
		if (!pick) return;

		const usedWeek = usageMap.get(teamId);
		if (usedWeek !== undefined) {
			reuseConfirm = { pick, clearWeek: usedWeek };
			return;
		}

		// Live mode: changing an existing pick saves immediately (still editable until kickoff)
		if (mode === 'live' && liveCurrentPick) {
			pendingPick = null;
			void onSavePick(activeWeek, pick);
			return;
		}

		pendingPick = pick;
	}

	function handleSubmitPick() {
		if (!pendingPick || saving) return;
		if (mode === 'demo' && pickSubmitted) return;

		const usedWeek = usageMap.get(pendingPick.team_id);
		if (usedWeek !== undefined) {
			reuseConfirm = { pick: pendingPick, clearWeek: usedWeek };
			return;
		}

		applyPendingPick(pendingPick, null);
	}

	function confirmReuse() {
		if (!reuseConfirm) return;
		applyPendingPick(reuseConfirm.pick, reuseConfirm.clearWeek);
	}

	function cancelReuse() {
		reuseConfirm = null;
	}
</script>

{#if mode === 'demo' && !demoState?.enabled}
	<p class="muted">Demo mode is unavailable for this season.</p>
{:else}
	<div class="pick-sticky-bar">
		<WeekNavigator
			{viewWeek}
			onWeekChange={onWeekChange}
			label={weekNavLabel}
			compact
			showReset={showWeekReset}
			canReset={canWeekReset}
			onReset={onWeekReset}
		/>

		{#if !loading && !error}
			<div class="pick-toolbar">
				<div
					class="pick-status"
					class:status-submitted={pickSubmitted && !pendingPick}
					class:status-ready={pendingPick !== null}
					class:status-needed={pickingEnabled && !pickSubmitted && !pendingPick}
					class:status-locked={!pickingEnabled && pickSubmitted}
				>
					{#if pendingPick}
						<span class="status-indicator ready" aria-hidden="true"></span>
						<span class="status-text">
							Ready to submit · <strong>{pendingPick.team_abbreviation}</strong>
							<span class="status-meta">({formatWinPct(pendingPick.win_pct_at_pick)})</span>
						</span>
					{:else if pickSubmitted && currentPick}
						<TeamLogo teamCode={currentPick.team_id} size={22} />
						<span class="status-text">
							{#if mode === 'live' && canChangeLivePick}
								Current pick · <strong>{currentPick.team_abbreviation}</strong>
							{:else}
								Pick submitted · <strong>{currentPick.team_abbreviation}</strong>
							{/if}
							<span class="status-meta">({formatWinPct(currentPick.win_pct_at_pick)})</span>
						</span>
						{#if mode === 'live' && !canChangeLivePick}
							<span class="status-tag">Final</span>
						{/if}
					{:else if pickingEnabled}
						<span class="status-indicator needed" aria-hidden="true"></span>
						<span class="status-text">Pick not submitted — choose a team below</span>
					{:else if mode === 'demo' && !weekOpen}
						<span class="status-indicator locked" aria-hidden="true"></span>
						<span class="status-text">This week is closed</span>
					{:else}
						<span class="status-indicator locked" aria-hidden="true"></span>
						<span class="status-text">No pick for Week {activeWeek}</span>
					{/if}
				</div>

				{#if showSubmitButton}
					<button
						type="button"
						class="btn btn-primary btn-sm submit-pick-btn"
						disabled={!pendingPick || saving}
						onclick={handleSubmitPick}
					>
						{#if saving}
							Saving…
						{:else if pendingPick}
							Submit · {pendingPick.team_abbreviation}
						{:else}
							Submit pick
						{/if}
					</button>
			{/if}
		</div>
		{:else if loading && mode === 'live'}
			<div class="pick-toolbar pick-toolbar-loading">
				<span class="muted">Refreshing odds and scores…</span>
			</div>
		{/if}

		{#if mode === 'live' && (syncTimeLabel || syncNotice)}
			<p class="sync-meta">
				{#if syncTimeLabel}
					Updated {syncTimeLabel}
				{/if}
				{#if syncNotice}
					{#if syncTimeLabel}
						·
					{/if}
					{syncNotice}
				{/if}
			</p>
		{/if}
	</div>

	{#if loading}
		<!-- games loading; sticky bar shows status above -->
	{:else if error}
		<p class="error" role="alert">{error}</p>
	{:else}
	<div class="pick-scroll-content">
		{#if priorScored}
			<div class="result-banner {priorScored.outcome}">
				<p class="result-title">Week {priorWeek} result</p>
				<p class="result-body">
					<span class="pick-with-logo">
						<TeamLogo teamCode={priorScored.team_id} size={28} />
						You picked <strong>{priorScored.team_abbreviation}</strong>
					</span>
					({formatWinPct(priorScored.win_pct_at_pick)})
					— {outcomeLabel(priorScored.outcome)},
					{formatPoints(priorScored.points_awarded)} pt{formatPoints(priorScored.points_awarded) === '1' ? '' : 's'}
					{#if priorScored.outcome === 'win' && priorScored.is_underdog_at_pick}
						<span class="underdawg-note">Underdawg bonus!</span>
					{/if}
				</p>
			</div>
		{/if}

		{#if pickSubmitted && !showResults && mode === 'demo'}
			<p class="hint muted">Time travel forward to see how you did.</p>
		{:else if pickSubmitted && !showResults && mode === 'live' && canChangeLivePick}
			<p class="hint muted">Tap another team to change your pick — you can change until kickoff.</p>
		{:else if pickSubmitted && !showResults && mode === 'live' && !canChangeLivePick}
			<p class="hint muted">Result pending — check back after the game.</p>
		{/if}

		{#if currentScored}
			<div class="result-banner {currentScored.outcome}">
				<p class="result-title">This week's result</p>
				<p class="result-body pick-with-logo">
					<TeamLogo teamCode={currentScored.team_id} size={28} />
					<strong>{currentScored.team_abbreviation}</strong>
					— {outcomeLabel(currentScored.outcome)},
					{formatPoints(currentScored.points_awarded)} pt{formatPoints(currentScored.points_awarded) === '1' ? '' : 's'}
				</p>
			</div>
		{/if}

		{#if games.length === 0}
			<p class="muted">No games found for Week {activeWeek}.</p>
		{:else}
			<div class="games-list">
				{#each games as game (game.id)}
					<GameCard
						{game}
						selectedTeamId={displayTeamId}
						teamUsageByWeek={usageMap}
						{activeWeek}
						{pickingEnabled}
						{showResults}
						{underdogThreshold}
						onSelectTeam={(teamId) => handleSelectTeam(game, teamId)}
					/>
				{/each}
			</div>
		{/if}
	</div>
	{/if}
{/if}

{#if reuseConfirm}
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class="modal-backdrop"
		role="presentation"
		onclick={cancelReuse}
		onkeydown={(e) => e.key === 'Escape' && cancelReuse()}
	>
		<div
			class="modal"
			role="dialog"
			aria-modal="true"
			aria-labelledby="reuse-title"
			tabindex="-1"
			onclick={(e) => e.stopPropagation()}
		>
			<h4 id="reuse-title" class="modal-title">Change team selection?</h4>
			<p class="modal-body">
				You already picked <strong>{reuseConfirm.pick.team_abbreviation}</strong> in Week
				{reuseConfirm.clearWeek}. Moving your pick to Week {activeWeek} will remove your previous
				selection.
			</p>
			<div class="modal-actions">
				<button type="button" class="btn-cancel" onclick={cancelReuse}>Cancel</button>
				<button type="button" class="btn-confirm" disabled={saving} onclick={confirmReuse}>
					{saving ? 'Saving…' : 'Continue'}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.muted {
		color: var(--text-muted);
		font-size: 0.9rem;
		margin: 0;
	}

	.error {
		margin: 0;
		padding: 0.65rem 0.75rem;
		border-radius: var(--radius);
		background: var(--danger-muted);
		color: var(--danger);
		font-size: 0.875rem;
	}

	.pick-sticky-bar {
		position: sticky;
		top: var(--app-header-height, 3.25rem);
		z-index: 40;
		margin: 0 -1rem 1rem;
		padding: 0.75rem 1rem 0.85rem;
		background: var(--chrome-bg);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		border: none;
		box-shadow: none;
	}

	.pick-toolbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.65rem;
		margin-top: 0.75rem;
		padding-top: 0;
	}

	.pick-toolbar-loading {
		justify-content: flex-start;
	}

	.pick-toolbar-loading .muted {
		font-size: 0.82rem;
	}

	.sync-meta {
		margin: 0.55rem 0 0;
		font-size: 0.75rem;
		color: var(--text-muted);
		text-align: center;
	}

	.pick-status {
		display: flex;
		align-items: center;
		gap: 0.45rem;
		min-width: 0;
		flex: 1;
		font-size: 0.82rem;
		color: var(--text-muted);
	}

	.status-text {
		min-width: 0;
		line-height: 1.35;
	}

	.status-text strong {
		color: var(--text);
	}

	.status-meta {
		color: var(--text-muted);
		font-size: 0.78rem;
	}

	.status-indicator {
		width: 0.55rem;
		height: 0.55rem;
		border-radius: 50%;
		flex-shrink: 0;
	}

	.status-indicator.needed {
		background: var(--brand);
		box-shadow: 0 0 0 3px color-mix(in srgb, var(--brand) 25%, transparent);
	}

	.status-indicator.ready {
		background: var(--brand);
		box-shadow: 0 0 0 3px color-mix(in srgb, var(--brand) 25%, transparent);
	}

	.status-indicator.locked {
		background: var(--text-muted);
		opacity: 0.65;
	}

	.pick-status.status-submitted {
		color: var(--text);
	}

	.pick-status.status-ready {
		color: var(--text);
	}

	.pick-status.status-needed {
		color: var(--text-muted);
	}

	.status-tag {
		flex-shrink: 0;
		padding: 0.12rem 0.45rem;
		border-radius: 999px;
		font-size: 0.68rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--text-muted);
		background: var(--surface-2);
		border: none;
		box-shadow: var(--shadow-sm);
	}

	.pick-scroll-content {
		display: flex;
		flex-direction: column;
		gap: 0;
	}

	.hint {
		margin: 0 0 0.85rem;
		font-size: 0.82rem;
	}

	.result-banner {
		margin: 0.85rem 0;
		padding: 0.85rem 1rem;
		border-radius: var(--radius);
		border: none;
		box-shadow: var(--shadow-sm);
		font-size: 0.9rem;
		font-weight: 600;
		color: var(--text);
		border-left: 3px solid transparent;
	}

	.result-banner.win {
		background: color-mix(in srgb, var(--win-bg) 28%, var(--surface));
		border-left-color: var(--win-bg);
	}

	.result-banner.loss {
		background: color-mix(in srgb, var(--danger) 24%, var(--surface));
		border-left-color: var(--danger);
	}

	.result-banner.tie {
		background: color-mix(in srgb, var(--tie-bg) 28%, var(--surface));
		border-left-color: var(--tie-bg);
	}

	.result-title {
		margin: 0 0 0.25rem;
		font-size: 0.75rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		color: var(--text-muted);
	}

	.result-body {
		margin: 0;
		font-size: 0.95rem;
	}

	.pick-with-logo {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
	}

	.underdawg-note {
		margin-left: 0.35rem;
		font-size: 0.8rem;
		font-weight: 700;
		color: var(--brand);
	}

	.submit-pick-btn {
		flex-shrink: 0;
		white-space: nowrap;
	}

	.submit-pick-btn:hover:not(:disabled) {
		filter: brightness(1.05);
	}

	.games-list {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.modal-backdrop {
		position: fixed;
		inset: 0;
		z-index: 100;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
		background: rgba(0, 0, 0, 0.55);
	}

	.modal {
		width: min(100%, 24rem);
		padding: 1.1rem 1.2rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.modal-title {
		margin: 0 0 0.5rem;
		font-size: 1rem;
		color: var(--text);
	}

	.modal-body {
		margin: 0;
		font-size: 0.9rem;
		color: var(--text-muted);
		line-height: 1.45;
	}

	.modal-actions {
		display: flex;
		justify-content: flex-end;
		gap: 0.5rem;
		margin-top: 1rem;
	}

	.btn-cancel,
	.btn-confirm {
		padding: 0.45rem 0.75rem;
		border-radius: var(--radius);
		font-size: 0.85rem;
		font-weight: 600;
		font-family: var(--font-body);
		cursor: pointer;
		box-shadow: var(--shadow-sm);
	}

	.btn-cancel {
		border: none;
		background: var(--surface-2);
		color: var(--text-muted);
	}

	.btn-confirm {
		border: none;
		background: var(--primary);
		color: var(--primary-text);
	}

	.btn-confirm:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	@media (max-width: 480px) {
		.pick-toolbar {
			flex-direction: column;
			align-items: stretch;
		}

		.submit-pick-btn {
			width: 100%;
			padding: 0.65rem 0.85rem;
		}
	}
</style>
