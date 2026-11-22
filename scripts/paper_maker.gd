class_name PaperMaker
extends Node3D
## The Paper-Maker (docs/lore.md, chapter 1): an old woman who makes fresh
## sheets by hand. A Meshy model (models/papermaker.glb, made from the
## Ronin's and the husk's references so it shares their folded-paper look;
## docs/reference/papermaker_front.png), posed by hand like them.
##
## She stands at her vat in Well Square, stooped, rocking the mould (sugeta)
## through the milky water, and every so often lifts it, tips it to let the
## water run off, and dips it again. When the Ronin comes near she stops,
## straightens a little, turns her head to him and gives a small nod; once
## he has gone on she goes back to her work.
## Origin: where she stands. She faces +X (the vat is in front of her).
##
## Meshy ids: image 01a203b6-9d73-7631-9e0f-b916b3288a26, model
## 01a203b7-355e-74b0-901f-d33b7ff6f89c, rig 01a203b8-19a9-77e8-8b1d-01868ced7b03
## (meshy-t2.5 smart topology, 10,000, meshy-n1, a-pose).

## Her height (metres).
@export var model_height := 1.38
## How near (metres along the street) he comes before she notices him.
@export var notice_distance := 4.0
## Seconds of one rock of the mould, forward and back.
@export var rock_time := 1.6
## Seconds between lifting the mould out to drain it.
@export var lift_every := 7.0

var _animator: SamuraiAnimator
var _mould: Node3D
var _hand_l := -1
var _hand_r := -1
var _clock := 0.0
var _attend := 0.0      # 0 = working, 1 = turned to him
var _nod_at := -100.0
var _ronin: Node3D
var _was_near := false
var _last_dip := 0
## True while she holds up a sheet for him (PaperMakerTale).
var showing := false
var _show := 0.0


func _ready() -> void:
	_build_model()
	_build_mould()


func _build_model() -> void:
	var model := Node3D.new()
	add_child(model)
	var figure: Node3D = (preload("res://models/papermaker.glb") as PackedScene).instantiate()
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
	figure.rotation.y = PI * 0.5  # Meshy models face +Z; the game faces +X.
	model.add_child(figure)
	for player: Node in figure.find_children("*", "AnimationPlayer", true, false):
		player.queue_free()
	for node: MeshInstance3D in meshes:
		var made := node.get_active_material(0) as BaseMaterial3D
		var paper := StandardMaterial3D.new()
		if made:
			paper.albedo_texture = made.albedo_texture
		paper.roughness = 1.0
		paper.metallic_specular = 0.2
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		for i in node.mesh.get_surface_count():
			node.set_surface_override_material(i, paper)
	var skeleton: Skeleton3D = figure.find_children("*", "Skeleton3D", true, false)[0]
	var units := 1.0 / (grow * PaperHusk._local_scale(skeleton, figure))
	_animator = SamuraiAnimator.new(skeleton, units)
	_hand_l = skeleton.find_bone("LeftHand")
	_hand_r = skeleton.find_bone("RightHand")
	_animator.apply(work(0.0, 0.0))


## The mould she holds: a light wooden frame with a screen of bamboo strips,
## a thin film of wet fibre on it.
func _build_mould() -> void:
	_mould = Node3D.new()
	_mould.top_level = true
	add_child(_mould)
	var b := PaperMesh.new(31)
	b.shade_jitter = 0.1
	b.color = Color(0.5, 0.44, 0.32)
	for z: float in [-0.24, 0.24]:
		b.box(Vector3(0.0, 0.0, z), Vector3(0.9, 0.035, 0.04))
	for x: float in [-0.43, 0.43]:
		b.box(Vector3(x, 0.0, 0.0), Vector3(0.04, 0.035, 0.52))
	b.color = Color(0.62, 0.58, 0.46)
	b.box(Vector3(0.0, 0.0, 0.0), Vector3(0.84, 0.012, 0.46))
	b.color = PaperMesh.WASHI.darkened(0.08)
	b.box(Vector3(0.0, 0.009, 0.0), Vector3(0.8, 0.006, 0.42))
	_mould.add_child(b.build())


func _process(delta: float) -> void:
	_clock += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Node3D
	var near := false
	if _ronin:
		near = absf(_ronin.global_position.x - global_position.x) < notice_distance \
				and absf(_ronin.global_position.y - global_position.y) < 2.5
	if near and not _was_near:
		_nod_at = _clock + 0.7
	if near and not SaveGame.papermaker_told and not showing and PaperMakerTale.allowed() and _free_to_tell():
		_tell()
	_was_near = near
	_attend = move_toward(_attend, 1.0 if near else 0.0, delta / (0.6 if near else 1.4))
	var nod := 0.0
	var since := _clock - _nod_at
	if since > 0.0 and since < 1.1:
		nod = sin(since / 1.1 * PI)
	var pose := SamuraiAnimator.mix(work(_clock, _rock_phase()), attend(_clock, nod), smoothstep(0.0, 1.0, _attend))
	_show = move_toward(_show, 1.0 if showing else 0.0, delta / 0.6)
	if _show > 0.0:
		pose = SamuraiAnimator.mix(pose, hold_up(_clock), smoothstep(0.0, 1.0, _show))
	_animator.apply(pose)
	_place_mould()
	# A soft slosh each time the mould dips into the water.
	var dips := int(_clock / rock_time)
	if dips != _last_dip and _attend < 0.3:
		_last_dip = dips
		Sound.play(self, &"wade", -22.0)


## 0 to 1 of the draining lift (0 = rocking in the water).
func _rock_phase() -> float:
	var t := fmod(_clock, lift_every)
	if t < lift_every - 2.2:
		return 0.0
	return sin((t - (lift_every - 2.2)) / 2.2 * PI)


## The mould sits between her hands, level with them, tipped as she tips it.
func _place_mould() -> void:
	var skeleton := _animator.skeleton
	if _hand_l < 0 or _hand_r < 0:
		return
	var l := skeleton.global_transform * skeleton.get_bone_global_pose(_hand_l).origin
	var r := skeleton.global_transform * skeleton.get_bone_global_pose(_hand_r).origin
	var mid := (l + r) * 0.5
	# Her hands hold its near edge; it reaches out in front of her.
	var forward := global_transform.basis.x
	_mould.global_position = mid + forward * 0.3 + Vector3(0.0, -0.03, 0.0)
	var tilt := clampf((l.y - r.y) * 2.0, -0.4, 0.4)
	_mould.rotation = Vector3(tilt, 0.0, _drain_tilt())


func _drain_tilt() -> float:
	return _rock_phase() * 0.4  # (the far end tips down, the water runs off it)


## Nothing else going on (no tutorial card, no cutscene, he is free to move).
func _free_to_tell() -> bool:
	if _ronin == null or not _ronin.is_physics_processing() or not (_ronin as Ronin).is_on_floor():
		return false
	var overlay := _overlay()
	if overlay == null:
		return false
	for kind: String in ["Tutorial", "PaperMakerTale", "SkipPrompt"]:
		if not overlay.get_parent().find_children("*", kind, true, false).is_empty():
			return false
	return true


## The game's overlay (where the HUD is).
func _overlay() -> Node:
	var hud := get_tree().get_first_node_in_group(&"hud")
	return hud.get_parent() if hud else null


## She shows him, in pictures (paper_maker_tale.gd).
func _tell() -> void:
	var tale := PaperMakerTale.new()
	tale.ronin = _ronin as Ronin
	tale.maker = self
	tale.hud = get_tree().get_first_node_in_group(&"hud") as CanvasItem
	_overlay().add_child(tale)


# --- Her stances (see samurai_animator.gd for what each entry means) -------------
# Directions: X = her left, Y = up, Z = the way she faces. Metres and degrees.

## A base pose for her: an old woman's stance, knees soft, feet close.
static func _pose(changes: Dictionary) -> Dictionary:
	return SamuraiAnimator.stance(changes, {"foot_l": Vector3(0.09, 0.0, 0.0), "foot_r": Vector3(-0.09, 0.0, 0.02),
			"hand_l": Vector3(0.18, -0.1, 0.12), "hand_r": Vector3(-0.18, -0.1, 0.12)})


## At the vat, stooped from the hips, both hands on the mould's near edge,
## rocking it forward and back through the water; `lift` raises it out and
## tips it to drain.
static func work(time: float, lift: float) -> Dictionary:
	var rock := sin(time / 1.6 * TAU)
	var reach := 0.36 + rock * 0.07 * (1.0 - lift)
	var high := 0.0 + lift * 0.16 - absf(rock) * 0.02 * (1.0 - lift)
	return _pose({
		"hips": Vector3(0.0, -0.06, -0.06),
		"hips_rot": Vector3(18.0, 0.0, 0.0),
		"spine": Vector3(16.0 + rock * 3.0 - lift * 6.0, 0.0, 0.0),
		"head": Vector3(14.0 - lift * 6.0, 0.0, 0.0),
		"hand_l": Vector3(0.2, high, reach),
		"hand_r": Vector3(-0.2, high, reach),
		"foot_l": Vector3(0.1, 0.0, 0.04), "foot_r": Vector3(-0.1, 0.0, -0.08),
	})


## Holding a fresh sheet up for him to see: both hands raised before her,
## straight-backed, head turned to him.
static func hold_up(time: float) -> Dictionary:
	var breath := sin(time * 1.6)
	return _pose({
		"hips": Vector3(0.0, -0.03 + breath * 0.004, -0.02),
		"hips_rot": Vector3(4.0, -18.0, 0.0),
		"spine": Vector3(2.0, -14.0, 0.0),
		"head": Vector3(-4.0, -24.0, 0.0),
		"hand_l": Vector3(0.24, 0.42, 0.26),
		"hand_r": Vector3(-0.24, 0.42, 0.26),
		"foot_l": Vector3(0.1, 0.0, 0.04), "foot_r": Vector3(-0.1, 0.0, -0.08),
	})


## Turned to him: straighter, hands resting on the vat's rim, head turned
## toward him (to her right, toward the street), with a small nod.
static func attend(time: float, nod: float) -> Dictionary:
	var breath := sin(time * 1.6)
	return _pose({
		"hips": Vector3(0.0, -0.04 + breath * 0.004, -0.03),
		"hips_rot": Vector3(8.0, -12.0, 0.0),
		"spine": Vector3(8.0 + breath, -10.0, 0.0),
		"head": Vector3(4.0 + nod * 22.0, -32.0, 0.0),
		"hand_l": Vector3(0.18, -0.02, 0.3),
		"hand_r": Vector3(-0.2, -0.02, 0.3),
		"foot_l": Vector3(0.1, 0.0, 0.04), "foot_r": Vector3(-0.1, 0.0, -0.08),
	})
