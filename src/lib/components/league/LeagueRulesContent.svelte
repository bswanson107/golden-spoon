<script lang="ts">
	import {
		type PickVisibility,
		type TiebreakerMode,
		pickVisibilityDescription,
		tiebreakerDescription
	} from '$lib/leagueRules';

	let {
		threshold,
		tiebreakerMode,
		pickVisibility
	}: {
		threshold: number;
		tiebreakerMode: TiebreakerMode;
		pickVisibility: PickVisibility;
	} = $props();
</script>

<section class="rules-section">
	<h3 class="rules-heading">Scoring</h3>
	<ul class="rules-list">
		<li><strong>Win</strong> (favorite): 1 point</li>
		<li><strong>Underdog win</strong>: 2 points</li>
		<li><strong>Loss</strong>: 0 points</li>
		<li><strong>Tie</strong>: 0.5 points</li>
		<li><strong>No pick</strong> by the week's last kickoff: 0 points (counts as a loss)</li>
	</ul>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Underdog</h3>
	<p>
		An <strong>underdog</strong> is a team with win probability of
		<strong>{threshold}% or lower</strong> at kickoff. Underdog wins earn the 2-point bonus.
	</p>
	<p class="rules-note">
		Win % is shown on each game card and snapshotted at your picked team's kickoff time.
	</p>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Pick deadline</h3>
	<p>
		You must submit your pick <strong>before that team's game kicks off</strong> — not at midnight
		Sunday. You can plan picks early in the week and
		<strong>change them anytime before kickoff</strong>.
	</p>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Pick visibility</h3>
	<p>{pickVisibilityDescription(pickVisibility)}</p>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Team reuse</h3>
	<p>Each team can only be picked <strong>once per season</strong> by the same player.</p>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Missed picks</h3>
	<p>
		If you don't submit a pick before the week's <strong>last game</strong> kicks off, the system
		records a missed pick automatically (0 points).
	</p>
	<p class="rules-note">The commissioner can override missed picks in exceptional cases.</p>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Standings tiebreaker</h3>
	<p>
		Standings rank by total points. {tiebreakerDescription(tiebreakerMode)}
	</p>
</section>

<section class="rules-section">
	<h3 class="rules-heading">Other policies</h3>
	<ul class="rules-list">
		<li><strong>Postponed games</strong>: your original pick stands; scored when the game is played.</li>
		<li><strong>Season scope</strong>: regular season only (Weeks 1–18).</li>
		<li><strong>Entries</strong>: one entry per person per league.</li>
	</ul>
</section>

<style>
	.rules-section {
		margin-bottom: 1.1rem;
	}

	.rules-section:last-child {
		margin-bottom: 0;
	}

	.rules-heading {
		margin: 0 0 0.45rem;
		font-size: 0.95rem;
		font-weight: 700;
		color: var(--text);
	}

	.rules-section p {
		margin: 0 0 0.5rem;
		font-size: 0.9rem;
		line-height: 1.5;
		color: var(--text);
	}

	.rules-section p:last-child {
		margin-bottom: 0;
	}

	.rules-note {
		color: var(--text-muted);
		font-size: 0.85rem;
	}

	.rules-list {
		margin: 0;
		padding-left: 1.25rem;
		font-size: 0.9rem;
		line-height: 1.55;
		color: var(--text);
	}

	.rules-list li {
		margin: 0.3rem 0;
	}
</style>
