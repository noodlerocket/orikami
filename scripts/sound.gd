class_name Sound
extends Node
## All the game's sound. The files in audio/ were generated with ElevenLabs
## (audio/README.md lists what each one is and the words used to make it).
##
## Any script can play a sound without knowing where this node is:
##     Sound.play(self, &"slash")
##
## This node also keeps the weather going: two layers of rain that never
## stop, and wind that swells and fades with the same gusts that swing the
## lanterns and blow the Ronin's cloak.
##
## Press M in the game to mute or unmute everything.

const FOLDER := "res://audio/"
## Each sound: the files to choose between (a random one each time, so
## repeats do not sound identical), how loud it is in decibels (0 = as
## recorded, negative = quieter), and how much its pitch varies.
const SOUNDS := {
	&"step": {"files": ["step_1.mp3", "step_2.mp3", "step_3.mp3"], "volume": -15.0, "vary": 0.1},
	&"jump": {"files": ["jump.mp3"], "volume": -11.0, "vary": 0.06},
	&"land": {"files": ["land.mp3"], "volume": -9.0, "vary": 0.06},
	&"dash": {"files": ["dash.mp3"], "volume": -7.0, "vary": 0.05},
	&"slash": {"files": ["slash_1.mp3"], "volume": -7.0, "vary": 0.06},
	&"paper_cut": {"files": ["paper_cut_1.mp3", "paper_cut_2.mp3"], "volume": -3.0, "vary": 0.08},
	&"paper_burst": {"files": ["paper_burst.mp3"], "volume": -4.0, "vary": 0.06},
	&"hurt": {"files": ["hurt.mp3"], "volume": -5.0, "vary": 0.05},
	&"heal": {"files": ["heal.mp3"], "volume": -10.0, "vary": 0.0},
	&"parry": {"files": ["parry.mp3"], "volume": -4.0, "vary": 0.05},
	&"stagger": {"files": ["stagger.mp3"], "volume": -8.0, "vary": 0.04},
	# The Hannya cutscene.
	&"lantern_snuff": {"files": ["lantern_snuff.mp3"], "volume": -8.0, "vary": 0.05},
	&"mask_creak": {"files": ["mask_creak.mp3"], "volume": -6.0, "vary": 0.03},
	&"ink_bleed": {"files": ["ink_bleed.mp3"], "volume": -6.0, "vary": 0.0},
	&"paper_rip": {"files": ["paper_rip.mp3"], "volume": -3.0, "vary": 0.07},
	&"taiko_hit": {"files": ["taiko_hit.mp3"], "volume": -2.0, "vary": 0.0},
	&"hannya_wail": {"files": ["hannya_wail.mp3"], "volume": -5.0, "vary": 0.05},
	&"draw_ready": {"files": ["draw_ready.mp3"], "volume": -9.0, "vary": 0.0},
	&"draw_gleam": {"files": ["draw_gleam.mp3"], "volume": -8.0, "vary": 0.03},
	&"shrine_rest": {"files": ["shrine_rest.mp3"], "volume": -7.0, "vary": 0.0},
	&"hannya_sob_short": {"files": ["hannya_sob_short.mp3"], "volume": -6.0, "vary": 0.06},
	# The prologue: each pop-up folding up off the page.
	&"paper_fold": {"files": ["paper_fold.mp3"], "volume": -6.0, "vary": 0.12},
	# The expanded village: water, planks, the grate, the bell.
	&"splash": {"files": ["splash.mp3"], "volume": -8.0, "vary": 0.08},
	&"wade": {"files": ["wade.mp3"], "volume": -8.0, "vary": 0.12},
	&"plank_creak": {"files": ["plank_creak.mp3"], "volume": -6.0, "vary": 0.1},
	&"plank_snap": {"files": ["plank_snap.mp3"], "volume": -4.0, "vary": 0.06},
	&"grate_clank": {"files": ["grate_clank.mp3"], "volume": -7.0, "vary": 0.08},
	&"fire_bell": {"files": ["fire_bell.mp3"], "volume": -9.0, "vary": 0.03},
	# The new enemies.
	&"dog_growl": {"files": ["dog_growl.mp3"], "volume": -9.0, "vary": 0.08},
	&"dog_bark": {"files": ["dog_bark.mp3"], "volume": -9.0, "vary": 0.08},
	&"dog_yelp": {"files": ["dog_yelp.mp3"], "volume": -9.0, "vary": 0.08},
	&"bird_shriek": {"files": ["bird_shriek.mp3"], "volume": -11.0, "vary": 0.1},
	&"fire_whoosh": {"files": ["fire_whoosh.mp3"], "volume": -8.0, "vary": 0.08},
	&"fire_burst": {"files": ["fire_burst.mp3"], "volume": -8.0, "vary": 0.08},
	# Moving: a skid, shaking off water; cranes found.
	&"skid": {"files": ["skid.mp3"], "volume": -10.0, "vary": 0.1},
	&"shake_off": {"files": ["shake_off.mp3"], "volume": -8.0, "vary": 0.06},
	&"cranes_rise": {"files": ["cranes_rise.mp3"], "volume": -6.0, "vary": 0.03},
	&"birds_scatter": {"files": ["birds_scatter.mp3"], "volume": -8.0, "vary": 0.08},
}

## The rain, wind and village music loops (off for the prologue, which has
## its own music).
@export var ambience := true

@export_group("Volume (decibels)")
## Everything at once.
@export var master_volume := 0.0
## Added to every one-off sound (steps, cuts, hits).
@export var effects_volume := 0.0
@export var rain_volume := -16.0
## The village music (shakuhachi and koto), under the rain. M mutes it too.
@export var music_volume := -12.0
## The wind when it is only a breeze, and at the height of a gust.
@export var wind_quiet := -30.0
@export var wind_loud := -11.0

## The player's own volume settings (0 to 1), set in the pause menu and
## remembered between plays in user://settings.cfg. "Sounds" covers
## everything that is not music: steps, cuts, rain and wind.
static var music_level := 1.0
static var sounds_level := 1.0
static var _levels_loaded := false

const SETTINGS_FILE := "user://settings.cfg"

var _streams := {}                       # sound name -> the loaded files
var _voices: Array[AudioStreamPlayer] = []  # a few players, shared by all one-off sounds
var _next_voice := 0
var _rain_near: AudioStreamPlayer
var _rain_far: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _music: AudioStreamPlayer
var _wind_hush := 0.0   # taken off the wind while the rain is hushed
var _rain_drop := 0.0   # taken off the rain while it is hushed
var _music_ducked := false


## Plays a one-off sound from anywhere. `from` is any node in the scene.
static func play(from: Node, sound: StringName, louder: float = 0.0) -> void:
	if from.is_inside_tree():
		from.get_tree().call_group(&"sound", &"play_sound", sound, louder)


func _ready() -> void:
	add_to_group(&"sound")
	Sound.load_levels()
	AudioServer.set_bus_volume_db(0, master_volume)
	for sound: StringName in SOUNDS:
		var files: Array[AudioStream] = []
		for file: String in SOUNDS[sound]["files"]:
			var stream := load(FOLDER + file) as AudioStream
			if stream:
				files.append(stream)
		_streams[sound] = files
	for i in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	if not ambience:
		return
	# Two rain layers at slightly different speeds, so the pattern of drops
	# takes a long time to repeat.
	_rain_near = _start_loop("rain_close.mp3", rain_volume + _sounds_db(), 1.0)
	_rain_far = _start_loop("rain_far.mp3", rain_volume - 3.0 + _sounds_db(), 0.93)
	_wind = _start_loop("wind.mp3", wind_quiet + _sounds_db(), 1.0)
	# The music loops seamlessly on its own (its end was blended into its
	# start when it was made); OGG, unlike MP3, adds no gap at the seam.
	var music := load(FOLDER + "music_village.ogg") as AudioStreamOggVorbis
	if music:
		music.loop = true
		_music = AudioStreamPlayer.new()
		_music.stream = music
		_music.volume_db = music_volume + _music_db()
		add_child(_music)
		_music.play()


func _process(_delta: float) -> void:
	# The wind is as loud as the gust passing the camera.
	var camera := get_viewport().get_camera_3d()
	if camera == null or _wind == null:
		return
	var gust := clampf((Wind.speed_at(camera.global_position.x) - Wind.breeze) / maxf(Wind.gusts, 0.1), 0.0, 1.0)
	_wind.volume_db = lerpf(wind_quiet, wind_loud, sqrt(gust)) + _wind_hush + _sounds_db()
	_wind.pitch_scale = lerpf(0.92, 1.1, gust)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


## Fades the village music out (true) or back in (false), from anywhere.
static func duck_music(on: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.call_group(&"sound", &"_fade_music", on)


## Hushes the rain and wind (true) or brings them back (false).
static func duck_rain(on: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.call_group(&"sound", &"_fade_rain", on)


func _fade_music(on: bool) -> void:
	if _music:
		_music_ducked = on
		create_tween().tween_property(_music, "volume_db", -60.0 if on else music_volume + _music_db(), 1.5)


func _fade_rain(on: bool) -> void:
	var drop := -14.0 if on else 0.0
	var t := create_tween().set_parallel()
	_rain_drop = drop
	if _rain_near:
		t.tween_property(_rain_near, "volume_db", rain_volume + drop + _sounds_db(), 1.2)
	if _rain_far:
		t.tween_property(_rain_far, "volume_db", rain_volume - 3.0 + drop + _sounds_db(), 1.2)
	_wind_hush = drop


## Plays one of the files for `sound`. (Called through Sound.play.)
func play_sound(sound: StringName, louder: float = 0.0) -> void:
	var files: Array = _streams.get(sound, [])
	if files.is_empty():
		return
	var settings: Dictionary = SOUNDS[sound]
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = files[randi() % files.size()]
	voice.volume_db = settings["volume"] + effects_volume + louder + _sounds_db()
	var vary: float = settings["vary"]
	voice.pitch_scale = 1.0 + randf_range(-vary, vary)
	voice.play()


func _start_loop(file: String, volume: float, pitch: float) -> AudioStreamPlayer:
	var stream := load(FOLDER + file) as AudioStreamMP3
	if stream == null:
		return null
	stream.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	player.pitch_scale = pitch
	add_child(player)
	player.play()
	return player


# --- The player's volume settings -------------------------------------------------

static func _music_db() -> float:
	return linear_to_db(maxf(music_level, 0.0001))


static func _sounds_db() -> float:
	return linear_to_db(maxf(sounds_level, 0.0001))


## Reads the saved volume settings (once).
static func load_levels() -> void:
	if _levels_loaded:
		return
	_levels_loaded = true
	var file := ConfigFile.new()
	if file.load(SETTINGS_FILE) == OK:
		music_level = clampf(float(file.get_value("volume", "music", 1.0)), 0.0, 1.0)
		sounds_level = clampf(float(file.get_value("volume", "sounds", 1.0)), 0.0, 1.0)


## Changes a volume setting by `step` tenths, applies it at once and saves it.
## Returns the new level. (Used by the pause menu's sliders.)
static func change_level(which: StringName, step: int) -> float:
	var level := music_level if which == &"music" else sounds_level
	level = clampf(snappedf(level + step * 0.1, 0.1), 0.0, 1.0)
	if which == &"music":
		music_level = level
	else:
		sounds_level = level
	if step != 0:
		var file := ConfigFile.new()
		file.load(SETTINGS_FILE)
		file.set_value("volume", "music", music_level)
		file.set_value("volume", "sounds", sounds_level)
		file.save(SETTINGS_FILE)
		var tree := Engine.get_main_loop() as SceneTree
		tree.call_group(&"sound", &"_apply_levels")
	return level


## For a player made somewhere else (the boss's music, the cutscene's): sets
## its volume to `base_db` plus the player's music or sounds setting, and keeps
## it there when the setting changes.
static func follow_level(player: AudioStreamPlayer, base_db: float, which: StringName = &"music") -> void:
	player.set_meta(&"base_db", base_db)
	player.add_to_group(&"music_level" if which == &"music" else &"sounds_level")
	player.volume_db = base_db + (_music_db() if which == &"music" else _sounds_db())


func _apply_levels() -> void:
	for player: AudioStreamPlayer in get_tree().get_nodes_in_group(&"music_level"):
		player.volume_db = float(player.get_meta(&"base_db")) + _music_db()
	for player: AudioStreamPlayer in get_tree().get_nodes_in_group(&"sounds_level"):
		player.volume_db = float(player.get_meta(&"base_db")) + _sounds_db()
	if _music and not _music_ducked:
		_music.volume_db = music_volume + _music_db()
	if _rain_near:
		_rain_near.volume_db = rain_volume + _rain_drop + _sounds_db()
	if _rain_far:
		_rain_far.volume_db = rain_volume - 3.0 + _rain_drop + _sounds_db()



## A looping sound standing somewhere in the level (running water, the
## river): it is heard louder as the camera comes near and fades with
## distance. `file` is in audio/ (a seamless OGG loop).
static func place_loop(parent: Node3D, file: String, at: Vector3, volume: float, reach: float) -> AudioStreamPlayer3D:
	var stream := load(FOLDER + file) as AudioStreamOggVorbis
	if stream == null:
		return null
	stream.loop = true
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume + _sounds_db()
	player.unit_size = reach
	player.max_distance = reach * 3.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.autoplay = true
	parent.add_child(player)
	player.position = at
	return player
