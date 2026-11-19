extends Node
## 音频总控；未导入音频资源时保持静默。
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("Ambience")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	music_player = _make_player("Music")
	ambience_player = _make_player("Ambience")
	for index in range(8):
		sfx_pool.append(_make_player("SFX"))
	SettingsManager.settings_changed.connect(_on_setting_changed)
	_apply_volumes()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"
	add_child(player)
	return player

func _on_setting_changed(section: String, _key: String, _value: Variant) -> void:
	if section == "audio":
		_apply_volumes()

func _apply_volumes() -> void:
	_set_bus_volume("Master", float(SettingsManager.get_value("audio", "master", 1.0)))
	_set_bus_volume("Music", float(SettingsManager.get_value("audio", "music", 0.75)))
	_set_bus_volume("SFX", float(SettingsManager.get_value("audio", "sfx", 1.0)))
	_set_bus_volume("UI", float(SettingsManager.get_value("audio", "ui", 0.8)))

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		var amount := clampf(linear, 0.0, 1.0)
		AudioServer.set_bus_mute(index, amount <= 0.001)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.001)))

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	music_player.stream = stream
	music_player.play()

func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for player in sfx_pool:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = clampf(pitch, 0.5, 2.0)
			player.play()
			return

func stop_all() -> void:
	music_player.stop()
	ambience_player.stop()
	for player in sfx_pool:
		player.stop()
