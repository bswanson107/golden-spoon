<script lang="ts">
	import TeamLogo from '$lib/components/TeamLogo.svelte';
	import { NFL_DIVISIONS, getTeamName, type NFLTeamCode } from '$lib/data/nflTeams';

	const SEASON_WEEKS = 18;
	const LOGO_SIZE = 40;
	const WEEK_CELL_LOGO = 28;
	const weekNumbers = Array.from({ length: SEASON_WEEKS }, (_, i) => i + 1);

	let {
		open = false,
		pickedTeamIds = [],
		pickedWeekByTeam = {},
		teamByWeek = {},
		onClose
	}: {
		open?: boolean;
		/** Team codes the user has already saved a pick for. */
		pickedTeamIds?: string[];
		/** Week number per team code. */
		pickedWeekByTeam?: Record<string, number>;
		/** Team code per week number (1–18). */
		teamByWeek?: Record<number, string>;
		onClose: () => void;
	} = $props();

	const pickedSet = $derived(new Set(pickedTeamIds.map((id) => id.toUpperCase())));
	const picksCount = $derived(pickedSet.size);

	function isPicked(teamCode: NFLTeamCode): boolean {
		return pickedSet.has(teamCode);
	}

	function weekForTeam(teamCode: NFLTeamCode): number | undefined {
		return pickedWeekByTeam[teamCode] ?? pickedWeekByTeam[teamCode.toUpperCase()];
	}

	function teamForWeek(week: number): string | null {
		const code = teamByWeek[week];
		return code ? code.toUpperCase() : null;
	}

	function teamTitle(teamCode: NFLTeamCode): string {
		const name = getTeamName(teamCode);
		const week = weekForTeam(teamCode);
		if (week !== undefined) return `${name} · Week ${week}`;
		return name;
	}

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
			aria-labelledby="season-picks-modal-title"
		>
			<header class="modal-header">
				<h2 id="season-picks-modal-title" class="modal-title">Season Outlook</h2>
			</header>

			<div class="modal-body">
				<p class="modal-subtitle">Picks: {picksCount} / {SEASON_WEEKS}</p>

				<section class="weeks-section" aria-label="Picks by week">
					<ul class="weeks-grid">
						{#each weekNumbers as week (week)}
							{@const teamCode = teamForWeek(week)}
							<li class="week-cell" class:has-pick={teamCode !== null}>
								<span class="week-num">Wk {week}</span>
								{#if teamCode}
									<TeamLogo teamCode={teamCode} size={WEEK_CELL_LOGO} />
									<span class="week-team">{teamCode}</span>
								{:else}
									<span class="week-empty">—</span>
								{/if}
							</li>
						{/each}
					</ul>
				</section>

				<p class="section-label">Remaining Teams</p>
				<div class="divisions">
					{#each NFL_DIVISIONS as division (division.label)}
						<section class="division">
							<h3 class="division-label">{division.label}</h3>
							<ul class="team-grid">
								{#each division.teams as teamCode (teamCode)}
									{@const used = isPicked(teamCode)}
									{@const usedWeek = weekForTeam(teamCode)}
									<li>
										<div
											class="team-chip"
											class:is-picked={used}
											title={teamTitle(teamCode)}
										>
											{#if used && usedWeek !== undefined}
												<span class="week-badge">Week {usedWeek}</span>
											{/if}
											<div class="team-chip-body">
												<TeamLogo teamCode={teamCode} size={LOGO_SIZE} />
												<span class="team-abbr">{teamCode}</span>
											</div>
										</div>
									</li>
								{/each}
							</ul>
						</section>
					{/each}
				</div>
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
		width: min(100%, 36rem);
		max-height: min(90vh, 44rem);
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
		margin: 0;
		font-family: var(--font-display);
		font-size: 1.25rem;
		color: var(--text);
	}

	.modal-subtitle {
		margin: 0 0 0.75rem;
		font-size: 0.95rem;
		font-weight: 700;
		color: var(--text);
		text-align: center;
	}

	.modal-body {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		padding-right: 0.15rem;
	}

	.weeks-section {
		margin-bottom: 1.15rem;
	}

	.weeks-grid {
		display: grid;
		grid-template-columns: repeat(6, minmax(0, 1fr));
		gap: 0.4rem;
		margin: 0;
		padding: 0;
		list-style: none;
	}

	.week-cell {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 0.2rem;
		min-height: 4.1rem;
		padding: 0.35rem 0.2rem;
		border-radius: var(--radius);
		background: color-mix(in srgb, var(--text) 5%, var(--surface));
		box-shadow: var(--shadow-sm);
	}

	.week-cell.has-pick {
		background: color-mix(in srgb, var(--text) 8%, var(--surface));
	}

	.week-num {
		font-size: 0.62rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--text-muted);
	}

	.week-team {
		font-size: 0.65rem;
		font-weight: 700;
		letter-spacing: 0.03em;
		color: var(--text);
	}

	.week-empty {
		font-size: 0.9rem;
		font-weight: 600;
		color: var(--text-muted);
		line-height: 1;
		opacity: 0.55;
	}

	.section-label {
		margin: 0 0 0.75rem;
		font-size: 0.95rem;
		font-weight: 700;
		color: var(--text);
		text-align: center;
	}

	.divisions {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1rem 0.75rem;
		width: 100%;
	}

	.division {
		min-width: 0;
	}

	.division-label {
		margin: 0 0 0.4rem;
		font-size: 0.8rem;
		font-weight: 700;
		color: var(--text-muted);
		text-align: center;
	}

	.team-grid {
		display: grid;
		grid-template-columns: repeat(4, minmax(0, 1fr));
		gap: 0.45rem;
		margin: 0;
		padding: 0;
		list-style: none;
	}

	.team-chip {
		position: relative;
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: 0.4rem 0.25rem 0.35rem;
		border-radius: var(--radius);
		border: 2px solid transparent;
		background: transparent;
	}

	.team-chip-body {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.25rem;
	}

	.team-chip.is-picked {
		border: 2px dotted var(--text-muted);
	}

	.team-chip.is-picked .team-chip-body {
		opacity: 0.72;
		filter: grayscale(0.75);
	}

	.week-badge {
		position: absolute;
		top: -0.2rem;
		right: -0.15rem;
		z-index: 1;
		padding: 0.1rem 0.3rem;
		border-radius: var(--radius);
		background: #3b82f6;
		color: #fff;
		font-size: 0.55rem;
		font-weight: 800;
		letter-spacing: 0.02em;
		line-height: 1.2;
		white-space: nowrap;
		/* Keep full color even when the logo body is muted */
		opacity: 1;
		filter: none;
	}

	.team-abbr {
		font-size: 0.68rem;
		font-weight: 700;
		letter-spacing: 0.04em;
		color: var(--text);
	}

	.team-chip.is-picked .team-abbr {
		color: var(--text-muted);
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
		.weeks-grid {
			grid-template-columns: repeat(3, minmax(0, 1fr));
		}

		.divisions {
			grid-template-columns: 1fr;
		}

		.team-grid {
			gap: 0.35rem;
		}

		.team-chip {
			padding: 0.3rem 0.15rem 0.25rem;
		}
	}
</style>
