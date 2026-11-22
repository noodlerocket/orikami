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
## Running, the view leads further, by up to this much more (metres), so he
## sees what he runs toward. It eases in and out as gently as the turn.
@export var run_lead := 0.9

## How much the camera rises and falls with him. 0 = it stays at one height
## (street level) however high he jumps or climbs; 1 = it follows him all the
## way up, as it used to. Julian asked for it to stay level.
@export_range(0.0, 1.0) var follow_height := 0.0
## The height he is treated as standing at when follow_height is 0.
@export var level_height := 0.0

## Where the climbing course is (left and right x). There the camera DOES
## follow him up, keeping him in the middle of the screen.
@export var climb_zone := Vector2(37.2, 44.6)
## In the climbing course: how far above his feet the camera sits. With the
## camera's slight downward tilt, this keeps him near the middle of the screen.
@export var climb_height := 2.2
## In the climbing course the camera rises no higher than this.
@export var climb_max_y := 13.0

## Underground (the canals and the drain pipe, between these x positions):
## once he is below street level the camera goes down with him, so the
## tunnels are seen from inside. It blends in as he drops, so it never jumps.
@export var under_zone := Vector2(-1000.0, -1000.0)
## Underground: how far above his feet the camera sits.
@export var under_height := 3.1
## The blend into following him down starts when his feet are this far
## below the street, and is complete this far below it.
@export var under_from := -0.4
@export var under_full := -2.6


## Never let his middle rise above the middle of the screen: when he jumps
## or climbs high enough that it would, the camera rises with him, exactly.
## On the ground he sits below the middle as before. (Julian's rule.)
@export var keep_below_center := true
## How high his middle is above his feet.
@export var body_center := 0.8

@export_group("Smoothing")
@export var follow_speed_x := 6.0
@export var follow_speed_y := 4.0

@export_group("Level limits")
@export var min_x := -7.0
## The camera's middle goes no further right than this: the middle of the
## shrine courtyard, so the whole courtyard is in view at the end of the
## level. (It used to hold still on the courtyard the moment he stepped in,
## and jump back left the moment he stepped out: rejected.)
@export var max_x := 55.25
@export var min_y := 4.2

@export_group("Shake")
@export var shake_fade := 6.0

var target: Node3D
var _shake := 0.0
var _lead := 0.0  # how far the view is leading right now (eases toward look_ahead)


func _ready() -> void:
	rotation_degrees = Vector3(tilt_degrees, 0.0, 0.0)
	cull_mask &= ~Hannya.SHADOW_LAYER  # the Hannya's silhouette double is for her shadow only


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
	# Smoothing must never let him rise past the middle of the screen. (He
	# crosses that line smoothly, so holding the camera to it does not jerk.)
	if keep_below_center and target:
		position.y = maxf(position.y, _lowest_y_keeping_center(target.global_position))
	position.z = distance
	_shake = move_toward(_shake, 0.0, shake_fade * delta * maxf(_shake, 0.05))
	h_offset = randf_range(-_shake, _shake)
	v_offset = randf_range(-_shake, _shake)


## The lowest the camera may be so that his middle is no higher than the
## middle of the screen. (The camera looks down a little, so the middle of
## the screen meets his plane `distance * tan(tilt)` below the camera.)
func _lowest_y_keeping_center(at: Vector3) -> float:
	return at.y + body_center + distance * tan(deg_to_rad(-rotation_degrees.x))


func _wanted_lead() -> float:
	if not "facing" in target:
		return 0.0
	var running := 0.0
	if target is CharacterBody3D:
		running = clampf((target as CharacterBody3D).velocity.x / 7.5, -1.0, 1.0) * run_lead
	return target.facing * look_ahead + running


func _goal() -> Vector3:
	var at := target.global_position
	var y := maxf(lerpf(level_height, at.y, follow_height) + height_offset, min_y)
	if at.x > under_zone.x and at.x < under_zone.y and at.y < under_from:
		var down := smoothstep(under_from, under_full, at.y)
		y = lerpf(y, at.y + under_height, down)
	if at.x > climb_zone.x and at.x < climb_zone.y:
		# Climbing: follow him up, but never lower than the usual view and
		# never above the top of the course.
		y = clampf(at.y + climb_height, y, maxf(climb_max_y, y))
	if keep_below_center:
		y = maxf(y, _lowest_y_keeping_center(at))
	return Vector3(clampf(at.x + _lead, min_x, max_x), y, distance)
