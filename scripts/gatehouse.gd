class_name Gatehouse
extends Node3D
## The Gatehouse (area 5 of the expanded village, docs/village_map.png):
## the old climbing course (Village.CLIMB_WALLS) now stands here. Under the
## first wall, the gatehouse, is a heavy gate, barred on its far (east)
## side. Coming up out of the canals east of it, he can cut the bar: the
## gate swings open, a shortcut back to the river warehouse's shrine.
## From the west the bar cannot be reached (a cut only thuds on the door).
## From the lookout on the tall wall, a broken road climbs away east toward
## the castle: out of reach until he can glide (the Crane Glide).

signal shortcut_opened(which: StringName)

var village: Village
var opened := false

var _rng := RandomNumberGenerator.new()
var _solid: StaticBody3D
var _door: Node3D
var _bar: Node3D
var _left := 0.0
var _right := 0.0


func _ready() -> void:
	_rng.seed = 4411
	var wall: Array = Village.CLIMB_WALLS[0]
	_left = wall[0]
	_right = wall[1]
	_build_gate()
	_build_castle_road()
	# A lantern on the gatehouse, so the door and its bar can be seen.
	village._hang_lantern(Vector3(_right + 0.55, 2.35, 1.25), 0.15, 0.6, false)


func _build_gate() -> void:
	var opening: float = Village.CLIMB_WALLS[0][3]
	var middle := (_left + _right) * 0.5
	_solid = village._add_solid(Vector3(middle, opening * 0.5, 0.0), Vector3(0.5, opening, 2.2))
	# The door: heavy planks with iron bands, seen in the cut-away, hung on
	# the west front post (it swings open toward us).
	_door = Node3D.new()
	_door.position = Vector3(_left + 0.16, 0.0, 1.12)
	add_child(_door)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	var width := _right - _left - 0.32
	var x := 0.0
	while x < width - 0.01:
		var x1 := minf(x + _rng.randf_range(0.22, 0.32), width)
		b.color = Scenery.WOOD.darkened(_rng.randf_range(0.0, 0.2))
		b.box(Vector3((x + x1) * 0.5, opening * 0.5 - 0.02, 0.0), Vector3(x1 - x - 0.02, opening - 0.06, 0.09))
		x = x1
	b.color = Color(0.1, 0.1, 0.13)
	for band: float in [0.35, opening * 0.5, opening - 0.35]:
		b.box(Vector3(width * 0.5, band, 0.055), Vector3(width, 0.08, 0.025))
		for k in 4:
			b.box(Vector3(0.08 + k * (width - 0.16) / 3.0, band, 0.07), Vector3(0.035, 0.035, 0.02))
	_door.add_child(b.build())
	# The bar (kannuki): a beam in two iron brackets, on the east side.
	_bar = Node3D.new()
	_bar.position = Vector3(_right - 0.25, 1.25, 1.24)
	add_child(_bar)
	var bar := PaperMesh.new(_rng.randi())
	bar.shade_jitter = 0.2
	bar.color = Scenery.WOOD.lightened(0.1)
	bar.box(Vector3(0.45, 0.0, 0.0), Vector3(1.4, 0.18, 0.14))
	bar.color = Color(0.12, 0.12, 0.15)
	for bx: float in [0.1, 0.9]:
		bar.box(Vector3(bx, 0.0, 0.03), Vector3(0.08, 0.3, 0.12))
	_bar.add_child(bar.build())
	var target := PropTarget.make(self, BoxShape3D.new(), Vector3(_right + 0.45, 1.25, 0.0))
	((target.get_child(0) as CollisionShape3D).shape as BoxShape3D).size = Vector3(1.2, 0.6, 2.0)
	target.struck.connect(_on_struck)


func _on_struck(direction: Vector2) -> void:
	if opened:
		return
	var ronin := get_tree().get_first_node_in_group(&"player") as Node3D
	if ronin and ronin.global_position.x < _right:
		# From the west: only the door is in reach. A dull thud.
		Sound.play(self, &"grate_clank", -10.0)
		return
	open_gate()


## The bar splits and drops, the door swings open, the way through is clear.
func open_gate(at_once: bool = false) -> void:
	if opened:
		return
	opened = true
	if _solid:
		_solid.queue_free()
		_solid = null
	if at_once:
		_bar.visible = false
		_door.rotation.y = deg_to_rad(-95.0)
		return
	Sound.play(self, &"paper_cut")
	var drop := create_tween()
	drop.tween_property(_bar, "rotation:z", -0.6, 0.18)
	drop.parallel().tween_property(_bar, "position:y", 0.08, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(Sound.play.bind(self, &"plank_snap", -6.0))
	drop.tween_property(_bar, "rotation:z", -1.45, 0.12)
	var swing := create_tween()
	swing.tween_interval(0.3)
	swing.tween_callback(Sound.play.bind(self, &"plank_creak", -2.0))
	swing.tween_property(_door, "rotation:y", deg_to_rad(-104.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	swing.tween_property(_door, "rotation:y", deg_to_rad(-95.0), 0.5).set_trans(Tween.TRANS_SINE)
	shortcut_opened.emit(&"gate")


## A broken road leaving the lookout eastward: a plank bridge on ropes that
## snapped a few metres out, its far half hanging; beyond a wide gap, the
## road goes on, climbing away into the hills with a line of small lights.
func _build_castle_road() -> void:
	var tall: Array = Village.CLIMB_WALLS[1]
	var ledge_y: float = tall[2]
	var start: float = tall[1] + 1.6
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	# The first span: planks on two ropes, sagging out to where they broke.
	var x := start
	while x < start + 2.4:
		var x1 := x + 0.26
		var sag := (x - start) * 0.12
		b.color = Scenery.WOOD.darkened(_rng.randf_range(0.2, 0.4))
		b.box(Vector3((x + x1) * 0.5, ledge_y - 0.06 - sag, -0.6), Vector3(0.22, 0.05, 0.9))
		x = x1
	b.color = Color(0.36, 0.32, 0.26)
	for z: float in [-0.15, -1.05]:
		b.extrude(PackedVector2Array([Vector2(start, ledge_y + 0.6), Vector2(start + 2.5, ledge_y + 0.1),
				Vector2(start + 2.5, ledge_y + 0.07), Vector2(start, ledge_y + 0.57)]), z - 0.015, z + 0.015)
	add_child(b.build())
	# The snapped ends hanging down, swinging.
	for z: float in [-0.15, -1.05]:
		var hang := Node3D.new()
		hang.position = Vector3(start + 2.5, ledge_y + 0.08, z)
		add_child(hang)
		var rope := PaperMesh.new(_rng.randi())
		rope.color = Color(0.36, 0.32, 0.26)
		rope.stroke(Vector2.ZERO, Vector2(0.15, -1.6), 0.03, 0.025)
		rope.color = Scenery.WOOD.darkened(0.3)
		rope.rect(Vector2(0.12, -1.3), Vector2(0.24, 0.05), 0.02)
		hang.add_child(rope.build())
		Scenery.windswept(hang, 0.05, _rng)
	# Beyond the gap: the road goes on, further back, climbing into the
	# hills, small lanterns along it.
	var far := PaperMesh.new(_rng.randi())
	far.shade_jitter = 0.1
	var road := [Vector3(start + 9.5, ledge_y + 0.6, -3.0), Vector3(start + 13.0, ledge_y + 1.6, -6.0),
			Vector3(start + 17.0, ledge_y + 3.0, -11.0), Vector3(start + 22.0, ledge_y + 4.8, -18.0)]
	for k in road.size() - 1:
		var p: Vector3 = road[k]
		var q: Vector3 = road[k + 1]
		far.color = Scenery.WOOD.darkened(0.35 + k * 0.1)
		far.quad(p + Vector3(0.0, 0.0, 0.5), q + Vector3(0.0, 0.0, 0.5), q + Vector3(0.0, 0.0, -0.5), p + Vector3(0.0, 0.0, -0.5), Vector3.UP)
		far.color = PaperMesh.TIMBER
		far.box((p + q) * 0.5 + Vector3(0.0, -1.5, 0.0), Vector3(0.12, 3.0, 0.12))
	var first: Vector3 = road[0]
	far.color = Scenery.WOOD.darkened(0.3)
	for k in 5:
		far.box(first + Vector3(-0.5 - k * 0.24, -0.04 - k * 0.05, 0.0), Vector3(0.2, 0.05, 0.9))
	add_child(far.build())
	for k in road.size():
		var spot: Vector3 = road[k]
		var shine := Scenery.halo(0.7 - k * 0.1, Color(1.0, 0.62, 0.3, 0.4))
		shine.position = spot + Vector3(0.0, 0.5, 0.3)
		add_child(shine)
		var lamp := PaperMesh.new(k + 1)
		lamp.shade_jitter = 0.0
		lamp.color = PaperMesh.LANTERN
		lamp.ellipse(Vector2(spot.x, spot.y + 0.5), Vector2(0.09, 0.12), 8, spot.z + 0.31)
		add_child(lamp.build(Color.WHITE, 2.0, true))
