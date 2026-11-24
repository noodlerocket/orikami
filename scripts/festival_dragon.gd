class_name FestivalDragon
extends Node3D
## The Festival Dragon, 祭龍 (Matsuri-ryū): the Lantern Market's mini-boss,
## fought in the Ward of Shut Doors (WardQuarter; docs/lantern_market_plan.md).
## One of the great paper dragons the market carried through its parades on
## poles; the Rain soaked it until its creases forgot what they were, and
## now it lives, writhing over the Ward, crushing houses, laughing.
##
## The head is a Meshy model (models/dragon_head.glb, picture
## docs/reference/dragon_head.png) given a jaw in code (ProceduralSkin). The
## long body is folded here: drums of red festival paper with gold rims and
## fins, cream belly plates, the parade poles still stuck through it, small
## clawed legs, ribbons. The body follows the path the head has taken (a
## trail of points), so wherever the head goes it writhes after it like a
## real serpent.
##
## Moves (each with a tell first):
##  - dive: it rears high at one end, roars, a pale streak marks the line,
##    then it plunges across the Ward at chest height. Duck under it, or
##    parry the head (gold): it is knocked down, stunned.
##  - rain breath: from one end, head low (a gout along the ground: jump)
##    or raised (at chest height: duck); ink gathers in its jaws first.
##  - lightning in its whiskers: dark wet stains spread where bolts will
##    fall, then they fall (several, in a rhythm, following him).
##  - coil and crush: it wraps a house, laughs on its roof and squeezes;
##    the coils in front can be cut. Then the house falls: jump the rubble.
##  - from half health, ribbons: its paper streamers tear loose and fly at
##    him in a rhythm (parry them: posture).
## Posture full: its head crashes down, jaw open, for a finishing cut.
## Coordinates: its parent's (the market's), like everything in the Ward.

signal health_changed(current: int, maximum: int)
signal posture_changed(current: int, maximum: int)
signal defeated
signal enraged
## A house it has crushed (its index in `houses`).
signal crushed(index: int)
## A crushed house standing again (he died: the fight starts over).
signal restored(index: int)

const HEAD_SCENE := preload("res://models/dragon_head.glb")
const RED := Color(0.5, 0.14, 0.11)
const GOLD := Color(0.62, 0.49, 0.25)
const CREAM := Color(0.74, 0.68, 0.55)
const INK := Color(0.05, 0.05, 0.08)
const TRAIL_STEP := 0.12

@export_group("Fight")
@export var max_health := 30
@export var max_posture := 6
@export var finish_damage := 4
## One point of posture drains away after this long without a parry.
@export var posture_recover_time := 3.0
## From half health its tells and rests are this much shorter.
@export var enraged_pace := 0.75
## Its rest between moves (seconds).
@export var rest_time := 1.2
@export_group("Dive")
@export var dive_tell := 1.1
@export var dive_speed := 15.0
## How far from him it rears before diving (m).
@export var dive_from := 14.0
## The head's middle above the ground as it crosses (its belly clears a
## ducking Ronin, not a standing one).
@export var dive_height := 1.9
## How long it lies stunned after its dive is parried.
@export var stun_time := 2.0
@export_group("Rain breath")
@export var breath_tell := 1.0
## How fast the gout of ink flies, and how long it is.
@export var breath_speed := 17.0
@export var breath_length := 6.0
## How far from him it breathes from (m).
@export var breath_from := 11.0
@export_group("Lightning")
## How long a stain shows before its bolt falls.
@export var bolt_mark_time := 0.85
@export var bolt_gap := 0.55
@export var bolt_count := 4
@export var bolt_radius := 1.0
@export_group("Coil and crush")
@export var coil_time := 2.6
## After its last coil, how long the house holds before it falls.
@export var collapse_tell := 0.3
## How far the rubble of a crushed house sweeps along the street (m).
@export var collapse_reach := 5.0
@export_group("Ribbons")
@export var ribbon_count := 3
@export var ribbon_gap := 0.65
## (Julian: faster; 10 was the first.)
@export var ribbon_speed := 15.0
@export_group("Stagger")
@export var stagger_time := 3.0
## How far inside the square's ends its head always stays (m).
@export var keep_inside := 2.5
@export_group("Body")
@export var segment_count := 30
@export var segment_gap := 0.62
@export var body_radius := 0.55
@export var head_scale := 1.5

## The Ward's fighting ground (market x), and its height.
var arena := Vector2(228.0, 270.0)
## The stretch clear of the walkways, where it comes down low.
var lane := Vector2(239.8, 258.6)
## Things it must never pass through (the Ward's red walkways): its head,
## every drum of its body and its ribbons keep out of these boxes (Julian:
## it went through the high platforms).
var obstacles: Array[AABB] = []
var ground := 6.5
## The houses it may crush (set by the Ward), and which still stand.
var houses: Array[Node3D] = []
var standing: Array[bool] = []
var ronin: Ronin
var active := false
var health := 30
var posture := 0

var head := Vector3.ZERO
var _vel := Vector3.ZERO
var _goal := Vector3.ZERO
var _direct := false
var _agility := 2.6
var _max_speed := 13.0
var _turn := Quaternion.IDENTITY
var _look := Vector3.ZERO
var _roll := 0.0
var _twitch := 0.0
var _twitch_clock := 1.0
var _jaw := 0.2
var _jaw_goal := 0.2
var _chatter := false
var _mode := &"perch"
var _mode_time := 0.0
var _time := 0.0
var _last_move := &""
var _since_crush := 2
var _enraged := false
var _posture_clock := 0.0
var _flash := 0.0
var _hit_clock := 0.0
var _rng := RandomNumberGenerator.new()

var _trail := PackedVector3Array()
var _segments: Array[Node3D] = []
var _seg_meshes: Array[MeshInstance3D] = []
var _streamers: Array[Node3D] = []
var _parts: Array[Part] = []
var _hard: Array[HardPart] = []
var _glance_clock := 0.0
var _bite_clock := 0.0
var _snap := 0.0
var _scorches: Array[Node3D] = []
## The great stone lantern's x (set by the Ward): its body never comes to
## rest on it when it falls.
var avoid_x := NAN
var _head_node: Node3D
var _skin: ProceduralSkin
var _head_mesh: MeshInstance3D
var _fallen := false

# The move in hand.
var _dir := 1.0
var _from := Vector3.ZERO
var _low := false
var _hit_done := false
var _count := 0
var _house := -1
var _theta := 0.0
var _jet_tip := 0.0
var _marks: Array = []      # [stain node, where, time left, struck]
var _ribbons: Array = []    # [node, velocity, life]
var _rose_at := -1.0
var _in_house := false
var _jolt := 0.0

# Effects.
var _streak: MeshInstance3D
var _shadow: MeshInstance3D
var _jet: MeshInstance3D
var _jet_drops: CPUParticles3D
var _gather: CPUParticles3D
var _sparks: CPUParticles3D
var _flash_light: OmniLight3D
var _puddles: Array = []    # [node, life]


## One of the bodies the Ronin's cut looks for: the head, or a stretch of
## the body (only while its coils can be cut).
class Part extends StaticBody3D:
	var dragon: FestivalDragon
	var is_head := false

	func take_hit(damage: int, direction: Vector2) -> void:
		dragon._struck(damage, direction, self)

	func is_staggered() -> bool:
		return dragon.is_staggered()


## A stretch of its body while it is not open to cuts: lacquered festival
## paper over a bamboo frame, hard. A cut glances off with a dull knock and
## he recoils (no harm to it, no ink for him: the Ronin treats it like a
## prop).
class HardPart extends StaticBody3D:
	var dragon: FestivalDragon

	func take_hit(_damage: int, _direction: Vector2) -> void:
		dragon._glance(self)

	func is_prop() -> bool:
		return true


func _ready() -> void:
	_rng.seed = 808
	_build_head()
	_build_body()
	_build_effects()
	health = max_health
	reset()


# --- Building it ---------------------------------------------------------------------

func _build_head() -> void:
	_head_node = Node3D.new()
	add_child(_head_node)
	var scene: Node3D = HEAD_SCENE.instantiate()
	var found: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
	var src := found[0] as MeshInstance3D
	_skin = ProceduralSkin.new()
	var skull := _skin.add_bone("skull", -1, Vector3.ZERO)
	_skin.add_bone("jaw", skull, Vector3(0.0, -0.06, -0.12))
	_skin.finish()
	_head_node.add_child(_skin.skeleton)
	# The jaw: everything under the line of the mouth (it slopes down toward
	# the snout), in front of the hinge. Measured from the model: the gap
	# between the teeth is at y -0.12 at z 0.3 and y -0.21 at z 0.7.
	_head_mesh = _skin.skin("dragon_head", src.mesh, src.get_active_material(0), func(v: Vector3) -> PackedFloat32Array:
		var split := -0.12 - 0.225 * (v.z - 0.3)
		var jaw := ProceduralSkin.ramp(split + 0.03, split - 0.03, v.y) * ProceduralSkin.ramp(-0.3, 0.02, v.z)
		return PackedFloat32Array([1.0 - jaw, jaw]))
	scene.free()
	var part := _part(1.3, true)
	_parts.push_front(part)


func _part(radius: float, is_head: bool) -> Part:
	var p := Part.new()
	p.dragon = self
	p.is_head = is_head
	p.collision_layer = 0
	p.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	p.add_child(shape)
	add_child(p)
	if not is_head:
		_parts.append(p)
	return p


## A drum of the body along z (length `l`, radius 1 scaled later): red
## festival paper blotched with ink, a gold rim at its front, a gold fin on
## top, cream plates underneath.
func _drum(seed_value: int) -> Mesh:
	var b := PaperMesh.new(seed_value)
	b.shade_jitter = 0.18
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var l := segment_gap * 1.3
	var r := body_radius
	var sides := 9
	var rings := [[-l * 0.5, 0.86], [0.0, 1.0], [l * 0.5, 0.88]]
	for k in rings.size() - 1:
		var z0: float = rings[k][0]
		var z1: float = rings[k + 1][0]
		var r0: float = rings[k][1] * r
		var r1: float = rings[k + 1][1] * r
		for i in sides:
			var a0 := TAU * i / sides + PI * 0.5
			var a1 := TAU * (i + 1) / sides + PI * 0.5
			var c0 := Vector2(cos(a0), sin(a0) * 1.08)
			var c1 := Vector2(cos(a1), sin(a1) * 1.08)
			b.color = RED * rng.randf_range(0.8, 1.12)
			if rng.randf() < 0.22:
				b.color = RED.lerp(INK, rng.randf_range(0.55, 0.8))
			elif rng.randf() < 0.12:
				b.color = GOLD.darkened(0.2)
			var mid := Vector3((c0.x + c1.x) * 0.5, (c0.y + c1.y) * 0.5, 0.0)
			b.quad(Vector3(c0.x * r0, c0.y * r0, z0), Vector3(c1.x * r0, c1.y * r0, z0),
					Vector3(c1.x * r1, c1.y * r1, z1), Vector3(c0.x * r1, c0.y * r1, z1), mid)
	# The gold rim round the front edge, like the hoop of a parade dragon.
	b.color = GOLD
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var o0 := Vector3(cos(a0), sin(a0) * 1.08, 0.0)
		var o1 := Vector3(cos(a1), sin(a1) * 1.08, 0.0)
		b.quad(o0 * r * 0.95 + Vector3(0, 0, l * 0.36), o1 * r * 0.95 + Vector3(0, 0, l * 0.36),
				o1 * r * 0.95 + Vector3(0, 0, l * 0.46), o0 * r * 0.95 + Vector3(0, 0, l * 0.46), (o0 + o1) * 0.5)
	# Cream belly plates.
	b.color = CREAM.darkened(0.15)
	b.box(Vector3(0.0, -r * 1.02, 0.0), Vector3(r * 1.05, 0.05, l * 0.8))
	# A torn gold fin along the back, both faces.
	b.color = GOLD.darkened(0.08)
	var top := r * 1.02
	var f0 := Vector3(0.0, top, -l * 0.45)
	var f1 := Vector3(0.0, top, l * 0.4)
	var f2 := Vector3(0.0, top + r * rng.randf_range(0.55, 0.8), -l * 0.3)   # (swept back)
	b.tri(f0, f1, f2, Vector3.RIGHT)
	b.tri(f0, f1, f2, Vector3.LEFT)
	return b.build().mesh


func _build_body() -> void:
	var meshes: Array[Mesh] = [_drum(11), _drum(23), _drum(37)]
	var look := PaperMesh.material()
	for i in segment_count:
		var seg := Node3D.new()
		add_child(seg)
		var m := MeshInstance3D.new()
		m.mesh = meshes[i % 3]
		m.material_override = look
		seg.add_child(m)
		_seg_meshes.append(m)
		_segments.append(seg)
		var taper := _taper(i)
		var extra := PaperMesh.new(100 + i)
		extra.shade_jitter = 0.15
		var r := body_radius
		if i % 5 == 3 and i < segment_count - 4:
			# A parade pole, still stuck through it, a gold cap at its foot.
			extra.color = PaperMesh.TIMBER.darkened(0.1)
			extra.box(Vector3(0.0, -r - 0.75, 0.0), Vector3(0.07, 1.6, 0.07))
			extra.color = GOLD.darkened(0.25)
			extra.box(Vector3(0.0, -r - 1.55, 0.0), Vector3(0.11, 0.08, 0.11))
			extra.color = CREAM.darkened(0.3)
			extra.box(Vector3(0.0, -r - 0.25, 0.0), Vector3(0.1, 0.18, 0.1))
		if i == 3 or i == 13:
			# Small clawed legs, folded, one each side.
			for side: float in [-1.0, 1.0]:
				extra.color = RED.darkened(0.15)
				extra.box(Vector3(side * r * 0.95, -r * 0.55, 0.05), Vector3(0.16, 0.55, 0.2))
				extra.box(Vector3(side * r * 1.05, -r * 0.95, 0.22), Vector3(0.14, 0.14, 0.42))
				extra.color = GOLD
				for c in 3:
					extra.frustum(4, Vector2(0.04, 0.04), Vector2.ZERO, 0.22,
							Vector3(side * r * 1.05 + (c - 1) * 0.06, -r * 1.02, 0.45), 0.0)
		if i >= segment_count - 2:
			# The tail's frayed tuft.
			extra.color = CREAM.darkened(0.1)
			for k in 6:
				var a := TAU * k / 6.0
				extra.box(Vector3(cos(a) * r * 0.4, sin(a) * r * 0.4, -segment_gap * 0.9), Vector3(0.05, 0.05, 0.9))
		var extra_mesh := extra.build()
		seg.add_child(extra_mesh)
		if i % 5 == 1 and i > 2 and i < segment_count - 3:
			# A paper streamer tied on, fluttering.
			var holder := Node3D.new()
			holder.position = Vector3(0.0, r * 0.9, 0.0)
			seg.add_child(holder)
			var s := PaperMesh.new(200 + i)
			s.color = GOLD if i % 2 == 0 else Color(0.62, 0.2, 0.15)
			for k in 4:
				var z0 := -k * 0.32
				s.quad(Vector3(-0.0, 0.0, z0), Vector3(0.0, 0.18, z0), Vector3(0.0, 0.16, z0 - 0.32), Vector3(0.0, 0.0, z0 - 0.32), Vector3.RIGHT)
				s.quad(Vector3(-0.0, 0.0, z0), Vector3(0.0, 0.18, z0), Vector3(0.0, 0.16, z0 - 0.32), Vector3(0.0, 0.0, z0 - 0.32), Vector3.LEFT)
			holder.add_child(s.build())
			holder.set_meta(&"phase", i * 0.7)
			_streamers.append(holder)
		if i % 3 == 1:
			_part(r * taper + 0.18, false)
			var hard := HardPart.new()
			hard.dragon = self
			hard.collision_layer = 0
			hard.collision_mask = 0
			var hold := CollisionShape3D.new()
			var ball := SphereShape3D.new()
			ball.radius = r * taper + 0.18
			hold.shape = ball
			hard.add_child(hold)
			add_child(hard)
			_hard.append(hard)
		seg.set_meta(&"taper", taper)


## The body thins toward the tail.
func _taper(i: int) -> float:
	var t := float(i) / maxf(segment_count - 1, 1)
	return 1.0 - 0.72 * pow(t, 1.6) + 0.08 * sin(t * PI)


func _build_effects() -> void:
	# The dive's line: a pale streak at the height it will cross, and its
	# shadow on the stones.
	var pale := StandardMaterial3D.new()
	pale.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pale.albedo_color = Color(0.9, 0.86, 0.78, 0.0)
	pale.disable_fog = true
	var strip := QuadMesh.new()
	strip.size = Vector2(1.0, 0.16)
	strip.material = pale
	_streak = MeshInstance3D.new()
	_streak.mesh = strip
	_streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_streak.visible = false
	add_child(_streak)
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.albedo_color = Color(0.02, 0.02, 0.05, 0.0)
	var band := QuadMesh.new()
	band.size = Vector2(1.0, 1.6)
	band.orientation = PlaneMesh.FACE_Y
	band.material = dark
	_shadow = MeshInstance3D.new()
	_shadow.mesh = band
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.visible = false
	add_child(_shadow)
	# The gout of black rainwater: streaming water (the waterfall's look,
	# run sideways: pale streaks racing along it, white where it breaks at
	# its head) over a dark core of ink, and drops flying off it. (A dark
	# band alone could not be seen against the night street.)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Tapered at both ends: thin where it leaves, swelling, then spraying
	# wide at its head (no hard straight ends).
	var along := [0.0, 0.12, 0.3, 0.7, 0.88, 1.0]
	var wide := [0.15, 0.75, 1.0, 1.0, 1.1, 0.5]
	for k in along.size() - 1:
		for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
			var i := k + int(corner.x)
			var x: float = along[i]
			st.set_uv(Vector2(corner.y, x))
			st.add_vertex(Vector3(x, (corner.y - 0.5) * (wide[i] as float), 0.0))
	var water := ShaderMaterial.new()
	water.shader = preload("res://shaders/waterfall.gdshader")
	water.set_shader_parameter(&"tint", Color(0.2, 0.24, 0.32, 0.95))
	water.set_shader_parameter(&"speed", 3.5)
	water.set_shader_parameter(&"columns", 9.0)
	_jet = MeshInstance3D.new()
	_jet.mesh = st.commit()
	_jet.material_override = water
	_jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_jet.visible = false
	add_child(_jet)
	_jet_drops = _ink_particles(90, 0.6, Vector2(0.18, 0.18))
	_jet_drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_jet_drops.gravity = Vector3(0.0, -9.0, 0.0)
	_jet_drops.spread = 25.0
	_jet_drops.initial_velocity_min = 1.0
	_jet_drops.initial_velocity_max = 4.0
	add_child(_jet_drops)
	# Ink gathering into its jaws before the breath.
	_gather = _ink_particles(40, 0.5, Vector2(0.12, 0.12))
	_gather.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_gather.emission_sphere_radius = 1.6
	_gather.radial_accel_min = -14.0
	_gather.radial_accel_max = -10.0
	_gather.gravity = Vector3.ZERO
	_gather.initial_velocity_max = 0.2
	add_child(_gather)
	# The crackle in its whiskers before lightning.
	_sparks = CPUParticles3D.new()
	_sparks.amount = 36
	_sparks.lifetime = 0.25
	_sparks.emitting = false
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = 1.4
	_sparks.spread = 180.0
	_sparks.gravity = Vector3.ZERO
	_sparks.initial_velocity_min = 1.5
	_sparks.initial_velocity_max = 3.5
	var mote := QuadMesh.new()
	mote.size = Vector2(0.05, 0.05)
	mote.material = WaterFx.bead_material(Color(0.82, 0.88, 1.0))
	_sparks.mesh = mote
	_sparks.local_coords = false
	add_child(_sparks)
	_flash_light = OmniLight3D.new()
	_flash_light.light_color = Color(0.78, 0.84, 1.0)
	_flash_light.omni_range = 14.0
	_flash_light.light_energy = 0.0
	add_child(_flash_light)


func _ink_particles(amount: int, life: float, size: Vector2) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.emitting = false
	p.local_coords = false
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.1))
	p.scale_amount_curve = shrink
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var bead := QuadMesh.new()
	bead.size = size
	bead.material = PaperMesh.soft_ink(INK)
	p.mesh = bead
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


# --- The fight: outside ------------------------------------------------------------

## Back where it waits, out of sight above the roofs, whole again (and the
## houses with it).
func reset() -> void:
	active = false
	health = max_health
	posture = 0
	_enraged = false
	_since_crush = 2
	_last_move = &""
	_fallen = false
	_set_mode(&"perch")
	_clear_effects()
	for i in houses.size():
		_restore_house(i)
	head = Vector3(arena.y + 12.0, ground + 18.0, -12.0)
	_vel = Vector3.ZERO
	_goal = head
	_direct = true
	_lay_trail(Vector3(1.0, 0.25, -0.3))
	for s: Node3D in _segments:
		s.visible = true
	visible = false


## The fight begins (after the intro).
func begin() -> void:
	active = true
	visible = true
	_direct = false
	_set_mode(&"hover")
	health_changed.emit(health, max_health)
	posture_changed.emit(posture, max_posture)


## The intro: it pours down off the roofs, sweeps over him and coils round
## the stone lantern at `lantern` (market coordinates), laughing.
func play_intro(lantern: Vector3) -> void:
	visible = true
	_from = lantern
	_set_mode(&"intro")
	_direct = false
	_agility = 2.2
	_max_speed = 16.0


## As it lies after the fight (a heap of wet festival paper), for a game
## loaded after it was beaten.
func lie_dead() -> void:
	visible = true
	active = false
	head = Vector3((lane.x + lane.y) * 0.5, ground + 0.75, 0.6)
	_lay_trail(Vector3(1.0, 0.0, -0.4))
	_place_body()
	_fall_apart(false)
	_set_mode(&"dead")


func is_staggered() -> bool:
	return _mode == &"stagger"


func mode() -> StringName:
	return _mode


func _set_mode(next: StringName) -> void:
	_mode = next
	_mode_time = 0.0
	_hit_done = false


func _pace() -> float:
	return enraged_pace if _enraged else 1.0


func _ronin_local() -> Vector3:
	return to_local(ronin.global_position) if ronin else Vector3(arena.x, ground, 0.0)


func _mid() -> float:
	return (arena.x + arena.y) * 0.5


# --- Being struck ---------------------------------------------------------------------

func _struck(damage: int, _direction: Vector2, _part_hit: Part) -> void:
	if not active or _mode in [&"perch", &"intro", &"dying", &"dead"]:
		return
	if _hit_clock > 0.0:
		return   # (one cut touching the head and a coil counts once)
	_hit_clock = 0.12
	if _mode == &"stagger":
		health -= finish_damage
		posture = 0
		posture_changed.emit(posture, max_posture)
		Confetti.burst(get_parent(), to_global(head), 40, [RED, GOLD, CREAM])
		Sound.play(self, &"paper_burst", 2.0)
		_rise()
	else:
		health -= damage
	_flash = 0.12
	health_changed.emit(maxi(health, 0), max_health)
	if health <= 0:
		_die()
		return
	if not _enraged and health <= max_health / 2:
		_enraged = true
		enraged.emit()
		Sound.play(self, &"dragon_roar", 2.0)


func _parried(cost: int) -> void:
	posture = mini(posture + cost, max_posture)
	_posture_clock = 0.0
	posture_changed.emit(posture, max_posture)
	if posture >= max_posture and _mode not in [&"dying", &"dead"]:
		_stagger()


func _stagger() -> void:
	_clear_moves()
	_set_mode(&"stagger")
	_direct = true
	_from = head
	Sound.play(self, &"stagger", 4.0)
	Sound.play(self, &"dragon_roar", -2.0)


func _rise() -> void:
	_set_mode(&"rise")
	_direct = false
	_goal = Vector3(head.x, ground + 6.0, -2.0)


func _die() -> void:
	_clear_moves()
	active = false
	_set_mode(&"dying")
	_direct = true
	_from = head
	posture = 0
	posture_changed.emit(posture, max_posture)
	defeated.emit()
	Sound.play(self, &"dragon_roar", 4.0)


# --- The fight: thinking ------------------------------------------------------------

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_mode_time += delta
	_flash -= delta
	_hit_clock -= delta
	_glance_clock -= delta
	_bite_clock -= delta
	_snap -= delta
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
	_think(delta)
	if active and _mode in [&"hover", &"dive_rise", &"dive_tell", &"dive_out", &"rise", &"breath_go", &"bolts_go", &"bolts",
			&"coil_go", &"ribbons_go", &"ribbons"]:
		_bite_check()
	if not _fallen:
		_steer(delta)
		if _mode != &"perch":
			# It never leaves the square: its head keeps `keep_inside` metres
			# from the walls of rain, and its body only follows where the head
			# has been (Julian: it went through the wall on the left).
			head.x = clampf(head.x, arena.x + keep_inside, arena.y - keep_inside)
			head = _clear_of(head, 1.15)
		_push_trail()
		_place_body()
		_pose_head(delta)
	_update_parts()
	_update_effects(delta)
	_update_ribbons(delta)
	_update_marks(delta)
	_flutter()
	var overlay := PaperHusk.flash_overlay() if _flash > 0.0 else null
	_head_mesh.material_overlay = overlay
	for m: MeshInstance3D in _seg_meshes:
		m.material_overlay = overlay


func _steer(delta: float) -> void:
	if _direct:
		return
	var want := (_route(_goal) - head) * _agility
	if want.length() > _max_speed:
		want = want.normalized() * _max_speed
	_vel = _vel.lerp(want, 1.0 - exp(-3.5 * delta))
	head += _vel * delta


## Moves the head straight to a point this frame (and notes its speed).
func _put(at: Vector3, delta: float) -> void:
	if delta > 0.0:
		_vel = (at - head) / delta
	head = at


func _weave(amount: float) -> Vector3:
	return Vector3(sin(_time * 0.9) * 2.0, sin(_time * 1.7) * 0.8, sin(_time * 0.6) * 0.5) * amount


func _think(delta: float) -> void:
	var r := _ronin_local()
	_chatter = false
	_look = Vector3.ZERO
	if active and _mode not in [&"stagger", &"dying", &"dead"]:
		_posture_clock += delta
		if posture > 0 and _posture_clock > posture_recover_time:
			_posture_clock = 0.0
			posture -= 1
			posture_changed.emit(posture, max_posture)
	match _mode:
		&"perch", &"dead":
			pass
		&"intro":
			_run_intro(delta, r)
		&"hover":
			_direct = false
			_agility = 2.6
			_max_speed = 13.0
			var off := clampf(r.x + (6.0 if r.x < _mid() else -6.0), lane.x, lane.y)
			_goal = Vector3(off, ground + 5.6, -1.8) + _weave(0.5)
			_jaw_goal = 0.25
			_look = r + Vector3(0.0, 1.0, 0.0)
			if _mode_time > rest_time * _pace():
				_choose(r)
		&"dive_rise":
			_goal = _from + _weave(0.2)
			_jaw_goal = 0.6
			_look = Vector3(_from.x + _dir * 6.0, ground + 1.0, 0.0)
			if head.distance_to(_from) < 2.0 or _mode_time > 1.8:
				_set_mode(&"dive_tell")
				Sound.play(self, &"dragon_roar")
				_streak.visible = true
				_shadow.visible = true
		&"dive_tell":
			_goal = _from + Vector3(-_dir * 1.2, 1.2, 0.0) * minf(_mode_time / 0.5, 1.0)
			_jaw_goal = 1.0
			_look = Vector3(_from.x + _dir * 6.0, ground + dive_height, 0.0)
			_line_alpha(minf(_mode_time / (dive_tell * _pace()), 1.0))
			if _mode_time > dive_tell * _pace():
				_set_mode(&"dive")
				_direct = true
				_from = head
		&"dive":
			_run_dive(delta, r)
		&"dive_out":
			_direct = false
			_line_alpha(maxf(0.0, 1.0 - _mode_time * 3.0))
			_goal = Vector3(clampf(head.x + _dir * 1.0, lane.x, lane.y), ground + 6.5, -1.8)
			_jaw_goal = 0.3
			if _mode_time > 0.9:
				_streak.visible = false
				_shadow.visible = false
				_set_mode(&"hover")
		&"stun":
			_run_down(delta, stun_time, false)
		&"stagger":
			_run_down(delta, stagger_time, true)
		&"rise":
			_direct = false
			_jaw_goal = 0.3
			if _mode_time > 0.6:
				_set_mode(&"hover")
		&"breath_go":
			_goal = _from
			_look = Vector3(_from.x + _dir * 5.0, _from.y - (0.8 if _low else 0.0), 0.0)
			_jaw_goal = 0.3
			if head.distance_to(_from) < 0.8 or _mode_time > 3.5:
				_set_mode(&"breath_tell")
				_direct = true
				_gather.emitting = true
				Sound.play(self, &"dragon_breath_in")
		&"breath_tell":
			var back := minf(_mode_time / 0.4, 1.0)
			_bite_check()
			_put(head.lerp(_from + Vector3(-_dir * 0.7 * back, (0.6 if not _low else -0.15) * back, 0.0), minf(1.0, delta * 8.0)), delta)
			_look = Vector3(_from.x + _dir * 5.0, _from.y - (0.9 if _low else -0.4), 0.0)
			_jaw_goal = 0.3 + 0.7 * back
			_gather.global_position = to_global(_mouth())
			if _mode_time > breath_tell * _pace():
				_gather.emitting = false
				_set_mode(&"breath")
				_jet_tip = 0.0
				Sound.play(self, &"dragon_breath", 2.0)
		&"breath":
			_run_breath(delta, r)
		&"bolts_go":
			_goal = Vector3(clampf(r.x, lane.x, lane.y), ground + 6.6, -1.8) + _weave(0.3)
			_look = r
			_jaw_goal = 0.5
			_sparks.emitting = true
			_sparks.global_position = to_global(head)
			if _mode_time > 0.7 * _pace():
				_set_mode(&"bolts")
				_count = 0
		&"bolts":
			_goal = Vector3(clampf(r.x, lane.x, lane.y), ground + 6.6, -1.8) + _weave(0.3)
			_look = r
			_sparks.global_position = to_global(head)
			_jaw_goal = 0.5 + 0.4 * absf(sin(_mode_time * 6.0))
			if _count < bolt_count and _mode_time > _count * bolt_gap * _pace():
				_count += 1
				_mark_bolt(r)
			if _count >= bolt_count and _marks.is_empty():
				_sparks.emitting = false
				_set_mode(&"hover")
		&"coil_go":
			_goal = _coil_point(0.0)
			_look = Vector3.ZERO
			if head.distance_to(_goal) < 1.2 or _mode_time > 2.5:
				_set_mode(&"coil")
				_direct = true
				Sound.play(self, &"dragon_roar", -4.0)
		&"coil":
			var t := minf(_mode_time / (coil_time * _pace()), 1.0)
			_put(_coil_point(t), delta)
			_jaw_goal = 0.9
			_pierce_check()
			_jolt = move_toward(_jolt, 0.0, delta * 0.25)
			_squeeze_house(0.0, _jolt)
			if t >= 1.0:
				# Wrapped through it twice: it falls at once (Julian: no long
				# squeeze).
				_set_mode(&"collapse_tell")
				_from = head
				Sound.play(self, &"plank_snap", 2.0)
		&"collapse_tell":
			_chatter = true
			_jaw_goal = 0.8
			_look = r + Vector3(0.0, 1.0, 0.0)
			_squeeze_house(0.6, 0.05)
			if _mode_time > collapse_tell * _pace():
				_collapse(r)
				Sound.play(self, &"dragon_laugh", 0.0)
		&"ribbons_go":
			_goal = _from + _weave(0.3)
			_look = r + Vector3(0.0, 1.0, 0.0)
			_jaw_goal = 0.4
			if head.distance_to(_from) < 1.5 or _mode_time > 1.8:
				_set_mode(&"ribbons")
				_count = 0
				Sound.play(self, &"paper_rip", 2.0)
		&"ribbons":
			_goal = _from + _weave(0.3)
			_look = r + Vector3(0.0, 1.0, 0.0)
			_jaw_goal = 0.6
			if _count < ribbon_count and _mode_time > 0.3 + _count * ribbon_gap * _pace():
				_count += 1
				_throw_ribbon(r)
			if _count >= ribbon_count and _mode_time > 0.3 + ribbon_count * ribbon_gap * _pace() + 0.6:
				_set_mode(&"hover")
		&"dying":
			_run_dying(delta)


func _choose(r: Vector3) -> void:
	var options: Array[StringName] = [&"dive", &"dive", &"breath", &"breath", &"bolts"]
	if _enraged:
		options.append_array([&"ribbons", &"ribbons", &"bolts"])
	if _since_crush >= 2 and standing.has(true):
		options.append_array([&"coil", &"coil"])
	var fresh := options.filter(func(o: StringName) -> bool: return o != _last_move)
	if not fresh.is_empty():
		options.assign(fresh)
	start_move(options[_rng.randi() % options.size()])


## Begins a move ("dive", "breath", "bolts", "coil", "ribbons"; the checks
## and frame sheets also call it to see each one).
func start_move(move: StringName) -> void:
	var r := _ronin_local()
	_direct = false
	_agility = 3.2
	_max_speed = 17.0
	_last_move = move
	_since_crush += 1
	match move:
		&"dive":
			# From the end farther from him, across toward him.
			_dir = 1.0 if r.x > _mid() else -1.0   # (from the side with more room)
			if _dir > 0.0:
				_from = Vector3(clampf(r.x - dive_from, lane.x, lane.y - 8.0), ground + 7.0, -1.8)
			else:
				_from = Vector3(clampf(r.x + dive_from, lane.x + 8.0, lane.y), ground + 7.0, -1.8)
			_set_mode(&"dive_rise")
		&"breath":
			_dir = 1.0 if r.x > _mid() else -1.0   # (from the side with more room)
			_low = _rng.randf() < 0.5
			_from = Vector3(clampf(r.x - _dir * breath_from, lane.x, lane.y), ground + (1.35 if _low else 2.0), 0.0)
			_set_mode(&"breath_go")
		&"bolts":
			_set_mode(&"bolts_go")
			Sound.play(self, &"whisker_crackle")
		&"coil":
			_since_crush = 0
			_house = _nearest_house(r.x)
			if _house < 0:
				_set_mode(&"hover")
				return
			_in_house = false
			_set_mode(&"coil_go")
		&"ribbons":
			_dir = 1.0 if r.x > _mid() else -1.0   # (from the side with more room)
			_from = Vector3(_start_x(r.x, 9.0), ground + 5.4, -1.8)
			_set_mode(&"ribbons_go")


# --- The moves ----------------------------------------------------------------------

## Where a move starts: `away` metres from him on the side it comes from
## (the side with more room), inside the square, so both are in the picture.
func _start_x(rx: float, away: float) -> float:
	var x := rx - _dir * away
	return clampf(x, lane.x, lane.y)

## The intro, by the clock: over the roofs (0 to 1.6 s), sweeping low over
## him (to 3.2), round the stone lantern (to 5.0), then laughing on it.
func _run_intro(delta: float, r: Vector3) -> void:
	var t := _mode_time
	var l := _from
	if t < 1.6:
		_goal = Vector3(_mid() + 6.0, ground + 7.5, -2.6)
	elif t < 3.2:
		_goal = Vector3(clampf(r.x + 6.0, lane.x + 1.0, lane.y - 1.0), ground + 3.0, 0.4)
		_max_speed = 18.0
	elif t < 5.0:
		if not _direct:
			_direct = true
			_theta = atan2(head.z - l.z, head.x - l.x)
		var k := (t - 3.2) / 1.8
		_theta += delta * TAU * 0.85
		var target := Vector3(l.x + cos(_theta) * 1.7, ground + lerpf(1.2, 4.2, k), l.z + sin(_theta) * 1.5)
		_put(head.lerp(target, minf(1.0, delta * 8.0)), delta)
		_jaw_goal = 0.4
	else:
		var perch := Vector3(l.x + 0.4, ground + 5.4, l.z + 0.8)
		_put(head.lerp(perch, minf(1.0, delta * 3.0)), delta)
		_look = r + Vector3(0.0, 1.0, 0.0)
		_chatter = t > 5.2 and t < 7.4
		_jaw_goal = 0.6


func _run_dive(delta: float, r: Vector3) -> void:
	var entry := Vector3(_from.x + _dir * 3.5, ground + dive_height, 0.0)
	var drop := 0.4 * _pace()
	if _mode_time < drop:
		var k := _mode_time / drop
		var at := _from.lerp(entry, k * k)
		at.y = lerpf(_from.y, entry.y, 1.0 - (1.0 - k) * (1.0 - k) * 0.3) if k > 0.0 else _from.y
		_put(at, delta)
	else:
		var x := head.x + _dir * dive_speed * delta
		_put(Vector3(x, ground + dive_height + 0.12 * sin(_mode_time * 9.0), 0.0), delta)
	_jaw_goal = 1.0
	_line_alpha(1.0)
	if not _hit_done and ronin and _hits_ronin(head + Vector3(_dir * 0.9, -0.1, 0.0), 0.95):
		_hit_done = true
		if ronin.receive_strike(1, to_global(head), &"ink"):
			_parried(2)
			if _mode != &"stagger":
				_set_mode(&"stun")
				_from = head
			return
	var end := lane.y if _dir > 0.0 else lane.x
	if (head.x - end) * _dir > 0.0:
		_set_mode(&"dive_out")


## Knocked down: thrown back and up, then crashed to the ground, jaw open,
## lying still (`finishing`: a stagger, the finishing cut's chance).
func _run_down(delta: float, hold: float, finishing: bool) -> void:
	_line_alpha(0.0)
	_streak.visible = false
	_shadow.visible = false
	var lie := Vector3(clampf(_from.x, lane.x, lane.y), ground + 0.85, 0.5)
	if _mode_time < 0.3:
		var up := _from + Vector3(-_dir * 1.6, 1.6, 0.0)
		_put(_from.lerp(up, _mode_time / 0.3), delta)
	elif _mode_time < 0.65:
		var k := (_mode_time - 0.3) / 0.35
		var up := _from + Vector3(-_dir * 1.6, 1.6, 0.0)
		_put(up.lerp(lie, k * k), delta)
		if _mode_time + delta >= 0.65:
			Sound.play(self, &"land", 4.0)
			Confetti.burst(get_parent(), to_global(lie) + Vector3(0.0, -0.6, 0.0), 14, [RED, GOLD])
	else:
		_put(lie + Vector3(0.0, 0.03 * sin(_mode_time * 3.0), 0.0), delta)
	_jaw_goal = 1.0 if finishing else 0.8
	_roll = lerpf(_roll, 0.45 if finishing else 0.25, minf(1.0, delta * 6.0))
	_look = lie + Vector3(_dir * 4.0, -0.4, 0.0)
	if _mode_time > hold * (1.0 if finishing else _pace()) + 0.65:
		_roll = 0.0
		_rise()


func _mouth() -> Vector3:
	var forward := Basis(_turn) * Vector3.BACK
	return head + forward * 1.3 * head_scale / 1.5 + Vector3(0.0, -0.25, 0.0)


func _run_breath(delta: float, r: Vector3) -> void:
	_put(head.lerp(_from + Vector3(-_dir * 0.2, 0.0, 0.0), minf(1.0, delta * 6.0)), delta)
	_jaw_goal = 1.0
	_look = Vector3(_from.x + _dir * 5.0, _from.y - (0.9 if _low else 0.0), 0.0)
	var mouth := _mouth()
	_jet_tip += breath_speed * delta
	var far := arena.y if _dir > 0.0 else arena.x
	var span := absf(far - mouth.x)
	var tip := minf(_jet_tip, span)
	var tail := clampf(_jet_tip - breath_length, 0.0, span)
	var band := Vector2(ground + 0.05, ground + 0.8) if _low else Vector2(ground + 1.15, ground + 2.2)
	if tip - tail > 0.05:
		_jet.visible = true
		var mid := mouth.x + _dir * (tip + tail) * 0.5
		_jet.position = Vector3(mouth.x + _dir * tail, (band.x + band.y) * 0.5, 0.15)
		_jet.scale = Vector3((tip - tail) * _dir, (band.y - band.x) * (0.8 + 0.1 * sin(_time * 30.0)), 1.0)
		_jet_drops.emitting = true
		_jet_drops.emission_box_extents = Vector3((tip - tail) * 0.5, (band.y - band.x) * 0.4, 0.3)
		_jet_drops.global_position = to_global(Vector3(mid, (band.x + band.y) * 0.5, 0.15))
		_jet_drops.direction = Vector3(_dir, 0.3, 0.0)
		if ronin and _hits_box(Vector3(mid, (band.x + band.y) * 0.5, 0.0), Vector3(tip - tail, band.y - band.x, 1.2)):
			ronin.take_damage(1, to_global(mouth), &"ink")
		if _rng.randf() < delta * 8.0:
			_puddle(Vector3(mouth.x + _dir * _rng.randf_range(tail, tip), ground + 0.02, _rng.randf_range(-0.6, 0.8)))
	else:
		_jet.visible = false
	if tail >= span - 0.05:
		_jet.visible = false
		_jet_drops.emitting = false
		_set_mode(&"hover")


func _mark_bolt(r: Vector3) -> void:
	# Aimed where he will be when it falls (he runs on: it leads him).
	var lead := 0.0
	if ronin:
		lead = clampf(ronin.velocity.x * bolt_mark_time * _pace() * 0.7, -3.0, 3.0)
	var x := clampf(r.x + lead + _rng.randf_range(-0.1, 0.1), arena.x + 1.0, arena.y - 1.0)
	# The surface under that spot: the stones or a roof.
	var from := to_global(Vector3(x, ground + 14.0, 0.0))
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0.0, -20.0, 0.0), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var y := ground
	if not hit.is_empty():
		y = to_local(hit["position"]).y
	var stain := MeshInstance3D.new()
	var disc := QuadMesh.new()
	disc.size = Vector2(bolt_radius * 2.2, bolt_radius * 2.2)
	disc.orientation = PlaneMesh.FACE_Y
	var look := PaperMesh.soft_ink(Color(0.03, 0.03, 0.07, 0.85), BaseMaterial3D.BILLBOARD_DISABLED)
	disc.material = look
	stain.mesh = disc
	stain.position = Vector3(x, y + 0.03, 0.2)
	stain.scale = Vector3.ONE * 0.1
	stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stain)
	_marks.append([stain, Vector3(x, y, 0.0), bolt_mark_time * _pace(), false])
	Sound.play(self, &"ink_bleed", -10.0)


func _update_marks(delta: float) -> void:
	for i in range(_marks.size() - 1, -1, -1):
		var m: Array = _marks[i]
		var stain: MeshInstance3D = m[0]
		m[2] -= delta
		if not m[3]:
			stain.scale = Vector3.ONE * lerpf(0.1, 1.0, clampf(1.0 - m[2] / (bolt_mark_time * _pace()), 0.0, 1.0))
			if m[2] <= 0.0:
				m[3] = true
				m[2] = 0.6
				_bolt(m[1])
		else:
			stain.scale = Vector3.ONE * (1.0 + (0.6 - m[2]) * 0.4)
			(stain.mesh as QuadMesh).material.albedo_color.a = maxf(m[2] / 0.6, 0.0) * 0.85
			if m[2] <= 0.0:
				stain.queue_free()
				_marks.remove_at(i)


## A bolt out of the storm at `at.x`: a jagged white crack of light all the
## way down to the stones, through any walkway in its way (it burns a hole in
## each), a flash; it burns him anywhere in its path (Julian: a walkway is no
## shelter from it).
func _bolt(at: Vector3) -> void:
	for box: AABB in obstacles:
		if at.x > box.position.x + 0.1 and at.x < box.end.x - 0.1:
			_burn_hole(Vector3(at.x, box.end.y - 2.0 + 0.02, 0.0))
	at.y = ground
	var b := PaperMesh.new(_rng.randi())
	b.color = Color(0.94, 0.95, 1.0)
	var x := at.x
	var y := at.y + 18.0
	var prev := Vector2(x + _rng.randf_range(-1.0, 1.0), y)
	while y > at.y:
		y = maxf(y - _rng.randf_range(0.8, 1.8), at.y)
		var next := Vector2(x + _rng.randf_range(-0.5, 0.5) if y > at.y else x, y)
		b.stroke(prev, next, 0.14, 0.12, 0.0)
		if _rng.randf() < 0.25 and y > at.y + 2.0:
			var fork := next + Vector2(_rng.randf_range(-1.2, 1.2), -_rng.randf_range(0.6, 1.4))
			b.stroke(next, fork, 0.07, 0.02, 0.0)
		prev = next
	var bolt := b.build(Color.WHITE, 2.5, true)
	bolt.position.z = 0.25
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bolt)
	var fade := create_tween()
	fade.tween_interval(0.12)
	fade.tween_callback(bolt.queue_free)
	_flash_light.position = at + Vector3(0.0, 2.0, 1.5)
	_flash_light.light_energy = 6.0
	Sound.play(self, &"thunder_crack", 0.0)
	var sparks := CPUParticles3D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 22
	sparks.lifetime = 0.5
	sparks.spread = 70.0
	sparks.direction = Vector3.UP
	sparks.gravity = Vector3(0.0, -9.0, 0.0)
	sparks.initial_velocity_min = 2.0
	sparks.initial_velocity_max = 5.0
	var mote := QuadMesh.new()
	mote.size = Vector2(0.05, 0.05)
	mote.material = WaterFx.bead_material(Color(1.0, 0.8, 0.5))
	sparks.mesh = mote
	add_child(sparks)
	sparks.position = at + Vector3(0.0, 0.1, 0.3)
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
	if ronin:
		var r := _ronin_local()
		if absf(r.x - at.x) < bolt_radius and r.y > at.y - 0.6:
			ronin.take_damage(1, to_global(Vector3(at.x, r.y + 1.0, 0.0)), &"fire")


## A hole burnt through a walkway's boards where a bolt went through:
## charred, with a glowing ember rim and smoke curling up. (They stay until
## the fight starts over or is won.)
func _burn_hole(at: Vector3) -> void:
	var hole := PaperMesh.new(_rng.randi())
	var ring := PackedVector2Array()
	for k in 11:
		var a := TAU * k / 11.0
		ring.append(Vector2(cos(a), sin(a)) * _rng.randf_range(0.3, 0.5))
	hole.color = Color(0.03, 0.02, 0.02)
	hole.torn_sheet(PaperMesh.tear(ring, 0.1, 0.06, _rng), 0.0, Color(0.95, 0.45, 0.15), 0.05)
	var mesh := hole.build(Color.WHITE, 0.0, true)
	mesh.rotation.x = -PI * 0.5
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	var under := hole.build(Color.WHITE, 0.0, true)   # (seen from below too)
	under.rotation.x = PI * 0.5
	under.position = at - Vector3(0.0, 0.34, 0.0)
	add_child(under)
	var smoke := _ink_particles(10, 1.6, Vector2(0.4, 0.4))
	(smoke.mesh as QuadMesh).material = PaperMesh.soft_ink(Color(0.25, 0.24, 0.27, 0.35))
	smoke.direction = Vector3.UP
	smoke.gravity = Vector3(0.0, 0.6, 0.0)
	smoke.initial_velocity_min = 0.3
	smoke.initial_velocity_max = 0.6
	smoke.position = at + Vector3(0.0, 0.1, 0.0)
	add_child(smoke)
	smoke.emitting = true
	_scorches.append_array([mesh, under, smoke])


func _nearest_house(x: float) -> int:
	var best := -1
	var best_d := INF
	for i in houses.size():
		if standing[i] and absf(houses[i].position.x - x) < best_d:
			best_d = absf(houses[i].position.x - x)
			best = i
	return best


## A point on the coil round the house it is crushing (t from 0 to 1: two
## turns, rising from near the ground to its eaves). The coil's front comes
## out to the street, where he can cut it.
func _coil_point(t: float) -> Vector3:
	var house := houses[_house]
	var h: Vector3 = (house.get_meta(&"rest") as Transform3D).origin
	var half: float = house.get_meta(&"half", 3.0)
	var tall: float = house.get_meta(&"height", 5.8)
	var a := PI * 0.5 + t * TAU * 2.0 * (1.0 if int(h.x) % 2 == 0 else -1.0)
	# Inside its side walls, so it bursts in and out through the front and
	# the back; the front of each coil comes out into the street.
	var rx := half * 0.7
	var middle := h.z - 1.8
	var s := sin(a)
	var rz := (0.35 - middle) if s > 0.0 else 1.4   # (out to the street; not out of its back)
	return Vector3(h.x + cos(a) * rx, ground + 1.1 + t * (tall - 1.6), middle + s * rz)


## Each time its head bursts through a wall of the house: a splintering
## crunch, the house jolts, paper and boards burst out, and a torn hole is
## left in the wall (it stays until the house falls).
func _pierce_check() -> void:
	var house := houses[_house]
	var h: Vector3 = (house.get_meta(&"rest") as Transform3D).origin
	var half: float = house.get_meta(&"half", 3.0)
	var tall: float = house.get_meta(&"height", 5.8)
	var local := head - h
	var inside := absf(local.x) < half and local.z < 0.0 and local.z > -3.6 and local.y < tall
	if inside == _in_house:
		return
	_in_house = inside
	_jolt = 0.05
	Sound.play(self, &"wall_pierce", 1.0)
	var at := head
	# Which wall: the front (the one he sees) gets the hole.
	if absf(local.z) < 0.9 and local.y < tall - 0.4:
		at = h + Vector3(local.x, local.y, 0.0)
		var hole := PaperMesh.new(_rng.randi())
		var ring := PackedVector2Array()
		var r := _rng.randf_range(0.75, 1.0)
		for k in 12:
			var a := TAU * k / 12.0
			ring.append(Vector2(cos(a) * r * _rng.randf_range(0.7, 1.15), sin(a) * r * 1.1 * _rng.randf_range(0.7, 1.15)))
		hole.color = Color(0.02, 0.02, 0.03)
		hole.torn_sheet(PaperMesh.tear(ring, 0.15, 0.1, _rng), 0.0, Scenery.WALL_PAPER_RIM, 0.06)
		# Splinters of the boards round it.
		hole.color = Color(0.5, 0.42, 0.32)
		for k in 6:
			var a := _rng.randf_range(0.0, TAU)
			var p := Vector2(cos(a), sin(a)) * r * 0.95
			hole.stroke(p, p * _rng.randf_range(1.25, 1.5), 0.05, 0.0, 0.01)
		var mesh := hole.build()
		mesh.set_meta(&"hole", true)
		mesh.position = Vector3(local.x, local.y, 0.15)
		house.add_child(mesh)
	Confetti.burst(get_parent(), to_global(at), 26, [Scenery.WALL_DARK, Color(0.62, 0.58, 0.52), PaperMesh.TIMBER])


func _squeeze_house(k: float, shake: float) -> void:
	if _house < 0:
		return
	var house := houses[_house]
	var rest: Transform3D = house.get_meta(&"rest")
	house.transform = rest
	house.scale = Vector3(1.0 - 0.07 * k, 1.0 - 0.1 * k, 1.0 - 0.05 * k)
	house.rotation.z = shake * sin(_time * 37.0)
	house.position.x = rest.origin.x + shake * 0.6 * sin(_time * 29.0)


func _collapse(r: Vector3) -> void:
	var house := houses[_house]
	var rest: Transform3D = house.get_meta(&"rest")
	standing[_house] = false
	# It buckles and drops; then (the Ward) it is a ruin.
	var index := _house
	var fall := create_tween().set_parallel()
	fall.tween_property(house, "scale", Vector3(1.04, 0.45, 1.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(house, "rotation:z", 0.06 * (1.0 if _rng.randf() < 0.5 else -1.0), 0.22)
	fall.tween_property(house, "position:x", rest.origin.x, 0.15)
	fall.chain().tween_callback(func() -> void: crushed.emit(index))
	Sound.play(self, &"house_crush", 4.0)
	Confetti.burst(get_parent(), to_global(rest.origin + Vector3(0.0, 2.0, 2.0)), 50,
			[Scenery.WALL_DARK, PaperMesh.TIMBER, Color(0.3, 0.3, 0.36)])
	# The rubble sweeps out along the street: off his feet he is clear.
	var dust := _ink_particles(70, 0.9, Vector2(0.3, 0.3))
	(dust.mesh as QuadMesh).material = PaperMesh.soft_ink(Color(0.3, 0.29, 0.33, 0.6))
	dust.one_shot = true
	dust.explosiveness = 0.9
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(collapse_reach, 0.2, 0.6)
	dust.direction = Vector3(0.0, 1.0, 0.4)
	dust.spread = 60.0
	dust.gravity = Vector3(0.0, -3.0, 0.0)
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 3.0
	add_child(dust)
	dust.position = Vector3(rest.origin.x, ground + 0.2, 0.0)
	dust.emitting = true
	dust.finished.connect(dust.queue_free)
	if ronin and ronin.is_on_floor() and absf(r.x - rest.origin.x) < collapse_reach and r.y < ground + 1.0:
		ronin.take_damage(1, to_global(rest.origin), &"cut")
	_set_mode(&"hover")


func _restore_house(i: int) -> void:
	var house := houses[i]
	if house.has_meta(&"rest"):
		house.transform = house.get_meta(&"rest")
	house.visible = true
	for c: Node in house.get_children():
		if c.has_meta(&"hole"):
			c.queue_free()
	standing[i] = true
	restored.emit(i)


func _throw_ribbon(r: Vector3) -> void:
	# Torn from its mane, by its head.
	var from: Vector3 = head + Vector3(0.0, 0.4, 0.0)
	var aim := Vector3(r.x, r.y + 1.15, 0.0)
	if ronin:
		# Where he will be when it gets there.
		var t := from.distance_to(aim) / ribbon_speed
		aim.x += clampf(ronin.velocity.x * t * 0.8, -3.0, 3.0)
	var ribbon := Node3D.new()
	var b := PaperMesh.new(_rng.randi())
	b.color = Color(0.66, 0.2, 0.15)
	for k in 5:
		var x0 := -k * 0.3
		var y0 := 0.08 * sin(k * 1.3)
		var y1 := 0.08 * sin((k + 1) * 1.3)
		b.quad(Vector3(x0, y0 - 0.12, 0.0), Vector3(x0 - 0.3, y1 - 0.1, 0.0), Vector3(x0 - 0.3, y1 + 0.1, 0.0), Vector3(x0, y0 + 0.12, 0.0), Vector3.BACK)
		b.quad(Vector3(x0, y0 - 0.12, 0.0), Vector3(x0 - 0.3, y1 - 0.1, 0.0), Vector3(x0 - 0.3, y1 + 0.1, 0.0), Vector3(x0, y0 + 0.12, 0.0), Vector3.FORWARD)
	b.color = GOLD
	b.quad(Vector3(0.0, -0.14, 0.01), Vector3(-1.5, -0.1, 0.01), Vector3(-1.5, -0.07, 0.01), Vector3(0.0, -0.1, 0.01), Vector3.BACK)
	ribbon.add_child(b.build())
	add_child(ribbon)
	ribbon.position = from
	var v := (aim - from).normalized() * ribbon_speed
	ribbon.rotation.z = atan2(v.y, v.x)
	_ribbons.append([ribbon, v, 3.0])
	Sound.play(self, &"paper_rip", -2.0)


func _update_ribbons(delta: float) -> void:
	for i in range(_ribbons.size() - 1, -1, -1):
		var rb: Array = _ribbons[i]
		var node: Node3D = rb[0]
		var v: Vector3 = rb[1]
		rb[2] -= delta
		node.position += v * delta
		node.scale.y = 1.0 + 0.25 * sin(_time * 22.0 + i)
		var gone: bool = rb[2] <= 0.0 or node.position.x < arena.x - 1.0 or node.position.x > arena.y + 1.0 or node.position.y < ground - 0.5 or _in_obstacle(node.position)
		if not gone and ronin and _hits_ronin(node.position, 0.5):
			if ronin.receive_strike(1, to_global(node.position), &"cut"):
				_parried(1)
				Sound.play(self, &"parry", -2.0)
			gone = true
		if gone:
			Confetti.burst(get_parent(), to_global(node.position), 10, [RED, GOLD])
			node.queue_free()
			_ribbons.remove_at(i)


func _run_dying(delta: float) -> void:
	if _mode_time < 1.3:
		# It writhes up, shaking.
		var up := _from + Vector3(sin(_mode_time * 13.0) * 0.6, _mode_time * 2.5, 0.0)
		_put(up, delta)
		_jaw_goal = 1.0
		_roll = 0.4 * sin(_mode_time * 17.0)
	elif _mode_time < 1.9:
		var k := (_mode_time - 1.3) / 0.6
		var top := _from + Vector3(0.0, 3.25, 0.0)
		var lie := Vector3(clampf(_from.x, lane.x, lane.y), ground + 0.75, 0.6)
		_put(top.lerp(lie, k * k), delta)
		_roll = lerpf(_roll, 0.5, delta * 5.0)
	elif not _fallen:
		Sound.play(self, &"house_crush", -2.0)
		_fall_apart(true)
		_set_mode(&"dead")


## It comes apart: each drum of the body drops to the stones where it is and
## slumps, a heap of wet festival paper.
func _fall_apart(slow: bool) -> void:
	_fallen = true
	_clear_effects()
	# A heap behind the street, off his path (Julian: he walked through its
	# head), never on the stone lantern.
	var middle := clampf(head.x, lane.x + 2.5, lane.y - 2.5)
	if not is_nan(avoid_x) and absf(middle - avoid_x) < 4.6:
		middle = avoid_x + (4.6 if head.x >= avoid_x else -4.6)
	var heap := RandomNumberGenerator.new()
	heap.seed = 77
	for i in _segments.size():
		var s := _segments[i]
		var lie := Vector3(middle - 0.9 + heap.randf_range(-2.6, 2.6) * (1.0 - float(i) / segment_count * 0.3),
				ground + 0.16 + 0.12 * heap.randf(), heap.randf_range(-3.3, -1.9))
		var turn := Basis(Vector3.UP, _rng.randf_range(-PI, PI)) * Basis.from_scale(Vector3(s.get_meta(&"taper"), 0.4, 1.0))
		if slow:
			var t := create_tween()
			t.tween_interval((segment_count - i) * 0.045)
			t.tween_property(s, "transform", Transform3D(turn, lie), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if i % 6 == 0:
				t.tween_callback(func() -> void:
					Confetti.burst(get_parent(), to_global(lie), 10, [RED, GOLD, CREAM])
					Sound.play(self, &"paper_fold", -6.0))
		else:
			s.transform = Transform3D(turn, lie)
	var drop := Vector3(middle + 2.2, ground + 0.7, -2.5)
	if slow:
		var t := create_tween()
		t.tween_property(self, "head", drop, 0.3)
	else:
		head = drop
	_jaw_goal = 0.9
	_jaw = 0.9
	_roll = 0.5
	_pose_head(1.0)


## Touching its head when it is not in the middle of an attack: it snaps at
## him and bites (Julian). Its jaws gape and slam shut, the head jerks at
## him; it costs him a point of health.
func _bite_check() -> void:
	if ronin == null or _bite_clock > 0.0:
		return
	if not _hits_ronin(head + Basis(_turn) * Vector3(0.0, -0.1, 0.4) * head_scale, 1.05):
		return
	_bite_clock = 1.2
	_jaw = 1.0
	_snap = 0.22
	var at := _ronin_local()
	if not _direct:
		head += (at + Vector3(0.0, 1.0, 0.0) - head).normalized() * 0.5
	Sound.play(self, &"dragon_snap", 2.0)
	ronin.take_damage(1, to_global(head), &"cut")


func _clear_moves() -> void:
	_gather.emitting = false
	_sparks.emitting = false
	_jet.visible = false
	_jet_drops.emitting = false
	_streak.visible = false
	_shadow.visible = false
	if _house >= 0 and _house < houses.size() and standing[_house]:
		_restore_house(_house)


func _clear_effects() -> void:
	_clear_moves()
	for m: Array in _marks:
		(m[0] as Node).queue_free()
	_marks.clear()
	for rb: Array in _ribbons:
		(rb[0] as Node).queue_free()
	_ribbons.clear()
	for p: Array in _puddles:
		(p[0] as Node).queue_free()
	_puddles.clear()
	for s: Node3D in _scorches:
		s.queue_free()
	_scorches.clear()


# --- Touching him ------------------------------------------------------------------

func _hits_ronin(at: Vector3, radius: float) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = radius
	return _query(shape, at)


func _hits_box(at: Vector3, size: Vector3) -> bool:
	var shape := BoxShape3D.new()
	shape.size = size
	return _query(shape, at)


func _query(shape: Shape3D, at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = 2
	q.transform = Transform3D(Basis.IDENTITY, to_global(at))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(q, 4):
		if result["collider"] is Ronin:
			return true
	return false


# --- How it looks -------------------------------------------------------------------

## `p` moved the shortest way out of every obstacle (grown by `radius`):
## out the back, out a side or up over the top, never down through it. It
## only ever moves a little at a time, so this slides it round them.
func _clear_of(p: Vector3, radius: float) -> Vector3:
	for box: AABB in obstacles:
		var lo := box.position - Vector3.ONE * radius
		var hi := box.end + Vector3.ONE * radius
		if p.x <= lo.x or p.x >= hi.x or p.y <= lo.y or p.y >= hi.y or p.z <= lo.z or p.z >= hi.z:
			continue
		var back := p.z - lo.z
		var left := p.x - lo.x
		var right := hi.x - p.x
		var up := hi.y - p.y
		var least := minf(minf(back * 1.6, up), minf(left, right))
		if least == back * 1.6:
			p.z = lo.z
		elif least == up:
			p.y = hi.y
		elif least == left:
			p.x = lo.x
		else:
			p.x = hi.x
	return p


## Where to head for now on the way to `goal`: straight there, unless a
## walkway is in the way; then first up, over it, and down again only once
## past.
func _route(goal: Vector3) -> Vector3:
	for box: AABB in obstacles:
		var grown := box.grow(1.25)
		if grown.intersects_segment(head, goal) == null and not grown.has_point(head):
			continue
		# Over it (behind it are the houses' eaves).
		var over := grown.end.y + 0.4
		if head.y < over:
			return Vector3(head.x, over + 0.6, head.z)
		return Vector3(goal.x, maxf(goal.y, over), goal.z)
	return goal


func _in_obstacle(p: Vector3) -> bool:
	for box: AABB in obstacles:
		if box.has_point(p):
			return true
	return false


## The point the body hangs from: the back of the head.
func _nape() -> Vector3:
	return head + Basis(_turn) * Vector3(0.0, -0.1, -0.85) * head_scale


## Fills the trail with a body trailing away from the head along `away`,
## with a lazy wave in it.
func _lay_trail(away: Vector3) -> void:
	_trail.clear()
	var n := int((segment_count + 3) * segment_gap / TRAIL_STEP) + 8
	var dir := away.normalized()
	var side := dir.cross(Vector3.UP).normalized() if absf(dir.y) < 0.9 else Vector3.RIGHT
	for k in range(n, -1, -1):
		var d := k * TRAIL_STEP
		_trail.append(head + dir * d + side * sin(d * 0.45) * 1.2 + Vector3(0.0, sin(d * 0.3) * 0.6, 0.0))


func _push_trail() -> void:
	var nape := _nape()
	if _trail.is_empty():
		_trail.append(nape)
	var last := _trail[_trail.size() - 1]
	var d := nape.distance_to(last)
	var guard := 0
	while d >= TRAIL_STEP and guard < 400:
		last = last.move_toward(nape, TRAIL_STEP)
		_trail.append(last)
		d -= TRAIL_STEP
		guard += 1
	var need := int((segment_count + 3) * segment_gap / TRAIL_STEP) + 8
	if _trail.size() > need + 40:
		_trail = _trail.slice(_trail.size() - need)


## A point `s` metres back along the body from the nape.
func _along(s: float) -> Vector3:
	var nape := _nape()
	var last := _trail.size() - 1
	var first_gap := nape.distance_to(_trail[last])
	if s <= first_gap:
		return nape.lerp(_trail[last], s / maxf(first_gap, 0.001))
	var f := float(last) - (s - first_gap) / TRAIL_STEP
	if f <= 0.0:
		return _trail[0]
	var i := int(floor(f))
	return _trail[i].lerp(_trail[mini(i + 1, last)], f - i)


func _place_body() -> void:
	for i in _segments.size():
		var s := (i + 0.5) * segment_gap
		var at := _along(s)
		var toward := _along(maxf(s - 0.3, 0.0)) - _along(s + 0.3)
		if toward.length() < 0.001:
			toward = Vector3.RIGHT
		toward = toward.normalized()
		var up := Vector3.UP if absf(toward.y) < 0.96 else Vector3.BACK
		var taper: float = _segments[i].get_meta(&"taper")
		at = _clear_of(at, body_radius * taper + 0.1)
		var breathe := 1.0 + 0.04 * sin(_time * 2.2 - i * 0.5)
		_segments[i].transform = Transform3D(Basis.looking_at(-toward, up) * Basis.from_scale(Vector3(taper * breathe, taper * breathe, 1.0)), at)


func _pose_head(delta: float) -> void:
	var dir := _vel
	if _look != Vector3.ZERO:
		dir = _look - head
	elif dir.length() < 1.0:
		dir = Basis(_turn) * Vector3.BACK
	dir = dir.normalized()
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK
	var want := Basis.looking_at(dir, up, true).get_rotation_quaternion()
	_turn = _turn.slerp(want, minf(1.0, delta * 7.0))
	# A mad twitch now and then: a quick jerk of the head.
	_twitch_clock -= delta
	if _twitch_clock <= 0.0:
		_twitch_clock = _rng.randf_range(0.8, 2.6)
		_twitch = _rng.randf_range(-0.35, 0.35)
	_twitch = move_toward(_twitch, 0.0, delta * 1.6)
	var roll := Basis(Basis(_turn) * Vector3.BACK, _roll + _twitch)
	_head_node.transform = Transform3D(roll * Basis(_turn) * Basis.from_scale(Vector3.ONE * head_scale), head)
	var goal := _jaw_goal
	if _snap > 0.0:
		# The bite: gaping wide for a moment, then slammed shut.
		goal = 1.0 if _snap > 0.12 else 0.0
		_jaw = move_toward(_jaw, goal, delta * 18.0)
	if _chatter:
		goal = 0.35 + 0.45 * absf(sin(_time * 16.0))
	_jaw = move_toward(_jaw, goal, delta * 5.0)
	_skin.turns[1] = Quaternion(Vector3.RIGHT, lerpf(-0.28, 0.42, _jaw))
	_skin.apply()


func _flutter() -> void:
	for s: Node3D in _streamers:
		var p: float = s.get_meta(&"phase")
		s.rotation = Vector3(0.35 * sin(_time * 5.0 + p), 0.6 * sin(_time * 3.3 + p), 0.0)


## What the cut finds: the head, always (where the cut reaches it); the
## coils in the street while they are open to cuts (going through a house,
## or knocked down); otherwise its hard body (cuts glance off).
func _update_parts() -> void:
	var fighting := active and _mode not in [&"perch", &"intro", &"dying", &"dead"]
	var head_part := _parts[0]
	head_part.position = head + Basis(_turn) * Vector3(0.0, -0.1, 0.25) * head_scale
	head_part.collision_layer = 4 if fighting else 0   # (Julian: some cuts at its head did nothing)
	var coils := fighting and _mode in [&"coil", &"collapse_tell", &"stun", &"stagger"]
	var k := 1
	for i in _segments.size():
		if i % 3 != 1:
			continue
		var p := _parts[k]
		k += 1
		p.position = _segments[i].position
		p.collision_layer = 4 if coils and absf(p.position.z) < 1.0 else 0
		var hard := _hard[k - 2]
		hard.position = p.position
		hard.collision_layer = 4 if fighting and not coils and absf(p.position.z) < 1.0 else 0


## A cut on its hard body: it glances off with a dull knock, a few flecks
## of lacquered paper.
func _glance(part: Node3D) -> void:
	if _glance_clock > 0.0:
		return
	_glance_clock = 0.15
	Sound.play(self, &"hard_paper", 0.0)
	Confetti.burst(get_parent(), to_global(part.position), 6, [RED, GOLD])


func _line_alpha(a: float) -> void:
	var y := ground + dive_height
	var mid := _mid()
	_streak.position = Vector3(mid, y, 0.3)
	_streak.scale = Vector3(arena.y - arena.x - 4.0, 1.0, 1.0)
	(_streak.mesh as QuadMesh).material.albedo_color.a = 0.32 * a * (0.8 + 0.2 * sin(_time * 12.0))
	_shadow.position = Vector3(mid, ground + 0.025, 0.2)
	_shadow.scale = Vector3(arena.y - arena.x - 4.0, 1.0, 1.0)
	(_shadow.mesh as QuadMesh).material.albedo_color.a = 0.4 * a


func _puddle(at: Vector3) -> void:
	var p := MeshInstance3D.new()
	var disc := QuadMesh.new()
	disc.size = Vector2(_rng.randf_range(0.8, 1.5), _rng.randf_range(0.5, 0.9))
	disc.orientation = PlaneMesh.FACE_Y
	disc.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.07, 0.8), BaseMaterial3D.BILLBOARD_DISABLED)
	p.mesh = disc
	p.position = at
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	_puddles.append([p, 5.0])


func _update_effects(delta: float) -> void:
	_flash_light.light_energy = move_toward(_flash_light.light_energy, 0.0, delta * 30.0)
	for i in range(_puddles.size() - 1, -1, -1):
		var p: Array = _puddles[i]
		p[1] -= delta
		var node: MeshInstance3D = p[0]
		(node.mesh as QuadMesh).material.albedo_color.a = clampf(p[1] / 2.0, 0.0, 1.0) * 0.8
		if p[1] <= 0.0:
			node.queue_free()
			_puddles.remove_at(i)
