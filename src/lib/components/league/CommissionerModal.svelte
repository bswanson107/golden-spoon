<script lang="ts">
	import { base } from '$app/paths';
	import PickReminderPanel from '$lib/components/league/PickReminderPanel.svelte';
	import type { WeekGame } from '$lib/types/game';
	import type { LeaguePick, StandingRow } from '$lib/types/standings';

	let {
		open = false,
		leagueId,
		inviteCode,
		isDemo = false,
		weekNumber,
		standings,
		picks,
		games,
		editingInvite = false,
		inviteDraft = $bindable(''),
		inviteSaving = false,
		inviteError = null,
		copied = false,
		onClose,
		onCopyInvite,
		onStartEditInvite,
		onCancelEditInvite,
		onSaveInvite
	}: {
		open?: boolean;
		leagueId: string;
		inviteCode: string;
		isDemo?: boolean;
		weekNumber: number;
		standings: StandingRow[];
		picks: LeaguePick[];
		games: WeekGame[];
		editingInvite?: boolean;
		inviteDraft?: string;
		inviteSaving?: boolean;
		inviteError?: string | null;
		copied?: boolean;
		onClose: () => void;
		onCopyInvite: () => void;
		onStartEditInvite: () => void;
		onCancelEditInvite: () => void;
		onSaveInvite: () => void;
	} = $props();

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
	<div class="modal-backdrop" role="presentation" onclick={handleBackdropClick}>
		<div
			class="modal"
			role="dialog"
			aria-modal="true"
			aria-labelledby="commissioner-modal-title"
		>
			<header class="modal-header">
				<h2 id="commissioner-modal-title" class="modal-title">Commissioner</h2>
				<p class="modal-subtitle">Invite members, nudge pickers, and open admin tools.</p>
			</header>

			<div class="modal-body">
				<section class="section">
					<div class="section-row">
						<div>
							<h3 class="section-title">Admin tools</h3>
							<p class="muted">Override picks, fix scores, and view sync diagnostics.</p>
						</div>
						<a
							href="{base}/league/{leagueId}/admin"
							class="btn btn-ghost btn-sm"
							onclick={onClose}
						>
							Open
						</a>
					</div>
				</section>

				{#if !isDemo}
					<section class="section">
						<h3 class="section-title">Invite family</h3>
						<p class="muted">Share this code so others can join.</p>
						{#if editingInvite}
							<div class="invite-edit">
								<input
									type="text"
									class="invite-input"
									name="inviteCode"
									minlength="3"
									maxlength="32"
									autocapitalize="off"
									autocomplete="off"
									spellcheck="false"
									bind:value={inviteDraft}
									disabled={inviteSaving}
								/>
								<div class="invite-row">
									<button
										type="button"
										class="btn btn-primary btn-sm"
										onclick={onSaveInvite}
										disabled={inviteSaving}
									>
										{inviteSaving ? 'Saving…' : 'Save'}
									</button>
									<button
										type="button"
										class="btn btn-ghost btn-sm"
										onclick={onCancelEditInvite}
										disabled={inviteSaving}
									>
										Cancel
									</button>
								</div>
								{#if inviteError}
									<p class="auth-error" role="alert">{inviteError}</p>
								{/if}
								<p class="muted invite-hint">
									Letters, numbers, and hyphens only. Must be unique across all leagues.
								</p>
							</div>
						{:else}
							<div class="invite-row invite-display">
								<code class="invite-code">{inviteCode}</code>
								<div class="invite-actions">
									<button type="button" class="btn btn-ghost btn-sm" onclick={onCopyInvite}>
										{copied ? 'Copied!' : 'Copy'}
									</button>
									<button type="button" class="btn btn-ghost btn-sm" onclick={onStartEditInvite}>
										Edit
									</button>
								</div>
							</div>
						{/if}
					</section>

					<PickReminderPanel {weekNumber} {standings} {picks} {games} />
				{/if}
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
		overflow: visible;
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

	.modal-body {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		overflow-x: visible;
		padding-right: 0.15rem;
	}

	.section {
		padding: 0.85rem 0;
		border-top: 1px solid var(--border);
	}

	.section:first-child {
		padding-top: 0;
		border-top: none;
	}

	.section-row {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 1rem;
	}

	.section-title {
		margin: 0 0 0.35rem;
		font-size: 1rem;
		color: var(--text);
	}

	.muted {
		margin: 0 0 0.75rem;
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.invite-row {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 0.75rem;
		margin-top: 0.75rem;
	}

	.invite-actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.invite-edit {
		margin-top: 0.75rem;
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.invite-edit .invite-row {
		margin-top: 0;
	}

	.invite-input {
		width: 100%;
		max-width: 20rem;
		font-size: 1.1rem;
		font-weight: 700;
		letter-spacing: 0.04em;
		font-family: var(--font-mono, ui-monospace, monospace);
	}

	.invite-hint {
		margin: 0;
		font-size: 0.82rem;
	}

	.invite-code {
		font-size: 1.25rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		color: var(--brand);
		padding: 0.5rem 0.75rem;
		border-radius: var(--radius);
		background: var(--brand-muted);
		box-shadow: var(--shadow-sm);
	}

	:global([data-theme='light']) .invite-code {
		color: var(--text);
	}

	.modal-actions {
		flex-shrink: 0;
		display: flex;
		justify-content: flex-end;
		margin-top: 1rem;
		padding-top: 0.75rem;
		border-top: 1px solid var(--border);
	}

	@media (max-width: 480px) {
		.invite-display {
			flex-direction: column;
			align-items: flex-start;
		}
	}
</style>
