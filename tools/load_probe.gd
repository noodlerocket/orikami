extends SceneTree
## How long the world takes to build and how much memory it holds, and how
## much of the frame each place's hidden contents cost (speed work).
## Usage: Godot_..._console.exe --path . --script tools/load_probe.gd

func _initialize() -> void:
	SaveGame.file = "user://speed_save.cfg"
	var before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var t0 := Time.get_ticks_msec()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var t1 := Time.get_ticks_msec()
	root.add_child(main)
	var t2 := Time.get_ticks_msec()
	for f in 5:
		await process_frame
	var t3 := Time.get_ticks_msec()
	var after := Performance.get_monitor(Performance.MEMORY_STATIC)
	var v := main.get_node("Village") as Village
	print("LOAD load scene %d ms, build world %d ms, first frames (joining scenery) %d ms" % [t1 - t0, t2 - t1, t3 - t2])
	print("LOAD memory for the world: %.0f MB; video memory %.0f MB" % [(after - before) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
	print("LOAD nodes in the whole game: %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for r: Node in [v, v.bamboo, v.lantern_market, v.marsh, v.skies, v.gates]:
		var n := r.find_children("*", "", true, false).size()
		print("LOAD   %s: %d nodes" % [r.get_script().resource_path.get_file(), n])
	quit()
