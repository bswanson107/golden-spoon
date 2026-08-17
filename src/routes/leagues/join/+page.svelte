<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { joinLeagueByInvite } from '$lib/leagues';

	let inviteCode = $state('');
	let error = $state<string | null>(null);
	let submitting = $state(false);

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		error = null;
		submitting = true;

		const { leagueId, error: joinError } = await joinLeagueByInvite(inviteCode);

		submitting = false;

		if (joinError || !leagueId) {
			error = joinError ?? 'Could not join league.';
			return;
		}

		goto(`${base}/league/${leagueId}`);
	}
</script>

<main class="page">
	<h1 class="page-title">Join league</h1>
	<p class="page-subtitle">Enter the invite code from your commissioner.</p>

	<form class="auth-form" onsubmit={handleSubmit}>
		<label>
			Invite code
			<input
				type="text"
				name="inviteCode"
				placeholder="e.g. family-pool"
				required
				autocapitalize="off"
				autocomplete="off"
				spellcheck="false"
				bind:value={inviteCode}
				disabled={submitting}
			/>
		</label>

		{#if error}
			<p class="auth-error" role="alert">{error}</p>
		{/if}

		<button type="submit" class="btn btn-primary" disabled={submitting}>
			{submitting ? 'Joining…' : 'Join league'}
		</button>
	</form>

	<p class="auth-footer">
		<a href="{base}/leagues">Back to my leagues</a>
	</p>
</main>
