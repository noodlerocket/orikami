class_name LoadingCover
extends Control
## The cover shown while the browser version warms up (main.gd, _warm_up):
## dark sumi paper, and a pale ensō painted round as the warm-up goes, in
## the same spirit as the healing circle. It fades away when it is done.

## 0 to 1: how much of the circle is painted.
var progress := 0.0

var _rng := RandomNumberGenerator.new()
var _wobble: PackedFloat32Array


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 7
	for i in 129:
		_wobble.append(_rng.randf_range(-1.0, 1.0))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.03, 0.03, 0.06, modulate.a))
	var middle := view * 0.5
	var radius := view.y * 0.11
	var steps := 128
	var shown := int(steps * clampf(progress, 0.0, 1.0) * 0.96)
	# The brush lands heavily and thins, with a slightly ragged edge.
	for i in shown:
		var t := float(i) / steps
		var angle := deg_to_rad(-100.0) - t * TAU * 0.96
		var at := middle + Vector2(cos(angle), sin(angle)) * (radius + _wobble[i] * radius * 0.015)
		var width := lerpf(radius * 0.13, radius * 0.045, t) * (1.0 + 0.2 * _wobble[(i * 5) % 129])
		draw_circle(at, width, Color(0.93, 0.89, 0.8, 0.92))
