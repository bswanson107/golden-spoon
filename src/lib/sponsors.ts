/** Parody sponsor creatives. Logos live in `static/sponsors/` as WebP. */

export type Sponsor = {
	slug: string;
	name: string;
	promos: string[];
};

const SPONSOR_DIR = 'sponsors';

export const SPONSORS: readonly Sponsor[] = [
	{
		slug: 'swensons',
		name: "Swenson's Drive-In",
		promos: [
			"Craving a Galley Boy? 🍔 Customer favorites, made to order — right now it's buy one, get one on the classics.",
			'Since 1934, Swensons has served made-to-order favorites with that legendary curbside experience. Quality you can count on, hot to your window.',
			'Turn on your headlights and let Swensons come to you! 🚗 Galley Boy, Potato Teezers, or a shake — use code SPOON for $5 off.'
		]
	},
	{
		slug: 'greatLakes',
		name: 'Great Lakes Brewing Co.',
		promos: [
			"Raise a glass to Ohio's original craft brewery. 🍺 Seasonal favorites are back on the shelf — limited time only.",
			'From Dortmunder Gold to Christmas Ale, Cleveland crafted since 1988. Shop the collection and celebrate the season.',
			"Independent. Ohio-born. Employee-owned. 🍻 Bundle & save on our best sellers — don't miss out."
		]
	},
	{
		slug: 'scag',
		name: 'Scag Power Equipment',
		promos: [
			'Built for the job. Built to last. Since 1983, Scag has been making "Simply the Best" commercial and residential mowing equipment. A brand you can trust.',
			"Don't settle for a mower that just gets the job done. Heavy-duty performance, 20% off today — ends soon.",
			'Quality you can count on since 1983. Find your next Scag machine with fast & free shipping on select models.'
		]
	},
	{
		slug: 'italos',
		name: "Italo's Pizza",
		promos: [
			'From a humble shop in 1966 to a Northeast Ohio favorite. 🍕 Original recipes, customer favorites — shop now.',
			'Great pizza starts with a great recipe. Signature sauces, quality ingredients, and a hot deal on family bundles. Bundle & save.',
			"A family tradition since 1966. Bring home Italo Ventura's original pizza — buy one, get one on classic pies, limited time only."
		]
	},
	{
		slug: 'goodyear',
		name: 'Goodyear',
		promos: [
			'Trusted since 1898. More than 125 years of keeping the world moving. A brand you can trust.',
			'From Akron to roads around the world — quality, innovation, dependability. Shop now and get free shipping on a set of four.',
			"More than 125 years of tire innovation. One iconic name. Can't-miss savings on best sellers — ends soon."
		]
	},
	{
		slug: 'chc',
		name: 'Community Health Care',
		promos: [
			"Feeling run down after another Sunday? Same-day appointments are open. Don't miss out — book today.",
			'Care that actually knows your name. Looking after Northeast Ohio families for decades. Quality you can count on.',
			"Don't tough it out. Community Health Care makes it easy to get seen fast — new patient visits are 20% off today."
		]
	},
	{
		slug: 'barilla',
		name: 'Barilla',
		promos: [
			"Dal 1877. 🍝 Italy's favorite pasta for nearly 150 years. Stock the pantry and bundle & save.",
			'Perfect al dente, every single time. The pasta Italians choose most — shop our best sellers.',
			'From Parma to your kitchen table since 1877. New arrivals in the sauce aisle, plus free shipping over $35.'
		]
	},
	{
		slug: 'raos',
		name: "Rao's Homemade",
		promos: [
			'The sauce that started in a Harlem kitchen in 1896. 🍅 Real ingredients, no shortcuts. Shop the collection.',
			'Slow-simmered in small batches with whole tomatoes and pure olive oil. A hot deal on customer favorites — limited time only.',
			'Restaurant quality, straight off the shelf. Use code SPOON for $5 off your first order.'
		]
	},
	{
		slug: 'zoo',
		name: 'Cleveland Metroparks Zoo',
		promos: [
			'Make it a family day at Cleveland Metroparks Zoo. 🦍 Over 3,000 animals from around the world. Fast & free digital tickets.',
			'Securing a future for wildlife since 1882. New arrivals in the aquarium and seasonal favorites all summer long.',
			'Elephants, giraffes, and a whole lot more. Plan your trip — 20% off admission, ends soon.'
		]
	}
] as const;

export type SponsorLogoSize = 128 | 256;

/** Build a site URL for a display-sized sponsor WebP. */
export function resolveSponsorLogoUrl(
	slug: string,
	basePath: string,
	size: SponsorLogoSize = 128
): string {
	const base = basePath.replace(/\/$/, '');
	return `${base}/${SPONSOR_DIR}/${encodeURIComponent(slug)}-${size}.webp`;
}

function shuffle<T>(items: readonly T[]): T[] {
	const copy = [...items];
	for (let i = copy.length - 1; i > 0; i -= 1) {
		const j = Math.floor(Math.random() * (i + 1));
		[copy[i], copy[j]] = [copy[j], copy[i]];
	}
	return copy;
}

/** Session bag: shuffle sponsors, then pick a random promo line each draw. */
export function createSponsorRotation(sponsors: readonly Sponsor[] = SPONSORS) {
	let bag = shuffle(sponsors);
	let lastSlug: string | null = null;

	return {
		next(): { sponsor: Sponsor; promo: string } {
			if (bag.length === 0) {
				bag = shuffle(sponsors);
				if (lastSlug && bag.length > 1 && bag[0]?.slug === lastSlug) {
					bag.push(bag.shift()!);
				}
			}
			const sponsor = bag.shift()!;
			lastSlug = sponsor.slug;
			const promo = sponsor.promos[Math.floor(Math.random() * sponsor.promos.length)]!;
			return { sponsor, promo };
		}
	};
}
