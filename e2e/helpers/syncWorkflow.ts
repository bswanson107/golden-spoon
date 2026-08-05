import { execFile } from 'node:child_process';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

export const SYNC_NFL_WORKFLOW = 'Sync NFL Data';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const markerPath = path.join(root, 'e2e', '.sync-nfl-paused-by-e2e');

function skipRequested(): boolean {
	return process.env.E2E_SKIP_WORKFLOW_PAUSE === '1' || process.env.E2E_SKIP_WORKFLOW_PAUSE === 'true';
}

async function runGh(args: string[]): Promise<{ ok: boolean; stdout: string; stderr: string }> {
	try {
		const { stdout, stderr } = await execFileAsync('gh', args, {
			cwd: root,
			encoding: 'utf8',
			maxBuffer: 1024 * 1024
		});
		return { ok: true, stdout: stdout ?? '', stderr: stderr ?? '' };
	} catch (err) {
		const e = err as { stdout?: string; stderr?: string; message?: string };
		return {
			ok: false,
			stdout: e.stdout ?? '',
			stderr: e.stderr ?? e.message ?? String(err)
		};
	}
}

/** True if the workflow is currently disabled in Actions. */
export async function isSyncNflWorkflowDisabled(): Promise<boolean | null> {
	const result = await runGh(['workflow', 'list', '--json', 'name,state']);
	if (!result.ok) {
		console.warn('[e2e] Could not list workflows via gh:', result.stderr.trim());
		return null;
	}
	try {
		const workflows = JSON.parse(result.stdout) as Array<{ name: string; state: string }>;
		const sync = workflows.find((w) => w.name === SYNC_NFL_WORKFLOW);
		if (!sync) {
			console.warn(`[e2e] Workflow "${SYNC_NFL_WORKFLOW}" not found`);
			return null;
		}
		return sync.state === 'disabled_manually' || sync.state === 'disabled_inactivity';
	} catch {
		console.warn('[e2e] Failed to parse gh workflow list output');
		return null;
	}
}

/**
 * Disable Sync NFL Data for the suite. Writes a marker only when this run
 * disabled it, so teardown does not re-enable a workflow the user left off.
 */
export async function pauseSyncNflWorkflow(): Promise<void> {
	if (skipRequested()) {
		console.log('[e2e] Skipping Sync NFL workflow pause (E2E_SKIP_WORKFLOW_PAUSE)');
		return;
	}

	const disabled = await isSyncNflWorkflowDisabled();
	if (disabled === true) {
		console.log(`[e2e] "${SYNC_NFL_WORKFLOW}" already disabled; leaving as-is`);
		return;
	}
	if (disabled === null) {
		console.warn(
			`[e2e] Could not check "${SYNC_NFL_WORKFLOW}" state. Install/auth gh, or set E2E_SKIP_WORKFLOW_PAUSE=1`
		);
		return;
	}

	const result = await runGh(['workflow', 'disable', SYNC_NFL_WORKFLOW]);
	if (!result.ok) {
		console.warn(`[e2e] Failed to disable "${SYNC_NFL_WORKFLOW}":`, result.stderr.trim());
		return;
	}

	await fs.writeFile(markerPath, new Date().toISOString(), 'utf8');
	console.log(`[e2e] Disabled "${SYNC_NFL_WORKFLOW}" for this run`);
}

/** Re-enable Sync NFL Data only if this suite disabled it. */
export async function resumeSyncNflWorkflow(): Promise<void> {
	if (skipRequested()) return;

	let hadMarker = false;
	try {
		await fs.access(markerPath);
		hadMarker = true;
	} catch {
		hadMarker = false;
	}

	if (!hadMarker) {
		console.log(`[e2e] No pause marker; not re-enabling "${SYNC_NFL_WORKFLOW}"`);
		return;
	}

	const result = await runGh(['workflow', 'enable', SYNC_NFL_WORKFLOW]);
	try {
		await fs.unlink(markerPath);
	} catch {
		/* ignore */
	}

	if (!result.ok) {
		console.warn(
			`[e2e] Failed to re-enable "${SYNC_NFL_WORKFLOW}" — do so manually: gh workflow enable "${SYNC_NFL_WORKFLOW}"`,
			result.stderr.trim()
		);
		return;
	}

	console.log(`[e2e] Re-enabled "${SYNC_NFL_WORKFLOW}"`);
}
