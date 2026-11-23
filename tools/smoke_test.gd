extends SceneTree
## Automated check that the basics still work. It plays the game with fake
## button presses and prints PASS/FAIL lines. Run it with:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/smoke_test.gd

var _failures := 0


func _initialize() -> void:
	SaveGame.file = "user://smoke_save.cfg"  # (never touch a real saved game)
	DirAccess.remove_absolute(SaveGame.file)
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
	ronin.position = Vector3((MarketStreet.GALLERIES[0][0] + MarketStreet.GALLERIES[0][1]) * 0.5, 5.8, 0.0)
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

	# (The new enemies are held still while the husk is checked: a lantern
	# husk stands near one of the husks and would throw at him.)
	for other: Node in main.get_node("Village").get_children():
		if other is LanternHusk or other is PaperCritter:
			other.set_physics_process(false)
	# Three side slashes kill a husk.
	var husks := main.get_node("Village").get_children().filter(func(n: Node) -> bool: return n is PaperHusk and not n is LanternHusk)
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
	# (Back to walking first: caught mid-swipe or recovering, a husk does not
	# shove, and the check would depend on what it happened to be doing.)
	husk.call("_set_mode", &"patrol")
	husk.set("_attack_cooldown_left", 1.0)
	ronin.position = husk.position
	ronin.velocity = Vector3.ZERO
	# (Watched every frame, and every husk: on a slow computer the short
	# shove can be over before a single look at the end, and the touch can
	# come from the husk next to the one he was put on.)
	var all_husks: Array[Node] = main.get_node("Village").find_children("*", "PaperHusk", true, false)
	var shoved := false
	for f in 12:
		await physics_frame
		for h: Node in all_husks:
			shoved = shoved or (is_instance_valid(h) and h.mode == &"shove")
	_check("touching an enemy costs health (%d/%d)" % [ronin.health, ronin.max_health], ronin.health == ronin.max_health - 1)
	_check("the husk shoves when touching hurts him", shoved)

	# The husk's swipe, and the parry.
	husk = husks[2]
	await _face_off(ronin, husk)
	var before := ronin.health
	# (Watched every frame for a while: on a slow computer the husk's
	# cooldown after its shove can still be running.)
	for f in 150:
		await physics_frame
		if ronin.health < before:
			break
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

	# A market stall's awning is solid from below: jumping up under it, he
	# does not pass through onto its top.
	var stall: MarketStall = main.get_node("Village").find_children("*", "MarketStall", true, false)[0]
	ronin.position = Vector3(stall.global_position.x, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(5)
	Input.action_press("jump")
	await _frames(30)
	Input.action_release("jump")
	_check("an awning cannot be jumped up through (%.2f m, awning %.2f m)" % [ronin.position.y, stall.top], ronin.position.y < stall.top - 0.5)
	# Landing on it from a height throws him back up (a bounce).
	ronin.position = Vector3(stall.global_position.x, stall.top + 3.0, 0.0)
	ronin.velocity = Vector3.ZERO
	var rise := -99.0
	for f in 60:
		await process_frame
		rise = maxf(rise, ronin.velocity.y)
	_check("landing on an awning from high up bounces him (%.1f m/s up)" % rise, rise > 8.0)

	# Resting at the Paper-Maker's shrine: whole again, and a fall now brings
	# him back to the shrine.
	var shrine: RestShrine = main.get_node("Village").find_children("*", "RestShrine", true, false)[0]
	ronin.health = ronin.max_health - 2
	ronin.position = Vector3(shrine.global_position.x - 3.5, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	while ronin.global_position.x < shrine.global_position.x - 0.3:
		await process_frame
	Input.action_release("move_right")
	await _frames(45)
	var rest_spot: Vector3 = ronin.get("_spawn_position")
	_check("resting at a shrine heals him (%d/%d)" % [ronin.health, ronin.max_health], ronin.health == ronin.max_health)
	_check("and he will come back there (%.1f m from it)" % absf(rest_spot.x - shrine.global_position.x), absf(rest_spot.x - shrine.global_position.x) < 0.1)
	# Running straight past a shrine, without stopping, is enough (Julian).
	ronin.position = Vector3(shrine.global_position.x + 20.0, 0.1, 0.0)
	await _frames(20)
	ronin.set_checkpoint(Vector3(-10.0, 0.0, 0.0))
	ronin.health = ronin.max_health - 1
	ronin.position = Vector3(shrine.global_position.x - 3.5, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	while ronin.global_position.x < shrine.global_position.x + 2.5:
		await physics_frame
	Input.action_release("move_right")
	rest_spot = ronin.get("_spawn_position")
	_check("running past a shrine without stopping rests there (%d/%d)" % [ronin.health, ronin.max_health],
			ronin.health == ronin.max_health and absf(rest_spot.x - shrine.global_position.x) < 0.1)

	# Any tall wall can be clung to, not only the ones marked climbable: the
	# storehouse's east wall in Market Street.
	var store_wall := MarketStreet.SECRET_X + 3.6 + 0.2
	ronin.position = Vector3(store_wall + 0.34, 2.2, 0.0)
	ronin.velocity = Vector3.ZERO
	Input.action_press("move_left")
	var clung := false
	for f in 40:
		await physics_frame
		clung = clung or ronin.get("_sliding")
	Input.action_release("move_left")
	_check("he wall-slides on an unmarked wall (the storehouse)", clung)
	# ...but not on something as low as a step or a crate.
	ronin.position = Vector3(MarketStreet.SECRET_X + 5.15 + 0.8, 0.5, 0.0)
	ronin.velocity = Vector3.ZERO
	Input.action_press("move_left")
	clung = false
	for f in 12:  # (any longer and he is over the crate and at the storehouse)
		await physics_frame
		clung = clung or (f > 1 and ronin.get("_sliding"))  # (the first frame still holds the last wall)
	Input.action_release("move_left")
	_check("but not on a low crate", not clung)
	await _frames(20)

	for other: Node in main.get_node("Village").get_children():
		if other is LanternHusk or other is PaperCritter:
			other.set_physics_process(true)
	await _expanded_village(main, ronin)

	# The Paper-Maker tells him, in pictures, the first time he comes to her
	# (switched on here: the check normally keeps her quiet); it stops play,
	# can be skipped, and is remembered.
	PaperMakerTale.force = true
	SaveGame.papermaker_told = false
	var maker: PaperMaker = main.get_node("Village").find_children("*", "PaperMaker", true, false)[0]
	var a_husk: PaperHusk = null
	for h: PaperHusk in main.find_children("*", "PaperHusk", true, false):
		h.set_physics_process(true)
		a_husk = h
	ronin.position = Vector3(maker.global_position.x + 6.0, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_left")
	var tale: PaperMakerTale = null
	for f in 120:
		await physics_frame
		var found := main.find_children("*", "PaperMakerTale", true, false)
		if not found.is_empty():
			tale = found[0]
			break
	Input.action_release("move_left")
	_check("the Paper-Maker shows him her pictures when he comes to her", tale != null and not ronin.is_physics_processing())
	_check("while she does, the enemies hold still and he cannot be hurt", a_husk != null and not a_husk.is_physics_processing()
			and not ronin.take_damage(1, ronin.global_position + Vector3(1.0, 0.0, 0.0)))
	Input.action_press("jump")
	await _frames(70)
	Input.action_release("jump")
	await _frames(40)
	_check("they can be skipped, and are remembered (the enemies move again)", a_husk.is_physics_processing() and SaveGame.papermaker_told and ronin.is_physics_processing()
			and main.find_children("*", "PaperMakerTale", true, false).is_empty())
	PaperMakerTale.force = false

	# Falling into deep water: the screen fades and he is back at the shrine.
	var spawn: Vector3 = ronin.get("_spawn_position")
	before = ronin.health
	ronin.position = Vector3((Canals.DEEP.x + Canals.DEEP.y) * 0.5, -4.0, 0.0)
	ronin.velocity = Vector3.ZERO
	var lowest := 0.0
	for f in 150:
		await process_frame
		lowest = minf(lowest, (ronin.get_node("Puppet") as Node3D).position.y)
	_check("in deep water he sinks out of sight (%.1f m)" % lowest, lowest < -1.6)
	_check("deep water carries him back to the last shrine (%.1f m away)" % ronin.position.distance_to(spawn), ronin.position.distance_to(spawn) < 1.0)
	_check("and costs one health (%d -> %d)" % [before, ronin.health], ronin.health == before - 1 or (before == 1 and ronin.health == ronin.max_health))

	# The camera follows smoothly into and out of the courtyard (it used to
	# jump left on stepping out). Checked after the fight is set up, below.

	# The Weeping Hannya: walking into the courtyard plays her cutscene;
	# holding jump skips it, and the fight begins.
	ronin.set("_draw_safe", 0.0)
	ronin.health = ronin.max_health
	ronin.position = Vector3(Village.ARENA.x + 0.9, 1.6, 0.0)
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
		ronin.position = Vector3(Village.ARENA.x + 3.0, 1.6, 0.0)
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
		# Her fall: the ending cutscene plays, can be skipped, and the far gate
		# to the bamboo is open after it.
		ronin.set("_draw_safe", 30.0)
		boss.begin()
		boss.health = 0
		boss.call("_die")
		var ending: HannyaEnding = null
		for f in 240:
			await physics_frame
			for child: Node in main.get_children():
				if child is HannyaEnding:
					ending = child
			if ending:
				break
		_check("when she falls, the ending cutscene plays", ending != null)
		Input.action_press("jump")
		await _frames(60)
		Input.action_release("jump")
		await _frames(10)
		var grove: BambooGrove = main.get_node("Village").bamboo
		_check("it can be skipped, and the gate to the bamboo is open", grove.gate_open and ronin.is_physics_processing()
				and not is_instance_valid(ending))
		# Walking out through the open gate: the screen fades and he is in the
		# bamboo grove (its own place, far off); back through its gate, home.
		ronin.set("_draw_safe", 0.0)
		ronin.position = Vector3(BambooGrove.GATE_X - 1.2, Village.STEPS_TOP + 0.05, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(10)
		Input.action_press("move_right")
		var arrived := false
		for f in 200:
			await physics_frame
			if BambooGrove.in_grove(ronin.global_position.x):
				arrived = true
				break
		Input.action_release("move_right")
		var faded: float = (main.get("_fade") as ColorRect).modulate.a
		_check("walking out through the gate fades into the bamboo grove (x %.1f, fade %.2f)" % [ronin.global_position.x, faded],
				arrived and faded > 0.9 and absf(ronin.global_position.x - BambooGrove.SHIFT - BambooGrove.ARRIVE_X) < 0.5)
		await _frames(90)
		_check("the camera is in the grove with him", BambooGrove.in_grove(cam.global_position.x))
		Input.action_press("move_left")
		var home := false
		for f in 300:
			await physics_frame
			if not BambooGrove.in_grove(ronin.global_position.x):
				home = true
				break
		Input.action_release("move_left")
		await _frames(90)
		_check("and walking back through the grove's gate takes him home to the courtyard (x %.1f)" % ronin.global_position.x,
				home and absf(ronin.global_position.x - BambooGrove.RETURN_X) < 1.5 and not BambooGrove.in_grove(cam.global_position.x))
		# Every bamboo stem stands on ground: none over a ravine, none in the air.
		var floating := 0
		for f: Vector2 in grove.stem_feet:
			var on := false
			for g: Array in BambooGrove.GROUND:
				if f.x - 0.3 >= g[0] and f.x + 0.3 <= g[1] and absf(f.y - (g[2] - 0.05)) < 0.01:
					on = true
			if not on:
				floating += 1
		_check("every bamboo stem stands on ground (%d stems, %d not)" % [grove.stem_feet.size(), floating], floating == 0 and grove.stem_feet.size() > 50)
		ronin.set("_draw_safe", 120.0)  # (the grove's creatures must not knock him off these routes)
		ronin.health = ronin.max_health
		# The Crane Glide carries him over the first ravine.
		ronin.has_glide = true
		ronin.position = Vector3(BambooGrove.SHIFT + BambooGrove.GROUND[0][1] - 0.6, BambooGrove.GROUND[0][2] + 0.05, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(10)
		Input.action_press("move_right")
		Input.action_press("jump")
		var glided := false
		for f in 150:
			await physics_frame
			glided = glided or ronin.is_gliding()
		Input.action_release("jump")
		Input.action_release("move_right")
		await _frames(20)
		_check("gliding carries him over the bamboo ravine (x %.1f)" % ronin.global_position.x,
				glided and ronin.global_position.x > BambooGrove.SHIFT + BambooGrove.GROUND[1][0] and ronin.global_position.y > 1.0)
		# The glide tires: the wings hold him for glide_time, then fold away.
		ronin.position = Vector3(BambooGrove.SHIFT + 320.0, 9.0, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(2)
		Input.action_press("jump")
		var glide_frames := 0
		for f in 240:
			await physics_frame
			if ronin.is_gliding():
				glide_frames += 1
		Input.action_release("jump")
		_check("the wings tire: he glides %.2f s of %.1f s held" % [glide_frames / 60.0, 4.0],
				absf(glide_frames / 60.0 - ronin.glide_time) < 0.15)
		# The Windfall Gorge: too wide for one glide; riding the rising gusts
		# (hovering in each until it has lifted him) carries him over.
		var ride := func(start: Vector3, goal_x: float, rise_to: float, seconds: float) -> void:
			ronin.global_position = start
			ronin.velocity = Vector3.ZERO
			await _frames(5)
			Input.action_press("jump")
			for f in int(seconds * 60.0):
				await physics_frame
				var at := ronin.global_position
				if at.x > goal_x:
					# (Over the goal: let go, and wait to land.)
					Input.action_release("move_right")
					Input.action_release("jump")
					if ronin.is_on_floor():
						break
					continue
				# In a gust: steer to its middle and let it lift him; then on.
				var gust: Updraft = null
				for u: Updraft in Updraft.all:
					if absf(u.global_position.x - at.x) < u.width * 0.5 and Updraft.lift_at(at) > 0.0:
						gust = u
				if gust and at.y < rise_to:
					Input.action_release("move_right")
					Input.action_release("move_left")
					if at.x < gust.global_position.x - 0.3:
						Input.action_press("move_right")
					elif at.x > gust.global_position.x + 0.3:
						Input.action_press("move_left")
				else:
					Input.action_release("move_left")
					Input.action_press("move_right")
			Input.action_release("move_right")
			Input.action_release("move_left")
			Input.action_release("jump")
			await _frames(30)
		await ride.call(Vector3(BambooGrove.SHIFT + 247.5, 1.55, 0.0), BambooGrove.SHIFT + 287.2, 7.0, 16.0)
		_check("riding the rising gusts carries him over the Windfall Gorge (x %.1f, y %.1f)" % [ronin.global_position.x - BambooGrove.SHIFT, ronin.global_position.y],
				ronin.global_position.x > BambooGrove.SHIFT + 287.0 and ronin.global_position.y > 1.0)
		# The Canopy Road: up between the two bound stems by wall jumps...
		ronin.global_position = Vector3(BambooGrove.SHIFT + (CanopyRoad.CLIMB_STEMS[0] + CanopyRoad.CLIMB_STEMS[1]) * 0.5, 1.55, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(5)
		var highest := 0.0
		for k in 24:
			Input.action_press("jump")
			await _frames(9)
			Input.action_release("jump")
			await _frames(3)
			highest = maxf(highest, ronin.global_position.y)
		_check("he climbs between the canopy's bound stems by wall jumps (up to %.1f m)" % highest, highest > CanopyRoad.DECKS[0][2])
		# ...and from the first deck, a rising gust lifts him to the second.
		await ride.call(Vector3(BambooGrove.SHIFT + 300.5, 9.55, 0.0), BambooGrove.SHIFT + 308.0, 15.8, 8.0)
		_check("a rising gust lifts him from the first canopy deck to the second (x %.1f, y %.1f)" % [ronin.global_position.x - BambooGrove.SHIFT, ronin.global_position.y],
				ronin.is_on_floor() and absf(ronin.global_position.y - CanopyRoad.DECKS[1][2]) < 0.3)
		# The Falls: from the cliff top, one long glide over the pool to the far bank.
		await ride.call(Vector3(BambooGrove.SHIFT + 382.5, 13.55, 0.0), BambooGrove.SHIFT + 396.5, 0.0, 8.0)
		_check("from the top of the Falls he glides over the pool to the far bank (x %.1f, y %.1f)" % [ronin.global_position.x - BambooGrove.SHIFT, ronin.global_position.y],
				ronin.global_position.x > BambooGrove.SHIFT + 396.0 and ronin.global_position.y > 1.9 and not ronin.is_in_pit())
		# Akane: the first time he steps into her clearing, she meets him (play
		# stops); skipped, the duel begins behind a wall of wind; a parried cut
		# costs her posture; broken far enough, she yields and is gone.
		var duel: AkaneDuel = grove.duel
		SaveGame.akane_met = false
		SaveGame.akane_dueled = false
		ronin.global_position = Vector3(BambooGrove.SHIFT + AkaneDuel.CLEARING.x - 1.0, BambooGrove.GROUND[2][2] + 0.05, 0.0)
		ronin.velocity = Vector3.ZERO
		ronin.set("_draw_safe", 0.0)
		await _frames(10)
		Input.action_press("move_right")
		var met := false
		for f in 120:
			await physics_frame
			if not ronin.is_physics_processing():
				met = true
				break
		Input.action_release("move_right")
		_check("stepping into the clearing, Akane meets him", met and duel.akane.visible)
		Input.action_press("jump")
		await _frames(70)
		Input.action_release("jump")
		await _frames(30)
		_check("skipped, the duel begins behind a wall of wind", duel.akane.active and ronin.is_physics_processing()
				and duel.get("_wall") != null)
		var duel_music: AudioStreamPlayer = duel.get("_music")
		_check("her own duel music plays while they fight", duel_music.playing and duel_music.stream.resource_path.ends_with("music_akane_duel.ogg"))
		var akane := duel.akane
		akane.set_physics_process(false)
		akane.global_position = ronin.global_position + Vector3(1.6, 0.0, 0.0)
		akane.facing = -1.0
		ronin.facing = 1.0
		await _frames(2)
		ronin.set("_parry_time", 0.2)
		var before_posture := akane.posture
		akane.call("_swing", akane.cut_reach, akane.cut_height, 1)
		_check("a parried cut costs her posture (%d -> %d)" % [before_posture, akane.posture], akane.posture == before_posture + 1)
		akane.set_physics_process(true)
		akane.health = akane.yield_at + 1
		akane.set(&"_mode", &"recover")
		ronin.facing = -signf(akane.global_position.x - ronin.global_position.x)  # (looking away)
		akane.take_hit(2, Vector2(1.0, 0.0))
		await _frames(150)
		var toward := signf(akane.global_position.x - ronin.global_position.x)
		_check("while she speaks he stands still, facing her", not ronin.is_physics_processing()
				and (ronin.get_node("Puppet") as RoninPuppet).facing == toward)
		await _frames(270)
		_check("broken far enough, she yields and is gone (and the wind wall falls); he can move again", akane.mode() == &"gone"
				and SaveGame.akane_dueled and duel.get("_wall") == null and ronin.is_physics_processing())
		_check("her music has faded away once she is gone", not duel_music.playing)
		# ...and over the Rooftop Road's gap above the river (the first Crane
		# Glide gate), even against the gusts.
		ronin.position = Vector3(RooftopRoad.GLIDE_GAP.x - 0.3, 6.7, 0.0)
		ronin.velocity = Vector3.ZERO
		await _frames(20)
		Input.action_press("move_right")
		Input.action_press("jump")
		for f in 150:
			await physics_frame
			if ronin.is_on_floor() and ronin.global_position.x > RooftopRoad.GLIDE_GAP.y - 0.5:
				break
		Input.action_release("jump")
		Input.action_release("move_right")
		_check("gliding crosses the rooftop gap over the river (x %.1f, y %.1f)" % [ronin.global_position.x, ronin.global_position.y],
				ronin.global_position.x > RooftopRoad.GLIDE_GAP.y and ronin.global_position.y > 6.0)
		ronin.has_glide = false

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


## The areas of the expanded village: the Fallen Street, the canals, the
## river and its bridge, the gatehouse, the Shrine Steps.
func _expanded_village(main: Node, ronin: Ronin) -> void:
	var village: Village = main.get_node("Village")
	var camera: Camera3D = main.get_node("Camera")
	ronin.set("_draw_safe", 120.0)  # nothing hurts him during these checks
	# A soggy plank holds him a moment, then gives way: he drops into the
	# canals, unharmed, and the camera goes down with him without a jump.
	var plank: SoggyPlank = village.fallen.planks[1]
	var health_before := ronin.health
	ronin.position = Vector3(plank.global_position.x + plank.length * 0.5, 0.5, 0.0)
	ronin.velocity = Vector3.ZERO
	await physics_frame
	(camera as FollowCamera).snap_to_target()
	var held := false
	var biggest := 0.0
	var last_cam := camera.global_position
	var landed_at := Time.get_ticks_msec()
	var looked := false
	for f in 200:
		await process_frame
		# (A moment = 0.3 s by the clock, not a count of drawn frames: those
		# come slower as the world grows, and the plank gives way at 0.55 s.)
		if not looked and Time.get_ticks_msec() - landed_at >= 300:
			looked = true
			held = ronin.is_on_floor() and ronin.global_position.y > -0.4 and not plank.fallen
		if f > 2:
			biggest = maxf(biggest, camera.global_position.distance_to(last_cam))
		last_cam = camera.global_position
	_check("a soggy plank holds him for a moment", held)
	_check("then gives way and drops him into the canals (y %.1f)" % ronin.global_position.y, plank.fallen and ronin.global_position.y < -3.5)
	_check("falling through it is not a death (%d -> %d)" % [health_before, ronin.health], ronin.health == health_before)
	_check("the camera follows him down smoothly (biggest step %.2f m)" % biggest, biggest < 0.45)
	_check("underground, the camera is down with him (y %.1f)" % camera.global_position.y, camera.global_position.y < 0.5)
	# Wading in the canal water slows him.
	ronin.position = Vector3(67.0, Village.CANAL_WATER - 0.3, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	var fastest := 0.0
	var waded := false
	for f in 18:
		await physics_frame
		fastest = maxf(fastest, ronin.velocity.x)
		waded = waded or ronin.wading
	Input.action_release("move_right")
	_check("wading in the canal slows him (%.1f m/s)" % fastest, waded and fastest < ronin.run_speed * 0.75)
	# A sluice presses him down.
	ronin.position = Vector3(Canals.SLUICES[0], -4.6, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	_check("a sluice presses him down (%.1f m/s)" % ronin.velocity.y, ronin.velocity.y < -11.0 or ronin.global_position.y < -6.0)
	# The crawlspace: standing he cannot pass; ducked he shuffles through,
	# and stays ducked under it even when he lets go.
	ronin.position = Vector3(Canals.CRAWL.x - 1.2, Village.PIPE_FLOOR + 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	await _frames(60)
	_check("standing, he cannot get into the crawlspace (x %.1f)" % ronin.global_position.x, ronin.global_position.x < Canals.CRAWL.x)
	Input.action_press("aim_down")
	await _frames(90)
	Input.action_release("aim_down")
	await _frames(8)
	var stays_down: bool = ronin.get("_ducking")
	await _frames(160)
	Input.action_release("move_right")
	_check("ducked, he crawls under it and stays down beneath it", stays_down)
	_check("and comes out the other side (x %.1f)" % ronin.global_position.x, ronin.global_position.x > Canals.CRAWL.y + 0.2)
	# The grate into Well Square opens with two cuts from below.
	ronin.position = Vector3(Village.GRATE_X - 0.45, -1.95, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(15)
	for k in 2:
		Input.action_press("aim_up")
		Input.action_press("slash")
		await _frames(2)
		Input.action_release("slash")
		Input.action_release("aim_up")
		await _frames(30)
	_check("two cuts from below open the drain grate", village.canals.grate_open)
	# Over the river nothing pushes him any more (the gusts were taken out);
	# falling in, the river carries him off, back to the shrine.
	var spawn: Vector3 = ronin.get("_spawn_position")
	ronin.position = Vector3((RiverBridge.GAP.x + RiverBridge.GAP.y) * 0.5, 3.0, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(14)
	_check("nothing pushes him sideways over the river (%.2f m/s)" % ronin.velocity.x, absf(ronin.velocity.x) < 0.05)
	await _frames(150)
	_check("the river carries him back to the shrine (%.1f m away)" % ronin.global_position.distance_to(spawn), ronin.global_position.distance_to(spawn) < 1.0)
	# The way under the first wall is open: he runs straight through.
	var wall: Array = Village.CLIMB_WALLS[0]
	ronin.position = Vector3(wall[0] - 1.5, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	await _frames(10)
	Input.action_press("move_right")
	await _frames(45)
	Input.action_release("move_right")
	_check("he runs straight through under the first wall (x %.1f)" % ronin.global_position.x, ronin.global_position.x > wall[1] + 0.5)
	# The ladder at the end of Market Street: drawn up until he cuts its cord
	# from the deck above; then he climbs it from the street.
	var steps_up: Ladder = village.rooftops.ladder
	ronin.position = Vector3(steps_up.global_position.x, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("aim_up")
	await _frames(30)
	Input.action_release("aim_up")
	_check("before it is kicked down, the ladder cannot be climbed", not ronin.is_climbing() and ronin.global_position.y < 0.5)
	ronin.position = Vector3(steps_up.global_position.x - 0.9, steps_up.top + 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = 1.0
	await _frames(10)
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	await _frames(70)
	_check("a cut from the deck above lets the ladder down", steps_up.lowered)
	ronin.position = Vector3(steps_up.global_position.x, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("aim_up")
	var climbed := false
	for f in 220:
		await physics_frame
		climbed = climbed or ronin.is_climbing()
		if ronin.global_position.y > steps_up.top - 0.2 and not ronin.is_climbing():
			break
	Input.action_release("aim_up")
	await _frames(30)
	_check("then he climbs it from the street up onto the deck (y %.1f)" % ronin.global_position.y,
			climbed and ronin.global_position.y > steps_up.top - 0.3 and ronin.is_on_floor())
	# Jumping up into the corner of a gallery's floor, his head slips round it.
	var gallery: Array = MarketStreet.GALLERIES[0]
	ronin.position = Vector3(gallery[0] - 0.2, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	var corner_jump := await _jump_height(ronin, 40)
	_check("a jump that clips a corner slips round it (%.2f m up)" % corner_jump, corner_jump > 2.0)
	await _new_enemies(village, ronin)
	await _bamboo_creatures(village, ronin)
	await _lantern_market(village, ronin)
	await _cranes_and_saving(main, village, ronin)
	# Three shrines to rest at.
	_check("there are three shrines", village.find_children("*", "RestShrine", true, false).size() >= 3)
	# Up the Shrine Steps.
	ronin.position = Vector3(Village.STEPS.x - 0.5, 0.05, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	await _frames(int((Village.STEPS.y - Village.STEPS.x - 0.5) / ronin.run_speed * 60.0))
	Input.action_release("move_right")
	await _frames(20)
	_check("he walks up the Shrine Steps (%.2f m up, at x %.1f)" % [ronin.global_position.y, ronin.global_position.x],
			ronin.global_position.y > Village.STEPS_TOP * 0.8 and ronin.is_on_floor())
	ronin.position = Vector3(20.0, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(20)
	ronin.set("_draw_safe", 0.0)
	ronin.health = ronin.max_health


## Paper cranes, saving at a shrine, Continue, and the Smudge.
func _cranes_and_saving(main: Node, village: Village, ronin: Ronin) -> void:
	# A bundle of cranes is found by walking into it, and counted.
	var bundle: CraneBundle = null
	for b: CraneBundle in village.find_children("*", "CraneBundle", true, false):
		if b.id == "canal_ledge":
			bundle = b
	var before := SaveGame.crane_total()
	ronin.position = bundle.global_position + Vector3(-2.0, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(5)
	Input.action_press("move_right")
	await _frames(25)
	Input.action_release("move_right")
	_check("walking into a bundle of cranes finds them (%d -> %d)" % [before, SaveGame.crane_total()],
			bundle.taken and SaveGame.crane_total() == before + bundle.count)
	# Resting at the warehouse shrine saves the game.
	var shrine: RestShrine = village.river.shrine
	ronin.position = Vector3(shrine.global_position.x - 3.0, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	while ronin.global_position.x < shrine.global_position.x - 0.3:
		await process_frame
	Input.action_release("move_right")
	await _frames(45)
	_check("resting at a shrine saves the game", SaveGame.exists() and SaveGame.last_shrine == "warehouse")
	var cfg := ConfigFile.new()
	cfg.load(SaveGame.file)
	_check("the save keeps the shrine and the cranes", cfg.get_value("game", "last_shrine", "") == "warehouse"
			and (cfg.get_value("game", "cranes", []) as Array).size() >= 1)
	# Continue puts him back at that shrine, with what he had found.
	ronin.position = Vector3(10.0, 0.1, 0.0)
	SaveGame.cranes = []
	main.call("_continue_from_save")
	await _frames(5)
	_check("Continue brings him back to the shrine he saved at (x %.1f)" % ronin.global_position.x,
			absf(ronin.global_position.x - shrine.global_position.x) < 0.5 and SaveGame.has_crane("canal_ledge"))
	# Dying with ink leaves a Smudge holding it; cutting it gives it back.
	ronin.position = Vector3(124.0, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	ronin.ink = 5
	ronin.set("_invulnerable", 0.0)
	ronin.set("_draw_safe", 0.0)
	ronin.health = 1
	ronin.take_damage(1, ronin.global_position + Vector3(1.0, 0.0, 0.0))
	await _frames(200)
	var smudge: Smudge = main.get("_smudge")
	_check("dying leaves a Smudge holding his ink (%d ink now)" % ronin.ink, smudge != null and smudge.ink == 5 and ronin.ink == 0)
	if smudge:
		ronin.position = smudge.global_position + Vector3(-1.2, 0.1, 0.0)
		ronin.velocity = Vector3.ZERO
		ronin.facing = 1.0
		await _frames(30)
		Input.action_press("slash")
		await _frames(2)
		Input.action_release("slash")
		await _frames(20)
		_check("cutting the Smudge gives the ink back (%d)" % ronin.ink, ronin.ink == 5)


## The paper dog, the paper bird and the lantern husk.
func _new_enemies(village: Village, ronin: Ronin) -> void:
	# (the town's second dog: the market's dogs sleep while he is in town)
	var town_dogs := village.find_children("*", "PaperDog", true, false).filter(
			func(d: Node3D) -> bool: return not LanternMarket.in_market(d.global_position.x))
	var dog: PaperDog = town_dogs[1]
	var bird: PaperBird = village.find_children("*", "PaperBird", true, false)[0]
	var keeper: LanternHusk = null   # (the town's: the market's rest while he is away)
	for k: LanternHusk in village.find_children("*", "LanternHusk", true, false):
		if not LanternMarket.in_market(k.global_position.x):
			keeper = k
			break
	ronin.set("_draw_safe", 0.0)
	# The dog: seeing him ahead, it gives its tell, then charges; a parried
	# charge staggers it, and a cut then finishes it.
	dog.global_position.x = 93.0
	ronin.position = dog.global_position + Vector3(4.5, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = -1.0
	dog.set("_dir", 1.0)
	dog.set("_cooldown", 0.0)
	ronin.set("_invulnerable", 0.0)
	ronin.health = ronin.max_health
	var told := false
	var charged := false
	for f in 90:
		await physics_frame
		told = told or dog.mode == &"tell"
		charged = charged or dog.mode == &"charge"
		ronin.velocity.x = 0.0
		# Parry just before the charge reaches him.
		if dog.mode == &"charge" and absf(dog.global_position.x - ronin.global_position.x) < 2.6 and ronin.get("_parry_time") <= 0.0 \
				and ronin.get("_parry_cooldown_left") <= 0.0:
			Input.action_press("parry")
			await physics_frame
			Input.action_release("parry")
		if dog.is_staggered():
			break
	_check("the dog gives its tell, then charges", told and charged)
	_check("a parried charge staggers it (%s)" % dog.mode, dog.is_staggered())
	await _frames(30)  # (out of the parry stance first: no cutting in it)
	ronin.position = dog.global_position + Vector3(1.2, 0.1, 0.0)
	ronin.facing = -1.0
	await _frames(2)
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	await _frames(20)
	_check("and one cut finishes it", not is_instance_valid(dog))
	# The bird: cut down onto from above, he bounces off it.
	await _frames(40)  # (the last cut's cooldown, slowed by its hit-stop)
	ronin.set("_invulnerable", 5.0)
	bird.set_physics_process(false)
	bird.call("_set_mode", &"patrol")
	ronin.position = bird.global_position + Vector3(0.0, 1.2, 0.0)
	ronin.velocity = Vector3.ZERO
	Input.action_press("aim_down")
	await _frames(3)
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	Input.action_release("aim_down")
	var best := -99.0
	for i in 12:
		await _frames(1)
		best = maxf(best, ronin.velocity.y)
	_check("he can pogo off a paper bird (%.1f m/s)" % best, best > 6.0)
	if is_instance_valid(bird):
		bird.set_physics_process(true)
	# The lantern husk throws burning paper; parried, it flies back and
	# burns the thrower.
	ronin.set("_invulnerable", 0.0)
	ronin.set("_draw_safe", 0.0)
	keeper.set("_dir", 1.0)
	keeper.call("_set_mode", &"patrol")
	keeper.set("_throw_cooldown", 0.0)
	ronin.position = keeper.global_position + Vector3(6.0, 0.2, 0.0)
	ronin.velocity = Vector3.ZERO
	ronin.facing = -1.0
	var thrown: BurningPaper = null
	var hp: int = keeper.health
	for f in 200:
		await physics_frame
		ronin.velocity.x = 0.0
		ronin.facing = -1.0
		if thrown == null:
			for node: Node in village.get_children():
				if node is BurningPaper:
					thrown = node
		elif is_instance_valid(thrown) and not thrown.get("_returned") and thrown.global_position.distance_to(ronin.global_position + Vector3(0.0, 0.8, 0.0)) < 1.6 \
				and ronin.get("_parry_cooldown_left") <= 0.0:
			Input.action_press("parry")
			await physics_frame
			Input.action_release("parry")
		if is_instance_valid(keeper) and keeper.health < hp:
			break
		if not is_instance_valid(keeper):
			break
	_check("the lantern husk throws burning paper", thrown != null)
	_check("a parried wad flies back and burns the thrower", not is_instance_valid(keeper) or keeper.health < hp)
	await _struck_kinds(village, ronin)


## The bamboo's creatures, the red panda and the kite husk, made here at the
## west end of the long floor under the canopy, out of reach of the ones the
## grove places (BambooGrove.PANDAS, KITES): each gives its
## tell before it attacks, its attack hurts unparried, a parry staggers it
## and a cut then finishes it; the kite can be pogo'd.
func _bamboo_creatures(village: Village, ronin: Ronin) -> void:
	var ground := 1.5
	var reset := func(at: Vector3, face: float) -> void:
		ronin.position = at
		ronin.velocity = Vector3.ZERO
		ronin.facing = face
		ronin.health = ronin.max_health
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
	var parry_now := func() -> void:
		if ronin.get("_parry_time") <= 0.0 and ronin.get("_parry_cooldown_left") <= 0.0:
			Input.action_press("parry")
			await physics_frame
			Input.action_release("parry")
	# The red panda: it rears up (the tell), then charges and springs.
	var panda := RedPanda.new()
	panda.position = Vector3(BambooGrove.SHIFT + 290.0, ground + 0.05, 0.0)
	village.add_child(panda)
	panda.set("_dir", 1.0)
	reset.call(panda.position + Vector3(4.2, 0.1, 0.0), -1.0)
	await _frames(20)
	panda.global_position.x = BambooGrove.SHIFT + 290.0
	reset.call(Vector3(BambooGrove.SHIFT + 294.2, ground + 0.1, 0.0), -1.0)
	var order: Array[StringName] = []
	var hurt_before_attack := false
	for f in 150:
		await physics_frame
		ronin.velocity.x = 0.0
		if order.is_empty() or order[-1] != panda.mode:
			order.append(panda.mode)
		if ronin.health < ronin.max_health and not (&"charge" in order):
			hurt_before_attack = true
		if ronin.health < ronin.max_health:
			break
	var told_first := order.find(&"tell") >= 0 and order.find(&"tell") < order.find(&"charge")
	_check("the red panda rears up (its tell) before it charges (%s)" % [order], told_first and not hurt_before_attack)
	_check("and its charge or spring hurts him unparried (%d/%d)" % [ronin.health, ronin.max_health], ronin.health < ronin.max_health)
	await _frames(60)
	panda.global_position = Vector3(BambooGrove.SHIFT + 290.0, ground + 0.05, 0.0)
	panda.velocity = Vector3.ZERO
	panda.set("_dir", 1.0)
	panda.set("_cooldown", 0.0)
	panda.call("_set_mode", &"patrol")
	reset.call(Vector3(BambooGrove.SHIFT + 294.2, ground + 0.1, 0.0), -1.0)
	for f in 150:
		await physics_frame
		ronin.velocity.x = 0.0
		if panda.mode in [&"charge", &"pounce"] and absf(panda.global_position.x - ronin.global_position.x) < 2.2:
			await parry_now.call()
		if panda.is_staggered():
			break
	_check("a parried charge throws the red panda over, staggered (%s, %d/%d)" % [panda.mode, ronin.health, ronin.max_health],
			panda.is_staggered() and ronin.health == ronin.max_health)
	await _frames(30)
	ronin.position = panda.global_position + Vector3(1.2, 0.1, 0.0)
	ronin.facing = -1.0
	await _frames(2)
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	await _frames(20)
	_check("and one cut finishes it", not is_instance_valid(panda))
	await _frames(40)
	# The kite husk: it rears back (the tell), then swoops raking.
	var kite := KiteHusk.new()
	var roost := Vector3(BambooGrove.SHIFT + 299.5, ground + 3.2, 0.0)
	kite.position = roost
	village.add_child(kite)
	reset.call(Vector3(BambooGrove.SHIFT + 301.5, ground + 0.1, 0.0), -1.0)
	kite.set("_cooldown", 0.0)
	order.clear()
	hurt_before_attack = false
	for f in 150:
		await physics_frame
		ronin.velocity.x = 0.0
		if order.is_empty() or order[-1] != kite.mode:
			order.append(kite.mode)
		if ronin.health < ronin.max_health and not (&"dive" in order):
			hurt_before_attack = true
		if ronin.health < ronin.max_health:
			break
	told_first = order.find(&"tell") >= 0 and order.find(&"tell") < order.find(&"dive")
	_check("the kite husk rears back (its tell) before it swoops (%s)" % [order], told_first and not hurt_before_attack)
	_check("and its claws hurt him unparried (%d/%d)" % [ronin.health, ronin.max_health], ronin.health < ronin.max_health)
	await _frames(60)
	# Cut down onto from above, he bounces off it.
	ronin.set("_invulnerable", 5.0)
	kite.set_physics_process(false)
	kite.global_position = roost
	kite.call("_set_mode", &"patrol")
	ronin.position = roost + Vector3(0.0, 1.35, 0.0)
	ronin.velocity = Vector3.ZERO
	Input.action_press("aim_down")
	await _frames(3)
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	Input.action_release("aim_down")
	var best := -99.0
	for i in 12:
		await _frames(1)
		best = maxf(best, ronin.velocity.y)
	_check("he can pogo off a kite husk (%.1f m/s, its health %d)" % [best, kite.health], best > 6.0 and kite.health < kite.max_health)
	await _frames(60)
	# A parried swoop sends it tumbling, staggered; a cut then finishes it.
	kite.global_position = roost
	kite.velocity = Vector3.ZERO
	kite.set("_cooldown", 0.0)
	kite.call("_set_mode", &"patrol")
	kite.set_physics_process(true)
	reset.call(Vector3(BambooGrove.SHIFT + 301.5, ground + 0.1, 0.0), -1.0)
	for f in 150:
		await physics_frame
		ronin.velocity.x = 0.0
		if kite.mode == &"dive" and kite.global_position.distance_to(ronin.global_position + Vector3(0.0, 0.9, 0.0)) < 2.4:
			await parry_now.call()
		if kite.is_staggered():
			break
	_check("a parried swoop sends the kite husk tumbling, staggered (%s, %d/%d)" % [kite.mode, ronin.health, ronin.max_health],
			kite.is_staggered() and ronin.health == ronin.max_health)
	await _frames(30)
	kite.set_physics_process(false)
	kite.global_position = ronin.global_position + Vector3(-1.2, 0.9, 0.0)
	ronin.facing = -1.0
	await _frames(2)
	Input.action_press("slash")
	await _frames(2)
	Input.action_release("slash")
	await _frames(20)
	_check("and one cut finishes it", not is_instance_valid(kite))
	ronin.set("_invulnerable", 0.0)
	ronin.health = ronin.max_health
	ronin.position = Vector3(20.0, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(20)


## What a blow does to his paper depends on what struck him: ink soaks it,
## fire scorches it, a blade, claws or teeth tear it; and nothing is left
## once he can be hurt again.
## The Lantern Market: the way in from Akane's clearing, the bridge, the
## steps, a keeper's bow, and the way back.
func _lantern_market(village: Village, ronin: Ronin) -> void:
	var was_dueled := SaveGame.akane_dueled
	var was_at := ronin.global_position   # (put back here after: the next checks expect it)
	SaveGame.akane_dueled = true
	# (As after she has yielded: her duel is over, she is gone.)
	var duel := village.bamboo.duel
	var duel_state: StringName = duel.get("_state")
	var akane_shown := duel.akane.visible
	duel.set("_state", &"done")
	duel.akane.visible = false
	duel.akane.set_physics_process(false)
	ronin.set("_draw_safe", 5.0)
	ronin.position = Vector3(BambooGrove.SHIFT + BambooGrove.EAST_END - 5.0, 2.2, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(20)
	_check("after Akane the clearing's east end opens", village.bamboo.east_wall == null)
	Input.action_press("move_right")
	await _frames(70)
	Input.action_release("move_right")
	await _frames(90)
	var x := ronin.global_position.x
	_check("walking east out of her clearing brings him to the Lantern Market (x %.1f)" % x,
			LanternMarket.in_market(x) and ronin.is_on_floor())
	# The bridge's crown.
	var crown := LanternMarket.SHIFT + (LanternMarket.BRIDGE.x + LanternMarket.BRIDGE.y) * 0.5
	ronin.position = Vector3(crown, LanternMarket.deck_at(crown - LanternMarket.SHIFT) + 0.6, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(40)
	var deck := LanternMarket.deck_at(crown - LanternMarket.SHIFT)
	_check("he stands on the red bridge's crown (%.2f, deck %.2f)" % [ronin.global_position.y, deck],
			ronin.is_on_floor() and absf(ronin.global_position.y - deck) < 0.2)
	# Up the steps to the plaza.
	ronin.position = Vector3(LanternMarket.SHIFT + LanternMarket.STEPS.x - 1.0, LanternMarket.UPPER.z + 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_right")
	await _frames(int((LanternMarket.STEPS.y - LanternMarket.STEPS.x + 2.0) / ronin.run_speed * 60.0))
	Input.action_release("move_right")
	await _frames(20)
	_check("he walks up the market's steps to the gate (%.2f m up)" % ronin.global_position.y,
			ronin.global_position.y > LanternMarket.PLAZA.z - 0.3 and ronin.is_on_floor())
	# A keeper bows as he passes.
	var keeper: MarketKeeper = village.lantern_market.find_children("*", "MarketKeeper", true, false)[0]
	ronin.position = Vector3(keeper.global_position.x + 3.0, keeper.global_position.y + 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(15)
	ronin.position.x = keeper.global_position.x + 0.3
	var deepest := 0.0
	for i in 40:
		await _frames(1)
		deepest = maxf(deepest, (keeper.get("_torso") as Node3D).rotation.x)
	_check("a shopkeeper bows as he passes (%.2f rad)" % deepest, deepest > 0.25)
	# The Canal Quarter: a boat carries him; the hoist lifts him; a canal
	# takes him under (back to the last shrine).
	var quarter: CanalQuarter = village.lantern_market.find_children("*", "CanalQuarter", true, false)[0]
	# (The market's enemies hold still meanwhile: a husk by the hoist would
	# knock him off it, which is the game working, not the hoist failing.)
	var held: Array[Node] = []
	for node: Node in village.lantern_market.find_children("*", "", true, false):
		if (node is PaperHusk or node is PaperCritter) and node.is_physics_processing():
			node.set_physics_process(false)
			held.append(node)
	var boat: LanternBoat = quarter.find_children("*", "LanternBoat", true, false)[0]
	ronin.global_position = boat.global_position + Vector3(0.0, 0.6, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(20)
	var on_boat := ronin.global_position.x
	await _frames(90)
	_check("a lantern boat carries him across the canal (%.2f m; boat at %.1f, %.1f; pit %s, physics %s, floor %s)" % [absf(ronin.global_position.x - on_boat),
			boat.global_position.x, boat.global_position.y, ronin.is_in_pit(), ronin.is_physics_processing(), ronin.is_on_floor()],
			absf(ronin.global_position.x - on_boat) > 1.0 and ronin.global_position.y > CanalQuarter.WATER_Y)
	var hoist: Node3D = null
	for n: Node in quarter.get_children():
		if n is AnimatableBody3D and not n is LanternBoat:
			hoist = n
	for i in 600:   # (step on at the bottom, as he would)
		await physics_frame
		if hoist.position.y < CanalQuarter.HOIST_RANGE.x + 0.05:
			break
	ronin.global_position = hoist.global_position + Vector3(0.0, 0.15, 0.0)
	ronin.velocity = Vector3.ZERO
	var lowest := ronin.global_position.y
	var highest := lowest
	for i in 360:
		await physics_frame
		highest = maxf(highest, ronin.global_position.y)
	_check("the lantern hoist lifts him to the high walkways (%.1f m to %.1f m)" % [lowest, highest], highest > CanalQuarter.HOIST_RANGE.y - 0.3)
	# (Into the first canal at the end its boat is not at, the boat held.)
	boat.set_physics_process(false)
	var into := 166.9 if boat.position.x < 163.0 else 159.1
	ronin.global_position = Vector3(LanternMarket.SHIFT + into, CanalQuarter.WATER_Y + 1.0, 0.0)
	ronin.velocity = Vector3.ZERO
	var went_under := false
	for i in 90:
		await physics_frame
		if ronin.is_in_pit():
			went_under = true
			break
	_check("falling into a canal takes him under", went_under)
	await _frames(150)
	boat.set_physics_process(true)
	for node: Node in held:
		if is_instance_valid(node):
			node.set_physics_process(true)
	# And west out of the market, back to her clearing.
	ronin.position = Vector3(LanternMarket.SHIFT + LanternMarket.ARRIVE_X, 0.1, 0.0)
	ronin.velocity = Vector3.ZERO
	await _frames(10)
	Input.action_press("move_left")
	await _frames(60)
	Input.action_release("move_left")
	await _frames(90)
	_check("walking west out of the market returns him to the bamboo (x %.1f)" % ronin.global_position.x,
			BambooGrove.in_grove(ronin.global_position.x))
	SaveGame.akane_dueled = was_dueled
	duel.set("_state", duel_state)
	duel.akane.visible = akane_shown
	ronin.global_position = was_at
	ronin.velocity = Vector3.ZERO
	await _frames(90)
	ronin.set("_draw_safe", 0.0)
	ronin.health = ronin.max_health


func _struck_kinds(village: Village, ronin: Ronin) -> void:
	var puppet: RoninPuppet = ronin.get_node("Puppet")
	# Every enemy holds still meanwhile, so only the blows under test land.
	var held: Array[Node] = []
	for node: Node in village.find_children("*", "", true, false):
		if (node is PaperHusk or node is PaperCritter or node is BurningPaper) and node.is_physics_processing():
			node.set_physics_process(false)
			held.append(node)
	var shown := func() -> Dictionary:
		return {&"ink": puppet.shows_ink(), &"fire": puppet.shows_burn(), &"cut": puppet.shows_tear()}
	var wait_clean := func() -> void:
		for f in 600:
			if ronin.get("_invulnerable") <= 0.0:
				break
			await physics_frame
		await _frames(5)
	for kind: StringName in [&"ink", &"fire", &"cut"]:
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
		ronin.health = ronin.max_health
		ronin.take_damage(1, ronin.global_position + Vector3(1.0, 0.0, 0.0), kind)
		await _frames(3)
		var now: Dictionary = shown.call()
		_check("a blow of %s shows %s and nothing else %s" % [kind, kind, now], now[kind] and now.values().count(true) == 1)
		await wait_clean.call()
		now = shown.call()
		_check("and once he can be hurt again nothing is left on him %s" % now, now.values().count(true) == 0)
	# A real burning wad, unparried, scorches him (no ink).
	ronin.set("_invulnerable", 0.0)
	ronin.set("_draw_safe", 0.0)
	ronin.health = ronin.max_health
	ronin.velocity = Vector3.ZERO
	ronin.last_hurt_kind = &""
	var wad := BurningPaper.new()
	village.add_child(wad)
	wad.global_position = ronin.global_position + Vector3(1.2, 0.9, 0.0)
	wad.velocity = Vector3(-8.0, 0.0, 0.0)
	for f in 30:
		await physics_frame
		if ronin.last_hurt_kind != &"":
			break
	_check("burning paper scorches him (%s)" % ronin.last_hurt_kind, ronin.last_hurt_kind == &"fire" and puppet.shows_burn() and not puppet.shows_ink())
	await wait_clean.call()
	# A paper dog's bite tears his paper (no ink).
	var dogs := village.find_children("*", "PaperDog", true, false).filter(
			func(d: Node3D) -> bool: return not LanternMarket.in_market(d.global_position.x))
	if not dogs.is_empty():
		var dog: PaperDog = dogs[0]
		dog.set_physics_process(false)
		ronin.last_hurt_kind = &""
		ronin.set("_invulnerable", 0.0)
		ronin.set("_draw_safe", 0.0)
		ronin.health = ronin.max_health
		dog.global_position = ronin.global_position + Vector3(-0.6, 0.0, 0.0)
		dog.set("_dir", 1.0)
		await _frames(2)
		dog.call("_bite", 0.5)
		await _frames(3)
		_check("a paper dog's bite tears his paper (%s)" % ronin.last_hurt_kind, ronin.last_hurt_kind == &"cut" and puppet.shows_tear() and not puppet.shows_ink())
		await wait_clean.call()
	for node: Node in held:
		if is_instance_valid(node):
			node.set_physics_process(true)


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
