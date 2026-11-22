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
## crossed. (Only the first stretch is built: the road goes on.)
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
const EAST_END := 258.0
## Where he arrives in the grove (local x), and where he arrives back in the
## courtyard (town x).
const ARRIVE_X := Village.ARENA.y + 1.6
const RETURN_X := Village.ARENA.y - 1.4
## The gate in the courtyard's far wall.
const GATE_X := Village.ARENA.y + 0.4
## [left x, right x, top] of the ground (between them, ravines).
const GROUND := [[Village.ARENA.y - 6.0, 213.0, 1.5], [221.5, 234.0, 1.5], [242.0, EAST_END, 2.1]]
## The altar with the great crane.
const ALTAR_X := 206.0
## The fourth shrine, just inside the gate.
const SHRINE_X := 196.0
## The gate's door, open: swung back away from us so it is seen edge-on
## (swung toward us it stuck out at the camera like a slab: Julian, "looks bad").
const OPEN_ANGLE := 88.0

var village: Village
var gate_open := false
var shrine: RestShrine
var _rng := RandomNumberGenerator.new()
var _gate_solid: StaticBody3D
var _door: Node3D
var _beyond_light: OmniLight3D
var _crane: Node3D
var _crane_taken := false
var _ronin: Ronin
var _leaves: CPUParticles3D
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
	_build_gate_from_grove()
	_build_sky()
	for g: Array in GROUND:
		_ground(g[0], g[1], g[2])
	_ravines()
	_bamboo()
	_altar()
	_air()
	for x: float in [200.0, 218.0, 238.0, 252.0]:
		Sound.place_loop(self, "bamboo_wind.ogg", Vector3(x, 4.0, -1.0), -6.0, 9.0)
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
	for span: Vector2 in [Vector2(-12.0, -1.25), Vector2(1.25, 1.5)]:
		b.color = Color(0.5, 0.49, 0.5)
		b.box(Vector3(GATE_X, g + 1.4, (span.x + span.y) * 0.5), Vector3(0.5, 2.8, span.y - span.x))
		b.color = Canals.STONE.lightened(0.1)
		b.box(Vector3(GATE_X, g + 0.3, (span.x + span.y) * 0.5), Vector3(0.56, 0.6, span.y - span.x))
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
	# The door (seen from its edge: shown facing us, hinged on the near post).
	_door = Node3D.new()
	_door.position = Vector3(GATE_X - 0.55, g, 1.12)
	_town_gate.add_child(_door)
	var d := PaperMesh.new(_rng.randi())
	d.shade_jitter = 0.16
	var x := 0.0
	while x < 1.1:
		var x1 := minf(x + 0.27, 1.1)
		d.color = Scenery.WOOD.darkened(_rng.randf_range(0.05, 0.25))
		d.box(Vector3((x + x1) * 0.5, 1.3, 0.0), Vector3(x1 - x - 0.02, 2.6, 0.08))
		x = x1
	d.color = Color(0.12, 0.12, 0.15)
	for band: float in [0.4, 2.2]:
		d.box(Vector3(0.55, band, 0.05), Vector3(1.1, 0.07, 0.02))
	_door.add_child(d.build())
	_gate_solid = village._add_solid(Vector3(GATE_X, g + 1.5, 0.0), Vector3(0.5, 3.0, 2.2))
	# Light beyond it, unseen until it opens: the grove's cold moonlight.
	_beyond_light = OmniLight3D.new()
	_beyond_light.light_color = Color(0.6, 0.78, 0.7)
	_beyond_light.light_energy = 0.0
	_beyond_light.omni_range = 6.0
	_beyond_light.position = Vector3(GATE_X + 1.5, g + 2.0, 0.5)
	_town_gate.add_child(_beyond_light)


## The same gate seen from the grove, at its west end: standing open (he has
## just come through it), the courtyard dark beyond.
func _build_gate_from_grove() -> void:
	var g := 1.5
	_gate_frame(self, g)
	var door := Node3D.new()
	door.position = Vector3(GATE_X - 0.55, g, 1.12)
	door.rotation.y = deg_to_rad(OPEN_ANGLE)
	add_child(door)
	var d := PaperMesh.new(_rng.randi())
	d.shade_jitter = 0.16
	var x := 0.0
	while x < 1.1:
		var x1 := minf(x + 0.27, 1.1)
		d.color = Scenery.WOOD.darkened(_rng.randf_range(0.05, 0.25))
		d.box(Vector3((x + x1) * 0.5, 1.3, 0.0), Vector3(x1 - x - 0.02, 2.6, 0.08))
		x = x1
	d.color = Color(0.12, 0.12, 0.15)
	for band: float in [0.4, 2.2]:
		d.box(Vector3(0.55, band, 0.05), Vector3(1.1, 0.07, 0.02))
	door.add_child(d.build())


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
	if at_once:
		_door.rotation.y = deg_to_rad(OPEN_ANGLE)
		_beyond_light.light_energy = 1.4
		return
	Sound.play(self, &"plank_creak", -1.0)
	var t := create_tween()
	t.tween_property(_door, "rotation:y", deg_to_rad(OPEN_ANGLE + 7.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_door, "rotation:y", deg_to_rad(OPEN_ANGLE), 0.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_beyond_light, "light_energy", 1.4, 1.4)


# --- The ground ------------------------------------------------------------------

## The path through the grove: packed earth, fallen leaves, its torn front
## edge in layers of dark earth and moss.
func _ground(left: float, right: float, top: float) -> void:
	_solid(Vector3((left + right) * 0.5, top - 4.0, -1.5), Vector3(right - left, 8.0, 6.0))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	var earth := Color(0.16, 0.17, 0.2)
	b.color = Village.EARTH
	# (Stopping short of the front, so it does not sit at the same depth as
	# the torn edge there and flicker.)
	b.box(Vector3((left + right) * 0.5, top - 5.02, -3.33), Vector3(right - left, 10.0, 9.34))
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 4.0, right)
		b.color = earth * _rng.randf_range(0.9, 1.1)
		b.quad(Vector3(x, top, -8.0), Vector3(x1, top, -8.0), Vector3(x1, top, 1.5), Vector3(x, top, 1.5), Vector3.UP)
		x = x1
	# Fallen bamboo leaves: thin pale-green slivers lying on the path.
	for i in int((right - left) * 3.0):
		var at := Vector3(_rng.randf_range(left + 0.2, right - 0.2), top + 0.012, _rng.randf_range(-5.0, 1.3))
		var turn := _rng.randf() * TAU
		var along := Vector3(cos(turn), 0.0, sin(turn)) * 0.13
		var across := Vector3(-sin(turn), 0.0, cos(turn)) * 0.022
		b.color = Color(0.42, 0.46, 0.3).lerp(Color(0.5, 0.44, 0.3), _rng.randf())
		b.quad(at - along, at - across, at + along, at + across, Vector3.UP)
	add_child(b.build())
	var front := PaperMesh.new(_rng.randi())
	front.shade_jitter = 0.04
	for layer: Array in [[0.0, Color(0.17, 0.19, 0.2), Color(0.38, 0.42, 0.36)], [0.3, Color(0.09, 0.1, 0.12), Color(0.2, 0.24, 0.22)],
			[0.8, Color(0.05, 0.055, 0.07), Color(0.12, 0.14, 0.14)]]:
		var line := PackedVector2Array()
		var fx := left
		while fx < right:
			line.append(Vector2(fx, top - layer[0] + _rng.randf_range(-0.08, 0.06)))
			fx += _rng.randf_range(0.6, 1.6)
		line.append(Vector2(right, top - layer[0]))
		var outline := PaperMesh.tear(line, 0.25, 0.02, _rng, false)
		outline.append(Vector2(right, top - 14.0))
		outline.append(Vector2(left, top - 14.0))
		front.color = layer[1]
		front.torn_sheet(outline, Village.STREET_FRONT + layer[0] * 0.2, layer[2], 0.03)
	# Moss along the lip.
	front.color = Color(0.22, 0.3, 0.18)
	var mx := left + 0.5
	while mx < right - 0.5:
		front.ellipse(Vector2(mx, top - 0.05), Vector2(_rng.randf_range(0.2, 0.45), 0.05), 7, Village.STREET_FRONT + 0.08, 0.2)
		mx += _rng.randf_range(1.5, 3.5)
	var cliff := front.build()
	cliff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cliff)


## The ravines between: the earth's broken faces with roots hanging, and
## mist welling up from far below.
func _ravines() -> void:
	for i in GROUND.size() - 1:
		var left: float = GROUND[i][1]
		var right: float = GROUND[i + 1][0]
		var veil := PaperMesh.new(1)
		for k in 3:
			var z := -4.0 + k * 2.2
			veil.fade_quad(Vector3(left - 0.5, -6.0, z), Vector3(right + 0.5, -6.0, z), Vector3(right + 0.5, -0.8 + k * 0.4, z),
					Vector3(left - 0.5, -0.8 + k * 0.4, z), Color(0.55, 0.62, 0.7, 0.45), Color(0.55, 0.62, 0.7, 0.0))
		add_child(veil.build_veil())
		for edge: float in [left, right]:
			var x := edge
			for k in 4:
				var hang := Node3D.new()
				hang.position = Vector3(x + (0.15 if edge == right else -0.15) * k * 0.3, GROUND[i][2] - 0.1, Village.STREET_FRONT + 0.1)
				add_child(hang)
				var root := PaperMesh.new(_rng.randi())
				root.color = Color(0.1, 0.09, 0.09)
				root.stroke(Vector2.ZERO, Vector2(_rng.randf_range(-0.15, 0.15), -_rng.randf_range(0.8, 2.4)), 0.05, 0.008)
				hang.add_child(root.build())
				Scenery.windswept(hang, 0.035, _rng)


# --- The bamboo ---------------------------------------------------------------------

## Stems of bamboo at many depths: a few dark ones close in front, many
## behind the path, more and paler further back. Each sways from its foot.
func _bamboo() -> void:
	var x := GATE_X - 12.0
	while x < EAST_END + 12.0:
		# Behind the path, three rows deep.
		for row: Array in [[-2.3, 1.0, 0.0], [-5.5, 0.85, 0.12], [-10.0, 0.7, 0.28]]:
			if _rng.randf() < 0.75:
				_culm(x + _rng.randf_range(-0.6, 0.6), row[0] + _rng.randf_range(-0.8, 0.8), _rng.randf_range(11.0, 16.0), row[1], row[2])
		# Now and then a dark one in front.
		if _rng.randf() < 0.18:
			_culm(x + _rng.randf_range(-0.5, 0.5), _rng.randf_range(2.6, 3.8), 16.0, 1.25, -0.25)
		x += _rng.randf_range(1.1, 2.0)


func _foot(x: float) -> float:
	for g: Array in GROUND:
		if x >= g[0] and x <= g[1]:
			return g[2]
	return -8.0


func _culm(x: float, z: float, height: float, thick: float, pale: float) -> void:
	var stem := Node3D.new()
	stem.position = Vector3(x, _foot(x) - 0.1, z)
	add_child(stem)
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.1
	var green := Color(0.24, 0.36, 0.26).lerp(Color(0.5, 0.58, 0.62), pale)
	if pale < 0.0:
		green = Color(0.03, 0.05, 0.05)
	var w := 0.09 * thick
	# The stem: a folded column, slightly tapering, in sections with a
	# paler ring at each node.
	var y := 0.0
	while y < height:
		var seg := _rng.randf_range(0.7, 1.1)
		b.color = green * _rng.randf_range(0.92, 1.08)
		b.frustum(6, Vector2(w, w), Vector2(w * 0.97, w * 0.97), seg - 0.03, Vector3(0.0, y, 0.0))
		b.color = green.lightened(0.18) if pale >= 0.0 else green
		b.frustum(6, Vector2(w * 1.12, w * 1.12), Vector2(w * 1.12, w * 1.12), 0.03, Vector3(0.0, y + seg - 0.03, 0.0))
		y += seg
		w *= 0.985
	# Leaves near the top: sprays of long thin blades.
	b.color = (Color(0.28, 0.4, 0.26) if pale >= 0.0 else Color(0.02, 0.04, 0.04)).lerp(Color(0.5, 0.58, 0.62), maxf(pale, 0.0))
	for k in _rng.randi_range(3, 6):
		var at := Vector2(0.0, height * _rng.randf_range(0.6, 0.98))
		var dir := 1.0 if _rng.randf() < 0.5 else -1.0
		for blade in 4:
			var a := Vector2(dir * _rng.randf_range(0.5, 1.1), _rng.randf_range(-0.5, 0.1)).normalized()
			var tip := at + a * _rng.randf_range(0.45, 0.8)
			var side := a.orthogonal() * 0.04
			b.polygon(PackedVector2Array([at, at + side + a * 0.2, tip, at - side + a * 0.25]), _rng.randf_range(-0.05, 0.05))
	var mesh := b.build()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if pale != 0.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if pale < 0.0:
		(mesh.material_override as StandardMaterial3D).disable_fog = true
	stem.add_child(mesh)
	Scenery.windswept(stem, -0.011, _rng)


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

## The grove is far from the town's backdrop, so it has its own: the night
## sky (the same dull indigo), the moon, far misty hills, and rows of bamboo
## further and further back, each paler and bluer, with mist at its foot
## (the same recipe as the town's backdrop).
func _build_sky() -> void:
	var left := GATE_X - 60.0
	var right := EAST_END + 60.0
	var sky := PaperMesh.new(_rng.randi())
	sky.shade_jitter = 0.0
	sky.fade_quad(Vector3(left, 40.0, -53.0), Vector3(right, 40.0, -53.0), Vector3(right, 8.0, -53.0), Vector3(left, 8.0, -53.0),
			Color(0.07, 0.08, 0.17), Color(0.17, 0.2, 0.36))
	sky.fade_quad(Vector3(left, 8.0, -53.0), Vector3(right, 8.0, -53.0), Vector3(right, -20.0, -53.0), Vector3(left, -20.0, -53.0),
			Color(0.17, 0.2, 0.36), Color(0.2, 0.24, 0.4))
	var sky_mesh := sky.build(Color.WHITE, 0.0, true)
	(sky_mesh.material_override as StandardMaterial3D).disable_fog = true
	sky_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sky_mesh)
	# The moon, crumpled paper, low over the grove; a soft halo.
	var moon := PaperMesh.new(_rng.randi())
	moon.color = Color(0.86, 0.84, 0.72)
	moon.ellipse(Vector2(226.0, 17.0), Vector2(3.0, 3.0), 24, -50.0, 0.04)
	var moon_mesh := moon.build(Color.WHITE, 0.0, true)
	(moon_mesh.material_override as StandardMaterial3D).disable_fog = true
	add_child(moon_mesh)
	var halo := PaperMesh.new(1)
	for k in 12:
		var a0 := TAU * k / 12.0
		var a1 := TAU * (k + 1) / 12.0
		halo.fade_quad(Vector3(226.0 + cos(a0) * 3.0, 17.0 + sin(a0) * 3.0, -50.2), Vector3(226.0 + cos(a1) * 3.0, 17.0 + sin(a1) * 3.0, -50.2),
				Vector3(226.0 + cos(a1) * 9.0, 17.0 + sin(a1) * 9.0, -50.2), Vector3(226.0 + cos(a0) * 9.0, 17.0 + sin(a0) * 9.0, -50.2),
				Color(0.7, 0.72, 0.8, 0.16), Color(0.7, 0.72, 0.8, 0.0))
	add_child(halo.build_veil(true))
	# Far hills, then rows of bamboo further and further back.
	for layer: Array in [[-46.0, 2.0, 7.0, Color(0.3, 0.35, 0.55)], [-38.0, 0.0, 5.0, Color(0.24, 0.29, 0.46)]]:
		var hills := PaperMesh.new(_rng.randi())
		hills.shade_jitter = 0.0
		hills.color = layer[3]
		var line := PackedVector2Array()
		var x := left
		while x < right:
			line.append(Vector2(x, layer[1] + layer[2] * (0.5 + 0.5 * sin(x * 0.05 + layer[0]))))
			x += _rng.randf_range(3.0, 6.0)
		line.append(Vector2(right, layer[1] + layer[2] * 0.5))
		var outline := PaperMesh.tear(line, 1.2, 0.25, _rng, false)
		outline.append(Vector2(right, -20.0))
		outline.append(Vector2(left, -20.0))
		hills.torn_sheet(outline, layer[0], (layer[3] as Color).lightened(0.25), 0.12)
		var hill_mesh := hills.build(Color.WHITE, 0.0, true)
		(hill_mesh.material_override as StandardMaterial3D).disable_fog = true
		hill_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(hill_mesh)
	for row: Array in [[-30.0, Color(0.27, 0.34, 0.45), 0.5], [-22.0, Color(0.2, 0.27, 0.34), 0.42], [-15.0, Color(0.14, 0.2, 0.24), 0.36]]:
		var far := PaperMesh.new(_rng.randi())
		far.shade_jitter = 0.0
		far.texture_scale = 0.0
		far.color = row[1]
		var x := left
		while x < right:
			var w: float = row[2] * _rng.randf_range(0.7, 1.2)
			var lean := _rng.randf_range(-0.6, 0.6)
			far.polygon(PackedVector2Array([Vector2(x - w * 0.5, -2.0), Vector2(x + w * 0.5, -2.0),
					Vector2(x + w * 0.4 + lean, 30.0), Vector2(x - w * 0.4 + lean, 30.0)]), row[0])
			# A few leaf sprays near the tops.
			for k in 2:
				var at := Vector2(x + lean * 0.7, _rng.randf_range(12.0, 22.0))
				far.polygon(PackedVector2Array([at, at + Vector2(1.6, 0.5), at + Vector2(2.2, 0.1), at + Vector2(1.4, -0.2)]), row[0] + 0.01)
				far.polygon(PackedVector2Array([at, at + Vector2(-1.5, 0.6), at + Vector2(-2.1, 0.2), at + Vector2(-1.3, -0.15)]), row[0] + 0.01)
			x += _rng.randf_range(1.6, 3.4)
		var far_mesh := far.build(Color.WHITE, 0.0, true)
		(far_mesh.material_override as StandardMaterial3D).disable_fog = true
		far_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(far_mesh)
		# Mist at the foot of each row.
		var mist := PaperMesh.new(1)
		mist.fade_quad(Vector3(left, -2.0, row[0] + 0.3), Vector3(right, -2.0, row[0] + 0.3), Vector3(right, 6.0, row[0] + 0.3), Vector3(left, 6.0, row[0] + 0.3),
				Color(0.32, 0.38, 0.54, 0.3), Color(0.32, 0.38, 0.54, 0.0))
		add_child(mist.build_veil())


# --- The air -----------------------------------------------------------------------

## Leaves blown along the path, and shafts of cold moonlight between stems.
func _air() -> void:
	_leaves = CPUParticles3D.new()
	_leaves.amount = 60
	_leaves.lifetime = 6.0
	_leaves.preprocess = 6.0
	_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_leaves.emission_box_extents = Vector3((EAST_END - Village.ARENA.y) * 0.5 + 6.0, 3.0, 3.0)
	_leaves.direction = Vector3(-1.0, 0.1, 0.0)
	_leaves.spread = 25.0
	_leaves.gravity = Vector3(-1.0, -0.3, 0.0)
	_leaves.initial_velocity_min = 0.5
	_leaves.initial_velocity_max = 1.5
	_leaves.angle_max = 360.0
	_leaves.angular_velocity_min = -200.0
	_leaves.angular_velocity_max = 200.0
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.16, 0.035)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.36, 0.44, 0.3)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.material = look
	_leaves.mesh = leaf
	_leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_leaves.position = Vector3((EAST_END + Village.ARENA.y) * 0.5, 4.5, -0.5)
	add_child(_leaves)
	for x: float in [199.0, 211.0, 228.0, 247.0]:
		var shaft := PaperMesh.new(1)
		shaft.fade_quad(Vector3(x - 1.2, _foot(x), -3.0), Vector3(x + 0.6, _foot(x), -3.0), Vector3(x + 2.6, 14.0, -3.0), Vector3(x + 1.2, 14.0, -3.0),
				Color(0.7, 0.85, 0.8, 0.12), Color(0.7, 0.85, 0.8, 0.0))
		add_child(shaft.build_veil(true))
		var moon := OmniLight3D.new()
		moon.light_color = Color(0.62, 0.76, 0.85)
		moon.light_energy = 1.2
		moon.omni_range = 7.0
		moon.omni_attenuation = 1.5
		moon.position = Vector3(x + 0.6, _foot(x) + 3.5, 0.8)
		add_child(moon)
