class_name LanternBoat
extends AnimatableBody3D
## A flat-bottomed canal boat of lacquered planks in the Lantern Market's
## Canal Quarter, a paper lantern on a pole at its stern. It drifts slowly
## back and forth between two quays (a moving platform: stand on it to be
## carried across deep water), bobbing on the water and rocking; it dips
## when he lands on it and settles; it pauses at each end before turning
## back. Origin: on the water at the boat's middle.

## Where it drifts between (local x of its middle, relative to its parent).
@export var from_x := 0.0
@export var to_x := 8.0
## How fast it drifts (m/s), and how long it waits at each end.
@export var speed := 1.3
@export var wait := 1.2
## How deep it dips when he lands, and how fast it settles.
@export var dip := 0.12
@export var length := 3.2

var _dir := 1.0
var _wait := 0.0
var _phase := 0.0
var _dip := 0.0
var _dip_speed := 0.0
var _was_on := false
var _base_y := 0.0
var _hull: Node3D
var _ronin: Ronin


func _ready() -> void:
	sync_to_physics = false  # (moved here in _physics_process, as the stalls and planks are)
	process_physics_priority = -5   # before the Ronin moves (he rides on it)
	_base_y = position.y
	position.x = from_x
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(from_x) * 13.0 + to_x)
	_phase = rng.randf() * TAU
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.3, 1.6)
	shape.shape = box
	shape.position.y = 0.2
	add_child(shape)
	_hull = Node3D.new()
	add_child(_hull)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.18
	var half := length * 0.5
	# The hull: a long low box with raised, pointed ends, red lacquer
	# outside, planks inside.
	b.color = LanternMarket.LACQUER.darkened(0.25)
	b.extrude(PackedVector2Array([Vector2(-half, 0.35), Vector2(-half + 0.5, -0.12), Vector2(half - 0.5, -0.12), Vector2(half, 0.35),
			Vector2(half - 0.15, 0.36), Vector2(-half + 0.15, 0.36)]), -0.8, 0.8)
	b.color = Scenery.WOOD.lightened(0.1)
	var x := -half + 0.3
	while x < half - 0.35:
		b.box(Vector3(x + 0.2, 0.36, 0.0), Vector3(0.36, 0.04, 1.5))
		x += 0.42
	b.color = LanternMarket.GOLD.darkened(0.25)
	b.box(Vector3(0.0, 0.38, 0.79), Vector3(length - 0.6, 0.05, 0.04))
	# The stern pole, the lantern hung from its crook.
	b.color = PaperMesh.TIMBER
	b.box(Vector3(-half + 0.35, 1.2, -0.55), Vector3(0.07, 1.7, 0.07))
	b.box(Vector3(-half + 0.55, 2.02, -0.55), Vector3(0.45, 0.05, 0.05))
	_hull.add_child(b.build())
	var lantern := Scenery.lantern(rng, 1.6, 0.75, 0.15)
	lantern.position = Vector3(-half + 0.74, 2.0, -0.55)
	_hull.add_child(lantern)
	Scenery.windswept(lantern, 0.04, rng)
	var light := OmniLight3D.new()
	light.light_color = PaperMesh.LANTERN
	light.light_energy = 2.4
	light.omni_range = 5.0
	light.position = Vector3(-half + 0.74, 1.6, 0.3)
	_hull.add_child(light)


func _physics_process(delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	var t := Time.get_ticks_msec() * 0.001
	# Drift, pausing at the ends.
	# (Its velocity is told to the physics too, so he rides it smoothly.)
	constant_linear_velocity = Vector3.ZERO if _wait > 0.0 else Vector3(_dir * speed, 0.0, 0.0)
	if _wait > 0.0:
		_wait -= delta
	else:
		position.x += _dir * speed * delta
		if (_dir > 0.0 and position.x >= to_x) or (_dir < 0.0 and position.x <= from_x):
			position.x = clampf(position.x, from_x, to_x)
			_dir = -_dir
			_wait = wait
	# He lands on it: it dips and springs back.
	var on := false
	if _ronin and _ronin.is_on_floor():
		var local := _ronin.global_position - global_position
		on = absf(local.x) < length * 0.5 + 0.1 and local.y > 0.0 and local.y < 0.8
	if on and not _was_on:
		_dip_speed = -dip * 9.0
		Sound.play(self, &"wade", -10.0)
	_was_on = on
	_dip_speed += (-_dip * 60.0 - _dip_speed * 7.0) * delta
	_dip += _dip_speed * delta
	# Bobbing on the water, and a slow rock.
	position.y = _base_y + 0.05 * sin(t * 1.3 + _phase) + _dip
	_hull.rotation.z = 0.025 * sin(t * 0.9 + _phase) + _dip * 0.4 * signf(_ronin.global_position.x - global_position.x if _ronin else 0.0)
