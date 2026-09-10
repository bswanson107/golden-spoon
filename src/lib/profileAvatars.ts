/** Static avatar files live in `static/avatars/` and are keyed by filename, not user id. */

const AVATAR_DIR = 'avatars';

/** Reject path traversal; allow simple filenames like `Ben.png` or `Ben`. */
export function normalizeAvatarKey(raw: string): string | null {
	const trimmed = raw.trim();
	if (!trimmed) return null;
	if (trimmed.includes('/') || trimmed.includes('\\') || trimmed.includes('..')) {
		return null;
	}
	return trimmed;
}

/** Build a site URL for a static avatar file from its key. */
export function resolveAvatarUrl(
	avatarKey: string | null | undefined,
	basePath: string
): string | null {
	const key = normalizeAvatarKey(avatarKey ?? '');
	if (!key) return null;

	const filename = key.includes('.') ? key : `${key}.png`;
	const base = basePath.replace(/\/$/, '');
	return `${base}/${AVATAR_DIR}/${encodeURIComponent(filename)}`;
}
