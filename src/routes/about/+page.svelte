<script lang="ts">
	import oldGs from '$lib/assets/oldGS.png';
	import newGs1 from '$lib/assets/newGS1.png';
	import newGs2 from '$lib/assets/newGS2.png';
	import benPhoto from '$lib/assets/ben.jpeg';
</script>

<svelte:head>
	<title>About · Golden Spoon</title>
</svelte:head>

<main class="page page-about">
	<section class="panel" aria-labelledby="me-heading">
		<div class="about-me">
			<div class="about-me-photo">
				<h2 id="me-heading" class="panel-title">About</h2>
				<img class="headshot" src={benPhoto} alt="Ben Swanson with his daughter on his shoulders" />
			</div>
			<div class="about-me-copy">
				<h3 class="name">Ben Swanson</h3>
				<p class="role">Developer / ✨Vibecoder✨</p>
				<blockquote>
					<p>
						I'm a developer in a tech landscape that has changed rapidly with the explosion of AI.
						In order to keep up, I was looking for a side-project that would:
					</p>
					<ul>
						<li>keep me busy building AI skills and disciplines</li>
						<li>be something I'm excited about (I love football!)</li>
					</ul>
					<p>
						Along the way, I’ve learned to effectively leverage AI agents to design, build, and
						iterate full-stack applications from physical sketches to app deployment.
					</p>
				</blockquote>
			</div>
		</div>
	</section>

	<section class="panel panel-why" aria-labelledby="why-heading">
		<h2 id="why-heading" class="panel-title">Why "Golden Spoon"?</h2>
		<p>
			My family is Italian—we love homemade sauce. And football. Naturally, our family league winner
			gets the Golden Spoon—the trophy that inspired this platform. What started with manually
			tracking the pool in Google Sheets has become a full-stack web app.
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

		<p class="why-footer">
			While this platform was born to upgrade the experience for one family league, it has since
			been created to host a variety of different leagues. Feel free to join an existing league or
			create your own!
		</p>
	</section>
</main>

<style>
	.page-about {
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

	.panel-why {
		padding-bottom: 2rem;
	}

	.panel-title {
		margin: 0 0 0.65rem;
		font-family: var(--font-display);
		font-size: 1.65rem;
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

	.panel p.why-footer {
		margin-top: 1.25rem;
	}

	.from-shot img {
		display: block;
		width: 92.5%;
		border-radius: 0.2rem;
		background: var(--surface-2);
		box-shadow: var(--shadow);
	}

	figcaption {
		width: 92.5%;
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.04em;
		text-transform: uppercase;
		text-align: center;
		color: var(--text-muted);
	}

	.scrapbook {
		position: relative;
		width: 92.5%;
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
		z-index: 1;
	}

	.scrap-front {
		grid-area: 1 / 1;
		width: 72%;
		justify-self: end;
		margin-top: 18%;
		z-index: 2;
	}

	.about-me {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr);
		gap: 1.15rem 1.5rem;
		align-items: start;
	}

	.about-me-photo {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		min-width: 8.5rem;
	}

	.about-me-photo .panel-title {
		margin-bottom: 0.75rem;
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
		font-size: 1.05rem;
		letter-spacing: -0.02em;
	}

	.about-me-copy .role {
		margin: 0 0 0.95rem;
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
