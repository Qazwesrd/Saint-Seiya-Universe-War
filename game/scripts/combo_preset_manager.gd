extends Node
## 玩家自定义连招配置。配置按角色职业保存到当前离线存档。

signal presets_changed(class_id: String)

const MAX_PRESETS := 5
const MAX_STEPS := 8
const MAX_WINDOW := 2.5
const MIN_WINDOW := 0.15
const VALID_MODES := ["按顺序点击", "连续点击", "自动衔接"]
const BUILTIN_STEPS := ["basic_attack_1", "basic_attack_2", "basic_attack_3", "dodge", "guard"]

func get_presets(class_id: String) -> Array:
    var root: Dictionary = RPGState.profile.get("combo_presets", {})
    return root.get(class_id, []).duplicate(true)

func get_active_preset(class_id: String) -> Dictionary:
    var presets := get_presets(class_id)
    var root: Dictionary = RPGState.profile.get("combo_active", {})
    var active_id := str(root.get(class_id, ""))
    for preset in presets:
        if str(preset.get("id", "")) == active_id:
            return preset.duplicate(true)
    return presets[0].duplicate(true) if not presets.is_empty() else {}

func save_preset(class_id: String, preset_id: String, preset_name: String, steps: Array, trigger_mode: String = "按顺序点击", input_window: float = 0.65) -> bool:
    if not SkillSystem.has_class(class_id) or preset_id.strip_edges().is_empty() or preset_name.strip_edges().is_empty():
        return false
    if steps.is_empty() or steps.size() > MAX_STEPS or not VALID_MODES.has(trigger_mode):
        return false
    if input_window < MIN_WINDOW or input_window > MAX_WINDOW:
        return false
    var normalized: Array[String] = []
    for raw_step in steps:
        var step := str(raw_step)
        if not _is_step_available(class_id, step) or normalized.has(step):
            return false
        normalized.append(step)
    var previous: Dictionary = RPGState.profile.duplicate(true)
    var all_presets: Dictionary = RPGState.profile.get("combo_presets", {}).duplicate(true)
    var class_presets: Array = all_presets.get(class_id, []).duplicate(true)
    var found := false
    var entry := {
        "id": preset_id,
        "name": preset_name.strip_edges().substr(0, 24),
        "steps": normalized,
        "trigger_mode": trigger_mode,
        "input_window": input_window,
        "updated_at": Time.get_datetime_string_from_system()
    }
    for i in range(class_presets.size()):
        if str(class_presets[i].get("id", "")) == preset_id:
            class_presets[i] = entry
            found = true
            break
    if not found:
        if class_presets.size() >= MAX_PRESETS:
            return false
        class_presets.append(entry)
    all_presets[class_id] = class_presets
    RPGState.profile["combo_presets"] = all_presets
    var active: Dictionary = RPGState.profile.get("combo_active", {}).duplicate(true)
    if str(active.get(class_id, "")).is_empty():
        active[class_id] = preset_id
    RPGState.profile["combo_active"] = active
    if not _commit(previous):
        return false
    presets_changed.emit(class_id)
    return true

func set_active_preset(class_id: String, preset_id: String) -> bool:
    if not SkillSystem.has_class(class_id):
        return false
    var exists := false
    for preset in get_presets(class_id):
        if str(preset.get("id", "")) == preset_id:
            exists = true
            break
    if not exists:
        return false
    var previous: Dictionary = RPGState.profile.duplicate(true)
    var active: Dictionary = RPGState.profile.get("combo_active", {}).duplicate(true)
    active[class_id] = preset_id
    RPGState.profile["combo_active"] = active
    if not _commit(previous):
        return false
    presets_changed.emit(class_id)
    return true

func delete_preset(class_id: String, preset_id: String) -> bool:
    if not SkillSystem.has_class(class_id):
        return false
    var previous: Dictionary = RPGState.profile.duplicate(true)
    var all_presets: Dictionary = RPGState.profile.get("combo_presets", {}).duplicate(true)
    var class_presets: Array = all_presets.get(class_id, []).duplicate(true)
    var removed := false
    for i in range(class_presets.size() - 1, -1, -1):
        if str(class_presets[i].get("id", "")) == preset_id:
            class_presets.remove_at(i)
            removed = true
    if not removed:
        return false
    all_presets[class_id] = class_presets
    RPGState.profile["combo_presets"] = all_presets
    var active: Dictionary = RPGState.profile.get("combo_active", {}).duplicate(true)
    if str(active.get(class_id, "")) == preset_id:
        active[class_id] = str(class_presets[0].get("id", "")) if not class_presets.is_empty() else ""
    RPGState.profile["combo_active"] = active
    if not _commit(previous):
        return false
    presets_changed.emit(class_id)
    return true

func _is_step_available(class_id: String, step: String) -> bool:
    if not SkillSystem.has_class(class_id):
        return false
    if BUILTIN_STEPS.has(step):
        return true
    return SkillSystem.is_ability_learned(class_id, step)

func _commit(previous: Dictionary) -> bool:
    if RPGState.save_slot(RPGState.active_slot):
        RPGState.state_changed.emit()
        return true
    RPGState.profile = previous
    return false
