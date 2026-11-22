class_name PauseMenu
extends Control
## The pause screen (Esc or P; Start on a gamepad). In the same style as the
## title: the game stops and sinks under a sumi wash, darkest down the left,
## where a vermilion seal with 休 ("rest") heads the menu: Resume, Settings,
## Controls, Return to the title (which asks first, because nothing is saved
## yet). Esc goes back a page, and from the first page carries on playing.

const TITLE_SCENE := "res://scenes/title.tscn"

## Seconds for the wash to come on (and a little less to go).
@export var open_time := 0.25

## Asked before pausing; return false when the game must not stop (during
## the loading cover or a cutscene).
var can_pause: Callable = func() -> bool: return true

var menu: InkMenu
var _open := false
var _wash := 0.0      # 0..1, the wash over the game (past 1: to black)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu = InkMenu.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.origin = Vector2(0.085, 0.43)
	menu.text_size = 0.036
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu)
	menu.add_page(&"main", "", [
		{"id": &"resume", "label": "Resume"},
		{"label": "Settings", "page": &"settings"},
		{"label": "Controls", "page": &"controls"},
		{"label": "Return to the title", "page": &"leave"},
	])
	menu.add_page(&"settings", "Settings", TitleMenu.settings_lines())
	menu.add_page(&"controls", "", [{"label": "Back", "back": true}])
	menu.add_page(&"leave", "Return to the title?", [
		{"label": "No, keep playing", "back": true},
		{"id": &"to_title", "label": "Yes, return"},
	])
	menu.chosen.connect(_on_chosen)
	menu.backed_out.connect(close)


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	get_tree().paused = true
	menu.reset()
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	Sound.play(self, &"step", 1.0)
	var t := create_tween()
	t.tween_property(self, "_wash", 1.0, open_time).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(menu, "shown", 1.0, open_time).set_delay(open_time * 0.4)


func close() -> void:
	if not _open:
		return
	_open = false
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Sound.play(self, &"step", 1.0)
	var t := create_tween()
	t.tween_property(menu, "shown", 0.0, open_time * 0.6)
	t.parallel().tween_property(self, "_wash", 0.0, open_time * 0.8)
	t.tween_callback(func() -> void: get_tree().paused = false)


func _unhandled_input(event: InputEvent) -> void:
	if not _open and event.is_action_pressed(&"pause") and not event.is_echo() and can_pause.call():
		open()
		accept_event()


func _on_chosen(id: StringName) -> void:
	match id:
		&"resume":
			close()
		&"to_title":
			_open = false
			var t := create_tween()
			t.tween_property(menu, "shown", 0.0, 0.2)
			t.parallel().tween_property(self, "_wash", 2.0, 0.6)
			t.tween_callback(func() -> void:
				get_tree().paused = false
				get_tree().change_scene_to_file(TITLE_SCENE))


func _process(_delta: float) -> void:
	if _wash > 0.0:
		queue_redraw()


func _draw() -> void:
	if _wash <= 0.0:
		return
	var view := size
	var w := minf(_wash, 1.0)
	# The wash over everything, then a pool of ink down the left behind the menu.
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.01, 0.01, 0.03, 0.45 * w))
	draw_texture_rect(UiStyle.shade("right"), Rect2(Vector2.ZERO, Vector2(view.x * 0.65, view.y)), false, Color(1, 1, 1, 0.6 * w))
	# The heading: a vermilion seal with 休, and RESTING beside it.
	var alpha := menu.shown
	if alpha > 0.0 and menu.current_page() != &"controls":
		var font_size := int(view.y * menu.text_size)
		var side := font_size * 2.1
		var seal := Rect2(Vector2(view.x * menu.origin.x - font_size * 0.15, view.y * menu.origin.y - font_size * 5.4), Vector2(side, side))
		draw_rect(Rect2(seal.position + Vector2(3, 4), seal.size), Color(0, 0, 0, 0.35 * alpha))
		draw_rect(seal, Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, alpha))
		draw_rect(seal.grow(-side * 0.06), Color(0.96, 0.9, 0.84, 0.9 * alpha), false, maxf(1.5, side * 0.025))
		var kanji := int(side * 0.66)
		var gw := UiStyle.width("休", kanji)
		draw_string(UiStyle.FONT, Vector2(seal.get_center().x - gw * 0.5, seal.position.y + side * 0.76), "休",
				HORIZONTAL_ALIGNMENT_LEFT, -1, kanji, Color(0.97, 0.92, 0.86, alpha))
		var word_size := int(font_size * 0.9)
		UiStyle.text(self, Vector2(seal.end.x + font_size * 0.6, seal.get_center().y + word_size * 0.35), "RESTING", word_size,
				Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, alpha), word_size * 0.4)
		var choose := [["W  S", "Stick", "Choose"], ["Enter", "A", "Select"], ["Esc", "B", "Back"]]
		if menu.current_page() == &"settings":
			choose.insert(1, ["A  D", "Stick", "Adjust"])
		UiStyle.prompts(self, Vector2(view.x * 0.965, view.y * 0.95), choose, int(view.y * 0.021), alpha * 0.85)
	if _wash > 1.0:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.02, 0.04, _wash - 1.0))
