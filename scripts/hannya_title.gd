class_name HannyaTitle
extends Control
## The boss's title, painted on in the cutscene: a broad stroke of sumi ink
## swept across the lower third (drawn on from left to right, with a dry,
## broken tail), then her name, 般若, brushed large over it with "The Weeping
## Hannya" beside it and a line beneath, and a small vermilion seal stamped
## at the end.
##
## The lettering is in the Yuji Syuku brush font, rendered into images by
## tools/render_lettering.gd (so the game does not have to carry the font).

## (The Hannya's, unless set otherwise: Akane's title uses this too.)
var KANJI: Texture2D = preload("res://textures/title_hannya_kanji.png")
var NAME: Texture2D = preload("res://textures/title_hannya_name.png")
var SUBTITLE: Texture2D = preload("res://textures/title_hannya_subtitle.png")
## The boss's seal (a hanko with its two characters carved in; rendered by
## tools/render_seals.py). Replaced a plain square with a cut mark (Julian).
var SEAL: Texture2D = preload("res://textures/seal_hannya.png")

var _stroke := 0.0     # 0 to 1: how much of the brush stroke is drawn
var _words := 0.0      # 0 to 1: the name fading in
var _seal := 0.0       # 0 to 1: the seal stamped
var _rng := RandomNumberGenerator.new()
var _edge_top: PackedFloat32Array
var _edge_bottom: PackedFloat32Array


func _ready() -> void:
	_rng.seed = 808
	for i in 121:
		_edge_top.append(_rng.randf_range(-1.0, 1.0))
		_edge_bottom.append(_rng.randf_range(-1.0, 1.0))


func paint() -> void:
	var t := create_tween()
	t.tween_property(self, "_stroke", 1.0, 0.9).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "_words", 1.0, 1.2).set_delay(0.45)
	t.tween_property(self, "_seal", 1.0, 0.12)
	t.tween_callback(func() -> void: Sound.play(self, &"land", 2.0))


func _process(_delta: float) -> void:
	if _stroke > 0.0:
		queue_redraw()


func _draw() -> void:
	if _stroke <= 0.0:
		return
	var view := size
	var middle := Vector2(view.x * 0.5, view.y * 0.72)
	var length := view.x * 0.62
	var thick := view.y * 0.085
	var left := middle.x - length * 0.5
	# The brush stroke: thick where the brush lands, a dry, splitting tail.
	var drawn := length * _stroke
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 121:
		var u := float(i) / 120.0
		if u * length > drawn:
			break
		var swell := maxf(sin(PI * pow(u, 0.6)) * (1.0 - u * 0.35), 0.08)
		var x := left + u * length
		var lift := (u - 0.5) * thick * -0.35
		var rough := thick * 0.05 * swell
		top.append(Vector2(x, middle.y - thick * 0.5 * swell + _edge_top[i] * rough + lift))
		bottom.append(Vector2(x, middle.y + thick * 0.5 * swell + _edge_bottom[i] * rough + lift))
	if top.size() > 2:
		var shape := top.duplicate()
		bottom.reverse()
		shape.append_array(bottom)
		draw_colored_polygon(shape, Color(0.03, 0.03, 0.05, 0.94))
		# Dry-brush streaks breaking up the tail.
		for k in 7:
			var y := middle.y + (float(k) / 6.0 - 0.5) * thick * 0.7
			var from := left + length * (0.55 + 0.05 * (k % 3))
			var to := minf(left + drawn, left + length * (0.92 + 0.012 * k))
			if to > from:
				draw_line(Vector2(from, y + (to - from) * -0.03), Vector2(to, y + (to - from) * -0.06),
						Color(0.36, 0.38, 0.5, 0.55), 1.5)
	# Her name: the kanji brushed large over the start of the stroke, the
	# English beside them, a line beneath. Pale washi on the ink.
	if _words > 0.0:
		var washi := Color(0.94, 0.91, 0.85, _words)
		var kanji_height := thick * 2.1
		var kanji_size := Vector2(KANJI.get_width(), KANJI.get_height()) * (kanji_height / KANJI.get_height())
		var kanji_at := Vector2(left - kanji_size.x * 0.06, middle.y - kanji_height * 0.56)
		# A dark echo behind, like ink soaking through, then the white.
		draw_texture_rect(KANJI, Rect2(kanji_at + Vector2(4, 5), kanji_size), false, Color(0.0, 0.0, 0.03, _words * 0.7))
		draw_texture_rect(KANJI, Rect2(kanji_at, kanji_size), false, washi)
		var name_height := thick * 0.62
		var name_size := Vector2(NAME.get_width(), NAME.get_height()) * (name_height / NAME.get_height())
		var name_at := Vector2(kanji_at.x + kanji_size.x * 0.86, middle.y - name_height * 0.55)
		draw_texture_rect(NAME, Rect2(name_at, name_size), false, washi)
		var sub_height := thick * 0.42
		var sub_size := Vector2(SUBTITLE.get_width(), SUBTITLE.get_height()) * (sub_height / SUBTITLE.get_height())
		draw_texture_rect(SUBTITLE, Rect2(Vector2(name_at.x + thick * 0.08, middle.y + thick * 0.62), sub_size),
				false, Color(0.75, 0.75, 0.82, _words * 0.85))
	# The seal: pressed down onto the end of the stroke at a slight tilt,
	# landing from a little above (bigger, fainter) and settling.
	if _seal > 0.0:
		var side := thick * 1.25 * lerpf(1.35, 1.0, _seal)
		var at := Vector2(left + length + thick * 0.55, middle.y - thick * 0.15)
		draw_set_transform(at, deg_to_rad(-5.0), Vector2.ONE)
		draw_texture_rect(SEAL, Rect2(Vector2(-side, -side) * 0.5 + Vector2(3, 4), Vector2(side, side)), false, Color(0.0, 0.0, 0.03, 0.45 * _seal))
		draw_texture_rect(SEAL, Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side)), false, Color(1.0, 1.0, 1.0, _seal))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
