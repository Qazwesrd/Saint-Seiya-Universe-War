extends Node
## 场景切换统一入口，避免 UI/NPC 直接耦合 SceneTree。
signal scene_change_started(scene_path: String)
signal scene_change_finished(scene_path: String)
var is_changing_scene := false

func change_scene(scene_path: String) -> bool:
	if is_changing_scene or scene_path.is_empty() or not scene_path.begins_with("res://"):
		return false
	if not ResourceLoader.exists(scene_path):
		push_warning("目标场景不存在：" + scene_path)
		return false
	is_changing_scene = true
	scene_change_started.emit(scene_path)
	call_deferred("_perform_change", scene_path)
	return true

func _perform_change(scene_path: String) -> void:
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("场景切换失败：" + scene_path)
		is_changing_scene = false
		return
	is_changing_scene = false
	scene_change_finished.emit(scene_path)
