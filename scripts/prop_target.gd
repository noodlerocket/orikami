class_name PropTarget
extends StaticBody3D
## Something in the scenery the Ronin's sword can strike: a lantern, a shop
## sign, a shoji door. It sits on the enemies' physics layer, so the cut's
## shape query finds it, but it is not an enemy: the cut bounces (pogo) and
## recoils as usual, and gives no ink (Ronin checks `is_prop`). Whatever owns
## it listens to `struck` and reacts.

signal struck(direction: Vector2)


static func make(owner_node: Node3D, shape: Shape3D, at: Vector3) -> PropTarget:
	var target := PropTarget.new()
	target.collision_layer = 4  # "enemies": what the cut looks for
	target.collision_mask = 0
	var holder := CollisionShape3D.new()
	holder.shape = shape
	target.add_child(holder)
	target.position = at
	owner_node.add_child(target)
	return target


func take_hit(_damage: int, direction: Vector2) -> void:
	struck.emit(direction)


func is_prop() -> bool:
	return true
