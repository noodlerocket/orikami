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
	var full := await _jump_height(ronin, 40)
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

	print("SMOKE TEST: ", "ALL PASSED" if _failures == 0 else "%d FAILED" % _failures)
	Engine.time_scale = 1.0
	quit(_failures)


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
