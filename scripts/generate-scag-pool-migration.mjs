import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';

const TEAM_MAP = { LA: 'LAR' };

const TEAM_NAME_TO_ID = {
	'Arizona Cardinals': 'ARI',
	'Atlanta Falcons': 'ATL',
	'Baltimore Ravens': 'BAL',
	'Buffalo Bills': 'BUF',
	'Carolina Panthers': 'CAR',
	'Chicago Bears': 'CHI',
	'Cincinnati Bengals': 'CIN',
	'Cleveland Browns': 'CLE',
	'Dallas Cowboys': 'DAL',
	'Denver Broncos': 'DEN',
	'Detroit Lions': 'DET',
	'Green Bay Packers': 'GB',
	'Houston Texans': 'HOU',
	'Indianapolis Colts': 'IND',
	'Jacksonville Jaguars': 'JAX',
	'Kansas City Chiefs': 'KC',
	'Las Vegas Raiders': 'LV',
	'Los Angeles Chargers': 'LAC',
	'Los Angeles Rams': 'LAR',
	'Miami Dolphins': 'MIA',
	'Minnesota Vikings': 'MIN',
	'New England Patriots': 'NE',
	'New Orleans Saints': 'NO',
	'New York Giants': 'NYG',
	'New York Jets': 'NYJ',
	'Philadelphia Eagles': 'PHI',
	'Pittsburgh Steelers': 'PIT',
	'San Francisco 49ers': 'SF',
	'Seattle Seahawks': 'SEA',
	'Tampa Bay Buccaneers': 'TB',
	'Tennessee Titans': 'TEN',
	'Washington Commanders': 'WAS'
};

const LEAGUE_ID = 'b0000001-0000-4000-8000-000000000001';
const LEAGUE_INVITE = 'scag2025';
const SEASON = 2025;
const UNDERDOG_THRESHOLD = 33;

function mapTeam(abbr) {
	return TEAM_MAP[abbr] ?? abbr;
}

function slugify(name) {
	return name
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-|-$/g, '');
}

function deterministicUuid(seed) {
	const hash = createHash('sha256').update(seed).digest('hex');
	return `${hash.slice(0, 8)}-${hash.slice(8, 12)}-4${hash.slice(13, 16)}-a${hash.slice(17, 20)}-${hash.slice(20, 32)}`;
}

function playerUuid(displayName) {
	return deterministicUuid(`scag-pool-player:${displayName}`);
}

function sqlStr(value) {
	if (value === null || value === undefined) return 'null';
	return `'${String(value).replace(/'/g, "''")}'`;
}

function americanToImpliedProb(odds) {
	const o = Number(odds);
	if (Number.isNaN(o)) return null;
	if (o < 0) return -o / (-o + 100);
	return 100 / (o + 100);
}

function winPcts(awayMl, homeMl) {
	const awayRaw = americanToImpliedProb(awayMl);
	const homeRaw = americanToImpliedProb(homeMl);
	if (awayRaw == null || homeRaw == null) return { away: null, home: null };
	const total = awayRaw + homeRaw;
	return {
		away: Math.round((awayRaw / total) * 10000) / 100,
		home: Math.round((homeRaw / total) * 10000) / 100
	};
}

function parseCsvLine(line) {
	return line.split(',').map((c) => c.trim().replace(/\r$/, ''));
}

function loadGames() {
	const lines = readFileSync('data/games_2025.csv', 'utf8').trim().split('\n');
	const header = parseCsvLine(lines[0]);
	const games = [];

	for (const line of lines.slice(1)) {
		const row = Object.fromEntries(parseCsvLine(line).map((v, i) => [header[i], v]));
		if (row.game_type !== 'REG') continue;

		const week = Number(row.week);
		const away = mapTeam(row.away_team);
		const home = mapTeam(row.home_team);
		const awayScore = Number(row.away_score);
		const homeScore = Number(row.home_score);
		const isTie = awayScore === homeScore;
		const winner = isTie ? null : mapTeam(row.winner);
		const { away: awayPct, home: homePct } = winPcts(row.away_moneyline, row.home_moneyline);

		const game = {
			espnEventId: row.game_id,
			week,
			away,
			home,
			awayScore,
			homeScore,
			isTie,
			winner,
			awayPct,
			homePct,
			kickoff: `${row.gameday} 17:00:00+00`
		};

		games.push(game);
	}

	return games;
}

function buildGameIndex(games) {
	const byWeekTeam = new Map();
	const byWeek = new Map();

	for (const game of games) {
		byWeekTeam.set(`${game.week}:${game.away}`, game);
		byWeekTeam.set(`${game.week}:${game.home}`, game);

		if (!byWeek.has(game.week)) byWeek.set(game.week, []);
		byWeek.get(game.week).push(game);
	}

	return { byWeekTeam, byWeek };
}

function buildCumulativeWins(games) {
	const wins = new Map();
	for (const team of new Set(games.flatMap((g) => [g.away, g.home]))) {
		wins.set(team, new Map());
	}

	for (const game of games) {
		const week = game.week;
		for (const team of [game.away, game.home]) {
			if (!wins.get(team).has(week)) wins.get(team).set(week, 0);
		}
		if (game.isTie) continue;
		const w = game.winner;
		wins.get(w).set(week, (wins.get(w).get(week) ?? 0) + 1);
	}

	const cumulativeBeforeWeek = new Map();
	for (const [team, weekWins] of wins) {
		const sortedWeeks = [...weekWins.keys()].sort((a, b) => a - b);
		let total = 0;
		const before = new Map();
		for (const w of sortedWeeks) {
			before.set(w, total);
			total += weekWins.get(w);
		}
		cumulativeBeforeWeek.set(team, before);
	}

	return cumulativeBeforeWeek;
}

function teamWinPct(game, teamId) {
	return teamId === game.home ? game.homePct : game.awayPct;
}

function resolveOutcome(teamId, game) {
	if (game.isTie) return 'tie';
	if (game.winner === teamId) return 'win';
	return 'loss';
}

function pointsForOutcome(outcome, isUnderdog) {
	if (outcome === 'missed') return 0;
	if (outcome === 'win') return isUnderdog ? 2 : 1;
	if (outcome === 'tie') return 0.5;
	return 0;
}

function findMissedPickGame(weekGames, usedPickTeamIds, blockedTeams, context) {
	for (const game of weekGames) {
		for (const teamId of [game.home, game.away]) {
			if (!usedPickTeamIds.has(teamId) && !blockedTeams.has(teamId)) {
				return { game, teamId };
			}
		}
	}
	throw new Error(
		`No available team in week ${context.week} for missed pick (${context.displayName}); tried ${weekGames.length} games`
	);
}

function loadPlayers() {
	const lines = readFileSync('data/scag_pool_2025.csv', 'utf8').trim().split('\n');
	const header = parseCsvLine(lines[1]);
	const weekCols = header.slice(5);

	return lines
		.slice(2)
		.map(parseCsvLine)
		.filter((cols) => cols[0] && /^[A-Za-z]/.test(cols[0]) && /^\d+$/.test(cols[1]))
		.map((cols) => {
			const rawName = cols[0].replace(/\s*👑\s*$/, '').trim();
			const picks = weekCols
				.map((label, i) => ({
					week: Number(label.replace('Week ', '')),
					teamName: cols[5 + i]
				}))
				.sort((a, b) => a.week - b.week);
			return { displayName: rawName, picks };
		});
}

function main() {
	const games = loadGames();
	const { byWeekTeam, byWeek } = buildGameIndex(games);
	const cumulativeWins = buildCumulativeWins(games);
	const players = loadPlayers();
	const erikUuid = playerUuid('Erik');

	const pickRows = [];

	for (const player of players) {
		const userId = playerUuid(player.displayName);
		// Intended teams from CSV (duplicate detection only).
		const usedIntendedTeams = new Set();
		// Every team_id assigned to a pick row (unique index + placeholder selection).
		const usedPickTeamIds = new Set();

		for (const { week, teamName } of player.picks) {
			const intendedTeam = TEAM_NAME_TO_ID[teamName];
			if (!intendedTeam) {
				throw new Error(`Unknown team "${teamName}" for ${player.displayName} week ${week}`);
			}

			const weekGames = byWeek.get(week) ?? [];
			let game;
			let teamId;
			let outcome;
			let isMissed = false;

			if (usedIntendedTeams.has(intendedTeam)) {
				isMissed = true;
				const blockedTeams = new Set(
					player.picks
						.filter((p) => p.week > week)
						.map((p) => TEAM_NAME_TO_ID[p.teamName])
						.filter(Boolean)
				);
				({ game, teamId } = findMissedPickGame(weekGames, usedPickTeamIds, blockedTeams, {
					week,
					displayName: player.displayName
				}));
				outcome = 'missed';
			} else {
				game = byWeekTeam.get(`${week}:${intendedTeam}`);
				if (!game) {
					throw new Error(`No REG game for ${intendedTeam} week ${week} (${player.displayName})`);
				}
				teamId = intendedTeam;
				outcome = resolveOutcome(teamId, game);
				usedIntendedTeams.add(intendedTeam);
			}

			usedPickTeamIds.add(teamId);

			const winPct = teamWinPct(game, teamId);
			const isUnderdog = winPct <= UNDERDOG_THRESHOLD;
			const teamSeasonWins =
				cumulativeWins.get(teamId)?.get(week) ?? 0;
			const points = pointsForOutcome(outcome, isUnderdog);

			pickRows.push({
				userId,
				displayName: player.displayName,
				week,
				espnEventId: game.espnEventId,
				teamId,
				winPct,
				isUnderdog,
				teamSeasonWins,
				outcome,
				points,
				isMissed,
				intendedTeam: isMissed ? intendedTeam : null
			});
		}
	}

	const out = [];
	out.push(`-- Golden Spoon — seed Scag Family Pool 2025 (dev/test data)`);
	out.push(`-- Generated from data/scag_pool_2025.csv + data/games_2025.csv`);
	out.push(`-- Prerequisite: run 004_seed_2025_games.sql first.`);
	out.push(`-- Idempotent: safe to re-run (deletes and re-inserts picks for seed league).`);
	out.push(`-- Join in app with invite code: ${LEAGUE_INVITE}`);
	out.push('');

	out.push(`do $$`);
	out.push(`begin`);
	out.push(`  if (select count(*) from public.nfl_games where season_year = ${SEASON}) = 0 then`);
	out.push(`    raise exception 'No ${SEASON} games found. Run 004_seed_2025_games.sql first.';`);
	out.push(`  end if;`);
	out.push(`end $$;`);
	out.push('');

	out.push(`-- ---------------------------------------------------------------------------`);
	out.push(`-- Synthetic auth users + profiles`);
	out.push(`-- ---------------------------------------------------------------------------`);

	for (const player of players) {
		const userId = playerUuid(player.displayName);
		const email = `scag-seed-${slugify(player.displayName)}@golden-spoon.test`;
		out.push(`insert into auth.users (`);
		out.push(`  id, instance_id, aud, role, email, encrypted_password,`);
		out.push(`  email_confirmed_at, created_at, updated_at,`);
		out.push(`  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token`);
		out.push(`) values (`);
		out.push(`  ${sqlStr(userId)}, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',`);
		out.push(`  ${sqlStr(email)}, crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),`);
		out.push(`  '{"provider":"email","providers":["email"]}', ${sqlStr(JSON.stringify({ display_name: player.displayName }))}, false, ''`);
		out.push(`) on conflict (id) do nothing;`);
		out.push('');

		out.push(`insert into auth.identities (`);
		out.push(`  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at`);
		out.push(`) values (`);
		out.push(`  ${sqlStr(userId)}, ${sqlStr(userId)},`);
		out.push(`  jsonb_build_object('sub', ${sqlStr(userId)}, 'email', ${sqlStr(email)}),`);
		out.push(`  'email', ${sqlStr(userId)}, now(), now(), now()`);
		out.push(`) on conflict (provider, provider_id) do nothing;`);
		out.push('');

		out.push(`insert into public.profiles (id, display_name)`);
		out.push(`values (${sqlStr(userId)}, ${sqlStr(player.displayName)})`);
		out.push(`on conflict (id) do update set display_name = excluded.display_name;`);
		out.push('');
	}

	out.push(`-- ---------------------------------------------------------------------------`);
	out.push(`-- League + members`);
	out.push(`-- ---------------------------------------------------------------------------`);
	out.push(`insert into public.leagues (`);
	out.push(`  id, name, season_year, commissioner_id, invite_code, is_active`);
	out.push(`) values (`);
	out.push(`  ${sqlStr(LEAGUE_ID)}, 'Scag Family Pool 2025', ${SEASON}, ${sqlStr(erikUuid)}, ${sqlStr(LEAGUE_INVITE)}, true`);
	out.push(`) on conflict (id) do update set`);
	out.push(`  name = excluded.name,`);
	out.push(`  season_year = excluded.season_year,`);
	out.push(`  commissioner_id = excluded.commissioner_id,`);
	out.push(`  invite_code = excluded.invite_code;`);
	out.push('');

	out.push(`insert into public.league_members (league_id, user_id)`);
	out.push(`values`);
	out.push(
		players
			.map((p) => `  (${sqlStr(LEAGUE_ID)}, ${sqlStr(playerUuid(p.displayName))})`)
			.join(',\n')
	);
	out.push(`on conflict (league_id, user_id) do nothing;`);
	out.push('');

	out.push(`-- ---------------------------------------------------------------------------`);
	out.push(`-- Picks (${pickRows.length} rows)`);
	out.push(`-- Duplicate team reuse in CSV → missed pick (0 pts)`);
	out.push(`-- ---------------------------------------------------------------------------`);
	out.push(`delete from public.picks where league_id = ${sqlStr(LEAGUE_ID)};`);
	out.push('');
	out.push(`set session_replication_role = replica;`);
	out.push('');
	out.push(`insert into public.picks (`);
	out.push(`  league_id, user_id, season_year, week_number, game_id, team_id,`);
	out.push(`  submitted_at, win_pct_at_pick, is_underdog_at_pick, team_season_wins_at_pick,`);
	out.push(`  outcome, points_awarded`);
	out.push(`)`);
	out.push(`values`);

	const pickValues = pickRows.map((p) => {
		const submittedAt = `(select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = ${sqlStr(p.espnEventId)})`;
		return `  (${sqlStr(LEAGUE_ID)}, ${sqlStr(p.userId)}, ${SEASON}, ${p.week}, (select id from public.nfl_games where espn_event_id = ${sqlStr(p.espnEventId)}), ${sqlStr(p.teamId)}, ${submittedAt}, ${p.winPct}, ${p.isUnderdog}, ${p.teamSeasonWins}, '${p.outcome}', ${p.points})`;
	});

	out.push(pickValues.join(',\n'));
	out.push(`;`);
	out.push('');
	out.push(`set session_replication_role = default;`);

	const missed = pickRows.filter((p) => p.isMissed);

	for (const player of players) {
		const userPicks = pickRows.filter((p) => p.userId === playerUuid(player.displayName));
		const teams = userPicks.map((p) => p.teamId);
		const unique = new Set(teams);
		if (unique.size !== teams.length) {
			const dupes = teams.filter((t, i) => teams.indexOf(t) !== i);
			throw new Error(`Duplicate team_id in picks for ${player.displayName}: ${dupes.join(', ')}`);
		}
	}

	if (missed.length) {
		out.push('');
		out.push(`-- Missed picks (duplicate team reuse): ${missed.length}`);
		for (const p of missed) {
			out.push(`-- ${p.displayName} week ${p.week}: wanted ${p.intendedTeam}, recorded missed`);
		}
	}

	const path = 'supabase/migrations/005_seed_scag_pool_2025.sql';
	writeFileSync(path, out.join('\n') + '\n');
	console.log(`Wrote ${path}`);
	console.log(`  ${players.length} players, ${pickRows.length} picks, ${missed.length} missed`);
}

main();
