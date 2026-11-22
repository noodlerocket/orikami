"""Draws the planned layout of the expanded Kamiyama Village as a side-on
cut-away map (docs/village_map.png). A planning picture for Julian: the
three layers (rooftops, street, canals), the areas, obstacles, enemies,
shrines, hidden cranes, shortcuts and the paths that open later.

Run:  python tools/village_map.py
Edit the lists below and run it again to move things around.
"""
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
FONT = str(ROOT / "art_source" / "fonts" / "YujiSyuku-Regular.ttf")
OUT = ROOT / "docs" / "village_map.png"

W, H = 2720, 1450
rng = random.Random(4)

# Colours (the game's palette).
NIGHT = (24, 26, 44)
NIGHT_LOW = (14, 15, 26)
WASHI = (238, 230, 212)
WASHI_DIM = (176, 170, 160)
SUMI = (10, 10, 16)
STONE = (78, 80, 96)
STONE_DARK = (52, 54, 68)
ROOF = (40, 42, 56)
WATER = (44, 62, 84)
VERMILION = (196, 52, 34)
AMBER = (236, 172, 92)
BLOSSOM = (196, 150, 160)
LOCKED = (120, 150, 190)


def X(m: float) -> float:
    return 110 + m * 11.0


def Y(m: float) -> float:
    return 700 - m * 34


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size)


img = Image.new("RGB", (W, H), NIGHT)
d = ImageDraw.Draw(img, "RGBA")

# Sky: darker toward the top, a crumpled moon.
for y in range(H):
    t = y / H
    c = tuple(int(NIGHT_LOW[i] * (1 - t) + NIGHT[i] * t) for i in range(3))
    d.line([(0, y), (W, y)], fill=c)
d.ellipse((2560, 36, 2650, 126), fill=(214, 206, 188, 60))

# Far hills (backdrop) and the castle on its crag.
pts = [(0, Y(9))]
for i in range(0, 61):
    m = i * 4.0
    pts.append((X(m - 10), Y(7 + 3.5 * math.sin(m * 0.05) + 2 * math.sin(m * 0.13))))
pts += [(W, Y(0)), (0, Y(0))]
d.polygon(pts, fill=(36, 39, 62))
d.polygon([(X(176), Y(13)), (X(186), Y(17.5)), (X(196), Y(13))], fill=(46, 49, 74))
d.text((X(181), Y(18.6)), "Shiro, the castle", font=font(17), fill=(130, 132, 160))

# ---------------------------------------------------------------------------
# The ground: street level (0) with its parts, the canals below, the river.
# ---------------------------------------------------------------------------
# Earth under everything.
d.rectangle((0, Y(0), W, H - 330), fill=(30, 28, 34))

# The canals: a cut-away tunnel under the street, from the well to the river.
canal = [(4, -3.2, 70, -5.0), (70, -3.0, 150, -9.0)]
d.rectangle((X(2), Y(-3.0), X(70), Y(-5.0)), fill=(16, 17, 24))           # the long drain pipe west
d.rectangle((X(70), Y(-2.0), X(150), Y(-9.0)), fill=(16, 17, 24))         # the canal hall
d.rectangle((X(70), Y(-7.4), X(150), Y(-9.0)), fill=WATER)                # water in the canal
d.rectangle((X(2), Y(-4.6), X(70), Y(-5.0)), fill=WATER)                  # a trickle in the pipe
# Walkways and ledges in the canals.
for a, b, h in [(70, 84, -6.0), (88, 98, -5.2), (102, 112, -6.4), (116, 126, -5.0), (130, 134, -6.6), (140, 150, -6.0)]:
    d.rectangle((X(a), Y(h), X(b), Y(h - 0.5)), fill=STONE)
# Sluices: falling water from the street drains.
for sx in [100.0, 121.0]:
    for k in range(9):
        x = X(sx) + rng.uniform(-6, 6)
        d.line([(x, Y(-2.0)), (x, Y(-7.4))], fill=(150, 170, 196, 120), width=2)
# Deep water: falling in sends you back (like the pit today).
d.rectangle((X(134), Y(-7.4), X(140), Y(-9.0)), fill=(26, 38, 58))

# The river, between the canals' mouth and the gatehouse, under the bridge.
d.rectangle((X(98), Y(-0.2), X(136), Y(-2.6)), fill=WATER)
d.polygon([(X(98), Y(0)), (X(101), Y(-2.6)), (X(98), Y(-2.6))], fill=(30, 28, 34))

# The street, broken at the Fallen Street (into the canals) and at the river.
street = [(-8, 78), (96, 98), (136, 172)]
for a, b in street:
    d.rectangle((X(a), Y(0), X(b), Y(-0.7)), fill=STONE)
# The Fallen Street: crumbled edges, soggy planks across.
for a in [78.0, 96.0]:
    for k in range(6):
        x = X(a) + rng.uniform(-10, 10)
        d.rectangle((x, Y(-0.7) + rng.uniform(0, 30), x + rng.uniform(6, 14), Y(-0.7) + rng.uniform(30, 60)), fill=STONE_DARK)
for k in range(5):
    px = X(80 + k * 3.2)
    d.line([(px, Y(0.05)), (px + 28, Y(-0.05) + (8 if k == 2 else 0))], fill=(150, 128, 96), width=6)

# The red bridge over the river, its middle fallen.
for a, b in [(98, 114), (118, 136)]:
    d.rectangle((X(a), Y(0.6), X(b), Y(0.2)), fill=(150, 46, 34))
    for p in range(int(a) + 2, int(b), 4):
        d.line([(X(p), Y(0.2)), (X(p), Y(-1.6))], fill=(120, 40, 30), width=5)
    d.line([(X(a), Y(1.4)), (X(b), Y(1.4))], fill=(170, 56, 40), width=4)

# Shrine steps rising to the courtyard.
steps = 12
for k in range(steps):
    x0 = 172 + k * 1.5
    d.rectangle((X(x0), Y(k * 0.28), X(x0 + 1.6), Y(-0.7)), fill=STONE)
d.rectangle((X(190), Y(3.3), X(212), Y(-0.7)), fill=STONE)          # courtyard
d.rectangle((X(212), Y(3.3), X(232), Y(2.6)), fill=STONE_DARK)      # the road on (locked at first)

# ---------------------------------------------------------------------------
# Buildings and the rooftop road.
# ---------------------------------------------------------------------------
def house(a: float, b: float, eave: float, ridge: float, light=True):
    d.rectangle((X(a + 0.4), Y(eave), X(b - 0.4), Y(0)), fill=(46, 44, 52))
    d.polygon([(X(a - 0.6), Y(eave)), (X((a + b) / 2), Y(ridge)), (X(b + 0.6), Y(eave))], fill=ROOF)
    d.line([(X(a - 0.6), Y(eave)), (X((a + b) / 2), Y(ridge)), (X(b + 0.6), Y(eave))], fill=(96, 98, 118), width=3)
    if light:
        wx = X((a + b) / 2) - 14
        d.rectangle((wx, Y(eave * 0.55), wx + 28, Y(eave * 0.55) + 22), fill=(*AMBER, 170))

# Well Square.
house(16, 28, 4.2, 7.0)        # the Paper-Maker's workshop
house(-6, 2, 3.6, 6.0)
# Market Street: a row of shops, roofs close enough to run along.
for a, b, e, r in [(32, 40, 4.6, 7.4), (41, 50, 5.0, 8.2), (51, 58, 4.4, 7.0), (60, 70, 5.4, 8.8), (71, 78, 4.8, 7.6)]:
    house(a, b, e, r)
# Past the Fallen Street, rooftops go on over the canals' end and the river bank.
house(86, 95, 5.6, 9.0, False)  # a tall ruined house: its floor is gone
# River warehouse and the gatehouse block.
house(136, 144, 5.0, 8.0)
# The climbing course (today's gatehouse wall and tall wall, moved here).
d.rectangle((X(148), Y(8.5), X(149.3), Y(0)), fill=(58, 56, 66))
d.rectangle((X(152), Y(11.5), X(153.1), Y(0)), fill=(58, 56, 66))
d.rectangle((X(149.3), Y(2.6), X(152), Y(0)), fill=(26, 24, 30))      # the gate you walk under
d.rectangle((X(152), Y(11.6), X(158), Y(11.2)), fill=STONE)            # lookout ledge
house(160, 170, 4.4, 7.0)

# Market awnings (paper, they sag when you land on them).
for ax in [36.0, 46.0, 54.5, 66.0]:
    d.polygon([(X(ax - 2.2), Y(2.8)), (X(ax + 2.2), Y(2.8)), (X(ax + 2.6), Y(2.2)), (X(ax - 2.6), Y(2.2))], fill=(190, 178, 150))
    d.line([(X(ax - 2.4), Y(2.2)), (X(ax - 2.4), Y(0))], fill=(110, 90, 70), width=3)
# Lantern strings across the street (pogo off the lanterns).
for a, b in [(39, 52), (55, 70), (102, 112)]:
    sag = []
    for k in range(21):
        t = k / 20
        x = a + (b - a) * t
        sag.append((X(x), Y(6.0 - 1.2 * math.sin(t * math.pi))))
    d.line(sag, fill=(120, 110, 100), width=2)
    for k in range(1, 5):
        t = k / 5
        x, y = X(a + (b - a) * t), Y(6.0 - 1.2 * math.sin(t * math.pi))
        d.ellipse((x - 7, y + 4, x + 7, y + 22), fill=(*AMBER, 230))
# Swinging shop signs.
for sx in [61.5, 64.5, 67.5]:
    d.line([(X(sx), Y(5.4)), (X(sx) + 6, Y(3.9))], fill=(110, 90, 70), width=2)
    d.rectangle((X(sx) - 4, Y(3.9), X(sx) + 18, Y(3.0)), fill=(84, 64, 48))

# The rooftop road: a dotted line along the ridges, with gaps.
roof_path = [(33, 7.6), (45.5, 8.4), (54.5, 7.2), (65, 9.0), (74.5, 7.8), (90.5, 9.2), (104, 9.6), (108, 9.6)]
for (a, ha), (b, hb) in zip(roof_path, roof_path[1:]):
    d.line([(X(a), Y(ha + 0.5)), (X(b), Y(hb + 0.5))], fill=(*WASHI, 90), width=2)
# Floating roof pieces over the river (broken roofs on poles) to the gatehouse.
for a, b, h in [(104, 109, 9.2), (124, 128, 9.0), (131, 136, 8.4)]:
    d.rectangle((X(a), Y(h), X(b), Y(h - 0.4)), fill=ROOF)
    d.line([(X((a + b) / 2), Y(h - 0.4)), (X((a + b) / 2), Y(0.6))], fill=(70, 60, 56), width=3)
# The gap too wide to jump: the first Crane Glide gate.
d.line([(X(109.5), Y(9.6)), (X(123.5), Y(9.6))], fill=(*LOCKED, 200), width=3)

# Trees, the well, torii, lanterns, the shrine hall.
def tree(x: float, h: float):
    d.line([(X(x), Y(0)), (X(x), Y(h * 0.6))], fill=(54, 40, 40), width=8)
    for k in range(14):
        cx, cy = X(x + rng.uniform(-2.4, 2.4)), Y(h * 0.6 + rng.uniform(-0.4, 1.8))
        r = rng.uniform(12, 22)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*BLOSSOM, 150))

tree(12, 7)
tree(186, 8)
# The well.
d.rectangle((X(7), Y(1.0), X(9.4), Y(0)), fill=STONE)
d.polygon([(X(6.4), Y(2.8)), (X(8.2), Y(3.6)), (X(10), Y(2.8))], fill=ROOF)
d.line([(X(7.1), Y(1.0)), (X(7.1), Y(2.8))], fill=(70, 60, 56), width=3)
d.line([(X(9.3), Y(1.0)), (X(9.3), Y(2.8))], fill=(70, 60, 56), width=3)
# Torii at the top of the steps.
d.rectangle((X(189.2), Y(7.6), X(189.7), Y(3.3)), fill=VERMILION)
d.rectangle((X(192.3), Y(7.6), X(192.8), Y(3.3)), fill=VERMILION)
d.rectangle((X(188.4), Y(7.9), X(193.6), Y(7.4)), fill=VERMILION)
d.rectangle((X(188.9), Y(6.9), X(193.1), Y(6.6)), fill=VERMILION)
# Stone lanterns along the steps.
for k, lx in enumerate([174, 178, 182]):
    base = Y(k * 0.28 * 2.7 + 0.2)
    d.rectangle((X(lx), base - 34, X(lx) + 12, base), fill=STONE_DARK)
    d.ellipse((X(lx) - 2, base - 46, X(lx) + 14, base - 32), fill=(*AMBER, 200))
# The Hannya's shrine hall.
d.rectangle((X(198), Y(8.0), X(210), Y(3.3)), fill=(48, 44, 52))
d.polygon([(X(196.5), Y(8.0)), (X(204), Y(11.0)), (X(211.5), Y(8.0))], fill=ROOF)
d.rectangle((X(200), Y(7.2), X(208), Y(4.0)), fill=(214, 200, 170, 120))

# ---------------------------------------------------------------------------
# Areas (names over the top), markers and labels.
# ---------------------------------------------------------------------------
AREAS = [
    (-8, 32, "1  Well Square", "the start; the Paper-Maker"),
    (32, 78, "2  Market Street", "stalls, awnings, lanterns"),
    (78, 98, "3  Fallen Street", "the way down"),
    (98, 136, "4  River & Red Bridge", "wind over the water"),
    (136, 172, "5  Gatehouse", "the climbing course"),
    (172, 190, "6  Shrine Steps", "the last rest"),
    (190, 212, "7  Shrine Courtyard", "the Weeping Hannya"),
]
for a, b, name, sub in AREAS:
    d.line([(X(a), 196), (X(a), H - 340)], fill=(*WASHI, 28), width=1)
    d.text((X(a) + 10, 160), name, font=font(22), fill=WASHI)
    d.text((X(a) + 10, 190), sub, font=font(15), fill=WASHI_DIM)
d.text((X(-6), Y(-6.2)), "Under the street:", font=font(22), fill=WASHI)
d.text((X(-6), Y(-6.9)), "the Canals", font=font(30), fill=WASHI)
d.text((X(36), Y(11.6)), "Over the street: the Rooftop Road", font=font(24), fill=WASHI)

# Marker shapes.
def shrine(x: float, y: float, label: str):
    cx, cy = X(x), Y(y) - 26
    d.rectangle((cx - 15, cy - 15, cx + 15, cy + 15), fill=VERMILION)
    d.rectangle((cx - 11, cy - 11, cx + 11, cy + 11), outline=WASHI, width=2)
    k = font(18)
    d.text((cx - 9, cy - 13), "社", font=k, fill=WASHI)
    d.text((cx + 22, cy - 12), label, font=font(16), fill=WASHI)


def crane(x: float, y: float):
    cx, cy = X(x), Y(y)
    d.polygon([(cx - 14, cy), (cx, cy - 10), (cx + 3, cy + 2)], fill=WASHI)
    d.polygon([(cx, cy - 10), (cx + 14, cy - 2), (cx + 3, cy + 2)], fill=WASHI_DIM)
    d.line([(cx + 12, cy - 2), (cx + 18, cy - 12)], fill=WASHI, width=2)


def enemy(x: float, y: float, kind: str):
    cx, cy = X(x), Y(y) - 18
    d.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=SUMI, outline=(150, 70, 60), width=2)
    letter = {"husk": "H", "dog": "D", "bird": "B", "lantern": "L"}[kind]
    d.text((cx - 6, cy - 12), letter, font=font(18), fill=(214, 120, 100))


def note(x: float, y: float, text: str, dx: float = 0, dy: float = -30, colour=WASHI_DIM, size=15):
    d.text((X(x) + dx, Y(y) + dy), text, font=font(size), fill=colour)


def shortcut(x0, y0, x1, y1, label, ldy=-22):
    a, b = (X(x0), Y(y0)), (X(x1), Y(y1))
    n = int(math.dist(a, b) // 14)
    for k in range(n):
        if k % 2 == 0:
            p = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
            q = (a[0] + (b[0] - a[0]) * (k + 1) / n, a[1] + (b[1] - a[1]) * (k + 1) / n)
            d.line([p, q], fill=(*AMBER, 230), width=3)
    d.ellipse((b[0] - 5, b[1] - 5, b[0] + 5, b[1] + 5), fill=AMBER)
    d.text(((a[0] + b[0]) / 2 + 8, (a[1] + b[1]) / 2 + ldy), label, font=font(15), fill=AMBER)


def locked(x: float, y: float, text: str, left: bool = False):
    cx, cy = X(x), Y(y)
    d.rounded_rectangle((cx - 9, cy - 6, cx + 9, cy + 10), 2, fill=LOCKED)
    d.arc((cx - 7, cy - 16, cx + 7, cy - 0), 180, 360, fill=LOCKED, width=3)
    tx = cx - 16 - d.textlength(text, font=font(15)) if left else cx + 16
    d.text((tx, cy - 8), text, font=font(15), fill=LOCKED)


# Shrines (save, heal, come back here when you die).
shrine(24, 0, "")
note(19.0, 0, "Shrine: the Paper-Maker's door", dy=-74, colour=WASHI, size=16)
shrine(140, 0, "")
note(136.5, 0, "Shrine: river warehouse", dy=-74, colour=WASHI, size=16)
shrine(184, 2.4, "")
note(178, 2.4, "Shrine before the Hannya", dy=-74, colour=WASHI, size=16)

# Hidden paper cranes (bundles).
for cx, cy in [(22, 7.6), (74, 2.0), (90.5, 10.2), (113, -1.0), (131, -5.4), (155.5, 12.2), (154, -2.0)]:
    crane(cx, cy)

# Enemies.
for ex, ey, k in [(42, 0, "husk"), (58, 0, "husk"), (68, 9.0, "bird"), (84, -6.0, "dog"), (108, -6.4, "dog"),
                  (124, -5.0, "dog"), (100, 0.6, "husk"), (128, 0.6, "lantern"), (101, 10.6, "bird"), (144, 0, "husk"),
                  (165, 0, "lantern")]:
    enemy(ex, ey, k)

# Obstacles and ways round, labelled where they are.
note(33, 2.8, "awnings sag and bounce", dy=-22)
note(40, 6.2, "pogo along the lanterns up to the roofs", dy=-50)
note(60.5, 3.0, "swinging signs", dy=26)
d.rectangle((X(73.2), Y(3.2), X(75.6), Y(0.6)), fill=(222, 206, 170, 150))
note(66, 0, "shoji wall: cut through to a back room", dy=28)
note(79, 0.0, "soggy planks give way", dy=-36)
note(80.5, 10.8, "ruined house: drop through", dy=-8)
note(108.5, 1.4, "broken: jump + dash", dy=-30)
note(121, 3.6, "gusts push you", dy=-30)
note(99, -2.2, "sluice: falling water", dx=-90, dy=20)
note(117, -2.2, "sluice", dy=20)
note(132.5, -7.4, "deep water", dy=10)
note(140, -6.0, "climb out", dy=-30)
note(84.5, -6.0, "crawlspace", dx=0, dy=16)
note(147, 8.6, "wall jumps", dx=-120, dy=0)
note(152.5, 11.6, "lookout", dy=-30)
note(170.5, 0.0, "the steps", dy=12)

# Shortcuts (opened from the far side).
shortcut(34, 7.6, 34, 0.2, "kick the ladder down")
shortcut(60, -4.0, 9, -4.0, "the drain pipe: a grate opens into Well Square")
shortcut(150.5, 1.0, 145, 1.0, "unbar the gate", ldy=40)

# Ways that open later.
locked(116.5, 10.4, "too wide: Crane Glide")
locked(157.0, 13.6, "the castle road: Crane Glide", left=True)
d.line([(X(158), Y(11.6)), (X(170), Y(14.0))], fill=(*LOCKED, 160), width=2)
locked(229.5, 4.4, "")
note(213.5, 2.6, "the road to the Bamboo:", dy=10, colour=LOCKED)
note(213.5, 2.6, "opens when the Hannya falls", dy=30, colour=LOCKED)

# The Ronin's main route, faint, so the shape of the level reads.
route = [(8, 0.4), (32, 0.4), (78, 0.4), (80, -1.0), (84, -5.6), (98, -4.8), (112, -6.0), (126, -4.6), (140, -5.6),
         (148, -3.4), (148, 0.4), (172, 0.4), (190, 3.7), (206, 3.7)]
for (a, ha), (b, hb) in zip(route, route[1:]):
    d.line([(X(a), Y(ha)), (X(b), Y(hb))], fill=(*WASHI, 60), width=7)

# Today's village, for scale: a bracket under the street.
d.line([(X(-8), Y(-11.2)), (X(64), Y(-11.2))], fill=(*WASHI_DIM, 160), width=2)
d.line([(X(-8), Y(-11.0)), (X(-8), Y(-11.4))], fill=WASHI_DIM, width=2)
d.line([(X(64), Y(-11.0)), (X(64), Y(-11.4))], fill=WASHI_DIM, width=2)
d.text((X(-6), Y(-11.3)), "the village today (75 m)", font=font(16), fill=WASHI_DIM)
d.text((X(70), Y(-11.3)), "planned: about 230 m, in three layers", font=font(16), fill=WASHI_DIM)

# Title and legend.
d.text((60, 40), "KAMIYAMA VILLAGE", font=font(52), fill=WASHI)
d.text((64, 108), "the expanded first region: a plan, seen from the side", font=font(22), fill=WASHI_DIM)
d.rectangle((1200, 52, 1236, 88), fill=VERMILION)
d.text((1206, 52), "神", font=font(26), fill=WASHI)

ly = H - 290
d.rectangle((0, ly - 20, W, H), fill=(12, 12, 20))
d.text((60, ly), "KEY", font=font(26), fill=WASHI)
col = [60, 560, 1060, 1560, 2060]
shrine_icon_y = ly + 70
items = [
    ("shrine", "Shrine: save, heal, return here when you fall"),
    ("crane", "Hidden paper cranes (a bundle)"),
    ("enemy", "H husk   D paper dog   B paper bird   L lantern husk"),
    ("short", "Shortcut, opened from the far side"),
    ("lock", "Opens later (Crane Glide, or after the Hannya)"),
    ("route", "The main way through"),
]
for i, (kind, words) in enumerate(items):
    cx = 90 + (i % 3) * 820
    cy = ly + 70 + (i // 3) * 70
    if kind == "shrine":
        d.rectangle((cx - 15, cy - 15, cx + 15, cy + 15), fill=VERMILION)
        d.text((cx - 9, cy - 13), "社", font=font(18), fill=WASHI)
    elif kind == "crane":
        d.polygon([(cx - 14, cy), (cx, cy - 10), (cx + 3, cy + 2)], fill=WASHI)
        d.polygon([(cx, cy - 10), (cx + 14, cy - 2), (cx + 3, cy + 2)], fill=WASHI_DIM)
    elif kind == "enemy":
        d.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=SUMI, outline=(150, 70, 60), width=2)
        d.text((cx - 6, cy - 12), "H", font=font(18), fill=(214, 120, 100))
    elif kind == "short":
        d.line([(cx - 20, cy), (cx - 6, cy)], fill=AMBER, width=3)
        d.line([(cx + 2, cy), (cx + 14, cy)], fill=AMBER, width=3)
        d.ellipse((cx + 14, cy - 5, cx + 24, cy + 5), fill=AMBER)
    elif kind == "lock":
        d.rounded_rectangle((cx - 9, cy - 6, cx + 9, cy + 10), 2, fill=LOCKED)
        d.arc((cx - 7, cy - 16, cx + 7, cy), 180, 360, fill=LOCKED, width=3)
    elif kind == "route":
        d.line([(cx - 22, cy), (cx + 22, cy)], fill=(*WASHI, 90), width=7)
    d.text((cx + 40, cy - 14), words, font=font(19), fill=WASHI)
d.text((60, ly + 210), "Everything moves: banners and lanterns sway, awnings sag under him, planks creak, water runs, "
       "villagers' shutters close as he passes, birds scatter.", font=font(19), fill=WASHI_DIM)
d.text((60, ly + 245), "Numbers are metres along the street; heights are drawn taller than they are so the layers read.",
       font=font(16), fill=(130, 126, 120))

img.save(OUT)
print("saved", OUT)
