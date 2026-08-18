<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import { getPostAuthPath } from '$lib/leagues';
	import { getSupabase } from '$lib/supabase';

	const auth = useAuth();

	let email = $state('');
	let password = $state('');
	let error = $state<string | null>(null);
	let submitting = $state(false);

	$effect(() => {
		const user = auth.user;
		if (auth.loading || !user) return;

		getPostAuthPath(user.id, base).then((path) => goto(path));
	});

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		error = null;
		submitting = true;

		const { data, error: signInError } = await getSupabase().auth.signInWithPassword({
			email: email.trim(),
			password
		});

		submitting = false;

		if (signInError) {
			error = signInError.message;
			return;
		}

		if (data.user) {
			const path = await getPostAuthPath(data.user.id, base);
			goto(path);
		}
	}
</script>

<main class="page">
	<h1 class="page-title">Sign in</h1>
	<p class="page-subtitle">Family NFL survivor pool</p>

	{#if auth.loading}
		<p class="page-subtitle">Checking session…</p>
	{:else}
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

			<label>
				Password
				<input
					type="password"
					name="password"
					autocomplete="current-password"
					required
					minlength="6"
					bind:value={password}
					disabled={submitting}
				/>
			</label>

			{#if error}
				<p class="auth-error" role="alert">{error}</p>
			{/if}

			<button type="submit" class="btn btn-primary" disabled={submitting}>
				{submitting ? 'Signing in…' : 'Sign in'}
			</button>
		</form>

		<div class="auth-actions">
			<a href="{base}/forgot-password" class="btn btn-ghost btn-sm">Forgot password?</a>
			<a href="{base}/signup" class="btn btn-ghost btn-sm">Create account</a>
		</div>
	{/if}
</main>
