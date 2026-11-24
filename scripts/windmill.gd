class_name Windmill
extends Node3D
## A great paper windmill in the lantern makers' yard: six sails of washi on
## bamboo spars, red-edged, on a timber post, a drum on its axle winding a
## rope. The breeze only stirs it; the Fan Gust sets it spinning hard
## ("gust_target"), and while it spins fast (`turning`) it winds its rope
## and the hoist it drives goes up (RiseQuarter). It slows to the breeze
## again over some seconds, creaking. Origin: the foot of its post.

## Hub height above its foot, and the sails' reach.
@export var hub := 3.6
@export var radius := 1.7
## How fast a gust sets it turning (radians a second), and how long it
## takes to slow back to the breeze.
@export var gust_spin := 9.0
@export var spin_down := 7.0
## Turning faster than this winds the rope.
@export var turning_at := 3.0

var spin := 0.0
var _rotor: Node3D
var _creak := 0.0


func _ready() -> void:
	add_to_group(&"gust_target")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 3.0)
	var post := PaperMesh.new(rng.randi())
	post.shade_jitter = 0.15
	post.color = PaperMesh.TIMBER.lightened(0.1)
	post.box(Vector3(0.0, hub * 0.5, -0.25), Vector3(0.24, hub, 0.24))
	post.box(Vector3(0.0, 0.08, -0.25), Vector3(1.2, 0.16, 0.8))
	for side: float in [-1.0, 1.0]:
		post.box(Vector3(side * 0.35, hub * 0.28, -0.25), Vector3(0.08, hub * 0.6, 0.08))
	# The drum on the axle, the rope wound on it.
	post.color = Scenery.WOOD
	post.frustum(10, Vector2(0.22, 0.22), Vector2(0.22, 0.22), 0.3, Vector3(0.0, hub - 0.15, -0.55))
	add_child(post.build())
	_rotor = Node3D.new()
	_rotor.position = Vector3(0.0, hub, 0.08)
	add_child(_rotor)
	var sails := PaperMesh.new(rng.randi())
	sails.shade_jitter = 0.12
	for k in 6:
		var a := TAU * k / 6.0
		var along := Vector2(cos(a), sin(a))
		var side := Vector2(-along.y, along.x)
		# A spar, and a sail of washi along one side of it, red at its edge.
		sails.color = Color(0.5, 0.42, 0.26)
		sails.stroke(Vector2.ZERO, along * radius, 0.05, 0.03, 0.02)
		var inner := along * 0.35
		var outer := along * radius
		for face: float in [1.0, -1.0]:
			var z := 0.0 if face > 0.0 else -0.005
			sails.color = Color(0.84, 0.8, 0.72) * rng.randf_range(0.92, 1.05)
			sails.quad(Vector3(inner.x, inner.y, z), Vector3(outer.x, outer.y, z),
					Vector3(outer.x + side.x * 0.5, outer.y + side.y * 0.5, z), Vector3(inner.x + side.x * 0.32, inner.y + side.y * 0.32, z),
					Vector3(0.0, 0.0, face))
			sails.color = Color(0.6, 0.22, 0.16)
			sails.quad(Vector3(outer.x + side.x * 0.44, outer.y + side.y * 0.44, z + face * 0.002), Vector3(outer.x + side.x * 0.5, outer.y + side.y * 0.5, z + face * 0.002),
					Vector3(inner.x + side.x * 0.32, inner.y + side.y * 0.32, z + face * 0.002), Vector3(inner.x + side.x * 0.27, inner.y + side.y * 0.27, z + face * 0.002),
					Vector3(0.0, 0.0, face))
	sails.color = PaperMesh.TIMBER
	sails.frustum(8, Vector2(0.14, 0.14), Vector2(0.1, 0.1), 0.2, Vector3(0.0, 0.0, 0.0))
	_rotor.add_child(sails.build())


func _process(delta: float) -> void:
	var breeze := Wind.speed_at(global_position.x) * 0.25
	spin = move_toward(spin, breeze, delta * gust_spin / spin_down)
	_rotor.rotation.z -= spin * delta
	_creak -= delta
	if spin > turning_at and _creak <= 0.0:
		_creak = 1.6
		Sound.play(self, &"windmill_creak", -4.0)


func turning() -> bool:
	return spin > turning_at


## The Fan Gust: it whirls.
func gusted(_direction: Vector3, _from: Vector3) -> void:
	spin = gust_spin
	_creak = 0.0
