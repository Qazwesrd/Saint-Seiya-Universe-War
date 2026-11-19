extends Node
## Headless scene-based smoke test so project AutoLoads are initialized normally.

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	assert(str(SettingsManager.get_value("system", "language", "zh_CN")) in ["zh_CN", "en_US"], "settings service")
	assert(str(LocalizationManager.text_for("ui.attack")) != "", "localization service")
	assert(AudioManager != null, "audio service")
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
	assert(RPGState.backup_slot(3) and RPGState.has_backup_slot(3), "backup character slot")
	assert(RPGState.delete_slot(3) and not RPGState.has_slot(3), "delete slot after backup")
	assert(RPGState.restore_backup(3) and RPGState.has_slot(3), "restore character slot backup")
	RPGState.delete_slot(3)

	print("FRAMEWORK_SMOKE_TEST_PASS")
	get_tree().quit(0)
