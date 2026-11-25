class_name SwimCache
extends Node3D
## A bundle of paper cranes on a scrap of floating wreckage out on deep
## water (a door, a shutter, a broken lantern boat's plank), bobbing: only
## reached by swimming, once the Wax Coat lets him float (Ronin.has_wax).
## Its origin is on the water's surface. One of the Wax Coat's reasons to go
## back to the town, the bamboo and the market.

@export var id := "swim_cache"
@export var count := 5

var bundle: CraneBundle
var _raft: Node3D
var _phase := 0.0


func _ready() -> void:
	_phase = global_position.x
	_raft = Node3D.new()
	add_child(_raft)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 17.0)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.14
	for k in 4:
		b.color = Color(0.3, 0.24, 0.2).lightened(rng.randf_range(0.0, 0.1))
		b.box(Vector3(-0.45 + k * 0.3, 0.02, rng.randf_range(-0.04, 0.04)), Vector3(0.27, 0.07, 0.95 + rng.randf_range(-0.1, 0.1)))
	b.color = Color(0.18, 0.14, 0.12)
	b.box(Vector3(0.0, 0.065, 0.3), Vector3(1.2, 0.04, 0.08))
	b.box(Vector3(0.0, 0.065, -0.3), Vector3(1.2, 0.04, 0.08))
	_raft.add_child(b.build())
	bundle = CraneBundle.new()
	bundle.id = id
	bundle.count = count
	bundle.swim_only = true
	bundle.reach = Vector2(1.0, 1.4)
	bundle.position = Vector3(0.0, 0.09, 0.0)
	_raft.add_child(bundle)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	_raft.position.y = 0.03 * sin(t * 1.3 + _phase)
	_raft.rotation.z = 0.04 * sin(t * 0.9 + _phase)
	_raft.rotation.x = 0.03 * sin(t * 0.7 + _phase * 0.5)
