class_name InkCurtain
extends Node3D
## Ink pouring from a height (Sumi Marsh: the broken aqueduct, a broken
## gutter): a falling sheet (shaders/ink_pour.gdshader) from its lip at the
## origin down to `bottom` (local y), dark froth and drops where it lands, a
## pouring sound. Under it, unwaxed, he is pressed down hard (the Rain
## weighs paper down: like the town's sluices); waxed (the Wax Coat), it
## runs off him in a spray of beads off his hat.

## How wide the pour is (m) and how far it falls (to local y `bottom`).
@export var width := 2.0
@export var bottom := -6.0
## How hard it presses him down (m/s/s), unwaxed.
@export var press := 70.0

var _ronin: Ronin
var _spray_clock := 0.0


func _ready() -> void:
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/ink_pour.gdshader")
	for k in 3:
		var z := -0.7 + k * 0.7
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rows := 10
		for r in rows:
			for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
				var t := float(r + corner[1]) / rows
				var across: float = corner[0]
				var wide := width * (0.92 + 0.2 * t)
				st.set_uv(Vector2(across, t))
				st.add_vertex(Vector3(-wide * 0.5 + across * wide + 0.08 * sin(t * 3.0 + k), lerpf(0.0, bottom, t), z))
		var sheet := MeshInstance3D.new()
		sheet.mesh = st.commit()
		var mine := look.duplicate() as ShaderMaterial
		mine.set_shader_parameter(&"speed", 1.6 + k * 0.2)
		sheet.material_override = mine
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sheet)
	# Drops of ink thrown up where it lands.
	var spray := CPUParticles3D.new()
	spray.amount = 36
	spray.lifetime = 0.8
	spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spray.emission_box_extents = Vector3(width * 0.45, 0.05, 1.0)
	spray.position = Vector3(0.0, bottom + 0.05, 0.0)
	spray.direction = Vector3.UP
	spray.spread = 40.0
	spray.gravity = Vector3(0.0, -9.0, 0.0)
	spray.initial_velocity_min = 1.0
	spray.initial_velocity_max = 2.4
	spray.scale_amount_min = 0.5
	spray.scale_amount_max = 1.2
	var drop := QuadMesh.new()
	drop.size = Vector2(0.07, 0.07)
	drop.material = PaperMesh.soft_ink(Color(0.04, 0.04, 0.06, 0.9))
	spray.mesh = drop
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spray)
	Sound.place_loop(self, "sluice_pour.ogg", Vector3(0.0, bottom * 0.5, 0.0), -10.0, 10.0)


func _physics_process(delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position - global_position
	at.z = 0.0
	if absf(at.x) < width * 0.5 and at.y < 0.0 and at.y > bottom - 1.5:
		if not _ronin.has_wax:
			_ronin.push.y -= press
		_spray_clock += delta
		if _spray_clock > (0.12 if not _ronin.has_wax else 0.07):
			_spray_clock = 0.0
			WaterFx.splash(get_parent(), _ronin.global_position + Vector3(0.0, 1.55, 0.0), 0.35 if not _ronin.has_wax else 0.5)
