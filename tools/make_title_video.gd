extends SceneTree
## Turns a folder of frames into video/title_loop.ogv, using Godot's own
## Movie Maker (the ffmpeg on this computer writes broken Theora files, so
## it is only used to cut the frames). It shows one frame per frame of the
## recording. The recording is as big as the window can be on this screen
## (1280x720 here).
##
## 1. Cut the frames (the whole clip as it is; Julian did not like a blended
##    seam, so the loop is a plain cut from the last frame to the first):
##    ffmpeg -i in.mp4 -vf "fps=30,scale=1920:1080:flags=lanczos" -q:v 2 frames/f_%04d.jpg
## 2. Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --write-movie C:ull\path	itle_loop.ogv --script tools/make_title_video.gd -- --frames=C:/full/path/frames
## 3. Copy the .ogv to video/title_loop.ogv.
var _rect: TextureRect
var _files: PackedStringArray
var _dir := ""
var _i := 0
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			_dir = arg.trim_prefix("--frames=")
	root.size = Vector2i(1920, 1080)
	_files = DirAccess.get_files_at(_dir)
	_rect = TextureRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(_rect)
	_show()
func _process(_delta: float) -> bool:
	_i += 1
	if _i >= _files.size():
		return true
	_show()
	return false
func _show() -> void:
	_rect.texture = ImageTexture.create_from_image(Image.load_from_file(_dir + "/" + _files[_i]))
