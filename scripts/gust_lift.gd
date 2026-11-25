class_name GustLift
extends AnimatableBody3D
## A stone slab hung on ropes from a timber gantry, wound up while its
## prayer wheel turns (PrayerWheel) and sinking slowly back when it slows.
## He rides it (moved in _physics_process with sync off and a velocity, like
## the market's boats). The gantry's posts stand on the ground behind it;
## the ropes run from the slab's corners up to the pulley on its beam.
## Origin: the slab's top at its lowest.

@export var rise := 6.0
@export var width := 2.0
@export var up_speed := 1.3
@export var down_speed := 0.6
var wheel: PrayerWheel

var _home := Vector3.ZERO
var _up := 0.0
var _ropes: Array[MeshInstance3D] = []
var _creak := 0.0


func _ready() -> void:
	sync_to_physics = false
	_home = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.25, 2.2)
	shape.shape = box
	shape.position.y = -0.125
	add_child(shape)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 5.0)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	MarshKit.masonry(b, Vector3(0.0, -0.125, 0.0), Vector3(width, 0.25, 2.2), rng, Color(0.52, 0.52, 0.5), false)
	b.color = Color(0.16, 0.16, 0.18)
	for x: float in [-width * 0.5 + 0.12, width * 0.5 - 0.12]:
		b.box(Vector3(x, 0.03, -0.9), Vector3(0.1, 0.06, 0.1))
	add_child(b.build())
	# The gantry: two posts behind the slab (standing on the ground under
	# them), a beam across their tops with a pulley. Top-level, it does not move.
	var g := PaperMesh.new(rng.randi())
	g.shade_jitter = 0.1
	var top := _home.y + rise + 2.6
	g.color = Color(0.3, 0.22, 0.17)
	for x: float in [-width * 0.5 - 0.15, width * 0.5 + 0.15]:
		g.box(Vector3(x, (_home.y - 0.25 + top) * 0.5, -1.35), Vector3(0.22, top - _home.y + 0.25, 0.22))
	g.box(Vector3(0.0, top + 0.1, -1.35), Vector3(width + 0.7, 0.24, 0.26))
	g.box(Vector3(0.0, top - 0.15, -0.95), Vector3(0.2, 0.2, 0.6))
	g.color = Color(0.2, 0.2, 0.22)
	g.frustum(10, Vector2(0.16, 0.16), Vector2(0.16, 0.16), 0.08, Vector3(0.0, top - 0.3, -0.62))
	var gantry := g.build()
	gantry.top_level = true
	gantry.position = Vector3(global_position.x, 0.0, global_position.z)
	add_child(gantry)
	for k in 2:
		var rope := MeshInstance3D.new()
		var line := BoxMesh.new()
		line.size = Vector3(0.03, 1.0, 0.03)
		rope.mesh = line
		var look := StandardMaterial3D.new()
		look.albedo_color = Color(0.6, 0.53, 0.4)
		rope.material_override = look
		rope.top_level = true
		add_child(rope)
		_ropes.append(rope)
	set_meta(&"top", top)


func _physics_process(delta: float) -> void:
	var before := position
	var going := up_speed if wheel and wheel.turning() else -down_speed
	_up = clampf(_up + going * delta, 0.0, rise)
	position.y = _home.y + _up
	constant_linear_velocity = (position - before) / maxf(delta, 0.0001)
	var moving := absf(position.y - before.y) > 0.0001
	_creak -= delta
	if moving and _creak <= 0.0:
		_creak = 1.1
		Sound.play(self, &"windmill_creak", -12.0)


func _process(_delta: float) -> void:
	# The ropes from the slab's back corners up to the pulley.
	var top: float = get_meta(&"top")
	var pulley := Vector3(global_position.x, top - 0.3, global_position.z - 0.62)
	for k in _ropes.size():
		var corner := global_position + Vector3((k * 2 - 1) * (width * 0.5 - 0.12), 0.06, -0.9)
		var mid := (corner + pulley) * 0.5
		var length := corner.distance_to(pulley)
		var up := (pulley - corner).normalized()
		var side := up.cross(Vector3.BACK).normalized()
		_ropes[k].global_transform = Transform3D(Basis(side, up * length, side.cross(up)), mid)
