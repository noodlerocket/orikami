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
##   parry     a whole exchange with a husk, played for real: its tell, the
##             parry and clash, a second parry, the stagger, the finishing cut
##             (use --zoom=6)
##   draw      the iaijutsu draw, played for real: settling into the stance,
##             ready (an inch of blade out), the dash and the streak, the
##             streak wiped away with the sword
##   husk      close-up of the paper husk's stances: four moments of its
##             shamble, the tell, the swipe, the stagger (use --zoom=4.6)
##   climb     a real climb up the wall course, in the game camera: under the
##             gatehouse, onto the tall wall, wall jumps up to the ledge
##   wall      close-up: sliding down a wall, springing off it, and the
##             gatehouse wall you walk under (use --zoom=6)
##   pit       falling into the pit: the fade out, black, back at the start
##   marks     close-up of his permanent ink marks: blank, a little, half,
##             most, covered (use --zoom=4.6)
##   cutscene  the Hannya cutscene, 18 moments through it (times printed)
##   sneak     close-up of his creeping walk, eight moments of one stride (--zoom=4.6)
##   boss      the Hannya fight running for real (cutscene skipped), 24 moments
##   death     he dies and shreds into strips, eight moments (use --zoom=6)
##   seal      the ink wall rising at the courtyard entrance, then seen mid-jump
##   heal      a real heal, held to the end: the ensō painted on, closing,
##             dissolving (use --zoom=5)
##   iai       close-up of the stance: settling, half-way, ready, and the
##             pose he ends the draw in (use --zoom=4.6)
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
		"parry":
			sheet = await _parry()
		"draw":
			sheet = await _draw()
		"iai":
			sheet = await _iai()
		"husk":
			sheet = await _husk()
		"climb":
			sheet = await _climb()
		"wall":
			sheet = await _wall()
		"pit":
			sheet = await _pit()
		"marks":
			sheet = await _marks()
		"cutscene":
			sheet = await _cutscene()
		"sneak":
			sheet = await _sneak()
		"boss":
			sheet = await _boss()
		"death":
			sheet = await _death()
		"seal":
			sheet = await _seal()
		"heal":
			sheet = await _heal()
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


## A real exchange (the game is NOT paused): the husk rears back and swipes,
## the Ronin parries just before it lands, twice, then cuts it while it is
## staggered. Rows: the tell | first parry, 25 ms apart | the stagger | the
## finishing cut.
func _parry() -> Image:
	var husk: PaperHusk = null
	for node: Node in _main.get_node("Village").get_children():
		if node is PaperHusk:
			husk = node
			break
	var tile := Vector2i(400, 280)
	var columns := 8
	var sheet := Image.create(tile.x * columns, tile.y * 4, false, Image.FORMAT_RGB8)
	var crop := Rect2i(400, 100, 800, 560)
	var hold := func() -> void:
		_ronin.position.x = husk.position.x - 1.35
		_ronin.velocity.x = 0.0
		_ronin.facing = 1.0
	_ronin.position = husk.position + Vector3(-1.35, 0.0, 0.0)
	husk.set("_dir", -1.0)
	_main.get_node("Camera").snap_to_target()
	await create_timer(0.3).timeout
	var row := 0
	for exchange in 2:
		# Wait for a fresh wind-up to begin, keeping him in place.
		while husk.mode == &"windup" and exchange == 0:
			hold.call()
			await physics_frame
		while husk.mode != &"windup":
			hold.call()
			await physics_frame
		if exchange == 0:
			for col in columns:
				var piece := await _snap(crop, tile)
				sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(col * tile.x, 0))
				print("tell  %d ms into the wind-up" % roundi(husk.get("_mode_time") * 1000.0))
				if husk.get("_mode_time") > husk.attack_windup - 0.12:
					break
				await create_timer(husk.attack_windup / 7.0).timeout
				hold.call()
		while husk.get("_mode_time") < husk.attack_windup - 0.06:
			hold.call()
			await physics_frame
		Input.action_press("parry")
		await physics_frame
		Input.action_release("parry")
		if exchange == 0:
			var started := Time.get_ticks_msec()
			for col in columns:
				var piece := await _snap(crop, tile)
				sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(col * tile.x, tile.y))
				print("parry %d ms after the press, husk %s" % [Time.get_ticks_msec() - started, husk.mode])
				await create_timer(0.025, true, false, true).timeout
	# The stagger.
	for col in 4:
		var piece := await _snap(crop, tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(col * tile.x, tile.y * 2))
		print("stagger: ", husk.mode)
		await create_timer(0.12).timeout
	# The finishing cut.
	_ronin.position.x = husk.position.x - 1.3
	Input.action_press("slash")
	await physics_frame
	Input.action_release("slash")
	for col in columns:
		var piece := await _snap(crop, tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(col * tile.x, tile.y * 3))
		await create_timer(0.05).timeout
	print("husk gone: ", not is_instance_valid(husk))
	return sheet


## The iaijutsu draw, played for real with the cut button held and let go.
## Two columns, read left to right then down; the times are printed.
func _draw() -> Image:
	_main.get_node("Camera").snap_to_target()
	await create_timer(0.6).timeout
	var tile := Vector2i(640, 260)
	var count := 12
	var sheet := Image.create(tile.x * 2, tile.y * (count / 2), false, Image.FORMAT_RGB8)
	var crop := Rect2i(160, 250, 960, 390)
	var shots := 0
	var started := Time.get_ticks_msec()
	Input.action_press("slash")
	# Settling into the stance, then ready.
	for wait: float in [0.36, 0.2, 0.3, 0.25]:
		await create_timer(wait, true, false, true).timeout
		var piece := await _snap(crop, tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((shots % 2) * tile.x, (shots / 2) * tile.y))
		print("%d ms: %s, ready %s" % [Time.get_ticks_msec() - started, _puppet.state, _ronin.iai_ready()])
		shots += 1
	Input.action_release("slash")
	started = Time.get_ticks_msec()
	while shots < count:
		var piece := await _snap(crop, tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((shots % 2) * tile.x, (shots / 2) * tile.y))
		print("%d ms after letting go: %s" % [Time.get_ticks_msec() - started, _puppet.state])
		shots += 1
		await create_timer(0.045, true, false, true).timeout
	return sheet


func _iai() -> Image:
	_ronin.set_physics_process(false)
	var tile := Vector2i(400, 400)
	var sheet := Image.create(tile.x * 4, tile.y, false, Image.FORMAT_RGB8)
	var shots := [[&"iai", 0.0], [&"iai", 0.5], [&"iai", 1.0], [&"draw", 1.0]]
	for i in shots.size():
		_puppet.state = shots[i][0]
		_puppet.iai_charge = shots[i][1]
		# The ready moment is caught at once, while its gleam is showing.
		await create_timer(0.1 if i == 2 else 0.4).timeout
		var piece := await _snap(Rect2i(360, 80, 560, 560), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(i * tile.x, 0))
	return sheet


func _husk() -> Image:
	var husk: PaperHusk = null
	for node: Node in _main.get_node("Village").get_children():
		if node is PaperHusk:
			husk = node
			break
	husk.set_physics_process(false)
	husk.set_process(false)
	_ronin.set_physics_process(false)
	_ronin.position = husk.position + Vector3(-0.2, 0.0, 0.0)
	husk.set("_dir", -1.0)
	husk.get("_rig").rotation.y = PI + 0.35
	_ronin.visible = false
	_ronin.position = husk.position
	_main.get_node("Camera").snap_to_target()
	var shots := [[&"patrol", 0.0], [&"patrol", 0.25], [&"patrol", 0.5], [&"patrol", 0.75],
			[&"windup", 0.25], [&"windup", 0.55], [&"strike", 0.0], [&"stagger", 0.0]]
	var tile := Vector2i(400, 400)
	var sheet := Image.create(tile.x * 4, tile.y * 2, false, Image.FORMAT_RGB8)
	await create_timer(0.5).timeout
	for i in shots.size():
		husk.mode = shots[i][0]
		husk.set("_mode_time", shots[i][1])
		husk.set("_stride", shots[i][1])
		husk.set("_seal_show", 1.0 if husk.mode == &"stagger" else 0.0)
		husk.call("_pose_model")
		husk.call("_process", 0.0)
		var piece := await _snap(Rect2i(360, 80, 560, 560), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % 4) * tile.x, (i / 4) * tile.y))
	return sheet


func _climb() -> Image:
	_ronin.position = Vector3(36.6, 1.6, 0.0)
	_ronin.set("_draw_safe", 60.0)
	_main.get_node("Camera").snap_to_target()
	await create_timer(0.5).timeout
	var tile := Vector2i(320, 180)
	var columns := 6
	var count := 24
	var sheet := Image.create(tile.x * columns, tile.y * (count / columns), false, Image.FORMAT_RGB8)
	Input.action_press("move_right")
	var started := Time.get_ticks_msec()
	var next_jump := 0.9
	var shot := 0
	var next_shot := 0.0
	while shot < count:
		var t := (Time.get_ticks_msec() - started) / 1000.0
		if t >= next_jump:
			Input.action_press("jump")
			await create_timer(0.22).timeout
			Input.action_release("jump")
			next_jump = t + 0.5
		if t >= next_shot:
			var piece := await _snap(Rect2i(0, 0, 1280, 720), tile)
			sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((shot % columns) * tile.x, (shot / columns) * tile.y))
			print("%.2f s: x %.1f  y %.1f  %s" % [t, _ronin.position.x, _ronin.position.y, _puppet.state])
			shot += 1
			next_shot = t + 0.22
		await process_frame
	Input.action_release("move_right")
	return sheet


func _wall() -> Image:
	var tile := Vector2i(400, 400)
	var sheet := Image.create(tile.x * 5, tile.y, false, Image.FORMAT_RGB8)
	var walls: Array = _main.get_node("Village").CLIMB_WALLS
	var tall: Array = walls[1]
	# Sliding down the tall wall's left face, then springing off it.
	_ronin.set("_draw_safe", 60.0)
	for i in 2:
		_ronin.set_physics_process(true)
		_ronin.position = Vector3(tall[0] - 0.4, 6.0, 0.0)
		_ronin.velocity = Vector3.ZERO
		Input.action_press("move_right")
		await create_timer(0.35).timeout
		Input.action_release("move_right")
		await create_timer(0.25 + i * 0.3).timeout
		_main.get_node("Camera").snap_to_target()
		await create_timer(0.03).timeout
		var piece := await _snap(Rect2i(360, 80, 560, 560), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(i * tile.x, 0))
	Input.action_press("move_right")
	Input.action_press("jump")
	await create_timer(0.09).timeout
	_main.get_node("Camera").snap_to_target()
	var jumped := await _snap(Rect2i(360, 80, 560, 560), tile)
	sheet.blit_rect(jumped, Rect2i(Vector2i.ZERO, tile), Vector2i(2 * tile.x, 0))
	Input.action_release("jump")
	Input.action_release("move_right")
	# The gatehouse: standing under the first wall.
	var first: Array = walls[0]
	_ronin.position = Vector3((first[0] + first[1]) * 0.5, 1.6, 0.0)
	_ronin.velocity = Vector3.ZERO
	await create_timer(0.6).timeout
	_main.get_node("Camera").snap_to_target()
	await create_timer(0.03).timeout
	var gate := await _snap(Rect2i(240, 0, 800, 800), tile)
	sheet.blit_rect(gate, Rect2i(Vector2i.ZERO, tile), Vector2i(3 * tile.x, 0))
	# Standing on top of the first wall's roof.
	_ronin.position = Vector3((first[0] + first[1]) * 0.5, first[2] + 2.0, 0.0)
	_ronin.velocity = Vector3.ZERO
	await create_timer(0.8).timeout
	_main.get_node("Camera").snap_to_target()
	await create_timer(0.03).timeout
	print("standing on the roof at y %.2f (ridge at %.2f)" % [_ronin.position.y, first[2] + 0.62])
	var roof := await _snap(Rect2i(360, 80, 560, 560), tile)
	sheet.blit_rect(roof, Rect2i(Vector2i.ZERO, tile), Vector2i(4 * tile.x, 0))
	return sheet


func _pit() -> Image:
	_ronin.position = Vector3(9.4, 0.0, 0.0)
	_main.get_node("Camera").snap_to_target()
	await create_timer(0.4).timeout
	var tile := Vector2i(427, 240)
	var sheet := Image.create(tile.x * 3, tile.y * 2, false, Image.FORMAT_RGB8)
	Input.action_press("move_right")
	var started := Time.get_ticks_msec()
	var times := [0.25, 0.55, 0.75, 1.05, 1.45, 2.0]
	for i in times.size():
		while (Time.get_ticks_msec() - started) / 1000.0 < times[i]:
			await process_frame
		if i == 1:
			Input.action_release("move_right")
		var piece := await _snap(Rect2i(0, 0, 1280, 720), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % 3) * tile.x, (i / 3) * tile.y))
		print("%.2f s: x %.1f y %.1f" % [times[i], _ronin.position.x, _ronin.position.y])
	return sheet


func _marks() -> Image:
	_ronin.set_physics_process(false)
	_puppet.state = &"idle"
	var levels := [0.0, 0.15, 0.4, 0.7, 1.0]
	var tile := Vector2i(360, 400)
	var sheet := Image.create(tile.x * levels.size(), tile.y, false, Image.FORMAT_RGB8)
	for i in levels.size():
		_puppet.set_marks_now(levels[i])
		await create_timer(0.25).timeout
		var piece := await _snap(Rect2i(388, 80, 504, 560), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(i * tile.x, 0))
	return sheet


func _cutscene() -> Image:
	_ronin.position = Vector3(45.0, 1.6, 0.0)
	await create_timer(0.3).timeout
	_main.play_hannya_cutscene()
	var scene: Node = null
	for child: Node in _main.get_children():
		if child is HannyaCutscene:
			scene = child
	var times := [1.0, 3.6, 6.4, 8.8, 12.0, 16.2, 18.6, 21.0, 23.4, 26.6, 28.25, 29.6, 31.4, 33.8, 35.2, 36.6, 38.2, 39.4]
	var tile := Vector2i(427, 240)
	var columns := 6
	var sheet := Image.create(tile.x * columns, tile.y * 3, false, Image.FORMAT_RGB8)
	for i in times.size():
		while is_instance_valid(scene) and scene.get("_time") < times[i]:
			await process_frame
		var piece := await _snap(Rect2i(0, 0, 1280, 720), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % columns) * tile.x, (i / columns) * tile.y))
		print("%.1f s" % (scene.get("_time") if is_instance_valid(scene) else -1.0))
	return sheet


func _sneak() -> Image:
	_ronin.set_physics_process(false)
	_puppet.strides_per_second = 1.15
	_puppet.state = &"sneak"
	var tile := Vector2i(320, 360)
	var sheet := Image.create(tile.x * 8, tile.y, false, Image.FORMAT_RGB8)
	await create_timer(0.5).timeout
	for i in 8:
		var piece := await _snap(Rect2i(400, 100, 480, 540), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i(i * tile.x, 0))
		await create_timer(1.0 / 1.15 / 8.0).timeout
	return sheet


func _boss() -> Image:
	_ronin.position = Vector3(45.0, 1.6, 0.0)
	await create_timer(0.3).timeout
	_main.play_hannya_cutscene()
	await process_frame
	for child: Node in _main.get_children():
		if child is HannyaCutscene:
			child.call("_skip")
	await create_timer(0.3).timeout
	var boss: HannyaBoss = _main.get("_boss")
	_ronin.global_position = Vector3(51.5, 1.6, 0.0)
	_ronin.set("_draw_safe", 999.0)
	var tile := Vector2i(427, 240)
	var columns := 6
	var sheet := Image.create(tile.x * columns, tile.y * 4, false, Image.FORMAT_RGB8)
	# Her moves in a set order, so each shows up: a slash at once, the ink
	# rain at 3 s, broken posture (a stagger) at 7.5 s.
	_ronin.global_position.x = boss.global_position.x - 2.2
	boss.call("_set_mode", &"slash_tell")
	var order: Dictionary = {}
	var gap := 0.35
	var mode_arg: String = OS.get_cmdline_user_args()[2] if OS.get_cmdline_user_args().size() > 2 else ""
	if mode_arg == "glide" or mode_arg == "duck":
		# The glide, close together: the tell, then the flight ("duck": with
		# him ducking under it).
		_ronin.global_position.x = boss.global_position.x - 5.0
		if mode_arg == "duck":
			Input.action_press("aim_down")
		boss.call("_start_glide")
		gap = 0.12
	elif mode_arg == "step":
		# The ink step, close together: sinking, gone, rising behind him.
		boss.call("_set_mode", &"vanish_tell")
		gap = 0.09
	elif mode_arg == "new":
		# The supernatural moves: blades at once, vanishing step at 3.5 s,
		# masks (at half health) at 6 s.
		boss.call("_set_mode", &"volley_tell")
		order = {10: &"vanish_tell", 17: &"masks"}
	else:
		order = {8: &"rain", 20: &"stagger"}
	for i in 24:
		await create_timer(gap).timeout
		if order.has(i):
			match order[i]:
				&"rain":
					boss.set("_rain_left", 9)
					boss.call("_set_mode", &"rain")
				&"masks":
					boss.health = boss.max_health / 2
					boss.call("_summon_masks")
				_:
					boss.call("_set_mode", order[i])
		var piece := await _snap(Rect2i(0, 0, 1280, 720), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % columns) * tile.x, (i / columns) * tile.y))
		print("%d: %s" % [i, boss.get("_mode")])
		# A few moments also saved full size, beside the sheet.
		if i in [1, 4, 12, 14, 19, 21]:
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[1].get_basename() + "_%d.png" % i)
	return sheet


func _death() -> Image:
	await create_timer(0.4).timeout
	var tile := Vector2i(400, 300)
	var sheet := Image.create(tile.x * 4, tile.y * 2, false, Image.FORMAT_RGB8)
	_ronin.set("_invulnerable", 0.0)
	_ronin.health = 1
	_ronin.take_damage(1, _ronin.global_position + Vector3(1.0, 0.0, 0.0))
	for i in 8:
		var piece := await _snap(Rect2i(240, 60, 800, 600), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % 4) * tile.x, (i / 4) * tile.y))
		await create_timer(0.13).timeout
	return sheet


func _seal() -> Image:
	_ronin.position = Vector3(45.0, 1.6, 0.0)
	await create_timer(0.3).timeout
	_main.play_hannya_cutscene()
	await process_frame
	for child: Node in _main.get_children():
		if child is HannyaCutscene:
			child.call("_skip")
	(_main.get("_boss") as HannyaBoss).set_physics_process(false)
	_ronin.global_position = Vector3(48.6, 1.6, 0.0)
	_ronin.set("_draw_safe", 99.0)
	var tile := Vector2i(427, 240)
	var sheet := Image.create(tile.x * 4, tile.y * 2, false, Image.FORMAT_RGB8)
	for i in 8:
		if i == 6:
			Input.action_press("jump")
			await create_timer(0.3).timeout
			Input.action_release("jump")
		else:
			await create_timer(0.16).timeout
		var piece := await _snap(Rect2i(0, 0, 1280, 720), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % 4) * tile.x, (i / 4) * tile.y))
	return sheet


func _heal() -> Image:
	await create_timer(0.4).timeout
	_ronin.ink = _ronin.max_ink
	_ronin.health = 2
	var tile := Vector2i(320, 320)
	var sheet := Image.create(tile.x * 5, tile.y * 2, false, Image.FORMAT_RGB8)
	Input.action_press("heal")
	for i in 10:
		await create_timer(0.11).timeout
		var piece := await _snap(Rect2i(340, 60, 600, 600), tile)
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, tile), Vector2i((i % 5) * tile.x, (i / 5) * tile.y))
		print("%d: health %d" % [i, _ronin.health])
	Input.action_release("heal")
	return sheet
