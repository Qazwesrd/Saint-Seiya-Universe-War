extends Node
## 单场战斗统计与事件分发。仅统计本地实时战斗，不连接网络。
signal encounter_started(encounter_id: String)
signal encounter_finished(summary: Dictionary)
signal statistics_changed(summary: Dictionary)

var encounter_id := ""
var active := false
var started_at := 0
var stats: Dictionary = {}

func _ready() -> void:
	_reset_stats()

func _reset_stats() -> void:
	stats = {
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"healing_received": 0.0,
		"enemies_defeated": 0,
		"bosses_defeated": 0,
		"skills_cast": 0,
		"combos_used": 0,
		"critical_hits": 0,
		"duration_seconds": 0
	}

func begin_encounter(id: String) -> void:
	if active:
		finish_encounter()
	encounter_id = id.strip_edges()
	if encounter_id.is_empty():
		encounter_id = "free_battle"
	_reset_stats()
	started_at = int(Time.get_unix_time_from_system())
	active = true
	encounter_started.emit(encounter_id)

func record_damage_dealt(amount: float, critical: bool = false) -> void:
	if not active or amount <= 0.0:
		return
	stats["damage_dealt"] = float(stats["damage_dealt"]) + amount
	if critical:
		stats["critical_hits"] = int(stats["critical_hits"]) + 1
	_emit_update()

func record_damage_taken(amount: float) -> void:
	if not active or amount <= 0.0:
		return
	stats["damage_taken"] = float(stats["damage_taken"]) + amount
	_emit_update()

func record_healing(amount: float) -> void:
	if not active or amount <= 0.0:
		return
	stats["healing_received"] = float(stats["healing_received"]) + amount
	_emit_update()

func record_skill_cast(is_combo: bool = false) -> void:
	if not active:
		return
	stats["skills_cast"] = int(stats["skills_cast"]) + 1
	if is_combo:
		stats["combos_used"] = int(stats["combos_used"]) + 1
	_emit_update()

func record_enemy_defeated(is_boss: bool) -> void:
	if not active:
		return
	stats["enemies_defeated"] = int(stats["enemies_defeated"]) + 1
	if is_boss:
		stats["bosses_defeated"] = int(stats["bosses_defeated"]) + 1
	_emit_update()

func finish_encounter() -> Dictionary:
	if not active:
		return get_summary()
	stats["duration_seconds"] = maxi(0, int(Time.get_unix_time_from_system()) - started_at)
	active = false
	var result := get_summary()
	encounter_finished.emit(result)
	EventBus.combat_event.emit("encounter_finished", result)
	return result

func get_summary() -> Dictionary:
	var result := stats.duplicate(true)
	result["encounter_id"] = encounter_id
	result["active"] = active
	result["grade"] = _calculate_grade(result)
	if active:
		result["duration_seconds"] = maxi(0, int(Time.get_unix_time_from_system()) - started_at)
	return result

func _emit_update() -> void:
	var result := get_summary()
	statistics_changed.emit(result)
	EventBus.combat_event.emit("statistics_updated", result)


func _calculate_grade(summary: Dictionary) -> String:
    var bosses := int(summary.get("bosses_defeated", 0))
    var damage_taken := float(summary.get("damage_taken", 0.0))
    var duration := int(summary.get("duration_seconds", 0))
    if bosses <= 0:
        return "未完成"
    if damage_taken <= 60.0 and duration <= 120:
        return "S"
    if damage_taken <= 140.0 and duration <= 240:
        return "A"
    if damage_taken <= 260.0:
        return "B"
    return "C"
