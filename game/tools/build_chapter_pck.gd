extends SceneTree
## Build one chapter's installable PCK from authored environment assets.
## Usage:
## godot --headless --path game --script res://tools/build_chapter_pck.gd -- --chapter galaxy_wars --output /absolute/path/galaxy_wars.pck

const CHAPTER_IDS := ["galaxy_wars", "sanctuary_twelve_houses", "asgard", "poseidon", "hades", "heaven", "original_final"]
const SOURCE_EXTENSIONS := ["tscn", "tres", "res", "glb", "gltf", "png", "webp", "jpg", "jpeg", "ogg", "wav", "mp3", "json", "gdshader", "shader", "material", "ttf", "otf"]
const IGNORED_DIRS := [".godot", ".git", "__pycache__"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_arguments(OS.get_cmdline_user_args())
	var chapter_id := str(options.get("chapter", ""))
	var output_path := str(options.get("output", ""))
	if not CHAPTER_IDS.has(chapter_id):
		push_error("Missing or unsupported --chapter. Allowed: " + ", ".join(CHAPTER_IDS))
		quit(2)
		return
	if output_path.is_empty() or not output_path.to_lower().ends_with(".pck"):
		push_error("A --output path ending in .pck is required.")
		quit(2)
		return
	var source_root := "res://assets/environments/" + chapter_id
	var source_absolute := ProjectSettings.globalize_path(source_root)
	if not DirAccess.dir_exists_absolute(source_absolute):
		push_error("Chapter asset directory does not exist: " + source_root)
		quit(3)
		return

	print("PCK_DIAG collect: start chapter=%s root=%s" % [chapter_id, source_root])
	var files: Array[String] = []
	_collect_files(source_absolute, files)
	files.sort()
	print("PCK_DIAG collect: complete discovered_files=%d" % files.size())
	var packer := PCKPacker.new()
	var start_error := packer.pck_start(output_path)
	if start_error != OK:
		push_error("Cannot create PCK: error %d" % start_error)
		quit(4)
		return
	var added: Dictionary = {}
	var authored_count := 0
	for absolute_path in files:
		var relative := absolute_path.trim_prefix(source_absolute).trim_prefix("/")
		var extension := absolute_path.get_extension().to_lower()
		if not SOURCE_EXTENSIONS.has(extension):
			continue
		var target_path := source_root.path_join(relative)
		print("PCK_DIAG add: %d/%d %s" % [authored_count + 1, files.size(), target_path])
		if not _add_file(packer, target_path, absolute_path, added):
			quit(5)
			return
		authored_count += 1
		var import_sidecar := absolute_path + ".import"
		if FileAccess.file_exists(import_sidecar):
			if not _add_file(packer, target_path + ".import", import_sidecar, added):
				quit(5)
				return
			var import_config := ConfigFile.new()
			if import_config.load(import_sidecar) != OK:
				push_error("Cannot parse import metadata: " + import_sidecar)
				quit(5)
				return
			var imported_path := str(import_config.get_value("remap", "path", ""))
			if imported_path.is_empty() or not imported_path.begins_with("res://"):
				push_error("Import metadata has no valid remap.path: " + import_sidecar)
				quit(5)
				return
			var imported_absolute := ProjectSettings.globalize_path(imported_path)
			if not FileAccess.file_exists(imported_absolute):
				push_error("Imported cache is missing. Run Godot editor import first: " + imported_path)
				quit(5)
				return
			if not _add_file(packer, imported_path, imported_absolute, added):
				quit(5)
				return
	if authored_count == 0:
		push_error("No runtime assets found. README files and source-only art files are not chapter content.")
		quit(6)
		return
	print("PCK_DIAG flush: start authored_files=%d packed_entries=%d" % [authored_count, added.size()])
	var flush_error := packer.flush(true)
	print("PCK_DIAG flush: complete error=%d" % flush_error)
	if flush_error != OK:
		push_error("Cannot finalize chapter PCK: error %d" % flush_error)
		quit(7)
		return
	var pck_file := FileAccess.open(output_path, FileAccess.READ)
	if pck_file == null or pck_file.get_length() <= 32:
		push_error("PCK output is missing or unexpectedly small.")
		quit(8)
		return
	var magic := pck_file.get_buffer(4)
	pck_file.close()
	if magic != PackedByteArray([0x47, 0x44, 0x50, 0x43]):
		push_error("PCK header magic is invalid.")
		quit(8)
		return
	print("CHAPTER_PCK_BUILD_PASS chapter=%s files=%d output=%s" % [chapter_id, authored_count, output_path])
	quit(0)

func _parse_arguments(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	var index := 0
	while index < arguments.size():
		var key := str(arguments[index])
		if key.begins_with("--") and index + 1 < arguments.size():
			result[key.trim_prefix("--")] = str(arguments[index + 1])
			index += 2
		else:
			index += 1
	return result

func _collect_files(directory_path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Cannot open chapter asset directory: " + directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry == "." or entry == ".." or IGNORED_DIRS.has(entry):
			entry = directory.get_next()
			continue
		var child := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_files(child, output)
		elif not entry.ends_with(".import") and not entry.ends_with(".uid"):
			output.append(child)
		entry = directory.get_next()
	directory.list_dir_end()

func _add_file(packer: PCKPacker, target_path: String, source_path: String, added: Dictionary) -> bool:
	if added.has(target_path):
		return true
	var error := packer.add_file(target_path, source_path)
	if error != OK:
		push_error("PCK add_file failed for %s (error %d)" % [target_path, error])
		return false
	added[target_path] = true
	return true
