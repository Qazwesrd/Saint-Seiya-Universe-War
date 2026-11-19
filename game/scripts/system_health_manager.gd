extends Node
## 本地系统诊断与错误日志；不上传数据，不依赖网络。
signal error_recorded(category: String, message: String)
const LOG_DIRECTORY := "user://logs"
const LOG_PATH := "user://logs/system.log"
const MAX_LOG_BYTES := 1024 * 1024
const MAX_LOG_LINES := 500
var recent_errors: Array[Dictionary] = []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_DIRECTORY))

func report_error(category: String, message: String, details: String = "") -> void:
	var entry := {
		"time": Time.get_datetime_string_from_system(true),
		"category": category.substr(0, 64),
		"message": message.substr(0, 512),
		"details": details.substr(0, 2048)
	}
	recent_errors.append(entry)
	while recent_errors.size() > 50:
		recent_errors.pop_front()
	_append_log(entry)
	error_recorded.emit(str(entry["category"]), str(entry["message"]))
	EventBus.system_error_reported.emit(str(entry["category"]), str(entry["message"]), str(entry["details"]))
	EventBus.notify("系统提示：" + str(entry["message"]), 4.0)

func get_recent_errors() -> Array[Dictionary]:
	return recent_errors.duplicate(true)

func clear_log() -> bool:
	if not FileAccess.file_exists(LOG_PATH):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH)) == OK

func _append_log(entry: Dictionary) -> void:
	if FileAccess.file_exists(LOG_PATH) and FileAccess.get_length(LOG_PATH) > MAX_LOG_BYTES:
		var old := FileAccess.open(LOG_PATH, FileAccess.READ)
		if old != null:
			var content := old.get_as_text()
			old.close()
			var lines := content.split("\n", false)
			var keep_from := maxi(0, lines.size() - MAX_LOG_LINES / 2)
			var trimmed := "\n".join(lines.slice(keep_from, lines.size()))
			var rotated := FileAccess.open(LOG_PATH, FileAccess.WRITE)
			if rotated != null:
				rotated.store_string(trimmed + "\n")
				rotated.close()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(entry))
	file.close()
