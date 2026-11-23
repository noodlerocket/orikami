class_name AkaneDuel
extends Node3D
## Akane's clearing at the end of the Bamboo of Folded Wind (the last ground,
## past the Falls), and the meeting there (Akane).
##
## The first time he steps in: play stops, she drops out of the bamboo and
## lands before him, and her warning is brushed along the bottom of the
## screen ("You do not know what you are."). She draws; her name is painted
## (HannyaTitle, with her lettering). A wall of whirling leaves rises behind
## him (the folded wind: it is what keeps him in), and they duel. Hold Space
## (A) to skip to the fight.
## When she yields, she sheathes, her parting line is brushed ("Not yet.
## Learn what you are, little blank one."), and she leaps away into the
## bamboo; the wall of leaves falls. If he dies, she is waiting when he
## comes back (no warning a second time).
## Coordinates are the grove's (this is a child of BambooGrove).

## The clearing (grove x).
const CLEARING := Vector2(399.0, 413.4)
## Where she lands and waits.
const HER_X := 408.0

var grove: BambooGrove
var akane: Akane

var _ronin: Ronin
var _state := &"before"    # before, intro, fight, parting, done
var _time := 0.0
var _wall: StaticBody3D
var _wind: CPUParticles3D
var _wind_petals: CPUParticles3D
var _overlay: Control
var _words: BrushLine
var _title: HannyaTitle
var _bar: BossBar
var _skip: SkipPrompt
var _hud: CanvasItem
var _ground := 2.1
var _parting_said := false
var _warned := false
var _held := false
var _music: AudioStreamPlayer
var _music_fade: Tween

## How loud her duel music plays (dB, before the Music volume setting).
@export var music_volume := -8.0
## How long her music takes to fade away when she yields or he falls.
@export var music_fade_time := 2.5


func _ready() -> void:
	_ground = grove._foot(HER_X)
	akane = Akane.new()
	add_child(akane)
	akane.position = Vector3(HER_X, _ground + 0.05, 0.0)
	akane.facing = -1.0
	akane.bounds = Vector2(BambooGrove.SHIFT + CLEARING.x + 0.6, BambooGrove.SHIFT + CLEARING.y - 0.6)
	akane.yielded.connect(_on_yielded)
	if SaveGame.akane_dueled:
		akane.visible = false
		akane.set_physics_process(false)
		_state = &"done"
	elif not SaveGame.akane_met:
		# Up in the bamboo, out of sight, until he comes.
		akane.visible = false
		akane.set_physics_process(false)
	_build_wind_wall()
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_akane_duel.ogg")
	(_music.stream as AudioStreamOggVorbis).loop = true
	Sound.follow_level(_music, music_volume)
	add_child(_music)


## Her duel music (music_akane_duel.ogg, a seamless loop): starts with the
## fight; fades away when she yields or he falls.
func _play_music(on: bool) -> void:
	if _music_fade:
		_music_fade.kill()
		_music_fade = null
	if on:
		Sound.follow_level(_music, music_volume)
		if not _music.playing:
			_music.play()
	elif _music.playing:
		_music_fade = create_tween()
		_music_fade.tween_property(_music, "volume_db", -60.0, music_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_fade.tween_callback(_music.stop)


## The wall of whirling leaves at the clearing's west edge: down until the
## duel begins, then it rises out of the ground.
func _build_wind_wall() -> void:
	_wind = CPUParticles3D.new()
	_wind.amount = 140
	_wind.lifetime = 1.6
	_wind.emitting = false
	_wind.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wind.emission_box_extents = Vector3(0.35, 0.1, 1.6)
	_wind.direction = Vector3(0.0, 1.0, 0.0)
	_wind.spread = 12.0
	_wind.gravity = Vector3(0.0, 1.0, 0.0)
	_wind.initial_velocity_min = 3.0
	_wind.initial_velocity_max = 6.0
	_wind.orbit_velocity_min = 0.6
	_wind.orbit_velocity_max = 1.2
	_wind.angle_max = 360.0
	_wind.angular_velocity_min = -400.0
	_wind.angular_velocity_max = 400.0
	_wind.tangential_accel_min = 2.0
	_wind.tangential_accel_max = 4.0
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.2, 0.05)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.46, 0.6, 0.26)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.material = look
	_wind.mesh = leaf
	_wind.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wind.position = Vector3(CLEARING.x, _ground, -0.2)
	add_child(_wind)
	_wind_petals = _wind.duplicate() as CPUParticles3D
	_wind_petals.amount = 50
	var petal := QuadMesh.new()
	petal.size = Vector2(0.07, 0.05)
	var pink := look.duplicate() as StandardMaterial3D
	pink.albedo_color = BambooGrove.PETAL
	petal.material = pink
	_wind_petals.mesh = petal
	add_child(_wind_petals)


func _set_wall(up: bool) -> void:
	_wind.emitting = up
	_wind_petals.emitting = up
	if up and _wall == null:
		_wall = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 8.0, 3.0)
		shape.shape = box
		_wall.add_child(shape)
		_wall.position = Vector3(CLEARING.x, _ground + 4.0, 0.0)
		_wall.set_meta(&"no_climb", true)
		add_child(_wall)
		Sound.play(self, &"birds_scatter", -6.0)
	elif not up and _wall:
		_wall.queue_free()
		_wall = null


func _process(delta: float) -> void:
	_time += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
		_ronin.died.connect(_on_ronin_died)
	var x := _ronin.global_position.x - BambooGrove.SHIFT
	match _state:
		&"before":
			if x > CLEARING.x + 1.2 and x < CLEARING.y and _ronin.is_on_floor() and _ronin.is_physics_processing():
				if SaveGame.akane_met:
					_start_fight()
				else:
					_start_intro()
		&"intro":
			_run_intro()
		&"parting":
			_run_parting()


# --- The meeting -------------------------------------------------------------------

func _overlay_node() -> Node:
	var hud := get_tree().get_first_node_in_group(&"hud")
	return hud.get_parent() if hud else null


func _start_intro() -> void:
	_state = &"intro"
	_time = 0.0
	SaveGame.akane_met = true
	_ronin.set_physics_process(false)
	_ronin.velocity = Vector3.ZERO
	var puppet: RoninPuppet = _ronin.get_node("Puppet")
	puppet.state = &"idle"
	puppet.facing = 1.0
	_hud = get_tree().get_first_node_in_group(&"hud") as CanvasItem
	if _hud:
		_hud.visible = false
	Sound.duck_music(true)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var where := _overlay_node()
	if where:
		where.add_child(_overlay)
	_words = BrushLine.new()
	_words.texture = preload("res://textures/akane_warning.png")
	_overlay.add_child(_words)
	_title = HannyaTitle.new()
	_title.KANJI = preload("res://textures/title_akane_kanji.png")
	_title.NAME = preload("res://textures/title_akane_name.png")
	_title.SUBTITLE = preload("res://textures/title_akane_subtitle.png")
	_title.SEAL = preload("res://textures/seal_akane.png")
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_title)
	_skip = SkipPrompt.new()
	_overlay.add_child(_skip)
	_skip.skipped.connect(func() -> void:
		if _state == &"intro":
			_end_intro())
	# She drops out of the bamboo.
	akane.visible = true
	akane.set_physics_process(false)
	akane.facing = -1.0
	akane.global_position = Vector3(BambooGrove.SHIFT + HER_X, _ground + 9.0, 0.0)
	var drop := create_tween()
	drop.tween_property(akane, "global_position:y", _ground + 0.05, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(func() -> void:
		Sound.play(self, &"land", 2.0)
		Confetti.burst(get_parent(), akane.global_position + Vector3(0.0, 0.2, 0.0), 18))
	Sound.play(self, &"fire_whoosh", -6.0)


## The meeting, by the clock: she lands (0.6), the warning is brushed (1.4),
## she draws (5.0), her name is painted (5.6), the fight (8.8).
func _run_intro() -> void:
	if _time > 1.4 and not _warned:
		_warned = true
		_words.show_line(3.2)
	if _time > 5.0 and akane.mode() == &"wait":
		akane.set(&"_mode", &"guard")
		Sound.play(self, &"draw_gleam", -4.0)
	if _time > 5.6 and _title.get(&"_stroke") == 0.0:
		_title.paint()
	if _time > 8.8:
		_end_intro()


func _end_intro() -> void:
	if _overlay:
		var fade := create_tween()
		fade.tween_property(_overlay, "modulate:a", 0.0, 0.5)
		fade.tween_callback(_overlay.queue_free)
		_overlay = null
	akane.global_position.y = _ground + 0.05
	if _hud:
		_hud.visible = true
	_ronin.set_physics_process(true)
	_start_fight()


func _start_fight() -> void:
	_state = &"fight"
	akane.visible = true
	akane.set_physics_process(true)
	akane.begin()
	_set_wall(true)
	Sound.duck_music(true)
	_play_music(true)
	if _bar == null:
		_bar = BossBar.new()
		_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		var where := _overlay_node()
		if where:
			where.add_child(_bar)
		_bar.watch(akane, preload("res://textures/title_akane_kanji.png"), preload("res://textures/title_akane_name.png"))
	akane.health_changed.emit(akane.health, akane.max_health)


# --- The end -------------------------------------------------------------------

func _on_yielded() -> void:
	_state = &"parting"
	_time = 0.0
	SaveGame.akane_dueled = true
	_play_music(false)
	if _bar:
		_bar.hide_bar()


## She lands, sheathes and speaks; then she is gone into the bamboo. While
## she speaks he stands still, facing her (Julian): held once his feet are
## on the ground, let go once she has gone.
func _run_parting() -> void:
	if not _held and _ronin.is_on_floor():
		_held = true
		_ronin.set_physics_process(false)
		_ronin.velocity = Vector3.ZERO
	if _held:
		var puppet: RoninPuppet = _ronin.get_node("Puppet")
		puppet.state = &"idle"
		puppet.facing = signf(akane.global_position.x - _ronin.global_position.x)
		_ronin.facing = puppet.facing
	if _time > 1.0 and not _parting_said:
		_parting_said = true
		var where := _overlay_node()
		if where:
			_words = BrushLine.new()
			_words.texture = preload("res://textures/akane_parting.png")
			where.add_child(_words)
			_words.show_line(3.0)
	if _time > 4.6 and akane.mode() == &"yield":
		akane.leave()
		_set_wall(false)
		Sound.duck_music(false)
	if _time > 6.0:
		_state = &"done"
		if _held:
			_held = false
			_ronin.set_physics_process(true)
		SaveGame.write()


func _on_ronin_died() -> void:
	if _state != &"fight":
		return
	# She waits for him to come back; the wall falls.
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func() -> void:
		_state = &"before"
		_set_wall(false)
		if _bar:
			_bar.hide_bar()
		_play_music(false)
		Sound.duck_music(false)
		akane.reset(Vector3(BambooGrove.SHIFT + HER_X, _ground + 0.05, 0.0)))
