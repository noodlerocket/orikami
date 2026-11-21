extends SceneTree
## Turns a folder of frames into video/title_loop.ogv, using Godot's own
## Movie Maker (the ffmpeg on this computer writes broken Theora files, so
## it is only used to cut the frames). It shows one frame per frame of the
## recording. The recording is as big as the window can be on this screen
## (1280x720 here).
##
## 1. Cut the frames, blending the last 1.2 s into the start so it loops
##    (T = the video's length in seconds, E = T - 1.2):
##    ffmpeg -i in.mp4 -filter_complex "[0:v]fps=30,scale=1920:1080,split=3[v1][v2][v3];[v1]trim=0:1.2,setpts=PTS-STARTPTS[a];[v2]trim=E:T,setpts=PTS-STARTPTS[b];[v3]trim=1.2:E,setpts=PTS-STARTPTS[m];[b][a]xfade=transition=fade:duration=1.2:offset=0[x];[x][m]concat=n=2:v=1:a=0[out]" -map "[out]" -q:v 2 frames/f_%04d.jpg
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
