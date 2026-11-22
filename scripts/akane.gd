class_name Akane
extends CharacterBody3D
## Akane, the Vermilion Fox (docs/lore.md): folded by the Emperor from his
## own sleeve as his guard; her red never runs in the Rain. She meets the
## Ronin at the end of the Bamboo of Folded Wind, warns him that he does not
## know what he is, and duels him. She does not fight to the death: once he
## has broken her far enough (her health down to `yield_at`, or her posture
## broken twice) she yields, sheathes, and is gone into the bamboo, to duel
## him again later, harder each time.
##
## Her look is Julian's picture of her (a woman in a white kitsune mask with
## red markings, long black hair with red cords, white robes painted in ink
## with a wolf and plum blossom over red hakama, a red bow with a gold
## crest, tall geta). A Meshy model (models/akane.glb, its front view
## docs/reference/akane_front.png made from his picture), posed by hand with the
## same poser and many of the Ronin's own sword stances (she is a swordswoman
## as he is). The model's sculpted sword is cut away at load
## (`_cut_away_handle`); a folded scabbard takes its place on her hip, and a
## folded katana rests in it or is drawn in her hand: only ever one sword.
## Meshy ids: image 01a203f2-45ef-7197-b17f-2ea292533ddc, model
## 01a203f3-0506-72e0-8096-665c8274d5a4, rig 01a203f4-35d9-75a8-afab-f93c8d06efbd
## (meshy-t2.5 smart topology, 14,000, meshy-n1, a-pose). (A first model, a
## fox warrior, was not what Julian wanted.)
##
## Her moves, each with its tell:
##  - cuts: she lifts her blade, a gleam runs along it, then two or three
##    quick cuts; parry each (posture). She also turns aside his cuts while
##    on guard, and answers at once;
##  - the draw (iai): from afar she sinks low, hand on the hilt, a vermilion
##    glint at the scabbard's mouth; then she dashes through him with one cut
##    (parry it: double posture; or jump over her);
##  - fox-fire: she lifts her left hand and flicks three vermilion fires at
##    him in arcs; parried, a fire flies back and burns her.

signal health_changed(current: int, maximum: int)
signal posture_changed(current: int, maximum: int)
signal yielded
signal defeated   # (for the boss bar: she leaves)

@export_group("Health")
@export var max_health := 24
## She yields when her health is down to this.
@export var yield_at := 12
@export var max_posture := 6
@export var posture_recover_time := 2.6
@export var stagger_time := 2.2
## A cut on her while she is staggered (finishing).
@export var finish_damage := 4
## While on guard, the chance that she turns his cut aside (and answers).
@export var deflect_chance := 0.35

@export_group("Cuts")
@export var cut_windup := 0.5
@export var cut_strike := 0.13
@export var cut_gap := 0.3
@export var cut_recover := 0.75
@export var cut_reach := 2.3
@export var cut_height := 1.9
## How near she comes to cut.
@export var cut_range := 2.2

@export_group("Draw (iai)")
@export var draw_tell := 0.65
@export var draw_speed := 13.0
@export var draw_distance := 6.5
@export var draw_recover := 0.9
## She only draws from further than this.
@export var draw_from := 3.6

@export_group("Fox-fire")
@export var fire_tell := 0.55
@export var fire_count := 3
@export var fire_gap := 0.28
@export var fire_recover := 0.7

@export_group("Slash effect")
## The tint of her swooshes: vermilion paper, hers (the Ronin's are white). A faint
## rose did not show against the grove's pale sky.
@export var swoosh_tint := Color(0.92, 0.42, 0.38, 0.95)
## How long a swoosh lasts: drawn on over the cut, wiped away just after.
@export var swoosh_time := 0.2
## How long the draw's streak lingers before it is wiped away.
@export var streak_time := 0.35

@export_group("Pace")
@export var walk_speed := 2.4
@export var guard_time := Vector2(0.5, 1.2)
@export var model_height := 1.7

var ronin: Ronin
var active := false
var health := 0
var posture := 0
var facing := 1.0
## Fight bounds (x): she keeps inside them.
var bounds := Vector2(-INF, INF)

var _mode: StringName = &"wait"
var _mode_time := 0.0
var _clock := 0.0
var _animator: SamuraiAnimator
var _model: Node3D
var _meshes: Array[MeshInstance3D] = []
var _katana: Node3D
var _katana_blade: Node3D
var _sheath: Node3D      # where the sword rests in its scabbard (on the hips)
## How long her sword's handle is (from pommel to guard).
const HANDLE_LENGTH := 0.27
var _hit_this_cut := false
var _cuts_left := 0
var _posture_clock := 0.0
var _finishes := 0
var _flash := 0.0
var _rng := RandomNumberGenerator.new()
var _swoosh: MeshInstance3D       # round her, for each cut
var _swoosh_turn: Node3D
var _streak: MeshInstance3D       # along her path, for the draw
var _swoosh_clock := -1.0
var _streak_clock := -1.0
var _streak_from := 0.0
var _draw_start := 0.0
var _fires_left := 0
var _guard_for := 0.8
var _yield_time := -1.0


func _ready() -> void:
	_rng.seed = 909
	collision_layer = 4
	collision_mask = 1
	health = max_health
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	axis_lock_linear_z = true
	_build_model()
	_build_katana()
	_build_swoosh()


# --- The model -------------------------------------------------------------------

func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	var figure: Node3D = (preload("res://models/akane.glb") as PackedScene).instantiate()
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
	var hilt := PackedVector3Array()
	for node: MeshInstance3D in meshes:
		var made := node.get_active_material(0) as BaseMaterial3D
		hilt.append_array(_cut_away_handle(node))
		var paper := StandardMaterial3D.new()
		if made:
			paper.albedo_texture = made.albedo_texture
		paper.roughness = 1.0
		paper.metallic_specular = 0.2
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, paper)
		_meshes.append(node)
	var units := 1.0 / (grow * PaperHusk._local_scale(skeleton, figure))
	_animator = SamuraiAnimator.new(skeleton, units)
	# Where the handle was: the sword rests there, on her hips.
	var hips := skeleton.find_bone("Hips")
	var anchor := BoneAttachment3D.new()
	anchor.bone_idx = hips
	skeleton.add_child(anchor)
	_sheath = Node3D.new()
	anchor.add_child(_sheath)
	if hilt.size() >= 3:
		var rest := skeleton.get_bone_global_rest(hips)
		var guard := rest.affine_inverse() * hilt[1]
		var tip := rest.affine_inverse() * hilt[2]
		# +Y of the sheath points from the guard down the scabbard.
		var up := (tip - guard).normalized()
		var side := up.cross(Vector3.FORWARD).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		_sheath.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), guard)
		_build_scabbard(guard.distance_to(tip))
	_animator.apply(SamuraiAnimator.idle(0.0))


## The model's sculpted sword (handle and scabbard in one) is a separate
## piece of the mesh: the long, straight, slanting one (her hair is long
## too, but hangs straight down). Cut it away, and return its line in
## skeleton space: [pommel, guard, scabbard's tip]. The folded scabbard and
## sword take its place.
func _cut_away_handle(node: MeshInstance3D) -> PackedVector3Array:
	var mesh := node.mesh
	if mesh == null or mesh.get_surface_count() == 0:
		return PackedVector3Array()
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var parent := PackedInt32Array()
	parent.resize(verts.size())
	for i in verts.size():
		parent[i] = i
	var same := {}
	for i in verts.size():
		var key := Vector3i(roundi(verts[i].x * 2000.0), roundi(verts[i].y * 2000.0), roundi(verts[i].z * 2000.0))
		if same.has(key):
			_join(parent, i, same[key])
		else:
			same[key] = i
	for t in range(0, index.size(), 3):
		_join(parent, index[t], index[t + 1])
		_join(parent, index[t], index[t + 2])
	var pieces := {}
	for i in verts.size():
		var r := _root(parent, i)
		if not pieces.has(r):
			pieces[r] = PackedVector3Array()
		(pieces[r] as PackedVector3Array).append(verts[i])
	# The sword: long (over half a metre), straight (all of it near one
	# line) and slanting.
	var best := -1
	var best_line := PackedVector3Array()
	for r: int in pieces:
		var pts: PackedVector3Array = pieces[r]
		if pts.size() < 40:
			continue
		var line := _line_of(pts)
		var length := line[0].distance_to(line[1])
		var axis := (line[1] - line[0]).normalized()
		if length < 0.55 or absf(axis.x) < 0.35 or absf(axis.y) < 0.35:
			continue
		var off := 0.0
		for p: Vector3 in pts:
			off = maxf(off, (p - line[0] - axis * (p - line[0]).dot(axis)).length())
		if off > 0.09:
			continue  # (not slim enough to be a sword)
		if best < 0 or length > best_line[0].distance_to(best_line[1]):
			best = r
			best_line = line
	if best < 0:
		return PackedVector3Array()
	var kept := PackedInt32Array()
	for t in range(0, index.size(), 3):
		if _root(parent, index[t]) == best:
			continue
		kept.append(index[t])
		kept.append(index[t + 1])
		kept.append(index[t + 2])
	arrays[Mesh.ARRAY_INDEX] = kept
	var cut := ArrayMesh.new()
	cut.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	for k in range(1, mesh.get_surface_count()):
		cut.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(k))
	node.mesh = cut
	# The higher end is the pommel; the guard a handle's length down.
	var top := best_line[0] if best_line[0].y > best_line[1].y else best_line[1]
	var tip := best_line[1] if top == best_line[0] else best_line[0]
	var guard := top + (tip - top).normalized() * HANDLE_LENGTH
	return PackedVector3Array([node.transform * top, node.transform * guard, node.transform * tip])


## The two ends of the line a set of points lies along.
static func _line_of(pts: PackedVector3Array) -> PackedVector3Array:
	var centre := Vector3.ZERO
	for p: Vector3 in pts:
		centre += p
	centre /= pts.size()
	var far := centre
	for p: Vector3 in pts:
		if p.distance_to(centre) > far.distance_to(centre):
			far = p
	var other := far
	for p: Vector3 in pts:
		if p.distance_to(far) > other.distance_to(far):
			other = p
	return PackedVector3Array([far, other])


func _join(parent: PackedInt32Array, a: int, b: int) -> void:
	var ra := _root(parent, a)
	var rb := _root(parent, b)
	if ra != rb:
		parent[rb] = ra


func _root(parent: PackedInt32Array, i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i


## The scabbard, black lacquered paper with a gold band at its mouth, along
## the line the sculpted one had (it stays at her hip, empty when she draws).
func _build_scabbard(length: float) -> void:
	var b := PaperMesh.new(79)
	b.texture_world = false
	b.shade_jitter = 0.1
	b.color = Color(0.08, 0.075, 0.09)
	b.frustum(6, Vector2(0.03, 0.022), Vector2(0.024, 0.018), length - 0.02, Vector3(0.0, 0.0, 0.0))
	b.color = Color(0.78, 0.62, 0.3)
	b.frustum(6, Vector2(0.034, 0.026), Vector2(0.034, 0.026), 0.03, Vector3(0.0, 0.0, 0.0))
	b.frustum(6, Vector2(0.027, 0.02), Vector2(0.02, 0.015), 0.04, Vector3(0.0, length - 0.06, 0.0))
	var mesh := b.build()
	_sheath.add_child(mesh)


## Her katana, folded: a wrapped handle (red and white, like the one cut
## away), a dark guard, a long pale blade with a slight curve. +Y runs from
## the handle into the blade; the guard is at the origin.
func _build_katana() -> void:
	_katana = Node3D.new()
	_katana.top_level = true
	add_child(_katana)
	var h := PaperMesh.new(77)
	h.texture_world = false
	h.shade_jitter = 0.1
	h.color = Color(0.55, 0.14, 0.12)
	h.box(Vector3(0.0, -0.13, 0.0), Vector3(0.045, 0.26, 0.038))
	h.color = Color(0.9, 0.88, 0.82)
	for k in 5:
		h.box(Vector3(0.0, -0.03 - k * 0.048, 0.0), Vector3(0.05, 0.014, 0.042))
	# The guard, gold, as in Julian's picture of her; a gold cap on the pommel.
	h.color = Color(0.78, 0.62, 0.3)
	h.frustum(8, Vector2(0.055, 0.05), Vector2(0.055, 0.05), 0.016, Vector3(0.0, -0.008, 0.0))
	h.box(Vector3(0.0, -0.265, 0.0), Vector3(0.05, 0.02, 0.042))
	_katana.add_child(h.build())
	_katana_blade = Node3D.new()
	_katana.add_child(_katana_blade)
	var b := PaperMesh.new(78)
	b.texture_world = false
	b.shade_jitter = 0.08
	b.color = Color(0.86, 0.88, 0.9)
	var length := 0.78
	var steps := 8
	for k in steps:
		var y0 := 0.01 + length * k / steps
		var y1 := 0.01 + length * (k + 1) / steps
		var bend0 := 0.035 * pow(float(k) / steps, 2.0)
		var bend1 := 0.035 * pow(float(k + 1) / steps, 2.0)
		var w0 := 0.016 * (1.0 - 0.3 * k / steps)
		var w1 := 0.016 * (1.0 - 0.3 * (k + 1) / steps) if k < steps - 1 else 0.0
		b.quad(Vector3(bend0 - w0, y0, 0.0), Vector3(bend1 - w1, y1, 0.0), Vector3(bend1 + w1, y1, 0.0), Vector3(bend0 + w0, y0, 0.0))
	b.color = Color(0.6, 0.62, 0.66)
	b.quad(Vector3(-0.004, 0.02, 0.003), Vector3(-0.004 + 0.035, length, 0.003), Vector3(0.004 + 0.035, length, 0.003), Vector3(0.004, 0.02, 0.003))
	var blade := b.build()
	(blade.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	_katana_blade.add_child(blade)


## Her slash effect, like the Ronin's (slash_sweep.gdshader): a curved strip
## of paper round her, standing on edge, drawn on in the direction her blade
## travels and wiped away from the same end by the end of the cut. It reaches
## exactly as far as her cut can hit (`cut_reach`). And for the draw, a long
## straight streak along her path, wiped away behind her.
func _build_swoosh() -> void:
	var steps := 30
	var reach := cut_reach - 0.05
	var tall := 0.55
	var side := SurfaceTool.new()
	side.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var across: float = corner[1]
			var angle := lerpf(deg_to_rad(-120.0), deg_to_rad(80.0), t)
			var swell := pow(sin(PI * t), 0.65)
			var radius := reach * (0.78 + 0.22 * sin(PI * t)) - reach * 0.2 * swell * (1.0 - across)
			var height := lerpf(-0.12, 0.22, t) + tall * swell * (across - 0.5)
			side.set_uv(Vector2(t, across))
			# Forward is +X: it starts behind her left side (-Z), passes in front
			# of her and ends at her right (+Z), as the Ronin's does.
			side.add_vertex(Vector3(cos(angle) * radius, height, sin(angle) * radius))
	_swoosh_turn = Node3D.new()
	_swoosh_turn.position = Vector3(0.0, 1.0, 0.0)
	_swoosh_turn.rotation.z = 0.0
	add_child(_swoosh_turn)
	_swoosh = _strip(side.commit())
	# Tipped toward the camera, so it is seen as an open curve.
	_swoosh.rotation.x = 0.25
	_swoosh_turn.add_child(_swoosh)
	var line := SurfaceTool.new()
	line.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var across: float = corner[1]
			var wide := 0.16 * pow(sin(PI * clampf(t * 0.9 + 0.1, 0.0, 1.0)), 0.5)
			line.set_uv(Vector2(t, across))
			line.add_vertex(Vector3(t, (across - 0.5) * wide, 0.0))
	_streak = _strip(line.commit())
	_streak.top_level = true
	add_child(_streak)


func _strip(mesh: Mesh) -> MeshInstance3D:
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/slash_sweep.gdshader")
	look.set_shader_parameter(&"tint", swoosh_tint)
	look.set_shader_parameter(&"head", 0.0)
	look.set_shader_parameter(&"tail", 0.0)
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = look
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return strip


# --- The fight -------------------------------------------------------------------

func begin() -> void:
	active = true
	health = max_health
	posture = 0
	_finishes = 0
	health_changed.emit(health, max_health)
	posture_changed.emit(posture, max_posture)
	_set_mode(&"guard")


## Back to waiting (he died during the duel).
func reset(at: Vector3) -> void:
	active = false
	health = max_health
	posture = 0
	_finishes = 0
	global_position = at
	velocity = Vector3.ZERO
	_set_mode(&"wait")


func is_staggered() -> bool:
	return _mode == &"stagger"


func mode() -> StringName:
	return _mode


func _set_mode(next: StringName) -> void:
	_mode = next
	_mode_time = 0.0
	_hit_this_cut = false
	if next == &"cut":
		_swoosh_clock = 0.0
	elif next == &"draw":
		_streak_clock = 0.0
		_streak_from = global_position.x


## Called by the Ronin's cuts.
func take_hit(damage: int, direction: Vector2) -> void:
	if not active or _mode == &"yield" or _mode == &"gone":
		return
	if _mode == &"stagger":
		health -= finish_damage
		_finishes += 1
		posture = 0
		posture_changed.emit(posture, max_posture)
		Confetti.burst(get_parent(), global_position + Vector3(0.0, 1.1, 0.0), 40)
		Sound.play(self, &"paper_burst", 2.0)
		_set_mode(&"recover")
		_mode_time = -0.3
	elif _mode == &"guard" and _rng.randf() < deflect_chance:
		# Turned aside: a clash, and she answers at once.
		Sound.play(self, &"parry", -4.0)
		_spark(Color(0.75, 0.74, 0.72))
		velocity.x = -facing * 1.5
		_cuts_left = 1
		_set_mode(&"windup")
		_mode_time = cut_windup * 0.55
		return
	else:
		health -= damage
		velocity.x = signf(direction.x) * 3.0 if direction.x != 0.0 else -facing * 3.0
	_flash = 0.12
	health_changed.emit(maxi(health, 0), max_health)
	if health <= yield_at or _finishes >= 2:
		_yield()


## A fire of hers parried back at her, or a parry of her cut.
func _parried(cost: int) -> void:
	posture = mini(posture + cost, max_posture)
	_posture_clock = 0.0
	posture_changed.emit(posture, max_posture)
	velocity.x = -facing * 3.5
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger", 4.0)
		_cuts_left = 0


func _yield() -> void:
	health = maxi(health, yield_at)
	health_changed.emit(health, max_health)
	_set_mode(&"yield")
	velocity = Vector3(-facing * 5.0, 4.5, 0.0)
	Sound.play(self, &"parry", -2.0)
	yielded.emit()


## She leaps up into the bamboo and is gone (petals where she was).
func leave() -> void:
	_set_mode(&"gone")
	Confetti.burst(get_parent(), global_position + Vector3(0.0, 1.2, 0.0), 30)
	var t := create_tween()
	t.tween_property(self, "global_position", global_position + Vector3(facing * -2.0, 9.0, -3.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		visible = false
		defeated.emit())


func _physics_process(delta: float) -> void:
	_clock += delta
	_mode_time += delta
	if not is_on_floor():
		velocity.y -= 30.0 * delta
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	var gap := (ronin.global_position.x - global_position.x) if ronin else 99.0
	if active and _mode in [&"guard", &"approach"] and ronin:
		facing = signf(gap) if gap != 0.0 else facing
	_posture_clock += delta
	if _posture_clock > posture_recover_time and posture > 0 and _mode != &"stagger":
		_posture_clock = 0.0
		posture -= 1
		posture_changed.emit(posture, max_posture)
	match _mode:
		&"guard":
			_guard(gap, delta)
		&"approach":
			velocity.x = move_toward(velocity.x, facing * walk_speed, 20.0 * delta)
			if absf(gap) <= cut_range:
				_cuts_left = 2 if _rng.randf() < 0.55 else 3
				_set_mode(&"windup")
			elif _mode_time > 2.0:
				_set_mode(&"guard")
		&"windup":
			velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
			if _mode_time >= cut_windup:
				_set_mode(&"cut")
				Sound.play(self, &"akane_slash", -2.0)
				velocity.x = facing * 4.0
		&"cut":
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if not _hit_this_cut and _mode_time > cut_strike * 0.4:
				_swing(cut_reach, cut_height, 1)
			if _mode_time >= cut_strike:
				_cuts_left -= 1
				if _cuts_left > 0:
					_set_mode(&"between")
				else:
					_set_mode(&"recover")
		&"between":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time >= cut_gap:
				_set_mode(&"cut")
				Sound.play(self, &"akane_slash", -2.0)
				velocity.x = facing * 4.0
		&"draw_tell":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time >= draw_tell:
				_set_mode(&"draw")
				_draw_start = global_position.x
				Sound.play(self, &"akane_draw", -1.0)
		&"draw":
			velocity.x = facing * draw_speed
			if not _hit_this_cut:
				_swing(1.2, 1.9, 2, -0.6)
			if absf(global_position.x - _draw_start) >= draw_distance or is_on_wall() \
					or global_position.x < bounds.x + 0.5 or global_position.x > bounds.y - 0.5:
				velocity.x = facing * 2.0
				_set_mode(&"recover")
				_mode_time = cut_recover - draw_recover
		&"fire_tell":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time >= fire_tell:
				_fires_left = fire_count
				_set_mode(&"fire")
		&"fire":
			if _mode_time >= fire_gap and _fires_left > 0:
				_throw_fire()
				_fires_left -= 1
				_mode_time = 0.0
			if _fires_left <= 0 and _mode_time >= fire_recover:
				_set_mode(&"guard")
		&"recover":
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			if _mode_time >= cut_recover:
				_set_mode(&"guard")
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			if _mode_time >= stagger_time:
				posture = 0
				posture_changed.emit(posture, max_posture)
				_set_mode(&"guard")
		&"yield":
			velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		_:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	if active and _mode != &"draw":
		global_position.x = clampf(global_position.x, bounds.x, bounds.y)
	move_and_slide()
	position.z = 0.0


## On guard: she holds her blade ready and steps, keeping her distance, then
## chooses what to do.
func _guard(gap: float, delta: float) -> void:
	var dist := absf(gap)
	var want := 0.0
	if dist > 3.2:
		want = facing * walk_speed * 0.5
	elif dist < 1.4:
		want = -facing * walk_speed * 0.6
	velocity.x = move_toward(velocity.x, want, 12.0 * delta)
	if _mode_time < _guard_for:
		return
	_guard_for = _rng.randf_range(guard_time.x, guard_time.y)
	var roll := _rng.randf()
	if dist > draw_from and roll < 0.45:
		_set_mode(&"draw_tell")
		Sound.play(self, &"draw_gleam", -6.0)
	elif dist > 2.6 and roll < 0.8:
		_set_mode(&"fire_tell")
	elif dist <= cut_range:
		_cuts_left = 2 if _rng.randf() < 0.55 else 3
		_set_mode(&"windup")
	else:
		_set_mode(&"approach")


## Anything of his inside her cut, in front of her. Parried: posture.
func _swing(reach: float, height: float, cost: int, back: float = 0.0) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(reach, height, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(facing * (reach * 0.5 + back), height * 0.5, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 4):
		var target: Object = result["collider"]
		if not target.has_method("receive_strike"):
			continue
		_hit_this_cut = true
		if target.receive_strike(1, global_position, &"cut"):
			_parried(cost)
			_spark(Color(1.0, 0.82, 0.4))
		return


## A fox-fire flicked at him: a vermilion fire in an arc.
func _throw_fire() -> void:
	if ronin == null:
		return
	var fire := BurningPaper.new()
	fire.fox = true
	fire.thrower = self
	get_parent().add_child(fire)
	var from := global_position + Vector3(facing * 0.4, 1.5, 0.0)
	fire.global_position = from
	var to := ronin.global_position + Vector3(_rng.randf_range(-0.6, 0.6), 0.8, 0.0)
	var t := clampf(absf(to.x - from.x) / 9.0, 0.45, 0.9)
	fire.velocity = Vector3((to.x - from.x) / t, (to.y - from.y) / t + fire.gravity * t * 0.5, 0.0)
	Sound.play(self, &"fox_fire", -2.0)


## A burst of sparks where blades meet.
func _spark(tint: Color) -> void:
	var burst := CPUParticles3D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 14
	burst.lifetime = 0.35
	burst.spread = 180.0
	burst.gravity = Vector3(0.0, -5.0, 0.0)
	burst.initial_velocity_min = 2.0
	burst.initial_velocity_max = 4.5
	var mote := QuadMesh.new()
	mote.size = Vector2(0.04, 0.04)
	mote.material = WaterFx.bead_material(tint)
	burst.mesh = mote
	get_parent().add_child(burst)
	burst.global_position = global_position + Vector3(facing * 0.8, 1.3, 0.3)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)


# --- How she looks ---------------------------------------------------------------

func _process(delta: float) -> void:
	_model.rotation.y = 0.0 if facing > 0.0 else PI
	var pose := _pose()
	_animator.apply(pose)
	_place_katana()
	_update_swoosh(delta)
	if _flash > 0.0:
		_flash -= delta
	for m: MeshInstance3D in _meshes:
		m.material_overlay = PaperHusk.flash_overlay() if _flash > 0.0 else null


func _pose() -> Dictionary:
	var t := _mode_time
	match _mode:
		&"wait":
			return SamuraiAnimator.mix(SamuraiAnimator.idle(_clock), _still(), 0.6)
		&"guard":
			return _en_garde(_clock)
		&"approach":
			return SamuraiAnimator.with_upper_body(SamuraiAnimator.run(fmod(_clock * 1.3, 1.0)), _en_garde(_clock))
		&"windup":
			# The blade lifted back over her shoulder; a gleam runs along it.
			return SamuraiAnimator.mix(_en_garde(_clock), _raised(), smoothstep(0.0, 0.6, t / cut_windup))
		&"cut":
			return SamuraiAnimator.slash(0.35 + 0.65 * clampf(t / cut_strike, 0.0, 1.0), Vector2.ZERO)
		&"between":
			return SamuraiAnimator.mix(SamuraiAnimator.slash(1.0, Vector2.ZERO), _raised(), smoothstep(0.0, 1.0, t / cut_gap))
		&"draw_tell":
			return SamuraiAnimator.iai(clampf(t / draw_tell, 0.0, 1.0), _clock)
		&"draw":
			return SamuraiAnimator.dash() if t < 0.12 else SamuraiAnimator.iai_strike()
		&"fire_tell", &"fire":
			return _fox_fire(clampf(t / fire_tell, 0.0, 1.0) if _mode == &"fire_tell" else 1.0)
		&"recover":
			return SamuraiAnimator.mix(SamuraiAnimator.slash(1.0, Vector2.ZERO), _en_garde(_clock), smoothstep(0.0, 1.0, t / cut_recover))
		&"stagger":
			return SamuraiAnimator.mix(SamuraiAnimator.hurt(), _bent(), smoothstep(0.0, 0.3, t))
		&"yield", &"gone":
			return SamuraiAnimator.mix(_en_garde(_clock), _still(), smoothstep(0.3, 1.2, t))
	return _still()


## Standing still, sword sheathed, hand resting on the hilt.
static func _still() -> Dictionary:
	return SamuraiAnimator.stance({"hips": Vector3(0.0, -0.02, 0.0), "head": Vector3(4.0, 0.0, 0.0),
			"foot_l": Vector3(0.12, 0.0, 0.05), "foot_r": Vector3(-0.12, 0.0, -0.08)})


## On guard: low, front foot forward, the blade held out slanted before her.
static func _en_garde(time: float) -> Dictionary:
	var breath := sin(time * 2.2)
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.1 + breath * 0.008, 0.0), "hips_rot": Vector3(6.0, 10.0, 0.0),
		"spine": Vector3(6.0, -6.0, 0.0), "head": Vector3(0.0, -4.0, 0.0),
		"foot_l": Vector3(0.14, 0.0, 0.22), "foot_r": Vector3(-0.12, 0.0, -0.2),
		"hand_r": Vector3(-0.02, 0.24, 0.34), "hand_l": Vector3(0.06, 0.2, 0.3),
		"blade": Vector3(0.0, 0.55, 0.84), "blade_out": 1.0,
	})


## The blade lifted back over her right shoulder, ready to cut.
static func _raised() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.08, -0.04), "hips_rot": Vector3(-4.0, 24.0, 0.0),
		"spine": Vector3(-4.0, 10.0, 0.0), "head": Vector3(4.0, -16.0, 0.0),
		"foot_l": Vector3(0.14, 0.0, 0.24), "foot_r": Vector3(-0.12, 0.0, -0.22),
		"hand_r": Vector3(-0.14, 0.62, -0.02), "hand_l": Vector3(0.0, 0.58, 0.04),
		"blade": Vector3(0.0, 0.5, -0.86), "blade_out": 1.0,
	})


## Broken: bent over, sword point down.
static func _bent() -> Dictionary:
	return SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.22, -0.06), "hips_rot": Vector3(18.0, 0.0, 0.0),
		"spine": Vector3(26.0, 0.0, 0.0), "head": Vector3(20.0, 0.0, 0.0),
		"foot_l": Vector3(0.16, 0.0, 0.2), "foot_r": Vector3(-0.14, 0.0, -0.18),
		"hand_r": Vector3(-0.12, -0.05, 0.3), "hand_l": Vector3(0.18, -0.02, 0.12),
		"blade": Vector3(0.0, -0.9, 0.4), "blade_out": 1.0,
	})


## The fox-fire: her left hand raised and turned up, sword held back low.
static func _fox_fire(u: float) -> Dictionary:
	return SamuraiAnimator.mix(_en_garde(0.0), SamuraiAnimator.stance({
		"hips": Vector3(0.0, -0.06, 0.0), "hips_rot": Vector3(0.0, -10.0, 0.0),
		"spine": Vector3(-6.0, -8.0, 0.0), "head": Vector3(-6.0, 0.0, 0.0),
		"foot_l": Vector3(0.14, 0.0, 0.22), "foot_r": Vector3(-0.12, 0.0, -0.2),
		"hand_l": Vector3(0.12, 0.72, 0.42), "hand_r": Vector3(-0.22, 0.05, -0.1),
		"blade": Vector3(0.0, -0.5, -0.86), "blade_out": 1.0,
	}), u)


## The sword: in her hand while drawn (where the pose puts her right fist,
## along the pose's blade line), else resting where the handle was cut away.
func _place_katana() -> void:
	var skeleton := _animator.skeleton
	if _animator.sword_out and _mode not in [&"wait", &"yield", &"gone"] or (_mode == &"yield" and _mode_time < 0.8):
		var at := skeleton.global_transform * _animator.sword_at
		var dir := (skeleton.global_transform.basis * _animator.sword_dir).normalized()
		var side := dir.cross(Vector3.BACK).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		_katana.global_transform = Transform3D(Basis(side, dir, side.cross(dir)).orthonormalized(), at)
		_katana_blade.visible = true
	else:
		_katana.global_transform = _sheath.global_transform
		_katana_blade.visible = false


## Moves the swooshes on, every frame: drawn on, then wiped away from the
## end where they began (they never pop in or out whole).
func _update_swoosh(delta: float) -> void:
	var look := _swoosh.material_override as ShaderMaterial
	var head := 0.0
	var tail := 0.0
	if _swoosh_clock >= 0.0:
		_swoosh_clock += delta
		var u := clampf(_swoosh_clock / swoosh_time, 0.0, 1.0)
		head = smoothstep(0.0, 0.55, u) * 1.03
		tail = pow(clampf((u - 0.45) / 0.55, 0.0, 1.0), 2.0) * 1.12 - 0.12 * (1.0 - u)
		if u >= 1.0:
			_swoosh_clock = -1.0
			head = 0.0
			tail = 0.0
	look.set_shader_parameter(&"head", head)
	look.set_shader_parameter(&"tail", tail)
	_swoosh_turn.rotation.y = 0.0 if facing > 0.0 else PI
	# The draw's streak: from where she set off to where she is, drawn on as
	# she goes, then wiped away from the start.
	var line := _streak.material_override as ShaderMaterial
	if _streak_clock >= 0.0:
		_streak_clock += delta
		var span := global_position.x - _streak_from
		if _mode == &"draw":
			_streak_clock = 0.0  # (the wipe is timed from when she stops)
			_streak.global_transform = Transform3D(Basis.from_scale(Vector3(maxf(absf(span), 0.01) * signf(span if span != 0.0 else facing), 1.0, 1.0)),
					Vector3(_streak_from, global_position.y + 1.0, 0.2))
			line.set_shader_parameter(&"head", 1.03)
			line.set_shader_parameter(&"tail", 0.0)
		else:
			var u := clampf(_streak_clock / streak_time, 0.0, 1.0)
			line.set_shader_parameter(&"tail", u * 1.12)
			if u >= 1.0:
				_streak_clock = -1.0
				line.set_shader_parameter(&"head", 0.0)
				line.set_shader_parameter(&"tail", 0.0)


