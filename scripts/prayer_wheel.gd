class_name PrayerWheel
extends Node3D
## A great prayer wheel of the Thousand Gates: an upright drum of lacquered
## paper painted round with bands of brushed sutra, red caps top and bottom,
## turning on an iron spindle in a timber frame on a stone base. The breeze
## barely stirs it; the Fan Gust ("gust_target") sets it spinning, and
## while it turns fast (`turning`) whatever it drives goes up (GustLift).
## It slows over some seconds, the small bell on its frame ringing as it
## turns. Origin: the foot of its base.

@export var height := 1.8
@export var radius := 0.55
## How fast a gust sets it turning (radians a second), how long it takes to
## slow, and the speed above which it drives its lift.
@export var gust_spin := 10.0
@export var spin_down := 8.0
@export var turning_at := 3.0

const LACQUER := Color(0.42, 0.14, 0.11)
const PAPER := Color(0.86, 0.8, 0.66)
const INK := Color(0.12, 0.1, 0.1)

var spin := 0.0
var _drum: Node3D
var _ring := 0.0


func _ready() -> void:
	add_to_group(&"gust_target")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 17.0)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.1
	# The stone base and the timber frame round the drum.
	MarshKit.masonry(b, Vector3(0.0, 0.25, 0.0), Vector3(1.6, 0.5, 1.4), rng, Color(0.5, 0.5, 0.5), false)
	b.color = Color(0.3, 0.22, 0.17)
	for x: float in [-0.75, 0.75]:
		b.box(Vector3(x, 0.5 + (height + 0.7) * 0.5, -0.45), Vector3(0.14, height + 0.7, 0.14))
	b.box(Vector3(0.0, 0.5 + height + 0.62, -0.45), Vector3(1.75, 0.14, 0.18))
	# A small roof over it.
	add_child(b.build())
	add_child(Scenery.tiled_roof(rng, -1.0, 1.0, Vector2(0.5 + height + 0.75, 0.5), Vector2(0.5 + height + 1.2, -0.45), 2))
	add_child(Scenery.tiled_roof(rng, -1.0, 1.0, Vector2(0.5 + height + 0.75, -1.4), Vector2(0.5 + height + 1.2, -0.45), 2))
	# The spindle, then the drum turning on it.
	var spindle := PaperMesh.new(rng.randi())
	spindle.texture_world = false
	spindle.color = Color(0.16, 0.16, 0.18)
	spindle.frustum(6, Vector2(0.04, 0.04), Vector2(0.04, 0.04), height + 0.6, Vector3(0.0, 0.5, 0.0))
	add_child(spindle.build())
	_drum = Node3D.new()
	_drum.position = Vector3(0.0, 0.62, 0.0)
	add_child(_drum)
	var d := PaperMesh.new(rng.randi())
	d.texture_world = false
	d.shade_jitter = 0.06
	d.color = PAPER
	d.frustum(16, Vector2(radius, radius), Vector2(radius, radius), height - 0.24, Vector3(0.0, 0.12, 0.0))
	d.color = LACQUER
	d.frustum(16, Vector2(radius + 0.05, radius + 0.05), Vector2(radius + 0.05, radius + 0.05), 0.12, Vector3.ZERO)
	d.frustum(16, Vector2(radius + 0.05, radius + 0.05), Vector2(radius * 0.4, radius * 0.4), 0.18, Vector3(0.0, height - 0.12, 0.0))
	# Bands of sutra brushed round it: rows of small strokes (as the drum
	# turns they stream past), and a red band between.
	# Columns of small brushed characters: each a cluster of three to five
	# fine strokes, some across, some down, some slanting.
	d.color = INK
	for row in 2:
		var y0 := 0.22 + row * (height - 0.24) * 0.5
		for k in 22:
			var a := TAU * k / 22.0 + row * 0.15
			var normal := Vector3(cos(a), 0.0, sin(a))
			var along := Vector3(-sin(a), 0.0, cos(a))
			var y := y0
			while y < y0 + (height - 0.24) * 0.5 - 0.2:
				var c := normal * (radius + 0.004) + Vector3(0.0, y, 0.0)
				for st in rng.randi_range(3, 5):
					var kind := rng.randi_range(0, 2)
					var mid := c + along * rng.randf_range(-0.03, 0.03) + Vector3(0.0, rng.randf_range(0.0, 0.07), 0.0)
					var dir := along if kind == 0 else (Vector3.UP if kind == 1 else (along + Vector3.UP * (1.0 if rng.randf() < 0.5 else -1.0)).normalized())
					var half := dir * rng.randf_range(0.015, 0.032)
					var thick := dir.cross(normal).normalized() * 0.006
					d.quad(mid - half - thick, mid + half - thick, mid + half + thick, mid - half + thick, normal)
				y += 0.12
	d.color = LACQUER.lightened(0.1)
	d.frustum(16, Vector2(radius + 0.01, radius + 0.01), Vector2(radius + 0.01, radius + 0.01), 0.06, Vector3(0.0, (height - 0.24) * 0.5 + 0.09, 0.0))
	_drum.add_child(d.build())
	# A little bell on an arm of the frame, struck by a peg on the drum.
	var bell := Scenery.lantern(rng, 0.2, 0.12, 0.0)
	bell.position = Vector3(0.6, 0.5 + height + 0.35, 0.1)
	add_child(bell)


func turning() -> bool:
	return spin >= turning_at


func gusted(direction: Vector3, _from: Vector3) -> void:
	spin = minf(spin + gust_spin, gust_spin * 1.4) * (1.0 if direction.x != 0.0 else 1.0)
	Sound.play(self, &"windmill_creak", -6.0)


func _process(delta: float) -> void:
	var breeze := 0.25
	spin = move_toward(spin, breeze, delta * gust_spin / spin_down)
	_drum.rotation.y += spin * delta
	_ring += spin * delta
	if _ring > TAU and spin > turning_at:
		_ring = 0.0
		Sound.play(self, &"draw_ready", -18.0)
