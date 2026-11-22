class_name RestShrine
extends Node3D
## A small roadside shrine (hokora) where the Ronin rests. Stand at it for a
## moment and he rests: the candle inside is lit (it flares, then settles),
## the paper streamers (shide) on its rope flutter, a small bell rings, his
## health is made whole, and from then on a fall or a death brings him back
## here instead of to the well. Resting again heals him again.
## Resting saves the game (SaveGame).

signal rested

## This shrine's name in the save.
@export var shrine_id := "shrine"

## How close (metres along the street) he must stand.
@export var reach := 1.0
## Seconds he must stand there before he rests.
@export var rest_time := 0.35

var ronin: Ronin
var lit := false

var _candle_light: OmniLight3D
var _candle: MeshInstance3D
var _streamers: Array[Node3D] = []
var _flutter := 0.0
var _standing := 0.0
var _rested_here := false   # rested since he last walked up to it
var _clock := 0.0
var _last_x := INF
var _respawns := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 13.0)
	_build(rng)


func _build(rng: RandomNumberGenerator) -> void:
	var stone := Color(0.3, 0.31, 0.39)
	var b := PaperMesh.new(rng.randi())
	b.shade_jitter = 0.14
	# A stone plinth, two steps.
	b.color = stone
	b.box(Vector3(0.0, 0.12, 0.0), Vector3(1.1, 0.24, 0.85))
	b.color = stone.lightened(0.06)
	b.box(Vector3(0.0, 0.32, 0.0), Vector3(0.86, 0.16, 0.66))
	# The little wooden house, its front open.
	b.color = Scenery.WOOD.darkened(0.25)
	b.box(Vector3(0.0, 0.75, -0.2), Vector3(0.66, 0.7, 0.06))          # back
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * 0.3, 0.75, 0.0), Vector3(0.06, 0.7, 0.46))  # sides
	b.color = PaperMesh.TIMBER
	b.box(Vector3(0.0, 0.42, 0.02), Vector3(0.7, 0.05, 0.5))            # floor
	# Front posts and lintel in faded vermilion: a shrine, and a place that
	# matters (where he rests).
	b.color = Color(0.5, 0.2, 0.16)
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * 0.31, 0.75, 0.22), Vector3(0.07, 0.72, 0.07))  # front posts
	b.box(Vector3(0.0, 1.07, 0.22), Vector3(0.74, 0.06, 0.07))
	# A gabled roof, sloping front and back, overhanging all round.
	b.color = Scenery.ROOF
	b.quad(Vector3(-0.5, 1.08, 0.42), Vector3(0.5, 1.08, 0.42), Vector3(0.5, 1.36, 0.0), Vector3(-0.5, 1.36, 0.0),
			Vector3(0.0, 1.0, 0.8))
	b.quad(Vector3(0.5, 1.08, -0.42), Vector3(-0.5, 1.08, -0.42), Vector3(-0.5, 1.36, 0.0), Vector3(0.5, 1.36, 0.0),
			Vector3(0.0, 1.0, -0.8))
	b.color = Scenery.ROOF_LIP
	b.box(Vector3(0.0, 1.37, 0.0), Vector3(1.06, 0.06, 0.1))
	for side: float in [-1.0, 1.0]:  # gable ends
		b.color = Scenery.WOOD.darkened(0.3)
		b.tri(Vector3(side * 0.33, 1.1, 0.24), Vector3(side * 0.33, 1.1, -0.24), Vector3(side * 0.33, 1.33, 0.0),
				Vector3(side, 0.0, 0.0))
	# Inside: a small offering dish and a stone.
	b.color = stone.darkened(0.2)
	b.box(Vector3(0.0, 0.5, -0.08), Vector3(0.22, 0.1, 0.16))
	add_child(b.build())

	# The candle: unlit until he rests.
	var wax := PaperMesh.new(rng.randi())
	wax.color = PaperMesh.WASHI
	wax.box(Vector3(0.12, 0.53, 0.02), Vector3(0.05, 0.16, 0.05))
	add_child(wax.build())
	var flame := PaperMesh.new(rng.randi())
	flame.texture_scale = 0.0
	flame.shade_jitter = 0.0
	flame.color = PaperMesh.LANTERN
	flame.ellipse(Vector2(0.12, 0.66), Vector2(0.025, 0.045), 8, 0.03)
	_candle = flame.build(Color.WHITE, 3.0, true)
	_candle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_candle.visible = false
	add_child(_candle)
	_candle_light = OmniLight3D.new()
	_candle_light.light_color = PaperMesh.LANTERN
	_candle_light.light_energy = 0.0
	_candle_light.omni_range = 3.2
	_candle_light.omni_attenuation = 2.0
	_candle_light.position = Vector3(0.12, 0.75, 0.5)
	add_child(_candle_light)

	# A rope across the front with zigzag paper streamers hanging from it.
	var rope := PaperMesh.new(rng.randi())
	rope.color = Color(0.5, 0.44, 0.34)
	rope.stroke(Vector2(-0.36, 1.0), Vector2(0.36, 1.0), 0.04, 0.04, 0.28)
	add_child(rope.build())
	for k in 3:
		var hang := Node3D.new()
		hang.position = Vector3(-0.24 + k * 0.24, 0.99, 0.29)
		add_child(hang)
		var paper := PaperMesh.new(rng.randi())
		paper.color = PaperMesh.WASHI.darkened(0.08)
		paper.shade_jitter = 0.05
		# A shide: a strip of paper cut and folded in a zigzag down, made of
		# four short strips stepping alternately left and right.
		for step in 4:
			var shift := (0.035 if step % 2 == 1 else 0.0)
			paper.rect(Vector2(shift, -0.045 - step * 0.085), Vector2(0.06, 0.08), 0.0)
		var strip := paper.build()
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hang.add_child(strip)
		Scenery.windswept(hang, 0.05, rng)
		_streamers.append(hang)


func _physics_process(delta: float) -> void:
	_clock += delta
	if ronin == null:
		ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if ronin == null:
			return
	# Put here (respawned after a fall or a death) rather than walking up:
	# that is not resting. He rests when he next walks up to it.
	if (absf(ronin.global_position.x - _last_x) > 3.0 or ronin.respawns != _respawns) 			and absf(ronin.global_position.x - global_position.x) < reach + 1.0:
		_rested_here = true
	_respawns = ronin.respawns
	_last_x = ronin.global_position.x
	var near := absf(ronin.global_position.x - global_position.x) < reach \
			and absf(ronin.global_position.y - global_position.y) < 0.6 and ronin.is_on_floor()
	if not near:
		_standing = 0.0
		if absf(ronin.global_position.x - global_position.x) > reach + 2.0:
			_rested_here = false
	elif not _rested_here:
		_standing += delta
		if _standing >= rest_time:
			_rest()
	# The candle breathes; the streamers flutter for a while after resting.
	if lit:
		var breathe := 1.0 + 0.12 * sin(_clock * 7.3) + 0.06 * sin(_clock * 13.1)
		_candle_light.light_energy = lerpf(_candle_light.light_energy, 1.6 * breathe, 0.1)
		_candle.scale = Vector3(1.0, breathe, 1.0)
	_flutter = maxf(_flutter - delta * 0.7, 0.0)
	for i in _streamers.size():
		var s := _streamers[i]
		s.rotation.z += sin(_clock * 17.0 + i * 2.1) * 0.25 * _flutter


func _rest() -> void:
	_rested_here = true
	_standing = 0.0
	ronin.set_checkpoint(Vector3(global_position.x, global_position.y, 0.0))
	if ronin.health < ronin.max_health:
		ronin.health = ronin.max_health
		ronin.health_changed.emit(ronin.health, ronin.max_health)
	_flutter = 1.0
	Sound.play(self, &"shrine_rest")
	SaveGame.last_shrine = shrine_id
	if shrine_id not in SaveGame.rested:
		SaveGame.rested.append(shrine_id)
	SaveGame.ink_absorbed = ronin.ink_absorbed
	SaveGame.write()
	get_tree().call_group(&"hud", &"saved")
	if not lit:
		lit = true
		_candle.visible = true
		# The wick catches: a flare, then it settles.
		var flare := create_tween()
		_candle_light.light_energy = 0.0
		flare.tween_property(_candle_light, "light_energy", 4.0, 0.12)
		flare.tween_property(_candle_light, "light_energy", 1.6, 0.6).set_trans(Tween.TRANS_SINE)
	rested.emit()


## Lit already (a saved game: he rested here before), without the flare.
func light_quietly() -> void:
	lit = true
	_candle.visible = true
	_candle_light.light_energy = 1.6
