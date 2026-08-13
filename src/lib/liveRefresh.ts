import { browser } from '$app/environment';

const DATA_POLL_MS = 60_000;

const listeners = new Set<() => void>();

function notifyLiveRefresh() {
	if (typeof document !== 'undefined' && document.visibilityState !== 'visible') return;
	for (const listener of listeners) listener();
}

/** Register a data refetch for visibility, window focus, and a 60s poll. */
export function subscribeLiveRefresh(listener: () => void): () => void {
	listeners.add(listener);
	return () => {
		listeners.delete(listener);
	};
}

/** Call once from the root layout (browser only). */
export function startLiveRefresh(): () => void {
	if (!browser) return () => {};

	const onVisible = () => {
		if (document.visibilityState === 'visible') notifyLiveRefresh();
	};
	const pollId = window.setInterval(notifyLiveRefresh, DATA_POLL_MS);
	document.addEventListener('visibilitychange', onVisible);
	window.addEventListener('focus', notifyLiveRefresh);

	return () => {
		window.clearInterval(pollId);
		document.removeEventListener('visibilitychange', onVisible);
		window.removeEventListener('focus', notifyLiveRefresh);
		listeners.clear();
	};
}
