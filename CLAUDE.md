# ORIKAMI

A 2.5D samurai metroidvania where everything is folded paper. It is Julian's
first game. Built with Godot 4.7.2 (standard, GDScript, Compatibility
renderer); played as Windows/Mac downloads. The web page shows the title
screen, but Begin there offers the downloads instead of starting.

- **This is the real game.** It began as a copy of the finished prototype
  (git tag `prototype-v1`). The prototype is kept, unchanged, in
  `noodlerocket/orikamiprototype` (folder `C:\Users\JulianUribe\Orikami`,
  https://noodlerocket.github.io/orikamiprototype/). Do not work there.
- The web page (title screen; Begin offers the downloads): https://noodlerocket.github.io/orikami/
- Download it: https://github.com/noodlerocket/orikami/releases/latest
- Code: https://github.com/noodlerocket/orikami (public). Every push to `main`
  runs the automated check, rebuilds the web page and the downloads, and
  publishes them in about two minutes.
- Design doc (story, mechanics, style): `docs/design.md`
- The lore, in story order, and the chapter plan: `docs/lore.md` (parts
  marked "proposed" still wait for Julian). The game is built in story
  order: title, the well, the village, the Hannya, what comes after her.
- **The expanded village is built** (overnight 2026-11-22, not yet played
  by Julian): `docs/village_map.png` (as built) and `docs/overnight_report.md`
  (what was done, settings, what only he can judge).
- What it looks like: `docs/screenshots/` (frame sheets of every move)

**Before changing anything, read "Working with Julian" and "What Julian
likes".** They were learned the slow way and save rounds of rework.

## Where the game stands (2026-11-22)

Title screen (Julian's looping video), a 45 s pop-up-book prologue, the
cutscene of him leaping out of the well, a tutorial, then Kamiyama Village
at night in the rain, about 210 m from the well to the shrine courtyard in
three layers (canals, street, Rooftop Road), and the first stretch of the
Bamboo of Folded Wind after it (see "The expanded village"), with:
- the Blank Ronin: run, jump, dash, wall slide and wall jump, duck, a 4-way
  iaijutsu cut with pogo, parry (gold) and block, the charged iaijutsu draw,
  healing with ink, ink marks that build up on his paper, shredding death;
- paper husks that patrol, wind up, swipe, shove and stagger;
- a climbing course, a pit, wind, rain, sound and music;
- the first boss, **the Weeping Hannya**, with a 40-second shadow-puppet
  cutscene, a full fight, and an ending cutscene after it (proposed lore);
- the paper dog, the paper bird and the lantern husk (folded in code);
- four shrines that save; paper cranes to find; the Smudge; a map; the
  Crane Glide.
Pause, settings and controls pages share one UI style. Downloads for
Windows and Mac carry Julian's icon.

**Next:** Julian plays the overnight work and judges it (the report lists
what only he can judge). Then: the rest of the Bamboo of Folded Wind with Akane (needs Julian's
story decision); the endings (the ink marks are saved; nothing reads them
yet).

## Working with Julian

- He is a beginner at the engineering side. **Explain in plain language and
  work in small steps.** Say what changed, where the setting is, and what you
  could not check.
- His eye for visuals and feel is sharp and specific. He decides by SEEING,
  not by reading descriptions: **send screenshots or frame sheets with every
  visual change**, and check them yourself against his reference and the
  "deliberate" list below before you show him.
- He plays the game and reports problems in short messages, often several
  while you are still working, sometimes with a screenshot. Fold each one
  into the work in hand and say you have.
- He sometimes takes a request back ("make W jump" ... "no, then don't").
  When a request has a side effect he may not expect (W is also aim-up), say
  so in one line before or while doing it, so he can decide.
- When his words are ambiguous ("the shrine is covered by the walls" meant
  the torii), state your reading and go ahead; invite him to correct it.
- When he asks "would X be better?", give your honest recommendation and the
  reason, even if it is "no" (he asked whether Meshy animation would be
  better for the boss; the answer was no, and he accepted it).
- He tunes by overshooting: "too fast" is often followed by "now too slow".
  So **move about halfway, not to the other extreme**, put the number in ONE
  `@export` setting, and tell him its name and the values already rejected.
- When he cannot name the problem ("one of the sounds is a pop"), do not ask
  him to identify it. **Measure it** (see "Checking work") and show him.
- Fix the careless side effects of your own changes without being asked
  (moving the torii exposed a fence through its gateway: remove it).
- **Commit and push only when he says so.** He usually says "commit and
  push"; the push deploys the site and the downloads.
- **Meshy:** confirm the cost (credits) before every call that spends any.
  He wants Meshy for MODELS only; every animation is posed by hand in code.
- **ElevenLabs:** sounds and music are fine to generate as part of a task he
  asked for; measure every one before using it.

## What Julian likes (learned; do not relearn)

**Looks**
- Copy his reference images closely; do not reinterpret them. If a picture
  and his words disagree, follow the latest picture and say so.
- Everything must look deliberate. He spots anything careless: houses flat
  from the side, branches with no trunk, cloth swinging through its pole,
  two sheets flickering at the same depth, a sword left hanging after a cut,
  a prop sunk into the ground, a fence across a gateway, an effect that
  appears out of nowhere. Before showing work, check: is it solid from every
  angle the camera reaches, is it attached to something, does anything pass
  through anything, does anything overlap at the same depth, does every
  effect come FROM something (the ink wall rises out of a pool).
- Muted and decaying, never vibrant. The night is a dull indigo; blossom is
  faded and dusty; warm colour comes only from lanterns and windows;
  vermilion is kept for things that matter (torii, banner, lantern crests,
  the heal-ready and finishing seals, the boss title's stamp). Gold is for
  a perfect parry.
- Effects belong to the world of paper and ink. Being hurt is ink soaking
  his paper, not a blink. Ink is LIQUID: soft round drops and blots
  (`PaperMesh.soft_ink()`), never hard black rectangles. Paper scraps may be
  rectangles. Generic game effects get rejected (blinking, ripple rings).
- Lettering is Japanese and samurai-feeling: the brush font Yuji Syuku, and
  kanji where it fits (般若).
- Bosses must be frightening, not cute (the Kasa-obake umbrella was rejected
  as "not scary"). He likes supernatural and projectile moves.
- Cinematics are 2.5D (camera in front of the diorama: pushes, cranes,
  pans), scored to their music.
- **The title screen is his looping video** (a still of it is
  `docs/reference/title_reference.jpg`), not a scene rebuilt in code: a paper
  diorama copy was built and he found it "pretty bad". Claude cannot make
  video; he makes it, Claude converts and loops it (see "Title and pause").
  Menus must look like a finished game's: crisp text, soft shading, no hard
  boxes or stripes.

**Alive (Julian, 2026-11-21: the most important rule for building
the game)**
- Everything must feel real, natural and alive. Nothing is static set
  dressing if it could plausibly move or answer him: lanterns and banners
  sway, awnings and planks give under his weight, water runs and splashes,
  birds scatter, shutters close as he passes, petals stir when he dashes.
- Every new thing gets its small touches: a reaction when he touches it,
  a sound, an idle motion, an anticipation before it acts, a settle after.
- Movement gets quality-of-life care (Hollow Knight standard): coyote time
  and jump buffering already exist (`coyote_time`, `jump_buffer_time`,
  `wall_coyote`); add the rest as levels need them: ledge forgiveness
  (nudging round a corner he just clips), camera look-ahead, quick returns
  to the last shrine, clear tells before anything that hurts.
- Small animation features count as much as big ones: a turn, a skid on
  a sharp stop, a look up at a high ledge, shaking water off.

**Motion**
- Natural, never mechanical. Rejected: a fast small jitter, a slow pendulum,
  swaying stepped at 12 fps. Wind motion is smooth (every frame), wide, at a
  middling pace.
- Effects are drawn on and wiped away; they never pop in and out whole.
- The cut is short and swift, a real samurai draw: out of the scabbard and
  sweeping round from the side. Never an up-and-down chop. Hollow Knight is
  his reference for how the swoosh and the hit feel.
- What you see is what you hit: hit areas end where the visible effect ends.
- Nothing lingers after it is over (the sword goes away with the swoosh).
- Anything that hurts must show its cause (touching a husk makes it shove;
  touching the Hannya makes her swat).
- Stock animation is not good enough. Meshy's preset clips were thrown out
  ("they don't look samurai at all"); all movement is posed by hand.
- Wall slide: his BACK to the wall, feet braced behind him flat on it, one
  hand pressed back on it. (Facing the wall was rejected.)
- Wall jump: the original one (a jump off the wall on pressing Space;
  holding it only makes it higher, like any jump). Julian tried and
  rejected both "hold Space after the jump to be carried further" and
  "hold Space on the wall to charge a further jump": keep the original.
- Walking into a scene: he creeps on tiptoe with short steps (big run steps
  at a walking speed were rejected).

**Camera**
- Gentle: it must not lurch when he turns, and must never jump.
- It stays at one height (`FollowCamera.follow_height` 0; following him up
  was rejected), BUT his middle may never rise above the middle of the
  screen (`keep_below_center`): when he gets that high it rises exactly
  enough. In the climbing course (`climb_zone`) it follows him up and keeps
  him centred, no higher than `climb_max_y`.
- It follows him into the shrine courtyard like anywhere else and stops at
  its middle (`max_x`). A hard lock on the courtyard made it jump: rejected.

**Sound**
- Real-sounding, generated with ElevenLabs. The cut is ONE airy whoosh (no
  metallic draw, no second variant, no sheathing click). A hit sounds like
  scissors through paper. Cues that must be heard are bells, not sword
  clicks. Each cue its own sound (Julian: the draw's ready bell was "the
  same sound for many other things"): the draw's ready cue is now a bright
  airy shimmer (`draw_gleam`); resting at a shrine a warm singing bowl
  (`shrine_rest`); the small temple bell (`draw_ready`) is for menus and
  the tutorial's seal.
- A sound that "pops" is wrong. Check every new sound by measurement.
- When he asks for a sound to be "more X", change the sound he has a little
  (process it: pitch, an undertone, echo) before generating a new one. A
  new "monstrous" Hannya cry was "really silly and bad"; the original sob,
  slightly lowered with an undertone and an echo, is what he wanted.

**Specific settings he has judged** (do not change without being asked)
- Rain splashes: `Village.splash_strength` 0.5 (fainter and stronger both
  rejected). Wind sway: `sway_speed` 2.4 (6, 1.4 and 3 rejected).
- Husk tell: `PaperHusk.attack_windup` 0.4 s (0.55 too slow).
- Sword reach 1.9 m (1.6 m a little short).
- Falling: `fall_gravity_multiplier` 1.0, `max_fall_speed` 17 (1.25 and 22
  were too fast for paper). In water he sinks out of sight while the screen
  fades (`sink_speed`, `sink_depth`: only the puppet sinks, his body stays
  on the bed so nothing in the canals below notices).
- Deep water, the river or death: the screen fades to sumi black and he is
  back at the last shrine he rested at; no ink, no blink. (The old pit is now
  the Fallen Street's way down.)

## Checking work without eyes or ears

A single screenshot cannot show motion, and sound cannot be heard. Use these,
and always say plainly what was checked this way and what only he can judge.

- **The automated check** (`tools/smoke_test.gd`, about 100 checks): movement,
  combat, walls, pit, death, husks and the whole Hannya fight. Must print
  ALL PASSED after every change. It proves rules work, nothing about looks.
  When fixing a bug, add a check that fails without the fix (and, when in
  doubt, prove it by briefly undoing the fix).
- **Screenshots:** `--screenshot=` (see Commands), with `--x=`, `--zoom=`,
  `--face=-1`, `--hold=move_right`, `--marks=0.5`, `--cutscene`.
- **Frame sheets** (`tools/frame_sheet.gd`) photograph a sequence and tile
  it into one picture. Use one for every animation or effect change and send
  it to him. Sheets: `stances`, `cuts`, `endings`, `struck`, `hud`, `parry`,
  `draw`, `iai`, `husk`, `climb`, `wall`, `pit` (now the plank drop), `marks`,
  `sneak`, `heal`, `death`, `seal`, `cutscene`, `boss`, and since the
  expanded village `dog`, `bird`, `lantern`, `ladder`, `crawl`, `cranes`,
  `smudge`, `ending` (with `--ending`) (optionally `new`, `step`, `glide` or
  `duck` after the file name). The top of the file says which need `--zoom`.
  Crop and enlarge a tile when details matter.
- **Timing:** when two things must end together, print the times and compare.
- **Sound:** decode with ffmpeg (installed) and numpy, and look at where the
  energy is. A pop has most of its energy inside ~50 ms, mostly below
  300 Hz, and starts at full loudness. A whoosh spreads over 100 ms or more,
  is mostly above 300 Hz and starts quietly. Peaks above 0.9 clip: level
  them. `audio/README.md` has worked examples.
- **Music:** look at loudness second by second to check its shape matches the
  scene, and that a loop's two ends meet smoothly.
- **Depth fights:** search for sheets built at the same `z` that overlap.
- **New Meshy models:** `tools/model_look.gd` photographs an unrigged model
  from three sides. Rigged models draw wrongly there; check them in game.

## Design summary

- **World:** Kamiyo, a land folded from one sacred sheet. The Rain makes ink
  bleed; soaked beings lose their creases and forget who they are.
- **Hero:** the Blank Ronin, unmarked white paper, silent, in a wide kasa hat
  and a torn cloak. The Rain can't erase him (nothing to erase) but water
  weighs him down.
- **Twist:** he is the cause of the Rain, not the cure. It is the Paper
  Emperor's tears at the world being unfolded, which began when the Ronin
  was folded.
- **Pillars:** paper is identity; parry + iaijutsu combat (more Sekiro than
  Hollow Knight); the body is slowly inked by absorbed ink and that decides
  endings; light through paper (shoji, lanterns, shadow-puppet layers).
- **Endings:** Refold (heavily inked), Unfold (near blank), Thousand Cranes
  (all 1,000 cranes + two generals freed).
- **Abilities (gates):** Crane Glide, Shuriken Dash, Flat Fold, Fan Gust, Wax
  Coat, Shadow Step.
- **Palette:** washi off-white, sumi black, indigo, vermilion for what
  matters. Constants live in `scripts/paper_mesh.gd`.
- **Vertical slice goal:** Kamiyama Village + well, Bamboo of Folded Wind,
  Crane Glide, parry/slash/iaijutsu, first ink-marking, first boss (now the
  Weeping Hannya; `docs/design.md` still names the Kasa-obake).

## The references

Julian owns them. The art references are in `docs/reference/`.

- **The Ronin** is the walking figure IN the rainy-town picture: wide white
  kasa hat hiding his eyes, cowl at the neck, long robe, cloak torn into long
  tails, slim legs, katana sheathed at the hip. All white, no red. Seen
  side-on. (He tried the horned samurai from the origami sheet first and
  chose this one; that sheet is a reference for folding style only.)
  Front view for Meshy: `ronin_front.png`.
- **Kamiyama Village** is the rainy night town: muted indigo night, torn
  paper edges with a pale rim, paler and mistier layers with distance,
  peeling paper walls with ink drips, shingled roofs, warm lanterns and shoji
  windows, wet paving, dark foreground framing, a pagoda castle and a
  crumpled moon. Written up in `docs/design.md`.
- Meshy references made from those: `husk_front.png`, `hannya_front.png`,
  `hannya_mask.png`. New characters should be made from the Ronin's and the
  husk's references (image-to-image) so they share the folded-paper style.

## Controls

Keyboard (gamepad): A/D move; S duck (on the ground); Space jump (also off
walls) (A); J cut, W/S to aim it up/down (X); hold K, let go, for the
iaijutsu draw (Y); L or Shift dash (right shoulder or trigger); I parry, hold
I to block (left shoulder or trigger); hold U heal (B); Esc or P pause
(Start); M mute. W is aim-up
only. The table is in `tools/setup_input.gd`: edit it, re-run it, and update
the Controls page (`InkMenu.CONTROLS`) and the tutorial (`Tutorial.STEPS`).
There is no controls line along the bottom of the game screen any more
(Julian had it removed).

## How the game is built

### Engine rules
- **Godot 4 syntax only**, never Godot 3. GDScript, typed where practical.
- **Compatibility renderer** (`gl_compatibility`). No Forward+/Mobile-only
  features (no volumetric fog, SDFGI, real translucency).
- **Web:** single-threaded (the Web preset has thread support OFF). Use
  `CPUParticles3D`, never GPU particles.
- **All numbers that affect feel are `@export` variables**, grouped with
  `@export_group`, so Julian can tune them in the Inspector.
- **Gameplay on one plane:** `CharacterBody3D` with `axis_lock_linear_z` and
  `position.z = 0`; side-view `Camera3D` (`scripts/follow_camera.gd`).
- Physics layers: 1 world, 2 player, 3 enemies. Render layer 20 is the
  Hannya's silhouette double: every camera except her shadow camera must
  leave it out (`cull_mask &= ~Hannya.SHADOW_LAYER`).
- Player and enemies do not push each other. Enemy ATTACKS call
  `Ronin.receive_strike()` (parry/block apply); TOUCHING calls
  `take_damage()` (cannot be parried). Cuts use a shape query.
- Slash directions use y-up (`Ronin.SLASH_UP` / `SLASH_DOWN`), never
  `Vector2.UP` / `DOWN`: Godot's point the other way.
- The level is built in code, so the editor's 3D view is empty until Play.
- After adding a script with a new `class_name`, run
  `--headless --import` once, or other scripts cannot find it.

### The Ronin: model and animation
- **A Meshy model with a skeleton, posed by hand in code.**
  `models/ronin.glb` (about 12,900 triangles, 24 bones). Meshy's stock clips
  are inside the file, unused.
- `scripts/samurai_animator.gd` poses the skeleton. A pose says where the
  hips, hands and feet ARE and how the back and head bend; two-bone inverse
  kinematics bends elbows and knees to fit. All stances are plain numbers in
  the second half of that file. The husk and the Hannya use the same poser
  with their own stance files.
- `scripts/ronin_puppet.gd` picks the stance for the state, 12 poses a
  second (30 for aimed cuts and the parry). Running eases in and out; jump
  and fall follow `vertical_speed`; landing crouches; a cut, parry or guard
  lays its upper body over a run or jump.
- **Style:** low, straight-backed, hands on the sword, head level under the
  hat, sharp held poses.
- **Cloth** (`shaders/paper_cloth.gdshader`): cloak, drapes and hem swing
  toward "gravity plus air" (the shared wind minus his velocity); loose
  points are painted into vertex colours at load (`_paint_cloth`), which also
  stores each point's rest position in CUSTOM0 for the ink marks.
- `RoninPuppet.use_model` off brings back an older hand-folded puppet.
- Meshy ids (to regenerate): image `01a1fe34-82ed-7777-a106-c9426c19a9be`,
  model `01a1fe35-1fe6-7224-8761-2b947296784c`, rig
  `01a1fe3a-367b-75e8-9da1-31847b37ff68` (meshy-t2.5 smart topology, 15,000
  triangles, meshy-n1 texture, a-pose).

### The Ronin: moves
- **Cut** (J): an iaijutsu draw, 0.22 s (`cut_time`). Forward: out of the
  scabbard at his left hip and level round to his right; W: up and over; S
  in the air: down and under (pogo). The drawn katana is folded in code;
  while it is out the sculpted handle slides out of sight in the shader, so
  there is only ever one sword. The swoosh (`shaders/slash_sweep.gdshader`)
  is a strip of paper along the blade's path, drawn on and wiped away from
  the end where the cut starts. **Hit area = swoosh:** `Ronin.slash_reach` +
  half of `slash_size.x` (1.9 m) matches `RoninPuppet.sweep_reach` (1.85):
  change them together.
- **Parry** (tap I): a short draw into a guard. A blow within
  `parry_window` (0.2 s) from the side he faces is deflected: no harm,
  hit-stop, push back, a GOLD clash (`parry_color`), the enemy loses
  posture. A deflect resets the cooldown so a quick second blow can be
  caught. No cutting during the parry stance (`_parrying`).
- **Block** (hold I): after the window, the guard stays up (shuffling at
  `guard_walk`). Blows from the front do no harm, push him back and give a
  dull grey clash; `block_breaks_after` (2) blocks close together break the
  guard and stun him (`guard_break_stun`). Blocks cost the enemy nothing.
- **Iaijutsu draw** (hold K, let go): crouches straight into the iai stance
  (no cut first: holding J for it was rejected). After `draw_charge_time` it
  is READY: an inch of blade, a gleam, a flash of his paper, a bell chime,
  then his paper breathes softly while held. Let go: he dashes
  `draw_distance` through everything in his path; the cut lands
  `draw_cut_delay` after he arrives; a paper streak is wiped away with the
  sword. K held straight after a parry (`draw_combo_window`) is ready at
  once. The draw protects him with `_draw_safe` (no ink shown), not
  `_invulnerable` (which shows the struck ink).
- **Finishing cut:** a cut on a staggered enemy (`is_staggered()`): a husk
  dies at once; the Hannya loses `finish_damage`. Bigger burst, longer
  hit-stop, `finish_ink` extra ink.
- **Dash** (L or Shift): an almost flat lunge, stretched, with speed lines.
- **Walls:** touching any solid wall of the level that reaches his chest
  (`Ronin.cling_check_height`; a low crate or step does not count) while
  falling, he clings and slides (Julian: some walls did not let him; walls
  marked `no_climb`: the level's ends, the ink wall, are not)
  (`wall_slide_speed`); jump springs off; holding back toward it climbs
  even one wall.
- **Duck** (hold S on the ground): a deep crouch; his body shrinks to
  `duck_height` (0.85 m), so the Hannya's chest-height glide passes over.
- **Heal** (hold U, 3 ink for 1 health): he kneels while an ensō is painted
  round him in pale glowing ink (its progress is the charge); let go early
  and it is wiped away; on completion it closes, flashes and bursts.
- **Ink marks:** `ink_absorbed` counts every drop ever taken in (healing
  does not wash it off); at `marks_full_at` (150) he is covered in flowing
  brush strokes (shader, drawn on at `marks_draw_speed`). Saved (`SaveGame.ink_absorbed`).
- **Struck:** ink drops fly off, his paper is soaked black, the blots shrink
  away while he is invulnerable (shader `ink`).
- **Death:** he shreds into white strips and scraps (`RoninPuppet.shred`),
  the screen fades, he is revived whole at the well (`died`, `revive()`).
  Deep water and the river fade the same way and cost `pit_damage` (1).
  Dying leaves the Smudge (the ink he carried) where he fell.

### Enemies: the paper husk
- A Meshy model (`models/husk.glb`, 7,118 triangles, the Ronin's 24-bone
  skeleton) posed by hand (`scripts/husk_poses.gd`): shamble, tell (both
  arms raised high behind its head, readable whichever way it faces), swipe,
  shove, stagger. `PaperHusk.use_model` off brings back the older folded one.
  Meshy ids: image `01a1ff5b-b853-72f6-923e-c586eff0fa96`, model
  `01a1ff5c-2442-71c0-b068-3d7173aefe25`, rig
  `01a1ff5e-19d7-752f-93a2-5355c1d32a6c` (meshy-t2.5, 8,000, meshy-n1).
- Within `attack_range` in front, it winds up (`attack_windup` 0.4 s), then
  lunges and swipes; a cut interrupts the swipe. Touching it hurts and it
  shoves (`shove_time`).
- **Posture:** each parried swipe adds 1; at `max_posture` (2) it staggers
  (`stagger_time`), folded over, a vermilion seal stamped on its body. One
  point drains per `posture_recover_time` without a parry. 3 health.

### The Weeping Hannya (first boss)
- Chosen by Julian over the Kasa-obake. Meshy models, posed by hand
  (`hannya_poses.gd`): `models/hannya.glb` (rigged, 2.6 m; image
  `01a1ff82-5cb1-74f2-af57-33d8f905d86c`, model
  `01a1ff83-2572-77c6-8489-0b0c8a48860d`, rig
  `01a1ff85-a583-7695-bd2f-b4e629bcbd0b`) and `models/hannya_mask.glb` (the
  close-up mask, meshy-7.1; image `01a1ff82-6a99-7641-94aa-210e4a826f5b`,
  model `01a1ff83-2d64-72ec-92b6-ff8ad6928c7a`). The mask's 4K texture is
  imported at 1024 (`hannya_mask_0.jpg.import`): identical in the close-up,
  0.7 MB instead of 17 MB.
- **The shoji screen** (`hannya_stage.gd`, `shaders/shoji_screen.gdshader`):
  a hidden camera at a lamp low behind her films her silhouette double and
  the screen prints it, softened, as her shadow (a tall profile: she kneels
  side-on near the lamp). The screen also bleeds ink from her shape, opens
  slashes and tears with pale torn rims. The shadow camera rests while the
  shrine is out of view (`set_shadow_active`).
- **The cutscene** (`hannya_cutscene.gd`, 40 s, scored to
  `music_hannya_intro.mp3`; the paper rips on the music's eruption at 28 s):
  he creeps in, the lanterns die, her shadow weeps, turns, bleeds ink, the
  paper rips, the mask comes through, she towers, and the title is painted
  (`hannya_title.gd`: 般若 and her name in brush lettering, a vermilion
  stamp). Julian finds the mask close-up at 30 s odd ("just a levitating
  head"), but rejected the first fix: her face pressed out through the
  paper as a relief, then leaning through the tear ("so bad"), then a wide
  shot of her stepping through, then hair and a robe under the mask. All
  undone: he wants the ORIGINAL cutscene left alone. Do not change it.
  It plays the first time he enters the courtyard; hold Space to
  skip; `--cutscene` plays it at once.
- **The fight** (`hannya_boss.gd`, 30 health, 6 posture):
  - sleeve slash, sometimes double, leaving a dark ink arc (parry);
  - glide at chest height (`glide_band` 1.0 to 2.6 m): her tell is rising
    with sleeves spread like wings, ink wisps, a wail and a pale streak
    along her path (duck or parry; parrying costs her double posture);
  - ink rain (`ink_drop.gd`): stains spread where tears will land (dodge);
  - ink blades (`ink_blade.gd`): three pale crescents in a rhythm (parry);
  - ink step: she sinks into an ink pool (`ink_pool.gd`) and rises out of
    another behind him, already swinging;
  - weeping masks (`phantom_mask.gd`) from half health: circle, then dive.
  At half health her tells and rests shrink (`enraged_pace`).
- Walking into her hurts and she swats (`contact_damage`, `swat_time`);
  that touch is off while she glides, so ducking under her works.
- While she fights, the courtyard entrance is sealed by a wall of ink that
  rises out of a spreading pool, droplets spurting (`Village.set_arena_sealed`,
  `shaders/ink_wall.gdshader`). Only dying resets her: she then waits at the
  courtyard's right end (`waiting_gap`); coming back restarts the fight
  without the cutscene. Her health bar: `boss_bar.gd`. Fight music
  `music_hannya_fight.ogg` (seamless loop).
- **Lettering:** the brush font Yuji Syuku lives in `art_source/` (Godot
  ignores it; never shipped, 8 MB). `tools/render_lettering.gd` renders the
  lines needed into `textures/`. New lettering: add a line there, re-run it.

### The world
- **Kirigami diorama:** flat paper cut-outs at real depths, so layers slide
  past each other as you walk. Depth guide (Z): +4 dark foreground, +1.5
  front edge of the street, 0 gameplay, -4.3 house walls, -9 to -17 back of
  the village, -24 to -48 hills and peaks, -53 sky.
- **Paper helpers** (`PaperMesh`): `tear()` roughens an outline,
  `torn_sheet()` adds the pale torn rim, `loft()` folds tubes, `fade_quad()`
  + `build_veil()` make gradients and mist, `soft_ink()` is the material for
  every ink particle. Every piece shares a crumple texture made in code. Use
  these, never plain straight-edged shapes.
- **Depth recipe** (`backdrop.gd`): each layer further back is paler and
  bluer, with mist at its foot, and is two sheets (lighter top edge, darker
  ridge). Backdrop sheets are unshaded with fog off.
- **No two flat sheets may share a depth where they overlap** (they flicker).
- **The level, left to right** (`village.gd`): the well (start), houses,
  platforms, the pit (`PIT_LEFT`/`PIT_RIGHT`/`PIT_BACK`: a hole in the
  street with crumbled edges; lantern reflections trimmed off it), a shoji
  panel (x 27.4, clear of the step up at x 30), the raised street, the
  climbing course (`CLIMB_WALLS`: a gatehouse wall you walk under and a tall
  wall with a lookout ledge at 11.5 m; solid up to the roof ridge,
  `CLIMB_ROOF`), the torii (`TORII_X` 46.0, clear of the tall wall), then the
  shrine courtyard (`ARENA`, x 47 to 63.5) with the Hannya's shrine hall,
  stone lanterns (`arena_lanterns`) and a cherry. Husks: `enemy_positions`.
- **Houses are solid** (side walls, gable ends, back wall, rear roof slope).
  **Cherry trees** are rooted (`Scenery.sakura_tree`); the foreground one
  keeps its limbs clear of play.
- **Light:** lanterns are real `OmniLight3D`s plus glowing paper and a halo.
  About 8 lights may touch one mesh (Compatibility limit): build long things
  (paving) in short lengths. Wet-street reflections are faked warm smears
  (`Village.wet_shine`). Colour grading: `color_saturation` /
  `color_contrast` keep the night muted; tune there first.
- **Wind** (`scripts/wind.gd`): one breeze plus gusts rolling along the
  street; everything asks it how hard it blows where it stands. Hanging and
  standing scenery is marked with `Scenery.windswept()` and swung every
  frame in two overlapping rhythms. Anything on a pole hangs on its downwind
  (left) side so it never swings through its support. Rain, petals, clouds,
  the wind sound and the cloak all follow it.

### Light and wet (Julian: "make the lighting more realistic")
- Lantern and window light falls off steeply (`Village.light_falloff`, 2.0;
  was 1.3, "flat"), stronger (`lantern_energy` 5.2), less flat fill
  (`ambient_energy` 0.45, was 0.55). Hung lanterns cast real shadows
  (`lantern_shadows`): measured 52 fps before, 41-47 fps after on this
  computer; switch off if the browser is too slow.
- Every glow (`Scenery.halo`, `_spot_material`) fades softly near surfaces
  (`proximity_fade`, 0.25 m): a glow cut off by a post looked like a flat
  painted patch on the wood (Julian's screenshot).
- Roof tiles are glossy, as if wet (`Scenery.tiled_roof`). The street was
  made wetter too (glossier stones, wavering reflections, sheen, puddles,
  ripples, a landing splash) and Julian had it all undone: "I liked the
  ground before better". Leave the ground as it is.

### The expanded village (built overnight 2026-11-22; `docs/village_map.png` as built)
Game x = plan metres - 16. Left to right: Well Square and Market Street
(-17 to 62), the Fallen Street (62 to 80, `Village.FALL_LEFT/RIGHT`), the
river (82 to 120, `Village.RIVER`), the Gatehouse (`CLIMB_WALLS` at 128.5
and 132.2), the Shrine Steps (158 to 171, `Village.STEPS`), the courtyard
(`ARENA` 174 to 190.5; `EAST` is 127), the bamboo (191 to 258). Each area
has its own script, built from `Village._ready`:
- `fallen_street.gd` + `soggy_plank.gd`: planks over the hole sag, creak and
  snap a moment after he lands (`give_time` 0.55): the way DOWN, not a death.
- `canals.gd`: the cut-away underworld. The drain pipe (`Village.PIPE`) with a
  crawlspace (`Canals.CRAWL`; ducked he crawls, `Ronin.crawl_speed`) and a
  chamber whose grate into Well Square opens with two upward cuts
  (`open_grate`); the canal hall (`Canals.WALKWAYS`, shallow water slows him:
  `Ronin.wading_speed`; `SLUICES` press him down: `sluice_press`; `DEEP`
  water carries him back to the last shrine: `Ronin.fall_in()`); the shaft
  out east (`Village.SHAFT`). The chamber's front fades (material alpha)
  only while he is inside it.
- Camera underground: `FollowCamera.under_zone`/`under_height`, blended in by
  his depth (`under_from` to `under_full`), so it never jumps. The dark
  foreground (`Village._near`) sinks away as the camera goes down; rain is
  cut off at the street while it is under (`shaders/rain_streak.gdshader`,
  identical above ground); the rain sound is hushed.
- `river_bridge.gd`: the river, the arched red bridge (smooth convex pieces
  along `deck_at`), its fallen middle (`GAP` 97 to 103: jump + dash), the river
  warehouse with shrine 2. (Gusts pushing him west over the water were
  removed: Julian, "slides slowly to the left". Do not bring back.)
- `gatehouse.gd`: the way under the first wall is always open, its door
  swung back (Julian: a barred gate there stopped him; he wants to run
  straight through). (The castle road from the lookout was removed: Julian.)
- `shrine_steps.gd`: 20 steps (a smooth ramp underfoot; step tops at the
  ramp's middle), stone lanterns (`_build_stone_lantern(at, false)`: NOT the
  courtyard's, which the cutscene snuffs), a cherry, shrine 3 at the foot.
- `rooftop_road.gd` + `ladder.gd`: drying decks on posts (`POST_Z`: at the
  BACK only, each standing on what is really under it, `_foot`; Julian:
  posts ran down through stalls, roofs and the bridge rails) (bell, barrels,
  drying paper), the burnt-out house over the hole, the Crane Glide gap
  (`GLIDE_GAP` 97.6 to 107) over the river; the ladder at the end of Market
  Street is lowered by cutting its cord from the deck, then climbed (he
  turns his back to us: `SamuraiAnimator.climb`).
- `bamboo_grove.gd`: its OWN place (Julian: not a continuation of the
  street). Built far off at `BambooGrove.SHIFT` (1000 m) with its own sky,
  moon and far bamboo; walking through the courtyard's open far gate fades
  to black and puts him at the grove's west end (`Main._travel`,
  `travel_fade`), and back through the grove's gate home. Camera limits
  per place: `Main._set_camera_limits`. **In DAYLIGHT, copied from Julian's
  bamboo picture** (`Village.set_daylight`, settings in its "Daylight"
  group; switched while the screen is black; no rain there): thick
  segmented stems in fresh greens with leaf sprays from the nodes, the
  forest floor reaching back so every stem stands on ground (`stem_feet`,
  checked: none over a ravine), framing stems in front rising from below
  the screen; cliff faces of faceted rock with torn red washi patches
  printed with sakura and seigaiha, a shaggy moss lip; a rope bridge over
  the second ravine, a snapped one over the first (the glide gap); a warm
  sky, red paper sun, misty mountains with a pagoda, far cliffs with a torii
  and waterfalls; a lantern, a crane banner, petals, sun shafts. Its colours
  are the `const`s at the top of the script. Its west end is the path running off
  into deep mist with a stone lantern (`_build_mist_way`; a copy of the
  courtyard's gate there was "a weird scene arrangement"). Shrine 4, the altar where he learns the
  Crane Glide (`Ronin.has_glide`, `glide_*` settings; paper wings on the
  puppet, `_build_wings`).
- Life: `villager_shadow.gd` (shadows behind lit shoji that sink away as he
  passes; at `Village.SHUTTERS` a bamboo blind unrolls instead: a sliding
  shutter "looked glitched"), `perched_birds.gd`
  (`Village.PERCHES`), petals stirred by a dash (`Ronin.dashed`), drips,
  water loops placed with `Sound.place_loop`.
- Enemies (`Village.dog_positions`, `bird_roosts`, `lantern_husk_positions`):
  `paper_critter.gd` (shared: health, flash overlay, posture, seal),
  `paper_dog.gd`, `paper_bird.gd` (pogo-able), `lantern_husk.gd` +
  `burning_paper.gd` (a parried wad flies back at the thrower).
- Systems: `save_game.gd` (user://save.cfg; the automated check and any
  debug-flag run use their own files), Continue on the title, `crane_bundle.gd`
  (`Village.CRANE_BUNDLES` + the back room; HUD tag), `smudge.gd` (death
  leaves his ink; cut it back), the Map page in the pause menu, corner
  nudge / ledge hop / skid / shaking off water (`Ronin` "Forgiveness"),
  `FollowCamera.run_lead`, `hannya_ending.gd` (after the fight; proposed lore).

The original plan, kept for reference:
Drawn by `tools/village_map.py` (Python + Pillow: edit its lists, re-run).
Julian has seen this plan; build it area by area, with screenshots and
frame sheets as each one comes together. About 230 m (today: 75 m), on
three layers joined in several places, so there is more than one way
through:
- **Areas, left to right:** 1 Well Square (the start, the Paper-Maker's
  workshop and the first shrine); 2 Market Street (stalls with paper
  awnings that sag and bounce, lantern strings to pogo up to the roofs,
  swinging shop signs, a shoji wall to cut through to a back room);
  3 Fallen Street (the street has fallen into the canals: soggy planks that
  give way; the old pit becomes this way DOWN instead of a death); 4 River
  and Red Bridge (the bridge's middle has fallen: jump and dash; gusts over
  the water); 5 Gatehouse (today's climbing course, moved here; a shrine in
  the river warehouse); 6 Shrine Steps (stone lanterns, the shrine before
  the boss); 7 Shrine Courtyard (the Hannya).
- **The Rooftop Road** over areas 2 to 4: ridges, a ruined house to drop
  through, paper birds; a gap too wide to jump is the first Crane Glide
  gate.
- **The Canals** under areas 3 and 4: walkways over water, sluices of
  falling water that press him down (water weighs him down, from the
  lore), paper dogs, a crawlspace, deep water (falling in = back to the
  last shrine), a climb out by the gatehouse; a drain pipe back west whose
  grate opens into Well Square (a shortcut).
- **Shortcuts, opened from the far side:** a ladder kicked down from the
  roofs into Market Street; the drain grate; the gatehouse gate unbarred.
- **Opens later:** the rooftop gap and the castle road from the lookout
  (Crane Glide); the road to the Bamboo past the courtyard (after the
  Hannya).
- **Shrines** (save, heal, return here when you fall): the Paper-Maker's
  door, the river warehouse, the foot of the shrine steps.
- **Paper cranes** hidden in bundles (rooftops, back rooms, canals, the
  lookout): the first of the 1,000 for the true ending.
- **New enemies:** the paper dog (inu-hariko, fast and low), paper birds
  (also something to pogo off), the lantern husk (throws burning paper).
- No browser speed limit any more (the game is not played on the web), but
  keep the desktop smooth: build long things in short lengths (the
  8-lights-per-mesh limit still applies).

**Areas 1 and 2 (2026-11-21):**
- **The Paper-Maker** (`paper_maker.gd`): a Meshy model
  (`models/papermaker.glb`, 1.38 m; picture `docs/reference/papermaker_front.png`
  made image-to-image from the Ronin's and husk's references; ids in the
  script), posed by hand with `SamuraiAnimator` (stances at the bottom of
  her script). She stands at her vat rocking the mould and lifting it to
  drain; when he comes near (`notice_distance`) she straightens, turns her
  head to him and nods. Her window's shadow is someone else now (kneeling).
  The first time he comes to her (after the tutorial), she holds up a sheet
  and tells him in pictures (`paper_maker_tale.gd`, no words, about 16 s,
  hold Space to skip, `SaveGame.papermaker_told`): the castle shut, weeping;
  the village bleeding ink, a husk; him, blank, in a vermilion ensō. Only in
  a real game (`PaperMakerTale.allowed`; the check and debug starts set
  `force`). Sheets: `papermaker`, `tale`.
- **Well Square:** the Paper-Maker's workshop (`paper_maker_yard.gd`):
  sheets drying on two lines (each sways on its own), the vat with its
  mould frame, a drying board, paper bundles; the first **RestShrine**
  (`rest_shrine.gd`) at her door.
- **RestShrine:** a small hokora with faded vermilion posts and paper
  streamers. Passing it is enough (`rest_time` 0; standing a moment was
  rejected): he rests (health full, the candle
  lights with a flare, the streamers flutter, `shrine_rest` sound) and falls
  and deaths now bring him back there (`Ronin.set_checkpoint`). Being put
  there by a respawn is not resting (else a fall would cost nothing).
- **Market Street** (`market_street.gd`; edit its lists to move things):
  - **MarketStall** (`market_stall.gd`): each has a trade, `kind`:
    "produce" (baskets, radishes, dried persimmons on strings), "noodles"
    (pot, bowls, a lantern, STEAM), "fish" (tray, tub, dried fish swinging).
    The awning is SOLID (Julian: jumping up through it from below was
    no-clipping); awnings sit at 2.2 to 2.3 m, under his 2.5 m jump, so he
    hops onto them from the side. Landing sags them; landing from high
    (falling over `bounce_from` 7 m/s) throws him up (`bounce_speed` 16.5).
    The front fringe is separate tassels, each swaying on its own (one strip
    turning as a whole see-sawed: Julian).
  - **Galleries** (`_build_gallery`): an upper storey on posts you walk
    under, dark boards, a band of lit shoji (one slid open, one torn), a
    balcony rail, a walkable tiled roof, climbable walls. Each has its own
    balcony: "laundry" (a real kimono shape: hung through its sleeves on a
    bamboo pole, seigaiha waves, overlap, collar; a towel) or "garden"
    (potted plants, a half-lowered bamboo blind). A plain cloth there was
    "way too basic".
  - **LanternString** (`lantern_string.gd`): lanterns between the two
    gallery roofs (tied to short posts on the roofs; tall poles went through
    the roofs). Cut down onto them in the air to pogo across.
  - **HangingSign** (`hanging_sign.gd`): from the shops' porch beams (posts
    in the street crossed windows), each with its own mark (`mark`: ring,
    character, sake gourd); swings when cut or brushed.
  - **SecretRoom** (`secret_room.gd`): a storehouse (namako tiled base,
    plaster, small barred window). A lit shoji door at the front's left
    end: two cuts tear it open; inside, the front wall fades; a lantern and
    a bundle of cranes on the shelf (collecting them is not built yet).
    The beams stop at the door's frame (a beam across it was a fault).
- **PropTarget** (`prop_target.gd`): anything in the scenery the sword can
  strike (lanterns, signs, the shoji door). It is on the enemies' layer so
  the cut finds it; the cut bounces and recoils as usual but gives NO ink
  (`Ronin._on_slash_connected(…, inky)`).
- **Houses have personality** (`Scenery.house` extras, each put at its own
  spot along the front, never two alike): "sudare", "pots", "umbrella",
  "firewood", "shutters", "buckets", and "noren_indigo" (an indigo shop
  curtain with a snake's-eye crest; 茶 on every shop was too repetitive).
  Torn-paper holes are never cut over a window any more.
- **Roof back slopes** (`Scenery.tiled_roof`): their tiles used to face
  DOWN, so a low roof seen from above showed a bare blue board. Fixed for
  every roof.
- Not built yet in Market Street: the ladder shortcut from the roofs, the
  paper birds, collecting cranes.

### Skipping cutscenes
- `skip_prompt.gd` (`SkipPrompt`, drawn by `UiStyle.skip_prompt`) in all
  three cutscenes: top right (clear of the lines at the bottom), a key cap
  and "Hold to skip", a slim rounded bar under it filling from the left
  while Space (A) is held, vermilion when full. Rejected: a thin ring
  ("bugged and basic"), a tapering brush stroke ("a red 2d object being
  distorted and stretched").

### Hit flashes (a Godot pitfall)
- The husk and the Hannya flash white when hit by laying a white overlay
  over them (`material_overlay`, `PaperHusk.flash_overlay()`), NOT by
  switching on emission: on these skinned Meshy models, emission made every
  soft glow in the sky (the moon's halo) draw as a white square while the
  flash lasted (Julian: "the sky flashes white when I slash a husk").
  Measured with a probe: the sky brightened 0.07-0.08 on hits before, 0.01
  (the rain's own flicker) after.

### The tutorial
- `tutorial.gd` (`Tutorial`), after the climb out of the well: one card at
  a time at the top (move, jump, dash, cut, parry, block, iaijutsu draw,
  duck, heal), key caps or gamepad buttons; each waits until he has done it,
  then a vermilion 了 seal is stamped and the next comes. It starts him one
  health point down with ink for one heal, so the last lesson is a real heal
  (Julian asked). The game carries
  on underneath. Backspace (Select) skips the rest. `--tutorial` starts it.

### Sound and music
- `scripts/sound.gd` (the `Sound` node): `Sound.play(self, &"name")` from
  anywhere; `Sound.duck_music()` / `duck_rain()` for cutscenes and the
  fight. Rain (two layers), wind and the village music loop all the time.
  M mutes. Seamless loops are OGG (MP3 leaves a gap).
- `audio/README.md` lists every file, when it plays, the words used to
  generate it, and how it was measured and levelled.
- Generating with ElevenLabs: make `audio/raw/` first (the tool will not),
  generate into it, measure, level, rename, then delete the folder. Files are
  named after the first five letters of the prompt, so start each prompt with
  a different word. Lengths 0.5 to 5 s. Music: music_v2; a section-by-section
  composition plan often comes back as one long swell, while a single prompt
  describing the timeline section by section worked. Cost cannot be read.

### The health display
- `scripts/hud.gd` draws it in code: a torn paper strip, one ink splat per
  health point (dried ring when lost; bursts when hurt, blooms when healed;
  the last one throbs), a brush stroke for ink with a tick per heal, a red
  seal when a heal is ready.

### Title and pause
- `scenes/title.tscn` is the main scene. `title_screen.gd` plays Julian's
  looping video `video/title_loop.ogv` (1280x720, 30 fps, 5.9 s, 3.9 MB),
  with the village music and rain. It loops with a plain cut: his clip is
  nearly a loop already (at the cut only the scarf, a few petals and the
  grass jump). A 1.2 s blend at the seam was tried; he found the "morph"
  weird. A still from it (`textures/title_backdrop.jpg`)
  stands in if the video is missing. **The ffmpeg on this computer writes
  broken Theora files** (coloured blocks); make .ogv with Godot's Movie
  Maker instead: `tools/make_title_video.gd` has the steps.
- **The UI** (Julian: the first menus "do not look good"; this is the
  overhaul): real text in the brush font, cut down to the characters used
  (`fonts/yuji_syuku_ui.ttf`, 188 KB, OFL). A new kanji in the UI must be
  added to that cut (fonttools: `subset.Subsetter` on
  `art_source/fonts/YujiSyuku-Regular.ttf`). `ui_style.gd` (`UiStyle`):
  colours, text with a soft shadow, smooth shading textures, the chosen-line
  wash, key caps and gamepad buttons, prompts that switch to gamepad buttons
  when a pad is used, and the display settings.
- `ink_menu.gd` (`InkMenu`): pages of lines (button, link to a page,
  slider, on/off, back). The chosen line: a feathered ink wash wiped on, a
  vermilion diamond, slides right. Controls page: a dark panel with key caps.
- `title_menu.gd` (`TitleMenu`): soft shading top, bottom and bottom-left;
  the logo (a vermilion seal with 折神 beside ORIKAMI, "THE FOLDED GOD"
  under); "Press any key" first (also lets a browser start sound); then
  Begin / Settings / Controls / Quit on the dark rock; prompts bottom right.
- `pause_menu.gd` (`PauseMenu`, built by `Main._build_pause`): Esc, P or
  Start. Wash, ink down the left, 休 seal and RESTING; Resume / Settings /
  Controls / Return to the title (asks first). Not during the loading cover
  or the cutscene. The `Sound` node keeps running while paused.
- Settings (both menus): Music and Sounds volume, Full screen (not in the
  browser). Saved in `user://settings.cfg` (`Sound.music_level` /
  `sounds_level`, `UiStyle.fullscreen`). Music made elsewhere follows the
  volume through `Sound.follow_level()`.
- Any command-line option skips the title and starts the game, so the usual
  screenshot commands still work; `--title` photographs the title, with
  `--menu` (skip "Press any key") or `--page=settings` / `--page=controls`.

### The prologue
- `scenes/prologue.tscn` / `prologue.gd` (`Prologue`): Begin on the title
  plays it; at its end the game starts at the bottom of the well. 45 s,
  scored to `audio/music_prologue.mp3` (its eruption at 25 s is the
  thunder); the five brushed lines are in `docs/lore.md`.
- **A pop-up book, in 3D, shot in 2.5D.** Fallen pieces lie flat on the
  page (88 degrees); solid ones (houses) are crushed flat instead of tipped,
  so nothing hangs in the air; the torii falls with its hill; the Emperor
  stands on a stone terrace and unfolds UP out of it (a `rise` pop-up: he
  seemed to appear from nowhere). The sun does not bleed (red streaks down
  the sky were removed at Julian's request); it only sinks. One blank sheet stands in
  candlelight (creases draw across it); the world folds up off the page in
  front of it: mountains, hills, river, village with lanterns, cherry trees,
  paper-doll villagers, cranes that fly, the castle, the red dusk sun, the
  Emperor. The Rain: lightning, cold light, colour drains, everything soaks
  (`WET`), the sun sinks, cranes fall, the Emperor bows,
  the mother and child's prints wash off and they fold down, then every
  pop-up goes limp. The camera cranes down past the page's front edge into
  a cut-away of the ground: the well's shaft, a small white figure at the
  bottom. The game opens on the same view.
- **Julian: keep it 2.5D** ("hard to make 3D look professional"). Every
  shot is from in front: pushes, pans, cranes; never from above or round
  behind. A shadow-puppet version came first and looked too crude; a
  top-down version was dropped for this rule.
- Everything is drawn from `time` alone (`_apply`): pop-ups (`_pop`, a
  spring up, a limp fall), soaking (`_soak`), lights, cranes, pools, the
  sun's tears. `--prologue` plays it; `--prologue-sheet=path` photographs it
  (`--prologue-moments=3,8.5,...` picks the moments); `--prologue-at=T`
  starts it at T. Each pop-up plays `paper_fold`. Hold Space (A) to skip.

### The well (the start of the game)
- After the prologue (`Prologue.into_well`, or `--well`), `well_cutscene.gd`
  (`WellCutscene`, about 7 s), seen from the street in the rain, close and
  low: the screen comes up from black on the well; he springs up out of its
  dark mouth in one quick jump FORWARD (toward us), clear over the front of
  the rim and under its roof, and lands on the street in front of it
  (`LAND_X`); then the camera arcs up and settles exactly where the game
  camera will be, and hands over. Posed by hand (physics off). Hold Space
  to skip. `--well-sheet=path` photographs it.
- Rejected by Julian, do not bring back: a playable climb up a cut-away
  shaft ("show it from the outside"); crouching on the well's mouth
  ("weird"); jumping out sideways (it looked like he went through the rim).
- The well stands in the BACKGROUND (`Village.WELL_Z`, behind the gameplay
  plane), nothing to stand on, its roof directly over it (no rain inside).
  Its mouth is open with depth (`Scenery.well`): a rim, an inner stone wall
  darkening downward, black water with a faint glint (Julian: not "just a
  black colour").
- The default clear colour is black (`project.godot`), so changing scenes
  (Begin to the prologue) shows black, not a grey flash.

### Builds, speed and downloads
- **No game in the browser** (Julian, 2026-11-21): the web build still
  opens on the title screen ("Press any key", the menu), but Begin there
  opens a Download page (`TitleMenu.download_instead`: Windows / Mac, the
  visitor's own computer first, Back; a line saying why, and after a pick
  "Your download has started" with the next step). The download starts in
  the same tab (`JavaScriptBridge`). `--title --download --page=download`
  shows it natively (`--downloaded` for the after-pick words). A separate
  HTML download page was tried first and dropped for this.
- **The icon** is Julian's picture (the Ronin before a red sun, 折神;
  he made it from a design of a brushed ensō), with its white surround cut
  away: `icon.png` (1024, the window, the Mac app and the web page),
  `icon.ico` (16 to 256, the Windows .exe; needs the Windows preset's
  `application/modify_resources` on). Sheet:
  `docs/screenshots/icon.png`.
- **Web freezes** (from when the game ran in the browser):** the browser prepares each new kind of material the first
  time it is drawn (up to 3.4 s). `Main._warm_up()` (web only; `--warmup`
  forces it natively) shows the whole level and every effect once behind a
  sumi cover with a pale ensō (`loading_cover.gd`). **Every new effect,
  material or enemy must be added to that list**, or it will hitch the first
  time it appears in the browser. Result on the live site: 15 slow frames
  and a 3.4 s freeze became 1 slow frame (51 ms).
- **Downloads:** export presets "Windows" (one .exe) and "Mac" (universal
  .app, ad-hoc signed, not notarized; needs the ETC2/ASTC texture setting,
  which is on). The workflow (`.github/workflows/deploy.yml`) runs the
  automated check, exports web, Windows and Mac (with `build/.gdignore`, so
  the builds are not packed into each other), replaces the GitHub Release
  "latest" with `Orikami-Windows.zip` and `Orikami-Mac.zip`, and deploys the
  page. Unsigned: Windows says "protected your PC" (More
  info, Run anyway); a Mac needs right-click, Open the first time.
- Godot's export templates are NOT installed on this computer (only on
  GitHub's builder), so web/desktop builds can only be tested after a push.
- The workflow's actions are on their Node 24 versions (checkout v7,
  configure-pages v6, upload-pages-artifact v5, deploy-pages v5).

## Pitfalls learned overnight (2026-11-22)
- `GeometryInstance3D.transparency` does nothing in the Compatibility
  renderer: fade a mesh through its material's alpha (and set it opaque
  again at 0).
- Measuring sound: `ffmpeg -ac 1` sums stereo channels and overstates the
  peak; decode the channels as they are for the peak, mono for the spectrum.
- ElevenLabs names files after the prompt's first five letters: a colon
  there ("Bark:") cannot be saved on Windows.
- Python edits sent through a Bash heredoc can lose tabs: write the .py
  file with the Write tool and assert every replacement.
- A shrine must tell a respawn from a walk-up (`Ronin.respawns`): deep water
  next to the warehouse shrine was healing him.

## Layout

| Path | What it is |
| --- | --- |
| `scenes/main.tscn` | The game scene: Village, Ronin, Camera, Rain, Sound, Overlay (grain + HUD) |
| `scenes/ronin.tscn`, `paper_husk.tscn` | The player (movement numbers on the root, looks on `Puppet`) and the husk |
| `scripts/main.gd` | Wiring: camera, HUD, pit and death fades, the cutscene and fight triggers, the web warm-up, debug flags |
| `scripts/ronin.gd` | Player rules: moves, parry, block, draw, walls, duck, heal, damage, death |
| `scripts/ronin_puppet.gd` | Player looks: stances, swoosh, clash, draw streak, ensō, cloth, ink, shred |
| `scripts/samurai_animator.gd` | Poses any of the Meshy skeletons; holds the Ronin's stances |
| `scripts/paper_husk.gd`, `husk_poses.gd` | The husk's rules and stances |
| `scripts/hannya.gd`, `hannya_poses.gd` | The Hannya puppet (and silhouette double) and her stances |
| `scripts/hannya_stage.gd` | Her shrine hall, shoji screen and shadow camera |
| `scripts/hannya_cutscene.gd`, `hannya_title.gd` | The cutscene and its painted title |
| `scripts/hannya_boss.gd`, `boss_bar.gd` | The fight and her health bar |
| `scripts/ink_drop.gd`, `ink_blade.gd`, `ink_pool.gd`, `phantom_mask.gd` | Her ink tears, blades, pools and masks |
| `scripts/village.gd` | The level layout: ground, pit, houses, lanterns, props, climbing course, courtyard, ink wall, wind sway, rain splashes |
| `scripts/scenery.gd` | The prop kit: houses, roofs, lanterns, banner, well, torii, fences, trees |
| `scripts/backdrop.gd` | Everything far away: sky, moon, clouds, peaks, hills, castle, far village, river, mist |
| `scripts/paper_mesh.gd` | Folds paper shapes in code; palette; `soft_ink()` |
| `scripts/follow_camera.gd` | The game camera |
| `scripts/wind.gd`, `sound.gd`, `hud.gd`, `rain.gd`, `confetti.gd`, `loading_cover.gd` | Wind, sound, health display, rain, paper bursts, the web loading cover |
| `shaders/` | `paper_cloth` (the Ronin's paper), `slash_sweep` (every drawn-on strip), `shoji_screen`, `ink_wall`, `paper_grain` (full-screen grain) |
| `models/` | Meshy models: `ronin`, `husk`, `hannya`, `hannya_mask` (`.glb`, textures beside them) |
| `audio/` | Sounds and music, with `README.md` |
| `textures/` | Brush lettering rendered from the font |
| `art_source/` | Source art Godot ignores (the brush font and its licence) |
| `docs/design.md`, `docs/reference/`, `docs/screenshots/` | Design doc, art references, frame sheets |
| `scripts/canals.gd`, `fallen_street.gd`, `soggy_plank.gd`, `river_bridge.gd`, `gatehouse.gd`, `shrine_steps.gd`, `rooftop_road.gd`, `ladder.gd`, `bamboo_grove.gd` | The expanded village's areas (see "The expanded village") |
| `scripts/paper_critter.gd`, `paper_dog.gd`, `paper_bird.gd`, `lantern_husk.gd`, `burning_paper.gd` | The new enemies |
| `scripts/paper_maker.gd` | The Paper-Maker at her vat (Meshy model `models/papermaker.glb`, posed by hand) |
| `scripts/save_game.gd`, `crane_bundle.gd`, `smudge.gd`, `ability_card.gd`, `hannya_ending.gd` | Saving, cranes, the Smudge, ability card, the ending after the Hannya |
| `scripts/water_fx.gd`, `villager_shadow.gd`, `perched_birds.gd` | Splashes and water, shadows behind shoji, perched birds |
| `docs/overnight_report.md` | What was built overnight on 2026-11-22, and what to judge |
| `tools/smoke_test.gd` | The automated check |
| `tools/frame_sheet.gd` | Frame sheets |
| `tools/setup_input.gd` | Writes the controls into `project.godot` |
| `tools/render_lettering.gd` | Renders brush lettering into `textures/` |
| `tools/village_map.py` | Draws the expanded village plan (`docs/village_map.png`) |
| `tools/model_look.gd` | Photographs an unrigged model from three sides |
| `tools/make_title_video.gd` | Turns frames into the title video (`video/title_loop.ogv`) |
| `scripts/title_screen.gd`, `title_menu.gd`, `pause_menu.gd`, `ink_menu.gd`, `ui_style.gd` | Title screen, pause screen, the shared menu and UI style |
| `fonts/` | The brush font, cut down for the UI (and its licence) |
| `video/` | The title video |
| `export_presets.cfg` | Web, Windows and Mac export settings (and the page's download link) |
| `.github/workflows/deploy.yml` | Check, build, release and deploy on every push to `main` |

## Commands

Godot was installed with winget; the `godot` alias was not created, so use
the full name (its folder is on PATH in new terminals).

```powershell
# Open the editor / play the game
Godot_v4.7.2-stable_win64.exe --path . --editor
Godot_v4.7.2-stable_win64.exe --path .
# Automated check (must print "ALL PASSED")
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/smoke_test.gd
# Import (after adding files or a new class_name)
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
# Screenshot (flags: --x=, --y= (underground), --zoom=, --face=-1, --hold= (repeatable), --marks=,
# --cutscene, --warmup, --map (pause map, all explored), --ending (her fall), --glide (has the glide))
Godot_v4.7.2-stable_win64_console.exe --path . -- --x=21 --screenshot=C:\full\path\shot.png
# The prologue as a frame sheet; the climb out of the well (play, or photograph with --well-sheet=)
Godot_v4.7.2-stable_win64_console.exe --path . -- --well
Godot_v4.7.2-stable_win64_console.exe --path . -- --prologue-sheet=C:\full\path\prologue.png
# The title screen (--menu, --page=settings, --page=controls), or the pause screen
Godot_v4.7.2-stable_win64_console.exe --path . -- --title --screenshot=C:\full\path\title.png
Godot_v4.7.2-stable_win64_console.exe --path . -- --title --page=controls --screenshot=C:\full\path\controls.png
Godot_v4.7.2-stable_win64_console.exe --path . -- --x=21 --pause --screenshot=C:\full\path\pause.png
# Frame sheet (see "Checking work" for the list)
Godot_v4.7.2-stable_win64_console.exe --path . --script tools/frame_sheet.gd -- cuts C:\full\path\cuts.png
# After a push: watch the build, then check the release
gh run watch <run id> --repo noodlerocket/orikami --exit-status
gh release view latest --repo noodlerocket/orikami
```

After changing scripts: run the automated check, and take a screenshot or a
frame sheet when the change can be seen.

## Milestones

- [x] **Setup and M1 (look and feel):** the village, the Ronin as a hand-posed
      Meshy model, wind, sound, rain, HUD, web build.
- [x] **M2 Combat core:** parry, block, posture and stagger, finishing cut,
      iaijutsu draw with the parry-then-draw combo.
- [x] **Movement:** wall slide and wall jump, climbing course, duck, pit fade.
- [x] **M4 First boss:** the Weeping Hannya, her cutscene and fight.
- [x] **Online:** Windows and Mac downloads; the web page shows the title
      and offers them.
- [ ] **M3 Ink:** ink marks (saved), Refold heal
      polish, the Smudge on death, shrines.
- [x] **Title and pause:** title screen on Julian's looping video, pause
      menu, settings and controls, all in one UI style (2026-11-21)
- [x] **Prologue:** a 2.5D pop-up-book cutscene with brushed lines and its
      own music, ending in the well (2026-11-21; not yet watched by Julian)
- [x] **The well:** a cutscene of him jumping out of it, seen from the
      street, the camera gliding into the game view
- [x] **Tutorial, icon, download page** (2026-11-21)
- [x] **The expanded village** (overnight 2026-11-22, awaiting Julian's
      judgement): three layers, seven areas, four shrines that save, new
      enemies, shortcuts, cranes, the Smudge, a map. (The Paper-Maker is
      only a shadow.)
- [x] **An ending after the Hannya** (proposed lore; awaiting Julian).
- [ ] **M5:** the Bamboo of Folded Wind region (first stretch and the Crane
      Glide built; the rest, and Akane, not).
- [ ] **M6:** vertical slice polish: audio balance, map.

## Known gaps

- **Not yet judged by Julian in play:** the Hannya fight's difficulty and
  pace (first guesses), the block, the duck, the healing ensō.
- Never judged in motion or by ear by Claude: animation, effects and sound
  were checked by frame sheets and measurement only. Volumes are guesses.
- The Mac download has not been tried on a Mac; a gamepad has never been
  tested.
- `tools/model_look.gd` cannot show rigged models (they draw wrongly there).
- The cloak does not collide with his body: a very strong gust can push it
  through his legs.
- The ink blots when struck follow the model's texture layout, so they are
  angular rather than round.
- Overnight work (2026-11-22) was checked by the automated check, screenshots
  and frame sheets only: never played by a person. See the report.
- The castle road from the lookout is scenery: the glide does not open it
  (it belongs to a later chapter).
- The husk's model has no wind cloth.
- `docs/design.md` still names the Kasa-obake as the first boss.
- One foreground rock near the climbing course cannot be filled (a warning
  in the log, "could not triangulate"): that rock is simply missing.
