class_name ShimeriPost
extends Node3D
## Shimeri's Post, the end of Sumi Marsh (docs/sumi_marsh_plan.md, area 7):
## a flooded gate fort, knee-deep in ink, its great gate shut at the east
## end (the way on, to the next region: not built). Shimeri stands guard
## there, slumped under the Rain (Shimeri). Built in the marsh's coordinates.
##
## The first time he walks in (directed, CineCamera, 12 s): along the flooded
## court; Shimeri, slumped, ink pouring off his helmet; his head lifts; his
## words are brushed ("Who goes. ... This gate is kept."); he raises the
## nodachi and brings it down into the ink, and his name is painted (湿将);
## a curtain of ink pours down across the way back.
## After (directed, 14 s): slowed on the last cut; he sinks to one knee; the
## ink drains from him (shaders/wash_white.gdshader: pale paper underneath)
## and his creases come back; he lifts his head ("Shimeri. That was my
## name."); he holds out his seal (湿将) and it flies to the Ronin's hand
## (SaveGame seal "shimeri"). The curtain of ink stops.

const ARENA := Vector2(356.0, 400.0)
const HIS_X := 392.0
const GATE_X := 401.5

@export var music_volume := -6.0
@export var fight_camera_distance := 17.0

var marsh: SumiMarsh
var shimeri: Shimeri
var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _state := &"before"
var _cine: CineCamera
var _overlay: Control
var _title: HannyaTitle
var _bar: BossBar
var _skip: SkipPrompt
var _hud: CanvasItem
var _music: AudioStreamPlayer
var _music_fade: Tween
var _camera_tween: Tween
var _curtain: InkCurtain
var _wall: StaticBody3D
var _wash: ShaderMaterial
var _held := false
var _focused := false
var _soldiers: Array[Node] = []
var _doors: Array[Node3D] = []
var _gate_wall: StaticBody3D


func _ready() -> void:
	_rng.seed = 8282
	add_to_group(&"shimeri_post")
	_build_fort()
	shimeri = Shimeri.new()
	add_child(shimeri)
	var floor_y := SumiMarsh.SHALLOW_BED
	shimeri.position = Vector3(HIS_X, floor_y + 0.05, 0.0)
	shimeri.facing = -1.0
	shimeri.bounds = Vector2(marsh.global_position.x + ARENA.x + 1.5, marsh.global_position.x + ARENA.y - 2.0)
	shimeri.floor_y = marsh.global_position.y + floor_y
	shimeri.defeated.connect(_on_defeated)
	shimeri.muster.connect(_muster)
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_shimeri_fight.ogg") if ResourceLoader.exists("res://audio/music_shimeri_fight.ogg") else load("res://audio/music_hosho_fight.ogg")
	if _music.stream is AudioStreamOggVorbis:
		(_music.stream as AudioStreamOggVorbis).loop = true
	add_child(_music)
	if SaveGame.shimeri_beaten:
		_state = &"done"
		shimeri.active = false
		shimeri.set(&"_mode", &"defeated")
		shimeri.set_kneel(0.0)
		shimeri.set_fallen(1.0)
		shimeri.collision_layer = 0
		_wash_ink(false)
		open_gate.call_deferred(false)


# --- Building it ----------------------------------------------------------------------

## The fort: a long wall of stained plaster on a stone base behind the flooded
## court, a gate tower (yagura) over the great gate at the east end, its
## doors shut, walls running back and forward from it; banners hanging limp;
## two old lanterns on the gate, dimly lit; half-sunk stone lanterns.
func _build_fort() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	# The back wall of the court.
	var x := ARENA.x - 2.0
	while x < GATE_X - 0.5:
		var x1 := minf(x + 6.0, GATE_X - 0.5)
		b.color = MarshKit.STONE.darkened(_rng.randf_range(0.15, 0.3))
		b.box(Vector3((x + x1) * 0.5, 0.3, -6.0), Vector3(x1 - x, 2.4, 1.2))
		b.color = Color(0.52, 0.5, 0.46).darkened(_rng.randf_range(0.05, 0.2))
		b.box(Vector3((x + x1) * 0.5, 3.2, -6.2), Vector3(x1 - x, 3.4, 0.6))
		b.color = Color(0.12, 0.12, 0.14)
		b.box(Vector3((x + x1) * 0.5, 1.9, -5.88), Vector3(x1 - x, 0.9, 0.05))  # ink soaked up the plaster
		for k in 3:
			b.box(Vector3(_rng.randf_range(x, x1), _rng.randf_range(2.6, 4.2), -5.88), Vector3(0.05, _rng.randf_range(0.6, 1.8), 0.04))
		x = x1
	_mesh(b)
	add_child(Scenery.tiled_roof(_rng, ARENA.x - 2.3, GATE_X - 0.3, Vector2(5.0, -5.2), Vector2(5.7, -6.8), 4))
	# The gate tower and the great gate, shut.
	var g := PaperMesh.new(_rng.randi())
	g.shade_jitter = 0.12
	var top := 6.4
	for z: float in [-2.8, 2.8]:
		g.color = Color(0.18, 0.15, 0.14)
		g.frustum(8, Vector2(0.32, 0.32), Vector2(0.3, 0.3), top + 1.0, Vector3(GATE_X, -1.0, z))
	g.color = Color(0.16, 0.13, 0.12)
	g.box(Vector3(GATE_X, top, 0.0), Vector3(0.7, 0.6, 6.6))
	# The doors: two heavy leaves of planks with iron bands, shut across the
	# way, hung on the posts (they swing open east once he is beaten).
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(GATE_X, 0.0, side * 2.7)
		add_child(hinge)
		var d := PaperMesh.new(_rng.randi())
		d.shade_jitter = 0.1
		d.color = Color(0.2, 0.17, 0.15)
		d.box(Vector3(0.0, top * 0.5 - 0.6, -side * 1.35), Vector3(0.3, top - 0.8, 2.68))
		d.color = Color(0.1, 0.1, 0.11)
		for y: float in [0.6, 2.4, 4.2]:
			d.box(Vector3(-0.17, y, -side * 1.35), Vector3(0.04, 0.16, 2.68))
		hinge.add_child(d.build())
		_doors.append(hinge)
	# The tower over it: a plastered room with a lattice window, its roof.
	g.color = Color(0.5, 0.48, 0.44)
	g.box(Vector3(GATE_X, top + 1.6, 0.0), Vector3(3.6, 2.6, 6.2))
	g.color = Color(0.1, 0.1, 0.12)
	g.box(Vector3(GATE_X - 1.82, top + 1.7, 0.0), Vector3(0.04, 0.9, 2.2))
	# Walls running back and forward from the gate.
	g.color = Color(0.5, 0.48, 0.44).darkened(0.1)
	g.box(Vector3(GATE_X, 2.6, -6.0), Vector3(1.0, 5.2, 6.4))
	g.box(Vector3(GATE_X, 1.8, 4.6), Vector3(1.0, 3.6, 3.4))
	g.color = MarshKit.STONE.darkened(0.25)
	g.box(Vector3(GATE_X, 0.2, -6.0), Vector3(1.2, 1.6, 6.6))
	g.box(Vector3(GATE_X, 0.2, 4.6), Vector3(1.2, 1.6, 3.6))
	_mesh(g)
	add_child(Scenery.tiled_roof(_rng, GATE_X - 2.3, GATE_X + 2.3, Vector2(top + 2.9, 3.6), Vector2(top + 4.6, 0.0), 5))
	add_child(Scenery.tiled_roof(_rng, GATE_X - 2.3, GATE_X + 2.3, Vector2(top + 2.9, -3.6), Vector2(top + 4.6, 0.0), 5))
	# Lanterns on the gate, dim.
	for z: float in [-2.4, 2.4]:
		var lantern := Scenery.lantern(_rng, marsh.village.lantern_glow * 0.6, 1.0)
		lantern.position = Vector3(GATE_X - 0.6, top - 0.35, z)
		add_child(lantern)
		Scenery.windswept(lantern, 0.035, _rng)
	marsh._light(Vector3(GATE_X - 1.2, top - 1.2, 0.0), 1.4, 7.0)
	marsh._shine(GATE_X - 1.5, 1.2, Color(1.0, 0.66, 0.36, 0.2))
	# Stone lanterns sunk in the court, banners on the back wall.
	for lx: float in [362.0, 374.0, 386.0]:
		var stone := MarshKit.stone_lantern(_rng, false)
		stone.position = Vector3(lx, -0.2, -3.6)
		add_child(stone)
	for bx: float in [365.0, 380.0, 395.0]:
		var pole := PaperMesh.new(_rng.randi())
		pole.color = Color(0.14, 0.12, 0.12)
		pole.box(Vector3(bx, 5.2, -5.6), Vector3(1.0, 0.06, 0.06))
		pole.box(Vector3(bx - 0.5, 5.3, -5.75), Vector3(0.08, 0.3, 0.2))
		_mesh(pole)
		var banner: Node3D = marsh.call(&"_limp_banner")
		banner.position = Vector3(bx, 5.17, -5.6)
		add_child(banner)
		Scenery.windswept(banner, 0.03, _rng)
	# Past the gate the fort's wall runs on east into the fog, dead trees
	# behind it (the way on: the next region, not built).
	var e := PaperMesh.new(_rng.randi())
	e.shade_jitter = 0.12
	var ex := GATE_X + 0.5
	while ex < GATE_X + 40.0:
		var ex1 := ex + 6.0
		e.color = MarshKit.STONE.darkened(_rng.randf_range(0.2, 0.35))
		e.box(Vector3((ex + ex1) * 0.5, 0.3, -6.0), Vector3(ex1 - ex, 2.4, 1.2))
		e.color = Color(0.48, 0.46, 0.42).darkened(_rng.randf_range(0.1, 0.25))
		e.box(Vector3((ex + ex1) * 0.5, 3.2, -6.2), Vector3(ex1 - ex, 3.4, 0.6))
		ex = ex1
	e.color = Color(0.5, 0.48, 0.44).darkened(0.15)
	e.box(Vector3(GATE_X + 14.0, 5.0, -8.5), Vector3(5.0, 10.0, 4.0))   # a corner tower
	_mesh(e)
	add_child(Scenery.tiled_roof(_rng, GATE_X + 0.3, GATE_X + 40.0, Vector2(5.0, -5.2), Vector2(5.7, -6.8), 4))
	add_child(Scenery.tiled_roof(_rng, GATE_X + 11.0, GATE_X + 17.0, Vector2(10.2, -6.2), Vector2(12.0, -8.5), 4))
	for k in 6:
		var tree := MarshKit.dead_tree(_rng, _rng.randf_range(6.0, 10.0), _rng.randf_range(-0.2, 0.2), 0.3, 2)
		tree.position = Vector3(GATE_X + 4.0 + k * 6.5 + _rng.randf_range(-1.5, 1.5), 0.0, _rng.randf_range(-12.0, -9.0))
		add_child(tree)
	# The way on is shut (until he is beaten).
	_gate_wall = marsh._solid(Vector3(GATE_X + 0.2, 8.0, 0.0), Vector3(0.6, 20.0, 4.0))
	_gate_wall.set_meta(&"no_climb", true)


## The great gate swings open east (after the fight; at once in a saved game).
func open_gate(slow: bool) -> void:
	if _gate_wall:
		_gate_wall.queue_free()
		_gate_wall = null
	if marsh.end_wall:
		marsh.end_wall.queue_free()
		marsh.end_wall = null
	for i in _doors.size():
		var side := -1.0 if i == 0 else 1.0
		var to := side * -1.45
		if slow:
			var t := create_tween()
			t.tween_interval(i * 0.15)
			t.tween_property(_doors[i], "rotation:y", to, 2.0).set_trans(Tween.TRANS_SINE)
		else:
			_doors[i].rotation.y = to
	if slow:
		Sound.play(self, &"shutter_open", 4.0)


func _mesh(b: PaperMesh) -> void:
	add_child(b.build())


# --- The fight --------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
		_ronin.died.connect(_on_ronin_died)
	var x := _ronin.global_position.x - marsh.global_position.x
	var camera := get_viewport().get_camera_3d() as FollowCamera
	if camera:
		if _state == &"fight":
			camera.focus = shimeri.global_position + Vector3(0.0, 2.6, 0.0)
			_focused = true
		elif _focused:
			camera.focus = Vector3(NAN, NAN, NAN)
			_focused = false
	# How many of his warriors are up (or rising): he musters more when few.
	var alive := 0
	for r: Node in _soldiers:
		if is_instance_valid(r):
			var h: Node = (r as InkRiser).husk
			if is_instance_valid(h) and not h.is_queued_for_deletion():
				alive += 1
	shimeri.soldiers_alive = alive
	match _state:
		&"before":
			if x > ARENA.x + 4.0 and _ronin.is_on_floor() and _ronin.is_physics_processing():
				if SaveGame.shimeri_met:
					_start_fight()
				else:
					_start_intro()
		&"intro":
			_ronin.facing = 1.0
			(_ronin.get_node("Puppet") as RoninPuppet).facing = 1.0
		&"after":
			if not _held and _ronin.is_on_floor():
				_held = true
				_hold_ronin(true)


func _overlay_node() -> Node:
	var hud := get_tree().get_first_node_in_group(&"hud")
	return hud.get_parent() if hud else null


func _hold_ronin(on: bool) -> void:
	_ronin.set_physics_process(not on)
	if on:
		_ronin.velocity = Vector3.ZERO
		(_ronin.get_node("Puppet") as RoninPuppet).state = &"idle"


func _start_intro() -> void:
	_state = &"intro"
	SaveGame.shimeri_met = true
	_hold_ronin(true)
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
	_title = _make_title()
	_overlay.add_child(_title)
	_skip = SkipPrompt.new()
	_overlay.add_child(_skip)
	_skip.skipped.connect(func() -> void:
		if _state == &"intro" and _cine:
			_cine.finish())
	var m := marsh.global_position
	var hx := HIS_X
	var him := func() -> Vector3: return shimeri.global_position + Vector3(0.0, 3.4, 0.0)
	_cine = CineCamera.new()
	_cine.game_camera = get_viewport().get_camera_3d()
	_cine.length = 12.0
	_cine.shot(0.0, 3.4, m + Vector3(ARENA.x + 1.0, 1.6, 13.0), m + Vector3(ARENA.x + 11.0, 2.0, 12.0),
			m + Vector3(ARENA.x + 13.0, 2.2, -6.0), m + Vector3(hx - 2.0, 3.0, -5.0), Vector2(44.0, 42.0))
	_cine.shot(3.4, 6.2, func() -> Vector3: return him.call() + Vector3(-3.2, -1.2, 4.6),
			func() -> Vector3: return him.call() + Vector3(-2.6, -0.8, 3.8), him, him, Vector2(38.0, 34.0))
	_cine.shot(6.2, 8.4, m + Vector3(hx - 9.0, 1.2, 7.5), m + Vector3(hx - 8.0, 1.4, 7.0), him, him, Vector2(42.0, 40.0))
	# Low at his feet, looking up as he towers and raises the nodachi.
	_cine.shot(8.4, 9.8, m + Vector3(hx - 3.2, 0.45, 3.6), m + Vector3(hx - 2.8, 0.5, 3.2),
			m + Vector3(hx, 4.2, -0.5), m + Vector3(hx, 5.0, -0.5), Vector2(52.0, 50.0))
	_cine.shot(9.8, 12.0, m + Vector3(hx - 10.0, 3.0, 15.0), m + Vector3(hx - 12.0, 3.6, 18.0),
			m + Vector3(hx - 4.0, 2.4, -2.0), m + Vector3(hx - 6.0, 2.6, -2.0), Vector2(40.0, 40.0), Vector2.ZERO, 0.02, 0.8)
	_cine.at(0.2, func() -> void:
		Sound.play(self, &"thunder_crack", 0.0)
		_cine.flash(0.55, 0.4))
	_cine.at(2.6, func() -> void:
		Sound.play(self, &"thunder_crack", -4.0)
		_cine.flash(0.35, 0.3))
	_cine.at(3.6, func() -> void:
		Sound.play(self, &"shimeri_groan", 6.0)
		_cine.shake(0.35)
		var kindle := create_tween()
		kindle.tween_property(shimeri, "eyes", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
		shimeri.set(&"_mode", &"guard"))
	_cine.at(6.3, func() -> void:
		var words := BrushLine.new()
		words.texture = preload("res://textures/shimeri_warning.png")
		var place := _overlay_node()
		if place:
			place.add_child(words)
			words.show_line(2.0))
	_cine.at(8.4, func() -> void: shimeri.set(&"_mode", &"cleave_tell"))
	_cine.at(9.5, func() -> void:
		shimeri.set(&"_mode", &"cleave")
		shimeri.call(&"_send_waves")
		shimeri.set(&"_waves", [])
		Engine.time_scale = 0.35
		Sound.play(self, &"taiko_hit", 6.0)
		Sound.play(self, &"thunder_crack", 2.0)
		WaterFx.splash(self, shimeri.position + Vector3(-2.6, -SumiMarsh.SHALLOW_BED, 0.0), 2.6, true)
		_cine.flash(0.6, 0.5)
		_cine.shake(1.0))
	_cine.at(9.75, func() -> void:
		Engine.time_scale = 1.0
		_title.paint())
	_cine.at(10.6, func() -> void: _seal(true))
	_cine.finished.connect(func() -> void:
		Engine.time_scale = 1.0
		if _state == &"intro":
			_end_intro())
	add_child(_cine)


func _make_title() -> HannyaTitle:
	var title := HannyaTitle.new()
	title.KANJI = preload("res://textures/title_shimeri_kanji.png")
	title.NAME = preload("res://textures/title_shimeri_name.png")
	title.SUBTITLE = preload("res://textures/title_shimeri_subtitle.png")
	title.SEAL = preload("res://textures/seal_shimeri.png")
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return title


func _end_intro() -> void:
	if _state != &"intro":
		return
	_state = &"starting"
	if _cine:
		var cine := _cine
		_cine = null
		cine.finish()
	if _overlay:
		var fade := create_tween()
		fade.tween_property(_overlay, "modulate:a", 0.0, 0.5)
		fade.tween_callback(_overlay.queue_free)
		_overlay = null
	if _hud:
		_hud.visible = true
	_hold_ronin(false)
	_start_fight()


## A curtain of ink pours down across the way back while he fights.
func _seal(shut: bool) -> void:
	if shut and _curtain == null:
		_curtain = InkCurtain.new()
		_curtain.width = 1.6
		_curtain.bottom = SumiMarsh.SHALLOW_BED - 8.0
		_curtain.press = 0.0
		_curtain.position = Vector3(ARENA.x - 0.2, 8.0, 0.0)
		add_child(_curtain)
		_curtain.scale = Vector3(1.0, 0.05, 1.0)
		var t := create_tween()
		t.tween_property(_curtain, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_SINE)
		_wall = marsh._solid(Vector3(ARENA.x - 0.2, 8.0, 0.0), Vector3(0.8, 20.0, 4.0))
		_wall.set_meta(&"no_climb", true)
	elif not shut and _curtain:
		var c := _curtain
		_curtain = null
		var t := create_tween()
		t.tween_property(c, "scale", Vector3(1.0, 0.02, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
		t.tween_callback(c.queue_free)
		if _wall:
			_wall.queue_free()
			_wall = null


func _start_fight() -> void:
	_state = &"fight"
	_seal(true)
	shimeri.begin()
	Sound.duck_music(true)
	_play_music(true)
	_camera_back(true)
	if _bar == null:
		_bar = BossBar.new()
		_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		var where := _overlay_node()
		if where:
			where.add_child(_bar)
		_bar.watch(shimeri, preload("res://textures/title_shimeri_kanji.png"), preload("res://textures/title_shimeri_name.png"))
	shimeri.health_changed.emit(shimeri.health, shimeri.max_health)


func _camera_back(on: bool) -> void:
	var camera := get_viewport().get_camera_3d() as FollowCamera
	if camera == null:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "distance", fight_camera_distance if on else 15.0, 1.5).set_trans(Tween.TRANS_SINE)


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
		_music_fade.tween_property(_music, "volume_db", -60.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_fade.tween_callback(_music.stop)


## The Drowned Muster: where he calls them, the ink bubbles for a moment
## (the tell), then his drowned warriors rise there in a spurt of ink.
func _muster(points: Array) -> void:
	for x: float in points:
		var local := x - marsh.global_position.x
		var bubbles := CPUParticles3D.new()
		bubbles.amount = 22
		bubbles.lifetime = 0.5
		bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		bubbles.emission_sphere_radius = 0.45
		bubbles.direction = Vector3.UP
		bubbles.spread = 25.0
		bubbles.gravity = Vector3(0.0, -6.0, 0.0)
		bubbles.initial_velocity_min = 0.6
		bubbles.initial_velocity_max = 1.6
		var bead := QuadMesh.new()
		bead.size = Vector2(0.1, 0.1)
		bead.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.05, 0.95))
		bubbles.mesh = bead
		bubbles.position = Vector3(local, SumiMarsh.INK_Y + 0.02, 0.0)
		add_child(bubbles)
		Sound.play(self, &"ink_surge", 0.0)
		var rise := get_tree().create_timer(1.0)
		rise.timeout.connect(func() -> void:
			bubbles.emitting = false
			var t := get_tree().create_timer(0.6)
			t.timeout.connect(bubbles.queue_free)
			if _state != &"fight":
				return
			var riser := InkRiser.new()
			riser.wake_distance = 1000.0
			riser.warrior = true
			riser.position = Vector3(local, SumiMarsh.SHALLOW_BED, 0.0)
			add_child(riser)
			_soldiers.append(riser))


## From half health: two of his drowned soldiers rise from the ink, one at
## each end of the court.
func _call_soldiers() -> void:
	for sx: float in [ARENA.x + 4.0, ARENA.y - 4.0]:
		var rise := InkRiser.new()
		rise.wake_distance = 1000.0
		rise.warrior = true
		rise.position = Vector3(sx, SumiMarsh.SHALLOW_BED, 0.0)
		add_child(rise)
		_soldiers.append(rise)


func _on_ronin_died() -> void:
	if _state != &"fight":
		return
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func() -> void:
		_state = &"before"
		_seal(false)
		if _bar:
			_bar.hide_bar()
		_play_music(false)
		Sound.duck_music(false)
		_camera_back(false)
		for s: Node in _soldiers:
			if is_instance_valid(s):
				s.queue_free()
		_soldiers.clear()
		shimeri.reset(marsh.global_position + Vector3(HIS_X, SumiMarsh.SHALLOW_BED + 0.05, 0.0)))


# --- After -----------------------------------------------------------------------

func _on_defeated() -> void:
	_state = &"after"
	SaveGame.shimeri_beaten = true
	if "shimeri" not in SaveGame.seals:
		SaveGame.seals.append("shimeri")
	_play_music(false)
	if _bar:
		_bar.hide_bar()
	for s2: Node in _soldiers:
		if is_instance_valid(s2):
			var husk: Node = (s2 as InkRiser).husk
			if is_instance_valid(husk) and husk.is_inside_tree():
				Confetti.burst(self, (husk as Node3D).global_position - global_position + Vector3(0.0, 1.0, 0.0), 30, [Color(0.1, 0.1, 0.12), Color(0.5, 0.5, 0.56)])
			s2.queue_free()
	_soldiers.clear()
	_hud = get_tree().get_first_node_in_group(&"hud") as CanvasItem
	if _hud:
		_hud.visible = false
	var g := marsh.global_position.y + SumiMarsh.INK_Y
	var him := func() -> Vector3: return shimeri.global_position + Vector3(0.0, 2.2, 0.0)
	var hx := shimeri.global_position.x
	_cine = CineCamera.new()
	_cine.game_camera = get_viewport().get_camera_3d()
	_cine.length = 19.5
	# The last cut, slowed; he staggers to his knees in the ink.
	_cine.shot(0.0, 1.4, func() -> Vector3: return him.call() + Vector3(-2.6, 0.8, 6.0),
			func() -> Vector3: return him.call() + Vector3(-2.0, 0.4, 4.8), him, him, Vector2(36.0, 32.0))
	_cine.shot(1.4, 5.0, Vector3(hx - 6.0, g + 1.6, 10.0), Vector3(hx - 5.0, g + 1.4, 8.4), him, him, Vector2(40.0, 38.0))
	# Close: the ink drains from him; he lifts his face; his line.
	_cine.shot(5.0, 9.8, func() -> Vector3: return him.call() + Vector3(-1.8, 0.9, 3.4),
			func() -> Vector3: return him.call() + Vector3(-1.5, 0.8, 2.9), him, him, Vector2(32.0, 30.0))
	# The seal: it rises from his hands, glowing, and flies to the Ronin.
	_cine.shot(9.8, 13.6, func() -> Vector3: return (_seal_node.global_position if is_instance_valid(_seal_node) else him.call()) + Vector3(-0.6, 0.2, 2.6),
			func() -> Vector3: return (_seal_node.global_position if is_instance_valid(_seal_node) else him.call()) + Vector3(-0.4, 0.3, 2.2),
			func() -> Vector3: return _seal_node.global_position if is_instance_valid(_seal_node) else him.call(),
			func() -> Vector3: return _seal_node.global_position if is_instance_valid(_seal_node) else him.call(), Vector2(34.0, 30.0))
	# Then he falls forward into the ink and is still.
	_cine.shot(13.6, 19.5, Vector3(hx - 7.0, g + 2.4, 12.0), Vector3(hx - 8.5, g + 3.0, 15.0),
			Vector3(hx - 1.0, g + 0.8, -1.5), Vector3(hx - 2.0, g + 1.0, -1.5), Vector2(40.0, 40.0), Vector2.ZERO, 0.02, 0.8)
	_cine.at(0.0, func() -> void:
		_cine.flash(0.8, 0.7)
		_cine.shake(0.7)
		Sound.play(self, &"thunder_crack", 0.0)
		Engine.time_scale = 0.25)
	_cine.at(0.9, func() -> void:
		Engine.time_scale = 1.0
		_seal(false))
	_cine.at(1.5, func() -> void:
		Sound.play(self, &"splash", 4.0)
		Sound.play(self, &"shimeri_groan", 2.0)
		WaterFx.splash(self, shimeri.position + Vector3(0.0, -SumiMarsh.SHALLOW_BED, 0.0), 1.8, true))
	_cine.at(2.4, func() -> void:
		_wash_ink(true)
		var dim := create_tween()
		dim.tween_property(shimeri, "eyes", 0.0, 2.0))
	_cine.at(5.2, func() -> void:
		var t := create_tween()
		t.tween_method(shimeri.set_kneel, 0.0, 1.0, 2.6).set_trans(Tween.TRANS_SINE))
	_cine.at(7.4, func() -> void:
		var words := BrushLine.new()
		words.texture = preload("res://textures/shimeri_line.png")
		var where := _overlay_node()
		if where:
			where.add_child(words)
			words.show_line(2.4))
	_cine.at(9.9, func() -> void: _give_seal())
	_cine.at(14.0, func() -> void:
		var t := create_tween()
		t.tween_method(shimeri.set_kneel, 1.0, 0.0, 0.6)
		t.parallel().tween_method(shimeri.set_fallen, 0.0, 1.0, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(func() -> void:
			Sound.play(self, &"splash", 6.0)
			Sound.play(self, &"land", 4.0)
			WaterFx.splash(self, shimeri.position + Vector3(shimeri.facing * 2.4, -SumiMarsh.SHALLOW_BED, 0.0), 2.4, true)
			_cine.shake(0.5)))
	_cine.finished.connect(func() -> void:
		Engine.time_scale = 1.0
		_cine = null
		_state = &"done"
		shimeri.set_fallen(1.0)
		_camera_back(false)
		Sound.duck_music(false)
		if _hud:
			_hud.visible = true
		if _held:
			_held = false
			_hold_ronin(false)
		open_gate(true)
		SaveGame.write())
	add_child(_cine)


## The ink drains out of his paper and leaves it pale: his creases show.
func _wash_ink(slow: bool) -> void:
	_wash = ShaderMaterial.new()
	_wash.shader = preload("res://shaders/wash_white.gdshader")
	_wash.set_shader_parameter(&"radius", 3.0)
	_wash.set_shader_parameter(&"centre", shimeri.global_position + Vector3(0.0, 1.8, 0.0))
	_wash.set_shader_parameter(&"paper", Color(0.8, 0.79, 0.76, 0.5))   # (his folds still show)
	shimeri.wash = _wash
	if not slow:
		_wash.set_shader_parameter(&"amount", 0.6)
		return
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _wash.set_shader_parameter(&"amount", v), 0.0, 0.6, 3.6).set_trans(Tween.TRANS_SINE)
	Sound.play(self, &"ink_bleed", 2.0)


var _seal_node: Node3D


## His seal (湿将): it rises from his hands glowing vermilion, turns, and
## flies slowly to the Ronin; where it reaches him, a flash, and the seal is
## stamped across the screen (SealCard).
func _give_seal() -> void:
	_seal_node = Node3D.new()
	add_child(_seal_node)
	# The seal's carved face (湿将), glowing, always turned to the camera.
	var face := Sprite3D.new()
	face.texture = preload("res://textures/seal_shimeri.png")
	face.pixel_size = 0.4 / maxf(face.texture.get_width(), 1.0)
	face.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	face.shaded = false
	face.modulate = Color(1.2, 1.1, 1.1)
	_seal_node.add_child(face)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.45, 0.3)
	glow.light_energy = 2.2
	glow.omni_range = 3.0
	_seal_node.add_child(glow)
	_seal_node.add_child(Scenery.halo(0.5, Color(1.0, 0.5, 0.35, 0.45)))
	_seal_node.scale = Vector3.ONE * 2.6
	_seal_node.position = shimeri.position + Vector3(shimeri.facing * 0.9, 1.3, 0.5)
	Sound.play(self, &"draw_gleam", 2.0)
	var to := _ronin.global_position - global_position + Vector3(0.0, 1.1, 0.3)
	var t := create_tween()
	t.tween_property(_seal_node, "position:y", _seal_node.position.y + 1.4, 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_interval(0.4)
	t.tween_property(_seal_node, "position", to, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(_seal_node, "scale", Vector3.ONE * 0.6, 1.4)
	t.tween_callback(func() -> void:
		_seal_node.queue_free()
		Sound.play(self, &"draw_ready", 4.0)
		Sound.play(self, &"shrine_rest", 0.0)
		if _cine:
			_cine.flash(0.7, 0.6)
		(_ronin.get_node("Puppet") as RoninPuppet).play_healed()
		var card := SealCard.new()
		card.seal = preload("res://textures/seal_shimeri.png")
		card.title = "The seal of Shimeri"
		card.count = SaveGame.seals.size()
		var where := _overlay_node()
		if where:
			where.add_child(card))
