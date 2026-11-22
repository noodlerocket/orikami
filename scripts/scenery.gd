class_name Scenery
extends RefCounted
## A kit of paper props for the rainy town: houses with tiled roofs and torn
## plaster walls, glowing lanterns, pines, banners, cherry branches and so on.
##
## Every function here builds ONE thing and returns it as a node, with its
## origin at a sensible spot (the ground under a house, the hook of a lantern).
## village.gd decides where the things go.
##
## The style rules, taken from the rainy-town reference picture:
##  - walls are dark boards with pale, peeling paper torn over them,
##  - every torn edge shows a thin pale rim,
##  - ink runs down the paper in drips,
##  - roofs are rows of small overlapping shingles with a wet pale lip,
##  - anything that glows gets a soft halo.

const WALL_DARK := Color(0.15, 0.15, 0.23)
const WALL_PAPER := Color(0.55, 0.535, 0.54)
const WALL_STAIN := Color(0.4, 0.39, 0.43)
const WALL_PAPER_RIM := Color(0.86, 0.84, 0.84)
const INK_DRIP := Color(0.09, 0.09, 0.15)
const TIMBER := PaperMesh.TIMBER
const ROOF := Color(0.21, 0.225, 0.3)
const ROOF_LIP := Color(0.3, 0.335, 0.47)
const ROOF_UNDER := Color(0.06, 0.06, 0.1)
const SHOJI_DARK := Color(0.1, 0.11, 0.2)
const WOOD := Color(0.24, 0.18, 0.17)
const CRIMSON := Color(0.5, 0.11, 0.12)
const OFF := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static var _halo_texture: GradientTexture2D


# --- Light: halos and wet reflections ---------------------------------------------

static func _soft_spot() -> GradientTexture2D:
	if _halo_texture == null:
		var fade := Gradient.new()
		fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		fade.add_point(0.3, Color(1.0, 1.0, 1.0, 0.38))
		fade.add_point(0.65, Color(1.0, 1.0, 1.0, 0.1))
		_halo_texture = GradientTexture2D.new()
		_halo_texture.gradient = fade
		_halo_texture.fill = GradientTexture2D.FILL_RADIAL
		_halo_texture.fill_from = Vector2(0.5, 0.5)
		_halo_texture.fill_to = Vector2(1.0, 0.5)
		_halo_texture.width = 128
		_halo_texture.height = 128
	return _halo_texture


static func _spot_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	mat.albedo_texture = _soft_spot()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	# Fade the glow out softly where it nears a surface, instead of the
	# surface cutting it off in a hard straight line (it looked like a flat
	# patch of paint on the wood next to a lantern).
	mat.proximity_fade_enabled = true
	mat.proximity_fade_distance = 0.25
	return mat


## A soft glow that always faces the camera. Put one on anything that shines.
static func halo(radius: float, tint: Color) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * radius * 2.0
	var mat := _spot_material(tint)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = mat
	node.cast_shadow = OFF
	return node


## A smear of light lying flat on wet ground, under a lantern or window.
## `size` is (width along the street, length toward the camera).
static func reflection(size: Vector2, tint: Color) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	quad.orientation = PlaneMesh.FACE_Y
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = _spot_material(tint)
	node.cast_shadow = OFF
	return node


# --- Wind -----------------------------------------------------------------------------

## Marks a piece so the wind moves it (village.gd does the moving). `gain` is
## how far it leans for each metre-per-second of wind: positive for things
## that HANG from their origin (curtains, streamers), negative for things
## that STAND on it (grass, branches).
static func windswept(node: Node3D, gain: float, rng: RandomNumberGenerator) -> void:
	node.add_to_group(&"windswept")
	node.set_meta(&"wind_gain", gain)
	node.set_meta(&"wind_phase", rng.randf() * TAU)
	node.set_meta(&"wind_rest", node.rotation)


# --- Lanterns ------------------------------------------------------------------------

## A chochin: a ribbed paper lantern with dark caps, a red crest and a tassel.
## Its origin is the hook it hangs from, so rotating it makes it sway.
static func lantern(rng: RandomNumberGenerator, glow: float, size: float = 1.0, string_length: float = 0.3) -> Node3D:
	var root := Node3D.new()
	var top := -string_length
	var radii := [0.13, 0.215, 0.27, 0.29, 0.27, 0.215, 0.13]
	var step := 0.11 * size
	var bottom := top - step * (radii.size() - 1)

	var frame := PaperMesh.new(rng.randi())
	frame.texture_world = false
	frame.color = PaperMesh.SUMI
	frame.box(Vector3(0.0, top * 0.5, 0.0), Vector3(0.025, string_length, 0.025))
	frame.frustum(8, Vector2.ONE * 0.15 * size, Vector2.ONE * 0.13 * size, 0.07 * size, Vector3(0.0, top - 0.01, 0.0))
	frame.frustum(8, Vector2.ONE * 0.13 * size, Vector2.ONE * 0.15 * size, 0.07 * size, Vector3(0.0, bottom - 0.06 * size, 0.0))
	# Tassel.
	frame.color = PaperMesh.VERMILION
	frame.stroke(Vector2(0.0, bottom - 0.06 * size), Vector2(0.0, bottom - 0.36 * size), 0.05 * size, 0.015 * size)
	# Crest on the front: five red petals.
	var middle := Vector2(0.0, (top + bottom) * 0.5)
	for k in 5:
		var angle := TAU * k / 5.0 + PI * 0.5
		frame.ellipse(middle + Vector2(cos(angle), sin(angle)) * 0.075 * size, Vector2(0.05, 0.05) * size, 6, 0.3 * size)
	var frame_mesh := frame.build()
	frame_mesh.cast_shadow = OFF
	root.add_child(frame_mesh)

	var paper := PaperMesh.new(rng.randi())
	paper.texture_world = false
	paper.texture_scale = 1.5
	paper.shade_jitter = 0.2
	var rings := []
	for i in radii.size():
		rings.append(PaperMesh.oval(Vector3(0.0, bottom + step * i, 0.0), Vector2.ONE * radii[i] * size, 10))
	paper.loft(rings, false, false)
	var body := paper.build(PaperMesh.LANTERN, glow)
	body.cast_shadow = OFF
	root.add_child(body)

	var shine := halo(1.9 * size, Color(1.0, 0.62, 0.3, 0.55))
	shine.position = Vector3(0.0, (top + bottom) * 0.5, -0.1)
	root.add_child(shine)
	root.set_meta("light_at", Vector3(0.0, (top + bottom) * 0.5, 0.0))
	return root


# --- Roofs ---------------------------------------------------------------------------

## A tiled roof seen from the front. Rows of small paper shingles overlap as
## they slope down toward the camera, from `ridge` to `eave`. Each of those is
## (height, depth). The pale lip on every shingle is the wet edge catching light.
static func tiled_roof(rng: RandomNumberGenerator, left: float, right: float, eave: Vector2, ridge: Vector2,
		rows: int, with_ridge: bool = true) -> Node3D:
	var root := Node3D.new()
	var tiles := PaperMesh.new(rng.randi())
	tiles.shade_jitter = 0.3
	tiles.color = ROOF
	var lips := PaperMesh.new(rng.randi())
	lips.shade_jitter = 0.45
	lips.color = ROOF_LIP
	var start := Vector3(0.0, eave.x, eave.y)
	var slope := Vector3(0.0, ridge.x - eave.x, ridge.y - eave.y)
	var along := slope.normalized()
	var up := Vector3(0.0, -along.z, along.y)
	if up.y < 0.0:
		up = -up  # (a back slope: its tiles must face up too, or from above it shows a bare board)
	for r in rows:
		var low := start + slope * (float(r) / rows) + up * 0.075
		var high := start + slope * minf(float(r + 1) / rows + 0.05, 1.0)
		var x := left - rng.randf() * 0.25
		while x < right:
			var x1 := x + rng.randf_range(0.34, 0.5)
			if rng.randf() < 0.035:  # a missing shingle
				x = x1
				continue
			var sag := along * rng.randf_range(-0.07, 0.03)
			var a := low + sag + Vector3(maxf(x, left) + 0.012, 0.0, 0.0)
			var b := low + sag + Vector3(minf(x1, right) - 0.012, 0.0, 0.0)
			tiles.quad(a, b, high + Vector3(b.x, 0.0, 0.0), high + Vector3(a.x, 0.0, 0.0), up)
			lips.quad(a, b, b - up * 0.06, a - up * 0.06, -along)
			x = x1

	# The dark board the shingles sit on, the eave's front edge, and the ridge.
	var under := PaperMesh.new(rng.randi())
	under.color = ROOF_UNDER
	under.quad(start + Vector3(left, -0.02, 0.0), start + Vector3(right, -0.02, 0.0),
			start + slope + Vector3(right, -0.02, 0.0), start + slope + Vector3(left, -0.02, 0.0), up)
	under.color = TIMBER
	under.box(start + Vector3((left + right) * 0.5, -0.09, -0.04), Vector3(right - left, 0.14, 0.08))
	if with_ridge:
		under.color = ROOF.darkened(0.25)
		under.box(start + slope + Vector3((left + right) * 0.5, 0.06, 0.0), Vector3(right - left + 0.3, 0.26, 0.34))
		under.color = Color(0.36, 0.4, 0.54)
		under.box(start + slope + Vector3((left + right) * 0.5, 0.2, 0.0), Vector3(right - left + 0.36, 0.05, 0.4))
	root.add_child(under.build())
	# Wet from the rain: the tiles catch the lanterns and the moon.
	var tile_mesh := tiles.build()
	var wet := tile_mesh.material_override as StandardMaterial3D
	wet.roughness = 0.32
	wet.metallic_specular = 0.7
	root.add_child(tile_mesh)
	var lip_mesh := lips.build(Color.WHITE, 0.0, true)
	lip_mesh.cast_shadow = OFF
	root.add_child(lip_mesh)
	return root


# --- Houses --------------------------------------------------------------------------

## One street house, origin on the ground at the middle of its front wall.
## `extras` can contain: "round" (a round window), "noren" (a tea-house
## banner), "noren_indigo" (a dyed curtain with a crest), "brace" (a diagonal
## timber), "awning" (a small lower roof), and lived-in details, each put in
## its own place along the front: "sudare" (a bamboo blind half down over the
## window), "pots" (potted plants by the wall), "umbrella" (a closed paper
## umbrella leaning on the wall), "firewood" (a stack of split logs),
## "shutters" (the window closed with wooden storm shutters), "buckets"
## (a pyramid of fire buckets with a water tub).
## The lit window's position is stored as the meta value "window".
static func house(rng: RandomNumberGenerator, width: float, height: float, lit: bool, window_glow: float,
		extras: Array = []) -> Node3D:
	var root := Node3D.new()
	var half := width * 0.5

	# 1. Dark boards at the back.
	var boards := PaperMesh.new(rng.randi())
	boards.color = WALL_DARK
	boards.rect(Vector2(0.0, height * 0.5), Vector2(width, height))
	boards.color = WALL_DARK.darkened(0.4)
	var x := -half + rng.randf_range(0.3, 0.5)
	while x < half - 0.2:
		boards.stroke(Vector2(x, 0.0), Vector2(x, height), 0.03, 0.03, 0.01)
		x += rng.randf_range(0.32, 0.6)
	root.add_child(boards.build())

	# 2. Pale paper torn over the boards, hanging lower in some places.
	var paper := PaperMesh.new(rng.randi())
	paper.color = WALL_PAPER
	paper.shade_jitter = 0.06
	var sheet := PackedVector2Array([Vector2(-half + 0.08, height), Vector2(-half + 0.08, height * 0.3)])
	x = -half + 0.5
	var base := height * rng.randf_range(0.14, 0.3)
	while x < half - 0.4:
		if rng.randf() < 0.18:  # a long tongue of paper still hanging down
			sheet.append(Vector2(x, maxf(base - rng.randf_range(0.5, 1.0), 0.05)))
		else:
			sheet.append(Vector2(x, base + rng.randf_range(-0.22, 0.3)))
		if rng.randf() < 0.3:  # now and then the tear jumps to a new height
			base = height * rng.randf_range(0.1, 0.42)
		x += rng.randf_range(0.5, 1.4)
	sheet.append(Vector2(half - 0.08, height * 0.3))
	sheet.append(Vector2(half - 0.08, height))
	paper.torn_sheet(PaperMesh.tear(sheet, 0.2, 0.05, rng), 0.04, WALL_PAPER_RIM, 0.045)
	# Damp stains, then holes where the paper has come away.
	paper.color = WALL_STAIN
	for i in 3:
		var stain := PackedVector2Array()
		var c := Vector2(rng.randf_range(-half * 0.8, half * 0.8), rng.randf_range(height * 0.35, height * 0.9))
		for k in 8:
			var angle := TAU * k / 8.0
			stain.append(c + Vector2(cos(angle) * 0.7, sin(angle) * 0.9) * rng.randf_range(0.5, 1.2))
		paper.polygon(PaperMesh.tear(stain, 0.2, 0.05, rng), 0.05)
	var holes: Array[PackedVector2Array] = []
	for i in rng.randi_range(1, 2):
		var hole := PackedVector2Array()
		var c := Vector2(rng.randf_range(-half * 0.7, half * 0.7), rng.randf_range(height * 0.55, height * 0.85))
		for k in 7:
			var angle := TAU * k / 7.0
			hole.append(c + Vector2(cos(angle) * 0.6, sin(angle) * 0.4) * rng.randf_range(0.5, 1.2))
		holes.append(PaperMesh.tear(hole, 0.16, 0.04, rng))
	# Ink running down the paper.
	paper.color = INK_DRIP
	for i in int(width * 1.6):
		var from := Vector2(rng.randf_range(-half + 0.3, half - 0.3), rng.randf_range(height * 0.5, height - 0.1))
		paper.stroke(from, from + Vector2(rng.randf_range(-0.03, 0.03), -rng.randf_range(0.5, 1.7)),
				rng.randf_range(0.03, 0.07), 0.008, 0.07)
	# (The holes are cut and the paper built once the window is placed: see 4.)

	# 3. Timber frame, a little proud of the wall so it catches light.
	var frame := PaperMesh.new(rng.randi())
	frame.color = TIMBER
	frame.shade_jitter = 0.25
	var beam_y := height * 0.44
	for side: float in [-1.0, 1.0]:
		frame.box(Vector3(side * (half - 0.11), height * 0.5, 0.12), Vector3(0.22, height, 0.2))
	frame.box(Vector3(0.0, beam_y, 0.12), Vector3(width, 0.17, 0.18))
	frame.box(Vector3(0.0, height - 0.09, 0.12), Vector3(width, 0.18, 0.2))
	frame.box(Vector3(0.0, 0.1, 0.12), Vector3(width, 0.2, 0.22))
	if "brace" in extras:
		var lean := 1.0 if rng.randf() < 0.5 else -1.0
		frame.extrude(PackedVector2Array([
			Vector2(lean * (half - 0.3), 0.2), Vector2(lean * (half - 0.12), 0.2),
			Vector2(lean * (half - 1.5), beam_y), Vector2(lean * (half - 1.68), beam_y),
		]), 0.06, 0.2)
	root.add_child(frame.build())

	# 4. Window.
	var window_at := Vector2(rng.randf_range(-half * 0.45, half * 0.2), beam_y + (height - beam_y) * 0.47)
	var window_size := Vector2(minf(1.7, width * 0.34), minf(1.35, (height - beam_y) * 0.62))
	var is_round := "round" in extras
	# Now the holes: only those clear of the window (and its frame), and of
	# the wall's corner posts.
	var keep_clear := Rect2(window_at - window_size * 0.5 - Vector2(0.35, 0.3), window_size + Vector2(0.7, 0.6))
	for hole: PackedVector2Array in holes:
		var bounds := Rect2(hole[0], Vector2.ZERO)
		for point: Vector2 in hole:
			bounds = bounds.expand(point)
		if bounds.intersects(keep_clear) or bounds.position.x < -half + 0.3 or bounds.end.x > half - 0.3:
			continue
		paper.color = WALL_DARK.darkened(0.15)
		paper.torn_sheet(hole, 0.06, WALL_PAPER_RIM, 0.035)
	var paper_mesh := paper.build()
	paper_mesh.cast_shadow = OFF
	root.add_child(paper_mesh)
	var pane := PaperMesh.new(rng.randi())
	pane.shade_jitter = 0.07
	if is_round:
		pane.ellipse(window_at, Vector2.ONE * window_size.y * 0.56, 14, 0.09)
	else:
		pane.rect(window_at, window_size, 0.09)
	var glass := pane.build(Color(1.0, 0.76, 0.46), window_glow, true) if lit else pane.build(SHOJI_DARK)
	glass.cast_shadow = OFF
	root.add_child(glass)
	var bars := PaperMesh.new(rng.randi())
	bars.color = TIMBER
	var reach := Vector2.ONE * window_size.y * 0.56 if is_round else window_size * 0.5
	for i in 4:
		var offset := lerpf(-reach.x, reach.x, (i + 0.5) / 4.0)
		var tall := sqrt(maxf(reach.y * reach.y - offset * offset, 0.0)) if is_round else reach.y
		bars.rect(window_at + Vector2(offset, 0.0), Vector2(0.045, tall * 2.0), 0.11)
	for i in 3:
		var offset := lerpf(-reach.y, reach.y, (i + 0.5) / 3.0)
		var wide := sqrt(maxf(reach.x * reach.x - offset * offset, 0.0)) if is_round else reach.x
		bars.rect(window_at + Vector2(0.0, offset), Vector2(wide * 2.0, 0.045), 0.11)
	if is_round:
		for k in 16:  # A ring of short strokes makes the round frame.
			var a0 := TAU * k / 16.0
			var a1 := TAU * (k + 1) / 16.0
			bars.stroke(window_at + Vector2(cos(a0), sin(a0)) * reach.x, window_at + Vector2(cos(a1), sin(a1)) * reach.x, 0.1, 0.1, 0.12)
	else:
		for side: float in [-1.0, 1.0]:
			bars.rect(window_at + Vector2(side * reach.x, 0.0), Vector2(0.1, window_size.y + 0.1), 0.12)
			bars.rect(window_at + Vector2(0.0, side * reach.y), Vector2(window_size.x + 0.1, 0.1), 0.12)
	if lit and not is_round:
		# One torn panel: the dark room shows through.
		bars.color = Color(0.2, 0.1, 0.06)
		var corner := window_at + Vector2(reach.x * 0.2, -reach.y * 0.9)
		bars.polygon(PaperMesh.tear(PackedVector2Array([corner, corner + Vector2(0.45, 0.05),
				corner + Vector2(0.3, 0.38), corner + Vector2(0.05, 0.3)]), 0.12, 0.04, rng), 0.1)
	var lattice := bars.build()
	lattice.cast_shadow = OFF
	root.add_child(lattice)
	if lit:
		var shine := halo(window_size.x * 1.3, Color(1.0, 0.6, 0.28, 0.32))
		shine.position = Vector3(window_at.x, window_at.y, 0.2)
		root.add_child(shine)
		root.set_meta("window", Vector3(window_at.x, window_at.y, 0.0))
		root.set_meta("window_size", window_size)
		root.set_meta("window_round", is_round)

	# 5. Roof, sloping toward the camera and overhanging the wall.
	var roof := tiled_roof(rng, -half - 0.75, half + 0.75, Vector2(height - 0.25, 1.75),
			Vector2(height + 1.55, -0.7), 6)
	root.add_child(roof)
	# 6. Depth. Side walls, gable ends, a back wall and the far slope of the
	# roof, so the house is a solid building when you see past its corner.
	var deep := 2.8
	var shell := PaperMesh.new(rng.randi())
	shell.shade_jitter = 0.1
	for side: float in [-1.0, 1.0]:
		var wall_x := side * half
		var out := Vector3(side, 0.0, 0.0)
		shell.color = WALL_DARK
		shell.quad(Vector3(wall_x, 0.0, 0.0), Vector3(wall_x, 0.0, -deep), Vector3(wall_x, height, -deep), Vector3(wall_x, height, 0.0), out)
		# The gable: the triangle of wall under the roof's slopes.
		shell.quad(Vector3(wall_x, height, 0.0), Vector3(wall_x, height, -deep), Vector3(wall_x, height + 1.5, -0.7),
				Vector3(wall_x, height + 1.0, 0.0), out)
		# Old paper still clinging to the side wall.
		shell.color = WALL_STAIN
		shell.quad(Vector3(wall_x + side * 0.02, height * 0.3, -0.35), Vector3(wall_x + side * 0.02, height * 0.22, -deep + 0.5),
				Vector3(wall_x + side * 0.02, height * 0.92, -deep + 0.4), Vector3(wall_x + side * 0.02, height * 0.95, -0.3), out)
		# Timber: the back corner post, and beams along the side.
		shell.color = TIMBER
		shell.box(Vector3(wall_x, height * 0.5, -deep + 0.1), Vector3(0.24, height, 0.22))
		shell.box(Vector3(wall_x + side * 0.03, height - 0.09, -deep * 0.5), Vector3(0.2, 0.18, deep))
		shell.box(Vector3(wall_x + side * 0.03, beam_y, -deep * 0.5), Vector3(0.18, 0.17, deep))
		shell.box(Vector3(wall_x + side * 0.03, 0.1, -deep * 0.5), Vector3(0.22, 0.2, deep))
	# A small shoji window in each side wall, lit if the house is lit.
	var side_glass := PaperMesh.new(rng.randi())
	side_glass.shade_jitter = 0.07
	var sill := beam_y + 0.35
	var lintel := minf(beam_y + 1.35, height - 0.35)
	shell.color = TIMBER
	for side: float in [-1.0, 1.0]:
		var pane_x := side * (half + 0.045)
		var bar_x := side * (half + 0.07)
		var out := Vector3(side, 0.0, 0.0)
		side_glass.quad(Vector3(pane_x, sill, -0.85), Vector3(pane_x, sill, -1.95),
				Vector3(pane_x, lintel, -1.95), Vector3(pane_x, lintel, -0.85), out)
		for k in 4:  # upright bars (the outer two are the frame)
			var z := lerpf(-0.85, -1.95, k / 3.0)
			var thick := 0.05 if k == 0 or k == 3 else 0.025
			shell.quad(Vector3(bar_x, sill - 0.05, z + thick), Vector3(bar_x, sill - 0.05, z - thick),
					Vector3(bar_x, lintel + 0.05, z - thick), Vector3(bar_x, lintel + 0.05, z + thick), out)
		for k in 3:  # cross bars
			var y := lerpf(sill, lintel, k / 2.0)
			var thick := 0.05 if k == 0 or k == 2 else 0.025
			shell.quad(Vector3(bar_x, y - thick, -0.8), Vector3(bar_x, y - thick, -2.0),
					Vector3(bar_x, y + thick, -2.0), Vector3(bar_x, y + thick, -0.8), out)
	var side_panes := side_glass.build(Color(1.0, 0.76, 0.46), window_glow, true) if lit else side_glass.build(SHOJI_DARK)
	side_panes.cast_shadow = OFF
	root.add_child(side_panes)
	shell.color = WALL_DARK.darkened(0.2)
	shell.quad(Vector3(-half, 0.0, -deep), Vector3(half, 0.0, -deep), Vector3(half, height, -deep),
			Vector3(-half, height, -deep), Vector3.FORWARD)
	# The far slope of the roof, running down behind the ridge.
	shell.color = ROOF.darkened(0.2)
	shell.quad(Vector3(-half - 0.75, height + 1.55, -0.7), Vector3(half + 0.75, height + 1.55, -0.7),
			Vector3(half + 0.75, height - 0.55, -3.6), Vector3(-half - 0.75, height - 0.55, -3.6), Vector3(0.0, 1.0, -0.7))
	root.add_child(shell.build())

	# Posts holding up the front of the roof.
	var porch := PaperMesh.new(rng.randi())
	porch.color = TIMBER
	porch.shade_jitter = 0.25
	for side: float in [-1.0, 1.0]:
		porch.box(Vector3(side * (half + 0.45), (height - 0.3) * 0.5, 1.5), Vector3(0.14, height - 0.3, 0.14))
	porch.box(Vector3(0.0, height - 0.42, 1.5), Vector3(width + 1.2, 0.12, 0.12))
	root.add_child(porch.build())

	if "awning" in extras:
		var low_roof := tiled_roof(rng, -half * 0.2, half + 0.3, Vector2(beam_y - 0.2, 1.3),
				Vector2(beam_y + 0.55, 0.15), 3, false)
		root.add_child(low_roof)
	_lived_in(root, rng, extras, half, height, beam_y, window_at, window_size, is_round)
	if "noren" in extras or "noren_indigo" in extras:
		var cloth := noren(rng, 1.25, 1.5, "noren_indigo" in extras)
		cloth.position = Vector3(-half * 0.45, beam_y - 0.08, 0.5)
		root.add_child(cloth)
	return root


## The small things that make a house someone's: each one asked for in
## `extras`, placed at a random spot along the front that is clear of the
## others, so no two houses keep them in the same place.
static func _lived_in(root: Node3D, rng: RandomNumberGenerator, extras: Array, half: float, height: float,
		beam_y: float, window_at: Vector2, window_size: Vector2, is_round: bool) -> void:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.2
	var taken: Array[Vector2] = []  # spans along the front already used
	var spot := func(wide: float) -> float:
		for attempt in 12:
			var x := rng.randf_range(-half + 0.4 + wide * 0.5, half - 0.4 - wide * 0.5)
			var clear := true
			for span: Vector2 in taken:
				if x + wide * 0.5 > span.x - 0.15 and x - wide * 0.5 < span.y + 0.15:
					clear = false
			if clear:
				taken.append(Vector2(x - wide * 0.5, x + wide * 0.5))
				return x
		return NAN
	if "shutters" in extras and not is_round:
		# Storm shutters: weathered boards over the window, a bar across.
		b.color = Color(0.2, 0.17, 0.18)
		b.rect(window_at, window_size + Vector2(0.12, 0.12), 0.115)
		b.color = Color(0.14, 0.12, 0.13)
		var bx := window_at.x - window_size.x * 0.5 + 0.18
		while bx < window_at.x + window_size.x * 0.5:
			b.rect(Vector2(bx, window_at.y), Vector2(0.02, window_size.y + 0.1), 0.12)
			bx += rng.randf_range(0.18, 0.26)
		b.color = PaperMesh.TIMBER
		b.rect(window_at + Vector2(0.0, rng.randf_range(-0.15, 0.15)), Vector2(window_size.x + 0.2, 0.07), 0.125)
	elif "sudare" in extras:
		# A bamboo blind, let down part way over the window.
		var drop := window_size.y * rng.randf_range(0.35, 0.75)
		var top_y := window_at.y + window_size.y * 0.5 + 0.06
		var wide := window_size.x + 0.16
		b.color = Color(0.5, 0.44, 0.32)
		b.rect(Vector2(window_at.x, top_y - drop * 0.5), Vector2(wide, drop), 0.13)
		b.color = Color(0.37, 0.31, 0.22)
		var y := top_y - 0.05
		while y > top_y - drop:
			b.rect(Vector2(window_at.x, y), Vector2(wide, 0.012), 0.135)
			y -= 0.055
		b.box(Vector3(window_at.x, top_y - drop, 0.15), Vector3(wide + 0.04, 0.05, 0.05))
	if "pots" in extras:
		var x: float = spot.call(1.0)
		if not is_nan(x):
			for k in rng.randi_range(2, 3):
				var px := x - 0.35 + k * 0.36
				var size := rng.randf_range(0.8, 1.2)
				b.color = [Color(0.36, 0.24, 0.18), Color(0.3, 0.3, 0.34), Color(0.42, 0.36, 0.3)][rng.randi() % 3]
				b.frustum(8, Vector2(0.11, 0.11) * size, Vector2(0.14, 0.14) * size, 0.2 * size, Vector3(px, 0.0, 0.45))
				b.color = Color(0.2, 0.28, 0.2) * rng.randf_range(0.8, 1.15)
				for leaf in 5:
					b.ellipse(Vector2(px + rng.randf_range(-0.12, 0.12), 0.25 * size + rng.randf_range(0.0, 0.25)),
							Vector2(0.08, 0.045), 6, 0.47 + leaf * 0.003, 0.2)
	if "umbrella" in extras:
		var x: float = spot.call(0.4)
		if not is_nan(x):
			# A closed wagasa: a long slim cone of oiled paper, its handle down.
			var lean := rng.randf_range(0.12, 0.22) * (1.0 if rng.randf() < 0.5 else -1.0)
			var tint: Color = [Color(0.5, 0.36, 0.22), Color(0.26, 0.28, 0.4), Color(0.4, 0.38, 0.34)][rng.randi() % 3]
			b.color = tint
			b.polygon(PackedVector2Array([Vector2(x, 0.25), Vector2(x + lean + 0.07, 1.25), Vector2(x + lean * 1.06, 1.42),
					Vector2(x + lean - 0.07, 1.25)]), 0.3)
			b.color = PaperMesh.TIMBER
			b.stroke(Vector2(x - lean * 0.2, 0.02), Vector2(x, 0.3), 0.025, 0.025, 0.31)
			b.color = tint.darkened(0.3)
			b.stroke(Vector2(x + lean * 0.5, 0.82), Vector2(x + lean * 0.55, 0.9), 0.1, 0.1, 0.32)
	if "firewood" in extras:
		var x: float = spot.call(1.1)
		if not is_nan(x):
			for row in 3:
				for k in 4 - row:
					var at := Vector2(x - 0.45 + row * 0.13 + k * 0.27, 0.11 + row * 0.2)
					b.color = Color(0.36, 0.28, 0.22) * rng.randf_range(0.8, 1.1)
					b.ellipse(at, Vector2(0.12, 0.1), 7, 0.55, 0.1)
					b.color = Color(0.5, 0.42, 0.32) * rng.randf_range(0.85, 1.05)
					b.ellipse(at, Vector2(0.07, 0.06), 6, 0.56, 0.1)
			b.color = Color(0.24, 0.2, 0.18)
			b.box(Vector3(x, 0.4, 0.35), Vector3(1.2, 0.8, 0.4))
	if "buckets" in extras:
		var x: float = spot.call(0.9)
		if not is_nan(x):
			# Fire buckets stacked in a pyramid on a stand, a tub of water by it.
			b.color = Scenery.WOOD
			b.box(Vector3(x, 0.35, 0.45), Vector3(0.7, 0.04, 0.4))
			for row in 3:
				for k in 3 - row:
					b.color = Color(0.32, 0.25, 0.2) * rng.randf_range(0.85, 1.1)
					b.frustum(8, Vector2(0.09, 0.09), Vector2(0.11, 0.11), 0.17,
							Vector3(x - 0.22 + row * 0.11 + k * 0.22, 0.37 + row * 0.17, 0.45))
			b.color = Scenery.WOOD.darkened(0.2)
			b.frustum(10, Vector2(0.24, 0.24), Vector2(0.27, 0.27), 0.34, Vector3(x + 0.55, 0.0, 0.5))
	root.add_child(b.build())


## A hanging shop curtain with the character 茶 (tea) brushed on it in ink.
## Like a real noren it is slit into strips, and each strip swings in the
## wind on its own. Origin: the middle of its top edge.
## `indigo`: a dyed indigo curtain with a pale ring crest instead.
static func noren(rng: RandomNumberGenerator, width: float, height: float, indigo: bool = false) -> Node3D:
	var root := Node3D.new()
	var half := width * 0.5
	var rail := PaperMesh.new(rng.randi())
	rail.color = TIMBER
	rail.rect(Vector2(0.0, 0.03), Vector2(width + 0.3, 0.07), 0.02)
	var rail_mesh := rail.build()
	rail_mesh.cast_shadow = OFF
	root.add_child(rail_mesh)
	# Each strip: where it starts and ends across the curtain (0 to 1).
	for strip: Array in [[0.0, 0.2], [0.22, 0.78], [0.8, 1.0]]:
		var left := lerpf(-half, half, strip[0])
		var right := lerpf(-half, half, strip[1])
		var wide := right - left
		var hinge := Node3D.new()
		hinge.position = Vector3((left + right) * 0.5, 0.0, 0.0)
		root.add_child(hinge)
		var b := PaperMesh.new(rng.randi())
		b.texture_world = false
		b.color = Color(0.2, 0.23, 0.38) if indigo else Color(0.74, 0.71, 0.68)
		var outline := PackedVector2Array([Vector2(-wide * 0.5, 0.0), Vector2(-wide * 0.5, -height * 0.9)])
		var teeth := maxi(2, roundi(wide / 0.2))
		for i in teeth:
			outline.append(Vector2(lerpf(-wide * 0.5, wide * 0.5, (i + 0.5) / teeth), -height * rng.randf_range(0.82, 1.08)))
		outline.append(Vector2(wide * 0.5, -height * 0.92))
		outline.append(Vector2(wide * 0.5, 0.0))
		b.torn_sheet(PaperMesh.tear(outline, 0.15, 0.025, rng), 0.0, Color(0.42, 0.45, 0.6) if indigo else Color(0.92, 0.9, 0.88), 0.03)
		if indigo and wide > width * 0.4:
			# A pale crest: a thick ring round a dot (the "snake's eye" crest).
			b.color = Color(0.78, 0.76, 0.72)
			var o := Vector2(0.0, -height * 0.44)
			var radius := wide * 0.28
			for k in 20:
				var a0 := TAU * k / 20.0
				var a1 := TAU * (k + 1.05) / 20.0
				b.stroke(o + Vector2(cos(a0), sin(a0)) * radius, o + Vector2(cos(a1), sin(a1)) * radius, wide * 0.1, wide * 0.1, 0.015)
			b.ellipse(o, Vector2.ONE * wide * 0.09, 12, 0.015)
		elif wide > width * 0.4:
			# 茶, stroke by stroke, on the wide middle strip.
			b.color = PaperMesh.SUMI
			var size := wide * 0.9
			var o := Vector2(0.0, -height * 0.46)
			for mark: Array in [
					[-0.42, 0.33, 0.42, 0.33, 0.09, 0.07], [-0.2, 0.47, -0.2, 0.2, 0.08, 0.06], [0.2, 0.47, 0.2, 0.2, 0.08, 0.06],
					[0.0, 0.22, -0.46, -0.08, 0.1, 0.03], [0.0, 0.22, 0.46, -0.08, 0.1, 0.03],
					[-0.24, -0.12, 0.24, -0.12, 0.08, 0.07], [0.0, -0.01, 0.0, -0.48, 0.09, 0.05],
					[-0.14, -0.24, -0.31, -0.41, 0.08, 0.03], [0.14, -0.24, 0.31, -0.41, 0.08, 0.03]]:
				b.stroke(o + Vector2(mark[0], mark[1]) * size, o + Vector2(mark[2], mark[3]) * size, mark[4] * size, mark[5] * size, 0.015)
		var cloth := b.build()
		cloth.cast_shadow = OFF
		hinge.add_child(cloth)
		windswept(hinge, 0.036, rng)
	return root


## A tall torn banner with a flower crest, on a pole. The cloth hangs from a
## crossbar on the pole's LEFT, which is downwind: the wind blows it away
## from the pole, never through it. Origin: the foot of the pole.
static func banner(rng: RandomNumberGenerator, height: float) -> Node3D:
	var root := Node3D.new()
	var pole := PaperMesh.new(rng.randi())
	pole.color = TIMBER
	pole.box(Vector3(0.0, height * 0.5, 0.0), Vector3(0.12, height, 0.12))
	pole.box(Vector3(-0.6, height - 0.25, 0.0), Vector3(1.4, 0.09, 0.09))
	root.add_child(pole.build())
	var hinge := Node3D.new()
	hinge.position = Vector3(-0.72, height - 0.3, 0.03)
	root.add_child(hinge)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.color = CRIMSON
	var long := height * 0.62
	var outline := PackedVector2Array([Vector2(-0.55, 0.0), Vector2(-0.55, -long * 0.95)])
	for i in 5:
		outline.append(Vector2(lerpf(-0.52, 0.53, (i + 0.5) / 5.0), -long * rng.randf_range(0.8, 1.12)))
	outline.append(Vector2(0.55, -long * 0.9))
	outline.append(Vector2(0.55, 0.0))
	b.torn_sheet(PaperMesh.tear(outline, 0.16, 0.035, rng), 0.0, Color(0.78, 0.36, 0.33), 0.03)
	# Chrysanthemum crest: a ring of petals round a dot.
	b.color = Color(0.76, 0.42, 0.36)
	var c := Vector2(0.0, -long * 0.42)
	for k in 12:
		var angle := TAU * k / 12.0
		var dir := Vector2(cos(angle), sin(angle))
		b.stroke(c + dir * 0.09, c + dir * 0.36, 0.07, 0.13, 0.015)
	b.ellipse(c, Vector2(0.09, 0.09), 8, 0.02)
	hinge.add_child(b.build())
	windswept(hinge, 0.028, rng)
	return root


# --- Street props ---------------------------------------------------------------------

## The well the Ronin climbs out of, with a small tiled roof on posts. Its
## mouth is open: a rim, then a stone wall inside going down and getting
## darker, to black water with a faint glint, so it has depth.
## `posts_back`: stands the two posts (and the beam and pulley) this far
## back; the roof stays directly over the well.
static func well(rng: RandomNumberGenerator, posts_back: float = 0.0) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.22
	b.color = Color(0.36, 0.38, 0.5)
	b.loft([PaperMesh.oval(Vector3.ZERO, Vector2(1.05, 1.05), 10), PaperMesh.oval(Vector3(0.0, 0.74, 0.0), Vector2(0.97, 0.97), 10)], false, false)
	b.color = Color(0.46, 0.48, 0.6)
	b.loft([PaperMesh.oval(Vector3(0.0, 0.72, 0.0), Vector2(1.03, 1.03), 10), PaperMesh.oval(Vector3(0.0, 0.84, 0.0), Vector2(1.03, 1.03), 10)], false, false)
	# The rim's top: a ring of stone round the mouth.
	var outer := PaperMesh.oval(Vector3(0.0, 0.84, 0.0), Vector2(1.03, 1.03), 10)
	var inner := PaperMesh.oval(Vector3(0.0, 0.84, 0.0), Vector2(0.8, 0.8), 10)
	b.color = Color(0.52, 0.54, 0.66)
	for i in 10:
		b.quad(outer[i], outer[(i + 1) % 10], inner[(i + 1) % 10], inner[i], Vector3.UP)
	root.add_child(b.build())
	# Inside: the stone wall going down, darker and darker (its own colours,
	# unlit: no light reaches down there), and black water at the bottom.
	var depth := PaperMesh.new(rng.randi())
	depth.shade_jitter = 0.08
	depth.texture_scale = 0.0
	var steps := 5
	for k in steps:
		var y_top := 0.84 - k * 0.16
		depth.color = Color(0.13, 0.14, 0.2).lerp(Color(0.01, 0.01, 0.02), pow(float(k + 1) / steps, 0.6))
		depth.loft([PaperMesh.oval(Vector3(0.0, y_top - 0.16, 0.0), Vector2(0.8, 0.8), 10),
				PaperMesh.oval(Vector3(0.0, y_top, 0.0), Vector2(0.8, 0.8), 10)], false, false)
	depth.color = Color(0.01, 0.01, 0.02)
	depth.frustum(10, Vector2(0.8, 0.8), Vector2(0.8, 0.8), 0.01, Vector3(0.0, 0.03, 0.0))
	depth.color = Color(0.2, 0.23, 0.34)   # a faint glint on the water, far down
	depth.quad(Vector3(-0.1, 0.045, -0.32), Vector3(0.38, 0.045, -0.32), Vector3(0.38, 0.045, -0.24), Vector3(-0.1, 0.045, -0.24), Vector3.UP)
	var water := depth.build(Color.WHITE, 0.0, true)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(water)
	var frame := PaperMesh.new(rng.randi())
	frame.color = TIMBER
	frame.shade_jitter = 0.25
	for side: float in [-1.0, 1.0]:
		frame.box(Vector3(side * 1.15, 1.5, 0.0), Vector3(0.17, 3.0, 0.17))
	frame.box(Vector3(0.0, 2.8, 0.0), Vector3(2.7, 0.13, 0.13))
	frame.box(Vector3(0.3, 2.25, 0.0), Vector3(0.025, 1.1, 0.025))
	frame.color = WOOD
	frame.frustum(6, Vector2(0.16, 0.16), Vector2(0.22, 0.22), 0.3, Vector3(0.3, 1.42, 0.0))
	var frame_mesh := frame.build()
	frame_mesh.position.z = posts_back
	root.add_child(frame_mesh)
	var roof := tiled_roof(rng, -1.9, 1.9, Vector2(2.95, 1.1), Vector2(3.65, -0.1), 3)
	root.add_child(roof)
	var back := tiled_roof(rng, -1.9, 1.9, Vector2(2.95, -1.3), Vector2(3.65, -0.1), 3, false)
	root.add_child(back)
	return root


## A wooden barrel with dark hoops.
static func barrel(rng: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.25
	b.color = WOOD
	b.loft([
		PaperMesh.oval(Vector3.ZERO, Vector2(0.34, 0.34) * size, 9),
		PaperMesh.oval(Vector3(0.0, 0.45 * size, 0.0), Vector2(0.42, 0.42) * size, 9),
		PaperMesh.oval(Vector3(0.0, 0.9 * size, 0.0), Vector2(0.34, 0.34) * size, 9),
	])
	b.color = TIMBER
	for y: float in [0.2, 0.7]:
		b.frustum(9, Vector2.ONE * 0.41 * size, Vector2.ONE * 0.41 * size, 0.06 * size, Vector3(0.0, y * size, 0.0))
	return b.build()


## A wooden crate.
static func crate(rng: RandomNumberGenerator, size: float = 0.8) -> Node3D:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.25
	b.color = WOOD.darkened(0.15)
	b.box(Vector3(0.0, size * 0.5, 0.0), Vector3(size, size, size))
	b.color = TIMBER
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * (size * 0.5 - 0.04), size * 0.5, size * 0.5), Vector3(0.08, size, 0.04))
		b.box(Vector3(0.0, size * 0.5 + side * (size * 0.5 - 0.04), size * 0.5), Vector3(size, 0.08, 0.04))
	return b.build()


## A run of broken fence: leaning posts and loose rails.
static func fence(rng: RandomNumberGenerator, length: float, height: float = 1.1) -> Node3D:
	var b := PaperMesh.new(rng.randi())
	b.color = TIMBER
	b.shade_jitter = 0.25
	var x := 0.0
	while x <= length:
		var lean := rng.randf_range(-0.14, 0.14)
		var tall := height * rng.randf_range(0.7, 1.1)
		b.extrude(PackedVector2Array([Vector2(x - 0.07, 0.0), Vector2(x + 0.07, 0.0),
				Vector2(x + 0.07 + lean, tall), Vector2(x - 0.07 + lean, tall)]), -0.06, 0.06)
		x += rng.randf_range(0.8, 1.1)
	for rail: float in [0.4, 0.8]:
		var sag := rng.randf_range(-0.12, 0.12)
		b.extrude(PackedVector2Array([Vector2(-0.1, height * rail), Vector2(length + 0.1, height * rail + sag),
				Vector2(length + 0.1, height * rail + sag + 0.1), Vector2(-0.1, height * rail + 0.1)]), 0.06, 0.1)
	return b.build()


## A torii gate. Origin: the ground between the posts.
static func torii(rng: RandomNumberGenerator, color: Color) -> Node3D:
	var root := Node3D.new()
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.18
	b.color = color
	for side: float in [-1.0, 1.0]:
		b.frustum(6, Vector2(0.21, 0.21), Vector2(0.16, 0.16), 4.2, Vector3(side * 1.5, 0.0, 0.0))
	b.box(Vector3(0.0, 3.35, 0.0), Vector3(3.7, 0.24, 0.2))
	b.box(Vector3(0.0, 3.8, 0.0), Vector3(0.2, 0.7, 0.16))
	# The top beam curves up at the ends.
	b.extrude(PackedVector2Array([Vector2(-2.45, 4.42), Vector2(-1.2, 4.18), Vector2(1.2, 4.18), Vector2(2.45, 4.42),
			Vector2(2.5, 4.72), Vector2(1.2, 4.5), Vector2(-1.2, 4.5), Vector2(-2.5, 4.72)]), -0.16, 0.16)
	b.color = PaperMesh.SUMI
	b.extrude(PackedVector2Array([Vector2(-2.5, 4.72), Vector2(-1.2, 4.5), Vector2(1.2, 4.5), Vector2(2.5, 4.72),
			Vector2(2.6, 4.88), Vector2(1.2, 4.64), Vector2(-1.2, 4.64), Vector2(-2.6, 4.88)]), -0.2, 0.2)
	root.add_child(b.build())
	# Torn paper streamers hanging from the lower beam, each free to swing.
	for i in 4:
		var hinge := Node3D.new()
		hinge.position = Vector3(lerpf(-1.0, 1.0, i / 3.0), 3.23, 0.13)
		root.add_child(hinge)
		var paper := PaperMesh.new(rng.randi())
		paper.texture_world = false
		paper.color = PaperMesh.WASHI
		var long := rng.randf_range(0.35, 0.8)
		paper.polygon(PackedVector2Array([Vector2(-0.08, 0.0), Vector2(0.08, 0.0),
				Vector2(0.14, -long * 0.5), Vector2(0.02, -long), Vector2(-0.1, -long * 0.6)]))
		var strip := paper.build()
		strip.cast_shadow = OFF
		hinge.add_child(strip)
		windswept(hinge, 0.055, rng)
	return root


# --- Trees ------------------------------------------------------------------------------

## Draws the silhouette of a Japanese pine into the cut-out builder `b`: a
## trunk that leans and kinks, boughs reaching out to alternate sides, and on
## each bough a flat, cloud-shaped pad of needles with a scalloped top.
static func pine(b: PaperMesh, base: Vector2, height: float, z: float, rng: RandomNumberGenerator) -> void:
	var at := base
	var width := height * 0.075
	var lean := rng.randf_range(-0.35, 0.35)
	var joints: Array[Vector2] = [at]
	# Roots spreading at the foot.
	b.polygon(PackedVector2Array([base + Vector2(-width * 1.5, 0.0), base + Vector2(width * 1.5, 0.0),
			base + Vector2(width * 0.5, height * 0.08), base + Vector2(-width * 0.5, height * 0.08)]), z)
	for i in 5:
		var next := at + Vector2(height * 0.2 * (lean + rng.randf_range(-0.45, 0.45)), height * 0.185)
		b.stroke(at, next, width, width * 0.78, z)
		at = next
		width *= 0.78
		joints.append(at)
	for i in range(1, joints.size()):
		var side := 1.0 if i % 2 == 0 else -1.0
		var reach := height * lerpf(0.4, 0.16, float(i) / joints.size())
		var tip := joints[i] + Vector2(side * reach * 0.7, height * rng.randf_range(0.0, 0.05))
		b.stroke(joints[i] - Vector2(0.0, height * 0.04), tip, width * 0.75, width * 0.3, z)
		_pine_pad(b, tip, reach, z + 0.01 * i, rng)
		if i <= 2 and rng.randf() < 0.6:   # a smaller pad tucked under the big ones
			_pine_pad(b, joints[i] + Vector2(-side * reach * 0.45, -height * 0.02), reach * 0.5, z + 0.005 * i, rng)
	_pine_pad(b, joints[joints.size() - 1] + Vector2(0.0, height * 0.015), height * 0.17, z + 0.06, rng)


## One pad of pine needles: flat underneath, three or four soft humps on top.
static func _pine_pad(b: PaperMesh, middle: Vector2, half_width: float, z: float, rng: RandomNumberGenerator) -> void:
	var pad := PackedVector2Array([middle + Vector2(-half_width, 0.0), middle + Vector2(half_width, 0.0)])
	var humps := rng.randf_range(3.0, 4.5)
	var phase := rng.randf() * TAU
	var steps := 14
	for k in range(1, steps):
		var angle := PI * float(k) / steps
		var rise := pow(sin(angle), 0.6) * (0.36 + 0.09 * sin(angle * humps * 2.0 + phase))
		pad.append(middle + Vector2(cos(angle) * half_width, rise * half_width))
	b.polygon(pad, z)


## A whole cherry tree: a gnarled trunk rooted at the node's origin, limbs
## that fork again and again, and blossom that is mostly over. Many twigs are
## bare, and what is left is dusty and faded, as the Rain would leave it.
## `lean` tips the tree (positive = toward the right); `flowers` is how many
## blossoms are still clinging on; `trunk` is how much of the height is bare
## trunk before the first fork (higher keeps the limbs out of the way).
static func sakura_tree(rng: RandomNumberGenerator, height: float, lean: float, flowers: int, trunk: float = 0.36) -> Node3D:
	var root := Node3D.new()
	var wood := PaperMesh.new(rng.randi())
	wood.texture_world = false
	wood.texture_scale = 0.5
	wood.shade_jitter = 0.18
	wood.color = Color(0.2, 0.16, 0.17)
	var twigs: Array[Vector2] = []
	# Roots flaring out at the foot, then the trunk and everything above it.
	wood.polygon(PackedVector2Array([Vector2(-height * 0.09, 0.0), Vector2(height * 0.09, 0.0),
			Vector2(height * 0.04, height * 0.08), Vector2(-height * 0.04, height * 0.08)]))
	_grow(wood, rng, Vector2.ZERO, PI * 0.5 - lean * 0.3, height * trunk, height * 0.075, 5, lean, twigs,
			height * (1.0 - trunk) * 0.42)
	var bark := wood.build()
	bark.cast_shadow = OFF
	root.add_child(bark)

	var petals := PaperMesh.new(rng.randi())
	petals.texture_world = false
	petals.texture_scale = 0.0
	petals.shade_jitter = 0.25
	# Only some twigs still carry blossom; it hangs on in clusters.
	var clusters: Array[Vector2] = []
	for tip: Vector2 in twigs:
		if rng.randf() < 0.55:
			clusters.append(tip)
	for i in flowers:
		if clusters.is_empty():
			break
		var c: Vector2 = clusters[rng.randi() % clusters.size()] + Vector2(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.45, 0.3))
		var size := rng.randf_range(0.13, 0.22)
		var turn := rng.randf() * TAU
		var z := 0.02 + rng.randf() * 0.1
		var fade := rng.randf()
		# Faded pink, greyer mauve, or browning at the edges.
		petals.color = PaperMesh.SAKURA if fade < 0.5 else (Color(0.52, 0.42, 0.5) if fade < 0.8 else Color(0.5, 0.43, 0.4))
		var kept := 5 if rng.randf() < 0.6 else rng.randi_range(2, 4)  # some have lost petals
		for k in kept:
			var angle := turn + TAU * k / 5.0
			var out := Vector2(cos(angle), sin(angle)) * size
			var across := out.orthogonal() * 0.42
			petals.polygon(PackedVector2Array([c, c + out * 0.62 - across, c + out - across * 0.35,
					c + out * 0.86, c + out + across * 0.35, c + out * 0.62 + across]), z)
		petals.color = Color(0.42, 0.26, 0.32)
		petals.ellipse(c, Vector2(size, size) * 0.2, 5, z + 0.005)
	var bloom := petals.build()
	bloom.cast_shadow = OFF
	root.add_child(bloom)
	root.set_meta(&"crown", Vector2(lean * height * 0.35, height * 0.8))
	windswept(root, -0.004, rng)
	return root


## Grows one limb and then, from its end, the limbs that fork off it.
## `next_length` (if given) is how long the limbs after this one start out.
static func _grow(wood: PaperMesh, rng: RandomNumberGenerator, from: Vector2, angle: float, length: float,
		width: float, forks_left: int, lean: float, twigs: Array[Vector2], next_length: float = -1.0) -> void:
	# Limbs always climb: never flatter than about 20 degrees above level.
	angle = clampf(angle, 0.35, PI - 0.35)
	if next_length < 0.0:
		next_length = length
	# Each limb is two strokes with a kink, so nothing is ruler-straight.
	var kink := angle + rng.randf_range(-0.25, 0.25)
	var middle := from + Vector2(cos(kink), sin(kink)) * length * 0.5
	var to := middle + Vector2(cos(angle), sin(angle)) * length * 0.5
	wood.stroke(from, middle, width, width * 0.86, 0.002 * forks_left)
	wood.stroke(middle, to, width * 0.86, width * 0.7, 0.002 * forks_left)
	if forks_left <= 0:
		twigs.append(to)
		return
	if forks_left <= 2:
		twigs.append(to)
	# One limb carries on, sweeping the way the tree leans; one forks away.
	var sweep := -lean * rng.randf_range(0.25, 0.55)
	_grow(wood, rng, to, angle + sweep, next_length * rng.randf_range(0.72, 0.86), width * 0.68, forks_left - 1, lean, twigs)
	var away := (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(0.5, 0.95)
	_grow(wood, rng, to, angle + away, next_length * rng.randf_range(0.55, 0.72), width * 0.52, forks_left - 1, lean, twigs)
	if forks_left >= 3 and rng.randf() < 0.5:
		# A dead stub: a short broken branch.
		_grow(wood, rng, middle, angle - away * 1.2, next_length * 0.22, width * 0.4, 0, lean, [])
