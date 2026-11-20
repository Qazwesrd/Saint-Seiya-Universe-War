extends RefCounted
class_name CharacterVisualCatalog
## Data-driven visual identity for every playable class.
## Procedural geometry is a fallback until authored, licensed character rigs are supplied.

const DEFAULT_PROFILE := {
    "accent": Color(1.0, 0.78, 0.28),
    "crest": "star",
    "ornament": "crest",
    "shoulder_scale": Vector3(1.0, 1.0, 1.0),
    "wing_span": 1.0,
    "glow": 0.10,
    "metallic": 0.82,
    "silhouette": "balanced"
}

const PROFILES := {
    "pegasus": {"accent": Color(0.98, 0.82, 0.42), "crest": "wing", "ornament": "comet", "shoulder_scale": Vector3(1.25, 0.9, 1.0), "wing_span": 0.0, "glow": 0.12, "metallic": 0.78, "silhouette": "swift"},
    "dragon": {"accent": Color(0.20, 0.88, 0.48), "crest": "horn", "ornament": "shield", "shoulder_scale": Vector3(1.35, 1.05, 1.15), "wing_span": 0.0, "glow": 0.08, "metallic": 0.88, "silhouette": "guard"},
    "cygnus": {"accent": Color(0.62, 0.90, 1.0), "crest": "ice", "ornament": "feather", "shoulder_scale": Vector3(1.1, 1.0, 1.0), "wing_span": 0.8, "glow": 0.20, "metallic": 0.9, "silhouette": "frost"},
    "andromeda": {"accent": Color(0.95, 0.42, 0.72), "crest": "halo", "ornament": "chain", "shoulder_scale": Vector3(0.95, 1.0, 1.0), "wing_span": 0.65, "glow": 0.18, "metallic": 0.76, "silhouette": "grace"},
    "phoenix": {"accent": Color(1.0, 0.38, 0.12), "crest": "flame", "ornament": "feather", "shoulder_scale": Vector3(1.15, 1.15, 1.0), "wing_span": 1.15, "glow": 0.28, "metallic": 0.84, "silhouette": "flare"},
    "sea_dragon": {"accent": Color(0.22, 0.92, 0.92), "crest": "fin", "ornament": "scale", "shoulder_scale": Vector3(1.35, 0.9, 1.1), "wing_span": 0.35, "glow": 0.16, "metallic": 0.92, "silhouette": "tidal"},
    "tenmou": {"accent": Color(0.88, 0.78, 0.42), "crest": "sun", "ornament": "radiant", "shoulder_scale": Vector3(1.25, 1.2, 1.0), "wing_span": 0.9, "glow": 0.22, "metallic": 0.9, "silhouette": "radiant"},
    "lyra": {"accent": Color(0.76, 0.62, 1.0), "crest": "lyre", "ornament": "sound", "shoulder_scale": Vector3(0.95, 1.0, 1.0), "wing_span": 0.45, "glow": 0.16, "metallic": 0.78, "silhouette": "resonance"},
    "sea_swallow": {"accent": Color(0.32, 0.76, 1.0), "crest": "wave", "ornament": "fin", "shoulder_scale": Vector3(1.0, 0.95, 1.0), "wing_span": 0.55, "glow": 0.14, "metallic": 0.86, "silhouette": "flow"},
    "apollo": {"accent": Color(1.0, 0.76, 0.22), "crest": "sun", "ornament": "solar_wings", "shoulder_scale": Vector3(1.5, 1.25, 1.0), "wing_span": 1.8, "glow": 0.42, "metallic": 0.94, "silhouette": "solar"},
    "abel": {"accent": Color(1.0, 0.46, 0.20), "crest": "sun", "ornament": "solar_wings", "shoulder_scale": Vector3(1.45, 1.2, 1.0), "wing_span": 1.65, "glow": 0.38, "metallic": 0.92, "silhouette": "solar"},
    "athena": {"accent": Color(0.96, 0.86, 0.52), "crest": "aegis", "ornament": "aegis", "shoulder_scale": Vector3(1.35, 1.1, 1.1), "wing_span": 1.1, "glow": 0.32, "metallic": 0.94, "silhouette": "guardian"},
    "hades": {"accent": Color(0.68, 0.40, 0.88), "crest": "crown", "ornament": "soul_wings", "shoulder_scale": Vector3(1.55, 1.25, 1.1), "wing_span": 1.7, "glow": 0.30, "metallic": 0.9, "silhouette": "reaper"},
    "poseidon": {"accent": Color(0.20, 0.82, 1.0), "crest": "trident", "ornament": "tidal_fins", "shoulder_scale": Vector3(1.5, 1.1, 1.2), "wing_span": 1.25, "glow": 0.28, "metallic": 0.96, "silhouette": "ocean"},
    "zeus": {"accent": Color(1.0, 0.92, 0.56), "crest": "bolt", "ornament": "storm_wings", "shoulder_scale": Vector3(1.6, 1.25, 1.1), "wing_span": 1.8, "glow": 0.45, "metallic": 0.96, "silhouette": "storm"},
    "artemis": {"accent": Color(0.72, 0.86, 1.0), "crest": "crescent", "ornament": "moon_wings", "shoulder_scale": Vector3(1.15, 1.05, 1.0), "wing_span": 1.35, "glow": 0.30, "metallic": 0.9, "silhouette": "lunar"},
    "hypnos": {"accent": Color(0.76, 0.72, 1.0), "crest": "dream", "ornament": "dream_wings", "shoulder_scale": Vector3(1.25, 1.2, 1.0), "wing_span": 1.5, "glow": 0.32, "metallic": 0.86, "silhouette": "dream"},
    "thanatos": {"accent": Color(0.72, 0.30, 0.54), "crest": "scythe", "ornament": "soul_wings", "shoulder_scale": Vector3(1.5, 1.2, 1.1), "wing_span": 1.6, "glow": 0.28, "metallic": 0.9, "silhouette": "reaper"},
    "odin": {"accent": Color(0.42, 0.82, 1.0), "crest": "rune", "ornament": "rune_wings", "shoulder_scale": Vector3(1.35, 1.15, 1.0), "wing_span": 1.2, "glow": 0.28, "metallic": 0.9, "silhouette": "rune"},
    "ares": {"accent": Color(0.96, 0.24, 0.18), "crest": "spear", "ornament": "war_spikes", "shoulder_scale": Vector3(1.65, 1.2, 1.15), "wing_span": 1.0, "glow": 0.26, "metallic": 0.94, "silhouette": "war"},
    "eris": {"accent": Color(0.76, 0.34, 0.86), "crest": "thorn", "ornament": "thorn_wings", "shoulder_scale": Vector3(1.35, 1.1, 1.0), "wing_span": 1.25, "glow": 0.3, "metallic": 0.88, "silhouette": "chaos"},
    "lucifer": {"accent": Color(0.88, 0.28, 0.22), "crest": "horn", "ornament": "fallen_wings", "shoulder_scale": Vector3(1.6, 1.25, 1.1), "wing_span": 1.7, "glow": 0.32, "metallic": 0.9, "silhouette": "fallen"},
    "saturn": {"accent": Color(0.72, 0.48, 1.0), "crest": "clock", "ornament": "time_rings", "shoulder_scale": Vector3(1.45, 1.2, 1.1), "wing_span": 1.25, "glow": 0.34, "metallic": 0.94, "silhouette": "chrono"},
    "pallas": {"accent": Color(1.0, 0.56, 0.72), "crest": "spear", "ornament": "time_rings", "shoulder_scale": Vector3(1.3, 1.1, 1.0), "wing_span": 1.0, "glow": 0.28, "metallic": 0.9, "silhouette": "chrono"},
    "chronos": {"accent": Color(0.88, 0.78, 1.0), "crest": "clock", "ornament": "time_rings", "shoulder_scale": Vector3(1.65, 1.3, 1.15), "wing_span": 1.5, "glow": 0.42, "metallic": 0.98, "silhouette": "titan"},
    "hera": {"accent": Color(1.0, 0.72, 0.84), "crest": "crown", "ornament": "royal_wings", "shoulder_scale": Vector3(1.35, 1.25, 1.0), "wing_span": 1.3, "glow": 0.32, "metallic": 0.92, "silhouette": "royal"},
    "demeter": {"accent": Color(0.68, 0.88, 0.48), "crest": "harvest", "ornament": "leaf_wings", "shoulder_scale": Vector3(1.25, 1.1, 1.0), "wing_span": 1.1, "glow": 0.24, "metallic": 0.84, "silhouette": "nature"},
    "hestia": {"accent": Color(1.0, 0.58, 0.28), "crest": "flame", "ornament": "flame_wings", "shoulder_scale": Vector3(1.2, 1.1, 1.0), "wing_span": 0.95, "glow": 0.34, "metallic": 0.88, "silhouette": "hearth"},
    "hermes": {"accent": Color(0.52, 0.92, 0.9), "crest": "wing", "ornament": "swift_wings", "shoulder_scale": Vector3(1.0, 0.95, 1.0), "wing_span": 1.2, "glow": 0.28, "metallic": 0.86, "silhouette": "swift"},
    "hephaestus": {"accent": Color(1.0, 0.48, 0.22), "crest": "anvil", "ornament": "forge_plates", "shoulder_scale": Vector3(1.7, 1.25, 1.2), "wing_span": 0.65, "glow": 0.3, "metallic": 0.98, "silhouette": "forge"},
    "aphrodite": {"accent": Color(1.0, 0.62, 0.82), "crest": "rose", "ornament": "petal_wings", "shoulder_scale": Vector3(1.1, 1.0, 1.0), "wing_span": 1.2, "glow": 0.28, "metallic": 0.84, "silhouette": "elegant"},
    "tenkishi": {"accent": Color(0.86, 0.92, 1.0), "crest": "halo", "ornament": "heaven_wings", "shoulder_scale": Vector3(1.45, 1.25, 1.05), "wing_span": 2.0, "glow": 0.4, "metallic": 0.96, "silhouette": "celestial"}
}

static func get_profile(class_id: String) -> Dictionary:
    var result: Dictionary = DEFAULT_PROFILE.duplicate(true)
    if PROFILES.has(class_id):
        result.merge(PROFILES[class_id], true)
    return result

static func validate_catalog() -> Dictionary:
    var errors: Array[String] = []
    for class_id in PROFILES:
        var profile: Dictionary = PROFILES[class_id]
        for key in ["accent", "crest", "ornament", "shoulder_scale", "wing_span", "glow", "metallic", "silhouette"]:
            if not profile.has(key):
                errors.append("%s missing %s" % [class_id, key])
        if float(profile.get("wing_span", -1.0)) < 0.0 or float(profile.get("wing_span", 0.0)) > 2.5:
            errors.append("%s invalid wing span" % class_id)
        if float(profile.get("glow", -1.0)) < 0.0 or float(profile.get("glow", 0.0)) > 0.6:
            errors.append("%s invalid glow" % class_id)
    return {"valid": errors.is_empty() and PROFILES.size() == 32, "class_count": PROFILES.size(), "errors": errors}
