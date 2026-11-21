class_name UiStyle
extends RefCounted
## The look shared by every menu: the brush font, the colours, and small
## drawing helpers (text with a soft shadow, the highlight behind a chosen
## line, key caps and gamepad buttons for prompts).
##
## The font is Yuji Syuku (SIL Open Font License, fonts/OFL.txt), cut down to
## the letters and kanji the game uses (fonts/yuji_syuku_ui.ttf) so it is
## small enough to ship. A new kanji in the UI must be added to that cut:
## see CLAUDE.md, "Title and pause".
##
## It also remembers whether the player last used a keyboard or a gamepad,
## so prompts can show the right buttons.

const FONT := preload("res://fonts/yuji_syuku_ui.ttf")

const WASHI := Color(0.95, 0.92, 0.86)
const WASHI_DIM := Color(0.86, 0.83, 0.78, 0.62)
const SUMI := Color(0.03, 0.03, 0.05)
const VERMILION := Color(0.78, 0.19, 0.13)
const GOLD := Color(0.92, 0.74, 0.42)

## True after the player touched a gamepad, false after a key or the mouse.
static var using_pad := false
## The on-screen control hints in the game (Settings > Control hints).
static var show_hints := true
static var fullscreen := false
static var _loaded := false

const SETTINGS_FILE := "user://settings.cfg"


## Call from any menu's _input to keep `using_pad` up to date.
static func note_device(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		using_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_pad = false


# --- Settings that are not sound -----------------------------------------------

static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var file := ConfigFile.new()
	if file.load(SETTINGS_FILE) == OK:
		show_hints = bool(file.get_value("display", "hints", true))
		fullscreen = bool(file.get_value("display", "fullscreen", false))
	_apply_fullscreen()


static func set_setting(key: String, value: bool) -> void:
	match key:
		"hints":
			show_hints = value
		"fullscreen":
			fullscreen = value
			_apply_fullscreen()
	var file := ConfigFile.new()
	file.load(SETTINGS_FILE)
	file.set_value("display", key, value)
	file.save(SETTINGS_FILE)


static func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want and (fullscreen or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
		DisplayServer.window_set_mode(want)


# --- Drawing -------------------------------------------------------------------

static var _shades := {}

## A smooth dark shading texture (sumi, see-through at its far end):
## "down" is darkest at the top, "up" at the bottom, "right" at the left,
## "corner" is a round pool darkest in the bottom-left corner.
## Stretch it over a rectangle with draw_texture_rect.
static func shade(kind: String) -> GradientTexture2D:
	if _shades.has(kind):
		return _shades[kind]
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.01, 0.01, 0.03, 1.0))
	ramp.set_color(1, Color(0.01, 0.01, 0.03, 0.0))
	ramp.add_point(0.35, Color(0.01, 0.01, 0.03, 0.62))
	ramp.add_point(0.7, Color(0.01, 0.01, 0.03, 0.18))
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.width = 256
	texture.height = 256
	match kind:
		"down":
			texture.fill_from = Vector2(0.5, 0.0)
			texture.fill_to = Vector2(0.5, 1.0)
		"up":
			texture.fill_from = Vector2(0.5, 1.0)
			texture.fill_to = Vector2(0.5, 0.0)
		"right":
			texture.fill_from = Vector2(0.0, 0.5)
			texture.fill_to = Vector2(1.0, 0.5)
		"corner":
			texture.fill = GradientTexture2D.FILL_RADIAL
			texture.fill_from = Vector2(0.0, 1.0)
			texture.fill_to = Vector2(1.0, 1.0)
	_shades[kind] = texture
	return texture

## Text with a soft dark shadow under it, so it reads on any picture.
## `at` is the left end of the baseline.
static func text(canvas: CanvasItem, at: Vector2, words: String, font_size: int, colour: Color,
		spacing: float = 0.0, shadow: float = 0.6) -> void:
	if shadow > 0.0:
		var dark := Color(0.0, 0.0, 0.02, colour.a * shadow * 0.5)
		for nudge: Vector2 in [Vector2(0, 2), Vector2(2, 2), Vector2(-1, 2), Vector2(0, 4)]:
			_spaced(canvas, at + nudge * (font_size / 40.0), words, font_size, dark, spacing)
	_spaced(canvas, at, words, font_size, colour, spacing)


static func _spaced(canvas: CanvasItem, at: Vector2, words: String, font_size: int, colour: Color, spacing: float) -> void:
	if spacing <= 0.0:
		canvas.draw_string(FONT, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
		return
	var x := at.x
	for letter in words:
		canvas.draw_string(FONT, Vector2(x, at.y), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
		x += FONT.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + spacing


## How wide a line of text is.
static func width(words: String, font_size: int, spacing: float = 0.0) -> float:
	if spacing <= 0.0:
		return FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var total := 0.0
	for letter in words:
		total += FONT.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + spacing
	return total - spacing


## The wash behind a chosen line: dark ink, feathered out to the right;
## `amount` (0..1) wipes it on from the left.
static func highlight(canvas: CanvasItem, box: Rect2, amount: float, alpha: float = 1.0) -> void:
	if amount <= 0.0:
		return
	var reach := ease(amount, 0.4)
	var texture := shade("right")
	canvas.draw_texture_rect_region(texture, Rect2(box.position, Vector2(box.size.x * reach, box.size.y)),
			Rect2(Vector2.ZERO, Vector2(texture.get_width() * reach, texture.get_height())), Color(1, 1, 1, 0.78 * alpha))


## A small vermilion diamond, the marker beside the chosen line.
static func marker(canvas: CanvasItem, middle: Vector2, size: float, alpha: float) -> void:
	var points := PackedVector2Array([middle + Vector2(0, -size), middle + Vector2(size * 0.7, 0),
			middle + Vector2(0, size), middle + Vector2(-size * 0.7, 0)])
	canvas.draw_colored_polygon(points, Color(VERMILION.r, VERMILION.g, VERMILION.b, alpha))


## A key cap (keyboard) or button (gamepad) with a label, for prompts.
## Returns how wide it was. `round_button` draws a circle (A, B, X, Y).
static func keycap(canvas: CanvasItem, at: Vector2, label: String, font_size: int, alpha: float,
		round_button: bool = false) -> float:
	var label_width := width(label, font_size)
	var tall := font_size * 1.45
	var wide := maxf(tall, label_width + font_size * 0.9)
	if round_button:
		wide = tall
	var box := Rect2(at - Vector2(0, tall * 0.78), Vector2(wide, tall))
	var face := Color(0.92, 0.89, 0.83, 0.9 * alpha)
	if round_button:
		canvas.draw_circle(box.get_center() + Vector2(0, 2), tall * 0.5, Color(0, 0, 0, 0.35 * alpha))
		canvas.draw_circle(box.get_center(), tall * 0.5, face)
	else:
		canvas.draw_rect(Rect2(box.position + Vector2(0, 2), box.size), Color(0, 0, 0, 0.35 * alpha))
		canvas.draw_rect(box, face)
		canvas.draw_rect(Rect2(box.position + Vector2(0, box.size.y - 3), Vector2(box.size.x, 3)), Color(0.6, 0.57, 0.52, 0.9 * alpha))
	canvas.draw_string(FONT, Vector2(box.get_center().x - label_width * 0.5, at.y), label, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color(0.08, 0.07, 0.08, alpha))
	return wide


## A row of prompts, right-aligned to `right`: [[key, pad button, words], ...].
## Draws key caps or gamepad buttons depending on what was used last.
static func prompts(canvas: CanvasItem, right: Vector2, items: Array, font_size: int, alpha: float) -> void:
	var gap := font_size * 1.2
	var total := 0.0
	var widths: Array[float] = []
	for item: Array in items:
		var cap: String = item[1] if using_pad else item[0]
		var cap_wide := maxf(font_size * 1.45, width(cap, font_size) + font_size * 0.9)
		if using_pad and cap.length() == 1:
			cap_wide = font_size * 1.45
		var w := cap_wide + font_size * 0.45 + width(item[2], font_size)
		widths.append(w)
		total += w + gap
	var x := right.x - total + gap
	for i in items.size():
		var item: Array = items[i]
		var cap: String = item[1] if using_pad else item[0]
		var used := keycap(canvas, Vector2(x, right.y), cap, font_size, alpha, using_pad and cap.length() == 1)
		text(canvas, Vector2(x + used + font_size * 0.45, right.y), item[2], font_size, Color(WASHI.r, WASHI.g, WASHI.b, 0.8 * alpha), 0.0, 0.8)
		x += widths[i] + gap
