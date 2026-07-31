<script lang="ts">
	import { base } from '$app/paths';
	import {
		getTeamLogo,
		getTeamName,
		getTeamTileGradient,
		isLightTeamColor,
		isNFLTeamCode
	} from '$lib/data/nflTeams';

	let {
		teamCode,
		size = 40,
		tile = true,
		className = ''
	}: {
		teamCode: string;
		size?: number;
		tile?: boolean;
		className?: string;
	} = $props();

	const fallbackSrc = `${base}/fallback-logo.svg`;

	let src = $state('');
	let loaded = $state(false);
	let imgEl = $state<HTMLImageElement | undefined>();

	const imageSize = $derived(
		tile ? Math.max(12, Math.round(size * 0.68)) : size
	);
	const radius = $derived(Math.max(4, Math.round(size * 0.22)));
	const tileGradient = $derived(getTeamTileGradient(teamCode));
	const lightTile = $derived(isLightTeamColor(teamCode));

	$effect(() => {
		src = isNFLTeamCode(teamCode) ? getTeamLogo(teamCode) : '';
		loaded = false;
	});

	// If the browser already has this image cached, the `load` event may
	// fire (or may have already fired) before we attach the listener below,
	// which would leave `loaded` stuck at false and the logo invisible.
	// Explicitly check `complete`/`naturalWidth` whenever the element or src
	// updates so cached images still show up.
	$effect(() => {
		void src;
		if (imgEl?.complete && imgEl.naturalWidth > 0) {
			loaded = true;
		}
	});

	function handleLoad() {
		loaded = true;
	}

	function handleError() {
		if (src !== fallbackSrc) {
			src = fallbackSrc;
			loaded = false;
		}
	}
</script>

{#if isNFLTeamCode(teamCode)}
	{#if tile}
		<span
			class="team-logo-tile {className}"
			class:light-tile={lightTile}
			style:width="{size}px"
			style:height="{size}px"
			style:border-radius="{radius}px"
			style:background={tileGradient}
		>
			<img
				bind:this={imgEl}
				{src}
				alt={getTeamName(teamCode)}
				width={imageSize}
				height={imageSize}
				class="team-logo"
				class:loaded
				loading="lazy"
				decoding="async"
				onload={handleLoad}
				onerror={handleError}
			/>
		</span>
	{:else}
		<img
			bind:this={imgEl}
			{src}
			alt={getTeamName(teamCode)}
			width={size}
			height={size}
			class="team-logo-plain {className}"
			class:loaded
			loading="lazy"
			decoding="async"
			onload={handleLoad}
			onerror={handleError}
		/>
	{/if}
{/if}

<style>
	.team-logo-tile {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
		border: 1px solid rgba(255, 255, 255, 0.16);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.45);
		vertical-align: middle;
	}

	.team-logo-tile.light-tile {
		border-color: rgba(0, 0, 0, 0.12);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
	}

	.team-logo,
	.team-logo-plain {
		display: block;
		object-fit: contain;
		opacity: 0;
		transition: opacity 0.15s ease;
		/* Chromium/Electron can drop the painted pixels of a transitioned
		   <img> after the opacity transition ends, leaving it invisible
		   until something forces a repaint (e.g. dragging). Forcing a
		   dedicated, stable compositor layer prevents that. */
		will-change: opacity;
		transform: translateZ(0);
		backface-visibility: hidden;
	}

	.team-logo-plain {
		flex-shrink: 0;
		vertical-align: middle;
	}

	.team-logo.loaded,
	.team-logo-plain.loaded {
		opacity: 1;
	}
</style>
