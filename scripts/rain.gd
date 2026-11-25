class_name Rain
extends Node3D
## The Rain. A cloud of thin streaks that follows the camera, spread across
## several depths so some drops fall in front of the Ronin and some behind.

@export var drop_count := 2250
@export var fall_speed := 26.0
## Size of the box the drops start in: (width, thickness, depth).
## (Deep enough to fall on the near ground in front of him too, up to 8 m
## toward the camera: Julian, "the rain doesn't rain on the near ground".)
@export var area := Vector3(44.0, 1.0, 15.0)
@export var height_above_camera := 10.0
## How much each metre-per-second of wind tips the rain over.
@export var wind_slant := 0.05
@export var streak_length := 1.3
@export var streak_width := 0.014
@export var streak_color := Color(0.78, 0.84, 1.0, 0.3)

var _drops: CPUParticles3D
var _look: ShaderMaterial
var _level := 1.0


func _ready() -> void:
	_drops = CPUParticles3D.new()
	_drops.amount = drop_count
	_drops.lifetime = 1.1
	_drops.preprocess = 1.1          # Start already raining.
	_drops.local_coords = false       # Drops stay put in the world as the camera moves.
	_drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_drops.emission_box_extents = area * 0.5
	_drops.direction = Vector3(-0.16, -1.0, 0.0)
	_drops.spread = 1.5
	_drops.gravity = Vector3.ZERO
	_drops.initial_velocity_min = fall_speed * 0.9
	_drops.initial_velocity_max = fall_speed * 1.1

	var streak := QuadMesh.new()
	streak.size = Vector2(streak_width, streak_length)
	# (A shader of our own, so that underground no rain falls inside the
	# canals: see shaders/rain_streak.gdshader.)
	_look = ShaderMaterial.new()
	_look.shader = preload("res://shaders/rain_streak.gdshader")
	_look.set_shader_parameter(&"tint", streak_color)
	_look.set_shader_parameter(&"hole", Vector2(Village.FALL_LEFT, Village.FALL_RIGHT))
	_look.set_shader_parameter(&"hole_floor", Village.CANAL_WATER)
	_look.set_shader_parameter(&"river", Village.RIVER)
	_look.set_shader_parameter(&"river_floor", RiverBridge.WATER)
	streak.material = _look
	_drops.mesh = streak
	_drops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drops)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		# Underground, the drops start no lower than above the street.
		global_position = Vector3(camera.global_position.x,
				maxf(camera.global_position.y, 4.2) + height_above_camera, 0.5)
		_look.set_shader_parameter(&"clip_on", camera.global_position.y < 3.5)
	# The rain slants further over in a gust.
	_drops.direction = Vector3(-0.04 - Wind.speed_at(global_position.x) * wind_slant, -1.0, 0.0)



## The rain eases (to `level` of itself: 0.25 = a quarter) over `time`
## seconds, or comes back (level 1).
func ease_off(level: float, time: float) -> void:
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		_look.set_shader_parameter(&"tint", Color(streak_color.r, streak_color.g, streak_color.b, streak_color.a * v)),
		_level, level, time).set_trans(Tween.TRANS_SINE)
	_level = level
