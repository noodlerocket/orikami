class_name PaperMakerTale
extends Control
## The Paper-Maker tells him (docs/lore.md, chapter 1): he never speaks and
## she barely does, so she shows him, in pictures. The first time he comes
## to her vat (after the tutorial), she stops, lifts a fresh sheet, and on it
## three pictures are brushed in ink, soaking into the sheet, each wiped
## away before the next (ink paintings made with Meshy's image generator,
## docs/reference/tale_*_source.png, prepared by tools/prepare_tale.py;
## brushed on and wiped by shaders/ink_reveal.gdshader; the first ones,
## drawn stroke by stroke in code, were not artistic enough: Julian):
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
@export var hold_time := 2.0
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
var _pictures: Array[Texture2D] = []
var _canvas: TextureRect   # the picture on the sheet (multiplied over it)
var _done := false
var _skip: SkipPrompt
var _rng := RandomNumberGenerator.new()
var _held: Array[Node] = []   # enemies held still while she shows him


static func allowed() -> bool:
	return force or SaveGame.is_real()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 2207
	_pictures = [preload("res://textures/tale_castle.jpg"), preload("res://textures/tale_village.jpg"),
			preload("res://textures/tale_blank.jpg")]
	_canvas = TextureRect.new()
	_canvas.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_canvas.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reveal := ShaderMaterial.new()
	reveal.shader = preload("res://shaders/ink_reveal.gdshader")
	_canvas.material = reveal
	_canvas.visible = false
	add_child(_canvas)
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
	if unfold < 0.98:
		_canvas.visible = false
	if unfold < 0.03:
		return
	_draw_sheet(sheet, show)
	if unfold < 0.98:
		return
	var t := _time - 0.6
	var span := paint_time + hold_time + wipe_time
	var index := int(t / span)
	if index < 0 or index >= _pictures.size():
		_canvas.visible = false
		return
	var local := t - index * span
	var painted := clampf(local / paint_time, 0.0, 1.0)
	var wiped := clampf((local - paint_time - hold_time) / wipe_time, 0.0, 1.0)
	# The picture, inside the sheet's margins.
	_canvas.texture = _pictures[index]
	_canvas.position = sheet.position + sheet.size * 0.05
	_canvas.size = sheet.size * 0.9
	var reveal := _canvas.material as ShaderMaterial
	reveal.set_shader_parameter(&"painted", smoothstep(0.0, 1.0, painted))
	reveal.set_shader_parameter(&"wiped", wiped)
	_canvas.visible = true


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
