class_name PaperWall
extends StaticBody3D
## A wall of tough kite paper stretched taut on a bamboo frame across the
## way (Koinobori Skies, and later back in older places): a cut glances off
## it, a dash bounces off it, but the Shuriken Dash's spin tears straight
## through (Ronin._spin_cut calls `tear`). Torn, the paper splits from the
## middle and its halves flap away on the wind; the frame stays. Saved
## (SaveGame.shortcuts `id`) when it has an id.

@export var id := ""
@export var width := 1.3
@export var height := 3.2

var torn := false
var _sheet: Node3D
var _shape: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	# (Solid well above the frame: it cannot be stood on or climbed over.)
	box.size = Vector3(0.3, height + 6.0, 2.4)
	_shape.shape = box
	_shape.position.y = (height + 6.0) * 0.5
	add_child(_shape)
	set_meta(&"no_climb", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 23.0)
	var f := PaperMesh.new(rng.randi())
	f.shade_jitter = 0.1
	f.color = Color(0.55, 0.48, 0.3)
	for side: float in [-1.0, 1.0]:
		f.frustum(6, Vector2(0.06, 0.06), Vector2(0.05, 0.05), height + 0.3, Vector3(side * width * 0.5, 0.0, 0.0))
	f.box(Vector3(0.0, height, 0.0), Vector3(width + 0.3, 0.07, 0.07))
	f.box(Vector3(0.0, 0.15, 0.0), Vector3(width + 0.1, 0.06, 0.06))
	# Lashings at the corners.
	f.color = Color(0.3, 0.22, 0.16)
	for side: float in [-1.0, 1.0]:
		f.box(Vector3(side * width * 0.5, height, 0.0), Vector3(0.12, 0.12, 0.1))
	add_child(f.build())
	_sheet = Node3D.new()
	_sheet.position = Vector3(0.0, (height + 0.15) * 0.5, 0.0)
	add_child(_sheet)
	for half: float in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(half * width * 0.5, 0.0, 0.0)
		_sheet.add_child(leaf)
		var p := PaperMesh.new(rng.randi())
		p.texture_world = false
		p.shade_jitter = 0.06
		p.color = Color(0.9, 0.86, 0.76)
		var h := (height - 0.2) * 0.5
		p.quad(Vector3(0.0, -h, 0.0), Vector3(-half * width * 0.5, -h, 0.0), Vector3(-half * width * 0.5, h, 0.0), Vector3(0.0, h, 0.0), Vector3.BACK)
		# A wind mon brushed across it: a red ring, split down the middle.
		p.color = Color(0.66, 0.24, 0.18)
		var r := width * 0.3
		for k in 12:
			var a0 := TAU * k / 12.0
			var a1 := TAU * (k + 1) / 12.0
			var c := Vector3(-half * width * 0.5, 0.3, 0.012)
			var p0 := c + Vector3(cos(a0), sin(a0), 0.0) * r
			var p1 := c + Vector3(cos(a1), sin(a1), 0.0) * r
			# (Only this half's side of the ring: it splits down the seam.)
			if (p0.x - c.x) * half >= -0.001 and (p1.x - c.x) * half >= -0.001:
				p.quad(p0, p1, c + Vector3(cos(a1), sin(a1), 0.0) * r * 0.75, c + Vector3(cos(a0), sin(a0), 0.0) * r * 0.75, Vector3.BACK)
		leaf.add_child(p.build())   # (hinged at its post, reaching to the seam)
	if id != "" and id in SaveGame.shortcuts:
		tear(true)


## Torn by the spin: the halves fly away downwind, the way is open.
func tear(quietly: bool = false) -> void:
	if torn:
		return
	torn = true
	_shape.disabled = true
	if id != "" and not quietly:
		SaveGame.opened(id)
	if quietly:
		_sheet.visible = false
		return
	Sound.play(self, &"kite_paper_tear", 0.0)
	Confetti.burst(get_parent(), global_position + Vector3(0.0, height * 0.5, 0.2), 30, [Color(0.9, 0.86, 0.76), Color(0.66, 0.24, 0.18)])
	for i in _sheet.get_child_count():
		var leaf := _sheet.get_child(i) as Node3D
		var half := -1.0 if i == 0 else 1.0
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(leaf, "rotation:y", half * 1.6, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(leaf, "position", leaf.position + Vector3(half * 1.5 - 1.2, 1.2, 0.6), 0.9)
		t.tween_property(leaf, "scale", Vector3(0.3, 0.3, 0.3), 0.9)
		t.chain().tween_callback(leaf.hide)
