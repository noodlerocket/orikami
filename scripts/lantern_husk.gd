class_name LanternHusk
extends PaperHusk
## A husk that still carries its lantern: a lamplighter the Rain got to. It
## keeps its distance. When the Ronin is in front of it, too far for a
## swipe but within a throw, it lifts the lantern high behind its head (the
## tell, lit from inside), tears a burning wad of paper from it and throws
## it in an arc (BurningPaper). Parry the wad and it flies back and burns
## the thrower. Up close it swipes like any husk.

@export_group("Throwing")
## It throws when he is this far in front of it (metres): nearer than the
## first number it swipes instead.
@export var throw_range := Vector2(2.6, 9.0)
## The tell: how long it holds the lantern up before throwing.
@export var throw_windup := 0.6
## How high over the target the throw arcs (seconds in the air).
@export var throw_time := 0.85
@export var throw_cooldown := 2.4

var _throw_cooldown := 1.2
var _lantern: Node3D
var _lantern_light: OmniLight3D


func _ready() -> void:
	super._ready()
	# The lantern, held in its right hand.
	if _animator:
		var hand := BoneAttachment3D.new()
		hand.bone_name = "RightHand"
		_animator.skeleton.add_child(hand)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(global_position.x * 7.0)
		_lantern = Scenery.lantern(rng, 1.1, 0.36, 0.1)
		hand.add_child(_lantern)
		# (Undo the skeleton's scale so the lantern keeps its own size.)
		_lantern.scale = Vector3.ONE / maxf(_animator.skeleton.global_transform.basis.get_scale().x, 0.0001) if _animator.skeleton.is_inside_tree() else Vector3.ONE
		_lantern_light = OmniLight3D.new()
		_lantern_light.light_color = PaperMesh.LANTERN
		_lantern_light.light_energy = 1.2
		_lantern_light.omni_range = 3.5
		_lantern_light.omni_attenuation = 2.0
		add_child(_lantern_light)
		_lantern_light.position = Vector3(0.0, 0.9, 0.6)


func _physics_process(delta: float) -> void:
	_throw_cooldown = maxf(_throw_cooldown - delta, 0.0)
	match mode:
		&"throw_windup":
			_mode_time += delta
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if not is_on_floor():
				velocity.y -= gravity * delta
			if _mode_time >= throw_windup:
				_throw()
				_set_mode(&"throw")
			move_and_slide()
			position.z = 0.0
			return
		&"throw":
			_mode_time += delta
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			if _mode_time >= 0.45:
				_set_mode(&"patrol")
			move_and_slide()
			position.z = 0.0
			return
		&"patrol":
			if _throw_cooldown <= 0.0 and is_on_floor() and _stun <= 0.0:
				var player := _target_in_throw_range()
				if player:
					_set_mode(&"throw_windup")
					Sound.play(self, &"fire_whoosh", -6.0)
					return
	super._physics_process(delta)


func _target_in_throw_range() -> Node3D:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null or absf(player.global_position.y - global_position.y) > 3.0:
		return null
	var ahead := (player.global_position.x - global_position.x) * _dir
	if ahead < 0.0 and ahead > -throw_range.y * 0.6:
		_dir = -_dir
		ahead = -ahead
	return player if ahead > throw_range.x and ahead < throw_range.y else null


func _throw() -> void:
	_throw_cooldown = throw_cooldown
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return
	var wad := BurningPaper.new()
	wad.thrower = self
	get_parent().add_child(wad)
	var from := global_position + Vector3(_dir * 0.3, 1.5, 0.0)
	wad.global_position = from
	var to := player.global_position + Vector3(0.0, 0.8, 0.0)
	var t := throw_time
	wad.velocity = Vector3((to.x - from.x) / t, (to.y - from.y) / t + wad.gravity * t * 0.5, 0.0)
	Sound.play(self, &"fire_whoosh")


func _pose_model() -> void:
	if mode == &"throw_windup":
		_animator.apply(HuskPoses.windup(_mode_time / throw_windup))
		return
	if mode == &"throw":
		_animator.apply(HuskPoses.strike())
		return
	super._pose_model()


func _process(delta: float) -> void:
	super._process(delta)
	if _lantern_light and _lantern:
		# The lantern's light follows it, flickering; brighter in the tell.
		_lantern_light.global_position = _lantern.global_position + Vector3(0.0, -0.2, 0.5)
		var boost := 1.6 if mode == &"throw_windup" else 1.0
		_lantern_light.light_energy = (1.1 + sin(_clock * 17.0) * 0.12) * boost
