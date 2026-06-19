<script lang="ts">
	import { base } from '$app/paths';
	import GameKickoffInfo from '$lib/components/pick/GameKickoffInfo.svelte';
	import WinPctBar from '$lib/components/pick/WinPctBar.svelte';
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import { formatPoints, outcomeLabel } from '$lib/demo';
	import PickKickoffCountdown from '$lib/components/league/PickKickoffCountdown.svelte';
	import type { PickCtaState } from '$lib/leaguePickStatus';
	import type { WeekGame } from '$lib/types/game';
	import type { LeaguePick } from '$lib/types/standings';

	let {
		leagueId,
		week,
		pickCta,
		userPick = null,
		game = null
	}: {
		leagueId: string;
		week: number;
		pickCta: PickCtaState;
		userPick?: LeaguePick | null;
		game?: WeekGame | null;
	} = $props();

	const pickUrl = $derived(`${base}/league/${leagueId}/pick`);

	const matchup = $derived.by(() => {
		if (!userPick || !game) return null;

		const isHome = userPick.team_id === game.home.id;
		const opponent = isHome ? game.away : game.home;

		return {
			isHome,
			opponent,
			awayCode: game.away.abbreviation,
			homeCode: game.home.abbreviation
		};
	});

	const outcomeClass = $derived.by(() => {
		if (!userPick) return null;
		switch (userPick.outcome) {
			case 'win':
				return 'outcome-win';
			case 'loss':
			case 'missed':
				return 'outcome-loss';
			case 'tie':
				return 'outcome-tie';
			default:
				return 'outcome-pending';
		}
	});
</script>

{#if pickCta.kind === 'needs_pick'}
	<section class="dashboard dashboard-action" aria-labelledby="pick-action-heading">
		<div class="action-body">
			<p class="action-eyebrow">Week {week}</p>
			<h2 id="pick-action-heading" class="action-title">Make your pick</h2>
			<PickKickoffCountdown kickoffAt={pickCta.nextKickoff} />
			<p class="action-copy">
				{#if pickCta.gamesStarted > 0}
					Some games started — pick from what's left before each kickoff.
				{:else}
					Pick any game before it kicks off.
				{/if}
			</p>
		</div>
		<a href={pickUrl} class="btn btn-primary">Pick now →</a>
	</section>
{:else if pickCta.kind === 'submitted' && userPick}
	<section class="dashboard dashboard-pick" aria-labelledby="pick-hero-heading">
		<div class="pick-hero">
			{#if pickCta.changeable}
				<a href={pickUrl} class="btn btn-ghost btn-sm change-link">Change pick</a>
			{/if}

			<div class="pick-logo">
				<TeamLogo teamCode={userPick.team_id} size={100} className="pick-hero-logo" />
			</div>

			<div class="pick-content">
				<div class="pick-badges">
					<span class="badge badge-pick">Your pick</span>
					{#if userPick.is_underdog_at_pick}
						<span class="badge badge-underdawg">Underdawg · 2 pts</span>
					{/if}
					{#if userPick.outcome !== 'pending'}
						<span class="badge {outcomeClass}">
							{outcomeLabel(userPick.outcome)}
							{#if userPick.outcome !== 'missed' && userPick.outcome !== 'void'}
								· {formatPoints(userPick.points_awarded)} pts
							{/if}
						</span>
					{/if}
				</div>

				<h2 id="pick-hero-heading" class="pick-team">{userPick.team_name}</h2>

				{#if matchup}
					<p class="pick-matchup">
						{#if matchup.isHome}
							Home vs <strong>{matchup.opponent.city} {matchup.opponent.name}</strong>
						{:else}
							Away @ <strong>{matchup.opponent.city} {matchup.opponent.name}</strong>
						{/if}
					</p>
				{/if}

				<p class="pick-week">Week {week}</p>
			</div>
		</div>

		{#if game}
			<div class="pick-details">
				<GameKickoffInfo kickoffAt={game.kickoff_at} />
				<WinPctBar
					awayTeamCode={game.away.id}
					homeTeamCode={game.home.id}
					awayTeamName={game.away.name}
					homeTeamName={game.home.name}
					awayWinPct={game.away_win_pct}
					homeWinPct={game.home_win_pct}
					pickedTeamCode={userPick.team_id}
				/>
			</div>
		{:else if userPick.kickoff_at}
			<div class="pick-details">
				<GameKickoffInfo kickoffAt={userPick.kickoff_at} />
			</div>
		{/if}

		{#if pickCta.changeable}
			<p class="pick-note">Your pick stays hidden from others until kickoff.</p>
		{/if}
	</section>
{:else if pickCta.kind === 'closed'}
	<section class="dashboard dashboard-closed" aria-labelledby="pick-closed-heading">
		<h2 id="pick-closed-heading" class="closed-title">Week {week}</h2>
		{#if userPick && !userPick.is_missed}
			<p class="closed-copy">
				You're locked in on <strong>{userPick.team_abbreviation}</strong>.
				{#if userPick.outcome !== 'pending'}
					Result: {outcomeLabel(userPick.outcome)} ({formatPoints(userPick.points_awarded)} pts).
				{:else}
					Waiting on the result.
				{/if}
			</p>
		{:else}
			<p class="closed-copy">This week's pick window has closed.</p>
		{/if}
	</section>
{/if}

<style>
	.dashboard {
		margin-top: 1.25rem;
		padding: 1.35rem 1.4rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow);
	}

	.dashboard-action {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 1.25rem;
		background: var(--brand-muted);
	}

	.action-body {
		flex: 1;
		min-width: 0;
	}

	.action-eyebrow {
		margin: 0 0 0.25rem;
		font-size: 0.78rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--text-muted);
	}

	.action-title {
		margin: 0 0 0.4rem;
		font-family: var(--font-display);
		font-size: 1.65rem;
		line-height: 1.1;
		color: var(--text);
	}

	.action-copy {
		margin: 0.55rem 0 0;
		font-size: 0.9rem;
		color: var(--text-muted);
		max-width: 36rem;
	}

	.dashboard-pick {
		display: flex;
		flex-direction: column;
		gap: 1.1rem;
	}

	.pick-hero {
		display: flex;
		align-items: stretch;
		gap: 1.1rem;
		position: relative;
	}

	.pick-logo {
		flex-shrink: 0;
		display: flex;
		align-self: stretch;
		line-height: 0;
	}

	.pick-logo :global(.pick-hero-logo) {
		height: 100%;
		width: auto !important;
		aspect-ratio: 1;
		min-width: 4.5rem;
	}

	.pick-logo :global(.pick-hero-logo .team-logo) {
		width: 68% !important;
		height: 68% !important;
	}

	.pick-content {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
	}

	.pick-badges {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4rem;
		margin-bottom: 0.45rem;
		padding-right: 6.5rem;
	}

	.pick-team {
		margin: 0 0 0.35rem;
		font-family: var(--font-display);
		font-size: clamp(1.5rem, 4vw, 2rem);
		line-height: 1.05;
		color: var(--text);
	}

	.pick-matchup {
		margin: 0 0 0.25rem;
		font-size: 1rem;
		color: var(--text-muted);
	}

	.pick-week {
		margin: 0;
		margin-top: auto;
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.badge {
		display: inline-block;
		font-size: 0.72rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		padding: 0.22rem 0.45rem;
		border-radius: var(--radius);
		box-shadow: var(--shadow-sm);
	}

	.badge-pick {
		background: var(--win-bg);
		color: var(--win-text);
	}

	.badge-underdawg {
		background: var(--brand);
		color: var(--brand-text);
	}

	.outcome-win {
		background: var(--win-bg);
		color: var(--win-text);
	}

	.outcome-loss {
		background: var(--loss-bg);
		color: var(--loss-text);
	}

	.outcome-tie {
		background: var(--tie-bg);
		color: var(--tie-text);
	}

	.outcome-pending {
		background: var(--pending-bg);
		color: var(--pending-text);
	}

	.pick-matchup strong {
		color: var(--text);
		font-weight: 600;
	}

	.change-link {
		position: absolute;
		top: 0;
		right: 0;
	}

	.pick-details {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
		padding-top: 0.25rem;
		border-top: 1px solid var(--border);
	}

	.pick-note {
		margin: 0;
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.dashboard-closed {
		background: var(--surface-2);
		box-shadow: var(--shadow-sm);
	}

	.closed-title {
		margin: 0 0 0.35rem;
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
	}

	.closed-copy {
		margin: 0;
		font-size: 0.92rem;
		color: var(--text-muted);
	}

	@media (max-width: 640px) {
		.dashboard-action {
			flex-direction: column;
			align-items: stretch;
		}

		.pick-badges {
			padding-right: 0;
		}

		.pick-hero {
			flex-wrap: wrap;
		}

		.change-link {
			position: static;
			align-self: flex-start;
			width: 100%;
			margin-top: 0.5rem;
			text-align: center;
		}
	}
</style>
