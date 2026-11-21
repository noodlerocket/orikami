class_name InkBlade
extends Node3D
## A crescent blade the Hannya flings from her sleeve: pale paper, edged
## and trailed with ink (pale so it reads against the night). It flies
## straight across the courtyard at one height. Parried, it bursts into ink
## and costs her posture; otherwise it cuts him. It leaves a thin smear
## behind it so its path reads.

var direction := 1.0
var speed := 9.5
var target: Ronin
var boss: HannyaBoss
var arena := Vector2(47.0, 63.5)

var _blade: MeshInstance3D
var _trail: CPUParticles3D
var _done := false


func _ready() -> void:
	# The crescent: a strip curved like a new moon, drawn fully on.
	var strip := SurfaceTool.new()
	strip.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 16
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var across: float = corner[1]
			var angle := lerpf(deg_to_rad(-70.0), deg_to_rad(70.0), t)
			var radius := 0.75 - 0.22 * sin(PI * t) * (1.0 - across)
			strip.set_uv(Vector2(t, across))
			strip.add_vertex(Vector3(cos(angle) * radius - 0.55, sin(angle) * radius, 0.0))
	_blade = MeshInstance3D.new()
	_blade.mesh = strip.commit()
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/slash_sweep.gdshader")
	look.set_shader_parameter(&"head", 1.05)
	look.set_shader_parameter(&"tail", -0.1)
	look.set_shader_parameter(&"tint", Color(0.9, 0.88, 0.84, 0.95))
	_blade.material_override = look
	_blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_blade.scale = Vector3(direction, 1.0, 1.0)
	add_child(_blade)
	_trail = CPUParticles3D.new()
	_trail.amount = 24
	_trail.lifetime = 0.35
	_trail.local_coords = false
	_trail.gravity = Vector3(0.0, -1.5, 0.0)
	_trail.initial_velocity_max = 0.2
	_trail.scale_amount_min = 0.6
	_trail.scale_amount_max = 1.2
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	_trail.scale_amount_curve = shrink
	var bead := QuadMesh.new()
	bead.size = Vector2(0.1, 0.1)
	bead.material = PaperMesh.soft_ink(Color(0.04, 0.04, 0.08))
	_trail.mesh = bead
	add_child(_trail)


func _process(delta: float) -> void:
	if _done:
		return
	global_position.x += direction * speed * delta
	_blade.rotation.z = sin(Time.get_ticks_msec() * 0.02) * 0.08
	if global_position.x < arena.x - 1.0 or global_position.x > arena.y + 1.0:
		queue_free()
		return
	if target and is_instance_valid(target):
		var dx := absf(target.global_position.x - global_position.x)
		var dy := global_position.y - target.global_position.y
		if dx < 0.5 and dy > 0.0 and dy < 1.7:
			_done = true
			if target.receive_strike(1, global_position - Vector3(direction * 1.0, 0.0, 0.0)):
				if boss and is_instance_valid(boss):
					boss.projectile_parried(1)
			_burst()


func _burst() -> void:
	_blade.visible = false
	_trail.emitting = false
	Confetti.burst(get_parent(), global_position, 14)
	await get_tree().create_timer(0.4).timeout
	queue_free()
