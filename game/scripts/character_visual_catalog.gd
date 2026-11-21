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
    "hades": {"accent": Color(0.38, 0.20, 0.58), "crest": "crown", "ornament": "soul_wings", "shoulder_scale": Vector3(1.55, 1.25, 1.1), "wing_span": 1.7, "glow": 0.30, "metallic": 0.9, "silhouette": "reaper"},
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

const ARMOR_STAGE_PALETTES := {
    "bronze": {"metal": Color(0.66, 0.38, 0.22), "trim": Color(0.92, 0.66, 0.38), "metallic": 0.72, "glow": 0.04},
    "silver": {"metal": Color(0.68, 0.76, 0.86), "trim": Color(0.9, 0.94, 1.0), "metallic": 0.88, "glow": 0.08},
    "gold": {"metal": Color(0.94, 0.68, 0.22), "trim": Color(1.0, 0.88, 0.48), "metallic": 0.94, "glow": 0.14},
    "sea_scale": {"metal": Color(0.12, 0.56, 0.74), "trim": Color(0.44, 0.88, 1.0), "metallic": 0.96, "glow": 0.16},
    # Surplices are consistently black-purple; violet is a restrained secondary material, never gold.
    "surplice": {"metal": Color(0.045, 0.025, 0.085), "trim": Color(0.30, 0.16, 0.48), "metallic": 0.94, "glow": 0.12},
    # Dark Cloth is a separate black/graphite/steel-blue family, not a purple Surplice.
    "dark_cloth": {"metal": Color(0.025, 0.030, 0.050), "trim": Color(0.22, 0.28, 0.38), "metallic": 0.92, "glow": 0.06},
    "platinum": {"metal": Color(0.72, 0.78, 0.88), "trim": Color(0.96, 0.98, 1.0), "metallic": 1.0, "glow": 0.32},
    "god_cloth": {"metal": Color(0.88, 0.78, 0.48), "trim": Color(1.0, 0.94, 0.7), "metallic": 0.98, "glow": 0.28},
    "god_armor": {"metal": Color(0.72, 0.78, 0.98), "trim": Color(1.0, 0.9, 0.72), "metallic": 1.0, "glow": 0.36}
}

static func get_stage_palette(stage_id: String, awakened: bool = false) -> Dictionary:
    var palette: Dictionary = ARMOR_STAGE_PALETTES.get(stage_id, ARMOR_STAGE_PALETTES["bronze"]).duplicate(true)
    if awakened:
        palette["glow"] = minf(0.6, float(palette.get("glow", 0.0)) + 0.18)
        palette["metallic"] = minf(1.0, float(palette.get("metallic", 0.8)) + 0.04)
    return palette

static func get_profile(class_id: String) -> Dictionary:
    var result: Dictionary = DEFAULT_PROFILE.duplicate(true)
    if PROFILES.has(class_id):
        result.merge(PROFILES[class_id], true)
    return result

const EQUIPMENT_PROFILES := {
    "aries_gold_cloth": {"accent": Color(1.0, 0.82, 0.42), "ornament": "royal_wings", "crest": "horn", "shoulder_scale": Vector3(1.35, 1.1, 1.0)},
    "taurus_gold_cloth": {"accent": Color(1.0, 0.72, 0.3), "ornament": "war_spikes", "crest": "horn", "shoulder_scale": Vector3(1.75, 1.35, 1.2)},
    "gemini_gold_cloth": {"accent": Color(0.9, 0.84, 0.62), "ornament": "time_rings", "crest": "halo", "shoulder_scale": Vector3(1.4, 1.15, 1.0)},
    "cancer_gold_cloth": {"accent": Color(0.78, 0.78, 0.92), "ornament": "soul_wings", "crest": "crown", "shoulder_scale": Vector3(1.35, 1.2, 1.05)},
    "leo_gold_cloth": {"accent": Color(1.0, 0.72, 0.24), "ornament": "solar_wings", "crest": "sun", "shoulder_scale": Vector3(1.5, 1.2, 1.0)},
    "virgo_gold_cloth": {"accent": Color(1.0, 0.88, 0.58), "ornament": "radiant", "crest": "halo", "shoulder_scale": Vector3(1.25, 1.1, 1.0)},
    "libra_gold_cloth": {"accent": Color(0.82, 0.88, 1.0), "ornament": "aegis", "crest": "aegis", "shoulder_scale": Vector3(1.55, 1.2, 1.1)},
    "scorpio_gold_cloth": {"accent": Color(0.96, 0.38, 0.26), "ornament": "thorn_wings", "crest": "thorn", "shoulder_scale": Vector3(1.3, 1.1, 1.0)},
    "sagittarius_gold_cloth": {"accent": Color(1.0, 0.86, 0.46), "ornament": "heaven_wings", "crest": "wing", "shoulder_scale": Vector3(1.35, 1.15, 1.0), "wing_span": 1.45},
    "capricorn_gold_cloth": {"accent": Color(0.92, 0.78, 0.42), "ornament": "war_spikes", "crest": "spear", "shoulder_scale": Vector3(1.5, 1.2, 1.1)},
    "aquarius_gold_cloth": {"accent": Color(0.48, 0.86, 1.0), "ornament": "moon_wings", "crest": "ice", "shoulder_scale": Vector3(1.2, 1.05, 1.0)},
    "pisces_gold_cloth": {"accent": Color(0.92, 0.62, 0.82), "ornament": "petal_wings", "crest": "rose", "shoulder_scale": Vector3(1.15, 1.0, 1.0)},
    "god_cloth_archive": {"accent": Color(1.0, 0.86, 0.52), "ornament": "radiant"},
    "athena_divine_garment": {"accent": Color(1.0, 0.88, 0.58), "ornament": "aegis"},
    "poseidon_scale": {"accent": Color(0.22, 0.82, 1.0), "ornament": "tidal_fins"},
    "hades_divine_garment": {"accent": Color(0.68, 0.36, 0.82), "ornament": "soul_wings"},
    "odin_god_robe": {"accent": Color(0.48, 0.82, 1.0), "ornament": "rune_wings"},
    "saturn_chronotector": {"accent": Color(0.72, 0.52, 1.0), "ornament": "time_rings"},
    "apollo_divine_relic": {"accent": Color(1.0, 0.78, 0.22), "ornament": "solar_wings"},
    "athena_divine_relic": {"accent": Color(1.0, 0.88, 0.56), "ornament": "aegis"},
    "hades_divine_relic": {"accent": Color(0.66, 0.34, 0.84), "ornament": "soul_wings"},
    "poseidon_divine_relic": {"accent": Color(0.18, 0.78, 1.0), "ornament": "tidal_fins"},
    "zeus_divine_relic": {"accent": Color(1.0, 0.9, 0.52), "ornament": "storm_wings"},
    "artemis_divine_relic": {"accent": Color(0.72, 0.86, 1.0), "ornament": "moon_wings"},
    "hypnos_divine_relic": {"accent": Color(0.72, 0.68, 1.0), "ornament": "dream_wings"},
    "thanatos_divine_relic": {"accent": Color(0.7, 0.28, 0.54), "ornament": "soul_wings"},
    "odin_divine_relic": {"accent": Color(0.42, 0.8, 1.0), "ornament": "rune_wings"},
    "ares_divine_relic": {"accent": Color(0.94, 0.22, 0.16), "ornament": "war_spikes"},
    "eris_divine_relic": {"accent": Color(0.76, 0.32, 0.88), "ornament": "thorn_wings"},
    "abel_divine_relic": {"accent": Color(1.0, 0.46, 0.18), "ornament": "solar_wings"},
    "lucifer_divine_relic": {"accent": Color(0.86, 0.24, 0.22), "ornament": "fallen_wings"},
    "saturn_divine_relic": {"accent": Color(0.72, 0.48, 1.0), "ornament": "time_rings"},
    "pallas_divine_relic": {"accent": Color(1.0, 0.54, 0.7), "ornament": "time_rings"},
    "chronos_divine_relic": {"accent": Color(0.86, 0.76, 1.0), "ornament": "time_rings"},
    "hera_divine_relic": {"accent": Color(1.0, 0.7, 0.82), "ornament": "royal_wings"},
    "demeter_divine_relic": {"accent": Color(0.66, 0.86, 0.44), "ornament": "leaf_wings"},
    "hestia_divine_relic": {"accent": Color(1.0, 0.56, 0.24), "ornament": "flame_wings"},
    "hermes_divine_relic": {"accent": Color(0.48, 0.9, 0.88), "ornament": "swift_wings"},
    "hephaestus_divine_relic": {"accent": Color(1.0, 0.44, 0.18), "ornament": "forge_plates"},
    "aphrodite_divine_relic": {"accent": Color(1.0, 0.58, 0.8), "ornament": "petal_wings"}
}

static func get_equipment_profile(equipment: Dictionary) -> Dictionary:
    if equipment.is_empty():
        return {}
    var item_id := str(equipment.get("id", ""))
    if item_id.begins_with("dark_"):
        var dark_profile: Dictionary = get_profile(str(equipment.get("class_id", "")))
        var class_accent: Color = dark_profile.get("accent", Color(0.72, 0.42, 0.92))
        dark_profile["accent"] = Color(0.22, 0.28, 0.38).lerp(class_accent.darkened(0.55), 0.12)
        dark_profile["metal"] = Color(0.025, 0.030, 0.050)
        dark_profile["trim"] = Color(0.22, 0.28, 0.38)
        dark_profile["palette_family"] = "graphite_steel_blue"
        # Keep the shared void treatment while retaining the class-specific design language
        # for armor builders, previews, and later authored model variants.
        dark_profile["class_accent"] = class_accent
        dark_profile["class_ornament"] = str(dark_profile.get("ornament", "crest"))
        dark_profile["class_crest"] = str(dark_profile.get("crest", "star"))
        dark_profile["class_silhouette"] = str(dark_profile.get("silhouette", "balanced"))
        dark_profile["ornament"] = "dark_aura"
        dark_profile["armor_family"] = "dark_cloth"
        dark_profile["cape"] = false
        dark_profile["stage_variant"] = "dark_cloth"
        dark_profile["glow"] = maxf(0.22, float(dark_profile.get("glow", 0.1)))
        dark_profile["metallic"] = maxf(0.92, float(dark_profile.get("metallic", 0.82)))
        return dark_profile
    if item_id == "platinum_cloth_archive" or item_id.begins_with("platinum_") or str(equipment.get("category", "")) == "白金圣衣 Platinum Cloth":
        var platinum_class_id := str(equipment.get("class_id", ""))
        if not platinum_class_id.is_empty() and PROFILES.has(platinum_class_id):
            var platinum_profile: Dictionary = get_profile(platinum_class_id)
            var class_accent: Color = platinum_profile.get("accent", Color(0.9, 0.94, 1.0))
            platinum_profile["class_accent"] = class_accent
            platinum_profile["class_ornament"] = str(platinum_profile.get("ornament", "crest"))
            platinum_profile["class_crest"] = str(platinum_profile.get("crest", "star"))
            platinum_profile["class_silhouette"] = str(platinum_profile.get("silhouette", "balanced"))
            platinum_profile["accent"] = Color(0.9, 0.94, 1.0).lerp(class_accent, 0.24)
            platinum_profile["stage_variant"] = "platinum"
            platinum_profile["glow"] = maxf(0.34, float(platinum_profile.get("glow", 0.1)))
            platinum_profile["metallic"] = 1.0
            return platinum_profile
        return {"accent": Color(0.9, 0.94, 1.0), "ornament": "radiant", "glow": 0.34, "metallic": 1.0, "stage_variant": "platinum"}
    if EQUIPMENT_PROFILES.has(item_id):
        return EQUIPMENT_PROFILES[item_id].duplicate(true)
    var category := str(equipment.get("category", ""))
    match category:
        "黄金圣衣 Gold Cloth":
            return {"accent": Color(1.0, 0.78, 0.32), "ornament": "royal_wings"}
        "白银圣衣 Silver Cloth":
            return {"accent": Color(0.78, 0.86, 0.96), "ornament": "feather"}
        "青铜圣衣 Bronze Cloth":
            return {"accent": Color(0.72, 0.48, 0.28), "ornament": "crest"}
        "神圣衣 God Cloth":
            return {"accent": Color(1.0, 0.86, 0.52), "ornament": "radiant"}
        "鳞衣 Scale":
            return {"accent": Color(0.18, 0.78, 1.0), "ornament": "tidal_fins"}
        "冥衣 Surplice":
            return {"accent": Color(0.62, 0.32, 0.78), "ornament": "soul_wings"}
        "黑暗圣衣 Dark Cloth":
            return {"metal": Color(0.025, 0.030, 0.050), "trim": Color(0.22, 0.28, 0.38), "accent": Color(0.38, 0.48, 0.62), "palette_family": "graphite_steel_blue", "armor_family": "dark_cloth", "ornament": "dark_aura", "cape": false}
        "白金圣衣 Platinum Cloth":
            return {"accent": Color(0.9, 0.94, 1.0), "ornament": "radiant"}
        "天衣 Glory":
            return {"accent": Color(0.86, 0.94, 1.0), "ornament": "heaven_wings"}
        "神斗衣 God Robe":
            return {"accent": Color(0.44, 0.8, 1.0), "ornament": "rune_wings"}
        "刻衣 Chronotector":
            return {"accent": Color(0.72, 0.5, 1.0), "ornament": "time_rings"}
        "神明专属神衣":
            return {"accent": Color(1.0, 0.78, 0.38), "ornament": "radiant"}
    return {}

static func get_class_armor_detail_profile(class_id: String) -> Dictionary:
    var profile: Dictionary = get_profile(class_id)
    if profile.is_empty() or not PROFILES.has(class_id):
        return {}
    var ornament := str(profile.get("ornament", "crest"))
    var crest := str(profile.get("crest", "star"))
    var shoulder_form := "balanced"
    match ornament:
        "war_spikes", "thorn_wings", "forge_plates", "shield":
            shoulder_form = "spiked_guard"
        "tidal_fins", "fin", "scale", "moon_wings":
            shoulder_form = "fin"
        "royal_wings", "heaven_wings", "solar_wings", "radiant", "soul_wings":
            shoulder_form = "wing"
        "time_rings", "dream_wings", "sound", "aegis", "rune_wings":
            shoulder_form = "arcane"
        "chain", "comet", "swift_wings", "feather":
            shoulder_form = "streamlined"
    var helmet_form := "crown"
    match crest:
        "horn":
            helmet_form = "horned"
        "wing", "ice", "fin":
            helmet_form = "crested"
        "flame":
            helmet_form = "flame"
        "halo", "aegis", "crown":
            helmet_form = "halo"
    return {
        "class_id": class_id,
        "shoulder_form": shoulder_form,
        "helmet_form": helmet_form,
        "crest": crest,
        "ornament": ornament,
        "shoulder_scale": profile.get("shoulder_scale", Vector3.ONE),
        "wing_span": float(profile.get("wing_span", 0.0))
    }

static func get_class_armor_part_profiles(class_id: String, stage_id: String = "bronze", awakened: bool = false) -> Dictionary:
    if not PROFILES.has(class_id):
        return {}
    var identity: Dictionary = PROFILES[class_id]
    var ornament := str(identity.get("ornament", "crest"))
    var crest := str(identity.get("crest", "star"))
    var shoulder_scale: Vector3 = identity.get("shoulder_scale", Vector3.ONE)
    var stage_scale := 1.0
    match stage_id:
        "silver":
            stage_scale = 1.03
        "gold", "sea_scale", "surplice", "dark_cloth":
            stage_scale = 1.07
        "platinum", "god_cloth":
            stage_scale = 1.12
        "god_armor":
            stage_scale = 1.16
    if awakened:
        stage_scale *= 1.025
    var helmet_form := "crown"
    match crest:
        "horn", "spear", "thorn", "anvil":
            helmet_form = "crest_spike"
        "wing", "ice", "fin", "rune":
            helmet_form = "crest_fin"
        "flame", "sun", "bolt":
            helmet_form = "crest_flame"
        "halo", "aegis", "crown", "crescent":
            helmet_form = "halo"
        "clock", "dream":
            helmet_form = "arcane"
    var chest_form := "plated"
    if ornament in ["chain", "sound", "time_rings", "dream_wings"]:
        chest_form = "arcane_core"
    elif ornament in ["tidal_fins", "fin", "scale", "moon_wings"]:
        chest_form = "lamellar"
    elif ornament in ["war_spikes", "thorn_wings", "forge_plates", "fallen_wings"]:
        chest_form = "reinforced"
    var arm_form := "guard"
    if ornament in ["royal_wings", "heaven_wings", "solar_wings", "radiant"]:
        arm_form = "wing_guard"
    elif ornament in ["tidal_fins", "fin", "scale"]:
        arm_form = "fin_guard"
    elif ornament in ["chain", "comet", "swift_wings", "feather"]:
        arm_form = "streamlined"
    var waist_form := "tasset"
    if ornament in ["chain", "sound", "time_rings", "dream_wings"]:
        waist_form = "arcane_belt"
    elif ornament in ["war_spikes", "thorn_wings", "forge_plates"]:
        waist_form = "reinforced_tasset"
    elif ornament in ["tidal_fins", "fin", "scale", "moon_wings"]:
        waist_form = "fin_tasset"
    var leg_form := "greaves"
    if ornament in ["tidal_fins", "fin", "scale", "moon_wings"]:
        leg_form = "fin_greaves"
    elif ornament in ["war_spikes", "thorn_wings", "forge_plates"]:
        leg_form = "heavy_greaves"
    elif ornament in ["chain", "comet", "swift_wings", "feather"]:
        leg_form = "light_greaves"
    return {
        "class_id": class_id,
        "stage_id": stage_id,
        "awakened": awakened,
        "head": {"form": helmet_form, "scale": Vector3(1.0, 1.0, 1.0) * stage_scale, "crest": crest},
        "chest": {"form": chest_form, "scale": Vector3(1.0, 1.0, 1.0) * stage_scale, "ornament": ornament},
        "arms": {"form": arm_form, "scale": Vector3(shoulder_scale.x, shoulder_scale.y, shoulder_scale.z) * stage_scale, "ornament": ornament},
        "waist": {"form": waist_form, "scale": Vector3(1.0, 1.0, 1.0) * stage_scale, "ornament": ornament},
        "legs": {"form": leg_form, "scale": Vector3(1.0, 1.0, 1.0) * stage_scale, "ornament": ornament}
    }

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


# Faction armor families are separate from class silhouettes. These profiles feed
# previews and procedural armor builders; final authored rigs remain a separate art task.
const FACTION_ARMOR_FAMILIES := {
    "sanctuary": {"family":"saint_cloth","name":"圣衣","stage":"bronze","metal":Color(0.66,0.38,0.22),"trim":Color(0.92,0.66,0.38),"accent":Color(0.98,0.82,0.42),"helmet":"saint_crest","chest":"anatomical_plate","shoulder":"saint_guard","waist":"tasset","legs":"greaves"},
    "dark_saints": {"family":"dark_cloth","name":"暗黑圣衣","stage":"dark_cloth","metal":Color(0.025,0.030,0.050),"trim":Color(0.22,0.28,0.38),"accent":Color(0.38,0.48,0.62),"palette_family":"graphite_steel_blue","helmet":"razor_crest","chest":"angular_black_plate","shoulder":"spiked_guard","waist":"segmented_tasset","legs":"armored_greaves"},
    "sea": {"family":"scale","name":"鳞衣","stage":"sea_scale","metal":Color(0.06,0.34,0.52),"trim":Color(0.22,0.82,1.0),"accent":Color(0.18,0.78,1.0),"palette_family":"ocean_teal","helmet":"fin_crest","chest":"overlapping_scales","shoulder":"fin_guard","waist":"fin_tasset","legs":"fin_greaves"},
    "underworld": {"family":"surplice","name":"冥衣","stage":"surplice","metal":Color(0.045,0.025,0.085),"trim":Color(0.30,0.16,0.48),"accent":Color(0.48,0.22,0.68),"palette_family":"black_violet","helmet":"soul_crown","chest":"ribbed_soul_plate","shoulder":"bone_wing_guard","waist":"soul_tasset","legs":"spined_greaves"},
    "divine": {"family":"god_cloth","name":"神圣衣","stage":"god_cloth","metal":Color(0.88,0.78,0.48),"trim":Color(1.0,0.94,0.7),"accent":Color(1.0,0.86,0.52),"palette_family":"radiant_gold","helmet":"divine_halo","chest":"radiant_plate","shoulder":"radiant_wing","waist":"divine_tasset","legs":"radiant_greaves"},
    "asgard": {"family":"god_robe","name":"神斗衣","stage":"god_armor","metal":Color(0.34,0.48,0.62),"trim":Color(0.64,0.84,1.0),"accent":Color(0.48,0.82,1.0),"palette_family":"northern_ice_silver","helmet":"rune_helm","chest":"rune_plate","shoulder":"rune_guard","waist":"fur_tasset","legs":"rune_greaves"},
    "steel": {"family":"steel_armor","name":"钢铁装甲","stage":"silver","metal":Color(0.24,0.32,0.40),"trim":Color(0.48,0.72,0.86),"accent":Color(0.45,0.72,0.86),"palette_family":"mechanical_steel","helmet":"sensor_visor","chest":"mechanical_core","shoulder":"mechanical_guard","waist":"utility_belt","legs":"servo_greaves"},
    "bluegrad": {"family":"ice_armor","name":"蓝格拉德冰甲","stage":"silver","metal":Color(0.30,0.48,0.66),"trim":Color(0.70,0.90,1.0),"accent":Color(0.62,0.88,1.0),"palette_family":"glacier_blue","helmet":"ice_crown","chest":"frost_plate","shoulder":"crystal_guard","waist":"ice_tasset","legs":"frost_greaves"},
    "fallen": {"family":"fallen_armor","name":"堕天装甲","stage":"god_armor","metal":Color(0.12,0.045,0.09),"trim":Color(0.72,0.22,0.42),"accent":Color(0.88,0.28,0.32),"palette_family":"fallen_crimson","helmet":"horned_helm","chest":"void_plate","shoulder":"fallen_wing_guard","waist":"void_tasset","legs":"talon_greaves"},
    "titans": {"family":"chronotector","name":"泰坦刻衣","stage":"god_armor","metal":Color(0.24,0.18,0.38),"trim":Color(0.72,0.52,1.0),"accent":Color(0.82,0.68,1.0),"palette_family":"titan_violet","helmet":"time_crown","chest":"chronal_plate","shoulder":"ring_guard","waist":"time_tasset","legs":"chronal_greaves"},
    "giants": {"family":"giant_plate","name":"巨人重甲","stage":"gold","metal":Color(0.36,0.26,0.18),"trim":Color(0.82,0.58,0.34),"accent":Color(0.72,0.48,0.28),"palette_family":"stone_bronze","helmet":"heavy_helm","chest":"heavy_plate","shoulder":"massive_guard","waist":"heavy_tasset","legs":"heavy_greaves"},
    "hongmeng": {"family":"primordial_armor","name":"鸿蒙神甲","stage":"god_armor","metal":Color(0.16,0.10,0.32),"trim":Color(0.72,0.55,1.0),"accent":Color(0.88,0.78,1.0),"palette_family":"primordial_cosmic","helmet":"cosmic_crown","chest":"starfield_plate","shoulder":"cosmic_guard","waist":"orbit_tasset","legs":"cosmic_greaves"}
}

const COSTUME_APPEARANCES := {
    "summer": {"name":"夏季时装","accent":Color(0.22,0.78,0.92),"silhouette":"light_casual","cape":false,"armor_overlay":false},
    "christmas": {"name":"圣诞时装","accent":Color(0.82,0.18,0.22),"silhouette":"winter_casual","cape":false,"armor_overlay":false},
    "school": {"name":"校园时装","accent":Color(0.24,0.32,0.58),"silhouette":"school_uniform","cape":false,"armor_overlay":false},
    "casual": {"name":"休闲时装","accent":Color(0.38,0.48,0.58),"silhouette":"street_casual","cape":false,"armor_overlay":false},
    "royal": {"name":"王子礼服","accent":Color(0.78,0.62,0.30),"silhouette":"formal_royal","cape":false,"armor_overlay":false}
}

static func resolve_armor_attachment_anchor(part_id: String, side_x: float = 0.0, part_y: float = 99.0) -> String:
    if part_id == "arms":
        var limb_prefix := "forearms" if part_y < 0.98 else "arms"
        return limb_prefix + ("_left" if side_x < 0.0 else "_right")
    if part_id == "legs":
        return "legs_left" if side_x < 0.0 else "legs_right"
    if part_id in ["head", "chest", "waist"]:
        return part_id
    return ""


static func get_faction_armor_profile(faction_id: String, class_id: String = "") -> Dictionary:
    var result: Dictionary = FACTION_ARMOR_FAMILIES.get(faction_id, FACTION_ARMOR_FAMILIES["sanctuary"]).duplicate(true)
    result["faction_id"] = faction_id if FACTION_ARMOR_FAMILIES.has(faction_id) else "sanctuary"
    result["class_id"] = class_id
    var identity := get_profile(class_id)
    result["class_crest"] = str(identity.get("crest", "star"))
    result["class_ornament"] = str(identity.get("ornament", "crest"))
    result["class_silhouette"] = str(identity.get("silhouette", "balanced"))
    result["shoulder_scale"] = identity.get("shoulder_scale", Vector3.ONE)
    return result

static func get_costume_profile(costume_id: String) -> Dictionary:
    if costume_id.is_empty() or not COSTUME_APPEARANCES.has(costume_id):
        return {}
    var result: Dictionary = COSTUME_APPEARANCES[costume_id].duplicate(true)
    result["costume_id"] = costume_id
    result["cape"] = false
    result["armor_overlay"] = false
    return result

static func validate_faction_armor_families() -> Dictionary:
    var errors: Array[String] = []
    for faction_id in FACTION_ARMOR_FAMILIES:
        var profile: Dictionary = FACTION_ARMOR_FAMILIES[faction_id]
        for key in ["family", "name", "metal", "trim", "accent", "helmet", "chest", "shoulder", "waist", "legs"]:
            if not profile.has(key):
                errors.append("%s missing %s" % [faction_id, key])
    var surplice: Dictionary = FACTION_ARMOR_FAMILIES["underworld"]
    var dark_cloth: Dictionary = FACTION_ARMOR_FAMILIES["dark_saints"]
    if str(surplice.get("palette_family", "")) == str(dark_cloth.get("palette_family", "")):
        errors.append("Surplice and Dark Cloth palettes must remain distinct")
    return {"valid": errors.is_empty() and FACTION_ARMOR_FAMILIES.size() == 12, "faction_count": FACTION_ARMOR_FAMILIES.size(), "errors": errors}
