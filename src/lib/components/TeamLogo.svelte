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

	// Tracks the logo URL that failed to load, so the fallback only applies to
	// that team and resets on its own once `teamCode` changes.
	let failedSrc = $state<string | null>(null);

	const imageSize = $derived(
		tile ? Math.max(12, Math.round(size * 0.68)) : size
	);
	const radius = $derived(Math.max(4, Math.round(size * 0.22)));
	const tileGradient = $derived(getTeamTileGradient(teamCode));
	const lightTile = $derived(isLightTeamColor(teamCode));

	const logoSrc = $derived(isNFLTeamCode(teamCode) ? getTeamLogo(teamCode) : fallbackSrc);
	const src = $derived(failedSrc === logoSrc ? fallbackSrc : logoSrc);

	function handleError() {
		if (logoSrc !== fallbackSrc) {
			failedSrc = logoSrc;
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
				{src}
				alt={getTeamName(teamCode)}
				width={imageSize}
				height={imageSize}
				class="team-logo"
				onerror={handleError}
			/>
		</span>
	{:else}
		<img
			{src}
			alt={getTeamName(teamCode)}
			width={size}
			height={size}
			class="team-logo-plain {className}"
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
	}

	.team-logo-plain {
		flex-shrink: 0;
		vertical-align: middle;
	}
</style>
