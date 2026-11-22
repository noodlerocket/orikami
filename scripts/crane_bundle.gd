class_name CraneBundle
extends Node3D
## A bundle of paper cranes, tied with a faded red thread, hidden somewhere
## in the village: the first of the thousand (senbazuru) for the true
## ending. Their paper stirs in the wind. Walk into them and they wake: a
## pale ring of ink is brushed round them and wiped away, and the cranes lift
## off one by one, beating their wings, rising and folding away into the
## night (none pops out). The count is kept (SaveGame) and shown (Hud).
## Origin: where the bundle rests.

signal collected(count: int)

## Its name in the save.
@export var id := "cranes"
## How many cranes are in it.
@export var count := 5
## How close (metres) he must come.
@export var reach := Vector2(0.9, 1.5)

var taken := false

var _ronin: Ronin
var _cranes: Array[Node3D] = []
var _ring: MeshInstance3D
var _ring_mesh: ImmediateMesh
var _ring_look: StandardMaterial3D
var _ring_time := -1.0
var _clock := 0.0


## How big the cranes are (1 = a hand's width).
@export var size := 1.8


func _ready() -> void:
	scale = Vector3.ONE * size
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	# The cranes, nested together in a little heap, the thread round them.
	for k in mini(count, 6):
		var crane := Node3D.new()
		var angle := TAU * k / mini(count, 6)
		crane.position = Vector3(cos(angle) * 0.1, 0.04 + (k % 2) * 0.07, sin(angle) * 0.08)
		crane.rotation.y = angle + rng.randf_range(-0.4, 0.4)
		add_child(crane)
		crane.add_child(_crane_mesh(rng))
		_cranes.append(crane)
	var thread := PaperMesh.new(rng.randi())
	thread.color = PaperMesh.VERMILION.darkened(0.4)
	thread.texture_scale = 0.0
	thread.frustum(10, Vector2(0.19, 0.15), Vector2(0.19, 0.15), 0.018, Vector3(0.0, 0.07, 0.0))
	add_child(thread.build())
	# A faint glow, so it can be spotted in the dark.
	var shine := Scenery.halo(0.55, Color(0.85, 0.88, 1.0, 0.16))
	shine.position = Vector3(0.0, 0.15, 0.2)
	add_child(shine)
	# The ring of ink brushed round them when they are found.
	_ring_mesh = ImmediateMesh.new()
	_ring = MeshInstance3D.new()
	_ring.mesh = _ring_mesh
	_ring_look = StandardMaterial3D.new()
	_ring_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_look.vertex_color_use_as_albedo = true
	_ring_look.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ring_look.disable_fog = true
	_ring.material_override = _ring_look
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0.0, 0.2, 0.35)
	add_child(_ring)


## One small folded crane: a pointed body, two wings, a neck and a tail.
func _crane_mesh(rng: RandomNumberGenerator) -> MeshInstance3D:
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.15
	b.color = PaperMesh.WASHI.darkened(rng.randf_range(0.0, 0.12))
	var body := Vector3(0.0, 0.03, 0.0)
	b.tri(body + Vector3(-0.05, 0.0, 0.0), body + Vector3(0.05, 0.0, 0.0), body + Vector3(0.0, -0.035, 0.0))
	b.tri(body + Vector3(0.0, 0.0, 0.0), body + Vector3(-0.02, 0.01, -0.1), body + Vector3(0.03, 0.005, 0.0), Vector3.UP)
	b.tri(body + Vector3(0.0, 0.0, 0.0), body + Vector3(-0.02, 0.01, 0.1), body + Vector3(0.03, 0.005, 0.0), Vector3.UP)
	b.color = PaperMesh.WASHI.darkened(0.2)
	b.tri(body + Vector3(0.04, 0.0, -0.008), body + Vector3(0.1, 0.07, 0.0), body + Vector3(0.04, 0.0, 0.008))
	b.tri(body + Vector3(-0.04, 0.0, -0.008), body + Vector3(-0.1, 0.06, 0.0), body + Vector3(-0.04, 0.0, 0.008))
	var mesh := b.build()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


func _physics_process(_delta: float) -> void:
	if taken:
		return
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var d := _ronin.global_position + Vector3(0.0, 0.7, 0.0) - global_position
	if absf(d.x) < reach.x and absf(d.y) < reach.y:
		collect()


## Found: the ring is brushed and the cranes fly off.
func collect(quietly: bool = false) -> void:
	if taken:
		return
	taken = true
	if quietly:
		visible = false
		return
	SaveGame.found_crane(id, count)
	collected.emit(count)
	get_tree().call_group(&"hud", &"cranes_found", SaveGame.crane_total())
	Sound.play(self, &"cranes_rise")
	_ring_time = 0.0
	for k in _cranes.size():
		var crane := _cranes[k]
		var drift := Vector3(randf_range(-0.9, 0.9), randf_range(1.8, 2.8), randf_range(-0.3, 0.3))
		var fly := create_tween()
		fly.tween_interval(0.12 * k)
		fly.tween_property(crane, "position", crane.position + drift, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fly.parallel().tween_property(crane, "rotation:y", crane.rotation.y + randf_range(-1.5, 1.5), 1.3)
		fly.tween_property(crane, "scale", Vector3.ONE * 0.001, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var end := create_tween()
	end.tween_interval(2.6)
	end.tween_callback(func() -> void: visible = false)
	for child: Node in get_children():
		if child is MeshInstance3D and child != _ring and not (child.get_parent() in _cranes):
			var piece := child as MeshInstance3D
			var fade := create_tween()
			fade.tween_property(piece, "scale", Vector3.ONE * 0.001, 0.35)


func _process(delta: float) -> void:
	_clock += delta
	if not taken:
		# The paper stirs in the wind.
		var blow := Wind.speed_at(global_position.x)
		for k in _cranes.size():
			_cranes[k].rotation.z = sin(_clock * 3.1 + k * 1.7) * 0.03 * blow
		return
	# Wings beat as they fly.
	for k in _cranes.size():
		_cranes[k].scale.y = _cranes[k].scale.x * (1.0 + 0.6 * sin(_clock * 22.0 + k))
	if _ring_time >= 0.0:
		_ring_time += delta
		_draw_ring()


## The ring of pale ink: brushed round in 0.35 s, held, then wiped away
## from where it began.
func _draw_ring() -> void:
	_ring_mesh.clear_surfaces()
	var on := clampf(_ring_time / 0.35, 0.0, 1.0)
	var off := clampf((_ring_time - 0.6) / 0.45, 0.0, 1.0)
	if off >= 1.0:
		_ring_time = -1.0
		return
	var start := off
	var finish := on
	if finish - start <= 0.01:
		return
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var steps := 40
	for i in steps + 1:
		var t := lerpf(start, finish, float(i) / steps)
		var a := -PI * 0.5 + t * TAU * 0.92
		var r := 0.55 + 0.04 * sin(t * 9.0)
		var w := 0.05 * sin(clampf(t, 0.0, 1.0) * PI) + 0.015
		var c := Color(0.92, 0.94, 1.0, 0.75)
		_ring_mesh.surface_set_color(c)
		_ring_mesh.surface_add_vertex(Vector3(cos(a) * (r - w), sin(a) * (r - w), 0.0))
		_ring_mesh.surface_set_color(c)
		_ring_mesh.surface_add_vertex(Vector3(cos(a) * (r + w), sin(a) * (r + w), 0.0))
	_ring_mesh.surface_end()
