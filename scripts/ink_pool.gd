class_name InkPool
extends Node3D
## A pool of glossy black ink spreading on the stones, with a ragged edge:
## the Hannya sinks into one and rises out of another. It spreads (open),
## holds, then shrinks away (close) and frees itself.
##
## Origin: on the ground at its middle.

## How wide it spreads (metres across).
var size := 2.4

var _mesh: MeshInstance3D
var _look: StandardMaterial3D
var _splash: CPUParticles3D


func _ready() -> void:
	# A ragged blob, lying flat.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var fan := SurfaceTool.new()
	fan.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := 28
	var edge: Array[Vector3] = []
	for i in points:
		var angle := TAU * i / points
		var reach := 0.5 * (0.78 + rng.randf_range(0.0, 0.22) + 0.1 * sin(angle * 3.0 + rng.randf() * 2.0))
		edge.append(Vector3(cos(angle) * reach, 0.0, sin(angle) * reach * 0.55))
	for i in points:
		fan.set_normal(Vector3.UP)
		fan.add_vertex(Vector3.ZERO)
		fan.add_vertex(edge[(i + 1) % points])
		fan.add_vertex(edge[i])
	_mesh = MeshInstance3D.new()
	_mesh.mesh = fan.commit()
	_look = StandardMaterial3D.new()
	_look.albedo_color = Color(0.015, 0.015, 0.03)
	_look.roughness = 0.08
	_look.metallic_specular = 1.0
	_look.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh.material_override = _look
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.position.y = 0.025
	_mesh.scale = Vector3.ONE * 0.01
	add_child(_mesh)
	_splash = CPUParticles3D.new()
	_splash.emitting = false
	_splash.one_shot = true
	_splash.explosiveness = 0.85
	_splash.amount = 26
	_splash.lifetime = 0.7
	_splash.direction = Vector3.UP
	_splash.spread = 35.0
	_splash.initial_velocity_min = 3.0
	_splash.initial_velocity_max = 7.0
	_splash.gravity = Vector3(0.0, -18.0, 0.0)
	_splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_splash.emission_box_extents = Vector3(size * 0.3, 0.05, 0.3)
	_splash.scale_amount_min = 0.6
	_splash.scale_amount_max = 1.6
	var bead := QuadMesh.new()
	bead.size = Vector2(0.1, 0.14)
	bead.material = PaperMesh.soft_ink(Color(0.02, 0.02, 0.05))
	_splash.mesh = bead
	add_child(_splash)


## Spreads out over `time` seconds.
func open(time: float) -> void:
	var t := create_tween()
	t.tween_property(_mesh, "scale", Vector3.ONE * size, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Throws drops of ink up out of it.
func splash() -> void:
	_splash.restart()


## Shrinks away over `time` seconds after `delay`, then frees itself.
func close(delay: float, time: float) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(_mesh, "scale", Vector3.ONE * 0.01, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_interval(0.8)
	t.tween_callback(queue_free)
