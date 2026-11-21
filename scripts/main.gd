extends Node3D
## The root of the test scene. It only introduces the pieces to each other:
## the camera follows the Ronin, the HUD listens to him, hits shake the camera.

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
	_debug_screenshot()


# --- Developer tools -------------------------------------------------------
# Optional launch arguments, written after a "--" on the command line:
#   --x=20                 start the Ronin at x = 20
#   --screenshot=shot.png  save a picture after a moment, then quit
#   --zoom=4               put the camera this close, for a look at the Ronin
#   --face=-1              start facing left
#   --hold=move_right      hold a control down (to photograph him running)

func _apply_debug_start() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--x="):
			_ronin.position.x = float(arg.trim_prefix("--x="))
			_ronin.position.y += 3.0
		elif arg.begins_with("--zoom="):
			_camera.distance = float(arg.trim_prefix("--zoom="))
			_camera.height_offset = 0.95
			_camera.min_y = 0.0
			_camera.min_x = -1000.0
			_camera.max_x = 1000.0
			_camera.look_ahead = 0.0
			_camera.rotation_degrees.x = 0.0
		elif arg.begins_with("--face="):
			_ronin.facing = signf(float(arg.trim_prefix("--face=")))
		elif arg.begins_with("--hold="):
			Input.action_press(arg.trim_prefix("--hold="))


func _debug_screenshot() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			await get_tree().create_timer(2.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--screenshot="))
			get_tree().quit()
