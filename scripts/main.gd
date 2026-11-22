extends Node3D
## The root of the test scene. It only introduces the pieces to each other:
## the camera follows the Ronin, the HUD listens to him, hits shake the camera.
## It also fades the screen out and in when he falls into a pit.

@export_group("Falling in a pit")
## Seconds for the screen to fade to black after he falls in.
@export var pit_fade_out := 0.45
## Seconds it stays black while he is put back at the start.
@export var pit_hold := 0.25
## Seconds for the screen to fade back in.
@export var pit_fade_in := 0.7
## The colour it fades to: sumi ink, not pure black.
@export var pit_fade_color := Color(0.03, 0.03, 0.06)

var _fade: ColorRect
var _cutscene_played := false
var _boss: HannyaBoss
var _warming := false
var _boss_bar: BossBar
var _pause: PauseMenu
var _smudge: Smudge
var _explore_clock := 0.0

@onready var _ronin: Ronin = $Ronin
@onready var _camera: FollowCamera = $Camera
@onready var _hud: Hud = $Overlay/HUD


func _ready() -> void:
	UiStyle.load_settings()
	# Underground (the drain pipe and the canals) the camera goes down with him.
	_camera.under_zone = Vector2(Village.CHAMBER.x - 1.0, Village.CANAL.y + 0.5)
	_apply_debug_start()
	_camera.target = _ronin
	# The climbing course and the courtyard's middle (the far end of the
	# level moves as the village grows).
	_camera.climb_zone = Vector2(Village.CLIMB_WALLS[0][0] - 0.7, Village.CLIMB_WALLS[1][1] + 1.9)
	_camera.max_x = (Village.ARENA.x + Village.ARENA.y) * 0.5
	_camera.snap_to_target()
	_hud.watch(_ronin)
	_ronin.slash_landed.connect(_camera.add_shake.bind(0.07))
	_ronin.hurt.connect(_camera.add_shake.bind(0.22))
	_ronin.parried.connect(_camera.add_shake.bind(0.12))
	_ronin.fell_in_pit.connect(_on_fell_in_pit)
	_ronin.died.connect(_on_died)
	_build_fade()
	_build_pause()
	_watch_shortcuts()
	if SaveGame.continuing:
		SaveGame.continuing = false
		_continue_from_save.call_deferred()
	_debug_screenshot()
	# The browser version prepares every material and effect once, behind a
	# loading cover, so the game does not freeze the first time each appears.
	if OS.has_feature("web") or "--warmup" in OS.get_cmdline_user_args():
		await _warm_up()
	if Prologue.into_well or "--well" in OS.get_cmdline_user_args():
		Prologue.into_well = false
		_start_in_well()


func _process(delta: float) -> void:
	# The Hannya's shadow is only filmed while her shrine could be on screen.
	var stage: HannyaStage = $Village.stage
	if stage and not _warming:
		stage.set_shadow_active(absf(_camera.global_position.x - stage.global_position.x) < 26.0
				or (_boss != null and is_instance_valid(_boss)))
	if _warming:
		return  # (he is moved about during the warm-up: no cutscene, no fight)
	_explore_clock += delta
	if _explore_clock > 0.4:
		_explore_clock = 0.0
		SaveGame.explore(_ronin.global_position)
	var in_arena := _ronin.global_position.x > Village.ARENA.x + 0.6
	# Walking into the shrine courtyard for the first time plays the cutscene
	# (once it has been seen, in a saved game, the fight starts at once).
	if not _cutscene_played and in_arena:
		if SaveGame.hannya_fallen:
			_cutscene_played = true
		elif SaveGame.hannya_seen:
			_cutscene_played = true
			_start_boss_fight()
		else:
			play_hannya_cutscene()
	# After that: coming back in (after dying) starts the fight again. (The
	# courtyard is sealed while she fights, so it cannot be walked out of.)
	if _boss and is_instance_valid(_boss) and _boss.health > 0:
		if not _boss.active and in_arena and _ronin.global_position.x > Village.ARENA.x + 2.0:
			_begin_fight()


## After the prologue: he climbs out of the village well, seen from the
## street (well_cutscene.gd); then the camera glides into place, the game is
## his, and the tutorial cards begin.
func _start_in_well() -> void:
	var scene := WellCutscene.new()
	scene.main = self
	scene.ronin = _ronin
	scene.game_camera = _camera
	scene.fade = _fade
	scene.hud = _hud
	scene.finished.connect(_start_tutorial)
	add_child(scene)


## The tutorial cards, once he is out of the well (tutorial.gd).
func _start_tutorial() -> void:
	var lessons := Tutorial.new()
	lessons.ronin = _ronin
	lessons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Overlay.add_child(lessons)


## The cutscene before the Weeping Hannya fight.
func play_hannya_cutscene() -> void:
	_cutscene_played = true
	SaveGame.hannya_seen = true
	SaveGame.write()
	var scene := HannyaCutscene.new()
	scene.main = self
	scene.ronin = _ronin
	scene.village = $Village
	scene.stage = $Village.stage
	scene.game_camera = _camera
	scene.finished.connect(_start_boss_fight)
	add_child(scene)


# --- Warming up (the browser version) -------------------------------------
# In a browser, the graphics card prepares (compiles) each new kind of
# material the first time it is drawn, and that can freeze the game for a
# second or more. So at the start, behind a cover, everything is shown once:
# the whole level (the camera sweeps along it) and every effect.

func _warm_up() -> void:
	_warming = true
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var cover := LoadingCover.new()
	layer.add_child(cover)
	_ronin.set_physics_process(false)
	var stage: HannyaStage = $Village.stage
	stage.set_shadow_active(true)
	var village: Village = $Village
	var puppet: RoninPuppet = _ronin.get_node("Puppet")
	var stops: Array[Vector3] = []
	for x in range(-8, int(Village.ARENA.y) - 5, 6):
		stops.append(Vector3(x, 4.2, _camera.distance))
	for x in range(int(Village.CHAMBER.x), int(Village.CANAL.y), 8):
		stops.append(Vector3(x, -2.6, _camera.distance))  # the canals and the drain pipe
	for x in range(46, 120, 8):
		stops.append(Vector3(x, 9.0, _camera.distance))  # the Rooftop Road
	stops.append(Vector3(Village.CLIMB_WALLS[1][0] - 0.7, 9.0, _camera.distance))  # up the climbing walls
	stops.append(Vector3(Village.CLIMB_WALLS[1][0] - 0.7, 13.0, _camera.distance))
	var total := stops.size() + 14
	var done := 0
	# 1. The level, from end to end.
	for stop: Vector3 in stops:
		_camera.global_position = stop
		await _two_frames()
		done += 1
		cover.progress = float(done) / total
	# 2. Every effect, once, in front of the camera at the courtyard.
	var here := Vector3(Village.ARENA.x + 5.0, 1.5, 0.0)
	_camera.global_position = Vector3(Village.ARENA.x + 5.0, 4.2, _camera.distance)
	_ronin.global_position = here
	var effects: Array[Callable] = [
		func() -> void: puppet.play_slash(Vector2(1, 0)),
		func() -> void: puppet.play_deflect(),
		func() -> void: puppet.play_block(),
		func() -> void:
			puppet.state = &"iai"
			puppet.iai_charge = 1.0,
		func() -> void:
			puppet.state = &"heal"
			puppet.heal_charge = 0.6,
		func() -> void:
			puppet.heal_charge = -1.0
			puppet.play_healed(),
		func() -> void:
			puppet.state = &"idle"
			puppet.play_draw(here.x - 3.0)
			puppet.end_draw(here.x),
		func() -> void: Confetti.burst(village, here + Vector3(1.0, 1.0, 0.0), 20),
		func() -> void:
			var drop := InkDrop.new()
			village.add_child(drop)
			drop.global_position = here + Vector3(1.5, 0.0, 0.0),
		func() -> void:
			var pool := InkPool.new()
			village.add_child(pool)
			pool.global_position = here + Vector3(-1.5, 0.0, 0.0)
			pool.open(0.05)
			pool.splash()
			pool.close(0.3, 0.1),
		func() -> void: village.set_arena_sealed(true),
		func() -> void:
			village.set_arena_sealed(false)
			var blade := InkBlade.new()
			village.add_child(blade)
			blade.global_position = here + Vector3(2.0, 1.0, 0.0)
			var mask := PhantomMask.new()
			village.add_child(mask)
			mask.global_position = here + Vector3(3.0, 2.0, 0.0)
			mask.dive_at = 0.2,
		func() -> void:
			# Hit flashes (a different look of the same paper) on her and a husk.
			stage.hannya.show_body(true)
			stage.hannya.flash(true)
			for node: Node in village.get_children():
				if node is PaperHusk:
					node.call("_set_flash", true),
		func() -> void:
			stage.hannya.flash(false)
			stage.hannya.show_body(false)
			for node: Node in village.get_children():
				if node is PaperHusk:
					node.call("_set_flash", false),
		func() -> void:
			# The new enemies, flashed, and a burning wad of paper.
			for node: Node in village.get_children():
				if node is PaperCritter:
					node.call("_set_flash", true)
			var wad := BurningPaper.new()
			village.add_child(wad)
			wad.global_position = here + Vector3(2.0, 1.5, 0.0),
		func() -> void:
			for node: Node in village.get_children():
				if node is PaperCritter:
					node.call("_set_flash", false)
			WaterFx.splash(village, here + Vector3(1.0, 0.0, 0.0), 1.0),
	]
	for effect: Callable in effects:
		effect.call()
		await _two_frames()
		done += 1
		cover.progress = float(done) / total
	# Put everything back as it was.
	puppet.state = &"idle"
	puppet.iai_charge = 0.0
	_ronin.global_position = _ronin.get("_spawn_position")
	_ronin.velocity = Vector3.ZERO
	_ronin.set_physics_process(true)
	_camera.snap_to_target()
	_warming = false
	await get_tree().create_timer(0.4).timeout
	var fade := create_tween()
	fade.tween_property(cover, "modulate:a", 0.0, 0.6)
	fade.tween_callback(layer.queue_free)


func _two_frames() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame


## After the cutscene: the Hannya steps down onto the courtyard and the fight
## begins.
func _start_boss_fight() -> void:
	var stage: HannyaStage = $Village.stage
	_boss = HannyaBoss.new()
	_boss.ronin = _ronin
	_boss.arena = Vector2(Village.ARENA.x, Village.ARENA.y)
	$Village.add_child(_boss)
	_boss.global_position = Vector3(stage.global_position.x + 1.5, stage.global_position.y, 0.0)
	_boss.take_puppet(stage.hannya)
	_boss_bar = BossBar.new()
	_boss_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	$Overlay.add_child(_boss_bar)
	_boss_bar.watch(_boss)
	_boss.defeated.connect(func() -> void:
		SaveGame.hannya_fallen = true
		SaveGame.write()
		$Village.relight_arena_lanterns()
		$Village.set_arena_sealed(false))
	_begin_fight()


## The pause screen (Esc, P or Start). It stays awake while the game is
## paused; the rain and music keep playing under it. No pausing during the
## loading cover or the Hannya cutscene (hold Space skips that instead).
func _build_pause() -> void:
	$Sound.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_pause = PauseMenu.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.can_pause = func() -> bool:
		for child: Node in get_children():
			if child is HannyaCutscene or child is WellCutscene:
				return false
		return not _warming
	layer.add_child(_pause)


## A sheet over the whole screen (above the HUD too), normally see-through.
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = pit_fade_color
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	layer.add_child(_fade)


## He has died: the screen fades out, he is put back together at the start,
## and the fight (if there was one) resets; then the screen fades in.
func _on_died() -> void:
	# The Smudge: the ink he carried stays where he fell (an older one is lost).
	if _smudge and is_instance_valid(_smudge):
		_smudge.dry_up()
		_smudge = null
	if _ronin.ink > 0:
		_leave_smudge(_ronin.global_position, _ronin.ink)
		_ronin.ink = 0
		_ronin.ink_changed.emit(0, _ronin.max_ink)
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, pit_fade_out).set_trans(Tween.TRANS_SINE)
	await out.finished
	_ronin.revive()
	if _boss and is_instance_valid(_boss) and _boss.health > 0 and _boss.active:
		_boss.reset()
		_boss_bar.hide_bar()
		$Village.set_arena_sealed(false)
	_camera.snap_to_target()
	await get_tree().create_timer(pit_hold).timeout
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, pit_fade_in).set_trans(Tween.TRANS_SINE)


func _begin_fight() -> void:
	_boss.begin()
	$Village.set_arena_sealed(true)


func _on_fell_in_pit() -> void:
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, pit_fade_out).set_trans(Tween.TRANS_SINE)
	await out.finished
	_ronin.respawn_at_checkpoint()
	_camera.snap_to_target()
	await get_tree().create_timer(pit_hold).timeout
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, pit_fade_in).set_trans(Tween.TRANS_SINE)


# --- Developer tools -------------------------------------------------------
# Optional launch arguments, written after a "--" on the command line:
#   --x=20                 start the Ronin at x = 20
#   --y=-4                 ...and at this height (after --x; e.g. down in the canals)
#   --screenshot=shot.png  save a picture after a moment, then quit
#   --zoom=4               put the camera this close, for a look at the Ronin
#   --face=-1              start facing left
#   --hold=move_right      hold a control down (to photograph him running)
#   --marks=0.5            start this inked (0 = blank, 1 = covered)
#   --cutscene             play the Hannya cutscene straight away
#   --pause                open the pause screen straight away
#   --well                 play the climb out of the well, as after the prologue
#   --tutorial             start the tutorial cards straight away

func _apply_debug_start() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		SaveGame.file = "user://debug_save.cfg"  # (never a real saved game)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--x="):
			_ronin.position.x = float(arg.trim_prefix("--x="))
			_ronin.position.y += 3.0
		elif arg.begins_with("--y="):
			_ronin.position.y = float(arg.trim_prefix("--y="))
		elif arg.begins_with("--zoom="):
			_camera.distance = float(arg.trim_prefix("--zoom="))
			_camera.height_offset = 0.95
			_camera.min_y = -100.0
			_camera.follow_height = 1.0  # close-ups follow him up onto platforms
			_camera.climb_zone = Vector2.ZERO  # and keep him centred, climbing or not
			_camera.under_zone = Vector2.ZERO
			_camera.min_x = -1000.0
			_camera.max_x = 1000.0
			_camera.look_ahead = 0.0
			_camera.rotation_degrees.x = 0.0
		elif arg.begins_with("--face="):
			_ronin.facing = signf(float(arg.trim_prefix("--face=")))
		elif arg.begins_with("--marks="):
			var amount := float(arg.trim_prefix("--marks="))
			_ronin.ink_absorbed = roundi(amount * _ronin.marks_full_at)
			_ronin.get_node("Puppet").set_marks_now(amount)
		elif arg == "--cutscene":
			_ronin.position = Vector3(Village.ARENA.x - 3.8, 1.6, 0.0)
			play_hannya_cutscene.call_deferred()
		elif arg == "--tutorial":
			_start_tutorial.call_deferred()
		elif arg == "--pause":
			(func() -> void:
				await get_tree().create_timer(0.5).timeout
				_pause.open()).call_deferred()
		elif arg == "--map":
			# The pause screen's map, with the whole village explored and two
			# shrines rested at (to see what a full map looks like).
			for layer: String in ["under", "street", "roofs"]:
				for cell in range(-5, 50):
					SaveGame.explored["%s:%d" % [layer, cell]] = true
			SaveGame.rested.assign(["paper_maker", "warehouse"])
			(func() -> void:
				await get_tree().create_timer(0.5).timeout
				_pause.open()
				_pause.menu.open_page(&"map")).call_deferred()
		elif arg.begins_with("--hold="):
			Input.action_press(arg.trim_prefix("--hold="))


func _debug_screenshot() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			await get_tree().create_timer(2.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--screenshot="))
			get_tree().quit()



# --- The saved game ----------------------------------------------------------------

## Leaves the Smudge (where he fell, on the ground below him).
func _leave_smudge(at: Vector3, ink: int) -> void:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3(0.0, 0.5, 0.0), at + Vector3(0.0, -30.0, 0.0), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	_smudge = Smudge.new()
	_smudge.ink = ink
	$Village.add_child(_smudge)
	_smudge.global_position = Vector3(at.x, (hit["position"] as Vector3).y if not hit.is_empty() else at.y, 0.0)
	SaveGame.smudge_at = _smudge.global_position
	SaveGame.smudge_ink = ink


## Shortcuts opened are kept (and saved at once: they are for good).
func _watch_shortcuts() -> void:
	var village: Village = $Village
	village.canals.shortcut_opened.connect(_on_shortcut)
	village.gatehouse.shortcut_opened.connect(_on_shortcut)
	village.rooftops.ladder.lowered_now.connect(_on_shortcut.bind(&"ladder"))


func _on_shortcut(which: StringName) -> void:
	SaveGame.opened(String(which))
	SaveGame.write()


## Continue (from the title): back at the last shrine, everything found and
## opened as it was saved.
func _continue_from_save() -> void:
	if not SaveGame.read():
		return
	var village: Village = $Village
	for shrine: RestShrine in village.find_children("*", "RestShrine", true, false):
		if shrine.shrine_id in SaveGame.rested:
			shrine.light_quietly()
		if shrine.shrine_id == SaveGame.last_shrine:
			var spot := Vector3(shrine.global_position.x, shrine.global_position.y + 0.1, 0.0)
			_ronin.global_position = spot
			_ronin.set_checkpoint(spot)
	_ronin.ink_absorbed = SaveGame.ink_absorbed
	(_ronin.get_node("Puppet") as RoninPuppet).set_marks_now(clampf(float(SaveGame.ink_absorbed) / _ronin.marks_full_at, 0.0, 1.0))
	if "grate" in SaveGame.shortcuts:
		village.canals.open_grate(true)
	if "gate" in SaveGame.shortcuts:
		village.gatehouse.open_gate(true)
	if "ladder" in SaveGame.shortcuts:
		village.rooftops.ladder.lower(true)
	for bundle: CraneBundle in village.find_children("*", "CraneBundle", true, false):
		if SaveGame.has_crane(bundle.id):
			bundle.collect(true)
	if SaveGame.smudge_at != Vector3.INF and SaveGame.smudge_ink > 0:
		_smudge = Smudge.new()
		_smudge.ink = SaveGame.smudge_ink
		village.add_child(_smudge)
		_smudge.global_position = SaveGame.smudge_at
	_camera.snap_to_target()
