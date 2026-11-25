class_name AkaneSkies
extends Node3D
## Akane's second duel, at the far end of Koinobori Skies: the Kite-Fighters'
## Ring, a cliff top high in the wind (docs/koinobori_skies_plan.md; lore:
## "Akane duels him again, harder each time"). Built like her first duel
## (AkaneDuel) but harder: more health, quicker wind-ups, she turns more of
## his cuts aside, more fox-fires. She is waiting, standing on a kite-
## fighter's post; she drops before him, says "Still you do not know what
## you are.", and a wall of whirling paper scraps closes the ring. When she
## yields: "Higher, then. The Gates will show you." and she leaps off the
## cliff onto a passing carp and is gone. Dying resets her.
## SaveGame.akane_skies_met / akane_skies_dueled. Coordinates are the
## Skies' (a child of KoinoboriSkies).

const RING := Vector2(342.0, 378.0)
const HER_X := 358.0
const GROUND := 2.4

@export var music_volume := -8.0
@export var music_fade_time := 2.5

var skies: KoinoboriSkies
var akane: Akane
var _ronin: Ronin
var _state := &"before"
var _time := 0.0
var _wall: StaticBody3D
var _wind: CPUParticles3D
var _overlay: Control
var _words: BrushLine
var _title: HannyaTitle
var _bar: BossBar
var _skip: SkipPrompt
var _hud: CanvasItem
var _warned := false
var _parting_said := false
var _held := false
var _music: AudioStreamPlayer
var _music_fade: Tween


func _ready() -> void:
	akane = Akane.new()
	# Harder than in the bamboo.
	akane.max_health = 32
	akane.yield_at = 14
	akane.cut_windup = 0.42
	akane.cut_gap = 0.24
	akane.deflect_chance = 0.45
	akane.draw_tell = 0.55
	akane.fire_count = 4
	akane.walk_speed = 2.8
	akane.guard_time = Vector2(0.35, 0.9)
	akane.gale = true   # (her new move here: the gale dive)
	add_child(akane)
	akane.position = Vector3(HER_X, GROUND + 0.05, 0.0)
	akane.facing = -1.0
	akane.bounds = Vector2(KoinoboriSkies.SHIFT + RING.x + 0.6, KoinoboriSkies.SHIFT + RING.y - 0.6)
	akane.yielded.connect(_on_yielded)
	if SaveGame.akane_skies_dueled or not SaveGame.akane_skies_met:
		akane.visible = false
		akane.set_physics_process(false)
		if SaveGame.akane_skies_dueled:
			_state = &"done"
	_build_ring()
	_build_wind_wall()
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_akane_duel.ogg")
	(_music.stream as AudioStreamOggVorbis).loop = true
	add_child(_music)


## The Kite-Fighters' Ring: a ring of stakes and rope round the cliff top,
## fighting kites tethered and tugging at their lines, her post.
func _build_ring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3434
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.1
	var x := RING.x
	while x <= RING.y:
		b.color = Color(0.4, 0.32, 0.24)
		b.box(Vector3(x, GROUND + 0.45, -2.6), Vector3(0.12, 0.9, 0.12))
		x += 3.0
	b.color = Color(0.7, 0.64, 0.5)
	b.box(Vector3((RING.x + RING.y) * 0.5, GROUND + 0.8, -2.6), Vector3(RING.y - RING.x, 0.03, 0.03))
	# Her post: a tall stake with a kite-fighter's reel on it.
	b.color = Color(0.36, 0.28, 0.22)
	b.box(Vector3(HER_X + 3.0, GROUND + 2.0, -1.8), Vector3(0.2, 4.0, 0.2))
	b.frustum(10, Vector2(0.3, 0.3), Vector2(0.3, 0.3), 0.3, Vector3(HER_X + 3.0, GROUND + 1.6, -1.6))
	add_child(b.build())
	# Fighting kites tugging at their lines (small square kites, high).
	for k in 4:
		var kite := Node3D.new()
		var kx := RING.x + 4.0 + k * 8.0
		kite.position = Vector3(kx - 2.0, GROUND + 9.0 + rng.randf_range(-1.0, 1.5), -6.0)
		add_child(kite)
		var p := PaperMesh.new(rng.randi())
		p.texture_world = false
		p.color = [Color(0.66, 0.26, 0.2), Color(0.86, 0.82, 0.72), Color(0.3, 0.36, 0.5), Color(0.2, 0.2, 0.22)][k]
		p.polygon(PackedVector2Array([Vector2(0.0, 0.7), Vector2(0.55, 0.0), Vector2(0.0, -0.7), Vector2(-0.55, 0.0)]), 0.0)
		p.color = Color(0.6, 0.56, 0.46)
		p.stroke(Vector2.ZERO, Vector2(2.0, -(kite.position.y - GROUND - 0.9)), 0.012, 0.012, 0.0)
		kite.add_child(p.build())
		Scenery.windswept(kite, 0.05, rng)


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
	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.14, 0.08)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.92, 0.9, 0.84)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	scrap.material = look
	_wind.mesh = scrap
	_wind.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wind.position = Vector3(RING.x, GROUND, -0.2)
	add_child(_wind)


func _set_wall(up: bool) -> void:
	_wind.emitting = up
	if up and _wall == null:
		_wall = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 10.0, 3.0)
		shape.shape = box
		_wall.add_child(shape)
		_wall.position = Vector3(RING.x, GROUND + 5.0, 0.0)
		_wall.set_meta(&"no_climb", true)
		add_child(_wall)
		Sound.play(self, &"fan_gust", -4.0)
	elif not up and _wall:
		_wall.queue_free()
		_wall = null


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


func _process(delta: float) -> void:
	_time += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
		_ronin.died.connect(_on_ronin_died)
	var x := _ronin.global_position.x - KoinoboriSkies.SHIFT
	match _state:
		&"before":
			if x > RING.x + 1.2 and x < RING.y and _ronin.is_on_floor() and _ronin.is_physics_processing():
				if SaveGame.akane_skies_met:
					_start_fight()
				else:
					_start_intro()
		&"intro":
			_run_intro()
		&"parting":
			_run_parting()


func _overlay_node() -> Node:
	var hud := get_tree().get_first_node_in_group(&"hud")
	return hud.get_parent() if hud else null


func _start_intro() -> void:
	_state = &"intro"
	_time = 0.0
	SaveGame.akane_skies_met = true
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
	_words.texture = preload("res://textures/akane_warning_2.png")
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
	# She drops from the top of her post.
	akane.visible = true
	akane.set_physics_process(false)
	akane.facing = -1.0
	akane.global_position = Vector3(KoinoboriSkies.SHIFT + HER_X, GROUND + 4.2, 0.0)
	var drop := create_tween()
	drop.tween_interval(0.3)
	drop.tween_property(akane, "global_position:y", GROUND + 0.05, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(func() -> void:
		Sound.play(self, &"land", 2.0)
		Confetti.burst(get_parent(), akane.global_position + Vector3(0.0, 0.2, 0.0), 18))


## She lands (0.8), her words (1.4), she draws (4.6), her name (5.2), the
## fight (8.0).
func _run_intro() -> void:
	if _time > 1.4 and not _warned:
		_warned = true
		_words.show_line(2.8)
	if _time > 4.6 and akane.mode() == &"wait":
		akane.set(&"_mode", &"guard")
		Sound.play(self, &"draw_gleam", -4.0)
	if _time > 5.2 and _title.get(&"_stroke") == 0.0:
		_title.paint()
	if _time > 8.0:
		_end_intro()


func _end_intro() -> void:
	if _overlay:
		var fade := create_tween()
		fade.tween_property(_overlay, "modulate:a", 0.0, 0.5)
		fade.tween_callback(_overlay.queue_free)
		_overlay = null
	akane.global_position.y = GROUND + 0.05
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


func _on_yielded() -> void:
	_state = &"parting"
	_time = 0.0
	SaveGame.akane_skies_dueled = true
	_play_music(false)
	if _bar:
		_bar.hide_bar()


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
			_words.texture = preload("res://textures/akane_parting_2.png")
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
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func() -> void:
		_state = &"before"
		_set_wall(false)
		if _bar:
			_bar.hide_bar()
		_play_music(false)
		Sound.duck_music(false)
		akane.reset(Vector3(KoinoboriSkies.SHIFT + HER_X, GROUND + 0.05, 0.0)))
