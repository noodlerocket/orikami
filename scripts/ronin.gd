class_name Ronin
extends CharacterBody3D
## The Blank Ronin's controls and rules: run, jump, dash, slash, pogo, heal.
## The look lives in ronin_puppet.gd; this file is only about how he MOVES.
##
## Every number below is an @export, so you can select the Ronin node in the
## editor and tune it in the Inspector without touching code.

signal health_changed(current: int, maximum: int)
signal ink_changed(current: int, maximum: int)
signal slash_landed
signal hurt
signal parried
## He has fallen into a pit: the screen should fade out, then call
## respawn_at_checkpoint() (main.gd does this).
signal fell_in_pit
## He has died (shredded): the screen should fade out, then call revive()
## (main.gd does this).
signal died
## He dashed (the village stirs fallen petals in his wake).
signal dashed(at: Vector3, direction: float)

@export_group("Run")
@export var run_speed := 7.5
## How fast he reaches full speed. Higher = snappier.
@export var ground_acceleration := 120.0
## How fast he stops when you let go. Higher = less sliding.
@export var ground_deceleration := 140.0
@export var air_acceleration := 90.0

@export_group("Jump")
## Upward speed at take-off. Jump height is roughly jump_velocity^2 / (2 * gravity).
@export var jump_velocity := 13.5
@export var gravity := 38.0
## Extra gravity while falling, so jumps feel less floaty.
## (1.25 and a top speed of 22 were "too fast for paper": Julian.)
@export var fall_gravity_multiplier := 1.0
@export var max_fall_speed := 17.0
## Letting go of jump early multiplies upward speed by this (variable height).
@export var jump_cut_multiplier := 0.4
## Grace period: you can still jump this long after walking off a ledge.
@export var coyote_time := 0.09
## Grace period: a jump pressed this long before landing still counts.
@export var jump_buffer_time := 0.11

@export_group("Dash")
@export var dash_speed := 19.0
@export var dash_duration := 0.17
@export var dash_cooldown := 0.4

@export_group("Slash")
@export var slash_damage := 1
## How long the blade can hit things after the button press.
@export var slash_active_time := 0.12
@export var slash_cooldown := 0.3
## How far in front of the body the hit area is centred.
@export var slash_reach := 1.05
## Hit area size: (length along the swing, width across it).
## The cut hits out to slash_reach + half the length = 1.9 m, which is where
## the white swoosh ends (RoninPuppet.sweep_reach). Keep the two in step:
## a cut should hit what the swoosh touches and nothing beyond it.
## (1.6 m was a little short.)
@export var slash_size := Vector2(1.7, 1.4)
## Upward bounce when a downward slash connects.
@export var pogo_velocity := 12.0
## Push-back when a sideways slash connects.
@export var recoil_speed := 5.0
@export var recoil_time := 0.08
## Tiny freeze on hit that makes blows feel heavy.
@export var hit_stop_time := 0.05

@export_group("Wall")
## Sliding down a wall: the fastest he falls while clinging to it.
@export var wall_slide_speed := 2.6
## A wall jump: how hard he is thrown away from the wall, and upward.
@export var wall_jump_push := 7.5
@export var wall_jump_velocity := 13.0
## For this long after a wall jump the push is not overridden by the stick,
## so the jump carries him out before you can steer back.
@export var wall_jump_lock := 0.14
## A jump pressed this long after leaving the wall still counts as a wall jump.
@export var wall_coyote := 0.1
## Holding away from the wall this long lets go of it.
@export var wall_let_go_time := 0.15
## Any wall reaching this high above his feet can be clung to (lower ones,
## like a step or a crate, are climbed over instead).
@export var cling_check_height := 1.2

@export_group("Parry")
## After pressing parry, a blow that lands within this many seconds is
## deflected. Smaller = harder. (Sekiro's is roughly 0.2.)
@export var parry_window := 0.2
## Seconds before he can parry again, so mashing the button does not work.
@export var parry_cooldown := 0.45
## Freeze on a deflect, a little longer than a hit's, so it feels weighty.
@export var parry_hit_stop := 0.09
## How far a deflect pushes him back, in metres per second.
@export var parry_push := 3.5
## A parry is also good for this long after a deflect, so a quick second
## blow straight after the first can be caught too.
@export var parry_chain_time := 0.25
## A finishing cut on a staggered enemy freezes the game this long.
@export var finish_hit_stop := 0.14
## Extra ink for a finishing cut, on top of ink_per_hit.
@export var finish_ink := 2

@export_group("Iaijutsu draw")
## Seconds in the stance before the draw is ready. Let go sooner and he just
## stands up again.
@export var draw_charge_time := 0.45
## How far the draw carries him, in metres, and how long it takes.
@export var draw_distance := 4.6
@export var draw_time := 0.13
@export var draw_damage := 2
## The cut lands this long after he arrives (the enemies he passed through
## fall a moment later, like the classic draw).
@export var draw_cut_delay := 0.07
## How tall the band he cuts through is (metres), centred on his body.
@export var draw_height := 1.5
## Safe from harm for this long after the draw starts.
@export var draw_safe_time := 0.35
## Holding the draw key (K) within this long of a parry skips the charge:
## straight into a ready stance (the parry-then-draw combo).
@export var draw_combo_window := 0.6

@export_group("Duck")
## Holding down (S) on the ground: he crouches low and his body shrinks to
## this height (metres), under the Hannya's glide.
@export var duck_height := 0.85
## Ducked, he can shuffle along this fast (metres per second), to get
## through a crawlspace. Under a low ceiling he stays ducked until he is out.
@export var crawl_speed := 2.0

@export_group("Crane Glide")
## Learned in the Bamboo of Folded Wind. In the air, falling, hold jump:
## paper wings unfold and he glides.
@export var has_glide := false
## The fastest he sinks while gliding (metres per second). (1.4 was too
## kind: from the bamboo tops he could cross the whole grove.)
@export var glide_fall_speed := 2.0
## How strongly gravity pulls while gliding (1 = as usual).
@export var glide_gravity := 0.25
## How fast he glides forward (metres per second). (Was 9.)
@export var glide_speed := 8.0
## How long the wings hold him up in one flight (seconds). Then they tire
## and fold away and he falls. Landing, clinging to a wall, a pogo bounce or
## a rising gust (Updraft) gives them back.
@export var glide_time := 2.0
## The wings start to tire (droop and tremble) this long before they give out.
@export var glide_tire_warning := 0.6
## How loud the soft paper rustle is as the wings start to tire (dB).
@export var tire_sound_db := -14.0
## How fast a rising gust lifts him while he glides (metres per second).
@export var updraft_lift := 7.0
## How quickly he is caught up to that lift (metres per second, per second).
@export var updraft_catch := 22.0
## How much the wind carries him while gliding (gusts push the wings).
@export var glide_wind := 0.35

@export_group("Forgiveness")
## Jumping up into the corner of a ledge: if he would have cleared it with
## his head this far to one side, he is nudged round it.
@export var corner_nudge := 0.32
## Coming up just short of a ledge's top (by up to this much), moving
## toward it, he is lifted onto it.
@export var ledge_hop := 0.42
## A sharp turn at a run: he skids for this long (seconds).
@export var skid_time := 0.2
## After getting wet (canal water, a sluice), standing still this long he
## shakes the water off.
@export var shake_after := 0.35

@export_group("Ladder")
## Climbing a ladder (W up, S down), in metres per second.
@export var climb_speed := 3.2

@export_group("Water")
## Wading in shallow water: his run is this fraction of its usual speed.
@export var wading_speed := 0.6
## Fallen into the river or deep water: how fast he sinks out of sight
## (metres per second) while the screen fades. He used to stop on the river's
## bed, still half out of the water (Julian: "sink quicker").
@export var sink_speed := 5.0
## How far down he sinks (metres): enough to be gone under the water.
@export var sink_depth := 2.2

@export_group("Block")
## Holding parry keeps his guard up after the parry window: a blow from the
## front is blocked (no harm, a push back). This many blocks close together
## break his guard and stun him.
@export var block_breaks_after := 2
## How long a broken guard leaves him stunned and open.
@export var guard_break_stun := 0.9
## Seconds without being hit before one block is forgotten.
@export var block_recover_time := 2.0
## How hard a blocked blow pushes him back.
@export var block_push := 4.0
## While guarding he can only shuffle, at this fraction of his run speed.
@export var guard_walk := 0.3

@export_group("Health and Ink")
@export var max_health := 5
## Seconds of safety after being hurt.
@export var invulnerable_time := 1.0
@export var hurt_knockback := Vector2(8.0, 8.0)
@export var hurt_lock_time := 0.25
@export var max_ink := 9
@export var ink_per_hit := 1
@export var heal_cost := 3
## Every drop of ink he takes in marks his paper for good. At this many
## drops (in total, over the whole game) he is covered in ink.
@export var marks_full_at := 150
## How long K must be held to heal one point.
@export var heal_hold_time := 0.9
## Falling below this height (into a pit) fades the screen out and puts him
## back at the start of the level.
@export var fall_limit_y := -11.0
## Health lost for falling in.
@export var pit_damage := 1
## Seconds between shredding and the screen starting to fade.
@export var respawn_delay := 1.3

const ENEMY_LAYER_MASK := 4
const BODY_CENTER := Vector3(0.0, 0.75, 0.0)
# Slash directions use "y up" like the 3D world. (Godot's own Vector2.UP points
# the other way, because 2D screens count y downward, so we avoid it here.)
const SLASH_UP := Vector2(0.0, 1.0)
const SLASH_DOWN := Vector2(0.0, -1.0)

var health := 0
var ink := 0
## All the ink he has ever taken in. It never goes down (spending ink to heal
## does not wash it off): it is what marks his body.
var ink_absorbed := 0
## 1 = facing right, -1 = facing left.
var facing := 1.0

var _coyote := 0.0
var _jump_buffer := 0.0
var _jumping := false
var _dash_time := 0.0
var _dash_cooldown_left := 0.0
var _dash_dir := 1.0
var _can_dash := true
var _slash_time := 0.0
var _slash_cooldown_left := 0.0
var _slash_dir := Vector2.RIGHT
var _slash_hits: Array[Object] = []
var _recoil_left := 0.0
var _hurt_lock := 0.0
var _invulnerable := 0.0
## What the last blow that hurt him was: &"ink", &"fire" or &"cut".
var last_hurt_kind: StringName = &""
var _heal_progress := 0.0
var _healing := false
var _parry_time := 0.0
var _parry_cooldown_left := 0.0
var _parrying := 0.0        # time left in the parry stance (no cutting while in it)
var _guarding := false      # holding his guard up (parry held past the window)
var _ducking := false       # crouched low (holding down on the ground)
var _body_shape: CapsuleShape3D
var _stand_height := 1.5
var _blocks := 0            # blocks taken close together (the guard breaks at block_breaks_after)
var _block_clock := 0.0
var _iai := false           # crouched in the iai stance
var _iai_charge := 0.0      # seconds spent in the stance
var _drawing := 0.0         # time left in the draw's dash
var _draw_from := 0.0       # x where the draw started
var _draw_hits: Array[Object] = []
var _combo := 0.0           # time left to start the parry-then-draw combo
var _draw_safe := 0.0       # time left that the draw keeps him from harm (no ink shown)
var _wall_normal := 0.0     # +1 = a wall on his left (it pushes right), -1 = on his right, 0 = none
var _wall_coyote := 0.0     # time left in which a jump still counts as a wall jump
var _wall_side := 0.0       # the side of the last wall he touched
var _wall_lock := 0.0       # time left in a wall jump's push
var _wall_away := 0.0       # how long he has held away from the wall
var _sliding := false       # clinging to a wall and sliding down it
var _sinking := false        # in water: sinking straight down, through the bed
var _in_pit := false        # falling into a pit; waiting for the screen to fade
var _prev_physics_position := Vector3.ZERO   # where he was a physics step ago (visual_position)
var _sink_y := 0.0          # how far his puppet has sunk in deep water
var _dead := false
var _grounded_time := 0.0
var _safe_position := Vector3.ZERO
var _spawn_position := Vector3.ZERO
## Pushes from the world for this frame (metres per second, per second): a
## sluice pressing him down, a gust over the river. Whatever pushes sets it
## each frame before he moves; it is used up by the move.
var push := Vector3.ZERO
## A wind carrying him sideways this frame (metres per second): his running
## and steering aim for this speed instead of standing still. Set each frame
## by whatever blows (the gusts over the river); used up by the move.
var drift := 0.0
## True while he stands in shallow water (set each frame by the water).
var wading := false
var _crawling := false
## The ladder he is next to this frame (set each frame by the ladder).
var ladder: Ladder
var _climbing: Ladder
## Counts every time he is put back at a shrine (a fall, a death), so a
## shrine can tell being put there from walking up to it.
var respawns := 0
var _skid := 0.0
var _gliding := false
var _glide_left := 0.0   # how long the wings can still hold him (glide_time)
var _wet := 0.0       # > 0: he is still wet from the water (seconds left)
var _still := 0.0     # how long he has stood still on dry ground

@onready var _puppet: RoninPuppet = $Puppet


func _ready() -> void:
	add_to_group(&"player")
	var holder: CollisionShape3D = $CollisionShape3D
	_body_shape = holder.shape as CapsuleShape3D
	_body_shape = _body_shape.duplicate()  # its own copy, to shrink when ducking
	holder.shape = _body_shape
	_stand_height = _body_shape.height
	health = max_health
	_spawn_position = global_position
	_safe_position = global_position


## Where he is drawn: between his last two physics steps, so on a screen
## that draws faster than physics runs (60 a second) he glides instead of
## stepping, and the world following him does not judder (Julian: running
## made the world look blurry). The camera follows this too.
func visual_position() -> Vector3:
	var now := global_position
	if _prev_physics_position.distance_to(now) > 2.0:
		return now  # (a jump to somewhere else: no gliding across)
	return _prev_physics_position.lerp(now, Engine.get_physics_interpolation_fraction())


func _process(_delta: float) -> void:
	if not is_physics_processing():
		_prev_physics_position = global_position  # (held, or placed by a cutscene)
	var offset := visual_position() - global_position
	_puppet.position = Vector3(offset.x, _sink_y + offset.y, 0.0)


func _physics_process(delta: float) -> void:
	_prev_physics_position = global_position
	_count_down(delta)
	var grounded := is_on_floor()

	if _in_pit:
		velocity.x = 0.0
		if _sinking:
			# He goes down out of sight. (Only how he looks: his body stops on
			# the bed as before, so nothing below the river, in the canals,
			# notices him.)
			_sink_y = maxf(_sink_y - sink_speed * delta, -sink_depth)
		_apply_gravity(delta, grounded)
		move_and_slide()
		_update_puppet()
		return
	if _dead:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		_apply_gravity(delta, grounded)
		move_and_slide()
		_update_puppet()
		return

	# --- Read the controls ---
	var move := Input.get_axis("move_left", "move_right")
	move = signf(move) if absf(move) > 0.3 else 0.0

	if grounded:
		_coyote = coyote_time
		_glide_left = glide_time
		if _dash_time <= 0.0:
			_can_dash = true
		_grounded_time += delta
		if _grounded_time > 0.3:
			_safe_position = global_position
	else:
		_grounded_time = 0.0

	_update_heal(delta, grounded)
	if _healing:
		move = 0.0

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	var busy := _hurt_lock > 0.0 or _healing or _climbing != null
	if Input.is_action_just_pressed("dash") and _can_dash and _dash_cooldown_left <= 0.0 and not busy:
		_start_dash(move)
	if Input.is_action_just_pressed("parry") and _parry_cooldown_left <= 0.0 and _dash_time <= 0.0 and not busy:
		_start_parry()
	# Holding down on the ground: duck. A cut, parry, draw or jump ends it.
	var duck := (grounded and Input.is_action_pressed("aim_down") and not busy and _dash_time <= 0.0
			and _slash_time <= 0.0 and not _iai and _drawing <= 0.0 and _parrying <= 0.0
			and not Input.is_action_pressed("parry"))
	# Under a low ceiling he cannot stand up again (a crawlspace).
	if _ducking and not duck and grounded and _low_ceiling():
		duck = true
	_set_ducking(duck)
	_crawling = false
	if _ducking:
		if move != 0.0:
			facing = signf(move)
			_crawling = true
		move *= crawl_speed / run_speed
	elif wading:
		move *= wading_speed
	# Holding parry keeps the guard up (after the parry stance).
	_guarding = (Input.is_action_pressed("parry") and not busy and _dash_time <= 0.0
			and not _iai and _drawing <= 0.0 and _slash_time <= 0.0)
	if _guarding:
		move *= guard_walk
	if _blocks > 0:
		_block_clock += delta
		if _block_clock >= block_recover_time:
			_block_clock = 0.0
			_blocks -= 1
	_update_iai(delta, grounded, busy)
	if (Input.is_action_just_pressed("slash") and _slash_cooldown_left <= 0.0 and _dash_time <= 0.0
			and not busy and not _iai and _drawing <= 0.0 and _parrying <= 0.0):
		_start_slash(grounded)

	# A sharp turn at a run: a skid.
	_skid = maxf(_skid - delta, 0.0)
	if grounded and move != 0.0 and signf(move) != signf(velocity.x) and absf(velocity.x) > run_speed * 0.75 			and _dash_time <= 0.0 and not _ducking:
		_skid = skid_time
		_puppet.play_skid(wading)
	# --- Work out the velocity ---
	_gliding = false
	if _update_ladder(delta, grounded):
		pass
	elif _drawing > 0.0:
		# The draw: a straight, very fast line along the ground.
		velocity = Vector3(facing * draw_distance / draw_time, 0.0, 0.0)
		_sweep_draw_path()
		_drawing -= delta
		if _drawing <= 0.0 or is_on_wall():
			_drawing = 0.0
			velocity.x = facing * run_speed * 0.3
			_land_draw()
	elif _iai:
		# Crouched, perfectly still. He may turn to face the other way.
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		if move != 0.0:
			facing = move
		_apply_gravity(delta, grounded)
	elif _dash_time > 0.0:
		# Dashing: a straight horizontal burst that ignores gravity.
		velocity = Vector3(_dash_dir * dash_speed, 0.0, 0.0)
		if _dash_time - delta <= 0.0:
			velocity.x = _dash_dir * run_speed
	elif _hurt_lock > 0.0:
		# Knocked back: no control for a moment.
		_apply_gravity(delta, grounded)
	else:
		# The Crane Glide: falling, jump held, wings out.
		var lift := Updraft.lift_at(global_position)
		if lift > 0.0 and has_glide:
			_glide_left = glide_time  # (a rising gust rests the wings)
		_gliding = (has_glide and not grounded and (velocity.y < 0.5 or lift > 0.0) and Input.is_action_pressed("jump")
				and not _sliding and _climbing == null and _hurt_lock <= 0.0 and _glide_left > 0.0)
		if _gliding:
			var was := _glide_left
			_glide_left = maxf(_glide_left - delta, 0.0)
			# The wings start to give: a soft rustle of paper (once per flight).
			if was > glide_tire_warning and _glide_left <= glide_tire_warning:
				Sound.play(self, &"paper_fold", tire_sound_db)
			drift += Wind.direction.x * Wind.speed_at(global_position.x) * glide_wind
			if lift > 0.0:
				velocity.y = move_toward(velocity.y, updraft_lift * lift, updraft_catch * delta)
		if _recoil_left <= 0.0 and _wall_lock <= 0.0:
			var rate := air_acceleration
			if grounded:
				rate = ground_acceleration if move != 0.0 else ground_deceleration
			velocity.x = move_toward(velocity.x, move * (glide_speed if _gliding else run_speed) + drift, rate * delta)
			if move != 0.0 and _slash_time <= 0.0:
				facing = signf(move)
		_apply_gravity(delta, grounded)
		_update_wall(delta, grounded, move)
		if _jump_buffer > 0.0 and _wall_coyote > 0.0 and not grounded and _coyote <= 0.0:
			_wall_jump()
		elif _jump_buffer > 0.0 and _coyote > 0.0:
			velocity.y = jump_velocity
			Sound.play(self, &"jump")
			_jumping = true
			_jump_buffer = 0.0
			_coyote = 0.0
		# Variable jump height: releasing the button early cuts the jump short.
		if _jumping and velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			velocity.y *= jump_cut_multiplier
			_jumping = false
		if velocity.y <= 0.0:
			_jumping = false
		velocity += push * get_physics_process_delta_time()
		velocity.y = maxf(velocity.y, -max_fall_speed * 1.4)

	push = Vector3.ZERO
	drift = 0.0
	var rising := velocity.y
	var heading := velocity.x
	move_and_slide()
	position.z = 0.0  # Gameplay stays on a single plane.
	_forgive(rising, heading, move)
	_find_wall()
	_update_wet(delta)

	_update_slash()
	if global_position.y < fall_limit_y:
		_fell_out_of_world()
	_update_puppet()


func _set_ducking(on: bool) -> void:
	if on == _ducking:
		return
	_ducking = on
	var holder: CollisionShape3D = $CollisionShape3D
	_body_shape.height = duck_height if on else _stand_height
	_body_shape.radius = minf(0.32, _body_shape.height * 0.5)
	holder.position.y = _body_shape.height * 0.5


## Called by an enemy's ATTACK (not by touching it). Returns true if the
## blow was parried, so the attacker can be knocked off balance.
## `kind` is what the blow does to his paper if it lands (see take_damage).
func receive_strike(amount: int, from: Vector3, kind: StringName = &"ink") -> bool:
	if _dead:
		return false
	var toward := signf(from.x - global_position.x)
	if _parry_time > 0.0 and (toward == facing or toward == 0.0):
		_deflect(toward if toward != 0.0 else facing)
		return true
	if _guarding and (toward == facing or toward == 0.0) and _hurt_lock <= 0.0:
		_block(toward if toward != 0.0 else facing)
		return false  # blocked: no harm to him, but no posture lost by them either
	take_damage(amount, from, kind)
	return false


## A blow taken on his guard: no harm, a push back. Too many close together
## break the guard and leave him stunned.
func _block(toward: float) -> void:
	_blocks += 1
	_block_clock = 0.0
	velocity.x = -toward * block_push
	_recoil_left = recoil_time * 1.5
	if _blocks >= block_breaks_after:
		_blocks = 0
		_guarding = false
		_hurt_lock = guard_break_stun
		velocity = Vector3(-toward * block_push * 1.4, 3.0, 0.0)
		_puppet.play_guard_break()
		Sound.play(self, &"stagger", 2.0)
		hurt.emit()  # (shakes the camera)
		_hit_stop(parry_hit_stop)
	else:
		_puppet.play_block()
		Sound.play(self, &"parry", -7.0)
		_hit_stop(hit_stop_time)


## Called by enemies when they touch the Ronin. Returns true if it hurt him
## (false while he cannot be hurt).
## `kind` is what the blow does to his paper: &"ink" soaks it black (husks,
## the Hannya), &"fire" scorches it (burning paper, fox-fires), &"cut" tears
## a slit in it (swords, claws, teeth, beaks).
func take_damage(amount: int, from: Vector3, kind: StringName = &"ink") -> bool:
	if _invulnerable > 0.0 or _draw_safe > 0.0 or _dead:
		return false
	last_hurt_kind = kind
	_puppet.struck(kind, from)
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	hurt.emit()
	Sound.play(self, &"hurt")
	_invulnerable = invulnerable_time
	_dash_time = 0.0
	_slash_time = 0.0
	_jumping = false
	_iai = false
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	velocity = Vector3(away * hurt_knockback.x, hurt_knockback.y, 0.0)
	_hurt_lock = hurt_lock_time
	_hit_stop(hit_stop_time * 2.0)
	if health <= 0:
		_die()
	return true


func _count_down(delta: float) -> void:
	_coyote = maxf(_coyote - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_dash_time = maxf(_dash_time - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_slash_time = maxf(_slash_time - delta, 0.0)
	_slash_cooldown_left = maxf(_slash_cooldown_left - delta, 0.0)
	_recoil_left = maxf(_recoil_left - delta, 0.0)
	_hurt_lock = maxf(_hurt_lock - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_parry_time = maxf(_parry_time - delta, 0.0)
	_parry_cooldown_left = maxf(_parry_cooldown_left - delta, 0.0)
	_combo = maxf(_combo - delta, 0.0)
	_draw_safe = maxf(_draw_safe - delta, 0.0)
	_parrying = maxf(_parrying - delta, 0.0)
	_wall_coyote = maxf(_wall_coyote - delta, 0.0)
	_wall_lock = maxf(_wall_lock - delta, 0.0)


func _apply_gravity(delta: float, grounded: bool) -> void:
	if grounded and velocity.y <= 0.0:
		return
	if _gliding:
		if Updraft.lift_at(global_position) <= 0.0:
			velocity.y = maxf(velocity.y - gravity * glide_gravity * delta, -glide_fall_speed)
		return
	var pull := gravity * (fall_gravity_multiplier if velocity.y < 0.0 else 1.0)
	velocity.y = maxf(velocity.y - pull * delta, -max_fall_speed)


func _start_dash(move: float) -> void:
	Sound.play(self, &"dash")
	_dash_dir = move if move != 0.0 else facing
	facing = _dash_dir
	_dash_time = dash_duration
	_dash_cooldown_left = dash_cooldown
	_can_dash = false
	_jumping = false
	dashed.emit(global_position, _dash_dir)


func _start_slash(grounded: bool) -> void:
	Sound.play(self, &"slash")
	var aim := Input.get_axis("aim_down", "aim_up")
	if aim > 0.5:
		_slash_dir = SLASH_UP
	elif aim < -0.5 and not grounded:
		_slash_dir = SLASH_DOWN  # Down-slash only works in the air (pogo).
	else:
		_slash_dir = Vector2(facing, 0.0)
	_slash_time = slash_active_time
	_slash_cooldown_left = slash_cooldown
	_slash_hits.clear()
	_puppet.play_slash(_slash_dir)


# --- The iaijutsu draw ------------------------------------------------------

## The draw has its own key (K), so holding it crouches straight into the
## stance with no cut first. (Holding the cut key instead would have meant
## waiting before every cut to see if it was held.)
func _update_iai(delta: float, grounded: bool, busy: bool) -> void:
	if _iai:
		if busy or not grounded:
			_iai = false
			return
		_iai_charge += delta
		if not Input.is_action_pressed("draw"):
			_iai = false
			if _iai_charge >= draw_charge_time:
				_start_draw()
		return
	if (Input.is_action_pressed("draw") and grounded and not busy and _slash_time <= 0.0
			and _drawing <= 0.0 and _dash_time <= 0.0 and _parrying <= 0.0):
		# Straight after a parry, the stance is ready at once (the combo).
		_enter_iai(_combo > 0.0)


func _enter_iai(ready: bool) -> void:
	_iai = true
	_iai_charge = draw_charge_time if ready else 0.0
	_combo = 0.0


## True once the draw is charged: letting go now will draw.
func iai_ready() -> bool:
	return _iai and _iai_charge >= draw_charge_time


func _start_draw() -> void:
	Sound.play(self, &"slash", 3.0)
	_drawing = draw_time
	_draw_from = global_position.x
	_draw_hits.clear()
	_draw_safe = draw_safe_time
	_slash_cooldown_left = slash_cooldown
	_puppet.play_draw(_draw_from)


## Every frame of the draw: note every enemy inside the band between where he
## started and where he is now. They are cut when he arrives.
func _sweep_draw_path() -> void:
	var left := minf(_draw_from, global_position.x) - 0.5
	var right := maxf(_draw_from, global_position.x) + 0.5
	var shape := BoxShape3D.new()
	shape.size = Vector3(right - left, draw_height, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = ENEMY_LAYER_MASK
	query.transform = Transform3D(Basis.IDENTITY, Vector3((left + right) * 0.5, global_position.y + BODY_CENTER.y, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var target: Object = result["collider"]
		if target not in _draw_hits and target.has_method("take_hit"):
			_draw_hits.append(target)


func _land_draw() -> void:
	_sweep_draw_path()
	_puppet.end_draw(global_position.x)
	if _draw_hits.is_empty():
		return
	await get_tree().create_timer(draw_cut_delay, true, true).timeout
	var any := false
	for target: Object in _draw_hits:
		if not is_instance_valid(target):
			continue
		var finishing: bool = target.has_method("is_staggered") and target.is_staggered()
		for i in draw_damage:
			if is_instance_valid(target):
				target.take_hit(1, Vector2(facing, 0.0))
		if target.has_method("is_prop"):
			continue
		ink = mini(ink + ink_per_hit + (finish_ink if finishing else 0), max_ink)
		ink_absorbed += ink_per_hit + (finish_ink if finishing else 0)
		any = true
	if any:
		ink_changed.emit(ink, max_ink)
		slash_landed.emit()
		Sound.play(self, &"paper_cut", 2.0)
		_hit_stop(finish_hit_stop)


func _start_parry() -> void:
	_parry_time = parry_window
	_parry_cooldown_left = parry_cooldown
	_slash_time = 0.0
	_iai = false
	_parrying = _puppet.parry_time
	_puppet.play_parry()


func _deflect(toward: float) -> void:
	Sound.play(self, &"parry")
	# A good parry is rewarded: he can parry again at once.
	_parry_time = parry_chain_time
	_parry_cooldown_left = 0.0
	velocity.x = -toward * parry_push
	_recoil_left = recoil_time * 1.5
	_puppet.play_deflect()
	_parrying = maxf(_parrying, _puppet.parry_time * 0.7)
	_combo = draw_combo_window
	parried.emit()
	_hit_stop(parry_hit_stop)


## While the blade is active, ask the physics engine "what enemies are inside
## this box in front of me?" and hit each one once.
func _update_slash() -> void:
	if _slash_time <= 0.0:
		return
	var shape := BoxShape3D.new()
	if _slash_dir.x != 0.0:
		shape.size = Vector3(slash_size.x, slash_size.y, 2.0)
	else:
		shape.size = Vector3(slash_size.y, slash_size.x, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = ENEMY_LAYER_MASK
	query.transform = Transform3D(Basis.IDENTITY,
			global_position + BODY_CENTER + Vector3(_slash_dir.x, _slash_dir.y, 0.0) * slash_reach)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var target: Object = result["collider"]
		if target in _slash_hits or not target.has_method("take_hit"):
			continue
		_slash_hits.append(target)
		var finishing: bool = target.has_method("is_staggered") and target.is_staggered()
		target.take_hit(slash_damage, _slash_dir)
		_on_slash_connected(finishing, not target.has_method("is_prop"))


## `inky`: off for props (lanterns, signs, a shoji door): they bounce and
## recoil like anything else, but give no ink and make their own sound.
func _on_slash_connected(finishing: bool = false, inky: bool = true) -> void:
	if inky:
		ink = mini(ink + ink_per_hit + (finish_ink if finishing else 0), max_ink)
		ink_absorbed += ink_per_hit + (finish_ink if finishing else 0)
		ink_changed.emit(ink, max_ink)
		slash_landed.emit()
		Sound.play(self, &"paper_cut")
	if _slash_dir == SLASH_DOWN:
		# Pogo: bounce up off whatever we hit, and get the air-dash back.
		velocity.y = pogo_velocity
		_jumping = false
		_can_dash = true
		_glide_left = glide_time
	elif _slash_dir.x != 0.0:
		velocity.x = -_slash_dir.x * recoil_speed
		_recoil_left = recoil_time
	_hit_stop(finish_hit_stop if finishing else hit_stop_time)


func _update_heal(delta: float, grounded: bool) -> void:
	_healing = (grounded and Input.is_action_pressed("heal") and ink >= heal_cost
			and health < max_health and _hurt_lock <= 0.0 and _dash_time <= 0.0)
	if not _healing:
		_heal_progress = 0.0
		return
	_heal_progress += delta
	if _heal_progress >= heal_hold_time:
		_heal_progress = 0.0
		ink -= heal_cost
		health += 1
		Sound.play(self, &"heal")
		_puppet.play_healed()
		ink_changed.emit(ink, max_ink)
		health_changed.emit(health, max_health)


func _fell_out_of_world() -> void:
	if _in_pit or _dead:
		return
	_in_pit = true
	_iai = false
	_drawing = 0.0
	_dash_time = 0.0
	fell_in_pit.emit()


## Quality of life (Hollow Knight standard): a jump that clips a ledge's
## corner with his head slips round it; a jump that comes up just short of
## a ledge's top, moving toward it, is lifted onto it.
func _forgive(rising: float, heading: float, move: float) -> void:
	if _climbing or _drawing > 0.0:
		return
	if rising > 2.0 and is_on_ceiling():
		var step := 0.08
		while step <= corner_nudge + 0.001:
			for side: float in [-1.0, 1.0]:
				var nudged := global_transform.translated(Vector3(side * step, 0.0, 0.0))
				if not test_move(global_transform, Vector3(side * step, 0.0, 0.0)) and not test_move(nudged, Vector3(0.0, 0.2, 0.0)):
					position.x += side * step
					velocity.y = rising
					return
			step += 0.08
	if not is_on_floor() and move != 0.0 and is_on_wall() and signf(heading) == move and velocity.y > -9.0:
		for i in get_slide_collision_count():
			var hit := get_slide_collision(i)
			if _can_cling(hit.get_collider() as Node, hit.get_normal()):
				return  # (that is for clinging to)
		var lift := 0.1
		while lift <= ledge_hop + 0.001:
			var raised := global_transform.translated(Vector3(0.0, lift, 0.0))
			if not test_move(global_transform, Vector3(0.0, lift, 0.0)) and not test_move(raised, Vector3(move * 0.2, 0.0, 0.0)):
				position.y += lift
				position.x += move * 0.08
				velocity.y = maxf(velocity.y, 0.0)
				return
			lift += 0.08


## Wet from the water: once he stands still on dry ground he shakes it off.
func _update_wet(delta: float) -> void:
	if wading:
		_wet = 6.0
	_wet = maxf(_wet - delta, 0.0)
	if _wet > 0.0 and not wading and is_on_floor() and absf(velocity.x) < 0.3 and not _ducking and _slash_time <= 0.0:
		_still += delta
		if _still >= shake_after:
			_wet = 0.0
			_still = 0.0
			_puppet.play_shake()
			Sound.play(self, &"shake_off")
	else:
		_still = 0.0


## Ladders: W at the foot of one (or S at its top) and he takes hold; W/S
## climb; jump lets go; at the top he steps off onto what it leans on.
## Returns true while he is on a ladder (it has moved him).
func _update_ladder(delta: float, grounded: bool) -> bool:
	var near := ladder
	ladder = null
	if _climbing == null:
		if near == null or _hurt_lock > 0.0 or _dash_time > 0.0 or _drawing > 0.0:
			return false
		var at_foot := global_position.y < near.top - 0.4
		if (at_foot and Input.is_action_pressed("aim_up")) or (not at_foot and grounded and Input.is_action_pressed("aim_down")):
			_climbing = near
			_jumping = false
			_slash_time = 0.0
			_iai = false
			_set_ducking(false)
			if not at_foot:
				global_position.y = near.top - 0.5  # over the edge, onto the rungs
		else:
			return false
	var rungs := _climbing
	var climb := Input.get_axis("aim_down", "aim_up")
	velocity = Vector3((rungs.global_position.x - global_position.x) * 12.0, climb * climb_speed, 0.0)
	_jump_buffer = 0.0
	if Input.is_action_just_pressed("jump") or _hurt_lock > 0.0:
		# Let go: a small hop away from it.
		_climbing = null
		velocity = Vector3(facing * 2.5, jump_velocity * 0.6 if not Input.is_action_pressed("aim_down") else 0.0, 0.0)
		return false
	if global_position.y >= rungs.top - 0.05 and climb > 0.0:
		# At the top: step off onto the deck it leans against.
		_climbing = null
		facing = rungs.step_off
		velocity = Vector3(rungs.step_off * 3.4, 5.5, 0.0)
		_wall_lock = 0.22  # (carried over the edge, not steered back)
		return false
	if grounded and climb < 0.0 and global_position.y < rungs.bottom + 0.2:
		_climbing = null
		return false
	return true


## True while he glides on paper wings.
func is_gliding() -> bool:
	return _gliding


## How tired the glide's wings are: 0 fresh, 1 about to give out.
func glide_tiredness() -> float:
	if glide_tire_warning <= 0.0:
		return 0.0
	return clampf(1.0 - _glide_left / glide_tire_warning, 0.0, 1.0)


## True while the screen fades after a fall (into water or out of the world).
func is_in_pit() -> bool:
	return _in_pit


## True while he is on a ladder.
func is_climbing() -> bool:
	return _climbing != null


## Something that drowns or carries him off (deep water, the river): the
## screen fades and he is back at the last shrine, as after a fall.
func fall_in() -> void:
	if _in_pit or _dead:
		return
	_sinking = true
	_fell_out_of_world()


## Is there something solid just over his head, too low to stand up under?
func _low_ceiling() -> bool:
	var from := global_position + Vector3(0.0, duck_height * 0.6, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * (_stand_height - duck_height * 0.6 + 0.05), 1)
	for offset: float in [-0.25, 0.0, 0.25]:
		query.from = from + Vector3(offset, 0.0, 0.0)
		query.to = query.from + Vector3.UP * (_stand_height - duck_height * 0.6 + 0.05)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return true
	return false


## True while he shuffles along ducked (in a crawlspace).
func is_crawling() -> bool:
	return _crawling


## A shrine he rested at: falls and deaths bring him back here.
func set_checkpoint(at: Vector3) -> void:
	_spawn_position = at


## Called (by main.gd) once the screen has faded out after a fall: he is
## put back at the start of the level, a point of health lighter. No ink:
## he was not struck, he fell.
func respawn_at_checkpoint() -> void:
	health = maxi(health - pit_damage, 0)
	if health <= 0:
		health = max_health  # falling to the end of your health is a death; a death respawns here too
	health_changed.emit(health, max_health)
	global_position = _spawn_position
	_safe_position = _spawn_position
	velocity = Vector3.ZERO
	facing = 1.0
	_sliding = false
	_wall_lock = 0.0
	_draw_safe = 0.6  # a moment's safety, without the struck look
	_in_pit = false
	_sinking = false
	_sink_y = 0.0
	respawns += 1


# --- Walls -------------------------------------------------------------------

## After moving: is he touching a climbable wall (one the level marked with
## the "climbable" meta)? Records which side it is on.
func _find_wall() -> void:
	_wall_normal = 0.0
	if is_on_floor():
		return
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var normal := hit.get_normal()
		var wall := hit.get_collider() as Node
		if absf(normal.x) > 0.7 and _can_cling(wall, normal):
			_wall_normal = signf(normal.x)
			_wall_side = _wall_normal
			_wall_coyote = wall_coyote
			_glide_left = glide_time  # (holding a wall rests the wings)


## Can he cling to this wall? Any solid part of the level will do (Julian:
## some walls did not let him slide or jump off them), as long as it rises
## up beside his chest, so the side of a low step or a crate is not one.
## Walls marked "no_climb" (the level's ends, the ink wall) and anything
## that is not the level itself (enemies, things to cut) are not.
func _can_cling(wall: Node, normal: Vector3) -> bool:
	if wall == null or wall.has_meta(&"no_climb"):
		return false
	if wall.has_meta(&"climbable"):
		return true
	if not (wall is StaticBody3D) or ((wall as StaticBody3D).collision_layer & 1) == 0:
		return false
	var from := global_position + Vector3(0.0, cling_check_height, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from - Vector3(signf(normal.x), 0.0, 0.0) * 0.8, 1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"] == wall


## Clinging and sliding. He clings to a wall he has jumped onto as soon as he
## starts to fall, keeps hold of it without any button held, and slides down
## slowly. Holding away from it for a moment lets go.
func _update_wall(delta: float, grounded: bool, move: float) -> void:
	var was_sliding := _sliding
	_sliding = (_wall_normal != 0.0 and not grounded and velocity.y <= 0.0
			and _wall_lock <= 0.0 and _hurt_lock <= 0.0)
	if not _sliding:
		_wall_away = 0.0
		return
	if move == _wall_normal:
		_wall_away += delta
		if _wall_away >= wall_let_go_time:
			_sliding = false
			return
	else:
		_wall_away = 0.0
		velocity.x = -_wall_normal * 1.5  # a light press, to keep touching it
	velocity.y = maxf(velocity.y, -wall_slide_speed)
	facing = _wall_normal  # back to the wall, looking out, feet braced on it
	_can_dash = true
	if not was_sliding:
		Sound.play(self, &"land", -6.0)


func _wall_jump() -> void:
	var away := _wall_side
	velocity = Vector3(away * wall_jump_push, wall_jump_velocity, 0.0)
	facing = away
	_wall_lock = wall_jump_lock
	_wall_coyote = 0.0
	_jump_buffer = 0.0
	_sliding = false
	_jumping = true
	_can_dash = true
	Sound.play(self, &"jump")
	_puppet.play_wall_jump()


## Out of health: his paper body shreds into pieces, and a moment later the
## screen fades and he is back at the start (main.gd calls revive()).
func _die() -> void:
	_dead = true
	_iai = false
	_drawing = 0.0
	_puppet.shred()
	Sound.play(self, &"paper_burst", 4.0)
	Sound.play(self, &"paper_rip", -2.0)
	await get_tree().create_timer(respawn_delay).timeout
	died.emit()


## Back at the start, whole again, at full health.
func revive() -> void:
	global_position = _spawn_position
	_safe_position = _spawn_position
	velocity = Vector3.ZERO
	facing = 1.0
	health = max_health
	health_changed.emit(health, max_health)
	_puppet.restore()
	_draw_safe = 0.8
	_invulnerable = 0.0
	_dead = false
	respawns += 1


## Freezes the whole game for a split second.
func _hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _update_puppet() -> void:
	_puppet.facing = facing
	_puppet.vertical_speed = velocity.y
	_puppet.horizontal_speed = velocity.x
	_puppet.blinking = _invulnerable > 0.0 and not _dead
	_puppet.iai_charge = clampf(_iai_charge / draw_charge_time, 0.0, 1.0)
	_puppet.guarding = _guarding
	_puppet.heal_charge = clampf(_heal_progress / heal_hold_time, 0.0, 1.0) if _healing else -1.0
	_puppet.marks = clampf(float(ink_absorbed) / maxf(marks_full_at, 1.0), 0.0, 1.0)
	if _dead or _hurt_lock > 0.0:
		_puppet.state = &"hurt"
	elif _climbing:
		_puppet.state = &"climb"
	elif _drawing > 0.0:
		_puppet.state = &"draw"
	elif _sliding:
		_puppet.state = &"wall"
	elif _ducking:
		_puppet.state = &"crawl" if _crawling else &"duck"
	elif _iai:
		_puppet.state = &"iai"
	elif _dash_time > 0.0:
		_puppet.state = &"dash"
	elif _healing:
		_puppet.state = &"heal"
	elif _gliding and not is_on_floor():
		_puppet.state = &"glide"
		_puppet.wing_tire = glide_tiredness()
	elif not is_on_floor():
		_puppet.state = &"jump" if velocity.y > 0.0 else &"fall"
	elif absf(velocity.x) > 0.5:
		_puppet.state = &"run"
	else:
		_puppet.state = &"idle"
