# Parody sponsorships

Lightweight in-app parody ads for Golden Spoon. Enabled per league via the Admin **Parody ads** toggle (`leagues.show_parody_sponsorships`, default off).

## What ships

- Dismissible bottom **banners** (common) and occasional **popup modals**
- Random sponsor + random promo line from the copy bank below
- First impression ~60s after the page is idle; at most 3 per tab session
- Footer **Thank you to our sponsors** logo grid on league pages (same toggle)
- Display assets are small WebP files under `static/sponsors/` (`*-128.webp` for the footer, `*-256.webp` for ads)

## Performance rules (do not break these)

The first attempt loaded full-size PNGs (Goodyear ~13MB, Italo’s ~2MB) on the league route’s critical path and made the app feel unusable. This pass avoids that:

1. Never put raw / 512×512 PNGs in `static/` for deploy — sources live in `assets/sponsors-src/`
2. Rebuild display WebPs with `python3 scripts/build-sponsor-assets.py` (requires Pillow)
3. Ad UI is dynamically imported after idle (`SponsorAdHost`) — do not statically import `SponsorAd` from league pages
4. One creative in the DOM at a time; footer images use `loading="lazy"` + `fetchpriority="low"`
5. Logos are referenced by URL string, never `import`ed into the JS bundle

Migration: `039_parody_sponsorships.sql` (`npm run db:apply-parody-sponsorships`).

## Ad copy

Keep the calls to action varied — spread the buzzwords around instead of ending every line with the same discount. Rough rotation of hooks in use: *use code SPOON for $5 off, 20% off today, free shipping, fast & free shipping, shop now, don't miss out, limited time only, ends soon, a brand you can trust, quality you can count on, best sellers, customer favorites, new arrivals, shop the collection, seasonal favorites, celebrate the season, hot deal, can't-miss savings, bundle & save, buy one get one.* When adding copy, pick a hook that isn't already all over the file.

Copy here must stay in sync with `src/lib/sponsors.ts`, which is what the app actually renders.

### Swensons Drive-In

1. Craving a Galley Boy? 🍔 Customer favorites, made to order — right now it's buy one, get one on the classics.

2. Since 1934, Swensons has served made-to-order favorites with that legendary curbside experience. Quality you can count on, hot to your window.

3. Turn on your headlights and let Swensons come to you! 🚗 Galley Boy, Potato Teezers, or a shake — use code SPOON for $5 off.

### Great Lakes Brewing Company

1. Raise a glass to Ohio’s original craft brewery. 🍺 Seasonal favorites are back on the shelf — limited time only.

2. From Dortmunder Gold to Christmas Ale, Cleveland crafted since 1988. Shop the collection and celebrate the season.

3. Independent. Ohio-born. Employee-owned. 🍻 Bundle & save on our best sellers — don’t miss out.

### Scag Power Equipment

1. Built for the job. Built to last. Since 1983, Scag has been making “Simply the Best” commercial and residential mowing equipment. A brand you can trust.

2. Don’t settle for a mower that just gets the job done. Heavy-duty performance, 20% off today — ends soon.

3. Quality you can count on since 1983. Find your next Scag machine with fast & free shipping on select models.

### Italo's Pizza

1. From a humble shop in 1966 to a Northeast Ohio favorite. 🍕 Original recipes, customer favorites — shop now.

2. Great pizza starts with a great recipe. Signature sauces, quality ingredients, and a hot deal on family bundles. Bundle & save.

3. A family tradition since 1966. Bring home Italo Ventura’s original pizza — buy one, get one on classic pies, limited time only.

### Goodyear

1. Trusted since 1898. More than 125 years of keeping the world moving. A brand you can trust.

2. From Akron to roads around the world — quality, innovation, dependability. Shop now and get free shipping on a set of four.

3. More than 125 years of tire innovation. One iconic name. Can’t-miss savings on best sellers — ends soon.

### Community Health Care

1. Feeling run down after another Sunday? Same-day appointments are open. Don’t miss out — book today.

2. Care that actually knows your name. Looking after Northeast Ohio families for decades. Quality you can count on.

3. Don’t tough it out. Community Health Care makes it easy to get seen fast — new patient visits are 20% off today.

### Barilla

1. Dal 1877. 🍝 Italy’s favorite pasta for nearly 150 years. Stock the pantry and bundle & save.

2. Perfect al dente, every single time. The pasta Italians choose most — shop our best sellers.

3. From Parma to your kitchen table since 1877. New arrivals in the sauce aisle, plus free shipping over $35.

### Rao's Homemade

1. The sauce that started in a Harlem kitchen in 1896. 🍅 Real ingredients, no shortcuts. Shop the collection.

2. Slow-simmered in small batches with whole tomatoes and pure olive oil. A hot deal on customer favorites — limited time only.

3. Restaurant quality, straight off the shelf. Use code SPOON for $5 off your first order.

### Cleveland Metroparks Zoo

1. Make it a family day at Cleveland Metroparks Zoo. 🦍 Over 3,000 animals from around the world. Fast & free digital tickets.

2. Securing a future for wildlife since 1882. New arrivals in the aquarium and seasonal favorites all summer long.

3. Elephants, giraffes, and a whole lot more. Plan your trip — 20% off admission, ends soon.
