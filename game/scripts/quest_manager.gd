extends Node
signal quest_changed

const QUEST_ID := "galaxy_arena_trial"
const GUIDE_NAME := "圣域训练引导员"

var status := "not_started"
var defeated_normal := 0
var boss_defeated := false

func _ready() -> void:
    RPGState.slot_loaded.connect(_on_profile_slot_loaded)
    load_progress()

func _on_profile_slot_loaded(_slot: int) -> void:
    load_progress()

func interact_with_guide() -> Dictionary:
    if status == "not_started":
        status = "active"
        _save_progress()
        quest_changed.emit()
        return {"speaker": GUIDE_NAME, "text": "年轻的圣斗士，欢迎来到银河竞技场。先击败两名训练对手，再战胜训练 Boss。完成后回来向我报告。", "action": "accept"}
    if status == "active":
        if defeated_normal < 2:
            return {"speaker": GUIDE_NAME, "text": "训练还没有结束。你还需要击败 %d 名普通训练对手。" % (2 - defeated_normal), "action": "progress"}
        if not boss_defeated:
            return {"speaker": GUIDE_NAME, "text": "普通训练已经完成。最后的训练 Boss 在竞技场中央，注意观察它的攻击节奏。", "action": "progress"}
        status = "ready_to_return"
        _save_progress()
        quest_changed.emit()
    if status == "ready_to_return":
        status = "completed"
        _save_progress()
        RPGState.add_exp(250)
        RPGState.add_currency(300)
        RPGState.add_item("bronze_helmet", 1)
        quest_changed.emit()
        return {"speaker": GUIDE_NAME, "text": "做得很好！你已经完成银河竞技场试炼。奖励已发放：250 经验、300 星币和青铜头盔。下一段圣域任务入口将在后续章节开放。", "action": "complete"}
    if status == "completed":
        return {"speaker": GUIDE_NAME, "text": "试炼记录已经保存。下一段圣域剧情将在后续章节开放。", "action": "completed"}
    return {"speaker": GUIDE_NAME, "text": "欢迎来到银河竞技场。", "action": "none"}

func on_enemy_defeated(is_boss: bool) -> void:
    if status != "active":
        return
    if is_boss:
        boss_defeated = true
    else:
        defeated_normal = mini(2, defeated_normal + 1)
    if defeated_normal >= 2 and boss_defeated:
        status = "ready_to_return"
    _save_progress()
    quest_changed.emit()

func get_tracker_text() -> String:
    if status == "not_started":
        return "主线：银河竞技场试炼\n目标：找到训练引导员并交谈"
    if status == "active":
        if defeated_normal < 2:
            return "主线：银河竞技场试炼\n目标：击败训练对手 %d/2" % defeated_normal
        if not boss_defeated:
            return "主线：银河竞技场试炼\n目标：击败训练 Boss"
        return "主线：银河竞技场试炼\n目标：返回训练引导员"
    if status == "ready_to_return":
        return "主线：银河竞技场试炼\n目标：返回训练引导员领取奖励"
    return "主线：银河竞技场试炼\n状态：已完成 · 下一段圣域任务：后续章节开放"

func get_map_objective() -> String:
    if status == "not_started" or status == "ready_to_return":
        return "返回引导员"
    if status == "active" and defeated_normal < 2:
        return "训练对手"
    if status == "active" and not boss_defeated:
        return "训练 Boss"
    return "试炼完成"

func _save_path() -> String:
    return "user://quest_progress_legacy.json"

func _save_progress() -> void:
    var data := {
        "version": 1,
        "quest_id": QUEST_ID,
        "status": status,
        "defeated_normal": defeated_normal,
        "boss_defeated": boss_defeated
    }
    RPGState.profile["quest_progress"] = data.duplicate(true)
    if not RPGState.save_slot(RPGState.active_slot):
        SystemHealthManager.report_error("save", "任务进度保存失败", "slot=%d" % RPGState.active_slot)
    quest_changed.emit()

func load_progress() -> void:
    var parsed: Variant = RPGState.profile.get("quest_progress", {})
    var migrated_legacy := false
    if (typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty()) and FileAccess.file_exists(_save_path()):
        var file := FileAccess.open(_save_path(), FileAccess.READ)
        if file != null:
            parsed = JSON.parse_string(file.get_as_text())
            file.close()
            migrated_legacy = typeof(parsed) == TYPE_DICTIONARY
    status = "not_started"
    defeated_normal = 0
    boss_defeated = false
    if typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("version", 0)) == 1 and str(parsed.get("quest_id", "")) == QUEST_ID:
        var loaded_status := str(parsed.get("status", "not_started"))
        if loaded_status in ["not_started", "active", "ready_to_return", "completed"]:
            status = loaded_status
            defeated_normal = clampi(int(parsed.get("defeated_normal", 0)), 0, 2)
            boss_defeated = bool(parsed.get("boss_defeated", false))
            if status == "active" and defeated_normal >= 2 and boss_defeated:
                status = "ready_to_return"
    if migrated_legacy:
        RPGState.profile["quest_progress"] = parsed.duplicate(true)
        RPGState.save_slot(RPGState.active_slot)
        DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path()))
    quest_changed.emit()

func reset_progress() -> void:
    status = "not_started"
    defeated_normal = 0
    boss_defeated = false
    _save_progress()
    quest_changed.emit()
