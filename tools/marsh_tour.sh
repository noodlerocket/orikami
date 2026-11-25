#!/bin/sh
# Photographs Sumi Marsh at a list of local x positions (debug starts in the
# marsh, waxed when --wax). Usage: sh tools/marsh_tour.sh OUTDIR x1 x2 ...
out=$1; shift
for x in "$@"; do
  Godot_v4.7.2-stable_win64_console.exe --path . -- --mere --x=$((3000 + x)) --screenshot="$out/marsh_$x.png" > /dev/null 2>&1 &
done
wait
