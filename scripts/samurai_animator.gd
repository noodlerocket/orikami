class_name SamuraiAnimator
extends RefCounted
## Hand-made animation for the sculpted Ronin.
##
## Instead of playing ready-made clips, this script POSES his skeleton
## directly, the way an animator poses a stop-motion figure. A pose is a
## small list of instructions:
##
##   "hips"      where the hips are (metres: left, up, forward) from standing
##   "hips_rot"  how the hips are turned (degrees: lean forward, turn left, tip right)
##   "spine"     how far the back bends from there (same three angles)
##   "head"      how the head is turned (same three angles; lean forward = bow)
##   "foot_l/r"  where each ankle is (metres: left, height off the ground, forward)
##   "toe_l/r"   how far each foot points down (degrees)
##   "hand_l/r"  where each hand is, measured from the hips
##   "reach_l/r" where each hand is, measured from the chest (used for sword cuts)
##   "aim_l/r"   0 = use "hand", 1 = use "reach"
##   "blade"     which way the drawn sword points (up and forward, as you see
##               it from the side); "blade_out" 1 = the sword is drawn
##
## You only say where the hands and feet should BE. The script works out how
## the elbows and knees must bend to get them there (this is called inverse
## kinematics). That is why his hand can rest exactly on the sword handle and
## his feet stay planted when he crouches.
##
## Directions: X = his left, Y = up, Z = the way he faces.
##
## The stances are in the second half of this file. Change the numbers there
## to change how he stands, runs, jumps and cuts.

# Where the sculpted sword is on the model, measured from the hips.
const HILT := Vector3(0.105, 0.085, 0.23)    # the handle: right hand rests here
const SAYA := Vector3(0.16, 0.015, 0.075)    # the scabbard's mouth: left hand holds here
## The line the sword slides along as it leaves the scabbard (forward and up).
const DRAW := Vector3(-0.25, 0.47, 0.84)
const HANG_L := Vector3(0.2, -0.07, 0.0)     # left hand hanging loose
const HANG_R := Vector3(-0.21, -0.07, 0.03)  # right hand hanging loose

## Every pose starts from this one; a stance only lists what it changes.
const STAND := {
	"hips": Vector3.ZERO, "hips_rot": Vector3.ZERO, "spine": Vector3.ZERO, "head": Vector3.ZERO,
	"foot_l": Vector3(0.12, 0.0, -0.06), "foot_r": Vector3(-0.13, 0.0, -0.07),
	"toe_l": 0.0, "toe_r": 0.0,
	"hand_l": SAYA, "hand_r": HILT, "reach_l": Vector3.ZERO, "reach_r": Vector3.ZERO,
	"aim_l": 0.0, "aim_r": 0.0,
	"blade": Vector3(0.0, 0.0, 1.0), "blade_out": 0.0,
}
## The parts of a pose that belong to the upper body (used to cut while running).
const UPPER := ["spine", "head", "hand_l", "hand_r", "reach_l", "reach_r", "aim_l", "aim_r", "blade", "blade_out"]

var skeleton: Skeleton3D
## Where the drawn sword should be after the last apply(), in skeleton space.
var sword_at := Vector3.ZERO
var sword_dir := Vector3.FORWARD
var sword_out := false
## How the hips are turned after the last apply(), in skeleton space.
var hips_turn := Basis.IDENTITY

var _unit := 100.0        # skeleton units per metre (Meshy rigs are in centimetres)
var _bone := {}           # bone name -> index
var _spine: Array[int] = []
var _canon := {}          # bone index -> its rest orientation, with limbs straightened
var _rest := {}           # bone index -> its rest position
var _length := {}         # bone index -> distance to the next joint down the limb


func _init(target: Skeleton3D, units_per_metre: float) -> void:
	skeleton = target
	_unit = units_per_metre
	for i in skeleton.get_bone_count():
		_bone[skeleton.get_bone_name(i)] = i
		_rest[i] = skeleton.get_bone_global_rest(i).origin
		_canon[i] = skeleton.get_bone_global_rest(i).basis.orthonormalized()
	# The spine bones, from the hips upward.
	var at: int = _bone["Hips"]
	while true:
		var next := -1
		for child: int in skeleton.get_bone_children(at):
			if skeleton.get_bone_name(child).begins_with("Spine"):
				next = child
		if next < 0:
			break
		_spine.append(next)
		at = next
	# The model was sculpted with its arms held out. Work out each limb bone's
	# orientation as if it hung straight down, so a pose can simply say
	# "point this bone that way".
	for side: String in ["Left", "Right"]:
		_straighten([side + "Arm", side + "ForeArm", side + "Hand"])
		_straighten([side + "UpLeg", side + "Leg", side + "Foot"])


func _straighten(chain: Array) -> void:
	for k in chain.size() - 1:
		var here: int = _bone[chain[k]]
		var there: int = _bone[chain[k + 1]]
		var along: Vector3 = _rest[there] - _rest[here]
		_length[here] = along.length()
		_canon[here] = Basis(Quaternion(along.normalized(), Vector3.DOWN)) * _canon[here]
		if chain[k + 1].ends_with("Hand"):
			_canon[there] = Basis(Quaternion(along.normalized(), Vector3.DOWN)) * _canon[there]


# --- Posing the skeleton --------------------------------------------------------

## Puts the skeleton into `pose` (a full pose: see STAND).
func apply(pose: Dictionary) -> void:
	var hips: int = _bone["Hips"]
	var hips_at: Vector3 = _rest[hips] + (pose["hips"] as Vector3) * _unit
	skeleton.set_bone_pose_position(hips, hips_at)
	var turn := _turn(pose["hips_rot"])
	hips_turn = turn
	_point(hips, turn * _canon[hips])

	# Back and head. The bend is shared out between the three spine bones.
	var back := turn
	var share := _turn((pose["spine"] as Vector3) / maxf(_spine.size(), 1.0))
	for bone: int in _spine:
		back = back * share
		_point(bone, back * _canon[bone])
	_point(_bone["neck"], back * _turn((pose["head"] as Vector3) * 0.4) * _canon[_bone["neck"]])
	_point(_bone["Head"], back * _turn(pose["head"]) * _canon[_bone["Head"]])
	for side: String in ["Left", "Right"]:
		_point(_bone[side + "Shoulder"], back * _canon[_bone[side + "Shoulder"]])

	var facing := Basis(Vector3.UP, deg_to_rad((pose["hips_rot"] as Vector3).y))

	# Arms: find where each hand should be, then bend the elbow to reach it.
	var chest: Vector3 = skeleton.get_bone_global_pose(_spine[_spine.size() - 1]).origin
	for side: String in ["Left", "Right"]:
		var s := "l" if side == "Left" else "r"
		var from_hips: Vector3 = hips_at + turn * ((pose["hand_" + s] as Vector3) * _unit)
		var from_chest: Vector3 = chest + back * ((pose["reach_" + s] as Vector3) * _unit)
		var target := from_hips.lerp(from_chest, pose["aim_" + s])
		var out := 0.5 if side == "Left" else -0.5
		_reach(_bone[side + "Arm"], _bone[side + "ForeArm"], _bone[side + "Hand"], target,
				back * Vector3(out, -0.5, -0.8))

	# Legs: the same, with the knees pointing forward.
	var middle := Vector3(_rest[hips].x, 0.0, _rest[hips].z)
	for side: String in ["Left", "Right"]:
		var s := "l" if side == "Left" else "r"
		var foot: int = _bone[side + "Foot"]
		var ankle: Vector3 = middle + (pose["foot_" + s] as Vector3) * _unit + Vector3(0.0, _rest[foot].y, 0.0)
		var out := 0.2 if side == "Left" else -0.2
		_reach(_bone[side + "UpLeg"], _bone[side + "Leg"], -1, ankle, facing * Vector3(out, 0.0, 1.0))
		var tilt := facing * Basis(Vector3.RIGHT, deg_to_rad(pose["toe_" + s]))
		_point(foot, tilt * _canon[foot])
		_point(_bone[side + "ToeBase"], tilt * _canon[_bone[side + "ToeBase"]])

	# The drawn sword sits in the right fist.
	sword_at = skeleton.get_bone_global_pose(_bone["RightHand"]).origin
	sword_dir = (facing * (pose["blade"] as Vector3)).normalized()
	sword_out = pose["blade_out"] > 0.5


## Turns one bone to face a given way, whatever its parent is doing.
func _point(bone: int, basis: Basis) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := Basis.IDENTITY
	if parent >= 0:
		parent_basis = skeleton.get_bone_global_pose(parent).basis.orthonormalized()
	skeleton.set_bone_pose_rotation(bone, (parent_basis.inverse() * basis).get_rotation_quaternion())


## Bends a two-part limb (upper arm + forearm, or thigh + shin) so its end
## reaches `target`. `bend_toward` says which way the elbow or knee points.
func _reach(upper: int, lower: int, end: int, target: Vector3, bend_toward: Vector3) -> void:
	var start: Vector3 = skeleton.get_bone_global_pose(upper).origin
	var a: float = _length[upper]
	var b: float = _length[lower]
	var to := target - start
	var far := clampf(to.length(), absf(a - b) + 0.5, a + b - 0.1)
	var along := to.normalized()
	var cos_bend := clampf((a * a + far * far - b * b) / (2.0 * a * far), -1.0, 1.0)
	var sideways := (bend_toward - along * bend_toward.dot(along)).normalized()
	var joint := start + along * (a * cos_bend) + sideways * (a * sqrt(1.0 - cos_bend * cos_bend))
	var upper_dir := (joint - start).normalized()
	var lower_dir := (start + along * far - joint).normalized()
	var upper_turn := Basis(Quaternion(Vector3.DOWN, upper_dir))
	var lower_turn := Basis(Quaternion(upper_dir, lower_dir)) * upper_turn
	_point(upper, upper_turn * _canon[upper])
	_point(lower, lower_turn * _canon[lower])
	if end >= 0:
		_point(end, lower_turn * _canon[end])


static func _turn(degrees: Vector3) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z)))


# --- Working with poses -----------------------------------------------------------

## A full pose: STAND with the given changes.
static func stance(changes: Dictionary, more: Dictionary = {}) -> Dictionary:
	var pose := STAND.duplicate()
	pose.merge(more, true)
	pose.merge(changes, true)
	return pose


## A pose part-way between two full poses (0 = all `a`, 1 = all `b`).
static func mix(a: Dictionary, b: Dictionary, amount: float) -> Dictionary:
	var out := {}
	for key: String in STAND:
		if a[key] is Vector3:
			out[key] = (a[key] as Vector3).lerp(b[key], amount)
		else:
			out[key] = lerpf(a[key], b[key], amount)
	# A hand that is not "reaching" in one pose has no meaningful reach point
	# there, so borrow the other pose's (and the other way round).
	for s: String in ["l", "r"]:
		if a["aim_" + s] <= 0.0:
			out["reach_" + s] = b["reach_" + s]
		elif b["aim_" + s] <= 0.0:
			out["reach_" + s] = a["reach_" + s]
		if a["aim_" + s] >= 1.0:
			out["hand_" + s] = b["hand_" + s]
		elif b["aim_" + s] >= 1.0:
			out["hand_" + s] = a["hand_" + s]
	return out


## `legs` with the upper body of `top` laid over it.
static func with_upper_body(legs: Dictionary, top: Dictionary) -> Dictionary:
	var pose := legs.duplicate()
	for key: String in UPPER:
		pose[key] = top[key]
	return pose


## Picks the pose at time `u` (0 to 1) from a list of [time, pose] keys.
static func along(keys: Array, u: float) -> Dictionary:
	for i in keys.size() - 1:
		var t0: float = keys[i][0]
		var t1: float = keys[i + 1][0]
		if u <= t1:
			return mix(keys[i][1], keys[i + 1][1], smoothstep(t0, t1, u))
	return keys[keys.size() - 1][1]


# =================================================================================
#  THE STANCES
#  Angles are degrees (lean forward, turn left, tip right). Distances are metres.
# =================================================================================

## Standing at ease: weight back, left hand on the scabbard, head bowed so the
## hat hides his eyes. He breathes slowly.
static func idle(time: float) -> Dictionary:
	var breath := sin(time * 1.9)
	return stance({
		"hips": Vector3(0.0, -0.035 + breath * 0.006, -0.01),
		"hips_rot": Vector3(2.0, 0.0, 0.0),
		"spine": Vector3(5.0 + breath * 1.5, 0.0, 0.0),
		"head": Vector3(9.0 - breath * 1.0, 0.0, 0.0),
		"foot_l": Vector3(0.15, 0.0, -0.15), "foot_r": Vector3(-0.14, 0.0, 0.07),
		"hand_r": HANG_R + Vector3(0.0, breath * 0.004, 0.0),
	})


## The samurai run: a straight back tipped forward from the hips, so his
## weight is over his front foot rather than hunched over it. Head level,
## both hands on the sword so it does not swing. Only the legs move.
## `phase` goes 0 to 1 over one full stride.
static func run(phase: float) -> Dictionary:
	var left := _stride(phase)
	var right := _stride(fposmod(phase + 0.5, 1.0))
	var bounce := absf(sin(phase * TAU))
	return stance({
		"hips": Vector3(0.0, -0.1 + bounce * 0.035, 0.09),
		"hips_rot": Vector3(19.0, sin(phase * TAU) * 7.0, 0.0),
		"spine": Vector3(8.0, -sin(phase * TAU) * 9.0, 0.0),
		"head": Vector3(-23.0, 0.0, 0.0),
		"foot_l": Vector3(0.1, left.y, left.z), "toe_l": left.x,
		"foot_r": Vector3(-0.11, right.y, right.z), "toe_r": right.x,
		"hand_r": HILT + Vector3(0.0, bounce * 0.008, 0.0),
	})


## One foot's path through a stride: (toe angle, height, forward).
## The foot is on the ground for the first 40%, then swings through with the
## heel kicked up behind.
static func _stride(p: float) -> Vector3:
	if p < 0.4:
		var plant := p / 0.4
		return Vector3(lerpf(-12.0, 38.0, plant * plant), plant * plant * 0.05, lerpf(0.4, -0.38, plant))
	var swing := (p - 0.4) / 0.6
	var lift := sin(PI * pow(swing, 0.75))
	return Vector3(lerpf(62.0, -12.0, swing), 0.05 + lift * 0.27, lerpf(-0.38, 0.4, smoothstep(0.0, 1.0, swing)))


## In the air. `rise` is 1 at take-off and 0 at the top of the jump;
## `drop` is 0 at the top and grows to 1 as he falls faster.
static func air(rise: float, drop: float) -> Dictionary:
	# Take-off: one knee drives up, the other leg trails, pointed.
	var launch := stance({
		"hips_rot": Vector3(4.0, 0.0, 0.0), "spine": Vector3(-6.0, 0.0, 0.0), "head": Vector3(-8.0, 0.0, 0.0),
		"foot_r": Vector3(-0.12, 0.3, 0.2), "toe_r": 25.0,
		"foot_l": Vector3(0.1, 0.0, -0.24), "toe_l": 60.0,
		"hand_r": Vector3(-0.25, 0.0, -0.2),
	})
	# Top of the jump: knees tucked, hand finds the sword.
	var top := stance({
		"hips_rot": Vector3(12.0, 0.0, 0.0), "spine": Vector3(14.0, 0.0, 0.0), "head": Vector3(4.0, 0.0, 0.0),
		"foot_r": Vector3(-0.12, 0.38, 0.16), "toe_r": 35.0,
		"foot_l": Vector3(0.11, 0.3, -0.1), "toe_l": 45.0,
	})
	# Falling: legs reach for the ground, sword arm flung out for balance,
	# eyes down.
	var falling := stance({
		"hips_rot": Vector3(6.0, 0.0, 0.0), "spine": Vector3(12.0, 0.0, 0.0), "head": Vector3(18.0, 0.0, 0.0),
		"foot_r": Vector3(-0.13, 0.13, 0.24), "toe_r": 30.0,
		"foot_l": Vector3(0.12, 0.3, -0.2), "toe_l": 60.0,
		"reach_r": Vector3(-0.2, 0.26, -0.22), "aim_r": 1.0,
	})
	if rise > 0.0:
		return mix(top, launch, pow(rise, 0.7))
	return mix(top, falling, smoothstep(0.0, 0.45, drop))


## Touching down: a deep crouch, hand on the sword. `settle` goes 0 to 1 as
## he straightens up again.
static func land(settle: float) -> Dictionary:
	var crouch := stance({
		"hips": Vector3(0.0, -0.3, 0.02), "hips_rot": Vector3(8.0, 0.0, 0.0),
		"spine": Vector3(26.0, 0.0, 0.0), "head": Vector3(-16.0, 0.0, 0.0),
		"foot_r": Vector3(-0.16, 0.0, 0.17), "foot_l": Vector3(0.15, 0.04, -0.22), "toe_l": 38.0,
	})
	return mix(crouch, idle(0.0), smoothstep(0.35, 1.0, settle))


## The dash: he throws himself forward, almost flat, head leading, back leg
## trailing straight out behind, both hands on the sword.
static func dash() -> Dictionary:
	return stance({
		"hips": Vector3(0.0, -0.3, 0.22), "hips_rot": Vector3(42.0, 0.0, 0.0),
		"spine": Vector3(24.0, 0.0, 0.0), "head": Vector3(-58.0, 0.0, 0.0),
		"foot_r": Vector3(-0.12, 0.0, 0.52), "toe_r": -10.0,
		"foot_l": Vector3(0.12, 0.16, -0.66), "toe_l": 75.0,
	})


## Struck: thrown back, arms flung wide.
static func hurt() -> Dictionary:
	return stance({
		"hips_rot": Vector3(-14.0, 0.0, 0.0), "spine": Vector3(-22.0, 0.0, 8.0), "head": Vector3(-22.0, 0.0, 0.0),
		"foot_r": Vector3(-0.14, 0.12, 0.22), "foot_l": Vector3(0.13, 0.04, -0.12), "toe_l": 30.0,
		"reach_r": Vector3(-0.3, 0.0, 0.2), "aim_r": 1.0,
		"reach_l": Vector3(0.32, -0.04, 0.18), "aim_l": 1.0,
	})


## Healing: down on one knee, head bowed, one hand raised before the chest.
static func heal(time: float) -> Dictionary:
	var breath := sin(time * 1.9)
	return stance({
		"hips": Vector3(0.0, -0.4, 0.0), "hips_rot": Vector3(4.0, 0.0, 0.0),
		"spine": Vector3(10.0 + breath, 0.0, 0.0), "head": Vector3(24.0, 0.0, 0.0),
		"foot_r": Vector3(-0.15, 0.0, 0.3), "foot_l": Vector3(0.13, 0.02, -0.34), "toe_l": 70.0,
		"reach_r": Vector3(0.02, -0.1, 0.2), "aim_r": 1.0,
	})


## The cut. `u` goes 0 to 1 over the whole slash. `direction` is where the
## player aimed: y above 0.5 = up, below -0.5 = down, otherwise forward.
##
## Every cut is a draw (iaijutsu): the katana slides out of the scabbard at
## his left hip and sweeps round in front of him, level, from one side to
## the other. Nothing chops up and down. Then it goes straight back in.
static func slash(u: float, direction: Vector2) -> Dictionary:
	var feet := {"foot_r": Vector3(-0.14, 0.0, 0.26), "foot_l": Vector3(0.15, 0.0, -0.28)}
	# Half-drawn: the hand has travelled up the line of the scabbard and the
	# blade still points back into it.
	var draw := stance({
		"hips": Vector3(0.0, -0.13, 0.04), "hips_rot": Vector3(8.0, 14.0, 0.0),
		"spine": Vector3(12.0, 20.0, 0.0), "head": Vector3(-8.0, -30.0, 0.0),
		"hand_r": HILT + DRAW * 0.2, "hand_l": SAYA - DRAW * 0.05,
		"blade": -DRAW, "blade_out": 1.0}, feet)
	if direction.y < -0.5:
		# In the air, aiming down: the blade sweeps from in front of him, down
		# and under, finishing pointed at the ground behind his feet.
		var tuck := {"foot_r": Vector3(-0.13, 0.36, 0.14), "toe_r": 40.0, "foot_l": Vector3(0.12, 0.34, -0.12), "toe_l": 50.0}
		return along([
			[0.0, stance({"blade": -DRAW, "blade_out": 1.0, "hand_r": HILT + DRAW * 0.2}, tuck)],
			[0.38, stance({
				"hips_rot": Vector3(8.0, 0.0, 0.0), "spine": Vector3(16.0, -8.0, 0.0), "head": Vector3(20.0, 0.0, 0.0),
				"reach_r": Vector3(-0.12, -0.14, 0.38), "aim_r": 1.0,
				"blade": Vector3(0.0, -0.45, 1.0), "blade_out": 1.0}, tuck)],
			[0.75, stance({
				"hips_rot": Vector3(12.0, 0.0, 0.0), "spine": Vector3(24.0, -14.0, 0.0), "head": Vector3(28.0, 0.0, 0.0),
				"reach_r": Vector3(-0.1, -0.3, 0.2), "aim_r": 1.0,
				"blade": Vector3(0.0, -1.0, 0.1), "blade_out": 1.0}, tuck)],
			[1.0, stance({
				"hips_rot": Vector3(12.0, 0.0, 0.0), "spine": Vector3(24.0, -16.0, 0.0), "head": Vector3(28.0, 0.0, 0.0),
				"reach_r": Vector3(-0.1, -0.3, 0.12), "aim_r": 1.0,
				"blade": Vector3(0.0, -0.92, -0.4), "blade_out": 1.0}, tuck)],
		], u)
	if direction.y > 0.5:
		# Aiming up: the same draw, carried on until the blade stands overhead.
		return along([
			[0.0, draw],
			[0.38, stance({
				"hips": Vector3(0.0, -0.08, 0.04), "spine": Vector3(0.0, -6.0, 0.0), "head": Vector3(-18.0, 0.0, 0.0),
				"reach_r": Vector3(-0.12, 0.08, 0.38), "aim_r": 1.0,
				"blade": Vector3(-0.1, 0.65, 0.75), "blade_out": 1.0}, feet)],
			[0.75, stance({
				"hips": Vector3(0.0, -0.04, 0.03), "spine": Vector3(-10.0, -10.0, 0.0), "head": Vector3(-28.0, 0.0, 0.0),
				"toe_l": 22.0,
				"reach_r": Vector3(-0.1, 0.36, 0.18), "aim_r": 1.0,
				"blade": Vector3(-0.08, 1.0, 0.12), "blade_out": 1.0}, feet)],
			[1.0, stance({
				"hips": Vector3(0.0, -0.03, 0.03), "spine": Vector3(-13.0, -12.0, 0.0), "head": Vector3(-30.0, 0.0, 0.0),
				"toe_l": 25.0,
				"reach_r": Vector3(-0.1, 0.38, 0.1), "aim_r": 1.0,
				"blade": Vector3(-0.08, 1.0, -0.12), "blade_out": 1.0}, feet)],
		], u)
	# Forward: one flat sweep. Out of the scabbard on his left, round in
	# front of him, and away to his right, rising only a little.
	return along([
		[0.0, draw],
		# Half-way round: arm at full stretch, blade level, pointing ahead.
		[0.38, stance({
			"hips": Vector3(0.0, -0.16, 0.1), "hips_rot": Vector3(9.0, -4.0, 0.0),
			"spine": Vector3(13.0, -8.0, 0.0), "head": Vector3(-13.0, 6.0, 0.0),
			"foot_r": Vector3(-0.14, 0.0, 0.4), "foot_l": Vector3(0.15, 0.0, -0.32), "toe_l": 20.0,
			"reach_r": Vector3(-0.12, -0.08, 0.41), "aim_r": 1.0,
			"hand_l": SAYA - DRAW * 0.08,
			"blade": Vector3(0.1, 0.06, 1.0), "blade_out": 1.0})],
		# All the way round: arm flung out to his right, body opened up.
		[0.75, stance({
			"hips": Vector3(0.0, -0.16, 0.12), "hips_rot": Vector3(8.0, -20.0, 0.0),
			"spine": Vector3(8.0, -32.0, 0.0), "head": Vector3(-10.0, 34.0, 0.0),
			"foot_r": Vector3(-0.14, 0.0, 0.42), "foot_l": Vector3(0.15, 0.02, -0.36), "toe_l": 30.0,
			"reach_r": Vector3(-0.36, 0.04, 0.2), "aim_r": 1.0,
			"hand_l": SAYA - DRAW * 0.08,
			"blade": Vector3(-0.9, 0.16, 0.42), "blade_out": 1.0})],
		# Held for an instant at the end of the sweep.
		[1.0, stance({
			"hips": Vector3(0.0, -0.16, 0.12), "hips_rot": Vector3(8.0, -22.0, 0.0),
			"spine": Vector3(7.0, -34.0, 0.0), "head": Vector3(-10.0, 36.0, 0.0),
			"foot_r": Vector3(-0.14, 0.0, 0.42), "foot_l": Vector3(0.15, 0.02, -0.36), "toe_l": 30.0,
			"reach_r": Vector3(-0.38, 0.08, 0.14), "aim_r": 1.0,
			"hand_l": SAYA - DRAW * 0.08,
			"blade": Vector3(-0.97, 0.2, 0.15), "blade_out": 1.0})],
	], u)


## The parry. `u` goes 0 to 1 over the whole parry.
##
## Like every cut it starts as a draw: the blade comes a little way out of the
## scabbard and up, until it stands slanted in front of his face with the edge
## turned outward, to catch the blow on the flat near the guard. He braces low
## on his front foot, holds it there, and slides it back in at the end.
static func parry(u: float) -> Dictionary:
	var feet := {"foot_r": Vector3(-0.14, 0.0, 0.24), "foot_l": Vector3(0.15, 0.0, -0.3), "toe_l": 22.0}
	var draw := stance({
		"hips": Vector3(0.0, -0.12, 0.03), "hips_rot": Vector3(8.0, 12.0, 0.0),
		"spine": Vector3(10.0, 16.0, 0.0), "head": Vector3(-6.0, -24.0, 0.0),
		"hand_r": HILT + DRAW * 0.2, "hand_l": SAYA - DRAW * 0.05,
		"blade": -DRAW, "blade_out": 1.0}, feet)
	# The guard: fist before his chest, blade slanted up and forward, his
	# left hand pressing the back of the blade to take the weight of the blow.
	var guard := stance({
		"hips": Vector3(0.0, -0.17, 0.05), "hips_rot": Vector3(10.0, 4.0, 0.0),
		"spine": Vector3(6.0, 4.0, 0.0), "head": Vector3(-12.0, -6.0, 0.0),
		"reach_r": Vector3(-0.06, 0.06, 0.32), "aim_r": 1.0,
		"reach_l": Vector3(0.1, 0.16, 0.34), "aim_l": 1.0,
		"blade": Vector3(0.0, 0.82, 0.57), "blade_out": 1.0}, feet)
	# The same guard, pressed a touch further out (the moment he holds).
	var braced := stance({
		"hips": Vector3(0.0, -0.18, 0.06), "hips_rot": Vector3(11.0, 2.0, 0.0),
		"spine": Vector3(7.0, 2.0, 0.0), "head": Vector3(-12.0, -4.0, 0.0),
		"reach_r": Vector3(-0.06, 0.07, 0.35), "aim_r": 1.0,
		"reach_l": Vector3(0.1, 0.17, 0.37), "aim_l": 1.0,
		"blade": Vector3(0.0, 0.8, 0.6), "blade_out": 1.0}, feet)
	return along([[0.0, draw], [0.22, guard], [0.8, braced], [1.0, braced]], u)



## The iai stance: crouched low and still, front foot forward, body turned to
## hide the sword, head bowed so the hat hides his eyes. Right hand on the
## hilt, left thumb on the guard. `charge` goes 0 to 1 as he settles lower;
## at 1 the thumb has pushed an inch of blade out of the scabbard (the sign
## that the draw is ready).
static func iai(charge: float, time: float) -> Dictionary:
	var breath := sin(time * 1.6) * (1.0 - charge)
	var sink := smoothstep(0.0, 1.0, charge)
	var pose := stance({
		"hips": Vector3(0.0, -0.24 - sink * 0.06 + breath * 0.005, 0.06),
		"hips_rot": Vector3(12.0 + sink * 4.0, 22.0, 0.0),
		"spine": Vector3(16.0 + sink * 4.0, 16.0, 0.0),
		"head": Vector3(6.0 + sink * 4.0, -24.0, 0.0),
		"foot_r": Vector3(-0.15, 0.0, 0.36), "foot_l": Vector3(0.15, 0.0, -0.36), "toe_l": 34.0,
		"hand_r": HILT, "hand_l": SAYA + DRAW * 0.03,
	})
	if charge >= 1.0:
		pose["hand_r"] = HILT + DRAW * 0.08
		pose["blade"] = -DRAW
		pose["blade_out"] = 1.0
	return pose


## The draw: caught at the end of the cut, low and stretched along the line
## he travelled, sword arm flung out behind him, blade level.
static func iai_strike() -> Dictionary:
	return stance({
		"hips": Vector3(0.0, -0.3, 0.16), "hips_rot": Vector3(16.0, -22.0, 0.0),
		"spine": Vector3(10.0, -32.0, 0.0), "head": Vector3(-14.0, 34.0, 0.0),
		"foot_r": Vector3(-0.14, 0.0, 0.56), "foot_l": Vector3(0.15, 0.06, -0.52), "toe_l": 45.0,
		"reach_r": Vector3(-0.42, 0.04, 0.02), "aim_r": 1.0,
		"hand_l": SAYA - DRAW * 0.08,
		"blade": Vector3(-0.92, 0.12, -0.36), "blade_out": 1.0,
	})



## Clinging to a wall and sliding down it, with his BACK to the wall (it is
## behind him, at -Z), looking out. Both feet are braced behind him with the
## soles pressed back flat against the wall, toes down, knees bent forward,
## one a little higher than the other; his left hand is pressed to the wall
## behind his hip and his right keeps the sword still. Head bowed under the
## hat.
##
## The wall's surface is WALL_REACH behind his centre (the Ronin's collision
## radius), so that is where the soles are put.
const WALL_REACH := 0.3

static func wall_slide(time: float) -> Dictionary:
	var scrape := sin(time * 9.0) * 0.006  # the shiver of paper sliding on plaster
	return stance({
		"hips": Vector3(0.0, -0.1, 0.04), "hips_rot": Vector3(12.0, 0.0, 0.0),
		"spine": Vector3(10.0, 0.0, 0.0), "head": Vector3(14.0, 0.0, 0.0),
		"foot_r": Vector3(-0.12, 0.34 + scrape, -(WALL_REACH - 0.03)), "toe_r": 78.0,
		"foot_l": Vector3(0.12, 0.12 - scrape, -(WALL_REACH - 0.03)), "toe_l": 72.0,
		"reach_l": Vector3(0.24, -0.3, -(WALL_REACH - 0.02)), "aim_l": 1.0,
	})


## Springing off a wall: thrown out and up, back leg still straight from the
## push, front knee driving up, the hand that was on the wall swept out behind.
static func wall_jump() -> Dictionary:
	return stance({
		"hips_rot": Vector3(-6.0, 0.0, 0.0), "spine": Vector3(-10.0, 0.0, 0.0), "head": Vector3(-14.0, 0.0, 0.0),
		"foot_r": Vector3(-0.12, 0.34, 0.2), "toe_r": 30.0,
		"foot_l": Vector3(0.11, 0.02, -0.34), "toe_l": 70.0,
		"reach_l": Vector3(0.3, 0.1, -0.24), "aim_l": 1.0,
	})



## Creeping forward on the balls of his feet: short steps, heels raised, each
## foot lifted only a little and set down toe first; knees bent, hips low and
## level, back straight, both hands on the sword. `phase` 0 to 1 over a full
## stride (two steps).
static func sneak(phase: float) -> Dictionary:
	var left := _tiptoe(phase)
	var right := _tiptoe(fposmod(phase + 0.5, 1.0))
	var roll := sin(phase * TAU)
	return stance({
		"hips": Vector3(0.0, -0.13 + absf(roll) * 0.012, 0.03),
		"hips_rot": Vector3(9.0, roll * 4.0, 0.0),
		"spine": Vector3(6.0, -roll * 4.0, 0.0),
		"head": Vector3(4.0, 0.0, 0.0),
		"foot_l": Vector3(0.11, left.y, left.z), "toe_l": left.x,
		"foot_r": Vector3(-0.12, right.y, right.z), "toe_r": right.x,
		"hand_r": HILT,
	})


## One foot through a creeping stride: (toe angle, height, forward). Planted
## on its toes for the first half while the body passes over it, then lifted
## a hand's breadth, carried forward and set down toe first.
static func _tiptoe(p: float) -> Vector3:
	if p < 0.5:
		var plant := p / 0.5
		return Vector3(lerpf(24.0, 34.0, plant), 0.045, lerpf(0.17, -0.17, plant))
	var swing := (p - 0.5) / 0.5
	var lift := sin(PI * swing)
	return Vector3(lerpf(40.0, 24.0, swing), 0.045 + lift * 0.1, lerpf(-0.17, 0.17, smoothstep(0.0, 1.0, swing)))



## Ducking: dropped low onto his heels, one knee nearly to the ground, back
## bent and head down so the wide hat covers him; hand on the sword. Low
## enough that a sweep at chest height passes over the brim of his hat.
static func duck(time: float) -> Dictionary:
	var breath := sin(time * 2.2) * 0.008
	return stance({
		"hips": Vector3(0.0, -0.5 + breath, -0.04), "hips_rot": Vector3(22.0, 0.0, 0.0),
		"spine": Vector3(34.0, 0.0, 0.0), "head": Vector3(26.0, 0.0, 0.0),
		"foot_r": Vector3(-0.14, 0.0, 0.22), "toe_r": 0.0,
		"foot_l": Vector3(0.14, 0.04, -0.3), "toe_l": 72.0,
	})


## Shuffling along ducked (through a crawlspace): the duck, with the feet
## taking short sliding steps in turn and the body rocking a little over
## them. `phase` 0 to 1 over two steps.
static func crawl(phase: float, time: float) -> Dictionary:
	var pose := duck(time)
	var rock := sin(phase * TAU)
	var lift_r := maxf(sin(phase * TAU), 0.0)
	var lift_l := maxf(-sin(phase * TAU), 0.0)
	pose["hips"] = (pose["hips"] as Vector3) + Vector3(0.0, absf(rock) * 0.02, 0.0)
	pose["hips_rot"] = (pose["hips_rot"] as Vector3) + Vector3(0.0, rock * 4.0, 0.0)
	pose["foot_r"] = Vector3(-0.14, lift_r * 0.06, 0.22 - cos(phase * TAU) * 0.12)
	pose["foot_l"] = Vector3(0.14, 0.04 + lift_l * 0.05, -0.3 + cos(phase * TAU) * 0.1)
	return pose



## On a ladder, facing it (his back to us): hands on the rungs above his
## head in turn, the other lower; one knee up on a rung, the other leg
## straighter. `phase` 0 to 1 over a full cycle (both hands, both feet).
## (Hand reach points are measured from the shoulders, the way he faces;
## the ladder's rungs are a hand's length in front of him.)
static func climb(phase: float) -> Dictionary:
	var a := sin(phase * TAU)
	return stance({
		"hips": Vector3(0.0, -0.06, -0.06), "hips_rot": Vector3(8.0, 0.0, 0.0),
		"spine": Vector3(4.0, 0.0, 0.0), "head": Vector3(-12.0, 0.0, 0.0),
		"foot_l": Vector3(0.13, 0.22 + 0.2 * maxf(a, 0.0), 0.2), "toe_l": 20.0,
		"foot_r": Vector3(-0.13, 0.22 + 0.2 * maxf(-a, 0.0), 0.2), "toe_r": 20.0,
		"reach_l": Vector3(0.16, 0.38 + 0.2 * maxf(-a, 0.0), 0.3), "aim_l": 1.0,
		"reach_r": Vector3(-0.16, 0.38 + 0.2 * maxf(a, 0.0), 0.3), "aim_r": 1.0,
	})



## A skid on a sharp turn: dropped low, the front foot braced out ahead in
## the new direction, the back foot sliding, body leaning into the turn.
static func skid() -> Dictionary:
	return stance({
		"hips": Vector3(0.0, -0.22, -0.08), "hips_rot": Vector3(14.0, 10.0, 0.0),
		"spine": Vector3(12.0, -8.0, 0.0), "head": Vector3(-8.0, 0.0, 0.0),
		"foot_l": Vector3(0.14, 0.0, 0.42), "toe_l": -14.0,
		"foot_r": Vector3(-0.15, 0.03, -0.36), "toe_r": 40.0,
		"hand_r": HILT,
	})
