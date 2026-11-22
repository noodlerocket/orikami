class_name Prologue
extends Node3D
## The prologue: Kamiyo folded out of one sheet, like a pop-up book, by
## candlelight; then the Rain soaks it and it forgets its shape. 45 seconds,
## scored to audio/music_prologue.mp3 (its eruption at 25 s is the thunder).
## The brushed lines are in docs/lore.md.
##
## The book lies open on a dark table: a flat page, and a back page standing
## up behind it as the sky. Everything else folds up off the page.
##
##   0     black, then candlelight on one blank sheet, seen from above
##   2     "In the beginning there was one sheet of paper."
##   7.5   creases draw themselves across it
##   9     the sky page rises behind; far mountains, near hills with pines
##         and a torii fold up; the river unrolls
##   10    "From it were folded mountains and rivers, people, and an Emperor."
##   12    the village folds up, house by house, lanterns lighting; a bridge;
##         the well; cherry trees; villagers, a mother holding her child's hand
##   14.5  paper cranes fold themselves and fly up over the village
##   15.6  the castle rises on its hill; 17.5 the red dusk sun climbs behind
##         it; 19.6 the Emperor stands on its terrace
##   21    wide on the whole world, warm and alive
##   25    thunder: lightning, the light goes cold, the Rain falls
##   25.5  "A hundred years ago, the Rain began."
##   26    the paper soaks and darkens; the sun sinks; the lanterns
##         gutter out; the cranes are beaten down onto the page
##   27.5  the Emperor bows his head
##   29.5  "Where it falls, ink bleeds, and paper forgets what it was."
##         close on the mother and child: the prints on their clothes wash
##         away, and they fold down onto the wet page together; one by one
##         every pop-up goes limp and falls
##   32.6  only the well still stands; the camera goes to it
##   36    down into its black mouth: "Deep in a well, something blank has
##         been waiting."   41 black; 45 the game begins at the well's bottom
##
## Everything follows the clock (`time`) alone, so any moment can be
## photographed: --prologue-sheet=path draws a frame sheet (16 moments, or
## --prologue-moments=3,8.5,...). Hold Space (A on a gamepad) to skip.

signal finished

## Set when the prologue ends: the game then starts at the bottom of the well.
static var into_well := false

const LENGTH := 45.0
const MUSIC := preload("res://audio/music_prologue.mp3")
const GAME_SCENE := "res://scenes/main.tscn"
const LINES := [
	[2.0, 7.4, "In the beginning there was one sheet of paper."],
	[10.0, 18.5, "From it were folded mountains and rivers, people, and an Emperor."],
	[25.5, 29.0, "A hundred years ago, the Rain began."],
	[29.5, 34.5, "Where it falls, ink bleeds, and paper forgets what it was."],
	[36.0, 41.5, "Deep in a well, something blank has been waiting."],
]

const OFF := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
const PAGE := Color(0.93, 0.89, 0.8)
const INDIGO := Color(0.2, 0.25, 0.42)
const WARM_LIGHT := Color(1.0, 0.8, 0.58)
const COLD_LIGHT := Color(0.66, 0.7, 0.84)
## What soaked paper turns to (multiplied over every colour).
const WET := Color(0.34, 0.34, 0.4)
## Where the well stands on the page; the end of the prologue looks into it.
const WELL_AT := Vector3(-1.3, 0.0, 5.7)
## The front edge of the page, where the cut-away of the ground hangs.
const FRONT := 6.42
## How deep the well's shaft goes under the page.
const SHAFT_BOTTOM := -3.2

@export var skip_hold := 0.8

## The clock. Everything is drawn from it.
var time := 0.0
var playing := true

var _camera: Camera3D
var _lamp: DirectionalLight3D
var _flash: DirectionalLight3D
var _env: Environment
var _world: Node3D
var _rain: CPUParticles3D
var _music: AudioStreamPlayer
var _rain_sound: AudioStreamPlayer
var _overlay: Control
var _done := false
var _rng := RandomNumberGenerator.new()
var _last_fold := -10.0

var _pops: Array[Dictionary] = []      # {node, t0, dur, fall, angle, fall_dur, sound}
var _soak: Array[Dictionary] = []      # {mat, delay}
var _glows: Array[Dictionary] = []     # {mat, energy}
var _lamps: Array[Dictionary] = []     # {light, energy}
var _cranes: Array[Dictionary] = []
var _creases: Array[Dictionary] = []   # {node, t0}
var _river: Array[Dictionary] = []     # {node, t0}
var _pools: Array[Dictionary] = []     # {node, t0, size}
var _prints: Array[StandardMaterial3D] = []   # the villagers' printed clothes (washed away)
var _sun: Node3D
var _emperor: Node3D
var _emperor_tears: CPUParticles3D
var _shots: Array[Dictionary] = []
var _well_light: OmniLight3D
var _blank: MeshInstance3D
var _candle: OmniLight3D


func _ready() -> void:
	_rng.seed = 2611
	var sound := Sound.new()
	sound.ambience = false
	add_child(sound)
	Sound.load_levels()
	_build_air()
	_world = Node3D.new()
	add_child(_world)
	_build_table_and_page()
	_build_sky_page()
	_build_land()
	_build_village()
	_build_castle()
	_build_cranes()
	_build_rain()
	_build_cutaway()
	_collect_materials()
	_plan_shots()
	_build_overlay()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--prologue-sheet="):
			playing = false
			_frame_sheet.call_deferred(arg.trim_prefix("--prologue-sheet="))
			return
		elif arg.begins_with("--prologue-at="):
			time = float(arg.trim_prefix("--prologue-at="))
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC
	add_child(_music)
	Sound.follow_level(_music, 0.0)
	_music.play(time)
	var rain := load("res://audio/rain_close.mp3") as AudioStreamMP3
	rain.loop = true
	_rain_sound = AudioStreamPlayer.new()
	_rain_sound.stream = rain
	add_child(_rain_sound)
	Sound.follow_level(_rain_sound, -80.0, &"sounds")
	_apply()


func _process(delta: float) -> void:
	if not playing:
		return
	var before := time
	time += delta
	# Each pop-up folds up with a paper sound (not too many at once).
	for pop: Dictionary in _pops:
		var t0: float = pop["t0"]
		if before < t0 and time >= t0 and pop["sound"] and time - _last_fold > 0.09:
			Sound.play(self, &"paper_fold", _rng.randf_range(-4.0, 0.0))
			_last_fold = time
	if _rain_sound and time > 24.8:
		var level := lerpf(-28.0, -13.0, clampf((time - 24.8) / 1.5, 0.0, 1.0)) - maxf(time - 38.0, 0.0) * 5.0
		Sound.follow_level(_rain_sound, level, &"sounds")
		if not _rain_sound.playing:
			_rain_sound.play()
	if time >= LENGTH:
		_finish()
		return
	_apply()


func _finish() -> void:
	if _done:
		return
	_done = true
	playing = false
	finished.emit()
	if is_inside_tree() and get_tree().current_scene == self:
		into_well = true
		get_tree().change_scene_to_file(GAME_SCENE)


## 0..1 as the clock goes from a to b, smoothed.
func _span(a: float, b: float) -> float:
	return smoothstep(a, b, time)


# --- The air: light, camera ---------------------------------------------------------

func _build_air() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.012, 0.01, 0.014)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.42, 0.36, 0.36)
	_env.ambient_light_energy = 0.55
	_env.glow_enabled = true
	_env.glow_intensity = 0.8
	_env.glow_hdr_threshold = 0.85
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.adjustment_enabled = true
	_env.adjustment_saturation = 0.95
	_env.adjustment_contrast = 1.06
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	add_child(world_env)
	# The candle: low, warm, from the front right, so every fold casts a
	# shadow on the page behind it.
	_lamp = DirectionalLight3D.new()
	_lamp.light_color = WARM_LIGHT
	_lamp.light_energy = 1.7
	_lamp.rotation_degrees = Vector3(-32.0, 28.0, 0.0)
	_lamp.shadow_enabled = true
	_lamp.directional_shadow_max_distance = 28.0
	_lamp.shadow_blur = 1.6
	add_child(_lamp)
	_flash = DirectionalLight3D.new()
	_flash.light_color = Color(0.85, 0.9, 1.0)
	_flash.light_energy = 0.0
	_flash.rotation_degrees = Vector3(-70.0, -20.0, 0.0)
	add_child(_flash)
	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.near = 0.02
	_camera.current = true
	add_child(_camera)


## A shot: the camera moves from one place to another and looks from one
## point to another over its time.
func _shot(start: float, end: float, from: Vector3, to: Vector3, look_from: Vector3, look_to: Vector3,
		fov := Vector2(40.0, 40.0), ease_power := 1.0) -> void:
	_shots.append({"start": start, "end": end, "from": from, "to": to, "look_from": look_from,
			"look_to": look_to, "fov": fov, "ease": ease_power})


func _plan_shots() -> void:
	var w := WELL_AT
	# Every shot is from in front of the diorama, looking into it: the camera
	# only pushes in, pulls back, pans sideways and cranes up or down (2.5D,
	# like the Hannya cutscene). It never looks down from above.
	# 1. One blank sheet standing in candlelight; a slow push.
	_shot(0.0, 8.0, Vector3(0.0, 4.6, 8.0), Vector3(0.0, 4.4, 6.5), Vector3(0.0, 4.4, -8.0), Vector3(0.0, 4.2, -8.0), Vector2(40, 39))
	# 2. Pulling back and craning down as the world folds up in front of it.
	_shot(8.0, 11.0, Vector3(0.0, 4.4, 6.5), Vector3(-1.0, 2.4, 11.5), Vector3(0.0, 4.2, -8.0), Vector3(-1.0, 1.6, -4.0),
			Vector2(39, 42), 0.8)
	# 3. Low, panning across the village from left to right as it folds up.
	_shot(11.0, 16.0, Vector3(-5.8, 1.9, 10.2), Vector3(1.8, 1.9, 10.2), Vector3(-5.8, 0.9, -2.0), Vector3(1.8, 1.0, -2.0),
			Vector2(40, 40))
	# 4. Craning up the castle as it rises, the sun climbing behind it and the
	#    Emperor standing on his terrace.
	_shot(16.0, 21.0, Vector3(3.6, 1.4, 6.6), Vector3(3.6, 3.0, 4.6), Vector3(3.6, 1.2, -4.4), Vector3(3.6, 2.8, -4.4),
			Vector2(44, 38), 1.0)
	# 5. Wide: the whole world, warm and alive; a slow push.
	_shot(21.0, 25.0, Vector3(0.0, 4.2, 14.0), Vector3(0.0, 4.0, 12.8), Vector3(0.0, 2.4, -3.0), Vector3(0.0, 2.3, -3.0),
			Vector2(42, 41))
	# 6. The Rain: a slow push in on the castle, where the Emperor bows his
	#    head as the sun sinks.
	_shot(25.0, 28.6, Vector3(0.0, 4.0, 12.8), Vector3(3.4, 2.6, 2.6), Vector3(0.0, 2.3, -3.0), Vector3(3.5, 2.2, -4.4),
			Vector2(41, 34), 1.1)
	# 7. Close on the mother and child as the prints wash off them, and they
	#    fold down onto the wet page together.
	_shot(28.6, 31.2, Vector3(1.6, 0.55, 4.6), Vector3(1.6, 0.5, 4.0), Vector3(1.6, 0.42, 2.3), Vector3(1.6, 0.32, 2.3),
			Vector2(34, 31), 1.0)
	# 8. Pulling back: the whole world goes limp and falls, piece by piece,
	#    while the sun sinks.
	_shot(31.2, 35.4, Vector3(1.4, 1.2, 7.0), Vector3(0.0, 4.0, 14.0), Vector3(1.4, 0.8, 0.0), Vector3(0.0, 1.6, -3.0),
			Vector2(40, 42), 0.8)
	# 9. Craning down past the front edge of the page, by the well (the last
	#    thing standing), into the cut-away of the ground beneath it: the shaft,
	#    and at its bottom one small white figure.
	_shot(35.4, 40.0, Vector3(0.0, 4.0, 14.0), Vector3(w.x, -2.2, 10.4), Vector3(0.0, 1.6, -3.0), Vector3(w.x, -2.35, FRONT - 1.0),
			Vector2(42, 34), 1.3)
	_shot(40.0, 50.0, Vector3(w.x, -2.2, 10.4), Vector3(w.x, -2.7, 8.6), Vector3(w.x, -2.35, FRONT - 1.0), Vector3(w.x, -2.85, FRONT - 1.0),
			Vector2(34, 30))


func _apply_camera() -> void:
	for shot: Dictionary in _shots:
		var start: float = shot["start"]
		var end: float = shot["end"]
		if time < start or time > end:
			continue
		var u := pow(clampf((time - start) / (end - start), 0.0, 1.0), shot["ease"])
		u = u * u * (3.0 - 2.0 * u)
		var at := (shot["from"] as Vector3).lerp(shot["to"], u)
		var look := (shot["look_from"] as Vector3).lerp(shot["look_to"], u)
		# A breath of handheld drift, and a shake with the thunder.
		var drift := Vector3(sin(time * 0.7), sin(time * 0.53 + 1.0), 0.0) * 0.03
		var shake := clampf(1.0 - (time - 25.0) / 0.8, 0.0, 1.0) * 0.06 if time > 25.0 else 0.0
		drift += Vector3(sin(time * 61.0), sin(time * 47.0), 0.0) * shake
		var fov: Vector2 = shot["fov"]
		_camera.fov = lerpf(fov.x, fov.y, u)
		var eye := at + drift
		var up := Vector3.UP if absf((look - eye).normalized().y) < 0.97 else Vector3.FORWARD
		_camera.look_at_from_position(eye, look, up)
		return


# --- Building: the table, the page, the sky ---------------------------------------------

## A paper builder for the pop-up pieces: crisp paper with a fine crumple
## that the candle catches.
func _paper() -> PaperMesh:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.05
	b.texture_world = false
	b.texture_scale = 0.35
	b.wrinkle_depth = 0.35
	return b


func _mesh(b: PaperMesh, parent: Node3D, glow: float = 0.0, shadows: bool = true) -> MeshInstance3D:
	var piece := b.build(Color.WHITE if glow <= 0.0 else PaperMesh.LANTERN, glow)
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else OFF
	parent.add_child(piece)
	return piece


func _build_table_and_page() -> void:
	# The page lies flat on the table (built in its own plane, then laid down:
	# its x is the world's x, its y runs back into the world).
	var page := Node3D.new()
	page.rotation.x = -PI * 0.5
	_world.add_child(page)
	var table := _paper()
	table.color = Color(0.09, 0.065, 0.055)
	table.rect(Vector2(0.0, 19.5), Vector2(90.0, 52.0), -0.04)
	table.color = Color(0.07, 0.05, 0.045)
	for i in 40:   # wood grain
		var y := _rng.randf_range(-6.4, 45.0)
		table.stroke(Vector2(-45.0, y), Vector2(45.0, y + _rng.randf_range(-0.5, 0.5)), 0.05, 0.05, -0.035)
	_mesh(table, page, 0.0, false)
	var sheet := _paper()
	sheet.color = PAGE
	var outline := PackedVector2Array([Vector2(-19.0, -6.4), Vector2(19.0, -6.4), Vector2(19.0, 8.0), Vector2(-19.0, 8.0)])
	sheet.torn_sheet(PaperMesh.tear(outline, 0.6, 0.08, _rng), 0.0, Color(0.98, 0.96, 0.9), 0.06)
	var sheet_mesh := _mesh(sheet, page, 0.0, false)
	sheet_mesh.set_meta(&"page", true)
	# The river, lying on the page; it unrolls from the back to the front.
	var course: Array[Vector2] = [Vector2(-3.4, 7.6), Vector2(-2.9, 5.2), Vector2(-2.3, 3.0), Vector2(-2.2, 0.9), Vector2(-2.5, -1.0),
			Vector2(-3.1, -3.0), Vector2(-3.4, -4.6), Vector2(-3.2, -6.3)]
	for i in course.size() - 1:
		var a := course[i]
		var b := course[i + 1]
		var side := (b - a).orthogonal().normalized() * 0.62
		var water := _paper()
		water.color = INDIGO.lightened(0.08)
		water.polygon(PackedVector2Array([a - side, b - side * 1.05, b + side * 1.05, a + side]), 0.006)
		water.color = Color(0.78, 0.8, 0.88)
		for k in 4:   # glints
			var p := a.lerp(b, _rng.randf())
			var along := (b - a).normalized() * _rng.randf_range(0.15, 0.4)
			var shift := side * _rng.randf_range(-0.6, 0.6)
			water.stroke(p + shift - along, p + shift + along, 0.025, 0.025, 0.008)
		var strip := _mesh(water, page, 0.0, false)
		_river.append({"node": strip, "t0": 10.6 + i * 0.28})


## The sky: the back page of the open book, standing up behind the world:
## a dusk wash, torn clouds, and the red sun that climbs it.
func _build_sky_page() -> void:
	var back := Node3D.new()
	back.position = Vector3(0.0, 0.0, -8.0)
	_world.add_child(back)
	var sky := _paper()
	sky.texture_scale = 0.2
	var bands := [[0.0, Color(0.96, 0.8, 0.62)], [2.5, Color(0.92, 0.66, 0.52)], [5.0, Color(0.7, 0.52, 0.56)], [8.0, Color(0.38, 0.36, 0.52)],
			[12.0, Color(0.16, 0.17, 0.3)], [16.0, Color(0.08, 0.08, 0.16)]]
	for i in bands.size() - 1:
		var y0: float = bands[i][0]
		var y1: float = bands[i + 1][0]
		sky.fade_quad(Vector3(-22.0, y0, 0.0), Vector3(22.0, y0, 0.0), Vector3(22.0, y1, 0.0), Vector3(-22.0, y1, 0.0), bands[i][1], bands[i + 1][1])
	# Torn strips of cloud.
	for c: Array in [[-6.5, 7.8, 7.0, 0.7], [3.0, 8.6, 9.0, 0.6], [-1.5, 6.4, 5.0, 0.45], [7.5, 6.9, 5.5, 0.5]]:
		var middle := Vector2(c[0], c[1])
		var long: float = c[2]
		var thick: float = c[3]
		var shape := PackedVector2Array()
		for k in 12:
			var t := k / 11.0
			shape.append(middle + Vector2((t - 0.5) * long, thick * 0.5 * pow(sin(PI * t), 0.6)))
		for k in range(10, 0, -1):
			var t := k / 11.0
			shape.append(middle + Vector2((t - 0.5) * long, -thick * 0.35 * pow(sin(PI * t), 0.8)))
		sky.color = Color(0.98, 0.9, 0.82)
		sky.torn_sheet(PaperMesh.tear(shape, 0.4, 0.06, _rng), 0.05, Color(1.0, 0.97, 0.92), 0.04)
	var sky_card := Node3D.new()
	back.add_child(sky_card)
	# Its own colours, unlit: the candle would turn a dusk sky to mud.
	var sky_mesh := sky.build(Color.WHITE, 0.0, true)
	sky_mesh.cast_shadow = OFF
	sky_card.add_child(sky_mesh)
	# At first it is only a blank sheet of washi, standing in candlelight:
	# a cover over the sky that fades as the world is folded. Creases draw
	# themselves across it first.
	var blank := PaperMesh.new(5)
	blank.shade_jitter = 0.0
	blank.texture_world = false
	blank.texture_scale = 0.12
	blank.color = Color(0.94, 0.9, 0.82)
	blank.rect(Vector2(0.0, 8.0), Vector2(44.0, 16.5), 0.3)
	_blank = blank.build(Color.WHITE, 0.0, false)
	_blank.cast_shadow = OFF
	(_blank.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sky_card.add_child(_blank)
	_candle = OmniLight3D.new()
	_candle.light_color = Color(1.0, 0.72, 0.45)
	_candle.light_energy = 3.0
	_candle.omni_range = 13.0
	_candle.omni_attenuation = 1.6
	_candle.position = Vector3(0.0, 3.2, 3.5)
	sky_card.add_child(_candle)
	# (They run past the sheet's edges, below the floor page and off the top,
	# so none stops short.)
	var folds := [[Vector2(-14.0, -1.0), Vector2(14.0, 13.0)], [Vector2(14.0, -1.0), Vector2(-14.0, 13.0)], [Vector2(0.0, -1.0), Vector2(0.0, 16.0)],
			[Vector2(-22.0, 6.0), Vector2(22.0, 6.0)], [Vector2(-7.0, -1.0), Vector2(-21.0, 6.0)], [Vector2(7.0, -1.0), Vector2(21.0, 6.0)],
			[Vector2(-7.0, 13.0), Vector2(-21.0, 6.0)], [Vector2(7.0, 13.0), Vector2(21.0, 6.0)], [Vector2(-7.0, -1.0), Vector2(-7.0, 16.0)],
			[Vector2(7.0, -1.0), Vector2(7.0, 16.0)]]
	for i in folds.size():
		var a: Vector2 = folds[i][0]
		var b: Vector2 = folds[i][1]
		var line := PaperMesh.new(i)
		line.shade_jitter = 0.0
		line.texture_scale = 0.0
		line.color = Color(0.66, 0.6, 0.52)
		line.stroke(Vector2.ZERO, Vector2(a.distance_to(b), 0.0), 0.05, 0.05, 0.0)
		var crease := line.build(Color.WHITE, 0.0, true)
		crease.cast_shadow = OFF
		(crease.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		crease.position = Vector3(a.x, a.y, 0.32)
		crease.rotation.z = (b - a).angle()
		sky_card.add_child(crease)
		_creases.append({"node": crease, "t0": 4.0 + i * 0.32})
	# The sun: a crumpled red disc that slides up the sky page.
	_sun = Node3D.new()
	sky_card.add_child(_sun)
	var disc := _paper()
	disc.texture_scale = 0.6
	disc.color = Color(0.82, 0.27, 0.2)
	disc.ellipse(Vector2.ZERO, Vector2(1.55, 1.55), 32, 0.12, 0.015)
	var sun_mesh := disc.build(Color.WHITE, 0.0, true)
	sun_mesh.cast_shadow = OFF
	_sun.add_child(sun_mesh)
	var halo := Scenery.halo(3.6, Color(1.0, 0.4, 0.3, 0.16))
	halo.position = Vector3(0.0, 0.0, 0.08)
	_sun.add_child(halo)


# --- Building: mountains, hills ---------------------------------------------------------

func _build_land() -> void:
	# Far peaks (paler and bluer), then nearer ones.
	var far := _ridge(38.0, [Vector2(-9.0, 3.6), Vector2(-4.5, 4.6), Vector2(0.5, 3.9), Vector2(5.5, 5.2), Vector2(9.5, 4.0)],
			Color(0.6, 0.64, 0.76), Color(0.95, 0.95, 0.97))
	far.position = Vector3(0.0, 0.0, -6.9)
	_world.add_child(far)
	_pop(far, 9.2, 1.0, 33.4, -88.0, 2.6)
	var near := _ridge(38.0, [Vector2(-10.0, 2.6), Vector2(-6.0, 3.3), Vector2(-1.5, 2.4), Vector2(2.5, 2.9), Vector2(7.5, 3.4), Vector2(11.0, 2.4)],
			Color(0.44, 0.49, 0.64), Color(0.86, 0.88, 0.92))
	near.position = Vector3(0.0, 0.0, -5.9)
	_world.add_child(near)
	_pop(near, 9.6, 1.0, 33.0, -88.0, 2.4)
	# Rolling hills with pines, and a torii on the left hill.
	var hills: Array[Node3D] = []
	for h: Array in [[-7.2, -4.4, 6.5, 1.5], [6.5, -4.0, 7.0, 1.3], [-1.0, -4.8, 6.0, 1.1]]:
		var hill := _hill(h[2], h[3])
		hill.position = Vector3(h[0], 0.0, h[1])
		_world.add_child(hill)
		var hx: float = h[0]
		_pop(hill, 10.0 + absf(hx) * 0.04, 0.9, 32.3 + _rng.randf() * 0.8, -88.0, 2.2)
		hills.append(hill)
	# The torii stands on the left hill, and folds up and falls with it.
	var torii := _torii()
	torii.position = Vector3(-0.2, 1.25, 0.1)
	hills[0].add_child(torii)


## A mountain range cut-out: two sheets (a darker ridge in front of the
## peaks), torn snow on the summits.
func _ridge(wide: float, peaks: Array, colour: Color, snow: Color) -> Node3D:
	var card := Node3D.new()
	var b := _paper()
	b.color = colour
	var line := PackedVector2Array([Vector2(-wide * 0.5, 0.0), Vector2(-wide * 0.5, 1.6)])
	var last := Vector2(-wide * 0.5, 1.6)
	for top: Vector2 in peaks:
		for k in range(1, 5):
			line.append(last.lerp(top, k / 5.0) + Vector2(0.0, _rng.randf_range(-0.15, 0.15)))
		line.append(top)
		last = top + Vector2(_rng.randf_range(1.2, 2.0), -_rng.randf_range(1.0, 1.8))
		for k in range(1, 4):
			line.append(top.lerp(last, k / 4.0) + Vector2(0.0, _rng.randf_range(-0.12, 0.12)))
		line.append(last)
	line.append(Vector2(wide * 0.5, 1.4))
	line.append(Vector2(wide * 0.5, 0.0))
	b.torn_sheet(line, 0.0, colour.lightened(0.35), 0.05)
	b.color = snow
	for top: Vector2 in peaks:
		b.polygon(PaperMesh.tear(PackedVector2Array([top + Vector2(0.0, 0.02), top + Vector2(0.75, -0.55), top + Vector2(0.3, -0.42),
				top + Vector2(0.05, -0.7), top + Vector2(-0.25, -0.4), top + Vector2(-0.7, -0.6)]), 0.2, 0.04, _rng), 0.02)
	b.color = colour.darkened(0.12)
	b.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-wide * 0.5, 0.0), Vector2(-wide * 0.5, 0.9), Vector2(-wide * 0.2, 1.3),
			Vector2(0.0, 0.8), Vector2(wide * 0.25, 1.2), Vector2(wide * 0.5, 0.7), Vector2(wide * 0.5, 0.0)]), 0.5, 0.08, _rng), 0.06)
	_mesh(b, card)
	return card


## A rolling hill cut-out with pines along its crest.
func _hill(wide: float, tall: float) -> Node3D:
	var card := Node3D.new()
	var b := _paper()
	b.color = Color(0.43, 0.5, 0.44)
	var line := PackedVector2Array([Vector2(-wide * 0.5, 0.0)])
	for k in range(1, 12):   # (not the ends: those are the corners already)
		var t := k / 12.0
		line.append(Vector2((t - 0.5) * wide, tall * pow(sin(PI * t), 0.7) + _rng.randf_range(-0.05, 0.05)))
	line.append(Vector2(wide * 0.5, 0.0))
	b.torn_sheet(line, 0.0, Color(0.62, 0.68, 0.6), 0.04)
	b.color = Color(0.2, 0.29, 0.26)
	for k in 6:
		var t := _rng.randf_range(0.15, 0.85)
		Scenery.pine(b, Vector2((t - 0.5) * wide, tall * pow(sin(PI * t), 0.7) - 0.1), _rng.randf_range(0.9, 1.5), 0.03, _rng)
	_mesh(b, card)
	return card


func _torii() -> Node3D:
	var card := Node3D.new()
	var b := _paper()
	b.color = Color(0.78, 0.22, 0.15)
	for side: float in [-1.0, 1.0]:
		b.stroke(Vector2(side * 0.42, 0.0), Vector2(side * 0.38, 1.0), 0.09, 0.08)
	b.stroke(Vector2(-0.55, 0.78), Vector2(0.55, 0.78), 0.07, 0.07)
	b.color = Color(0.1, 0.08, 0.08)
	b.polygon(PackedVector2Array([Vector2(-0.72, 1.0), Vector2(-0.3, 0.94), Vector2(0.3, 0.94), Vector2(0.72, 1.0),
			Vector2(0.74, 1.1), Vector2(0.3, 1.04), Vector2(-0.3, 1.04), Vector2(-0.74, 1.1)]), 0.01)
	_mesh(b, card)
	return card


# --- Building: the village --------------------------------------------------------------

func _build_village() -> void:
	# [x, z, width, height, depth, lit, fold-up time]
	var houses := [[-6.6, -1.6, 1.6, 1.15, 1.1, true, 12.3], [-4.7, -0.9, 1.3, 1.0, 1.0, true, 12.6],
			[-6.0, 0.6, 1.4, 0.95, 1.0, false, 12.9], [0.3, -1.4, 1.7, 1.2, 1.1, true, 13.1], [2.3, -0.5, 1.3, 1.0, 1.0, true, 13.4],
			[0.9, 1.0, 1.2, 0.9, 0.9, true, 13.7], [4.4, -1.6, 1.5, 1.1, 1.0, false, 13.9], [-5.2, 2.4, 1.2, 0.9, 0.9, true, 13.5]]
	for h: Array in houses:
		var house := _house(h[2], h[3], h[4], h[5])
		house.rotation.y = _rng.randf_range(-0.12, 0.12)
		var hinge := Node3D.new()
		hinge.position = Vector3(h[0], 0.0, h[1])
		hinge.add_child(house)
		_world.add_child(hinge)
		_pop(hinge, h[6], 0.75, 31.4 + _rng.randf() * 2.4, 0.0, 2.0, true, true)
		var wide: float = h[2]
		_pool(Vector3(h[0], 0.0, h[1]), wide * 1.2, 27.0 + _rng.randf() * 3.0)
	# The bridge over the river, red.
	var bridge := _bridge()
	bridge.position = Vector3(-2.35, 0.0, -0.05)
	_world.add_child(bridge)
	_pop(bridge, 12.0, 0.8, 32.4, 88.0, 1.8)
	# The well, which is still standing at the end.
	var well := _well()
	well.position = WELL_AT
	_world.add_child(well)
	_pop(well, 12.8, 0.7)
	# Cherry trees in faded-pink blossom.
	for t: Array in [[-8.6, -0.4, 2.2], [3.6, 1.2, 1.8], [-3.3, -2.2, 1.9], [5.8, 0.2, 2.0]]:
		var tree := Scenery.sakura_tree(_rng, t[2], _rng.randf_range(-0.6, 0.6), 40)
		var hinge := Node3D.new()
		hinge.position = Vector3(t[0], 0.0, t[1])
		hinge.add_child(tree)
		_world.add_child(hinge)
		_pop(hinge, 12.2 + _rng.randf() * 1.6, 0.8, 31.6 + _rng.randf() * 2.0, 88.0, 2.2)
	# Villagers, paper dolls with printed clothes; a mother and her child at
	# the front, holding hands.
	var people := [[1.3, 2.3, 0, Color(0.3, 0.36, 0.6), 14.3], [1.82, 2.4, 1, Color(0.82, 0.48, 0.5), 14.4],
			[-4.0, 1.1, 0, Color(0.5, 0.36, 0.28), 14.0], [-6.9, 1.8, 2, Color(0.36, 0.42, 0.34), 14.6],
			[3.4, 0.4, 2, Color(0.46, 0.3, 0.42), 14.2], [-1.0, -0.4, 0, Color(0.3, 0.33, 0.5), 14.8]]
	for p: Array in people:
		var doll := _villager(int(p[2]), p[3])
		doll.position = Vector3(p[0], 0.0, p[1])
		_world.add_child(doll)
		var x: float = p[0]
		var together := absf(x - 1.5) < 0.6   # the mother and child fall together
		_pop(doll, p[4], 0.6, 29.5 if together else 31.3 + _rng.randf() * 1.6, 88.0, 1.9 if together else 1.4)
		_pool(Vector3(p[0], 0.0, float(p[1]) + 0.2), 0.7, 28.5)
	# Their hands: a strip joining mother and child.
	var hands := _paper()
	hands.color = Color(0.93, 0.88, 0.8)
	hands.stroke(Vector2(1.5, 0.23), Vector2(1.7, 0.21), 0.03, 0.03, 0.02)
	var hold := Node3D.new()
	hold.position = Vector3(0.0, 0.0, 2.35)
	_world.add_child(hold)
	_mesh(hands, hold)
	_pop(hold, 14.45, 0.5, 29.5, 88.0, 1.9, false)


## A folded paper house: cream walls with dark timbers, a lit shoji window,
## a deep indigo roof with ridged tiles.
func _house(wide: float, tall: float, deep: float, lit: bool) -> Node3D:
	var root := Node3D.new()
	var b := _paper()
	var hw := wide * 0.5
	var hd := deep * 0.5
	b.color = Color(0.9, 0.85, 0.74)
	b.box(Vector3(0.0, tall * 0.5, 0.0), Vector3(wide, tall, deep))
	# Timbers on the front.
	b.color = Color(0.22, 0.16, 0.13)
	for x: float in [-hw + 0.04, hw - 0.04, -hw * 0.3, hw * 0.3]:
		b.box(Vector3(x, tall * 0.5, hd + 0.005), Vector3(0.06, tall, 0.02))
	b.box(Vector3(0.0, tall * 0.42, hd + 0.006), Vector3(wide, 0.05, 0.02))
	b.box(Vector3(0.0, 0.05, hd + 0.006), Vector3(wide, 0.1, 0.02))
	_mesh(b, root)
	# The window (warm, glowing when lit) with its lattice.
	var win := _paper()
	win.color = Color(1.0, 0.82, 0.55) if lit else Color(0.5, 0.46, 0.4)
	win.box(Vector3(hw * 0.65, tall * 0.68, hd + 0.012), Vector3(hw * 0.5, tall * 0.3, 0.01))
	if lit:
		_mesh(win, root, 1.4)
	else:
		_mesh(win, root)
	var lattice := _paper()
	lattice.color = Color(0.22, 0.16, 0.13)
	for k in 3:
		lattice.box(Vector3(hw * 0.65 + (k - 1) * hw * 0.16, tall * 0.68, hd + 0.02), Vector3(0.015, tall * 0.3, 0.01))
	lattice.box(Vector3(hw * 0.65, tall * 0.68, hd + 0.02), Vector3(hw * 0.5, 0.015, 0.01))
	# A dark doorway, half covered by a noren curtain.
	lattice.box(Vector3(-hw * 0.55, tall * 0.3, hd + 0.012), Vector3(hw * 0.45, tall * 0.6, 0.01))
	_mesh(lattice, root)
	var noren := _paper()
	noren.color = Color(0.25, 0.32, 0.55)
	for k in 3:
		noren.box(Vector3(-hw * 0.55 + (k - 1) * hw * 0.15, tall * 0.5, hd + 0.03), Vector3(hw * 0.13, tall * 0.22, 0.01))
	_mesh(noren, root)
	# The roof: two slopes over the eaves, a ridge, rows of tiles.
	var roof := _paper()
	var over := 0.18
	var peak := tall + deep * 0.42
	roof.color = Color(0.2, 0.24, 0.38)
	roof.quad(Vector3(-hw - over, tall - 0.04, hd + over), Vector3(hw + over, tall - 0.04, hd + over), Vector3(hw + over, peak, 0.0),
			Vector3(-hw - over, peak, 0.0), Vector3(0.0, 1.0, 1.0))
	roof.quad(Vector3(-hw - over, tall - 0.04, -hd - over), Vector3(hw + over, tall - 0.04, -hd - over), Vector3(hw + over, peak, 0.0),
			Vector3(-hw - over, peak, 0.0), Vector3(0.0, 1.0, -1.0))
	roof.color = Color(0.32, 0.36, 0.52)
	for k in 4:
		var t := (k + 0.5) / 4.0
		var y := lerpf(tall - 0.04, peak, t)
		var z := lerpf(hd + over, 0.0, t)
		roof.box(Vector3(0.0, y + 0.012, z), Vector3(wide + over * 2.0, 0.02, 0.03))
	roof.color = Color(0.12, 0.14, 0.22)
	roof.box(Vector3(0.0, peak + 0.03, 0.0), Vector3(wide + over * 2.2, 0.07, 0.09))
	# The gable ends.
	roof.color = Color(0.86, 0.8, 0.7)
	for side: float in [-1.0, 1.0]:
		roof.tri(Vector3(side * hw, tall, hd), Vector3(side * hw, tall, -hd), Vector3(side * hw, peak - 0.03, 0.0), Vector3(side, 0.0, 0.0))
	_mesh(roof, root)
	# A small lantern at the door, glowing.
	if lit:
		var lamp := _paper()
		lamp.color = Color(1.0, 0.75, 0.45)
		lamp.ellipse(Vector2.ZERO, Vector2(0.08, 0.11), 10, 0.0)
		var lantern := _mesh(lamp, root, 2.4, false)
		lantern.position = Vector3(-hw - 0.05, tall * 0.72, hd + 0.12)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.7, 0.4)
		light.light_energy = 0.9
		light.omni_range = 2.2
		light.position = lantern.position + Vector3(0.0, 0.0, 0.2)
		root.add_child(light)
		_lamps.append({"light": light, "energy": 0.9})
	return root


func _bridge() -> Node3D:
	var card := Node3D.new()
	var b := _paper()
	b.color = Color(0.76, 0.22, 0.16)
	var arch_top := PackedVector2Array()
	var arch_bottom := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		var x := lerpf(-1.1, 1.1, t)
		arch_top.append(Vector2(x, 0.25 + 0.45 * sin(PI * t)))
		arch_bottom.append(Vector2(x, 0.12 + 0.42 * sin(PI * t)))
	arch_bottom.reverse()
	var deck := arch_top.duplicate()
	deck.append_array(arch_bottom)
	b.polygon(deck, 0.0)
	for k in 7:   # rail posts and the rail
		var t := (k + 0.5) / 7.0
		var x := lerpf(-1.05, 1.05, t)
		var y := 0.25 + 0.45 * sin(PI * t)
		b.stroke(Vector2(x, y), Vector2(x, y + 0.22), 0.035, 0.035, 0.01)
	for k in 12:
		var t0 := k / 12.0
		var t1 := (k + 1) / 12.0
		b.stroke(Vector2(lerpf(-1.1, 1.1, t0), 0.45 + 0.45 * sin(PI * t0)), Vector2(lerpf(-1.1, 1.1, t1), 0.45 + 0.45 * sin(PI * t1)), 0.035, 0.035, 0.012)
	b.color = Color(0.4, 0.12, 0.1)
	for x: float in [-0.95, 0.95]:   # piers
		b.stroke(Vector2(x, 0.0), Vector2(x, 0.25), 0.1, 0.1, -0.01)
	_mesh(b, card)
	return card


func _well() -> Node3D:
	var root := Node3D.new()
	var b := _paper()
	b.color = Color(0.6, 0.6, 0.66)
	b.frustum(10, Vector2(0.36, 0.36), Vector2(0.33, 0.33), 0.3)
	b.color = Color(0.72, 0.72, 0.78)
	b.frustum(10, Vector2(0.35, 0.35), Vector2(0.35, 0.35), 0.04, Vector3(0.0, 0.29, 0.0))
	b.color = Color(0.24, 0.17, 0.13)   # posts, set back, and a little roof
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * 0.42, 0.55, -0.32), Vector3(0.05, 1.1, 0.05))
	b.box(Vector3(0.0, 1.05, -0.32), Vector3(0.95, 0.05, 0.05))
	b.color = Color(0.2, 0.24, 0.38)
	b.quad(Vector3(-0.6, 1.08, 0.0), Vector3(0.6, 1.08, 0.0), Vector3(0.6, 1.32, -0.32), Vector3(-0.6, 1.32, -0.32), Vector3(0.0, 1.0, 1.0))
	b.quad(Vector3(-0.6, 1.08, -0.64), Vector3(0.6, 1.08, -0.64), Vector3(0.6, 1.32, -0.32), Vector3(-0.6, 1.32, -0.32), Vector3(0.0, 1.0, -1.0))
	_mesh(b, root)
	# A cold light that finds the well at the end.
	_well_light = OmniLight3D.new()
	_well_light.light_color = Color(0.78, 0.84, 1.0)
	_well_light.light_energy = 0.0
	_well_light.omni_range = 3.0
	_well_light.position = Vector3(0.3, 1.6, 1.2)
	root.add_child(_well_light)
	return root


## A paper doll villager, facing us: kimono with a printed pattern, an obi,
## a round face, dark hair. 0: woman, 1: child, 2: man in a kasa hat.
func _villager(kind: int, cloth: Color) -> Node3D:
	var root := Node3D.new()
	var b := _paper()
	var tall := 0.62 if kind != 1 else 0.38
	var w := tall * 0.34
	b.color = cloth
	b.polygon(PackedVector2Array([Vector2(-w * 0.55, 0.0), Vector2(w * 0.55, 0.0), Vector2(w * 0.6, tall * 0.45), Vector2(w * 1.05, tall * 0.56),
			Vector2(w * 0.95, tall * 0.74), Vector2(w * 0.4, tall * 0.8), Vector2(-w * 0.4, tall * 0.8), Vector2(-w * 0.95, tall * 0.74),
			Vector2(-w * 1.05, tall * 0.56), Vector2(-w * 0.6, tall * 0.45)]), 0.0)
	b.color = Color(0.86, 0.76, 0.42) if kind != 2 else Color(0.2, 0.2, 0.24)   # the obi
	b.rect(Vector2(0.0, tall * 0.52), Vector2(w * 1.25, tall * 0.08), 0.01)
	b.color = Color(0.95, 0.9, 0.84)   # collar and face
	b.polygon(PackedVector2Array([Vector2(-w * 0.18, tall * 0.8), Vector2(w * 0.18, tall * 0.8), Vector2(0.0, tall * 0.68)]), 0.012)
	b.ellipse(Vector2(0.0, tall * 0.88), Vector2(w * 0.32, w * 0.36), 14, 0.012)
	b.color = Color(0.08, 0.07, 0.08)   # eyes, painted in ink
	for side: float in [-1.0, 1.0]:
		b.stroke(Vector2(side * w * 0.16, tall * 0.885), Vector2(side * w * 0.06, tall * 0.875), w * 0.05, w * 0.03, 0.016)
	if kind == 2:   # a kasa hat
		b.color = Color(0.72, 0.62, 0.44)
		b.polygon(PackedVector2Array([Vector2(-w * 0.85, tall * 0.92), Vector2(w * 0.85, tall * 0.92), Vector2(0.0, tall * 1.1)]), 0.02)
	else:   # hair
		b.color = Color(0.07, 0.06, 0.08)
		b.polygon(PackedVector2Array([Vector2(-w * 0.34, tall * 0.9), Vector2(-w * 0.3, tall * 0.98), Vector2(-w * 0.1, tall * 1.03),
				Vector2(w * 0.1, tall * 1.03), Vector2(w * 0.3, tall * 0.98), Vector2(w * 0.34, tall * 0.9), Vector2(0.0, tall * 0.95)]), 0.014)
		b.ellipse(Vector2(0.0, tall * 1.06), Vector2(w * 0.16, w * 0.12), 10, 0.013)
	_mesh(b, root)
	# The print on the kimono: small flowers and lines, which the Rain washes away.
	var pattern := _paper()
	pattern.color = Color(0.96, 0.9, 0.8) if kind != 1 else Color(0.98, 0.95, 0.9)
	for k in 9:
		var at := Vector2(_rng.randf_range(-w * 0.6, w * 0.6), _rng.randf_range(tall * 0.08, tall * 0.44))
		for petal in 5:
			var a := TAU * petal / 5.0
			pattern.ellipse(at + Vector2(cos(a), sin(a)) * w * 0.07, Vector2(w * 0.045, w * 0.045), 6, 0.008)
	pattern.color = Color(0.78, 0.22, 0.16)
	for k in 3:
		var y := tall * (0.12 + k * 0.12)
		pattern.stroke(Vector2(-w * 0.5, y), Vector2(w * 0.5, y + tall * 0.02), w * 0.04, w * 0.04, 0.007)
	var printed := pattern.build()
	printed.cast_shadow = OFF
	var look := printed.material_override as StandardMaterial3D
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	root.add_child(printed)
	_prints.append(look)
	return root


# --- Building: the castle and the Emperor --------------------------------------------------

func _build_castle() -> void:
	var hinge := Node3D.new()
	hinge.position = Vector3(3.6, 0.0, -4.4)
	_world.add_child(hinge)
	var b := _paper()
	# Its hill, with stone walls stepping up.
	b.color = Color(0.4, 0.47, 0.42)
	var hill := PackedVector2Array([Vector2(-3.2, 0.0)])
	for k in 11:
		var t := k / 10.0
		hill.append(Vector2(lerpf(-3.2, 3.2, t), 1.25 * pow(sin(PI * t), 0.55)))
	hill.append(Vector2(3.2, 0.0))
	b.torn_sheet(hill, 0.0, Color(0.6, 0.66, 0.6), 0.04)
	b.color = Color(0.55, 0.55, 0.6)
	b.polygon(PackedVector2Array([Vector2(-1.5, 0.9), Vector2(1.5, 0.9), Vector2(1.25, 1.55), Vector2(-1.25, 1.55)]), 0.02)
	b.color = Color(0.45, 0.45, 0.5)
	for course: float in [1.1, 1.3]:
		b.stroke(Vector2(-1.4 + (course - 0.9) * 0.4, course), Vector2(1.4 - (course - 0.9) * 0.4, course), 0.025, 0.025, 0.025)
	# Three storeys stepping inward: white walls, dark roofs curling up at the
	# corners, a gold ornament on top.
	var y := 1.55
	var half := 1.05
	var windows := _paper()
	windows.color = Color(1.0, 0.82, 0.52)
	for storey in 3:
		var wall := 0.55 - storey * 0.08
		b.color = Color(0.95, 0.93, 0.88)
		b.rect(Vector2(0.0, y + wall * 0.5), Vector2(half * 2.0, wall), 0.03)
		b.color = Color(0.25, 0.2, 0.18)
		b.rect(Vector2(0.0, y + wall * 0.15), Vector2(half * 2.0, wall * 0.3), 0.04)
		var count := 4 - storey
		for k in count:
			windows.rect(Vector2(lerpf(-half * 0.6, half * 0.6, (k + 0.5) / count), y + wall * 0.62), Vector2(0.13, 0.15), 0.05)
		y += wall
		b.color = Color(0.17, 0.2, 0.32)
		b.polygon(PackedVector2Array([Vector2(-half - 0.5, y + 0.14), Vector2(-half - 0.25, y - 0.02), Vector2(half + 0.25, y - 0.02),
				Vector2(half + 0.5, y + 0.14), Vector2(half * 0.6, y + 0.28), Vector2(-half * 0.6, y + 0.28)]), 0.06)
		y += 0.26
		half *= 0.74
	b.color = Color(0.86, 0.68, 0.3)
	for side: float in [-1.0, 1.0]:
		b.stroke(Vector2(side * half * 0.5, y - 0.02), Vector2(side * half * 0.75, y + 0.2), 0.07, 0.02, 0.07)
	# The terrace the Emperor stands on: a stone ledge out from the wall.
	b.color = Color(0.6, 0.6, 0.64)
	b.box(Vector3(0.0, 1.5, 0.2), Vector3(1.3, 0.1, 0.5))
	b.color = Color(0.48, 0.48, 0.53)
	b.box(Vector3(0.0, 1.22, 0.42), Vector3(1.3, 0.48, 0.06))
	_mesh(b, hinge)
	_mesh(windows, hinge, 1.3)
	_pop(hinge, 15.6, 1.2, 33.8, 88.0, 2.8)
	# The Emperor, on the terrace in front of the lowest storey: purple court
	# robes printed with gold, a tall black hat with its ribbon standing up.
	_emperor = Node3D.new()
	_emperor.position = Vector3(0.0, 1.55, 0.22)
	hinge.add_child(_emperor)
	var e := _paper()
	var t := 0.62
	e.color = Color(0.36, 0.22, 0.44)
	e.polygon(PackedVector2Array([Vector2(-0.24, 0.0), Vector2(0.24, 0.0), Vector2(0.2, t * 0.5), Vector2(0.34, t * 0.62), Vector2(0.3, t * 0.74),
			Vector2(0.1, t * 0.8), Vector2(-0.1, t * 0.8), Vector2(-0.3, t * 0.74), Vector2(-0.34, t * 0.62), Vector2(-0.2, t * 0.5)]), 0.0)
	e.color = Color(0.86, 0.68, 0.3)
	for k in 6:
		e.ellipse(Vector2(_rng.randf_range(-0.16, 0.16), _rng.randf_range(0.06, t * 0.45)), Vector2(0.025, 0.025), 6, 0.01)
	e.stroke(Vector2(0.0, t * 0.3), Vector2(0.02, t * 0.68), 0.03, 0.025, 0.012)   # the baton held before him
	e.color = Color(0.95, 0.9, 0.84)
	e.ellipse(Vector2(0.0, t * 0.88), Vector2(0.08, 0.09), 14, 0.01)
	e.color = Color(0.06, 0.05, 0.07)
	e.rect(Vector2(0.0, t * 1.0), Vector2(0.15, 0.1), 0.015)
	e.stroke(Vector2(0.0, t * 1.02), Vector2(0.03, t * 1.32), 0.035, 0.02, 0.012)
	_mesh(e, _emperor)
	# He unfolds up out of the terrace, slowly enough to see, while the
	# camera is on him.
	_pop(_emperor, 18.8, 1.6, -1.0, 88.0, 2.2, true, false, true)
	_emperor_tears = CPUParticles3D.new()
	_emperor_tears.amount = 6
	_emperor_tears.lifetime = 0.8
	_emperor_tears.emitting = false
	_emperor_tears.direction = Vector3(0.0, -1.0, 0.2)
	_emperor_tears.initial_velocity_min = 0.2
	_emperor_tears.initial_velocity_max = 0.4
	_emperor_tears.gravity = Vector3(0.0, -2.0, 0.0)
	var drop := QuadMesh.new()
	drop.size = Vector2(0.03, 0.03)
	drop.material = PaperMesh.soft_ink(Color(0.15, 0.15, 0.25, 0.9))
	_emperor_tears.mesh = drop
	_emperor_tears.position = Vector3(0.0, t * 0.85, 0.1)
	_emperor.add_child(_emperor_tears)
	# The sun climbs up the sky page behind the castle.
	_sun.position = Vector3(3.2, -2.2, 0.0)


# --- Building: cranes -------------------------------------------------------------------

func _build_cranes() -> void:
	var colours := [Color(0.96, 0.93, 0.88), Color(0.86, 0.38, 0.32), Color(0.92, 0.74, 0.4), Color(0.4, 0.48, 0.7),
			Color(0.96, 0.93, 0.88), Color(0.9, 0.6, 0.62)]
	for i in colours.size():
		var crane := Node3D.new()
		_world.add_child(crane)
		var body := _paper()
		body.color = colours[i]
		body.tri(Vector3(-0.22, 0.0, 0.0), Vector3(0.0, 0.08, 0.0), Vector3(0.22, 0.0, 0.0), Vector3.BACK)
		body.tri(Vector3(-0.22, 0.0, 0.0), Vector3(0.0, -0.06, 0.03), Vector3(0.22, 0.0, 0.0), Vector3.BACK)
		body.tri(Vector3(0.18, 0.0, 0.0), Vector3(0.34, 0.2, 0.0), Vector3(0.22, 0.02, 0.02), Vector3.BACK)   # neck
		body.tri(Vector3(0.34, 0.2, 0.0), Vector3(0.4, 0.17, 0.0), Vector3(0.33, 0.18, 0.02), Vector3.BACK)   # head
		body.tri(Vector3(-0.18, 0.0, 0.0), Vector3(-0.34, 0.18, 0.0), Vector3(-0.22, 0.02, 0.02), Vector3.BACK)   # tail
		_mesh(body, crane)
		var wings: Array[Node3D] = []
		for side: float in [-1.0, 1.0]:
			var wing := Node3D.new()
			wing.position = Vector3(0.0, 0.04, 0.0)
			crane.add_child(wing)
			var w := _paper()
			w.color = colours[i]
			w.tri(Vector3(-0.1, 0.0, 0.0), Vector3(0.1, 0.0, 0.0), Vector3(-0.02, 0.0, side * 0.32), Vector3.UP)
			_mesh(w, wing)
			wings.append(wing)
		_cranes.append({
			"node": crane, "wings": wings,
			"rest": Vector3(_rng.randf_range(-6.0, 5.0), 0.02, _rng.randf_range(-1.0, 3.0)),
			"t0": 14.5 + i * 0.22, "fly": 15.6 + i * 0.3,
			"centre": Vector3(_rng.randf_range(-2.5, 2.0), 0.0, _rng.randf_range(-2.4, -0.8)),
			"radius": _rng.randf_range(2.6, 4.6), "height": _rng.randf_range(2.4, 3.8),
			"speed": _rng.randf_range(0.35, 0.55) * (1.0 if i % 2 == 0 else -1.0), "phase": _rng.randf() * TAU,
			"fall": 25.3 + i * 0.35,
		})


# --- The cut-away under the page ----------------------------------------------------------

## The ground beneath the page, cut away at its front edge like a diorama's
## base: torn layers of earth, and the well's shaft going down through them
## to a small white figure curled at the bottom. The end of the prologue
## cranes down to it, and the game opens on the same view.
func _build_cutaway() -> void:
	var front := Node3D.new()
	front.position = Vector3(0.0, 0.0, FRONT)
	_world.add_child(front)
	var b := PaperMesh.new(7)
	b.shade_jitter = 0.05
	b.texture_world = false
	b.texture_scale = 0.25
	var shaft_left := WELL_AT.x - 0.27
	var shaft_right := WELL_AT.x + 0.27
	var shades := [Color(0.4, 0.34, 0.38), Color(0.32, 0.28, 0.34), Color(0.44, 0.37, 0.39), Color(0.28, 0.25, 0.32), Color(0.37, 0.33, 0.39)]
	var top := 0.0
	var layer := 0
	while top > -7.0:
		var thick := _rng.randf_range(0.5, 1.1)
		b.color = shades[layer % shades.size()]
		for side in [[-16.0, shaft_left], [shaft_right, 16.0]]:
			var x0: float = side[0]
			var x1: float = side[1]
			var band := PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, top - thick - 0.1), Vector2(x0, top - thick - 0.1)])
			if top - thick < SHAFT_BOTTOM:   # below the shaft the layer runs right across
				band = PackedVector2Array([Vector2(-16.0, top), Vector2(16.0, top), Vector2(16.0, top - thick - 0.1), Vector2(-16.0, top - thick - 0.1)])
			b.torn_sheet(PaperMesh.tear(band, 0.35, 0.05, _rng), 0.0 + layer * 0.001, (b.color as Color).lightened(0.15), 0.02)
			if top - thick < SHAFT_BOTTOM:
				break
		# Stones in the layer.
		for i in 14:
			var at := Vector2(_rng.randf_range(-15.0, 15.0), top - _rng.randf_range(0.1, thick))
			if absf(at.x - WELL_AT.x) < 0.45 and at.y > SHAFT_BOTTOM:
				continue
			var r := _rng.randf_range(0.06, 0.18)
			b.color = Color(0.45, 0.43, 0.48).darkened(_rng.randf() * 0.35)
			var stone := PackedVector2Array()
			for k in 7:
				var a := TAU * k / 7.0
				stone.append(at + Vector2(cos(a) * r, sin(a) * r * 0.7) * _rng.randf_range(0.8, 1.15))
			b.polygon(stone, 0.01)
		top -= thick
		layer += 1
	var earth := b.build(Color.WHITE, 0.0, true)
	earth.cast_shadow = OFF
	front.add_child(earth)
	# Inside the shaft: its back wall of stones, faintly lit from above.
	var wall := PaperMesh.new(8)
	wall.shade_jitter = 0.15
	wall.texture_scale = 0.0
	var y := 0.0
	var row := 0
	while y > SHAFT_BOTTOM:
		var tall := _rng.randf_range(0.14, 0.2)
		var x := shaft_left - (0.08 if row % 2 == 0 else 0.0)
		while x < shaft_right:
			var wide := _rng.randf_range(0.16, 0.26)
			wall.color = Color(0.3, 0.32, 0.4).lerp(Color(0.1, 0.1, 0.14), clampf(y / SHAFT_BOTTOM, 0.0, 1.0))
			wall.rect(Vector2(x + wide * 0.5, y - tall * 0.5), Vector2(wide - 0.02, tall - 0.02), -0.3)
			x += wide
		y -= tall
		row += 1
	wall.color = Color(0.03, 0.03, 0.05)
	wall.rect(Vector2(WELL_AT.x, SHAFT_BOTTOM * 0.5), Vector2(0.6, -SHAFT_BOTTOM), -0.31)
	var back := wall.build(Color.WHITE, 0.0, true)
	back.cast_shadow = OFF
	front.add_child(back)
	var light := PaperMesh.new(9)
	light.fade_quad(Vector3(shaft_left, SHAFT_BOTTOM, -0.25), Vector3(shaft_right, SHAFT_BOTTOM, -0.25), Vector3(shaft_right, 0.0, -0.25),
			Vector3(shaft_left, 0.0, -0.25), Color(0.7, 0.76, 1.0, 0.05), Color(0.75, 0.8, 1.0, 0.35))
	front.add_child(light.build_veil(true))
	# The figure at the bottom: blank white paper, curled up, the wide hat
	# hiding his face, his sword along his back. The only white thing here.
	var figure := PaperMesh.new(10)
	figure.shade_jitter = 0.0
	figure.texture_scale = 0.0
	var u := 0.13
	var feet := Vector2(WELL_AT.x, SHAFT_BOTTOM)
	figure.color = Color(0.82, 0.8, 0.76)
	figure.stroke(feet + Vector2(-0.2, 0.8) * u, feet + Vector2(-1.7, 0.25) * u, u * 0.1, u * 0.1, -0.12)   # the katana
	figure.color = Color(0.93, 0.91, 0.86)
	var shape := [[-0.7, 0.0], [-0.78, 0.35], [-0.72, 0.8], [-0.55, 1.12], [-0.7, 1.16], [-1.25, 1.22], [-0.05, 1.95], [1.1, 1.24],
			[0.62, 1.17], [0.5, 1.05], [0.62, 0.98], [0.95, 0.78], [1.0, 0.62], [0.82, 0.52], [0.9, 0.2], [1.12, 0.04], [1.15, 0.0]]
	var outline := PackedVector2Array()
	for p: Array in shape:
		outline.append(feet + Vector2(float(p[0]), float(p[1])) * u)
	figure.polygon(outline, -0.1)
	var shape_mesh := figure.build(Color.WHITE, 0.0, true)
	shape_mesh.cast_shadow = OFF
	front.add_child(shape_mesh)
	var glow := Scenery.halo(0.4, Color(0.9, 0.92, 1.0, 0.3))
	glow.position = Vector3(feet.x, feet.y + 0.1, -0.08)
	front.add_child(glow)


# --- The Rain --------------------------------------------------------------------------

func _build_rain() -> void:
	_rain = CPUParticles3D.new()
	_rain.amount = 1600
	_rain.lifetime = 0.9
	_rain.emitting = false
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(14.0, 0.5, 9.0)
	_rain.direction = Vector3(-0.12, -1.0, 0.05)
	_rain.spread = 2.0
	_rain.gravity = Vector3.ZERO
	_rain.initial_velocity_min = 13.0
	_rain.initial_velocity_max = 16.0
	var streak := QuadMesh.new()
	streak.size = Vector2(0.012, 0.5)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.8, 0.86, 1.0, 0.4)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	look.billboard_keep_scale = true
	streak.material = look
	_rain.mesh = streak
	_rain.cast_shadow = OFF
	_rain.position = Vector3(0.0, 11.0, -1.0)
	add_child(_rain)


## A pool of ink spreading on the wet page under something.
func _pool(at: Vector3, size: float, t0: float) -> void:
	var b := PaperMesh.new(1)
	var ring := 18
	for k in ring:
		var a0 := TAU * k / ring
		var a1 := TAU * (k + 1) / ring
		var r0 := _rng.randf_range(0.8, 1.15)
		var r1 := _rng.randf_range(0.8, 1.15)
		b.fade_quad(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(cos(a1) * r1, 0.0, sin(a1) * r1 * 0.8),
				Vector3(cos(a0) * r0, 0.0, sin(a0) * r0 * 0.8), Color(0.04, 0.04, 0.07, 0.8), Color(0.04, 0.04, 0.07, 0.0))
	var pool := b.build_veil()
	pool.position = at + Vector3(0.0, 0.012, 0.0)
	_world.add_child(pool)
	_pools.append({"node": pool, "t0": t0, "size": size})


## Every paper material, so the Rain can soak them, and the glowing ones,
## so their light can die. (Veils, halos and pools are left as they are.)
func _collect_materials() -> void:
	for node: Node in _world.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var look := mesh.material_override as StandardMaterial3D
		if look == null or look.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and look.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			continue
		if _prints.has(look):
			continue
		_soak.append({"mat": look, "delay": _rng.randf_range(0.0, 3.0) + clampf(-mesh.global_position.z * 0.12, -0.5, 1.0)})
		if look.emission_enabled:
			_glows.append({"mat": look, "energy": look.emission_energy_multiplier})


# --- Pop-ups -------------------------------------------------------------------------

## A piece that folds up off the page at `t0`, taking `dur` (with a little
## spring), and (if `fall` >= 0) goes limp and falls at `fall`, over
## `fall_dur`, to `angle` degrees (positive: toward the camera).
## `rise`: it unfolds upward out of the floor instead of tipping up.
## `squash`: instead of tipping over, it is crushed down flat onto the page
## (for solid things like houses: tipped over, half of one would hang in
## the air).
func _pop(node: Node3D, t0: float, dur: float = 0.75, fall: float = -1.0, angle: float = 88.0, fall_dur: float = 2.2,
		sound: bool = true, squash: bool = false, rise: bool = false) -> void:
	node.set_meta(&"rest_rotation", node.rotation)
	_pops.append({"node": node, "t0": t0, "dur": dur, "fall": fall, "angle": deg_to_rad(angle), "fall_dur": fall_dur, "sound": sound,
			"squash": squash, "rise": rise})


func _apply_pops() -> void:
	for pop: Dictionary in _pops:
		var node: Node3D = pop["node"]
		var t0: float = pop["t0"]
		var rest: Vector3 = node.get_meta(&"rest_rotation")
		if time < t0:
			node.visible = false
			continue
		node.visible = true
		var u := clampf((time - t0) / float(pop["dur"]), 0.0, 1.0)
		# Ease out with a spring: it overshoots a hair and settles, as a
		# pop-up does when the page opens.
		var c1 := 1.4
		var spring := 1.0 + (c1 + 1.0) * pow(u - 1.0, 3.0) + c1 * pow(u - 1.0, 2.0)
		var angle := (PI * 0.49) * (1.0 - spring)
		var grow := 1.0
		if pop["rise"]:
			# Unfolding upward out of the floor, like paper pulled up from a
			# fold, instead of tipping up.
			grow = maxf(spring, 0.02)
			angle = 0.0
		var fall: float = pop["fall"]
		var flat := 1.0
		if fall >= 0.0 and time > fall:
			var v := clampf((time - fall) / float(pop["fall_dur"]), 0.0, 1.0)
			# Soggy: slow to start, then it gives way, with a last sag.
			var limp := v * v * (3.0 - 2.0 * v)
			if pop["squash"]:
				flat = lerpf(1.0, 0.05, limp)
				angle += 0.08 * sin(v * PI)
			else:
				angle += float(pop["angle"]) * limp + sin(v * PI) * 0.04 * (1.0 - v)
		node.rotation = Vector3(rest.x + angle, rest.y, rest.z)
		node.scale = Vector3(1.0 + (1.0 - flat) * 0.15, flat * grow, 1.0 + (1.0 - flat) * 0.15)


# --- Everything, from the clock -------------------------------------------------------------

func _apply() -> void:
	_apply_camera()
	_apply_pops()
	# The blank sheet: creases draw themselves across it, then it fades as
	# the sky washes in behind.
	var cover := 1.0 - _span(8.6, 11.6)
	(_blank.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, cover)
	_blank.visible = cover > 0.0
	_candle.light_energy = 3.0 * _span(0.2, 2.8) * (0.85 + 0.15 * sin(time * 5.3) * sin(time * 2.1)) * cover
	for crease: Dictionary in _creases:
		var node: MeshInstance3D = crease["node"]
		var t0: float = crease["t0"]
		node.scale.x = clampf((time - t0) / 0.6, 0.001, 1.0)
		node.visible = time > t0 and cover > 0.0
		(node.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, cover)
	# The river unrolls.
	for piece: Dictionary in _river:
		var node: Node3D = piece["node"]
		node.visible = time > float(piece["t0"])
	# The sun climbs the sky, and sinks again in the Rain.
	_sun.position.y = lerpf(-2.2, 4.9, _span(17.5, 21.0)) - _span(27.0, 35.0) * 1.6
	_apply_cranes()
	# The Emperor bows his head, and something falls from his face.
	_emperor.rotation.x = 0.42 * _span(26.6, 28.4)
	_emperor_tears.emitting = playing and time > 26.8 and time < 31.0
	# The Rain: light goes cold, lightning, the paper soaks.
	var storm := _span(24.9, 26.2)
	var dark := _span(35.0, 40.0)
	_lamp.light_color = WARM_LIGHT.lerp(COLD_LIGHT, storm)
	_lamp.light_energy = lerpf(1.7, 0.95, storm) * (1.0 - dark * 0.7) * _span(0.0, 2.5)
	_env.ambient_light_color = Color(0.42, 0.36, 0.36).lerp(Color(0.3, 0.31, 0.36), storm)
	_env.ambient_light_energy = 0.55 * (1.0 - dark * 0.6)
	# The colour drains out of the world as the storm takes it.
	_env.adjustment_saturation = lerpf(0.95, 0.5, _span(25.5, 31.0))
	_env.adjustment_brightness = lerpf(1.0, 0.9, _span(26.0, 33.0))
	var flash := 0.0
	for strike: float in [25.0, 27.9]:
		if time >= strike:
			flash = maxf(flash, clampf(1.0 - (time - strike) / 0.35, 0.0, 1.0) * (1.0 if strike == 25.0 else 0.6))
	_flash.light_energy = flash * 2.0
	_well_light.light_energy = 1.4 * _span(33.0, 37.0)
	_rain.emitting = playing and time > 25.0
	for item: Dictionary in _soak:
		var look: StandardMaterial3D = item["mat"]
		var wet := clampf((time - 25.6 - float(item["delay"])) / 3.0, 0.0, 1.0)
		look.albedo_color = Color.WHITE.lerp(WET, wet * wet * (3.0 - 2.0 * wet))
	var gutter := _span(26.0, 29.0)
	var flicker := 1.0 - 0.3 * absf(sin(time * 23.0)) * gutter
	for glow: Dictionary in _glows:
		var look: StandardMaterial3D = glow["mat"]
		look.emission_energy_multiplier = float(glow["energy"]) * (1.0 - gutter) * flicker
	for lamp: Dictionary in _lamps:
		(lamp["light"] as OmniLight3D).light_energy = float(lamp["energy"]) * (1.0 - gutter) * flicker
	for pool: Dictionary in _pools:
		var node: Node3D = pool["node"]
		var grow := clampf((time - float(pool["t0"])) / 4.0, 0.0, 1.0)
		node.visible = grow > 0.0
		node.scale = Vector3.ONE * maxf(float(pool["size"]) * sqrt(grow), 0.001)
	for look: StandardMaterial3D in _prints:
		var c := look.albedo_color
		look.albedo_color = Color(c.r, c.g, c.b, 1.0 - _span(26.6, 29.2))
	_overlay.queue_redraw()


func _apply_cranes() -> void:
	for crane: Dictionary in _cranes:
		var node: Node3D = crane["node"]
		var t0: float = crane["t0"]
		node.visible = time > t0
		if time < t0:
			continue
		var rest: Vector3 = crane["rest"]
		var fly: float = crane["fly"]
		var fall: float = crane["fall"]
		var wings: Array[Node3D] = crane["wings"]
		var flap := 0.0
		if time < fly:
			# Folding itself up on the page: rising from flat.
			node.position = rest
			node.rotation = Vector3(PI * 0.5 * (1.0 - clampf((time - t0) / 0.5, 0.0, 1.0)), 0.0, 0.0)
			flap = 0.6 * clampf((time - t0) / 0.8, 0.0, 1.0)
		else:
			var now := minf(time, fall)
			var flight := _flight(crane, now)
			var lift: float = clampf((now - fly) / 1.5, 0.0, 1.0)
			var pos: Vector3 = rest.lerp(flight, lift * lift * (3.0 - 2.0 * lift))
			var ahead: Vector3 = _flight(crane, now + 0.05)
			flap = sin(time * 10.0 + float(crane["phase"])) * 0.7
			var fallen := false
			if time > fall:
				# Beaten down by the Rain: it tumbles onto the wet page and lies there.
				var drop := time - fall
				pos.y = maxf(pos.y - 4.5 * drop * drop, 0.03)
				fallen = pos.y <= 0.05
				flap = -0.05 if fallen else 0.15 * sin(drop * 3.0)
			node.position = pos
			var heading := atan2(-(ahead.z - pos.z), ahead.x - pos.x)
			if fallen:
				node.rotation = Vector3(0.0, heading, 0.25)
			else:
				node.rotation = Vector3(0.0, heading, 0.15 if time < fall else 0.6 * (time - fall))
		for k in wings.size():
			wings[k].rotation.x = flap * (1.0 if k == 0 else -1.0)


func _flight(crane: Dictionary, at_time: float) -> Vector3:
	var fly: float = crane["fly"]
	var angle: float = float(crane["phase"]) + (at_time - fly) * float(crane["speed"])
	var centre: Vector3 = crane["centre"]
	var radius: float = crane["radius"]
	var height: float = float(crane["height"]) + 0.3 * sin(at_time * 0.9 + float(crane["phase"]))
	return centre + Vector3(cos(angle) * radius, height, sin(angle) * radius * 0.4)


# --- The overlay: letterbox, lines, skip, black ---------------------------------------------

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var grain := ColorRect.new()
	var look := ShaderMaterial.new()
	look.shader = load("res://shaders/paper_grain.gdshader")
	look.set_shader_parameter(&"vignette_strength", 0.55)
	look.set_shader_parameter(&"grain_strength", 0.12)
	grain.material = look
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(grain)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	layer.add_child(_overlay)
	var skip := SkipPrompt.new()
	skip.hold_time = skip_hold
	skip.skipped.connect(_finish)
	layer.add_child(skip)


func _draw_overlay() -> void:
	var c := _overlay
	var view := c.size
	# Letterbox bars, sliding in at the start.
	var bar := view.y * 0.1 * _span(0.0, 1.6)
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(view.x, bar)), Color(0, 0, 0))
	c.draw_rect(Rect2(Vector2(0, view.y - bar), Vector2(view.x, bar)), Color(0, 0, 0))
	# Black at the start and the end.
	var black := 1.0 - _span(0.3, 3.0) + _span(41.8, 44.0)
	if black > 0.0:
		c.draw_rect(Rect2(Vector2.ZERO, view), Color(0.0, 0.0, 0.0, clampf(black, 0.0, 1.0)))
	# The lines: each letter inks in from the left, the line fades at its end.
	var font_size := int(view.y * 0.04)
	for line: Array in LINES:
		var start: float = line[0]
		var stop: float = line[1]
		if time < start or time > stop + 0.8:
			continue
		var words: String = line[2]
		var spacing := font_size * 0.05
		var x := (view.x - UiStyle.width(words, font_size, spacing)) * 0.5
		var y := view.y * 0.955
		var out := 1.0 - clampf((time - stop) / 0.8, 0.0, 1.0)
		var letters := words.length()
		var ink_time := minf(2.2, (stop - start) * 0.45)
		for i in letters:
			var own := clampf((time - start - ink_time * i / letters) / 0.35, 0.0, 1.0) * out
			if own > 0.0:
				UiStyle.text(c, Vector2(x, y + (1.0 - own) * font_size * 0.05), words[i], font_size,
						Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, own), 0.0, 0.6)
			x += UiStyle.width(words[i], font_size) + spacing


# --- Frame sheet ---------------------------------------------------------------------

## Draws the prologue at a row of moments and tiles them into one picture.
func _frame_sheet(path: String) -> void:
	var moments := [3.0, 8.4, 10.2, 12.0, 13.6, 15.4, 18.5, 20.6, 23.0, 25.1, 27.0, 29.0, 30.8, 32.2, 34.5, 38.0]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--prologue-moments="):
			moments = []
			for part: String in arg.trim_prefix("--prologue-moments=").split(","):
				moments.append(float(part))
	var tiles: Array[Image] = []
	for moment: float in moments:
		time = moment
		_apply()
		_rain.emitting = moment > 25.0
		if moment > 25.0:
			_rain.preprocess = 0.9
			_rain.restart()
		for k in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.resize(480, 270)
		tiles.append(image)
	var columns := 4
	var rows := ceili(tiles.size() / float(columns))
	var sheet := Image.create(480 * columns, 270 * rows, false, tiles[0].get_format())
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, 480, 270), Vector2i((i % columns) * 480, (i / columns) * 270))
	sheet.save_png(path)
	print("prologue sheet: ", moments)
	get_tree().quit()
