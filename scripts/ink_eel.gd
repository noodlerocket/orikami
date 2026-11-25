class_name InkEel
extends PaperCritter
## The ink eel (sumi-unagi) of Sumi Marsh (picture: docs/reference/
## inkeel_side.png): a long eel folded from paper in angular segments,
## glossy ink-black on top and pale grey beneath, a ragged pale fin along its
## back, a long jaw of cut-paper teeth, one pale weeping eye. Folded in code
## as a chain: its head leads and every segment follows the trail the head
## has left (as the Festival Dragon's body does).
##
## It lives in one pool of deep ink (`pool`). Its tell: a pale fin cuts the
## surface toward him and the ink bulges where it will come up. Then it
## bursts out in an arc over him, jaws open (a bite: parry it), and drops
## back in on the far side. In the air it can be cut. Parried, it falls
## back onto the ink belly-up, staggered: a cut finishes it.

## The stretch of deep ink it lives in (local x of its parent).
var pool := Vector2(0.0, 10.0)
@export_group("Hunting")
## How near (m along x) he must come, and how high above the ink at most.
@export var sight := 7.0
@export var sight_rise := 5.0
## The fin's approach (the tell), then the bulge before it leaps (s).
@export var stalk_time := 1.1
@export var bulge_time := 0.4
## The leap: how long it is in the air (s), how far it goes (m), how high
## above where he stands.
@export var leap_time := 1.05
@export var leap_span := 6.0
@export var leap_over := 1.3
@export var attack_damage := 1
@export var rest_time := 2.2

const SEGMENTS := 11
const SPACING := 0.26
const INK_TOP := Color(0.05, 0.05, 0.07)
const BELLY := Color(0.62, 0.63, 0.64)
const FIN := Color(0.76, 0.76, 0.72)

var _trail: Array[Vector3] = []
var _segs: Array[Node3D] = []
var _head: Node3D
var _jaw: Node3D
var _fin: Node3D
var _leap_from := Vector3.ZERO
var _leap_to := Vector3.ZERO
var _peak := 0.0
var _bit := false
var _ronin: Ronin
var _side := 1.0
## Leaping from the edge of its pool at him on the bank: out to him and back
## into the ink where it came up (not across).
var _lunge := false
var _reach_x := 0.0


func _ready() -> void:
	max_health = 3
	max_posture = 1
	stagger_time = 2.2
	confetti_count = 36
	confetti_colors = [Color(0.08, 0.08, 0.1), BELLY, FIN]
	super._ready()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 0.5, 0.6)
	shape.shape = box
	add_child(shape)
	collision_mask = 0  # (it moves itself; nothing stops it)
	_make_touch(Vector3(0.9, 0.5, 1.0), Vector3.ZERO)
	for i in SEGMENTS * 4 + 4:
		_trail.append(global_position + Vector3(-i * SPACING * 0.25, -1.5, 0.0))
	_set_mode(&"lurk")
	visible = false


func _body_centre() -> Vector3:
	return Vector3.ZERO


func _build() -> void:
	var seed_value := int(global_position.x * 7.0) + 77
	# The head (in the rig): an angular wedge, its jaw hinged under it.
	_head = Node3D.new()
	_rig.add_child(_head)
	var h := PaperMesh.new(seed_value)
	h.texture_world = false
	h.shade_jitter = 0.14
	h.color = INK_TOP
	h.loft([PaperCritter.ring_x(Vector3(-0.22, 0.0, 0.0), Vector2(0.16, 0.14), 5), PaperCritter.ring_x(Vector3(0.05, 0.02, 0.0), Vector2(0.15, 0.13), 5),
			PaperCritter.ring_x(Vector3(0.32, 0.0, 0.0), Vector2(0.06, 0.07), 5)])
	h.color = BELLY.darkened(0.1)
	h.box(Vector3(0.02, -0.1, 0.0), Vector3(0.44, 0.05, 0.2))
	# The eye, pale, weeping a line of ink.
	for side: float in [-1.0, 1.0]:
		h.color = Color(0.86, 0.88, 0.88)
		h.box(Vector3(0.12, 0.06, side * 0.11), Vector3(0.06, 0.06, 0.02))
		h.color = Color(0.03, 0.03, 0.04)
		h.box(Vector3(0.12, -0.03, side * 0.115), Vector3(0.015, 0.12, 0.01))
	# Upper teeth.
	h.color = Color(0.86, 0.85, 0.8)
	for k in 6:
		var tx := 0.3 - k * 0.06
		for side: float in [-1.0, 1.0]:
			h.tri(Vector3(tx, -0.06, side * 0.06), Vector3(tx - 0.03, -0.06, side * 0.06), Vector3(tx - 0.015, -0.13, side * 0.06), Vector3(0.0, 0.0, side))
	_part(_head, h.build())
	_jaw = Node3D.new()
	_jaw.position = Vector3(-0.12, -0.08, 0.0)
	_head.add_child(_jaw)
	var j := PaperMesh.new(seed_value + 1)
	j.texture_world = false
	j.color = BELLY
	j.extrude(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.44, 0.0), Vector2(0.4, -0.06), Vector2(0.0, -0.08)]), -0.08, 0.08)
	j.color = Color(0.86, 0.85, 0.8)
	for k in 6:
		var tx := 0.4 - k * 0.06
		for side: float in [-1.0, 1.0]:
			j.tri(Vector3(tx, 0.0, side * 0.06), Vector3(tx - 0.03, 0.0, side * 0.06), Vector3(tx - 0.015, 0.07, side * 0.06), Vector3(0.0, 0.0, side))
	_part(_jaw, j.build())
	# The body: segments, each a short folded tube, dark over pale, with a
	# ragged fin on top; they hang off the trail (not the rig).
	for i in SEGMENTS:
		var seg := Node3D.new()
		add_child(seg)
		seg.top_level = true
		var t := float(i) / (SEGMENTS - 1)
		var r := lerpf(0.15, 0.05, t * t)
		var s := PaperMesh.new(seed_value + 10 + i)
		s.texture_world = false
		s.shade_jitter = 0.16
		s.color = INK_TOP.lightened(0.05 * (i % 2))
		s.loft([PaperCritter.ring_x(Vector3(-SPACING * 0.62, 0.0, 0.0), Vector2(r * 0.95, r * 0.85), 5), PaperCritter.ring_x(Vector3(SPACING * 0.5, 0.0, 0.0), Vector2(r, r * 0.9), 5)])
		s.color = BELLY.darkened(0.05 * (i % 2))
		s.box(Vector3(0.0, -r * 0.7, 0.0), Vector3(SPACING * 1.05, r * 0.3, r * 1.2))
		s.color = FIN.darkened(0.1 * (i % 3))
		s.polygon(PackedVector2Array([Vector2(-SPACING * 0.6, r * 0.8), Vector2(SPACING * 0.55, r * 0.8),
				Vector2(SPACING * 0.3, r + 0.16 - t * 0.08), Vector2(-SPACING * 0.1, r + 0.08), Vector2(-SPACING * 0.4, r + 0.13 - t * 0.06)]), 0.0)
		if i == SEGMENTS - 1:
			s.polygon(PackedVector2Array([Vector2(-SPACING * 0.5, 0.0), Vector2(-SPACING * 1.6, 0.18), Vector2(-SPACING * 1.4, -0.12)]), 0.0)
		_part(seg, s.build())
		_segs.append(seg)
	# The fin alone, cutting the surface in the tell.
	_fin = Node3D.new()
	add_child(_fin)
	_fin.top_level = true
	var f := PaperMesh.new(seed_value + 40)
	f.texture_world = false
	f.color = FIN
	f.polygon(PackedVector2Array([Vector2(-0.7, 0.0), Vector2(0.3, 0.0), Vector2(0.1, 0.32), Vector2(-0.2, 0.18), Vector2(-0.45, 0.26)]), 0.0)
	_fin.add_child(f.build())
	_fin.visible = false


func _physics_process(delta: float) -> void:
	_tick(delta)
	if _ronin == null:
		_ronin = get_tree().get_first_node_in_group(&"player") as Ronin
		if _ronin == null:
			return
	var base := get_parent() as Node3D
	var left := base.to_global(Vector3(pool.x, 0.0, 0.0)).x
	var right := base.to_global(Vector3(pool.y, 0.0, 0.0)).x
	var surface := base.to_global(Vector3(0.0, SumiMarsh.INK_Y, 0.0)).y
	var him := _ronin.global_position
	match mode:
		&"lurk":
			global_position = Vector3(clampf(him.x, left + 0.5, right - 0.5), surface - 1.5, 0.0)
			if him.x > left - sight * 0.5 and him.x < right + sight * 0.5 and him.y - surface < sight_rise and not _ronin.is_in_pit():
				_side = -1.0 if him.x > (left + right) * 0.5 else 1.0
				_set_mode(&"stalk")
				visible = true
				_fin.visible = true
				_fin.global_position = Vector3(clampf(him.x + _side * 5.0, left + 0.4, right - 0.4), surface, -0.2)
		&"stalk":
			# The fin cuts toward him through the ink.
			var aim := clampf(him.x + _side * 2.4, left + 0.4, right - 0.4)
			_fin.global_position.x = move_toward(_fin.global_position.x, aim, 4.5 * delta)
			_fin.global_position.y = surface + 0.01
			_fin.rotation.y = 0.0 if _side < 0.0 else PI
			if _mode_time >= stalk_time:
				_set_mode(&"bulge")
				Sound.play(self, &"eel_hiss", -2.0)
		&"bulge":
			# The ink swells where it will burst out; the fin sinks.
			_fin.global_position.y = surface - _mode_time * 0.6
			if _mode_time >= bulge_time:
				_fin.visible = false
				_leap_from = Vector3(_fin.global_position.x, surface - 0.4, 0.0)
				var dir := -_side
				_leap_to = Vector3(clampf(_leap_from.x + dir * leap_span, left + 0.3, right - 0.3), surface - 0.4, 0.0)
				# He is over the ink (a walkway, swimming): across, over him.
				# On the bank beside it: out at him and back into the pool.
				_lunge = him.x < left or him.x > right or absf(_leap_to.x - _leap_from.x) < 2.5
				if _lunge:
					_leap_from.x = clampf(him.x, left + 0.6, right - 0.6)
					_leap_to = _leap_from
					_reach_x = him.x
				_peak = maxf(him.y - surface + leap_over, 1.6)
				# Never up through a walkway or a deck: if the arc meets
				# anything solid, try it the other way, or out at him from
				# where the ink is open; if nothing is clear, it stays down.
				if not _arc_clear():
					var tries: Array = []
					tries.append([_leap_to, _leap_from, false, 0.0])
					for edge: float in [_fin.global_position.x, left + 0.6, right - 0.6]:
						tries.append([Vector3(edge, surface - 0.4, 0.0), Vector3(edge, surface - 0.4, 0.0), true, him.x])
					var found := false
					for t: Array in tries:
						_leap_from = t[0]
						_leap_to = t[1]
						_lunge = t[2]
						_reach_x = t[3]
						if _arc_clear():
							found = true
							break
					if not found:
						_set_mode(&"rest")
						return
				_dir = signf((_reach_x if _lunge else _leap_to.x) - _leap_from.x)
				_bit = false
				_set_mode(&"leap")
				WaterFx.splash(base, Vector3(base.to_local(_leap_from).x, SumiMarsh.INK_Y, 0.0), 1.3, true)
				Sound.play(self, &"splash", 0.0)
		&"leap":
			var u := _mode_time / leap_time
			var p := _leap_from.lerp(_leap_to, u)
			if _lunge:
				p.x = _leap_from.x + (_reach_x - _leap_from.x) * sin(PI * u)
				_dir = signf(_reach_x - _leap_from.x) if u < 0.5 else -signf(_reach_x - _leap_from.x)
			p.y += _peak * 4.0 * u * (1.0 - u) + 0.4
			global_position = p
			if not _bit and u > 0.2 and u < 0.8:
				_bite()
			if u >= 1.0:
				WaterFx.splash(base, Vector3(base.to_local(_leap_to).x, SumiMarsh.INK_Y, 0.0), 1.1, true)
				Sound.play(self, &"splash", -3.0)
				_set_mode(&"rest")
		&"stagger", &"flop":
			# Fallen back on the ink, belly up, writhing.
			global_position.y = move_toward(global_position.y, surface + 0.12, 6.0 * delta)
			if _mode_time >= stagger_time:
				posture = 0
				WaterFx.splash(base, Vector3(base.to_local(global_position).x, SumiMarsh.INK_Y, 0.0), 0.8, true)
				_set_mode(&"rest")
		&"hurt":
			global_position.y -= 2.0 * delta
			if _mode_time >= 0.4:
				_set_mode(&"rest")
		&"rest", &"recover":
			global_position.y = move_toward(global_position.y, surface - 1.6, 5.0 * delta)
			if _mode_time >= rest_time:
				visible = false
				_set_mode(&"lurk")
	_trail.push_front(global_position)
	_trail.resize(SEGMENTS * 4 + 4)
	if mode == &"leap":
		_check_touch()


## Is the leap's whole arc (as set up now) clear of the world's solids?
func _arc_clear() -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.collision_mask = 1
	for k in 13:
		var u := float(k) / 12.0
		var p := _leap_from.lerp(_leap_to, u)
		if _lunge:
			p.x = _leap_from.x + (_reach_x - _leap_from.x) * sin(PI * u)
		p.y += _peak * 4.0 * u * (1.0 - u) + 0.4
		for dy: float in [-0.25, 0.0, 0.25]:
			q.position = p + Vector3(0.0, dy, 0.0)
			if not space.intersect_point(q, 1).is_empty():
				return false
	return true


## Its jaws at him in the leap: an attack he can parry.
func _bite() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.8, 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(_dir * 0.3, 0.0, 0.0))
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 2):
		var target: Object = result["collider"]
		if target.has_method("receive_strike"):
			_bit = true
			if target.receive_strike(attack_damage, global_position, hurt_kind):
				Sound.play(self, &"parry", -4.0)
				_on_parried()
			return


func _on_parried() -> void:
	posture += 1
	_set_mode(&"stagger")
	Sound.play(self, &"stagger")


func _on_hit(_direction: Vector2) -> void:
	if mode != &"stagger":
		_set_mode(&"hurt")
		Sound.play(self, &"eel_hiss", -6.0)


func gusted(direction: Vector3, _from: Vector3) -> void:
	if mode == &"leap":
		_leap_to.x = global_position.x + signf(direction.x) * 2.0
		Sound.play(self, &"paper_fold", -4.0)


func _process(delta: float) -> void:
	super._process(delta)
	# The segments hang along the head's trail (every frame: smooth).
	var surface := (get_parent() as Node3D).to_global(Vector3(0.0, SumiMarsh.INK_Y, 0.0)).y
	for i in _segs.size():
		var a := _trail[mini((i + 1) * 3, _trail.size() - 1)]
		var b := _trail[mini((i + 1) * 3 + 2, _trail.size() - 1)]
		var seg := _segs[i]
		seg.global_position = a
		var d := a - b
		var ang := atan2(d.y, d.x) if d.length() > 0.001 else (0.0 if _dir > 0.0 else PI)
		seg.global_rotation = Vector3(0.0, 0.0, ang)
		if mode == &"stagger":
			seg.global_rotation.x = PI  # belly up
		seg.visible = visible and seg.global_position.y > surface - 0.5


func _pose() -> void:
	var d := _trail[0] - _trail[2]
	var ang := atan2(d.y, d.x) if d.length() > 0.001 else (0.0 if _dir > 0.0 else PI)
	_rig.rotation = Vector3(PI if mode == &"stagger" else 0.0, 0.0, ang)
	var gape := 0.0
	match mode:
		&"leap":
			gape = 0.75 if _mode_time / leap_time < 0.75 else 0.2
		&"stagger":
			gape = 0.3 + 0.2 * sin(_clock * 9.0)
		&"hurt":
			gape = 0.5
	_jaw.rotation.z = -gape
	_head.visible = mode != &"lurk" and mode != &"stalk" and mode != &"bulge"
