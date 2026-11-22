class_name HannyaBoss
extends CharacterBody3D
## The Weeping Hannya, fought in the shrine courtyard after her cutscene.
##
## Her moves (each has a tell you can read):
##   Sleeve slash   She draws a sleeve up behind her, then sweeps it down in
##                  front, leaving an arc of ink. Parry it. Sometimes two in a
##                  row, the second quicker.
##   Glide          She rises, sleeves spread, then flies across the
##                  courtyard at chest height. Parry it (double posture) or
##                  duck under it (hold S).
##   Ink rain       She covers her face and weeps; ink tears rain down. A
##                  stain spreads on the ground where each will land. Cannot
##                  be parried: get out from under them.
##   Ink blades     She draws her sleeve back and flings three crescent blades
##                  of ink across the courtyard, one after another. Parry each
##                  (a rhythm), or jump them.
##   Ink step       A pool of ink spreads under her and she sinks into it;
##                  another spreads behind him and she rises out of it,
##                  already raising a sleeve: turn and parry.
##   Weeping masks  From half health: three pale copies of her mask circle
##                  her, shiver, and dive at him one by one. Parry each.
## Parries build her posture; when it is full she sinks to her knees,
## weeping, with the vermilion seal on her back, and a finishing cut takes a
## big piece of her health. At half health she grows faster and the rain
## heavier.
##
## She is a "Hannya" puppet (hannya.gd) carried by this body. The body is on
## the enemy layer, so the Ronin's cuts find it like any enemy's.

signal health_changed(current: int, maximum: int)
signal posture_changed(current: int, maximum: int)
signal defeated

## When set (main.gd does), she does not burst into scraps when she falls:
## the ending cutscene shows what becomes of her.
var ending_follows := false

@export_group("Health")
@export var max_health := 30
## Parries (or glide parries, which count double) before she staggers.
@export var max_posture := 6
## Seconds without being parried before one point of posture comes back.
@export var posture_recover_time := 3.0
@export var stagger_time := 2.6
## Health a finishing cut takes from her.
@export var finish_damage := 6

@export_group("Sleeve slash")
@export var slash_windup := 0.7
@export var slash_strike := 0.16
@export var slash_recover := 0.75
## How far in front of her the sleeve reaches, and how tall the sweep is.
@export var slash_reach := 2.5
@export var slash_height := 2.3
## How often the slash comes as a pair; the second follows this fast.
@export var double_chance := 0.4
@export var double_windup := 0.38

@export_group("Glide")
## The tell: she rises off the ground with her sleeves spread like wings,
## ink streams off her, a wail, and a streak of pale light races along the
## ground where she will fly. (0.65 s with a small draw-back was too easy to miss.)
@export var glide_windup := 0.8
## How high she rises during the tell (and flies).
@export var glide_lift := 1.0
## Her sleeves sweep between these heights above the ground: duck under the
## lower, or parry. (Too high to jump over.)
@export var glide_band := Vector2(1.0, 2.6)
@export var glide_speed := 12.0

@export_group("Ink rain")
@export var rain_time := 3.4
@export var rain_drops := 9
## How long a stain spreads on the ground before its drop lands.
@export var drop_warning := 0.8
## How close (metres, sideways) a drop must land to hit him.
@export var drop_radius := 0.6

@export_group("Ink blades")
@export var volley_windup := 0.6
@export var volley_count := 3
@export var volley_gap := 0.42
@export var blade_speed := 9.5
## How high the blades fly (metres above the ground): chest height.
@export var blade_height := 1.05

@export_group("Ink step")
## The pool spreading under her before she sinks.
@export var vanish_tell := 0.45
## How fast she sinks into it.
@export var sink_time := 0.3
## How long she is under, while the pool behind him spreads (the warning).
@export var vanish_time := 0.5
## How long she takes to rise out of it.
@export var rise_time := 0.5
## How deep she goes (below the stones she is hidden).
@export var sink_depth := 3.0
## Her slash on rising has this (shorter) wind-up.
@export var ambush_windup := 0.5

@export_group("Weeping masks")
@export var mask_tell := 0.7
## Seconds between one mask diving and the next.
@export var mask_gap := 0.55

@export_group("Touch")
## Walking into her hurts (and knocks him back), like a husk; she answers
## with a quick swat of her sleeve if she is not already attacking.
@export var contact_damage := 1
@export var swat_time := 0.35

@export_group("Waiting")
## After he dies she waits this far in from the courtyard's right end.
@export var waiting_gap := 2.5

@export_group("Pace")
## Seconds between her moves.
@export var rest_time := 0.9
## How fast she drifts toward him between moves.
@export var drift_speed := 1.3
## At half health her tells and rests shrink to this fraction.
@export var enraged_pace := 0.75

var health := 0
var posture := 0
var arena := Vector2(47.0, 63.5)
var puppet: Hannya
var ronin: Ronin
var active := false

var _mode: StringName = &"wait"
var _mode_time := 0.0
var _facing := -1.0
var _hit_this_swing := false
var _second_slash := false
var _posture_clock := 0.0
var _clock := 0.0
var _glide_target := 0.0
var _rain_left := 0
var _rain_clock := 0.0
var _last_rain := -99.0
var _flash := 0.0
var _arc: MeshInstance3D
var _arc_clock := -1.0
var _seal: Node3D
var _seal_show := 0.0
var _music: AudioStreamPlayer
var _home := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _volley_left := 0
var _volley_clock := 0.0
var _last_masks := -99.0
var _ambush := false
var _pool: InkPool
var _path: MeshInstance3D
var _wisps: CPUParticles3D
var _touch: Area3D
var _drips: CPUParticles3D


func _ready() -> void:
	collision_layer = 4     # enemies
	collision_mask = 1      # the world
	axis_lock_linear_z = true
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 2.4
	shape.shape = capsule
	shape.position.y = 1.2
	add_child(shape)
	health = max_health
	_rng.randomize()
	_home = global_position
	_build_arc()
	_build_seal()
	_touch = Area3D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = 2  # the player
	var touch_shape := CollisionShape3D.new()
	var touch_box := BoxShape3D.new()
	touch_box.size = Vector3(0.9, 2.3, 1.0)
	touch_shape.shape = touch_box
	touch_shape.position.y = 1.15
	_touch.add_child(touch_shape)
	add_child(_touch)
	# The glide's ground smear: a long flat strip of ink, laid on the stones.
	var strip := SurfaceTool.new()
	strip.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / 24.0
			var half := 0.32 * (0.6 + 0.4 * sin(PI * t)) * (0.85 + 0.15 * sin(t * 31.0))
			strip.set_uv(Vector2(t, corner[1]))
			strip.add_vertex(Vector3(t, 0.0, (corner[1] * 2.0 - 1.0) * half))
	_path = MeshInstance3D.new()
	_path.mesh = strip.commit()
	var path_look := ShaderMaterial.new()
	path_look.shader = preload("res://shaders/slash_sweep.gdshader")
	# Cold, pale ghost-light (dark ink did not show on the dark stones).
	path_look.set_shader_parameter(&"tint", Color(0.74, 0.8, 1.0, 0.6))
	_path.material_override = path_look
	_path.top_level = true
	_path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_path.visible = false
	add_child(_path)
	# Soft puffs of ink smoke streaming off her while she gathers and flies:
	# each swells and fades as it drifts. (Black rectangles looked careless.)
	_wisps = CPUParticles3D.new()
	_wisps.emitting = false
	_wisps.amount = 50
	_wisps.lifetime = 0.7
	_wisps.local_coords = false
	_wisps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wisps.emission_box_extents = Vector3(0.6, 1.2, 0.3)
	_wisps.position = Vector3(0.0, 1.6, 0.0)
	_wisps.direction = Vector3.UP
	_wisps.spread = 40.0
	_wisps.initial_velocity_min = 0.6
	_wisps.initial_velocity_max = 1.8
	_wisps.gravity = Vector3(0.0, 1.2, 0.0)
	_wisps.scale_amount_min = 0.7
	_wisps.scale_amount_max = 1.3
	var swell := Curve.new()
	swell.add_point(Vector2(0.0, 0.35))
	swell.add_point(Vector2(1.0, 1.0))
	_wisps.scale_amount_curve = swell
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.75))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	_wisps.color_ramp = fade
	var wisp := QuadMesh.new()
	wisp.size = Vector2(0.42, 0.42)
	wisp.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.06))
	_wisps.mesh = wisp
	_wisps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_wisps)
	# Ink running off her as she rises out of a pool.
	_drips = CPUParticles3D.new()
	_drips.emitting = false
	_drips.amount = 40
	_drips.lifetime = 0.6
	_drips.local_coords = false
	_drips.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_drips.emission_box_extents = Vector3(0.45, 1.1, 0.3)
	_drips.position = Vector3(0.0, 1.3, 0.0)
	_drips.direction = Vector3.DOWN
	_drips.initial_velocity_min = 0.5
	_drips.initial_velocity_max = 1.5
	_drips.gravity = Vector3(0.0, -14.0, 0.0)
	_drips.scale_amount_min = 0.5
	_drips.scale_amount_max = 1.2
	var drip := QuadMesh.new()
	drip.size = Vector2(0.06, 0.15)
	drip.material = PaperMesh.soft_ink(Color(0.02, 0.02, 0.05))
	_drips.mesh = drip
	add_child(_drips)
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music_hannya_fight.ogg")
	(_music.stream as AudioStreamOggVorbis).loop = true
	Sound.follow_level(_music, -7.0)
	add_child(_music)


## Carries the puppet (taken from the shrine stage after the cutscene).
func take_puppet(figure: Hannya) -> void:
	puppet = figure
	puppet.reparent(self)
	puppet.position = Vector3.ZERO
	puppet.show_body(true)


## The fight starts (after the cutscene, or when he comes back in).
func begin() -> void:
	active = true
	_set_mode(&"idle")
	_music.play()
	Sound.duck_music(true)
	health_changed.emit(health, max_health)
	posture_changed.emit(posture, max_posture)


## He has died: she goes back to the right end of the courtyard, facing the
## way he will come in, and waits, healed. (She used to go to a "home" spot
## recorded before she was moved into the courtyard, which put her at its
## left end, right where he walks in.)
func reset() -> void:
	active = false
	if puppet:
		puppet.visible = true
	health = max_health
	posture = 0
	global_position = Vector3(arena.y - waiting_gap, global_position.y, 0.0)
	_facing = -1.0
	velocity = Vector3.ZERO
	_set_mode(&"wait")
	_music.stop()
	Sound.duck_music(false)


func is_staggered() -> bool:
	return _mode == &"stagger"


## Called by the Ronin's cuts.
func take_hit(damage: int, _direction: Vector2) -> void:
	if _mode == &"dead" or _mode == &"vanished" or _mode == &"sinking" or not active:
		return  # (while she is under the ink there is nothing to cut)
	if _mode == &"stagger":
		health -= finish_damage
		posture = 0
		posture_changed.emit(posture, max_posture)
		Confetti.burst(get_parent(), puppet.back_position(), 40)
		Sound.play(self, &"paper_burst", 2.0)
		_set_mode(&"recover")
		_mode_time = slash_recover * 0.3
	else:
		health -= damage
	_flash = 0.1
	puppet.flash(true)
	health_changed.emit(maxi(health, 0), max_health)
	if health <= 0:
		_die()


func _physics_process(delta: float) -> void:
	_clock += delta
	_mode_time += delta
	if not is_on_floor():
		velocity.y -= 30.0 * delta
	else:
		velocity.y = 0.0
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			puppet.flash(false)
	if posture > 0 and _mode != &"stagger":
		_posture_clock += delta
		if _posture_clock >= posture_recover_time:
			_posture_clock = 0.0
			posture -= 1
			posture_changed.emit(posture, max_posture)
	var pace := enraged_pace if health <= max_health / 2 else 1.0
	var to_him := ronin.global_position.x - global_position.x if ronin else 0.0

	match _mode:
		&"wait", &"dead":
			velocity.x = 0.0
		&"idle":
			_facing = signf(to_him) if to_him != 0.0 else _facing
			var gap := absf(to_him)
			velocity.x = signf(to_him) * drift_speed if gap > 2.2 else 0.0
			if _mode_time >= rest_time * pace:
				_choose_move(gap)
		&"slash_tell":
			velocity.x = 0.0
			var windup := (double_windup if _second_slash else (ambush_windup if _ambush else slash_windup)) * pace
			if _mode_time >= windup:
				_ambush = false
				_set_mode(&"slash")
				_hit_this_swing = false
				_arc_clock = 0.0
				Sound.play(self, &"slash", 4.0)
		&"slash":
			velocity.x = _facing * 2.5
			if not _hit_this_swing:
				_swing_hits(slash_reach, slash_height, 1)
			if _mode_time >= slash_strike:
				if not _second_slash and _rng.randf() < double_chance:
					_second_slash = true
					_set_mode(&"slash_tell")
				else:
					_second_slash = false
					_set_mode(&"recover")
		&"recover":
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			if _mode_time >= slash_recover * pace:
				_set_mode(&"idle")
		&"glide_tell":
			velocity.x = -_facing * 0.6
			if _mode_time >= glide_windup * pace:
				_set_mode(&"glide")
				_hit_this_swing = false
				Sound.play(self, &"dash", 4.0)
		&"glide":
			velocity.x = _facing * glide_speed
			if not _hit_this_swing:
				_swing_hits(0.9, glide_band.y - glide_band.x, 2, glide_band.x)
			var past := (global_position.x - _glide_target) * _facing >= 0.0
			if past or is_on_wall():
				_facing = -_facing
				_set_mode(&"recover")
		&"rain":
			velocity.x = 0.0
			_rain_clock -= delta
			if _rain_left > 0 and _rain_clock <= 0.0:
				_rain_left -= 1
				_rain_clock = rain_time * 0.8 / float(_rain_drops_now())
				_drop_ink()
			if _mode_time >= rain_time:
				_set_mode(&"idle")
		&"volley_tell":
			velocity.x = 0.0
			_facing = signf(to_him) if to_him != 0.0 else _facing
			if _mode_time >= volley_windup * pace:
				_set_mode(&"volley")
				_volley_left = volley_count
				_volley_clock = 0.0
		&"volley":
			velocity.x = 0.0
			_volley_clock -= delta
			if _volley_left > 0 and _volley_clock <= 0.0:
				_volley_left -= 1
				_volley_clock = volley_gap * pace
				_fling_blade()
			if _volley_left == 0 and _volley_clock <= -0.3:
				_set_mode(&"recover")
		&"vanish_tell":
			velocity.x = 0.0
			if _mode_time >= vanish_tell * pace:
				_set_mode(&"sinking")
				_pool.splash()
				Sound.play(self, &"ink_bleed", 4.0)
		&"sinking":
			velocity.x = 0.0
			if _mode_time >= sink_time:
				_set_mode(&"vanished")
				puppet.visible = false
				_pool.close(0.1, 0.5)
				# The pool behind him (the side he is not facing) spreads first.
				var behind := -ronin.facing
				var x := ronin.global_position.x + behind * 1.9
				if x < arena.x + 1.2 or x > arena.y - 1.2:
					x = ronin.global_position.x - behind * 1.9
				global_position.x = clampf(x, arena.x + 1.0, arena.y - 1.0)
				_facing = signf(ronin.global_position.x - global_position.x)
				_spread_pool(vanish_time * 0.9)
		&"vanished":
			velocity.x = 0.0
			if _mode_time >= vanish_time:
				_set_mode(&"rising")
				puppet.visible = true
				_pool.splash()
				_drips.emitting = true
				Sound.play(self, &"mask_creak", 2.0)
		&"rising":
			velocity.x = 0.0
			if _mode_time >= rise_time:
				_drips.emitting = false
				_pool.close(0.4, 0.8)
				_ambush = true
				_set_mode(&"slash_tell")
		&"masks_tell":
			velocity.x = 0.0
			if _mode_time >= mask_tell * pace:
				_set_mode(&"idle")
		&"swat":
			velocity.x = 0.0
			if _mode_time >= swat_time:
				_set_mode(&"recover")
				_mode_time = slash_recover * pace * 0.5
		&"stagger":
			velocity.x = 0.0
			if _mode_time >= stagger_time:
				posture = 0
				posture_changed.emit(posture, max_posture)
				_set_mode(&"idle")
	move_and_slide()
	position.z = 0.0
	global_position.x = clampf(global_position.x, arena.x + 1.0, arena.y - 1.0)
	_check_touch()


func _process(delta: float) -> void:
	if not puppet:
		return
	# She turns to face him, a little toward the camera, like the Ronin.
	puppet.rotation.y = lerp_angle(puppet.rotation.y, (PI * 0.5 - 0.45) if _facing > 0.0 else (-PI * 0.5 + 0.45), 1.0 - exp(-8.0 * delta))
	var pace := enraged_pace if health <= max_health / 2 else 1.0
	match _mode:
		&"wait":
			puppet.pose = HannyaPoses.menace(_clock)
		&"idle", &"recover":
			puppet.pose = HannyaPoses.menace(_clock)
		&"slash_tell":
			var windup := (double_windup if _second_slash else (ambush_windup if _ambush else slash_windup)) * pace
			puppet.pose = HannyaPoses.slash(clampf(_mode_time / windup, 0.0, 1.0) * 0.35)
		&"slash":
			puppet.pose = HannyaPoses.slash(0.35 + clampf(_mode_time / slash_strike, 0.0, 1.0) * 0.4)
		&"swat":
			# A short, quick backhand: half the slash, fast.
			var u := clampf(_mode_time / swat_time, 0.0, 1.0)
			puppet.pose = HannyaPoses.slash(0.3 + smoothstep(0.0, 0.45, u) * 0.4 - smoothstep(0.6, 1.0, u) * 0.3)
		&"glide_tell":
			var u := clampf(_mode_time / (glide_windup * pace), 0.0, 1.0)
			puppet.pose = HannyaPoses.glide_tell(u)
			puppet.position.y = glide_lift * smoothstep(0.0, 0.6, u) + sin(_clock * 9.0) * 0.03 * u
		&"glide":
			puppet.pose = HannyaPoses.glide()
			puppet.position.y = glide_lift
		&"rain", &"masks_tell":
			puppet.pose = HannyaPoses.cover_face(_clock)
		&"volley_tell":
			puppet.pose = HannyaPoses.slash(clampf(_mode_time / (volley_windup * pace), 0.0, 1.0) * 0.35)
		&"volley":
			# A fling for each blade.
			var beat := 1.0 - clampf(_volley_clock / maxf(volley_gap * pace, 0.01), 0.0, 1.0)
			puppet.pose = HannyaPoses.slash(0.35 + beat * 0.3)
		&"sinking":
			# Down into the ink: slow for an instant, then fast.
			var u := clampf(_mode_time / sink_time, 0.0, 1.0)
			puppet.position.y = -sink_depth * u * u * u
			puppet.pose = HannyaPoses.cover_face(_clock)
		&"rising":
			# Up out of it: a slow emergence, then a surge to her full height,
			# head bowed until the very end.
			var u := clampf(_mode_time / rise_time, 0.0, 1.0)
			var up := 1.0 - pow(1.0 - u, 3.0)
			puppet.position.y = -sink_depth * (1.0 - up)
			var risen := HannyaPoses.slash(0.0)
			var bowed := HannyaPoses.cover_face(_clock)
			puppet.pose = SamuraiAnimator.mix(bowed, risen, smoothstep(0.5, 1.0, u))
		&"vanish_tell":
			var shudder := HannyaPoses.menace(_clock)
			shudder["hips"] = (shudder["hips"] as Vector3) + Vector3(sin(_clock * 70.0) * 0.03, 0.0, 0.0)
			shudder["head"] = (shudder["head"] as Vector3) + Vector3(0.0, sin(_clock * 53.0) * 8.0, 0.0)
			puppet.pose = shudder
		&"stagger":
			puppet.pose = HannyaPoses.broken(_clock)
		&"dead":
			puppet.pose = HannyaPoses.fall(clampf(_mode_time / 1.4, 0.0, 1.0))
	_update_arc(delta)
	# The finishing seal, stamped on her back while she is staggered.
	_seal_show = move_toward(_seal_show, 1.0 if _mode == &"stagger" else 0.0, delta / 0.15)
	_seal.visible = _seal_show > 0.0
	if _seal.visible:
		_seal.global_position = puppet.back_position() + Vector3(0.0, 0.1, 0.45)
		_seal.scale = Vector3.ONE * maxf(smoothstep(0.0, 1.0, _seal_show), 0.001)


## He has walked into her. Only while she is solid and in the courtyard
## (not under the ink, not broken, not dying).
func _check_touch() -> void:
	# (Not while she is gathering for or flying her glide: then she is in the
	# air and her sweep has its own height, so he can duck under her.)
	if not active or _mode in [&"sinking", &"vanished", &"rising", &"stagger", &"dead", &"wait", &"glide_tell", &"glide"]:
		return
	for body: Node3D in _touch.get_overlapping_bodies():
		if body.has_method("take_damage") and body.take_damage(contact_damage, global_position):
			if _mode in [&"idle", &"recover"]:
				_facing = signf(body.global_position.x - global_position.x)
				if _facing == 0.0:
					_facing = 1.0
				_set_mode(&"swat")
				_arc_clock = 0.0
				Sound.play(self, &"slash", 2.0)


func _choose_move(gap: float) -> void:
	var enraged := health <= max_health / 2
	var roll := _rng.randf()
	if enraged and _clock - _last_masks > 10.0 and roll < 0.3:
		_summon_masks()
		return
	if gap < 3.4:
		if roll < 0.6:
			_set_mode(&"slash_tell")
		elif roll < 0.8:
			_set_mode(&"vanish_tell")
		else:
			_start_glide()
		return
	if _clock - _last_rain > 9.0 and roll < 0.3:
		_last_rain = _clock
		_rain_left = _rain_drops_now()
		_rain_clock = 0.3
		_set_mode(&"rain")
		Sound.play(self, &"hannya_sob_short")
	elif roll < 0.6:
		_set_mode(&"volley_tell")
	elif roll < 0.8:
		_start_glide()
	else:
		_set_mode(&"vanish_tell")


func _start_glide() -> void:
	# Glide right across him, to the far side.
	var side := signf(ronin.global_position.x - global_position.x)
	_facing = side
	_glide_target = clampf(ronin.global_position.x + side * 4.0, arena.x + 1.5, arena.y - 1.5)
	_set_mode(&"glide_tell")


## A parried blade or mask: posture, as if she had been parried herself.
func projectile_parried(cost: int) -> void:
	if _mode == &"dead":
		return
	posture = mini(posture + cost, max_posture)
	_posture_clock = 0.0
	posture_changed.emit(posture, max_posture)
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger", 4.0)


## The glide's warning: a streak of cold, pale light races along the ground
## from her to where she will stop, then is wiped away behind her as she
## flies.
func _show_path() -> void:
	var from := global_position.x
	var length := _glide_target - from
	if absf(length) < 0.5:
		return
	_path.global_transform = Transform3D(
			Basis(Vector3(length, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 1.0)),
			Vector3(from, global_position.y + 0.03, 0.1))
	_path.visible = true
	var look := _path.material_override as ShaderMaterial
	look.set_shader_parameter(&"tail", -0.12)
	var draw := create_tween()
	draw.tween_method(func(v: float) -> void: look.set_shader_parameter(&"head", v), 0.0, 1.03,
			glide_windup * 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _wipe_path() -> void:
	var look := _path.material_override as ShaderMaterial
	var wipe := create_tween()
	wipe.tween_method(func(v: float) -> void: look.set_shader_parameter(&"tail", v), -0.12, 1.0, 0.35)
	wipe.tween_callback(func() -> void: _path.visible = false)


## A pool of ink spreads where she stands.
func _spread_pool(time: float) -> void:
	_pool = InkPool.new()
	get_parent().add_child(_pool)
	_pool.global_position = Vector3(global_position.x, global_position.y, 0.0)
	_pool.open(time)


func _fling_blade() -> void:
	var blade := InkBlade.new()
	blade.direction = _facing
	blade.speed = blade_speed
	blade.target = ronin
	blade.boss = self
	blade.arena = arena
	get_parent().add_child(blade)
	blade.global_position = global_position + Vector3(_facing * 1.0, blade_height, 0.0)
	Sound.play(self, &"slash", 2.0)


func _summon_masks() -> void:
	_last_masks = _clock
	_set_mode(&"masks_tell")
	Sound.play(self, &"hannya_sob_short", 3.0)
	for i in 3:
		var mask := PhantomMask.new()
		mask.boss = self
		mask.target = ronin
		mask.slot = i
		mask.dive_at = 1.5 + i * mask_gap
		mask.arena = arena
		get_parent().add_child(mask)
		mask.global_position = global_position + Vector3(0.0, 2.4, 0.0)


func _rain_drops_now() -> int:
	return rain_drops + (4 if health <= max_health / 2 else 0)


func _set_mode(next: StringName) -> void:
	var was := _mode
	_mode = next
	_mode_time = 0.0
	_wisps.emitting = next == &"glide_tell" or next == &"glide"
	if next == &"glide_tell":
		Sound.play(self, &"hannya_wail")
		_show_path()
	if was == &"glide" and next != &"glide":
		_wipe_path()
	if next == &"vanish_tell":
		_spread_pool(vanish_tell * 0.9)
	if puppet and next not in [&"sinking", &"vanished", &"rising", &"glide_tell", &"glide"]:
		puppet.position.y = 0.0
	if puppet:
		puppet.snap(puppet.pose)


## Anything of his inside the sweep in front of her. Parried: posture.
func _swing_hits(reach: float, height: float, posture_cost: int, bottom: float = 0.0) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(reach, height, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_facing * (reach * 0.5 + 0.2), bottom + height * 0.5, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 4):
		var target: Object = result["collider"]
		if not target.has_method("receive_strike"):
			continue
		_hit_this_swing = true
		if target.receive_strike(1, global_position):
			_parried(posture_cost)
		return


func _parried(cost: int) -> void:
	posture = mini(posture + cost, max_posture)
	_posture_clock = 0.0
	posture_changed.emit(posture, max_posture)
	velocity.x = -_facing * 3.0
	if posture >= max_posture:
		_set_mode(&"stagger")
		Sound.play(self, &"stagger", 4.0)
		_second_slash = false
	elif _mode == &"glide":
		_set_mode(&"recover")


## One ink tear: a stain spreads where it will land, then it falls.
func _drop_ink() -> void:
	var x := ronin.global_position.x
	if _rain_left % 3 != 0:
		x += _rng.randf_range(-4.0, 4.0)
	x = clampf(x, arena.x + 0.6, arena.y - 0.6)
	var ground := global_position.y
	var drop := InkDrop.new()
	drop.target = ronin
	drop.warning = drop_warning
	drop.radius = drop_radius
	get_parent().add_child(drop)
	drop.global_position = Vector3(x, ground, 0.0)


func _die() -> void:
	_set_mode(&"dead")
	active = false
	_music.stop()
	Sound.play(self, &"taiko_hit")
	await get_tree().create_timer(1.6).timeout
	if ending_follows:
		# The ending (hannya_ending.gd) takes it from here: she stays, fallen.
		Sound.duck_music(false)
		defeated.emit()
		return
	Confetti.burst(get_parent(), puppet.back_position(), 160)
	Confetti.burst(get_parent(), puppet.back_position() + Vector3(0.0, 0.8, 0.0), 120)
	Sound.play(self, &"paper_burst", 6.0)
	puppet.visible = false
	Sound.duck_music(false)
	defeated.emit()


# --- Looks ---------------------------------------------------------------------

## The arc of ink a slash leaves: drawn on with the sweep, then wiped away.
func _build_arc() -> void:
	var tall := SurfaceTool.new()
	tall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 28
	for i in steps:
		for corner: Array in [[0, 0.0], [1, 0.0], [1, 1.0], [0, 0.0], [1, 1.0], [0, 1.0]]:
			var t := float(i + corner[0]) / steps
			var across: float = corner[1]
			# From high behind her, over, and down in front.
			var angle := lerpf(deg_to_rad(120.0), deg_to_rad(-40.0), t)
			var wide := 0.45 * pow(sin(PI * t), 0.6)
			var radius := slash_reach * 0.92 - wide * (1.0 - across)
			tall.set_uv(Vector2(t, across))
			tall.add_vertex(Vector3(cos(angle) * radius, sin(angle) * radius, 0.0))
	_arc = MeshInstance3D.new()
	_arc.mesh = tall.commit()
	var look := ShaderMaterial.new()
	look.shader = preload("res://shaders/slash_sweep.gdshader")
	look.set_shader_parameter(&"tint", Color(0.05, 0.05, 0.09, 0.92))
	_arc.material_override = look
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arc.position = Vector3(0.0, 1.2, 0.5)
	add_child(_arc)


func _update_arc(delta: float) -> void:
	var look := _arc.material_override as ShaderMaterial
	if _arc_clock < 0.0:
		look.set_shader_parameter(&"head", 0.0)
		return
	_arc_clock += delta
	var life := slash_strike + 0.2
	var through := clampf(_arc_clock / life, 0.0, 1.0)
	_arc.scale = Vector3(_facing, 1.0, 1.0)
	look.set_shader_parameter(&"head", smoothstep(0.0, 0.45, through) * 1.03)
	look.set_shader_parameter(&"tail", pow(clampf((through - 0.45) / 0.55, 0.0, 1.0), 1.5) * 1.12 - 0.12)
	if through >= 1.0:
		_arc_clock = -1.0


func _build_seal() -> void:
	_seal = Node3D.new()
	add_child(_seal)
	var seal := PaperMesh.new(204)
	seal.shade_jitter = 0.0
	seal.color = PaperMesh.VERMILION
	var r := 0.2
	seal.quad(Vector3(0.0, -r, 0.0), Vector3(r * 0.8, 0.0, 0.0), Vector3(0.0, r, 0.0), Vector3(-r * 0.8, 0.0, 0.0))
	seal.color = PaperMesh.WASHI
	var c := 0.05
	seal.quad(Vector3(0.0, -c, 0.012), Vector3(c * 0.8, 0.0, 0.012), Vector3(0.0, c, 0.012), Vector3(-c * 0.8, 0.0, 0.012))
	_seal.add_child(seal.build(Color.WHITE, 0.0, true))
	_seal.visible = false
