class_name KeyBinds
extends RefCounted
## The player's own keyboard keys (Julian: "there should be an ability to
## change your keybinds"). The Controls page lists the actions below; picking
## one and pressing a key gives that action that key instead of its own. A
## key already used by another action is swapped over to it, so no action is
## ever left without a key. Saved in user://settings.cfg ("keys": action ->
## physical keycode) and applied at start (UiStyle.load_settings). The
## gamepad's buttons are not changed. The menus keep the arrows, Enter and
## Esc whatever is chosen, so nobody can lock themselves out.

## [what the Controls page calls it, the action]. (The Flat Fold is duck then
## dash, so it follows those two; Mute is always M.)
const ACTIONS := [
	["Move left", &"move_left"],
	["Move right", &"move_right"],
	["Aim up", &"aim_up"],
	["Duck  (aim down)", &"aim_down"],
	["Jump  (off walls too)", &"jump"],
	["Cut", &"slash"],
	["Iaijutsu draw  (hold, let go)", &"draw"],
	["Dash", &"dash"],
	["Parry  (hold to block)", &"parry"],
	["Heal  (hold, 3 ink)", &"heal"],
	["Fan Gust  (once learned)", &"gust"],
	["Pause", &"pause"],
]
## Keys kept for every action alongside the chosen one (the arrows still
## move and aim, as they always did).
const KEEP := {
	&"move_left": [KEY_LEFT], &"move_right": [KEY_RIGHT],
	&"aim_up": [KEY_UP], &"aim_down": [KEY_DOWN],
	&"pause": [KEY_ESCAPE],   # (Esc always pauses)
}
## Where the keys are saved (the settings file; the automated check uses
## its own).
static var file_path := UiStyle.SETTINGS_FILE
## Keys that cannot be chosen (the menus need them; M mutes).
const RESERVED := [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_M]


## The keyboard keys an action has now (not counting the kept arrows).
static func keys_of(action: StringName) -> Array[Key]:
	var out: Array[Key] = []
	if not InputMap.has_action(action):
		return out
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			if code not in (KEEP.get(action, []) as Array):
				out.append(code)
	return out


## How a key is written on its key cap.
static func key_label(code: Key) -> String:
	match code:
		KEY_SPACE:
			return "Space"
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_ALT:
			return "Alt"
		KEY_TAB:
			return "Tab"
		KEY_ESCAPE:
			return "Esc"
	return OS.get_keycode_string(code)


## The action's keys as the Controls page writes them ("L  /  Shift").
static func label_of(action: StringName) -> String:
	var parts: Array[String] = []
	for code: int in KEEP.get(action, []):
		if code == KEY_ESCAPE:
			parts.append("Esc")
	for code: Key in keys_of(action):
		parts.append(key_label(code))
	return "  /  ".join(parts) if not parts.is_empty() else "-"


## Gives the action this key instead of its own. If another action had it,
## that action gets this one's old first key (a swap). Returns false for a
## key that cannot be chosen.
static func bind(action: StringName, code: Key) -> bool:
	if code in RESERVED:
		return false
	var old := keys_of(action)
	for pair: Array in ACTIONS:
		var other: StringName = pair[1]
		if other != action and code in keys_of(other):
			var theirs := keys_of(other)
			theirs.erase(code)
			if theirs.is_empty() and not old.is_empty():
				theirs.append(old[0])
			_set_keys(other, theirs)
	_set_keys(action, [code])
	save()
	return true


static func _set_keys(action: StringName, codes: Array) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for code: int in codes + (KEEP.get(action, []) as Array):
		var event := InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)


## Back to the keys the game comes with.
static func reset() -> void:
	for pair: Array in ACTIONS:
		var action: StringName = pair[1]
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		var setting: Dictionary = ProjectSettings.get_setting("input/" + String(action), {})
		for event: InputEvent in setting.get("events", []):
			if event is InputEventKey:
				InputMap.action_add_event(action, event)
	var file := ConfigFile.new()
	file.load(file_path)
	if file.has_section("keys"):
		file.erase_section("keys")
	file.save(file_path)


static func save() -> void:
	var file := ConfigFile.new()
	file.load(file_path)
	for pair: Array in ACTIONS:
		var action: StringName = pair[1]
		file.set_value("keys", String(action), keys_of(action))
	file.save(file_path)


## A prompt's keys as the player has them now: every key name the game came
## with ("Space", "hold K", "Space, then L", "A  D") is written as the key
## that does that now. Other words and the menus' keys are left alone.
static func live(text: String) -> String:
	var map := _renames()
	if map.is_empty():
		return text
	var words := text.split(" ")
	for i in words.size():
		var word := words[i]
		var tail := ""
		if word.ends_with(","):
			tail = ","
			word = word.trim_suffix(",")
		if map.has(word):
			words[i] = (map[word] as String) + tail
	return " ".join(words)


static var _defaults := {}   # action -> the keys it came with


## Original key name -> the key that does the same now (only those changed).
static func _renames() -> Dictionary:
	if _defaults.is_empty():
		for pair: Array in ACTIONS:
			var action: StringName = pair[1]
			var codes: Array[int] = []
			var setting: Dictionary = ProjectSettings.get_setting("input/" + String(action), {})
			for event: InputEvent in setting.get("events", []):
				var key := event as InputEventKey
				if key:
					var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
					if code not in (KEEP.get(action, []) as Array) and code not in RESERVED:
						codes.append(code)
			_defaults[action] = codes
	var out := {}
	for pair: Array in ACTIONS:
		var action: StringName = pair[1]
		var now := keys_of(action)
		var was: Array = _defaults[action]
		for j in was.size():
			if now.is_empty():
				break
			var then := key_label(was[j])
			var here := key_label(now[mini(j, now.size() - 1)])
			if then != here:
				out[then] = here
	return out


## The saved keys, put in place (at start).
static func apply_saved() -> void:
	var file := ConfigFile.new()
	if file.load(file_path) != OK or not file.has_section("keys"):
		return
	for pair: Array in ACTIONS:
		var action: StringName = pair[1]
		var codes: Array = file.get_value("keys", String(action), [])
		if not codes.is_empty() and InputMap.has_action(action):
			_set_keys(action, codes)
