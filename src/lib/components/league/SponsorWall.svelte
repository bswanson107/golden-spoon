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
					src={resolveSponsorLogoUrl(sponsor.slug, base, 128)}
					alt={sponsor.name}
					title={sponsor.name}
					width="64"
					height="64"
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
	}

	.sponsor-wall-title {
		margin: 0 0 0.85rem;
		font-size: 0.8rem;
		font-weight: 600;
		letter-spacing: 0.04em;
		text-transform: uppercase;
		color: var(--text-muted);
	}

	.sponsor-grid {
		list-style: none;
		margin: 0 auto;
		padding: 0;
		display: grid;
		grid-template-columns: repeat(3, 4.5rem);
		gap: 0.75rem 0.5rem;
		justify-content: center;
		align-items: center;
		justify-items: center;
	}

	.sponsor-cell {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	@media (min-width: 48rem) {
		.sponsor-grid {
			display: flex;
			flex-wrap: wrap;
			/* 5 × 4.5rem + 4 × 0.5rem gaps — forces 5 on the first row, 4 centered below */
			max-width: calc(5 * 4.5rem + 4 * 0.5rem);
		}

		.sponsor-cell {
			flex: 0 0 4.5rem;
			width: 4.5rem;
		}
	}

	.sponsor-cell img {
		display: block;
		width: 3.5rem;
		height: 3.5rem;
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
</style>
