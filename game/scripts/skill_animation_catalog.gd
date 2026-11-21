extends RefCounted
class_name SkillAnimationCatalog
## Runtime animation timing and procedural pose metadata for every class ability.
## Authored skeletal clips can replace these profiles without changing combat data.

const CLASS_STYLE := {
    "pegasus": "拳击", "dragon": "盾拳", "cygnus": "冰拳", "andromeda": "锁链",
    "phoenix": "火焰拳", "sea_dragon": "次元掌", "tenmou": "重装拳", "lyra": "乐器",
    "sea_swallow": "疾风", "tenkishi": "空战",
    "apollo": "日耀", "athena": "神圣", "hades": "暗影", "poseidon": "海潮",
    "zeus": "雷霆", "artemis": "月弓", "hypnos": "梦境", "thanatos": "死亡",
    "odin": "寒霜", "ares": "战斧", "eris": "混沌", "abel": "太阳",
    "lucifer": "堕天", "saturn": "时空", "pallas": "神圣", "chronos": "时空",
    "hera": "神圣", "demeter": "自然", "hestia": "圣焰", "hermes": "迅捷",
    "hephaestus": "锻造", "aphrodite": "玫瑰"
}

static func get_profile(class_id: String, ability: Dictionary) -> Dictionary:
    if not SkillSystem.has_class(class_id) or not CLASS_STYLE.has(class_id) or ability.is_empty() or str(ability.get("id", "")).is_empty():
        return {}
    var ability_type := str(ability.get("type", "攻击"))
    var ability_name := str(ability.get("name", "技能"))
    var effect: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var action := str(effect.get("action", "strike"))
    var motion := _resolve_motion(class_id, ability_type, action, ability_name)
    var style := str(CLASS_STYLE.get(class_id, "小宇宙"))
    var finisher := ("奥义" in ability_type or "终结" in ability_type or "终结" in ability_name)
    var cooldown := maxf(1.0, float(ability.get("cooldown", 6.0)))
    var startup := clampf(0.12 + cooldown * 0.012, 0.12, 0.48)
    if "蓄力" in ability_type or "蓄力" in ability_name:
        startup += 0.18
    if action in ["projectile", "homing_projectile"]:
        startup = maxf(startup, 0.22)
    var active := clampf(0.18 + float(effect.get("extra_hits", 0)) * 0.075, 0.18, 0.72)
    if action in ["field", "trap", "summon"]:
        active = clampf(float(effect.get("field_lifetime", effect.get("summon_lifetime", 1.0))), 0.18, 1.0)
    var recovery := clampf(0.24 + startup * 0.55, 0.24, 0.72)
    if finisher:
        recovery += 0.18
    var socket := "right_hand"
    if style == "锁链":
        socket = "chain_anchor"
    elif style == "盾拳":
        socket = "shield_hand"
    elif style == "乐器":
        socket = "instrument_anchor"
    elif style == "月弓":
        socket = "bow_hand"
    elif style == "空战":
        socket = "aerial_core"
    elif style in ["战斧", "锻造"]:
        socket = "weapon_hand"
    var root_motion := 0.0
    if motion in ["dash", "lunge", "leap"]:
        root_motion = 0.8 if not finisher else 1.35
    var yaw := 0.0
    if motion == "spin":
        yaw = 300.0 if finisher else 150.0
    elif motion == "guard":
        yaw = -8.0
    elif motion == "cast":
        yaw = 5.0
    var pose_scale := 1.08 if not finisher else 1.18
    var hit_count := maxi(1, 1 + int(effect.get("extra_hits", 0)))
    var hit_window_duration := minf(0.12, maxf(0.045, active * 0.2))
    var hit_windows: Array[Dictionary] = []
    var timeline: Array[Dictionary] = [
        {"time": 0.0, "event": "telegraph", "weight": 1.0 if finisher else 0.55},
        {"time": startup * 0.45, "event": "anticipation", "weight": 0.8},
        {"time": startup, "event": "action_start", "weight": 1.0}
    ]
    for hit_index in range(hit_count):
        var hit_offset := 0.0
        if hit_count > 1:
            hit_offset = (active - hit_window_duration) * float(hit_index) / float(hit_count - 1)
        var hit_start := startup + hit_offset
        var hit_end := minf(startup + active, hit_start + hit_window_duration)
        hit_windows.append({"start": hit_start, "end": hit_end, "index": hit_index})
        timeline.append({"time": hit_start, "event": "hit_start", "index": hit_index})
        timeline.append({"time": hit_end, "event": "hit_end", "index": hit_index})
    var recovery_start := startup + active
    var combo_cancel_at := startup + active * 0.72
    timeline.append({"time": combo_cancel_at, "event": "combo_cancel_open"})
    timeline.append({"time": recovery_start, "event": "recovery_start"})
    timeline.append({"time": startup + active + recovery, "event": "action_end"})
    timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
    )
    return {
        "class_id": class_id,
        "ability_id": str(ability.get("id", "")),
        "ability_name": ability_name,
        "style": style,
        "motion": motion,
        "action": action,
        "startup": startup,
        "active": active,
        "recovery": recovery,
        "total_duration": startup + active + recovery,
        "combo_cancel_at": combo_cancel_at,
        "hit_windows": hit_windows,
        "timeline": timeline,
        "interruptible_during_startup": action != "guard",
        "interruptible_during_recovery": true,
        "invulnerability_window": {"start": 0.0, "end": minf(startup * 0.35, 0.12)} if motion in ["dash", "leap"] else {"start": 0.0, "end": 0.0},
        "root_motion_window": {"start": startup * 0.35, "end": startup + active * 0.5} if root_motion > 0.0 else {"start": 0.0, "end": 0.0},
        "telegraph_duration": startup * (1.25 if finisher else 0.85),
        "root_motion_distance": root_motion,
        "rotation_degrees": yaw,
        "pose_scale": pose_scale,
        "camera_shake": 0.42 if finisher else (0.18 if action in ["heavy_strike", "throw"] else 0.08),
        "hit_stop": 0.075 if finisher else (0.045 if action in ["heavy_strike", "throw"] else 0.025),
        "hit_count": hit_count,
        "weapon_socket": socket,
        "vfx_anchor": "ground" if action in ["field", "trap"] else ("target" if action in ["projectile", "homing_projectile"] else ("upper_body" if motion in ["chain", "bow", "instrument", "divine", "cast", "summon"] else "ground" if motion in ["heavy", "axe", "throw"] else "upper_body")),
        "finisher": finisher
    }

const BASIC_COMBO_MOTIONS := {
    "pegasus": ["strike", "leap", "heavy"],
    "dragon": ["shield_strike", "guard", "heavy"],
    "cygnus": ["strike", "spin", "cast"],
    "andromeda": ["chain", "chain", "spin"],
    "phoenix": ["strike", "spin", "heavy"],
    "sea_dragon": ["cast", "spin", "heavy"],
    "tenmou": ["heavy", "axe", "throw"],
    "lyra": ["instrument", "cast", "spin"],
    "sea_swallow": ["dash", "strike", "spin"],
    "tenkishi": ["aerial_strike", "leap", "heavy"],
    "apollo": ["divine", "spin", "heavy"],
    "abel": ["divine", "cast", "heavy"],
    "athena": ["guard", "divine", "heavy"],
    "hades": ["cast", "spin", "heavy"],
    "poseidon": ["cast", "spin", "heavy"],
    "zeus": ["strike", "dash", "heavy"],
    "artemis": ["bow", "bow", "spin"],
    "hypnos": ["cast", "spin", "divine"],
    "thanatos": ["heavy", "throw", "spin"],
    "odin": ["strike", "cast", "heavy"],
    "ares": ["axe", "heavy", "throw"],
    "eris": ["spin", "cast", "heavy"],
    "lucifer": ["dash", "spin", "heavy"],
    "saturn": ["cast", "spin", "heavy"],
    "pallas": ["strike", "dash", "heavy"],
    "chronos": ["cast", "spin", "divine"],
    "hera": ["guard", "divine", "spin"],
    "demeter": ["cast", "spin", "heavy"],
    "hestia": ["strike", "cast", "heavy"],
    "hermes": ["dash", "strike", "spin"],
    "hephaestus": ["axe", "heavy", "throw"],
    "aphrodite": ["strike", "cast", "spin"]
}

static func get_basic_combo_profile(class_id: String, combo_step: int) -> Dictionary:
    if not BASIC_COMBO_MOTIONS.has(class_id):
        return {}
    var step := clampi(combo_step, 1, 3)
    var motions: Array = BASIC_COMBO_MOTIONS[class_id]
    var motion := str(motions[step - 1])
    var startup := [0.10, 0.13, 0.18][step - 1]
    var active := [0.16, 0.19, 0.24][step - 1]
    var recovery := [0.18, 0.22, 0.34][step - 1]
    return {
        "class_id": class_id,
        "motion": motion,
        "startup": startup,
        "active": active,
        "recovery": recovery,
        "total_duration": startup + active + recovery,
        "combo_cancel_at": startup + active * 0.72,
        "pose_scale": [1.04, 1.08, 1.14][step - 1],
        "rotation_degrees": 300.0 if motion == "spin" else (8.0 if motion in ["dash", "leap"] else 0.0),
        "combo_step": step,
        "authored_clip": "%s_basic_attack_%d" % [class_id, step]
    }

static func _resolve_motion(class_id: String, ability_type: String, action: String, ability_name: String) -> String:
    var text_value := ability_type + " " + ability_name
    if "防御" in ability_type or "护盾" in ability_type or "守护" in ability_type or "格挡" in ability_type or action == "guard":
        return "guard"
    if "旋" in ability_name or "风暴" in ability_name or "漩涡" in ability_name:
        return "spin"
    if "突进" in ability_type or "冲锋" in ability_type or "突袭" in ability_type or action in ["pursuit", "dash"]:
        return "dash"
    if "挑空" in ability_type or "跃" in ability_type or "跳" in ability_name:
        return "leap"
    if action == "throw" or "投技" in ability_type:
        return "throw"
    if action == "heavy_strike" or "重击" in ability_type:
        return "axe" if class_id in ["ares", "hephaestus", "tenmou"] else "heavy"
    if class_id == "andromeda":
        return "chain"
    if class_id == "lyra":
        return "instrument"
    if class_id == "artemis":
        return "bow"
    if class_id == "dragon" and ("攻击" in ability_type or "反击" in ability_type):
        return "shield_strike"
    if class_id in ["apollo", "athena", "hades", "poseidon", "zeus", "hypnos", "thanatos", "odin", "eris", "abel", "lucifer", "saturn", "pallas", "chronos", "hera", "demeter", "hestia", "hermes", "aphrodite"]:
        if action in ["projectile", "homing_projectile", "field", "trap", "summon"] or "奥义" in ability_type or "神" in ability_name:
            return "divine"
    if action == "summon":
        return "summon"
    if action in ["projectile", "homing_projectile", "field", "trap"]:
        return "cast"
    if action in ["heavy_strike"]:
        return "heavy"
    if class_id == "tenkishi":
        return "aerial_strike"
    return "strike"

static func validate_profile(profile: Dictionary) -> bool:
    var startup := float(profile.get("startup", -1.0))
    var active := float(profile.get("active", -1.0))
    var recovery := float(profile.get("recovery", -1.0))
    var total := float(profile.get("total_duration", -1.0))
    if startup <= 0.0 or active <= 0.0 or recovery <= 0.0:
        return false
    if not is_equal_approx(total, startup + active + recovery):
        return false
    if float(profile.get("combo_cancel_at", -1.0)) < startup:
        return false
    var windows: Array = profile.get("hit_windows", [])
    if windows.is_empty():
        return false
    for window in windows:
        var hit_start := float(window.get("start", -1.0))
        var hit_end := float(window.get("end", -1.0))
        if hit_start < startup or hit_end <= hit_start or hit_end > startup + active + 0.001:
            return false
    var timeline: Array = profile.get("timeline", [])
    if timeline.size() < 5:
        return false
    var previous_time := -1.0
    for marker in timeline:
        var marker_time := float(marker.get("time", -1.0))
        if marker_time < previous_time or marker_time < 0.0 or marker_time > total + 0.001:
            return false
        previous_time = marker_time
    return true

static func validate_catalog() -> bool:
    var class_catalog: Array = SkillSystem.get_class_skill_catalog()
    if CLASS_STYLE.size() != class_catalog.size():
        return false
    for class_entry in class_catalog:
        var class_id := str(class_entry.get("id", ""))
        if not CLASS_STYLE.has(class_id):
            return false
    return CLASS_STYLE.has("pegasus") and CLASS_STYLE.has("apollo") and CLASS_STYLE.has("tenkishi")
