class_name Village
extends Node3D
## Kamiyama Village, built entirely in code as a kirigami diorama, in the
## style of the rainy-town reference picture.
##
## This file is the LAYOUT: where the ground, houses, lanterns and props go,
## and how the scene is lit. The things themselves are made by:
##   scenery.gd   houses, roofs, lanterns, banners, trees, props
##   backdrop.gd  sky, moon, clouds, hills, castle, far village, mist
##
## Depth guide (Z): +4 dark foreground ... +1.5 front edge of the street ...
## 0 the gameplay plane ... -4.3 house walls ... -11 to -17 far village ...
## -24 to -46 hills ... -53 sky.
##
## To rearrange the level, edit the lists in _build_ground(), _build_houses()
## and _build_props(). Positions are in metres; the Ronin is 1.5 m tall.

const HUSK_SCENE := preload("res://scenes/paper_husk.tscn")
const OFF := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## How far forward (toward the camera) and back the street surface reaches.
const STREET_FRONT := 1.5
const STREET_BACK := -8.0
## Depth of the house walls.
const HOUSE_Z := -4.3

const STREET := Color(0.21, 0.225, 0.31)
const STREET_JOINT := Color(0.08, 0.09, 0.17)
const EARTH := Color(0.06, 0.07, 0.14)
const MOSS := Color(0.3, 0.34, 0.18)

@export_group("Light")
@export var moon_energy := 0.55
@export var ambient_energy := 0.55
@export var lantern_energy := 4.2
@export var lantern_range := 7.5
@export var lantern_glow := 2.2
@export var window_glow := 1.6
## How strongly lantern light smears across the wet street (0 = dry).
@export var wet_shine := 0.34
## How many raindrop splashes per metre of street (0 = none).
@export var splashes_per_metre := 5.0
## How big each splash is: 0 = a few faint droplets, 1 = a strong spray.
@export_range(0.0, 1.0) var splash_strength := 0.5
@export var fog_density := 0.006
@export var glow_intensity := 0.7
## 1 = full colour, 0 = black and white.
@export var color_saturation := 0.8
@export var color_contrast := 1.05

@export_group("Wind")
## The steady breeze, in metres per second.
@export var wind_breeze := 2.0
## How much stronger a full gust is than the breeze.
@export var wind_gusts := 4.5
## How fast hanging things swing back and forth (lower = slower). 1.4 was
## too sleepy for a storm and 6 was a nervous jitter.
@export var sway_speed := 2.4
## How wide the swing is, compared with how far the wind leans the thing
## (1 = it swings all the way back to hanging straight).
@export var sway_range := 0.9

@export_group("Layout")
## Change this to reshuffle the random details (torn edges, drips, tiles).
@export var layout_seed := 7
@export var enemy_positions: Array[Vector2] = [Vector2(19.0, 0.1), Vector2(24.5, 0.1), Vector2(37.0, 1.6)]

var _rng := RandomNumberGenerator.new()
var _lanterns: Array[Node3D] = []
var _bead_picture: GradientTexture2D


func _ready() -> void:
	_rng.seed = layout_seed
	Wind.breeze = wind_breeze
	Wind.gusts = wind_gusts
	_build_light_and_air()
	var backdrop := Backdrop.new()
	backdrop.layout_seed = layout_seed
	add_child(backdrop)
	_build_houses()
	_build_ground()
	_build_props()
	_build_foreground()
	for spot: Vector2 in enemy_positions:
		var husk: Node3D = HUSK_SCENE.instantiate()
		husk.position = Vector3(spot.x, spot.y, 0.0)
		add_child(husk)


func _process(_delta: float) -> void:
	# Everything the wind touches is moved every frame, so it flows. (The
	# characters are posed 12 times a second like puppets; cloth and lanterns
	# are not, because stepped swaying looks like a stutter.)
	var t := Wind.now()
	# Lanterns are heavy: they lean a little with the wind and swing gently.
	for i in _lanterns.size():
		var blow := Wind.speed_at(_lanterns[i].global_position.x)
		var swing := sin(t * sway_speed * 0.8 + i * 1.7) + 0.25 * sin(t * sway_speed * 1.7 + i * 0.9)
		_lanterns[i].rotation.z = -blow * 0.02 + swing * 0.016 * blow
		_lanterns[i].rotation.x = sin(t * sway_speed * 0.6 + i * 2.3) * 0.01 * blow
	# Curtains, banners, streamers, grass and branches (see Scenery.windswept).
	# Each piece leans as far as the wind is blowing where it hangs, and on
	# top of that rocks back and forth in two overlapping rhythms, one slow
	# and wide, one a bit quicker and smaller. Every piece keeps its own
	# pace, so they never move in step.
	for node: Node3D in get_tree().get_nodes_in_group(&"windswept"):
		var blow := Wind.speed_at(node.global_position.x)
		var gain: float = node.get_meta(&"wind_gain")
		var phase: float = node.get_meta(&"wind_phase")
		var rest: Vector3 = node.get_meta(&"wind_rest")
		var pace := sway_speed * lerpf(0.8, 1.2, fposmod(phase * 0.37, 1.0))
		var rock := 0.7 * sin(t * pace + phase) + 0.3 * sin(t * pace * 1.9 + phase * 1.9)
		node.rotation.z = rest.z - blow * gain * (1.0 + sway_range * rock)
		node.rotation.x = rest.x + sin(t * pace * 0.7 + phase * 1.7) * absf(gain) * 0.5 * blow
	# Falling petals are carried further in a gust.
	for drift: CPUParticles3D in get_tree().get_nodes_in_group(&"petal_drift"):
		drift.gravity.x = -0.1 - Wind.speed_at(drift.global_position.x) * 0.22


## Height of the street at a given x (ignoring the pit).
func _street_height(x: float) -> float:
	return 1.5 if x >= 30.0 else 0.0


# --- Light, fog and glow ----------------------------------------------------

func _build_light_and_air() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.045, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.8)
	env.ambient_light_energy = ambient_energy
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.24, 0.46)
	env.fog_density = fog_density
	env.glow_enabled = true
	env.glow_intensity = glow_intensity
	env.glow_hdr_threshold = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Colour grading: the reference is a muted indigo, not a bright blue.
	env.adjustment_enabled = true
	env.adjustment_saturation = color_saturation
	env.adjustment_contrast = color_contrast
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)

	# Moonlight. It shines from the front, so each paper layer casts a soft
	# shadow onto the layer behind it. That is what sells the diorama look.
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.64, 0.72, 0.96)
	moon.light_energy = moon_energy
	moon.rotation_degrees = Vector3(-42.0, 24.0, 0.0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 45.0
	add_child(moon)


# --- Houses -----------------------------------------------------------------

func _build_houses() -> void:
	# [x, width, wall height, window lit?, extras, which side the lantern hangs (-1, 0 = none, 1)]
	var street := [
		[-13.0, 6.5, 4.3, true, ["noren", "brace"], 1],
		[-4.5, 6.0, 5.2, true, ["round"], 1],
		[3.5, 5.2, 4.0, false, ["brace", "awning"], 0],
		[16.5, 6.5, 5.0, true, ["brace"], -1],
		[24.5, 5.5, 4.2, true, ["awning"], 1],
		[34.5, 6.5, 4.6, true, ["round", "noren"], 1],
		[40.3, 4.4, 4.0, false, ["brace"], 0],
	]
	for h: Array in street:
		var x: float = h[0]
		var ground := _street_height(x)
		var house := Scenery.house(_rng, h[1], h[2], h[3], window_glow, h[4])
		house.position = Vector3(x, ground, HOUSE_Z)
		add_child(house)
		if house.has_meta("window"):
			var window: Vector3 = house.position + house.get_meta("window")
			_add_light(window + Vector3(0.0, 0.0, 1.1), lantern_energy * 0.45, lantern_range * 0.7)
			_add_wet_shine(window.x, ground, 0.6)
		if h[5] != 0:
			var side: float = h[5]
			var half: float = h[1] * 0.5
			_hang_lantern(Vector3(x + side * (half + 1.15), ground + h[2] - 0.5, HOUSE_Z + 1.5), 0.3, 1.0)
			# The little arm the lantern hangs from.
			var arm := PaperMesh.new(1)
			arm.color = PaperMesh.TIMBER
			arm.box(Vector3(x + side * (half + 0.82), ground + h[2] - 0.47, HOUSE_Z + 1.5), Vector3(0.9, 0.07, 0.07))
			add_child(arm.build())


## Hangs a lantern, gives it a real light, and smears its glow on the street.
func _hang_lantern(hook: Vector3, string_length: float, size: float) -> void:
	var lantern := Scenery.lantern(_rng, lantern_glow, size, string_length)
	lantern.position = hook
	add_child(lantern)
	_lanterns.append(lantern)
	var light := _add_light(Vector3.ZERO, lantern_energy * size, lantern_range * size)
	light.reparent(lantern)
	light.position = (lantern.get_meta("light_at") as Vector3) + Vector3(0.0, 0.0, 0.7)
	_add_wet_shine(hook.x, _street_height(hook.x), size)


## The streak of lantern light on the wet stones.
func _add_wet_shine(x: float, ground: float, strength: float) -> void:
	if wet_shine <= 0.0:
		return
	var shine := Scenery.reflection(Vector2(2.2, 9.0), Color(1.0, 0.6, 0.28, wet_shine * strength))
	shine.position = Vector3(x, ground + 0.015, -1.6)
	add_child(shine)


# --- Ground and platforms (the parts you can stand on) ----------------------

func _build_ground() -> void:
	# [left edge, right edge, height of the top surface]
	for g: Array in [[-17.0, 10.0, 0.0], [13.0, 30.0, 0.0], [30.0, 47.0, 1.5]]:
		_build_ground_block(g[0], g[1], g[2])
	# [centre x, top height, width]
	for p: Array in [[4.5, 1.9, 3.0], [8.0, 3.6, 2.6], [16.5, 2.1, 3.6], [22.0, 3.9, 3.0]]:
		_build_platform(p[0], p[1], p[2])
	# The pit: a dark gap with black water at the bottom.
	var pit := PaperMesh.new(_rng.randi())
	pit.shade_jitter = 0.0
	pit.color = Color(0.035, 0.04, 0.085)
	pit.rect(Vector2(11.5, -6.2), Vector2(3.4, 12.0), -3.2)
	pit.color = Color(0.02, 0.022, 0.05)
	pit.quad(Vector3(9.9, -3.0, -3.2), Vector3(13.1, -3.0, -3.2), Vector3(13.1, -3.0, STREET_FRONT + 0.3),
			Vector3(9.9, -3.0, STREET_FRONT + 0.3), Vector3.UP)
	var hole := pit.build(Color.WHITE, 0.0, true)
	hole.cast_shadow = OFF
	add_child(hole)
	# Invisible walls at both ends of the level.
	for x: float in [-16.5, 46.5]:
		_add_solid(Vector3(x, 10.0, 0.0), Vector3(1.0, 40.0, 4.0))


func _build_ground_block(left: float, right: float, top: float) -> void:
	var width := right - left
	var middle := (left + right) * 0.5
	_add_solid(Vector3(middle, top - 4.0, -1.5), Vector3(width, 8.0, 6.0))

	# The earth under the street (you only see its sides, in the pit).
	var earth := PaperMesh.new(_rng.randi())
	earth.shade_jitter = 0.05
	earth.color = EARTH
	# (It stops a little short of the front edge, so its face does not sit
	# at exactly the same depth as the torn sheets there and flicker.)
	earth.box(Vector3(middle, top - 5.02, (STREET_FRONT - 0.15 + STREET_BACK) * 0.5),
			Vector3(width, 10.0, STREET_FRONT - 0.15 - STREET_BACK))
	add_child(earth.build())

	# The wet paving, in short lengths so no piece is touched by too many
	# lights at once (the web renderer allows about 8 per piece).
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 4.5, right)
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.08
		b.wrinkle_depth = 1.0
		b.color = STREET
		var z := STREET_BACK
		while z < STREET_FRONT - 0.01:  # rows of paving stones
			var z1 := minf(z + 1.15, STREET_FRONT)
			var sx := x
			while sx < x1 - 0.01:
				var sx1 := minf(sx + _rng.randf_range(1.2, 1.9), x1)
				b.quad(Vector3(sx + 0.02, top, z + 0.02), Vector3(sx1 - 0.02, top, z + 0.02),
						Vector3(sx1 - 0.02, top, z1 - 0.02), Vector3(sx + 0.02, top, z1 - 0.02), Vector3.UP)
				sx = sx1
			z = z1
		b.color = STREET_JOINT
		b.quad(Vector3(x, top - 0.01, STREET_BACK), Vector3(x1, top - 0.01, STREET_BACK),
				Vector3(x1, top - 0.01, STREET_FRONT), Vector3(x, top - 0.01, STREET_FRONT), Vector3.UP)
		var paving := b.build()
		var wet := paving.material_override as StandardMaterial3D
		wet.roughness = 0.38
		wet.metallic_specular = 0.6
		paving.cast_shadow = OFF
		add_child(paving)
		x = x1

	_add_rain_splashes(left, right, top)

	# The front of the street: torn sheets stepping down toward the camera.
	var front := PaperMesh.new(_rng.randi())
	front.shade_jitter = 0.04
	front.color = Color(0.23, 0.245, 0.34)
	front.torn_sheet(_torn_band(left, right, top, top - 1.2, 0.0), STREET_FRONT, Color(0.5, 0.54, 0.68), 0.03)
	front.color = Color(0.125, 0.135, 0.22)
	front.torn_sheet(_torn_band(left, right, top - 0.3, top - 12.0, 0.13), STREET_FRONT + 0.1, Color(0.24, 0.265, 0.39), 0.03)
	front.color = Color(0.07, 0.076, 0.14)
	front.torn_sheet(_torn_band(left, right, top - 0.82, top - 12.0, 0.22), STREET_FRONT + 0.2, Color(0.15, 0.165, 0.27), 0.03)
	# Loose chunks of stone in the broken edge, on each of the three layers.
	# Each chunk gets its own depth, a few millimetres from its neighbours:
	# two sheets at exactly the same depth flicker where they overlap.
	var chunk_number := 0
	var cx := left + 0.5
	while cx < right - 0.7:
		var layer := _rng.randi_range(0, 2)
		var drop: float = [0.17, 0.62, 1.15][layer]
		var tone: Color = [Color(0.19, 0.2, 0.29), Color(0.1, 0.11, 0.185), Color(0.055, 0.06, 0.115)][layer]
		var rim: Color = [Color(0.4, 0.43, 0.56), Color(0.2, 0.22, 0.33), Color(0.12, 0.135, 0.22)][layer]
		var wide := _rng.randf_range(0.3, 0.8)
		var chunk := PackedVector2Array()
		for k in 6:
			var angle := TAU * k / 6.0 + _rng.randf_range(-0.3, 0.3)
			chunk.append(Vector2(cx + cos(angle) * wide, top - drop - _rng.randf() * 0.2 + sin(angle) * wide * 0.36))
		front.color = tone * _rng.randf_range(0.85, 1.2)
		front.torn_sheet(chunk, STREET_FRONT + 0.03 + layer * 0.1 + (chunk_number % 9) * 0.0045, rim, 0.022)
		chunk_number += 1
		cx += _rng.randf_range(0.5, 1.7)
	# Moss along the lip.
	front.color = MOSS
	var mx := left + _rng.randf_range(0.5, 2.0)
	while mx < right - 0.6:
		var tuft := PackedVector2Array()
		for k in 7:
			var angle := TAU * k / 7.0
			tuft.append(Vector2(mx, top - 0.07) + Vector2(cos(angle) * _rng.randf_range(0.15, 0.36), sin(angle) * 0.055) * _rng.randf_range(0.6, 1.1))
		front.polygon(tuft, STREET_FRONT + 0.083)
		mx += _rng.randf_range(2.0, 5.5)
	var cliff := front.build()
	cliff.cast_shadow = OFF
	add_child(cliff)


## Outline of a long strip whose top edge is broken into flat runs and sudden
## steps, like the edge of cracked stone, for the torn front of the street.
func _torn_band(left: float, right: float, top: float, bottom: float, rough: float) -> PackedVector2Array:
	var line := PackedVector2Array()
	var x := left
	var y := top + _rng.randf_range(-rough, rough)
	while x < right - 0.5:
		line.append(Vector2(x, y))
		x = minf(x + _rng.randf_range(0.5, 1.9), right - 0.3)
		line.append(Vector2(x, y + _rng.randf_range(-0.3, 0.3) * rough))
		x += _rng.randf_range(0.08, 0.2)
		y = top + _rng.randf_range(-rough, rough)
	line.append(Vector2(right, y))
	var outline := PaperMesh.tear(line, 0.25, 0.02, _rng, false)
	outline.append(Vector2(right, bottom))
	outline.append(Vector2(left, bottom))
	return outline


func _build_platform(center_x: float, top: float, width: float) -> void:
	_add_solid(Vector3(center_x, top - 0.15, 0.0), Vector3(width, 0.3, 2.2))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.22
	# Planks, with a pale worn edge along the front.
	b.color = Scenery.WOOD
	var x := center_x - width * 0.5
	while x < center_x + width * 0.5 - 0.01:
		var x1 := minf(x + _rng.randf_range(0.45, 0.7), center_x + width * 0.5)
		b.box(Vector3((x + x1) * 0.5, top - 0.11, 0.0), Vector3(x1 - x - 0.03, 0.22, 2.2))
		x = x1
	b.color = Color(0.45, 0.4, 0.42)
	b.box(Vector3(center_x, top - 0.02, 1.1), Vector3(width, 0.04, 0.04))
	# Scaffolding behind the gameplay plane: posts, a beam and a cross brace.
	b.color = PaperMesh.TIMBER
	b.box(Vector3(center_x, top - 0.28, -0.9), Vector3(width + 0.3, 0.14, 0.14))
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(center_x + side * (width * 0.5 - 0.2), (top - 0.3) * 0.5, -0.95),
				Vector3(0.16, top - 0.3, 0.16))
	var half := width * 0.5 - 0.2
	b.extrude(PackedVector2Array([Vector2(center_x - half, 0.3), Vector2(center_x - half + 0.14, 0.3),
			Vector2(center_x + half, top - 0.45), Vector2(center_x + half - 0.14, top - 0.45)]), -1.02, -0.96)
	add_child(b.build())


# --- Props: the well, lanterns, a shoji screen, the torii --------------------

func _build_props() -> void:
	var well := Scenery.well(_rng)
	well.position = Vector3(-8.0, 0.0, -1.5)
	add_child(well)
	_hang_lantern(Vector3(-9.45, 2.75, -1.35), 0.25, 0.8)

	_build_shoji_screen(Vector3(28.6, 0.0, -2.2))

	var gate := Scenery.torii(_rng, PaperMesh.VERMILION)
	gate.position = Vector3(44.6, 1.5, -1.3)
	add_child(gate)
	_hang_lantern(Vector3(44.6, 4.75, -1.0), 0.2, 0.8)

	var flag := Scenery.banner(_rng, 5.2)
	flag.position = Vector3(31.95, 1.5, -2.4)
	add_child(flag)

	# Clutter along the street: [what, x, depth, size, turn]
	for prop: Array in [["barrel", -1.2, -2.6, 1.0, 0.0], ["crate", -0.2, -2.9, 0.8, 0.3], ["barrel", 0.5, -2.3, 0.8, 0.0],
			["crate", 20.6, -2.8, 0.9, -0.2], ["crate", 21.0, -2.75, 0.6, 0.5], ["barrel", 14.3, -2.5, 1.0, 0.0],
			["barrel", 38.6, -2.6, 1.0, 0.0], ["crate", 39.4, -2.9, 0.8, 0.2]]:
		var thing: Node3D = Scenery.barrel(_rng, prop[3]) if prop[0] == "barrel" else Scenery.crate(_rng, prop[3])
		thing.position = Vector3(prop[1], _street_height(prop[1]), prop[2])
		thing.rotation.y = prop[4]
		if prop[0] == "crate" and prop[3] < 0.7:
			thing.position.y += 0.9  # the small crate sits on the big one
		add_child(thing)

	# Broken fences either side of the pit, and at the far end.
	for f: Array in [[6.3, 3.4, -3.0], [13.3, 2.6, -3.0], [45.0, 2.0, 1.0]]:
		var rails := Scenery.fence(_rng, f[1])
		rails.position = Vector3(f[0], _street_height(f[0] + 0.1), f[2])
		add_child(rails)

	# Fallen petals on the stones near the well.
	var petals := PaperMesh.new(_rng.randi())
	petals.texture_scale = 0.0
	petals.shade_jitter = 0.2
	petals.color = PaperMesh.SAKURA
	for i in 26:
		var at := Vector3(_rng.randf_range(-15.5, -4.0), 0.02, _rng.randf_range(-2.4, 1.3))
		var turn := _rng.randf() * TAU
		var across := Vector3(cos(turn), 0.0, sin(turn)) * 0.09
		var along := Vector3(-sin(turn), 0.0, cos(turn)) * 0.14
		petals.quad(at - across, at + along, at + across, at - along * 0.6, Vector3.UP)
	var fallen := petals.build()
	fallen.cast_shadow = OFF
	add_child(fallen)


## A standing shoji screen lit from behind, with the shadow of a pine on it.
## A first taste of the Shadow Step idea from the design doc.
func _build_shoji_screen(at: Vector3) -> void:
	var size := Vector2(2.7, 2.9)
	var middle := Vector2(0.0, size.y * 0.5 + 0.25)
	var panel := PaperMesh.new(1)
	panel.shade_jitter = 0.04
	panel.rect(middle, size)
	var screen := panel.build(Color(1.0, 0.78, 0.5), 1.3, true)
	screen.position = at
	screen.cast_shadow = OFF
	add_child(screen)

	# The silhouette, as if cast on the paper by a lantern behind it.
	var shadow := PaperMesh.new(_rng.randi())
	shadow.color = Color(0.3, 0.16, 0.08)
	shadow.texture_scale = 0.0
	Scenery.pine(shadow, Vector2(0.15, 0.3), 2.2, 0.012, _rng)
	var silhouette := shadow.build(Color.WHITE, 0.0, true)
	silhouette.position = at
	silhouette.cast_shadow = OFF
	add_child(silhouette)

	# Dark wooden frame and lattice in front.
	var b := PaperMesh.new(_rng.randi())
	b.color = PaperMesh.TIMBER
	for i in 5:
		b.rect(middle + Vector2(lerpf(-size.x, size.x, i / 4.0) * 0.5, 0.0), Vector2(0.06, size.y), 0.05)
	for i in 5:
		b.rect(middle + Vector2(0.0, lerpf(-size.y, size.y, i / 4.0) * 0.5), Vector2(size.x + 0.06, 0.06), 0.05)
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * (size.x * 0.5 + 0.1), size.y * 0.5 + 0.2, 0.0), Vector3(0.17, size.y + 0.5, 0.17))
		b.box(Vector3(side * (size.x * 0.5 + 0.1), 0.06, 0.0), Vector3(0.3, 0.12, 0.7))
	var frame := b.build()
	frame.position = at
	add_child(frame)
	var shine := Scenery.halo(3.2, Color(1.0, 0.6, 0.28, 0.3))
	shine.position = at + Vector3(0.0, middle.y, 0.2)
	add_child(shine)
	_add_light(at + Vector3(0.0, middle.y, 1.3), lantern_energy * 0.7, lantern_range * 0.8)
	_add_wet_shine(at.x, at.y, 0.9)


# --- Foreground: dark shapes between the camera and the action ---------------

func _build_foreground() -> void:
	# Two near-black torn strips along the bottom of the view. They follow the
	# height of the street so they never cover the Ronin's feet.
	var near := PaperMesh.new(_rng.randi())
	near.shade_jitter = 0.0
	near.texture_scale = 0.3
	for layer: Array in [[3.3, -0.5, Color(0.04, 0.047, 0.105), Color(0.12, 0.14, 0.27)],
			[4.2, -0.32, Color(0.018, 0.02, 0.05), Color(0.07, 0.085, 0.17)]]:
		var line := PackedVector2Array()
		var x := -34.0
		while x < 66.0:
			var ground := lerpf(0.0, 1.5, smoothstep(33.5, 38.0, x))
			line.append(Vector2(x, ground + layer[1] + _rng.randf_range(-0.16, 0.16)))
			x += _rng.randf_range(0.8, 2.2)
		var outline := PaperMesh.tear(line, 0.3, 0.05, _rng, false)
		outline.append(Vector2(66.0, -14.0))
		outline.append(Vector2(-34.0, -14.0))
		near.color = layer[2]
		near.torn_sheet(outline, layer[0], layer[3], 0.03)

	# Rocks and clumps of grass poking up from the dark.
	near.color = Color(0.03, 0.035, 0.08)
	var gx := -30.0
	while gx < 62.0:
		var ground := lerpf(0.0, 1.5, smoothstep(33.5, 38.0, gx))
		if _rng.randf() < 0.3:
			var rock := PackedVector2Array()
			var wide := _rng.randf_range(0.7, 1.6)
			for k in 6:
				var angle := PI * k / 5.0
				rock.append(Vector2(gx + cos(angle) * wide, ground - 0.55 + sin(angle) * wide * 0.5 * _rng.randf_range(0.7, 1.1)))
			near.torn_sheet(PaperMesh.tear(rock, 0.3, 0.05, _rng), 3.7, Color(0.1, 0.12, 0.23), 0.03)
		else:
			# A clump of grass: its own piece, so the wind can bend it.
			var clump := PaperMesh.new(_rng.randi())
			clump.shade_jitter = 0.0
			clump.texture_scale = 0.0
			clump.color = Color(0.03, 0.035, 0.08)
			for blade in _rng.randi_range(4, 9):
				var foot := _rng.randf_range(-0.5, 0.5)
				var tip := Vector2(foot + _rng.randf_range(-0.35, 0.35), _rng.randf_range(0.6, 1.25))
				clump.polygon(PackedVector2Array([Vector2(foot - 0.06, 0.0), Vector2(foot + 0.06, 0.0), tip]))
			var grass := clump.build(Color.WHITE, 0.0, true)
			(grass.material_override as StandardMaterial3D).disable_fog = true
			grass.cast_shadow = OFF
			grass.position = Vector3(gx, ground - 0.8, 3.5)
			add_child(grass)
			Scenery.windswept(grass, -0.03, _rng)
		gx += _rng.randf_range(1.5, 4.5)
	var dark := near.build(Color.WHITE, 0.0, true)
	(dark.material_override as StandardMaterial3D).disable_fog = true
	dark.cast_shadow = OFF
	add_child(dark)

	# Cherry trees. One stands in the foreground at the start, its trunk at
	# the left of the view; the others stand on the street behind the Ronin.
	# [x, depth, height, lean, blossoms left, how much of it is bare trunk]
	for t: Array in [[-14.2, 2.6, 10.5, 0.9, 40, 0.56], [20.3, -2.0, 7.6, 0.8, 30, 0.42], [38.2, -2.0, 7.2, -0.7, 26, 0.42]]:
		var x: float = t[0]
		var tree := Scenery.sakura_tree(_rng, t[2], t[3], t[4], t[5])
		tree.position = Vector3(x, (_street_height(x) if t[1] < 0.0 else -0.9), t[1])
		add_child(tree)
		var crown: Vector2 = tree.get_meta(&"crown")
		_add_falling_petals(Vector2(x + crown.x, tree.position.y + crown.y), t[1])


## A few petals drifting down from a cherry branch.
func _add_falling_petals(from: Vector2, z: float) -> void:
	var drift := CPUParticles3D.new()
	drift.amount = 7
	drift.lifetime = 7.0
	drift.preprocess = 7.0
	drift.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drift.emission_box_extents = Vector3(3.5, 0.3, 0.6)
	drift.direction = Vector3(-0.5, -1.0, 0.0)
	drift.spread = 25.0
	drift.gravity = Vector3(-0.15, -0.25, 0.0)
	drift.initial_velocity_min = 0.5
	drift.initial_velocity_max = 1.0
	drift.angle_max = 360.0
	var petal := QuadMesh.new()
	petal.size = Vector2(0.13, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = PaperMesh.SAKURA.darkened(0.12)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.disable_fog = true
	petal.material = mat
	drift.mesh = petal
	drift.cast_shadow = OFF
	drift.position = Vector3(from.x, from.y - 0.5, z - 1.0)
	drift.add_to_group(&"petal_drift")
	add_child(drift)


## Raindrops hitting the wet paving. Each hit throws up a little crown of
## water: a short jet straight up, and round droplets flung outward that
## arc over and fall back. (No ripple rings: Julian did not like them.)
func _add_rain_splashes(left: float, right: float, top: float) -> void:
	var count := int((right - left) * splashes_per_metre)
	if count < 1:
		return
	var area := Vector3((right - left) * 0.5, 0.0, (STREET_FRONT - STREET_BACK) * 0.5 - 1.6)
	var middle := Vector3((left + right) * 0.5, top, (STREET_FRONT + STREET_BACK) * 0.5 + 1.6)

	# The jet: a thin streak of water that shoots up and drops.
	var jets := CPUParticles3D.new()
	jets.amount = maxi(1, int(count * splash_strength * 0.6))
	jets.lifetime = 0.24
	jets.preprocess = 0.3
	jets.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	jets.emission_box_extents = area
	jets.direction = Vector3.UP
	jets.spread = 12.0
	jets.gravity = Vector3(0.0, -16.0, 0.0)
	jets.initial_velocity_min = 1.0 + splash_strength * 0.5
	jets.initial_velocity_max = 1.5 + splash_strength * 0.9
	jets.scale_amount_min = 0.7
	jets.scale_amount_max = 1.3
	var thin := Curve.new()
	thin.add_point(Vector2(0.0, 1.0))
	thin.add_point(Vector2(1.0, 0.2))
	jets.scale_amount_curve = thin
	var jet := QuadMesh.new()
	jet.size = Vector2(0.024, 0.1 + splash_strength * 0.08)
	var jet_look := StandardMaterial3D.new()
	jet_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	jet_look.albedo_color = Color(0.82, 0.88, 1.0, 0.3 + splash_strength * 0.35)
	jet_look.albedo_texture = _bead_texture()
	jet_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jet_look.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	jet_look.billboard_keep_scale = true
	jet_look.disable_fog = true
	jet.material = jet_look
	jets.mesh = jet
	jets.cast_shadow = OFF
	jets.position = middle + Vector3(0.0, 0.08, 0.0)
	add_child(jets)

	# The droplets: round beads flung up and outward, pulled back down.
	var beads := CPUParticles3D.new()
	beads.amount = maxi(1, int(count * (1.0 + splash_strength * 2.5)))
	beads.lifetime = 0.42
	beads.preprocess = 0.5
	beads.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	beads.emission_box_extents = area
	beads.direction = Vector3.UP
	beads.spread = 55.0
	beads.gravity = Vector3(0.0, -12.0, 0.0)
	beads.initial_velocity_min = 0.9 + splash_strength * 0.4
	beads.initial_velocity_max = 1.7 + splash_strength * 1.1
	beads.scale_amount_min = 0.6
	beads.scale_amount_max = 1.5
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.4))
	beads.scale_amount_curve = shrink
	var bead := QuadMesh.new()
	bead.size = Vector2(0.026, 0.026) * (1.0 + splash_strength * 0.35)
	var bead_look := StandardMaterial3D.new()
	bead_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bead_look.albedo_color = Color(0.8, 0.87, 1.0, 0.55 + splash_strength * 0.22)
	bead_look.albedo_texture = _bead_texture()
	bead_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bead_look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	bead_look.disable_fog = true
	bead.material = bead_look
	beads.mesh = bead
	beads.cast_shadow = OFF
	beads.position = middle + Vector3(0.0, 0.04, 0.0)
	add_child(beads)


## A picture of a round bead of water: solid, with a soft rim.
func _bead_texture() -> GradientTexture2D:
	if _bead_picture == null:
		var rim := Gradient.new()
		rim.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
		rim.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
		_bead_picture = _round_texture(rim)
	return _bead_picture


func _round_texture(from_middle_out: Gradient) -> GradientTexture2D:
	var picture := GradientTexture2D.new()
	picture.gradient = from_middle_out
	picture.fill = GradientTexture2D.FILL_RADIAL
	picture.fill_from = Vector2(0.5, 0.5)
	picture.fill_to = Vector2(1.0, 0.5)
	picture.width = 64
	picture.height = 64
	return picture


# --- Small helpers ------------------------------------------------------------

func _add_light(at: Vector3, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = PaperMesh.LANTERN
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.3
	light.position = at
	add_child(light)
	return light


## An invisible solid box the Ronin and enemies collide with.
func _add_solid(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child(body)
