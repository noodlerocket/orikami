class_name BossBar
extends Control
## The boss's health, at the bottom of the screen, drawn in code like the
## Ronin's own display: her name in brush lettering (the same images as her
## title), a long ink stroke for her health that shortens as she is cut, and
## above it a thin vermilion line for her posture that grows out from the
## middle with every parry (when it meets the ends, she is broken).

const KANJI := preload("res://textures/title_hannya_kanji.png")
const NAME := preload("res://textures/title_hannya_name.png")

var _health := 1.0      # 0 to 1, as shown (eases toward the real value)
var _health_goal := 1.0
var _posture := 0.0
var _posture_goal := 0.0
var _show := 0.0
var _show_goal := 0.0
var _rng := RandomNumberGenerator.new()
var _rough: PackedFloat32Array


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 33
	for i in 81:
		_rough.append(_rng.randf_range(-1.0, 1.0))


func watch(boss: HannyaBoss) -> void:
	boss.health_changed.connect(func(current: int, maximum: int) -> void:
		_health_goal = float(current) / maxf(maximum, 1.0)
		_show_goal = 1.0 if current > 0 else 0.0)
	boss.posture_changed.connect(func(current: int, maximum: int) -> void:
		_posture_goal = float(current) / maxf(maximum, 1.0))
	boss.defeated.connect(func() -> void: _show_goal = 0.0)


func hide_bar() -> void:
	_show_goal = 0.0


func _process(delta: float) -> void:
	_health = move_toward(_health, _health_goal, delta * 0.8)
	_posture = move_toward(_posture, _posture_goal, delta * 3.0)
	_show = move_toward(_show, _show_goal, delta * 2.0)
	queue_redraw()


func _draw() -> void:
	if _show <= 0.0:
		return
	var view := get_viewport_rect().size
	var width := view.x * 0.52
	var left := (view.x - width) * 0.5
	var y := view.y * 0.9
	var thick := view.y * 0.016
	var alpha := _show
	# A torn strip of washi under it all, so the ink reads on the dark.
	var strip := PackedVector2Array()
	var strip_top := y - view.y * 0.075
	var strip_bottom := y + thick * 1.4
	for i in 41:
		strip.append(Vector2(left - 30.0 + (width + 60.0) * i / 40.0, strip_top + _rough[i] * 2.5))
	for i in range(40, -1, -1):
		strip.append(Vector2(left - 30.0 + (width + 60.0) * i / 40.0, strip_bottom + _rough[(i * 3) % 81] * 2.5))
	draw_colored_polygon(strip, Color(0.86, 0.83, 0.77, 0.9 * alpha))
	# Her name above the bar.
	var kanji_h := view.y * 0.05
	var kanji_w := KANJI.get_width() * kanji_h / KANJI.get_height()
	draw_texture_rect(KANJI, Rect2(Vector2(left - kanji_w * 0.1, y - kanji_h * 1.25), Vector2(kanji_w, kanji_h)),
			false, Color(0.07, 0.07, 0.1, alpha))
	var name_h := view.y * 0.028
	var name_w := NAME.get_width() * name_h / NAME.get_height()
	draw_texture_rect(NAME, Rect2(Vector2(left + kanji_w * 0.95, y - name_h * 1.7), Vector2(name_w, name_h)),
			false, Color(0.12, 0.12, 0.16, alpha))
	# The empty groove, then the ink of her health, with a ragged brush edge.
	draw_rect(Rect2(left, y - thick * 0.5, width, thick), Color(0.55, 0.52, 0.5, 0.45 * alpha))
	var ink := PackedVector2Array()
	var shown := width * _health
	if shown > 2.0:
		var steps := 80
		for i in steps + 1:
			var x := left + shown * i / steps
			ink.append(Vector2(x, y - thick * 0.6 + _rough[i] * thick * 0.12))
		for i in range(steps, -1, -1):
			var x := left + shown * i / steps
			ink.append(Vector2(x, y + thick * 0.6 + _rough[(i * 7) % 81] * thick * 0.12))
		draw_colored_polygon(ink, Color(0.03, 0.03, 0.05, 0.95 * alpha))

	# Posture: from the middle outward.
	if _posture > 0.0:
		var half := width * 0.5 * _posture
		var py := y - thick * 1.6
		draw_line(Vector2(left + width * 0.5 - half, py), Vector2(left + width * 0.5 + half, py),
				Color(0.78, 0.2, 0.13, alpha), maxf(thick * 0.35, 2.0))
