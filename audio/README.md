# Sounds

Every file here was generated with ElevenLabs sound effects on 2026-11-21.
The cut is one airy whoosh, `slash_1.mp3` (Julian did not want a metallic
draw, and asked for the second variant to be removed: only this one plays). A hit
sounds like scissors through paper (third attempt). There is no sound for
the katana going back in: he asked for it to be removed.

Tip: a sound that "pops" can be found without ears. Decode it with ffmpeg
and look at where its energy is: the rejected `slash_2` had 90% of its
energy inside 50 ms, 85% of it below 300 Hz, and started at full loudness.
A whoosh spreads over 100 ms or more, is mostly above 300 Hz, and starts
quietly.
`scripts/sound.gd` decides when each one plays and how loud it is.

To replace a sound, generate a new one and save it under the same file name.

| File | Plays when | Words used to generate it |
| --- | --- | --- |
| `rain_close.mp3` | always (loop) | Steady heavy rain falling on stone paving and clay roof tiles at night, close and detailed, no thunder, no voices, seamless ambience |
| `rain_far.mp3` | always (loop) | Distant wash of rain over rooftops and hills at night, soft continuous hiss with water dripping from eaves, no thunder, seamless ambience |
| `wind.mp3` | always (loop); louder in a gust | Low moaning night wind gusting through narrow wooden alleyways, soft whistling through gaps, no rain, no voices, seamless ambience |
| `step_1.mp3` | each running step | Footstep, a single step of a straw sandal on wet stone paving with a tiny splash, close, dry recording |
| `step_2.mp3` | each running step | Footstep, one light quick step in a shallow puddle on stone, soft wet slap, close, dry recording |
| `step_3.mp3` | each running step | Footstep, a single soft running step on wet flagstones, cloth sandal, faint water, close, dry recording |
| `jump.mp3` | jumping | Leap, a quick rustle of heavy cloth robes as a person jumps upward, short soft whoosh, no voice |
| `land.mp3` | landing | Landing, two feet landing on wet stone with a soft thud, small splash and a rustle of cloth, no voice |
| `dash.mp3` | dashing | Whoosh, a very fast sharp rush of air with cloth snapping as someone dashes past, short and forceful |
| `slash_1.mp3` | every cut | Swish, a single very fast airy whoosh of a thin sword blade slicing through the air, breathy and sharp, no metal ringing, no impact |
| `paper_cut_1.mp3` | a cut hits an enemy | Scissors, one quick snip of sharp scissors cutting through a sheet of paper, crisp snip with a short papery crunch, close and dry, nothing else |
| `paper_cut_2.mp3` | a cut hits an enemy | Scissors, a single fast cut of large scissors gliding through thick paper, smooth slicing snip ending in a clean snap, close and dry, nothing else |
| `paper_burst.mp3` | an enemy bursts | Crumple, a large sheet of paper being crushed and torn apart, then scraps fluttering down, no voice |
| `hurt.mp3` | the Ronin is hurt | Thud, a dull heavy blow against a body wrapped in thick cloth and paper, short muffled impact, no voice |
| `heal.mp3` | healing completes | Chime, a soft low temple bell struck once with a gentle shimmer and a faint rustle of paper, calm and warm |
| `parry.mp3` | a parry catches a blow | Deflect, a stiff paper folding fan snapped shut hard against a blade, one sharp crisp papery crack with a brief bright rustle, close and dry, no metal ringing, no voice. *Trimmed: the first 0.26 s (a slow lead-in) cut off so the crack lands at once, and turned down (it clipped).* |
| `stagger.mp3` | a husk's posture breaks | Crinkle, a sheet of thick paper being slowly crushed and folded in half by hand, loud close crackling paper creases, dry studio recording, no voice. *(A first take, "Slump...", was rejected: nearly silent and 92% low rumble.)* |

- `paper_fold.mp3`: each pop-up folding up off the page in the prologue.
  Words: "Folding paper pop-up: a sheet of thick washi paper quickly folding up
  and standing, a soft crisp crease and flap, close and gentle, no click"
  (0.8 s). Measured: energy spread over 417 ms, 7% below 300 Hz, starts at
  0.17 of its loudest: not a pop.

## Music

`music_village.ogg` loops all the time under the rain (`Sound.music_volume`).
Made with ElevenLabs music (music_v2, instrumental, 90 s) from: "Slow, sparse,
melancholic Japanese ambient music for a rainy night village in a quiet video
game. Solo shakuhachi with long breathy phrases and pauses, occasional soft
koto plucks, a faint low drone underneath, lots of silence and space. Muted,
decaying, lonely, gentle. No drums, no beat, no vocals, no modern synths.
Even, steady volume from start to end so it can loop."
Its last 4 seconds were blended into its first 4 so it loops with no seam,
and it was saved as OGG because MP3 leaves a tiny gap when looped.
Measured: nothing below 120 Hz, no drum-like hits; it swells gently in the
middle and is quiet at both ends.

## The Weeping Hannya

All generated with ElevenLabs on 2026-11-21, measured, and levelled so none
clips (the rip was turned down from 1.35; the ink bleed and taiko from 1.28
and 1.25). The taiko is mostly low and starts at full loudness, as a drum hit
should; its energy spreads over 0.7 s, so it is a boom, not a pop.

| File | Plays when | Words used to generate it |
| --- | --- | --- |
| `hannya_sob.ogg` | her shadow weeping (cutscene, looped) | The original sob (Sobbing, a woman weeping quietly behind a thin paper screen in the rain, muffled, slow shaking breaths and soft sobs, distant and intimate, no words), made cursed in ffmpeg: pitched down 12% (and so slower, 6.3 s), a copy an octave below mixed in at 0.5, and an echo at 180, 390 and 650 ms (0.34, 0.22, 0.12). (First version: 7% down, undertone 0.3, a soft echo at 140 and 310 ms; Julian asked for the effects stronger.) *(Julian asked for her crying "more cursed"; a newly generated monstrous take sounded "really silly and bad": he wanted the original, just a little cursed. Levelled to the original's 0.63 peak; a 20 ms fade-in. Its ends are silent, so it loops cleanly.)* |
| `hannya_sob_short.mp3` | the ink rain and the masks (fight) | The same as `hannya_sob.ogg`, as an MP3 for one-shot use. |
| `lantern_snuff.mp3` | a stone lantern goes out | Snuff, a stone lantern flame put out by rain, a short wet hiss and a soft puff, close |
| `ink_bleed.mp3` | ink bleeds through the screen; she sinks into ink | Bleeding, wet black ink slowly soaking through a sheet of paper, faint crackle of fibres swelling and a few slow drips, close and quiet, unsettling |
| `mask_creak.mp3` | her head turns; the mask; she rises from ink; a mask dives | Creak, stiff folded paper and old lacquer slowly bending and creaking as a head turns, close, eerie, no voice |
| `paper_rip.mp3` | the screen is slashed and torn | Rip, a large sheet of thick shoji paper torn violently apart in one long fast tear, with scraps fluttering, close and loud |
| `taiko_hit.mp3` | the title; her death | Taiko, one single deep huge taiko drum hit in a large wooden temple hall, long dark reverberating tail, nothing else |
| `music_prologue.mp3` | the prologue (45 s, its events are timed to it) | music_v2, 45 s, one prompt describing each section with its loudness spelled out: very quiet hum and koto (0-8 s), a warm koto melody building (8-21 s), a loud taiko-and-strings eruption, sorrowful (it landed at 25 s, not 21), drop to near silence with one shakuhachi note and a soft heartbeat drum, one koto chord fading. A first take without the loudness words came out at one flat level and was thrown away. Raised 5 dB through a limiter, then 2.2 dB down: peak 0.87. |
| `music_hannya_intro.mp3` | the cutscene (40 s, the shots are timed to it) | music_v2: a 40-second cue described section by section: near silence and one shakuhachi note (0-9 s), mournful koto (9-19 s), draining to one thin dissonant string (19-27 s), a violent taiko and shakuhachi eruption (27-34 s), a dark ringing chord fading (34-40 s). A first take that only swelled and stopped was thrown away. |
| `music_hannya_fight.ogg` | the fight (loops) | music_v2, 75 s: intense dark Japanese boss battle music, driving taiko, aggressive shamisen, wailing shakuhachi, low dissonant strings, steady energy so it loops. Its last 3 s were blended into its start. |

| `draw_ready.mp3` | menus (choosing), the tutorial's seal; it was the draw's ready cue until Julian asked for that to have its own sound | Rin, a single small Japanese temple singing bowl struck once very lightly, a bright pure clear ring that fades quickly, close and clean, nothing else. *(A bell, not a sword click: Julian rejected sword clicks. Measured: no energy below 300 Hz, rings out over ~0.4 s; turned up from a very quiet 0.15 peak, with a 3 ms fade-in.)* |
| `draw_gleam.mp3` | the iaijutsu draw is charged and ready (hold K) | Gleam of light along a sword blade: one short bright airy shimmer, a high glassy sparkle that rises and fades quickly, soft start, no metal scrape, no bell. *(Julian: the old bell was the same sound as other things. Measured: no energy below 300 Hz, half its energy by 0.25 s, starts quietly; it clipped at 1.2, levelled to 0.73; cut to 0.7 s with a fade-out.)* |
| `shrine_rest.mp3` | resting at a shrine | Resting at a quiet shrine: a soft deep singing bowl struck once with a padded mallet, warm low resonant hum, long gentle peaceful decay, very calm. *(A pure tone at about 296 Hz, so small speakers still play it; rings out over ~1.5 s. It started at full loudness: a 12 ms fade-in so it cannot click; raised to 0.64 peak; cut to 3.2 s with a fade-out.)* |
| `hannya_wail.mp3` | the Hannya gathers herself to glide | Wail, a ghostly woman's short rising breathy shriek echoing in the rain, eerie and distant, no words. *(Turned down: it clipped at 1.12; given a 30 ms fade-in.)* |

## The expanded village (overnight, 2026-11-22)

Generated with ElevenLabs, measured with ffmpeg and numpy, shaped and
levelled (peaks at or under 0.88 in each channel). Sounds that started at
full loudness got a short fade-in so they cannot click; every one-shot got a
20 ms fade-out. The three loops are OGG and their ends meet (loudness at the
two ends within 0.01, no jump at the seam); they are placed in the level with
`Sound.place_loop`, so they swell as the camera comes near and fade away.
Three first takes were thrown away: a bark (the file name had a colon, which
Windows cannot save), a nearly silent grate clank (peak 0.03, mostly a
click), and a fire whoosh that started at full loudness with 91% of its
energy below 300 Hz (a pop).

| File | Plays when | Words used to generate it, and what was done |
| --- | --- | --- |
| `splash.mp3` | dropping into canal water, a plank landing in it, falling in the river | Splash: a person drops into shallow water in a stone canal, one heavy splash with droplets falling back, slight echo, no music. *(Very quiet, raised 12x; no energy below 300 Hz.)* |
| `wade.mp3` | each step while wading | Wading footstep in ankle deep water, a single soft slosh, close. *(5 ms fade-in.)* |
| `plank_creak.mp3` | stepping onto a soggy plank, and as it is about to go; the gate swinging | Creak of a wet old wooden plank bending under weight, slow groan of soaked wood |
| `plank_snap.mp3` | a plank gives way; the ladder lands; the gate's bar breaks | Snap of a rotten soggy wooden plank breaking, a dull wet crack and splintering |
| `grate_clank.mp3` | cutting the drain grate; it flips open; a cut on the barred gate from the wrong side | Clank of a heavy rusty iron grate rattling loudly in its stone frame when struck from below, metallic. *(Raised 10x; high-pass at 180 Hz and a 6 ms fade-in, so its strike is not a low thump.)* |
| `fire_bell.mp3` | cutting the fire-watch bell on the rooftop deck | Hanshō: an old bronze Japanese fire-watch bell struck once with a wooden mallet, deep clang ringing out and fading. *(Almost no energy below 300 Hz; rings over 3 s.)* |
| `dog_growl.mp3` | the paper dog's tell | Growl of a small fierce dog, low rumbling snarl, close. *(Starts quietly; a growl is low, so 68% below 300 Hz, spread over the whole 0.9 s.)* |
| `dog_bark.mp3` | the dog charges | Barking dog, one short sharp angry bark from a small dog, close. *(8 ms fade-in.)* |
| `dog_yelp.mp3` | the dog is cut | Yelp of a small dog that has been struck, one short whimper |
| `bird_shriek.mp3` | the paper bird's tell; it is struck | Shriek of a crow, one harsh rasping caw, eerie, at night. *(It clipped at 1.4 and started mid-cry: levelled, 15 ms fade-in.)* |
| `fire_whoosh.mp3` | the lantern husk's tell, and its throw | Whoosh of flames, a burning wad of paper flung through the air, rising airy fire swish, starts quietly. *(High-pass at 180 Hz and a 60 ms fade-in: it was a low rumble that started loud.)* |
| `fire_burst.mp3` | a burning wad hits something | Flare of burning paper hitting wet ground, a soft fiery puff and crackle of embers. *(High-pass at 220 Hz and a 35 ms fade-in: it started with a low thump.)* |
| `canal_drips.ogg` | the drain pipe and the canals (looped, six places) | Drips of water falling into a dark stone canal tunnel, slow echoing drops over a faint trickle, ambience. *(Generated as a loop; it clipped at 1.33, levelled.)* |
| `river_flow.ogg` | the river (looped, three places along it) | River flowing steadily past stone banks in the rain, gentle continuous water ambience |
| `sluice_pour.ogg` | each sluice (looped) | Pouring water: a steady stream of water falling from a grate onto stone and splashing, continuous |

| `skid.mp3` | a sharp turn at a run | Skidding sandals scraping to a sudden stop on wet stone paving, a short gritty slide. *(High-pass at 150 Hz; starts quietly.)* |
| `shake_off.mp3` | shaking the water off after the canals | Shaking water off a wet paper cloak and straw hat, a quick rustle and a spray of droplets |
| `cranes_rise.mp3` | a bundle of paper cranes found | Fluttering of many small paper cranes taking flight, soft paper wings rustling upward with a faint airy shimmer, gentle and magical. *(Quiet: raised 5.4x; starts from silence.)* |

Measuring tip: decode each channel separately (or `-ac 1` overstates the
peak of a stereo file: ffmpeg's down-mix sums the channels).
