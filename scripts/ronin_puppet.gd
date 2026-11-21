class_name RoninPuppet
extends Node3D
## The Blank Ronin's body: how he LOOKS. ronin.gd tells this script WHAT he
## is doing (state, facing); this script shows it.
##
## There are two Ronins in this file:
##
##  1. The sculpted model (use_model = on, the default). Meshy made it from
##     the walking figure in the rainy-town picture: wide kasa hat, cowl, long
##     robe, torn cloak, sheathed katana, and gave it a skeleton. The
##     animation is ours: samurai_animator.gd poses that skeleton by hand,
##     stance by stance, and this script decides which stance to show. Poses
##     change only ~12 times a second, so he still moves like stop-motion.
##
##  2. The hand-folded puppet (use_model = off). Rigid paper pieces built in
##     code and rotated on little pivots. No skeleton. Kept as a fallback and
##     as the pattern for enemies.

@export_group("Stop-motion")
## How many poses per second. 12 = animating "on twos".
@export var frames_per_second := 12.0
## How far the figure turns toward the camera (radians). 0 = a pure side view,
## as in the reference; a little turn lets the folds catch more light.
@export var turn_toward_camera := 0.28

@export_group("Animation")
@export var run_cycle_speed := 16.0
## How long the sword swing pose lasts.
@export var slash_show_time := 0.2
## How long the white slash arc stays visible.
@export var arc_show_time := 0.13
@export var arc_radius := 2.1
## How far the cloak tails hang down when he stands still (radians below
## straight-back) and when he runs.
@export var cloak_hang := 1.2
@export var cloak_stream := 0.6

@export_group("Paper")
## A little light of his own, so the white paper reads against the dark town.
@export var paper_glow := 0.2
## Colour of the cowl round his neck. White in the reference; try
## PaperMesh.VERMILION for a red scarf.
@export var scarf_color := Color(0.9, 0.87, 0.81)
@export var hat_color := Color(0.95, 0.92, 0.85)

@export_group("Sculpted model")
## The Ronin sculpted by Meshy from the reference picture. Turn this off to
## get the hand-folded paper puppet built by the code below instead.
@export var use_model := true
@export var model_scene: PackedScene = preload("res://models/ronin.glb")
## How tall the model stands, in metres, to the point of the hat.
@export var model_height := 1.6

@export_group("Model animation")
## Full strides (left step + right step) per second when running.
@export var strides_per_second := 2.0
## How long the whole cut takes, from draw to the held finish. The white
## sweep lasts exactly this long too.
@export var cut_time := 0.22
## The point in the cut (0 to 1) at which the sword goes back in. It is set
## to when the last of the swoosh disappears, so the two go together.
@export_range(0.5, 1.0) var sword_away_at := 0.95
## Poses per second during a cut aimed up or down (the rest of his movement
## stays at frames_per_second).
@export var aimed_cut_fps := 30.0
## How far out the white sweep reaches (metres), and how tall its ribbon is
## at the widest point.
@export var sweep_reach := 1.55
@export var sweep_height := 0.5
## How much of cut_time the sweep takes to be drawn on (0 to 1), and the
## moment it starts being wiped away from the end where it began.
@export_range(0.1, 1.0) var sweep_draw := 0.45
@export_range(0.0, 0.9) var sweep_wipe_from := 0.5
## How long it takes to lean fully into a run, and to come back upright.
@export var run_ease_in := 0.3
@export var run_ease_out := 0.22
## How much he is stretched along the way he is going during a dash.
@export var dash_stretch := 1.12

@export_group("Struck")
## When he is hurt, ink splashes off him and blots his paper. This is how
## long the blots take to fade (match it to the Ronin's invulnerable_time).
@export var ink_fade_time := 1.0
## How many drops of ink fly off.
@export var ink_drops := 26

@export_group("Cloth")
## Wind speed (metres per second) that lifts the cloak to 45 degrees. Lower
## = lighter cloth that flies more.
@export var cloth_weight := 9.0
## How quickly the cloth catches up with a change in the wind or in his
## movement (higher = snappier, lower = it trails behind more).
@export var cloth_follow := 7.0
## How much the cloth ripples.
@export var cloth_flutter := 0.22
## How long the landing crouch lasts.
@export var land_time := 0.22
## Rising at this speed (or faster) shows the full take-off pose.
@export var jump_pose_speed := 13.5
## Falling at this speed (or faster) shows the full falling pose.
@export var fall_pose_speed := 14.0
## How much of a new stance shows on its first frame (1 = snap straight to
## it, lower = one in-between frame first).
@export_range(0.3, 1.0) var pose_snap := 0.6

## Set by ronin.gd: idle, run, jump, fall, dash, hurt or heal.
var state: StringName = &"idle"
var facing := 1.0
var blinking := false
## Set by ronin.gd: how fast he is moving up (positive) or down (negative),
## and along the street (positive = right).
var vertical_speed := 0.0
var horizontal_speed := 0.0

var _clock := 0.0
var _frame_clock := 0.0
var _frame := 0
var _slash_clock := -1.0
var _slash_dir := Vector2.RIGHT

var _rig: Node3D
var _body: Node3D
var _head: Node3D
var _leg_front: Node3D
var _leg_back: Node3D
var _arm_front: Node3D
var _arm_back: Node3D
var _sword: Node3D       # the drawn blade, in his right hand
var _sword_far: Node3D   # the same, in his left hand (used when he faces left)
var _hilt: Node3D        # the handle sticking out of the scabbard
var _tails: Array[Node3D] = []      # the base piece of each cloak tail
var _tail_tips: Array[Node3D] = []  # the end piece of each cloak tail
var _arc: Node3D
var _model: Node3D       # the sculpted model, when use_model is on
var _animator: SamuraiAnimator    # poses the model's skeleton
var _model_sword: Node3D          # the drawn blade in the model's fist
var _shown := {}                  # the pose he is in right now
var _shown_state: StringName = &""
var _run_phase := 0.0             # 0 to 1 through the current stride
var _cut_clock := -1.0            # seconds into the current cut, or -1
var _sheathed := false            # true once the sword is back in during this cut
var _land_clock := -1.0           # seconds since he touched down, or -1
var _was_airborne := false
var _run_blend := 0.0             # 0 = standing, 1 = fully into his run
var _cloth: ShaderMaterial        # the model's paper, which blows in the wind
var _cloth_push := Vector3.ZERO   # how the air is pushing the cloth right now
var _streaks: CPUParticles3D      # speed lines left behind by a dash
var _ink := 0.0                   # how much ink is on him (1 = just struck)
var _ink_drops: CPUParticles3D    # the ink that splashes off when he is struck
var _was_struck := false
var _sweep_tilt: Node3D           # tips the sideways swoosh toward the camera
var _sweep_side: MeshInstance3D   # the swoosh for a forward cut: round him, from the side
var _sweep_tall: MeshInstance3D   # the swoosh for cuts aimed up or down
var _sweep_flip: Node3D           # flips the upright swoosh for facing and up/down
var _step := 0.0         # seconds since the last stop-motion pose


func _ready() -> void:
	_build()
	_pose()


func _process(delta: float) -> void:
	# Turning is instant (not stop-motion) so the controls feel responsive.
	_rig.rotation.y = -turn_toward_camera if facing > 0.0 else PI + turn_toward_camera
	_clock += delta
	if _slash_clock >= 0.0:
		_slash_clock += delta
		if _slash_clock > slash_show_time:
			_slash_clock = -1.0
	if _cut_clock >= 0.0:
		_cut_clock += delta
		# The sword is put away just as the last of the swoosh is wiped off
		# (a hair before the cut's clock runs out), and he is posed again
		# that instant rather than at the next stop-motion tick. Otherwise
		# the sword hangs in the air for a moment after the slash is over.
		if not _sheathed and _cut_clock > cut_time * sword_away_at:
			_sheathed = true
			_shown_state = &""  # ease back out of the cut
			_frame_clock = 1.0
		if _cut_clock > cut_time:
			_cut_clock = -1.0
	# The blade is only out while he strikes, in the hand nearest the camera.
	var drawn := _slash_clock >= 0.0
	if not _model:
		_sword.visible = drawn and facing > 0.0
		_sword_far.visible = drawn and facing <= 0.0
		_hilt.visible = not drawn
	if _model:
		_update_sweep()
		_blow_cloth(delta)  # every frame, so the cloth flows rather than steps
	_frame_clock += delta
	# Cuts aimed up or down show more poses per second, because the blade
	# travels a long way in a very short time and would otherwise skip.
	var rate := frames_per_second
	if _model and _cut_clock >= 0.0 and not _sheathed and absf(_slash_dir.y) > 0.5:
		rate = aimed_cut_fps
	if _frame_clock >= 1.0 / rate:
		_step = minf(_frame_clock, 1.0 / frames_per_second)
		_frame_clock = 0.0
		_frame += 1
		_pose()


## Called by ronin.gd when a slash starts. `direction` is left/right/up/down.
func play_slash(direction: Vector2) -> void:
	_slash_dir = direction
	_slash_clock = 0.0
	_frame_clock = 0.0
	_step = 0.0
	_cut_clock = 0.0
	_sheathed = false
	_pose()


# --- Building the paper figure -------------------------------------------
# The figure is modelled facing +X (right). Y is up. +Z is toward the camera,
# which is his right-hand side. All sizes are in metres. He is about 1.25 m to
# the brim of the hat and 1.6 m to its point; the hat is 0.84 m across.

func _piece(parent: Node3D, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	parent.add_child(pivot)
	return pivot


## A fresh sheet of the Ronin's white paper.
func _sheet(seed_value: int, tint: Color = PaperMesh.WASHI) -> PaperMesh:
	var b := PaperMesh.new(seed_value)
	b.color = tint
	b.shade_jitter = 0.1
	b.texture_world = false
	b.texture_scale = 1.4
	b.wrinkle_depth = 0.45
	return b


func _finish(b: PaperMesh, parent: Node3D) -> MeshInstance3D:
	var mesh := b.build(Color.WHITE, 0.0)
	var mat := mesh.material_override as StandardMaterial3D
	if paper_glow > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(0.92, 0.89, 0.82)
		mat.emission_energy_multiplier = paper_glow
	parent.add_child(mesh)
	return mesh


func _build() -> void:
	_rig = _piece(self, Vector3.ZERO)
	if use_model and model_scene:
		_build_model()
		_build_sweeps()
		return
	_build_legs()
	_body = _piece(_rig, Vector3(0.0, 0.62, 0.0))
	_build_cloak_tails()
	_build_robe()
	_build_scabbard()
	_build_cowl()
	_head = _piece(_body, Vector3(0.03, 0.52, 0.0))
	_build_head()
	_build_hat()
	_build_arms()
	_sword = _build_sword(_arm_front, 1.0)
	_sword_far = _build_sword(_arm_back, -1.0)
	_build_arc()


## Loads the sculpted model, scales it to model_height, stands it on the
## ground facing right, gives it paper that blows in the wind, and hands its
## skeleton to the animator.
func _build_model() -> void:
	_model = _piece(_rig, Vector3.ZERO)
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
	figure.rotation.y = PI * 0.5  # Meshy models face +Z; our rig faces +X.
	_model.add_child(figure)

	# Meshy's ready-made clips came inside the file. We do not use them.
	for player: Node in figure.find_children("*", "AnimationPlayer", true, false):
		player.queue_free()
	var skeleton: Skeleton3D = figure.find_children("*", "Skeleton3D", true, false)[0]
	# The skeleton is measured in centimetres; this is centimetres per metre.
	var units := 1.0 / skeleton.global_transform.basis.get_scale().y
	_animator = SamuraiAnimator.new(skeleton, units)
	_shown = SamuraiAnimator.idle(0.0)

	# His paper: one material that glows faintly and lets the cloth blow.
	_cloth = ShaderMaterial.new()
	_cloth.shader = preload("res://shaders/paper_cloth.gdshader")
	_cloth.set_shader_parameter(&"glow", paper_glow)
	_cloth.set_shader_parameter(&"flutter", cloth_flutter)
	_cloth.set_shader_parameter(&"reach_scale", CLOTH_REACH * units)
	for node: MeshInstance3D in meshes:
		var paper := node.get_active_material(0) as BaseMaterial3D
		if paper:
			_cloth.set_shader_parameter(&"paper", paper.albedo_texture)
		_paint_cloth(node)
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, _cloth)

	# The katana he draws.
	_model_sword = _piece(_rig, Vector3.ZERO)
	_fold_slim_katana(_model_sword)
	_model_sword.visible = false

	# Speed lines for the dash: thin white strokes left hanging in the air.
	_streaks = CPUParticles3D.new()
	_streaks.emitting = false
	_streaks.amount = 18
	_streaks.lifetime = 0.2
	_streaks.local_coords = false
	_streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_streaks.emission_box_extents = Vector3(0.15, 0.55, 0.25)
	_streaks.gravity = Vector3.ZERO
	_streaks.initial_velocity_max = 0.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	_streaks.scale_amount_curve = shrink
	var stroke := QuadMesh.new()
	stroke.size = Vector2(1.1, 0.02)
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color(1.0, 1.0, 1.0, 0.75)
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.disable_fog = true
	stroke.material = white
	_streaks.mesh = stroke
	_streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_streaks.position = Vector3(0.0, 0.75, 0.3)
	add_child(_streaks)

	# Drops of ink that fly off him when he is struck.
	_ink_drops = CPUParticles3D.new()
	_ink_drops.emitting = false
	_ink_drops.one_shot = true
	_ink_drops.explosiveness = 1.0
	_ink_drops.amount = ink_drops
	_ink_drops.lifetime = 0.7
	_ink_drops.local_coords = false
	_ink_drops.direction = Vector3.UP
	_ink_drops.spread = 75.0
	_ink_drops.initial_velocity_min = 2.0
	_ink_drops.initial_velocity_max = 5.5
	_ink_drops.gravity = Vector3(0.0, -15.0, 0.0)
	_ink_drops.scale_amount_min = 0.5
	_ink_drops.scale_amount_max = 1.6
	var drop := QuadMesh.new()
	drop.size = Vector2(0.07, 0.07)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = PaperMesh.SUMI
	black.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	black.disable_fog = true
	drop.material = black
	_ink_drops.mesh = drop
	_ink_drops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ink_drops.position = Vector3(0.0, 0.9, 0.3)
	add_child(_ink_drops)


## How far (in metres) the very end of the cloak can swing.
const CLOTH_REACH := 1.2
## Where the sculpted sword is on the model: the scabbard's mouth, and the
## direction the handle sticks out. Used to keep the scabbard stiff and to
## hide the handle while the katana is drawn.
const SCABBARD_MOUTH := Vector3(0.09, 0.915, 0.26)
const HANDLE_ALONG := Vector3(-0.25, 0.47, 0.84)


## Marks which parts of the model are loose cloth, by "painting" numbers into
## every point's colour (see paper_cloth.gdshader for what they mean).
func _paint_cloth(node: MeshInstance3D) -> void:
	var source := node.mesh
	var painted := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var paint := PackedColorArray()
		paint.resize(points.size())
		for i in points.size():
			var p := points[i]
			# Distance along, and away from, the line of the sword.
			var along := (p - SCABBARD_MOUTH).dot(HANDLE_ALONG.normalized())
			var away := (p - SCABBARD_MOUTH - HANDLE_ALONG.normalized() * along).length()
			var handle := 1.0 if along > 0.03 and along < 0.3 and away < 0.05 else 0.0
			var scabbard := along <= 0.03 and along > -0.85 and away < 0.07
			# Cloth: everything behind his back, the drapes at his sides, and
			# a little of the robe's hem. Nothing above the shoulders.
			var behind := smoothstep(0.0, 0.2, -0.02 - p.z)
			var beside := smoothstep(0.3, 0.45, absf(p.x + 0.04)) * 0.5
			var hem := smoothstep(0.0, 0.3, 0.5 - p.y) * 0.12
			var loose := maxf(behind, maxf(beside, hem)) * (1.0 - smoothstep(1.14, 1.22, p.y))
			var swing := 0.0 if scabbard or handle > 0.0 else loose * clampf(1.2 - p.y, 0.0, 1.1) / CLOTH_REACH
			paint[i] = Color(swing, fposmod(p.x * 1.7 + p.y * 2.3 + p.z * 1.1, 1.0), handle)
		arrays[Mesh.ARRAY_COLOR] = paint
		painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
				source.surface_get_format(surface) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
	node.mesh = painted


## Tells the cloth which way the air is pushing it: the wind, minus his own
## movement. So the cloak sways in a gust when he stands, streams behind him
## when he runs or dashes, and flies up when he falls.
func _blow_cloth(delta: float) -> void:
	var air := Wind.at(global_position.x) - Vector3(horizontal_speed, vertical_speed, 0.0)
	var space := _animator.skeleton.global_transform.basis.orthonormalized()
	var push := ((space.inverse() * air) / cloth_weight).limit_length(2.2)
	push.z = minf(push.z, 0.2)  # it cannot blow through his back
	push.y = minf(push.y, 0.85) # in a fall it lifts level, but not over his head
	_cloth_push = _cloth_push.lerp(push, 1.0 - exp(-cloth_follow * delta))
	_cloth.set_shader_parameter(&"push", _cloth_push)
	_cloth.set_shader_parameter(&"flutter_clock", _clock)


## Chooses the stance for what he is doing, and puts the skeleton in it.
func _pose_model() -> void:
	var airborne := state == &"jump" or state == &"fall"
	if _was_airborne and (state == &"idle" or state == &"run"):
		_land_clock = 0.0
		Sound.play(self, &"land")
	_was_airborne = airborne

	# Running eases in and out, so he tips forward over a few frames instead
	# of snapping from upright to leaning.
	if state == &"run":
		_run_blend = minf(1.0, _run_blend + _step / run_ease_in)
	else:
		_run_blend = maxf(0.0, _run_blend - _step / run_ease_out)

	var pose: Dictionary
	match state:
		&"jump", &"fall":
			pose = SamuraiAnimator.air(clampf(vertical_speed / jump_pose_speed, 0.0, 1.0),
					clampf(-vertical_speed / fall_pose_speed, 0.0, 1.0))
		&"dash":
			pose = SamuraiAnimator.dash()
		&"hurt":
			pose = SamuraiAnimator.hurt()
		&"heal":
			pose = SamuraiAnimator.heal(_clock)
		_:
			pose = SamuraiAnimator.idle(_clock)
			if _run_blend > 0.0:
				var before := _run_phase
				_run_phase = fposmod(_run_phase + _step * strides_per_second * lerpf(0.65, 1.0, _run_blend), 1.0)
				# A foot comes down at the start and the middle of every stride.
				if state == &"run" and (_run_phase < before or (before < 0.5 and _run_phase >= 0.5)):
					Sound.play(self, &"step")
				pose = SamuraiAnimator.mix(pose, SamuraiAnimator.run(_run_phase), smoothstep(0.0, 1.0, _run_blend))

	# Just touched down: crouch, then rise into whatever he is doing.
	if _land_clock >= 0.0:
		_land_clock += _step
		if _land_clock > land_time or airborne or state == &"dash" or state == &"hurt":
			_land_clock = -1.0
		else:
			var settle := _land_clock / land_time
			pose = SamuraiAnimator.mix(SamuraiAnimator.land(0.0), pose, smoothstep(0.35, 1.0, settle))

	# The cut. Standing still (or plunging down) it uses the whole body;
	# otherwise only the upper body, so he can cut while running or jumping.
	var cutting := _cut_clock >= 0.0 and not _sheathed
	if cutting:
		var cut := SamuraiAnimator.slash(_cut_clock / cut_time, _slash_dir)
		if (state == &"idle" and _run_blend <= 0.0) or _slash_dir.y < -0.5:
			pose = cut
		else:
			pose = SamuraiAnimator.with_upper_body(pose, cut)

	# A new kind of stance gets one in-between frame, so it does not pop.
	# (Standing and running count as one kind: the easing above handles them.)
	var kind: StringName = &"ground" if state == &"idle" or state == &"run" else state
	if kind != _shown_state and not cutting:
		_shown = SamuraiAnimator.mix(_shown, pose, pose_snap)
	else:
		_shown = pose
	_shown_state = kind
	_animator.apply(_shown)

	# A dash stretches him along the way he is going.
	_model.scale = Vector3(dash_stretch, 1.0 / sqrt(dash_stretch), 1.0) if state == &"dash" else Vector3.ONE
	_streaks.emitting = state == &"dash"

	# The katana. While it is out, the sculpted handle at his hip slides back
	# out of sight, so there is only ever one sword.
	var space := _animator.skeleton.global_transform
	_model_sword.visible = _animator.sword_out
	var slide := Vector3.ZERO
	if _animator.sword_out:
		slide = _animator.hips_turn * (-HANDLE_ALONG.normalized() * 0.32) / space.basis.get_scale().y
		var along := (space.basis * _animator.sword_dir).normalized()
		var edge := Vector3.BACK.cross(along)
		if edge.length() < 0.05:
			edge = Vector3.UP
		edge = edge.normalized()
		_model_sword.global_transform = Transform3D(Basis(along, edge, along.cross(edge)), space * _animator.sword_at)
	_cloth.set_shader_parameter(&"hilt_slide", slide)

	# Struck: ink splashes off him and soaks his paper black, then the blots
	# shrink away while he cannot be hurt again. (No flickering in and out.)
	if blinking and not _was_struck:
		_ink = 1.0
		_ink_drops.restart()
	_was_struck = blinking
	_ink = maxf(0.0, _ink - _step / ink_fade_time) if blinking else 0.0
	_cloth.set_shader_parameter(&"ink", _ink)


## Builds the white swoosh of a cut: one for forward cuts, which curves
## round him from his left to his right like the path of the blade, and one
## for cuts aimed up or down. Each is a single strip of paper; the shader
## slash_sweep.gdshader decides how much of the strip is showing.
func _build_sweeps() -> void:
	var steps := 30

	# Forward: a ribbon wrapped round him. It starts behind his left side,
	# passes in front, and ends at his right, a little higher. The ribbon
	# stands up on edge (like the wall of a bowl), so from the side it looks
	# broad in front of him and thin at the two ends.
	var side := SurfaceTool.new()
	side.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var across: float = corner[1]
			var angle := lerpf(deg_to_rad(-125.0), deg_to_rad(85.0), t)
			var swell := pow(sin(PI * t), 0.65)
			var radius := sweep_reach * (0.78 + 0.22 * sin(PI * t)) - sweep_reach * 0.2 * swell * (1.0 - across)
			var height := lerpf(-0.14, 0.24, t) + sweep_height * swell * (across - 0.5)
			side.set_uv(Vector2(t, across))
			side.add_vertex(Vector3(cos(angle) * radius, height, sin(angle) * radius))
	_sweep_tilt = _piece(self, Vector3(0.0, 0.95, 0.0))
	_sweep_tilt.rotation.x = 0.25  # tipped toward the camera, so we see it as an open curve
	_sweep_side = _sweep_strip(side.commit())
	_sweep_tilt.add_child(_sweep_side)

	# Up or down: a crescent standing upright, facing the camera. It starts
	# in front of him and runs up and over (or, flipped, down and under).
	var tall := SurfaceTool.new()
	tall.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var across: float = corner[1]
			var angle := lerpf(deg_to_rad(18.0), deg_to_rad(150.0), t)
			var wide := sweep_reach * 0.3 * pow(sin(PI * t), 0.65)
			var radius := sweep_reach * 1.05 - wide * (1.0 - across)
			tall.set_uv(Vector2(t, across))
			tall.add_vertex(Vector3(cos(angle) * radius, sin(angle) * radius, 0.0))
	_sweep_tall = _sweep_strip(tall.commit())
	# This parent flips it: left-right for the way he faces, and upside down
	# for a downward cut.
	_sweep_flip = _piece(self, Vector3(0.0, 0.85, 0.4))
	_sweep_flip.add_child(_sweep_tall)


## One swoosh strip with its own copy of the swoosh material. It is always
## "visible" but drawn fully see-through until a cut, so the game does not
## stutter the first time he strikes.
func _sweep_strip(mesh: Mesh) -> MeshInstance3D:
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/slash_sweep.gdshader")
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = look
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return strip


## Moves the swoosh on, every frame (not 12 times a second: it should be
## smooth). It is drawn on from the end where the cut starts, then wiped
## away from that same end, and is gone exactly when the cut ends.
func _update_sweep() -> void:
	var head := 0.0
	var tail := 0.0
	if _cut_clock >= 0.0:
		var through := clampf(_cut_clock / cut_time, 0.0, 1.0)
		head = smoothstep(0.0, sweep_draw, through) * 1.03
		# The wipe starts gently and finishes right at the end of the cut,
		# so the last of the swoosh goes as the sword is put away.
		var wiped := pow(clampf((through - sweep_wipe_from) / (1.0 - sweep_wipe_from), 0.0, 1.0), 2.0)
		tail = wiped * 1.12 - 0.12 * (1.0 - through)
	var aimed := absf(_slash_dir.y) > 0.5
	var side_look := _sweep_side.material_override as ShaderMaterial
	var tall_look := _sweep_tall.material_override as ShaderMaterial
	side_look.set_shader_parameter(&"head", 0.0 if aimed else head)
	side_look.set_shader_parameter(&"tail", tail)
	tall_look.set_shader_parameter(&"head", head if aimed else 0.0)
	tall_look.set_shader_parameter(&"tail", tail)
	# The sideways swoosh turns with him; the upright one is flipped to
	# match the way he faces and whether the cut goes up or down.
	_sweep_side.rotation.y = _rig.rotation.y
	_sweep_flip.scale = Vector3(1.0 if facing > 0.0 else -1.0, -1.0 if _slash_dir.y < -0.5 else 1.0, 1.0)


## Folds the katana he draws: a slim, gently curved blade with a pale cutting
## edge, a small dark guard, and a handle wrapped like the sculpted one.
## It lies along +X with its cutting edge toward -Y.
func _fold_slim_katana(pivot: Node3D) -> void:
	var b := _sheet(121, PaperMesh.SUMI)
	b.shade_jitter = 0.1
	b.box(Vector3(-0.075, 0.0, 0.0), Vector3(0.25, 0.03, 0.024))      # handle
	b.color = Color(0.32, 0.28, 0.2)
	b.box(Vector3(0.058, 0.0, 0.0), Vector3(0.012, 0.07, 0.055))      # guard
	b.box(Vector3(-0.203, 0.0, 0.0), Vector3(0.012, 0.034, 0.028))    # end cap
	b.color = PaperMesh.WASHI
	b.shade_jitter = 0.0
	for i in 4:  # the pale diamonds of the wrap
		var x := -0.165 + i * 0.058
		for side: float in [1.0, -1.0]:
			b.quad(Vector3(x - 0.018, 0.0, side * 0.0135), Vector3(x, 0.011, side * 0.0135),
					Vector3(x + 0.018, 0.0, side * 0.0135), Vector3(x, -0.011, side * 0.0135), Vector3(0.0, 0.0, side))
	# The blade, in short lengths that follow a gentle upward curve. The
	# last length runs to a point on the back edge, like a real katana's tip.
	var steps := 8
	var start := 0.066
	var length := 0.74
	for side: float in [1.0, -1.0]:
		var z := side * 0.003
		var tip := Vector3(start + length, 0.05 + 0.011, z)
		for i in steps:
			var t0 := float(i) / steps
			var t1 := float(i + 1) / steps
			var x0 := start + length * t0
			var x1 := start + length * t1
			var y0 := 0.05 * t0 * t0
			var y1 := 0.05 * t1 * t1
			var w0 := lerpf(0.015, 0.011, t0)
			var w1 := lerpf(0.015, 0.011, t1)
			var back0 := Vector3(x0, y0 + w0, z)
			var mid0 := Vector3(x0, y0, z)
			var edge0 := Vector3(x0, y0 - w0, z)
			var facing := Vector3(0.0, 0.0, side)
			if i == steps - 1:
				b.color = Color(0.74, 0.76, 0.8)
				b.tri(back0, tip, mid0, facing)
				b.color = Color(1.0, 1.0, 1.0)
				b.tri(mid0, tip, edge0, facing)
			else:
				b.color = Color(0.74, 0.76, 0.8)   # the back of the blade
				b.quad(back0, Vector3(x1, y1 + w1, z), Vector3(x1, y1, z), mid0, facing)
				b.color = Color(1.0, 1.0, 1.0)     # the bright cutting edge
				b.quad(mid0, Vector3(x1, y1, z), Vector3(x1, y1 - w1, z), edge0, facing)
	var mesh := _finish(b, pivot)
	(mesh.material_override as StandardMaterial3D).emission_energy_multiplier = paper_glow * 2.5


## Slim legs with small folded feet. They swing from the hip, under the robe.
func _build_legs() -> void:
	_leg_front = _piece(_rig, Vector3(0.0, 0.62, 0.075))
	_leg_back = _piece(_rig, Vector3(0.0, 0.62, -0.075))
	var seed_value := 11
	for leg: Node3D in [_leg_front, _leg_back]:
		var b := _sheet(seed_value, Color(0.88, 0.85, 0.8))
		seed_value += 1
		b.loft([
			PaperMesh.oval(Vector3(0.0, -0.53, 0.0), Vector2(0.045, 0.042), 5, 0.6),
			PaperMesh.oval(Vector3(0.0, -0.3, 0.0), Vector2(0.062, 0.055), 5, 0.6),
			PaperMesh.oval(Vector3(0.0, 0.0, 0.0), Vector2(0.085, 0.07), 5, 0.6),
		])
		b.color = PaperMesh.WASHI
		b.extrude(PackedVector2Array([
			Vector2(-0.06, -0.62), Vector2(0.15, -0.62), Vector2(0.14, -0.585),
			Vector2(0.03, -0.525), Vector2(-0.06, -0.525),
		]), -0.045, 0.045)
		_finish(b, leg)


## The long robe: a skirt to mid-calf with a ragged hem, a sash, the chest,
## and a short mantle draped over the shoulders.
func _build_robe() -> void:
	var skirt := _sheet(21, Color(0.9, 0.87, 0.82))
	skirt.shade_jitter = 0.13
	skirt.loft([
		PaperMesh.oval(Vector3(0.01, -0.36, 0.0), Vector2(0.21, 0.2), 7, 0.22),
		PaperMesh.oval(Vector3(0.0, -0.1, 0.0), Vector2(0.165, 0.175), 7, 0.22),
		PaperMesh.oval(Vector3(0.0, 0.14, 0.0), Vector2(0.125, 0.15), 7, 0.22),
	], false, false)
	_finish(skirt, _body)

	var folds := _sheet(22)
	# The front of the robe wraps across: one long fold from sash to hem.
	folds.quad(Vector3(0.135, 0.14, 0.0), Vector3(0.1, 0.14, 0.12), Vector3(0.17, -0.4, 0.17),
			Vector3(0.235, -0.43, 0.0), Vector3(1.0, 0.0, 0.5))
	folds.quad(Vector3(0.135, 0.14, 0.0), Vector3(0.1, 0.14, -0.12), Vector3(0.16, -0.37, -0.17),
			Vector3(0.225, -0.39, -0.01), Vector3(1.0, 0.0, -0.5))
	# Torn points hanging below the hem.
	for p: Array in [[70.0, -0.47], [128.0, -0.44], [-75.0, -0.46], [-130.0, -0.43], [178.0, -0.48]]:
		var angle := deg_to_rad(p[0])
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-sin(angle), 0.0, cos(angle))
		var top := Vector3(out.x * 0.19, -0.2, out.z * 0.185)
		var low := Vector3(out.x * 0.225, -0.36, out.z * 0.215)
		var tip := Vector3(out.x * 0.24, p[1], out.z * 0.23)
		folds.quad(top - side * 0.05, top + out * 0.01, tip, low - side * 0.1, out - side * 0.4)
		folds.quad(top + out * 0.01, top + side * 0.05, low + side * 0.1, tip, out + side * 0.4)
	_finish(folds, _body)

	var top := _sheet(23)
	top.color = Color(0.82, 0.79, 0.74)  # sash
	top.loft([
		PaperMesh.oval(Vector3(0.0, 0.1, 0.0), Vector2(0.134, 0.158), 7, 0.22),
		PaperMesh.oval(Vector3(0.0, 0.175, 0.0), Vector2(0.13, 0.155), 7, 0.22),
	], false, false)
	top.color = PaperMesh.WASHI      # chest
	top.loft([
		PaperMesh.oval(Vector3(0.0, 0.14, 0.0), Vector2(0.12, 0.145), 7, 0.22),
		PaperMesh.oval(Vector3(0.0, 0.3, 0.0), Vector2(0.13, 0.175), 7, 0.22),
		PaperMesh.oval(Vector3(0.0, 0.44, 0.0), Vector2(0.09, 0.14), 7, 0.22),
	])
	top.shade_jitter = 0.14          # mantle over the shoulders
	top.loft([
		PaperMesh.oval(Vector3(-0.02, 0.19, 0.0), Vector2(0.2, 0.25), 7, 0.5),
		PaperMesh.oval(Vector3(-0.01, 0.36, 0.0), Vector2(0.15, 0.205), 7, 0.5),
		PaperMesh.oval(Vector3(0.0, 0.48, 0.0), Vector2(0.07, 0.08), 7, 0.5),
	], false, false)
	_finish(top, _body)


## The cowl: paper gathered in thick folds round the neck.
func _build_cowl() -> void:
	var b := _sheet(41, scarf_color)
	b.shade_jitter = 0.16
	b.loft([
		PaperMesh.oval(Vector3(0.0, 0.41, 0.0), Vector2(0.135, 0.15), 7, 0.2),
		PaperMesh.oval(Vector3(0.01, 0.49, 0.0), Vector2(0.115, 0.125), 7, 0.2),
	])
	b.loft([
		PaperMesh.oval(Vector3(0.015, 0.47, 0.0), Vector2(0.11, 0.12), 7, 0.75),
		PaperMesh.oval(Vector3(0.025, 0.545, 0.0), Vector2(0.088, 0.095), 7, 0.75),
	])
	_finish(b, _body)


## The cloak's torn tails: four long shards fanned down his back, each in two
## hinged pieces so they whip a little as they stream behind him.
func _build_cloak_tails() -> void:
	# [where it joins the body, length, width at the root]
	var seed_value := 51
	for t: Array in [[Vector3(-0.09, 0.37, 0.05), 0.98, 0.24], [Vector3(-0.11, 0.21, -0.06), 0.86, 0.26],
			[Vector3(-0.12, 0.04, 0.045), 0.7, 0.26], [Vector3(-0.13, -0.13, -0.04), 0.46, 0.24]]:
		var length: float = t[1]
		var width: float = t[2]
		var near := length * 0.55   # length of the base piece
		var far := length * 0.45    # length of the end piece
		var base := _piece(_body, t[0])
		var b := _sheet(seed_value)
		seed_value += 1
		b.shade_jitter = 0.16
		var root_top := Vector3(0.04, width * 0.5, 0.0)
		var root_mid := Vector3(0.04, 0.0, 0.03)
		var root_low := Vector3(0.04, -width * 0.5, 0.0)
		var end_top := Vector3(-near, width * 0.36, -0.015)
		var end_mid := Vector3(-near, 0.0, 0.04)
		var end_low := Vector3(-near, -width * 0.4, -0.015)
		b.quad(root_top, root_mid, end_mid, end_top)
		b.quad(root_mid, root_low, end_low, end_mid)
		# A torn barb off the lower edge.
		b.tri(root_low.lerp(end_low, 0.35), root_low.lerp(end_low, 0.8), Vector3(-near * 0.8, -width * 0.72, 0.0))
		_finish(b, base)
		_tails.append(base)

		var tip := _piece(base, Vector3(-near, 0.0, 0.0))
		var e := _sheet(seed_value)
		seed_value += 1
		e.shade_jitter = 0.16
		var point := Vector3(-far, -width * 0.05, 0.0)
		var crease := Vector3(-far * 0.45, 0.0, 0.035)
		e.tri(Vector3(0.0, width * 0.36, -0.015), Vector3(0.0, 0.0, 0.04), crease)
		e.tri(Vector3(0.0, width * 0.36, -0.015), crease, Vector3(-far * 0.7, width * 0.24, 0.0))
		e.tri(Vector3(0.0, 0.0, 0.04), Vector3(0.0, -width * 0.4, -0.015), crease)
		e.tri(Vector3(0.0, -width * 0.4, -0.015), Vector3(-far * 0.55, -width * 0.42, 0.0), crease)
		e.tri(crease, Vector3(-far * 0.7, width * 0.12, 0.0), point)
		e.tri(crease, point, Vector3(-far * 0.6, -width * 0.2, 0.0))
		_finish(e, tip)
		_tail_tips.append(tip)


## The katana's scabbard through his sash at the left hip, handle forward.
func _build_scabbard() -> void:
	var pivot := _piece(_body, Vector3(0.11, 0.15, -0.1))
	pivot.rotation = Vector3(0.0, -0.2, 0.27)
	var s := _sheet(61, Color(0.74, 0.72, 0.7))
	s.box(Vector3(-0.3, 0.0, 0.0), Vector3(0.62, 0.05, 0.04))
	_finish(s, pivot)
	_hilt = _piece(pivot, Vector3.ZERO)
	_build_handle(_hilt, 62)


## The handle and guard: dark wrap with small pale diamonds, as in the picture.
func _build_handle(parent: Node3D, seed_value: int) -> void:
	var b := _sheet(seed_value, Color(0.3, 0.27, 0.2))
	b.shade_jitter = 0.15
	b.box(Vector3(0.02, 0.0, 0.0), Vector3(0.025, 0.1, 0.09))
	b.color = PaperMesh.SUMI
	b.box(Vector3(0.175, 0.0, 0.0), Vector3(0.29, 0.05, 0.042))
	b.color = PaperMesh.WASHI
	b.shade_jitter = 0.0
	for i in 4:
		var x := 0.075 + i * 0.066
		for side: float in [1.0, -1.0]:
			b.quad(Vector3(x - 0.022, 0.0, side * 0.023), Vector3(x, 0.017, side * 0.023),
					Vector3(x + 0.022, 0.0, side * 0.023), Vector3(x, -0.017, side * 0.023), Vector3(0.0, 0.0, side))
	b.box(Vector3(0.325, 0.0, 0.0), Vector3(0.015, 0.055, 0.047))
	_finish(b, parent)


## The blank mask: a flat front, bevelled cheeks, a narrow chin, and two
## slanted slits for eyes (mostly hidden under the hat). No mouth.
func _build_head() -> void:
	var b := _sheet(71, Color(0.97, 0.95, 0.91))
	b.shade_jitter = 0.06
	# Each ring: [height, front x, front half-width, cheek x, cheek half-width, back x, back half-width]
	var rings := []
	for r: Array in [[-0.03, 0.068, 0.03, 0.04, 0.058, 0.06, 0.05],
			[0.06, 0.097, 0.048, 0.05, 0.094, 0.082, 0.085],
			[0.2, 0.09, 0.05, 0.05, 0.09, 0.082, 0.085]]:
		rings.append(PackedVector3Array([
			Vector3(r[1], r[0], r[2]), Vector3(r[3], r[0], r[4]), Vector3(-r[5], r[0], r[6]),
			Vector3(-r[5], r[0], -r[6]), Vector3(r[3], r[0], -r[4]), Vector3(r[1], r[0], -r[2]),
		]))
	b.loft(rings)
	b.color = PaperMesh.SUMI
	b.shade_jitter = 0.0
	for side: float in [1.0, -1.0]:
		var inner := Vector3(0.099, 0.082, side * 0.008)
		var top := Vector3(0.099, 0.108, side * 0.048)
		var bottom := Vector3(0.099, 0.09, side * 0.048)
		var outer := Vector3(0.076, 0.116, side * 0.074)
		b.tri(inner, top, bottom, Vector3.RIGHT)
		b.tri(top, outer, bottom, Vector3(1.0, 0.0, side))
	_finish(b, _head)


## The kasa: a wide, shallow paper cone tipped slightly forward, so the brim
## hides his eyes. The underside is in shadow.
func _build_hat() -> void:
	var pivot := _piece(_head, Vector3(-0.01, 0.125, 0.0))
	pivot.rotation.z = -0.09
	var b := _sheet(81, hat_color)
	b.shade_jitter = 0.11
	var sides := 9
	var apex := Vector3(0.0, 0.32, 0.0)
	var inside := Vector3(0.0, 0.17, 0.0)
	var rim: Array[Vector3] = []
	for i in sides:
		var angle := TAU * i / sides + 0.2
		rim.append(Vector3(cos(angle) * 0.42, 0.0, sin(angle) * 0.42))
	for i in sides:
		var a := rim[i]
		var c := rim[(i + 1) % sides]
		b.color = hat_color
		b.tri(a, c, apex, a + c + Vector3.UP)
		b.color = hat_color * 0.5
		b.tri(a, c, inside, Vector3.DOWN)
	b.color = hat_color
	b.frustum(4, Vector2(0.035, 0.035), Vector2.ZERO, 0.06, Vector3(0.0, 0.305, 0.0))
	_finish(b, pivot)


## Sleeves that widen to the cuff, with a small folded hand.
func _build_arms() -> void:
	_arm_front = _piece(_body, Vector3(0.0, 0.4, 0.17))
	_arm_back = _piece(_body, Vector3(0.0, 0.4, -0.17))
	var seed_value := 91
	for arm: Node3D in [_arm_front, _arm_back]:
		var side := 1.0 if arm == _arm_front else -1.0
		var splay := _piece(arm, Vector3.ZERO)
		splay.rotation.x = -0.12 * side
		var b := _sheet(seed_value)
		seed_value += 1
		b.loft([
			PaperMesh.oval(Vector3(0.0, -0.31, 0.0), Vector2(0.11, 0.075), 5, 0.6),
			PaperMesh.oval(Vector3(0.0, -0.15, 0.0), Vector2(0.085, 0.07), 5, 0.6),
			PaperMesh.oval(Vector3(0.0, 0.03, 0.0), Vector2(0.06, 0.06), 5, 0.6),
		], false, true)
		# The hanging corner of the sleeve.
		b.tri(Vector3(-0.09, -0.31, 0.04), Vector3(-0.09, -0.31, -0.04), Vector3(-0.09, -0.43, 0.0), Vector3.LEFT)
		b.tri(Vector3(-0.09, -0.31, 0.04), Vector3(0.02, -0.31, 0.07), Vector3(-0.09, -0.43, 0.0), Vector3(0.0, 0.0, 1.0))
		b.tri(Vector3(-0.09, -0.31, -0.04), Vector3(0.02, -0.31, -0.07), Vector3(-0.09, -0.43, 0.0), Vector3(0.0, 0.0, -1.0))
		b.color = Color(0.98, 0.96, 0.92)
		b.box(Vector3(0.03, -0.345, 0.0), Vector3(0.065, 0.07, 0.06))
		_finish(b, splay)


## The drawn katana: "a single razor-sharp fold". One is built for each hand;
## it is only shown during a slash, in the hand nearest the camera.
func _build_sword(arm: Node3D, hand_side: float) -> Node3D:
	var pivot := _piece(arm, Vector3(0.03, -0.345, 0.05 * hand_side))
	_fold_katana(pivot)
	return pivot


## Folds the katana (handle, guard and blade pointing along +X) into `pivot`.
func _fold_katana(pivot: Node3D) -> void:
	# The same handle as in the scabbard, turned round so it sits in his fist
	# with the guard in front.
	var grip := _piece(pivot, Vector3(0.16, 0.0, 0.0))
	grip.rotation.y = PI
	_build_handle(grip, 101)
	var b := _sheet(102, Color(1.0, 1.0, 1.0))
	b.shade_jitter = 0.05
	var start := 0.15
	var length := 0.92
	for side: float in [1.0, -1.0]:
		var ridge := Vector3(0.0, 0.008, side * 0.012)
		# Back of the blade, then the cutting edge, on each face.
		b.quad(Vector3(start, 0.028, 0.0), Vector3(start, 0.0, 0.0) + ridge,
				Vector3(start + length - 0.05, 0.0, 0.0) + ridge, Vector3(start + length, 0.028, 0.0),
				Vector3(0.0, 0.3, side))
		b.quad(Vector3(start, 0.0, 0.0) + ridge, Vector3(start, -0.03, 0.0),
				Vector3(start + length - 0.09, -0.03, 0.0), Vector3(start + length - 0.05, 0.0, 0.0) + ridge,
				Vector3(0.0, -0.3, side))
		b.tri(Vector3(start + length - 0.05, 0.0, 0.0) + ridge, Vector3(start + length - 0.09, -0.03, 0.0),
				Vector3(start + length, 0.028, 0.0), Vector3(0.3, -0.3, side))
	var mesh := _finish(b, pivot)
	(mesh.material_override as StandardMaterial3D).emission_energy_multiplier = paper_glow * 3.0


## The slash arc: a white paper crescent that flashes when you attack.
## It is NOT inside the rig, so it stays flat to the camera.
func _build_arc() -> void:
	_arc = _piece(self, Vector3(0.0, 0.85, 0.4))
	var arc := PaperMesh.new(111)
	arc.shade_jitter = 0.0
	arc.texture_scale = 0.0
	var steps := 8
	var half_angle := deg_to_rad(58.0)
	for i in steps:
		var a0 := lerpf(-half_angle, half_angle, float(i) / steps)
		var a1 := lerpf(-half_angle, half_angle, float(i + 1) / steps)
		var inner0 := arc_radius - 0.3 * cos(a0 / half_angle * PI * 0.5)
		var inner1 := arc_radius - 0.3 * cos(a1 / half_angle * PI * 0.5)
		arc.quad(
			Vector3(cos(a0) * arc_radius, sin(a0) * arc_radius, 0.0),
			Vector3(cos(a1) * arc_radius, sin(a1) * arc_radius, 0.0),
			Vector3(cos(a1) * inner1, sin(a1) * inner1, 0.0),
			Vector3(cos(a0) * inner0, sin(a0) * inner0, 0.0))
	var arc_mesh := arc.build(Color(1.0, 1.0, 1.0, 0.92), 0.0, true)
	arc_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arc.add_child(arc_mesh)
	_arc.visible = false


# --- Posing ---------------------------------------------------------------
# All angles are in radians, rotating around the Z axis (the axis pointing at
# the camera). Positive = swings forward/up, negative = swings back.
# For the cloak, 0 = streaming straight back, positive = hanging down,
# negative = flying up.

func _pose() -> void:
	var t := _clock
	var lean := -0.05      # body tilt (negative = leaning forward)
	var bob := 0.0         # body height offset
	var leg_f := 0.12
	var leg_b := -0.12
	var arm_f := 0.5       # the sword arm; 0.5 rests the hand on the handle
	var arm_b := -0.1
	var blade := 0.0       # where the drawn sword points: 0 = ahead, PI/2 = straight up
	var cloak := cloak_hang + sin(t * 2.2) * 0.07
	var flutter := sin(t * 2.2 + 1.0) * 0.12
	var head_tilt := 0.0

	match state:
		&"idle":
			bob = sin(t * 2.5) * 0.01
		&"run":
			var p := t * run_cycle_speed
			leg_f = sin(p) * 0.7
			leg_b = -sin(p) * 0.7
			lean = -0.2
			bob = absf(cos(p)) * 0.04
			arm_b = sin(p) * 0.6 - 0.2
			head_tilt = 0.08
			cloak = cloak_stream + sin(t * 17.0) * 0.1
			flutter = sin(t * 17.0 + 1.5) * 0.28
		&"jump":
			leg_f = 0.7
			leg_b = -0.25
			arm_b = -0.7
			lean = -0.08
			cloak = cloak_hang + 0.2
			flutter = 0.25
		&"fall":
			leg_f = 0.3
			leg_b = -0.5
			arm_f = 0.7
			arm_b = 1.5
			cloak = -0.55 + sin(t * 20.0) * 0.08
			flutter = -0.3 + sin(t * 20.0 + 1.0) * 0.15
		&"dash":
			lean = -0.75
			leg_f = -0.5
			leg_b = -0.9
			arm_b = -1.0
			head_tilt = 0.4
			cloak = 0.05
			flutter = sin(t * 30.0) * 0.1
		&"hurt":
			lean = 0.4
			leg_f = 0.4
			leg_b = 0.2
			arm_f = 1.3
			arm_b = 1.2
			cloak = 1.5
			flutter = 0.3
		&"heal":
			bob = -0.16
			lean = -0.2
			leg_f = 0.6
			leg_b = -0.6
			arm_f = 0.7
			arm_b = 0.7
			head_tilt = -0.25
			cloak = cloak_hang + 0.25

	# A slash overrides the sword arm, whatever else the body is doing.
	if _slash_clock >= 0.0:
		var p := clampf(_slash_clock / slash_show_time, 0.0, 1.0)
		if _slash_dir.y > 0.5:
			arm_f = lerpf(1.6, 3.4, p)
			blade = lerpf(0.3, 2.4, p)
		elif _slash_dir.y < -0.5:
			arm_f = lerpf(1.2, -0.1, p)
			blade = lerpf(-0.3, -2.2, p)
			lean -= 0.2
		else:
			arm_f = lerpf(2.3, 0.7, p)
			blade = lerpf(1.6, -0.7, p)
			lean += lerpf(0.1, -0.2, p)

	if _model:
		# The sculpted model is posed by samurai_animator.gd instead.
		_pose_model()
		return

	_body.position.y = 0.62 + bob
	_body.rotation.z = lean
	_head.rotation.z = head_tilt
	_leg_front.rotation.z = leg_f
	_leg_back.rotation.z = leg_b
	# "arm_f" is the sword arm: whichever one is nearest the camera.
	var near_arm := _arm_front if facing > 0.0 else _arm_back
	var far_arm := _arm_back if facing > 0.0 else _arm_front
	near_arm.rotation.z = arm_f
	far_arm.rotation.z = arm_b
	_sword.rotation.z = blade - arm_f - lean
	_sword_far.rotation.z = blade - arm_f - lean
	# Cloak tails: fanned out, the upper ones flying highest.
	var fan := [-0.2, 0.0, 0.2, 0.42]
	for i in _tails.size():
		var spread: float = fan[i]
		_tails[i].rotation.z = cloak + spread - lean + sin(t * 3.1 + i * 1.3) * 0.04
		_tail_tips[i].rotation.z = flutter * (1.0 if i % 2 == 0 else -0.7)

	_show_arc()
	# Blink while invulnerable after being hurt.
	_rig.visible = not blinking or _frame % 2 == 0


## Flashes the white crescent in the direction of the slash.
func _show_arc() -> void:
	_arc.visible = _slash_clock >= 0.0 and _slash_clock <= arc_show_time
	if _arc.visible:
		var grow := lerpf(0.85, 1.05, clampf(_slash_clock / arc_show_time, 0.0, 1.0))
		if absf(_slash_dir.y) > 0.5:
			_arc.rotation.z = PI * 0.5 * signf(_slash_dir.y)
			_arc.scale = Vector3(grow, grow, 1.0)
		else:
			_arc.rotation.z = 0.0
			_arc.scale = Vector3(grow * facing, grow, 1.0)

