# Overnight report (2026-11-22)

Good morning. Everything on the approved plan is built, from Part A to
Part E. Each step is committed **locally** (14 commits, this report included). **Nothing is pushed**:
a push rebuilds the downloads, so that is your call. The automated check
prints ALL PASSED (about 100 checks now, up from about 60).

**Start here:** `docs/screenshots/overnight/SHEET_new_areas.png` (every new
area on one sheet), then `docs/village_map.png` (redrawn as built).

Nobody has played any of this yet. I checked it with the automated check,
screenshots and frame sheets. The feel of it (speeds, the camera, the
gusts, the sounds) is for you to judge.

## How to try it

```powershell
Godot_v4.7.2-stable_win64.exe --path .
```

Begin plays the prologue and the well as before. To jump straight to a place:

```powershell
Godot_v4.7.2-stable_win64.exe --path . -- --x=75 --y=-4
```

New start options: `--y=` (lets you start underground), `--glide` (gives
you the Crane Glide), `--map` (opens the pause map with everything
explored) and `--ending` (the Hannya falls at once, then her ending).

**Where things are (x):**

| x | What is there |
| --- | --- |
| 0 | Well Square |
| 30 to 60 | Market Street |
| 62 to 80 | The Fallen Street (hole) |
| 54 to 136 | The canals, underground (`--y=-4`) |
| 82 to 120 | The river and the bridge |
| 124 | The warehouse shrine |
| 128 to 137 | The gatehouse |
| 158 | The Shrine Steps |
| 174 | The courtyard |
| 198 | The bamboo |

## Part A: the whole village

The level now runs about 210 m from the well to the courtyard, then on
into the bamboo. The Hannya and her intro cutscene are unchanged; they just
moved east.

**1. The Fallen Street and the canals**
- **The old pit is gone.** Planks laid over the hole sag, creak and
  shudder, then snap and drop him into the canals. It is not a death.
  - Settings: `SoggyPlank.give_time` 0.55 s, `sag_depth` 0.16 m.
- **The canals** are shown as a cut-away, as if the front of the ground had
  been sliced off. There are walkways and boardwalks, shallow water that
  slows him and splashes, and sluices of river water that press him down
  (a dash goes straight through). Deep water carries him back to the last
  shrine.
  - Settings: `Ronin.wading_speed` 0.6, `Canals.sluice_press` 70.
- **A crawlspace** in the drain pipe. **New: ducked, he can now shuffle
  along** (`Ronin.crawl_speed` 2.0), and under a low ceiling he stays down
  until he is through. Before, ducking froze him in place.
- **The drain grate** in Well Square, by the well, opens with two upward
  cuts from below. It is a shortcut back down.
  - Inside the chamber under it, its front fades away so you can see him
    (a hidden place revealed). From the street it looks like solid ground.
- **The camera follows him underground** and blends in as he drops, so it
  never jumps. Measured: under 0.45 m per frame while falling through a
  plank.
  - Settings: `FollowCamera.under_height` 3.1, `under_from` -0.4,
    `under_full` -2.6.
  - The dark foreground strips sink out of the way when the camera goes
    down.
- **No rain falls inside the tunnels.** The rain now has its own small
  shader; above ground it looks exactly as before. Underground, the rain
  sound is hushed.

**2. The river and the red bridge**
- The bridge is arched, in faded red lacquer. **Its middle has fallen: jump,
  then dash.**
- **Gusts over the water carry him west.** In a full gust a jump east falls
  short, so you wait for a lull (you can see the gusts coming in the
  lanterns).
  - Settings: `RiverBridge.gust_drift` 0.45, `gap_push_gain` 1.3.
- **The river warehouse** stands on the east bank, with the second shrine
  at its door.

**3. The Gatehouse**
- The climbing course moved here. You now walk under both walls.
- **Its gate is barred from the east.** Coming up out of the canals, you
  cut the bar and the gate swings open: a shortcut back to the warehouse
  shrine. From the west, a cut only thuds.
- **The castle road** leaves the lookout: a snapped rope bridge, its ends
  swinging. It is scenery only (see "Choices you may want to change").

**4. The Shrine Steps**
- Twenty worn steps up to the courtyard, with stone lanterns and an old
  cherry tree.
- **The third shrine** is at the foot of the steps.

**5. The Rooftop Road and the ladder**
- **Drying decks on tall posts** above the roofs, each with its own life:
  drying paper, rain barrels, and **a fire-watch bell that rings and swings
  when you cut it**.
- **A burnt-out house** over the hole. What is left of its floors lets him
  drop down through it.
- Over the river, **a gap far too wide to jump: the first Crane Glide
  gate.** The decks beyond it are lit, so you can see them.
- **The kick-down ladder:** cut its cord from the deck, and it swings down.
  W at its foot climbs it, and he turns his back to us to climb.

## Part B: new enemies (folded from paper in code, no Meshy)

Each one has a tell before it hurts, follows the husk's parry and cut
rules, flashes white when hit, and is in the warm-up list.
- **Paper dog (inu-hariko)**, in the canals. Its tell: it drops low, its
  paper ruff fans up, and it growls. Then it charges. A parried charge
  staggers it. After a charge it skids to a stop and shakes itself.
- **Paper bird**, over the rooftops. It loops, beating and gliding. Its
  tell: it rears up with its wings spread and shrieks, then dives. You can
  pogo off it.
- **Lantern husk.** At a distance it lifts its lantern and throws a burning
  wad of paper. **Parry the wad and it flies back and burns the thrower.**

## Part C: systems

**9. Paper cranes.** There are 8 bundles (43 cranes), including the one in
the back room. Walking into one brushes a pale ring of ink around it, and
the cranes fly off. A small paper tag on the HUD shows the count out of
1000.

**10. Saving.** Resting at a shrine saves to `user://save.cfg`. It keeps:
the last shrine, the shrines you rested at, the cranes, the ink marks, the
shortcuts, the Hannya seen or fallen, the Smudge, the explored map, and the
glide.
- A small "Rested and saved" fades in.
- **The title shows Continue** when a save exists. Begin still starts the
  prologue.

**11. The Smudge.** When he dies, the ink he carried stays where he fell: a
pool with a wisp of ink rising from it. Cut it to take the ink back. If he
dies again first, the old one dries away.

**12. The map:** a Map page in the pause menu. It is a paper map, brushed in
ink only where he has been. Shrines show as seals (vermilion once rested
at), with where he is and the crane count.

**13. Movement feel** (settings in the "Forgiveness" group on the Ronin):
- A jump that clips a ledge's corner slips round it (`corner_nudge` 0.32).
- Coming up just short of a ledge's top, he is lifted onto it
  (`ledge_hop` 0.42).
- A sharp turn at a run is a skid, with grit or water kicked up
  (`skid_time` 0.2).
- Wet from the canals, standing still, he shakes the water off.
- The camera leads a little further while he runs
  (`FollowCamera.run_lead` 0.9).

## Part D: story

**14. After the Hannya** (16 s, 2.5D shots, hold Space to skip). This uses
the **proposed** lore ("After her" in `docs/lore.md`), which you have not
approved yet. Her intro cutscene is untouched. In order:
1. A crack is drawn across her mask, and the mask falls and breaks into
   paper.
2. Her face shows, washed blank.
3. She comes apart into pale scraps rising into the rain.
4. The lanterns relight.
5. The Rain eases for a breath.
6. The courtyard's far gate opens onto the bamboo.
7. On the shoji, a small figure climbs out of a well, then fades.

Frame sheet: `d_sheet_after_hannya.png`.

**15. The Bamboo of Folded Wind** (the first stretch, past that gate):
- Towering paper bamboo sways from its foot. Leaves blow along, and there
  are shafts of moonlight, misty ravines, and a fourth shrine.
- **The Crane Glide:** on an altar, a great paper crane rises, circles him
  and folds itself into his cloak. A card like the tutorial's appears.
  **Hold jump in the air:** paper wings unfold and he glides. The wind leans
  on the wings.
  - Settings: `Ronin.glide_fall_speed` 1.4, `glide_speed` 9,
    `glide_gravity` 0.25, `glide_wind` 0.35.
- **The glide also opens the rooftop gap over the river.** Tested: 8 tries
  out of 8 across gusts, and 0 out of 4 without the glide.

## Part E: life

- **Villagers' shadows behind the lit shoji:** pacing, kneeling at work, and
  the Paper-Maker rocking her mould in the vat. They sink out of sight as
  he passes and rise again later.
  - Two windows have storm shutters that slide shut instead.
- **The Paper-Maker is only a shadow.** I chose not to build her as a
  figure tonight. A hand-folded person in code would very likely have
  fallen short of your standard, and the shadow at her vat already reads.
- **Little paper birds** perch on the drying line, a fence, a deck rail,
  the bridge rail, the warehouse ridge and a stone lantern. They burst up
  and fly off when he comes near, and come back long after.
- **A dash near a cherry tree** stirs up the fallen petals.
- **Sounds:** canal drips, the river, the sluices and the bamboo wind are
  loops placed in the world, so they fade with distance. 22 new sounds in
  all, every one generated with ElevenLabs, measured, shaped and levelled.
  - Three takes were thrown away: a nearly silent clank, a whoosh that
    started with a pop, and a bark whose file could not be saved.
  - `audio/README.md` lists each one.

## What I checked, and how

- **The automated check**, with new checks for: the planks, the camera
  going down without a jump, wading, the sluices, the crawlspace, the
  grate, the gusts, the river, the gate from each side, the ladder, three
  or more shrines, the steps, the corner nudge, all three enemies (tells,
  parries, the pogo, the wad thrown back), cranes, saving and Continue, the
  Smudge, the ending (and skipping it), and gliding the ravine and the
  rooftop gap.
- **Screenshots of every area**, looked at closely. Fixed along the way:
  - rain falling inside the tunnels;
  - the chamber hiding the Ronin;
  - the gate too dark to read;
  - an infinite loop in the deck posts;
  - a crate at the ladder's foot;
  - the bamboo ground's front showing as a flat box;
  - the dog's collar too big;
  - the lantern husk's lantern too big;
  - the cranes too small to see;
  - scorched plaster hanging in mid-air in the burnt-out house;
  - camera limits (it now follows into the bamboo).
- **Frame sheets:** dog, bird, lantern husk, ladder, cranes, Smudge, the
  ending, glide.
- **Bugs found and fixed:**
  - Deep water right beside the warehouse shrine counted as resting there
    and healed him. Shrines now tell a respawn from walking up.
  - The automated check could overwrite a real save. It now uses its own
    file.
  - One older check (the husk's swipe) failed now and then. It is now
    watched every frame.
- **Saved games:** saving is new tonight, so no real save of yours existed.
  One test file had been written to the real save's place before I gave
  the automated check its own file; I deleted it.

## What only you can judge

- How the canals feel: the camera's depth underground, the wading speed,
  the sluices.
- Whether the gusts over the bridge are fair.
- The new enemies' looks and timing (frame sheets `b_sheet_*`).
- The ending cutscene (proposed lore).
- The Crane Glide's feel and its wings (`d_crane_glide.png`).
- Every new sound, by ear. The volumes are guesses.

## Not done, and choices you may want to change

- **The castle road** from the lookout stays out of reach even with the
  glide. I left it for a later chapter.
- **The bamboo** is only its first stretch. Akane is not there yet.
- **The ladder** is at the end of Market Street, under the deck it serves,
  not at the street's start as on the plan.
- **The river warehouse** sits west of the gatehouse, so the gate is the
  shortcut back to it.
- **Crawling while ducked** is new. It also lets him shuffle under the
  Hannya's glide.
- The web build still works, but the warm-up now takes longer (more of the
  level to show).

## Screenshots

`docs/screenshots/overnight/`:
- `SHEET_new_areas.png`: every new area on one sheet.
- `final_*`: each area on its own.
- `a*`: Part A.
- `b_sheet_*`: the new enemies.
- `c_map.png`, `c_sheet_smudge.png`: the map and the Smudge.
- `d_*`: the ending, the bamboo, the glide.
- `e_shadows_behind_shoji.png`: the shadows.
