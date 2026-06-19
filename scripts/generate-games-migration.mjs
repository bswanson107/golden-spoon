import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { normalizedWinPcts } from '../src/lib/sync/winPct.ts';

const TEAM_MAP = { LA: 'LAR' };

function mapTeam(abbr) {
	if (!abbr) return null;
	return TEAM_MAP[abbr] ?? abbr;
}

function parseCsvLine(line) {
	return line.split(',').map((c) => c.trim().replace(/\r$/, ''));
}

function winPcts(awayMl, homeMl) {
	return normalizedWinPcts(
		awayMl === '' || awayMl == null ? null : Number(awayMl),
		homeMl === '' || homeMl == null ? null : Number(homeMl)
	);
}

function sqlNum(value) {
	if (value === null || value === undefined || value === '') return 'null';
	return String(value);
}

function sqlStr(value) {
	if (value === null || value === undefined || value === '') return 'null';
	return `'${String(value).replace(/'/g, "''")}'`;
}

function kickoffExpr(gameday, gametime) {
	return `('${gameday} ${gametime}:00'::timestamp AT TIME ZONE 'America/New_York')`;
}

function loadGames(csvPath, seasonYear) {
	const lines = readFileSync(csvPath, 'utf8').trim().split('\n');
	const header = parseCsvLine(lines[0]);
	const games = [];

	for (const line of lines.slice(1)) {
		const cols = parseCsvLine(line);
		const row = Object.fromEntries(header.map((key, i) => [key, cols[i] ?? '']));
		if (row.game_type !== 'REG') continue;

		const awayScore = row.away_score === '' ? null : Number(row.away_score);
		const homeScore = row.home_score === '' ? null : Number(row.home_score);
		const hasScores = awayScore !== null && homeScore !== null && !Number.isNaN(awayScore) && !Number.isNaN(homeScore);
		const isTie = hasScores && awayScore === homeScore;
		const winnerRaw = row.winner === '' ? null : mapTeam(row.winner);
		const winner = isTie ? null : winnerRaw;
		const { away: awayPct, home: homePct } = winPcts(row.away_moneyline, row.home_moneyline);
		const hasWinPct = awayPct != null && homePct != null;

		games.push({
			espnEventId: row.game_id,
			season: Number(row.season),
			week: Number(row.week),
			away: mapTeam(row.away_team),
			home: mapTeam(row.home_team),
			gameday: row.gameday,
			gametime: row.gametime,
			awayScore: hasScores ? awayScore : null,
			homeScore: hasScores ? homeScore : null,
			isTie,
			winner,
			awayPct,
			homePct,
			hasWinPct,
			isFinal: hasScores && winner != null
		});
	}

	if (games.some((g) => g.season !== seasonYear)) {
		throw new Error(`Expected season ${seasonYear} for all rows in ${csvPath}`);
	}

	return games;
}

function nflTeamsFromGames(games) {
	return [...new Set(games.flatMap((g) => [g.away, g.home]))].sort();
}

export function generateGamesMigration({
	csvPath,
	seasonYear,
	migrationPath,
	includeSeasonRecords = true
}) {
	const games = loadGames(csvPath, seasonYear);
	const weeks = [...new Set(games.map((g) => g.week))].sort((a, b) => a - b);
	const teams = nflTeamsFromGames(games);

	const out = [];
	out.push(`-- Golden Spoon — seed ${seasonYear} NFL schedule (dev/test data)`);
	out.push(`-- Generated from ${csvPath}`);
	out.push('-- Idempotent: safe to re-run (upserts on espn_event_id / season-week keys).');
	out.push('-- CSV uses LA for Rams; mapped to LAR to match public.nfl_teams.');
	out.push('-- Win % derived from moneylines where available (vig removed via normalization).');
	out.push('');
	out.push('-- ---------------------------------------------------------------------------');
	out.push(`-- Weeks (${seasonYear})`);
	out.push('-- ---------------------------------------------------------------------------');
	out.push('insert into public.nfl_weeks (season_year, week_number, phase, label)');
	out.push('values');

	const weekValues = weeks.map(
		(week) => `  (${seasonYear}, ${week}, 'regular', 'Week ${week}')`
	);
	out.push(weekValues.join(',\n'));
	out.push('on conflict (season_year, week_number) do update');
	out.push('  set phase = excluded.phase,');
	out.push('      label = excluded.label;');
	out.push('');
	out.push('-- ---------------------------------------------------------------------------');
	out.push(`-- Games (${seasonYear})`);
	out.push('-- ---------------------------------------------------------------------------');
	out.push('insert into public.nfl_games (');
	out.push('  season_year,');
	out.push('  week_number,');
	out.push('  home_team_id,');
	out.push('  away_team_id,');
	out.push('  kickoff_at,');
	out.push('  status,');
	out.push('  home_score,');
	out.push('  away_score,');
	out.push('  is_tie,');
	out.push('  winner_team_id,');
	out.push('  home_win_pct,');
	out.push('  away_win_pct,');
	out.push('  win_pct_source,');
	out.push('  win_pct_updated_at,');
	out.push('  espn_event_id');
	out.push(')');
	out.push('values');

	const gameValues = games.map((game) => {
		const status = game.isFinal ? 'final' : 'scheduled';
		const winPctSource = game.hasWinPct ? `'moneyline'` : 'null';
		const winPctUpdated = game.hasWinPct ? 'now()' : 'null';

		return `  (${seasonYear}, ${game.week}, ${sqlStr(game.home)}, ${sqlStr(game.away)}, ${kickoffExpr(game.gameday, game.gametime)}, '${status}', ${sqlNum(game.homeScore)}, ${sqlNum(game.awayScore)}, ${game.isTie}, ${sqlStr(game.winner)}, ${sqlNum(game.homePct)}, ${sqlNum(game.awayPct)}, ${winPctSource}, ${winPctUpdated}, ${sqlStr(game.espnEventId)})`;
	});
	out.push(gameValues.join(',\n'));
	out.push('on conflict (espn_event_id) do update set');
	out.push('  season_year = excluded.season_year,');
	out.push('  week_number = excluded.week_number,');
	out.push('  home_team_id = excluded.home_team_id,');
	out.push('  away_team_id = excluded.away_team_id,');
	out.push('  kickoff_at = excluded.kickoff_at,');
	out.push('  status = excluded.status,');
	out.push('  home_score = excluded.home_score,');
	out.push('  away_score = excluded.away_score,');
	out.push('  is_tie = excluded.is_tie,');
	out.push('  winner_team_id = excluded.winner_team_id,');
	out.push('  home_win_pct = excluded.home_win_pct,');
	out.push('  away_win_pct = excluded.away_win_pct,');
	out.push('  win_pct_source = excluded.win_pct_source,');
	out.push('  win_pct_updated_at = excluded.win_pct_updated_at,');
	out.push('  updated_at = now();');

	if (includeSeasonRecords) {
		out.push('');
		out.push('-- ---------------------------------------------------------------------------');
		out.push(`-- Regular-season team records (${seasonYear}) — tiebreaker snapshots`);
		out.push('-- ---------------------------------------------------------------------------');
		out.push(
			'insert into public.season_team_records (season_year, team_id, wins, losses, ties, updated_at)'
		);
		out.push('values');
		out.push(
			teams.map((team) => `  (${seasonYear}, '${team}', 0, 0, 0, now())`).join(',\n')
		);
		out.push('on conflict (season_year, team_id) do update set');
		out.push('  wins = excluded.wins,');
		out.push('  losses = excluded.losses,');
		out.push('  ties = excluded.ties,');
		out.push('  updated_at = excluded.updated_at;');
	}

	out.push('');
	writeFileSync(migrationPath, `${out.join('\n')}\n`);
	console.log(`Wrote ${migrationPath}`);
	console.log(`  ${games.length} games, weeks ${weeks[0]}-${weeks[weeks.length - 1]}, ${teams.length} teams`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	const seasonYear = Number(process.argv[2] ?? 2026);
	const csvPath = process.argv[3] ?? `data/games_${seasonYear}.csv`;
	const migrationPath =
		process.argv[4] ?? `supabase/migrations/007_seed_${seasonYear}_games.sql`;

	generateGamesMigration({ csvPath, seasonYear, migrationPath });
}
