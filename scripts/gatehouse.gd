class_name Gatehouse
extends Node3D
## The Gatehouse (area 5 of the expanded village, docs/village_map.png):
## the old climbing course (Village.CLIMB_WALLS) now stands here. Under the
## first wall, the gatehouse, the heavy gate stands open: he runs straight
## through.

signal shortcut_opened(which: StringName)

var village: Village
var opened := true

var _rng := RandomNumberGenerator.new()
var _door: Node3D
## The door, standing open: swung back from us, seen edge-on.
const OPEN_ANGLE := 88.0

var _left := 0.0
var _right := 0.0


func _ready() -> void:
	_rng.seed = 4411
	var wall: Array = Village.CLIMB_WALLS[0]
	_left = wall[0]
	_right = wall[1]
	_build_gate()
	# A lantern on the gatehouse, lighting the way under it.
	village._hang_lantern(Vector3(_right + 0.55, 2.35, 1.25), 0.15, 0.6, false)


func _build_gate() -> void:
	var opening: float = Village.CLIMB_WALLS[0][3]
	# The way under the wall is always open (Julian: "make it so that the
	# player can actually run through it"; a barred gate stopped him). Its
	# heavy door stands swung back, seen edge-on, against the passage's
	# west post.
	_door = Node3D.new()
	_door.position = Vector3(_left + 0.16, 0.0, 1.12)
	_door.rotation.y = deg_to_rad(OPEN_ANGLE)
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
	# Its bar, set down long ago against the wall's foot.
	var bar := PaperMesh.new(_rng.randi())
	bar.shade_jitter = 0.2
	bar.color = Scenery.WOOD.lightened(0.05)
	bar.extrude(PackedVector2Array([Vector2(_right + 0.05, 0.0), Vector2(_right + 0.2, 0.0),
			Vector2(_right + 0.55, 1.2), Vector2(_right + 0.4, 1.22)]), -1.15, -1.0)
	add_child(bar.build())


## (Kept for old saves and callers: the gate always stands open now.)
func open_gate(_at_once: bool = false) -> void:
	opened = true
