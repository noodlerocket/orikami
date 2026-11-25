extends SceneTree
## Prints the size of a model's meshes (for placing bones in code):
## Godot_..._console.exe --headless --path . --script tools/model_bounds.gd -- res://models/x.glb

func _init() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var scene := (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	for m: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var box := m.global_transform * m.get_aabb()
		print(m.name, " aabb pos ", box.position, " size ", box.size, " verts ", m.mesh.surface_get_array_len(0))
		# Slices along z (front-back) and y, to find limbs.
		var arrays := m.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for v in verts:
			lo = lo.min(v)
			hi = hi.max(v)
		print("local min ", lo, " max ", hi)
		for k in 10:
			var z0 := lerpf(lo.z, hi.z, k / 10.0)
			var z1 := lerpf(lo.z, hi.z, (k + 1) / 10.0)
			var a := Vector3.INF
			var b := -Vector3.INF
			for v in verts:
				if v.z >= z0 and v.z < z1:
					a = a.min(v)
					b = b.max(v)
			print("  z %.3f..%.3f: x %.3f..%.3f  y %.3f..%.3f" % [z0, z1, a.x, b.x, a.y, b.y])
	quit()
