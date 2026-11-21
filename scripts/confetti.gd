class_name Confetti
extends RefCounted
## A one-shot burst of paper scraps, used when an enemy is cut apart.
## Usage: Confetti.burst(get_parent(), global_position, 48)


static func burst(parent: Node, at: Vector3, amount: int = 48) -> void:
	var scraps := CPUParticles3D.new()
	scraps.emitting = false
	scraps.one_shot = true
	scraps.explosiveness = 1.0
	scraps.amount = amount
	scraps.lifetime = 1.4
	scraps.direction = Vector3.UP
	scraps.spread = 180.0
	scraps.initial_velocity_min = 2.5
	scraps.initial_velocity_max = 8.0
	scraps.gravity = Vector3(0.0, -13.0, 0.0)
	scraps.damping_min = 1.0
	scraps.damping_max = 2.5
	scraps.angle_min = 0.0
	scraps.angle_max = 360.0
	scraps.angular_velocity_min = -500.0
	scraps.angular_velocity_max = 500.0
	scraps.scale_amount_min = 0.6
	scraps.scale_amount_max = 1.6

	# Each scrap picks a random colour from this strip of paper colours.
	var colors := Gradient.new()
	colors.set_color(0, Color(0.55, 0.6, 0.74))
	colors.set_color(1, PaperMesh.WASHI)
	colors.add_point(0.35, Color(0.2, 0.22, 0.36))
	colors.add_point(0.7, Color(0.75, 0.78, 0.86))
	scraps.color_initial_ramp = colors

	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.13, 0.1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	scrap.material = mat
	scraps.mesh = scrap

	parent.add_child(scraps)
	scraps.global_position = at
	scraps.emitting = true
	scraps.finished.connect(scraps.queue_free)
