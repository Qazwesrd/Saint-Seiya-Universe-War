extends RefCounted
class_name SkillAnimationCatalog
## Runtime animation timing and procedural pose metadata for every class ability.
## Authored skeletal clips can replace these profiles without changing combat data.

const CLASS_STYLE := {
    "pegasus": "拳击", "dragon": "盾拳", "cygnus": "冰拳", "andromeda": "锁链",
    "phoenix": "火焰拳", "sea_dragon": "次元掌", "lyra": "乐器", "tenkishi": "空战",
    "apollo": "神圣", "athena": "神圣", "hades": "暗影", "poseidon": "海潮",
    "zeus": "雷霆", "odin": "寒霜", "artemis": "月弓", "ares": "战斧",
    "hermes": "迅捷", "hephaestus": "锻造", "hestia": "圣焰", "hera": "神圣",
    "demeter": "自然", "eris": "混沌", "hypnos": "梦境", "thanatos": "死亡",
    "thanatos_divine": "死亡", "hypnos_divine": "梦境", "chronos": "时空",
    "saturn": "时空", "tartarus": "深渊", "nyx": "暗夜", "eos": "黎明",
    "helios": "日耀"
}

static func get_profile(class_id: String, ability: Dictionary) -> Dictionary:
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
        active = minf(1.0, float(effect.get("field_lifetime", effect.get("summon_lifetime", 1.0))))
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
    var hit_count := 1 + int(effect.get("extra_hits", 0))
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
        "combo_cancel_at": startup + active * 0.72,
        "telegraph_duration": startup * (1.25 if finisher else 0.85),
        "root_motion_distance": root_motion,
        "rotation_degrees": yaw,
        "pose_scale": pose_scale,
        "camera_shake": 0.42 if finisher else (0.18 if action in ["heavy_strike", "throw"] else 0.08),
        "hit_stop": 0.075 if finisher else (0.045 if action in ["heavy_strike", "throw"] else 0.025),
        "hit_count": hit_count,
        "weapon_socket": socket,
        "vfx_anchor": "ground" if action in ["field", "trap"] else ("target" if action in ["projectile", "homing_projectile"] else "upper_body"),
        "finisher": finisher
    }

static func _resolve_motion(class_id: String, ability_type: String, action: String, ability_name: String) -> String:
    if "防御" in ability_type or "护盾" in ability_type or "守护" in ability_type or action == "guard":
        return "guard"
    if "旋" in ability_name or "风暴" in ability_name or "漩涡" in ability_name:
        return "spin"
    if "突进" in ability_type or "冲锋" in ability_type or "突袭" in ability_type or action in ["pursuit", "dash"]:
        return "dash"
    if "挑空" in ability_type or "跃" in ability_type or "跳" in ability_name:
        return "leap"
    if action in ["projectile", "homing_projectile", "field", "trap", "summon"]:
        return "cast"
    if action in ["heavy_strike", "throw"]:
        return "heavy"
    if class_id == "tenkishi":
        return "aerial_strike"
    return "strike"

static func validate_catalog() -> bool:
    return CLASS_STYLE.size() >= 32 and CLASS_STYLE.has("pegasus") and CLASS_STYLE.has("apollo") and CLASS_STYLE.has("tenkishi")
