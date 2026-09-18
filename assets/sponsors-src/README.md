# Sponsor logo sources

Canonical 512×512 PNG masters for parody sponsorships.

Do **not** put these in `static/` — they are build inputs only. Display-sized WebPs are generated into `static/sponsors/`:

```bash
npm run sponsors:build
# or: python3 scripts/build-sponsor-assets.py
```

Requires Pillow (`python3 -m pip install Pillow`).
