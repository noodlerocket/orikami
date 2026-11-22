class_name PaperCritter
extends CharacterBody3D
## What every small paper creature shares (the paper dog, the paper bird):
## health; a white flash when cut (a material overlay, as on the husk: see
## PaperHusk.flash_overlay); posture, filled by parried attacks, that
## staggers it (a vermilion seal is stamped on it: a cut now finishes it);
## a burst of paper scraps when it dies. Folded from rigid paper pieces in
## code and posed by hand, 12 poses a second like the other puppets.

@export_group("Health")
@export var max_health := 2
@export var contact_damage := 1
@export_group("Posture")
## Parried attacks it can take before it staggers.
@export var max_posture := 1
## How long a stagger lasts. A cut in this time finishes it.
@export var stagger_time := 1.8
@export var posture_recover_time := 2.5
@export_group("Getting hit")
@export var flash_time := 0.12
@export var confetti_count := 30
@export var knockback_speed := 6.0
@export_group("Stop-motion")
@export var frames_per_second := 12.0

var health := 0
var posture := 0
## What it is doing now (each kind has its own set of modes).
var mode: StringName = &"patrol"

var _mode_time := 0.0
var _flash := 0.0
var _flash_meshes: Array[GeometryInstance3D] = []
var _rig: Node3D
var _seal: Node3D
var _seal_show := 0.0
var _frame_clock := 0.0
var _clock := 0.0
var _posture_clock := 0.0
var _touch: Area3D
var _dir := -1.0


func _ready() -> void:
	health = max_health
	collision_layer = 4  # "enemies"
	collision_mask = 1   # the world only
	_rig = Node3D.new()
	add_child(_rig)
	_build()
	_build_seal()


## Builds the body. Each kind does its own.
func _build() -> void:
	pass


## Adds a finished piece to the body (it flashes when hit).
func _part(parent: Node3D, mesh: MeshInstance3D) -> MeshInstance3D:
	parent.add_child(mesh)
	_flash_meshes.append(mesh)
	return mesh


## A touch box that notices the player.
func _make_touch(size: Vector3, at: Vector3) -> void:
	_touch = Area3D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	_touch.add_child(shape)
	add_child(_touch)


func _set_mode(next: StringName) -> void:
	mode = next
	_mode_time = 0.0
	_frame_clock = 1.0  # show the new pose at once


func is_staggered() -> bool:
	return mode == &"stagger"


## Called by the Ronin's cut.
func take_hit(damage: int, direction: Vector2) -> void:
	var finishing := mode == &"stagger"
	health = 0 if finishing else health - damage
	_set_flash(true)
	_flash = flash_time
	if health <= 0:
		Confetti.burst(get_parent(), global_position + _body_centre(), roundi(confetti_count * (1.5 if finishing else 1.0)))
		Sound.play(self, &"paper_burst", 2.0 if finishing else -1.0)
		queue_free()
		return
	_on_hit(direction)


## What it does when cut but not killed. Each kind decides.
func _on_hit(direction: Vector2) -> void:
	velocity.x = direction.x * knockback_speed


## Its attack was parried: posture, and perhaps a stagger.
func _on_parried() -> void:
	posture += 1
	_posture_clock = 0.0
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger")
	else:
		_set_mode(&"recover")


## Where its middle is, above its origin.
func _body_centre() -> Vector3:
	return Vector3(0.0, 0.4, 0.0)


## Hurts the player if he is touching it (not while it is staggered).
func _check_touch() -> void:
	if mode == &"stagger" or _touch == null:
		return
	for body: Node3D in _touch.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(contact_damage, global_position)


func _tick(delta: float) -> void:
	_mode_time += delta
	if posture > 0 and mode != &"stagger":
		_posture_clock += delta
		if _posture_clock >= posture_recover_time:
			_posture_clock = 0.0
			posture -= 1


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_set_flash(false)
	_seal_show = move_toward(_seal_show, 1.0 if mode == &"stagger" else 0.0, delta / 0.12)
	_seal.visible = _seal_show > 0.0
	_seal.scale = Vector3.ONE * maxf(smoothstep(0.0, 1.0, _seal_show), 0.001)
	_seal.rotation.z = (1.0 - _seal_show) * 0.8
	_clock += delta
	_frame_clock += delta
	if _frame_clock >= 1.0 / frames_per_second:
		_frame_clock = 0.0
		_pose()


## Puts the body in the pose for what it is doing (12 times a second).
func _pose() -> void:
	pass


func _set_flash(on: bool) -> void:
	for mesh: GeometryInstance3D in _flash_meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = PaperHusk.flash_overlay() if on else null


## The finishing seal: a small vermilion paper diamond on its side, shown
## while it is staggered (drawn in and out, never popping).
func _build_seal() -> void:
	_seal = Node3D.new()
	_seal.position = _body_centre() + Vector3(0.0, 0.05, 0.3)
	add_child(_seal)
	var seal := PaperMesh.new(104)
	seal.shade_jitter = 0.0
	seal.color = PaperMesh.VERMILION
	var r := 0.1
	seal.quad(Vector3(0.0, -r, 0.0), Vector3(r * 0.8, 0.0, 0.0), Vector3(0.0, r, 0.0), Vector3(-r * 0.8, 0.0, 0.0))
	seal.color = PaperMesh.WASHI
	var c := 0.025
	seal.quad(Vector3(0.0, -c, 0.012), Vector3(c * 0.8, 0.0, 0.012), Vector3(0.0, c, 0.012), Vector3(-c * 0.8, 0.0, 0.012))
	_seal.add_child(seal.build(Color.WHITE, 0.0, true))
	_seal.visible = false


## Is the player close in front of it and roughly level? (Within `ahead`
## metres in front, `behind` behind (then it turns), `rise` up or down.)
func _player_ahead(ahead: float, behind: float, rise: float) -> Ronin:
	var player := get_tree().get_first_node_in_group(&"player") as Ronin
	if player == null:
		return null
	if absf(player.global_position.y - global_position.y) > rise:
		return null
	var dx := (player.global_position.x - global_position.x) * _dir
	if dx > 0.0 and dx < ahead:
		return player
	if dx < 0.0 and dx > -behind:
		_dir = -_dir
	return null


func _wall_ahead() -> bool:
	return is_on_wall() and get_wall_normal().x * _dir < 0.0


func _edge_ahead(reach: float = 0.5) -> bool:
	var from := global_position + Vector3(_dir * reach, 0.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 0.9, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## One ring of points for PaperMesh.loft() standing upright across the x
## axis (for bodies that lie along x: a dog's body, a bird's): radius y is
## its height, radius z its width.
static func ring_x(center: Vector3, radius: Vector2, sides: int) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in sides:
		var angle := TAU * float(i) / float(sides) + PI * 0.5
		ring.append(center + Vector3(0.0, sin(angle) * radius.x, cos(angle) * radius.y))
	return ring
