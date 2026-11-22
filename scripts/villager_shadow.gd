class_name VillagerShadow
extends Node3D
## Someone at home behind a lit shoji: their shadow on the paper, soft and
## warm-dark, cut off at the window's edges (shaders/window_shadow). Each
## does something of their own: paces the room, kneels at some small work
## (head nodding), or (the Paper-Maker) rocks her mould in the vat. When the
## Ronin comes near, they shrink down out of sight below the sill (people
## keep away from strangers in the Rain); once he has gone they rise again,
## slowly, peering first. A window can instead have a wooden storm shutter
## (amado) that slides across as he comes, and back once he has gone.
## Origin: the middle of the window, just in front of its paper.

## "pace", "kneel", "papermaker"
@export var activity := "pace"
@export var window_size := Vector2(1.6, 1.2)
@export var round_window := false
## Slide a shutter across instead of hiding.
@export var shutter := false
## Which side of the window the shutter's box is (1 = right, -1 = left).
@export var side := 1.0
## How near he comes (metres along the street) before they hide.
@export var shy_distance := 3.5

var _figure: Node3D
var _arms: Node3D
var _head: Node3D
var _look: ShaderMaterial
var _clock := 0.0
var _hide := 0.0      # 0 = at ease, 1 = ducked out of sight
var _ronin: Node3D
var _shutter: Node3D
var _closed := 0.0
var _seed := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 97.0)
	_seed = rng.randf() * 10.0
	if shutter:
		_build_shutter(rng)
		return
	_look = ShaderMaterial.new()
	_look.shader = preload("res://shaders/window_shadow.gdshader")
	var extent := window_size if not round_window else Vector2.ONE * window_size.y * 1.12
	_look.set_shader_parameter(&"window_rect", Vector4(global_position.x - extent.x * 0.5, global_position.y - extent.y * 0.5, extent.x, extent.y))
	_look.set_shader_parameter(&"round_window", 1.0 if round_window else 0.0)
	_figure = Node3D.new()
	add_child(_figure)
	var s := window_size.y  # the shadow is about this tall in the window
	var body := PaperMesh.new(rng.randi())
	body.texture_scale = 0.0
	body.shade_jitter = 0.0
	match activity:
		"kneel":
			# Kneeling, back bent over some work in the lap.
			body.polygon(PackedVector2Array([Vector2(-0.35, -0.75), Vector2(0.32, -0.75), Vector2(0.26, -0.1), Vector2(0.1, 0.12),
					Vector2(-0.16, 0.14), Vector2(-0.3, -0.2)]))
		"papermaker":
			# Standing at the vat, bent forward from the hips.
			body.polygon(PackedVector2Array([Vector2(-0.22, -0.9), Vector2(0.05, -0.9), Vector2(0.08, -0.35), Vector2(0.3, 0.05),
					Vector2(0.18, 0.2), Vector2(-0.12, 0.05), Vector2(-0.2, -0.35)]))
			# The vat's rim, a long low shape in front of her.
			body.polygon(PackedVector2Array([Vector2(0.25, -0.9), Vector2(1.4, -0.9), Vector2(1.4, -0.45), Vector2(0.25, -0.45)]))
		_:
			body.polygon(PackedVector2Array([Vector2(-0.2, -0.9), Vector2(0.2, -0.9), Vector2(0.22, -0.2), Vector2(0.16, 0.12),
					Vector2(-0.16, 0.12), Vector2(-0.22, -0.2)]))
	var torso := body.build()
	torso.material_override = _look
	_figure.add_child(torso)
	_head = Node3D.new()
	_head.position = Vector3(0.12 if activity == "papermaker" else 0.0, 0.28 if activity != "papermaker" else 0.3, 0.0)
	_figure.add_child(_head)
	var h := PaperMesh.new(rng.randi())
	h.texture_scale = 0.0
	h.ellipse(Vector2.ZERO, Vector2(0.11, 0.13), 12)
	h.ellipse(Vector2(-0.07, 0.1), Vector2(0.06, 0.05), 8)  # the hair, tied up
	var head_mesh := h.build()
	head_mesh.material_override = _look
	_head.add_child(head_mesh)
	if activity == "papermaker":
		# Her arms and the mould (sugeta) she rocks in the vat.
		_arms = Node3D.new()
		_arms.position = Vector3(0.18, 0.05, 0.0)
		_figure.add_child(_arms)
		var a := PaperMesh.new(rng.randi())
		a.texture_scale = 0.0
		a.stroke(Vector2.ZERO, Vector2(0.4, -0.35), 0.06, 0.05)
		a.rect(Vector2(0.65, -0.38), Vector2(0.7, 0.05))
		var arms_mesh := a.build()
		arms_mesh.material_override = _look
		_arms.add_child(arms_mesh)
	_figure.scale = Vector3.ONE * s
	_figure.position = Vector3(rng.randf_range(-0.2, 0.2) * window_size.x, -s * 0.05, 0.0)


func _process(delta: float) -> void:
	_clock += delta
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Node3D
		if _ronin == null:
			return
	var near := absf(_ronin.global_position.x - global_position.x) < shy_distance and _ronin.global_position.y > -1.0 \
			and _ronin.global_position.y < global_position.y + 2.0
	if shutter:
		var before := _closed
		_closed = move_toward(_closed, 1.0 if near else 0.0, delta / (0.5 if near else 1.6))
		if before == 0.0 and _closed > 0.0 or before == 1.0 and _closed < 1.0:
			Sound.play(self, &"plank_creak", -14.0)
		_shutter.position.x = lerpf(window_size.x * 1.02 * side, 0.0, smoothstep(0.0, 1.0, _closed))
		return
	# Hide quickly, come back slowly (and only once he is well away).
	var far := absf(_ronin.global_position.x - global_position.x) > shy_distance + 2.0
	if near:
		_hide = move_toward(_hide, 1.0, delta / 0.45)
	elif far:
		_hide = move_toward(_hide, 0.0, delta / 2.4)
	var s := window_size.y
	var t := _clock + _seed
	var x := _figure.position.x
	var y := -s * 0.05
	match activity:
		"pace":
			x = sin(t * 0.32) * window_size.x * 0.45
			y += absf(sin(t * 2.4)) * 0.015
			_figure.scale.x = s * (1.0 if cos(t * 0.32) > 0.0 else -1.0)
			_head.rotation.z = sin(t * 0.7) * 0.08
		"kneel":
			_head.rotation.z = -0.25 + sin(t * 1.6) * 0.12
			y -= s * 0.15
		"papermaker":
			# The rocking stroke of paper-making: forward, back, forward, a
			# pause, the mould lifted and tilted.
			var rock := sin(t * 2.2) * 0.09 + sin(t * 4.4) * 0.03
			_arms.position.x = 0.18 + rock
			_arms.rotation.z = sin(t * 2.2 + 0.6) * 0.05
			_head.rotation.z = rock * 0.6
	_figure.position = Vector3(x, y - _hide * s * 1.3, 0.0)
	# (Nothing pops: as they sink below the sill they also fade.)
	_look.set_shader_parameter(&"fade", 1.0 - _hide * 0.6)


## A wooden storm shutter (amado) in its box beside the window, that slides
## across the window as he comes near.
func _build_shutter(rng: RandomNumberGenerator) -> void:
	var box := PaperMesh.new(rng.randi())
	box.color = Scenery.WOOD.darkened(0.35)
	box.box(Vector3(window_size.x * 1.05 * side, 0.0, 0.08), Vector3(window_size.x * 0.98, window_size.y + 0.25, 0.07))
	add_child(box.build())
	_shutter = Node3D.new()
	_shutter.position.x = window_size.x * 1.02 * side
	add_child(_shutter)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.16
	var x := -window_size.x * 0.5
	while x < window_size.x * 0.5:
		var x1 := minf(x + rng.randf_range(0.16, 0.24), window_size.x * 0.5)
		b.color = Scenery.WOOD.darkened(rng.randf_range(0.15, 0.4))
		b.box(Vector3((x + x1) * 0.5, 0.0, 0.14), Vector3(x1 - x - 0.015, window_size.y + 0.12, 0.04))
		x = x1
	b.color = PaperMesh.TIMBER
	for band: float in [-0.35, 0.35]:
		b.box(Vector3(0.0, band * window_size.y, 0.17), Vector3(window_size.x, 0.05, 0.02))
	_shutter.add_child(b.build())
