extends Node
## 本地设置服务：校验、持久化并广播图像、音频、镜头、触控、玩法和语言设置。
signal settings_changed(section: String, key: String, value: Variant)
signal settings_loaded
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
	if config.load(CONFIG_PATH) == OK:
		for section in DEFAULTS:
			for key in DEFAULTS[section]:
				values[section][key] = _sanitize_value(str(section), str(key), config.get_value(section, key, DEFAULTS[section][key]))
	settings_loaded.emit()

func save_settings() -> bool:
	var config := ConfigFile.new()
	for section in DEFAULTS:
		for key in DEFAULTS[section]:
			config.set_value(section, key, get_value(str(section), str(key), DEFAULTS[section][key]))
	return config.save(CONFIG_PATH) == OK

func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	if values.has(section) and values[section].has(key):
		return values[section][key]
	return fallback

func set_value(section: String, key: String, value: Variant, persist: bool = true) -> bool:
	if not DEFAULTS.has(section) or not DEFAULTS[section].has(key):
		return false
	var safe_value: Variant = _sanitize_value(section, key, value)
	var previous: Variant = get_value(section, key, DEFAULTS[section][key])
	values[section][key] = safe_value
	if persist and not save_settings():
		values[section][key] = previous
		return false
	if section == "system" and key == "language":
		LocalizationManager.set_locale(str(safe_value))
	if section == "graphics" and key == "fps_limit":
		apply_settings()
	settings_changed.emit(section, key, safe_value)
	EventBus.settings_changed.emit(section, key, safe_value)
	return true

func reset_section(section: String) -> bool:
	if not DEFAULTS.has(section):
		return false
	var previous: Dictionary = values.get(section, {}).duplicate(true)
	values[section] = DEFAULTS[section].duplicate(true)
	if not save_settings():
		values[section] = previous
		return false
	apply_settings()
	for key in values[section]:
		settings_changed.emit(section, str(key), values[section][key])
		EventBus.settings_changed.emit(section, str(key), values[section][key])
	return true

func reset_all() -> bool:
	var previous: Dictionary = values.duplicate(true)
	values = DEFAULTS.duplicate(true)
	if not save_settings():
		values = previous
		return false
	apply_settings()
	LocalizationManager.set_locale(str(values["system"]["language"]))
	for section in values:
		for key in values[section]:
			settings_changed.emit(str(section), str(key), values[section][key])
			EventBus.settings_changed.emit(str(section), str(key), values[section][key])
	return true

func apply_settings() -> void:
	Engine.max_fps = clampi(int(get_value("graphics", "fps_limit", 60)), 30, 120)

func _sanitize_value(section: String, key: String, value: Variant) -> Variant:
	if section == "graphics":
		if key == "quality":
			return str(value) if str(value) in ["low", "medium", "high"] else "medium"
		if key == "fps_limit":
			return clampi(int(value), 30, 120)
		if key == "render_scale":
			return snappedf(clampf(float(value), 0.5, 1.0), 0.05)
		if key in ["shadows", "effects"]:
			return bool(value)
	if section == "audio":
		return clampf(float(value), 0.0, 1.0)
	if section == "camera":
		if key == "distance":
			return clampf(float(value), 3.0, 14.0)
		if key == "sensitivity":
			return clampf(float(value), 0.2, 3.0)
		return bool(value)
	if section == "controls":
		if key == "button_scale":
			return clampf(float(value), 0.75, 1.5)
		return bool(value)
	if section == "gameplay":
		return bool(value)
	if section == "system" and key == "language":
		return str(value) if str(value) in ["zh_CN", "en_US"] else "zh_CN"
	return DEFAULTS[section][key]
