class_name BackCourt
extends Node3D
## Behind Hōshō's hall (Julian: "after the Hōshō fight, going right, make
## them get out of the building and go through a gate outside to the next
## region"). Once he is beaten the gold screen at the hall's east end folds
## back (HoshoHall.open_way) onto a covered stair going down out of the hall;
## at its foot, the palace's back garden in the rain: raked gravel, an old
## pine, stone lanterns, a storehouse, the long back wall of the palace;
## at the garden's east end, the Rain Gate, a tall gate between walls, its
## doors standing open; beyond it a path goes off into fog: walking on along
## it fades to Sumi Marsh (Main._travel). Built in the market's coordinates.

## The stair down from the hall's floor, the garden, the gate, the way out.
const STAIR := Vector2(482.0, 488.0)
const HALL_Y := 24.0
const COURT_Y := 20.8
const GATE_X := 522.0
## Walking past this (local x) fades to the marsh.
const EXIT_X := 528.5

var market: LanternMarket
var _rng := RandomNumberGenerator.new()


static func ground_at(x: float) -> float:
	if x < STAIR.x:
		return HALL_Y
	if x < STAIR.y:
		return lerpf(HALL_Y, COURT_Y, (x - STAIR.x) / (STAIR.y - STAIR.x))
	return COURT_Y


func _ready() -> void:
	_rng.seed = 4848
	_build_ground()
	_build_passage()
	_build_garden()
	_build_gate()
	_build_beyond()
	market.village._add_rain_splashes(LanternMarket.SHIFT + STAIR.y, LanternMarket.SHIFT + LanternMarket.END, COURT_Y)


func _build_ground() -> void:
	# The stair (a solid slope) and the garden's ground.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for z: float in [-1.6, 1.6]:
		pts.append(Vector3(STAIR.x, HALL_Y, z))
		pts.append(Vector3(STAIR.y, COURT_Y, z))
		pts.append(Vector3(STAIR.y, COURT_Y - 8.0, z))
		pts.append(Vector3(STAIR.x, COURT_Y - 8.0, z))
	hull.points = pts
	shape.shape = hull
	body.add_child(shape)
	body.position.x = LanternMarket.SHIFT
	market.village.add_child(body)   # (always in the physics)
	market._solid(Vector3((STAIR.y + LanternMarket.END + 4.0) * 0.5, COURT_Y - 6.0, -1.5), Vector3(LanternMarket.END + 4.0 - STAIR.y, 12.0, 6.0))
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	for k in 11:
		var x0 := lerpf(STAIR.x, STAIR.y, k / 11.0)
		var x1 := lerpf(STAIR.x, STAIR.y, (k + 1) / 11.0)
		var y := lerpf(HALL_Y, COURT_Y, (k + 0.5) / 11.0)
		b.color = Color(0.32, 0.3, 0.33).darkened(_rng.randf_range(0.0, 0.2))
		b.box(Vector3((x0 + x1) * 0.5, y - 0.15, -0.6), Vector3(x1 - x0 + 0.02, 0.3, 4.6))
	# Under the stair and the garden: the dressed stone of the terrace.
	MarshKit.masonry(b, Vector3((STAIR.x + LanternMarket.END + 4.0) * 0.5, COURT_Y - 2.0, 1.9), Vector3(LanternMarket.END + 4.0 - STAIR.x, 4.0, 0.8), _rng, Color(0.34, 0.32, 0.36), false)
	market.add_child(b.build())
	# Raked gravel, in lines, a stepping-stone path across it.
	var g := PaperMesh.new(_rng.randi())
	g.shade_jitter = 0.05
	g.color = Color(0.56, 0.54, 0.52)
	g.box(Vector3((STAIR.y + LanternMarket.END) * 0.5, COURT_Y - 0.02, -1.6), Vector3(LanternMarket.END - STAIR.y, 0.04, 9.0))
	g.color = Color(0.46, 0.44, 0.43)
	for z in range(-5, 3):
		g.box(Vector3((STAIR.y + LanternMarket.END) * 0.5, COURT_Y + 0.005, z * 0.7), Vector3(LanternMarket.END - STAIR.y, 0.004, 0.06))
	var x := STAIR.y + 0.5
	while x < GATE_X + 4.0:
		g.color = Color(0.36, 0.35, 0.38).darkened(_rng.randf_range(0.0, 0.2))
		g.frustum(7, Vector2(0.4, 0.32), Vector2(0.38, 0.3), 0.06, Vector3(x, COURT_Y, _rng.randf_range(-0.2, 0.2)), _rng.randf() * TAU)
		x += _rng.randf_range(0.85, 1.1)
	market.add_child(g.build())


## The covered stair out of the hall: dark timber walls each side, a roof
## over it, a lantern; the rain falls past its open end.
func _build_passage() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	b.color = Color(0.2, 0.15, 0.13)
	b.box(Vector3((STAIR.x + STAIR.y) * 0.5, HALL_Y + 1.6, -3.2), Vector3(STAIR.y - STAIR.x + 2.0, 6.4, 0.3))
	for px: float in [STAIR.x - 1.4, STAIR.x + 2.0, STAIR.y - 1.0, STAIR.y + 0.4]:
		var py: float = ground_at(px)
		b.color = LanternMarket.LACQUER.darkened(0.25)
		b.box(Vector3(px, (py + HALL_Y + 4.2) * 0.5, 2.6), Vector3(0.24, HALL_Y + 4.2 - py, 0.24))
		b.box(Vector3(px, (py + HALL_Y + 4.2) * 0.5, -3.0), Vector3(0.24, HALL_Y + 4.2 - py, 0.24))
	b.color = Color(0.16, 0.12, 0.1)
	b.box(Vector3((STAIR.x + STAIR.y) * 0.5, HALL_Y + 4.2, -0.2), Vector3(STAIR.y - STAIR.x + 3.0, 0.25, 6.2))
	market.add_child(b.build())
	market.add_child(Scenery.tiled_roof(_rng, STAIR.x - 1.8, STAIR.y + 1.0, Vector2(HALL_Y + 4.4, 3.2), Vector2(HALL_Y + 5.6, -0.2), 3))
	market.add_child(Scenery.tiled_roof(_rng, STAIR.x - 1.8, STAIR.y + 1.0, Vector2(HALL_Y + 4.4, -3.6), Vector2(HALL_Y + 5.6, -0.2), 3))
	market._hang(Vector3(STAIR.y - 0.8, HALL_Y + 3.9, -0.4), 1.0, 0.3)
	market._light(Vector3(STAIR.y - 0.8, HALL_Y + 3.0, 0.4), market.village.lantern_energy * 0.8, 6.0)


## The palace's back garden: its long back wall, an old pine, stone
## lanterns, a storehouse in the corner.
func _build_garden() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = Color(0.58, 0.55, 0.5)
	b.box(Vector3((STAIR.y + GATE_X) * 0.5, COURT_Y + 1.8, -6.0), Vector3(GATE_X - STAIR.y + 1.0, 3.6, 0.5))
	b.color = Color(0.2, 0.18, 0.22)
	b.box(Vector3((STAIR.y + GATE_X) * 0.5, COURT_Y + 0.3, -5.9), Vector3(GATE_X - STAIR.y + 1.0, 0.6, 0.6))
	# The storehouse: plaster, a tiled base, a small barred window.
	var sx := 510.0
	b.color = Color(0.68, 0.65, 0.6)
	b.box(Vector3(sx, COURT_Y + 2.0, -4.4), Vector3(4.0, 4.0, 2.6))
	b.color = Color(0.22, 0.22, 0.26)
	b.box(Vector3(sx, COURT_Y + 0.4, -4.4), Vector3(4.05, 0.8, 2.65))
	b.color = Color(0.1, 0.09, 0.1)
	b.box(Vector3(sx + 0.8, COURT_Y + 2.8, -3.08), Vector3(0.7, 0.5, 0.04))
	market.add_child(b.build())
	market.add_child(Scenery.tiled_roof(_rng, sx - 2.3, sx + 2.3, Vector2(COURT_Y + 4.1, -2.9), Vector2(COURT_Y + 5.0, -4.4), 3))
	market.add_child(Scenery.tiled_roof(_rng, sx - 2.3, sx + 2.3, Vector2(COURT_Y + 4.1, -5.9), Vector2(COURT_Y + 5.0, -4.4), 3))
	market.add_child(Scenery.tiled_roof(_rng, STAIR.y - 0.5, GATE_X + 0.5, Vector2(COURT_Y + 3.7, -5.6), Vector2(COURT_Y + 4.2, -6.2), 2))
	# An old pine, bent, its pads of needles.
	var p := PaperMesh.new(_rng.randi())
	p.shade_jitter = 0.14
	p.color = Color(0.2, 0.25, 0.21)
	Scenery.pine(p, Vector2(497.0, COURT_Y), 5.5, -3.6, _rng)
	market.add_child(p.build())
	for lx: float in [492.0, 503.0, 516.0]:
		var lantern := MarshKit.stone_lantern(_rng, true, 1.1)
		lantern.position = Vector3(lx, COURT_Y + 0.5, -2.4)
		market.add_child(lantern)
		market._light(Vector3(lx, COURT_Y + 1.6, -2.0), 0.8, 4.0)


## The Rain Gate: two thick posts, a tie beam, a tiled roof, its two door
## leaves standing open (swung back east), walls running back and forward
## from it (every gate has them: GateWalls).
func _build_gate() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.1
	var h := 5.6
	for z: float in [-2.4, 2.4]:
		b.color = Color(0.24, 0.18, 0.15)
		b.box(Vector3(GATE_X, COURT_Y + h * 0.5, z), Vector3(0.45, h, 0.45))
		b.color = Color(0.18, 0.18, 0.2)
		b.box(Vector3(GATE_X, COURT_Y + 0.3, z), Vector3(0.6, 0.6, 0.6))
	b.color = Color(0.22, 0.16, 0.14)
	b.box(Vector3(GATE_X, COURT_Y + h - 0.5, 0.0), Vector3(0.35, 0.4, 5.4))
	# The door, open: one great leaf swung back against the wall beyond (on
	# the far side, so it never hides him as he walks through).
	for side: float in [-1.0]:
		b.color = Color(0.26, 0.2, 0.16)
		b.box(Vector3(GATE_X + 1.15, COURT_Y + (h - 1.0) * 0.5, side * 2.15), Vector3(2.1, h - 1.0, 0.16))
		b.color = Color(0.12, 0.12, 0.13)
		for y: float in [0.8, 2.4, 4.0]:
			b.box(Vector3(GATE_X + 1.15, COURT_Y + y, side * 2.06), Vector3(2.1, 0.12, 0.04))
	market.add_child(b.build())
	market.add_child(Scenery.tiled_roof(_rng, GATE_X - 1.6, GATE_X + 1.6, Vector2(COURT_Y + h + 0.1, 3.4), Vector2(COURT_Y + h + 1.4, 0.0), 3))
	market.add_child(Scenery.tiled_roof(_rng, GATE_X - 1.6, GATE_X + 1.6, Vector2(COURT_Y + h + 0.1, -3.4), Vector2(COURT_Y + h + 1.4, 0.0), 3))
	GateWalls.build(market, market, _rng, GATE_X, COURT_Y, -2.6, 2.6, -6.4, 4.4)
	market._hang(Vector3(GATE_X - 0.4, COURT_Y + h - 0.75, 1.4), 0.9, 0.2)
	market._light(Vector3(GATE_X - 0.8, COURT_Y + h - 1.4, 0.6), market.village.lantern_energy * 0.7, 6.0)


## Past the gate: the path going off east into fog and the dark of the
## marsh beyond (a veil of mist across it, deepening).
func _build_beyond() -> void:
	var m := PaperMesh.new(1)
	var tint := Color(0.13, 0.15, 0.2)
	for k in 4:
		var x := GATE_X + 2.5 + k * 1.3
		m.fade_quad(Vector3(x, COURT_Y - 4.0, -9.0), Vector3(x, COURT_Y - 4.0, 5.0), Vector3(x, COURT_Y + 12.0, 5.0), Vector3(x, COURT_Y + 12.0, -9.0),
				Color(tint, 0.2 + k * 0.22), Color(tint, 0.12 + k * 0.2))
	market.add_child(m.build_veil())
