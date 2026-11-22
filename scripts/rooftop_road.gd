class_name RooftopRoad
extends Node3D
## The Rooftop Road (docs/village_map.png), over Market Street, the Fallen
## Street and the river: the town's rooftop drying decks (monohoshi), wooden
## platforms on tall posts above the roofs, joined by jumps. He gets up from
## the second gallery's roof (or, once he has kicked it down, by the ladder
## at the end of Market Street).
##  - over the Fallen Street, a burnt-out house: what is left of its floors
##    is a way to drop down through it toward the canals;
##  - over the river the decks stand on poles in the water, until a gap far
##    too wide to jump: the first Crane Glide gate. The decks beyond it can
##    be seen, out of reach.
## Each deck has its own life: sheets of paper drying, rain barrels, the
## fire-watch bell (cut it and it rings), a tattered awning.

## [left x, right x, top, what is on it]
const DECKS := [
	[47.0, 52.4, 6.9, "drying"], [53.4, 60.0, 7.6, "barrels"], [62.6, 68.2, 8.2, "bell"],
	[95.0, 97.6, 6.6, "broken"], [107.0, 112.4, 7.0, "laundry"], [114.6, 119.4, 6.4, "far"]]
## The burnt-out house over the Fallen Street: its left and right x.
const RUIN := Vector2(70.2, 78.6)
## The gap too wide to jump (the Crane Glide gate).
const GLIDE_GAP := Vector2(97.6, 107.0)

var village: Village
var ladder: Ladder
var _rng := RandomNumberGenerator.new()
var _bell: Node3D
var _bell_swing := 0.0
var _bell_speed := 0.0


func _ready() -> void:
	_rng.seed = 7311
	for d: Array in DECKS:
		_deck(d[0], d[1], d[2], d[3])
	_ruin()
	ladder = Ladder.new()
	ladder.height = 7.6
	ladder.step_off = -1.0
	ladder.position = Vector3(60.35, 0.0, 0.0)
	add_child(ladder)


## What the posts under x stand on: the street, the canal's floor (in the
## Fallen Street's hole) or the river's bed.
func _foot(x: float) -> float:
	if x > Village.FALL_LEFT and x < Village.FALL_RIGHT:
		return Canals.FLOOR
	if x > Village.RIVER.x and x < Village.RIVER.y:
		return RiverBridge.BED
	return 0.0


func _deck(left: float, right: float, top: float, kind: String) -> void:
	village._add_solid(Vector3((left + right) * 0.5, top - 0.15, 0.0), Vector3(right - left, 0.3, 2.2))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	# Boards across, on two beams.
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + _rng.randf_range(0.2, 0.3), right)
		b.color = Scenery.WOOD.darkened(_rng.randf_range(0.1, 0.35))
		b.box(Vector3((x + x1) * 0.5, top - 0.05, 0.0), Vector3(x1 - x - 0.025, 0.1, 2.3 - _rng.randf_range(0.0, 0.12)))
		x = x1
	b.color = PaperMesh.TIMBER
	for z: float in [1.0, -1.0]:
		b.box(Vector3((left + right) * 0.5, top - 0.2, z), Vector3(right - left + 0.2, 0.18, 0.16))
	# Posts down to whatever is below, braced; a railing along the back.
	var posts: Array[float] = [left + 0.15]
	while posts[posts.size() - 1] + 2.6 < right - 0.6:
		posts.append(posts[posts.size() - 1] + 2.6)
	posts.append(right - 0.15)
	for px: float in posts:
		var foot := _foot(px)
		# (Over the Fallen Street's hole only the back posts reach down, so
		# none stands in front of him when he is down in the canals.)
		for pz: float in ([-1.15] if foot == Canals.FLOOR else [1.15, -1.15]):
			b.box(Vector3(px, (top - 0.25 + foot) * 0.5, pz), Vector3(0.15, top - 0.25 - foot, 0.15))
		b.extrude(PackedVector2Array([Vector2(px - 0.06, top - 2.2), Vector2(px + 0.06, top - 2.2),
				Vector2(px + 0.9, top - 0.3), Vector2(px + 0.78, top - 0.3)]) if px < right - 1.0 else
				PackedVector2Array([Vector2(px - 0.78, top - 0.3), Vector2(px - 0.9, top - 0.3),
				Vector2(px - 0.06, top - 2.2), Vector2(px + 0.06, top - 2.2)]), -1.2, -1.1)
	b.color = PaperMesh.TIMBER.lightened(0.04)
	b.box(Vector3((left + right) * 0.5, top + 0.85, -1.1), Vector3(right - left, 0.07, 0.07))
	b.box(Vector3((left + right) * 0.5, top + 0.4, -1.1), Vector3(right - left, 0.05, 0.05))
	var rail := left + 0.05
	while rail < right:
		b.box(Vector3(rail, top + 0.42, -1.1), Vector3(0.05, 0.85, 0.05))
		rail += 0.6
	# Where the posts stand in water, they are dark and slick at the waterline.
	if _foot(left + 0.5) < 0.0:
		b.color = Canals.SLIME
		var water := Village.CANAL_WATER if _foot(left + 0.5) == Canals.FLOOR else RiverBridge.WATER
		for px: float in posts:
			for pz: float in [1.15, -1.15]:
				b.box(Vector3(px, water + 0.15, pz), Vector3(0.17, 0.3, 0.17))
	add_child(b.build())
	match kind:
		"drying": _drying(left, right, top)
		"barrels": _barrels(left, right, top)
		"bell": _bell_frame(left, right, top)
		"broken": _broken_end(right, top)
		"laundry": _cloth(left, right, top)
		"far": _far_end(left, right, top)


## Sheets of fresh paper pegged on a line along the back, drying; each
## stirs on its own in the wind.
func _drying(left: float, right: float, top: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.color = PaperMesh.TIMBER
	for px: float in [left + 0.4, right - 0.4]:
		b.box(Vector3(px, top + 0.9, -0.8), Vector3(0.08, 1.8, 0.08))
	b.color = Color(0.4, 0.36, 0.3)
	b.box(Vector3((left + right) * 0.5, top + 1.72, -0.8), Vector3(right - left - 0.8, 0.025, 0.025))
	add_child(b.build())
	var x := left + 0.75
	while x < right - 0.7:
		var hang := Node3D.new()
		hang.position = Vector3(x, top + 1.7, -0.78)
		add_child(hang)
		var sheet := PaperMesh.new(_rng.randi())
		sheet.color = PaperMesh.WASHI.darkened(_rng.randf_range(0.05, 0.2))
		sheet.shade_jitter = 0.04
		var w := _rng.randf_range(0.45, 0.6)
		sheet.rect(Vector2(w * 0.5, -0.38), Vector2(w, 0.72), 0.0)
		sheet.color = Color(0.2, 0.2, 0.25)
		for peg: float in [0.06, w - 0.06]:
			sheet.rect(Vector2(peg, -0.02), Vector2(0.03, 0.07), 0.01)
		hang.add_child(sheet.build())
		Scenery.windswept(hang, 0.06, _rng)
		x += w + _rng.randf_range(0.1, 0.25)


## Rain barrels at the back, full and overflowing, a bucket, a pot.
func _barrels(left: float, right: float, top: float) -> void:
	for bx: float in [left + 0.7, left + 1.6]:
		var barrel := Scenery.barrel(_rng, 0.85)
		barrel.position = Vector3(bx, top, -0.7)
		add_child(barrel)
	var b := PaperMesh.new(_rng.randi())
	b.color = Scenery.WOOD.darkened(0.2)
	b.frustum(8, Vector2(0.16, 0.16), Vector2(0.2, 0.2), 0.3, Vector3(right - 1.6, top, -0.6))
	b.color = Color(0.36, 0.24, 0.18)
	b.frustum(8, Vector2(0.14, 0.14), Vector2(0.18, 0.18), 0.24, Vector3(right - 1.0, top, -0.75))
	b.color = Color(0.22, 0.3, 0.2)
	for k in 5:
		b.ellipse(Vector2(right - 1.0 + _rng.randf_range(-0.12, 0.12), top + 0.35 + _rng.randf_range(0.0, 0.2)),
				Vector2(0.09, 0.05), 6, -0.55 + k * 0.003, 0.2)
	add_child(b.build())


## The fire-watch bell in its frame: struck by the sword, it rings and swings.
func _bell_frame(left: float, right: float, top: float) -> void:
	var cx := (left + right) * 0.5 + 0.8
	var b := PaperMesh.new(_rng.randi())
	b.color = PaperMesh.TIMBER
	for px: float in [cx - 0.75, cx + 0.75]:
		b.box(Vector3(px, top + 1.2, -0.55), Vector3(0.12, 2.4, 0.12))
	b.box(Vector3(cx, top + 2.35, -0.55), Vector3(1.8, 0.14, 0.16))
	# A small roof over it.
	b.color = Scenery.ROOF
	b.quad(Vector3(cx - 1.0, top + 2.45, 0.0), Vector3(cx + 1.0, top + 2.45, 0.0), Vector3(cx + 1.0, top + 2.8, -0.55),
			Vector3(cx - 1.0, top + 2.8, -0.55), Vector3(0.0, 1.0, 0.6))
	b.quad(Vector3(cx + 1.0, top + 2.45, -1.1), Vector3(cx - 1.0, top + 2.45, -1.1), Vector3(cx - 1.0, top + 2.8, -0.55),
			Vector3(cx + 1.0, top + 2.8, -0.55), Vector3(0.0, 1.0, -0.6))
	add_child(b.build())
	_bell = Node3D.new()
	_bell.position = Vector3(cx, top + 2.28, -0.55)
	add_child(_bell)
	var bell := PaperMesh.new(_rng.randi())
	bell.shade_jitter = 0.1
	bell.texture_world = false
	bell.color = Color(0.3, 0.3, 0.26)  # old bronze, gone dark
	bell.box(Vector3(0.0, -0.05, 0.0), Vector3(0.05, 0.1, 0.05))
	bell.frustum(10, Vector2(0.2, 0.2), Vector2(0.14, 0.14), 0.55, Vector3(0.0, -0.66, 0.0))
	bell.color = Color(0.22, 0.24, 0.2)
	bell.frustum(10, Vector2(0.22, 0.22), Vector2(0.21, 0.21), 0.06, Vector3(0.0, -0.68, 0.0))
	_bell.add_child(bell.build())
	var target := PropTarget.make(self, BoxShape3D.new(), Vector3(cx, top + 1.85, 0.0))
	((target.get_child(0) as CollisionShape3D).shape as BoxShape3D).size = Vector3(0.7, 0.8, 2.0)
	target.struck.connect(func(direction: Vector2) -> void:
		_bell_speed += 2.6 * (direction.x if direction.x != 0.0 else 1.0)
		Sound.play(self, &"fire_bell"))


## The deck's broken end over the river, splintered, a torn awning hanging.
func _broken_end(right: float, top: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.color = Scenery.WOOD.darkened(0.3)
	for k in 4:
		var z := _rng.randf_range(-0.9, 0.9)
		var reach := _rng.randf_range(0.2, 0.7)
		b.extrude(PackedVector2Array([Vector2(right - 0.1, top - 0.1), Vector2(right + reach, top - 0.1 - reach * 0.4),
				Vector2(right + reach - 0.06, top - reach * 0.3), Vector2(right - 0.1, top)]), z - 0.11, z + 0.11)
	add_child(b.build())
	var hang := Node3D.new()
	hang.position = Vector3(right - 0.9, top + 1.9, -0.9)
	add_child(hang)
	var cloth := PaperMesh.new(_rng.randi())
	cloth.color = Color(0.3, 0.33, 0.46)
	cloth.polygon(PackedVector2Array([Vector2(-0.6, 0.0), Vector2(0.5, 0.0), Vector2(0.45, -0.6), Vector2(0.2, -1.1),
			Vector2(0.05, -0.7), Vector2(-0.2, -1.3), Vector2(-0.35, -0.6), Vector2(-0.6, -0.5)]))
	hang.add_child(cloth.build())
	Scenery.windswept(hang, 0.07, _rng)
	var pole := PaperMesh.new(_rng.randi())
	pole.color = PaperMesh.TIMBER
	pole.box(Vector3(right - 0.9, top + 0.95, -0.95), Vector3(0.08, 1.9, 0.08))
	add_child(pole.build())


## A strip of cloth drying, on the far side of the gap.
func _cloth(left: float, right: float, top: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.color = PaperMesh.TIMBER
	for px: float in [left + 0.6, right - 0.6]:
		b.box(Vector3(px, top + 0.9, -0.8), Vector3(0.07, 1.8, 0.07))
	b.box(Vector3((left + right) * 0.5, top + 1.75, -0.8), Vector3(right - left - 1.1, 0.04, 0.04))
	add_child(b.build())
	for k in 3:
		var hang := Node3D.new()
		hang.position = Vector3(left + 1.2 + k * 1.4, top + 1.73, -0.78)
		add_child(hang)
		var cloth := PaperMesh.new(_rng.randi())
		cloth.color = [Color(0.25, 0.28, 0.42), Color(0.5, 0.47, 0.42), Color(0.36, 0.22, 0.2)][k]
		cloth.rect(Vector2(0.0, -0.5), Vector2(0.55, 1.0), 0.0)
		hang.add_child(cloth.build())
		Scenery.windswept(hang, 0.07, _rng)


## The far end: a lantern still lit on a post, so the decks past the gap
## catch the eye from the other side.
func _far_end(left: float, right: float, top: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.color = PaperMesh.TIMBER
	b.box(Vector3(right - 0.3, top + 1.0, -0.9), Vector3(0.09, 2.0, 0.09))
	b.box(Vector3(right - 0.6, top + 1.95, -0.9), Vector3(0.65, 0.07, 0.07))
	add_child(b.build())
	village._hang_lantern(Vector3(right - 0.85, top + 1.92, -0.9), 0.2, 0.7, false)


## The burnt-out house over the Fallen Street: blackened posts and beams,
## the roof's skeleton with a few tiles hanging on, scorched plaster, and
## what is left of its floors: a top floor at the left, a middle floor at
## the right, a low floor just over the hole. You drop down through it.
func _ruin() -> void:
	var left := RUIN.x
	var right := RUIN.y
	var foot := Canals.FLOOR
	var char_wood := Color(0.06, 0.05, 0.06)
	# Floors he can stand on: [left, right, height].
	var floors := [[left, left + 2.9, 8.6], [right - 4.0, right, 4.6], [left, left + 2.4, 0.9]]
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.25
	for f: Array in floors:
		village._add_solid(Vector3((f[0] + f[1]) * 0.5, f[2] - 0.12, 0.0), Vector3(f[1] - f[0], 0.24, 2.2))
		var x: float = f[0]
		while x < f[1] - 0.01:
			var x1 := minf(x + _rng.randf_range(0.22, 0.34), f[1])
			b.color = Scenery.WOOD.darkened(_rng.randf_range(0.35, 0.6))
			b.box(Vector3((x + x1) * 0.5, f[2] - 0.06, 0.0), Vector3(x1 - x - 0.02, 0.1, 2.2 - _rng.randf_range(0.0, 0.4)))
			x = x1
		# Its broken edge: charred board ends sticking out.
		var edge: float = f[1] if f[0] == left else f[0]
		var out := 1.0 if f[0] == left else -1.0
		b.color = char_wood
		for k in 3:
			var z := _rng.randf_range(-0.8, 0.8)
			b.box(Vector3(edge + out * _rng.randf_range(0.1, 0.35), f[2] - 0.06 - _rng.randf_range(0.0, 0.1), z), Vector3(0.4, 0.08, 0.22))
		b.color = char_wood
		b.box(Vector3((f[0] + f[1]) * 0.5, f[2] - 0.24, 1.05), Vector3(f[1] - f[0], 0.18, 0.15))
	# Corner posts, charred, from the canal floor to the roof, at front and back.
	b.color = char_wood
	for px: float in [left + 0.1, right - 0.1, (left + right) * 0.5]:
		for pz: float in [-1.2]:  # (the front of the house has fallen)
			var top := 9.4 if px != (left + right) * 0.5 else 6.2  # the middle one has burnt through
			b.box(Vector3(px, (foot + top) * 0.5, pz), Vector3(0.18, top - foot, 0.18))
	# The roof's skeleton: rafters from the walls up to a ridge, a few tiles.
	var ridge := Vector2((left + right) * 0.5 - 1.2, 11.0)
	for k in 6:
		var rx := lerpf(left - 0.3, right + 0.3, k / 5.0)
		if k == 3:
			continue  # fallen in
		b.extrude(PackedVector2Array([Vector2(rx - 0.06, 9.4), Vector2(rx + 0.06, 9.4), Vector2(ridge.x + 0.05, ridge.y), Vector2(ridge.x - 0.05, ridge.y)]), -1.3, -1.1)
	b.box(Vector3((left + ridge.x) * 0.5, 9.45, -1.2), Vector3(ridge.x - left + 0.4, 0.14, 0.16))
	b.color = Scenery.ROOF.darkened(0.2)
	for k in 7:
		var t := _rng.randf_range(0.1, 0.6)
		var at := Vector2(lerpf(left, ridge.x, t), lerpf(9.4, ridge.y, t))
		b.extrude(PackedVector2Array([at + Vector2(-0.22, -0.02), at + Vector2(0.22, 0.1), at + Vector2(0.2, 0.2), at + Vector2(-0.24, 0.08)]),
				-1.6 + _rng.randf_range(0.0, 0.6), -0.9 + _rng.randf_range(0.0, 0.6))
	# What is left of the back wall's frame: charred rails between the posts,
	# a few laths, for the scorched plaster to cling to.
	b.color = char_wood
	for rail: Array in [[left + 0.1, (left + right) * 0.5, 5.2], [left + 0.1, (left + right) * 0.5, 7.9],
			[(left + right) * 0.5, right - 0.1, 1.7], [(left + right) * 0.5, right - 0.1, 4.3]]:
		b.box(Vector3((rail[0] + rail[1]) * 0.5, rail[2], -1.3), Vector3(rail[1] - rail[0], 0.14, 0.1))
	for lath: float in [left + 1.0, left + 2.1, right - 2.4, right - 1.2]:
		var low := 5.2 if lath < (left + right) * 0.5 else 1.7
		b.box(Vector3(lath, low + 1.3, -1.32), Vector3(0.06, 2.6, 0.05))
	# Scorched plaster still on the back wall, torn, black at the edges.
	b.color = Color(0.32, 0.3, 0.3)
	b.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(left + 0.3, 7.6), Vector2(left + 2.6, 8.1), Vector2(left + 3.3, 6.0),
			Vector2(left + 2.0, 5.1), Vector2(left + 0.4, 5.6)]), 0.3, 0.12, _rng), -1.25, Color(0.08, 0.07, 0.08), 0.06)
	b.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(right - 3.2, 3.9), Vector2(right - 0.3, 4.2), Vector2(right - 0.4, 1.6),
			Vector2(right - 2.6, 2.2)]), 0.3, 0.12, _rng), -1.25, Color(0.08, 0.07, 0.08), 0.06)
	# A fallen beam leaning across, inside.
	b.color = char_wood
	b.extrude(PackedVector2Array([Vector2(left + 3.1, 4.8), Vector2(left + 3.3, 4.7), Vector2(right - 1.0, 8.7), Vector2(right - 1.2, 8.8)]), -0.95, -0.75)
	add_child(b.build())
	# A torn shoji panel still standing on the top floor, faintly lit from a
	# lantern someone left up here.
	var shoji := PaperMesh.new(_rng.randi())
	shoji.color = PaperMesh.WASHI.darkened(0.35)
	shoji.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(left + 0.5, 8.6), Vector2(left + 1.6, 8.6), Vector2(left + 1.6, 9.9),
			Vector2(left + 1.1, 10.2), Vector2(left + 0.5, 9.7)]), 0.2, 0.06, _rng), -0.95, Color(0.12, 0.1, 0.1), 0.04)
	add_child(shoji.build(Color(1.0, 0.85, 0.7), 0.4))
	village._hang_lantern(Vector3(left + 2.2, 10.2, -0.5), 0.3, 0.55, false)


func _process(delta: float) -> void:
	if _bell == null:
		return
	# The bell swings as a pendulum and settles.
	_bell_speed += (-_bell_swing * 14.0 - _bell_speed * 1.2) * delta
	_bell_swing += _bell_speed * delta
	_bell.rotation.z = _bell_swing * 0.35 + sin(Wind.now() * 1.3) * 0.015 * Wind.speed_at(_bell.global_position.x)
