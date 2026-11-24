class_name PaperFan
extends Node3D
## A folding paper fan (sensu), folded in code: ten panels of washi between
## dark bamboo ribs, every other panel a shade darker so the folds read, a
## faded vermilion sun across the middle panels. `open` (0 to 1) spreads the
## panels round the pivot like a real fan, from shut (one stick) to a half
## circle. It lies in its own x-y plane, the pivot at its origin, spreading
## from +x (open 0) round toward +y.

const PANELS := 10
const SPREAD := deg_to_rad(160.0)
const RADIUS := 0.4
const INNER := 0.06

## How far it is spread, 0 (shut) to 1 (wide open).
var open := 0.0:
	set(value):
		open = value
		_spread()

var _panels: Array[Node3D] = []


func _ready() -> void:
	var step := SPREAD / PANELS
	for i in PANELS:
		var b := PaperMesh.new(31 + i)
		b.shade_jitter = 0.05
		var c0 := Vector2(cos(0.0), sin(0.0))
		var c1 := Vector2(cos(step), sin(step))
		b.color = Color(0.86, 0.82, 0.74) if i % 2 == 0 else Color(0.74, 0.7, 0.63)
		# The panel, both faces.
		for face: float in [1.0, -1.0]:
			b.quad(Vector3(c0.x * INNER, c0.y * INNER, 0.0), Vector3(c1.x * INNER, c1.y * INNER, 0.0),
					Vector3(c1.x * RADIUS, c1.y * RADIUS, 0.0), Vector3(c0.x * RADIUS, c0.y * RADIUS, 0.0), Vector3(0.0, 0.0, face))
		# The sun: a band of faded vermilion across the middle panels.
		if i >= 3 and i <= 6:
			b.color = Color(0.62, 0.24, 0.18)
			for face: float in [1.0, -1.0]:
				var z := 0.002 * face
				b.quad(Vector3(c0.x * 0.2, c0.y * 0.2, z), Vector3(c1.x * 0.2, c1.y * 0.2, z),
						Vector3(c1.x * 0.31, c1.y * 0.31, z), Vector3(c0.x * 0.31, c0.y * 0.31, z), Vector3(0.0, 0.0, face))
		# Its rib.
		var rib := PaperMesh.new(70 + i)
		rib.color = Color(0.2, 0.14, 0.1)
		rib.stroke(Vector2.ZERO, c0 * (RADIUS + 0.01), 0.018, 0.01, 0.004)
		rib.stroke(Vector2.ZERO, c0 * (RADIUS + 0.01), 0.018, 0.01, -0.004)
		var panel := Node3D.new()
		var mesh := b.build()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		panel.add_child(mesh)
		var rib_mesh := rib.build()
		rib_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		panel.add_child(rib_mesh)
		add_child(panel)
		_panels.append(panel)
	# The guard sticks and the rivet at the pivot.
	var guard := PaperMesh.new(5)
	guard.color = Color(0.16, 0.11, 0.08)
	guard.box(Vector3(0.0, 0.0, 0.0), Vector3(0.04, 0.04, 0.03))
	add_child(guard.build())
	_spread()


func _spread() -> void:
	var step := SPREAD / PANELS
	for i in _panels.size():
		_panels[i].rotation.z = i * step * open
