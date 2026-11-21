class_name HannyaStage
extends Node3D
## The Hannya's shrine hall in the courtyard: a dark timber hall whose front
## is one tall shoji screen, lit from inside by a lamp. She kneels inside,
## between the lamp and the paper, so her shadow falls on the screen.
##
## How the shadow is made: a hidden camera stands where the lamp is and
## films only her silhouette double (white on black). shoji_screen.gdshader
## lays that picture over the paper, blurred, as the shadow. Because it is
## the real model, posed the same frame by frame, the shadow moves exactly
## as she does.
##
## Origin: on the ground, at the middle of the screen's foot. The screen faces
## +Z (the camera).

## The screen's width and height, in metres.
@export var screen_size := Vector2(5.2, 4.2)
## How far behind the screen the lamp is.
@export var lamp_distance := 3.4
## How high the lamp stands: low on the floor, so her shadow looms up tall.
@export var lamp_height := 0.45
## How far behind the screen she kneels. Nearer the lamp = a bigger shadow
## (at 2.3 it is about three times her size).
@export var hannya_depth := 1.9
## How soft her shadow is (a fraction of the screen).
@export var shadow_softness := 0.01

var hannya: Hannya
var screen_material: ShaderMaterial
var front_light: OmniLight3D   # the warm spill from the screen onto the courtyard
var inner_light: OmniLight3D   # the lamp inside, which lights her when the paper is torn

var _slash_open := Vector2.ZERO
var _viewport: SubViewport
var _shadow_camera: Camera3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	_build_hall()
	_build_screen()
	hannya = Hannya.new()
	hannya.position = Vector3(0.0, 0.0, -hannya_depth)
	hannya.rotation.y = PI * 0.5  # kneeling side-on, so her shadow is her profile
	add_child(hannya)
	hannya.make_shadow_double()
	hannya.show_body(false)  # behind the paper she is only a shadow
	_build_shadow_camera()


## The lamp behind the paper: 1 = lit, 0 = out.
func set_light(amount: float) -> void:
	screen_material.set_shader_parameter(&"light", amount)
	front_light.light_energy = 1.6 * amount
	inner_light.light_energy = 2.4 * amount


func set_ink(amount: float) -> void:
	screen_material.set_shader_parameter(&"ink", amount)


func set_softness(amount: float) -> void:
	screen_material.set_shader_parameter(&"softness", amount)


## Opens slash 0 or 1 (0 to 1).
func open_slash(which: int, amount: float) -> void:
	_slash_open[which] = amount
	screen_material.set_shader_parameter(&"slash_open", _slash_open)


func set_tear(amount: float) -> void:
	screen_material.set_shader_parameter(&"tear", amount)


## Where on the screen (UV, 0 to 1, y downward) a point in the world falls.
func screen_uv(world: Vector3) -> Vector2:
	var local := to_local(world)
	return Vector2(local.x / screen_size.x + 0.5, 1.0 - local.y / screen_size.y)


## She has come out through the paper: her shadow leaves the screen (the ink
## she bled stays, frozen), and the shadow camera stops, to save time.
func stop_shadow() -> void:
	var last := _viewport.get_texture().get_image()
	if last:
		screen_material.set_shader_parameter(&"ink_shape", ImageTexture.create_from_image(last))
	screen_material.set_shader_parameter(&"shadow_strength", 0.0)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	hannya.hide_double()


func _build_screen() -> void:
	var quad := QuadMesh.new()
	quad.size = screen_size
	var paper := MeshInstance3D.new()
	paper.mesh = quad
	paper.position = Vector3(0.0, screen_size.y * 0.5, 0.0)
	paper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen_material = ShaderMaterial.new()
	screen_material.shader = preload("res://shaders/shoji_screen.gdshader")
	screen_material.set_shader_parameter(&"aspect", screen_size.x / screen_size.y)
	screen_material.set_shader_parameter(&"lamp_uv", Vector2(0.5, 1.0 - lamp_height / screen_size.y))
	screen_material.set_shader_parameter(&"softness", shadow_softness)
	paper.material_override = screen_material
	add_child(paper)

	# The lattice (kumiko) over the paper, and its heavy frame.
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.15
	b.color = PaperMesh.TIMBER
	var w := screen_size.x
	var h := screen_size.y
	for i in range(1, 6):
		b.box(Vector3(-w * 0.5 + w * i / 6.0, h * 0.5, 0.04), Vector3(0.035, h, 0.04))
	for j in range(1, 7):
		b.box(Vector3(0.0, h * j / 7.0, 0.04), Vector3(w, 0.035, 0.04))
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * (w * 0.5 + 0.08), h * 0.5 + 0.1, 0.02), Vector3(0.18, h + 0.2, 0.18))
	b.box(Vector3(0.0, h + 0.08, 0.02), Vector3(w + 0.34, 0.18, 0.2))
	b.box(Vector3(0.0, 0.06, 0.02), Vector3(w + 0.34, 0.12, 0.2))
	add_child(b.build())

	front_light = OmniLight3D.new()
	front_light.light_color = Color(1.0, 0.7, 0.42)
	front_light.light_energy = 1.6
	front_light.omni_range = 6.5
	front_light.omni_attenuation = 1.4
	front_light.position = Vector3(0.0, 1.6, 1.0)
	add_child(front_light)


## The hall behind the screen: dark board walls, posts, a deep tiled roof,
## and the lamp inside. Solid on every side the camera reaches.
func _build_hall() -> void:
	var w := screen_size.x
	var h := screen_size.y
	var depth := lamp_distance + 0.9
	var b := PaperMesh.new(_rng.randi())
	b.shade_jitter = 0.08
	b.color = Scenery.WALL_DARK.darkened(0.35)
	b.box(Vector3(0.0, h * 0.5 + 0.2, -depth), Vector3(w + 0.6, h + 0.4, 0.12))   # back wall
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(side * (w * 0.5 + 0.3), h * 0.5 + 0.2, -depth * 0.5), Vector3(0.12, h + 0.4, depth))
	b.color = Color(0.05, 0.045, 0.06)
	b.box(Vector3(0.0, 0.02, -depth * 0.5), Vector3(w + 0.6, 0.04, depth))          # floor boards
	b.box(Vector3(0.0, h + 0.3, -depth * 0.5), Vector3(w + 0.6, 0.06, depth))       # ceiling
	b.color = PaperMesh.TIMBER
	for side: float in [-1.0, 1.0]:
		for z: float in [0.1, -depth]:
			b.box(Vector3(side * (w * 0.5 + 0.38), (h + 0.5) * 0.5, z), Vector3(0.22, h + 0.5, 0.22))
	# The step up to the screen.
	b.color = Color(0.28, 0.29, 0.36)
	b.box(Vector3(0.0, 0.1, 0.45), Vector3(w + 0.9, 0.2, 0.7))
	add_child(b.build())
	var roof := Scenery.tiled_roof(_rng, -w * 0.5 - 0.9, w * 0.5 + 0.9, Vector2(h + 0.35, 1.5),
			Vector2(h + 1.9, -depth * 0.5), 5)
	add_child(roof)
	var back := Scenery.tiled_roof(_rng, -w * 0.5 - 0.9, w * 0.5 + 0.9, Vector2(h + 0.35, -depth - 1.0),
			Vector2(h + 1.9, -depth * 0.5), 5, false)
	add_child(back)
	# The lamp inside: a paper lantern on the floor behind her.
	var lamp := Scenery.lantern(_rng, 2.4, 0.55, 0.0)
	lamp.position = Vector3(0.0, lamp_height + 0.35, -lamp_distance - 0.25)
	add_child(lamp)
	inner_light = OmniLight3D.new()
	inner_light.light_color = Color(1.0, 0.7, 0.42)
	inner_light.light_energy = 2.4
	inner_light.omni_range = 5.0
	inner_light.position = Vector3(0.0, lamp_height + 0.2, -lamp_distance + 0.3)
	add_child(inner_light)


func _build_shadow_camera() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(512, int(512.0 * screen_size.y / screen_size.x))
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	_shadow_camera = Camera3D.new()
	_shadow_camera.cull_mask = Hannya.SHADOW_LAYER
	_shadow_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	# The lamp is low, so the screen is above it: an off-centre lens that
	# frames exactly the screen from there.
	var near := 0.05
	_shadow_camera.projection = Camera3D.PROJECTION_FRUSTUM
	_shadow_camera.near = near
	_shadow_camera.size = screen_size.y * near / lamp_distance
	_shadow_camera.frustum_offset = Vector2(0.0, (screen_size.y * 0.5 - lamp_height) * near / lamp_distance)
	var dark := Environment.new()
	dark.background_mode = Environment.BG_COLOR
	dark.background_color = Color.BLACK
	_shadow_camera.environment = dark
	_viewport.add_child(_shadow_camera)
	# At the lamp, looking out through the screen (+Z).
	_shadow_camera.global_transform = Transform3D(Basis(Vector3.UP, PI),
			to_global(Vector3(0.0, lamp_height, -lamp_distance)))
	screen_material.set_shader_parameter(&"shadow", _viewport.get_texture())
	screen_material.set_shader_parameter(&"ink_shape", _viewport.get_texture())
