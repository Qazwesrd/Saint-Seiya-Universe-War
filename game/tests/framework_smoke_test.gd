extends SceneTree
## Headless smoke test: access AutoLoads through SceneTree root so --script mode can compile.

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var settings: Node = root.get_node("SettingsManager")
	var localization: Node = root.get_node("LocalizationManager")
	var audio: Node = root.get_node("AudioManager")
	var saves: Node = root.get_node("SaveManager")
	var dialogue: Node = root.get_node("DialogueManager")
	var packs: Node = root.get_node("ResourcePackManager")

	assert(str(settings.get_value("system", "language", "zh_CN")) in ["zh_CN", "en_US"], "settings service")
	assert(str(localization.text_for("ui.attack")) != "", "localization service")
	assert(audio != null, "audio service")
	assert(bool(saves.save_document("ci_framework_smoke", {"passed": true, "value": 42})), "save document")
	var loaded: Dictionary = saves.load_document("ci_framework_smoke")
	assert(bool(loaded.get("passed", false)) and int(loaded.get("value", 0)) == 42, "save/load roundtrip")
	saves.delete_document("ci_framework_smoke")
	assert(bool(dialogue.start_dialogue("ci_smoke", [{"text": "第一句"}, {"text": "第二句"}])), "dialogue start")
	assert(str(dialogue.get_current_line().get("text", "")) == "第一句", "dialogue first line")
	assert(str(dialogue.advance().get("text", "")) == "第二句", "dialogue advance")
	dialogue.advance()
	assert(not bool(dialogue.is_active), "dialogue completion")
	assert(not packs.get_pack_info("galaxy_wars").is_empty(), "offline pack catalog")
	print("FRAMEWORK_SMOKE_TEST_PASS")
	quit(0)
