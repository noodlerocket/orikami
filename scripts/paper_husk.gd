class_name PaperHusk
extends CharacterBody3D
## A sodden husk: a paper villager the Rain has soaked until it forgot its
## shape. It shuffles back and forth, hurts on touch, crumples a little with
## every hit and bursts into confetti on the third.

@export_group("Health")
@export var max_health := 3
@export var contact_damage := 1

@export_group("Patrol")
@export var patrol_speed := 1.6
## How far it wanders either side of where it was placed.
@export var patrol_distance := 3.5
@export var gravity := 38.0

@export_group("Getting hit")
@export var knockback_speed := 7.0
@export var stun_time := 0.25
@export var flash_time := 0.12
## Each hit squashes it to this fraction of its height ("damaged enemies get crumpled").
@export var crumple_per_hit := 0.85
@export var confetti_count := 48

@export_group("Stop-motion")
@export var frames_per_second := 12.0

var health := 0

var _dir := -1.0
var _home_x := 0.0
var _stun := 0.0
var _flash := 0.0
var _frame_clock := 0.0
var _frame := 0
var _rig: Node3D
var _head: Node3D
var _arms: Array[Node3D] = []
var _materials: Array[StandardMaterial3D] = []
var _touch: Area3D


func _ready() -> void:
	health = max_health
	_home_x = global_position.x
	collision_layer = 4  # "enemies"
	collision_mask = 1   # collides with the "world" only, not the player
	axis_lock_linear_z = true

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.1
	shape.shape = capsule
	shape.position.y = 0.55
	add_child(shape)

	# An invisible box that notices the player touching us.
	_touch = Area3D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = 2  # "player"
	var touch_shape := CollisionShape3D.new()
	var touch_box := BoxShape3D.new()
	touch_box.size = Vector3(0.8, 1.0, 1.0)
	touch_shape.shape = touch_box
	touch_shape.position.y = 0.55
	_touch.add_child(touch_shape)
	add_child(_touch)

	_build()


func _physics_process(delta: float) -> void:
	_stun = maxf(_stun - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta

	if _stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	else:
		if is_on_floor() and (_wall_ahead() or _edge_ahead() or _too_far()):
			_dir = -_dir
		velocity.x = _dir * patrol_speed
	move_and_slide()
	position.z = 0.0

	for body: Node3D in _touch.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(contact_damage, global_position)


func _process(delta: float) -> void:
	_rig.rotation.y = -0.35 if _dir > 0.0 else PI + 0.35
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_set_flash(false)
	_frame_clock += delta
	if _frame_clock >= 1.0 / frames_per_second:
		_frame_clock = 0.0
		_frame += 1
		# A limp, soggy waddle.
		var p := _frame * 0.9
		_rig.rotation.z = sin(p) * 0.09
		_head.rotation.z = -0.55 + sin(p * 0.5) * 0.12
		_arms[0].rotation.z = sin(p) * 0.35
		_arms[1].rotation.z = -sin(p) * 0.35


## Called by the Ronin's slash. `direction` is the way the blade travelled.
func take_hit(damage: int, direction: Vector2) -> void:
	health -= damage
	if health <= 0:
		Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.6, 0.0), confetti_count)
		Sound.play(self, &"paper_burst")
		queue_free()
		return
	_stun = stun_time
	velocity.x = direction.x * knockback_speed
	if direction.y > 0.0:
		velocity.y = 5.0
	_rig.scale.y *= crumple_per_hit
	_rig.scale.x *= 1.0 + (1.0 - crumple_per_hit) * 0.5
	_set_flash(true)
	_flash = flash_time


func _wall_ahead() -> bool:
	return is_on_wall() and get_wall_normal().x * _dir < 0.0


func _edge_ahead() -> bool:
	var from := global_position + Vector3(_dir * 0.55, 0.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 1.0, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _too_far() -> bool:
	return (global_position.x - _home_x) * _dir > patrol_distance


func _set_flash(on: bool) -> void:
	for mat: StandardMaterial3D in _materials:
		mat.emission_enabled = on
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 1.4


func _add(parent: Node3D, mesh: MeshInstance3D) -> void:
	parent.add_child(mesh)
	_materials.append(mesh.material_override as StandardMaterial3D)


func _build() -> void:
	var soggy := Color(0.5, 0.55, 0.68)
	var soaked := Color(0.13, 0.14, 0.22)
	_rig = Node3D.new()
	add_child(_rig)

	# Drooping body, with ink soaked up from the ground.
	var body := PaperMesh.new(101)
	body.shade_jitter = 0.2
	body.color = soggy
	body.frustum(5, Vector2(0.42, 0.36), Vector2(0.2, 0.18), 0.72)
	body.color = soaked
	body.frustum(5, Vector2(0.45, 0.39), Vector2(0.39, 0.33), 0.18)
	_add(_rig, body.build())

	# Head that has forgotten how to hold itself up.
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.68, 0.0)
	_rig.add_child(_head)
	var head := PaperMesh.new(102)
	head.shade_jitter = 0.2
	head.color = soggy
	head.frustum(5, Vector2(0.21, 0.19), Vector2(0.11, 0.1), 0.32)
	head.color = PaperMesh.SUMI
	head.tri(Vector3(0.2, 0.1, -0.06), Vector3(0.19, 0.19, 0.0), Vector3(0.2, 0.08, 0.07), Vector3.RIGHT)
	_add(_head, head.build())

	# Two limp strips for arms.
	for side: float in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(0.0, 0.6, side * 0.22)
		_rig.add_child(arm)
		var strip := PaperMesh.new(103)
		strip.color = soggy
		strip.quad(Vector3(-0.06, 0.0, 0.0), Vector3(0.06, 0.0, 0.0),
				Vector3(0.1, -0.42, side * 0.05), Vector3(-0.02, -0.46, side * 0.05))
		_add(arm, strip.build())
		_arms.append(arm)
