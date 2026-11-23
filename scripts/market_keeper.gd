class_name MarketKeeper
extends Node3D
## A shopkeeper behind a stall in the Lantern Market (Julian's picture): a
## paper doll in a kimono, its face hidden under a mask of gold leaf (Hōshō's
## people, like him, hide from the Rain under gold and feel nothing).
## Alive: it breathes, works at its wares, glances up to watch him go by,
## and bows as he passes in front of its counter.
## Origin: the floor under it (it stands behind a counter about 1 m high).

## The kimono's colour.
@export var robe := Color(0.55, 0.17, 0.14)
## What it does with its hands: "idle", "fan" (fans a grill), "pour" (tips a
## sake flask), "fold" (folds paper).
@export var work := "idle"
## How near he must come before it looks up at him (metres).
@export var notice_distance := 4.5
## How near before it bows (metres).
@export var bow_distance := 1.4
## How deep the bow is (radians).
@export var bow_depth := 0.42
## A headband (the grill cook).
@export var headband := false

const GOLD := Color(0.86, 0.68, 0.34)
const GOLD_DARK := Color(0.56, 0.4, 0.18)

var _torso: Node3D
var _head: Node3D
var _arm: Node3D
var _ronin: Node3D
var _phase := 0.0
var _look := 0.0
var _bow_time := -10.0
var _bowed := false


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 13.0 + global_position.y * 7.0)
	_phase = rng.randf() * TAU
	_build(rng)


func _build(rng: RandomNumberGenerator) -> void:
	# The skirt of the kimono, from the floor to the hips (mostly hidden by
	# the counter).
	var low := PaperMesh.new(rng.randi())
	low.shade_jitter = 0.12
	low.color = robe.darkened(0.15)
	low.frustum(8, Vector2(0.3, 0.2), Vector2(0.24, 0.16), 0.85, Vector3.ZERO)
	add_child(low.build())
	_torso = Node3D.new()
	_torso.position.y = 0.85
	add_child(_torso)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.12
	b.color = robe
	b.loft([PaperMesh.oval(Vector3(0.0, 0.0, 0.0), Vector2(0.24, 0.16), 9),
			PaperMesh.oval(Vector3(0.0, 0.2, 0.0), Vector2(0.21, 0.14), 9),
			PaperMesh.oval(Vector3(0.0, 0.45, 0.0), Vector2(0.25, 0.16), 9),
			PaperMesh.oval(Vector3(0.0, 0.58, 0.0), Vector2(0.27, 0.15), 9),
			PaperMesh.oval(Vector3(0.0, 0.64, 0.0), Vector2(0.1, 0.08), 9)])
	# The obi (gold leaf) and the white collar crossing at the front.
	b.color = GOLD_DARK
	b.frustum(9, Vector2(0.225, 0.155), Vector2(0.22, 0.15), 0.16, Vector3(0.0, 0.1, 0.0))
	b.color = PaperMesh.WASHI.darkened(0.1)
	b.stroke(Vector2(-0.12, 0.6), Vector2(0.02, 0.34), 0.05, 0.03, 0.155)
	b.stroke(Vector2(0.12, 0.6), Vector2(-0.02, 0.34), 0.05, 0.03, 0.157)
	# Gold-leaf sakura printed on the robe.
	b.color = GOLD.darkened(0.1)
	for k in 4:
		var at := Vector2(rng.randf_range(-0.16, 0.16), rng.randf_range(0.3, 0.55))
		for p in 5:
			var a := TAU * p / 5.0
			b.ellipse(at + Vector2(cos(a), sin(a)) * 0.022, Vector2(0.018, 0.018), 5, 0.16 + k * 0.001)
	# The far sleeve, hanging (the near arm moves).
	b.color = robe.darkened(0.08)
	b.box(Vector3(-0.3, 0.36, 0.0), Vector3(0.13, 0.42, 0.26))
	_torso.add_child(b.build())
	# The head: on a neck, the gold mask on the front, black hair in a knot.
	_head = Node3D.new()
	_head.position.y = 0.66
	_torso.add_child(_head)
	var h := PaperMesh.new(rng.randi())
	h.shade_jitter = 0.1
	h.color = Color(0.08, 0.07, 0.09)
	h.loft([PaperMesh.oval(Vector3(0.0, 0.0, -0.01), Vector2(0.08, 0.08), 8),
			PaperMesh.oval(Vector3(0.0, 0.12, -0.02), Vector2(0.135, 0.13), 8),
			PaperMesh.oval(Vector3(0.0, 0.25, -0.02), Vector2(0.125, 0.12), 8),
			PaperMesh.oval(Vector3(0.0, 0.31, -0.03), Vector2(0.05, 0.05), 8)])
	h.frustum(8, Vector2(0.07, 0.07), Vector2(0.05, 0.05), 0.09, Vector3(0.0, 0.3, -0.06))
	h.color = PaperMesh.VERMILION.darkened(0.2)
	h.box(Vector3(0.0, 0.33, -0.06), Vector3(0.15, 0.025, 0.025))  # a pin through the knot
	if headband:
		h.color = PaperMesh.WASHI.darkened(0.05)
		h.frustum(8, Vector2(0.14, 0.135), Vector2(0.14, 0.135), 0.045, Vector3(0.0, 0.2, -0.02))
	_head.add_child(h.build())
	var mask := PaperMesh.new(rng.randi())
	mask.shade_jitter = 0.05
	mask.color = GOLD
	mask.ellipse(Vector2(0.0, 0.12), Vector2(0.1, 0.13), 12, 0.118)
	mask.color = Color(0.12, 0.09, 0.06)
	for side: float in [-1.0, 1.0]:
		mask.stroke(Vector2(side * 0.06, 0.15), Vector2(side * 0.025, 0.14), 0.016, 0.01, 0.121)
	mask.stroke(Vector2(-0.025, 0.055), Vector2(0.025, 0.055), 0.008, 0.008, 0.121)
	var m := mask.build(Color.WHITE, 0.25)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_head.add_child(m)
	# The near arm: a sleeve and a gold hand, holding what it works with.
	_arm = Node3D.new()
	_arm.position = Vector3(0.27, 0.56, 0.02)
	_torso.add_child(_arm)
	var a := PaperMesh.new(rng.randi())
	a.shade_jitter = 0.12
	a.color = robe.darkened(0.04)
	a.box(Vector3(0.04, -0.2, 0.08), Vector3(0.14, 0.4, 0.24))
	a.color = GOLD
	a.box(Vector3(0.04, -0.42, 0.16), Vector3(0.07, 0.08, 0.07))
	match work:
		"fan":
			a.color = PaperMesh.WASHI.darkened(0.1)
			a.polygon(PackedVector2Array([Vector2(0.04, -0.44), Vector2(-0.12, -0.68), Vector2(0.06, -0.74), Vector2(0.22, -0.66)]), 0.2)
		"pour":
			a.color = PaperMesh.WASHI.darkened(0.15)
			a.loft([PaperMesh.oval(Vector3(0.04, -0.62, 0.17), Vector2(0.05, 0.05), 8),
					PaperMesh.oval(Vector3(0.04, -0.52, 0.17), Vector2(0.07, 0.07), 8),
					PaperMesh.oval(Vector3(0.04, -0.42, 0.17), Vector2(0.025, 0.025), 8)])
		"fold":
			a.color = PaperMesh.WASHI
			a.rect(Vector2(0.0, -0.46), Vector2(0.16, 0.12), 0.2)
	_arm.add_child(a.build())


func _process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Node3D
		if _ronin == null:
			return
	var t := Time.get_ticks_msec() * 0.001
	var dx := _ronin.global_position.x - global_position.x
	var near := absf(dx) < notice_distance and absf(_ronin.global_position.y - global_position.y) < 3.0
	# Breathing.
	_torso.scale.y = 1.0 + 0.012 * sin(t * 1.7 + _phase)
	# Looking: down at its work, or up and round at him while he is near.
	var want := clampf(dx * 0.22, -0.75, 0.75) if near else 0.22 * sin(t * 0.31 + _phase)
	_look = lerpf(_look, want, 0.06)
	_head.rotation.y = _look
	_head.rotation.x = lerpf(_head.rotation.x, -0.05 if near else 0.22, 0.05)
	# A bow as he passes in front (once each time he comes by).
	if near and absf(dx) < bow_distance and not _bowed:
		_bowed = true
		_bow_time = t
	elif not near:
		_bowed = false
	var since := t - _bow_time
	var bow := 0.0
	if since < 1.6:
		bow = smoothstep(0.0, 0.35, since) * (1.0 - smoothstep(0.9, 1.6, since))
	_torso.rotation.x = bow_depth * bow + 0.03 * sin(t * 0.9 + _phase)
	# Its work.
	match work:
		"fan":
			_arm.rotation.z = 0.55 + 0.4 * sin(t * 7.0 + _phase) * (1.0 - bow)
			_arm.rotation.x = -0.5
		"pour":
			_arm.rotation.x = -0.55 - 0.25 * maxf(0.0, sin(t * 0.9 + _phase))
			_arm.rotation.z = 0.25
		"fold":
			_arm.rotation.x = -0.75 - 0.12 * sin(t * 2.4 + _phase)
			_arm.rotation.z = 0.35 + 0.1 * sin(t * 1.2 + _phase)
		_:
			_arm.rotation.x = -0.35 - 0.06 * sin(t * 0.8 + _phase)
			_arm.rotation.z = 0.2
