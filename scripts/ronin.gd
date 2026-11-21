class_name Ronin
extends CharacterBody3D
## The Blank Ronin's controls and rules: run, jump, dash, slash, pogo, heal.
## The look lives in ronin_puppet.gd; this file is only about how he MOVES.
##
## Every number below is an @export, so you can select the Ronin node in the
## editor and tune it in the Inspector without touching code.

signal health_changed(current: int, maximum: int)
signal ink_changed(current: int, maximum: int)
signal slash_landed
signal hurt

@export_group("Run")
@export var run_speed := 7.5
## How fast he reaches full speed. Higher = snappier.
@export var ground_acceleration := 120.0
## How fast he stops when you let go. Higher = less sliding.
@export var ground_deceleration := 140.0
@export var air_acceleration := 90.0

@export_group("Jump")
## Upward speed at take-off. Jump height is roughly jump_velocity^2 / (2 * gravity).
@export var jump_velocity := 13.5
@export var gravity := 38.0
## Extra gravity while falling, so jumps feel less floaty.
@export var fall_gravity_multiplier := 1.25
@export var max_fall_speed := 22.0
## Letting go of jump early multiplies upward speed by this (variable height).
@export var jump_cut_multiplier := 0.4
## Grace period: you can still jump this long after walking off a ledge.
@export var coyote_time := 0.09
## Grace period: a jump pressed this long before landing still counts.
@export var jump_buffer_time := 0.11

@export_group("Dash")
@export var dash_speed := 19.0
@export var dash_duration := 0.17
@export var dash_cooldown := 0.4

@export_group("Slash")
@export var slash_damage := 1
## How long the blade can hit things after the button press.
@export var slash_active_time := 0.12
@export var slash_cooldown := 0.3
## How far in front of the body the hit area is centred.
@export var slash_reach := 0.85
## Hit area size: (length along the swing, width across it).
## The cut hits out to slash_reach + half the length = 1.6 m, which is where
## the white swoosh ends (RoninPuppet.sweep_reach). Keep the two in step:
## a cut should hit what the swoosh touches and nothing beyond it.
@export var slash_size := Vector2(1.5, 1.4)
## Upward bounce when a downward slash connects.
@export var pogo_velocity := 12.0
## Push-back when a sideways slash connects.
@export var recoil_speed := 5.0
@export var recoil_time := 0.08
## Tiny freeze on hit that makes blows feel heavy.
@export var hit_stop_time := 0.05

@export_group("Health and Ink")
@export var max_health := 5
## Seconds of safety after being hurt.
@export var invulnerable_time := 1.0
@export var hurt_knockback := Vector2(8.0, 8.0)
@export var hurt_lock_time := 0.25
@export var max_ink := 9
@export var ink_per_hit := 1
@export var heal_cost := 3
## How long K must be held to heal one point.
@export var heal_hold_time := 0.9
## Falling below this height counts as falling out of the world.
@export var fall_limit_y := -10.0
@export var respawn_delay := 0.9

const ENEMY_LAYER_MASK := 4
const BODY_CENTER := Vector3(0.0, 0.75, 0.0)
# Slash directions use "y up" like the 3D world. (Godot's own Vector2.UP points
# the other way, because 2D screens count y downward, so we avoid it here.)
const SLASH_UP := Vector2(0.0, 1.0)
const SLASH_DOWN := Vector2(0.0, -1.0)

var health := 0
var ink := 0
## 1 = facing right, -1 = facing left.
var facing := 1.0

var _coyote := 0.0
var _jump_buffer := 0.0
var _jumping := false
var _dash_time := 0.0
var _dash_cooldown_left := 0.0
var _dash_dir := 1.0
var _can_dash := true
var _slash_time := 0.0
var _slash_cooldown_left := 0.0
var _slash_dir := Vector2.RIGHT
var _slash_hits: Array[Object] = []
var _recoil_left := 0.0
var _hurt_lock := 0.0
var _invulnerable := 0.0
var _heal_progress := 0.0
var _healing := false
var _dead := false
var _grounded_time := 0.0
var _safe_position := Vector3.ZERO
var _spawn_position := Vector3.ZERO

@onready var _puppet: RoninPuppet = $Puppet


func _ready() -> void:
	health = max_health
	_spawn_position = global_position
	_safe_position = global_position


func _physics_process(delta: float) -> void:
	_count_down(delta)
	var grounded := is_on_floor()

	if _dead:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		_apply_gravity(delta, grounded)
		move_and_slide()
		_update_puppet()
		return

	# --- Read the controls ---
	var move := Input.get_axis("move_left", "move_right")
	move = signf(move) if absf(move) > 0.3 else 0.0

	if grounded:
		_coyote = coyote_time
		if _dash_time <= 0.0:
			_can_dash = true
		_grounded_time += delta
		if _grounded_time > 0.3:
			_safe_position = global_position
	else:
		_grounded_time = 0.0

	_update_heal(delta, grounded)
	if _healing:
		move = 0.0

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	var busy := _hurt_lock > 0.0 or _healing
	if Input.is_action_just_pressed("dash") and _can_dash and _dash_cooldown_left <= 0.0 and not busy:
		_start_dash(move)
	if Input.is_action_just_pressed("slash") and _slash_cooldown_left <= 0.0 and _dash_time <= 0.0 and not busy:
		_start_slash(grounded)

	# --- Work out the velocity ---
	if _dash_time > 0.0:
		# Dashing: a straight horizontal burst that ignores gravity.
		velocity = Vector3(_dash_dir * dash_speed, 0.0, 0.0)
		if _dash_time - delta <= 0.0:
			velocity.x = _dash_dir * run_speed
	elif _hurt_lock > 0.0:
		# Knocked back: no control for a moment.
		_apply_gravity(delta, grounded)
	else:
		if _recoil_left <= 0.0:
			var rate := air_acceleration
			if grounded:
				rate = ground_acceleration if move != 0.0 else ground_deceleration
			velocity.x = move_toward(velocity.x, move * run_speed, rate * delta)
			if move != 0.0 and _slash_time <= 0.0:
				facing = move
		_apply_gravity(delta, grounded)
		if _jump_buffer > 0.0 and _coyote > 0.0:
			velocity.y = jump_velocity
			Sound.play(self, &"jump")
			_jumping = true
			_jump_buffer = 0.0
			_coyote = 0.0
		# Variable jump height: releasing the button early cuts the jump short.
		if _jumping and velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			velocity.y *= jump_cut_multiplier
			_jumping = false
		if velocity.y <= 0.0:
			_jumping = false

	move_and_slide()
	position.z = 0.0  # Gameplay stays on a single plane.

	_update_slash()
	if global_position.y < fall_limit_y:
		_fell_out_of_world()
	_update_puppet()


## Called by enemies when they touch the Ronin.
func take_damage(amount: int, from: Vector3) -> void:
	if _invulnerable > 0.0 or _dead:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	hurt.emit()
	Sound.play(self, &"hurt")
	_invulnerable = invulnerable_time
	_dash_time = 0.0
	_slash_time = 0.0
	_jumping = false
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	velocity = Vector3(away * hurt_knockback.x, hurt_knockback.y, 0.0)
	_hurt_lock = hurt_lock_time
	_hit_stop(hit_stop_time * 2.0)
	if health <= 0:
		_die()


func _count_down(delta: float) -> void:
	_coyote = maxf(_coyote - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_dash_time = maxf(_dash_time - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_slash_time = maxf(_slash_time - delta, 0.0)
	_slash_cooldown_left = maxf(_slash_cooldown_left - delta, 0.0)
	_recoil_left = maxf(_recoil_left - delta, 0.0)
	_hurt_lock = maxf(_hurt_lock - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)


func _apply_gravity(delta: float, grounded: bool) -> void:
	if grounded and velocity.y <= 0.0:
		return
	var pull := gravity * (fall_gravity_multiplier if velocity.y < 0.0 else 1.0)
	velocity.y = maxf(velocity.y - pull * delta, -max_fall_speed)


func _start_dash(move: float) -> void:
	Sound.play(self, &"dash")
	_dash_dir = move if move != 0.0 else facing
	facing = _dash_dir
	_dash_time = dash_duration
	_dash_cooldown_left = dash_cooldown
	_can_dash = false
	_jumping = false


func _start_slash(grounded: bool) -> void:
	Sound.play(self, &"slash")
	var aim := Input.get_axis("aim_down", "aim_up")
	if aim > 0.5:
		_slash_dir = SLASH_UP
	elif aim < -0.5 and not grounded:
		_slash_dir = SLASH_DOWN  # Down-slash only works in the air (pogo).
	else:
		_slash_dir = Vector2(facing, 0.0)
	_slash_time = slash_active_time
	_slash_cooldown_left = slash_cooldown
	_slash_hits.clear()
	_puppet.play_slash(_slash_dir)


## While the blade is active, ask the physics engine "what enemies are inside
## this box in front of me?" and hit each one once.
func _update_slash() -> void:
	if _slash_time <= 0.0:
		return
	var shape := BoxShape3D.new()
	if _slash_dir.x != 0.0:
		shape.size = Vector3(slash_size.x, slash_size.y, 2.0)
	else:
		shape.size = Vector3(slash_size.y, slash_size.x, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = ENEMY_LAYER_MASK
	query.transform = Transform3D(Basis.IDENTITY,
			global_position + BODY_CENTER + Vector3(_slash_dir.x, _slash_dir.y, 0.0) * slash_reach)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var target: Object = result["collider"]
		if target in _slash_hits or not target.has_method("take_hit"):
			continue
		_slash_hits.append(target)
		target.take_hit(slash_damage, _slash_dir)
		_on_slash_connected()


func _on_slash_connected() -> void:
	ink = mini(ink + ink_per_hit, max_ink)
	ink_changed.emit(ink, max_ink)
	slash_landed.emit()
	Sound.play(self, &"paper_cut")
	if _slash_dir == SLASH_DOWN:
		# Pogo: bounce up off whatever we hit, and get the air-dash back.
		velocity.y = pogo_velocity
		_jumping = false
		_can_dash = true
	elif _slash_dir.x != 0.0:
		velocity.x = -_slash_dir.x * recoil_speed
		_recoil_left = recoil_time
	_hit_stop(hit_stop_time)


func _update_heal(delta: float, grounded: bool) -> void:
	_healing = (grounded and Input.is_action_pressed("heal") and ink >= heal_cost
			and health < max_health and _hurt_lock <= 0.0 and _dash_time <= 0.0)
	if not _healing:
		_heal_progress = 0.0
		return
	_heal_progress += delta
	if _heal_progress >= heal_hold_time:
		_heal_progress = 0.0
		ink -= heal_cost
		health += 1
		Sound.play(self, &"heal")
		ink_changed.emit(ink, max_ink)
		health_changed.emit(health, max_health)


func _fell_out_of_world() -> void:
	health = maxi(health - 1, 0)
	health_changed.emit(health, max_health)
	hurt.emit()
	Sound.play(self, &"hurt")
	velocity = Vector3.ZERO
	global_position = _safe_position
	_invulnerable = invulnerable_time
	if health <= 0:
		_die()


func _die() -> void:
	_dead = true
	await get_tree().create_timer(respawn_delay).timeout
	global_position = _spawn_position
	_safe_position = _spawn_position
	velocity = Vector3.ZERO
	health = max_health
	health_changed.emit(health, max_health)
	_invulnerable = invulnerable_time
	_dead = false


## Freezes the whole game for a split second.
func _hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _update_puppet() -> void:
	_puppet.facing = facing
	_puppet.vertical_speed = velocity.y
	_puppet.horizontal_speed = velocity.x
	_puppet.blinking = _invulnerable > 0.0 and not _dead
	if _dead or _hurt_lock > 0.0:
		_puppet.state = &"hurt"
	elif _dash_time > 0.0:
		_puppet.state = &"dash"
	elif _healing:
		_puppet.state = &"heal"
	elif not is_on_floor():
		_puppet.state = &"jump" if velocity.y > 0.0 else &"fall"
	elif absf(velocity.x) > 0.5:
		_puppet.state = &"run"
	else:
		_puppet.state = &"idle"
