class_name Backdrop
extends Node3D
## Everything far behind the street, from the back forward:
##
##   the night sky and a crumpled paper moon,
##   torn clouds that drift with the wind,
##   a range of far peaks,
##   layers of hills, each with pines on it,
##   the Emperor's castle on its own hill, a path of lanterns climbing to it,
##   a far torii,
##   the back of the village, a river and an arched bridge,
##   and a thin veil of far-off rain.
##
## Two tricks make it feel deep, both copied from the reference picture:
##  1. each layer further away is PALER and BLUER than the one in front, and
##     a sheet of mist sits at the foot of every layer;
##  2. every layer is two sheets, not one: a lighter top edge fading down
##     into its own colour, and a darker ridge in front of that. Stacked
##     paper, not flat cut-outs.
## Because the layers really are at different distances, they also slide past
## each other as you walk.
##
## Nothing here is solid or lit: these are flat sheets in fixed colours.

const OFF := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
const MIST := Color(0.5, 0.57, 0.84)
const WINDOW := Color(1.0, 0.74, 0.42)
const MOON_AT := Vector3(30.0, 15.2, -50.5)

@export var mist_strength := 0.5
@export var layout_seed := 7
## How fast the clouds drift for each metre-per-second of wind.
@export var cloud_drift := 0.14
## How many streaks of far-off rain fall behind the village (0 = none).
@export var far_rain := 700

var _rng := RandomNumberGenerator.new()
var _clouds: Array[Node3D] = []
## Every rolling skyline as it was made, so the east end can be carried on
## (see _build_east): [base, height, lump, p1, p2, p3, z, top colour, body
## colour, fade, rim colour, rim width, skyline].
var _layers: Array = []
var _peaks_end := Vector2.ZERO


func _ready() -> void:
	_rng.seed = layout_seed
	_build_sky()
	_build_mountains()
	_build_far_village()
	_build_far_rain()
	_build_east()


func _process(delta: float) -> void:
	# Clouds ride the same wind as everything else, and come round again.
	var blow := Wind.speed_at(0.0) * cloud_drift * delta
	for cloud: Node3D in _clouds:
		cloud.position.x -= blow
		if cloud.position.x < -150.0:
			cloud.position.x += 300.0


# --- Sky ---------------------------------------------------------------------------

func _build_sky() -> void:
	# The night itself: darkest overhead, paler toward the horizon.
	var sky := _sheet()
	sky.fade_quad(Vector3(-200.0, -30.0, -53.0), Vector3(330.0, -30.0, -53.0),
			Vector3(330.0, 12.0, -53.0), Vector3(-200.0, 12.0, -53.0), Color(0.33, 0.37, 0.59), Color(0.17, 0.195, 0.37))
	sky.fade_quad(Vector3(-200.0, 12.0, -53.0), Vector3(330.0, 12.0, -53.0),
			Vector3(330.0, 26.0, -53.0), Vector3(-200.0, 26.0, -53.0), Color(0.17, 0.195, 0.37), Color(0.075, 0.085, 0.19))
	sky.fade_quad(Vector3(-200.0, 26.0, -53.0), Vector3(330.0, 26.0, -53.0),
			Vector3(330.0, 70.0, -53.0), Vector3(-200.0, 70.0, -53.0), Color(0.075, 0.085, 0.19), Color(0.03, 0.035, 0.1))
	_add(sky, true)

	# The moon: a wide soft glow, a tighter one, a torn pale rim, and the disc
	# itself, crumpled into many small folds.
	for glow: Array in [[17.0, 0.13], [8.5, 0.3]]:
		var halo := Scenery.halo(glow[0], Color(0.62, 0.7, 1.0, glow[1]))
		halo.position = MOON_AT + Vector3(0.0, 0.0, -0.6)
		add_child(halo)
	var moon := PaperMesh.new(_rng.randi())
	moon.texture_scale = 0.12
	moon.shade_jitter = 0.0
	moon.color = Color(1.0, 0.98, 0.93)
	moon.ellipse(Vector2.ZERO, Vector2(3.45, 3.45), 26, -0.05, 0.025)
	moon.shade_jitter = 0.15
	moon.color = Color(0.94, 0.9, 0.79)
	var dots := PackedVector2Array()
	for i in 22:   # the edge
		var angle := TAU * i / 22.0
		dots.append(Vector2(cos(angle), sin(angle)) * 3.3 * _rng.randf_range(0.97, 1.02))
	for i in 34:   # scattered inside: where the folds meet
		var angle := _rng.randf() * TAU
		dots.append(Vector2(cos(angle), sin(angle)) * 3.0 * sqrt(_rng.randf()))
	var folds := Geometry2D.triangulate_delaunay(dots)
	for i in range(0, folds.size(), 3):
		var a := dots[folds[i]]
		var b := dots[folds[i + 1]]
		var c := dots[folds[i + 2]]
		moon.tri(Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), Vector3(c.x, c.y, 0.0), Vector3.BACK)
	var disc := _add(moon, true)
	disc.position = MOON_AT

	# Long torn strips of cloud. Each is its own piece so it can drift.
	# [x, y, length, thickness, depth, brightness]
	for c: Array in [[-70.0, 30.0, 90.0, 6.5, -52.0, 0.75], [40.0, 27.5, 100.0, 5.5, -52.0, 0.8],
			[-25.0, 22.5, 70.0, 3.8, -51.6, 0.95], [75.0, 21.0, 64.0, 3.6, -51.6, 1.0],
			[-95.0, 17.5, 60.0, 3.0, -49.6, 1.15], [22.0, 17.2, 34.0, 2.2, -49.6, 1.35],
			[120.0, 15.5, 70.0, 3.0, -49.2, 1.2], [-20.0, 13.8, 52.0, 2.2, -49.2, 1.3],
			[62.0, 12.6, 30.0, 1.5, -49.0, 1.4], [-130.0, 24.0, 50.0, 3.0, -51.6, 0.9]]:
		_build_cloud(Vector2(c[0], c[1]), c[2], c[3], c[4], c[5])


## One cloud: a dark torn strip with a paler rim, and a second, lighter strip
## laid over its upper half, so it reads as two sheets rather than one.
func _build_cloud(middle: Vector2, length: float, thickness: float, z: float, brightness: float) -> void:
	var b := _sheet()
	b.color = Color(0.115, 0.14, 0.295) * brightness
	b.torn_sheet(PaperMesh.tear(_lens(middle, length, thickness), length / 50.0, thickness * 0.035, _rng), z,
			Color(0.22, 0.26, 0.46) * brightness, _rim(z) * 0.8)
	b.color = Color(0.15, 0.18, 0.36) * brightness
	b.torn_sheet(PaperMesh.tear(_lens(middle + Vector2(length * _rng.randf_range(-0.08, 0.08), thickness * 0.16),
			length * 0.7, thickness * 0.5), length / 50.0, thickness * 0.03, _rng), z + 0.03,
			Color(0.27, 0.32, 0.54) * brightness, _rim(z) * 0.7)
	_clouds.append(_add(b, true))


## The outline of a long flat lens: pointed at both ends, fat in the middle.
func _lens(middle: Vector2, length: float, thickness: float) -> PackedVector2Array:
	var outline := PackedVector2Array()
	var steps := 16
	for i in steps + 1:   # top edge, left to right
		var t := float(i) / steps
		var bulge := maxf(pow(sin(PI * t), 0.55), 0.2)
		outline.append(middle + Vector2((t - 0.5) * length, thickness * 0.5 * bulge * _rng.randf_range(0.75, 1.15)))
	for i in range(steps - 1, 0, -1):   # bottom edge, back again
		var t := float(i) / steps
		var bulge := maxf(pow(sin(PI * t), 0.8), 0.2)
		outline.append(middle + Vector2((t - 0.5) * length, -thickness * 0.4 * bulge * _rng.randf_range(0.7, 1.2)))
	return outline


# --- Peaks, hills, castle, pines -----------------------------------------------------

func _build_mountains() -> void:
	# Furthest first: a range of sharp peaks with pale caps.
	var peaks := PackedVector2Array()
	var x := -170.0
	while x < 190.0:
		var wide := _rng.randf_range(15.0, 26.0)
		var tall := _rng.randf_range(12.5, 19.0)
		peaks.append(Vector2(x, _rng.randf_range(7.5, 9.5)))
		peaks.append(Vector2(x + wide * _rng.randf_range(0.4, 0.6), tall))
		x += wide
	peaks.append(Vector2(x, 8.0))
	_peaks_end = Vector2(x, 8.0)
	var range_sheet := _sheet()
	var range_line := PaperMesh.tear(peaks, 2.2, 0.35, _rng, false)
	_curtain(range_sheet, range_line, -48.5, Color(0.31, 0.355, 0.585), Color(0.38, 0.43, 0.66), 9.0)
	_torn_rim(range_sheet, range_line, -48.52, Color(0.5, 0.56, 0.8), _rim(-48.5))
	range_sheet.color = Color(0.5, 0.56, 0.79)
	for i in range(1, peaks.size() - 1, 2):   # a pale cap on each summit
		var top := peaks[i]
		range_sheet.polygon(PaperMesh.tear(PackedVector2Array([top + Vector2(0.0, 0.1), top + Vector2(2.6, -2.4),
				top + Vector2(1.0, -1.7), top + Vector2(0.2, -2.9), top + Vector2(-0.9, -1.6), top + Vector2(-2.4, -2.6)]),
				0.9, 0.14, _rng), -48.4)
	_add(range_sheet, true)
	_mist(-47.0, 12.0, 0.6)

	_hills(-45.0, 8.0, 3.2, 17.0, Color(0.3, 0.345, 0.575), Color(0.48, 0.54, 0.79))
	_mist(-43.5, 10.0, 0.5)
	var back := _hills(-40.0, 5.6, 2.8, 12.0, Color(0.25, 0.29, 0.515), Color(0.43, 0.49, 0.74))
	_plant_pines(back, [-70.0, -48.0, -22.0, 52.0, 70.0, 96.0], 5.0, 7.5, -39.9, Color(0.2, 0.235, 0.44))
	_mist(-38.5, 8.0, 0.55)

	# The castle hill and the castle, where a few windows are lit: the
	# Emperor is awake. A path of lanterns climbs to its gate.
	var hill := _sheet()
	var mound := PackedVector2Array()
	for i in 27:
		var t := i / 26.0
		mound.append(Vector2(lerpf(-12.0, 46.0, t), 0.6 + 4.9 * pow(sin(PI * t), 1.5) + _rng.randf_range(-0.2, 0.2)))
	var mound_line := PaperMesh.tear(mound, 1.1, 0.16, _rng, false)
	_curtain(hill, mound_line, -36.0, Color(0.24, 0.28, 0.5), Color(0.205, 0.24, 0.45), 4.5)
	_torn_rim(hill, mound_line, -36.02, Color(0.4, 0.46, 0.7), _rim(-36.0))
	_add(hill, true)
	_build_castle(Vector3(17.0, 5.2, -35.8), 0.62)
	_plant_pines(mound_line, [-4.0, 2.5, 7.0, 27.5, 33.0, 39.0], 3.2, 5.2, -35.7, Color(0.155, 0.185, 0.37))
	var path := _sheet()
	for i in 7:
		var t := i / 6.0
		var spot := Vector2(lerpf(24.0, 37.0, t), _height_at(mound_line, lerpf(24.0, 37.0, t)) - 0.5 - 0.5 * sin(t * 9.0))
		path.ellipse(spot, Vector2(0.14, 0.2), 6, -35.6)
		var shine := Scenery.halo(0.9, Color(1.0, 0.62, 0.3, 0.36))
		shine.position = Vector3(spot.x, spot.y, -35.55)
		add_child(shine)
	_glow(path, 1.5)
	_mist(-34.0, 6.2, 0.6)

	# Nearer hills are lower, so the castle stands clear above them.
	var middle := _hills(-31.0, 3.0, 1.7, 9.0, Color(0.185, 0.22, 0.425), Color(0.33, 0.38, 0.62))
	_plant_pines(middle, [-55.0, -41.0, -29.0, -14.0, 0.0, 46.0, 58.0, 72.0, 86.0], 5.0, 8.0, -30.8, Color(0.135, 0.165, 0.335))
	_mist(-28.0, 5.2, 0.6)

	var near := _hills(-24.0, 2.0, 1.4, 7.0, Color(0.14, 0.17, 0.355), Color(0.27, 0.32, 0.54))
	_plant_pines(near, [-46.0, -32.0, -22.0, -7.0, 10.0, 26.0, 54.0, 67.0], 4.5, 7.5, -23.7, Color(0.09, 0.115, 0.255))
	_build_far_torii(Vector3(40.0, _height_at(near, 40.0) - 0.4, -23.6))
	_mist(-21.0, 4.6, 0.65)


## One layer of rolling hills. Returns its skyline, so pines can be stood on it.
func _hills(z: float, base: float, height: float, lump: float, color: Color, rim: Color) -> PackedVector2Array:
	var skyline := _rolling(base, height, lump)
	_layers[_layers.size() - 1].append_array([z, color.lightened(0.09), color, height * 2.2, rim, _rim(z), skyline])
	var ridge := _rolling(base - height * 1.05, height * 0.7, lump * 0.75)
	_layers[_layers.size() - 1].append_array([z + 0.05, color.darkened(0.07), color.darkened(0.1), height, color.lightened(0.12), _rim(z) * 0.7, ridge])
	var b := _sheet()
	_curtain(b, skyline, z, color.lightened(0.09), color, height * 2.2)
	_torn_rim(b, skyline, z - 0.02, rim, _rim(z))
	# A second, slightly darker ridge in front: the layer has depth of its own.
	_curtain(b, ridge, z + 0.05, color.darkened(0.07), color.darkened(0.1), height)
	_torn_rim(b, ridge, z + 0.03, color.lightened(0.12), _rim(z) * 0.7)
	_add(b, true)
	return skyline


## A lumpy line of hilltops running the whole width of the world.
func _rolling(base: float, height: float, lump: float) -> PackedVector2Array:
	var line := PackedVector2Array()
	var p1 := _rng.randf() * TAU
	var p2 := _rng.randf() * TAU
	var p3 := _rng.randf() * TAU
	var x := -170.0
	while x <= 190.0:
		line.append(Vector2(x, base + height * (0.55 * sin(x / lump + p1) + 0.3 * sin(x / (lump * 0.43) + p2)
				+ 0.15 * sin(x / (lump * 0.19) + p3))))
		x += lump * 0.25
	_layers.append([base, height, lump, p1, p2, p3])
	return PaperMesh.tear(line, lump * 0.11, lump * 0.03, _rng, false)


## The same skyline as _rolling made, carried on east from where it ended.
func _rolling_on(layer: Array, from: Vector2, to: float) -> PackedVector2Array:
	var base: float = layer[0]
	var height: float = layer[1]
	var lump: float = layer[2]
	var line := PackedVector2Array([from])
	var x := from.x + lump * 0.25
	while x <= to:
		line.append(Vector2(x, base + height * (0.55 * sin(x / lump + layer[3]) + 0.3 * sin(x / (lump * 0.43) + layer[4])
				+ 0.15 * sin(x / (lump * 0.19) + layer[5]))))
		x += lump * 0.25
	return PaperMesh.tear(line, lump * 0.11, lump * 0.03, _rng, false)


## Fills everything below a skyline: `top` colour along the skyline, fading
## to `body` colour over `fade` metres, then solid `body` all the way down.
func _curtain(b: PaperMesh, skyline: PackedVector2Array, z: float, top: Color, body: Color, fade: float) -> void:
	for i in skyline.size() - 1:
		var p := skyline[i]
		var q := skyline[i + 1]
		b.fade_quad(Vector3(p.x, p.y - fade, z), Vector3(q.x, q.y - fade, z), Vector3(q.x, q.y, z), Vector3(p.x, p.y, z), body, top)
		b.fade_quad(Vector3(p.x, -45.0, z), Vector3(q.x, -45.0, z), Vector3(q.x, q.y - fade, z), Vector3(p.x, p.y - fade, z), body, body)


## The pale torn edge along the top of a skyline.
func _torn_rim(b: PaperMesh, skyline: PackedVector2Array, z: float, color: Color, width: float) -> void:
	var lift := width * _rng.randf_range(0.4, 1.5)
	for i in skyline.size() - 1:
		var next_lift := width * _rng.randf_range(0.4, 1.5)
		var p := skyline[i]
		var q := skyline[i + 1]
		b.fade_quad(Vector3(p.x, p.y - width, z), Vector3(q.x, q.y - width, z), Vector3(q.x, q.y + next_lift, z),
				Vector3(p.x, p.y + lift, z), color, color)
		lift = next_lift


## How high a skyline is at a given x.
func _height_at(skyline: PackedVector2Array, x: float) -> float:
	for i in skyline.size() - 1:
		if x >= skyline[i].x and x <= skyline[i + 1].x:
			return lerpf(skyline[i].y, skyline[i + 1].y, inverse_lerp(skyline[i].x, skyline[i + 1].x, x))
	return skyline[0].y


## Stands pines on a skyline at the given places.
func _plant_pines(skyline: PackedVector2Array, places: Array, shortest: float, tallest: float, z: float, color: Color) -> void:
	var b := _sheet()
	b.color = color
	for place: float in places:
		var x := place + _rng.randf_range(-2.0, 2.0)
		Scenery.pine(b, Vector2(x, _height_at(skyline, x) - 0.4), _rng.randf_range(shortest, tallest), z, _rng)
	_add(b, true)


## Shiro, the Paper Castle: a stone base, five storeys that step inward, each
## under a roof whose corners curl up, and a spire on top.
func _build_castle(at: Vector3, size: float) -> void:
	var b := _sheet()
	var lights := _sheet()
	var boards := Color(0.15, 0.18, 0.365)
	var plaster := Color(0.27, 0.315, 0.535)
	var roof := Color(0.125, 0.15, 0.315)
	var rim := Color(0.42, 0.48, 0.72)
	# The stone base, wider at the foot, with a few courses marked.
	b.color = Color(0.2, 0.235, 0.44)
	b.torn_sheet(PaperMesh.tear(PackedVector2Array([Vector2(-8.0, -2.0), Vector2(8.0, -2.0), Vector2(6.2, 3.2), Vector2(-6.2, 3.2)]),
			1.0, 0.12, _rng), 0.0, rim.darkened(0.25), 0.1)
	b.color = Color(0.16, 0.19, 0.38)
	for course: float in [0.6, 1.5, 2.4]:
		b.stroke(Vector2(-6.9 + course * 0.25, course), Vector2(6.9 - course * 0.25, course), 0.07, 0.07, 0.01)
	var y := 3.2
	var half := 5.4
	for storey in 5:
		var tall := lerpf(2.4, 1.7, storey / 4.0)
		b.color = plaster
		b.rect(Vector2(0.0, y + tall * 0.5), Vector2(half * 2.0, tall), 0.02)
		b.color = boards
		b.rect(Vector2(0.0, y + tall * 0.19), Vector2(half * 2.0, tall * 0.38), 0.03)
		for side: float in [-1.0, 1.0]:
			b.rect(Vector2(side * (half - 0.14), y + tall * 0.5), Vector2(0.28, tall), 0.03)
		# Windows: most are lit.
		var count := maxi(1, 5 - storey)
		for i in count:
			var spot := Vector2(lerpf(-half * 0.68, half * 0.68, (i + 0.5) / count), y + tall * 0.68)
			if _rng.randf() < 0.72:
				lights.rect(spot, Vector2(0.46, 0.56), 0.06)
			else:
				b.rect(spot, Vector2(0.46, 0.56), 0.04)
		# The roof over this storey, and the shadow under its eave.
		b.color = boards.darkened(0.3)
		b.rect(Vector2(0.0, y + tall - 0.1), Vector2(half * 2.0 + 0.5, 0.22), 0.04)
		b.color = roof
		var eave := y + tall
		var reach := half + 0.3
		b.torn_sheet(PackedVector2Array([
			Vector2(-reach - 1.6, eave + 0.62), Vector2(-reach - 1.0, eave + 0.12), Vector2(-reach * 0.4, eave),
			Vector2(reach * 0.4, eave), Vector2(reach + 1.0, eave + 0.12), Vector2(reach + 1.6, eave + 0.62),
			Vector2(reach * 0.8, eave + 0.42), Vector2(reach * 0.64, eave + 0.98),
			Vector2(-reach * 0.64, eave + 0.98), Vector2(-reach * 0.8, eave + 0.42),
		]), 0.05 + storey * 0.02, rim, 0.085)
		if storey == 1 or storey == 3:   # a small gable breaking the roof line
			b.torn_sheet(PackedVector2Array([Vector2(-1.5, eave + 0.5), Vector2(1.5, eave + 0.5), Vector2(0.0, eave + 1.75)]),
					0.07 + storey * 0.02, rim, 0.08)
		y += tall + 0.98
		half *= 0.78
	# The spire, with its rings, and a fish-tail ornament at each end of the top roof.
	b.color = roof
	b.stroke(Vector2(0.0, y - 0.1), Vector2(0.0, y + 2.1), 0.2, 0.05, 0.12)
	for ring: float in [0.5, 0.95, 1.4]:
		b.rect(Vector2(0.0, y + ring), Vector2(0.52 - ring * 0.18, 0.11), 0.13)
	for side: float in [-1.0, 1.0]:
		b.stroke(Vector2(side * 1.3, y - 0.05), Vector2(side * 2.0, y + 0.85), 0.32, 0.05, 0.13)
	var keep := _add(b, true)
	keep.position = at
	keep.scale = Vector3.ONE * size
	var windows := _glow(lights, 1.25)
	windows.position = at
	windows.scale = Vector3.ONE * size
	# A soft glow behind it, so the castle stands out from the hills.
	var aura := Scenery.halo(11.0 * size, Color(0.55, 0.63, 1.0, 0.18))
	aura.position = at + Vector3(0.0, 9.0 * size, -0.4)
	add_child(aura)


## A torii on a hilltop, with a rope across it and torn paper hanging from the rope.
func _build_far_torii(at: Vector3) -> void:
	var b := _sheet()
	b.color = Color(0.085, 0.105, 0.24)
	for side: float in [-1.0, 1.0]:
		b.stroke(Vector2(side * 2.0, -1.5), Vector2(side * 1.8, 5.0), 0.55, 0.42)
	b.stroke(Vector2(-2.6, 3.9), Vector2(2.6, 3.9), 0.35, 0.35)
	b.polygon(PackedVector2Array([Vector2(-3.6, 5.3), Vector2(-1.5, 4.85), Vector2(1.5, 4.85),
			Vector2(3.6, 5.3), Vector2(3.7, 5.9), Vector2(1.5, 5.45), Vector2(-1.5, 5.45), Vector2(-3.7, 5.9)]))
	b.color = Color(0.3, 0.35, 0.56)   # the rope, sagging between the posts
	for i in 8:
		var t0 := i / 8.0
		var t1 := (i + 1) / 8.0
		b.stroke(Vector2(lerpf(-1.85, 1.85, t0), 3.4 - 0.45 * sin(PI * t0)), Vector2(lerpf(-1.85, 1.85, t1), 3.4 - 0.45 * sin(PI * t1)), 0.12, 0.12, 0.02)
	b.color = Color(0.5, 0.56, 0.78)   # torn paper streamers
	for i in 4:
		var t := (i + 0.5) / 4.0
		var top := Vector2(lerpf(-1.85, 1.85, t), 3.4 - 0.45 * sin(PI * t))
		b.polygon(PackedVector2Array([top + Vector2(-0.14, 0.0), top + Vector2(0.14, 0.0), top + Vector2(0.24, -0.5),
				top + Vector2(0.02, -1.0 - _rng.randf() * 0.4), top + Vector2(-0.2, -0.55)]), 0.03)
	var gate := _add(b, true)
	gate.position = at


# --- The back of the village ----------------------------------------------------------

func _build_far_village() -> void:
	# The slope the far houses stand on.
	_hills(-16.5, 1.3, 0.7, 5.0, Color(0.115, 0.14, 0.3), Color(0.22, 0.26, 0.46))
	var houses := _sheet()
	var lights := _sheet()
	# [x, ground, width, height]
	for h: Array in [[-34.0, 1.0, 6.0, 3.6], [-25.0, 1.6, 5.0, 4.4], [-17.5, 1.2, 6.5, 3.4], [-8.8, 1.8, 4.6, 4.0],
			[-1.0, 1.2, 6.0, 3.2], [8.5, 1.8, 5.5, 4.6], [15.5, 1.0, 5.0, 3.0], [22.5, 1.9, 6.0, 4.2],
			[30.0, 1.3, 5.0, 3.4], [38.5, 2.0, 6.5, 4.4], [47.0, 1.4, 5.0, 3.6], [55.0, 2.0, 6.0, 4.0]]:
		_far_house(houses, lights, Vector2(h[0], h[1]), h[2], h[3], -15.6, 1.0)
	# A fire watchtower standing above the roofs.
	houses.color = Color(0.085, 0.1, 0.225)
	var foot := Vector2(-12.6, 1.6)
	for side: float in [-1.0, 1.0]:
		houses.stroke(foot + Vector2(side * 0.9, 0.0), foot + Vector2(side * 0.45, 7.2), 0.16, 0.12, -15.5)
		houses.stroke(foot + Vector2(side * 0.9, 0.6), foot + Vector2(-side * 0.6, 3.6), 0.07, 0.07, -15.5)
		houses.stroke(foot + Vector2(side * 0.7, 3.6), foot + Vector2(-side * 0.5, 6.4), 0.07, 0.07, -15.5)
	houses.rect(foot + Vector2(0.0, 7.2), Vector2(1.9, 0.16), -15.5)
	houses.rect(foot + Vector2(0.0, 7.9), Vector2(1.3, 0.1), -15.5)
	houses.color = Color(0.15, 0.18, 0.35)
	houses.torn_sheet(PackedVector2Array([foot + Vector2(-1.5, 8.5), foot + Vector2(1.5, 8.5), foot + Vector2(0.0, 9.5)]),
			-15.45, Color(0.33, 0.38, 0.6), _rim(-15.5))
	_add(houses, true)
	_glow(lights, 1.3)
	_mist(-13.5, 4.2, 0.55)

	# The river, with moonlight broken on it, and the arched bridge across.
	var water := _sheet()
	water.fade_quad(Vector3(-80.0, -8.0, -12.4), Vector3(330.0, -8.0, -12.4), Vector3(330.0, 0.9, -12.4),
			Vector3(-80.0, 0.9, -12.4), Color(0.09, 0.11, 0.25), Color(0.19, 0.235, 0.45))
	water.color = Color(0.5, 0.57, 0.82)
	for i in 70:
		var along := _rng.randf_range(-60.0, 80.0)
		var down := _rng.randf_range(0.05, 0.78)
		# More glints, and longer, in the path of the moon.
		var near_moon := clampf(1.0 - absf(along - 22.0) / 16.0, 0.0, 1.0)
		if _rng.randf() > 0.3 + near_moon * 0.7:
			continue
		var long := _rng.randf_range(0.4, 1.2) * (1.0 + near_moon * 1.5)
		water.stroke(Vector2(along - long, down), Vector2(along + long, down), 0.035, 0.035, -12.35)
	_add(water, true)

	var bridge := _sheet()
	bridge.color = Color(0.085, 0.1, 0.22)
	var arch := PackedVector2Array()
	for i in 11:
		var t := i / 10.0
		arch.append(Vector2(lerpf(3.0, 17.0, t), 1.0 + 2.0 * sin(PI * t)))
	for i in range(10, -1, -1):
		var t := i / 10.0
		arch.append(Vector2(lerpf(3.0, 17.0, t), 0.3 + 2.0 * sin(PI * t)))
	bridge.torn_sheet(arch, -11.0, Color(0.2, 0.24, 0.43), 0.07)
	for i in 9:
		var t := (i + 0.5) / 9.0
		var post := Vector2(lerpf(3.0, 17.0, t), 1.0 + 2.0 * sin(PI * t))
		bridge.stroke(post, post + Vector2(0.0, 0.85), 0.14, 0.14, -11.0)
	for i in 10:
		var t0 := i / 10.0
		var t1 := (i + 1) / 10.0
		bridge.stroke(Vector2(lerpf(3.0, 17.0, t0), 1.8 + 2.0 * sin(PI * t0)), Vector2(lerpf(3.0, 17.0, t1), 1.8 + 2.0 * sin(PI * t1)), 0.13, 0.13, -11.0)
	for pier: float in [3.3, 16.7]:
		bridge.stroke(Vector2(pier, -4.0), Vector2(pier, 1.9), 0.4, 0.4, -11.0)
	bridge.stroke(Vector2(10.0, 3.0), Vector2(10.0, 4.1), 0.1, 0.1, -11.0)   # the lantern's post
	_add(bridge, true)
	var lamp := _sheet()
	lamp.ellipse(Vector2(10.0, 4.35), Vector2(0.22, 0.3), 8, -10.95)
	_glow(lamp, 1.5)
	var shine := Scenery.halo(1.6, Color(1.0, 0.6, 0.3, 0.4))
	shine.position = Vector3(10.0, 4.35, -10.9)
	add_child(shine)
	_mist(-9.6, 3.2, 0.45)

	# A middle row of houses close behind the street. Their roofs peek over
	# the street's roofs and they fill the gaps between its houses.
	var mid := _sheet()
	var mid_lights := _sheet()
	for h: Array in [[-21.0, 0.0, 6.0, 5.6], [-8.6, 0.0, 5.0, 5.9], [20.8, 0.0, 5.0, 6.5], [29.2, 0.0, 5.5, 5.9], [47.5, 1.5, 6.0, 5.6]]:
		_far_house(mid, mid_lights, Vector2(h[0], h[1]), h[2], h[3], -8.8, 0.78)
	_add(mid, true)
	_glow(mid_lights, 1.4)
	_mist(-6.6, 2.4, 0.3)


## A house for the rows behind the street: plaster above, boards below, a
## tiled roof with a pale edge, and (usually) a lit window with its lattice.
## `tone` darkens it: nearer rows are darker, further rows are paler.
func _far_house(b: PaperMesh, lights: PaperMesh, at: Vector2, width: float, height: float, z: float, tone: float) -> void:
	var half := width * 0.5
	var timber := Color(0.065, 0.08, 0.18) * tone
	b.color = Color(0.225, 0.265, 0.475) * tone   # plaster
	b.rect(at + Vector2(0.0, height * 0.5), Vector2(width, height), z)
	b.color = Color(0.105, 0.125, 0.265) * tone  # boards, and the wall running down out of sight
	b.rect(at + Vector2(0.0, height * 0.22 - 2.0), Vector2(width, height * 0.44 + 4.0), z + 0.01)
	b.color = timber
	for side: float in [-1.0, 1.0]:
		b.rect(at + Vector2(side * (half - 0.12), height * 0.5), Vector2(0.22, height), z + 0.02)
	b.rect(at + Vector2(0.0, height * 0.44), Vector2(width, 0.15), z + 0.02)
	b.rect(at + Vector2(0.0, height - 0.22), Vector2(width + 0.9, 0.3), z + 0.03)   # shadow under the eave
	if _rng.randf() < 0.5:   # a doorway
		b.rect(at + Vector2(_rng.randf_range(-half * 0.5, half * 0.5), height * 0.2), Vector2(0.9, height * 0.4), z + 0.02)
	# Roof, with two lines of tiles picked out.
	var roof_color := Color(0.165, 0.195, 0.375) * tone
	b.color = roof_color
	var roof := PackedVector2Array([
		at + Vector2(-half - 0.9, height - 0.15), at + Vector2(half + 0.9, height - 0.15),
		at + Vector2(half + 0.45, height + 0.45), at + Vector2(half * 0.25, height + 1.55),
		at + Vector2(-half * 0.25, height + 1.55), at + Vector2(-half - 0.45, height + 0.45)])
	b.torn_sheet(PaperMesh.tear(roof, 0.5, 0.06, _rng), z + 0.05, Color(0.36, 0.42, 0.66) * tone, _rim(z) * 0.9)
	b.color = roof_color.lightened(0.14)
	b.stroke(at + Vector2(-half - 0.6, height + 0.22), at + Vector2(half + 0.6, height + 0.22), 0.06, 0.06, z + 0.06)
	b.stroke(at + Vector2(-half * 0.6, height + 0.85), at + Vector2(half * 0.6, height + 0.85), 0.06, 0.06, z + 0.06)
	# Two windows in the plaster: usually one is lit and one is dark.
	var pane := Vector2(0.95, 0.75)
	var lit := _rng.randi_range(0, 2)   # 0 = left, 1 = right, 2 = neither
	for w in 2:
		var spot := at + Vector2(half * (-0.42 if w == 0 else 0.42) + _rng.randf_range(-0.2, 0.2),
				height * 0.44 + (height * 0.56 - 0.3) * 0.5)
		if w == lit:
			lights.rect(spot, pane, z + 0.04)
			var shine := Scenery.halo(1.5, Color(1.0, 0.6, 0.3, 0.3))
			shine.position = Vector3(spot.x, spot.y, z + 0.12)
			add_child(shine)
		else:
			b.color = Color(0.08, 0.095, 0.21) * tone
			b.rect(spot, pane, z + 0.04)
		b.color = timber
		for bar in 3:   # lattice
			b.rect(spot + Vector2((bar - 1) * pane.x / 3.0, 0.0), Vector2(0.045, pane.y), z + 0.07)
		b.rect(spot, Vector2(pane.x + 0.1, 0.045), z + 0.07)
		for edge: float in [-1.0, 1.0]:
			b.rect(spot + Vector2(0.0, edge * pane.y * 0.5), Vector2(pane.x + 0.12, 0.07), z + 0.07)


## A thin veil of rain falling far behind the village: it makes the air
## between here and the hills feel wet.
func _build_far_rain() -> void:
	if far_rain <= 0:
		return
	var drops := CPUParticles3D.new()
	drops.amount = far_rain
	drops.lifetime = 1.7
	drops.preprocess = 1.7
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drops.emission_box_extents = Vector3(80.0, 0.5, 4.0)
	drops.direction = Vector3(-0.2, -1.0, 0.0)
	drops.spread = 1.0
	drops.gravity = Vector3.ZERO
	drops.initial_velocity_min = 17.0
	drops.initial_velocity_max = 21.0
	var streak := QuadMesh.new()
	streak.size = Vector2(0.035, 1.5)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.72, 0.8, 1.0, 0.16)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	look.billboard_keep_scale = true
	look.disable_fog = true
	streak.material = look
	drops.mesh = streak
	drops.cast_shadow = OFF
	drops.position = Vector3(15.0, 27.0, -19.0)
	add_child(drops)


# --- Helpers -----------------------------------------------------------------------------

## A fresh builder for flat, evenly coloured backdrop sheets.
func _sheet() -> PaperMesh:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.0
	b.texture_scale = 0.07
	return b


## Finishes a backdrop sheet: fixed colour, no shadows, untouched by fog.
func _add(b: PaperMesh, unshaded: bool) -> MeshInstance3D:
	var piece := b.build(Color.WHITE, 0.0, unshaded)
	(piece.material_override as StandardMaterial3D).disable_fog = true
	piece.cast_shadow = OFF
	add_child(piece)
	return piece


## Finishes a sheet of lit windows or lanterns: warm, and bright enough to glow.
func _glow(b: PaperMesh, strength: float) -> MeshInstance3D:
	var piece := b.build(WINDOW, strength, true)
	(piece.material_override as StandardMaterial3D).disable_fog = true
	piece.cast_shadow = OFF
	add_child(piece)
	return piece


## How wide a torn rim must be at depth `z` to look the same on screen.
func _rim(z: float) -> float:
	return 0.05 * (15.0 - z) / 15.0


## A sheet of mist: solid at the bottom, fading to nothing at `top`.
func _mist(z: float, top: float, amount: float) -> void:
	var b := PaperMesh.new(1)
	var solid := Color(MIST.r, MIST.g, MIST.b, amount * mist_strength)
	var clear := Color(MIST.r, MIST.g, MIST.b, 0.0)
	b.fade_quad(Vector3(-200.0, top - 7.0, z), Vector3(330.0, top - 7.0, z),
			Vector3(330.0, top, z), Vector3(-200.0, top, z), solid, clear)
	b.fade_quad(Vector3(-200.0, -45.0, z), Vector3(330.0, -45.0, z),
			Vector3(330.0, top - 7.0, z), Vector3(-200.0, top - 7.0, z), solid, solid)
	add_child(b.build_veil())


# --- The east end ------------------------------------------------------------------

## The village grew east (to the Shrine Steps and the courtyard, x 190), so
## the far layers are carried on past where they used to end. Built last,
## with its own random numbers, so nothing already seen west of here changes.
func _build_east() -> void:
	var kept := _rng
	_rng = RandomNumberGenerator.new()
	_rng.seed = layout_seed * 31 + 5
	var to := 330.0
	# The peaks.
	var peaks := PackedVector2Array([_peaks_end])
	var x := _peaks_end.x
	while x < to:
		var wide := _rng.randf_range(15.0, 26.0)
		peaks.append(Vector2(x + wide * _rng.randf_range(0.4, 0.6), _rng.randf_range(12.5, 19.0)))
		x += wide
		peaks.append(Vector2(x, _rng.randf_range(7.5, 9.5)))
	var range_sheet := _sheet()
	var range_line := PaperMesh.tear(peaks, 2.2, 0.35, _rng, false)
	_curtain(range_sheet, range_line, -48.5, Color(0.31, 0.355, 0.585), Color(0.38, 0.43, 0.66), 9.0)
	_torn_rim(range_sheet, range_line, -48.52, Color(0.5, 0.56, 0.8), _rim(-48.5))
	range_sheet.color = Color(0.5, 0.56, 0.79)
	for i in range(1, peaks.size() - 1, 2):
		var top := peaks[i]
		range_sheet.polygon(PaperMesh.tear(PackedVector2Array([top + Vector2(0.0, 0.1), top + Vector2(2.6, -2.4),
				top + Vector2(1.0, -1.7), top + Vector2(0.2, -2.9), top + Vector2(-0.9, -1.6), top + Vector2(-2.4, -2.6)]),
				0.9, 0.14, _rng), -48.4)
	_add(range_sheet, true)
	# Every rolling layer of hills, carried on from where it ended.
	for layer: Array in _layers:
		if layer.size() < 13:
			continue  # (a skyline that is not part of a hill layer)
		var b := _sheet()
		var old: PackedVector2Array = layer[12]
		var line := _rolling_on(layer, old[old.size() - 1], to)
		var z: float = layer[6]
		_curtain(b, line, z, layer[7], layer[8], layer[9])
		_torn_rim(b, line, z - 0.02, layer[10], layer[11])
		_add(b, true)
	# More of the far village on its slope, and the middle row behind the
	# street, as far as the courtyard.
	var houses := _sheet()
	var lights := _sheet()
	x = 63.0
	while x < 215.0:
		_far_house(houses, lights, Vector2(x, _rng.randf_range(1.0, 2.0)), _rng.randf_range(4.6, 6.5), _rng.randf_range(3.0, 4.6), -15.6, 1.0)
		x += _rng.randf_range(7.0, 10.0)
	_add(houses, true)
	_glow(lights, 1.3)
	var mid := _sheet()
	var mid_lights := _sheet()
	for h: Array in [[60.5, 0.0, 5.0, 5.8], [141.5, 0.0, 5.5, 6.4], [160.0, 0.6, 6.0, 5.6]]:
		_far_house(mid, mid_lights, Vector2(h[0], h[1]), h[2], h[3], -8.8, 0.78)
	_add(mid, true)
	_glow(mid_lights, 1.4)
	_rng = kept
