class_name ShrineSteps
extends Node3D
## The Shrine Steps (area 6 of the expanded village, docs/village_map.png):
## a long flight of worn stone steps up from the street to the shrine
## courtyard, lined with stone lanterns, an old cherry leaning over them,
## and at their foot the third shrine: the last rest before the Hannya.
## He walks up them as up a slope (the steps are for the eye; underfoot
## it is a smooth ramp, so he never catches on a step's edge).

## How many steps.
const COUNT := 20

var village: Village
var shrine: RestShrine
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 9107
	_build_steps()
	_build_lanterns()
	_build_tree()
	shrine = RestShrine.new()
	shrine.shrine_id = "steps"
	shrine.position = Vector3(Village.STEPS.x - 1.6, 0.0, -0.9)
	shrine.scale = Vector3.ONE * 1.45
	add_child(shrine)


func _build_steps() -> void:
	var left := Village.STEPS.x
	var right := Village.STEPS.y
	var top := Village.STEPS_TOP
	# Underfoot: a smooth ramp.
	var shape := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for z: float in [-4.5, 1.5]:
		pts.append_array([Vector3(left, 0.0, z), Vector3(right, top, z), Vector3(right, -1.0, z), Vector3(left, -1.0, z)])
	shape.points = pts
	var body := StaticBody3D.new()
	var holder := CollisionShape3D.new()
	holder.shape = shape
	body.add_child(holder)
	add_child(body)
	# The steps: granite slabs, each a little different, worn in the middle.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.08
	var run := (right - left) / COUNT
	var rise := top / COUNT
	var stone := Color(0.27, 0.28, 0.36)
	# The ground under them (its side shows at the front).
	b.color = Village.EARTH
	b.box(Vector3((left + right) * 0.5, -5.0, (Village.STREET_FRONT - 0.15 + Village.STREET_BACK) * 0.5),
			Vector3(right - left, 10.0, Village.STREET_FRONT - 0.15 - Village.STREET_BACK))
	for k in COUNT:
		var x0 := left + k * run
		# (Each step's top is where the ramp is at its middle, so his feet
		# never sink more than a couple of centimetres into the stone.)
		var h := (k + 0.5) * rise
		b.color = stone * _rng.randf_range(0.88, 1.1)
		b.box(Vector3(x0 + run * 0.5 + 0.0, h * 0.5, -3.0), Vector3(run + 0.02, h, 9.0))
		# The worn nose of each step, catching the light.
		b.color = stone.lightened(0.14)
		b.box(Vector3(x0 + 0.06, h - 0.02, -3.0), Vector3(0.12, 0.05, 9.0))
		# Moss in the corner where it meets the next.
		b.color = Village.MOSS * 0.8
		b.box(Vector3(x0 + run - 0.08, h + 0.01, _rng.randf_range(-2.0, 0.5)), Vector3(0.14, 0.03, _rng.randf_range(0.6, 2.0)))
	add_child(b.build())
	# Their torn front, stepping down like the street's.
	var front := PaperMesh.new(_rng.randi())
	front.shade_jitter = 0.04
	var outline := PackedVector2Array()
	for k in COUNT:
		var x0 := left + k * run
		outline.append(Vector2(x0, (k + 0.5) * rise))
		outline.append(Vector2(x0 + run, (k + 0.5) * rise))
	outline = PaperMesh.tear(outline, 0.3, 0.015, _rng, false)
	outline.append(Vector2(right, -12.0))
	outline.append(Vector2(left, -12.0))
	front.color = Color(0.23, 0.245, 0.34)
	front.torn_sheet(outline, Village.STREET_FRONT, Color(0.5, 0.54, 0.68), 0.03)
	var lower := PackedVector2Array()
	for k in COUNT:
		lower.append(Vector2(left + k * run, (k + 0.5) * rise - 0.32))
		lower.append(Vector2(left + (k + 1) * run, (k + 0.5) * rise - 0.32))
	lower = PaperMesh.tear(lower, 0.3, 0.03, _rng, false)
	lower.append(Vector2(right, -12.0))
	lower.append(Vector2(left, -12.0))
	front.color = Color(0.125, 0.135, 0.22)
	front.torn_sheet(lower, Village.STREET_FRONT + 0.1, Color(0.24, 0.265, 0.39), 0.03)
	var cliff := front.build()
	cliff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cliff)


## Stone lanterns up the steps, on the back side (lit), their light pooling
## on the stone.
func _build_lanterns() -> void:
	for x: float in [Village.STEPS.x + 1.5, Village.STEPS.x + 6.6, Village.STEPS.y - 1.2]:
		village._build_stone_lantern(Vector3(x, village._street_height(x), -2.3), false)


## The cherry's depth: in front of the houses' eaves (at -3.4 its trunk ran
## up through a roof).
const TREE_Z := -2.75


func _build_tree() -> void:
	var tree := Scenery.sakura_tree(_rng, 7.6, -0.6, 28, 0.42)
	tree.position = Vector3(Village.STEPS.x + 4.4, village._street_height(Village.STEPS.x + 4.4), TREE_Z)
	add_child(tree)
	var crown: Vector2 = tree.get_meta(&"crown")
	village._add_falling_petals(Vector2(tree.position.x + crown.x, tree.position.y + crown.y), TREE_Z)
	# Petals fallen on the steps.
	var petals := PaperMesh.new(_rng.randi())
	petals.texture_scale = 0.0
	petals.shade_jitter = 0.2
	petals.color = PaperMesh.SAKURA
	for i in 30:
		var x := _rng.randf_range(Village.STEPS.x, Village.STEPS.y)
		var k := int((x - Village.STEPS.x) / ((Village.STEPS.y - Village.STEPS.x) / COUNT))
		var at := Vector3(x, (k + 0.5) * Village.STEPS_TOP / COUNT + 0.012, _rng.randf_range(-3.5, 1.2))
		var turn := _rng.randf() * TAU
		var across := Vector3(cos(turn), 0.0, sin(turn)) * 0.09
		var along := Vector3(-sin(turn), 0.0, cos(turn)) * 0.14
		petals.quad(at - across, at + along, at + across, at - along * 0.6, Vector3.UP)
	var fallen := petals.build()
	fallen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fallen)
