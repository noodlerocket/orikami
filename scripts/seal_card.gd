class_name SealCard
extends Control
## A general's seal, won (Julian: "it needs to be obvious that the player
## gets the seal"): the screen dims, the seal (its hanko, textures/seal_*.png)
## is stamped down large in the middle with a jolt and a burst of vermilion
## flecks, then its name is brushed under it and how many of the Emperor's
## three seals he now holds. It stays a few seconds and fades.

## The seal's picture, its name ("The seal of Shimeri"), and the count.
var seal: Texture2D
var title := "The seal of Shimeri"
var count := 1
@export var stay := 4.2

var _age := 0.0
var _flecks: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for k in 26:
		var a := rng.randf() * TAU
		_flecks.append([Vector2(cos(a), sin(a)) * rng.randf_range(0.6, 1.0), rng.randf_range(0.004, 0.012), rng.randf_range(0.8, 1.6)])
	Sound.play(self, &"seal_stamp", 2.0)


func _process(delta: float) -> void:
	_age += delta
	if _age > stay + 0.8:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var view := size
	if view.y < 50.0:
		return
	var fade := clampf(_age / 0.3, 0.0, 1.0) * (1.0 - clampf((_age - stay) / 0.8, 0.0, 1.0))
	# The screen dims round it.
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.02, 0.04, 0.55 * fade))
	var middle := view * Vector2(0.5, 0.42)
	var side := view.y * 0.26
	# Stamped down: from large and faint to its size with a jolt.
	var u := clampf((_age - 0.15) / 0.22, 0.0, 1.0)
	var grow := lerpf(1.7, 1.0, u * u)
	var jolt := sin(clampf(_age - 0.37, 0.0, 0.3) * 60.0) * 6.0 * (1.0 - clampf((_age - 0.37) / 0.3, 0.0, 1.0)) if _age > 0.37 else 0.0
	var s := side * grow
	if seal and _age > 0.15:
		draw_texture_rect(seal, Rect2(middle - Vector2(s, s) * 0.5 + Vector2(0.0, jolt), Vector2(s, s)), false, Color(1, 1, 1, fade * minf(u * 1.5, 1.0)))
	# Vermilion flecks thrown out when it lands.
	if _age > 0.37:
		var t := _age - 0.37
		for f: Array in _flecks:
			var p: Vector2 = middle + (f[0] as Vector2) * side * (0.55 + t * (f[2] as float) * 0.8)
			var r: float = (f[1] as float) * view.y * (1.0 - clampf(t / 1.4, 0.0, 1.0))
			if r > 0.5:
				draw_circle(p, r, Color(0.72, 0.18, 0.12, 0.9 * fade))
	# Its name, then the count.
	if _age > 0.7:
		var a := clampf((_age - 0.7) / 0.5, 0.0, 1.0) * fade
		var big := int(view.y * 0.05)
		var small := int(view.y * 0.026)
		UiStyle.text(self, Vector2(middle.x - UiStyle.width(title, big) * 0.5, middle.y + side * 0.62 + big), title, big,
				Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, a))
		var line := "%d of the Emperor's three seals" % count
		UiStyle.text(self, Vector2(middle.x - UiStyle.width(line, small) * 0.5, middle.y + side * 0.62 + big + small * 1.9), line, small,
				Color(0.95, 0.55, 0.45, 0.9 * a))
