<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { useAuth } from '$lib/auth';
	import {
		DEFAULT_PICK_VISIBILITY,
		DEFAULT_TIEBREAKER_MODE,
		DEFAULT_UNDERDOG_THRESHOLD,
		type PickVisibility,
		type TiebreakerMode,
		UNDERDOG_THRESHOLD_PRESETS
	} from '$lib/leagueRules';
	import { createLeague, currentNflSeasonYear } from '$lib/leagues';

	const auth = useAuth();

	let name = $state('');
	let seasonYear = $state(currentNflSeasonYear());
	let inviteCode = $state('');
	let underdogThreshold = $state<number>(DEFAULT_UNDERDOG_THRESHOLD);
	let tiebreakerMode = $state<TiebreakerMode>(DEFAULT_TIEBREAKER_MODE);
	let pickVisibility = $state<PickVisibility>(DEFAULT_PICK_VISIBILITY);
	let error = $state<string | null>(null);
	let submitting = $state(false);

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		if (!auth.user) return;

		error = null;
		submitting = true;

		const { league, error: createError } = await createLeague(name, seasonYear, {
			inviteCode,
			underdogThresholdPct: underdogThreshold,
			tiebreakerMode,
			pickVisibility
		});

		submitting = false;

		if (createError || !league) {
			error = createError ?? 'Could not create league.';
			return;
		}

		goto(`${base}/league/${league.id}`);
	}
</script>

<main class="page page-create">
	<h1 class="page-title">Create league</h1>
	<p class="page-subtitle">You'll be the commissioner and can share the invite code.</p>

	<form class="auth-form" onsubmit={handleSubmit}>
		<label>
			League name
			<input
				type="text"
				name="name"
				placeholder="Scaglione Family Pool"
				required
				maxlength="80"
				bind:value={name}
				disabled={submitting}
			/>
		</label>

		<label>
			Invite code
			<input
				type="text"
				name="inviteCode"
				placeholder="e.g. scaglione-family"
				required
				minlength="3"
				maxlength="32"
				autocapitalize="off"
				autocomplete="off"
				spellcheck="false"
				bind:value={inviteCode}
				disabled={submitting}
			/>
		</label>
		<p class="field-hint">
			Something short and shareable. Letters, numbers, and hyphens only (3–32 characters). Must be
			unique across all leagues.
		</p>

		<label>
			Season year
			<input
				type="number"
				name="seasonYear"
				min="2020"
				max="2035"
				required
				bind:value={seasonYear}
				disabled={submitting}
			/>
		</label>

		<section class="rules-panel" aria-labelledby="rules-heading">
			<h2 id="rules-heading" class="rules-heading">League rules</h2>
			<p class="rules-intro muted">
				Defaults match the standard pool. Rules lock after the first pick is submitted.
			</p>

			<div class="rule-group" role="radiogroup" aria-labelledby="threshold-label">
				<span id="threshold-label" class="rule-label">Underdog threshold</span>
				<p class="rule-hint muted">
					Teams at or below this win % at kickoff count as underdogs (2 pts).
				</p>
				<div class="option-row">
					{#each UNDERDOG_THRESHOLD_PRESETS as preset (preset)}
						<button
							type="button"
							class="option-chip"
							class:selected={underdogThreshold === preset}
							role="radio"
							aria-checked={underdogThreshold === preset}
							disabled={submitting}
							onclick={() => (underdogThreshold = preset)}
						>
							{preset}%
						</button>
					{/each}
				</div>
			</div>

			<div class="rule-group" role="radiogroup" aria-labelledby="tiebreaker-label">
				<span id="tiebreaker-label" class="rule-label">Standings tiebreaker</span>
				<div class="option-column">
					<button
						type="button"
						class="option-card"
						class:selected={tiebreakerMode === 'fewest_wins'}
						role="radio"
						aria-checked={tiebreakerMode === 'fewest_wins'}
						disabled={submitting}
						onclick={() => (tiebreakerMode = 'fewest_wins')}
					>
						<span class="option-dot" aria-hidden="true"></span>
						<span class="option-text">Fewest cumulative team wins (default)</span>
					</button>
					<button
						type="button"
						class="option-card"
						class:selected={tiebreakerMode === 'most_wins'}
						role="radio"
						aria-checked={tiebreakerMode === 'most_wins'}
						disabled={submitting}
						onclick={() => (tiebreakerMode = 'most_wins')}
					>
						<span class="option-dot" aria-hidden="true"></span>
						<span class="option-text">Most cumulative team wins</span>
					</button>
				</div>
			</div>

			<div class="rule-group" role="radiogroup" aria-labelledby="visibility-label">
				<span id="visibility-label" class="rule-label">Pick visibility</span>
				<div class="option-column">
					<button
						type="button"
						class="option-card"
						class:selected={pickVisibility === 'hidden_until_kickoff'}
						role="radio"
						aria-checked={pickVisibility === 'hidden_until_kickoff'}
						disabled={submitting}
						onclick={() => (pickVisibility = 'hidden_until_kickoff')}
					>
						<span class="option-dot" aria-hidden="true"></span>
						<span class="option-text">Hidden until kickoff (default)</span>
					</button>
					<button
						type="button"
						class="option-card"
						class:selected={pickVisibility === 'open'}
						role="radio"
						aria-checked={pickVisibility === 'open'}
						disabled={submitting}
						onclick={() => (pickVisibility = 'open')}
					>
						<span class="option-dot" aria-hidden="true"></span>
						<span class="option-text">Open — picks visible immediately</span>
					</button>
				</div>
			</div>
		</section>

		{#if error}
			<p class="auth-error" role="alert">{error}</p>
		{/if}

		<button type="submit" class="btn btn-primary" disabled={submitting}>
			{submitting ? 'Creating…' : 'Create league'}
		</button>
	</form>

	<p class="auth-footer">
		<a href="{base}/leagues">Back to my leagues</a>
	</p>
</main>

<style>
	.page-create {
		display: flex;
		flex-direction: column;
		align-items: center;
		text-align: center;
	}

	.page-create .auth-form {
		width: 100%;
		max-width: 24rem;
		text-align: left;
	}

	.page-create .auth-footer {
		width: 100%;
		max-width: 24rem;
	}

	.muted {
		color: var(--text-muted);
		font-size: 0.88rem;
	}

	.rules-panel {
		margin: 0;
		padding: 1rem;
		border: 1px solid var(--border);
		border-radius: var(--radius);
		background: var(--surface);
		min-width: 0;
	}

	.rules-heading {
		margin: 0 0 0.5rem;
		font-size: 0.95rem;
		font-weight: 700;
		color: var(--text);
	}

	.rules-intro {
		margin: 0 0 1rem;
		line-height: 1.45;
	}

	.rule-group + .rule-group {
		margin-top: 1.1rem;
		padding-top: 1.1rem;
		border-top: 1px solid var(--border);
	}

	.rule-label {
		display: block;
		font-weight: 600;
		font-size: 0.92rem;
		color: var(--text);
	}

	.rule-hint {
		margin: 0.25rem 0 0.55rem;
		line-height: 1.4;
	}

	.option-row {
		display: flex;
		flex-wrap: wrap;
		gap: 0.45rem;
	}

	.option-chip,
	.option-card {
		margin: 0;
		font-family: var(--font-body);
		cursor: pointer;
		box-shadow: none;
		transition:
			border-color 0.12s ease,
			background 0.12s ease;
	}

	.option-chip:disabled,
	.option-card:disabled {
		opacity: 0.55;
		cursor: not-allowed;
	}

	.option-chip {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.4rem 0.8rem;
		border: 2px solid var(--border);
		border-radius: 999px;
		background: var(--surface-2);
		color: var(--text);
		font-size: 0.88rem;
		font-weight: 500;
	}

	.option-chip.selected {
		border-color: var(--brand);
		background: var(--brand-muted-you);
	}

	.option-column {
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
		margin-top: 0.45rem;
	}

	.option-card {
		display: flex;
		align-items: flex-start;
		gap: 0.6rem;
		width: 100%;
		padding: 0.65rem 0.75rem;
		border: 2px solid var(--border);
		border-radius: var(--radius);
		background: var(--surface-2);
		color: var(--text);
		font-size: 0.9rem;
		line-height: 1.4;
		text-align: left;
	}

	.option-card.selected {
		border-color: var(--brand);
		background: var(--brand-muted-you);
	}

	.option-dot {
		flex-shrink: 0;
		width: 1rem;
		height: 1rem;
		margin-top: 0.1rem;
		border-radius: 50%;
		border: 2px solid color-mix(in srgb, var(--text-muted) 50%, transparent);
		background: transparent;
		transition:
			border-color 0.12s ease,
			background 0.12s ease,
			box-shadow 0.12s ease;
	}

	.option-card.selected .option-dot {
		border-color: var(--brand);
		background: var(--brand);
		box-shadow: inset 0 0 0 2px var(--surface-2);
	}

	.option-text {
		flex: 1;
		min-width: 0;
	}

	.field-hint {
		margin: -0.35rem 0 0.35rem;
		font-size: 0.82rem;
		line-height: 1.4;
		color: var(--text-muted);
	}
</style>
