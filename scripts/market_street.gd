class_name MarketStreet
extends Node3D
## Market Street (area 2 of the expanded village, docs/village_map.png):
## the shop houses along the back are built by Village with the others;
## this puts in what stands IN the street:
##  - market stalls whose paper awnings sag and bounce (MarketStall);
##  - two galleries: an upper storey on posts you walk under, with a tiled
##    roof you can stand on (and climb: their walls are climbable);
##  - a string of lanterns between the galleries' roofs, to cross by cutting
##    down onto them in the air (LanternString);
##  - shop signs that swing (HangingSign);
##  - a storehouse with a back room behind a shoji door (SecretRoom).
## Positions are along the street (Village x); edit the lists to move things.

var village: Village

## [centre x, width, awning height, what it sells]
## (Awnings stay below his full jump, 2.5 m, so he can hop up onto them.)
const STALLS := [[19.8, 3.2, 2.2, "produce"], [25.4, 3.0, 2.3, "noodles"], [52.4, 3.0, 2.2, "fish"]]
## [left x, right x, height of the upper storey's top, opening underneath,
##  what is on its balcony: "laundry" or "garden"]
const GALLERIES := [[29.6, 34.4, 5.0, 2.9, "laundry"], [41.6, 46.2, 5.0, 2.9, "garden"]]
## [left pole x, span, rope height, sag, lanterns]
const STRINGS := [[34.1, 7.8, 6.7, 1.0, 4]]
## [x, height of the shop's porch beam, mark]: signs hung out over the street.
const SIGNS := [[39.6, 4.15, 1], [47.0, 4.55, 0], [50.4, 4.55, 2]]
## Left wall x of the storehouse with the back room.
const SECRET_X := 56.2


func _ready() -> void:
	for s: Array in STALLS:
		var stall := MarketStall.new()
		stall.width = s[1]
		stall.top = s[2]
		stall.kind = s[3]
		stall.bounce_speed = 16.5
		stall.position = Vector3(s[0], 0.0, 0.0)
		add_child(stall)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	for g: Array in GALLERIES:
		_build_gallery(rng, g[0], g[1], g[3], g[2], g[4])
	for l: Array in STRINGS:
		var line := LanternString.new()
		line.span = l[1]
		line.height = l[2]
		line.sag = l[3]
		line.count = l[4]
		line.on_roofs = true
		line.position = Vector3(l[0], 0.0, 0.0)
		add_child(line)
	for g: Array in SIGNS:
		var sign := HangingSign.new()
		sign.height = g[1]
		sign.mark = g[2]
		sign.position = Vector3(g[0], 0.0, 0.0)
		add_child(sign)
	var room := SecretRoom.new()
	room.position = Vector3(SECRET_X, 0.0, 0.0)
	add_child(room)
	# A crate by the storehouse, solid: something to hop onto.
	var crate := Scenery.crate(RandomNumberGenerator.new(), 0.9)
	crate.position = Vector3(SECRET_X + 5.15, 0.0, -0.2)
	add_child(crate)
	village._add_solid(Vector3(SECRET_X + 5.15, 0.45, 0.0), Vector3(0.9, 0.9, 1.2))


## A gallery: the upper storey of a shop built out over the street on posts,
## so the street runs underneath it. Dark boards, a row of shoji windows lit
## from inside (one slid open on a dark room, one torn), a balcony with a
## railing along its front, a tiled roof you can stand on. Its walls are
## climbable. Solid from every side the camera sees.
func _build_gallery(rng: RandomNumberGenerator, left: float, right: float, opening: float, top: float,
		balcony: String) -> void:
	var width := right - left
	var middle := (left + right) * 0.5
	var deep := 1.1
	var roof_ridge := Village.CLIMB_ROOF
	var body := village._add_solid(Vector3(middle, (opening + top + roof_ridge) * 0.5, 0.0),
			Vector3(width, top + roof_ridge - opening, 2.2))
	body.set_meta(&"climbable", true)

	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.16
	# Posts down to the street: at both ends and in the middle, in front of
	# and behind the path, with knee braces up under the floor beam.
	b.color = PaperMesh.TIMBER
	var posts := [left + 0.12, right - 0.12]
	if width > 4.0:
		posts.append(middle)
	for px: float in posts:
		for pz: float in [1.0, -1.0]:
			b.box(Vector3(px, opening * 0.5, pz), Vector3(0.2, opening, 0.2))
	for pz: float in [1.0, -1.0]:
		for px: float in posts:
			for side: float in [-1.0, 1.0]:
				if (px <= left + 0.2 and side < 0.0) or (px >= right - 0.2 and side > 0.0):
					continue
				b.extrude(PackedVector2Array([Vector2(px, opening - 0.75), Vector2(px + side * 0.08, opening - 0.75),
						Vector2(px + side * 0.62, opening - 0.16), Vector2(px + side * 0.5, opening - 0.16)]) if side > 0.0 else
						PackedVector2Array([Vector2(px + side * 0.08, opening - 0.75), Vector2(px, opening - 0.75),
						Vector2(px + side * 0.5, opening - 0.16), Vector2(px + side * 0.62, opening - 0.16)]), pz - 0.05, pz + 0.05)
	# The floor beam all round, and the floor's underside.
	b.box(Vector3(middle, opening - 0.08, 0.0), Vector3(width + 0.2, 0.2, deep * 2.0 + 0.1))
	b.color = Scenery.WOOD.darkened(0.45)
	b.box(Vector3(middle, opening - 0.2, 0.0), Vector3(width, 0.04, deep * 2.0))
	# The upper storey: dark board walls, front and sides.
	b.color = Scenery.WALL_DARK
	b.box(Vector3(middle, (opening + top) * 0.5, 0.0), Vector3(width - 0.04, top - opening, deep * 2.0 - 0.04))
	add_child(b.build())

	# The front: timber frame, the shoji band, plaster above and below it.
	var sill := opening + 0.45
	var lintel := top - 0.45
	var f := PaperMesh.new(rng.randi())
	f.shade_jitter = 0.08
	f.color = Scenery.WALL_PAPER.darkened(0.15)
	f.rect(Vector2(middle, (lintel + top) * 0.5), Vector2(width - 0.1, top - lintel), deep + 0.01)
	f.rect(Vector2(middle, (opening + sill) * 0.5), Vector2(width - 0.1, sill - opening), deep + 0.01)
	f.color = Scenery.WALL_STAIN
	for k in 2:
		var at := Vector2(rng.randf_range(left + 0.5, right - 0.5), lintel + 0.18)
		f.ellipse(at, Vector2(rng.randf_range(0.3, 0.6), 0.12), 8, deep + 0.015, 0.2)
	f.color = PaperMesh.TIMBER
	f.box(Vector3(middle, top - 0.06, deep + 0.04), Vector3(width + 0.06, 0.14, 0.1))
	f.box(Vector3(middle, lintel, deep + 0.04), Vector3(width + 0.06, 0.1, 0.09))
	f.box(Vector3(middle, sill, deep + 0.04), Vector3(width + 0.06, 0.1, 0.09))
	for px: float in [left + 0.06, right - 0.06]:
		f.box(Vector3(px, (opening + top) * 0.5, deep + 0.04), Vector3(0.14, top - opening, 0.1))
	# Ink running down from the beams.
	f.color = Scenery.INK_DRIP
	for k in 3:
		var dx := rng.randf_range(left + 0.3, right - 0.3)
		f.stroke(Vector2(dx, lintel - 0.05), Vector2(dx + 0.01, lintel - rng.randf_range(0.3, 0.7)), 0.035, 0.006, deep + 0.05)
	add_child(f.build())

	# The shoji panels: lit paper behind a lattice; one slid open on the dark
	# room behind, one with a torn pane.
	var panels := maxi(3, int(width / 1.05))
	var panel_w := (width - 0.2) / panels
	var open_one := rng.randi_range(0, panels - 1)
	var torn_one := (open_one + 1 + rng.randi_range(0, panels - 2)) % panels
	var glass := PaperMesh.new(rng.randi())
	glass.shade_jitter = 0.07
	var dark := PaperMesh.new(rng.randi())
	dark.color = Color(0.05, 0.045, 0.07)
	var lattice := PaperMesh.new(rng.randi())
	lattice.color = PaperMesh.TIMBER
	for k in panels:
		var x0 := left + 0.1 + k * panel_w
		var centre := Vector2(x0 + panel_w * 0.5, (sill + lintel) * 0.5)
		var size := Vector2(panel_w - 0.04, lintel - sill - 0.08)
		if k == open_one:
			dark.rect(centre, size, deep + 0.02)
			continue
		glass.rect(centre, size, deep + 0.02)
		for c in 3:
			lattice.rect(centre + Vector2(lerpf(-size.x, size.x, (c + 1) / 4.0) * 0.5, 0.0), Vector2(0.025, size.y), deep + 0.035)
		for c in 4:
			lattice.rect(centre + Vector2(0.0, lerpf(-size.y, size.y, (c + 1) / 5.0) * 0.5), Vector2(size.x, 0.025), deep + 0.035)
		lattice.rect(centre + Vector2(-size.x * 0.5, 0.0), Vector2(0.05, size.y + 0.04), deep + 0.04)
		lattice.rect(centre + Vector2(size.x * 0.5, 0.0), Vector2(0.05, size.y + 0.04), deep + 0.04)
		if k == torn_one:
			var corner := centre + Vector2(-size.x * 0.25, size.y * 0.05)
			dark.polygon(PaperMesh.tear(PackedVector2Array([corner, corner + Vector2(0.22, 0.04), corner + Vector2(0.16, 0.24),
					corner + Vector2(0.02, 0.18)]), 0.08, 0.03, rng), deep + 0.025)
	var lit := glass.build(Color(1.0, 0.76, 0.46), village.window_glow, true)
	lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lit)
	add_child(dark.build(Color.WHITE, 0.0, true))
	add_child(lattice.build())
	var shine := Scenery.halo(width * 0.55, Color(1.0, 0.6, 0.28, 0.22))
	shine.position = Vector3(middle, (sill + lintel) * 0.5, deep + 0.3)
	add_child(shine)
	village._add_light(Vector3(middle, (sill + lintel) * 0.5, deep + 1.4), village.lantern_energy * 0.35, village.lantern_range * 0.7)

	# The balcony along the front: a narrow board floor on brackets and a
	# railing, just in front of the windows.
	var bal := PaperMesh.new(rng.randi())
	bal.shade_jitter = 0.2
	bal.color = Scenery.WOOD.darkened(0.15)
	bal.box(Vector3(middle, opening + 0.02, deep + 0.28), Vector3(width + 0.1, 0.07, 0.5))
	bal.color = PaperMesh.TIMBER
	bal.box(Vector3(middle, opening + 0.78, deep + 0.5), Vector3(width + 0.1, 0.07, 0.07))
	bal.box(Vector3(middle, opening + 0.3, deep + 0.5), Vector3(width + 0.1, 0.04, 0.04))
	var bx := left + 0.02
	while bx < right:
		bal.box(Vector3(bx, opening + 0.4, deep + 0.5), Vector3(0.035, 0.76, 0.035))
		bx += 0.22
	add_child(bal.build())
	if balcony == "laundry":
		_balcony_laundry(rng, left, right, opening, deep)
	else:
		_balcony_garden(rng, left, right, opening, top, deep)

	# Sides: dark boards with a beam, and the roof, sloping front and back.
	var sides := PaperMesh.new(rng.randi())
	sides.color = Scenery.WALL_DARK.darkened(0.1)
	for side: float in [-1.0, 1.0]:
		var wx := middle + side * width * 0.5
		sides.quad(Vector3(wx, opening, deep), Vector3(wx, opening, -deep), Vector3(wx, top, -deep), Vector3(wx, top, deep),
				Vector3(side, 0.0, 0.0))
		sides.tri(Vector3(wx, top, deep), Vector3(wx, top, -deep), Vector3(wx, top + roof_ridge - 0.12, 0.0), Vector3(side, 0.0, 0.0))
	add_child(sides.build())
	add_child(Scenery.tiled_roof(rng, left - 0.25, right + 0.25, Vector2(top - 0.02, deep + 0.4), Vector2(top + roof_ridge - 0.12, 0.0), 4))
	add_child(Scenery.tiled_roof(rng, left - 0.25, right + 0.25, Vector2(top - 0.02, -deep - 0.4), Vector2(top + roof_ridge - 0.12, 0.0), 4, false))


## A household's balcony: a robe hung out on a bamboo pole to dry, sleeves
## spread, and a small towel over the rail. Both stir in the wind.
func _balcony_laundry(rng: RandomNumberGenerator, left: float, right: float, opening: float, deep: float) -> void:
	var pole := PaperMesh.new(rng.randi())
	pole.color = Color(0.58, 0.53, 0.38)
	var py := opening + 1.55
	pole.box(Vector3((left + right) * 0.5, py, deep + 0.63), Vector3(right - left - 0.3, 0.06, 0.06))
	# Bamboo nodes along it.
	pole.color = Color(0.44, 0.4, 0.28)
	var nx := left + 0.4
	while nx < right - 0.3:
		pole.box(Vector3(nx, py, deep + 0.63), Vector3(0.03, 0.075, 0.075))
		nx += 0.55
	for px: float in [left + 0.25, right - 0.25]:
		pole.box(Vector3(px, opening + 1.15, deep + 0.55), Vector3(0.04, 0.85, 0.04))
	add_child(pole.build())
	# The robe: a kimono hung to dry with the pole run through its sleeves,
	# as it is done. Indigo, with a pale wave pattern (seigaiha) dyed in rows,
	# a lighter lining showing at the sleeve openings and hem, the collar
	# crossing at the front, and soft folds where it hangs heavy.
	var hang := Node3D.new()
	var rx := left + (right - left) * rng.randf_range(0.35, 0.55)
	hang.position = Vector3(rx, py - 0.02, deep + 0.66)
	add_child(hang)
	var robe := PaperMesh.new(rng.randi())
	robe.shade_jitter = 0.04
	var cloth := Color(0.2, 0.23, 0.36)
	var lining := Color(0.46, 0.44, 0.5)
	var sleeve := 0.82  # from the middle to the sleeve's end
	var body := 0.34    # half the body's width at the shoulders
	var flare := 0.42   # ...and at the hem
	var hem := -1.22
	var cuff := -0.62   # how far down the sleeves hang
	# Lining first: it shows at the sleeve mouths and along the hem.
	robe.color = lining
	for side: float in [-1.0, 1.0]:
		robe.polygon(_mirror(PackedVector2Array([Vector2(sleeve - 0.05, 0.02), Vector2(sleeve + 0.025, -0.01),
				Vector2(sleeve + 0.03, -0.22), Vector2(sleeve - 0.05, -0.24)]), side), -0.004)
	robe.polygon(PackedVector2Array([Vector2(-flare - 0.01, hem + 0.06), Vector2(flare + 0.01, hem + 0.06),
			Vector2(flare + 0.02, hem - 0.03), Vector2(0.0, hem - 0.05), Vector2(-flare - 0.02, hem - 0.03)]), -0.004)
	# The body: straight at the shoulders, flaring a little to the hem, the
	# hem dipping where the weight pulls it.
	robe.color = cloth
	robe.polygon(PackedVector2Array([Vector2(-body, 0.0), Vector2(body, 0.0), Vector2(flare, hem + 0.06),
			Vector2(flare * 0.4, hem + 0.02), Vector2(-flare * 0.3, hem + 0.03), Vector2(-flare, hem + 0.06)]))
	# The sleeves: deep pockets of cloth hanging from the arms, their outer
	# bottom corners rounded, the inner edge open below the armpit.
	for side: float in [-1.0, 1.0]:
		var outline := PackedVector2Array([Vector2(body - 0.03, 0.0), Vector2(sleeve, 0.0), Vector2(sleeve + 0.01, cuff + 0.14)])
		for k in 5:  # the rounded corner
			var a := -PI * 0.5 * (k + 1) / 5.0
			outline.append(Vector2(sleeve - 0.14 + cos(a) * 0.14 + 0.01, cuff + 0.14 + sin(a) * 0.14))
		outline.append(Vector2(body + 0.12, cuff + 0.02))
		outline.append(Vector2(body + 0.1, -0.26))
		outline.append(Vector2(body - 0.03, -0.3))
		robe.polygon(_mirror(outline, side), 0.002)
	# The front panel (okumi) overlapping, left over right, from the collar
	# down to the hem.
	robe.color = cloth.lightened(0.05)
	robe.polygon(PackedVector2Array([Vector2(-0.06, -0.02), Vector2(0.02, -0.02), Vector2(0.2, -0.5), Vector2(0.26, hem + 0.05),
			Vector2(0.06, hem + 0.03), Vector2(0.04, -0.5)]), 0.004)
	# The pattern: rows of small overlapping wave arcs, in a pale indigo.
	robe.color = Color(0.48, 0.52, 0.66)
	var row := 0
	var wy := -0.08
	while wy > hem + 0.1:
		var wx := -sleeve + 0.06 + (0.07 if row % 2 == 1 else 0.0)
		while wx < sleeve - 0.06:
			var inside_body := absf(wx) < body - 0.04
			var inside_sleeve := absf(wx) > body + 0.06 and absf(wx) < sleeve - 0.08 and wy > cuff + 0.08
			if inside_body or inside_sleeve:
				for ring in 2:
					var r := 0.055 - ring * 0.022
					for k in 4:
						var a0 := PI * k / 4.0
						var a1 := PI * (k + 1) / 4.0
						robe.stroke(Vector2(wx + cos(a0) * r, wy + sin(a0) * r), Vector2(wx + cos(a1) * r, wy + sin(a1) * r),
								0.008, 0.008, 0.006 + ring * 0.001)
			wx += 0.14
		wy -= 0.09
		row += 1
	# The collar band, dark, running down the overlap, with a pale edge.
	robe.color = Color(0.12, 0.13, 0.22)
	robe.polygon(PackedVector2Array([Vector2(-0.1, -0.01), Vector2(-0.03, -0.01), Vector2(0.12, -0.46), Vector2(0.05, -0.46)]), 0.01)
	robe.polygon(PackedVector2Array([Vector2(0.03, -0.01), Vector2(0.1, -0.01), Vector2(0.02, -0.24), Vector2(-0.03, -0.2)]), 0.011)
	robe.color = lining.lightened(0.15)
	robe.stroke(Vector2(-0.1, -0.01), Vector2(0.05, -0.46), 0.012, 0.012, 0.012)
	# The seams where the sleeves join the body.
	robe.color = cloth.darkened(0.25)
	for side: float in [-1.0, 1.0]:
		robe.stroke(Vector2(side * (body - 0.02), -0.01), Vector2(side * (body - 0.02), -0.3), 0.012, 0.012, 0.009)
	# Folds: darker creases where the weight pulls it down.
	robe.color = cloth.darkened(0.35)
	for fx: float in [-0.2, 0.05, 0.24]:
		robe.stroke(Vector2(fx + rng.randf_range(-0.03, 0.03), -0.55), Vector2(fx + rng.randf_range(-0.05, 0.05), hem + 0.08),
				0.012, 0.028, 0.009)
	for side: float in [-1.0, 1.0]:
		robe.stroke(Vector2(side * (body + 0.12), -0.04), Vector2(side * (body + 0.2), -0.44), 0.01, 0.02, 0.009)
	hang.add_child(robe.build())
	Scenery.windswept(hang, 0.045, rng)
	# A towel over the rail, somewhere else along it.
	var towel := Node3D.new()
	var tx := right - rng.randf_range(0.5, 0.9) if rx < (left + right) * 0.5 else left + rng.randf_range(0.5, 0.9)
	towel.position = Vector3(tx, opening + 0.8, deep + 0.6)
	add_child(towel)
	var rag := PaperMesh.new(rng.randi())
	rag.color = Color(0.66, 0.63, 0.56)
	rag.rect(Vector2(0.0, -0.22), Vector2(0.34, 0.46), 0.0)
	rag.color = Color(0.3, 0.36, 0.5)
	rag.rect(Vector2(0.0, -0.38), Vector2(0.34, 0.04), 0.005)
	towel.add_child(rag.build())
	Scenery.windswept(towel, 0.05, rng)


## Another household's balcony: potted plants along the rail (a pine bonsai,
## a leafy one, a bare one) and a bamboo blind let half down over the windows.
func _balcony_garden(rng: RandomNumberGenerator, left: float, right: float, opening: float, top: float, deep: float) -> void:
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.2
	var x := left + rng.randf_range(0.35, 0.6)
	var kinds := ["pine", "leafy", "bare", "leafy"]
	kinds.shuffle()
	for kind: String in kinds:
		if x > right - 0.4:
			break
		b.color = [Color(0.36, 0.24, 0.18), Color(0.3, 0.3, 0.34), Color(0.42, 0.36, 0.3)][rng.randi() % 3]
		b.frustum(8, Vector2(0.1, 0.1), Vector2(0.13, 0.13), 0.16, Vector3(x, opening + 0.06, deep + 0.3))
		match kind:
			"pine":
				b.color = PaperMesh.TIMBER
				b.stroke(Vector2(x, opening + 0.2), Vector2(x + 0.12, opening + 0.42), 0.04, 0.02, deep + 0.32)
				b.color = Color(0.18, 0.26, 0.2)
				b.ellipse(Vector2(x + 0.14, opening + 0.45), Vector2(0.16, 0.06), 9, deep + 0.33, 0.2)
				b.ellipse(Vector2(x - 0.02, opening + 0.33), Vector2(0.11, 0.045), 9, deep + 0.33, 0.2)
			"leafy":
				b.color = Color(0.22, 0.3, 0.2)
				for k in 6:
					b.ellipse(Vector2(x + rng.randf_range(-0.1, 0.1), opening + 0.28 + rng.randf_range(0.0, 0.2)),
							Vector2(0.07, 0.04), 6, deep + 0.33 + k * 0.002, 0.2)
			"bare":
				b.color = PaperMesh.TIMBER
				for k in 3:
					b.stroke(Vector2(x, opening + 0.2), Vector2(x + rng.randf_range(-0.14, 0.14), opening + rng.randf_range(0.4, 0.58)),
							0.02, 0.008, deep + 0.32)
		x += rng.randf_range(0.6, 1.05)
	add_child(b.build())
	# The blind: split bamboo rolled half down, over one side's windows.
	var blind := PaperMesh.new(rng.randi())
	var bl := left + 0.15 if rng.randf() < 0.5 else (left + right) * 0.5
	var br := bl + (right - left) * 0.45
	var lintel := top - 0.45
	var low := lintel - (lintel - opening - 0.45) * rng.randf_range(0.45, 0.7)
	blind.color = Color(0.5, 0.44, 0.32)
	blind.rect(Vector2((bl + br) * 0.5, (lintel + low) * 0.5), Vector2(br - bl, lintel - low), deep + 0.07)
	blind.color = Color(0.38, 0.32, 0.22)
	var y := low + 0.05
	while y < lintel:
		blind.rect(Vector2((bl + br) * 0.5, y), Vector2(br - bl, 0.012), deep + 0.075)
		y += 0.06
	blind.box(Vector3((bl + br) * 0.5, low, deep + 0.09), Vector3(br - bl + 0.04, 0.05, 0.05))
	add_child(blind.build())


## A polygon given for the right-hand side, mirrored to the left when
## `side` is -1 (kept wound the same way).
static func _mirror(points: PackedVector2Array, side: float) -> PackedVector2Array:
	if side > 0.0:
		return points
	var out := PackedVector2Array()
	for k in range(points.size() - 1, -1, -1):
		out.append(Vector2(-points[k].x, points[k].y))
	return out
