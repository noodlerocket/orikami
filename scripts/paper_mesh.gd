class_name PaperMesh
extends RefCounted
## Builds "folded paper" shapes in code, so no Blender is needed.
##
## How to use it:
##   var b := PaperMesh.new()
##   b.color = PaperMesh.VERMILION      # colour of the pieces added next
##   b.frustum(6, Vector2(0.4, 0.3), Vector2(0.2, 0.2), 0.6)
##   add_child(b.build())               # a ready MeshInstance3D
##
## Three things make it look like paper rather than plastic:
##  1. every fold (triangle) gets its own flat shading and a slightly
##     different shade,
##  2. a crumple texture, so light catches tiny wrinkles,
##  3. torn edges: tear() roughens an outline and torn_sheet() adds the pale
##     fibrous rim you see where real paper has been ripped.

# The palette from the design doc.
const WASHI := Color(0.93, 0.9, 0.84)
const SUMI := Color(0.07, 0.07, 0.1)
const INDIGO := Color(0.16, 0.19, 0.36)
const VERMILION := Color(0.84, 0.2, 0.12)
const LANTERN := Color(1.0, 0.72, 0.38)
## Cherry blossom past its best: dusty and faded, not bright pink.
const SAKURA := Color(0.7, 0.56, 0.6)
const TIMBER := Color(0.1, 0.085, 0.11)

## Colour of the pieces added from now on.
var color := Color.WHITE
## How much each fold's brightness varies (0 = perfectly even).
var shade_jitter := 0.1
## How often the paper texture repeats per metre. 0 = perfectly smooth paper.
var texture_scale := 0.22
## True for scenery that never moves. False for puppets, so the wrinkles
## travel with the piece instead of sliding across it.
var texture_world := true
## How deep the wrinkles look (0 = none).
var wrinkle_depth := 0.6

var _st := SurfaceTool.new()
var _rng := RandomNumberGenerator.new()

static var _grain: ImageTexture
static var _crumple: ImageTexture


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


# --- Folds (3D shapes) --------------------------------------------------------

## Adds one triangle. If `outward` is given, the triangle is flipped when
## needed so its lit side faces that direction.
func tri(a: Vector3, b: Vector3, c: Vector3, outward: Vector3 = Vector3.ZERO) -> void:
	_emit(a, b, c, outward, _shade(color))


## Adds a four-cornered face (corners given in order around the edge).
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3 = Vector3.ZERO) -> void:
	tri(a, b, c, outward)
	tri(a, c, d, outward)


## A ring of `sides` faces going from a bottom ellipse to a top ellipse. Top of
## Vector2.ZERO gives a cone; equal top and bottom gives a column; 4 sides with
## turn = PI/4 gives a tapered box.
func frustum(sides: int, bottom: Vector2, top: Vector2, height: float,
		base: Vector3 = Vector3.ZERO, turn: float = 0.0) -> void:
	var center := base + Vector3(0.0, height * 0.5, 0.0)
	var top_center := base + Vector3(0.0, height, 0.0)
	for i in sides:
		var a0 := turn + TAU * float(i) / float(sides)
		var a1 := turn + TAU * float(i + 1) / float(sides)
		var b0 := base + Vector3(cos(a0) * bottom.x, 0.0, sin(a0) * bottom.y)
		var b1 := base + Vector3(cos(a1) * bottom.x, 0.0, sin(a1) * bottom.y)
		var t0 := top_center + Vector3(cos(a0) * top.x, 0.0, sin(a0) * top.y)
		var t1 := top_center + Vector3(cos(a1) * top.x, 0.0, sin(a1) * top.y)
		var outward := (b0 + b1 + t0 + t1) / 4.0 - center
		if top == Vector2.ZERO:
			tri(b0, b1, top_center, outward)
		elif bottom == Vector2.ZERO:
			tri(base, t1, t0, outward)
		else:
			quad(b0, b1, t1, t0, outward)
		if bottom != Vector2.ZERO:
			tri(base, b0, b1, Vector3.DOWN)
		if top != Vector2.ZERO:
			tri(top_center, t0, t1, Vector3.UP)


## A plain box.
func box(center: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				corners.append(center + Vector3(sx * h.x, sy * h.y, sz * h.z))
	# Corner index = x*4 + y*2 + z (each 0 or 1).
	quad(corners[0], corners[1], corners[3], corners[2], Vector3.LEFT)
	quad(corners[4], corners[5], corners[7], corners[6], Vector3.RIGHT)
	quad(corners[0], corners[1], corners[5], corners[4], Vector3.DOWN)
	quad(corners[2], corners[3], corners[7], corners[6], Vector3.UP)
	quad(corners[0], corners[2], corners[6], corners[4], Vector3.FORWARD)
	quad(corners[1], corners[3], corners[7], corners[5], Vector3.BACK)


## One ring of points for loft(): an oval lying flat at `center`.
## Radius x is front-to-back, radius y is side-to-side.
static func oval(center: Vector3, radius: Vector2, sides: int, turn: float = 0.0) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in sides:
		var angle := turn + TAU * float(i) / float(sides)
		ring.append(center + Vector3(cos(angle) * radius.x, 0.0, sin(angle) * radius.y))
	return ring


## Joins a stack of rings (each with the same number of points) into a folded
## tube, like a paper lantern. Used for robes, sleeves, heads and helmets.
func loft(rings: Array, cap_bottom: bool = true, cap_top: bool = true) -> void:
	for r in rings.size() - 1:
		var low: PackedVector3Array = rings[r]
		var high: PackedVector3Array = rings[r + 1]
		var middle := (_middle(low) + _middle(high)) * 0.5
		for i in low.size():
			var j := (i + 1) % low.size()
			var face := (low[i] + low[j] + high[i] + high[j]) / 4.0
			quad(low[i], low[j], high[j], high[i], face - middle)
	if cap_bottom:
		_cap(rings[0], Vector3.DOWN)
	if cap_top:
		_cap(rings[rings.size() - 1], Vector3.UP)


## Pushes a flat outline (x, y) through the Z axis to make a solid bar.
## Used for beams, feet and anything with a constant cross-section.
func extrude(profile: PackedVector2Array, z_back: float, z_front: float) -> void:
	var middle := Vector2.ZERO
	for p: Vector2 in profile:
		middle += p
	middle /= profile.size()
	for i in profile.size():
		var a := profile[i]
		var b := profile[(i + 1) % profile.size()]
		var out := (a + b) * 0.5 - middle
		quad(Vector3(a.x, a.y, z_back), Vector3(b.x, b.y, z_back),
				Vector3(b.x, b.y, z_front), Vector3(a.x, a.y, z_front), Vector3(out.x, out.y, 0.0))
	var keep := shade_jitter
	polygon(profile, z_front)
	polygon(profile, z_back)
	shade_jitter = keep


# --- Cut-outs (flat shapes facing the camera) ---------------------------------

## A flat paper cut-out facing the camera. Points are (x, y); `z` is its depth.
## The whole cut-out gets one even shade, like a single sheet.
func polygon(points: PackedVector2Array, z: float = 0.0) -> void:
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		push_warning("PaperMesh.polygon: could not triangulate a cut-out shape near %s (%d points)." % [points[0], points.size()])
		return
	var tint := _shade(color)
	for i in range(0, indices.size(), 3):
		var a := points[indices[i]]
		var b := points[indices[i + 1]]
		var c := points[indices[i + 2]]
		_emit(Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), Vector3.BACK, tint)


## A flat rectangle cut-out.
func rect(center: Vector2, size: Vector2, z: float = 0.0) -> void:
	var h := size * 0.5
	polygon(PackedVector2Array([
		center + Vector2(-h.x, -h.y), center + Vector2(h.x, -h.y),
		center + Vector2(h.x, h.y), center + Vector2(-h.x, h.y),
	]), z)


## A flat oval or circle cut-out. `wobble` makes it uneven, like a hand cut.
func ellipse(center: Vector2, radius: Vector2, sides: int = 12, z: float = 0.0, wobble: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		var r := 1.0 + _rng.randf_range(-wobble, wobble)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y) * r)
	polygon(points, z)


## A straight stroke from `a` to `b`, like one brush mark or one stick.
## It can taper: `width_a` at the start, `width_b` at the end.
func stroke(a: Vector2, b: Vector2, width_a: float, width_b: float = -1.0, z: float = 0.0) -> void:
	if width_b < 0.0:
		width_b = width_a
	var side := (b - a).orthogonal().normalized()
	polygon(PackedVector2Array([
		a - side * width_a * 0.5, b - side * width_b * 0.5,
		b + side * width_b * 0.5, a + side * width_a * 0.5,
	]), z)


## A cut-out with a ripped edge: the sheet itself, plus a thin paler sheet
## peeking out behind it, which reads as the fibrous core of torn paper.
func torn_sheet(points: PackedVector2Array, z: float, rim_color: Color, rim_width: float) -> void:
	var sheet_color := color
	if rim_width > 0.0:
		color = rim_color
		polygon(PaperMesh.grow(points, rim_width, _rng), z - 0.012)
	color = sheet_color
	polygon(points, z)


## A four-cornered face whose colour fades from one edge to the other.
## Corners a, b get `color_ab`; corners c, d get `color_cd`. Used for mist.
func fade_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color_ab: Color, color_cd: Color) -> void:
	var corners := [a, b, c, a, c, d]
	var tints := [color_ab, color_ab, color_cd, color_ab, color_cd, color_cd]
	for i in 6:
		_st.set_color(tints[i])
		_st.set_normal(Vector3.BACK)
		_st.add_vertex(corners[i])


# --- Torn edges ----------------------------------------------------------------

## Returns a copy of an outline with every edge chopped into short pieces and
## nudged in and out, like the edge of torn paper. Keep `amount` well under
## `step` or the outline can cross itself.
## Pass closed = false for an open line (such as a hill's skyline) rather than
## a full outline.
static func tear(points: PackedVector2Array, step: float, amount: float,
		rng: RandomNumberGenerator, closed: bool = true) -> PackedVector2Array:
	var out := PackedVector2Array()
	var count := points.size()
	for i in count:
		var a := points[i]
		if not closed and i == count - 1:
			out.append(a)
			break
		var b := points[(i + 1) % count]
		var pieces := maxi(1, roundi(a.distance_to(b) / step))
		var normal := (b - a).orthogonal().normalized()
		for k in pieces:
			var push := rng.randf_range(-amount, amount) * (0.3 if k == 0 else 1.0)
			out.append(a.lerp(b, float(k) / pieces) + normal * push)
	return out


## Returns the outline pushed outward by roughly `amount` (unevenly, if an rng
## is given). Used for the pale rim of torn paper.
static func grow(points: PackedVector2Array, amount: float, rng: RandomNumberGenerator = null) -> PackedVector2Array:
	var count := points.size()
	var area := 0.0
	for i in count:
		area += points[i].cross(points[(i + 1) % count])
	var turn := 1.0 if area > 0.0 else -1.0
	var out := PackedVector2Array()
	for i in count:
		var before := points[(i - 1 + count) % count]
		var here := points[i]
		var after := points[(i + 1) % count]
		var n := ((here - before).normalized() + (after - here).normalized()).orthogonal()
		if n.length() < 0.001:
			n = (after - here).orthogonal()
		var push := amount * (rng.randf_range(0.35, 1.5) if rng else 1.0)
		out.append(here + n.normalized() * push * turn)
	return out


# --- Finishing -------------------------------------------------------------------

## Finishes the shape and returns it as a node you can add to the scene.
## `glow` above 0 makes the paper emit light (lanterns, windows).
func build(albedo: Color = Color.WHITE, glow: float = 0.0, unshaded: bool = false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = _st.commit()
	var mat := PaperMesh.material(albedo, glow, unshaded)
	if texture_scale > 0.0:
		mat.albedo_texture = PaperMesh.grain_texture()
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = texture_world
		mat.uv1_scale = Vector3.ONE * texture_scale
		if not unshaded and wrinkle_depth > 0.0:
			mat.normal_enabled = true
			mat.normal_texture = PaperMesh.crumple_texture()
			mat.normal_scale = wrinkle_depth
	instance.material_override = mat
	return instance


## The shared paper material: matte, visible from both sides, no shine.
static func material(albedo: Color = Color.WHITE, glow: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = albedo
		mat.emission_energy_multiplier = glow
	if albedo.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


## A see-through, unlit material for mist, halos and reflections.
## `additive` makes it brighten what is behind it (light), instead of covering it.
static func veil_material(additive: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return mat


## Finishes the shape as a veil (see veil_material). Use with fade_quad().
func build_veil(additive: bool = false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = _st.commit()
	instance.material_override = PaperMesh.veil_material(additive)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


# --- The paper textures (made once, in code, when first needed) ------------------

## Soft blotches and fibres that vary the paper's brightness a little.
static func grain_texture() -> ImageTexture:
	if _grain == null:
		var blotch := FastNoiseLite.new()
		blotch.seed = 11
		blotch.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		blotch.frequency = 0.02
		blotch.fractal_octaves = 3
		var fibre := FastNoiseLite.new()
		fibre.seed = 12
		fibre.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fibre.frequency = 0.22
		var low := blotch.get_seamless_image(256, 256)
		var high := fibre.get_seamless_image(256, 256)
		var image := Image.create(256, 256, true, Image.FORMAT_RGB8)
		for y in 256:
			for x in 256:
				var v := 0.76 + 0.17 * low.get_pixel(x, y).r + 0.07 * high.get_pixel(x, y).r
				image.set_pixel(x, y, Color(v, v, v))
		image.generate_mipmaps()
		_grain = ImageTexture.create_from_image(image)
	return _grain


## Crumple wrinkles: a "normal map", which tells the lights which way each
## tiny patch of paper is tilted.
static func crumple_texture() -> ImageTexture:
	if _crumple == null:
		var creases := FastNoiseLite.new()
		creases.seed = 5
		creases.noise_type = FastNoiseLite.TYPE_CELLULAR
		creases.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
		creases.frequency = 0.03
		creases.fractal_octaves = 2
		creases.fractal_gain = 0.45
		var image := creases.get_seamless_image(512, 512)
		image.bump_map_to_normal_map(5.0)
		image.generate_mipmaps()
		_crumple = ImageTexture.create_from_image(image)
	return _crumple


# --- Internals -------------------------------------------------------------------

func _shade(base: Color) -> Color:
	var shade := 1.0 - _rng.randf() * shade_jitter
	return Color(base.r * shade, base.g * shade, base.b * shade, base.a)


func _emit(a: Vector3, b: Vector3, c: Vector3, outward: Vector3, tint: Color) -> void:
	var normal := (c - a).cross(b - a).normalized()
	if outward != Vector3.ZERO and normal.dot(outward) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	for vertex: Vector3 in [a, b, c]:
		_st.set_color(tint)
		_st.set_normal(normal)
		_st.add_vertex(vertex)


static func _middle(ring: PackedVector3Array) -> Vector3:
	var sum := Vector3.ZERO
	for p: Vector3 in ring:
		sum += p
	return sum / ring.size()


func _cap(ring: PackedVector3Array, outward: Vector3) -> void:
	var middle := PaperMesh._middle(ring)
	for i in ring.size():
		tri(middle, ring[i], ring[(i + 1) % ring.size()], outward)
