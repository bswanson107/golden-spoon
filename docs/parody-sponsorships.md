# Parody sponsorships — parked

A first pass at in-app parody ads was built and then **fully reverted from the app**. Shipping it made Golden Spoon take far too long to load. We should not turn this back on until we have a more efficient approach.

## What we created (and removed)

- Per-league **Parody ads** toggle in Admin (database flag `show_parody_sponsorships`, default off)
- Rotating, dismissible ads on league overview and pick pages
- Mix of bottom **banners** and **popup modals**
- Shuffled order per browser session; dismissed ads stayed gone until the tab closed
- Sponsors: Swenson’s Drive-In, Great Lakes Brewing Co., SCAG Power Equipment, Italo’s Pizza, Goodyear (blimp art)

That implementation loaded the creatives as full static PNGs on league routes. The original Goodyear file was ~13MB; Italo’s was ~2MB. Even after squaring/downsampling the images, the feature was too heavy for how this app loads. **We need a new solution that is more efficient** — for example: much smaller WebP/AVIF assets, lazy-load only after the league UI is interactive, do not import ad UI on every league page, and never block first paint on sponsor files.

If migration `039_parody_sponsorships` was already applied to a database, drop the unused flag:

```sql
alter table public.leagues drop column if exists show_parody_sponsorships;
drop function if exists public.admin_set_league_parody_sponsorships(uuid, boolean);
```

Then recreate `admin_list_leagues` from `034_league_profile_pictures.sql` (or later) so it no longer returns that column.

## Assets that remain

These files stay in `static/` for a future attempt:

- `static/swensons.png`
- `static/greatLakes.png`
- `static/scag.png`
- `static/italos.png`
- `static/goodyear-blimp.png`

During the first attempt they were trimmed and saved as 512×512 PNGs (Goodyear went from ~13MB to ~64KB). If you still have the source files, keep those somewhere safe; the next pass should use compressed, display-sized images from the start — not the raw exports.

## Ad copy to use next time

### Swensons Drive-In

1. Craving a Galley Boy? 🍔 Treat yourself to a Swensons classic today and save 20% OFF your order!

2. Since 1934, Swensons has been serving up made-to-order favorites with that legendary curbside experience. Come taste the tradition—and save 20% OFF today!

3. Turn on your headlights and let Swensons come to you! 🚗 Get your favorite Galley Boy, Potato Teezers, or shake and use code SPOON for $5 OFF.

### Great Lakes Brewing Company

1. Raise a glass to Ohio’s original craft brewery. 🍺 Since 1988, Great Lakes Brewing Co. has been crafting award-winning favorites. Shop now and save 20% OFF!

2. From Dortmunder Gold to Christmas Ale, Great Lakes has been Cleveland crafted since 1988. Discover a local classic and get 20% OFF your order today.

3. Independent. Ohio-born. Employee-owned. 🍻 Bring home a piece of Great Lakes Brewing Co. and use code SPOON for $5 OFF.

### Scag Power Equipment

1. Built for the job. Built to last. Since 1983, Scag has been making “Simply the Best” commercial and residential mowing equipment. Shop now and save 20% OFF.

2. Don’t settle for a mower that just gets the job done. Choose the heavy-duty performance Scag is known for—and get 20% OFF today.

3. Since 1983, Scag has built its reputation on quality, durability, and performance. Find your next Scag machine and use code SPOON for $5 OFF.

### Italo's Pizza

1. From a humble shop in 1966 to a Northeast Ohio favorite, Italo’s Pizza has stayed true to its original recipes and quality. Order now and save 20% OFF!

2. Great pizza starts with a great recipe. 🍕 Since 1966, Italo’s has been serving its signature sauces and quality ingredients. Get 20% OFF your next order!

3. A family tradition since 1966. Bring home the taste of Italo Ventura’s original pizza—and use code SPOON for $5 OFF your order.

### Goodyear

1. Trusted since 1898. Goodyear has been helping keep the world moving for more than 125 years. Shop Goodyear tires today and save 20% OFF.

2. From Akron to roads around the world, Goodyear has built a reputation for quality, innovation, and dependability. Choose a brand you can trust—and get 20% OFF today.

3. More than 125 years of tire innovation. One iconic name. Goodyear. Get the tires you need today and use code SPOON for $5 OFF.
