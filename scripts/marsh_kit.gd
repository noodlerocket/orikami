class_name MarshKit
extends RefCounted
## The props of Sumi Marsh, folded in code (SumiMarsh, docs/sumi_marsh_plan.md):
## bone-white dead trees hung with soaked paper streamers, reeds and
## cattails, grave posts (sotoba), drowned stone lanterns, thatched stilt
## houses, lotus leaves. The palette is the constants below: ink black,
## bone, a grey-green, rust only round the Wax-Maker.

const BONE := Color(0.6, 0.6, 0.56)
const BONE_DARK := Color(0.3, 0.3, 0.31)
const REED := Color(0.3, 0.34, 0.28)
const REED_DRY := Color(0.34, 0.33, 0.27)
const MUD := Color(0.1, 0.1, 0.1)
const MUD_TOP := Color(0.16, 0.16, 0.15)
const MOSS := Color(0.17, 0.21, 0.16)
const THATCH := Color(0.36, 0.33, 0.28)
const THATCH_DARK := Color(0.2, 0.18, 0.15)
const WOOD_WET := Color(0.17, 0.15, 0.15)
const STONE := Color(0.3, 0.31, 0.33)
const STONE_DARK := Color(0.14, 0.15, 0.17)
const INK := Color(0.045, 0.05, 0.065)
const RUST := Color(0.5, 0.25, 0.16)
const CANDLE := Color(1.0, 0.74, 0.42)
const WISP := Color(0.7, 0.85, 1.0)
const SHIDE := Color(0.76, 0.76, 0.72)


## A tube along the segment a to c, radius r0 at a and r1 at c (a limb, a
## pole that leans): rings at right angles to its line.
static func limb(b: PaperMesh, a: Vector3, c: Vector3, r0: float, r1: float, sides: int = 6, cap: bool = true) -> void:
	var d := (c - a).normalized()
	var helper := Vector3.FORWARD if absf(d.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var u := d.cross(helper).normalized()
	var v := d.cross(u).normalized()
	var rings: Array = []
	for t: float in [0.0, 1.0]:
		var centre := a.lerp(c, t)
		var r := lerpf(r0, r1, t)
		var ring := PackedVector3Array()
		for i in sides:
			var ang := TAU * float(i) / float(sides)
			ring.append(centre + (u * cos(ang) + v * sin(ang)) * r)
		rings.append(ring)
	b.loft(rings, cap, cap)


## A dead tree: a twisted bone-white trunk rising from its foot (the origin),
## splitting into bare crooked limbs, some hung with soaked paper streamers
## (shide) that sway. `ledges`, if given, are the heights of branches made
## solid to climb by (the caller adds their bodies: see `branch_ledges`).
static func dead_tree(rng: RandomNumberGenerator, height: float, lean: float, radius: float = 0.32, streamers: int = 3) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.16
	b.texture_world = false
	# Roots spreading into the ink or mud at its foot.
	b.color = BONE_DARK
	for k in 4:
		var a := TAU * k / 4.0 + rng.randf_range(-0.4, 0.4)
		var out := Vector3(cos(a), 0.0, sin(a) * 0.7)
		limb(b, Vector3(0.0, 0.5, 0.0), out * radius * 3.2 + Vector3(0.0, -0.3, 0.0), radius * 0.6, radius * 0.18, 5)
	# The trunk: a column bending as it rises, thinning.
	var pts: Array[Vector3] = []
	var p := Vector3(0.0, -0.4, 0.0)
	var steps := 6
	for i in steps + 1:
		pts.append(p)
		var t := float(i + 1) / float(steps)
		p += Vector3(lean * height / steps * (0.6 + rng.randf_range(-0.7, 0.7)), height / steps, rng.randf_range(-0.05, 0.05))
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		b.color = BONE.darkened(rng.randf_range(0.0, 0.18) + 0.12 * (1.0 - t0))
		limb(b, pts[i], pts[i + 1], radius * lerpf(1.0, 0.35, t0), radius * lerpf(1.0, 0.35, t1), 7, i == 0 or i == steps - 1)
	# Bare limbs from the upper trunk, each with a twig or two.
	var tips: Array[Vector3] = []
	for k in 5:
		var at: Vector3 = pts[rng.randi_range(3, steps)]
		var side := -1.0 if k % 2 == 0 else 1.0
		var reach := rng.randf_range(0.9, 2.0) * (height / 7.0)
		var tip := at + Vector3(side * reach, rng.randf_range(0.2, 1.1), rng.randf_range(-0.4, 0.4))
		b.color = BONE.darkened(rng.randf_range(0.05, 0.2))
		limb(b, at, tip, radius * 0.28, radius * 0.08, 5)
		var twig := tip + Vector3(side * rng.randf_range(0.3, 0.7), rng.randf_range(0.3, 0.7), 0.0)
		limb(b, tip, twig, radius * 0.08, radius * 0.03, 4)
		tips.append(tip)
	# Ink soaked up the bark from the waterline.
	b.color = Color(0.1, 0.1, 0.12)
	limb(b, Vector3(0.0, -0.4, 0.0), Vector3(pts[1].x * 0.5, 0.55, 0.0), radius * 1.04, radius * 0.96, 7)
	root.add_child(b.build())
	# Streamers: zigzag paper strips hung from limbs, soaked, swaying.
	for k in mini(streamers, tips.size()):
		var tip: Vector3 = tips[k]
		var hang := Node3D.new()
		hang.position = tip.lerp(pts[steps - 1], 0.4)
		root.add_child(hang)
		var s := PaperMesh.new(rng.randi())
		s.texture_world = false
		s.shade_jitter = 0.08
		s.color = SHIDE.darkened(rng.randf_range(0.05, 0.25))
		var y := 0.0
		var w := 0.09
		for z in 4:
			var x0 := 0.04 if z % 2 == 0 else -0.04
			s.quad(Vector3(x0 - w, y, 0.0), Vector3(x0 + w, y, 0.0), Vector3(-x0 + w, y - 0.22, 0.0), Vector3(-x0 - w, y - 0.22, 0.0), Vector3.BACK)
			y -= 0.22
		s.color = Color(0.24, 0.24, 0.26)
		s.box(Vector3(0.0, 0.03, 0.0), Vector3(0.24, 0.025, 0.025))
		hang.add_child(s.build())
		Scenery.windswept(hang, 0.12, rng)
	return root


## A clump of reeds: thin tapering blades (each a sharp folded strip) and a
## few cattails, rooted at the origin, spread along x by `width`. Swayed by
## the wind and parted by him (SumiMarsh sets `reed_lean`).
## `dark`: silhouettes only (the foreground), no dry blades or pale heads.
static func reeds(rng: RandomNumberGenerator, width: float, height: float, depth: float = 0.5, tint: Color = REED, dark: bool = false) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.14
	var blades := int(width * 9.0) + 4
	for k in blades:
		var x := rng.randf_range(-width * 0.5, width * 0.5)
		var z := rng.randf_range(-depth, depth)
		var h := height * rng.randf_range(0.6, 1.15)
		var bend := rng.randf_range(-0.5, 0.5)
		b.color = tint.darkened(rng.randf_range(-0.1, 0.3)) if (rng.randf() > 0.2 or dark) else REED_DRY.darkened(rng.randf_range(0.0, 0.3))
		var w := rng.randf_range(0.025, 0.045)
		var mid := Vector3(x + bend * 0.35, h * 0.55, z)
		var top := Vector3(x + bend, h, z)
		b.quad(Vector3(x - w, -0.3, z), Vector3(x + w, -0.3, z), mid + Vector3(w * 0.7, 0.0, 0.0), mid - Vector3(w * 0.7, 0.0, 0.0), Vector3.BACK)
		b.tri(mid - Vector3(w * 0.7, 0.0, 0.0), mid + Vector3(w * 0.7, 0.0, 0.0), top, Vector3.BACK)
	for k in int(width * 1.5) + 1:
		var x := rng.randf_range(-width * 0.4, width * 0.4)
		var z := rng.randf_range(-depth * 0.6, depth * 0.6)
		var h := height * rng.randf_range(0.8, 1.05)
		b.color = REED_DRY.darkened(0.25) if not dark else tint
		limb(b, Vector3(x, -0.3, z), Vector3(x + 0.05, h, z), 0.012, 0.01, 4, false)
		b.color = Color(0.2, 0.13, 0.1) if not dark else tint
		limb(b, Vector3(x + 0.05, h - 0.05, z), Vector3(x + 0.055, h + 0.22, z), 0.035, 0.03, 6)
	root.add_child(b.build())
	return root


## A grave post (sotoba): a tall thin plank with a notched top, its brushed
## lines washed into streaks. Its foot at the origin.
static func grave_post(rng: RandomNumberGenerator, height: float) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.1
	b.color = Color(0.5, 0.48, 0.44).darkened(rng.randf_range(0.0, 0.25))
	var w := 0.13
	var profile := PackedVector2Array([Vector2(-w, -0.4), Vector2(w, -0.4), Vector2(w, height - 0.5),
			Vector2(w * 0.6, height - 0.42), Vector2(w, height - 0.3), Vector2(w * 0.5, height - 0.22),
			Vector2(w * 0.8, height - 0.1), Vector2(0.0, height), Vector2(-w * 0.8, height - 0.1),
			Vector2(-w * 0.5, height - 0.22), Vector2(-w, height - 0.3), Vector2(-w * 0.6, height - 0.42), Vector2(-w, height - 0.5)])
	b.extrude(profile, -0.02, 0.02)
	b.color = Color(0.12, 0.12, 0.14)
	var y := height - 0.7
	while y > 0.5:
		var len := rng.randf_range(0.08, 0.2)
		b.box(Vector3(rng.randf_range(-0.02, 0.02), y - len * 0.5, 0.024), Vector3(0.05, len, 0.004))
		y -= len + rng.randf_range(0.04, 0.12)
	root.add_child(b.build())
	root.rotation.z = rng.randf_range(-0.12, 0.12)
	return root


## A stone lantern (tōrō), sunk to `sunk` metres, its fire box dark or lit.
static func stone_lantern(rng: RandomNumberGenerator, lit: bool, glow: float = 1.4) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.12
	b.color = STONE
	b.frustum(6, Vector2(0.36, 0.36), Vector2(0.3, 0.3), 0.25, Vector3(0.0, -0.5, 0.0))
	b.frustum(6, Vector2(0.12, 0.12), Vector2(0.11, 0.11), 1.0, Vector3(0.0, -0.25, 0.0))
	b.color = STONE.darkened(0.1)
	b.frustum(6, Vector2(0.3, 0.3), Vector2(0.24, 0.24), 0.16, Vector3(0.0, 0.75, 0.0))
	b.color = STONE_DARK
	b.frustum(4, Vector2(0.2, 0.2), Vector2(0.2, 0.2), 0.32, Vector3(0.0, 0.91, 0.0), PI * 0.25)
	b.color = STONE
	b.frustum(6, Vector2(0.44, 0.44), Vector2(0.05, 0.05), 0.32, Vector3(0.0, 1.23, 0.0))
	b.frustum(6, Vector2(0.06, 0.06), Vector2(0.0, 0.0), 0.12, Vector3(0.0, 1.55, 0.0))
	b.color = MOSS
	b.frustum(6, Vector2(0.38, 0.38), Vector2(0.33, 0.33), 0.05, Vector3(0.0, -0.27, 0.0))
	root.add_child(b.build())
	if lit:
		var f := PaperMesh.new(1)
		f.color = CANDLE
		f.box(Vector3(0.0, 1.07, 0.0), Vector3(0.22, 0.2, 0.22))
		root.add_child(f.build(Color.WHITE, glow, true))
	return root


## A lotus leaf lying on the ink: a round pad with a notch, veins, its rim
## lifting a little. Centred at the origin, radius r.
static func lotus_leaf(b: PaperMesh, r: float, rng: RandomNumberGenerator) -> void:
	var sides := 16
	var notch := rng.randf() * TAU
	var centre := Vector3(0.0, 0.03, 0.0)
	for i in sides:
		var a0 := notch + 0.3 + (TAU - 0.6) * float(i) / sides
		var a1 := notch + 0.3 + (TAU - 0.6) * float(i + 1) / sides
		var r0 := r * rng.randf_range(0.93, 1.04)
		var r1 := r * rng.randf_range(0.93, 1.04)
		b.color = Color(0.2, 0.27, 0.21).darkened(rng.randf_range(0.0, 0.2))
		b.tri(centre, Vector3(cos(a0) * r0, 0.06, sin(a0) * r0), Vector3(cos(a1) * r1, 0.06, sin(a1) * r1), Vector3.UP)
	b.color = Color(0.32, 0.37, 0.28)
	for k in 7:
		var a := notch + 0.5 + TAU * 0.85 * k / 7.0
		b.box(Vector3(cos(a) * r * 0.45, 0.065, sin(a) * r * 0.45), Vector3(0.02, 0.005, 0.02) + Vector3(absf(cos(a)), 0.0, absf(sin(a))) * r * 0.85)
	b.color = Color(0.1, 0.12, 0.1)
	b.frustum(10, Vector2(r * 0.98, r * 0.98), Vector2(r, r), 0.03, Vector3(0.0, 0.0, 0.0))


## A thatched lean-to roof from x0 to x1: its low front eave at (front_y,
## front_z), up to (back_y, back_z); thick bundled straw, a ragged hem of
## loose straw hanging off the eave.
static func thatch(rng: RandomNumberGenerator, x0: float, x1: float, front_y: float, front_z: float, back_y: float, back_z: float) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.18
	var rows := 5
	for r in rows:
		var t0 := float(r) / rows
		var t1 := float(r + 1) / rows + 0.05
		var y0 := lerpf(front_y, back_y, t0)
		var y1 := lerpf(front_y, back_y, minf(t1, 1.0))
		var z0 := lerpf(front_z, back_z, t0)
		var z1 := lerpf(front_z, back_z, minf(t1, 1.0))
		# One bundled course of straw across the whole roof, its lower edge
		# a step (thatch is laid in overlapping courses).
		b.color = THATCH.darkened(0.06 * (r % 2) + rng.randf_range(0.0, 0.06))
		b.quad(Vector3(x0 - 0.3, y0 - 0.04, z0 + 0.06), Vector3(x1 + 0.3, y0 - 0.04, z0 + 0.06), Vector3(x1 + 0.3, y1 + 0.1, z1), Vector3(x0 - 0.3, y1 + 0.1, z1), Vector3.UP)
		b.color = THATCH_DARK
		b.quad(Vector3(x0 - 0.3, y0 - 0.12, z0 + 0.07), Vector3(x1 + 0.3, y0 - 0.12, z0 + 0.07), Vector3(x1 + 0.3, y0 - 0.02, z0 + 0.07), Vector3(x0 - 0.3, y0 - 0.02, z0 + 0.07), Vector3.BACK)
		# Straws: thin lines down the course, lighter and darker.
		var x := x0 - 0.25
		while x < x1 + 0.25:
			b.color = THATCH.lightened(0.12) if rng.randf() < 0.5 else THATCH_DARK.lightened(0.05)
			var dx := rng.randf_range(-0.04, 0.04)
			var a := Vector3(x, y0 - 0.03, z0 + 0.065)
			var c := Vector3(x + dx, y1 + 0.1, z1 + 0.005)
			var n := (c - a).cross(Vector3.RIGHT).normalized() * 0.006
			b.quad(a + n, a + n + Vector3(0.018, 0.0, 0.0), c + n + Vector3(0.018, 0.0, 0.0), c + n, Vector3.UP)
			x += rng.randf_range(0.05, 0.13)
	# The thick eave edge and its underside.
	b.color = THATCH_DARK
	b.box(Vector3((x0 + x1) * 0.5, front_y - 0.12, front_z - 0.15), Vector3(x1 - x0 + 0.7, 0.3, 0.4))
	b.color = Color(0.09, 0.08, 0.08)
	b.quad(Vector3(x0 - 0.3, front_y - 0.27, front_z), Vector3(x1 + 0.3, front_y - 0.27, front_z),
			Vector3(x1 + 0.3, back_y - 0.3, back_z), Vector3(x0 - 0.3, back_y - 0.3, back_z), Vector3.DOWN)
	# Loose straw hanging off the eave.
	b.color = THATCH.darkened(0.15)
	var x := x0 - 0.2
	while x < x1 + 0.2:
		var l := rng.randf_range(0.12, 0.35)
		b.tri(Vector3(x, front_y - 0.25, front_z + 0.02), Vector3(x + 0.07, front_y - 0.25, front_z + 0.02), Vector3(x + 0.03, front_y - 0.25 - l, front_z + 0.04), Vector3.BACK)
		x += rng.randf_range(0.06, 0.16)
	root.add_child(b.build())
	return root


## Dressed stone: a box whose front face (toward the camera, +z) is laid in
## courses of blocks with dark joints, weathered, with moss along its top
## and ink stains run down from it.
## `stains`: ink has run down it from the top (the marsh's stone only), soft
## trickles ending in a round drop (ink is liquid: never hard black strips).
static func masonry(b: PaperMesh, center: Vector3, size: Vector3, rng: RandomNumberGenerator, tone: Color = STONE, stains := true) -> void:
	b.color = tone.darkened(0.15)
	b.box(center, size)
	var front := center.z + size.z * 0.5 + 0.005
	var bottom := center.y - size.y * 0.5
	var top := center.y + size.y * 0.5
	var left := center.x - size.x * 0.5
	var right := center.x + size.x * 0.5
	var y := bottom
	var row := 0
	while y < top - 0.01:
		var y1 := minf(y + 0.48, top)
		var x := left + (0.35 if row % 2 == 1 else 0.0)
		if x > left:
			b.color = tone.darkened(rng.randf_range(0.0, 0.25))
			b.box(Vector3((left + x) * 0.5, (y + y1) * 0.5, front), Vector3(x - left - 0.03, y1 - y - 0.04, 0.01))
		while x < right - 0.01:
			var x1 := minf(x + rng.randf_range(0.6, 0.95), right)
			b.color = tone.darkened(rng.randf_range(-0.05, 0.25))
			b.box(Vector3((x + x1) * 0.5, (y + y1) * 0.5, front), Vector3(x1 - x - 0.03, y1 - y - 0.04, 0.01))
			x = x1
		y = y1
		row += 1
	b.color = MOSS
	b.box(Vector3(center.x, top + 0.01, center.z), Vector3(size.x + 0.02, 0.03, size.z + 0.02))
	if not stains:
		return
	for k in int(size.x / 1.6) + 1:
		var sx := rng.randf_range(left + 0.15, right - 0.15)
		var l := rng.randf_range(0.3, minf(1.4, size.y * 0.8))
		var w := rng.randf_range(0.035, 0.06)
		b.color = tone.darkened(0.55).lerp(Color(0.08, 0.08, 0.1), 0.4)
		# A trickle: widest at the lip, thinning, wavering a little as it runs.
		var pts := PackedVector2Array()
		var n := 6
		var wob := rng.randf() * TAU
		for i in n + 1:
			var t := float(i) / n
			pts.append(Vector2(sx + w * (1.0 - 0.6 * t) * 0.5 + 0.02 * sin(wob + t * 5.0), top - l * t))
		for i in range(n, -1, -1):
			var t := float(i) / n
			pts.append(Vector2(sx - w * (1.0 - 0.6 * t) * 0.5 + 0.02 * sin(wob + t * 5.0), top - l * t))
		b.polygon(pts, front + 0.006)
		# The drop gathering at its end.
		var drop := PackedVector2Array()
		var r := w * 0.7
		var dx := sx + 0.02 * sin(wob + 5.0)
		for i in 10:
			var a := TAU * i / 10.0
			drop.append(Vector2(dx + cos(a) * r, top - l - r * 0.6 + sin(a) * r * 1.2))
		b.polygon(drop, front + 0.007)


## A candle on a stick, glowing, its flame a soft blob.
static func candle(b: PaperMesh, glow: PaperMesh, at: Vector3, height: float = 0.22) -> void:
	b.color = Color(0.86, 0.8, 0.66)
	b.frustum(6, Vector2(0.035, 0.035), Vector2(0.032, 0.032), height, at)
	glow.color = CANDLE
	glow.frustum(6, Vector2(0.018, 0.018), Vector2(0.0, 0.0), 0.07, at + Vector3(0.0, height + 0.01, 0.0))
