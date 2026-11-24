class_name HoshoHall
extends Node3D
## Hōshō's hall, through the Gilded Gate at the top of the Lantern Market,
## and his fight there (Hosho). Built in the market's coordinates, a child of
## the Gilded Terraces.
##
## The hall: open in front, its back one vast wall of shoji lit gold from
## behind, where his shadow falls (a shadow puppet, folded here, that copies
## him, many times his size); red pillars, his banners hung from the beams,
## tall lantern stands, the floor red lacquer edged in gold, burning paper
## drifting high up. No rain falls inside it.
##
## The first time he steps in (the intro, directed: CineCamera, 13 s):
## lanterns light one by one down the hall; Hōshō's shadow rises on the
## shoji, vast; he steps out of the dark, the lanterns on his shoulders
## flaring; his mask, close; he whirls the naginata and plants it; his name
## is painted (宝照); the doors slam shut behind the Ronin.
## The fight (from half health his shadow on the shoji strikes too: it
## raises its own naginata, and a wave of shadow sweeps the whole floor, high
## (duck) or low (jump)).
## After (directed, 15 s): slowed on the last cut; he sinks to one knee, and
## the gold leaf washes off him (shaders/wash_white.gdshader: plain paper
## underneath); the shoji behind him tears open and the Rain pours in on him;
## he lifts his face into it ("I can feel it. The rain."); he holds out his
## seal (宝照) and it flies to the Ronin's hand (SaveGame "hosho" seal). The
## doors open again.

const HALL := TerracesQuarter.HALL
const ARENA := Vector2(447.0, 477.0)
const HIS_X := 471.0
const SHOJI_Z := -6.0

@export var music_volume := -6.0
@export var fight_camera_distance := 16.0

var market: LanternMarket
var terraces: TerracesQuarter
var hosho: Hosho
var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _state := &"before"
var _time := 0.0
var _lights: Array[OmniLight3D] = []
var _light_energy: Array[float] = []
var _shoji: MeshInstance3D
var _wave: MeshInstance3D
var _wave_x := 0.0
var _wave_dir := 1.0
var _wave_low := true
var _wave_hit := false
var _tear: Node3D
var _hole_rain: CPUParticles3D
var _gold_shower: CPUParticles3D
var _wall: StaticBody3D
var _cine: CineCamera
var _overlay: Control
var _title: HannyaTitle
var _bar: BossBar
var _skip: SkipPrompt
var _hud: CanvasItem
var _music: AudioStreamPlayer
var _music_fade: Tween
var _camera_tween: Tween
var _rain: Node
var _in_hall := false
var _wash: ShaderMaterial
var _held := false
var _focused := false


func _ready() -> void:
	_rng.seed = 9393
	add_to_group(&"hosho_hall")
	_build_floor()
	_build_shoji()
	_build_pillars_and_roof()
	_build_end_screen()
	_build_banners_and_lanterns()
	_build_wave()
	hosho = Hosho.new()
	add_child(hosho)
	hosho.position = Vector3(HIS_X, HALL.z + 0.05, 0.0)
	hosho.facing = -1.0
	hosho.bounds = Vector2(market.global_position.x + ARENA.x + 1.0, market.global_position.x + ARENA.y - 1.0)
	hosho.floor_y = market.global_position.y + HALL.z
	hosho.defeated.connect(_on_defeated)
	hosho.wave_coming.connect(_wave_coming)
	hosho.wave_sent.connect(_wave_sent)
	hosho.roused.connect(_roused)
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_hosho_fight.ogg")
	(_music.stream as AudioStreamOggVorbis).loop = true
	add_child(_music)
	# The end wall of the market, behind the hall.
	market._solid(Vector3(HALL.y + 0.5, HALL.z + 15.0, 0.0), Vector3(1.0, 30.0, 4.0)).set_meta(&"no_climb", true)
	if SaveGame.hosho_beaten:
		_state = &"done"
		hosho.active = false
		hosho.set(&"_mode", &"defeated")
		hosho.set_kneel(1.0)
		_tear_open(false)
		_wash_gold(false)
	else:
		# Before the fight he stands in the dark at the back of the hall,
		# the lanterns down its length unlit.
		_set_hall_light(0.25 if not SaveGame.hosho_met else 1.0, false)


# --- Building it ----------------------------------------------------------------------

func _build_floor() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	var x := HALL.x
	while x < HALL.y - 0.01:
		var x1 := minf(x + _rng.randf_range(0.5, 0.8), HALL.y)
		b.color = Color(0.36, 0.1, 0.08) * _rng.randf_range(0.85, 1.1)
		b.box(Vector3((x + x1) * 0.5, HALL.z + 0.02, -1.75), Vector3(x1 - x - 0.02, 0.04, 8.5))
		x = x1
	b.color = Color(0.86, 0.68, 0.34)
	b.box(Vector3((HALL.x + HALL.y) * 0.5, HALL.z + 0.045, 2.55), Vector3(HALL.y - HALL.x, 0.02, 0.12))
	b.box(Vector3((HALL.x + HALL.y) * 0.5, HALL.z + 0.045, -5.9), Vector3(HALL.y - HALL.x, 0.02, 0.12))
	var floor := b.build()
	(floor.material_override as StandardMaterial3D).roughness = 0.25
	(floor.material_override as StandardMaterial3D).metallic_specular = 0.7
	add_child(floor)


## The back of the hall: one vast wall of shoji, lit gold from behind, in a
## dark lacquered lattice.
func _build_shoji() -> void:
	var top := HALL.z + 10.0
	var paper := PaperMesh.new(_rng.randi())
	paper.shade_jitter = 0.04
	paper.color = Color(1.0, 0.82, 0.52)
	paper.quad(Vector3(HALL.x, HALL.z, SHOJI_Z), Vector3(HALL.y, HALL.z, SHOJI_Z), Vector3(HALL.y, top, SHOJI_Z), Vector3(HALL.x, top, SHOJI_Z), Vector3.BACK)
	_shoji = paper.build(Color.WHITE, 1.1, true)
	add_child(_shoji)
	var lattice := PaperMesh.new(_rng.randi())
	lattice.color = Color(0.12, 0.05, 0.04)
	var x := HALL.x
	while x <= HALL.y + 0.01:
		lattice.box(Vector3(x, (HALL.z + top) * 0.5, SHOJI_Z + 0.06), Vector3(0.07, top - HALL.z, 0.06))
		x += 1.2
	var y := HALL.z
	while y <= top + 0.01:
		lattice.box(Vector3((HALL.x + HALL.y) * 0.5, y, SHOJI_Z + 0.06), Vector3(HALL.y - HALL.x, 0.07, 0.06))
		y += 1.6
	lattice.color = LanternMarket.LACQUER.darkened(0.25)
	lattice.box(Vector3((HALL.x + HALL.y) * 0.5, top + 0.4, SHOJI_Z + 0.1), Vector3(HALL.y - HALL.x, 0.8, 0.3))
	lattice.box(Vector3((HALL.x + HALL.y) * 0.5, HALL.z + 0.3, SHOJI_Z + 0.1), Vector3(HALL.y - HALL.x, 0.6, 0.3))
	add_child(lattice.build())


func _build_pillars_and_roof() -> void:
	var top := HALL.z + 11.0
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	for x: float in [HALL.x + 0.6, 452.0, 460.0, 468.0, HALL.y - 0.6]:
		b.color = LanternMarket.LACQUER
		b.frustum(10, Vector2(0.32, 0.32), Vector2(0.3, 0.3), top - HALL.z, Vector3(x, HALL.z, -5.3))
		b.color = Color(0.86, 0.68, 0.34)
		b.frustum(10, Vector2(0.38, 0.38), Vector2(0.38, 0.38), 0.25, Vector3(x, HALL.z, -5.3))
	# The front pillars, only at the hall's two ends (never between him and us).
	for x: float in [HALL.x + 0.6, HALL.y - 0.6]:
		b.color = LanternMarket.LACQUER
		b.frustum(10, Vector2(0.34, 0.34), Vector2(0.32, 0.32), top - HALL.z, Vector3(x, HALL.z, 2.4))
	# Beams overhead.
	b.color = LanternMarket.LACQUER.darkened(0.2)
	b.box(Vector3((HALL.x + HALL.y) * 0.5, top, -1.5), Vector3(HALL.y - HALL.x, 0.5, 8.6))
	b.box(Vector3((HALL.x + HALL.y) * 0.5, top - 0.6, 2.4), Vector3(HALL.y - HALL.x, 0.4, 0.4))
	b.box(Vector3((HALL.x + HALL.y) * 0.5, top - 0.6, -5.3), Vector3(HALL.y - HALL.x, 0.4, 0.4))
	add_child(b.build())
	add_child(Scenery.tiled_roof(_rng, HALL.x - 1.0, HALL.y + 1.0, Vector2(top + 0.3, 3.8), Vector2(top + 3.2, -1.5), 6))


## The hall's east end: closed by a great gold folding screen (byobu) in a
## black lacquer frame, six leaves zig-zagging, painted with a sun disc and
## clouds of gold leaf, on a low lacquered dais. (Open, it showed a house and
## a bare sheet beyond: unfinished.) Solid behind (the market's end wall).
func _build_end_screen() -> void:
	var top := HALL.z + 10.4
	var x := HALL.y - 0.25
	var leaves := 6
	var z0 := SHOJI_Z
	var z1 := 2.6
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.05
	var w := (z1 - z0) / leaves
	for i in leaves:
		var za := z0 + i * w
		var zb := za + w
		# The zig-zag: every other fold steps out toward the hall.
		var xa := x - (0.0 if i % 2 == 0 else 0.35)
		var xb := x - (0.35 if i % 2 == 0 else 0.0)
		b.color = Color(0.86, 0.62, 0.24) * _rng.randf_range(0.92, 1.05)
		b.quad(Vector3(xa, HALL.z + 0.5, za), Vector3(xb, HALL.z + 0.5, zb), Vector3(xb, top, zb), Vector3(xa, top, za), Vector3.LEFT)
		b.color = Color(0.08, 0.04, 0.03)
		b.box(Vector3(xa, (HALL.z + 0.5 + top) * 0.5, za), Vector3(0.09, top - HALL.z - 0.5, 0.09))
		b.box(Vector3((xa + xb) * 0.5 - 0.03, top, (za + zb) * 0.5), Vector3(0.09, 0.12, w))
		b.box(Vector3((xa + xb) * 0.5 - 0.03, HALL.z + 0.5, (za + zb) * 0.5), Vector3(0.09, 0.12, w))
	b.box(Vector3(x, (HALL.z + 0.5 + top) * 0.5, z1), Vector3(0.09, top - HALL.z - 0.5, 0.09))
	# The dais it stands on.
	b.color = LanternMarket.LACQUER.darkened(0.3)
	b.box(Vector3(x - 0.2, HALL.z + 0.25, (z0 + z1) * 0.5), Vector3(0.9, 0.5, z1 - z0 + 0.2))
	b.color = Color(0.86, 0.68, 0.34)
	b.box(Vector3(x - 0.66, HALL.z + 0.48, (z0 + z1) * 0.5), Vector3(0.04, 0.04, z1 - z0 + 0.2))
	# Painted on it: a vermilion sun and drifting gold-leaf clouds, darker.
	var screen := b.build()
	(screen.material_override as StandardMaterial3D).metallic = 0.1
	(screen.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	(screen.material_override as StandardMaterial3D).roughness = 0.4
	add_child(screen)
	# The sun and the clouds, as flat shapes laid on the leaves.
	var paint := PaperMesh.new(_rng.randi())
	paint.texture_world = false
	paint.color = Color(0.7, 0.18, 0.1)
	paint.ellipse(Vector2.ZERO, Vector2(1.2, 1.2), 28, 0.0)
	paint.color = Color(0.78, 0.56, 0.24)
	for c: Array in [[Vector2(-2.6, -1.6), Vector2(2.2, 0.35)], [Vector2(1.8, -2.4), Vector2(2.6, 0.4)], [Vector2(-1.2, 1.9), Vector2(2.0, 0.3)], [Vector2(2.4, 1.2), Vector2(1.6, 0.28)]]:
		paint.ellipse(c[0], c[1], 18, 0.01)
	var art := paint.build()
	art.rotation.y = -PI * 0.5
	art.position = Vector3(x - 0.42, HALL.z + 6.2, -1.7)
	add_child(art)


func _build_banners_and_lanterns() -> void:
	for x: float in [455.0, 464.0]:
		var banner := Node3D.new()
		banner.position = Vector3(x, HALL.z + 10.4, -4.8)
		add_child(banner)
		var c := PaperMesh.new(_rng.randi())
		c.color = LanternMarket.RED_CLOTH
		c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.9, 0.0), Vector2(0.9, 0.0), Vector2(0.9, -5.5), Vector2(0.0, -5.0), Vector2(-0.9, -5.5)]), 0.35, 0.05, _rng), 0.0)
		c.color = Color(0.86, 0.68, 0.34)
		c.ellipse(Vector2(0.0, -1.5), Vector2(0.65, 0.65), 20, 0.005)
		c.color = LanternMarket.RED_CLOTH
		for p in 5:
			var a := TAU * p / 5.0 + PI * 0.5
			c.ellipse(Vector2(0.0, -1.5) + Vector2(cos(a), sin(a)) * 0.26, Vector2(0.18, 0.18), 8, 0.008)
		banner.add_child(c.build())
		Scenery.windswept(banner, 0.02, _rng)
	for x: float in [449.0, 456.5, 463.5, 474.5]:
		var stand := PaperMesh.new(_rng.randi())
		stand.color = PaperMesh.TIMBER
		stand.box(Vector3(x, HALL.z + 1.6, -3.6), Vector3(0.14, 3.2, 0.14))
		stand.box(Vector3(x, HALL.z + 0.08, -3.6), Vector3(0.6, 0.16, 0.6))
		stand.color = Color(0.86, 0.68, 0.34)
		stand.box(Vector3(x, HALL.z + 3.25, -3.6), Vector3(0.5, 0.06, 0.5))
		add_child(stand.build())
		market._hang(Vector3(x, HALL.z + 3.22, -3.6), 1.3, 0.05)
		var light := market._light(Vector3(x, HALL.z + 3.0, -2.6), market.village.lantern_energy, market.village.lantern_range * 1.2)
		_lights.append(light)
		_light_energy.append(light.light_energy)
	# Burning paper drifting high in the hall (as in his picture).
	var embers := CPUParticles3D.new()
	embers.amount = 26
	embers.lifetime = 6.0
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3((HALL.y - HALL.x) * 0.5, 2.0, 2.0)
	embers.direction = Vector3.UP
	embers.spread = 40.0
	embers.gravity = Vector3(-0.2, 0.15, 0.0)
	embers.initial_velocity_min = 0.2
	embers.initial_velocity_max = 0.5
	var mote := QuadMesh.new()
	mote.size = Vector2(0.12, 0.12)
	mote.material = WaterFx.bead_material(Color(1.0, 0.6, 0.25))
	embers.mesh = mote
	embers.position = Vector3((HALL.x + HALL.y) * 0.5, HALL.z + 7.0, -3.0)
	add_child(embers)


## The wave of shadow his shadow's naginata sends across the floor: the
## shadow blade itself come off the paper, a tall crescent of sumi (the
## swoosh shader, dark), shedding ink as it goes. Its body is one unit tall
## (scaled to the band it sweeps).
func _build_wave() -> void:
	var strip := SurfaceTool.new()
	strip.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 16
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var y := t - 0.5
			var bow := 0.55 * (1.0 - 4.0 * y * y)
			var x := bow + lerpf(-0.9, 0.0, corner[1]) * (0.35 + 0.65 * (1.0 - 4.0 * y * y))
			strip.set_uv(Vector2(t, corner[1]))
			strip.add_vertex(Vector3(x, y, 0.0))
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/slash_sweep.gdshader")
	look.set_shader_parameter(&"head", 1.05)
	look.set_shader_parameter(&"tail", -0.1)
	look.set_shader_parameter(&"tint", Color(1.0, 0.8, 0.42, 0.95))
	_wave = MeshInstance3D.new()
	_wave.mesh = strip.commit()
	_wave.material_override = look
	_wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wave.visible = false
	add_child(_wave)
	var drops := CPUParticles3D.new()
	drops.amount = 50
	drops.lifetime = 0.7
	drops.local_coords = false
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drops.emission_box_extents = Vector3(0.2, 0.5, 0.3)
	drops.gravity = Vector3(0.0, -6.0, 0.0)
	drops.spread = 60.0
	drops.initial_velocity_min = 0.5
	drops.initial_velocity_max = 2.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.1))
	drops.scale_amount_curve = shrink
	var bead := QuadMesh.new()
	bead.size = Vector2(0.08, 0.06)
	var gilt := StandardMaterial3D.new()
	gilt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gilt.albedo_color = Color(1.0, 0.84, 0.48)
	gilt.cull_mode = BaseMaterial3D.CULL_DISABLED
	gilt.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	bead.material = gilt
	drops.mesh = bead
	drops.angular_velocity_min = -500.0
	drops.angular_velocity_max = 500.0
	drops.name = "Drops"
	_wave.add_child(drops)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.42)
	light.light_energy = 2.5
	light.omni_range = 4.5
	_wave.add_child(light)


# --- Every frame ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
		_ronin.died.connect(_on_ronin_died)
		if _rain == null:
			_rain = get_tree().root.find_child("Rain", true, false)
	var x := _ronin.global_position.x - market.global_position.x
	var y := _ronin.global_position.y - market.global_position.y
	# No rain inside the hall.
	var inside := x > HALL.x + 0.5 and x < HALL.y and y > HALL.z - 1.0
	if inside != _in_hall:
		_in_hall = inside
		if _rain and _rain.has_method("ease_off"):
			_rain.ease_off(0.0 if inside else 1.0, 1.2)
	_update_wave(delta)
	var camera := get_viewport().get_camera_3d() as FollowCamera
	if camera:
		if _state == &"fight":
			camera.focus = hosho.global_position + Vector3(0.0, 2.0, 0.0)
			_focused = true
		elif _focused:
			camera.focus = Vector3(NAN, NAN, NAN)
			_focused = false
	match _state:
		&"before":
			if x > ARENA.x + 1.5 and inside and _ronin.is_on_floor() and _ronin.is_physics_processing():
				if SaveGame.hosho_met:
					_start_fight()
				else:
					_start_intro()
		&"intro":
			var puppet: RoninPuppet = _ronin.get_node("Puppet")
			puppet.facing = 1.0
			_ronin.facing = 1.0
		&"after":
			if not _held and _ronin.is_on_floor():
				_held = true
				_ronin.set_physics_process(false)
				_ronin.velocity = Vector3.ZERO
				(_ronin.get_node("Puppet") as RoninPuppet).state = &"idle"


## From half health: he raises the naginata, the hall's lanterns gutter
## and gold gathers on the blade (Hosho's tell)...
func _wave_coming(_low: bool) -> void:
	_set_hall_light(0.45, true)


## ...then he sweeps, and a crescent of molten gold rolls along the floor
## from his blade, low (jump it) or high (duck it).
func _wave_sent(low: bool) -> void:
	_wave_low = low
	_wave_dir = hosho.facing
	_wave_x = hosho.position.x + _wave_dir * 1.2
	_wave_hit = false
	_wave.visible = true
	Sound.play(self, &"fire_whoosh", 4.0)
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(_set_hall_light.bind(1.0, true))


## His second wind: the naginata's butt strikes the floor, every lantern in
## the hall flares and settles, the banners lift.
func _roused() -> void:
	for i in _lights.size():
		var t := create_tween()
		t.tween_property(_lights[i], "light_energy", _light_energy[i] * 2.6, 0.08)
		t.tween_property(_lights[i], "light_energy", _light_energy[i], 1.4).set_trans(Tween.TRANS_SINE)
	Wind.puff(market.global_position.x + hosho.position.x, 1.0)
	Wind.puff(market.global_position.x + hosho.position.x, -1.0)
	Sound.play(self, &"fire_whoosh", 2.0)


func _update_wave(delta: float) -> void:
	if not _wave.visible:
		return
	_wave_x += _wave_dir * 16.0 * delta
	var band := Vector2(0.0, 0.85) if _wave_low else Vector2(1.15, 2.6)
	_wave.position = Vector3(_wave_x, HALL.z + (band.x + band.y) * 0.5, 0.2)
	_wave.scale = Vector3(_wave_dir * 1.4, (band.y - band.x) * 1.25, 1.0)
	(_wave.get_node("Drops") as CPUParticles3D).emitting = true
	if not _wave_hit and _ronin:
		var r := _ronin.global_position - market.global_position
		var hit_low := _wave_low and r.y - HALL.z < 0.8
		var hit_high: bool = not _wave_low and r.y - HALL.z < 2.5 and not _ronin.get(&"_ducking")
		if absf(r.x - _wave_x) < 1.2 and (hit_low or hit_high):
			_wave_hit = true
			_ronin.take_damage(1, Vector3(_wave_x, HALL.z + 1.0, 0.0) + market.global_position, &"ink")
	if _wave_x < ARENA.x - 1.0 or _wave_x > ARENA.y + 1.0:
		_wave.visible = false


func _set_hall_light(level: float, slow: bool) -> void:
	for i in _lights.size():
		if slow:
			var t := create_tween()
			t.tween_property(_lights[i], "light_energy", _light_energy[i] * level, 0.6)
		else:
			_lights[i].light_energy = _light_energy[i] * level


# --- The intro -------------------------------------------------------------------

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
	SaveGame.hosho_met = true
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
	var m := market.global_position
	var g := m.y + HALL.z
	var him := func() -> Vector3: return hosho.global_position + Vector3(0.0, 2.4, 0.0)
	_cine = CineCamera.new()
	_cine.game_camera = get_viewport().get_camera_3d()
	_cine.length = 13.0
	_cine.shot(0.0, 3.2, m + Vector3(ARENA.x, HALL.z + 1.6, 9.0), m + Vector3(ARENA.x + 8.0, HALL.z + 2.2, 8.0),
			m + Vector3(ARENA.x + 12.0, HALL.z + 3.0, -4.0), m + Vector3(HIS_X - 2.0, HALL.z + 3.5, -4.0), Vector2(42.0, 40.0))
	_cine.shot(3.2, 5.6, m + Vector3(HIS_X - 3.4, HALL.z + 0.35, 4.4), m + Vector3(HIS_X - 3.1, HALL.z + 0.9, 4.0),
			m + Vector3(HIS_X, HALL.z + 0.4, 0.0), m + Vector3(HIS_X, HALL.z + 3.0, 0.0), Vector2(42.0, 40.0))
	_cine.shot(5.6, 7.4, m + Vector3(HIS_X - 4.0, HALL.z + 0.6, 5.0), m + Vector3(HIS_X - 3.2, HALL.z + 0.9, 4.2), him, him,
			Vector2(40.0, 36.0))
	_cine.shot(7.4, 8.8, func() -> Vector3: return him.call() + Vector3(-1.6, 0.4, 2.6),
			func() -> Vector3: return him.call() + Vector3(-1.2, 0.3, 2.0), him, him, Vector2(32.0, 28.0), Vector2(2.0, -2.0), 0.015)
	_cine.shot(8.8, 13.0, m + Vector3(HIS_X - 9.0, HALL.z + 2.6, 12.0), m + Vector3(HIS_X - 11.0, HALL.z + 3.6, 17.0),
			m + Vector3(HIS_X - 4.0, HALL.z + 2.6, -2.0), m + Vector3(HIS_X - 6.0, HALL.z + 3.0, -2.0), Vector2(40.0, 40.0), Vector2.ZERO, 0.02, 0.8)
	for i in _lights.size():
		var when := 0.4 + i * 0.6
		var k := i
		_cine.at(when, func() -> void:
			var t := create_tween()
			t.tween_property(_lights[k], "light_energy", _light_energy[k], 0.4)
			Sound.play(self, &"lantern_snuff", -6.0))
	_cine.at(3.2, func() -> void:
		Sound.play(self, &"taiko_hit", 2.0)
		_cine.shake(0.3))
	_cine.at(5.6, func() -> void:
		Sound.play(self, &"fire_whoosh", 0.0)
		hosho.set(&"_mode", &"lantern_tell"))
	_cine.at(7.4, func() -> void: hosho.set(&"_mode", &"wait"))
	_cine.at(8.8, func() -> void:
		hosho.set(&"_mode", &"storm_tell")
		Sound.play(self, &"akane_slash", 2.0))
	_cine.at(9.6, func() -> void:
		hosho.set(&"_mode", &"wait")
		Sound.play(self, &"taiko_hit", 4.0)
		Confetti.burst(market, hosho.position + Vector3(0.0, 0.3, 0.0), 40, [Color(1.0, 0.82, 0.42), Color(0.86, 0.68, 0.34)])
		_cine.shake(0.5)
		_title.paint())
	_cine.at(11.6, func() -> void: _seal_doors(true))
	_cine.finished.connect(func() -> void:
		if _state == &"intro":
			_end_intro())
	add_child(_cine)


func _make_title() -> HannyaTitle:
	var title := HannyaTitle.new()
	title.KANJI = preload("res://textures/title_hosho_kanji.png")
	title.NAME = preload("res://textures/title_hosho_name.png")
	title.SUBTITLE = preload("res://textures/title_hosho_subtitle.png")
	title.SEAL = preload("res://textures/seal_hosho.png")
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
	_set_hall_light(1.0, false)
	if _hud:
		_hud.visible = true
	_hold_ronin(false)
	_start_fight()


## The doors shut behind him (and a wall he cannot pass).
func _seal_doors(shut: bool) -> void:
	terraces.close_gate(shut)
	if shut and _wall == null:
		_wall = market._solid(Vector3(TerracesQuarter.GATE_X + 0.2, HALL.z + 15.0, 0.0), Vector3(0.6, 30.0, 4.0))
		_wall.set_meta(&"no_climb", true)
	elif not shut and _wall:
		_wall.queue_free()
		_wall = null


func _start_fight() -> void:
	_state = &"fight"
	_seal_doors(true)
	_set_hall_light(1.0, false)
	hosho.begin()
	Sound.duck_music(true)
	_play_music(true)
	_camera_back(true)
	if _bar == null:
		_bar = BossBar.new()
		_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		var where := _overlay_node()
		if where:
			where.add_child(_bar)
		_bar.watch(hosho, preload("res://textures/title_hosho_kanji.png"), preload("res://textures/title_hosho_name.png"))
	hosho.health_changed.emit(hosho.health, hosho.max_health)


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


func _on_ronin_died() -> void:
	if _state != &"fight":
		return
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func() -> void:
		_state = &"before"
		_seal_doors(false)
		if _bar:
			_bar.hide_bar()
		_play_music(false)
		Sound.duck_music(false)
		_camera_back(false)
		_wave.visible = false
		_set_hall_light(1.0, false)
		hosho.reset(market.global_position + Vector3(HIS_X, HALL.z + 0.05, 0.0)))


# --- After -----------------------------------------------------------------------

func _on_defeated() -> void:
	_state = &"after"
	SaveGame.hosho_beaten = true
	if "hosho" not in SaveGame.seals:
		SaveGame.seals.append("hosho")
	_play_music(false)
	_wave.visible = false
	if _bar:
		_bar.hide_bar()
	_hud = get_tree().get_first_node_in_group(&"hud") as CanvasItem
	if _hud:
		_hud.visible = false
	var m := market.global_position
	var g := m.y + HALL.z
	var him := func() -> Vector3: return hosho.global_position + Vector3(0.0, 1.7, 0.0)
	var hx := hosho.global_position.x
	_cine = CineCamera.new()
	_cine.game_camera = get_viewport().get_camera_3d()
	_cine.length = 15.0
	_cine.shot(0.0, 1.2, func() -> Vector3: return him.call() + Vector3(-2.0, 0.6, 5.0),
			func() -> Vector3: return him.call() + Vector3(-1.5, 0.3, 3.8), him, him, Vector2(36.0, 32.0))
	_cine.shot(1.2, 4.6, Vector3(hx - 5.0, g + 1.4, 8.5), Vector3(hx - 4.2, g + 1.2, 7.0), him, him, Vector2(40.0, 38.0))
	_cine.shot(4.6, 8.2, Vector3(hx - 3.0, g + 0.5, 6.0), Vector3(hx - 2.4, g + 0.6, 5.2),
			Vector3(hx, g + 2.4, -2.0), Vector3(hx, g + 3.4, -3.0), Vector2(46.0, 42.0), Vector2(0.0, 2.0))
	_cine.shot(8.2, 11.0, func() -> Vector3: return him.call() + Vector3(-1.2, 0.8, 2.6),
			func() -> Vector3: return him.call() + Vector3(-1.0, 0.7, 2.2), him, him, Vector2(32.0, 30.0))
	_cine.shot(11.0, 15.0, Vector3(hx - 6.5, g + 2.2, 10.0), Vector3(hx - 8.0, g + 3.0, 14.0),
			Vector3(hx - 2.5, g + 1.6, -1.5), Vector3(hx - 3.0, g + 2.0, -1.5), Vector2(40.0, 40.0), Vector2.ZERO, 0.02, 0.8)
	_cine.at(0.0, func() -> void:
		_cine.flash(0.7, 0.6)
		_cine.shake(0.5)
		Engine.time_scale = 0.3)
	_cine.at(0.8, func() -> void:
		Engine.time_scale = 1.0
		_seal_doors(false))
	_cine.at(1.4, func() -> void:
		Sound.play(self, &"land", 2.0)
		_wash_gold(true))
	_cine.at(4.6, func() -> void:
		_tear_open(true)
		_cine.shake(0.3))
	_cine.at(5.6, func() -> void:
		var t := create_tween()
		t.tween_method(hosho.set_kneel, 0.0, 1.0, 2.4).set_trans(Tween.TRANS_SINE))
	_cine.at(8.4, func() -> void:
		var words := BrushLine.new()
		words.texture = preload("res://textures/hosho_line.png")
		var where := _overlay_node()
		if where:
			where.add_child(words)
			words.show_line(2.2))
	_cine.at(11.2, func() -> void: _give_seal())
	_cine.finished.connect(func() -> void:
		Engine.time_scale = 1.0
		_cine = null
		_state = &"done"
		_camera_back(false)
		Sound.duck_music(false)
		if _hud:
			_hud.visible = true
		if _held:
			_held = false
			_ronin.set_physics_process(true)
		SaveGame.write())
	add_child(_cine)


## The gold leaf washes off him (laid over his paper: the Hannya's wash
## shader), flakes of it showering down as it goes.
func _wash_gold(slow: bool) -> void:
	_wash = ShaderMaterial.new()
	_wash.shader = preload("res://shaders/wash_white.gdshader")
	_wash.set_shader_parameter(&"radius", 2.4)
	_wash.set_shader_parameter(&"centre", hosho.global_position + Vector3(0.0, 1.5, 0.0))
	_wash.set_shader_parameter(&"paper", Color(0.84, 0.82, 0.78, 0.72))   # (his folds still show)
	hosho.wash = _wash
	hosho.set_process(true)
	if not slow:
		_wash.set_shader_parameter(&"amount", 0.85)
		return
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _wash.set_shader_parameter(&"amount", v), 0.0, 0.85, 3.2).set_trans(Tween.TRANS_SINE)
	_gold_shower = CPUParticles3D.new()
	_gold_shower.amount = 90
	_gold_shower.lifetime = 2.0
	_gold_shower.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_gold_shower.emission_box_extents = Vector3(0.7, 1.2, 0.5)
	_gold_shower.gravity = Vector3(0.0, -2.0, 0.0)
	_gold_shower.angular_velocity_min = -400.0
	_gold_shower.angular_velocity_max = 400.0
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.08, 0.06)
	var gilt := StandardMaterial3D.new()
	gilt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gilt.albedo_color = Color(1.0, 0.82, 0.42)
	gilt.cull_mode = BaseMaterial3D.CULL_DISABLED
	gilt.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.material = gilt
	_gold_shower.mesh = leaf
	add_child(_gold_shower)
	_gold_shower.position = hosho.position + Vector3(0.0, 1.6, 0.0)
	_gold_shower.emitting = true
	var stop := create_tween()
	stop.tween_interval(3.6)
	stop.tween_callback(func() -> void: _gold_shower.emitting = false)


## The shoji behind him tears open: a ragged hole with pale torn edges, the
## night beyond, and the Rain pouring in through it onto him.
func _tear_open(slow: bool) -> void:
	var x := hosho.position.x
	_tear = Node3D.new()
	add_child(_tear)
	var hole := PaperMesh.new(7)
	var ring := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		ring.append(Vector2(x + cos(a) * _rng.randf_range(2.2, 3.2), HALL.z + 5.0 + sin(a) * _rng.randf_range(3.2, 4.4)))
	hole.color = Color(0.04, 0.05, 0.1)
	hole.torn_sheet(PaperMesh.tear(ring, 0.25, 0.15, _rng), SHOJI_Z + 0.02, Scenery.WALL_PAPER_RIM, 0.08)
	_tear.add_child(hole.build(Color.WHITE, 0.0, true))
	_hole_rain = CPUParticles3D.new()
	_hole_rain.amount = 160
	_hole_rain.lifetime = 0.9
	_hole_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_hole_rain.emission_box_extents = Vector3(1.6, 0.1, 1.6)
	_hole_rain.direction = Vector3(-0.05, -1.0, 0.0)
	_hole_rain.spread = 2.0
	_hole_rain.gravity = Vector3.ZERO
	_hole_rain.initial_velocity_min = 14.0
	_hole_rain.initial_velocity_max = 16.0
	_hole_rain.particle_flag_align_y = true
	var streak := QuadMesh.new()
	streak.size = Vector2(0.015, 0.9)
	var pale := StandardMaterial3D.new()
	pale.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pale.albedo_color = Color(0.78, 0.84, 1.0, 0.35)
	streak.material = pale
	_hole_rain.mesh = streak
	_hole_rain.position = Vector3(x, HALL.z + 10.5, -1.0)
	_tear.add_child(_hole_rain)
	_hole_rain.emitting = true
	var cold := OmniLight3D.new()
	cold.light_color = Color(0.62, 0.7, 0.95)
	cold.light_energy = 1.4
	cold.omni_range = 7.0
	cold.position = Vector3(x, HALL.z + 4.0, -3.0)
	_tear.add_child(cold)
	if slow:
		Sound.play(self, &"paper_rip", 4.0)
		_tear.scale = Vector3(1.0, 0.05, 1.0)
		var t := create_tween()
		t.tween_property(_tear, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## He holds out his seal; it flies to the Ronin's hand.
func _give_seal() -> void:
	var seal := Node3D.new()
	add_child(seal)
	var s := PaperMesh.new(8)
	s.color = Color(0.86, 0.68, 0.34)
	s.frustum(8, Vector2(0.09, 0.09), Vector2(0.09, 0.09), 0.16, Vector3.ZERO)
	s.color = Color(0.7, 0.16, 0.12)
	s.box(Vector3(0.0, -0.01, 0.0), Vector3(0.15, 0.03, 0.15))
	seal.add_child(s.build())
	seal.position = hosho.position + Vector3(-hosho.facing * -0.6, 1.4, 0.4)
	Sound.play(self, &"draw_ready", 0.0)
	var to := _ronin.global_position - market.global_position + Vector3(0.0, 1.1, 0.3)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_property(seal, "position", (seal.position + to) * 0.5 + Vector3(0.0, 1.0, 0.0), 0.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(seal, "rotation:y", TAU, 0.6)
	t.tween_property(seal, "position", to, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(seal, "scale", Vector3.ONE * 0.3, 0.4)
	t.tween_callback(func() -> void:
		seal.queue_free()
		(_ronin.get_node("Puppet") as RoninPuppet).play_healed())
