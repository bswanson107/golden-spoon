<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import { isAppAdmin } from '$lib/admin';
	import { fetchWeekGames } from '$lib/games';
	import { formatGameKickoffShort } from '$lib/gameKickoff';
	import {
		clearQaClock,
		isQaClockEnabled,
		qaNowDate,
		qaSimulatedNowMs,
		setQaClock
	} from '$lib/qaClock.svelte';
	import {
		qaResetAll,
		qaResetWeek,
		qaSetGameResult,
		qaSetGameWinPct,
		qaSimulateWeek,
		runQaProcessing,
		type GameResult
	} from '$lib/qa';
	import type { WeekGame } from '$lib/types/game';

	const auth = useAuth();

	const isAdmin = $derived(!auth.loading && auth.user !== null && isAppAdmin(auth.user.email));

	$effect(() => {
		if (auth.loading) return;
		if (!auth.user || !isAppAdmin(auth.user.email)) {
			goto(`${base}/`);
		}
	});

	let seasonYear = $state(2026);
	let week = $state(1);
	let games = $state<WeekGame[]>([]);
	let loadingGames = $state(false);
	let busy = $state(false);
	let message = $state<string | null>(null);
	let errorMsg = $state<string | null>(null);

	let clockInput = $state('');
	const clockEnabled = $derived(isQaClockEnabled());
	const simulatedMs = $derived(qaSimulatedNowMs());

	const winPctDraft = $state<Record<string, { home: string; away: string }>>({});

	function pad(n: number): string {
		return String(n).padStart(2, '0');
	}

	function toLocalInput(ms: number): string {
		const d = new Date(ms);
		return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
	}

	function feedback(msg: string | null, err: string | null) {
		message = msg;
		errorMsg = err;
	}

	async function loadGames() {
		loadingGames = true;
		const result = await fetchWeekGames(seasonYear, week);
		if (result.error) {
			feedback(null, result.error);
			games = [];
		} else {
			games = result.games;
			for (const g of games) {
				winPctDraft[g.id] = {
					home: g.home_win_pct !== null ? String(g.home_win_pct) : '',
					away: g.away_win_pct !== null ? String(g.away_win_pct) : ''
				};
			}
		}
		loadingGames = false;
	}

	$effect(() => {
		if (!isAdmin) return;
		// re-run when season/week change
		void seasonYear;
		void week;
		loadGames();
	});

	// Seed the datetime input from the current (simulated or live) clock.
	$effect(() => {
		if (!clockInput) {
			clockInput = toLocalInput(simulatedMs ?? qaNowDate().getTime());
		}
	});

	function errorText(err: unknown): string {
		if (err instanceof Error) return err.message;
		return typeof err === 'string' ? err : 'Unexpected error';
	}

	async function applyClock() {
		if (!clockInput) return;
		const ms = new Date(clockInput).getTime();
		if (Number.isNaN(ms)) {
			feedback(null, 'Invalid date/time');
			return;
		}
		busy = true;
		try {
			const { error } = await setQaClock(new Date(ms));
			feedback(error ? null : `Clock set to ${new Date(ms).toLocaleString()}`, error);
		} catch (err) {
			feedback(null, errorText(err));
		} finally {
			busy = false;
		}
	}

	async function resetClock() {
		busy = true;
		try {
			const { error } = await clearQaClock();
			clockInput = toLocalInput(Date.now());
			feedback(error ? null : 'Clock reset to live time', error);
		} catch (err) {
			feedback(null, errorText(err));
		} finally {
			busy = false;
		}
	}

	async function setClockMs(ms: number) {
		busy = true;
		try {
			const { error } = await setQaClock(new Date(ms));
			clockInput = toLocalInput(ms);
			feedback(error ? null : `Clock set to ${new Date(ms).toLocaleString()}`, error);
		} catch (err) {
			feedback(null, errorText(err));
		} finally {
			busy = false;
		}
	}

	function currentMs(): number {
		return simulatedMs ?? Date.now();
	}

	async function bump(minutes: number) {
		await setClockMs(currentMs() + minutes * 60_000);
	}

	async function jumpToWeekFirstKickoff() {
		if (games.length === 0) return;
		const first = games.reduce((a, b) => (a.kickoff_at < b.kickoff_at ? a : b));
		await setClockMs(new Date(first.kickoff_at).getTime());
	}

	async function jumpToWeekLastKickoff() {
		if (games.length === 0) return;
		const last = games.reduce((a, b) => (a.kickoff_at > b.kickoff_at ? a : b));
		await setClockMs(new Date(last.kickoff_at).getTime());
	}

	async function jumpToNextKickoff() {
		const now = currentMs();
		const upcoming = games
			.map((g) => new Date(g.kickoff_at).getTime())
			.filter((t) => t > now)
			.sort((a, b) => a - b);
		if (upcoming.length === 0) {
			feedback(null, 'No upcoming kickoffs this week');
			return;
		}
		await setClockMs(upcoming[0]);
	}

	async function runAction<T>(fn: () => Promise<T & { error: string | null }>, ok: string) {
		busy = true;
		feedback(null, null);
		try {
			const res = await fn();
			if (res.error) {
				feedback(null, res.error);
			} else {
				feedback(ok, null);
				await loadGames();
			}
		} catch (err) {
			feedback(null, errorText(err));
		} finally {
			busy = false;
		}
	}

	async function simulateWeek(result: GameResult) {
		await runAction(
			() => qaSimulateWeek(seasonYear, week, result),
			`Simulated week ${week} (${result} result)`
		);
	}

	async function setGameResult(gameId: string, result: GameResult) {
		await runAction(() => qaSetGameResult(gameId, result), 'Game result applied');
	}

	async function applyWinPct(game: WeekGame) {
		const draft = winPctDraft[game.id];
		if (!draft) return;
		const home = Number(draft.home);
		const away = Number(draft.away);
		if (Number.isNaN(home) || Number.isNaN(away)) {
			feedback(null, 'Win % values must be numbers');
			return;
		}
		await runAction(() => qaSetGameWinPct(game.id, home, away), 'Win % overridden');
	}

	async function resetWeek() {
		await runAction(() => qaResetWeek(seasonYear, week), `Week ${week} reset`);
	}

	async function resetAll() {
		if (!confirm(`Reset ALL of season ${seasonYear} back to scheduled?`)) return;
		await runAction(() => qaResetAll(seasonYear), `Season ${seasonYear} reset`);
	}

	async function runProcessing() {
		busy = true;
		feedback(null, null);
		try {
			const { result, error } = await runQaProcessing(seasonYear);
			if (error) {
				feedback(null, error);
			} else {
				feedback(
					`Processing done — kickoff locks: ${result?.kickoffLocksApplied ?? 0}, auto/missed assigned: ${result?.autoOrMissedAssigned ?? 0}`,
					null
				);
				await loadGames();
			}
		} catch (err) {
			feedback(null, errorText(err));
		} finally {
			busy = false;
		}
	}

	const weekOptions = Array.from({ length: 18 }, (_, i) => i + 1);
</script>

<svelte:head><title>QA Mode · Golden Spoon</title></svelte:head>

{#if isAdmin}
	<div class="qa-page">
		<header class="qa-head">
			<h1>QA Mode</h1>
			<p class="muted">
				Admin-only test harness. Time travel and game simulation affect the live database.
				Disable the GitHub sync workflow while simulating so nflverse does not overwrite games.
			</p>
		</header>

		{#if message}<p class="alert ok">{message}</p>{/if}
		{#if errorMsg}<p class="alert err">{errorMsg}</p>{/if}

		<section class="card">
			<h2>Clock</h2>
			<p class="status">
				Status:
				{#if clockEnabled && simulatedMs !== null}
					<strong class="on">SIMULATED</strong> — {new Date(simulatedMs).toLocaleString()}
				{:else}
					<strong>LIVE</strong> (real time)
				{/if}
			</p>

			<div class="row">
				<input type="datetime-local" bind:value={clockInput} disabled={busy} />
				<button class="btn primary" onclick={applyClock} disabled={busy}>Set clock</button>
				<button class="btn" onclick={resetClock} disabled={busy}>Reset to live</button>
			</div>

			<div class="row wrap">
				<button class="btn sm" onclick={() => bump(-60)} disabled={busy}>-1 hr</button>
				<button class="btn sm" onclick={() => bump(-15)} disabled={busy}>-15 min</button>
				<button class="btn sm" onclick={() => bump(-1)} disabled={busy}>-1 min</button>
				<button class="btn sm" onclick={() => bump(1)} disabled={busy}>+1 min</button>
				<button class="btn sm" onclick={() => bump(15)} disabled={busy}>+15 min</button>
				<button class="btn sm" onclick={() => bump(60)} disabled={busy}>+1 hr</button>
			</div>

			<div class="row wrap">
				<button class="btn sm" onclick={jumpToWeekFirstKickoff} disabled={busy}>
					Jump to week first kickoff
				</button>
				<button class="btn sm" onclick={jumpToNextKickoff} disabled={busy}>
					Advance to next kickoff
				</button>
				<button class="btn sm" onclick={jumpToWeekLastKickoff} disabled={busy}>
					Jump to last (MNF) kickoff
				</button>
			</div>
		</section>

		<section class="card">
			<h2>Week simulation</h2>
			<div class="row wrap">
				<label>Season <input type="number" bind:value={seasonYear} disabled={busy} /></label>
				<label>
					Week
					<select bind:value={week} disabled={busy}>
						{#each weekOptions as w (w)}<option value={w}>{w}</option>{/each}
					</select>
				</label>
			</div>

			<div class="row wrap">
				<button class="btn primary" onclick={() => simulateWeek('home')} disabled={busy}>
					Default: home wins
				</button>
				<button class="btn" onclick={() => simulateWeek('away')} disabled={busy}>
					All away wins
				</button>
				<button class="btn" onclick={() => simulateWeek('tie')} disabled={busy}>All ties</button>
				<button class="btn warn" onclick={resetWeek} disabled={busy}>Reset week</button>
				<button class="btn warn" onclick={resetAll} disabled={busy}>Reset season</button>
			</div>

			<div class="row">
				<button class="btn primary" onclick={runProcessing} disabled={busy}>
					Run week processing (kickoff lock + auto-MNF / missed)
				</button>
			</div>

			{#if loadingGames}
				<p class="muted">Loading games…</p>
			{:else if games.length === 0}
				<p class="muted">No games found for {seasonYear} week {week}.</p>
			{:else}
				<table class="games">
					<thead>
						<tr>
							<th>Matchup</th>
							<th>Kickoff</th>
							<th>Status</th>
							<th>Result</th>
							<th>Win % (away / home)</th>
						</tr>
					</thead>
					<tbody>
						{#each games as game (game.id)}
							<tr>
								<td>{game.away.abbreviation} @ {game.home.abbreviation}</td>
								<td>{formatGameKickoffShort(game.kickoff_at)}</td>
								<td>
									<span class="pill" class:final={game.status === 'final'}>{game.status}</span>
									{#if game.status === 'final'}
										<small>
											{game.is_tie
												? 'tie'
												: game.winner_team_id === game.home.id
													? `${game.home.abbreviation} won`
													: `${game.away.abbreviation} won`}
										</small>
									{/if}
								</td>
								<td class="nowrap">
									<button class="btn xs" onclick={() => setGameResult(game.id, 'away')} disabled={busy}>
										Away
									</button>
									<button class="btn xs" onclick={() => setGameResult(game.id, 'home')} disabled={busy}>
										Home
									</button>
									<button class="btn xs" onclick={() => setGameResult(game.id, 'tie')} disabled={busy}>
										Tie
									</button>
								</td>
								<td class="nowrap">
									{#if winPctDraft[game.id]}
										<input
											class="pct"
											type="number"
											bind:value={winPctDraft[game.id].away}
											disabled={busy}
										/>
										/
										<input
											class="pct"
											type="number"
											bind:value={winPctDraft[game.id].home}
											disabled={busy}
										/>
										<button class="btn xs" onclick={() => applyWinPct(game)} disabled={busy}>
											Set
										</button>
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{/if}
		</section>
	</div>
{:else}
	<p class="muted center">Not authorized.</p>
{/if}

<style>
	.qa-page {
		max-width: 60rem;
		margin: 0 auto;
		padding: 1.25rem 1rem 4rem;
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.qa-head h1 {
		margin: 0 0 0.25rem;
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.85rem;
	}

	.center {
		text-align: center;
		margin-top: 3rem;
	}

	.card {
		background: var(--surface);
		border-radius: var(--radius);
		box-shadow: var(--shadow-sm);
		padding: 1rem 1.1rem;
	}

	.card h2 {
		margin: 0 0 0.75rem;
		font-size: 1.05rem;
	}

	.status {
		font-size: 0.85rem;
		margin: 0 0 0.75rem;
	}

	.status .on {
		color: var(--danger, #b91c1c);
	}

	.row {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 0.6rem;
	}

	.row.wrap {
		flex-wrap: wrap;
	}

	.row label {
		display: inline-flex;
		flex-direction: column;
		font-size: 0.78rem;
		gap: 0.2rem;
		color: var(--text-muted);
	}

	input,
	select {
		font: inherit;
		padding: 0.4rem 0.5rem;
		border-radius: var(--radius);
		border: 1px solid var(--border);
		background: var(--surface-2);
		color: var(--text);
	}

	input[type='number'] {
		width: 6rem;
	}

	.pct {
		width: 4rem;
	}

	.btn {
		font: inherit;
		font-weight: 600;
		padding: 0.45rem 0.7rem;
		border: 1px solid var(--border);
		border-radius: var(--radius);
		background: var(--surface-2);
		color: var(--text);
		cursor: pointer;
	}

	.btn:disabled {
		opacity: 0.55;
		cursor: not-allowed;
	}

	.btn.primary {
		background: var(--brand);
		color: var(--brand-text);
		border-color: transparent;
	}

	.btn.warn {
		color: var(--danger, #b91c1c);
		border-color: var(--danger, #b91c1c);
	}

	.btn.sm {
		padding: 0.3rem 0.55rem;
		font-size: 0.8rem;
	}

	.btn.xs {
		padding: 0.2rem 0.45rem;
		font-size: 0.75rem;
	}

	.alert {
		margin: 0;
		padding: 0.6rem 0.8rem;
		border-radius: var(--radius);
		font-size: 0.85rem;
	}

	.alert.ok {
		background: color-mix(in srgb, green 14%, var(--surface));
		color: var(--text);
	}

	.alert.err {
		background: color-mix(in srgb, var(--danger, #b91c1c) 16%, var(--surface));
		color: var(--text);
	}

	.games {
		width: 100%;
		border-collapse: collapse;
		margin-top: 0.75rem;
		font-size: 0.82rem;
	}

	.games th,
	.games td {
		text-align: left;
		padding: 0.4rem 0.5rem;
		border-bottom: 1px solid var(--border);
		vertical-align: middle;
	}

	.nowrap {
		white-space: nowrap;
	}

	.pill {
		display: inline-block;
		padding: 0.05rem 0.4rem;
		border-radius: 999px;
		background: var(--surface-2);
		font-size: 0.72rem;
		text-transform: uppercase;
		letter-spacing: 0.03em;
	}

	.pill.final {
		background: color-mix(in srgb, green 22%, var(--surface));
	}

	td small {
		display: block;
		color: var(--text-muted);
		font-size: 0.72rem;
	}
</style>
