extends SceneTree
## Photographs a model from the front, the side and three-quarters, on a
## plain grey stage, and prints its size and bones. For checking what Meshy
## made before using it. Needs a window (not --headless):
##   Godot_v4.7.2-stable_win64_console.exe --path . --script tools/model_look.gd -- res://models/x.glb C:\full\path\out.png


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: Node3D = load(args[0]).instantiate()
	root.add_child(scene)
	await process_frame
	var low := Vector3.INF
	var high := -Vector3.INF
	var tris := 0
	for m: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var box := m.global_transform * m.get_aabb()
		low = low.min(box.position)
		high = high.max(box.end)
		for s in m.mesh.get_surface_count():
			var arrays := m.mesh.surface_get_arrays(s)
			var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			tris += index.size() / 3 if index.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	print("size: ", high - low, "  from ", low, " to ", high, "  triangles: ", tris)
	for sk: Skeleton3D in scene.find_children("*", "Skeleton3D", true, false):
		print("bones: ", sk.get_bone_count())
	for p: Node in scene.find_children("*", "AnimationPlayer", true, false):
		p.queue_free()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.45, 0.47)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.72)
	root.add_child(env)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	var middle := (low + high) * 0.5
	# An optional third argument moves the camera further out (skinned models
	# can draw larger than their bounding box says).
	var reach := (high - low).length() * 1.1 * (float(args[2]) if args.size() > 2 else 1.0)
	var sheet := Image.create(1200, 400, false, Image.FORMAT_RGB8)
	var angles := [0.0, 90.0, 35.0]
	for i in 3:
		var a := deg_to_rad(angles[i])
		camera.look_at_from_position(middle + Vector3(sin(a), 0.0, cos(a)) * reach, middle)
		for f in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGB8)
		var side := mini(shot.get_width(), shot.get_height())
		var piece := shot.get_region(Rect2i((shot.get_width() - side) / 2, (shot.get_height() - side) / 2, side, side))
		piece.resize(400, 400)
		sheet.blit_rect(piece, Rect2i(0, 0, 400, 400), Vector2i(i * 400, 0))
	sheet.save_png(args[1])
	quit()
