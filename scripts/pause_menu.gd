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
		{"label": "Map", "page": &"map"},
		{"label": "Settings", "page": &"settings"},
		{"label": "Controls", "page": &"controls"},
		{"label": "Return to the title", "page": &"leave"},
	])
	menu.add_page(&"settings", "Settings", TitleMenu.settings_lines())
	menu.add_page(&"controls", "", [{"label": "Back", "back": true}])
	menu.add_page(&"map", "Map", [{"label": "Back", "back": true}])
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
	if alpha > 0.0 and menu.current_page() == &"map":
		_draw_map(view, alpha)
	if _wash > 1.0:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.02, 0.04, _wash - 1.0))



# --- The map --------------------------------------------------------------------------

## The map of the village: a sheet of paper with the village brushed on in
## ink, only where he has been (SaveGame.explored): the street, the canals
## under it, the Rooftop Road over it, the river; the shrines as small seals
## (vermilion once rested at, an empty square before), and where he is now.
func _draw_map(view: Vector2, alpha: float) -> void:
	var panel := Rect2(Vector2(view.x * 0.3, view.y * 0.14), Vector2(view.x * 0.64, view.y * 0.7))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# The paper, torn at its edges, with a soft shadow.
	var outline := PackedVector2Array()
	var corners := [panel.position, Vector2(panel.end.x, panel.position.y), panel.end, Vector2(panel.position.x, panel.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var pieces := maxi(2, int(a.distance_to(b) / 18.0))
		var out := (b - a).orthogonal().normalized()
		for k in pieces:
			outline.append(a.lerp(b, float(k) / pieces) + out * rng.randf_range(-3.0, 3.0))
	var shadow := PackedVector2Array()
	for point: Vector2 in outline:
		shadow.append(point + Vector2(8.0, 10.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.03, 0.4 * alpha))
	draw_colored_polygon(outline, Color(0.9, 0.86, 0.78, 0.97 * alpha))
	for i in 30:
		var from := panel.position + Vector2(rng.randf() * panel.size.x, rng.randf() * panel.size.y)
		draw_line(from, from + Vector2(rng.randf_range(10.0, 40.0), rng.randf_range(-4.0, 4.0)), Color(0.6, 0.55, 0.47, 0.18 * alpha), 1.0, true)
	var ink := Color(0.08, 0.08, 0.12, 0.9 * alpha)
	var faint := Color(0.08, 0.08, 0.12, 0.35 * alpha)
	var title_size := int(view.y * 0.034)
	UiStyle.text(self, panel.position + Vector2(view.y * 0.03, view.y * 0.06), "Kamiyama", title_size, ink, 2.0, 0.0)
	# World to map: x along the village, three bands of height.
	var left := -17.0
	var right := Village.ARENA.y + 1.0
	var to_map := func(x: float, y: float) -> Vector2:
		var u := (x - left) / (right - left)
		return Vector2(panel.position.x + panel.size.x * (0.04 + 0.92 * u), panel.position.y + panel.size.y * (0.62 - y * 0.035))
	var seen := func(layer: String, x: float) -> bool:
		return SaveGame.explored.has("%s:%d" % [layer, floori(x / 4.0)])
	var line := maxf(2.0, view.y * 0.004)
	# The street (and the steps up to the courtyard).
	var x := left
	while x < right:
		var x1 := x + 2.0
		if seen.call("street", x) and not Village.is_hole(x + 1.0):
			var y0 := 1.5 if x >= Village.STEPS.y else (0.0 if x <= Village.STEPS.x else 1.5 * (x - Village.STEPS.x) / (Village.STEPS.y - Village.STEPS.x))
			var y1 := 1.5 if x1 >= Village.STEPS.y else (0.0 if x1 <= Village.STEPS.x else 1.5 * (x1 - Village.STEPS.x) / (Village.STEPS.y - Village.STEPS.x))
			draw_line(to_map.call(x, y0), to_map.call(x1, y1), ink, line * 1.4, true)
			# Houses behind, as small roofs.
			if fmod(x - left, 6.0) < 2.0 and x < Village.STEPS.x:
				var at: Vector2 = to_map.call(x + 1.0, 0.0)
				draw_polyline(PackedVector2Array([at + Vector2(-7, -6), at + Vector2(0, -13), at + Vector2(7, -6)]), faint, 1.5, true)
		x = x1
	# The river, where it has been seen.
	if seen.call("street", 100.0) or seen.call("under", 100.0):
		for k in 3:
			var a: Vector2 = to_map.call(Village.RIVER.x + 1.0, -0.6 - k * 0.5)
			var b: Vector2 = to_map.call(Village.RIVER.y - 1.0, -0.6 - k * 0.5)
			draw_line(a, b, Color(0.2, 0.3, 0.5, 0.55 * alpha), 1.5, true)
	# The canals and the drain pipe: a tunnel of two lines.
	x = Village.CHAMBER.x
	while x < Village.CANAL.y:
		if seen.call("under", x):
			var depth := -4.0 if x < Village.CANAL.x else -5.5
			draw_line(to_map.call(x, depth + 1.2), to_map.call(minf(x + 4.0, Village.CANAL.y), depth + 1.2), ink, line, true)
			draw_line(to_map.call(x, depth - 0.8), to_map.call(minf(x + 4.0, Village.CANAL.y), depth - 0.8), ink, line, true)
		x += 4.0
	# The Rooftop Road: a dotted line.
	x = 30.0
	while x < 120.0:
		if seen.call("roofs", x):
			var a: Vector2 = to_map.call(x, 7.5)
			draw_line(a, a + Vector2(view.x * 0.006, 0.0), ink, line, true)
		x += 1.5
	# The shrines.
	var seal := view.y * 0.022
	for shrine: Array in [["paper_maker", 8.9], ["warehouse", 123.0], ["steps", Village.STEPS.x - 1.6]]:
		if not (seen.call("street", shrine[1]) or shrine[0] in SaveGame.rested):
			continue
		var at: Vector2 = to_map.call(shrine[1], 0.0) + Vector2(0.0, -seal * 1.4)
		var box := Rect2(at - Vector2(seal, seal) * 0.5, Vector2(seal, seal))
		if shrine[0] in SaveGame.rested:
			draw_rect(box, Color(UiStyle.VERMILION, alpha))
		else:
			draw_rect(box, Color(UiStyle.VERMILION, 0.7 * alpha), false, 1.5)
	# Where he is: a small wide hat.
	var ronin := get_tree().get_first_node_in_group(&"player") as Node3D
	if ronin:
		var at: Vector2 = to_map.call(ronin.global_position.x, ronin.global_position.y)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-9, 0), at + Vector2(0, -6), at + Vector2(9, 0)]), ink)
		draw_circle(at + Vector2(0, 4), 3.0, ink)
	# The cranes found.
	var count := "Cranes  %d / 1000" % SaveGame.crane_total()
	UiStyle.text(self, Vector2(panel.end.x - UiStyle.width(count, int(title_size * 0.6)) - view.y * 0.03, panel.end.y - view.y * 0.03),
			count, int(title_size * 0.6), Color(0.08, 0.08, 0.12, 0.7 * alpha), 0.0, 0.0)
