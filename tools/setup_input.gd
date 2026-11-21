extends SceneTree
## One-off helper: writes the control scheme into project.godot.
## Run it again after editing the table below:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/setup_input.gd
## Afterwards the actions show up in Project > Project Settings > Input Map.


func _init() -> void:
	var actions := {
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)],
		"aim_up": [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)],
		"aim_down": [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)],
		"jump": [_key(KEY_SPACE), _button(JOY_BUTTON_A)],
		"slash": [_key(KEY_J), _button(JOY_BUTTON_X)],
		"dash": [_key(KEY_L), _key(KEY_SHIFT), _button(JOY_BUTTON_RIGHT_SHOULDER), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"heal": [_key(KEY_U), _button(JOY_BUTTON_B)],
		"draw": [_key(KEY_K), _button(JOY_BUTTON_Y)],
		"parry": [_key(KEY_I), _button(JOY_BUTTON_LEFT_SHOULDER), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
	}
	for action: String in actions:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.4, "events": actions[action]})
	var result := ProjectSettings.save()
	print("Input map saved (0 means OK): ", result)
	quit()


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.device = -1  # -1 means "any controller"
	return event


func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	event.device = -1
	return event
