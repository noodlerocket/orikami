class_name KiteHusk
extends PaperCritter
## A haunted paper kite over the Bamboo of Folded Wind: a torn washi kite on
## a bamboo frame, ink soaking up from its hem, a husk's blank mask on it with
## one weeping ink eye, and two long thin clawed paper arms hanging from its
## lower corners. A Meshy model (models/kitehusk.glb, reference
## docs/reference/kitehusk_front.png), given bones here (ProceduralSkin) and
## posed by hand every frame. Its tail is two long torn paper streamers tied
## under its hem, waving in the wind.
##
## It rides the wind near its roost, bobbing and tilting with the gusts,
## drifting back and forth. When he comes near it rears back, its sail bowing
## forward like a hood, its arms flung up and wide, the eye weeping ink, the
## paper rattling: the tell. Then it swoops at him raking with its claws.
## Parried, it tumbles down like a falling leaf, stunned (a finishing cut);
## cut from above, he bounces off it (it can be pogo'd), and it is knocked
## aside and drifts back. Three cuts tear it apart.

@export_group("Looks")
## Its size: 1 is the model as made (0.95 m tall with its arms).
@export var model_scale := 1.8
## The streamers under its hem, each this long (metres).
@export var streamer_length := 1.3
@export_group("Flying")
## Half the width and half the height of its slow drift round its roost.
@export var drift := Vector2(2.2, 0.45)
## Seconds for one drift round.
@export var drift_time := 9.0
## How far a gust pushes it downwind (metres per metre-per-second of wind).
@export var wind_push := 0.08
## It swoops when he is within this far sideways, and below it by up to
## `reach_down` (or a little above).
@export var reach_side := 5.0
@export var reach_down := 6.0
@export_group("Attack")
## The tell: how long it rears back before it swoops.
@export var swoop_windup := 0.6
@export var swoop_speed := 9.0
@export var swoop_time := 0.75
@export var attack_damage := 1
@export var swoop_cooldown := 2.4

# Measured from the model (its own units; it faces +Z).
const SAIL_MIDDLE := Vector3(0.0, 0.1, 0.0)
const EYE := Vector3(0.042, 0.235, 0.1)
const KNOT := Vector3(0.0, -0.12, -0.012)  # (behind the hem, so the tops are tucked up under it)
enum { ROOT, SIDE_L, SIDE_R, HEM, ARM_L, FORE_L, HAND_L, ARM_R, FORE_R, HAND_R, STREAMERS }
const SEGMENTS := 8

static var _material: StandardMaterial3D

var roost := Vector3.ZERO
var _skin: ProceduralSkin
var _model: Node3D
var _phase := 0.0
var _cooldown := 1.0
var _dive_dir := Vector3.ZERO
var _struck := false
var _face := 0.0
var _last_clock := 0.0
var _arm_swing := 0.0
var _hit_side := 1.0
var _rattle_wait := 3.0
var _weep_wait := 2.0
var _weep_burst := 0.0
var _trail := 0.0
var _tears: CPUParticles3D
var _cur_turns: Array[Quaternion] = []
var _cur_moves := PackedVector3Array()


func _ready() -> void:
	max_health = 3
	max_posture = 1
	confetti_count = 34
	# Its own paper: washi, grey, ink-soaked.
	confetti_colors = [PaperMesh.WASHI, Color(0.72, 0.74, 0.72), Color(0.32, 0.33, 0.34), Color(0.1, 0.1, 0.12)]
	stagger_time = 2.0
	frames_per_second = 240.0  # (posed every frame: smooth, never stepped)
	super._ready()
	roost = global_position
	_phase = fposmod(global_position.x * 0.29, 1.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.72, 1.15, 0.5)
	shape.shape = box
	add_child(shape)
	_make_touch(Vector3(0.9, 1.7, 1.0), Vector3(0.0, -0.35, 0.0))
	_seal.position = Vector3(-0.2, -0.32, 0.25)


func _body_centre() -> Vector3:
	return Vector3.ZERO


func _build() -> void:
	_model = Node3D.new()
	_model.scale = Vector3.ONE * model_scale
	_model.position = -SAIL_MIDDLE * model_scale
	_rig.add_child(_model)
	_skin = ProceduralSkin.new()
	var s := _skin
	s.add_bone("root", -1, SAIL_MIDDLE)
	s.add_bone("side_l", ROOT, Vector3(-0.1, 0.1, 0.0))
	s.add_bone("side_r", ROOT, Vector3(0.1, 0.1, 0.0))
	s.add_bone("hem", ROOT, Vector3(0.0, -0.06, 0.0))
	for side: float in [-1.0, 1.0]:
		var top := s.add_bone("arm", SIDE_L if side < 0.0 else SIDE_R, Vector3(side * 0.165, -0.215, -0.065))
		s.add_bone("fore", top, Vector3(side * 0.165, -0.335, -0.075))
		s.add_bone("hand", top + 1, Vector3(side * 0.16, -0.415, -0.085))
	var seg := streamer_length / model_scale / SEGMENTS
	for n in 2:
		var parent := HEM
		for j in SEGMENTS:
			parent = s.add_bone("tail%d_%d" % [n, j], parent, _streamer_top(n) + Vector3(0.0, -seg * j, 0.0))
	s.finish()
	var source: Node3D = (preload("res://models/kitehusk.glb") as PackedScene).instantiate()
	var found: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	if _material == null:
		# (The material is taken before the mesh is rebuilt, or it is lost.)
		var made := found.get_active_material(0) as BaseMaterial3D
		_material = StandardMaterial3D.new()
		if made:
			_material.albedo_texture = made.albedo_texture
		_material.albedo_color = Color(0.84, 0.84, 0.86)  # (a little dimmed: the sun washed it out)
		_material.roughness = 1.0
		_material.metallic_specular = 0.2
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flash_meshes.append(s.skin("kite_husk", found.mesh, _material, _weigh))
	source.free()
	for n in 2:
		var strip := _streamer_mesh(n, seg)
		var paper := strip.material_override
		_flash_meshes.append(s.skin("kite_streamer_%d_%.2f" % [n, streamer_length], strip.mesh, paper, _weigh_streamer.bind(n, seg)))
		strip.free()
	_model.add_child(s.skeleton)
	for i in s.heads.size():
		_cur_turns.append(Quaternion.IDENTITY)
		_cur_moves.append(Vector3.ZERO)
	# Ink weeping from its one eye.
	_tears = CPUParticles3D.new()
	_tears.emitting = false
	_tears.amount = 12
	_tears.lifetime = 1.0
	_tears.local_coords = false
	_tears.direction = Vector3(0.0, -1.0, 0.0)
	_tears.spread = 8.0
	_tears.gravity = Vector3(0.0, -5.0, 0.0)
	_tears.initial_velocity_min = 0.05
	_tears.initial_velocity_max = 0.3
	_tears.scale_amount_min = 0.5
	_tears.scale_amount_max = 1.0
	var drop := QuadMesh.new()
	drop.size = Vector2(0.045, 0.06)
	drop.material = PaperMesh.soft_ink(PaperMesh.SUMI)
	_tears.mesh = drop
	s.skeleton.add_child(_tears)


func _streamer_top(n: int) -> Vector3:
	return KNOT + Vector3(-0.008 if n == 0 else 0.008, 0.0, -0.004 if n == 0 else -0.02)


## One streamer: a long strip of torn washi, narrowing, grey ink soaked into
## its lower end and torn into a fork at the tip. The first also carries the
## cord knot that ties both under the hem.
func _streamer_mesh(n: int, seg: float) -> MeshInstance3D:
	var m := PaperMesh.new(71 + n * 13)
	m.texture_world = false
	m.shade_jitter = 0.06
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + n
	var top := _streamer_top(n)
	var length := seg * SEGMENTS
	var rows := 26
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for r in rows + 1:
		var f := float(r) / rows
		var half := lerpf(0.03, 0.019, f) + rng.randf_range(-0.004, 0.004)
		var lean := sin(f * 5.0 + n * 2.0) * 0.004
		var y := top.y - length * f
		left.append(Vector3(top.x - half + lean, y, top.z))
		right.append(Vector3(top.x + half + lean, y, top.z))
	# The fork at the tip.
	left[rows] += Vector3(-0.006, -0.02, 0.0)
	right[rows] += Vector3(0.006, -0.012, 0.0)
	var washi := Color(0.74, 0.74, 0.72)
	var ink := Color(0.24, 0.25, 0.3)
	for r in rows:
		var f := (r + 0.5) / rows
		var soak := smoothstep(0.55, 0.95, f + rng.randf_range(-0.06, 0.06))
		m.color = washi.lerp(ink, soak)
		if r == rows - 1:
			var mid := (left[r] + right[r]) * 0.5
			var low := (left[rows] + right[rows]) * 0.5 + Vector3(0.0, 0.035, 0.0)
			m.tri(left[r], mid, left[rows], Vector3.BACK)
			m.tri(mid, right[r], right[rows], Vector3.BACK)
			m.tri(mid, low, left[rows], Vector3.BACK)
			m.tri(mid, right[rows], low, Vector3.BACK)
		else:
			m.quad(left[r], right[r], right[r + 1], left[r + 1], Vector3.BACK)
	if n == 0:
		# The cord knot round both streamers' tops.
		m.color = Color(0.28, 0.22, 0.16)
		m.box(KNOT + Vector3(0.0, -0.008, -0.012), Vector3(0.05, 0.014, 0.03))
		m.box(KNOT + Vector3(0.0, 0.004, -0.012), Vector3(0.012, 0.016, 0.012))
	return m.build()


## How much each bone holds a vertex of the kite: the mask is rigid on the
## frame; the sail's sides bow from just outside the mask; the hem flutters;
## the arms hang from the lower corners in three pieces.
func _weigh(p: Vector3) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_skin.heads.size())
	var ax := absf(p.x)
	var side := SIDE_L if p.x < 0.0 else SIDE_R
	var arm := ARM_L if p.x < 0.0 else ARM_R
	var on_arm := p.y < -0.2 and ((ax > 0.105 and (ax < 0.195 or p.y < -0.26)) or (p.y < -0.36 and ax > 0.075))
	if on_arm:
		var held := ProceduralSkin.ramp(-0.205, -0.245, p.y)
		var fore := ProceduralSkin.ramp(-0.315, -0.35, p.y)
		var hand := ProceduralSkin.ramp(-0.4, -0.425, p.y)
		out[arm] = held * (1.0 - fore)
		out[arm + 1] = held * fore * (1.0 - hand)
		out[arm + 2] = held * fore * hand
		out[side] = 1.0 - held
		return out
	if p.z > 0.03 and p.y > 0.03 and p.y < 0.39 and ax < 0.11:
		out[ROOT] = 1.0
		return out
	var bow := ProceduralSkin.ramp(0.1, 0.19, ax)
	var hem := ProceduralSkin.ramp(-0.02, -0.2, p.y)
	out[side] = bow
	out[HEM] = hem * (1.0 - bow)
	out[ROOT] = (1.0 - bow) * (1.0 - hem)
	return out


## A streamer's vertex follows the segments nearest it along the strip.
func _weigh_streamer(p: Vector3, n: int, seg: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_skin.heads.size())
	var along := (_streamer_top(n).y - p.y) / seg
	var first := STREAMERS + n * SEGMENTS
	for j in SEGMENTS:
		out[first + j] = maxf(0.0, 1.0 - absf(along - (j + 0.5)))
	if along < 0.5:
		out[first] = 1.0
	if along > SEGMENTS - 0.5:
		out[first + SEGMENTS - 1] = 1.0
	return out


func _physics_process(delta: float) -> void:
	_tick(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	match mode:
		&"tell":
			velocity = velocity.move_toward(Vector3(0.0, 0.6, 0.0), 10.0 * delta)
			if _mode_time >= swoop_windup:
				_set_mode(&"dive")
				_struck = false
				_aim()
				Sound.play(self, &"dash", -5.0)
		&"dive":
			velocity = _dive_dir * swoop_speed * (0.55 + 0.45 * smoothstep(0.0, 0.2, _mode_time))
			if not _struck:
				_strike()
			if _mode_time >= swoop_time or is_on_floor() or is_on_wall():
				_set_mode(&"recover")
				_cooldown = swoop_cooldown
		&"stagger":
			# Tumbling down like a falling leaf, stunned.
			velocity.x = move_toward(velocity.x, sin(_mode_time * 2.2) * 1.2, 6.0 * delta)
			velocity.y = maxf(velocity.y - 9.0 * delta, -2.0)
			if is_on_floor():
				velocity.y = 0.0
			if _mode_time >= stagger_time:
				posture = 0
				_set_mode(&"recover")
		&"knocked":
			velocity = velocity.move_toward(Vector3.ZERO, 9.0 * delta)
			if _mode_time >= 0.5:
				_set_mode(&"recover")
		&"recover":
			# Back up to its drift on the wind, swooping.
			var goal := _drift_point()
			velocity = velocity.move_toward((goal - global_position).limit_length(1.0) * 4.0, 14.0 * delta)
			if global_position.distance_to(goal) < 0.35 or _mode_time > 3.5:
				_set_mode(&"patrol")
		_:
			_phase = fposmod(_phase + delta / drift_time, 1.0)
			velocity = (_drift_point() - global_position) * 3.0
			if _cooldown <= 0.0:
				_look_for_prey()
			# Strong gusts make it rattle now and then.
			_rattle_wait -= delta
			if _rattle_wait <= 0.0 and Wind.speed_at(global_position.x) > Wind.breeze + Wind.gusts * 0.7:
				_rattle_wait = randf_range(5.0, 9.0)
				Sound.play(self, &"kite_rattle", -9.0)
	move_and_slide()
	position.z = 0.0
	# Touching it in the swoop hurts too, but only once its claws (which can
	# be parried) have had their chance.
	if mode == &"dive" and _struck:
		_check_touch()


## Where on its drift it should be now: round its roost, bobbing, and pushed
## downwind by the gusts.
func _drift_point() -> Vector3:
	var a := _phase * TAU
	var t := Wind.now()
	var push := Wind.at(global_position.x).x * wind_push
	return roost + Vector3(sin(a) * drift.x + push, sin(a * 2.0) * drift.y + sin(t * 1.3 + roost.x) * 0.12, 0.0)


func _look_for_prey() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return
	var d := player.global_position - global_position
	if absf(d.x) < reach_side and d.y < 0.6 and d.y > -reach_down:
		_dir = signf(d.x) if d.x != 0.0 else _dir
		_set_mode(&"tell")
		Sound.play(self, &"kite_rattle", -6.0)
		Sound.play(self, &"kite_wail")


## Swoops so its claws, hanging below, rake through where he is.
func _aim() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		_dive_dir = Vector3(_dir, -1.0, 0.0).normalized()
		return
	var goal := player.global_position + Vector3(-_dir * 0.2, 1.35, 0.0)
	_dive_dir = (goal - global_position).normalized()
	if _dive_dir.length() < 0.5:
		_dive_dir = Vector3(_dir, -0.5, 0.0).normalized()
	_dir = signf(_dive_dir.x) if absf(_dive_dir.x) > 0.05 else _dir


## The claws reaching him: an attack (it can be parried).
func _strike() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 1.1, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * 0.45, -0.6, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_struck = true
			if target.receive_strike(attack_damage, global_position):
				velocity = Vector3(-_dir * 4.0, 2.5, 0.0)
				_on_parried()
			return


func _on_hit(direction: Vector2) -> void:
	if mode == &"stagger":
		return
	# Struck: knocked the way the blade went (down, from a pogo).
	_hit_side = signf(direction.x) if direction.x != 0.0 else -_dir
	velocity = Vector3(direction.x * 4.5, -3.5 if direction.y < -0.5 else (2.5 if direction.y > 0.5 else 0.8), 0.0)
	_set_mode(&"knocked")
	Sound.play(self, &"paper_rip", -9.0)


# --- Posing --------------------------------------------------------------------

func _pose() -> void:
	var dt := _clock - _last_clock
	_last_clock = _clock
	var jump := dt <= 0.0 or dt > 0.25  # (set directly, as by a frame sheet)
	var s := _skin
	for i in s.heads.size():
		s.turns[i] = Quaternion.IDENTITY
		s.moves[i] = Vector3.ZERO
	var t := _mode_time
	var k := _clock + roost.x
	var wind := Wind.at(global_position.x).x
	var gust := clampf((absf(wind) - Wind.breeze) / maxf(Wind.gusts, 0.1), 0.0, 1.0)
	# It turns a little toward where it is going (always facing us).
	var heading := _dir if mode in [&"tell", &"dive"] else signf(velocity.x) if absf(velocity.x) > 0.3 else 0.0
	_face = heading if jump else move_toward(_face, heading, dt * 2.0)
	_model.rotation.y = _face * 0.22
	var roll := 0.0       # positive tilts its top to the left
	var pitch := 0.0      # positive tips its top toward us
	var rise := 0.0
	var bow := sin(k * 6.5) * (0.04 + 0.08 * gust)  # the sail's sides breathing in the wind
	var hem_swing := clampf((wind - velocity.x) * 0.04, -0.4, 0.4) + sin(k * 7.3) * (0.05 + 0.08 * gust)
	var hem_flap := sin(k * 9.1 + 1.0) * (0.06 + 0.1 * gust)
	var arms_out := 0.0   # 0 hanging, 1 flung up and wide
	var reach := 0.0      # arm angle toward its prey when swooping
	var claws := 0.15 + sin(k * 2.3) * 0.08
	var rate := 10.0
	# Its arms swing behind its motion, slowly, like weighted paper.
	var swing_goal := clampf((wind * 0.25 - velocity.x) * 0.1, -0.6, 0.6)
	_arm_swing = swing_goal if jump else lerpf(_arm_swing, swing_goal, 1.0 - exp(-2.5 * dt))
	var weeping := false
	match mode:
		&"tell":
			# Rears back away from him, rising, sail bowed forward like a
			# hood, arms flung up and wide, the eye weeping ink.
			var u := smoothstep(0.0, 0.35, t)
			var shiver := sin(t * 38.0) * 0.03 * u
			roll = _dir * 0.32 * u + shiver
			pitch = -0.3 * u
			rise = 0.05 * u
			bow = 0.38 * u + shiver * 2.0
			arms_out = u
			claws = 0.7 * u
			weeping = true
			rate = 18.0
		&"dive":
			# Swooping, leaning back, claws reaching ahead then raking down
			# through him.
			var r := smoothstep(0.05, swoop_time * 0.85, t)
			roll = _dir * lerpf(0.45, 0.15, r)
			pitch = 0.25
			bow = 0.25
			reach = _dir * lerpf(1.7, -0.5, r)
			claws = lerpf(0.9, 0.3, r)
			weeping = true
			rate = 24.0
		&"stagger":
			# Tumbling like a falling leaf, crumpled, arms flailing.
			var fall := 1.0 - smoothstep(0.0, 0.4, t) * (0.4 if is_on_floor() else 0.0)
			roll = sin(t * 2.2) * 0.9 * fall + (0.5 if is_on_floor() else 0.0)
			pitch = 0.35 + sin(t * 3.1) * 0.25
			bow = 0.5
			_arm_swing = sin(t * 4.0) * 0.6
			claws = 0.9
		&"knocked":
			var f := 1.0 - smoothstep(0.0, 0.5, t)
			roll = -_hit_side * 0.8 * f + sin(t * 20.0) * 0.1 * f
			bow = -0.2 * f
			_arm_swing = -_hit_side * 0.8 * f
			rate = 24.0
		&"recover":
			roll = clampf(-velocity.x * 0.06, -0.4, 0.4)
		_:
			roll = clampf(-velocity.x * 0.08, -0.35, 0.35) + sin(k * 0.9) * 0.1 + wind * 0.02
			pitch = sin(k * 1.4) * 0.08
	s.turns[ROOT] = Quaternion(Vector3.BACK, roll) * Quaternion(Vector3.RIGHT, pitch)
	s.moves[ROOT] = Vector3(0.0, rise, 0.0)
	s.turns[SIDE_L] = Quaternion(Vector3.UP, bow)
	s.turns[SIDE_R] = Quaternion(Vector3.UP, -bow)
	s.turns[HEM] = Quaternion(Vector3.BACK, hem_swing * 0.5) * Quaternion(Vector3.RIGHT, hem_flap)
	# The arms, in model space (0 is hanging straight down; positive turns
	# the hand toward +x).
	for side in 2:
		var sx := -1.0 if side == 0 else 1.0
		var top := ARM_L if side == 0 else ARM_R
		var sway := sin(k * 1.7 + side * 1.3) * 0.08
		var hang := _arm_swing + sway
		var flung := sx * 1.95 + sin(t * 9.0 + side) * 0.06
		var angle := lerpf(hang, flung, arms_out)
		if reach != 0.0:
			angle = reach + sx * 0.18
		var elbow := lerpf(0.05, -sx * 0.7, arms_out) + sin(k * 2.1 + side) * 0.05
		s.turn_globally(top, Basis(Vector3.BACK, angle))
		s.turn_globally(top + 1, Basis(Vector3.BACK, angle + elbow))
		s.turn_globally(top + 2, Basis(Vector3.BACK, angle + elbow * 1.3) * Basis(Vector3.RIGHT, -claws))
	# Ease toward this pose; the streamers follow the air every frame.
	var a := 1.0 if jump else 1.0 - exp(-rate * dt)
	for i in STREAMERS:
		_cur_turns[i] = _cur_turns[i].slerp(s.turns[i], a)
		_cur_moves[i] = _cur_moves[i].lerp(s.moves[i], a)
		s.turns[i] = _cur_turns[i]
		s.moves[i] = _cur_moves[i]
	var trail := clampf(atan2(wind - velocity.x, 4.0) * 0.95, -1.35, 1.35)
	_trail = trail if jump else lerpf(_trail, trail, 1.0 - exp(-4.0 * dt))
	_pose_streamers(wind, gust)
	s.apply()
	# The eye weeps: steadily in the tell and the swoop, a drop now and then
	# otherwise.
	_tears.position = s.point_on(ROOT, EYE)
	_weep_wait -= maxf(dt, 0.0)
	_weep_burst -= maxf(dt, 0.0)
	if _weep_wait <= 0.0:
		_weep_wait = randf_range(2.5, 4.5)
		_weep_burst = 0.2
	_tears.emitting = weeping or _weep_burst > 0.0


## Each streamer hangs on the air flowing past it (the wind, less the kite's
## own motion) and waves along its length, a wave running down to its tip.
func _pose_streamers(wind: float, gust: float) -> void:
	var s := _skin
	var flow := wind - velocity.x
	var trail := _trail
	var k := Wind.now() + roost.x * 0.3
	var amplitude := 0.14 + 0.16 * gust + clampf(absf(flow) * 0.02, 0.0, 0.2)
	for n in 2:
		var first := STREAMERS + n * SEGMENTS
		for j in SEGMENTS:
			var f := float(j) / (SEGMENTS - 1)
			var wave := sin(k * (5.2 + n * 0.7) - j * 0.75 + n * 1.9) * amplitude * (0.25 + 0.75 * f)
			var twist := sin(k * 3.1 - j * 0.6 + n * 2.4) * 0.45 * (0.3 + 0.7 * f)
			var angle := trail * (0.55 + 0.45 * f) + wave + (n - 0.5) * 0.22 * f
			s.turn_globally(first + j, Basis(Vector3.BACK, angle) * Basis(Vector3.UP, twist))
