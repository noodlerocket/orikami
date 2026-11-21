# ORIKAMI

A 2.5D samurai metroidvania where everything is folded paper. It is Julian's
first game. Built with Godot 4.7.2 (standard, GDScript, Compatibility
renderer); playable in a browser and as Windows/Mac downloads.

- **This is the real game.** It began as a copy of the finished prototype
  (git tag `prototype-v1`). The prototype is kept, unchanged, in
  `noodlerocket/orikamiprototype` (folder `C:\Users\JulianUribe\Orikami`,
  https://noodlerocket.github.io/orikamiprototype/). Do not work there.
- Play it: https://noodlerocket.github.io/orikami/
- Download it: https://github.com/noodlerocket/orikami/releases/latest
- Code: https://github.com/noodlerocket/orikami (public). Every push to `main`
  runs the automated check, rebuilds the web page and the downloads, and
  publishes them in about two minutes.
- Design doc (story, mechanics, style): `docs/design.md`
- What it looks like: `docs/screenshots/` (frame sheets of every move)

**Before changing anything, read "Working with Julian" and "What Julian
likes".** They were learned the slow way and save rounds of rework.

## Where the game stands (2026-11-21)

One level, Kamiyama Village at night in the rain, from the well to a shrine
courtyard, with:
- the Blank Ronin: run, jump, dash, wall slide and wall jump, duck, a 4-way
  iaijutsu cut with pogo, parry (gold) and block, the charged iaijutsu draw,
  healing with ink, ink marks that build up on his paper, shredding death;
- paper husks that patrol, wind up, swipe, shove and stagger;
- a climbing course, a pit, wind, rain, sound and music;
- the first boss, **the Weeping Hannya**, with a 40-second shadow-puppet
  cutscene and a full fight.

Not built yet (the likely next steps): an ending after the Hannya, a title
screen and pause menu, saving (and shrines to save at), the Smudge on death,
the Bamboo of Folded Wind region and the Crane Glide, a map. See Milestones.

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
  clicks (the draw's "ready" chime is a small temple bell).
- A sound that "pops" is wrong. Check every new sound by measurement.

**Specific settings he has judged** (do not change without being asked)
- Rain splashes: `Village.splash_strength` 0.5 (fainter and stronger both
  rejected). Wind sway: `sway_speed` 2.4 (6, 1.4 and 3 rejected).
- Husk tell: `PaperHusk.attack_windup` 0.4 s (0.55 too slow).
- Sword reach 1.9 m (1.6 m a little short).
- Pit or death: the screen fades to sumi black and he is back at the start;
  no ink, no blink.

## Checking work without eyes or ears

A single screenshot cannot show motion, and sound cannot be heard. Use these,
and always say plainly what was checked this way and what only he can judge.

- **The automated check** (`tools/smoke_test.gd`, 52 checks): movement,
  combat, walls, pit, death, husks and the whole Hannya fight. Must print
  ALL PASSED after every change. It proves rules work, nothing about looks.
  When fixing a bug, add a check that fails without the fix (and, when in
  doubt, prove it by briefly undoing the fix).
- **Screenshots:** `--screenshot=` (see Commands), with `--x=`, `--zoom=`,
  `--face=-1`, `--hold=move_right`, `--marks=0.5`, `--cutscene`.
- **Frame sheets** (`tools/frame_sheet.gd`) photograph a sequence and tile
  it into one picture. Use one for every animation or effect change and send
  it to him. Sheets: `stances`, `cuts`, `endings`, `struck`, `hud`, `parry`,
  `draw`, `iai`, `husk`, `climb`, `wall`, `pit`, `marks`, `sneak`, `heal`,
  `death`, `seal`, `cutscene`, `boss` (optionally `new`, `step`, `glide` or
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
- **Browser speed:** open the live site in the Browser pane (it must be
  VISIBLE: a hidden pane is throttled), then time frames with
  `requestAnimationFrame` in JavaScript (median, slow frames over 33 ms,
  worst) while holding a key with dispatched `KeyboardEvent`s.
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
I to block (left shoulder or trigger); hold U heal (B); M mute. W is aim-up
only. The table is in `tools/setup_input.gd`: edit it, re-run it, and update
the controls line in `scripts/hud.gd`.

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
- **Walls:** touching a wall marked `climbable` (meta) while falling, he
  clings and slides (`wall_slide_speed`); jump springs off; holding back
  toward it climbs even one wall. Level edges and pit sides are not
  climbable.
- **Duck** (hold S on the ground): a deep crouch; his body shrinks to
  `duck_height` (0.85 m), so the Hannya's chest-height glide passes over.
- **Heal** (hold U, 3 ink for 1 health): he kneels while an ensō is painted
  round him in pale glowing ink (its progress is the charge); let go early
  and it is wiped away; on completion it closes, flashes and bursts.
- **Ink marks:** `ink_absorbed` counts every drop ever taken in (healing
  does not wash it off); at `marks_full_at` (150) he is covered in flowing
  brush strokes (shader, drawn on at `marks_draw_speed`). Not saved yet.
- **Struck:** ink drops fly off, his paper is soaked black, the blots shrink
  away while he is invulnerable (shader `ink`).
- **Death:** he shreds into white strips and scraps (`RoninPuppet.shred`),
  the screen fades, he is revived whole at the well (`died`, `revive()`).
  Falling into the pit fades the same way and costs `pit_damage` (1).

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
  stamp). It plays the first time he enters the courtyard; hold Space to
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
  seal when a heal is ready, and the controls line at the bottom.

### Builds, speed and downloads
- **Web freezes:** the browser prepares each new kind of material the first
  time it is drawn (up to 3.4 s). `Main._warm_up()` (web only; `--warmup`
  forces it natively) shows the whole level and every effect once behind a
  sumi cover with a pale ensō (`loading_cover.gd`). **Every new effect,
  material or enemy must be added to that list**, or it will hitch the first
  time it appears in the browser. Result on the live site: 15 slow frames
  and a 3.4 s freeze became 1 slow frame (51 ms).
- **Downloads:** export presets "Windows" (one .exe) and "Mac" (universal
  .app, ad-hoc signed, not notarized; needs the ETC2/ASTC texture setting,
  which is on). The workflow (`.github/workflows/deploy.yml`) runs the
  automated check, exports web, Windows and Mac, replaces the GitHub Release
  "latest" with `Orikami-Windows.zip` and `Orikami-Mac.zip`, and deploys the
  page. The page's "Download: Windows · Mac" link is in the Web preset's
  `html/head_include`. Unsigned: Windows says "protected your PC" (More
  info, Run anyway); a Mac needs right-click, Open the first time.
- Godot's export templates are NOT installed on this computer (only on
  GitHub's builder), so web/desktop builds can only be tested after a push.
- The workflow's actions are on their Node 24 versions (checkout v7,
  configure-pages v6, upload-pages-artifact v5, deploy-pages v5).

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
| `tools/smoke_test.gd` | The automated check |
| `tools/frame_sheet.gd` | Frame sheets |
| `tools/setup_input.gd` | Writes the controls into `project.godot` |
| `tools/render_lettering.gd` | Renders brush lettering into `textures/` |
| `tools/model_look.gd` | Photographs an unrigged model from three sides |
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
# Screenshot (flags: --x=, --zoom=, --face=-1, --hold=, --marks=, --cutscene, --warmup)
Godot_v4.7.2-stable_win64_console.exe --path . -- --x=21 --screenshot=C:\full\path\shot.png
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
- [x] **Online:** web page with a loading warm-up; Windows and Mac downloads.
- [ ] **M3 Ink:** ink marks (first version done; not saved), Refold heal
      polish, the Smudge on death, shrines.
- [ ] **Finish the slice:** an ending after the Hannya, a title screen and
      pause menu (with volume and controls), saving at shrines.
- [ ] **M5:** the Bamboo of Folded Wind region and the Crane Glide.
- [ ] **M6:** vertical slice polish: audio balance, map.

## Known gaps

- **Not yet judged by Julian in play:** the Hannya fight's difficulty and
  pace (first guesses), the block, the duck, the healing ensō.
- Never judged in motion or by ear by Claude: animation, effects and sound
  were checked by frame sheets and measurement only. Volumes are guesses.
- The Mac download has not been tried on a Mac; a gamepad has never been
  tested; how long the web loading cover lasts for a first visit is untimed.
- `tools/model_look.gd` cannot show rigged models (they draw wrongly there).
- The cloak does not collide with his body: a very strong gust can push it
  through his legs.
- The ink blots when struck follow the model's texture layout, so they are
  angular rather than round.
- Death and the pit always send him back to the well (no checkpoints yet).
- Nothing is saved between sessions (ink marks reset).
- The husk's model has no wind cloth.
- `docs/design.md` still names the Kasa-obake as the first boss.
