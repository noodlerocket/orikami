class_name Smudge
extends StaticBody3D
## The Smudge: where the Ronin died, the ink he was carrying stays behind,
## a pool of it on the ground with a dark wisp of ink curling up out of it
## like breath, roughly his height. Cut it and the ink is his again: it
## flies back into him in soft drops, and the pool shrinks away. Die again
## before taking it back and it is lost (the old smudge dries away as the new
## one spreads). It sits on the enemies' layer so the sword finds it, but it
## is not an enemy (no ink for the cut itself, see Ronin.is_prop).

## The ink it holds.
var ink := 0
var _pool: InkPool
var _wisp: CPUParticles3D
var _done := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.4, 2.0)
	shape.shape = box
	shape.position.y = 0.7
	add_child(shape)
	_pool = InkPool.new()
	_pool.size = 1.3
	add_child(_pool)
	_pool.open(0.6)
	# The wisp: soft drops of ink rising slowly from the pool and thinning
	# away, leaning with the wind.
	_wisp = CPUParticles3D.new()
	_wisp.amount = 34
	_wisp.lifetime = 2.2
	_wisp.preprocess = 0.0
	_wisp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wisp.emission_box_extents = Vector3(0.22, 0.02, 0.15)
	_wisp.direction = Vector3.UP
	_wisp.spread = 8.0
	_wisp.gravity = Vector3(-0.08, 0.25, 0.0)
	_wisp.initial_velocity_min = 0.35
	_wisp.initial_velocity_max = 0.6
	_wisp.scale_amount_min = 0.8
	_wisp.scale_amount_max = 1.8
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(0.5, 1.0))
	grow.add_point(Vector2(1.0, 0.2))
	_wisp.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.15, Color(1, 1, 1, 0.85))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0.0))
	_wisp.color_ramp = fade
	var drop := QuadMesh.new()
	drop.size = Vector2(0.16, 0.2)
	drop.material = PaperMesh.soft_ink(Color(0.02, 0.02, 0.05))
	_wisp.mesh = drop
	_wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wisp.position = Vector3(0.0, 0.03, 0.2)
	add_child(_wisp)


func is_prop() -> bool:
	return true


## Cut: the ink flies back into him.
func take_hit(_damage: int, _direction: Vector2) -> void:
	if _done:
		return
	_done = true
	var ronin := get_tree().get_first_node_in_group(&"player") as Ronin
	if ronin:
		ronin.ink = mini(ronin.ink + ink, ronin.max_ink)
		ronin.ink_changed.emit(ronin.ink, ronin.max_ink)
		_return_drops(ronin)
	Sound.play(self, &"ink_bleed", -2.0)
	SaveGame.smudge_at = Vector3.INF
	SaveGame.smudge_ink = 0
	dry_up()


## Shrinks away and frees itself (taken back, or lost to a new death).
func dry_up() -> void:
	_done = true
	collision_layer = 0
	_wisp.emitting = false
	_pool.close(0.0, 0.8)
	var end := create_tween()
	end.tween_interval(2.4)
	end.tween_callback(queue_free)


## Soft drops of ink flying from the pool into him.
func _return_drops(ronin: Ronin) -> void:
	for k in mini(ink + 4, 14):
		var drop := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.14, 0.14)
		drop.mesh = quad
		drop.material_override = PaperMesh.soft_ink(Color(0.02, 0.02, 0.05), BaseMaterial3D.BILLBOARD_ENABLED)
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3(randf_range(-0.4, 0.4), randf_range(0.05, 0.6), 0.3)
		var fly := drop.create_tween()
		fly.tween_interval(k * 0.03)
		fly.tween_method(func(t: float) -> void:
			if not is_instance_valid(ronin):
				return
			var target := ronin.global_position + Vector3(0.0, 0.8, 0.0)
			drop.global_position = drop.global_position.lerp(target, t * 0.35)
			drop.scale = Vector3.ONE * maxf(1.0 - t, 0.05), 0.0, 1.0, 0.45)
		fly.tween_callback(drop.queue_free)
