<script lang="ts">
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import { fetchProfile, updateDisplayName } from '$lib/profile';

	const auth = useAuth();

	let displayName = $state('');
	let loading = $state(true);
	let saving = $state(false);
	let error = $state<string | null>(null);
	let success = $state<string | null>(null);

	$effect(() => {
		const user = auth.user;
		if (auth.loading || !user) return;

		loading = true;
		error = null;

		fetchProfile(user.id).then((result) => {
			if (result.error) {
				error = result.error;
				displayName = user.email?.split('@')[0] ?? '';
			} else {
				displayName =
					result.displayName?.trim() ||
					(typeof user.user_metadata?.display_name === 'string'
						? user.user_metadata.display_name
						: '') ||
					user.email?.split('@')[0] ||
					'';
			}
			loading = false;
		});
	});

	async function handleSave(event: SubmitEvent) {
		event.preventDefault();
		const user = auth.user;
		if (!user) return;

		saving = true;
		error = null;
		success = null;

		const result = await updateDisplayName(user.id, displayName);
		saving = false;

		if (result.error) {
			error = result.error;
			return;
		}

		success = 'Display name saved.';
	}
</script>

<main class="page page-account">
	<div class="back-nav">
		<a href="{base}/leagues" class="btn btn-ghost btn-sm">← My leagues</a>
	</div>

	<h1 class="page-title">Account</h1>
	<p class="page-subtitle">How your name appears in standings and the picks grid.</p>

	{#if auth.loading || loading}
		<p class="muted">Loading…</p>
	{:else if !auth.user}
		<p class="auth-error" role="alert">Sign in to edit your profile.</p>
	{:else}
		<section class="card">
			<form class="account-form" onsubmit={handleSave}>
				<label for="display-name">Display name</label>
				<input
					id="display-name"
					type="text"
					bind:value={displayName}
					maxlength="40"
					autocomplete="nickname"
					disabled={saving}
					required
				/>
				<p class="hint muted">Family members see this name instead of your email prefix.</p>

				{#if error}
					<p class="auth-error" role="alert">{error}</p>
				{/if}
				{#if success}
					<p class="success" role="status">{success}</p>
				{/if}

				<button type="submit" class="btn btn-primary" disabled={saving}>
					{saving ? 'Saving…' : 'Save'}
				</button>
			</form>
		</section>

		<p class="email-note muted">Signed in as {auth.user.email}</p>
	{/if}
</main>

<style>
	.page-account {
		max-width: var(--app-content-max, 50rem);
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.card {
		margin-top: 1.25rem;
		padding: 1.1rem 1.25rem;
		border: none;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
	}

	.account-form {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		max-width: 24rem;
	}

	.account-form label {
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--text-muted);
	}

	.account-form input {
		padding: 0.55rem 0.65rem;
		border: none;
		border-radius: var(--radius);
		background: var(--input-bg);
		color: var(--text);
		font-size: 1rem;
		font-family: var(--font-body);
		box-shadow: var(--shadow-sm);
	}

	.success {
		margin: 0;
		padding: 0.5rem 0.65rem;
		border-radius: var(--radius);
		background: var(--win-muted);
		border: none;
		color: var(--win-bg);
		font-size: 0.9rem;
		box-shadow: var(--shadow-sm);
	}

	.hint {
		margin: 0;
	}

	.email-note {
		margin-top: 1rem;
	}
</style>
