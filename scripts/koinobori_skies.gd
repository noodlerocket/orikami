class_name KoinoboriSkies
extends Node3D
## Koinobori Skies (docs/koinobori_skies_plan.md; design.md region 5: "bright
## and windy, giant koi-fish kites drift across the clouds as moving
## platforms"). Past Shimeri's gate: a stair climbs out of the marsh's fog
## and he comes out into wind and daylight on cliffs above a sea of cloud.
## Its own place, far off along x (SHIFT).
##
## The look: a pale washed sky, a white sun behind thin cloud, a sea of
## torn white paper cloud below, snowy peaks far off (Yukiyama); tall poles
## on the cliffs flying faded carp streamers (koinobori) that fill and
## flap in the wind; free carp, cut loose, drifting along the wind between
## the cliffs: the moving platforms (SkyCarp); paper prayer flags, pinwheels.
## Falling off is falling into the cloud: back to the last shrine.
##
## Left to right (local x): the Cloudbreak Stair and shrine 14; the Pole
## Field (cliffs, poles, free carp, rising air at the cliff edges); the
## Kite-Makers' Eyrie (later); the Carp Run; the Wind Shrine; Akane's second
## duel (later).

const SHIFT := 4000.0
const END := 380.0
const ARRIVE_X := 3.0
const WEST_X := -6.0
## Cliff tops along the gameplay plane: [left, right, top]. Between them,
## open sky over the cloud sea.
const CLIFFS := [[-14.0, 22.0, 0.0], [27.0, 36.0, 0.6], [44.0, 52.0, 1.8], [60.0, 74.0, 0.8], [83.0, 90.0, 2.6],
		[98.0, 168.0, 1.6], [176.0, 182.0, 2.2], [196.0, 202.0, 1.0], [218.0, 224.0, 2.8], [240.0, 246.0, 1.6],
		[262.0, 268.0, 3.0], [282.0, 330.0, 1.8], [338.0, 384.0, 2.4]]
## Carp-streamer poles on the cliffs: [x, height].
## (Clear of the paper walls and their guy ropes' stakes, 2.2 m each side.)
const POLES := [[8.0, 11.0], [32.0, 9.0], [48.0, 10.0], [67.0, 12.0], [86.5, 9.0], [104.0, 11.0], [162.5, 10.0],
		[221.0, 9.0], [296.0, 12.0], [350.0, 11.0]]
## Free carp drifting between cliffs: [from x, to x, height, speed].
const CARP := [[22.8, 26.2, 0.9, 1.1], [37.0, 43.0, 1.4, 1.3], [53.0, 59.0, 1.6, 1.2], [75.0, 82.0, 1.8, 1.5],
		[91.0, 97.0, 2.2, 1.4], [169.0, 175.0, 2.0, 1.4], [183.0, 195.0, 1.8, 1.8], [203.0, 217.0, 2.2, 2.0],
		[225.0, 239.0, 2.4, 2.0], [247.0, 261.0, 2.6, 2.1], [269.0, 281.0, 2.6, 1.9], [331.0, 337.0, 2.2, 1.2]]
## Rising air at cliff edges (to glide up): [x, base, height].
const UPDRAFTS := [[40.5, -6.0, 12.0], [79.0, -6.0, 13.0], [210.0, -6.0, 14.0], [254.0, -6.0, 14.0]]
## Shrines: [x, ground, id].
const SHRINES := [[6.0, 0.0, "cloudbreak"], [140.0, 1.6, "eyrie"], [300.0, 1.8, "wind_shrine"]]
## The Eyrie's altar, where the Shuriken Dash is learned (x).
const ALTAR_X := 150.0
## Paper walls across the way (only the Shuriken Dash tears them): [x, ground, id].
const WALLS := [[158.0, 1.6, "skies_wall_eyrie"], [179.0, 2.2, ""], [199.5, 1.0, ""], [243.0, 1.6, ""], [265.0, 3.0, ""], [318.0, 1.8, "skies_wall_shrine"]]
## Kite husks riding the wind over the Carp Run and the Pole Field: [x, y].
const KITES := [[56.0, 5.5], [94.0, 6.0], [188.0, 6.5], [230.0, 7.0], [256.0, 7.5], [275.0, 7.0]]
## Kamaitachi riding the gusts over the Carp Run: [x, y].
const KAMAITACHI := [[200.0, 6.0], [250.0, 6.5], [324.0, 6.0]]
## Cranes: [id, count, x, y].
const CRANES := [["skies_pole", 6, 67.0, 12.6], ["skies_ledge", 6, 87.0, 2.6]]

const SKY_TOP := Color(0.48, 0.6, 0.74)
const SKY_LOW := Color(0.83, 0.86, 0.86)
const CLOUD := Color(0.93, 0.93, 0.92)
const ROCK := Color(0.53, 0.51, 0.48)
const GRASS := Color(0.5, 0.56, 0.38)
## The faded colours of old carp streamers.
const CARP_COLOURS := [Color(0.16, 0.16, 0.2), Color(0.72, 0.3, 0.24), Color(0.32, 0.42, 0.6), Color(0.78, 0.66, 0.36)]

var village: Village
var _rng := RandomNumberGenerator.new()
var _awake := true
var _streamers: Array[Node3D] = []
var _wheels: Array[Node3D] = []


static func in_skies(x: float) -> bool:
	return x > SHIFT - 300.0 and not ThousandGates.in_gates(x)


## The top of the ground under a local x (cliff top), or NAN over open sky.
static func ground_at(x: float) -> float:
	for c: Array in CLIFFS:
		if x >= c[0] and x <= c[1]:
			return c[2]
	return NAN


func _ready() -> void:
	_rng.seed = 6060
	position.x = SHIFT
	_build_sky()
	_build_cloud_sea()
	for c: Array in CLIFFS:
		_cliff(c[0], c[1], c[2])
	_build_stair()
	for p: Array in POLES:
		_pole(p[0], p[1])
	for c: Array in CARP:
		var carp := SkyCarp.new()
		var gap := _gap_round((c[0] + c[1]) * 0.5)
		carp.length = clampf(gap.y - gap.x - 3.2, 2.2, 3.8)
		var half := 0.55 * carp.length + 0.85
		carp.from_x = maxf(c[0], gap.x + half)
		carp.to_x = minf(c[1], gap.y - half)
		if carp.from_x > carp.to_x:
			carp.from_x = (gap.x + gap.y) * 0.5
			carp.to_x = carp.from_x + 0.01
		carp.speed = c[3]
		carp.colour = CARP_COLOURS[_rng.randi() % CARP_COLOURS.size()]
		carp.position = Vector3(carp.from_x, c[2], 0.0)
		add_child(carp)
	for u: Array in UPDRAFTS:
		var up := Updraft.new()
		up.height = u[2]
		up.position = Vector3(u[0], u[1], 0.0)
		add_child(up)
	for s: Array in SHRINES:
		var rest := RestShrine.new()
		rest.shrine_id = s[2]
		rest.position = Vector3(s[0], s[1], -0.9)
		rest.scale = Vector3.ONE * 1.2
		add_child(rest)
	for c: Array in CRANES:
		var bundle := CraneBundle.new()
		bundle.id = c[0]
		bundle.count = c[1]
		bundle.position = Vector3(c[2], c[3], 0.0)
		add_child(bundle)
	_build_eyrie()
	_build_wind_shrine()
	for k: Array in KAMAITACHI:
		var weasel := Kamaitachi.new()
		weasel.position = Vector3(k[0], k[1], 0.0)
		add_child(weasel)
	for k: Array in KITES:
		var kite := KiteHusk.new()
		kite.position = Vector3(k[0], k[1], 0.0)
		add_child(kite)
	for w: Array in WALLS:
		var wall := PaperWall.new()
		wall.id = w[2]
		wall.position = Vector3(w[0], w[1], 0.0)
		add_child(wall)
	_build_bridge_out()
	_build_air()
	for x: float in [10.0, 70.0, 130.0, 190.0, 250.0, 310.0, 365.0]:
		Sound.place_loop(self, "skies_wind.ogg", Vector3(x, 3.0, -3.0), -10.0, 34.0)
	# Akane, waiting in the Kite-Fighters' Ring at the far end.
	duel = AkaneSkies.new()
	duel.skies = self
	add_child(duel)
	_solid(Vector3(WEST_X - 9.0, 12.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)
	_solid(Vector3(END + 1.0, 12.0, 0.0), Vector3(1.0, 40.0, 4.0)).set_meta(&"no_climb", true)


var duel: AkaneSkies
var _shuriken: Node3D
var _taught := false
var _ronin: Ronin


## The open sky between the cliffs round a local x: [right edge of the
## cliff before, left edge of the cliff after].
func _gap_round(x: float) -> Vector2:
	var lo := -INF
	var hi := INF
	for c: Array in CLIFFS:
		if c[1] <= x:
			lo = maxf(lo, c[1])
		if c[0] >= x:
			hi = minf(hi, c[0])
	return Vector2(lo, hi)


func set_awake(on: bool) -> void:
	if on == _awake:
		return
	_awake = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	# The streamers fill and flap in the wind, a wave running down each.
	for s: Node3D in _streamers:
		var gust := 0.7 + 0.3 * sin(t * 0.6 + s.position.x * 0.1)
		var segs: Array = s.get_meta(&"segs")
		for i in segs.size():
			var seg: Node3D = segs[i]
			var k := float(i + 1) / segs.size()
			seg.rotation.z = (0.18 * sin(t * 4.0 - i * 0.9 + s.position.x) * k) * gust
			seg.rotation.x = 0.12 * sin(t * 3.1 - i * 0.7) * k
		s.rotation.z = lerpf(1.1, 0.2, gust)   # (hanging downwind; a stronger wind holds it out level)
	for w: Node3D in _wheels:
		w.rotation.z -= 6.0 * get_process_delta_time()
	# The great folded shuriken on the altar turns slowly; coming to it, he
	# learns the fold.
	if _shuriken and not _taught:
		_shuriken.rotation.z += 0.6 * get_process_delta_time()
		if _ronin == null:
			_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		elif absf(_ronin.global_position.x - (SHIFT + ALTAR_X)) < 1.3 and _ronin.is_on_floor() and _ronin.is_physics_processing():
			learn_shuriken()


func _solid(center: Vector3, size: Vector3) -> StaticBody3D:
	return village._add_solid(center + Vector3(SHIFT, 0.0, 0.0), size)


func _flat(b: PaperMesh) -> MeshInstance3D:
	var mesh := b.build(Color.WHITE, 0.0, true)
	(mesh.material_override as StandardMaterial3D).disable_fog = true
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


# --- The sky and the cloud sea ----------------------------------------------------

func _build_sky() -> void:
	var left := -140.0
	var right := END + 320.0
	var sky := PaperMesh.new(1)
	sky.shade_jitter = 0.0
	sky.fade_quad(Vector3(left, 110.0, -53.0), Vector3(right, 110.0, -53.0), Vector3(right, 8.0, -53.0), Vector3(left, 8.0, -53.0), SKY_TOP, SKY_LOW)
	sky.fade_quad(Vector3(left, 8.0, -53.0), Vector3(right, 8.0, -53.0), Vector3(right, -40.0, -53.0), Vector3(left, -40.0, -53.0), SKY_LOW, CLOUD)
	_flat(sky)
	# The sun: a white disc behind thin cloud, its glow.
	var sun := PaperMesh.new(1)
	sun.color = Color(0.98, 0.97, 0.92)
	sun.ellipse(Vector2(150.0, 30.0), Vector2(3.4, 3.4), 32, -52.0)
	_flat(sun)
	var glow := PaperMesh.new(1)
	for k in 32:
		var a0 := TAU * k / 32.0
		var a1 := TAU * (k + 1) / 32.0
		var at := Vector3(150.0, 30.0, -52.2)
		glow.fade_quad(at + Vector3(cos(a0), sin(a0), 0.0) * 3.2, at + Vector3(cos(a1), sin(a1), 0.0) * 3.2,
				at + Vector3(cos(a1), sin(a1), 0.0) * 22.0, at + Vector3(cos(a0), sin(a0), 0.0) * 22.0,
				Color(1.0, 0.98, 0.9, 0.45), Color(1.0, 0.98, 0.9, 0.0))
	add_child(glow.build_veil(true))
	# Thin high cloud, torn paper, drifting across the sun.
	for k in 14:
		var c := PaperMesh.new(_rng.randi())
		c.shade_jitter = 0.0
		var mid := Vector2(_rng.randf_range(left, right), _rng.randf_range(18.0, 40.0))
		var w := _rng.randf_range(20.0, 50.0)
		var h := _rng.randf_range(1.5, 4.0)
		var outline := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			outline.append(mid + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.5))
		c.color = Color(0.92, 0.93, 0.94, 1.0)
		c.torn_sheet(PaperMesh.tear(outline, 0.9, 0.16, _rng), -50.0 + k * 0.05, Color(1.0, 1.0, 1.0), 0.06)
		_flat(c)
	# Far snowy peaks standing out of the cloud (Yukiyama, later).
	var peaks := PaperMesh.new(_rng.randi())
	peaks.shade_jitter = 0.0
	var x := left
	while x < right:
		var w := _rng.randf_range(16.0, 30.0)
		var h := _rng.randf_range(6.0, 13.0)
		var top := Vector2(x + w * 0.5 + _rng.randf_range(-3.0, 3.0), h)
		# The lit face and the shadowed face, then snow on the top.
		peaks.color = Color(0.72, 0.77, 0.84)
		peaks.polygon(PackedVector2Array([Vector2(x, -6.0), top, Vector2(top.x, -6.0)]), -46.0)
		peaks.color = Color(0.6, 0.66, 0.75)
		peaks.polygon(PackedVector2Array([Vector2(top.x, -6.0), top, Vector2(x + w, -6.0)]), -46.0)
		peaks.color = Color(0.95, 0.96, 0.97)
		peaks.polygon(PackedVector2Array([top + Vector2(-w * 0.15, -h * 0.3), top + Vector2(-w * 0.05, -h * 0.22), top, top + Vector2(w * 0.04, -h * 0.25),
				top + Vector2(w * 0.12, -h * 0.34), top + Vector2(0.0, -h * 0.18)]), -45.98)
		x += w * _rng.randf_range(0.7, 1.4)
	_flat(peaks)
	# Far east, beyond the ring: a steep mountain climbed by rows of
	# vermilion torii, the Thousand Gates (where Akane sends him next).
	var gates := PaperMesh.new(_rng.randi())
	gates.shade_jitter = 0.0
	var mx := END - 2.0
	gates.color = Color(0.56, 0.6, 0.66)
	gates.polygon(PackedVector2Array([Vector2(mx - 40.0, -6.0), Vector2(mx - 6.0, 30.0), Vector2(mx + 4.0, 33.0), Vector2(mx + 36.0, -6.0)]), -44.0)
	for k in 40:
		var t := float(k) / 40.0
		var gx := lerpf(mx - 34.0, mx - 3.0, t) + sin(t * 18.0) * 2.5
		var gy := lerpf(-3.0, 30.0, t)
		var sz := lerpf(1.2, 0.5, t)
		gates.color = Color(0.66, 0.3, 0.24).lerp(Color(0.6, 0.6, 0.66), t * 0.7)
		gates.rect(Vector2(gx - sz * 0.35, gy + sz * 0.4), Vector2(sz * 0.08, sz * 0.8), -43.9)
		gates.rect(Vector2(gx + sz * 0.35, gy + sz * 0.4), Vector2(sz * 0.08, sz * 0.8), -43.9)
		gates.rect(Vector2(gx, gy + sz * 0.85), Vector2(sz * 1.0, sz * 0.1), -43.9)
	_flat(gates)
	var mist := PaperMesh.new(1)
	mist.fade_quad(Vector3(left, -6.0, -45.5), Vector3(right, -6.0, -45.5), Vector3(right, 4.0, -45.5), Vector3(left, 4.0, -45.5), Color(SKY_LOW, 0.9), Color(SKY_LOW, 0.0))
	add_child(mist.build_veil())


## The sea of cloud below: layer on layer of torn white paper, nearer ones
## brighter, drifting slowly.
func _build_cloud_sea() -> void:
	for layer: Array in [[-40.0, -7.0, 0.8], [-26.0, -8.0, 0.86], [-14.0, -6.5, 0.92], [-6.0, -5.0, 0.95], [3.6, -5.0, 0.98], [6.0, -4.8, 1.0]]:
		var c := PaperMesh.new(_rng.randi())
		c.shade_jitter = 0.0
		var z: float = layer[0]
		var y: float = layer[1]
		var line := PackedVector2Array()
		var x := -140.0
		while x < END + 320.0:
			line.append(Vector2(x, y + _rng.randf_range(0.0, 2.5) + 1.2 * sin(x * 0.07 + z)))
			x += _rng.randf_range(2.0, 5.0)
		line.append(Vector2(END + 320.0, -40.0))
		line.append(Vector2(-140.0, -40.0))
		var tone := CLOUD * (layer[2] as float)
		tone.a = 1.0
		c.color = tone
		c.torn_sheet(PaperMesh.tear(line, 0.8, 0.14, _rng, false), z, Color(1.0, 1.0, 1.0), 0.08)
		_flat(c)


# --- The cliffs ---------------------------------------------------------------------

## A cliff top standing out of the cloud: its rock face faceted and ochre-
## grey, grass and small flowers on its top, roots hanging off its edges.
func _cliff(left: float, right: float, top: float) -> void:
	_solid(Vector3((left + right) * 0.5, top - 8.0, 0.0), Vector3(right - left, 16.0, 4.0))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.16
	# The face: a column of rock narrowing downward into the cloud, faceted.
	var rows := 6
	for r in rows:
		var y0 := top - r * 2.4
		var y1 := y0 - 2.4
		var inset0 := r * 0.35
		var inset1 := (r + 1) * 0.35
		b.color = ROCK.darkened(_rng.randf_range(0.0, 0.25) + r * 0.04)
		b.extrude(PackedVector2Array([Vector2(left + inset1 + _rng.randf_range(-0.2, 0.2), y1), Vector2(right - inset1 + _rng.randf_range(-0.2, 0.2), y1),
				Vector2(right - inset0, y0), Vector2(left + inset0, y0)]), -7.5 + r * 0.3, 3.0 - r * 0.3)
		b.color = ROCK.darkened(0.3)
		b.box(Vector3((left + right) * 0.5, y0 - 0.05, 3.02 - r * 0.3), Vector3(right - left - inset0 * 2.0, 0.07, 0.02))
		# A paler band of stone through the middle of each course, and moss
		# streaks running down from the turf.
		b.color = ROCK.lightened(0.14)
		b.box(Vector3((left + right) * 0.5, y0 - 1.1, 3.015 - r * 0.3), Vector3(right - left - inset0 * 2.0 - 0.2, 0.5, 0.01))
		if r == 0:
			for k in int((right - left) / 1.6):
				b.color = GRASS.darkened(0.35)
				var mx := _rng.randf_range(left + 0.3, right - 0.3)
				var ml := _rng.randf_range(0.4, 1.6)
				var mw := _rng.randf_range(0.12, 0.35)
				var tip := mx + _rng.randf_range(-0.1, 0.1)
				b.quad(Vector3(mx - mw, top, 3.025), Vector3(mx + mw, top, 3.025), Vector3(tip + 0.02, top - ml, 3.025), Vector3(tip - 0.02, top - ml, 3.025), Vector3.BACK)
		# Cracks running down the face: jagged, widest where they open, closing
		# to nothing (straight strips read as rods hung on the rock).
		for k in int((right - left) / 3.0):
			b.color = ROCK.darkened(0.4)
			var cx := _rng.randf_range(left + inset0 + 0.5, right - inset0 - 0.5)
			var cy := y0 - _rng.randf_range(0.1, 0.6)
			var length := _rng.randf_range(0.9, 2.0)
			var spine: Array[Vector2] = []
			var steps := 5
			for i in steps + 1:
				var t := float(i) / steps
				spine.append(Vector2(cx + (_rng.randf_range(-0.18, 0.18) if i > 0 else 0.0), cy - length * t))
			var pts := PackedVector2Array()
			for i in spine.size():
				var w := 0.07 * (1.0 - float(i) / steps) + 0.006
				pts.append(spine[i] + Vector2(w, 0.0))
			for i in range(spine.size() - 1, -1, -1):
				var w := 0.07 * (1.0 - float(i) / steps) + 0.006
				pts.append(spine[i] - Vector2(w, 0.0))
			b.polygon(pts, 3.03 - r * 0.3)
		for k in int((right - left) / 0.5):
			b.color = ROCK.darkened(_rng.randf_range(-0.15, 0.35))
			var fx := _rng.randf_range(left + inset0 + 0.3, right - inset0 - 0.3)
			var fy := _rng.randf_range(y1 + 0.3, y0 - 0.3)
			b.tri(Vector3(fx, fy, 3.02 - r * 0.3), Vector3(fx + _rng.randf_range(0.4, 1.0), fy + _rng.randf_range(-0.3, 0.5), 3.02 - r * 0.3),
					Vector3(fx + _rng.randf_range(-0.3, 0.6), fy + _rng.randf_range(0.4, 1.0), 3.02 - r * 0.3), Vector3.BACK)
	# The grass on top, a lip of turf over the edge.
	b.color = GRASS
	b.box(Vector3((left + right) * 0.5, top + 0.02, -2.25), Vector3(right - left + 0.2, 0.06, 10.5))
	b.color = GRASS.darkened(0.25)
	for e: float in [left, right]:
		b.box(Vector3(e, top - 0.12, -2.25), Vector3(0.3, 0.3, 10.5))
	var mesh := b.build()
	add_child(mesh)
	# Tufts of grass and wild flowers, bending in the wind.
	var x := left + 0.4
	while x < right - 0.4:
		var tuft := MarshKit.reeds(_rng, _rng.randf_range(0.3, 0.6), _rng.randf_range(0.25, 0.45), 0.2, GRASS.darkened(0.1), true)
		tuft.position = Vector3(x, top, _rng.randf_range(-6.5, -1.8) if _rng.randf() < 0.6 else _rng.randf_range(1.6, 2.8))
		add_child(tuft)
		Scenery.windswept(tuft, -0.05, _rng)
		x += _rng.randf_range(0.8, 1.8)


## The way in: a stair of wet stone up out of the marsh's fog (at the west
## end, rising east to the first cliff top).
func _build_stair() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	for i in 14:
		var x0 := -14.0 + i * 1.1
		b.color = Color(0.5, 0.5, 0.52).darkened(_rng.randf_range(0.0, 0.2))
		b.box(Vector3(x0 + 0.5, 0.03, -0.2 + _rng.randf_range(-0.1, 0.1)), Vector3(0.95, 0.06, 1.6))
	add_child(b.build())
	# A torii at the cliff top, faded, with paper streamers.
	var torii := Scenery.torii(_rng, Color(0.56, 0.26, 0.2))
	torii.position = Vector3(1.5, 0.0, -2.8)
	add_child(torii)


# --- The poles and their streamers -------------------------------------------------

## A tall pole with a wind-wheel (yaguruma) at its top and a pennant, and
## carp streamers flying from it, largest first: black, red, blue.
func _pole(x: float, height: float) -> void:
	var g: float = ground_at(x)
	if is_nan(g):
		g = 0.0
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	b.color = Color(0.36, 0.3, 0.24)
	b.frustum(8, Vector2(0.12, 0.12), Vector2(0.08, 0.08), height, Vector3(x, g, -1.6))
	# Guy ropes down to stakes.
	b.color = Color(0.6, 0.56, 0.46)
	for side: float in [-1.0, 1.0]:
		MarshKit.limb(b, Vector3(x, g + height * 0.8, -1.6), Vector3(x + side * 2.2, g, -1.6 + side * 0.4), 0.012, 0.012, 4)
		b.color = Color(0.3, 0.25, 0.2)
		b.box(Vector3(x + side * 2.2, g + 0.1, -1.6 + side * 0.4), Vector3(0.08, 0.2, 0.08))
		b.color = Color(0.6, 0.56, 0.46)
	add_child(b.build())
	# The wind-wheel: spokes and arrows, spinning.
	var wheel := Node3D.new()
	wheel.position = Vector3(x, g + height + 0.2, -1.45)
	add_child(wheel)
	var w := PaperMesh.new(_rng.randi())
	for k in 8:
		var a := TAU * k / 8.0
		w.color = [Color(0.72, 0.3, 0.24), Color(0.85, 0.82, 0.74)][k % 2]
		w.tri(Vector3.ZERO, Vector3(cos(a), sin(a), 0.0) * 0.55, Vector3(cos(a + 0.5), sin(a + 0.5), 0.0) * 0.45, Vector3.BACK)
	wheel.add_child(w.build())
	_wheels.append(wheel)
	# The streamers, hung from the top downwind (left).
	for k in 3:
		var root := Node3D.new()
		root.position = Vector3(x - 0.1, g + height - 0.6 - k * 1.7, -1.6)
		add_child(root)
		var segs: Array = []
		var length := 3.4 - k * 0.6
		var colour: Color = CARP_COLOURS[k % 3]
		var parent: Node3D = root
		var n := 6
		for i in n:
			var seg := Node3D.new()
			seg.position = Vector3(-length / n if i > 0 else 0.0, 0.0, 0.0)
			parent.add_child(seg)
			var t := float(i) / n
			var r0 := lerpf(0.42, 0.3, t) * (1.0 - k * 0.15)
			var r1 := lerpf(0.42, 0.3, t + 1.0 / n) * (1.0 - k * 0.15)
			var p := PaperMesh.new(_rng.randi())
			p.texture_world = false
			p.shade_jitter = 0.1
			p.color = colour.darkened(_rng.randf_range(0.0, 0.1))
			p.loft([PaperCritter.ring_x(Vector3(0.0, 0.0, 0.0), Vector2(r0, r0 * 0.8), 8), PaperCritter.ring_x(Vector3(-length / n, 0.0, 0.0), Vector2(r1, r1 * 0.8), 8)], false, false)
			# Scales painted on: pale arcs.
			p.color = colour.lightened(0.25)
			for s in 2:
				p.box(Vector3(-length / n * (0.3 + s * 0.4), r0 * 0.6, r0 * 0.55), Vector3(0.1, 0.03, 0.02))
			if i == 0:
				# The mouth ring and the eye.
				p.color = Color(0.9, 0.88, 0.82)
				p.frustum(10, Vector2(r0 * 1.02, r0 * 0.82), Vector2(r0 * 1.02, r0 * 0.82), 0.06, Vector3(0.0, 0.0, 0.0))
				p.color = Color(0.95, 0.94, 0.9)
				p.ellipse(Vector2(-0.2, r0 * 0.25), Vector2(0.09, 0.09), 10, r0 * 0.82)
				p.color = Color(0.05, 0.05, 0.06)
				p.ellipse(Vector2(-0.2, r0 * 0.25), Vector2(0.045, 0.045), 8, r0 * 0.83)
			if i == n - 1:
				p.color = colour.darkened(0.1)
				p.polygon(PackedVector2Array([Vector2(-length / n, 0.0), Vector2(-length / n - 0.6, r1 * 1.2), Vector2(-length / n - 0.4, 0.0), Vector2(-length / n - 0.6, -r1 * 1.2)]), 0.0)
			var m := p.build()
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			seg.add_child(m)
			segs.append(seg)
			parent = seg
		root.set_meta(&"segs", segs)
		_streamers.append(root)


# --- The Kite-Makers' Eyrie --------------------------------------------------------

## Workshops built into the cliff: a long open-fronted timber hall at the
## back, giant kite frames leaning in it (paper half-stretched, faded faces
## painted on them), rolls of paper on a bench, a winch with its rope going
## off over the edge; the altar where a great folded shuriken waits
## (learn_shuriken).
func _build_eyrie() -> void:
	var g := 1.6
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	for x: float in [112.0, 118.0, 124.0, 130.0, 136.0, 142.0, 148.0, 154.0]:
		b.color = Color(0.4, 0.33, 0.26)
		b.box(Vector3(x, g + 2.4, -3.0), Vector3(0.22, 4.8, 0.22))
	b.color = Color(0.48, 0.42, 0.36)
	b.box(Vector3(133.0, g + 2.4, -5.8), Vector3(43.0, 4.8, 0.2))
	b.color = Color(0.36, 0.3, 0.24)
	for y: float in [g + 1.2, g + 2.4, g + 3.6]:
		b.box(Vector3(133.0, y, -5.68), Vector3(43.0, 0.06, 0.04))
	for sx: float in [111.5, 154.5]:
		b.color = Color(0.44, 0.38, 0.32)
		b.box(Vector3(sx, g + 2.4, -4.4), Vector3(0.2, 4.8, 2.8))
	add_child(b.build())
	add_child(Scenery.tiled_roof(_rng, 110.5, 155.5, Vector2(g + 4.8, -2.4), Vector2(g + 6.6, -6.2), 5))
	for k: Array in [[115.0, -4.6, 2.6, 0], [121.5, -4.8, 2.2, 1], [127.5, -4.7, 2.8, 2], [146.0, -4.8, 2.4, 3]]:
		var kite := _kite_frame(k[2], k[3])
		kite.position = Vector3(k[0], g + k[2] * 0.62 + 0.15, k[1])
		kite.rotation.z = _rng.randf_range(-0.12, 0.12)
		add_child(kite)
	var r := PaperMesh.new(_rng.randi())
	r.shade_jitter = 0.1
	r.color = Color(0.42, 0.34, 0.26)
	r.box(Vector3(133.5, g + 0.45, -3.8), Vector3(4.0, 0.08, 1.0))
	for lx: float in [131.8, 135.2]:
		r.box(Vector3(lx, g + 0.22, -3.8), Vector3(0.1, 0.44, 0.9))
	for k in 6:
		r.color = Color(0.9, 0.87, 0.8).darkened(_rng.randf_range(0.0, 0.12))
		r.frustum(10, Vector2(0.12, 0.12), Vector2(0.12, 0.12), 0.8, Vector3(132.0 + k * 0.5, g + 0.49, -3.8))
	# The winch: two posts with a sill and a cross beam, a drum lying across
	# them wound with rope, a crank on the near side; the rope runs off the
	# drum's top over the cliff's edge, down into the cloud.
	var wx := 166.4
	var wy := g + 0.85
	for wz: float in [-2.4, -0.9]:
		r.color = Color(0.36, 0.28, 0.2).darkened(0.1)
		r.box(Vector3(wx, g + 0.6, wz), Vector3(0.16, 1.2, 0.16))
		r.box(Vector3(wx, g + 0.06, wz), Vector3(1.0, 0.12, 0.2))
		# A brace from the sill up to the post.
		r.quad(Vector3(wx - 0.45, g + 0.12, wz + 0.05), Vector3(wx - 0.37, g + 0.12, wz + 0.05), Vector3(wx - 0.04, g + 0.62, wz + 0.05), Vector3(wx - 0.1, g + 0.62, wz + 0.05), Vector3.BACK)
	r.color = Color(0.36, 0.28, 0.2)
	r.box(Vector3(wx, g + 1.24, -1.65), Vector3(0.14, 0.12, 1.7))
	var drum := PackedVector2Array()
	var rope_ring := PackedVector2Array()
	for i in 10:
		var ang := TAU * i / 10.0
		drum.append(Vector2(wx + cos(ang) * 0.26, wy + sin(ang) * 0.26))
		rope_ring.append(Vector2(wx + cos(ang) * 0.3, wy + sin(ang) * 0.3))
	r.color = Color(0.42, 0.33, 0.23)
	r.extrude(drum, -2.3, -1.0)
	r.color = Color(0.62, 0.56, 0.44)
	for k in 5:
		r.extrude(rope_ring, -2.1 + k * 0.23, -1.96 + k * 0.23)
	# The crank: an arm off the drum's axle, a handle.
	r.color = Color(0.2, 0.18, 0.17)
	r.box(Vector3(wx, wy, -0.78), Vector3(0.08, 0.08, 0.16))
	r.box(Vector3(wx + 0.14, wy + 0.14, -0.7), Vector3(0.36, 0.07, 0.05))
	r.box(Vector3(wx + 0.28, wy + 0.28, -0.6), Vector3(0.05, 0.05, 0.24))
	r.color = Color(0.6, 0.55, 0.44)
	MarshKit.limb(r, Vector3(wx + 0.05, wy + 0.3, -1.6), Vector3(168.0, g + 0.02, -1.6), 0.02, 0.02, 3)
	MarshKit.limb(r, Vector3(168.0, g + 0.02, -1.6), Vector3(168.3, g - 4.0, -1.6), 0.02, 0.02, 4)
	add_child(r.build())
	var a := PaperMesh.new(_rng.randi())
	a.shade_jitter = 0.08
	a.color = Color(0.3, 0.12, 0.1)
	a.box(Vector3(ALTAR_X, g + 0.5, -1.6), Vector3(1.2, 1.0, 0.8))
	a.color = Color(0.2, 0.16, 0.14)
	a.box(Vector3(ALTAR_X, g + 1.03, -1.6), Vector3(1.35, 0.06, 0.95))
	var flame := PaperMesh.new(2)
	MarshKit.candle(a, flame, Vector3(ALTAR_X - 0.45, g + 1.06, -1.4), 0.2)
	MarshKit.candle(a, flame, Vector3(ALTAR_X + 0.45, g + 1.06, -1.4), 0.2)
	add_child(a.build())
	add_child(flame.build(Color.WHITE, 2.0, true))
	_shuriken = Node3D.new()
	_shuriken.position = Vector3(ALTAR_X, g + 1.75, -1.55)
	add_child(_shuriken)
	var sh := PaperMesh.new(_rng.randi())
	sh.texture_world = false
	for k in 4:
		var ang := TAU * k / 4.0
		var tip := Vector3(cos(ang), sin(ang), 0.0) * 0.55
		var side := Vector3(cos(ang + PI * 0.5), sin(ang + PI * 0.5), 0.0) * 0.16
		sh.color = Color(0.86, 0.84, 0.8) if k % 2 == 0 else Color(0.32, 0.36, 0.5)
		sh.tri(Vector3(0.0, 0.0, 0.02), side, tip, Vector3.BACK)
		sh.color = sh.color.darkened(0.2)
		sh.tri(Vector3(0.0, 0.0, 0.02), tip, -side * 0.2 + tip * 0.3, Vector3.BACK)
	sh.color = Color(0.66, 0.24, 0.18)
	sh.ellipse(Vector2.ZERO, Vector2(0.07, 0.07), 10, 0.03)
	_shuriken.add_child(sh.build(Color.WHITE, 0.15))
	if "shuriken" in SaveGame.abilities:
		_taught = true
		_shuriken.visible = false


## The Wind Shrine: a small hall on the last broad cliff before the ring,
## its eaves hung with wind-bells (furin) that swing and ring, a bell rope,
## great paper streamers, pinwheels planted along its fence (the Fan Gust
## sets them whirring), and ropes from the cliff's edges down into the
## cloud, as though the whole rock were tethered there.
func _build_wind_shrine() -> void:
	var g := 1.8
	var hx := 304.0
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = Color(0.5, 0.5, 0.5)
	b.box(Vector3(hx, g + 0.25, -4.4), Vector3(7.6, 0.5, 4.0))
	for px: float in [hx - 3.4, hx - 1.1, hx + 1.1, hx + 3.4]:
		b.color = Color(0.56, 0.24, 0.18)
		b.box(Vector3(px, g + 2.3, -2.7), Vector3(0.2, 3.6, 0.2))
	b.color = Color(0.82, 0.78, 0.7)
	b.box(Vector3(hx, g + 2.1, -5.9), Vector3(7.0, 3.2, 0.15))
	b.color = Color(0.3, 0.26, 0.22)
	b.box(Vector3(hx, g + 4.1, -2.7), Vector3(7.4, 0.25, 0.3))
	for sx: float in [hx - 3.45, hx + 3.45]:
		b.color = Color(0.78, 0.74, 0.66)
		b.box(Vector3(sx, g + 2.1, -4.3), Vector3(0.15, 3.2, 3.2))
	# The bell, its rope of red and white.
	b.color = Color(0.62, 0.52, 0.3)
	b.frustum(12, Vector2(0.24, 0.24), Vector2(0.16, 0.16), 0.36, Vector3(hx, g + 3.5, -2.7))
	b.color = Color(0.8, 0.76, 0.68)
	b.box(Vector3(hx, g + 2.2, -2.62), Vector3(0.07, 2.4, 0.07))
	b.color = Color(0.62, 0.24, 0.18)
	for k in 6:
		b.box(Vector3(hx, g + 1.2 + k * 0.4, -2.6), Vector3(0.08, 0.14, 0.08))
	add_child(b.build())
	add_child(Scenery.tiled_roof(_rng, hx - 4.2, hx + 4.2, Vector2(g + 4.2, -1.9), Vector2(g + 5.8, -4.4), 4))
	add_child(Scenery.tiled_roof(_rng, hx - 4.2, hx + 4.2, Vector2(g + 4.2, -6.9), Vector2(g + 5.8, -4.4), 4))
	# Wind-bells along the eave, each with its paper tongue, swinging.
	var x := hx - 3.0
	while x <= hx + 3.0:
		var bell := Node3D.new()
		bell.position = Vector3(x, g + 4.0, -2.4)
		add_child(bell)
		var f := PaperMesh.new(_rng.randi())
		f.texture_world = false
		f.color = Color(0.8, 0.84, 0.86)
		f.frustum(10, Vector2(0.1, 0.1), Vector2(0.04, 0.04), 0.14, Vector3(0.0, -0.2, 0.0))
		f.color = Color(0.5, 0.48, 0.44)
		f.box(Vector3(0.0, -0.08, 0.0), Vector3(0.008, 0.16, 0.008))
		f.box(Vector3(0.0, -0.32, 0.0), Vector3(0.008, 0.2, 0.008))
		f.color = [Color(0.62, 0.24, 0.18), Color(0.3, 0.36, 0.52), Color(0.86, 0.82, 0.72)][int(x) % 3]
		f.rect(Vector2(0.0, -0.54), Vector2(0.08, 0.24), 0.0)
		bell.add_child(f.build())
		Scenery.windswept(bell, 0.08, _rng)
		x += 1.5
	# Pinwheels along the fence in front.
	x = 286.0
	while x < 296.0:
		var wheel := Pinwheel.new()
		wheel.position = Vector3(x, g, -1.9)
		add_child(wheel)
		x += 1.6
	# Ropes from the cliff's edges down into the cloud.
	var r := PaperMesh.new(_rng.randi())
	r.color = Color(0.6, 0.55, 0.44)
	for e: Array in [[282.3, -1.0], [282.3, 1.5], [329.7, -1.0], [329.7, 1.5]]:
		MarshKit.limb(r, Vector3(e[0], g - 0.2, e[1]), Vector3(e[0] + (-6.0 if e[0] < 300.0 else 6.0), g - 14.0, e[1] - 3.0), 0.04, 0.04, 5)
	add_child(r.build())


## Off the ring's east edge: a rope bridge going away into the haze, toward
## the mountain of gates (walking onto it fades to the Thousand Gates, once
## Akane has yielded here).
func _build_bridge_out() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	var x := 384.0
	var k := 0
	while x < 404.0:
		var sag := 0.6 * sin(clampf((x - 384.0) / 20.0, 0.0, 1.0) * PI)
		b.color = Color(0.46, 0.38, 0.28).darkened(_rng.randf_range(0.0, 0.2))
		b.box(Vector3(x, 2.35 - sag, 0.0), Vector3(0.3, 0.06, 1.4 - (k % 2) * 0.1))
		x += 0.42
		k += 1
	b.color = Color(0.62, 0.56, 0.44)
	for z: float in [-0.75, 0.75]:
		for i in 10:
			var x0 := 384.0 + i * 2.0
			var x1 := x0 + 2.0
			var s0 := 0.6 * sin(clampf((x0 - 384.0) / 20.0, 0.0, 1.0) * PI)
			var s1 := 0.6 * sin(clampf((x1 - 384.0) / 20.0, 0.0, 1.0) * PI)
			MarshKit.limb(b, Vector3(x0, 3.3 - s0, z), Vector3(x1, 3.3 - s1, z), 0.02, 0.02, 4)
	b.color = Color(0.36, 0.28, 0.22)
	for z: float in [-0.8, 0.8]:
		b.box(Vector3(383.8, 2.9, z), Vector3(0.16, 1.2, 0.16))
	add_child(b.build())


## A giant kite on its bamboo frame, paper half-stretched, a faded face
## painted on it, a torn corner.
func _kite_frame(size: float, kind: int) -> Node3D:
	var root := Node3D.new()
	var f := PaperMesh.new(_rng.randi())
	f.texture_world = false
	f.shade_jitter = 0.1
	var pts := PackedVector2Array()
	var sides := 6 if kind % 2 == 0 else 4
	for i in sides:
		var a := TAU * i / sides + (PI / sides if sides == 4 else 0.0)
		pts.append(Vector2(cos(a) * size * 0.5, sin(a) * size * 0.62))
	f.color = Color(0.86, 0.8, 0.68)
	f.polygon(pts, 0.0)
	f.color = [Color(0.62, 0.26, 0.2), Color(0.28, 0.34, 0.48), Color(0.2, 0.2, 0.22), Color(0.66, 0.54, 0.3)][kind % 4]
	f.ellipse(Vector2(0.0, size * 0.08), Vector2(size * 0.22, size * 0.26), 14, 0.01)
	f.color = Color(0.12, 0.1, 0.1)
	for side: float in [-1.0, 1.0]:
		f.stroke(Vector2(side * size * 0.06, size * 0.14), Vector2(side * size * 0.16, size * 0.18), 0.05, 0.02, 0.02)
	f.color = Color(0.55, 0.48, 0.3)
	for i in sides:
		f.stroke(pts[i], pts[(i + 1) % sides], 0.05, 0.05, 0.03)
	f.stroke(pts[0], pts[sides / 2], 0.04, 0.04, 0.03)
	f.color = Color(0.36, 0.42, 0.52)
	f.polygon(PackedVector2Array([pts[1], pts[1] * 0.6 + Vector2(0.1, -0.1), pts[1] * 0.7 + Vector2(-0.2, 0.0)]), 0.015)
	root.add_child(f.build())
	return root


## The Shuriken Dash is his: the great shuriken lifts off the altar, spins
## and flies to him (SaveGame ability "shuriken", an AbilityCard).
func learn_shuriken() -> void:
	_taught = true
	if _ronin:
		_ronin.has_shuriken = true
	if "shuriken" not in SaveGame.abilities:
		SaveGame.abilities.append("shuriken")
	SaveGame.write()
	Sound.play(self, &"draw_ready", 0.0)
	if _shuriken and _ronin:
		var to := _ronin.global_position - global_position + Vector3(0.0, 1.0, 0.3)
		var t := create_tween()
		t.tween_property(_shuriken, "position:y", _shuriken.position.y + 0.8, 0.5).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(_shuriken, "rotation:z", _shuriken.rotation.z + TAU * 2.0, 0.5)
		t.tween_property(_shuriken, "position", to, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(_shuriken, "scale", Vector3.ONE * 0.2, 0.35)
		t.tween_callback(func() -> void:
			_shuriken.visible = false
			(_ronin.get_node("Puppet") as RoninPuppet).play_healed())
	var card := AbilityCard.new()
	card.title = "Shuriken Dash"
	card.prompts = [["Space, then L", "A, then RB", "Spin, in the air"]]
	card.advice = "Dash in the air to spin like a thrown shuriken: further, and through paper walls."
	var ronin := _ronin
	card.used = func() -> bool: return is_instance_valid(ronin) and ronin.spinning
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud:
		hud.get_parent().add_child(card)


# --- The air ------------------------------------------------------------------------

## Paper scraps and petals blown along, and a few loose kites far off.
func _build_air() -> void:
	var scraps := CPUParticles3D.new()
	scraps.amount = 120
	scraps.lifetime = 9.0
	scraps.preprocess = 9.0
	scraps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	scraps.emission_box_extents = Vector3(END * 0.5 + 20.0, 6.0, 5.0)
	scraps.position = Vector3(END * 0.5, 4.0, -1.0)
	scraps.direction = Vector3(-1.0, 0.1, 0.0)
	scraps.spread = 20.0
	scraps.gravity = Vector3(-1.2, -0.2, 0.0)
	scraps.initial_velocity_min = 1.0
	scraps.initial_velocity_max = 3.0
	scraps.angle_max = 360.0
	scraps.angular_velocity_min = -300.0
	scraps.angular_velocity_max = 300.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.06)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.94, 0.9, 0.84)
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = look
	scraps.mesh = quad
	scraps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(scraps)
