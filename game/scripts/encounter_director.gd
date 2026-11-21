extends Node
## Drives ordered offline encounter waves; story progression remains owned by CampaignManager.
signal wave_changed(state: Dictionary)
signal encounter_completed(encounter_id: String)

var encounter_id := ""
var waves: Array[Dictionary] = []
var wave_index := -1
var living_enemies := 0
var active := false

func get_dark_faction_trial_waves() -> Array[Dictionary]:
	return [
		{"spawns":[{"archetype_id":"dark_saint_scout","count":2,"position":Vector3(-3,0.1,-5)},{"archetype_id":"dark_saint_raider","count":1,"position":Vector3(3,0.1,-5)}]},
		{"spawns":[{"archetype_id":"dark_saint_raider","count":2,"position":Vector3(-3,0.1,-6)},{"archetype_id":"dark_saint_elite","count":1,"position":Vector3(3,0.1,-6)}]},
		{"spawns":[{"archetype_id":"dark_saint_captain","count":1,"position":Vector3(-2,0.1,-7)},{"archetype_id":"dark_black_knight_champion","count":1,"boss":true,"position":Vector3(2,0.1,-8)}]}
	]

func start(new_encounter_id: String, wave_definitions: Array[Dictionary]) -> bool:
	if new_encounter_id.is_empty() or wave_definitions.is_empty() or active:
		return false
	for wave in wave_definitions:
		if not wave.has("spawns") or typeof(wave["spawns"]) != TYPE_ARRAY or wave["spawns"].is_empty():
			return false
		for spawn in wave["spawns"]:
			if typeof(spawn) != TYPE_DICTIONARY:
				return false
			var archetype_id := str(spawn.get("archetype_id", ""))
			var spawn_count := int(spawn.get("count", 1))
			if archetype_id.is_empty() or not EnemyDatabase.has_archetype(archetype_id):
				return false
			if spawn_count < 1 or spawn_count > 20:
				return false
			if spawn.has("position") and typeof(spawn["position"]) != TYPE_VECTOR3:
				return false
	encounter_id = new_encounter_id
	waves = wave_definitions.duplicate(true)
	wave_index = -1
	living_enemies = 0
	active = true
	return not advance_wave().is_empty()

func advance_wave() -> Dictionary:
	if not active or living_enemies > 0:
		return {}
	wave_index += 1
	if wave_index >= waves.size():
		var finished_id := encounter_id
		active = false
		encounter_id = ""
		waves.clear()
		wave_index = -1
		encounter_completed.emit(finished_id)
		wave_changed.emit(get_state())
		return {}
	var wave: Dictionary = waves[wave_index].duplicate(true)
	wave["wave_number"] = wave_index + 1
	wave["wave_total"] = waves.size()
	wave_changed.emit(get_state())
	return wave

func register_enemy(count: int = 1) -> void:
	if active and count > 0:
		living_enemies += count
		wave_changed.emit(get_state())

func report_enemy_defeated() -> void:
	if not active:
		return
	living_enemies = maxi(0, living_enemies - 1)
	wave_changed.emit(get_state())

func get_current_wave() -> Dictionary:
	if not active or wave_index < 0 or wave_index >= waves.size():
		return {}
	var result: Dictionary = waves[wave_index].duplicate(true)
	result["wave_number"] = wave_index + 1
	result["wave_total"] = waves.size()
	return result

func get_state() -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"wave_number": wave_index + 1 if active else 0,
		"wave_total": waves.size(),
		"living_enemies": living_enemies,
		"active": active
	}

func cancel() -> void:
	var cancelled_id := encounter_id
	active = false
	encounter_id = ""
	waves.clear()
	wave_index = -1
	living_enemies = 0
	wave_changed.emit(get_state())
