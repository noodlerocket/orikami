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

## How far back the deck's posts stand (behind the stalls' awnings, the
## storehouse's roof and the bridge's back railing).
const POST_Z := -1.75
## Shop signs hang out over the street at these x: no post there.
const KEEP_CLEAR := [47.0, 50.4]

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
		# Down in the hole: on a canal walkway if there is one under it.
		for w: Array in Canals.WALKWAYS:
			if x > w[0] + 0.1 and x < w[1] - 0.1:
				return w[2]
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
		var front := 1.15 - _rng.randf_range(0.0, 0.12)
		b.box(Vector3((x + x1) * 0.5, top - 0.05, (front + POST_Z - 0.15) * 0.5), Vector3(x1 - x - 0.025, 0.1, front - POST_Z + 0.15))
		x = x1
	b.color = PaperMesh.TIMBER
	for z: float in [1.0, POST_Z]:
		b.box(Vector3((left + right) * 0.5, top - 0.2, z), Vector3(right - left + 0.2, 0.18, 0.16))
	# Posts down to whatever is below, all along the BACK of the deck (so
	# none stands in the street in front of him or runs through a stall, the
	# storehouse's roof or the bridge's railings), each stopping on what is
	# really under it: the street, a canal walkway, the river's bed. They step
	# aside for the shop signs. Joists carry the deck's front from them, and
	# knee braces stiffen them along the street.
	var posts := _post_spots(left, right)
	for px: float in posts:
		var foot := _foot(px)
		b.color = PaperMesh.TIMBER
		b.box(Vector3(px, (top - 0.25 + foot) * 0.5, POST_Z), Vector3(0.16, top - 0.25 - foot, 0.16))
		# A joist from the post out under the front beam.
		b.box(Vector3(px, top - 0.36, (POST_Z + 1.0) * 0.5), Vector3(0.12, 0.14, 1.0 - POST_Z + 0.1))
		# A strut up from the post to the joist's front end (seen from the
		# street as a short dark stroke under the deck).
		_strut(b, Vector3(px, top - 1.7, POST_Z), Vector3(px, top - 0.42, 0.9), 0.09)
		var brace := 1.0 if px < right - 1.0 else -1.0
		b.extrude(PackedVector2Array([Vector2(px - 0.06, top - 2.0), Vector2(px + 0.06, top - 2.0),
				Vector2(px + brace * 0.9, top - 0.3), Vector2(px + brace * 0.78, top - 0.3)]) if brace > 0.0 else
				PackedVector2Array([Vector2(px - 0.78, top - 0.3), Vector2(px - 0.9, top - 0.3),
				Vector2(px - 0.06, top - 2.0), Vector2(px + 0.06, top - 2.0)]), POST_Z - 0.05, POST_Z + 0.05)
		# Where it stands in water it is dark and slick at the waterline.
		if foot < 0.0:
			var water := Village.CANAL_WATER if px > Village.FALL_LEFT and px < Village.FALL_RIGHT else RiverBridge.WATER
			if foot < water:
				b.color = Canals.SLIME
				b.box(Vector3(px, water + 0.15, POST_Z), Vector3(0.18, 0.3, 0.18))
	b.color = PaperMesh.TIMBER.lightened(0.04)
	b.box(Vector3((left + right) * 0.5, top + 0.85, POST_Z), Vector3(right - left, 0.07, 0.07))
	b.box(Vector3((left + right) * 0.5, top + 0.4, POST_Z), Vector3(right - left, 0.05, 0.05))
	var rail := left + 0.05
	while rail < right:
		b.box(Vector3(rail, top + 0.42, POST_Z), Vector3(0.05, 0.85, 0.05))
		rail += 0.6
	add_child(b.build())
	match kind:
		"drying": _drying(left, right, top)
		"barrels": _barrels(left, right, top)
		"bell": _bell_frame(left, right, top)
		"broken": _broken_end(right, top)
		"laundry": _cloth(left, right, top)
		"far": _far_end(left, right, top)


## Where the posts go under a deck: at both ends and about every 3 m,
## nudged aside from the signs.
func _post_spots(left: float, right: float) -> Array[float]:
	var count := maxi(2, int(ceil((right - left - 0.3) / 3.0)) + 1)
	var spots: Array[float] = []
	for k in count:
		var px := lerpf(left + 0.15, right - 0.15, float(k) / (count - 1))
		for sign_x: float in KEEP_CLEAR:
			if absf(px - sign_x) < 0.5:
				px = sign_x + (0.5 if px >= sign_x and sign_x + 0.5 < right - 0.1 else -0.5)
		spots.append(px)
	return spots


## A square timber strut between two points (any direction).
func _strut(b: PaperMesh, from: Vector3, to: Vector3, width: float) -> void:
	var along := (to - from).normalized()
	var side := along.cross(Vector3.RIGHT).normalized() * width * 0.5
	var across := Vector3.RIGHT * width * 0.5
	var c := [from - side - across, from + side - across, from + side + across, from - side + across]
	var d := [to - side - across, to + side - across, to + side + across, to - side + across]
	for i in 4:
		var j := (i + 1) % 4
		b.quad(c[i], c[j], d[j], d[i])


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


## The burnt-out house over the Fallen Street: what is left of a two-storey
## house after a fire, every piece still holding on to something (Julian: the
## first version's pieces hung apart in the air). Charred posts stand on the
## canal boardwalk below; beams run between them along the back wall at each
## floor; each floor's boards lie on joists running out from those beams,
## their front ends burnt off (the front of the house has fallen); scorched
## plaster still fills parts of the back wall's bays, on its laths, torn where
## it burned; one rafter still climbs to the ridge with a few tiles on it, the
## other is burnt short; a fallen beam lies from the middle floor up against a
## post. He drops down through it, floor to floor.
func _ruin() -> void:
	var left := RUIN.x
	var right := RUIN.y
	var char_wood := Color(0.06, 0.05, 0.06)
	var burnt := Color(0.1, 0.08, 0.08)
	var back := -1.2
	# Floors he can stand on: [left, right, height].
	var floors := [[left, left + 2.9, 8.6], [right - 4.0, right, 4.6], [left, left + 2.4, 0.9]]
	# The posts along the back wall: [x, top].
	var posts := [[left + 0.1, 9.4], [left + 2.95, 8.75], [right - 4.05, 5.7], [right - 0.1, 9.4]]
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.25
	b.color = char_wood
	for post: Array in posts:
		var px: float = post[0]
		var top: float = post[1]
		var stand := _foot(px)  # (on the canal walkway under it)
		b.box(Vector3(px, (stand + top) * 0.5, back), Vector3(0.2, top - stand, 0.2))
		# A burnt, splintered top where it stops short of the roof.
		if top < 9.3:
			b.extrude(PackedVector2Array([Vector2(px - 0.1, top), Vector2(px + 0.1, top), Vector2(px + 0.03, top + 0.28),
					Vector2(px - 0.04, top + 0.12)]), back - 0.1, back + 0.1)
	# Two stubs of the fallen front: posts burnt off low.
	for stub: Array in [[left + 0.1, 1.9], [right - 0.1, 3.0]]:
		var px: float = stub[0]
		var top: float = stub[1]
		var stand := _foot(px)
		b.box(Vector3(px, (stand + top) * 0.5, 1.05), Vector3(0.18, top - stand, 0.18))
		b.extrude(PackedVector2Array([Vector2(px - 0.09, top), Vector2(px + 0.09, top), Vector2(px, top + 0.3)]), 0.96, 1.14)
	# Beams along the back wall, post to post: at each floor, and a rail
	# half-way up each storey, and the top plate under the roof.
	var beams := [
		[left + 0.1, left + 2.95, 0.9], [left + 0.1, left + 2.95, 4.6], [left + 0.1, left + 2.95, 8.6],
		[right - 4.05, right - 0.1, 0.9], [right - 4.05, right - 0.1, 4.6],
		[left + 0.1, left + 2.95, 2.75], [right - 4.05, right - 0.1, 2.75],
		[left + 0.1, left + 2.95, 6.6], [left - 0.3, left + 3.4, 9.4], [right - 2.2, right + 0.3, 9.4],
	]
	for beam: Array in beams:
		b.box(Vector3((beam[0] + beam[1]) * 0.5, beam[2] - 0.08, back), Vector3(beam[1] - beam[0] + 0.1, 0.16, 0.18))
	# Each floor's joists, from the back beam out under the boards, burnt off
	# at the front.
	for f: Array in floors:
		var x: float = f[0] + 0.12
		while x < f[1] - 0.05:
			var reach := _rng.randf_range(1.6, 2.15)
			b.box(Vector3(x, f[2] - 0.2, back + reach * 0.5), Vector3(0.12, 0.14, reach))
			b.color = burnt
			b.box(Vector3(x, f[2] - 0.2, back + reach + 0.06), Vector3(0.1, 0.1, 0.12))
			b.color = char_wood
			x += 0.62
	# The boards on them, their front ends uneven and charred.
	for f: Array in floors:
		village._add_solid(Vector3((f[0] + f[1]) * 0.5, f[2] - 0.12, 0.0), Vector3(f[1] - f[0], 0.24, 2.2))
		var x: float = f[0]
		while x < f[1] - 0.01:
			var x1 := minf(x + _rng.randf_range(0.22, 0.34), f[1])
			var front := 1.0 - _rng.randf_range(0.0, 0.45)
			b.color = Scenery.WOOD.darkened(_rng.randf_range(0.35, 0.6))
			b.box(Vector3((x + x1) * 0.5, f[2] - 0.06, (back + front) * 0.5), Vector3(x1 - x - 0.02, 0.1, front - back))
			b.color = burnt
			b.box(Vector3((x + x1) * 0.5, f[2] - 0.06, front + 0.03), Vector3(x1 - x - 0.02, 0.09, 0.07))
			x = x1
		b.color = char_wood
	# Laths across the burnt-open bays, top beam to bottom beam.
	for bay: Array in [[left + 0.1, left + 2.95, 4.6, 8.6], [right - 4.05, right - 0.1, 0.9, 4.6], [left + 0.1, left + 2.95, 0.9, 4.6]]:
		var lx: float = bay[0] + 0.45
		while lx < bay[1] - 0.3:
			b.box(Vector3(lx, (bay[2] + bay[3]) * 0.5, back - 0.06), Vector3(0.05, bay[3] - bay[2] - 0.16, 0.04))
			lx += _rng.randf_range(0.55, 0.8)
	# The roof: the left rafter whole, from the top plate to the ridge; the
	# right one burnt short; a stub of ridge.
	var ridge := Vector2((left + right) * 0.5 - 0.6, 11.0)
	b.extrude(PackedVector2Array([Vector2(left - 0.25, 9.3), Vector2(left - 0.1, 9.42), Vector2(ridge.x + 0.06, ridge.y + 0.06),
			Vector2(ridge.x - 0.06, ridge.y - 0.1)]), back - 0.1, back + 0.1)
	var stub_end := Vector2(right - 2.2, lerpf(9.4, ridge.y, 2.0 / (right + 0.25 - ridge.x)))
	b.extrude(PackedVector2Array([Vector2(right + 0.25, 9.3), Vector2(right + 0.1, 9.42), stub_end + Vector2(0.0, 0.1), stub_end + Vector2(0.05, -0.06)]),
			back - 0.1, back + 0.1)
	b.box(Vector3(ridge.x, ridge.y + 0.02, back + 0.2), Vector3(0.18, 0.18, 0.8))
	# A few tiles still on the left rafter, lying along its slope.
	b.color = Scenery.ROOF.darkened(0.2)
	for k in 6:
		var t := 0.15 + k * 0.13 + _rng.randf_range(-0.03, 0.03)
		var at := Vector2(lerpf(left - 0.1, ridge.x, t), lerpf(9.42, ridge.y, t))
		var slope := Vector2(ridge.x - left, ridge.y - 9.42).normalized()
		var up := slope.orthogonal() * -1.0
		if up.y < 0.0:
			up = -up
		b.extrude(PackedVector2Array([at - slope * 0.22, at + slope * 0.22, at + slope * 0.22 + up * 0.07, at - slope * 0.22 + up * 0.07]),
				back - 0.05 - _rng.randf_range(0.0, 0.4), back + 0.35 + _rng.randf_range(0.0, 0.3))
	# The fallen beam: its foot on the middle floor, its head against the
	# post that held the top floor.
	b.color = char_wood
	var foot := Vector2(right - 2.6, 4.6)
	var head := Vector2(left + 3.07, 7.2)
	var along := (head - foot).normalized()
	var side := along.orthogonal() * 0.09
	b.extrude(PackedVector2Array([foot - side, foot + side, head + side, head - side]), back + 0.1, back + 0.28)
	add_child(b.build())
	# Scorched plaster still on the wall: each piece fills part of a bay,
	# held along the bay's frame (posts and beams) and torn where it burned.
	var plaster := PaperMesh.new(_rng.randi())
	plaster.shade_jitter = 0.08
	plaster.color = Color(0.32, 0.3, 0.3)
	var patches := [
		# [bay left, bay right, bay bottom, bay top, which corner it clings to]
		[left + 0.2, left + 2.85, 4.68, 6.52, "low_left"],
		[right - 3.95, right - 0.2, 0.98, 2.67, "low_right"],
		[right - 3.95, right - 0.2, 2.83, 4.52, "high_right"],
	]
	for patch: Array in patches:
		var l: float = patch[0]
		var r: float = patch[1]
		var lo: float = patch[2]
		var hi: float = patch[3]
		var outline := PackedVector2Array()
		match patch[4]:
			"low_left":
				outline = PackedVector2Array([Vector2(l, lo), Vector2(r, lo), Vector2(r, lo + 0.5), Vector2(l + 1.6, lo + 0.9),
						Vector2(l + 0.7, hi - 0.2), Vector2(l, hi)])
			"low_right":
				outline = PackedVector2Array([Vector2(l, lo), Vector2(r, lo), Vector2(r, hi), Vector2(r - 1.2, hi),
						Vector2(r - 2.0, lo + 0.9), Vector2(l + 0.6, lo + 0.6), Vector2(l, lo + 0.5)])
			_:
				outline = PackedVector2Array([Vector2(r - 1.6, lo), Vector2(r, lo), Vector2(r, hi), Vector2(r - 2.4, hi),
						Vector2(r - 1.9, hi - 0.6)])
		# (Torn only along its free edges: the edges on the frame stay straight.)
		plaster.torn_sheet(PaperMesh.tear(outline, 0.18, 0.06, _rng), back - 0.1, Color(0.08, 0.07, 0.08), 0.05)
	add_child(plaster.build())
	# A torn shoji panel still standing on the top floor against the back
	# wall, faintly lit by a lantern someone left hung from the rafter.
	var shoji := PaperMesh.new(_rng.randi())
	shoji.color = PaperMesh.WASHI.darkened(0.35)
	shoji.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(left + 0.5, 8.6), Vector2(left + 1.6, 8.6), Vector2(left + 1.6, 9.35),
			Vector2(left + 1.1, 9.38), Vector2(left + 0.5, 9.3)]), 0.2, 0.06, _rng), back + 0.2, Color(0.12, 0.1, 0.1), 0.04)
	add_child(shoji.build(Color(1.0, 0.85, 0.7), 0.4))
	village._hang_lantern(Vector3(left + 2.2, lerpf(9.42, ridge.y, (left + 2.2 - left + 0.1) / (ridge.x - left + 0.1)) - 0.05, back + 0.05), 0.3, 0.55, false)


func _process(delta: float) -> void:
	if _bell == null:
		return
	# The bell swings as a pendulum and settles.
	_bell_speed += (-_bell_swing * 14.0 - _bell_speed * 1.2) * delta
	_bell_swing += _bell_speed * delta
	_bell.rotation.z = _bell_swing * 0.35 + sin(Wind.now() * 1.3) * 0.015 * Wind.speed_at(_bell.global_position.x)
