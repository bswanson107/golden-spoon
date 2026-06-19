<script lang="ts">
	import GameCard from '$lib/components/pick/GameCard.svelte';
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import { getTeamSurfaceTint } from '$lib/data/nflTeams';
	import { week1Games2026 } from './week1Games2026';

	type Theme = 'dark' | 'light';

	let theme = $state<Theme>('dark');

	/** Demo pick on one game so picked / underdog states are visible */
	const demoPickGameId = '2026_01_NYJ_TEN';
	const demoPickTeamId = 'NYJ';

	const sampleTeams = [
		{ code: 'NYJ', name: 'Jets', note: 'White / green — light tile' },
		{ code: 'LAR', name: 'Rams', note: 'Gold / blue — warm tile' },
		{ code: 'CLE', name: 'Browns', note: 'Brown / orange — dark tile' },
		{ code: 'NYG', name: 'Giants', note: 'Gray / blue — neutral tile' }
	] as const;

	function toggleTheme() {
		theme = theme === 'dark' ? 'light' : 'dark';
	}
</script>

<svelte:head>
	<title>Design demo — Golden Spoon</title>
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link
		href="https://fonts.googleapis.com/css2?family=Archivo+Black&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

<!-- Full-screen shell covers app chrome — styles scoped to this page only -->
<div class="design-shell" data-theme={theme}>
	<header class="topbar">
		<div class="topbar-brand">
			<span class="brand-mark">GL</span>
			<span class="brand-label">Design demo</span>
		</div>
		<button type="button" class="theme-toggle" onclick={toggleTheme}>
			{theme === 'dark' ? '☀ Light' : '☾ Dark'}
		</button>
	</header>

	<main class="canvas">
		<section class="float-block hero-block">
			<p class="eyebrow">Golden Spoon · draft 1</p>
			<h1 class="display">Pick bold.<br /><span class="display-accent">Score loud.</span></h1>
			<p class="lead">
				Hard contrast, soft offset shadows, components floating in open space. Mostly neutral
				chrome with gold accents — team colors and status badges carry the rest.
			</p>
			<div class="btn-row">
				<button type="button" class="ds-btn ds-btn-primary">Make your pick</button>
				<button type="button" class="ds-btn ds-btn-secondary">View standings</button>
				<button type="button" class="ds-btn ds-btn-ghost">Rules</button>
			</div>
		</section>

		<section class="float-block">
			<h2 class="section-title">Typography</h2>
			<h3 class="subsection-title">Week 3 · pick before Thu 8:20 PM ET</h3>
			<p class="body">
				Body copy at comfortable size. Win probability is snapshotted at kickoff. Underdog wins
				earn double points when the team is at or below the league threshold.
			</p>
			<p class="body-muted">
				Muted supporting text — tiebreaker uses cumulative picked-team season wins (lower is
				better).
			</p>
			<ul class="bullet-list">
				<li>One pick per week, one use per team per season</li>
				<li>Picks hidden until your game kicks off</li>
				<li>Change your pick anytime before kickoff</li>
				<li>Missed pick = 0 points after the week's last game</li>
			</ul>
		</section>

		<section class="float-block">
			<h2 class="section-title">Buttons &amp; inputs</h2>
			<div class="btn-row">
				<button type="button" class="ds-btn ds-btn-primary">Primary</button>
				<button type="button" class="ds-btn ds-btn-secondary">Secondary</button>
				<button type="button" class="ds-btn ds-btn-ghost">Ghost</button>
				<button type="button" class="ds-btn ds-btn-danger">Danger</button>
				<button type="button" class="ds-btn ds-btn-primary" disabled>Disabled</button>
			</div>
			<div class="btn-row">
				<button type="button" class="ds-btn ds-btn-primary ds-btn-sm">Small primary</button>
				<button type="button" class="ds-btn ds-btn-ghost ds-btn-sm">Small ghost</button>
			</div>
			<form class="form-stack" onsubmit={(e) => e.preventDefault()}>
				<label class="field">
					<span class="field-label">Display name</span>
					<input type="text" placeholder="Grandma" value="Katherine" />
				</label>
				<label class="field">
					<span class="field-label">Invite code</span>
					<input type="text" placeholder="abc123" />
				</label>
				<label class="field">
					<span class="field-label">Commissioner notes</span>
					<textarea rows="3" placeholder="Optional override reason…"></textarea>
				</label>
				<label class="field">
					<span class="field-label">Week</span>
					<select>
						<option>Week 1</option>
						<option selected>Week 3</option>
						<option>Week 12</option>
					</select>
				</label>
			</form>
		</section>

		<section class="float-block">
			<h2 class="section-title">Team logos</h2>
			<p class="body-muted">Diverse tile backgrounds — existing TeamLogo component, new shadow treatment.</p>
			<div class="logo-grid">
				{#each sampleTeams as team (team.code)}
					<div class="logo-card" style:--team-tint={getTeamSurfaceTint(team.code)}>
						<TeamLogo teamCode={team.code} size={72} />
						<div class="logo-meta">
							<strong>{team.name}</strong>
							<span>{team.note}</span>
						</div>
					</div>
				{/each}
			</div>
			<div class="logo-row-plain">
				<span class="body-muted">Plain (no tile):</span>
				<TeamLogo teamCode="NYJ" size={40} tile={false} />
				<TeamLogo teamCode="LAR" size={40} tile={false} />
				<TeamLogo teamCode="CLE" size={40} tile={false} />
				<TeamLogo teamCode="NYG" size={40} tile={false} />
			</div>
		</section>

		<section class="float-block">
			<h2 class="section-title">Status &amp; badges</h2>
			<div class="badge-row">
				<span class="ds-badge ds-badge-win">Win · 1 pt</span>
				<span class="ds-badge ds-badge-underdog">Underdog · 2 pt</span>
				<span class="ds-badge ds-badge-tie">Tie · 0.5 pt</span>
				<span class="ds-badge ds-badge-loss">Loss</span>
				<span class="ds-badge ds-badge-pending">Pending</span>
			</div>
			<div class="alert-stack">
				<div class="ds-alert ds-alert-success">Week 3 pick saved — change anytime before kickoff.</div>
				<div class="ds-alert ds-alert-warn">3 players haven't picked yet this week.</div>
				<div class="ds-alert ds-alert-error">Could not refresh odds — showing last saved data.</div>
			</div>
		</section>

		<section class="float-block schedule-block">
			<h2 class="section-title">Week 1 · 2026 schedule</h2>
			<p class="body-muted">
				Full slate using the real GameCard component — all 16 games, moneyline win %, kickoff
				badges. NYJ pick shown on Jets @ Titans as a sample.
			</p>
			<div class="games-list">
				{#each week1Games2026 as game (game.id)}
					<GameCard
						{game}
						selectedTeamId={game.id === demoPickGameId ? demoPickTeamId : null}
						activeWeek={1}
						pickingEnabled={true}
						underdogThreshold={33}
					/>
				{/each}
			</div>
		</section>

		<section class="float-block">
			<h2 class="section-title">Standings row (mock)</h2>
			<div class="standings-row standings-row-leader">
				<span class="rank rank-first">1</span>
				<span class="player">Grandma</span>
				<span class="points">14.5</span>
				<span class="record">9–4</span>
			</div>
			<div class="standings-row standings-row-you">
				<span class="rank">2</span>
				<span class="player">You</span>
				<span class="points">13.0</span>
				<span class="record">8–5</span>
			</div>
			<div class="standings-row">
				<span class="rank">3</span>
				<span class="player">Uncle Mike</span>
				<span class="points">11.5</span>
				<span class="record">7–6</span>
			</div>
		</section>

		<section class="float-block pick-toolbar-demo">
			<h2 class="section-title">Pick toolbar (mock)</h2>
			<div class="pick-toolbar">
				<div class="pick-status pick-status-ready">
					<TeamLogo teamCode="LAR" size={28} />
					<span>Current pick · <strong>LAR</strong> <span class="muted-inline">(61%)</span></span>
				</div>
				<button type="button" class="ds-btn ds-btn-primary ds-btn-sm">Submit · LAR</button>
			</div>
			<p class="body-muted toolbar-hint">Tap another team to change — editable until kickoff.</p>
		</section>
	</main>
</div>

<style>
	/* ── Theme tokens (demo-only) ── */
	.design-shell {
		--ds-font-display: 'Archivo Black', 'Arial Black', sans-serif;
		--ds-font-body: 'IBM Plex Sans', system-ui, sans-serif;
		--ds-radius: 4px;

		--ds-shadow: 3px 3px 0 var(--ds-shadow-color);
		--ds-shadow-sm: 2px 2px 0 var(--ds-shadow-color);
		--ds-shadow-lg: 4px 4px 0 var(--ds-shadow-color);
		--ds-shadow-press: 1px 1px 0 var(--ds-shadow-color);
		--ds-shadow-focus: 1px 1px 0 var(--ds-shadow-color), 3px 3px 0 var(--ds-brand);

		position: fixed;
		inset: 0;
		z-index: 300;
		overflow-y: auto;
		font-family: var(--ds-font-body);
		color: var(--ds-text);
		/* Bridge real app components used in schedule section */
		--bg: var(--ds-bg);
		--bg-elevated: var(--ds-surface);
		--text: var(--ds-text);
		--text-muted: var(--ds-text-muted);
		--border: color-mix(in srgb, var(--ds-text) 10%, transparent);
		--accent: var(--ds-brand);
		--underdog: var(--ds-brand);
		--underdog-bg: var(--ds-brand);
		--link: #6b9fd4;
		background:
			radial-gradient(ellipse 65% 40% at 10% 0%, color-mix(in srgb, var(--ds-brand) 10%, transparent), transparent),
			radial-gradient(ellipse 50% 35% at 90% 5%, color-mix(in srgb, var(--ds-brand) 7%, transparent), transparent),
			var(--ds-bg);
	}

	.design-shell[data-theme='dark'] {
		color-scheme: dark;
		--ds-bg: #16161a;
		--ds-text: #fafafa;
		--ds-text-muted: #a8a8b3;
		--ds-surface: #222228;
		--ds-surface-2: #2c2c34;
		--ds-shadow-color: #0a0a0c;
		/* Neutral UI + gold accent */
		--ds-brand: #e0c068;
		--ds-brand-text: #1a1408;
		--ds-primary: #e4e4ea;
		--ds-primary-text: #121216;
		--ds-secondary: #3a3a44;
		--ds-secondary-text: #f4f4f6;
		--ds-highlight: color-mix(in srgb, var(--ds-brand) 12%, var(--ds-surface));
		--ds-highlight-you: color-mix(in srgb, var(--ds-brand) 14%, var(--ds-surface));
		--ds-input-bg: #1e1e24;
		--ds-danger: #dc2626;
		--ds-danger-text: #ffffff;
		--ds-focus: var(--ds-brand);
		/* Semantic status colors */
		--ds-win-bg: #166534;
		--ds-win-text: #ecfdf5;
		--ds-underdog-bg: var(--ds-brand);
		--ds-underdog-text: var(--ds-brand-text);
		--ds-tie-bg: #1e40af;
		--ds-tie-text: #eff6ff;
		--ds-loss-bg: #b91c1c;
		--ds-loss-text: #ffffff;
		--ds-pending-bg: #4b5563;
		--ds-pending-text: #f9fafb;
		--ds-win: #22c55e;
		--ds-underdog: var(--ds-brand);
		--ds-tie: #3b82f6;
		--ds-loss: #dc2626;
	}

	.design-shell[data-theme='light'] {
		color-scheme: light;
		--ds-bg: #f3ecdf;
		--ds-text: #1a1208;
		--ds-text-muted: #5c5348;
		--ds-surface: #fff9f0;
		--ds-surface-2: #ffffff;
		--ds-shadow-color: #2a2218;
		/* Neutral UI + gold accent */
		--ds-brand: #e0c068;
		--ds-brand-text: #1a1408;
		--ds-primary: #2a2826;
		--ds-primary-text: #faf9f7;
		--ds-secondary: #e8e0d4;
		--ds-secondary-text: #1a1208;
		--ds-highlight: color-mix(in srgb, var(--ds-brand) 10%, var(--ds-surface));
		--ds-highlight-you: color-mix(in srgb, var(--ds-brand) 12%, var(--ds-surface));
		--ds-input-bg: #ffffff;
		--ds-danger: #b91c1c;
		--ds-danger-text: #ffffff;
		--ds-focus: var(--ds-brand);
		/* Semantic status colors */
		--ds-win-bg: #15803d;
		--ds-win-text: #ffffff;
		--ds-underdog-bg: var(--ds-brand);
		--ds-underdog-text: var(--ds-brand-text);
		--ds-tie-bg: #1d4ed8;
		--ds-tie-text: #ffffff;
		--ds-loss-bg: #b91c1c;
		--ds-loss-text: #ffffff;
		--ds-pending-bg: #78716c;
		--ds-pending-text: #fafaf9;
		--ds-win: #15803d;
		--ds-underdog: var(--ds-brand);
		--ds-tie: #2563eb;
		--ds-loss: #b91c1c;
	}

	/* Light mode: tame headings — dark type, gold reserved for badges */
	.design-shell[data-theme='light'] .eyebrow {
		color: var(--ds-text-muted);
	}

	.design-shell[data-theme='light'] .display-accent {
		color: var(--ds-text);
	}

	.design-shell[data-theme='light'] .section-title {
		color: var(--ds-text);
		border-left: 3px solid var(--ds-brand);
		padding-left: 0.55rem;
	}

	.design-shell[data-theme='light'] .rank-first {
		color: var(--ds-text);
		font-weight: 800;
	}

	.design-shell[data-theme='light'] .points {
		color: var(--ds-text);
	}

	.design-shell[data-theme='light'] .bullet-list li::marker {
		color: var(--ds-text-muted);
	}

	.design-shell[data-theme='light'] .schedule-block :global(.pick-marker) {
		color: var(--ds-brand-text);
		background: var(--ds-brand);
		padding: 0.1rem 0.35rem;
		border-radius: var(--ds-radius);
	}

	/* ── Top bar ── */
	.topbar {
		position: sticky;
		top: 0;
		z-index: 10;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 1rem 1.5rem;
		background: color-mix(in srgb, var(--ds-bg) 88%, transparent);
		backdrop-filter: blur(8px);
	}

	.topbar-brand {
		display: flex;
		align-items: center;
		gap: 0.65rem;
	}

	.brand-mark {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.25rem;
		height: 2.25rem;
		font-family: var(--ds-font-display);
		font-size: 0.85rem;
		background: var(--ds-brand);
		color: var(--ds-brand-text);
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
	}

	.brand-label {
		font-weight: 700;
		font-size: 0.95rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.theme-toggle {
		padding: 0.5rem 0.85rem;
		font-family: var(--ds-font-body);
		font-size: 0.85rem;
		font-weight: 700;
		cursor: pointer;
		border: none;
		border-radius: var(--ds-radius);
		background: var(--ds-surface-2);
		color: var(--ds-text);
		box-shadow: var(--ds-shadow-sm);
	}

	.theme-toggle:active {
		transform: translate(1px, 1px);
		box-shadow: var(--ds-shadow-press);
	}

	/* ── Canvas ── */
	.canvas {
		max-width: 42rem;
		margin: 0 auto;
		padding: 0 1.25rem 4rem;
		display: flex;
		flex-direction: column;
		gap: 2.5rem;
	}

	.hero-block {
		padding-top: 0.5rem;
	}

	.eyebrow {
		margin: 0 0 0.75rem;
		font-size: 0.78rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: var(--ds-brand);
	}

	.display {
		margin: 0 0 1rem;
		font-family: var(--ds-font-display);
		font-size: clamp(2.5rem, 8vw, 3.75rem);
		line-height: 0.95;
		letter-spacing: -0.02em;
		text-transform: uppercase;
	}

	.display-accent {
		color: var(--ds-brand);
	}

	.lead {
		margin: 0 0 1.5rem;
		font-size: 1.05rem;
		line-height: 1.55;
		max-width: 36ch;
	}

	.section-title {
		margin: 0 0 1rem;
		font-family: var(--ds-font-display);
		font-size: 1.35rem;
		text-transform: uppercase;
		letter-spacing: 0.02em;
		color: var(--ds-brand);
	}

	.subsection-title {
		margin: 0 0 0.65rem;
		font-size: 1.05rem;
		font-weight: 700;
	}

	.body {
		margin: 0 0 0.75rem;
		line-height: 1.55;
	}

	.body-muted {
		margin: 0 0 0.75rem;
		color: var(--ds-text-muted);
		line-height: 1.55;
		font-size: 0.95rem;
	}

	.bullet-list {
		margin: 0.5rem 0 0;
		padding-left: 1.25rem;
		line-height: 1.65;
	}

	.bullet-list li {
		margin: 0.35rem 0;
	}

	.bullet-list li::marker {
		color: var(--ds-brand);
	}

	/* ── Buttons ── */
	.btn-row {
		display: flex;
		flex-wrap: wrap;
		gap: 0.65rem;
		margin-bottom: 1rem;
	}

	.ds-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.7rem 1.15rem;
		font-family: var(--ds-font-body);
		font-size: 0.95rem;
		font-weight: 700;
		cursor: pointer;
		border: none;
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow);
		transition: transform 0.08s ease, box-shadow 0.08s ease;
	}

	.ds-btn:active:not(:disabled) {
		transform: translate(2px, 2px);
		box-shadow: var(--ds-shadow-press);
	}

	.ds-btn-sm:active:not(:disabled) {
		transform: translate(1px, 1px);
	}

	.ds-btn:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.ds-btn-primary {
		background: var(--ds-primary);
		color: var(--ds-primary-text);
	}

	.ds-btn-secondary {
		background: var(--ds-secondary);
		color: var(--ds-secondary-text);
	}

	.ds-btn-ghost {
		background: var(--ds-surface-2);
		color: var(--ds-text);
	}

	.ds-btn-danger {
		background: var(--ds-danger);
		color: var(--ds-danger-text);
	}

	.ds-btn-sm {
		padding: 0.45rem 0.85rem;
		font-size: 0.85rem;
		box-shadow: var(--ds-shadow-sm);
	}

	/* ── Form ── */
	.form-stack {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		margin-top: 0.5rem;
	}

	.field {
		display: flex;
		flex-direction: column;
		gap: 0.35rem;
	}

	.field-label {
		font-size: 0.78rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--ds-text-muted);
	}

	.field input,
	.field textarea,
	.field select {
		padding: 0.65rem 0.75rem;
		font-family: var(--ds-font-body);
		font-size: 1rem;
		color: var(--ds-text);
		background: var(--ds-input-bg);
		border: none;
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
		transition: transform 0.08s ease, box-shadow 0.08s ease;
	}

	.field input:focus,
	.field textarea:focus,
	.field select:focus {
		outline: none;
	}

	.field input:focus-visible,
	.field textarea:focus-visible,
	.field select:focus-visible {
		transform: translate(1px, 1px);
		box-shadow: var(--ds-shadow-focus);
	}

	/* ── Logos ── */
	.logo-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(9.5rem, 1fr));
		gap: 1.25rem;
		margin: 1rem 0;
	}

	.logo-card {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.65rem;
		padding: 1.25rem 0.75rem;
		background: color-mix(in srgb, var(--team-tint, var(--ds-text-muted)) 16%, var(--ds-surface));
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow);
		text-align: center;
	}

	.logo-card :global(.team-logo-tile) {
		box-shadow: var(--ds-shadow-sm) !important;
		border: none !important;
		border-radius: var(--ds-radius) !important;
	}

	.logo-meta {
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
		font-size: 0.8rem;
	}

	.logo-meta strong {
		font-size: 0.9rem;
		color: var(--ds-text);
	}

	.logo-meta span {
		color: var(--ds-text-muted);
		font-size: 0.75rem;
		line-height: 1.3;
	}

	.logo-row-plain {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 0.75rem;
		margin-top: 0.5rem;
	}

	/* ── Badges ── */
	.badge-row {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}

	.ds-badge {
		padding: 0.35rem 0.65rem;
		font-size: 0.78rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
	}

	.ds-badge-win {
		background: var(--ds-win-bg);
		color: var(--ds-win-text);
	}

	.ds-badge-underdog {
		background: var(--ds-underdog-bg);
		color: var(--ds-underdog-text);
	}

	.ds-badge-tie {
		background: var(--ds-tie-bg);
		color: var(--ds-tie-text);
	}

	.ds-badge-loss {
		background: var(--ds-loss-bg);
		color: var(--ds-loss-text);
	}

	.ds-badge-pending {
		background: var(--ds-pending-bg);
		color: var(--ds-pending-text);
	}

	/* ── Alerts ── */
	.alert-stack {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.ds-alert {
		padding: 0.85rem 1rem;
		font-size: 0.9rem;
		font-weight: 600;
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
	}

	.ds-alert-success {
		background: color-mix(in srgb, var(--ds-win) 28%, var(--ds-surface));
		color: var(--ds-text);
		border-left: 3px solid var(--ds-win);
	}

	.ds-alert-warn {
		background: color-mix(in srgb, var(--ds-brand) 28%, var(--ds-surface));
		color: var(--ds-text);
		border-left: 3px solid var(--ds-brand);
	}

	.ds-alert-error {
		background: color-mix(in srgb, var(--ds-danger) 24%, var(--ds-surface));
		color: var(--ds-text);
		border-left: 3px solid var(--ds-danger);
	}

	/* ── Week 1 schedule (real GameCard + design treatment) ── */
	.schedule-block {
		max-width: none;
	}

	.games-list {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		margin-top: 0.75rem;
	}

	.schedule-block :global(.game-card) {
		border: none;
		border-radius: var(--ds-radius);
		background: var(--ds-surface);
		box-shadow: var(--ds-shadow);
	}

	.schedule-block :global(.team-side) {
		border: none;
		border-radius: var(--ds-radius);
		background: color-mix(in srgb, var(--team-tint, var(--ds-text-muted)) 20%, var(--ds-surface)) !important;
		box-shadow: var(--ds-shadow-sm);
	}

	.schedule-block :global(.team-side.selectable:hover),
	.schedule-block :global(.team-side.used-elsewhere:hover) {
		background: color-mix(in srgb, var(--team-tint, var(--ds-text-muted)) 30%, var(--ds-surface)) !important;
		box-shadow: var(--ds-shadow-sm);
	}

	.schedule-block :global(.team-side.is-picked),
	.schedule-block :global(.team-side.selected) {
		background: color-mix(
			in srgb,
			var(--ds-brand) 18%,
			color-mix(in srgb, var(--team-tint, var(--ds-text-muted)) 24%, var(--ds-surface))
		) !important;
		box-shadow: var(--ds-shadow);
	}

	.schedule-block :global(.team-logo-tile) {
		border: none !important;
		border-radius: var(--ds-radius) !important;
		box-shadow: var(--ds-shadow-sm) !important;
	}

	.schedule-block :global(.kickoff),
	.schedule-block :global(.kickoff.highlighted),
	.schedule-block :global(.kickoff[class*='slot-']) {
		border: none !important;
		border-radius: 0;
		background: var(--ds-surface) !important;
		padding-left: 0;
		padding-right: 0;
	}

	/* Light mode: saturated slot badges — readable on cream/white cards */
	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge) {
		border: none;
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-tnf) {
		color: #ffffff;
		background: #0369a1;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-snf) {
		color: var(--ds-brand-text);
		background: var(--ds-brand);
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-mnf) {
		color: #ffffff;
		background: #b91c1c;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-season-opener) {
		color: #ffffff;
		background: #6d28d9;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-international) {
		color: #ffffff;
		background: #047857;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-thanksgiving-eve),
	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-thanksgiving) {
		color: #ffffff;
		background: #c2410c;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-black-friday) {
		color: #ffffff;
		background: #1e293b;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-christmas-eve) {
		color: #ffffff;
		background: #15803d;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-christmas) {
		color: #ffffff;
		background: #991b1b;
	}

	.design-shell[data-theme='light'] .schedule-block :global(.slot-badge.slot-saturday) {
		color: #ffffff;
		background: #475569;
	}

	.schedule-block :global(.underdawg-badge) {
		color: var(--ds-brand-text);
		background: var(--ds-brand);
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
	}

	.schedule-block :global(.win-pct-track) {
		border: none;
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
	}

	/* ── Standings ── */
	.standings-row {
		display: grid;
		grid-template-columns: 2rem 1fr auto auto;
		gap: 0.75rem;
		align-items: center;
		padding: 0.75rem 1rem;
		margin-bottom: 0.5rem;
		background: var(--ds-surface);
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow-sm);
		font-size: 0.95rem;
	}

	.standings-row-leader {
		background: color-mix(in srgb, var(--ds-brand) 10%, var(--ds-surface));
	}

	.standings-row-you {
		background: var(--ds-highlight-you);
		box-shadow: var(--ds-shadow);
	}

	.rank-first {
		color: var(--ds-brand);
	}

	.rank {
		font-family: var(--ds-font-display);
		font-size: 1.1rem;
		color: var(--ds-text-muted);
	}

	.player {
		font-weight: 600;
	}

	.points {
		font-family: var(--ds-font-display);
		font-size: 1.05rem;
		color: var(--ds-brand);
	}

	.record {
		color: var(--ds-text-muted);
		font-size: 0.85rem;
	}

	/* ── Pick toolbar mock ── */
	.pick-toolbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 0.85rem 1rem;
		background: var(--ds-surface);
		border-radius: var(--ds-radius);
		box-shadow: var(--ds-shadow);
	}

	.pick-status {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.9rem;
	}

	.pick-status-ready {
		padding: 0.35rem 0.5rem;
		border-radius: var(--ds-radius);
		background: var(--ds-highlight);
	}

	.muted-inline {
		color: var(--ds-text-muted);
		font-weight: 500;
	}

	.toolbar-hint {
		margin: 0.65rem 0 0;
	}
</style>
