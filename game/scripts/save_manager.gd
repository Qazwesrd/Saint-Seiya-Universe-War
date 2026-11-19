extends Node
## 通用 JSON 文档保存服务；角色三槽存档仍由 RPGState 管理。
signal document_saved(document_id: String, success: bool)
const SAVE_DIR := "user://system"
const FORMAT_VERSION := 1

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

func save_document(document_id: String, data: Dictionary) -> bool:
	if not _valid_id(document_id):
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path := SAVE_DIR.path_join(document_id + ".json")
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var payload := {"format_version": FORMAT_VERSION, "saved_at": Time.get_unix_time_from_system(), "data": data}
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		document_saved.emit(document_id, false)
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK
	document_saved.emit(document_id, result)
	EventBus.save_completed.emit(document_id, result)
	return result

func load_document(document_id: String, fallback: Dictionary = {}) -> Dictionary:
	if not _valid_id(document_id):
		return fallback.duplicate(true)
	var path := SAVE_DIR.path_join(document_id + ".json")
	var result := _read_document(path)
	if result.is_empty():
		result = _read_document(path + ".bak")
	return result if not result.is_empty() else fallback.duplicate(true)

func delete_document(document_id: String) -> bool:
	if not _valid_id(document_id):
		return false
	var path := SAVE_DIR.path_join(document_id + ".json")
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func _read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("format_version", 0)) != FORMAT_VERSION:
		return {}
	var data: Variant = parsed.get("data", {})
	return data if typeof(data) == TYPE_DICTIONARY else {}

func _valid_id(value: String) -> bool:
	return not value.is_empty() and value.length() <= 48 and value.is_valid_identifier()
