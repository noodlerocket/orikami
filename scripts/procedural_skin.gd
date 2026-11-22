class_name ProceduralSkin
extends RefCounted
## Gives an unrigged model bones, in code. Meshy can only rig people, so for
## an animal or a thing (the red panda, the kite husk) the skeleton is built
## here: a few bones placed at joints measured from the model's own vertices,
## and every vertex given up to four bones to follow, weighted smoothly by
## how near it is to each (so nothing tears at a joint). The model's own
## material is kept. Then the bones are posed by hand every frame.
##
## A bone's rest has no turn, only a position, so a pose's turns are in the
## model's own axes (+Z is the model's front for a Meshy model).

var skeleton := Skeleton3D.new()
var parents := PackedInt32Array()
## Each bone's joint, in the model's own space.
var heads := PackedVector3Array()
## Each bone's turn now, relative to its parent (set these, then apply()).
var turns: Array[Quaternion] = []
## Each bone's move from its rest position (used for the root).
var moves := PackedVector3Array()

## Meshes already skinned, shared between creatures of one kind (skinning
## takes a moment, so it is done once).
static var _made := {}


func add_bone(bone_name: String, parent: int, head: Vector3) -> int:
	parents.append(parent)
	heads.append(head)
	turns.append(Quaternion.IDENTITY)
	moves.append(Vector3.ZERO)
	return heads.size() - 1


## Builds the skeleton from the bones added.
func finish() -> void:
	for i in heads.size():
		skeleton.add_bone("b%d" % i)
		if parents[i] >= 0:
			skeleton.set_bone_parent(i, parents[i])
		skeleton.set_bone_rest(i, Transform3D(Basis.IDENTITY, _rest_offset(i)))
	skeleton.reset_bone_poses()


func _rest_offset(i: int) -> Vector3:
	return heads[i] - (heads[parents[i]] if parents[i] >= 0 else Vector3.ZERO)


## Skins a mesh to the skeleton and adds it. `weigh` is called with each
## vertex (model space) and returns a PackedFloat32Array of raw weights, one
## per bone; the four largest are kept and made to add up to one. `key`
## names the result so creatures of one kind share it.
func skin(key: String, source: Mesh, material: Material, weigh: Callable) -> MeshInstance3D:
	var made: Array = _made.get(key, [])
	if made.is_empty():
		var mesh := ArrayMesh.new()
		for s in source.get_surface_count():
			var arrays := source.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			bones.resize(verts.size() * 4)
			weights.resize(verts.size() * 4)
			for v in verts.size():
				var raw: PackedFloat32Array = weigh.call(verts[v])
				var best := [-1, -1, -1, -1]
				var best_w := [0.0, 0.0, 0.0, 0.0]
				for b in raw.size():
					var w := raw[b]
					if w <= 0.0:
						continue
					for k in 4:
						if w > best_w[k]:
							best.insert(k, b)
							best_w.insert(k, w)
							best.resize(4)
							best_w.resize(4)
							break
				var total: float = best_w[0] + best_w[1] + best_w[2] + best_w[3]
				for k in 4:
					bones[v * 4 + k] = maxi(best[k], 0)
					weights[v * 4 + k] = (best_w[k] / total) if total > 0.0 else (1.0 if k == 0 else 0.0)
			arrays[Mesh.ARRAY_BONES] = bones
			arrays[Mesh.ARRAY_WEIGHTS] = weights
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(s, material)
		var binds := Skin.new()
		for i in heads.size():
			binds.add_bind(i, Transform3D(Basis.IDENTITY, -heads[i]))
		made = [mesh, binds]
		_made[key] = made
	var instance := MeshInstance3D.new()
	instance.mesh = made[0]
	instance.skin = made[1]
	instance.extra_cull_margin = 2.0  # (posed far from rest, it must not be culled)
	skeleton.add_child(instance)
	instance.skeleton = NodePath("..")
	return instance


## Puts the turns and moves on the skeleton.
func apply() -> void:
	for i in heads.size():
		skeleton.set_bone_pose_rotation(i, turns[i])
		skeleton.set_bone_pose_position(i, _rest_offset(i) + moves[i])


## Where a bone is and how it is turned, in model space, from the turns and
## moves as they are now (not yet applied).
func global_of(i: int) -> Transform3D:
	var here := Transform3D(Basis(turns[i]), _rest_offset(i) + moves[i])
	return global_of(parents[i]) * here if parents[i] >= 0 else here


## Sets a bone's turn so that, in model space, it is turned by `basis`
## (whatever its parents are doing).
func turn_globally(i: int, basis: Basis) -> void:
	var parent := global_of(parents[i]).basis if parents[i] >= 0 else Basis.IDENTITY
	turns[i] = (parent.inverse() * basis).get_rotation_quaternion()


## Where a point fixed to bone `i` (given in rest model space) is now.
func point_on(i: int, rest_point: Vector3) -> Vector3:
	return global_of(i) * (rest_point - heads[i])


# --- Weighing helpers ----------------------------------------------------------

## Distance from p to the segment a-b.
static func to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## 0 at `from`, 1 at `to`, smooth between (either way round).
static func ramp(from: float, to: float, x: float) -> float:
	var t := clampf((x - from) / (to - from), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
