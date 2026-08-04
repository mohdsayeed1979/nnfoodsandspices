"""Generates the NN Food & Spices premium app icon, Android adaptive
foreground layer, and splash mark from scratch (vector-drawn, not a crop
of the source logo). Run with: python tool/generate_icon.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "icon")
SPLASH_OUT = os.path.join(ROOT, "assets", "splash")
os.makedirs(OUT, exist_ok=True)
os.makedirs(SPLASH_OUT, exist_ok=True)

GREEN = (94, 156, 44, 255)        # #5E9C2C
GREEN_LIGHT = (139, 195, 74, 255)  # lighter accent for gradient
GREEN_DARK = (61, 110, 24, 255)    # shadow / depth
ORANGE = (243, 107, 33, 255)       # #F36B21
ORANGE_LIGHT = (255, 158, 84, 255)
WHITE = (255, 255, 255, 255)

SIZE = 1024
FONT_PATH = r"C:\Windows\Fonts\ARLRDBD.TTF"  # Arial Rounded MT Bold


def radial_gradient(size, center, r0, c_in, c_out):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    cx, cy = center
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / r0
            d = min(d, 1.0)
            r = int(c_in[0] + (c_out[0] - c_in[0]) * d)
            g = int(c_in[1] + (c_out[1] - c_in[1]) * d)
            b = int(c_in[2] + (c_out[2] - c_in[2]) * d)
            px[x, y] = (r, g, b, 255)
    return img


def draw_sunburst(canvas_size, center, inner_r, outer_r, n_rays, color_in, color_out):
    """Fan of pointed triangular rays opening upward (rising-sun look).

    Each ray is a narrow triangle: a wide base near the center (inner_r)
    tapering to a point at outer_r — the classic sun-ray silhouette.
    Screen coords (y grows downward): sweeping theta from 180deg (left)
    through 270deg (straight up) to 360deg (right) traces an
    upward-opening fan, never dipping below the center line.
    """
    layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    for i in range(n_rays):
        t = i / (n_rays - 1)
        theta = math.radians(180 + 180 * t)
        ray_len = outer_r if i % 2 == 0 else outer_r * 0.80
        half_w = math.radians(180 / n_rays) * 0.42
        a1 = theta - half_w
        a2 = theta + half_w
        tip = (cx + ray_len * math.cos(theta), cy + ray_len * math.sin(theta))
        base1 = (cx + inner_r * math.cos(a1), cy + inner_r * math.sin(a1))
        base2 = (cx + inner_r * math.cos(a2), cy + inner_r * math.sin(a2))
        t_color = tuple(
            int(color_in[k] + (color_out[k] - color_in[k]) * t) for k in range(3)
        ) + (255,)
        draw.polygon([tip, base1, base2], fill=t_color)
    # A small filled disc at the core hides the seams where ray bases meet.
    draw.ellipse(
        [cx - inner_r * 0.9, cy - inner_r * 0.9, cx + inner_r * 0.9, cy + inner_r * 0.9],
        fill=color_out,
    )
    return layer


def draw_leaf(size, fill_color, vein_color):
    """Small leaf accent: a vesica (lens of two overlapping circles) tapers
    naturally to a point at both ends, giving a real leaf silhouette."""
    ss = size * 4  # supersample for a clean edge
    r = ss * 0.62
    offset = r * 0.80  # close to tangent (2r) so the lens tapers to sharp points
    c1 = Image.new("L", (ss, ss), 0)
    c2 = Image.new("L", (ss, ss), 0)
    ImageDraw.Draw(c1).ellipse(
        [ss / 2 - offset - r, ss / 2 - r, ss / 2 - offset + r, ss / 2 + r], fill=255
    )
    ImageDraw.Draw(c2).ellipse(
        [ss / 2 + offset - r, ss / 2 - r, ss / 2 + offset + r, ss / 2 + r], fill=255
    )
    from PIL import ImageChops

    mask = ImageChops.multiply(c1, c2)
    leaf = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    leaf.paste(Image.new("RGBA", (ss, ss), fill_color), (0, 0), mask)

    vein = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vein)
    vd.line(
        [(ss * 0.5 - offset * 0.32, ss * 0.5), (ss * 0.5 + offset * 0.32, ss * 0.5)],
        fill=vein_color,
        width=max(2, ss // 70),
    )
    leaf.alpha_composite(vein)
    leaf = leaf.resize((size, size), Image.LANCZOS)
    leaf = leaf.rotate(-32, expand=True, resample=Image.BICUBIC)
    return leaf


def build_mark(transparent_bg: bool, mark_scale: float = 1.0):
    """Builds the sunburst + NN + leaf artwork. Returns an RGBA image SIZE x SIZE."""
    if transparent_bg:
        base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    else:
        base = radial_gradient(SIZE, (SIZE * 0.5, SIZE * 0.38), SIZE * 0.85, GREEN_LIGHT, GREEN_DARK)

    # Anchor point: where the sunburst base meets the top of the NN wordmark.
    center_y = SIZE * 0.60 * mark_scale + SIZE * 0.5 * (1 - mark_scale)

    # Sunburst fan rising from behind the NN mark, like a sunrise.
    burst = draw_sunburst(
        SIZE,
        (SIZE * 0.5, center_y),
        inner_r=SIZE * 0.09 * mark_scale,
        outer_r=SIZE * 0.335 * mark_scale,
        n_rays=13,
        color_in=ORANGE_LIGHT,
        color_out=ORANGE,
    )
    burst = burst.filter(ImageFilter.GaussianBlur(SIZE * 0.001))
    base.alpha_composite(burst)

    # Soft shadow for the NN wordmark (depth).
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    font_size = int(SIZE * 0.30 * mark_scale)
    font = ImageFont.truetype(FONT_PATH, font_size)
    text = "NN"
    bbox = sd.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = SIZE * 0.5 - tw / 2 - bbox[0]
    ty = center_y - th * 0.32 - bbox[1]
    sd.text((tx + SIZE * 0.010, ty + SIZE * 0.016), text, font=font, fill=(20, 50, 10, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(SIZE * 0.010))
    base.alpha_composite(shadow)

    # White "NN" wordmark.
    text_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    td = ImageDraw.Draw(text_layer)
    td.text((tx, ty), text, font=font, fill=WHITE)
    base.alpha_composite(text_layer)

    # Small leaf accent, nestled where the top rays meet — reads as a sprout
    # crowning the sunburst rather than a disconnected shape.
    leaf_size = int(SIZE * 0.135 * mark_scale)
    leaf = draw_leaf(leaf_size, (255, 255, 255, 245), (94, 156, 44, 255))
    lx = int(SIZE * 0.5 + SIZE * 0.125 * mark_scale)
    ly = int(center_y - SIZE * 0.305 * mark_scale)
    base.alpha_composite(leaf, (lx - leaf.width // 2, ly - leaf.height // 2))

    return base


def add_outer_shadow(icon: Image.Image) -> Image.Image:
    """Soft outer drop shadow behind the full icon square (for web/desktop use)."""
    pad = int(SIZE * 0.06)
    canvas = Image.new("RGBA", (SIZE + pad * 2, SIZE + pad * 2), (0, 0, 0, 0))
    shadow_shape = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow_shape).rounded_rectangle(
        [pad, pad + int(SIZE * 0.02), pad + SIZE, pad + int(SIZE * 0.02) + SIZE],
        radius=int(SIZE * 0.18),
        fill=(20, 40, 10, 90),
    )
    shadow_shape = shadow_shape.filter(ImageFilter.GaussianBlur(SIZE * 0.03))
    canvas.alpha_composite(shadow_shape)
    canvas.alpha_composite(icon, (pad, pad))
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


# 1. Full-bleed app icon (green bg baked in) — used for iOS/Android/web/windows/macos source.
icon = build_mark(transparent_bg=False)
icon.convert("RGB").save(os.path.join(OUT, "app_icon.png"), "PNG")

# 2. Android adaptive icon foreground (transparent bg, scaled into safe zone ~66%).
foreground = build_mark(transparent_bg=True, mark_scale=0.62)
foreground.save(os.path.join(OUT, "app_icon_foreground.png"), "PNG")

# 3. Splash mark (transparent bg, generous size for the animated splash widget).
splash_mark = build_mark(transparent_bg=True, mark_scale=0.9)
splash_mark.save(os.path.join(SPLASH_OUT, "splash_logo.png"), "PNG")

# 4. Android 12+ splash icon (system draws it inside a fixed circular container;
#    per spec the artwork should occupy roughly the central 55% of the canvas).
android12 = Image.new("RGBA", (1152, 1152), (0, 0, 0, 0))
mark_for_a12 = build_mark(transparent_bg=True, mark_scale=0.62)
mark_for_a12 = mark_for_a12.resize((960, 960), Image.LANCZOS)
android12.alpha_composite(mark_for_a12, (96, 96))
android12.save(os.path.join(SPLASH_OUT, "splash_logo_android12.png"), "PNG")

print("Generated:")
for f in [
    os.path.join(OUT, "app_icon.png"),
    os.path.join(OUT, "app_icon_foreground.png"),
    os.path.join(SPLASH_OUT, "splash_logo.png"),
    os.path.join(SPLASH_OUT, "splash_logo_android12.png"),
]:
    print(" -", f)
