class_name InkMenu
extends Control
## The menu used by the title screen and the pause screen.
##
## It has pages (the main list, Settings, Controls). Each page is a list of
## lines: a button, a link to another page, a volume slider (ten ink ticks)
## or an on/off switch. The chosen line has a feathered ink wash wiped on
## behind it, a small vermilion marker, and slides a little to the right;
## the others are dimmer. Nothing pops: every change eases.
##
## Keys: W / S or arrows choose, A / D change a slider or switch, Space, J or
## Enter picks, Esc or Backspace goes back a page. Gamepad: stick or d-pad,
## A picks, B goes back. The mouse: hover chooses, click picks.

signal chosen(id: StringName)
## Back pressed on the first page.
signal backed_out

@export_group("Layout (fractions of the screen)")
## Where the first line's left end and baseline are.
@export var origin := Vector2(0.075, 0.62)
## Height of the lettering, as a fraction of the screen height.
@export var text_size := 0.036
## Distance between lines, in line heights.
@export var line_gap := 1.75
## How far the chosen line slides right (in line heights).
@export var slide := 0.35

@export_group("Timing")
## Seconds for the highlight to wipe on.
@export var highlight_time := 0.18

## How visible the whole menu is (0..1). Tween it to fade the menu in or out.
var shown := 0.0

var _pages := {}                 # name -> {"title": String, "lines": Array[Dictionary]}
var _stack: Array[StringName] = []
var _selected := 0
var _glow := {}                  # line index -> 0..1, how chosen it looks (eases)
var _boxes: Array[Rect2] = []    # where each line was drawn, for the mouse
var _page_fade := 1.0            # eases from 0 to 1 when a page opens


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UiStyle.load_settings()


## Adds a page. Lines are dictionaries:
##   {"id": &"begin", "label": "Begin"}                         a button
##   {"label": "Settings", "page": &"settings"}                 opens a page
##   {"label": "Music", "slider": callable(step) -> level 0..1}  a slider
##   {"label": "Full screen", "toggle": callable(flip) -> bool}  a switch
##   {"label": "Back", "back": true}                             goes back
## A page named &"controls" is drawn as the controls panel instead.
func add_page(page: StringName, title: String, lines: Array) -> void:
	_pages[page] = {"title": title, "lines": lines}
	if _stack.is_empty():
		_stack.append(page)


func current_page() -> StringName:
	return _stack[-1] if not _stack.is_empty() else &""


func open_page(page: StringName) -> void:
	_listening = false
	_bind_row = 0
	_stack.append(page)
	_selected = 0
	_glow.clear()
	_page_fade = 0.0
	Sound.play(self, &"step", 1.0)


## Back one page; on the first page, tells whoever owns the menu.
func go_back() -> void:
	if _stack.size() > 1:
		_stack.pop_back()
		_selected = 0
		_glow.clear()
		_page_fade = 0.0
		Sound.play(self, &"step", 1.0)
	else:
		backed_out.emit()


func reset() -> void:
	_stack.resize(1)
	_selected = 0
	_glow.clear()


func _lines() -> Array:
	if _stack.is_empty():
		return []
	return _pages[current_page()]["lines"]


func _process(delta: float) -> void:
	_page_fade = minf(_page_fade + delta / 0.25, 1.0)
	var lines := _lines()
	for i in lines.size():
		var target := 1.0 if i == _selected else 0.0
		_glow[i] = move_toward(float(_glow.get(i, 0.0)), target, delta / maxf(highlight_time, 0.01))
	queue_redraw()


func _input(event: InputEvent) -> void:
	UiStyle.note_device(event)
	if current_page() == &"controls" and shown >= 0.6 and is_visible_in_tree():
		if _controls_input(event):
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if shown < 0.6 or not is_visible_in_tree():
		return
	if _is(event, [&"ui_up", &"aim_up"]):
		_move(-1)
	elif _is(event, [&"ui_down", &"aim_down"]):
		_move(1)
	elif _is(event, [&"ui_left", &"move_left"]):
		_change(-1)
	elif _is(event, [&"ui_right", &"move_right"]):
		_change(1)
	elif _is(event, [&"ui_accept", &"jump", &"slash"]):
		_pick()
	elif _is(event, [&"ui_cancel", &"pause"]) or (event is InputEventKey and (event as InputEventKey).pressed
			and (event as InputEventKey).keycode == KEY_BACKSPACE):
		go_back()
	else:
		return
	accept_event()


func _gui_input(event: InputEvent) -> void:
	if shown < 0.6:
		return
	var motion := event as InputEventMouseMotion
	if motion:
		for i in _boxes.size():
			if _boxes[i].has_point(motion.position) and i != _selected:
				_selected = i
				Sound.play(self, &"step", -2.0)
	var click := event as InputEventMouseButton
	if current_page() == &"controls":
		# A row of the controls page: hover chooses it, a click listens for its key.
		var at := (event as InputEventMouse).position if event is InputEventMouse else Vector2(-1, -1)
		for i in _row_boxes.size():
			if _row_boxes[i].has_area() and _row_boxes[i].has_point(at):
				if motion and i != _bind_row and not _listening:
					_bind_row = i
				if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and not _listening:
					_bind_row = i
					_choose_row()
				return
		if click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
			if _listening:
				_listening = false
			else:
				go_back()
		return
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		for i in _boxes.size():
			if _boxes[i].has_point(click.position):
				_selected = i
				var line: Dictionary = _lines()[i]
				if line.has("slider"):
					_change(-1 if click.position.x < _boxes[i].get_center().x + _boxes[i].size.x * 0.2 else 1)
				else:
					_pick()
				return
	if click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		go_back()


func _is(event: InputEvent, actions: Array) -> bool:
	for action: StringName in actions:
		if InputMap.has_action(action) and event.is_action_pressed(action, true):
			return true
	return false


func _move(step: int) -> void:
	var lines := _lines()
	if lines.is_empty():
		return
	_selected = wrapi(_selected + step, 0, lines.size())
	Sound.play(self, &"step", -2.0)


func _change(step: int) -> void:
	var lines := _lines()
	if lines.is_empty():
		return
	var line: Dictionary = lines[_selected]
	if line.has("slider"):
		(line["slider"] as Callable).call(step)
		Sound.play(self, &"step", 0.0)
	elif line.has("toggle"):
		(line["toggle"] as Callable).call(true)
		Sound.play(self, &"step", 0.0)


func _pick() -> void:
	var lines := _lines()
	if lines.is_empty():
		return
	var line: Dictionary = lines[_selected]
	if line.has("back"):
		go_back()
	elif line.has("page"):
		open_page(line["page"])
	elif line.has("slider"):
		_change(1)
	elif line.has("toggle"):
		_change(1)
	elif line.has("id"):
		Sound.play(self, &"draw_ready")
		chosen.emit(line["id"])


# --- Drawing ----------------------------------------------------------------------

func _draw() -> void:
	_boxes.clear()
	if shown <= 0.0 or _stack.is_empty():
		return
	if current_page() == &"controls":
		_draw_controls()
		return
	var view := size
	var font_size := int(view.y * text_size)
	var step := font_size * line_gap
	var at := Vector2(view.x * origin.x, view.y * origin.y)
	var alpha := shown * _page_fade
	var page: Dictionary = _pages[current_page()]
	var title: String = page["title"]
	# A page other than the first gets its name above, small and spaced out,
	# with a thin vermilion rule under it.
	if not title.is_empty():
		var head := int(font_size * 0.62)
		var head_at := at + Vector2(0, -step * 1.05)
		UiStyle.text(self, head_at, title.to_upper(), head, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.7 * alpha), head * 0.35)
		draw_rect(Rect2(head_at + Vector2(0, head * 0.5), Vector2(UiStyle.width(title.to_upper(), head, head * 0.35), 2)),
				Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, 0.85 * alpha))
	var lines: Array = page["lines"]
	var column := font_size * 9.5   # where slider values and switches line up
	for i in lines.size():
		var line: Dictionary = lines[i]
		var glow: float = _glow.get(i, 0.0)
		var baseline := at + Vector2(0, step * i)
		var label: String = line["label"]
		var wide := UiStyle.width(label, font_size)
		var extra := column + font_size * 6.0 - wide if (line.has("slider") or line.has("toggle")) else font_size * 3.0
		var box := Rect2(baseline + Vector2(-font_size * 1.1, -font_size * 1.0), Vector2(wide + extra + font_size * 1.1, font_size * 1.45))
		_boxes.append(box)
		UiStyle.highlight(self, Rect2(box.position, Vector2(box.size.x + font_size * 2.0, box.size.y)), glow, alpha)
		UiStyle.marker(self, baseline + Vector2(-font_size * 0.55 + glow * font_size * 0.1, -font_size * 0.33), font_size * 0.2 * glow, alpha * glow)
		var x := baseline.x + slide * font_size * ease(glow, 0.5)
		var colour := UiStyle.WASHI_DIM.lerp(UiStyle.WASHI, glow)
		UiStyle.text(self, Vector2(x, baseline.y), label, font_size, Color(colour.r, colour.g, colour.b, colour.a * alpha))
		if line.has("slider"):
			var level: float = (line["slider"] as Callable).call(0)
			_draw_level(Vector2(baseline.x + column, baseline.y), font_size, level, alpha, glow)
		elif line.has("toggle"):
			var on: bool = (line["toggle"] as Callable).call(false)
			var value_colour := UiStyle.WASHI if on else UiStyle.WASHI_DIM
			UiStyle.text(self, Vector2(baseline.x + column, baseline.y), "On" if on else "Off", font_size,
					Color(value_colour.r, value_colour.g, value_colour.b, value_colour.a * alpha * lerpf(0.8, 1.0, glow)))
			if glow > 0.5:
				_draw_arrows(Vector2(baseline.x + column, baseline.y), font_size, UiStyle.width("Off", font_size), alpha * glow)


## A volume: ten upright brush ticks, inked up to the level.
func _draw_level(at: Vector2, font_size: int, level: float, alpha: float, glow: float) -> void:
	var tick := font_size * 0.36
	var filled := roundi(level * 10.0)
	for k in 10:
		var x := at.x + k * tick * 1.55
		var tall := font_size * (0.5 + 0.04 * k)
		var colour := UiStyle.WASHI if k < filled else Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.18)
		draw_rect(Rect2(Vector2(x, at.y - tall + font_size * 0.05), Vector2(tick * 0.7, tall)), Color(colour.r, colour.g, colour.b, colour.a * alpha))
	var percent := "%d" % roundi(level * 100.0)
	UiStyle.text(self, Vector2(at.x + tick * 1.55 * 10.0 + font_size * 0.4, at.y), percent, int(font_size * 0.7),
			Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.75 * alpha))
	if glow > 0.5:
		_draw_arrows(at, font_size, tick * 1.55 * 10.0 + font_size * 1.6, alpha * glow)


## Small arrows either side of a value that A / D (left / right) change.
func _draw_arrows(at: Vector2, font_size: int, value_width: float, alpha: float) -> void:
	var y := at.y - font_size * 0.33
	var s := font_size * 0.16
	var colour := Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, alpha)
	var lx := at.x - font_size * 0.55
	draw_colored_polygon(PackedVector2Array([Vector2(lx - s, y), Vector2(lx + s * 0.6, y - s), Vector2(lx + s * 0.6, y + s)]), colour)
	var rx := at.x + value_width + font_size * 0.4
	draw_colored_polygon(PackedVector2Array([Vector2(rx + s, y), Vector2(rx - s * 0.6, y - s), Vector2(rx - s * 0.6, y + s)]), colour)


## The controls page: a dark panel in the middle of the screen with every
## control, keyboard on one side and gamepad on the other. Its keyboard keys
## can be changed (KeyBinds): W / S choose a row, Enter (or a click) and then
## the new key; Esc cancels. The last line puts every key back.
const PAD := {
	&"move_left": "Left stick", &"move_right": "Left stick", &"aim_up": "Up", &"aim_down": "Down",
	&"jump": "A", &"slash": "X", &"draw": "Y", &"dash": "RB", &"parry": "LB", &"heal": "B",
	&"gust": "RT", &"pause": "Start",
}

var _bind_row := 0
var _listening := false
var _row_boxes: Array[Rect2] = []


## The rows the controls page shows: [label, keys as written, gamepad,
## action or &"" if it cannot be changed here].
func _control_rows() -> Array:
	var rows := []
	for pair: Array in KeyBinds.ACTIONS:
		var action: StringName = pair[1]
		rows.append([pair[0], KeyBinds.label_of(action), PAD.get(action, ""), action])
	var duck := KeyBinds.keys_of(&"aim_down")
	var dash := KeyBinds.keys_of(&"dash")
	var fold := "-"
	if not duck.is_empty() and not dash.is_empty():
		fold = KeyBinds.key_label(duck[0]) + "  +  " + KeyBinds.key_label(dash[0])
	rows.append(["Flat Fold  (once learned)", fold, "Down + RB", &""])
	rows.append(["Mute", "M", "", &""])
	return rows


## Keys on the controls page. Returns true if it used the event.
func _controls_input(event: InputEvent) -> bool:
	var actions := KeyBinds.ACTIONS.size()
	if _listening:
		var key := event as InputEventKey
		if key and key.pressed and not key.echo:
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			if code == KEY_ESCAPE:
				_listening = false
				Sound.play(self, &"step", 0.0)
			elif KeyBinds.bind(KeyBinds.ACTIONS[_bind_row][1], code):
				_listening = false
				Sound.play(self, &"draw_ready", -4.0)
			else:
				Sound.play(self, &"paper_fold", -2.0)   # (a key kept for the menus)
			return true
		return event is InputEventKey or event is InputEventJoypadButton
	if _is(event, [&"ui_up", &"aim_up"]):
		_bind_row = wrapi(_bind_row - 1, 0, actions + 1)
		Sound.play(self, &"step", -2.0)
	elif _is(event, [&"ui_down", &"aim_down"]):
		_bind_row = wrapi(_bind_row + 1, 0, actions + 1)
		Sound.play(self, &"step", -2.0)
	elif _is(event, [&"ui_accept", &"jump", &"slash"]):
		_choose_row()
	elif _is(event, [&"ui_cancel", &"pause"]) or (event is InputEventKey and (event as InputEventKey).pressed
			and (event as InputEventKey).keycode == KEY_BACKSPACE):
		go_back()
	else:
		return false
	return true


func _choose_row() -> void:
	if _bind_row < KeyBinds.ACTIONS.size():
		_listening = true
		Sound.play(self, &"step", 1.0)
	else:
		KeyBinds.reset()
		Sound.play(self, &"draw_ready", -4.0)


func _draw_controls() -> void:
	var view := size
	var alpha := shown * _page_fade
	var font_size := int(view.y * 0.025)
	var row := font_size * 1.85
	var rows := _control_rows()
	var panel_size := Vector2(minf(view.x * 0.8, font_size * 42.0), row * (rows.size() + 3.8))
	var panel := Rect2((view - panel_size) * 0.5, panel_size)
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.0, 0.0, 0.02, 0.45 * alpha))
	draw_rect(panel, Color(0.03, 0.03, 0.05, 0.86 * alpha))
	for y: float in [panel.position.y, panel.end.y - 2.0]:
		draw_rect(Rect2(Vector2(panel.position.x, y), Vector2(panel.size.x, 2)), Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.25 * alpha))
	var left := panel.position.x + font_size * 1.6
	var key_x := panel.position.x + panel.size.x * 0.56
	var pad_x := panel.position.x + panel.size.x * 0.8
	var y := panel.position.y + row * 1.1
	var head := int(font_size * 0.8)
	UiStyle.text(self, Vector2(left, y), "CONTROLS", head, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.8 * alpha), head * 0.35)
	draw_rect(Rect2(Vector2(left, y + head * 0.45), Vector2(UiStyle.width("CONTROLS", head, head * 0.35), 2)), Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, alpha))
	UiStyle.text(self, Vector2(key_x, y), "KEYBOARD", head, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.55 * alpha), head * 0.3)
	UiStyle.text(self, Vector2(pad_x, y), "GAMEPAD", head, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.55 * alpha), head * 0.3)
	y += row * 1.2
	_row_boxes.clear()
	var washi := Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b)
	for i in rows.size() + 1:
		var band := Rect2(Vector2(panel.position.x + font_size * 0.6, y - row * 0.62), Vector2(panel.size.x - font_size * 1.2, row))
		var chosen := i == _bind_row and not UiStyle.using_pad
		if chosen:
			# The chosen row: a soft wash and a vermilion diamond.
			draw_rect(band, Color(washi, 0.09 * alpha))
			var d := font_size * 0.22
			var dx := panel.position.x + font_size * 1.0
			var dy := y - font_size * 0.3
			draw_colored_polygon(PackedVector2Array([Vector2(dx, dy - d), Vector2(dx + d, dy), Vector2(dx, dy + d), Vector2(dx - d, dy)]),
					Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, alpha))
		elif i % 2 == 0:
			draw_rect(band, Color(1, 1, 1, 0.03 * alpha))
		if i == rows.size():
			# The last line: every key back as the game came.
			UiStyle.text(self, Vector2(left, y), "Reset to the original keys", font_size, Color(washi, (0.92 if chosen else 0.6) * alpha))
			_row_boxes.append(band)
			break
		var line: Array = rows[i]
		var dim := 0.92 if (line[3] as StringName) != &"" else 0.6
		UiStyle.text(self, Vector2(left, y), line[0], font_size, Color(washi, dim * alpha))
		var x := key_x
		if chosen and _listening:
			var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.006)
			UiStyle.text(self, Vector2(x, y), "Press a key...", font_size, Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, blink * alpha))
		else:
			for key: String in (line[1] as String).split("  "):
				if key == "/" or key == "+":
					UiStyle.text(self, Vector2(x, y), key, font_size, Color(1, 1, 1, 0.5 * alpha))
					x += font_size * 0.8
					continue
				x += UiStyle.keycap(self, Vector2(x, y), key, int(font_size * 0.8), alpha) + font_size * 0.35
		var pad: String = line[2]
		if not pad.is_empty():
			var round_button := pad.length() == 1
			if round_button or pad == "RB" or pad == "LB" or pad == "Start":
				UiStyle.keycap(self, Vector2(pad_x, y), pad, int(font_size * 0.8), alpha, round_button)
			else:
				UiStyle.text(self, Vector2(pad_x, y), pad, int(font_size * 0.85), Color(washi, 0.8 * alpha))
		if i < KeyBinds.ACTIONS.size():
			_row_boxes.append(band)
		else:
			_row_boxes.append(Rect2())
		y += row
	var prompts := [["Esc", "B", "Cancel"]] if _listening else [["Enter", "A", "Change key"], ["Esc", "B", "Back"]]
	UiStyle.prompts(self, Vector2(panel.end.x - font_size, panel.end.y + row * 0.9), prompts, int(font_size * 0.8), alpha)
	_boxes.append(panel)
