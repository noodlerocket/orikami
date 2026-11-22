class_name CanopyRoad
extends Node3D
## The Canopy Road (Bamboo of Folded Wind, after the Windfall Gorge;
## docs/bamboo_map.png): the stems here grow taller and the woodcutters'
## decks are lashed high among them, a way through the treetops 9 to 17 m
## up, from deck to deck by glides and the rising gusts. Below, the forest
## floor is the plain way on (with its creatures); the high road is the
## harder, better one (a bundle of cranes on the highest deck).
## Up: two thick stems close together at its west end to wall-jump between.
## Coordinates are the grove's (a child of BambooGrove).

## The decks: [left, right, top, how far the stems go on above it].
const DECKS := [[297.0, 302.5, 9.5, 6.0], [308.0, 312.0, 14.0, 5.0], [315.5, 318.0, 15.6, 1.4],
	[324.0, 329.0, 12.5, 6.0], [335.0, 338.0, 18.5, 1.4], [341.0, 346.0, 12.0, 6.0]]
## The rising gusts: [x, how high (from the floor)].
const UPDRAFTS := [[305.0, 15.0], [332.0, 19.0]]
## The two stems to climb up between (x).
const CLIMB_STEMS := [294.9, 296.3]

var grove: BambooGrove
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 808
	var ground := float(BambooGrove.GROUND[4][2])
	for d: Array in DECKS:
		var deck := LashedDeck.new()
		deck.grove = grove
		deck.left = d[0]
		deck.right = d[1]
		deck.top = d[2]
		deck.stem_above = d[3]
		deck.foot = ground
		add_child(deck)
	for u: Array in UPDRAFTS:
		var draft := Updraft.new()
		draft.position = Vector3(u[0], ground, 0.0)
		draft.height = u[1]
		add_child(draft)
	# The climb: two stems, solid, from the floor to above the first deck.
	var b := PaperMesh.new(_rng.randi())
	b.texture_world = false
	b.shade_jitter = 0.08
	var top := float(DECKS[0][2]) + 1.6
	for x: float in CLIMB_STEMS:
		# (Feet just behind him, solid only above his head: he walks in under
		# them to the gap between and jumps up: Julian.)
		LashedDeck.climb_stem(b, Vector3(x, ground - 0.05, LashedDeck.CLIMB_Z), top + 7.0 - ground, 0.25, _rng)
		LashedDeck.climb_marks(b, x, LashedDeck.CLIMB_Z, ground, top, 0.25)
		var low := ground + LashedDeck.CLIMB_CLEAR
		grove._solid(Vector3(x, (low + top) * 0.5, 0.0), Vector3(0.48, top - low, 0.6)).set_meta(&"climbable", true)
	add_child(b.build())
	var bundle := CraneBundle.new()
	bundle.id = "canopy_top"
	bundle.count = 8
	bundle.position = Vector3(316.8, float(DECKS[2][2]), -0.6)
	add_child(bundle)
