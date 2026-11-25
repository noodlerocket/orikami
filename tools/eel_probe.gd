extends SceneTree
## Stands him on a deck beside an ink eel's pool and watches the eel for a
## while: prints every moment its head is inside a solid of the world (it
## once leapt through the stilt houses' decks). Usage (headless):
##   Godot_..._console.exe --headless --path . --script tools/eel_probe.gd -- STAND_X STAND_Y SECONDS

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var at := Vector3(SumiMarsh.SHIFT + float(args[0]), float(args[1]), 0.0)
	var seconds := float(args[2])
	SaveGame.file = "user://probe_save.cfg"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var ronin := main.get_node("Ronin") as Ronin
	ronin.global_position = at
	ronin.velocity = Vector3.ZERO
	for f in 10:
		await physics_frame
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.collision_mask = 1
	var inside := 0
	var leaps := 0
	var was := &""
	for f in int(seconds * 60.0):
		await physics_frame
		ronin.global_position = at   # (keep him standing there)
		ronin.velocity = Vector3.ZERO
		for eel: InkEel in main.find_children("*", "InkEel", true, false):
			if eel.global_position.distance_to(at) > 14.0:
				continue
			if eel.mode != was:
				was = eel.mode
				if was == &"leap":
					leaps += 1
			if eel.mode != &"leap":
				continue
			q.position = eel.global_position
			if not space.intersect_point(q, 1).is_empty():
				inside += 1
				print("INSIDE at ", eel.global_position - Vector3(SumiMarsh.SHIFT, 0, 0))
	print("EEL PROBE: leaps %d, frames inside a solid %d, health %d" % [leaps, inside, ronin.health])
	quit()
