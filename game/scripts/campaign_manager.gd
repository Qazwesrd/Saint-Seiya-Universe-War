extends Node
signal campaign_changed

const SAVE_PATH := "user://campaign_progress_legacy.json"
const SAVE_VERSION := 1

var progress: Dictionary = {}

func _ready() -> void:
    RPGState.slot_loaded.connect(_on_profile_slot_loaded)
    load_progress()

func _on_profile_slot_loaded(_slot: int) -> void:
    load_progress()

func _default_progress() -> Dictionary:
    var unlocked: Array[String] = [CampaignDatabase.CHAPTERS[0]["id"]]
    return {
        "version": SAVE_VERSION,
        "unlocked_chapters": unlocked,
        "completed_missions": [],
        "active_mission": CampaignDatabase.get_first_mission_id(),
        "objective_counts": {},
        "claimed_rewards": []
    }

func load_progress() -> void:
    progress = _default_progress()
    var parsed: Variant = RPGState.profile.get("campaign_progress", {})
    var migrated_legacy := false
    if (typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty()) and FileAccess.file_exists(SAVE_PATH):
        var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if file != null:
            parsed = JSON.parse_string(file.get_as_text())
            file.close()
            migrated_legacy = typeof(parsed) == TYPE_DICTIONARY
    if typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("version", 0)) == SAVE_VERSION:
        var loaded: Dictionary = parsed
        var unlocked: Array = loaded.get("unlocked_chapters", [])
        var completed: Array = loaded.get("completed_missions", [])
        var active := str(loaded.get("active_mission", CampaignDatabase.get_first_mission_id()))
        if CampaignDatabase.get_mission(active).is_empty():
            active = CampaignDatabase.get_first_mission_id()
        progress = {
            "version": SAVE_VERSION,
            "unlocked_chapters": unlocked.duplicate(),
            "completed_missions": completed.duplicate(),
            "active_mission": active,
            "objective_counts": loaded.get("objective_counts", {}).duplicate(true),
            "claimed_rewards": loaded.get("claimed_rewards", []).duplicate()
        }
        _normalize_progress()
    if migrated_legacy:
        RPGState.profile["campaign_progress"] = progress.duplicate(true)
        RPGState.save_slot(RPGState.active_slot)
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    campaign_changed.emit()

func _normalize_progress() -> void:
    var valid_chapters: Array[String] = []
    for chapter in CampaignDatabase.CHAPTERS:
        if str(chapter["id"]) in progress["unlocked_chapters"]:
            valid_chapters.append(str(chapter["id"]))
    if valid_chapters.is_empty():
        valid_chapters.append(str(CampaignDatabase.CHAPTERS[0]["id"]))
    progress["unlocked_chapters"] = valid_chapters
    var valid_completed: Array[String] = []
    for mission_id in progress["completed_missions"]:
        if not CampaignDatabase.get_mission(str(mission_id)).is_empty():
            valid_completed.append(str(mission_id))
    progress["completed_missions"] = valid_completed
    var next_in_order := _first_incomplete_mission_id()
    if not next_in_order.is_empty():
        progress["active_mission"] = next_in_order

func _first_incomplete_mission_id() -> String:
    for chapter in CampaignDatabase.CHAPTERS:
        for mission in chapter["missions"]:
            var mission_id := str(mission["id"])
            if not mission_id in progress["completed_missions"]:
                return mission_id
    return CampaignDatabase.get_first_mission_id()

func get_active_mission() -> Dictionary:
    return CampaignDatabase.get_mission(str(progress.get("active_mission", "")))

func get_active_chapter() -> Dictionary:
    var mission := get_active_mission()
    if mission.is_empty():
        return {}
    for chapter in CampaignDatabase.CHAPTERS:
        for entry in chapter["missions"]:
            if str(entry["id"]) == str(mission["id"]):
                return chapter.duplicate(true)
    return {}

func get_mission_progress(mission_id: String) -> Dictionary:
    var mission := CampaignDatabase.get_mission(mission_id)
    if mission.is_empty():
        return {}
    var counts: Dictionary = progress.get("objective_counts", {}).get(mission_id, {})
    var objectives: Array = []
    var all_done := true
    for objective in mission.get("objectives", []):
        var objective_id := str(objective["id"])
        var target := maxi(1, int(objective.get("target", 1)))
        var current := clampi(int(counts.get(objective_id, 0)), 0, target)
        objectives.append({"id": objective_id, "text": objective["text"], "current": current, "target": target, "completed": current >= target})
        if current < target:
            all_done = false
    return {"mission": mission, "objectives": objectives, "completed": all_done}

func accept_mission(mission_id: String) -> bool:
    var mission := CampaignDatabase.get_mission(mission_id)
    if mission.is_empty() or mission_id in progress["completed_missions"]:
        return false
    if mission_id != str(progress.get("active_mission", "")):
        return false
    var chapter := _chapter_for_mission(mission_id)
    if chapter.is_empty() or not str(chapter["id"]) in progress["unlocked_chapters"]:
        return false
    var previous_progress: Dictionary = progress.duplicate(true)
    progress["active_mission"] = mission_id
    var counts: Dictionary = progress["objective_counts"]
    if not counts.has(mission_id):
        counts[mission_id] = {}
    progress["objective_counts"] = counts
    if not _save():
        progress = previous_progress
        return false
    return true

func add_objective_progress(objective_id: String, amount: int = 1) -> bool:
    if amount <= 0:
        return false
    var mission := get_active_mission()
    if mission.is_empty() or str(mission["id"]) in progress["completed_missions"]:
        return false
    var valid := false
    for objective in mission.get("objectives", []):
        if str(objective["id"]) == objective_id:
            valid = true
            break
    if not valid:
        return false
    var previous_progress: Dictionary = progress.duplicate(true)
    var counts: Dictionary = progress["objective_counts"]
    var mission_counts: Dictionary = counts.get(str(mission["id"]), {})
    var target := 1
    for objective in mission["objectives"]:
        if str(objective["id"]) == objective_id:
            target = maxi(1, int(objective.get("target", 1)))
            break
    mission_counts[objective_id] = mini(target, int(mission_counts.get(objective_id, 0)) + amount)
    counts[str(mission["id"])] = mission_counts
    progress["objective_counts"] = counts
    if not _save():
        progress = previous_progress
        return false
    return true

func can_complete_active_mission() -> bool:
    var mission := get_active_mission()
    if mission.is_empty():
        return false
    return bool(get_mission_progress(str(mission["id"])).get("completed", false))

func complete_active_mission() -> Dictionary:
    var mission := get_active_mission()
    if mission.is_empty() or not can_complete_active_mission():
        return {"success": false, "reason": "目标尚未全部完成"}
    var mission_id := str(mission["id"])
    if mission_id in progress["completed_missions"]:
        return {"success": false, "reason": "任务已经完成"}

    # Commit campaign progress and rewards in one character-slot write.
    # This prevents a failed campaign save from allowing the same reward to be claimed twice.
    var previous_profile: Dictionary = RPGState.profile.duplicate(true)
    var previous_progress: Dictionary = progress.duplicate(true)
    progress["completed_missions"].append(mission_id)
    var reward: Dictionary = mission.get("rewards", {})
    if not mission_id in progress["claimed_rewards"]:
        progress["claimed_rewards"].append(mission_id)
        RPGState.profile["exp"] = int(RPGState.profile.get("exp", 0)) + int(reward.get("exp", 0))
        RPGState.profile["currency"] = maxi(0, int(RPGState.profile.get("currency", 0)) + int(reward.get("coins", 0)))
        while int(RPGState.profile.get("level", 1)) < RPGState.MAX_LEVEL and int(RPGState.profile["exp"]) >= RPGState.exp_to_next_level():
            RPGState.profile["exp"] = int(RPGState.profile["exp"]) - RPGState.exp_to_next_level()
            RPGState.profile["level"] = int(RPGState.profile["level"]) + 1
            RPGState.profile["skill_points"] = int(RPGState.profile.get("skill_points", 0)) + 1

    _unlock_next_chapter_if_ready(mission_id)
    var next_id := _next_mission_id(mission_id)
    progress["active_mission"] = next_id
    RPGState.profile["campaign_progress"] = progress.duplicate(true)
    if not RPGState.save_slot(RPGState.active_slot):
        RPGState.profile = previous_profile
        progress = previous_progress
        SystemHealthManager.report_error("save", "剧情任务奖励与进度提交失败", "mission=%s slot=%d" % [mission_id, RPGState.active_slot])
        return {"success": false, "reason": "存档写入失败，任务奖励未发放，请重试"}
    RPGState._emit_change()
    campaign_changed.emit()
    return {"success": true, "mission": mission, "rewards": reward, "next_mission": CampaignDatabase.get_mission(next_id)}
func _unlock_next_chapter_if_ready(completed_id: String) -> void:
    var chapter_index := -1
    var mission_index := -1
    for i in range(CampaignDatabase.CHAPTERS.size()):
        var chapter: Dictionary = CampaignDatabase.CHAPTERS[i]
        for j in range(chapter["missions"].size()):
            if str(chapter["missions"][j]["id"]) == completed_id:
                chapter_index = i
                mission_index = j
                break
        if chapter_index >= 0:
            break
    if chapter_index < 0:
        return
    var chapter: Dictionary = CampaignDatabase.CHAPTERS[chapter_index]
    if mission_index == chapter["missions"].size() - 1 and chapter_index + 1 < CampaignDatabase.CHAPTERS.size():
        var next_chapter_id := str(CampaignDatabase.CHAPTERS[chapter_index + 1]["id"])
        if not next_chapter_id in progress["unlocked_chapters"]:
            progress["unlocked_chapters"].append(next_chapter_id)

func _next_mission_id(completed_id: String) -> String:
    var found := false
    for chapter in CampaignDatabase.CHAPTERS:
        for mission in chapter["missions"]:
            var mission_id := str(mission["id"])
            if found:
                return mission_id
            if mission_id == completed_id:
                found = true
    return completed_id

func _chapter_for_mission(mission_id: String) -> Dictionary:
    for chapter in CampaignDatabase.CHAPTERS:
        for mission in chapter["missions"]:
            if str(mission["id"]) == mission_id:
                return chapter
    return {}

func get_chapter_overview() -> Array:
    var result: Array = []
    for chapter in CampaignDatabase.CHAPTERS:
        var unlocked: bool = str(chapter["id"]) in progress["unlocked_chapters"]
        var completed_count := 0
        for mission in chapter["missions"]:
            if str(mission["id"]) in progress["completed_missions"]:
                completed_count += 1
        result.append({
            "id": chapter["id"], "name": chapter["name"], "order": chapter["order"],
            "unlocked": unlocked, "completed": completed_count == chapter["missions"].size(),
            "completed_missions": completed_count, "total_missions": chapter["missions"].size()
        })
    return result

func _save() -> bool:
    var previous_campaign: Dictionary = RPGState.profile.get("campaign_progress", {}).duplicate(true)
    RPGState.profile["campaign_progress"] = progress.duplicate(true)
    if not RPGState.save_slot(RPGState.active_slot):
        RPGState.profile["campaign_progress"] = previous_campaign
        SystemHealthManager.report_error("save", "剧情进度保存失败", "slot=%d" % RPGState.active_slot)
        return false
    RPGState.state_changed.emit()
    campaign_changed.emit()
    return true
