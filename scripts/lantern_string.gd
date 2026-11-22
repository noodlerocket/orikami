class_name LanternString
extends Node3D
## A rope strung across the street between two poles, sagging, with paper
## lanterns hanging from it. The lanterns hang in the gameplay plane, so the
## sword reaches them: cut down onto one in the air and he bounces off it
## (pogo), lantern to lantern, up to the rooftops. Struck, a lantern swings
## hard, its light flickers, and it settles. They sway in the wind like all
## the others.
## Origin: the street at the left pole.

## Length of the rope (metres).
@export var span := 9.0
## Height of the rope where it is tied to the poles.
@export var height := 6.4
## How far the rope sags in the middle.
@export var sag := 1.1
## How many lanterns hang from it.
@export var count := 4
## Tied to short posts standing on rooftops at each end (behind the ridge),
## instead of tall poles from the street.
@export var on_roofs := false
## How hard a cut swings a lantern.
@export var strike_swing := 3.2

var _lanterns: Array[Node3D] = []
var _lights: Array[OmniLight3D] = []
var _angle: Array[float] = []
var _spin: Array[float] = []
var _flicker: Array[float] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 17.0)
	_build(rng)


## Height of the rope at `x` metres from the left pole.
func rope_at(x: float) -> float:
	var t := clampf(x / span, 0.0, 1.0)
	return height - sag * sin(t * PI)


func _build(rng: RandomNumberGenerator) -> void:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.2
	b.color = PaperMesh.TIMBER
	# A pole at each end, standing just behind the path, with a short arm
	# out over it that the rope is tied to.
	for px: float in [0.0, span]:
		if on_roofs:
			# A short post on the roof's back slope, and an arm out to the rope.
			b.box(Vector3(px, height - 0.55, -0.75), Vector3(0.1, 1.5, 0.1))
			b.box(Vector3(px, height + 0.05, -0.4), Vector3(0.08, 0.08, 0.8))
		else:
			b.box(Vector3(px, (height + 0.5) * 0.5, -1.2), Vector3(0.14, height + 0.5, 0.14))
			b.box(Vector3(px, height + 0.05, -0.6), Vector3(0.1, 0.1, 1.3))
	add_child(b.build())
	# The rope: short straight lengths following the sag.
	var rope := PaperMesh.new(rng.randi())
	rope.color = Color(0.32, 0.28, 0.24)
	var steps := 18
	for k in steps:
		var x0 := span * k / steps
		var x1 := span * (k + 1) / steps
		rope.stroke(Vector2(x0, rope_at(x0)), Vector2(x1, rope_at(x1)), 0.035, 0.035, 0.0)
	var rope_mesh := rope.build()
	rope_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rope_mesh)
	# The lanterns, evenly along it, each with its own light and a target for
	# the sword.
	for i in count:
		var x := span * (i + 1.0) / (count + 1.0)
		var size := rng.randf_range(0.78, 0.9)
		var lantern := Scenery.lantern(rng, 2.0, size, 0.22)
		lantern.position = Vector3(x, rope_at(x), 0.0)
		add_child(lantern)
		var light := OmniLight3D.new()
		light.light_color = PaperMesh.LANTERN
		light.light_energy = 2.2
		light.omni_range = 4.5
		light.omni_attenuation = 2.0
		light.position = (lantern.get_meta("light_at") as Vector3) + Vector3(0.0, 0.0, 0.6)
		lantern.add_child(light)
		var centre: Vector3 = lantern.get_meta("light_at")
		var sphere := SphereShape3D.new()
		sphere.radius = 0.34
		var target := PropTarget.make(lantern, sphere, centre)
		target.struck.connect(_on_struck.bind(i))
		_lanterns.append(lantern)
		_lights.append(light)
		_angle.append(0.0)
		_spin.append(0.0)
		_flicker.append(0.0)


func _on_struck(direction: Vector2, index: int) -> void:
	# Pushed the way the blade went; a cut from above shoves it sideways a little.
	var push := direction.x if direction.x != 0.0 else (0.4 if randf() < 0.5 else -0.4)
	_spin[index] += -push * strike_swing
	_flicker[index] = 1.0
	Sound.play(self, &"paper_fold", -3.0)


func _physics_process(delta: float) -> void:
	var t := Wind.now()
	for i in _lanterns.size():
		var lantern := _lanterns[i]
		var blow := Wind.speed_at(lantern.global_position.x)
		# A pendulum: pulled back to hanging straight, leaning with the wind,
		# rocked gently, and swung hard when struck.
		var rest := -blow * 0.02 + sin(t * 2.0 + i * 1.7) * 0.016 * blow
		_spin[i] += (-(_angle[i] - rest) * 26.0 - _spin[i] * 1.6) * delta
		_angle[i] += _spin[i] * delta
		lantern.rotation.z = _angle[i]
		# Its light gutters for a moment after a knock.
		_flicker[i] = maxf(_flicker[i] - delta * 1.5, 0.0)
		var gutter := 1.0 - _flicker[i] * (0.5 + 0.5 * sin(t * 40.0 + i))
		_lights[i].light_energy = 2.2 * gutter
