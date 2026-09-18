#!/usr/bin/env python3
"""Build display-sized WebP sponsor logos from assets/sponsors-src/*.png."""

from pathlib import Path

try:
	from PIL import Image
except ImportError as exc:
	raise SystemExit(
		'Pillow is required. Install with: python3 -m pip install Pillow'
	) from exc

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / 'assets' / 'sponsors-src'
OUT_DIR = ROOT / 'static' / 'sponsors'
SIZES = (128, 256)
QUALITY = 82


def main() -> None:
	if not SRC_DIR.is_dir():
		raise SystemExit(f'Missing source directory: {SRC_DIR}')

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	sources = sorted(SRC_DIR.glob('*.png'))
	if not sources:
		raise SystemExit(f'No PNG sources in {SRC_DIR}')

	for src in sources:
		slug = src.stem
		im = Image.open(src).convert('RGBA')
		for size in SIZES:
			resized = im.resize((size, size), Image.Resampling.LANCZOS)
			out = OUT_DIR / f'{slug}-{size}.webp'
			resized.save(out, 'WEBP', quality=QUALITY, method=6)
			print(f'{out.relative_to(ROOT)}: {out.stat().st_size / 1024:.1f}KB')


if __name__ == '__main__':
	main()
