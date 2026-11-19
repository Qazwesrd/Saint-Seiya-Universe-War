extends Node
## 全局事件总线：系统间使用信号解耦。
signal notice_requested(message: String, duration: float)
signal scene_change_requested(scene_path: String)
signal player_profile_changed(profile: Dictionary)
signal quest_updated(quest_id: String, state: Dictionary)
signal inventory_changed(inventory: Dictionary)
signal equipment_changed(equipment: Dictionary)
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal resource_pack_changed(pack_id: String, state: String)
signal settings_changed(section: String, key: String, value: Variant)
signal save_completed(save_id: String, success: bool)
signal combat_event(event_id: String, payload: Dictionary)
signal system_error_reported(category: String, message: String, details: String)

func notify(message: String, duration: float = 2.5) -> void:
	notice_requested.emit(message, duration)
