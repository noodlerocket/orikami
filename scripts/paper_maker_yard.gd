class_name PaperMakerYard
extends Node3D
## The yard in front of the Paper-Maker's workshop, in Well Square: fresh
## sheets of washi hung on lines to dry (each one sways and lifts in the
## wind on its own), a drying board leaning on the wall with sheets pressed
## to it, the vat she pulls paper from, bundles of finished paper, and the
## shrine at her door where the Ronin first rests.
## Origin: the street at the left end of the yard. Everything stands behind
## the path, so nothing is in his way.

## Width of the yard (metres along the street).
@export var width := 9.0

var shrine: RestShrine


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1607
	_build(rng)


func _build(rng: RandomNumberGenerator) -> void:
	# Two drying lines between posts, sheets pegged along them.
	for line: Array in [[0.6, 4.4, 2.35, -2.2], [4.9, 8.4, 2.2, -1.6]]:
		_drying_line(rng, line[0], line[1], line[2], line[3])

	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.18
	# The vat: a wooden tub of milky water.
	b.color = Scenery.WOOD.darkened(0.2)
	b.frustum(10, Vector2(0.62, 0.42), Vector2(0.68, 0.46), 0.7, Vector3(6.6, 0.0, -2.9))
	b.color = PaperMesh.TIMBER
	b.frustum(10, Vector2(0.7, 0.48), Vector2(0.7, 0.48), 0.06, Vector3(6.6, 0.32, -2.9))
	b.frustum(10, Vector2(0.7, 0.48), Vector2(0.7, 0.48), 0.06, Vector3(6.6, 0.6, -2.9))
	add_child(b.build())
	var water := PaperMesh.new(rng.randi())
	water.shade_jitter = 0.0
	water.color = Color(0.62, 0.64, 0.68)
	water.quad(Vector3(6.0, 0.66, -2.5), Vector3(7.2, 0.66, -2.5), Vector3(7.2, 0.66, -3.3), Vector3(6.0, 0.66, -3.3), Vector3.UP)
	var milk := water.build()
	(milk.material_override as StandardMaterial3D).roughness = 0.25
	add_child(milk)
	# The mould frame (su) resting across the vat. (She works down by the
	# river now, PaperMaker in river_bridge.gd: this is her home.)
	var frame := PaperMesh.new(rng.randi())
	frame.color = Color(0.5, 0.44, 0.32)
	frame.box(Vector3(6.6, 0.72, -2.9), Vector3(1.1, 0.04, 0.6))
	frame.color = PaperMesh.WASHI.darkened(0.12)
	frame.box(Vector3(6.6, 0.745, -2.9), Vector3(0.95, 0.01, 0.48))
	add_child(frame.build())

	# A drying board leaning on the workshop wall, sheets pressed flat on it.
	var board := PaperMesh.new(rng.randi())
	board.shade_jitter = 0.12
	board.color = Scenery.WOOD
	board.quad(Vector3(2.0, 0.0, -3.55), Vector3(3.3, 0.0, -3.55), Vector3(3.3, 2.5, -4.1), Vector3(2.0, 2.5, -4.1),
			Vector3(0.0, 0.2, 1.0))
	board.color = PaperMesh.WASHI.darkened(0.05)
	for k in 3:
		var y0 := 0.25 + k * 0.75
		var lean := Vector3(0.0, 0.0, -0.22 * (y0 + 0.65) / 2.5)
		board.quad(Vector3(2.12, y0, -3.54) + Vector3(0, 0, -0.22 * y0 / 2.5), Vector3(3.18, y0, -3.54) + Vector3(0, 0, -0.22 * y0 / 2.5),
				Vector3(3.18, y0 + 0.65, -3.54) + lean, Vector3(2.12, y0 + 0.65, -3.54) + lean, Vector3(0.0, 0.2, 1.0))
	add_child(board.build())

	# Bundles of finished paper, tied with cord, stacked by the door.
	var stack := PaperMesh.new(rng.randi())
	stack.shade_jitter = 0.1
	for k in 4:
		stack.color = PaperMesh.WASHI.darkened(rng.randf_range(0.05, 0.2))
		var at := Vector3(8.3 + (k % 2) * 0.5, 0.13 + (k / 2) * 0.26, -3.0 + rng.randf_range(-0.05, 0.05))
		stack.box(at, Vector3(0.45, 0.24, 0.34))
		stack.color = Scenery.CRIMSON.darkened(0.2)
		stack.box(at + Vector3(0.0, 0.0, 0.0), Vector3(0.04, 0.25, 0.35))
	add_child(stack.build())

	# The shrine at her door: where he rests first.
	shrine = RestShrine.new()
	shrine.shrine_id = "paper_maker"
	shrine.position = Vector3(width - 1.1, 0.0, -0.9)
	shrine.scale = Vector3.ONE * 1.45
	add_child(shrine)


## A rope between two posts with fresh sheets pegged along it. Each sheet is
## its own piece hanging from its pegs, so the wind lifts each one a little
## differently.
func _drying_line(rng: RandomNumberGenerator, from: float, to: float, height: float, z: float) -> void:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.2
	b.color = PaperMesh.TIMBER
	for px: float in [from, to]:
		b.box(Vector3(px, height * 0.5 + 0.1, z), Vector3(0.08, height + 0.2, 0.08))
	b.color = Color(0.52, 0.47, 0.4)
	b.stroke(Vector2(from, height), Vector2(to, height - 0.05), 0.04, 0.04, z + 0.02)
	add_child(b.build())
	var x := from + 0.25
	while x < to - 0.7:
		var wide := rng.randf_range(0.5, 0.68)
		var tall := rng.randf_range(0.7, 0.9)
		var hang := Node3D.new()
		hang.position = Vector3(x + wide * 0.5, height - 0.02, z + 0.03)
		add_child(hang)
		var sheet := PaperMesh.new(rng.randi())
		sheet.shade_jitter = 0.06
		sheet.color = PaperMesh.WASHI.darkened(rng.randf_range(0.0, 0.12))
		# A soft, slightly uneven deckle edge at the bottom.
		var outline := PackedVector2Array([Vector2(-wide * 0.5, 0.0), Vector2(wide * 0.5, 0.0)])
		var by := -tall
		outline.append(Vector2(wide * 0.5, by + rng.randf_range(-0.03, 0.03)))
		for k in 5:
			outline.append(Vector2(wide * 0.5 - wide * (k + 1) / 6.0, by + rng.randf_range(-0.03, 0.02)))
		outline.append(Vector2(-wide * 0.5, by))
		sheet.polygon(outline)
		# Two wooden pegs.
		sheet.color = Scenery.WOOD
		for side: float in [-0.32, 0.32]:
			sheet.rect(Vector2(side * wide, -0.04), Vector2(0.04, 0.12), 0.01)
		var mesh := sheet.build()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hang.add_child(mesh)
		Scenery.windswept(hang, 0.09, rng)
		x += wide + rng.randf_range(0.12, 0.3)
