<script lang="ts">
	import { DEMO_SEASON_YEAR } from '$lib/season';

	let {
		seasonYear = DEMO_SEASON_YEAR
	}: {
		seasonYear?: number;
	} = $props();
</script>

<section class="alert alert-info" role="status">
	<strong>Demo league</strong>
	— This is a {seasonYear} season pool so you can see what a live league looks like.
	Browse standings, weekly picks, and travel through weeks with the week selector.
</section>
