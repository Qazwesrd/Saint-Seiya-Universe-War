extends Node
## 完全离线资源包生命周期：目录发现、依赖、空间预检、SHA-256、暂存安装、PCK挂载与安全卸载。
signal pack_catalog_loaded
signal pack_validation_finished(pack_id: String, valid: bool, message: String)
signal pack_install_finished(pack_id: String, success: bool, message: String)
signal pack_removed(pack_id: String)
const PACK_ROOT := "user://content_packs"
const STAGING_ROOT := "user://content_packs/.staging"
const CATALOG_PATH := "res://content/pack_catalog.json"
const MANIFEST_VERSION := 1
const MIN_FREE_SPACE_MARGIN := 64 * 1024 * 1024
var catalog: Dictionary = {}
var mounted_packs: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PACK_ROOT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STAGING_ROOT))
	load_catalog()

func load_catalog() -> void:
	catalog = {}
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("资源包目录缺失：" + CATALOG_PATH)
		pack_catalog_loaded.emit()
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取资源包目录")
		pack_catalog_loaded.emit()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY and typeof(parsed.get("packs", null)) == TYPE_DICTIONARY:
		catalog = parsed
	else:
		push_error("资源包目录格式无效")
	pack_catalog_loaded.emit()

func get_pack_info(pack_id: String) -> Dictionary:
	var packs: Dictionary = catalog.get("packs", {})
	return packs.get(pack_id, {}).duplicate(true) if packs.has(pack_id) else {}

func list_available_packs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pack_id in catalog.get("packs", {}):
		var info: Dictionary = get_pack_info(str(pack_id))
		info["id"] = str(pack_id)
		info["installed"] = is_pack_installed(str(pack_id))
		result.append(info)
	return result

func list_installed_packs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := DirAccess.open(PACK_ROOT)
	if directory == null:
		return result
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if directory.current_is_dir() and not entry.begins_with("."):
			var manifest := _read_pack_manifest(entry)
			if not manifest.is_empty():
				manifest["id"] = entry
				result.append(manifest)
		entry = directory.get_next()
	directory.list_dir_end()
	return result

func is_pack_installed(pack_id: String) -> bool:
	return _valid_pack_id(pack_id) and FileAccess.file_exists(PACK_ROOT.path_join(pack_id).path_join("pack.json"))

func get_pack_status(pack_id: String) -> Dictionary:
	if not get_pack_info(pack_id).is_empty() and bool(get_pack_info(pack_id).get("required", false)):
		return {"installed": true, "required": true, "valid": true, "message": "基础资源随游戏内置"}
	if not is_pack_installed(pack_id):
		return {"installed": false, "required": false, "valid": false, "message": "尚未安装"}
	return validate_pack(pack_id)

func validate_pack(pack_id: String) -> Dictionary:
	var result := _validate_directory(PACK_ROOT.path_join(pack_id), pack_id)
	pack_validation_finished.emit(pack_id, bool(result.get("valid", false)), str(result.get("message", "")))
	return result

func validate_source_directory(source_path: String, pack_id: String) -> Dictionary:
	if not _valid_pack_id(pack_id):
		return {"valid": false, "message": "资源包编号无效"}
	return _validate_directory(source_path, pack_id)

func _validate_directory(folder: String, expected_id: String) -> Dictionary:
	if not _valid_pack_id(expected_id) or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		return {"valid": false, "message": "资源包目录不存在"}
	var manifest_path := folder.path_join("pack.json")
	if not FileAccess.file_exists(manifest_path):
		return {"valid": false, "message": "缺少 pack.json"}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return {"valid": false, "message": "无法读取资源包清单"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"valid": false, "message": "资源包清单必须是 JSON 对象"}
	if str(parsed.get("id", "")) != expected_id:
		return {"valid": false, "message": "资源包 ID 与目录/目录定义不一致"}
	if int(parsed.get("manifest_version", 0)) != MANIFEST_VERSION:
		return {"valid": false, "message": "不支持的清单版本"}
	if int(parsed.get("version", 0)) < 1:
		return {"valid": false, "message": "资源包版本号无效"}
	var files: Variant = parsed.get("files", null)
	if typeof(files) != TYPE_ARRAY or files.is_empty():
		return {"valid": false, "message": "资源包 files 必须是非空数组"}
	var failures: Array[String] = []
	var seen: Dictionary = {}
	var actual_total := 0
	for item in files:
		if typeof(item) != TYPE_DICTIONARY:
			failures.append("文件条目格式错误")
			continue
		var relative := str(item.get("path", ""))
		if not _valid_relative_path(relative) or seen.has(relative):
			failures.append("非法或重复路径：" + relative)
			continue
		seen[relative] = true
		var full_path := folder.path_join(relative)
		if not FileAccess.file_exists(full_path):
			failures.append("缺失：" + relative)
			continue
		var size_reader := FileAccess.open(full_path, FileAccess.READ)
		if size_reader == null:
			failures.append("无法读取：" + relative)
			continue
		var actual_size := int(size_reader.get_length())
		size_reader.close()
		actual_total += actual_size
		if int(item.get("size_bytes", -1)) != actual_size:
			failures.append("大小不符：" + relative)
		var expected_hash := str(item.get("sha256", ""))
		if expected_hash.length() != 64 or not expected_hash.is_valid_hex_number(false):
			failures.append("SHA-256格式无效：" + relative)
		elif FileAccess.get_sha256(full_path).to_lower() != expected_hash.to_lower():
			failures.append("哈希不符：" + relative)
	var declared_size := int(parsed.get("size_bytes", -1))
	if declared_size != actual_total:
		failures.append("资源包总大小不符")
	var valid := failures.is_empty()
	var message := "资源包校验通过" if valid else "资源包校验失败：" + "；".join(failures.slice(0, 6))
	return {"valid": valid, "message": message, "checked_files": files.size(), "size_bytes": actual_total, "manifest": parsed}

func preflight_install(source_path: String, pack_id: String) -> Dictionary:
	var info := get_pack_info(pack_id)
	if info.is_empty():
		return {"allowed": false, "message": "资源包不在本地目录中"}
	if bool(info.get("required", false)):
		return {"allowed": false, "message": "基础资源包不可覆盖"}
	var validation := validate_source_directory(source_path, pack_id)
	if not bool(validation.get("valid", false)):
		return {"allowed": false, "message": str(validation.get("message", "资源包校验失败"))}
	var manifest: Dictionary = validation.get("manifest", {})
	for dependency in manifest.get("dependencies", []):
		if not is_pack_installed(str(dependency)):
			return {"allowed": false, "message": "缺少依赖资源包：" + str(dependency)}
	var needed := int(validation.get("size_bytes", 0)) + MIN_FREE_SPACE_MARGIN
	var free := _get_free_space_bytes()
	if free >= 0 and free < needed:
		return {"allowed": false, "message": "剩余空间不足，需要至少 %.1f MB" % (float(needed) / 1048576.0)}
	return {"allowed": true, "message": "空间与依赖检查通过", "required_bytes": needed, "free_bytes": free}

func install_from_directory(source_path: String, pack_id: String) -> bool:
	var preflight := preflight_install(source_path, pack_id)
	if not bool(preflight.get("allowed", false)):
		pack_install_finished.emit(pack_id, false, str(preflight.get("message", "安装预检失败")))
		return false
	var staging := STAGING_ROOT.path_join(pack_id)
	var final_path := PACK_ROOT.path_join(pack_id)
	_remove_directory_if_exists(staging)
	if not _copy_directory(source_path, staging):
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "复制到暂存目录失败")
		return false
	var staged_validation := _validate_directory(staging, pack_id)
	if not bool(staged_validation.get("valid", false)):
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, str(staged_validation.get("message", "暂存校验失败")))
		return false
	var backup := STAGING_ROOT.path_join(pack_id + ".previous")
	_remove_directory_if_exists(backup)
	var had_old := DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(final_path))
	if had_old and DirAccess.rename_absolute(ProjectSettings.globalize_path(final_path), ProjectSettings.globalize_path(backup)) != OK:
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "无法保护旧版本，已取消更新")
		return false
	var move_result := DirAccess.rename_absolute(ProjectSettings.globalize_path(staging), ProjectSettings.globalize_path(final_path))
	if move_result != OK:
		if had_old:
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup), ProjectSettings.globalize_path(final_path))
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "切换新版本失败，已回滚")
		return false
	_remove_directory_if_exists(backup)
	pack_install_finished.emit(pack_id, true, "资源包安装完成")
	EventBus.resource_pack_changed.emit(pack_id, "installed")
	return true

func mount_pack(pack_id: String) -> bool:
	if mounted_packs.has(pack_id):
		return true
	var validation := validate_pack(pack_id)
	if not bool(validation.get("valid", false)):
		return false
	var manifest: Dictionary = validation.get("manifest", {})
	var mounted := false
	for item in manifest.get("files", []):
		var relative := str(item.get("path", ""))
		if relative.to_lower().ends_with(".pck") or relative.to_lower().ends_with(".zip"):
			var path := PACK_ROOT.path_join(pack_id).path_join(relative)
			if not ProjectSettings.load_resource_pack(path, true):
				return false
			mounted = true
	if mounted:
		mounted_packs[pack_id] = true
		EventBus.resource_pack_changed.emit(pack_id, "mounted")
	return mounted

func get_installed_size_bytes() -> int:
	var total := 0
	for pack in list_installed_packs():
		total += int(pack.get("size_bytes", 0))
	return total

func get_storage_summary() -> Dictionary:
	var installed := list_installed_packs()
	var packs: Array[String] = []
	for item in installed:
		packs.append(str(item.get("id", "")))
	return {"installed_count": installed.size(), "installed_bytes": get_installed_size_bytes(), "installed_ids": packs, "free_bytes": _get_free_space_bytes()}

func remove_pack(pack_id: String) -> bool:
	if not _valid_pack_id(pack_id):
		return false
	var info := get_pack_info(pack_id)
	if info.is_empty() or bool(info.get("required", false)) or mounted_packs.has(pack_id):
		return false
	for other in list_installed_packs():
		if str(other.get("id", "")) == pack_id:
			continue
		if pack_id in other.get("dependencies", []):
			return false
	var folder := PACK_ROOT.path_join(pack_id)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		return false
	var backup := STAGING_ROOT.path_join(pack_id + ".removing")
	_remove_directory_if_exists(backup)
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(folder), ProjectSettings.globalize_path(backup)) != OK:
		return false
	if not _remove_directory(backup):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(backup), ProjectSettings.globalize_path(folder))
		return false
	pack_removed.emit(pack_id)
	EventBus.resource_pack_changed.emit(pack_id, "removed")
	return true

func _read_pack_manifest(pack_id: String) -> Dictionary:
	var path := PACK_ROOT.path_join(pack_id).path_join("pack.json")
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed.duplicate(true) if typeof(parsed) == TYPE_DICTIONARY else {}

func _valid_pack_id(value: String) -> bool:
	return not value.is_empty() and value.is_valid_identifier() and not value.begins_with(".")

func _valid_relative_path(value: String) -> bool:
	if value.is_empty() or value.begins_with("/") or value.contains("\\") or value.contains(":"):
		return false
	for segment in value.split("/"):
		if segment.is_empty() or segment == "." or segment == "..":
			return false
	return true

func _get_free_space_bytes() -> int:
	var root := ProjectSettings.globalize_path("user://")
	if root.is_empty():
		return -1
	var directory := DirAccess.open(root)
	return int(directory.get_space_left()) if directory != null else -1

func _copy_directory(source: String, destination: String) -> bool:
	var source_dir := DirAccess.open(source)
	if source_dir == null:
		return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination)) != OK:
		return false
	source_dir.list_dir_begin()
	var entry := source_dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = source_dir.get_next()
			continue
		var source_child := source.path_join(entry)
		var destination_child := destination.path_join(entry)
		if source_dir.current_is_dir():
			if not _copy_directory(source_child, destination_child):
				source_dir.list_dir_end()
				return false
		else:
			var input := FileAccess.open(source_child, FileAccess.READ)
			if input == null:
				source_dir.list_dir_end()
				return false
			var bytes := input.get_buffer(input.get_length())
			input.close()
			var output := FileAccess.open(destination_child, FileAccess.WRITE)
			if output == null:
				source_dir.list_dir_end()
				return false
			output.store_buffer(bytes)
			output.close()
		entry = source_dir.get_next()
	source_dir.list_dir_end()
	return true

func _remove_directory_if_exists(path: String) -> void:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		_remove_directory(path)

func _remove_directory(path: String) -> bool:
	var directory := DirAccess.open(path)
	if directory == null:
		return false
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = directory.get_next()
			continue
		var child := path.path_join(entry)
		var result := _remove_directory(child) if directory.current_is_dir() else DirAccess.remove_absolute(ProjectSettings.globalize_path(child)) == OK
		if not result:
			directory.list_dir_end()
			return false
		entry = directory.get_next()
	directory.list_dir_end()
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK


## 从国内 CDN 下载资源包。服务端必须支持 HTTPS、HTTP Range 和正确的 Content-Range。
## manifest_sha256 必须由随 APK 发布的可信目录固定，不能信任下载站自行声明的哈希。
signal pack_download_progress(pack_id: String, downloaded_bytes: int, total_bytes: int, current_file: String)

const DOWNLOAD_CHUNK_BYTES := 4 * 1024 * 1024
const DOWNLOAD_HTTP_BODY_LIMIT := 5 * 1024 * 1024
const DOWNLOAD_TIMEOUT_SECONDS := 90.0

func download_pack_from_cdn(pack_id: String, cdn_base_url: String, manifest_sha256: String, manifest_size_bytes: int) -> bool:
	var info := get_pack_info(pack_id)
	if info.is_empty() or bool(info.get("required", false)):
		pack_install_finished.emit(pack_id, false, "资源包编号无效或属于不可覆盖的基础资源")
		return false
	if not cdn_base_url.begins_with("https://") or not cdn_base_url.ends_with("/"):
		pack_install_finished.emit(pack_id, false, "下载地址必须是以 https:// 开头并以 / 结尾的国内 CDN 地址")
		return false
	if manifest_sha256.length() != 64 or not manifest_sha256.is_valid_hex_number(false) or manifest_size_bytes < 2 or manifest_size_bytes > 2 * 1024 * 1024:
		pack_install_finished.emit(pack_id, false, "资源清单的固定 SHA-256 或大小无效")
		return false

	var staging := STAGING_ROOT.path_join(pack_id)
	var backup := STAGING_ROOT.path_join(pack_id + ".previous")
	_remove_directory_if_exists(staging)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(staging)) != OK:
		pack_install_finished.emit(pack_id, false, "无法创建下载暂存目录")
		return false

	var manifest_path := staging.path_join("pack.json")
	var manifest_url := cdn_base_url + pack_id + "/pack.json"
	var manifest_result: Dictionary = await _download_resumable(manifest_url, manifest_path, manifest_size_bytes, manifest_sha256, pack_id, "pack.json")
	if not bool(manifest_result.get("success", false)):
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, str(manifest_result.get("message", "下载资源清单失败")))
		return false

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "无法打开下载的资源清单")
		return false
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()
	if typeof(parsed) != TYPE_DICTIONARY or str(parsed.get("id", "")) != pack_id or int(parsed.get("manifest_version", 0)) != MANIFEST_VERSION:
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "资源清单格式、编号或版本不匹配")
		return false
	var files: Variant = parsed.get("files", null)
	if typeof(files) != TYPE_ARRAY or files.is_empty():
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "资源清单没有文件列表")
		return false

	var total_bytes := 0
	for item in files:
		if typeof(item) != TYPE_DICTIONARY or not _valid_relative_path(str(item.get("path", ""))):
			_remove_directory_if_exists(staging)
			pack_install_finished.emit(pack_id, false, "资源清单包含非法文件路径")
			return false
		var size := int(item.get("size_bytes", -1))
		var digest := str(item.get("sha256", ""))
		if size < 0 or digest.length() != 64 or not digest.is_valid_hex_number(false):
			_remove_directory_if_exists(staging)
			pack_install_finished.emit(pack_id, false, "资源清单包含无效的文件大小或 SHA-256")
			return false
		total_bytes += size

	var required_space := total_bytes + manifest_size_bytes + MIN_FREE_SPACE_MARGIN
	var free_space := _get_free_space_bytes()
	if free_space >= 0 and free_space < required_space:
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "手机空间不足，需要 %.2f GB 可用空间" % (float(required_space) / 1073741824.0))
		return false

	for item in files:
		var relative_path := str(item.get("path", ""))
		var destination := staging.path_join(relative_path)
		var parent_path := destination.get_base_dir()
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent_path)) != OK:
			_remove_directory_if_exists(staging)
			pack_install_finished.emit(pack_id, false, "无法创建资源目录：" + relative_path)
			return false
		var download_url := cdn_base_url + pack_id + "/" + relative_path.uri_encode()
		var downloaded: Dictionary = await _download_resumable(download_url, destination, int(item.get("size_bytes", 0)), str(item.get("sha256", "")), pack_id, relative_path)
		if not bool(downloaded.get("success", false)):
			_remove_directory_if_exists(staging)
			pack_install_finished.emit(pack_id, false, str(downloaded.get("message", "资源文件下载失败")))
			return false

	var validation := _validate_directory(staging, pack_id)
	if not bool(validation.get("valid", false)):
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, str(validation.get("message", "下载完成但资源包校验失败")))
		return false
	for dependency in parsed.get("dependencies", []):
		if not is_pack_installed(str(dependency)):
			_remove_directory_if_exists(staging)
			pack_install_finished.emit(pack_id, false, "缺少依赖资源包：" + str(dependency))
			return false

	_remove_directory_if_exists(backup)
	var final_path := PACK_ROOT.path_join(pack_id)
	var had_old := DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(final_path))
	if had_old and DirAccess.rename_absolute(ProjectSettings.globalize_path(final_path), ProjectSettings.globalize_path(backup)) != OK:
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "无法保护旧版本，已取消更新")
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(staging), ProjectSettings.globalize_path(final_path)) != OK:
		if had_old:
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup), ProjectSettings.globalize_path(final_path))
		_remove_directory_if_exists(staging)
		pack_install_finished.emit(pack_id, false, "安装切换失败，旧版本已回滚")
		return false
	_remove_directory_if_exists(backup)
	pack_install_finished.emit(pack_id, true, "资源包下载、校验和安装完成")
	EventBus.resource_pack_changed.emit(pack_id, "installed")
	return true

func _download_resumable(url: String, destination: String, expected_size: int, expected_sha256: String, pack_id: String, file_label: String) -> Dictionary:
	var partial_path := destination + ".part"
	var existing_size := 0
	if FileAccess.file_exists(partial_path):
		var existing := FileAccess.open(partial_path, FileAccess.READ)
		if existing != null:
			existing_size = int(existing.get_length())
			existing.close()
	if existing_size > expected_size:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(partial_path))
		existing_size = 0
	if not FileAccess.file_exists(partial_path):
		var create_file := FileAccess.open(partial_path, FileAccess.WRITE)
		if create_file == null:
			return {"success": false, "message": "无法创建下载文件：" + file_label}
		create_file.close()

	while existing_size < expected_size:
		var chunk_end := mini(existing_size + DOWNLOAD_CHUNK_BYTES - 1, expected_size - 1)
		var headers := PackedStringArray(["Range: bytes=%d-%d" % [existing_size, chunk_end], "Accept-Encoding: identity"])
		var response: Dictionary = await _http_get_bytes(url, headers)
		if not bool(response.get("success", false)):
			return {"success": false, "message": "下载中断（可再次启动继续下载）：" + file_label + "；" + str(response.get("message", ""))}
		var status := int(response.get("status", 0))
		var body: PackedByteArray = response.get("body", PackedByteArray())
		var expected_chunk := chunk_end - existing_size + 1
		if status != 206 or body.size() != expected_chunk:
			return {"success": false, "message": "CDN 未正确支持 HTTP Range 分段下载：" + file_label}
		var output := FileAccess.open(partial_path, FileAccess.READ_WRITE)
		if output == null:
			return {"success": false, "message": "无法写入下载文件：" + file_label}
		output.seek_end()
		output.store_buffer(body)
		output.close()
		existing_size += body.size()
		pack_download_progress.emit(pack_id, existing_size, expected_size, file_label)

	if FileAccess.get_sha256(partial_path).to_lower() != expected_sha256.to_lower():
		return {"success": false, "message": "SHA-256 校验失败：" + file_label}
	if FileAccess.file_exists(destination):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination))
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(partial_path), ProjectSettings.globalize_path(destination)) != OK:
		return {"success": false, "message": "下载完成但无法写入目标文件：" + file_label}
	return {"success": true, "message": "下载完成"}

func _http_get_bytes(url: String, headers: PackedStringArray = PackedStringArray()) -> Dictionary:
	var request_node := HTTPRequest.new()
	request_node.timeout = DOWNLOAD_TIMEOUT_SECONDS
	request_node.body_size_limit = DOWNLOAD_HTTP_BODY_LIMIT
	request_node.max_redirects = 5
	add_child(request_node)
	var request_error := request_node.request(url, headers, HTTPClient.METHOD_GET)
	if request_error != OK:
		request_node.queue_free()
		return {"success": false, "message": "无法发起 HTTPS 请求，错误码 %d" % request_error}
	var result: Array = await request_node.request_completed
	request_node.queue_free()
	var request_result := int(result[0])
	var response_code := int(result[1])
	var body: PackedByteArray = result[3]
	if request_result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return {"success": false, "status": response_code, "message": "HTTP 请求失败（结果 %d，状态 %d）" % [request_result, response_code]}
	return {"success": true, "status": response_code, "body": body}
