class_name BambooGrove
extends Node3D
## The start of the Bamboo of Folded Wind (chapter 2, docs/lore.md), past
## the shrine courtyard's far gate, which opens when the Hannya falls.
## Towering strips of green paper folded into bamboo, swaying slowly in a
## wind that never stops here; leaves blown along; cold moonlight in shafts
## between the stems; calm, airy, and dangerous: the path breaks off over
## ravines too wide to jump. On an old altar in the grove a great paper crane
## waits: walk up to it and it rises, circles, and folds itself into his
## cloak: the Crane Glide (hold jump in the air). Then the ravines can be
## crossed.
##
## Grown to the town's size (Julian: "lots of opportunities to use the
## glide"; docs/bamboo_map.png): past the two ravines, the Windfall Gorge
## (rising gusts out of a deep gorge, WindfallGorge), the Canopy Road (decks
## lashed high in the stems, CanopyRoad), the paper mill (shrine 5,
## PaperMill), the Falls (a climb, then one long glide down, BambooFalls),
## and Akane's clearing at the end.
##
## It is its own place, not a continuation of the town's street (Julian:
## "once you walk out of the town the screen should fade out and then you
## should spawn into the bamboo area"). The grove is built far off along x
## (SHIFT), with its own sky and far bamboo, and its numbers below are as if
## it began at the courtyard's gate. Walking out through the open gate
## fades to black and puts him at the grove's west end (Main._travel); the
## open gate stands there too, and walking back through it returns him.

## How far along x the grove really is (it is drawn there, out of sight of
## the town). Its own numbers (GROUND, ALTAR_X...) are before this shift.
const SHIFT := 1000.0
## The grove runs from the courtyard's far gate to here.
const EAST_END := 414.0
## Where he arrives in the grove (local x), and where he arrives back in the
## courtyard (town x).
const ARRIVE_X := Village.ARENA.y + 1.6
const RETURN_X := Village.ARENA.y - 1.4
## The gate in the courtyard's far wall.
const GATE_X := Village.ARENA.y + 0.4
## [left x, right x, top, how deep its rock goes (optional)] of the ground.
## Between the first three: the two ravines (bridged). Then the Windfall
## Gorge's floor between its two lips; the long floor under the canopy and
## the mill; the cliff of the Falls; the pool (no ground); Akane's clearing.
const GROUND := [[Village.ARENA.y - 6.0, 213.0, 1.5], [221.5, 234.0, 1.5], [242.0, 249.0, 1.5, 24.0],
	[249.0, 287.0, -9.5, 14.0], [287.0, 378.0, 1.5, 24.0], [378.0, 384.0, 13.5, 18.0], [396.0, EAST_END, 2.1, 6.0]]
## The Windfall Gorge (between its lips), and the gorge's floor.
const GORGE := Vector2(249.0, 287.0)
## The pool under the Falls (between the cliff and the far bank).
const POOL := Vector2(384.0, 396.0)
## The second shrine in the grove: at the paper mill.
const MILL_SHRINE_X := 356.0
## The grove's creatures (Julian: red pandas instead of dogs, kite husks
## instead of birds): where each red panda prowls (x, ground) ...
const PANDAS := [Vector2(228.0, 1.5), Vector2(268.0, -9.5), Vector2(312.0, 1.5), Vector2(340.0, 1.5), Vector2(373.0, 1.5)]
## ... and where each kite husk rides the wind (its roost in the air): two
## over the gorge between the gusts, one in the canopy, one over the pool.
const KITES := [Vector2(262.5, 0.5), Vector2(272.5, -0.5), Vector2(327.0, 17.0), Vector2(390.0, 8.0)]
## The altar with the great crane.
const ALTAR_X := 206.0
## The fourth shrine, just inside the gate.
const SHRINE_X := 196.0
## The day's colours here (Julian's picture: fresh greens, red washi, warm
## light).
const STEM := Color(0.24, 0.44, 0.2)
const STEM_YELLOW := Color(0.52, 0.6, 0.24)
const LEAF := Color(0.4, 0.58, 0.2)
const MOSS := Color(0.22, 0.32, 0.12)
const MOSS_LIGHT := Color(0.36, 0.46, 0.17)
const ROCK := Color(0.22, 0.2, 0.19)
const ROCK_WARM := Color(0.3, 0.23, 0.18)
const WASHI_RED := Color(0.54, 0.15, 0.13)
const SAKURA_PRINT := Color(0.93, 0.78, 0.74)
const PETAL := Color(0.96, 0.78, 0.8)
const TIMBER_WARM := Color(0.46, 0.33, 0.22)
const ROPE := Color(0.66, 0.56, 0.4)
## How far back the forest floor reaches (the stems behind stand on it).
const FLOOR_BACK := -8.0
## The red sun in the sky (grove x, height).
const SUN_AT := Vector2(236.0, 15.0)
## How far the gate's leaves swing open (degrees).
const OPEN_ANGLE := 90.0

var village: Village
var gate_open := false
var shrine: RestShrine
var _rng := RandomNumberGenerator.new()
var _gate_solid: StaticBody3D
var _gate_leaves: Array[Node3D] = []   # the courtyard gate's two leaves (front, back)
var _beyond_light: OmniLight3D
var _crane: Node3D
var _crane_taken := false
var _ronin: Ronin
var _leaves: CPUParticles3D
var _petals: CPUParticles3D
var duel: AkaneDuel
## Where each stem stands (local x, foot height), for the automated check.
var stem_feet: Array[Vector2] = []
## The grown grove's areas and creatures: they rest (no processing) while he
## is in the town, where none of it can be seen or heard (set_awake).
var _far: Array[Node] = []
var _awake := true
var _town_gate: Node3D   # the gate in the courtyard (in the town's place)


## True when this x (a real, world x) is in the grove rather than the town.
static func in_grove(x: float) -> bool:
	return x > SHIFT * 0.5


func _ready() -> void:
	_rng.seed = 2601
	position.x = SHIFT
	_town_gate = Node3D.new()
	_town_gate.position.x = -SHIFT
	add_child(_town_gate)
	_build_gate()
	_build_beyond_gate()
	_build_mist_way()
	_build_sky()
	for g: Array in GROUND:
		_ground(g[0], g[1], g[2], g[3] if g.size() > 3 else 10.0)
	_ravines()
	_bamboo()
	_altar()
	_air()
	for x: float in [200.0, 218.0, 238.0, 252.0, 300.0, 325.0, 350.0, 404.0]:
		Sound.place_loop(self, "bamboo_wind.ogg", Vector3(x, _foot(x) + 2.5, -1.0), -6.0, 9.0)
	# The new stretch, area by area.
	for area: Node3D in [WindfallGorge.new(), CanopyRoad.new(), PaperMill.new(), BambooFalls.new()]:
		area.set(&"grove", self)
		add_child(area)
		_far.append(area)
	for spot: Vector2 in PANDAS:
		var panda := RedPanda.new()
		panda.position = Vector3(spot.x, spot.y, 0.0)
		add_child(panda)
		_far.append(panda)
	for spot: Vector2 in KITES:
		var kite := KiteHusk.new()
		kite.position = Vector3(spot.x, spot.y, 0.0)
		add_child(kite)
		_far.append(kite)
	# Akane's clearing, at the end (akane_duel.gd).
	duel = AkaneDuel.new()
	duel.grove = self
	add_child(duel)
	shrine = RestShrine.new()
	shrine.shrine_id = "bamboo"
	shrine.position = Vector3(SHRINE_X, 1.5, -0.9)
	shrine.scale = Vector3.ONE * 1.45
	add_child(shrine)
	# The end of what is built: a thicket too dense to pass.
	_solid(Vector3(EAST_END - 0.5, 10.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)
	# Behind the gate at the west end (he is taken back to the town as he
	# walks through it): nothing to walk into.
	_solid(Vector3(GATE_X - 2.6, 10.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)


## Wakes the grown grove's areas and creatures (he is in the grove) or lets
## them rest (he is in the town).
func set_awake(on: bool) -> void:
	if on == _awake:
		return
	_awake = on
	for n: Node in _far:
		if is_instance_valid(n):
			n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## A solid in the grove (its x shifted to where the grove really is).
func _solid(center: Vector3, size: Vector3) -> StaticBody3D:
	return village._add_solid(center + Vector3(SHIFT, 0.0, 0.0), size)


# --- The courtyard's far gate ---------------------------------------------------------

## The gate's wall, posts, lintel and little roof, into a parent.
func _gate_frame(parent: Node3D, g: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	# The wall: plaster over a stone base, behind and in front of the path.
	# (It runs far back, so it reads as the courtyard's boundary wall going
	# off into the dark, not a lone block.) A timber coping along its top.
	for span: Vector2 in [Vector2(-12.0, -1.25), Vector2(1.25, 1.42)]:
		b.color = Color(0.5, 0.49, 0.5)
		b.box(Vector3(GATE_X, g + 1.4, (span.x + span.y) * 0.5), Vector3(0.5, 2.8, span.y - span.x))
		b.color = Canals.STONE.lightened(0.1)
		b.box(Vector3(GATE_X, g + 0.304, (span.x + span.y) * 0.5), Vector3(0.56, 0.6, span.y - span.x - 0.02))
		b.color = PaperMesh.TIMBER
		b.box(Vector3(GATE_X, g + 2.86, (span.x + span.y) * 0.5), Vector3(0.7, 0.13, span.y - span.x + 0.1))
		b.color = Scenery.ROOF.darkened(0.15)
		b.box(Vector3(GATE_X, g + 2.98, (span.x + span.y) * 0.5), Vector3(0.82, 0.1, span.y - span.x + 0.2))
	# Posts and a lintel, the little roof over the gateway.
	b.color = PaperMesh.TIMBER
	for pz: float in [1.18, -1.18]:
		b.box(Vector3(GATE_X, g + 1.6, pz), Vector3(0.22, 3.2, 0.22))
	b.box(Vector3(GATE_X, g + 3.05, 0.0), Vector3(0.3, 0.22, 2.8))
	parent.add_child(b.build())
	parent.add_child(Scenery.tiled_roof(_rng, GATE_X - 0.7, GATE_X + 0.7, Vector2(g + 3.25, 1.7), Vector2(g + 3.9, 0.0), 3))
	parent.add_child(Scenery.tiled_roof(_rng, GATE_X - 0.7, GATE_X + 0.7, Vector2(g + 3.25, -1.7), Vector2(g + 3.9, 0.0), 3, false))


## A roofed gate (a small mon) in the courtyard's far wall of plaster and
## tiles. Its door faces us in the cut-away; it swings open toward us.
func _build_gate() -> void:
	var g := 1.5
	_gate_frame(_town_gate, g)
	# Two leaves across the passage, in line with the wall, hung on the posts
	# at the front and back of the path; they meet in the middle and swing
	# open away from the courtyard, into the bamboo side. (A single door
	# drawn facing us looked wrong whichever way it swung: Julian.)
	for side: float in [1.0, -1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(GATE_X, g, side * 1.16)
		_town_gate.add_child(leaf)
		var d := PaperMesh.new(_rng.randi())
		d.shade_jitter = 0.16
		var z := 0.0
		while z < 1.14:
			var z1 := minf(z + 0.28, 1.14)
			d.color = Scenery.WOOD.darkened(_rng.randf_range(0.05, 0.25))
			d.box(Vector3(0.0, 1.3, -side * (z + z1) * 0.5), Vector3(0.08, 2.6, z1 - z - 0.02))
			z = z1
		d.color = Color(0.12, 0.12, 0.15)
		for band: float in [0.4, 2.2]:
			d.box(Vector3(0.0, band, -side * 0.57), Vector3(0.1, 0.07, 1.14))
			for k in 4:
				d.box(Vector3(0.0, band, -side * (0.12 + k * 0.3)), Vector3(0.12, 0.035, 0.035))
		leaf.add_child(d.build())
		_gate_leaves.append(leaf)
	_gate_solid = village._add_solid(Vector3(GATE_X, g + 1.5, 0.0), Vector3(0.5, 3.0, 2.2))
	# Light beyond it, unseen until it opens: the grove's warm daylight.
	_beyond_light = OmniLight3D.new()
	_beyond_light.light_color = Color(1.0, 0.86, 0.62)
	_beyond_light.light_energy = 0.0
	_beyond_light.omni_range = 6.0
	_beyond_light.position = Vector3(GATE_X + 1.5, g + 2.0, 0.5)
	_town_gate.add_child(_beyond_light)


## Beyond the courtyard's far gate, in the town: the street goes on a few
## metres and runs off into fog (lit warm from deep inside, where the grove
## is), so the open gate does not give onto nothing (Julian). Built with
## the village's own street (its random draws put back afterwards, so
## nothing else in the town changes).
func _build_beyond_gate() -> void:
	var left := Village.ARENA.y + 0.5
	var right := left + 9.0
	var saved: int = village._rng.state
	village._build_ground_block(left, right, Village.STEPS_TOP, 8.0, false, false)
	village._rng.state = saved
	var mist := PaperMesh.new(1)
	var fog := Color(0.42, 0.46, 0.64)
	var warm := Color(0.95, 0.82, 0.6)
	for k in 6:
		var z := 3.0 - k * 2.4
		var from := GATE_X + 0.8 + k * 0.3
		var full := from + 3.2
		mist.fade_quad(Vector3(from, -8.0, z), Vector3(from, 26.0, z), Vector3(full, 26.0, z), Vector3(full, -8.0, z),
				Color(fog, 0.0), Color(fog, 0.38))
		mist.fade_quad(Vector3(full, -8.0, z), Vector3(full, 26.0, z), Vector3(full + 30.0, 26.0, z), Vector3(full + 30.0, -8.0, z),
				Color(fog, 0.38), Color(fog, 0.38))
	# A warm glow deep in the fog, low down: the grove's daylight.
	mist.fade_quad(Vector3(GATE_X + 4.0, 0.5, -2.0), Vector3(GATE_X + 4.0, 6.0, -2.0), Vector3(GATE_X + 14.0, 6.0, -2.0), Vector3(GATE_X + 14.0, 0.5, -2.0),
			Color(warm, 0.0), Color(warm, 0.18))
	_town_gate.add_child(mist.build_veil())


## The grove's west end: the path runs off into deep bright mist (the way
## back to the courtyard), the bamboo fading into it, a mossy stone lantern
## at the path's edge marking the way. Walking into the mist takes him home
## (Main._travel). (A copy of the courtyard's gate stood here at first, a
## lone chunk of wall in the forest: Julian, "a weird scene arrangement".)
func _build_mist_way() -> void:
	var edge := GATE_X + 1.0   # where the mist is thickest from, westward
	var mist := PaperMesh.new(1)
	for k in 7:
		var z := 3.0 - k * 2.6
		var clear := edge + 2.6 + k * 0.6   # how far east it reaches at this depth
		# Fading in from the east...
		mist.fade_quad(Vector3(clear, -12.0, z), Vector3(clear, 32.0, z), Vector3(edge, 32.0, z), Vector3(edge, -12.0, z),
				Color(0.95, 0.92, 0.84, 0.0), Color(0.95, 0.92, 0.84, 0.42))
		# ...and solid to the west of it.
		mist.fade_quad(Vector3(edge, -12.0, z), Vector3(edge, 32.0, z), Vector3(edge - 30.0, 32.0, z), Vector3(edge - 30.0, -12.0, z),
				Color(0.95, 0.92, 0.84, 0.42), Color(0.95, 0.92, 0.84, 0.42))
	add_child(mist.build_veil())
	# A mossy stone lantern at the back edge of the path, half in the mist.
	var x := GATE_X + 2.6
	var g := _foot(x)
	var z := -1.7
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	var stone := Color(0.5, 0.5, 0.46)
	b.color = stone
	b.box(Vector3(x, g + 0.1, z), Vector3(0.62, 0.2, 0.62))
	b.frustum(6, Vector2(0.14, 0.14), Vector2(0.12, 0.12), 0.8, Vector3(x, g + 0.2, z))
	b.box(Vector3(x, g + 1.04, z), Vector3(0.56, 0.08, 0.56))
	b.color = stone.darkened(0.1)
	b.box(Vector3(x, g + 1.25, z), Vector3(0.4, 0.34, 0.4))
	b.color = Color(1.0, 0.86, 0.6)
	b.box(Vector3(x, g + 1.25, z + 0.205), Vector3(0.18, 0.16, 0.01))
	b.color = stone.darkened(0.05)
	b.frustum(6, Vector2(0.44, 0.44), Vector2(0.05, 0.05), 0.3, Vector3(x, g + 1.42, z))
	b.color = MOSS.lerp(MOSS_LIGHT, 0.4)
	b.box(Vector3(x - 0.08, g + 0.21, z + 0.05), Vector3(0.4, 0.03, 0.4))
	b.box(Vector3(x + 0.1, g + 1.47, z - 0.05), Vector3(0.24, 0.03, 0.2))
	add_child(b.build())


## The door swings open toward us; the grove's light spills through.
func open_gate(at_once: bool = false) -> void:
	if gate_open:
		return
	gate_open = true
	if _gate_solid:
		_gate_solid.queue_free()
		_gate_solid = null
	if village.east_wall:
		village.east_wall.queue_free()
		village.east_wall = null
		# Just past the gateway (he is taken to the grove as he walks through).
		village._add_solid(Vector3(GATE_X + 2.6, 10.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)
	# Each leaf swings a quarter turn on its post, away from the courtyard.
	if at_once:
		_gate_leaves[0].rotation.y = -deg_to_rad(OPEN_ANGLE)
		_gate_leaves[1].rotation.y = deg_to_rad(OPEN_ANGLE)
		_beyond_light.light_energy = 1.4
		return
	Sound.play(self, &"plank_creak", -1.0)
	for k in 2:
		var turn := -1.0 if k == 0 else 1.0
		var t := create_tween()
		t.tween_interval(0.12 * k)
		t.tween_property(_gate_leaves[k], "rotation:y", turn * deg_to_rad(OPEN_ANGLE + 6.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(_gate_leaves[k], "rotation:y", turn * deg_to_rad(OPEN_ANGLE), 0.6).set_trans(Tween.TRANS_SINE)
	var glow := create_tween()
	glow.tween_property(_beyond_light, "light_energy", 1.4, 1.4)


# --- The ground ------------------------------------------------------------------

func _ground(left: float, right: float, top: float, deep: float = 10.0) -> void:
	_solid(Vector3((left + right) * 0.5, top - maxf(deep, 8.0) * 0.5, -1.5), Vector3(right - left, maxf(deep, 8.0), 6.0))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	# The rock under the path (its sides show at the ravines), and the mossy
	# forest floor on top, reaching far back so the stems behind stand on it.
	b.color = ROCK
	b.box(Vector3((left + right) * 0.5, top - deep * 0.5 - 0.02, (FLOOR_BACK + 1.34) * 0.5), Vector3(right - left, deep, 1.34 - FLOOR_BACK))
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 3.0, right)
		b.color = MOSS.lerp(MOSS_LIGHT, _rng.randf_range(0.0, 0.5))
		b.quad(Vector3(x, top, FLOOR_BACK), Vector3(x1, top, FLOOR_BACK), Vector3(x1, top, 1.5), Vector3(x, top, 1.5), Vector3.UP)
		x = x1
	# Fallen bamboo leaves and a few petals on the moss.
	for i in int((right - left) * 3.0):
		var at := Vector3(_rng.randf_range(left + 0.2, right - 0.2), top + 0.012, _rng.randf_range(-6.0, 1.3))
		var turn := _rng.randf() * TAU
		var along := Vector3(cos(turn), 0.0, sin(turn)) * 0.13
		var across := Vector3(-sin(turn), 0.0, cos(turn)) * 0.022
		b.color = Color(0.62, 0.56, 0.3).lerp(Color(0.5, 0.6, 0.28), _rng.randf())
		if _rng.randf() < 0.2:
			b.color = PETAL
			along *= 0.4
			across *= 2.2
		b.quad(at - along, at - across, at + along, at + across, Vector3.UP)
	add_child(b.build())
	_cliff_face(left, right, top, deep)


## The cut front of the path, as in Julian's picture: a shaggy lip of moss
## hanging over the edge; under it a band of red washi printed with sakura
## and seigaiha waves, torn and pasted over the rock; below, faceted rock
## going down into the mist.
func _cliff_face(left: float, right: float, top: float, deep: float = 10.0) -> void:
	var z := Village.STREET_FRONT
	var f := PaperMesh.new(_rng.randi())
	f.shade_jitter = 0.06
	# The rock: a jittered net of facets (triangles), each its own shade,
	# darkening downward, as if crumpled.
	var cols := int(ceil((right - left) / 0.8)) + 1
	var rows := maxi(12, int(ceil(deep / 0.75)))
	var grid: Array = []
	for r in rows + 1:
		var line: Array[Vector2] = []
		for c in cols + 1:
			var gx := left + c * (right - left) / cols
			var gy := top - 0.15 - r * 0.75
			if c > 0 and c < cols:
				gx += _rng.randf_range(-0.28, 0.28)
			if r > 0:
				gy += _rng.randf_range(-0.25, 0.25)
			line.append(Vector2(gx, gy))
		grid.append(line)
	for r in rows:
		var dark := float(r) / rows
		for c in cols:
			var a: Vector2 = grid[r][c]
			var b2: Vector2 = grid[r][c + 1]
			var c2: Vector2 = grid[r + 1][c + 1]
			var d: Vector2 = grid[r + 1][c]
			for tri: Array in [[a, b2, c2], [a, c2, d]]:
				f.color = ROCK.lerp(ROCK_WARM, _rng.randf()).lightened(_rng.randf_range(-0.05, 0.12) - dark * 0.1)
				f.polygon(PackedVector2Array(tri), z + 0.01)
	# Patches of red washi pasted over the rock, torn, of every size and at
	# every height (not a row of matching banners), each with its print:
	# sakura scattered, and on some a band of seigaiha waves.
	var px := left + _rng.randf_range(-0.4, 0.8)
	var patch := 0
	while px < right - 0.6:
		var w := _rng.randf_range(1.0, 3.6)
		var tall := _rng.randf_range(0.9, 2.6)
		var high := top - _rng.randf_range(0.1, 1.6)
		var low := high - tall
		var outline := PackedVector2Array()
		for k in 7:
			var t := TAU * k / 7.0 + _rng.randf_range(-0.25, 0.25)
			outline.append(Vector2(px + w * 0.5 + cos(t) * w * 0.5 * _rng.randf_range(0.75, 1.0),
					(high + low) * 0.5 + sin(t) * tall * 0.5 * _rng.randf_range(0.75, 1.0)))
		var torn := PaperMesh.tear(outline, 0.22, 0.07, _rng)
		var pz := z + 0.04 + patch * 0.003
		f.color = WASHI_RED.darkened(_rng.randf_range(-0.05, 0.15))
		f.torn_sheet(torn, pz, WASHI_RED.lightened(0.35), 0.025)
		var mid := Vector2(px + w * 0.5, (high + low) * 0.5)
		var inside := func(at: Vector2, r: float) -> bool:
			var e := Vector2((at.x - mid.x) / (w * 0.5 * 0.7 - r), (at.y - mid.y) / (tall * 0.5 * 0.7 - r))
			return w * 0.35 > r and tall * 0.35 > r and e.length() < 1.0
		if _rng.randf() < 0.6 and tall > 1.2:
			var row_y := low + tall * 0.3
			for ry in 2:
				var wx := px + 0.2 + (0.21 if ry % 2 == 1 else 0.0)
				while wx < px + w - 0.2:
					var at := Vector2(wx, row_y + ry * 0.16)
					if inside.call(at + Vector2(0.0, 0.1), 0.2):
						_seigaiha(f, at, 0.2, pz + 0.004 + ry * 0.003)
					wx += 0.42
		for k in int(w * tall * 1.6):
			var c := mid + Vector2(_rng.randf_range(-w, w), _rng.randf_range(-tall * 0.1, tall)) * 0.5
			var r := _rng.randf_range(0.1, 0.22)
			if inside.call(c, r):
				_sakura(f, c, r, pz + 0.012 + k * 0.0004)
		px += w * _rng.randf_range(0.7, 1.3) + _rng.randf_range(0.2, 1.4)
		patch += 1
	var cliff := f.build()
	cliff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cliff)
	# The moss lip: shaggy tufts hanging over the edge, in two greens.
	var m := PaperMesh.new(_rng.randi())
	m.texture_world = false
	m.shade_jitter = 0.12
	var mx := left
	while mx < right:
		var wide := _rng.randf_range(0.12, 0.26)
		var hang := _rng.randf_range(0.12, 0.42)
		m.color = MOSS.lerp(MOSS_LIGHT, _rng.randf())
		m.polygon(PackedVector2Array([Vector2(mx - wide * 0.6, top + 0.06), Vector2(mx + wide * 0.6, top + 0.06),
				Vector2(mx + wide * 0.3, top - hang * 0.5), Vector2(mx + _rng.randf_range(-0.04, 0.04), top - hang),
				Vector2(mx - wide * 0.35, top - hang * 0.45)]), z + 0.07 + _rng.randf_range(0.0, 0.02))
		# Blades of grass standing up along the lip.
		if _rng.randf() < 0.6:
			m.color = MOSS_LIGHT.lightened(0.1)
			var gx := mx + _rng.randf_range(-0.1, 0.1)
			m.polygon(PackedVector2Array([Vector2(gx - 0.02, top), Vector2(gx + 0.02, top), Vector2(gx + _rng.randf_range(-0.06, 0.06), top + _rng.randf_range(0.12, 0.26))]), z + 0.1)
		mx += wide * 0.8
	var lip := m.build()
	lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lip)


## A sakura flower printed on the washi: five round petals and a dark eye.
func _sakura(b: PaperMesh, c: Vector2, r: float, z: float) -> void:
	b.color = SAKURA_PRINT.lerp(Color(0.95, 0.88, 0.8), _rng.randf_range(0.0, 0.5))
	var turn := _rng.randf() * TAU
	for k in 5:
		var a := turn + TAU * k / 5.0
		var petal := PackedVector2Array()
		for s in 7:
			var t := float(s) / 6.0
			var side := (t - 0.5) * 0.9
			var reach := r * (0.25 + 0.75 * sin(t * PI))
			# (a small notch at the petal's tip)
			if s == 3:
				reach *= 0.86
			petal.append(c + Vector2(cos(a + side), sin(a + side)) * reach)
		petal.append(c)
		b.polygon(petal, z)
	b.color = WASHI_RED.darkened(0.3)
	b.ellipse(c, Vector2(r * 0.18, r * 0.18), 8, z + 0.0005)


## One seigaiha wave: three half-rings, cream and red, one inside the other.
func _seigaiha(b: PaperMesh, c: Vector2, r: float, z: float) -> void:
	for ring in 4:
		b.color = SAKURA_PRINT.lerp(Color(0.95, 0.88, 0.8), 0.5) if ring % 2 == 0 else WASHI_RED.lightened(0.05)
		var rr := r * (1.0 - ring * 0.24)
		var half := PackedVector2Array()
		for s in 13:
			var a := PI * float(s) / 12.0
			half.append(c + Vector2(cos(a), sin(a)) * rr)
		b.polygon(half, z + ring * 0.0006)


## The ravines between: the first spanned once by a rope bridge, long since
## snapped (its ends hang down the cliffs: he must glide it); the second by
## a rope bridge still standing, that sags and sways as he crosses. Mist
## wells up from far below.
func _ravines() -> void:
	for i in 2:
		var left: float = GROUND[i][1]
		var right: float = GROUND[i + 1][0]
		var veil := PaperMesh.new(1)
		for k in 3:
			var z := -4.0 + k * 2.2
			veil.fade_quad(Vector3(left - 0.5, -6.0, z), Vector3(right + 0.5, -6.0, z), Vector3(right + 0.5, -1.0 + k * 0.4, z),
					Vector3(left - 0.5, -1.0 + k * 0.4, z), Color(0.92, 0.88, 0.76, 0.55), Color(0.92, 0.88, 0.76, 0.0))
			# (On down out of sight, so the mist has no lower edge.)
			veil.fade_quad(Vector3(left - 0.5, -20.0, z), Vector3(right + 0.5, -20.0, z), Vector3(right + 0.5, -6.0, z),
					Vector3(left - 0.5, -6.0, z), Color(0.92, 0.88, 0.76, 0.55), Color(0.92, 0.88, 0.76, 0.55))
		add_child(veil.build_veil())
		if i == 0:
			_snapped_bridge(left, right, GROUND[i][2], GROUND[i + 1][2])
		else:
			_rope_bridge(left, right, GROUND[i][2], GROUND[i + 1][2])


## Posts at a bridge's end: two weathered logs with rope wound round them.
func _bridge_posts(b: PaperMesh, x: float, top: float) -> void:
	for pz: float in [0.75, -0.75]:
		b.color = TIMBER_WARM.darkened(_rng.randf_range(0.0, 0.15))
		b.box(Vector3(x, top + 0.45, pz), Vector3(0.16, 1.2, 0.16))
		b.color = ROPE
		for k in 3:
			b.box(Vector3(x, top + 0.62 + k * 0.05, pz), Vector3(0.18, 0.025, 0.18))


## The rope bridge over the second ravine: planks on two ropes, a hand rope
## each side, sagging; posts at both ends. It is walked on (a chain of solid
## pieces along the sag).
func _rope_bridge(left: float, right: float, top_l: float, top_r: float) -> void:
	var sag := 0.45
	var deck := func(x: float) -> float:
		var t := (x - left) / (right - left)
		return lerpf(top_l, top_r, t) - sag * sin(t * PI)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	_bridge_posts(b, left + 0.08, top_l)
	_bridge_posts(b, right - 0.08, top_r)
	var x := left + 0.1
	while x < right - 0.1:
		var x1 := minf(x + 0.24, right - 0.1)
		b.color = TIMBER_WARM.darkened(_rng.randf_range(0.05, 0.3))
		var h0: float = deck.call(x)
		var h1: float = deck.call(x1)
		b.extrude(PackedVector2Array([Vector2(x, h0 - 0.06), Vector2(x1 - 0.03, h1 - 0.06), Vector2(x1 - 0.03, h1), Vector2(x, h0)]),
				-0.7 + _rng.randf_range(0.0, 0.05), 0.7 - _rng.randf_range(0.0, 0.05))
		x = x1 + 0.03
	# The ropes: under the planks, and the hand ropes from post top to post top.
	b.color = ROPE
	for pz: float in [0.72, -0.72]:
		_rope(b, Vector2(left + 0.08, top_l - 0.03), Vector2(right - 0.08, top_r - 0.03), sag, pz, 0.025)
		_rope(b, Vector2(left + 0.08, top_l + 0.95), Vector2(right - 0.08, top_r + 0.95), sag * 0.8, pz, 0.025)
		# Short ties from the hand rope down to the planks.
		var tx := left + 0.7
		while tx < right - 0.5:
			var t := (tx - left) / (right - left)
			var low: float = deck.call(tx)
			var high := lerpf(top_l, top_r, t) + 0.95 - sag * 0.8 * sin(t * PI)
			b.box(Vector3(tx, (low + high) * 0.5, pz), Vector3(0.02, high - low, 0.02))
			tx += 0.6
	var mesh := b.build()
	add_child(mesh)
	# What he walks on: convex pieces following the sag exactly.
	x = left - 0.2
	while x < right + 0.19:
		var x1 := minf(x + 0.5, right + 0.2)
		var h0: float = deck.call(clampf(x, left, right))
		var h1: float = deck.call(clampf(x1, left, right))
		var shape := ConvexPolygonShape3D.new()
		shape.points = PackedVector3Array([
			Vector3(x, h0, -0.9), Vector3(x1, h1, -0.9), Vector3(x1, h1 - 0.3, -0.9), Vector3(x, h0 - 0.3, -0.9),
			Vector3(x, h0, 0.9), Vector3(x1, h1, 0.9), Vector3(x1, h1 - 0.3, 0.9), Vector3(x, h0 - 0.3, 0.9)])
		var body := StaticBody3D.new()
		var holder := CollisionShape3D.new()
		holder.shape = shape
		body.add_child(holder)
		body.set_meta(&"no_climb", true)
		add_child(body)
		x = x1


## The snapped rope bridge over the first ravine: posts at both edges, the
## ropes and a few planks hanging down the cliff faces, swaying.
func _snapped_bridge(left: float, right: float, top_l: float, top_r: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	_bridge_posts(b, left + 0.08, top_l)
	_bridge_posts(b, right - 0.08, top_r)
	add_child(b.build())
	for end: Array in [[left + 0.08, top_l, 1.0], [right - 0.08, top_r, -1.0]]:
		var hang := Node3D.new()
		hang.position = Vector3(end[0], end[1] - 0.02, 0.0)
		add_child(hang)
		var r := PaperMesh.new(_rng.randi())
		r.shade_jitter = 0.15
		var dir: float = end[2]
		r.color = ROPE
		for pz: float in [0.72, -0.72]:
			r.box(Vector3(dir * 0.06, -1.3, pz), Vector3(0.025, 2.6, 0.025))
		var y := -0.25
		for k in 7:
			r.color = TIMBER_WARM.darkened(_rng.randf_range(0.1, 0.35))
			r.box(Vector3(dir * 0.09, y, _rng.randf_range(-0.05, 0.05)), Vector3(0.05, 0.2, 1.45 - _rng.randf_range(0.0, 0.3)))
			y -= _rng.randf_range(0.3, 0.38)
		hang.add_child(r.build())
		hang.rotation.z = dir * 0.04
		Scenery.windswept(hang, 0.02, _rng)


## A rope between two points, sagging, as a strip of short boxes.
func _rope(b: PaperMesh, a: Vector2, c: Vector2, sag: float, z: float, thick: float) -> void:
	var steps := 16
	var last := a
	for k in range(1, steps + 1):
		var t := float(k) / steps
		var p := a.lerp(c, t) - Vector2(0.0, sag * sin(t * PI))
		b.extrude(PackedVector2Array([last + Vector2(0, -thick * 0.5), p + Vector2(0, -thick * 0.5), p + Vector2(0, thick * 0.5), last + Vector2(0, thick * 0.5)]),
				z - thick * 0.5, z + thick * 0.5)
		last = p


# --- The bamboo ---------------------------------------------------------------------

## Thick stems of paper bamboo at many depths, as in Julian's picture: fresh
## greens close by, paler and mistier further back, leaf sprays from the
## nodes. Every stem stands on ground: none over a ravine (and none with its
## foot in the air). The few dark stems framing the front rise from below
## the bottom of the screen. Each sways from its foot.
func _bamboo() -> void:
	var x := GATE_X - 12.0
	while x < EAST_END + 12.0:
		# Behind the path, rows deeper and deeper on the forest floor.
		for row: Array in [[-2.4, 1.0, 0.0], [-4.2, 0.95, 0.08], [-6.0, 0.85, 0.2]]:
			if _rng.randf() < 0.7:
				var cx := x + _rng.randf_range(-0.6, 0.6)
				var z: float = row[0] + _rng.randf_range(-0.5, 0.5)
				if _standing(cx, 0.35):
					# (Down in the gorge they grow up out of it; under the
					# canopy road, taller, so the decks have stems to hang on.)
					var tall := _rng.randf_range(13.0, 18.0) + maxf(1.5 - _foot(cx), 0.0) * 0.9
					if cx > 290.0 and cx < 346.0:
						tall += 6.0
					_culm(cx, z, tall, row[1], row[2])
		x += _rng.randf_range(1.2, 2.1)
	# Framing stems in front, rising from below the screen, few and dark.
	x = GATE_X + 4.0
	while x < EAST_END:
		_culm(x + _rng.randf_range(-1.0, 1.0), _rng.randf_range(3.2, 3.9), 50.0, 1.5, -0.25, -14.0)
		x += _rng.randf_range(9.0, 14.0)


## Is there ground under a stem at x (with room for its thickness)?
func _standing(x: float, margin: float) -> bool:
	for g: Array in GROUND:
		if x - margin >= g[0] and x + margin <= g[1]:
			return true
	return false


func _foot(x: float) -> float:
	for g: Array in GROUND:
		if x >= g[0] and x <= g[1]:
			return g[2]
	return -8.0


## One stem: a folded column in sections, a darker ring and a pale band at
## each node, tapering; sprays of leaves on short twigs from the upper nodes.
## `pale` 0 = close and fresh, higher = further and mistier, below 0 = a dark
## framing stem in front. `base` overrides where its foot is.
func _culm(x: float, z: float, height: float, thick: float, pale: float, base: float = NAN) -> void:
	var stem := Node3D.new()
	var foot := _foot(x) - 0.05 if is_nan(base) else base
	stem.position = Vector3(x, foot, z)
	if is_nan(base):
		stem_feet.append(Vector2(x, foot))
	add_child(stem)
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.08
	var haze := Color(0.78, 0.8, 0.66)
	var green := STEM.lerp(STEM_YELLOW, _rng.randf_range(0.0, 0.6)).lerp(haze, maxf(pale, 0.0))
	if pale < 0.0:
		green = Color(0.12, 0.2, 0.12)
	var w := _rng.randf_range(0.17, 0.24) * thick
	var y := 0.0
	var nodes: Array[float] = []
	while y < height:
		var seg := _rng.randf_range(0.85, 1.3)
		b.color = green * _rng.randf_range(0.94, 1.06)
		b.frustum(8, Vector2(w, w), Vector2(w * 0.985, w * 0.985), seg - 0.05, Vector3(0.0, y, 0.0))
		# The node: a raised dark ring, a pale powdery band under it.
		b.color = green.darkened(0.3)
		b.frustum(8, Vector2(w * 1.1, w * 1.1), Vector2(w * 1.1, w * 1.1), 0.035, Vector3(0.0, y + seg - 0.05, 0.0))
		b.color = green.lightened(0.22)
		b.frustum(8, Vector2(w * 1.01, w * 1.01), Vector2(w * 1.0, w * 1.0), 0.05, Vector3(0.0, y + seg - 0.1, 0.0))
		nodes.append(y + seg)
		y += seg
		w *= 0.988
	# Leaf sprays from the upper nodes (and a few lower on the near stems).
	var leaf_green := LEAF.lerp(haze, maxf(pale, 0.0))
	if pale < 0.0:
		leaf_green = Color(0.1, 0.18, 0.1)
	for n: float in nodes:
		var low := n < height * 0.45
		if (low and _rng.randf() > 0.12) or (not low and _rng.randf() > 0.8):
			continue
		var dir := 1.0 if _rng.randf() < 0.5 else -1.0
		var twig := Vector2(dir * _rng.randf_range(0.5, 1.1), _rng.randf_range(0.15, 0.5))
		var start := Vector2(dir * w * 0.8, n)
		b.color = green.darkened(0.15)
		b.stroke(start, start + twig, 0.025, 0.012, _rng.randf_range(-0.1, 0.1))
		for k in _rng.randi_range(6, 9):
			var at := start + twig * _rng.randf_range(0.4, 1.0)
			var a := Vector2(dir * _rng.randf_range(0.2, 1.0), _rng.randf_range(-1.0, 0.25)).normalized()
			_leaf(b, at, a, _rng.randf_range(0.5, 0.85), leaf_green, _rng.randf_range(-0.12, 0.12))
	var mesh := b.build()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if pale <= 0.05 and pale >= 0.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if pale < 0.0:
		(mesh.material_override as StandardMaterial3D).disable_fog = true
	stem.add_child(mesh)
	Scenery.windswept(stem, -0.011, _rng)


## One bamboo leaf: a long blade, pointed, broadest a third of the way out,
## the half nearer the light paler.
func _leaf(b: PaperMesh, at: Vector2, dir: Vector2, length: float, green: Color, z: float) -> void:
	var side := dir.orthogonal()
	var wide := length * 0.11
	b.color = green.lightened(_rng.randf_range(0.0, 0.18))
	b.polygon(PackedVector2Array([at, at + dir * length * 0.3 + side * wide, at + dir * length * 0.7 + side * wide * 0.55, at + dir * length]), z)
	b.color = green.darkened(_rng.randf_range(0.05, 0.2))
	b.polygon(PackedVector2Array([at, at + dir * length, at + dir * length * 0.7 - side * wide * 0.55, at + dir * length * 0.3 - side * wide]), z + 0.002)


# --- The great crane ----------------------------------------------------------------

## An old stone altar beside the path, moss on it, and on it a great crane
## folded from a single sheet, glowing faintly in the dark.
func _altar() -> void:
	var g := _foot(ALTAR_X)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	b.color = Canals.STONE.lightened(0.12)
	b.box(Vector3(ALTAR_X, g + 0.2, -1.6), Vector3(1.4, 0.4, 1.0))
	b.color = Canals.STONE.lightened(0.18)
	b.box(Vector3(ALTAR_X, g + 0.6, -1.6), Vector3(1.0, 0.4, 0.8))
	b.color = Color(0.22, 0.3, 0.18)
	b.box(Vector3(ALTAR_X - 0.3, g + 0.81, -1.5), Vector3(0.4, 0.03, 0.4))
	# Shide streamers on a rope round it.
	b.color = Color(0.5, 0.44, 0.34)
	b.box(Vector3(ALTAR_X, g + 0.75, -1.18), Vector3(1.05, 0.05, 0.05))
	add_child(b.build())
	_crane = Node3D.new()
	_crane.position = Vector3(ALTAR_X, g + 0.8, -1.6)
	add_child(_crane)
	var c := PaperMesh.new(_rng.randi())
	c.texture_world = false
	c.shade_jitter = 0.12
	c.color = PaperMesh.WASHI
	# Body, two wings raised, neck and head, tail.
	c.tri(Vector3(-0.3, 0.15, 0.0), Vector3(0.3, 0.15, 0.0), Vector3(0.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		c.tri(Vector3(-0.15, 0.15, 0.0), Vector3(0.15, 0.15, 0.0), Vector3(-0.1, 0.7, side * 0.8))
	c.color = PaperMesh.WASHI.darkened(0.12)
	c.tri(Vector3(0.25, 0.15, -0.03), Vector3(0.55, 0.62, 0.0), Vector3(0.25, 0.15, 0.03))
	c.tri(Vector3(0.55, 0.62, -0.02), Vector3(0.72, 0.56, 0.0), Vector3(0.55, 0.62, 0.02))
	c.tri(Vector3(-0.25, 0.15, -0.03), Vector3(-0.6, 0.5, 0.0), Vector3(-0.25, 0.15, 0.03))
	var bird := c.build(Color.WHITE, 0.35)
	_crane.add_child(bird)
	var glow := Scenery.halo(1.4, Color(0.85, 0.9, 1.0, 0.2))
	glow.position = Vector3(0.0, 0.4, 0.4)
	_crane.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = Color(0.85, 0.9, 1.0)
	light.light_energy = 0.9
	light.omni_range = 3.5
	light.position = Vector3(0.0, 0.6, 1.0)
	_crane.add_child(light)


func _process(delta: float) -> void:
	if _crane and not _crane_taken:
		# It stirs: wings lifting a little in the wind.
		_crane.rotation.z = sin(Wind.now() * 1.4) * 0.03
		_crane.position.y = _foot(ALTAR_X) + 0.8 + sin(Wind.now() * 0.9) * 0.02
	if _leaves:
		_leaves.gravity.x = -0.4 - Wind.speed_at(_leaves.global_position.x) * 0.5


func _physics_process(_delta: float) -> void:
	if _crane_taken:
		return
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	if absf(_ronin.global_position.x - SHIFT - ALTAR_X) < 1.0 and _ronin.is_on_floor():
		learn_glide()


## The crane rises off the altar, circles him once, and folds itself away
## into his cloak (shrinking into his back): he can glide.
func learn_glide(at_once: bool = false) -> void:
	if _crane_taken:
		return
	_crane_taken = true
	_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	if _ronin:
		_ronin.has_glide = true
	if "glide" not in SaveGame.abilities:
		SaveGame.abilities.append("glide")
	if at_once:
		_crane.visible = false
		return
	SaveGame.write()
	Sound.play(self, &"cranes_rise", 4.0)
	var to := _ronin.global_position + Vector3(0.0, 1.2, 0.0) if _ronin else _crane.global_position
	var fly := create_tween()
	fly.tween_property(_crane, "global_position", _crane.global_position + Vector3(0.0, 2.2, 0.8), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fly.parallel().tween_property(_crane, "rotation:y", TAU, 0.9)
	fly.tween_property(_crane, "global_position", to + Vector3(0.0, 0.3, 0.3), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fly.parallel().tween_property(_crane, "scale", Vector3.ONE * 0.001, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fly.tween_callback(func() -> void:
		_crane.visible = false
		if _ronin:
			(_ronin.get_node("Puppet") as RoninPuppet).play_healed()
		var card := AbilityCard.new()
		card.used = func() -> bool: return is_instance_valid(_ronin) and _ronin.is_gliding()
		get_tree().current_scene.get_node("Overlay").add_child(card))


# --- Its own sky -------------------------------------------------------------------

## The grove is far from the town's backdrop, so it has its own, in
## daylight as in Julian's picture: a warm hazy sky, a red paper sun with
## clouds across it, misty blue-green mountains (a pagoda on one), a far
## cliff with a torii and waterfalls into the mist, then rows of bamboo
## further and further back, each paler and hazier, mist at each foot (the
## same recipe as the town's backdrop).
func _build_sky() -> void:
	var left := GATE_X - 60.0
	var right := EAST_END + 60.0
	var sky := PaperMesh.new(_rng.randi())
	sky.shade_jitter = 0.0
	sky.fade_quad(Vector3(left, 40.0, -53.0), Vector3(right, 40.0, -53.0), Vector3(right, 10.0, -53.0), Vector3(left, 10.0, -53.0),
			Color(0.86, 0.8, 0.64), Color(0.96, 0.9, 0.74))
	sky.fade_quad(Vector3(left, 10.0, -53.0), Vector3(right, 10.0, -53.0), Vector3(right, -20.0, -53.0), Vector3(left, -20.0, -53.0),
			Color(0.96, 0.9, 0.74), Color(0.9, 0.88, 0.76))
	_flat(sky)
	# The sun, red paper, with cream clouds drifting across it.
	var sun := PaperMesh.new(_rng.randi())
	sun.shade_jitter = 0.03
	sun.color = Color(0.86, 0.3, 0.22)
	sun.ellipse(Vector2(SUN_AT.x, SUN_AT.y), Vector2(4.2, 4.2), 32, -51.0, 0.02)
	sun.color = Color(0.92, 0.42, 0.32)
	sun.ellipse(Vector2(SUN_AT.x - 0.8, SUN_AT.y + 0.9), Vector2(2.6, 2.6), 24, -50.98, 0.03)
	_flat(sun)
	for cloud: Array in [[SUN_AT.x + 3.0, SUN_AT.y - 1.6, 9.0, 1.3], [SUN_AT.x - 5.0, SUN_AT.y - 3.2, 7.0, 1.0],
			[SUN_AT.x + 14.0, SUN_AT.y + 2.0, 8.0, 1.1], [SUN_AT.x - 22.0, SUN_AT.y + 4.0, 10.0, 1.2], [SUN_AT.x + 30.0, SUN_AT.y - 3.0, 9.0, 1.0]]:
		var c := PaperMesh.new(_rng.randi())
		c.shade_jitter = 0.04
		var mid := Vector2(cloud[0], cloud[1])
		var outline := PackedVector2Array()
		for k in 24:
			var t := TAU * k / 24.0
			var bump := 1.0 + 0.25 * sin(t * 5.0 + _rng.randf()) if sin(t) > 0.0 else 1.0
			outline.append(mid + Vector2(cos(t) * cloud[2] * 0.5, sin(t) * cloud[3] * 0.5 * bump * (1.3 if sin(t) > 0.0 else 0.6)))
		c.color = Color(0.97, 0.93, 0.84)
		c.torn_sheet(PaperMesh.tear(outline, 0.6, 0.12, _rng), -50.5 + _rng.randf_range(0.0, 0.2), Color(1.0, 0.97, 0.9), 0.08)
		_flat(c)
	# Mountains: far ones pale, nearer ones a little greener; a pagoda on a
	# peak, its roofs stacked.
	for layer: Array in [[-47.0, 4.0, 12.0, Color(0.6, 0.66, 0.66), 0.09], [-40.0, 1.0, 8.0, Color(0.46, 0.55, 0.52), 0.06]]:
		var hills := PaperMesh.new(_rng.randi())
		hills.shade_jitter = 0.0
		var line := PackedVector2Array()
		var x := left
		var freq: float = layer[4]
		while x < right:
			line.append(Vector2(x, layer[1] + layer[2] * pow(absf(sin(x * freq + layer[0])), 1.6)))
			x += _rng.randf_range(2.0, 4.0)
		line.append(Vector2(right, layer[1]))
		var outline := PaperMesh.tear(line, 1.0, 0.2, _rng, false)
		outline.append(Vector2(right, -20.0))
		outline.append(Vector2(left, -20.0))
		hills.color = layer[3]
		hills.torn_sheet(outline, layer[0], (layer[3] as Color).lightened(0.3), 0.12)
		_flat(hills)
		var mist := PaperMesh.new(1)
		mist.fade_quad(Vector3(left, -3.0, layer[0] + 0.4), Vector3(right, -3.0, layer[0] + 0.4), Vector3(right, layer[1] + 4.0, layer[0] + 0.4),
				Vector3(left, layer[1] + 4.0, layer[0] + 0.4), Color(0.95, 0.92, 0.82, 0.8), Color(0.95, 0.92, 0.82, 0.0))
		add_child(mist.build_veil())
	_pagoda(Vector3(SUN_AT.x + 9.0, 9.2, -39.5), 1.0)
	# A far cliff with a torii on it, and waterfalls pouring into the mist.
	_far_cliff(Vector3(223.0, 0.0, -28.0))
	_far_cliff(Vector3(252.0, -1.0, -30.0))
	# Rows of bamboo further back, paler and hazier, rooted in the mist.
	for row: Array in [[-24.0, Color(0.62, 0.68, 0.56), 0.5], [-17.0, Color(0.48, 0.58, 0.42), 0.42], [-11.0, Color(0.36, 0.5, 0.3), 0.36]]:
		var far := PaperMesh.new(_rng.randi())
		far.shade_jitter = 0.0
		far.texture_scale = 0.0
		var x := left
		while x < right:
			var w: float = row[2] * _rng.randf_range(0.7, 1.2)
			var lean := _rng.randf_range(-0.4, 0.4)
			far.color = (row[1] as Color) * _rng.randf_range(0.94, 1.06)
			far.polygon(PackedVector2Array([Vector2(x - w * 0.5, -4.0), Vector2(x + w * 0.5, -4.0),
					Vector2(x + w * 0.4 + lean, 30.0), Vector2(x - w * 0.4 + lean, 30.0)]), row[0])
			# Node rings, and leaf sprays near the tops.
			far.color = (row[1] as Color).darkened(0.12)
			var ny := _rng.randf_range(0.0, 1.0)
			while ny < 28.0:
				far.rect(Vector2(x + lean * ny / 34.0, ny), Vector2(w * 1.05, 0.06), row[0] + 0.002)
				ny += _rng.randf_range(1.1, 1.5)
			far.color = (row[1] as Color).lerp(LEAF, 0.25)
			for k in 3:
				var at := Vector2(x + lean * 0.6, _rng.randf_range(10.0, 22.0))
				var dir := 1.0 if k % 2 == 0 else -1.0
				for l in 4:
					var a := Vector2(dir * _rng.randf_range(0.3, 1.0), _rng.randf_range(-0.9, 0.2)).normalized()
					far.polygon(PackedVector2Array([at, at + a * 0.6 + a.orthogonal() * 0.1, at + a * 1.6, at + a * 0.6 - a.orthogonal() * 0.1]), row[0] + 0.004)
			x += _rng.randf_range(1.4, 3.0)
		_flat(far)
		var mist := PaperMesh.new(1)
		mist.fade_quad(Vector3(left, -4.0, row[0] + 0.3), Vector3(right, -4.0, row[0] + 0.3), Vector3(right, 5.0, row[0] + 0.3), Vector3(left, 5.0, row[0] + 0.3),
				Color(0.95, 0.92, 0.8, 0.6), Color(0.95, 0.92, 0.8, 0.0))
		add_child(mist.build_veil())


## A sheet of the backdrop: unshaded, no fog, no shadow.
func _flat(b: PaperMesh) -> void:
	var mesh := b.build(Color.WHITE, 0.0, true)
	(mesh.material_override as StandardMaterial3D).disable_fog = true
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


## A far pagoda on a peak: stacked roofs, small, hazy.
func _pagoda(at: Vector3, s: float) -> void:
	var p := PaperMesh.new(_rng.randi())
	p.shade_jitter = 0.0
	var tone := Color(0.36, 0.42, 0.44)
	var y := at.y
	for k in 4:
		var wide := (1.6 - k * 0.28) * s
		p.color = tone.lightened(0.08)
		p.rect(Vector2(at.x, y + 0.28 * s), Vector2(wide * 0.6, 0.56 * s), at.z)
		p.color = tone
		p.polygon(PackedVector2Array([Vector2(at.x - wide, y + 0.56 * s), Vector2(at.x + wide, y + 0.56 * s),
				Vector2(at.x + wide * 0.45, y + 0.8 * s), Vector2(at.x - wide * 0.45, y + 0.8 * s)]), at.z + 0.01)
		y += 0.8 * s
	p.rect(Vector2(at.x, y + 0.4 * s), Vector2(0.06 * s, 0.8 * s), at.z + 0.01)
	_flat(p)


## A far cliff: a crag of rock with moss on top and a small red torii on its
## edge, two waterfalls pouring off it into the mist below.
func _far_cliff(at: Vector3) -> void:
	var c := PaperMesh.new(_rng.randi())
	c.shade_jitter = 0.0
	var top := at.y + 6.0
	var outline := PackedVector2Array([Vector2(at.x - 5.0, at.y - 6.0), Vector2(at.x + 5.5, at.y - 6.0), Vector2(at.x + 4.6, top - 1.0),
			Vector2(at.x + 3.0, top), Vector2(at.x - 3.4, top + 0.3), Vector2(at.x - 4.6, top - 1.4)])
	c.color = Color(0.5, 0.52, 0.48)
	c.torn_sheet(PaperMesh.tear(outline, 0.6, 0.18, _rng), at.z, Color(0.66, 0.68, 0.6), 0.08)
	c.color = Color(0.46, 0.56, 0.36)
	c.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(at.x - 3.6, top + 0.35), Vector2(at.x + 3.1, top + 0.05), Vector2(at.x + 3.0, top - 0.5),
			Vector2(at.x - 3.5, top - 0.3)]), 0.4, 0.1, _rng), at.z + 0.02, Color(0.6, 0.68, 0.46), 0.05)
	# The torii, small and red.
	c.color = Color(0.78, 0.26, 0.2)
	var tx := at.x - 0.6
	for side: float in [-0.55, 0.55]:
		c.rect(Vector2(tx + side, top + 0.85), Vector2(0.09, 1.3), at.z + 0.04)
	c.rect(Vector2(tx, top + 1.45), Vector2(1.6, 0.1), at.z + 0.045)
	c.polygon(PackedVector2Array([Vector2(tx - 0.95, top + 1.6), Vector2(tx + 0.95, top + 1.6), Vector2(tx + 0.85, top + 1.72), Vector2(tx - 0.85, top + 1.72)]), at.z + 0.05)
	_flat(c)
	# Waterfalls: pale strips fading as they fall into the mist.
	var w := PaperMesh.new(1)
	for fall: Array in [[at.x + 2.2, 0.7], [at.x - 2.8, 0.5]]:
		var fx: float = fall[0]
		var fw: float = fall[1]
		w.fade_quad(Vector3(fx - fw * 0.5, top - 0.6, at.z + 0.06), Vector3(fx + fw * 0.5, top - 0.6, at.z + 0.06),
				Vector3(fx + fw * 0.6, at.y - 4.0, at.z + 0.06), Vector3(fx - fw * 0.6, at.y - 4.0, at.z + 0.06),
				Color(0.97, 0.97, 0.95, 0.9), Color(0.97, 0.97, 0.95, 0.15))
	add_child(w.build_veil())
	# Spray at their feet.
	var spray := PaperMesh.new(1)
	spray.fade_quad(Vector3(at.x - 6.0, at.y - 5.0, at.z + 0.1), Vector3(at.x + 6.0, at.y - 5.0, at.z + 0.1), Vector3(at.x + 6.0, at.y - 1.0, at.z + 0.1),
			Vector3(at.x - 6.0, at.y - 1.0, at.z + 0.1), Color(0.97, 0.95, 0.88, 0.9), Color(0.97, 0.95, 0.88, 0.0))
	add_child(spray.build_veil())


# --- The air -----------------------------------------------------------------------

## Leaves and sakura petals blown along the path; warm shafts of sunlight
## slanting down between the stems; a lantern and a crane banner by the path.
func _air() -> void:
	_leaves = _drift(70, Color(0.55, 0.66, 0.3), Vector2(0.16, 0.035))
	_petals = _drift(40, PETAL, Vector2(0.06, 0.045))
	for x: float in [199.0, 211.0, 228.0, 247.0]:
		var shaft := PaperMesh.new(1)
		var g := _foot(x)
		shaft.fade_quad(Vector3(x - 2.6, g, -3.2), Vector3(x - 1.0, g, -3.2), Vector3(x + 4.4, 16.0, -3.2), Vector3(x + 2.4, 16.0, -3.2),
				Color(1.0, 0.88, 0.6, 0.0), Color(1.0, 0.88, 0.6, 0.22))
		add_child(shaft.build_veil(true))
	# A lantern on a post by the shrine, and a banner with a crane by the altar.
	_lantern(SHRINE_X + 2.4)
	_banner(ALTAR_X - 2.2)
	_lantern(229.0)


func _drift(amount: int, tint: Color, size: Vector2) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3((EAST_END - Village.ARENA.y) * 0.5 + 6.0, 3.0, 3.0)
	p.direction = Vector3(-1.0, 0.1, 0.0)
	p.spread = 25.0
	p.gravity = Vector3(-1.0, -0.3, 0.0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.angle_max = 360.0
	p.angular_velocity_min = -200.0
	p.angular_velocity_max = 200.0
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
	p.position = Vector3((EAST_END + Village.ARENA.y) * 0.5, 4.5, -0.5)
	add_child(p)
	return p


## A small wooden lantern on a post (as in the picture), standing on the
## path's back edge, glowing warm.
func _lantern(x: float) -> void:
	var g := _foot(x)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	var z := -1.5
	b.color = TIMBER_WARM.darkened(0.2)
	b.box(Vector3(x, g + 0.4, z), Vector3(0.12, 0.8, 0.12))
	b.box(Vector3(x, g + 0.82, z), Vector3(0.5, 0.05, 0.5))
	for cx: float in [-0.2, 0.2]:
		for cz: float in [-0.2, 0.2]:
			b.box(Vector3(x + cx, g + 1.06, z + cz), Vector3(0.04, 0.46, 0.04))
	b.color = Color(0.3, 0.2, 0.14)
	b.polygon(PackedVector2Array([Vector2(x - 0.42, g + 1.3), Vector2(x + 0.42, g + 1.3), Vector2(x + 0.1, g + 1.55), Vector2(x - 0.1, g + 1.55)]), z + 0.26)
	b.box(Vector3(x, g + 1.32, z), Vector3(0.7, 0.05, 0.62))
	b.frustum(4, Vector2(0.38, 0.34), Vector2(0.06, 0.06), 0.25, Vector3(x, g + 1.34, z))
	add_child(b.build())
	var paper := PaperMesh.new(_rng.randi())
	paper.color = Color(1.0, 0.86, 0.6)
	paper.box(Vector3(x, g + 1.06, z), Vector3(0.36, 0.42, 0.36))
	add_child(paper.build(Color.WHITE, 0.8))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.45)
	light.light_energy = 1.4
	light.omni_range = 3.0
	light.position = Vector3(x, g + 1.1, z + 0.6)
	add_child(light)


## A tall red banner on a bamboo pole, a white crane and seigaiha waves on
## it, hanging on the pole's downwind side and swaying.
func _banner(x: float) -> void:
	var g := _foot(x)
	var z := -1.9
	var pole := PaperMesh.new(_rng.randi())
	pole.color = STEM_YELLOW.darkened(0.25)
	pole.frustum(6, Vector2(0.05, 0.05), Vector2(0.045, 0.045), 3.6, Vector3(x, g, z))
	pole.box(Vector3(x - 0.45, g + 3.5, z), Vector3(0.95, 0.05, 0.05))
	pole.color = ROPE
	pole.box(Vector3(x, g + 3.5, z), Vector3(0.09, 0.09, 0.09))
	add_child(pole.build())
	var hang := Node3D.new()
	hang.position = Vector3(x - 0.48, g + 3.48, z)
	add_child(hang)
	var cloth := PaperMesh.new(_rng.randi())
	cloth.texture_world = false
	cloth.color = WASHI_RED
	cloth.rect(Vector2(0.0, -1.1), Vector2(0.78, 2.2), 0.0)
	for k in 3:
		_seigaiha(cloth, Vector2(-0.24 + k * 0.24, -2.14), 0.13, 0.004 + k * 0.002)
	# The crane, in white: body, raised wing, neck and tail.
	cloth.color = Color(0.95, 0.92, 0.86)
	var c := Vector2(0.0, -0.95)
	cloth.polygon(PackedVector2Array([c + Vector2(-0.2, 0.0), c + Vector2(0.05, -0.06), c + Vector2(0.2, 0.02), c + Vector2(0.0, 0.07)]), 0.012)
	cloth.polygon(PackedVector2Array([c + Vector2(-0.06, 0.02), c + Vector2(-0.22, 0.32), c + Vector2(0.06, 0.04)]), 0.013)
	cloth.polygon(PackedVector2Array([c + Vector2(0.16, 0.02), c + Vector2(0.3, 0.26), c + Vector2(0.28, 0.27), c + Vector2(0.13, 0.05)]), 0.013)
	cloth.polygon(PackedVector2Array([c + Vector2(-0.18, 0.0), c + Vector2(-0.34, -0.12), c + Vector2(-0.15, 0.03)]), 0.013)
	hang.add_child(cloth.build())
	Scenery.windswept(hang, 0.06, _rng)
