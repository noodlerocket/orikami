extends SceneTree
## Photographs the game in a series of situations and tiles the pictures into
## one image (a "frame sheet"). This is how animation, effects and the health
## display are checked without a person watching: you cannot see motion in a
## single screenshot, but you can see it frame by frame.
##
## Run it with (note: NOT --headless, it needs a real window to draw):
##   Godot_v4.7.2-stable_win64_console.exe --path . --script tools/frame_sheet.gd -- <sheet> <C:\full\path\out.png> [--zoom=4.6]
##
## Sheets:
##   stances   idle, six run frames, dash, take-off, rising, top of jump, falling,
##             fast fall, landing, hurt, heal            (use --zoom=4.6)
##   cuts      forward, up and down cuts, ten moments each, in the game camera
##   endings   the last moments of each cut, with timings printed
##   struck    being hurt: soaked in ink, blots shrinking, clean (use --zoom=4.6)
##   hud       the health display: full, just hurt, low with a heal ready, last point
##
## The player's own script is switched off for most sheets, so the puppet can
## be put in any state directly.

## How much the game is slowed while cuts are photographed.
const SLOW := 0.4

var _main: Node
var _ronin: Ronin
var _puppet: RoninPuppet


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -- <stances|cuts|endings|struck|hud> <output.png> [--zoom=4.6]")
		quit(1)
		return
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await create_timer(1.2).timeout
	_ronin = _main.get_node("Ronin")
	_puppet = _ronin.get_node("Puppet")
	var sheet: Image
	match args[0]:
		"stances":
			sheet = await _stances()
		"cuts":
			sheet = await _cuts(10, 0.0, 0.0)
		"endings":
			sheet = await _cuts(7, 0.0, 0.14)
		"struck":
			sheet = await _struck()
		"hud":
			sheet = await _hud()
		_:
			push_error("Unknown sheet: " + args[0])
			quit(1)
			return
	sheet.save_png(args[1])
	quit()


## One picture of the middle of the screen, shrunk to a tile.
func _snap(crop: Rect2i, tile: Vector2i) -> Image:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.convert(Image.FORMAT_RGB8)
	var piece := frame.get_region(crop)
	piece.resize(tile.x, tile.y)
	return piece


func _stances() -> Image:
	_ronin.set_physics_process(false)
	# [state, vertical speed, seconds to wait first]
	var shots := [
		[&"idle", 0.0, 0.5], [&"run", 0.0, 0.3], [&"run", 0.0, 0.085], [&"run", 0.0, 0.085],
		[&"run", 0.0, 0.085], [&"run", 0.0, 0.085], [&"run", 0.0, 0.085], [&"dash", 0.0, 0.3],
		[&"jump", 13.0, 0.3], [&"jump", 6.0, 0.2], [&"jump", 0.5, 0.2], [&"fall", -4.0, 0.2],
		[&"fall", -14.0, 0.2], [&"idle", 0.0, 0.03], [&"hurt", 0.0, 0.3], [&"heal", 0.0, 0.4],
	]
	var tile := Vector2i(400, 400)
	var sheet := Image.create(tile.x * 4, tile.y * 4, false, Image.FORMAT_RGB8)
	for i in shots.size():
		_puppet.state = shots[i][0]
		_puppet.vertical_speed = shots[i][1]
		await create_timer(shots[i][2]).timeout
		var piece := await _snap(Rect2i(360, 80, 560, 560), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % 4) * tile.x, (i / 4) * tile.y))
	return sheet


## The three cuts. `gap` is the pause between pictures; `skip` is how long
## to wait after the cut starts before the first picture.
func _cuts(columns: int, gap: float, skip: float) -> Image:
	_ronin.set_physics_process(false)
	var tile := Vector2i(256, 220)
	var sheet := Image.create(tile.x * columns, tile.y * 3, false, Image.FORMAT_RGB8)
	_puppet.play_slash(Vector2(0, 1))   # a warm-up cut, not photographed
	await create_timer(0.6).timeout
	# Run the game at less than half speed while photographing, so a cut that
	# lasts a fifth of a second still gets plenty of pictures.
	Engine.time_scale = SLOW
	var cuts := [Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]
	for row in 3:
		_puppet.state = &"fall" if row == 2 else &"idle"
		_puppet.vertical_speed = -3.0 if row == 2 else 0.0
		_ronin.position.y = 1.6 if row == 2 else 0.0   # the down cut happens in the air
		await create_timer(0.45).timeout
		_puppet.play_slash(cuts[row])
		var started := Time.get_ticks_msec()
		if skip > 0.0:
			await create_timer(skip).timeout
		var times := []
		for col in columns:
			var piece := await _snap(Rect2i(430, 290 if row < 2 else 330, 420, 360), tile)
			times.append(roundi((Time.get_ticks_msec() - started) * SLOW))
			sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(col * tile.x, row * tile.y))
			if gap > 0.0:
				await create_timer(gap).timeout
		print(["forward", "up", "down"][row], " cut, pictures taken at (ms into the cut): ", times)
	Engine.time_scale = 1.0
	return sheet


func _struck() -> Image:
	_ronin.set_physics_process(false)
	_puppet.state = &"hurt"
	_puppet.blinking = true
	var tile := Vector2i(400, 400)
	var sheet := Image.create(tile.x * 3, tile.y, false, Image.FORMAT_RGB8)
	var waits := [0.12, 0.3, 0.4]
	for i in 3:
		await create_timer(waits[i]).timeout
		if i == 1:
			_puppet.state = &"idle"
		var piece := await _snap(Rect2i(360, 80, 560, 560), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(i * tile.x, 0))
	return sheet


func _hud() -> Image:
	var tile := Vector2i(360, 120)
	var sheet := Image.create(tile.x * 2, tile.y * 2, false, Image.FORMAT_RGB8)
	var strike := func() -> void:
		_ronin.set("_invulnerable", 0.0)
		_ronin.take_damage(1, _ronin.global_position + Vector3(1.0, 0.0, 0.0))
	for step in 4:
		if step == 1:      # just hurt, a little ink
			_ronin.ink = 4
			_ronin.ink_changed.emit(_ronin.ink, _ronin.max_ink)
			strike.call()
			await create_timer(0.16).timeout
		elif step == 2:    # low health, full ink
			await create_timer(0.8).timeout
			strike.call()
			strike.call()
			_ronin.ink = _ronin.max_ink
			_ronin.ink_changed.emit(_ronin.ink, _ronin.max_ink)
			await create_timer(0.7).timeout
		elif step == 3:    # last point
			strike.call()
			await create_timer(0.7).timeout
		var piece := await _snap(Rect2i(0, 0, 360, 120), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((step % 2) * tile.x, (step / 2) * tile.y))
	return sheet
