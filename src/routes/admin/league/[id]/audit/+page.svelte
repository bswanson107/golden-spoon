<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { base } from '$app/paths';
	import { isAppAdmin } from '$lib/admin';
	import { fetchAdminLeagues, fetchAdminPickAuditLog, type AdminPickAuditRow } from '$lib/adminData';
	import { useAuth } from '$lib/auth';

	const auth = useAuth();

	type SortKey = 'name' | 'week' | 'timestamp';
	type SortDir = 'asc' | 'desc';

	const leagueId = $derived($page.params.id);
	const isAdmin = $derived(!auth.loading && auth.user !== null && isAppAdmin(auth.user.email));

	let leagueName = $state<string | null>(null);
	let entries = $state<AdminPickAuditRow[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let sortKey = $state<SortKey>('timestamp');
	let sortDir = $state<SortDir>('desc');

	const sortedEntries = $derived(
		[...entries].sort((a, b) => {
			let cmp = 0;

			if (sortKey === 'name') {
				cmp = a.display_name.localeCompare(b.display_name, undefined, { sensitivity: 'base' });
			} else if (sortKey === 'week') {
				cmp = a.week_number - b.week_number;
			} else {
				cmp = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
			}

			if (cmp === 0) {
				cmp = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
			}

			return sortDir === 'asc' ? cmp : -cmp;
		})
	);

	$effect(() => {
		if (auth.loading) return;
		if (!auth.user || !isAppAdmin(auth.user.email)) {
			goto(`${base}/`);
		}
	});

	$effect(() => {
		const id = leagueId;
		if (!isAdmin || !id) return;

		loading = true;
		error = null;

		Promise.all([fetchAdminLeagues(), fetchAdminPickAuditLog(id)]).then(
			([leagueResult, auditResult]) => {
				const league = leagueResult.leagues.find((row) => row.id === id);
				leagueName = league?.name ?? null;
				entries = auditResult.entries;
				error = leagueResult.error ?? auditResult.error;
				loading = false;
			}
		);
	});

	function defaultDirFor(key: SortKey): SortDir {
		if (key === 'timestamp') return 'desc';
		return 'asc';
	}

	function toggleSort(key: SortKey) {
		if (sortKey === key) {
			sortDir = sortDir === 'asc' ? 'desc' : 'asc';
			return;
		}

		sortKey = key;
		sortDir = defaultDirFor(key);
	}

	function sortIndicator(key: SortKey): string {
		if (sortKey !== key) return '';
		return sortDir === 'asc' ? ' ↑' : ' ↓';
	}

	function ariaSort(key: SortKey): 'ascending' | 'descending' | 'none' {
		if (sortKey !== key) return 'none';
		return sortDir === 'asc' ? 'ascending' : 'descending';
	}

	function formatTimestamp(value: string): string {
		return new Date(value).toLocaleString(undefined, {
			month: 'short',
			day: 'numeric',
			year: 'numeric',
			hour: 'numeric',
			minute: '2-digit'
		});
	}

	function teamLabel(abbreviation: string | null, name: string | null, teamId: string | null): string {
		if (abbreviation && name) return `${name} (${abbreviation})`;
		return abbreviation ?? name ?? teamId ?? 'Unknown team';
	}

	function actionSummary(entry: AdminPickAuditRow): string {
		const team = teamLabel(entry.team_abbreviation, entry.team_name, entry.team_id);
		if (entry.action === 'picked') return `Picked ${team}`;
		if (entry.action === 'cleared') return `Cleared ${team}`;
		const previous = teamLabel(
			entry.previous_team_abbreviation,
			entry.previous_team_name,
			entry.previous_team_id
		);
		return `Changed ${previous} → ${team}`;
	}

	function actionClass(action: AdminPickAuditRow['action']): string {
		if (action === 'picked') return 'action-picked';
		if (action === 'changed') return 'action-changed';
		return 'action-cleared';
	}
</script>

<main class="page page-wide">
	<p class="back-link">
		<a href="{base}/admin">← Admin</a>
	</p>

	<h1 class="page-title">Pick audit log</h1>
	{#if leagueName}
		<p class="page-subtitle">{leagueName}</p>
	{/if}
	<p class="muted intro">
		Every pick selection, change, and clear for this league. Changes before this feature shipped
		are shown as the pick that existed at migration time.
	</p>

	{#if auth.loading || !isAdmin}
		<p class="muted">Checking access…</p>
	{:else if loading}
		<p class="muted">Loading activity…</p>
	{:else if error}
		<p class="auth-error" role="alert">{error}</p>
	{:else if entries.length === 0}
		<p class="muted">No pick activity recorded yet.</p>
	{:else}
		<section class="card">
			<div class="table-wrap">
				<table class="audit-table">
					<colgroup>
						<col class="c-timestamp" />
						<col class="c-name" />
						<col class="c-week" />
						<col class="c-action" />
						<col class="c-detail" />
					</colgroup>
					<thead>
						<tr>
							<th scope="col" aria-sort={ariaSort('timestamp')}>
								<button type="button" class="sort-btn" onclick={() => toggleSort('timestamp')}>
									Timestamp{sortIndicator('timestamp')}
								</button>
							</th>
							<th scope="col" aria-sort={ariaSort('name')}>
								<button type="button" class="sort-btn" onclick={() => toggleSort('name')}>
									Name{sortIndicator('name')}
								</button>
							</th>
							<th scope="col" aria-sort={ariaSort('week')}>
								<button type="button" class="sort-btn" onclick={() => toggleSort('week')}>
									Week{sortIndicator('week')}
								</button>
							</th>
							<th scope="col">Action</th>
							<th scope="col">Detail</th>
						</tr>
					</thead>
					<tbody>
						{#each sortedEntries as entry (entry.id)}
							<tr>
								<td class="col-timestamp">
									<time datetime={entry.created_at}>{formatTimestamp(entry.created_at)}</time>
								</td>
								<td class="col-name">{entry.display_name}</td>
								<td class="col-week">{entry.week_number}</td>
								<td class="col-action">
									<span class="action-badge {actionClass(entry.action)}">{entry.action}</span>
								</td>
								<td class="col-detail">{actionSummary(entry)}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</section>
	{/if}
</main>

<style>
	.back-link {
		margin: 0 0 0.5rem;
		font-size: 0.88rem;
	}

	.intro {
		margin: 0 0 1rem;
		max-width: 42rem;
	}

	.muted {
		margin: 0;
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.card {
		margin-top: 0.5rem;
		padding: 0;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
		overflow: hidden;
	}

	.table-wrap {
		overflow-x: auto;
	}

	.audit-table {
		width: 100%;
		min-width: 40rem;
		border-collapse: collapse;
		font-size: 0.88rem;
	}

	.c-timestamp {
		width: 11rem;
	}

	.c-name {
		width: 9rem;
	}

	.c-week {
		width: 4rem;
	}

	.c-action {
		width: 6rem;
	}

	.c-detail {
		width: auto;
	}

	thead {
		background: var(--surface);
	}

	th {
		padding: 0.55rem 0.75rem;
		border-bottom: 1px solid var(--border);
		color: var(--text-muted);
		font-weight: 600;
		font-size: 0.72rem;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		text-align: left;
		vertical-align: bottom;
		white-space: nowrap;
	}

	.sort-btn {
		display: inline-flex;
		align-items: center;
		gap: 0.15rem;
		padding: 0;
		border: none;
		background: transparent;
		color: inherit;
		font: inherit;
		text-transform: inherit;
		letter-spacing: inherit;
		cursor: pointer;
	}

	.sort-btn:hover {
		color: var(--text);
	}

	td {
		padding: 0.65rem 0.75rem;
		border-bottom: 1px solid var(--border);
		vertical-align: middle;
	}

	tbody tr:nth-child(odd) {
		background: color-mix(in srgb, var(--text) 3%, var(--surface));
	}

	tbody tr:last-child td {
		border-bottom: none;
	}

	.col-timestamp {
		color: var(--text-muted);
		font-size: 0.82rem;
		white-space: nowrap;
	}

	.col-name {
		font-weight: 600;
	}

	.col-week {
		font-variant-numeric: tabular-nums;
	}

	.col-detail {
		line-height: 1.35;
	}

	.action-badge {
		display: inline-block;
		padding: 0.12rem 0.4rem;
		border-radius: var(--radius);
		font-size: 0.68rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.action-picked {
		background: color-mix(in srgb, var(--brand) 18%, var(--surface));
		color: var(--text);
	}

	.action-changed {
		background: color-mix(in srgb, #d4a017 22%, var(--surface));
		color: var(--text);
	}

	.action-cleared {
		background: color-mix(in srgb, var(--danger) 16%, var(--surface));
		color: var(--text);
	}
</style>
