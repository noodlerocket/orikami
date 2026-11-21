extends Node3D
## The root of the test scene. It only introduces the pieces to each other:
## the camera follows the Ronin, the HUD listens to him, hits shake the camera.
## It also fades the screen out and in when he falls into a pit.

@export_group("Falling in a pit")
## Seconds for the screen to fade to black after he falls in.
@export var pit_fade_out := 0.45
## Seconds it stays black while he is put back at the start.
@export var pit_hold := 0.25
## Seconds for the screen to fade back in.
@export var pit_fade_in := 0.7
## The colour it fades to: sumi ink, not pure black.
@export var pit_fade_color := Color(0.03, 0.03, 0.06)

var _fade: ColorRect
var _cutscene_played := false
var _boss: HannyaBoss
var _boss_bar: BossBar

@onready var _ronin: Ronin = $Ronin
@onready var _camera: FollowCamera = $Camera
@onready var _hud: Hud = $Overlay/HUD


func _ready() -> void:
	_apply_debug_start()
	_camera.target = _ronin
	_camera.snap_to_target()
	_hud.watch(_ronin)
	_ronin.slash_landed.connect(_camera.add_shake.bind(0.07))
	_ronin.hurt.connect(_camera.add_shake.bind(0.22))
	_ronin.parried.connect(_camera.add_shake.bind(0.12))
	_ronin.fell_in_pit.connect(_on_fell_in_pit)
	_ronin.died.connect(_on_died)
	_build_fade()
	_debug_screenshot()


func _process(_delta: float) -> void:
	var in_arena := _ronin.global_position.x > Village.ARENA.x + 0.6
	# Walking into the shrine courtyard for the first time plays the cutscene.
	if not _cutscene_played and in_arena:
		play_hannya_cutscene()
	# After that: coming back in (after dying) starts the fight again. (The
	# courtyard is sealed while she fights, so it cannot be walked out of.)
	if _boss and is_instance_valid(_boss) and _boss.health > 0:
		if not _boss.active and in_arena and _ronin.global_position.x > Village.ARENA.x + 2.0:
			_begin_fight()


## The cutscene before the Weeping Hannya fight.
func play_hannya_cutscene() -> void:
	_cutscene_played = true
	var scene := HannyaCutscene.new()
	scene.main = self
	scene.ronin = _ronin
	scene.village = $Village
	scene.stage = $Village.stage
	scene.game_camera = _camera
	scene.finished.connect(_start_boss_fight)
	add_child(scene)


## After the cutscene: the Hannya steps down onto the courtyard and the fight
## begins.
func _start_boss_fight() -> void:
	var stage: HannyaStage = $Village.stage
	_boss = HannyaBoss.new()
	_boss.ronin = _ronin
	_boss.arena = Vector2(Village.ARENA.x, Village.ARENA.y)
	$Village.add_child(_boss)
	_boss.global_position = Vector3(stage.global_position.x + 1.5, stage.global_position.y, 0.0)
	_boss.take_puppet(stage.hannya)
	_boss_bar = BossBar.new()
	_boss_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	$Overlay.add_child(_boss_bar)
	_boss_bar.watch(_boss)
	_boss.defeated.connect(func() -> void:
		$Village.relight_arena_lanterns()
		$Village.set_arena_sealed(false))
	_begin_fight()


## A sheet over the whole screen (above the HUD too), normally see-through.
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = pit_fade_color
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	layer.add_child(_fade)


## He has died: the screen fades out, he is put back together at the start,
## and the fight (if there was one) resets; then the screen fades in.
func _on_died() -> void:
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, pit_fade_out).set_trans(Tween.TRANS_SINE)
	await out.finished
	_ronin.revive()
	if _boss and is_instance_valid(_boss) and _boss.health > 0 and _boss.active:
		_boss.reset()
		_boss_bar.hide_bar()
		$Village.set_arena_sealed(false)
	_camera.snap_to_target()
	await get_tree().create_timer(pit_hold).timeout
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, pit_fade_in).set_trans(Tween.TRANS_SINE)


func _begin_fight() -> void:
	_boss.begin()
	$Village.set_arena_sealed(true)


func _on_fell_in_pit() -> void:
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, pit_fade_out).set_trans(Tween.TRANS_SINE)
	await out.finished
	_ronin.respawn_at_checkpoint()
	_camera.snap_to_target()
	await get_tree().create_timer(pit_hold).timeout
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, pit_fade_in).set_trans(Tween.TRANS_SINE)


# --- Developer tools -------------------------------------------------------
# Optional launch arguments, written after a "--" on the command line:
#   --x=20                 start the Ronin at x = 20
#   --screenshot=shot.png  save a picture after a moment, then quit
#   --zoom=4               put the camera this close, for a look at the Ronin
#   --face=-1              start facing left
#   --hold=move_right      hold a control down (to photograph him running)
#   --marks=0.5            start this inked (0 = blank, 1 = covered)
#   --cutscene             play the Hannya cutscene straight away

func _apply_debug_start() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--x="):
			_ronin.position.x = float(arg.trim_prefix("--x="))
			_ronin.position.y += 3.0
		elif arg.begins_with("--zoom="):
			_camera.distance = float(arg.trim_prefix("--zoom="))
			_camera.height_offset = 0.95
			_camera.min_y = 0.0
			_camera.follow_height = 1.0  # close-ups follow him up onto platforms
			_camera.climb_zone = Vector2.ZERO  # and keep him centred, climbing or not
			_camera.min_x = -1000.0
			_camera.max_x = 1000.0
			_camera.look_ahead = 0.0
			_camera.rotation_degrees.x = 0.0
		elif arg.begins_with("--face="):
			_ronin.facing = signf(float(arg.trim_prefix("--face=")))
		elif arg.begins_with("--marks="):
			var amount := float(arg.trim_prefix("--marks="))
			_ronin.ink_absorbed = roundi(amount * _ronin.marks_full_at)
			_ronin.get_node("Puppet").set_marks_now(amount)
		elif arg == "--cutscene":
			_ronin.position = Vector3(43.2, 1.6, 0.0)
			play_hannya_cutscene.call_deferred()
		elif arg.begins_with("--hold="):
			Input.action_press(arg.trim_prefix("--hold="))


func _debug_screenshot() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			await get_tree().create_timer(2.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--screenshot="))
			get_tree().quit()
