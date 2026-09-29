<script lang="ts">
	import { base } from '$app/paths';
	import { SPONSORS, resolveSponsorLogoUrl } from '$lib/sponsors';
</script>

<section class="sponsor-wall" aria-label="Thank you to our sponsors">
	<h3 class="sponsor-wall-title">Thank you to our sponsors</h3>
	<ul class="sponsor-grid">
		{#each SPONSORS as sponsor (sponsor.slug)}
			<li class="sponsor-cell">
				<img
					src={resolveSponsorLogoUrl(sponsor.slug, base, 256)}
					alt={sponsor.name}
					title={sponsor.name}
					width="112"
					height="112"
					loading="lazy"
					decoding="async"
					fetchpriority="low"
				/>
			</li>
		{/each}
	</ul>
</section>

<style>
	.sponsor-wall {
		margin-top: 1.5rem;
		padding-top: 1.25rem;
		border-top: 1px solid var(--border);
		text-align: center;
		width: 100%;
	}

	.sponsor-wall-title {
		margin: 0 0 1rem;
		font-size: 0.8rem;
		font-weight: 600;
		letter-spacing: 0.04em;
		text-transform: uppercase;
		color: var(--text-muted);
	}

	.sponsor-grid {
		list-style: none;
		margin: 0;
		padding: 0;
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 0.85rem 0.5rem;
		width: 100%;
		align-items: center;
		justify-items: center;
	}

	.sponsor-cell {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 100%;
	}

	.sponsor-cell img {
		display: block;
		width: min(100%, 7rem);
		height: auto;
		aspect-ratio: 1;
		object-fit: contain;
		filter: grayscale(1);
		opacity: 0.72;
		transition:
			filter 0.15s ease,
			opacity 0.15s ease;
	}

	.sponsor-cell img:hover {
		filter: none;
		opacity: 1;
	}

	@media (min-width: 48rem) {
		.sponsor-grid {
			display: flex;
			flex-wrap: wrap;
			justify-content: center;
			gap: 1rem 0.85rem;
			/* 5 logos across, centered 4 below */
			max-width: calc(5 * 7.5rem + 4 * 0.85rem);
			margin-inline: auto;
		}

		.sponsor-cell {
			flex: 0 0 7.5rem;
			width: 7.5rem;
		}

		.sponsor-cell img {
			width: 6.5rem;
		}
	}
</style>
