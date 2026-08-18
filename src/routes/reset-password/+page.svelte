<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import { getPostAuthPath } from '$lib/leagues';
	import { getSupabase } from '$lib/supabase';

	const auth = useAuth();

	let password = $state('');
	let confirmPassword = $state('');
	let error = $state<string | null>(null);
	let submitting = $state(false);

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		error = null;

		if (password !== confirmPassword) {
			error = 'Passwords do not match.';
			return;
		}

		submitting = true;

		const { error: updateError } = await getSupabase().auth.updateUser({ password });

		submitting = false;

		if (updateError) {
			error = updateError.message;
			return;
		}

		const user = auth.user;
		if (user) {
			const path = await getPostAuthPath(user.id, base);
			goto(path);
			return;
		}

		goto(`${base}/login`);
	}
</script>

<main class="page">
	<h1 class="page-title">Set a new password</h1>

	{#if auth.loading}
		<p class="page-subtitle">Checking reset link…</p>
	{:else if !auth.user}
		<p class="page-subtitle">This reset link is invalid or expired.</p>
		<p class="auth-footer">
			<a href="{base}/forgot-password">Request a new link</a>
		</p>
	{:else}
		<p class="page-subtitle">Choose a new password for {auth.user.email}.</p>

		<form class="auth-form" onsubmit={handleSubmit}>
			<label>
				New password
				<input
					type="password"
					name="password"
					autocomplete="new-password"
					required
					minlength="6"
					bind:value={password}
					disabled={submitting}
				/>
			</label>

			<label>
				Confirm password
				<input
					type="password"
					name="confirmPassword"
					autocomplete="new-password"
					required
					minlength="6"
					bind:value={confirmPassword}
					disabled={submitting}
				/>
			</label>

			{#if error}
				<p class="auth-error" role="alert">{error}</p>
			{/if}

			<button type="submit" class="btn btn-primary" disabled={submitting}>
				{submitting ? 'Saving…' : 'Save password'}
			</button>
		</form>
	{/if}
</main>
