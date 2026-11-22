class_name HannyaEnding
extends Node
## After the Weeping Hannya falls (docs/lore.md, "After her": proposed, not
## yet approved by Julian). About 16 seconds, 2.5D shots only (the camera
## stays in front of the diorama: pushes, pans, a crane up):
##  - close on her: a crack is drawn across her mask; black ink runs out of
##    it in drips, and the mask she wears is washed blank white (Shizu, at
##    peace). (A copy of the mask used to fall off her, which looked like her
##    head falling, and a flat oval stood in for her face: Julian chose this
##    instead.)
##  - she comes apart into pale paper scraps that rise into the rain;
##  - the courtyard's lanterns light again, one by one;
##  - the Rain eases for a breath, and the far gate swings open on the road
##    to the bamboo, light beyond it;
##  - the camera glides back to the game. Hold Space to skip.
## Her intro cutscene (hannya_cutscene.gd) is not touched.

signal finished

const LENGTH := 16.0

var main: Node
var ronin: Ronin
var village: Village
var boss: HannyaBoss
var game_camera: Camera3D

var _time := -0.01
var _camera: Camera3D
var _keys: Array = []            # [time, position, look-at, cut?]
var _events: Array = []
var _next_event := 0
var _bars: Array[ColorRect] = []
var _hud: CanvasItem
var _crack: MeshInstance3D
var _crack_mesh: ImmediateMesh
var _crack_points := PackedVector3Array()
var _crack_grow := 0.0
var _wash: ShaderMaterial
var _head := Vector3.ZERO
var _her := Vector3.ZERO
var _done := false


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.cull_mask &= ~Hannya.SHADOW_LAYER
	_camera.fov = 38.0
	_camera.near = 0.03
	add_child(_camera)
	_camera.global_transform = game_camera.global_transform
	_camera.current = true
	ronin.set_physics_process(false)
	ronin.velocity = Vector3.ZERO
	var puppet: RoninPuppet = ronin.get_node("Puppet")
	puppet.state = &"idle"
	puppet.facing = signf(boss.global_position.x - ronin.global_position.x)
	_hud = main.get_node("Overlay/HUD")
	_hud.visible = false
	_her = boss.global_position
	village.stage.show_torn()
	_head = boss.puppet.head_position()
	_build_overlay()
	_build_crack()
	_plan()


func _plan() -> void:
	var g := _her.y
	var m := (Village.ARENA.x + Village.ARENA.y) * 0.5
	var side := -1.0 if ronin.global_position.x < _her.x else 1.0
	_keys = [
		# Close on her face, pushing in slowly.
		[0.0, _head + Vector3(side * 0.7, 0.15, 3.6), _head, false],
		[3.4, _head + Vector3(side * 0.35, 0.05, 2.5), _head + Vector3(0.0, -0.1, 0.0), false],
		# Wider: she comes apart; the camera cranes up and back over the courtyard.
		[3.45, Vector3(_her.x, g + 2.0, 6.0), Vector3(_her.x, g + 1.2, 0.0), true],
		[6.0, Vector3(lerpf(_her.x, m, 0.5), g + 3.2, 10.5), Vector3(lerpf(_her.x, m, 0.5), g + 1.4, -1.5), false],
		[8.6, Vector3(m, g + 3.0, 12.0), Vector3(m, g + 1.8, -2.0), false],
		# Pan right to the far gate as the rain eases and it opens.
		[11.0, Vector3(Village.ARENA.y - 3.5, g + 2.4, 8.5), Vector3(Village.ARENA.y + 1.5, g + 1.6, -1.0), false],
		# Held on the open gate, pushing in a little toward the light beyond.
		[14.2, Vector3(Village.ARENA.y - 2.8, g + 2.2, 7.4), Vector3(Village.ARENA.y + 1.5, g + 1.6, -1.0), false],
	]
	_events = [
		[0.0, _bars_in],
		[0.7, func() -> void:
			_crack_grow = 0.001
			Sound.play(self, &"mask_creak", 2.0)],
		[1.4, _bleed_white],
		[3.6, _dissolve],
		[6.1, func() -> void: _relight(0)],
		[6.8, func() -> void: _relight(1)],
		[8.0, _ease_rain],
		[9.2, func() -> void: village.bamboo.open_gate()],
		[14.3, _bars_out],
		[14.3, _glide_home],
	]


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	while _next_event < _events.size() and _time >= _events[_next_event][0]:
		(_events[_next_event][1] as Callable).call()
		_next_event += 1
	if _time < 14.3:
		_place_camera()
	if _crack_grow > 0.0 and _crack_grow < 1.0:
		_crack_grow = minf(_crack_grow + delta / 0.55, 1.0)
		_draw_crack()
	if _time >= LENGTH:
		_finish()


## The camera along its keys: smooth between keys, a cut where a key says so.
func _place_camera() -> void:
	for i in _keys.size() - 1:
		var a: Array = _keys[i]
		var b: Array = _keys[i + 1]
		if _time >= a[0] and _time < b[0]:
			if b[3]:
				_look(a[1], a[2])  # (held until the cut)
				return
			var u := smoothstep(0.0, 1.0, (_time - a[0]) / (b[0] - a[0]))
			_look((a[1] as Vector3).lerp(b[1], u), (a[2] as Vector3).lerp(b[2], u))
			return
	var last: Array = _keys[_keys.size() - 1]
	_look(last[1], last[2])


func _look(from: Vector3, at: Vector3) -> void:
	_camera.global_position = from
	_camera.look_at(at, Vector3.UP)


# --- What happens -------------------------------------------------------------------

## A crack in the mask, drawn on in ink from the brow down across the face.
func _build_crack() -> void:
	_crack_mesh = ImmediateMesh.new()
	_crack = MeshInstance3D.new()
	_crack.mesh = _crack_mesh
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.03, 0.03, 0.05)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.no_depth_test = true
	look.render_priority = 2
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_crack.material_override = look
	add_child(_crack)
	_crack.global_position = _head + Vector3(0.0, 0.0, 0.32)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var p := Vector3(0.02, 0.2, 0.0)
	_crack_points.append(p)
	for k in 7:
		p += Vector3(rng.randf_range(-0.06, 0.06), -0.06, 0.0)
		_crack_points.append(p)


func _draw_crack() -> void:
	_crack_mesh.clear_surfaces()
	var shown := _crack_points.size() * _crack_grow
	if shown < 1.1:
		return
	_crack_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in int(shown):
		var p := _crack_points[i]
		var w := 0.026 * (1.0 - float(i) / _crack_points.size()) + 0.008
		_crack_mesh.surface_add_vertex(p + Vector3(-w, 0.0, 0.0))
		_crack_mesh.surface_add_vertex(p + Vector3(w, 0.0, 0.0))
	_crack_mesh.surface_end()


## The crack runs; ink bleeds out of the mask in drips, and the mask is
## washed blank white, spreading from the middle of her face (laid over her
## own paper: shaders/wash_white.gdshader).
func _bleed_white() -> void:
	Sound.play(self, &"ink_bleed", -2.0)
	var puppet := boss.puppet
	var centre := _head + Vector3(signf(ronin.global_position.x - _her.x) * 0.1, 0.06, 0.08)
	_wash = ShaderMaterial.new()
	_wash.shader = preload("res://shaders/wash_white.gdshader")
	_wash.set_shader_parameter(&"centre", centre)
	for mesh: GeometryInstance3D in puppet.get("_flash_meshes"):
		mesh.material_overlay = _wash
	var spread := create_tween()
	spread.tween_method(func(v: float) -> void: _wash.set_shader_parameter(&"amount", v), 0.0, 1.0, 1.9).set_trans(Tween.TRANS_SINE)
	# The crack is soaked away with the rest.
	spread.parallel().tween_property(_crack.material_override, "albedo_color:a", 0.0, 1.6).set_delay(0.3)
	# Ink running out of it: dark drops falling from the mask.
	var drips := CPUParticles3D.new()
	drips.amount = 26
	drips.lifetime = 0.9
	drips.explosiveness = 0.0
	drips.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	drips.emission_sphere_radius = 0.1
	drips.direction = Vector3.DOWN
	drips.spread = 10.0
	drips.gravity = Vector3(0.0, -6.0, 0.0)
	drips.initial_velocity_min = 0.1
	drips.initial_velocity_max = 0.4
	drips.scale_amount_min = 0.5
	drips.scale_amount_max = 1.2
	var drop := QuadMesh.new()
	drop.size = Vector2(0.035, 0.05)
	drop.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.06, 0.95))
	drips.mesh = drop
	village.add_child(drips)
	drips.global_position = centre + Vector3(0.0, -0.08, 0.05)
	drips.emitting = true
	get_tree().create_timer(1.8).timeout.connect(func() -> void: drips.emitting = false)
	get_tree().create_timer(3.0).timeout.connect(drips.queue_free)


## She comes apart: pale scraps lift off her and rise into the rain while
## she fades, her face last.
func _dissolve() -> void:
	Sound.play(self, &"paper_burst", -2.0)
	var scraps := CPUParticles3D.new()
	scraps.emitting = false
	scraps.one_shot = true
	scraps.explosiveness = 0.15
	scraps.amount = 140
	scraps.lifetime = 3.2
	scraps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	scraps.emission_box_extents = Vector3(0.6, 1.0, 0.3)
	scraps.direction = Vector3(0.0, 1.0, 0.0)
	scraps.spread = 30.0
	scraps.gravity = Vector3(-0.3, 0.8, 0.0)
	scraps.initial_velocity_min = 0.3
	scraps.initial_velocity_max = 1.2
	scraps.angle_max = 360.0
	scraps.angular_velocity_min = -90.0
	scraps.angular_velocity_max = 90.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.15, Color(1, 1, 1, 0.9))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0.0))
	scraps.color_ramp = fade
	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.09, 0.07)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.86, 0.86, 0.9)
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	scrap.material = look
	scraps.mesh = scrap
	village.add_child(scraps)
	scraps.global_position = _her + Vector3(0.0, 1.1, 0.2)
	scraps.emitting = true
	scraps.finished.connect(scraps.queue_free)
	var puppet := boss.puppet
	var sink := create_tween()
	sink.tween_method(func(v: float) -> void:
		puppet.set_fade(v)
		if _wash:
			_wash.set_shader_parameter(&"paper", Color(0.92, 0.91, 0.88, 1.0 - v)), 0.0, 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	sink.tween_callback(func() -> void: puppet.visible = false)


## A courtyard lantern lights again: a flare, then it settles.
func _relight(index: int) -> void:
	if index >= village.arena_lanterns.size():
		return
	var lantern: Dictionary = village.arena_lanterns[index]
	var light: OmniLight3D = lantern["light"]
	var fire: StandardMaterial3D = lantern["fire"]
	fire.albedo_color = Color.WHITE
	Sound.play(self, &"lantern_snuff", -10.0)
	var t := create_tween()
	t.tween_property(light, "light_energy", lantern["energy"] * 1.7, 0.18)
	t.parallel().tween_property(fire, "emission_energy_multiplier", lantern["glow"] * 1.6, 0.18)
	t.tween_property(light, "light_energy", lantern["energy"], 0.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(fire, "emission_energy_multiplier", lantern["glow"], 0.6)
	if lantern["shine"]:
		(lantern["shine"] as GeometryInstance3D).transparency = 0.0


## The Rain eases for a breath, then comes back.
func _ease_rain() -> void:
	var rain := main.get_node("Rain") as Rain
	rain.ease_off(0.25, 1.4)
	Sound.duck_rain(true)
	var back := create_tween()
	back.tween_interval(5.0)
	back.tween_callback(func() -> void:
		rain.ease_off(1.0, 2.0)
		Sound.duck_rain(false))


func _fade(mesh: MeshInstance3D, to: float, time: float) -> void:
	var look := mesh.material_override as StandardMaterial3D
	var t := create_tween()
	t.tween_property(look, "albedo_color:a", to, time).set_trans(Tween.TRANS_SINE)


# --- The overlay -------------------------------------------------------------------

func _build_overlay() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 6
	add_child(overlay)
	for top: bool in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.0, 0.0, 0.0)
		bar.anchor_right = 1.0
		if top:
			bar.anchor_bottom = 0.0
		else:
			bar.anchor_top = 1.0
			bar.anchor_bottom = 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
		_bars.append(bar)
	var skip := SkipPrompt.new()
	skip.hold_time = 0.6
	skip.skipped.connect(func() -> void:
		if _time < LENGTH - 1.0:
			_skip())
	overlay.add_child(skip)


func _set_bars(fraction: float) -> void:
	var height := get_viewport().get_visible_rect().size.y * fraction
	_bars[0].offset_bottom = height
	_bars[1].offset_top = -height


func _bars_in() -> void:
	create_tween().tween_method(_set_bars, 0.0, 0.11, 1.0).set_trans(Tween.TRANS_SINE)


func _bars_out() -> void:
	create_tween().tween_method(_set_bars, 0.11, 0.0, 1.0).set_trans(Tween.TRANS_SINE)


## The camera glides from the shoji back to where the game camera will be.
func _glide_home() -> void:
	(game_camera as FollowCamera).snap_to_target()
	var t := create_tween()
	t.tween_property(_camera, "global_transform", game_camera.global_transform, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Held Space: everything as it will be at the end.
func _skip() -> void:
	village.relight_arena_lanterns()
	village.bamboo.open_gate(true)
	boss.puppet.visible = false
	_crack.visible = false
	(main.get_node("Rain") as Rain).ease_off(1.0, 0.1)
	Sound.duck_rain(false)
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	village.set_arena_sealed(false)
	ronin.set_physics_process(true)
	_hud.visible = true
	game_camera.current = true
	(game_camera as FollowCamera).snap_to_target()
	finished.emit()
	queue_free()
