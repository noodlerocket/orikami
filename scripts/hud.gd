class_name Hud
extends Control
## The heads-up display, drawn like a scrap of the Ronin's own paper:
##
##  - a torn paper strip in the corner, with a soft shadow under it;
##  - one INK SPLAT per health point. A lost point leaves a faint dried ring.
##    When you are hurt the splat bursts into droplets; when you heal, a new
##    one blooms. On your last point the splat throbs;
##  - a BRUSH STROKE showing how much ink you carry, with small tick marks
##    at every "one heal's worth", so you can see how many heals you hold;
##  - a red SEAL that lights up when you have enough ink to heal.
##
## Everything is drawn in code in _draw(), so there are no picture files.

@export_group("Layout")
## Top-left corner of the paper strip, in pixels.
@export var corner := Vector2(18.0, 16.0)
@export var blot_spacing := 46.0
@export var blot_radius := 13.0
@export_group("Animation")
## How long a splat takes to burst when you are hurt, and to bloom when you heal.
@export var burst_time := 0.45
@export var bloom_time := 0.3
## Seconds the crane count stays up after a bundle is found.
@export var crane_tag_time := 3.5

const PAPER := Color(0.93, 0.9, 0.84)
const PAPER_EDGE := Color(0.99, 0.98, 0.95)
const INK := Color(0.07, 0.07, 0.1)
const SEAL := Color(0.84, 0.2, 0.12)

var _health := 5
var _max_health := 5
var _ink := 0
var _max_ink := 9
var _heal_cost := 3
var _clock := 0.0
var _burst := {}   # health slot -> seconds since its splat burst
var _bloom := {}   # health slot -> seconds since its splat appeared
var _sip := 0.0    # counts down after the ink meter changes, for a little swell
var _started := false


var _tag: Control           # the crane count, on its own scrap of paper
var _cranes := 0
var _tag_tween: Tween
var _tag_pulse := 0.0       # 1 when a crane has just arrived, easing to 0
## How big the crane tag is drawn (1 = its first, small size).
@export var crane_tag_scale := 1.35


## The crane count: a small paper tag under the strip, with a crane drawn
## in ink and how many have been found. It fades in when a bundle is found,
## stays a while, and fades away.
func cranes_found(total: int) -> void:
	_cranes = total
	if _tag == null:
		_tag = Control.new()
		_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tag.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tag.modulate.a = 0.0
		_tag.draw.connect(_draw_tag)
		add_child(_tag)
	_tag.queue_redraw()
	# The inked crane lifts its wings and the number swells, once per crane.
	var pulse := create_tween()
	pulse.tween_method(func(v: float) -> void:
		_tag_pulse = v
		_tag.queue_redraw(), 1.0, 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _tag_tween:
		_tag_tween.kill()
	_tag_tween = create_tween()
	_tag_tween.tween_property(_tag, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	_tag_tween.tween_interval(crane_tag_time)
	_tag_tween.tween_property(_tag, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)


func _draw_tag() -> void:
	var at := corner + Vector2(6.0, 98.0)
	_tag.draw_set_transform(at * (1.0 - crane_tag_scale), 0.0, Vector2.ONE * crane_tag_scale)
	# The scrap is as wide as what is written on it (the numbers stuck out
	# of a fixed one: Julian).
	var words := str(_cranes)
	var number_w := UiStyle.width(words, 31)
	var area := Rect2(at, Vector2(maxf(138.0, 66.0 + number_w + UiStyle.width("/ 1000", 15) + 18.0), 44.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var outline := PackedVector2Array()
	var corners := [area.position, Vector2(area.end.x, area.position.y + 3.0), area.end + Vector2(3.0, -2.0), Vector2(area.position.x - 2.0, area.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var pieces := maxi(2, int(a.distance_to(b) / 12.0))
		var out := (b - a).orthogonal().normalized()
		for k in pieces:
			outline.append(a.lerp(b, float(k) / pieces) + out * rng.randf_range(-1.8, 1.8))
	var shadow := PackedVector2Array()
	for point: Vector2 in outline:
		shadow.append(point + Vector2(3.0, 4.0))
	_tag.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.05, 0.3))
	_tag.draw_colored_polygon(outline, Color(PAPER, 0.96))
	# A crane, in ink: body, raised wings, neck and tail.
	var c := at + Vector2(30.0, 25.0)
	_tag.draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 2), c + Vector2(0, -2), c + Vector2(13, 3), c + Vector2(0, 7)]), Color(INK, 0.85))
	var lift := _tag_pulse * 6.0
	_tag.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(-11, -15 - lift), c + Vector2(3, -1)]), Color(INK, 0.7))
	_tag.draw_colored_polygon(PackedVector2Array([c + Vector2(1, -1), c + Vector2(9, -13 - lift), c + Vector2(6, 1)]), Color(INK, 0.55))
	_tag.draw_line(c + Vector2(11, 3), c + Vector2(18, -6), Color(INK, 0.85), 2.0, true)
	_tag.draw_line(c + Vector2(-12, 2), c + Vector2(-19, -3), Color(INK, 0.85), 2.0, true)
	var big := 26 + int(round(_tag_pulse * 5.0))
	_tag.draw_string(UiStyle.FONT, at + Vector2(58.0, 33.0 + _tag_pulse * 2.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(INK, 0.9))
	_tag.draw_string(UiStyle.FONT, at + Vector2(66.0 + number_w, 33.0), "/ 1000", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(INK, 0.55))
	_tag.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


var _note: Control


## "Saved": a small line of brush lettering under the strip, after resting
## at a shrine. It fades in and away.
func saved() -> void:
	if _note == null:
		_note = Control.new()
		_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_note.set_anchors_preset(Control.PRESET_FULL_RECT)
		_note.modulate.a = 0.0
		_note.draw.connect(func() -> void:
			UiStyle.text(_note, corner + Vector2(blot_spacing * _max_health + 90.0, 40.0), "Rested and saved", 20,
					Color(UiStyle.WASHI.r, UiStyle.WASHI.g, UiStyle.WASHI.b, 0.85), 1.0))
		add_child(_note)
	var t := create_tween()
	t.tween_property(_note, "modulate:a", 1.0, 0.4)
	t.tween_interval(1.8)
	t.tween_property(_note, "modulate:a", 0.0, 0.9)


## Start listening to a Ronin's health and ink.
func watch(ronin: Ronin) -> void:
	add_to_group(&"hud")
	_heal_cost = maxi(ronin.heal_cost, 1)
	ronin.health_changed.connect(_on_health_changed)
	ronin.ink_changed.connect(_on_ink_changed)
	_on_health_changed(ronin.health, ronin.max_health)
	_on_ink_changed(ronin.ink, ronin.max_ink)
	_started = true


func _on_health_changed(current: int, maximum: int) -> void:
	if _started:
		for slot in range(current, _health):   # lost points burst
			_burst[slot] = 0.0
		for slot in range(_health, current):   # gained points bloom
			_bloom[slot] = 0.0
	_health = current
	_max_health = maximum
	queue_redraw()


func _on_ink_changed(current: int, maximum: int) -> void:
	if _started and current != _ink:
		_sip = 0.25
	_ink = current
	_max_ink = maximum
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	_sip = maxf(0.0, _sip - delta)
	for slot: int in _burst.keys():
		_burst[slot] += delta
		if _burst[slot] > burst_time:
			_burst.erase(slot)
	for slot: int in _bloom.keys():
		_bloom[slot] += delta
		if _bloom[slot] > bloom_time:
			_bloom.erase(slot)
	# Only redraw while something is moving (or the last splat is throbbing).
	if not _burst.is_empty() or not _bloom.is_empty() or _sip > 0.0 or _health <= 1 or _can_heal():
		queue_redraw()


func _can_heal() -> bool:
	return _ink >= _heal_cost and _health < _max_health


func _draw() -> void:
	var width := blot_spacing * _max_health + 64.0
	var height := 84.0
	_draw_paper(Rect2(corner, Vector2(width, height)))

	# Health: one splat per point.
	for slot in _max_health:
		var center := corner + Vector2(34.0 + slot * blot_spacing, 30.0)
		if slot < _health:
			var size := 1.0
			if _bloom.has(slot):   # blooms in: starts big and settles
				size = lerpf(1.5, 1.0, ease(_bloom[slot] / bloom_time, 0.3))
			elif _health == 1:     # the last one throbs
				size = 1.0 + 0.07 * sin(_clock * 7.0)
			_draw_splat(center, slot, size, 1.0)
		else:
			_draw_stain(center, slot)
		if _burst.has(slot):
			_draw_burst(center, slot, _burst[slot] / burst_time)

	# Ink: a brush stroke that grows as you land hits.
	var left := corner.x + 22.0
	var full := width - 74.0
	var line_y := corner.y + 62.0
	draw_line(Vector2(left, line_y), Vector2(left + full, line_y), Color(INK, 0.13), 2.0, true)
	for heal in range(1, _max_ink / _heal_cost + 1):   # a tick at each heal's worth
		var x := left + full * float(heal * _heal_cost) / float(maxi(_max_ink, 1))
		draw_line(Vector2(x, line_y - 6.0), Vector2(x, line_y + 6.0), Color(INK, 0.3), 1.5, true)
	if _ink > 0:
		_draw_brush_stroke(Vector2(left, line_y), full * float(_ink) / float(maxi(_max_ink, 1)), 9.0 + _sip * 14.0)

	# The seal: red when a heal is ready, a faint grey stamp when it is not.
	var seal_at := corner + Vector2(width - 32.0, 58.0)
	_draw_seal(seal_at, _can_heal())


## The paper strip: torn edges, a paler torn rim, and a shadow beneath.
func _draw_paper(area: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var outline := PackedVector2Array()
	var corners := [area.position, Vector2(area.end.x, area.position.y - 5.0), area.end + Vector2(6.0, 2.0),
			Vector2(area.position.x - 3.0, area.end.y - 4.0)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var pieces := maxi(2, int(a.distance_to(b) / 14.0))
		var out := (b - a).orthogonal().normalized()
		for k in pieces:
			outline.append(a.lerp(b, float(k) / pieces) + out * rng.randf_range(-2.2, 2.2))
	var shadow := PackedVector2Array()
	var rim := PackedVector2Array()
	var middle := area.get_center()
	for point: Vector2 in outline:
		shadow.append(point + Vector2(4.0, 5.0))
		rim.append(point + (point - middle).normalized() * 2.2)
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.05, 0.3))
	draw_colored_polygon(rim, Color(PAPER_EDGE, 0.95))
	draw_colored_polygon(outline, Color(PAPER, 0.96))
	# A few pale fibres and one soft fold line.
	for i in 14:
		var from := area.position + Vector2(rng.randf() * area.size.x, rng.randf() * area.size.y)
		draw_line(from, from + Vector2(rng.randf_range(6.0, 22.0), rng.randf_range(-3.0, 3.0)),
				Color(0.7, 0.66, 0.58, 0.22), 1.0, true)
	draw_line(area.position + Vector2(area.size.x * 0.62, 0.0), Vector2(area.position.x + area.size.x * 0.6, area.end.y),
			Color(0.55, 0.5, 0.45, 0.12), 2.0, true)


## One splat of ink: an uneven blob with a few thrown arms and stray drops.
func _draw_splat(center: Vector2, slot: int, size: float, strength: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + slot * 31
	var tint := Color(INK, strength)
	var radius := blot_radius * size
	# A round blob with a wobbly edge, and two soft bulges where the ink ran.
	var blob := PackedVector2Array()
	var points := 36
	var bulges := [rng.randf() * TAU, rng.randf() * TAU]
	var wobble := rng.randf() * TAU
	for i in points:
		var angle := TAU * i / points
		var reach := radius * (0.97 + 0.045 * sin(angle * 5.0 + wobble) + 0.03 * sin(angle * 9.0 + wobble * 2.0))
		for bulge: float in bulges:
			var near := maxf(0.0, cos(angle - bulge))
			reach += radius * 0.34 * pow(near, 14.0)
		blob.append(center + Vector2(cos(angle), sin(angle)) * reach)
	draw_colored_polygon(blob, tint)
	for i in 6:   # stray drops
		var angle := rng.randf() * TAU
		var away := radius * rng.randf_range(1.25, 1.9)
		draw_circle(center + Vector2(cos(angle), sin(angle)) * away, rng.randf_range(1.0, 2.8) * size, tint)
	# A wet glint, so it reads as liquid rather than a flat dot.
	draw_circle(center + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.2, Color(1.0, 1.0, 1.0, 0.1 * strength))


## A lost health point: the dried ring an ink splat leaves behind.
func _draw_stain(center: Vector2, slot: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2000 + slot * 17
	draw_circle(center, blot_radius * 0.9, Color(INK, 0.05))
	var turn := rng.randf() * TAU
	draw_arc(center, blot_radius - 1.5, turn, turn + TAU * 0.62, 20, Color(INK, 0.24), 1.6, true)
	draw_arc(center, blot_radius - 1.5, turn + TAU * 0.7, turn + TAU * 0.93, 10, Color(INK, 0.15), 1.2, true)


## The moment a splat is lost: droplets fly outward and fade.
func _draw_burst(center: Vector2, slot: int, through: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3000 + slot * 13
	var fade := 1.0 - through
	_draw_splat(center, slot, 1.0 + through * 0.5, fade * fade)
	for i in 12:
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(22.0, 58.0)
		var at := center + Vector2(cos(angle), sin(angle)) * (blot_radius + speed * ease(through, 0.4))
		at.y += 26.0 * through * through   # they fall as they fly
		draw_circle(at, rng.randf_range(1.5, 3.6) * fade, Color(INK, fade))


## The ink meter: a stroke that is loaded at the start and dry at the end,
## with a few bristle streaks trailing past it.
func _draw_brush_stroke(from: Vector2, length: float, thick: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var steps := maxi(4, int(length / 9.0))
	for i in steps + 1:
		var t := float(i) / steps
		var half := thick * 0.5 * lerpf(1.0, 0.55, t) * rng.randf_range(0.88, 1.08)
		if i == 0:
			half *= 0.6   # the rounded start, where the brush touched down
		top.append(from + Vector2(length * t, -half))
		bottom.append(from + Vector2(length * t, half * 0.85))
	bottom.reverse()
	top.append_array(bottom)
	draw_colored_polygon(top, INK)
	for i in 4:   # dry bristle streaks past the end of the stroke
		var y := from.y + rng.randf_range(-thick * 0.28, thick * 0.24)
		var start := from.x + length - rng.randf_range(2.0, 8.0)
		draw_line(Vector2(start, y), Vector2(start + rng.randf_range(8.0, 20.0), y + rng.randf_range(-1.0, 1.0)),
				Color(INK, rng.randf_range(0.35, 0.7)), 1.3, true)


## A square name-seal. Vermilion is kept for things that matter: here it
## means "you can heal now".
func _draw_seal(center: Vector2, ready: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var half := 13.0 + (1.2 * sin(_clock * 5.0) if ready else 0.0)
	var tint := Color(SEAL, 0.95) if ready else Color(INK, 0.14)
	var square := PackedVector2Array()
	for side in 4:
		var a := Vector2(-half, -half).rotated(side * PI * 0.5)
		var b := Vector2(half, -half).rotated(side * PI * 0.5)
		for k in 4:
			square.append(center + (a.lerp(b, k / 4.0) + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))).rotated(-0.08))
	draw_colored_polygon(square, tint)
	# The mark carved in the seal: a folded sheet (a diamond with its crease).
	var cut := Color(PAPER, 0.95 if ready else 0.5)
	var diamond := PackedVector2Array([center + Vector2(0.0, -8.0), center + Vector2(7.0, 0.0),
			center + Vector2(0.0, 8.0), center + Vector2(-7.0, 0.0), center + Vector2(0.0, -8.0)])
	draw_polyline(diamond, cut, 1.8, true)
	draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), cut, 1.4, true)
	draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 0.0), cut, 1.4, true)
