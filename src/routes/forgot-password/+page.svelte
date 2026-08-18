<script lang="ts">
	import { base } from '$app/paths';
	import { getSupabase } from '$lib/supabase';

	let email = $state('');
	let error = $state<string | null>(null);
	let message = $state<string | null>(null);
	let submitting = $state(false);

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		error = null;
		message = null;
		submitting = true;

		const redirectTo = `${window.location.origin}${base}/reset-password`;
		const { error: resetError } = await getSupabase().auth.resetPasswordForEmail(email.trim(), {
			redirectTo
		});

		submitting = false;

		if (resetError) {
			error = resetError.message;
			return;
		}

		message = 'If an account exists for that email, we sent a reset link. Check your inbox.';
	}
</script>

<main class="page">
	<h1 class="page-title">Forgot password</h1>
	<p class="page-subtitle">We’ll email you a link to choose a new password.</p>

	<form class="auth-form" onsubmit={handleSubmit}>
		<label>
			Email
			<input
				type="email"
				name="email"
				autocomplete="email"
				required
				bind:value={email}
				disabled={submitting}
			/>
		</label>

		{#if error}
			<p class="auth-error" role="alert">{error}</p>
		{/if}

		{#if message}
			<p class="auth-message" role="status">{message}</p>
		{/if}

		<button type="submit" class="btn btn-primary" disabled={submitting}>
			{submitting ? 'Sending…' : 'Send reset link'}
		</button>
	</form>

	<p class="auth-footer">
		<a href="{base}/login">Back to sign in</a>
	</p>
</main>

<style>
	.auth-message {
		margin: 0;
		padding: 0.65rem 0.75rem;
		border-radius: var(--radius);
		background: var(--win-muted);
		color: var(--win-bg);
		font-size: 0.875rem;
		box-shadow: var(--shadow-sm);
	}
</style>
