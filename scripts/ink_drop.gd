class_name InkDrop
extends Node3D
## One of the Hannya's ink tears. A stain spreads on the ground where it will
## land (the warning); then a long drop of ink falls and lands exactly when
## the stain is full, splashes, and the stain fades. It hurts the Ronin if he
## is standing in the stain when it lands.
##
## Origin: on the ground where it lands.

## Seconds of warning before it lands.
var warning := 0.8
## How close (sideways) it must land to hit him.
var radius := 0.6
var target: Node3D

const FALL_TIME := 0.32
const FALL_FROM := 9.0

var _clock := 0.0
var _landed := false
var _stain: MeshInstance3D
var _stain_look: StandardMaterial3D
var _drop: MeshInstance3D
var _splash: CPUParticles3D


func _ready() -> void:
	# The stain: a soft dark blot lying on the stones.
	var blot := QuadMesh.new()
	blot.size = Vector2(radius * 2.2, radius * 2.2)
	blot.orientation = PlaneMesh.FACE_Y
	_stain = MeshInstance3D.new()
	_stain.mesh = blot
	_stain_look = StandardMaterial3D.new()
	_stain_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_stain_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_stain_look.albedo_texture = _soft_spot()
	_stain_look.albedo_color = Color(0.02, 0.02, 0.05, 0.0)
	_stain_look.disable_fog = true
	_stain.material_override = _stain_look
	_stain.position.y = 0.03
	_stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stain.scale = Vector3.ONE * 0.2
	add_child(_stain)
	# The drop: a long tear of ink.
	var tear := SphereMesh.new()
	tear.radius = 0.09
	tear.height = 0.6
	_drop = MeshInstance3D.new()
	_drop.mesh = tear
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.03, 0.03, 0.06)
	ink.roughness = 0.2
	ink.metallic_specular = 0.8
	_drop.material_override = ink
	_drop.visible = false
	add_child(_drop)
	_splash = CPUParticles3D.new()
	_splash.emitting = false
	_splash.one_shot = true
	_splash.explosiveness = 1.0
	_splash.amount = 16
	_splash.lifetime = 0.5
	_splash.direction = Vector3.UP
	_splash.spread = 60.0
	_splash.initial_velocity_min = 2.0
	_splash.initial_velocity_max = 4.5
	_splash.gravity = Vector3(0.0, -16.0, 0.0)
	_splash.scale_amount_min = 0.5
	_splash.scale_amount_max = 1.3
	var bead := QuadMesh.new()
	bead.size = Vector2(0.09, 0.09)
	bead.material = PaperMesh.soft_ink(Color(0.03, 0.03, 0.06))
	_splash.mesh = bead
	add_child(_splash)


func _process(delta: float) -> void:
	_clock += delta
	if not _landed:
		var grow := clampf(_clock / warning, 0.0, 1.0)
		_stain.scale = Vector3.ONE * lerpf(0.2, 1.0, smoothstep(0.0, 1.0, grow))
		_stain_look.albedo_color.a = 0.75 * grow
		var fall := (_clock - (warning - FALL_TIME)) / FALL_TIME
		if fall >= 0.0:
			_drop.visible = true
			_drop.position.y = lerpf(FALL_FROM, 0.25, clampf(fall * fall, 0.0, 1.0))
		if _clock >= warning:
			_land()
	else:
		var after := _clock - warning
		_stain_look.albedo_color.a = 0.75 * (1.0 - clampf(after / 1.2, 0.0, 1.0))
		if after > 1.3:
			queue_free()


func _land() -> void:
	_landed = true
	_drop.visible = false
	_splash.restart()
	Sound.play(self, &"step", -2.0)
	if target and is_instance_valid(target):
		var gap := absf(target.global_position.x - global_position.x)
		var above := target.global_position.y - global_position.y
		if gap < radius and above < 1.8 and target.has_method("take_damage"):
			target.take_damage(1, global_position)


static func _soft_spot() -> GradientTexture2D:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.55, Color(1, 1, 1, 0.9))
	var spot := GradientTexture2D.new()
	spot.gradient = ramp
	spot.fill = GradientTexture2D.FILL_RADIAL
	spot.fill_from = Vector2(0.5, 0.5)
	spot.fill_to = Vector2(1.0, 0.5)
	return spot
