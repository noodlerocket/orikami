class_name PerchedBirds
extends Node3D
## A few small paper birds (sparrows folded from brown-grey paper) perched
## on a line, a fence, a railing or a ridge: they shuffle, peck, ruffle
## their wings. When the Ronin comes near they burst up all together and fly
## off into the dark (shrinking with the distance, never vanishing on the
## spot). Long after he has gone they come back, flying in and landing.
## Origin: the perch, at its middle.

## How many birds.
@export var count := 4
## How far along the perch they sit (metres).
@export var spread := 1.2
## How near (metres along the street) he may come before they fly.
@export var shy_distance := 4.5

var _birds: Array[Dictionary] = []   # {node, wings, home, away, phase}
var _ronin: Node3D
var _flown := 0.0      # 0 = perched; 1 = gone
var _flying := false
var _gone_clock := 0.0
var _clock := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 59.0 + global_position.y * 7.0)
	for k in count:
		var bird := Node3D.new()
		var home := Vector3(lerpf(-spread * 0.5, spread * 0.5, (k + rng.randf_range(0.2, 0.8)) / count), 0.0, rng.randf_range(-0.05, 0.05))
		bird.position = home
		bird.rotation.y = 0.0 if rng.randf() < 0.5 else PI
		add_child(bird)
		var b := PaperMesh.new(rng.randi())
		b.texture_world = false
		b.shade_jitter = 0.18
		b.color = Color(0.34, 0.3, 0.28).lerp(Color(0.5, 0.46, 0.4), rng.randf())
		# A plump folded body, a head, a short tail, a tiny beak.
		b.tri(Vector3(-0.09, 0.03, 0.0), Vector3(0.07, 0.04, 0.0), Vector3(0.0, 0.1, 0.045))
		b.tri(Vector3(-0.09, 0.03, 0.0), Vector3(0.07, 0.04, 0.0), Vector3(0.0, 0.1, -0.045))
		b.tri(Vector3(-0.09, 0.03, 0.0), Vector3(0.07, 0.04, 0.0), Vector3(0.0, 0.005, 0.0))
		b.color = b.color.darkened(0.25)
		b.tri(Vector3(0.05, 0.08, -0.025), Vector3(0.11, 0.13, 0.0), Vector3(0.05, 0.08, 0.025))
		b.tri(Vector3(0.05, 0.08, -0.025), Vector3(0.11, 0.13, 0.0), Vector3(0.09, 0.07, 0.0))
		b.tri(Vector3(-0.08, 0.05, -0.02), Vector3(-0.17, 0.08, 0.0), Vector3(-0.08, 0.05, 0.02))
		b.color = Color(0.2, 0.18, 0.12)
		b.tri(Vector3(0.11, 0.12, -0.008), Vector3(0.15, 0.115, 0.0), Vector3(0.11, 0.11, 0.008))
		bird.add_child(b.build())
		var wings := Node3D.new()
		wings.position = Vector3(0.0, 0.09, 0.0)
		bird.add_child(wings)
		var w := PaperMesh.new(rng.randi())
		w.texture_world = false
		w.color = Color(0.28, 0.25, 0.24)
		for side: float in [-1.0, 1.0]:
			w.tri(Vector3(0.04, 0.0, 0.0), Vector3(-0.06, 0.0, 0.0), Vector3(-0.03, 0.01, side * 0.16))
		wings.add_child(w.build())
		wings.scale = Vector3(1.0, 1.0, 0.2)  # folded at rest
		var away := Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(6.0, 10.0), rng.randf_range(-16.0, -9.0))
		_birds.append({"node": bird, "wings": wings, "home": home, "away": away, "phase": rng.randf() * TAU})


func _process(delta: float) -> void:
	_clock += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Node3D
		if _ronin == null:
			return
	var dx := absf(_ronin.global_position.x - global_position.x)
	var near := dx < shy_distance and absf(_ronin.global_position.y - global_position.y) < 5.0
	if near and not _flying and _flown < 0.5:
		_flying = true
		Sound.play(self, &"birds_scatter", -4.0)
	if _flying:
		_flown = minf(_flown + delta / 2.6, 1.0)
		if _flown >= 1.0:
			_gone_clock += delta
			# Back, once he has been well away for a while: they fly in.
			if dx > 22.0 and _gone_clock > 6.0:
				_flying = false
				_gone_clock = 0.0
	else:
		_flown = maxf(_flown - delta / 3.0, 0.0)
	for k in _birds.size():
		var bird: Dictionary = _birds[k]
		var node: Node3D = bird["node"]
		var wings: Node3D = bird["wings"]
		var phase: float = bird["phase"]
		# Each leaves a moment after the last; they fly up and away.
		var u := clampf(_flown * 1.25 - k * 0.06, 0.0, 1.0)
		var e := u * u * (3.0 - 2.0 * u)
		var home: Vector3 = bird["home"]
		var away: Vector3 = bird["away"]
		node.position = home.lerp(away, e) + Vector3(0.0, sin(e * PI) * 1.2, 0.0)
		node.visible = u < 0.999
		if u > 0.0:
			wings.scale.z = 1.0
			wings.rotation.x = sin(_clock * 38.0 + phase) * 0.9
			node.rotation.z = 0.25
			node.rotation.y = 0.0 if away.x > 0.0 else PI
		else:
			# Perched: a hop now and then, a peck, a ruffle of the wings.
			wings.scale.z = 0.2 + maxf(0.0, sin(_clock * 0.7 + phase * 3.0) - 0.92) * 8.0
			wings.rotation.x = 0.0
			var peck := maxf(0.0, sin(_clock * 1.3 + phase) - 0.85) * 3.0
			node.rotation.z = -peck * 0.5
			node.position.y = maxf(0.0, sin(_clock * 2.1 + phase * 2.0) - 0.97) * 1.5
