class_name WellCutscene
extends Node
## After the prologue: the Ronin comes out of the village well. Seen from
## the street, from in front (2.5D), in the rain, about 7 seconds:
##
##   0     black; the screen comes up on the well, close and low, the
##         lantern swaying in the rain
##   2.4   he springs up out of its dark mouth in one quick jump, forward,
##         toward us, clear over the front of the rim (under its roof), and
##         comes down onto the street just in front of the well
##   3.15  he lands, crouched, and straightens up
##   4.4   the camera lifts away in an arc and settles exactly where the
##         game camera will be; then the game is his
##
## He is posed by hand here (his physics is off); the camera is the
## cutscene's own until the last moment. Holding Space skips to the end.

signal finished

## Where he lands on the street: just in front of the well.
const LAND_X := -7.8

var main: Node
var ronin: Ronin
var game_camera: FollowCamera
var fade: ColorRect
var hud: CanvasItem

@export_group("Timing (seconds)")
@export var fade_in := 2.0
@export var jump_at := 2.4
@export var jump_time := 0.75
@export var glide_at := 4.4
@export var glide_time := 2.8

var _time := 0.0
var _camera: Camera3D
var _puppet: RoninPuppet
var _glide_from: Transform3D
var _glide_to: Transform3D
var _gliding := false
var _landed_sound := false
var _jump_sound := false


func _ready() -> void:
	_puppet = ronin.get_node("Puppet")
	ronin.set_physics_process(false)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	if hud:
		hud.visible = false
	_camera = Camera3D.new()
	_camera.fov = 36.0
	_camera.cull_mask &= ~Hannya.SHADOW_LAYER
	add_child(_camera)
	_camera.current = true
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	var skip := SkipPrompt.new()
	skip.hold_time = 0.6
	skip.skipped.connect(func() -> void:
		if _time < glide_at:
			_time = glide_at + glide_time)
	layer.add_child(skip)
	fade.modulate.a = 1.0
	_pose()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--well-sheet="):
			set_process(false)
			_frame_sheet.call_deferred(arg.trim_prefix("--well-sheet="))


func _process(delta: float) -> void:
	_time += delta
	fade.modulate.a = 1.0 - smoothstep(0.2, fade_in, _time)
	_pose()
	if _time >= glide_at + glide_time:
		_finish()


func _end() -> float:
	return glide_at + glide_time


## Where he is and how he stands, from the clock.
func _pose() -> void:
	var x := Village.WELL_X
	var y := -1.8   # still down in the well, out of sight
	var z := Village.WELL_Z
	var state := &"duck"
	var vertical := 0.0
	if _time >= jump_at and _time < jump_at + jump_time:
		# One quick jump: straight up out of the mouth and forward, toward us,
		# clear over the front of the rim (never through its side), and down
		# onto the street in front. Low enough to pass under the roof.
		var u := (_time - jump_at) / jump_time
		x = lerpf(Village.WELL_X, LAND_X, u)
		z = lerpf(Village.WELL_Z, 0.0, minf(u / 0.75, 1.0))   # clear of the rim before he comes down
		y = lerpf(-1.8, 0.0, u) + 8.0 * u * (1.0 - u)
		state = &"jump" if u < 0.55 else &"fall"
		vertical = 6.0 * (0.55 - u)
		if not _jump_sound:
			_jump_sound = true
			Sound.play(self, &"jump")
	elif _time >= jump_at + jump_time:
		x = LAND_X
		y = 0.0
		z = 0.0
		state = &"duck" if _time < jump_at + jump_time + 0.3 else &"idle"
		if not _landed_sound:
			_landed_sound = true
			Sound.play(self, &"land")
	ronin.global_position = Vector3(x, y, z)
	ronin.facing = 1.0
	_puppet.facing = 1.0
	_puppet.state = state
	_puppet.vertical_speed = vertical
	_puppet.horizontal_speed = 0.0
	_place_camera()


## Close and low on the well, drifting a little after him; then lifting away
## in an arc and settling exactly where the game camera will be.
func _place_camera() -> void:
	var well := Village.WELL_X
	var follow_x := lerpf(well, LAND_X, smoothstep(jump_at, jump_at + 1.4, _time))
	var push := smoothstep(0.0, jump_at + jump_time, _time)
	var close := Vector3(follow_x - 0.4, lerpf(1.75, 1.6, push), lerpf(8.6, 7.6, push))
	var look := Vector3(follow_x, lerpf(1.45, 1.2, push), Village.WELL_Z * 0.5)
	var near := Transform3D(Basis.IDENTITY, close).looking_at(look, Vector3.UP)
	if _time < glide_at:
		_camera.global_transform = near
		return
	if not _gliding:
		_gliding = true
		_glide_from = near
		# Where the game camera will be, with him standing where he landed.
		game_camera.snap_to_target()
		_glide_to = game_camera.global_transform
	var u := smoothstep(0.0, 1.0, clampf((_time - glide_at) / glide_time, 0.0, 1.0))
	# An arc: up and back over the street, then settling into place.
	var a := _glide_from.origin
	var c := _glide_to.origin
	var b := Vector3((a.x + c.x) * 0.5, maxf(a.y, c.y) + 2.2, lerpf(a.z, c.z, 0.55))
	var at := a.lerp(b, u).lerp(b.lerp(c, u), u)
	var turn := Quaternion(_glide_from.basis.orthonormalized()).slerp(Quaternion(_glide_to.basis.orthonormalized()), u)
	_camera.global_transform = Transform3D(Basis(turn), at)


func _finish() -> void:
	_time = _end()
	ronin.global_position = Vector3(LAND_X, 0.0, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	ronin.set_physics_process(true)
	fade.modulate.a = 0.0
	game_camera.snap_to_target()
	game_camera.current = true
	if hud:
		hud.visible = true
	finished.emit()
	queue_free()


## Photographs the cutscene at a row of moments and tiles them into one
## picture (--well-sheet=path).
func _frame_sheet(path: String) -> void:
	var moments := [0.8, 2.0, 2.45, 2.6, 2.75, 2.9, 3.05, 3.2, 3.6, 4.4, 5.2, 6.0, 6.6, 7.1]
	var tiles: Array[Image] = []
	for moment: float in moments:
		_time = moment
		fade.modulate.a = 1.0 - smoothstep(0.2, fade_in, _time)
		_pose()
		for k in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.resize(480, 270)
		tiles.append(image)
	var columns := 4
	var sheet := Image.create(480 * columns, 270 * ceili(tiles.size() / float(columns)), false, tiles[0].get_format())
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, 480, 270), Vector2i((i % columns) * 480, (i / columns) * 270))
	sheet.save_png(path)
	print("well sheet: ", moments)
	get_tree().quit()
