class_name PhantomMask
extends Node3D
## A pale, floating copy of the Hannya's mask. It circles her for a moment,
## shivers (the tell), then dives at where the Ronin is standing. Parried, it
## shatters and costs her posture; otherwise it hurts him. Used from half
## health on.

const MASK := preload("res://models/hannya_mask.glb")

var boss: HannyaBoss
var target: Ronin
## Its place in the circle (0, 1, 2) and when it dives (seconds after it appears).
var slot := 0
var dive_at := 1.4
var dive_speed := 10.0
var arena := Vector2(47.0, 63.5)

var _clock := 0.0
var _diving := false
var _dive_dir := Vector3.ZERO
var _done := false
var _model: Node3D
var _paper: Array[StandardMaterial3D] = []


func _ready() -> void:
	_model = MASK.instantiate()
	var meshes := _model.find_children("*", "MeshInstance3D", true, false)
	var low := Vector3.INF
	var high := -Vector3.INF
	for m: MeshInstance3D in meshes:
		low = low.min(m.get_aabb().position)
		high = high.max(m.get_aabb().end)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in m.mesh.get_surface_count():
			var made := m.mesh.surface_get_material(i) as BaseMaterial3D
			var ghost := StandardMaterial3D.new()
			if made:
				ghost.albedo_texture = made.albedo_texture
			ghost.albedo_color = Color(0.9, 0.92, 1.0, 0.0)
			ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ghost.emission_enabled = true
			ghost.emission = Color(0.55, 0.6, 0.85)
			ghost.emission_energy_multiplier = 0.9
			m.set_surface_override_material(i, ghost)
			_paper.append(ghost)
	var grow := 0.8 / maxf(high.y - low.y, 0.001)
	_model.scale = Vector3.ONE * grow
	_model.position = -(low + high) * 0.5 * grow
	add_child(_model)


func _process(delta: float) -> void:
	if _done:
		return
	_clock += delta
	# Fading in, then circling above her shoulders.
	for p in _paper:
		p.albedo_color.a = clampf(_clock / 0.4, 0.0, 0.92)
	if not _diving:
		var centre := boss.global_position + Vector3(0.0, 3.1, 0.0) if is_instance_valid(boss) else global_position
		var angle := _clock * 2.2 + slot * TAU / 3.0
		var goal := centre + Vector3(cos(angle) * 1.4, sin(angle) * 0.4, sin(angle) * 0.5)
		# The tell: it stops, faces him and shivers.
		var shiver := 0.0
		if _clock > dive_at - 0.35:
			goal = global_position
			shiver = sin(_clock * 60.0) * 0.04
		global_position = global_position.lerp(goal, 1.0 - exp(-6.0 * delta)) + Vector3(shiver, 0.0, 0.0)
		if is_instance_valid(target):
			var to := target.global_position + Vector3(0.0, 0.9, 0.0) - global_position
			rotation.y = lerp_angle(rotation.y, atan2(to.x, 0.6), 1.0 - exp(-8.0 * delta))
		if _clock >= dive_at:
			_diving = true
			Sound.play(self, &"mask_creak", 2.0)
			var aim := target.global_position + Vector3(0.0, 0.9, 0.0) if is_instance_valid(target) else global_position + Vector3.DOWN
			_dive_dir = (aim - global_position).normalized()
	else:
		global_position += _dive_dir * dive_speed * delta
		global_position.z = 0.0
		if global_position.y < (boss.global_position.y if is_instance_valid(boss) else 0.0) - 0.2 \
				or global_position.x < arena.x - 1.0 or global_position.x > arena.y + 1.0:
			_shatter()
			return
		if is_instance_valid(target):
			var gap := target.global_position + Vector3(0.0, 0.8, 0.0) - global_position
			if absf(gap.x) < 0.5 and absf(gap.y) < 0.9:
				_done = true
				if target.receive_strike(1, global_position - _dive_dir):
					if is_instance_valid(boss):
						boss.projectile_parried(1)
				_shatter()


func _shatter() -> void:
	_done = true
	_model.visible = false
	Confetti.burst(get_parent(), global_position, 22)
	Sound.play(self, &"paper_cut", -2.0)
	await get_tree().create_timer(0.3).timeout
	queue_free()
