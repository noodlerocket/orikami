"""Photographs a stretch of the world at even steps and tiles the shots 2 x 2
into sheets, for checking an area by eye before Julian sees it (see
"Checking a new area" in CLAUDE.md).

    python tools/area_sweep.py FROM_X TO_X [STEP] [HEIGHT] [OUT_DIR]

FROM_X / TO_X are world x (the market is at 2000 + its own x, the grove at
1000 + its own x). He is dropped from HEIGHT (default 14 m) at each spot and
lands on whatever is there before the picture is taken (over deep water he
falls in and is carried away: skip those spots). Pass a HEIGHT like 11 with
"high" in OUT_DIR's name to photograph a high route instead; he lands on
it. Sheets go to OUT_DIR (default docs/screenshots/sweep, which git
ignores).
Takes PARALLEL pictures at a time (separate copies of the game).
"""
import os
import subprocess
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
start = float(sys.argv[1])
end = float(sys.argv[2])
step = float(sys.argv[3]) if len(sys.argv) > 3 else 9.0
height = float(sys.argv[4]) if len(sys.argv) > 4 else 14.0
out = Path(sys.argv[5]) if len(sys.argv) > 5 else ROOT / "docs" / "screenshots" / "sweep"
out.mkdir(parents=True, exist_ok=True)

# Several copies of the game at once (Julian's idea): each takes one picture.
from concurrent.futures import ThreadPoolExecutor

PARALLEL = 4


def take(x: float) -> Path:
    path = out / f"x_{x:07.1f}.png"
    # (SWEEP_ARGS: more debug flags, e.g. "--wax" so deep ink holds him up.)
    extra = os.environ.get("SWEEP_ARGS", "").split()
    subprocess.run(["Godot_v4.7.2-stable_win64_console.exe", "--path", str(ROOT), "--"] + extra + [f"--x={x}", f"--y={height}",
                    f"--screenshot={path}"], capture_output=True, timeout=240)
    return path


spots = []
x = start
while x <= end:
    spots.append(x)
    x += step
with ThreadPoolExecutor(PARALLEL) as pool:
    shots = [p for p in pool.map(take, spots) if p.exists()]
for i in range(0, len(shots), 4):
    ims = [Image.open(p).convert("RGB") for p in shots[i:i + 4]]
    w, h = ims[0].size
    sheet = Image.new("RGB", (w * 2, h * 2))
    for j, im in enumerate(ims):
        sheet.paste(im, ((j % 2) * w, (j // 2) * h))
    sheet.save(out / f"sheet_{i // 4:02d}.png")
print(len(shots), "shots in", out)
