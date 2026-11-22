class_name MarketStall
extends Node3D
## A market stall standing in the street: four poles, a low counter set back
## out of the way, goods on it, and a paper awning stretched over the top.
## Each stall has its own trade (`kind`), and looks it: a greengrocer with
## baskets of persimmons and radishes, a noodle stand with a steaming pot, a
## fishmonger with dried fish swinging from the awning's edge.
## The awning is something to stand on (it is solid: get onto it from the
## side, never up through it):
##  - land on it and it sags under him and springs back;
##  - land on it from high enough and it throws him up again (a bounce),
##    so stalls are steps up to the rooftops.
## Origin: on the street at the middle of the stall.

## What the stall sells: "produce", "noodles" or "fish".
@export var kind := "produce"
## Width of the awning (metres).
@export var width := 3.2
## Height of the awning's top.
@export var top := 2.7
## How fast he must be falling (m/s) for the awning to throw him back up.
@export var bounce_from := 7.0
## How fast it throws him up.
@export var bounce_speed := 11.5
## How far it sags when he lands (metres, at most).
@export var sag_depth := 0.22

var ronin: Ronin

var _body: AnimatableBody3D
var _cloth: Node3D
var _sag := 0.0
var _sag_speed := 0.0
var _was_on := false
var _last_fall := 0.0
var _steam: CPUParticles3D


func _ready() -> void:
	process_physics_priority = 10  # after the Ronin has moved
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 31.0)
	_build(rng)


func _build(rng: RandomNumberGenerator) -> void:
	var half := width * 0.5
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.22
	b.color = PaperMesh.TIMBER
	# Poles: two at the front (toward the camera), two at the back.
	for px: float in [-half + 0.1, half - 0.1]:
		for pz: float in [1.0, -1.0]:
			b.box(Vector3(px, top * 0.5, pz), Vector3(0.09, top, 0.09))
	# The counter, set back behind the path, and goods on it.
	b.color = Scenery.WOOD
	b.box(Vector3(0.0, 0.8, -1.25), Vector3(width - 0.3, 0.08, 0.6))
	b.color = Scenery.WOOD.darkened(0.3)
	b.box(Vector3(0.0, 0.4, -1.38), Vector3(width - 0.4, 0.8, 0.3))
	match kind:
		"noodles": _noodle_goods(b, rng, half)
		"fish": _fish_goods(b, rng, half)
		_: _produce_goods(b, rng, half)
	add_child(b.build())

	# The awning: a frame of thin bamboo with paper stretched over it,
	# sloping a little toward the camera, its front edge hanging in a fringe.
	_cloth = Node3D.new()
	add_child(_cloth)
	var sheet := PaperMesh.new(rng.randi())
	sheet.shade_jitter = 0.12
	# Each trade's awning its own faded colour.
	var tint: Color = {"produce": Color(0.64, 0.56, 0.42), "noodles": Color(0.3, 0.33, 0.48), "fish": Color(0.52, 0.52, 0.5)}.get(kind, Color(0.6, 0.56, 0.52))
	sheet.color = tint
	var back := Vector3(0.0, top + 0.14, -1.15)
	var front := Vector3(0.0, top - 0.04, 1.2)
	sheet.quad(back + Vector3(-half - 0.1, 0, 0), back + Vector3(half + 0.1, 0, 0), front + Vector3(half + 0.1, 0, 0),
			front + Vector3(-half - 0.1, 0, 0), Vector3(0.0, 1.0, 0.1))
	# Faded stripes across it.
	sheet.color = tint.darkened(0.22)
	var sx := -half + 0.2
	while sx < half - 0.2:
		var sx1 := minf(sx + 0.28, half + 0.1)
		sheet.quad(back + Vector3(sx, 0.006, 0), back + Vector3(sx1, 0.006, 0), front + Vector3(sx1, 0.006, 0),
				front + Vector3(sx, 0.006, 0), Vector3(0.0, 1.0, 0.1))
		sx += 0.56
	# The fringe along the front edge: a row of torn paper tassels, each
	# hanging from the edge on its own, so each sways on its own in the wind
	# (one strip turning as a whole see-sawed about its middle: Julian).
	var fx := -half - 0.1
	while fx < half + 0.05:
		var wide := rng.randf_range(0.12, 0.2)
		var tassel := Node3D.new()
		tassel.position = front + Vector3(fx + wide * 0.5, 0.0, 0.01)
		_cloth.add_child(tassel)
		var piece := PaperMesh.new(rng.randi())
		piece.color = tint.darkened(rng.randf_range(0.06, 0.18))
		var drop := rng.randf_range(0.18, 0.34)
		piece.polygon(PackedVector2Array([Vector2(-wide * 0.5, 0.0), Vector2(wide * 0.5, 0.0),
				Vector2(wide * 0.5 - 0.02, -drop * rng.randf_range(0.75, 1.0)), Vector2(rng.randf_range(-0.03, 0.03), -drop),
				Vector2(-wide * 0.5 + 0.02, -drop * rng.randf_range(0.75, 1.0))]))
		var strip := piece.build()
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tassel.add_child(strip)
		Scenery.windswept(tassel, 0.035, rng)
		fx += wide + 0.01
	var cloth_mesh := sheet.build()
	_cloth.add_child(cloth_mesh)

	# What he stands on: the awning's top, moving with it as it sags.
	_body = AnimatableBody3D.new()
	_body.sync_to_physics = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.2, 2.2)
	shape.shape = box
	_body.add_child(shape)
	_body.position = Vector3(0.0, top - 0.1 + 0.05, 0.0)
	add_child(_body)


func _physics_process(delta: float) -> void:
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if ronin == null:
			return
	var feet := ronin.global_position.y
	var surface := global_position.y + top - _sag
	var over := absf(ronin.global_position.x - global_position.x) < width * 0.5 + 0.3

	var on := over and ronin.is_on_floor() and absf(feet - surface) < 0.2
	if on and not _was_on:
		# Landed on it: it gives under him, more the harder he came down.
		_sag_speed += clampf(-_last_fall, 2.0, 14.0) * 0.18
		Sound.play(self, &"paper_fold", -6.0)
		if -_last_fall >= bounce_from:
			ronin.velocity.y = bounce_speed
			_sag_speed += 1.2
			Sound.play(self, &"jump", -4.0)
	_was_on = on
	_last_fall = ronin.velocity.y
	# The sag springs back, overshooting a little, like stretched paper.
	var weight := 0.35 if on else 0.0
	_sag_speed += (-(_sag - weight * sag_depth * 0.25) * 90.0 - _sag_speed * 7.0) * delta
	_sag = clampf(_sag + _sag_speed * delta, -sag_depth * 0.5, sag_depth)
	_cloth.position.y = -_sag
	_body.position.y = top - 0.05 - _sag


# --- What each trade sells ----------------------------------------------------

## Greengrocer: shallow baskets of persimmons, a pile of white radishes, a
## bundle of greens, and a string of dried persimmons hanging at the front.
func _produce_goods(b: PaperMesh, rng: RandomNumberGenerator, half: float) -> void:
	var x := -half + 0.45
	while x < half - 0.5:
		var basket := rng.randf_range(0.42, 0.55)
		b.color = Color(0.42, 0.34, 0.22)
		b.frustum(8, Vector2(basket * 0.42, basket * 0.32), Vector2(basket * 0.5, basket * 0.38), 0.12, Vector3(x, 0.84, -1.22))
		var fruit: Color = [Color(0.62, 0.3, 0.14), Color(0.7, 0.66, 0.6), Color(0.3, 0.36, 0.2)][rng.randi() % 3]
		for k in rng.randi_range(4, 6):
			b.color = fruit * rng.randf_range(0.85, 1.1)
			var at := Vector3(x + rng.randf_range(-0.16, 0.16), 1.0 + rng.randf_range(0.0, 0.06), -1.22 + rng.randf_range(-0.1, 0.1))
			b.frustum(6, Vector2(0.06, 0.06), Vector2(0.05, 0.05), 0.08, at)
		x += basket + rng.randf_range(0.08, 0.2)
	# White radishes lying in a heap at one end.
	b.color = Color(0.78, 0.76, 0.7)
	for k in 5:
		b.box(Vector3(half - 0.45 + rng.randf_range(-0.1, 0.1), 0.9 + k * 0.03, -1.3 + k * 0.05), Vector3(0.36, 0.07, 0.07))
	# Dried persimmons on strings from the front bar (they swing in the wind).
	for k in 2:
		var hang := Node3D.new()
		hang.position = Vector3(-half * 0.5 + k * half, top - 0.05, 1.05)
		add_child(hang)
		var strand := PaperMesh.new(rng.randi())
		strand.color = Color(0.3, 0.25, 0.2)
		strand.stroke(Vector2(0.0, 0.0), Vector2(0.0, -0.7), 0.015, 0.015, 0.0)
		strand.color = Color(0.5, 0.24, 0.12)
		for f in 5:
			strand.ellipse(Vector2(0.0, -0.12 - f * 0.13), Vector2(0.045, 0.055), 7, 0.01)
		hang.add_child(strand.build())
		Scenery.windswept(hang, 0.06, rng)


## Noodle stand: a big pot steaming on a brazier, stacked bowls, a ladle,
## a small lantern, and steam rising and drifting with the wind.
func _noodle_goods(b: PaperMesh, rng: RandomNumberGenerator, half: float) -> void:
	b.color = Color(0.16, 0.15, 0.17)
	b.frustum(10, Vector2(0.3, 0.3), Vector2(0.34, 0.34), 0.32, Vector3(-half * 0.45, 0.84, -1.22))
	b.color = Color(0.3, 0.12, 0.08)
	b.box(Vector3(-half * 0.45, 0.88, -1.22), Vector3(0.5, 0.06, 0.3))
	b.color = Color(0.2, 0.2, 0.24)
	b.box(Vector3(-half * 0.45 + 0.3, 1.25, -1.22), Vector3(0.03, 0.03, 0.42))
	# Bowls, stacked unevenly.
	for stack in 3:
		var sx := half * 0.1 + stack * 0.32
		for k in rng.randi_range(2, 5):
			b.color = [Color(0.66, 0.62, 0.56), Color(0.3, 0.34, 0.48)][(stack + k) % 2]
			b.frustum(8, Vector2(0.08, 0.08), Vector2(0.12, 0.12), 0.06, Vector3(sx, 0.84 + k * 0.055, -1.2))
	# Steam.
	_steam = CPUParticles3D.new()
	_steam.amount = 14
	_steam.lifetime = 2.2
	_steam.preprocess = 2.0
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_steam.emission_sphere_radius = 0.18
	_steam.direction = Vector3.UP
	_steam.spread = 12.0
	_steam.gravity = Vector3(0.0, 0.25, 0.0)
	_steam.initial_velocity_min = 0.25
	_steam.initial_velocity_max = 0.45
	_steam.scale_amount_min = 0.8
	_steam.scale_amount_max = 1.5
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.3))
	grow.add_point(Vector2(1.0, 1.0))
	_steam.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.25, Color(1, 1, 1, 0.22))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0.0))
	_steam.color_ramp = fade
	var puff := QuadMesh.new()
	puff.size = Vector2(0.4, 0.4)
	puff.material = PaperMesh.soft_ink(Color(0.8, 0.82, 0.9))
	_steam.mesh = puff
	_steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_steam.position = Vector3(-half * 0.45, 1.25, -1.2)
	add_child(_steam)
	var lamp := Scenery.lantern(rng, 1.8, 0.55, 0.15)
	lamp.position = Vector3(half - 0.35, top - 0.05, 0.9)
	add_child(lamp)
	Scenery.windswept(lamp, 0.02, rng)


## Fishmonger: a wooden tray of fish on the counter, a tub, and dried fish
## strung from the awning's front bar, swinging.
func _fish_goods(b: PaperMesh, rng: RandomNumberGenerator, half: float) -> void:
	b.color = Scenery.WOOD.darkened(0.2)
	b.box(Vector3(-half * 0.25, 0.88, -1.22), Vector3(1.1, 0.07, 0.45))
	for k in 6:
		b.color = Color(0.46, 0.5, 0.56) * rng.randf_range(0.8, 1.1)
		var at := Vector3(-half * 0.25 - 0.42 + k * 0.17, 0.95, -1.22 + rng.randf_range(-0.08, 0.08))
		b.box(at, Vector3(0.07, 0.04, 0.34))
	b.color = Scenery.WOOD
	b.frustum(9, Vector2(0.26, 0.26), Vector2(0.3, 0.3), 0.42, Vector3(half * 0.55, 0.0, -1.2))
	var x := -half + 0.35
	while x < half - 0.3:
		var hang := Node3D.new()
		hang.position = Vector3(x, top - 0.05, 1.05)
		add_child(hang)
		var fish := PaperMesh.new(rng.randi())
		fish.color = Color(0.3, 0.27, 0.22)
		fish.stroke(Vector2(0.0, 0.0), Vector2(0.0, -0.18), 0.012, 0.012, 0.0)
		fish.color = Color(0.5, 0.5, 0.48) * rng.randf_range(0.75, 1.0)
		var long := rng.randf_range(0.34, 0.5)
		fish.polygon(PackedVector2Array([Vector2(0.0, -0.18), Vector2(0.06, -0.24), Vector2(0.05, -0.18 - long * 0.8),
				Vector2(0.08, -0.18 - long), Vector2(-0.08, -0.18 - long), Vector2(-0.05, -0.18 - long * 0.8),
				Vector2(-0.06, -0.24)]))
		hang.add_child(fish.build())
		Scenery.windswept(hang, 0.07, rng)
		x += rng.randf_range(0.3, 0.5)
