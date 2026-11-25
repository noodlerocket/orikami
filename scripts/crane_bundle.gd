class_name CraneBundle
extends Node3D
## A bundle of paper cranes, hidden somewhere in the village: the first of
## the thousand (senbazuru) for the true ending. Properly folded cranes
## (pointed body, raised wings, long neck and tail, the head bent down)
## nestle together on a square of washi, tied round with a thin faded-red
## thread and a little knot. Their paper stirs in the wind, and a faint pale
## glow and a mote or two rising give them away in the dark.
##
## Walk into them and they wake: the thread snaps and its ends fall away,
## then one by one the cranes open their wings, lift off with real
## wingbeats, circle round him once and fold themselves into his robe, a
## small burst of paper at his chest as each arrives, the count on the HUD
## ticking up with each one. The empty washi stays where they lay. (The
## first version, a red puck, a hard white ring and specks shooting off
## through the ceiling, was "carelessly made": Julian.)
## The count is kept (SaveGame) and shown (Hud). Origin: where it rests.

signal collected(count: int)

## Its name in the save.
@export var id := "cranes"
## How many cranes are in it (the heap shows up to six).
@export var count := 5
## How close (metres) he must come.
@export var reach := Vector2(0.9, 1.5)
## Only taken by him floating (the Wax Coat): cranes out on deep water.
@export var swim_only := false
## How big the cranes are (1 = a hand's width).
@export var size := 1.8

@export_group("Flight")
## Seconds between one crane waking and the next.
@export var wake_gap := 0.22
## Seconds a crane takes to lift off its heap.
@export var lift_time := 0.45
## Seconds it circles him before folding into his robe.
@export var circle_time := 1.5
## Radius of the circle round him (metres).
@export var circle_radius := 0.95
## Wingbeats per second in flight.
@export var flap_rate := 7.0

var taken := false

var _ronin: Ronin
var _cranes: Array[Dictionary] = []   # {node, wings: [left, right], home, from, start, done}
var _thread: Node3D
var _glow: MeshInstance3D
var _motes: CPUParticles3D
var _clock := 0.0
var _found_at := -1.0
var _total_before := 0
var _arrived := 0


func _ready() -> void:
	scale = Vector3.ONE * size
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	_build_wrapper(rng)
	# The cranes, nestled together, heads every way.
	var shown := mini(count, 6)
	for k in shown:
		var crane := Node3D.new()
		var angle := TAU * k / shown + rng.randf_range(-0.25, 0.25)
		var ring := 0.07 if k < shown - 1 else 0.0
		crane.position = Vector3(cos(angle) * ring, 0.035 + (0.05 if k == shown - 1 else 0.0), sin(angle) * ring * 0.8)
		crane.rotation.y = angle + PI * 0.5 + rng.randf_range(-0.5, 0.5)
		add_child(crane)
		var wings := _build_crane(crane, rng)
		_cranes.append({"node": crane, "wings": wings, "home": crane.position, "phase": rng.randf() * TAU,
				"start": 0.0, "from": Vector3.ZERO, "done": false})
	_build_thread(rng)
	# A faint glow, and a mote now and then, so it can be spotted.
	_glow = Scenery.halo(0.42, Color(0.85, 0.88, 1.0, 0.13))
	_glow.position = Vector3(0.0, 0.1, 0.15)
	add_child(_glow)
	_motes = CPUParticles3D.new()
	_motes.amount = 4
	_motes.lifetime = 2.4
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_motes.emission_sphere_radius = 0.12
	_motes.direction = Vector3.UP
	_motes.spread = 15.0
	_motes.gravity = Vector3(0.0, 0.05, 0.0)
	_motes.initial_velocity_min = 0.08
	_motes.initial_velocity_max = 0.16
	var mote := QuadMesh.new()
	mote.size = Vector2(0.018, 0.018)
	mote.material = PaperMesh.soft_ink(Color(0.9, 0.93, 1.0, 0.7))
	_motes.mesh = mote
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	_motes.color_ramp = fade
	_motes.position = Vector3(0.0, 0.1, 0.0)
	add_child(_motes)


## The square of washi they rest on, folded once corner to corner (a crease
## and two faces at slightly different shades), its corners lifting a little.
func _build_wrapper(rng: RandomNumberGenerator) -> void:
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.04
	var h := 0.2
	var y := 0.004
	b.color = PaperMesh.WASHI.darkened(0.12)
	b.tri(Vector3(-h, y, -h), Vector3(h, y, h), Vector3(h, y + 0.012, -h), Vector3.UP)
	b.color = PaperMesh.WASHI.darkened(0.2)
	b.tri(Vector3(-h, y, -h), Vector3(-h, y + 0.018, h), Vector3(h, y, h), Vector3.UP)
	# The crease.
	b.color = PaperMesh.WASHI.darkened(0.32)
	b.tri(Vector3(-h, y + 0.002, -h + 0.006), Vector3(h - 0.006, y + 0.002, h), Vector3(h, y + 0.002, h - 0.006), Vector3.UP)
	var mesh := b.build()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


## One folded crane (facing +x), its two wings on hinges along its back so
## they can beat. Returns the two wing nodes.
func _build_crane(parent: Node3D, rng: RandomNumberGenerator) -> Array:
	var paper := PaperMesh.WASHI.darkened(rng.randf_range(0.0, 0.1))
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.1
	# The body: a folded diamond, ridge on top, keel below.
	var nose := Vector3(0.05, 0.03, 0.0)
	var rump := Vector3(-0.05, 0.03, 0.0)
	var ridge := Vector3(0.0, 0.045, 0.0)
	var keel := Vector3(0.0, 0.0, 0.0)
	for side: float in [-1.0, 1.0]:
		var flank := Vector3(0.0, 0.025, 0.022 * side)
		b.color = paper.darkened(0.06 if side > 0.0 else 0.14)
		b.tri(nose, ridge, flank)
		b.tri(rump, flank, ridge)
		b.color = paper.darkened(0.22)
		b.tri(nose, flank, keel)
		b.tri(rump, keel, flank)
	# The neck rising forward, the head bent down at its tip; the tail
	# rising back to a point.
	b.color = paper.darkened(0.04)
	var neck_top := Vector3(0.11, 0.11, 0.0)
	b.tri(nose + Vector3(-0.012, -0.005, -0.006), neck_top, nose + Vector3(-0.012, -0.005, 0.006))
	b.tri(nose + Vector3(-0.012, -0.005, 0.006), neck_top, nose + Vector3(0.008, 0.0, 0.0))
	b.tri(nose + Vector3(-0.012, -0.005, -0.006), nose + Vector3(0.008, 0.0, 0.0), neck_top)
	b.color = paper.darkened(0.18)
	b.tri(neck_top, neck_top + Vector3(0.028, -0.022, -0.004), neck_top + Vector3(0.004, -0.012, 0.004))
	b.tri(neck_top, neck_top + Vector3(0.004, -0.012, -0.004), neck_top + Vector3(0.028, -0.022, 0.004))
	b.color = paper.darkened(0.04)
	var tail_top := Vector3(-0.115, 0.1, 0.0)
	b.tri(rump + Vector3(0.012, -0.005, 0.006), tail_top, rump + Vector3(0.012, -0.005, -0.006))
	b.tri(rump + Vector3(0.012, -0.005, -0.006), tail_top, rump + Vector3(-0.008, 0.0, 0.0))
	b.tri(rump + Vector3(-0.008, 0.0, 0.0), tail_top, rump + Vector3(0.012, -0.005, 0.006))
	var body := b.build()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(body)
	var wings := []
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = ridge
		parent.add_child(hinge)
		var w := PaperMesh.new(rng.randi())
		w.texture_world = false
		w.shade_jitter = 0.08
		w.color = paper.darkened(0.02 if side > 0.0 else 0.1)
		# A long wing, broad at the root, a fold line along it.
		var tip := Vector3(-0.025, 0.0, 0.13 * side)
		w.tri(Vector3(0.035, 0.0, 0.0), Vector3(-0.04, 0.0, 0.0), Vector3(0.0, 0.004, 0.065 * side), Vector3.UP)
		w.color = paper.darkened(0.08 if side > 0.0 else 0.16)
		w.tri(Vector3(0.0, 0.004, 0.065 * side), Vector3(-0.04, 0.0, 0.0), tip, Vector3.UP)
		w.tri(Vector3(0.035, 0.0, 0.0), Vector3(0.0, 0.004, 0.065 * side), tip, Vector3.UP)
		var wing := w.build()
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hinge.add_child(wing)
		# At rest the wings are raised high, as a folded crane's are.
		hinge.rotation.x = -side * 1.05
		wings.append(hinge)
	return wings


## A thin faded-red thread looped round the heap, and a little knot with
## two short ends.
func _build_thread(rng: RandomNumberGenerator) -> void:
	_thread = Node3D.new()
	add_child(_thread)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.05
	b.color = PaperMesh.VERMILION.darkened(0.35)
	var steps := 18
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		var p0 := Vector3(cos(a0) * 0.15, 0.052 + 0.006 * sin(a0 * 3.0), sin(a0) * 0.12)
		var p1 := Vector3(cos(a1) * 0.15, 0.052 + 0.006 * sin(a1 * 3.0), sin(a1) * 0.12)
		b.quad(p0 + Vector3(0, -0.005, 0), p1 + Vector3(0, -0.005, 0), p1 + Vector3(0, 0.005, 0), p0 + Vector3(0, 0.005, 0))
	var knot := Vector3(0.0, 0.055, 0.125)
	b.box(knot, Vector3(0.018, 0.016, 0.014))
	b.tri(knot, knot + Vector3(0.03, -0.045, 0.012), knot + Vector3(0.018, -0.05, 0.012))
	b.tri(knot, knot + Vector3(-0.022, -0.05, 0.014), knot + Vector3(-0.034, -0.044, 0.014))
	var mesh := b.build()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_thread.add_child(mesh)


func _physics_process(_delta: float) -> void:
	if taken:
		return
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var d := _ronin.global_position + Vector3(0.0, 0.7, 0.0) - global_position
	if absf(d.x) < reach.x and absf(d.y) < reach.y and (_ronin.swimming or not swim_only):
		collect()


## Found: the thread snaps, and the cranes wake and come to him.
func collect(quietly: bool = false) -> void:
	if taken:
		return
	taken = true
	if quietly:
		# (A saved game: they were found before. Only the empty washi.)
		for c: Dictionary in _cranes:
			(c["node"] as Node3D).visible = false
		_thread.visible = false
		_glow.visible = false
		_motes.emitting = false
		return
	_total_before = SaveGame.crane_total()
	SaveGame.found_crane(id, count)
	collected.emit(count)
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	Sound.play(self, &"cranes_rise")
	_found_at = _clock
	_motes.emitting = false
	# The thread snaps: it gives a little, the loop springs open and its
	# pieces drop to the washi and fade.
	var snap := create_tween()
	snap.tween_property(_thread, "scale", Vector3(1.12, 1.0, 1.12), 0.08).set_ease(Tween.EASE_OUT)
	snap.tween_property(_thread, "position", Vector3(0.0, -0.04, 0.03), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	snap.parallel().tween_property(_thread, "rotation:z", 0.35, 0.35)
	snap.tween_property(_thread, "scale", Vector3(1.12, 0.05, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
	snap.tween_callback(func() -> void: _thread.visible = false)
	var dim := create_tween()
	dim.tween_property(_glow, "scale", Vector3.ONE * 0.4, 1.2).set_trans(Tween.TRANS_SINE)
	dim.tween_callback(func() -> void: _glow.visible = false)
	for k in _cranes.size():
		_cranes[k]["start"] = 0.25 + wake_gap * k


func _process(delta: float) -> void:
	_clock += delta
	if not taken:
		# The paper stirs in the wind; a wing lifts now and then.
		var blow := Wind.speed_at(global_position.x)
		for c: Dictionary in _cranes:
			var node: Node3D = c["node"]
			var phase: float = c["phase"]
			node.rotation.z = sin(_clock * 3.1 + phase) * 0.04 * blow
			var stir := maxf(0.0, sin(_clock * 0.9 + phase * 2.0) - 0.9) * 2.5
			for i in 2:
				var side := -1.0 if i == 0 else 1.0
				(c["wings"][i] as Node3D).rotation.x = -side * (1.05 - stir * 0.4)
		return
	if _found_at < 0.0:
		return
	var since := _clock - _found_at
	var all_done := true
	for c: Dictionary in _cranes:
		if not c["done"]:
			all_done = false
			_fly(c, since - float(c["start"]))
	if all_done:
		_found_at = -1.0


## One crane's flight, t seconds after it woke: wings open, it lifts off the
## heap, circles round him at chest height, then folds itself flat and slips
## into his robe.
func _fly(c: Dictionary, t: float) -> void:
	var node: Node3D = c["node"]
	var wings: Array = c["wings"]
	var phase: float = c["phase"]
	if t < 0.0:
		return
	if not node.top_level:
		c["from"] = node.global_position
		node.top_level = true
		node.global_position = c["from"]
		node.scale = Vector3.ONE * size
	var chest := (_ronin.global_position if _ronin else global_position) + Vector3(0.0, 1.05, 0.0)
	var circle_start := lift_time
	var fold_start := lift_time + circle_time
	var beat := sin(t * flap_rate * TAU + phase)
	var spread := 1.0
	var at: Vector3
	var heading := Vector3.RIGHT
	var angle0 := phase
	var from: Vector3 = c["from"]
	var lift_end := from + Vector3(0.0, 0.55, 0.35)
	if t < circle_start:
		# Lifting off: wings open from raised to beating; a hop up and out.
		var u := t / lift_time
		var e := u * u * (3.0 - 2.0 * u)
		at = from.lerp(lift_end, e) + Vector3(0.0, sin(u * PI) * 0.1, 0.0)
		spread = e
		heading = (lift_end - from).normalized()
	else:
		# Circling him (in front and behind), drawing in and rising a little.
		var s := t - circle_start
		var p := clampf(s / circle_time, 0.0, 1.0)
		var angle := angle0 + s * 3.4
		var radius := lerpf(circle_radius, circle_radius * 0.45, p * p)
		var orbit := chest + Vector3(cos(angle) * radius, 0.25 * sin(s * 4.0 + phase) + 0.35 * (1.0 - p), sin(angle) * radius * 0.7)
		var blend := clampf(s / 0.35, 0.0, 1.0)
		at = lift_end.lerp(orbit, blend * blend * (3.0 - 2.0 * blend))
		heading = Vector3(-sin(angle), 0.0, cos(angle) * 0.7)
		if t >= fold_start:
			# Folding away: wings close flat, it dives into his chest and is
			# gone into the robe.
			var f := clampf((t - fold_start) / 0.3, 0.0, 1.0)
			at = at.lerp(chest + Vector3(0.0, -0.05, 0.12), f * f)
			spread = 1.0 - f
			node.scale = Vector3.ONE * size * lerpf(1.0, 0.25, f * f)
			if f >= 1.0:
				_arrive(c)
				return
	node.global_position = at
	if heading.length() > 0.01:
		node.rotation = Vector3(0.0, atan2(-heading.z, heading.x), 0.12 * beat)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var raised := -side * 1.05
		var flying := -side * (0.15 + 0.75 * beat)
		var closed := -side * 1.45
		var r: float = lerpf(raised, flying, spread) if t < circle_start or spread >= 1.0 else lerpf(closed, flying, spread)
		(wings[i] as Node3D).rotation.x = r


## A crane has folded into his robe: a small burst of paper at his chest,
## and the count on the HUD goes up by one.
func _arrive(c: Dictionary) -> void:
	c["done"] = true
	var node: Node3D = c["node"]
	node.visible = false
	_arrived += 1
	var at := node.global_position
	var burst := CPUParticles3D.new()
	burst.top_level = true
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.amount = 8
	burst.lifetime = 0.6
	burst.direction = Vector3.UP
	burst.spread = 180.0
	burst.gravity = Vector3(0.0, -1.2, 0.0)
	burst.initial_velocity_min = 0.4
	burst.initial_velocity_max = 0.9
	burst.angle_max = 360.0
	var scrap := QuadMesh.new()
	scrap.size = Vector2(0.03, 0.02)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.92, 0.91, 0.86)
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scrap.material = look
	burst.mesh = scrap
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	burst.color_ramp = fade
	add_child(burst)
	burst.global_position = at
	burst.emitting = true
	get_tree().create_timer(1.0).timeout.connect(burst.queue_free)
	Sound.play(self, &"paper_fold", -14.0)
	var shown := _cranes.size()
	# (A bundle shows at most six cranes; the count still rises by all of them.)
	var total := _total_before + int(round(float(count) * _arrived / shown))
	get_tree().call_group(&"hud", &"cranes_found", total)
