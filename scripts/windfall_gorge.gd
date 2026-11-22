class_name WindfallGorge
extends Node3D
## The Windfall Gorge (Bamboo of Folded Wind, after the two ravines;
## docs/bamboo_map.png): the path breaks off over a gorge 11 m deep and 38 m
## wide, too wide for one glide. Out of clefts in its floor the folded wind
## blows straight up (Updraft): glide into a rising gust, ride it up, glide
## on to the next. Bamboo grows up out of the gorge; old woodcutters' decks
## are lashed to its stems part-way down (LashedDeck). On the floor a
## shallow stream runs over stones: falling in is not death. The cliff walls
## can be climbed (wall slide and jump), and by the east wall a stem stands
## close enough to jump between the two.
## Coordinates are the grove's (a child of BambooGrove).

## The rising gusts: [x, how high (from the floor)].
const UPDRAFTS := [[257.5, 17.0], [267.5, 17.0], [277.5, 17.0]]
## The decks: [left, right, top].
const DECKS := [[251.5, 254.5, -5.0], [261.0, 264.0, -2.0], [271.0, 274.0, -4.0], [280.5, 283.5, -3.0]]
## The stem by the east wall to climb back up between (x).
const CLIMB_STEM := 284.95  # (gap to the wall about 1.8 m; 1 m was too tight: Julian)

var grove: BambooGrove
var _rng := RandomNumberGenerator.new()
var _floor := -9.5


func _ready() -> void:
	_rng.seed = 707
	_floor = float(BambooGrove.GROUND[3][2])
	for u: Array in UPDRAFTS:
		var draft := Updraft.new()
		draft.position = Vector3(u[0], _floor, 0.0)
		draft.height = u[1]
		add_child(draft)
	for d: Array in DECKS:
		var deck := LashedDeck.new()
		deck.grove = grove
		deck.left = d[0]
		deck.right = d[1]
		deck.top = d[2]
		deck.foot = _floor
		add_child(deck)
	_build_back_wall()
	_build_stream()
	_build_climb_stem()
	_build_mist()
	var bundle := CraneBundle.new()
	bundle.id = "gorge_floor"
	bundle.count = 6
	bundle.position = Vector3(270.5, _floor, -0.7)
	add_child(bundle)
	for x: float in [256.0, 278.0]:
		Sound.place_loop(self, "river_flow.ogg", Vector3(x, _floor + 0.3, -2.5), -12.0, 6.0)


## The gorge's far wall, behind the stems: faceted rock, darker toward the
## floor, a few red washi patches like the cliffs in front, a moss lip along
## its top (so from down here he sees rock, not the far landscape).
func _build_back_wall() -> void:
	var left := BambooGrove.GORGE.x - 0.5
	var right := BambooGrove.GORGE.y + 0.5
	var z := BambooGrove.FLOOR_BACK + 0.35
	var top := float(BambooGrove.GROUND[2][2])
	var f := PaperMesh.new(_rng.randi())
	f.shade_jitter = 0.06
	var cols := int(ceil((right - left) / 0.9))
	var rows := int(ceil((top - _floor) / 0.8))
	var grid: Array = []
	for r in rows + 1:
		var line: Array[Vector2] = []
		for c in cols + 1:
			var gx := left + c * (right - left) / cols
			var gy := top - r * (top - _floor) / rows
			if c > 0 and c < cols:
				gx += _rng.randf_range(-0.3, 0.3)
			if r > 0 and r < rows:
				gy += _rng.randf_range(-0.25, 0.25)
			line.append(Vector2(gx, gy))
		grid.append(line)
	for r in rows:
		var dark := float(r) / rows
		for c in cols:
			var a: Vector2 = grid[r][c]
			var b2: Vector2 = grid[r][c + 1]
			var c2: Vector2 = grid[r + 1][c + 1]
			var d: Vector2 = grid[r + 1][c]
			for tri: Array in [[a, b2, c2], [a, c2, d]]:
				f.color = BambooGrove.ROCK.lerp(BambooGrove.ROCK_WARM, _rng.randf()).lightened(_rng.randf_range(0.0, 0.14) - dark * 0.12)
				f.polygon(PackedVector2Array(tri), z)
	# Torn red washi patches pasted on it here and there.
	var px := left + 2.0
	while px < right - 3.0:
		var w := _rng.randf_range(1.2, 2.6)
		var tall := _rng.randf_range(1.0, 2.0)
		var cy := _rng.randf_range(_floor + 2.0, top - 1.5)
		var outline := PackedVector2Array()
		for k in 7:
			var t := TAU * k / 7.0 + _rng.randf_range(-0.25, 0.25)
			outline.append(Vector2(px + cos(t) * w * 0.5 * _rng.randf_range(0.75, 1.0), cy + sin(t) * tall * 0.5 * _rng.randf_range(0.75, 1.0)))
		f.color = BambooGrove.WASHI_RED.darkened(_rng.randf_range(0.0, 0.2))
		f.torn_sheet(PaperMesh.tear(outline, 0.2, 0.06, _rng), z + 0.03, BambooGrove.WASHI_RED.lightened(0.35), 0.025)
		px += _rng.randf_range(5.0, 9.0)
	add_child(f.build())
	# The moss lip along its top, hanging over.
	var m := PaperMesh.new(_rng.randi())
	m.texture_world = false
	var mx := left
	while mx < right:
		var wide := _rng.randf_range(0.14, 0.28)
		var hang := _rng.randf_range(0.15, 0.5)
		m.color = BambooGrove.MOSS.lerp(BambooGrove.MOSS_LIGHT, _rng.randf())
		m.polygon(PackedVector2Array([Vector2(mx - wide * 0.6, top + 0.05), Vector2(mx + wide * 0.6, top + 0.05),
				Vector2(mx + wide * 0.3, top - hang * 0.5), Vector2(mx, top - hang), Vector2(mx - wide * 0.35, top - hang * 0.45)]), z + 0.06)
		mx += wide * 0.8
	m.quad(Vector3(left, top, z), Vector3(right, top, z), Vector3(right, top, BambooGrove.FLOOR_BACK - 2.0), Vector3(left, top, BambooGrove.FLOOR_BACK - 2.0), Vector3.UP)
	add_child(m.build())


## The stream along the gorge floor, behind where he walks: water over
## stones, flecks of foam carried along, a gravel bank in front of it.
func _build_stream() -> void:
	var left := BambooGrove.GORGE.x + 0.4
	var right := BambooGrove.GORGE.y - 0.4
	var water := PaperMesh.new(_rng.randi())
	water.shade_jitter = 0.0
	water.texture_world = false
	water.color = Color(0.4, 0.52, 0.5)
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 3.0, right)
		water.quad(Vector3(x, _floor + 0.03, -4.2), Vector3(x1, _floor + 0.03, -4.2), Vector3(x1, _floor + 0.03, -1.5),
				Vector3(x, _floor + 0.03, -1.5), Vector3.UP)
		x = x1
	var surface := water.build()
	(surface.material_override as StandardMaterial3D).roughness = 0.12
	add_child(surface)
	# Stones in and along it, and the gravel bank's edge.
	var stones := PaperMesh.new(_rng.randi())
	stones.shade_jitter = 0.2
	x = left
	while x < right:
		var r := _rng.randf_range(0.12, 0.38)
		var z := _rng.randf_range(-4.4, -1.2)
		stones.color = BambooGrove.ROCK.lerp(BambooGrove.ROCK_WARM, _rng.randf()).lightened(_rng.randf_range(0.0, 0.25))
		stones.frustum(6, Vector2(r, r * 0.8), Vector2(r * 0.55, r * 0.45), r * 0.7, Vector3(x, _floor - 0.05, z))
		x += _rng.randf_range(0.3, 1.1)
	add_child(stones.build())
	# Foam flecks carried along with the current (west, with the wind).
	var foam := CPUParticles3D.new()
	foam.amount = 70
	foam.lifetime = 9.0
	foam.preprocess = 9.0
	foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	foam.emission_box_extents = Vector3((right - left) * 0.5, 0.0, 1.2)
	foam.position = Vector3((left + right) * 0.5, _floor + 0.05, -2.85)
	foam.direction = Vector3(-1.0, 0.0, 0.0)
	foam.spread = 4.0
	foam.gravity = Vector3.ZERO
	foam.initial_velocity_min = 0.8
	foam.initial_velocity_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 0.8))
	fade.add_point(0.8, Color(1, 1, 1, 0.8))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	foam.color_ramp = fade
	var fleck := QuadMesh.new()
	fleck.size = Vector2(0.22, 0.06)
	fleck.orientation = PlaneMesh.FACE_Y
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.9, 0.93, 0.9)
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fleck.material = look
	foam.mesh = fleck
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(foam)


## A thick stem close by the east wall, solid, to wall-jump between it and
## the cliff back up out of the gorge.
func _build_climb_stem() -> void:
	var top := float(BambooGrove.GROUND[4][2]) - 0.6
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.08
	# (Its foot stands just behind him and its solid part starts above his
	# head, so he walks in under it into the gap and jumps up between: Julian.)
	LashedDeck.climb_stem(b, Vector3(CLIMB_STEM, _floor - 0.05, LashedDeck.CLIMB_Z), top + 6.0 - _floor, 0.26, _rng)
	LashedDeck.climb_marks(b, CLIMB_STEM, LashedDeck.CLIMB_Z, _floor, top, 0.26)
	add_child(b.build())
	var low := _floor + LashedDeck.CLIMB_CLEAR
	var solid := grove._solid(Vector3(CLIMB_STEM, (low + top) * 0.5, 0.0), Vector3(0.5, top - low, 0.6))
	solid.set_meta(&"climbable", true)


## Pale mist lying in the gorge, thicker low down (as in the ravines).
func _build_mist() -> void:
	var veil := PaperMesh.new(1)
	var left := BambooGrove.GORGE.x
	var right := BambooGrove.GORGE.y
	for k in 3:
		var z := -5.0 + k * 1.8
		veil.fade_quad(Vector3(left, _floor, z), Vector3(right, _floor, z), Vector3(right, _floor + 3.0 + k * 0.6, z),
				Vector3(left, _floor + 3.0 + k * 0.6, z), Color(0.92, 0.88, 0.76, 0.35), Color(0.92, 0.88, 0.76, 0.0))
	add_child(veil.build_veil())
