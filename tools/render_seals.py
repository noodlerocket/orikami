"""Renders the bosses' seals (hanko) for their painted titles (HannyaTitle):
a vermilion impression with the boss's two characters carved out in the
brush font, stacked as on a real seal, an inner border, and the wear of a
real stamp: uneven ink, worn speckles, rough edges.

Run from the project folder:  python tools/render_seals.py
Writes textures/seal_<name>.png. Add a line to SEALS for a new boss.
"""
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

FONT = "art_source/fonts/YujiSyuku-Regular.ttf"
SEALS = [("hannya", "般若"), ("akane", "朱狐"), ("orikami", "折神"), ("dragon", "祭龍"), ("hosho", "宝照")]
SIZE = 512
INK = (178, 40, 30)
PAPER = (240, 226, 206)


def noise(size, scale, seed):
    """Soft blotchy noise 0..255 (small random image blown up and blurred)."""
    rnd = random.Random(seed)
    small = Image.new("L", (max(2, size // scale), max(2, size // scale)))
    small.putdata([rnd.randint(0, 255) for _ in range(small.width * small.height)])
    return small.resize((size, size), Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale * 0.4))


def render(name, text, seed):
    rnd = random.Random(seed)
    s = SIZE
    m = 34  # margin round the seal
    # The seal's outline: a square with slightly wavering, worn edges.
    mask = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(mask)
    pts = []
    corners = [(m, m), (s - m, m), (s - m, s - m), (m, s - m)]
    for i in range(4):
        a, b = corners[i], corners[(i + 1) % 4]
        for k in range(24):
            t = k / 24
            jitter = rnd.uniform(-3.5, 3.5)
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            if a[1] == b[1]:
                y += jitter
            else:
                x += jitter
            pts.append((x, y))
    d.polygon(pts, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1.2)).point(lambda v: 255 if v > 128 else 0)
    # Carved parts: the inner border and the two characters, stacked.
    carve = Image.new("L", (s, s), 0)
    c = ImageDraw.Draw(carve)
    inset = m + 26
    c.rectangle([inset, inset, s - inset, s - inset], outline=255, width=9)
    font = ImageFont.truetype(FONT, 205)
    cell = (s - 2 * (inset + 16)) / 2
    for i, ch in enumerate(text):
        box = font.getbbox(ch)
        w, h = box[2] - box[0], box[3] - box[1]
        cx = s / 2
        cy = inset + 16 + cell * (i + 0.5)
        c.text((cx - w / 2 - box[0], cy - h / 2 - box[1]), ch, font=font, fill=255)
    carve = carve.filter(ImageFilter.GaussianBlur(0.8))
    # Wear: the ink takes unevenly; specks where it did not take at all.
    density = noise(s, 24, seed + 1).point(lambda v: 215 + v * 40 // 255)
    specks = noise(s, 5, seed + 2).point(lambda v: 0 if v > 232 else 255)
    edge_wear = noise(s, 9, seed + 3).point(lambda v: 0 if v > 238 else 255)
    ink = ImageChops.multiply(mask, density)
    ink = ImageChops.multiply(ink, specks)
    ink = ImageChops.multiply(ink, edge_wear)
    ink = ImageChops.multiply(ink, carve.point(lambda v: 255 - v))
    # The carved characters show the paper: drawn under the ink, inside the seal.
    paper = ImageChops.multiply(mask, carve)
    out = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (s, s), PAPER + (255,)), (0, 0), paper)
    out.paste(Image.new("RGBA", (s, s), INK + (255,)), (0, 0), ink)
    out.save(f"textures/seal_{name}.png")
    print("rendered seal", name)


for n, (name, text) in enumerate(SEALS):
    render(name, text, 100 + n * 17)
