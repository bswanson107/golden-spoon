export type Theme = 'dark' | 'light';

const STORAGE_KEY = 'golden-spoon-theme';

function readStoredTheme(): Theme {
	if (typeof localStorage === 'undefined') return 'dark';
	const stored = localStorage.getItem(STORAGE_KEY);
	return stored === 'light' ? 'light' : 'dark';
}

function applyTheme(theme: Theme) {
	if (typeof document === 'undefined') return;
	document.documentElement.dataset.theme = theme;
}

let theme = $state<Theme>('dark');

export function initTheme() {
	theme = readStoredTheme();
	applyTheme(theme);
}

export function getTheme(): Theme {
	return theme;
}

export function setTheme(next: Theme) {
	theme = next;
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(STORAGE_KEY, next);
	}
	applyTheme(next);
}

export function toggleTheme() {
	setTheme(theme === 'dark' ? 'light' : 'dark');
}
