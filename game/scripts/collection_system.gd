extends Node
signal collection_changed
const COMPANIONS := {
 "training_mentor":{"name":"训练场引导灵","description":"陪伴新晋圣斗士进行训练。","bonus_attack":1.0},
 "silver_sentinel":{"name":"白银守护灵","description":"提升战斗中的防护能力。","bonus_defense":2.0},
 "cosmos_phoenix":{"name":"小宇宙凤凰灵","description":"带来额外的小宇宙力量。","bonus_cosmos":10.0}
}
const PETS := {
 "star_pup":{"name":"星灵幼兽","description":"跟随主人探索世界。","bonus_health":5.0},
 "sea_sprite":{"name":"海潮精灵","description":"来自海界的灵性伙伴。","bonus_defense":1.0}
}
const MOUNTS := {
 "nebula_runner":{"name":"星云疾行兽","description":"提升地图探索移动速度。","speed_bonus":0.5},
 "sanctuary_lion":{"name":"圣域守护狮","description":"象征勇气与守护。","speed_bonus":0.8}
}
const ACHIEVEMENTS := {
 "first_victory":{"name":"初次胜利","description":"击败第一名敌人。","target":1},
 "ten_victories":{"name":"训练有素","description":"累计击败 10 名敌人。","target":10},
 "boss_hunter":{"name":"Boss 挑战者","description":"击败一名 Boss。","target":1},
 "veteran":{"name":"百战勇士","description":"累计击败 100 名敌人。","target":100}
}
func _ensure_state() -> Dictionary:
 var data: Dictionary = RPGState.profile.get("collection_state",{})
 if data.is_empty():
  data = {"companions":[],"pets":[],"mounts":[],"active_companion":"","active_pet":"","active_mount":"","enemy_defeats":0,"boss_defeats":0,"achievements":{},"claimed_achievements":[]}
  RPGState.profile["collection_state"] = data
 return data
func get_state() -> Dictionary:
 return _ensure_state().duplicate(true)
func unlock_all() -> void:
 var data := _ensure_state()
 data["companions"] = COMPANIONS.keys()
 data["pets"] = PETS.keys()
 data["mounts"] = MOUNTS.keys()
 if str(data.get("active_companion","")) == "": data["active_companion"] = "training_mentor"
 if str(data.get("active_pet","")) == "": data["active_pet"] = "star_pup"
 if str(data.get("active_mount","")) == "": data["active_mount"] = "nebula_runner"
 RPGState.profile["collection_state"] = data
 _save()
func unlock_companion(item_id: String) -> bool:
 if not COMPANIONS.has(item_id): return false
 var data := _ensure_state()
 var owned: Array = data.get("companions",[])
 if item_id in owned: return false
 owned.append(item_id)
 data["companions"] = owned
 if str(data.get("active_companion","")) == "": data["active_companion"] = item_id
 RPGState.profile["collection_state"] = data
 _save()
 return true
func unlock_pet(item_id: String) -> bool:
 if not PETS.has(item_id): return false
 var data := _ensure_state()
 var owned: Array = data.get("pets",[])
 if item_id in owned: return false
 owned.append(item_id)
 data["pets"] = owned
 if str(data.get("active_pet","")) == "": data["active_pet"] = item_id
 RPGState.profile["collection_state"] = data
 _save()
 return true
func unlock_mount(item_id: String) -> bool:
 if not MOUNTS.has(item_id): return false
 var data := _ensure_state()
 var owned: Array = data.get("mounts",[])
 if item_id in owned: return false
 owned.append(item_id)
 data["mounts"] = owned
 if str(data.get("active_mount","")) == "": data["active_mount"] = item_id
 RPGState.profile["collection_state"] = data
 _save()
 return true
func equip(kind: String, item_id: String) -> bool:
 var data := _ensure_state()
 var list_key := ""
 var active_key := ""
 if kind == "companion": list_key = "companions"; active_key = "active_companion"
 elif kind == "pet": list_key = "pets"; active_key = "active_pet"
 elif kind == "mount": list_key = "mounts"; active_key = "active_mount"
 else: return false
 if not (item_id in data.get(list_key,[])): return false
 data[active_key] = item_id
 RPGState.profile["collection_state"] = data
 _save()
 return true
func record_enemy_defeat(is_boss: bool) -> void:
 var data := _ensure_state()
 data["enemy_defeats"] = int(data.get("enemy_defeats",0))+1
 if is_boss: data["boss_defeats"] = int(data.get("boss_defeats",0))+1
 var achievements: Dictionary = data.get("achievements",{})
 if int(data["enemy_defeats"]) >= 1: achievements["first_victory"] = true
 if int(data["enemy_defeats"]) >= 10: achievements["ten_victories"] = true
 if int(data["enemy_defeats"]) >= 100: achievements["veteran"] = true
 if int(data["boss_defeats"]) >= 1: achievements["boss_hunter"] = true
 data["achievements"] = achievements
 RPGState.profile["collection_state"] = data
 _save()
func get_bonus_stats() -> Dictionary:
 var data := _ensure_state()
 var result := {"attack":0.0,"defense":0.0,"max_health":0.0,"max_cosmos":0.0,"speed":0.0}
 var companion_id := str(data.get("active_companion",""))
 var pet_id := str(data.get("active_pet",""))
 var mount_id := str(data.get("active_mount",""))
 if COMPANIONS.has(companion_id):
  result["attack"] += float(COMPANIONS[companion_id].get("bonus_attack",0))
  result["defense"] += float(COMPANIONS[companion_id].get("bonus_defense",0))
  result["max_cosmos"] += float(COMPANIONS[companion_id].get("bonus_cosmos",0))
 if PETS.has(pet_id):
  result["max_health"] += float(PETS[pet_id].get("bonus_health",0))
  result["defense"] += float(PETS[pet_id].get("bonus_defense",0))
 if MOUNTS.has(mount_id): result["speed"] += float(MOUNTS[mount_id].get("speed_bonus",0))
 return result
func _save() -> void:
 RPGState.state_changed.emit()
 RPGState.save_slot(RPGState.active_slot)
 collection_changed.emit()

func claim_achievement(achievement_id: String) -> bool:
 if not ACHIEVEMENTS.has(achievement_id): return false
 var data := _ensure_state()
 var achievements: Dictionary = data.get("achievements",{})
 var claimed: Array = data.get("claimed_achievements",[])
 if not bool(achievements.get(achievement_id,false)) or achievement_id in claimed: return false
 var rewards := {"first_victory":{"coins":100,"exp":80},"ten_victories":{"coins":500,"exp":300},"boss_hunter":{"coins":300,"exp":250},"veteran":{"coins":2000,"exp":1500}}
 var reward: Dictionary = rewards.get(achievement_id,{})
 claimed.append(achievement_id)
 data["claimed_achievements"] = claimed
 RPGState.profile["collection_state"] = data
 RPGState.add_currency(int(reward.get("coins",0)))
 RPGState.add_exp(int(reward.get("exp",0)))
 _save()
 return true
