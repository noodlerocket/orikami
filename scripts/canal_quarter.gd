class_name CanalQuarter
extends Node3D
## The Lantern Market's second stretch (docs/lantern_market_plan.md, areas 4
## and 5), built on from the steps:
##  - Festival Square (to SQUARE_END, on the plaza at 6.5 m): the first
##    crossroads. A drum tower (yagura) hung with lanterns, and the empty
##    racks the festival dragon hung from in the parades, torn and clawed
##    (the dragon is loose in the Ward beyond: the mini-boss, not built
##    yet). A lantern hoist rides up to the high walkways.
##  - The Canal Quarter: stairs down to stone quays, deep canals between
##    them crossed on drifting lantern boats (LanternBoat) or by hopping
##    along pilings; falling in carries him back to the last shrine. Above,
##    the high route: red walkways for jumping and gliding. Floating paper
##    lanterns drift on the water; a gold-leaf workshop on the middle quay
##    has cranes; stairs climb to the teahouse bank, shrine 7.
##  - The Ward's gate (WARD_GATE): shut, pasted over with paper charms.
## Built in the market's own coordinates (a child of it at its origin), with
## its helpers (market._gallery, _booth, _hang...).

const SQUARE_END := 146.0
## Stairs down to the first quay, and up to the teahouse bank.
const STAIRS_DOWN := Vector2(146.0, 152.0)
const STAIRS_UP := Vector2(196.0, 202.0)
## The quays: [left, right], all at QUAY_Y.
const QUAYS := [Vector2(152.0, 158.0), Vector2(168.0, 176.0), Vector2(190.0, 196.0)]
const QUAY_Y := 3.0
## The canals between the quays: water surface, and how deep they are.
const WATERS := [Vector2(158.0, 168.0), Vector2(176.0, 190.0)]
const WATER_Y := 2.0
const BED_Y := -1.5
## Pilings to hop along in the second canal: [x, top].
const PILINGS := [Vector2(180.5, 3.3), Vector2(185.5, 3.3)]
## The teahouse bank, and the Ward's gate at its end.
const BANK := Vector2(202.0, 216.0)
const BANK_Y := 6.5
const WARD_GATE := 214.0
const SHRINE_X := 205.5
## The lantern hoist (x), and the walkways of the high route: [middle, top, width].
const HOIST_X := 144.4
const HOIST_RANGE := Vector2(6.55, 10.0)
const WALKWAYS := [[150.0, 10.0, 8.0], [164.0, 10.5, 7.0], [180.0, 10.0, 8.0], [194.0, 10.5, 7.0]]
const DOGS := [Vector2(172.0, 3.0)]
const HUSKS := [Vector2(155.0, 3.0)]
const LANTERN_HUSKS := [Vector2(193.0, 3.0)]

var market: LanternMarket
var _rng := RandomNumberGenerator.new()
var _floaters: Array[Node3D] = []
var _ronin: Ronin
var _gate_door: Node3D
var _gate_wall: StaticBody3D
var _gate_target: PropTarget
var _charms: Array[Node3D] = []
var _hint: ActionHint


## Height of the ground (or of the water, over a canal) at a market x past
## the square.
static func ground_at(x: float) -> float:
	if x < STAIRS_DOWN.y:
		return lerpf(LanternMarket.PLAZA.z, QUAY_Y, clampf((x - STAIRS_DOWN.x) / (STAIRS_DOWN.y - STAIRS_DOWN.x), 0.0, 1.0))
	if x >= STAIRS_UP.x and x <= STAIRS_UP.y:
		return lerpf(QUAY_Y, BANK_Y, (x - STAIRS_UP.x) / (STAIRS_UP.y - STAIRS_UP.x))
	if x > STAIRS_UP.y:
		return BANK_Y
	for w: Vector2 in WATERS:
		if x > w.x and x < w.y:
			return WATER_Y
	return QUAY_Y


func _ready() -> void:
	_rng.seed = 4407
	_build_square()
	_build_stairs(STAIRS_DOWN, LanternMarket.PLAZA.z, QUAY_Y)
	_build_stairs(STAIRS_UP, QUAY_Y, BANK_Y)
	for q: Vector2 in QUAYS:
		_quay(q.x, q.y, QUAY_Y)
	_quay(BANK.x, BANK.y + 2.0, BANK_Y)
	for w: Vector2 in WATERS:
		_canal(w.x, w.y)
	for p: Vector2 in PILINGS:
		_piling(p.x, p.y)
	# A boat across the first canal. (The second is crossed on its pilings:
	# a boat there sailed through them.)
	for b: Array in [[159.8, 166.2]]:
		var boat := LanternBoat.new()
		boat.from_x = b[0]
		boat.to_x = b[1]
		boat.position = Vector3(b[0], WATER_Y - 0.05, 0.0)
		add_child(boat)
	_canal_houses()
	# The gold-leaf workshop on the middle quay, its cranes behind the counter.
	market._booth(172.0, "fans", Color(0.6, 0.48, 0.24))
	var bundle := CraneBundle.new()
	bundle.id = "market_workshop"
	bundle.count = 6
	bundle.position = Vector3(174.6, QUAY_Y, 0.0)
	add_child(bundle)
	_build_high_route()
	_build_teahouse()
	_build_ward_gate()
	_floating_lanterns()
	var ward := WardQuarter.new()
	ward.market = market
	ward.quarter = self
	add_child(ward)
	for spot: Vector2 in DOGS:
		var dog := PaperDog.new()
		dog.position = Vector3(spot.x, spot.y, 0.0)
		add_child(dog)
	for spot: Vector2 in HUSKS:
		var husk: Node3D = Village.HUSK_SCENE.instantiate()
		husk.position = Vector3(spot.x, spot.y, 0.0)
		add_child(husk)
	for spot: Vector2 in LANTERN_HUSKS:
		var keeper := LanternHusk.new()
		keeper.position = Vector3(spot.x, spot.y, 0.0)
		add_child(keeper)
	Sound.place_loop(self, "river_flow.ogg", Vector3(165.0, WATER_Y, -1.0), -12.0, 14.0)
	Sound.place_loop(self, "river_flow.ogg", Vector3(184.0, WATER_Y, -1.0), -12.0, 14.0)


func _process(_delta: float) -> void:
	_process_gate_hint()
	# Floating lanterns drift slowly downstream (west), bobbing, and come
	# round again from the other end of their canal.
	var t := Time.get_ticks_msec() * 0.001
	for f: Node3D in _floaters:
		var span: Vector2 = f.get_meta(&"span")
		var speed: float = f.get_meta(&"speed")
		f.position.x -= speed * get_process_delta_time()
		if f.position.x < span.x + 0.4:
			f.position.x = span.y - 0.4
		f.position.y = WATER_Y + 0.02 + 0.03 * sin(t * 1.4 + f.position.x)
		f.rotation.z = 0.06 * sin(t * 1.1 + f.position.x * 0.7)


func _physics_process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	# Into a canal: he goes under, and the fade takes him back to the last
	# shrine (as in the town's deep water).
	var x := _ronin.global_position.x - market.global_position.x
	for w: Vector2 in WATERS:
		if x > w.x and x < w.y and _ronin.global_position.y < WATER_Y - 0.35:
			Sound.play(self, &"splash", 2.0)
			_ronin.fall_in()
			return


# --- Festival Square -----------------------------------------------------------------

func _build_square() -> void:
	var g := LanternMarket.PLAZA.z
	# The drum tower: four posts, a railed platform with a great drum, a
	# little roof, lantern strings running down from its top to poles.
	var tx := 139.0
	var tz := -4.5
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	b.color = PaperMesh.TIMBER.lightened(0.1)
	for c: Vector2 in [Vector2(-1.4, -1.2), Vector2(1.4, -1.2), Vector2(-1.4, 1.2), Vector2(1.4, 1.2)]:
		b.box(Vector3(tx + c.x, g + 2.8, tz + c.y), Vector3(0.22, 5.6, 0.22))
	for y: float in [1.6, 3.4]:
		b.box(Vector3(tx, g + y, tz + 1.2), Vector3(2.9, 0.12, 0.12))
	b.color = Scenery.WOOD
	b.box(Vector3(tx, g + 5.0, tz), Vector3(3.4, 0.2, 2.9))
	b.color = LanternMarket.LACQUER
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(tx + side * 1.6, g + 5.5, tz + 1.35), Vector3(0.08, 0.8, 0.08))
	b.box(Vector3(tx, g + 5.85, tz + 1.35), Vector3(3.3, 0.08, 0.08))
	# Red and white bunting round the railing.
	for k in 8:
		b.color = LanternMarket.RED_CLOTH if k % 2 == 0 else LanternMarket.CREAM
		b.box(Vector3(tx - 1.4 + k * 0.4, g + 5.55, tz + 1.4), Vector3(0.38, 0.5, 0.02))
	# The stand the drum rests on.
	b.color = PaperMesh.TIMBER
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(tx + side * 0.5, g + 5.5, tz - 0.3), Vector3(0.1, 0.8, 0.1))
	b.box(Vector3(tx, g + 5.15, tz - 0.3), Vector3(1.2, 0.1, 0.5))
	add_child(b.build())
	# The great drum lying on it, its skin facing us (built along y, then
	# turned to face the front), studded rim, a vermilion tomoe on the skin.
	var drum := Node3D.new()
	drum.position = Vector3(tx, g + 6.2, tz - 0.3)
	drum.rotation_degrees.x = 90.0
	add_child(drum)
	var d := PaperMesh.new(_rng.randi())
	d.shade_jitter = 0.12
	d.color = Color(0.42, 0.24, 0.16)
	d.loft([PaperMesh.oval(Vector3(0.0, -0.4, 0.0), Vector2(0.5, 0.5), 14, 0.0),
			PaperMesh.oval(Vector3(0.0, 0.0, 0.0), Vector2(0.58, 0.58), 14, 0.0),
			PaperMesh.oval(Vector3(0.0, 0.4, 0.0), Vector2(0.5, 0.5), 14, 0.0)])
	drum.add_child(d.build())
	var skin := PaperMesh.new(_rng.randi())
	skin.color = LanternMarket.CREAM.darkened(0.1)
	skin.ellipse(Vector2(tx, g + 6.2), Vector2(0.48, 0.48), 16, tz + 0.11)
	skin.color = LanternMarket.RED_CLOTH
	for k in 3:
		var a := TAU * k / 3.0
		skin.ellipse(Vector2(tx, g + 6.2) + Vector2(cos(a), sin(a)) * 0.14, Vector2(0.11, 0.11), 10, tz + 0.115)
	skin.color = Color(0.1, 0.08, 0.08)
	for k in 12:
		var a := TAU * k / 12.0
		skin.ellipse(Vector2(tx, g + 6.2) + Vector2(cos(a), sin(a)) * 0.5, Vector2(0.025, 0.025), 5, tz + 0.112)
	add_child(skin.build())
	add_child(Scenery.tiled_roof(_rng, tx - 2.0, tx + 2.0, Vector2(g + 8.0, tz + 1.8), Vector2(g + 9.2, tz - 0.2), 3))
	add_child(Scenery.tiled_roof(_rng, tx - 2.0, tx + 2.0, Vector2(g + 8.0, tz - 2.2), Vector2(g + 9.2, tz - 0.2), 3, false))
	var posts := PaperMesh.new(_rng.randi())
	posts.color = PaperMesh.TIMBER.lightened(0.1)
	for c: Vector2 in [Vector2(-1.4, -1.2), Vector2(1.4, -1.2), Vector2(-1.4, 1.2), Vector2(1.4, 1.2)]:
		posts.box(Vector3(tx + c.x, g + 6.6, tz + c.y), Vector3(0.16, 2.8, 0.16))
	add_child(posts.build())
	for side: float in [-1.0, 1.0]:
		market._hang(Vector3(tx + side * 1.4, g + 7.8, tz + 1.35), 1.1, 0.25)
	market._light(Vector3(tx, g + 5.0, tz + 3.0), market.village.lantern_energy * 0.8, market.village.lantern_range)
	# Lantern strings from the tower's top out to poles at the square's ends.
	for end_x: float in [129.0]:
		var pole := PaperMesh.new(_rng.randi())
		pole.color = PaperMesh.TIMBER
		pole.box(Vector3(end_x, g + 3.6, tz + 1.0), Vector3(0.14, 7.2, 0.14))
		add_child(pole.build())
		var rope := PaperMesh.new(1)
		rope.color = PaperMesh.SUMI
		var a := Vector2(tx + signf(end_x - tx) * 1.5, g + 7.6)
		var c := Vector2(end_x, g + 7.0)
		var prev := a
		for k in range(1, 9):
			var t := k / 8.0
			var p := a.lerp(c, t) - Vector2(0.0, 0.9 * 4.0 * t * (1.0 - t))
			rope.stroke(prev, p, 0.025, 0.025, tz + 1.2)
			prev = p
			if k < 8 and k % 2 == 1:
				market._hang(Vector3(p.x, p.y, tz + 1.2), 0.65, 0.1)
		add_child(rope.build())
	# The racks the festival dragon hung from in the parades: two tall poles
	# and a beam, empty now, shreds of its red and gold paper left on the
	# hooks, the beam gouged where it tore itself free.
	var rx := 131.2
	var rz := -6.5
	var r := PaperMesh.new(_rng.randi())
	r.shade_jitter = 0.15
	r.color = LanternMarket.LACQUER.darkened(0.35)
	for side: float in [-1.0, 1.0]:
		r.box(Vector3(rx + side * 3.2, g + 4.2, rz), Vector3(0.24, 8.4, 0.24))
	r.box(Vector3(rx, g + 8.2, rz), Vector3(7.0, 0.3, 0.3))
	r.color = Color(0.08, 0.06, 0.07)
	for k in 3:
		var cx := rx - 1.5 + k * 1.4
		r.stroke(Vector2(cx, g + 8.33), Vector2(cx + 0.5, g + 8.05), 0.06, 0.03, rz + 0.16)   # claw gouges
	add_child(r.build())
	for k in 5:
		var hook := Node3D.new()
		hook.position = Vector3(rx - 2.6 + k * 1.3, g + 8.05, rz + 0.18)
		add_child(hook)
		var shred := PaperMesh.new(_rng.randi())
		shred.color = PaperMesh.SUMI
		shred.stroke(Vector2.ZERO, Vector2(0.0, -0.2), 0.02, 0.02, 0.0)
		shred.color = LanternMarket.RED_CLOTH if k % 2 == 0 else LanternMarket.GOLD.darkened(0.2)
		var long := _rng.randf_range(0.5, 1.4)
		shred.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.12, -0.2), Vector2(0.12, -0.2), Vector2(0.06, -0.2 - long),
				Vector2(-0.1, -0.2 - long * 0.8)]), 0.15, 0.04, _rng), 0.0)
		hook.add_child(shred.build())
		Scenery.windswept(hook, 0.12, _rng)
	# The lantern hoist: a timber frame with a pulley, a platform riding up
	# and down on ropes, a counterweight of lantern-wax barrels.
	var f := PaperMesh.new(_rng.randi())
	f.color = PaperMesh.TIMBER.lightened(0.08)
	for side: float in [-1.0, 1.0]:
		f.box(Vector3(HOIST_X + side * 1.15, g + 6.25, -1.3), Vector3(0.18, 12.5, 0.18))
	f.box(Vector3(HOIST_X, g + 12.4, -1.3), Vector3(2.6, 0.22, 0.22))
	f.color = Color(0.2, 0.18, 0.2)
	f.loft([PaperMesh.oval(Vector3(HOIST_X, g + 12.0, -1.3), Vector2(0.28, 0.28), 10, 0.0),
			PaperMesh.oval(Vector3(HOIST_X, g + 12.0, -1.1), Vector2(0.28, 0.28), 10, 0.0)])
	add_child(f.build())
	var hoist := Hoist.new()
	hoist.low = HOIST_RANGE.x
	hoist.high = HOIST_RANGE.y
	hoist.position = Vector3(HOIST_X, HOIST_RANGE.x, 0.0)
	hoist.top = g + 12.0
	add_child(hoist)


## A platform on ropes riding up and down between `low` and `high`, waiting
## a moment at each end: the way up to the high walkways.
class Hoist extends AnimatableBody3D:
	var low := 6.5
	var high := 10.0
	var top := 18.0
	var speed := 1.1
	var wait := 1.4
	var _dir := 1.0
	var _wait := 1.0
	var _ropes: Array[MeshInstance3D] = []

	func _ready() -> void:
		sync_to_physics = false
		process_physics_priority = -5
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, 0.2, 2.0)
		shape.shape = box
		shape.position.y = -0.1
		add_child(shape)
		var b := PaperMesh.new(91)
		b.shade_jitter = 0.2
		b.color = Scenery.WOOD.lightened(0.15)
		b.box(Vector3(0.0, -0.1, 0.0), Vector3(2.0, 0.2, 2.0))
		b.color = LanternMarket.LACQUER
		b.box(Vector3(0.0, -0.1, 1.0), Vector3(2.05, 0.24, 0.06))
		add_child(b.build())
		var l := Scenery.lantern(RandomNumberGenerator.new(), 1.6, 0.6, 0.1)
		l.position = Vector3(-0.85, 0.9, -0.9)
		add_child(l)
		var pole := PaperMesh.new(92)
		pole.color = PaperMesh.TIMBER
		pole.box(Vector3(-0.85, 0.45, -0.9), Vector3(0.05, 0.9, 0.05))
		add_child(pole.build())
		for side: float in [-1.0, 1.0]:
			var rope := MeshInstance3D.new()
			var line := BoxMesh.new()
			line.size = Vector3(0.03, 1.0, 0.03)
			rope.mesh = line
			rope.material_override = PaperMesh.material(Color(0.5, 0.42, 0.3))
			rope.position = Vector3(side * 0.9, 0.0, -1.3)
			add_child(rope)
			_ropes.append(rope)

	func _physics_process(delta: float) -> void:
		# (Its velocity is told to the physics too, so he rides it smoothly
		# instead of being shoved up by it step by step.)
		constant_linear_velocity = Vector3.ZERO if _wait > 0.0 else Vector3(0.0, _dir * speed, 0.0)
		if _wait > 0.0:
			_wait -= delta
		else:
			position.y += _dir * speed * delta
			if (_dir > 0.0 and position.y >= high) or (_dir < 0.0 and position.y <= low):
				position.y = clampf(position.y, low, high)
				_dir = -_dir
				_wait = wait
		# The ropes, from the platform's corners up to the pulley.
		for rope: MeshInstance3D in _ropes:
			rope.scale.y = top - position.y
			rope.position.y = (top - position.y) * 0.5


# --- The canals ----------------------------------------------------------------------

func _build_stairs(span: Vector2, from: float, to: float) -> void:
	market._slope(span.x, from, span.y, to, 9.0)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	var n := 10
	for k in n:
		var x0 := span.x + (span.y - span.x) * k / n
		var x1 := span.x + (span.y - span.x) * (k + 1) / n
		var top := lerpf(from, to, (k + 0.5) / n) + 0.1
		b.color = Color(0.3, 0.3, 0.37) * _rng.randf_range(0.85, 1.1)
		b.box(Vector3((x0 + x1) * 0.5, top - 2.0, (LanternMarket.NEAR_Z + Village.STREET_BACK) * 0.5),
				Vector3(x1 - x0 + 0.02, 4.0, LanternMarket.NEAR_Z - Village.STREET_BACK))
	add_child(b.build())
	for lx: float in [span.x + 0.6, span.y - 0.6]:
		market.village._build_stone_lantern(Vector3(LanternMarket.SHIFT + lx, ground_at(lx), -2.6), false)


## A quay of stone blocks: solid, paved on top, a dressed stone face where it
## meets the water.
func _quay(left: float, right: float, top: float) -> void:
	market._solid(Vector3((left + right) * 0.5, top - 5.0, -1.5), Vector3(right - left, 10.0, 6.0))
	market.village._lay_paving(LanternMarket.SHIFT + left, LanternMarket.SHIFT + right, top, Village.STREET_BACK, LanternMarket.NEAR_Z)
	market.village._add_rain_splashes(LanternMarket.SHIFT + left, LanternMarket.SHIFT + right, top)
	var s := PaperMesh.new(_rng.randi())
	s.shade_jitter = 0.18
	for wx: float in [left, right]:
		var y := BED_Y - 1.0
		while y < top - 0.01:
			var y1 := minf(y + 0.5, top)
			var z := Village.STREET_BACK
			while z < LanternMarket.NEAR_Z - 0.01:
				var z1 := minf(z + _rng.randf_range(0.7, 1.2), LanternMarket.NEAR_Z)
				s.color = Color(0.26, 0.25, 0.31) * _rng.randf_range(0.8, 1.1)
				s.box(Vector3(wx, (y + y1) * 0.5, (z + z1) * 0.5), Vector3(0.3, y1 - y - 0.03, z1 - z - 0.03))
				z = z1
			y = y1
	# The front, facing us: courses of dressed stone down to the water's
	# bed (a plain black slab loomed like a wall from the lower quays).
	var y := BED_Y
	var row := 0
	while y < top - 0.01:
		var y1 := minf(y + 0.5, top)
		var bx := left - (0.4 if row % 2 == 1 else 0.0)
		while bx < right - 0.01:
			var bx1 := minf(bx + _rng.randf_range(0.8, 1.3), right)
			var l := maxf(bx, left)
			s.color = Color(0.27, 0.26, 0.32) * _rng.randf_range(0.75, 1.05)
			s.box(Vector3((l + bx1) * 0.5, (y + y1) * 0.5, LanternMarket.NEAR_Z - 0.15), Vector3(bx1 - l - 0.04, y1 - y - 0.04, 0.3))
			bx = bx1
		y = y1
		row += 1
	add_child(s.build())   # (no torn front sheet over it: two faces at one depth flicker)


func _canal(left: float, right: float) -> void:
	market._solid(Vector3((left + right) * 0.5, BED_Y - 2.0, -1.5), Vector3(right - left, 4.0, 6.0))
	var w := PaperMesh.new(1)
	w.shade_jitter = 0.04
	w.color = Color(0.1, 0.11, 0.2)
	w.quad(Vector3(left, WATER_Y, Village.STREET_BACK), Vector3(right, WATER_Y, Village.STREET_BACK),
			Vector3(right, WATER_Y, LanternMarket.NEAR_Z), Vector3(left, WATER_Y, LanternMarket.NEAR_Z), Vector3.UP)
	w.color = Color(0.03, 0.04, 0.09)
	w.quad(Vector3(left, WATER_Y, LanternMarket.NEAR_Z), Vector3(right, WATER_Y, LanternMarket.NEAR_Z),
			Vector3(right, -12.0, LanternMarket.NEAR_Z), Vector3(left, -12.0, LanternMarket.NEAR_Z))
	var water := w.build()
	var gloss := water.material_override as StandardMaterial3D
	gloss.roughness = 0.12
	gloss.metallic_specular = 0.9
	add_child(water)
	var x := left + 1.5
	while x < right - 1.0:
		var r := Scenery.reflection(Vector2(1.4, 7.0), Color(1.0, 0.62, 0.3, 0.55))
		r.position = Vector3(x, WATER_Y + 0.01, 1.5)
		r.set_meta(&"x", x)
		add_child(r)
		market._shimmer.append(r)
		x += _rng.randf_range(2.5, 4.0)
	market.village._add_rain_splashes(LanternMarket.SHIFT + left, LanternMarket.SHIFT + right, WATER_Y)


func _piling(x: float, top: float) -> void:
	market._solid(Vector3(x, (top + BED_Y) * 0.5, 0.0), Vector3(0.9, top - BED_Y, 1.2))
	# A bundle of three thick logs driven into the bed, bound with rope at
	# the waterline and near the top; their cut ends are the stepping place.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.2
	for pile: Vector3 in [Vector3(-0.2, 0.0, -0.25), Vector3(0.22, -0.06, -0.15), Vector3(0.0, 0.04, 0.3)]:
		b.color = Scenery.WOOD.darkened(_rng.randf_range(0.0, 0.2))
		b.loft([PaperMesh.oval(Vector3(x + pile.x, BED_Y, pile.z), Vector2(0.26, 0.26), 9, 0.0),
				PaperMesh.oval(Vector3(x + pile.x, top + pile.y, pile.z), Vector2(0.24, 0.24), 9, 0.0)], true, true)
	b.color = Color(0.55, 0.46, 0.32)
	for y: float in [WATER_Y + 0.15, top - 0.35]:
		b.frustum(10, Vector2(0.52, 0.5), Vector2(0.52, 0.5), 0.1, Vector3(x, y, 0.0))
	add_child(b.build())


## Tall houses standing in the water at the back of the canals on stone
## plinths, lit shoji, lanterns at their eaves, steps down to the water.
func _canal_houses() -> void:
	var x := STAIRS_DOWN.y
	while x < STAIRS_UP.x:
		var w := _rng.randf_range(5.0, 6.5)
		var plinth := PaperMesh.new(_rng.randi())
		plinth.shade_jitter = 0.2
		var top := QUAY_Y + 0.4
		var y := BED_Y
		while y < top - 0.01:
			var y1 := minf(y + 0.45, top)
			var bx := x
			while bx < x + w - 0.01:
				var bx1 := minf(bx + _rng.randf_range(0.7, 1.2), x + w)
				plinth.color = Color(0.26, 0.24, 0.29) * _rng.randf_range(0.75, 1.05)
				plinth.box(Vector3((bx + bx1) * 0.5, (y + y1) * 0.5, -6.5), Vector3(bx1 - bx - 0.03, y1 - y - 0.03, 4.2))
				bx = bx1
			y = y1
		add_child(plinth.build())
		var hh := _rng.randf_range(5.0, 6.5)
		var house := Scenery.house(_rng, w - 0.3, hh, true, market.village.window_glow,
				[["noren"], ["sudare"], ["round"], ["awning"]][_rng.randi() % 4])
		house.position = Vector3(x + w * 0.5, top, -5.6)
		add_child(house)
		if _rng.randf() < 0.7:
			market._eave_lantern(house.position, hh, x + w * 0.5 + _rng.randf_range(-1.5, 1.5), 0.9)
		x += w + _rng.randf_range(0.4, 1.0)
	for lx: float in [160.0, 182.0, 192.0]:
		market._light(Vector3(lx, QUAY_Y + 3.5, -2.5), market.village.lantern_energy * 0.8, market.village.lantern_range * 1.2)


## Paper lanterns floating on the canals (as for the dead at Obon), drifting
## slowly downstream, glowing on the water.
func _floating_lanterns() -> void:
	for w: Vector2 in WATERS:
		var n := int((w.y - w.x) / 3.5)
		for k in n:
			var f := Node3D.new()
			# (In front of or behind his path, never on it: the boat runs there.)
			var lane := _rng.randf_range(-3.5, -1.6) if k % 2 == 0 else _rng.randf_range(1.6, 3.4)
			f.position = Vector3(w.x + 1.0 + k * (w.y - w.x - 2.0) / n + _rng.randf_range(-0.6, 0.6), WATER_Y, lane)
			f.set_meta(&"span", w)
			f.set_meta(&"speed", _rng.randf_range(0.12, 0.25))
			add_child(f)
			var b := PaperMesh.new(_rng.randi())
			b.color = Scenery.WOOD.darkened(0.2)
			b.box(Vector3(0.0, 0.03, 0.0), Vector3(0.38, 0.06, 0.38))
			# A paper box in a dark frame, a red crest on its face, softly lit
			# (a plain glowing box looked like a white cube).
			b.color = PaperMesh.TIMBER
			for c: Vector2 in [Vector2(-0.14, -0.14), Vector2(0.14, -0.14), Vector2(-0.14, 0.14), Vector2(0.14, 0.14)]:
				b.box(Vector3(c.x, 0.24, c.y), Vector3(0.03, 0.36, 0.03))
			b.frustum(4, Vector2(0.24, 0.24), Vector2(0.2, 0.2), 0.03, Vector3(0.0, 0.42, 0.0))
			f.add_child(b.build())
			var p := PaperMesh.new(_rng.randi())
			p.color = PaperMesh.LANTERN.lerp(LanternMarket.CREAM, 0.25) * 0.85
			p.frustum(4, Vector2(0.2, 0.2), Vector2(0.18, 0.18), 0.34, Vector3(0.0, 0.07, 0.0))
			p.color = LanternMarket.RED_CLOTH
			p.ellipse(Vector2(0.0, 0.25), Vector2(0.055, 0.055), 8, 0.145)
			var lit := p.build(Color.WHITE, 0.55)
			lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			f.add_child(lit)
			var halo := Scenery.halo(0.9, Color(1.0, 0.62, 0.3, 0.4))
			halo.position = Vector3(0.0, 0.25, 0.2)
			f.add_child(halo)
			_floaters.append(f)


# --- Above: the high route -----------------------------------------------------------

func _build_high_route() -> void:
	for wk: Array in WALKWAYS:
		market._gallery(wk[0], wk[1], wk[2])
	var bundle := CraneBundle.new()
	bundle.id = "market_high"
	bundle.count = 5
	bundle.position = Vector3(181.5, 10.0, 0.0)
	add_child(bundle)
	var line := LanternString.new()
	line.span = 7.0
	line.height = 12.2 - QUAY_Y
	line.sag = 1.2
	line.count = 3
	line.position = Vector3(168.5, QUAY_Y, 0.0)   # (both poles on the middle quay)
	add_child(line)


# --- The teahouse and the Ward's gate -------------------------------------------------

func _build_teahouse() -> void:
	var house := Scenery.house(_rng, 7.0, 5.2, true, market.village.window_glow, ["noren", "pots"])
	house.position = Vector3(208.5, BANK_Y, -4.3)
	add_child(house)
	market._eave_lantern(house.position, 5.2, 205.6, 1.2)
	market._light(Vector3(207.0, BANK_Y + 2.6, -0.6), market.village.lantern_energy * 0.9, market.village.lantern_range)
	market._shine(207.0, BANK_Y, 5.0, 0.9)
	var bench := PaperMesh.new(_rng.randi())
	bench.color = LanternMarket.RED_CLOTH.darkened(0.15)
	bench.box(Vector3(210.0, BANK_Y + 0.45, -2.4), Vector3(2.2, 0.08, 0.7))
	bench.color = PaperMesh.TIMBER
	for side: float in [-1.0, 1.0]:
		bench.box(Vector3(210.0 + side * 0.95, BANK_Y + 0.22, -2.4), Vector3(0.08, 0.44, 0.6))
	add_child(bench.build())
	var umbrella := PaperMesh.new(_rng.randi())
	umbrella.color = LanternMarket.RED_CLOTH
	umbrella.frustum(12, Vector2(1.5, 1.5), Vector2(0.05, 0.05), 0.55, Vector3(211.2, BANK_Y + 2.4, -2.8))
	umbrella.color = PaperMesh.TIMBER
	umbrella.box(Vector3(211.2, BANK_Y + 1.25, -2.8), Vector3(0.05, 2.5, 0.05))
	add_child(umbrella.build())
	var shrine := RestShrine.new()
	shrine.shrine_id = "teahouse"
	shrine.position = Vector3(SHRINE_X, BANK_Y, -0.9)
	shrine.scale = Vector3.ONE * 1.3
	add_child(shrine)


## The gate into the Ward of Shut Doors, where the festival dragon is loose:
## its door shut and pasted over with paper charms (ofuda), a straw rope
## across it. Cut the charms away (three cuts, three charms torn off with
## each, fluttering down to the stones) and the door swings back into the
## Ward (SaveGame.ward_open).
func _build_ward_gate() -> void:
	var g := BANK_Y
	var gx := WARD_GATE
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.color = PaperMesh.TIMBER.lightened(0.12)
	for pz: float in [1.6, -2.6]:
		b.box(Vector3(gx, g + 2.9, pz), Vector3(0.4, 5.8, 0.4))
	b.box(Vector3(gx, g + 5.4, -0.5), Vector3(0.5, 0.35, 5.2))
	add_child(b.build())
	add_child(Scenery.tiled_roof(_rng, gx - 1.2, gx + 1.2, Vector2(g + 5.6, 2.4), Vector2(g + 6.8, -0.5), 3))
	add_child(Scenery.tiled_roof(_rng, gx - 1.2, gx + 1.2, Vector2(g + 5.6, -3.4), Vector2(g + 6.8, -0.5), 3, false))
	_build_ward_walls()
	# The door, hinged on the back post, and the bars across it.
	_gate_door = Node3D.new()
	_gate_door.position = Vector3(gx, g, -2.4)
	add_child(_gate_door)
	var d := PaperMesh.new(_rng.randi())
	d.shade_jitter = 0.14
	d.color = Scenery.WOOD.darkened(0.25)
	d.box(Vector3(0.0, 2.5, 1.9), Vector3(0.18, 5.0, 3.8))
	d.color = Color(0.09, 0.08, 0.1)
	for y: float in [1.0, 2.6, 4.2]:
		d.box(Vector3(-0.1, y, 1.9), Vector3(0.06, 0.16, 3.8))
	_gate_door.add_child(d.build())
	# Paper charms pasted crosswise over it, each brushed, a few flapping.
	for k in 9:
		var at := Vector3(-0.2, _rng.randf_range(0.6, 4.6), _rng.randf_range(0.3, 3.5))
		var charm := Node3D.new()
		charm.position = at
		charm.rotation = Vector3(0.0, -PI * 0.5, _rng.randf_range(-0.5, 0.5))
		_gate_door.add_child(charm)
		var c := PaperMesh.new(_rng.randi())
		c.color = LanternMarket.CREAM
		c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.14, 0.4), Vector2(0.14, 0.4), Vector2(0.14, -0.4), Vector2(-0.14, -0.4)]), 0.15, 0.02, _rng), 0.0)
		c.color = LanternMarket.RED_CLOTH
		c.ellipse(Vector2(0.0, 0.24), Vector2(0.06, 0.06), 8, 0.002)
		market._writing(c, Vector2(0.0, 0.08), 3, 0.11, 0.003)
		charm.add_child(c.build())
		if k % 3 == 0:
			Scenery.windswept(charm, 0.08, _rng)
		_charms.append(charm)
	# The straw rope with its zigzag paper streamers (high over the way).
	var rope := PaperMesh.new(_rng.randi())
	for k in 8:
		var t := (k + 0.5) / 8.0
		rope.color = Color(0.6, 0.52, 0.34)
		rope.box(Vector3(gx - 0.42, g + 4.6 - 0.5 * 4.0 * t * (1.0 - t), lerpf(1.5, -2.5, t)), Vector3(0.12, 0.13, 0.52))
		if k % 2 == 1:
			rope.color = LanternMarket.CREAM
			rope.box(Vector3(gx - 0.45, g + 4.25 - 0.5 * 4.0 * t * (1.0 - t), lerpf(1.5, -2.5, t)), Vector3(0.02, 0.5, 0.16))
	add_child(rope.build())
	if SaveGame.ward_open:
		_open_gate(false)
		return
	_gate_wall = market._solid(Vector3(gx, g + 15.0, 0.0), Vector3(0.5, 30.0, 4.0))
	_gate_wall.set_meta(&"no_climb", true)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 3.6, 2.0)
	_gate_target = PropTarget.make(self, shape, Vector3(gx - 0.35, g + 1.9, 0.0))
	_gate_target.struck.connect(_on_gate_struck)


## The Ward's wall, flanking its gate (Julian: the gate stood alone with
## empty gaps either side): behind, a plastered wall on a dark tiled base
## runs back from the gate's post and then along between the teahouse and the
## Ward's first house, capped with tiles, charms pasted on it; in front, a
## low wing of the same wall ends at a stout post (low, so it never hides him).
func _build_ward_walls() -> void:
	var g := BANK_Y
	var gx := WARD_GATE
	var w := PaperMesh.new(_rng.randi())
	w.shade_jitter = 0.12
	var plaster := Color(0.6, 0.57, 0.53)
	var base := Color(0.15, 0.14, 0.18)
	# Along z: from the back post to the house line.
	w.color = base
	w.box(Vector3(gx, g + 0.6, -3.85), Vector3(0.5, 1.2, 2.5))
	w.color = plaster
	w.box(Vector3(gx, g + 2.8, -3.85), Vector3(0.44, 3.2, 2.5))
	# Along x, between the teahouse and the Ward's first house, at the line
	# of their fronts.
	var left := 212.0
	var right := WardQuarter.HOUSES[0][0] - WardQuarter.HOUSES[0][1] * 0.5 - 0.05
	w.color = base
	w.box(Vector3((left + right) * 0.5, g + 0.6, -5.1), Vector3(right - left, 1.2, 0.5))
	w.color = plaster
	w.box(Vector3((left + right) * 0.5, g + 2.8, -5.1), Vector3(right - left, 3.2, 0.44))
	# Namako tiles: a lattice of pale grout on the dark base, facing us.
	w.color = Color(0.5, 0.49, 0.5)
	var x := left + 0.3
	while x < right - 0.2:
		w.box(Vector3(x, g + 0.6, -4.84), Vector3(0.04, 1.1, 0.02))
		x += 0.55
	for y: float in [0.25, 0.6, 0.95]:
		w.box(Vector3((left + right) * 0.5, g + y, -4.84), Vector3(right - left - 0.1, 0.04, 0.02))
	# A dark timber band under the coping.
	w.color = PaperMesh.TIMBER
	w.box(Vector3((left + right) * 0.5, g + 4.3, -4.86), Vector3(right - left, 0.14, 0.06))
	# The wing in front, out to a stout post: long and high enough that no
	# one could just walk round the gate (Julian).
	w.color = base
	w.box(Vector3(gx, g + 0.6, 3.4), Vector3(0.5, 1.2, 3.6))
	w.color = plaster
	w.box(Vector3(gx, g + 2.1, 3.4), Vector3(0.44, 1.8, 3.6))
	w.color = PaperMesh.TIMBER
	w.box(Vector3(gx + 0.24, g + 2.9, 3.4), Vector3(0.06, 0.12, 3.6))
	w.color = PaperMesh.TIMBER.lightened(0.1)
	w.box(Vector3(gx, g + 1.8, 5.3), Vector3(0.4, 3.6, 0.4))
	add_child(w.build())
	# Tiled coping on each stretch.
	add_child(Scenery.tiled_roof(_rng, left - 0.1, right + 0.1, Vector2(g + 4.35, -4.6), Vector2(g + 4.85, -5.1), 2))
	add_child(Scenery.tiled_roof(_rng, left - 0.1, right + 0.1, Vector2(g + 4.35, -5.6), Vector2(g + 4.85, -5.1), 2, false))
	var cope := Scenery.tiled_roof(_rng, -1.25, 1.25, Vector2(g + 4.35, 0.5), Vector2(g + 4.85, 0.0), 2)
	cope.rotation.y = PI * 0.5
	cope.position = Vector3(gx, 0.0, -3.85)
	add_child(cope)
	var cope_back := Scenery.tiled_roof(_rng, -1.25, 1.25, Vector2(g + 4.35, -0.5), Vector2(g + 4.85, 0.0), 2, false)
	cope_back.rotation.y = PI * 0.5
	cope_back.position = Vector3(gx, 0.0, -3.85)
	add_child(cope_back)
	for side: float in [1.0, -1.0]:
		var wing := Scenery.tiled_roof(_rng, -1.8, 1.8, Vector2(g + 3.0, 0.45 * side), Vector2(g + 3.35, 0.0), 2, side > 0.0)
		wing.rotation.y = PI * 0.5
		wing.position = Vector3(gx, 0.0, 3.4)
		add_child(wing)
	# Charms on the wall too.
	for k in 4:
		var charm := Node3D.new()
		charm.position = Vector3(_rng.randf_range(left + 0.5, right - 0.5), g + _rng.randf_range(1.8, 3.6), -4.86)
		charm.rotation.z = _rng.randf_range(-0.4, 0.4)
		add_child(charm)
		var c := PaperMesh.new(_rng.randi())
		c.color = LanternMarket.CREAM
		c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.1, 0.3), Vector2(0.1, 0.3), Vector2(0.1, -0.3), Vector2(-0.1, -0.3)]), 0.12, 0.015, _rng), 0.0)
		c.color = LanternMarket.RED_CLOTH
		c.ellipse(Vector2(0.0, 0.18), Vector2(0.045, 0.045), 8, 0.002)
		market._writing(c, Vector2(0.0, 0.06), 3, 0.08, 0.003)
		charm.add_child(c.build())
	# A lantern on the wing's post (hung from a bracket on it).
	var bracket := PaperMesh.new(_rng.randi())
	bracket.color = PaperMesh.TIMBER
	bracket.box(Vector3(gx - 0.37, g + 3.3, 5.3), Vector3(0.74, 0.07, 0.07))
	add_child(bracket.build())
	market._hang(Vector3(gx - 0.62, g + 3.27, 5.3), 0.8, 0.12)


func _process_gate_hint() -> void:
	if _gate_target == null or _ronin == null:
		if _hint:
			_hint.near = false
		return
	if _hint == null:
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud == null:
			return
		_hint = ActionHint.new()
		_hint.items = [["J", "X", "Cut away the charms"]]
		_hint.point = market.to_global(Vector3(WARD_GATE - 0.3, BANK_Y + 3.2, 0.0))
		hud.get_parent().add_child(_hint)
	var x := _ronin.global_position.x - market.global_position.x
	_hint.near = x > WARD_GATE - 6.0 and x < WARD_GATE + 0.5 and absf(_ronin.global_position.y - BANK_Y - market.global_position.y) < 3.0


func _on_gate_struck(_direction: Vector2) -> void:
	Sound.play(self, &"paper_rip", -2.0)
	for k in 3:
		if _charms.is_empty():
			break
		var charm: Node3D = _charms.pop_back()
		# Torn off, it flutters down to the stones and lies there.
		var where := charm.global_position
		charm.reparent(self)
		charm.global_position = where
		var lie := Vector3(WARD_GATE - _rng.randf_range(0.5, 1.6), BANK_Y + 0.03, _rng.randf_range(-1.6, 1.0))
		var t := create_tween().set_parallel()
		t.tween_property(charm, "position", lie, _rng.randf_range(0.8, 1.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(charm, "rotation", Vector3(-PI * 0.5, _rng.randf_range(-PI, PI), 0.0), 1.0)
	if _charms.is_empty():
		_open_gate(true)


func _open_gate(slow: bool) -> void:
	SaveGame.ward_open = true
	if _gate_wall:
		_gate_wall.queue_free()
		_gate_wall = null
	if _gate_target:
		_gate_target.queue_free()
		_gate_target = null
	if slow:
		var t := create_tween()
		t.tween_interval(0.3)
		t.tween_property(_gate_door, "rotation:y", PI * 0.5, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sound.play(self, &"plank_creak", 2.0)
	else:
		for c: Node3D in _charms:
			c.visible = false
		_gate_door.rotation.y = PI * 0.5
