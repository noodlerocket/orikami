# ORIKAMI (prototype, frozen)

> **This is the finished prototype, kept as it is.** The real game is
> developed in `noodlerocket/orikami` (folder `C:\Users\JulianUribe\OrikamiGame`),
> which started as a copy of this at the tag `prototype-v1`. Work on the
> game there, not here.

A 2.5D samurai metroidvania where everything is folded paper. It is Julian's
first game. Built with Godot 4.7.2 (standard, GDScript), meant to be playable
in a browser via GitHub Pages.

- Play it: https://noodlerocket.github.io/orikamiprototype/
- Download it: https://github.com/noodlerocket/orikamiprototype/releases/latest
  (Orikami-Windows.zip, Orikami-Mac.zip; rebuilt on every push to `main`,
  linked from the game page's top-right corner)
- Code: https://github.com/noodlerocket/orikamiprototype (public; every push to `main`
  rebuilds and redeploys the page in about a minute)
- Design doc (story, mechanics, style): `docs/design.md`
- What it looks like right now: `docs/screenshots/`
- Read "Working with Julian" and "What Julian likes" before changing anything.
  They were learned the slow way and will save several rounds of rework.

## Working with Julian

- He is a beginner at the engineering side. **Explain in plain language and
  work in small steps.** Say what changed, where the setting is, and what you
  could not check.
- His eye for visuals and feel is sharp and specific. He decides by SEEING,
  not by reading descriptions: **send screenshots or frame sheets with every
  visual change**, and compare them with his reference yourself before you
  show him.
- He gives feedback in short messages, often several while you are still
  working. Fold each one into the work in hand and say you have.
- He tunes by overshooting: "too fast" is often followed by "now too slow".
  So when asked to change something, **move about halfway, not to the other
  extreme**, put the number in ONE `@export` setting, and tell him its name
  and the values he has already rejected.
- When he cannot name the problem ("one of the sounds is a pop"), do not ask
  him to identify it. **Measure it** (see "Checking work without eyes or
  ears") and show him what you found.
- Commit and push only when he says so. Confirm the cost before any Meshy
  call that spends credits. He asked for ElevenLabs sounds by name; generating
  a few more on request is fine.

## What Julian likes (learned; do not relearn)

**Looks**
- Copy his reference images closely; do not reinterpret them. If a picture and
  his words disagree, follow the latest picture and say so.
- Everything must look deliberate. He spots anything careless: houses that are
  flat from the side, branches with no trunk, cloth swinging through its pole,
  two sheets flickering at the same depth, a sword left hanging after a cut.
  Before showing work, look for exactly these: is it solid from every angle
  the camera reaches, is it attached to something, does anything pass through
  anything, does anything overlap at the same depth.
- Muted and decaying, never vibrant. The night is a dull indigo; blossom is
  faded and dusty; warm colour comes only from lanterns and windows; vermilion
  is kept for things that matter (torii, the banner, lantern crests, the
  "heal ready" seal).
- Effects belong to the world of paper and ink. Being hurt is ink soaking his
  paper, not a blink. Generic game effects get rejected (blinking, ripple
  rings on the ground).

**Motion**
- Natural, never mechanical. He has rejected: a fast small jitter, a slow
  pendulum, and swaying stepped at 12 fps. Wind motion is smooth (every
  frame), wide, at a middling pace.
- Effects are drawn on and wiped away; they never pop in and out whole.
- The attack is short and swift, and looks like a real samurai draw: out of
  the scabbard and sweeping round from the side. Never an up-and-down chop.
  Hollow Knight is his reference for how the swoosh and the hit should feel.
- What you see is what you hit: the hit area ends where the swoosh ends.
- Nothing lingers after it is over (the sword goes away with the swoosh).
- The camera is gentle: it must not lurch when he turns.
- The camera stays at one height: it does not rise when he jumps or climbs
  onto a platform (`FollowCamera.follow_height` 0; 1 was the old
  follow-him-up behaviour, rejected). BUT his middle may never be above the
  middle of the screen (`keep_below_center`): when he gets that high, the
  camera rises exactly enough to keep him there. The exception is the climbing course
  (`climb_zone`), where it follows him up and keeps him in the middle of the
  screen, no higher than `climb_max_y`. `--zoom` close-ups always follow.
- Falling into a pit fades the screen to sumi black and back (`Main.pit_fade_*`)
  and puts him at the start; no ink, no blink. He asked for exactly this.
- Wall slide: his BACK to the wall, both feet braced behind him flat on it,
  one hand pressed back on it. (Facing the wall was tried and rejected.)
- Anything that hurts must show its cause: touching a husk makes it shove.
- Stock animation is not good enough. Meshy's preset clips were thrown out
  ("they don't look samurai at all"); his movement is posed by hand.

**Sound**
- Real-sounding, generated with ElevenLabs. The cut is ONE airy whoosh (no
  metallic draw, no second variant, no sheathing click). A hit sounds like
  scissors through paper. The enemy bursting is fine as it is.
- A sound that "pops" is wrong. Check new sounds by measurement.

**Rain**
- Each drop hitting the street throws up a small jet and a few droplets. He
  found a faint version too weak and a strong one too strong; it sits at
  `Village.splash_strength` 0.5.

## Checking work without eyes or ears

A single screenshot cannot show motion, and sound cannot be heard. Use these.

- **Screenshots:** `--screenshot=` (see Commands). `--x=` starts further along
  the level, `--zoom=` puts the camera close, `--face=-1` faces left,
  `--hold=move_right` holds a control down.
- **Frame sheets:** `tools/frame_sheet.gd` photographs a sequence and tiles it
  into one picture: `stances`, `cuts` (ten moments of each cut, 20 ms apart),
  `endings`, `struck`, `hud`, `parry` (a real exchange with a husk: its
  tell, the parry and clash, the stagger, the finishing cut; use
  `--zoom=6`), `draw`, `iai`, `husk`, `climb`, `wall`, `pit`, `marks`
  (see the top of the file for which need `--zoom`). Use it for every animation or effect change,
  and send him the sheet.
- **Timing:** when two things must end together, print the times and compare
  them; do not trust the picture alone.
- **Sound:** decode with ffmpeg (installed) and numpy, and look at where the
  energy is. A pop has most of its energy inside ~50 ms, mostly below 300 Hz,
  and starts at full loudness. A whoosh spreads over 100 ms or more, is mostly
  above 300 Hz and starts quietly. `audio/README.md` has the worked example.
- **Depth fights:** search for sheets built at the same `z` that overlap.
- **The automated check** (`tools/smoke_test.gd`) only proves the rules of
  movement and combat still work. Run it after every change, but it says
  nothing about looks or feel.
- Always say plainly what was checked this way and what only he can judge.

## Design summary

- **World:** Kamiyo, a land folded from one sacred sheet. The Rain makes ink
  bleed; soaked beings lose their creases and forget who they are.
- **Hero:** the Blank Ronin, unmarked white paper, silent, in a wide kasa hat
  and a torn cloak. The Rain can't erase him (nothing to erase) but water
  weighs him down.
- **Twist:** he is the cause of the Rain, not the cure. It is the Paper
  Emperor's tears at the world being unfolded, which began when the Ronin was
  folded.
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
  Crane Glide, parry/slash/iaijutsu, first ink-marking, Kasa-obake boss.

## The references

Julian owns both images.

- **The Ronin** is the walking figure IN the rainy-town picture: wide white
  kasa hat hiding his eyes, cowl at the neck, long robe, cloak torn into long
  tails, slim legs, katana sheathed at the hip. All white, no red. Seen
  side-on. (He tried the horned samurai from the origami sheet first and then
  chose this one; that sheet is a reference for folding style only.)
- **Kamiyama Village** is the rainy night town: muted indigo night, torn paper
  edges with a pale rim, paler and mistier layers with distance, peeling paper
  walls with ink drips, shingled roofs, warm lanterns and shoji windows, wet
  paving, dark foreground framing, a pagoda castle and a crumpled moon.
- Both are written up in `docs/design.md`.

## How the game is built

### Engine rules
- **Godot 4 syntax only**, never Godot 3. GDScript, typed where practical.
- **Compatibility renderer** (`gl_compatibility`). No Forward+/Mobile-only
  features (no volumetric fog, SDFGI, real translucency).
- **Web:** must run on GitHub Pages. The Web export preset has thread support
  OFF. Use `CPUParticles3D`, not GPU particles.
- **All numbers that affect feel are `@export` variables**, grouped with
  `@export_group`, so Julian can tune them in the Inspector.
- **Gameplay on one plane:** `CharacterBody3D` with `axis_lock_linear_z` and
  `position.z = 0`; side-view `Camera3D` (`scripts/follow_camera.gd`).
- Physics layers: 1 world, 2 player, 3 enemies. Player and enemies do not
  push each other; enemies hurt through an `Area3D`; cuts use a shape query.
- Slash directions use y-up (`Ronin.SLASH_UP` / `SLASH_DOWN`), never
  `Vector2.UP` / `DOWN`: Godot's point the other way.
- The level is built in code, so the editor's 3D view is empty until you
  press Play.

### The Ronin
- **A Meshy model with a skeleton, animated by hand in code.** This replaced
  the original "rigid pieces, no skeletons" rule, for the Ronin only.
  `models/ronin.glb` holds the mesh (about 12,900 triangles) and a 24-bone
  skeleton. Meshy's four stock clips are still inside the file, unused.
- `scripts/samurai_animator.gd` poses the skeleton directly. A pose says where
  the hips, hands and feet ARE and how the back and head bend; the script
  bends elbows and knees to fit (two-bone inverse kinematics). All the stances
  (idle, run, air, land, dash, hurt, heal, three cuts) are plain numbers in
  the second half of that file.
- `scripts/ronin_puppet.gd` picks the stance for the state, 12 poses a second.
  Running eases in and out (`run_ease_in`); jump and fall follow
  `vertical_speed`; landing gives a short crouch; a cut lays its upper body
  over a run or jump.
- **Style of his movement:** low, straight-backed, hands on the sword, head
  level under the hat, sharp held poses.
- **Cuts** are iaijutsu draws, 0.22 s long (`cut_time`). Forward: out of the
  scabbard at his left hip and level round to his right. W + cut: up and over
  his head. S + cut in the air: down and under. The drawn katana is folded in
  code (slim, curved, pale edge); while it is out, the sculpted handle slides
  out of sight in the shader, so there is only ever one sword.
- **The swoosh** (`shaders/slash_sweep.gdshader`, `_build_sweeps`) is a strip
  of paper along the blade's path: a ribbon wrapped round him for forward
  cuts, an upright crescent for up and down. It is drawn on from the end
  where the cut starts, wiped away from that same end, and lasts `cut_time`.
- **Hit area = swoosh:** `Ronin.slash_reach` + half of `slash_size.x` (1.9 m)
  matches `RoninPuppet.sweep_reach` (1.85). Change them together. (1.6 m was
  a little short.)
- Up and down cuts are posed at `aimed_cut_fps` (30) so the blade's travel
  shows. The sword goes away at `sword_away_at` (0.95), with the last of the
  swoosh, and he is re-posed that instant.
- **Parry** (I): `SamuraiAnimator.parry` is a short draw into a guard, blade
  slanted up before his face. A blow that lands within `Ronin.parry_window`
  (0.2 s) of the press, from the side he faces, is deflected: no damage, a
  hit-stop, a push back, and the clash (`_build_clash`: thin paper rays
  fanned toward the blow, drawn out and wiped away with the swoosh shader,
  plus white chips). A deflect resets the cooldown so a quick second blow
  can be caught. Enemy attacks call `Ronin.receive_strike()`; touching an
  enemy still calls `take_damage()` and cannot be parried.
- **No cutting during a parry** (`_parrying`, as long as the parry stance).
- **Block:** holding parry (I) past the parry window keeps his guard up
  (the braced parry pose, shuffling at `guard_walk`). A blow from the front
  does no harm and pushes him back; `block_breaks_after` (2) blocks close
  together break the guard and stun him (`guard_break_stun`). A perfect
  parry's clash is GOLD (`RoninPuppet.parry_color`, Julian asked); a block's
  is a smaller dull grey.
- **Duck (hold S on the ground):** a deep crouch, his body shrunk to
  `duck_height` (0.85 m), so the Hannya's glide (at chest height,
  `HannyaBoss.glide_band` 1.0 to 2.6 m) passes over. Her "walking into her
  hurts" area is off while she gathers for and flies the glide (it used to
  hurt him as she flew over, so ducking did not work). W stays aim-up only
  (Julian tried W as jump too and took it back).
- **Ink as liquid:** every ink drop, splash, drip and wisp uses
  `PaperMesh.soft_ink()` (a soft round blot), never a hard rectangle (black
  rectangles looked careless). Paper scraps stay rectangles. The ink wall's
  spurting droplets are soft round drops (Julian wanted the spurting kept,
  just not as rectangles).
- **Healing (hold U):** an ensō is painted round him in pale glowing ink as
  the heal charges (its progress is the charge), pale motes drawn in; let
  go early and it is wiped away; on completion it closes, flashes and
  bursts into motes, and his paper flashes. Julian asked for clearer
  charging and finishing cues.
- **Death:** he shreds into white strips and scraps (`RoninPuppet.shred`),
  then the screen fades and he is revived whole at the start (`Ronin.died`,
  `revive()`), like the pit fade.
- **Iaijutsu draw:** on its own key, K (gamepad Y; it was U, and heal moved from K to U): hold it to crouch into
  the iai stance at once, with no cut first (holding J was rejected: J cut
  first, and making J wait would slow every cut); after `draw_charge_time`
  an inch of blade shows and it is READY: a gleam on the blade, a flash of
  his paper, and a chime (`draw_ready.mp3`); while held ready his paper
  glows, breathing (`RoninPuppet._update_ready_cue`);
  let go to dash `draw_distance` through everything in the way, cut a moment
  after he arrives (`draw_cut_delay`). A paper streak is left along the path
  and wiped away with the sword. K held straight after a parry
  (`draw_combo_window`) goes into a ready stance at once: the
  parry-then-draw combo. The draw keeps him safe with `_draw_safe` (no ink
  shown), not `_invulnerable` (which shows the struck ink).
- **Walls:** touching a wall marked `climbable` (meta) while falling, he
  clings and slides at `wall_slide_speed`; jump to spring off
  (`wall_jump_push`, `wall_jump_velocity`); holding back toward it climbs
  even a single wall. Level edges and pit sides are not climbable.
- **Ink marks:** `Ronin.ink_absorbed` counts every drop ever taken in (healing
  does not wash it off). At `marks_full_at` (150) he is covered. The shader
  draws thin flowing brush strokes from each point's resting position
  (stored in CUSTOM0 by `_paint_cloth`), spreading and thickening, with
  soaked blots near the end; they are drawn on at `marks_draw_speed`.
  `--marks=0.5` starts him half-inked.
- **Finishing cut:** a cut on a staggered enemy (`is_staggered()`) kills it
  at once, with a bigger burst, a longer hit-stop and `finish_ink` extra ink.
- **Dash:** an almost flat lunge, stretched along its direction, with white
  speed lines.
- **Cloth:** `shaders/paper_cloth.gdshader` swings the cloak, side drapes and
  hem toward "gravity plus air", where the air is the shared wind minus his
  own velocity. Which points are loose is painted into the vertex colours
  when the model loads (`_paint_cloth`). Updated every frame.
- **Struck:** ink drops fly off, his paper is soaked black, and the blots
  shrink away while he is invulnerable (same shader, `ink`).
- `RoninPuppet.use_model` off brings back an older hand-folded puppet.
- Meshy task ids, for regenerating: reference image
  `01a1fe34-82ed-7777-a106-c9426c19a9be`, model
  `01a1fe35-1fe6-7224-8761-2b947296784c`, rig
  `01a1fe3a-367b-75e8-9da1-31847b37ff68`. Settings: meshy-t2.5 smart topology,
  15,000 target triangles, meshy-n1 texture, a-pose.

### Enemies
- Low-poly, flat-shaded paper figures, posed at ~12 fps.
- **The paper husk** is a Meshy model (`models/husk.glb`, 7,118 triangles,
  same 24-bone skeleton as the Ronin) posed by hand: its stances are in
  `scripts/husk_poses.gd` and `SamuraiAnimator.apply()` bends the skeleton
  to fit. Shamble, tell (both arms raised high behind its head, so it reads
  whichever way it faces), swipe, shove, stagger. `PaperHusk.use_model` off
  brings back the older figure folded from rigid pieces. Meshy ids:
  reference image `01a1ff5b-b853-72f6-923e-c586eff0fa96`, model
  `01a1ff5c-2442-71c0-b068-3d7173aefe25`, rig
  `01a1ff5e-19d7-752f-93a2-5355c1d32a6c` (meshy-t2.5, 8,000 target, meshy-n1,
  a-pose). Its reference is `docs/reference/husk_front.png`.
- **Touching a husk** that hurts him makes it shove (`shove_time`), unless it
  is already swiping.
- **The husk's attack:** when the Ronin is within `attack_range` in front of
  it, it rears back with an arm raised behind its head (`attack_windup`
  0.4 s, the tell; 0.55 was too slow), then lunges and swipes. A cut interrupts the swipe.
- **Posture:** each parried swipe adds 1; at `max_posture` (2) it staggers
  for `stagger_time`, folded over, with a small vermilion seal stamped on
  its body (the sign that a finishing cut is ready). Posture drains one
  point per `posture_recover_time` without a parry.

### The world
- **Kirigami diorama:** flat paper cut-outs at real depths, so layers slide
  past each other as you walk. Depth guide (Z): +4 dark foreground, +1.5
  front edge of the street, 0 gameplay, -4.3 house walls, -9 to -17 back of
  the village, -24 to -48 hills and peaks, -53 sky.
- **Paper helpers** (`PaperMesh`): `tear()` roughens an outline,
  `torn_sheet()` adds the pale torn rim, `loft()` folds tubes, `fade_quad()`
  + `build_veil()` make gradients and mist. Every piece shares a crumple
  texture made in code. Use these, never plain straight-edged shapes.
- **Depth recipe** (`backdrop.gd`): each layer further back is paler and
  bluer, with a sheet of mist at its foot; and each layer is two sheets (a
  lighter top edge, a darker ridge in front), not one flat cut-out. Backdrop
  sheets are unshaded with fog off, so their colours are exactly as written.
- **Backdrop contents:** sky, crumpled moon with a glow, clouds that drift
  with the wind, far peaks with pale caps, hill layers with pines, the
  five-storey castle on its hill with a path of lanterns, a far torii, the
  back of the village with a watchtower, a river with moonlight on it, the
  arched bridge, and a veil of far rain.
- **Houses are solid:** side walls with a shoji window, gable ends, a back
  wall and a rear roof slope.
- **Cherry trees** (`Scenery.sakura_tree`) are rooted: trunk, limbs that only
  climb, mostly bare twigs, a little faded blossom. The foreground one keeps
  its limbs high, clear of the play area.
- **Light:** lanterns are real `OmniLight3D`s plus glowing paper and a halo.
  About 8 lights may touch any one mesh (Compatibility limit), which is why
  the paving is built in short lengths. "Light through paper" is faked with
  glowing paper and a light in front. Wet-street reflections are faked warm
  smears (`Village.wet_shine`).
- **Colour grading:** `Village.color_saturation` / `color_contrast` keep the
  night muted. Tune there before changing individual colours.
- **No two flat sheets may share a depth where they overlap** (they flicker).
- **The climbing course** (`Village.CLIMB_WALLS`, `_build_climb_wall`): two
  tall plastered timber walls before the torii. The first is raised on posts
  like a gatehouse (walk under it into the gap); its solid part reaches the
  ridge of its little roof (`CLIMB_ROOF`) so you stand on the ridge, not in
  the tiles. The second carries a lookout ledge with a lantern at 11.5 m.
- **The torii** stands at `Village.TORII_X` (46.0), the courtyard's gateway,
  clear of the tall climbing wall (at 44.6 the wall hid its left side).
- **The shrine courtyard** past the torii (`Village.ARENA`, x 47 to 63.5):
  the Hannya's shrine hall (`HannyaStage`), a fence, two lit stone lanterns
  (`arena_lanterns`, snuffed in the cutscene), a cherry. The camera follows
  him in as anywhere else and stops at its middle (`FollowCamera.max_x`).
  (A hard lock on the courtyard made it jump left when he stepped out:
  rejected.)

### The Weeping Hannya (first boss)
- Chosen by Julian over the Kasa-obake ("not scary"). Meshy models:
  `models/hannya.glb` (rigged, 2.6 m; reference `docs/reference/hannya_front.png`;
  image `01a1ff82-5cb1-74f2-af57-33d8f905d86c`, model
  `01a1ff83-2572-77c6-8489-0b0c8a48860d`, rig `01a1ff85-a583-7695-bd2f-b4e629bcbd0b`)
  and `models/hannya_mask.glb` (close-up mask, meshy-7.1 with a 4K texture;
  image `01a1ff82-6a99-7641-94aa-210e4a826f5b`, model
  `01a1ff83-2d64-72ec-92b6-ff8ad6928c7a`). Posed by hand (`hannya_poses.gd`);
  Julian asked whether Meshy animation would be better: no, timing must
  match the hit areas, and he rejected stock clips before.
- **The shoji screen** (`hannya_stage.gd`, `shaders/shoji_screen.gdshader`):
  a hidden camera at the lamp films her silhouette double (render layer 20,
  `Hannya.SHADOW_LAYER`; every other camera must leave that layer out) and
  the screen prints it, softened, as her shadow. The lamp is low on the floor
  and she kneels side-on near it, so the shadow is a tall profile. The
  screen also bleeds ink from her shape, opens slashes and tears.
- **The cutscene** (`hannya_cutscene.gd`, 40 s, 2.5D, scored to
  `music_hannya_intro.mp3`; the rip lands on the music's eruption at 28 s):
  he creeps in (`SamuraiAnimator.sneak`), lanterns die, her shadow weeps,
  turns, bleeds ink, the paper rips, the mask comes through, she towers, the
  title is painted (`hannya_title.gd`). It plays the first time he enters the
  courtyard; hold jump to skip. `--cutscene` plays it at once.
- **Lettering:** the brush font Yuji Syuku lives in `art_source/` (ignored by
  Godot, never shipped); `tools/render_lettering.gd` renders the few lines
  needed into `textures/`. Julian wants Japanese, samurai-feeling lettering.
- **The fight** (`hannya_boss.gd`, 30 health, 6 posture): sleeve slash
  (sometimes double), glide (at chest height: duck or parry; its tell: she rises with sleeves spread like wings, ink streaming
  off her, a wail, and a streak of pale light along her path; the old small
  draw-back was too easy to miss), ink rain (`ink_drop.gd`, dodge it), ink blades
  (`ink_blade.gd`, pale crescents, parry each), ink step (sinks into an ink
  pool, `ink_pool.gd`, rises behind him; Julian asked for this instead of a
  paper burst), weeping masks from half health (`phantom_mask.gd`). Julian
  asked for more projectile and supernatural moves. A finishing cut takes
  `finish_damage` (6). While she fights, the courtyard entrance is sealed
  by a wall of ink that erupts out of a spreading ink pool and rises
  (`Village.set_arena_sealed`, `shaders/ink_wall.gdshader`; ink falling
  from nowhere was rejected), so the fight
  cannot be walked out of (walking out used to reset her: rejected); only
  dying resets her. Walking into her hurts and knocks him back, and she
  swats (`contact_damage`, `swat_time`), like a husk. Her bar: `boss_bar.gd`. Fight music
  `music_hannya_fight.ogg` (seamless loop). Dying resets her: she waits at
  the courtyard's right end (`waiting_gap`), facing the way he comes back
  in; coming back restarts the fight without the cutscene.
- **The pit** (`Village._build_pit`, `PIT_LEFT`/`PIT_RIGHT`/`PIT_BACK`) is a
  hole in the street, not a cut through it: the street carries on behind
  it, the street's torn front crumbles at its edges, and lantern
  reflections (`_add_wet_shine`) are trimmed so none hangs over the hole.

### Wind
- One shared wind (`scripts/wind.gd`): a breeze plus gusts that roll along the
  street. Everything asks it how hard it is blowing where it stands.
- Hanging and standing scenery is hinged and marked with
  `Scenery.windswept()`; `village.gd` swings it every frame in two
  overlapping rhythms (`sway_speed` 2.4, `sway_range`). Rejected: 6 (jitter),
  1.4 (sleepy), 3 with a third fast shiver (jittery).
- Anything on a pole or bracket hangs on its downwind (left) side, or far
  enough out, so it never swings through its support.
- The rain slants with the wind, petals drift with it, clouds ride it, the
  wind sound swells with it, and the Ronin's cloak blows in it.

### Sound
- `scripts/sound.gd` (the `Sound` node in `main.tscn`). Any script plays a
  sound with `Sound.play(self, &"name")`. Rain (two layers), wind and the
  village music (`music_village.ogg`, `Sound.music_volume`) loop all the
  time. M mutes. Loops that must be seamless are OGG: MP3 leaves a gap.
- Files are in `audio/`; `audio/README.md` lists each one, when it plays and
  the words used to generate it.
- Generating with ElevenLabs: make `audio/raw/` first (the tool will not
  create it), generate into it, rename, then delete the folder. Files come
  out named after the first five letters of the prompt, so start each prompt
  with a different word. Lengths are 0.5 to 5 seconds. The key cannot read
  usage, so the cost cannot be checked.

### The health display
- `scripts/hud.gd` draws everything in code: a torn paper strip, one ink
  splat per health point (a dried ring when lost; it bursts when you are hurt
  and blooms when you heal; the last one throbs), a brush stroke for ink with
  a tick at every heal's worth, and a red seal that lights when a heal is
  ready.

### Builds and speed
- **Web:** the browser prepares each new kind of material the first time it
  is drawn, which froze the game for up to 3.4 s. `Main._warm_up()` (web
  only; `--warmup` forces it natively) shows the whole level and every
  effect once behind a sumi cover with a pale ensō (`loading_cover.gd`).
  ANY NEW EFFECT, MATERIAL OR ENEMY must be added to that warm-up list, or
  it will hitch the first time it appears in the browser. Measured on the
  live site: 15 slow frames and a 3.4 s freeze while running became 1 slow
  frame (51 ms). The Hannya's shadow camera rests while her shrine is out
  of view (`HannyaStage.set_shadow_active`).
- **Downloads:** export presets "Windows" (one .exe, everything inside) and
  "Mac" (universal .app, ad-hoc signed, not notarized). The workflow exports
  both and replaces the GitHub Release "latest" with
  `Orikami-Windows.zip` and `Orikami-Mac.zip`. The page's link to them is
  in the Web preset's `html/head_include`. Unsigned: Windows shows
  "protected your PC" (More info, Run anyway); a Mac needs right-click, Open
  the first time.

## Layout

| Path | What it is |
| --- | --- |
| `scenes/main.tscn` | The test scene: Village, Ronin, Camera, Rain, Sound, Overlay (grain + HUD) |
| `scenes/ronin.tscn` | The player. Movement numbers are on the root node; looks and animation on `Puppet` |
| `scenes/paper_husk.tscn` | The patrolling enemy |
| `scripts/ronin.gd` | Player rules: run, jump, dash, cut, pogo, heal, damage |
| `scripts/ronin_puppet.gd` | Player looks: picks the stance, draws the swoosh, blows the cloak, shows the ink |
| `scripts/samurai_animator.gd` | Poses the model's skeleton; holds all his stances |
| `models/ronin.glb` | The Ronin, sculpted and rigged by Meshy (the `.png` beside it is its texture) |
| `scripts/paper_husk.gd` | Enemy: patrol, tell + swipe, shove, posture/stagger, 3 hits, crumple, confetti |
| `scripts/husk_poses.gd` | The husk's hand-made stances |
| `scripts/hannya*.gd`, `ink_*.gd`, `phantom_mask.gd`, `boss_bar.gd` | The Weeping Hannya: stage, poses, cutscene, title, fight, projectiles, health bar |
| `shaders/shoji_screen.gdshader` | The backlit shoji with her shadow, ink and tears |
| `art_source/` | Source art Godot ignores (the brush font) |
| `textures/` | Lettering rendered from the brush font |
| `tools/model_look.gd` | Photographs an unrigged model from three sides (rigged ones: check in game) |
| `tools/render_lettering.gd` | Renders brush lettering into `textures/` |
| `models/husk.glb` | The husk, sculpted and rigged by Meshy |
| `scripts/village.gd` | The level LAYOUT: ground, houses, lanterns, props, lighting, wind sway, rain splashes |
| `scripts/scenery.gd` | The prop kit: houses, roofs, lanterns, curtains, banner, well, torii, pines, cherry trees |
| `scripts/backdrop.gd` | Everything far away: sky, moon, clouds, peaks, hills, castle, far village, river, mist |
| `scripts/paper_mesh.gd` | Folds paper shapes in code: folds, torn edges, paper texture, palette |
| `scripts/wind.gd` | The one shared wind |
| `scripts/sound.gd` | Plays every sound; keeps the rain and wind going |
| `scripts/hud.gd` | The health and ink display |
| `scripts/rain.gd`, `confetti.gd`, `follow_camera.gd`, `main.gd` | Rain, death burst, camera, wiring and debug options |
| `shaders/paper_grain.gdshader` | Full-screen paper grain + vignette |
| `shaders/paper_cloth.gdshader` | The Ronin's paper: wind-blown cloth, ink when struck, hiding the sculpted handle |
| `shaders/slash_sweep.gdshader` | The swoosh of a cut: drawn on, then wiped away |
| `audio/` | The sound files and a README saying what each one is |
| `docs/design.md` | The design doc |
| `docs/reference/ronin_front.png` | The front-view drawing the Meshy model was built from |
| `docs/screenshots/` | The current look, including frame sheets |
| `tools/setup_input.gd` | Writes the controls into `project.godot` (re-run after editing) |
| `tools/smoke_test.gd` | The automated check |
| `tools/frame_sheet.gd` | Photographs animation and effects frame by frame |
| `.github/workflows/deploy.yml` | Builds the web version and deploys to GitHub Pages on push to `main` |

Controls (keyboard + gamepad): A/D move, S duck, Space jump (also off walls), J cut
(W/S to aim), hold K then let go for the iaijutsu draw (gamepad Y), L or Shift dash,
I parry, hold I to block (gamepad left shoulder or trigger), hold U heal,
M mute.

## Commands

Godot was installed with winget. The `godot` alias was not created (it needs
admin), so use the full name; its folder is on PATH in new terminals.

```powershell
# Open the editor
Godot_v4.7.2-stable_win64.exe --path . --editor
# Play the game
Godot_v4.7.2-stable_win64.exe --path .
# Automated check (must print "ALL PASSED")
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/smoke_test.gd
# Screenshot (optionally start at another x)
Godot_v4.7.2-stable_win64_console.exe --path . -- --x=21 --screenshot=C:\full\path\shot.png
# Close-up of the Ronin
Godot_v4.7.2-stable_win64_console.exe --path . -- --zoom=4.2 --screenshot=C:\full\path\ronin.png
# Frame sheet: stances | cuts | endings | struck | hud | parry | draw | iai | husk | climb | wall | pit | marks | sneak | cutscene | boss [new|step]
Godot_v4.7.2-stable_win64_console.exe --path . --script tools/frame_sheet.gd -- cuts C:\full\path\cuts.png
```

After changing scripts: run the smoke test, and take a screenshot or a frame
sheet when the change can be seen.

## Milestones

- [x] **Setup:** Godot 4.7.2, project, git, CLAUDE.md, web export preset, Pages workflow
- [x] **M1 Look and feel test:** Ronin run / variable jump / dash / 4-way cut
      with pogo; rainy village with well, platforms, lanterns, shoji screen;
      paper husk enemy (3 hits, confetti); paper grain; ink HUD
- [x] **M1 art pass:** the Ronin as a Meshy model of the hat-and-cloak figure,
      animated by hand; village rebuilt in the rainy-town style
- [x] **M1 feel pass:** wind on scenery and cloth, sound, solid houses, rooted
      cherry trees, ink when struck, reworked run / dash / draw-cut, the
      swoosh, rain splashes, gentle camera, upgraded backdrop and HUD
- [x] **Online:** pushed to GitHub; the Pages workflow builds, runs the smoke
      test, exports and deploys; the game loads and takes input in a browser
      with no console errors (checked 2026-11-21)
- [ ] **M1 follow-ups:** Julian playtests the browser version for speed and
      sound (music added 2026-11-21)
- [x] **M2 Combat core:** parry + posture/stagger, finishing cut, iaijutsu
      draw with the parry-then-draw combo (2026-11-21; feel not yet judged
      in play by Julian)
- [x] **Movement:** wall slide and wall jump, climbing course, pit fade
      (2026-11-21)
- [ ] **M3 Ink:** ink-marking on the Ronin's body (first version done
      2026-11-21), Refold heal polish, Smudge on death, shrines
- [x] **M4 First boss:** the Weeping Hannya, with her cutscene (first pass,
      2026-11-21; not yet played by Julian)
- [ ] **M5 Bamboo of Folded Wind** region + Crane Glide
- [ ] **M6** Vertical slice polish: audio, menus, save at shrines, map

## Known gaps

- **Never judged in motion or by ear by Claude.** Animation, wind and effects
  were checked from frame sheets; sounds by measurement. Volumes in
  `sound.gd` are first guesses.
- The browser version was only checked to load, draw and take input. Its
  frame rate and its sound have not been checked by anyone yet.
- The workflow's actions were moved to Node 24 versions (checkout v7,
  configure-pages v6, upload-pages-artifact v5, deploy-pages v5) on
  2026-11-21, after GitHub warned that Node 20 was being retired.
- The cloak does not collide with his body, so a very strong gust can push it
  through his legs.
- The ink blots when struck follow the model's texture layout, so they are
  angular rather than round.
- Heal (hold U) costs 3 ink for 1 health; he kneels while an ensō (brush
  circle, `RoninPuppet._update_enso`) is painted round him as the charge
  builds, then it closes, flashes and dissolves when the heal lands.
- Death just respawns at the well; falling in the pit costs 1 health.
- Ink marks are not saved between sessions (there is no saving yet).
- The husk's model is lit like the rest of the scene but has no wind cloth.
- `models/hannya_mask.glb` keeps its 4K source texture in the repo, but the
  game imports it at 1024 (`hannya_mask_0.jpg.import`, `process/size_limit`):
  in the close-up 1024 looks the same as 4096, and it is 0.7 MB in the game
  instead of 17 MB.
- The Hannya fight was checked by the automated test and frame sheets only;
  its difficulty and pace are first guesses, not yet played.
