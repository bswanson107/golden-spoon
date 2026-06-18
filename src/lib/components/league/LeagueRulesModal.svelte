<script lang="ts">
	import LeagueRulesContent from '$lib/components/league/LeagueRulesContent.svelte';
	import {
		type PickVisibility,
		type TiebreakerMode,
		DEFAULT_PICK_VISIBILITY,
		DEFAULT_TIEBREAKER_MODE,
		DEFAULT_UNDERDOG_THRESHOLD,
		parsePickVisibility,
		parseTiebreakerMode
	} from '$lib/leagueRules';

	let {
		open = false,
		leagueName,
		seasonYear,
		threshold = DEFAULT_UNDERDOG_THRESHOLD,
		tiebreakerMode = DEFAULT_TIEBREAKER_MODE,
		pickVisibility = DEFAULT_PICK_VISIBILITY,
		onClose
	}: {
		open?: boolean;
		leagueName: string;
		seasonYear: number;
		threshold?: number;
		tiebreakerMode?: TiebreakerMode | string;
		pickVisibility?: PickVisibility | string;
		onClose: () => void;
	} = $props();

	const resolvedTiebreaker = $derived(parseTiebreakerMode(tiebreakerMode));
	const resolvedVisibility = $derived(parsePickVisibility(pickVisibility));

	function handleBackdropClick(event: MouseEvent) {
		if (event.currentTarget === event.target) {
			onClose();
		}
	}

	function handleKeyDown(event: KeyboardEvent) {
		if (event.key === 'Escape') {
			onClose();
		}
	}

	$effect(() => {
		if (!open) return;

		window.addEventListener('keydown', handleKeyDown);
		return () => window.removeEventListener('keydown', handleKeyDown);
	});
</script>

{#if open}
	<div
		class="modal-backdrop"
		role="presentation"
		onclick={handleBackdropClick}
	>
		<div
			class="modal"
			role="dialog"
			aria-modal="true"
			aria-labelledby="rules-modal-title"
		>
			<header class="modal-header">
				<h2 id="rules-modal-title" class="modal-title">League rules</h2>
				<p class="modal-subtitle">{leagueName} · {seasonYear} season</p>
			</header>

			<div class="rules-body">
				<LeagueRulesContent
					threshold={threshold}
					tiebreakerMode={resolvedTiebreaker}
					pickVisibility={resolvedVisibility}
				/>
			</div>

			<div class="modal-actions">
				<button type="button" class="btn btn-ghost btn-sm" onclick={onClose}>Close</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.modal-backdrop {
		position: fixed;
		inset: 0;
		z-index: 100;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
		background: rgba(0, 0, 0, 0.55);
	}

	.modal {
		width: min(100%, 32rem);
		max-height: min(90vh, 40rem);
		display: flex;
		flex-direction: column;
		padding: 1.25rem 1.35rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.modal-header {
		flex-shrink: 0;
		margin-bottom: 0.75rem;
	}

	.modal-title {
		margin: 0 0 0.2rem;
		font-family: var(--font-display);
		font-size: 1.25rem;
		color: var(--text);
	}

	.modal-subtitle {
		margin: 0;
		font-size: 0.88rem;
		color: var(--text-muted);
	}

	.rules-body {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		padding-right: 0.15rem;
	}

	.modal-actions {
		flex-shrink: 0;
		display: flex;
		justify-content: flex-end;
		margin-top: 1rem;
		padding-top: 0.75rem;
		border-top: 1px solid var(--border);
	}
</style>
