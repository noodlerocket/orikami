class_name KitsuneStatue
extends PaperCritter
## A stone fox of the Thousand Gates that wakes (docs/thousand_gates_plan.md).
## A Meshy model (models/kitsune_statue.glb, picture
## docs/reference/kitsune_statue_side.png; image
## 01a20dbe-6e77-748c-abc4-4c311a95abfa, model
## 01a20dbe-e5a2-732e-a066-87ae901d7e5f, meshy-t2.5 7,000 + meshy-n1),
## unrigged: three bones are given here (ProceduralSkin) and every pose is
## set by hand. Stone moves stiffly: the whole fox tips and hops, only its
## head and tail bend.
##
## It sits on its plinth beside the path like every other fox, its eyes
## carved shut. When he comes near, its tell: its eyes kindle red, the stone
## shudders and sheds grit. Then it leaps down at him. Awake, it stalks him
## in stiff hops; its tell: it crouches, eyes flaring; then it lunges and
## bites (parry it: the stone cracks and it is stunned). Cuts hurt it only
## once it is awake (asleep it is stone, nothing to cut).

@export_group("Waking")
## How near he must come for it to wake (m), and how long its eyes kindle (s).
@export var wake_range := 7.0
@export var kindle_time := 0.9
@export_group("Hunting")
@export var stalk_speed := 2.4
## How near it stalks before it crouches to lunge (m).
@export var lunge_range := 3.4
@export var lunge_windup := 0.5
@export var lunge_speed := 9.0
@export var attack_damage := 1
@export var rest_time := 0.9
@export var gravity := 24.0
## Its height in the game (m).
@export var model_height := 1.3

## Where its plinth stands behind the path (z), and the plinth's top (local y,
## above the path under it).
var plinth_z := -1.1
var plinth_height := 0.7

const EYE := Color(1.0, 0.32, 0.16)
const STONE_TINT := Color(0.86, 0.86, 0.84)
enum { BODY, HEAD, TAIL }

static var _material: StandardMaterial3D
var _skin: ProceduralSkin
var _model: Node3D
var _segments: Array = []
var _eyes: Array[MeshInstance3D] = []
var _eye_glow := 0.0
var _hop := 0.0
var _bit := false
var _ronin: Ronin
var _ground_y := 0.0
var _out := 0.0      # 0 on its plinth, 1 on the path
var _lift := 0.0     # how far it rose for the leap


func _ready() -> void:
	max_health = 4
	max_posture = 1
	stagger_time = 1.6
	confetti_count = 30
	confetti_colors = [Color(0.55, 0.56, 0.55), Color(0.42, 0.44, 0.42), Color(0.7, 0.22, 0.16)]
	super._ready()
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.9, 0.6)
	shape.shape = box
	shape.position.y = 0.45
	add_child(shape)
	_make_touch(Vector3(0.8, 0.9, 1.0), Vector3(0.0, 0.45, 0.0))
	_ground_y = global_position.y
	# Asleep: up on its plinth, stone, nothing to cut.
	global_position.y = _ground_y + plinth_height
	collision_layer = 0
	_set_mode(&"asleep")
	_build_plinth()


func _body_centre() -> Vector3:
	return Vector3(0.0, 0.5, 0.0)


func _build() -> void:
	_model = Node3D.new()
	_rig.add_child(_model)
	var s := ProceduralSkin.new()
	_skin = s
	s.add_bone("body", -1, Vector3(0.0, -0.3, 0.0))
	s.add_bone("head", BODY, Vector3(0.0, 0.05, 0.12))
	s.add_bone("tail", BODY, Vector3(0.0, -0.32, -0.22))
	s.finish()
	_segments = [
		[Vector3(0.0, -0.4, -0.1), Vector3(0.0, 0.0, 0.1), 0.18],
		[Vector3(0.0, 0.1, 0.14), Vector3(0.0, 0.25, 0.34), 0.1],
		[Vector3(0.0, -0.3, -0.3), Vector3(0.0, 0.2, -0.34), 0.08],
	]
	var source: Node3D = (preload("res://models/kitsune_statue.glb") as PackedScene).instantiate()
	var found: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	if _material == null:
		_material = KitsuneStatue.stone_material(found)
	var body := s.skin("kitsune_statue", found.mesh, _material, _weigh)
	source.free()
	_model.add_child(s.skeleton)
	_flash_meshes.append(body)
	var grow := model_height / 0.952
	_model.scale = Vector3.ONE * grow
	_model.position.y = 0.476 * grow
	# Its eyes: carved shut, until they kindle.
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.022
		m.height = 0.03
		m.radial_segments = 8
		m.rings = 4
		eye.mesh = m
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.albedo_color = EYE
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		eye.material_override = look
		eye.set_meta(&"side", side)
		_model.add_child(eye)
		_eyes.append(eye)


## The stone of every fox statue (the waking ones and the still ones).
static func stone_material(found: MeshInstance3D) -> StandardMaterial3D:
	var made := found.get_active_material(0) as BaseMaterial3D
	var mat := StandardMaterial3D.new()
	if made:
		mat.albedo_texture = made.albedo_texture
	mat.albedo_color = STONE_TINT
	mat.roughness = 1.0
	mat.metallic_specular = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## A fox statue that never wakes (the ones by the tunnels' mouths): the same
## stone fox, on its plinth.
static func still(at: Vector3, facing: float, height := 1.1) -> Node3D:
	var root := Node3D.new()
	root.position = at
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 13.0)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.12
	MarshKit.masonry(b, Vector3(0.0, 0.35, 0.0), Vector3(0.8, 0.7, 0.6), rng, Color(0.5, 0.5, 0.5), false)
	root.add_child(b.build())
	var source: Node3D = (preload("res://models/kitsune_statue.glb") as PackedScene).instantiate()
	var found: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	var fox := MeshInstance3D.new()
	fox.mesh = found.mesh
	fox.material_override = stone_material(found)
	source.free()
	var grow := height / 0.952
	fox.scale = Vector3.ONE * grow
	fox.position.y = 0.7 + 0.476 * grow
	fox.rotation.y = PI * 0.5 - 0.35 if facing > 0.0 else -PI * 0.5 + 0.35
	root.add_child(fox)
	return root


func _build_plinth() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 7.0)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.12
	MarshKit.masonry(b, Vector3(0.0, plinth_height * 0.5, 0.0), Vector3(0.9, plinth_height, 0.7), rng, Color(0.5, 0.5, 0.5), false)
	var plinth := b.build()
	# (Left behind in the world when it leaps down.)
	plinth.position = Vector3(global_position.x, _ground_y, plinth_z)
	get_parent().add_child.call_deferred(plinth)
	plinth.top_level = true


func _weigh(p: Vector3) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_segments.size())
	for b in _segments.size():
		var seg: Array = _segments[b]
		var d := maxf(ProceduralSkin.to_segment(p, seg[0], seg[1]) - (seg[2] as float), 0.0) + 0.004
		var w := 1.0 / (d * d * d * d)
		match b:
			HEAD:
				w *= ProceduralSkin.ramp(0.04, 0.12, p.z) * ProceduralSkin.ramp(0.0, 0.1, p.y)
			TAIL:
				w *= ProceduralSkin.ramp(-0.18, -0.26, p.z)
		out[b] = w
	return out


func _physics_process(delta: float) -> void:
	_tick(delta)
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var him := _ronin.global_position
	match mode:
		&"asleep":
			velocity = Vector3.ZERO
			if absf(him.x - global_position.x) < wake_range and absf(him.y - _ground_y) < 3.0 and not _ronin.is_in_pit():
				_dir = signf(him.x - global_position.x) if absf(him.x - global_position.x) > 0.1 else _dir
				_set_mode(&"kindle")
				Sound.play(self, &"stone_grind", 0.0)
			return
		&"kindle":
			_eye_glow = smoothstep(0.0, 1.0, _mode_time / kindle_time)
			if _mode_time >= kindle_time:
				_leap_down(him)
			return
		&"leap":
			_out = clampf(_mode_time / 0.55, 0.0, 1.0)
			velocity.y -= gravity * delta
			if not _bit and _mode_time > 0.15:
				_bite()
			if is_on_floor() and _mode_time > 0.12:
				_land()
		&"stalk":
			_face(him)
			var gap := absf(him.x - global_position.x)
			if gap < lunge_range and absf(him.y - global_position.y) < 1.6:
				velocity.x = 0.0
				_set_mode(&"tell")
				Sound.play(self, &"fox_snarl", -2.0)
			else:
				# Stiff hops toward him.
				velocity.x = _dir * stalk_speed
				if is_on_floor() and fmod(_clock, 0.42) < delta:
					velocity.y = 2.6
					_hop = 1.0
				if _edge_ahead(0.6) or _wall_ahead():
					velocity.x = 0.0
		&"tell":
			velocity.x = 0.0
			_face(him)
			if _mode_time >= lunge_windup:
				velocity = Vector3(_dir * lunge_speed, 5.5, 0.0)
				_bit = false
				_set_mode(&"lunge")
				Sound.play(self, &"frog_leap", -4.0)
		&"lunge":
			if not _bit and _mode_time > 0.05:
				_bite()
			if is_on_floor() and _mode_time > 0.1:
				_land()
		&"land":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= 0.3:
				_set_mode(&"recover")
		&"recover", &"hurt":
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			if _mode_time >= (rest_time if mode == &"recover" else 0.35):
				_set_mode(&"stalk")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			if _mode_time >= stagger_time:
				posture = 0
				_set_mode(&"recover")
		_:
			_set_mode(&"stalk")
	if mode != &"leap":
		velocity.y -= gravity * delta
	_hop = move_toward(_hop, 0.0, delta * 3.0)
	move_and_slide()
	position.z = 0.0
	if mode == &"stalk" or mode == &"recover":
		_check_touch()


func _face(him: Vector3) -> void:
	if absf(him.x - global_position.x) > 0.3:
		_dir = signf(him.x - global_position.x)


## Off its plinth in one leap, landing a little short of him, biting as it
## comes; from now on it can be cut.
func _leap_down(him: Vector3) -> void:
	collision_layer = 4
	var to := him.x - _dir * 1.2
	var t := 0.6
	velocity.x = clampf((to - global_position.x) / t, -9.0, 9.0)
	velocity.y = ((_ground_y - global_position.y) + 0.5 * gravity * t * t) / t
	_bit = false
	_set_mode(&"leap")
	Sound.play(self, &"fox_snarl", 0.0)
	Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.3, plinth_z), 10, [Color(0.55, 0.56, 0.55), Color(0.42, 0.44, 0.42)])


func _land() -> void:
	_out = 1.0
	velocity.x = 0.0
	_set_mode(&"land")
	Sound.play(self, &"stone_thud", -2.0)
	Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.05, 0.0), 6, [Color(0.55, 0.56, 0.55)])


func _bite() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.9, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * 0.45, 0.6, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_bit = true
			if target.receive_strike(attack_damage, global_position, hurt_kind):
				velocity = Vector3(-_dir * 4.0, 3.5, 0.0)
				_on_parried()
			return


func _on_parried() -> void:
	# The stone cracks: chips fly, it is stunned.
	Confetti.burst(get_parent(), global_position + Vector3(_dir * 0.3, 0.7, 0.0), 12, [Color(0.55, 0.56, 0.55), Color(0.42, 0.44, 0.42)])
	Sound.play(self, &"stone_thud", 0.0)
	super._on_parried()


func take_hit(damage: int, direction: Vector2) -> void:
	if mode == &"asleep" or mode == &"kindle":
		return
	super.take_hit(damage, direction)


func _on_hit(direction: Vector2) -> void:
	velocity.x = direction.x * knockback_speed * 0.4   # (stone: heavy)
	if mode != &"stagger":
		_set_mode(&"hurt")


## The Fan Gust: stone is heavy; it only slides back a little.
func gusted(direction: Vector3, _from: Vector3) -> void:
	if mode == &"asleep" or mode == &"kindle":
		return
	velocity.x = direction.x * 3.0
	if mode == &"tell" or mode == &"lunge":
		_set_mode(&"recover")


func _pose() -> void:
	_rig.rotation.y = (PI * 0.5 - 0.35) if _dir > 0.0 else (-PI * 0.5 + 0.35)
	_rig.position.z = lerpf(plinth_z, 0.0, smoothstep(0.0, 1.0, _out))
	var s := _skin
	for i in s.heads.size():
		s.turns[i] = Quaternion.IDENTITY
		s.moves[i] = Vector3.ZERO
	var pitch := 0.0      # >0 tips forward
	var low := 0.0
	var head := 0.0       # >0 nods down
	var tail := 0.0
	var shake := 0.0
	var glow := 0.0 if mode == &"asleep" else 1.0
	match mode:
		&"asleep":
			pass
		&"kindle":
			glow = _eye_glow
			shake = 0.02 * _eye_glow
			head = -0.12 * _eye_glow
		&"leap", &"lunge":
			pitch = clampf(0.5 - velocity.y * 0.06, -0.2, 0.8)
			tail = -0.5
			head = -0.2
		&"tell":
			var u := smoothstep(0.0, 1.0, _mode_time / lunge_windup)
			pitch = 0.35 * u
			low = 0.12 * u
			head = -0.25 * u
			tail = 0.4 * u
			glow = 1.0 + 0.6 * u
			shake = 0.01 * u
		&"stalk":
			pitch = 0.18 + 0.1 * _hop
			tail = 0.15 * sin(_clock * 6.0)
			head = 0.05
		&"land":
			low = 0.1 * (1.0 - _mode_time / 0.3)
			pitch = 0.2
		&"stagger":
			pitch = -0.4
			head = 0.4
			tail = -0.3
			shake = 0.015
			glow = 0.3 + 0.3 * sin(_clock * 12.0)
		&"hurt":
			pitch = -0.2
		_:
			pitch = 0.1
	_rig.rotation.x = 0.0
	s.turns[BODY] = Quaternion(Vector3.RIGHT, pitch)
	s.moves[BODY] = Vector3(randf_range(-shake, shake), -low, randf_range(-shake, shake))
	s.turns[HEAD] = Quaternion(Vector3.RIGHT, head)
	s.turns[TAIL] = Quaternion(Vector3.RIGHT, tail)
	s.apply()
	for eye: MeshInstance3D in _eyes:
		var side: float = eye.get_meta(&"side")
		eye.position = s.point_on(HEAD, Vector3(side * 0.07, 0.2, 0.255))
		eye.visible = glow > 0.02
		eye.scale = Vector3.ONE * (0.6 + 0.4 * clampf(glow, 0.0, 1.6))
		(eye.material_override as StandardMaterial3D).albedo_color = Color(EYE, clampf(glow, 0.0, 1.0))
