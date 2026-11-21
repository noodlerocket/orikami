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
	&"hannya_sob_short": {"files": ["hannya_sob.mp3"], "volume": -6.0, "vary": 0.06},
}

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

var _streams := {}                       # sound name -> the loaded files
var _voices: Array[AudioStreamPlayer] = []  # a few players, shared by all one-off sounds
var _next_voice := 0
var _rain_near: AudioStreamPlayer
var _rain_far: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _music: AudioStreamPlayer
var _wind_hush := 0.0   # taken off the wind while the rain is hushed


## Plays a one-off sound from anywhere. `from` is any node in the scene.
static func play(from: Node, sound: StringName, louder: float = 0.0) -> void:
	if from.is_inside_tree():
		from.get_tree().call_group(&"sound", &"play_sound", sound, louder)


func _ready() -> void:
	add_to_group(&"sound")
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
	# Two rain layers at slightly different speeds, so the pattern of drops
	# takes a long time to repeat.
	_rain_near = _start_loop("rain_close.mp3", rain_volume, 1.0)
	_rain_far = _start_loop("rain_far.mp3", rain_volume - 3.0, 0.93)
	_wind = _start_loop("wind.mp3", wind_quiet, 1.0)
	# The music loops seamlessly on its own (its end was blended into its
	# start when it was made); OGG, unlike MP3, adds no gap at the seam.
	var music := load(FOLDER + "music_village.ogg") as AudioStreamOggVorbis
	if music:
		music.loop = true
		_music = AudioStreamPlayer.new()
		_music.stream = music
		_music.volume_db = music_volume
		add_child(_music)
		_music.play()


func _process(_delta: float) -> void:
	# The wind is as loud as the gust passing the camera.
	var camera := get_viewport().get_camera_3d()
	if camera == null or _wind == null:
		return
	var gust := clampf((Wind.speed_at(camera.global_position.x) - Wind.breeze) / maxf(Wind.gusts, 0.1), 0.0, 1.0)
	_wind.volume_db = lerpf(wind_quiet, wind_loud, sqrt(gust)) + _wind_hush
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
		create_tween().tween_property(_music, "volume_db", -60.0 if on else music_volume, 1.5)


func _fade_rain(on: bool) -> void:
	var drop := -14.0 if on else 0.0
	var t := create_tween().set_parallel()
	if _rain_near:
		t.tween_property(_rain_near, "volume_db", rain_volume + drop, 1.2)
	if _rain_far:
		t.tween_property(_rain_far, "volume_db", rain_volume - 3.0 + drop, 1.2)
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
	voice.volume_db = settings["volume"] + effects_volume + louder
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
