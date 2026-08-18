<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { isAppAdmin } from '$lib/admin';
	import {
		adminDeleteUser,
		fetchAdminLeagues,
		fetchAdminUsers,
		type AdminLeagueRow,
		type AdminUserRow
	} from '$lib/adminData';
	import { useAdmin, useAuth } from '$lib/auth';

	const auth = useAuth();
	const admin = useAdmin();

	const isAdmin = $derived(!auth.loading && auth.user !== null && isAppAdmin(auth.user.email));

	let leagues = $state<AdminLeagueRow[]>([]);
	let users = $state<AdminUserRow[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let deletingUserId = $state<string | null>(null);
	let deleteError = $state<string | null>(null);

	$effect(() => {
		if (auth.loading) return;
		if (!auth.user || !isAppAdmin(auth.user.email)) {
			goto(`${base}/`);
		}
	});

	$effect(() => {
		if (!isAdmin) return;

		loading = true;
		error = null;

		Promise.all([fetchAdminLeagues(), fetchAdminUsers()]).then(([leagueResult, userResult]) => {
			leagues = leagueResult.leagues;
			users = userResult.users;
			error = leagueResult.error ?? userResult.error;
			loading = false;
		});
	});

	async function handleDeleteUser(user: AdminUserRow) {
		if (deletingUserId) return;

		const leagueNote =
			user.leagues.length > 0
				? `\n\nThey will be removed from: ${user.leagues.map((league) => league.name).join(', ')}.`
				: '';
		const commissionerLeagues = user.leagues.filter((league) => league.is_commissioner && !league.is_public_demo);
		const extra =
			commissionerLeagues.length > 0
				? `\n\nLeagues they commission will be deleted: ${commissionerLeagues.map((league) => league.name).join(', ')}.`
				: '';

		const confirmed = confirm(
			`Delete ${user.display_name} (${user.email})? This cannot be undone.${leagueNote}${extra}`
		);
		if (!confirmed) return;

		deletingUserId = user.user_id;
		deleteError = null;

		const result = await adminDeleteUser(user.user_id);
		deletingUserId = null;

		if (result.error) {
			deleteError = result.error;
			return;
		}

		users = users.filter((row) => row.user_id !== user.user_id);
		const leagueResult = await fetchAdminLeagues();
		if (!leagueResult.error) {
			leagues = leagueResult.leagues;
		}
	}
</script>

<main class="page page-wide">
	<h1 class="page-title">Admin</h1>
	<p class="page-subtitle">Browse every league and account. You do not need to join a league to inspect it.</p>

	{#if auth.loading || !isAdmin}
		<p class="muted">Checking access…</p>
	{:else}
		<section class="card">
			<h2 class="section-title">Admin mode</h2>
			<p class="muted">
				When this is on, league overview pages show extra tools (remove players, delete league).
			</p>
			<label class="admin-toggle">
				<input
					type="checkbox"
					checked={admin.adminModeEnabled}
					onchange={(e) => admin.setAdminMode((e.currentTarget as HTMLInputElement).checked)}
				/>
				<span>{admin.adminModeEnabled ? 'On' : 'Off'}</span>
			</label>
		</section>

		{#if loading}
			<p class="muted">Loading directory…</p>
		{:else if error}
			<p class="auth-error" role="alert">{error}</p>
		{:else}
			<section class="card">
				<h2 class="section-title">Leagues</h2>
				{#if leagues.length === 0}
					<p class="muted">No leagues found.</p>
				{:else}
					<ul class="directory-list">
						{#each leagues as league (league.id)}
							<li>
								<a href="{base}/league/{league.id}" class="directory-link">
									<div class="directory-main">
										<span class="directory-name">{league.name}</span>
										<span class="directory-meta">
											{league.season_year} · {league.member_count}
											{league.member_count === 1 ? 'member' : 'members'} · {league.commissioner_name}
										</span>
									</div>
									<div class="badges">
										{#if league.is_public_demo}
											<span class="badge">Demo</span>
										{/if}
										{#if !league.is_active}
											<span class="badge">Inactive</span>
										{/if}
									</div>
								</a>
							</li>
						{/each}
					</ul>
				{/if}
			</section>

			<section class="card">
				<h2 class="section-title">Users</h2>
				{#if deleteError}
					<p class="auth-error" role="alert">{deleteError}</p>
				{/if}
				{#if users.length === 0}
					<p class="muted">No users found.</p>
				{:else}
					<ul class="user-list">
						{#each users as user (user.user_id)}
							<li class="user-card">
								<div class="user-head">
									<div>
										<p class="directory-name">{user.display_name}</p>
										<p class="directory-meta">{user.email}</p>
									</div>
									<button
										type="button"
										class="btn btn-ghost btn-sm"
										disabled={deletingUserId === user.user_id || user.user_id === auth.user?.id}
										onclick={() => handleDeleteUser(user)}
									>
										{deletingUserId === user.user_id ? 'Deleting…' : 'Delete'}
									</button>
								</div>
								{#if user.leagues.length === 0}
									<p class="muted">Not in any leagues.</p>
								{:else}
									<ul class="user-leagues">
										{#each user.leagues as league (league.id)}
											<li>
												<a href="{base}/league/{league.id}">{league.name}</a>
												<span class="directory-meta">
													{league.season_year}{#if league.is_commissioner} · commissioner{/if}{#if league.is_public_demo} · demo{/if}
												</span>
											</li>
										{/each}
									</ul>
								{/if}
							</li>
						{/each}
					</ul>
				{/if}
			</section>
		{/if}
	{/if}
</main>

<style>
	.card {
		margin-top: 1.25rem;
		padding: 1.1rem 1.25rem 1.25rem;
		border-radius: var(--radius);
		background: var(--surface);
		box-shadow: var(--shadow-sm);
	}

	.section-title {
		margin: 0 0 0.65rem;
		font-family: var(--font-display);
		font-size: 1.15rem;
		letter-spacing: -0.02em;
	}

	.muted {
		margin: 0;
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.admin-toggle {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		margin-top: 0.75rem;
		font-size: 0.9rem;
		font-weight: 600;
		color: var(--text-muted);
		cursor: pointer;
		user-select: none;
	}

	.admin-toggle input {
		width: 0.9rem;
		height: 0.9rem;
		accent-color: var(--danger);
	}

	.admin-toggle:has(input:checked) {
		color: var(--danger);
	}

	.directory-list,
	.user-list,
	.user-leagues {
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.directory-list {
		display: flex;
		flex-direction: column;
		gap: 0.55rem;
	}

	.directory-link,
	.user-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 0.85rem 0.95rem;
		border-radius: var(--radius);
		background: var(--surface-2);
		box-shadow: var(--shadow-sm);
		text-decoration: none;
		color: inherit;
	}

	.directory-link:hover {
		filter: brightness(1.04);
		color: inherit;
	}

	.directory-main {
		display: flex;
		flex-direction: column;
		gap: 0.15rem;
		min-width: 0;
	}

	.directory-name {
		margin: 0;
		font-weight: 700;
	}

	.directory-meta {
		color: var(--text-muted);
		font-size: 0.82rem;
	}

	.badges {
		display: flex;
		flex-wrap: wrap;
		gap: 0.35rem;
	}

	.badge {
		padding: 0.15rem 0.45rem;
		border-radius: var(--radius);
		background: var(--brand-muted);
		color: var(--text);
		font-size: 0.72rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.user-list {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.user-card {
		flex-direction: column;
		align-items: stretch;
	}

	.user-head {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.75rem;
	}

	.user-leagues {
		margin-top: 0.65rem;
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
	}

	.user-leagues a {
		font-weight: 600;
	}
</style>
