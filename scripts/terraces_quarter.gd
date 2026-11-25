class_name TerracesQuarter
extends Node3D
## The Gilded Terraces and Hōshō's Gate (docs/lantern_market_plan.md, areas
## 8 and 9), past the top of the Lantern Makers' Rise, and his hall:
##  - The first terrace (G1, 18.5 m): gilded houses, their eaves hung with
##    gold-leaf lanterns, a gilded guard.
##  - A red arched bridge between two towers over a deep drop (falling in
##    carries him back to the last shrine), to the second terrace (G2,
##    21.5 m), two more guards.
##  - Steps up to Hōshō's Gate (G3, 24 m): shrine 9 (`hosho_gate`), great
##    lanterns, his banners, and the Gilded Gate itself, whose doors swing
##    open as he comes.
##  - The hall (HALL): a great lacquered room, open in front, its back one
##    vast wall of lit shoji where Hōshō's shadow falls, red pillars, his
##    banners, lantern stands, the floor red and gold. HoshoHall runs what
##    happens there.
## Built in the market's coordinates, a child of the Rise.

const START := 372.0
const G1 := Vector3(372.0, 392.0, 18.5)
const BRIDGE := Vector2(392.0, 404.0)
const DROP_FLOOR := 4.0
const G2 := Vector3(404.0, 420.0, 21.5)
const STEPS := Vector2(420.0, 426.0)
const G3 := Vector3(426.0, 444.0, 24.0)
const SHRINE_X := 429.5
const GATE_X := 442.5
const HALL := Vector3(444.0, 480.0, 24.0)
const GUARDS := [385.0, 411.0, 416.5]
const BACK_Z := -6.5
const GOLD := Color(0.86, 0.68, 0.34)

var market: LanternMarket
var quarter: CanalQuarter
var hall: HoshoHall
var _rng := RandomNumberGenerator.new()
var _gate_doors: Array[Node3D] = []
var _gate_open := false
var _ronin: Ronin


static func deck_at(x: float) -> float:
	var u := clampf((x - BRIDGE.x) / (BRIDGE.y - BRIDGE.x), 0.0, 1.0)
	return lerpf(G1.z, G2.z, u) + 1.3 * sin(PI * u)


static func ground_at(x: float) -> float:
	if x > HALL.y:
		return BackCourt.ground_at(x)
	if x < BRIDGE.x:
		return G1.z
	if x < BRIDGE.y:
		return deck_at(x)
	if x < STEPS.x:
		return G2.z
	if x < STEPS.y:
		return lerpf(G2.z, G3.z, (x - STEPS.x) / (STEPS.y - STEPS.x))
	return G3.z


func _ready() -> void:
	_rng.seed = 8181
	add_to_group(&"terraces")
	quarter._quay(START + 2.0, G1.y, G1.z)
	quarter._quay(G2.x, STEPS.y, G2.z)
	quarter._build_stairs(STEPS, G2.z, G3.z)
	quarter._quay(G3.x, HALL.y + 2.0, G3.z)
	_build_drop()
	_build_bridge()
	_build_backing()
	_build_houses()
	_build_gate_plaza()
	for x: float in GUARDS:
		var guard := GildedGuard.new()
		guard.position = Vector3(x, ground_at(x) + 0.05, 0.0)
		add_child(guard)
	var shrine := RestShrine.new()
	shrine.shrine_id = "hosho_gate"
	shrine.position = Vector3(SHRINE_X, G3.z, -0.9)
	shrine.scale = Vector3.ONE * 1.3
	add_child(shrine)
	hall = HoshoHall.new()
	hall.market = market
	hall.terraces = self
	add_child(hall)
	for x: float in [380.0, 398.0, 412.0, 432.0]:
		market._light(Vector3(x, ground_at(x) + 3.4, -2.2), market.village.lantern_energy * 0.8, market.village.lantern_range * 1.1)


const DOOR_X := (BRIDGE.x + BRIDGE.y) * 0.5 + 2.4
var _door_hint: ActionHint
var _through := false


func _process_door(x: float) -> void:
	var at_door := absf(x - DOOR_X) < 0.9 and _ronin.global_position.y - market.global_position.y < DROP_FLOOR + 1.0 and _ronin.is_on_floor()
	if _door_hint == null:
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud == null:
			return
		_door_hint = ActionHint.new()
		_door_hint.items = [["W", "Up", "Go through"]]
		_door_hint.point = market.to_global(Vector3(DOOR_X, DROP_FLOOR + 2.9, 0.0))
		hud.get_parent().add_child(_door_hint)
	_door_hint.near = at_door and not _through
	if at_door and not _through and Input.is_action_pressed("aim_up"):
		_through = true
		Sound.play(self, &"shutter_open", 0.0)
		var main := get_tree().root.get_node_or_null("Main")
		if main and main.has_method("_travel"):
			main.call("_travel", market.to_global(Vector3(G2.x + 1.6, G2.z + 0.1, 0.0)), 1.0)
		get_tree().create_timer(2.0).timeout.connect(func() -> void: _through = false)


func _physics_process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		return
	var x := _ronin.global_position.x - market.global_position.x
	# (Under the bridge is the back alley now, not a fall back to the
	# shrine.) Its back door: W there and he goes up through the cliff and
	# comes out on the far terrace (the bridge roofs the alley over, so its
	# walls cannot be climbed out of).
	_process_door(x)
	# The Gilded Gate opens as he comes up to it.
	if not _gate_open and x > GATE_X - 3.0 and x < GATE_X + 1.0 and _ronin.global_position.y > G3.z - 1.0:
		open_gate(true)


# --- Building it ----------------------------------------------------------------------

## The back alley under the bridge (the plan: "a back-alley route
## underneath for those who fall"): a narrow paved lane deep between the
## terrace walls, a lantern on a bracket, crates, a drain, the bridge's
## underside high above, a bundle of cranes for whoever comes down, and a
## lacquered back door: through it a stair inside the cliff comes out on the
## far terrace (`_process_door`).
func _build_drop() -> void:
	var mid := (BRIDGE.x + BRIDGE.y) * 0.5
	market._solid(Vector3(mid, DROP_FLOOR - 0.5, 0.0), Vector3(BRIDGE.y - BRIDGE.x, 1.0, 4.0))
	# The terrace walls go all the way down (the quays' bodies stop 10 m
	# under their tops).
	market._solid(Vector3(BRIDGE.x - 2.0, (DROP_FLOOR + G1.z - 10.0) * 0.5, -1.5), Vector3(4.0, G1.z - 10.0 - DROP_FLOOR + 0.2, 6.0))
	market._solid(Vector3(BRIDGE.y + 2.0, (DROP_FLOOR + G2.z - 10.0) * 0.5, -1.5), Vector3(4.0, G2.z - 10.0 - DROP_FLOOR + 0.2, 6.0))
	market.village._lay_paving(LanternMarket.SHIFT + BRIDGE.x, LanternMarket.SHIFT + BRIDGE.y, DROP_FLOOR, Village.STREET_BACK, LanternMarket.NEAR_Z)
	market.village._add_rain_splashes(LanternMarket.SHIFT + BRIDGE.x, LanternMarket.SHIFT + BRIDGE.y, DROP_FLOOR)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.16
	# The back: the old stone of the cliff, a lacquered back door, set in.
	b.color = Color(0.2, 0.19, 0.24)
	b.box(Vector3(mid, (DROP_FLOOR + G1.z) * 0.5, Village.STREET_BACK - 0.3), Vector3(BRIDGE.y - BRIDGE.x, G1.z - DROP_FLOOR, 0.4))
	b.color = Color(0.29, 0.28, 0.33)
	var y := DROP_FLOOR
	var row := 0
	while y < G1.z - 0.01:
		var x0 := BRIDGE.x + (0.5 if row % 2 == 1 else 0.0)
		while x0 < BRIDGE.y - 0.01:
			var x1 := minf(x0 + _rng.randf_range(0.9, 1.4), BRIDGE.y)
			b.color = Color(0.27, 0.26, 0.31) * _rng.randf_range(0.8, 1.12)
			b.box(Vector3((x0 + x1) * 0.5, y + 0.3, Village.STREET_BACK - 0.08), Vector3(x1 - x0 - 0.04, 0.56, 0.06))
			x0 = x1
		y += 0.6
		row += 1
	b.color = LanternMarket.LACQUER.darkened(0.35)
	b.box(Vector3(mid + 2.4, DROP_FLOOR + 1.2, Village.STREET_BACK - 0.02), Vector3(1.4, 2.4, 0.1))
	b.color = GOLD.darkened(0.3)
	b.box(Vector3(mid + 2.4, DROP_FLOOR + 2.45, Village.STREET_BACK + 0.02), Vector3(1.6, 0.1, 0.12))
	# Crates and a barrel by the wall; a drain grate.
	b.color = Color(0.42, 0.3, 0.2)
	b.box(Vector3(BRIDGE.x + 1.2, DROP_FLOOR + 0.4, -1.9), Vector3(0.8, 0.8, 0.8))
	b.box(Vector3(BRIDGE.x + 1.3, DROP_FLOOR + 1.1, -2.0), Vector3(0.6, 0.6, 0.6))
	b.box(Vector3(BRIDGE.x + 2.2, DROP_FLOOR + 0.35, -2.2), Vector3(0.7, 0.7, 0.7))
	b.color = Color(0.3, 0.2, 0.16)
	b.frustum(10, Vector2(0.32, 0.32), Vector2(0.3, 0.3), 0.9, Vector3(BRIDGE.y - 1.4, DROP_FLOOR, -2.0))
	b.color = Color(0.08, 0.08, 0.1)
	b.box(Vector3(mid - 1.5, DROP_FLOOR + 0.02, -0.6), Vector3(1.2, 0.02, 0.6))
	add_child(b.build())
	# A lantern on a bracket from the back wall.
	var arm := PaperMesh.new(_rng.randi())
	arm.color = PaperMesh.TIMBER
	arm.box(Vector3(mid - 0.6, DROP_FLOOR + 3.3, Village.STREET_BACK + 0.35), Vector3(0.07, 0.07, 0.8))
	add_child(arm.build())
	market._hang(Vector3(mid - 0.6, DROP_FLOOR + 3.27, Village.STREET_BACK + 0.72), 0.7, 0.15)
	market._light(Vector3(mid - 0.6, DROP_FLOOR + 2.8, -0.8), market.village.lantern_energy * 0.7, market.village.lantern_range)
	var cranes := CraneBundle.new()
	cranes.id = "terraces_alley"
	cranes.count = 6
	cranes.position = Vector3(BRIDGE.y - 2.6, DROP_FLOOR, -0.2)
	add_child(cranes)


## The red arched bridge over the drop, between two towers: lacquered rails
## on posts, lanterns on the posts at its ends and crown, boards underfoot.
func _build_bridge() -> void:
	var steps := 24
	for k in steps:
		var x0 := BRIDGE.x + (BRIDGE.y - BRIDGE.x) * k / steps
		var x1 := BRIDGE.x + (BRIDGE.y - BRIDGE.x) * (k + 1) / steps
		market._slope(x0, deck_at(x0), x1, deck_at(x1), 0.5)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	for k in steps:
		var x0 := BRIDGE.x + (BRIDGE.y - BRIDGE.x) * k / steps
		var x1 := BRIDGE.x + (BRIDGE.y - BRIDGE.x) * (k + 1) / steps
		var y0 := deck_at(x0)
		var y1 := deck_at(x1)
		b.color = Scenery.WOOD.lightened(0.12) * _rng.randf_range(0.85, 1.1)
		b.quad(Vector3(x0, y0, 1.4), Vector3(x1, y1, 1.4), Vector3(x1, y1, -1.4), Vector3(x0, y0, -1.4), Vector3.UP)
		b.color = LanternMarket.LACQUER
		b.quad(Vector3(x0, y0, 1.4), Vector3(x1, y1, 1.4), Vector3(x1, y1 - 0.5, 1.4), Vector3(x0, y0 - 0.5, 1.4), Vector3.BACK)
		# The rails, front and back, rising and falling with the deck.
		for z: float in [1.35, -1.35]:
			b.quad(Vector3(x0, y0 + 0.95, z), Vector3(x1, y1 + 0.95, z), Vector3(x1, y1 + 1.05, z), Vector3(x0, y0 + 1.05, z), Vector3(0.0, 0.0, signf(z)))
	# Posts along the rails, gold-capped.
	for k in 7:
		var x := BRIDGE.x + 0.3 + (BRIDGE.y - BRIDGE.x - 0.6) * k / 6.0
		var y := deck_at(x)
		for z: float in [1.35, -1.35]:
			b.color = LanternMarket.LACQUER
			b.box(Vector3(x, y + 0.6, z), Vector3(0.12, 1.2, 0.12))
			b.color = GOLD
			b.frustum(6, Vector2(0.08, 0.08), Vector2(0.01, 0.01), 0.16, Vector3(x, y + 1.2, z))
	# The arch underneath: a curved beam on piers down into the drop.
	b.color = LanternMarket.LACQUER.darkened(0.2)
	for k in steps:
		var x0 := BRIDGE.x + (BRIDGE.y - BRIDGE.x) * k / steps
		var x1 := BRIDGE.x + (BRIDGE.y - BRIDGE.x) * (k + 1) / steps
		b.box(Vector3((x0 + x1) * 0.5, (deck_at(x0) + deck_at(x1)) * 0.5 - 0.8, 0.0), Vector3(x1 - x0 + 0.02, 0.4, 2.4))
	add_child(b.build())
	for x: float in [BRIDGE.x + 0.3, (BRIDGE.x + BRIDGE.y) * 0.5, BRIDGE.y - 0.3]:
		market._hang(Vector3(x - 0.3, deck_at(x) + 1.36, -1.35), 0.8, 0.1)
		var arm := PaperMesh.new(_rng.randi())
		arm.color = LanternMarket.LACQUER
		arm.box(Vector3(x, deck_at(x) + 1.4, -1.35), Vector3(0.12, 0.1, 0.1))
		arm.box(Vector3(x - 0.15, deck_at(x) + 1.4, -1.35), Vector3(0.4, 0.06, 0.06))
		add_child(arm.build())
	# The towers at its two ends, behind it.
	for tx: float in [BRIDGE.x - 1.6, BRIDGE.y + 1.6]:
		var foot := ground_at(tx)
		var t := PaperMesh.new(_rng.randi())
		t.shade_jitter = 0.12
		t.color = Color(0.5, 0.46, 0.42)
		t.box(Vector3(tx, foot + 3.0, -4.2), Vector3(2.6, 6.0, 2.6))
		t.color = LanternMarket.LACQUER.darkened(0.1)
		for k in 3:
			t.box(Vector3(tx, foot + 1.6 + k * 2.0, -2.85), Vector3(2.7, 0.12, 0.06))
		t.color = Color(1.0, 0.76, 0.46)
		t.rect(Vector2(tx, foot + 4.5), Vector2(0.9, 0.7), -2.88)
		add_child(t.build(Color.WHITE, 0.0))
		add_child(Scenery.tiled_roof(_rng, tx - 1.8, tx + 1.8, Vector2(foot + 6.0, -2.4), Vector2(foot + 7.2, -4.2), 2))
		add_child(Scenery.tiled_roof(_rng, tx - 1.8, tx + 1.8, Vector2(foot + 6.0, -6.0), Vector2(foot + 7.2, -4.2), 2, false))


func _build_backing() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.color = Scenery.WALL_DARK.darkened(0.35)
	for t: Vector3 in [G1, G2, G3]:
		b.box(Vector3((t.x + t.y) * 0.5, t.z + 3.4, -9.4), Vector3(t.y - t.x + 2.0, 6.8, 0.2))
	add_child(b.build())


## Gilded houses: lit, their fronts trimmed with gold leaf, gold lanterns.
func _build_houses() -> void:
	for h: Array in [[375.6, 5.0, 6.2], [381.2, 5.4, 6.8], [387.0, 5.2, 6.0], [407.6, 5.6, 6.6], [413.6, 5.4, 6.2], [419.0, 4.6, 5.8]]:
		var x: float = h[0]
		var house := Scenery.house(_rng, h[1], h[2], true, market.village.window_glow,
				[["noren"], ["sudare"], ["pots"], ["umbrella"]][_rng.randi() % 4])
		house.position = Vector3(x, ground_at(x), -6.6)
		add_child(house)
		# Gold leaf along its eaves and corner posts.
		var g := PaperMesh.new(_rng.randi())
		g.color = GOLD
		var half: float = h[1] * 0.5
		g.box(Vector3(0.0, h[2] - 0.45, 0.16), Vector3(h[1], 0.1, 0.04))
		for side: float in [-1.0, 1.0]:
			g.box(Vector3(side * (half - 0.12), h[2] * 0.5, 0.16), Vector3(0.06, h[2] - 0.8, 0.04))
		var trim := g.build()
		(trim.material_override as StandardMaterial3D).metallic = 0.6
		(trim.material_override as StandardMaterial3D).roughness = 0.35
		house.add_child(trim)
		market._eave_lantern(house.position, h[2], x + _rng.randf_range(-1.2, 1.2), 0.9)
	# Banners with his crest along the terraces.
	for bx: float in [378.5, 390.0, 409.5]:
		_banner(Vector3(bx, ground_at(bx), -3.0))


## One of his banners: red, with his crest (a plum blossom in gold) on a
## pole with a crossbar.
func _banner(at: Vector3) -> void:
	var banner := Node3D.new()
	banner.position = at + Vector3(0.0, 6.0, 0.0)
	add_child(banner)
	var c := PaperMesh.new(_rng.randi())
	c.color = LanternMarket.RED_CLOTH
	c.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.55, 0.0), Vector2(0.55, 0.0), Vector2(0.55, -3.4), Vector2(0.0, -3.0), Vector2(-0.55, -3.4)]), 0.3, 0.04, _rng), 0.0)
	c.color = GOLD
	c.ellipse(Vector2(0.0, -0.9), Vector2(0.4, 0.4), 16, 0.005)
	c.color = LanternMarket.RED_CLOTH
	for p in 5:
		var a := TAU * p / 5.0 + PI * 0.5
		c.ellipse(Vector2(0.0, -0.9) + Vector2(cos(a), sin(a)) * 0.16, Vector2(0.11, 0.11), 8, 0.007)
	banner.add_child(c.build())
	Scenery.windswept(banner, 0.05, _rng)
	var pole := PaperMesh.new(_rng.randi())
	pole.color = PaperMesh.TIMBER
	pole.box(at + Vector3(0.6, 3.6, 0.0), Vector3(0.12, 7.2, 0.12))
	pole.box(at + Vector3(0.0, 6.05, 0.0), Vector3(1.5, 0.08, 0.08))
	add_child(pole.build())


## Hōshō's Gate: the plaza before it with great lanterns, and the Gilded
## Gate, its doors gold leaf with his crest, in a wall running back.
func _build_gate_plaza() -> void:
	var g := G3.z
	var gx := GATE_X
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = LanternMarket.LACQUER.darkened(0.1)
	for pz: float in [1.9, -3.2]:
		b.box(Vector3(gx, g + 3.8, pz), Vector3(0.55, 7.6, 0.55))
	b.box(Vector3(gx, g + 7.0, -0.65), Vector3(0.75, 0.5, 6.4))
	b.box(Vector3(gx, g + 5.7, -0.65), Vector3(0.55, 0.3, 5.6))
	add_child(b.build())
	GateWalls.build(self, market, _rng, gx, g, -3.2, 1.9, -9.1, 5.6, Vector2.ZERO, 5.2)
	add_child(Scenery.tiled_roof(_rng, gx - 1.7, gx + 1.7, Vector2(g + 7.4, 2.8), Vector2(g + 9.0, -0.65), 4))
	add_child(Scenery.tiled_roof(_rng, gx - 1.7, gx + 1.7, Vector2(g + 7.4, -4.1), Vector2(g + 9.0, -0.65), 4, false))
	# The doors: two leaves of gold leaf, hinged on the posts, his crest.
	for k in 2:
		var hinge := Node3D.new()
		hinge.position = Vector3(gx, g, 1.65 if k == 0 else -2.95)
		add_child(hinge)
		var d := PaperMesh.new(_rng.randi())
		d.color = GOLD.darkened(0.12)
		var span := -2.3 if k == 0 else 2.3
		d.box(Vector3(0.0, 2.75, span * 0.5), Vector3(0.18, 5.5, absf(span)))
		d.color = LanternMarket.RED_CLOTH
		d.box(Vector3(-0.1, 3.6, span * 0.5), Vector3(0.02, 0.6, 0.6))
		var doors := d.build()
		(doors.material_override as StandardMaterial3D).metallic = 0.6
		(doors.material_override as StandardMaterial3D).roughness = 0.4
		hinge.add_child(doors)
		_gate_doors.append(hinge)
	# Great lanterns on stands before it.
	for lx: float in [gx - 7.5, gx - 3.0]:
		var stand := PaperMesh.new(_rng.randi())
		stand.color = PaperMesh.TIMBER
		stand.box(Vector3(lx, g + 2.4, -1.8), Vector3(0.14, 4.8, 0.14))
		stand.box(Vector3(lx + 0.4, g + 4.75, -1.8), Vector3(0.9, 0.1, 0.1))
		add_child(stand.build())
		market._hang(Vector3(lx + 0.7, g + 4.7, -1.8), 1.9, 0.2)
		market._light(Vector3(lx + 0.7, g + 3.8, -0.8), market.village.lantern_energy, market.village.lantern_range * 1.1)
	_banner(Vector3(gx - 10.0, g, -2.8))
	_banner(Vector3(gx - 5.2, g, -2.8))
	if SaveGame.hosho_met:
		open_gate(false)


## The doors swing open into the hall.
func open_gate(slow: bool) -> void:
	if _gate_open:
		return
	_gate_open = true
	for k in _gate_doors.size():
		var hinge := _gate_doors[k]
		var to := deg_to_rad(80.0) * (-1.0 if k == 0 else 1.0)   # (into the hall)
		if slow:
			var t := create_tween()
			t.tween_property(hinge, "rotation:y", to, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			hinge.rotation.y = to
	if slow:
		Sound.play(self, &"plank_creak", 2.0)
		Sound.play(self, &"taiko_hit", -6.0)


## The doors swing shut behind him (the fight), or open again.
func close_gate(shut: bool) -> void:
	for k in _gate_doors.size():
		var to := 0.0 if shut else deg_to_rad(80.0) * (-1.0 if k == 0 else 1.0)
		var t := create_tween()
		t.tween_property(_gate_doors[k], "rotation:y", to, 0.8).set_trans(Tween.TRANS_QUAD)
	if shut:
		Sound.play(self, &"plank_snap", 0.0)
