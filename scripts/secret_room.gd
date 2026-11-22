class_name SecretRoom
extends Node3D
## A small storehouse standing in the street, with a back room you can only
## get into by cutting through its shoji door. From outside it is a plastered
## wall with a tiled roof (stand on the roof to get past it) and, at its left
## end, a sliding paper door lit faintly from inside.
## Cut the shoji: the paper tears open in scraps and the way in is clear.
## Step inside: the front wall fades so you can see the room, lit by one
## lantern, with something hidden on its shelf. Step out: the wall comes back.
## Origin: the street at the room's left wall (where the door is).

## Inside width (metres).
@export var width := 3.6
## Height of the walls (the roof sits on top).
@export var height := 2.5
## The door: in the left wall, this tall.
@export var door_height := 1.95

## Width of the shoji door at the front's left end.
const DOOR_WIDTH := 0.95

var ronin: Ronin
var opened := false

var _door_solid: StaticBody3D
var _door_paper: MeshInstance3D
var _door_target: PropTarget
var _front: Array[GeometryInstance3D] = []
var _seen := 0.0   # 0 = wall solid, 1 = faded (inside)
var _tears := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 41.0)
	_build(rng)


func _solid(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	add_child(body)
	return body


func _build(rng: RandomNumberGenerator) -> void:
	var left := 0.0
	var right := width
	var deep := 1.15
	# Solids: the right wall, the wall over the door, the roof slab. (The
	# floor is the street.)
	_solid(Vector3(right + 0.1, height * 0.5, 0.0), Vector3(0.2, height, 2.4))
	_solid(Vector3(left - 0.1, (door_height + height) * 0.5 + 0.02, 0.0), Vector3(0.2, height - door_height, 2.4))
	_solid(Vector3(width * 0.5, height + 0.25, 0.0), Vector3(width + 0.4, 0.5, 2.4))
	_door_solid = _solid(Vector3(left - 0.1, door_height * 0.5, 0.0), Vector3(0.2, door_height, 2.4))

	# The room inside: a dark back wall, a floor of boards, a shelf, and a
	# lantern.
	var inside := PaperMesh.new(rng.randi())
	inside.shade_jitter = 0.1
	inside.color = Scenery.WALL_DARK.darkened(0.3)
	inside.quad(Vector3(left, 0.0, -deep), Vector3(right, 0.0, -deep), Vector3(right, height, -deep), Vector3(left, height, -deep),
			Vector3.BACK)
	inside.color = Scenery.WOOD.darkened(0.35)
	inside.quad(Vector3(left, 0.02, deep), Vector3(right, 0.02, deep), Vector3(right, 0.02, -deep), Vector3(left, 0.02, -deep),
			Vector3.UP)
	inside.color = Scenery.WOOD.darkened(0.1)
	inside.box(Vector3(right - 0.9, 1.15, -deep + 0.2), Vector3(1.3, 0.06, 0.35))
	inside.box(Vector3(right - 0.9, 0.58, -deep + 0.12), Vector3(1.24, 1.15, 0.06))
	# Old stacked paper and a chest.
	inside.color = PaperMesh.WASHI.darkened(0.35)
	inside.box(Vector3(left + 0.7, 0.18, -deep + 0.4), Vector3(0.8, 0.36, 0.5))
	inside.color = Scenery.CRIMSON.darkened(0.35)
	inside.box(Vector3(left + 1.6, 0.25, -deep + 0.35), Vector3(0.6, 0.5, 0.45))
	# A bundle of folded paper cranes on the shelf (collecting them comes later).
	inside.color = PaperMesh.WASHI
	for k in 3:
		var c := Vector3(right - 1.25 + k * 0.28, 1.28, -deep + 0.22)
		inside.tri(c + Vector3(-0.12, 0.0, 0.0), c + Vector3(0.0, 0.1, 0.02), c + Vector3(0.02, -0.01, 0.06), Vector3.BACK)
		inside.tri(c + Vector3(0.0, 0.1, 0.02), c + Vector3(0.13, 0.03, 0.0), c + Vector3(0.02, -0.01, 0.06), Vector3.BACK)
	var room := inside.build()
	add_child(room)
	var lantern := Scenery.lantern(rng, 1.6, 0.6, 0.35)
	lantern.position = Vector3(right - 0.5, height - 0.05, -0.4)
	add_child(lantern)
	var glow := OmniLight3D.new()
	glow.light_color = PaperMesh.LANTERN
	glow.light_energy = 1.6
	glow.omni_range = 3.5
	glow.omni_attenuation = 2.0
	glow.position = Vector3(right - 0.5, height - 0.5, 0.4)
	add_child(glow)

	# The outside: the front wall (fades when he is inside), the side walls,
	# corner posts and beams, and the roof.
	var front := PaperMesh.new(rng.randi())
	front.shade_jitter = 0.06
	front.color = Scenery.WALL_PAPER
	# (The door's part of the front, at the left end, is the shoji itself.)
	front.quad(Vector3(left + DOOR_WIDTH, 0.0, deep + 0.05), Vector3(right + 0.2, 0.0, deep + 0.05),
			Vector3(right + 0.2, height, deep + 0.05), Vector3(left + DOOR_WIDTH, height, deep + 0.05), Vector3.BACK)
	front.quad(Vector3(left - 0.2, door_height, deep + 0.05), Vector3(left + DOOR_WIDTH, door_height, deep + 0.05),
			Vector3(left + DOOR_WIDTH, height, deep + 0.05), Vector3(left - 0.2, height, deep + 0.05), Vector3.BACK)
	# A storehouse wall: below, dark tiles set in a white diamond grid of
	# plaster (namako); above, white plaster, weathered at the top.
	var base := 0.95
	front.color = Color(0.17, 0.18, 0.24)
	front.rect(Vector2((left + DOOR_WIDTH + right + 0.2) * 0.5, base * 0.5), Vector2(right + 0.2 - left - DOOR_WIDTH, base), deep + 0.06)
	front.color = Color(0.62, 0.62, 0.64)
	var gx := left + DOOR_WIDTH - 0.6
	while gx < right + 0.2:
		for dir: float in [1.0, -1.0]:
			var a := Vector2(gx, 0.04 if dir > 0.0 else base - 0.04)
			var b := Vector2(gx + base - 0.08, base - 0.04 if dir > 0.0 else 0.04)
			# Clip the stroke to the wall's tiled part.
			var lo := left + DOOR_WIDTH + 0.02
			var hi := right + 0.18
			if b.x < lo or a.x > hi:
				continue
			var t0 := clampf((lo - a.x) / (b.x - a.x), 0.0, 1.0)
			var t1 := clampf((hi - a.x) / (b.x - a.x), 0.0, 1.0)
			front.stroke(a.lerp(b, t0), a.lerp(b, t1), 0.035, 0.035, deep + 0.065)
		gx += 0.42
	front.color = Scenery.WALL_STAIN
	for k in 3:
		front.stroke(Vector2(rng.randf_range(left + DOOR_WIDTH + 0.2, right - 0.2), height - 0.12),
				Vector2(rng.randf_range(left + DOOR_WIDTH + 0.2, right - 0.2), height - rng.randf_range(0.4, 0.8)), 0.16, 0.04, deep + 0.055)
	# A small window high up, with wooden bars and a heavy shutter beside it.
	var win := Vector2(right - 0.9, height - 0.65)
	front.color = Color(0.05, 0.05, 0.07)
	front.rect(win, Vector2(0.5, 0.42), deep + 0.06)
	front.color = PaperMesh.TIMBER
	for k in 4:
		front.rect(win + Vector2(-0.18 + k * 0.12, 0.0), Vector2(0.03, 0.42), deep + 0.07)
	front.rect(win, Vector2(0.6, 0.52), deep + 0.058)
	front.color = Color(0.5, 0.5, 0.52)
	front.rect(win + Vector2(-0.6, 0.0), Vector2(0.5, 0.5), deep + 0.062)
	front.color = PaperMesh.TIMBER
	# (The beams stop at the door's frame: they never cross the door.)
	var beam_mid := (left + DOOR_WIDTH + right + 0.2) * 0.5
	var beam_long := right + 0.2 - left - DOOR_WIDTH
	front.box(Vector3(beam_mid, 0.1, deep + 0.08), Vector3(beam_long, 0.2, 0.06))
	front.box(Vector3(beam_mid, 0.97, deep + 0.08), Vector3(beam_long, 0.08, 0.06))
	for px: float in [left - 0.1, right + 0.1]:
		front.box(Vector3(px, height * 0.5, deep + 0.08), Vector3(0.16, height, 0.08))
	front.color = Scenery.INK_DRIP
	for k in 4:
		var dx := rng.randf_range(0.3, width - 0.3)
		front.stroke(Vector2(dx, height - 0.18), Vector2(dx + 0.02, height - rng.randf_range(0.5, 0.9)), 0.03, 0.006,
				deep + 0.09)
	var front_mesh := front.build()
	front_mesh.transparency = 0.0
	add_child(front_mesh)
	_front.append(front_mesh)

	var shell := PaperMesh.new(rng.randi())
	shell.shade_jitter = 0.08
	shell.color = Scenery.WALL_DARK
	shell.quad(Vector3(right + 0.2, 0.0, deep), Vector3(right + 0.2, 0.0, -deep), Vector3(right + 0.2, height, -deep),
			Vector3(right + 0.2, height, deep), Vector3.RIGHT)
	shell.quad(Vector3(left - 0.2, door_height, -deep), Vector3(left - 0.2, door_height, deep), Vector3(left - 0.2, height, deep),
			Vector3(left - 0.2, height, -deep), Vector3.LEFT)
	shell.color = PaperMesh.TIMBER
	shell.box(Vector3(left - 0.12, door_height + 0.04, 0.0), Vector3(0.18, 0.1, deep * 2.0))
	add_child(shell.build())
	var roof_front := Scenery.tiled_roof(rng, left - 0.35, right + 0.35, Vector2(height - 0.05, deep + 0.35), Vector2(height + 0.5, 0.0), 5)
	add_child(roof_front)
	var roof_back := Scenery.tiled_roof(rng, left - 0.35, right + 0.35, Vector2(height - 0.05, -deep - 0.35), Vector2(height + 0.5, 0.0), 5, false)
	add_child(roof_back)

	# The shoji door, at the left end of the front: a lattice with paper, lit
	# faintly from the room behind it (a hint that there is a room).
	var door := PaperMesh.new(rng.randi())
	door.shade_jitter = 0.05
	# It fits between the corner post and its own frame (nothing past the corner).
	var door_lo := left - 0.02
	var door_hi := left + DOOR_WIDTH
	var door_mid := Vector2((door_lo + door_hi) * 0.5, door_height * 0.5)
	door.rect(door_mid, Vector2(door_hi - door_lo, door_height), deep + 0.05)
	_door_paper = door.build(Color(1.0, 0.8, 0.55), 0.7, true)
	add_child(_door_paper)
	var bars := PaperMesh.new(rng.randi())
	bars.color = PaperMesh.TIMBER
	for k in 4:
		var x := lerpf(door_lo, door_hi, k / 3.0)
		bars.box(Vector3(x, door_height * 0.5, deep + 0.08), Vector3(0.04 if k in [1, 2] else 0.08, door_height, 0.04))
	for k in 6:
		var y := lerpf(0.04, door_height, k / 5.0)
		bars.box(Vector3(door_mid.x, y, deep + 0.08), Vector3(door_hi - door_lo, 0.04 if k in [1, 2, 3, 4] else 0.08, 0.04))
	var lattice := bars.build()
	add_child(lattice)
	_door_paper.set_meta(&"lattice", lattice)
	# A faint glow on the street from the paper door.
	var spill := Scenery.halo(1.4, Color(1.0, 0.6, 0.28, 0.25))
	spill.position = Vector3(door_mid.x, door_height * 0.5, deep + 0.3)
	add_child(spill)
	_door_paper.set_meta(&"spill", spill)

	var box := BoxShape3D.new()
	box.size = Vector3(0.7, door_height, 1.0)
	_door_target = PropTarget.make(self, box, Vector3(left - 0.1, door_height * 0.5, 0.0))
	_door_target.struck.connect(_on_door_struck)


func _on_door_struck(_direction: Vector2) -> void:
	if opened:
		return
	_tears += 1
	Sound.play(self, &"paper_rip", -4.0 if _tears == 1 else 0.0)
	if _tears < 2:
		# The first cut slits the paper: it shudders.
		var shake := create_tween()
		shake.tween_property(_door_paper, "position:z", 0.04, 0.05)
		shake.tween_property(_door_paper, "position:z", -0.03, 0.06)
		shake.tween_property(_door_paper, "position:z", 0.0, 0.08)
		return
	opened = true
	Confetti.burst(get_parent(), global_position + Vector3(0.3, door_height * 0.55, 1.2), 36)
	_door_solid.queue_free()
	_door_target.queue_free()
	_door_paper.queue_free()
	(_door_paper.get_meta(&"lattice") as Node3D).queue_free()


func _process(delta: float) -> void:
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if ronin == null:
			return
	var local_x := ronin.global_position.x - global_position.x
	var inside := local_x > 0.0 and local_x < width and ronin.global_position.y < global_position.y + height
	_seen = move_toward(_seen, 1.0 if inside else 0.0, delta / 0.35)
	for mesh: GeometryInstance3D in _front:
		mesh.transparency = smoothstep(0.0, 1.0, _seen) * 0.92
