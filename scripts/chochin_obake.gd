class_name ChochinObake
extends PaperCritter
## Chōchin-obake: a paper lantern gone wrong (the lantern makers' Rise). Its
## paper split open into a mouth of ragged teeth, one great eye, a long red
## tongue lolling out; the candle still burns inside it, so it glows. It
## floats and bobs about its spot, tongue swinging. When he comes near it
## swells up, its eye goes wide, its flame flares and it cackles (the tell),
## then lunges at him, tongue lashing (it burns: parry it and it tumbles
## down, sputtering, for a finishing cut). Cut from above, he bounces off
## it. Each cut makes its candle gutter. Three cuts tear it apart. The Fan
## Gust blows it back and nearly puts its flame out.

@export_group("Floating")
## Half the width and height of the little loop it bobs round its spot.
@export var drift := Vector2(1.4, 0.4)
@export var drift_time := 5.0
## It lunges when he is within this far (any way).
@export var notice := 5.0
@export_group("Attack")
@export var windup := 0.55
@export var lunge_speed := 9.0
@export var lunge_time := 0.5
@export var attack_damage := 1
@export var cooldown := 1.8

const WASHI := Color(0.86, 0.8, 0.66)
## The Meshy model (Julian: a model, not the lantern folded in code; picture
## docs/reference/chochin_front.png, image-to-image from the kite husk's
## picture, nano-banana-pro: 01a20c1b-79b3-771b-ba39-a80d693fd3be; model
## meshy-7.1 + meshy-7 2K, remeshed to 12,000: 01a20c1c-b01b-7630-95d7-e16228a6d0da).
## Its tongue's tip is given a bone here (ProceduralSkin) so it lolls and lashes.
const MODEL := preload("res://models/chochin.glb")
@export var use_model := true
## The model's height in the world (it is 1.9 m as Meshy made it).
@export var model_height := 1.0
const LACQUER := Color(0.36, 0.12, 0.1)

var home := Vector3.ZERO
var _phase := 0.0
var _wait := 1.0
var _aim := Vector3.ZERO
var _struck := false
var _body: Node3D
var _eye: Node3D
var _tongue: Array[Node3D] = []
var _light: OmniLight3D
var _gutter := 0.0
var _skin: ProceduralSkin


func _ready() -> void:
	max_health = 3
	max_posture = 1
	confetti_count = 28
	confetti_colors = [WASHI, LACQUER, Color(0.95, 0.6, 0.25)]
	hurt_kind = &"fire"
	super._ready()
	home = global_position
	_phase = fposmod(global_position.x * 0.29, 1.0)
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.38 if not use_model else 0.42
	shape.shape = ball
	shape.position.y = 0.4 if not use_model else 0.5
	add_child(shape)
	if use_model:
		_make_touch(Vector3(0.8, 1.0, 1.0), Vector3(0.0, 0.5, 0.0))
	else:
		_make_touch(Vector3(0.75, 0.85, 1.0), Vector3(0.0, 0.4, 0.0))


func _body_centre() -> Vector3:
	return Vector3(0.0, 0.5 if use_model else 0.4, 0.0)


func _build() -> void:
	if use_model:
		_build_model()
		return
	var seed_value := int(global_position.x * 19.0) + 5
	_body = Node3D.new()
	_body.position.y = 0.4
	_rig.add_child(_body)
	# The lantern: ribbed rings of washi, lacquered caps top and bottom.
	var b := PaperMesh.new(seed_value)
	b.texture_world = false
	b.shade_jitter = 0.12
	var rings := []
	for k in 8:
		var t := k / 7.0
		var r := 0.36 * sin(PI * (0.12 + 0.76 * t)) + 0.04
		rings.append(PaperMesh.oval(Vector3(0.0, -0.38 + t * 0.76, 0.0), Vector2(r, r), 12))
	b.color = WASHI
	b.loft(rings, false, false)
	b.color = LACQUER
	b.frustum(12, Vector2(0.17, 0.17), Vector2(0.17, 0.17), 0.08, Vector3(0.0, 0.36, 0.0))
	b.frustum(12, Vector2(0.17, 0.17), Vector2(0.17, 0.17), 0.08, Vector3(0.0, -0.44, 0.0))
	# Dark ribs round it.
	b.color = Color(0.22, 0.14, 0.1)
	for k in 6:
		var t := (k + 0.5) / 6.0
		var r := 0.36 * sin(PI * (0.12 + 0.76 * t)) + 0.045
		b.frustum(12, Vector2(r, r), Vector2(r, r), 0.012, Vector3(0.0, -0.38 + t * 0.76, 0.0))
	_part(_body, b.build(Color.WHITE, 0.55))
	# The torn mouth on its front, ragged teeth, the dark inside.
	var m := PaperMesh.new(seed_value + 1)
	m.texture_world = false
	m.color = Color(0.08, 0.03, 0.02)
	var lips := PackedVector2Array()
	for k in 14:
		var a := TAU * k / 14.0
		lips.append(Vector2(cos(a) * 0.24, sin(a) * 0.11 - 0.08))
	m.polygon(PaperMesh.tear(lips, 0.06, 0.03, RandomNumberGenerator.new()), 0.0)
	m.color = WASHI.lightened(0.1)
	for k in 6:
		var x := -0.18 + k * 0.072
		m.tri(Vector3(x - 0.03, 0.03, 0.002), Vector3(x + 0.03, 0.03, 0.002), Vector3(x, -0.04, 0.002))
		m.tri(Vector3(x - 0.03, -0.19, 0.002), Vector3(x, -0.12, 0.002), Vector3(x + 0.03, -0.19, 0.002))
	var mouth := m.build()
	mouth.position = Vector3(0.0, 0.0, 0.37)
	_body.add_child(mouth)
	_flash_meshes.append(mouth)
	# One great eye above it.
	_eye = Node3D.new()
	_eye.position = Vector3(0.04, 0.16, 0.36)
	_body.add_child(_eye)
	var e := PaperMesh.new(seed_value + 2)
	e.texture_world = false
	e.color = Color(0.95, 0.93, 0.86)
	e.ellipse(Vector2.ZERO, Vector2(0.11, 0.08), 14, 0.0)
	e.color = Color(0.05, 0.04, 0.04)
	e.ellipse(Vector2(0.015, -0.005), Vector2(0.04, 0.045), 10, 0.003)
	e.color = Color(0.6, 0.12, 0.08)
	e.stroke(Vector2(-0.12, 0.09), Vector2(0.12, 0.06), 0.02, 0.01, 0.004)
	_eye.add_child(e.build())
	# The tongue: a long red strip out of the mouth, in pieces so it swings.
	var parent := _body
	for k in 4:
		var bit := Node3D.new()
		bit.position = Vector3(0.0, -0.13, 0.4) if k == 0 else Vector3(0.0, -0.12, 0.0)
		parent.add_child(bit)
		var t := PaperMesh.new(seed_value + 3 + k)
		t.texture_world = false
		t.color = Color(0.68, 0.18, 0.18)
		var w := 0.07 - k * 0.012
		t.box(Vector3(0.0, -0.06, 0.0), Vector3(w, 0.13, 0.015))
		_part(bit, t.build())
		_tongue.append(bit)
		parent = bit
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.3)
	_light.light_energy = 1.4
	_light.omni_range = 4.0
	_light.position = Vector3(0.0, 0.4, 0.0)
	add_child(_light)


## The Meshy lantern: its tongue's tip on a bone (measured from the model:
## the tongue hangs down the front, its tip standing out past z 0.5 below
## y -0.5; above that it lies on the paper, so only the tip can swing
## without tearing the lantern).
func _build_model() -> void:
	_body = Node3D.new()
	_body.position.y = 0.5
	_rig.add_child(_body)
	var scene: Node3D = MODEL.instantiate()
	var src := scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_skin = ProceduralSkin.new()
	var root := _skin.add_bone("lantern", -1, Vector3.ZERO)
	_skin.add_bone("tongue", root, Vector3(0.05, -0.5, 0.52))
	_skin.finish()
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * (model_height / 1.9)
	_body.add_child(holder)
	holder.add_child(_skin.skeleton)
	var mesh := _skin.skin("chochin", src.mesh, src.get_active_material(0), func(v: Vector3) -> PackedFloat32Array:
		var tip := ProceduralSkin.ramp(-0.48, -0.62, v.y) * ProceduralSkin.ramp(0.46, 0.56, v.z)
		return PackedFloat32Array([1.0 - tip, tip]))
	_flash_meshes.append(mesh)   # (skin() has put it on the skeleton)
	scene.free()
	_eye = Node3D.new()   # (the model's eye: nothing to scale)
	_body.add_child(_eye)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.3)
	_light.light_energy = 1.4
	_light.omni_range = 4.0
	_light.position = Vector3(0.0, 0.5, 0.0)
	add_child(_light)


func _physics_process(delta: float) -> void:
	_tick(delta)
	_wait = maxf(_wait - delta, 0.0)
	var player := get_tree().get_first_node_in_group(&"player") as Ronin
	match mode:
		&"tell":
			velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
			if _mode_time >= windup:
				_set_mode(&"lunge")
				_struck = false
				Sound.play(self, &"fire_whoosh", -4.0)
		&"lunge":
			velocity = _aim * lunge_speed
			if not _struck:
				_strike()
			if _mode_time >= lunge_time or is_on_wall() or is_on_floor():
				_set_mode(&"recover")
				_wait = cooldown
		&"stagger":
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.y = maxf(velocity.y - 16.0 * delta, -6.0)
			if _mode_time >= stagger_time:
				posture = 0
				_set_mode(&"recover")
		&"knocked":
			velocity = velocity.move_toward(Vector3.ZERO, 9.0 * delta)
			if _mode_time >= 0.45:
				_set_mode(&"recover")
		&"recover":
			var goal := _drift_point()
			velocity = (goal - global_position).limit_length(1.0) * 3.5
			if global_position.distance_to(goal) < 0.3 or _mode_time > 3.0:
				_set_mode(&"patrol")
		_:
			_phase = fposmod(_phase + delta / drift_time, 1.0)
			velocity = (_drift_point() - global_position) * 3.0
			if player and _wait <= 0.0:
				var d := player.global_position + Vector3(0.0, 0.9, 0.0) - (global_position + _body_centre())
				if d.length() < notice:
					_dir = signf(d.x) if d.x != 0.0 else _dir
					_aim = d.normalized()
					_set_mode(&"tell")
					Sound.play(self, &"chochin_cackle")
	move_and_slide()
	position.z = 0.0
	if mode == &"lunge":
		_check_touch()


func _drift_point() -> Vector3:
	var a := _phase * TAU
	return home + Vector3(sin(a) * drift.x, sin(a * 2.0) * drift.y + sin(_clock * 1.7) * 0.1, 0.0)


func _strike() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + _body_centre() + _aim * 0.35)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_struck = true
			if target.receive_strike(attack_damage, global_position, &"fire"):
				velocity = Vector3(-_aim.x * 4.0, 2.0, 0.0)
				_on_parried()
			return


func _on_hit(direction: Vector2) -> void:
	_gutter = 1.0
	if mode == &"stagger":
		return
	velocity = Vector3(direction.x * 5.0, -4.0 if direction.y < -0.5 else 1.5, 0.0)
	_set_mode(&"knocked")


func gusted(direction: Vector3, from: Vector3) -> void:
	super.gusted(direction, from)
	_gutter = 1.0


func _pose() -> void:
	# Turned three-quarters to us, the way it faces.
	_rig.rotation.y = 0.9 if _dir > 0.0 else -0.9
	var swell := 1.0
	var eye := 1.0
	var lash := 0.0
	var tilt := 0.0
	match mode:
		&"tell":
			var u := clampf(_mode_time / windup, 0.0, 1.0)
			swell = 1.0 + 0.18 * u + sin(_clock * 40.0) * 0.02
			eye = 1.0 + 0.6 * u
			tilt = -0.25 * u
		&"lunge":
			swell = 0.92
			eye = 1.5
			lash = 1.0
			tilt = 0.35
		&"stagger":
			swell = 0.85
			eye = 0.25
			tilt = -0.6 + sin(_clock * 3.0) * 0.1
		&"knocked":
			tilt = sin(_clock * 20.0) * 0.3
		_:
			tilt = sin(_clock * 1.6) * 0.08
	_body.scale = Vector3(swell, 1.0 / sqrt(swell), swell)
	_body.rotation.z = tilt
	_eye.scale = Vector3(1.0, eye, 1.0)
	if _skin:
		var lolling := sin(_clock * 3.0) * 0.3
		_skin.turns[1] = Quaternion(Vector3.RIGHT, lerpf(lolling, -1.1, lash)) * Quaternion(Vector3.FORWARD, sin(_clock * 2.1) * 0.2)
		_skin.apply()
	for i in _tongue.size():
		var lolling := sin(_clock * 3.0 - i * 0.8) * 0.25
		_tongue[i].rotation.x = lerpf(lolling + 0.15, -1.3 if i == 0 else 0.05, lash)
		_tongue[i].scale = Vector3.ONE * (1.0 + lash * 0.6)


func _process(delta: float) -> void:
	super._process(delta)
	# Its candle: flickering, flaring in the tell, guttering when cut.
	_gutter = maxf(_gutter - delta * 0.8, 0.0)
	var flare := 1.6 if mode == &"tell" else 1.0
	_light.light_energy = (1.3 + 0.25 * sin(_clock * 17.0) + 0.15 * sin(_clock * 41.0)) * flare * (1.0 - _gutter * 0.8)
