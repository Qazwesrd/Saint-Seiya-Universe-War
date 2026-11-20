extends RefCounted
class_name EnemyVisualCatalog
## Data-driven silhouettes and armor accents for campaign enemies and bosses.

static func get_profile(archetype_id: String, boss: bool, base_color: Color) -> Dictionary:
	var family := "cosmic"
	if archetype_id.begins_with("gold_"):
		family = "gold_sanctuary"
	elif archetype_id.begins_with("judge_") or archetype_id in ["hades_emperor", "thanatos_reaper", "hypnos_guardian", "cocytus_guard", "wailing_wall_guard"]:
		family = "underworld"
	elif archetype_id.begins_with("mariner_") or archetype_id.begins_with("sea_") or archetype_id.contains("poseidon"):
		family = "sea_scale"
	elif archetype_id.begins_with("god_warrior_") or archetype_id.contains("asgard"):
		family = "asgard"
	elif archetype_id.begins_with("heaven") or archetype_id.contains("celestial") or archetype_id.contains("apollo") or archetype_id.contains("zeus"):
		family = "celestial"
	elif archetype_id.begins_with("arena_"):
		family = "arena"
	elif archetype_id.contains("void") or archetype_id.contains("cosmos") or archetype_id.contains("universe"):
		family = "primordial"

	var crest := "crest"
	match family:
		"gold_sanctuary":
			crest = "horn"
		"underworld":
			crest = "crown"
		"sea_scale":
			crest = "fin"
		"asgard":
			crest = "rune"
		"celestial":
			crest = "halo"
		"primordial":
			crest = "void"
		"arena":
			crest = "crest"

	var accent := base_color.lightened(0.32)
	var secondary := base_color.darkened(0.34)
	var glow := 0.16
	var metallic := 0.72
	match family:
		"gold_sanctuary":
			accent = Color(1.0, 0.78, 0.28)
			secondary = Color(0.34, 0.22, 0.08)
			glow = 0.22
			metallic = 0.96
		"underworld":
			accent = Color(0.78, 0.48, 0.94)
			secondary = Color(0.16, 0.08, 0.24)
			glow = 0.3
			metallic = 0.9
		"sea_scale":
			accent = Color(0.34, 0.9, 1.0)
			secondary = Color(0.04, 0.22, 0.38)
			glow = 0.24
			metallic = 0.94
		"asgard":
			accent = Color(0.64, 0.88, 1.0)
			secondary = Color(0.16, 0.28, 0.42)
			glow = 0.2
			metallic = 0.88
		"celestial":
			accent = Color(1.0, 0.9, 0.62)
			secondary = Color(0.32, 0.34, 0.5)
			glow = 0.34
			metallic = 0.96
		"primordial":
			accent = Color(0.72, 0.46, 1.0)
			secondary = Color(0.08, 0.04, 0.16)
			glow = 0.38
			metallic = 0.92

	return {
		"family": family,
		"crest": crest,
		"accent": accent,
		"secondary": secondary,
		"glow": glow if boss else glow * 0.55,
		"metallic": metallic,
		"shoulder_width": 1.24 if boss else 1.0,
		"winged": boss and family in ["underworld", "celestial", "primordial"],
		"halo": boss and family in ["celestial", "primordial"]
	}

static func validate_profile(profile: Dictionary) -> bool:
	if str(profile.get("family", "")).is_empty():
		return false
	if typeof(profile.get("accent")) != TYPE_COLOR or typeof(profile.get("secondary")) != TYPE_COLOR:
		return false
	var glow := float(profile.get("glow", -1.0))
	var metallic := float(profile.get("metallic", -1.0))
	return glow >= 0.0 and glow <= 0.6 and metallic >= 0.0 and metallic <= 1.0
