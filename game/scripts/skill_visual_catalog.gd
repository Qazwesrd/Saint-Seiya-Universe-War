extends RefCounted
class_name SkillVisualCatalog
## Shared elemental presentation profiles for the complete 768-skill roster.

const ELEMENTS := {
    "fire": {"color": Color(1.0, 0.28, 0.08), "shape": "flare", "glow": 0.46, "impact_scale": 1.15},
    "ice": {"color": Color(0.42, 0.86, 1.0), "shape": "shard", "glow": 0.42, "impact_scale": 0.95},
    "lightning": {"color": Color(1.0, 0.9, 0.32), "shape": "bolt", "glow": 0.52, "impact_scale": 1.05},
    "light": {"color": Color(1.0, 0.86, 0.58), "shape": "halo", "glow": 0.5, "impact_scale": 1.2},
    "dark": {"color": Color(0.58, 0.24, 0.82), "shape": "void", "glow": 0.38, "impact_scale": 1.1},
    "water": {"color": Color(0.18, 0.72, 1.0), "shape": "wave", "glow": 0.34, "impact_scale": 1.0},
    "wind": {"color": Color(0.48, 1.0, 0.78), "shape": "crescent", "glow": 0.32, "impact_scale": 0.9},
    "time": {"color": Color(0.72, 0.56, 1.0), "shape": "ring", "glow": 0.48, "impact_scale": 1.0},
    "soul": {"color": Color(0.72, 0.36, 0.9), "shape": "wisp", "glow": 0.4, "impact_scale": 1.05},
    "sound": {"color": Color(0.7, 0.68, 1.0), "shape": "pulse", "glow": 0.36, "impact_scale": 0.9},
    "cosmos": {"color": Color(0.42, 0.66, 1.0), "shape": "star", "glow": 0.4, "impact_scale": 1.0}
}

static func get_profile(class_id: String, ability: Dictionary) -> Dictionary:
    var text_value := "%s %s %s %s" % [
        str(ability.get("name", "")),
        str(ability.get("description", "")),
        str(ability.get("type", "")),
        str(ability.get("role", ""))
    ]
    var element := "cosmos"
    if "冰" in text_value or "冻结" in text_value or "冰霜" in text_value:
        element = "ice"
    elif "火" in text_value or "灼烧" in text_value or "烈焰" in text_value or "太阳" in text_value:
        element = "fire"
    elif "雷" in text_value or "闪电" in text_value or "雷霆" in text_value:
        element = "lightning"
    elif "光" in text_value or "圣" in text_value or "神圣" in text_value or "守护" in text_value:
        element = "light"
    elif "暗" in text_value or "虚空" in text_value or "冥" in text_value or "黑" in text_value:
        element = "dark"
    elif "海" in text_value or "潮" in text_value or "水" in text_value or "波塞冬" in text_value:
        element = "water"
    elif "风" in text_value or "疾风" in text_value or "迅捷" in text_value:
        element = "wind"
    elif "时间" in text_value or "时空" in text_value or "时钟" in text_value:
        element = "time"
    elif "灵魂" in text_value or "生命汲取" in text_value or "死亡" in text_value:
        element = "soul"
    elif "音" in text_value or "琴" in text_value or "共鸣" in text_value:
        element = "sound"
    var result: Dictionary = ELEMENTS[element].duplicate(true)
    var class_profile := CharacterVisualCatalog.get_profile(class_id)
    if element == "cosmos":
        result["color"] = class_profile.get("accent", Color(0.42, 0.66, 1.0))
    result["element"] = element
    result["shape"] = str(result.get("shape", "star"))
    result["glow"] = clampf(float(result.get("glow", 0.4)), 0.0, 0.6)
    result["impact_scale"] = clampf(float(result.get("impact_scale", 1.0)), 0.5, 1.5)
    result["lifetime"] = 0.24 if element in ["lightning", "wind"] else 0.42
    return result

static func validate_catalog() -> Dictionary:
    var errors: Array[String] = []
    for element in ELEMENTS:
        var profile: Dictionary = ELEMENTS[element]
        if not profile.get("color") is Color:
            errors.append("%s has no valid color" % element)
        if float(profile.get("glow", -1.0)) < 0.0 or float(profile.get("glow", 0.0)) > 0.6:
            errors.append("%s has invalid glow" % element)
        if float(profile.get("impact_scale", 0.0)) < 0.5 or float(profile.get("impact_scale", 2.0)) > 1.5:
            errors.append("%s has invalid impact scale" % element)
    return {"valid": errors.is_empty(), "element_count": ELEMENTS.size(), "errors": errors}
