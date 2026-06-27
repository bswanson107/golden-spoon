<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import WeekNavigator from '$lib/components/pick/WeekNavigator.svelte';
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import {
		defaultPointsForOutcome,
		fetchLeaguePicksAdmin,
		getSyncState,
		overridePick,
		rescoreGame,
		updateGameStatus
	} from '$lib/commissioner';
	import { outcomeLabel, formatPoints } from '$lib/demo';
	import { fetchWeekGames } from '$lib/games';
	import { formatGameKickoffShort } from '$lib/gameKickoff';
	import { fetchLeague } from '$lib/leagues';
	import { qaNowDate } from '$lib/qaClock.svelte';
	import { getCurrentWeekFromDate } from '$lib/season';
	import { formatSyncTimeAgo } from '$lib/syncGames';
	import type { AdminPick, OverrideOutcome } from '$lib/types/commissioner';
	import type { SyncState } from '$lib/types/sync';
	import type { WeekGame } from '$lib/types/game';
	import type { LeagueWithRole } from '$lib/types/league';

	const auth = useAuth();

	const OUTCOME_OPTIONS: OverrideOutcome[] = ['pending', 'win', 'loss', 'tie', 'missed'];

	let league = $state<LeagueWithRole | null>(null);
	let syncState = $state<SyncState | null>(null);
	let picks = $state<AdminPick[]>([]);
	let games = $state<WeekGame[]>([]);
	let viewWeek = $state(1);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let actionMessage = $state<string | null>(null);
	let actionError = $state<string | null>(null);
	let busy = $state(false);

	let editingPickId = $state<string | null>(null);
	let overrideOutcome = $state<OverrideOutcome>('loss');
	let overridePoints = $state('0');
	let overrideNotes = $state('');

	let markingGameId = $state<string | null>(null);
	let markHomeScore = $state('');
	let markAwayScore = $state('');

	const leagueId = $derived($page.params.id);

	const weekPicks = $derived(picks.filter((pick) => pick.week_number === viewWeek));

	async function loadAdminData() {
		const user = auth.user;
		const id = leagueId;
		if (!user || !id) return;

		loading = true;
		error = null;

		const [leagueResult, syncResult, picksResult] = await Promise.all([
			fetchLeague(id, user.id),
			getSyncState(),
			fetchLeaguePicksAdmin(id)
		]);

		if (leagueResult.error || !leagueResult.league) {
			league = null;
			error = leagueResult.error ?? 'League not found.';
			loading = false;
			return;
		}

		league = leagueResult.league;

		if (!leagueResult.league.is_commissioner) {
			goto(`${base}/league/${id}`);
			return;
		}

		viewWeek = getCurrentWeekFromDate(qaNowDate(), leagueResult.league.season_year);
		syncState = syncResult.state;

		if (syncResult.error && !error) {
			error = syncResult.error;
		}

		if (picksResult.error) {
			error = picksResult.error;
			picks = [];
		} else {
			picks = picksResult.picks;
		}

		loading = false;
		await loadWeekGames();
	}

	async function loadWeekGames() {
		if (!league) return;

		const result = await fetchWeekGames(league.season_year, viewWeek);
		if (result.error) {
			actionError = result.error;
			games = [];
			return;
		}
		games = result.games;
	}

	function clearActionFeedback() {
		actionMessage = null;
		actionError = null;
	}

	function startOverride(pick: AdminPick) {
		clearActionFeedback();
		editingPickId = pick.id;
		overrideOutcome = pick.outcome === 'void' ? 'loss' : (pick.outcome as OverrideOutcome);
		overridePoints = String(pick.points_awarded);
		overrideNotes = pick.override_notes ?? '';
	}

	function cancelOverride() {
		editingPickId = null;
		overrideNotes = '';
	}

	function handleOutcomeChange(outcome: OverrideOutcome) {
		overrideOutcome = outcome;
		overridePoints = String(defaultPointsForOutcome(outcome));
	}

	async function confirmOverride(pick: AdminPick) {
		const points = Number(overridePoints);
		if (!Number.isFinite(points)) {
			actionError = 'Points must be a number.';
			return;
		}

		const summary = `${pick.display_name} Week ${pick.week_number}: ${pick.outcome} → ${overrideOutcome} (${points} pts)`;
		if (!confirm(`Apply override?\n\n${summary}`)) return;

		clearActionFeedback();
		busy = true;

		const result = await overridePick(
			pick.id,
			overrideOutcome,
			points,
			overrideNotes.trim() || undefined
		);

		busy = false;

		if (result.error) {
			actionError = result.error;
			return;
		}

		actionMessage = `Updated pick for ${pick.display_name}.`;
		editingPickId = null;
		await reloadPicks();
	}

	async function reloadPicks() {
		const id = leagueId;
		if (!id) return;

		const result = await fetchLeaguePicksAdmin(id);
		if (result.error) {
			actionError = result.error;
			return;
		}
		picks = result.picks;
	}

	function startMarkFinal(game: WeekGame) {
		clearActionFeedback();
		markingGameId = game.id;
		markHomeScore = game.home_score !== null ? String(game.home_score) : '';
		markAwayScore = game.away_score !== null ? String(game.away_score) : '';
	}

	function cancelMarkFinal() {
		markingGameId = null;
	}

	async function confirmMarkFinal(game: WeekGame) {
		const id = league?.id;
		if (!id) return;

		const homeScore = Number(markHomeScore);
		const awayScore = Number(markAwayScore);

		if (!Number.isInteger(homeScore) || !Number.isInteger(awayScore) || homeScore < 0 || awayScore < 0) {
			actionError = 'Enter valid non-negative integer scores.';
			return;
		}

		const label = `${game.away.abbreviation} @ ${game.home.abbreviation}: ${awayScore}–${homeScore}`;
		if (!confirm(`Mark this game final?\n\n${label}`)) return;

		clearActionFeedback();
		busy = true;

		const result = await updateGameStatus(id, game.id, 'final', {
			homeScore,
			awayScore,
			isTie: homeScore === awayScore
		});

		busy = false;

		if (result.error) {
			actionError = result.error;
			return;
		}

		actionMessage = `Marked ${label} as final and scored picks.`;
		markingGameId = null;
		await Promise.all([loadWeekGames(), reloadPicks()]);
	}

	async function handleRescore(game: WeekGame) {
		if (!confirm(`Re-score all pending picks for ${game.away.abbreviation} @ ${game.home.abbreviation}?`)) {
			return;
		}

		clearActionFeedback();
		busy = true;

		const result = await rescoreGame(game.id);
		busy = false;

		if (result.error) {
			actionError = result.error;
			return;
		}

		actionMessage = `Re-scored ${result.count} pick${result.count === 1 ? '' : 's'} for ${game.away.abbreviation} @ ${game.home.abbreviation}.`;
		await reloadPicks();
	}

	async function handleWeekChange(week: number) {
		viewWeek = week;
		markingGameId = null;
		editingPickId = null;
		await loadWeekGames();
	}

	$effect(() => {
		const user = auth.user;
		const id = leagueId;
		if (auth.loading || !user || !id) return;
		void loadAdminData();
	});
</script>

<main class="page page-admin">
	<div class="back-nav">
		<a href="{base}/league/{leagueId}" class="btn btn-ghost btn-sm">← Back to league</a>
	</div>

	{#if auth.loading || loading}
		<p class="muted">Loading commissioner tools…</p>
	{:else if error || !league}
		<p class="auth-error" role="alert">{error ?? 'League not found.'}</p>
	{:else}
		<h1 class="page-title">Commissioner Admin</h1>
		<p class="page-subtitle">{league.name} · {league.season_year} season</p>

		{#if actionMessage}
			<p class="action-ok" role="status">{actionMessage}</p>
		{/if}
		{#if actionError}
			<p class="auth-error" role="alert">{actionError}</p>
		{/if}

		<section class="card admin-panel">
			<h2 class="card-title">Sync status</h2>
			<p class="muted">Diagnostic view for when nflverse sync fails or data looks stale.</p>
			{#if syncState}
				<dl class="sync-dl">
					<div>
						<dt>Last synced</dt>
						<dd>{formatSyncTimeAgo(syncState.last_completed_at) ?? 'never'}</dd>
					</div>
					<div>
						<dt>Games updated</dt>
						<dd>{syncState.games_updated}</dd>
					</div>
					<div>
						<dt>Odds updated</dt>
						<dd>{syncState.odds_updated}</dd>
					</div>
					{#if syncState.last_started_at && !syncState.last_completed_at}
						<div>
							<dt>Status</dt>
							<dd>Sync in progress…</dd>
						</div>
					{/if}
				</dl>
				{#if syncState.last_error}
					<p class="sync-error" role="alert">Last error: {syncState.last_error}</p>
				{/if}
			{:else}
				<p class="muted">Sync state unavailable.</p>
			{/if}
		</section>

		<section class="card admin-panel">
			<h2 class="card-title">Pick overrides</h2>
			<p class="muted">Correct missed picks, disputes, or scoring errors. Changes are logged.</p>

			<WeekNavigator
				{viewWeek}
				onWeekChange={handleWeekChange}
				label="Week"
				compact
			/>

			{#if weekPicks.length === 0}
				<p class="muted panel-empty">No picks for Week {viewWeek}.</p>
			{:else}
				<div class="table-wrap">
					<table class="admin-table">
						<thead>
							<tr>
								<th>Player</th>
								<th>Team</th>
								<th>Outcome</th>
								<th>Pts</th>
								<th></th>
							</tr>
						</thead>
						<tbody>
							{#each weekPicks as pick (pick.id)}
								<tr
									class:row-missed={pick.is_missed}
									class:row-override={pick.is_commissioner_override}
								>
									<td>{pick.display_name}</td>
									<td>
										<span class="team-cell">
											<TeamLogo teamCode={pick.team_id} size={22} />
											{pick.team_abbreviation}
										</span>
									</td>
									<td>{outcomeLabel(pick.outcome)}</td>
									<td>{formatPoints(pick.points_awarded)}</td>
									<td class="actions-cell">
										{#if editingPickId === pick.id}
											<div class="inline-form">
												<label>
													Outcome
													<select
														value={overrideOutcome}
														disabled={busy}
														onchange={(e) =>
															handleOutcomeChange(
																(e.currentTarget as HTMLSelectElement)
																	.value as OverrideOutcome
															)}
													>
														{#each OUTCOME_OPTIONS as option (option)}
															<option value={option}>{outcomeLabel(option)}</option>
														{/each}
													</select>
												</label>
												<label>
													Points
													<input
														type="number"
														step="0.5"
														min="0"
														max="2"
														bind:value={overridePoints}
														disabled={busy}
													/>
												</label>
												<label class="notes-field">
													Notes
													<textarea
														rows="2"
														bind:value={overrideNotes}
														disabled={busy}
														placeholder="Optional reason for override"
													></textarea>
												</label>
												<div class="inline-actions">
													<button
														type="button"
														class="btn btn-primary btn-sm"
														disabled={busy}
														onclick={() => confirmOverride(pick)}
													>
														{busy ? 'Saving…' : 'Confirm'}
													</button>
													<button
														type="button"
														class="btn btn-ghost btn-sm"
														disabled={busy}
														onclick={cancelOverride}
													>
														Cancel
													</button>
												</div>
											</div>
										{:else}
											<button
												type="button"
												class="btn btn-ghost btn-sm"
												disabled={busy}
												onclick={() => startOverride(pick)}
											>
												Override
											</button>
										{/if}
									</td>
								</tr>
								{#if pick.is_commissioner_override && pick.override_notes}
									<tr class="notes-row">
										<td colspan="5">
											<span class="muted">Override note: {pick.override_notes}</span>
										</td>
									</tr>
								{/if}
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</section>

		<section class="card admin-panel">
			<h2 class="card-title">Game scoring</h2>
			<p class="muted">Manually mark a game final or re-run scoring if sync data was wrong.</p>

			{#if games.length === 0}
				<p class="muted panel-empty">No games loaded for Week {viewWeek}.</p>
			{:else}
				<ul class="game-list">
					{#each games as game (game.id)}
						<li class="game-item">
							<div class="game-summary">
								<span class="game-matchup">
									<TeamLogo teamCode={game.away.id} size={24} />
									{game.away.abbreviation}
									<span class="at">@</span>
									<TeamLogo teamCode={game.home.id} size={24} />
									{game.home.abbreviation}
								</span>
								<span class="game-meta">
									{formatGameKickoffShort(game.kickoff_at)} · {game.status}
									{#if game.home_score !== null && game.away_score !== null}
										· {game.away_score}–{game.home_score}
									{/if}
								</span>
							</div>

							<div class="game-actions">
								{#if markingGameId === game.id}
									<div class="inline-form mark-form">
										<label>
											Away ({game.away.abbreviation})
											<input type="number" min="0" bind:value={markAwayScore} disabled={busy} />
										</label>
										<label>
											Home ({game.home.abbreviation})
											<input type="number" min="0" bind:value={markHomeScore} disabled={busy} />
										</label>
										<div class="inline-actions">
											<button
												type="button"
												class="btn btn-primary btn-sm"
												disabled={busy}
												onclick={() => confirmMarkFinal(game)}
											>
												{busy ? 'Saving…' : 'Mark final'}
											</button>
											<button
												type="button"
												class="btn btn-ghost btn-sm"
												disabled={busy}
												onclick={cancelMarkFinal}
											>
												Cancel
											</button>
										</div>
									</div>
								{:else}
									{#if game.status !== 'final'}
										<button
											type="button"
											class="btn btn-ghost btn-sm"
											disabled={busy}
											onclick={() => startMarkFinal(game)}
										>
											Mark final
										</button>
									{/if}
									<button
										type="button"
										class="btn btn-ghost btn-sm"
										disabled={busy || game.status !== 'final'}
										onclick={() => handleRescore(game)}
									>
										Re-score picks
									</button>
								{/if}
							</div>
						</li>
					{/each}
				</ul>
			{/if}
		</section>
	{/if}
</main>

<style>
	.page-admin {
		max-width: 52rem;
	}

	.admin-panel + .admin-panel {
		margin-top: 1.25rem;
	}

	.sync-dl {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr));
		gap: 0.75rem 1.25rem;
		margin: 1rem 0 0;
	}

	.sync-dl dt {
		font-size: 0.78rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--text-muted);
	}

	.sync-dl dd {
		margin: 0.2rem 0 0;
		font-size: 1rem;
	}

	.sync-error {
		margin: 0.85rem 0 0;
		padding: 0.65rem 0.75rem;
		border-radius: var(--radius);
		background: var(--danger-muted);
		border: none;
		color: var(--danger);
		font-size: 0.9rem;
		box-shadow: var(--shadow-sm);
	}

	.action-ok {
		margin: 0 0 1rem;
		padding: 0.65rem 0.75rem;
		border-radius: var(--radius);
		background: var(--win-muted);
		border: none;
		color: var(--win-bg);
		font-size: 0.9rem;
		box-shadow: var(--shadow-sm);
	}

	.panel-empty {
		margin-top: 1rem;
	}

	.table-wrap {
		margin-top: 1rem;
		overflow-x: auto;
	}

	.admin-table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.9rem;
	}

	.admin-table th,
	.admin-table td {
		padding: 0.55rem 0.5rem;
		border-bottom: 1px solid var(--border);
		text-align: left;
		vertical-align: top;
	}

	.admin-table th {
		font-size: 0.78rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--text-muted);
	}

	.row-missed {
		background: var(--loss-muted);
	}

	.row-override {
		background: var(--brand-muted);
	}

	.team-cell {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
	}

	.actions-cell {
		min-width: 12rem;
	}

	.inline-form {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		min-width: 14rem;
	}

	.inline-form label {
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
		font-size: 0.78rem;
		color: var(--text-muted);
	}

	.inline-form select,
	.inline-form input,
	.inline-form textarea {
		padding: 0.45rem 0.55rem;
		border: 1px solid var(--border);
		border-radius: 8px;
		background: var(--bg);
		color: var(--text);
		font-size: 0.9rem;
	}

	.notes-field textarea {
		resize: vertical;
		min-height: 3rem;
	}

	.inline-actions {
		display: flex;
		gap: 0.45rem;
		flex-wrap: wrap;
	}

	.notes-row td {
		padding-top: 0;
		border-bottom: 1px solid var(--border);
		font-size: 0.82rem;
	}

	.game-list {
		list-style: none;
		margin: 1rem 0 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.game-item {
		padding: 0.75rem 0;
		border-bottom: 1px solid var(--border);
	}

	.game-item:last-child {
		border-bottom: none;
	}

	.game-summary {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.game-matchup {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		font-weight: 600;
	}

	.at {
		color: var(--text-muted);
		font-weight: 400;
	}

	.game-meta {
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.game-actions {
		margin-top: 0.65rem;
		display: flex;
		flex-wrap: wrap;
		gap: 0.45rem;
		align-items: flex-start;
	}

	.mark-form {
		flex-direction: row;
		flex-wrap: wrap;
		align-items: flex-end;
	}
</style>
