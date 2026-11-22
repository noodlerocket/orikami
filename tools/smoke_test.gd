extends SceneTree
## Automated check that the basics still work. It plays the game with fake
## button presses and prints PASS/FAIL lines. Run it with:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/smoke_test.gd

var _failures := 0


func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred(main)


func _run(main: Node) -> void:
	var ronin: Ronin = main.get_node("Ronin")
	await _frames(40)
	_check("lands on the ground", ronin.is_on_floor() and absf(ronin.position.y) < 0.1)
	_check("stays on the gameplay plane", ronin.position.z == 0.0)

	# Run right for half a second.
	var start_x := ronin.position.x
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check("runs right (moved %.2f m)" % (ronin.position.x - start_x), ronin.position.x - start_x > 3.0)
	await _frames(20)

	# Full jump versus a short tap.
	var camera: Camera3D = main.get_node("Camera")
	var camera_before := camera.position.y
	var full := await _jump_height(ronin, 40)
	await _frames(90)
	_check("the camera settles back to its level after a jump (%.3f m off)" % absf(camera.position.y - camera_before), absf(camera.position.y - camera_before) < 0.03)
	# High up (on a platform, say), his middle is kept at or below the
	# middle of the screen.
	ronin.position = Vector3(8.0, 3.7, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(90)
	await process_frame
	var screen_y := camera.unproject_position(ronin.global_position + Vector3(0.0, 0.8, 0.0)).y
	var middle := camera.get_viewport().get_visible_rect().size.y * 0.5
	_check("high up, he stays at or below the middle of the screen (%.0f px from the middle)" % (screen_y - middle), screen_y >= middle - 4.0)
	ronin.position = Vector3(2.0, 0.5, 0.0)
	await _frames(60)
	var tap := await _jump_height(ronin, 3)
	_check("full jump %.2f m is higher than tap jump %.2f m" % [full, tap], full > 1.8 and tap < full * 0.75)

	# Dash.
	start_x = ronin.position.x
	Input.action_press("dash")
	await _frames(2)
	Input.action_release("dash")
	await _frames(12)
	_check("dash covers ground (%.2f m)" % (ronin.position.x - start_x), ronin.position.x - start_x > 2.5)
	await _frames(30)

	# Three side slashes kill a husk.
	var husks := main.get_node("Village").get_children().filter(func(n: Node) -> bool: return n is PaperHusk)
	_check("level has enemies", husks.size() >= 3)
	var husk: PaperHusk = husks[0]
	for i in 3:
		if not is_instance_valid(husk) or husk.is_queued_for_deletion():
			break
		ronin.position = husk.position + Vector3(-1.3, 0.0, 0.0)
		ronin.velocity = Vector3.ZERO
		ronin.facing = 1.0
		ronin.set("_invulnerable", 5.0)
		await _frames(2)
		Input.action_press("slash")
		await _frames(2)
		Input.action_release("slash")
		await _frames(30)
	await _frames(5)
	_check("husk dies after 3 hits", not is_instance_valid(husk))
	_check("hits give ink (%d)" % ronin.ink, ronin.ink == 3)
	_check("ink taken in is kept as marks (%d)" % ronin.ink_absorbed, ronin.ink_absorbed == 3)

	# Down-slash pogo on the second husk.
	husk = husks[1]
	ronin.position = husk.position + Vector3(0.0, 1.7, 0.0)
	ronin.velocity = Vector3.ZERO
	Input.action_press("aim_down")
	await _frames(3)  # Give the game a moment to notice he is airborne.
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	Input.action_release("aim_down")
	var best := -99.0
	for i in 10:
		await _frames(1)
		best = maxf(best, ronin.velocity.y)
	_check("pogo bounces upward (%.1f m/s)" % best, best > 6.0)

	# Touching a husk hurts.
	ronin.set("_invulnerable", 0.0)
	husk = husks[2]
	ronin.position = husk.position
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	_check("touching an enemy costs health (%d/%d)" % [ronin.health, ronin.max_health], ronin.health == ronin.max_health - 1)
	_check("the husk shoves when touching hurts him (%s)" % husk.mode, husk.mode == &"shove")

	# The husk's swipe, and the parry.
	husk = husks[2]
	await _face_off(ronin, husk)
	var before := ronin.health
	await _frames(70)
	_check("an unparried swipe costs health (%d -> %d)" % [before, ronin.health], ronin.health < before)

	await _face_off(ronin, husk)
	before = ronin.health
	await _parry_next_swipe(ronin, husk)
	_check("a timed parry deflects the swipe (health %d -> %d)" % [before, ronin.health], ronin.health == before)
	# No cutting in the middle of a parry.
	Input.action_press("parry")
	await _frames(2)
	Input.action_release("parry")
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	_check("no cut during a parry", ronin.get("_slash_time") <= 0.0)
	await _frames(30)
	_check("a parry costs the husk posture (%d)" % husk.posture, husk.posture == 1)

	await _face_off(ronin, husk, false)
	await _parry_next_swipe(ronin, husk)
	_check("two parries stagger the husk (%s)" % husk.mode, husk.is_staggered())

	var ink_before := ronin.ink
	ronin.position = husk.position + Vector3(-1.3, 0.0, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	await _frames(20)
	_check("one cut finishes a staggered husk", not is_instance_valid(husk))
	_check("a finishing cut gives extra ink (%d -> %d)" % [ink_before, ronin.ink], ronin.ink - ink_before == 1 + ronin.finish_ink or ronin.ink == ronin.max_ink)

	# Holding parry blocks: the first blow does no harm; the second breaks
	# the guard and stuns him.
	ronin.set("_invulnerable", 0.0)
	ronin.set("_draw_safe", 0.0)
	ronin.velocity = Vector3.ZERO
	before = ronin.health
	Input.action_press("parry")
	await _frames(20)  # past the parry window: now only a block
	ronin.receive_strike(1, ronin.global_position + Vector3(1.0, 0.0, 0.0))
	_check("holding parry blocks a blow (health %d -> %d)" % [before, ronin.health], ronin.health == before)
	ronin.receive_strike(1, ronin.global_position + Vector3(1.0, 0.0, 0.0))
	_check("the second block breaks his guard and stuns him", ronin.get("_hurt_lock") > 0.3 and ronin.health == before)
	Input.action_release("parry")
	await _frames(70)
	ronin.set("_invulnerable", 0.0)
	# The iaijutsu draw: hold the draw key, wait for the charge, let go.
	husk = husks[1]
	ronin.position = husk.position + Vector3(-2.6, 0.0, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	await _frames(2)
	ronin.set("_invulnerable", 0.0)
	var draw_from := ronin.position.x
	var ink_before_draw := ronin.ink
	Input.action_press("draw")
	await _frames(int(ronin.draw_charge_time * 60.0) + 12)
	_check("holding the draw key readies the draw", ronin.iai_ready())
	_check("holding the draw key does not cut first", ronin.get("_slash_time") <= 0.0 and ronin.ink == ink_before_draw)
	Input.action_release("draw")
	await _frames(30)
	_check("the draw carries him through (%.2f m)" % (ronin.position.x - draw_from), ronin.position.x - draw_from > 3.5)
	_check("the draw cuts down the husk in its path", not is_instance_valid(husk))

	# Letting go early does not draw.
	ronin.velocity = Vector3.ZERO
	await _frames(30)
	draw_from = ronin.position.x
	Input.action_press("draw")
	await _frames(int(ronin.draw_charge_time * 60.0 * 0.5))
	Input.action_release("draw")
	await _frames(20)
	_check("letting go before it is ready does not draw (%.2f m)" % absf(ronin.position.x - draw_from), absf(ronin.position.x - draw_from) < 0.5)

	# Walls: jumping onto a climbing wall, he clings and slides
	# slowly; jumping off it and steering back climbs it.
	var walls: Array = main.get_node("Village").CLIMB_WALLS
	var wall_left: float = walls[1][0]  # the tall one, which stands on the street
	ronin.set("_draw_safe", 30.0)
	ronin.position = Vector3(wall_left - 0.6, 6.5, 0.0)
	ronin.velocity = Vector3.ZERO
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	var slide_speed := -ronin.velocity.y
	_check("clings to a wall and slides slowly (%.1f m/s)" % slide_speed, ronin.get("_sliding") and slide_speed <= ronin.wall_slide_speed + 0.1)
	await _frames(20)
	_check("stays on the wall without holding toward it", ronin.get("_sliding"))
	var start_y := ronin.position.y
	Input.action_press("move_right")
	for hop in 4:
		Input.action_press("jump")
		await _frames(14)
		Input.action_release("jump")
		await _frames(14)
	Input.action_release("move_right")
	_check("wall jumps climb the wall (%.2f m higher)" % (ronin.position.y - start_y), ronin.position.y - start_y > 2.0)
	ronin.set("_draw_safe", 0.0)

	# Falling in the pit: the screen fades and he is back at the start.
	var spawn: Vector3 = ronin.get("_spawn_position")
	before = ronin.health
	ronin.position = Vector3(11.5, 1.0, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(150)
	_check("a fall into the pit puts him back at the start (%.1f m away)" % ronin.position.distance_to(spawn), ronin.position.distance_to(spawn) < 1.0)
	_check("a fall costs one health (%d -> %d)" % [before, ronin.health], ronin.health == before - 1 or (before == 1 and ronin.health == ronin.max_health))

	# The camera follows smoothly into and out of the courtyard (it used to
	# jump left on stepping out). Checked after the fight is set up, below.

	# The Weeping Hannya: walking into the courtyard plays her cutscene;
	# holding jump skips it, and the fight begins.
	ronin.set("_draw_safe", 0.0)
	ronin.health = ronin.max_health
	ronin.position = Vector3(47.9, 1.6, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("jump")
	await _frames(60)
	Input.action_release("jump")
	await _frames(20)
	var boss: HannyaBoss = main.get("_boss")
	_check("the courtyard starts the Hannya fight (cutscene skippable)", boss != null and boss.active)
	if boss:
		boss.set_physics_process(false)  # hold her still while each rule is checked
		boss.set_process(false)
		var bx := boss.global_position.x
		# A cut hurts her.
		var hp := boss.health
		ronin.position = Vector3(bx - 1.3, 1.6, 0.0)
		ronin.facing = 1.0
		ronin.set("_invulnerable", 0.0)
		await _frames(2)
		Input.action_press("slash")
		await _frames(2)
		Input.action_release("slash")
		await _frames(25)
		_check("a cut hurts her (%d -> %d)" % [hp, boss.health], boss.health < hp)
		# A parried slash builds her posture.
		boss.set("_facing", -1.0)
		var posture_before := boss.posture
		Input.action_press("parry")
		await _frames(2)
		Input.action_release("parry")
		boss.call("_swing_hits", boss.slash_reach, boss.slash_height, 1)
		_check("parrying her slash builds posture (%d -> %d)" % [posture_before, boss.posture], boss.posture == posture_before + 1)
		await _frames(30)
		# A blade at range: unparried it hurts, parried it builds posture.
		ronin.set("_invulnerable", 0.0)
		ronin.set("_parry_time", 0.0)
		var health_before := ronin.health
		ronin.position = Vector3(bx - 6.0, 1.6, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(5)
		boss.call("_fling_blade")
		await _frames(50)
		_check("an ink blade hurts when not parried (%d -> %d)" % [health_before, ronin.health], ronin.health < health_before)
		await _frames(70)
		ronin.set("_invulnerable", 0.0)
		ronin.position = Vector3(bx - 6.0, 1.6, 0.0)
		ronin.velocity = Vector3.ZERO
		ronin.facing = 1.0
		posture_before = boss.posture
		boss.call("_fling_blade")
		var blade_time := (6.0 - 1.0 - 0.5) / boss.blade_speed
		await _frames(int(blade_time * 60.0) - 6)
		Input.action_press("parry")
		await _frames(2)
		Input.action_release("parry")
		await _frames(20)
		_check("parrying an ink blade builds posture (%d -> %d)" % [posture_before, boss.posture], boss.posture == posture_before + 1)
		# An ink tear lands on him.
		await _frames(70)
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
		health_before = ronin.health
		var drop := InkDrop.new()
		drop.target = ronin
		main.get_node("Village").add_child(drop)
		drop.global_position = Vector3(ronin.global_position.x, boss.global_position.y, 0.0)
		await _frames(70)
		_check("an ink tear hurts him if he stands under it (%d -> %d)" % [health_before, ronin.health], ronin.health < health_before)
		# Full posture: she is broken, and a finishing cut takes a big piece.
		boss.projectile_parried(boss.max_posture)
		_check("full posture staggers her", boss.is_staggered())
		hp = boss.health
		ronin.set("_invulnerable", 5.0)
		ronin.position = Vector3(bx - 1.3, 1.6, 0.0)
		ronin.facing = 1.0
		await _frames(30)
		Input.action_press("slash")
		await _frames(2)
		Input.action_release("slash")
		await _frames(20)
		_check("a finishing cut takes %d of her health (%d -> %d)" % [boss.finish_damage, hp, boss.health], hp - boss.health == boss.finish_damage)
		# Her glide sweeps at chest height: it hits him standing, not ducking.
		await _frames(60)
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
		ronin.position = Vector3(bx - 1.0, 1.6, 0.0)
		ronin.velocity = Vector3.ZERO
		Input.action_press("aim_down")
		await _frames(10)
		var duck_before := ronin.health
		boss.set("_facing", -1.0)
		boss.set("_hit_this_swing", false)
		boss.call("_swing_hits", 0.9, boss.glide_band.y - boss.glide_band.x, 2, boss.glide_band.x)
		_check("ducking, the glide passes over him (%d -> %d)" % [duck_before, ronin.health], ronin.health == duck_before)
		Input.action_release("aim_down")
		await _frames(10)
		boss.call("_swing_hits", 0.9, boss.glide_band.y - boss.glide_band.x, 2, boss.glide_band.x)
		_check("standing, the glide hits him (%d -> %d)" % [duck_before, ronin.health], ronin.health < duck_before)
		# A whole real glide, flown over him while he ducks: no harm at all
		# (her body touching him on the way over must not count either).
		await _frames(70)
		boss.set_physics_process(true)
		boss.set_process(true)
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
		ronin.position = Vector3(bx - 2.5, 1.6, 0.0)
		ronin.velocity = Vector3.ZERO
		Input.action_press("aim_down")
		await _frames(10)
		duck_before = ronin.health
		boss.global_position.x = bx
		boss.set("_facing", -1.0)
		boss.set("_glide_target", bx - 6.0)
		boss.call("_set_mode", &"glide")
		await _frames(50)
		_check("a whole glide flies over him while he ducks (%d -> %d, she is at x %.1f, he at %.1f)" % [duck_before, ronin.health, boss.global_position.x, ronin.global_position.x],
				ronin.health == duck_before and boss.global_position.x < ronin.global_position.x)
		Input.action_release("aim_down")
		boss.set_physics_process(false)
		boss.set_process(false)
		boss.global_position.x = bx
		await _frames(70)
		# Walking into her hurts, knocks him back, and she swats.
		await _frames(30)
		boss.set_physics_process(true)
		boss.set_process(true)
		boss.call("_set_mode", &"idle")
		boss.set("_mode_time", -5.0)  # keep her from starting a move meanwhile
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
		var hurt_before := ronin.health
		ronin.position = Vector3(boss.global_position.x - 0.3, 1.6, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(6)
		_check("walking into her hurts him (%d -> %d)" % [hurt_before, ronin.health], ronin.health < hurt_before)
		_check("and she swats (%s)" % boss.get("_mode"), boss.get("_mode") == &"swat")
		# The fight seals the courtyard: walking left, he is stopped at its edge.
		_check("the fight cannot be walked out of", main.get_node("Village").get("_seal_wall") != null)
		# Walking out of the courtyard and back: the camera never jumps.
		boss.reset()
		_check("after a reset she waits at the courtyard's right end (x %.1f)" % boss.global_position.x,
				boss.global_position.x > boss.arena.y - 3.0)
		main.get_node("Village").set_arena_sealed(false)
		var cam: Camera3D = main.get_node("Camera")
		ronin.set("_draw_safe", 30.0)
		ronin.position = Vector3(50.0, 1.6, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(90)
		var biggest := 0.0
		var last_x := cam.global_position.x
		Input.action_press("move_left")
		for f in 110:
			await process_frame
			biggest = maxf(biggest, absf(cam.global_position.x - last_x))
			last_x = cam.global_position.x
		Input.action_release("move_left")
		_check("the camera glides out of the courtyard (biggest step %.2f m)" % biggest, biggest < 0.4)

	# Dying: he shreds, the screen fades, he is whole again at the start.
	ronin.set("_invulnerable", 0.0)
	ronin.set("_draw_safe", 0.0)
	ronin.health = 1
	ronin.take_damage(1, ronin.global_position + Vector3(1.0, 0.0, 0.0))
	await _frames(10)
	var puppet_rig: Node3D = ronin.get_node("Puppet").get("_rig")
	_check("dying shreds him (his body is gone)", not puppet_rig.visible)
	await _frames(200)
	_check("then he is back at the start, whole, at full health",
			puppet_rig.visible and ronin.health == ronin.max_health and ronin.global_position.distance_to(ronin.get("_spawn_position")) < 1.0)

	# After the prologue, he climbs out of the well in a cutscene; at its end
	# he stands on the street, the game camera is back, and he is playable.
	main.call("_start_in_well")
	await _frames(5)
	var climb: WellCutscene = null
	for child: Node in main.get_children():
		if child is WellCutscene:
			climb = child
	_check("the climb out of the well plays", climb != null and not ronin.is_physics_processing())
	climb.set("_time", climb.glide_at + climb.glide_time - 0.05)
	await _frames(20)
	_check("and ends with him on the street, playable (x %.1f)" % ronin.global_position.x,
			ronin.is_physics_processing() and main.get_node("Camera").current and absf(ronin.global_position.x - WellCutscene.LAND_X) < 0.5)
	# Then the tutorial cards: walking ticks off the first one.
	await _frames(5)
	var lessons: Array[Node] = main.find_children("*", "Tutorial", true, false)
	_check("the tutorial starts after the climb", not lessons.is_empty())
	_check("and starts him one point down, with ink for a heal (%d/%d, %d ink)" % [ronin.health, ronin.max_health, ronin.ink],
			ronin.health == ronin.max_health - 1 and ronin.ink >= ronin.heal_cost)
	if not lessons.is_empty():
		var tutorial: Tutorial = lessons[0]
		await _frames(40)
		Input.action_press("move_right")
		await _frames(70)
		Input.action_release("move_right")
		await _frames(120)
		_check("walking completes its first lesson (now on lesson %d)" % (int(tutorial.get("_step")) + 1), int(tutorial.get("_step")) >= 1)
		tutorial.queue_free()

	# The pause screen: Esc stops the game, Esc again starts it.
	var pause := InputEventAction.new()
	pause.action = &"pause"
	pause.pressed = true
	Input.parse_input_event(pause)
	await _frames(20)
	var x_paused := ronin.global_position.x
	Input.action_press("move_right")
	await _frames(20)
	_check("Esc pauses the game (he does not move: %.2f m)" % absf(ronin.global_position.x - x_paused),
			paused and absf(ronin.global_position.x - x_paused) < 0.01)
	Input.action_release("move_right")
	Input.parse_input_event(pause)
	await _frames(30)
	_check("Esc again carries on", not paused)
	# The volume settings change and come back.
	var music_before := Sound.music_level
	var quieter := Sound.change_level(&"music", -1)
	_check("the music volume can be turned down (%.1f -> %.1f)" % [music_before, quieter], quieter < music_before or music_before == 0.0)
	Sound.change_level(&"music", 1)

	# The title screen opens with its menu.
	main.queue_free()
	await _frames(5)
	var title: Node = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await _frames(20)
	var title_menu: TitleMenu = title.get("_menu")
	_check("the title screen opens with its menu", title_menu != null and title_menu.menu.current_page() == &"main")
	title_menu.show_menu_now()
	title_menu.menu.open_page(&"settings")
	await _frames(5)
	_check("its Settings page opens, and Esc comes back", title_menu.menu.current_page() == &"settings")
	title_menu.menu.go_back()
	_check("...to the main list", title_menu.menu.current_page() == &"main")
	title.queue_free()
	await _frames(5)
	# In the browser, Begin asks which download to take instead of starting.
	var web_menu := TitleMenu.new()
	web_menu.download_instead = true
	root.add_child(web_menu)
	await _frames(2)
	web_menu.show_menu_now()
	web_menu.menu.call("_pick")
	var offered: Array = web_menu.menu.get("_pages")[&"download"]["lines"].map(func(l: Dictionary) -> String: return l["label"])
	_check("in the browser, Begin opens the download page (%s)" % ", ".join(offered),
			web_menu.menu.current_page() == &"download" and "Windows" in offered and "Mac" in offered)
	web_menu.queue_free()
	await _frames(5)

	# The prologue plays and, at its end, hands over to the game.
	var prologue: Prologue = load("res://scenes/prologue.tscn").instantiate()
	root.add_child(prologue)
	var started := prologue.time
	await _frames(30)
	_check("the prologue plays (%.2f s in)" % prologue.time, prologue.time > started)
	var ended := [false]
	prologue.finished.connect(func() -> void: ended[0] = true)
	prologue.time = Prologue.LENGTH - 0.01
	await _frames(5)
	_check("and ends after %d s, handing over to the game" % int(Prologue.LENGTH), ended[0])
	prologue.queue_free()
	await _frames(5)

	print("SMOKE TEST: ", "ALL PASSED" if _failures == 0 else "%d FAILED" % _failures)
	Engine.time_scale = 1.0
	quit(_failures)


## Puts the Ronin just in front of the husk, the two facing each other.
func _face_off(ronin: Ronin, husk: PaperHusk, reset: bool = true) -> void:
	ronin.position = husk.position + Vector3(-1.4, 0.0, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	husk.set("_dir", -1.0)
	await _frames(1)
	if reset:
		ronin.set("_invulnerable", 0.0)
		ronin.health = ronin.max_health


## Waits for the husk's wind-up to nearly finish, then parries.
func _parry_next_swipe(ronin: Ronin, husk: PaperHusk) -> void:
	for i in 200:
		if husk.mode == &"windup" and husk.get("_mode_time") > husk.attack_windup - 0.08:
			break
		ronin.velocity.x = 0.0
		ronin.position.x = husk.position.x - 1.4
		await _frames(1)
	Input.action_press("parry")
	await _frames(2)
	Input.action_release("parry")
	await _frames(25)


func _jump_height(ronin: Ronin, hold_frames: int) -> float:
	var ground := ronin.position.y
	var peak := ground
	Input.action_press("jump")
	for i in 70:
		if i == hold_frames:
			Input.action_release("jump")
		await physics_frame
		peak = maxf(peak, ronin.position.y)
	Input.action_release("jump")
	return peak - ground


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(label: String, passed: bool) -> void:
	print("PASS  " if passed else "FAIL  ", label)
	if not passed:
		_failures += 1
