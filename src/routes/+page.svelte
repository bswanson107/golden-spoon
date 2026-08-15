<script lang="ts">
	import { base } from '$app/paths';
	import oldGs from '$lib/assets/oldGS.png';
	import newGs1 from '$lib/assets/newGS1.png';
	import newGs2 from '$lib/assets/newGS2.png';
	import benPhoto from '$lib/assets/ben.jpeg';
	import { useAuth } from '$lib/auth';
	import { PUBLIC_DEMO_LEAGUE_ID } from '$lib/leagues';

	const auth = useAuth();
</script>

<svelte:head>
	<title>Golden Spoon</title>
</svelte:head>

<main class="page page-splash">
	<section class="hero-block" aria-labelledby="splash-heading">
		<p class="eyebrow">Golden Spoon</p>
		<h1 id="splash-heading" class="display">
			Survivor Pool<br /><span class="display-accent">With a Twist</span>
		</h1>
		<p class="lead">Select one NFL team each week.</p>
		<ul class="lead-list">
			<li>Pick correctly, you get a point</li>
			<li>Pick wrong, no points</li>
		</ul>
		<p class="lead lead-follow">
			One bad pick doesn't end your season, and there's always a chance for a comeback.
		</p>
		<div class="btn-row">
			{#if !auth.loading && !auth.user}
				<a href="{base}/signup" class="hero-btn hero-btn-secondary">Create an account</a>
			{/if}
			<a href="{base}/league/{PUBLIC_DEMO_LEAGUE_ID}" class="hero-btn hero-btn-primary">View Demo</a>
		</div>
		{#if !auth.loading && !auth.user}
			<p class="hero-note">(No email verification needed)</p>
		{/if}
	</section>

	<section class="panel panel-why" aria-labelledby="why-heading">
		<h2 id="why-heading" class="panel-title">Why Golden Spoon?</h2>
		<p>
			My family is Italian—we love homemade sauce. And football. Naturally, our family league winner
			gets the Golden Spoon—the trophy that inspired this platform. This platform is built for any
			pool but born from ours. What started with manually tracking the pool in Google Sheets has
			become a full-stack web app.
		</p>

		<div class="trophy-compare">
			<figure class="from-shot">
				<figcaption>From this</figcaption>
				<img src={oldGs} alt="The original family pool tracked in a spreadsheet" />
			</figure>

			<figure class="to-shot">
				<figcaption>To this</figcaption>
				<div class="scrapbook" aria-hidden="true">
					<img class="scrap-back" src={newGs1} alt="" />
					<img class="scrap-front" src={newGs2} alt="" />
				</div>
			</figure>
		</div>
	</section>

	<section class="panel" aria-labelledby="me-heading">
		<div class="about-me">
			<img class="headshot" src={benPhoto} alt="Ben Swanson with his daughter on his shoulders" />
			<div class="about-me-copy">
				<h2 id="me-heading" class="name">About Ben Swanson</h2>
				<p class="role">Developer / ✨Vibecoder✨</p>
				<blockquote>
					<p>
						As a developer in a rapidly changing AI tech landscape, I wanted a side-project that
						would be something that:
					</p>
					<ul>
						<li>keeps me busy building AI skills and disciplines</li>
						<li>I'm excited about.</li>
					</ul>
					<p>
						Along the way, I’ve learned to effectively leverage AI agents to design, build, and
						iterate full-stack applications from physical sketches to app deployment.
					</p>
				</blockquote>
			</div>
		</div>
	</section>
</main>

<style>
	.page-splash {
		display: flex;
		flex-direction: column;
		gap: 1.15rem;
		padding-bottom: 2.5rem;
	}

	.hero-block {
		padding-top: 0.5rem;
		padding-bottom: 0.85rem;
	}

	.eyebrow {
		margin: 0 0 0.75rem;
		font-size: 0.78rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: var(--brand);
	}

	.display {
		margin: 0 0 1rem;
		font-family: var(--font-display);
		font-size: clamp(2.5rem, 8vw, 3.75rem);
		line-height: 0.95;
		letter-spacing: -0.02em;
		text-transform: uppercase;
		color: var(--text);
	}

	.display-accent {
		color: var(--brand);
	}

	.lead {
		margin: 0 0 1.5rem;
		font-size: 1.05rem;
		line-height: 1.55;
		max-width: 36ch;
		color: var(--text);
	}

	.lead-list {
		margin: -0.85rem 0 1.15rem;
		padding-left: 1.25rem;
		max-width: 36ch;
		font-size: 1.05rem;
		line-height: 1.55;
		color: var(--text);
	}

	.lead-list li {
		margin: 0.2rem 0;
	}

	.lead-list li::marker {
		color: var(--brand);
	}

	.lead-follow {
		margin-top: 0;
	}

	.btn-row {
		display: flex;
		flex-wrap: wrap;
		gap: 0.65rem;
		margin-bottom: 0.65rem;
	}

	.hero-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.7rem 1.15rem;
		font-family: var(--font-body);
		font-size: 0.95rem;
		font-weight: 700;
		text-decoration: none;
		border: none;
		border-radius: var(--radius);
		box-shadow: var(--shadow);
		transition:
			transform 0.08s ease,
			box-shadow 0.08s ease;
	}

	.hero-btn:active {
		transform: translate(2px, 2px);
		box-shadow: var(--shadow-press);
	}

	.hero-btn-primary,
	.hero-btn-primary:visited,
	.hero-btn-primary:hover {
		background: var(--primary);
		color: var(--primary-text);
	}

	.hero-btn-secondary,
	.hero-btn-secondary:visited,
	.hero-btn-secondary:hover {
		background: var(--secondary);
		color: var(--secondary-text);
	}

	.hero-note {
		margin: 0;
		font-size: 0.72rem;
		color: var(--text-muted);
	}

	:global([data-theme='light']) .eyebrow {
		color: var(--text-muted);
	}

	:global([data-theme='light']) .display-accent {
		color: var(--text);
	}

	.panel {
		padding: 1.25rem 1.3rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.panel-why {
		padding-bottom: 2rem;
	}

	.panel-title {
		margin: 0 0 0.65rem;
		font-family: var(--font-display);
		font-size: 1.15rem;
		line-height: 1.25;
		color: var(--text);
		letter-spacing: -0.02em;
	}

	.panel p {
		margin: 0;
		color: var(--text);
		font-size: 0.95rem;
		line-height: 1.55;
	}

	.trophy-compare {
		display: flex;
		flex-direction: column;
		gap: 2.75rem;
		align-items: center;
		margin-top: 1.25rem;
	}

	.from-shot,
	.to-shot {
		margin: 0;
		width: 100%;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.55rem;
	}

	.to-shot {
		gap: 2rem;
	}

	.from-shot img {
		display: block;
		width: 80%;
		border-radius: 0.2rem;
		background: var(--surface-2);
		box-shadow: var(--shadow);
		transform: rotate(-2.5deg);
	}

	figcaption {
		width: 80%;
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.04em;
		text-transform: uppercase;
		text-align: center;
		color: var(--text-muted);
	}

	.scrapbook {
		position: relative;
		width: 80%;
		display: grid;
		padding-bottom: 2.75rem;
	}

	.scrap-back,
	.scrap-front {
		display: block;
		border-radius: 0.2rem;
		background: var(--surface-2);
		box-shadow: var(--shadow-lg);
	}

	.scrap-back {
		grid-area: 1 / 1;
		width: 68%;
		justify-self: start;
		margin-bottom: 18%;
		transform: rotate(-7deg);
		z-index: 1;
	}

	.scrap-front {
		grid-area: 1 / 1;
		width: 72%;
		justify-self: end;
		margin-top: 18%;
		transform: rotate(5deg);
		z-index: 2;
	}

	.about-me {
		display: grid;
		grid-template-columns: 8.5rem minmax(0, 1fr);
		gap: 1.15rem 1.25rem;
		align-items: start;
	}

	.headshot {
		width: 8.5rem;
		height: 8.5rem;
		object-fit: cover;
		border-radius: var(--radius);
		box-shadow: var(--shadow);
	}

	.name {
		margin: 0 0 0.15rem;
		font-family: var(--font-display);
		font-size: 1.2rem;
		letter-spacing: -0.02em;
	}

	.role {
		margin: 0 0 0.85rem;
		font-size: 0.92rem;
		font-weight: 600;
		color: var(--text-muted);
	}

	blockquote {
		margin: 0;
		padding: 0.75rem 0.9rem;
		border-left: 3px solid var(--brand);
		background: color-mix(in srgb, var(--brand) 10%, var(--surface-2));
		border-radius: 0 var(--radius) var(--radius) 0;
	}

	blockquote p + p,
	blockquote p + ul,
	blockquote ul + p {
		margin-top: 0.65rem;
	}

	blockquote ul {
		margin: 0.35rem 0 0;
		padding-left: 1.2rem;
	}

	blockquote li {
		margin: 0.2rem 0;
		font-size: 0.92rem;
		line-height: 1.45;
	}

	@media (max-width: 640px) {
		.about-me {
			grid-template-columns: 1fr;
		}

		.headshot {
			width: 7.25rem;
			height: 7.25rem;
		}
	}
</style>
