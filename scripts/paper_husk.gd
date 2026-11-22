class_name PaperHusk
extends CharacterBody3D
## A sodden husk: a paper villager the Rain has soaked until it forgot its
## shape. It shuffles back and forth and hurts on touch. When the Ronin comes
## close in front of it, it rears back (the tell) and swipes. A parried swipe
## costs it posture; two in a row stagger it, folded over, and a cut then
## finishes it at once. Otherwise it crumples a little with every hit and
## bursts into confetti on the third.

@export_group("Health")
@export var max_health := 3
@export var contact_damage := 1

@export_group("Patrol")
@export var patrol_speed := 1.6
## How far it wanders either side of where it was placed.
@export var patrol_distance := 3.5
@export var gravity := 38.0

@export_group("Attack")
## It attacks when the Ronin is this close in front of it (metres).
@export var attack_range := 1.9
@export var attack_damage := 1
## The tell: how long it rears back before swiping. This is the player's
## time to read the blow and parry. (0.55 was too slow.)
@export var attack_windup := 0.4
## How long the swipe can hit.
@export var attack_strike_time := 0.14
## The lunge forward during the swipe, in metres per second.
@export var attack_lunge := 5.0
## Pause after a swipe, before it can do anything else.
@export var attack_recover := 0.7
## Seconds between attacks.
@export var attack_cooldown := 1.1
## How far in front of it the swipe's hit box is centred, and its size.
@export var attack_reach := 0.75
@export var attack_size := Vector2(1.0, 1.0)

## When the Ronin walks into it and is hurt by the touch, it gives a quick
## shove (if it is not already attacking), so the hurt has a cause you see.
@export var shove_time := 0.3

@export_group("Posture")
## Parries it can take before it staggers.
@export var max_posture := 2
## Seconds without being parried before one point of posture comes back.
@export var posture_recover_time := 2.5
## How long a stagger lasts. A cut in this time is a finishing cut.
@export var stagger_time := 2.0
## How hard a parry knocks it back, in metres per second.
@export var parried_knockback := 6.0
## Each parried blow leaves it reeling this long.
@export var parried_stun := 0.5

@export_group("Getting hit")
@export var knockback_speed := 7.0
@export var stun_time := 0.25
@export var flash_time := 0.12
## Each hit squashes it to this fraction of its height ("damaged enemies get crumpled").
@export var crumple_per_hit := 0.85
@export var confetti_count := 48

@export_group("Sculpted model")
## On: the Meshy model (models/husk.glb), posed by hand in husk_poses.gd.
## Off: the older figure folded from rigid pieces in code.
@export var use_model := true
@export var model_scene: PackedScene = preload("res://models/husk.glb")
## How tall the model stands, in metres.
@export var model_height := 1.2
## Strides per second of its shamble.
@export var shamble_speed := 0.9
## Its paper is dimmed and cooled by this colour, so it reads as soaked.
@export var soak_tint := Color(0.78, 0.84, 0.95)

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
var _flash_meshes: Array[GeometryInstance3D] = []   # what turns white when it is hit
var _touch: Area3D
## &"patrol", &"windup", &"strike", &"recover" or &"stagger"
var mode: StringName = &"patrol"
var posture := 0
var _mode_time := 0.0
var _attack_cooldown_left := 0.0
var _posture_clock := 0.0
var _struck_this_swipe := false
var _seal: Node3D
var _seal_show := 0.0
var _model: Node3D
var _animator: SamuraiAnimator
var _stride := 0.0
var _clock := 0.0


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
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_mode_time += delta
	if posture > 0 and mode != &"stagger":
		_posture_clock += delta
		if _posture_clock >= posture_recover_time:
			_posture_clock = 0.0
			posture -= 1
	if not is_on_floor():
		velocity.y -= gravity * delta

	match mode:
		&"windup":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= attack_windup:
				_set_mode(&"strike")
				_struck_this_swipe = false
		&"strike":
			velocity.x = _dir * attack_lunge
			if not _struck_this_swipe:
				_swipe()
			if mode == &"strike" and _mode_time >= attack_strike_time:
				_set_mode(&"recover")
		&"shove":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= shove_time:
				_set_mode(&"patrol")
				_attack_cooldown_left = maxf(_attack_cooldown_left, 0.4)
		&"recover", &"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			var wait := attack_recover if mode == &"recover" else stagger_time
			if _mode_time >= wait:
				if mode == &"stagger":
					posture = 0
				_set_mode(&"patrol")
		_:
			if _stun > 0.0:
				velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			else:
				if is_on_floor() and (_wall_ahead() or _edge_ahead() or _too_far()):
					_dir = -_dir
				velocity.x = _dir * patrol_speed
				if _attack_cooldown_left <= 0.0 and is_on_floor() and _player_in_reach():
					_set_mode(&"windup")
	move_and_slide()
	position.z = 0.0

	if mode != &"stagger":
		for body: Node3D in _touch.get_overlapping_bodies():
			if body.has_method("take_damage"):
				var hurt: bool = body.take_damage(contact_damage, global_position)
				if hurt and (mode == &"patrol" or mode == &"windup"):
					# Face him and shove.
					_dir = signf(body.global_position.x - global_position.x)
					if _dir == 0.0:
						_dir = 1.0
					_set_mode(&"shove")


## True while it is staggered: a cut now is a finishing cut.
func is_staggered() -> bool:
	return mode == &"stagger"


func _set_mode(next: StringName) -> void:
	mode = next
	_mode_time = 0.0
	_frame_clock = 1.0  # show the new pose at once, not at the next tick
	if next == &"recover":
		_attack_cooldown_left = attack_cooldown


## Is the Ronin close in front of it (and roughly level with it)? If he is
## close BEHIND it, it turns round to face him instead.
func _player_in_reach() -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var player := node as Node3D
		if absf(player.global_position.y - global_position.y) > 1.2:
			continue
		var ahead := (player.global_position.x - global_position.x) * _dir
		if ahead > 0.0 and ahead < attack_range:
			return true
		if ahead < 0.0 and ahead > -attack_range * 0.8:
			_dir = -_dir
	return false


## The swipe: hits the player if he is inside the box in front of it.
func _swipe() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(attack_size.x, attack_size.y, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2  # "player"
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * attack_reach, 0.6, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 4):
		var target: Object = result["collider"]
		if not target.has_method("receive_strike"):
			continue
		_struck_this_swipe = true
		if target.receive_strike(attack_damage, global_position):
			_on_parried()
		return


func _on_parried() -> void:
	posture += 1
	_posture_clock = 0.0
	velocity.x = -_dir * parried_knockback
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger")
	else:
		_set_mode(&"recover")
		_mode_time = attack_recover - parried_stun


func _process(delta: float) -> void:
	_rig.rotation.y = -0.35 if _dir > 0.0 else PI + 0.35
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_set_flash(false)
	# The finishing seal is drawn in and out smoothly, every frame.
	_seal_show = move_toward(_seal_show, 1.0 if mode == &"stagger" else 0.0, delta / 0.12)
	_seal.visible = _seal_show > 0.0
	_seal.scale = Vector3.ONE * maxf(smoothstep(0.0, 1.0, _seal_show), 0.001)
	_seal.rotation.z = (1.0 - _seal_show) * 0.8
	if _model:
		# Stamped on its back, on the side the camera sees, riding the
		# folded-over body.
		var space := _animator.skeleton.global_transform
		var back: Vector3 = space * _animator.skeleton.get_bone_global_pose(_animator.skeleton.find_bone("Spine")).origin
		_seal.global_position = back + Vector3(0.0, 0.06, 0.24)
		_seal.global_rotation = Vector3(0.0, 0.0, _seal.rotation.z)
	else:
		# Keep it on the side of the body facing the camera, whichever way it faces.
		_seal.position.z = 0.37 if _dir > 0.0 else -0.37
		_seal.rotation.y = 0.0 if _dir > 0.0 else PI
	_clock += delta
	_frame_clock += delta
	if _frame_clock >= 1.0 / frames_per_second:
		_frame_clock = 0.0
		_frame += 1
		_pose()


## Puts the rigid pieces in the stance for what it is doing.
## Angles: body lean (+ back, - forward), arms (+ swung forward, - up and back).
func _pose() -> void:
	if _model:
		_pose_model()
		return
	var p := _frame * 0.9
	var lean := 0.0
	var arm := 0.0
	var head := -0.55
	match mode:
		&"windup":
			# The tell: it draws itself up and back, arms raised behind its head.
			var ready := smoothstep(0.0, 0.6, _mode_time / attack_windup)
			lean = 0.38 * ready
			arm = -2.4 * ready
			head = lerpf(-0.55, 0.15, ready)
		&"strike", &"shove":
			lean = -0.42
			arm = 1.7
			head = -0.2
		&"recover":
			var settle := smoothstep(0.0, 1.0, _mode_time / attack_recover)
			lean = lerpf(-0.42, 0.0, settle)
			arm = lerpf(1.6, 0.0, settle)
		&"stagger":
			# Folded over at the waist, arms hanging, head lolling slowly.
			lean = -0.75
			arm = 0.9
			head = -1.0 + sin(p * 0.25) * 0.08
		_:
			# A limp, soggy waddle.
			_rig.rotation.z = sin(p) * 0.09
			_head.rotation.z = -0.55 + sin(p * 0.5) * 0.12
			_arms[0].rotation.z = sin(p) * 0.35
			_arms[1].rotation.z = -sin(p) * 0.35
			return
	_rig.rotation.z = lean
	_head.rotation.z = head
	_arms[0].rotation.z = arm
	_arms[1].rotation.z = arm * 0.85


## Picks the model's stance for what it is doing (12 times a second).
func _pose_model() -> void:
	var pose: Dictionary
	match mode:
		&"windup":
			pose = HuskPoses.windup(_mode_time / attack_windup)
		&"strike":
			pose = HuskPoses.strike()
		&"shove":
			pose = HuskPoses.shove(_mode_time / shove_time)
		&"recover":
			var settle := smoothstep(0.0, 1.0, _mode_time / attack_recover)
			pose = SamuraiAnimator.mix(HuskPoses.strike(), HuskPoses.shamble(_stride), settle)
		&"stagger":
			pose = HuskPoses.stagger(_clock)
		_:
			# It only shuffles forward while it is actually moving.
			if absf(velocity.x) > 0.2:
				_stride = fposmod(_stride + shamble_speed / frames_per_second, 1.0)
			pose = HuskPoses.shamble(_stride)
	_animator.apply(pose)


## Called by the Ronin's slash. `direction` is the way the blade travelled.
func take_hit(damage: int, direction: Vector2) -> void:
	var finishing := mode == &"stagger"
	health = 0 if finishing else health - damage
	if health <= 0:
		var scraps := roundi(confetti_count * (1.6 if finishing else 1.0))
		Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.6, 0.0), scraps)
		Sound.play(self, &"paper_burst", 3.0 if finishing else 0.0)
		queue_free()
		return
	if mode == &"windup" or mode == &"strike":
		_set_mode(&"recover")  # a cut interrupts its swipe
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


## The hit flash: a white layer laid over the paper for a moment (a
## material overlay). Not by switching on the paper's glow ("emission"):
## on the skinned Meshy model that made every soft glow in the sky (the
## moon's) draw as a white square for as long as the flash lasted.
func _set_flash(on: bool) -> void:
	for mesh: GeometryInstance3D in _flash_meshes:
		mesh.material_overlay = PaperHusk.flash_overlay() if on else null


static var _flash_look: StandardMaterial3D


static func flash_overlay() -> StandardMaterial3D:
	if _flash_look == null:
		_flash_look = StandardMaterial3D.new()
		_flash_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_look.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
		_flash_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flash_look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_flash_look.cull_mode = BaseMaterial3D.CULL_DISABLED
		_flash_look.disable_fog = true
	return _flash_look


func _add(parent: Node3D, mesh: MeshInstance3D) -> void:
	parent.add_child(mesh)
	_materials.append(mesh.material_override as StandardMaterial3D)
	_flash_meshes.append(mesh)


func _build() -> void:
	if use_model and model_scene:
		_build_model()
	else:
		_build_folded()
	_build_seal()


## The Meshy model: scaled to model_height, turned to face +X like the rest
## of the game, and given its own copy of the paper (so a hit flashes only
## this husk).
func _build_model() -> void:
	_rig = Node3D.new()
	add_child(_rig)
	_model = Node3D.new()
	_rig.add_child(_model)
	var figure: Node3D = model_scene.instantiate()
	var meshes := figure.find_children("*", "MeshInstance3D", true, false)
	var low := INF
	var high := -INF
	for node: MeshInstance3D in meshes:
		var box := node.get_aabb()
		low = minf(low, box.position.y)
		high = maxf(high, box.end.y)
	var grow := model_height / maxf(high - low, 0.001)
	figure.scale = Vector3.ONE * grow
	figure.position.y = -low * grow
	figure.rotation.y = PI * 0.5  # Meshy models face +Z; the game faces +X.
	_model.add_child(figure)
	for player: Node in figure.find_children("*", "AnimationPlayer", true, false):
		player.queue_free()  # Meshy's walk and run are not used
	for node: MeshInstance3D in meshes:
		var made := node.get_active_material(0) as BaseMaterial3D
		var paper := StandardMaterial3D.new()
		if made:
			paper.albedo_texture = made.albedo_texture
		paper.albedo_color = soak_tint
		paper.roughness = 1.0
		paper.metallic_specular = 0.2
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, paper)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_materials.append(paper)
		_flash_meshes.append(node)
	var skeleton: Skeleton3D = figure.find_children("*", "Skeleton3D", true, false)[0]
	# Skeleton units per metre (Meshy rigs are in centimetres), allowing for
	# the scale above. Worked out from the scales, as it is not in the tree yet.
	var units := 1.0 / (grow * _local_scale(skeleton, figure))
	_animator = SamuraiAnimator.new(skeleton, units)
	_animator.apply(HuskPoses.shamble(0.0))


## How much `node` is scaled relative to `top` (both before entering the tree).
static func _local_scale(node: Node3D, top: Node3D) -> float:
	var scale_y := 1.0
	var at: Node = node
	while at and at != top:
		if at is Node3D:
			scale_y *= (at as Node3D).scale.y
		at = at.get_parent()
	return scale_y


## The older husk, folded from rigid pieces in code.
func _build_folded() -> void:
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



func _build_seal() -> void:
	# The finishing seal: a small vermilion paper diamond stamped on the side
	# of its body that faces us, with a pale fleck at its heart, shown only
	# while it is staggered. It rides on the body, so it folds over with it.
	# It is not in _materials, so it does not flash when the husk is hit.
	_seal = Node3D.new()
	_seal.position = Vector3(0.0, 0.42, 0.37)
	_rig.add_child(_seal)
	var seal := PaperMesh.new(104)
	seal.shade_jitter = 0.0
	seal.color = PaperMesh.VERMILION
	var r := 0.12
	seal.quad(Vector3(0.0, -r, 0.0), Vector3(r * 0.8, 0.0, 0.0), Vector3(0.0, r, 0.0), Vector3(-r * 0.8, 0.0, 0.0))
	seal.color = PaperMesh.WASHI
	var c := 0.03
	seal.quad(Vector3(0.0, -c, 0.012), Vector3(c * 0.8, 0.0, 0.012), Vector3(0.0, c, 0.012), Vector3(-c * 0.8, 0.0, 0.012))
	_seal.add_child(seal.build(Color.WHITE, 0.0, true))
	_seal.visible = false
