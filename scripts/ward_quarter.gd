class_name WardQuarter
extends Node3D
## The Ward of Shut Doors (docs/lantern_market_plan.md, area 6): past the
## teahouse and the Ward's gate, the district the Festival Dragon torments.
## Storm shutters closed and pasted over with paper charms (ofuda), claw
## gouges down the walls, festival lanterns torn and dropped, a cart
## overturned, nobody in the street.
##  - The lane in (WARD.x to ARENA.x): shut houses.
##  - The square (ARENA): where it is fought. Houses along the back (three
##    of them it can crush: `crush` in HOUSES), a great stone lantern, red
##    walkways on two levels at each side to fight from up high. The first
##    time he walks in, the last open shutters slam shut one by one, it
##    pours down off the roofs, sweeps over him and coils round the stone
##    lantern, laughing; its name is painted (祭龍); walls of pouring rain
##    close both ends of the square while it lives.
##  - After: it comes apart into a heap of wet festival paper; the rain
##    walls stop; the shutters slide open one by one, warm light, people
##    peering out at him (shy, they duck as he comes near).
##  - The lane out east, to the gate up to the Lantern Makers' Rise (shut:
##    not built yet).
## Built in the market's own coordinates, a child of the Canal Quarter at
## its origin, with the market's helpers.

const WARD := Vector2(216.0, 300.0)
const G := CanalQuarter.BANK_Y
## The square where it is fought.
const ARENA := Vector2(228.0, 270.0)
## The walls of rain that close it, a little outside it (the dragon keeps
## inside the square: FestivalDragon.keep_inside).
const RAIN_WALLS := Vector2(226.5, 271.5)
## The great stone lantern it coils round in the intro.
const LANTERN := Vector3(249.2, CanalQuarter.BANK_Y, -2.4)
## The houses along the back: [middle, width, height, it can crush it].
const HOUSES := [
	[219.5, 5.4, 5.4, false], [225.0, 5.2, 6.0, false],
	[231.0, 5.0, 5.4, false], [236.8, 6.0, 5.8, false], [243.0, 6.0, 5.8, true],
	[249.2, 6.0, 6.4, false], [255.4, 6.0, 5.8, true], [261.6, 6.0, 6.2, false],
	[267.4, 5.0, 5.6, false],
	[273.5, 6.0, 5.8, false], [279.5, 6.0, 5.4, false], [285.5, 5.6, 6.0, false], [291.0, 5.0, 5.4, false],
]
const HOUSE_Z := -5.0
## Red walkways to fight from: [middle, top, width] (low, about 2.3 m up,
## reached with a jump; high, about 4.6 m, from the low ones). They stand
## toward the ends, clear of the houses it crushes and of LANE, so its body
## never goes through them.
const WALKS := [[231.6, 8.8, 3.8], [266.8, 8.8, 3.8], [236.6, 11.1, 3.4], [261.8, 11.1, 3.4]]
## The stretch of the square clear of the walkways, where it comes down low
## (its dive, its breath, lying stunned).
const LANE := Vector2(239.8, 258.6)
## The gate up to the Lantern Makers' Rise, at the Ward's east end.
const RISE_GATE := 296.0
## The fan-maker's shop, at the front of the house there: after the dragon
## she gives him the Fan Gust.
const FAN_SHOP := 279.5

## How loud its fight music plays (dB, before the Music volume setting).
@export var music_volume := -7.0
@export var music_fade_time := 2.5
## How far back the camera stands while it is fought (it is long; the
## camera usually stands at 15).
@export var fight_camera_distance := 20.0

var market: LanternMarket
var quarter: CanalQuarter
var dragon: FestivalDragon

var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _state := &"before"    # before, intro, fight, after, done
var _time := 0.0
var _houses: Array[Node3D] = []
## Each window's storm shutters: {house, left, right, halo, width, open}.
var _windows: Array[Dictionary] = []
var _curtains: Array[Node3D] = []
var _walls: Array[StaticBody3D] = []
var _curtain_level := 0.0
var _overlay: Control
var _title: HannyaTitle
var _bar: BossBar
var _skip: SkipPrompt
var _hud: CanvasItem
var _music: AudioStreamPlayer
var _music_fade: Tween
var _camera_tween: Tween
var _slammed := 0
var _opened := 0
var _shadows_added := false
var _fan_maker: MarketKeeper
var _cine: CineCamera
var _held := false
var _settled := false
var _focused := false
var _fan_given := false


func _ready() -> void:
	_rng.seed = 5150
	add_to_group(&"ward")
	quarter._quay(218.0, RiseQuarter.STEPS_1.x, G)
	_build_backing()
	_build_houses()
	for w: Array in WALKS:
		market._gallery(w[0], w[1], w[2])
	market.village._build_stone_lantern(Vector3(LanternMarket.SHIFT + LANTERN.x, G, LANTERN.z), false)
	_build_debris()
	_build_lights()
	_build_curtains()
	_build_rise_gate()
	_build_fan_shop()
	dragon = FestivalDragon.new()
	dragon.arena = ARENA
	dragon.lane = LANE
	dragon.avoid_x = LANTERN.x
	for walk: Array in WALKS:
		# (platform, rails, lanterns, and the posts down to the stones)
		dragon.obstacles.append(AABB(Vector3(walk[0] - walk[2] * 0.5 - 0.15, G, -1.45),
				Vector3(walk[2] + 0.3, walk[1] - G + 2.0, 2.7)))
	dragon.ground = G
	add_child(dragon)
	for i in HOUSES.size():
		if HOUSES[i][3]:
			dragon.houses.append(_houses[i])
			dragon.standing.append(true)
	dragon.reset()
	dragon.defeated.connect(_on_defeated)
	dragon.crushed.connect(func(i: int) -> void: _ruin(_houses.find(dragon.houses[i]), true))
	dragon.restored.connect(func(i: int) -> void: _unruin(_houses.find(dragon.houses[i])))
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_dragon_fight.ogg")
	(_music.stream as AudioStreamOggVorbis).loop = true
	add_child(_music)
	Sound.place_loop(self, "canal_drips.ogg", Vector3(222.0, G + 2.5, -3.0), -16.0, 8.0)
	Sound.place_loop(self, "canal_drips.ogg", Vector3(282.0, G + 2.5, -3.0), -16.0, 8.0)
	if SaveGame.dragon_beaten:
		_state = &"done"
		_fan_maker_comes()
		dragon.lie_dead()
		for k: int in SaveGame.ward_ruins:
			var i := dragon.houses.find(_houses[k])
			if i >= 0:
				dragon.standing[i] = false
			_ruin(k, false)
		for w: Dictionary in _windows:
			if not (w["house"] as Node3D).has_meta(&"ruin"):
				_set_shutters(w, true, false)
		_add_shadows()
	else:
		# Before the first fight the square's windows are still open (people
		# watching the sky); the lane's are shut.
		for w: Dictionary in _windows:
			var x: float = (w["house"] as Node3D).position.x
			_set_shutters(w, not SaveGame.dragon_met and x > ARENA.x and x < ARENA.y, false)


# --- Building it ---------------------------------------------------------------------

## A dark wall behind the houses, so no slit between them shows the bright
## city behind.
func _build_backing() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	b.color = Scenery.WALL_DARK.darkened(0.35)
	b.box(Vector3((WARD.x + WARD.y) * 0.5, G + 2.6, HOUSE_Z - 3.4), Vector3(WARD.y - WARD.x + 4.0, 5.2, 0.2))
	add_child(b.build())


func _build_houses() -> void:
	for h: Array in HOUSES:
		var x: float = h[0]
		var w: float = h[1]
		var hh: float = h[2]
		var house := Scenery.house(_rng, w, hh, true, market.village.window_glow,
				[["firewood"], ["buckets"], ["pots"], []][_rng.randi() % 4])
		house.position = Vector3(x, G, HOUSE_Z)
		add_child(house)
		house.set_meta(&"rest", house.transform)
		house.set_meta(&"half", w * 0.5)
		house.set_meta(&"height", hh)
		_houses.append(house)
		if house.has_meta("window"):
			_add_shutters(house)
		_claw_marks(house, w, hh)
		if not h[3]:
			# (A crushable house gets no eave lantern: it would hang from
			# nothing once the house fell.)
			if _rng.randf() < 0.6:
				market._eave_lantern(house.position, hh, x + _rng.randf_range(-1.4, 1.4), 0.85)


## Storm shutters over a house's lit window: two weathered leaves that slide
## shut over it (and apart again), paper charms pasted across them.
func _add_shutters(house: Node3D) -> void:
	var at: Vector3 = house.get_meta("window")
	var size: Vector2 = house.get_meta("window_size")
	var halo: Node3D = null
	for c: Node in house.get_children():
		if c is MeshInstance3D and (c as Node3D).position.is_equal_approx(Vector3(at.x, at.y, 0.2)):
			halo = c
	var leaves: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var leaf := Node3D.new()
		house.add_child(leaf)
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.2
		var lw := size.x * 0.5 + 0.12
		b.color = Color(0.2, 0.17, 0.18)
		b.rect(Vector2(side * lw * 0.5, 0.0), Vector2(lw, size.y + 0.26), 0.0)
		b.color = Color(0.13, 0.11, 0.12)
		var bx := -lw * 0.5 + 0.14
		while bx < lw * 0.5 - 0.05:
			b.rect(Vector2(side * lw * 0.5 + bx, 0.0), Vector2(0.025, size.y + 0.24), 0.005)
			bx += _rng.randf_range(0.16, 0.24)
		b.color = PaperMesh.TIMBER
		b.rect(Vector2(side * lw * 0.5, size.y * 0.2), Vector2(lw, 0.06), 0.01)
		leaf.add_child(b.build())
		# Charms pasted across.
		for k in 2:
			_charm(leaf, Vector3(side * _rng.randf_range(0.1, lw - 0.15), _rng.randf_range(-size.y * 0.35, size.y * 0.3), 0.02),
					_rng.randf_range(-0.35, 0.35))
		leaves.append(leaf)
	var w := {"house": house, "left": leaves[0], "right": leaves[1], "halo": halo,
			"at": Vector3(at.x, at.y, 0.17), "width": size.x * 0.5 + 0.12, "open": true}
	_windows.append(w)


## A paper charm (ofuda): cream paper, a vermilion seal, brushed writing.
func _charm(parent: Node3D, at: Vector3, tilt: float) -> void:
	var c := PaperMesh.new(_rng.randi())
	c.color = LanternMarket.CREAM
	c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.1, 0.3), Vector2(0.1, 0.3), Vector2(0.1, -0.3), Vector2(-0.1, -0.3)]), 0.12, 0.015, _rng), 0.0)
	c.color = LanternMarket.RED_CLOTH
	c.ellipse(Vector2(0.0, 0.18), Vector2(0.045, 0.045), 8, 0.002)
	market._writing(c, Vector2(0.0, 0.06), 3, 0.08, 0.003)
	var mesh := c.build()
	mesh.position = at
	mesh.rotation.z = tilt
	parent.add_child(mesh)


## Shutters shut (false) or open (true); `slow` slides them.
func _set_shutters(w: Dictionary, open: bool, slow: bool) -> void:
	w["open"] = open
	var at: Vector3 = w["at"]
	var lw: float = w["width"]
	var halo: Node3D = w["halo"]
	for side: float in [-1.0, 1.0]:
		var leaf: Node3D = w["left"] if side < 0.0 else w["right"]
		# Shut, the leaves meet over the window; open, each has slid aside
		# over the wall.
		var to := at + Vector3(side * (lw + 0.05) if open else 0.0, 0.0, 0.0)
		if slow:
			var t := create_tween()
			t.tween_property(leaf, "position", to, 0.28 if not open else 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN if not open else Tween.EASE_OUT)
		else:
			leaf.position = to
	if halo:
		if slow:
			var t := create_tween()
			t.tween_property(halo, "scale", Vector3.ONE * (1.0 if open else 0.01), 0.9 if open else 0.2)
		else:
			halo.scale = Vector3.ONE * (1.0 if open else 0.01)


## A house the dragon crushed becomes a ruin (`k`: its place in HOUSES):
## the house is gone and in its place its roof lies fallen in, in broken
## slabs of its own tiles, over a heap of rubble; posts stand snapped off at
## different heights, one leaning; beams lie across; a sheet of its torn
## wall paper hangs from a post; tiles are strewn out into the street; a
## shutter lies in the wet with a charm. Dust drifts up for a while.
## `fresh`: it has just fallen (the pieces drop into place and settle).
## (Julian: a squashed house was not destroyed enough.)
func _ruin(k: int, fresh: bool) -> void:
	if k < 0:
		return
	var house := _houses[k]
	if house.has_meta(&"ruin"):
		return
	var w: float = HOUSES[k][1]
	var hh: float = HOUSES[k][2]
	var half := w * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + k
	var ruin := Node3D.new()
	ruin.position = (house.get_meta(&"rest") as Transform3D).origin
	add_child(ruin)
	house.set_meta(&"ruin", ruin)
	house.visible = false
	# The rubble: a long mound of broken plaster, boards and tiles.
	var heap := PaperMesh.new(rng.randi())
	heap.shade_jitter = 0.25
	var tones := [Scenery.WALL_DARK, Color(0.52, 0.48, 0.44), PaperMesh.TIMBER, Scenery.ROOF, Color(0.3, 0.29, 0.34)]
	for n in 130:
		var x := rng.randf_range(-half - 0.2, half + 0.2)
		var z := rng.randf_range(-3.3, 0.5)
		var top := 1.5 * maxf(1.0 - pow(x / (half + 0.4), 2.0), 0.0) * maxf(1.0 - pow((z + 1.4) / 2.3, 2.0), 0.0)
		var y := rng.randf_range(0.0, maxf(top, 0.1))
		var tone: Color = tones[n % 5]
		heap.color = tone * rng.randf_range(0.75, 1.1)
		var size := Vector3(rng.randf_range(0.2, 0.7), rng.randf_range(0.06, 0.25), rng.randf_range(0.2, 0.6))
		heap.box(Vector3(x, y + size.y * 0.5, z), size)
	ruin.add_child(heap.build())
	# Snapped posts: the front corners and two at the back, each broken off
	# at its own height with a splintered pale end.
	var posts := PaperMesh.new(rng.randi())
	posts.shade_jitter = 0.15
	var spots := [Vector2(-half + 0.15, 0.0), Vector2(half - 0.15, 0.0), Vector2(-half + 0.15, -3.4), Vector2(rng.randf_range(-1.0, 1.0), -3.4)]
	var tall_post := Vector3.ZERO
	for i in spots.size():
		var s: Vector2 = spots[i]
		var high := hh * 0.72 if i == 0 else rng.randf_range(1.0, hh * 0.55)
		posts.color = PaperMesh.TIMBER.lightened(0.08)
		posts.box(Vector3(s.x, high * 0.5, s.y), Vector3(0.22, high, 0.22))
		posts.color = Color(0.5, 0.42, 0.32)
		var tip := Vector3(s.x + rng.randf_range(-0.05, 0.06), high + rng.randf_range(0.2, 0.4), s.y + 0.02)
		posts.tri(Vector3(s.x - 0.11, high, s.y + 0.11), Vector3(s.x + 0.11, high, s.y + 0.11), tip, Vector3.BACK)
		posts.tri(Vector3(s.x - 0.11, high, s.y - 0.11), Vector3(s.x - 0.11, high, s.y + 0.11), tip, Vector3.LEFT)
		posts.tri(Vector3(s.x + 0.11, high, s.y - 0.11), Vector3(s.x + 0.11, high, s.y + 0.11), tip, Vector3.RIGHT)
		posts.tri(Vector3(s.x - 0.11, high, s.y - 0.11), Vector3(s.x + 0.11, high, s.y - 0.11), tip, Vector3.FORWARD)
		if i == 0:
			tall_post = Vector3(s.x, high, s.y)
	ruin.add_child(posts.build())
	# What is left of the walls: the front broken off low with a jagged,
	# torn top (pale torn rims, like every wall in the town), its dark boards
	# showing; a stub of each side wall.
	var walls := PaperMesh.new(rng.randi())
	var front := PackedVector2Array([Vector2(-half + 0.1, 0.0)])
	var x := -half + 0.1
	while x < half - 0.1:
		front.append(Vector2(x, rng.randf_range(0.5, 2.0) if absf(x) > 0.6 else rng.randf_range(0.2, 0.6)))
		x += rng.randf_range(0.25, 0.55)
	front.append(Vector2(half - 0.1, rng.randf_range(0.8, 1.6)))
	front.append(Vector2(half - 0.1, 0.0))
	walls.color = Scenery.WALL_DARK
	walls.torn_sheet(PaperMesh.tear(front, 0.12, 0.05, rng), 0.02, Scenery.WALL_PAPER_RIM, 0.04)
	ruin.add_child(walls.build())
	for side: float in [-1.0, 1.0]:
		var stub := PaperMesh.new(rng.randi())
		var top := rng.randf_range(1.2, 2.6)
		stub.color = Scenery.WALL_DARK.darkened(0.15)
		stub.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, top), Vector2(1.2, top * 0.6), Vector2(2.2, 0.4), Vector2(2.4, 0.0)]),
				0.12, 0.06, rng), 0.0, Scenery.WALL_PAPER_RIM, 0.035)
		var stub_mesh := stub.build()
		stub_mesh.position = Vector3(side * (half - 0.05), 0.0, 0.0)
		stub_mesh.rotation.y = PI * 0.5
		ruin.add_child(stub_mesh)
	# A little light from the neighbours' lanterns falling on it.
	var glow := OmniLight3D.new()
	glow.light_color = PaperMesh.LANTERN
	glow.light_energy = market.village.lantern_energy * 0.3
	glow.omni_range = 6.0
	glow.omni_attenuation = market.village.light_falloff
	glow.position = Vector3(0.0, 2.6, 2.2)
	ruin.add_child(glow)
	var lean := PaperMesh.new(rng.randi())
	lean.color = PaperMesh.TIMBER.lightened(0.05)
	lean.box(Vector3(0.0, 1.4, 0.0), Vector3(0.2, 2.8, 0.2))
	var leaning := lean.build()
	leaning.position = Vector3(half * 0.35, 0.0, -1.2)
	leaning.rotation.z = rng.randf_range(0.35, 0.6) * (1.0 if rng.randf() < 0.5 else -1.0)
	ruin.add_child(leaning)
	# The roof, fallen in: two broken slabs of its tiles leaning into the
	# heap, the ridge snapped between them.
	var left_slab := Scenery.tiled_roof(rng, -half - 0.6, rng.randf_range(-0.4, 0.3), Vector2(0.35, 0.9), Vector2(rng.randf_range(1.8, 2.4), -1.9), 4, false)
	left_slab.rotation.z = rng.randf_range(-0.12, -0.04)
	ruin.add_child(left_slab)
	var right_slab := Scenery.tiled_roof(rng, rng.randf_range(0.5, 1.1), half + 0.5, Vector2(rng.randf_range(1.2, 1.7), 0.7), Vector2(0.3, -2.6), 4, false)
	right_slab.rotation.z = rng.randf_range(0.05, 0.14)
	ruin.add_child(right_slab)
	# Beams fallen across, from the heap up onto the slabs.
	for b in 3:
		var from := Vector3(rng.randf_range(-half * 0.8, half * 0.8), rng.randf_range(0.2, 0.5), rng.randf_range(-2.6, -0.4))
		var to := from + Vector3(rng.randf_range(1.6, 2.6) * (1.0 if from.x < 0.0 else -1.0), rng.randf_range(0.9, 1.6), rng.randf_range(-0.6, 0.6))
		var length := from.distance_to(to)
		var piece := PaperMesh.new(rng.randi())
		piece.color = PaperMesh.TIMBER.lightened(0.04 * b)
		piece.box(Vector3(0.0, 0.0, -length * 0.5), Vector3(0.18, 0.2, length))
		var beam := piece.build()
		ruin.add_child(beam)
		beam.transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	# A sheet of its torn wall paper still hanging from the tall back post.
	var sheet := PaperMesh.new(rng.randi())
	sheet.color = Color(0.62, 0.58, 0.52)
	var top_y := tall_post.y - 0.2
	var pts := PackedVector2Array([Vector2(0.0, top_y), Vector2(1.5, top_y - 0.1), Vector2(1.2, top_y - 1.6), Vector2(0.5, top_y - 2.2), Vector2(0.0, top_y - 1.7)])
	sheet.torn_sheet(PaperMesh.tear(pts, 0.15, 0.08, rng), 0.0, Scenery.WALL_PAPER_RIM, 0.035)
	var hanging := sheet.build()
	hanging.position = Vector3(tall_post.x + 0.12, 0.0, tall_post.z + 0.14)
	ruin.add_child(hanging)
	Scenery.windswept(hanging, 0.05, _rng)
	# Tiles strewn out into the street, and a shutter fallen in the wet with
	# one of its charms.
	var strewn := PaperMesh.new(rng.randi())
	strewn.shade_jitter = 0.3
	for n in 26:
		strewn.color = Scenery.ROOF * rng.randf_range(0.7, 1.15)
		strewn.box(Vector3(rng.randf_range(-half - 1.5, half + 1.5), 0.03, rng.randf_range(0.6, 2.4)),
				Vector3(rng.randf_range(0.18, 0.32), 0.05, rng.randf_range(0.14, 0.24)))
	strewn.color = Color(0.2, 0.17, 0.18)
	strewn.box(Vector3(rng.randf_range(-1.0, 1.0), 0.06, 1.3), Vector3(0.9, 0.06, 1.2))
	ruin.add_child(strewn.build())
	var lying := Node3D.new()
	lying.position = Vector3(0.0, 0.1, 1.3)
	lying.rotation = Vector3(-PI * 0.5, 0.0, 0.4)
	ruin.add_child(lying)
	_charm(lying, Vector3.ZERO, 0.0)
	# Dust drifting up out of it.
	var dust := CPUParticles3D.new()
	dust.amount = 24
	dust.lifetime = 3.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(half, 0.4, 1.4)
	dust.direction = Vector3.UP
	dust.spread = 25.0
	dust.gravity = Vector3(0.0, 0.25, 0.0)
	dust.initial_velocity_min = 0.2
	dust.initial_velocity_max = 0.6
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(0.5, 1.0))
	grow.add_point(Vector2(1.0, 0.0))
	dust.scale_amount_curve = grow
	var mote := QuadMesh.new()
	mote.size = Vector2(0.9, 0.9)
	mote.material = PaperMesh.soft_ink(Color(0.36, 0.35, 0.4, 0.25))
	dust.mesh = mote
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dust.position = Vector3(0.0, 0.8, -1.4)
	ruin.add_child(dust)
	dust.emitting = fresh
	if fresh:
		var settle := get_tree().create_timer(7.0)
		settle.timeout.connect(func() -> void:
			if is_instance_valid(dust):
				dust.emitting = false)
		# The wreckage drops into place and settles.
		for c: Node in ruin.get_children():
			if c is Node3D and c != dust and not (c is Light3D):
				var n3 := c as Node3D
				var rest_y := n3.position.y
				n3.position.y = rest_y + rng.randf_range(1.0, 2.4)
				var t := create_tween()
				t.tween_interval(rng.randf_range(0.0, 0.15))
				t.tween_property(n3, "position:y", rest_y, rng.randf_range(0.3, 0.45)).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## A ruin gone and the house whole again (he died: the fight starts over).
func _unruin(k: int) -> void:
	if k < 0 or not _houses[k].has_meta(&"ruin"):
		return
	(_houses[k].get_meta(&"ruin") as Node).queue_free()
	_houses[k].remove_meta(&"ruin")
	_houses[k].visible = true


## Claw gouges raked down a wall: three torn dark strokes.
func _claw_marks(house: Node3D, w: float, hh: float) -> void:
	if _rng.randf() < 0.45:
		return
	var b := PaperMesh.new(_rng.randi())
	b.color = Color(0.05, 0.04, 0.06)
	var x := _rng.randf_range(-w * 0.42, -w * 0.1) if _rng.randf() < 0.5 else _rng.randf_range(w * 0.15, w * 0.42)
	var y := _rng.randf_range(hh * 0.45, hh * 0.7)
	var slant := _rng.randf_range(-0.5, 0.5)
	for k in 3:
		var top := Vector2(x + k * 0.22, y + k * 0.05)
		b.stroke(top, top + Vector2(slant, -_rng.randf_range(1.3, 1.9)), 0.07, 0.01, 0.14)
	b.color = Color(0.55, 0.5, 0.46)
	for k in 3:
		var top := Vector2(x + k * 0.22 + 0.05, y + k * 0.05)
		b.stroke(top, top + Vector2(slant, -1.1), 0.015, 0.004, 0.141)
	house.add_child(b.build())


## What the dragon left in the street: festival lanterns torn down and
## crumpled, an overturned cart, parade streamers lying in the wet.
func _build_debris() -> void:
	for x: float in [221.0, 226.0, 262.5, 277.0, 288.0]:   # (none where it falls)
		_dropped_lantern(Vector3(x, G, _rng.randf_range(-2.4, -1.6)))
	# The overturned cart in the lane: its bed on its side, a wheel up.
	var c := PaperMesh.new(_rng.randi())
	c.shade_jitter = 0.18
	c.color = Scenery.WOOD
	c.box(Vector3(284.0, G + 0.65, -2.6), Vector3(2.2, 1.3, 0.12))
	c.box(Vector3(284.0, G + 0.06, -2.1), Vector3(2.2, 0.12, 1.0))
	c.box(Vector3(284.0, G + 1.25, -2.1), Vector3(2.2, 0.1, 1.0))
	c.color = PaperMesh.TIMBER
	c.box(Vector3(285.6, G + 0.6, -1.7), Vector3(1.6, 0.08, 0.08))
	add_child(c.build())
	# Its two big wheels: one still on its axle, turned up to the sky, one
	# come off and leaning on the cart.
	for k in 2:
		var w := PaperMesh.new(_rng.randi())
		w.shade_jitter = 0.15
		w.color = Scenery.WOOD.darkened(0.1)
		for i in 14:
			var a0 := TAU * i / 14.0
			var a1 := TAU * (i + 1) / 14.0
			w.stroke(Vector2(cos(a0), sin(a0)) * 0.62, Vector2(cos(a1), sin(a1)) * 0.62, 0.1, 0.1, 0.0)
		for i in 6:
			var a := TAU * i / 6.0
			w.stroke(Vector2.ZERO, Vector2(cos(a), sin(a)) * 0.6, 0.05, 0.04, 0.01)
		w.color = PaperMesh.TIMBER
		w.ellipse(Vector2.ZERO, Vector2(0.11, 0.11), 8, 0.02)
		var wheel := w.build()
		if k == 0:
			wheel.position = Vector3(282.9, G + 1.45, -2.0)
			wheel.rotation = Vector3(0.0, 0.0, 0.3)
		else:
			wheel.position = Vector3(286.2, G + 0.6, -1.95)
			wheel.rotation = Vector3(-0.25, 0.0, 0.0)
		add_child(wheel)
	# Streamers lying flat on the stones.
	var s := PaperMesh.new(_rng.randi())
	for k in 9:
		var x := _rng.randf_range(WARD.x + 2.0, WARD.y - 6.0)
		var z := _rng.randf_range(-2.6, 0.8)
		var a := _rng.randf_range(-0.6, 0.6)
		s.color = [FestivalDragon.GOLD, Color(0.58, 0.18, 0.14), LanternMarket.CREAM][k % 3].darkened(0.25)
		var d := Vector3(cos(a), 0.0, sin(a))
		var n := Vector3(-d.z, 0.0, d.x) * 0.07
		var p := Vector3(x, G + 0.02, z)
		s.quad(p - n, p + n, p + d * 1.4 + n, p + d * 1.4 - n, Vector3.UP)
	add_child(s.build())


## A festival lantern torn down: lying on its side, crushed flat on one
## side, its candle out, the paper soaked and torn open over its ribs.
func _dropped_lantern(at: Vector3) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.2
	var rings := []
	for k in 6:
		var t := k / 5.0
		var r := 0.32 * sin(PI * (0.15 + 0.7 * t)) + 0.05
		rings.append(PaperMesh.oval(Vector3(0.0, t * 0.7, 0.0), Vector2(r * 0.55, r), 9))
	b.color = Color(0.48, 0.2, 0.15)
	b.loft(rings)
	b.color = Color(0.06, 0.05, 0.07)
	for k in 5:
		b.frustum(9, Vector2(0.2, 0.34) * sin(PI * (0.15 + 0.14 * (k + 0.5))) / 0.85, Vector2(0.2, 0.34) * sin(PI * (0.15 + 0.14 * (k + 0.5))) / 0.85,
				0.025, Vector3(0.0, (k + 0.5) * 0.14, 0.0))
	b.color = PaperMesh.TIMBER
	b.frustum(8, Vector2(0.1, 0.07), Vector2(0.1, 0.07), 0.06, Vector3(0.0, -0.03, 0.0))
	var mesh := b.build()
	mesh.position = at + Vector3(0.36, 0.2, 0.0)
	mesh.rotation = Vector3(0.0, _rng.randf_range(-0.8, 0.8), PI * 0.5 + _rng.randf_range(-0.2, 0.2))
	add_child(mesh)


func _build_lights() -> void:
	for lx: float in [222.0, 240.0, 256.0, 276.0, 290.0]:
		market._light(Vector3(lx, G + 3.4, -2.4), market.village.lantern_energy * 0.7, market.village.lantern_range * 1.1)
		market._shine(lx, G, 5.0, 0.7)


## The walls of pouring rain that close the square while it lives: sheets
## of falling water down from the storm, splashing at their feet.
func _build_curtains() -> void:
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/waterfall.gdshader")
	look.set_shader_parameter(&"tint", Color(0.58, 0.66, 0.76, 0.42))
	for x: float in [RAIN_WALLS.x, RAIN_WALLS.y]:
		var holder := Node3D.new()
		holder.position = Vector3(x, G + 16.0, 0.0)
		add_child(holder)
		for k in 3:
			var z := -2.6 + k * 1.7
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var rows := 8
			for row in rows:
				for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
					var t := float(row + corner[1]) / rows
					var across: float = corner[0]
					st.set_uv(Vector2(across, t))
					st.add_vertex(Vector3(-0.9 + across * 1.8 + (k % 2) * 0.2, -t * 16.0, z))
			var sheet := MeshInstance3D.new()
			sheet.mesh = st.commit()
			var mine := look.duplicate() as ShaderMaterial
			mine.set_shader_parameter(&"speed", 2.2 + k * 0.2)
			sheet.material_override = mine
			sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(sheet)
		var splash := CPUParticles3D.new()
		splash.amount = 50
		splash.lifetime = 0.5
		splash.emitting = false
		splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		splash.emission_box_extents = Vector3(0.7, 0.05, 2.8)
		splash.direction = Vector3.UP
		splash.spread = 45.0
		splash.gravity = Vector3(0.0, -9.0, 0.0)
		splash.initial_velocity_min = 1.0
		splash.initial_velocity_max = 2.6
		var bead := QuadMesh.new()
		bead.size = Vector2(0.05, 0.05)
		bead.material = WaterFx.bead_material(Color(0.7, 0.74, 0.82))
		splash.mesh = bead
		splash.position = Vector3(0.0, -16.0 + 0.05, -0.6)
		holder.add_child(splash)
		holder.scale = Vector3(1.0, 0.001, 1.0)
		holder.visible = false
		_curtains.append(holder)


## Up (true) or down; the water starts at the storm and reaches the ground,
## and stops the same way (the last of it falls).
func _set_curtains(up: bool) -> void:
	if up and not _walls.is_empty():
		return
	for holder: Node3D in _curtains:
		var splash := holder.get_child(holder.get_child_count() - 1) as CPUParticles3D
		var t := create_tween()
		if up:
			holder.visible = true
			holder.position.y = G + 16.0
			holder.scale.y = 0.001
			t.tween_property(holder, "scale:y", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t.tween_callback(func() -> void: splash.emitting = true)
		else:
			splash.emitting = false
			t.set_parallel()
			t.tween_property(holder, "scale:y", 0.001, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t.tween_property(holder, "position:y", G, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t.chain().tween_callback(func() -> void: holder.visible = false)
	if up and _walls.is_empty():
		for x: float in [RAIN_WALLS.x, RAIN_WALLS.y]:
			var wall := market._solid(Vector3(x, G + 15.0, 0.0), Vector3(0.6, 30.0, 4.0))
			wall.set_meta(&"no_climb", true)
			_walls.append(wall)
		Sound.play(self, &"splash", 4.0)
	elif not up:
		for wall: StaticBody3D in _walls:
			wall.queue_free()
		_walls.clear()


## The gate up to the Lantern Makers' Rise, its door swung open; the Rise
## itself (RiseQuarter) is built from here.
func _build_rise_gate() -> void:
	var gx := RISE_GATE
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.color = PaperMesh.TIMBER.lightened(0.12)
	for pz: float in [1.6, -2.6]:
		b.box(Vector3(gx, G + 2.9, pz), Vector3(0.4, 5.8, 0.4))
	b.box(Vector3(gx, G + 5.4, -0.5), Vector3(0.5, 0.35, 5.2))
	add_child(b.build())
	# Its door stands open, swung back into the Ward (the way up is
	# barred by fire instead: RiseQuarter).
	var door := PaperMesh.new(_rng.randi())
	door.color = Scenery.WOOD.darkened(0.2)
	door.box(Vector3(gx - 1.95, G + 2.5, -2.55), Vector3(3.8, 5.0, 0.18))
	door.color = Color(0.09, 0.08, 0.1)
	for y: float in [1.2, 3.6]:
		door.box(Vector3(gx - 1.95, G + y, -2.43), Vector3(3.8, 0.18, 0.06))
	add_child(door.build())
	# Walls either side of it (Julian: every gate, not only the Ward's).
	GateWalls.build(self, market, _rng, gx, G, -2.6, 1.6, -5.1, 5.3, Vector2(293.6, gx - 0.22))
	var rise := RiseQuarter.new()
	rise.market = market
	rise.quarter = quarter
	rise.ward = self
	add_child(rise)
	add_child(Scenery.tiled_roof(_rng, gx - 1.2, gx + 1.2, Vector2(G + 5.6, 2.4), Vector2(G + 6.8, -0.5), 3))
	add_child(Scenery.tiled_roof(_rng, gx - 1.2, gx + 1.2, Vector2(G + 5.6, -3.4), Vector2(G + 6.8, -0.5), 3, false))
	market._hang(Vector3(gx - 0.5, G + 6.05, 1.2), 1.0, 0.8)   # (hooked right under the roof)


## The fan-maker's shop: a counter at the front of her house with three fans
## standing open on it, a pot of pinwheels beside it turning in the wind
## (her wares, left out when the Ward shut; the gust whirs them).
func _build_fan_shop() -> void:
	var x := FAN_SHOP
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	b.color = Scenery.WOOD.darkened(0.1)
	b.box(Vector3(x, G + 0.5, -2.9), Vector3(2.4, 1.0, 0.6))
	b.color = PaperMesh.TIMBER
	b.box(Vector3(x, G + 1.02, -2.9), Vector3(2.5, 0.05, 0.7))
	b.color = Color(0.3, 0.34, 0.5)   # an indigo cloth along its front
	b.box(Vector3(x, G + 0.78, -2.58), Vector3(2.4, 0.4, 0.02))
	add_child(b.build())
	for k in 3:
		var fan := PaperFan.new()
		fan.position = Vector3(x - 0.75 + k * 0.75, G + 1.05, -2.95)
		fan.rotation.z = deg_to_rad(10.0)
		fan.scale = Vector3.ONE * 0.85
		add_child(fan)
		fan.open = 0.9 - k * 0.15
	var pot := PaperMesh.new(_rng.randi())
	pot.color = Color(0.34, 0.26, 0.22)
	pot.frustum(10, Vector2(0.2, 0.2), Vector2(0.26, 0.26), 0.45, Vector3(x + 1.8, G, -2.7))
	add_child(pot.build())
	for k in 3:
		var wheel := Pinwheel.new()
		wheel.height = 0.95 + k * 0.18
		wheel.position = Vector3(x + 1.72 + k * 0.08, G + 0.3, -2.7 + k * 0.05)
		wheel.rotation.z = (k - 1) * 0.12
		add_child(wheel)


## After the dragon: the fan-maker is back at her counter (a paper doll like
## the market's shopkeepers, in indigo, fanning herself).
func _fan_maker_comes() -> void:
	if _fan_maker:
		return
	_fan_maker = MarketKeeper.new()
	_fan_maker.robe = Color(0.28, 0.32, 0.48)
	_fan_maker.work = "fan"
	_fan_maker.position = Vector3(FAN_SHOP, G, -3.45)
	add_child(_fan_maker)


## She holds out a fan; it flies to his hand and folds shut there: he has the
## Fan Gust (SaveGame "gust"), and its card shows.
func _give_fan() -> void:
	_fan_given = true
	var fan := PaperFan.new()
	add_child(fan)
	fan.position = Vector3(FAN_SHOP + 0.35, G + 1.3, -3.0)
	fan.rotation.z = deg_to_rad(10.0)
	fan.scale = Vector3.ONE * 0.8
	Sound.play(self, &"fan_gust", -4.0)
	var ronin := _ronin
	var hand := func() -> Vector3: return to_local(ronin.global_position) + Vector3(0.0, 1.1, 0.3)
	var t := create_tween()
	t.tween_property(fan, "open", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_interval(0.5)
	t.tween_property(fan, "position", hand.call() + Vector3(0.0, 0.8, 0.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(fan, "rotation:z", deg_to_rad(370.0), 0.6)
	t.tween_property(fan, "position", hand.call(), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(fan, "open", 0.0, 0.35)
	t.parallel().tween_property(fan, "scale", Vector3.ONE * 0.3, 0.35)
	t.tween_callback(func() -> void:
		fan.queue_free()
		learn_gust())


func learn_gust() -> void:
	if _ronin:
		_ronin.has_gust = true
		(_ronin.get_node("Puppet") as RoninPuppet).play_healed()
	if "gust" not in SaveGame.abilities:
		SaveGame.abilities.append("gust")
	SaveGame.write()
	Sound.play(self, &"draw_ready", 0.0)
	var card := AbilityCard.new()
	card.title = "Fan Gust"
	card.prompts = [["O", "RT", "Fan Gust"], ["S + O", "Down + RT", "Lift, in the air"]]
	card.advice = "A paper fan's gust: blows back fire and paper, whirs wheels, sways what hangs. Gust down in the air to lift yourself."
	var ronin := _ronin
	card.used = func() -> bool: return is_instance_valid(ronin) and ronin.has_gusted
	var where := _overlay_node()
	if where:
		where.add_child(card)


# --- The fight ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
		_ronin.died.connect(_on_ronin_died)
	var x := _ronin.global_position.x - market.global_position.x
	var camera := get_viewport().get_camera_3d() as FollowCamera
	if camera:
		var watching := _state in [&"intro", &"fight"] and dragon.visible and dragon.mode() != &"perch"
		if watching:
			camera.focus = dragon.to_global(dragon.head)
			_focused = true
		elif _focused:
			camera.focus = Vector3(NAN, NAN, NAN)
			_focused = false
	match _state:
		&"before":
			if x > ARENA.x + 3.0 and x < ARENA.y - 3.0 and _ronin.is_on_floor() and _ronin.is_physics_processing():
				if SaveGame.dragon_met:
					_start_fight()
				else:
					_start_intro()
		&"intro":
			_run_intro()
		&"after":
			_run_after()
	if _fan_maker and not _fan_given and not "gust" in SaveGame.abilities 			and absf(x - FAN_SHOP) < 1.4 and _ronin.is_on_floor() and _ronin.is_physics_processing():
		_give_fan()


func _overlay_node() -> Node:
	var hud := get_tree().get_first_node_in_group(&"hud")
	return hud.get_parent() if hud else null


func _start_intro() -> void:
	_state = &"intro"
	_time = 0.0
	_slammed = 0
	SaveGame.dragon_met = true
	_ronin.set_physics_process(false)
	_ronin.velocity = Vector3.ZERO
	var puppet: RoninPuppet = _ronin.get_node("Puppet")
	puppet.state = &"idle"
	_hud = get_tree().get_first_node_in_group(&"hud") as CanvasItem
	if _hud:
		_hud.visible = false
	Sound.duck_music(true)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var where := _overlay_node()
	if where:
		where.add_child(_overlay)
	_title = _make_title()
	_overlay.add_child(_title)
	_skip = SkipPrompt.new()
	_overlay.add_child(_skip)
	_skip.skipped.connect(func() -> void:
		if _state == &"intro" and _cine:
			_cine.finish())
	_direct_intro()


func _make_title() -> HannyaTitle:
	var title := HannyaTitle.new()
	title.KANJI = preload("res://textures/title_dragon_kanji.png")
	title.NAME = preload("res://textures/title_dragon_name.png")
	title.SUBTITLE = preload("res://textures/title_dragon_subtitle.png")
	title.SEAL = preload("res://textures/seal_dragon.png")
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return title


## The intro, shot by shot (Julian: much more dramatic and cinematic):
##   0    Low along the street, the camera dollies past the houses as the
##        last open shutters slam one by one, each a jolt.
##   2.4  A cracked bell. The camera tilts up to the storm over the roofs:
##        lightning, and in its flash a long shape crossing the clouds.
##   3.6  It pours down off the roofs: the camera tracks its head as it
##        sweeps low over him, a roar as it passes.
##   5.6  Low by the stone lantern as it coils round it, pushing in.
##   7.4  Its head, close: it turns to us, roars, laughs.
##   9.2  Pulling back and up over the square, its name painted; the walls
##        of rain fall at both ends. 12: the fight.
func _direct_intro() -> void:
	_cine = CineCamera.new()
	_cine.game_camera = get_viewport().get_camera_3d()
	_cine.length = 12.0
	var m := market.global_position
	var g := m.y + G
	var r := _ronin.global_position
	var l := m + LANTERN
	var head := func() -> Vector3: return dragon.to_global(dragon.head)
	_cine.shot(0.0, 2.4, Vector3(r.x + 1.0, g + 1.3, 7.5), Vector3(r.x + 9.0, g + 1.6, 7.0),
			Vector3(r.x + 7.0, g + 2.6, -4.0), Vector3(r.x + 15.0, g + 2.8, -4.0), Vector2(40.0, 38.0))
	_cine.shot(2.4, 3.6, Vector3(l.x - 7.0, g + 0.8, 10.0), Vector3(l.x - 6.0, g + 0.7, 10.5),
			Vector3(l.x - 2.0, g + 5.0, -4.0), Vector3(l.x + 3.0, g + 11.0, -8.0), Vector2(46.0, 50.0))
	_cine.shot(3.6, 5.6, func() -> Vector3: return head.call() + Vector3(-3.0, 1.0, 10.0),
			func() -> Vector3: return head.call() + Vector3(2.0, 0.6, 8.0), head, head, Vector2(42.0, 38.0), Vector2(-3.0, 2.0), 0.06)
	_cine.shot(5.6, 7.4, Vector3(l.x - 3.6, g + 0.5, l.z + 6.5), Vector3(l.x - 2.2, g + 0.7, l.z + 4.8),
			Vector3(l.x, g + 2.4, l.z), Vector3(l.x, g + 3.6, l.z), Vector2(40.0, 34.0))
	_cine.shot(7.4, 9.2, func() -> Vector3: return head.call() + Vector3(-0.7, -0.4, 4.4),
			func() -> Vector3: return head.call() + Vector3(-0.5, -0.5, 3.4), head, head, Vector2(34.0, 28.0), Vector2(2.0, -2.0), 0.02)
	_cine.shot(9.2, 12.0, Vector3(l.x - 2.0, g + 3.5, 8.0), Vector3(l.x - 4.0, g + 5.5, 21.0),
			Vector3(l.x, g + 4.0, -2.0), Vector3(l.x, g + 3.5, -2.0), Vector2(38.0, 40.0), Vector2.ZERO, 0.02, 0.8)
	_cine.at(2.4, func() -> void:
		Sound.play(self, &"fire_bell", 2.0)
		dragon.play_intro(LANTERN))
	_cine.at(2.9, func() -> void:
		dragon.bolt_visual(Vector3(LANTERN.x + 9.0, G + 6.0, -14.0))
		_cine.flash(0.3, 0.4)
		_cine.shake(0.3))
	_cine.at(3.3, func() -> void: Sound.play(self, &"dragon_roar", -2.0))
	_cine.at(4.7, func() -> void:
		_cine.shake(0.6)
		Sound.play(self, &"dragon_roar", 2.0))
	_cine.at(7.4, func() -> void:
		dragon.look_override = dragon.to_local(_cine.camera().global_position))
	_cine.at(7.6, func() -> void:
		Sound.play(self, &"dragon_roar", 4.0)
		dragon.set(&"_jaw", 1.0)
		_cine.shake(0.9))
	_cine.at(8.5, func() -> void: Sound.play(self, &"dragon_laugh", 3.0))
	_cine.at(9.2, func() -> void: dragon.look_override = Vector3(NAN, NAN, NAN))
	_cine.at(9.4, func() -> void:
		_title.paint()
		Sound.play(self, &"taiko_hit", 0.0))
	_cine.at(10.6, func() -> void:
		_set_curtains(true)
		_cine.shake(0.25))
	_cine.finished.connect(func() -> void:
		dragon.look_override = Vector3(NAN, NAN, NAN)
		if _state == &"intro":
			_end_intro())
	add_child(_cine)


func _run_intro() -> void:
	var puppet: RoninPuppet = _ronin.get_node("Puppet")
	var open := _windows.filter(func(w: Dictionary) -> bool: return w["open"] and not (w["house"] as Node3D).has_meta(&"ruin"))
	if _cine and _cine.time > 0.4 + _slammed * 0.3 and _cine.time < 2.4 and not open.is_empty():
		_slammed += 1
		# Nearest him first, outward.
		open.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return absf((a["house"] as Node3D).position.x - _ronin_x()) < absf((b["house"] as Node3D).position.x - _ronin_x()))
		_set_shutters(open[0], false, true)
		Sound.play(self, &"shutter_slam", -2.0 + _rng.randf_range(-2.0, 1.0))
		_cine.shake(0.12)
	if dragon.mode() == &"intro":
		puppet.facing = signf(dragon.head.x - _ronin_x()) if absf(dragon.head.x - _ronin_x()) > 0.5 else puppet.facing
		_ronin.facing = puppet.facing



func _ronin_x() -> float:
	return _ronin.global_position.x - market.global_position.x


func _end_intro() -> void:
	if _state != &"intro":
		return
	_state = &"starting"
	if _cine:
		var cine := _cine
		_cine = null
		cine.finish()
	if _overlay:
		var fade := create_tween()
		fade.tween_property(_overlay, "modulate:a", 0.0, 0.5)
		fade.tween_callback(_overlay.queue_free)
		_overlay = null
	for w: Dictionary in _windows:
		if w["open"]:
			_set_shutters(w, false, true)
	if _hud:
		_hud.visible = true
	_ronin.set_physics_process(true)
	_start_fight()


func _start_fight() -> void:
	_state = &"fight"
	if dragon.mode() in [&"perch", &"intro"]:
		dragon.begin()
	_set_curtains(true)
	Sound.duck_music(true)
	_play_music(true)
	_camera_back(true)
	if _bar == null:
		_bar = BossBar.new()
		_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		var where := _overlay_node()
		if where:
			where.add_child(_bar)
		_bar.watch(dragon, preload("res://textures/title_dragon_kanji.png"), preload("res://textures/title_dragon_name.png"))
	dragon.health_changed.emit(dragon.health, dragon.max_health)


func _camera_back(on: bool) -> void:
	var camera := get_viewport().get_camera_3d() as FollowCamera
	if camera == null:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "distance", fight_camera_distance if on else 15.0, 1.5).set_trans(Tween.TRANS_SINE)


func _play_music(on: bool) -> void:
	if _music_fade:
		_music_fade.kill()
		_music_fade = null
	if on:
		Sound.follow_level(_music, music_volume)
		if not _music.playing:
			_music.play()
	elif _music.playing:
		_music_fade = create_tween()
		_music_fade.tween_property(_music, "volume_db", -60.0, music_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_fade.tween_callback(_music.stop)


## Its death (Julian: much more dramatic and cinematic):
##   0    The killing cut: everything slows (a quarter speed for a moment),
##        a white flash; the camera pushes in on its head.
##   1    It writhes up into the storm; the camera, low, looks up after it.
##   3.3  Lightning strikes it, twice; it comes apart in the air, and the
##        camera, wide, follows the rain of paper down.
##   5.1  Its head crashes onto the stones last.
##   5.7  Quiet. The walls of rain stop, the clouds part, moonlight falls on
##        the heap; the camera eases in on him standing by it. 9: play.
func _direct_death() -> void:
	_cine = CineCamera.new()
	_cine.game_camera = get_viewport().get_camera_3d()
	_cine.length = 9.0
	var m := market.global_position
	var g := m.y + G
	var hx := dragon.to_global(dragon.head).x
	var head := func() -> Vector3: return dragon.to_global(dragon.head)
	_cine.shot(0.0, 1.0, func() -> Vector3: return head.call() + Vector3(-1.6, 0.6, 6.0),
			func() -> Vector3: return head.call() + Vector3(-0.9, 0.3, 4.2), head, head, Vector2(36.0, 32.0))
	_cine.shot(1.0, 3.3, Vector3(hx - 3.0, g + 0.9, 9.0), Vector3(hx - 3.5, g + 0.8, 9.5), head, head,
			Vector2(46.0, 50.0), Vector2(0.0, -3.0), 0.04)
	_cine.shot(3.3, 5.7, Vector3(hx - 1.0, g + 5.5, 16.0), Vector3(hx - 1.0, g + 2.6, 13.0), head,
			Vector3(hx, g + 0.9, m.z - 2.0), Vector2(44.0, 40.0), Vector2.ZERO, 0.03)
	_cine.shot(5.7, 9.0, Vector3(hx - 4.5, g + 1.7, 10.5), Vector3(hx - 3.0, g + 1.4, 7.8),
			Vector3(hx - 0.5, g + 1.0, m.z - 2.0), Vector3(hx, g + 0.9, m.z - 2.0), Vector2(40.0, 36.0), Vector2.ZERO, 0.015, 0.8)
	_cine.at(0.0, func() -> void:
		_cine.flash(0.7, 0.6)
		_cine.shake(0.5)
		Engine.time_scale = 0.25)
	_cine.at(0.9, func() -> void: Engine.time_scale = 1.0)
	dragon.struck_down.connect(func() -> void:
		if _cine:
			_cine.flash(0.8, 0.5)
			_cine.shake(0.7), CONNECT_ONE_SHOT)
	dragon.crashed.connect(func() -> void:
		if _cine:
			_cine.shake(1.0), CONNECT_ONE_SHOT)
	_cine.at(5.9, func() -> void:
		_set_curtains(false)
		_moonlight())
	_cine.finished.connect(func() -> void:
		Engine.time_scale = 1.0
		_cine = null
		if _hud:
			_hud.visible = true
		if _held:
			_held = false
			_ronin.set_physics_process(true))
	add_child(_cine)


## After it falls: the clouds over the Ward part and a shaft of pale
## moonlight comes down on the heap, then fades as the night settles.
func _moonlight() -> void:
	var x := dragon.head.x - 1.0
	var beam := PaperMesh.new(3)
	beam.fade_quad(Vector3(x - 1.6, G, -2.8), Vector3(x - 4.0, G + 22.0, -6.0), Vector3(x + 4.0, G + 22.0, -6.0), Vector3(x + 3.0, G, -2.8),
			Color(0.75, 0.8, 0.95, 0.22), Color(0.75, 0.8, 0.95, 0.0))
	var mesh := beam.build_veil(true)
	add_child(mesh)
	mesh.scale = Vector3(1.0, 0.001, 1.0)
	var t := create_tween()
	t.tween_property(mesh, "scale:y", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_interval(6.0)
	t.tween_property(mesh, "scale:x", 0.001, 3.0).set_trans(Tween.TRANS_SINE)
	t.tween_callback(mesh.queue_free)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.78, 1.0)
	light.light_energy = 0.0
	light.omni_range = 9.0
	light.position = Vector3(x, G + 4.0, -1.5)
	add_child(light)
	var l := create_tween()
	l.tween_property(light, "light_energy", 1.6, 1.6)
	l.tween_interval(6.0)
	l.tween_property(light, "light_energy", 0.0, 3.0)
	l.tween_callback(light.queue_free)


func _on_defeated() -> void:
	_state = &"after"
	_time = 0.0
	_opened = 0
	_hud = get_tree().get_first_node_in_group(&"hud") as CanvasItem
	if _hud:
		_hud.visible = false
	_direct_death()
	SaveGame.dragon_beaten = true
	SaveGame.ward_ruins.clear()
	for k in _houses.size():
		if _houses[k].has_meta(&"ruin"):
			SaveGame.ward_ruins.append(k)
	_play_music(false)
	if _bar:
		_bar.hide_bar()


## After: it comes apart (FestivalDragon); the rain walls stop (2.5 s);
## the shutters slide open one by one from the middle outward (from 3.5 s),
## and the people come back to their windows.
func _run_after() -> void:
	# He stands and watches while it dies (held once his feet are down).
	if _cine and not _held and _ronin.is_on_floor():
		_held = true
		_ronin.set_physics_process(false)
		_ronin.velocity = Vector3.ZERO
		var puppet: RoninPuppet = _ronin.get_node("Puppet")
		puppet.state = &"idle"
		puppet.facing = signf(dragon.to_global(dragon.head).x - _ronin.global_position.x)
		_ronin.facing = puppet.facing
	if _time > 6.0 and not _settled:
		_settled = true
		Sound.duck_music(false)
		_camera_back(false)
	var shut := _windows.filter(func(w: Dictionary) -> bool: return not w["open"] and not (w["house"] as Node3D).has_meta(&"ruin"))
	if _time > 6.5 + _opened * 0.4 and not shut.is_empty():
		_opened += 1
		var mid := (ARENA.x + ARENA.y) * 0.5
		shut.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return absf((a["house"] as Node3D).position.x - mid) < absf((b["house"] as Node3D).position.x - mid))
		_set_shutters(shut[0], true, true)
		Sound.play(self, &"shutter_open", -6.0 + _rng.randf_range(-2.0, 1.0))
	if _time > 6.5 and _fan_maker == null:
		_fan_maker_comes()
	if shut.is_empty() and _time > 7.0 and _cine == null:
		_add_shadows()
		_state = &"done"
		SaveGame.write()


## Someone at home at every window again (VillagerShadow: shy, they duck
## out of sight as he comes near).
func _add_shadows() -> void:
	if _shadows_added:
		return
	_shadows_added = true
	for i in _houses.size():
		var house := _houses[i]
		if not house.has_meta("window") or house.has_meta(&"ruin"):
			continue
		var shadow := VillagerShadow.new()
		shadow.window_size = house.get_meta("window_size")
		shadow.round_window = house.get_meta("window_round")
		shadow.activity = ["pace", "kneel"][i % 2]
		shadow.position = house.position + (house.get_meta("window") as Vector3) + Vector3(0.0, 0.0, 0.1)
		add_child(shadow)


func _on_ronin_died() -> void:
	if _state != &"fight":
		return
	# It waits for him to come back; the rain walls stop; the houses it
	# crushed stand again.
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func() -> void:
		_state = &"before"
		_set_curtains(false)
		if _bar:
			_bar.hide_bar()
		_play_music(false)
		Sound.duck_music(false)
		_camera_back(false)
		dragon.reset())
