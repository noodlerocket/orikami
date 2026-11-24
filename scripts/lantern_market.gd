class_name LanternMarket
extends Node3D
## The Lantern Market (chapter 3, docs/lore.md): Hōshō's city, past Akane's
## clearing at the end of the bamboo. Copied from Julian's picture
## (docs/reference/lantern_market.webp): a night market of folded paper in the
## rain, stalls under tiled roofs hung with crested lanterns and red noren,
## gilded paper-doll shopkeepers behind counters of fans, sweets, sake, fish
## and a smoking grill; red arched bridges; a hillside of glowing houses
## climbing to a golden pagoda palace; a crumpled gold moon; gold leaf
## drifting like snow; cherry trees at the back of the street;
## a dark railing along the bottom; wet stones shining gold.
##
## Like the grove it is its own place, built far off along x (SHIFT): walking
## east out of Akane's clearing (once she has yielded) fades to black and
## puts him at its west end (Main._travel); walking back out west returns
## him to the clearing.
##
## Left to right (local x): the misty way in and shrine 6; the Lower Market
## (ground 0); the red bridge rising over a canal to the Upper Market (3 m);
## stone steps up to the palace plaza (6.5 m) and the Gilded Gate, shut
## (Hōshō waits behind it: not built yet).

## How far along x the market really is.
const SHIFT := 2000.0
## Its east end: Hōshō's hall, at the top of the Gilded Terraces (the whole
## region: docs/lantern_market_plan.md).
const END := 482.0
## Where he arrives (local x), and how far west he may walk before he is
## taken back to the bamboo.
const ARRIVE_X := 3.0
const WEST_X := -1.0
## The ground: [left, right, top] of each stretch.
const LOWER := Vector3(-8.0, 58.0, 0.0)
const CANAL := Vector2(58.0, 72.0)
const UPPER := Vector3(72.0, 116.0, 3.0)
const STEPS := Vector2(116.0, 128.0)
## Festival Square, at the top of the steps (then the Canal Quarter:
## canal_quarter.gd).
const PLAZA := Vector3(128.0, 146.0, 6.5)
## The canal's water and its bed.
const WATER_Y := -0.9
const CANAL_BED := -1.6
## The red bridge: from the lower street, arching over the canal, down onto
## the upper street.
const BRIDGE := Vector2(55.0, 75.0)
const SHRINE_X := 8.0
## The stalls along the back: [x, wares, the keeper's robe].
const BOOTHS := [[14.0, "fans", Color(0.56, 0.18, 0.15)], [21.5, "sweets", Color(0.3, 0.24, 0.26)],
	[29.0, "sake", Color(0.24, 0.22, 0.3)], [36.5, "fish", Color(0.5, 0.36, 0.22)],
	[44.0, "grill", Color(0.62, 0.52, 0.38)], [51.5, "cranes", Color(0.52, 0.16, 0.16)],
	[87.5, "fans", Color(0.3, 0.26, 0.3)],   # (80: the burning store stands there)
	[95.0, "sake", Color(0.48, 0.34, 0.2)], [102.5, "grill", Color(0.6, 0.5, 0.36)],
	[110.0, "fish", Color(0.26, 0.24, 0.32)]]
## Stalls standing in the street, whose awnings bounce him up: [x, kind].
const STALLS := [[24.5, "produce"], [47.5, "noodles"], [92.0, "fish"]]
## Lantern strings across the street (cut down onto them to pogo): [left x, span].
const STRINGS := [[33.0, 10.0], [98.5, 9.0]]
## Walkways up high, reached off the awnings: [middle x, top, width], and the
## cranes hidden on them.
const GALLERIES := [[30.0, 5.2, 7.0], [96.0, 8.0, 6.0]]
const HUSKS := [Vector2(50.0, 0.0), Vector2(88.0, 3.0)]
const LANTERN_HUSKS := [Vector2(38.0, 0.0), Vector2(106.0, 3.0), Vector2(133.0, 6.5)]
## The colours of the picture.
const RED_CLOTH := Color(0.62, 0.17, 0.14)
const CREAM := Color(0.9, 0.84, 0.72)
const GOLD := Color(0.88, 0.7, 0.36)
const LACQUER := Color(0.64, 0.17, 0.13)
const BLOSSOM := Color(0.92, 0.7, 0.74)
const NIGHT := Color(0.05, 0.055, 0.12)
## The wet stones reach out toward us, to the railing (the picture's
## foreground of shining paving).
const NEAR_Z := 9.0

## How bright each stall's light is (times the town's lantern energy).
@export var booth_light := 1.15

var village: Village
var shrine: RestShrine
var _rng := RandomNumberGenerator.new()
var _far: Array[Node] = []
var _awake := true
var _glow := 1.6     # lantern paper glow
var _shimmer: Array[MeshInstance3D] = []   # lantern reflections on the water


## True when this (real, world) x is in the market.
## A storehouse in the Upper Market whose door is barred by a burning heap
## of stall screens: only the Fan Gust (learned later, after the dragon)
## puts it out; inside, cranes on the shelf. A reason to come back.
const STORE_X := 79.0


func _build_burning_store() -> void:
	var room := SecretRoom.new()
	room.crane_id = "market_store"
	room.crane_count = 8
	room.start_open = true
	room.position = Vector3(STORE_X, UPPER.z, 0.0)
	add_child(room)
	var fire := FireBarrier.new()
	fire.id = "market_store_fire"
	fire.position = Vector3(STORE_X - 1.1, UPPER.z, 0.0)
	add_child(fire)


static func in_market(x: float) -> bool:
	return x > SHIFT - 300.0


## Height of the ground at a local x (the bridge's deck over the canal).
static func ground_at(x: float) -> float:
	if x >= BRIDGE.x and x <= BRIDGE.y:
		return deck_at(x)
	if x < CANAL.x:
		return LOWER.z
	if x <= STEPS.x:
		return UPPER.z
	if x < STEPS.y:
		return lerpf(UPPER.z, PLAZA.z, (x - STEPS.x) / (STEPS.y - STEPS.x))
	if x <= PLAZA.y:
		return PLAZA.z
	return CanalQuarter.ground_at(x)


## The bridge's deck: rising from the lower street in an arch and coming down
## level onto the upper street.
static func deck_at(x: float) -> float:
	var t := clampf((x - BRIDGE.x) / (BRIDGE.y - BRIDGE.x), 0.0, 1.0)
	return LOWER.z + (UPPER.z - LOWER.z) * smoothstep(0.0, 1.0, t) + 1.1 * sin(PI * t)


func _ready() -> void:
	_rng.seed = 3301
	position.x = SHIFT
	_glow = village.lantern_glow
	_build_sky()
	_build_hillside()
	_build_midground()
	_build_ground()
	_build_canal()
	_build_bridge()
	_build_steps()
	for b: Array in BOOTHS:
		_booth(b[0], b[1], b[2])
	_fill_between_booths()
	_build_street_life()
	# (The Gilded Gate, _build_gate, moves to the region's far end when it is
	# built; past the square come the canals.)
	var quarter := CanalQuarter.new()
	quarter.market = self
	add_child(quarter)
	_build_foreground()
	_build_air()
	shrine = RestShrine.new()
	shrine.shrine_id = "market"
	shrine.position = Vector3(SHRINE_X, 0.0, -0.9)
	shrine.scale = Vector3.ONE * 1.3
	add_child(shrine)
	_build_burning_store()
	for spot: Vector2 in HUSKS:
		var husk: Node3D = Village.HUSK_SCENE.instantiate()
		husk.position = Vector3(spot.x, spot.y, 0.0)
		add_child(husk)
		_far.append(husk)
	for spot: Vector2 in LANTERN_HUSKS:
		var keeper := LanternHusk.new()
		keeper.position = Vector3(spot.x, spot.y, 0.0)
		add_child(keeper)
		_far.append(keeper)
	# The canal running under the bridge, and water dripping off the eaves.
	Sound.place_loop(self, "river_flow.ogg", Vector3(65.0, WATER_Y, -1.0), -14.0, 12.0)
	for x: float in [20.0, 46.0, 90.0, 110.0]:
		Sound.place_loop(self, "canal_drips.ogg", Vector3(x, ground_at(x) + 2.5, -2.5), -16.0, 8.0)
	# The ends: the way back west into the mist, the Gilded Gate shut east.
	_solid(Vector3(WEST_X - 3.0, 10.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)
	_solid(Vector3(END - 1.0, 14.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)


## The market's creatures and busy things rest while he is elsewhere.
func set_awake(on: bool) -> void:
	if on == _awake:
		return
	_awake = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	for n: Node in _far:
		if is_instance_valid(n):
			n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in _shimmer.size():
		var s := _shimmer[i]
		s.scale.x = 1.0 + 0.12 * sin(t * 2.3 + i * 1.7)
		s.position.x = s.get_meta(&"x") + 0.06 * sin(t * 1.6 + i)


func _solid(center: Vector3, size: Vector3) -> StaticBody3D:
	return village._add_solid(center + Vector3(SHIFT, 0.0, 0.0), size)


## A solid slope: a prism under the line from (x0, y0) to (x1, y1).
func _slope(x0: float, y0: float, x1: float, y1: float, depth: float = 0.5) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for z: float in [-1.4, 1.4]:
		pts.append(Vector3(x0, y0, z))
		pts.append(Vector3(x1, y1, z))
		pts.append(Vector3(x1, y1 - depth, z))
		pts.append(Vector3(x0, y0 - depth, z))
	hull.points = pts
	shape.shape = hull
	body.add_child(shape)
	add_child(body)


func _flat(b: PaperMesh) -> MeshInstance3D:
	var mesh := b.build(Color.WHITE, 0.0, true)
	(mesh.material_override as StandardMaterial3D).disable_fog = true
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


func _light(at: Vector3, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = PaperMesh.LANTERN
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = village.light_falloff
	light.position = at
	add_child(light)
	return light


## Where something standing at x has its foot: the ground, or the bed of a
## canal (over water things stand in it, down to the bottom).
static func foot_at(x: float) -> float:
	if x > CANAL.x and x < CANAL.y and not (x >= BRIDGE.x and x <= BRIDGE.y):
		return CANAL_BED
	if x > PLAZA.y:
		for w: Vector2 in CanalQuarter.WATERS:
			if x > w.x and x < w.y:
				return CanalQuarter.BED_Y
	return ground_at(x)


## A lantern hung under a house's eave (Scenery.house: the eave is at
## height - 0.25, reaching 1.75 m in front of the wall).
func _eave_lantern(house_at: Vector3, height: float, x: float, size: float = 1.0) -> void:
	_hang(Vector3(x, house_at.y + height - 0.4, house_at.z + 1.45), size, 0.3)


## A crested chochin hung from a hook (local), swaying in the wind.
func _hang(at: Vector3, size: float, string_length: float = 0.3, parent: Node3D = null) -> Node3D:
	if parent == null:
		parent = self
	var l := Scenery.lantern(_rng, _glow, size, string_length)
	l.position = at
	parent.add_child(l)
	Scenery.windswept(l, 0.035, _rng)
	return l


## Gold shine on the wet stones under a light.
func _shine(x: float, ground: float, width: float, strength: float, z: float = 1.6) -> void:
	var s := Scenery.reflection(Vector2(width, 10.0), Color(1.0, 0.64, 0.3, village.wet_shine * strength))
	s.position = Vector3(x, ground + 0.016, z)
	add_child(s)


# --- The sky and the far city ------------------------------------------------------

func _build_sky() -> void:
	var left := -120.0
	var right := END + 120.0
	var sky := PaperMesh.new(1)
	sky.shade_jitter = 0.0
	# (Up to 170 m: the dragon's cutscenes look up into the storm, and above
	# 70 m the bare background showed through.)
	sky.fade_quad(Vector3(left, 170.0, -53.0), Vector3(right, 170.0, -53.0), Vector3(right, 70.0, -53.0), Vector3(left, 70.0, -53.0),
			Color(0.02, 0.025, 0.06), Color(0.035, 0.04, 0.1))
	sky.fade_quad(Vector3(left, 70.0, -53.0), Vector3(right, 70.0, -53.0), Vector3(right, 14.0, -53.0), Vector3(left, 14.0, -53.0),
			Color(0.035, 0.04, 0.1), Color(0.1, 0.1, 0.19))
	sky.fade_quad(Vector3(left, 14.0, -53.0), Vector3(right, 14.0, -53.0), Vector3(right, -30.0, -53.0), Vector3(left, -30.0, -53.0),
			Color(0.1, 0.1, 0.19), Color(0.26, 0.18, 0.17))
	_flat(sky)
	# The moon: crumpled gold paper, its creases catching the light.
	var mx := 18.0
	var my := 19.0
	var moon := PaperMesh.new(_rng.randi())
	moon.shade_jitter = 0.0
	moon.color = Color(0.9, 0.78, 0.5)
	moon.ellipse(Vector2(mx, my), Vector2(4.6, 4.6), 36, -51.5, 0.025)
	for k in 14:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.4, 3.0)
		var c := Vector2(mx, my) + Vector2(cos(a), sin(a)) * r
		var facet := PackedVector2Array()
		for p in 4:
			var q := a + TAU * p / 4.0 + _rng.randf_range(-0.4, 0.4)
			facet.append(c + Vector2(cos(q), sin(q)) * _rng.randf_range(0.4, 1.1))
		moon.color = Color(0.9, 0.78, 0.5) * _rng.randf_range(0.82, 1.1)
		moon.polygon(facet, -51.48 + k * 0.001)
	_flat(moon)
	_glow_disc(Vector3(mx, my, -51.8), 4.0, 11.0, Color(0.95, 0.8, 0.5, 0.35))
	# Thin dark cloud across the moon and the sky.
	for cloud: Array in [[mx + 3.0, my - 1.5, 13.0, 0.9], [mx - 30.0, my + 4.0, 22.0, 1.4], [mx + 60.0, my + 2.0, 26.0, 1.2], [mx + 120.0, my - 2.0, 24.0, 1.3]]:
		var c := PaperMesh.new(_rng.randi())
		c.shade_jitter = 0.0
		var mid := Vector2(cloud[0], cloud[1])
		var outline := PackedVector2Array()
		for k in 20:
			var t := TAU * k / 20.0
			outline.append(mid + Vector2(cos(t) * cloud[2] * 0.5, sin(t) * cloud[3] * 0.5))
		c.color = Color(0.13, 0.13, 0.22)
		c.torn_sheet(PaperMesh.tear(outline, 0.7, 0.14, _rng), -51.0, Color(0.32, 0.3, 0.4), 0.06)
		_flat(c)
	# Mountains, dark and misty, folded ridges.
	for layer: Array in [[-47.0, 6.0, 14.0, Color(0.14, 0.15, 0.25), 0.07], [-43.0, 2.0, 10.0, Color(0.1, 0.11, 0.2), 0.11]]:
		var hills := PaperMesh.new(_rng.randi())
		hills.shade_jitter = 0.0
		var line := PackedVector2Array()
		var x := left
		var freq: float = layer[4]
		while x < right:
			line.append(Vector2(x, layer[1] + layer[2] * pow(absf(sin(x * freq + layer[0])), 1.4)))
			x += _rng.randf_range(2.0, 4.0)
		line.append(Vector2(right, layer[1]))
		var outline := PaperMesh.tear(line, 1.0, 0.25, _rng, false)
		outline.append(Vector2(right, -30.0))
		outline.append(Vector2(left, -30.0))
		hills.color = layer[3]
		hills.torn_sheet(outline, layer[0], (layer[3] as Color).lightened(0.25), 0.1)
		_flat(hills)
		_mist(layer[0] + 0.5, layer[1] - 2.0, layer[1] + 6.0, Color(0.36, 0.34, 0.44, 0.75))


## A soft round glow (a ring of quads fading out from the rim).
func _glow_disc(at: Vector3, inner: float, outer: float, tint: Color) -> void:
	var d := PaperMesh.new(1)
	for k in 32:
		var a0 := TAU * k / 32.0
		var a1 := TAU * (k + 1) / 32.0
		d.fade_quad(at + Vector3(cos(a0), sin(a0), 0.0) * inner, at + Vector3(cos(a1), sin(a1), 0.0) * inner,
				at + Vector3(cos(a1), sin(a1), 0.0) * outer, at + Vector3(cos(a0), sin(a0), 0.0) * outer,
				tint, Color(tint, 0.0))
	add_child(d.build_veil(true))


func _mist(z: float, bottom: float, top: float, tint: Color) -> void:
	var m := PaperMesh.new(1)
	m.fade_quad(Vector3(-120.0, bottom - 6.0, z), Vector3(END + 120.0, bottom - 6.0, z), Vector3(END + 120.0, top, z),
			Vector3(-120.0, top, z), tint, Color(tint, 0.0))
	add_child(m.build_veil())


## The hillside of houses climbing to the palace (right), each tier nearer
## and bigger; red bridges and strings of lanterns between them.
func _build_hillside() -> void:
	# [z, base height, rise to the right, house scale, wall tone, window brightness]
	for tier: Array in [[-38.0, 4.0, 13.0, 0.75, Color(0.16, 0.14, 0.2), 0.75], [-31.0, 1.5, 11.0, 0.95, Color(0.17, 0.14, 0.18), 0.85],
			[-24.0, -0.5, 8.0, 1.15, Color(0.18, 0.14, 0.16), 0.95], [-17.0, -2.0, 5.0, 1.35, Color(0.18, 0.13, 0.14), 1.0]]:
		_house_row(tier[0], tier[1], tier[2], tier[3], tier[4], tier[5])
	_palace(Vector3(128.0, 15.5, -40.0), 1.6)
	_palace(Vector3(36.0, 8.5, -44.0), 0.7)
	_glow_disc(Vector3(128.0, 24.0, -40.5), 5.0, 26.0, Color(1.0, 0.7, 0.35, 0.28))
	# Red arched bridges between the tiers (on legs), lanterns along them.
	for br: Array in [[18.0, -20.0, 4.5, 9.0], [66.0, -27.0, 8.0, 10.0], [104.0, -20.0, 7.5, 11.0], [-14.0, -27.0, 5.0, 8.0]]:
		_far_bridge(br[0], br[1], br[2], br[3])
	# Lantern strings across the hill (tied to poles).
	for s: Array in [[-30.0, 10.0, 6.5, 8.0, -21.0], [4.0, 40.0, 8.5, 10.0, -26.0], [40.0, 80.0, 10.5, 12.5, -33.0],
			[70.0, 110.0, 9.5, 13.0, -22.0], [100.0, 140.0, 14.0, 17.0, -30.0], [130.0, 170.0, 12.0, 9.0, -21.0]]:
		_far_string(Vector2(s[0], s[2]), Vector2(s[1], s[3]), s[4], 1.2)


## Behind the stalls: a stone terrace, and on it a row of tall shops and
## houses, their shoji lit, a red bridge between them (the picture's second
## tier), rising with the market.
func _build_midground() -> void:
	var z := -10.5
	var x := -14.0
	var stone := PaperMesh.new(_rng.randi())
	stone.shade_jitter = 0.2
	while x < END + 14.0:
		var w := _rng.randf_range(5.0, 7.0)
		var gap := _rng.randf_range(0.6, 1.6)
		var g := ground_at(clampf(x + w * 0.5, LOWER.x, END)) + 1.2
		if x + w * 0.5 > CANAL.x and x + w * 0.5 < CANAL.y + 2.0:
			g = UPPER.z + 1.2
		# The terrace wall under it (stone courses), lantern-lit.
		var y := g - 6.0
		while y < g - 0.01:
			var y1 := minf(y + 0.45, g)
			var sx := x
			while sx < x + w + gap - 0.01:
				var sx1 := minf(sx + _rng.randf_range(0.7, 1.3), x + w + gap)
				stone.color = Color(0.3, 0.28, 0.32) * _rng.randf_range(0.75, 1.05)
				stone.box(Vector3((sx + sx1) * 0.5, (y + y1) * 0.5, z + 2.0), Vector3(sx1 - sx - 0.03, y1 - y - 0.03, 0.3))
				sx = sx1
			y = y1
		# The terrace itself behind the wall: solid ground the houses stand
		# on, reaching back past them (they floated over nothing: Julian).
		stone.color = Color(0.2, 0.19, 0.23)
		stone.box(Vector3(x + (w + gap) * 0.5, g - 3.0, (z + 1.85 + z - 4.0) * 0.5), Vector3(w + gap, 6.0, 5.85))
		var hh := _rng.randf_range(3.6, 4.8)
		var house := Scenery.house(_rng, w, hh, _rng.randf() < 0.85, village.window_glow,
				[["round"], ["noren"], ["awning"], ["sudare"], []][_rng.randi() % 5])
		house.position = Vector3(x + w * 0.5, g, z)
		add_child(house)
		# A lantern at its eave, and its light on the terrace.
		if _rng.randf() < 0.6:
			_eave_lantern(house.position, hh, x + w * 0.5 + _rng.randf_range(-1.5, 1.5))
		x += w + gap
	add_child(stone.build())
	for lx: float in [10.0, 40.0, 82.0, 120.0]:
		_light(Vector3(lx, ground_at(lx) + 5.5, -7.0), village.lantern_energy * 0.8, village.lantern_range * 1.4)
	# A red bridge between two houses up there, people crossing it.
	for br: Array in [[25.0, 9.5], [104.0, 12.5]]:
		_mid_bridge(br[0], br[1], z - 2.5)


func _mid_bridge(x: float, y: float, z: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	var span := 9.0
	var prev := Vector2.INF
	for k in 19:
		var t := k / 18.0
		var px := x - span * 0.5 + span * t
		var py := y + 0.9 * sin(PI * t)
		if prev != Vector2.INF:
			b.color = LACQUER
			b.extrude(PackedVector2Array([Vector2(prev.x, prev.y - 0.35), Vector2(px, py - 0.35), Vector2(px, py), Vector2(prev.x, prev.y)]), z - 0.8, z + 0.8)
			b.color = LACQUER.darkened(0.1)
			b.extrude(PackedVector2Array([Vector2(prev.x, prev.y + 0.85), Vector2(px, py + 0.85), Vector2(px, py + 0.93), Vector2(prev.x, prev.y + 0.93)]), z + 0.75, z + 0.82)
		if k % 3 == 0:
			b.color = LACQUER
			b.box(Vector3(px, py + 0.45, z + 0.78), Vector3(0.08, 0.9, 0.08))
		prev = Vector2(px, py)
	add_child(b.build())
	# It joins two watchtowers standing on the terrace, entering each by a
	# lit doorway (it led nowhere: Julian).
	for side: float in [-1.0, 1.0]:
		var tx := x + side * (span * 0.5 + 1.1)
		var foot := ground_at(clampf(tx, LOWER.x, END)) + 1.2
		if tx > CANAL.x and tx < CANAL.y + 2.0:
			foot = UPPER.z + 1.2
		_watchtower(Vector3(tx, foot, z), y, -side)
	# Lanterns hung from posts standing on the rail.
	for k in [5, 13]:
		var t: float = k / 18.0
		var lx := x - span * 0.5 + span * t
		var ly := y + 0.9 * sin(PI * t)
		var post := PaperMesh.new(_rng.randi())
		post.color = LACQUER
		post.box(Vector3(lx, ly + 1.0, z + 0.78), Vector3(0.09, 2.0, 0.09))
		post.box(Vector3(lx + 0.22, ly + 1.95, z + 0.78), Vector3(0.5, 0.06, 0.06))
		add_child(post.build())
		_hang(Vector3(lx + 0.42, ly + 1.93, z + 0.78), 0.8, 0.15)
	# Two paper-doll figures crossing, dark against the glow.
	var f := PaperMesh.new(_rng.randi())
	f.color = Color(0.1, 0.08, 0.1)
	for k in 2:
		var fx := x - 1.0 + k * 1.6
		var fy := y + 0.9 * sin(PI * (fx - x + span * 0.5) / span)
		f.frustum(6, Vector2(0.28, 0.2), Vector2(0.14, 0.12), 1.1, Vector3(fx, fy, z))
		f.ellipse(Vector2(fx, fy + 1.3), Vector2(0.13, 0.15), 8, z)
		f.color = Color(0.3, 0.12, 0.1)
		f.ellipse(Vector2(fx + 0.3, fy + 1.4), Vector2(0.28, 0.08), 10, z + 0.05)  # an umbrella
		f.color = Color(0.1, 0.08, 0.1)
	add_child(f.build())


## A watchtower on the terrace: a stone foot, timber storeys, a lit doorway
## where a bridge comes in at `deck` (facing `toward`: -1 left, 1 right), a
## lantern, a hipped roof. Origin `at`: its foot.
func _watchtower(at: Vector3, deck: float, toward: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	var top := deck + 2.4
	b.color = Color(0.3, 0.28, 0.32)
	b.box(Vector3(at.x, at.y + 1.0, at.z), Vector3(2.4, 2.0, 2.4))
	b.color = Scenery.WOOD.darkened(0.2)
	b.box(Vector3(at.x, (at.y + 2.0 + top) * 0.5, at.z), Vector3(2.1, top - at.y - 2.0, 2.1))
	b.color = PaperMesh.TIMBER
	for c: Vector2 in [Vector2(-1.05, 1.05), Vector2(1.05, 1.05)]:
		b.box(Vector3(at.x + c.x, (at.y + 2.0 + top) * 0.5, at.z + c.y), Vector3(0.14, top - at.y - 2.0, 0.14))
	var floor_y := at.y + 2.0
	while floor_y < top - 0.5:
		b.box(Vector3(at.x, floor_y, at.z + 1.07), Vector3(2.2, 0.12, 0.08))
		floor_y += 2.2
	b.color = Color(0.09, 0.085, 0.12)
	b.frustum(4, Vector2(1.9, 1.9), Vector2(0.25, 0.25), 1.3, Vector3(at.x, top, at.z))
	add_child(b.build())
	# The doorway the bridge comes in at, and a window on the front.
	var lit := PaperMesh.new(_rng.randi())
	lit.color = PaperMesh.LANTERN.lerp(CREAM, 0.3)
	lit.box(Vector3(at.x + toward * 1.06, deck + 0.95, at.z), Vector3(0.04, 1.7, 0.9))
	lit.rect(Vector2(at.x, top - 1.1), Vector2(1.0, 0.8), at.z + 1.07)
	add_child(lit.build(Color.WHITE, 0.6))
	_hang(Vector3(at.x + toward * 0.6, top - 0.1, at.z + 1.2), 0.7, 0.2)


func _hill(x: float, base: float, rise: float) -> float:
	return base + rise * smoothstep(-40.0, 150.0, x) + 1.2 * sin(x * 0.11)


func _house_row(z: float, base: float, rise: float, s: float, tone: Color, bright: float) -> void:
	var walls := PaperMesh.new(_rng.randi())
	walls.shade_jitter = 0.0
	var lights := PaperMesh.new(_rng.randi())
	lights.shade_jitter = 0.0
	# The hill itself under the houses.
	var ground := PackedVector2Array()
	var x := -120.0
	while x <= END + 120.0:
		ground.append(Vector2(x, _hill(x, base, rise)))
		x += 3.0
	ground.append(Vector2(END + 120.0, -30.0))
	ground.append(Vector2(-120.0, -30.0))
	walls.color = tone.darkened(0.45)
	walls.polygon(ground, z - 0.05)
	x = -110.0
	var n := 0
	while x < END + 110.0:
		var w := _rng.randf_range(2.4, 4.2) * s
		var h := _rng.randf_range(1.5, 2.6) * s
		var g := _hill(x + w * 0.5, base, rise) - 0.3
		var zz := z + (n % 3) * 0.02
		walls.color = tone * _rng.randf_range(0.85, 1.15)
		walls.rect(Vector2(x + w * 0.5, g + h * 0.5), Vector2(w, h), zz)
		# A roof with curved eaves, a second storey sometimes.
		var roof := Color(0.08, 0.08, 0.12)
		walls.color = roof
		var top := g + h
		walls.polygon(PackedVector2Array([Vector2(x - 0.35 * s, top - 0.05), Vector2(x + w + 0.35 * s, top - 0.05),
				Vector2(x + w - 0.3 * s, top + 0.75 * s), Vector2(x + 0.3 * s, top + 0.75 * s)]), zz + 0.01)
		if _rng.randf() < 0.35:
			var w2 := w * 0.6
			var x2 := x + w * 0.2
			walls.color = tone * 1.05
			walls.rect(Vector2(x2 + w2 * 0.5, top + 0.75 * s + 0.6 * s), Vector2(w2, 1.2 * s), zz + 0.003)
			walls.color = roof
			var t2 := top + 1.95 * s
			walls.polygon(PackedVector2Array([Vector2(x2 - 0.3 * s, t2), Vector2(x2 + w2 + 0.3 * s, t2),
					Vector2(x2 + w2 - 0.2 * s, t2 + 0.6 * s), Vector2(x2 + 0.2 * s, t2 + 0.6 * s)]), zz + 0.013)
			lights.color = PaperMesh.LANTERN * bright
			lights.rect(Vector2(x2 + w2 * 0.5, top + 1.3 * s), Vector2(w2 * 0.6, 0.45 * s), zz + 0.006)
		# Glowing shoji windows.
		var panes := _rng.randi_range(1, 3)
		for p in panes:
			lights.color = PaperMesh.LANTERN.lerp(Color(1.0, 0.85, 0.55), _rng.randf()) * bright * _rng.randf_range(0.8, 1.1)
			var px := x + w * (p + 0.5) / panes
			lights.rect(Vector2(px, g + h * 0.5), Vector2(w / panes * 0.7, h * 0.5), zz + 0.006)
		x += w + _rng.randf_range(0.2, 1.2) * s
		n += 1
	_flat(walls)
	var lit := lights.build(Color.WHITE, 0.0, true)
	(lit.material_override as StandardMaterial3D).disable_fog = true
	add_child(lit)
	_mist(z + 0.4, _hill(0.0, base, 0.0) - 1.0, _hill(0.0, base, 0.0) + 2.5, Color(0.3, 0.26, 0.34, 0.7))


## A golden pagoda palace on the hilltop: stacked roofs, rows of lit windows.
func _palace(at: Vector3, s: float) -> void:
	var p := PaperMesh.new(_rng.randi())
	p.shade_jitter = 0.0
	var lights := PaperMesh.new(_rng.randi())
	lights.shade_jitter = 0.0
	# The stone base and terraces.
	p.color = Color(0.2, 0.18, 0.22)
	p.polygon(PackedVector2Array([Vector2(at.x - 9.0 * s, at.y - 6.0), Vector2(at.x + 9.0 * s, at.y - 6.0),
			Vector2(at.x + 7.0 * s, at.y), Vector2(at.x - 7.0 * s, at.y)]), at.z)
	var y := at.y
	for k in 5:
		var wide := (6.0 - k * 0.95) * s
		var tall := (1.7 - k * 0.12) * s
		p.color = Color(0.32, 0.22, 0.14)
		p.rect(Vector2(at.x, y + tall * 0.5), Vector2(wide * 1.5, tall), at.z + 0.01)
		for w in int(wide * 1.2):
			lights.color = Color(1.0, 0.76, 0.4) * (0.9 + 0.2 * _rng.randf())
			lights.rect(Vector2(at.x - wide * 0.65 + (w + 0.5) * wide * 1.3 / int(wide * 1.2), y + tall * 0.48),
					Vector2(wide * 0.6 / int(wide * 1.2) + 0.08, tall * 0.55), at.z + 0.02)
		# The roof, its eaves curling up at the ends, a gold lip.
		var r0 := y + tall
		p.color = Color(0.09, 0.08, 0.12)
		p.polygon(PackedVector2Array([Vector2(at.x - wide - 0.9 * s, r0 + 0.25 * s), Vector2(at.x - wide * 0.8, r0 - 0.05),
				Vector2(at.x + wide * 0.8, r0 - 0.05), Vector2(at.x + wide + 0.9 * s, r0 + 0.25 * s),
				Vector2(at.x + wide * 0.5, r0 + 0.9 * s), Vector2(at.x - wide * 0.5, r0 + 0.9 * s)]), at.z + 0.03)
		p.color = GOLD.darkened(0.2)
		p.stroke(Vector2(at.x - wide - 0.9 * s, r0 + 0.25 * s), Vector2(at.x - wide * 0.8, r0 - 0.03), 0.09 * s, 0.07 * s, at.z + 0.035)
		p.stroke(Vector2(at.x + wide * 0.8, r0 - 0.03), Vector2(at.x + wide + 0.9 * s, r0 + 0.25 * s), 0.07 * s, 0.09 * s, at.z + 0.035)
		p.stroke(Vector2(at.x - wide * 0.8, r0 - 0.03), Vector2(at.x + wide * 0.8, r0 - 0.03), 0.06 * s, 0.06 * s, at.z + 0.035)
		y = r0 + 0.9 * s
	p.color = GOLD
	p.stroke(Vector2(at.x, y), Vector2(at.x, y + 2.2 * s), 0.14 * s, 0.05 * s, at.z + 0.04)
	_flat(p)
	var lit := lights.build(Color.WHITE, 0.0, true)
	(lit.material_override as StandardMaterial3D).disable_fog = true
	add_child(lit)


func _far_bridge(x: float, z: float, y: float, span: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.0
	var pts := PackedVector2Array()
	var under := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		var px := x - span * 0.5 + span * t
		pts.append(Vector2(px, y + 1.1 * sin(PI * t)))
		under.append(Vector2(px, y - 0.3 + 1.1 * sin(PI * t)))
	var deck := PackedVector2Array(pts)
	under.reverse()
	deck.append_array(under)
	b.color = LACQUER.darkened(0.25)
	b.polygon(deck, z)
	# The railing: posts and a top rail.
	for k in 13:
		b.rect(pts[k] + Vector2(0.0, 0.35), Vector2(0.08, 0.7), z + 0.01)
	for k in 12:
		b.stroke(pts[k] + Vector2(0.0, 0.66), pts[k + 1] + Vector2(0.0, 0.66), 0.08, 0.08, z + 0.012)
	_flat(b)
	# Legs: pairs of red pillars down into the misty gap, braced.
	var legs := PaperMesh.new(_rng.randi())
	legs.shade_jitter = 0.0
	legs.color = LACQUER.darkened(0.45)
	for k in [4, 8]:
		legs.rect(Vector2(pts[k].x, pts[k].y - 7.0), Vector2(0.2, 13.4), z - 0.02)
	# A gatehouse tower at each end, which the bridge joins (it led
	# nowhere: Julian): rising out of the haze, a lit door, a roof.
	for side: float in [-1.0, 1.0]:
		var tx := x + side * (span * 0.5 + 0.9)
		legs.color = Color(0.17, 0.13, 0.15)
		legs.rect(Vector2(tx, y - 6.0), Vector2(1.8, 15.6), z - 0.01)
		legs.color = Color(0.09, 0.08, 0.11)
		legs.polygon(PackedVector2Array([Vector2(tx - 1.3, y + 1.8), Vector2(tx + 1.3, y + 1.8), Vector2(tx + 0.5, y + 2.7), Vector2(tx - 0.5, y + 2.7)]), z - 0.005)
		legs.color = Color(0.46, 0.34, 0.26)
		legs.stroke(Vector2(tx - 1.3, y + 1.8), Vector2(tx + 1.3, y + 1.8), 0.06, 0.06, z - 0.004)
		legs.color = LACQUER.darkened(0.45)
		_far_lamp(Vector3(tx, y + 0.5, z), 0.3)
		_far_lamp(Vector3(tx, y - 2.5, z), 0.22)
	legs.rect(Vector2(x, y - 2.2), Vector2(span, 0.12), z - 0.015)
	legs.rect(Vector2(x, y - 5.0), Vector2(span, 0.12), z - 0.015)
	_flat(legs)
	var haze := PaperMesh.new(1)
	haze.fade_quad(Vector3(x - span * 0.5 - 3.0, y - 14.0, z + 0.05), Vector3(x + span * 0.5 + 3.0, y - 14.0, z + 0.05),
			Vector3(x + span * 0.5 + 3.0, y - 2.5, z + 0.05), Vector3(x - span * 0.5 - 3.0, y - 2.5, z + 0.05),
			Color(0.34, 0.25, 0.27, 0.95), Color(0.34, 0.25, 0.27, 0.0))
	add_child(haze.build_veil())
	# Lanterns on short posts along its rail.
	for k in [2, 6, 10]:
		var post := PaperMesh.new(1)
		post.color = LACQUER.darkened(0.25)
		post.rect(Vector2(pts[k].x, pts[k].y + 1.0), Vector2(0.07, 0.75), z + 0.015)
		_flat(post)
		_far_lamp(Vector3(pts[k].x, pts[k].y + 1.3, z + 0.02), 0.22)


## A string of small glowing lanterns sagging between two points.
func _far_string(a: Vector2, c: Vector2, z: float, sag: float) -> void:
	var line := PaperMesh.new(1)
	line.shade_jitter = 0.0
	line.color = Color(0.06, 0.05, 0.08)
	# Tied to tall poles at each end, standing down among the houses.
	for end: Vector2 in [a, c]:
		line.rect(Vector2(end.x, end.y - 4.5), Vector2(0.09, 9.2), z - 0.005)
	var prev := a
	var count := int(a.distance_to(c) / 1.3)
	for k in range(1, count + 1):
		var t := float(k) / count
		var p := a.lerp(c, t) - Vector2(0.0, sag * 4.0 * t * (1.0 - t))
		line.stroke(prev, p, 0.03, 0.03, z)
		prev = p
		if k < count:
			_far_lamp(Vector3(p.x, p.y - 0.22, z + 0.01), 0.17)
	_flat(line)


var _lamps: PaperMesh
## A tiny far lantern: a warm oval (drawn into one sheet, built at the end).
func _far_lamp(at: Vector3, r: float) -> void:
	if _lamps == null:
		_lamps = PaperMesh.new(1)
		_lamps.shade_jitter = 0.0
		(func() -> void:
			var lit := _lamps.build(Color.WHITE, 0.0, true)
			(lit.material_override as StandardMaterial3D).disable_fog = true
			add_child(lit)).call_deferred()
	_lamps.color = Color(1.0, 0.7, 0.38) * _rng.randf_range(0.9, 1.1)
	_lamps.ellipse(Vector2(at.x, at.y), Vector2(r * 0.8, r), 8, at.z)
	_lamps.color = PaperMesh.VERMILION
	_lamps.ellipse(Vector2(at.x, at.y), Vector2(r * 0.3, r * 0.3), 6, at.z + 0.002)


# --- The ground: streets, the canal, the bridge, the steps ---------------------------

func _build_ground() -> void:
	for g: Vector3 in [LOWER, UPPER, PLAZA]:
		var x := g.x
		while x < g.y - 0.01:
			var x1 := minf(x + 12.0, g.y)
			# (Not the town's street block: its torn front edge would lie as a
			# pale line across the middle of these stones.)
			_solid(Vector3((x + x1) * 0.5, g.z - 4.0, -1.5), Vector3(x1 - x, 8.0, 6.0))
			village._lay_paving(SHIFT + x, SHIFT + x1, g.z, Village.STREET_BACK, NEAR_Z)
			village._add_rain_splashes(SHIFT + x, SHIFT + x1, g.z)
			x = x1
		_front_edge(g.x, g.y, g.z)
	# Under the steps.
	_slope(STEPS.x, UPPER.z, STEPS.y, PLAZA.z, 8.0)
	var e := PaperMesh.new(_rng.randi())
	e.color = Village.EARTH
	e.extrude(PackedVector2Array([Vector2(STEPS.x, UPPER.z), Vector2(STEPS.y, PLAZA.z), Vector2(STEPS.y, -10.0), Vector2(STEPS.x, -10.0)]),
			Village.STREET_BACK, Village.STREET_FRONT - 0.15)
	add_child(e.build())


## The torn front edge of the paving, nearest us.
func _front_edge(left: float, right: float, top: float) -> void:
	var f := PaperMesh.new(_rng.randi())
	f.color = Color(0.1, 0.09, 0.13)
	f.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, top - 6.0), Vector2(left, top - 6.0)]),
			0.5, 0.06, _rng), NEAR_Z, Color(0.36, 0.3, 0.34), 0.03)
	var m := f.build()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)


func _build_canal() -> void:
	_solid(Vector3((CANAL.x + CANAL.y) * 0.5, CANAL_BED - 4.0, -1.5), Vector3(CANAL.y - CANAL.x, 8.0, 6.0))
	# Stone walls lining the canal, the water dark and glossy between.
	var s := PaperMesh.new(_rng.randi())
	s.shade_jitter = 0.18
	for side: Array in [[CANAL.x, LOWER.z, 1.0], [CANAL.y, UPPER.z, -1.0]]:
		var wx: float = side[0]
		var top: float = side[1]
		var y := CANAL_BED - 1.0
		while y < top - 0.01:
			var y1 := minf(y + 0.5, top)
			var z := Village.STREET_BACK
			while z < NEAR_Z - 0.01:
				var z1 := minf(z + _rng.randf_range(0.7, 1.2), NEAR_Z)
				s.color = Color(0.25, 0.25, 0.32) * _rng.randf_range(0.8, 1.1)
				s.box(Vector3(wx + side[2] * 0.15, (y + y1) * 0.5, (z + z1) * 0.5), Vector3(0.3, y1 - y - 0.03, z1 - z - 0.03))
				z = z1
			y = y1
	add_child(s.build())
	var w := PaperMesh.new(1)
	w.shade_jitter = 0.04
	w.color = Color(0.1, 0.11, 0.2)
	w.quad(Vector3(CANAL.x, WATER_Y, Village.STREET_BACK), Vector3(CANAL.y, WATER_Y, Village.STREET_BACK),
			Vector3(CANAL.y, WATER_Y, NEAR_Z), Vector3(CANAL.x, WATER_Y, NEAR_Z), Vector3.UP)
	w.color = Color(0.03, 0.04, 0.09)
	w.quad(Vector3(CANAL.x, WATER_Y, NEAR_Z), Vector3(CANAL.y, WATER_Y, NEAR_Z),
			Vector3(CANAL.y, -12.0, NEAR_Z), Vector3(CANAL.x, -12.0, NEAR_Z))
	var water := w.build()
	var gloss := water.material_override as StandardMaterial3D
	gloss.roughness = 0.12
	gloss.metallic_specular = 0.9
	add_child(water)
	# Lantern light trembling on the water.
	for x: float in [60.5, 63.0, 66.5, 69.5]:
		var r := Scenery.reflection(Vector2(1.6, 7.0), Color(1.0, 0.62, 0.3, 0.75))
		r.position = Vector3(x, WATER_Y + 0.01, 1.5)
		r.set_meta(&"x", x)
		add_child(r)
		_shimmer.append(r)
	village._add_rain_splashes(SHIFT + CANAL.x, SHIFT + CANAL.y, WATER_Y)


## The red arched bridge: lacquered girders, a plank deck, railings with
## gold-capped posts, lanterns at its crown.
func _build_bridge() -> void:
	var step := 0.5
	var x := BRIDGE.x
	var deck := PaperMesh.new(_rng.randi())
	deck.shade_jitter = 0.2
	var red := PaperMesh.new(_rng.randi())
	red.shade_jitter = 0.12
	while x < BRIDGE.y - 0.01:
		var x1 := minf(x + step, BRIDGE.y)
		var d0 := deck_at(x)
		var d1 := deck_at(x1)
		_slope(x, d0, x1, d1, 0.4)
		deck.color = Scenery.WOOD.lightened(0.1) * _rng.randf_range(0.85, 1.1)
		deck.extrude(PackedVector2Array([Vector2(x, d0 - 0.18), Vector2(x1, d1 - 0.18), Vector2(x1, d1), Vector2(x, d0)]), -1.15, 1.15)
		red.color = LACQUER
		for zz: Vector2 in [Vector2(1.15, 1.35), Vector2(-1.35, -1.15)]:
			# The girder deepens toward the ends where it meets the banks.
			var deep0 := 0.45 + 0.5 * (1.0 - sin(PI * (x - BRIDGE.x) / (BRIDGE.y - BRIDGE.x)))
			var deep1 := 0.45 + 0.5 * (1.0 - sin(PI * (x1 - BRIDGE.x) / (BRIDGE.y - BRIDGE.x)))
			red.extrude(PackedVector2Array([Vector2(x, d0 - deep0), Vector2(x1, d1 - deep1), Vector2(x1, d1 + 0.05), Vector2(x, d0 + 0.05)]), zz.x, zz.y)
		x = x1
	add_child(deck.build())
	# Railings: posts every 1.25 m with gold caps, a top rail and a lower one.
	var post := BRIDGE.x + 0.3
	var prev := Vector2.INF
	while post < BRIDGE.y - 0.2:
		var d := deck_at(post)
		for pz: float in [1.25, -1.25]:
			red.color = LACQUER
			red.box(Vector3(post, d + 0.5, pz), Vector3(0.12, 1.0, 0.12))
			red.color = GOLD.darkened(0.15)
			red.frustum(6, Vector2(0.08, 0.08), Vector2(0.01, 0.01), 0.16, Vector3(post, d + 1.0, pz))
			if prev != Vector2.INF:
				red.color = LACQUER.darkened(0.1)
				for rh: float in [0.92, 0.45]:
					red.extrude(PackedVector2Array([Vector2(prev.x, prev.y + rh), Vector2(post, d + rh), Vector2(post, d + rh + 0.07),
							Vector2(prev.x, prev.y + rh + 0.07)]), pz - 0.04, pz + 0.04)
		prev = Vector2(post, d)
		post += 1.25
	add_child(red.build())
	# Stone piers into the water.
	var s := PaperMesh.new(_rng.randi())
	s.color = Color(0.24, 0.24, 0.3)
	for px: float in [61.5, 68.5]:
		s.box(Vector3(px, (WATER_Y - 1.0 + deck_at(px) - 0.6) * 0.5, 0.0), Vector3(0.7, deck_at(px) - 0.6 - WATER_Y + 1.0, 2.6))
	add_child(s.build())
	# Tall lacquered lantern posts at both feet of the bridge, paper lantern
	# boxes glowing on top; and garlands of small lanterns swagging from
	# post to post along both rails (the arms at its crown looked "basic and
	# lazy": Julian).
	for foot: Vector2 in [Vector2(BRIDGE.x + 0.5, LOWER.z), Vector2(BRIDGE.y - 0.5, UPPER.z)]:
		for pz: float in [1.75, -1.75]:
			_toro(Vector3(foot.x, foot.y, pz))
		_light(Vector3(foot.x, foot.y + 3.2, 2.4), village.lantern_energy * 0.75, village.lantern_range)
	_light(Vector3((BRIDGE.x + BRIDGE.y) * 0.5, deck_at((BRIDGE.x + BRIDGE.y) * 0.5) + 1.6, 2.2), village.lantern_energy * 0.6, village.lantern_range)
	var garland := PaperMesh.new(_rng.randi())
	garland.color = Color(0.12, 0.08, 0.07)
	var gx := BRIDGE.x + 0.3 + 1.25 * 2.0
	while gx + 2.5 < BRIDGE.y - 0.2:
		var x1 := gx + 2.5
		var d0 := deck_at(gx) + 0.95
		var d1 := deck_at(x1) + 0.95
		for pz: float in [1.32, -1.32]:
			var prevp := Vector2(gx, d0)
			for k in range(1, 7):
				var t := k / 6.0
				var pnt := Vector2(lerpf(gx, x1, t), lerpf(d0, d1, t) - 0.35 * 4.0 * t * (1.0 - t))
				garland.extrude(PackedVector2Array([prevp, pnt, pnt + Vector2(0.0, 0.025), prevp + Vector2(0.0, 0.025)]), pz - 0.012, pz + 0.012)
				prevp = pnt
			var mid := Vector2((gx + x1) * 0.5, (d0 + d1) * 0.5 - 0.35)
			_hang(Vector3(mid.x, mid.y, pz), 0.5, 0.06)
		gx = x1
	add_child(garland.build())


## A tall lantern post (as at the feet of a shrine bridge): a lacquered post
## on a stone foot, a roofed paper lantern box glowing on top, a gold cap.
func _toro(at: Vector3) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = Color(0.3, 0.3, 0.36)
	b.box(at + Vector3(0.0, 0.18, 0.0), Vector3(0.5, 0.36, 0.5))
	b.color = LACQUER
	b.box(at + Vector3(0.0, 1.5, 0.0), Vector3(0.16, 2.3, 0.16))
	b.box(at + Vector3(0.0, 2.68, 0.0), Vector3(0.62, 0.08, 0.62))
	b.color = PaperMesh.TIMBER
	for c: Vector2 in [Vector2(-0.22, -0.22), Vector2(0.22, -0.22), Vector2(-0.22, 0.22), Vector2(0.22, 0.22)]:
		b.box(at + Vector3(c.x, 3.02, c.y), Vector3(0.05, 0.6, 0.05))
	b.color = Color(0.1, 0.09, 0.12)
	b.frustum(4, Vector2(0.5, 0.5), Vector2(0.06, 0.06), 0.36, at + Vector3(0.0, 3.32, 0.0))
	b.color = GOLD.darkened(0.15)
	b.frustum(6, Vector2(0.07, 0.07), Vector2(0.01, 0.01), 0.22, at + Vector3(0.0, 3.66, 0.0))
	add_child(b.build())
	var paper := PaperMesh.new(_rng.randi())
	paper.color = PaperMesh.LANTERN.lerp(CREAM, 0.35)
	paper.box(at + Vector3(0.0, 3.02, 0.0), Vector3(0.4, 0.52, 0.4))
	var lit := paper.build(Color.WHITE, _glow * 0.9)
	lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lit)
	var crest := PaperMesh.new(_rng.randi())
	crest.color = RED_CLOTH
	crest.ellipse(Vector2(at.x, at.y + 3.02), Vector2(0.1, 0.1), 10, at.z + 0.205)
	add_child(crest.build(Color.WHITE, 0.4))
	var halo := Scenery.halo(1.6, Color(1.0, 0.62, 0.3, 0.5))
	halo.position = at + Vector3(0.0, 3.02, 0.3)
	add_child(halo)


func _build_steps() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	var n := 16
	for k in n:
		var x0 := STEPS.x + (STEPS.y - STEPS.x) * k / n
		var x1 := STEPS.x + (STEPS.y - STEPS.x) * (k + 1) / n
		var top := ground_at((x0 + x1) * 0.5) + 0.11
		b.color = Color(0.3, 0.3, 0.37) * _rng.randf_range(0.85, 1.1)
		b.box(Vector3((x0 + x1) * 0.5, top - 0.6, (NEAR_Z - 5.5) * 0.5), Vector3(x1 - x0 + 0.02, 1.2, NEAR_Z + 5.5))
		b.color = Color(0.42, 0.42, 0.5)
		b.box(Vector3((x0 + x1) * 0.5, top - 0.02, NEAR_Z), Vector3(x1 - x0 - 0.02, 0.04, 0.05))
	add_child(b.build())
	var front := PaperMesh.new(_rng.randi())
	front.color = Color(0.12, 0.12, 0.2)
	var outline := PackedVector2Array([Vector2(STEPS.x, UPPER.z - 0.2), Vector2(STEPS.y, PLAZA.z - 0.2),
			Vector2(STEPS.y, -10.0), Vector2(STEPS.x, -10.0)])
	front.torn_sheet(PaperMesh.tear(outline, 0.5, 0.08, _rng), NEAR_Z + 0.05, Color(0.3, 0.32, 0.45), 0.03)
	add_child(front.build())
	for lx: float in [STEPS.x + 1.0, STEPS.y - 1.0]:
		village._build_stone_lantern(Vector3(SHIFT + lx, ground_at(lx), -2.6), false)


# --- The stalls ----------------------------------------------------------------------

## A stall at the back of the street, like those in the picture: a tiled
## roof, a red noren with a white crest, crested lanterns, banners with
## brushed writing, a counter of wares and a gilded keeper behind it.
func _booth(x: float, kind: String, robe: Color) -> void:
	var g := ground_at(x)
	var root := Node3D.new()
	root.position = Vector3(x, g, 0.0)
	add_child(root)
	var half := 3.0
	var front := -2.5
	var back := -4.7
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	# Back wall of dark boards with three lit shoji panels.
	b.color = Scenery.WALL_DARK.lerp(Scenery.WOOD, 0.4)
	b.box(Vector3(0.0, 1.65, back), Vector3(half * 2.0, 3.3, 0.1))
	# Side walls (solid from the side), posts, the lintel.
	for side: float in [-1.0, 1.0]:
		b.color = Scenery.WOOD.darkened(0.25)
		b.box(Vector3(side * half, 1.65, (front + back) * 0.5), Vector3(0.08, 3.3, absf(back - front)))
		b.color = PaperMesh.TIMBER.lightened(0.08)
		for pz: float in [front, back]:
			b.box(Vector3(side * half, 1.7, pz), Vector3(0.18, 3.4, 0.18))
	b.box(Vector3(0.0, 3.25, front), Vector3(half * 2.0 + 0.3, 0.2, 0.2))
	# The counter.
	b.color = Scenery.WOOD.lightened(0.05)
	b.box(Vector3(0.0, 0.5, front - 0.45), Vector3(half * 2.0 - 0.5, 1.0, 0.6))
	b.color = Scenery.WOOD.darkened(0.3)
	b.box(Vector3(0.0, 1.02, front - 0.45), Vector3(half * 2.0 - 0.4, 0.05, 0.68))
	var walls := b.build()
	root.add_child(walls)
	# Shoji glowing in the back wall.
	var sh := PaperMesh.new(_rng.randi())
	sh.shade_jitter = 0.06
	sh.color = PaperMesh.LANTERN.lerp(CREAM, 0.4)
	for p in 3:
		sh.rect(Vector2(-1.9 + p * 1.9, 2.05), Vector2(1.6, 1.6), back + 0.06)
	root.add_child(sh.build(Color.WHITE, 0.55))
	var lattice := PaperMesh.new(_rng.randi())
	lattice.color = PaperMesh.TIMBER
	for p in 3:
		var cx := -1.9 + p * 1.9
		for k in 4:
			lattice.rect(Vector2(cx - 0.8 + k * 0.533, 2.05), Vector2(0.035, 1.6), back + 0.07)
		for k in 5:
			lattice.rect(Vector2(cx, 1.25 + k * 0.4), Vector2(1.6, 0.035), back + 0.072)
	root.add_child(lattice.build())
	# The roof: tiles sloping down toward us, closed at both ends.
	var roof := Scenery.tiled_roof(_rng, -half - 0.55, half + 0.55, Vector2(3.3, -1.65), Vector2(4.75, back - 0.3), 4)
	root.add_child(roof)
	var gable := PaperMesh.new(_rng.randi())
	gable.color = Scenery.WOOD.darkened(0.35)
	for side: float in [-1.0, 1.0]:
		var gx := side * (half + 0.05)
		gable.tri(Vector3(gx, 3.3, front), Vector3(gx, 4.6, back), Vector3(gx, 3.3, back), Vector3(side, 0.0, 0.0))
	root.add_child(gable.build())
	# The noren: three strips of red cloth, the middle one with a white crest.
	var widths := [1.6, 2.4, 1.6]
	var nx := -2.8
	for i in 3:
		var strip := Node3D.new()
		var sw: float = widths[i]
		strip.position = Vector3(nx + sw * 0.5, 3.15, front + 0.14)
		root.add_child(strip)
		var c := PaperMesh.new(_rng.randi())
		c.shade_jitter = 0.08
		c.color = RED_CLOTH * _rng.randf_range(0.9, 1.05)
		c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-sw * 0.5 + 0.03, 0.0), Vector2(sw * 0.5 - 0.03, 0.0),
				Vector2(sw * 0.5 - 0.03, -0.95), Vector2(-sw * 0.5 + 0.03, -0.95)]), 0.25, 0.03, _rng), 0.0)
		if i == 1:
			c.color = CREAM
			c.ellipse(Vector2(0.0, -0.47), Vector2(0.36, 0.36), 18, 0.004)
			c.color = RED_CLOTH
			c.ellipse(Vector2(0.0, -0.47), Vector2(0.3, 0.3), 18, 0.006)
			c.color = CREAM
			for p in 5:
				var a := TAU * p / 5.0 + PI * 0.5
				c.ellipse(Vector2(0.0, -0.47) + Vector2(cos(a), sin(a)) * 0.14, Vector2(0.1, 0.1), 8, 0.008)
		strip.add_child(c.build())
		Scenery.windswept(strip, 0.05, _rng)
		nx += sw
	# Lanterns at the corners, under the eaves.
	for side: float in [-1.0, 1.0]:
		_hang(Vector3(side * (half - 0.05), 3.2, front + 0.45), 1.25, 0.2, root)
	# Banners of brushed writing hanging beside the counter.
	for side: float in [-1.0, 1.0]:
		var banner := Node3D.new()
		banner.position = Vector3(side * (half - 0.55), 2.3, front + 0.12)
		root.add_child(banner)
		var w := PaperMesh.new(_rng.randi())
		w.color = CREAM
		w.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.22, 0.0), Vector2(0.22, 0.0), Vector2(0.22, -1.1), Vector2(-0.22, -1.1)]), 0.2, 0.025, _rng), 0.0)
		_writing(w, Vector2(0.0, -0.18), 3, 0.18, 0.004)
		banner.add_child(w.build())
		Scenery.windswept(banner, 0.04, _rng)
	# A cloth over the counter's front.
	var cloth := PaperMesh.new(_rng.randi())
	cloth.color = CREAM.darkened(0.08)
	cloth.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-1.6, 1.0), Vector2(1.6, 1.0), Vector2(1.6, 0.25), Vector2(-1.6, 0.25)]), 0.3, 0.03, _rng), front - 0.13)
	_writing(cloth, Vector2(-1.1, 0.88), 1, 0.16, front - 0.126)
	_writing(cloth, Vector2(1.1, 0.88), 1, 0.16, front - 0.126)
	# The stall's crest: a red ring with a five-petal flower (as on the noren).
	cloth.color = RED_CLOTH
	cloth.ellipse(Vector2(0.0, 0.62), Vector2(0.25, 0.25), 18, front - 0.126)
	cloth.color = CREAM.darkened(0.08)
	cloth.ellipse(Vector2(0.0, 0.62), Vector2(0.2, 0.2), 18, front - 0.124)
	cloth.color = RED_CLOTH
	for p in 5:
		var a := TAU * p / 5.0 + PI * 0.5
		cloth.ellipse(Vector2(0.0, 0.62) + Vector2(cos(a), sin(a)) * 0.09, Vector2(0.065, 0.065), 8, front - 0.122)
	root.add_child(cloth.build())
	# The wares.
	var wares := PaperMesh.new(_rng.randi())
	wares.shade_jitter = 0.1
	var work := "idle"
	match kind:
		"fans":
			for k in 3:
				_fan(wares, Vector2(-1.5 + k * 1.5, 1.05), 0.55, [CREAM, RED_CLOTH, CREAM][k], front - 0.5)
			_fan(wares, Vector2(-1.9, 2.3), 0.8, RED_CLOTH.lightened(0.1), back + 0.12)
			_fan(wares, Vector2(1.9, 2.3), 0.8, CREAM, back + 0.12)
			work = "fold"
		"sweets":
			for k in 4:
				_mochi(wares, Vector2(-1.8 + k * 1.2, 1.05), front - 0.5, [CREAM, BLOSSOM, Color(0.62, 0.68, 0.5), CREAM][k])
		"sake":
			for k in 2:
				_jar(wares, Vector3(-1.4 + k * 2.8, 1.04, front - 0.5), 0.75)
			for k in 4:
				wares.color = CREAM.darkened(0.1)
				wares.frustum(8, Vector2(0.06, 0.06), Vector2(0.07, 0.07), 0.09, Vector3(-0.4 + k * 0.28, 1.05, front - 0.4))
			work = "pour"
		"fish":
			wares.color = Scenery.WOOD
			wares.box(Vector3(0.0, 1.1, front - 0.5), Vector3(3.2, 0.1, 0.5))
			for k in 6:
				_fish(wares, Vector2(-1.4 + k * 0.56, 1.22), 0.5, front - 0.3 + (k % 2) * 0.01, 0.0)
			for k in 4:
				var f := Node3D.new()
				f.position = Vector3(-1.2 + k * 0.8, 3.1, front + 0.3)
				root.add_child(f)
				var fb := PaperMesh.new(_rng.randi())
				fb.color = PaperMesh.SUMI
				fb.stroke(Vector2.ZERO, Vector2(0.0, -0.3), 0.015, 0.015, 0.0)
				_fish(fb, Vector2(0.0, -0.62), 0.6, 0.0, -PI * 0.5)
				f.add_child(fb.build())
				Scenery.windswept(f, 0.1, _rng)
		"grill":
			wares.color = Color(0.1, 0.1, 0.12)
			wares.box(Vector3(0.6, 1.2, front - 0.5), Vector3(2.0, 0.3, 0.5))
			for k in 7:
				wares.color = Color(0.7, 0.5, 0.28)
				wares.stroke(Vector2(-0.2 + k * 0.27, 1.38), Vector2(0.0 + k * 0.27, 1.5), 0.05, 0.03, front - 0.24)
			var coals := PaperMesh.new(_rng.randi())
			coals.color = Color(1.0, 0.42, 0.14)
			coals.box(Vector3(0.6, 1.36, front - 0.5), Vector3(1.8, 0.04, 0.4))
			root.add_child(coals.build(Color.WHITE, 2.0))
			var steam := _smoke()
			steam.position = Vector3(0.6, 1.5, front - 0.5)
			root.add_child(steam)
			work = "fan"
		"cranes":
			for row in 3:
				for k in 7:
					var cc: Color = [CREAM, RED_CLOTH.lightened(0.15), BLOSSOM, GOLD][(k + row) % 4]
					_crane(wares, Vector2(-2.3 + k * 0.75, 1.7 + row * 0.55), 0.24, cc, back + 0.12)
			for k in 3:
				_crane(wares, Vector2(-1.2 + k * 1.2, 1.2), 0.3, [RED_CLOTH, CREAM, BLOSSOM][k], front - 0.5)
			for side: float in [-1.0, 1.0]:
				var hang := Node3D.new()
				hang.position = Vector3(side * 2.0, 3.15, front + 0.25)
				root.add_child(hang)
				var hb := PaperMesh.new(_rng.randi())
				hb.color = PaperMesh.SUMI
				hb.stroke(Vector2.ZERO, Vector2(0.0, -1.3), 0.012, 0.012, 0.0)
				for k in 5:
					_crane(hb, Vector2(0.0, -0.2 - k * 0.26), 0.16, [RED_CLOTH, BLOSSOM, CREAM][k % 3], 0.01)
				hang.add_child(hb.build())
				Scenery.windswept(hang, 0.08, _rng)
			work = "fold"
	root.add_child(wares.build())
	# Barrels with crests, a floor lantern.
	var barrel := Scenery.barrel(_rng, 0.9)
	barrel.position = Vector3(half - 0.55, 0.0, front + 0.55)
	root.add_child(barrel)
	var crest := PaperMesh.new(_rng.randi())
	crest.color = CREAM
	crest.ellipse(Vector2(half - 0.55, 0.42), Vector2(0.17, 0.17), 14, front + 0.55 + 0.4)
	crest.color = RED_CLOTH
	crest.ellipse(Vector2(half - 0.55, 0.42), Vector2(0.1, 0.1), 10, front + 0.55 + 0.405)
	root.add_child(crest.build())
	_andon(root, Vector3(-half + 0.5, 0.0, front + 0.6))
	# The keeper.
	var keeper := MarketKeeper.new()
	keeper.robe = robe
	keeper.work = work
	keeper.headband = kind == "grill"
	keeper.position = Vector3(-0.6 if kind == "grill" else 0.2, 0.0, front - 1.25)
	root.add_child(keeper)
	_far.append(keeper)
	# Its light, and the gold it throws on the wet street.
	_light(Vector3(x, g + 2.4, -0.4), village.lantern_energy * booth_light, village.lantern_range * 1.1)
	_shine(x, g, 5.0, 0.9)


## Between neighbouring stalls: a dark boarded wall and a strip of roof, so
## the lit houses behind do not show through the gap as pale pillars.
func _fill_between_booths() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	for i in range(BOOTHS.size() - 1):
		var x0: float = BOOTHS[i][0]
		var x1: float = BOOTHS[i + 1][0]
		if x1 - x0 > 9.0 or absf(ground_at(x0) - ground_at(x1)) > 0.1:
			continue
		var mid := (x0 + x1) * 0.5
		var gap := x1 - x0 - 6.0 + 0.3
		var g := ground_at(mid)
		b.color = Scenery.WOOD.darkened(0.45)
		b.box(Vector3(mid, g + 2.3, -3.9), Vector3(gap, 4.6, 1.6))
		b.color = Scenery.ROOF.darkened(0.25)
		b.extrude(PackedVector2Array([Vector2(mid - gap * 0.5, g + 3.3), Vector2(mid + gap * 0.5, g + 3.3),
				Vector2(mid + gap * 0.5, g + 4.78), Vector2(mid - gap * 0.5, g + 4.78)]), -5.05, -3.1)
	add_child(b.build())


## Brush writing: columns of a few strokes each, like characters.
func _writing(b: PaperMesh, top: Vector2, glyphs: int, size: float, z: float) -> void:
	b.color = PaperMesh.SUMI
	for k in glyphs:
		var c := top - Vector2(0.0, k * size * 1.25)
		for s in _rng.randi_range(3, 5):
			var a := c + Vector2(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.4, 0.4)) * size
			var dir := [Vector2(1, 0), Vector2(0, -1), Vector2(0.7, -0.7), Vector2(-0.7, -0.7)][_rng.randi() % 4] as Vector2
			b.stroke(a, a + dir * size * _rng.randf_range(0.35, 0.7), size * 0.13, size * 0.06, z)


func _fan(b: PaperMesh, at: Vector2, r: float, tint: Color, z: float) -> void:
	var pts := PackedVector2Array([at])
	for k in 13:
		var a := deg_to_rad(20.0 + 140.0 * k / 12.0)
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	b.color = tint
	b.polygon(pts, z)
	b.color = tint.darkened(0.3)
	for k in 7:
		var a := deg_to_rad(20.0 + 140.0 * k / 6.0)
		b.stroke(at, at + Vector2(cos(a), sin(a)) * r, 0.012, 0.01, z + 0.002)
	b.color = RED_CLOTH if tint != RED_CLOTH else CREAM
	for k in 3:
		var a := deg_to_rad(60.0 + 30.0 * k)
		b.ellipse(at + Vector2(cos(a), sin(a)) * r * 0.65, Vector2(0.05, 0.05) * r * 2.0, 6, z + 0.003)


func _mochi(b: PaperMesh, at: Vector2, z: float, tint: Color) -> void:
	b.color = Scenery.WOOD.lightened(0.15)
	b.box(Vector3(at.x, at.y + 0.03, z), Vector3(0.95, 0.06, 0.5))
	for row in 3:
		for k in 3 - row:
			b.color = tint * _rng.randf_range(0.92, 1.05)
			b.ellipse(at + Vector2((k - (2 - row) * 0.5) * 0.24, 0.17 + row * 0.18), Vector2(0.12, 0.1), 10, z + 0.26 + row * 0.01)


func _jar(b: PaperMesh, at: Vector3, s: float) -> void:
	b.color = CREAM.darkened(0.05)
	b.loft([PaperMesh.oval(at, Vector2(0.18, 0.18) * s, 10),
			PaperMesh.oval(at + Vector3(0.0, 0.3 * s, 0.0), Vector2(0.3, 0.3) * s, 10),
			PaperMesh.oval(at + Vector3(0.0, 0.62 * s, 0.0), Vector2(0.26, 0.26) * s, 10),
			PaperMesh.oval(at + Vector3(0.0, 0.78 * s, 0.0), Vector2(0.1, 0.1) * s, 10),
			PaperMesh.oval(at + Vector3(0.0, 0.88 * s, 0.0), Vector2(0.11, 0.11) * s, 10)])
	b.color = RED_CLOTH
	b.ellipse(Vector2(at.x, at.y + 0.42 * s), Vector2(0.15, 0.15) * s, 12, at.z + 0.3 * s)
	b.color = CREAM
	b.ellipse(Vector2(at.x, at.y + 0.42 * s), Vector2(0.08, 0.08) * s, 10, at.z + 0.302 * s)


func _fish(b: PaperMesh, at: Vector2, length: float, z: float, angle: float) -> void:
	var d := Vector2(cos(angle), sin(angle))
	var n := d.orthogonal()
	var l := length
	b.color = Color(0.78, 0.4, 0.26) * _rng.randf_range(0.9, 1.05)
	b.polygon(PackedVector2Array([at + d * l * 0.5, at + d * l * 0.2 + n * l * 0.16, at - d * l * 0.25 + n * l * 0.1,
			at - d * l * 0.35, at - d * l * 0.25 - n * l * 0.1, at + d * l * 0.2 - n * l * 0.16]), z)
	b.polygon(PackedVector2Array([at - d * l * 0.33, at - d * l * 0.52 + n * l * 0.14, at - d * l * 0.5 - n * l * 0.14]), z)
	b.color = CREAM
	b.polygon(PackedVector2Array([at + d * l * 0.45, at + d * l * 0.15 - n * l * 0.15, at - d * l * 0.2 - n * l * 0.08, at + d * l * 0.1 - n * l * 0.04]), z + 0.002)
	b.color = PaperMesh.SUMI
	b.ellipse(at + d * l * 0.36 + n * l * 0.04, Vector2(0.02, 0.02), 6, z + 0.003)


func _crane(b: PaperMesh, at: Vector2, s: float, tint: Color, z: float) -> void:
	b.color = tint
	b.polygon(PackedVector2Array([at + Vector2(-0.5, 0.0) * s, at + Vector2(0.0, -0.2) * s, at + Vector2(0.55, 0.05) * s, at + Vector2(0.0, 0.1) * s]), z)
	b.color = tint.darkened(0.12)
	b.polygon(PackedVector2Array([at + Vector2(-0.1, 0.05) * s, at + Vector2(0.15, 0.05) * s, at + Vector2(-0.25, 0.65) * s]), z + 0.002)
	b.polygon(PackedVector2Array([at + Vector2(0.5, 0.02) * s, at + Vector2(0.6, 0.35) * s, at + Vector2(0.66, 0.3) * s]), z + 0.002)


## A floor lantern (andon): a paper box glowing in a dark frame.
func _andon(parent: Node3D, at: Vector3) -> void:
	var f := PaperMesh.new(_rng.randi())
	f.color = PaperMesh.TIMBER
	for c: Vector2 in [Vector2(-0.17, -0.17), Vector2(0.17, -0.17), Vector2(-0.17, 0.17), Vector2(0.17, 0.17)]:
		f.box(at + Vector3(c.x, 0.4, c.y), Vector3(0.05, 0.8, 0.05))
	f.frustum(4, Vector2(0.3, 0.3), Vector2(0.18, 0.18), 0.1, at + Vector3(0.0, 0.8, 0.0))
	parent.add_child(f.build())
	var p := PaperMesh.new(_rng.randi())
	p.color = PaperMesh.LANTERN.lerp(CREAM, 0.3)
	p.box(at + Vector3(0.0, 0.48, 0.0), Vector3(0.3, 0.5, 0.3))
	var lit := p.build(Color.WHITE, _glow * 0.8)
	lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(lit)
	var halo := Scenery.halo(1.1, Color(1.0, 0.62, 0.3, 0.45))
	halo.position = at + Vector3(0.0, 0.5, 0.3)
	parent.add_child(halo)


func _smoke() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 2.6
	p.preprocess = 2.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.7, 0.05, 0.15)
	# Out toward us first, under the stall's eave, then rising in the open
	# (straight up it went through the roof like a pale chimney: Julian).
	p.direction = Vector3(0.0, 0.25, 1.0)
	p.spread = 10.0
	p.gravity = Vector3(-0.2, 0.45, 0.0)
	p.initial_velocity_min = 0.9
	p.initial_velocity_max = 1.2
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 2.2))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(0.9, 0.88, 0.85, 0.0))
	fade.add_point(0.2, Color(0.9, 0.88, 0.85, 0.32))
	fade.set_color(fade.get_point_count() - 1, Color(0.9, 0.88, 0.85, 0.0))
	p.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	quad.material = PaperMesh.soft_ink(Color.WHITE)
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


# --- In the street -------------------------------------------------------------------

func _build_street_life() -> void:
	for s: Array in STALLS:
		var stall := MarketStall.new()
		stall.kind = s[1]
		stall.bounce_speed = 16.5
		stall.position = Vector3(s[0], ground_at(s[0]), 0.0)
		add_child(stall)
	for l: Array in STRINGS:
		var line := LanternString.new()
		line.span = l[1]
		line.height = 6.6
		line.sag = 1.0
		line.count = 4
		line.position = Vector3(l[0], ground_at(l[0]), 0.0)
		add_child(line)
	var n := 0
	for gal: Array in GALLERIES:
		_gallery(gal[0], gal[1], gal[2])
		var bundle := CraneBundle.new()
		bundle.id = "market_%d" % n
		bundle.count = 5
		bundle.position = Vector3(gal[0] + 1.5, gal[1], 0.0)
		add_child(bundle)
		# Lanterns along the walkway's rail.
		n += 1
	# Cherry trees at the back of the street, petals falling from them.
	for t: Array in [[3.0, 0.0, -3.2, 5.5], [56.0, 0.0, -7.3, 6.0], [74.0, 3.0, -7.3, 5.0], [119.0, 3.4, -3.6, 5.5], [131.0, 6.5, -5.0, 6.0]]:
		var tree := Scenery.sakura_tree(_rng, t[3], _rng.randf_range(-0.2, 0.2), 70)
		tree.position = Vector3(t[0], t[1], t[2])
		add_child(tree)
		var petals := _drift(24, BLOSSOM, Vector2(0.06, 0.045), Vector3(3.5, 1.5, 2.5))
		petals.position = Vector3(t[0], t[1] + t[3] * 0.7, t[2] + 2.0)
	# Lanterns strung on ropes behind the stalls (between tall poles).
	for row: Array in [[-6.0, 60.0, 0.0, -6.2, 7.2], [70.0, 146.0, 3.0, -6.2, 10.2]]:
		var x0: float = row[0]
		while x0 < row[1]:
			var x1 := x0 + 9.0
			var y: float = row[4]
			var z: float = row[3]
			var pole := PaperMesh.new(_rng.randi())
			pole.color = PaperMesh.TIMBER
			pole.box(Vector3(x0, (ground_at(x0) + y) * 0.5, z), Vector3(0.14, y - ground_at(x0) + 0.3, 0.14))
			add_child(pole.build())
			var rope := PaperMesh.new(1)
			rope.color = PaperMesh.SUMI
			var prev := Vector2(x0, y)
			for k in range(1, 9):
				var t := k / 8.0
				var p := Vector2(lerpf(x0, x1, t), y - 1.0 * 4.0 * t * (1.0 - t))
				rope.stroke(prev, p, 0.025, 0.025, z)
				prev = p
				if k < 8 and k % 2 == 1:
					_hang(Vector3(p.x, p.y, z), 0.75, 0.12)
			add_child(rope.build())
			x0 = x1


## A lacquered walkway up high on red posts at the back (in the picture,
## bridges of lacquer span between the tiers): a solid deck, a rail at the
## back, posts standing on the street behind him.
func _gallery(mid: float, top: float, width: float) -> void:
	_solid(Vector3(mid, top - 0.15, 0.0), Vector3(width, 0.3, 2.2))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	var x := mid - width * 0.5
	while x < mid + width * 0.5 - 0.01:
		var x1 := minf(x + _rng.randf_range(0.45, 0.7), mid + width * 0.5)
		b.color = Scenery.WOOD.lightened(0.12) * _rng.randf_range(0.85, 1.1)
		b.box(Vector3((x + x1) * 0.5, top - 0.1, 0.0), Vector3(x1 - x - 0.03, 0.2, 2.2))
		x = x1
	b.color = LACQUER
	b.box(Vector3(mid, top - 0.27, 1.12), Vector3(width + 0.1, 0.16, 0.08))
	b.box(Vector3(mid, top - 0.27, -1.12), Vector3(width + 0.1, 0.16, 0.08))
	for side: float in [-1.0, 1.0]:
		var px := mid + side * (width * 0.5 - 0.25)
		# Each post stands on what is really under it: the street, a quay,
		# the steps, or the canal's bed (one ending in mid-air: Julian).
		var g := foot_at(px)
		b.color = LACQUER
		b.box(Vector3(px, (g + top) * 0.5, -1.3), Vector3(0.12, top - g, 0.12))
		b.box(Vector3(px, top + 0.85, -1.15), Vector3(0.1, 1.7, 0.1))
		b.color = GOLD.darkened(0.15)
		b.frustum(6, Vector2(0.08, 0.08), Vector2(0.01, 0.01), 0.15, Vector3(px, top + 1.7, -1.15))
		# A bracket reaching in from the post, a lantern hung from it.
		b.color = LACQUER.darkened(0.1)
		b.box(Vector3(px - side * 0.25, top + 1.58, -1.15), Vector3(0.56, 0.06, 0.06))
		_hang(Vector3(px - side * 0.45, top + 1.56, -1.15), 0.9, 0.12)
	b.color = LACQUER.darkened(0.1)
	b.box(Vector3(mid, top + 0.95, -1.15), Vector3(width - 0.5, 0.08, 0.08))
	b.box(Vector3(mid, top + 0.5, -1.15), Vector3(width - 0.5, 0.06, 0.06))
	add_child(b.build())


# --- The Gilded Gate -----------------------------------------------------------------

## At the top of the steps: the gate to Hōshō's hall, its doors gold leaf,
## shut, two great lanterns, banners with his crest.
func _build_gate() -> void:
	var g := PLAZA.z
	var gx := END - 1.4
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = LACQUER.darkened(0.1)
	for pz: float in [1.7, -3.2]:
		b.box(Vector3(gx, g + 3.6, pz), Vector3(0.5, 7.2, 0.5))
	b.box(Vector3(gx, g + 6.6, -0.75), Vector3(0.7, 0.5, 6.2))
	b.box(Vector3(gx, g + 5.4, -0.75), Vector3(0.5, 0.3, 5.4))
	# The doors: gold leaf panels with studs, his crest.
	b.color = GOLD.darkened(0.12)
	b.box(Vector3(gx, g + 2.65, -0.75), Vector3(0.2, 5.3, 4.4))
	b.color = GOLD.darkened(0.4)
	b.box(Vector3(gx - 0.12, g + 2.65, -0.75), Vector3(0.03, 5.3, 0.05))
	add_child(b.build())
	var r := Scenery.tiled_roof(_rng, gx - 1.6, gx + 1.6, Vector2(g + 7.0, 2.6), Vector2(g + 8.6, -0.75), 4)
	add_child(r)
	var r2 := Scenery.tiled_roof(_rng, gx - 1.6, gx + 1.6, Vector2(g + 7.0, -4.1), Vector2(g + 8.6, -0.75), 4, false)
	add_child(r2)
	# The wall running off into the dark either side.
	var w := PaperMesh.new(_rng.randi())
	w.color = Color(0.48, 0.42, 0.4)
	w.box(Vector3(gx, g + 1.8, -6.5), Vector3(0.6, 3.6, 6.0))
	w.color = Color(0.3, 0.26, 0.26)
	w.box(Vector3(gx, g + 0.3, -6.5), Vector3(0.66, 0.6, 6.0))
	add_child(w.build())
	# Banners with his crest, great lanterns before the gate.
	for bx: float in [END - 10.0, END - 5.0]:
		var banner := Node3D.new()
		banner.position = Vector3(bx, g + 6.0, -2.8)
		add_child(banner)
		var c := PaperMesh.new(_rng.randi())
		c.color = RED_CLOTH
		c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.55, 0.0), Vector2(0.55, 0.0), Vector2(0.55, -3.4), Vector2(0.0, -3.0), Vector2(-0.55, -3.4)]), 0.3, 0.04, _rng), 0.0)
		c.color = GOLD
		c.ellipse(Vector2(0.0, -0.9), Vector2(0.4, 0.4), 16, 0.005)
		c.color = RED_CLOTH
		for p in 5:
			var a := TAU * p / 5.0 + PI * 0.5
			c.ellipse(Vector2(0.0, -0.9) + Vector2(cos(a), sin(a)) * 0.16, Vector2(0.11, 0.11), 8, 0.007)
		banner.add_child(c.build())
		Scenery.windswept(banner, 0.05, _rng)
		var pole := PaperMesh.new(_rng.randi())
		pole.color = PaperMesh.TIMBER
		pole.box(Vector3(bx + 0.6, g + 3.6, -2.8), Vector3(0.12, 7.2, 0.12))
		pole.box(Vector3(bx, g + 6.05, -2.8), Vector3(1.5, 0.08, 0.08))
		add_child(pole.build())
	for lx: float in [END - 7.5, END - 3.0]:
		var stand := PaperMesh.new(_rng.randi())
		stand.color = PaperMesh.TIMBER
		stand.box(Vector3(lx, g + 2.4, -1.8), Vector3(0.14, 4.8, 0.14))
		stand.box(Vector3(lx + 0.4, g + 4.75, -1.8), Vector3(0.9, 0.1, 0.1))
		add_child(stand.build())
		_hang(Vector3(lx + 0.7, g + 4.7, -1.8), 1.9, 0.2)
		_light(Vector3(lx + 0.7, g + 3.8, -0.8), village.lantern_energy, village.lantern_range * 1.1)
	_shine(END - 5.0, g, 9.0, 1.0)


# --- In front: the dark railing -----------------------------

func _build_foreground() -> void:
	var z := NEAR_Z - 0.4
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	var x := -10.0
	var prev := Vector2.INF
	while x < END + 6.0:
		var inside := x > BRIDGE.x - 1.0 and x < BRIDGE.y + 1.0
		var g := WATER_Y + 0.6 if x > CANAL.x and x < CANAL.y else ground_at(x)
		if not inside:
			b.color = Color(0.07, 0.06, 0.07)
			b.box(Vector3(x, g - 0.5, z), Vector3(0.2, 2.0, 0.2))
			b.color = Color(0.1, 0.08, 0.08)
			b.ellipse(Vector2(x, g + 0.56), Vector2(0.15, 0.11), 8, z + 0.11)
			# (No rail down the face of a cliff: the Rise's terraces.)
			if prev != Vector2.INF and absf(prev.y - g) < 1.2:
				for rh: float in [0.3, -0.05]:
					b.color = Color(0.07, 0.06, 0.07)
					b.extrude(PackedVector2Array([Vector2(prev.x, prev.y + rh), Vector2(x, g + rh), Vector2(x, g + rh + 0.1), Vector2(prev.x, prev.y + rh + 0.1)]),
							z - 0.05, z + 0.05)
			prev = Vector2(x, g)
		else:
			prev = Vector2.INF
		x += 2.6
	var rail := b.build()
	rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rail)


# --- The air: gold leaf drifting like snow ------------------------------------------

func _build_air() -> void:
	var flakes := _drift(220, GOLD, Vector2(0.08, 0.06), Vector3(END * 0.5 + 14.0, 7.0, 4.0))
	flakes.position = Vector3(END * 0.5, 6.0, 0.0)
	var mat := (flakes.mesh as QuadMesh).material as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = GOLD
	mat.emission_energy_multiplier = 0.6
	flakes.gravity = Vector3(-0.15, -0.25, 0.0)
	flakes.initial_velocity_min = 0.1
	flakes.initial_velocity_max = 0.4
	flakes.lifetime = 12.0
	flakes.preprocess = 12.0
	# Far flakes behind the stalls too.
	var far := _drift(160, GOLD.darkened(0.1), Vector2(0.1, 0.08), Vector3(END * 0.5 + 20.0, 9.0, 6.0))
	far.position = Vector3(END * 0.5, 9.0, -12.0)
	far.gravity = Vector3(-0.1, -0.2, 0.0)
	far.lifetime = 14.0
	far.preprocess = 14.0
	# Misty glow over the street.
	_mist(-8.5, -1.0, 3.5, Color(0.5, 0.36, 0.3, 0.35))


func _drift(amount: int, tint: Color, size: Vector2, extents: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(-1.0, -0.2, 0.0)
	p.spread = 30.0
	p.gravity = Vector3(-0.3, -0.35, 0.0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.8
	p.angle_max = 360.0
	p.angular_velocity_min = -160.0
	p.angular_velocity_max = 160.0
	var quad := QuadMesh.new()
	quad.size = size
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = tint
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = look
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p
