class_name InkRiser
extends Node3D
## A sodden husk lying under the marsh's ink (Sumi Marsh): as he comes near
## it rises out of the ink in a spurt of black drops, ink streaming off it,
## and fights as the town's husk does. Before that it sleeps, hidden, its
## body out of reach of cuts. Its paper is soaked dark (`soak`).

## How near he must come (m along x) for it to rise.
@export var wake_distance := 5.5
## How long it takes to stand up out of the ink (s).
@export var rise_time := 0.9

const SOAKED := Color(0.5, 0.5, 0.56)
## Shimeri's drowned soldiers (the Drowned Muster, his call at half health)
## are his own foot soldiers: a Meshy model (models/drowned_warrior.glb,
## picture docs/reference/drowned_warrior_front.png; image
## 01a20d74-1ba3-73fe-8473-c89fca16504b, model
## 01a20d7a-4677-70a7-ad6d-eadb70aabc26, rig
## 01a20d7b-fe61-708c-888d-7571203649c4; meshy-t2.5, 9,000, meshy-n1),
## the usual 24 bones, posed with the husk's stances. Its paper is already
## ink-stained, so it is only lightly soaked.
const WARRIOR_SCENE := preload("res://models/drowned_warrior.glb")
const WARRIOR_TINT := Color(0.8, 0.82, 0.88)

## A drowned soldier rather than a soaked husk.
@export var warrior := false

var husk: Node3D
var _risen := false
var _t := -1.0
var _layer := 0
var _ronin: Ronin
var _drip: CPUParticles3D


## Soaks a husk's paper dark (before it is added, or after).
static func soak(h: Node3D) -> void:
	h.set(&"soak_tint", SOAKED)
	for m: StandardMaterial3D in h.get(&"_materials"):
		m.albedo_color = SOAKED


func _ready() -> void:
	husk = Village.HUSK_SCENE.instantiate()
	husk.set(&"soak_tint", SOAKED)
	if warrior:
		husk.set(&"model_scene", WARRIOR_SCENE)
		husk.set(&"soak_tint", WARRIOR_TINT)
		husk.set(&"model_height", 1.4)
	# (Not in the tree until it rises: nothing wakes it early.)
	husk.position = Vector3(0.0, -2.2, 0.0)
	_drip = CPUParticles3D.new()
	_drip.emitting = false
	_drip.amount = 30
	_drip.lifetime = 0.8
	_drip.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_drip.emission_box_extents = Vector3(0.3, 0.8, 0.2)
	_drip.direction = Vector3.DOWN
	_drip.spread = 15.0
	_drip.gravity = Vector3(0.0, -9.0, 0.0)
	_drip.initial_velocity_min = 0.2
	_drip.initial_velocity_max = 0.6
	var drop := QuadMesh.new()
	drop.size = Vector2(0.05, 0.07)
	drop.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.05, 0.9))
	_drip.mesh = drop
	husk.add_child(_drip)
	_drip.position = Vector3(0.0, 1.0, 0.0)


func _exit_tree() -> void:
	if is_instance_valid(husk) and not husk.is_inside_tree():
		husk.free()


func _process(delta: float) -> void:
	if _risen:
		return
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	if _t < 0.0:
		var d := _ronin.global_position - global_position
		if absf(d.x) < wake_distance and absf(d.y) < 3.0:
			_t = 0.0
			add_child(husk)
			_layer = (husk as CollisionObject3D).collision_layer
			(husk as CollisionObject3D).collision_layer = 0
			husk.process_mode = Node.PROCESS_MODE_DISABLED
			_drip.emitting = true
			WaterFx.splash(get_parent(), global_position + Vector3(0.0, maxf(SumiMarsh.INK_Y - position.y, 0.0), 0.0), 1.2, true)
			Sound.play(self, &"splash", -2.0)
			Sound.play(self, &"husk_rasp", -4.0)
			if is_instance_valid(husk) and husk.has_method(&"face_toward"):
				husk.call(&"face_toward", _ronin.global_position)
		return
	_t += delta
	var u := smoothstep(0.0, 1.0, _t / rise_time)
	husk.position = Vector3(0.0, lerpf(-2.2, 0.05, u), 0.0)
	if _t >= rise_time:
		_risen = true
		(husk as CollisionObject3D).collision_layer = _layer
		husk.process_mode = Node.PROCESS_MODE_INHERIT
		var stop := get_tree().create_timer(2.5)
		stop.timeout.connect(func() -> void:
			if is_instance_valid(_drip):
				_drip.emitting = false)
