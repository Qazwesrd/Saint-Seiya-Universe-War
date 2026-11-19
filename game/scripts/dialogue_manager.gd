extends Node
## 通用离线对话流程：支持逐句推进、结束事件与当前对话查询。
signal line_changed(dialogue_id: String, line_index: int, line: Dictionary)
signal dialogue_finished(dialogue_id: String)
var active_dialogue_id := ""
var active_lines: Array[Dictionary] = []
var current_index := -1
var is_active := false

func start_dialogue(dialogue_id: String, lines: Array[Dictionary]) -> bool:
	if dialogue_id.is_empty() or lines.is_empty():
		return false
	active_dialogue_id = dialogue_id
	active_lines = lines.duplicate(true)
	current_index = 0
	is_active = true
	EventBus.dialogue_started.emit(dialogue_id)
	line_changed.emit(active_dialogue_id, current_index, active_lines[current_index])
	return true

func advance() -> Dictionary:
	if not is_active:
		return {}
	current_index += 1
	if current_index >= active_lines.size():
		finish_dialogue()
		return {}
	var line: Dictionary = active_lines[current_index]
	line_changed.emit(active_dialogue_id, current_index, line)
	return line.duplicate(true)

func get_current_line() -> Dictionary:
	if not is_active or current_index < 0 or current_index >= active_lines.size():
		return {}
	return active_lines[current_index].duplicate(true)

func finish_dialogue() -> void:
	if not is_active:
		return
	var finished_id := active_dialogue_id
	active_dialogue_id = ""
	active_lines.clear()
	current_index = -1
	is_active = false
	dialogue_finished.emit(finished_id)
	EventBus.dialogue_ended.emit(finished_id)

func skip_dialogue() -> void:
	finish_dialogue()
