class_name WaterFx
extends RefCounted
## Water for the canals and the river: a dark glossy surface, and splashes.
## A splash is a crown of round beads flung up and outward that arc over
## and fall back, and a short pale jet: soft drops, never hard rectangles.
## Usage: WaterFx.splash(parent, position, strength)

static var _bead: GradientTexture2D


## A one-shot splash at `at` (on the water's surface). `strength` 0.3 is a
## step in a puddle, 1 a fall from a height.
static func splash(parent: Node, at: Vector3, strength: float = 1.0) -> void:
	var beads := CPUParticles3D.new()
	beads.emitting = false
	beads.one_shot = true
	beads.explosiveness = 0.85
	beads.amount = int(lerpf(8.0, 46.0, clampf(strength, 0.0, 1.5) / 1.5))
	beads.lifetime = 0.7
	beads.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	beads.emission_box_extents = Vector3(0.25, 0.02, 0.3) * (0.6 + strength * 0.6)
	beads.direction = Vector3.UP
	beads.spread = 38.0
	beads.gravity = Vector3(0.0, -13.0, 0.0)
	beads.initial_velocity_min = 1.2 + strength * 1.2
	beads.initial_velocity_max = 2.4 + strength * 3.0
	beads.scale_amount_min = 0.6
	beads.scale_amount_max = 1.4
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.35))
	beads.scale_amount_curve = shrink
	var bead := QuadMesh.new()
	bead.size = Vector2(0.05, 0.05)
	bead.material = bead_material(Color(0.72, 0.8, 0.95, 0.75))
	beads.mesh = bead
	beads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(beads)
	beads.global_position = at + Vector3(0.0, 0.03, 0.0)
	beads.emitting = true
	beads.finished.connect(beads.queue_free)
	# The jet: a few pale streaks shooting straight up.
	var jet := CPUParticles3D.new()
	jet.emitting = false
	jet.one_shot = true
	jet.explosiveness = 0.9
	jet.amount = int(4 + strength * 6)
	jet.lifetime = 0.45
	jet.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	jet.emission_box_extents = Vector3(0.12, 0.02, 0.15)
	jet.direction = Vector3.UP
	jet.spread = 8.0
	jet.gravity = Vector3(0.0, -14.0, 0.0)
	jet.initial_velocity_min = 2.0 + strength * 1.5
	jet.initial_velocity_max = 3.0 + strength * 2.5
	var thin := Curve.new()
	thin.add_point(Vector2(0.0, 1.0))
	thin.add_point(Vector2(1.0, 0.2))
	jet.scale_amount_curve = thin
	var streak := QuadMesh.new()
	streak.size = Vector2(0.035, 0.22)
	var look := bead_material(Color(0.8, 0.86, 1.0, 0.45))
	look.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	look.billboard_keep_scale = true
	streak.material = look
	jet.mesh = streak
	jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(jet)
	jet.global_position = at + Vector3(0.0, 0.05, 0.0)
	jet.emitting = true
	jet.finished.connect(jet.queue_free)


## A soft round bead of water (see-through at its rim).
static func bead_material(tint: Color) -> StandardMaterial3D:
	if _bead == null:
		var rim := Gradient.new()
		rim.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
		rim.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
		_bead = GradientTexture2D.new()
		_bead.gradient = rim
		_bead.fill = GradientTexture2D.FILL_RADIAL
		_bead.fill_from = Vector2(0.5, 0.5)
		_bead.fill_to = Vector2(1.0, 0.5)
		_bead.width = 64
		_bead.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	mat.albedo_texture = _bead
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.disable_fog = true
	return mat


## A flat sheet of dark, glossy water between two x positions, from `back`
## to `front` (z), at height `y`. It catches the lanterns' light like a
## mirror. Built in short lengths (the 8-lights-per-mesh limit).
static func surface(parent: Node3D, left: float, right: float, y: float, back: float, front: float,
		tint: Color = Color(0.035, 0.045, 0.085)) -> void:
	var x := left
	while x < right - 0.01:
		var x1 := minf(x + 5.0, right)
		var b := PaperMesh.new(int(x * 7.0) + 3)
		b.shade_jitter = 0.0
		b.texture_scale = 0.0
		b.color = tint
		b.quad(Vector3(x, y, back), Vector3(x1, y, back), Vector3(x1, y, front), Vector3(x, y, front), Vector3.UP)
		var sheet := b.build()
		var mat := sheet.material_override as StandardMaterial3D
		mat.roughness = 0.08
		mat.metallic_specular = 0.9
		mat.metallic = 0.2
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(sheet)
		x = x1
