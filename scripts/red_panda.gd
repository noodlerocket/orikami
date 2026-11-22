class_name RedPanda
extends PaperCritter
## A wild red panda of the Bamboo of Folded Wind, folded from rust-red and
## cream paper, its ringed tail swinging, ink tears running from its eyes
## like the husks'. A Meshy model (models/redpanda.glb, reference
## docs/reference/redpanda_side.png). Meshy cannot rig animals, so its bones
## are made here (ProceduralSkin) and every pose is set by hand, every frame.
##
## It pads back and forth on its short legs, now and then sitting up to look
## round. When it sees him ahead it rears up on its hind legs with its
## forelegs flung up and wide (the red panda's threat stance) and huffs: the
## tell. Then it drops and bounds at him, and close in it springs, claws
## first. Parry the spring (or the charge) and it is thrown back staggered,
## rolled on its side, for a finishing cut. Touching it hurts: it swats.

@export_group("Looks")
## Its size: 1 is the model as made (0.95 m nose to tail tip, 0.28 m tall).
@export var model_scale := 1.05
## How far it turns its face toward us from side-on (radians).
@export var turn_to_camera := 0.3
## How long it takes to turn round (seconds).
@export var turn_time := 0.22
## Rearing up (the tell) it turns this much further toward us (radians),
## so its flung-up forelegs can be seen from the side.
@export var tell_turn := 0.8
@export_group("Hunting")
## How far ahead it sees him (metres), and how far up or down.
@export var sight := 7.0
@export var sight_rise := 1.3
@export var walk_speed := 0.9
@export var patrol_distance := 3.0
## The tell: how long it stands reared up before it drops and charges.
@export var rear_time := 0.65
@export var charge_speed := 8.0
## The longest a charge lasts (seconds).
@export var charge_time := 1.1
## Charging, it springs at him from this far.
@export var pounce_range := 1.7
@export var pounce_speed := 6.5
@export var pounce_lift := 4.2
@export var attack_damage := 1
## Rest after an attack before it can attack again.
@export var attack_cooldown := 1.8
@export var gravity := 30.0
@export_group("Idle")
## Seconds between sitting up to look round, at random between these.
@export var look_every := Vector2(4.0, 8.0)

# Measured from the model (its own units; +Z is its nose, y -0.139 its feet).
const MID := -0.025      # the line down its middle
const FEET := -0.139
const WRIST_Y := -0.112  # a paw's wrist when the paw is flat on the ground
enum { HIPS, SPINE, CHEST, NECK, HEAD, TAIL1, TAIL2, TAIL3, TAIL4, FL, FL_PAW, FR, FR_PAW, BL, BL_PAW, BR, BR_PAW }
const LEGS := [[FL, FL_PAW], [FR, FR_PAW], [BL, BL_PAW], [BR, BR_PAW]]

static var _material: StandardMaterial3D

var _skin: ProceduralSkin
var _model: Node3D
var _cur_turns: Array[Quaternion] = []
var _cur_moves := PackedVector3Array()
var _last_clock := 0.0
var _face := -1.0
var _square_up := 0.0
var _gait := 0.0
var _home_x := 0.0
var _cooldown := 0.0
var _struck := false
var _next_look := 5.0
var _look_length := 1.6
var _rng := RandomNumberGenerator.new()
var _segments: Array = []   # for weighing: [a, b, radius] per bone
var _dust: CPUParticles3D


func _ready() -> void:
	max_health = 3
	max_posture = 1
	confetti_count = 30
	# Its own paper: rust, cream, dark brown.
	confetti_colors = [Color(0.62, 0.24, 0.12), Color(0.85, 0.5, 0.26), Color(0.92, 0.86, 0.74), Color(0.3, 0.17, 0.12)]
	frames_per_second = 240.0  # (posed every frame: smooth, never stepped)
	_rng.seed = int(absf(global_position.x) * 31.0) + 7
	_next_look = _rng.randf_range(look_every.x, look_every.y)
	_face = _dir
	super._ready()
	_home_x = global_position.x
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.75, 0.32, 0.4)
	shape.shape = box
	shape.position.y = 0.16  # (its bottom at its feet)
	add_child(shape)
	_make_touch(Vector3(0.75, 0.36, 1.0), Vector3(0.0, 0.18, 0.0))


func _body_centre() -> Vector3:
	return Vector3(0.0, 0.2, 0.0)


func _build() -> void:
	_model = Node3D.new()
	_rig.add_child(_model)
	_skin = ProceduralSkin.new()
	var s := _skin
	s.add_bone("hips", -1, Vector3(MID, 0.03, 0.02))
	s.add_bone("spine", HIPS, Vector3(MID, 0.04, 0.09))
	s.add_bone("chest", SPINE, Vector3(MID, 0.045, 0.17))
	s.add_bone("neck", CHEST, Vector3(-0.01, 0.045, 0.265))
	s.add_bone("head", NECK, Vector3(0.03, 0.055, 0.335))
	s.add_bone("tail1", HIPS, Vector3(MID, 0.03, -0.07))
	s.add_bone("tail2", TAIL1, Vector3(MID, 0.012, -0.17))
	s.add_bone("tail3", TAIL2, Vector3(MID, -0.004, -0.27))
	s.add_bone("tail4", TAIL3, Vector3(MID, -0.02, -0.37))
	s.add_bone("fl", CHEST, Vector3(-0.105, -0.02, 0.235))
	s.add_bone("fl_paw", FL, Vector3(-0.1, WRIST_Y, 0.255))
	s.add_bone("fr", CHEST, Vector3(0.059, -0.02, 0.235))
	s.add_bone("fr_paw", FR, Vector3(0.055, WRIST_Y, 0.255))
	s.add_bone("bl", HIPS, Vector3(-0.075, -0.02, 0.03))
	s.add_bone("bl_paw", BL, Vector3(-0.077, WRIST_Y, 0.015))
	s.add_bone("br", HIPS, Vector3(0.025, -0.02, 0.03))
	s.add_bone("br_paw", BR, Vector3(0.025, WRIST_Y, 0.012))
	s.finish()
	# Each bone's reach for weighing: a segment and how thick it is.
	_segments = [
		[Vector3(MID, 0.03, -0.05), Vector3(MID, 0.04, 0.09), 0.075],
		[Vector3(MID, 0.04, 0.09), Vector3(MID, 0.045, 0.17), 0.08],
		[Vector3(MID, 0.045, 0.17), Vector3(-0.01, 0.045, 0.265), 0.08],
		[Vector3(-0.01, 0.045, 0.265), Vector3(0.03, 0.055, 0.335), 0.045],
		[Vector3(0.03, 0.055, 0.335), Vector3(0.07, 0.04, 0.42), 0.08],
		[s.heads[TAIL1], s.heads[TAIL2], 0.045],
		[s.heads[TAIL2], s.heads[TAIL3], 0.045],
		[s.heads[TAIL3], s.heads[TAIL4], 0.045],
		[s.heads[TAIL4], Vector3(-0.027, -0.03, -0.475), 0.045],
		[s.heads[FL], s.heads[FL_PAW], 0.03], [s.heads[FL_PAW], Vector3(-0.08, -0.13, 0.33), 0.025],
		[s.heads[FR], s.heads[FR_PAW], 0.03], [s.heads[FR_PAW], Vector3(0.03, -0.13, 0.33), 0.025],
		[s.heads[BL], s.heads[BL_PAW], 0.03], [s.heads[BL_PAW], Vector3(-0.08, -0.13, 0.06), 0.025],
		[s.heads[BR], s.heads[BR_PAW], 0.03], [s.heads[BR_PAW], Vector3(0.027, -0.13, 0.06), 0.025],
	]
	var source: Node3D = (preload("res://models/redpanda.glb") as PackedScene).instantiate()
	var found: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	if _material == null:
		# (The material is taken before the mesh is rebuilt, or it is lost.)
		var made := found.get_active_material(0) as BaseMaterial3D
		_material = StandardMaterial3D.new()
		if made:
			_material.albedo_texture = made.albedo_texture
		_material.albedo_color = Color(0.86, 0.85, 0.85)  # (a little dimmed: the sun washed it out)
		_material.roughness = 1.0
		_material.metallic_specular = 0.2
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := s.skin("red_panda", found.mesh, _material, _weigh)
	source.free()
	_model.add_child(s.skeleton)
	_flash_meshes.append(body)
	for i in s.heads.size():
		_cur_turns.append(Quaternion.IDENTITY)
		_cur_moves.append(Vector3.ZERO)
	_place_model()
	# Leaf litter and dust kicked up when it lands from a spring.
	_dust = CPUParticles3D.new()
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 14
	_dust.lifetime = 0.55
	_dust.explosiveness = 0.85
	_dust.direction = Vector3(0.0, 1.0, 0.0)
	_dust.spread = 60.0
	_dust.gravity = Vector3(0.0, -6.0, 0.0)
	_dust.initial_velocity_min = 0.6
	_dust.initial_velocity_max = 1.6
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.0
	var mote := QuadMesh.new()
	mote.size = Vector2(0.05, 0.05)
	mote.material = PaperMesh.soft_ink(Color(0.55, 0.5, 0.36, 0.55))
	_dust.mesh = mote
	_dust.position = Vector3(0.0, 0.03, 0.0)
	add_child(_dust)


## How much each bone holds a vertex: near its segment (measured from the
## surface of a capsule round it), with a few borders so the head, the tail
## and the legs do not pull on the body.
func _weigh(p: Vector3) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_segments.size())
	for b in _segments.size():
		var seg: Array = _segments[b]
		var d := maxf(ProceduralSkin.to_segment(p, seg[0], seg[1]) - (seg[2] as float), 0.0) + 0.004
		var w := 1.0 / (d * d * d * d)
		match b:
			HIPS:
				w *= ProceduralSkin.ramp(-0.16, -0.08, p.z)
			SPINE, CHEST:
				w *= ProceduralSkin.ramp(0.33, 0.27, p.z)
			HEAD:
				w *= ProceduralSkin.ramp(0.25, 0.31, p.z)
			TAIL1, TAIL2, TAIL3, TAIL4:
				w *= ProceduralSkin.ramp(-0.03, -0.09, p.z)
			FL, FL_PAW, FR, FR_PAW, BL, BL_PAW, BR, BR_PAW:
				w *= ProceduralSkin.ramp(0.0, -0.05, p.y)
		out[b] = w
	return out


func _physics_process(delta: float) -> void:
	_tick(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta
	match mode:
		&"tell":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= rear_time:
				_set_mode(&"charge")
				_struck = false
		&"charge":
			# It drops onto all fours and bounds at him.
			velocity.x = _dir * charge_speed * smoothstep(0.0, 0.15, _mode_time)
			if not _struck:
				_strike(0.45)
			var ahead := _distance_ahead()
			if is_on_floor() and _mode_time > 0.12 and ahead > -0.2 and ahead < pounce_range and not _struck:
				_set_mode(&"pounce")
				velocity = Vector3(_dir * pounce_speed, pounce_lift, 0.0)
				Sound.play(self, &"panda_huff", -4.0)
			elif _mode_time >= charge_time or (is_on_floor() and (_wall_ahead() or _edge_ahead(0.6))):
				_set_mode(&"land")
		&"pounce":
			if not _struck:
				_strike(0.5)
			if (_mode_time > 0.15 and is_on_floor()) or _mode_time > 1.2:
				_set_mode(&"land")
				_dust.restart()
				Sound.play(self, &"land", -6.0)
		&"land":
			velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
			if _mode_time >= 0.4:
				_set_mode(&"recover")
				_cooldown = attack_cooldown
		&"recover", &"stagger", &"hurt", &"look":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			var wait := {&"recover": 0.8, &"stagger": stagger_time, &"hurt": 0.35, &"look": _look_length}[mode] as float
			if mode == &"look" and _cooldown <= 0.0 and _player_ahead(sight, 2.5, sight_rise):
				_start_tell()
			elif _mode_time >= wait:
				if mode == &"stagger":
					posture = 0
				_set_mode(&"patrol")
		&"snap":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= 0.35:
				_set_mode(&"patrol")
		_:
			if is_on_floor() and (_wall_ahead() or _edge_ahead(0.6) or (global_position.x - _home_x) * _dir > patrol_distance):
				_dir = -_dir
			velocity.x = _dir * walk_speed
			_next_look -= delta
			if _cooldown <= 0.0 and is_on_floor() and _player_ahead(sight, 2.0, sight_rise):
				_start_tell()
			elif _next_look <= 0.0 and is_on_floor():
				_next_look = _rng.randf_range(look_every.x, look_every.y)
				_look_length = _rng.randf_range(1.3, 2.2)
				_set_mode(&"look")
	move_and_slide()
	position.z = 0.0
	if mode in [&"patrol", &"look", &"recover"]:
		for body: Node3D in _touch.get_overlapping_bodies():
			if body.has_method("take_damage") and body.take_damage(contact_damage, global_position):
				_dir = signf(body.global_position.x - global_position.x)
				_set_mode(&"snap")
				Sound.play(self, &"panda_huff", -8.0)


func _start_tell() -> void:
	_set_mode(&"tell")
	Sound.play(self, &"panda_huff")


## How far ahead of it he is (negative: behind), or far away if he is not on
## its level.
func _distance_ahead() -> float:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null or absf(player.global_position.y - global_position.y) > sight_rise:
		return 99.0
	return (player.global_position.x - global_position.x) * _dir


## Its teeth and claws reaching him: an attack (it can be parried).
func _strike(reach: float) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 0.7, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * reach, 0.35, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_struck = true
			if target.receive_strike(attack_damage, global_position):
				velocity = Vector3(-_dir * 6.5, 3.5, 0.0)
				_on_parried()
			return


func _on_hit(direction: Vector2) -> void:
	velocity.x = direction.x * knockback_speed
	if direction.y < -0.5:
		velocity.y = -2.0
	if mode != &"stagger":
		_set_mode(&"hurt")
		Sound.play(self, &"panda_squeal")


# --- Posing --------------------------------------------------------------------

## Its whole body: on the ground, turned side-on (a little toward us), and
## mirrored when it faces right so its turned head always looks our way.
func _place_model() -> void:
	var yaw := _face * (PI * 0.5 - turn_to_camera - _square_up)
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * model_scale), Vector3(0.0, -FEET * model_scale, 0.0))
	if _face > 0.0:
		xf = xf * Transform3D(Basis.from_scale(Vector3(-1.0, 1.0, 1.0)), Vector3(2.0 * MID, 0.0, 0.0))
	_model.transform = xf


func _pose() -> void:
	var dt := _clock - _last_clock
	_last_clock = _clock
	var jump := dt <= 0.0 or dt > 0.25  # (set directly, as by a frame sheet)
	_face = float(_dir) if jump else move_toward(_face, _dir, dt * 2.0 / turn_time)
	var square := tell_turn * smoothstep(0.0, 0.3, _mode_time) if mode == &"tell" else 0.0
	_square_up = square if jump else lerpf(_square_up, square, 1.0 - exp(-12.0 * dt))
	_place_model()
	var s := _skin
	for i in s.heads.size():
		s.turns[i] = Quaternion.IDENTITY
		s.moves[i] = Vector3.ZERO
	var rate := 14.0
	var t := _mode_time
	var k := _clock
	# While it turns round it looks straight ahead, so the mirroring halfway
	# through cannot be seen.
	var straight := 1.0 - smoothstep(0.0, 0.7, absf(_face))
	match mode:
		&"tell":
			# Up on its hind legs, forelegs flung up and wide, claws out,
			# head toward him; it bounces a little on its hind feet.
			var u := smoothstep(0.0, 0.28, t)
			var pump := sin(t * 14.0) * smoothstep(0.25, 0.4, t)
			_body(-1.08 * u, 0.0, -0.035 * u + pump * 0.004)
			_spine_bend(-0.12 * u)
			_head(-0.66 * u - 0.66 * straight, 0.05 + pump * 0.04, sin(t * 9.0) * 0.06 * u)
			for side in 2:
				var sx := -1.0 if side == 0 else 1.0
				var wide := Vector3(sx * 0.6, 0.78 + pump * 0.1, 0.25).normalized()
				var down := _rest_dir(FL if side == 0 else FR)
				_aim_leg(LEGS[side], down.slerp(wide, u), 1.3 * u)
			_plant_leg(LEGS[2], 1.0)
			_plant_leg(LEGS[3], 1.0)
			_tail(0.12 + 0.1 * u, sin(k * 2.0) * 0.15, 0.55 * u)
			rate = 22.0
		&"charge":
			# Bounding: front feet together, back feet together, the back
			# arching and stretching.
			_gait += maxf(dt, 0.0) * 5.5
			var p := _gait * TAU
			_body(0.1 * sin(p), 0.0, 0.03 * maxf(0.0, sin(p + 0.6)))
			_spine_bend(0.12 * cos(p))
			_head(-0.5 - 0.66 * straight, 0.12 - 0.08 * sin(p), 0.0)
			for leg in 4:
				var front := leg < 2
				var phase := p + (0.35 if leg % 2 == 1 else 0.0)
				var a := (-0.95 * sin(phase)) if front else (0.95 * sin(phase))
				var lift := maxf(0.0, cos(phase) if front else -cos(phase))
				_swing_leg(LEGS[leg], a, -0.6 * lift)
			_tail(0.3, sin(p * 0.5) * 0.12, 0.1)
			rate = 30.0
		&"pounce":
			# Springing, claws reaching high, then raking down.
			var r := smoothstep(0.05, 0.25, t)
			_body(lerpf(-0.5, 0.15, r), 0.0, 0.0)
			_spine_bend(lerpf(-0.1, 0.1, r))
			_head(-0.55 - 0.66 * straight, lerpf(-0.15, 0.25, r), 0.0)
			for side in 2:
				var sx := -1.0 if side == 0 else 1.0
				var high := Vector3(sx * 0.25, 0.6, 0.8).normalized()
				var low := Vector3(sx * 0.2, -0.75, 0.55).normalized()
				_aim_leg(LEGS[side], high.slerp(low, r), 1.0)
			_swing_leg(LEGS[2], 0.9, 0.6)
			_swing_leg(LEGS[3], 0.9, 0.6)
			_tail(0.35, 0.0, 0.2)
			rate = 30.0
		&"land":
			# Landed in a crouch, front feet braced forward, sliding.
			var c := 1.0 - smoothstep(0.15, 0.4, t)
			_body(0.12 * c, 0.0, -0.02 * c)
			_head(-0.3 - 0.66 * straight, 0.1, 0.0)
			_plant_leg(LEGS[0], 1.0)
			_plant_leg(LEGS[1], 1.0)
			_plant_leg(LEGS[2], -1.0)
			_plant_leg(LEGS[3], -1.0)
			_tail(0.1, sin(k * 3.0) * 0.2, 0.0)
		&"recover":
			# Shakes its head, flicks its tail.
			var shake := sin(t * 32.0) * maxf(0.0, 1.0 - t / 0.55)
			_body(0.0, shake * 0.08, 0.0)
			_head(-0.66 * straight, 0.0, shake * 0.4)
			_stand()
			_tail(0.15 + shake * 0.1, shake * 0.4, 0.0)
		&"look":
			# Sits up on its haunches, forepaws hanging at its chest, and
			# looks round.
			var u := smoothstep(0.0, 0.35, t) * (1.0 - smoothstep(_look_length - 0.3, _look_length, t))
			_body(-0.62 * u, 0.0, -0.025 * u)
			_spine_bend(-0.06 * u)
			_head((-0.25 + sin(t * 2.2) * 0.45) * u - 0.66 * straight, 0.12 * u, sin(t * 1.7) * 0.12 * u)
			for side in 2:
				var sx := -1.0 if side == 0 else 1.0
				var hang := Vector3(sx * 0.08, -0.8, 0.5).normalized()
				_aim_leg(LEGS[side], _rest_dir(FL if side == 0 else FR).slerp(hang, u), 0.7 * u)
			_plant_leg(LEGS[2], 1.0)
			_plant_leg(LEGS[3], 1.0)
			_tail(0.08, sin(k * 1.1) * 0.25, 0.25 * u)
			rate = 10.0
		&"snap":
			# A swat with the near forepaw.
			var sw := smoothstep(0.0, 0.14, t)
			var up := 1.0 - smoothstep(0.2, 0.35, t)
			_body(-0.35 * up, 0.0, 0.0)
			_head(-0.4 - 0.66 * straight, 0.1, 0.0)
			_aim_leg(LEGS[1], Vector3(0.2, 0.5, 0.8).normalized().slerp(Vector3(0.2, -0.7, 0.6).normalized(), sw), 1.0)
			_plant_leg(LEGS[0], 1.0)
			_plant_leg(LEGS[2], 1.0)
			_plant_leg(LEGS[3], 1.0)
			_tail(0.2, 0.0, 0.3)
			rate = 30.0
		&"hurt":
			# Flinches back, head thrown up.
			var f := 1.0 - smoothstep(0.1, 0.35, t)
			_body(0.18 * f, 0.0, 0.0)
			s.moves[HIPS] += Vector3(0.0, 0.0, -0.03 * f)
			_head(-0.66 * straight, -0.35 * f, 0.2 * f)
			_plant_leg(LEGS[0], 1.0)
			_plant_leg(LEGS[1], 1.0)
			_plant_leg(LEGS[2], -1.0)
			_plant_leg(LEGS[3], -1.0)
			_tail(0.25 * f, 0.0, 0.0)
			rate = 30.0
		&"stagger":
			# Rolled over onto its back, belly up toward us, legs limp in the
			# air and twitching, head lolling.
			var twitch := sin(k * 5.0) * 0.12
			_body(0.0, 1.85, -0.05)
			_head(0.2, -0.1, 1.0 + sin(k * 2.2) * 0.2)
			for leg in 4:
				s.turns[LEGS[leg][0]] = Quaternion(Vector3.RIGHT, (-0.45 if leg < 2 else 0.45) + twitch * (1.0 if leg % 2 == 0 else -1.0))
				s.turns[LEGS[leg][1]] = Quaternion(Vector3.RIGHT, 1.0)
			s.turn_globally(TAIL1, Basis(Vector3.UP, sin(k * 1.5) * 0.15) * Basis(Vector3.RIGHT, 0.05))
		_:
			# Padding along: a quick diagonal walk, the tail swinging.
			if absf(velocity.x) > 0.1:
				_gait += maxf(dt, 0.0) * absf(velocity.x) / (0.2 * model_scale)
			var p := _gait * TAU
			var moving := clampf(absf(velocity.x) / maxf(walk_speed, 0.1), 0.0, 1.0)
			_body(0.0, sin(p) * 0.03 * moving, absf(sin(p)) * 0.004 * moving)
			_head(-0.66 * straight + sin(k * 0.7) * 0.1, 0.08 + sin(p * 2.0) * 0.03 * moving, 0.0)
			for leg in 4:
				var diagonal := leg == 0 or leg == 3
				var phase := p + (0.0 if diagonal else PI)
				# (Stepping, the toe lifts: the paw never dips into the ground.)
				_swing_leg(LEGS[leg], 0.55 * sin(phase) * moving, -maxf(0.0, -cos(phase)) * 0.5 * moving)
			_tail(0.06 + sin(k * 1.3) * 0.04, sin(p * 0.5) * 0.25 * moving + sin(k * 1.1) * 0.12, 0.0)
	# Ease from the pose it is in toward this one (snappy for strikes).
	var a := 1.0 if jump else 1.0 - exp(-rate * dt)
	for i in s.heads.size():
		_cur_turns[i] = _cur_turns[i].slerp(s.turns[i], a)
		_cur_moves[i] = _cur_moves[i].lerp(s.moves[i], a)
		s.turns[i] = _cur_turns[i]
		s.moves[i] = _cur_moves[i]
	s.apply()


## The body: pitch (negative lifts the nose: rearing), roll (onto its side),
## and how far the hips rise or sink.
func _body(pitch: float, roll: float, rise: float) -> void:
	_skin.turns[HIPS] = Quaternion(Vector3.BACK, roll) * Quaternion(Vector3.RIGHT, pitch)
	_skin.moves[HIPS] = Vector3(0.0, rise, 0.0)


## Arches (positive) or straightens the back.
func _spine_bend(bend: float) -> void:
	_skin.turns[SPINE] = Quaternion(Vector3.RIGHT, bend * 0.5)
	_skin.turns[CHEST] = Quaternion(Vector3.RIGHT, bend * 0.5)


## The head, turned in model space: yaw (negative: toward its nose's way,
## from its modelled turn toward us), pitch (positive: nose down), roll. The
## neck takes half.
func _head(yaw: float, pitch: float, roll: float) -> void:
	var s := _skin
	var want := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, roll)
	var chest := s.global_of(CHEST).basis.orthonormalized()
	s.turn_globally(NECK, chest.slerp(want, 0.5))
	s.turn_globally(HEAD, want)


## The tail: lifted (positive up, in model space), swung side to side
## (a wave running down it), curled up at its tip.
func _tail(lift: float, sway: float, curl: float) -> void:
	var s := _skin
	s.turn_globally(TAIL1, Basis(Vector3.UP, sway * 0.5) * Basis(Vector3.RIGHT, lift))
	var k := _clock
	for n in 3:
		var wave := sin(k * 2.6 - float(n + 1) * 0.9) * 0.12 + sway * 0.25
		s.turns[TAIL2 + n] = Quaternion(Vector3.UP, wave) * Quaternion(Vector3.RIGHT, curl * (0.4 + 0.3 * n))


func _rest_dir(upper: int) -> Vector3:
	return (_skin.heads[upper + 1] - _skin.heads[upper]).normalized()


## A leg swung forward or back (in model space; positive is back) with its
## paw turned by `curl` (0 is flat on the ground, negative lifts the toe,
## positive curls the claws under).
func _swing_leg(leg: Array, angle: float, curl: float) -> void:
	var g := Basis(Vector3.RIGHT, angle)
	_skin.turn_globally(leg[0], g)
	_skin.turn_globally(leg[1], Basis(Vector3.RIGHT, curl))


## A leg pointed along `direction` (model space), paw curled by `curl`.
func _aim_leg(leg: Array, direction: Vector3, curl: float) -> void:
	var from := _rest_dir(leg[0])
	var g := Basis(Quaternion(from, direction.normalized())) if from.dot(direction.normalized()) > -0.999 else Basis(Vector3.RIGHT, PI)
	_skin.turn_globally(leg[0], g)
	_skin.turn_globally(leg[1], g * Basis(Vector3.RIGHT, curl))


## A leg whose paw stays flat on the ground wherever the body is: the leg
## swings to whichever angle puts its wrist at paw height, `prefer` 1 with the
## paw ahead of the hip, -1 behind.
func _plant_leg(leg: Array, prefer: float) -> void:
	var s := _skin
	var upper: int = leg[0]
	var hip := s.point_on(s.parents[upper], s.heads[upper])
	var r: Vector3 = s.heads[leg[1]] - s.heads[upper]
	var reach := Vector2(r.y, r.z).length()
	var phi := atan2(r.z, r.y)
	var c := clampf((WRIST_Y - hip.y) / reach, -1.0, 1.0)
	var best := 0.0
	var best_score := -INF
	for sign_a: float in [1.0, -1.0]:
		var a := wrapf(sign_a * acos(c) - phi, -PI, PI)
		var z := r.y * sin(a) + r.z * cos(a)
		var score := z * prefer - absf(a) * 0.01
		if score > best_score:
			best_score = score
			best = a
	s.turn_globally(upper, Basis(Vector3.RIGHT, best))
	s.turn_globally(leg[1], Basis.IDENTITY)


## Standing square on all four feet.
func _stand() -> void:
	for leg in 4:
		_plant_leg(LEGS[leg], 1.0 if leg < 2 else -1.0)
