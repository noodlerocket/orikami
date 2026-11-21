class_name FollowCamera
extends Camera3D
## Side-view camera. It sits back on the Z axis looking at the gameplay plane
## and glides after the Ronin. Because the scenery is at real depths, moving
## the camera gives parallax for free.

@export_group("Framing")
## How far back the camera sits. Bigger = the Ronin looks smaller.
@export var distance := 15.0
## How far above the Ronin the camera sits. Higher = you see more of the
## wet street surface.
@export var height_offset := 4.2
## Tilt down in degrees (negative looks down).
@export var tilt_degrees := -5.0
## How far the view leads in the direction the Ronin faces.
@export var look_ahead := 1.4
## How quickly the view swings round to lead the other way when he turns.
## Lower = gentler. (Before this existed, the view lurched across the
## moment he changed direction.)
@export var look_ahead_ease := 1.6

@export_group("Smoothing")
@export var follow_speed_x := 6.0
@export var follow_speed_y := 4.0

@export_group("Level limits")
@export var min_x := -7.0
@export var max_x := 37.0
@export var min_y := 4.2

@export_group("Shake")
@export var shake_fade := 6.0

var target: Node3D
var _shake := 0.0
var _lead := 0.0  # how far the view is leading right now (eases toward look_ahead)


func _ready() -> void:
	rotation_degrees = Vector3(tilt_degrees, 0.0, 0.0)


func snap_to_target() -> void:
	if target:
		_lead = _wanted_lead()
		position = _goal()


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if not target:
		return
	# Drift the lead toward the side he now faces, instead of jumping there.
	_lead = lerpf(_lead, _wanted_lead(), 1.0 - exp(-look_ahead_ease * delta))
	var goal := _goal()
	position.x = lerpf(position.x, goal.x, 1.0 - exp(-follow_speed_x * delta))
	position.y = lerpf(position.y, goal.y, 1.0 - exp(-follow_speed_y * delta))
	position.z = distance
	_shake = move_toward(_shake, 0.0, shake_fade * delta * maxf(_shake, 0.05))
	h_offset = randf_range(-_shake, _shake)
	v_offset = randf_range(-_shake, _shake)


func _wanted_lead() -> float:
	return target.facing * look_ahead if "facing" in target else 0.0


func _goal() -> Vector3:
	return Vector3(
		clampf(target.global_position.x + _lead, min_x, max_x),
		maxf(target.global_position.y + height_offset, min_y),
		distance)
