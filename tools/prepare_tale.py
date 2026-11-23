"""Prepares the Paper-Maker's three pictures (ink paintings made with Meshy's
image generator, docs/reference/tale_*_source.png) for her tale
(paper_maker_tale.gd): crops each to the painting, turns its paper white
(the picture is laid over her sheet by multiplying, so only the ink shows),
fades its edges to nothing, and saves a smaller JPEG in textures/.

Run from the project folder:  python tools/prepare_tale.py
"""
from PIL import Image, ImageFilter, ImageStat

# [source, output, crop box (left, top, right, bottom) in the source]
PICTURES = [
    ("docs/reference/tale_castle_source.png", "textures/tale_castle.jpg", (70, 60, 1150, 860)),
    ("docs/reference/tale_village_source.png", "textures/tale_village.jpg", (250, 205, 995, 700)),
    ("docs/reference/tale_blank_source.png", "textures/tale_blank.jpg", (0, 0, 1200, 896)),
]

for src, out, box in PICTURES:
    im = Image.open(src).convert("RGB").crop(box)
    # The paper's colour: the brightest tenth of the picture.
    grey = im.convert("L")
    hist = grey.histogram()
    total = sum(hist)
    count, level = 0, 255
    while level > 0 and count < total * 0.1:
        count += hist[level]
        level -= 1
    bright = grey.point(lambda v, l=level: 255 if v >= l else 0)
    paper = ImageStat.Stat(im, mask=bright).mean
    # Divide by the paper: paper becomes white, ink keeps its tone.
    r, g, b = im.split()
    r = r.point(lambda v, p=paper[0]: min(255, int(v * 255 / p)))
    g = g.point(lambda v, p=paper[1]: min(255, int(v * 255 / p)))
    b = b.point(lambda v, p=paper[2]: min(255, int(v * 255 / p)))
    im = Image.merge("RGB", (r, g, b))
    # Fade the edges to white.
    w, h = im.size
    fade = Image.new("L", (w, h), 0)
    margin = int(min(w, h) * 0.06)
    inner = Image.new("L", (w - margin * 2, h - margin * 2), 255)
    fade.paste(inner, (margin, margin))
    fade = fade.filter(ImageFilter.GaussianBlur(margin * 0.6))
    white = Image.new("RGB", (w, h), (255, 255, 255))
    im = Image.composite(im, white, fade)
    im.thumbnail((1024, 1024))
    im.save(out, quality=90)
    print(out, im.size, "paper", [int(c) for c in paper])
