extends Node
## Android应用生命周期处理：后台暂停时保存当前角色与设置，恢复时广播事件。
signal application_paused
signal application_resumed
var pause_save_succeeded := true
var last_pause_timestamp := 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_pause()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		application_resumed.emit()
		EventBus.notify("游戏已恢复", 1.5)

func _handle_pause() -> void:
	last_pause_timestamp = int(Time.get_unix_time_from_system())
	var character_saved: bool = bool(RPGState.save_slot(RPGState.active_slot))
	var settings_saved: bool = bool(SettingsManager.save_settings())
	pause_save_succeeded = character_saved and settings_saved
	application_paused.emit()
	if not pause_save_succeeded:
		SystemHealthManager.report_error("lifecycle", "后台保存未完全成功", "character_saved=%s settings_saved=%s" % [str(character_saved), str(settings_saved)])

func get_last_pause_timestamp() -> int:
	return last_pause_timestamp
