import { browser } from '$app/environment';

const ADMIN_MODE_KEY = 'golden-spoon-admin-mode';
const ADMIN_EMAIL_LOCAL_PART = 'bswanson107';

export function isAppAdmin(email: string | null | undefined): boolean {
	if (!email) return false;
	const localPart = email.toLowerCase().trim().split('@')[0];
	return localPart === ADMIN_EMAIL_LOCAL_PART;
}

export function loadAdminMode(): boolean {
	if (!browser) return false;

	try {
		return localStorage.getItem(ADMIN_MODE_KEY) === 'true';
	} catch {
		return false;
	}
}

export function saveAdminMode(enabled: boolean): void {
	if (!browser) return;
	localStorage.setItem(ADMIN_MODE_KEY, enabled ? 'true' : 'false');
}
