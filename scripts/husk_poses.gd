class_name HuskPoses
extends RefCounted
## The paper husk's stances, posed by hand. They use the same kind of pose as
## the Ronin (see samurai_animator.gd for what each entry means): where the
## hips, hands and feet ARE, and how the back and head bend. The skeleton is
## then bent to fit by SamuraiAnimator.apply().
##
## Directions: X = its left, Y = up, Z = the way it faces. Metres and degrees.
##
## The husk is a villager the Rain has soaked until it forgot its shape: it
## hangs from the shoulders like wet paper, head lolling to one side, feet
## dragging. Everything it does starts from that slump.

const HANG_L := Vector3(0.16, -0.2, 0.1)   # left hand hanging, a little forward
const HANG_R := Vector3(-0.16, -0.2, 0.1)


## A full pose for the husk: the Ronin's standing pose with the husk's own
## limp hands, and the given changes.
static func _pose(changes: Dictionary) -> Dictionary:
	return SamuraiAnimator.stance(changes, {"hand_l": HANG_L, "hand_r": HANG_R,
			"foot_l": Vector3(0.1, 0.0, 0.0), "foot_r": Vector3(-0.1, 0.0, 0.0)})


## The shamble it patrols with. `phase` goes 0 to 1 over a full stride: short,
## dragging steps, the body rolling over each one, arms swinging dead.
static func shamble(phase: float) -> Dictionary:
	var a := phase * TAU
	var left := _drag(phase)
	var right := _drag(fposmod(phase + 0.5, 1.0))
	return _pose({
		"hips": Vector3(sin(a) * 0.02, -0.05 + absf(sin(a)) * 0.015, 0.0),
		"hips_rot": Vector3(8.0, sin(a) * 6.0, sin(a) * 4.0),
		"spine": Vector3(24.0, -sin(a) * 6.0, -sin(a) * 5.0),
		"head": Vector3(26.0, 0.0, 22.0 + sin(a * 0.5) * 5.0),
		"foot_l": Vector3(0.1, left.y, left.z), "toe_l": left.x,
		"foot_r": Vector3(-0.1, right.y, right.z), "toe_r": right.x,
		"hand_l": HANG_L + Vector3(0.0, 0.0, -sin(a) * 0.07),
		"hand_r": HANG_R + Vector3(0.0, 0.0, sin(a) * 0.07),
	})


## One foot's path through a shuffling stride: (toe angle, height, forward).
## It barely leaves the ground.
static func _drag(p: float) -> Vector3:
	if p < 0.55:
		var plant := p / 0.55
		return Vector3(0.0, 0.0, lerpf(0.13, -0.13, plant))
	var swing := (p - 0.55) / 0.45
	return Vector3(lerpf(25.0, 0.0, swing), sin(PI * swing) * 0.05, lerpf(-0.13, 0.13, smoothstep(0.0, 1.0, swing)))


## The tell, `u` 0 to 1 over the wind-up. It drags itself upright for the
## first time, rears back, and lifts both arms high behind its head (both, so
## the tell reads whichever way it faces). The head comes up last, as if it
## has just remembered something.
static func windup(u: float) -> Dictionary:
	var rear := smoothstep(0.0, 0.7, u)
	var poised := _pose({
		"hips": Vector3(0.0, -0.02, -0.04), "hips_rot": Vector3(-8.0, 18.0, 0.0),
		"spine": Vector3(-14.0, 24.0, 0.0), "head": Vector3(-6.0, -18.0, 6.0),
		"foot_l": Vector3(0.1, 0.0, 0.18), "foot_r": Vector3(-0.11, 0.0, -0.16), "toe_r": 15.0,
		"hand_r": Vector3(-0.2, 0.58, -0.3),
		"hand_l": Vector3(0.22, 0.52, -0.26),
	})
	return SamuraiAnimator.mix(shamble(0.0), poised, rear)


## The swipe: lunging forward over its front foot, both raised arms raked
## down in front of it.
static func strike() -> Dictionary:
	return _pose({
		"hips": Vector3(0.0, -0.1, 0.12), "hips_rot": Vector3(22.0, -20.0, 0.0),
		"spine": Vector3(26.0, -24.0, 0.0), "head": Vector3(-10.0, 16.0, 0.0),
		"foot_l": Vector3(0.1, 0.0, 0.32), "foot_r": Vector3(-0.11, 0.04, -0.24), "toe_r": 40.0,
		"hand_r": Vector3(-0.04, 0.02, 0.5),
		"hand_l": Vector3(0.14, 0.1, 0.46),
	})


## Folded over at the waist: its posture broken. Knees giving, back bent
## nearly flat, arms hanging to the street, head hanging lowest of all. It
## sways very slowly, like a wet sheet on a line.
static func stagger(time: float) -> Dictionary:
	var sway := sin(time * 1.3)
	return _pose({
		"hips": Vector3(0.0, -0.16, -0.06), "hips_rot": Vector3(30.0, 0.0, sway * 2.0),
		"spine": Vector3(48.0, 0.0, sway * 4.0), "head": Vector3(30.0, 0.0, 18.0),
		"foot_l": Vector3(0.12, 0.0, 0.08), "foot_r": Vector3(-0.12, 0.0, -0.06),
		"hand_l": Vector3(0.14, -0.4, 0.42 + sway * 0.02),
		"hand_r": Vector3(-0.14, -0.42, 0.4 - sway * 0.02),
	})


## A quick shove, `u` 0 to 1, when the Ronin walks into it: no wind-up, just
## both hands jabbed out low in front, a lurch onto the front foot, and back
## to its slump. Much smaller than the swipe.
static func shove(u: float) -> Dictionary:
	var jab := _pose({
		"hips": Vector3(0.0, -0.06, 0.06), "hips_rot": Vector3(16.0, 0.0, 0.0),
		"spine": Vector3(18.0, 0.0, 0.0), "head": Vector3(6.0, 0.0, 10.0),
		"foot_l": Vector3(0.1, 0.0, 0.16), "foot_r": Vector3(-0.1, 0.0, -0.1),
		"hand_l": Vector3(0.12, 0.1, 0.42), "hand_r": Vector3(-0.12, 0.08, 0.44),
	})
	# Out fast (the first quarter), back slowly.
	var out := smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(0.45, 1.0, u))
	return SamuraiAnimator.mix(shamble(0.0), jab, out)
