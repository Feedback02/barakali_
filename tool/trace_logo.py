"""Regenerate the in-app vector logo (assets/images/barakali_logo.svg) from the
raster master (design/barakali_logo_source.png).

Pipeline:
  1. vtracer traces the cream-background PNG to a colour SVG.
  2. Cream-ish fills (background + the lattice negative space) are recoloured to
     the app background #FAF8F5, so the logo sits seamlessly on the splash/login
     screens (which use that colour) with the geometric lattice intact.
  3. SVGO compresses it (run separately: npx svgo --multipass).

Requires: `pip install vtracer` and (for step 3) Node `npx svgo`.
Run:  python tool/trace_logo.py  &&  npx -y svgo --multipass \
        -i design/_recolored.svg -o assets/images/barakali_logo.svg
"""

import re

import vtracer

SRC = "design/barakali_logo_source.png"
RAW = "design/logo_from_source.svg"
OUT = "design/_recolored.svg"
APP_BG = "#faf8f5"


def is_creamish(hex6: str) -> bool:
    r, g, b = (int(hex6[i : i + 2], 16) for i in (0, 2, 4))
    return min(r, g, b) > 205 and (max(r, g, b) - min(r, g, b)) < 40


def main() -> None:
    vtracer.convert_image_to_svg_py(
        SRC,
        RAW,
        colormode="color",
        mode="spline",
        filter_speckle=4,
        color_precision=7,
        layer_difference=16,
    )
    svg = open(RAW, encoding="utf-8").read()
    svg = re.sub(
        r'fill="#([0-9a-fA-F]{6})"',
        lambda m: f'fill="{APP_BG}"' if is_creamish(m.group(1)) else m.group(0),
        svg,
    )
    open(OUT, "w", encoding="utf-8").write(svg)
    print(f"wrote {OUT} — now: npx -y svgo --multipass -i {OUT} "
          "-o assets/images/barakali_logo.svg")


if __name__ == "__main__":
    main()
