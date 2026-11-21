extends Node
## Seven-region offline world map, chapter-gated travel and landmark discovery.
signal world_map_changed

const Catalog = preload("res://scripts/world_exploration_catalog.gd")
const PROFILE_KEY := "world_exploration"
var active_region_id := "galaxy_wars"
var visited_regions: Array[String] = ["galaxy_wars"]
var discovered_landmarks: Array[String] = []

func _ready() -> void:
	if not RPGState.slot_loaded.is_connected(_on_slot_loaded):
		RPGState.slot_loaded.connect(_on_slot_loaded)
	if not CampaignManager.campaign_changed.is_connected(_on_campaign_changed):
		CampaignManager.campaign_changed.connect(_on_campaign_changed)
	load_profile()

func _on_slot_loaded(_slot: int) -> void:
	load_profile()

func _on_campaign_changed() -> void:
	var active_chapter: Dictionary = CampaignManager.get_active_chapter()
	var chapter_id := str(active_chapter.get("id", ""))
	if not chapter_id.is_empty() and _is_region_unlocked(chapter_id) and active_region_id != chapter_id:
		active_region_id = chapter_id
		if not visited_regions.has(chapter_id):
			visited_regions.append(chapter_id)
		_persist()

func load_profile() -> void:
	var saved: Variant = RPGState.profile.get(PROFILE_KEY, {})
	active_region_id = "galaxy_wars"
	visited_regions = ["galaxy_wars"]
	discovered_landmarks = []
	if typeof(saved) == TYPE_DICTIONARY:
		active_region_id = str(saved.get("active_region_id", "galaxy_wars"))
		visited_regions.clear()
		for region_id in saved.get("visited_regions", ["galaxy_wars"]):
			if not visited_regions.has(str(region_id)) and _region_exists(str(region_id)):
				visited_regions.append(str(region_id))
		discovered_landmarks = []
		for landmark_id in saved.get("discovered_landmarks", []):
			if not discovered_landmarks.has(str(landmark_id)):
				discovered_landmarks.append(str(landmark_id))
	if not _region_exists(active_region_id) or not _is_region_unlocked(active_region_id):
		var active_chapter: Dictionary = CampaignManager.get_active_chapter()
		active_region_id = str(active_chapter.get("id", "galaxy_wars"))
	if not visited_regions.has(active_region_id):
		visited_regions.append(active_region_id)
	world_map_changed.emit()

func get_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var chapter_states: Dictionary = {}
	for state in CampaignManager.get_chapter_overview():
		chapter_states[str(state.get("id", ""))] = state
	for region in Catalog.get_regions():
		var region_id := str(region.get("id", ""))
		var chapter_state: Dictionary = chapter_states.get(region_id, {})
		var copy: Dictionary = region.duplicate(true)
		copy["unlocked"] = bool(chapter_state.get("unlocked", false))
		copy["completed"] = bool(chapter_state.get("completed", false))
		copy["active"] = region_id == active_region_id
		copy["visited"] = visited_regions.has(region_id)
		var discovered_count := 0
		for landmark in region.get("landmarks", []):
			if discovered_landmarks.has(str(landmark.get("id", ""))):
				discovered_count += 1
		copy["discovered_count"] = discovered_count
		copy["landmark_count"] = region.get("landmarks", []).size()
		result.append(copy)
	return result

func get_region(region_id: String) -> Dictionary:
	for region in Catalog.get_regions():
		if str(region.get("id", "")) == region_id:
			return region.duplicate(true)
	return {}

func travel_to_region(region_id: String) -> Dictionary:
	if not _region_exists(region_id):
		return {"success": false, "reason": "目标区域不存在"}
	if not _is_region_unlocked(region_id):
		return {"success": false, "reason": "该篇章尚未解锁，请先推进主线剧情"}
	var previous := _snapshot()
	active_region_id = region_id
	if not visited_regions.has(region_id):
		visited_regions.append(region_id)
	if not _persist():
		_restore(previous)
		return {"success": false, "reason": "地图进度保存失败，请重试"}
	world_map_changed.emit()
	return {"success": true, "region": get_region(region_id)}

func discover_landmark(landmark_id: String) -> bool:
	if discovered_landmarks.has(landmark_id):
		return false
	var region := get_region(active_region_id)
	var valid := false
	for landmark in region.get("landmarks", []):
		if str(landmark.get("id", "")) == landmark_id:
			valid = true
			break
	if not valid:
		return false
	var previous := _snapshot()
	discovered_landmarks.append(landmark_id)
	if not _persist():
		_restore(previous)
		return false
	world_map_changed.emit()
	return true

func _is_region_unlocked(region_id: String) -> bool:
	for chapter_state in CampaignManager.get_chapter_overview():
		if str(chapter_state.get("id", "")) == region_id:
			return bool(chapter_state.get("unlocked", false))
	return false

func _region_exists(region_id: String) -> bool:
	for region in Catalog.get_regions():
		if str(region.get("id", "")) == region_id:
			return true
	return false

func _snapshot() -> Dictionary:
	return {"active_region_id": active_region_id, "visited_regions": visited_regions.duplicate(), "discovered_landmarks": discovered_landmarks.duplicate()}

func _restore(snapshot: Dictionary) -> void:
	active_region_id = str(snapshot.get("active_region_id", "galaxy_wars"))
	visited_regions = snapshot.get("visited_regions", ["galaxy_wars"]).duplicate()
	discovered_landmarks = snapshot.get("discovered_landmarks", []).duplicate()

func _persist() -> bool:
	RPGState.profile[PROFILE_KEY] = _snapshot()
	if not RPGState.save_slot(RPGState.active_slot):
		SystemHealthManager.report_error("save", "世界地图进度保存失败", "slot=%d" % RPGState.active_slot)
		return false
	world_map_changed.emit()
	return true
