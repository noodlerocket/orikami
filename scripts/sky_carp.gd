class_name SkyCarp
extends AnimatableBody3D
## A giant carp streamer cut loose from its pole, riding the wind between
## the cliffs of Koinobori Skies: a moving platform. Its paper body fills
## and slackens with the wind, its tail flicks, it drifts back and forth
## between `from_x` and `to_x`, turning round at each end (a slow swing of
## its head). Landing on it, it dips under him and its body ripples.
## Moved in _physics_process with sync_to_physics off and a velocity, so he
## rides it (like the market's lantern boats).

@export var from_x := 0.0
@export var to_x := 6.0
@export var speed := 1.4
@export var length := 3.8
@export var wait := 0.8
var colour := Color(0.72, 0.3, 0.24)

var _home := Vector3.ZERO
var _dir := 1.0
var _wait := 0.0
var _clock := 0.0
var _dip := 0.0
var _on := false
var _look: Node3D
var _segs: Array[Node3D] = []
var _ronin: Ronin
var _turn := 0.0


func _ready() -> void:
	sync_to_physics = false
	_home = position
	_clock = randf() * 10.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length * 0.8, 0.3, 1.4)
	shape.shape = box
	shape.position.y = -0.15
	add_child(shape)
	_look = Node3D.new()
	add_child(_look)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 41.0)
	var n := 7
	var parent: Node3D = _look
	for i in n:
		var seg := Node3D.new()
		seg.position = Vector3(length * 0.45 if i == 0 else -length / n, 0.0, 0.0)
		parent.add_child(seg)
		var t := float(i) / n
		var r0 := lerpf(0.55, 0.32, t)
		var r1 := lerpf(0.55, 0.32, t + 1.0 / n)
		var p := PaperMesh.new(rng.randi())
		p.texture_world = false
		p.shade_jitter = 0.12
		p.color = colour.darkened(rng.randf_range(0.0, 0.08))
		p.loft([PaperCritter.ring_x(Vector3(0.0, -r0 * 0.9, 0.0), Vector2(r0, r0 * 0.9), 10),
				PaperCritter.ring_x(Vector3(-length / n, -r1 * 0.9, 0.0), Vector2(r1, r1 * 0.9), 10)], i == 0, false)
		# Painted scales: pale scalloped arcs along its flanks.
		p.color = colour.lightened(0.3)
		for k in 3:
			var sx := -length / n * (0.2 + k * 0.3)
			for side: float in [-1.0, 1.0]:
				p.box(Vector3(sx, -r0 * 0.55, side * r0 * 0.86), Vector3(0.12, 0.04, 0.02))
		# A pale belly.
		p.color = Color(0.92, 0.9, 0.84)
		p.box(Vector3(-length / n * 0.5, -r0 * 1.72, 0.0), Vector3(length / n, 0.03, r0 * 0.9))
		if i == 0:
			# Its mouth ring and its eyes.
			p.color = Color(0.92, 0.9, 0.84)
			p.frustum(12, Vector2(r0 * 1.02, r0 * 0.92), Vector2(r0 * 1.02, r0 * 0.92), 0.08, Vector3(0.02, -r0 * 0.9 - 0.04, 0.0))
			for side: float in [-1.0, 1.0]:
				p.color = Color(0.96, 0.95, 0.9)
				p.box(Vector3(-0.28, -r0 * 0.6, side * r0 * 0.88), Vector3(0.2, 0.2, 0.02))
				p.color = Color(0.05, 0.05, 0.06)
				p.box(Vector3(-0.28, -r0 * 0.6, side * r0 * 0.9), Vector3(0.1, 0.1, 0.02))
		if i == n - 1:
			p.color = colour.darkened(0.12)
			var tx := -length / n
			p.polygon(PackedVector2Array([Vector2(tx, -r1 * 0.9), Vector2(tx - 0.8, r1 * 0.6), Vector2(tx - 0.55, -r1 * 0.9), Vector2(tx - 0.8, -r1 * 2.3)]), 0.0)
		var m := p.build()
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seg.add_child(m)
		_segs.append(seg)
		parent = seg
	position = _home


func _physics_process(delta: float) -> void:
	_clock += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	var before := position
	if _wait > 0.0:
		_wait -= delta
		_turn = move_toward(_turn, 0.0 if _dir > 0.0 else 1.0, delta / wait)
	else:
		position.x += _dir * speed * delta
		var lo := from_x
		var hi := to_x
		if (_dir > 0.0 and position.x >= hi) or (_dir < 0.0 and position.x <= lo):
			position.x = clampf(position.x, lo, hi)
			_dir = -_dir
			_wait = wait
	var on := false
	if _ronin:
		var at := _ronin.global_position - global_position
		on = _ronin.is_on_floor() and absf(at.x) < length * 0.45 and at.y > -0.2 and at.y < 0.5
	if on and not _on:
		_dip = 0.22
		Sound.play(self, &"carp_flap", 0.0)
	_on = on
	_dip = move_toward(_dip, 0.06 if on else 0.0, delta * 0.6)
	position.y = _home.y + 0.18 * sin(_clock * 0.9) - _dip
	constant_linear_velocity = (position - before) / maxf(delta, 0.0001)


func _process(_delta: float) -> void:
	# It faces the way it drifts; turning at the ends.
	_look.rotation.y = PI * _turn
	var t := _clock
	for i in _segs.size():
		var k := float(i) / _segs.size()
		_segs[i].rotation.y = 0.12 * sin(t * 3.0 - i * 0.8) * k
		_segs[i].rotation.z = 0.05 * sin(t * 2.2 - i * 0.6) * k
	# Filling and slackening with the wind.
	var fill := 1.0 + 0.05 * sin(t * 1.3)
	_look.scale = Vector3(1.0, fill, fill)
