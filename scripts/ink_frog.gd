class_name InkFrog
extends PaperCritter
## The ink frog (sumi-gaeru) of Sumi Marsh: a folded origami frog soaked
## black, pale-bellied, green at its creases (a Meshy model, picture
## docs/reference/inkfrog_side.png; image 01a20c5e-1704-74f9-bbc9-99aad839b7a1,
## model 01a20c62-a8fc-7095-b0e1-227b41f01376, meshy-t2.5 8,000 + meshy-n1).
## Unrigged: bones are given here (ProceduralSkin) and every pose is set by
## hand.
##
## It sits on banks and pads, croaking (its throat swells). When he comes
## near on its level it turns to him; its tell: it rocks back on its coiled
## hind legs, throat swelling, eye glinting. Then it leaps at him in a long
## arc, legs kicked out behind (a bite: parry it), and lands in a splat of
## ink. Pogo off it. Parried, it flips onto its back, legs kicking:
## staggered, a cut finishes it. It keeps to its own patch of ground (never
## leaps into deep ink).

@export_group("Hunting")
@export var sight := 6.5
@export var sight_rise := 2.0
## The tell (s), the leap's time in the air (s) and its longest reach (m).
@export var leap_windup := 0.55
@export var leap_time := 0.75
@export var leap_reach := 5.0
## How far from home it will go (m).
@export var home_range := 4.0
@export var rest_time := 1.4
@export var attack_damage := 1
@export var gravity := 22.0
## The model's size in the game (1 = Meshy's 0.6 m tall).
@export var model_scale := 1.3

enum { BODY, HEAD, FL, FR, HL, HR, HL_FOOT, HR_FOOT }

static var _material: StandardMaterial3D
var _skin: ProceduralSkin
var _model: Node3D
var _segments: Array = []
var _home_x := 0.0
var _bit := false
var _croak := 0.0
var _swell := 0.0
var _ronin: Ronin


func _ready() -> void:
	max_health = 2
	max_posture = 1
	stagger_time = 1.8
	confetti_count = 28
	confetti_colors = [Color(0.06, 0.06, 0.07), Color(0.7, 0.72, 0.72), Color(0.3, 0.42, 0.28)]
	super._ready()
	_home_x = global_position.x
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.6, 0.6)
	shape.shape = box
	shape.position.y = 0.3
	add_child(shape)
	_make_touch(Vector3(0.9, 0.6, 1.0), Vector3(0.0, 0.3, 0.0))
	_croak = randf_range(1.0, 4.0)


func _body_centre() -> Vector3:
	return Vector3(0.0, 0.35, 0.0)


func _build() -> void:
	_model = Node3D.new()
	_rig.add_child(_model)
	var s := ProceduralSkin.new()
	_skin = s
	s.add_bone("body", -1, Vector3(0.0, 0.0, -0.05))
	s.add_bone("head", BODY, Vector3(0.0, 0.08, 0.18))
	s.add_bone("fl", BODY, Vector3(-0.18, -0.06, 0.22))
	s.add_bone("fr", BODY, Vector3(0.18, -0.06, 0.22))
	s.add_bone("hl", BODY, Vector3(-0.22, -0.04, -0.22))
	s.add_bone("hr", BODY, Vector3(0.22, -0.04, -0.22))
	s.add_bone("hl_foot", HL, Vector3(-0.42, -0.12, 0.0))
	s.add_bone("hr_foot", HR, Vector3(0.42, -0.12, 0.0))
	s.finish()
	_segments = [
		[Vector3(0.0, 0.0, -0.32), Vector3(0.0, 0.04, 0.14), 0.2],
		[Vector3(0.0, 0.1, 0.2), Vector3(0.0, 0.1, 0.42), 0.14],
		[Vector3(-0.18, -0.06, 0.22), Vector3(-0.28, -0.29, 0.38), 0.05],
		[Vector3(0.18, -0.06, 0.22), Vector3(0.28, -0.29, 0.38), 0.05],
		[Vector3(-0.22, -0.04, -0.22), Vector3(-0.42, -0.12, 0.0), 0.09],
		[Vector3(0.22, -0.04, -0.22), Vector3(0.42, -0.12, 0.0), 0.09],
		[Vector3(-0.42, -0.12, 0.0), Vector3(-0.3, -0.29, 0.12), 0.06],
		[Vector3(0.42, -0.12, 0.0), Vector3(0.3, -0.29, 0.12), 0.06],
	]
	var source: Node3D = (preload("res://models/inkfrog.glb") as PackedScene).instantiate()
	var found: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	if _material == null:
		var made := found.get_active_material(0) as BaseMaterial3D
		_material = StandardMaterial3D.new()
		if made:
			_material.albedo_texture = made.albedo_texture
		_material.roughness = 0.45   # (wet ink: a little gloss)
		_material.metallic_specular = 0.6
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := s.skin("ink_frog", found.mesh, _material, _weigh)
	source.free()
	_model.add_child(s.skeleton)
	_flash_meshes.append(body)
	_model.scale = Vector3.ONE * model_scale
	_model.position.y = 0.3 * model_scale


func _weigh(p: Vector3) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_segments.size())
	for b in _segments.size():
		var seg: Array = _segments[b]
		var d := maxf(ProceduralSkin.to_segment(p, seg[0], seg[1]) - (seg[2] as float), 0.0) + 0.004
		var w := 1.0 / (d * d * d * d)
		match b:
			HEAD:
				w *= ProceduralSkin.ramp(0.1, 0.18, p.z) * ProceduralSkin.ramp(-0.12, -0.04, p.y)
			FL, FR:
				w *= ProceduralSkin.ramp(-0.04, -0.1, p.y) * ProceduralSkin.ramp(0.1, 0.16, p.z) * ProceduralSkin.ramp(0.06, 0.12, absf(p.x))
			HL, HR, HL_FOOT, HR_FOOT:
				w *= ProceduralSkin.ramp(0.16, 0.24, absf(p.x)) if p.y > -0.15 else ProceduralSkin.ramp(0.08, 0.14, absf(p.x))
				w *= ProceduralSkin.ramp(0.2, 0.12, p.z)
		if (b == FL or b == HL or b == HL_FOOT) and p.x > 0.0:
			w = 0.0
		if (b == FR or b == HR or b == HR_FOOT) and p.x < 0.0:
			w = 0.0
		out[b] = w
	return out


func _physics_process(delta: float) -> void:
	_tick(delta)
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	if not is_on_floor():
		velocity.y -= gravity * delta
	match mode:
		&"tell":
			velocity.x = 0.0
			if _mode_time >= leap_windup:
				_leap()
		&"leap":
			if not _bit and _mode_time > 0.08:
				_bite()
			if is_on_floor() and _mode_time > 0.15:
				velocity.x = 0.0
				_set_mode(&"land")
				WaterFx.splash(get_parent(), global_position, 0.6, true)
				Sound.play(self, &"frog_splat", -4.0)
		&"land":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time >= 0.35:
				_set_mode(&"recover")
		&"recover", &"hurt":
			velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
			if _mode_time >= (rest_time if mode == &"recover" else 0.35):
				_set_mode(&"patrol")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
			if _mode_time >= stagger_time:
				posture = 0
				_set_mode(&"recover")
		_:
			velocity.x = 0.0
			_croak -= delta
			if _croak <= 0.0:
				_croak = randf_range(3.0, 6.0)
				_swell = 1.0
				Sound.play(self, &"frog_croak", -10.0)
			if is_on_floor() and _player_ahead(sight, sight, sight_rise):
				_set_mode(&"tell")
				_swell = 1.0
				Sound.play(self, &"frog_croak", -2.0)
	_swell = move_toward(_swell, 0.0, delta * 1.6)
	move_and_slide()
	position.z = 0.0
	if mode == &"patrol" or mode == &"recover":
		_check_touch()


## Where it lands: at him, but no further than it can leap, no further
## from home than it keeps, and never into deep ink.
func _leap() -> void:
	var target := _ronin.global_position.x if _ronin else global_position.x + _dir * 3.0
	var marsh := get_parent() as Node3D
	var dx := clampf(target - global_position.x, -leap_reach, leap_reach)
	var to := clampf(global_position.x + dx, _home_x - home_range, _home_x + home_range)
	var local := marsh.to_local(Vector3(to, 0.0, 0.0)).x
	var tries := 0
	while SumiMarsh.kind_at(local) == "deep" and tries < 20:
		local += 0.4 * signf(marsh.to_local(Vector3(_home_x, 0.0, 0.0)).x - local)
		tries += 1
	to = marsh.to_global(Vector3(local, 0.0, 0.0)).x
	var rise := ((_ronin.global_position.y if _ronin else global_position.y) - global_position.y) + 0.3
	velocity.x = (to - global_position.x) / leap_time
	velocity.y = (rise + 0.5 * gravity * leap_time * leap_time) / leap_time
	velocity.y = clampf(velocity.y, 5.0, 13.0)
	_dir = signf(velocity.x) if absf(velocity.x) > 0.1 else _dir
	_bit = false
	_set_mode(&"leap")
	Sound.play(self, &"frog_leap", -2.0)


func _bite() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 0.8, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * 0.4, 0.35, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_bit = true
			if target.receive_strike(attack_damage, global_position, hurt_kind):
				velocity = Vector3(-_dir * 4.0, 4.0, 0.0)
				_on_parried()
			return


func _on_hit(direction: Vector2) -> void:
	velocity.x = direction.x * knockback_speed * 0.7
	if direction.y < -0.5:
		velocity.y = -2.0
	if mode != &"stagger":
		_set_mode(&"hurt")
		Sound.play(self, &"frog_croak", -4.0)


func _pose() -> void:
	_rig.rotation.y = (PI * 0.5 - 0.35) if _dir > 0.0 else (-PI * 0.5 + 0.35)
	var s := _skin
	for i in s.heads.size():
		s.turns[i] = Quaternion.IDENTITY
		s.moves[i] = Vector3.ZERO
	var pitch := 0.0
	var low := 0.0
	var head := 0.0
	var hind := 0.0     # >0 legs kicked out behind
	var fore := 0.0
	var swell := _swell
	match mode:
		&"tell":
			var u := smoothstep(0.0, 1.0, _mode_time / leap_windup)
			pitch = -0.3 * u
			low = 0.08 * u
			head = -0.2 * u
			hind = -0.35 * u
			swell = 1.0
		&"leap":
			var vy := velocity.y
			pitch = clampf(vy * 0.06, -0.6, 0.5)
			hind = 1.2
			fore = -0.7
			head = -0.15
		&"land":
			low = 0.1 * (1.0 - _mode_time / 0.35)
			hind = -0.2
			fore = 0.3
		&"stagger":
			_rig.rotation.z = PI
			hind = 0.6 + 0.5 * sin(_clock * 14.0)
			fore = 0.4 * sin(_clock * 11.0 + 1.0)
			_model.position.y = 0.55 * model_scale
		&"hurt":
			pitch = 0.25
		_:
			head = 0.04 * sin(_clock * 0.9)
	if mode != &"stagger":
		_rig.rotation.z = 0.0
		_model.position.y = 0.3 * model_scale - low
	s.turns[BODY] = Quaternion(Vector3.RIGHT, pitch)
	s.turns[HEAD] = Quaternion(Vector3.RIGHT, head - swell * 0.06)
	s.moves[HEAD] = Vector3(0.0, swell * 0.015, swell * 0.01)
	s.turns[FL] = Quaternion(Vector3.RIGHT, fore)
	s.turns[FR] = Quaternion(Vector3.RIGHT, fore)
	# Hind legs: kicked straight out behind (positive) or coiled tighter.
	s.turns[HL] = Quaternion(Vector3.UP, -hind * 0.9) * Quaternion(Vector3.RIGHT, hind * 0.4)
	s.turns[HR] = Quaternion(Vector3.UP, hind * 0.9) * Quaternion(Vector3.RIGHT, hind * 0.4)
	s.turns[HL_FOOT] = Quaternion(Vector3.UP, -hind * 0.6)
	s.turns[HR_FOOT] = Quaternion(Vector3.UP, hind * 0.6)
	s.apply()
	# The throat swelling: the whole frog breathes up a little.
	_model.scale = Vector3(model_scale * (1.0 + swell * 0.05), model_scale * (1.0 + swell * 0.04), model_scale)
