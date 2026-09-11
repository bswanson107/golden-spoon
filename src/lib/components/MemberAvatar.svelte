<script lang="ts">
	import { base } from '$app/paths';
	import gsFavicon from '$lib/assets/GSfavicon.png';
	import { resolveAvatarUrl } from '$lib/profileAvatars';

	let {
		name,
		avatarKey = null,
		size = 28
	}: {
		name: string;
		avatarKey?: string | null;
		size?: number;
	} = $props();

	let loadFailed = $state(false);
	const resolved = $derived(resolveAvatarUrl(avatarKey, base) ?? gsFavicon);
	const src = $derived(loadFailed ? gsFavicon : resolved);

	$effect(() => {
		void avatarKey;
		loadFailed = false;
	});

	function handleError() {
		if (src !== gsFavicon) {
			loadFailed = true;
		}
	}
</script>

<img
	class="member-avatar"
	{src}
	alt=""
	width={size}
	height={size}
	loading="lazy"
	decoding="async"
	onerror={handleError}
/>

<style>
	.member-avatar {
		display: block;
		flex-shrink: 0;
		object-fit: contain;
		background: transparent;
	}
</style>
