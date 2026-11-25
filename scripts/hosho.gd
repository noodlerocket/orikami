class_name Hosho
extends CharacterBody3D
## Hōshō, 宝照, the Gilded General (docs/lore.md): one of the Emperor's
## three generals, holder of one of his seals, lord of the Lantern Market.
## He hides from the Rain under gold leaf and can no longer feel anything.
## Julian's four views (docs/reference/hosho_*): a gold mask, a helmet
## crowned with a lantern, rows of lit lanterns along his shoulders, red
## tassels, a long coat of torn paper strips and gold leaf painted with plum
## blossom, a naginata with a curved gold blade. A Meshy model
## (models/hosho.glb, 3 m, rigged), posed by hand with SamuraiAnimator; the
## naginata (Meshy dropped it) is folded here and held along the pose's
## blade line, his right hand on the shaft.
##
## His moves, each with its tell (HoshoHall runs the fight round him):
##  - the sweep: he draws the naginata back high (duck under it) or low and
##    trailing (jump it), a glint runs along the blade, then the great blade
##    sweeps round in front of him; parry it (posture). From half health he
##    sweeps twice, high then low or low then high;
##  - the thrust: from afar he levels it and lunges across the floor; parry
##    it (double posture);
##  - the lantern volley: he lifts his hand and the lanterns on his shoulders
##    fly at him burning, three in a rhythm (parry them back at him, or blow
##    them back with the Fan Gust);
##  - the gold storm: he whirls the naginata over his head and gold leaf
##    whirls round him, cutting; keep away, or break it with the Fan Gust
##    (posture);
##  - the leap: he crouches, leaps high, hangs over him (a gold ring marks
##    where he will land) and slams down; the floor shakes round him.
## Posture full: he sinks to one knee, mask down, for a finishing cut.

signal health_changed(current: int, maximum: int)
signal posture_changed(current: int, maximum: int)
signal defeated
## From half health, his gold wave (HoshoHall rolls it along the floor):
## `wave_coming` as he raises the naginata, `wave_sent` as he sweeps it.
signal wave_coming(low: bool)
signal wave_sent(low: bool)
## At half health he slams the naginata's butt on the floor: his second wind.
signal roused

@export_group("Fight")
@export var max_health := 40
@export var max_posture := 8
@export var finish_damage := 4
@export var posture_recover_time := 2.5
@export var contact_damage := 1
## Rest between moves, and how much quicker everything is from half health.
@export var rest_time := 0.9
@export var enraged_pace := 0.78
@export_group("Sweep")
@export var sweep_tell := 0.46   # (0.62: too slow, Julian)
@export var sweep_time := 0.26
@export var sweep_reach := 4.2
@export_group("Thrust")
@export var thrust_tell := 0.52   # (0.7: too slow)
@export var thrust_speed := 14.0
@export var thrust_time := 0.42
@export_group("Lanterns")
@export var lantern_tell := 0.45   # (0.6: too slow)
@export var lantern_gap := 0.36
@export_group("Gold storm")
@export var storm_tell := 0.6   # (0.8: too slow)
@export var storm_time := 1.8
@export var storm_radius := 2.6
@export_group("Leap")
@export var leap_tell := 0.38   # (0.5: too slow)
@export var leap_rise := 6.0
@export var leap_hang := 0.35
@export var slam_reach := 3.0
## How fast the leap's landing spot follows him, and how long before the
## slam it stops following (the moment he has to get out from under).
@export var leap_track_speed := 11.0
@export var leap_lock := 0.14
@export_group("Gold wave")
@export var wave_tell := 0.72   # (0.95: too slow)
@export_group("Stagger")
@export var stagger_time := 3.0
@export_group("Model")
@export var model_height := 3.0
@export var walk_speed := 2.4
@export var gravity := 38.0

var active := false
var health := 0
var posture := 0
var facing := -1.0
var ronin: Ronin
## The fighting ground (global x).
var bounds := Vector2(-INF, INF)
var floor_y := 0.0

var _mode := &"wait"
var _mode_time := 0.0
var _clock := 0.0
var _rng := RandomNumberGenerator.new()
var _model: Node3D
var _meshes: Array[MeshInstance3D] = []
var _animator: SamuraiAnimator
var _naginata: Node3D
var _swoosh: MeshInstance3D
var _swoosh_look: ShaderMaterial
var _storm: CPUParticles3D
var _ring: MeshInstance3D
var _flash := 0.0
var _posture_clock := 0.0
var _high := true
var _second := false
var _hit_done := false
var _thrown := 0
var _from := Vector3.ZERO
var _target_x := 0.0
var _storm_tick := 0.0
var _moves_since_wave := 0
var _enraged := false
var _swat := 0.0
var _kneel := 0.0
var _rouse_pending := false
var _wave_low := false
## Gold flecks shed by the blade as it moves; the gleam gathering at its tip.
var _trail: CPUParticles3D
var _glint: MeshInstance3D
var _glint_size := 0.0
## Laid over his paper while not flashing (the ending's wash: HoshoHall).
var wash: Material


func _ready() -> void:
	_rng.seed = 4545
	collision_layer = 4
	collision_mask = 1
	health = max_health
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = model_height * 0.92
	shape.shape = capsule
	shape.position.y = model_height * 0.46
	add_child(shape)
	_build_model()
	_build_naginata()
	_build_effects()


# --- The model ----------------------------------------------------------------------

func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	var figure: Node3D = (preload("res://models/hosho.glb") as PackedScene).instantiate()
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
		paper.roughness = 0.55
		paper.metallic = 0.25
		paper.metallic_specular = 0.6
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, paper)
		_meshes.append(node)
	var units := 1.0 / (grow * PaperHusk._local_scale(skeleton, figure))
	_animator = SamuraiAnimator.new(skeleton, units)
	_animator.apply(_wait_pose(0.0))


## The naginata: a long lacquered shaft banded in gold, a red tassel, and the
## curved gold blade, folded from stiff gilded paper. Its local +Y runs from
## the butt toward the blade; its origin is where his right hand holds it.
func _build_naginata() -> void:
	_naginata = Node3D.new()
	_naginata.top_level = true
	add_child(_naginata)
	var b := PaperMesh.new(606)
	b.shade_jitter = 0.12
	b.color = Color(0.16, 0.08, 0.07)
	b.box(Vector3(0.0, 0.3, 0.0), Vector3(0.07, 2.6, 0.07))
	b.color = Color(0.86, 0.68, 0.34)
	for y: float in [-0.95, -0.3, 0.5, 1.2, 1.58]:
		b.box(Vector3(0.0, y, 0.0), Vector3(0.085, 0.06, 0.085))
	b.frustum(6, Vector2(0.05, 0.05), Vector2(0.03, 0.03), 0.12, Vector3(0.0, -1.12, 0.0))
	# The guard, a gold disc.
	b.frustum(12, Vector2(0.13, 0.08), Vector2(0.13, 0.08), 0.04, Vector3(0.0, 1.6, 0.0))
	# The blade: a long curve, broad near its tip, edged pale.
	var edge := PackedVector2Array()
	var back := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		var y := 1.64 + t * 1.15
		var curve := 0.28 * t * t
		var width := 0.07 + 0.08 * sin(PI * minf(t * 1.1, 1.0))
		edge.append(Vector2(-curve + width * 0.5, y))
		back.append(Vector2(-curve - width * 0.5, y))
	var outline := PackedVector2Array()
	outline.append_array(edge)
	back.reverse()
	outline.append_array(back)
	b.color = Color(0.92, 0.78, 0.42)
	b.extrude(outline, -0.012, 0.012)
	b.color = Color(1.0, 0.95, 0.8)
	for k in 12:
		b.stroke(edge[k], edge[k + 1], 0.012, 0.012, 0.014)
		b.stroke(edge[k], edge[k + 1], 0.012, 0.012, -0.014)
	var mesh := b.build()
	(mesh.material_override as StandardMaterial3D).metallic = 0.7
	(mesh.material_override as StandardMaterial3D).roughness = 0.3
	_naginata.add_child(mesh)
	# The red tassel under the guard, swinging.
	var tassel := Node3D.new()
	tassel.position = Vector3(0.0, 1.55, 0.0)
	tassel.name = "Tassel"
	_naginata.add_child(tassel)
	var t := PaperMesh.new(607)
	t.color = Color(0.62, 0.14, 0.12)
	for k in 5:
		t.box(Vector3((k - 2) * 0.015, -0.22, 0.0), Vector3(0.012, 0.44, 0.012))
	t.color = Color(0.86, 0.68, 0.34)
	t.box(Vector3(0.0, -0.01, 0.0), Vector3(0.06, 0.05, 0.06))
	tassel.add_child(t.build())
	# Gold leaf shed by the blade as it cuts (more once he is roused).
	_trail = CPUParticles3D.new()
	_trail.amount = 36
	_trail.lifetime = 0.7
	_trail.emitting = false
	_trail.local_coords = false
	_trail.position = Vector3(-0.2, 2.4, 0.0)
	_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_trail.emission_box_extents = Vector3(0.08, 0.4, 0.05)
	_trail.gravity = Vector3(0.0, -2.5, 0.0)
	_trail.initial_velocity_max = 0.6
	_trail.angular_velocity_min = -500.0
	_trail.angular_velocity_max = 500.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.9, 0.6, 1.0))
	fade.set_color(1, Color(0.9, 0.66, 0.3, 0.0))
	_trail.color_ramp = fade
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.06, 0.045)
	var gilt := StandardMaterial3D.new()
	gilt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gilt.vertex_color_use_as_albedo = true
	gilt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gilt.cull_mode = BaseMaterial3D.CULL_DISABLED
	gilt.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.material = gilt
	_trail.mesh = leaf
	_naginata.add_child(_trail)
	# The gleam at the blade's tip: light gathering before a big cut.
	var glow := QuadMesh.new()
	glow.size = Vector2(1.0, 1.0)
	var shine := PaperMesh.soft_ink(Color(1.0, 0.84, 0.5, 0.9), BaseMaterial3D.BILLBOARD_ENABLED)
	shine.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.material = shine
	_glint = MeshInstance3D.new()
	_glint.mesh = glow
	_glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint.position = Vector3(-0.22, 2.55, 0.0)
	_glint.scale = Vector3.ZERO
	_naginata.add_child(_glint)


func _build_effects() -> void:
	# The sweep's swoosh: a gold crescent drawn on round in front of him.
	var strip := SurfaceTool.new()
	strip.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 20
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var a := lerpf(deg_to_rad(150.0), deg_to_rad(-25.0), t)
			var r := lerpf(2.4, 3.9, corner[1])
			strip.set_uv(Vector2(t, corner[1]))
			strip.add_vertex(Vector3(cos(a) * r, sin(a) * r * 0.55, 0.0))
	_swoosh = MeshInstance3D.new()
	_swoosh.mesh = strip.commit()
	_swoosh_look = ShaderMaterial.new()
	_swoosh_look.shader = preload("res://shaders/slash_sweep.gdshader")
	_swoosh_look.set_shader_parameter(&"tint", Color(1.0, 0.86, 0.5, 0.85))
	_swoosh.material_override = _swoosh_look
	_swoosh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_swoosh.top_level = true
	_swoosh.visible = false
	add_child(_swoosh)
	# The gold storm: leaf whirling round him.
	_storm = CPUParticles3D.new()
	_storm.amount = 120
	_storm.lifetime = 1.0
	_storm.emitting = false
	_storm.local_coords = false
	_storm.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_storm.emission_ring_axis = Vector3.UP
	_storm.emission_ring_radius = storm_radius * 0.8
	_storm.emission_ring_inner_radius = 0.6
	_storm.emission_ring_height = 1.2   # (round the blade, at his chest)
	_storm.gravity = Vector3.ZERO
	_storm.orbit_velocity_min = 1.2
	_storm.orbit_velocity_max = 1.8
	_storm.angular_velocity_min = -600.0
	_storm.angular_velocity_max = 600.0
	_storm.initial_velocity_max = 0.4
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.09, 0.06)
	var gilt := StandardMaterial3D.new()
	gilt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gilt.albedo_color = Color(1.0, 0.82, 0.42)
	gilt.cull_mode = BaseMaterial3D.CULL_DISABLED
	gilt.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.material = gilt
	_storm.mesh = leaf
	_storm.position.y = 1.0
	add_child(_storm)
	# The ring where he will land.
	# (A flat oval on the floor: as wide as the slam reaches, shallow in
	# depth; a bright rim, a faint fill. A soft glow here did not show on
	# the red floor.)
	var band := SurfaceTool.new()
	band.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 48
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for r: Array in [[0.82, 1.0, 1.0], [0.0, 0.82, 0.3]]:
			var o0 := Vector3(cos(a0) * slam_reach, 0.0, sin(a0) * 1.1)
			var o1 := Vector3(cos(a1) * slam_reach, 0.0, sin(a1) * 1.1)
			band.set_color(Color(1.0, 1.0, 1.0, r[2]))
			band.add_vertex(o0 * r[0]); band.add_vertex(o1 * r[1]); band.add_vertex(o0 * r[1])
			band.add_vertex(o0 * r[0]); band.add_vertex(o1 * r[0]); band.add_vertex(o1 * r[1])
	var ring_look := StandardMaterial3D.new()
	ring_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_look.vertex_color_use_as_albedo = true
	ring_look.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD   # (it glows on the red boards)
	ring_look.albedo_color = Color(1.0, 0.88, 0.55, 0.0)
	var disc := band.commit()
	disc.surface_set_material(0, ring_look)
	_ring = MeshInstance3D.new()
	_ring.mesh = disc
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(1.0, 0.8, 0.45)
	glow.omni_range = slam_reach + 0.5
	glow.position.y = 0.6
	_ring.add_child(glow)


# --- Outside -----------------------------------------------------------------------

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
	_rouse_pending = false
	_moves_since_wave = 0
	_trail.amount = 36
	global_position = at
	velocity = Vector3.ZERO
	facing = -1.0
	_storm.emitting = false
	_ring.visible = false
	_swoosh.visible = false
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
	if _mode == &"stagger":
		health -= finish_damage
		posture = 0
		posture_changed.emit(posture, max_posture)
		Confetti.burst(get_parent(), global_position + Vector3(0.0, 1.8, 0.0), 50, [Color(1.0, 0.82, 0.42), Color(0.86, 0.68, 0.34), Color(0.62, 0.14, 0.12)])
		Sound.play(self, &"paper_burst", 2.0)
		_set_mode(&"recover")
	else:
		health -= damage
		# Gold leaf flakes off where he is cut.
		Confetti.burst(get_parent(), global_position + Vector3(-signf(direction.x) * 0.3, 1.6, 0.0), 6, [Color(1.0, 0.82, 0.42)])
	_flash = 0.12
	health_changed.emit(maxi(health, 0), max_health)
	if health <= 0:
		_fall()
		return
	if not _enraged and health <= max_health / 2:
		_enraged = true
		_rouse_pending = true   # (at his next move: never in the air)


func _parried(cost: int) -> void:
	posture = mini(posture + cost, max_posture)
	_posture_clock = 0.0
	posture_changed.emit(posture, max_posture)
	velocity.x = -facing * 3.0
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger", 4.0)
		_storm.emitting = false
		_swoosh.visible = false


func _fall() -> void:
	active = false
	velocity = Vector3.ZERO
	# (Beaten, his body is not something to cut.)
	collision_layer = 0
	remove_from_group(&"gust_target")
	_storm.emitting = false
	_ring.visible = false
	_swoosh.visible = false
	_set_mode(&"defeated")
	posture = 0
	posture_changed.emit(posture, max_posture)
	defeated.emit()


## The Fan Gust breaks his gold storm (it is only leaf): posture.
func gusted(direction: Vector3, _from_point: Vector3) -> void:
	if _mode == &"storm" and signf(direction.x) == -facing:
		_storm.emitting = false
		Sound.play(self, &"paper_rip", 0.0)
		_parried(2)
		if _mode != &"stagger":
			_set_mode(&"recover")


# --- Thinking ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_clock += delta
	_mode_time += delta
	_swat = maxf(_swat - delta, 0.0)
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if ronin and not is_in_group(&"gust_target"):
			add_to_group(&"gust_target")
	if not is_on_floor() and _mode not in [&"leap", &"hang", &"slam"]:
		velocity.y -= gravity * delta
	if active:
		_think(delta)
	if _mode not in [&"leap", &"hang", &"slam"]:
		move_and_slide()
		global_position.x = clampf(global_position.x, bounds.x, bounds.y)
	position.z = 0.0
	if active and _mode not in [&"stagger", &"defeated", &"leap", &"hang"]:
		_touch_check()


func _think(delta: float) -> void:
	var dx := ronin.global_position.x - global_position.x if ronin else 0.0
	var dist := absf(dx)
	if _mode not in [&"stagger", &"defeated"]:
		_posture_clock += delta
		if posture > 0 and _posture_clock > posture_recover_time:
			_posture_clock = 0.0
			posture -= 1
			posture_changed.emit(posture, max_posture)
	match _mode:
		&"guard":
			if absf(dx) > 0.3:
				facing = signf(dx)
			# Keep a spear's length off him.
			var want := 0.0
			if dist > 4.0:
				want = walk_speed
			elif dist < 2.4:
				want = -walk_speed * 0.6
			velocity.x = move_toward(velocity.x, facing * want, 10.0 * delta)
			if _mode_time > rest_time * _pace():
				_choose(dist)
		&"sweep_tell":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time > sweep_tell * _pace() * (0.6 if _second else 1.0):
				_set_mode(&"sweep")
				_swoosh.visible = true
				Sound.play(self, &"akane_slash", 2.0)
		&"sweep":
			velocity.x = facing * 2.0
			var u := clampf(_mode_time / sweep_time, 0.0, 1.0)
			_update_swoosh(u, 1.0)
			if not _hit_done and u > 0.3:
				var band := Vector2(1.15, 2.7) if _high else Vector2(0.0, 0.85)
				_strike(Vector3(facing * sweep_reach * 0.5, (band.x + band.y) * 0.5, 0.0), Vector3(sweep_reach, band.y - band.x, 1.6), 1, &"cut")
			if _mode_time > sweep_time:
				if _enraged and not _second:
					_second = true
					_high = not _high
					_set_mode(&"sweep_tell")
				else:
					_second = false
					_set_mode(&"recover")
		&"thrust_tell":
			velocity.x = move_toward(velocity.x, -facing * 1.0, 10.0 * delta)
			if _mode_time > thrust_tell * _pace():
				_set_mode(&"thrust")
				Sound.play(self, &"hosho_lunge", 2.0)   # (Akane's draw here: not liked)
		&"thrust":
			velocity.x = facing * thrust_speed
			if not _hit_done:
				_strike(Vector3(facing * 2.2, 1.4, 0.0), Vector3(2.4, 1.4, 1.6), 2, &"cut")
			if _mode_time > thrust_time or is_on_wall():
				_set_mode(&"recover")
		&"lantern_tell":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time > lantern_tell * _pace():
				_set_mode(&"lanterns")
				_thrown = 0
		&"lanterns":
			if _thrown < 3 and _mode_time > _thrown * lantern_gap * _pace():
				_throw_lantern()
				_thrown += 1
			if _mode_time > 3 * lantern_gap * _pace() + 0.4:
				_set_mode(&"recover")
		&"storm_tell":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time > storm_tell * _pace():
				_set_mode(&"storm")
				_storm.emitting = true
				_storm_tick = 0.0
				Sound.play(self, &"fire_whoosh", 2.0)
		&"storm":
			velocity.x = move_toward(velocity.x, signf(dx) * 2.2, 8.0 * delta)
			_storm_tick -= delta
			if _storm_tick <= 0.0:
				_storm_tick = 0.35
				# (Level with the Ronin's chest: jumping clear of it works.)
				if ronin and dist < storm_radius and ronin.global_position.y - global_position.y < 1.25:
					ronin.take_damage(1, global_position + Vector3(0.0, 1.4, 0.0), &"cut")
				Sound.play(self, &"paper_rip", -10.0)
			if _mode_time > storm_time:
				_storm.emitting = false
				_set_mode(&"recover")
		&"leap_tell":
			velocity.x = 0.0
			if _mode_time > leap_tell * _pace():
				_from = global_position
				_target_x = clampf(ronin.global_position.x if ronin else global_position.x, bounds.x + 1.0, bounds.y - 1.0)
				_set_mode(&"leap")
				Sound.play(self, &"jump", 4.0)
		&"leap":
			var k := minf(_mode_time / 0.6, 1.0)
			_follow(delta)
			global_position = Vector3(lerpf(_from.x, _target_x, k), _from.y + leap_rise * sin(k * PI * 0.5), 0.0)
			_ring.visible = true
			_ring.global_position = Vector3(_target_x, floor_y + 0.07, 0.4)
			_ring_strength(0.5 * k)
			if k >= 1.0:
				_set_mode(&"hang")
		&"hang":
			# Over him; the ring on the floor follows him until just before
			# the slam, then holds (brighter): the moment to get out.
			var locked := _mode_time > leap_hang * _pace() - leap_lock
			if not locked:
				_follow(delta)
			global_position = Vector3(_target_x, _from.y + leap_rise + 0.1 * sin(_mode_time * 20.0), 0.0)
			_ring.global_position = Vector3(_target_x, floor_y + 0.07, 0.4)
			_ring_strength((0.85 + 0.15 * sin(_mode_time * 40.0)) if locked else 0.6)
			if _mode_time > leap_hang * _pace():
				_set_mode(&"slam")
		&"slam":
			var k := minf(_mode_time / 0.18, 1.0)
			global_position = Vector3(_target_x, lerpf(_from.y + leap_rise, floor_y, k * k), 0.0)
			if k >= 1.0:
				_land()
		&"recover":
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			_swoosh.visible = false
			if _mode_time > 0.7 * _pace():
				_set_mode(&"guard")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			if _mode_time > stagger_time:
				posture = 0
				posture_changed.emit(posture, max_posture)
				_set_mode(&"recover")
		&"rouse":
			# Up goes the naginata; down comes its butt on the floor.
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if not _hit_done and _mode_time > 0.62:
				_hit_done = true
				roused.emit()
				_trail.amount = 80
				Sound.play(self, &"taiko_hit", 6.0)
				Sound.play(self, &"land", 4.0)
				Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.3, 0.0), 70,
						[Color(1.0, 0.82, 0.42), Color(0.86, 0.68, 0.34), Color(1.0, 0.95, 0.8)])
				var camera := get_viewport().get_camera_3d()
				if camera and camera.has_method("add_shake"):
					camera.call("add_shake", 0.9)
			if _mode_time > 1.9:
				_set_mode(&"guard")
		&"wave_tell":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time > wave_tell * _pace():
				_high = not _wave_low
				_set_mode(&"wave")
				_swoosh.visible = true
				wave_sent.emit(_wave_low)
				Sound.play(self, &"akane_slash", 4.0)
		&"wave":
			velocity.x = facing * 3.0
			_update_swoosh(clampf(_mode_time / sweep_time, 0.0, 1.0), 1.0)
			if _mode_time > sweep_time:
				_set_mode(&"recover")


func _choose(dist: float) -> void:
	if _rouse_pending:
		_rouse_pending = false
		_moves_since_wave = 3
		_set_mode(&"rouse")
		return
	_moves_since_wave += 1
	if _enraged and _moves_since_wave >= 4:
		_moves_since_wave = 0
		_wave_low = _rng.randf() < 0.5
		if absf(ronin.global_position.x - global_position.x) > 0.3:
			facing = signf(ronin.global_position.x - global_position.x)
		_set_mode(&"wave_tell")
		wave_coming.emit(_wave_low)
		Sound.play(self, &"draw_gleam", 2.0)
		return
	var roll := _rng.randf()
	if dist > 5.5:
		if roll < 0.4:
			_set_mode(&"thrust_tell")
		elif roll < 0.75:
			_set_mode(&"lantern_tell")
		else:
			_set_mode(&"leap_tell")
	elif dist > 2.6:
		if roll < 0.5:
			_start_sweep()
		elif roll < 0.7:
			_set_mode(&"storm_tell")
		elif roll < 0.85:
			_set_mode(&"lantern_tell")
		else:
			_set_mode(&"leap_tell")
	else:
		if roll < 0.6:
			_start_sweep()
		elif roll < 0.85:
			_set_mode(&"storm_tell")
		else:
			_set_mode(&"leap_tell")
	if _mode == &"sweep_tell" or _mode == &"thrust_tell":
		Sound.play(self, &"draw_gleam", -2.0)


## How bright the landing ring (and its light on the boards) is.
func _ring_strength(a: float) -> void:
	((_ring.mesh as ArrayMesh).surface_get_material(0) as StandardMaterial3D).albedo_color.a = a
	(_ring.get_node("Glow") as OmniLight3D).light_energy = a * 2.5


## The leap's landing spot moves toward him (never faster than he can run).
func _follow(delta: float) -> void:
	if ronin:
		_target_x = clampf(move_toward(_target_x, ronin.global_position.x, leap_track_speed * delta), bounds.x + 1.0, bounds.y - 1.0)


func _start_sweep() -> void:
	_high = _rng.randf() < 0.5
	_second = false
	_set_mode(&"sweep_tell")


## Anything of his inside his blow (a box, relative to him, the way he
## faces). Parried: posture.
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
		if target.receive_strike(1, global_position + Vector3(0.0, 1.4, 0.0), kind):
			_parried(cost)
			_spark()
		return


func _spark() -> void:
	Confetti.burst(get_parent(), global_position + Vector3(facing * 1.6, 1.5, 0.3), 12, [Color(1.0, 0.86, 0.5), Color(1.0, 0.95, 0.75)])


## One of the lanterns off his shoulders, thrown burning at him in an arc.
func _throw_lantern() -> void:
	if ronin == null:
		return
	var fire := BurningPaper.new()
	fire.thrower = self
	get_parent().add_child(fire)
	var from := global_position + Vector3(facing * 0.4, model_height * 0.8, 0.0)
	fire.global_position = from
	var to := ronin.global_position + Vector3(_rng.randf_range(-0.5, 0.5), 0.8, 0.0)
	var t := clampf(absf(to.x - from.x) / 9.0, 0.5, 1.0)
	fire.velocity = Vector3((to.x - from.x) / t, (to.y - from.y) / t + fire.gravity * t * 0.5, 0.0)
	Sound.play(self, &"fox_fire", 0.0)


func _land() -> void:
	_ring.visible = false
	_set_mode(&"recover")
	_mode_time = -0.5   # (he stays down a moment: the chance to cut him)
	Sound.play(self, &"taiko_hit", 4.0)
	Sound.play(self, &"land", 6.0)
	Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.2, 0.0), 30, [Color(1.0, 0.82, 0.42), Color(0.5, 0.46, 0.5)])
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("add_shake"):
		camera.call("add_shake", 0.6)
	if ronin:
		var dx := absf(ronin.global_position.x - global_position.x)
		var dy := ronin.global_position.y - floor_y
		if (dx < 1.2 and dy < 3.0) or (dx < slam_reach and dy < 0.4 and ronin.is_on_floor()):
			ronin.take_damage(1, global_position + Vector3(0.0, 0.5, 0.0), &"cut")


## Walking into him: he shoves him off with the shaft.
func _touch_check() -> void:
	if ronin == null or _swat > 0.0:
		return
	var rel := ronin.global_position - global_position
	if absf(rel.x) < 0.75 and rel.y > -0.5 and rel.y < model_height * 0.9:
		_swat = 1.0
		ronin.take_damage(contact_damage, global_position + Vector3(0.0, 1.4, 0.0), &"cut")


func _update_swoosh(u: float, alpha: float) -> void:
	var low := 0.0 if _high else -1.25
	var turn := Basis.IDENTITY if facing > 0.0 else Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
	_swoosh.global_transform = Transform3D(turn, global_position + Vector3(0.0, 1.9 + low, 0.35))
	_swoosh_look.set_shader_parameter(&"head", clampf(u * 1.6, 0.0, 1.05))
	_swoosh_look.set_shader_parameter(&"tail", clampf((u - 0.45) * 1.9, 0.0, 1.05))
	_swoosh_look.set_shader_parameter(&"tint", Color(1.0, 0.86, 0.5, 0.85 * alpha))


# --- How he looks --------------------------------------------------------------------

func _process(delta: float) -> void:
	_model.rotation.y = 0.0 if facing > 0.0 else PI
	# Fallen: he topples forward from his knees onto the floor, lifeless.
	_model.rotation.z = -fallen * 1.45
	_model.position.y = fallen * 0.3
	if _mode == &"storm":
		_model.rotation.y += _mode_time * 14.0
	_animator.apply(_pose())
	_place_naginata()
	if _mode == &"recover" and _swoosh.visible:
		_update_swoosh(1.0, 1.0)
	if _flash > 0.0:
		_flash -= delta
	for m: MeshInstance3D in _meshes:
		m.material_overlay = PaperHusk.flash_overlay() if _flash > 0.0 else wash
	_trail.emitting = _mode in [&"sweep", &"thrust", &"wave", &"storm", &"slam", &"rouse"] \
			or (_enraged and _mode == &"guard" and absf(velocity.x) > 0.3)
	# The gleam: big while gold gathers for the wave, a wink before a cut.
	var want := 0.0
	match _mode:
		&"wave_tell":
			want = 0.4 + 1.6 * clampf(_mode_time / 0.9, 0.0, 1.0) + sin(_clock * 40.0) * 0.12
		&"sweep_tell", &"thrust_tell":
			want = 0.7 * sin(PI * clampf(_mode_time / 0.45, 0.0, 1.0))
		&"rouse":
			want = 1.4 if _mode_time < 0.62 else 0.0
	_glint_size = lerpf(_glint_size, want, minf(1.0, delta * 14.0))
	_glint.scale = Vector3.ONE * maxf(_glint_size, 0.0)
	_glint.visible = _glint_size > 0.02
	var tassel := _naginata.get_node("Tassel") as Node3D
	tassel.rotation.z = sin(_clock * 3.1) * 0.2 - clampf(velocity.x * 0.03, -0.4, 0.4)


func _place_naginata() -> void:
	var skeleton := _animator.skeleton
	var at := skeleton.global_transform * _animator.sword_at
	var dir := (skeleton.global_transform.basis * _animator.sword_dir).normalized()
	if dir.length() < 0.1:
		dir = Vector3.UP
	var side := dir.cross(Vector3.BACK).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var s := model_height / 3.0 * 1.15
	_naginata.global_transform = Transform3D(Basis(side, dir, side.cross(dir)).orthonormalized().scaled(Vector3.ONE * s), at)


func _pose() -> Dictionary:
	var t := _mode_time
	match _mode:
		&"wait":
			return _wait_pose(_clock)
		&"guard":
			if absf(velocity.x) > 0.3:
				return SamuraiAnimator.with_upper_body(SamuraiAnimator.run(fmod(_clock * 0.9, 1.0)), _guard_pose(_clock))
			return _guard_pose(_clock)
		&"sweep_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), _sweep_back(_high), smoothstep(0.0, 0.7, t / (sweep_tell * _pace())))
		&"sweep":
			return SamuraiAnimator.mix(_sweep_back(_high), _sweep_through(_high), smoothstep(0.0, 1.0, t / sweep_time))
		&"thrust_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), _thrust_back(), smoothstep(0.0, 0.6, t / (thrust_tell * _pace())))
		&"thrust":
			return _thrust_out()
		&"lantern_tell", &"lanterns":
			return SamuraiAnimator.mix(_guard_pose(_clock), _beckon(), smoothstep(0.0, 0.5, t / maxf(lantern_tell * _pace(), 0.01)) if _mode == &"lantern_tell" else 1.0)
		&"storm_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), _spin_pose(), smoothstep(0.0, 1.0, t / (storm_tell * _pace())))
		&"storm":
			return _spin_pose()
		&"leap_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), _crouch(), smoothstep(0.0, 1.0, t / (leap_tell * _pace())))
		&"leap", &"hang":
			return _airborne()
		&"slam":
			return _crouch()
		&"recover":
			if _swoosh.visible:
				return SamuraiAnimator.mix(_sweep_through(_high), _guard_pose(_clock), smoothstep(0.0, 1.0, t / 0.7))
			return SamuraiAnimator.mix(_crouch(), _guard_pose(_clock), smoothstep(0.0, 1.0, maxf(t, 0.0) / 0.7))
		&"stagger":
			return SamuraiAnimator.mix(SamuraiAnimator.hurt(), _kneel_pose(0.0), smoothstep(0.0, 0.4, t))
		&"rouse":
			if t < 0.5:
				return SamuraiAnimator.mix(_guard_pose(_clock), _overhead(), smoothstep(0.0, 1.0, t / 0.5))
			if t < 0.62:
				return _overhead()
			if t < 1.35:
				return SamuraiAnimator.mix(_overhead(), _plant(), smoothstep(0.0, 1.0, (t - 0.5) / 0.12))
			return SamuraiAnimator.mix(_plant(), _guard_pose(_clock), smoothstep(0.0, 1.0, (t - 1.35) / 0.55))
		&"wave_tell":
			return SamuraiAnimator.mix(_guard_pose(_clock), _sweep_back(not _wave_low), smoothstep(0.0, 0.5, t / (wave_tell * _pace())))
		&"wave":
			return SamuraiAnimator.mix(_sweep_back(_high), _sweep_through(_high), smoothstep(0.0, 1.0, t / sweep_time))
		&"defeated":
			return _kneel_pose(_kneel)
	return _guard_pose(_clock)


## How far his head lifts as he kneels beaten (the ending: he looks up into
## the rain). 0 head bowed, 1 looking up.
## 0 kneeling, 1 fallen forward on his face (the end of him).
var fallen := 0.0


func set_fallen(amount: float) -> void:
	fallen = amount


func set_kneel(lift: float) -> void:
	_kneel = lift


# His stances. The naginata lies along "blade"; his right hand holds it.

static func _wait_pose(time: float) -> Dictionary:
	var breath := sin(time * 1.4)
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, breath * 0.006, 0.0), "head": Vector3(-2.0, 0.0, 0.0),
		"foot_l": Vector3(0.16, 0.0, 0.06), "foot_r": Vector3(-0.16, 0.0, -0.04),
		"hand_r": Vector3(-0.3, 0.22, 0.08), "hand_l": Vector3(0.24, -0.12, 0.06),
		"blade": Vector3(0.0, 1.0, 0.08), "blade_out": 1.0})


static func _guard_pose(time: float) -> Dictionary:
	var breath := sin(time * 2.0)
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.1 + breath * 0.008, 0.0), "hips_rot": Vector3(6.0, 14.0, 0.0),
		"spine": Vector3(6.0, -8.0, 0.0), "head": Vector3(0.0, -6.0, 0.0),
		"foot_l": Vector3(0.16, 0.0, 0.26), "foot_r": Vector3(-0.14, 0.0, -0.24),
		"hand_r": Vector3(-0.12, 0.08, 0.16), "hand_l": Vector3(0.0, 0.24, 0.46),
		"blade": Vector3(0.0, 0.45, 0.9), "blade_out": 1.0})


static func _sweep_back(high: bool) -> Dictionary:
	if high:
		return SamuraiAnimator.stance({
			"hips": Vector3(0.0, -0.08, -0.04), "hips_rot": Vector3(-4.0, 34.0, 0.0),
			"spine": Vector3(-6.0, 18.0, 0.0), "head": Vector3(4.0, -20.0, 0.0),
			"foot_l": Vector3(0.16, 0.0, 0.28), "foot_r": Vector3(-0.14, 0.0, -0.26),
			"hand_r": Vector3(-0.16, 0.62, -0.06), "hand_l": Vector3(-0.04, 0.66, 0.16),
			"blade": Vector3(0.0, 0.45, -0.89), "blade_out": 1.0})
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.3, -0.04), "hips_rot": Vector3(12.0, 30.0, 0.0),
		"spine": Vector3(16.0, 16.0, 0.0), "head": Vector3(-4.0, -18.0, 0.0),
		"foot_l": Vector3(0.18, 0.0, 0.34), "foot_r": Vector3(-0.14, 0.0, -0.3),
		"hand_r": Vector3(-0.22, -0.02, -0.12), "hand_l": Vector3(-0.08, 0.0, 0.1),
		"blade": Vector3(0.0, -0.4, -0.92), "blade_out": 1.0})


static func _sweep_through(high: bool) -> Dictionary:
	if high:
		return SamuraiAnimator.stance({
			"hips": Vector3(0.0, -0.12, 0.08), "hips_rot": Vector3(6.0, -28.0, 0.0),
			"spine": Vector3(4.0, -20.0, 0.0), "head": Vector3(-2.0, 18.0, 0.0),
			"foot_l": Vector3(0.16, 0.0, 0.36), "foot_r": Vector3(-0.14, 0.0, -0.22),
			"hand_r": Vector3(-0.06, 0.32, 0.4), "hand_l": Vector3(0.04, 0.34, 0.66),
			"blade": Vector3(0.0, 0.12, 0.99), "blade_out": 1.0})
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.32, 0.1), "hips_rot": Vector3(14.0, -26.0, 0.0),
		"spine": Vector3(18.0, -18.0, 0.0), "head": Vector3(-8.0, 16.0, 0.0),
		"foot_l": Vector3(0.18, 0.0, 0.4), "foot_r": Vector3(-0.14, 0.0, -0.26),
		"hand_r": Vector3(-0.08, -0.02, 0.42), "hand_l": Vector3(0.02, -0.06, 0.68),
		"blade": Vector3(0.0, -0.3, 0.95), "blade_out": 1.0})


static func _thrust_back() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.2, -0.06), "hips_rot": Vector3(8.0, 20.0, 0.0),
		"spine": Vector3(8.0, 10.0, 0.0), "head": Vector3(0.0, -10.0, 0.0),
		"foot_l": Vector3(0.16, 0.0, 0.3), "foot_r": Vector3(-0.14, 0.0, -0.32),
		"hand_r": Vector3(-0.14, 0.12, -0.24), "hand_l": Vector3(-0.02, 0.14, 0.12),
		"blade": Vector3(0.0, 0.05, 1.0), "blade_out": 1.0})


static func _thrust_out() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.24, 0.16), "hips_rot": Vector3(14.0, -10.0, 0.0),
		"spine": Vector3(12.0, -6.0, 0.0), "head": Vector3(-6.0, 6.0, 0.0),
		"foot_l": Vector3(0.16, 0.0, 0.56), "foot_r": Vector3(-0.14, 0.04, -0.42), "toe_l": 30.0,
		"hand_r": Vector3(-0.04, 0.14, 0.5), "hand_l": Vector3(0.02, 0.15, 0.8),
		"blade": Vector3(0.0, 0.02, 1.0), "blade_out": 1.0})


## Calling up the lanterns on his shoulders: the naginata held upright before
## him in both hands, chest out, head up. (An open palm raised beside a shaft
## he was not holding looked wrong: Julian.)
static func _beckon() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.08, 0.0), "hips_rot": Vector3(-4.0, -8.0, 0.0),
		"spine": Vector3(-10.0, -4.0, 0.0), "head": Vector3(-14.0, 0.0, 0.0),
		"foot_l": Vector3(0.18, 0.0, 0.14), "foot_r": Vector3(-0.18, 0.0, -0.1),
		"hand_r": Vector3(-0.1, 0.24, 0.36), "hand_l": Vector3(0.04, 0.56, 0.38),
		"blade": Vector3(0.0, 1.0, 0.04), "blade_out": 1.0})


static func _overhead() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.1, 0.0), "spine": Vector3(-4.0, 0.0, 0.0), "head": Vector3(-6.0, 0.0, 0.0),
		"foot_l": Vector3(0.2, 0.0, 0.14), "foot_r": Vector3(-0.2, 0.0, -0.12),
		"hand_r": Vector3(-0.2, 0.86, 0.06), "hand_l": Vector3(0.24, 0.86, 0.06),
		"blade": Vector3(0.0, 0.08, 1.0), "blade_out": 1.0})


## The spin: knees bent, the naginata held out level at the height of the
## Ronin's chest, sweeping round as he turns.
static func _spin_pose() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.3, 0.0), "hips_rot": Vector3(10.0, -20.0, 0.0),
		"spine": Vector3(8.0, -14.0, 0.0), "head": Vector3(-6.0, 10.0, 0.0),
		"foot_l": Vector3(0.22, 0.0, 0.22), "foot_r": Vector3(-0.22, 0.0, -0.2),
		"hand_r": Vector3(-0.06, -0.12, 0.3), "hand_l": Vector3(0.04, -0.14, 0.58),
		"blade": Vector3(0.0, -0.06, 1.0), "blade_out": 1.0})


static func _crouch() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.4, 0.06), "hips_rot": Vector3(22.0, 6.0, 0.0),
		"spine": Vector3(20.0, 0.0, 0.0), "head": Vector3(-14.0, 0.0, 0.0),
		"foot_l": Vector3(0.2, 0.0, 0.34), "foot_r": Vector3(-0.18, 0.0, -0.3),
		"hand_r": Vector3(-0.1, -0.05, 0.34), "hand_l": Vector3(0.02, -0.12, 0.6),
		"blade": Vector3(0.0, -0.28, 0.96), "blade_out": 1.0})


## His second wind: the naginata planted upright, its butt on the floor,
## chest out, head thrown back.
static func _plant() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.12, 0.0), "hips_rot": Vector3(-6.0, -6.0, 0.0),
		"spine": Vector3(-12.0, -4.0, 0.0), "head": Vector3(-22.0, 0.0, 0.0),
		"foot_l": Vector3(0.2, 0.0, 0.16), "foot_r": Vector3(-0.2, 0.0, -0.12),
		"hand_r": Vector3(-0.1, 0.2, 0.36), "hand_l": Vector3(0.04, 0.5, 0.38),
		"blade": Vector3(0.0, 1.0, 0.04), "blade_out": 1.0})


static func _airborne() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, 0.0, 0.0), "hips_rot": Vector3(-10.0, 10.0, 0.0),
		"spine": Vector3(-10.0, 0.0, 0.0), "head": Vector3(14.0, 0.0, 0.0),
		"foot_l": Vector3(0.16, 0.36, 0.24), "foot_r": Vector3(-0.16, 0.28, -0.16),
		"hand_r": Vector3(-0.14, 0.7, -0.1), "hand_l": Vector3(0.0, 0.76, 0.14),
		"blade": Vector3(0.0, 0.55, -0.84), "blade_out": 1.0})


## On one knee, the naginata propped before him; `lift` raises his head
## from bowed (0) to looking up (1).
static func _kneel_pose(lift: float) -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.42, 0.0), "hips_rot": Vector3(lerpf(14.0, 4.0, lift), 0.0, 0.0),
		"spine": Vector3(lerpf(22.0, -6.0, lift), 0.0, 0.0), "head": Vector3(lerpf(28.0, -34.0, lift), 0.0, 0.0),
		"foot_r": Vector3(-0.15, 0.0, 0.3), "foot_l": Vector3(0.13, 0.02, -0.34), "toe_l": 70.0,
		"hand_r": Vector3(-0.18, 0.1, 0.32), "hand_l": Vector3(0.2, -0.2, 0.2),
		"blade": Vector3(0.0, 0.92, 0.38), "blade_out": 1.0})
