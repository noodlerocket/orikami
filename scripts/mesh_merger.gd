class_name MeshMerger
extends RefCounted
## Joins the world's still scenery into a few big meshes (speed: the town
## asked the graphics card for about 800 separate pieces a frame; every
## plank, tile row and post was its own mesh, folded in code).
##
## Run once, after the whole world is built (Main). A piece is joined only if
## nothing can ever move, fade, swap or remove it:
## - it is a plain mesh (no script, no group, no children, not top-level),
##   solid (not see-through), not a billboard, not skinned, no overlay;
## - every node between it and its region's builder is plain too (no script,
##   no group): swaying things are in the "windswept" group;
## - no script keeps it, its material or anything above it in a variable or
##   in a node's meta (scanned below), so no code can reach it later.
## Pieces under the same builder, in the same 16 m stretch, with materials
## that look the same, become one mesh there. The originals are not freed
## (a forgotten reference could still touch one): they are taken off every
## render layer, so they are neither drawn nor cast shadows.

const CHUNK := 16.0

static var merged_count := 0
static var piece_count := 0


## `builders`: the nodes whose scripts build the world (the Village and each
## region's own node): pieces are joined under the builder they belong to.
static func merge(scene: Node, builders: Array) -> void:
	var builder_set := {}
	for b: Node in builders:
		builder_set[b] = true
	var held := _referenced(scene, builder_set)
	var groups := {}   # key -> [builder, Array[MeshInstance3D]]
	for node: Node in scene.find_children("*", "MeshInstance3D", true, false):
		var m := node as MeshInstance3D
		var builder := _builder_of(m, builder_set, held)
		if builder == null or not _plain_mesh(m, held):
			continue
		var mat := m.material_override as StandardMaterial3D
		var x := (m.global_transform * m.get_aabb()).get_center().x
		var key := [builder.get_instance_id(), floori(x / CHUNK), _look(mat), m.cast_shadow, m.layers, m.mesh.surface_get_format(0)]
		var k := str(key)
		if not groups.has(k):
			groups[k] = [builder, []]
		(groups[k][1] as Array).append(m)
	for k: String in groups:
		var builder: Node3D = groups[k][0]
		var pieces: Array = groups[k][1]
		if pieces.size() < 2:
			continue
		var tool := SurfaceTool.new()
		var to_local := builder.global_transform.affine_inverse()
		for m: MeshInstance3D in pieces:
			var mesh := m.mesh
			for s in mesh.get_surface_count():
				tool.append_from(mesh, s, to_local * m.global_transform)
		var joined := MeshInstance3D.new()
		joined.name = "Joined"
		joined.mesh = tool.commit()
		var first: MeshInstance3D = pieces[0]
		joined.material_override = (first.material_override as Material).duplicate()
		joined.cast_shadow = first.cast_shadow
		joined.layers = first.layers
		builder.add_child(joined)
		for m: MeshInstance3D in pieces:
			m.layers = 0
		merged_count += 1
		piece_count += pieces.size()


## The builder above this mesh, if everything between is plain and nothing
## holds any of it; else null.
static func _builder_of(m: MeshInstance3D, builders: Dictionary, held: Dictionary) -> Node3D:
	var n: Node = m.get_parent()
	while n != null:
		if builders.has(n):
			return n as Node3D
		if n.get_script() != null or not n.get_groups().is_empty() or held.has(n):
			return null
		if n is Node3D and (n as Node3D).top_level:
			return null
		if not (n is Node3D) or n.get_class() != "Node3D":
			return null   # (only plain grouping nodes between)
		n = n.get_parent()
	return null


static func _plain_mesh(m: MeshInstance3D, held: Dictionary) -> bool:
	if m.get_script() != null or not m.get_groups().is_empty() or held.has(m) or m.get_child_count() > 0:
		return false
	if not m.visible or m.top_level or m.layers == 0 or m.material_overlay != null or m.skeleton != NodePath("") and m.skin != null:
		return false
	if m.mesh == null or not (m.mesh is ArrayMesh) or m.mesh.get_surface_count() == 0:
		return false
	for s in m.mesh.get_surface_count():
		if m.get_surface_override_material(s) != null:
			return false
	var mat := m.material_override as StandardMaterial3D
	if mat == null or held.has(mat) or mat.next_pass != null:
		return false
	if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or mat.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return false
	if mat.proximity_fade_enabled or mat.distance_fade_mode != BaseMaterial3D.DISTANCE_FADE_DISABLED:
		return false
	return true


## What makes two materials draw the same.
static func _look(mat: StandardMaterial3D) -> String:
	return str([mat.albedo_color, mat.albedo_texture, mat.vertex_color_use_as_albedo, mat.vertex_color_is_srgb,
			mat.shading_mode, mat.emission_enabled, mat.emission, mat.emission_energy_multiplier, mat.cull_mode,
			mat.roughness, mat.metallic, mat.metallic_specular, mat.texture_filter, mat.no_depth_test, mat.render_priority,
			mat.disable_receive_shadows, mat.disable_fog, mat.uv1_scale, mat.uv1_triplanar, mat.diffuse_mode, mat.specular_mode])


## Every node and material any script keeps in a variable (or any node keeps
## in its meta), looking into arrays and dictionaries: these may be moved,
## faded or freed later, so they (and what is under them) are left alone.
static func _referenced(scene: Node, builders: Dictionary) -> Dictionary:
	var held := {}
	var all: Array = [scene] + scene.find_children("*", "", true, false)
	for n: Node in all:
		if n.get_script() != null:
			for p: Dictionary in n.get_property_list():
				if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
					_hold(n.get(p["name"]), held, 0)
		for key: StringName in n.get_meta_list():
			_hold(n.get_meta(key), held, 0)
	# Whatever is held, everything under it is held too (but not under a
	# builder or the scene itself: holding the market's node is not holding
	# every plank in it).
	for n: Variant in held.keys():
		if is_instance_valid(n) and n is Node and not builders.has(n) and not _holds_builder(n as Node, builders):
			for c: Node in (n as Node).find_children("*", "", true, false):
				held[c] = true
	return held


static func _holds_builder(n: Node, builders: Dictionary) -> bool:
	for b: Node in builders:
		if n.is_ancestor_of(b):
			return true
	return false


static func _hold(v: Variant, held: Dictionary, depth: int) -> void:
	if depth > 3:
		return
	if typeof(v) == TYPE_OBJECT:
		if not is_instance_valid(v):
			return
		if v is Node or v is Material:
			held[v] = true
	elif v is Array:
		for e: Variant in v:
			_hold(e, held, depth + 1)
	elif v is Dictionary:
		for e: Variant in (v as Dictionary).values():
			_hold(e, held, depth + 1)

