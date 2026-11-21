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
