class_name SkipPrompt
extends Control
## "Hold to skip" for every cutscene (the prologue, the climb out of the
## well, the Hannya): it appears in the top right when a button is
## pressed, a slim bar under it fills from the left while Space (A) is held,
## and when it is full `skipped` fires. Let go early and it empties again. It fades a few seconds after the
## last press. Drawn by UiStyle.skip_prompt.

signal skipped

## Seconds Space (A) must be held.
@export var hold_time := 0.8

var _held := 0.0
var _hint := 0.0
var _done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _input(event: InputEvent) -> void:
	UiStyle.note_device(event)
	if event.is_pressed() and not event.is_echo():
		_hint = 1.0


func _process(delta: float) -> void:
	if _done:
		_hint = maxf(_hint - delta * 2.0, 0.0)
	elif Input.is_action_pressed(&"jump"):
		_held = minf(_held + delta, hold_time)
		_hint = 1.0
		if _held >= hold_time:
			_done = true
			skipped.emit()
	else:
		_held = maxf(_held - delta * 2.5, 0.0)
		_hint = maxf(_hint - delta * 0.35, 0.0)
	queue_redraw()


func _draw() -> void:
	if size.y < 50.0:
		return
	# Top right: clear of the lines of text at the bottom of every cutscene.
	UiStyle.skip_prompt(self, Vector2(size.x * 0.955, size.y * 0.065), int(size.y * 0.022), clampf(_hint, 0.0, 1.0),
			_held / maxf(hold_time, 0.01))
