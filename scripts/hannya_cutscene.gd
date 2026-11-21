class_name HannyaCutscene
extends Node
## The cutscene before the Weeping Hannya fight. 40 seconds, in the game's
## own world (2.5D: the camera stays in front of the diorama and moves by
## pushing in, craning, panning and drifting, never round behind things).
## It is scored to music_hannya_intro.mp3; the times below are matched to it
## (the paper rips on the music's eruption at 28 s).
##
## The shots (seconds):
##   0    He walks through the torii; the camera low on the wet stones, craning up
##   5    The courtyard, wide; the stone lanterns gutter out one by one
##   10   Slow push in on her shadow on the screen, weeping
##   17   Close on his sword hand: an inch of blade
##   19.5 The weeping stops; her shadow turns to face us, horns rising
##   24   Ink bleeds out of her shadow through the paper
##   28   The paper is slashed open, twice, and torn
##   30   Her mask pushes through the hole: extreme close-up
##   34.5 She towers in front of the torn screen; the title is painted on
##   40   Back to the game
##
## Holding jump for a moment skips it.

signal finished

const LENGTH := 40.0
## Where the Ronin starts creeping in, and where he stops, facing the shrine.
const SNEAK_FROM := 45.0
const RONIN_STOP := 48.6
## His creeping pace: strides (two short steps) a second. Each step is about
## a third of a metre.
const SNEAK_STRIDES := 1.15

var main: Node
var ronin: Ronin
var village: Node
var stage: HannyaStage
var game_camera: Camera3D

var _time := -0.01
var _camera: Camera3D
var _shots: Array[Dictionary] = []
var _events: Array = []          # [time, callable], fired in order
var _next_event := 0
var _shake := 0.0
var _bars: Array[ColorRect] = []
var _overlay: CanvasLayer
var _title: Control
var _music: AudioStreamPlayer
var _sob: AudioStreamPlayer
var _mask: Node3D
var _skip_held := 0.0
var _hud: CanvasItem
var _origin: Vector3             # the middle of the screen's foot, in the world
var _scraps: CPUParticles3D


func _ready() -> void:
	_origin = stage.global_position
	_camera = Camera3D.new()
	_camera.cull_mask &= ~Hannya.SHADOW_LAYER
	_camera.near = 0.03
	add_child(_camera)
	_camera.current = true
	ronin.set_physics_process(false)
	ronin.velocity = Vector3.ZERO
	ronin.global_position = Vector3(SNEAK_FROM, 1.5, 0.0)
	ronin.facing = 1.0
	_hud = main.get_node("Overlay/HUD")
	_hud.visible = false
	_build_overlay()
	_build_mask()
	_build_scraps()
	_plan_shots()
	_plan_events()
	stage.hannya.rotation.y = PI * 0.5
	stage.hannya.show_body(false)
	stage.set_light(1.0)
	stage.set_ink(0.0)
	stage.set_tear(0.0)
	stage.open_slash(0, 0.0)
	stage.open_slash(1, 0.0)
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_hannya_intro.mp3")
	_music.volume_db = -3.0
	add_child(_music)
	_music.play()
	Sound.duck_music(true)


func _process(delta: float) -> void:
	_time += delta
	# Hold jump to skip.
	_skip_held = _skip_held + delta if Input.is_action_pressed("jump") else 0.0
	if _skip_held > 0.6 and _time < LENGTH - 1.0:
		_skip()
		return
	while _next_event < _events.size() and _time >= _events[_next_event][0]:
		(_events[_next_event][1] as Callable).call()
		_next_event += 1
	_animate_actors(delta)
	_animate_camera(delta)
	if _time >= LENGTH:
		_finish()


# --- The camera --------------------------------------------------------------

## A shot: the camera moves from one place to another, looking from one point
## to another, over its time; `fov` and `roll` change too. `hand` is a little
## handheld drift. Times are seconds from the start.
func _shot(start: float, end: float, from: Vector3, to: Vector3, look_from: Vector3, look_to: Vector3,
		fov := Vector2(42.0, 42.0), roll := Vector2.ZERO, hand := 0.02, ease := 1.0) -> void:
	_shots.append({"start": start, "end": end, "from": from, "to": to, "look_from": look_from,
			"look_to": look_to, "fov": fov, "roll": roll, "hand": hand, "ease": ease})


## Positions relative to the shrine: x across, y up from the courtyard, z
## toward the camera from the screen.
func _at(x: float, y: float, z: float) -> Vector3:
	return _origin + Vector3(x, y, z)


func _plan_shots() -> void:
	var g := _origin.y
	# 1. Low on the wet stones by the torii as his sandals pass, craning up and
	#    back to show the courtyard ahead.
	_shot(0.0, 5.0, Vector3(45.0, g + 0.35, 2.2), Vector3(47.2, g + 2.4, 7.5),
			Vector3(46.2, g + 0.45, 0.0), Vector3(51.0, g + 1.6, -1.0), Vector2(38, 46), Vector2(2, 0), 0.015, 0.8)
	# 2. Wide on the courtyard, pushing gently in as the lanterns go out.
	_shot(5.0, 10.0, _at(-1.6, 2.6, 13.5), _at(-0.8, 2.5, 11.5), _at(-0.5, 2.0, -0.5), _at(0.0, 2.1, -0.5),
			Vector2(46, 44), Vector2.ZERO, 0.01)
	# 3. A long slow push in on her weeping shadow.
	_shot(10.0, 17.0, _at(0.2, 2.3, 7.2), _at(0.7, 2.45, 3.4), _at(0.5, 2.1, 0.0), _at(0.9, 2.35, 0.0),
			Vector2(40, 36), Vector2(0, -1.5), 0.012, 1.0)
	# 4. Close on him from in front, low: the hat hiding his eyes, his hand on
	#    the hilt as his thumb pushes the guard. (His sword is on his far side
	#    from the usual camera, so this shot looks back at him from ahead.)
	var hip := Vector3(RONIN_STOP + 0.1, g + 0.95, 0.0)
	_shot(17.0, 19.5, hip + Vector3(2.1, 0.15, 1.35), hip + Vector3(1.75, 0.15, 1.15),
			hip + Vector3(0.0, 0.12, 0.0), hip + Vector3(0.0, 0.2, 0.0), Vector2(34, 30), Vector2(-2, -3), 0.006)
	# 5. Still, on the screen: the weeping stops; she turns to face us.
	_shot(19.5, 24.0, _at(0.0, 2.2, 6.0), _at(0.0, 2.25, 5.4), _at(0.0, 2.2, 0.0), _at(0.0, 2.3, 0.0),
			Vector2(40, 38), Vector2.ZERO, 0.004)
	# 6. Ink bleeding through: pushing in, the camera tilting slowly off level.
	_shot(24.0, 28.0, _at(0.0, 2.3, 5.4), _at(0.0, 2.5, 3.9), _at(0.0, 2.3, 0.0), _at(0.0, 2.6, 0.0),
			Vector2(38, 40), Vector2(0, 4), 0.008, 1.2)
	# 7a. The first slash: square on.
	_shot(28.0, 28.7, _at(0.0, 2.3, 5.6), _at(0.0, 2.3, 5.9), _at(0.0, 2.4, 0.0), _at(0.0, 2.4, 0.0),
			Vector2(42, 44), Vector2(4, -2), 0.0)
	# 7b. The second, and the tear: low, off to one side, looking up.
	_shot(28.7, 30.0, _at(-2.4, 0.6, 4.6), _at(-2.0, 0.5, 4.2), _at(0.2, 2.6, 0.0), _at(0.3, 2.9, 0.0),
			Vector2(46, 44), Vector2(-6, -5), 0.0)
	# 8. Extreme close-up: the mask pushing through the hole.
	_shot(30.0, 34.5, _mask_front() + Vector3(0.12, 0.1, 1.9), _mask_front() + Vector3(0.0, 0.08, 1.4),
			_mask_front() + Vector3(0.0, 0.06, 0.0), _mask_front() + Vector3(0.0, 0.04, 0.0), Vector2(28, 24), Vector2(2, -1), 0.004, 1.3)
	# 9. Low, looking up: she towers in front of the torn screen; the camera
	#    eases back as the title is painted.
	_shot(34.5, 40.0, _at(-0.25, 0.4, 3.6), _at(0.0, 0.6, 5.0), _at(0.0, 2.5, 0.6), _at(0.0, 2.2, 0.6),
			Vector2(52, 50), Vector2(-3, 0), 0.01, 0.9)


## Where the mask comes through: the middle of the tear, just in front of
## the paper.
func _mask_front() -> Vector3:
	return _at(0.35, 2.75, 0.15)


func _animate_camera(delta: float) -> void:
	var shot: Dictionary = _shots[_shots.size() - 1]
	for s: Dictionary in _shots:
		if _time < s["end"]:
			shot = s
			break
	var u := clampf((_time - shot["start"]) / (shot["end"] - shot["start"]), 0.0, 1.0)
	# Ease in and out; `ease` above 1 lingers at the start, below 1 at the end.
	var e := pow(u, shot["ease"])
	e = e * e * (3.0 - 2.0 * e)
	var at: Vector3 = (shot["from"] as Vector3).lerp(shot["to"], e)
	var look: Vector3 = (shot["look_from"] as Vector3).lerp(shot["look_to"], e)
	var hand: float = shot["hand"]
	var drift := Vector3(sin(_time * 0.9) + 0.5 * sin(_time * 2.3), cos(_time * 0.7) + 0.4 * sin(_time * 1.9), 0.0) * hand
	_shake = maxf(_shake - delta * 2.5, 0.0)
	var jolt := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * 0.12
	_camera.look_at_from_position(at + drift + jolt, look + drift * 0.5)
	var fov: Vector2 = shot["fov"]
	var roll: Vector2 = shot["roll"]
	_camera.fov = lerpf(fov.x, fov.y, e)
	_camera.rotate_object_local(Vector3.BACK, deg_to_rad(lerpf(roll.x, roll.y, e) + _shake * randf_range(-2.0, 2.0)))


# --- What happens when ----------------------------------------------------------

func _plan_events() -> void:
	_events = [
		[0.0, func() -> void: _bars_in()],
		[5.9, func() -> void:
			village.snuff_arena_lantern(0, 0.9)
			Sound.play(self, &"lantern_snuff")],
		[7.4, func() -> void:
			village.snuff_arena_lantern(1, 0.9)
			Sound.play(self, &"lantern_snuff")],
		[8.2, func() -> void: _start_sob()],
		[19.5, func() -> void:
			_sob.stop()
			Sound.duck_rain(true)],
		[20.6, func() -> void: Sound.play(self, &"mask_creak")],
		[24.2, func() -> void: Sound.play(self, &"ink_bleed")],
		[28.0, func() -> void: _rip(0)],
		[28.7, func() -> void: _rip(1)],
		[29.2, func() -> void: _tear()],
		[30.0, func() -> void:
			stage.hannya.show_body(false)
			_mask.visible = true
			Sound.play(self, &"mask_creak", 3.0)],
		[34.5, func() -> void:
			_mask.visible = false
			_step_out()],
		[35.8, func() -> void:
			Sound.play(self, &"taiko_hit")
			_shake = 0.8],
		[36.0, func() -> void: _paint_title()],
		[38.8, func() -> void: Sound.duck_rain(false)],
		[39.0, func() -> void: _bars_out()],
	]


func _animate_actors(_delta: float) -> void:
	var h := stage.hannya
	# The Ronin: walks in, stops, crouches into the iai stance and holds it.
	var puppet: RoninPuppet = ronin.get_node("Puppet")
	puppet.facing = 1.0
	if _time < 4.4:
		# Creeping in: the distance matches the steps (about 0.34 m each).
		var walk := smoothstep(0.0, 1.0, _time / 4.4) * 0.15 + (_time / 4.4) * 0.85
		ronin.global_position.x = lerpf(SNEAK_FROM, RONIN_STOP, walk)
		puppet.strides_per_second = SNEAK_STRIDES
		puppet.state = &"sneak"
	elif _time < 17.0:
		puppet.strides_per_second = 2.0
		puppet.state = &"idle"
	else:
		puppet.state = &"iai"
		puppet.iai_charge = clampf((_time - 17.2) / 1.6, 0.0, 1.0)
	puppet.horizontal_speed = 0.0
	puppet.vertical_speed = 0.0
	# The Hannya.
	if _time < 19.5:
		h.pose = HannyaPoses.weep(_time)
	elif _time < 24.0:
		var u := clampf((_time - 20.4) / 3.2, 0.0, 1.0)
		h.pose = HannyaPoses.turn(u)
		# Her whole body swings round from side-on to facing the paper.
		h.rotation.y = lerpf(PI * 0.5, 0.0, smoothstep(0.2, 1.0, u))
	elif _time < 28.0:
		h.pose = HannyaPoses.rise(clampf((_time - 24.5) / 3.3, 0.0, 1.0) * 0.55)
	elif _time < 30.0:
		h.pose = HannyaPoses.slash(fmod(_time - 28.0, 0.7) / 0.7)
	elif _time < 34.5:
		# The close-up: the mask slides out through the hole and tilts.
		var push := smoothstep(0.0, 1.0, (_time - 30.0) / 3.8)
		_mask.global_position = _mask_front() + Vector3(0.0, 0.0, lerpf(-0.75, 0.0, push))
		_mask.rotation = Vector3(deg_to_rad(lerpf(8.0, -4.0, push)), deg_to_rad(lerpf(-12.0, 4.0, push)),
				deg_to_rad(lerpf(-4.0, 14.0, smoothstep(0.5, 1.0, push))))
	else:
		h.pose = HannyaPoses.rise(1.0) if _time < 36.0 else HannyaPoses.menace(_time)
	stage.set_ink(clampf((_time - 24.2) / 3.6, 0.0, 1.0) * 0.85 if _time < 34.5 else 0.85)


func _start_sob() -> void:
	_sob = AudioStreamPlayer.new()
	var stream: AudioStreamMP3 = load("res://audio/hannya_sob.mp3")
	stream.loop = true
	_sob.stream = stream
	_sob.volume_db = -4.0
	add_child(_sob)
	_sob.play()


## A sleeve slash tears through the paper.
func _rip(which: int) -> void:
	Sound.play(self, &"paper_rip", 2.0)
	_shake = 1.0
	stage.hannya.show_body(true)
	var open := create_tween()
	open.tween_method(func(v: float) -> void: stage.open_slash(which, v), 0.0, 1.0, 0.12)
	_scraps.global_position = _at(0.0 if which == 0 else 0.4, 2.6, 0.1)
	_scraps.restart()


func _tear() -> void:
	Sound.play(self, &"paper_rip", 4.0)
	_shake = 0.7
	var uv := stage.screen_uv(_mask_front())
	stage.screen_material.set_shader_parameter(&"tear_center", uv)
	var open := create_tween()
	open.tween_method(func(v: float) -> void: stage.set_tear(v), 0.0, 0.62, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_scraps.global_position = _mask_front()
	_scraps.restart()


## For the last shot she stands in front of the torn screen, on its step.
func _step_out() -> void:
	var h := stage.hannya
	h.show_body(true)
	h.rotation.y = 0.0
	h.global_position = _at(0.0, 0.2, 0.55)
	h.snap(HannyaPoses.rise(1.0))
	stage.set_tear(0.95)
	stage.stop_shadow()


# --- The overlay: letterbox bars and the title --------------------------------

func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 6
	add_child(_overlay)
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
		_overlay.add_child(bar)
		_bars.append(bar)
	_title = HannyaTitle.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_title)


func _set_bars(fraction: float) -> void:
	var height := get_viewport().get_visible_rect().size.y * fraction
	_bars[0].offset_bottom = height
	_bars[1].offset_top = -height


func _bars_in() -> void:
	var t := create_tween()
	t.tween_method(_set_bars, 0.0, 0.11, 1.2).set_trans(Tween.TRANS_SINE)


func _bars_out() -> void:
	var t := create_tween()
	t.tween_method(_set_bars, 0.11, 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	var fade := create_tween()
	fade.tween_property(_title, "modulate:a", 0.0, 0.8)


func _paint_title() -> void:
	(_title as HannyaTitle).paint()


# --- Props -----------------------------------------------------------------------

## The detailed mask, for the extreme close-up only.
func _build_mask() -> void:
	_mask = Node3D.new()
	add_child(_mask)
	var model: Node3D = load("res://models/hannya_mask.glb").instantiate()
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var low := Vector3.INF
	var high := -Vector3.INF
	for m: MeshInstance3D in meshes:
		low = low.min(m.get_aabb().position)
		high = high.max(m.get_aabb().end)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var grow := 0.62 / maxf(high.y - low.y, 0.001)
	model.scale = Vector3.ONE * grow
	model.position = -(low + high) * 0.5 * grow
	_mask.add_child(model)
	# A cold light from the front-left (the moon through the rain) and the
	# warm lamp glow from behind, so the mask is carved out of the dark.
	# Lit from the side and below, never flat from the front: the cold moon
	# grazing one cheek, the warm lamp from below and behind, so the brow
	# throws the eyes into shadow.
	for m: MeshInstance3D in meshes:
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i) as BaseMaterial3D
			if mat:
				var dim := mat.duplicate() as BaseMaterial3D
				dim.albedo_color = Color(0.78, 0.76, 0.74)
				dim.roughness = 0.85
				m.set_surface_override_material(i, dim)
	var cold := OmniLight3D.new()
	cold.light_color = Color(0.55, 0.62, 0.95)
	cold.light_energy = 0.9
	cold.omni_range = 2.0
	cold.position = Vector3(-0.85, 0.15, 0.35)
	_mask.add_child(cold)
	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.55, 0.25)
	warm.light_energy = 1.5
	warm.omni_range = 1.6
	warm.position = Vector3(0.35, -0.55, 0.25)
	_mask.add_child(warm)
	_mask.visible = false


## Scraps of shoji paper that burst from each rip.
func _build_scraps() -> void:
	_scraps = CPUParticles3D.new()
	_scraps.emitting = false
	_scraps.one_shot = true
	_scraps.explosiveness = 0.9
	_scraps.amount = 40
	_scraps.lifetime = 2.2
	_scraps.direction = Vector3(0.0, 0.3, 1.0)
	_scraps.spread = 55.0
	_scraps.initial_velocity_min = 2.0
	_scraps.initial_velocity_max = 6.5
	_scraps.gravity = Vector3(-0.6, -5.0, 0.0)
	_scraps.damping_min = 1.5
	_scraps.damping_max = 3.0
	_scraps.angle_max = 360.0
	_scraps.angular_velocity_min = -400.0
	_scraps.angular_velocity_max = 400.0
	_scraps.scale_amount_min = 0.5
	_scraps.scale_amount_max = 1.6
	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.14, 0.1)
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.95, 0.82, 0.6)
	paper.emission_enabled = true
	paper.emission = Color(1.0, 0.7, 0.4)
	paper.emission_energy_multiplier = 0.5
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	scrap.material = paper
	_scraps.mesh = scrap
	add_child(_scraps)


# --- Ending ------------------------------------------------------------------------

func _skip() -> void:
	_time = LENGTH
	for e in range(_next_event, _events.size()):
		pass
	village.snuff_arena_lantern(0, 0.01)
	village.snuff_arena_lantern(1, 0.01)
	if _sob:
		_sob.stop()
	_music.stop()
	stage.open_slash(0, 1.0)
	stage.open_slash(1, 1.0)
	_step_out()
	stage.hannya.snap(HannyaPoses.menace(0.0))
	_finish()


func _finish() -> void:
	set_process(false)
	Sound.duck_rain(false)
	Sound.duck_music(false)
	ronin.global_position.x = RONIN_STOP
	ronin.set_physics_process(true)
	(ronin.get_node("Puppet") as RoninPuppet).strides_per_second = 2.0
	_hud.visible = true
	game_camera.current = true
	if game_camera.has_method("snap_to_target"):
		game_camera.snap_to_target()
	finished.emit()
	queue_free()
