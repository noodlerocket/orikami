class_name ActionHint
extends Control
## A quiet hint over something in the world that he can act on (the Ward's
## gate: "J  Cut the charms"): a key cap (or gamepad button) and the words in
## the menus' style, on a soft dark shading, floating just above the thing.
## It fades in while `near` is true and out when not.
## Set `point` (world position) and `items` ([[key, pad button, words]]).

var point := Vector3.ZERO
var items: Array = []
var near := false
var _shown := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _input(event: InputEvent) -> void:
	UiStyle.note_device(event)


func _process(delta: float) -> void:
	_shown = move_toward(_shown, 1.0 if near else 0.0, delta * (2.5 if near else 3.5))
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if _shown <= 0.0 or camera == null or camera.is_position_behind(point) or items.is_empty():
		return
	var view := size
	var at := camera.unproject_position(point)
	var alpha := ease(_shown, 0.6)
	var font_size := int(view.y * 0.028)
	var wide := 0.0
	for item: Array in items:
		var cap: String = item[1] if UiStyle.using_pad else item[0]
		wide += maxf(font_size * 1.45, UiStyle.width(cap, font_size) + font_size * 0.9) + font_size * 0.45 + UiStyle.width(item[2], font_size)
	at.x = clampf(at.x, wide * 0.5 + 20.0, view.x - wide * 0.5 - 20.0)
	at.y = clampf(at.y - (1.0 - alpha) * view.y * 0.01, font_size * 2.0, view.y - font_size * 2.0)
	var shade := Rect2(at - Vector2(wide * 0.5 + font_size * 2.0, font_size * 1.8), Vector2(wide + font_size * 4.0, font_size * 3.0))
	draw_texture_rect(UiStyle.shade("spot"), shade, false, Color(1, 1, 1, 0.85 * alpha))
	UiStyle.prompts(self, Vector2(at.x + wide * 0.5, at.y), items, font_size, alpha)
