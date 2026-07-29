<script lang="ts">
	import { getGameKickoffInfo } from '$lib/gameKickoff';

	let { kickoffAt }: { kickoffAt: string } = $props();

	const info = $derived(getGameKickoffInfo(kickoffAt));
</script>

<div
	class="kickoff"
	class:highlighted={info.badges.length > 0}
>
	{#each info.badges as badge (badge.id)}
		<span
			class="slot-badge slot-{badge.id}"
			title={badge.label}
			aria-label={badge.label}
			data-tooltip={badge.label}
			tabindex="0"
		>{badge.short}</span>
	{/each}
	<time class="kickoff-time" datetime={kickoffAt}>{info.formatted}</time>
</div>

<style>
	.kickoff {
		display: flex;
		align-items: center;
		justify-content: center;
		flex-wrap: wrap;
		gap: 0.45rem;
		padding: 0.45rem 0.65rem;
		border-radius: var(--radius);
		background: var(--surface);
		border: none;
	}

	.kickoff.highlighted {
		padding: 0.5rem 0.7rem;
	}

	.kickoff-time {
		font-size: 0.82rem;
		font-weight: 600;
		color: var(--text-muted);
		font-variant-numeric: tabular-nums;
	}

	.kickoff.highlighted .kickoff-time {
		color: var(--text);
	}

	.slot-badge {
		position: relative;
		display: inline-flex;
		align-items: center;
		padding: 0.18rem 0.5rem;
		border-radius: var(--radius);
		font-size: 0.68rem;
		font-weight: 800;
		letter-spacing: 0.05em;
		text-transform: uppercase;
		border: none;
		box-shadow: var(--shadow-sm);
		cursor: help;
	}

	.slot-badge::after {
		content: attr(data-tooltip);
		position: absolute;
		left: 50%;
		bottom: calc(100% + 0.4rem);
		transform: translateX(-50%) translateY(0.15rem);
		padding: 0.35rem 0.55rem;
		border-radius: var(--radius);
		background: var(--text);
		color: var(--surface);
		font-size: 0.72rem;
		font-weight: 600;
		letter-spacing: 0.01em;
		text-transform: none;
		white-space: nowrap;
		box-shadow: var(--shadow);
		opacity: 0;
		pointer-events: none;
		transition:
			opacity 0.12s ease,
			transform 0.12s ease;
		z-index: 5;
	}

	.slot-badge:hover::after,
	.slot-badge:focus-visible::after {
		opacity: 1;
		transform: translateX(-50%) translateY(0);
	}

	.slot-badge:focus-visible {
		outline: 2px solid var(--brand);
		outline-offset: 2px;
	}

	.slot-tnf {
		color: #7dd3fc;
		background: rgba(0, 168, 225, 0.18);
		border-color: rgba(0, 168, 225, 0.45);
	}

	.slot-snf {
		color: #f5d76e;
		background: rgba(212, 175, 55, 0.16);
		border-color: rgba(212, 175, 55, 0.45);
	}

	.slot-mnf {
		color: #fca5a5;
		background: rgba(239, 68, 68, 0.16);
		border-color: rgba(239, 68, 68, 0.45);
	}

	.slot-international {
		color: #86efac;
		background: rgba(52, 211, 153, 0.16);
		border-color: rgba(52, 211, 153, 0.45);
	}

	.slot-season-opener {
		color: #d8b4fe;
		background: rgba(168, 85, 247, 0.18);
		border-color: rgba(168, 85, 247, 0.45);
	}

	.slot-thanksgiving-eve {
		color: #fdba74;
		background: rgba(251, 146, 60, 0.16);
		border-color: rgba(251, 146, 60, 0.45);
	}

	.slot-thanksgiving {
		color: #fdba74;
		background: rgba(234, 88, 12, 0.18);
		border-color: rgba(234, 88, 12, 0.5);
	}

	.slot-black-friday {
		color: #e2e8f0;
		background: rgba(15, 23, 42, 0.55);
		border-color: rgba(148, 163, 184, 0.45);
	}

	.slot-christmas-eve {
		color: #86efac;
		background: rgba(34, 197, 94, 0.16);
		border-color: rgba(34, 197, 94, 0.45);
	}

	.slot-christmas {
		color: #fca5a5;
		background: rgba(220, 38, 38, 0.18);
		border-color: rgba(220, 38, 38, 0.5);
	}

	.slot-saturday {
		color: #cbd5e1;
		background: rgba(148, 163, 184, 0.16);
		border-color: rgba(148, 163, 184, 0.45);
	}

	:global([data-theme='light']) .slot-tnf {
		color: #fff;
		background: #0369a1;
		border-color: #0369a1;
	}

	:global([data-theme='light']) .slot-snf {
		color: #1a1408;
		background: #ca8a04;
		border-color: #ca8a04;
	}

	:global([data-theme='light']) .slot-mnf {
		color: #fff;
		background: #dc2626;
		border-color: #dc2626;
	}

	:global([data-theme='light']) .slot-international {
		color: #fff;
		background: #059669;
		border-color: #059669;
	}

	:global([data-theme='light']) .slot-season-opener {
		color: #fff;
		background: #7c3aed;
		border-color: #7c3aed;
	}

	:global([data-theme='light']) .slot-thanksgiving-eve {
		color: #fff;
		background: #ea580c;
		border-color: #ea580c;
	}

	:global([data-theme='light']) .slot-thanksgiving {
		color: #fff;
		background: #c2410c;
		border-color: #c2410c;
	}

	:global([data-theme='light']) .slot-black-friday {
		color: #fff;
		background: #334155;
		border-color: #334155;
	}

	:global([data-theme='light']) .slot-christmas-eve {
		color: #fff;
		background: #15803d;
		border-color: #15803d;
	}

	:global([data-theme='light']) .slot-christmas {
		color: #fff;
		background: #b91c1c;
		border-color: #b91c1c;
	}

	:global([data-theme='light']) .slot-saturday {
		color: #fff;
		background: #64748b;
		border-color: #64748b;
	}
</style>
