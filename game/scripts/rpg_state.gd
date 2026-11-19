extends Node
signal state_changed
signal slot_loaded(slot: int)
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
 "sea_swallow":{"name":"海燕","hp":108,"attack":13,"defense":10,"speed":13,"starter":"swallow_scale"},
 "tenkishi":{"name":"天斗士","hp":520,"attack":82,"defense":76,"speed":34,"starter":"heavenly_glory","tier":"天斗士","faction":"天界·阿尔忒弥斯阵营","canon_status":"天斗士与天衣Glory属于天界篇设定","unlock_level":45,"unlock_condition":"角色达到45级并完成天界试炼"},
 "apollo":{"name":"阿波罗","hp":720,"attack":118,"defense":92,"speed":28,"starter":"apollo_divine_relic","tier":"神明","unlock_level":70,"unlock_condition":"完成对应神明篇章与神级试炼"},
 "athena":{"name":"雅典娜","hp":860,"attack":98,"defense":135,"speed":25,"starter":"athena_divine_relic","tier":"神明","unlock_level":70,"unlock_condition":"完成对应神明篇章与神级试炼"},
 "hades":{"name":"哈迪斯","hp":800,"attack":125,"defense":108,"speed":26,"starter":"hades_divine_relic","tier":"神明","unlock_level":70,"unlock_condition":"完成对应神明篇章与神级试炼"},
 "poseidon":{"name":"波塞冬","hp":820,"attack":116,"defense":112,"speed":27,"starter":"poseidon_divine_relic","tier":"神明","unlock_level":70,"unlock_condition":"完成对应神明篇章与神级试炼"},
 "zeus":{"name":"宙斯","hp":900,"attack":150,"defense":140,"speed":28,"starter":"zeus_divine_relic","tier":"神明","faction":"奥林匹斯神王","canon_status":"原作提及，未正式正面登场","unlock_level":70,"unlock_condition":"角色达到70级并完成宙斯篇章试炼"},
 "artemis":{"name":"阿尔忒弥斯","hp":790,"attack":118,"defense":120,"speed":31,"starter":"artemis_divine_relic","tier":"神明","faction":"月之女神","canon_status":"天界篇相关作品登场","unlock_level":70,"unlock_condition":"角色达到70级并完成阿尔忒弥斯篇章试炼"},
 "hypnos":{"name":"修普诺斯","hp":810,"attack":112,"defense":132,"speed":25,"starter":"hypnos_divine_relic","tier":"神明","faction":"睡神","canon_status":"冥王篇登场","unlock_level":70,"unlock_condition":"角色达到70级并完成修普诺斯篇章试炼"},
 "thanatos":{"name":"达纳托斯","hp":820,"attack":138,"defense":116,"speed":29,"starter":"thanatos_divine_relic","tier":"神明","faction":"死神","canon_status":"冥王篇登场","unlock_level":70,"unlock_condition":"角色达到70级并完成达纳托斯篇章试炼"},
 "odin":{"name":"奥丁","hp":920,"attack":130,"defense":142,"speed":27,"starter":"odin_divine_relic","tier":"神明","faction":"北欧主神","canon_status":"北欧篇登场","unlock_level":70,"unlock_condition":"角色达到70级并完成奥丁篇章试炼"},
 "ares":{"name":"阿瑞斯","hp":860,"attack":155,"defense":112,"speed":32,"starter":"ares_divine_relic","tier":"神明","faction":"战神","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成阿瑞斯篇章试炼"},
 "eris":{"name":"厄里斯","hp":750,"attack":130,"defense":108,"speed":30,"starter":"eris_divine_relic","tier":"神明","faction":"纷争女神","canon_status":"剧场版《邪神厄里斯》","unlock_level":70,"unlock_condition":"角色达到70级并完成厄里斯篇章试炼"},
 "abel":{"name":"亚伯","hp":840,"attack":148,"defense":124,"speed":30,"starter":"abel_divine_relic","tier":"神明","faction":"太阳神","canon_status":"剧场版《真红少年传说》","unlock_level":70,"unlock_condition":"角色达到70级并完成亚伯篇章试炼"},
 "lucifer":{"name":"路西法","hp":870,"attack":150,"defense":118,"speed":33,"starter":"lucifer_divine_relic","tier":"神明","faction":"堕天使之王","canon_status":"剧场版《最终圣战的战士们》","unlock_level":70,"unlock_condition":"角色达到70级并完成路西法篇章试炼"},
 "saturn":{"name":"萨图恩","hp":960,"attack":158,"defense":148,"speed":28,"starter":"saturn_divine_relic","tier":"神明","faction":"时间之神","canon_status":"《圣斗士星矢Ω》","unlock_level":70,"unlock_condition":"角色达到70级并完成萨图恩篇章试炼"},
 "pallas":{"name":"帕拉斯","hp":800,"attack":126,"defense":120,"speed":32,"starter":"pallas_divine_relic","tier":"神明","faction":"爱与战争女神","canon_status":"《圣斗士星矢Ω》","unlock_level":70,"unlock_condition":"角色达到70级并完成帕拉斯篇章试炼"},
 "chronos":{"name":"柯罗诺斯","hp":980,"attack":162,"defense":155,"speed":27,"starter":"chronos_divine_relic","tier":"神明","faction":"时间神","canon_status":"Episode G 系列；与泰坦克洛诺斯区分","unlock_level":70,"unlock_condition":"角色达到70级并完成柯罗诺斯篇章试炼"},
 "hera":{"name":"赫拉","hp":840,"attack":120,"defense":145,"speed":25,"starter":"hera_divine_relic","tier":"神明","faction":"天后","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成赫拉篇章试炼"},
 "demeter":{"name":"德墨忒尔","hp":860,"attack":110,"defense":140,"speed":24,"starter":"demeter_divine_relic","tier":"神明","faction":"丰饶女神","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成德墨忒尔篇章试炼"},
 "hestia":{"name":"赫斯提亚","hp":870,"attack":116,"defense":152,"speed":23,"starter":"hestia_divine_relic","tier":"神明","faction":"炉灶女神","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成赫斯提亚篇章试炼"},
 "hermes":{"name":"赫尔墨斯","hp":760,"attack":132,"defense":106,"speed":39,"starter":"hermes_divine_relic","tier":"神明","faction":"神使","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成赫尔墨斯篇章试炼"},
 "hephaestus":{"name":"赫淮斯托斯","hp":950,"attack":136,"defense":158,"speed":21,"starter":"hephaestus_divine_relic","tier":"神明","faction":"锻造之神","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成赫淮斯托斯篇章试炼"},
 "aphrodite":{"name":"阿佛洛狄忒","hp":770,"attack":122,"defense":114,"speed":31,"starter":"aphrodite_divine_relic","tier":"神明","faction":"爱与美之神","canon_status":"希腊神话扩展职业","unlock_level":70,"unlock_condition":"角色达到70级并完成阿佛洛狄忒篇章试炼"}
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
 profile = {"version":1,"class_id":"pegasus","level":1,"exp":0,"currency":500,"cosmos_level":1,"cosmos_levels":{"pegasus":1},"inventory":{"cosmos_potion":3},"equipment":{"head":"","chest":"","arms":"pegasus_bracer","legs":""},"equipment_levels":{},"skill_points":3,"learned_skills":{"pegasus":["pegasus_skill_1"]},"skill_branches":{},"skill_slots":{"pegasus":["pegasus_skill_1","","",""]},"created_at":Time.get_datetime_string_from_system(),"quest_progress":{},"campaign_progress":{}}
func get_class_list() -> Array:
 var result: Array = []
 for class_id in CLASS_DATA:
  result.append({"id":class_id,"name":CLASS_DATA[class_id]["name"],"stats":CLASS_DATA[class_id].duplicate(true)})
 return result
func select_class(class_id: String) -> bool:
 if not CLASS_DATA.has(class_id):
  return false
 var class_data: Dictionary = CLASS_DATA[class_id]
 if str(class_data.get("tier", "")) in ["神明", "天斗士"] and int(profile.get("level", 1)) < int(class_data.get("unlock_level", 70 if str(class_data.get("tier", "")) == "神明" else 45)):
  return false
 if str(profile.get("class_id","pegasus")) == class_id:
  return true
 var equipment: Dictionary = profile.get("equipment",{})
 var inventory: Dictionary = profile.get("inventory",{})
 var old_arm: String = str(equipment.get("arms",""))
 if old_arm != "":
  inventory[old_arm] = int(inventory.get(old_arm,0)) + 1
 var starter: String = str(CLASS_DATA[class_id]["starter"])
 equipment["arms"] = starter
 profile["class_id"] = class_id
 var cosmos_levels: Dictionary = profile.get("cosmos_levels", {})
 if not cosmos_levels.has(class_id): cosmos_levels[class_id] = 21 if str(CLASS_DATA[class_id].get("tier", "")) in ["神明", "天斗士"] else 1
 profile["cosmos_levels"] = cosmos_levels
 profile["cosmos_level"] = int(cosmos_levels[class_id])
 var learned: Dictionary = profile.get("learned_skills", {})
 if not learned.has(class_id): learned[class_id] = [class_id + "_skill_1"]
 profile["learned_skills"] = learned
 var slots: Dictionary = profile.get("skill_slots", {})
 if not slots.has(class_id): slots[class_id] = [class_id + "_skill_1", "", "", ""]
 profile["skill_slots"] = slots
 profile["inventory"] = inventory
 profile["equipment"] = equipment
 _emit_change()
 save_slot(active_slot)
 return true
func get_cosmos_profile() -> Dictionary:
 var class_id := str(profile.get("class_id", "pegasus"))
 var base: Dictionary = CLASS_DATA.get(class_id, CLASS_DATA["pegasus"])
 var divine := str(base.get("tier", "")) == "神明"
 var heavenly := str(base.get("tier", "")) == "天斗士"
 var levels: Dictionary = profile.get("cosmos_levels", {})
 var level := int(levels.get(class_id, profile.get("cosmos_level", 1)))
 if divine or heavenly: level = maxi(21, level)
 var max_level := 100 if divine else (50 if heavenly else 20)
 var rank := ""
 if divine:
  rank = "神格觉醒" if level <= 40 else "神域掌控" if level <= 60 else "主神神格" if level <= 80 else "至高神格"
 elif heavenly:
  rank = "天衣觉醒" if level <= 30 else "天域掌控" if level <= 40 else "天使神格"
 else:
  rank = "初识小宇宙" if level < 7 else "第七感" if level < 14 else "第八感" if level < 19 else "究极小宇宙"
 return {"level":level,"max_level":max_level,"divine":divine,"heavenly":heavenly,"rank":rank,"max_cosmos":float(260+(level-21)*18) if divine else (float(180+(level-21)*12) if heavenly else float(100+(level-1)*10)),"attack_bonus":float(maxi(0,level-21)*3.5) if divine else (float(maxi(0,level-21)*2.0) if heavenly else float((level-1)*0.7)),"defense_bonus":float(maxi(0,level-21)*2.5) if divine else (float(maxi(0,level-21)*1.5) if heavenly else float((level-1)*0.5)),"health_bonus":float(maxi(0,level-21)*14) if divine else (float(maxi(0,level-21)*8) if heavenly else float((level-1)*4)),"regen_rate":8.5 if divine else (5.5 if heavenly else 3.0),"skill_power_multiplier":float(maxi(0,level-21)*0.004) if divine else (float(maxi(0,level-21)*0.0025) if heavenly else float((level-1)*0.002)),"upgrade_cost":level*1500 if divine else (level*800 if heavenly else level*250)}
func get_combat_stats() -> Dictionary:
 var cosmos_data: Dictionary = get_cosmos_profile()
 var base: Dictionary = CLASS_DATA.get(str(profile.get("class_id","pegasus")),CLASS_DATA["pegasus"])
 var level: int = int(profile.get("level",1))
 var divine_tier := bool(cosmos_data.get("divine", false))
 var stats := {"max_health":float(base["hp"]+(level-1)*(30 if divine_tier else 8))+float(cosmos_data.get("health_bonus",0.0)),"attack":float(base["attack"]+(level-1)*(8 if divine_tier else 2))+float(cosmos_data.get("attack_bonus",0.0)),"defense":float(base["defense"]+(level-1)*(5 if divine_tier else 1))+float(cosmos_data.get("defense_bonus",0.0)),"speed":float(base["speed"]),"max_cosmos":float(cosmos_data.get("max_cosmos",100.0))}
 for slot in profile.get("equipment",{}):
  var item_id: String = str(profile["equipment"][slot])
  if ITEM_DATA.has(item_id):
   stats["attack"] += float(ITEM_DATA[item_id].get("attack",0))
   stats["defense"] += float(ITEM_DATA[item_id].get("defense",0))
   var enhance_level: int = int(profile.get("equipment_levels",{}).get(item_id,0))
   stats["attack"] += float(enhance_level) * 1.5
   stats["defense"] += float(enhance_level) * 1.5
 var relic_bonus: Dictionary = EquipmentDatabase.get_bonus_stats()
 stats["attack"] += float(relic_bonus.get("attack", 0.0))
 stats["defense"] += float(relic_bonus.get("defense", 0.0))
 stats["max_health"] += float(relic_bonus.get("max_health", 0.0))
 var armor_bonus: Dictionary = ArmorSystem.get_bonus_stats()
 stats["attack"] += float(armor_bonus.get("attack",0.0))
 stats["defense"] += float(armor_bonus.get("defense",0.0))
 stats["max_health"] += float(armor_bonus.get("max_health",0.0))
 var affix_bonus: Dictionary = EquipmentAffixManager.get_bonus_stats()
 stats["attack"] += float(affix_bonus.get("attack", 0.0))
 stats["defense"] += float(affix_bonus.get("defense", 0.0))
 stats["max_health"] += float(affix_bonus.get("max_health", 0.0))
 stats["speed"] += float(affix_bonus.get("speed", 0.0))
 stats["max_cosmos"] += float(affix_bonus.get("max_cosmos", 0.0))
 var collection_bonus: Dictionary = CollectionSystem.get_bonus_stats()
 stats["attack"] += float(collection_bonus.get("attack",0.0))
 stats["defense"] += float(collection_bonus.get("defense",0.0))
 stats["max_health"] += float(collection_bonus.get("max_health",0.0))
 stats["max_cosmos"] += float(collection_bonus.get("max_cosmos",0.0))
 stats["speed"] += float(collection_bonus.get("speed",0.0))
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
  profile["skill_points"] = int(profile.get("skill_points", 0)) + 1
  gained_levels += 1
 _emit_change()
 save_slot(active_slot)
 return gained_levels
func add_currency(amount: int) -> void:
 profile["currency"] = maxi(0,int(profile.get("currency",0))+amount)
 _emit_change()
 save_slot(active_slot)
func add_item(item_id: String, quantity: int = 1) -> bool:
  return add_items({item_id: quantity})

func add_items(items: Dictionary) -> bool:
	if items.is_empty():
		return false
	for item_id in items.keys():
		if not ITEM_DATA.has(str(item_id)) or int(items[item_id]) <= 0:
			return false
	var previous_inventory: Dictionary = profile.get("inventory", {}).duplicate(true)
	var inventory: Dictionary = previous_inventory.duplicate(true)
	for item_id in items.keys():
		inventory[str(item_id)] = int(inventory.get(str(item_id), 0)) + int(items[item_id])
	profile["inventory"] = inventory
	if not save_slot(active_slot):
		profile["inventory"] = previous_inventory
		return false
	_emit_change()
	EventBus.inventory_changed.emit(inventory.duplicate(true))
	return true
func equip_item(item_id: String) -> bool:
 if not ITEM_DATA.has(item_id):
  return false
 var previous_inventory: Dictionary = profile.get("inventory", {}).duplicate(true)
 var previous_equipment: Dictionary = profile.get("equipment", {}).duplicate(true)
 if int(previous_inventory.get(item_id, 0)) <= 0:
  return false
 var slot: String = str(ITEM_DATA[item_id].get("slot", ""))
 if slot == "" or slot == "consumable":
  return false
 var inventory: Dictionary = previous_inventory.duplicate(true)
 var equipment: Dictionary = previous_equipment.duplicate(true)
 var old_id := str(equipment.get(slot, ""))
 if old_id != "":
  inventory[old_id] = int(inventory.get(old_id, 0)) + 1
 inventory[item_id] = int(inventory[item_id]) - 1
 if int(inventory[item_id]) <= 0:
  inventory.erase(item_id)
 equipment[slot] = item_id
 profile["inventory"] = inventory
 profile["equipment"] = equipment
 if not save_slot(active_slot):
  profile["inventory"] = previous_inventory
  profile["equipment"] = previous_equipment
  return false
 _emit_change()
 EventBus.inventory_changed.emit(inventory.duplicate(true))
 EventBus.equipment_changed.emit(equipment.duplicate(true))
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
 var class_id := str(profile.get("class_id", "pegasus"))
 var cosmos_data: Dictionary = get_cosmos_profile()
 var level := int(cosmos_data.get("level", 1))
 var cost := int(cosmos_data.get("upgrade_cost", level * 250))
 if level >= int(cosmos_data.get("max_level", 20)) or int(profile.get("currency", 0)) < cost: return false
 profile["currency"] = int(profile.get("currency", 0)) - cost
 var levels: Dictionary = profile.get("cosmos_levels", {})
 levels[class_id] = level + 1
 profile["cosmos_levels"] = levels
 profile["cosmos_level"] = level + 1
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
 profile["cosmos_levels"] = profile.get("cosmos_levels", {str(profile.get("class_id", "pegasus")): int(profile.get("cosmos_level", 1))})
 profile["skill_points"] = int(profile.get("skill_points", 3))
 profile["learned_skills"] = profile.get("learned_skills", {str(profile.get("class_id", "pegasus")): [str(profile.get("class_id", "pegasus")) + "_skill_1"]})
 profile["skill_branches"] = profile.get("skill_branches", {})
 profile["skill_slots"] = profile.get("skill_slots", {str(profile.get("class_id", "pegasus")): [str(profile.get("class_id", "pegasus")) + "_skill_1", "", "", ""]})
 active_slot = slot
 slot_loaded.emit(slot)
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
 EventBus.player_profile_changed.emit(profile.duplicate(true))


func has_slot(slot: int) -> bool:
 return slot >= 1 and slot <= 3 and FileAccess.file_exists(_save_path(slot))

func get_slot_summary(slot: int) -> Dictionary:
 if not has_slot(slot):
  return {"slot": slot, "exists": false, "label": "空存档槽"}
 var file := FileAccess.open(_save_path(slot), FileAccess.READ)
 if file == null:
  return {"slot": slot, "exists": false, "label": "存档无法读取"}
 var parsed: Variant = JSON.parse_string(file.get_as_text())
 file.close()
 if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != 1:
  return {"slot": slot, "exists": true, "valid": false, "label": "存档损坏或版本不兼容"}
 var class_id := str(parsed.get("class_id", "pegasus"))
 var class_data: Dictionary = CLASS_DATA.get(class_id, CLASS_DATA["pegasus"])
 return {
  "slot": slot,
  "exists": true,
  "valid": true,
  "class_id": class_id,
  "class_name": str(class_data.get("name", class_id)),
  "level": int(parsed.get("level", 1)),
  "currency": int(parsed.get("currency", 0)),
  "saved_at": str(parsed.get("updated_at", parsed.get("created_at", "未知"))),
  "label": "%s · Lv.%d · 星币 %d" % [str(class_data.get("name", class_id)), int(parsed.get("level", 1)), int(parsed.get("currency", 0))]
 }

func create_new_slot(slot: int) -> bool:
 if slot < 1 or slot > 3 or has_slot(slot):
  return false
 var previous_profile: Dictionary = profile.duplicate(true)
 var previous_slot: int = active_slot
 profile = {}
 _ensure_profile()
 if not save_slot(slot):
  profile = previous_profile
  active_slot = previous_slot
  return false
 slot_loaded.emit(slot)
 _emit_change()
 return true

func delete_slot(slot: int) -> bool:
 if not has_slot(slot):
  return false
 if not backup_slot(slot):
  return false
 var result := DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path(slot))) == OK
 if result and active_slot == slot:
  profile = {}
  _ensure_profile()
  slot_loaded.emit(active_slot)
  _emit_change()
 return result

func has_backup_slot(slot: int) -> bool:
 return slot >= 1 and slot <= 3 and FileAccess.file_exists("user://backup_slot_%d.json" % slot)
