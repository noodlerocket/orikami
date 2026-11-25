extends SceneTree
## Measures how fast the game runs at spots across the whole world (for the
## speed work: measure before and after every change). Run it with a window
## (not headless), vsync off, nothing else heavy running:
##   Godot_..._console.exe --path . --script tools/speed_probe.gd -- [label]
## For each spot it prints: frames a second (average over 3 s), the worst
## frame (ms), the graphics card's time and the processor's time per frame
## (ms), draw calls and objects drawn, and the scripts' time per frame.
## Every boss is set as met or beaten so no cutscene starts.

const SPOTS := [
	["town: well square", 6.0, 1.0], ["town: market street", 40.0, 1.0], ["town: river bridge", 100.0, 3.0],
	["town: shrine steps", 165.0, 3.0], ["grove: west", 1020.0, 1.0], ["grove: canopy road", 1300.0, 1.0],
	["grove: falls", 1380.0, 1.0], ["market: lower market", 2030.0, 0.5], ["market: festival square", 2135.0, 3.5],
	["market: canal quarter", 2180.0, 3.5], ["market: ward", 2250.0, 3.5], ["market: rise", 2340.0, 15.5],
	["market: terraces", 2430.0, 22.0], ["marsh: steps", 3010.0, 1.0], ["marsh: drowned village", 3130.0, 1.0],
	["marsh: black mere", 3260.0, 1.0], ["skies: eyrie", 4130.0, 2.0], ["skies: wind shrine", 4300.0, 2.2],
	["gates: foot", 5020.0, 0.5], ["gates: high terrace", 5170.0, 26.5],
]


func _initialize() -> void:
	var label: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	SaveGame.file = "user://speed_save.cfg"
	SaveGame.hannya_fallen = true
	SaveGame.akane_met = true
	SaveGame.akane_dueled = true
	SaveGame.dragon_met = true
	SaveGame.dragon_beaten = true
	SaveGame.hosho_beaten = true
	SaveGame.shimeri_met = true
	SaveGame.shimeri_beaten = true
	SaveGame.akane_skies_met = true
	SaveGame.akane_skies_dueled = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var vp := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for f in 60:
		await process_frame
	var ronin := main.get_node("Ronin") as Ronin
	ronin.set("_invulnerable", 99999.0)
	# SPEED_OFF=particles|veils|lights|shadows|grain: switch one kind of thing
	# off everywhere, to see what it costs. SPEED_SPOTS=a,b,c: only those spots.
	var off := OS.get_environment("SPEED_OFF")
	var spots := SPOTS
	if OS.get_environment("SPEED_SPOTS") != "":
		spots = []
		for i: String in OS.get_environment("SPEED_SPOTS").split(","):
			spots.append(SPOTS[int(i)])
	print("SPEED %s  (renderer %s)" % [label, RenderingServer.get_current_rendering_method()])
	print("SPEED spot                      fps   worst ms   gpu ms   cpu ms   draws   objects   scripts ms")
	var all_fps := 0.0
	for spot: Array in spots:
		_switch_off(main, off)
		ronin.global_position = Vector3(spot[1], spot[2], 0.0)
		ronin.velocity = Vector3.ZERO
		for f in 90:
			await process_frame
			ronin.set("_invulnerable", 99999.0)
		var frames := 0
		var total := 0.0
		var worst := 0.0
		var gpu := 0.0
		var cpu := 0.0
		var draws := 0.0
		var objects := 0.0
		var scripts := 0.0
		var start := Time.get_ticks_usec()
		var last := start
		while Time.get_ticks_usec() - start < 3000000:
			await process_frame
			var now := Time.get_ticks_usec()
			var ms := (now - last) / 1000.0
			last = now
			frames += 1
			total += ms
			worst = maxf(worst, ms)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
			draws += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			objects += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
			scripts += (Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
		var fps := frames / (total / 1000.0)
		all_fps += fps
		print("SPEED %-26s %5.0f   %7.1f   %6.1f   %6.1f   %5.0f   %7.0f   %6.1f" % [spot[0], fps, worst, gpu / frames, cpu / frames, draws / frames, objects / frames, scripts / frames])
	print("SPEED average fps %.0f" % (all_fps / spots.size()))
	quit()


func ronin_x_place(main: Node) -> Node:
	var v := main.get_node("Village") as Village
	var x := (main.get_node("Ronin") as Node3D).global_position.x
	if LanternMarket.in_market(x):
		return v.lantern_market
	return null


func _switch_off(main: Node, what: String) -> void:
	if what == "":
		return
	for n: Node in main.find_children("*", "", true, false):
		match what:
			"particles":
				if n is CPUParticles3D or n is GPUParticles3D:
					(n as Node3D).visible = false
			"veils":
				var m := n as MeshInstance3D
				if m and m.material_override is BaseMaterial3D and (m.material_override as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					m.visible = false
			"lights":
				if n is OmniLight3D or n is SpotLight3D:
					(n as Light3D).visible = false
			"range":
				if n is OmniLight3D and not n.has_meta(&"probe_ranged"):
					n.set_meta(&"probe_ranged", true)
					(n as OmniLight3D).omni_range *= 0.75
			"regions":
				# Every other place removed outright (not just hidden).
				var v := main.get_node("Village") as Village
				var here := ronin_x_place(main)
				for r: Node in [v.bamboo, v.lantern_market, v.marsh, v.skies, v.gates]:
					if is_instance_valid(r) and r != here and not r.is_queued_for_deletion():
						r.queue_free()
				return
			"shadows":
				if n is Light3D:
					(n as Light3D).shadow_enabled = false
			"grain":
				if n.name == "PaperGrain":
					(n as CanvasItem).visible = false
