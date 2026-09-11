<script lang="ts">
	import MemberAvatar from '$lib/components/MemberAvatar.svelte';
	import {
		deleteLeagueMessage,
		fetchLeagueMessages,
		LEAGUE_CHAT_MAX_LENGTH,
		markLeagueChatRead,
		sendLeagueMessage,
		type LeagueChatMessage
	} from '$lib/chat';

	let {
		open = false,
		leagueId,
		leagueName,
		currentUserId,
		currentUserDisplayName,
		currentUserAvatarKey = null,
		showProfilePictures = false,
		canDeleteAny = false,
		onClose,
		onRead
	}: {
		open?: boolean;
		leagueId: string;
		leagueName: string;
		currentUserId: string;
		currentUserDisplayName: string;
		currentUserAvatarKey?: string | null;
		showProfilePictures?: boolean;
		canDeleteAny?: boolean;
		onClose: () => void;
		onRead?: () => void;
	} = $props();

	let messages = $state<LeagueChatMessage[]>([]);
	let hasMore = $state(false);
	let loading = $state(false);
	let loadingMore = $state(false);
	let sending = $state(false);
	let deletingId = $state<string | null>(null);
	let error = $state<string | null>(null);
	let draft = $state('');
	let listEl = $state<HTMLDivElement | null>(null);
	let openedFor = $state<string | null>(null);

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

	function formatTimestamp(value: string): string {
		return new Date(value).toLocaleString(undefined, {
			month: 'short',
			day: 'numeric',
			hour: 'numeric',
			minute: '2-digit'
		});
	}

	function canDelete(message: LeagueChatMessage): boolean {
		return canDeleteAny || message.user_id === currentUserId;
	}

	function scrollToBottom() {
		const el = listEl;
		if (!el) return;
		el.scrollTop = el.scrollHeight;
	}

	async function loadInitial() {
		loading = true;
		error = null;
		const [listResult] = await Promise.all([
			fetchLeagueMessages(leagueId),
			markLeagueChatRead(leagueId)
		]);
		loading = false;

		if (listResult.error) {
			error = listResult.error;
			messages = [];
			hasMore = false;
			return;
		}

		messages = listResult.messages;
		hasMore = listResult.hasMore;
		onRead?.();
		queueMicrotask(scrollToBottom);
	}

	async function loadMore() {
		if (loadingMore || !hasMore || messages.length === 0) return;

		const oldest = messages[0];
		const previousHeight = listEl?.scrollHeight ?? 0;
		loadingMore = true;
		error = null;

		const result = await fetchLeagueMessages(leagueId, { before: oldest.created_at });
		loadingMore = false;

		if (result.error) {
			error = result.error;
			return;
		}

		const existing = new Set(messages.map((row) => row.id));
		const older = result.messages.filter((row) => !existing.has(row.id));
		messages = [...older, ...messages];
		hasMore = result.hasMore;

		queueMicrotask(() => {
			const el = listEl;
			if (!el) return;
			el.scrollTop = el.scrollHeight - previousHeight;
		});
	}

	async function handleSend(event: SubmitEvent) {
		event.preventDefault();
		if (sending) return;

		const trimmed = draft.trim();
		if (!trimmed) return;

		sending = true;
		error = null;

		const result = await sendLeagueMessage(leagueId, currentUserId, trimmed);
		sending = false;

		if (result.error || !result.message) {
			error = result.error ?? 'Could not send message.';
			return;
		}

		draft = '';
		messages = [
			...messages,
			{
				...result.message,
				display_name: currentUserDisplayName,
				avatar_key: currentUserAvatarKey
			}
		];
		void markLeagueChatRead(leagueId);
		onRead?.();
		queueMicrotask(scrollToBottom);
	}

	async function handleDelete(message: LeagueChatMessage) {
		if (deletingId) return;
		const confirmed = confirm('Delete this message?');
		if (!confirmed) return;

		deletingId = message.id;
		const result = await deleteLeagueMessage(message.id);
		deletingId = null;

		if (result.error) {
			error = result.error;
			return;
		}

		messages = messages.filter((row) => row.id !== message.id);
	}

	function onComposerKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter' && !event.shiftKey) {
			event.preventDefault();
			(event.currentTarget as HTMLTextAreaElement).form?.requestSubmit();
		}
	}

	$effect(() => {
		if (!open) {
			openedFor = null;
			return;
		}

		window.addEventListener('keydown', handleKeyDown);
		const previousOverflow = document.body.style.overflow;
		document.body.style.overflow = 'hidden';

		if (openedFor !== leagueId) {
			openedFor = leagueId;
			messages = [];
			hasMore = false;
			draft = '';
			void loadInitial();
		}

		return () => {
			window.removeEventListener('keydown', handleKeyDown);
			document.body.style.overflow = previousOverflow;
		};
	});
</script>

{#if open}
	<div class="modal-backdrop" role="presentation" onclick={handleBackdropClick}>
		<div class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-modal-title">
			<header class="modal-header">
				<div class="header-copy">
					<h2 id="chat-modal-title" class="modal-title">Chat</h2>
					<p class="modal-subtitle">{leagueName}</p>
				</div>
				<button type="button" class="btn btn-ghost btn-sm" onclick={onClose}>Close</button>
			</header>

			<div class="chat-body" bind:this={listEl}>
				{#if hasMore}
					<div class="load-more-wrap">
						<button
							type="button"
							class="btn btn-ghost btn-sm"
							disabled={loadingMore}
							onclick={() => void loadMore()}
						>
							{loadingMore ? 'Loading…' : 'Load more'}
						</button>
					</div>
				{/if}

				{#if loading}
					<p class="muted">Loading messages…</p>
				{:else if messages.length === 0 && !error}
					<p class="muted empty">No messages yet. Say hi.</p>
				{:else}
					<ul class="message-list">
						{#each messages as message (message.id)}
							<li class="message" class:mine={message.user_id === currentUserId}>
								{#if showProfilePictures}
									<MemberAvatar
										name={message.display_name}
										avatarKey={message.avatar_key}
										size={28}
									/>
								{/if}
								<div class="message-main">
									<div class="message-meta">
										<span class="message-name">{message.display_name}</span>
										<time class="message-time" datetime={message.created_at}>
											{formatTimestamp(message.created_at)}
										</time>
										{#if canDelete(message)}
											<button
												type="button"
												class="delete-btn"
												disabled={deletingId === message.id}
												aria-label="Delete message from {message.display_name}"
												onclick={() => void handleDelete(message)}
											>
												{deletingId === message.id ? '…' : 'Delete'}
											</button>
										{/if}
									</div>
									<p class="message-body">{message.body}</p>
								</div>
							</li>
						{/each}
					</ul>
				{/if}
			</div>

			<form class="composer" onsubmit={handleSend}>
				{#if error}
					<p class="auth-error" role="alert">{error}</p>
				{/if}
				<textarea
					bind:value={draft}
					maxlength={LEAGUE_CHAT_MAX_LENGTH}
					rows="2"
					placeholder="Message the league…"
					disabled={sending || loading}
					onkeydown={onComposerKeydown}
				></textarea>
				<div class="composer-row">
					<span class="char-count muted">{draft.trim().length}/{LEAGUE_CHAT_MAX_LENGTH}</span>
					<button
						type="submit"
						class="btn btn-primary btn-sm"
						disabled={sending || loading || draft.trim().length === 0}
					>
						{sending ? 'Sending…' : 'Send'}
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<style>
	.modal-backdrop {
		position: fixed;
		inset: 0;
		z-index: 100;
		display: flex;
		align-items: stretch;
		justify-content: center;
		padding: 0.65rem;
		background: rgba(0, 0, 0, 0.55);
	}

	.modal {
		width: min(100%, 44rem);
		height: min(100%, 100dvh);
		max-height: calc(100dvh - 1.3rem);
		display: flex;
		flex-direction: column;
		padding: 1rem 1.1rem 0.9rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-lg);
	}

	.modal-header {
		flex-shrink: 0;
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.75rem;
		margin-bottom: 0.75rem;
	}

	.header-copy {
		min-width: 0;
	}

	.modal-title {
		margin: 0 0 0.15rem;
		font-family: var(--font-display);
		font-size: 1.25rem;
		color: var(--text);
	}

	.modal-subtitle {
		margin: 0;
		font-size: 0.88rem;
		color: var(--text-muted);
	}

	.chat-body {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		padding: 0.15rem 0.1rem 0.75rem;
	}

	.load-more-wrap {
		display: flex;
		justify-content: center;
		margin-bottom: 0.75rem;
	}

	.muted {
		margin: 0;
		color: var(--text-muted);
		font-size: 0.88rem;
	}

	.empty {
		text-align: center;
		padding: 2rem 0.5rem;
	}

	.message-list {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 0.85rem;
	}

	.message {
		display: flex;
		align-items: flex-start;
		gap: 0.5rem;
	}

	.message-main {
		min-width: 0;
		flex: 1;
	}

	.message-meta {
		display: flex;
		flex-wrap: wrap;
		align-items: baseline;
		gap: 0.35rem 0.5rem;
	}

	.message-name {
		font-weight: 700;
		font-size: 0.88rem;
	}

	.message.mine .message-name {
		color: var(--brand);
	}

	.message-time {
		color: var(--text-muted);
		font-size: 0.75rem;
	}

	.delete-btn {
		padding: 0;
		border: none;
		background: none;
		color: var(--text-muted);
		font: inherit;
		font-size: 0.75rem;
		font-weight: 600;
		cursor: pointer;
	}

	.delete-btn:hover:not(:disabled) {
		color: var(--danger);
	}

	.delete-btn:disabled {
		opacity: 0.55;
		cursor: not-allowed;
	}

	.message-body {
		margin: 0.2rem 0 0;
		white-space: pre-wrap;
		overflow-wrap: anywhere;
		line-height: 1.4;
	}

	.composer {
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
		padding-top: 0.75rem;
		border-top: 1px solid var(--border);
	}

	.composer textarea {
		width: 100%;
		resize: none;
		padding: 0.6rem 0.7rem;
		border: none;
		border-radius: var(--radius);
		background: var(--input-bg);
		color: var(--text);
		font: inherit;
		font-size: 0.95rem;
		box-shadow: var(--shadow-sm);
	}

	.composer-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
	}

	.char-count {
		margin: 0;
		font-size: 0.75rem;
	}
</style>
