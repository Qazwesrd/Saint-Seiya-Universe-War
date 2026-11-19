extends Node
signal state_changed
const MAX_LEVEL := 100
const CLASS_DATA := {
 "pegasus":{"name":"天马座","hp":110,"attack":14,"defense":8,"speed":12,"starter":"pegasus_bracer"},
 "dragon":{"name":"天龙座","hp":135,"attack":11,"defense":14,"speed":8,"starter":"dragon_shield"},
 "cygnus":{"name":"白鸟座","hp":105,"attack":14,"defense":9,"speed":11,"starter":"cygnus_claw"},
 "andromeda":{"name":"仙女座","hp":100,"attack":12,"defense":10,"speed":13,"starter":"andromeda_chain"},
 "phoenix":{"name":"凤凰座","hp":115,"attack":16,"defense":8,"speed":10,"starter":"phoenix_fist"},
 "sea_dragon":{"name":"海龙","hp":120,"attack":15,"defense":10,"speed":9,"starter":"sea_dragon_scale"},
 "tenmou":{"name":"天猛","hp":125,"attack":13,"defense":12,"speed":8,"starter":"tenmou_armor"},
 "lyra":{"name":"天琴","hp":100,"attack":15,"defense":8,"speed":14,"starter":"lyra_harp"},
 "sea_swallow":{"name":"海燕","hp":108,"attack":13,"defense":10,"speed":13,"starter":"swallow_scale"}
}
const ITEM_DATA := {
 "pegasus_bracer":{"name":"天马青铜护腕","slot":"arms","attack":3,"defense":1,"price":0},
 "dragon_shield":{"name":"天龙青铜护盾","slot":"arms","attack":1,"defense":4,"price":0},
 "cygnus_claw":{"name":"白鸟青铜护腕","slot":"arms","attack":3,"defense":1,"price":0},
 "andromeda_chain":{"name":"仙女青铜锁链","slot":"arms","attack":2,"defense":2,"price":0},
 "phoenix_fist":{"name":"凤凰青铜护腕","slot":"arms","attack":4,"defense":0,"price":0},
 "sea_dragon_scale":{"name":"海龙鳞甲护腕","slot":"arms","attack":3,"defense":2,"price":0},
 "tenmou_armor":{"name":"天猛青铜护腕","slot":"arms","attack":2,"defense":3,"price":0},
 "lyra_harp":{"name":"天琴战具","slot":"arms","attack":4,"defense":0,"price":0},
 "swallow_scale":{"name":"海燕青铜护腕","slot":"arms","attack":2,"defense":2,"price":0},
 "bronze_helmet":{"name":"青铜头盔","slot":"head","attack":0,"defense":3,"price":120},
 "bronze_chest":{"name":"青铜胸甲","slot":"chest","attack":0,"defense":6,"price":220},
 "bronze_greaves":{"name":"青铜腿甲","slot":"legs","attack":1,"defense":3,"price":160},
 "cosmos_potion":{"name":"小宇宙恢复药剂","slot":"consumable","attack":0,"defense":0,"price":45}
}
var active_slot := 1
var profile: Dictionary = {}
func _ready() -> void:
 _ensure_profile()
 if FileAccess.file_exists(_save_path(active_slot)):
  load_slot(active_slot)
 else:
  save_slot(active_slot)
func _ensure_profile() -> void:
 if not profile.is_empty(): return
 profile = {"version":1,"class_id":"pegasus","level":1,"exp":0,"currency":500,"cosmos_level":1,"inventory":{"cosmos_potion":3},"equipment":{"head":"","chest":"","arms":"pegasus_bracer","legs":""},"equipment_levels":{},"created_at":Time.get_datetime_string_from_system()}
func get_class_list() -> Array:
 var result: Array = []
 for class_id in CLASS_DATA:
  result.append({"id":class_id,"name":CLASS_DATA[class_id]["name"],"stats":CLASS_DATA[class_id].duplicate(true)})
 return result
func select_class(class_id: String) -> bool:
 if not CLASS_DATA.has(class_id):
  return false
 var equipment: Dictionary = profile.get("equipment",{})
 var inventory: Dictionary = profile.get("inventory",{})
 var old_arm: String = str(equipment.get("arms",""))
 if old_arm != "":
  inventory[old_arm] = int(inventory.get(old_arm,0)) + 1
 var starter: String = str(CLASS_DATA[class_id]["starter"])
 equipment["arms"] = starter
 profile["class_id"] = class_id
 profile["inventory"] = inventory
 profile["equipment"] = equipment
 _emit_change()
 save_slot(active_slot)
 return true
func get_combat_stats() -> Dictionary:
 var base: Dictionary = CLASS_DATA.get(str(profile.get("class_id","pegasus")),CLASS_DATA["pegasus"])
 var level: int = int(profile.get("level",1))
 var stats := {"max_health":float(base["hp"]+(level-1)*8),"attack":float(base["attack"]+(level-1)*2),"defense":float(base["defense"]+(level-1)),"speed":float(base["speed"]),"max_cosmos":float(100 + (int(profile.get("cosmos_level",1))-1)*10)}
 for slot in profile.get("equipment",{}):
  var item_id: String = str(profile["equipment"][slot])
  if ITEM_DATA.has(item_id):
   stats["attack"] += float(ITEM_DATA[item_id].get("attack",0))
   stats["defense"] += float(ITEM_DATA[item_id].get("defense",0))\n   var enhance_level: int = int(profile.get("equipment_levels",{}).get(item_id,0))\n   stats["attack"] += float(enhance_level) * 1.5\n   stats["defense"] += float(enhance_level) * 1.5
 return stats
func exp_to_next_level() -> int:
 return 100+(int(profile.get("level",1))-1)*65
func add_exp(amount: int) -> int:
 if amount <= 0: return 0
 var gained_levels := 0
 profile["exp"] = int(profile.get("exp",0))+amount
 while int(profile.get("level",1)) < MAX_LEVEL and int(profile["exp"]) >= exp_to_next_level():
  profile["exp"] = int(profile["exp"])-exp_to_next_level()
  profile["level"] = int(profile["level"])+1
  gained_levels += 1
 _emit_change()
 save_slot(active_slot)
 return gained_levels
func add_currency(amount: int) -> void:
 profile["currency"] = maxi(0,int(profile.get("currency",0))+amount)
 _emit_change()
 save_slot(active_slot)
func add_item(item_id: String, quantity: int = 1) -> bool:
 if not ITEM_DATA.has(item_id) or quantity <= 0: return false
 var inventory: Dictionary = profile.get("inventory",{})
 inventory[item_id] = int(inventory.get(item_id,0))+quantity
 profile["inventory"] = inventory
 _emit_change()
 save_slot(active_slot)
 return true
func equip_item(item_id: String) -> bool:
 if not ITEM_DATA.has(item_id): return false
 var inventory: Dictionary = profile.get("inventory",{})
 if int(inventory.get(item_id,0)) <= 0: return false
 var slot: String = str(ITEM_DATA[item_id]["slot"])
 if slot == "consumable": return false
 var equipment: Dictionary = profile.get("equipment",{})
 var old_id: String = str(equipment.get(slot,""))
 if old_id != "": inventory[old_id] = int(inventory.get(old_id,0))+1
 inventory[item_id] = int(inventory[item_id])-1
 if int(inventory[item_id]) <= 0: inventory.erase(item_id)
 equipment[slot] = item_id
 profile["inventory"] = inventory
 profile["equipment"] = equipment
 _emit_change()
 save_slot(active_slot)
 return true
func enhance_equipment(slot: String) -> bool:
 var equipment: Dictionary = profile.get("equipment",{})
 var item_id: String = str(equipment.get(slot,""))
 if item_id == "" or not ITEM_DATA.has(item_id):
  return false
 var levels: Dictionary = profile.get("equipment_levels",{})
 var current_level: int = int(levels.get(item_id,0))
 if current_level >= 10:
  return false
 var cost: int = (current_level + 1) * 100
 if int(profile.get("currency",0)) < cost:
  return false
 profile["currency"] = int(profile["currency"]) - cost
 levels[item_id] = current_level + 1
 profile["equipment_levels"] = levels
 _emit_change()
 save_slot(active_slot)
 return true
func upgrade_cosmos() -> bool:
 var level: int = int(profile.get("cosmos_level",1))
 var cost := level*250
 if level >= 20 or int(profile.get("currency",0)) < cost: return false
 profile["currency"] = int(profile["currency"])-cost
 profile["cosmos_level"] = level+1
 _emit_change()
 save_slot(active_slot)
 return true
func buy_item(item_id: String) -> bool:
 if not ITEM_DATA.has(item_id): return false
 var price: int = int(ITEM_DATA[item_id].get("price",0))
 if price <= 0 or int(profile.get("currency",0)) < price: return false
 profile["currency"] = int(profile["currency"])-price
 var inventory: Dictionary = profile.get("inventory",{})
 inventory[item_id] = int(inventory.get(item_id,0))+1
 profile["inventory"] = inventory
 _emit_change()
 save_slot(active_slot)
 return true
func use_item(item_id: String) -> bool:
 var inventory: Dictionary = profile.get("inventory",{})
 if item_id != "cosmos_potion" or int(inventory.get(item_id,0)) <= 0: return false
 inventory[item_id] = int(inventory[item_id])-1
 if int(inventory[item_id]) <= 0: inventory.erase(item_id)
 profile["inventory"] = inventory
 _emit_change()
 save_slot(active_slot)
 return true
func _save_path(slot: int) -> String:
 return "user://save_slot_%d.json" % clampi(slot,1,3)
func save_slot(slot: int) -> bool:
 if slot < 1 or slot > 3: return false
 var file := FileAccess.open(_save_path(slot),FileAccess.WRITE)
 if file == null: return false
 file.store_string(JSON.stringify(profile))
 file.close()
 active_slot = slot
 return true
func load_slot(slot: int) -> bool:
 if slot < 1 or slot > 3 or not FileAccess.file_exists(_save_path(slot)): return false
 var file := FileAccess.open(_save_path(slot),FileAccess.READ)
 if file == null: return false
 var parsed: Variant = JSON.parse_string(file.get_as_text())
 file.close()
 if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version",0)) != 1: return false
 profile = parsed
 active_slot = slot
 _emit_change()
 return true
func backup_slot(slot: int) -> bool:
 if slot < 1 or slot > 3 or not FileAccess.file_exists(_save_path(slot)): return false
 var source := FileAccess.open(_save_path(slot),FileAccess.READ)
 if source == null: return false
 var contents := source.get_as_text()
 source.close()
 var target := FileAccess.open("user://backup_slot_%d.json" % slot,FileAccess.WRITE)
 if target == null: return false
 target.store_string(contents)
 target.close()
 return true
func restore_backup(slot: int) -> bool:
 if slot < 1 or slot > 3 or not FileAccess.file_exists("user://backup_slot_%d.json" % slot): return false
 var source := FileAccess.open("user://backup_slot_%d.json" % slot,FileAccess.READ)
 if source == null: return false
 var parsed: Variant = JSON.parse_string(source.get_as_text())
 source.close()
 if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version",0)) != 1: return false
 var target := FileAccess.open(_save_path(slot),FileAccess.WRITE)
 if target == null: return false
 target.store_string(JSON.stringify(parsed))
 target.close()
 return load_slot(slot)
func _emit_change() -> void:
 state_changed.emit()
