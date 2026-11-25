class_name MarshVillage
extends Node3D
## The Drowned Village in Sumi Marsh (docs/sumi_marsh_plan.md, area 3):
## stilt houses standing in the ink, their porches the boardwalks
## (SumiMarsh.WALKS), thatched lean-to roofs over the porches walkable as the
## high route (climbed by a stack of crates and a barrel at a porch's end);
## one house slumped half into the ink; the old street drowned under deep
## ink, its roofs poking up (SumiMarsh.SUNKEN). Shrine 11 on the third
## porch. Cranes: on the third roof (the high route), and floating under the
## first porch (only reached swimming, with the Wax Coat).
## Built in the marsh's own coordinates.

## [left, right, deck top, walkable roof?, lit window?]
const HOUSES := [[104.0, 112.6, 1.6, true, false], [118.6, 126.4, 1.8, true, false], [133.4, 140.6, 1.6, true, true],
		[149.0, 154.6, 0.55, false, false], [162.4, 169.6, 1.6, true, true]]
## The crate stacks to climb onto a roof: x on its porch.
const STACKS := [[113.0, 1.6], [126.7, 1.8], [140.8, 1.6], [169.8, 1.6]]
## The roof over a porch: its eave's height above the deck and its front.
const EAVE := 3.4
const RIDGE := 5.2
const FRONT_Z := 1.6
const RIDGE_Z := -3.4
## The broken niche on the last house, under a pour of ink (SumiMarsh
## CURTAINS): a shelf with cranes, reached only once the Rain's weight runs
## off him (the Wax Coat).
const NICHE := Vector3(172.0, 3.6, 0.0)

var marsh: SumiMarsh
var _rng := RandomNumberGenerator.new()


## The walkable roof's top along the gameplay plane, for a deck height.
static func roof_top(deck: float) -> float:
	var t := FRONT_Z / (FRONT_Z - RIDGE_Z)
	return deck + EAVE + t * (RIDGE - EAVE)


func _ready() -> void:
	_rng.seed = 6161
	for h: Array in HOUSES:
		_house(h[0], h[1], h[2], h[3], h[4])
	for s: Array in STACKS:
		_stack(s[0], s[1])
	_niche()
	var roofs := CraneBundle.new()
	roofs.id = "marsh_roofs"
	roofs.count = 6
	roofs.position = Vector3(137.0, roof_top(1.6), 0.0)
	add_child(roofs)
	# Under the first porch, on a floating door: only swum to.
	var door := PaperMesh.new(_rng.randi())
	door.color = MarshKit.WOOD_WET.lightened(0.1)
	door.box(Vector3(107.6, SumiMarsh.INK_Y + 0.02, 0.0), Vector3(1.3, 0.08, 0.9))
	door.color = Color(0.5, 0.48, 0.42)
	door.box(Vector3(107.6, SumiMarsh.INK_Y + 0.065, 0.0), Vector3(1.1, 0.01, 0.7))
	add_child(door.build())
	var sunken := CraneBundle.new()
	sunken.id = "marsh_sunken"
	sunken.count = 5
	sunken.position = Vector3(107.6, SumiMarsh.INK_Y + 0.07, 0.0)
	sunken.swim_only = true
	add_child(sunken)


## A stilt house: its front wall of frames and paper panels (some torn,
## stained up from the ink), its stilts into the ink, the thatch over the
## porch. Slumped (no walkable roof), it leans back and sinks.
func _house(left: float, right: float, deck: float, walkable: bool, lit: bool) -> void:
	var root := Node3D.new()
	add_child(root)
	var slumped := not walkable
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	var wall_h := 3.2 if not slumped else 2.4
	var front := -1.6
	var back := -5.4
	# The floor of the house behind the porch, and its stilts.
	b.color = MarshKit.WOOD_WET
	b.box(Vector3((left + right) * 0.5, deck - 0.12, (front + back) * 0.5), Vector3(right - left, 0.24, back - front))
	var x := left + 0.2
	while x <= right:
		for z: float in [back + 0.3, (front + back) * 0.5]:
			b.color = MarshKit.WOOD_WET.darkened(0.15)
			b.frustum(6, Vector2(0.11, 0.11), Vector2(0.1, 0.1), deck + 1.0, Vector3(x, -1.0, z))
		x += 2.1
	# The walls: frame posts and a rail, paper between, ink soaking up from below.
	b.color = Color(0.16, 0.14, 0.14)
	var px := left
	var panel := 0
	while px < right - 0.01:
		var px1 := minf(px + 1.2, right)
		b.color = Color(0.16, 0.14, 0.14)
		b.box(Vector3(px, deck + wall_h * 0.5, front), Vector3(0.12, wall_h, 0.12))
		var tone := Color(0.5, 0.49, 0.45).darkened(_rng.randf_range(0.0, 0.25))
		var torn := _rng.randf() < 0.25
		if lit and panel % 3 == 1:
			tone = Color(0.8, 0.62, 0.4)
		b.color = tone
		if not torn:
			b.box(Vector3((px + px1) * 0.5, deck + wall_h * 0.52, front - 0.04), Vector3(px1 - px - 0.1, wall_h * 0.8, 0.03))
		else:
			b.box(Vector3((px + px1) * 0.5, deck + wall_h * 0.75, front - 0.04), Vector3(px1 - px - 0.1, wall_h * 0.34, 0.03))
			b.color = Color(0.04, 0.04, 0.05)
			b.box(Vector3((px + px1) * 0.5, deck + wall_h * 0.32, front - 0.2), Vector3(px1 - px - 0.1, wall_h * 0.46, 0.03))
		# Ink soaked up the paper's bottom.
		b.color = Color(0.1, 0.1, 0.12)
		b.box(Vector3((px + px1) * 0.5, deck + 0.35, front - 0.02), Vector3(px1 - px - 0.1, 0.5, 0.03))
		# Lattice.
		b.color = Color(0.18, 0.16, 0.15)
		b.box(Vector3((px + px1) * 0.5, deck + wall_h * 0.52, front - 0.01), Vector3(0.03, wall_h * 0.8, 0.02))
		b.box(Vector3((px + px1) * 0.5, deck + wall_h * 0.6, front - 0.01), Vector3(px1 - px - 0.1, 0.03, 0.02))
		px = px1
		panel += 1
	b.color = Color(0.16, 0.14, 0.14)
	b.box(Vector3(right, deck + wall_h * 0.5, front), Vector3(0.12, wall_h, 0.12))
	b.box(Vector3((left + right) * 0.5, deck + wall_h, front), Vector3(right - left + 0.12, 0.16, 0.16))
	# Side walls, back wall (solid from every angle the camera reaches).
	b.color = Color(0.22, 0.2, 0.19)
	for sx: float in [left, right]:
		b.box(Vector3(sx, deck + wall_h * 0.5, (front + back) * 0.5), Vector3(0.1, wall_h, back - front))
	b.box(Vector3((left + right) * 0.5, deck + wall_h * 0.5, back), Vector3(right - left, wall_h, 0.1))
	# The porch's front posts hold the eave.
	if not slumped:
		for fx: float in [left + 0.1, (left + right) * 0.5, right - 0.1]:
			b.color = MarshKit.WOOD_WET.lightened(0.04)
			b.frustum(6, Vector2(0.09, 0.09), Vector2(0.09, 0.09), EAVE - 0.3, Vector3(fx, deck, FRONT_Z - 0.25))
	var walls := b.build()
	root.add_child(walls)
	if slumped:
		var roof := MarshKit.thatch(_rng, left, right, deck + wall_h + 0.2, front + 0.8, deck + wall_h + 1.6, back)
		root.add_child(roof)
		root.position = Vector3(0.0, -0.25, 0.0)
		root.rotation = Vector3(-0.05, 0.0, -0.06)
		return
	root.add_child(MarshKit.thatch(_rng, left, right, deck + EAVE, FRONT_Z, deck + RIDGE, RIDGE_Z))
	root.add_child(MarshKit.thatch(_rng, left, right, deck + RIDGE - 0.05, RIDGE_Z - 0.05, deck + EAVE + 0.5, back - 0.4))
	# The roof is solid along the gameplay plane: the high route.
	var top := roof_top(deck)
	marsh._solid(Vector3((left + right) * 0.5, top - 0.2, 0.0), Vector3(right - left + 0.4, 0.4, 2.0))
	# A lantern under the eave, dim; a warm window inside if lit.
	var lantern := Scenery.lantern(_rng, marsh.village.lantern_glow * (0.9 if lit else 0.35), 0.8)
	lantern.position = Vector3(left + 0.8, deck + EAVE - 0.35, FRONT_Z - 0.3)
	add_child(lantern)
	Scenery.windswept(lantern, 0.035, _rng)
	if lit:
		marsh._light(Vector3((left + right) * 0.5, deck + 1.6, front + 0.6), 1.6, 6.0)
		marsh._shine((left + right) * 0.5, 1.4, Color(1.0, 0.66, 0.36, 0.22))
	else:
		marsh._light(Vector3(left + 0.8, deck + EAVE - 0.6, FRONT_Z), 0.6, 3.5)


## A barrel and two crates, stacked at a porch's end: steps up to the roof.
func _stack(x: float, deck: float) -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	b.color = Color(0.28, 0.22, 0.17)
	b.box(Vector3(x, deck + 0.4, 0.0), Vector3(0.85, 0.8, 0.85))
	b.color = Color(0.24, 0.19, 0.15)
	b.box(Vector3(x - 0.05, deck + 0.8 + 0.45, -0.05), Vector3(0.75, 0.9, 0.75))
	b.color = Color(0.12, 0.1, 0.09)
	for y: float in [deck + 0.06, deck + 0.74, deck + 0.86, deck + 1.64]:
		b.box(Vector3(x, y, 0.0), Vector3(0.88, 0.04, 0.88))
	add_child(b.build())
	marsh._solid(Vector3(x, deck + 0.4, 0.0), Vector3(0.85, 0.8, 1.2))
	marsh._solid(Vector3(x - 0.05, deck + 1.25, 0.0), Vector3(0.75, 0.9, 1.2))


## The broken niche on the last house's east end: a shelf with a roof
## over it and walls round it, a gutter pouring ink across its mouth.
func _niche() -> void:
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.14
	var n := NICHE
	# The shelf (a broken upper floor), its posts down into the shallows.
	marsh._solid(Vector3(n.x, n.y - 0.15, 0.0), Vector3(2.4, 0.3, 2.4))
	b.color = MarshKit.WOOD_WET
	b.box(Vector3(n.x, n.y - 0.1, -0.4), Vector3(2.4, 0.2, 3.2))
	for px: float in [n.x - 1.1, n.x + 1.1]:
		b.frustum(6, Vector2(0.1, 0.1), Vector2(0.1, 0.1), n.y + 0.5, Vector3(px, -0.6, 0.4))
		b.frustum(6, Vector2(0.1, 0.1), Vector2(0.1, 0.1), n.y + 0.5, Vector3(px, -0.6, -1.8))
	# Its back and end walls and the roof over it (no way in from above).
	b.color = Color(0.22, 0.2, 0.19)
	b.box(Vector3(n.x, n.y + 1.1, -1.9), Vector3(2.4, 2.2, 0.1))
	b.box(Vector3(n.x + 1.2, n.y + 1.1, -0.4), Vector3(0.1, 2.2, 3.0))
	marsh._solid(Vector3(n.x + 1.25, n.y + 1.1, 0.0), Vector3(0.2, 2.2, 2.0))
	marsh._solid(Vector3(n.x, n.y + 2.3, 0.0), Vector3(2.8, 0.3, 2.4))
	b.color = Color(0.12, 0.1, 0.1)
	b.box(Vector3(n.x, n.y + 2.15, -0.4), Vector3(2.6, 0.12, 3.2))
	# The broken gutter above its mouth (the pour comes from here).
	b.color = Color(0.2, 0.17, 0.15)
	b.box(Vector3(n.x - 0.1, 6.0, 1.55), Vector3(3.0, 0.18, 0.4))
	b.box(Vector3(n.x - 1.5, 6.0, 0.3), Vector3(0.2, 0.18, 2.8))
	add_child(b.build())
	add_child(MarshKit.thatch(_rng, n.x - 1.3, n.x + 1.3, n.y + 2.3, 1.2, n.y + 3.0, -2.0))
	var bundle := CraneBundle.new()
	bundle.id = "marsh_niche"
	bundle.count = 6
	bundle.position = Vector3(n.x + 0.3, n.y, 0.0)
	add_child(bundle)
