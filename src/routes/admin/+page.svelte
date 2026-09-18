<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { isAppAdmin } from '$lib/admin';
	import {
		adminDeleteUser,
		adminSetLeagueParodySponsorships,
		adminSetLeagueProfilePictures,
		adminUpdateUser,
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
	let editingUserId = $state<string | null>(null);
	let editDisplayName = $state('');
	let editAvatarKey = $state('');
	let editCanChangeDisplayName = $state(true);
	let savingUserId = $state<string | null>(null);
	let editError = $state<string | null>(null);
	let togglingLeagueId = $state<string | null>(null);
	let leagueToggleError = $state<string | null>(null);

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

	function openEditUser(user: AdminUserRow) {
		editingUserId = user.user_id;
		editDisplayName = user.display_name;
		editAvatarKey = user.avatar_key ?? '';
		editCanChangeDisplayName = user.can_change_display_name;
		editError = null;
	}

	function cancelEditUser() {
		editingUserId = null;
		editError = null;
	}

	async function handleSaveUser(user: AdminUserRow) {
		if (savingUserId) return;

		const trimmed = editDisplayName.trim();
		if (!trimmed) {
			editError = 'Display name cannot be empty.';
			return;
		}

		savingUserId = user.user_id;
		editError = null;

		const avatarKey = editAvatarKey.trim();
		const result = await adminUpdateUser(
			user.user_id,
			trimmed,
			editCanChangeDisplayName,
			avatarKey
		);
		savingUserId = null;

		if (result.error) {
			editError = result.error;
			return;
		}

		users = users.map((row) =>
			row.user_id === user.user_id
				? {
						...row,
						display_name: trimmed,
						avatar_key: avatarKey || null,
						can_change_display_name: editCanChangeDisplayName
					}
				: row
		);

		const leagueResult = await fetchAdminLeagues();
		if (!leagueResult.error) {
			leagues = leagueResult.leagues;
		}

		editingUserId = null;
	}

	async function handleToggleProfilePictures(league: AdminLeagueRow, enabled: boolean) {
		if (togglingLeagueId) return;

		togglingLeagueId = league.id;
		leagueToggleError = null;

		const result = await adminSetLeagueProfilePictures(league.id, enabled);
		togglingLeagueId = null;

		if (result.error) {
			leagueToggleError = result.error;
			return;
		}

		leagues = leagues.map((row) =>
			row.id === league.id ? { ...row, show_profile_pictures: enabled } : row
		);
	}

	async function handleToggleParodySponsorships(league: AdminLeagueRow, enabled: boolean) {
		if (togglingLeagueId) return;

		togglingLeagueId = league.id;
		leagueToggleError = null;

		const result = await adminSetLeagueParodySponsorships(league.id, enabled);
		togglingLeagueId = null;

		if (result.error) {
			leagueToggleError = result.error;
			return;
		}

		leagues = leagues.map((row) =>
			row.id === league.id ? { ...row, show_parody_sponsorships: enabled } : row
		);
	}

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
				{#if leagueToggleError}
					<p class="auth-error" role="alert">{leagueToggleError}</p>
				{/if}
				{#if leagues.length === 0}
					<p class="muted">No leagues found.</p>
				{:else}
					<ul class="directory-list">
						{#each leagues as league (league.id)}
							<li class="league-row">
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
								<div class="league-actions">
									<a href="{base}/admin/league/{league.id}/audit" class="btn btn-ghost btn-sm">
										Audit log
									</a>
									<label class="league-toggle">
										<input
											type="checkbox"
											checked={league.show_profile_pictures}
											disabled={togglingLeagueId === league.id}
											onchange={(event) =>
												handleToggleProfilePictures(
													league,
													(event.currentTarget as HTMLInputElement).checked
												)}
										/>
										<span>Profile pics</span>
									</label>
									<label class="league-toggle">
										<input
											type="checkbox"
											checked={league.show_parody_sponsorships}
											disabled={togglingLeagueId === league.id}
											onchange={(event) =>
												handleToggleParodySponsorships(
													league,
													(event.currentTarget as HTMLInputElement).checked
												)}
										/>
										<span>Parody ads</span>
									</label>
								</div>
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
									<div class="user-identity">
										<div class="user-name-row">
											<p class="directory-name">{user.display_name}</p>
											<button
												type="button"
												class="icon-btn edit-btn"
												aria-label="Edit {user.display_name}"
												disabled={savingUserId === user.user_id || deletingUserId === user.user_id}
												onclick={() => openEditUser(user)}
											>
												<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">
													<path
														fill="none"
														stroke="currentColor"
														stroke-width="1.75"
														stroke-linecap="round"
														stroke-linejoin="round"
														d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17v3ZM14 6l3 3"
													/>
												</svg>
											</button>
										</div>
										<p class="directory-meta">{user.email}</p>
										{#if !user.can_change_display_name}
											<p class="lock-note">Display name locked</p>
										{/if}
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

								{#if editingUserId === user.user_id}
									<form
										class="user-edit-form"
										onsubmit={(event) => {
											event.preventDefault();
											handleSaveUser(user);
										}}
									>
										<label class="edit-label" for="edit-name-{user.user_id}">Display name</label>
										<input
											id="edit-name-{user.user_id}"
											type="text"
											bind:value={editDisplayName}
											maxlength="40"
											disabled={savingUserId === user.user_id}
											required
										/>

										<label class="edit-label" for="edit-avatar-{user.user_id}">Avatar file</label>
										<input
											id="edit-avatar-{user.user_id}"
											type="text"
											bind:value={editAvatarKey}
											placeholder="Ben.png"
											disabled={savingUserId === user.user_id}
										/>
										<p class="edit-hint muted">
											File in static/avatars/ (e.g. Ben.png). Tied to this account, not display name.
											Leave blank to clear.
										</p>

										<label class="edit-toggle">
											<input
												type="checkbox"
												bind:checked={editCanChangeDisplayName}
												disabled={savingUserId === user.user_id}
											/>
											<span>Allow user to change their display name</span>
										</label>

										{#if editError}
											<p class="auth-error" role="alert">{editError}</p>
										{/if}

										<div class="edit-actions">
											<button
												type="button"
												class="btn btn-ghost btn-sm"
												disabled={savingUserId === user.user_id}
												onclick={cancelEditUser}
											>
												Cancel
											</button>
											<button
												type="submit"
												class="btn btn-primary btn-sm"
												disabled={savingUserId === user.user_id}
											>
												{savingUserId === user.user_id ? 'Saving…' : 'Save'}
											</button>
										</div>
									</form>
								{/if}
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

	.league-row {
		display: flex;
		align-items: stretch;
		gap: 0.65rem;
	}

	.league-row .directory-link {
		flex: 1;
		min-width: 0;
	}

	.league-actions {
		display: flex;
		flex-direction: column;
		align-items: stretch;
		gap: 0.45rem;
	}

	.league-actions .btn {
		justify-content: center;
		white-space: nowrap;
	}

	.league-toggle {
		display: inline-flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 0.2rem;
		padding: 0.55rem 0.65rem;
		border-radius: var(--radius);
		background: var(--surface-2);
		box-shadow: var(--shadow-sm);
		font-size: 0.72rem;
		font-weight: 600;
		color: var(--text-muted);
		cursor: pointer;
		user-select: none;
		white-space: nowrap;
	}

	.league-toggle input {
		width: 0.95rem;
		height: 0.95rem;
		accent-color: var(--brand);
	}

	.league-toggle:has(input:checked) {
		color: var(--text);
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

	.user-identity {
		min-width: 0;
	}

	.user-name-row {
		display: flex;
		align-items: center;
		gap: 0.35rem;
	}

	.edit-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 1.85rem;
		height: 1.85rem;
		padding: 0;
		border: none;
		border-radius: var(--radius);
		background: transparent;
		color: var(--text-muted);
		box-shadow: none;
		cursor: pointer;
	}

	.edit-btn:hover:not(:disabled) {
		color: var(--text);
		background: color-mix(in srgb, var(--text) 8%, var(--surface-2));
	}

	.edit-btn:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.edit-btn .icon {
		width: 1rem;
		height: 1rem;
	}

	.lock-note {
		margin: 0.2rem 0 0;
		color: var(--text-muted);
		font-size: 0.75rem;
		font-weight: 600;
	}

	.user-edit-form {
		display: flex;
		flex-direction: column;
		gap: 0.55rem;
		margin-top: 0.75rem;
		padding-top: 0.75rem;
		border-top: 1px solid var(--border);
	}

	.edit-label {
		font-size: 0.82rem;
		font-weight: 600;
		color: var(--text-muted);
	}

	.user-edit-form input[type='text'],
	.user-edit-form input[type='url'] {
		padding: 0.55rem 0.65rem;
		border: none;
		border-radius: var(--radius);
		background: var(--input-bg);
		color: var(--text);
		font-size: 0.95rem;
		font-family: var(--font-body);
		box-shadow: var(--shadow-sm);
	}

	.edit-hint {
		margin: -0.15rem 0 0;
		font-size: 0.78rem;
	}

	.edit-toggle {
		display: flex;
		align-items: flex-start;
		gap: 0.45rem;
		font-size: 0.88rem;
		color: var(--text);
		cursor: pointer;
	}

	.edit-toggle input {
		width: 0.95rem;
		height: 0.95rem;
		margin-top: 0.15rem;
		accent-color: var(--brand);
	}

	.edit-actions {
		display: flex;
		justify-content: flex-end;
		gap: 0.45rem;
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
