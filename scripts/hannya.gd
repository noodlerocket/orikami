class_name Hannya
extends Node3D
## The Weeping Hannya: the Meshy model (models/hannya.glb), posed by hand
## with the stances in hannya_poses.gd. She can also make a SILHOUETTE
## DOUBLE of herself: a second copy, posed the same, drawn plain white on a
## render layer only the shadow camera sees. That copy is what throws her
## shadow onto the shoji screen.

## The render layer only the shadow camera draws (layer 20; the bit value).
const SHADOW_LAYER := 1 << 19

@export var model_scene: PackedScene = preload("res://models/hannya.glb")
@export var model_height := 2.6
## Her paper is darkened and cooled a little to sit in the night.
@export var tint := Color(0.82, 0.84, 0.92)
## Stop-motion poses a second, like everything else alive in the game.
@export var frames_per_second := 12.0

## The pose she should be in right now (set by the cutscene or the fight).
var pose: Dictionary = HannyaPoses.weep(0.0)

var _figure: Node3D
var _animator: SamuraiAnimator
var _double: Node3D
var _double_animator: SamuraiAnimator
var _frame_clock := 0.0
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	var built := _build(false)
	_figure = built[0]
	_animator = built[1]
	_animator.apply(pose)


## Makes the silhouette double (call once, if her shadow is wanted).
func make_shadow_double() -> void:
	var built := _build(true)
	_double = built[0]
	_double_animator = built[1]
	_double_animator.apply(pose)


## Removes the silhouette double (once she is out from behind the paper).
func hide_double() -> void:
	if _double:
		_double.queue_free()
		_double = null
		_double_animator = null


## Shows or hides her solid self (the double is unaffected).
func show_body(on: bool) -> void:
	_figure.visible = on


## Puts her in a pose at once, rather than at the next stop-motion tick.
func snap(new_pose: Dictionary) -> void:
	pose = new_pose
	_frame_clock = 1.0 / frames_per_second


## Flashes her paper white (when she is hit).
func flash(on: bool) -> void:
	for mat in _materials:
		mat.emission_enabled = on
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 1.2


func _process(delta: float) -> void:
	_frame_clock += delta
	if _frame_clock >= 1.0 / frames_per_second:
		_frame_clock = 0.0
		_animator.apply(pose)
		if _double_animator:
			_double_animator.apply(pose)


## Loads one copy of the model. Returns [the copy, its animator].
func _build(silhouette: bool) -> Array:
	var holder := Node3D.new()
	add_child(holder)
	var figure: Node3D = model_scene.instantiate()
	var meshes := figure.find_children("*", "MeshInstance3D", true, false)
	var low := INF
	var high := -INF
	for node: MeshInstance3D in meshes:
		var box := node.get_aabb()
		low = minf(low, box.position.y)
		high = maxf(high, box.end.y)
	var grow := model_height / maxf(high - low, 0.001)
	figure.scale = Vector3.ONE * grow
	figure.position.y = -low * grow
	holder.add_child(figure)
	for player: Node in figure.find_children("*", "AnimationPlayer", true, false):
		player.queue_free()
	for node: MeshInstance3D in meshes:
		var made := node.get_active_material(0) as BaseMaterial3D
		var paper := StandardMaterial3D.new()
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		if silhouette:
			paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			paper.albedo_color = Color.WHITE
			paper.disable_fog = true
			node.layers = SHADOW_LAYER
		else:
			if made:
				paper.albedo_texture = made.albedo_texture
			paper.albedo_color = tint
			paper.roughness = 1.0
			paper.metallic_specular = 0.15
			_materials.append(paper)
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, paper)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var skeleton: Skeleton3D = figure.find_children("*", "Skeleton3D", true, false)[0]
	var scale_y := 1.0
	var at: Node = skeleton
	while at and at != figure:
		if at is Node3D:
			scale_y *= (at as Node3D).scale.y
		at = at.get_parent()
	var animator := SamuraiAnimator.new(skeleton, 1.0 / (grow * scale_y))
	return [holder, animator]


## Where her back is (the "Spine" bone), in the world: for the finishing seal.
func back_position() -> Vector3:
	var skeleton := _animator.skeleton
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Spine")).origin
