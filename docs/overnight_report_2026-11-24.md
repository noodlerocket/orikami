# Overnight, 2026-11-23 to 24: what was done

Nothing is committed or pushed yet. Say "commit and push" when you have
looked. The automated check prints ALL PASSED (it has new checks for
Hōshō's fight, the market's floor, the back alley and the burning store).

## Fixed from your notes before bed

- **The market's floor was missing.** My speed change ("only the place
  you're in runs") hid the market's paving, because the paving is built
  into the village rather than the market. Each piece now belongs to the
  place it stands in. The paving and its wet reflections are back. A new
  check fails if anything of the market is hidden while you are in it.
- **Detail:** the speed changes hide only the *other* places (the town
  while you're in the market, and so on), and pause faraway creatures. That
  floor was the only thing in your own place that went missing, and it is
  fixed.
- **Hōshō:**
  - Wind-ups about a quarter faster: `sweep_tell` 0.46, `thrust_tell`
    0.52, `lantern_tell` 0.45, `storm_tell` 0.6, `leap_tell` 0.38, gold
    wave `wave_tell` 0.72.
  - **Leap and slam:** the landing spot follows you all the way up
    (`leap_track_speed` 11 m/s), then holds still for 0.14 s before he
    comes down (`leap_lock`).
  - The landing ring was invisible before (it was under the floorboards).
    It is now a glowing gold oval as wide as the slam's real reach, with a
    light on the boards.
  - **Spin:** the naginata is held level at the Ronin's chest. You can
    jump over it now.
  - **The intro close-up:** he holds the naginata upright in both hands.
    The open palm beside the shaft is gone. The same pose is used whenever
    he calls his lanterns.
  - **The thrust's sound:** a new sound, an armoured lunge with rattling
    lacquer plates (`hosho_lunge`). It replaces Akane's draw sound there.
    I read your "glide sound" as this one. If you meant the gold wave's
    whoosh, tell me.

## New

1. **Lantern ghosts (chōchin-obake) are a Meshy model** (you asked). It is
   a paper lantern torn into a toothed mouth, with one weeping eye, a
   candle glowing inside and a long red tongue whose tip lolls and lashes.
   It cost **39 credits**: 9 for the picture, 30 for the model. Your
   balance was 1,576 before. Normally I'd ask first, but you had just asked
   for it and were going to bed.
2. **Hōshō's hall is closed at its east end** by a great gold folding
   screen with a vermilion sun. Open, the end showed a house and a bare
   sheet: unfinished.
3. **The back alley under the Gilded Terraces bridge** (from the region
   plan). Falling off the bridge no longer sends you back to the shrine.
   You land in a narrow wet alley with a lantern, crates and **6 cranes**.
   Its red back door (hold **W**) takes you up through the cliff to the far
   terrace.
4. **A new use for the Fan Gust: the burning store.** In the Upper Market
   (just past the red bridge) a storehouse's door is barred by a burning
   heap of stall screens. Only the Fan Gust, learned much later, puts it
   out. Inside are **8 cranes**. A reason to come back. (The sweets booth
   that stood there was taken out to make room.)
5. **The fire looks better.** The heart of every burning barricade used to
   burn out to a flat white rectangle. Now it is orange and gold flame.
6. **Screenshots are taken 4 at a time** (your idea): `tools/area_sweep.py`
   runs four copies of the game at once.

## Checked

- The Rise, the Terraces, Hōshō's Gate and his hall were photographed
  every 9 m and gone through for floating, sunken or overlapping things.
  The hall's open end was the only fault found, and it is fixed.
- The automated check prints ALL PASSED.

## Only you can judge

- The fight's feel: the new wind-up speeds, how fair the leap is now, and
  jumping over the spin.
- The new lunge sound (by measurement it is not a pop).
- The lantern ghost model: is it scary enough, and is it the right size?
  It is 1 m tall.

## Not built (and why)

- **The hoist shortcut from the Rise back to Festival Square.** A rope
  over the rooftops would have to clear the drying deck (18.6 m), the drum
  tower (19 m) and the Ward's tall gate. I would rather plan it with you
  than leave something clipping through roofs.
- The canal lock shortcut and the other Fan Gust ideas from the plan
  (blowing an awning round, turning a waterwheel to raise a boat).

## Your question: would loading only the region you're in fix the lag?

Partly, and the part that matters most is already done. Every region is in
memory, but the town and the bamboo are now hidden and stopped while you
are in the market, so they cost almost nothing per frame. True unloading
(separate scenes per region) would mostly save memory and loading time,
not frame rate. It would be a big rebuild, because the level is built in
code and the regions' heights are joined together. The lag that's left in
the market is the market itself, which is dense. Merging its many small
pieces into fewer meshes is the next step if it still feels slow.
