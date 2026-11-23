class_name TitleMenu
extends Control
## Everything drawn over the title video:
##  - soft shading at the top and bottom left, so lettering reads on it;
##  - the logo: ORIKAMI large in brush lettering, a vermilion seal with 折神
##    beside it, "the folded god" beneath;
##  - first "Press any key" (gently breathing), which also lets a browser
##    start the sound; then the menu: Begin, Settings, Controls, Quit;
##  - key prompts in the bottom right (key caps, or gamepad buttons if a
##    gamepad was used).
## Opening: up from sumi black, the logo inked in, then the prompt.
##
## In the browser the game is not played: Begin opens a page asking which
## download to take (Windows or Mac, the visitor's own computer first).
## `--download` shows that page natively too, for screenshots.

signal chosen(id: StringName)

@export_group("Logo")
## Where the middle of the logo is (fractions of the screen).
@export var logo_at := Vector2(0.5, 0.155)
## Height of the ORIKAMI lettering (fraction of the screen height).
@export var logo_size := 0.095

@export_group("Opening")
## Seconds the screen takes to come up out of black.
@export var open_time := 2.0
## Seconds for the logo to ink in.
@export var logo_time := 1.4

const DOWNLOADS := {
	&"get_windows": "https://github.com/noodlerocket/orikami/releases/latest/download/Orikami-Windows.zip",
	&"get_mac": "https://github.com/noodlerocket/orikami/releases/latest/download/Orikami-Mac.zip",
}

var menu: InkMenu
## Begin asks for a download instead of starting (in the browser).
var download_instead := OS.has_feature("web") or "--download" in OS.get_cmdline_user_args()
## Which download was taken (shown as "started"), or empty.
var downloaded: StringName = &""
var _cover := 1.0      # sumi over everything, 1 = black
var _logo := 0.0       # 0..1
var _seal := 0.0       # 0..1, the seal stamped
var _prompt := 0.0     # 0..1, "Press any key"
var _waiting := false  # showing "Press any key"
var _clock := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	menu = InkMenu.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.origin = Vector2(0.075, 0.71)
	menu.text_size = 0.034
	add_child(menu)
	# Save slots (Julian): Begin asks which slot to start in (once there is a
	# saved game), and starting over in a used one asks first; Continue asks
	# which saved game when there is more than one.
	var filled := [] if download_instead else SaveGame.filled_slots()
	var extra_pages := []   # [name, title, lines], added after the main page
	var begin: Dictionary = {"label": "Begin", "page": &"download"} if download_instead else {"id": &"begin", "label": "Begin"}
	if not filled.is_empty():
		begin = {"label": "Begin", "page": &"slots_new"}
		var lines := []
		for n in range(1, SaveGame.SLOTS + 1):
			if n in filled:
				lines.append({"label": SaveGame.summary(n), "page": StringName("overwrite_%d" % n)})
				extra_pages.append([StringName("overwrite_%d" % n), "Start over in slot %d? Its saved game will be lost." % n,
						[{"id": StringName("new_%d" % n), "label": "Start over"}, {"label": "Back", "back": true}]])
			else:
				lines.append({"id": StringName("new_%d" % n), "label": SaveGame.summary(n)})
		lines.append({"label": "Back", "back": true})
		extra_pages.append([&"slots_new", "Begin in which slot?", lines])
	var main_lines: Array = [
		begin,
		{"label": "Settings", "page": &"settings"},
		{"label": "Controls", "page": &"controls"},
	]
	# A saved game: Continue, first.
	if filled.size() == 1:
		main_lines.insert(0, {"id": StringName("load_%d" % filled[0]), "label": "Continue"})
	elif filled.size() > 1:
		main_lines.insert(0, {"label": "Continue", "page": &"slots_load"})
		var lines := []
		for n: int in filled:
			lines.append({"id": StringName("load_%d" % n), "label": SaveGame.summary(n)})
		lines.append({"label": "Back", "back": true})
		extra_pages.append([&"slots_load", "Continue which game?", lines])
	if not OS.has_feature("web"):
		main_lines.append({"id": &"quit", "label": "Quit"})
	menu.add_page(&"main", "", main_lines)
	for page: Array in extra_pages:
		menu.add_page(page[0], page[1], page[2])
	menu.add_page(&"settings", "Settings", TitleMenu.settings_lines())
	menu.add_page(&"controls", "", [{"label": "Back", "back": true}])
	var windows := {"id": &"get_windows", "label": "Windows"}
	var mac := {"id": &"get_mac", "label": "Mac"}
	menu.add_page(&"download", "Download", ([mac, windows] if _on_mac() else [windows, mac]) + [{"label": "Back", "back": true}])
	menu.chosen.connect(func(id: StringName) -> void: chosen.emit(id))
	var t := create_tween()
	t.tween_property(self, "_cover", 0.0, open_time).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(self, "_logo", 1.0, logo_time).set_delay(open_time * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "_seal", 1.0, 0.14)
	t.tween_callback(func() -> void:
		Sound.play(self, &"land", 2.0)
		if menu.shown <= 0.0:
			_waiting = true)
	t.tween_property(self, "_prompt", 1.0, 0.6)


## Is the visitor (or this computer) a Mac?
static func _on_mac() -> bool:
	if OS.has_feature("web"):
		var agent: Variant = JavaScriptBridge.eval("navigator.userAgent", true)
		return agent is String and (agent as String).contains("Mac")
	return OS.get_name() == "macOS"


## Starts the download (the page stays where it is).
func start_download(id: StringName) -> void:
	downloaded = id
	var url: String = DOWNLOADS[id]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = '%s';" % url)
	elif not "--download" in OS.get_cmdline_user_args():
		OS.shell_open(url)


## The Settings page, shared with the pause screen.
static func settings_lines() -> Array:
	var lines: Array = [
		{"label": "Music", "slider": func(step: int) -> float: return Sound.change_level(&"music", step)},
		{"label": "Sounds", "slider": func(step: int) -> float: return Sound.change_level(&"sounds", step)},
	]
	if not OS.has_feature("web"):
		lines.append({"label": "Full screen", "toggle": func(flip: bool) -> bool:
			if flip:
				UiStyle.set_setting("fullscreen", not UiStyle.fullscreen)
			return UiStyle.fullscreen})
	lines.append({"label": "Back", "back": true})
	return lines


## Fades the menu out, covers the screen in sumi, then calls `then`.
func fade_to_black(then: Callable) -> void:
	var t := create_tween()
	t.tween_property(menu, "shown", 0.0, 0.3)
	t.parallel().tween_property(self, "_cover", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_callback(then)


## Skips "Press any key" (used by the developer options).
func show_menu_now() -> void:
	_waiting = false
	_prompt = 0.0
	menu.shown = 1.0


func _input(event: InputEvent) -> void:
	UiStyle.note_device(event)
	if not _waiting:
		return
	var pressed := (event is InputEventKey and event.is_pressed() and not event.is_echo()) \
			or (event is InputEventJoypadButton and event.is_pressed()) \
			or (event is InputEventMouseButton and event.is_pressed())
	if pressed:
		_waiting = false
		Sound.play(self, &"draw_ready")
		var t := create_tween()
		t.tween_property(self, "_prompt", 0.0, 0.25)
		t.tween_property(menu, "shown", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var view := size
	_draw_shade(view)
	_draw_logo(view)
	if _prompt > 0.0 and menu.shown < 0.05:
		var font_size := int(view.y * 0.03)
		var words := "Press any button" if UiStyle.using_pad else "Press any key"
		var breathe := 0.55 + 0.45 * (0.5 + 0.5 * sin(_clock * 2.2))
		var spacing := font_size * 0.3
		UiStyle.text(self, Vector2((view.x - UiStyle.width(words, font_size, spacing)) * 0.5, view.y * 0.88), words, font_size,
				Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, _prompt * breathe), spacing, 0.9)
	if menu.shown > 0.0 and menu.current_page() == &"download":
		_draw_download_words(view)
	if menu.shown > 0.0 and menu.current_page() != &"controls":
		var choose := [["W  S", "Stick", "Choose"], ["Enter", "A", "Select"], ["Esc", "B", "Back"]]
		if menu.current_page() == &"settings":
			choose.insert(1, ["A  D", "Stick", "Adjust"])
		UiStyle.prompts(self, Vector2(view.x * 0.965, view.y * 0.95), choose, int(view.y * 0.021), menu.shown * 0.85)
	if _cover > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.02, 0.04, _cover))


## Under the download choices (in the dark corner, clear of the Ronin in
## the video): why; after one is picked, what next.
func _draw_download_words(view: Vector2) -> void:
	var alpha := menu.shown
	var size_big := int(view.y * 0.03)
	var size_small := int(view.y * 0.02)
	var left := view.x * menu.origin.x
	var top := view.y * 0.905
	var lines: Array
	if downloaded.is_empty():
		lines = ["Orikami is played on your computer.", "Choose the download for it."]
	else:
		lines = ["Your download has started.",
				"Unzip it and open Orikami." if downloaded == &"get_windows" else "Unzip it, then right-click Orikami and choose Open."]
	UiStyle.text(self, Vector2(left, top - size_big * 0.6), lines[0], size_big, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, alpha))
	UiStyle.text(self, Vector2(left, top + size_big * 0.6), lines[1], size_small, Color(UiStyle.WASHI_DIM.r, UiStyle.WASHI_DIM.g,
			UiStyle.WASHI_DIM.b, 0.9 * alpha))
	if downloaded == &"get_windows":
		UiStyle.text(self, Vector2(left, top + size_big * 1.5), "If Windows says it protected your PC: More info, then Run anyway.", size_small,
				Color(UiStyle.WASHI_DIM.r, UiStyle.WASHI_DIM.g, UiStyle.WASHI_DIM.b, 0.8 * alpha))


## Dark, soft shading: a band down from the top (behind the logo), a pool
## in the bottom left (behind the menu) and along the bottom (behind the
## prompts). Smooth gradients, so there are no edges.
func _draw_shade(view: Vector2) -> void:
	draw_texture_rect(UiStyle.shade("down"), Rect2(Vector2.ZERO, Vector2(view.x, view.y * 0.36)), false, Color(1, 1, 1, 0.55))
	draw_texture_rect(UiStyle.shade("up"), Rect2(Vector2(0, view.y * 0.66), Vector2(view.x, view.y * 0.34)), false, Color(1, 1, 1, 0.6))
	# The pool behind the menu: darkest in the bottom-left corner.
	draw_texture_rect(UiStyle.shade("corner"), Rect2(Vector2(0, view.y * 0.3), Vector2(view.x * 0.55, view.y * 0.7)), false,
			Color(1, 1, 1, 0.7 * menu.shown))


func _draw_logo(view: Vector2) -> void:
	if _logo <= 0.0:
		return
	var font_size := int(view.y * logo_size)
	var spacing := font_size * 0.16
	var word := "ORIKAMI"
	var word_width := UiStyle.width(word, font_size, spacing)
	var seal_side := font_size * 1.05
	var gap := font_size * 0.32
	var total := seal_side + gap + word_width
	var left := view.x * logo_at.x - total * 0.5
	var baseline := view.y * logo_at.y + font_size * 0.36
	# The word inks in from the left: each letter fades up in turn.
	var x := left + seal_side + gap
	var letters := word.length()
	for i in letters:
		var letter := word[i]
		var own := clampf(_logo * (letters + 2.0) / 3.0 - i / 3.0, 0.0, 1.0)
		UiStyle.text(self, Vector2(x, baseline + (1.0 - own) * font_size * 0.06), letter, font_size,
				Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, own), 0.0, 1.0)
		x += UiStyle.width(letter, font_size) + spacing
	# A thin brushed rule under the word, and the tagline.
	var rule_y := baseline + font_size * 0.28
	var rule_from := left + seal_side + gap
	draw_rect(Rect2(Vector2(rule_from, rule_y), Vector2(word_width * ease(_logo, 0.5), maxf(2.0, font_size * 0.025))),
			Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.55 * _logo))
	var tag := "THE  FOLDED  GOD"
	var tag_size := int(font_size * 0.24)
	var tag_spacing := tag_size * 0.55
	UiStyle.text(self, Vector2(rule_from + (word_width - UiStyle.width(tag, tag_size, tag_spacing)) * 0.5, rule_y + tag_size * 1.7), tag,
			tag_size, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.8 * _logo), tag_spacing, 1.0)
	# The seal: a vermilion square, 折 over 神 cut out of it in washi, stamped
	# on (it lands a little large and settles).
	if _seal > 0.0:
		var side := seal_side * lerpf(1.25, 1.0, _seal)
		var middle := Vector2(left + seal_side * 0.5, baseline - font_size * 0.36)
		var box := Rect2(middle - Vector2.ONE * side * 0.5, Vector2.ONE * side)
		draw_rect(Rect2(box.position + Vector2(3, 4), box.size), Color(0, 0, 0, 0.35 * _seal))
		draw_rect(box, Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, _seal))
		draw_rect(box.grow(-side * 0.06), Color(0.96, 0.9, 0.84, 0.9 * _seal), false, maxf(1.5, side * 0.025))
		var kanji := int(side * 0.4)
		for k in 2:
			var glyph := "折" if k == 0 else "神"
			var gw := UiStyle.width(glyph, kanji)
			draw_string(UiStyle.FONT, Vector2(middle.x - gw * 0.5, box.position.y + side * (0.44 + 0.42 * k)), glyph,
					HORIZONTAL_ALIGNMENT_LEFT, -1, kanji, Color(0.97, 0.92, 0.86, _seal))
