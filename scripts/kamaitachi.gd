class_name Kamaitachi
extends PaperCritter
## The kamaitachi of Koinobori Skies (docs/koinobori_skies_plan.md): a
## sickle-weasel folded from stiff grey-white paper, its forelegs two long
## curved blades, riding a whirl of paper scraps on the wind. It drifts in
## a loose loop high over its patch of sky. When he comes near, its tell: a
## thin whistle, and a curl of scraps gathering in the air where it will
## come from (it gathers itself there, coiled). Then it streaks past him in
## a straight line, blades out (a cut: parry it), and swings back up into
## the wind. Parried, it tumbles, staggered. The Shuriken Dash's spin cuts
## it. Folded in code, posed by hand.

@export_group("Hunting")
## How near he must come (m).
@export var sight := 8.0
## The tell (s), the pass's speed (m/s) and length (m).
@export var tell_time := 0.75
@export var pass_speed := 15.0
@export var pass_length := 9.0
@export var attack_damage := 1
@export var rest_time := 2.0
## Its loop in the sky round where it was put (m).
@export var roam := Vector2(5.0, 1.4)

const PAPER := Color(0.82, 0.82, 0.8)
const PAPER_DARK := Color(0.5, 0.5, 0.52)
const BLADE := Color(0.72, 0.76, 0.8)

var _home := Vector3.ZERO
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _struck := false
var _ronin: Ronin
var _body: Node3D
var _head: Node3D
var _tail: Node3D
var _blades: Array[Node3D] = []
var _whirl: CPUParticles3D
var _phase := 0.0


func _ready() -> void:
	max_health = 2
	max_posture = 1
	stagger_time = 1.6
	confetti_count = 26
	confetti_colors = [PAPER, PAPER_DARK, BLADE]
	super._ready()
	_home = global_position
	_phase = randf() * TAU
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.5, 0.6)
	shape.shape = box
	add_child(shape)
	_make_touch(Vector3(0.8, 0.5, 1.0), Vector3.ZERO)


func _body_centre() -> Vector3:
	return Vector3.ZERO


func _build() -> void:
	var seed_value := int(global_position.x * 11.0) + 3
	_body = Node3D.new()
	_rig.add_child(_body)
	var b := PaperMesh.new(seed_value)
	b.texture_world = false
	b.shade_jitter = 0.18
	b.color = PAPER
	b.loft([PaperCritter.ring_x(Vector3(-0.35, 0.0, 0.0), Vector2(0.08, 0.08), 5), PaperCritter.ring_x(Vector3(-0.1, 0.02, 0.0), Vector2(0.13, 0.12), 5),
			PaperCritter.ring_x(Vector3(0.18, 0.03, 0.0), Vector2(0.12, 0.11), 5), PaperCritter.ring_x(Vector3(0.3, 0.05, 0.0), Vector2(0.07, 0.07), 5)])
	b.color = PAPER_DARK
	b.box(Vector3(0.0, 0.11, 0.0), Vector3(0.5, 0.02, 0.08))   # a dark stripe down its back
	_part(_body, b.build())
	_head = Node3D.new()
	_head.position = Vector3(0.34, 0.07, 0.0)
	_body.add_child(_head)
	var h := PaperMesh.new(seed_value + 1)
	h.texture_world = false
	h.color = PAPER
	h.loft([PaperCritter.ring_x(Vector3(0.0, 0.0, 0.0), Vector2(0.08, 0.08), 5), PaperCritter.ring_x(Vector3(0.16, -0.01, 0.0), Vector2(0.03, 0.04), 5)])
	for side: float in [-1.0, 1.0]:
		h.color = PAPER_DARK
		h.tri(Vector3(0.0, 0.06, side * 0.04), Vector3(0.04, 0.06, side * 0.08), Vector3(-0.02, 0.16, side * 0.06), Vector3(0.0, 0.0, side))
		h.color = Color(0.1, 0.08, 0.08)
		h.box(Vector3(0.09, 0.03, side * 0.06), Vector3(0.04, 0.015, 0.01))
	h.color = PaperMesh.VERMILION.darkened(0.3)
	h.box(Vector3(0.12, -0.02, 0.0), Vector3(0.05, 0.008, 0.04))
	_part(_head, h.build())
	# The blades: long curved sickles for forelegs.
	for side: float in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(0.18, -0.05, side * 0.08)
		_body.add_child(arm)
		var a := PaperMesh.new(seed_value + 4 + int(side))
		a.texture_world = false
		a.color = PAPER_DARK
		a.box(Vector3(0.02, -0.08, 0.0), Vector3(0.05, 0.16, 0.05))
		a.color = BLADE
		var pts := PackedVector2Array()
		for k in 8:
			var t := float(k) / 7.0
			pts.append(Vector2(0.05 + 0.5 * t, -0.16 - 0.35 * sin(t * 2.2)))
		for k in 8:
			var t := 1.0 - float(k) / 7.0
			pts.append(Vector2(0.05 + 0.5 * t, -0.16 - 0.35 * sin(t * 2.2) + 0.05 * (1.0 - t)))
		a.polygon(pts, 0.0)
		_part(arm, a.build())
		_blades.append(arm)
	_tail = Node3D.new()
	_tail.position = Vector3(-0.35, 0.0, 0.0)
	_body.add_child(_tail)
	var t2 := PaperMesh.new(seed_value + 9)
	t2.texture_world = false
	t2.color = PAPER
	t2.polygon(PackedVector2Array([Vector2(0.0, 0.05), Vector2(-0.6, 0.18), Vector2(-0.75, 0.05), Vector2(-0.55, -0.03), Vector2(0.0, -0.05)]), 0.0)
	_part(_tail, t2.build())
	# The whirl of paper scraps it rides.
	_whirl = CPUParticles3D.new()
	_whirl.amount = 24
	_whirl.lifetime = 0.9
	_whirl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_whirl.emission_sphere_radius = 0.4
	_whirl.orbit_velocity_min = 0.8
	_whirl.orbit_velocity_max = 1.4
	_whirl.gravity = Vector3.ZERO
	_whirl.angle_max = 360.0
	_whirl.angular_velocity_min = -400.0
	_whirl.angular_velocity_max = 400.0
	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.07, 0.05)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.92, 0.9, 0.84)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	scrap.material = look
	_whirl.mesh = scrap
	_whirl.position = Vector3(0.0, -0.25, 0.0)
	add_child(_whirl)


func _physics_process(delta: float) -> void:
	_tick(delta)
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var him := _ronin.global_position + Vector3(0.0, 1.0, 0.0)
	match mode:
		&"tell":
			# Coiled where it will come from, the scraps curling tighter.
			global_position = global_position.lerp(_from, 1.0 - exp(-delta * 6.0))
			_whirl.speed_scale = 2.0
			if _mode_time >= tell_time:
				_to = _from + (him - _from).normalized() * pass_length
				_dir = signf(_to.x - _from.x)
				_struck = false
				_set_mode(&"pass")
				Sound.play(self, &"kamaitachi_pass", 0.0)
		&"pass":
			var step := (_to - _from).normalized() * pass_speed * delta
			global_position += step
			if not _struck:
				_slash()
			if global_position.distance_to(_from) >= pass_length:
				_set_mode(&"recover")
		&"stagger":
			global_position.y -= 0.6 * delta
			if _mode_time >= stagger_time:
				posture = 0
				_set_mode(&"recover")
		&"hurt":
			if _mode_time >= 0.3:
				_set_mode(&"recover")
		&"recover":
			# Back up into the wind, to its loop.
			global_position = global_position.lerp(_loop_point(), 1.0 - exp(-delta * 1.5))
			_whirl.speed_scale = 1.0
			if _mode_time >= rest_time:
				_set_mode(&"patrol")
		_:
			global_position = global_position.lerp(_loop_point(), 1.0 - exp(-delta * 2.0))
			var d := him - global_position
			if d.length() < sight and not _ronin.is_in_pit():
				# Gather beside him, up and to one side, and whistle.
				var side := -1.0 if d.x < 0.0 else 1.0
				_from = him + Vector3(-side * 4.5, 2.2, 0.0)
				_dir = side
				_set_mode(&"tell")
				Sound.play(self, &"kamaitachi_whistle", 0.0)
	position.z = 0.0


func _loop_point() -> Vector3:
	var t := _clock * 0.5 + _phase
	return _home + Vector3(cos(t) * roam.x, sin(t * 2.0) * roam.y, 0.0)


func _slash() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_struck = true
			if target.receive_strike(attack_damage, global_position, hurt_kind):
				Sound.play(self, &"parry", -4.0)
				_on_parried()
			return


func _on_parried() -> void:
	posture += 1
	_set_mode(&"stagger")
	Sound.play(self, &"stagger")


func _on_hit(_direction: Vector2) -> void:
	if mode != &"stagger":
		_set_mode(&"hurt")


func gusted(direction: Vector3, _from_point: Vector3) -> void:
	global_position += Vector3(signf(direction.x) * 2.0, 0.5, 0.0)
	if mode != &"stagger":
		_set_mode(&"recover")
	Sound.play(self, &"paper_fold", -4.0)


func _pose() -> void:
	_rig.rotation.y = -0.25 if _dir > 0.0 else PI + 0.25
	var stretch := 0.0
	var blades := 0.3
	var coil := 0.0
	match mode:
		&"tell":
			coil = smoothstep(0.0, 1.0, _mode_time / tell_time)
			blades = lerpf(0.3, -0.9, coil)   # drawn back
		&"pass":
			stretch = 1.0
			blades = 1.1                       # swept forward
		&"stagger":
			_rig.rotation.z = _clock * 9.0     # tumbling
			return
		_:
			blades = 0.3 + 0.15 * sin(_clock * 5.0)
	_rig.rotation.z = -0.25 * stretch
	_body.scale = Vector3(1.0 + 0.25 * stretch - 0.15 * coil, 1.0 + 0.1 * coil, 1.0)
	for i in _blades.size():
		_blades[i].rotation.z = blades + 0.08 * sin(_clock * 11.0 + i)
	_head.rotation.z = 0.1 * sin(_clock * 3.0) - 0.2 * coil
	_tail.rotation.z = 0.35 * sin(_clock * 7.0) + 0.4 * coil
