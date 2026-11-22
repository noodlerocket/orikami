# Overnight report (2026-11-22)

Everything here is committed locally, step by step. **Nothing is pushed**:
you decide when (a push rebuilds the downloads). The automated check prints
ALL PASSED after every commit.

Screenshots are in `docs/screenshots/overnight/`. A sheet of all of them is
at the end.

## How to try it

```powershell
Godot_v4.7.2-stable_win64.exe --path .
```

Begin plays the prologue and the well as before. To jump straight to a
place: `Godot_v4.7.2-stable_win64.exe --path . -- --x=75 --y=-4` (`--y`
is new: it lets you start underground).

## Part A: the whole village (areas 3 to 7)

The level now runs from the well (x -8) to the shrine courtyard (x 174 to
190), following the plan (`docs/village_map.png`; game x = plan metres
minus 16). The Hannya fight and its cutscene are unchanged; they simply
moved east (`Village.EAST`, now 127).

### 1. Fallen Street and the Canals (`fallen_street.gd`, `soggy_plank.gd`, `canals.gd`)
- **The old pit is gone.** The street has caved in from x 62 to 80. Planks
  laid over the hole on a timber frame **sag, creak and shudder, then snap
  and drop him into the canals** (`SoggyPlank.give_time` 0.55 s,
  `sag_depth` 0.16 m). A fallen plank splashes and floats. It is not a
  death: no health lost.
- **The canals**, seen as a cut-away (as if the front of the ground were
  sliced off): stone walls in courses, moss and slime at the waterline,
  piers and beams, lanterns hung by whoever still works there, drips from
  the vault.
  - **Shallow water** slows him (`Ronin.wading_speed` 0.6), splashes at his
    feet, and splashes big when he drops in.
  - **Sluices**: river water pours through grates in the vault and **presses
    him down** (`Canals.sluice_press` 70). A dash goes straight through.
  - **Deep water** (x 116.5 to 123): carried off, fade, back to the last
    shrine (like the pit was).
  - **Crawlspace** in the drain pipe (x 47.5 to 51.5): he must duck. **New:
    ducked, he can shuffle along** (`Ronin.crawl_speed` 2.0), and under a low
    ceiling he stays down until he is out. (Before, ducking froze him in
    place; the Hannya's glide can still be ducked the same way.)
  - **The drain pipe** runs west under Market Street to a low chamber in Well
    Square. **Two cuts upward open its grate** into the street by the well
    (rust shakes loose the first time; the second bursts it open and it
    flips over onto the paving). A shortcut back down. When he is inside the
    chamber its front fades away so you can see him (a hidden place
    revealed); from the street it looks like solid ground.
  - Ways back up: crates under the end of Market Street, the river's west
    bank (an old timber tower beside it to jump between), and a shaft at
    the east end, past the gatehouse (stone-lined, a pulley and a rope with
    a bucket).
- **The camera follows him underground** (`FollowCamera.under_zone`,
  `under_height` 3.1). It blends in as he drops (`under_from` -0.4 to
  `under_full` -2.6), so it never jumps: measured, the biggest step in one
  frame while falling through a plank is under 0.45 m (the same limit the
  courtyard camera check uses).
- The dark foreground strips **sink out of the way** when the camera goes
  under (a separate underground foreground frames the bottom there).
- **No rain falls inside the tunnels.** The rain now has its own small
  shader (`shaders/rain_streak.gdshader`); above ground it looks exactly as
  before. It still falls into the open hole and onto the river. The rain
  sound is hushed while the camera is underground.

### 2. River and Red Bridge (`river_bridge.gd`)
- The river crosses the street (x 82 to 120), flowing toward us between
  stone embankments, its depth shown at the front as a band of dark water.
- **The red bridge** (faded red lacquer, bronze post caps) is arched: you
  walk up and over it smoothly. **Its middle has fallen (x 97 to 103):
  jump, then dash.**
- **Gusts over the water carry him west** (`RiverBridge.gust_drift` 0.45,
  stronger over the gap: `gap_push_gain` 1.3). In a full gust a jump east
  falls short, so wait for a lull: you can see the gusts coming in the
  lanterns. Falling in, the river carries him back to the shrine.
- **The river warehouse** (plastered storehouse, namako tile skirt, a crest
  over the half-open door, rice bales lit inside) with **the second shrine**.

### 3. Gatehouse (`gatehouse.gd`, `Village.CLIMB_WALLS`)
- The climbing course moved here, both walls now raised on posts (you walk
  under both). The lookout is still at 11.5 m.
- **The gate under the first wall is barred from the east.** From the west a
  cut only thuds; from the east (coming up out of the canals) a cut splits
  the bar and the door swings open: a shortcut back to the warehouse
  shrine. Its west face cannot be climbed (else you could go over it).
- **The castle road** leaves the lookout: a rope bridge snapped a few metres
  out, ends swinging; beyond a wide gap the road climbs away into the hills
  with small lights. Out of reach until the Crane Glide.

### 4. Shrine Steps (`shrine_steps.gd`)
- Twenty worn granite steps up to the courtyard (underfoot a smooth ramp, so
  he never catches on an edge; each step's top sits where his feet are at
  its middle, so they never sink more than about 3 cm), stone lanterns, an
  old cherry dropping petals, the torii at the top, **the third shrine** at
  the foot.

### 5. Rooftop Road and the ladder (`rooftop_road.gd`, `ladder.gd`)
- **Drying decks on tall posts** (monohoshi) over the roofs, from the second
  gallery's roof east: drying paper, rain barrels, **a fire-watch bell that
  rings and swings when you cut it**.
- **A burnt-out house** over the Fallen Street: charred posts, the roof's
  skeleton, scorched plaster, a torn shoji still lit by a lantern someone
  left; what is left of its floors lets him drop down through it.
- Over the river the decks stand on poles in the water **until a gap far too
  wide to jump: the first Crane Glide gate**. The decks beyond are lit, so
  you can see them.
- **The kick-down ladder** at the end of Market Street: drawn up under the
  deck, a faded red tag on its cord. Cut the cord from the deck: it swings
  down, clattering. Then **W at its foot climbs** (W/S up and down, jump lets
  go). He turns his back to us to climb, hand over hand.
- My choice: the plan put the ladder at the start of Market Street; I put it
  at the end (by the storehouse), under the deck it serves.

### Also changed
- The far backdrop (hills, peaks, far village, far river) carries on east
  to the new end of the level. It was built so that **nothing already seen
  in areas 1 and 2 changed** (it uses its own random numbers).

## What I checked, and how

- **Automated check** (`tools/smoke_test.gd`), new checks: the plank holds
  then gives way; falling through is not a death; the camera follows down
  smoothly and is down with him; wading slows him; a sluice presses him
  down; standing he cannot enter the crawlspace, ducked he gets through and
  stays down under it; two upward cuts open the grate; a gust pushes him;
  the river and deep water carry him back to the shrine; the gate stays
  barred from the west and opens from the east; the ladder cannot be climbed
  before it is let down, then can, up onto the deck; three shrines; he walks
  up the Shrine Steps. One old check (the husk's unparried swipe) failed now
  and then; it is now watched every frame, like the shove check.
- **Screenshots** of every new area, looked at for careless details.

## What only you can judge
- How the canals feel to move through (the camera's depth underground, the
  sluice's strength, the wading speed).
- Whether the gusts over the bridge are fair.
- Whether the gate and its bar read clearly enough.

## Not done / known gaps (so far)
- (filled in as the night goes on)
