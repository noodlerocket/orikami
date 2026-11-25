extends SceneTree
## Lists every solid along the gameplay plane in a stretch of the world that
## could block or trap him by mistake (for checking a new area by its code):
##  - LOW: something whose underside hangs 0.05 to 1.9 m above the surface
##    under it (he cannot walk under it, and would bump his head);
##  - STEP: something standing on the surface 0.3 to 2.6 m tall (he must
##    jump it; fine if meant);
##  - WALL: something taller than 2.6 m standing in the path.
## Usage (headless):
##   Godot_..._console.exe --headless --path . --script tools/blockage_scan.gd -- FROM_X TO_X

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var from := float(args[0])
	var to := float(args[1])
	SaveGame.file = "user://scan_save.cfg"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var found := 0
	for body: CollisionObject3D in main.find_children("*", "CollisionObject3D", true, false):
		if not (body is StaticBody3D or body is AnimatableBody3D):
			continue
		if (body.collision_layer & 1) == 0:
			continue
		for shape_node: Node in body.get_children():
			if not (shape_node is CollisionShape3D) or (shape_node as CollisionShape3D).disabled:
				continue
			var cs := shape_node as CollisionShape3D
			var box := cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
			if box.end.x < from or box.position.x > to:
				continue
			if box.position.z > 0.3 or box.end.z < -0.3:
				continue
			var cx := clampf(box.get_center().x, from, to)
			# The surface under it (another solid) at its middle.
			var q := PhysicsRayQueryParameters3D.create(Vector3(cx, box.position.y + 0.05, 0.0), Vector3(cx, box.position.y - 40.0, 0.0), 1)
			q.exclude = [body.get_rid()]
			var hit: Dictionary = space.intersect_ray(q)
			if hit.is_empty():
				continue
			var under: float = (hit["position"] as Vector3).y
			var gap := box.position.y - under
			var tall := box.size.y
			var kind := ""
			if gap > 0.05 and gap < 1.9:
				kind = "LOW "
			elif gap <= 0.05 and tall > 0.3 and tall <= 2.6:
				kind = "STEP"
			elif gap <= 0.05 and tall > 2.6:
				kind = "WALL"
			if kind == "":
				continue
			found += 1
			var meta := ""
			for m: StringName in body.get_meta_list():
				meta += " " + String(m)
			print("%s x %.1f..%.1f  y %.2f..%.2f  (surface %.2f, gap %.2f)  %s %s%s" % [kind, box.position.x, box.end.x, box.position.y, box.end.y,
					under, gap, body.get_class(), body.get_parent().name, meta])
	print("SCAN DONE: %d" % found)
	quit()
