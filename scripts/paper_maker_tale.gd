class_name PaperMakerTale
extends Control
## The Paper-Maker tells him (docs/lore.md, chapter 1): he never speaks and
## she barely does, so she shows him, in pictures. The first time he comes
## to her vat (after the tutorial), she stops, lifts a fresh sheet, and on it
## three pictures are brushed in ink, stroke by stroke, each wiped away
## before the next:
##   1. the castle on its hill, its gate barred, tears falling on it: the
##      Emperor has shut himself away, and weeps;
##   2. the village in the rain, ink running down its walls, a husk slumped
##      in a black pool: the land is dying;
##   3. a small blank figure in the rain, the drops glancing off his hat,
##      and a vermilion ensō brushed round him: the Rain cannot unmake him.
## No words. Hold Space (A) to skip. Played once (SaveGame.papermaker_told).

signal finished

## Seconds to paint one picture, to hold it, and to wipe it away.
@export var paint_time := 3.0
@export var hold_time := 1.4
@export var wipe_time := 0.7

## Only in a real game (not the automated check or a debug start), unless
## something switches it on.
static var force := false

const INK := Color(0.08, 0.07, 0.1)
const VERMILION := Color(0.72, 0.2, 0.16)

var ronin: Ronin
var maker: PaperMaker
var hud: CanvasItem

var _time := 0.0
var _pictures: Array = []   # each: Array of strokes {pts, w, fill, color}
var _done := false
var _skip: SkipPrompt
var _rng := RandomNumberGenerator.new()
var _held: Array[Node] = []   # enemies held still while she shows him


static func allowed() -> bool:
	return force or SaveGame.file == "user://save.cfg"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 2207
	_pictures = [_castle(), _village(), _blank_one()]
	_hold_enemies()
	if ronin:
		ronin.set_physics_process(false)
		ronin.velocity = Vector3.ZERO
		ronin.set("_draw_safe", 999.0)  # (nothing may hurt him while she shows him)
		var puppet: RoninPuppet = ronin.get_node("Puppet")
		puppet.state = &"idle"
		if maker:
			puppet.facing = signf(maker.global_position.x - ronin.global_position.x)
	if maker:
		maker.showing = true
	if hud:
		hud.visible = false
	Sound.duck_music(true)
	Sound.play(self, &"paper_fold")
	_skip = SkipPrompt.new()
	add_child(_skip)
	_skip.skipped.connect(_finish)


func _length() -> float:
	return 0.6 + _pictures.size() * (paint_time + hold_time + wipe_time) + 0.6


func _process(delta: float) -> void:
	if _done:
		return
	var before := _time
	_time += delta
	# A rustle of paper as each new sheet comes up.
	for k in range(1, _pictures.size()):
		var at := 0.6 + k * (paint_time + hold_time + wipe_time)
		if before < at and _time >= at:
			Sound.play(self, &"paper_fold", -6.0)
	queue_redraw()
	if _time >= _length():
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	SaveGame.papermaker_told = true
	_release_enemies()
	if ronin:
		ronin.set_physics_process(true)
		ronin.set("_draw_safe", 1.0)  # (a moment to get his bearings)
	if maker:
		maker.showing = false
	if hud:
		hud.visible = true
	Sound.duck_music(false)
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.4)
	out.tween_callback(func() -> void:
		finished.emit()
		queue_free())


## Every enemy (and anything they have thrown) holds still while she shows
## him her pictures (Julian was attacked by a husk during them).
func _hold_enemies() -> void:
	var world := get_tree().current_scene if get_tree().current_scene else get_tree().root
	if ronin:
		world = ronin.get_parent()
	for node: Node in world.find_children("*", "", true, false):
		if (node is PaperHusk or node is PaperCritter or node is BurningPaper) and node.is_physics_processing():
			node.set_physics_process(false)
			_held.append(node)


func _release_enemies() -> void:
	for node: Node in _held:
		if is_instance_valid(node):
			node.set_physics_process(true)
	_held.clear()


# --- Drawing -----------------------------------------------------------------------

func _draw() -> void:
	var length := _length()
	# The wash behind, and the sheet coming up and going down.
	var show := clampf(_time / 0.6, 0.0, 1.0) * clampf((length - _time) / 0.6, 0.0, 1.0)
	if _done:
		show = 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.45 * show))
	var h := size.y * 0.62
	var w := h * 1.45
	var unfold := smoothstep(0.0, 1.0, show)
	var centre := Vector2(size.x * 0.5, size.y * 0.48)
	var sheet := Rect2(centre - Vector2(w, h * unfold) * 0.5, Vector2(w, h * unfold))
	if unfold < 0.03:
		return
	_draw_sheet(sheet, show)
	if unfold < 0.98:
		return
	var t := _time - 0.6
	var span := paint_time + hold_time + wipe_time
	var index := int(t / span)
	if index < 0 or index >= _pictures.size():
		return
	var local := t - index * span
	var painted := clampf(local / paint_time, 0.0, 1.0)
	var wiped := clampf((local - paint_time - hold_time) / wipe_time, 0.0, 1.0)
	_draw_picture(_pictures[index], sheet, painted, wiped)


## A sheet of washi: torn edges, a soft shadow, faint fibres.
func _draw_sheet(r: Rect2, alpha: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var outline := PackedVector2Array()
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var pieces := maxi(3, int(a.distance_to(b) / 14.0))
		var out := (b - a).orthogonal().normalized()
		for k in pieces:
			outline.append(a.lerp(b, float(k) / pieces) + out * rng.randf_range(-2.5, 2.5))
	var shadow := PackedVector2Array()
	for p: Vector2 in outline:
		shadow.append(p + Vector2(8.0, 10.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.03, 0.4 * alpha))
	draw_colored_polygon(outline, Color(0.93, 0.9, 0.82, alpha))
	for k in 40:
		var y := r.position.y + rng.randf() * r.size.y
		var x := r.position.x + rng.randf() * r.size.x
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(20.0, 70.0), y + rng.randf_range(-2.0, 2.0)),
				Color(0.75, 0.72, 0.64, 0.25 * alpha), 1.0)


## One picture: its strokes appear one after another as `painted` goes 0 to
## 1 (each drawn along its length); `wiped` sweeps them away from the left.
func _draw_picture(strokes: Array, r: Rect2, painted: float, wiped: float) -> void:
	var count := strokes.size()
	var wipe_x := r.position.x - 40.0 + (r.size.x + 80.0) * wiped
	for i in count:
		var s: Dictionary = strokes[i]
		var start := float(i) / count
		var own := clampf((painted - start) * count, 0.0, 1.0)
		if own <= 0.0:
			return
		var pts: PackedVector2Array = s["pts"]
		var screen := PackedVector2Array()
		for p: Vector2 in pts:
			screen.append(r.position + Vector2(p.x * r.size.x, p.y * r.size.y))
		var colour: Color = s["color"]
		if s["fill"]:
			if own < 0.08:
				continue  # (too small yet to draw)
			var middle := Vector2.ZERO
			for p: Vector2 in screen:
				middle += p
			middle /= screen.size()
			if middle.x < wipe_x:
				continue
			# A blot soaks in: it grows from its middle.
			var grown := PackedVector2Array()
			for p: Vector2 in screen:
				grown.append(middle.lerp(p, smoothstep(0.0, 1.0, own)))
			draw_colored_polygon(grown, Color(colour, colour.a * 0.92))
			continue
		var width: float = s["w"] * r.size.y
		var segments := screen.size() - 1
		var reach := own * segments
		for k in segments:
			if k >= reach:
				break
			var a := screen[k]
			var b := screen[k + 1]
			if k + 1 > reach:
				b = a.lerp(b, reach - k)
			if (a.x + b.x) * 0.5 < wipe_x:
				continue
			# Tapered at both ends, like a brush lifting.
			var t0 := float(k) / segments
			var t1 := float(k + 1) / segments
			var w0 := width * pow(sin(PI * clampf(t0, 0.04, 0.96)), 0.45)
			var w1 := width * pow(sin(PI * clampf(t1, 0.04, 0.96)), 0.45)
			var n := (b - a).orthogonal().normalized()
			if n == Vector2.ZERO:
				continue
			# A faint bleed round the stroke, then the stroke.
			# (Drawn as plain quads: a sharp bend cannot trip up triangulation.)
			var faint := Color(colour, 0.12)
			draw_primitive(PackedVector2Array([a + n * w0 * 1.6, b + n * w1 * 1.6, b - n * w1 * 1.6, a - n * w0 * 1.6]),
					PackedColorArray([faint, faint, faint, faint]), PackedVector2Array())
			draw_primitive(PackedVector2Array([a + n * w0, b + n * w1, b - n * w1, a - n * w0]),
					PackedColorArray([colour, colour, colour, colour]), PackedVector2Array())
			# A round joint, so bends do not show gaps.
			draw_circle(b, w1 * 0.95, colour)


# --- The pictures (sheet coordinates: 0 to 1 across and down) ----------------------

func _line(pts: Array, w: float, colour: Color = INK) -> Dictionary:
	var out := PackedVector2Array()
	# A little wobble, so no line is ruled.
	for p: Vector2 in pts:
		out.append(p + Vector2(_rng.randf_range(-0.002, 0.002), _rng.randf_range(-0.003, 0.003)))
	return {"pts": out, "w": w, "fill": false, "color": colour}


func _curve(from: Vector2, mid: Vector2, to: Vector2, w: float, colour: Color = INK, steps: int = 10) -> Dictionary:
	var pts := []
	for k in steps + 1:
		var t := float(k) / steps
		pts.append(from.lerp(mid, t).lerp(mid.lerp(to, t), t))
	return _line(pts, w, colour)


func _blot(centre: Vector2, radius: Vector2, colour: Color = INK) -> Dictionary:
	var pts := PackedVector2Array()
	for k in 14:
		var a := TAU * k / 14.0
		pts.append(centre + Vector2(cos(a) * radius.x, sin(a) * radius.y) * _rng.randf_range(0.8, 1.15))
	return {"pts": pts, "w": 0.0, "fill": true, "color": colour}


## A falling tear or raindrop: round below, pointed above.
func _drop(at: Vector2, size: float, colour: Color = INK) -> Dictionary:
	var pts := PackedVector2Array([at + Vector2(0.0, -size * 1.8)])
	for k in 9:
		var a := PI * k / 8.0
		pts.append(at + Vector2(cos(a) * size * 0.7, sin(a) * size))
	return {"pts": pts, "w": 0.0, "fill": true, "color": colour}


## A curved roof: a sweeping line with its ends turned up, a ridge above.
func _roof(left: float, right: float, y: float, rise: float, w: float) -> Array:
	var mid := (left + right) * 0.5
	var out := []
	out.append(_line([Vector2(left - 0.03, y - 0.03), Vector2(left, y), Vector2(left + (mid - left) * 0.4, y + 0.004),
			Vector2(mid, y - 0.002), Vector2(right - (right - mid) * 0.4, y + 0.004), Vector2(right, y), Vector2(right + 0.03, y - 0.03)], w))
	out.append(_line([Vector2(left + 0.03, y - 0.005), Vector2(mid - 0.04, y - rise), Vector2(mid + 0.04, y - rise), Vector2(right - 0.03, y - 0.005)], w * 0.7))
	return out


## 1. The castle on its hill, gate barred shut; tears falling on it.
func _castle() -> Array:
	var s := []
	s.append(_curve(Vector2(0.04, 0.9), Vector2(0.5, 0.58), Vector2(0.96, 0.9), 0.013))
	for k in 6:
		var gx := 0.12 + k * 0.15 + _rng.randf_range(-0.03, 0.03)
		var gy := 0.9 - 0.32 * sin(PI * gx) * 0.9 + 0.02
		s.append(_line([Vector2(gx, gy), Vector2(gx + 0.012, gy - 0.025)], 0.003))
	# The stone base, sloping in.
	s.append(_line([Vector2(0.33, 0.72), Vector2(0.36, 0.6), Vector2(0.64, 0.6), Vector2(0.67, 0.72)], 0.008))
	for k in 3:
		s.append(_line([Vector2(0.35 + k * 0.005, 0.64 + k * 0.03), Vector2(0.65 - k * 0.005, 0.64 + k * 0.03)], 0.0025))
	# Three storeys, each smaller, with windows; upturned roofs.
	var y := 0.6
	for tier: Array in [[0.2, 0.09], [0.15, 0.08], [0.1, 0.07]]:
		var half: float = tier[0]
		var tall: float = tier[1]
		s.append(_line([Vector2(0.5 - half * 0.75, y), Vector2(0.5 - half * 0.75, y - tall)], 0.006))
		s.append(_line([Vector2(0.5 + half * 0.75, y), Vector2(0.5 + half * 0.75, y - tall)], 0.006))
		for k in 3:
			s.append(_blot(Vector2(0.5 - half * 0.45 + k * half * 0.45, y - tall * 0.5), Vector2(0.009, 0.013)))
		s.append_array(_roof(0.5 - half - 0.02, 0.5 + half + 0.02, y - tall, 0.04, 0.01))
		y -= tall + 0.045
	s.append(_line([Vector2(0.5, y + 0.045), Vector2(0.5, y - 0.01)], 0.006))
	# The gate in the base: shut, a heavy bar across it.
	s.append(_blot(Vector2(0.5, 0.67), Vector2(0.035, 0.045)))
	s.append(_line([Vector2(0.44, 0.665), Vector2(0.56, 0.665)], 0.011))
	# Tears falling out of the sky onto the castle (the first of the Rain).
	for k in 6:
		s.append(_drop(Vector2(0.3 + k * 0.08 + _rng.randf_range(-0.01, 0.01), 0.07 + (k % 3) * 0.04), 0.012))
	return s


## 2. The village in the rain: roofs, ink running down the walls, a husk
## slumped in a black pool.
func _village() -> Array:
	var s := []
	for house: Array in [[0.06, 0.26], [0.37, 0.24], [0.66, 0.28]]:
		var x: float = house[0]
		var w: float = house[1]
		s.append_array(_roof(x, x + w, 0.4, 0.07, 0.011))
		for k in 4:
			var tx := x + w * (0.15 + k * 0.23)
			s.append(_line([Vector2(tx, 0.395), Vector2(tx + 0.006, 0.345)], 0.003))
		s.append(_line([Vector2(x + 0.02, 0.41), Vector2(x + 0.02, 0.8)], 0.007))
		s.append(_line([Vector2(x + w - 0.02, 0.41), Vector2(x + w - 0.02, 0.8)], 0.007))
		s.append(_line([Vector2(x + w * 0.35, 0.8), Vector2(x + w * 0.35, 0.58), Vector2(x + w * 0.65, 0.58), Vector2(x + w * 0.65, 0.8)], 0.004))
		# Ink running down from the eaves, a bead at each end.
		for k in 3:
			var dx := x + w * (0.2 + k * 0.3)
			var end := 0.5 + _rng.randf() * 0.22
			s.append(_line([Vector2(dx, 0.415), Vector2(dx + 0.002, (0.415 + end) * 0.5), Vector2(dx + 0.004, end)], 0.005))
			s.append(_drop(Vector2(dx + 0.004, end + 0.012), 0.008))
	for k in 16:
		var rx := _rng.randf_range(0.03, 0.97)
		var ry := _rng.randf_range(0.03, 0.22)
		s.append(_line([Vector2(rx, ry), Vector2(rx - 0.02, ry + 0.11)], 0.0025))
	# The husk: sat slumped in a black pool, back bent, head hanging, an arm
	# trailing in the ink.
	s.append(_blot(Vector2(0.5, 0.9), Vector2(0.2, 0.035)))
	s.append(_curve(Vector2(0.45, 0.89), Vector2(0.46, 0.72), Vector2(0.55, 0.73), 0.02))
	s.append(_blot(Vector2(0.57, 0.775), Vector2(0.024, 0.03)))
	s.append(_curve(Vector2(0.52, 0.75), Vector2(0.56, 0.82), Vector2(0.6, 0.89), 0.008))
	s.append(_line([Vector2(0.45, 0.89), Vector2(0.52, 0.895), Vector2(0.56, 0.885)], 0.01))
	return s


## 3. A small blank figure in the rain; the drops glance off him; a
## vermilion ensō round him.
func _blank_one() -> Array:
	var s := []
	for k in 22:
		var rx := _rng.randf_range(0.04, 0.96)
		if absf(rx - 0.5) < 0.14:
			continue
		var ry := _rng.randf_range(0.04, 0.62)
		s.append(_line([Vector2(rx, ry), Vector2(rx - 0.02, ry + 0.13)], 0.0025))
	# Him, only in outline: the wide kasa hat, the cowl, the long robe, the
	# cloak torn into tails, the sword at his hip. Nothing filled in.
	s.append(_line([Vector2(0.425, 0.47), Vector2(0.5, 0.405), Vector2(0.575, 0.47)], 0.007))
	s.append(_line([Vector2(0.42, 0.472), Vector2(0.58, 0.472)], 0.004))
	s.append(_curve(Vector2(0.475, 0.475), Vector2(0.5, 0.5), Vector2(0.525, 0.475), 0.004))
	s.append(_line([Vector2(0.478, 0.49), Vector2(0.462, 0.6), Vector2(0.47, 0.76)], 0.005))
	s.append(_line([Vector2(0.522, 0.49), Vector2(0.53, 0.6), Vector2(0.525, 0.76)], 0.005))
	s.append(_line([Vector2(0.47, 0.76), Vector2(0.525, 0.76)], 0.004))
	s.append(_line([Vector2(0.48, 0.5), Vector2(0.44, 0.58), Vector2(0.43, 0.7), Vector2(0.44, 0.66), Vector2(0.445, 0.74), Vector2(0.452, 0.68)], 0.004))
	s.append(_line([Vector2(0.5, 0.6), Vector2(0.565, 0.57)], 0.004))
	# Drops glancing off his hat.
	for side: float in [-1.0, 1.0]:
		s.append(_curve(Vector2(0.5 + side * 0.06, 0.43), Vector2(0.5 + side * 0.1, 0.395), Vector2(0.5 + side * 0.125, 0.425), 0.003))
		s.append(_drop(Vector2(0.5 + side * 0.13, 0.44), 0.006))
	# The ensō, last, in vermilion.
	var pts := []
	for k in 30:
		var a := -PI * 0.4 + TAU * 0.93 * k / 29.0
		pts.append(Vector2(0.5 + cos(a) * 0.17, 0.58 + sin(a) * 0.17 * 1.45))
	s.append(_line(pts, 0.016, VERMILION))
	return s
