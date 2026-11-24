class_name Updraft
extends Node3D
## A rising gust of the folded wind, in the Bamboo of Folded Wind: a column
## of air that lifts him while he glides (Ronin.updraft_lift), and rests his
## wings (Ronin.glide_time). Walking or falling through it does nothing; it
## is what carries the Crane Glide far.
##
## It must come FROM something (Julian): it blows up out of a cleft in the
## ground, where dry bamboo leaves lie, and the leaves and a pale shimmer
## ride it up. The top fades, so he bobs there rather than flying off.
## Place it with its foot on the ground (position = the cleft).

## Every updraft in play (looked up by the Ronin each frame).
static var all: Array[Updraft] = []

## How wide the column is (metres).
@export var width := 3.2
## How high it lifts (metres above its foot).
@export var height := 10.0
## How strong it is (1 = Ronin.updraft_lift).
@export var strength := 1.0
## The last part of its height where its lift fades away (metres).
@export var fade_top := 2.5
## Hot air from a kiln's flue (the Lantern Makers' Rise) instead of the
## folded wind out of a cleft: no cleft or leaves; embers and ash ride it up.
@export var kiln := false

var _clock := 0.0
var _shimmers: Array[MeshInstance3D] = []


## How much rising air there is at this point (0 none, up to strength).
static func lift_at(at: Vector3) -> float:
	var best := 0.0
	for u: Updraft in all:
		if not is_instance_valid(u) or not u.is_inside_tree():
			continue
		var p := u.global_position
		var dx := absf(at.x - p.x)
		if dx > u.width * 0.5:
			continue
		var up := at.y - p.y
		if up < -0.5 or up > u.height:
			continue
		var edge := smoothstep(u.width * 0.5, u.width * 0.3, dx)
		var top := clampf((u.height - up) / maxf(u.fade_top, 0.01), 0.0, 1.0)
		best = maxf(best, u.strength * edge * top)
	return best


func _enter_tree() -> void:
	all.append(self)


func _exit_tree() -> void:
	all.erase(self)


func _ready() -> void:
	if kiln:
		_build_embers()
	else:
		_build_cleft()
		_build_leaves()
	_build_shimmers()


## Embers and flakes of ash carried up on the hot air, the embers fading as
## they cool.
func _build_embers() -> void:
	for ash: bool in [false, true]:
		var p := CPUParticles3D.new()
		p.amount = int((10 if ash else 24) + height * 2.0)
		p.lifetime = height / 4.5
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(width * 0.3, 0.05, 0.5)
		p.direction = Vector3.UP
		p.spread = 8.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 3.5
		p.initial_velocity_max = 5.5
		p.tangential_accel_min = -1.0
		p.tangential_accel_max = 1.0
		p.angular_velocity_min = -200.0
		p.angular_velocity_max = 200.0
		var fade := Gradient.new()
		if ash:
			fade.set_color(0, Color(0.4, 0.38, 0.4, 0.0))
			fade.add_point(0.2, Color(0.45, 0.43, 0.45, 0.8))
			fade.set_color(fade.get_point_count() - 1, Color(0.4, 0.38, 0.4, 0.0))
		else:
			fade.set_color(0, Color(1.0, 0.75, 0.35, 1.0))
			fade.add_point(0.5, Color(1.0, 0.45, 0.15, 0.8))
			fade.set_color(fade.get_point_count() - 1, Color(0.5, 0.1, 0.05, 0.0))
		p.color_ramp = fade
		var mote := QuadMesh.new()
		mote.size = Vector2(0.09, 0.06) if ash else Vector2(0.05, 0.05)
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.vertex_color_use_as_albedo = true
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.cull_mode = BaseMaterial3D.CULL_DISABLED
		look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		if not ash:
			look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mote.material = look
		p.mesh = mote
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(p)


## The cleft it blows out of: a dark split in the rock with dry leaves
## caught round its lips.
func _build_cleft() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 13.0)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.15
	b.color = Color(0.08, 0.07, 0.06)
	var half := width * 0.32
	# A ragged dark split lying in the ground, longer across than along.
	var rim: Array[Vector3] = []
	for k in 14:
		var t := TAU * k / 14.0
		rim.append(Vector3(cos(t) * half * rng.randf_range(0.8, 1.15), 0.025, sin(t) * 0.55 * rng.randf_range(0.6, 1.1) - 0.1))
	for k in 14:
		b.tri(Vector3(0.0, 0.025, -0.1), rim[(k + 1) % 14], rim[k])
	# Stones round its lips.
	for k in 6:
		var t := TAU * k / 6.0 + rng.randf_range(-0.3, 0.3)
		var r := rng.randf_range(0.08, 0.16)
		b.color = BambooGrove.ROCK.lightened(rng.randf_range(0.0, 0.25))
		b.frustum(6, Vector2(r, r), Vector2(r * 0.5, r * 0.5), r * 0.6, Vector3(cos(t) * half * 1.2, 0.0, sin(t) * 0.7 - 0.1))
	b.color = Color(0.55, 0.5, 0.3)
	for k in 9:
		var x := rng.randf_range(-half * 1.4, half * 1.4)
		var z := rng.randf_range(-0.6, 0.45)
		var a := rng.randf_range(0.0, TAU)
		var dir := Vector3(cos(a), 0.0, sin(a)) * 0.09
		var side := Vector3(-dir.z, 0.0, dir.x) * 0.3
		b.tri(Vector3(x, 0.06, z) - dir, Vector3(x, 0.06, z) + side, Vector3(x, 0.06, z) + dir)
	add_child(b.build())


## Bamboo leaves lifted out of the cleft, turning over as they rise, thinning
## out toward the top.
func _build_leaves() -> void:
	var leaves := CPUParticles3D.new()
	leaves.amount = int(20 + height * 4.0)
	leaves.lifetime = height / 5.0
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(width * 0.28, 0.05, 0.5)
	leaves.direction = Vector3(0.0, 1.0, 0.0)
	leaves.spread = 8.0
	leaves.gravity = Vector3.ZERO
	leaves.initial_velocity_min = 4.0
	leaves.initial_velocity_max = 6.0
	leaves.damping_min = 0.0
	leaves.damping_max = 0.4
	leaves.angle_max = 360.0
	leaves.angular_velocity_min = -260.0
	leaves.angular_velocity_max = 260.0
	leaves.tangential_accel_min = -1.5
	leaves.tangential_accel_max = 1.5
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.12, Color(1, 1, 1, 1))
	fade.add_point(0.7, Color(1, 1, 1, 0.9))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	leaves.color_ramp = fade
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.24, 0.07)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(0.93, 0.88, 0.66)  # (dry, sun-bleached: pale against the green)
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.material = look
	leaves.mesh = leaf
	leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(leaves)
	# A few blossom petals carried up with them.
	var petals := leaves.duplicate() as CPUParticles3D
	petals.amount = int(6 + height)
	var petal := QuadMesh.new()
	petal.size = Vector2(0.09, 0.07)
	var pink := look.duplicate() as StandardMaterial3D
	pink.albedo_color = BambooGrove.PETAL
	petal.material = pink
	petals.mesh = petal
	add_child(petals)


## Pale ribbons of moving air: a few long thin strips that rise and fade,
## each on its own clock (the air is seen moving, not standing).
func _build_shimmers() -> void:
	for k in 5:
		var strip := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.11, height * 0.3)
		strip.mesh = quad
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.albedo_color = Color(1.0, 0.98, 0.9, 0.0)
		look.cull_mode = BaseMaterial3D.CULL_DISABLED
		strip.material_override = look
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strip)
		_shimmers.append(strip)


func _process(delta: float) -> void:
	_clock += delta
	for k in _shimmers.size():
		# Each rises from the cleft to the top over 1.6 s, fading in and out.
		var u := fposmod(_clock / 1.6 + k / 5.0, 1.0)
		var strip := _shimmers[k]
		strip.position = Vector3((k - 2) * width * 0.15 + sin(_clock * 1.3 + k) * 0.1, lerpf(height * 0.15, height * 0.85, u), 0.3)
		(strip.material_override as StandardMaterial3D).albedo_color.a = sin(PI * u) * 0.38
