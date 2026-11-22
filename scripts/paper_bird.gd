class_name PaperBird
extends PaperCritter
## A paper bird over the rooftops: an origami bird gone dark with ink, its
## beak a sharp fold. It flies a slow loop round its roost, wings beating
## in deep strokes and gliding between. When he is below it and near, it
## stops, rears up with its wings raised and spread and shrieks (the tell),
## then dives at where he stood. Parry the dive and it tumbles down,
## stunned, for a finishing cut; cut it from above and he bounces off it
## (it is something to pogo from), and it is knocked down a little and
## flutters back up. Three cuts tear it apart.

@export_group("Flying")
## Half the width and half the height of its loop round its roost.
@export var loop := Vector2(3.5, 0.8)
## Seconds for one loop.
@export var loop_time := 7.0
## It dives when he is within this far sideways, and below it by up to `reach_down`.
@export var reach_side := 4.5
@export var reach_down := 7.0
@export_group("Attack")
## The tell: how long it rears up before diving.
@export var dive_windup := 0.55
@export var dive_speed := 10.0
@export var dive_time := 0.8
@export var attack_damage := 1
@export var dive_cooldown := 2.2

const INKED := Color(0.34, 0.35, 0.46)
const PALE := Color(0.55, 0.56, 0.64)

var roost := Vector3.ZERO
var _phase := 0.0
var _cooldown := 1.0
var _dive_dir := Vector3.ZERO
var _struck := false
var _beat := 0.0
var _wings: Array[Node3D] = []
var _head: Node3D
var _tail: Node3D


func _ready() -> void:
	max_health = 3
	max_posture = 1
	confetti_count = 26
	super._ready()
	roost = global_position
	_phase = fposmod(global_position.x * 0.37, 1.0)
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.32
	shape.shape = ball
	shape.position.y = 0.2
	add_child(shape)
	_make_touch(Vector3(0.7, 0.5, 1.0), Vector3(0.0, 0.2, 0.0))


func _body_centre() -> Vector3:
	return Vector3(0.0, 0.2, 0.0)


func _build() -> void:
	var seed_value := int(roost.x * 17.0) + 9
	var b := PaperMesh.new(seed_value)
	b.texture_world = false
	b.shade_jitter = 0.2
	# The body: a folded diamond, ridge on top, pale underneath.
	b.color = INKED
	var nose := Vector3(0.26, 0.24, 0.0)
	var rump := Vector3(-0.22, 0.2, 0.0)
	var top := Vector3(0.0, 0.32, 0.0)
	var belly := Vector3(0.02, 0.1, 0.0)
	for side: float in [-1.0, 1.0]:
		var flank := Vector3(0.0, 0.2, side * 0.11)
		b.tri(nose, top, flank, Vector3(0.0, 1.0, side))
		b.tri(top, rump, flank, Vector3(0.0, 1.0, side))
		b.color = PALE
		b.tri(nose, flank, belly, Vector3(0.0, -1.0, side))
		b.tri(flank, rump, belly, Vector3(0.0, -1.0, side))
		b.color = INKED
	_part(_rig, b.build())
	# Neck and head with a long sharp beak, held forward.
	_head = Node3D.new()
	_head.position = Vector3(0.24, 0.25, 0.0)
	_rig.add_child(_head)
	var h := PaperMesh.new(seed_value + 1)
	h.texture_world = false
	h.color = INKED.darkened(0.15)
	h.tri(Vector3(0.0, -0.03, -0.04), Vector3(0.14, 0.12, 0.0), Vector3(0.0, 0.04, 0.04), Vector3.BACK)
	h.tri(Vector3(0.0, -0.03, 0.04), Vector3(0.14, 0.12, 0.0), Vector3(0.0, 0.04, -0.04), Vector3.FORWARD)
	h.color = PaperMesh.SUMI
	h.tri(Vector3(0.12, 0.13, -0.025), Vector3(0.32, 0.07, 0.0), Vector3(0.12, 0.09, 0.025))
	h.color = Color(0.75, 0.72, 0.6)  # a pale eye
	h.box(Vector3(0.13, 0.13, 0.03), Vector3(0.02, 0.02, 0.01))
	_part(_head, h.build())
	# The tail: a long point.
	_tail = Node3D.new()
	_tail.position = Vector3(-0.2, 0.2, 0.0)
	_rig.add_child(_tail)
	var t := PaperMesh.new(seed_value + 2)
	t.texture_world = false
	t.color = INKED.darkened(0.08)
	t.tri(Vector3(0.0, 0.03, -0.05), Vector3(-0.32, 0.1, 0.0), Vector3(0.0, -0.02, 0.05))
	_part(_tail, t.build())
	# Two wings, each a long fold with a crease, hinged at the shoulder.
	for side: float in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(0.04, 0.28, side * 0.08)
		_rig.add_child(wing)
		var w := PaperMesh.new(seed_value + 3 + int(side))
		w.texture_world = false
		w.color = INKED.lightened(0.04)
		w.tri(Vector3(0.12, 0.0, 0.0), Vector3(-0.16, 0.0, 0.0), Vector3(-0.02, 0.02, side * 0.62), Vector3.UP)
		w.color = INKED.darkened(0.2)
		w.tri(Vector3(-0.16, 0.0, 0.0), Vector3(-0.3, 0.0, side * 0.42), Vector3(-0.02, 0.02, side * 0.62), Vector3.UP)
		_part(wing, w.build())
		_wings.append(wing)


func _physics_process(delta: float) -> void:
	_tick(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	match mode:
		&"tell":
			velocity = velocity.move_toward(Vector3.ZERO, 12.0 * delta)
			if _mode_time >= dive_windup:
				_set_mode(&"dive")
				_struck = false
		&"dive":
			velocity = _dive_dir * dive_speed
			if not _struck:
				_strike()
			if _mode_time >= dive_time or is_on_floor() or is_on_wall():
				_set_mode(&"recover")
				_cooldown = dive_cooldown
		&"stagger":
			# Tumbling down, stunned, fluttering weakly on the ground.
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.y = maxf(velocity.y - 20.0 * delta, -8.0)
			if _mode_time >= stagger_time:
				posture = 0
				_set_mode(&"recover")
		&"knocked":
			velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
			if _mode_time >= 0.45:
				_set_mode(&"recover")
		&"recover":
			# Back up to its loop.
			var goal := _loop_point()
			velocity = (goal - global_position).limit_length(1.0) * 4.0
			if global_position.distance_to(goal) < 0.3 or _mode_time > 3.0:
				_set_mode(&"patrol")
		_:
			_phase = fposmod(_phase + delta / loop_time, 1.0)
			var goal := _loop_point()
			velocity = (goal - global_position) * 4.0
			_dir = signf(cos(_phase * TAU)) * -1.0 if absf(cos(_phase * TAU)) > 0.05 else _dir
			if _cooldown <= 0.0:
				_look_for_prey()
	move_and_slide()
	position.z = 0.0
	if mode == &"dive":
		_check_touch()


## Where on its loop it should be now.
func _loop_point() -> Vector3:
	var a := _phase * TAU
	return roost + Vector3(sin(a) * loop.x, sin(a * 2.0) * loop.y, 0.0)


func _look_for_prey() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Ronin
	if player == null:
		return
	var d := player.global_position + Vector3(0.0, 0.8, 0.0) - global_position
	if absf(d.x) < reach_side and d.y < -0.8 and d.y > -reach_down:
		_dir = signf(d.x) if d.x != 0.0 else _dir
		_dive_dir = d.normalized()
		_set_mode(&"tell")
		Sound.play(self, &"bird_shriek")


func _strike() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0.0, 0.2, 0.0) + _dive_dir * 0.3)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_struck = true
			if target.receive_strike(attack_damage, global_position, hurt_kind):
				velocity = Vector3(-_dive_dir.x * 4.0, 2.0, 0.0)
				_on_parried()
			return


func _on_hit(direction: Vector2) -> void:
	if mode == &"stagger":
		return
	# Struck: knocked the way the blade went (down, from a pogo).
	velocity = Vector3(direction.x * 5.0, -4.0 if direction.y < -0.5 else (3.0 if direction.y > 0.5 else 1.0), 0.0)
	_set_mode(&"knocked")
	Sound.play(self, &"bird_shriek", -6.0)


func _pose() -> void:
	_rig.rotation.y = -0.25 if _dir > 0.0 else PI + 0.25
	var flap := 0.0
	var pitch := 0.0
	var head := 0.0
	var tail := 0.0
	match mode:
		&"tell":
			# Reared up, wings raised high and spread, beak open to the sky.
			var u := smoothstep(0.0, 0.4, _mode_time / dive_windup)
			flap = lerpf(0.2, 1.25, u) + sin(_clock * 30.0) * 0.06
			pitch = 0.5 * u
			head = 0.4 * u
			tail = -0.3 * u
		&"dive":
			# Wings folded back, a dart.
			flap = -0.9
			pitch = atan2(_dive_dir.y, absf(_dive_dir.x))
			head = 0.0
			tail = 0.2
		&"stagger":
			flap = sin(_clock * 12.0) * 0.5 - 0.2
			pitch = -0.4 + sin(_clock * 3.0) * 0.1
			head = -0.5
		&"knocked":
			flap = sin(_clock * 25.0) * 0.9
			pitch = -0.3
		_:
			# Deep slow beats, then a glide with the wings held level.
			_beat = fposmod(_beat + 1.0 / frames_per_second / 0.55, 1.0)
			var gliding := fposmod(_clock * 0.25 + roost.x, 1.0) > 0.55
			flap = 0.05 if gliding else sin(_beat * TAU) * 0.85
			pitch = clampf(velocity.y * 0.08, -0.4, 0.4)
			head = sin(_clock * 1.3) * 0.08
	for i in _wings.size():
		var side := -1.0 if i == 0 else 1.0
		_wings[i].rotation.x = -side * flap
	_rig.rotation.z = pitch if _dir > 0.0 else pitch
	_head.rotation.z = head
	_tail.rotation.z = tail
