extends Node
const STAGES := {
 "bronze":{"name":"青铜圣衣","attack":1.0,"defense":2.0,"hp":8.0},
 "silver":{"name":"白银圣衣","attack":2.0,"defense":4.0,"hp":16.0},
 "gold":{"name":"黄金圣衣","attack":4.0,"defense":7.0,"hp":28.0},
 "sea_scale":{"name":"海界鳞衣","attack":4.0,"defense":6.0,"hp":24.0},
 "surplice":{"name":"冥衣","attack":5.0,"defense":6.0,"hp":22.0},
 "god_cloth":{"name":"神圣衣","attack":7.0,"defense":9.0,"hp":40.0},
 "god_armor":{"name":"主神圣衣","attack":9.0,"defense":12.0,"hp":55.0}
}
const PARTS := ["head","chest","arms","waist","legs"]
const PART_NAMES := {"head":"头盔","chest":"胸甲","arms":"护腕","waist":"腰甲","legs":"腿甲"}
var damage_ticks := 0
func _ensure_data() -> Dictionary:
 var data: Dictionary = RPGState.profile.get("armor_state", {})
 if data.is_empty():
  data = {"unlocked_stages":["bronze"],"current_stage":"bronze","durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100},"levels":{},"awakened":false}
  RPGState.profile["armor_state"] = data
 return data
func get_stage_ids() -> Array:
 return STAGES.keys()
func get_state() -> Dictionary:
 return _ensure_data().duplicate(true)
func get_current_stage_name() -> String:
 var data := _ensure_data()
 return str(STAGES.get(str(data.get("current_stage","bronze")),STAGES["bronze"])["name"])
func unlock_all_stages() -> bool:
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 data["unlocked_stages"] = STAGES.keys()
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func equip_stage(stage_id: String) -> bool:
 if not STAGES.has(stage_id):
  return false
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 if not (stage_id in data.get("unlocked_stages", [])):
  return false
 data["current_stage"] = stage_id
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func repair_all() -> bool:
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var durability: Dictionary = data.get("durability", {}).duplicate(true)
 var missing := 0
 for part in PARTS:
  missing += 100 - int(durability.get(part, 100))
 if missing <= 0:
  return false
 var cost := missing * 2
 if int(RPGState.profile.get("currency", 0)) < cost:
  return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
 for part in PARTS:
  durability[part] = 100
 data["durability"] = durability
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func damage_random_part(amount: int = 8) -> void:
 damage_ticks += 1
 if damage_ticks % 5 != 0:
  return
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var durability: Dictionary = data.get("durability", {}).duplicate(true)
 var part: String = PARTS[randi_range(0, PARTS.size() - 1)]
 durability[part] = maxi(0, int(durability.get(part, 100)) - maxi(1, amount))
 data["durability"] = durability
 RPGState.profile["armor_state"] = data
 _commit(previous)
func enhance_part(part: String) -> bool:
 if not (part in PARTS):
  return false
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var levels: Dictionary = data.get("levels", {}).duplicate(true)
 var level := int(levels.get(part, 0))
 if level >= 10:
  return false
 var cost := (level + 1) * 180
 if int(RPGState.profile.get("currency", 0)) < cost:
  return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
 levels[part] = level + 1
 data["levels"] = levels
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func awaken_current() -> bool:
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var stage := str(data.get("current_stage", "bronze"))
 if not ["gold", "god_cloth", "god_armor"].has(stage) or bool(data.get("awakened", false)):
  return false
 var cost := 5000 if stage == "gold" else 12000
 if int(RPGState.profile.get("currency", 0)) < cost:
  return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
 data["awakened"] = true
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func get_bonus_stats() -> Dictionary:
 var data := _ensure_data()
 var stage_id := str(data.get("current_stage","bronze"))
 var base: Dictionary = STAGES.get(stage_id,STAGES["bronze"])
 var levels: Dictionary = data.get("levels",{})
 var durability: Dictionary = data.get("durability",{})
 var condition := 0.0
 for part in PARTS: condition += float(durability.get(part,100))/500.0
 var level_sum := 0
 for part in PARTS: level_sum += int(levels.get(part,0))
 var awaken := 1.25 if bool(data.get("awakened",false)) else 1.0
 return {"attack":(float(base["attack"])+float(level_sum))*condition*awaken,"defense":(float(base["defense"])+float(level_sum)*0.8)*condition*awaken,"max_health":float(base["hp"])*condition*awaken}
func _commit(previous: Dictionary) -> bool:
 if RPGState.save_slot(RPGState.active_slot):
  RPGState.state_changed.emit()
  return true
 RPGState.profile = previous
 return false
