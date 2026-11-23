class_name LoadingScreen
extends CanvasLayer
## The loading screen (Julian: "a very well-made loading screen" whenever
## the game loads into the world: after the prologue, or Continue).
## Sumi black with a warm glow at its heart; a pale ensō brushed round 折神
## as the world loads, its tail splitting into dry bristles; when all is
## ready the vermilion 折神 seal is stamped beside it; flecks of paper drift
## up; a line of advice or lore at the bottom, a new one each time.
##
## It loads the scene in the background, changes to it, then holds (the game
## paused underneath) until the world is built and has drawn its first
## frames, so nothing hitches behind it; then it fades away.
## Use: LoadingScreen.go(get_tree(), "res://scenes/main.tscn").

const SEAL := preload("res://textures/seal_orikami.png")
const WASHI := Color(0.9, 0.87, 0.8)
const VERMILION := Color(0.72, 0.18, 0.13)
const HINTS := [
	"Parry just as a blow lands: a gold clash, and their posture begins to break.",
	"Hold the draw, then let go: the iaijutsu cut passes through everything in its path.",
	"A staggered foe, its seal stamped on it, falls to a single finishing cut.",
	"Three drops of ink buy back one stroke of health. Kneel, and let the ensō close.",
	"Cut down onto lanterns, kites and birds in the air to spring off them.",
	"Duck beneath what sweeps at chest height.",
	"Rest at a shrine. When you fall, you wake at the last one you rested at.",
	"Where you fall, your ink remains. Cut the Smudge to take it back.",
	"Every drop of ink you take in stays on your paper. Healing does not wash it off.",
	"Paper cranes hide in high and hidden places. A thousand are said to grant a wish.",
	"Kamiyo was folded from a single sacred sheet.",
	"The Rain makes ink bleed. The soaked forget their creases, and then themselves.",
	"The Rain cannot erase what was never written.",
	"Once the crane has taught you, hold jump in the air to glide.",
]

## At least this long on screen (seconds), so it never just flashes.
@export var least_time := 2.6
## How long it takes to fade away at the end.
@export var fade_time := 0.8
## Frames the new world draws, paused, behind the screen before it lifts.
@export var settle_frames := 20

var _path := ""
var _canvas: Control
var _time := 0.0
var _progress := 0.0     # the ensō drawn (0 to 1)
var _target := 0.0
var _state := &"loading"
var _frames := 0
var _alpha := 1.0
var _seal := 0.0
var _seal_time := -1.0
var _hint := ""
var _glow: GradientTexture2D
var _rng := RandomNumberGenerator.new()
var _flecks: Array[Vector4] = []   # x, start y, speed, size
var _bristles: Array[Vector3] = [] # offset, width, where it runs dry


## Loads `path` behind the loading screen and goes there.
static func go(tree: SceneTree, path: String) -> void:
	var screen := LoadingScreen.new()
	screen._path = path
	tree.root.add_child(screen)


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_hint = HINTS[_rng.randi() % HINTS.size()]
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_screen)
	add_child(_canvas)
	_glow = GradientTexture2D.new()
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(0.16, 0.11, 0.08, 1.0))
	g.set_color(1, Color(0.16, 0.11, 0.08, 0.0))
	_glow.gradient = g
	for k in 28:
		_flecks.append(Vector4(_rng.randf(), _rng.randf(), _rng.randf_range(0.012, 0.035), _rng.randf_range(2.0, 5.0)))
	for k in 11:
		var off := (k - 5.0) / 5.0
		_bristles.append(Vector3(off, _rng.randf_range(0.35, 1.0), _rng.randf_range(0.82, 1.0) if absf(off) > 0.3 else 1.0))
	if _path != "":
		ResourceLoader.load_threaded_request(_path)


func _process(delta: float) -> void:
	_time += delta
	match _state:
		&"loading":
			var amount := []
			var status := ResourceLoader.load_threaded_get_status(_path, amount)
			if not amount.is_empty():
				_target = 0.7 * float(amount[0])
			if status == ResourceLoader.THREAD_LOAD_LOADED and _time > 0.8 and _progress > 0.6:
				var scene := ResourceLoader.load_threaded_get(_path) as PackedScene
				get_tree().change_scene_to_packed(scene)
				_state = &"building"
				_target = 0.82
			elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				get_tree().change_scene_to_file(_path)
				_state = &"building"
		&"building":
			# The new world is built; hold it still behind us while it
			# draws its first frames (its materials get ready unseen).
			var scene := get_tree().current_scene
			if scene and scene.is_node_ready() and scene.scene_file_path == _path:
				get_tree().paused = true
				_frames += 1
				_target = lerpf(0.82, 1.0, clampf(float(_frames) / settle_frames, 0.0, 1.0))
				if _frames >= settle_frames and _progress >= 0.995 and _time > least_time:
					if _seal_time < 0.0:
						_seal_time = _time
					if _time - _seal_time > 0.55:
						_state = &"fading"
						get_tree().paused = false
		&"fading":
			_alpha -= delta / fade_time
			if _alpha <= 0.0:
				queue_free()
				return
	_progress = move_toward(_progress, _target, delta * 0.85)
	if _seal_time >= 0.0:
		_seal = clampf((_time - _seal_time) / 0.14, 0.0, 1.0)
	_canvas.queue_redraw()


func _draw_screen() -> void:
	var view := _canvas.size
	var a := clampf(_alpha, 0.0, 1.0)
	var fade_in := clampf(_time / 0.5, 0.0, 1.0)
	_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(0.03, 0.028, 0.038, a))
	var h := view.y
	var centre := Vector2(view.x * 0.5, h * 0.44)
	var glow := h * 0.75
	_canvas.draw_texture_rect(_glow, Rect2(centre - Vector2(glow, glow), Vector2(glow, glow) * 2.0), false, Color(1, 1, 1, a * fade_in))
	# Paper flecks drifting up.
	for f: Vector4 in _flecks:
		var y := fposmod(f.y - _time * f.z, 1.0)
		var x := f.x + 0.01 * sin(_time * 0.7 + f.y * 20.0)
		var tw := 0.25 + 0.2 * sin(_time * 1.3 + f.x * 30.0)
		_canvas.draw_set_transform(Vector2(x * view.x, y * h), _time * 0.4 + f.x * 9.0, Vector2.ONE)
		_canvas.draw_rect(Rect2(Vector2(-f.w, -f.w * 0.6), Vector2(f.w * 2.0, f.w * 1.2)), Color(WASHI, tw * a * fade_in))
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The ensō, brushed clockwise from the lower left; thick where the
	# brush lands, its tail splitting into dry bristles.
	var radius := h * 0.17
	var width := h * 0.032
	var start := deg_to_rad(115.0)
	var sweep := deg_to_rad(330.0)
	var steps := 96
	# A solid body of ink first (its width lifting as the brush goes) ...
	var prev := Vector2.INF
	var prev_w := 0.0
	for i in steps + 1:
		var t := float(i) / steps
		if t > _progress:
			break
		var angle := start + sweep * t
		var p := centre + Vector2(cos(angle), sin(angle)) * (radius + 0.004 * h * sin(t * 7.0))
		var w := width * (1.0 - 0.6 * t) * (0.55 + 0.45 * smoothstep(0.0, 0.05, t))
		if prev != Vector2.INF:
			var n := (p - prev).orthogonal().normalized()
			var ink := Color(WASHI, a * fade_in * (1.0 - 0.75 * smoothstep(0.78, 1.0, t)))
			_canvas.draw_primitive(PackedVector2Array([prev + n * prev_w * 0.5, p + n * w * 0.5, p - n * w * 0.5, prev - n * prev_w * 0.5]),
					PackedColorArray([ink, ink, ink, ink]), PackedVector2Array())
			_canvas.draw_circle(p, w * 0.5, ink)
		prev = p
		prev_w = w
	# ... then bristle streaks over it: darker grooves where the brush ran
	# dry, wisps carrying on past the body at the tail.
	for b: Vector3 in _bristles:
		var reach := minf(_progress, b.z)
		var points := PackedVector2Array()
		var colours := PackedColorArray()
		for i in steps + 1:
			var t := float(i) / steps
			if t > reach:
				break
			var angle := start + sweep * t
			var r := radius + b.x * width * 0.42 * (1.0 - 0.6 * t)
			points.append(centre + Vector2(cos(angle), sin(angle)) * r)
			var dry := smoothstep(0.45, 0.95, t)
			colours.append(Color(0.03, 0.028, 0.038, a * fade_in * dry * 0.55 * (1.0 - b.y * 0.5)))
		if points.size() > 1:
			_canvas.draw_polyline_colors(points, colours, maxf(1.0, width * 0.07), true)
	# The brush tip while it is still moving.
	if _progress < 0.99:
		var angle := start + sweep * _progress
		var tip := centre + Vector2(cos(angle), sin(angle)) * radius
		_canvas.draw_circle(tip, width * 0.35 * (1.0 - 0.5 * _progress), Color(WASHI, 0.8 * a * fade_in))
	# 折神 in the middle.
	var size := int(h * 0.1)
	var word := "折神"
	var ww := UiStyle.width(word, size)
	UiStyle.text(_canvas, centre + Vector2(-ww * 0.5, size * 0.36), word, size, Color(WASHI, 0.9 * a * fade_in))
	# The seal, stamped when the world is ready.
	if _seal > 0.0:
		var side := h * 0.085 * lerpf(1.4, 1.0, _seal)
		var at := centre + Vector2(radius * 0.98, radius * 0.72)
		_canvas.draw_set_transform(at, deg_to_rad(-6.0), Vector2.ONE)
		_canvas.draw_texture_rect(SEAL, Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side)), false, Color(1, 1, 1, _seal * a))
		_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The line of advice or lore, and a quiet word that it is loading.
	var hint_size := int(h * 0.03)
	var hw := UiStyle.width(_hint, hint_size)
	UiStyle.marker(_canvas, Vector2(view.x * 0.5, h * 0.785), h * 0.012, a * fade_in)
	UiStyle.text(_canvas, Vector2((view.x - hw) * 0.5, h * 0.84), _hint, hint_size, Color(WASHI, 0.78 * a * fade_in))
	var small := int(h * 0.022)
	var dots := ".".repeat(1 + int(_time * 2.0) % 3) if _state != &"fading" and _seal <= 0.0 else ""
	var label := "Folding the world" + dots if _seal <= 0.0 else "Ready"
	UiStyle.text(_canvas, Vector2(view.x - h * 0.05 - UiStyle.width("Folding the world...", small), h * 0.94), label, small,
			Color(WASHI, 0.45 * a * fade_in))
