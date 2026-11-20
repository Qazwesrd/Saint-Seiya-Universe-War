extends RefCounted
class_name ArtAssetAudit
## Reports authored art coverage without treating procedural fallbacks as finished assets.

const MODEL_CANDIDATES := ["model/character.glb", "model/character.gltf", "model/character.tscn"]
const PORTRAIT_CANDIDATES := ["portraits/portrait.png", "portraits/portrait.webp", "portraits/portrait.jpg"]
const ANIMATION_CANDIDATES := ["animations/animation_library.tres", "animations/animation_library.res", "animations/animation_library.glb"]

static func _has_any_file(base_path: String, candidates: Array[String]) -> bool:
	for relative_path in candidates:
		if FileAccess.file_exists(base_path.path_join(relative_path)):
			return true
	return false

static func build_report() -> Dictionary:
	var missing_models: Array[String] = []
	var missing_portraits: Array[String] = []
	var missing_animations: Array[String] = []
	var class_ids: Array[String] = []
	for class_id in CharacterVisualCatalog.PROFILES:
		var base_path := "res://assets/characters/%s" % class_id
		class_ids.append(class_id)
		if not _has_any_file(base_path, MODEL_CANDIDATES):
			missing_models.append(class_id)
		if not _has_any_file(base_path, PORTRAIT_CANDIDATES):
			missing_portraits.append(class_id)
		if not _has_any_file(base_path, ANIMATION_CANDIDATES):
			missing_animations.append(class_id)
	var total := class_ids.size()
	var model_count := total - missing_models.size()
	var portrait_count := total - missing_portraits.size()
	var animation_count := total - missing_animations.size()
	return {
		"class_count": total,
		"model_count": model_count,
		"portrait_count": portrait_count,
		"animation_library_count": animation_count,
		"model_coverage": float(model_count) / maxf(1.0, float(total)),
		"portrait_coverage": float(portrait_count) / maxf(1.0, float(total)),
		"animation_coverage": float(animation_count) / maxf(1.0, float(total)),
		"missing_models": missing_models,
		"missing_portraits": missing_portraits,
		"missing_animations": missing_animations,
		"procedural_fallback_only": model_count == 0
	}
