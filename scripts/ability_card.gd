class_name AbilityCard
extends Control
## A card shown when the Ronin learns an ability: like the tutorial's
## cards (the same soft ink oval, brush title, key caps), with a vermilion
## line "learned" over the title. It stays until he has used the ability
## once (or `stay` seconds pass), then fades.

@export var stay := 9.0

var title := "Crane Glide"
var prompts: Array = [["hold Space", "hold A", "Glide"]]
var advice := "In the air, hold Jump: paper wings carry you over gaps. The wind leans on them."
## Returns true once he has used it (the card then goes).
var used: Callable = func() -> bool: return false

var _shown := 0.0
var _age := 0.0
var _leaving := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_age += delta
	if not _leaving and _age > 1.2 and (used.call() or _age > stay):
		_leaving = true
	_shown = move_toward(_shown, 0.0 if _leaving else 1.0, delta / 0.45)
	if _leaving and _shown <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if _shown <= 0.0 or size.y < 50.0:
		return
	var view := size
	var alpha := ease(_shown, 0.6)
	var middle := Vector2(view.x * 0.5, view.y * 0.16 - (1.0 - alpha) * view.y * 0.02)
	var title_size := int(view.y * 0.046)
	var line_size := int(view.y * 0.022)
	var prompt_size := int(view.y * 0.024)
	var wide := maxf(UiStyle.width(title, title_size) + view.y * 0.1, UiStyle.width(advice, line_size) + view.y * 0.06)
	wide = maxf(wide, view.y * 0.6)
	var panel := Rect2(middle - Vector2(wide * 0.5, title_size * 1.35), Vector2(wide, title_size * 1.35 + line_size * 4.6 + prompt_size * 1.6))
	draw_texture_rect(UiStyle.shade("spot"), panel.grow_individual(wide * 0.25, title_size * 0.8, wide * 0.25, title_size * 1.2), false,
			Color(1, 1, 1, 0.95 * alpha))
	var learned := "learned"
	var small := int(line_size * 0.85)
	UiStyle.text(self, Vector2(middle.x - UiStyle.width(learned, small, small * 0.3) * 0.5, panel.position.y + small * 1.2), learned,
			small, Color(0.95, 0.55, 0.45, 0.95 * alpha), small * 0.3)
	var title_at := Vector2(middle.x - UiStyle.width(title, title_size) * 0.5, panel.position.y + title_size * 1.55)
	UiStyle.text(self, title_at, title, title_size, Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, alpha))
	var row_width := 0.0
	for item: Array in prompts:
		row_width += UiStyle.width(item[0] if not UiStyle.using_pad else item[1], prompt_size) + prompt_size * 1.5 \
				+ UiStyle.width(item[2], prompt_size) + prompt_size * 1.6
	var prompt_y := title_at.y + prompt_size * 2.1
	UiStyle.prompts(self, Vector2(middle.x + row_width * 0.5, prompt_y), prompts, prompt_size, alpha)
	UiStyle.text(self, Vector2(middle.x - UiStyle.width(advice, line_size) * 0.5, prompt_y + line_size * 2.2), advice, line_size,
			Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.78 * alpha))
