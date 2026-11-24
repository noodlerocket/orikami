class_name Pinwheel
extends Node3D
## A paper pinwheel (kazaguruma) on a bamboo stick, as sold at the fan-maker's
## shop: it turns lazily in the wind, and a gust of the Ronin's fan sets it
## whirring (its spin decays back to the wind's). Origin: the foot of its
## stick. Something the Fan Gust can move (group "gust_target").

## How long its stick is.
@export var height := 1.1
## Its blades' colours.
@export var tints: Array[Color] = [Color(0.62, 0.24, 0.18), Color(0.82, 0.78, 0.7), Color(0.3, 0.34, 0.5), Color(0.62, 0.5, 0.26)]

var _wheel: Node3D
var _spin := 0.0


func _ready() -> void:
	add_to_group(&"gust_target")
	var stick := PaperMesh.new(int(global_position.x * 10.0))
	stick.color = Color(0.55, 0.48, 0.3)
	stick.box(Vector3(0.0, height * 0.5, 0.0), Vector3(0.025, height, 0.025))
	add_child(stick.build())
	_wheel = Node3D.new()
	_wheel.position = Vector3(0.0, height, 0.04)
	add_child(_wheel)
	var b := PaperMesh.new(int(global_position.x * 7.0))
	for k in 4:
		var a := TAU * k / 4.0
		var along := Vector2(cos(a), sin(a))
		var side := Vector2(-along.y, along.x)
		b.color = tints[k % tints.size()]
		# Each blade: a square of paper folded in to the middle, one corner
		# pinned, so it curls like a scoop.
		for face: float in [1.0, -1.0]:
			b.tri(Vector3.ZERO, Vector3(along.x * 0.17, along.y * 0.17, 0.0), Vector3(along.x * 0.17 + side.x * 0.12, along.y * 0.17 + side.y * 0.12, 0.05),
					Vector3(0.0, 0.0, face))
			b.tri(Vector3.ZERO, Vector3(along.x * 0.17 + side.x * 0.12, along.y * 0.17 + side.y * 0.12, 0.05), Vector3(side.x * 0.09, side.y * 0.09, 0.0),
					Vector3(0.0, 0.0, face))
	b.color = Color(0.15, 0.1, 0.08)
	b.box(Vector3.ZERO, Vector3(0.03, 0.03, 0.03))
	_wheel.add_child(b.build())


func _process(delta: float) -> void:
	var lazy := Wind.speed_at(global_position.x) * 1.2
	_spin = move_toward(_spin, lazy, delta * 6.0)
	_wheel.rotation.z -= _spin * delta


## The Fan Gust: whirring.
func gusted(direction: Vector3, _from: Vector3) -> void:
	_spin = 30.0 * (-1.0 if direction.x < 0.0 else 1.0)
