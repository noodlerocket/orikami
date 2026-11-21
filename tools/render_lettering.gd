extends SceneTree
## Renders lettering in the brush-calligraphy font (art_source/fonts) into
## images in textures/, so the game can show it without shipping the 8 MB
## font. Re-run after changing the lines below (needs a window, not --headless):
##   Godot_v4.7.2-stable_win64_console.exe --path . --script tools/render_lettering.gd

const FONT := "res://art_source/fonts/YujiSyuku-Regular.ttf"
## [file name, text, size in pixels]
const LINES := [
	["title_hannya_kanji", "般若", 220],
	["title_hannya_name", "The Weeping Hannya", 84],
	["title_hannya_subtitle", "she who wept until her face became a mask", 40],
]


func _initialize() -> void:
	var font := FontFile.new()
	var error := font.load_dynamic_font(ProjectSettings.globalize_path(FONT))
	if error != OK:
		push_error("Could not load the font: %d" % error)
		quit(1)
		return
	for line: Array in LINES:
		await _render(font, line[0], line[1], line[2])
	quit()


func _render(font: FontFile, file: String, text: String, font_size: int) -> void:
	var measure := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pad := font_size / 4
	var view := SubViewport.new()
	var lines := text.count("\n") + 1
	view.size = Vector2i(int(measure.x) + pad * 2, int(maxf(measure.y * 1.15, font_size * 1.45 * lines)) + pad * 2)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.position = Vector2(pad, pad)
	view.add_child(label)
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	image.save_png("res://textures/%s.png" % file)
	print("rendered ", file, " ", image.get_size())
	view.queue_free()
