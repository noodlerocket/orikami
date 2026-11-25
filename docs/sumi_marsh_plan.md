# Sumi Marsh: plan for the region (proposed, for Julian)

**Status (2026-11-25): all of it is built**, as below, except that the
drowned soldiers in the causeway stand on guard rather than rising out of
the ink (the causeway is dry stone). Not yet played by Julian.

Chapter 4 in `docs/design.md` ("Oppressive and dark. Bled ink pools into
black swamps. Home of Shimeri, the Sodden General. Wax Coat is essential").
Built after the Lantern Market (2026-11-24 night, Julian: "the next region,
large like its predecessors and unique").

## How he gets there

Beaten, Hōshō kneels in the rain that pours through the torn shoji. The
gold folding screen at the hall's east end then stands folded aside, and
past it a back stair goes down off the market's cliff. Walking east through
it fades to black, and he is at the marsh's west end, at the foot of the
Weeping Steps. Walking back west takes him to the hall.

Like the grove and the market, it is its own place, far off along x:
`SumiMarsh.SHIFT` 3000.

## The look (what makes it unlike the others)

- **Ink, not water.** Everything that was water in the town is black ink
  here. It is glossy and slow, and it shows pale reflections of the fog.
- **A drowned dusk, not night.** There is no moon. A low ceiling of torn
  grey-violet paper cloud hangs over the marsh, with a band of sickly pale
  jade fog along the horizon.
- **The only warm light is candles.** The Wax-Maker's candles and a few
  votive candles at drowned shrines give it. Pale blue-white will-o'-wisps
  (onibi) drift between the dead trees.
- **Bone-white dead trees.** Bare, twisted and hung with soaked paper
  streamers (shide). Grey-green reeds that sway and part as he passes. A
  few haze trees (hazenoki, whose berries give Japanese wax) in faded
  rust-red, only round the Wax-Maker's island.
- **Drowned things.** Half-sunk torii, stilt houses leaning into the ink,
  grave posts (sotoba) and stone lanterns up to their necks, banners of
  Shimeri's army hanging limp.
- **Weather:** the Rain falls in long slow drops. In places a broken
  aqueduct pours a curtain of ink that presses him down.

## Areas, left to right (local metres)

| | Area | Metres | What happens there |
|---|---|---|---|
| 1 | **The Weeping Steps** | 0 to 18 | Arrival. Stone steps down into the fog, a half-sunk torii, **shrine 10** (`marsh`) at a drowned jizō. |
| 2 | **The Reed Shallows** | 18 to 96 | Boardwalks over shallow ink. Wading in it is slow and **stains** him: ink soaks into his paper, a little at a time, and counts toward the endings. Reeds part. Lotus pads dip under him. **Sinking planks** settle into the ink while he stands on them and come back up after. Ink frogs. A heron's nest in a dead tree holds cranes. |
| 3 | **The Drowned Village** | 96 to 176 | Stilt houses, some leaning, with walkable roofs as the high route and rope lines between. The old street lies under deep ink, its sunken roofs poking up as stepping stones. Sodden husks rise out of the ink. Ink eels in the deep stretch. **Shrine 11** (`stilt_house`) on a porch. Cranes in a sunken attic can only be reached by swimming (come back with the Wax Coat). |
| 4 | **The Wax-Maker's Island** | 176 to 212 | Haze trees, the wax press, cakes of wax drying, candles hanging on strings. The Wax-Maker is an old paper doll in a straw rain cape. She dips him: **the Wax Coat**. |
| 5 | **The Black Mere** | 212 to 300 | Wide deep ink, crossed by swimming (waxed paper floats). Islands of dead trees, ink eels leaping. The broken aqueduct pours **ink curtains**: unwaxed he would be pressed under, waxed it runs off him. A high route along the aqueduct's fallen arches (glide and gust) has cranes. **Shrine 12** (`mere`) in a reed hut on an island. |
| 6 | **The Causeway of Lost Names** | 300 to 352 | A stone causeway between rows of grave posts and drowned stone lanterns, past the limp banners of his army. Sodden husk soldiers stand guard. **Shrine 13** (`causeway`) before the gate. |
| 7 | **Shimeri's Post** | 352 to 404 | A flooded gate fort (a yagura gate), knee-deep in ink: the arena. Shimeri still guards it. Past it, the gate onward is shut (the next region). |

That makes about 404 m, near the market (482) and the grove (413). There
are three layers: the boardwalks and banks, the roofs, aqueduct and dead
trees above, and the ink below, swum through once he has the Wax Coat.

## The Wax Coat (Rōbiki), the region's ability

The Wax-Maker presses the berries of the haze trees into wax and coats
him in it. With it:
- **Waxed paper floats.** In deep water or ink anywhere in the game he no
  longer goes under and back to the shrine. He floats chest-deep, swims
  slowly, and can jump up out of it. This opens the Black Mere, and on the
  way back it opens cranes in places that were deep water: the town's
  canals, the market's canals and the Lower Market's canal under the bridge.
- **Ink no longer stains him or slows him** when he wades.
- **The Rain no longer weighs him down.** Ink curtains here and the town's
  sluices no longer press him.

## New creatures (all folded in code, posed by hand)

- **Ink frog (sumi-gaeru).** A folded origami jumping frog, soaked black,
  with a pale belly. It sits on pads and banks and croaks. Its tell: its
  throat swells, it rocks back and its eyes catch the light. Then it
  leaps at him in a long arc and lands in a splat of ink. He can pogo off
  it; parried, it flips onto its back.
- **Ink eel (sumi-unagi).** It lives in deep ink. Its tell: a pale paper
  fin cuts through the surface toward him and the ink bulges. Then it
  bursts out in an arc over the boardwalk, jaws open, and drops back in.
  He can cut it in the air and parry it.
- **Sodden husk.** A paper husk soaked dark. It rises out of the ink with
  a spurt of drops as he comes near (it is the town's husk, made to rise
  out of the ink).
- **Life:** will-o'-wisps, herons that take off when he comes near, reeds
  that part, candles that gutter as he passes, bubbles, and lotus pads
  that rock when landed on.

## Shimeri, 湿将, the Sodden General (the region's boss)

From the design: *he endures the Rain. He is soaked through, barely
holding his shape, and still guarding his post out of duty. Slow and
heavy. He fights with fading honour and forgets his own moves
mid-fight.*

- A great armoured samurai, about 4 m tall, knee-deep in the ink, folded
  in code as a rigid paper puppet (design.md: "the pieces never bend, they
  only hinge"). He wears o-yoroi, its lacing run and dripping ink, and a
  kabuto whose long horns (kuwagata) droop. His menpō mask has its painted
  face half washed off. He carries a long nodachi, and the sashimono
  banner on his back hangs soaked and limp. Ink drips from every hem.
- **Moves:**
  - Overhead cleave: he raises the blade high, ink streaming off it, and
    slams it down so a wave of ink runs along the floor both ways. Jump
    the wave; parry the blade.
  - Low sweep: he drags the blade back through the ink, leaving a wake,
    then sweeps at the ankles. Jump.
  - Charge: he lowers his shoulder and lunges across the arena. Parry.
  - Wringing the banner: he wrings his soaked banner over his head, and
    drops of ink rain down where stains spread first. Dodge.
  - **Forgetting:** in the middle of a tell he stops and his armour sags.
    His head tilts as if trying to remember, which leaves an opening.
    Then he begins again, sometimes a different move, always with its
    own tell from the start, so it stays fair.
  - From half health he calls his drowned soldiers: two sodden husks
    rise from the ink.
  - Touching him hurts and he stamps.
- **Intro** (CineCamera): the gate in the rain. He stands motionless
  under his limp banner. The Ronin walks up, the head lifts and ink pours
  from the helmet. His brushed line: "Who goes. ... This gate is kept." His
  title 湿将 is painted, with its seal.
- **After:** he kneels into the ink. For a moment the soaked paper takes
  its creases again and he remembers. His line: "Shimeri. That was my
  name." He holds out his seal (SaveGame seal "shimeri") and it flies to
  the Ronin's hand.

## Order of building

1. The Wax Coat in the Ronin (floating, swimming, no staining, no press),
   with deep water everywhere calling it.
2. The place: sky, fog, ink, banks, boardwalks, the Weeping Steps,
   shrine 10, the way in from Hōshō's hall.
3. The Reed Shallows: sinking planks, lotus pads, reeds, ink frogs.
4. The Drowned Village: stilt houses, roofs, deep street, sodden husks,
   eels, shrine 11.
5. The Wax-Maker's Island and the Wax Coat.
6. The Black Mere: swimming, ink curtains, the aqueduct, shrine 12.
7. The Causeway, shrine 13, and Shimeri's Post with the fight, intro and
   ending.
8. Wax Coat cranes back in the town and market.
