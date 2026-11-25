class_name MarketShortcuts
extends Node3D
## The Lantern Market's two shortcuts from its plan (docs/lantern_market_plan.md),
## both opened from the far side, both walked through with W (the screen
## fades and he comes out at the other end, as the back alley's door does):
##  - the canal lock: in the Canal Quarter, on the first quay, a culvert's
##    iron lock gate; cut its windlass three times and the gate winds up.
##    The culvert runs back under the Upper Market and comes out in the
##    canal under the Lower Market's red bridge, near shrine 6.
##  - the porters' lift: in the Lantern Makers' Rise, by shrine 8, a lift cage
##    hangs in an old shaft on a braked rope; cut the brake rope and it drops
##    to the bottom; it comes out at a porters' door in Festival Square.
## Until it is opened, the near end of each is shut (the culvert's grate is
## down, the porters' door is barred from inside).
## SaveGame.shortcuts: "canal_lock", "porters_lift". Built in the market's
## own coordinates.

## The culvert's ends: in the Canal Quarter (on the quay), under the bridge.
const LOCK_X := 154.6
const LOCK_Y := CanalQuarter.QUAY_Y
const CULVERT_X := 63.0
## The lift: its cage on the Rise's workshops, the door in Festival Square.
const LIFT_X := 337.6
const LIFT_Y := 15.0
const DOOR_X := 128.9
const DOOR_Y := 6.5

var market: LanternMarket
var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _ends: Array = []   # [x, y, id, to_x, to_y, opens_here]
var _hints: Array[ActionHint] = []
var _through := false
var _lock_gate: Node3D
var _culvert_grate: Node3D
var _windlass: Node3D
var _lock_cuts := 0
var _cage: Node3D
var _brake: Node3D
var _door_bar: Node3D


func _ready() -> void:
	_rng.seed = 7272
	_build_lock()
	_build_lift()
	_ends = [
		[LOCK_X, LOCK_Y, "canal_lock", CULVERT_X + 1.2, LanternMarket.CANAL_BED + 0.1],
		[CULVERT_X, LanternMarket.CANAL_BED, "canal_lock", LOCK_X + 1.2, LOCK_Y + 0.1],
		[LIFT_X, LIFT_Y, "porters_lift", DOOR_X + 1.2, DOOR_Y + 0.1],
		[DOOR_X, DOOR_Y, "porters_lift", LIFT_X - 1.2, LIFT_Y + 0.1],
	]
	if "canal_lock" in SaveGame.shortcuts:
		_open_lock(false)
	if "porters_lift" in SaveGame.shortcuts:
		_open_lift(false)


func _physics_process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position - market.global_position
	for i in _ends.size():
		var e: Array = _ends[i]
		var open: bool = e[2] in SaveGame.shortcuts
		var here := absf(at.x - e[0]) < 0.9 and absf(at.y - e[1]) < 0.8 and _ronin.is_on_floor()
		if _hints.size() <= i:
			var hud := get_tree().get_first_node_in_group(&"hud")
			if hud == null:
				return
			var hint := ActionHint.new()
			hint.items = [["W", "Up", "Go through"]]
			hint.point = market.to_global(Vector3(e[0], e[1] + 2.6, 0.0))
			hud.get_parent().add_child(hint)
			_hints.append(hint)
		_hints[i].near = here and open and not _through
		if here and open and not _through and Input.is_action_pressed("aim_up"):
			_through = true
			Sound.play(self, &"shutter_open", -2.0)
			var main := get_tree().root.get_node_or_null("Main")
			if main and main.has_method("_travel"):
				main.call("_travel", market.to_global(Vector3(e[3], e[4], 0.0)), 1.0 if e[3] > e[0] else -1.0)
			get_tree().create_timer(2.0).timeout.connect(func() -> void: _through = false)


# --- The canal lock ------------------------------------------------------------------

func _build_lock() -> void:
	# The quay end: a stone arch at the back of the quay, the culvert dark
	# inside, an iron grate across it; the windlass beside it on a post.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	_arch(b, LOCK_X, LOCK_Y, -1.9)
	add_child(b.build())
	_lock_gate = _grate(LOCK_X, LOCK_Y, -1.75)
	_windlass = Node3D.new()
	_windlass.position = Vector3(LOCK_X - 1.6, LOCK_Y, -1.2)
	add_child(_windlass)
	var w := PaperMesh.new(_rng.randi())
	w.color = Color(0.24, 0.18, 0.15)
	w.box(Vector3(0.0, 0.55, 0.0), Vector3(0.16, 1.1, 0.16))
	w.color = Color(0.18, 0.14, 0.12)
	w.box(Vector3(0.0, 1.1, 0.12), Vector3(0.08, 0.08, 0.3))
	_windlass.add_child(w.build())
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	wheel.position = Vector3(0.0, 1.1, 0.28)
	_windlass.add_child(wheel)
	var r := PaperMesh.new(_rng.randi())
	r.color = Color(0.3, 0.22, 0.17)
	for k in 6:
		var a := TAU * k / 6.0
		r.box(Vector3(cos(a) * 0.22, sin(a) * 0.22, 0.0), Vector3(0.06, 0.06, 0.05))
		MarshKit.limb(r, Vector3.ZERO, Vector3(cos(a) * 0.4, sin(a) * 0.4, 0.0), 0.025, 0.025, 4)
	r.color = Color(0.16, 0.12, 0.1)
	r.frustum(12, Vector2(0.4, 0.4), Vector2(0.4, 0.4), 0.04, Vector3(0.0, 0.0, -0.02))
	var rim := r.build()
	rim.rotation.x = PI * 0.5
	wheel.add_child(rim)
	var chain := PaperMesh.new(1)
	chain.color = Color(0.12, 0.12, 0.14)
	chain.box(Vector3(0.0, 0.25, 0.0), Vector3(0.03, 0.5, 0.03))
	chain.box(Vector3(0.6, 0.55, -0.3), Vector3(1.2, 0.03, 0.03))
	var c := chain.build()
	c.position = Vector3(0.0, 1.1, 0.0)
	_windlass.add_child(c)
	var target := PropTarget.make(self, _box(Vector3(0.7, 1.3, 1.0)), Vector3(LOCK_X - 1.6, LOCK_Y + 0.9, 0.0))
	target.struck.connect(_on_windlass_struck)
	# The far end: under the bridge, in the canal's back wall at its bed.
	var u := PaperMesh.new(_rng.randi())
	u.shade_jitter = 0.12
	_arch(u, CULVERT_X, LanternMarket.CANAL_BED, -1.9)
	add_child(u.build())
	_culvert_grate = _grate(CULVERT_X, LanternMarket.CANAL_BED, -1.75)


## A stone arch set into a wall, the culvert dark behind it.
func _arch(b: PaperMesh, x: float, y: float, z: float) -> void:
	b.color = Color(0.03, 0.03, 0.05)
	b.box(Vector3(x, y + 1.2, z - 0.5), Vector3(1.8, 2.4, 0.9))
	b.color = Color(0.36, 0.35, 0.38)
	for k in 9:
		var a0 := PI * k / 9.0
		var a1 := PI * (k + 1) / 9.0
		var c := Vector3(x, y + 1.6, z + 0.05)
		var r0 := 0.95
		var r1 := 1.3
		b.quad(c + Vector3(cos(a0) * r0, sin(a0) * r0, 0.0), c + Vector3(cos(a0) * r1, sin(a0) * r1, 0.0),
				c + Vector3(cos(a1) * r1, sin(a1) * r1, 0.0), c + Vector3(cos(a1) * r0, sin(a1) * r0, 0.0), Vector3.BACK)
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(x + side * 1.12, y + 0.8, z + 0.05), Vector3(0.35, 1.6, 0.2))
	b.color = Color(0.3, 0.29, 0.32)
	b.box(Vector3(x, y + 0.04, z + 0.2), Vector3(2.6, 0.08, 0.5))


## An iron grate of bars across an arch (it winds up when opened).
func _grate(x: float, y: float, z: float) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x, y, z)
	add_child(g)
	var b := PaperMesh.new(_rng.randi())
	b.color = Color(0.14, 0.14, 0.16)
	for k in 7:
		b.box(Vector3(-0.84 + k * 0.28, 1.25, 0.0), Vector3(0.05, 2.5, 0.05))
	for y2: float in [0.5, 1.3, 2.1]:
		b.box(Vector3(0.0, y2, 0.02), Vector3(1.8, 0.06, 0.04))
	g.add_child(b.build())
	return g


func _box(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


func _on_windlass_struck(_direction: Vector2) -> void:
	if "canal_lock" in SaveGame.shortcuts:
		return
	_lock_cuts += 1
	Sound.play(self, &"grate_clank", -2.0)
	var wheel := _windlass.get_node("Wheel") as Node3D
	var t := create_tween()
	t.tween_property(wheel, "rotation:z", wheel.rotation.z - 1.4, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lift := create_tween()
	lift.tween_property(_lock_gate, "position:y", LOCK_Y + _lock_cuts * 0.6, 0.35)
	if _lock_cuts >= 3:
		SaveGame.opened("canal_lock")
		SaveGame.write()
		_open_lock(true)


func _open_lock(slow: bool) -> void:
	for g: Node3D in [_lock_gate, _culvert_grate]:
		var to := g.position.y + 2.3 if g == _culvert_grate else LOCK_Y + 2.3
		if slow:
			var t := create_tween()
			t.tween_property(g, "position:y", to, 0.8).set_trans(Tween.TRANS_SINE)
		else:
			g.position.y = to
	if slow:
		Sound.play(self, &"grate_clank", 2.0)


# --- The porters' lift ---------------------------------------------------------------

func _build_lift() -> void:
	# On the Rise: a timber frame over an old shaft at the back of the
	# workshops, a pulley at its top, the cage hung on its rope, a brake
	# rope tied to a cleat.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	var x := LIFT_X
	var y := LIFT_Y
	b.color = Color(0.22, 0.17, 0.14)
	for px: float in [x - 1.1, x + 1.1]:
		for pz: float in [-2.6, -0.9]:
			b.box(Vector3(px, y + 2.3, pz), Vector3(0.16, 4.6, 0.16))
	b.box(Vector3(x, y + 4.6, -1.75), Vector3(2.5, 0.2, 1.9))
	b.color = Color(0.03, 0.03, 0.05)
	b.box(Vector3(x, y + 0.01, -1.75), Vector3(2.0, 0.02, 1.5))  # the shaft's dark mouth
	b.color = Color(0.3, 0.24, 0.2)
	b.frustum(10, Vector2(0.28, 0.28), Vector2(0.28, 0.28), 0.12, Vector3(x, y + 4.4, -1.75))
	add_child(b.build())
	_cage = Node3D.new()
	_cage.position = Vector3(x, y + 0.05, -1.75)
	add_child(_cage)
	var c := PaperMesh.new(_rng.randi())
	c.color = Color(0.3, 0.24, 0.19)
	for cx: float in [-0.75, 0.75]:
		for cz: float in [-0.55, 0.55]:
			c.box(Vector3(cx, 1.1, cz), Vector3(0.07, 2.2, 0.07))
	c.box(Vector3(0.0, 0.05, 0.0), Vector3(1.6, 0.1, 1.2))
	c.box(Vector3(0.0, 2.2, 0.0), Vector3(1.6, 0.08, 1.2))
	c.color = Color(0.22, 0.17, 0.14)
	for k in 4:
		c.box(Vector3(-0.75, 0.4 + k * 0.5, 0.0), Vector3(0.04, 0.04, 1.2))
		c.box(Vector3(0.75, 0.4 + k * 0.5, 0.0), Vector3(0.04, 0.04, 1.2))
	c.color = Color(0.5, 0.44, 0.34)
	c.box(Vector3(0.0, 2.2 + 1.1, 0.0), Vector3(0.03, 2.2, 0.03))  # its rope up to the pulley
	_cage.add_child(c.build())
	# The brake rope down to a cleat on the near post.
	_brake = Node3D.new()
	_brake.position = Vector3(x + 1.1, y + 1.2, -0.85)
	add_child(_brake)
	var r := PaperMesh.new(1)
	r.color = Color(0.55, 0.48, 0.36)
	MarshKit.limb(r, Vector3.ZERO, Vector3(-1.05, 3.2, -0.9), 0.02, 0.02, 4)
	r.color = Color(0.2, 0.15, 0.12)
	r.box(Vector3(0.0, 0.0, 0.05), Vector3(0.2, 0.06, 0.08))
	_brake.add_child(r.build())
	var target := PropTarget.make(self, _box(Vector3(0.7, 1.6, 1.0)), Vector3(x + 1.0, y + 1.6, 0.0))
	target.struck.connect(_on_brake_struck)
	# In Festival Square: a porters' door at the back of the square, barred.
	var d := PaperMesh.new(_rng.randi())
	d.shade_jitter = 0.1
	var dx := DOOR_X
	var dy := DOOR_Y
	# (A porters' storehouse, its door on the square: solid all round.)
	d.color = MarshKit.STONE.darkened(0.2)
	d.box(Vector3(dx, dy + 0.3, -3.0), Vector3(3.2, 0.6, 1.8))
	d.color = Color(0.58, 0.55, 0.5)
	d.box(Vector3(dx, dy + 1.9, -3.0), Vector3(3.0, 2.6, 1.6))
	d.color = Color(0.2, 0.17, 0.15)
	for px: float in [dx - 1.5, dx + 1.5]:
		d.box(Vector3(px, dy + 1.6, -2.2), Vector3(0.16, 3.2, 0.16))
	d.box(Vector3(dx, dy + 3.2, -2.2), Vector3(3.2, 0.16, 0.16))
	d.color = Color(0.36, 0.34, 0.38)
	d.box(Vector3(dx, dy + 1.3, -2.24), Vector3(2.0, 2.6, 0.12))
	d.color = LanternMarket.LACQUER.darkened(0.4)
	d.box(Vector3(dx, dy + 1.1, -2.08), Vector3(1.4, 2.2, 0.08))
	d.color = Color(0.86, 0.68, 0.34).darkened(0.3)
	d.box(Vector3(dx, dy + 2.28, -2.05), Vector3(1.6, 0.1, 0.12))
	add_child(d.build())
	add_child(Scenery.tiled_roof(_rng, dx - 1.9, dx + 1.9, Vector2(dy + 3.3, -1.7), Vector2(dy + 4.1, -3.0), 3))
	add_child(Scenery.tiled_roof(_rng, dx - 1.9, dx + 1.9, Vector2(dy + 3.3, -4.3), Vector2(dy + 4.1, -3.0), 3))
	_door_bar = Node3D.new()
	_door_bar.position = Vector3(dx, dy + 1.1, -2.0)
	add_child(_door_bar)
	var bar := PaperMesh.new(1)
	bar.color = Color(0.2, 0.15, 0.12)
	bar.box(Vector3.ZERO, Vector3(1.7, 0.14, 0.1))
	_door_bar.add_child(bar.build())


func _on_brake_struck(_direction: Vector2) -> void:
	if "porters_lift" in SaveGame.shortcuts:
		return
	SaveGame.opened("porters_lift")
	SaveGame.write()
	_open_lift(true)


func _open_lift(slow: bool) -> void:
	if slow:
		Sound.play(self, &"plank_snap", 2.0)
		var t := create_tween()
		t.tween_property(_brake, "rotation:z", -1.2, 0.3)
		t.parallel().tween_property(_brake, "scale", Vector3(1.0, 0.4, 1.0), 0.3)
		# The cage drops down the shaft and is gone; then rises back up to wait.
		var c := create_tween()
		c.tween_property(_cage, "position:y", LIFT_Y - 6.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		c.tween_callback(func() -> void: Sound.play(self, &"land", 2.0))
		c.tween_interval(0.6)
		c.tween_property(_cage, "position:y", LIFT_Y + 0.05, 2.4).set_trans(Tween.TRANS_SINE)
		var bar := create_tween()
		bar.tween_interval(1.2)
		bar.tween_property(_door_bar, "position:x", DOOR_X + 1.3, 0.6)
		bar.parallel().tween_property(_door_bar, "rotation:z", 1.4, 0.6)
	else:
		_brake.rotation.z = -1.2
		_brake.scale = Vector3(1.0, 0.4, 1.0)
		_door_bar.position.x = DOOR_X + 1.3
		_door_bar.rotation.z = 1.4
