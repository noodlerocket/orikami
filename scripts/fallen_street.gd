class_name FallenStreet
extends Node3D
## The Fallen Street (area 3 of the expanded village, docs/village_map.png):
## the street has caved in, down into the canals. Villagers laid planks over
## the hole on a rough timber frame; the rain has soaked them through, and
## they give way a moment after he steps on them (SoggyPlank): the way DOWN.
## Past the planks the frame has fallen too: broken posts stick up out of
## the water. Behind the hole the back of the street still stands, its
## broken edge torn like paper, a fence across it.

## [left x, length] of each plank, at street level.
const PLANKS := [[62.1, 2.3], [64.5, 2.2], [66.8, 2.0], [68.9, 1.6]]

var village: Village
var planks: Array[SoggyPlank] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 6203
	for p: Array in PLANKS:
		var plank := SoggyPlank.new()
		plank.length = p[1]
		plank.position = Vector3(p[0], 0.0, 0.0)
		add_child(plank)
		planks.append(plank)
	_build_frame()
	_build_back_edge()
	_build_debris()


## The timber frame the planks were laid on: posts standing in the canal,
## a beam across under each joint; past the planks, broken stubs.
func _build_frame() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.2
	b.color = PaperMesh.TIMBER
	for joint: float in [64.45, 66.75, 68.85]:
		var foot := _floor_at(joint)
		for pz: float in [1.32, -2.2]:
			b.box(Vector3(joint, (foot - 0.25) * 0.5, pz), Vector3(0.17, -foot - 0.25, 0.17))
		# The beam across, under the planks' ends.
		b.box(Vector3(joint, -0.2, -0.45), Vector3(0.2, 0.16, 3.7))
		# A diagonal brace from the back post.
		b.extrude(PackedVector2Array([Vector2(joint - 0.06, foot + 0.5), Vector2(joint + 0.06, foot + 0.5),
				Vector2(joint + 1.0, -0.35), Vector2(joint + 0.88, -0.35)]), -2.26, -2.14)
	# Where the frame has fallen: broken posts, one leaning, splintered tops.
	for stub: Array in [[71.2, -1.3, 0.0], [73.6, -2.6, 0.24], [76.0, -1.9, -0.12]]:
		var x: float = stub[0]
		var foot := _floor_at(x)
		var top: float = stub[1]
		var lean: float = stub[2]
		b.extrude(PackedVector2Array([Vector2(x - 0.08, foot), Vector2(x + 0.08, foot),
				Vector2(x + 0.08 + lean * (top - foot), top - 0.12), Vector2(x + 0.03 + lean * (top - foot), top + 0.05),
				Vector2(x - 0.02 + lean * (top - foot), top - 0.18), Vector2(x - 0.08 + lean * (top - foot), top)]), -0.12 - 2.0, 0.04 - 2.0)
	add_child(b.build())


## What is under x in the canal: a walkway's top, or the water.
func _floor_at(x: float) -> float:
	for w: Array in Canals.WALKWAYS:
		if x >= w[0] and x <= w[1]:
			return w[2]
	return Village.CANAL_WATER - 0.4


## The back of the hole: the street behind it carries on (paving at street
## level), its broken edge torn in layers over the canal's back wall.
func _build_back_edge() -> void:
	var left := Village.FALL_LEFT
	var right := Village.FALL_RIGHT
	village._lay_paving(left, right, 0.0, Village.STREET_BACK, Village.FALL_BACK)
	var lip := PaperMesh.new(_rng.randi())
	lip.shade_jitter = 0.04
	lip.color = Color(0.17, 0.185, 0.27)
	lip.torn_sheet(village._torn_band(left, right, 0.0, -1.0, 0.0), Village.FALL_BACK + 0.02, Color(0.36, 0.39, 0.52), 0.03)
	lip.color = Color(0.08, 0.087, 0.155)
	lip.torn_sheet(village._torn_band(left, right, -0.35, -2.4, 0.13), Village.FALL_BACK + 0.06, Color(0.16, 0.18, 0.28), 0.03)
	# Roots and torn paper hanging over the edge, swaying.
	var back := lip.build()
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(back)
	var x := left + _rng.randf_range(0.6, 1.5)
	while x < right - 0.5:
		var hang := Node3D.new()
		hang.position = Vector3(x, -0.05, Village.FALL_BACK + 0.12)
		add_child(hang)
		var root := PaperMesh.new(_rng.randi())
		root.color = Color(0.13, 0.11, 0.12) if _rng.randf() < 0.6 else Color(0.42, 0.4, 0.42)
		var length := _rng.randf_range(0.6, 1.8)
		root.stroke(Vector2(0.0, 0.0), Vector2(_rng.randf_range(-0.1, 0.1), -length), _rng.randf_range(0.03, 0.06), 0.008)
		hang.add_child(root.build())
		Scenery.windswept(hang, 0.03, _rng)
		x += _rng.randf_range(1.2, 3.4)
	# A broken fence along the back, warning people off.
	for f: Array in [[left + 0.4, 5.6], [left + 7.6, 3.2], [right - 5.4, 5.0]]:
		var rails := Scenery.fence(_rng, f[1])
		rails.position = Vector3(f[0], 0.0, -3.2)
		add_child(rails)


## Paving slabs that fell with the street, lying tilted on the walkway and
## in the water below; a lantern that fell with them.
func _build_debris() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	for slab: Array in [[64.8, -4.6, 0.3, -1.6], [66.2, -4.6, -0.5, -0.4], [72.5, -4.2, 0.2, -2.0], [78.4, -4.2, -0.35, -1.2],
			[67.9, Village.CANAL_WATER - 0.1, 0.4, -0.8]]:
		b.color = Village.STREET * _rng.randf_range(0.8, 1.1)
		var at := Vector3(slab[0], slab[1], slab[3])
		var tilt: float = slab[2]
		var half := Vector2(0.55, 0.06)
		var pts := PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
		var turned := PackedVector2Array()
		for q: Vector2 in pts:
			turned.append(Vector2(at.x, at.y + 0.12) + q.rotated(tilt * 0.4))
		b.extrude(turned, at.z - 0.5, at.z + 0.5)
	add_child(b.build())
	var fallen_lantern := Scenery.lantern(_rng, 0.0, 0.7, 0.0)
	fallen_lantern.position = Vector3(65.4, -4.42, -1.9)
	fallen_lantern.rotation.z = 1.4
	add_child(fallen_lantern)
