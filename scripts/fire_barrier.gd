class_name FireBarrier
extends Node3D
## A barricade on fire across a way: torn shoji screens, broken lantern
## frames and paper heaped up and burning, the flames high, embers and smoke
## going up, its light flickering on everything near. Touching it burns him.
## Nothing gets past it but the Fan Gust: blown on (within reach), its flames
## lean away, gutter and go out in a burst of smoke and embers, and the
## charred heap slumps (SaveGame.shortcuts `id`). Something the gust can
## move ("gust_target"). Origin: the ground in the middle of the way.

signal blown_out

## Its name in the saved game, once it is out.
@export var id := ""
## How tall and how deep (across the street) it is.
@export var height := 2.4
@export var depth := 3.0

var out := false
var _wall: StaticBody3D
var _heap: Node3D
var _flames: Array[CPUParticles3D] = []
## The fire itself: tongues of flame (shaders/paper_flame.gdshader) at
## several depths and sizes, each its own pace (Julian: make the fire look
## better than the first soft blobs).
var _tongues: Array[MeshInstance3D] = []
const FLAME_STRENGTH := 0.5
var _scraps: CPUParticles3D
var _glow: MeshInstance3D
var _embers: CPUParticles3D
var _smoke: CPUParticles3D
var _light: OmniLight3D
var _clock := 0.0
var _burn_clock := 0.0
var _ronin: Ronin


func _ready() -> void:
	add_to_group(&"gust_target")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 31.0)
	_heap = Node3D.new()
	add_child(_heap)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.25
	# The heap: screens leant against each other, frames, crumpled sheets.
	for k in 9:
		var z := rng.randf_range(-depth * 0.45, depth * 0.45)
		var h := rng.randf_range(0.8, height * 0.85)
		b.color = Color(0.2, 0.13, 0.1) * rng.randf_range(0.8, 1.2)
		var lean := rng.randf_range(-0.35, 0.35)
		b.box(Vector3(lean * h * 0.5, h * 0.5, z), Vector3(0.08, h, rng.randf_range(0.6, 1.1)))
	for k in 14:
		# (Charred: pale sheets this close to the fire's light burned out
		# to a flat white patch.)
		b.color = [Color(0.36, 0.26, 0.2), Color(0.4, 0.2, 0.14), Color(0.15, 0.1, 0.08)][k % 3] * rng.randf_range(0.8, 1.1)
		var s := rng.randf_range(0.25, 0.6)
		b.box(Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(0.1, 1.0), rng.randf_range(-depth * 0.45, depth * 0.45)), Vector3(s, s * 0.6, s))
	# A charred lantern frame on top.
	b.color = Color(0.1, 0.07, 0.06)
	for k in 5:
		var y := 1.3 + k * 0.14
		var r := 0.35 * sin(PI * (0.15 + 0.7 * k / 4.0))
		b.frustum(8, Vector2(r, r), Vector2(r, r), 0.03, Vector3(0.0, y, rng.randf_range(-0.3, 0.3)))
	_heap.add_child(b.build())
	# The fire: tongues of flame across it, back to front, tall and small;
	# soft flickers among them; embers, burning scraps, smoke.
	var look := preload("res://shaders/paper_flame.gdshader")
	for k in 7:
		var tongue := MeshInstance3D.new()
		var quad := QuadMesh.new()
		var tall := rng.randf_range(1.6, 2.9) * height / 2.4
		quad.size = Vector2(rng.randf_range(1.0, 1.6), tall)
		tongue.mesh = quad
		var m := ShaderMaterial.new()
		m.shader = look
		m.set_shader_parameter(&"seed", rng.randf() * 10.0)
		m.set_shader_parameter(&"speed", rng.randf_range(1.2, 2.0))
		# (Seven of them added up: at full strength the heart burned out
		# to a flat white blob.)
		m.set_shader_parameter(&"strength", FLAME_STRENGTH)
		tongue.material_override = m
		tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tongue.position = Vector3(rng.randf_range(-0.25, 0.25), tall * 0.5 + 0.05, -depth * 0.45 + k * depth * 0.15)
		add_child(tongue)
		_tongues.append(tongue)
	for k in 3:
		var f := _fire(rng)
		f.amount = 14
		f.position = Vector3(0.0, 0.4 + rng.randf_range(0.0, 0.6), -depth * 0.35 + k * depth * 0.35)
		add_child(f)
		_flames.append(f)
	# Scraps of paper lifting off it, glowing at first, cooling to ash.
	_scraps = CPUParticles3D.new()
	_scraps.amount = 16
	_scraps.lifetime = 2.6
	_scraps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_scraps.emission_box_extents = Vector3(0.3, 0.5, depth * 0.4)
	_scraps.direction = Vector3.UP
	_scraps.spread = 30.0
	_scraps.gravity = Vector3(-0.3, 0.9, 0.0)
	_scraps.initial_velocity_min = 0.8
	_scraps.initial_velocity_max = 1.8
	_scraps.tangential_accel_min = -1.5
	_scraps.tangential_accel_max = 1.5
	_scraps.angular_velocity_min = -300.0
	_scraps.angular_velocity_max = 300.0
	var cool := Gradient.new()
	cool.set_color(0, Color(1.0, 0.62, 0.25))
	cool.add_point(0.35, Color(0.45, 0.12, 0.05))
	cool.set_color(cool.get_point_count() - 1, Color(0.18, 0.17, 0.18, 0.0))
	_scraps.color_ramp = cool
	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.11, 0.08)
	var paper := StandardMaterial3D.new()
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.vertex_color_use_as_albedo = true
	paper.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	scrap.material = paper
	_scraps.mesh = scrap
	_scraps.position.y = 1.4
	add_child(_scraps)
	# Its warm glow on the wet stones.
	_glow = Scenery.reflection(Vector2(3.6, 3.2), Color(1.0, 0.5, 0.2, 0.55))
	_glow.position = Vector3(0.0, 0.02, 0.9)
	add_child(_glow)
	_embers = CPUParticles3D.new()
	_embers.amount = 40
	_embers.lifetime = 2.0
	_embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_embers.emission_box_extents = Vector3(0.3, 0.6, depth * 0.45)
	_embers.direction = Vector3.UP
	_embers.spread = 25.0
	_embers.gravity = Vector3(0.0, 1.2, 0.0)
	_embers.initial_velocity_min = 0.6
	_embers.initial_velocity_max = 1.8
	var mote := QuadMesh.new()
	mote.size = Vector2(0.04, 0.04)
	mote.material = WaterFx.bead_material(Color(1.0, 0.6, 0.25))
	_embers.mesh = mote
	_embers.position.y = 1.2
	add_child(_embers)
	_smoke = CPUParticles3D.new()
	_smoke.amount = 18
	_smoke.lifetime = 3.0
	_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_smoke.emission_box_extents = Vector3(0.5, 0.3, depth * 0.45)
	_smoke.direction = Vector3.UP
	_smoke.spread = 12.0
	_smoke.gravity = Vector3(-0.3, 0.5, 0.0)
	_smoke.initial_velocity_min = 0.6
	_smoke.initial_velocity_max = 1.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.0))
	_smoke.scale_amount_curve = grow
	var puff := QuadMesh.new()
	puff.size = Vector2(1.4, 1.4)
	puff.material = PaperMesh.soft_ink(Color(0.32, 0.3, 0.33, 0.14))   # (thin: a dark clump looked like a black ball)
	_smoke.mesh = puff
	_smoke.position.y = height
	add_child(_smoke)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.22)
	_light.light_energy = 2.2
	_light.omni_range = 7.0
	_light.position = Vector3(-0.9, 2.2, 1.4)   # (out of the heap, over its front)
	add_child(_light)
	_wall = StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 30.0, 4.0)
	shape.shape = box
	shape.position.y = 15.0
	_wall.add_child(shape)
	_wall.set_meta(&"no_climb", true)
	add_child(_wall)
	Sound.place_loop(self, "kiln_fire.ogg", Vector3(0.0, 1.0, 0.0), -10.0, 9.0)
	if id != "" and id in SaveGame.shortcuts:
		_put_out(false)


## One flame: tongues of fire licking up, yellow at their roots to deep
## orange, thinning to nothing.
func _fire(rng: RandomNumberGenerator) -> CPUParticles3D:
	var f := CPUParticles3D.new()
	f.amount = 26
	f.lifetime = 0.7
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.25
	f.direction = Vector3.UP
	f.spread = 12.0
	f.gravity = Vector3(0.0, 2.5, 0.0)
	f.initial_velocity_min = 1.0
	f.initial_velocity_max = 2.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.1))
	f.scale_amount_curve = shrink
	f.scale_amount_min = 0.8
	f.scale_amount_max = 1.4
	var heat := Gradient.new()
	heat.set_color(0, Color(1.0, 0.7, 0.35, 0.45))   # (dim: stacked, they burned white)
	heat.add_point(0.4, Color(1.0, 0.45, 0.12, 0.4))
	heat.set_color(heat.get_point_count() - 1, Color(0.6, 0.12, 0.05, 0.0))
	f.color_ramp = heat
	var tongue := QuadMesh.new()
	tongue.size = Vector2(0.38, 0.6)
	var look := PaperMesh.soft_ink(Color(1.0, 1.0, 1.0, 1.0))
	look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tongue.material = look
	f.mesh = tongue
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return f


func _process(delta: float) -> void:
	_clock += delta
	if out:
		return
	_light.light_energy = 2.2 + 0.5 * sin(_clock * 13.0) + 0.3 * sin(_clock * 31.0)
	_glow.scale = Vector3.ONE * (1.0 + 0.08 * sin(_clock * 11.0))
	# Touching it burns.
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	_burn_clock -= delta
	if _ronin and _burn_clock <= 0.0:
		var rel := _ronin.global_position - global_position
		if absf(rel.x) < 0.95 and rel.y > -0.5 and rel.y < height:
			_burn_clock = 0.8
			_ronin.take_damage(1, global_position + Vector3(0.0, 1.0, 0.0), &"fire")


## The Fan Gust: the flames lean away and go out.
func gusted(direction: Vector3, _from: Vector3) -> void:
	if out:
		return
	_put_out(true, direction.x if absf(direction.x) > 0.5 else 1.0)


func _put_out(slow: bool, toward: float = 1.0) -> void:
	out = true
	if id != "" and id not in SaveGame.shortcuts:
		SaveGame.shortcuts.append(id)
	if _wall:
		_wall.queue_free()
		_wall = null
	for node: Node in get_children():
		if node is AudioStreamPlayer3D:
			node.queue_free()
	if not slow:
		for f: CPUParticles3D in _flames:
			f.emitting = false
		for t: MeshInstance3D in _tongues:
			t.visible = false
		_scraps.emitting = false
		_glow.visible = false
		_embers.emitting = false
		_smoke.emitting = false
		_light.light_energy = 0.0
		_heap.scale = Vector3(1.0, 0.45, 1.0)
		return
	Sound.play(self, &"fire_whoosh", 2.0)
	Sound.play(self, &"lantern_snuff", 0.0)
	# The flames are blown over, gutter and die; a burst of smoke and embers
	# is carried off on the gust; the heap slumps, charred.
	for f: CPUParticles3D in _flames:
		f.gravity = Vector3(toward * 14.0, 0.5, 0.0)
		f.initial_velocity_max = 0.6
	# The tongues are bent flat over by the gust and gutter out.
	for t: MeshInstance3D in _tongues:
		var m := t.material_override as ShaderMaterial
		var bend := create_tween()
		bend.tween_method(func(v: float) -> void: m.set_shader_parameter(&"lean", v), 0.0, toward * 2.2, 0.25)
		bend.parallel().tween_method(func(v: float) -> void: m.set_shader_parameter(&"strength", v), FLAME_STRENGTH, 0.0, 0.6).set_delay(0.15)
		bend.tween_callback(func() -> void: t.visible = false)
	_scraps.emitting = false
	var dark := create_tween()
	dark.tween_property(_glow, "scale", Vector3.ONE * 0.01, 0.6)
	var t := create_tween()
	t.tween_interval(0.45)
	t.tween_callback(func() -> void:
		for f: CPUParticles3D in _flames:
			f.emitting = false
		_embers.emitting = false)
	var puff := _smoke.duplicate() as CPUParticles3D
	puff.one_shot = true
	puff.explosiveness = 0.9
	puff.amount = 26
	puff.gravity = Vector3(toward * 3.0, 0.8, 0.0)
	puff.initial_velocity_min = 1.0
	puff.initial_velocity_max = 3.0
	puff.position.y = 1.2
	add_child(puff)
	puff.emitting = true
	var sparks := _embers.duplicate() as CPUParticles3D
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 50
	sparks.gravity = Vector3(toward * 6.0, -1.0, 0.0)
	sparks.initial_velocity_min = 3.0
	sparks.initial_velocity_max = 7.0
	sparks.direction = Vector3(toward, 0.6, 0.0)
	add_child(sparks)
	sparks.emitting = true
	var dim := create_tween()
	dim.tween_property(_light, "light_energy", 0.0, 0.8)
	var slump := create_tween()
	slump.tween_interval(0.3)
	slump.tween_property(_heap, "scale", Vector3(1.05, 0.45, 1.0), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	slump.tween_callback(func() -> void: _smoke.amount = 8)
	blown_out.emit()
