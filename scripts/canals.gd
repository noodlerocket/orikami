class_name Canals
extends Node3D
## The Canals (under areas 3 and 4 of the expanded village,
## docs/village_map.png): the old waterways under the street, seen as a
## cut-away, as if the front of the ground had been sliced off.
##  - the DRAIN PIPE runs west under Market Street and Well Square to a low
##    chamber whose grate opens into Well Square (cut it from below: a
##    shortcut back here);
##  - a CRAWLSPACE where the pipe's ceiling has come down: duck through;
##  - the CANAL HALL under the Fallen Street and the river: stone walkways
##    and boardwalks over shallow dark water (wading slows him), SLUICES of
##    river water pouring through grates in the vault that press him down
##    (water weighs him down; a dash goes straight through), DEEP WATER that
##    carries him off (back to the last shrine), and a shaft to climb out by
##    at the east end, past the gatehouse.
## Everything is placed with the Village constants (PIPE, CANAL, SHAFT...).

const BACK_Z := -2.8
const FRONT_Z := 1.5
## The top of the shallow water's floor (he stands ankle-deep on it).
const FLOOR := -6.8
## [left x, right x, top, what it is: "stone" ledge or "boards" on posts]
const WALKWAYS := [
	[54.0, 66.5, -4.6, "stone"], [69.5, 86.0, -4.2, "boards"], [90.0, 99.0, -5.0, "stone"],
	[101.0, 111.0, -4.0, "boards"], [113.0, 116.5, -5.6, "stone"], [123.0, 136.8, -4.8, "stone"]]
## River water pouring down through grates in the vault, at these x.
const SLUICES := [88.0, 106.0]
## The deep water (no floor): between these x.
const DEEP := Vector2(116.5, 123.0)
## How far down the deep water's shaft is drawn.
const DEEP_BOTTOM := -11.0
## The old timber tower by the river's west bank (to wall-jump up between).
const TOWER := Vector2(77.0, 77.6)
## The crawlspace in the drain pipe, and how low its ceiling comes.
const CRAWL := Vector2(47.5, 51.5)
const CRAWL_TOP := -3.62

@export_group("Water")
## How hard a sluice presses him down (metres per second, per second).
@export var sluice_press := 70.0
## Half the width of a sluice's falling water (metres).
@export var sluice_half := 0.7
## Falling into water faster than this (m/s) makes a big splash.
@export var big_splash_from := 6.0
## Seconds between the little splashes of his feet while he wades.
@export var wade_splash_every := 0.28

var village: Village
## The grate into Well Square has been cut open (a shortcut).
var grate_open := false

var _rng := RandomNumberGenerator.new()
var _ronin: Ronin
var _last_y := 0.0
var _wade_clock := 0.0
var _spray_clock := 0.0
var _grate: Node3D
var _grate_solid: StaticBody3D
var _grate_hits := 0
var _chamber_front: MeshInstance3D
var _carried_off := false
var _hushed := false
var _chamber_seen := 0.0


var _was_wading := false


func _ready() -> void:
	# Waxed (the Wax Coat), he floats in the deep water.
	Ronin.float_surface(self, DEEP.x, DEEP.y, Village.CANAL_WATER)
	# Out on the deep water, cranes on a floating shutter: only swum to.
	var cache := SwimCache.new()
	cache.id = "canals_deep_swim"
	cache.count = 5
	cache.position = Vector3((DEEP.x + DEEP.y) * 0.5, Village.CANAL_WATER, 0.0)
	add_child(cache)
	process_physics_priority = -5  # before the Ronin moves: the water pushes him
	_rng.seed = 5501
	_build_solids()
	_build_tower()
	_build_back_wall()
	_build_ceiling()
	_build_walkways()
	_build_water()
	_build_front()
	_build_pipe_details()
	_build_chamber()
	for x: float in SLUICES:
		_build_sluice(x)
	_build_drips()
	_build_lights()
	_build_shaft()
	# Water dripping and trickling all through the tunnels, and the roar of
	# each sluice.
	for x: float in [10.0, 34.0, 60.0, 84.0, 110.0, 130.0]:
		Sound.place_loop(self, "canal_drips.ogg", Vector3(x, Village.PIPE_FLOOR + 1.0, -1.0), -12.0, 6.0)
	for x: float in SLUICES:
		Sound.place_loop(self, "sluice_pour.ogg", Vector3(x, -4.0, 0.0), -6.0, 5.0)


func ceiling_at(x: float) -> float:
	if x < Village.CHAMBER.y:
		return -Village.CHAMBER_SLAB
	if x < Village.CANAL.x:
		return Village.PIPE_TOP
	if x < Village.FALL_LEFT:
		return -1.5
	if x < Village.FALL_RIGHT:
		return 0.0
	if x < Village.RIVER.y:
		return -2.2
	if x < Village.SHAFT.x:
		return -1.5
	return 0.0


# --- What he stands on and bumps into --------------------------------------------

func _build_solids() -> void:
	var v := village
	# The pipe's floor (and the chamber's steps up to the grate).
	_box(Vector2(Village.CHAMBER.y, Village.CANAL.x), Vector2(-9.0, Village.PIPE_FLOOR))
	for step: Array in [[-2.6, -1.5, -3.85], [-3.7, -2.6, -3.1], [Village.CHAMBER.x, -3.7, -2.0]]:
		_box(Vector2(step[0], step[1]), Vector2(-9.0, step[2]))
	# The crawlspace: the pipe's roof has slumped down here.
	_box(CRAWL, Vector2(CRAWL_TOP, Village.PIPE_TOP + 0.05))
	# Walkways: solid piers down to the water's floor.
	for w: Array in WALKWAYS:
		_box(Vector2(w[0], w[1]), Vector2(FLOOR, w[2]))
	# The shallow water's floor, except over the deep water.
	_box(Vector2(Village.CANAL.x, DEEP.x), Vector2(-10.0, FLOOR))
	_box(Vector2(DEEP.y, Village.CANAL.y), Vector2(-10.0, FLOOR))
	# Under the deep water: far down, out of reach (he is carried off first).
	_box(DEEP, Vector2(-14.0, -12.5))
	# The river's bed is the vault over the canal.
	_box(Village.RIVER, Vector2(-2.2, -1.45))
	# Climbable faces: the end of Market Street over the hole, the west bank
	# of the river (with an old timber tower beside it to jump between), and
	# both sides of the shaft out at the east end.
	_climb(Vector2(Village.FALL_LEFT - 0.05, Village.FALL_LEFT + 0.03), Vector2(-1.5, 0.0))
	_climb(Vector2(Village.FALL_RIGHT - 0.03, Village.FALL_RIGHT + 0.05), Vector2(-2.2, 0.0))
	_climb(TOWER, Vector2(-4.2, -0.5))
	_climb(Vector2(Village.SHAFT.x - 0.05, Village.SHAFT.x + 0.03), Vector2(-1.5, 0.0))
	_climb(Vector2(Village.CANAL.y - 0.03, Village.CANAL.y + 0.05), Vector2(FLOOR, 0.0))
	# Crates stacked under the end of Market Street: a way back up.
	_box(Vector2(63.0, 64.0), Vector2(-4.6, -3.7))
	_box(Vector2(63.2, 63.9), Vector2(-3.7, -3.05))
	# The grate in Well Square's street, until it is cut open from below.
	_grate_solid = _box(Vector2(Village.GRATE_X - Village.GRATE_WIDTH * 0.5, Village.GRATE_X + Village.GRATE_WIDTH * 0.5),
			Vector2(-Village.CHAMBER_SLAB, 0.0))


func _box(span: Vector2, heights: Vector2) -> StaticBody3D:
	return village._add_solid(Vector3((span.x + span.y) * 0.5, (heights.x + heights.y) * 0.5, -0.75),
			Vector3(span.y - span.x, heights.y - heights.x, 4.5))


func _climb(span: Vector2, heights: Vector2) -> void:
	var wall := _box(span, heights)
	wall.set_meta(&"climbable", true)


# --- How it looks -----------------------------------------------------------------

## The old timber tower beside the river's west bank: four weathered posts
## standing on the boardwalk, boards nailed across its face, an X brace, a
## cap. It is solid and climbable (before, only its collision was there: an
## invisible wall).
func _build_tower() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	var bottom := -4.2
	var top := -0.5
	b.color = PaperMesh.TIMBER
	for px: float in [TOWER.x + 0.07, TOWER.y - 0.07]:
		for pz: float in [0.9, -0.9]:
			b.box(Vector3(px, (bottom + top) * 0.5, pz), Vector3(0.14, top - bottom, 0.14))
	# Boards across the front and back, uneven, a few missing.
	var y := bottom + 0.25
	while y < top - 0.1:
		for pz: float in [0.98, -0.98]:
			if _rng.randf() < 0.85:
				b.color = Scenery.WOOD.darkened(_rng.randf_range(0.15, 0.4))
				b.box(Vector3((TOWER.x + TOWER.y) * 0.5 + _rng.randf_range(-0.02, 0.02), y, pz),
						Vector3(TOWER.y - TOWER.x + 0.1, 0.12, 0.04))
		y += _rng.randf_range(0.42, 0.55)
	# The sides, planked full height so it reads as solid from the side.
	b.color = Scenery.WOOD.darkened(0.45)
	for px: float in [TOWER.x + 0.02, TOWER.y - 0.02]:
		b.box(Vector3(px, (bottom + top) * 0.5, 0.0), Vector3(0.04, top - bottom - 0.1, 1.8))
	# A cap of boards and a few nails' rust streaks.
	b.color = PaperMesh.TIMBER.lightened(0.05)
	b.box(Vector3((TOWER.x + TOWER.y) * 0.5, top + 0.05, 0.0), Vector3(TOWER.y - TOWER.x + 0.3, 0.1, 2.1))
	b.color = Color(0.2, 0.12, 0.08)
	for k in 5:
		var sx := _rng.randf_range(TOWER.x + 0.1, TOWER.y - 0.1)
		var sy := _rng.randf_range(bottom + 0.4, top - 0.4)
		b.stroke(Vector2(sx, sy), Vector2(sx + 0.01, sy - _rng.randf_range(0.15, 0.3)), 0.025, 0.005, 1.01)
	add_child(b.build())


const STONE := Color(0.13, 0.14, 0.21)
const STONE_JOINT := Color(0.06, 0.065, 0.11)
const MOSS_DARK := Color(0.14, 0.18, 0.12)
const SLIME := Color(0.1, 0.13, 0.12)


## The back wall of the tunnels: courses of dark stone blocks, slick near
## the water, moss along the waterline, ink-dark streaks where water runs
## down from the vault. In the open hole it reaches up to the street.
func _build_back_wall() -> void:
	var x := Village.CHAMBER.x
	while x < Village.CANAL.y - 0.01:
		var x1 := minf(x + 4.0, Village.CANAL.y)
		var mid := (x + x1) * 0.5
		var bottom := Village.PIPE_FLOOR - 0.6 if mid < Village.CANAL.x else CANAL_WATER_LINE - 0.5
		var top := ceiling_at(mid) + 0.01
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.07
		b.color = STONE
		b.quad(Vector3(x, bottom, BACK_Z), Vector3(x1, bottom, BACK_Z), Vector3(x1, top, BACK_Z), Vector3(x, top, BACK_Z), Vector3.BACK)
		# Courses of blocks: a dark joint along each course, staggered joints
		# up between the blocks, some blocks a little paler or darker.
		var course := 0.42
		var y := bottom
		var row := 0
		while y < top - 0.05:
			var y1 := minf(y + course, top)
			b.color = STONE_JOINT
			b.rect(Vector2(mid, y1), Vector2(x1 - x, 0.035), BACK_Z + 0.01)
			var bx := x + (0.0 if row % 2 == 0 else 0.35)
			while bx < x1 - 0.05:
				var bw := _rng.randf_range(0.6, 0.95)
				if bx > x + 0.02:
					b.color = STONE_JOINT
					b.rect(Vector2(bx, (y + y1) * 0.5), Vector2(0.03, y1 - y), BACK_Z + 0.011)
				if _rng.randf() < 0.22:
					b.color = STONE * _rng.randf_range(0.78, 1.25)
					b.rect(Vector2(minf(bx + bw * 0.5, x1 - 0.1), (y + y1) * 0.5), Vector2(minf(bw - 0.05, x1 - bx), y1 - y - 0.05), BACK_Z + 0.006)
				bx += bw
			y = y1
			row += 1
		# Water running down from the vault: long dark streaks.
		b.color = Color(0.05, 0.055, 0.1)
		for k in _rng.randi_range(1, 3):
			var sx := _rng.randf_range(x + 0.3, x1 - 0.3)
			var length := _rng.randf_range(0.8, minf(3.0, top - bottom - 0.3))
			b.stroke(Vector2(sx, top - 0.05), Vector2(sx + _rng.randf_range(-0.04, 0.04), top - length), 0.09, 0.015, BACK_Z + 0.015)
		# Moss and slime along the waterline (canals) or the floor (pipe).
		var line := Village.PIPE_FLOOR if mid < Village.CANAL.x else CANAL_WATER_LINE
		b.color = MOSS_DARK
		var mx := x + _rng.randf_range(0.1, 0.6)
		while mx < x1 - 0.2:
			b.ellipse(Vector2(mx, line + _rng.randf_range(0.05, 0.25)), Vector2(_rng.randf_range(0.25, 0.6), _rng.randf_range(0.08, 0.2)), 8, BACK_Z + 0.02, 0.25)
			mx += _rng.randf_range(0.4, 1.1)
		b.color = SLIME
		b.rect(Vector2(mid, line + 0.06), Vector2(x1 - x, 0.12), BACK_Z + 0.018)
		var wall := b.build()
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(wall)
		x = x1
	# Stone piers standing against the back wall, holding up the vault, and
	# arched ribs between them (the canal hall only; not in the open hole).
	var px := Village.CANAL.x + 3.5
	while px < Village.CANAL.y - 1.0:
		if px > Village.FALL_LEFT - 0.8 and px < Village.FALL_RIGHT + 0.8:
			px += 6.5
			continue
		_pier(px)
		px += 6.5


const CANAL_WATER_LINE := Village.CANAL_WATER


func _pier(x: float) -> void:
	var top := ceiling_at(x)
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = STONE.lightened(0.05)
	b.box(Vector3(x, (FLOOR - 0.4 + top) * 0.5, BACK_Z + 0.25), Vector3(0.7, top - FLOOR + 0.4, 0.5))
	b.color = STONE_JOINT
	var y := FLOOR
	while y < top - 0.3:
		y += _rng.randf_range(0.45, 0.6)
		b.rect(Vector2(x, y), Vector2(0.72, 0.035), BACK_Z + 0.505)
	# A capital under the vault, and moss at its foot.
	b.color = STONE.lightened(0.1)
	b.box(Vector3(x, top - 0.12, BACK_Z + 0.3), Vector3(0.95, 0.22, 0.62))
	b.color = MOSS_DARK
	b.ellipse(Vector2(x, CANAL_WATER_LINE + 0.15), Vector2(0.4, 0.14), 8, BACK_Z + 0.51, 0.2)
	add_child(b.build())


## The underside of the street: heavy timber beams across the tunnels.
func _build_ceiling() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.2
	b.color = PaperMesh.TIMBER
	var x := Village.CHAMBER.y + 0.8
	while x < Village.CANAL.y - 0.4:
		if not Village.is_hole(x) and not (x > CRAWL.x - 0.3 and x < CRAWL.y + 0.3):
			var top := ceiling_at(x)
			b.box(Vector3(x, top - 0.11, (BACK_Z + FRONT_Z) * 0.5), Vector3(0.22, 0.22, FRONT_Z - BACK_Z))
		x += 2.6 if x < Village.CANAL.x else 2.2
	add_child(b.build())
	# Under the river the vault is stone, with a seam of water seeping in.
	var vault := PaperMesh.new(_rng.randi())
	vault.color = STONE.darkened(0.15)
	vault.quad(Vector3(Village.RIVER.x, -2.2, BACK_Z), Vector3(Village.RIVER.y, -2.2, BACK_Z),
			Vector3(Village.RIVER.y, -2.2, FRONT_Z), Vector3(Village.RIVER.x, -2.2, FRONT_Z), Vector3.DOWN)
	vault.color = STONE.darkened(0.3)
	var vx := Village.RIVER.x + 0.6
	while vx < Village.RIVER.y:
		vault.box(Vector3(vx, -2.24, (BACK_Z + FRONT_Z) * 0.5), Vector3(0.12, 0.08, FRONT_Z - BACK_Z))
		vx += 1.1
	# The vault's cut face at the front: a thick band of stone.
	vault.color = STONE
	vault.rect(Vector2((Village.RIVER.x + Village.RIVER.y) * 0.5, -1.82), Vector2(Village.RIVER.y - Village.RIVER.x, 0.76), FRONT_Z + 0.02)
	# The river's west bank (the street's broken end over the hole): its
	# front is the stone of the embankment, all the way down to the vault.
	vault.rect(Vector2((Village.FALL_RIGHT + Village.RIVER.x) * 0.5, -1.1), Vector2(Village.RIVER.x - Village.FALL_RIGHT, 2.2), FRONT_Z + 0.25)
	vault.color = STONE_JOINT
	var by := -0.38
	while by > -2.2:
		vault.rect(Vector2((Village.FALL_RIGHT + Village.RIVER.x) * 0.5, by), Vector2(Village.RIVER.x - Village.FALL_RIGHT, 0.035), FRONT_Z + 0.26)
		by -= 0.4
	vault.rect(Vector2(Village.FALL_RIGHT + 0.95, -1.1), Vector2(0.035, 2.2), FRONT_Z + 0.26)
	var jx := Village.RIVER.x + 0.5
	while jx < Village.RIVER.y:
		vault.rect(Vector2(jx, -1.82), Vector2(0.04, 0.76), FRONT_Z + 0.03)
		jx += _rng.randf_range(0.7, 1.0)
	vault.rect(Vector2((Village.RIVER.x + Village.RIVER.y) * 0.5, -1.8), Vector2(Village.RIVER.y - Village.RIVER.x, 0.035), FRONT_Z + 0.031)
	add_child(vault.build())


## The walkways: old stone ledges, and boardwalks of planks on posts.
func _build_walkways() -> void:
	for w: Array in WALKWAYS:
		var left: float = w[0]
		var right: float = w[1]
		var top: float = w[2]
		var b := PaperMesh.new(_rng.randi())
		b.shade_jitter = 0.14
		if w[3] == "stone":
			b.color = STONE.lightened(0.08)
			b.box(Vector3((left + right) * 0.5, (top + FLOOR - 0.3) * 0.5, (BACK_Z + 1.25) * 0.5),
					Vector3(right - left, top - FLOOR + 0.3, 1.25 - BACK_Z))
			# A worn coping along the front edge, and joints.
			b.color = STONE.lightened(0.2)
			b.box(Vector3((left + right) * 0.5, top - 0.06, 1.18), Vector3(right - left + 0.04, 0.12, 0.2))
			b.color = STONE_JOINT
			var jx := left + _rng.randf_range(0.6, 1.2)
			while jx < right - 0.3:
				b.rect(Vector2(jx, (top + FLOOR) * 0.5), Vector2(0.035, top - FLOOR), 1.255)
				jx += _rng.randf_range(0.8, 1.4)
			var jy := top - 0.45
			while jy > FLOOR:
				b.rect(Vector2((left + right) * 0.5, jy), Vector2(right - left, 0.03), 1.256)
				jy -= 0.42
			b.color = MOSS_DARK
			b.rect(Vector2((left + right) * 0.5, CANAL_WATER_LINE + 0.1), Vector2(right - left, 0.16), 1.258)
		else:
			# Planks along the top on two stringers, posts down into the water,
			# cross braces between them.
			b.color = Scenery.WOOD.darkened(0.2)
			var px := left
			while px < right - 0.01:
				var px1 := minf(px + _rng.randf_range(0.45, 0.7), right)
				b.box(Vector3((px + px1) * 0.5, top - 0.08, (BACK_Z + 1.2) * 0.5),
						Vector3(px1 - px - 0.03, 0.12 + _rng.randf_range(-0.02, 0.02), 1.2 - BACK_Z - 0.1))
				px = px1
			b.color = PaperMesh.TIMBER
			for sz: float in [1.05, -0.4, BACK_Z + 0.2]:
				b.box(Vector3((left + right) * 0.5, top - 0.25, sz), Vector3(right - left, 0.16, 0.14))
			var post := left + 0.3
			while post < right:
				for pz: float in [1.05, BACK_Z + 0.2]:
					b.box(Vector3(post, (top - 0.3 + FLOOR - 0.4) * 0.5, pz), Vector3(0.16, top - 0.3 - FLOOR + 0.4, 0.16))
				if post + 2.2 < right:
					b.extrude(PackedVector2Array([Vector2(post + 0.08, top - 0.4), Vector2(post + 0.2, top - 0.4),
							Vector2(post + 2.1, CANAL_WATER_LINE + 0.3), Vector2(post + 1.98, CANAL_WATER_LINE + 0.3)]), 1.0, 1.1)
				post += 2.4
			# Dark water-stain on the posts where the water reaches.
			b.color = SLIME
			post = left + 0.3
			while post < right:
				b.box(Vector3(post, CANAL_WATER_LINE + 0.15, 1.05), Vector3(0.18, 0.3, 0.18))
				post += 2.4
		var piece := b.build()
		add_child(piece)
	# The crates stacked under the end of Market Street.
	var crate := Scenery.crate(_rng, 1.0)
	crate.position = Vector3(63.5, -4.6, -0.2)
	add_child(crate)
	var small := Scenery.crate(_rng, 0.7)
	small.position = Vector3(63.55, -3.7, 0.0)
	small.rotation.y = 0.3
	add_child(small)


func _build_water() -> void:
	WaterFx.surface(self, Village.CANAL.x, Village.CANAL.y, Village.CANAL_WATER, BACK_Z, FRONT_Z)
	# The deep water: darker, with a slow swirl of pale flecks over it.
	var deep := PaperMesh.new(1)
	deep.shade_jitter = 0.0
	deep.texture_scale = 0.0
	deep.color = Color(0.0, 0.0, 0.02, 0.55)
	deep.quad(Vector3(DEEP.x, Village.CANAL_WATER + 0.005, BACK_Z), Vector3(DEEP.y, Village.CANAL_WATER + 0.005, BACK_Z),
			Vector3(DEEP.y, Village.CANAL_WATER + 0.005, FRONT_Z), Vector3(DEEP.x, Village.CANAL_WATER + 0.005, FRONT_Z), Vector3.UP)
	var dark := deep.build()
	var dark_look := dark.material_override as StandardMaterial3D
	dark_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dark)
	# The water runs east, slowly: pale flecks of paper drifting on it.
	var flecks := CPUParticles3D.new()
	flecks.amount = 70
	flecks.lifetime = 14.0
	flecks.preprocess = 14.0
	flecks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	flecks.emission_box_extents = Vector3((Village.CANAL.y - Village.CANAL.x) * 0.5, 0.0, (FRONT_Z - BACK_Z) * 0.45)
	flecks.direction = Vector3(1.0, 0.0, 0.0)
	flecks.spread = 6.0
	flecks.gravity = Vector3.ZERO
	flecks.initial_velocity_min = 0.25
	flecks.initial_velocity_max = 0.5
	flecks.angle_max = 360.0
	var fleck := QuadMesh.new()
	fleck.size = Vector2(0.08, 0.05)
	fleck.orientation = PlaneMesh.FACE_Y
	var fleck_look := StandardMaterial3D.new()
	fleck_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fleck_look.albedo_color = Color(0.5, 0.52, 0.6, 0.5)
	fleck_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fleck.material = fleck_look
	flecks.mesh = fleck
	flecks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flecks.position = Vector3((Village.CANAL.x + Village.CANAL.y) * 0.5, Village.CANAL_WATER + 0.01, (BACK_Z + FRONT_Z) * 0.5)
	add_child(flecks)
	# A thin trickle along the drain pipe's floor.
	var trickle := PaperMesh.new(2)
	trickle.shade_jitter = 0.0
	trickle.texture_scale = 0.0
	trickle.color = Color(0.05, 0.06, 0.1)
	trickle.quad(Vector3(Village.CHAMBER.y, Village.PIPE_FLOOR - 0.01, -0.9), Vector3(Village.CANAL.x, Village.PIPE_FLOOR - 0.01, -0.9),
			Vector3(Village.CANAL.x, Village.PIPE_FLOOR - 0.01, 0.3), Vector3(Village.CHAMBER.y, Village.PIPE_FLOOR - 0.01, 0.3), Vector3.UP)
	var line := trickle.build()
	(line.material_override as StandardMaterial3D).roughness = 0.1
	(line.material_override as StandardMaterial3D).metallic_specular = 0.9
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line)


## The cut face of the ground at the front, below the tunnels: torn sheets
## stepping down toward the camera, like the street's front edge, and a
## dark foreground strip with rocks lower down (seen only from below).
func _build_front() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.04
	for span: Array in [[Village.CHAMBER.x, Village.CANAL.x, Village.PIPE_FLOOR], [Village.CANAL.x, DEEP.x, Village.CANAL_WATER - 0.04],
			[DEEP.y, Village.CANAL.y, Village.CANAL_WATER - 0.04], [DEEP.x, DEEP.y, DEEP_BOTTOM]]:
		var left: float = span[0]
		var right: float = span[1]
		var top: float = span[2]
		for layer: Array in [[0.0, Color(0.15, 0.16, 0.25), Color(0.32, 0.35, 0.48)], [0.32, Color(0.085, 0.09, 0.16), Color(0.18, 0.2, 0.3)],
				[0.85, Color(0.05, 0.055, 0.1), Color(0.11, 0.12, 0.2)]]:
			var line := PackedVector2Array()
			var x := left
			while x < right:
				line.append(Vector2(x, top - layer[0] + _rng.randf_range(-0.08, 0.05)))
				x += _rng.randf_range(0.6, 1.8)
			line.append(Vector2(right, top - layer[0]))
			var outline := PaperMesh.tear(line, 0.25, 0.02, _rng, false)
			outline.append(Vector2(right, -16.0))
			outline.append(Vector2(left, -16.0))
			b.color = layer[1]
			b.torn_sheet(outline, FRONT_Z + 0.05 + layer[0] * 0.2, layer[2], 0.03)
	var cut := b.build()
	cut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cut)
	_build_deep_shaft()
	# Dark foreground below, framing the bottom of the view underground.
	var near := PaperMesh.new(_rng.randi())
	near.shade_jitter = 0.0
	near.texture_scale = 0.3
	for layer: Array in [[3.1, -8.1, Color(0.03, 0.035, 0.08), Color(0.1, 0.12, 0.22)], [3.9, -8.4, Color(0.015, 0.018, 0.045), Color(0.06, 0.075, 0.15)]]:
		var line := PackedVector2Array()
		var x := Village.CHAMBER.x - 14.0
		while x < Village.CANAL.y + 14.0:
			var ground: float = layer[1] + (2.2 if x < Village.CANAL.x else 0.0)
			line.append(Vector2(x, ground + _rng.randf_range(-0.2, 0.2)))
			x += _rng.randf_range(0.8, 2.2)
		var outline := PaperMesh.tear(line, 0.3, 0.05, _rng, false)
		outline.append(Vector2(Village.CANAL.y + 14.0, -24.0))
		outline.append(Vector2(Village.CHAMBER.x - 14.0, -24.0))
		near.color = layer[2]
		near.torn_sheet(outline, layer[0], layer[3], 0.03)
	var dark := near.build(Color.WHITE, 0.0, true)
	(dark.material_override as StandardMaterial3D).disable_fog = true
	dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dark)


## The deep water seen in the cut-away: where the canal's floor falls away,
## the cut front of the ground breaks off (its torn edges on either side),
## and the water below the surface fades quickly into black: a pit, not one
## more puddle. (A first try with stone walls inside it, a pale waterline and
## bubbles was "too much": Julian.)
func _build_deep_shaft() -> void:
	var w := PaperMesh.new(3)
	w.shade_jitter = 0.0
	w.texture_scale = 0.0
	var dark := Color(0.0, 0.0, 0.015)
	w.fade_quad(Vector3(DEEP.x, Village.CANAL_WATER, FRONT_Z - 0.02), Vector3(DEEP.y, Village.CANAL_WATER, FRONT_Z - 0.02),
			Vector3(DEEP.y, Village.CANAL_WATER - 1.6, FRONT_Z - 0.02), Vector3(DEEP.x, Village.CANAL_WATER - 1.6, FRONT_Z - 0.02),
			Color(0.02, 0.035, 0.08, 0.72), Color(dark.r, dark.g, dark.b, 1.0))
	w.fade_quad(Vector3(DEEP.x, Village.CANAL_WATER - 1.6, FRONT_Z - 0.02), Vector3(DEEP.y, Village.CANAL_WATER - 1.6, FRONT_Z - 0.02),
			Vector3(DEEP.y, DEEP_BOTTOM - 0.5, FRONT_Z - 0.02), Vector3(DEEP.x, DEEP_BOTTOM - 0.5, FRONT_Z - 0.02),
			Color(dark.r, dark.g, dark.b, 1.0), Color(dark.r, dark.g, dark.b, 1.0))
	var water := w.build_veil()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


## The pipe's floor: worn flagstones across its whole depth, from the back
## wall to the cut front, laid in rows, a low lip of kerb along the front,
## with the trickle running in a shallow channel down the middle. (It used to
## be only the trickle, with darkness either side: Julian, "too thin".)
func _build_pipe_floor() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	var y := Village.PIPE_FLOOR
	var x := Village.CHAMBER.y
	var row_z := [BACK_Z, -1.6, -0.95, 0.35, 1.0, FRONT_Z + 0.02]
	while x < Village.CANAL.x - 0.01:
		var x1 := minf(x + _rng.randf_range(0.5, 0.8), Village.CANAL.x)
		for r in row_z.size() - 1:
			var z0: float = row_z[r]
			var z1: float = row_z[r + 1]
			if r == 2:
				# The channel: a little lower, darker, under the trickle.
				b.color = STONE.darkened(0.35)
				b.box(Vector3((x + x1) * 0.5, y - 0.04, (z0 + z1) * 0.5), Vector3(x1 - x, 0.04, z1 - z0))
				continue
			b.color = STONE.lightened(0.08).darkened(_rng.randf_range(0.0, 0.18))
			var off := _rng.randf_range(-0.1, 0.1) if r % 2 == 1 else 0.0
			b.box(Vector3((x + x1) * 0.5 + off * 0.0, y - 0.06, (z0 + z1) * 0.5), Vector3(x1 - x - 0.03, 0.12, z1 - z0 - 0.03))
		x = x1
	# The kerb along the front edge, and the joints showing dark between.
	b.color = STONE.lightened(0.14)
	b.box(Vector3((Village.CHAMBER.y + Village.CANAL.x) * 0.5, y - 0.1, FRONT_Z - 0.1), Vector3(Village.CANAL.x - Village.CHAMBER.y, 0.2, 0.2))
	b.color = STONE_JOINT
	b.box(Vector3((Village.CHAMBER.y + Village.CANAL.x) * 0.5, y - 0.2, (BACK_Z + FRONT_Z) * 0.5), Vector3(Village.CANAL.x - Village.CHAMBER.y, 0.14, FRONT_Z - BACK_Z))
	var floor := b.build()
	add_child(floor)


## The drain pipe: a low brick-lined culvert, with the collapsed stretch
## (the crawlspace) where the roof has slumped in a heap of stones and a
## broken beam.
func _build_pipe_details() -> void:
	_build_pipe_floor()
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.18
	# The slumped roof of the crawlspace: the vault's stones have dropped
	# out of place and hang in a heap, each block its own, jutting and
	# tilted, lowest in the middle (where he must crawl) and tapering up
	# into the pipe's roof at both ends.
	var reach := 0.9
	var y := Village.PIPE_TOP
	var row := 0
	while y > CRAWL_TOP + 0.02:
		var y0 := maxf(y - _rng.randf_range(0.22, 0.3), CRAWL_TOP)
		var x := CRAWL.x - reach
		if row % 2 == 1:
			x += _rng.randf_range(0.1, 0.25)
		while x < CRAWL.y + reach:
			var x1 := minf(x + _rng.randf_range(0.32, 0.55), CRAWL.y + reach)
			var mid := (x + x1) * 0.5
			# How far down the heap reaches here.
			var low := CRAWL_TOP
			if mid < CRAWL.x:
				low = lerpf(CRAWL_TOP, Village.PIPE_TOP, (CRAWL.x - mid) / reach)
			elif mid > CRAWL.y:
				low = lerpf(CRAWL_TOP, Village.PIPE_TOP, (mid - CRAWL.y) / reach)
			if y0 >= low - 0.05 or y > low + 0.12:
				var bottom := maxf(y0, low)
				b.color = STONE.lerp(STONE.lightened(0.2), _rng.randf()).darkened(_rng.randf_range(0.0, 0.25))
				var jut := _rng.randf_range(-0.12, 0.1)
				b.box(Vector3(mid, (y + bottom) * 0.5 + _rng.randf_range(-0.03, 0.03), (BACK_Z + FRONT_Z + jut) * 0.5),
						Vector3(x1 - x - 0.04, y - bottom - 0.03, FRONT_Z - BACK_Z + jut))
			x = x1
		y = y0
		row += 1
	# Grit and earth trickled down between the stones, a dark seam behind.
	b.color = Color(0.06, 0.065, 0.1)
	b.box(Vector3((CRAWL.x + CRAWL.y) * 0.5, (CRAWL_TOP + Village.PIPE_TOP) * 0.5 + 0.05, (BACK_Z + FRONT_Z) * 0.5 - 0.05),
			Vector3(CRAWL.y - CRAWL.x - 0.1, Village.PIPE_TOP - CRAWL_TOP - 0.1, FRONT_Z - BACK_Z - 0.2))
	for k in 9:
		b.color = STONE * _rng.randf_range(0.8, 1.3)
		var sx := _rng.randf_range(CRAWL.x - 0.2, CRAWL.y + 0.2)
		b.box(Vector3(sx, CRAWL_TOP + _rng.randf_range(-0.04, 0.08), _rng.randf_range(-1.5, 1.2)),
				Vector3(_rng.randf_range(0.25, 0.45), _rng.randf_range(0.12, 0.22), _rng.randf_range(0.3, 0.6)))
	# A broken roof beam, fallen at a slant across the heap.
	b.color = PaperMesh.TIMBER
	b.extrude(PackedVector2Array([Vector2(CRAWL.x - 0.6, CRAWL_TOP - 0.02), Vector2(CRAWL.x - 0.45, CRAWL_TOP - 0.1),
			Vector2(CRAWL.y - 0.4, Village.PIPE_TOP - 0.02), Vector2(CRAWL.y - 0.55, Village.PIPE_TOP + 0.06)]), 0.7, 0.92)
	# Loose stones on the floor either side of it.
	b.color = STONE.lightened(0.05)
	for k in 6:
		var lx := CRAWL.x - 1.4 + _rng.randf() * (CRAWL.y - CRAWL.x + 2.8)
		b.box(Vector3(lx, Village.PIPE_FLOOR + 0.06, _rng.randf_range(-2.0, -0.9)), Vector3(0.22, 0.12, 0.2))
	add_child(b.build())


## The chamber at the pipe's west end: steps up to the grate in Well Square's
## street. Its front is closed by a sheet of earth that only fades away
## while the camera is down here (from the street it must look solid).
func _build_chamber() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	b.color = STONE.lightened(0.06)
	for step: Array in [[-2.6, -1.5, -3.85], [-3.7, -2.6, -3.1], [Village.CHAMBER.x, -3.7, -2.0]]:
		b.box(Vector3((step[0] + step[1]) * 0.5, (step[2] - 5.0) * 0.5, (BACK_Z + 1.2) * 0.5),
				Vector3(step[1] - step[0], step[2] + 5.0, 1.2 - BACK_Z))
		b.color = STONE.lightened(0.16)
		b.box(Vector3((step[0] + step[1]) * 0.5, step[2] - 0.05, 1.15), Vector3(step[1] - step[0] + 0.02, 0.1, 0.14))
		b.color = STONE.lightened(0.06)
	add_child(b.build())
	# The grate: iron bars across a frame, set into the street.
	_grate = Node3D.new()
	_grate.position = Vector3(Village.GRATE_X - Village.GRATE_WIDTH * 0.5, -0.02, 0.0)
	add_child(_grate)
	var g := PaperMesh.new(_rng.randi())
	g.shade_jitter = 0.1
	g.color = Color(0.09, 0.09, 0.12)
	var w := Village.GRATE_WIDTH
	for z: float in [-1.05, 1.05]:
		g.box(Vector3(w * 0.5, -0.06, z), Vector3(w, 0.1, 0.1))
	for gx: float in [0.04, w - 0.04]:
		g.box(Vector3(gx, -0.06, 0.0), Vector3(0.08, 0.1, 2.2))
	var bar := 0.16
	while bar < w - 0.1:
		g.box(Vector3(bar, -0.07, 0.0), Vector3(0.045, 0.08, 2.1))
		bar += 0.15
	g.color = Color(0.3, 0.17, 0.11)  # rust
	for k in 5:
		g.box(Vector3(_rng.randf_range(0.1, w - 0.1), -0.02, _rng.randf_range(-0.9, 0.9)), Vector3(0.06, 0.012, 0.12))
	_grate.add_child(g.build())
	var target := PropTarget.make(self, BoxShape3D.new(), Vector3(Village.GRATE_X, -0.3, 0.0))
	((target.get_child(0) as CollisionShape3D).shape as BoxShape3D).size = Vector3(w, 0.5, 2.0)
	target.struck.connect(_on_grate_struck)
	# Moonlight falling through the bars into the chamber.
	var moon := OmniLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 1.4
	moon.omni_range = 3.4
	moon.omni_attenuation = 1.6
	moon.position = Vector3(Village.GRATE_X, -0.8, 0.6)
	add_child(moon)
	var shaft := PaperMesh.new(1)
	shaft.fade_quad(Vector3(Village.GRATE_X - 0.5, -2.0, -0.4), Vector3(Village.GRATE_X + 0.7, -2.0, -0.4),
			Vector3(Village.GRATE_X + 0.55, -0.3, -0.4), Vector3(Village.GRATE_X - 0.55, -0.3, -0.4),
			Color(0.6, 0.7, 1.0, 0.0), Color(0.6, 0.7, 1.0, 0.16))
	add_child(shaft.build_veil(true))
	# The chamber's front: from the street it is just more ground.
	var front := PaperMesh.new(_rng.randi())
	front.shade_jitter = 0.03
	front.color = Color(0.125, 0.135, 0.22)
	var line := PackedVector2Array()
	var x := Village.CHAMBER.x
	while x < Village.CHAMBER.y + 1.5:
		line.append(Vector2(x, -0.32 + _rng.randf_range(-0.05, 0.03)))
		x += _rng.randf_range(0.5, 1.2)
	var outline := PaperMesh.tear(line, 0.25, 0.02, _rng, false)
	outline.append(Vector2(Village.CHAMBER.y + 1.5, Village.PIPE_FLOOR - 1.0))
	outline.append(Vector2(Village.CHAMBER.x, Village.PIPE_FLOOR - 1.0))
	front.torn_sheet(outline, FRONT_Z + 0.12, Color(0.24, 0.265, 0.39), 0.03)
	_chamber_front = front.build()
	_chamber_front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_chamber_front)


func _on_grate_struck(direction: Vector2) -> void:
	if grate_open:
		return
	if direction.y <= 0.5:
		Sound.play(self, &"grate_clank", -4.0)
		return
	_grate_hits += 1
	Sound.play(self, &"grate_clank")
	if _grate_hits < 2:
		# Rusted fast: it jumps in its frame and rust and grit rain down.
		var jolt := create_tween()
		jolt.tween_property(_grate, "position:y", 0.05, 0.05)
		jolt.tween_property(_grate, "position:y", -0.02, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_grit(Vector3(Village.GRATE_X, -0.35, 0.0), 14)
		return
	open_grate()


## Bursts the grate open: it flips up on its hinge and falls open onto the
## street, and the way between the street and the pipe is clear.
func open_grate(at_once: bool = false) -> void:
	if grate_open:
		return
	grate_open = true
	if _grate_solid:
		_grate_solid.queue_free()
		_grate_solid = null
	if at_once:
		_grate.rotation.z = PI
		_grate.position.y = 0.0
		return
	_grit(Vector3(Village.GRATE_X, -0.35, 0.0), 26)
	var flip := create_tween()
	flip.tween_property(_grate, "rotation:z", deg_to_rad(120.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flip.tween_property(_grate, "rotation:z", PI, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flip.parallel().tween_property(_grate, "position:y", 0.0, 0.3)
	# (It lands flat on the stones beside the hole, with a small bounce.)
	flip.tween_property(_grate, "rotation:z", PI - 0.06, 0.08)
	flip.tween_property(_grate, "rotation:z", PI, 0.12)
	flip.tween_callback(Sound.play.bind(self, &"grate_clank", -2.0))
	shortcut_opened.emit(&"grate")


signal shortcut_opened(which: StringName)


## Rust and grit shaken loose: small dark flakes falling.
func _grit(at: Vector3, amount: int) -> void:
	var grit := CPUParticles3D.new()
	grit.emitting = false
	grit.one_shot = true
	grit.explosiveness = 0.7
	grit.amount = amount
	grit.lifetime = 1.1
	grit.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	grit.emission_box_extents = Vector3(0.5, 0.05, 0.8)
	grit.direction = Vector3.DOWN
	grit.spread = 25.0
	grit.gravity = Vector3(0.0, -9.0, 0.0)
	grit.initial_velocity_min = 0.3
	grit.initial_velocity_max = 1.5
	grit.angle_max = 360.0
	var flake := QuadMesh.new()
	flake.size = Vector2(0.04, 0.03)
	flake.material = PaperMesh.soft_ink(Color(0.22, 0.14, 0.1))
	grit.mesh = flake
	add_child(grit)
	grit.global_position = at
	grit.emitting = true
	grit.finished.connect(grit.queue_free)


## A sluice: river water pouring through a grate in the vault, down onto
## whatever is below, foaming where it lands. It presses him down.
func _build_sluice(x: float) -> void:
	var top := ceiling_at(x)
	var bottom := Village.CANAL_WATER
	for w: Array in WALKWAYS:
		if x > w[0] and x < w[1]:
			bottom = w[2]
	var height := top - bottom
	# The grate in the vault it pours through.
	var g := PaperMesh.new(_rng.randi())
	g.color = Color(0.08, 0.08, 0.11)
	g.box(Vector3(x, top - 0.05, -0.4), Vector3(sluice_half * 2.4, 0.1, 2.0))
	g.color = Color(0.03, 0.035, 0.06)
	g.box(Vector3(x, top - 0.11, -0.4), Vector3(sluice_half * 2.0, 0.04, 1.7))
	add_child(g.build())
	# The falling water: many long pale streaks pouring down.
	var fall := CPUParticles3D.new()
	fall.amount = 140
	var speed := 11.0
	fall.lifetime = height / speed
	fall.preprocess = 1.0
	fall.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fall.emission_box_extents = Vector3(sluice_half * 0.85, 0.02, 0.9)
	fall.direction = Vector3.DOWN
	fall.spread = 1.0
	fall.gravity = Vector3.ZERO
	fall.initial_velocity_min = speed * 0.92
	fall.initial_velocity_max = speed * 1.08
	var streak := QuadMesh.new()
	streak.size = Vector2(0.05, 0.75)
	var look := WaterFx.bead_material(Color(0.7, 0.78, 0.95, 0.32))
	look.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	look.billboard_keep_scale = true
	streak.material = look
	fall.mesh = streak
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fall.position = Vector3(x, top - 0.12, -0.4)
	add_child(fall)
	# A pale sheet behind the streaks, so it reads as a body of water.
	var sheet := PaperMesh.new(1)
	sheet.fade_quad(Vector3(x - sluice_half * 0.8, bottom, -1.2), Vector3(x + sluice_half * 0.8, bottom, -1.2),
			Vector3(x + sluice_half * 0.75, top, -1.2), Vector3(x - sluice_half * 0.75, top, -1.2),
			Color(0.55, 0.62, 0.8, 0.22), Color(0.55, 0.62, 0.8, 0.12))
	add_child(sheet.build_veil())
	# Spray and foam where it lands: beads thrown up all the time.
	var spray := CPUParticles3D.new()
	spray.amount = 50
	spray.lifetime = 0.55
	spray.preprocess = 0.6
	spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spray.emission_box_extents = Vector3(sluice_half, 0.02, 0.9)
	spray.direction = Vector3.UP
	spray.spread = 50.0
	spray.gravity = Vector3(0.0, -10.0, 0.0)
	spray.initial_velocity_min = 1.0
	spray.initial_velocity_max = 2.6
	var bead := QuadMesh.new()
	bead.size = Vector2(0.05, 0.05)
	bead.material = WaterFx.bead_material(Color(0.75, 0.82, 0.98, 0.6))
	spray.mesh = bead
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spray.position = Vector3(x, bottom + 0.05, -0.4)
	add_child(spray)
	# A cold light where it falls (moonlight coming down with the river).
	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 0.65, 0.95)
	light.light_energy = 1.1
	light.omni_range = 4.0
	light.omni_attenuation = 1.6
	light.position = Vector3(x, (top + bottom) * 0.5, 0.8)
	add_child(light)


## The shaft out of the canals east of the gatehouse: an old well-head in
## the street, stone-lined, with a timber frame and a pulley over it, a rope
## hanging down into the dark.
func _build_shaft() -> void:
	var left := Village.SHAFT.x
	var right := Village.SHAFT.y
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.12
	# Stone lining down both sides.
	b.color = STONE.lightened(0.06)
	for side: Array in [[left - 0.18, 1.0], [right + 0.18, -1.0]]:
		b.box(Vector3(side[0], -0.75, (BACK_Z + FRONT_Z) * 0.5), Vector3(0.36, 1.5, FRONT_Z - BACK_Z))
	b.color = STONE_JOINT
	for side: float in [left, right]:
		var y := -0.4
		while y > -1.5:
			b.box(Vector3(side, y, FRONT_Z - 0.01), Vector3(0.38, 0.03, 0.02))
			y -= 0.36
	# A low kerb round the opening at the back, and the frame over it.
	b.color = STONE.lightened(0.14)
	b.box(Vector3((left + right) * 0.5, 0.18, -1.9), Vector3(right - left + 0.6, 0.36, 0.4))
	b.color = PaperMesh.TIMBER
	for px: float in [left - 0.1, right + 0.1]:
		b.box(Vector3(px, 1.4, -1.9), Vector3(0.14, 2.8, 0.14))
	b.box(Vector3((left + right) * 0.5, 2.8, -1.9), Vector3(right - left + 0.5, 0.16, 0.18))
	b.color = Color(0.2, 0.18, 0.18)
	b.frustum(10, Vector2(0.16, 0.16), Vector2(0.16, 0.16), 0.1, Vector3((left + right) * 0.5, 2.62, -1.95), 0.0)
	add_child(b.build())
	var rope := Node3D.new()
	rope.position = Vector3((left + right) * 0.5 + 0.16, 2.62, -1.85)
	add_child(rope)
	var line := PaperMesh.new(_rng.randi())
	line.color = Color(0.4, 0.35, 0.28)
	line.stroke(Vector2.ZERO, Vector2(0.0, -5.6), 0.03, 0.03)
	line.color = Scenery.WOOD.darkened(0.2)
	line.box(Vector3(0.0, -5.7, 0.0), Vector3(0.36, 0.3, 0.3))  # a bucket on the end
	rope.add_child(line.build())
	Scenery.windswept(rope, 0.012, _rng)


## Drops falling from the vault here and there.
func _build_drips() -> void:
	var x := Village.CHAMBER.y + 3.0
	while x < Village.CANAL.y - 1.0:
		if not Village.is_hole(x):
			var drips := CPUParticles3D.new()
			drips.amount = 2
			drips.lifetime = 2.2
			drips.randomness = 0.6
			drips.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			drips.emission_box_extents = Vector3(0.6, 0.0, 1.0)
			drips.direction = Vector3.DOWN
			drips.spread = 0.0
			drips.gravity = Vector3(0.0, -9.8, 0.0)
			drips.initial_velocity_min = 0.0
			drips.initial_velocity_max = 0.2
			var drop := QuadMesh.new()
			drop.size = Vector2(0.025, 0.06)
			drop.material = WaterFx.bead_material(Color(0.7, 0.78, 0.95, 0.7))
			drips.mesh = drop
			drips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			drips.position = Vector3(x, ceiling_at(x) - 0.25, -0.3)
			add_child(drips)
		x += _rng.randf_range(5.0, 9.0)


## Lanterns hung from the beams by whoever still works down here, and a
## couple left on the walkways.
func _build_lights() -> void:
	for at: Array in [[-0.5, 0.5], [12.0, 0.55], [26.0, 0.55], [38.0, 0.6], [45.6, 0.6], [53.0, 0.6], [57.5, 0.75], [74.2, 0.7], [94.0, 0.7], [108.0, 0.65], [127.5, 0.75], [133.0, 0.7]]:
		var x: float = at[0]
		var top := ceiling_at(x)
		village._hang_lantern(Vector3(x, top - 0.2, -1.4), 0.25, at[1], false)


# --- The water and the sluices at work ---------------------------------------------

func _physics_process(delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var at := _ronin.global_position
	var in_canal := at.x > Village.CANAL.x and at.x < Village.CANAL.y
	# Into the water from above: a splash, bigger the harder he came down.
	if in_canal and _last_y >= Village.CANAL_WATER and at.y < Village.CANAL_WATER:
		var fall := -_ronin.velocity.y
		WaterFx.splash(get_parent(), Vector3(at.x, Village.CANAL_WATER, 0.0), clampf(fall / 10.0, 0.4, 1.5))
		Sound.play(self, &"splash", -2.0 if fall > big_splash_from else -8.0)
	# (Only while he is in the canal, so other water can set it too.)
	if in_canal or _was_wading:
		_ronin.wading = in_canal and at.y < Village.CANAL_WATER + 0.05 and _ronin.is_on_floor()
		_was_wading = _ronin.wading
	if _ronin.wading and absf(_ronin.velocity.x) > 0.5:
		_wade_clock += delta
		if _wade_clock >= wade_splash_every:
			_wade_clock = 0.0
			WaterFx.splash(get_parent(), Vector3(at.x, Village.CANAL_WATER, 0.0), 0.3)
			Sound.play(self, &"wade", -10.0)
	# Deep water: he is carried off.
	if at.x > DEEP.x and at.x < DEEP.y and at.y < Village.CANAL_WATER - 0.3:
		if not _carried_off:
			_carried_off = true
			WaterFx.splash(get_parent(), Vector3(at.x, Village.CANAL_WATER, 0.0), 1.4)
			_ronin.deep_water()  # (waxed, he floats)
	elif at.y > Village.CANAL_WATER + 1.0 or at.x < DEEP.x or at.x > DEEP.y:
		_carried_off = false
	# Under a sluice: pressed down, and spray off his hat.
	for x: float in SLUICES:
		if absf(at.x - x) < sluice_half and at.y < ceiling_at(x) and at.y > Village.CANAL_WATER - 1.0:
			if not _ronin.has_wax:  # (waxed, the water runs off him)
				_ronin.push.y -= sluice_press
			if _ronin.is_on_floor():
				_ronin.wading = true
			_spray_clock += delta
			if _spray_clock > 0.12:
				_spray_clock = 0.0
				WaterFx.splash(get_parent(), at + Vector3(0.0, 1.55, 0.0), 0.35)
	_last_y = at.y


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	# Underground the rain is only heard muffled, through the street above.
	if camera:
		var below := camera.global_position.y < 1.6 and camera.global_position.x > Village.CHAMBER.x - 4.0 				and camera.global_position.x < Village.CANAL.y + 4.0
		if below != _hushed:
			_hushed = below
			Sound.duck_rain(below)
	# The chamber's front is earth from the street, but fades away while he
	# is down inside it, so it can be seen (a hidden place revealed).
	if _ronin and _chamber_front:
		var inside := _ronin.global_position.y < -0.35 and _ronin.global_position.x > Village.CHAMBER.x - 0.5 				and _ronin.global_position.x < Village.CHAMBER.y + 3.0
		_chamber_seen = move_toward(_chamber_seen, 1.0 if inside else 0.0, delta / 0.4)
		# (Faded with its material's alpha: the Compatibility renderer does
		# not fade whole meshes. Opaque again once it is fully back.)
		var look := _chamber_front.material_override as StandardMaterial3D
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if _chamber_seen > 0.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		look.albedo_color.a = 1.0 - smoothstep(0.0, 1.0, _chamber_seen)
