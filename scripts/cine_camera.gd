class_name CineCamera
extends Node
## A cutscene's camera and its timeline (the Festival Dragon's intro and its
## death; the Hannya's cutscene does the same in its own script). 2.5D: the
## camera stays in front of the diorama and pushes, cranes, pans and tracks.
## Shots: `shot(start, end, from, to, look_from, look_to, ...)`, where any
## point may be a Callable returning a world point (to track something that
## moves). Events: `at(time, callable)`. Letterbox bars slide in at the start
## and out at the end; `shake(amount)` jolts the camera; `flash(alpha)`
## whitens the screen a moment. When the time runs out (or `finish()`), the
## game camera is made current again and `finished` is emitted.

signal finished

var length := 10.0
var game_camera: Camera3D
## Seconds into it; runs on the real clock (a slow-motion moment does not
## stretch the cutscene).
var time := 0.0

var _camera: Camera3D
var _shots: Array[Dictionary] = []
var _events: Array = []
var _next := 0
var _shake := 0.0
var _bars: Array[ColorRect] = []
var _white: ColorRect
var _overlay: CanvasLayer
var _done := false
var _last_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera3D.new()
	_camera.near = 0.05
	_camera.far = 400.0
	_camera.cull_mask = game_camera.cull_mask if game_camera else _camera.cull_mask
	add_child(_camera)
	_overlay = CanvasLayer.new()
	_overlay.layer = 6
	add_child(_overlay)
	_white = ColorRect.new()
	_white.color = Color(1.0, 0.98, 0.94, 0.0)
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_white)
	for top: bool in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.0, 0.0, 0.0)
		bar.anchor_right = 1.0
		if not top:
			bar.anchor_top = 1.0
		bar.anchor_bottom = 0.0 if top else 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.add_child(bar)
		_bars.append(bar)
	_events.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_last_ms = Time.get_ticks_msec()
	_animate(0.0)
	_camera.current = true
	var t := create_tween().set_ignore_time_scale()
	t.tween_method(_set_bars, 0.0, 0.11, 0.8).set_trans(Tween.TRANS_SINE)


## The overlay, for titles and lines to sit on during the cutscene.
func overlay() -> CanvasLayer:
	return _overlay


func shot(start: float, end: float, from: Variant, to: Variant, look_from: Variant, look_to: Variant,
		fov := Vector2(38.0, 38.0), roll := Vector2.ZERO, hand := 0.03, ease := 1.0) -> void:
	_shots.append({"start": start, "end": end, "from": from, "to": to, "look_from": look_from,
			"look_to": look_to, "fov": fov, "roll": roll, "hand": hand, "ease": ease})


func at(when: float, what: Callable) -> void:
	_events.append([when, what])


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func flash(alpha: float, fade := 0.5) -> void:
	_white.color.a = alpha
	var t := create_tween().set_ignore_time_scale()
	t.tween_property(_white, "color:a", 0.0, fade)


func camera() -> Camera3D:
	return _camera


func _process(_delta: float) -> void:
	if _done:
		return
	var now := Time.get_ticks_msec()
	var delta := minf((now - _last_ms) * 0.001, 0.1)
	_last_ms = now
	time += delta
	while _next < _events.size() and time >= _events[_next][0]:
		(_events[_next][1] as Callable).call()
		_next += 1
	_animate(delta)
	if time >= length:
		finish()


func _point(p: Variant) -> Vector3:
	return (p as Callable).call() if p is Callable else p


func _animate(delta: float) -> void:
	if _shots.is_empty():
		return
	var s: Dictionary = _shots[_shots.size() - 1]
	for each: Dictionary in _shots:
		if time < each["end"]:
			s = each
			break
	var u := clampf((time - s["start"]) / maxf(s["end"] - s["start"], 0.01), 0.0, 1.0)
	var e := pow(u, s["ease"])
	e = e * e * (3.0 - 2.0 * e)
	var at_point := _point(s["from"]).lerp(_point(s["to"]), e)
	var look := _point(s["look_from"]).lerp(_point(s["look_to"]), e)
	var hand: float = s["hand"]
	var drift := Vector3(sin(time * 0.9) + 0.5 * sin(time * 2.3), cos(time * 0.7) + 0.4 * sin(time * 1.9), 0.0) * hand
	_shake = maxf(_shake - delta * 2.2, 0.0)
	var jolt := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * 0.16
	if at_point.distance_to(look) < 0.01:
		look += Vector3(0.0, 0.0, -1.0)
	_camera.look_at_from_position(at_point + drift + jolt, look + drift * 0.5)
	var fov: Vector2 = s["fov"]
	var roll: Vector2 = s["roll"]
	_camera.fov = lerpf(fov.x, fov.y, e)
	_camera.rotate_object_local(Vector3.BACK, deg_to_rad(lerpf(roll.x, roll.y, e) + _shake * randf_range(-2.5, 2.5)))


func _set_bars(fraction: float) -> void:
	var height := get_viewport().get_visible_rect().size.y * fraction
	_bars[0].offset_bottom = height
	_bars[1].offset_top = -height


## Ends it: the bars slide away, the game camera takes over again.
func finish() -> void:
	if _done:
		return
	_done = true
	var t := create_tween().set_ignore_time_scale()
	t.tween_method(_set_bars, 0.11, 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	t.tween_callback(queue_free)
	if game_camera:
		game_camera.current = true
		if game_camera.has_method("snap_to_target"):
			game_camera.snap_to_target()
	finished.emit()
