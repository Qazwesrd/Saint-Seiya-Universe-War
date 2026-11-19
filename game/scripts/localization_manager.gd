extends Node
## 轻量离线本地化入口，后续可扩展为 Godot Translation 资源。
signal locale_changed(locale: String)
var current_locale := "zh_CN"
const TEXTS := {
	"zh_CN": {
		"ui.attack": "普攻", "ui.dodge": "闪避", "ui.skill": "技能",
		"ui.character": "角色", "ui.inventory": "背包", "ui.equipment": "装备",
		"ui.settings": "设置", "ui.quit": "退出", "common.confirm": "确认",
		"common.cancel": "取消", "common.close": "关闭", "system.save_ok": "保存成功",
		"system.save_failed": "保存失败", "system.offline": "离线模式"
	},
	"en_US": {
		"ui.attack": "Attack", "ui.dodge": "Dodge", "ui.skill": "Skill",
		"ui.character": "Character", "ui.inventory": "Inventory", "ui.equipment": "Equipment",
		"ui.settings": "Settings", "ui.quit": "Quit", "common.confirm": "Confirm",
		"common.cancel": "Cancel", "common.close": "Close", "system.save_ok": "Saved",
		"system.save_failed": "Save failed", "system.offline": "Offline mode"
	}
}

func _ready() -> void:
	set_locale(str(SettingsManager.get_value("system", "language", "zh_CN")))

func set_locale(locale: String) -> void:
	current_locale = locale if TEXTS.has(locale) else "zh_CN"
	locale_changed.emit(current_locale)

func text_for(key: String, fallback: String = "") -> String:
	var table: Dictionary = TEXTS.get(current_locale, TEXTS["zh_CN"])
	if table.has(key):
		return str(table[key])
	return fallback if fallback != "" else key
