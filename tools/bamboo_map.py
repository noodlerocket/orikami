"""Draws the PLAN for the expanded Bamboo of Folded Wind (docs/bamboo_map.png)
as a side-on cut-away map: a planning picture for Julian, like
tools/village_map.py. About 230 m, the size of the town, built around the
Crane Glide: ravines, a deep gorge with updrafts, a high canopy road, a
waterfall, then Akane's clearing at the far end.

Run:  python tools/bamboo_map.py
Edit the lists below and run it again to move things around.
Heights are metres above the grove's floor (the path he walks in today).
"""
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = str(ROOT / "art_source" / "fonts" / "YujiSyuku-Regular.ttf")
OUT = ROOT / "docs" / "bamboo_map.png"

W, H = 3300, 1500
rng = random.Random(7)

SKY_TOP = (226, 206, 170)
SKY_LOW = (240, 228, 200)
GROUND = (74, 62, 50)
GROUND_TOP = (92, 112, 52)
ROCK = (66, 58, 54)
STEM = (70, 116, 56)
STEM_FAR = (150, 170, 120)
WATER = (96, 140, 160)
SUMI = (24, 22, 20)
WASHI = (250, 244, 230)
VERMILION = (186, 48, 34)
GLIDE = (40, 90, 150)
WIND = (110, 150, 90)
GOLD = (190, 150, 60)
OLD = (120, 112, 100)


def X(m: float) -> float:
    return 70 + (m - 180.0) * 13.2


def Y(m: float) -> float:
    return 780 - m * 25


def R(box, **kw):
    x0, y0, x1, y1 = box
    d.rectangle((min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)), **kw)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size)


img = Image.new("RGB", (W, H), SKY_LOW)
d = ImageDraw.Draw(img, "RGBA")
for y in range(H):
    t = min(1.0, y / 1000)
    d.line([(0, y), (W, y)], fill=tuple(int(SKY_TOP[i] * (1 - t) + SKY_LOW[i] * t) for i in range(3)))
d.ellipse((X(330) - 40, Y(26) - 40, X(330) + 40, Y(26) + 40), fill=(200, 70, 50, 150))
# Far misty bamboo.
for k in range(260):
    x = rng.uniform(0, W)
    d.line([(x, Y(-6)), (x + rng.uniform(-6, 6), Y(rng.uniform(14, 30)))], fill=STEM_FAR + (70,), width=rng.randint(3, 6))

# ---- The ground, left to right: [x, height] points of its top edge. ----
# (None between two points = a gap: the ground drops into a ravine there.)
PROFILE = [
    (183, 0), (213, 0), None,                       # mist way, altar; the first ravine
    (221.5, 0), (234, 0), None,                     # the rope bridge's ravine
    (242, 0), (248, 0), (250, -14), (256, -15), (270, -15), (276, -13), (286, -14),  # the gorge
    (288, -2), (292, 0), (296, 0),
    (300, 0), (318, -1), (330, 0), (345, 0),         # the grove floor under the canopy
    (345, 0), (372, 0),                              # the paper mill
    (372, 0), (376, 3), (378, 12), (384, 12),        # up beside the falls
    None,
    (396, -3), (399, 1), (414, 1),                   # the falls' far bank, Akane's clearing
]


def ground(points):
    poly = [(X(points[0][0]), Y(-18))] + [(X(px), Y(py)) for px, py in points] + [(X(points[-1][0]), Y(-18))]
    d.polygon(poly, fill=GROUND)
    for a, b in zip(points, points[1:]):
        d.line([(X(a[0]), Y(a[1])), (X(b[0]), Y(b[1]))], fill=GROUND_TOP, width=7)


run = []
for p in PROFILE:
    if p is None:
        ground(run)
        run = []
    else:
        run.append(p)
ground(run)

# Ravine floors, the gorge stream, the falls and its pool.
R((X(213), Y(-16), X(221.5), Y(-18)), fill=ROCK)
R((X(234), Y(-16), X(242), Y(-18)), fill=ROCK)
R((X(250), Y(-15.2), X(286), Y(-16.5)), fill=WATER)
R((X(384), Y(-6), X(396), Y(-18)), fill=ROCK)
R((X(384.5), Y(-4), X(395.5), Y(-6.5)), fill=WATER)
R((X(380), Y(12), X(383.5), Y(-4)), fill=WATER + (170,))
d.text((X(381.7), Y(5)), "滝", font=font(34), fill=WASHI, anchor="mm")

# Stems: standing on the ground (never floating).
def stems(x0, x1, foot, every=1.6, tall=(14, 24)):
    x = x0
    while x < x1:
        top = foot + rng.uniform(*tall)
        d.line([(X(x), Y(foot)), (X(x), Y(top))], fill=STEM, width=5)
        for n in range(int(foot) + 2, int(top), 3):
            d.line([(X(x) - 4, Y(n)), (X(x) + 4, Y(n))], fill=(40, 70, 34), width=2)
        x += every * rng.uniform(0.7, 1.4)


stems(184, 212, 0)
stems(222, 233, 0)
stems(243, 247.5, 0)
stems(251, 285, -15, 2.6, (12, 30))
stems(289, 296, 0)
stems(298, 344, 0, 1.3, (18, 28))
stems(373, 377, 0)
stems(400, 413, 1)

# ---- Things to stand on that are not ground: [x0, x1, height, kind]. ----
LEDGES = [
    (214.5, 216.0, -1.0, "snapped bridge"),
    (234, 242, -0.3, "rope bridge"),
    (252, 256, -6, "ledge"), (262, 265, -3, "ledge"), (271, 275, -8, "ledge"), (280, 283, -4, "ledge"),
    (297, 303, 8, "walk"), (306, 311, 12, "walk"), (315, 318, 16, "top"), (322, 328, 13, "walk"),
    (332, 336, 17, "top"), (339, 345, 11, "walk"),
    (352, 362, 5, "mill loft"),
]
for x0, x1, h, kind in LEDGES:
    colour = (150, 120, 70) if kind in ("walk", "rope bridge", "mill loft", "snapped bridge") else (94, 84, 72)
    R((X(x0), Y(h) - 4, X(x1), Y(h) + 6), fill=colour)

# The paper mill: a waterwheel on a stream, drying racks, a loft.
R((X(349), Y(0), X(365), Y(5)), outline=SUMI, width=3, fill=(196, 170, 130, 120))
d.polygon([(X(348), Y(5)), (X(357), Y(9)), (X(366), Y(5))], fill=(60, 54, 58))
d.ellipse((X(366) - 38, Y(2.5) - 38, X(366) + 38, Y(2.5) + 38), outline=(110, 80, 50), width=5)
for k in range(3):
    R((X(342 - k * 1.2) - 1, Y(0), X(342 - k * 1.2) + 1, Y(2.4)), fill=(110, 80, 50))

# ---- Updrafts: the folded wind rising (it lifts him while he glides). ----
UPDRAFTS = [(259, -15, 4), (268, -15, 6), (278, -15, 3), (313, 0, 18), (330, 0, 20)]
for x, lo, hi in UPDRAFTS:
    for k in range(5):
        yy = lo + (hi - lo) * k / 5
        d.line([(X(x) - 14, Y(yy)), (X(x), Y(yy + 1.4)), (X(x) + 14, Y(yy))], fill=WIND + (220,), width=4)
    d.line([(X(x), Y(lo)), (X(x), Y(hi))], fill=WIND + (120,), width=2)

# ---- Glide paths (dashed arcs). ----
def dashed_arc(a, b, lift=2.0):
    pts = []
    for i in range(41):
        t = i / 40
        x = a[0] + (b[0] - a[0]) * t
        y = a[1] + (b[1] - a[1]) * t + math.sin(math.pi * t) * lift
        pts.append((X(x), Y(y)))
    for i in range(0, 40, 2):
        d.line([pts[i], pts[i + 1]], fill=GLIDE, width=5)
    d.ellipse((pts[-1][0] - 6, pts[-1][1] - 6, pts[-1][0] + 6, pts[-1][1] + 6), fill=GLIDE)


GLIDES = [
    ((211, 2), (222, 0)),             # the first ravine (as today)
    ((247, 2), (259, -2)), ((259, 4), (268, 1)), ((268, 6), (278, 0)), ((278, 3), (288, -1.5)),  # the gorge
    ((303, 9), (306, 12)), ((311, 13), (313, 10)), ((313, 18), (315, 16)), ((318, 17), (322, 13)),
    ((328, 14), (330, 12)), ((330, 20), (332, 17)), ((336, 18), (339, 11)),
    ((384, 13), (399, 1.5)),          # the long glide over the falls
]
for a, b in GLIDES:
    dashed_arc(a, b, 1.6)

# Climbs (wall-jump chimneys between close stems).
for x, lo, hi in [(287, -14, -2), (296, 0, 8), (377, 0, 12)]:
    for k in range(int(lo), int(hi), 2):
        d.line([(X(x) - 10, Y(k)), (X(x) + 10, Y(k + 1)), (X(x) - 10, Y(k + 2))], fill=SUMI + (160,), width=3)

# ---- Marks: shrines, cranes, enemies, Akane, the altar. ----
def shrine(x, h, n):
    R((X(x) - 11, Y(h) - 40, X(x) + 11, Y(h)), fill=VERMILION)
    d.text((X(x), Y(h) - 54), f"shrine {n}", font=font(24), fill=VERMILION, anchor="mm")


shrine(196, 0, 4)
shrine(356, 0, 5)
d.polygon([(X(206) - 16, Y(0)), (X(206) + 16, Y(0)), (X(206), Y(2.2))], fill=GOLD)
d.text((X(206), Y(3.2)), "the Crane Glide", font=font(24), fill=SUMI, anchor="mm")

for x, h in [(268, -15), (316.5, 16), (380.5, 4), (360, 5)]:
    d.text((X(x), Y(h) - 18), "鶴", font=font(30), fill=GOLD, anchor="mm")

ENEMIES = [(226, 0, "dog"), (230, 0, "dog"), (263, -2, "bird"), (276, -6, "bird"), (304, 0, "dog"),
           (325, 0, "kamaitachi"), (308, 13, "kamaitachi"), (334, 18, "bird"), (375, 0, "dog")]
for x, h, kind in ENEMIES:
    d.ellipse((X(x) - 9, Y(h) - 26, X(x) + 9, Y(h) - 8), fill=SUMI)
    d.text((X(x), Y(h) - 38), kind, font=font(20), fill=SUMI, anchor="mm")

d.text((X(407), Y(1) - 50), "Akane", font=font(30), fill=VERMILION, anchor="mm")
d.ellipse((X(407) - 10, Y(1) - 30, X(407) + 10, Y(1) - 8), fill=VERMILION)
d.text((X(186), Y(0) - 40), "from the\ntown's gate", font=font(22), fill=SUMI, anchor="mm")

# ---- Area names and numbers along the top. ----
AREAS = [
    (183, 213, "1  Mist Way and the Crane Altar", "as today"),
    (213, 242, "2  The two ravines", "as today"),
    (242, 292, "3  The Windfall Gorge", "new: updrafts out of a deep gorge"),
    (292, 345, "4  The Canopy Road", "new: high walkways, stem-tops"),
    (345, 372, "5  The paper mill", "new: shrine 5, a quiet rest"),
    (372, 398, "6  The Falls", "new: climb up, one long glide down"),
    (398, 414, "7  Akane", "her clearing, moved to the end"),
]
for i, (x0, x1, name, note) in enumerate(AREAS):
    top = 130 + (i % 2) * 80
    d.line([(X(x0), top - 10), (X(x0), Y(-18))], fill=SUMI + (40,), width=2)
    d.text(((X(x0) + X(x1)) / 2, top + 10), name, font=font(30), fill=SUMI, anchor="mm")
    d.text(((X(x0) + X(x1)) / 2, top + 46), note, font=font(22), fill=OLD, anchor="mm")

d.text((70, 40), "竹  The Bamboo of Folded Wind: the PLAN, about 230 m (today 75 m)", font=font(44), fill=SUMI)

# Legend, on a strip of paper under the map.
R((0, Y(-18), W, H), fill=(236, 228, 210))
LX, LY = 70, Y(-18) + 70
d.line([(LX, LY), (LX + 60, LY)], fill=GLIDE, width=5)
d.text((LX + 75, LY), "glide", font=font(24), fill=SUMI, anchor="lm")
d.line([(LX + 190, LY + 8), (LX + 204, LY - 6), (LX + 218, LY + 8)], fill=WIND, width=4)
d.text((LX + 235, LY), "updraft: lifts him while he glides", font=font(24), fill=SUMI, anchor="lm")
d.line([(LX + 740, LY - 10), (LX + 760, LY), (LX + 740, LY + 10)], fill=SUMI, width=3)
d.text((LX + 780, LY), "wall-jump climb between close stems", font=font(24), fill=SUMI, anchor="lm")
d.text((LX + 1340, LY), "鶴", font=font(30), fill=GOLD, anchor="mm")
d.text((LX + 1365, LY), "paper cranes", font=font(24), fill=SUMI, anchor="lm")
d.text((LX, LY + 60), "The gorge floor is a shallow stream: falling in is not death, a stem chimney climbs back up. "
       "kamaitachi = a new enemy: a paper sickle-weasel that rides the gusts (to be proposed).",
       font=font(24), fill=SUMI, anchor="lm")
d.text((LX, LY + 105), "The glide gets weaker (it tires: see the note). Updrafts are what carry him far, "
       "so the long crossings need skill, not just holding Space.", font=font(24), fill=SUMI, anchor="lm")

img.save(OUT)
print("wrote", OUT)
