extends SceneTree
## Verify a chapter PCK by mounting it and reading a known resource.
## Usage:
## godot --headless --path game --script res://tools/verify_chapter_pck.gd -- --pck /absolute/path/chapter.pck

const PROBE_RESOURCE := "res://" + "assets/environments/galaxy_wars/" + "ci_pck_probe.json"
const EXPECTED_CONTENT := "{\"probe\":\"chapter pck builder verified\"}"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var pck_path := ""
	var index := 0
	while index < arguments.size():
		if str(arguments[index]) == "--pck" and index + 1 < arguments.size():
			pck_path = str(arguments[index + 1])
			index += 2
		else:
			index += 1
	if pck_path.is_empty() or not FileAccess.file_exists(pck_path):
		push_error("A readable --pck file is required.")
		quit(2)
		return
	if not ProjectSettings.load_resource_pack(pck_path, true):
		push_error("Godot failed to mount chapter PCK: " + pck_path)
		quit(3)
		return
	if not FileAccess.file_exists(PROBE_RESOURCE):
		push_error("Mounted chapter PCK does not expose the expected probe resource.")
		quit(4)
		return
	var content := FileAccess.get_file_as_string(PROBE_RESOURCE)
	if content != EXPECTED_CONTENT:
		push_error("Mounted chapter PCK probe content does not match.")
		quit(5)
		return
	print("CHAPTER_PCK_MOUNT_READ_PASS path=%s" % PROBE_RESOURCE)
	quit(0)
