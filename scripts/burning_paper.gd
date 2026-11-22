class_name BurningPaper
extends Node3D
## A crumpled wad of burning paper, thrown by a lantern husk. It flies in an
## arc, trailing embers and a thread of smoke. If it reaches the Ronin it is
## an attack: parry it (with good timing) and it is knocked back the way it
## came, now dangerous to whoever threw it. On the ground it flares, its
## embers scatter, and it burns down to nothing (it never pops out).

## Who threw it (it cannot hurt its thrower until it is parried back).
var thrower: Node3D
var velocity := Vector3.ZERO
@export var gravity := 14.0
@export var damage := 1
## A fox-fire (Akane's): folded vermilion paper burning with a redder flame.
var fox := false

var _returned := false
var _burning_out := -1.0
var _ball: Node3D
var _flame: MeshInstance3D
var _light: OmniLight3D
var _embers: CPUParticles3D
var _smoke: CPUParticles3D
var _life := 0.0


func _ready() -> void:
	_ball = Node3D.new()
	add_child(_ball)
	var b := PaperMesh.new(randi())
	b.texture_world = false
	b.shade_jitter = 0.3
	b.color = Color(0.62, 0.2, 0.16) if fox else Color(0.55, 0.45, 0.33)
	b.frustum(5, Vector2(0.11, 0.1), Vector2(0.07, 0.08), 0.18, Vector3(0.0, -0.09, 0.0), 0.4)
	b.color = Color(0.12, 0.09, 0.08)  # charred
	b.frustum(5, Vector2(0.07, 0.08), Vector2(0.02, 0.02), 0.06, Vector3(0.0, 0.09, 0.0), 1.1)
	_ball.add_child(b.build())
	var f := PaperMesh.new(1)
	f.texture_scale = 0.0
	f.shade_jitter = 0.0
	f.color = Color(1.0, 0.4, 0.3) if fox else Color(1.0, 0.62, 0.25)
	f.ellipse(Vector2(0.0, 0.08), Vector2(0.11, 0.16), 9, 0.0, 0.25)
	f.color = Color(1.0, 0.86, 0.55)
	f.ellipse(Vector2(0.0, 0.05), Vector2(0.05, 0.08), 7, 0.01, 0.2)
	_flame = f.build(Color.WHITE, 3.0, true)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.42, 0.32) if fox else Color(1.0, 0.6, 0.3)
	_light.light_energy = 1.6
	_light.omni_range = 3.0
	_light.omni_attenuation = 2.0
	add_child(_light)
	_embers = CPUParticles3D.new()
	_embers.amount = 24
	_embers.lifetime = 0.7
	_embers.local_coords = false
	_embers.direction = Vector3.UP
	_embers.spread = 40.0
	_embers.gravity = Vector3(0.0, 1.5, 0.0)
	_embers.initial_velocity_min = 0.3
	_embers.initial_velocity_max = 1.0
	var ember := QuadMesh.new()
	ember.size = Vector2(0.035, 0.035)
	ember.material = WaterFx.bead_material(Color(1.0, 0.62, 0.3, 0.9))
	_embers.mesh = ember
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.85, 0.5, 1.0))
	fade.set_color(1, Color(0.6, 0.2, 0.1, 0.0))
	_embers.color_ramp = fade
	add_child(_embers)
	_smoke = CPUParticles3D.new()
	_smoke.amount = 14
	_smoke.lifetime = 1.2
	_smoke.local_coords = false
	_smoke.direction = Vector3.UP
	_smoke.spread = 15.0
	_smoke.gravity = Vector3(-0.6, 0.6, 0.0)
	_smoke.initial_velocity_min = 0.2
	_smoke.initial_velocity_max = 0.5
	_smoke.scale_amount_min = 1.0
	_smoke.scale_amount_max = 2.2
	var puff := QuadMesh.new()
	puff.size = Vector2(0.18, 0.18)
	puff.material = PaperMesh.soft_ink(Color(0.12, 0.12, 0.16, 0.35))
	_smoke.mesh = puff
	var thin := Gradient.new()
	thin.set_color(0, Color(1, 1, 1, 0.6))
	thin.set_color(1, Color(1, 1, 1, 0.0))
	_smoke.color_ramp = thin
	add_child(_smoke)


func _physics_process(delta: float) -> void:
	_life += delta
	if _burning_out >= 0.0:
		# Burning down where it fell: the flame shrinks away and is gone.
		_burning_out += delta
		var left := 1.0 - _burning_out / 0.9
		_flame.scale = Vector3.ONE * maxf(left, 0.001) * (1.0 + sin(_burning_out * 30.0) * 0.1)
		_light.light_energy = 1.6 * maxf(left, 0.0)
		_ball.scale = Vector3.ONE * maxf(0.4 + left * 0.6, 0.001)
		if _burning_out > 0.9:
			_embers.emitting = false
			_smoke.emitting = false
			_flame.visible = false
		if _burning_out > 2.2:
			queue_free()
		return
	velocity.y -= gravity * delta
	var from := global_position
	global_position += velocity * delta
	_ball.rotation.z += delta * 9.0
	_flame.scale = Vector3.ONE * (1.0 + sin(_life * 28.0) * 0.12)
	_light.light_energy = 1.6 + sin(_life * 23.0) * 0.3
	# Did it reach anyone?
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 4 if _returned else 2
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in space.intersect_shape(query, 4):
		var target: Object = result["collider"]
		if _returned and target.has_method("take_hit") and not target.has_method("is_prop"):
			target.take_hit(2, Vector2(signf(velocity.x), 0.0))
			_flare()
			return
		if not _returned and target.has_method("receive_strike"):
			if target.receive_strike(damage, global_position - Vector3(signf(velocity.x) * 0.3, 0.0, 0.0), &"fire"):
				# Parried: knocked back at the thrower, faster.
				_returned = true
				var home := thrower.global_position + Vector3(0.0, 0.9, 0.0) if is_instance_valid(thrower) else global_position + Vector3(-signf(velocity.x) * 5.0, 0.0, 0.0)
				var to := home - global_position
				var t := clampf(absf(to.x) / 11.0, 0.25, 0.8)
				velocity = Vector3(to.x / t, to.y / t + gravity * t * 0.5, 0.0)
				Sound.play(self, &"parry")
				return
			_flare()
			return
	# The ground (or a wall).
	var ray := PhysicsRayQueryParameters3D.create(from, global_position + velocity.normalized() * 0.12, 1)
	if not space.intersect_ray(ray).is_empty() or _life > 4.0:
		_flare()


## It hits something: a flare and a scatter of embers, then it burns down.
func _flare() -> void:
	_burning_out = 0.0
	Sound.play(self, &"fire_burst", -3.0)
	var burst := CPUParticles3D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = 26
	burst.lifetime = 0.8
	burst.direction = Vector3.UP
	burst.spread = 80.0
	burst.gravity = Vector3(0.0, -6.0, 0.0)
	burst.initial_velocity_min = 1.2
	burst.initial_velocity_max = 3.5
	var ember := QuadMesh.new()
	ember.size = Vector2(0.04, 0.04)
	ember.material = WaterFx.bead_material(Color(1.0, 0.6, 0.28, 0.95))
	burst.mesh = ember
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.9, 0.6, 1.0))
	fade.set_color(1, Color(0.5, 0.15, 0.05, 0.0))
	burst.color_ramp = fade
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
