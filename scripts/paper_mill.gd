class_name PaperMill
extends Node3D
## The paper mill in the Bamboo of Folded Wind (after the Canopy Road;
## docs/bamboo_map.png): a quiet place to rest before the Falls. A small mill
## house stands back from the path; a split-bamboo flume carries water from
## the top of the Falls on trestles to the overshot waterwheel at its east
## end, which turns, dripping, into a tail race. Bamboo is beaten into pulp
## here and the sheets dried in the sun: boards of drying paper lean by the
## house, and sheets hang on a line, each stirring on its own. Shrine 5 is
## at its door. A drying loft lashed out from the house's upper storey is
## reached from the vats (a bundle of cranes on it).
## Coordinates are the grove's (a child of BambooGrove).

## The waterwheel: its axle (x, height) and radius.
const WHEEL := Vector3(367.0, 3.7, 2.1)
## Where the flume starts: on the top of the Falls' cliff, fed by its stream.
const FLUME_FROM := Vector2(378.6, 13.3)

var grove: BambooGrove
var _rng := RandomNumberGenerator.new()
var _wheel: Node3D
var _ground := 1.5


func _ready() -> void:
	_rng.seed = 909
	_ground = float(BambooGrove.GROUND[4][2])
	var house := Scenery.house(_rng, 10.0, 3.6, false, 0.0, ["firewood", "buckets"])
	house.position = Vector3(356.0, _ground, -4.3)
	add_child(house)
	var shrine := RestShrine.new()
	shrine.shrine_id = "mill"
	shrine.position = Vector3(BambooGrove.MILL_SHRINE_X, _ground, -0.9)
	shrine.scale = Vector3.ONE * 1.45
	add_child(shrine)
	_build_vats()
	_build_loft()
	_build_drying()
	_build_wheel()
	_build_flume()
	Sound.place_loop(self, "sluice_pour.ogg", Vector3(WHEEL.x, WHEEL.y, -1.6), -14.0, 5.0)


## Two pulp vats by the house, solid: the steps up to the loft.
func _build_vats() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	for v: Array in [[347.6, 1.1], [349.0, 0.75]]:
		var x: float = v[0]
		var tall: float = v[1]
		b.color = Scenery.WOOD.darkened(0.15)
		b.frustum(10, Vector2(0.55, 0.55), Vector2(0.6, 0.6), tall, Vector3(x, _ground, 0.0))
		b.color = PaperMesh.TIMBER
		for k in 2:
			b.frustum(10, Vector2(0.62, 0.62), Vector2(0.62, 0.62), 0.05, Vector3(x, _ground + tall * (0.3 + k * 0.45), 0.0))
		b.color = Color(0.78, 0.78, 0.7)
		b.frustum(10, Vector2(0.54, 0.54), Vector2(0.54, 0.54), 0.01, Vector3(x, _ground + tall - 0.06, 0.0))
		grove._solid(Vector3(x, _ground + tall * 0.5, 0.0), Vector3(1.0, tall, 1.0))
	add_child(b.build())


## The drying loft: a deck lashed out from the house's upper storey, posts
## standing on the ground in front, a crane bundle among the paper.
func _build_loft() -> void:
	var left := 349.6
	var right := 354.2
	var top := 3.6
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.color = PaperMesh.TIMBER
	for x: float in [left + 0.1, right - 0.1]:
		b.box(Vector3(x, (_ground + top) * 0.5, 0.75), Vector3(0.14, top - _ground, 0.14))
	# Beams from the house wall out to the posts, and the boards.
	for x: float in [left + 0.1, right - 0.1]:
		b.box(Vector3(x, top - 0.16, -1.6), Vector3(0.12, 0.12, 4.9))
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 0.28, right)
		b.color = Scenery.WOOD.darkened(_rng.randf_range(0.0, 0.25))
		b.box(Vector3((x + x1) * 0.5, top - 0.05, -0.5), Vector3(x1 - x - 0.02, 0.08, 2.6))
		x = x1
	add_child(b.build())
	grove._solid(Vector3((left + right) * 0.5, top - 0.12, 0.0), Vector3(right - left, 0.24, 1.9)).set_meta(&"no_climb", true)
	# Sheets drying on it, propped on frames.
	var sheets := PaperMesh.new(_rng.randi())
	sheets.texture_world = false
	for k in 4:
		var sx := left + 0.6 + k * 1.05
		sheets.color = PaperMesh.TIMBER
		sheets.box(Vector3(sx, top + 0.45, -0.95), Vector3(0.7, 0.9, 0.03))
		sheets.color = PaperMesh.WASHI.darkened(_rng.randf_range(0.0, 0.08))
		sheets.quad(Vector3(sx - 0.32, top + 0.05, -0.92), Vector3(sx + 0.32, top + 0.05, -0.92), Vector3(sx + 0.32, top + 0.86, -0.92),
				Vector3(sx - 0.32, top + 0.86, -0.92), Vector3(0, 0, 1))
	add_child(sheets.build())
	var bundle := CraneBundle.new()
	bundle.id = "mill_loft"
	bundle.count = 5
	bundle.position = Vector3(right - 0.7, top, -0.5)
	add_child(bundle)


## Boards of drying paper leaning on the house, and a line of sheets.
func _build_drying() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	for x: float in [357.8, 359.4, 361.0]:
		b.color = PaperMesh.TIMBER
		b.extrude(PackedVector2Array([Vector2(x - 0.5, _ground), Vector2(x + 0.5, _ground), Vector2(x + 0.62, _ground + 1.9), Vector2(x - 0.38, _ground + 1.9)]), -2.75, -2.7)
		b.color = PaperMesh.WASHI.darkened(_rng.randf_range(0.0, 0.1))
		b.polygon(PackedVector2Array([Vector2(x - 0.4, _ground + 0.15), Vector2(x + 0.42, _ground + 0.15), Vector2(x + 0.5, _ground + 1.75), Vector2(x - 0.3, _ground + 1.75)]), -2.68)
	b.color = PaperMesh.TIMBER
	for px: float in [362.4, 365.4]:
		b.box(Vector3(px, _ground + 1.15, -2.2), Vector3(0.08, 2.3, 0.08))
	b.color = BambooGrove.ROPE
	b.box(Vector3(363.9, _ground + 2.22, -2.2), Vector3(3.0, 0.025, 0.025))
	add_child(b.build())
	var x := 362.7
	while x < 365.1:
		var hang := Node3D.new()
		hang.position = Vector3(x, _ground + 2.2, -2.18)
		add_child(hang)
		var sheet := PaperMesh.new(_rng.randi())
		sheet.texture_world = false
		sheet.color = PaperMesh.WASHI.darkened(_rng.randf_range(0.0, 0.08))
		sheet.rect(Vector2(0.0, -0.33), Vector2(0.44, 0.64), 0.0)
		hang.add_child(sheet.build())
		Scenery.windswept(hang, 0.05, _rng)
		x += _rng.randf_range(0.55, 0.65)


## The overshot waterwheel, behind the path: two rims, spokes, buckets; it
## turns (in _process), water spilling off it into the tail race.
func _build_wheel() -> void:
	var r := WHEEL.z
	var frame := PaperMesh.new(_rng.randi())
	frame.shade_jitter = 0.14
	frame.color = PaperMesh.TIMBER.darkened(0.1)
	# Its stands, either side: two legs each, splayed, meeting under the
	# axle, with a cross tie.
	for z: float in [-0.65, -2.95]:
		for side: float in [-1.0, 1.0]:
			frame.extrude(PackedVector2Array([Vector2(WHEEL.x + side * 0.85 - 0.07, _ground), Vector2(WHEEL.x + side * 0.85 + 0.07, _ground),
					Vector2(WHEEL.x + side * 0.05 + 0.05, WHEEL.y + 0.1), Vector2(WHEEL.x + side * 0.05 - 0.05, WHEEL.y + 0.1)]), z - 0.06, z + 0.06)
		frame.box(Vector3(WHEEL.x, _ground + 0.7, z), Vector3(1.35, 0.08, 0.1))
	add_child(frame.build())
	_wheel = Node3D.new()
	_wheel.position = Vector3(WHEEL.x, WHEEL.y, -1.8)
	add_child(_wheel)
	var w := PaperMesh.new(_rng.randi())
	w.texture_world = false
	w.shade_jitter = 0.16
	w.color = Scenery.WOOD.darkened(0.25)
	w.box(Vector3.ZERO, Vector3(0.18, 0.18, 2.5))
	var n := 16
	for k in n:
		var a := TAU * k / n
		var a1 := TAU * (k + 1) / n
		for z: float in [-0.55, 0.55]:
			# Rim pieces.
			var p0 := Vector2(cos(a), sin(a)) * r
			var p1 := Vector2(cos(a1), sin(a1)) * r
			var mid := (p0 + p1) * 0.5
			w.color = Scenery.WOOD.darkened(_rng.randf_range(0.1, 0.3))
			w.extrude(PackedVector2Array([p0 * 0.93, p1 * 0.93, p1, p0]), z - 0.05, z + 0.05)
			if k % 2 == 0:
				w.box(Vector3(mid.x * 0.5, mid.y * 0.5, z), Vector3(0.08, 0.08, 0.08))
		# Spokes (every other), and a bucket between the rims at each step.
		if k % 2 == 0:
			var s := Vector2(cos(a), sin(a))
			w.extrude(PackedVector2Array([s.orthogonal() * 0.04, s * r * 0.93 + s.orthogonal() * 0.04, s * r * 0.93 - s.orthogonal() * 0.04,
					-s.orthogonal() * 0.04]), -0.6, -0.5)
			w.extrude(PackedVector2Array([s.orthogonal() * 0.04, s * r * 0.93 + s.orthogonal() * 0.04, s * r * 0.93 - s.orthogonal() * 0.04,
					-s.orthogonal() * 0.04]), 0.5, 0.6)
		var b0 := Vector2(cos(a), sin(a))
		w.color = Scenery.WOOD.darkened(0.35)
		w.extrude(PackedVector2Array([b0 * r * 0.78, b0 * r * 0.98, b0 * r * 0.98 + b0.orthogonal() * 0.06, b0 * r * 0.78 + b0.orthogonal() * 0.06]),
				-0.5, 0.5)
	_wheel.add_child(w.build())
	# Water spilling out of the buckets as they come round the bottom.
	var spill := CPUParticles3D.new()
	spill.amount = 40
	spill.lifetime = 0.7
	spill.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spill.emission_box_extents = Vector3(0.1, 0.4, 0.5)
	spill.position = Vector3(WHEEL.x + r * 0.55, WHEEL.y - r * 0.75, -1.8)
	spill.direction = Vector3(0.2, -1.0, 0.0)
	spill.spread = 12.0
	spill.gravity = Vector3(0.0, -9.0, 0.0)
	spill.initial_velocity_min = 0.6
	spill.initial_velocity_max = 1.4
	var drop := SphereMesh.new()
	drop.radius = 0.035
	drop.height = 0.07
	drop.radial_segments = 6
	drop.rings = 3
	var look := StandardMaterial3D.new()
	look.albedo_color = Color(0.75, 0.86, 0.9, 0.8)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.roughness = 0.1
	drop.material = look
	spill.mesh = drop
	spill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spill)
	# The tail race under the wheel: a short channel of water at the back.
	var race := PaperMesh.new(_rng.randi())
	race.shade_jitter = 0.0
	race.color = Color(0.4, 0.52, 0.5)
	race.quad(Vector3(WHEEL.x - 2.6, _ground + 0.02, -2.5), Vector3(WHEEL.x + 2.0, _ground + 0.02, -2.5), Vector3(WHEEL.x + 2.0, _ground + 0.02, -1.1),
			Vector3(WHEEL.x - 2.6, _ground + 0.02, -1.1), Vector3.UP)
	var surface := race.build()
	(surface.material_override as StandardMaterial3D).roughness = 0.12
	add_child(surface)


## The flume: half a bamboo stem split lengthways, water running in it, on
## trestles, from the cliff of the Falls down to the top of the wheel.
func _build_flume() -> void:
	var to := Vector2(WHEEL.x + 0.2, WHEEL.y + WHEEL.z + 0.25)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	var z := -1.8
	var steps := 10
	for k in steps:
		var a := FLUME_FROM.lerp(to, float(k) / steps)
		var c := FLUME_FROM.lerp(to, float(k + 1) / steps)
		b.color = BambooGrove.STEM_YELLOW.darkened(0.15)
		# The half-pipe: an open trough (two sides and a bottom).
		b.extrude(PackedVector2Array([a + Vector2(0, -0.12), c + Vector2(0, -0.12), c + Vector2(0, -0.08), a + Vector2(0, -0.08)]), z - 0.14, z + 0.14)
		b.extrude(PackedVector2Array([a + Vector2(0, -0.12), c + Vector2(0, -0.12), c + Vector2(0, 0.04), a + Vector2(0, 0.04)]), z - 0.16, z - 0.12)
		b.extrude(PackedVector2Array([a + Vector2(0, -0.12), c + Vector2(0, -0.12), c + Vector2(0, 0.04), a + Vector2(0, 0.04)]), z + 0.12, z + 0.16)
		b.color = Color(0.62, 0.76, 0.8)
		b.quad(Vector3(a.x, a.y - 0.03, z - 0.12), Vector3(c.x, c.y - 0.03, z - 0.12), Vector3(c.x, c.y - 0.03, z + 0.12), Vector3(a.x, a.y - 0.03, z + 0.12), Vector3.UP)
	# Trestles: crossed legs standing on the ground under it.
	b.color = PaperMesh.TIMBER
	var t := 0.18
	while t < 0.95:
		var p := FLUME_FROM.lerp(to, t)
		var h := p.y - 0.12 - _ground
		for side: float in [-1.0, 1.0]:
			b.extrude(PackedVector2Array([Vector2(p.x - 0.04 + side * 0.35, _ground), Vector2(p.x + 0.04 + side * 0.35, _ground),
					Vector2(p.x + 0.04, p.y - 0.12), Vector2(p.x - 0.04, p.y - 0.12)]), z - 0.04, z + 0.04)
		b.box(Vector3(p.x, _ground + h * 0.55, z), Vector3(0.6, 0.05, 0.05))
		t += 0.22
	add_child(b.build())
	# The water pouring off its end onto the wheel.
	var pour := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.45)
	pour.mesh = quad
	var look := StandardMaterial3D.new()
	look.albedo_color = Color(0.72, 0.84, 0.88, 0.75)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	pour.material_override = look
	pour.position = Vector3(to.x - 0.05, to.y - 0.3, z)
	add_child(pour)


func _process(delta: float) -> void:
	# The wheel turns with the water poured onto its east side.
	if _wheel:
		_wheel.rotation.z -= delta * 0.55  # (the east side goes down)
