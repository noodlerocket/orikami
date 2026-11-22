class_name BambooFalls
extends Node3D
## The Falls (Bamboo of Folded Wind, after the paper mill; docs/bamboo_map.png):
## a cliff 12 m high with a stream running along its top and pouring off its
## east edge into a deep pool. He climbs the west face (a stem stands close
## to it to wall-jump between), and from the top makes the longest glide of
## the grove, down over the pool against the gusts, to Akane's clearing on
## the far bank. The pool is deep: falling in carries him back to the last
## shrine (the mill's). Behind the falling water, a ledge in the rock holds
## a bundle of cranes: drop onto it from the top, close to the face.
## Coordinates are the grove's (a child of BambooGrove).

## The stem to climb up beside the cliff (x).
const CLIMB_STEM := 376.75
## The pool's water surface.
const WATER := -0.5
## The ledge behind the falls: [left, right, top].
const LEDGE := [384.0, 386.2, 4.5]

var grove: BambooGrove
var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _carried_off := false
var _cliff_top := 13.5


func _ready() -> void:
	_rng.seed = 1010
	_cliff_top = float(BambooGrove.GROUND[5][2])
	var ground := float(BambooGrove.GROUND[4][2])
	# The climb.
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.08
	var top := _cliff_top - 0.6
	# (Its foot stands just behind him and its solid part starts above his
	# head, so he walks in under it into the gap and jumps up between: Julian.)
	LashedDeck.climb_stem(b, Vector3(CLIMB_STEM, ground - 0.05, LashedDeck.CLIMB_Z), top + 5.0 - ground, 0.26, _rng)
	LashedDeck.climb_marks(b, CLIMB_STEM, LashedDeck.CLIMB_Z, ground, top, 0.26)
	add_child(b.build())
	var low := ground + LashedDeck.CLIMB_CLEAR
	grove._solid(Vector3(CLIMB_STEM, (low + top) * 0.5, 0.0), Vector3(0.5, top - low, 0.6)).set_meta(&"climbable", true)
	_build_stream()
	_build_falls()
	_build_pool()
	_build_ledge()
	Sound.place_loop(self, "sluice_pour.ogg", Vector3(384.8, 2.0, -1.0), -4.0, 10.0)
	Sound.place_loop(self, "river_flow.ogg", Vector3(381.0, _cliff_top + 0.5, -2.5), -10.0, 6.0)


## The stream along the cliff top, behind where he walks, running east to
## the edge (it also feeds the mill's flume at the west end).
func _build_stream() -> void:
	var water := PaperMesh.new(_rng.randi())
	water.shade_jitter = 0.0
	water.color = Color(0.42, 0.55, 0.55)
	water.quad(Vector3(378.2, _cliff_top + 0.03, -3.6), Vector3(384.0, _cliff_top + 0.03, -3.6), Vector3(384.0, _cliff_top + 0.03, -1.2),
			Vector3(378.2, _cliff_top + 0.03, -1.2), Vector3.UP)
	var surface := water.build()
	(surface.material_override as StandardMaterial3D).roughness = 0.12
	add_child(surface)


## The falling water: several sheets, one behind another across the stream's
## width, leaving the lip and curving out as they fall; spray and mist where
## they hit the pool.
func _build_falls() -> void:
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/waterfall.gdshader")
	for k in 4:
		var z := -3.4 + k * 0.75
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rows := 12
		for r in rows:
			for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
				var t := float(r + corner[1]) / rows
				var across: float = corner[0]
				# Out from the lip in a falling curve, spreading as it goes.
				var out := 0.15 + 1.4 * sqrt(t)
				var wide := 0.9 + 0.7 * t
				var x := 384.0 + out - wide * 0.5 + across * wide
				var y := lerpf(_cliff_top + 0.02, WATER, t)
				st.set_uv(Vector2(across, t))
				st.add_vertex(Vector3(x, y, z))
		var sheet := MeshInstance3D.new()
		sheet.mesh = st.commit()
		var mine := look.duplicate() as ShaderMaterial
		mine.set_shader_parameter(&"speed", 1.4 + k * 0.15)
		sheet.material_override = mine
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sheet)
	# Spray thrown up where it lands.
	var spray := CPUParticles3D.new()
	spray.amount = 60
	spray.lifetime = 1.2
	spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spray.emission_box_extents = Vector3(0.7, 0.05, 1.8)
	spray.position = Vector3(385.6, WATER, -1.6)
	spray.direction = Vector3(0.3, 1.0, 0.0)
	spray.spread = 35.0
	spray.gravity = Vector3(0.0, -4.0, 0.0)
	spray.initial_velocity_min = 1.0
	spray.initial_velocity_max = 2.6
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.7))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	spray.color_ramp = fade
	var puff := SphereMesh.new()
	puff.radius = 0.12
	puff.height = 0.24
	puff.radial_segments = 6
	puff.rings = 3
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color(0.94, 0.97, 0.98)
	white.vertex_color_use_as_albedo = true
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material = white
	spray.mesh = puff
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spray)
	# Mist off the falls: thickest by the water, thinning out across the pool
	# (in strips, each fainter, so it has no hard edge).
	var veil := PaperMesh.new(2)
	for k in 2:
		var z := -2.5 + k * 2.0
		for s in 6:
			var x0 := 383.5 + s * 1.4
			var a := 0.32 * (1.0 - s / 6.0)
			veil.fade_quad(Vector3(x0, WATER, z), Vector3(x0 + 1.4, WATER, z), Vector3(x0 + 1.4, WATER + 3.0 - s * 0.3, z), Vector3(x0, WATER + 3.0 - s * 0.3, z),
					Color(0.95, 0.96, 0.94, a), Color(0.95, 0.96, 0.94, 0.0))
	add_child(veil.build_veil())


## The pool: deep water between the cliff and the far bank.
func _build_pool() -> void:
	var pool := BambooGrove.POOL
	var water := PaperMesh.new(_rng.randi())
	water.shade_jitter = 0.0
	water.color = Color(0.3, 0.42, 0.44)
	var x := pool.x
	while x < pool.y - 0.01:
		var x1 := minf(x + 3.0, pool.y)
		water.quad(Vector3(x, WATER, BambooGrove.FLOOR_BACK), Vector3(x1, WATER, BambooGrove.FLOOR_BACK), Vector3(x1, WATER, Village.STREET_FRONT),
				Vector3(x, WATER, Village.STREET_FRONT), Vector3.UP)
		x = x1
	var surface := water.build()
	(surface.material_override as StandardMaterial3D).roughness = 0.08
	add_child(surface)
	# The cut-away front of the pool, like the cliffs': faceted rock from the
	# water's edge down, darkening, so the water is held, not floating.
	var face := PaperMesh.new(_rng.randi())
	face.shade_jitter = 0.06
	var cols := 14
	var rows := 8
	var grid: Array = []
	for r in rows + 1:
		var line: Array[Vector2] = []
		for c in cols + 1:
			var gx := pool.x + c * (pool.y - pool.x) / cols
			var gy := WATER - 0.05 - r * 0.8
			if c > 0 and c < cols:
				gx += _rng.randf_range(-0.25, 0.25)
			if r > 0:
				gy += _rng.randf_range(-0.2, 0.2)
			line.append(Vector2(gx, gy))
		grid.append(line)
	for r in rows:
		for c in cols:
			var a: Vector2 = grid[r][c]
			var b2: Vector2 = grid[r][c + 1]
			var c2: Vector2 = grid[r + 1][c + 1]
			var d: Vector2 = grid[r + 1][c]
			for tri: Array in [[a, b2, c2], [a, c2, d]]:
				face.color = BambooGrove.ROCK.lerp(BambooGrove.ROCK_WARM, _rng.randf()).lightened(_rng.randf_range(-0.05, 0.1) - float(r) / rows * 0.12)
				face.polygon(PackedVector2Array(tri), Village.STREET_FRONT + 0.01)
	# A band of wet dark stone along the waterline.
	face.color = Color(0.16, 0.18, 0.18)
	face.polygon(PackedVector2Array([Vector2(pool.x, WATER + 0.02), Vector2(pool.y, WATER + 0.02), Vector2(pool.y, WATER - 0.18), Vector2(pool.x, WATER - 0.18)]),
			Village.STREET_FRONT + 0.02)
	var front := face.build()
	front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(front)
	# Ripples spreading from the falls across the pool (flecks carried east).
	var foam := CPUParticles3D.new()
	foam.amount = 40
	foam.lifetime = 6.0
	foam.preprocess = 6.0
	foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	foam.emission_box_extents = Vector3(0.6, 0.0, 2.5)
	foam.position = Vector3(386.0, WATER + 0.02, -1.5)
	foam.direction = Vector3(1.0, 0.0, 0.0)
	foam.spread = 20.0
	foam.gravity = Vector3.ZERO
	foam.initial_velocity_min = 0.8
	foam.initial_velocity_max = 1.6
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.8))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	foam.color_ramp = fade
	var fleck := QuadMesh.new()
	fleck.size = Vector2(0.25, 0.07)
	fleck.orientation = PlaneMesh.FACE_Y
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.9, 0.94, 0.94)
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fleck.material = look
	foam.mesh = fleck
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(foam)


## The ledge behind the falling water: a shelf of rock jutting from the
## cliff's east face, a bundle of cranes on it.
func _build_ledge() -> void:
	var left: float = LEDGE[0]
	var right: float = LEDGE[1]
	var top: float = LEDGE[2]
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.2
	# Faceted underside tapering back into the cliff.
	for z: float in [-1.0, -0.33, 0.33, 1.0]:
		b.color = BambooGrove.ROCK.lerp(BambooGrove.ROCK_WARM, _rng.randf()).lightened(_rng.randf_range(0.0, 0.1))
		b.extrude(PackedVector2Array([Vector2(left - 0.05, top - 1.6), Vector2(left - 0.05, top), Vector2(right, top),
				Vector2(right - 0.4, top - 0.45), Vector2(left + 0.6, top - 1.1)]), z - 0.34, z + 0.34)
	b.color = BambooGrove.MOSS
	b.box(Vector3((left + right) * 0.5, top + 0.01, 0.0), Vector3(right - left, 0.02, 2.0))
	add_child(b.build())
	grove._solid(Vector3((left + right) * 0.5, top - 0.3, 0.0), Vector3(right - left, 0.6, 2.0))
	var bundle := CraneBundle.new()
	bundle.id = "behind_falls"
	bundle.count = 7
	bundle.position = Vector3(left + 0.7, top, -0.6)
	add_child(bundle)


func _physics_process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position - global_position
	var pool := BambooGrove.POOL
	if at.x > pool.x and at.x < pool.y and at.y < WATER - 0.2:
		if not _carried_off:
			_carried_off = true
			WaterFx.splash(get_parent(), Vector3(at.x, WATER, 0.0), 1.4)
			_ronin.fall_in()
	elif at.y > WATER + 1.0:
		_carried_off = false
