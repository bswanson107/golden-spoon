<script lang="ts">
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import {
		type PickVisibility,
		DEFAULT_PICK_VISIBILITY,
		isOpenPickVisibility,
		parsePickVisibility
	} from '$lib/leagueRules';
	import {
		normalizePickUserId,
		pickSubmissionKey,
		type PickSubmissionsByCell,
		type WeekPickSubmissionStatus
	} from '$lib/standings';
	import type { LeaguePick, PickOutcome } from '$lib/types/standings';

	type CellDisplay = 'empty' | 'hidden' | 'visible' | 'missed';

	let {
		picks,
		standings = [],
		currentUserId = null,
		viewWeek = null,
		pickSubmissions = {},
		pickVisibility = DEFAULT_PICK_VISIBILITY
	}: {
		picks: LeaguePick[];
		standings?: { user_id: string; display_name: string; standing_rank: number }[];
		currentUserId?: string | null;
		viewWeek?: number | null;
		/** `${userId}:${weekNumber}` → submission status for hidden picks. */
		pickSubmissions?: PickSubmissionsByCell;
		pickVisibility?: PickVisibility | string;
	} = $props();

	const resolvedPickVisibility = $derived(parsePickVisibility(pickVisibility));
	const picksAreOpen = $derived(isOpenPickVisibility(resolvedPickVisibility));

	const LOGO_SIZE = 24;

	const now = Date.now();
	const normalizedCurrentUserId = $derived(
		currentUserId ? normalizePickUserId(currentUserId) : null
	);

	const rankByUser = $derived(
		new Map(standings.map((s) => [normalizePickUserId(s.user_id), s.standing_rank]))
	);

	const weeks = $derived.by(() => {
		const fromPicks = picks.map((p) => p.week_number);
		const fromSubmissions = Object.keys(pickSubmissions).map((key) => {
			const separator = key.lastIndexOf(':');
			return separator === -1 ? 0 : Number(key.slice(separator + 1));
		});
		const allWeeks = [...new Set([...fromPicks, ...fromSubmissions])]
			.filter((week) => week > 0)
			.sort((a, b) => a - b);

		if (viewWeek !== null && viewWeek > 0) {
			return [viewWeek];
		}

		return allWeeks;
	});

	const players = $derived.by(() => {
		const byUser = new Map<string, { name: string; picks: Map<number, LeaguePick> }>();

		for (const row of standings) {
			byUser.set(normalizePickUserId(row.user_id), {
				name: row.display_name,
				picks: new Map()
			});
		}

		for (const pick of picks) {
			const userId = normalizePickUserId(pick.user_id);
			let entry = byUser.get(userId);
			if (!entry) {
				entry = { name: pick.display_name, picks: new Map() };
				byUser.set(userId, entry);
			}
			entry.picks.set(pick.week_number, pick);
		}

		return [...byUser.entries()]
			.map(([userId, data]) => ({ userId, ...data }))
			.sort((a, b) => {
				const rankA = rankByUser.get(a.userId) ?? 999;
				const rankB = rankByUser.get(b.userId) ?? 999;
				return rankA - rankB || a.name.localeCompare(b.name);
			});
	});

	const cellDisplays = $derived.by(() => {
		const displays = new Map<string, CellDisplay>();

		for (const player of players) {
			for (const week of weeks) {
				const key = pickSubmissionKey(player.userId, week);
				const pick = player.picks.get(week);
				const submission = pickSubmissions[key];
				displays.set(key, cellDisplay(pick, submission, resolvedPickVisibility));
			}
		}

		return displays;
	});

	function ringClass(outcome: PickOutcome, display: CellDisplay): string {
		if (display === 'missed') return 'ring-missed';
		if (display === 'hidden') return 'ring-hidden';
		if (display === 'empty') return 'ring-empty';

		switch (outcome) {
			case 'win':
				return 'ring-win';
			case 'loss':
				return 'ring-loss';
			case 'tie':
				return 'ring-tie';
			case 'missed':
				return 'ring-missed';
			default:
				return 'ring-pending';
		}
	}

	function cellDisplay(
		pick: LeaguePick | undefined,
		submission: WeekPickSubmissionStatus | undefined,
		visibility: PickVisibility
	): CellDisplay {
		if (pick?.is_missed || pick?.outcome === 'missed' || submission === 'missed') return 'missed';

		const hasSubmitted = pick !== undefined || submission === 'submitted';
		if (!hasSubmitted) return 'empty';

		if (pick) {
			if (isOpenPickVisibility(visibility)) return 'visible';
			const kickedOff = new Date(pick.kickoff_at).getTime() <= now;
			if (kickedOff) return 'visible';
		}

		return 'hidden';
	}

	function hiddenPickTitle(userId: string): string {
		return userId === normalizedCurrentUserId
			? 'Your pick is saved — team hidden until kickoff'
			: 'Pick saved — team hidden until kickoff';
	}
</script>

<div class="grid-wrap">
	<table class="picks-grid">
		<thead>
			<tr>
				<th scope="col" class="sticky player-col">Player</th>
				{#each weeks as week (week)}
					<th scope="col" class="week-col">{week}</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each players as player (player.userId)}
				<tr>
					<th scope="row" class="sticky player-col">{player.name}</th>
					{#each weeks as week (week)}
						{@const pick = player.picks.get(week)}
						{@const display =
							cellDisplays.get(pickSubmissionKey(player.userId, week)) ?? 'empty'}
						<td class="pick-cell">
							{#if display === 'hidden'}
								<span class="pick-ring ring-hidden" title={hiddenPickTitle(player.userId)}>
									<span class="ring-icon" aria-hidden="true">🔒</span>
								</span>
							{:else if display === 'missed'}
								<span class="pick-ring ring-missed" title="Missed pick">
									<span class="ring-icon ring-icon-missed" aria-hidden="true">×</span>
								</span>
							{:else if display === 'visible' && pick}
								<span
									class="pick-ring {ringClass(pick.outcome, display)}"
									title="{pick.team_abbreviation}{pick.outcome === 'win' && pick.is_underdog_at_pick
										? ' · Underdawg (2 pts)'
										: ''}{pick.is_commissioner_override ? ' · Commissioner override' : ''}"
								>
									<TeamLogo teamCode={pick.team_id} size={LOGO_SIZE} tile={false} />
									{#if pick.outcome === 'win' && pick.is_underdog_at_pick}
										<span class="chip-badge underdawg" title="Underdawg win (2 pts)">2</span>
									{/if}
									{#if pick.is_commissioner_override}
										<span class="chip-badge override" title="Commissioner override">✎</span>
									{/if}
								</span>
							{/if}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<p class="grid-legend muted">
	<span class="legend-ring ring-win"></span> win ·
	<span class="legend-ring ring-loss"></span> loss ·
	<span class="legend-ring ring-tie"></span> tie ·
	{#if !picksAreOpen}
		<span class="legend-ring ring-hidden"><span class="legend-lock">🔒</span></span> hidden pick ·
	{/if}
	<span class="legend-ring ring-missed"><span class="legend-missed">×</span></span> missed
</p>

<style>
	.grid-wrap {
		overflow-x: auto;
		max-width: 100%;
	}

	.picks-grid {
		border-collapse: separate;
		border-spacing: 0;
		font-size: 0.8rem;
		min-width: max-content;
		width: 100%;
	}

	th,
	td {
		padding: 0.35rem;
		border: none;
		background: transparent;
		text-align: center;
		vertical-align: middle;
	}

	thead th {
		color: var(--text-muted);
		font-weight: 600;
		font-size: 0.7rem;
		padding-bottom: 0.5rem;
	}

	.sticky {
		position: sticky;
		left: 0;
		z-index: 1;
		background: var(--surface);
	}

	.player-col {
		text-align: left;
		min-width: 6.5rem;
		max-width: 8rem;
		font-weight: 500;
		color: var(--text);
		padding-right: 0.65rem;
		background: var(--surface);
	}

	.week-col {
		width: 2.75rem;
		min-width: 2.75rem;
	}

	.pick-cell {
		width: 2.75rem;
		min-width: 2.75rem;
		height: 2.75rem;
		padding: 0.2rem;
	}

	.pick-ring {
		position: relative;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.25rem;
		height: 2.25rem;
		border-radius: 50%;
		background: #ffffff;
		border: 3px solid var(--ring-pending);
		box-sizing: border-box;
		flex-shrink: 0;
	}

	.ring-win {
		border-color: var(--ring-win);
	}

	.ring-loss {
		border-color: var(--ring-loss);
	}

	.ring-tie {
		border-color: var(--ring-tie);
	}

	.ring-pending {
		border-color: var(--ring-pending);
	}

	.ring-missed {
		border-color: var(--ring-loss);
	}

	.ring-hidden {
		border-color: var(--ring-pending);
	}

	.ring-icon {
		font-size: 0.85rem;
		line-height: 1;
	}

	.ring-icon-missed {
		font-size: 1.1rem;
		font-weight: 700;
		color: var(--ring-loss);
	}

	.chip-badge {
		position: absolute;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-width: 0.85rem;
		height: 0.85rem;
		padding: 0 0.15rem;
		border-radius: var(--radius);
		font-size: 0.55rem;
		font-weight: 800;
		line-height: 1;
		box-shadow: var(--shadow-sm);
	}

	.chip-badge.underdawg {
		top: -0.15rem;
		right: -0.2rem;
		background: var(--brand);
		color: var(--brand-text);
	}

	.chip-badge.override {
		bottom: -0.15rem;
		right: -0.2rem;
		background: var(--surface-2);
		color: var(--text-muted);
		font-size: 0.6rem;
	}

	.grid-legend {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.35rem 0.65rem;
		margin: 0.75rem 0 0;
		font-size: 0.78rem;
		line-height: 1.4;
	}

	.legend-ring {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 0.85rem;
		height: 0.85rem;
		border-radius: 50%;
		background: #ffffff;
		border: 2px solid var(--ring-pending);
		vertical-align: middle;
		margin-right: 0.15rem;
	}

	.legend-ring.ring-win {
		border-color: var(--ring-win);
	}

	.legend-ring.ring-loss,
	.legend-ring.ring-missed {
		border-color: var(--ring-loss);
	}

	.legend-ring.ring-tie {
		border-color: var(--ring-tie);
	}

	.legend-ring.ring-pending,
	.legend-ring.ring-hidden {
		border-color: var(--ring-pending);
	}

	.legend-lock {
		font-size: 0.45rem;
		line-height: 1;
	}

	.legend-missed {
		font-size: 0.55rem;
		font-weight: 700;
		color: var(--ring-loss);
		line-height: 1;
	}
</style>
