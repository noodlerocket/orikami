class_name GateWalls
extends RefCounted
## The walls that flank a gate (Julian: a gate standing alone, with empty
## gaps either side, looks as though anyone could walk round it). Behind the
## gate, a plastered wall on a dark tiled base runs back from its rear post
## (to the line of the houses); in front, a wing of the same wall, high
## enough to bar the way, runs out to a stout post with a lantern on a
## bracket. Both are capped with tiles, a timber band under the coping, pale
## grout on the base.
## `gx`, `g`: the gate's x and the ground; `back_post`, `front_post`: the z of
## its rear and front posts; `back_to`: how far back the wall runs (z);
## `front_to`: where the wing ends (z); `along`: optionally [left, right] of a
## stretch along x at the back (at `back_to`), to close a gap between houses.


static func build(parent: Node3D, market: LanternMarket, rng: RandomNumberGenerator, gx: float, g: float,
		back_post: float, front_post: float, back_to: float, front_to: float, along := Vector2.ZERO, height := 4.4) -> void:
	var w := PaperMesh.new(rng.randi())
	w.shade_jitter = 0.12
	var plaster := Color(0.6, 0.57, 0.53)
	var base := Color(0.15, 0.14, 0.18)
	var wing_h := minf(height - 1.0, 3.4)
	# Back, along z from the rear post.
	var bz := (back_post + back_to) * 0.5
	var bd := absf(back_post - back_to)
	w.color = base
	w.box(Vector3(gx, g + 0.6, bz), Vector3(0.5, 1.2, bd))
	w.color = plaster
	w.box(Vector3(gx, g + 1.2 + (height - 1.2) * 0.5, bz), Vector3(0.44, height - 1.2, bd))
	# Along x at the back, between houses.
	if along != Vector2.ZERO:
		var mid := (along.x + along.y) * 0.5
		var len := along.y - along.x
		w.color = base
		w.box(Vector3(mid, g + 0.6, back_to), Vector3(len, 1.2, 0.5))
		w.color = plaster
		w.box(Vector3(mid, g + 1.2 + (height - 1.2) * 0.5, back_to), Vector3(len, height - 1.2, 0.44))
		w.color = Color(0.5, 0.49, 0.5)
		var x := along.x + 0.3
		while x < along.y - 0.2:
			w.box(Vector3(x, g + 0.6, back_to + 0.26), Vector3(0.04, 1.1, 0.02))
			x += 0.55
		for y: float in [0.25, 0.6, 0.95]:
			w.box(Vector3(mid, g + y, back_to + 0.26), Vector3(len - 0.1, 0.04, 0.02))
		w.color = PaperMesh.TIMBER
		w.box(Vector3(mid, g + height - 0.1, back_to + 0.24), Vector3(len, 0.14, 0.06))
	# The wing in front, to its post.
	var fz := (front_post + front_to) * 0.5
	var fd := absf(front_to - front_post)
	w.color = base
	w.box(Vector3(gx, g + 0.6, fz), Vector3(0.5, 1.2, fd))
	w.color = plaster
	w.box(Vector3(gx, g + 1.2 + (wing_h - 1.2) * 0.5, fz), Vector3(0.44, wing_h - 1.2, fd))
	w.color = PaperMesh.TIMBER
	w.box(Vector3(gx + 0.24, g + wing_h - 0.5, fz), Vector3(0.06, 0.12, fd))
	w.color = PaperMesh.TIMBER.lightened(0.1)
	w.box(Vector3(gx, g + (wing_h + 0.4) * 0.5, front_to), Vector3(0.4, wing_h + 0.4, 0.4))
	parent.add_child(w.build())
	# Tiled coping on each.
	for part: Array in [[bz, bd, height], [fz, fd, wing_h]]:
		for side: float in [1.0, -1.0]:
			var cope := Scenery.tiled_roof(rng, -part[1] * 0.5 - 0.05, part[1] * 0.5 + 0.05, Vector2(g + part[2] - 0.05, 0.45 * side),
					Vector2(g + part[2] + 0.3, 0.0), 2, side > 0.0)
			cope.rotation.y = PI * 0.5
			cope.position = Vector3(gx, 0.0, part[0])
			parent.add_child(cope)
	if along != Vector2.ZERO:
		parent.add_child(Scenery.tiled_roof(rng, along.x - 0.1, along.y + 0.1, Vector2(g + height - 0.05, back_to + 0.5), Vector2(g + height + 0.4, back_to), 2))
		parent.add_child(Scenery.tiled_roof(rng, along.x - 0.1, along.y + 0.1, Vector2(g + height - 0.05, back_to - 0.5), Vector2(g + height + 0.4, back_to), 2, false))
	# A lantern on the wing's post, hung from a bracket.
	var bracket := PaperMesh.new(rng.randi())
	bracket.color = PaperMesh.TIMBER
	bracket.box(Vector3(gx - 0.37, g + wing_h - 0.1, front_to), Vector3(0.74, 0.07, 0.07))
	parent.add_child(bracket.build())
	market._hang(Vector3(gx - 0.62, g + wing_h - 0.13, front_to), 0.8, 0.12)
