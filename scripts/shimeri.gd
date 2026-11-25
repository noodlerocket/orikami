class_name Shimeri
extends CharacterBody3D
## Shimeri, 湿将, the Sodden General (docs/sumi_marsh_plan.md; design.md: "he
## endures the Rain. Soaked through, barely holding his shape, still
## guarding his post out of duty. Slow and heavy. He fights with fading honour
## and forgets his own moves mid-fight."). The second of the three generals,
## holder of one of the Emperor's seals, at his post in Sumi Marsh.
##
## A Meshy model (models/shimeri.glb, 4 m, rigged; picture
## docs/reference/shimeri_front.png; image 01a20c5e-078f-7788-b2bd-8efbd8892676,
## model 01a20c62-a41b-705d-bbea-309465d3f038 (meshy-7.1 + meshy-7 2K,
## remeshed 30,000), rig 01a20c66-3526-71a2-8599-205f72417e8b), posed by hand
## with SamuraiAnimator; his long nodachi is folded here. Ink drips off him
## all the time.
##
## His moves, each slow, each with its tell (ShimeriPost runs the fight):
##  - the cleave: the nodachi raised high over his head, ink streaming off
##    it, then brought down: parry it. Where it strikes, a wave of ink runs
##    along the floor both ways: jump it;
##  - the low sweep: he drags the blade back through the ink (a wake), then
##    sweeps it round at the ankles: jump (or parry);
##  - the charge: shoulder lowered, he wades in at a run: parry (double
##    posture) or get out of the way;
##  - the weeping sky: he lifts his face and arms to the Rain, and ink falls
##    where stains spread first (InkDrop): keep moving;
##  - forgetting: in the middle of a tell he stops; his arms sag, his head
##    tilts as if trying to remember: an opening. Then he begins again,
##    sometimes something else, always with its own tell from the start.
##  - from half health he calls his drowned soldiers once: two sodden husks
##    rise from the ink.
## Touching him: he stamps. Posture full: he sinks to one knee for a
## finishing cut.

signal health_changed(current: int, maximum: int)
signal posture_changed(current: int, maximum: int)
signal defeated
## From half health, once: his soldiers rise (ShimeriPost makes them).
signal called_soldiers
## The Drowned Muster: he drives the nodachi into the ink and calls his
## drowned warriors; the ink bubbles at these points (world x) first, then
## they rise there (ShimeriPost).
signal muster(points: Array)

@export_group("Fight")
@export var max_health := 36
@export var max_posture := 7
@export var finish_damage := 4
@export var posture_recover_time := 3.0
@export var contact_damage := 1
## Rest between moves, and how much quicker everything is from half health.
@export var rest_time := 1.2
@export var enraged_pace := 0.82
@export var walk_speed := 1.3
## How likely he is to forget a move part-way through its tell, before and
## after half health, and how long he stands lost.
@export var forget_chance := 0.15
@export var forget_chance_late := 0.25
@export var forget_time := 1.5
@export_group("Cleave")
@export var cleave_tell := 0.95
@export var cleave_reach := 3.4
## The ink wave from where it strikes: speed (m/s) and how far it runs.
@export var wave_speed := 8.5
@export var wave_range := 13.0
@export_group("Sweep")
@export var sweep_tell := 0.85
@export var sweep_time := 0.4
@export var sweep_reach := 4.2
@export_group("Charge")
@export var charge_tell := 0.85
@export var charge_speed := 8.0
@export var charge_time := 1.1
@export_group("Weeping sky")
@export var sky_tell := 1.0
@export var sky_drops := 6
@export var sky_gap := 0.3
## The ink drops: how wide their stains spread (m) and how long they warn (s).
@export var drop_radius := 1.0
@export var drop_warning := 1.0
@export_group("Drowned Muster")
## He drives the nodachi into the ink (the tell, s), and how many of his
## drowned warriors may be up at once; the least time between musters.
@export var muster_tell := 1.2
@export var most_soldiers := 3
@export var muster_cooldown := 9.0
@export_group("Body")
@export var model_height := 4.0
@export var gravity := 30.0

var health := 0
var posture := 0
var active := false
var facing := -1.0
var ronin: Ronin
## Where he may go (world x), and the floor he stands on (world y).
var bounds := Vector2(-INF, INF)
var floor_y := 0.0
## Laid over his paper while not flashing (the ending: ShimeriPost).
var wash: Material

var _mode := &"wait"
var _mode_time := 0.0
var _clock := 0.0
var _rng := RandomNumberGenerator.new()
var _model: Node3D
var _meshes: Array[MeshInstance3D] = []
var _animator: SamuraiAnimator
var _blade: Node3D
var _drips: CPUParticles3D
var _wake: CPUParticles3D
var _swoosh: MeshInstance3D
var _swoosh_look: ShaderMaterial
var _flash := 0.0
var _posture_clock := 0.0
var _hit_done := false
var _enraged := false
var _called := false
## Kept by ShimeriPost: how many of his warriors are up (or rising).
var soldiers_alive := 0
var _muster_clock := 4.0
var _hit_clock := 9.0
## The dark cloud of ink gathering overhead in the weeping sky.
var _cloud: CPUParticles3D
var _swat := 0.0
var _kneel := 0.0
## 0 kneeling, 1 fallen forward, lifeless, face down in the ink (the end).
var fallen := 0.0
## His eyes, kindled in the dark of the helmet (the intro; the fight).
var eyes := 0.0
var _eye_glow: Array[MeshInstance3D] = []
var _head_bone := -1
var _next := &""          # the move he was about to make (after forgetting)
var _lost_from := &""     # the tell he forgot in
var _dropped := 0
## The ink waves rolling out from a cleave: [x, direction, travelled].
var _waves: Array = []
var _wave_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	_rng.seed = 7171
	collision_layer = 4
	collision_mask = 1
	health = max_health
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.7
	capsule.height = model_height * 0.92
	shape.shape = capsule
	shape.position.y = model_height * 0.46
	add_child(shape)
	_build_model()
	_build_blade()
	_build_effects()
	_build_eyes()
	_build_cloud()


func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	var figure: Node3D = (preload("res://models/shimeri.glb") as PackedScene).instantiate()
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
		player.queue_free()
	var skeleton: Skeleton3D = figure.find_children("*", "Skeleton3D", true, false)[0]
	for node: MeshInstance3D in meshes:
		var made := node.get_active_material(0) as BaseMaterial3D
		var paper := StandardMaterial3D.new()
		if made:
			paper.albedo_texture = made.albedo_texture
		paper.roughness = 0.42   # (soaked: a wet sheen)
		paper.metallic_specular = 0.7
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, paper)
		_meshes.append(node)
	# (Poses are in Hōshō's measure, a 3 m general: scaled up to his 4 m.)
	var units := 1.0 / (grow * PaperHusk._local_scale(skeleton, figure)) * (model_height / 3.0)
	_animator = SamuraiAnimator.new(skeleton, units)
	_animator.apply(_wait_pose(0.0))


## The nodachi: a very long, slightly curved blade of dark soaked paper with
## a pale edge, a long grip wrapped in faded indigo cord, a round guard. Its
## +Y runs from the grip toward the point; its origin is his right hand.
func _build_blade() -> void:
	_blade = Node3D.new()
	add_child(_blade)
	var b := PaperMesh.new(31)
	b.texture_world = false
	b.shade_jitter = 0.08
	b.color = Color(0.2, 0.22, 0.32)
	b.box(Vector3(0.0, -0.05, 0.0), Vector3(0.05, 0.62, 0.05))
	b.color = Color(0.12, 0.12, 0.16)
	for k in 6:
		b.box(Vector3(0.0, -0.3 + k * 0.1, 0.0), Vector3(0.055, 0.025, 0.055))
	b.color = Color(0.3, 0.26, 0.2)
	b.frustum(10, Vector2(0.11, 0.11), Vector2(0.11, 0.11), 0.03, Vector3(0.0, 0.26, 0.0))
	# The blade: a gentle curve back, its edge forward.
	var length := 1.75
	var steps := 8
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var y0 := 0.29 + t0 * length
		var y1 := 0.29 + t1 * length
		var c0 := -0.08 * t0 * t0
		var c1 := -0.08 * t1 * t1
		var w0 := lerpf(0.055, 0.04, t0)
		var w1 := lerpf(0.055, 0.04, t1) if i < steps - 1 else 0.0
		b.color = Color(0.16, 0.16, 0.19)
		b.quad(Vector3(c0 - 0.01, y0, -0.012), Vector3(c0 + w0, y0, 0.0), Vector3(c1 + w1, y1, 0.0), Vector3(c1 - 0.01, y1, -0.012))
		b.quad(Vector3(c0 - 0.01, y0, 0.012), Vector3(c0 + w0, y0, 0.0), Vector3(c1 + w1, y1, 0.0), Vector3(c1 - 0.01, y1, 0.012))
		b.color = Color(0.72, 0.74, 0.74)
		b.quad(Vector3(c0 + w0 * 0.75, y0, 0.004), Vector3(c0 + w0, y0, 0.0), Vector3(c1 + w1, y1, 0.0), Vector3(c1 + w1 * 0.75, y1, 0.004))
	var mesh := b.build()
	_blade.add_child(mesh)
	_meshes.append(mesh)


func _build_effects() -> void:
	# Ink dripping off him all the time.
	_drips = CPUParticles3D.new()
	_drips.amount = 40
	_drips.lifetime = 0.9
	_drips.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_drips.emission_box_extents = Vector3(0.7, model_height * 0.35, 0.5)
	_drips.direction = Vector3.DOWN
	_drips.spread = 5.0
	_drips.gravity = Vector3(0.0, -9.0, 0.0)
	_drips.initial_velocity_min = 0.1
	_drips.initial_velocity_max = 0.5
	var drop := QuadMesh.new()
	drop.size = Vector2(0.06, 0.1)
	drop.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.05, 0.9))
	_drips.mesh = drop
	_drips.position = Vector3(0.0, model_height * 0.55, 0.0)
	add_child(_drips)
	# The wake he drags through the ink before a sweep.
	_wake = CPUParticles3D.new()
	_wake.emitting = false
	_wake.amount = 40
	_wake.lifetime = 0.6
	_wake.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wake.emission_box_extents = Vector3(0.3, 0.05, 0.4)
	_wake.direction = Vector3.UP
	_wake.spread = 30.0
	_wake.gravity = Vector3(0.0, -10.0, 0.0)
	_wake.initial_velocity_min = 1.2
	_wake.initial_velocity_max = 2.6
	var d2 := QuadMesh.new()
	d2.size = Vector2(0.07, 0.07)
	d2.material = PaperMesh.soft_ink(Color(0.04, 0.04, 0.06, 0.95))
	_wake.mesh = d2
	add_child(_wake)
	# The blade's swoosh (the Ronin's kind: the slash_sweep shader), ink-dark.
	_swoosh_look = ShaderMaterial.new()
	_swoosh_look.shader = preload("res://shaders/slash_sweep.gdshader")
	var arc := PaperMesh.new(5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 18
	for r in rows:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(r + corner[1]) / rows
			var across: float = corner[0]
			var a := lerpf(PI * 0.72, -PI * 0.18, t)
			var radius := lerpf(1.2, sweep_reach * 0.9, across)
			st.set_uv(Vector2(t, across))
			st.add_vertex(Vector3(cos(a) * radius, sin(a) * radius, 0.0))
	_swoosh = MeshInstance3D.new()
	_swoosh.mesh = st.commit()
	_swoosh.material_override = _swoosh_look
	_swoosh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_swoosh.top_level = true
	_swoosh.visible = false
	add_child(_swoosh)
	arc = null
	# The ink waves: two dark crests that run out along the floor.
	for k in 2:
		var w := PaperMesh.new(40 + k)
		w.texture_world = false
		w.color = Color(0.03, 0.03, 0.05)
		w.polygon(PackedVector2Array([Vector2(-0.9, 0.0), Vector2(0.5, 0.0), Vector2(0.35, 0.55), Vector2(0.1, 0.85),
				Vector2(-0.15, 0.7), Vector2(-0.4, 0.4)]), 0.0)
		w.color = Color(0.5, 0.55, 0.55)
		w.polygon(PackedVector2Array([Vector2(0.05, 0.82), Vector2(0.15, 0.82), Vector2(0.38, 0.5), Vector2(0.3, 0.5)]), 0.01)
		var m := w.build(Color.WHITE, 0.0, true)
		m.top_level = true
		m.visible = false
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		_wave_meshes.append(m)


## The ink cloud of the weeping sky: dark heavy puffs gathering over the
## court above him, from which the drops fall.
func _build_cloud() -> void:
	_cloud = CPUParticles3D.new()
	_cloud.emitting = false
	_cloud.amount = 50
	_cloud.lifetime = 2.2
	_cloud.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_cloud.emission_box_extents = Vector3(6.0, 0.6, 1.5)
	_cloud.direction = Vector3(-1.0, 0.0, 0.0)
	_cloud.spread = 30.0
	_cloud.gravity = Vector3(0.0, -0.1, 0.0)
	_cloud.initial_velocity_min = 0.2
	_cloud.initial_velocity_max = 0.6
	_cloud.scale_amount_min = 1.5
	_cloud.scale_amount_max = 3.0
	var puff := QuadMesh.new()
	puff.size = Vector2(1.2, 1.0)
	puff.material = PaperMesh.soft_ink(Color(0.04, 0.04, 0.06, 0.7))
	_cloud.mesh = puff
	_cloud.top_level = true
	add_child(_cloud)


## Two pale cold points in the dark of his helmet, shown as `eyes` rises.
func _build_eyes() -> void:
	_head_bone = _animator.skeleton.find_bone("Head")
	for side: float in [-1.0, 1.0]:
		var e := PaperMesh.new(1)
		e.color = Color(0.75, 0.85, 1.0)
		e.ellipse(Vector2.ZERO, Vector2(0.05, 0.025), 10, 0.0)
		var m := e.build(Color.WHITE, 3.0, true)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(m.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.top_level = true
		m.set_meta(&"side", side)
		add_child(m)
		_eye_glow.append(m)


func begin() -> void:
	active = true
	_set_mode(&"guard")
	health_changed.emit(health, max_health)
	posture_changed.emit(posture, max_posture)


func reset(at: Vector3) -> void:
	active = false
	collision_layer = 4
	fallen = 0.0
	health = max_health
	posture = 0
	_enraged = false
	_called = false
	global_position = at
	velocity = Vector3.ZERO
	facing = -1.0
	_swoosh.visible = false
	_wake.emitting = false
	_waves.clear()
	for m: MeshInstance3D in _wave_meshes:
		m.visible = false
	_set_mode(&"wait")


func mode() -> StringName:
	return _mode


func is_staggered() -> bool:
	return _mode == &"stagger"


func _set_mode(next: StringName) -> void:
	_mode = next
	_mode_time = 0.0
	_hit_done = false


func _pace() -> float:
	return enraged_pace if _enraged else 1.0


## Called by the Ronin's cuts.
func take_hit(damage: int, direction: Vector2) -> void:
	if not active or _mode in [&"defeated", &"wait"]:
		return
	_hit_clock = 0.0
	if _mode == &"stagger":
		health -= finish_damage
		posture = 0
		posture_changed.emit(posture, max_posture)
		Confetti.burst(get_parent(), global_position + Vector3(0.0, 2.2, 0.0), 50, [Color(0.06, 0.06, 0.08), Color(0.62, 0.62, 0.6), Color(0.3, 0.32, 0.46)])
		Sound.play(self, &"paper_burst", 2.0)
		_set_mode(&"recover")
	else:
		health -= damage
		# Wet scraps and drops of ink where he is cut.
		WaterFx.splash(get_parent(), global_position + Vector3(-signf(direction.x) * 0.4, 2.0, 0.3), 0.5, true)
	_flash = 0.12
	health_changed.emit(maxi(health, 0), max_health)
	if health <= 0:
		_fall()
		return
	if not _enraged and health <= max_health / 2:
		_enraged = true


func _parried(cost: int) -> void:
	posture = mini(posture + cost, max_posture)
	_posture_clock = 0.0
	posture_changed.emit(posture, max_posture)
	velocity.x = -facing * 2.0
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger", 4.0)
		_swoosh.visible = false
		_wake.emitting = false


func _fall() -> void:
	active = false
	velocity = Vector3.ZERO
	# (Beaten, his body is not something to cut.)
	collision_layer = 0
	remove_from_group(&"gust_target")
	_swoosh.visible = false
	_wake.emitting = false
	_set_mode(&"defeated")
	posture = 0
	posture_changed.emit(posture, max_posture)
	defeated.emit()


## The Fan Gust cannot move him; it only blows the drops off his armour.
func gusted(_direction: Vector3, _from_point: Vector3) -> void:
	WaterFx.splash(get_parent(), global_position + Vector3(0.0, 2.4, 0.0), 0.8, true)


# --- Thinking ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_clock += delta
	_mode_time += delta
	_swat = maxf(_swat - delta, 0.0)
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if ronin and not is_in_group(&"gust_target"):
			add_to_group(&"gust_target")
	if not is_on_floor():
		velocity.y -= gravity * delta
	if active and ronin:
		_think(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, bounds.x, bounds.y)
	position.z = 0.0
	_update_waves(delta)
	if active and _mode not in [&"stagger", &"defeated", &"forget"]:
		_touch_check()


func _think(delta: float) -> void:
	var dx := ronin.global_position.x - global_position.x
	var dist := absf(dx)
	if _mode not in [&"stagger", &"defeated"]:
		_posture_clock += delta
		if posture > 0 and _posture_clock > posture_recover_time:
			_posture_clock = 0.0
			posture -= 1
			posture_changed.emit(posture, max_posture)
	_hit_clock += delta
	_muster_clock += delta
	var tells := {&"cleave_tell": cleave_tell, &"sweep_tell": sweep_tell, &"charge_tell": charge_tell, &"sky_tell": sky_tell}
	if _mode in tells:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		var length: float = tells[_mode] * _pace()
		# Part-way through a tell he may lose the thread.
		if _mode_time > length * 0.45 and _mode_time - delta <= length * 0.45:
			if _hit_clock > 1.2 and _rng.randf() < (forget_chance_late if _enraged else forget_chance):
				_lost_from = _mode
				_set_mode(&"forget")
				Sound.play(self, &"shimeri_groan", -4.0)
				return
		if _mode == &"sweep_tell":
			_wake.emitting = true
			_wake.global_position = Vector3(global_position.x - facing * 1.6, floor_y + 0.45, 0.4)
		if _mode_time > length:
			_wake.emitting = false
			match _mode:
				&"cleave_tell":
					_set_mode(&"cleave")
					Sound.play(self, &"akane_slash", 4.0)
				&"sweep_tell":
					_set_mode(&"sweep")
					_swoosh.visible = true
					Sound.play(self, &"akane_slash", 2.0)
				&"charge_tell":
					_set_mode(&"charge")
					Sound.play(self, &"shimeri_groan", 0.0)
				&"sky_tell":
					_set_mode(&"sky")
					_dropped = 0
				&"muster_tell":
					pass
		return
	match _mode:
		&"guard":
			if dist > 0.4:
				facing = signf(dx)
			var want := 0.0
			if dist > 3.6:
				want = walk_speed
			elif dist < 2.0:
				want = -walk_speed * 0.5
			velocity.x = move_toward(velocity.x, facing * want, 6.0 * delta)
			if _mode_time > rest_time * _pace():
				_choose(dist)
		&"cleave":
			velocity.x = facing * 1.0
			if not _hit_done and _mode_time > 0.18:
				_strike(Vector3(facing * cleave_reach * 0.5, 1.6, 0.0), Vector3(cleave_reach, 3.2, 1.6), 1, &"cut")
				_hit_done = true
				_send_waves()
			if _mode_time > 0.9:
				_set_mode(&"recover")
		&"sweep":
			velocity.x = facing * 1.5
			var u := clampf(_mode_time / sweep_time, 0.0, 1.0)
			_update_swoosh(u)
			if not _hit_done and u > 0.3:
				_strike(Vector3(facing * sweep_reach * 0.5, 0.45, 0.0), Vector3(sweep_reach, 0.9, 1.6), 1, &"cut")
			if _mode_time > sweep_time:
				_set_mode(&"recover")
		&"charge":
			velocity.x = facing * charge_speed
			if not _hit_done:
				_strike(Vector3(facing * 1.2, 1.6, 0.0), Vector3(1.6, 2.6, 1.6), 2, &"ink")
			if _mode_time > charge_time or is_on_wall() \
					or global_position.x <= bounds.x + 0.05 or global_position.x >= bounds.y - 0.05:
				_set_mode(&"recover")
				Sound.play(self, &"land", 2.0)
		&"sky":
			velocity.x = 0.0
			if _dropped < sky_drops and _mode_time > _dropped * sky_gap * _pace():
				_drop_ink()
				_dropped += 1
			if _mode_time > sky_drops * sky_gap * _pace() + 0.4:
				_set_mode(&"recover")
			elif dist < 2.4 and _mode_time > 0.4:
				# He will not stand and be cut: he breaks off and swings.
				facing = signf(dx) if absf(dx) > 0.2 else facing
				_set_mode(&"sweep")
				_swoosh.visible = true
				Sound.play(self, &"akane_slash", 2.0)
		&"muster":
			velocity.x = 0.0
			if _mode_time > muster_tell * _pace():
				_set_mode(&"recover")
		&"forget":
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			if _mode_time > forget_time * _pace():
				_set_mode(&"remember")
		&"remember":
			if _mode_time > 0.35:
				_choose(dist)
		&"recover":
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			if _mode_time > 0.9 * _pace():
				_swoosh.visible = false
				_set_mode(&"guard")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			if _mode_time > 2.6:
				posture = 0
				posture_changed.emit(posture, max_posture)
				_set_mode(&"recover")


func _choose(dist: float) -> void:
	# The Drowned Muster, when too few of his warriors are up.
	var muster_every := muster_cooldown * (0.7 if _enraged else 1.0)
	if soldiers_alive < (most_soldiers if _enraged else 2) and _muster_clock > muster_every and _rng.randf() < 0.6:
		_muster_clock = 0.0
		_start_muster()
		return
	var options: Array[StringName] = []
	if dist < cleave_reach + 0.4:
		options.append_array([&"cleave_tell", &"cleave_tell", &"sweep_tell"])
	elif dist < sweep_reach + 0.3:
		options.append_array([&"sweep_tell", &"sweep_tell", &"cleave_tell"])
	else:
		options.append_array([&"charge_tell", &"charge_tell", &"sky_tell"])
	options.append(&"sky_tell" if _rng.randf() < 0.5 else &"charge_tell")
	# After forgetting, not straight back into the same tell (usually).
	if _mode == &"remember" and _lost_from in options and _rng.randf() < 0.6:
		options.erase(_lost_from)
	var pick: StringName = options[_rng.randi() % options.size()]
	if ronin:
		facing = signf(ronin.global_position.x - global_position.x) if absf(ronin.global_position.x - global_position.x) > 0.3 else facing
	_set_mode(pick)
	if pick == &"sky_tell":
		Sound.play(self, &"shimeri_groan", -2.0)


## The Drowned Muster: the nodachi driven point-down into the ink with
## both hands, a groan; the ink bubbles where they will rise (round the
## Ronin, never on him), and ShimeriPost raises them a moment later.
func _start_muster() -> void:
	_set_mode(&"muster")
	Sound.play(self, &"shimeri_groan", 4.0)
	Sound.play(self, &"splash", 4.0)
	WaterFx.splash(get_parent(), global_position + Vector3(facing * 1.4, 0.45, 0.2), 1.6, true)
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("add_shake"):
		camera.call("add_shake", 0.35)
	var points: Array = []
	var count := (most_soldiers if _enraged else 2) - soldiers_alive
	var hx := ronin.global_position.x if ronin else global_position.x
	for k in maxi(count, 1):
		var side := -1.0 if k % 2 == 0 else 1.0
		var x := clampf(hx + side * _rng.randf_range(2.8, 4.5), bounds.x + 0.5, bounds.y - 0.5)
		points.append(x)
	muster.emit(points)


## Anything of his inside his blow (a box, relative to him). Parried: posture.
func _strike(at: Vector3, size: Vector3, cost: int, kind: StringName) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + at)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 4):
		var target: Object = result["collider"]
		if not target.has_method("receive_strike"):
			continue
		_hit_done = true
		if target.receive_strike(1, global_position + Vector3(0.0, 1.8, 0.0), kind):
			_parried(cost)
			Confetti.burst(get_parent(), global_position + Vector3(facing * 1.8, 1.6, 0.3), 12, [Color(1.0, 0.86, 0.5), Color(0.9, 0.92, 0.9)])
		return


## The blade strikes the ink: a dark crest runs out each way along the floor.
func _send_waves() -> void:
	var at := global_position.x + facing * cleave_reach * 0.8
	_waves = [[at, 1.0, 0.0, false], [at, -1.0, 0.0, false]]
	WaterFx.splash(get_parent(), Vector3(at, floor_y + 0.45, 0.0), 1.5, true)
	Sound.play(self, &"splash", 4.0)
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("add_shake"):
		camera.call("add_shake", 0.45)


func _update_waves(delta: float) -> void:
	for k in _wave_meshes.size():
		var m := _wave_meshes[k]
		if k >= _waves.size():
			m.visible = false
			continue
		var w: Array = _waves[k]
		w[2] += wave_speed * delta
		w[0] += w[1] * wave_speed * delta
		var x: float = w[0]
		var fade := 1.0 - clampf((w[2] - wave_range * 0.7) / (wave_range * 0.3), 0.0, 1.0)
		m.visible = w[2] < wave_range and x > bounds.x - 1.0 and x < bounds.y + 1.0
		m.global_position = Vector3(x, floor_y + 0.38, 0.2)
		m.scale = Vector3(w[1], fade, 1.0)
		if m.visible and not w[3] and ronin:
			var rel := ronin.global_position - Vector3(x, floor_y, 0.0)
			if absf(rel.x) < 0.6 and rel.y < 0.75:
				w[3] = true
				ronin.take_damage(1, Vector3(x - w[1], floor_y + 0.4, 0.0), &"ink")
	if not _waves.is_empty() and (_waves[0] as Array)[2] >= wave_range:
		_waves.clear()


## A drop of ink from the sky, near him: its stain spreads first (InkDrop).
func _drop_ink() -> void:
	if ronin == null:
		return
	var drop := InkDrop.new()
	drop.target = ronin
	drop.radius = drop_radius
	drop.warning = drop_warning
	get_parent().add_child(drop)
	var x := ronin.global_position.x + _rng.randf_range(-2.5, 2.5)
	if _dropped == 0:
		x = ronin.global_position.x
	x = clampf(x, bounds.x - 1.0, bounds.y + 1.0)
	drop.global_position = Vector3(x, floor_y + 0.45, 0.0)


## Walking into him: he stamps.
func _touch_check() -> void:
	if ronin == null or _swat > 0.0:
		return
	var rel := ronin.global_position - global_position
	if absf(rel.x) < 0.95 and rel.y > -0.5 and rel.y < model_height * 0.9:
		_swat = 1.0
		ronin.take_damage(contact_damage, global_position + Vector3(0.0, 1.0, 0.0), &"ink")
		Sound.play(self, &"splash", 2.0)


func _update_swoosh(u: float) -> void:
	var turn := Basis.IDENTITY if facing > 0.0 else Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
	_swoosh.global_transform = Transform3D(turn.scaled(Vector3(1.0, 0.45, 1.0)), global_position + Vector3(0.0, 0.9, 0.35))
	_swoosh_look.set_shader_parameter(&"head", clampf(u * 1.6, 0.0, 1.05))
	_swoosh_look.set_shader_parameter(&"tail", clampf((u - 0.45) * 1.9, 0.0, 1.05))
	_swoosh_look.set_shader_parameter(&"tint", Color(0.08, 0.08, 0.12, 0.9))


# --- How he looks --------------------------------------------------------------------

func _process(delta: float) -> void:
	_model.rotation.y = 0.0 if facing > 0.0 else PI
	_animator.apply(_pose())
	_place_blade()
	# Fallen: the whole of him topples forward from where he knelt.
	_model.rotation.z = -fallen * 1.42
	_model.position.y = fallen * 0.6   # (half sunk in the ink, his back breaking its skin)
	# His eyes in the helmet.
	var show_eyes := eyes > 0.01 and _head_bone >= 0 and fallen < 0.5
	for e: MeshInstance3D in _eye_glow:
		e.visible = show_eyes
		if show_eyes:
			var head := _animator.skeleton.global_transform * _animator.skeleton.get_bone_global_pose(_head_bone)
			var fwd := Vector3(facing, 0.0, 0.0)
			e.global_position = head.origin + Vector3(0.0, 0.12, 0.0) + fwd * 0.2 + Vector3(0.0, 0.0, (e.get_meta(&"side") as float) * 0.09)
			e.scale = Vector3.ONE * eyes
	if _flash > 0.0:
		_flash -= delta
	for m: MeshInstance3D in _meshes:
		m.material_overlay = PaperHusk.flash_overlay() if _flash > 0.0 else wash
	if _mode == &"recover" and _swoosh.visible:
		_update_swoosh(1.0)
	_drips.emitting = fallen < 0.5
	var raining := _mode in [&"sky_tell", &"sky"]
	if raining != _cloud.emitting:
		_cloud.emitting = raining
	if raining:
		_cloud.global_position = Vector3(ronin.global_position.x if ronin else global_position.x, floor_y + 5.6, -1.0)


func _place_blade() -> void:
	var skeleton := _animator.skeleton
	var at := skeleton.global_transform * _animator.sword_at
	var dir := (skeleton.global_transform.basis * _animator.sword_dir).normalized()
	if dir.length() < 0.1:
		dir = Vector3.UP
	var side := dir.cross(Vector3.BACK).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var s := model_height / 3.0 * 1.1
	_blade.global_transform = Transform3D(Basis(side, dir, side.cross(dir)).orthonormalized().scaled(Vector3.ONE * s), at)


func _pose() -> Dictionary:
	var t := _mode_time
	var p := _pace()
	match _mode:
		&"wait":
			return _wait_pose(_clock)
		&"guard":
			if absf(velocity.x) > 0.3:
				return SamuraiAnimator.with_upper_body(SamuraiAnimator.run(fmod(_clock * 0.55, 1.0)), _guard_pose(_clock))
			return _guard_pose(_clock)
		&"cleave_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), _raised_pose(), smoothstep(0.0, 0.8, t / (cleave_tell * p)))
		&"cleave":
			return SamuraiAnimator.mix(_raised_pose(), Hosho._crouch(), smoothstep(0.0, 0.18, t))
		&"sweep_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), Hosho._sweep_back(false), smoothstep(0.0, 0.7, t / (sweep_tell * p)))
		&"sweep":
			return SamuraiAnimator.mix(Hosho._sweep_back(false), Hosho._sweep_through(false), smoothstep(0.0, 1.0, t / sweep_time))
		&"charge_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), Hosho._thrust_back(), smoothstep(0.0, 0.6, t / (charge_tell * p)))
		&"charge":
			return SamuraiAnimator.with_upper_body(SamuraiAnimator.run(fmod(_clock * 1.4, 1.0)), Hosho._thrust_out())
		&"sky_tell", &"sky":
			var u := smoothstep(0.0, 0.8, t / (sky_tell * p)) if _mode == &"sky_tell" else 1.0
			return SamuraiAnimator.mix(_guard_pose(_clock), _sky_pose(_clock), u)
		&"muster":
			return SamuraiAnimator.mix(_guard_pose(_clock), _plunge_pose(), smoothstep(0.0, 0.3, t))
		&"forget", &"remember":
			var lost := _sag_pose(_clock)
			if _mode == &"remember":
				return SamuraiAnimator.mix(lost, _guard_pose(_clock), smoothstep(0.0, 1.0, t / 0.35))
			return SamuraiAnimator.mix(_guard_pose(_clock), lost, smoothstep(0.0, 1.0, t / 0.5))
		&"recover":
			return SamuraiAnimator.mix(Hosho._crouch(), _guard_pose(_clock), smoothstep(0.0, 1.0, t / 0.9))
		&"stagger":
			return SamuraiAnimator.mix(SamuraiAnimator.hurt(), Hosho._kneel_pose(0.0), smoothstep(0.0, 0.5, t))
		&"defeated":
			return Hosho._kneel_pose(_kneel)
	return _guard_pose(_clock)


## How far his head lifts as he kneels beaten (the ending). 0 bowed, 1 up.
func set_kneel(lift: float) -> void:
	_kneel = lift


func set_fallen(amount: float) -> void:
	fallen = amount


# His stances (in Hōshō's measure: scaled up by the animator).

static func _wait_pose(time: float) -> Dictionary:
	var breath := sin(time * 0.9)
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.06 + breath * 0.008, 0.0), "hips_rot": Vector3(10.0, 0.0, 0.0),
		"spine": Vector3(16.0, 0.0, 0.0), "head": Vector3(24.0, 0.0, 0.0),
		"foot_l": Vector3(0.18, 0.0, 0.04), "foot_r": Vector3(-0.18, 0.0, -0.02),
		"hand_r": Vector3(-0.16, 0.12, 0.3), "hand_l": Vector3(0.0, 0.18, 0.34),
		"blade": Vector3(0.0, -0.9, 0.35), "blade_out": 1.0})


## His guard: heavy, low, the nodachi held out in front, its point dipping
## (it is very heavy and he is very tired).
static func _guard_pose(time: float) -> Dictionary:
	var breath := sin(time * 1.3)
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.14 + breath * 0.012, 0.0), "hips_rot": Vector3(10.0, 12.0, 0.0),
		"spine": Vector3(12.0, -6.0, 0.0), "head": Vector3(6.0, -4.0, 0.0),
		"foot_l": Vector3(0.2, 0.0, 0.26), "foot_r": Vector3(-0.16, 0.0, -0.24),
		"hand_r": Vector3(-0.06, 0.12, 0.3), "hand_l": Vector3(0.04, 0.16, 0.42),
		"blade": Vector3(0.0, 0.2 + breath * 0.04, 0.98), "blade_out": 1.0})


## The cleave's wind-up: the nodachi lifted high over his right shoulder,
## its point back and up, both hands on the long grip above his head, his
## chest open, leaning back a little under its weight.
static func _raised_pose() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.1, -0.04), "hips_rot": Vector3(-6.0, 18.0, 0.0),
		"spine": Vector3(-10.0, 10.0, 0.0), "head": Vector3(-8.0, -10.0, 0.0),
		"foot_l": Vector3(0.2, 0.0, 0.3), "foot_r": Vector3(-0.16, 0.0, -0.26),
		"hand_r": Vector3(-0.12, 0.82, -0.02), "hand_l": Vector3(-0.02, 0.9, 0.12),
		"blade": Vector3(0.0, 0.62, -0.78), "blade_out": 1.0})


## The Drowned Muster: the nodachi held point-down in both hands, driven
## into the ink before him, his weight bowed over it.
static func _plunge_pose() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.3, 0.06), "hips_rot": Vector3(20.0, 0.0, 0.0),
		"spine": Vector3(24.0, 0.0, 0.0), "head": Vector3(10.0, 0.0, 0.0),
		"foot_l": Vector3(0.22, 0.0, 0.2), "foot_r": Vector3(-0.2, 0.0, -0.16),
		"hand_r": Vector3(-0.04, 0.0, 0.5), "hand_l": Vector3(0.04, 0.12, 0.5),
		"blade": Vector3(0.0, -1.0, 0.12), "blade_out": 1.0})


## The weeping sky: face and arms lifted to the Rain, the blade held up.
static func _sky_pose(time: float) -> Dictionary:
	var sway := sin(time * 2.0) * 3.0
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.08, 0.0), "hips_rot": Vector3(-6.0, sway, 0.0),
		"spine": Vector3(-14.0, 0.0, 0.0), "head": Vector3(-34.0, 0.0, 0.0),
		"foot_l": Vector3(0.22, 0.0, 0.1), "foot_r": Vector3(-0.22, 0.0, -0.08),
		"hand_r": Vector3(-0.42, 0.8, 0.1), "hand_l": Vector3(0.46, 0.76, 0.1),
		"blade": Vector3(0.0, 1.0, -0.1), "blade_out": 1.0})


## Lost: his arms sag, the blade's point drops into the ink, his head
## tilts to one side as if listening for something he has forgotten.
static func _sag_pose(time: float) -> Dictionary:
	var drift := sin(time * 0.8) * 4.0
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.2, 0.0), "hips_rot": Vector3(16.0, 4.0, 0.0),
		"spine": Vector3(18.0, 0.0, 6.0), "head": Vector3(10.0, 16.0 + drift, 22.0),
		"foot_l": Vector3(0.2, 0.0, 0.1), "foot_r": Vector3(-0.18, 0.0, -0.06),
		"hand_r": Vector3(-0.24, -0.12, 0.16), "hand_l": Vector3(0.24, -0.16, 0.06),
		"blade": Vector3(0.0, -0.85, 0.5), "blade_out": 1.0})
