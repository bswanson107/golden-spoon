import ariLogo from '$lib/assets/nflLogos/arizona-cardinals-logo.svg';
import atlLogo from '$lib/assets/nflLogos/atlanta-falcons-logo.svg';
import balLogo from '$lib/assets/nflLogos/baltimore-ravens-logo.svg';
import bufLogo from '$lib/assets/nflLogos/buffalo-bills-logo.svg';
import carLogo from '$lib/assets/nflLogos/carolina-panthers-logo.svg';
import chiLogo from '$lib/assets/nflLogos/chicago-bears-logo.svg';
import cinLogo from '$lib/assets/nflLogos/cincinnati-bengals-logo.svg';
import cleLogo from '$lib/assets/nflLogos/cleveland-browns-logo.svg';
import dalLogo from '$lib/assets/nflLogos/dallas-cowboys-logo.svg';
import denLogo from '$lib/assets/nflLogos/denver-broncos-logo.svg';
import detLogo from '$lib/assets/nflLogos/detroit-lions-logo.svg';
import gbLogo from '$lib/assets/nflLogos/green-bay-packers-logo.svg';
import houLogo from '$lib/assets/nflLogos/houston-texans-logo.svg';
import indLogo from '$lib/assets/nflLogos/indianapolis-colts-logo.svg';
import jaxLogo from '$lib/assets/nflLogos/jacksonville-jaguars-logo.svg';
import kcLogo from '$lib/assets/nflLogos/kansas-city-chiefs-logo.svg';
import lvLogo from '$lib/assets/nflLogos/las-vegas-raiders-logo.svg';
import lacLogo from '$lib/assets/nflLogos/los-angeles-chargers-logo.svg';
import larLogo from '$lib/assets/nflLogos/los-angeles-rams-logo.svg';
import miaLogo from '$lib/assets/nflLogos/miami-dolphins-logo.svg';
import minLogo from '$lib/assets/nflLogos/minnesota-vikings-logo.svg';
import neLogo from '$lib/assets/nflLogos/new-england-patriots-logo.svg';
import noLogo from '$lib/assets/nflLogos/new-orleans-saints-logo.svg';
import nygLogo from '$lib/assets/nflLogos/new-york-giants-logo.svg';
import nyjLogo from '$lib/assets/nflLogos/new-york-jets-logo.svg';
import phiLogo from '$lib/assets/nflLogos/philadelphia-eagles-logo.svg';
import pitLogo from '$lib/assets/nflLogos/pittsburgh-steelers-logo.svg';
import seaLogo from '$lib/assets/nflLogos/seattle-seahawks-logo.svg';
import sfLogo from '$lib/assets/nflLogos/san-francisco-49ers-logo.svg';
import tbLogo from '$lib/assets/nflLogos/tampa-bay-buccaneers-logo.svg';
import tenLogo from '$lib/assets/nflLogos/tennessee-titans-logo.svg';
import wasLogo from '$lib/assets/nflLogos/washington-commanders-logo.svg';

export type NFLTeamCode =
	| 'ARI'
	| 'ATL'
	| 'BAL'
	| 'BUF'
	| 'CAR'
	| 'CHI'
	| 'CIN'
	| 'CLE'
	| 'DAL'
	| 'DEN'
	| 'DET'
	| 'GB'
	| 'HOU'
	| 'IND'
	| 'JAX'
	| 'KC'
	| 'LV'
	| 'LAC'
	| 'LAR'
	| 'MIA'
	| 'MIN'
	| 'NE'
	| 'NO'
	| 'NYG'
	| 'NYJ'
	| 'PHI'
	| 'PIT'
	| 'SEA'
	| 'SF'
	| 'TB'
	| 'TEN'
	| 'WAS';

export type NFLTeam = {
	code: NFLTeamCode;
	name: string;
	logo: string;
	primaryColor: string;
};

const TEAM_LOGOS: Record<NFLTeamCode, string> = {
	ARI: ariLogo,
	ATL: atlLogo,
	BAL: balLogo,
	BUF: bufLogo,
	CAR: carLogo,
	CHI: chiLogo,
	CIN: cinLogo,
	CLE: cleLogo,
	DAL: dalLogo,
	DEN: denLogo,
	DET: detLogo,
	GB: gbLogo,
	HOU: houLogo,
	IND: indLogo,
	JAX: jaxLogo,
	KC: kcLogo,
	LV: lvLogo,
	LAC: lacLogo,
	LAR: larLogo,
	MIA: miaLogo,
	MIN: minLogo,
	NE: neLogo,
	NO: noLogo,
	NYG: nygLogo,
	NYJ: nyjLogo,
	PHI: phiLogo,
	PIT: pitLogo,
	SEA: seaLogo,
	SF: sfLogo,
	TB: tbLogo,
	TEN: tenLogo,
	WAS: wasLogo
};

const TEAM_NAMES: Record<NFLTeamCode, string> = {
	ARI: 'Arizona Cardinals',
	ATL: 'Atlanta Falcons',
	BAL: 'Baltimore Ravens',
	BUF: 'Buffalo Bills',
	CAR: 'Carolina Panthers',
	CHI: 'Chicago Bears',
	CIN: 'Cincinnati Bengals',
	CLE: 'Cleveland Browns',
	DAL: 'Dallas Cowboys',
	DEN: 'Denver Broncos',
	DET: 'Detroit Lions',
	GB: 'Green Bay Packers',
	HOU: 'Houston Texans',
	IND: 'Indianapolis Colts',
	JAX: 'Jacksonville Jaguars',
	KC: 'Kansas City Chiefs',
	LV: 'Las Vegas Raiders',
	LAC: 'Los Angeles Chargers',
	LAR: 'Los Angeles Rams',
	MIA: 'Miami Dolphins',
	MIN: 'Minnesota Vikings',
	NE: 'New England Patriots',
	NO: 'New Orleans Saints',
	NYG: 'New York Giants',
	NYJ: 'New York Jets',
	PHI: 'Philadelphia Eagles',
	PIT: 'Pittsburgh Steelers',
	SEA: 'Seattle Seahawks',
	SF: 'San Francisco 49ers',
	TB: 'Tampa Bay Buccaneers',
	TEN: 'Tennessee Titans',
	WAS: 'Washington Commanders'
};

const TEAM_COLORS: Record<NFLTeamCode, string> = {
	ARI: '#97233F',
	ATL: '#A71930',
	BAL: '#241773',
	BUF: '#00338D',
	CAR: '#0085CA',
	CHI: '#0B162A',
	CIN: '#FB4F14',
	CLE: '#311D00',
	DAL: '#003594',
	DEN: '#FB4F14',
	DET: '#0076B6',
	GB: '#203731',
	HOU: '#03202F',
	IND: '#002C5F',
	JAX: '#006778',
	KC: '#E31837',
	LV: '#000000',
	LAC: '#0080C6',
	LAR: '#FFC72C',
	MIA: '#008E97',
	MIN: '#4F2683',
	NE: '#002244',
	NO: '#D3BC8D',
	NYG: '#A2AAAD',
	NYJ: '#FFFFFF',
	PHI: '#004C54',
	PIT: '#FFB612',
	SEA: '#002244',
	SF: '#AA0000',
	TB: '#D50A0A',
	TEN: '#4B92DB',
	WAS: '#5A1414'
};

export const NFL_TEAMS = Object.fromEntries(
	(Object.keys(TEAM_NAMES) as NFLTeamCode[]).map((code) => [
		code,
		{
			code,
			name: TEAM_NAMES[code],
			logo: TEAM_LOGOS[code],
			primaryColor: TEAM_COLORS[code]
		}
	])
) as Record<NFLTeamCode, NFLTeam>;

export const TEAM_OPTIONS = (Object.keys(TEAM_NAMES) as NFLTeamCode[])
	.map((code) => ({
		value: code,
		label: TEAM_NAMES[code]
	}))
	.sort((a, b) => a.label.localeCompare(b.label));

export const NFL_TEAM_CODES = Object.keys(NFL_TEAMS) as NFLTeamCode[];

export type NFLConference = 'AFC' | 'NFC';
export type NFLDivisionName = 'East' | 'North' | 'South' | 'West';

export type NFLDivision = {
	conference: NFLConference;
	name: NFLDivisionName;
	label: string;
	teams: NFLTeamCode[];
};

/** NFL divisions in standard standings order (AFC then NFC, East→West). */
export const NFL_DIVISIONS: NFLDivision[] = [
	{ conference: 'AFC', name: 'East', label: 'AFC East', teams: ['BUF', 'MIA', 'NE', 'NYJ'] },
	{ conference: 'AFC', name: 'North', label: 'AFC North', teams: ['BAL', 'CIN', 'CLE', 'PIT'] },
	{ conference: 'AFC', name: 'South', label: 'AFC South', teams: ['HOU', 'IND', 'JAX', 'TEN'] },
	{ conference: 'AFC', name: 'West', label: 'AFC West', teams: ['DEN', 'KC', 'LAC', 'LV'] },
	{ conference: 'NFC', name: 'East', label: 'NFC East', teams: ['DAL', 'NYG', 'PHI', 'WAS'] },
	{ conference: 'NFC', name: 'North', label: 'NFC North', teams: ['CHI', 'DET', 'GB', 'MIN'] },
	{ conference: 'NFC', name: 'South', label: 'NFC South', teams: ['ATL', 'CAR', 'NO', 'TB'] },
	{ conference: 'NFC', name: 'West', label: 'NFC West', teams: ['ARI', 'LAR', 'SF', 'SEA'] }
];

export function isNFLTeamCode(teamCode: string): teamCode is NFLTeamCode {
	return teamCode in NFL_TEAMS;
}

export function getTeamLogo(teamCode: string): string {
	if (!isNFLTeamCode(teamCode)) return '';
	return NFL_TEAMS[teamCode].logo;
}

export function getTeamName(teamCode: string): string {
	if (!isNFLTeamCode(teamCode)) return teamCode;
	return NFL_TEAMS[teamCode].name;
}

export function getTeamPrimaryColor(teamCode: string): string {
	if (!isNFLTeamCode(teamCode)) return 'var(--logo-tile-bg)';
	return NFL_TEAMS[teamCode].primaryColor;
}

function hexLuminance(hex: string): number {
	const normalized = hex.replace('#', '');
	if (normalized.length !== 6) return 0;

	const r = parseInt(normalized.slice(0, 2), 16);
	const g = parseInt(normalized.slice(2, 4), 16);
	const b = parseInt(normalized.slice(4, 6), 16);

	return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
}

function parseHex(hex: string): { r: number; g: number; b: number } | null {
	const normalized = hex.replace('#', '');
	if (normalized.length !== 6) return null;

	return {
		r: parseInt(normalized.slice(0, 2), 16),
		g: parseInt(normalized.slice(2, 4), 16),
		b: parseInt(normalized.slice(4, 6), 16)
	};
}

function toHex(r: number, g: number, b: number): string {
	return `#${[r, g, b]
		.map((channel) => Math.max(0, Math.min(255, Math.round(channel))).toString(16).padStart(2, '0'))
		.join('')}`;
}

function adjustHex(hex: string, amount: number): string {
	const rgb = parseHex(hex);
	if (!rgb) return hex;

	return toHex(rgb.r + amount, rgb.g + amount, rgb.b + amount);
}

export function getTeamTileGradient(teamCode: string): string {
	const base = getTeamPrimaryColor(teamCode);
	if (base.startsWith('var(')) return base;

	const isLight = hexLuminance(base) > 0.65;
	const topShift = isLight ? 10 : 20;
	const bottomShift = isLight ? -12 : -20;

	const top = adjustHex(base, topShift);
	const bottom = adjustHex(base, bottomShift);

	return `linear-gradient(145deg, ${top} 0%, ${base} 52%, ${bottom} 100%)`;
}

export function isLightTeamColor(teamCode: string): boolean {
	if (!isNFLTeamCode(teamCode)) return false;
	return hexLuminance(NFL_TEAMS[teamCode].primaryColor) > 0.65;
}

/** Richer accent for light primaries so surface tints read on UI panels */
const LIGHT_TEAM_SURFACE_TINT: Partial<Record<NFLTeamCode, string>> = {
	LAR: '#003594',
	LV: '#54595F',
	NO: '#8B6914',
	NYG: '#0B2265',
	NYJ: '#12543d',
	PIT: '#101010'
};

export function getTeamSurfaceTint(teamCode: string): string {
	if (!isNFLTeamCode(teamCode)) return getTeamPrimaryColor(teamCode);
	if (isLightTeamColor(teamCode) && LIGHT_TEAM_SURFACE_TINT[teamCode]) {
		return LIGHT_TEAM_SURFACE_TINT[teamCode]!;
	}
	return getTeamPrimaryColor(teamCode);
}
