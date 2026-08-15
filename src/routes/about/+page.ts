import { redirect } from '@sveltejs/kit';

/** Old bookmarks and hamburger links that still point at /about. */
export function load() {
	throw redirect(308, '/');
}
