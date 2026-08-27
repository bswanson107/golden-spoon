<script lang="ts">
	import { base } from '$app/paths';
</script>

<svelte:head>
	<title>Save App to Homepage · Golden Spoon</title>
</svelte:head>

<main class="page page-install">
	<header class="hero">
		<figure class="hero-icon">
			<div class="tile">
				<img src="{base}/icons/apple-touch-icon.png" alt="Golden Spoon app icon" />
			</div>
			<figcaption class="tile-label">Golden Spoon</figcaption>
		</figure>

		<div class="hero-copy">
			<h1 class="page-title">Save App to Homepage</h1>
			<p class="hero-sub">Add Golden Spoon to your home screen and it opens like a real app:</p>
			<ul class="hero-perks">
				<li>Full screen</li>
				<li>No address bar</li>
				<li>One tap from your picks</li>
			</ul>
		</div>
	</header>

	<section class="panel" aria-labelledby="iphone-heading">
		<h2 id="iphone-heading" class="panel-title">iPhone</h2>
		<p>Use <strong>Safari</strong> — this option lives in Safari's share menu.</p>
		<ul class="steps">
			<li>Open Golden Spoon in Safari.</li>
			<li>
				Tap the <strong>Share</strong> button
				<svg class="glyph" viewBox="0 0 24 24" aria-hidden="true">
					<path
						fill="none"
						stroke="currentColor"
						stroke-width="1.75"
						stroke-linecap="round"
						stroke-linejoin="round"
						d="M12 15.5V3.5m0 0L8.5 7M12 3.5 15.5 7M6 11.5H5a1.5 1.5 0 0 0-1.5 1.5v6A1.5 1.5 0 0 0 5 20.5h14a1.5 1.5 0 0 0 1.5-1.5v-6a1.5 1.5 0 0 0-1.5-1.5h-1"
					/>
				</svg>
				in the toolbar at the bottom of the screen.
			</li>
			<li>Scroll down the list and tap <strong>Add to Home Screen</strong>.</li>
			<li>Keep the name <strong>Golden Spoon</strong>, then tap <strong>Add</strong>.</li>
			<li>Tap the new icon on your home screen to launch it full screen.</li>
		</ul>
	</section>

	<section class="panel" aria-labelledby="android-heading">
		<h2 id="android-heading" class="panel-title">Android</h2>
		<p>Use <strong>Chrome</strong> for the smoothest install.</p>
		<ul class="steps">
			<li>Open Golden Spoon in Chrome.</li>
			<li>
				Tap the <strong>menu</strong> button
				<svg class="glyph" viewBox="0 0 24 24" aria-hidden="true">
					<circle cx="12" cy="5" r="1.75" fill="currentColor" />
					<circle cx="12" cy="12" r="1.75" fill="currentColor" />
					<circle cx="12" cy="19" r="1.75" fill="currentColor" />
				</svg>
				in the top-right corner.
			</li>
			<li>
				Tap <strong>Add to Home screen</strong> — some versions of Chrome label it
				<strong>Install app</strong>.
			</li>
			<li>Confirm with <strong>Install</strong> or <strong>Add</strong>.</li>
			<li>Find <strong>Golden Spoon</strong> on your home screen or in your app drawer.</li>
		</ul>
	</section>

	<p class="footnote">
		You'll still need an internet connection — scores, standings, and picks load live.
	</p>
</main>

<style>
	.page-install {
		display: flex;
		flex-direction: column;
		gap: 1.15rem;
		padding-bottom: 2.5rem;
	}

	.panel {
		padding: 1.25rem 1.3rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.panel-title {
		margin: 0 0 0.65rem;
		font-family: var(--font-display);
		font-size: 1.4rem;
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

	.hero {
		display: flex;
		align-items: center;
		gap: 1.15rem;
	}

	.hero-icon {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.45rem;
		margin: 0;
		flex-shrink: 0;
	}

	.tile {
		width: 4.25rem;
		height: 4.25rem;
		overflow: hidden;
		border-radius: 1rem;
		background: #16161a;
		box-shadow: var(--shadow);
	}

	.tile img {
		display: block;
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.tile-label {
		font-size: 0.72rem;
		font-weight: 700;
		line-height: 1.2;
		letter-spacing: 0.01em;
		text-align: center;
		color: var(--text);
	}

	.hero-copy {
		min-width: 0;
	}

	.hero-copy .page-title {
		margin: 0 0 0.3rem;
		font-size: 1.5rem;
	}

	.hero-sub {
		margin: 0;
		color: var(--text-muted);
		font-size: 0.88rem;
		line-height: 1.5;
	}

	.hero-perks {
		margin: 0.35rem 0 0;
		padding-left: 1.1rem;
		display: flex;
		flex-direction: column;
		gap: 0.15rem;
	}

	.hero-perks li {
		color: var(--text-muted);
		font-size: 0.88rem;
		line-height: 1.45;
	}

	@media (max-width: 26rem) {
		.hero {
			gap: 0.9rem;
		}

		.tile {
			width: 3.6rem;
			height: 3.6rem;
			border-radius: 0.85rem;
		}

		.hero-copy .page-title {
			font-size: 1.3rem;
		}
	}

	.steps {
		margin: 0.85rem 0 0;
		padding-left: 1.2rem;
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.steps li {
		font-size: 0.95rem;
		line-height: 1.5;
		color: var(--text);
	}

	.glyph {
		width: 1.05rem;
		height: 1.05rem;
		vertical-align: -0.2rem;
		color: var(--text-muted);
	}

	.footnote {
		margin: 0;
		color: var(--text-muted);
		font-size: 0.85rem;
		line-height: 1.5;
	}
</style>
