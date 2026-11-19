extends Node
## 离线章节资源包管理：清单、校验、容量统计和卸载，不联网下载。
signal pack_catalog_loaded
signal pack_validation_finished(pack_id: String, valid: bool, message: String)
const PACK_ROOT := "user://content_packs"
const CATALOG_PATH := "res://content/pack_catalog.json"
var catalog: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PACK_ROOT))
	load_catalog()

func load_catalog() -> void:
	catalog = {}
	if FileAccess.file_exists(CATALOG_PATH):
		var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				catalog = parsed
	pack_catalog_loaded.emit()

func get_pack_info(pack_id: String) -> Dictionary:
	var packs: Dictionary = catalog.get("packs", {})
	return packs.get(pack_id, {}).duplicate(true) if packs.has(pack_id) else {}

func list_installed_packs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := DirAccess.open(PACK_ROOT)
	if directory == null:
		return result
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if directory.current_is_dir() and not entry.begins_with("."):
			var pack := _read_pack_manifest(entry)
			if not pack.is_empty():
				result.append(pack)
		entry = directory.get_next()
	directory.list_dir_end()
	return result

func validate_pack(pack_id: String) -> Dictionary:
	if not _valid_pack_id(pack_id):
		return {"valid": false, "message": "资源包编号无效"}
	var folder := PACK_ROOT.path_join(pack_id)
	var manifest_path := folder.path_join("pack.json")
	if not FileAccess.file_exists(manifest_path):
		return {"valid": false, "message": "缺少 pack.json"}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return {"valid": false, "message": "无法读取资源包清单"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"valid": false, "message": "资源包清单格式错误"}
	var entries: Array = parsed.get("files", [])
	var failures: Array[String] = []
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var relative := str(item.get("path", ""))
		if relative.is_empty() or relative.begins_with("/") or relative.contains(".."):
			failures.append("非法路径：" + relative)
			continue
		var full_path := folder.path_join(relative)
		if not FileAccess.file_exists(full_path):
			failures.append(relative)
			continue
		var expected_hash := str(item.get("sha256", ""))
		if expected_hash != "" and FileAccess.get_sha256(full_path).to_lower() != expected_hash.to_lower():
			failures.append("校验失败：" + relative)
	var valid := failures.is_empty()
	var message := "资源包完整" if valid else "资源缺失或校验失败：" + ", ".join(failures.slice(0, 5))
	pack_validation_finished.emit(pack_id, valid, message)
	return {"valid": valid, "message": message, "checked_files": entries.size()}

func get_installed_size_bytes() -> int:
	var total := 0
	for pack in list_installed_packs():
		total += int(pack.get("size_bytes", 0))
	return total

func remove_pack(pack_id: String) -> bool:
	if not _valid_pack_id(pack_id):
		return false
	var folder := PACK_ROOT.path_join(pack_id)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		return false
	return _remove_directory(folder)

func _read_pack_manifest(pack_id: String) -> Dictionary:
	var path := PACK_ROOT.path_join(pack_id).path_join("pack.json")
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = parsed.duplicate(true)
	result["id"] = pack_id
	return result

func _remove_directory(path: String) -> bool:
	var directory := DirAccess.open(path)
	if directory == null:
		return false
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var child := path.path_join(entry)
		if directory.current_is_dir():
			if not _remove_directory(child):
				directory.list_dir_end()
				return false
		else:
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(child)) != OK:
				directory.list_dir_end()
				return false
		entry = directory.get_next()
	directory.list_dir_end()
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func _valid_pack_id(value: String) -> bool:
	return not value.is_empty() and value.is_valid_identifier()
