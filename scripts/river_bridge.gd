class_name RiverBridge
extends Node3D
## The River and the Red Bridge (area 4 of the expanded village,
## docs/village_map.png). The river crosses the street, flowing toward us
## between stone embankments; a red arched bridge spans it, but its middle
## has fallen in: jump, and dash, to get across. (Gusts over the water used
## to push him west; Julian had that taken out: "the samurai slides slowly
## to the left".) Falling in, the river carries him off (back to the last
## shrine). On the east bank stands the river warehouse, with the second
## shrine at its door.

## How high the bridge's arch rises in the middle (metres).
const ARCH := 1.0
## The fallen middle of the bridge: between these x.
const GAP := Vector2(97.0, 103.0)
## The river's surface and its bed (the vault of the canal below).
const WATER := -0.75
const BED := -1.45
## Faded red lacquer: a red bridge, but old and rained on.
const LACQUER := Color(0.46, 0.15, 0.11)

var village: Village
var shrine: RestShrine
var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _carried_off := false
var _last_y := 0.0


func _ready() -> void:
	process_physics_priority = -5
	_rng.seed = 8801
	_build_river()
	_build_bridge()
	for x: float in [88.0, 101.0, 114.0]:
		Sound.place_loop(self, "river_flow.ogg", Vector3(x, WATER, -1.0), -10.0, 7.0)
	_build_warehouse()


## Height of the bridge deck at x (0 at the banks, ARCH in the middle).
static func deck_at(x: float) -> float:
	var t := clampf((x - Village.RIVER.x) / (Village.RIVER.y - Village.RIVER.x), 0.0, 1.0)
	return ARCH * sin(t * PI)


# --- The river ---------------------------------------------------------------

func _build_river() -> void:
	var left := Village.RIVER.x
	var right := Village.RIVER.y
	# The water, from far behind (where it joins the river in the backdrop)
	# to the cut at the front.
	WaterFx.surface(self, left, right, WATER, -15.0, 1.5, Color(0.05, 0.07, 0.13))
	# The cut-away at the front: the river's depth as a band of dark water
	# with a pale torn rim, above the stone of the vault.
	var cut := PaperMesh.new(_rng.randi())
	cut.shade_jitter = 0.03
	cut.color = Color(0.1, 0.14, 0.26)
	var line := PackedVector2Array()
	var x := left
	while x < right:
		line.append(Vector2(x, WATER + _rng.randf_range(-0.03, 0.03)))
		x += _rng.randf_range(0.8, 1.6)
	line.append(Vector2(right, WATER))
	var outline := PaperMesh.tear(line, 0.3, 0.015, _rng, false)
	outline.append(Vector2(right, BED))
	outline.append(Vector2(left, BED))
	cut.torn_sheet(outline, 1.52, Color(0.34, 0.42, 0.62), 0.025)
	var band := cut.build()
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(band)
	# Stone embankments on both banks, all the way back.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	for side: Array in [[left, 1.0], [right, -1.0]]:
		var bx: float = side[0]
		var face: float = side[1]
		b.color = Canals.STONE.lightened(0.06)
		b.box(Vector3(bx - face * 0.3, (BED - 0.6) * 0.5, -6.5), Vector3(0.6, -BED + 0.6, 16.0))
		b.color = Canals.STONE_JOINT
		var y := BED + 0.35
		while y < -0.05:
			b.box(Vector3(bx + face * 0.005, y, -6.5), Vector3(0.012, 0.03, 16.0))
			y += 0.36
		b.color = Canals.MOSS_DARK
		b.box(Vector3(bx + face * 0.006, WATER + 0.1, -6.5), Vector3(0.014, 0.16, 16.0))
		# The coping stones along the top of the embankment.
		b.color = Canals.STONE.lightened(0.18)
		b.box(Vector3(bx - face * 0.3, -0.05, -6.5), Vector3(0.7, 0.1, 16.0))
	add_child(b.build())
	# The current: pale flecks and foam streaks flowing toward us.
	var flow := CPUParticles3D.new()
	flow.amount = 90
	flow.lifetime = 9.0
	flow.preprocess = 9.0
	flow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	flow.emission_box_extents = Vector3((right - left) * 0.48, 0.0, 0.5)
	flow.direction = Vector3(0.0, 0.0, 1.0)
	flow.spread = 4.0
	flow.gravity = Vector3.ZERO
	flow.initial_velocity_min = 1.4
	flow.initial_velocity_max = 2.2
	var streak := QuadMesh.new()
	streak.size = Vector2(0.06, 0.4)
	streak.orientation = PlaneMesh.FACE_Y
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.55, 0.62, 0.8, 0.35)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.disable_fog = true
	streak.material = look
	flow.mesh = streak
	flow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flow.position = Vector3((left + right) * 0.5, WATER + 0.01, -14.0)
	add_child(flow)
	# Rain hitting the river: rings would be generic; little jets instead.
	village._add_rain_splashes(left + 0.4, right - 0.4, WATER)


# --- The bridge ---------------------------------------------------------------

func _build_bridge() -> void:
	var left := Village.RIVER.x
	var right := Village.RIVER.y
	# What he walks on: a chain of solid pieces whose tops follow the arch
	# exactly, so the walk up and over is smooth. Not across the gap.
	var x := left - 0.3
	while x < right + 0.29:
		var x1 := minf(x + 0.8, right + 0.3)
		if x1 > GAP.x and x < GAP.y:
			if x < GAP.x:
				x1 = GAP.x
			else:
				x = GAP.y
				continue
		var h0 := deck_at(x)
		var h1 := deck_at(x1)
		var shape := ConvexPolygonShape3D.new()
		shape.points = PackedVector3Array([
			Vector3(x, h0, -1.1), Vector3(x1, h1, -1.1), Vector3(x1, h1 - 0.35, -1.1), Vector3(x, h0 - 0.35, -1.1),
			Vector3(x, h0, 1.1), Vector3(x1, h1, 1.1), Vector3(x1, h1 - 0.35, 1.1), Vector3(x, h0 - 0.35, 1.1)])
		var body := StaticBody3D.new()
		var holder := CollisionShape3D.new()
		holder.shape = shape
		body.add_child(holder)
		add_child(body)
		x = x1
	# The deck: planks across, on two great beams that follow the arch.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	x = left - 0.2
	while x < right + 0.2:
		var x1 := x + _rng.randf_range(0.28, 0.36)
		if _in_gap(x) or _in_gap(x1):
			x = x1
			continue
		var h := deck_at((x + x1) * 0.5)
		b.color = Scenery.WOOD.darkened(_rng.randf_range(0.15, 0.35))
		var tilt := Vector2(x1 - x, deck_at(x1) - deck_at(x))
		var pts := PackedVector2Array([Vector2(x, deck_at(x) - 0.09), Vector2(x1, deck_at(x1) - 0.09), Vector2(x1, deck_at(x1)), Vector2(x, deck_at(x))])
		b.extrude(pts, -1.12, 1.12 - _rng.randf_range(0.0, 0.06))
		x = x1
	# The beams under the deck, and the railings, in faded red lacquer.
	for span: Vector2 in [Vector2(left - 0.2, GAP.x - _rng.randf_range(0.3, 0.6)), Vector2(GAP.y + _rng.randf_range(0.3, 0.6), right + 0.2)]:
		for z: float in [1.0, -1.0]:
			_arch_strip(b, span, -0.1, -0.42, z - 0.12, z + 0.12, LACQUER.darkened(0.2))
		# Railings: a top rail, a lower rail, posts with bronze caps.
		for z: float in [1.2, -1.2]:
			_arch_strip(b, span, 0.95, 0.85, z - 0.06, z + 0.06, LACQUER)
			_arch_strip(b, span, 0.45, 0.39, z - 0.04, z + 0.04, LACQUER.darkened(0.1))
			var post := span.x
			while post <= span.y + 0.01:
				var h := deck_at(post)
				b.color = LACQUER
				b.box(Vector3(post, h + 0.48, z), Vector3(0.11, 1.0, 0.11))
				b.color = Color(0.34, 0.3, 0.22)  # bronze, gone dull
				b.frustum(8, Vector2(0.07, 0.07), Vector2(0.01, 0.01), 0.16, Vector3(post, h + 0.98, z))
				post += 1.9
		# Piers down into the river.
		var pier := span.x + 2.5
		while pier < span.y - 1.0:
			for z: float in [0.95, -0.95]:
				b.color = LACQUER.darkened(0.35)
				b.box(Vector3(pier, (deck_at(pier) - 0.4 + BED) * 0.5, z), Vector3(0.22, deck_at(pier) - 0.4 - BED, 0.22))
				b.color = Canals.SLIME
				b.box(Vector3(pier, WATER + 0.1, z), Vector3(0.24, 0.2, 0.24))
			b.color = LACQUER.darkened(0.3)
			b.box(Vector3(pier, deck_at(pier) - 0.5, 0.0), Vector3(0.18, 0.14, 2.1))
			pier += 4.2
	# The broken ends: splintered planks and beams sticking out over the gap,
	# a railing hanging down, swaying.
	for end: Array in [[GAP.x, 1.0], [GAP.y, -1.0]]:
		var ex: float = end[0]
		var out: float = end[1]
		var h := deck_at(ex)
		b.color = Scenery.WOOD.darkened(0.3)
		for k in 4:
			var z := _rng.randf_range(-0.9, 0.9)
			var reach := _rng.randf_range(0.15, 0.6)
			b.extrude(PackedVector2Array([Vector2(ex - out * 0.1, h - 0.09), Vector2(ex + out * reach, h - 0.09 - reach * 0.3),
					Vector2(ex + out * (reach - 0.06), h - reach * 0.2), Vector2(ex - out * 0.1, h)]) if out > 0.0 else
					PackedVector2Array([Vector2(ex + out * reach, h - 0.09 - reach * 0.3), Vector2(ex - out * 0.1, h - 0.09),
					Vector2(ex - out * 0.1, h), Vector2(ex + out * (reach - 0.06), h - reach * 0.2)]), z - 0.12, z + 0.12)
	add_child(b.build())
	for end: Array in [[GAP.x - 0.4, 1.0], [GAP.y + 0.4, -1.0]]:
		var hang := Node3D.new()
		hang.position = Vector3(end[0], deck_at(end[0]) + 0.92, 1.2)
		add_child(hang)
		var rail := PaperMesh.new(_rng.randi())
		rail.color = LACQUER
		rail.stroke(Vector2(0.0, 0.0), Vector2(end[1] * 0.25, -1.3), 0.08, 0.07)
		rail.color = LACQUER.darkened(0.2)
		rail.stroke(Vector2(end[1] * 0.12, -0.6), Vector2(end[1] * 0.5, -0.75), 0.05, 0.05, 0.01)
		hang.add_child(rail.build())
		Scenery.windswept(hang, 0.06, _rng)
	# Lanterns on a rope over the west half (the last lights before the gap).
	var string := LanternString.new()
	string.span = 9.0
	string.height = 6.0
	string.sag = 1.1
	string.count = 3
	string.position = Vector3(85.6, deck_at(85.6), 0.0)
	add_child(string)


func _in_gap(x: float) -> bool:
	return x > GAP.x and x < GAP.y


## A strip following the arch (a beam or a rail) between two heights above
## the deck, from z0 to z1.
func _arch_strip(b: PaperMesh, span: Vector2, upper: float, lower: float, z0: float, z1: float, colour: Color) -> void:
	b.color = colour
	var x := span.x
	while x < span.y - 0.01:
		var x1 := minf(x + 0.6, span.y)
		b.extrude(PackedVector2Array([Vector2(x, deck_at(x) + lower), Vector2(x1, deck_at(x1) + lower),
				Vector2(x1, deck_at(x1) + upper), Vector2(x, deck_at(x) + upper)]), z0, z1)
		x = x1


# --- The river warehouse -----------------------------------------------------

## A big plastered storehouse on the east bank, its lower walls faced with
## tiles in a lattice (namako), heavy doors slid half open on a lit store
## of rice bales and crates, a crest painted over the door. The second
## shrine stands at its door.
func _build_warehouse() -> void:
	var left := Village.RIVER.y + 0.6
	var right := left + 7.4
	var middle := (left + right) * 0.5
	var z := Village.HOUSE_Z
	var height := 5.0
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.07
	# Walls: plaster over a dark body, solid all round.
	b.color = Scenery.WALL_DARK
	b.box(Vector3(middle, height * 0.5, z - 1.4), Vector3(right - left, height, 2.8))
	b.color = Color(0.6, 0.59, 0.58)
	b.rect(Vector2(middle, height * 0.62), Vector2(right - left - 0.1, height * 0.76), z + 0.01)
	# Damp stains on the plaster, running down from the eaves.
	b.color = Color(0.45, 0.44, 0.47)
	for k in 4:
		var sx := _rng.randf_range(left + 0.5, right - 0.5)
		b.stroke(Vector2(sx, height - 0.1), Vector2(sx + _rng.randf_range(-0.1, 0.1), height - _rng.randf_range(1.0, 2.6)), 0.3, 0.08, z + 0.015)
	# Namako tiles: dark squares with pale raised joints in a lattice.
	b.color = Color(0.16, 0.17, 0.24)
	b.rect(Vector2(middle, 0.62), Vector2(right - left - 0.1, 1.24), z + 0.02)
	b.color = Color(0.66, 0.64, 0.62)
	var tx := left + 0.25
	while tx < right - 0.2:
		b.stroke(Vector2(tx - 0.3, 0.05), Vector2(tx + 0.3, 1.2), 0.035, 0.035, z + 0.03)
		b.stroke(Vector2(tx + 0.3, 0.05), Vector2(tx - 0.3, 1.2), 0.035, 0.035, z + 0.031)
		tx += 0.6
	# The doorway: a big opening, doors slid back, a lit store inside.
	var door := Vector2(middle + 0.6, 1.5)
	b.color = Color(0.07, 0.06, 0.08)
	b.rect(door, Vector2(2.2, 3.0), z + 0.035)
	b.color = PaperMesh.TIMBER
	b.box(Vector3(door.x, 3.08, z + 0.1), Vector3(2.6, 0.16, 0.16))
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(door.x + side * 1.16, 1.5, z + 0.1), Vector3(0.14, 3.0, 0.16))
	# The heavy door, slid back over the wall to the right, iron-banded.
	b.color = Scenery.WOOD.darkened(0.3)
	b.box(Vector3(door.x + 1.9, 1.5, z + 0.2), Vector3(1.3, 2.9, 0.1))
	b.color = Color(0.12, 0.12, 0.14)
	for band: float in [0.6, 1.5, 2.4]:
		b.box(Vector3(door.x + 1.9, band, z + 0.26), Vector3(1.32, 0.06, 0.02))
	# Inside: rice bales and crates, lit warm.
	b.color = Color(0.5, 0.42, 0.28)
	for k in 3:
		b.frustum(8, Vector2(0.3, 0.3), Vector2(0.3, 0.3), 0.75, Vector3(door.x - 0.6 + k * 0.55, 0.38, z - 0.6), 0.0)
	b.color = Scenery.WOOD
	b.box(Vector3(door.x + 0.6, 0.35, z - 0.9), Vector3(0.7, 0.7, 0.6))
	# A crest painted over the door: three commas in a ring (tomoe), faded.
	b.color = Color(0.22, 0.2, 0.26)
	b.ellipse(Vector2(door.x, 3.9), Vector2(0.38, 0.38), 16, z + 0.04)
	b.color = Color(0.6, 0.59, 0.58)
	b.ellipse(Vector2(door.x, 3.9), Vector2(0.3, 0.3), 16, z + 0.045)
	b.color = Color(0.22, 0.2, 0.26)
	for k in 3:
		var a := TAU * k / 3.0
		b.ellipse(Vector2(door.x, 3.9) + Vector2(cos(a), sin(a)) * 0.13, Vector2(0.09, 0.09), 10, z + 0.05)
	# A small barred window high up.
	b.color = Color(0.05, 0.05, 0.08)
	b.rect(Vector2(left + 1.3, 3.6), Vector2(0.7, 0.5), z + 0.035)
	b.color = PaperMesh.TIMBER
	for k in 4:
		b.rect(Vector2(left + 1.04 + k * 0.17, 3.6), Vector2(0.04, 0.5), z + 0.04)
	add_child(b.build())
	var glow := OmniLight3D.new()
	glow.light_color = PaperMesh.LANTERN
	glow.light_energy = 2.2
	glow.omni_range = 4.0
	glow.omni_attenuation = 2.0
	glow.position = Vector3(door.x, 1.6, z + 0.9)
	add_child(glow)
	var shine := Scenery.halo(1.6, Color(1.0, 0.6, 0.28, 0.2))
	shine.position = Vector3(door.x, 1.5, z + 0.3)
	add_child(shine)
	# The roof: a heavy tiled roof, both slopes, the ridge with raised ends.
	add_child(Scenery.tiled_roof(_rng, left - 0.4, right + 0.4, Vector2(height - 0.05, z + 0.6), Vector2(height + 1.3, z - 1.4), 5))
	add_child(Scenery.tiled_roof(_rng, left - 0.4, right + 0.4, Vector2(height - 0.05, z - 3.4), Vector2(height + 1.3, z - 1.4), 5, false))
	# A lantern by the door, and the shrine in front of it.
	village._hang_lantern(Vector3(door.x - 1.65, 2.9, z + 0.7), 0.25, 0.8)
	shrine = RestShrine.new()
	shrine.shrine_id = "warehouse"
	shrine.position = Vector3(door.x - 2.4, 0.0, -0.9)
	shrine.scale = Vector3.ONE * 1.45
	add_child(shrine)


# --- The river and the wind at work ------------------------------------------------

func _physics_process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position
	var over := at.x > Village.RIVER.x + 0.2 and at.x < Village.RIVER.y - 0.2
	# Into the river: a splash, and the current carries him off.
	if over and _last_y >= WATER and at.y < WATER and at.y > BED:
		WaterFx.splash(get_parent(), Vector3(at.x, WATER, 0.0), 1.3)
		Sound.play(self, &"splash")
	if over and at.y < WATER - 0.35 and at.y > BED - 0.3:
		if not _carried_off:
			_carried_off = true
			_ronin.fall_in()
	elif at.y > WATER + 0.5 or not over:
		_carried_off = false
	_last_y = at.y
