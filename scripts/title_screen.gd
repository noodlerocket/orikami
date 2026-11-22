class_name TitleScreen
extends Control
## The title screen: Julian's looping video (video/title_loop.ogv) filling
## the screen, with the village music and rain, and TitleMenu over it (the
## logo, "Press any key", the menu).
##
## The video was made by Julian from his title picture; it is 1280x720, 30
## frames a second, 5.9 s, and loops with a plain cut (his clip as it is:
## a blended seam was tried and he did not like it). tools/make_title_video.gd
## says how the file was made.
## If the video is missing, a still from it (textures/title_backdrop.jpg) is
## shown instead.
##
## "Begin" plays the prologue (scenes/prologue.tscn), which leads into the
## game (scenes/main.tscn).
##
## Developer options, after a "--" on the command line. Any of the game's
## own options (--x=, --zoom=, --cutscene, --screenshot= ...) skip the title
## and go straight into the game, so the usual screenshot commands still work.
## To photograph the title itself, add --title:
##   --title --screenshot=shot.png   save a picture after a moment, then quit
##   --title-at=3.0                  ...taken this many seconds in (default 6)
##   --menu                          skip "Press any key"
##   --page=settings                 open a page of the menu (settings, controls)
##   --prologue                      play the prologue straight away
##   --prologue-sheet=sheet.png      photograph the prologue at 16 moments

const GAME_SCENE := "res://scenes/main.tscn"
const PROLOGUE_SCENE := "res://scenes/prologue.tscn"
const PICTURE := preload("res://textures/title_backdrop.jpg")
const VIDEO := "res://video/title_loop.ogv"

var _backdrop: Control
var _menu: TitleMenu


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for arg: String in args:
		if arg == "--prologue" or arg.begins_with("--prologue-sheet="):
			get_tree().change_scene_to_file.call_deferred(PROLOGUE_SCENE)
			return
	if not args.is_empty() and not "--title" in args:
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
		return
	Wind.breeze = 2.2
	Wind.gusts = 4.0
	var sound := Sound.new()
	sound.name = "Sound"
	add_child(sound)
	_build_backdrop()
	var grain := ColorRect.new()
	var look := ShaderMaterial.new()
	look.shader = load("res://shaders/paper_grain.gdshader")
	look.set_shader_parameter(&"vignette_strength", 0.35)
	look.set_shader_parameter(&"grain_strength", 0.12)
	look.set_shader_parameter(&"fiber_strength", 0.08)
	grain.material = look
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grain)
	_menu = TitleMenu.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_menu)
	_menu.chosen.connect(_on_chosen)
	for arg: String in args:
		if arg == "--menu":
			_menu.show_menu_now.call_deferred()
		elif arg.begins_with("--page="):
			var page := StringName(arg.trim_prefix("--page="))
			(func() -> void:
				_menu.show_menu_now()
				_menu.menu.open_page(page)).call_deferred()
	_debug_screenshot()


func _process(_delta: float) -> void:
	# Cover the screen (cropping the edges if the window is not 16:9).
	if _backdrop:
		var source := Vector2(16.0, 9.0)
		var cover := maxf(size.x / source.x, size.y / source.y)
		_backdrop.size = source * cover
		_backdrop.position = (size - _backdrop.size) * 0.5


func _build_backdrop() -> void:
	if ResourceLoader.exists(VIDEO):
		var video := VideoStreamPlayer.new()
		video.stream = load(VIDEO)
		video.loop = true
		video.expand = true
		video.autoplay = true
		video.volume_db = -80.0   # (its sound track is silent; the game's rain and music play)
		video.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_backdrop = video
	else:
		var still := TextureRect.new()
		still.texture = PICTURE
		still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		still.stretch_mode = TextureRect.STRETCH_SCALE
		still.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_backdrop = still
	add_child(_backdrop)


func _on_chosen(item: StringName) -> void:
	match item:
		&"begin":
			Sound.duck_music(true)
			_menu.fade_to_black(func() -> void: get_tree().change_scene_to_file(PROLOGUE_SCENE))
		&"quit":
			_menu.fade_to_black(func() -> void: get_tree().quit())


func _debug_screenshot() -> void:
	var wait := 6.0
	var path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			path = arg.trim_prefix("--screenshot=")
		elif arg.begins_with("--title-at="):
			wait = float(arg.trim_prefix("--title-at="))
	if path.is_empty():
		return
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
