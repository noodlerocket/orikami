class_name HannyaPoses
extends RefCounted
## The Weeping Hannya's stances, posed by hand, in the same kind of pose as
## the Ronin and the husk (see samurai_animator.gd for what each entry
## means). She is 2.6 m tall, so her distances are about 1.6 times his.
##
## Directions: X = her left, Y = up, Z = the way she faces. Metres, degrees.

const HANG_L := Vector3(0.3, -0.12, 0.08)
const HANG_R := Vector3(-0.3, -0.12, 0.08)


static func _pose(changes: Dictionary) -> Dictionary:
	return SamuraiAnimator.stance(changes, {"hand_l": HANG_L, "hand_r": HANG_R,
			"foot_l": Vector3(0.16, 0.0, 0.0), "foot_r": Vector3(-0.16, 0.0, 0.0)})


## Kneeling (seiza) behind the screen, weeping: bowed low, hands over her
## face. (She kneels side-on to the paper, so her shadow is her profile.) `time`
## drives the sobbing: bursts of shaking shoulders, then stillness.
## `stillness` 1 stops the sobs (the moment she hears him).
static func weep(time: float, stillness: float = 0.0) -> Dictionary:
	var burst := maxf(sin(time * 1.1), 0.0) * (1.0 - stillness)
	var shake := sin(time * 11.0) * burst
	return _pose({
		"hips": Vector3(0.0, -0.78, -0.1), "hips_rot": Vector3(14.0, 0.0, 0.0),
		"spine": Vector3(34.0 + shake * 4.0 + burst * 3.0, 0.0, 0.0),
		"head": Vector3(26.0 + shake * 3.0, 0.0, 4.0),
		"foot_l": Vector3(0.14, 0.04, -0.62), "toe_l": 85.0,
		"foot_r": Vector3(-0.14, 0.04, -0.62), "toe_r": 85.0,
		"reach_l": Vector3(0.1, 0.38 + shake * 0.015, 0.32), "aim_l": 1.0,
		"reach_r": Vector3(-0.1, 0.38 - shake * 0.015, 0.32), "aim_r": 1.0,
	})


## The turn: `u` 0 to 1. Still kneeling, her hands fall from her face, her
## back straightens and her head comes up; the horns stand up in the
## silhouette. (The cutscene also turns her whole body round to the paper.)
static func turn(u: float) -> Dictionary:
	var lift := smoothstep(0.0, 0.5, u)
	var round := smoothstep(0.35, 1.0, u)
	var pose := weep(0.0, 1.0)
	pose["spine"] = Vector3(lerpf(34.0, -4.0, lift), 0.0, 0.0)
	pose["head"] = Vector3(lerpf(26.0, -6.0, lift), 0.0, lerpf(4.0, 10.0, round))
	pose["reach_l"] = (pose["reach_l"] as Vector3).lerp(Vector3(0.36, -0.2, 0.18), lift)
	pose["reach_r"] = (pose["reach_r"] as Vector3).lerp(Vector3(-0.36, -0.2, 0.18), lift)
	return pose


## Rising from her knees to her full height, `u` 0 to 1, arms lifting out
## to her sides so the long sleeves open like wings.
static func rise(u: float) -> Dictionary:
	var up := smoothstep(0.0, 0.8, u)
	var spread := smoothstep(0.3, 1.0, u)
	var kneel := turn(1.0)
	var tall := _pose({
		"hips": Vector3(0.0, 0.0, 0.0), "hips_rot": Vector3(-4.0, 0.0, 0.0),
		"spine": Vector3(-8.0, 0.0, 0.0), "head": Vector3(-4.0, 0.0, 12.0),
		"foot_l": Vector3(0.2, 0.0, 0.06), "foot_r": Vector3(-0.2, 0.0, -0.06),
		"reach_l": Vector3(0.75, 0.05, 0.2), "aim_l": 1.0,
		"reach_r": Vector3(-0.75, 0.05, 0.2), "aim_r": 1.0,
	})
	var pose := SamuraiAnimator.mix(kneel, tall, up)
	pose["reach_l"] = (kneel["reach_l"] as Vector3).lerp(tall["reach_l"], spread)
	pose["reach_r"] = (kneel["reach_r"] as Vector3).lerp(tall["reach_r"], spread)
	return pose


## A sleeve slash, `u` 0 to 1: her right arm drawn up high behind her,
## then swept down and across in front, the sleeve following like a blade.
static func slash(u: float) -> Dictionary:
	var swing := smoothstep(0.35, 0.65, u)
	var raised := _pose({
		"hips": Vector3(0.0, -0.05, -0.05), "hips_rot": Vector3(-6.0, 20.0, 0.0),
		"spine": Vector3(-10.0, 26.0, 0.0), "head": Vector3(-6.0, -20.0, 10.0),
		"foot_l": Vector3(0.2, 0.0, 0.2), "foot_r": Vector3(-0.2, 0.0, -0.2),
		"reach_r": Vector3(-0.4, 0.75, -0.35), "aim_r": 1.0,
		"reach_l": Vector3(0.6, 0.0, 0.25), "aim_l": 1.0,
	})
	var swept := _pose({
		"hips": Vector3(0.0, -0.12, 0.12), "hips_rot": Vector3(14.0, -24.0, 0.0),
		"spine": Vector3(20.0, -30.0, 0.0), "head": Vector3(4.0, 20.0, 10.0),
		"foot_l": Vector3(0.2, 0.0, 0.34), "foot_r": Vector3(-0.2, 0.0, -0.24),
		"reach_r": Vector3(0.45, -0.35, 0.55), "aim_r": 1.0,
		"reach_l": Vector3(0.6, 0.1, -0.1), "aim_l": 1.0,
	})
	return SamuraiAnimator.mix(raised, swept, swing)


## Towering, arms low and wide so the sleeve-blades hang either side of her,
## head tilted. She sways very slowly. `time` drives the sway.
static func menace(time: float) -> Dictionary:
	var sway := sin(time * 0.9)
	return _pose({
		"hips": Vector3(sway * 0.03, 0.0, 0.0), "hips_rot": Vector3(-2.0, sway * 4.0, sway * 2.0),
		"spine": Vector3(6.0, -sway * 5.0, 0.0), "head": Vector3(8.0, sway * 6.0, 16.0),
		"foot_l": Vector3(0.22, 0.0, 0.08), "foot_r": Vector3(-0.22, 0.0, -0.08),
		"reach_l": Vector3(0.62, -0.42, 0.22), "aim_l": 1.0,
		"reach_r": Vector3(-0.62, -0.42, 0.22), "aim_r": 1.0,
	})


## Standing, weeping into her hands (the ink rain): bowed, both hands over
## the mask, shoulders shaking.
static func cover_face(time: float) -> Dictionary:
	var shake := sin(time * 10.0) * maxf(sin(time * 1.7), 0.2)
	return _pose({
		"hips": Vector3(0.0, -0.06, -0.04), "hips_rot": Vector3(6.0, 0.0, 0.0),
		"spine": Vector3(26.0 + shake * 3.0, 0.0, 0.0), "head": Vector3(22.0 + shake * 2.0, 0.0, 6.0),
		"foot_l": Vector3(0.18, 0.0, 0.05), "foot_r": Vector3(-0.18, 0.0, -0.05),
		"reach_l": Vector3(0.1, 0.36 + shake * 0.012, 0.3), "aim_l": 1.0,
		"reach_r": Vector3(-0.1, 0.36 - shake * 0.012, 0.3), "aim_r": 1.0,
	})


## Drifting low across the ground like a ghost: leaning hard into it, arms
## swept back so the sleeves stream behind her, feet trailing off the ground.
static func glide() -> Dictionary:
	return _pose({
		"hips": Vector3(0.0, 0.25, 0.0), "hips_rot": Vector3(34.0, 0.0, 0.0),
		"spine": Vector3(18.0, 0.0, 0.0), "head": Vector3(-26.0, 0.0, 0.0),
		"foot_l": Vector3(0.14, 0.32, -0.5), "toe_l": 70.0,
		"foot_r": Vector3(-0.14, 0.22, -0.42), "toe_r": 70.0,
		"reach_l": Vector3(0.45, -0.2, -0.6), "aim_l": 1.0,
		"reach_r": Vector3(-0.45, -0.2, -0.6), "aim_r": 1.0,
	})


## Gathering herself before a glide: she leans back and spreads her arms
## wide, so the long sleeves open like wings (she also rises off the ground:
## hannya_boss.gd lifts her).
static func glide_tell(u: float) -> Dictionary:
	var wings := _pose({
		"hips": Vector3(0.0, 0.0, -0.1), "hips_rot": Vector3(-16.0, 0.0, 0.0),
		"spine": Vector3(-14.0, 0.0, 0.0), "head": Vector3(-20.0, 0.0, 14.0),
		"foot_l": Vector3(0.14, 0.12, -0.1), "toe_l": 60.0,
		"foot_r": Vector3(-0.14, 0.06, -0.2), "toe_r": 65.0,
		"reach_l": Vector3(0.95, 0.35, -0.2), "aim_l": 1.0,
		"reach_r": Vector3(-0.95, 0.35, -0.2), "aim_r": 1.0,
	})
	return SamuraiAnimator.mix(menace(0.0), wings, smoothstep(0.0, 0.7, u))


## Staggered (her posture broken): sunk to her knees, weeping, still.
static func broken(time: float) -> Dictionary:
	return weep(time * 0.4)


## Defeated: `u` 0 to 1, she folds forward until her mask touches the ground.
static func fall(u: float) -> Dictionary:
	var pose := weep(0.0, 1.0)
	pose["spine"] = Vector3(lerpf(34.0, 70.0, smoothstep(0.0, 1.0, u)), 0.0, 0.0)
	pose["head"] = Vector3(lerpf(26.0, 40.0, u), 0.0, lerpf(4.0, 20.0, u))
	pose["reach_l"] = Vector3(0.3, lerpf(0.38, -0.5, u), lerpf(0.32, 0.6, u))
	pose["reach_r"] = Vector3(-0.3, lerpf(0.38, -0.5, u), lerpf(0.32, 0.6, u))
	return pose
