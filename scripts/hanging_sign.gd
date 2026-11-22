class_name HangingSign
extends Node3D
## A shop sign: a wooden board hanging on two short chains from a timber
## bracket that reaches out over the street from the shop's front. It swings in the wind, and
## a cut (or brushing past it on a jump) sets it swinging hard; it creaks
## and settles. The board is painted with the shop's mark.
## Origin: the street, under where the sign hangs.

## Height of the bracket: the shop's porch beam it comes out from.
@export var height := 4.3
## Depth of the shop front the bracket comes out of.
@export var wall_z := -2.8
## Depth the sign hangs at (in reach of the sword: near the path).
@export var hang_z := -0.75
## The shop's mark: 0 a ring, 1 a brushed character, 2 a sake gourd.
@export var mark := 0
## Size of the board.
@export var board := Vector2(0.95, 0.6)

var ronin: Ronin

var _hang: Node3D
var _angle := 0.0
var _spin := 0.0
var _phase := 0.0
var _brushed := false


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 23.0)
	_phase = rng.randf() * TAU
	_build(rng)


func _build(rng: RandomNumberGenerator) -> void:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.2
	b.color = PaperMesh.TIMBER
	# The bracket: a beam out from the wall, and a brace under it back to the wall.
	var length := hang_z - wall_z + 0.15
	b.box(Vector3(0.0, height, wall_z + length * 0.5), Vector3(0.08, 0.09, length))
	# A short crossbar at its end, the board's two chains hang from it.
	b.box(Vector3(0.0, height - 0.02, hang_z), Vector3(board.x * 0.86, 0.05, 0.05))
	var brace := PaperMesh.new(rng.randi())
	brace.color = PaperMesh.TIMBER
	for k in 6:
		var t0 := k / 6.0
		var t1 := (k + 1) / 6.0
		var p0 := Vector3(0.0, height - 0.75 + 0.7 * t0, wall_z + (length * 0.6) * t0)
		var p1 := Vector3(0.0, height - 0.75 + 0.7 * t1, wall_z + (length * 0.6) * t1)
		brace.box((p0 + p1) * 0.5, Vector3(0.06, absf(p1.y - p0.y) + 0.05, absf(p1.z - p0.z) + 0.05))
	add_child(brace.build())
	add_child(b.build())

	_hang = Node3D.new()
	_hang.position = Vector3(0.0, height - 0.05, hang_z)
	add_child(_hang)
	var sign := PaperMesh.new(rng.randi())
	sign.shade_jitter = 0.14
	sign.color = PaperMesh.SUMI.lightened(0.18)
	for side: float in [-1.0, 1.0]:  # the two chains
		sign.box(Vector3(side * board.x * 0.38, -0.12, 0.0), Vector3(0.02, 0.24, 0.02))
	sign.color = Scenery.WOOD.darkened(0.1)
	sign.box(Vector3(0.0, -0.24 - board.y * 0.5, 0.0), Vector3(board.x, board.y, 0.06))
	sign.color = Scenery.WOOD.lightened(0.15)
	sign.box(Vector3(0.0, -0.24 - board.y * 0.5, 0.0), Vector3(board.x - 0.08, board.y - 0.08, 0.07))
	# The shop's mark in ink: a few broad brush strokes, or a ring.
	sign.color = PaperMesh.SUMI
	var middle := Vector2(0.0, -0.24 - board.y * 0.5)
	if mark == 0:
		for k in 14:
			var a0 := TAU * k / 14.0
			var a1 := TAU * (k + 0.8) / 14.0
			var r := board.y * 0.3
			sign.stroke(middle + Vector2(cos(a0), sin(a0)) * r, middle + Vector2(cos(a1), sin(a1)) * r, 0.05, 0.035, 0.04)
	elif mark == 2:
		# A gourd (a sake shop): two rounds, a waist, a cord.
		sign.ellipse(middle + Vector2(0.0, -0.08), Vector2(0.13, 0.12), 12, 0.04)
		sign.ellipse(middle + Vector2(0.0, 0.1), Vector2(0.085, 0.08), 12, 0.04)
		sign.stroke(middle + Vector2(-0.02, 0.2), middle + Vector2(0.03, 0.25), 0.03, 0.02, 0.041)
	else:
		sign.stroke(middle + Vector2(-0.28, 0.12), middle + Vector2(0.28, 0.1), 0.07, 0.04, 0.04)
		sign.stroke(middle + Vector2(0.0, 0.2), middle + Vector2(0.02, -0.2), 0.06, 0.03, 0.04)
		sign.stroke(middle + Vector2(-0.18, -0.06), middle + Vector2(0.2, -0.14), 0.05, 0.03, 0.04)
	var mesh := sign.build()
	_hang.add_child(mesh)
	var box := BoxShape3D.new()
	box.size = Vector3(board.x, board.y + 0.2, 0.6)
	var target := PropTarget.make(_hang, box, Vector3(0.0, -0.24 - board.y * 0.5, 0.0))
	target.struck.connect(_on_struck)


func _on_struck(direction: Vector2) -> void:
	_spin += -(direction.x if direction.x != 0.0 else 0.5) * 3.5
	Sound.play(self, &"paper_fold", -5.0)


func _physics_process(delta: float) -> void:
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	var t := Wind.now()
	var blow := Wind.speed_at(global_position.x)
	# Brushing past it in the air nudges it.
	if ronin:
		var close := _hang.global_position.distance_to(ronin.global_position + Vector3(0.0, 0.9, 0.0)) < 0.8
		if close and not _brushed:
			_spin += -signf(ronin.velocity.x) * clampf(absf(ronin.velocity.x) * 0.25, 0.4, 2.0)
		_brushed = close
	var rest := -blow * 0.05 + sin(t * 1.7 + _phase) * 0.03 * blow
	_spin += (-(_angle - rest) * 20.0 - _spin * 1.3) * delta
	_angle += _spin * delta
	_hang.rotation.z = _angle
