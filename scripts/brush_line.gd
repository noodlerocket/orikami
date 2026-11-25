class_name BrushLine
extends Control
## A spoken line in brush lettering (an image rendered by
## tools/render_lettering.gd), along the bottom of the screen: brushed on
## from left to right, held, and wiped away the same way. Pale on a soft
## band of sumi so it reads over anything.

var texture: Texture2D
var shown := false
var _on := 0.0      # 0 to 1: how much is brushed on
var _off := 0.0     # 0 to 1: how much is wiped away


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Brush it on, hold it `hold` seconds, wipe it away, then remove it.
func show_line(hold: float) -> void:
	shown = true
	var t := create_tween()
	t.tween_property(self, "_on", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	t.tween_interval(hold)
	t.tween_property(self, "_off", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	t.tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if texture == null or _on <= 0.0:
		return
	var view := size
	var h := view.y * 0.06
	var w := texture.get_width() * h / texture.get_height()
	var at := Vector2((view.x - w) * 0.5, view.y * 0.78)
	# The band behind, fading at its ends.
	var band := Rect2(at.x - h, at.y - h * 0.1, w + h * 2.0, h * 1.2)
	var alpha := 1.0 - _off
	for k in 12:
		var u0 := float(k) / 12.0
		var a := sin(PI * (u0 + 0.5 / 12.0)) * 0.42 * alpha * _on
		draw_rect(Rect2(band.position.x + band.size.x * u0, band.position.y, band.size.x / 12.0 + 1.0, band.size.y), Color(0.02, 0.02, 0.05, a))
	# The words, brushed on from the left and wiped away from the left.
	var from := clampf(_off, 0.0, 1.0)
	var to := clampf(_on, 0.0, 1.0)
	if to <= from:
		return
	var src := Rect2(texture.get_width() * from, 0.0, texture.get_width() * (to - from), texture.get_height())
	var dst := Rect2(at.x + w * from, at.y, w * (to - from), h)
	draw_texture_rect_region(texture, dst, src, Color(0.95, 0.92, 0.86, 1.0))
