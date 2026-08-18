<script lang="ts">
	import { base } from '$app/paths';
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
			Play the whole season, a few minutes per week. No elimination from one bad pick, and there's
			always a chance for a comeback.
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
</style>
