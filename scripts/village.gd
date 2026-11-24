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
## The well he climbs out of after the prologue (main.gd, well_cutscene.gd).
const WELL_X := -8.0
const WELL_Z := -1.5
## The expanded village (docs/village_map.png), left to right, in game x
## (plan metres - 16): Well Square and Market Street (-17 to 62), the Fallen
## Street (62 to 82), the River and the red bridge (82 to 120), the Gatehouse
## (120 to 158), the Shrine Steps (158 to 172), the shrine courtyard.
## The far end of the old level (the torii and the shrine courtyard) is
## shifted this far right.
const EAST := 127.0
## The Fallen Street: the street has caved in between these x positions,
## down into the canals, from the front edge back to FALL_BACK. Behind it
## the street (and its houses) carry on.
const FALL_LEFT := 62.0
const FALL_RIGHT := 80.0
const FALL_BACK := -2.8
## The river crosses the street between these x positions.
const RIVER := Vector2(82.0, 120.0)
## The drain pipe under Well Square and Market Street: its left and right
## ends, its floor and its ceiling. The grate in the street over its left
## end opens from below (a shortcut back to the canals).
const PIPE := Vector2(-6.0, 54.0)
const PIPE_FLOOR := -4.6
const PIPE_TOP := -2.4
const GRATE_X := -3.6
const GRATE_WIDTH := 1.2
## At its left end the pipe opens into a low chamber just under the street
## (between these x positions), with steps up to the grate.
const CHAMBER := Vector2(-6.0, -1.5)
const CHAMBER_SLAB := 0.3
## The canal hall under the Fallen Street and the river, and its water.
const CANAL := Vector2(54.0, 136.8)
const CANAL_WATER := -6.4
## The shaft he climbs out of the canals by, east of the gatehouse.
const SHAFT := Vector2(134.4, 136.8)
## The Shrine Steps rise from the street (0) at the first x to the
## courtyard's height (1.5) at the second.
const STEPS := Vector2(158.0, 171.0)
const STEPS_TOP := 1.5
## The shrine courtyard past the torii, where the Weeping Hannya waits: its
## left and right x. (The level's right end is its right side.)
const ARENA := Vector2(47.0 + EAST, 63.5 + EAST)
## The torii at the courtyard's entrance, at the top of the steps.
const TORII_X := 46.0 + EAST

const STREET := Color(0.21, 0.225, 0.31)
const STREET_JOINT := Color(0.08, 0.09, 0.17)
const EARTH := Color(0.06, 0.07, 0.14)
const MOSS := Color(0.3, 0.34, 0.18)

@export_group("Light")
@export var moon_energy := 0.55
@export var ambient_energy := 0.45
@export var lantern_energy := 5.2
@export var lantern_range := 7.5
## How quickly lantern and window light fades with distance: higher makes a
## bright pool near the lantern that dies away into the night (realistic);
## lower lights everything around evenly (it looked flat). Was 1.3.
@export var light_falloff := 2.0
## Hung lanterns cast real shadows (posts, eaves and the Ronin shadow the
## walls behind them). Costs speed; off makes them shadowless again.
@export var lantern_shadows := true
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
@export_group("Daylight (the bamboo grove)")
@export var sun_energy := 1.7
@export var day_ambient := 0.6
@export var day_fog := 0.004
## Colour in the grove (the town's night is 0.8).
@export var day_saturation := 1.05
@export var day_contrast := 1.12

@export_group("Night in the Lantern Market")
## Warmer than the town's night (Julian's picture: gold lantern light, warm
## haze). The town is 0.8 saturation, 0.55-ish ambient.
@export var market_saturation := 1.05
@export var market_contrast := 1.08
@export var market_ambient := 0.55
@export var market_ambient_color := Color(0.86, 0.66, 0.52)
@export var market_fog_color := Color(0.36, 0.25, 0.22)

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
@export var enemy_positions: Array[Vector2] = [Vector2(27.5, 0.1), Vector2(44.0, 0.1), Vector2(143.0, 0.1), Vector2(87.0, 0.6)]
## Paper dogs, in the canals.
@export var dog_positions: Array[Vector2] = [Vector2(76.0, -4.1), Vector2(94.0, -4.9), Vector2(129.0, -4.7)]
## Paper birds: the middle of each one's loop, over the rooftops.
@export var bird_roosts: Array[Vector2] = [Vector2(52.0, 10.0), Vector2(70.5, 12.2), Vector2(90.0, 9.6)]
## Bundles of paper cranes: [name, x, y, depth, how many]. (A sixth is in
## Market Street's back room: SecretRoom.)
const CRANE_BUNDLES := [
	["gallery_roof", 32.0, 5.64, -0.6, 5], ["chamber", -5.4, -2.0, -1.4, 3], ["ruin", 72.4, 8.6, -0.7, 4],
	["canal_ledge", 115.0, -5.6, -1.6, 6], ["lookout", 134.5, 11.5, -0.6, 7], ["canal_end", 136.1, -4.8, -1.8, 4],
	["far_deck", 117.6, 6.4, -0.6, 9]]
## Little birds perched about the village: [x, y, depth, how many].
const PERCHES := [[3.0, 2.38, -2.2, 4], [64.5, 1.12, -3.2, 3], [49.5, 7.75, -1.1, 3], [92.0, 1.85, -1.2, 4],
	[124.4, 6.32, -5.7, 5], [164.6, 3.38, -2.3, 2]]
## Lantern husks (they throw burning paper).
@export var lantern_husk_positions: Array[Vector2] = [Vector2(111.0, 0.8), Vector2(148.0, 0.1)]

var _rng := RandomNumberGenerator.new()
## The Hannya's shrine hall in the courtyard (built by _build_arena).
var stage: HannyaStage
## The courtyard's stone lanterns: {light, fire, shine, energy, glow}.
var arena_lanterns: Array[Dictionary] = []
var _seal_wall: StaticBody3D
var _env: Environment
var _moon: DirectionalLight3D
var daylight := false
var _seal_sheet: MeshInstance3D
var _seal_pool: InkPool
var _seal_jets: CPUParticles3D
var _lanterns: Array[Node3D] = []
var _bead_picture: GradientTexture2D
## The dark foreground strips and grass: lowered out of the way when the
## camera goes down into the canals (see _process).
var _near: Node3D
## The areas of the expanded village (built in _ready).
var canals: Canals
var river: RiverBridge
var gatehouse: Gatehouse
var steps: ShrineSteps
var fallen: FallenStreet
var rooftops: RooftopRoad
var bamboo: BambooGrove
var lantern_market: LanternMarket
## The invisible wall at the courtyard's far end (gone when its gate opens).
var east_wall: StaticBody3D
var market: MarketStreet


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
	_build_climb_course()
	_build_arena()
	# The areas of the expanded village (docs/village_map.png).
	var yard := PaperMakerYard.new()
	yard.position = Vector3(1.0, 0.0, 0.0)
	add_child(yard)
	market = MarketStreet.new()
	market.village = self
	add_child(market)
	rooftops = RooftopRoad.new()
	rooftops.village = self
	add_child(rooftops)
	fallen = FallenStreet.new()
	fallen.village = self
	add_child(fallen)
	canals = Canals.new()
	canals.village = self
	add_child(canals)
	river = RiverBridge.new()
	river.village = self
	add_child(river)
	gatehouse = Gatehouse.new()
	gatehouse.village = self
	add_child(gatehouse)
	steps = ShrineSteps.new()
	steps.village = self
	add_child(steps)
	bamboo = BambooGrove.new()
	bamboo.village = self
	add_child(bamboo)
	# The Lantern Market, past the bamboo (its own place; the town's random
	# draws are put back afterwards, so nothing in the town changes).
	var saved_rng: int = _rng.state
	lantern_market = LanternMarket.new()
	lantern_market.village = self
	add_child(lantern_market)
	_rng.state = saved_rng
	_build_foreground()
	for spot: Vector2 in enemy_positions:
		var husk: Node3D = HUSK_SCENE.instantiate()
		husk.position = Vector3(spot.x, spot.y, 0.0)
		add_child(husk)
	for spot: Vector2 in dog_positions:
		var dog := PaperDog.new()
		dog.position = Vector3(spot.x, spot.y, 0.0)
		add_child(dog)
	for spot: Vector2 in bird_roosts:
		var bird := PaperBird.new()
		bird.position = Vector3(spot.x, spot.y, 0.0)
		add_child(bird)
	for perch: Array in PERCHES:
		var flock := PerchedBirds.new()
		flock.count = perch[3]
		flock.position = Vector3(perch[0], perch[1], perch[2])
		add_child(flock)
	for c: Array in CRANE_BUNDLES:
		var bundle := CraneBundle.new()
		bundle.id = c[0]
		bundle.count = c[4]
		bundle.position = Vector3(c[1], c[2], c[3])
		add_child(bundle)
	for spot: Vector2 in lantern_husk_positions:
		var keeper := LanternHusk.new()
		keeper.position = Vector3(spot.x, spot.y, 0.0)
		add_child(keeper)


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
	# (Only those near the camera: swinging all ~740 in the world every frame
	# cost frames for nothing.)
	var cam_x := camera_x()
	for node: Node3D in get_tree().get_nodes_in_group(&"windswept"):
		var at_x := node.global_position.x
		if absf(at_x - cam_x) > 40.0:
			continue
		var blow := Wind.speed_at(at_x)
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
	# The dark foreground strips sink out of the way when the camera goes
	# down into the canals (a little faster than the camera, so they slide
	# off the bottom of the view like scenery being lowered on a stage).
	var camera := get_viewport().get_camera_3d()
	if _near and camera:
		_near.position.y = minf(camera.global_position.y - 4.2, 0.0) * 1.6


## Where the camera is along x (for leaving far things still).
func camera_x() -> float:
	var camera := get_viewport().get_camera_3d()
	return camera.global_position.x if camera else 0.0


## Lit windows (by their house's x) whose storm shutters slide shut as he
## passes, instead of a shadow behind them.
const SHUTTERS := [35.6, 139.6]


## Height of the street at a given x (ignoring holes): level, then up the
## Shrine Steps to the courtyard.
func _street_height(x: float) -> float:
	if x <= STEPS.x:
		return 0.0
	if x >= STEPS.y:
		return STEPS_TOP
	return STEPS_TOP * (x - STEPS.x) / (STEPS.y - STEPS.x)


## True where there is a hole in the street at x (the Fallen Street, the
## river, the shaft out of the canals, the drain grate when open).
static func is_hole(x: float) -> bool:
	return (x > FALL_LEFT and x < FALL_RIGHT) or (x > RIVER.x and x < RIVER.y) or (x > SHAFT.x and x < SHAFT.y)


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
	_env = env

	# Moonlight. It shines from the front, so each paper layer casts a soft
	# shadow onto the layer behind it. That is what sells the diorama look.
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.64, 0.72, 0.96)
	moon.light_energy = moon_energy
	moon.rotation_degrees = Vector3(-42.0, 24.0, 0.0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 45.0
	add_child(moon)
	_moon = moon


## Night in the town, day in the bamboo grove (Julian's picture: warm sun,
## golden haze). Switched at once, while the screen is black between them.
func set_daylight(on: bool) -> void:
	daylight = on
	if on:
		_env.background_color = Color(0.93, 0.87, 0.72)
		_env.ambient_light_color = Color(1.0, 0.93, 0.8)
		_env.ambient_light_energy = day_ambient
		_env.fog_light_color = Color(0.9, 0.86, 0.72)
		_env.fog_density = day_fog
		_env.adjustment_saturation = day_saturation
		_env.adjustment_contrast = day_contrast
		_moon.light_color = Color(1.0, 0.86, 0.62)
		_moon.light_energy = sun_energy
		_moon.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	else:
		_env.background_color = Color(0.04, 0.045, 0.12)
		_env.ambient_light_color = Color(0.5, 0.55, 0.8)
		_env.ambient_light_energy = ambient_energy
		_env.fog_light_color = Color(0.2, 0.24, 0.46)
		_env.fog_density = fog_density
		_env.adjustment_saturation = color_saturation
		_env.adjustment_contrast = color_contrast
		_moon.light_color = Color(0.64, 0.72, 0.96)
		_moon.light_energy = moon_energy
		_moon.rotation_degrees = Vector3(-42.0, 24.0, 0.0)


## The warm night of the Lantern Market (on), or back to the town's (off).
## Switched while the screen is black.
## Only the place he is in runs and is drawn: the town, the bamboo grove or
## the Lantern Market (Julian: the market grew laggy; the whole town and
## grove were still running and being culled every frame there). The moon
## and the world's settings are shared and stay.
func set_place(place: StringName) -> void:
	if place == _place:
		return
	_place = place
	for c: Node in get_children():
		# (Solid ground and walls stay: the grove's and the market's are kept
		# here too, and a resting body leaves the physics: he fell through.)
		if c is WorldEnvironment or c is DirectionalLight3D or c is CollisionObject3D:
			continue
		var on := _place_of(c) == place
		c.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		if c is Node3D:
			(c as Node3D).visible = on


var _place := &""
var _places := {}


## Which place a piece of the level belongs to, by where it stands (some of
## the market's paving and splashes are built here, not in the market: hidden
## with the town they left the market's street bare).
func _place_of(c: Node) -> StringName:
	if c == bamboo:
		return &"grove"
	if c == lantern_market:
		return &"market"
	if _places.has(c):
		return _places[c]
	var x := 0.0
	var found := false
	for m: Node in [c] + c.find_children("*", "VisualInstance3D", true, false):
		if m is VisualInstance3D and is_instance_valid(m):
			var box: AABB = (m as VisualInstance3D).global_transform * (m as VisualInstance3D).get_aabb()
			x = box.get_center().x
			found = true
			break
	if not found and c is Node3D:
		x = (c as Node3D).global_position.x
	var where := &"town"
	if x > LanternMarket.SHIFT - 100.0:
		where = &"market"
	elif x > BambooGrove.SHIFT - 100.0:
		where = &"grove"
	_places[c] = where
	return where


func set_market(on: bool) -> void:
	set_daylight(false)
	if on:
		_env.ambient_light_color = market_ambient_color
		_env.ambient_light_energy = market_ambient
		_env.fog_light_color = market_fog_color
		_env.adjustment_saturation = market_saturation
		_env.adjustment_contrast = market_contrast
		_env.background_color = LanternMarket.NIGHT


# --- Houses -----------------------------------------------------------------

func _build_houses() -> void:
	# [x, width, wall height, window lit?, extras, which side the lantern hangs (-1, 0 = none, 1)]
	var street := [
		# Well Square, and the Paper-Maker's workshop (wide, low, lit).
		[-13.0, 6.5, 4.3, true, ["noren", "brace"], 1],
		[-4.5, 6.0, 5.2, true, ["round"], 1],
		[5.6, 9.2, 4.4, true, ["awning", "brace", "sudare", "firewood"], 1],
		# Market Street: shops, some with tea-house curtains.
		[17.2, 5.6, 4.6, true, ["noren_indigo", "pots"], 1],
		[23.4, 5.8, 5.0, false, ["brace", "awning", "shutters", "buckets"], 0],
		[29.6, 5.4, 4.4, true, ["round", "umbrella"], -1],
		[35.6, 6.0, 5.2, true, ["brace", "blind", "pots", "firewood"], 1],
		[42.0, 5.6, 4.6, false, ["awning", "shutters", "umbrella"], 0],
		[48.2, 6.2, 5.0, true, ["round", "noren_indigo", "buckets"], 1],
		[54.6, 5.4, 4.2, true, ["brace", "pots", "umbrella"], -1],
		[60.6, 5.8, 4.8, false, ["awning", "firewood"], 1],
		# Behind the Fallen Street (on the strip of street that still stands
		# at the back), past the river, and along the road to the steps.
		[66.0, 5.4, 4.2, false, ["brace", "shutters"], 0],
		[80.6, 2.4, 4.0, false, ["pots"], 0],
		[139.6, 5.6, 4.6, true, ["round", "noren", "umbrella"], 1],
		[145.6, 5.2, 4.2, false, ["brace", "firewood", "buckets"], 0],
		[151.6, 5.8, 5.0, true, ["sudare", "pots"], -1],
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
			# Someone at home: their shadow on the shoji (the Paper-Maker at
			# her vat in her workshop), or a bamboo blind that unrolls.
			var shadow := VillagerShadow.new()
			var size: Vector2 = house.get_meta("window_size")
			shadow.window_size = size
			shadow.round_window = house.get_meta("window_round")
			if x in SHUTTERS and not shadow.round_window:
				shadow.shutter = true
			elif x == 5.6:
				# (She is out at her vat now; at her window, someone kneels
				# at some small work.)
				shadow.activity = "kneel"
			else:
				shadow.activity = ["pace", "kneel"][_rng.randi() % 2]
			shadow.position = window + Vector3(0.0, 0.0, 0.1)
			add_child(shadow)
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
## `shine` off for a lantern hung high above the street (it would be too far
## up to smear its light on the paving).
func _hang_lantern(hook: Vector3, string_length: float, size: float, shine: bool = true) -> void:
	var lantern := Scenery.lantern(_rng, lantern_glow, size, string_length)
	lantern.position = hook
	add_child(lantern)
	_lanterns.append(lantern)
	var light := _add_light(Vector3.ZERO, lantern_energy * size, lantern_range * size)
	if lantern_shadows:
		light.shadow_enabled = true
		light.shadow_bias = 0.08
		light.shadow_normal_bias = 1.5
		light.shadow_blur = 1.5
	light.reparent(lantern)
	light.position = (lantern.get_meta("light_at") as Vector3) + Vector3(0.0, 0.0, 0.7)
	if shine:
		_add_wet_shine(hook.x, _street_height(hook.x), size)


## The streak of lantern light on the wet stones.
## It lies flat on the street, so where the street is missing (over the pit)
## it is trimmed off; otherwise it would hang in mid-air over the hole.
func _add_wet_shine(x: float, ground: float, strength: float) -> void:
	if wet_shine <= 0.0:
		return
	var left := x - 1.1
	var right := x + 1.1
	for hole: Vector2 in [Vector2(FALL_LEFT, FALL_RIGHT), RIVER, SHAFT]:
		if ground == 0.0 and right > hole.x and left < hole.y:
			# Keep the piece that is on solid street.
			if x < (hole.x + hole.y) * 0.5:
				right = minf(right, hole.x - 0.05)
			else:
				left = maxf(left, hole.y + 0.05)
	if right - left < 0.4:
		return
	var shine := Scenery.reflection(Vector2(right - left, 9.0), Color(1.0, 0.6, 0.28, wet_shine * strength))
	shine.position = Vector3((left + right) * 0.5, ground + 0.015, -1.6)
	add_child(shine)


# --- Ground and platforms (the parts you can stand on) ----------------------

func _build_ground() -> void:
	# [left edge, right edge, height of the top surface, how thick it is (8 =
	# solid all the way down; thinner where a tunnel runs underneath),
	# crumbled left end?, crumbled right end?]
	for g: Array in [
			[-17.0, CHAMBER.x, 0.0, 8.0, false, false],
			[CHAMBER.x, GRATE_X - GRATE_WIDTH * 0.5, 0.0, CHAMBER_SLAB, false, false],
			[GRATE_X + GRATE_WIDTH * 0.5, CHAMBER.y, 0.0, CHAMBER_SLAB, false, false],
			[CHAMBER.y, CANAL.x, 0.0, -PIPE_TOP, false, false],
			[CANAL.x, FALL_LEFT, 0.0, 1.5, false, true],
			[FALL_RIGHT, RIVER.x, 0.0, 2.2, true, false],
			[RIVER.y, SHAFT.x, 0.0, 1.5, false, false],
			[SHAFT.y, STEPS.x, 0.0, 8.0, false, false],
			[STEPS.y, ARENA.y + 0.5, STEPS_TOP, 8.0, false, false]]:
		_build_ground_block(g[0], g[1], g[2], g[3], g[4], g[5])
	_build_grate_surround()
	# Invisible walls at both ends of the level.
	_add_solid(Vector3(-16.5, 10.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)
	east_wall = _add_solid(Vector3(ARENA.y + 0.5, 10.0, 0.0), Vector3(1.0, 40.0, 4.0))
	east_wall.set_meta(&"no_climb", true)


func _build_ground_block(left: float, right: float, top: float, thick: float = 8.0,
		broken_left: bool = false, broken_right: bool = false) -> void:
	var width := right - left
	var middle := (left + right) * 0.5
	var solid := _add_solid(Vector3(middle, top - thick * 0.5, -1.5), Vector3(width, thick, 6.0))
	if thick < 8.0:
		solid.set_meta(&"slab", true)
	# How far down the earth and the torn front reach (a slab over a tunnel
	# stops at the tunnel's ceiling).
	var deep := 10.0 if thick >= 8.0 else thick

	# The earth under the street (you only see its sides, at holes).
	var earth := PaperMesh.new(_rng.randi())
	earth.shade_jitter = 0.05
	earth.color = EARTH
	# (It stops a little short of the front edge, so its face does not sit
	# at exactly the same depth as the torn sheets there and flicker.)
	earth.box(Vector3(middle, top - deep * 0.5 - 0.02, (STREET_FRONT - 0.15 + STREET_BACK) * 0.5),
			Vector3(width, deep, STREET_FRONT - 0.15 - STREET_BACK))
	add_child(earth.build())

	_lay_paving(left, right, top, STREET_BACK, STREET_FRONT)

	_add_rain_splashes(left, right, top)

	# The front of the street: torn sheets stepping down toward the camera.
	var front := PaperMesh.new(_rng.randi())
	front.shade_jitter = 0.04
	front.color = Color(0.23, 0.245, 0.34)
	# Where the street breaks off at a hole, the ends crumble too, each layer
	# a little differently, instead of stopping in a straight cut. Over a
	# tunnel the torn layers stop at the tunnel's ceiling.
	var bottom := top - (12.0 if thick >= 8.0 else thick)
	front.torn_sheet(_torn_band(left, right, top, maxf(top - 1.2, bottom), 0.0, broken_left, broken_right), STREET_FRONT, Color(0.5, 0.54, 0.68), 0.03)
	front.color = Color(0.125, 0.135, 0.22)
	if top - 0.3 > bottom + 0.15:
		front.torn_sheet(_torn_band(left, right, top - 0.3, bottom, 0.13, broken_left, broken_right), STREET_FRONT + 0.1, Color(0.24, 0.265, 0.39), 0.03)
	front.color = Color(0.07, 0.076, 0.14)
	if top - 0.82 > bottom + 0.2:
		front.torn_sheet(_torn_band(left, right, top - 0.82, bottom, 0.22, broken_left, broken_right), STREET_FRONT + 0.2, Color(0.15, 0.165, 0.27), 0.03)
	# Loose chunks of stone in the broken edge, on each of the three layers.
	# Each chunk gets its own depth, a few millimetres from its neighbours:
	# two sheets at exactly the same depth flicker where they overlap.
	var chunk_number := 0
	var cx := left + 0.5
	while cx < right - 0.7:
		var layer := _rng.randi_range(0, 2)
		var drop: float = maxf(minf([0.17, 0.62, 1.15][layer], thick - 0.45), 0.08)
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


## The street around the drain grate in Well Square. The ground there is
## left out only where the grate itself lies (its own width and depth, a
## stone-lined opening down into the chamber); in front of and behind it
## the paving, the earth and the street's torn front edge carry on. (It used
## to be a slot cut right across the street, which looked wrong once the
## grate was open.)
func _build_grate_surround() -> void:
	var gl := GRATE_X - GRATE_WIDTH * 0.5
	var gr := GRATE_X + GRATE_WIDTH * 0.5
	var half := 1.12
	_lay_paving(gl, gr, 0.0, STREET_BACK, -half)
	_lay_paving(gl, gr, 0.0, half, STREET_FRONT)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.05
	b.color = EARTH
	b.box(Vector3(GRATE_X, -CHAMBER_SLAB * 0.5 - 0.02, (STREET_BACK - half) * 0.5), Vector3(GRATE_WIDTH, CHAMBER_SLAB, -half - STREET_BACK))
	b.box(Vector3(GRATE_X, -CHAMBER_SLAB * 0.5 - 0.02, (STREET_FRONT - 0.15 + half) * 0.5), Vector3(GRATE_WIDTH, CHAMBER_SLAB, STREET_FRONT - 0.15 - half))
	# The opening's stone sides (a dressed curb), going down to the chamber.
	b.color = Color(0.17, 0.18, 0.26)
	for z: float in [-half - 0.04, half + 0.04]:
		b.box(Vector3(GRATE_X, -0.2, z), Vector3(GRATE_WIDTH + 0.16, 0.4, 0.08))
	for x: float in [gl - 0.04, gr + 0.04]:
		b.box(Vector3(x, -0.2, 0.0), Vector3(0.08, 0.4, half * 2.0 + 0.16))
	# A pale worn lip round it, where feet and carts have rubbed the stone.
	b.color = Color(0.3, 0.32, 0.42)
	for z: float in [-half - 0.04, half + 0.04]:
		b.box(Vector3(GRATE_X, 0.005, z), Vector3(GRATE_WIDTH + 0.16, 0.02, 0.1))
	for x: float in [gl - 0.04, gr + 0.04]:
		b.box(Vector3(x, 0.005, 0.0), Vector3(0.1, 0.02, half * 2.0 + 0.16))
	add_child(b.build())
	# The street's torn front edge, across the grate's width too.
	var front := PaperMesh.new(_rng.randi())
	front.shade_jitter = 0.04
	front.color = Color(0.23, 0.245, 0.34)
	front.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(gl - 0.05, 0.0), Vector2(gr + 0.05, 0.0),
			Vector2(gr + 0.05, -CHAMBER_SLAB - 0.05), Vector2(gl - 0.05, -CHAMBER_SLAB - 0.05)]), 0.25, 0.02, _rng), STREET_FRONT - 0.004,
			Color(0.5, 0.54, 0.68), 0.03)
	var cliff := front.build()
	cliff.cast_shadow = OFF
	add_child(cliff)


## Outline of a long strip whose top edge is broken into flat runs and sudden
## steps, like the edge of cracked stone, for the torn front of the street.
func _torn_band(left: float, right: float, top: float, bottom: float, rough: float,
		broken_left: bool = false, broken_right: bool = false) -> PackedVector2Array:
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
	if broken_right:
		outline.append_array(_crumbled_end(right, y, bottom, -1.0))
	outline.append(Vector2(right, bottom))
	outline.append(Vector2(left, bottom))
	if broken_left:
		var up := _crumbled_end(left, outline[0].y, bottom, 1.0)
		up.reverse()
		outline.append_array(up)
	return outline


## The broken end of the street at the pit: a jagged line running down from
## `top` to `bottom`, bitten inward (toward `inward`) by up to a third of a
## metre in short steps, like crumbled stone. Never outward, so no paper
## hangs out over the hole.
func _crumbled_end(x: float, top: float, bottom: float, inward: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var y := top - _rng.randf_range(0.05, 0.15)
	while y > bottom + 0.3:
		var bite := _rng.randf_range(0.04, 0.3)
		points.append(Vector2(x + inward * bite, y))
		y -= _rng.randf_range(0.12, 0.4)
	return points


## Wet paving stones between two x positions and two depths.
func _lay_paving(left: float, right: float, top: float, back: float, front: float) -> void:
	# The wet paving, in short lengths so no piece is touched by too many
	# lights at once (the web renderer allows about 8 per piece).
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 4.5, right)
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.08
		b.wrinkle_depth = 1.0
		b.color = STREET
		var z := back
		while z < front - 0.01:  # rows of paving stones
			var z1 := minf(z + 1.15, front)
			var sx := x
			while sx < x1 - 0.01:
				var sx1 := minf(sx + _rng.randf_range(1.2, 1.9), x1)
				b.quad(Vector3(sx + 0.02, top, z + 0.02), Vector3(sx1 - 0.02, top, z + 0.02),
						Vector3(sx1 - 0.02, top, z1 - 0.02), Vector3(sx + 0.02, top, z1 - 0.02), Vector3.UP)
				sx = sx1
			z = z1
		b.color = STREET_JOINT
		b.quad(Vector3(x, top - 0.01, back), Vector3(x1, top - 0.01, back),
				Vector3(x1, top - 0.01, front), Vector3(x, top - 0.01, front), Vector3.UP)
		var paving := b.build()
		var wet := paving.material_override as StandardMaterial3D
		wet.roughness = 0.38
		wet.metallic_specular = 0.6
		paving.cast_shadow = OFF
		add_child(paving)
		x = x1


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


# --- The climbing course: two tall walls to wall-jump up ----------------------

## [left edge, right edge, height of the top, opening underneath, roof?] of
## each climbable wall. They stand on the raised street just before the torii.
## The first is raised on timber posts like a gatehouse, so you walk under it
## into the gap between the two; wall jumping zig-zags up the gap; the taller
## one has a lookout ledge on top.
## (The Gatehouse, area 5: the first wall is the gatehouse itself, with the
## barred gate under it; the second is a tall tower you also walk under.)
const CLIMB_WALLS := [[128.5, 129.8, 8.5, 2.5, true], [132.2, 133.3, 11.5, 2.5, false]]
## How far above a wall's top its little roof's ridge reaches. The solid part
## of the wall goes up this far too, so you stand ON the ridge, not in the tiles.
const CLIMB_ROOF := 0.62


func _build_climb_course() -> void:
	for w: Array in CLIMB_WALLS:
		_build_climb_wall(w[0], w[1], _street_height(w[0]), w[2], w[3], w[4])
	# The lookout: planks across the top of the tall wall, reaching out over
	# the torii side, with a lantern on a post at the far end.
	var tall: Array = CLIMB_WALLS[CLIMB_WALLS.size() - 1]
	var top: float = tall[2]
	var ledge_left: float = tall[0]
	var ledge_right: float = tall[1] + 1.6
	_add_solid(Vector3((ledge_left + ledge_right) * 0.5, top - 0.15, 0.0), Vector3(ledge_right - ledge_left, 0.3, 2.2))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.22
	b.color = Scenery.WOOD
	var x := ledge_left
	while x < ledge_right - 0.01:
		var x1 := minf(x + _rng.randf_range(0.45, 0.7), ledge_right)
		b.box(Vector3((x + x1) * 0.5, top - 0.11, 0.0), Vector3(x1 - x - 0.03, 0.22, 2.2))
		x = x1
	b.color = Color(0.45, 0.4, 0.42)
	b.box(Vector3((ledge_left + ledge_right) * 0.5, top - 0.02, 1.1), Vector3(ledge_right - ledge_left, 0.04, 0.04))
	# A timber bracket under the part that reaches out, back into the wall.
	b.color = PaperMesh.TIMBER
	b.extrude(PackedVector2Array([Vector2(tall[1], top - 1.3), Vector2(ledge_right - 0.2, top - 0.22),
			Vector2(ledge_right - 0.45, top - 0.22), Vector2(tall[1], top - 1.1)]), -0.08, 0.08)
	# The lantern post, standing on the far end of the ledge.
	b.box(Vector3(ledge_right - 0.2, top + 0.9, -0.6), Vector3(0.1, 1.8, 0.1))
	b.box(Vector3(ledge_right - 0.5, top + 1.75, -0.6), Vector3(0.7, 0.08, 0.08))
	add_child(b.build())
	# It hangs on the downwind (left) side of its arm, clear of the post.
	_hang_lantern(Vector3(ledge_right - 0.75, top + 1.72, -0.6), 0.2, 0.75, false)


## One climbable wall: a tall storehouse wall of dark boards with pale paper
## plaster torn over them, timber posts at its corners, beams across it,
## stains and ink drips, and a small tiled roof on top. It is solid all the
## way through, so it looks right from every angle the camera reaches.
## With an `opening`, the wall starts that high above the street, carried on
## four corner posts (in front of and behind the path), with a heavy sill
## beam along its underside: a gatehouse you walk through.
func _build_climb_wall(left: float, right: float, street: float, top: float, opening: float = 0.0,
		roofed: bool = true) -> void:
	var width := right - left
	var middle := (left + right) * 0.5
	var ground := street + opening  # where the wall itself begins
	var height := top - ground
	var solid_top := top + (CLIMB_ROOF if roofed else 0.0)
	var wall := _add_solid(Vector3(middle, (ground + solid_top) * 0.5, 0.0), Vector3(width, solid_top - ground, 2.2))
	wall.set_meta(&"climbable", true)
	if left == CLIMB_WALLS[0][0]:
		# The gatehouse: its outer (west) face is sheer, so the barred gate
		# cannot just be climbed over from outside; inside the course (its
		# east face) it climbs like the others.
		wall.queue_free()
		var outer := _add_solid(Vector3(left + width * 0.25, (ground + solid_top) * 0.5, 0.0), Vector3(width * 0.5, solid_top - ground, 2.2))
		outer.set_meta(&"sheer", true)
		var inner := _add_solid(Vector3(left + width * 0.75, (ground + solid_top) * 0.5, 0.0), Vector3(width * 0.5, solid_top - ground, 2.2))
		inner.set_meta(&"climbable", true)
	if opening > 0.0:
		var frame := PaperMesh.new(_rng.randi())
		frame.shade_jitter = 0.18
		frame.color = PaperMesh.TIMBER
		# The sill: a heavy beam the whole depth of the wall, under it.
		frame.box(Vector3(middle, ground - 0.1, 0.0), Vector3(width + 0.16, 0.22, 2.3))
		# The posts it stands on, at its four corners, clear of the path.
		for pz: float in [1.02, -1.02]:
			for px: float in [left + 0.08, right - 0.08]:
				frame.box(Vector3(px, street + opening * 0.5, pz), Vector3(0.16, opening, 0.16))
			# A knee brace from each pair of posts up under the sill.
			frame.extrude(PackedVector2Array([Vector2(left + 0.16, ground - 0.6), Vector2(middle - 0.04, ground - 0.21),
					Vector2(middle - 0.2, ground - 0.21), Vector2(left + 0.16, ground - 0.42)]), pz - 0.05, pz + 0.05)
			frame.extrude(PackedVector2Array([Vector2(right - 0.16, ground - 0.6), Vector2(right - 0.16, ground - 0.42),
					Vector2(middle + 0.2, ground - 0.21), Vector2(middle + 0.04, ground - 0.21)]), pz - 0.05, pz + 0.05)
		add_child(frame.build())

	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.06
	b.color = Scenery.WALL_DARK
	b.box(Vector3(middle, ground + height * 0.5, 0.0), Vector3(width - 0.04, height, 2.16))
	# Plaster on the face toward the camera, torn off near the ground.
	b.color = Scenery.WALL_PAPER
	var sheet := PackedVector2Array([Vector2(left + 0.1, top - 0.25)])
	sheet.append(Vector2(right - 0.1, top - 0.25))
	var y := top - 0.25
	var base := ground + (0.3 if opening > 0.0 else _rng.randf_range(0.9, 1.4))
	while y > base + 0.4:  # the right edge, flaking a little
		y -= _rng.randf_range(0.6, 1.4)
		sheet.append(Vector2(right - 0.1 - _rng.randf_range(0.0, 0.08), maxf(y, base)))
	var tx := right - 0.1
	while tx > left + 0.2:  # the torn bottom
		tx -= _rng.randf_range(0.12, 0.22)
		sheet.append(Vector2(maxf(tx, left + 0.1), base + _rng.randf_range(-0.25, 0.3)))
	y = base
	while y < top - 0.9:  # the left edge
		y += _rng.randf_range(0.6, 1.4)
		sheet.append(Vector2(left + 0.1 + _rng.randf_range(0.0, 0.08), minf(y, top - 0.4)))
	b.torn_sheet(sheet, 1.105, Scenery.WALL_PAPER_RIM, 0.025)
	# A couple of damp stains, and ink running down from the beams.
	var stain_z := 1.112
	for i in 2:
		var at := Vector2(middle + _rng.randf_range(-0.15, 0.15), _rng.randf_range(base + 1.0, top - 1.0))
		var blot := PackedVector2Array()
		for k in 7:
			var angle := TAU * k / 7.0
			blot.append(at + Vector2(cos(angle) * _rng.randf_range(0.12, 0.25), sin(angle) * _rng.randf_range(0.3, 0.6)))
		b.color = Scenery.WALL_STAIN
		b.polygon(blot, stain_z)
		stain_z += 0.004
	# Beams across it every couple of metres, and posts up both front corners.
	b.color = PaperMesh.TIMBER
	var beam := ground + 2.3
	while beam < top - 0.6:
		b.box(Vector3(middle, beam, 1.08), Vector3(width + 0.06, 0.13, 0.16))
		b.color = Scenery.INK_DRIP
		var dx := left + _rng.randf_range(0.15, width - 0.15)
		b.polygon(PackedVector2Array([Vector2(dx - 0.02, beam - 0.06), Vector2(dx + 0.02, beam - 0.06),
				Vector2(dx + 0.008, beam - _rng.randf_range(0.35, 0.8)), Vector2(dx - 0.008, beam - 0.3)]), 1.13)
		b.color = PaperMesh.TIMBER
		beam += _rng.randf_range(2.1, 2.6)
	for px: float in [left + 0.07, right - 0.07]:
		b.box(Vector3(px, ground + height * 0.5, 1.06), Vector3(0.14, height, 0.16))
	add_child(b.build())

	# A small tiled roof, sloping both ways, so it is solid seen from the side.
	# It does not overhang the wall's sides, so nothing pokes out over the
	# faces you climb.
	if roofed:
		var roof_front := Scenery.tiled_roof(_rng, left, right, Vector2(top + 0.02, 1.35), Vector2(top + 0.4, 0.0), 3)
		add_child(roof_front)
		var roof_back := Scenery.tiled_roof(_rng, left, right, Vector2(top + 0.02, -1.35), Vector2(top + 0.4, 0.0), 3, false)
		add_child(roof_back)


# --- The shrine courtyard (the boss arena) ---------------------------------

func _build_arena() -> void:
	var ground := _street_height(ARENA.x)
	var middle := (ARENA.x + ARENA.y) * 0.5
	# The Hannya's shrine hall, its shoji screen facing the courtyard.
	stage = HannyaStage.new()
	stage.position = Vector3(middle, ground, -2.0)
	add_child(stage)
	var half: float = stage.screen_size.x * 0.5 + 0.8
	# An old wooden fence across the back of the courtyard, either side of it.
	for span: Vector2 in [Vector2(ARENA.x + 0.3, middle - half), Vector2(middle + half, ARENA.y - 0.3)]:
		var fence := Scenery.fence(_rng, span.y - span.x, 1.4)
		fence.position = Vector3(span.x, ground, -4.0)
		add_child(fence)
	# Two stone lanterns, one either side, lit.
	for x: float in [ARENA.x + 2.2, ARENA.y - 2.0]:
		_build_stone_lantern(Vector3(x, ground, -2.4))
	# An old cherry leaning over from behind the fence.
	var tree := Scenery.sakura_tree(_rng, 6.5, -0.12, 14)
	tree.position = Vector3(ARENA.y - 2.6, ground, -5.2)
	add_child(tree)


## Seals the courtyard's entrance during the fight (on) or opens it (off).
## A pool of ink spreads on the stones, then ink rises out of it into a dark,
## running wall, thinning toward its top, with droplets spurting up out of
## the pool and falling back; behind it, an invisible wall. Opening it, the ink sinks
## back into the pool, which shrinks away.
func set_arena_sealed(on: bool) -> void:
	var x := ARENA.x - 0.35
	var ground := _street_height(ARENA.x)
	if on and not _seal_wall:
		_seal_wall = _add_solid(Vector3(ARENA.x - 0.5, 8.0, 0.0), Vector3(1.0, 16.0, 4.0))
		_seal_wall.set_meta(&"no_climb", true)
		_seal_pool = InkPool.new()
		_seal_pool.size = 2.8
		add_child(_seal_pool)
		_seal_pool.position = Vector3(x, ground, 0.0)
		_seal_pool.open(0.35)
		_seal_pool.splash()
		Sound.play(self, &"ink_bleed", 6.0)
		# The wall of ink: a sheet that rises out of the pool.
		_seal_sheet = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.1, 6.5)
		quad.center_offset = Vector3(0.0, 3.25, 0.0)
		_seal_sheet.mesh = quad
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/ink_wall.gdshader")
		_seal_sheet.material_override = ink
		_seal_sheet.cast_shadow = OFF
		_seal_sheet.position = Vector3(x, ground, 0.3)
		_seal_sheet.rotation.y = 0.0
		add_child(_seal_sheet)
		# Droplets of ink spurting up out of the pool and falling back: soft
		# round drops, stretched a little as they fly (not hard rectangles).
		_seal_jets = CPUParticles3D.new()
		_seal_jets.amount = 60
		_seal_jets.lifetime = 1.0
		_seal_jets.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_seal_jets.emission_box_extents = Vector3(0.45, 0.02, 0.4)
		_seal_jets.direction = Vector3.UP
		_seal_jets.spread = 9.0
		_seal_jets.initial_velocity_min = 5.0
		_seal_jets.initial_velocity_max = 9.5
		_seal_jets.gravity = Vector3(0.0, -14.0, 0.0)
		_seal_jets.scale_amount_min = 0.6
		_seal_jets.scale_amount_max = 1.4
		var drop_size := Curve.new()
		drop_size.add_point(Vector2(0.0, 0.6))
		drop_size.add_point(Vector2(0.3, 1.0))
		drop_size.add_point(Vector2(1.0, 0.5))
		_seal_jets.scale_amount_curve = drop_size
		var drop := QuadMesh.new()
		drop.size = Vector2(0.11, 0.17)
		drop.material = PaperMesh.soft_ink(Color(0.015, 0.015, 0.035))
		_seal_jets.mesh = drop
		_seal_jets.cast_shadow = OFF
		_seal_jets.position = Vector3(x, ground + 0.05, 0.25)
		add_child(_seal_jets)
		var rise := create_tween()
		rise.tween_interval(0.25)
		rise.tween_method(func(v: float) -> void: ink.set_shader_parameter(&"rise", v), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif not on and _seal_wall:
		_seal_wall.queue_free()
		_seal_wall = null
		_seal_jets.emitting = false
		var sheet := _seal_sheet
		var pool := _seal_pool
		var jets := _seal_jets
		_seal_sheet = null
		_seal_pool = null
		_seal_jets = null
		var sink := create_tween()
		var look := sheet.material_override as ShaderMaterial
		sink.tween_method(func(v: float) -> void: look.set_shader_parameter(&"rise", v), 1.0, 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		sink.tween_callback(sheet.queue_free)
		sink.tween_callback(jets.queue_free)
		pool.close(0.5, 0.6)


## Puts out stone lantern `index` in the courtyard (for the cutscene): the
## flame gutters and dies over `time` seconds.
func snuff_arena_lantern(index: int, time: float = 0.6) -> void:
	if index >= arena_lanterns.size():
		return
	var lantern: Dictionary = arena_lanterns[index]
	var light: OmniLight3D = lantern["light"]
	var fire: StandardMaterial3D = lantern["fire"]
	var shine: GeometryInstance3D = lantern["shine"]
	var gutter := create_tween()
	gutter.tween_property(light, "light_energy", light.light_energy * 1.4, time * 0.15)
	gutter.tween_property(light, "light_energy", light.light_energy * 0.3, time * 0.2)
	gutter.tween_property(light, "light_energy", light.light_energy * 0.8, time * 0.15)
	gutter.tween_property(light, "light_energy", 0.0, time * 0.5)
	var dim := create_tween()
	dim.tween_interval(time * 0.3)
	dim.tween_property(fire, "emission_energy_multiplier", 0.0, time * 0.7)
	dim.parallel().tween_property(fire, "albedo_color", Color(0.12, 0.11, 0.14), time * 0.7)
	if shine:
		dim.parallel().tween_property(shine, "transparency", 1.0, time * 0.7)


## Lights the courtyard lanterns again (after the cutscene, or a retry).
func relight_arena_lanterns() -> void:
	for lantern: Dictionary in arena_lanterns:
		(lantern["light"] as OmniLight3D).light_energy = lantern["energy"]
		var fire: StandardMaterial3D = lantern["fire"]
		fire.emission_energy_multiplier = lantern["glow"]
		fire.albedo_color = Color.WHITE
		if lantern["shine"]:
			(lantern["shine"] as GeometryInstance3D).transparency = 0.0


## A stone lantern (toro): a foot, a post, a lit fire box with paper
## windows, and a cap. It gives off a real, low light.
## `arena`: one of the courtyard's (the Hannya cutscene puts those out).
func _build_stone_lantern(at: Vector3, arena: bool = true) -> void:
	var stone := Color(0.32, 0.33, 0.41)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	b.color = stone
	b.box(at + Vector3(0.0, 0.1, 0.0), Vector3(0.7, 0.2, 0.7))
	b.frustum(6, Vector2(0.16, 0.16), Vector2(0.13, 0.13), 0.9, at + Vector3(0.0, 0.2, 0.0))
	b.box(at + Vector3(0.0, 1.15, 0.0), Vector3(0.6, 0.12, 0.6))
	b.box(at + Vector3(0.0, 1.62, 0.0), Vector3(0.5, 0.06, 0.5))
	b.frustum(6, Vector2(0.52, 0.52), Vector2(0.08, 0.08), 0.34, at + Vector3(0.0, 1.65, 0.0))
	b.color = stone.darkened(0.2)
	for corner: Vector2 in [Vector2(-0.2, -0.2), Vector2(0.2, -0.2), Vector2(-0.2, 0.2), Vector2(0.2, 0.2)]:
		b.box(at + Vector3(corner.x, 1.39, corner.y), Vector3(0.08, 0.36, 0.08))
	add_child(b.build())
	var fire := PaperMesh.new(_rng.randi())
	fire.shade_jitter = 0.0
	fire.color = PaperMesh.LANTERN
	fire.box(at + Vector3(0.0, 1.39, 0.0), Vector3(0.3, 0.3, 0.3))
	var flame := fire.build(Color.WHITE, lantern_glow * 0.8)
	add_child(flame)
	var light := _add_light(at + Vector3(0.0, 1.4, 0.7), lantern_energy * 0.45, lantern_range * 0.6)
	var before := get_child_count()
	_add_wet_shine(at.x, at.y, 0.5)
	var shine: Node = get_child(get_child_count() - 1) if get_child_count() > before else null
	var fire_material := flame.material_override as StandardMaterial3D
	if not arena:
		return
	arena_lanterns.append({"light": light, "fire": fire_material, "shine": shine,
			"energy": light.light_energy, "glow": fire_material.emission_energy_multiplier})


# --- Props: the well, lanterns, a shoji screen, the torii --------------------

func _build_props() -> void:
	# The well, in the background behind where he walks (nothing to stand
	# on): he climbs out of it after the prologue (well_cutscene.gd).
	var well := Scenery.well(_rng)
	well.position = Vector3(WELL_X, 0.0, WELL_Z)
	add_child(well)
	_hang_lantern(Vector3(-9.45, 2.75, WELL_Z + 0.15), 0.25, 0.8)

	var gate := Scenery.torii(_rng, PaperMesh.VERMILION)
	gate.position = Vector3(TORII_X, 1.5, -1.3)
	add_child(gate)
	_hang_lantern(Vector3(TORII_X, 4.75, -1.0), 0.2, 0.8)

	var flag := Scenery.banner(_rng, 5.2)
	flag.position = Vector3(155.2, 0.0, -2.4)
	add_child(flag)

	# Clutter along the street: [what, x, depth, size, turn]
	for prop: Array in [["barrel", -1.2, -2.6, 1.0, 0.0], ["crate", -0.2, -2.9, 0.8, 0.3], ["barrel", 0.3, -2.3, 0.8, 0.0],
			["crate", 38.6, -2.9, 0.9, -0.2], ["crate", 39.0, -2.85, 0.6, 0.5], ["barrel", 14.3, -2.5, 1.0, 0.0],
			["barrel", 61.0, -2.5, 1.0, 0.0], ["barrel", 142.6, -2.6, 1.0, 0.0], ["crate", 143.4, -2.9, 0.8, 0.2],
			["crate", 126.0, -2.9, 0.9, 0.4], ["barrel", 81.2, -2.6, 0.8, 0.0]]:
		var thing: Node3D = Scenery.barrel(_rng, prop[3]) if prop[0] == "barrel" else Scenery.crate(_rng, prop[3])
		thing.position = Vector3(prop[1], _street_height(prop[1]), prop[2])
		thing.rotation.y = prop[4]
		if prop[0] == "crate" and prop[3] < 0.7:
			thing.position.y += 0.9  # the small crate sits on the big one
		add_child(thing)


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
	_near = Node3D.new()
	add_child(_near)
	# Two near-black torn strips along the bottom of the view. They follow the
	# height of the street so they never cover the Ronin's feet.
	var near := PaperMesh.new(_rng.randi())
	near.shade_jitter = 0.0
	near.texture_scale = 0.3
	for layer: Array in [[3.3, -0.5, Color(0.04, 0.047, 0.105), Color(0.12, 0.14, 0.27)],
			[4.2, -0.32, Color(0.018, 0.02, 0.05), Color(0.07, 0.085, 0.17)]]:
		var line := PackedVector2Array()
		var x := -34.0
		while x < ARENA.y + 3.0:
			var ground := lerpf(0.0, STEPS_TOP, smoothstep(STEPS.x - 1.0, STEPS.y + 1.0, x))
			line.append(Vector2(x, ground + layer[1] + _rng.randf_range(-0.16, 0.16)))
			x += _rng.randf_range(0.8, 2.2)
		var outline := PaperMesh.tear(line, 0.3, 0.05, _rng, false)
		outline.append(Vector2(ARENA.y + 3.0, -14.0))
		outline.append(Vector2(-34.0, -14.0))
		near.color = layer[2]
		near.torn_sheet(outline, layer[0], layer[3], 0.03)

	# Rocks and clumps of grass poking up from the dark.
	near.color = Color(0.03, 0.035, 0.08)
	var gx := -30.0
	while gx < ARENA.y - 1.0:
		var ground := lerpf(0.0, STEPS_TOP, smoothstep(STEPS.x - 1.0, STEPS.y + 1.0, gx))
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
			_near.add_child(grass)
			Scenery.windswept(grass, -0.03, _rng)
		gx += _rng.randf_range(1.5, 4.5)
	var dark := near.build(Color.WHITE, 0.0, true)
	(dark.material_override as StandardMaterial3D).disable_fog = true
	dark.cast_shadow = OFF
	_near.add_child(dark)


	# Cherry trees. One stands in the foreground at the start, its trunk at
	# the left of the view; the others stand on the street behind the Ronin.
	# [x, depth, height, lean, blossoms left, how much of it is bare trunk]
	for t: Array in [[-14.2, 2.6, 10.5, 0.9, 40, 0.56], [13.4, -2.0, 7.6, 0.8, 30, 0.42]]:
		var x: float = t[0]
		var tree := Scenery.sakura_tree(_rng, t[2], t[3], t[4], t[5])
		tree.position = Vector3(x, (_street_height(x) if t[1] < 0.0 else -0.9), t[1])
		add_child(tree)
		var crown: Vector2 = tree.get_meta(&"crown")
		_add_falling_petals(Vector2(x + crown.x, tree.position.y + crown.y), t[1])


## He dashed (Ronin.dashed): near a cherry tree, the fallen petals on
## the stones are stirred up in his wake and settle again.
func stir_petals(at: Vector3, direction: float) -> void:
	var near := false
	for x: float in [-14.2, 13.4, STEPS.x + 4.4, ARENA.y - 2.6, -8.0]:
		if absf(at.x - x) < 7.0:
			near = true
	if not near:
		return
	var swirl := CPUParticles3D.new()
	swirl.emitting = false
	swirl.one_shot = true
	swirl.explosiveness = 0.7
	swirl.amount = 18
	swirl.lifetime = 1.6
	swirl.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	swirl.emission_box_extents = Vector3(0.8, 0.02, 0.8)
	swirl.direction = Vector3(direction, 1.2, 0.0)
	swirl.spread = 35.0
	swirl.gravity = Vector3(-0.4, -1.2, 0.0)
	swirl.initial_velocity_min = 1.0
	swirl.initial_velocity_max = 2.4
	swirl.damping_min = 1.5
	swirl.damping_max = 2.5
	swirl.angle_max = 360.0
	swirl.angular_velocity_min = -300.0
	swirl.angular_velocity_max = 300.0
	var petal := QuadMesh.new()
	petal.size = Vector2(0.12, 0.08)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = PaperMesh.SAKURA.darkened(0.12)
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.disable_fog = true
	petal.material = look
	swirl.mesh = petal
	swirl.cast_shadow = OFF
	add_child(swirl)
	swirl.global_position = at + Vector3(-direction * 0.6, 0.05, 0.0)
	swirl.emitting = true
	swirl.finished.connect(swirl.queue_free)


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
	light.omni_attenuation = light_falloff
	light.position = at
	add_child(light)
	return light


## An invisible solid box the Ronin and enemies collide with.
func _add_solid(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child(body)
	return body
