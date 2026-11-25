class_name WaxMaker
extends Node3D
## The Wax-Maker of Sumi Marsh (docs/sumi_marsh_plan.md): an old paper doll
## in a straw rain cape (mino) and a wide sedge hat, bent over a pot of wax
## pressed from the haze trees' berries, stirring it with a long paddle.
## She looks up as he comes near. The first time he comes to her she lifts
## a ladle and pours warm wax over him: the Wax Coat (Ronin.has_wax,
## SaveGame ability "wax", an AbilityCard). Folded in code, posed by hand.

const MINO := Color(0.36, 0.32, 0.24)
const MINO_DARK := Color(0.24, 0.21, 0.16)
const SKIN := Color(0.82, 0.78, 0.7)
const WAX := Color(0.95, 0.86, 0.6)

@export var notice_distance := 5.0
## How near he must come for her to coat him (m).
@export var give_distance := 1.5

var marsh: SumiMarsh
var _body: Node3D
var _head: Node3D
var _arm: Node3D
var _ronin: Ronin
var _look := 0.0
var _giving := -1.0
var _given := false
var _drip: CPUParticles3D
var _steam: CPUParticles3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	_build(rng)
	_given = "wax" in SaveGame.abilities


func _build(rng: RandomNumberGenerator) -> void:
	# The pot of wax on its little stove, in front of her, steaming.
	var pot := PaperMesh.new(rng.randi())
	pot.shade_jitter = 0.12
	pot.color = Color(0.3, 0.24, 0.2)
	pot.frustum(8, Vector2(0.34, 0.3), Vector2(0.3, 0.28), 0.35, Vector3(0.75, 0.0, 0.2))
	pot.color = Color(0.14, 0.12, 0.12)
	pot.frustum(10, Vector2(0.3, 0.3), Vector2(0.34, 0.34), 0.3, Vector3(0.75, 0.35, 0.2))
	add_child(pot.build())
	var melt := PaperMesh.new(1)
	melt.color = WAX
	melt.frustum(10, Vector2(0.3, 0.3), Vector2(0.3, 0.3), 0.02, Vector3(0.75, 0.6, 0.2))
	add_child(melt.build(Color.WHITE, 0.8))
	var coal := PaperMesh.new(2)
	coal.color = Color(1.0, 0.45, 0.2)
	coal.rect(Vector2(0.75, 0.15), Vector2(0.24, 0.12), 0.55)
	add_child(coal.build(Color.WHITE, 2.0, true))
	_steam = CPUParticles3D.new()
	_steam.amount = 14
	_steam.lifetime = 2.6
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_steam.emission_sphere_radius = 0.2
	_steam.direction = Vector3.UP
	_steam.spread = 12.0
	_steam.gravity = Vector3(-0.1, 0.25, 0.0)
	_steam.initial_velocity_min = 0.2
	_steam.initial_velocity_max = 0.4
	_steam.scale_amount_min = 1.0
	_steam.scale_amount_max = 2.2
	var puff := QuadMesh.new()
	puff.size = Vector2(0.3, 0.3)
	puff.material = PaperMesh.soft_ink(Color(0.75, 0.74, 0.68, 0.18))
	_steam.mesh = puff
	_steam.position = Vector3(0.75, 0.65, 0.2)
	add_child(_steam)
	# Her body: bent, the straw cape in shaggy layers from her shoulders.
	_body = Node3D.new()
	add_child(_body)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.18
	b.texture_world = false
	b.color = Color(0.2, 0.19, 0.22)
	b.frustum(8, Vector2(0.24, 0.18), Vector2(0.2, 0.15), 0.5, Vector3.ZERO)  # the hem of her kimono
	for layer in 4:
		var y := 1.05 - layer * 0.24
		var r := 0.2 + layer * 0.07
		var k := 0
		while k < 22:
			var a := TAU * k / 22.0
			b.color = (MINO if (k + layer) % 3 else MINO_DARK).darkened(rng.randf_range(0.0, 0.2))
			var top := Vector3(cos(a) * r * 0.7, y, sin(a) * r * 0.6)
			var bottom := Vector3(cos(a) * r * 1.15, y - 0.42, sin(a) * r * 0.85)
			var side := Vector3(-sin(a), 0.0, cos(a)) * 0.05
			b.quad(top - side, top + side, bottom + side * 1.3 + Vector3(0.0, -rng.randf_range(0.0, 0.08), 0.0), bottom - side * 1.3, Vector3(cos(a), 0.0, sin(a)))
			k += 1
	_body.add_child(b.build())
	# Her head, bowed under the sedge hat.
	_head = Node3D.new()
	_head.position = Vector3(0.04, 1.12, 0.0)
	_body.add_child(_head)
	var h := PaperMesh.new(rng.randi())
	h.shade_jitter = 0.1
	h.texture_world = false
	h.color = SKIN
	h.loft([PaperMesh.oval(Vector3(0.05, 0.0, 0.0), Vector2(0.09, 0.08), 8), PaperMesh.oval(Vector3(0.07, 0.1, 0.0), Vector2(0.11, 0.1), 8),
			PaperMesh.oval(Vector3(0.06, 0.2, 0.0), Vector2(0.09, 0.09), 8)])
	# Her face painted on: closed creased eyes, a small mouth.
	h.color = Color(0.2, 0.18, 0.18)
	for side: float in [-1.0, 1.0]:
		h.box(Vector3(0.17, 0.12, side * 0.04), Vector3(0.01, 0.008, 0.035))
	h.box(Vector3(0.17, 0.05, 0.0), Vector3(0.01, 0.006, 0.03))
	h.color = Color(0.72, 0.72, 0.7)
	h.frustum(8, Vector2(0.08, 0.07), Vector2(0.04, 0.04), 0.06, Vector3(0.0, 0.2, 0.0))  # white hair in a knot
	# The sedge hat: a wide shallow cone of woven straw.
	h.color = Color(0.44, 0.38, 0.27)
	h.frustum(16, Vector2(0.42, 0.42), Vector2(0.03, 0.03), 0.2, Vector3(0.02, 0.2, 0.0))
	h.color = Color(0.3, 0.26, 0.19)
	h.frustum(16, Vector2(0.43, 0.43), Vector2(0.42, 0.42), 0.02, Vector3(0.02, 0.19, 0.0))
	_head.add_child(h.build())
	# Her arm with the paddle (stirring) or the ladle (pouring on him).
	_arm = Node3D.new()
	_arm.position = Vector3(0.12, 0.95, 0.16)
	_body.add_child(_arm)
	var a := PaperMesh.new(rng.randi())
	a.texture_world = false
	a.color = MINO_DARK
	a.box(Vector3(0.12, -0.16, 0.0), Vector3(0.12, 0.34, 0.14))
	a.color = SKIN
	a.box(Vector3(0.18, -0.34, 0.0), Vector3(0.07, 0.07, 0.07))
	a.color = Color(0.36, 0.28, 0.2)
	MarshKit.limb(a, Vector3(0.18, 0.1, 0.0), Vector3(0.62, -0.5, 0.04), 0.022, 0.02, 5)
	a.box(Vector3(0.64, -0.55, 0.04), Vector3(0.12, 0.1, 0.03))
	_arm.add_child(a.build())
	# The wax she pours, dripping in warm strings.
	_drip = CPUParticles3D.new()
	_drip.emitting = false
	_drip.amount = 40
	_drip.lifetime = 0.9
	_drip.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_drip.emission_box_extents = Vector3(0.25, 0.05, 0.25)
	_drip.direction = Vector3.DOWN
	_drip.spread = 10.0
	_drip.gravity = Vector3(0.0, -6.0, 0.0)
	_drip.initial_velocity_min = 0.5
	_drip.initial_velocity_max = 1.2
	var bead := QuadMesh.new()
	bead.size = Vector2(0.05, 0.09)
	var gold := PaperMesh.soft_ink(Color(WAX, 0.9))
	gold.emission_enabled = true
	gold.emission = WAX
	gold.emission_energy_multiplier = 0.6
	bead.material = gold
	_drip.mesh = bead
	add_child(_drip)


func _process(delta: float) -> void:
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var t := Time.get_ticks_msec() * 0.001
	var dx := _ronin.global_position.x - global_position.x
	var near := absf(dx) < notice_distance and absf(_ronin.global_position.y - global_position.y) < 2.5
	_look = lerpf(_look, clampf(dx * 0.3, -0.8, 0.8) if near else 0.0, 1.0 - exp(-delta * 3.0))
	_head.rotation.y = -_look
	_head.rotation.z = lerpf(_head.rotation.z, 0.12 if near else -0.25, 1.0 - exp(-delta * 3.0))
	_body.scale.y = 1.0 + 0.01 * sin(t * 1.4)
	if _giving >= 0.0:
		_giving += delta
		# She turns to him, lifts the ladle high over his hat, pours.
		var u := smoothstep(0.0, 0.8, _giving)
		_body.rotation.y = -u * 0.9 * signf(dx if absf(dx) > 0.1 else 1.0)
		_arm.rotation.z = lerpf(-0.3, 1.9, u)
		_arm.rotation.x = 0.0
		if _giving > 0.9 and not _drip.emitting and _giving < 2.6:
			_drip.global_position = _ronin.global_position + Vector3(0.0, 2.3, 0.0)
			_drip.emitting = true
			Sound.play(self, &"wax_pour", 0.0)
		if _giving > 2.6:
			_drip.emitting = false
		if _giving > 2.9:
			_giving = -1.0
			_learn()
		return
	_body.rotation.y = lerpf(_body.rotation.y, 0.0, 1.0 - exp(-delta * 2.0))
	# Stirring: the paddle goes round in the pot, slowly.
	_arm.rotation.z = -0.3 + 0.12 * sin(t * 1.6)
	_arm.rotation.x = 0.25 * cos(t * 1.6)
	if not _given and absf(dx) < give_distance and absf(_ronin.global_position.y - global_position.y) < 1.5 \
			and _ronin.is_on_floor() and _ronin.is_physics_processing():
		_given = true
		_giving = 0.0
		_ronin.set_physics_process(false)
		_ronin.velocity = Vector3.ZERO
		(_ronin.get_node("Puppet") as RoninPuppet).state = &"idle"


## The Wax Coat is his (also called by the automated check).
func _learn() -> void:
	_given = true
	if _ronin:
		_ronin.has_wax = true
		_ronin.set_physics_process(true)
		(_ronin.get_node("Puppet") as RoninPuppet).play_healed()
	if "wax" not in SaveGame.abilities:
		SaveGame.abilities.append("wax")
	SaveGame.write()
	Sound.play(self, &"draw_ready", 0.0)
	var card := AbilityCard.new()
	card.title = "Wax Coat"
	card.prompts = []
	card.advice = "Waxed paper floats. Deep water and ink no longer carry you off; ink no longer stains you, and the Rain's weight runs off you."
	var ronin := _ronin
	card.used = func() -> bool: return is_instance_valid(ronin) and ronin.swimming
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud:
		hud.get_parent().add_child(card)
