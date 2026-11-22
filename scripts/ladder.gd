class_name Ladder
extends Node3D
## A wooden ladder standing just behind the path, leaning on a deck of the
## Rooftop Road. At first it is drawn up and lashed under the deck, out of
## reach from the street; from the deck above he cuts the cord, and it drops
## and swings down into place, clattering (a shortcut: after that he can
## climb up from the street). W at its foot takes hold, W and S climb, jump
## lets go; at the top he steps off onto the deck.
## Origin: on the street at the ladder's foot.

signal lowered_now

## Height of its top (where the deck is), above its foot.
@export var height := 7.0
## Which way he steps off at the top (-1 = left, 1 = right).
@export var step_off := -1.0

var lowered := false
var top := 0.0
var bottom := 0.0

var _ronin: Ronin
var _frame: Node3D
var _cord: Node3D
var _drop := 0.0  # 0 = drawn up, 1 = down


func _ready() -> void:
	process_physics_priority = -5
	bottom = global_position.y
	top = bottom + height
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 71.0)
	# The ladder hangs from a pin at its top, so drawn up it is swung up
	# under the deck, and lowered it swings down.
	_frame = Node3D.new()
	_frame.position = Vector3(0.0, height - 0.35, -0.38)
	add_child(_frame)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.18
	b.color = Scenery.WOOD.darkened(0.1)
	for side: float in [-0.24, 0.24]:
		b.box(Vector3(side, -(height - 0.35) * 0.5, 0.0), Vector3(0.07, height - 0.3, 0.07))
	b.color = Scenery.WOOD.lightened(0.05)
	var y := -0.25
	while y > -height + 0.55:
		b.box(Vector3(0.0, y, 0.0), Vector3(0.5, 0.05, 0.05))
		y -= 0.34
	# Rope lashings at the joints.
	b.color = Color(0.4, 0.35, 0.28)
	y = -0.25
	while y > -height + 0.1:
		for side: float in [-0.24, 0.24]:
			b.box(Vector3(side, y, 0.0), Vector3(0.09, 0.07, 0.09))
		y -= 1.36
	_frame.add_child(b.build())
	# Drawn up: swung up flat under the deck, the cord holding it there.
	_frame.rotation.z = deg_to_rad(86.0) * step_off
	_cord = Node3D.new()
	_cord.position = Vector3(0.0, height + 0.05, -0.38)
	add_child(_cord)
	var cord := PaperMesh.new(rng.randi())
	cord.color = Color(0.45, 0.4, 0.32)
	cord.stroke(Vector2(0.0, 0.0), Vector2(0.02, -0.45), 0.03, 0.03)
	cord.color = PaperMesh.VERMILION.darkened(0.35)  # a faded red tag: something to cut
	cord.rect(Vector2(0.02, -0.5), Vector2(0.09, 0.12), 0.01)
	_cord.add_child(cord.build())
	Scenery.windswept(_cord, 0.05, rng)
	var latch := PropTarget.make(self, BoxShape3D.new(), Vector3(0.0, height + 0.6, 0.0))
	((latch.get_child(0) as CollisionShape3D).shape as BoxShape3D).size = Vector3(0.8, 1.0, 2.0)
	latch.struck.connect(_on_struck)


func _on_struck(_direction: Vector2) -> void:
	lower()


## Cuts the cord: the ladder swings down into place, clattering.
func lower(at_once: bool = false) -> void:
	if lowered:
		return
	lowered = true
	_cord.visible = false
	if at_once:
		_frame.rotation.z = 0.0
		return
	Sound.play(self, &"paper_cut", -4.0)
	var swing := create_tween()
	swing.tween_property(_frame, "rotation:z", deg_to_rad(-9.0) * step_off, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	swing.tween_callback(Sound.play.bind(self, &"plank_snap", -8.0))
	swing.tween_property(_frame, "rotation:z", deg_to_rad(3.5) * step_off, 0.2).set_trans(Tween.TRANS_SINE)
	swing.tween_property(_frame, "rotation:z", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	lowered_now.emit()


func _physics_process(_delta: float) -> void:
	if not lowered:
		return
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position
	if absf(at.x - global_position.x) < 0.5 and at.y > bottom - 0.2 and at.y < top + 0.3:
		_ronin.ladder = self
