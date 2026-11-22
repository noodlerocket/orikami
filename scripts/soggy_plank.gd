class_name SoggyPlank
extends Node3D
## A rain-soaked plank laid over the hole in the Fallen Street. It holds him
## for a moment: it sags and creaks under him, shudders, then snaps and
## falls into the canal below, with him on it. (The way down: the old pit
## is no longer a death.) A fallen plank floats in the water for a while.
## Origin: its left end, on the street's surface.

## Its length along the street (metres).
@export var length := 2.2
## Seconds he can stand on it before it gives way.
@export var give_time := 0.55
## How far it sags under him before it snaps (metres).
@export var sag_depth := 0.16

var ronin: Ronin
var fallen := false

var _body: AnimatableBody3D
var _board: Node3D
var _load := 0.0       # seconds he has been on it
var _was_on := false
var _creaked := false
var _velocity := Vector3.ZERO
var _spin := 0.0
var _afloat := false
var _bob := 0.0


func _ready() -> void:
	process_physics_priority = 10  # after the Ronin has moved
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 53.0)
	_board = Node3D.new()
	add_child(_board)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.16
	# Two or three boards side by side (across the path), swollen and dark
	# with rain, nailed to a batten underneath.
	var z := -1.1
	while z < 1.05:
		var wide := rng.randf_range(0.45, 0.8)
		var z1 := minf(z + wide, 1.1)
		b.color = Scenery.WOOD.darkened(rng.randf_range(0.25, 0.45))
		var drop := rng.randf_range(-0.02, 0.02)
		b.box(Vector3(length * 0.5, -0.05 + drop, (z + z1) * 0.5), Vector3(length - rng.randf_range(0.0, 0.25), 0.09, z1 - z - 0.03))
		z = z1
	b.color = PaperMesh.TIMBER
	for bx: float in [0.25, length - 0.25]:
		b.box(Vector3(bx, -0.13, 0.0), Vector3(0.12, 0.08, 2.1))
	# Dark water stains and a crack along the middle.
	b.color = Color(0.08, 0.07, 0.09)
	for k in 3:
		b.box(Vector3(rng.randf_range(0.3, length - 0.3), -0.003, rng.randf_range(-0.8, 0.8)), Vector3(rng.randf_range(0.2, 0.5), 0.004, 0.06))
	_board.add_child(b.build())
	_body = AnimatableBody3D.new()
	_body.sync_to_physics = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.12, 2.2)
	shape.shape = box
	_body.add_child(shape)
	_body.position = Vector3(length * 0.5, -0.06, 0.0)
	add_child(_body)


func _physics_process(delta: float) -> void:
	if fallen:
		_fall(delta)
		return
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if ronin == null:
			return
	var x := ronin.global_position.x - global_position.x
	var on := x > -0.25 and x < length + 0.25 and ronin.is_on_floor() \
			and absf(ronin.global_position.y - (global_position.y - _sag())) < 0.25
	if on and not _was_on:
		Sound.play(self, &"plank_creak", -6.0)
	_was_on = on
	if on:
		_load += delta
		if _load > give_time * 0.5 and not _creaked:
			_creaked = true
			Sound.play(self, &"plank_creak", -2.0)
		if _load >= give_time:
			give_way()
	else:
		_load = maxf(_load - delta * 0.5, 0.0)
	# It sags under him and shudders as it is about to go.
	var shudder := sin(Time.get_ticks_msec() * 0.06) * 0.012 * smoothstep(0.5, 1.0, _load / give_time)
	_board.position.y = -_sag() + shudder
	_board.rotation.z = shudder * 0.6
	_body.position.y = -0.06 - _sag()


func _sag() -> float:
	return sag_depth * smoothstep(0.0, 1.0, _load / give_time)


## It snaps: splinters fly, and it drops into the canal.
func give_way() -> void:
	if fallen:
		return
	fallen = true
	_body.queue_free()
	Sound.play(self, &"plank_snap")
	_splinters()
	_velocity = Vector3(randf_range(-0.6, 0.6), -1.0, 0.0)
	_spin = randf_range(-1.6, 1.6)


func _fall(delta: float) -> void:
	var water := Village.CANAL_WATER
	if not _afloat:
		_velocity.y -= 22.0 * delta
		_board.position += _velocity * delta
		_board.rotation.z += _spin * delta
		if global_position.y + _board.position.y <= water + 0.05:
			_afloat = true
			_board.position.y = water - global_position.y + 0.05
			WaterFx.splash(get_parent(), _board.global_position + Vector3(length * 0.5, 0.0, 0.0), 1.2)
			Sound.play(self, &"splash", -4.0)
		return
	# Afloat: it settles flat, bobs, drifts slowly east, waterlogged.
	_bob += delta
	_board.rotation.z = move_toward(_board.rotation.z, round(_board.rotation.z / PI) * PI, delta * 0.8)
	_board.position.y = water - global_position.y + 0.05 + sin(_bob * 1.7) * 0.025
	_board.position.x += delta * 0.18


func _splinters() -> void:
	var chips := CPUParticles3D.new()
	chips.emitting = false
	chips.one_shot = true
	chips.explosiveness = 1.0
	chips.amount = 24
	chips.lifetime = 1.2
	chips.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	chips.emission_box_extents = Vector3(length * 0.4, 0.05, 0.9)
	chips.direction = Vector3.UP
	chips.spread = 70.0
	chips.gravity = Vector3(0.0, -14.0, 0.0)
	chips.initial_velocity_min = 1.5
	chips.initial_velocity_max = 4.0
	chips.angle_max = 360.0
	chips.angular_velocity_min = -400.0
	chips.angular_velocity_max = 400.0
	var chip := QuadMesh.new()
	chip.size = Vector2(0.12, 0.03)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Scenery.WOOD.darkened(0.15)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	chip.material = look
	chips.mesh = chip
	add_child(chips)
	chips.position = Vector3(length * 0.5, 0.0, 0.0)
	chips.emitting = true
	chips.finished.connect(chips.queue_free)
