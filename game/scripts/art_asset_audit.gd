extends RefCounted
class_name ArtAssetAudit
## Audits authored art delivery separately from procedural runtime fallbacks.

const CHARACTER_MODEL_CANDIDATES := ["model/character.glb", "model/character.gltf", "model/character.tscn"]
const PORTRAIT_CANDIDATES := ["portraits/portrait.png", "portraits/portrait.webp", "portraits/portrait.jpg"]
const ANIMATION_CANDIDATES := ["animations/animation_library.tres", "animations/animation_library.res", "animations/animation_library.glb"]
const ARMOR_MODEL_CANDIDATES := ["model/armor.glb", "model/armor.gltf", "model/armor.tscn"]
const ICON_CANDIDATES := ["icons/icon.png", "icons/icon.webp", "icons/icon.jpg"]
const ENEMY_MODEL_CANDIDATES := ["model/enemy.glb", "model/enemy.gltf", "model/enemy.tscn"]
const ENEMY_PORTRAIT_CANDIDATES := ["portraits/portrait.png", "portraits/portrait.webp", "portraits/portrait.jpg"]
const CHAPTER_THEMES := ["galaxy_wars", "sanctuary_twelve_houses", "asgard", "poseidon", "hades", "heaven", "original_final"]
const SKILL_ELEMENTS := ["fire", "ice", "lightning", "light", "dark", "water", "wind", "time", "soul", "sound", "cosmos"]

static func _has_any_file(base_path: String, candidates: Array) -> bool:
	for relative_path in candidates:
		if FileAccess.file_exists(base_path.path_join(relative_path)):
			return true
	return false

static func _coverage(found: int, total: int) -> float:
	return float(found) / maxf(1.0, float(total))

static func build_report() -> Dictionary:
	var missing_character_models: Array[String] = []
	var missing_character_portraits: Array[String] = []
	var missing_character_animations: Array[String] = []
	var class_ids: Array[String] = []
	for class_id in CharacterVisualCatalog.PROFILES:
		var base_path := "res://assets/characters/%s" % class_id
		class_ids.append(class_id)
		if not _has_any_file(base_path, CHARACTER_MODEL_CANDIDATES):
			missing_character_models.append(class_id)
		if not _has_any_file(base_path, PORTRAIT_CANDIDATES):
			missing_character_portraits.append(class_id)
		if not _has_any_file(base_path, ANIMATION_CANDIDATES):
			missing_character_animations.append(class_id)

	var missing_armor_models: Array[String] = []
	var missing_armor_icons: Array[String] = []
	var missing_armor_manifests: Array[String] = []
	var equipment_catalog: Array = EquipmentDatabase.get_catalog()
	for equipment in equipment_catalog:
		var equipment_id := str(equipment.get("id", ""))
		var armor_path := "res://assets/armors/%s" % equipment_id
		if not _has_any_file(armor_path, ARMOR_MODEL_CANDIDATES):
			missing_armor_models.append(equipment_id)
		if not _has_any_file(armor_path, ICON_CANDIDATES):
			missing_armor_icons.append(equipment_id)
		if not FileAccess.file_exists(armor_path.path_join("manifest.json")):
			missing_armor_manifests.append(equipment_id)

	var missing_enemy_models: Array[String] = []
	var missing_enemy_portraits: Array[String] = []
	for enemy_id in EnemyDatabase.ARCHETYPES:
		var enemy_path := "res://assets/enemies/%s" % str(enemy_id)
		if not _has_any_file(enemy_path, ENEMY_MODEL_CANDIDATES):
			missing_enemy_models.append(str(enemy_id))
		if not _has_any_file(enemy_path, ENEMY_PORTRAIT_CANDIDATES):
			missing_enemy_portraits.append(str(enemy_id))

	var missing_chapter_scenes: Array[String] = []
	for theme_id in CHAPTER_THEMES:
		var theme_path := "res://assets/environments/%s" % theme_id
		if not _has_any_file(theme_path, ["environment.tscn", "environment.glb", "environment.gltf"]):
			missing_chapter_scenes.append(theme_id)

	var missing_skill_effects: Array[String] = []
	for element_id in SKILL_ELEMENTS:
		var effect_path := "res://assets/vfx/%s" % element_id
		if not _has_any_file(effect_path, ["effect.tscn", "effect.glb", "effect.gltf"]):
			missing_skill_effects.append(element_id)

	var class_total := class_ids.size()
	var equipment_total := equipment_catalog.size()
	var enemy_total := EnemyDatabase.ARCHETYPES.size()
	var skill_total := 0
	for class_id in class_ids:
		skill_total += SkillSystem.get_ability_catalog(class_id).size()

	var authored_asset_total := class_total * 3 + equipment_total * 3 + enemy_total * 2 + CHAPTER_THEMES.size() + SKILL_ELEMENTS.size()
	var authored_asset_missing := missing_character_models.size() + missing_character_portraits.size() + missing_character_animations.size() + missing_armor_models.size() + missing_armor_icons.size() + missing_armor_manifests.size() + missing_enemy_models.size() + missing_enemy_portraits.size() + missing_chapter_scenes.size() + missing_skill_effects.size()
	var authored_asset_found := authored_asset_total - authored_asset_missing

	return {
		"authored_asset_total": authored_asset_total,
		"authored_asset_found": authored_asset_found,
		"authored_asset_missing": authored_asset_missing,
		"authored_asset_coverage": _coverage(authored_asset_found, authored_asset_total),
		"class_count": class_total,
		"model_count": class_total - missing_character_models.size(),
		"portrait_count": class_total - missing_character_portraits.size(),
		"animation_library_count": class_total - missing_character_animations.size(),
		"model_coverage": _coverage(class_total - missing_character_models.size(), class_total),
		"portrait_coverage": _coverage(class_total - missing_character_portraits.size(), class_total),
		"animation_coverage": _coverage(class_total - missing_character_animations.size(), class_total),
		"missing_models": missing_character_models,
		"missing_portraits": missing_character_portraits,
		"missing_animations": missing_character_animations,
		"equipment_count": equipment_total,
		"armor_model_count": equipment_total - missing_armor_models.size(),
		"armor_icon_count": equipment_total - missing_armor_icons.size(),
		"armor_manifest_count": equipment_total - missing_armor_manifests.size(),
		"armor_model_coverage": _coverage(equipment_total - missing_armor_models.size(), equipment_total),
		"armor_icon_coverage": _coverage(equipment_total - missing_armor_icons.size(), equipment_total),
		"armor_manifest_coverage": _coverage(equipment_total - missing_armor_manifests.size(), equipment_total),
		"missing_armor_models": missing_armor_models,
		"missing_armor_icons": missing_armor_icons,
		"missing_armor_manifests": missing_armor_manifests,
		"enemy_count": enemy_total,
		"enemy_model_count": enemy_total - missing_enemy_models.size(),
		"enemy_portrait_count": enemy_total - missing_enemy_portraits.size(),
		"enemy_model_coverage": _coverage(enemy_total - missing_enemy_models.size(), enemy_total),
		"enemy_portrait_coverage": _coverage(enemy_total - missing_enemy_portraits.size(), enemy_total),
		"missing_enemy_models": missing_enemy_models,
		"missing_enemy_portraits": missing_enemy_portraits,
		"chapter_count": CHAPTER_THEMES.size(),
		"chapter_scene_count": CHAPTER_THEMES.size() - missing_chapter_scenes.size(),
		"chapter_scene_coverage": _coverage(CHAPTER_THEMES.size() - missing_chapter_scenes.size(), CHAPTER_THEMES.size()),
		"missing_chapter_scenes": missing_chapter_scenes,
		"skill_count": skill_total,
		"skill_element_count": SKILL_ELEMENTS.size(),
		"skill_effect_count": SKILL_ELEMENTS.size() - missing_skill_effects.size(),
		"skill_effect_coverage": _coverage(SKILL_ELEMENTS.size() - missing_skill_effects.size(), SKILL_ELEMENTS.size()),
		"missing_skill_effects": missing_skill_effects,
		"procedural_fallback_only": (class_total - missing_character_models.size()) == 0,
		"authored_art_complete": missing_character_models.is_empty() and missing_character_portraits.is_empty() and missing_character_animations.is_empty() and missing_armor_models.is_empty() and missing_armor_icons.is_empty() and missing_armor_manifests.is_empty() and missing_enemy_models.is_empty() and missing_enemy_portraits.is_empty() and missing_chapter_scenes.is_empty() and missing_skill_effects.is_empty()
	}
