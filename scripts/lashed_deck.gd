class_name LashedDeck
extends Node3D
## A deck of dry bamboo poles lashed high in the stems of the Bamboo of
## Folded Wind (the woodcutters' platforms, long abandoned): where he lands
## between glides. Built so every piece holds on to something (Julian):
## two or three thick stems stand behind it on the ground below (`foot`);
## the back bearer is lashed to them; the cross poles lie on the back and
## front bearers; ropes run from the stems down to the front bearer's ends.
## It gives a little under him when he lands (a dip and a creak), then
## settles. Positions are the grove's own (it is a child of an area).

## Its left and right ends (grove x) and its walking height.
@export var left := 0.0
@export var right := 4.0
@export var top := 8.0
## The height of the ground its stems stand on.
@export var foot := 1.5
## How far the stems go on up above the deck (a "top" deck is near the
## stems' tops: they end just above it).
@export var stem_above := 6.0
## How far it dips when he lands, and how quickly it settles.
@export var dip := 0.07
@export var settle := 7.0

const STRAW := Color(0.62, 0.56, 0.34)
const BACK_Z := -1.15
## A stem he climbs stands just behind him (so he is seen in front of it),
## and is solid only from this high above its foot (he walks in under it).
const CLIMB_Z := -0.5
const CLIMB_CLEAR := 1.8

var grove: BambooGrove
var _deck: Node3D
var _sag := 0.0
var _sag_speed := 0.0
var _on := false
var _ronin: Ronin


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(left * 31.0 + top * 7.0)
	# The stems behind it, on the ground below: never swaying (it hangs on them).
	var stems := PaperMesh.new(rng.randi())
	stems.texture_world = false
	stems.shade_jitter = 0.08
	var at: Array[float] = [left + 0.18, right - 0.18]
	if right - left > 4.6:
		at.insert(1, (left + right) * 0.5)
	for x: float in at:
		stem(stems, Vector3(x, foot - 0.05, BACK_Z), top + stem_above - foot, rng.randf_range(0.2, 0.24), rng)
	add_child(stems.build())
	# The deck itself (it is what dips).
	_deck = Node3D.new()
	add_child(_deck)
	var b := PaperMesh.new(rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.12
	# Bearers along the back and front, under the poles.
	b.color = STRAW.darkened(0.25)
	for z: float in [BACK_Z + 0.25, 0.8]:
		b.box(Vector3((left + right) * 0.5, top - 0.17, z), Vector3(right - left + 0.25, 0.1, 0.1))
	# Cross poles, side by side, each its own shade of dried bamboo.
	var x := left + 0.04
	while x < right - 0.03:
		b.color = STRAW.lerp(BambooGrove.STEM_YELLOW, rng.randf_range(0.0, 0.5)).darkened(rng.randf_range(0.0, 0.18))
		b.box(Vector3(x + 0.045, top - 0.07, -0.08 + rng.randf_range(-0.04, 0.04)), Vector3(0.085, 0.08, 1.95 + rng.randf_range(-0.12, 0.05)))
		x += 0.095
	# Rope lashings: round each stem at the back bearer, and over the poles
	# at both ends.
	b.color = BambooGrove.ROPE
	for sx: float in at:
		for k in 3:
			b.box(Vector3(sx, top - 0.22 + k * 0.05, BACK_Z), Vector3(0.3, 0.025, 0.3))
	for ex: float in [left + 0.12, right - 0.12]:
		b.box(Vector3(ex, top - 0.02, -0.08), Vector3(0.05, 0.03, 2.0))
	# Hanging ropes: from each end stem, above, down to the front bearer.
	var hang := minf(stem_above * 0.6, 2.2)
	for ex: float in [at[0], at[at.size() - 1]]:
		var from := Vector3(ex, top + hang, BACK_Z + 0.12)
		var to := Vector3(ex + (0.1 if ex < (left + right) * 0.5 else -0.1), top - 0.12, 0.8)
		var along := to - from
		var mid := from + along * 0.5
		var rope := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = 0.014
		tube.bottom_radius = 0.014
		tube.height = along.length()
		tube.radial_segments = 5
		rope.mesh = tube
		var look := StandardMaterial3D.new()
		look.albedo_color = BambooGrove.ROPE
		rope.material_override = look
		_deck.add_child(rope)
		rope.position = mid
		rope.basis = Basis(Quaternion(Vector3.UP, along.normalized()))
	_deck.add_child(b.build())
	# What he stands on.
	if grove:
		var solid := grove._solid(Vector3((left + right) * 0.5, top - 0.15, 0.0), Vector3(right - left, 0.3, 1.9))
		solid.set_meta(&"no_climb", true)


## The marks of a stem he can climb (wall slide and wall jump), so it is
## plain at a glance (Julian): the woodcutters' climbing stems are cut dry
## and golden (every other stem is green: see `climb_stem`), bound with
## thick rope every so often, the loose ends hanging. (White paper strips
## tied to the ropes were removed: Julian.)
static func climb_marks(b: PaperMesh, x: float, z: float, from: float, to: float, w: float) -> void:
	var y := from + 0.7
	while y < to:
		b.color = BambooGrove.ROPE.darkened(0.12)
		for r in 4:
			b.frustum(8, Vector2(w * 1.24, w * 1.24), Vector2(w * 1.24, w * 1.24), 0.035, Vector3(x, y + r * 0.045, z))
		# The loose end, hanging down the front.
		b.color = BambooGrove.ROPE
		b.box(Vector3(x + w * 0.5, y - 0.12, z + w * 1.1), Vector3(0.03, 0.3, 0.03))
		y += 1.15


## A stem he can climb: the dry golden colour of cut, seasoned bamboo.
const CLIMB_STRAW := Color(0.72, 0.6, 0.3)


static func climb_stem(b: PaperMesh, foot_at: Vector3, height: float, w: float, rng: RandomNumberGenerator) -> void:
	stem(b, foot_at, height, w, rng, CLIMB_STRAW)


## A thick bamboo stem standing on the ground: sections with a dark ring and
## a pale band at each node (as the grove's own stems), into a builder.
static func stem(b: PaperMesh, foot_at: Vector3, height: float, w: float, rng: RandomNumberGenerator, tint: Color = Color(0, 0, 0, 0)) -> void:
	var green := BambooGrove.STEM.lerp(BambooGrove.STEM_YELLOW, rng.randf_range(0.1, 0.5))
	if tint.a > 0.0:
		green = tint.lerp(tint.lightened(0.1), rng.randf())
	var y := 0.0
	while y < height:
		var seg := minf(rng.randf_range(0.85, 1.3), height - y)
		b.color = green * rng.randf_range(0.94, 1.06)
		b.frustum(8, Vector2(w, w), Vector2(w * 0.99, w * 0.99), maxf(seg - 0.05, 0.02), foot_at + Vector3(0.0, y, 0.0))
		b.color = green.darkened(0.3)
		b.frustum(8, Vector2(w * 1.1, w * 1.1), Vector2(w * 1.1, w * 1.1), 0.035, foot_at + Vector3(0.0, y + seg - 0.05, 0.0))
		b.color = green.lightened(0.22)
		b.frustum(8, Vector2(w * 1.01, w * 1.01), Vector2(w, w), 0.05, foot_at + Vector3(0.0, y + seg - 0.1, 0.0))
		y += seg
		w *= 0.99
	# A cut top, pale inside.
	b.color = Color(0.82, 0.8, 0.6)
	b.frustum(8, Vector2(w * 0.85, w * 0.85), Vector2(w * 0.85, w * 0.85), 0.01, foot_at + Vector3(0.0, height, 0.0))


func _physics_process(delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var x := _ronin.global_position.x - global_position.x
	var on := (_ronin.is_on_floor() and x > left - 0.3 and x < right + 0.3
			and absf(_ronin.global_position.y - global_position.y - top) < 0.2)
	if on and not _on:
		# Landing: it gives, more the faster he came down.
		_sag_speed -= dip * 9.0
		Sound.play(self, &"plank_creak", -16.0)
	_on = on
	# A damped spring back to rest (lower while he stands on it).
	var rest := -dip * 0.35 if on else 0.0
	_sag_speed += ((rest - _sag) * settle * settle - _sag_speed * settle * 0.9) * delta
	_sag += _sag_speed * delta
	_deck.position.y = _sag
