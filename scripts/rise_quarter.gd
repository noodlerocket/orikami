class_name RiseQuarter
extends Node3D
## The Lantern Makers' Rise (docs/lantern_market_plan.md, area 7): out of the
## Ward of Shut Doors through its east gate, a climb where the market's great
## lanterns are made.
##  - The gate out of the Ward: a burning barricade across it (FireBarrier),
##    that only the Fan Gust puts out.
##  - Stone steps up to the kiln yard (T1, 10 m): two great brick kilns
##    glowing; in front of each, an iron grate in the floor over the flue,
##    hot air pouring up out of it (Updraft, kiln) to glide up on. Up there,
##    a red drying deck (HIGH_DECK) with cranes behind a second burning
##    barricade. A great paper windmill: gusted, it spins and drives the
##    lantern-cage hoist up the cliff to the workshops.
##  - The workshops (T2, 15 m): lantern frames, giant and bare, drying
##    paper, the kiln shrine (shrine 8, "kilns"). Chōchin-obake float here.
##  - Steps up to the top (T3, 18.5 m) and the gate onward to the Gilded
##    Terraces (shut: not built yet).
## Built in the market's coordinates, a child of the Ward.

const START := 296.0
const STEPS_1 := Vector2(297.0, 305.0)
const T1 := Vector3(305.0, 330.0, 10.0)
const T2 := Vector3(330.0, 350.0, 15.0)
const STEPS_2 := Vector2(350.0, 356.0)
const T3 := Vector3(356.0, 372.0, 18.5)
const KILNS := [312.0, 323.5]
## The drying deck above the kiln yard: [middle, top, width].
const HIGH_DECK := [317.5, 16.8, 6.0]
const WINDMILL_X := 326.6
const HOIST_X := 328.7
const SHRINE_X := 333.5
const TERRACES_GATE := 370.0
const CHOCHIN := [Vector2(318.0, 13.2), Vector2(338.5, 17.6), Vector2(346.5, 18.2)]
const LANTERN_HUSKS := [Vector2(342.5, 15.0)]

var market: LanternMarket
var quarter: CanalQuarter
var ward: WardQuarter
var windmill: Windmill
var hoist: CageHoist
var _rng := RandomNumberGenerator.new()
var _hint: ActionHint
var _ronin: Ronin
var _gate_fire: FireBarrier


## The ground's height at a market x on the Rise.
static func ground_at(x: float) -> float:
	if x < STEPS_1.x:
		return CanalQuarter.BANK_Y
	if x < STEPS_1.y:
		return lerpf(CanalQuarter.BANK_Y, T1.z, (x - STEPS_1.x) / (STEPS_1.y - STEPS_1.x))
	if x < T2.x:
		return T1.z
	if x < STEPS_2.x:
		return T2.z
	if x < STEPS_2.y:
		return lerpf(T2.z, T3.z, (x - STEPS_2.x) / (STEPS_2.y - STEPS_2.x))
	if x >= TerracesQuarter.START:
		return TerracesQuarter.ground_at(x)
	return T3.z


func _ready() -> void:
	_rng.seed = 7070
	add_to_group(&"rise")
	quarter._quay(STEPS_1.x, STEPS_1.y, CanalQuarter.BANK_Y)
	quarter._build_stairs(STEPS_1, CanalQuarter.BANK_Y, T1.z)
	quarter._quay(T1.x, T1.y, T1.z)
	quarter._quay(T2.x, STEPS_2.y, T2.z)
	quarter._build_stairs(STEPS_2, T2.z, T3.z)
	quarter._quay(T3.x, T3.y + 2.0, T3.z)
	var terraces := TerracesQuarter.new()
	terraces.market = market
	terraces.quarter = quarter
	add_child(terraces)
	_build_backing()
	_build_houses()
	for x: float in KILNS:
		_kiln(x)
	market._gallery(HIGH_DECK[0], HIGH_DECK[1], HIGH_DECK[2])
	_build_windmill_and_hoist()
	_build_workshops()
	_build_terraces_gate()
	_gate_fire = FireBarrier.new()
	_gate_fire.id = "rise_gate_fire"
	# (In front of the gate, the Ward's side: just inside it, the gate's wing
	# hid it from him as he came.)
	_gate_fire.position = Vector3(START - 1.0, CanalQuarter.BANK_Y, 0.0)
	add_child(_gate_fire)
	var deck_fire := FireBarrier.new()
	deck_fire.id = "rise_deck_fire"
	deck_fire.height = 2.0
	deck_fire.depth = 2.2
	deck_fire.position = Vector3(HIGH_DECK[0] + 1.3, HIGH_DECK[1], 0.0)
	add_child(deck_fire)
	var cranes := CraneBundle.new()
	cranes.id = "rise_deck"
	cranes.count = 8
	cranes.position = Vector3(HIGH_DECK[0] + 2.5, HIGH_DECK[1], 0.0)
	add_child(cranes)
	var shrine := RestShrine.new()
	shrine.shrine_id = "kilns"
	shrine.position = Vector3(SHRINE_X, T2.z, -0.9)
	shrine.scale = Vector3.ONE * 1.3
	add_child(shrine)
	for spot: Vector2 in CHOCHIN:
		var ghost := ChochinObake.new()
		ghost.position = Vector3(spot.x, spot.y, 0.0)
		add_child(ghost)
	for spot: Vector2 in LANTERN_HUSKS:
		var keeper := LanternHusk.new()
		keeper.position = Vector3(spot.x, spot.y, 0.0)
		add_child(keeper)
	for x: float in [314.0, 336.0, 352.0, 364.0]:
		market._light(Vector3(x, ground_at(x) + 3.4, -2.4), market.village.lantern_energy * 0.7, market.village.lantern_range * 1.1)


func _process(_delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		return
	# A hint by the burning gate once he has the fan.
	if _hint == null:
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud == null:
			return
		_hint = ActionHint.new()
		_hint.items = [["O", "RT", "Fan Gust"]]
		_hint.point = market.to_global(Vector3(START - 1.0, CanalQuarter.BANK_Y + 3.4, 0.0))
		hud.get_parent().add_child(_hint)
	var x := _ronin.global_position.x - market.global_position.x
	_hint.near = _ronin.has_gust and not _gate_fire.out and x > START - 8.0 and x < START - 1.0


# --- Building it --------------------------------------------------------------------

func _build_backing() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	b.color = Scenery.WALL_DARK.darkened(0.35)
	for t: Vector3 in [T1, T2, T3]:
		b.box(Vector3((t.x + t.y) * 0.5, t.z + 3.2, -9.0), Vector3(t.y - t.x + 2.0, 6.4, 0.2))
	add_child(b.build())


## The lantern makers' houses at the back of each terrace.
func _build_houses() -> void:
	for h: Array in [[306.8, 3.6, 5.2], [317.6, 5.4, 6.4], [333.0, 5.2, 5.8], [339.2, 5.6, 6.2], [345.6, 6.0, 5.6], [359.0, 5.6, 6.0], [365.2, 5.4, 5.6]]:
		var x: float = h[0]
		var house := Scenery.house(_rng, h[1], h[2], true, market.village.window_glow,
				[["noren"], ["sudare"], ["pots"], ["firewood"]][_rng.randi() % 4])
		house.position = Vector3(x, ground_at(x), -6.6)
		add_child(house)
		if _rng.randf() < 0.7:
			market._eave_lantern(house.position, h[2], x + _rng.randf_range(-1.2, 1.2), 0.85)


## A great brick kiln for the lanterns: a dome of brick, soot-stained, its
## arched mouth glowing, a chimney smoking; in front of it, in the yard's
## floor, an iron grate over its flue, hot air pouring up out of it.
func _kiln(x: float) -> void:
	var g := T1.z
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.22
	var rings := []
	for k in 8:
		var t := k / 7.0
		var r := 2.4 * sqrt(maxf(1.0 - t * t, 0.0)) + 0.2
		rings.append(PaperMesh.oval(Vector3(x, g + t * 3.4, -4.4), Vector2(r, r * 0.75), 14))
	b.color = Color(0.4, 0.22, 0.16)
	b.loft(rings, false, true)
	# Courses of brick, soot up its face.
	b.color = Color(0.2, 0.12, 0.1)
	for k in 5:
		var t := (k + 0.5) / 6.0
		var r := 2.4 * sqrt(maxf(1.0 - t * t, 0.0)) + 0.22
		b.frustum(14, Vector2(r, r * 0.75), Vector2(r, r * 0.75), 0.04, Vector3(x, g + t * 3.4, -4.4))
	# The chimney behind it.
	b.color = Color(0.3, 0.17, 0.13)
	b.frustum(8, Vector2(0.45, 0.45), Vector2(0.35, 0.35), 7.5, Vector3(x + 1.0, g + 1.0, -6.0))
	add_child(b.build())
	# Its mouth, glowing.
	var mouth := PaperMesh.new(_rng.randi())
	var arch := PackedVector2Array()
	for k in 12:
		var a := PI * k / 11.0
		arch.append(Vector2(x + cos(a) * 0.9, g + 0.9 + sin(a) * 0.8))
	arch.append(Vector2(x - 0.9, g))
	arch.append(Vector2(x + 0.9, g))
	mouth.color = Color(1.0, 0.62, 0.28)
	mouth.polygon(arch, -2.3)   # (in front of the dome's foot)
	var glow := mouth.build(Color.WHITE, 2.0, true)
	add_child(glow)
	var heat := OmniLight3D.new()
	heat.light_color = Color(1.0, 0.55, 0.22)
	heat.light_energy = 3.0
	heat.omni_range = 9.0
	heat.position = Vector3(x, g + 1.2, -1.8)
	add_child(heat)
	heat.set_meta(&"flicker", true)
	# Smoke from the chimney.
	var smoke := CPUParticles3D.new()
	smoke.amount = 20
	smoke.lifetime = 5.0
	smoke.direction = Vector3.UP
	smoke.spread = 10.0
	smoke.gravity = Vector3(-0.4, 0.4, 0.0)
	smoke.initial_velocity_min = 0.8
	smoke.initial_velocity_max = 1.4
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.4))
	smoke.scale_amount_curve = grow
	var puff := QuadMesh.new()
	puff.size = Vector2(1.2, 1.2)
	puff.material = PaperMesh.soft_ink(Color(0.2, 0.19, 0.22, 0.3))
	smoke.mesh = puff
	smoke.position = Vector3(x + 1.0, g + 8.6, -6.0)
	add_child(smoke)
	# The grate in the floor in front of it, and the hot air rising from it.
	var grate := PaperMesh.new(_rng.randi())
	grate.color = Color(1.0, 0.5, 0.18)
	grate.box(Vector3(x, g + 0.005, 0.0), Vector3(2.0, 0.01, 1.6))
	var hot := grate.build(Color.WHITE, 1.5, true)
	add_child(hot)
	var bars := PaperMesh.new(_rng.randi())
	bars.color = Color(0.1, 0.09, 0.1)
	for k in 8:
		bars.box(Vector3(x - 0.9 + k * 0.257, g + 0.03, 0.0), Vector3(0.06, 0.05, 1.7))
	bars.box(Vector3(x, g + 0.03, -0.82), Vector3(2.1, 0.06, 0.06))
	bars.box(Vector3(x, g + 0.03, 0.82), Vector3(2.1, 0.06, 0.06))
	add_child(bars.build())
	var up := Updraft.new()
	up.kiln = true
	up.width = 2.6
	up.height = 9.0
	up.position = Vector3(x, g + 0.02, 0.0)
	add_child(up)
	Sound.place_loop(self, "kiln_fire.ogg", Vector3(x, g + 1.0, -3.0), -12.0, 10.0)


## The windmill in the yard, and the lantern-cage hoist it drives, up the
## cliff to the workshops: a beam over the cliff's edge with a pulley, the
## rope from the windmill's drum up to it and down to the cage.
func _build_windmill_and_hoist() -> void:
	windmill = Windmill.new()
	windmill.position = Vector3(WINDMILL_X, T1.z, -1.6)
	add_child(windmill)
	hoist = CageHoist.new()
	hoist.low = T1.z
	hoist.high = T2.z
	hoist.windmill = windmill
	hoist.position = Vector3(HOIST_X, T1.z, 0.0)
	add_child(hoist)
	var b := PaperMesh.new(_rng.randi())
	b.color = PaperMesh.TIMBER.lightened(0.08)
	# A gantry on T2's edge: a post and a beam reaching out over the cage.
	b.box(Vector3(T2.x + 0.3, T2.z + 1.8, -1.6), Vector3(0.22, 3.6, 0.22))
	b.box(Vector3(HOIST_X + 0.65, T2.z + 3.5, -1.0), Vector3(2.2, 0.2, 0.2))
	b.color = Scenery.WOOD
	b.frustum(10, Vector2(0.16, 0.16), Vector2(0.16, 0.16), 0.12, Vector3(HOIST_X, T2.z + 3.35, -1.0))
	add_child(b.build())
	hoist.top = T2.z + 3.3
	# The rope from the windmill's drum up to the pulley.
	var rope := PaperMesh.new(_rng.randi())
	rope.color = Color(0.5, 0.42, 0.3)
	var from := Vector3(WINDMILL_X, T1.z + windmill.hub - 0.15, -2.15)
	var to := Vector3(HOIST_X, T2.z + 3.35, -1.0)
	var mid := (from + to) * 0.5
	var length := from.distance_to(to)
	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.03, length, 0.03)
	line.mesh = box
	line.material_override = PaperMesh.material(Color(0.5, 0.42, 0.3))
	add_child(line)
	line.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, (to - from).normalized())), market.to_global(mid))


## The workshops: giant lantern frames, bare ribs of bamboo on stands, and
## sheets of lantern paper drying on lines.
func _build_workshops() -> void:
	for f: Array in [[337.0, 2.6], [343.8, 3.0], [361.5, 2.4]]:
		var x: float = f[0]
		var size: float = f[1]
		var g := ground_at(x)
		var b := PaperMesh.new(_rng.randi())
		b.color = Color(0.55, 0.45, 0.28)
		for k in 9:
			var t := (k + 0.5) / 9.0
			var r := size * 0.5 * sin(PI * t)
			b.frustum(14, Vector2(r, r * 0.8), Vector2(r, r * 0.8), 0.025, Vector3(x, g + 0.6 + t * size, -3.4))
		for k in 6:
			var a := TAU * k / 6.0
			b.box(Vector3(x + cos(a) * size * 0.25, g + 0.6 + size * 0.5, -3.4 + sin(a) * size * 0.2), Vector3(0.025, size, 0.025))
		b.color = PaperMesh.TIMBER
		b.box(Vector3(x, g + 0.3, -3.4), Vector3(0.5, 0.6, 0.5))
		# Half papered: a few panels on, the rest bare.
		b.color = Color(0.86, 0.82, 0.72)
		b.box(Vector3(x - size * 0.32, g + 0.6 + size * 0.5, -3.2), Vector3(0.02, size * 0.6, size * 0.35))
		add_child(b.build())
	# Paper drying on lines between posts.
	for d: Array in [[340.0, 343.0], [362.5, 366.0]]:
		var g := ground_at(d[0])
		var line := PaperMesh.new(_rng.randi())
		line.color = PaperMesh.TIMBER
		for x: float in [d[0], d[1]]:
			line.box(Vector3(x, g + 1.4, -2.2), Vector3(0.08, 2.8, 0.08))
		line.color = Color(0.4, 0.35, 0.28)
		line.box(Vector3((d[0] + d[1]) * 0.5, g + 2.7, -2.2), Vector3(d[1] - d[0], 0.02, 0.02))
		add_child(line.build())
		var x: float = d[0] + 0.5
		while x < d[1] - 0.4:
			var sheet := Node3D.new()
			sheet.position = Vector3(x, g + 2.69, -2.2)
			add_child(sheet)
			var s := PaperMesh.new(_rng.randi())
			s.color = Color(0.88, 0.84, 0.74) if _rng.randf() < 0.7 else Color(0.66, 0.24, 0.18)
			s.polygon(PaperMesh.tear(PackedVector2Array([Vector2(-0.3, 0.0), Vector2(0.3, 0.0), Vector2(0.3, -0.75), Vector2(-0.3, -0.75)]), 0.12, 0.02, _rng), 0.0)
			sheet.add_child(s.build())
			Scenery.windswept(sheet, 0.12, _rng)
			x += 0.75


## The gate onward to the Gilded Terraces, its doors open.
func _build_terraces_gate() -> void:
	var gx := TERRACES_GATE
	var g := T3.z
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.color = PaperMesh.TIMBER.lightened(0.12)
	for pz: float in [1.6, -2.6]:
		b.box(Vector3(gx, g + 2.9, pz), Vector3(0.4, 5.8, 0.4))
	b.box(Vector3(gx, g + 5.4, -0.5), Vector3(0.5, 0.35, 5.2))
	# Its gold-leafed doors (Hōshō's) stand open, swung back against the
	# terrace's side.
	b.color = Color(0.62, 0.5, 0.26)
	b.box(Vector3(gx - 1.95, g + 2.5, -2.55), Vector3(3.8, 5.0, 0.18))
	add_child(b.build())
	add_child(Scenery.tiled_roof(_rng, gx - 1.2, gx + 1.2, Vector2(g + 5.6, 2.4), Vector2(g + 6.8, -0.5), 3))
	add_child(Scenery.tiled_roof(_rng, gx - 1.2, gx + 1.2, Vector2(g + 5.6, -3.4), Vector2(g + 6.8, -0.5), 3, false))
	market._hang(Vector3(gx - 0.5, g + 6.05, 1.2), 1.0, 0.8)
	GateWalls.build(self, market, _rng, gx, g, -2.6, 1.6, -6.75, 5.3, Vector2(367.95, 373.05))


## A lantern cage on ropes, wound up the cliff while the windmill spins and
## let down again slowly when it stops.
class CageHoist extends AnimatableBody3D:
	var low := 10.0
	var high := 15.0
	var top := 18.3
	var windmill: Windmill
	## Up while the windmill spins (m/s), down when it does not.
	var up_speed := 1.4
	var down_speed := 0.7
	var _ropes: Array[MeshInstance3D] = []
	var _creak := 0.0

	func _ready() -> void:
		sync_to_physics = false
		process_physics_priority = -5
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, 0.2, 2.0)
		shape.shape = box
		shape.position.y = -0.1
		add_child(shape)
		# The cage: a floor of boards, bamboo bars round three sides and a
		# lantern-shaped top of ribs (a giant lantern frame, turned to use).
		var b := PaperMesh.new(93)
		b.shade_jitter = 0.2
		b.color = Scenery.WOOD.lightened(0.15)
		b.box(Vector3(0.0, -0.1, 0.0), Vector3(2.0, 0.2, 2.0))
		b.color = Color(0.55, 0.45, 0.28)
		for k in 7:
			var a := PI * (0.15 + 0.7 * k / 6.0)
			b.box(Vector3(cos(a) * -0.95, 1.1, -sin(a) * 0.95), Vector3(0.04, 2.2, 0.04))
		for y: float in [0.9, 2.2]:
			b.frustum(12, Vector2(0.98, 0.98), Vector2(0.98, 0.98), 0.04, Vector3(0.0, y, 0.0))
		b.frustum(12, Vector2(0.98, 0.98), Vector2(0.15, 0.15), 0.6, Vector3(0.0, 2.24, 0.0))
		add_child(b.build())
		var l := Scenery.lantern(RandomNumberGenerator.new(), 1.6, 0.5, 0.1)
		l.position = Vector3(0.0, 2.25, 0.0)
		add_child(l)
		for side: float in [-1.0, 1.0]:
			var rope := MeshInstance3D.new()
			var line := BoxMesh.new()
			line.size = Vector3(0.03, 1.0, 0.03)
			rope.mesh = line
			rope.material_override = PaperMesh.material(Color(0.5, 0.42, 0.3))
			rope.position = Vector3(side * 0.08, 0.0, -1.0)
			add_child(rope)
			_ropes.append(rope)

	func _physics_process(delta: float) -> void:
		var going := 0.0
		if windmill and windmill.turning():
			going = up_speed if position.y < high else 0.0
		elif position.y > low:
			going = -down_speed
		position.y = clampf(position.y + going * delta, low, high)
		constant_linear_velocity = Vector3(0.0, going, 0.0)
		_creak -= delta
		if going != 0.0 and _creak <= 0.0:
			_creak = 1.4
			Sound.play(self, &"plank_creak", -8.0)
		for rope: MeshInstance3D in _ropes:
			var length := maxf(top - position.y - 2.5, 0.1)
			rope.scale.y = length
			rope.position.y = 2.5 + length * 0.5
