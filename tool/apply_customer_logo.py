"""Processes the customer-supplied original logo (assets/icon/app_icon_orginal.png)
into the app icon, Android adaptive-icon foreground, and splash mark —
replacing the earlier custom-drawn placeholder icon.

The source is a 442x306 raster of the real NN Food & Spices badge on a
solid green field, with a separate white "An ISO 9001:2005 Certified
Company" caption bar along the bottom. This script:
  1. Crops out the certification caption bar (the app shows that
     certification as text elsewhere, e.g. the About page).
  2. Crops tightly to the badge (measured via pixel scanning — see
     project notes) to avoid the wide green margins in the original file,
     which would otherwise make the mark look small once scaled to icon
     sizes.
  3. Pads to a square canvas (never stretches) using the logo's own
     background green, so launcher icons/splash aren't distorted.

Run with: python tool/apply_customer_logo.py
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "assets", "icon", "app_icon_orginal.png")
ICON_OUT = os.path.join(ROOT, "assets", "icon")
SPLASH_OUT = os.path.join(ROOT, "assets", "splash")

# Measured by scanning the source pixel-by-pixel (row/column green-fraction
# scan) to find where the badge content actually sits, excluding the wide
# green margins and the bottom ISO-certification banner.
BADGE_CROP_BOX = (85, 5, 335, 271)  # (left, top, right, bottom) -> 250x266
BANNER_EXCLUDED_FROM_Y = 271
LOGO_GREEN = (99, 188, 53)  # sampled from the source background

SQUARE_SIZE = 1024


def load_source():
    return Image.open(SOURCE).convert("RGBA")


def build_square_badge():
    """Badge cropped tight, padded (not stretched) to a square canvas."""
    src = load_source()
    badge = src.crop(BADGE_CROP_BOX)
    w, h = badge.size
    side = max(w, h)
    canvas = Image.new("RGBA", (side, side), LOGO_GREEN + (255,))
    canvas.paste(badge, ((side - w) // 2, (side - h) // 2), badge)
    return canvas.resize((SQUARE_SIZE, SQUARE_SIZE), Image.LANCZOS)


def main():
    os.makedirs(ICON_OUT, exist_ok=True)
    os.makedirs(SPLASH_OUT, exist_ok=True)

    square = build_square_badge()

    # 1. Full-bleed app icon (opaque) — iOS / legacy Android / web / windows / macos.
    app_icon_path = os.path.join(ICON_OUT, "app_icon.png")
    square.convert("RGB").save(app_icon_path, "PNG")

    # 2. Android adaptive-icon foreground: same square placed on a
    #    transparent 1024 canvas. Because its own fill matches
    #    adaptive_icon_background (set to the same green in pubspec.yaml),
    #    the mask edge is seamless regardless of launcher shape.
    foreground_path = os.path.join(ICON_OUT, "app_icon_foreground.png")
    square.save(foreground_path, "PNG")

    # 3. Splash mark — same square artwork (own green background baked in;
    #    the Flutter splash widget shows it directly with a drop shadow,
    #    no extra colored wrapper, to avoid a visible seam between two
    #    different greens).
    splash_path = os.path.join(SPLASH_OUT, "splash_logo.png")
    square.save(splash_path, "PNG")

    android12 = Image.new("RGBA", (1152, 1152), (0, 0, 0, 0))
    scaled = square.resize((960, 960), Image.LANCZOS)
    android12.alpha_composite(scaled, (96, 96))
    android12.save(os.path.join(SPLASH_OUT, "splash_logo_android12.png"), "PNG")

    print("Generated:")
    for f in [app_icon_path, foreground_path, splash_path,
              os.path.join(SPLASH_OUT, "splash_logo_android12.png")]:
        print(" -", f)


if __name__ == "__main__":
    main()
