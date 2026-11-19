extends Node
## 本地设置服务：图像、音频、镜头、触控、辅助与语言。
signal settings_changed(section: String, key: String, value: Variant)
const CONFIG_PATH := "user://settings.cfg"
const DEFAULTS := {
	"graphics": {"quality": "medium", "fps_limit": 60, "render_scale": 1.0, "shadows": true, "effects": true},
	"audio": {"master": 1.0, "music": 0.75, "sfx": 1.0, "ui": 0.8},
	"camera": {"distance": 7.5, "sensitivity": 1.0, "invert_y": false},
	"controls": {"vibration": true, "auto_pickup": true, "left_handed": false, "button_scale": 1.0},
	"gameplay": {"auto_target": false, "damage_numbers": true, "show_tutorials": true},
	"system": {"language": "zh_CN"}
}
var values: Dictionary = {}

func _ready() -> void:
	load_settings()
	apply_settings()

func load_settings() -> void:
	values = DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for section in DEFAULTS:
		for key in DEFAULTS[section]:
			values[section][key] = config.get_value(section, key, DEFAULTS[section][key])

func save_settings() -> bool:
	var config := ConfigFile.new()
	for section in values:
		for key in values[section]:
			config.set_value(section, key, values[section][key])
	return config.save(CONFIG_PATH) == OK

func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	if values.has(section) and values[section].has(key):
		return values[section][key]
	return fallback

func set_value(section: String, key: String, value: Variant, persist: bool = true) -> bool:
	if not values.has(section):
		values[section] = {}
	values[section][key] = value
	if persist and not save_settings():
		return false
	settings_changed.emit(section, key, value)
	EventBus.settings_changed.emit(section, key, value)
	return true

func apply_settings() -> void:
	Engine.max_fps = clampi(int(get_value("graphics", "fps_limit", 60)), 30, 120)
