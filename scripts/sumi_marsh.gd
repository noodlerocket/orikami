class_name SumiMarsh
extends Node3D
## Sumi Marsh (docs/sumi_marsh_plan.md; design.md chapter 4: "oppressive and
## dark, bled ink pools into black swamps, home of Shimeri, the Sodden
## General"). Past Hōshō's hall: walking east through the hall's opened end
## (once he is beaten) fades to black and puts him at the marsh's west end;
## back west the same way.
##
## Its own place, far off along x (SHIFT). Everything that was water in the
## town is black ink here. A drowned dusk under a low ceiling of torn cloud,
## a band of pale jade fog on the horizon; bone-white dead trees, reeds,
## drowned torii, stilt houses; the only warm light is candles. Wading in
## shallow ink stains him (Ronin.soak_ink) and slows him; deep ink carries
## him back to the last shrine, until the Wax Coat (learned on the
## Wax-Maker's island, halfway) lets him float in it.
##
## Left to right (local x): the Weeping Steps and shrine 10; the Reed
## Shallows; the Drowned Village (MarshVillage) and shrine 11; the
## Wax-Maker's island; the Black Mere (swum, the broken aqueduct above) and
## shrine 12; the Causeway of Lost Names and shrine 13; Shimeri's Post
## (ShimeriPost), the arena, and the shut gate onward.

const SHIFT := 3000.0
const END := 404.0
## Where he arrives (local x) on the steps, and how far west he may climb
## before he is taken back to Hōshō's hall.
const ARRIVE_X := 4.0
const WEST_X := -6.0
## The ink's surface, the bed of the shallows (he wades) and of deep ink.
const INK_Y := 0.0
const SHALLOW_BED := -0.45
const DEEP_BED := -5.0
## The nearest edge of the ink (the dark foreground beyond it).
const NEAR_Z := 7.0
## The ground along the gameplay plane: [left, right, kind, top].
## kind "bank" (mud, at top), "shallow" (wading, the bed at SHALLOW_BED),
## "deep" (deep ink: carried off, or floating once waxed).
const GROUND := [
	[-14.0, 3.0, "steps", 0.6],
	[3.0, 18.0, "bank", 0.6],
	[18.0, 30.0, "shallow", 0.0],
	[30.0, 34.0, "bank", 0.5],
	[34.0, 50.0, "deep", 0.0],
	[50.0, 58.0, "bank", 0.6],
	[58.0, 72.0, "shallow", 0.0],
	[72.0, 80.0, "deep", 0.0],
	[80.0, 104.0, "bank", 0.8],
	[104.0, 118.0, "deep", 0.0],
	[118.0, 141.0, "shallow", 0.0],
	[141.0, 148.5, "deep", 0.0],
	[148.5, 155.0, "shallow", 0.0],
	[155.0, 162.0, "deep", 0.0],
	[162.0, 176.0, "shallow", 0.0],
	[176.0, 212.0, "bank", 0.8],
	[212.0, 236.0, "deep", 0.0],
	[236.0, 242.0, "bank", 0.5],
	[242.0, 252.0, "deep", 0.0],
	[252.0, 262.0, "bank", 0.6],
	[262.0, 278.0, "deep", 0.0],
	[278.0, 284.0, "bank", 0.5],
	[284.0, 300.0, "deep", 0.0],
	[300.0, 352.0, "bank", 0.9],
	[352.0, 406.0, "shallow", 0.0],
	[406.0, 430.0, "bank", 0.9],
]
## The steps down from Hōshō's hall: from (x, y) at the top to the bank.
const STEPS_TOP := Vector2(-14.0, 4.6)
const STEPS_FOOT := Vector2(3.0, 0.6)
## Boardwalks on posts over the ink: [left, right, top]. (The Drowned
## Village's porches are boardwalks too; MarshVillage builds the houses.)
const WALKS := [[34.0, 41.0, 1.1], [60.0, 66.5, 1.0], [103.0, 109.0, 1.6], [111.0, 113.5, 1.6],
		[118.0, 127.0, 1.8], [133.0, 141.0, 1.6], [148.5, 155.0, 0.55], [162.0, 170.0, 1.6]]
## Sodden planks that sink under him: [x, top at rest].
const SINKERS := [[42.6, 0.4], [45.6, 0.4], [156.7, 0.45], [159.7, 0.45]]
## Lotus pads floating on the ink: x.
const LOTUS := [48.2, 73.7, 76.3, 78.7]
## Sunken roofs poking up out of deep ink, to step on: [x, top, width].
const SUNKEN := [[115.6, 0.35, 1.3], [143.3, 0.3, 1.4], [146.0, 0.45, 1.2]]
## The dead tree whose branches are climbed to the heron's nest (cranes):
## its x, and its solid branches [x, top].
const NEST_TREE := 88.0
const NEST_LEDGES := [[86.7, 3.0], [89.5, 5.0], [86.9, 7.0]]   # (the lowest clears his head on the bank)
## The Black Mere's broken aqueduct: piers to climb [x, top], its channel
## [left, right, top] (a high route, glided between).
const PIERS := [[222.0, 1.2], [225.2, 3.2], [228.2, 5.2]]
const CHANNELS := [[229.5, 246.0, 6.5], [251.0, 268.5, 6.5]]
## The shrines: [x, ground, id].
const SHRINES := [[9.0, 0.6, "marsh"], [135.2, 1.6, "stilt_house"], [257.0, 0.6, "mere"], [344.0, 0.9, "causeway"]]
## The Wax-Maker's hut on her island.
const WAX_X := 190.0
## Creatures: ink frogs [x, y]; ink eels' pools [left, right]; sodden husks
## that rise from the ink [x, y]; husks standing guard [x, y].
const FROGS := [[32.0, 0.5], [53.0, 0.6], [56.5, 0.6], [70.0, -0.45], [92.0, 0.8], [239.0, 0.5], [281.0, 0.5]]
const EELS := [[141.0, 148.5], [212.0, 236.0], [262.0, 278.0], [284.0, 300.0]]
const RISERS := [[129.5, SHALLOW_BED], [151.5, SHALLOW_BED], [174.5, SHALLOW_BED]]
const GUARDS := [[308.0, 0.9], [318.0, 0.9], [334.0, 0.9]]
## Ink pouring from a height: [x, lip, bottom, width, z].
const CURTAINS := [[171.9, 5.9, SHALLOW_BED, 2.6, 1.55], [246.6, 6.3, INK_Y, 1.4, 0.0], [250.4, 6.3, INK_Y, 1.4, 0.0], [323.0, 7.6, 0.9, 2.2, 0.0]]

const SKY_TOP := Color(0.06, 0.06, 0.09)
const SKY_MID := Color(0.15, 0.15, 0.19)
const SKY_LOW := Color(0.3, 0.34, 0.33)
const FOG := Color(0.34, 0.38, 0.37)

var village: Village
var shrine: RestShrine
var houses: MarshVillage
var post: ShimeriPost
var wax_maker: WaxMaker
## The east end (opened with Shimeri's gate: the way on to Koinobori Skies).
var end_wall: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _far: Array[Node] = []
var _awake := true
var _ronin: Ronin
var _carried := false
var _was_wading := false
var _wade_clock := 0.0
var _last_y := 0.0
var _reeds: Array[Node3D] = []
var _wisps: Array[OmniLight3D] = []
var _shimmer: Array[MeshInstance3D] = []


static func in_marsh(x: float) -> bool:
	return x > SHIFT - 300.0 and not KoinoboriSkies.in_skies(x)


## The ground's top along the gameplay plane at a local x: a bank, or the
## bed of the ink (a walkway or a plank is not ground).
static func ground_at(x: float) -> float:
	if x < STEPS_FOOT.x:
		var t := clampf((x - STEPS_TOP.x) / (STEPS_FOOT.x - STEPS_TOP.x), 0.0, 1.0)
		return lerpf(STEPS_TOP.y, STEPS_FOOT.y, t)
	for g: Array in GROUND:
		if x >= g[0] and x < g[1]:
			match g[2]:
				"bank":
					return g[3]
				"shallow":
					return SHALLOW_BED
				"deep":
					return DEEP_BED
	return 0.9


static func kind_at(x: float) -> String:
	if x < STEPS_FOOT.x:
		return "steps"
	for g: Array in GROUND:
		if x >= g[0] and x < g[1]:
			return g[2]
	return "bank"


func _ready() -> void:
	_rng.seed = 5150
	position.x = SHIFT
	_build_sky()
	_build_far()
	_build_ink()
	_build_ground()
	_build_steps()
	_build_walks()
	for s: Array in SINKERS:
		var p := SinkingPlank.new()
		p.rest = s[1]
		p.position = Vector3(s[0], INK_Y, 0.0)
		add_child(p)
	for x: float in LOTUS:
		var pad := SinkingPlank.new()
		pad.lotus = true
		pad.length = 1.5
		pad.rest = 0.12
		pad.position = Vector3(x, INK_Y, 0.0)
		add_child(pad)
	for r: Array in SUNKEN:
		_sunken_roof(r[0], r[1], r[2])
	_build_nest_tree()
	_build_trees_and_reeds()
	_build_wax_island()
	_build_mere()
	_build_causeway()
	for c: Array in CURTAINS:
		var curtain := InkCurtain.new()
		curtain.width = c[3]
		curtain.bottom = c[2] - c[1]
		curtain.position = Vector3(c[0], c[1], c[4])
		add_child(curtain)
	houses = MarshVillage.new()
	houses.marsh = self
	add_child(houses)
	post = ShimeriPost.new()
	post.marsh = self
	add_child(post)
	for s: Array in SHRINES:
		var rest := RestShrine.new()
		rest.shrine_id = s[2]
		rest.position = Vector3(s[0], s[1], -0.9)
		rest.scale = Vector3.ONE * 1.2
		add_child(rest)
		if shrine == null:
			shrine = rest
	_build_creatures()
	_build_life()
	_build_foreground()
	_build_air()
	# The ends: the steps up west, the shut gate east (ShimeriPost).
	_solid(Vector3(STEPS_TOP.x - 1.0, 12.0, 0.0), Vector3(1.0, 30.0, 4.0)).set_meta(&"no_climb", true)
	end_wall = _solid(Vector3(END + 0.5, 12.0, 0.0), Vector3(1.0, 30.0, 4.0))
	end_wall.set_meta(&"no_climb", true)
	for x: float in [20.0, 70.0, 120.0, 160.0, 230.0, 290.0, 340.0]:
		Sound.place_loop(self, "marsh_night.ogg", Vector3(x, 1.0, -3.0), -14.0, 26.0)


## The marsh's creatures and busy things rest while he is elsewhere.
func set_awake(on: bool) -> void:
	if on == _awake:
		return
	_awake = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if _ronin == null:
		return
	var x := _ronin.global_position.x - SHIFT
	# Reeds lean away as he pushes through them (and spring back).
	for r: Node3D in _reeds:
		var dx := r.position.x - x
		var near := absf(dx) < 1.6 and absf(r.position.z) < 1.6 and absf(_ronin.global_position.y - r.position.y) < 2.0
		var want := (signf(dx) * 0.45 * (1.0 - absf(dx) / 1.6)) if near else 0.0
		var lean: float = r.get_meta(&"lean", 0.0)
		lean = lerpf(lean, want, 1.0 - exp(-delta * (10.0 if near else 3.0)))
		r.set_meta(&"lean", lean)
		var rest: Vector3 = r.get_meta(&"wind_rest")
		r.rotation.z = rest.z - lean + 0.05 * sin(t * 1.7 + r.position.x)
	# The will-o'-wisps drift and breathe.
	for i in _wisps.size():
		var w := _wisps[i]
		var home: Vector3 = w.get_meta(&"home")
		w.position = home + Vector3(1.6 * sin(t * 0.21 + i * 2.1), 0.5 * sin(t * 0.37 + i), 0.8 * sin(t * 0.17 + i * 1.3))
		w.light_energy = 0.55 + 0.25 * sin(t * 1.3 + i * 0.7)
	for i in _shimmer.size():
		var s := _shimmer[i]
		s.scale.x = 1.0 + 0.15 * sin(t * 1.1 + i * 1.7)


func _physics_process(delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position - global_position
	if at.x < -40.0:
		return
	var kind := kind_at(at.x)
	var y := at.y
	# Into the ink from above: a splash of black drops.
	if (kind == "shallow" or kind == "deep") and _last_y >= INK_Y and y < INK_Y:
		WaterFx.splash(self, Vector3(at.x, INK_Y, 0.0), clampf(-_ronin.velocity.y / 10.0, 0.4, 1.4), true)
		Sound.play(self, &"splash", -6.0)
	_last_y = y
	if kind == "shallow" and y < INK_Y + 0.05 and _ronin.is_on_floor():
		_ronin.wading = true
		_was_wading = true
		_ronin.soak_ink(delta)
		if absf(_ronin.velocity.x) > 0.5:
			_wade_clock += delta
			if _wade_clock > 0.3:
				_wade_clock = 0.0
				WaterFx.splash(self, Vector3(at.x, INK_Y, 0.0), 0.3, true)
				Sound.play(self, &"wade", -10.0)
	elif kind == "deep" and y < INK_Y - 0.35:
		_was_wading = true
		_ronin.soak_ink(delta)
		if not _carried:
			_carried = true
			if _ronin.deep_water():
				WaterFx.splash(self, Vector3(at.x, INK_Y, 0.0), 1.3, true)
		if _ronin.swimming and absf(_ronin.velocity.x) > 0.5:
			_wade_clock += delta
			if _wade_clock > 0.4:
				_wade_clock = 0.0
				WaterFx.splash(self, Vector3(at.x, INK_Y, 0.0), 0.4, true)
				Sound.play(self, &"wade", -9.0)
	elif _was_wading:
		_was_wading = false
		_ronin.wading = false
	if y > INK_Y + 0.6:
		_carried = false


# --- Helpers ------------------------------------------------------------------------

func _solid(center: Vector3, size: Vector3) -> StaticBody3D:
	return village._add_solid(center + Vector3(SHIFT, 0.0, 0.0), size)


func _flat(b: PaperMesh) -> MeshInstance3D:
	var mesh := b.build(Color.WHITE, 0.0, true)
	(mesh.material_override as StandardMaterial3D).disable_fog = true
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


func _mesh(b: PaperMesh, glow: float = 0.0) -> MeshInstance3D:
	var mesh := b.build(Color.WHITE, glow)
	add_child(mesh)
	return mesh


func _light(at: Vector3, energy: float, reach: float, tint: Color = MarshKit.CANDLE) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = village.light_falloff
	light.position = at
	add_child(light)
	return light


## A pale or warm streak on the ink under a light.
func _shine(x: float, width: float, tint: Color, z: float = 2.0) -> void:
	var s := Scenery.reflection(Vector2(width, 9.0), tint)
	s.position = Vector3(x, INK_Y + 0.012, z)
	add_child(s)
	_shimmer.append(s)


func _mist(z: float, bottom: float, top: float, tint: Color, left: float = -140.0, right: float = END + 320.0) -> void:
	var m := PaperMesh.new(1)
	m.fade_quad(Vector3(left, bottom, z), Vector3(right, bottom, z), Vector3(right, top, z), Vector3(left, top, z), tint, Color(tint, 0.0))
	add_child(m.build_veil())


## A post from a height down into the ink to its bed (or the bank) under its own x.
func _post(b: PaperMesh, x: float, top: float, z: float, r: float = 0.09) -> void:
	var foot := ground_at(x) - 0.3
	b.frustum(6, Vector2(r, r), Vector2(r * 0.9, r * 0.9), top - foot, Vector3(x, foot, z))


# --- The sky and the far marsh -----------------------------------------------------

func _build_sky() -> void:
	var left := -140.0
	var right := END + 320.0
	var sky := PaperMesh.new(1)
	sky.shade_jitter = 0.0
	sky.fade_quad(Vector3(left, 120.0, -53.0), Vector3(right, 120.0, -53.0), Vector3(right, 26.0, -53.0), Vector3(left, 26.0, -53.0), SKY_TOP, SKY_MID)
	sky.fade_quad(Vector3(left, 26.0, -53.0), Vector3(right, 26.0, -53.0), Vector3(right, 3.0, -53.0), Vector3(left, 3.0, -53.0), SKY_MID, SKY_LOW)
	sky.fade_quad(Vector3(left, 3.0, -53.0), Vector3(right, 3.0, -53.0), Vector3(right, -30.0, -53.0), Vector3(left, -30.0, -53.0), SKY_LOW, SKY_LOW.darkened(0.3))
	_flat(sky)
	# Where the moon is, behind the cloud: only a faint pale smear.
	var smear := PaperMesh.new(1)
	for k in 32:
		var a0 := TAU * k / 32.0
		var a1 := TAU * (k + 1) / 32.0
		var at := Vector3(120.0, 22.0, -52.5)
		smear.fade_quad(at + Vector3(cos(a0) * 1.5, sin(a0) * 0.9, 0.0), at + Vector3(cos(a1) * 1.5, sin(a1) * 0.9, 0.0),
				at + Vector3(cos(a1) * 14.0, sin(a1) * 7.0, 0.0), at + Vector3(cos(a0) * 14.0, sin(a0) * 7.0, 0.0),
				Color(0.62, 0.68, 0.64, 0.22), Color(0.62, 0.68, 0.64, 0.0))
	add_child(smear.build_veil(true))
	# The low ceiling of torn cloud, layer on layer, darker underneath.
	for row in 3:
		var y := 30.0 - row * 5.5
		var z := -51.0 + row * 1.5
		var x := left
		while x < right:
			var w := _rng.randf_range(26.0, 48.0)
			var h := _rng.randf_range(3.0, 6.0)
			var c := PaperMesh.new(_rng.randi())
			c.shade_jitter = 0.0
			var mid := Vector2(x + w * 0.5, y + _rng.randf_range(-2.0, 2.0))
			var outline := PackedVector2Array()
			for k in 22:
				var a := TAU * k / 22.0
				outline.append(mid + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.5 * (0.6 if sin(a) < 0.0 else 1.0)))
			var tone := Color(0.12, 0.12, 0.16).lerp(Color(0.2, 0.21, 0.24), row / 2.0)
			c.color = tone
			c.torn_sheet(PaperMesh.tear(outline, 0.9, 0.18, _rng), z, tone.lightened(0.22), 0.07)
			_flat(c)
			x += w * _rng.randf_range(0.6, 0.85)
	# Low hills far off, almost lost in the fog.
	for layer: Array in [[-47.0, -1.0, 7.0, Color(0.25, 0.28, 0.28), 0.05], [-42.0, -1.5, 4.0, Color(0.2, 0.23, 0.23), 0.08]]:
		var hills := PaperMesh.new(_rng.randi())
		hills.shade_jitter = 0.0
		var line := PackedVector2Array()
		var x := left
		var freq: float = layer[4]
		while x < right:
			line.append(Vector2(x, layer[1] + layer[2] * pow(absf(sin(x * freq + layer[0])), 1.6)))
			x += _rng.randf_range(2.5, 5.0)
		line.append(Vector2(right, layer[1]))
		var outline := PaperMesh.tear(line, 1.0, 0.25, _rng, false)
		outline.append(Vector2(right, -30.0))
		outline.append(Vector2(left, -30.0))
		hills.color = layer[3]
		hills.torn_sheet(outline, layer[0], (layer[3] as Color).lightened(0.18), 0.08)
		_flat(hills)
		_mist(layer[0] + 0.5, -4.0, layer[1] + 5.0, Color(FOG, 0.85))


## Far off: drowned groves of dead trees in fog, paler with distance; a
## drowned pagoda leaning out of the ink; stilt houses with one dim light;
## the aqueduct's line marching away.
func _build_far() -> void:
	for layer: Array in [[-38.0, 0.55, 1.0], [-28.0, 0.42, 1.3], [-19.0, 0.3, 1.7]]:
		var z: float = layer[0]
		var fade: float = layer[1]
		var scale_k: float = layer[2]
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.0
		var tone := Color(0.08, 0.09, 0.1).lerp(FOG, fade)
		var x := -120.0
		while x < END + 320.0:
			var h := _rng.randf_range(4.0, 9.0) * scale_k
			b.color = tone * _rng.randf_range(0.92, 1.06)
			_far_tree(b, Vector2(x, -0.2), h, z)
			x += _rng.randf_range(4.0, 11.0) * scale_k
		# A strip of reeds and mud along their foot.
		var line := PackedVector2Array()
		x = -120.0
		while x < END + 320.0:
			line.append(Vector2(x, _rng.randf_range(0.1, 0.6) * scale_k))
			x += _rng.randf_range(0.5, 1.5)
		line.append(Vector2(END + 320.0, -3.0))
		line.append(Vector2(-120.0, -3.0))
		b.color = tone.darkened(0.1)
		b.polygon(PaperMesh.tear(line, 0.6, 0.1, _rng, false), z + 0.05)
		_flat(b)
		_mist(z + 1.0, -2.0, 4.0 * scale_k, Color(FOG, 0.55))
	# The drowned pagoda, five roofs leaning, far left of the Mere.
	var p := PaperMesh.new(_rng.randi())
	p.shade_jitter = 0.0
	var px := 250.0
	var tone := Color(0.08, 0.09, 0.1).lerp(FOG, 0.38)
	for k in 5:
		var y := -1.0 + k * 3.2
		var w := 6.0 - k * 0.8
		var lean := k * 0.35
		p.color = tone.darkened(0.08)
		p.rect(Vector2(px + lean, y + 1.4), Vector2(w * 0.55, 2.8), -33.0)
		p.color = tone.darkened(0.18)
		p.polygon(PackedVector2Array([Vector2(px + lean - w * 0.75, y + 2.6), Vector2(px + lean + w * 0.75, y + 2.6 + 0.3),
				Vector2(px + lean + w * 0.4, y + 3.4), Vector2(px + lean - w * 0.4, y + 3.2)]), -32.95)
	p.color = tone.darkened(0.2)
	p.stroke(Vector2(px + 1.8, 14.5), Vector2(px + 2.4, 19.0), 0.15, 0.05, -32.9)
	_flat(p)
	# Far stilt houses, one with a dim light.
	var h := PaperMesh.new(_rng.randi())
	h.shade_jitter = 0.0
	for spot: Array in [[60.0, -24.0], [148.0, -26.0], [205.0, -23.0], [330.0, -25.0]]:
		var hx: float = spot[0]
		var hz: float = spot[1]
		var c := Color(0.08, 0.09, 0.1).lerp(FOG, 0.3)
		h.color = c
		for sx: float in [-1.6, -0.4, 0.8, 1.8]:
			h.rect(Vector2(hx + sx, 0.4), Vector2(0.12, 2.0), hz)
		h.rect(Vector2(hx, 2.4), Vector2(4.4, 2.2), hz + 0.01)
		h.color = c.darkened(0.15)
		h.polygon(PackedVector2Array([Vector2(hx - 3.0, 3.4), Vector2(hx + 3.0, 3.4), Vector2(hx + 0.4, 5.6), Vector2(hx - 0.6, 5.6)]), hz + 0.02)
	_flat(h)
	var lamp := PaperMesh.new(1)
	lamp.color = Color(0.9, 0.66, 0.4)
	lamp.rect(Vector2(148.5, 2.3), Vector2(0.5, 0.6), -25.97)
	_flat(lamp)
	# The aqueduct far away across the Mere: a line of arches into the fog.
	var a := PaperMesh.new(_rng.randi())
	a.shade_jitter = 0.0
	var ac := Color(0.08, 0.09, 0.1).lerp(FOG, 0.45)
	a.color = ac
	var ax := 190.0
	while ax < 340.0:
		a.rect(Vector2(ax, 2.5), Vector2(0.9, 7.0), -16.0)
		if not (ax > 238.0 and ax < 258.0):
			a.rect(Vector2(ax + 3.0, 6.4), Vector2(6.2, 1.0), -16.01)
		ax += 6.0
	_flat(a)


func _far_tree(b: PaperMesh, foot: Vector2, h: float, z: float) -> void:
	var lean := _rng.randf_range(-0.25, 0.25)
	var top := foot + Vector2(lean * h, h)
	b.stroke(foot, top, h * 0.045, h * 0.012, z)
	for k in 4:
		var t := _rng.randf_range(0.45, 0.9)
		var from := foot.lerp(top, t)
		var side := -1.0 if k % 2 == 0 else 1.0
		var to := from + Vector2(side * _rng.randf_range(0.2, 0.45) * h, _rng.randf_range(0.05, 0.3) * h)
		b.stroke(from, to, h * 0.016, h * 0.004, z + 0.001)


# --- The ink ------------------------------------------------------------------------

func _build_ink() -> void:
	var x := -40.0
	while x < END + 40.0:
		var x1 := x + 20.0
		var w := PaperMesh.new(1)
		w.shade_jitter = 0.03
		w.texture_scale = 0.0
		w.color = MarshKit.INK
		w.quad(Vector3(x, INK_Y, -40.0), Vector3(x1, INK_Y, -40.0), Vector3(x1, INK_Y, NEAR_Z), Vector3(x, INK_Y, NEAR_Z), Vector3.UP)
		w.color = Color(0.01, 0.01, 0.02)
		w.quad(Vector3(x, INK_Y, NEAR_Z), Vector3(x1, INK_Y, NEAR_Z), Vector3(x1, -14.0, NEAR_Z), Vector3(x, -14.0, NEAR_Z))
		var ink := w.build()
		var gloss := ink.material_override as StandardMaterial3D
		gloss.roughness = 0.06
		gloss.metallic_specular = 1.0
		ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ink)
		x = x1
	# The fog's pale light lying on the ink in long streaks, nearer ones
	# brighter (the ink is a mirror for the grey sky).
	x = -30.0
	while x < END + 30.0:
		_shine(x, _rng.randf_range(1.0, 2.4), Color(0.6, 0.68, 0.66, 0.14), _rng.randf_range(-6.0, 3.0))
		x += _rng.randf_range(4.0, 7.0)
	x = -30.0
	while x < END + 30.0:
		var near := Scenery.reflection(Vector2(_rng.randf_range(2.0, 5.0), 3.0), Color(0.55, 0.63, 0.62, _rng.randf_range(0.08, 0.16)))
		near.position = Vector3(x, INK_Y + 0.013, _rng.randf_range(3.6, 6.4))
		add_child(near)
		x += _rng.randf_range(3.0, 6.0)
	# Lotus leaves and soaked scraps of paper floating in the foreground ink.
	var leaves := PaperMesh.new(_rng.randi())
	leaves.texture_world = false
	x = -20.0
	while x < END + 20.0:
		var leaf := PaperMesh.new(_rng.randi())
		leaf.texture_world = false
		MarshKit.lotus_leaf(leaf, _rng.randf_range(0.35, 0.8), _rng)
		var m := leaf.build()
		m.position = Vector3(x, INK_Y, _rng.randf_range(3.6, 6.2))
		m.rotation.y = _rng.randf() * TAU
		add_child(m)
		if _rng.randf() < 0.6:
			leaves.color = Color(0.62, 0.6, 0.55).darkened(_rng.randf_range(0.1, 0.4))
			var c := Vector3(x + _rng.randf_range(1.0, 3.0), INK_Y + 0.02, _rng.randf_range(3.4, 6.4))
			var a := _rng.randf() * TAU
			var w := _rng.randf_range(0.12, 0.3)
			leaves.quad(c + Vector3(cos(a), 0.0, sin(a)) * w, c + Vector3(cos(a + 1.7), 0.0, sin(a + 1.7)) * w * 0.8,
					c + Vector3(cos(a + PI), 0.0, sin(a + PI)) * w, c + Vector3(cos(a + 4.4), 0.0, sin(a + 4.4)) * w * 0.7, Vector3.UP)
		x += _rng.randf_range(3.0, 7.0)
	add_child(leaves.build())
	village._add_rain_splashes(SHIFT - 20.0, SHIFT + END + 20.0, INK_Y)


# --- The ground ----------------------------------------------------------------------

func _build_ground() -> void:
	for g: Array in GROUND:
		var left: float = g[0]
		var right: float = g[1]
		match g[2]:
			"bank":
				_bank(left, right, g[3])
			"shallow":
				_solid(Vector3((left + right) * 0.5, SHALLOW_BED - 3.0, 0.0), Vector3(right - left, 6.0, 4.0))
			"deep":
				_solid(Vector3((left + right) * 0.5, DEEP_BED - 3.0, 0.0), Vector3(right - left, 6.0, 4.0))
				Ronin.float_surface(self, left, right, INK_Y, 1.0)


## A mud bank: solid, its top uneven and mossy, sloping into the ink at its
## ends, tufts of grass and small reeds, puddles of ink.
func _bank(left: float, right: float, top: float) -> void:
	_solid(Vector3((left + right) * 0.5, top - 4.0, 0.0), Vector3(right - left, 8.0, 4.0))
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 6.0, right)
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.12
		b.wrinkle_depth = 1.0
		var profile := PackedVector2Array()
		var a := x - (0.9 if x == left else 0.0)
		var e := x1 + (0.9 if x1 == right else 0.0)
		profile.append(Vector2(a, -1.0))
		if x == left:
			profile.append(Vector2(x - 0.3, top * 0.4))
		var sx := x
		while sx < x1:
			profile.append(Vector2(sx, top + _rng.randf_range(-0.03, 0.03)))
			sx += _rng.randf_range(0.6, 1.2)
		profile.append(Vector2(x1, top))
		if x1 == right:
			profile.append(Vector2(x1 + 0.3, top * 0.4))
		profile.append(Vector2(e, -1.0))
		b.color = MarshKit.MUD
		b.extrude(profile, -6.5, 3.2)
		# The top: darker mud, moss, a few flat stones.
		var mx := x
		while mx < x1 - 0.3:
			var w := _rng.randf_range(0.6, 1.8)
			b.color = (MarshKit.MOSS if _rng.randf() < 0.45 else MarshKit.MUD_TOP).darkened(_rng.randf_range(0.0, 0.3))
			b.frustum(7, Vector2(w * 0.5, _rng.randf_range(0.3, 1.0)), Vector2(w * 0.48, 0.3), 0.012, Vector3(mx + w * 0.5, top, _rng.randf_range(-5.5, 2.4)), _rng.randf() * TAU)
			mx += w * _rng.randf_range(0.6, 1.1)
		b.color = MarshKit.INK
		for k in int((x1 - x) / 3.0):
			var px := _rng.randf_range(x + 0.5, x1 - 0.5)
			var pz := _rng.randf_range(-4.0, 2.0)
			b.frustum(10, Vector2(_rng.randf_range(0.3, 0.7), _rng.randf_range(0.2, 0.4)), Vector2(0.3, 0.2) * 0.98, 0.01, Vector3(px, top + 0.004, pz))
		_mesh(b)
		# Grass tufts along the front and back edges.
		for k in int((x1 - x) * 0.8):
			var tuft := MarshKit.reeds(_rng, _rng.randf_range(0.3, 0.7), _rng.randf_range(0.25, 0.5), 0.15, MarshKit.REED.darkened(0.2))
			var tz := _rng.randf_range(1.6, 3.0) if _rng.randf() < 0.5 else _rng.randf_range(-6.0, -2.0)
			tuft.position = Vector3(_rng.randf_range(x, x1), top, tz)
			add_child(tuft)
			Scenery.windswept(tuft, -0.03, _rng)
		x = x1
	village._add_rain_splashes(SHIFT + left, SHIFT + right, top)


## The way in: weathered stone steps down from the west (Hōshō's back
## stair), a half-sunk torii at their foot.
func _build_steps() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	var n := 14
	for i in n:
		var x0 := lerpf(STEPS_TOP.x, STEPS_FOOT.x, float(i) / n)
		var x1 := lerpf(STEPS_TOP.x, STEPS_FOOT.x, float(i + 1) / n)
		var y := lerpf(STEPS_TOP.y, STEPS_FOOT.y, float(i) / n)
		b.color = MarshKit.STONE.darkened(_rng.randf_range(0.05, 0.3))
		b.box(Vector3((x0 + x1) * 0.5 - 0.1, y - 0.6, -1.4), Vector3(x1 - x0 + 0.2, 1.2, 4.6))
		b.color = MarshKit.MOSS
		b.box(Vector3((x0 + x1) * 0.5, y + 0.005, 0.85), Vector3(x1 - x0, 0.01, 0.4))
	# Their mass under, down into the ink.
	b.color = MarshKit.STONE_DARK
	b.extrude(PackedVector2Array([Vector2(STEPS_TOP.x - 2.0, STEPS_TOP.y - 0.5), Vector2(STEPS_FOOT.x, STEPS_FOOT.y - 0.5), Vector2(STEPS_FOOT.x, -2.0), Vector2(STEPS_TOP.x - 2.0, -2.0)]),
			-3.7, 0.9)
	# A landing at the top, under the mist, and the old wall beside them.
	b.color = MarshKit.STONE.darkened(0.2)
	b.box(Vector3(STEPS_TOP.x - 2.5, STEPS_TOP.y - 0.5, -1.4), Vector3(5.0, 1.0, 4.6))
	b.color = Color(0.22, 0.22, 0.24)
	b.box(Vector3(STEPS_TOP.x - 1.0, STEPS_TOP.y + 2.5, -4.2), Vector3(8.0, 7.0, 0.8))
	_mesh(b)
	# Solid: a slope.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for z: float in [-1.4, 1.4]:
		pts.append(Vector3(STEPS_TOP.x - 6.0, STEPS_TOP.y, z))
		pts.append(Vector3(STEPS_TOP.x, STEPS_TOP.y, z))
		pts.append(Vector3(STEPS_FOOT.x, STEPS_FOOT.y, z))
		pts.append(Vector3(STEPS_FOOT.x, -3.0, z))
		pts.append(Vector3(STEPS_TOP.x - 6.0, -3.0, z))
	hull.points = pts
	shape.shape = hull
	body.add_child(shape)
	# (Kept in the village, always in the physics: see ThousandGates._build_path.)
	body.position.x = SHIFT
	village.add_child(body)
	# The half-sunk torii at the edge of the shallows, leaning.
	var torii := Scenery.torii(_rng, Color(0.3, 0.13, 0.11))
	torii.position = Vector3(17.0, -1.1, -2.6)
	torii.rotation.z = 0.06
	torii.scale = Vector3.ONE * 1.1
	add_child(torii)
	# A drowned jizō by the shrine, in a red bib, ink to its waist.
	var j := PaperMesh.new(_rng.randi())
	j.color = MarshKit.STONE
	j.frustum(8, Vector2(0.22, 0.2), Vector2(0.18, 0.16), 0.6, Vector3(11.6, 0.6, -1.2))
	j.loft([PaperMesh.oval(Vector3(11.6, 1.18, -1.2), Vector2(0.14, 0.13), 8), PaperMesh.oval(Vector3(11.6, 1.32, -1.2), Vector2(0.15, 0.14), 8),
			PaperMesh.oval(Vector3(11.6, 1.46, -1.2), Vector2(0.07, 0.07), 8)])
	j.color = Color(0.5, 0.16, 0.13)
	j.frustum(8, Vector2(0.21, 0.19), Vector2(0.12, 0.12), 0.2, Vector3(11.6, 1.0, -1.2))
	_mesh(j)
	# Votive candles at its feet.
	var wax := PaperMesh.new(1)
	var flame := PaperMesh.new(2)
	for k in 3:
		MarshKit.candle(wax, flame, Vector3(11.2 + k * 0.25, 0.6, -0.8), 0.12 + k * 0.04)
	_mesh(wax)
	add_child(flame.build(Color.WHITE, 2.0, true))
	_light(Vector3(11.5, 1.0, -0.4), 0.9, 4.0)
	_shine(11.5, 0.7, Color(1.0, 0.7, 0.4, 0.2))


## Boardwalks on posts over the ink: grey sodden boards, some missing,
## posts down into the bed, a rope rail on some.
func _build_walks() -> void:
	for w: Array in WALKS:
		var left: float = w[0]
		var right: float = w[1]
		var top: float = w[2]
		_solid(Vector3((left + right) * 0.5, top - 0.15, 0.0), Vector3(right - left, 0.3, 3.0))
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.14
		var x := left
		while x < right - 0.01:
			var x1 := minf(x + _rng.randf_range(0.26, 0.36), right)
			b.color = MarshKit.WOOD_WET.lightened(_rng.randf_range(0.0, 0.15))
			b.box(Vector3((x + x1) * 0.5, top - 0.05 + _rng.randf_range(-0.015, 0.0), 0.0), Vector3(x1 - x - 0.025, 0.1, 2.8 + _rng.randf_range(-0.2, 0.1)))
			x = x1
		b.color = Color(0.1, 0.09, 0.09)
		for z: float in [-1.25, 1.25]:
			b.box(Vector3((left + right) * 0.5, top - 0.17, z), Vector3(right - left, 0.12, 0.14))
		var px := left + 0.15
		while px <= right:
			for z: float in [-1.3, 1.3]:
				b.color = MarshKit.WOOD_WET.darkened(0.1)
				_post(b, px, top - 0.1, z)
			px += 2.0
		_mesh(b)


## The ridge of a drowned house's roof poking out of the ink: tiles under a
## film of ink, moss, a broken ridge-end.
func _sunken_roof(x: float, top: float, width: float) -> void:
	_solid(Vector3(x, top - 0.6, 0.0), Vector3(width, 1.2, 2.4))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.color = Color(0.12, 0.12, 0.13)
	b.extrude(PackedVector2Array([Vector2(x - width * 0.5 - 0.3, -0.8), Vector2(x - 0.1, top), Vector2(x + 0.1, top), Vector2(x + width * 0.5 + 0.3, -0.8)]), -1.6, 1.6)
	b.color = Color(0.2, 0.2, 0.21)
	b.box(Vector3(x, top + 0.04, 0.0), Vector3(0.24, 0.08, 3.3))
	b.color = MarshKit.MOSS
	b.box(Vector3(x + 0.2, top - 0.05, 0.7), Vector3(0.4, 0.06, 0.8))
	_mesh(b)


## The dead tree on the bank before the village, its branches solid: climbed
## to a heron's old nest with cranes in it.
func _build_nest_tree() -> void:
	var tree := MarshKit.dead_tree(_rng, 8.6, 0.04, 0.42, 4)
	tree.position = Vector3(NEST_TREE, 0.8, -0.9)
	add_child(tree)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.texture_world = false
	for l: Array in NEST_LEDGES:
		var lx: float = l[0]
		var ly: float = l[1]
		_solid(Vector3(lx, ly - 0.12, 0.0), Vector3(1.6, 0.24, 1.4))
		b.color = MarshKit.BONE.darkened(_rng.randf_range(0.05, 0.2))
		var trunk := Vector3(NEST_TREE + 0.05, ly - 0.35, -0.9)
		MarshKit.limb(b, trunk, Vector3(lx + signf(lx - NEST_TREE) * 0.75, ly - 0.08, 0.0), 0.2, 0.1, 6)
		MarshKit.limb(b, Vector3(lx - 0.8, ly - 0.12, 0.05), Vector3(lx + 0.8, ly - 0.1, -0.05), 0.12, 0.1, 6)
	# The nest: a heap of twigs and old paper on the top branch.
	var n: Array = NEST_LEDGES[NEST_LEDGES.size() - 1]
	b.color = Color(0.3, 0.27, 0.22)
	for k in 26:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.25, 0.5)
		var c := Vector3(n[0] + cos(a) * r, n[1] + 0.06 + _rng.randf_range(0.0, 0.14), sin(a) * r * 0.6)
		MarshKit.limb(b, c, c + Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.05, 0.05), _rng.randf_range(-0.3, 0.3)), 0.025, 0.02, 4)
	add_child(b.build())
	var bundle := CraneBundle.new()
	bundle.id = "marsh_nest"
	bundle.count = 6
	bundle.position = Vector3(n[0], n[1], 0.0)
	add_child(bundle)


## Dead trees and reeds through the whole marsh, at the back, in the
## shallows, along the banks.
func _build_trees_and_reeds() -> void:
	var x := -6.0
	while x < END:
		# Trees behind the gameplay plane, standing in the ink or on banks.
		var z := _rng.randf_range(-12.0, -4.5)
		var tree := MarshKit.dead_tree(_rng, _rng.randf_range(5.0, 10.0), _rng.randf_range(-0.2, 0.2), _rng.randf_range(0.2, 0.4), _rng.randi_range(1, 3))
		tree.position = Vector3(x, minf(ground_at(x), 0.4) if absf(z) < 6.0 else 0.0, z)
		if not (x > 100.0 and x < 172.0 and z > -7.0):  # (the stilt houses stand there)
			add_child(tree)
		x += _rng.randf_range(7.0, 14.0)
	x = 18.0
	while x < END:
		var k := kind_at(x)
		if k == "shallow" or k == "deep":
			var clump := MarshKit.reeds(_rng, _rng.randf_range(0.8, 2.0), _rng.randf_range(1.2, 2.2), 0.5)
			var court := x > ShimeriPost.ARENA.x - 2.0   # (his court: clear in front, for the fight)
			var z := _rng.randf_range(-3.5, -1.8) if (_rng.randf() < 0.6 or court) else _rng.randf_range(1.6, 2.6)
			clump.position = Vector3(x, INK_Y, z)
			add_child(clump)
			Scenery.windswept(clump, -0.04, _rng)
			# Some stand right in his way in the shallows and part as he goes.
			if k == "shallow" and _rng.randf() < 0.55 and not _under_walk(x) and not court:
				var near := MarshKit.reeds(_rng, 0.9, _rng.randf_range(1.0, 1.6), 0.25)
				near.position = Vector3(x + 1.2, INK_Y, 0.3)
				add_child(near)
				near.set_meta(&"wind_rest", near.rotation)  # (swayed and parted here, not by the village)
				_reeds.append(near)
		x += _rng.randf_range(2.5, 5.5)


func _under_walk(x: float) -> bool:
	for w: Array in WALKS:
		if x > w[0] - 1.0 and x < w[1] + 1.0:
			return true
	return false


# --- The Wax-Maker's island -------------------------------------------------------

## Haze trees in faded rust, the Wax-Maker's hut with its press and pot,
## cakes of wax drying on racks, candles hung on strings, warm light.
func _build_wax_island() -> void:
	var g := 0.8
	# The hut, thatched, its front open: a hearth glowing, the press.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	var hx := WAX_X + 2.5
	b.color = MarshKit.WOOD_WET.lightened(0.05)
	for px: float in [hx - 3.2, hx + 3.2]:
		for pz: float in [-6.0, -3.2]:
			b.frustum(6, Vector2(0.1, 0.1), Vector2(0.09, 0.09), 3.3, Vector3(px, g, pz))
	b.color = Color(0.25, 0.22, 0.2)
	b.box(Vector3(hx, g + 1.6, -6.1), Vector3(6.4, 3.2, 0.12))
	b.box(Vector3(hx - 3.25, g + 1.6, -4.6), Vector3(0.12, 3.2, 3.0))
	b.box(Vector3(hx + 3.25, g + 1.6, -4.6), Vector3(0.12, 3.2, 3.0))
	b.color = Color(0.55, 0.5, 0.4)
	b.box(Vector3(hx + 1.2, g + 1.6, -6.03), Vector3(1.6, 1.0, 0.04))  # a paper window
	# Its hearth: a low clay stove, a pot of molten wax on it.
	b.color = Color(0.34, 0.26, 0.22)
	b.box(Vector3(hx - 1.5, g + 0.4, -4.8), Vector3(1.2, 0.8, 1.0))
	b.color = Color(0.18, 0.16, 0.15)
	b.frustum(10, Vector2(0.42, 0.42), Vector2(0.48, 0.48), 0.45, Vector3(hx - 1.5, g + 0.8, -4.8))
	# The wax press: a heavy beam on a post, a wedge, a trough.
	b.color = Color(0.3, 0.24, 0.2)
	b.box(Vector3(hx + 1.4, g + 0.9, -4.6), Vector3(0.3, 1.8, 0.3))
	b.box(Vector3(hx + 0.6, g + 1.5, -4.6), Vector3(2.4, 0.26, 0.3))
	b.box(Vector3(hx + 0.4, g + 0.3, -4.6), Vector3(1.3, 0.3, 0.6))
	_mesh(b)
	add_child(MarshKit.thatch(_rng, hx - 3.4, hx + 3.4, g + 3.3, -2.6, g + 5.2, -6.4))
	# The glow of the pot and the hearth.
	var glow := PaperMesh.new(3)
	glow.color = Color(1.0, 0.82, 0.5)
	glow.frustum(10, Vector2(0.4, 0.4), Vector2(0.4, 0.4), 0.02, Vector3(hx - 1.5, g + 1.22, -4.8))
	glow.color = Color(1.0, 0.5, 0.25)
	glow.rect(Vector2(hx - 1.5, g + 0.35), Vector2(0.5, 0.3), -4.28)
	add_child(glow.build(Color.WHITE, 2.2, true))
	_light(Vector3(hx - 1.4, g + 1.6, -3.8), 2.6, 9.0)
	_shine(hx - 1.4, 1.2, Color(1.0, 0.66, 0.36, 0.25))
	# Racks of drying wax cakes, and candles hung in strings.
	var r := PaperMesh.new(_rng.randi())
	r.shade_jitter = 0.1
	for rx: float in [WAX_X - 6.5, WAX_X + 8.0]:
		r.color = MarshKit.WOOD_WET.lightened(0.08)
		for sx: float in [-1.0, 1.0]:
			r.frustum(5, Vector2(0.05, 0.05), Vector2(0.05, 0.05), 1.6, Vector3(rx + sx, g, -2.8))
		for shelf in 3:
			var sy := g + 0.4 + shelf * 0.5
			r.color = MarshKit.WOOD_WET.lightened(0.04)
			r.box(Vector3(rx, sy, -2.8), Vector3(2.1, 0.04, 0.5))
			for c in 6:
				r.color = Color(0.84, 0.8, 0.68).darkened(_rng.randf_range(0.0, 0.15))
				r.box(Vector3(rx - 0.8 + c * 0.32, sy + 0.06, -2.8), Vector3(0.22, 0.08, 0.3))
	_mesh(r)
	var strings := PaperMesh.new(_rng.randi())
	for k in 3:
		var sx := WAX_X - 2.5 + k * 1.2
		strings.color = Color(0.2, 0.18, 0.15)
		strings.box(Vector3(sx, g + 2.6, -2.75), Vector3(0.01, 0.6, 0.01))
		for c in 4:
			strings.color = Color(0.86, 0.82, 0.7)
			strings.frustum(6, Vector2(0.025, 0.025), Vector2(0.02, 0.02), 0.3, Vector3(sx + (c - 1.5) * 0.06, g + 2.0, -2.75))
	_mesh(strings)
	# Haze trees, their leaves a faded rust: the only warm colour but candles.
	for tx: float in [WAX_X - 11.0, WAX_X + 13.0, WAX_X + 19.0]:
		var tree := _haze_tree(_rng.randf_range(4.5, 6.0))
		tree.position = Vector3(tx, g, _rng.randf_range(-4.8, -3.0))
		add_child(tree)
	wax_maker = WaxMaker.new()
	wax_maker.marsh = self
	wax_maker.position = Vector3(WAX_X, g, -1.1)
	add_child(wax_maker)


func _haze_tree(height: float) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.14
	b.color = Color(0.22, 0.18, 0.17)
	MarshKit.limb(b, Vector3(0.0, -0.3, 0.0), Vector3(0.3, height * 0.6, 0.0), 0.2, 0.12, 7)
	var tips: Array[Vector3] = []
	for k in 5:
		var from := Vector3(0.3, height * _rng.randf_range(0.45, 0.6), 0.0)
		var to := from + Vector3(_rng.randf_range(-1.8, 1.8), _rng.randf_range(0.8, 1.6), _rng.randf_range(-0.8, 0.8))
		MarshKit.limb(b, from, to, 0.08, 0.03, 5)
		tips.append(to)
	root.add_child(b.build())
	var leaves := Node3D.new()
	root.add_child(leaves)
	var l := PaperMesh.new(_rng.randi())
	l.texture_world = false
	l.shade_jitter = 0.2
	for tip: Vector3 in tips:
		for k in 14:
			var c := tip + Vector3(_rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.4, 0.5), _rng.randf_range(-0.6, 0.6))
			l.color = MarshKit.RUST.lerp(Color(0.42, 0.32, 0.2), _rng.randf()).darkened(_rng.randf_range(0.0, 0.3))
			var a := _rng.randf() * TAU
			l.tri(c, c + Vector3(cos(a), sin(a), 0.2) * 0.22, c + Vector3(cos(a + 0.5), sin(a + 0.5), -0.2) * 0.2)
	leaves.add_child(l.build())
	Scenery.windswept(leaves, -0.015, _rng)
	return root


# --- The Black Mere ---------------------------------------------------------------

## The broken aqueduct: piers out of the ink, its channel high up (a route
## glided between), ink pouring from its broken ends (InkCurtain); islands
## with dead trees; the reed hut of shrine 12.
func _build_mere() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.13
	for p: Array in PIERS:
		var px: float = p[0]
		var top: float = p[1]
		_solid(Vector3(px, (top + DEEP_BED) * 0.5, 0.0), Vector3(1.3, top - DEEP_BED, 2.0))
		MarshKit.masonry(b, Vector3(px, (top - 2.0) * 0.5, -0.3), Vector3(1.3, top + 2.0, 2.6), _rng)
	for c: Array in CHANNELS:
		var left: float = c[0]
		var right: float = c[1]
		var top: float = c[2]
		_solid(Vector3((left + right) * 0.5, top - 0.4, 0.0), Vector3(right - left, 0.8, 2.6))
		# Its trough walls, the ink in it, its arches down to piers in the Mere.
		MarshKit.masonry(b, Vector3((left + right) * 0.5, top - 0.6, -0.4), Vector3(right - left, 1.2, 2.8), _rng)
		b.color = MarshKit.STONE.darkened(0.3)
		b.box(Vector3((left + right) * 0.5, top + 0.35, -1.55), Vector3(right - left, 0.7, 0.3))
		b.color = MarshKit.INK
		b.box(Vector3((left + right) * 0.5, top + 0.12, -1.0), Vector3(right - left, 0.02, 0.8))
		var ax := left + 1.0
		while ax < right:
			MarshKit.masonry(b, Vector3(ax, (top - 1.2 + DEEP_BED) * 0.5, -0.9), Vector3(0.9, top - 1.2 - DEEP_BED, 1.4), _rng)
			# The arch's spandrels.
			b.extrude(PackedVector2Array([Vector2(ax + 0.45, top - 1.2), Vector2(ax + 1.2, top - 1.2), Vector2(ax + 0.45, top - 2.4)]), -1.5, -0.3)
			b.extrude(PackedVector2Array([Vector2(ax + 4.0, top - 1.2), Vector2(ax + 4.75, top - 1.2), Vector2(ax + 4.75, top - 2.4)]), -1.5, -0.3)
			ax += 5.2
		# Broken ends: jagged stone.
		for e: float in [left, right]:
			if (e == right and right < 247.0) or (e == left and left > 250.0):
				b.color = MarshKit.STONE.darkened(0.25)
				for k in 4:
					b.box(Vector3(e + (-0.2 if e == right else 0.2), top - 0.4 - k * 0.3, -0.5 + _rng.randf_range(-0.5, 0.5)), Vector3(0.4, 0.3, 0.6))
	_mesh(b)
	var bundle := CraneBundle.new()
	bundle.id = "mere_aqueduct"
	bundle.count = 8
	bundle.position = Vector3(267.0, 6.5, 0.0)
	add_child(bundle)
	# Island trees.
	for t: Array in [[239.0, 0.5], [281.5, 0.5]]:
		var tree := MarshKit.dead_tree(_rng, 7.0, 0.1, 0.34, 3)
		tree.position = Vector3(t[0], t[1], -1.8)
		add_child(tree)
	# The reed hut on the middle island (shrine 12 at its door).
	var hut := PaperMesh.new(_rng.randi())
	hut.shade_jitter = 0.16
	var hx := 257.0
	hut.color = MarshKit.REED_DRY.darkened(0.3)
	for k in 40:
		var x := hx - 2.6 + k * 0.13
		hut.box(Vector3(x, 0.6 + 1.2, -3.4 + _rng.randf_range(-0.04, 0.04)), Vector3(0.11, 2.4 + _rng.randf_range(-0.1, 0.1), 0.06))
	_mesh(hut)
	add_child(MarshKit.thatch(_rng, hx - 2.8, hx + 2.8, 0.6 + 2.5, -1.8, 0.6 + 4.0, -4.2))
	_light(Vector3(hx + 0.6, 1.6, -1.6), 1.2, 5.0)
	_shine(hx + 0.6, 0.8, Color(1.0, 0.7, 0.4, 0.2))
	# Lotus leaves (scenery) on the open ink.
	var leaves := PaperMesh.new(_rng.randi())
	leaves.texture_world = false
	for k in 30:
		var lx := _rng.randf_range(212.0, 300.0)
		var lz := _rng.randf_range(-7.0, 4.0)
		if absf(lz) < 1.8:
			continue
		var leaf := PaperMesh.new(_rng.randi())
		leaf.texture_world = false
		MarshKit.lotus_leaf(leaf, _rng.randf_range(0.3, 0.7), _rng)
		var m := leaf.build()
		m.position = Vector3(lx, INK_Y, lz)
		add_child(m)


# --- The Causeway of Lost Names ---------------------------------------------------

## Rows of grave posts and drowned stone lanterns, the limp banners of his
## army on their poles, the aqueduct crossing over (ink pouring through a
## broken arch onto the stones).
func _build_causeway() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	# Its kerb of dressed stone along the front, down into the ink.
	var x := 300.0
	while x < 352.0:
		var x1 := minf(x + _rng.randf_range(0.8, 1.3), 352.0)
		b.color = MarshKit.STONE.darkened(_rng.randf_range(0.15, 0.35))
		b.box(Vector3((x + x1) * 0.5, 0.45, 3.0), Vector3(x1 - x - 0.04, 0.9, 0.5))
		b.color = MarshKit.STONE.darkened(_rng.randf_range(0.0, 0.2))
		b.box(Vector3((x + x1) * 0.5, 0.905, 0.6), Vector3(x1 - x - 0.03, 0.02, 4.4))
		x = x1
	_mesh(b)
	x = 302.0
	while x < 350.0:
		for z: float in [-2.6, -3.6]:
			if _rng.randf() < 0.75:
				var post_ := MarshKit.grave_post(_rng, _rng.randf_range(1.6, 2.6))
				post_.position = Vector3(x + _rng.randf_range(-0.3, 0.3), 0.9, z)
				add_child(post_)
		x += _rng.randf_range(1.0, 1.8)
	for lx: float in [306.0, 316.0, 328.0, 338.0, 348.0]:
		var lantern := MarshKit.stone_lantern(_rng, lx == 348.0)
		lantern.position = Vector3(lx, 1.2, -1.8)
		add_child(lantern)
	_light(Vector3(348.0, 2.4, -1.4), 1.0, 5.0)
	# Banners on poles, soaked limp (Scenery.banner, hung slack).
	for bx: float in [311.0, 322.0, 333.0, 342.0]:
		var pole := PaperMesh.new(_rng.randi())
		pole.color = Color(0.14, 0.12, 0.12)
		pole.frustum(6, Vector2(0.06, 0.06), Vector2(0.05, 0.05), 5.0, Vector3(bx, 0.9, -4.4))
		pole.box(Vector3(bx + 0.35, 5.8, -4.4), Vector3(0.75, 0.05, 0.05))
		_mesh(pole)
		var banner := _limp_banner()
		banner.position = Vector3(bx + 0.35, 5.78, -4.4)
		add_child(banner)
		Scenery.windswept(banner, 0.03, _rng)
	# The aqueduct crossing above (the pour at 323 comes from its break).
	var a := PaperMesh.new(_rng.randi())
	a.shade_jitter = 0.12
	for px: float in [316.0, 330.0]:
		MarshKit.masonry(a, Vector3(px, 4.2, -6.0), Vector3(1.4, 9.0, 1.6), _rng)
	# Its span, broken in the middle (the pour comes through the break).
	MarshKit.masonry(a, Vector3(318.8, 8.4, -2.5), Vector3(5.6, 1.4, 8.0), _rng)
	MarshKit.masonry(a, Vector3(327.6, 8.4, -2.5), Vector3(5.6, 1.4, 8.0), _rng)
	a.color = MarshKit.STONE.darkened(0.3)
	for e: float in [321.6, 324.8]:
		for k in 4:
			a.box(Vector3(e + (-0.15 if e < 323.0 else 0.15), 8.0 - k * 0.25, -0.5 + _rng.randf_range(-1.5, 1.5)), Vector3(0.35, 0.3, 0.7))
	_mesh(a)


## A soldier's banner, soaked and hanging straight down, its painted crest
## run into a stain, the hem in rags dripping.
func _limp_banner() -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.06
	b.color = Color(0.46, 0.45, 0.43)
	var outline := PackedVector2Array([Vector2(-0.35, 0.0), Vector2(0.35, 0.0), Vector2(0.33, -2.6)])
	var hx := 0.33
	while hx > -0.33:
		outline.append(Vector2(hx, -2.6 - _rng.randf_range(0.0, 0.3)))
		hx -= 0.08
	outline.append(Vector2(-0.33, -2.5))
	b.polygon(outline, 0.0)
	b.color = Color(0.13, 0.13, 0.17)
	b.ellipse(Vector2(0.0, -0.8), Vector2(0.22, 0.22), 10, 0.01)
	b.polygon(PackedVector2Array([Vector2(-0.12, -0.9), Vector2(0.12, -0.9), Vector2(0.06, -2.0), Vector2(0.0, -2.4), Vector2(-0.05, -1.8)]), 0.01)
	root.add_child(b.build())
	return root


# --- Creatures ---------------------------------------------------------------------

func _build_creatures() -> void:
	for f: Array in FROGS:
		var frog := InkFrog.new()
		frog.position = Vector3(f[0], f[1] + 0.05, 0.0)
		add_child(frog)
	for e: Array in EELS:
		var eel := InkEel.new()
		eel.pool = Vector2(e[0], e[1])
		eel.position = Vector3((e[0] + e[1]) * 0.5, INK_Y, 0.0)
		add_child(eel)
	for r: Array in RISERS:
		var rise := InkRiser.new()
		rise.position = Vector3(r[0], r[1], 0.0)
		add_child(rise)
	for g: Array in GUARDS:
		var husk: Node3D = Village.HUSK_SCENE.instantiate()
		husk.position = Vector3(g[0], g[1] + 0.1, 0.0)
		husk.set(&"soak_tint", InkRiser.SOAKED)
		add_child(husk)


# --- Life ---------------------------------------------------------------------------

## Small paper birds perched on the boardwalks' edges, a sunken roof's ridge,
## the torii's beam and a stone lantern, bursting up as he comes near; and
## bubbles rising out of the deep ink, breaking on its skin.
func _build_life() -> void:
	for perch: Array in [[36.0, 1.1, -1.25, 4], [63.5, 1.0, -1.25, 3], [143.3, 0.36, 0.0, 3], [17.0, 2.72, -2.6, 4],
			[316.0, 0.9, 3.0, 3], [239.5, 0.55, -1.0, 4]]:
		var flock := PerchedBirds.new()
		flock.count = perch[3]
		flock.spread = 0.9
		flock.position = Vector3(perch[0], perch[1], perch[2])
		add_child(flock)
	for g: Array in GROUND:
		if g[2] != "deep":
			continue
		var bubbles := CPUParticles3D.new()
		bubbles.amount = int((g[1] - g[0]) * 0.6) + 2
		bubbles.lifetime = 1.6
		bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		bubbles.emission_box_extents = Vector3((g[1] - g[0]) * 0.5 - 0.5, 0.0, 3.0)
		bubbles.position = Vector3((g[0] + g[1]) * 0.5, INK_Y + 0.02, 0.5)
		bubbles.direction = Vector3.UP
		bubbles.spread = 0.0
		bubbles.gravity = Vector3.ZERO
		bubbles.initial_velocity_min = 0.0
		bubbles.initial_velocity_max = 0.02
		bubbles.scale_amount_min = 0.4
		bubbles.scale_amount_max = 1.2
		var grow := Curve.new()
		grow.add_point(Vector2(0.0, 0.0))
		grow.add_point(Vector2(0.8, 1.0))
		grow.add_point(Vector2(1.0, 0.0))
		bubbles.scale_amount_curve = grow
		var bead := QuadMesh.new()
		bead.size = Vector2(0.09, 0.06)
		bead.material = WaterFx.bead_material(Color(0.5, 0.55, 0.56, 0.5))
		bubbles.mesh = bead
		bubbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bubbles)


# --- The foreground and the air ------------------------------------------------------

## Dark reeds rising out of the ink in front, dead branches.
func _build_foreground() -> void:
	var x := -10.0
	while x < END + 10.0:
		if x > ShimeriPost.ARENA.x and x < ShimeriPost.ARENA.y:
			x += 6.0
			continue   # (his court: nothing between the camera and the fight)
		var clump := MarshKit.reeds(_rng, _rng.randf_range(1.0, 2.6), _rng.randf_range(1.0, 1.8), 0.3, Color(0.03, 0.035, 0.035), true)
		clump.position = Vector3(x, INK_Y, NEAR_Z - _rng.randf_range(1.2, 2.6))
		add_child(clump)
		Scenery.windswept(clump, -0.04, _rng)
		x += _rng.randf_range(4.0, 9.0)


## Will-o'-wisps (cold small lights drifting among the trees), slow paper
## motes falling like ash, mist on the ink.
func _build_air() -> void:
	for spot: Vector3 in [Vector3(26.0, 1.6, -5.0), Vector3(66.0, 2.0, -7.0), Vector3(144.0, 1.4, -6.0),
			Vector3(226.0, 1.2, -5.0), Vector3(272.0, 1.8, -6.5), Vector3(312.0, 1.6, -5.5), Vector3(366.0, 2.2, -7.0)]:
		var l := _light(spot, 0.6, 5.0, MarshKit.WISP)
		l.set_meta(&"home", spot)
		_wisps.append(l)
		var orb := PaperMesh.new(1)
		orb.color = MarshKit.WISP
		orb.ellipse(Vector2.ZERO, Vector2(0.08, 0.1), 10, 0.0)
		var m := orb.build(Color.WHITE, 2.5, true)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(m.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		l.add_child(m)
		var halo := Scenery.halo(0.7, Color(0.6, 0.8, 1.0, 0.3))
		l.add_child(halo)
	var motes := CPUParticles3D.new()
	motes.amount = 160
	motes.lifetime = 14.0
	motes.preprocess = 14.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(END * 0.5 + 12.0, 6.0, 5.0)
	motes.position = Vector3(END * 0.5, 5.0, -1.0)
	motes.direction = Vector3(-1.0, -0.3, 0.0)
	motes.spread = 40.0
	motes.gravity = Vector3(-0.1, -0.12, 0.0)
	motes.initial_velocity_min = 0.05
	motes.initial_velocity_max = 0.25
	motes.angle_max = 360.0
	motes.angular_velocity_min = -60.0
	motes.angular_velocity_max = 60.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.04)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.62, 0.66, 0.64, 0.7)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = look
	motes.mesh = quad
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)
	# Mist lying on the ink, and a thicker band at the back.
	_mist(-3.0, -1.0, 1.4, Color(FOG, 0.28))
	_mist(-9.0, -1.0, 3.5, Color(FOG, 0.45))
	_mist(-15.0, -1.0, 5.0, Color(FOG, 0.55))
