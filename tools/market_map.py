"""Draws the PLAN for the whole Lantern Market (docs/market_map.png) as a
side-on cut-away map: a planning picture for Julian, like
tools/bamboo_map.py. About 450 m (double the bamboo grove), on three layers
(street, roofs, canals), the mini-boss (a paper dragon) in the middle.
Written up in docs/lantern_market_plan.md.

Run:  python tools/market_map.py
Edit the lists below and run it again to move things around.
Heights are metres above the Mist Gate's street.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = str(ROOT / "art_source" / "fonts" / "YujiSyuku-Regular.ttf")
OUT = ROOT / "docs" / "market_map.png"

W, H = 3500, 1500
LEFT, RIGHT = 120, 3380
LENGTH = 450.0
BASE_Y = 1080   # where height 0 is drawn
PX_PER_M = (RIGHT - LEFT) / LENGTH
UP = 26.0       # pixels per metre of height

NIGHT = (22, 24, 46)
NIGHT_LOW = (58, 40, 46)
GROUND = (40, 34, 44)
STREET = (96, 92, 120)
ROOF = (150, 74, 52)
CANAL = (52, 84, 130)
WASHI = (246, 238, 220)
GOLD = (222, 176, 82)
VERMILION = (196, 52, 36)
EMBER = (240, 120, 40)
GREEN = (120, 190, 120)
BUILT = (120, 200, 160)


def X(m):
    return LEFT + m * PX_PER_M


def Y(h):
    return BASE_Y - h * UP


# The street: (metres, height) points.
STREET_LINE = [(0, 0), (55, 0), (65, 2.6), (75, 3), (116, 3), (128, 6.5), (150, 6.5), (215, 6.5),
               (215, 5), (285, 5), (290, 7), (300, 10), (315, 13), (330, 16), (345, 20), (355, 22),
               (420, 22), (420, 24), (450, 24)]
# The roofs route: (metres, height).
ROOF_LINE = [(10, 2.5), (30, 5.2), (45, 6.6), (60, 7), (96, 8), (116, 10), (140, 11), (165, 12),
             (190, 12.5), (215, 12), (285, 14), (310, 20), (340, 26), (360, 28), (400, 28), (420, 27)]
# The canals: (metres, height).
CANAL_LINE = [(58, -1), (72, -1), (128, 2), (150, 2), (215, 2.5), (232, 2.5)]
# [from m, to m, name, note]
AREAS = [
    (0, 8, "Mist Gate", "from the bamboo"),
    (8, 58, "Night Bazaar", "built"),
    (58, 116, "Red Bridge, Upper Market", "built"),
    (116, 150, "Festival Square", "crossroads"),
    (150, 215, "Canal Quarter", "boats, a lock"),
    (215, 285, "Ward of Shut Doors", "MINI-BOSS"),
    (285, 355, "Lantern Makers' Rise", "a climb, kilns"),
    (355, 420, "Gilded Terraces", "bridges, guards"),
    (420, 450, "Hosho's Gate", "the general"),
]
# (metres, height, label)
SHRINES = [(8, 0, "shrine 6"), (205, 6.5, "shrine 7"), (436, 24, "shrine 8")]
CRANES = [(30, 5.2), (96, 8), (180, 0.5), (330, 24), (395, 30)]
SHORTCUTS = [((200, 2.5), (8, 0.5), "canal lock"), ((300, 10), (140, 6.5), "lantern hoist"), ((380, 22), (360, 14), "rope ladder")]
BOATS = [(165, 2.3), (185, 2.3), (200, 2.3)]
UPDRAFTS = [(300, 10), (322, 15), (342, 20)]
ENEMIES = [(38, 0, "lantern husk"), (50, 0, "husk"), (88, 3, "husk"), (106, 3, "lantern husk"), (160, 6.5, "gilded guard"),
           (175, 2.2, "paper dog"), (198, 12.5, "chochin-obake"), (305, 12, "chochin-obake"), (335, 18, "chochin-obake"),
           (370, 22, "gilded guard"), (405, 22, "gilded guard"), (395, 28, "chochin-obake")]


def font(size):
    return ImageFont.truetype(FONT, size)


def main():
    img = Image.new("RGB", (W, H), NIGHT)
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        c = tuple(int(NIGHT[i] + (NIGHT_LOW[i] - NIGHT[i]) * t) for i in range(3))
        d.line([(0, y), (W, y)], fill=c)
    # The ground under the street.
    poly = [(X(m), Y(h)) for m, h in STREET_LINE] + [(X(450), H), (X(0), H)]
    d.polygon(poly, fill=GROUND)
    # Canals: water bands.
    for i in range(len(CANAL_LINE) - 1):
        (m0, h0), (m1, h1) = CANAL_LINE[i], CANAL_LINE[i + 1]
        d.polygon([(X(m0), Y(h0)), (X(m1), Y(h1)), (X(m1), Y(h1) + 34), (X(m0), Y(h0) + 34)], fill=CANAL)
    d.text((X(175), Y(2.5) + 40), "the Canals", font=font(30), fill=(170, 200, 240))
    # Area bands and names.
    for i, (a, b, name, note) in enumerate(AREAS):
        boss = note == "MINI-BOSS"
        row = 0 if (i % 2 == 0 or b - a > 45) else 70
        if boss:
            d.rectangle([X(a), 160, X(b), Y(0) + 80], fill=(70, 34, 30))
        d.line([(X(a), 150), (X(a), H - 60)], fill=(80, 80, 110), width=2)
        d.text((X((a + b) / 2), 50 + row), name, font=font(30), fill=GOLD if boss else WASHI, anchor="mm")
        d.text((X((a + b) / 2), 88 + row), f"{a}-{b} m  {note}", font=font(20),
               fill=EMBER if boss else (BUILT if note == "built" else (190, 180, 200)), anchor="mm")
    for k in range(5):
        hx = X(222 + k * 13)
        d.rectangle([hx, Y(10), hx + 70, Y(5)], fill=(70, 50, 50), outline=(120, 70, 50))
        d.polygon([(hx - 10, Y(10)), (hx + 80, Y(10)), (hx + 35, Y(12))], fill=(50, 40, 44))
    # The mini-boss.
    # The dragon: a long serpent body winding over the Ward's roofs.
    import math
    pts = []
    for k in range(60):
        t = k / 59
        pts.append((X(222 + 60 * t), Y(13 + 3.2 * math.sin(t * math.pi * 3.0))))
    for k in range(len(pts) - 1):
        w = int(30 - 22 * k / len(pts))
        d.line([pts[k], pts[k + 1]], fill=(170, 40, 34), width=w)
        if k % 5 == 0:
            d.line([pts[k], pts[k + 1]], fill=GOLD, width=max(2, w // 3))
    hx, hy = pts[0]
    d.ellipse([hx - 34, hy - 26, hx + 34, hy + 26], fill=(150, 34, 30), outline=GOLD, width=4)
    d.line([(hx - 30, hy - 10), (hx - 70, hy - 40)], fill=GOLD, width=4)
    d.line([(hx - 30, hy + 6), (hx - 74, hy + 20)], fill=GOLD, width=4)
    bx, by = X(250), Y(13)
    d.text((bx, by - 160), "the Festival Dragon, a paper ryu gone mad (proposed)", font=font(30), fill=EMBER, anchor="mm")
    d.text((bx, by - 122), "coils round the houses, dives through the roofs", font=font(22), fill=(230, 190, 160), anchor="mm")
    # Routes.
    d.line([(X(m), Y(h)) for m, h in STREET_LINE], fill=STREET, width=12)
    d.line([(X(m), Y(h)) for m, h in ROOF_LINE], fill=ROOF, width=8)
    d.text((X(60), Y(7) - 40), "the Lantern Roofs", font=font(30), fill=(240, 160, 130))
    d.text((X(20), Y(0) + 20), "the Street", font=font(30), fill=(200, 200, 230))
    # Boats, updrafts, shortcuts.
    for m, h in BOATS:
        d.polygon([(X(m) - 30, Y(h)), (X(m) + 30, Y(h)), (X(m) + 20, Y(h) + 14), (X(m) - 20, Y(h) + 14)], fill=(120, 80, 50))
        d.ellipse([X(m) - 8, Y(h) - 30, X(m) + 8, Y(h) - 10], fill=GOLD)
    for m, h in UPDRAFTS:
        for k in range(3):
            x0 = X(m) - 20 + k * 20
            d.line([(x0, Y(h)), (x0, Y(h + 6))], fill=GREEN, width=4)
            d.polygon([(x0 - 8, Y(h + 6)), (x0 + 8, Y(h + 6)), (x0, Y(h + 6.8))], fill=GREEN)
    for (m0, h0), (m1, h1), name in SHORTCUTS:
        d.line([(X(m0), Y(h0)), (X(m1), Y(h1))], fill=GREEN, width=4)
        d.ellipse([X(m1) - 9, Y(h1) - 9, X(m1) + 9, Y(h1) + 9], fill=GREEN)
        d.text(((X(m0) + X(m1)) / 2 - 60, (Y(h0) + Y(h1)) / 2 + 26), "shortcut: " + name, font=font(22), fill=GREEN, anchor="mm")
    for m, h, name in SHRINES:
        d.rectangle([X(m) - 16, Y(h) - 50, X(m) + 16, Y(h)], fill=VERMILION)
        d.polygon([(X(m) - 26, Y(h) - 50), (X(m) + 26, Y(h) - 50), (X(m), Y(h) - 66)], fill=(60, 30, 30))
        d.text((X(m), Y(h) - 84), name, font=font(24), fill=VERMILION, anchor="mm")
    for m, h in CRANES:
        d.polygon([(X(m) - 14, Y(h) - 8), (X(m) + 16, Y(h) - 12), (X(m), Y(h) - 30)], fill=WASHI)
    for m, h, name in ENEMIES:
        d.ellipse([X(m) - 9, Y(h) - 30, X(m) + 9, Y(h) - 12], fill=(30, 20, 26), outline=(220, 220, 220), width=2)
        d.text((X(m), Y(h) - 44), name, font=font(18), fill=(220, 210, 220), anchor="mm")
    # The gate at the end, the palace above.
    gx = X(446)
    d.rectangle([gx - 14, Y(24) - 120, gx + 14, Y(24)], fill=GOLD)
    d.text((gx - 10, Y(24) - 150), "Gilded Gate", font=font(24), fill=GOLD, anchor="rm")
    # Legend.
    ly = H - 120
    items = [(STREET, "street"), (ROOF, "roofs"), (CANAL, "canals"), (GREEN, "shortcuts and rising gusts"),
             (VERMILION, "shrines"), (WASHI, "paper cranes"), (EMBER, "mini-boss")]
    x = LEFT
    for colour, label in items:
        d.rectangle([x, ly, x + 40, ly + 24], fill=colour)
        d.text((x + 52, ly + 12), label, font=font(24), fill=WASHI, anchor="lm")
        x += 120 + len(label) * 13
    d.text((W - 40, H - 50), "Lantern Market, planned: about 450 m (double the bamboo grove)", font=font(26), fill=WASHI, anchor="rm")
    img.save(OUT)
    print("wrote", OUT)


main()
