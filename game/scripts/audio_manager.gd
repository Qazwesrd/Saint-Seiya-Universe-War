extends Node
## Centralized offline audio routing, volume control and lightweight crossfades.
## Audio remains silent until authored AudioStream assets are assigned by the game.

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var ui_pool: Array[AudioStreamPlayer] = []
var music_tween: Tween
var ambience_tween: Tween
var music_fade_duration := 0.65
var ambience_fade_duration := 1.0
var _music_generation := 0

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("Ambience")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	music_player = _make_player("Music", "MusicPlayer")
	ambience_player = _make_player("Ambience", "AmbiencePlayer")
	music_player.volume_db = -36.0
	ambience_player.volume_db = -36.0
	for index in range(10):
		sfx_pool.append(_make_player("SFX", "SFX_%02d" % index))
	for index in range(4):
		ui_pool.append(_make_player("UI", "UI_%02d" % index))
	if SettingsManager.settings_changed.is_connected(_on_setting_changed) == false:
		SettingsManager.settings_changed.connect(_on_setting_changed)
	_apply_volumes()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _make_player(bus_name: String, player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"
	add_child(player)
	return player

func _on_setting_changed(section: String, _key: String, _value: Variant) -> void:
	if section == "audio":
		_apply_volumes()

func _apply_volumes() -> void:
	_set_bus_volume("Master", float(SettingsManager.get_value("audio", "master", 1.0)))
	_set_bus_volume("Music", float(SettingsManager.get_value("audio", "music", 0.75)))
	_set_bus_volume("Ambience", float(SettingsManager.get_value("audio", "ambience", 0.65)))
	_set_bus_volume("SFX", float(SettingsManager.get_value("audio", "sfx", 1.0)))
	_set_bus_volume("UI", float(SettingsManager.get_value("audio", "ui", 0.8)))

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		var amount := clampf(linear, 0.0, 1.0)
		AudioServer.set_bus_mute(index, amount <= 0.001)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.001)))

func play_music(stream: AudioStream, fade_duration: float = -1.0) -> void:
	if stream == null or not is_instance_valid(music_player):
		return
	if music_player.stream == stream and music_player.playing:
		return
	_music_generation += 1
	var generation := _music_generation
	var duration := music_fade_duration if fade_duration < 0.0 else maxf(0.0, fade_duration)
	_kill_tween(music_tween)
	if not music_player.playing or duration <= 0.0:
		music_player.stream = stream
		music_player.volume_db = 0.0
		music_player.play()
		return
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", -36.0, duration * 0.45)
	music_tween.tween_callback(_replace_music.bind(stream, generation, duration * 0.55))

func _replace_music(stream: AudioStream, generation: int, fade_in: float) -> void:
	if generation != _music_generation or not is_instance_valid(music_player):
		return
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = -36.0
	music_player.play()
	_kill_tween(music_tween)
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", 0.0, maxf(0.01, fade_in))

func play_ambience(stream: AudioStream, fade_duration: float = -1.0) -> void:
	if stream == null or not is_instance_valid(ambience_player):
		return
	if ambience_player.stream == stream and ambience_player.playing:
		return
	var duration := ambience_fade_duration if fade_duration < 0.0 else maxf(0.0, fade_duration)
	_kill_tween(ambience_tween)
	if not ambience_player.playing or duration <= 0.0:
		ambience_player.stream = stream
		ambience_player.volume_db = 0.0
		ambience_player.play()
		return
	ambience_tween = create_tween()
	ambience_tween.tween_property(ambience_player, "volume_db", -36.0, duration * 0.5)
	ambience_tween.tween_callback(_replace_ambience.bind(stream, duration * 0.5))

func _replace_ambience(stream: AudioStream, fade_in: float) -> void:
	if not is_instance_valid(ambience_player):
		return
	ambience_player.stop()
	ambience_player.stream = stream
	ambience_player.volume_db = -36.0
	ambience_player.play()
	_kill_tween(ambience_tween)
	ambience_tween = create_tween()
	ambience_tween.tween_property(ambience_player, "volume_db", 0.0, maxf(0.01, fade_in))

func play_sfx(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	_play_from_pool(sfx_pool, stream, pitch, volume_db)

func play_ui(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	_play_from_pool(ui_pool, stream, pitch, volume_db)

func _play_from_pool(pool: Array[AudioStreamPlayer], stream: AudioStream, pitch: float, volume_db: float) -> void:
	if stream == null:
		return
	for player in pool:
		if not is_instance_valid(player) or player.playing:
			continue
		player.stream = stream
		player.pitch_scale = clampf(pitch, 0.5, 2.0)
		player.volume_db = clampf(volume_db, -18.0, 6.0)
		player.play()
		return

func stop_music(fade_duration: float = 0.35) -> void:
	_music_generation += 1
	_kill_tween(music_tween)
	if not is_instance_valid(music_player) or not music_player.playing:
		return
	if fade_duration <= 0.0:
		music_player.stop()
		return
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", -36.0, fade_duration)
	music_tween.tween_callback(music_player.stop)

func stop_ambience(fade_duration: float = 0.5) -> void:
	_kill_tween(ambience_tween)
	if not is_instance_valid(ambience_player) or not ambience_player.playing:
		return
	if fade_duration <= 0.0:
		ambience_player.stop()
		return
	ambience_tween = create_tween()
	ambience_tween.tween_property(ambience_player, "volume_db", -36.0, fade_duration)
	ambience_tween.tween_callback(ambience_player.stop)

func stop_all() -> void:
	_music_generation += 1
	_kill_tween(music_tween)
	_kill_tween(ambience_tween)
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.volume_db = 0.0
	if is_instance_valid(ambience_player):
		ambience_player.stop()
		ambience_player.volume_db = 0.0
	for player in sfx_pool + ui_pool:
		if is_instance_valid(player):
			player.stop()

func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
