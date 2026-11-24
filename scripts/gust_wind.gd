class_name GustWind
extends Node3D
## What the Fan Gust looks like (made each time, top level, then gone):
##  - ribbons of wind: three long pale strips (the sword swoosh's shader),
##    rippling and ending in a curl, like the wind lines of an ukiyo-e print,
##    drawn on from the fan outward as the gust rolls, then wiped away;
##  - the fan's sweep: a pale arc where it was flung open;
##  - dust rolling away along the ground (on the ground only);
##  - paper flecks and faded petals tumbling and swirling on it.
## `direction`: +x / -x along the street, or DOWN (under him, in the air).
## `reach`: how far it goes.

var direction := Vector3.RIGHT
var reach := 8.5
var grounded := true

var _age := 0.0
var _strips: Array[ShaderMaterial] = []
const LIFE := 0.75


func _ready() -> void:
	top_level = true
	var along := direction
	var side := Vector3.UP if absf(along.y) < 0.5 else Vector3(1.0, 0.0, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Three ribbons at different heights (or, downward, either side), each
	# its own length, ripple and curl.
	for k in 3:
		var offset := (k - 1) * 0.42 + rng.randf_range(-0.1, 0.1)
		var length := reach * rng.randf_range(0.7, 1.0)
		var look := ShaderMaterial.new()
		look.shader = preload("res://shaders/slash_sweep.gdshader")
		look.set_shader_parameter(&"head", 0.0)
		look.set_shader_parameter(&"tail", 0.0)
		look.set_shader_parameter(&"tint", Color(0.93, 0.92, 0.88, 0.62 - absf(k - 1) * 0.12))
		_strips.append(look)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var steps := 40
		var points: Array[Vector3] = []
		var widths: Array[float] = []
		var curl_from := 0.78
		var phase := rng.randf() * TAU
		for i in steps + 1:
			var t := float(i) / steps
			var p: Vector3
			if t < curl_from:
				# Rippling out along the gust.
				var s := t / curl_from * length * 0.85
				p = along * s + side * (offset + sin(phase + s * 1.4) * 0.12 * (0.4 + s / length))
			else:
				# The curl at its head: round and in on itself.
				var c := (t - curl_from) / (1.0 - curl_from)
				var base := along * length * 0.85 + side * (offset + sin(phase + length * 0.85 * 1.4) * 0.12)
				var radius := 0.32 * (1.0 - c * 0.6)
				var a := c * TAU * 0.85
				p = base + along * sin(a) * radius + side * (1.0 - cos(a)) * radius * (1.0 if k != 0 else -1.0)
			points.append(p)
			widths.append(lerpf(0.03, 0.11, sin(t * PI)) * (1.0 if k == 1 else 0.75))
		for i in steps:
			var a0 := points[i]
			var a1 := points[i + 1]
			var dir := (a1 - a0).normalized()
			var n0 := Vector3(-dir.y, dir.x, 0.0) * widths[i]
			var n1 := Vector3(-dir.y, dir.x, 0.0) * widths[i + 1]
			var u0 := float(i) / steps
			var u1 := float(i + 1) / steps
			for corner: Array in [[a0 - n0, u0, 0.0], [a1 - n1, u1, 0.0], [a1 + n1, u1, 1.0], [a0 - n0, u0, 0.0], [a1 + n1, u1, 1.0], [a0 + n0, u0, 1.0]]:
				st.set_uv(Vector2(corner[1], corner[2]))
				st.add_vertex(corner[0] + Vector3(0.0, 0.0, 0.25 + k * 0.05))
		var mesh := MeshInstance3D.new()
		mesh.mesh = st.commit()
		mesh.material_override = look
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
	# The fan's sweep: a pale arc round where it opened.
	var arc := ShaderMaterial.new()
	arc.shader = preload("res://shaders/slash_sweep.gdshader")
	arc.set_shader_parameter(&"tint", Color(0.95, 0.94, 0.9, 0.5))
	_strips.append(arc)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var turn := atan2(along.y, along.x)
	for i in 16:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / 16.0
			var a := turn + lerpf(1.3, -1.1, t) * (1.0 if along.x >= 0.0 else -1.0)
			var r := lerpf(0.32, 0.6, corner[1])
			st.set_uv(Vector2(t, corner[1]))
			st.add_vertex(Vector3(cos(a) * r, sin(a) * r, 0.3))
	var sweep := MeshInstance3D.new()
	sweep.mesh = st.commit()
	sweep.material_override = arc
	sweep.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sweep)
	# Paper flecks and faded petals, tumbling on the wind and curling round.
	var flecks := CPUParticles3D.new()
	flecks.one_shot = true
	flecks.explosiveness = 0.6
	flecks.amount = 28
	flecks.lifetime = 1.1
	flecks.local_coords = false
	flecks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flecks.emission_sphere_radius = 0.35
	flecks.direction = along
	flecks.spread = 18.0
	flecks.gravity = Vector3(0.0, -0.8, 0.0)
	flecks.initial_velocity_min = 6.0
	flecks.initial_velocity_max = 12.0
	flecks.damping_min = 7.0
	flecks.damping_max = 11.0
	flecks.tangential_accel_min = -5.0
	flecks.tangential_accel_max = 5.0
	flecks.angular_velocity_min = -720.0
	flecks.angular_velocity_max = 720.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(0.7, 0.8))
	shrink.add_point(Vector2(1.0, 0.0))
	flecks.scale_amount_curve = shrink
	var tones := Gradient.new()
	tones.set_color(0, Color(0.88, 0.85, 0.78))
	tones.set_color(1, Color(0.86, 0.66, 0.66))
	tones.add_point(0.5, Color(0.7, 0.3, 0.24))
	flecks.color_initial_ramp = tones
	var fleck := QuadMesh.new()
	fleck.size = Vector2(0.06, 0.04)
	var washi := StandardMaterial3D.new()
	washi.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	washi.vertex_color_use_as_albedo = true
	washi.cull_mode = BaseMaterial3D.CULL_DISABLED
	washi.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fleck.material = washi
	flecks.mesh = fleck
	flecks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flecks)
	flecks.position = along * 0.4
	flecks.emitting = true
	# Dust rolling away along the ground.
	if grounded and absf(along.y) < 0.5:
		var dust := CPUParticles3D.new()
		dust.one_shot = true
		dust.explosiveness = 0.5
		dust.amount = 16
		dust.lifetime = 0.9
		dust.local_coords = false
		dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		dust.emission_box_extents = Vector3(0.6, 0.05, 0.6)
		dust.direction = along + Vector3(0.0, 0.15, 0.0)
		dust.spread = 10.0
		dust.gravity = Vector3.ZERO
		dust.initial_velocity_min = 4.0
		dust.initial_velocity_max = 9.0
		dust.damping_min = 6.0
		dust.damping_max = 9.0
		var grow := Curve.new()
		grow.add_point(Vector2(0.0, 0.3))
		grow.add_point(Vector2(0.4, 1.0))
		grow.add_point(Vector2(1.0, 0.0))
		dust.scale_amount_curve = grow
		var puff := QuadMesh.new()
		puff.size = Vector2(0.7, 0.5)
		puff.material = PaperMesh.soft_ink(Color(0.45, 0.43, 0.48, 0.35))
		dust.mesh = puff
		dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dust)
		dust.position = Vector3(0.0, -0.85, 0.0) + along * 0.6
		dust.emitting = true


func _process(delta: float) -> void:
	_age += delta
	var u := _age / LIFE
	# The ribbons: drawn on out to their curls, then wiped from the fan end.
	for i in _strips.size():
		var lag := 0.0 if i == _strips.size() - 1 else i * 0.06
		var v := clampf(u - lag, 0.0, 1.0)
		var quick := 2.2 if i == _strips.size() - 1 else 1.0
		_strips[i].set_shader_parameter(&"head", clampf(v * 2.6 * quick, 0.0, 1.1))
		_strips[i].set_shader_parameter(&"tail", clampf((v - 0.3) * 1.9 * quick, 0.0, 1.1))
	if _age > 1.4:
		queue_free()
