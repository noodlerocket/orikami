class_name SinkingPlank
extends AnimatableBody3D
## A sodden plank (or a bundle of boards) floating on the marsh's ink: it
## dips when he lands on it, then settles slowly under his weight, down into
## the ink if he stays (over deep ink, that is a way in: unwaxed, it carries
## him back to the shrine). Off it, it bobs back up. Moved in
## _physics_process with sync_to_physics off and a velocity, so he rides it
## (canal_quarter.gd: the lantern boats).

## How long (m) and its top above the ink at rest.
@export var length := 2.2
@export var rest := 0.32
## How fast it sinks under him (m/s), and how deep it goes.
@export var sink_speed := 0.28
@export var sink_to := -0.7
## How fast it comes back up once he is off.
@export var rise_speed := 0.5
## Lotus pad: a round leaf instead of boards; it rocks more and never sinks
## further than a dip.
@export var lotus := false

var _top := 0.0
var _home := Vector3.ZERO
var _ronin: Ronin
var _dip := 0.0
var _on := false
var _look: Node3D
var _clock := 0.0
var _creak := 0.0


func _ready() -> void:
	sync_to_physics = false
	_home = position
	_top = rest
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.3, 1.6 if not lotus else length * 0.8)
	shape.shape = box
	shape.position.y = -0.15
	add_child(shape)
	_look = Node3D.new()
	add_child(_look)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 31.0)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.16
	if lotus:
		MarshKit.lotus_leaf(b, length * 0.55, rng)
		# A closed bud on a stalk beside it.
		b.color = Color(0.62, 0.5, 0.52)
		b.frustum(5, Vector2(0.07, 0.07), Vector2(0.0, 0.0), 0.22, Vector3(length * 0.3, 0.06, -0.35))
	else:
		var x := -length * 0.5
		var k := 0
		while x < length * 0.5 - 0.01:
			var x1 := minf(x + rng.randf_range(0.28, 0.4), length * 0.5)
			b.color = MarshKit.WOOD_WET.lightened(rng.randf_range(0.0, 0.12))
			b.box(Vector3((x + x1) * 0.5, -0.06 + rng.randf_range(-0.02, 0.02), rng.randf_range(-0.04, 0.04)), Vector3(x1 - x - 0.03, 0.1, 1.5 - (k % 3) * 0.12))
			x = x1
			k += 1
		b.color = Color(0.1, 0.09, 0.09)
		for side: float in [-1.0, 1.0]:
			b.box(Vector3(0.0, -0.14, side * 0.55), Vector3(length - 0.1, 0.08, 0.12))
		# Moss and a rope end.
		b.color = MarshKit.MOSS
		b.box(Vector3(-length * 0.3, -0.005, 0.5), Vector3(0.4, 0.02, 0.3))
	_look.add_child(b.build())
	position.y = _home.y + _top


func _physics_process(delta: float) -> void:
	_clock += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position - global_position
	var on := _ronin.is_on_floor() and absf(at.x) < length * 0.5 + 0.3 and at.y > -0.25 and at.y < 0.4
	if on and not _on:
		_dip = 0.12 if not lotus else 0.16
		Sound.play(self, &"plank_creak" if not lotus else &"wade", -8.0)
		WaterFx.splash(get_parent(), global_position + Vector3(rng_side() * length * 0.4, -0.1, 0.0), 0.35)
	_on = on
	var before := position.y
	if on and not lotus:
		_top = maxf(_top - sink_speed * delta, sink_to)
		_creak += delta
		if _creak > 1.1:
			_creak = 0.0
			Sound.play(self, &"plank_creak", -12.0)
	else:
		_top = minf(_top + rise_speed * delta, rest)
	_dip = move_toward(_dip, 0.0, delta * 0.5)
	var bob := 0.025 * sin(_clock * 1.3 + _home.x)
	position.y = _home.y + _top - _dip * (1.0 - absf(sin(_clock * 6.0)) * 0.3) + bob
	constant_linear_velocity = Vector3(0.0, (position.y - before) / maxf(delta, 0.0001), 0.0)
	var tilt := 0.05 if lotus else 0.02
	_look.rotation.z = tilt * sin(_clock * 0.9 + _home.x) + (clampf(at.x / length, -0.5, 0.5) * 0.12 if on else 0.0)
	_look.rotation.x = tilt * 0.6 * sin(_clock * 0.7 + _home.x * 0.3)


func rng_side() -> float:
	return -1.0 if int(_clock * 10.0) % 2 == 0 else 1.0
