class_name PaperDog
extends PaperCritter
## The paper dog (inu-hariko): a papier-mache dog charm, the kind given for
## a safe birth, soaked grey by the Rain and gone feral in the canals. Low
## and fast. It trots back and forth; when it sees him ahead on its level
## it drops low, its paper ruff fans up and it growls (the tell), then
## charges along the ground. Jump over it, or parry the charge: a parried
## charge throws it back, staggered, for a finishing cut. Touching it hurts
## (it snaps). After a charge it skids to a stop and shakes itself.

@export_group("Hunting")
## How far ahead it sees him (metres), and how far up or down.
@export var sight := 7.5
@export var sight_rise := 1.3
@export var trot_speed := 1.6
@export var patrol_distance := 3.0
## The tell: how long it crouches and growls before charging.
@export var charge_windup := 0.5
@export var charge_speed := 11.0
## The longest a charge lasts (seconds).
@export var charge_time := 0.9
@export var attack_damage := 1
## Rest after a charge before it can charge again.
@export var charge_cooldown := 1.6
@export var gravity := 38.0

const SOAKED := Color(0.62, 0.64, 0.7)
const SOAKED_DARK := Color(0.32, 0.34, 0.42)
const MARK := Color(0.5, 0.2, 0.17)   # the faded red of its painted markings

var _home_x := 0.0
var _cooldown := 0.0
var _struck_this_charge := false
var _stride := 0.0
var _body: Node3D
var _head: Node3D
var _jaw: Node3D
var _tail: Node3D
var _ruff: Node3D
var _legs: Array[Node3D] = []   # front left, front right, back left, back right
var _dust: CPUParticles3D


func _ready() -> void:
	max_health = 2
	confetti_count = 30
	super._ready()
	_home_x = global_position.x
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.55, 0.5)
	shape.shape = box
	shape.position.y = 0.3
	add_child(shape)
	_make_touch(Vector3(0.8, 0.5, 1.0), Vector3(0.0, 0.3, 0.0))


func _body_centre() -> Vector3:
	return Vector3(0.0, 0.35, 0.0)


func _build() -> void:
	var seed_value := int(global_position.x * 13.0) + 5
	_body = Node3D.new()
	_body.position = Vector3(0.0, 0.34, 0.0)
	_rig.add_child(_body)
	# The body: a chubby folded box, rounder at the chest, a pale belly.
	var b := PaperMesh.new(seed_value)
	b.texture_world = false
	b.shade_jitter = 0.18
	b.color = SOAKED
	b.loft([PaperCritter.ring_x(Vector3(-0.32, 0.02, 0.0), Vector2(0.13, 0.16), 6), PaperCritter.ring_x(Vector3(-0.1, 0.04, 0.0), Vector2(0.2, 0.2), 6),
			PaperCritter.ring_x(Vector3(0.14, 0.05, 0.0), Vector2(0.21, 0.21), 6), PaperCritter.ring_x(Vector3(0.3, 0.06, 0.0), Vector2(0.15, 0.17), 6)])
	# Painted markings, faded: spots on its back and a collar.
	b.color = MARK
	for spot: Vector3 in [Vector3(-0.12, 0.25, 0.08), Vector3(0.06, 0.26, -0.06)]:
		b.box(spot, Vector3(0.12, 0.012, 0.1))
	b.box(Vector3(0.31, 0.12, 0.0), Vector3(0.05, 0.2, 0.34))
	# Rain-dark soaking up from below.
	b.color = SOAKED_DARK
	b.box(Vector3(0.0, -0.12, 0.0), Vector3(0.5, 0.05, 0.3))
	_part(_body, b.build())
	# The ruff: paper frills folded flat on its neck, fanned up in the tell.
	_ruff = Node3D.new()
	_ruff.position = Vector3(0.24, 0.16, 0.0)
	_body.add_child(_ruff)
	var ruff := PaperMesh.new(seed_value + 1)
	ruff.texture_world = false
	ruff.color = SOAKED.lightened(0.1)
	for k in 5:
		var z := -0.14 + k * 0.07
		ruff.tri(Vector3(-0.02, 0.0, z), Vector3(-0.16, 0.2, z + 0.02), Vector3(-0.1, 0.0, z + 0.035), Vector3.BACK)
	_part(_ruff, ruff.build())
	# The head, on a short neck: a rounded box, a short snout, triangle ears,
	# painted eyes and brows.
	_head = Node3D.new()
	_head.position = Vector3(0.34, 0.2, 0.0)
	_body.add_child(_head)
	var h := PaperMesh.new(seed_value + 2)
	h.texture_world = false
	h.shade_jitter = 0.15
	h.color = SOAKED
	h.loft([PaperCritter.ring_x(Vector3(-0.04, 0.0, 0.0), Vector2(0.14, 0.15), 6), PaperCritter.ring_x(Vector3(0.1, 0.02, 0.0), Vector2(0.15, 0.16), 6),
			PaperCritter.ring_x(Vector3(0.2, -0.01, 0.0), Vector2(0.08, 0.09), 6)])
	for side: float in [-1.0, 1.0]:
		h.color = SOAKED.darkened(0.1)
		h.tri(Vector3(0.0, 0.12, side * 0.06), Vector3(0.06, 0.12, side * 0.13), Vector3(-0.02, 0.27, side * 0.1), Vector3(0.0, 0.0, side))
		h.color = PaperMesh.SUMI
		h.box(Vector3(0.12, 0.06, side * 0.12), Vector3(0.03, 0.03, 0.01))  # eye
		h.color = MARK
		h.box(Vector3(0.11, 0.1, side * 0.115), Vector3(0.06, 0.012, 0.01))  # brow
	h.color = PaperMesh.SUMI
	h.box(Vector3(0.28, 0.0, 0.0), Vector3(0.03, 0.035, 0.05))  # nose
	_part(_head, h.build())
	# The jaw: it drops open when it snaps or growls.
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.12, -0.06, 0.0)
	_head.add_child(_jaw)
	var j := PaperMesh.new(seed_value + 3)
	j.texture_world = false
	j.color = SOAKED.darkened(0.05)
	j.box(Vector3(0.07, -0.02, 0.0), Vector3(0.15, 0.04, 0.1))
	j.color = MARK.darkened(0.3)
	j.box(Vector3(0.06, 0.005, 0.0), Vector3(0.12, 0.01, 0.07))
	_part(_jaw, j.build())
	# Four short legs, each a folded tapering column with a dark paw.
	for leg in 4:
		var front := leg < 2
		var side := -1.0 if leg % 2 == 0 else 1.0
		var hip := Node3D.new()
		hip.position = Vector3(0.22 if front else -0.24, -0.06, side * 0.11)
		_body.add_child(hip)
		var l := PaperMesh.new(seed_value + 10 + leg)
		l.texture_world = false
		l.color = SOAKED.darkened(0.05 if side > 0.0 else 0.15)
		l.frustum(5, Vector2(0.06, 0.06), Vector2(0.045, 0.045), 0.24, Vector3(0.0, -0.26, 0.0))
		l.color = SOAKED_DARK
		l.box(Vector3(0.02, -0.25, 0.0), Vector3(0.09, 0.03, 0.07))
		_part(hip, l.build())
		_legs.append(hip)
	# A curled tail.
	_tail = Node3D.new()
	_tail.position = Vector3(-0.33, 0.08, 0.0)
	_body.add_child(_tail)
	var t := PaperMesh.new(seed_value + 20)
	t.texture_world = false
	t.color = SOAKED
	t.stroke(Vector2(0.0, 0.0), Vector2(-0.08, 0.14), 0.05, 0.035)
	t.stroke(Vector2(-0.08, 0.14), Vector2(0.0, 0.22), 0.035, 0.015)
	_part(_tail, t.build())
	# Dust and water kicked up when it skids.
	_dust = CPUParticles3D.new()
	_dust.emitting = false
	_dust.amount = 16
	_dust.lifetime = 0.5
	_dust.direction = Vector3(0.0, 1.0, 0.0)
	_dust.spread = 50.0
	_dust.gravity = Vector3(0.0, -9.0, 0.0)
	_dust.initial_velocity_min = 0.8
	_dust.initial_velocity_max = 2.0
	var drop := QuadMesh.new()
	drop.size = Vector2(0.04, 0.04)
	drop.material = WaterFx.bead_material(Color(0.7, 0.75, 0.88, 0.6))
	_dust.mesh = drop
	_dust.position = Vector3(0.0, 0.05, 0.0)
	add_child(_dust)


func _physics_process(delta: float) -> void:
	_tick(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta
	match mode:
		&"tell":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= charge_windup:
				_set_mode(&"charge")
				_struck_this_charge = false
				Sound.play(self, &"dog_bark")
		&"charge":
			velocity.x = _dir * charge_speed
			if not _struck_this_charge:
				_bite(0.5)
			if _mode_time >= charge_time or (is_on_floor() and (_wall_ahead() or _edge_ahead(0.7))):
				_set_mode(&"skid")
				_dust.emitting = true
		&"skid":
			velocity.x = move_toward(velocity.x, 0.0, 26.0 * delta)
			if _mode_time >= 0.45:
				_dust.emitting = false
				_set_mode(&"recover")
				_cooldown = charge_cooldown
		&"recover", &"stagger", &"hurt":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			var wait := {&"recover": 0.7, &"stagger": stagger_time, &"hurt": 0.3}[mode] as float
			if _mode_time >= wait:
				if mode == &"stagger":
					posture = 0
				_set_mode(&"patrol")
		&"snap":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= 0.3:
				_set_mode(&"patrol")
		_:
			if is_on_floor() and (_wall_ahead() or _edge_ahead() or (global_position.x - _home_x) * _dir > patrol_distance):
				_dir = -_dir
			velocity.x = _dir * trot_speed
			if _cooldown <= 0.0 and is_on_floor() and _player_ahead(sight, 2.0, sight_rise):
				_set_mode(&"tell")
				Sound.play(self, &"dog_growl")
	move_and_slide()
	position.z = 0.0
	if mode == &"patrol" or mode == &"recover":
		for body: Node3D in _touch.get_overlapping_bodies():
			if body.has_method("take_damage") and body.take_damage(contact_damage, global_position):
				_dir = signf(body.global_position.x - global_position.x)
				_set_mode(&"snap")


## The charge reaching him: its teeth are an attack (it can be parried).
func _bite(reach: float) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 0.8, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * reach, 0.4, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_struck_this_charge = true
			if target.receive_strike(attack_damage, global_position):
				velocity.x = -_dir * 7.0
				velocity.y = 3.5
				_on_parried()
			return


func _on_hit(direction: Vector2) -> void:
	velocity.x = direction.x * knockback_speed
	if direction.y < -0.5:
		velocity.y = -2.0
	if mode != &"stagger":
		_set_mode(&"hurt")
		Sound.play(self, &"dog_yelp")


func _pose() -> void:
	_rig.rotation.y = -0.3 if _dir > 0.0 else PI + 0.3
	var trot := 0.0
	var body_tilt := 0.0
	var body_low := 0.0
	var head_tilt := 0.0
	var jaw := 0.0
	var ruff := -1.35  # folded flat
	var tail := 0.3 + sin(_clock * 9.0) * 0.25
	var leg_spread := 0.0
	match mode:
		&"tell":
			# Dropped low on its front legs, hindquarters up, head down and
			# forward, ruff fanned, jaw open on a growl, tail stiff.
			var u := smoothstep(0.0, 0.5, _mode_time / charge_windup)
			body_tilt = -0.2 * u
			body_low = 0.1 * u
			head_tilt = -0.25 * u
			jaw = 0.4 * u + sin(_clock * 40.0) * 0.05 * u
			ruff = lerpf(-1.35, -0.15, u)
			tail = lerpf(tail, -0.4, u)
			leg_spread = 0.35 * u
		&"charge":
			# A flat-out gallop: stretched long, legs reaching front and back.
			var p := fposmod(_clock * 9.0, 1.0)
			body_tilt = sin(p * TAU) * 0.1
			head_tilt = -0.1
			jaw = 0.35
			ruff = -0.5
			tail = -0.6
			for k in 4:
				var front := k < 2
				_legs[k].rotation.z = (1.0 if front else -1.0) * 0.6 * sin(p * TAU + (0.0 if front else PI)) + (0.3 if front else -0.3)
			_body.rotation.z = body_tilt
			_body.position.y = 0.32 + absf(sin(p * TAU)) * 0.05
			_head.rotation.z = head_tilt
			_jaw.rotation.z = -jaw
			_ruff.rotation.z = ruff
			_tail.rotation.z = tail
			return
		&"skid":
			# Front legs braced out ahead, sliding, head back.
			body_tilt = 0.18
			head_tilt = 0.2
			leg_spread = -0.5
		&"snap":
			head_tilt = -0.15 + sin(_mode_time * 30.0) * 0.1
			jaw = 0.5 if _mode_time < 0.15 else 0.05
		&"stagger":
			# Rolled half over, legs folded, head lolling.
			body_tilt = 0.6
			body_low = 0.12
			head_tilt = 0.4 + sin(_clock * 3.0) * 0.1
			for k in 4:
				_legs[k].rotation.z = 0.9 if k < 2 else 0.6
			_body.rotation.z = body_tilt
			_body.position.y = 0.34 - body_low
			_head.rotation.z = head_tilt
			_ruff.rotation.z = -1.0
			_tail.rotation.z = 0.8
			return
		&"recover":
			# Shaking itself off: the body twists back and forth, fast.
			var shake := sin(_mode_time * 38.0) * maxf(0.0, 1.0 - _mode_time / 0.7)
			_body.rotation.x = shake * 0.25
			head_tilt = shake * 0.2
		&"hurt":
			body_tilt = 0.25
			head_tilt = 0.3
		_:
			if absf(velocity.x) > 0.2:
				_stride = fposmod(_stride + trot_speed * 0.9 / frames_per_second, 1.0)
			trot = sin(_stride * TAU)
	if mode != &"recover":
		_body.rotation.x = 0.0
	for k in 4:
		var front := k < 2
		var diagonal := (k == 0 or k == 3)
		_legs[k].rotation.z = (trot if diagonal else -trot) * 0.45 + (leg_spread if front else -leg_spread * 0.5)
	_body.rotation.z = body_tilt
	_body.position.y = 0.34 - body_low + absf(trot) * 0.02
	_head.rotation.z = head_tilt + sin(_clock * 2.0) * 0.04
	_jaw.rotation.z = -jaw
	_ruff.rotation.z = ruff
	_tail.rotation.z = tail
