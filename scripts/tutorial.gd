class_name Tutorial
extends Control
## The tutorial, after the Ronin climbs out of the well: one card at a time
## near the top of the screen, in the menus' style, teaching the controls.
## Each card waits until he has actually done the thing (or, for healing,
## until it has been read), then a vermilion seal is stamped on it and it
## fades, and the next one comes in. The game carries on underneath; nothing
## stops. Backspace (Select on a gamepad) skips the rest.
##
## Keys or gamepad buttons are shown, whichever was used last.

signal finished

## [title, [key, gamepad, words] prompts, a line of advice, what completes it]
const STEPS := [
	["Move", [["A  D", "Stick", "Walk"]], "Walk along the street.", &"move"],
	["Jump", [["Space", "A", "Jump"]], "Hold it longer to jump higher. Jump again from a wall to climb.", &"jump"],
	["Dash", [["L", "RB", "Dash"], ["Shift", "RT", "Dash"]], "A quick, low lunge. Either key does it.", &"dash"],
	["Cut", [["J", "X", "Cut"], ["W  S", "Stick", "Aim up or down"]], "A swift draw from the scabbard. Cut down in the air to bounce off enemies.", &"slash"],
	["Parry", [["I", "LB", "Parry"]], "Press it just as a blow lands to turn it aside. Parries break an enemy's guard.", &"parry"],
	["Block", [["hold I", "hold LB", "Block"]], "Keep your guard up. It takes the blow, but too many break it.", &"block"],
	["Iaijutsu draw", [["hold K", "hold Y", "Ready"], ["let go", "let go", "Strike"]], "Hold until the blade gleams, then let go: a lightning dash and cut.", &"draw"],
	["Duck", [["hold S", "hold Down", "Duck"]], "Get under attacks that sweep high.", &"duck"],
	["Heal", [["hold U", "hold B", "Heal"]], "You are hurt. Hold to spend 3 ink and mend your paper. Cutting enemies fills your ink.", &"heal"],
]

## Seconds a card takes to come in and to go.
@export var card_time := 0.45
## Seconds the healing card stays up if he has no ink to heal with.
@export var read_time := 6.0

var ronin: Ronin

var _step := 0
var _shown := 0.0        # 0..1 the current card
var _done := 0.0         # 0..1 its seal, once completed
var _leaving := false
var _walked := 0.0
var _last_x := 0.0
var _held := 0.0         # how long a hold has lasted
var _drawn := false      # the draw has been readied (held long enough)
var _read := 0.0
var _healed_from := -1    # his health when the healing card came up


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ronin:
		_last_x = ronin.global_position.x
		# He starts the lessons one point short of full health, with enough
		# ink for one heal, so the last lesson can be practised.
		ronin.health = maxi(ronin.max_health - 1, 1)
		ronin.ink = maxi(ronin.ink, ronin.heal_cost)
		ronin.health_changed.emit(ronin.health, ronin.max_health)
		ronin.ink_changed.emit(ronin.ink, ronin.max_ink)


func _input(event: InputEvent) -> void:
	UiStyle.note_device(event)
	var skip_key := event is InputEventKey and event.is_pressed() and (event as InputEventKey).keycode == KEY_BACKSPACE
	var skip_button := event is InputEventJoypadButton and event.is_pressed() and (event as InputEventJoypadButton).button_index == JOY_BUTTON_BACK
	if skip_key or skip_button:
		_end()


func _process(delta: float) -> void:
	if _step >= STEPS.size() or ronin == null or not is_instance_valid(ronin):
		return
	queue_redraw()
	if _leaving:
		_shown = move_toward(_shown, 0.0, delta / card_time)
		if _shown <= 0.0:
			_leaving = false
			_done = 0.0
			_held = 0.0
			_drawn = false
			_read = 0.0
			_step += 1
			if _step >= STEPS.size():
				_end()
		return
	_shown = move_toward(_shown, 1.0, delta / card_time)
	if _done > 0.0:
		_done = move_toward(_done, 1.0, delta / 0.25)
		if _done >= 1.0:
			_held += delta
			if _held > 0.7:
				_leaving = true
		return
	if _shown >= 1.0 and _completed(delta):
		_done = 0.01
		_held = 0.0
		Sound.play(self, &"draw_ready", -4.0)


## Has he done what the current card asks?
func _completed(delta: float) -> bool:
	var goal: StringName = STEPS[_step][3]
	match goal:
		&"move":
			_walked += absf(ronin.global_position.x - _last_x)
			_last_x = ronin.global_position.x
			return _walked > 3.0
		&"jump":
			return Input.is_action_just_pressed(&"jump")
		&"dash":
			return Input.is_action_just_pressed(&"dash")
		&"slash":
			return Input.is_action_just_pressed(&"slash")
		&"parry":
			return Input.is_action_just_pressed(&"parry")
		&"block":
			_held = _held + delta if Input.is_action_pressed(&"parry") else 0.0
			return _held > 0.8
		&"draw":
			if Input.is_action_pressed(&"draw"):
				_held += delta
				_drawn = _drawn or _held >= ronin.draw_charge_time
			elif _drawn:
				return true
			else:
				_held = 0.0
			return false
		&"duck":
			_held = _held + delta if Input.is_action_pressed(&"aim_down") and ronin.is_on_floor() else 0.0
			return _held > 0.5
		&"heal":
			# Done when he has healed. (If he is somehow already whole, or has
			# no ink, the card is simply read.)
			if ronin.health >= ronin.max_health:
				_read += delta
				return _read > 1.2 or _healed_from >= 0
			if _healed_from < 0:
				_healed_from = ronin.health
			if ronin.ink < ronin.heal_cost:
				_read += delta
				return _read > read_time
			return false
		_:
			_read += delta
			return _read > read_time
	return false


func _end() -> void:
	if not is_inside_tree():
		return
	finished.emit()
	queue_free()


func _draw() -> void:
	if _step >= STEPS.size() or _shown <= 0.0 or size.y < 50.0:
		return
	var view := size
	var step: Array = STEPS[_step]
	var alpha := ease(_shown, 0.6)
	var middle := Vector2(view.x * 0.5, view.y * 0.16 - (1.0 - alpha) * view.y * 0.02)
	var title_size := int(view.y * 0.046)
	var line_size := int(view.y * 0.022)
	var prompt_size := int(view.y * 0.024)
	var title: String = step[0]
	var advice: String = step[2]
	var wide := maxf(UiStyle.width(title, title_size) + view.y * 0.1, UiStyle.width(advice, line_size) + view.y * 0.06)
	wide = maxf(wide, view.y * 0.6)
	var panel := Rect2(middle - Vector2(wide * 0.5, title_size * 1.35), Vector2(wide, title_size * 1.35 + line_size * 4.6 + prompt_size * 1.6))
	# A soft oval of ink behind it, feathered all round.
	draw_texture_rect(UiStyle.shade("spot"), panel.grow_individual(wide * 0.25, title_size * 0.8, wide * 0.25, title_size * 1.2), false,
			Color(1, 1, 1, 0.95 * alpha))
	# Which step this is, small, and the title.
	var count := "%d / %d" % [_step + 1, STEPS.size()]
	var count_size := int(line_size * 0.85)
	UiStyle.text(self, Vector2(middle.x - UiStyle.width(count, count_size, count_size * 0.3) * 0.5, panel.position.y + count_size * 1.2), count,
			count_size, Color(0.95, 0.55, 0.45, 0.95 * alpha), count_size * 0.3)
	var title_at := Vector2(middle.x - UiStyle.width(title, title_size) * 0.5, panel.position.y + title_size * 1.55)
	UiStyle.text(self, title_at, title, title_size, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, alpha))
	# The controls for it, as key caps (or gamepad buttons).
	var prompts: Array = step[1]
	var row_width := 0.0
	for item: Array in prompts:
		row_width += UiStyle.width(item[0] if not UiStyle.using_pad else item[1], prompt_size) + prompt_size * 1.5 \
				+ UiStyle.width(item[2], prompt_size) + prompt_size * 1.6
	var prompt_y := title_at.y + prompt_size * 2.1
	UiStyle.prompts(self, Vector2(middle.x + row_width * 0.5, prompt_y), prompts, prompt_size, alpha)
	# The advice, smaller and dimmer.
	UiStyle.text(self, Vector2(middle.x - UiStyle.width(advice, line_size) * 0.5, prompt_y + line_size * 2.2), advice, line_size,
			Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.78 * alpha))
	# Done: a vermilion seal stamped beside the title.
	if _done > 0.0:
		var side := title_size * 1.05 * lerpf(1.4, 1.0, _done)
		var at := Vector2(title_at.x + UiStyle.width(title, title_size) + title_size * 0.4, title_at.y - title_size * 0.82)
		var seal := Rect2(at, Vector2(side, side))
		draw_rect(seal, Color(UiStyle.VERMILION.r, UiStyle.VERMILION.g, UiStyle.VERMILION.b, _done * alpha))
		draw_rect(seal.grow(-side * 0.08), Color(0.96, 0.9, 0.84, 0.9 * _done * alpha), false, maxf(1.5, side * 0.03))
		var mark_size := int(side * 0.62)
		var mark := "了"   # "finished"
		draw_string(UiStyle.FONT, Vector2(seal.get_center().x - UiStyle.width(mark, mark_size) * 0.5, seal.position.y + side * 0.74), mark,
				HORIZONTAL_ALIGNMENT_LEFT, -1, mark_size, Color(0.97, 0.92, 0.86, _done * alpha))
	# How to skip the rest, small, under it.
	var skip_size := int(line_size * 0.8)
	UiStyle.prompts(self, Vector2(panel.end.x - skip_size, panel.end.y + skip_size * 1.6), [["Backspace", "Select", "Skip the lessons"]],
			skip_size, 0.55 * alpha)
