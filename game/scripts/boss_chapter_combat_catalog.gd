extends RefCounted
## Seven campaign chapters have distinct boss combat identities.
const CHAPTER_PROFILES := {
    "galaxy_wars": {"mechanic":"cosmic_pressure","heavy_interval_scale":1.0,"windup_scale":1.0,"recovery_scale":1.0,"clash_threshold":1.0,"label":"银河战争"},
    "sanctuary_twelve_houses": {"mechanic":"golden_guard","heavy_interval_scale":0.92,"windup_scale":1.08,"recovery_scale":1.12,"clash_threshold":1.12,"label":"黄金十二宫"},
    "asgard": {"mechanic":"frost_hunt","heavy_interval_scale":0.86,"windup_scale":0.9,"recovery_scale":0.88,"clash_threshold":0.94,"label":"北欧仙宫"},
    "poseidon": {"mechanic":"tidal_control","heavy_interval_scale":1.0,"windup_scale":1.0,"recovery_scale":0.96,"clash_threshold":1.08,"label":"海皇篇"},
    "hades": {"mechanic":"underworld_pressure","heavy_interval_scale":0.9,"windup_scale":1.12,"recovery_scale":1.08,"clash_threshold":1.18,"label":"冥王篇"},
    "heaven": {"mechanic":"divine_judgment","heavy_interval_scale":0.82,"windup_scale":1.05,"recovery_scale":1.15,"clash_threshold":1.25,"label":"天界篇"},
    "original_final": {"mechanic":"primordial_adaptation","heavy_interval_scale":0.88,"windup_scale":1.0,"recovery_scale":1.0,"clash_threshold":1.2,"label":"原创终章"}
}
static func get_profile(archetype_id: String) -> Dictionary:
    var chapter_id := ""
    if archetype_id.begins_with("arena_"):
        chapter_id = "galaxy_wars"
    elif archetype_id.begins_with("gold_") or archetype_id == "pope_saga":
        chapter_id = "sanctuary_twelve_houses"
    elif archetype_id.begins_with("god_warrior_") or archetype_id.begins_with("asgard_"):
        chapter_id = "asgard"
    elif archetype_id.begins_with("mariner_") or archetype_id == "poseidon_emperor":
        chapter_id = "poseidon"
    elif archetype_id.begins_with("judge_") or archetype_id.begins_with("hades_") or archetype_id in ["hypnos_guardian", "thanatos_reaper"]:
        chapter_id = "hades"
    elif archetype_id.begins_with("heaven") or archetype_id in ["heaven_gatekeeper", "heavenly_warden", "celestial_trial", "apollo_trial", "zeus_trial"]:
        chapter_id = "heaven"
    elif archetype_id in ["primordial_void", "cosmos_warden", "universe_arbiter", "divine_echo"]:
        chapter_id = "original_final"
    else:
        chapter_id = "galaxy_wars"
    var profile: Dictionary = CHAPTER_PROFILES.get(chapter_id, CHAPTER_PROFILES["galaxy_wars"]).duplicate(true)
    profile["chapter_id"] = chapter_id
    profile["boss_id"] = archetype_id
    return profile
static func validate_catalog() -> bool:
    if CHAPTER_PROFILES.size() != 7:
        return false
    for chapter_id in CHAPTER_PROFILES:
        var profile: Dictionary = CHAPTER_PROFILES[chapter_id]
        for key in ["mechanic","heavy_interval_scale","windup_scale","recovery_scale","clash_threshold","label"]:
            if not profile.has(key):
                return false
        if float(profile["heavy_interval_scale"]) <= 0.0 or float(profile["clash_threshold"]) <= 0.0:
            return false
    return true
