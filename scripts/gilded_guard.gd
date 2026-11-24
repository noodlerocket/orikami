class_name GildedGuard
extends PaperHusk
## A gilded guard (the Gilded Terraces): one of Hōshō's people, a husk under
## gold leaf; like him it hides from the Rain under gold and feels nothing.
## Its gold turns cuts from the front aside (a clang, gold sparks, no harm)
## until one of its swipes is parried: the parry cracks its gold, flakes of
## leaf fall away, and from then on it can be cut, staggered and finished
## like any husk. Cuts from behind always bite.

## The gold leaf over it, and what shows when it has cracked.
const GILT := Color(1.0, 0.8, 0.42)
const CRACKED := Color(0.78, 0.7, 0.58)

var cracked := false


func _ready() -> void:
	max_health = 4
	max_posture = 2
	soak_tint = GILT
	super._ready()
	for m: StandardMaterial3D in _materials:
		m.metallic = 0.55
		m.roughness = 0.35
		m.metallic_specular = 0.8


func take_hit(damage: int, direction: Vector2) -> void:
	# From the front (the cut travelling at its face) its gold turns it.
	var from_front := direction.x != 0.0 and signf(direction.x) == -_dir
	if not cracked and from_front and mode != &"stagger":
		Sound.play(self, &"parry", -3.0)
		Confetti.burst(get_parent(), global_position + Vector3(_dir * 0.3, 1.0, 0.0), 8, [GILT, Color(1.0, 0.92, 0.6)])
		velocity.x = signf(direction.x) * 1.5   # (a step back)
		return
	super.take_hit(damage, direction)


func _on_parried() -> void:
	if not cracked:
		cracked = true
		# The gold cracks and flakes away: under it, plain paper.
		Sound.play(self, &"paper_rip", 0.0)
		Confetti.burst(get_parent(), global_position + Vector3(0.0, 0.9, 0.0), 30, [GILT, Color(0.9, 0.7, 0.3), Color(1.0, 0.92, 0.6)])
		for m: StandardMaterial3D in _materials:
			m.albedo_color = CRACKED
			m.metallic = 0.1
			m.roughness = 0.9
	super._on_parried()
