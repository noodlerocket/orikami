class_name ThousandGates
extends Node3D
## The Thousand Gates (docs/thousand_gates_plan.md; design.md region 6:
## "vertical, relentless: a climb through endless vermilion torii"). Past
## Akane's ring at the end of Koinobori Skies, a rope bridge to the foot of
## the mountain. Its own place, far off along x (SHIFT).
##
## The look: late afternoon turning to dusk; the path climbs through
## tunnels of old flaking vermilion torii close together, their feet black,
## donors' names brushed down their posts; low warm sun throws bars of light
## between them; stone foxes with red bibs, stone lanterns, little shrines
## piled with tiny offering gates. Under the gates it is dry; between them,
## fine drizzle.
##
## It climbs: terraces joined by stairs and by walls to cling to, five
## shrines on the way up, gatekeepers (husks in vermilion) on the paths.
## The summit (later) is for Julian to decide (plan).

const SHIFT := 5000.0
const END := 236.0
const ARRIVE_X := 3.0
const WEST_X := -6.0
## The ground along the gameplay plane: [left, right, height at left,
## height at right]. Flat terraces and stairs between them.
const PATH := [[-14.0, 30.0, 0.0, 0.0], [30.0, 44.0, 0.0, 6.0], [44.0, 70.0, 6.0, 6.0], [72.0, 100.0, 12.0, 12.0],
		[100.0, 112.0, 12.0, 18.0], [112.0, 146.0, 18.0, 18.0], [146.0, 156.0, 18.0, 26.0], [156.0, 186.0, 26.0, 26.0],
		[188.0, 236.0, 34.0, 34.0]]
## Walls between terraces: [x, bottom, top], and the stone ledges jutting
## from their faces to climb by (staggered so no ledge is under another):
## [left, right, top].
const CLIMBS := [[71.0, 6.0, 12.0], [187.0, 26.0, 34.0]]
## (Each about 2 m above the last: his jump reaches 2.5 m.)
## The first of each is a stone plinth standing on the terrace (a ledge
## hung that low was in his way: he hit his head walking to the wall).
const LEDGES := [[67.0, 68.4, 7.8, true], [69.2, 70.0, 10.0, false], [183.2, 184.6, 27.8, true], [185.2, 186.0, 29.9, false], [183.4, 184.7, 31.9, false]]
## Gate tunnels over the path: [left, right] (gates every GATE_STEP m).
const TUNNELS := [[4.0, 28.0], [46.0, 68.0], [74.0, 98.0], [114.0, 138.0], [158.0, 184.0], [192.0, 222.0]]
const GATE_STEP := 1.15
## A paper-walled gate hall (the Shuriken Dash tears through): [x, ground, id].
const WALLS := [[141.0, 18.0, "gates_wall_hall"]]
## Shrines: [x, ground, id].
const SHRINES := [[8.0, 0.0, "gates_foot"], [84.0, 12.0, "gates_middle"], [168.0, 26.0, "gates_high"], [198.0, 34.0, "gates_summit"]]
## Gatekeepers on the paths: [x, ground].
const KEEPERS := [[56.0, 6.0], [92.0, 12.0], [126.0, 18.0], [176.0, 26.0]]
## Stone foxes on plinths beside the path that wake as he comes (KitsuneStatue): x.
const FOXES := [50.0, 79.0, 120.0, 134.0, 162.0, 208.0, 218.0]
## Cranes: [id, count, x, y].
const CRANES := [["gates_tunnel", 6, 62.0, 6.0], ["gates_ledge", 6, 132.0, 18.0], ["gates_lookout", 8, 234.6, 34.0]]
## The summit lookout at the top terrace's end: a prayer wheel (x) that,
## gusted, winds a stone slab (x) up a gantry to a stone pillar (left, right)
## with a small pavilion on top, LOOKOUT_Y up.
const WHEEL_X := 225.5
const LIFT_X := 229.6
const PILLAR := Vector2(231.3, 235.9)
const LOOKOUT_Y := 40.25
## On the lookout, the altar of the Flat Fold (x). In the pillar's foot, a
## store chamber behind a heavy door shut but for a slit under it (only
## folded can he slide in): the door's x, the slit's height, the chamber's
## ceiling.
const FOLD_ALTAR_X := 233.0
const STORE_DOOR_X := 231.55
const STORE_SLIT := 0.38
const STORE_CEILING := 1.25

var _charm: Node3D
var _taught := false
var _ronin: Ronin

const VERMILION := Color(0.66, 0.24, 0.17)
const VERMILION_OLD := Color(0.56, 0.26, 0.2)
const SUMI := Color(0.1, 0.09, 0.1)
const STONE := Color(0.48, 0.46, 0.43)
const SKY_TOP := Color(0.36, 0.42, 0.56)
const SKY_LOW := Color(0.92, 0.7, 0.5)
const KEEPER_TINT := Color(0.72, 0.42, 0.36)

var village: Village
var _rng := RandomNumberGenerator.new()
var _awake := true


static func in_gates(x: float) -> bool:
	return x > SHIFT - 300.0


## The ground's height under a local x, or NAN (none).
static func ground_at(x: float) -> float:
	for p: Array in PATH:
		if x >= p[0] and x <= p[1]:
			return lerpf(p[2], p[3], (x - p[0]) / (p[1] - p[0]))
	return NAN


func _ready() -> void:
	_rng.seed = 7070
	position.x = SHIFT
	_build_sky()
	_build_mountain()
	_build_path()
	for c: Array in CLIMBS:
		_climb_wall(c[0], c[1], c[2])
	for l: Array in LEDGES:
		var lb := PaperMesh.new(_rng.randi())
		lb.shade_jitter = 0.12
		var lx: float = (l[0] + l[1]) * 0.5
		var lw: float = l[1] - l[0]
		var ly: float = l[2]
		if l[3]:
			var floor_y: float = ground_at(lx)
			_solid(Vector3(lx, (ly + floor_y) * 0.5, 0.0), Vector3(lw, ly - floor_y, 2.4))
			MarshKit.masonry(lb, Vector3(lx, (ly + floor_y) * 0.5, -0.2), Vector3(lw, ly - floor_y, 2.8), _rng, STONE, false)
		else:
			_solid(Vector3(lx, ly - 0.2, 0.0), Vector3(lw, 0.4, 2.4))
			MarshKit.masonry(lb, Vector3(lx, ly - 0.2, -0.2), Vector3(lw, 0.4, 2.8), _rng, STONE, false)
			# A bracket of stone under it, back into the wall.
			lb.color = STONE.darkened(0.25)
			lb.box(Vector3(lx, ly - 0.6, -1.2), Vector3(lw * 0.6, 0.4, 0.6))
		add_child(lb.build())
	for t: Array in TUNNELS:
		_tunnel(t[0], t[1])
	for w: Array in WALLS:
		var wall := PaperWall.new()
		wall.id = w[2]
		wall.position = Vector3(w[0], w[1], 0.0)
		add_child(wall)
	_build_offerings()
	for s: Array in SHRINES:
		var rest := RestShrine.new()
		rest.shrine_id = s[2]
		rest.position = Vector3(s[0], s[1], -0.9)
		rest.scale = Vector3.ONE * 1.2
		add_child(rest)
	for k: Array in KEEPERS:
		var husk: Node3D = Village.HUSK_SCENE.instantiate()
		husk.set(&"soak_tint", KEEPER_TINT)
		husk.position = Vector3(k[0], k[1] + 0.1, 0.0)
		add_child(husk)
	_build_lookout()
	for fx: float in FOXES:
		var fox := KitsuneStatue.new()
		fox.position = Vector3(fx, ground_at(fx), 0.0)
		add_child(fox)
	for c: Array in CRANES:
		var bundle := CraneBundle.new()
		bundle.id = c[0]
		bundle.count = c[1]
		bundle.position = Vector3(c[2], c[3], 0.0)
		add_child(bundle)
	_build_air()
	for x: float in [10.0, 60.0, 110.0, 160.0, 210.0]:
		var gy: float = ground_at(x)
		Sound.place_loop(self, "gates_evening.ogg", Vector3(x, (0.0 if is_nan(gy) else gy) + 3.0, -3.0), -12.0, 30.0)
	_solid(Vector3(WEST_X - 9.0, 20.0, 0.0), Vector3(1.0, 60.0, 4.0)).set_meta(&"no_climb", true)
	_solid(Vector3(END + 1.0, 50.0, 0.0), Vector3(1.0, 60.0, 4.0)).set_meta(&"no_climb", true)


func set_awake(on: bool) -> void:
	if on == _awake:
		return
	_awake = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _solid(center: Vector3, size: Vector3) -> StaticBody3D:
	return village._add_solid(center + Vector3(SHIFT, 0.0, 0.0), size)


func _flat(b: PaperMesh) -> MeshInstance3D:
	var mesh := b.build(Color.WHITE, 0.0, true)
	(mesh.material_override as StandardMaterial3D).disable_fog = true
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


# --- The sky and the mountain -------------------------------------------------------

func _build_sky() -> void:
	var left := -140.0
	var right := END + 200.0
	var sky := PaperMesh.new(1)
	sky.shade_jitter = 0.0
	sky.fade_quad(Vector3(left, 160.0, -53.0), Vector3(right, 160.0, -53.0), Vector3(right, 20.0, -53.0), Vector3(left, 20.0, -53.0), SKY_TOP, SKY_LOW)
	sky.fade_quad(Vector3(left, 20.0, -53.0), Vector3(right, 20.0, -53.0), Vector3(right, -40.0, -53.0), Vector3(left, -40.0, -53.0), SKY_LOW, SKY_LOW.darkened(0.2))
	_flat(sky)
	# The low sun, a warm disc behind thin bars of cloud.
	var sun := PaperMesh.new(1)
	sun.color = Color(1.0, 0.86, 0.62)
	sun.ellipse(Vector2(60.0, 26.0), Vector2(4.0, 4.0), 32, -52.0)
	_flat(sun)
	var glow := PaperMesh.new(1)
	for k in 32:
		var a0 := TAU * k / 32.0
		var a1 := TAU * (k + 1) / 32.0
		var at := Vector3(60.0, 26.0, -52.2)
		glow.fade_quad(at + Vector3(cos(a0), sin(a0), 0.0) * 3.8, at + Vector3(cos(a1), sin(a1), 0.0) * 3.8,
				at + Vector3(cos(a1), sin(a1), 0.0) * 26.0, at + Vector3(cos(a0), sin(a0), 0.0) * 26.0,
				Color(1.0, 0.8, 0.55, 0.5), Color(1.0, 0.8, 0.55, 0.0))
	add_child(glow.build_veil(true))
	for k in 10:
		var c := PaperMesh.new(_rng.randi())
		c.shade_jitter = 0.0
		var mid := Vector2(_rng.randf_range(left, right), _rng.randf_range(20.0, 50.0))
		var w := _rng.randf_range(24.0, 60.0)
		var outline := PackedVector2Array()
		for i in 18:
			var a := TAU * i / 18.0
			outline.append(mid + Vector2(cos(a) * w * 0.5, sin(a) * 0.9))
		c.color = Color(0.86, 0.62, 0.52)
		c.torn_sheet(PaperMesh.tear(outline, 0.8, 0.12, _rng), -50.0 + k * 0.05, Color(1.0, 0.86, 0.7), 0.05)
		_flat(c)


## The mountain behind the path: dark forested slopes climbing right, far
## ridges paler, gate-lines zigzagging up them (more gates, far off).
func _build_mountain() -> void:
	for layer: Array in [[-44.0, 0.45, 0.0], [-32.0, 0.3, 10.0], [-20.0, 0.15, 20.0]]:
		var z: float = layer[0]
		var tone := Color(0.2, 0.24, 0.2).lerp(SKY_LOW, (layer[1] as float) * 1.3)
		var m := PaperMesh.new(_rng.randi())
		m.shade_jitter = 0.0
		var line := PackedVector2Array()
		var x := -140.0
		while x < END + 200.0:
			var rise := clampf((x + 20.0) / (END + 40.0), 0.0, 1.0) * 44.0 + (layer[2] as float)
			line.append(Vector2(x, rise + 4.0 * sin(x * 0.05 + z) + _rng.randf_range(0.0, 1.5)))
			x += _rng.randf_range(2.0, 5.0)
		line.append(Vector2(END + 200.0, -30.0))
		line.append(Vector2(-140.0, -30.0))
		m.color = tone
		m.torn_sheet(PaperMesh.tear(line, 0.9, 0.2, _rng, false), z, tone.lightened(0.15), 0.08)
		# Cedars standing all over the slope, darker than it, in rows of
		# pointed silhouettes (more of them on the nearer layers).
		var count := 90 if z > -25.0 else 60
		for k in count:
			var cx := _rng.randf_range(-130.0, END + 190.0)
			var ridge := clampf((cx + 20.0) / (END + 40.0), 0.0, 1.0) * 44.0 + (layer[2] as float)
			var cy := ridge - _rng.randf_range(1.0, 30.0)
			var ch := _rng.randf_range(2.5, 6.0) * (1.4 if z > -25.0 else 1.0)
			m.color = tone.darkened(_rng.randf_range(0.38, 0.55))
			m.polygon(PackedVector2Array([Vector2(cx - ch * 0.22, cy), Vector2(cx + ch * 0.22, cy), Vector2(cx, cy + ch)]), z + 0.01)
			m.polygon(PackedVector2Array([Vector2(cx - ch * 0.16, cy + ch * 0.35), Vector2(cx + ch * 0.16, cy + ch * 0.35), Vector2(cx, cy + ch * 1.15)]), z + 0.011)
		# Gate-lines zigzagging up it, small and far.
		var gx := -10.0
		var gy := 0.0
		var side := 1.0
		for k in 60:
			gx += side * 1.6
			gy += 0.6
			if k % 10 == 9:
				side = -side
			var sz := 0.7 if z < -30.0 else 1.0
			m.color = VERMILION.lerp(tone, 0.4 if z < -30.0 else 0.15)
			m.rect(Vector2(gx + 30.0 + k * 1.2, gy + sz * 0.4 + (layer[2] as float) * 0.3), Vector2(sz * 0.9, sz * 0.12), z + 0.02)
		_flat(m)
		var mist := PaperMesh.new(1)
		mist.fade_quad(Vector3(-140.0, -10.0, z + 0.5), Vector3(END + 200.0, -10.0, z + 0.5), Vector3(END + 200.0, 8.0 + (layer[2] as float) * 0.5, z + 0.5),
				Vector3(-140.0, 8.0 + (layer[2] as float) * 0.5, z + 0.5), Color(SKY_LOW, 0.55), Color(SKY_LOW, 0.0))
		add_child(mist.build_veil())


# --- The path ------------------------------------------------------------------------

## Stone paths and stairs up the mountainside, the slope's earth under them
## and behind, moss, fallen red leaves.
func _build_path() -> void:
	for p: Array in PATH:
		var left: float = p[0]
		var right: float = p[1]
		var y0: float = p[2]
		var y1: float = p[3]
		# Solid: a slope (or flat) prism down into the mountain.
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var hull := ConvexPolygonShape3D.new()
		var pts := PackedVector3Array()
		for z: float in [-1.6, 1.6]:
			pts.append(Vector3(left, y0, z))
			pts.append(Vector3(right, y1, z))
			pts.append(Vector3(right, minf(y0, y1) - 12.0, z))
			pts.append(Vector3(left, minf(y0, y1) - 12.0, z))
		hull.points = pts
		shape.shape = hull
		body.add_child(shape)
		# (Kept in the village, always in the physics: a body under a place
		# that rests leaves the physics, and he could fall through on arrival.)
		body.position.x = SHIFT
		village.add_child(body)
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.14
		# The earth of the mountainside, front and top, dark under the trees.
		b.color = Color(0.26, 0.22, 0.2)
		b.extrude(PackedVector2Array([Vector2(left, y0 - 0.25), Vector2(right, y1 - 0.25), Vector2(right, minf(y0, y1) - 14.0), Vector2(left, minf(y0, y1) - 14.0)]), -9.0, 2.6)
		# A retaining wall of dressed stone under the path's front edge, then
		# the dark earth with ferns.
		var wy := minf(y0, y1)
		if y0 == y1:
			MarshKit.masonry(b, Vector3((left + right) * 0.5, wy - 1.0, 2.0), Vector3(right - left, 1.9, 1.2), _rng, STONE.darkened(0.1), false)
		for k in int((right - left) / 1.5):
			var fx := _rng.randf_range(left, right)
			var fy := lerpf(y0, y1, (fx - left) / (right - left)) - _rng.randf_range(2.2, 5.0)
			b.color = Color(0.2, 0.28, 0.18).darkened(_rng.randf_range(0.0, 0.3))
			for f in 5:
				var a := -0.4 + f * 0.2 + _rng.randf_range(-0.05, 0.05)
				var tip := Vector3(fx + sin(a) * 0.7, fy + cos(a) * 0.6, 2.65)
				b.tri(Vector3(fx - 0.03, fy, 2.65), Vector3(fx + 0.03, fy, 2.65), tip, Vector3.BACK)
		# The paving or the steps.
		var stairs := y0 != y1
		var x := left
		while x < right - 0.01:
			var x1 := minf(x + (0.55 if stairs else _rng.randf_range(0.8, 1.3)), right)
			var y := lerpf(y0, y1, ((x + x1) * 0.5 - left) / (right - left))
			b.color = STONE.darkened(_rng.randf_range(0.0, 0.25))
			if stairs:
				b.box(Vector3((x + x1) * 0.5, y - 0.12, -0.2), Vector3(x1 - x, 0.3, 3.4))
			else:
				b.box(Vector3((x + x1) * 0.5, y - 0.04, -0.2), Vector3(x1 - x - 0.03, 0.1, 3.4))
			x = x1
		# Moss along the edges; fallen leaves.
		for k in int((right - left) * 1.2):
			var lx := _rng.randf_range(left, right)
			var ly := lerpf(y0, y1, (lx - left) / (right - left))
			b.color = Color(0.62, 0.28, 0.16).darkened(_rng.randf_range(0.0, 0.3)) if _rng.randf() < 0.6 else Color(0.32, 0.38, 0.24)
			var a := _rng.randf() * TAU
			var c := Vector3(lx, ly + 0.02, _rng.randf_range(-1.8, 1.5))
			b.tri(c, c + Vector3(cos(a), 0.0, sin(a)) * 0.09, c + Vector3(cos(a + 1.2), 0.0, sin(a + 1.2)) * 0.07, Vector3.UP)
		add_child(b.build())


## A wall of dressed stone between terraces, to cling to and climb.
func _climb_wall(x: float, bottom: float, top: float) -> void:
	var wall := _solid(Vector3(x, (bottom + top) * 0.5, 0.0), Vector3(2.0, top - bottom, 3.0))
	wall.set_meta(&"climbable", true)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	MarshKit.masonry(b, Vector3(x, (bottom + top) * 0.5, -0.2), Vector3(2.0, top - bottom, 3.4), _rng, STONE, false)
	add_child(b.build())


## A tunnel of torii over the path: gates close together, each two posts
## (black-footed), a lower tie beam and the top beam with its upturned ends,
## names brushed down the posts; their old paint flaking.
func _tunnel(left: float, right: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	var x := left
	while x <= right:
		var g: float = ground_at(x)
		if is_nan(g):
			x += GATE_STEP
			continue
		var h := 3.6
		var paint := VERMILION.lerp(VERMILION_OLD, _rng.randf()).darkened(_rng.randf_range(0.0, 0.12))
		for z: float in [-1.7, 1.7]:
			b.color = paint
			b.box(Vector3(x, g + h * 0.5, z), Vector3(0.2, h, 0.2))
			b.color = SUMI
			b.box(Vector3(x, g + 0.25, z), Vector3(0.23, 0.5, 0.23))
			# Brushed names down the post (on the side the camera sees).
			if z > 0.0:
				b.color = Color(0.12, 0.08, 0.08)
				var y := g + 0.8
				while y < g + h - 0.6:
					b.box(Vector3(x + 0.105, y, z), Vector3(0.005, _rng.randf_range(0.06, 0.12), 0.08))
					y += _rng.randf_range(0.14, 0.22)
		b.color = paint
		b.box(Vector3(x, g + h - 0.45, 0.0), Vector3(0.16, 0.16, 3.9))
		b.color = SUMI
		b.box(Vector3(x, g + h + 0.05, 0.0), Vector3(0.26, 0.22, 4.4))
		b.color = paint.darkened(0.1)
		b.box(Vector3(x, g + h - 0.12, 0.0), Vector3(0.22, 0.18, 4.1))
		x += GATE_STEP
	add_child(b.build())
	# Under the gates the drizzle is held off: no splashes there; the low sun
	# comes through between them in bars (a warm light along the tunnel).
	var mid := (left + right) * 0.5
	var g2: float = ground_at(mid)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.76, 0.5)
	light.light_energy = 1.2
	light.omni_range = (right - left) * 0.6
	light.position = Vector3(mid, g2 + 3.0, 3.0)
	add_child(light)


## Fox statues with red bibs by the tunnels' mouths, stone lanterns, little
## shrines piled with tiny offering gates.
func _build_offerings() -> void:
	for t: Array in TUNNELS:
		for e: float in [t[0] - 1.2, t[1] + 1.2]:
			var g: float = ground_at(e)
			if is_nan(g):
				continue
			add_child(KitsuneStatue.still(Vector3(e, g, -2.4), -1.0 if e < t[0] else 1.0))
		var mid: float = (t[0] + t[1]) * 0.5 + _rng.randf_range(-4.0, 4.0)
		var gm: float = ground_at(mid)
		if not is_nan(gm):
			var pile := PaperMesh.new(_rng.randi())
			pile.shade_jitter = 0.12
			for k in 14:
				var px: float = mid + _rng.randf_range(-0.8, 0.8)
				var s := _rng.randf_range(0.18, 0.34)
				pile.color = VERMILION.darkened(_rng.randf_range(0.0, 0.3))
				var pz := -2.6 + _rng.randf_range(-0.3, 0.3)
				pile.box(Vector3(px - s * 0.35, gm + s * 0.5, pz), Vector3(0.03, s, 0.03))
				pile.box(Vector3(px + s * 0.35, gm + s * 0.5, pz), Vector3(0.03, s, 0.03))
				pile.box(Vector3(px, gm + s, pz), Vector3(s * 1.0, 0.04, 0.05))
			add_child(pile.build())




## The summit lookout: a prayer wheel, the lift it winds, the stone pillar
## the lift comes up beside, and on top a little roofed pavilion with a
## stone lantern looking out over the gates below (cranes up there).
func _build_lookout() -> void:
	var g := 34.0
	var wheel := PrayerWheel.new()
	wheel.position = Vector3(WHEEL_X, g, -2.2)
	add_child(wheel)
	var lift := GustLift.new()
	lift.wheel = wheel
	lift.rise = LOOKOUT_Y - (g + 0.25)
	lift.position = Vector3(LIFT_X, g + 0.25, 0.0)
	add_child(lift)
	# The pillar, solid above its store chamber; the chamber's door (shut
	# but for the slit under it) and its far wall.
	var above := g + STORE_CEILING
	var pillar := _solid(Vector3((PILLAR.x + PILLAR.y) * 0.5, (above + LOOKOUT_Y) * 0.5, 0.0), Vector3(PILLAR.y - PILLAR.x, LOOKOUT_Y - above, 3.0))
	pillar.set_meta(&"no_climb", true)   # (only the lift goes up)
	var door := _solid(Vector3(STORE_DOOR_X, (g + STORE_SLIT + above) * 0.5, 0.0), Vector3(0.5, above - g - STORE_SLIT, 3.0))
	door.set_meta(&"no_climb", true)
	_solid(Vector3(PILLAR.y - 0.25, g + STORE_CEILING * 0.5, 0.0), Vector3(0.5, STORE_CEILING, 3.0)).set_meta(&"no_climb", true)
	# A lip of stone round the pillar's top, reaching back over the lift.
	var lip_left := LIFT_X + 1.0
	_solid(Vector3((lip_left + PILLAR.x) * 0.5, LOOKOUT_Y - 0.2, 0.0), Vector3(PILLAR.x - lip_left, 0.4, 3.0)).set_meta(&"no_climb", true)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	MarshKit.masonry(b, Vector3((PILLAR.x + PILLAR.y) * 0.5, (above + LOOKOUT_Y) * 0.5, -0.2), Vector3(PILLAR.y - PILLAR.x, LOOKOUT_Y - above, 3.4), _rng, STONE, false)
	MarshKit.masonry(b, Vector3((lip_left + PILLAR.x) * 0.5, LOOKOUT_Y - 0.2, -0.2), Vector3(PILLAR.x - lip_left, 0.4, 3.4), _rng, STONE.lightened(0.05), false)
	# The chamber: open at the front so he is seen inside, its back wall of
	# dark stone, a shelf of old offerings, lit by a small lamp.
	MarshKit.masonry(b, Vector3((PILLAR.x + PILLAR.y) * 0.5, g + STORE_CEILING * 0.5, -1.6), Vector3(PILLAR.y - PILLAR.x, STORE_CEILING, 0.2), _rng, STONE.darkened(0.45), false)
	MarshKit.masonry(b, Vector3(PILLAR.y - 0.25, g + STORE_CEILING * 0.5, -0.2), Vector3(0.5, STORE_CEILING, 3.4), _rng, STONE, false)
	b.color = Color(0.3, 0.22, 0.17)
	b.box(Vector3((STORE_DOOR_X + PILLAR.y) * 0.5, g + 0.8, -1.35), Vector3(2.6, 0.05, 0.4))
	for k in 5:
		b.color = Color(0.86, 0.8, 0.66).darkened(_rng.randf_range(0.0, 0.3))
		b.box(Vector3(STORE_DOOR_X + 0.7 + k * 0.5, g + 0.9, -1.35), Vector3(0.2, 0.16 + _rng.randf() * 0.1, 0.25))
	# The door: heavy boards with iron bands, the slit of dark under it, a
	# vermilion charm strip pasted on.
	b.color = Color(0.28, 0.2, 0.15)
	b.box(Vector3(STORE_DOOR_X, (g + STORE_SLIT + above) * 0.5, 0.0), Vector3(0.36, above - g - STORE_SLIT, 2.9))
	b.color = Color(0.14, 0.14, 0.15)
	for y: float in [0.6, 0.95]:
		b.box(Vector3(STORE_DOOR_X - 0.19, g + y, 0.0), Vector3(0.02, 0.06, 2.9))
	b.color = VERMILION.darkened(0.15)
	b.box(Vector3(STORE_DOOR_X - 0.19, g + 0.75, 0.6), Vector3(0.015, 0.3, 0.09))
	add_child(b.build())
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.72, 0.45)
	lamp.light_energy = 0.8
	lamp.omni_range = 3.0
	lamp.position = Vector3(STORE_DOOR_X + 1.6, g + 1.0, -1.0)
	add_child(lamp)
	# The pavilion: four red posts on the pillar's top, a tiled roof.
	var top := LOOKOUT_Y
	for px: float in [PILLAR.x + 0.3, PILLAR.y - 0.3]:
		for pz: float in [-1.5, 1.2]:
			b.color = VERMILION.darkened(0.1)
			b.box(Vector3(px, top + 1.3, pz), Vector3(0.16, 2.6, 0.16))
			b.color = SUMI
			b.box(Vector3(px, top + 0.15, pz), Vector3(0.2, 0.3, 0.2))
	b.color = VERMILION
	b.box(Vector3((PILLAR.x + PILLAR.y) * 0.5, top + 2.55, -1.5), Vector3(PILLAR.y - PILLAR.x - 0.3, 0.14, 0.12))
	b.box(Vector3((PILLAR.x + PILLAR.y) * 0.5, top + 2.55, 1.2), Vector3(PILLAR.y - PILLAR.x - 0.3, 0.14, 0.12))
	add_child(b.build())
	add_child(Scenery.tiled_roof(_rng, PILLAR.x - 0.3, PILLAR.y + 0.3, Vector2(top + 2.65, 1.9), Vector2(top + 3.5, -0.15), 3))
	add_child(Scenery.tiled_roof(_rng, PILLAR.x - 0.3, PILLAR.y + 0.3, Vector2(top + 2.65, -2.2), Vector2(top + 3.5, -0.15), 3))
	var lantern := MarshKit.stone_lantern(_rng, true, 0.9)
	lantern.position = Vector3(PILLAR.y - 0.5, top, -1.1)
	add_child(lantern)
	# The altar of the Flat Fold: a low lacquered table, two candles, and on
	# it a paper charm folded flat into a thin square, turning slowly.
	var a := PaperMesh.new(_rng.randi())
	a.shade_jitter = 0.08
	a.color = Color(0.3, 0.12, 0.1)
	a.box(Vector3(FOLD_ALTAR_X, top + 0.35, -1.5), Vector3(1.0, 0.7, 0.6))
	a.color = SUMI
	a.box(Vector3(FOLD_ALTAR_X, top + 0.72, -1.5), Vector3(1.1, 0.05, 0.7))
	var flame := PaperMesh.new(3)
	MarshKit.candle(a, flame, Vector3(FOLD_ALTAR_X - 0.38, top + 0.75, -1.4), 0.18)
	MarshKit.candle(a, flame, Vector3(FOLD_ALTAR_X + 0.38, top + 0.75, -1.4), 0.18)
	add_child(a.build())
	add_child(flame.build(Color.WHITE, 1.0, true))
	if "fold" not in SaveGame.abilities:
		_charm = Node3D.new()
		_charm.position = Vector3(FOLD_ALTAR_X, top + 1.25, -1.5)
		add_child(_charm)
		var c := PaperMesh.new(_rng.randi())
		c.texture_world = false
		c.shade_jitter = 0.05
		c.color = PaperMesh.WASHI
		c.quad(Vector3(-0.22, -0.22, 0.0), Vector3(0.22, -0.22, 0.0), Vector3(0.22, 0.22, 0.0), Vector3(-0.22, 0.22, 0.0))
		c.color = PaperMesh.WASHI.darkened(0.12)
		c.tri(Vector3(-0.22, -0.22, 0.01), Vector3(0.22, 0.22, 0.01), Vector3(0.22, -0.22, 0.01), Vector3.BACK)
		c.color = PaperMesh.VERMILION
		c.box(Vector3(0.0, 0.0, 0.015), Vector3(0.12, 0.12, 0.005))
		_charm.add_child(c.build())


func _process(delta: float) -> void:
	# The charm on the lookout's altar turns slowly; coming to it, he learns
	# the Flat Fold.
	if _charm == null or _taught:
		return
	_charm.rotation.y += 0.8 * delta
	_charm.position.y = LOOKOUT_Y + 1.25 + 0.05 * sin(Time.get_ticks_msec() * 0.002)
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	elif absf(_ronin.global_position.x - (SHIFT + FOLD_ALTAR_X)) < 1.0 and absf(_ronin.global_position.y - LOOKOUT_Y) < 0.5 \
			and _ronin.is_on_floor() and _ronin.is_physics_processing():
		learn_fold()


## The Flat Fold, learned: the charm rises, folds thin and flies to him.
func learn_fold() -> void:
	_taught = true
	if _ronin:
		_ronin.has_fold = true
	if "fold" not in SaveGame.abilities:
		SaveGame.abilities.append("fold")
	SaveGame.write()
	Sound.play(self, &"draw_ready", 0.0)
	if _charm and _ronin:
		var to := _ronin.global_position - global_position + Vector3(0.0, 1.0, 0.3)
		var t := create_tween()
		t.tween_property(_charm, "position:y", _charm.position.y + 0.6, 0.5).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(_charm, "scale", Vector3(1.0, 0.05, 1.0), 0.5)
		t.tween_property(_charm, "position", to, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(func() -> void:
			_charm.visible = false
			(_ronin.get_node("Puppet") as RoninPuppet).play_healed())
	var card := AbilityCard.new()
	card.title = "Flat Fold"
	card.prompts = [["S, then L", "Down, then RB", "Fold flat"]]
	card.advice = "Duck, then dash: you fold paper-thin and slide under shut doors and through slits."
	var ronin := _ronin
	card.used = func() -> bool: return is_instance_valid(ronin) and ronin.folding
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud:
		hud.get_parent().add_child(card)


func _build_air() -> void:
	# Red maple leaves falling slowly through the bars of light.
	var leaves := CPUParticles3D.new()
	leaves.amount = 120
	leaves.lifetime = 10.0
	leaves.preprocess = 10.0
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(END * 0.5 + 20.0, 4.0, 4.0)
	leaves.position = Vector3(END * 0.5, 24.0, -1.0)
	leaves.direction = Vector3(-0.3, -1.0, 0.0)
	leaves.spread = 25.0
	leaves.gravity = Vector3(-0.3, -0.5, 0.0)
	leaves.initial_velocity_min = 0.2
	leaves.initial_velocity_max = 0.6
	leaves.angle_max = 360.0
	leaves.angular_velocity_min = -120.0
	leaves.angular_velocity_max = 120.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.07)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.7, 0.3, 0.18)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = look
	leaves.mesh = quad
	leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(leaves)
