extends Node
## Headless scene-based smoke test so project AutoLoads are initialized normally.

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	assert(str(SettingsManager.get_value("system", "language", "zh_CN")) in ["zh_CN", "en_US"], "settings service")
	assert(str(LocalizationManager.text_for("ui.attack")) != "", "localization service")
	assert(AudioManager != null, "audio service")
	assert(SystemHealthManager != null, "system health service")
	assert(ApplicationLifecycleManager != null, "application lifecycle service")
	var original_fps := int(SettingsManager.get_value("graphics", "fps_limit", 60))
	assert(SettingsManager.set_value("graphics", "fps_limit", 999), "settings write")
	assert(int(SettingsManager.get_value("graphics", "fps_limit", 60)) == 120, "settings clamp")
	assert(SettingsManager.set_value("graphics", "fps_limit", original_fps), "settings restore")
	LocalizationManager.set_locale("en_US")
	assert(str(LocalizationManager.text_for("ui.attack")) == "Attack", "locale switch")
	LocalizationManager.set_locale("zh_CN")
	assert(not SceneFlowManager.change_scene("res://" + "scenes/not_a_real_scene.tscn"), "reject invalid scene path")
	assert(not ResourcePackManager.validate_source_directory("user://missing_pack", "galaxy_wars").get("valid", false), "reject missing pack source")
	var source_dir := "user://framework_pack_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_dir))
	var payload_path := source_dir.path_join("payload.txt")
	var payload := FileAccess.open(payload_path, FileAccess.WRITE)
	assert(payload != null, "create package payload")
	payload.store_string("offline package test")
	payload.close()
	var payload_reader := FileAccess.open(payload_path, FileAccess.READ)
	assert(payload_reader != null, "read package payload")
	var payload_size := int(payload_reader.get_length())
	payload_reader.close()
	var manifest := {
		"id": "galaxy_wars",
		"manifest_version": 1,
		"version": 1,
		"size_bytes": payload_size,
		"dependencies": [],
		"files": [{"path": "payload.txt", "size_bytes": payload_size, "sha256": FileAccess.get_sha256(payload_path)}]
	}
	var manifest_file := FileAccess.open(source_dir.path_join("pack.json"), FileAccess.WRITE)
	assert(manifest_file != null, "create package manifest")
	manifest_file.store_string(JSON.stringify(manifest))
	manifest_file.close()
	assert(bool(ResourcePackManager.preflight_install(source_dir, "galaxy_wars").get("allowed", false)), "resource package preflight")
	assert(ResourcePackManager.install_from_directory(source_dir, "galaxy_wars"), "resource package staged install")
	assert(bool(ResourcePackManager.validate_pack("galaxy_wars").get("valid", false)), "resource package installed validation")
	assert(ResourcePackManager.remove_pack("galaxy_wars"), "resource package safe removal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(payload_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_dir.path_join("pack.json")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_dir))

	assert(int(ResourcePackManager.get_storage_summary().get("installed_count", -1)) >= 0, "pack storage summary")
	SystemHealthManager.report_error("smoke_test", "诊断日志测试")
	assert(not SystemHealthManager.get_recent_errors().is_empty(), "diagnostic error record")
	assert(SystemHealthManager.clear_log(), "diagnostic log cleanup")
	assert(bool(SaveManager.save_document("ci_framework_smoke", {"passed": true, "value": 42})), "save document")
	var loaded: Dictionary = SaveManager.load_document("ci_framework_smoke")
	assert(bool(loaded.get("passed", false)) and int(loaded.get("value", 0)) == 42, "save/load roundtrip")
	SaveManager.delete_document("ci_framework_smoke")
	assert(bool(DialogueManager.start_dialogue("ci_smoke", [{"text": "第一句"}, {"text": "第二句"}])), "dialogue start")
	assert(str(DialogueManager.get_current_line().get("text", "")) == "第一句", "dialogue first line")
	assert(str(DialogueManager.advance().get("text", "")) == "第二句", "dialogue advance")
	DialogueManager.advance()
	assert(not DialogueManager.is_active, "dialogue completion")
	assert(not ResourcePackManager.get_pack_info("galaxy_wars").is_empty(), "offline pack catalog")
	assert(RPGState.create_new_slot(3), "create empty character slot")
	var slot_summary: Dictionary = RPGState.get_slot_summary(3)
	assert(bool(slot_summary.get("exists", false)) and bool(slot_summary.get("valid", false)), "slot summary")
	RPGState.profile["currency"] = 9876
	assert(RPGState.save_slot(3), "save created slot")
	assert(not RPGState.create_new_slot(3), "do not overwrite occupied slot")
	assert(RPGState.load_slot(3) and int(RPGState.profile.get("currency", 0)) == 9876, "occupied slot data preserved")
	assert(RPGState.backup_slot(3) and RPGState.has_backup_slot(3), "backup character slot")
	assert(RPGState.delete_slot(3) and not RPGState.has_slot(3), "delete slot after backup")
	assert(RPGState.restore_backup(3) and RPGState.has_slot(3), "restore character slot backup")
	RPGState.delete_slot(3)

	print("FRAMEWORK_SMOKE_TEST_PASS")
	get_tree().quit(0)
