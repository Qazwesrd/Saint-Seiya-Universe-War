extends Node
signal sanctuary_changed
const FACILITIES := {
 "training_ground":{"name":"修炼场","description":"每日积累修炼经验。","base_cost":300,"exp_per_hour":12},
 "cosmos_well":{"name":"小宇宙泉","description":"每日凝聚小宇宙星币。","base_cost":350,"coins_per_hour":18},
 "armor_forge":{"name":"圣衣工坊","description":"提升圣衣修复与锻造能力。","base_cost":450,"exp_per_hour":5,"coins_per_hour":8}
}
const MAX_FACILITY_LEVEL := 10
const OFFLINE_CAP_HOURS := 24.0
func _state() -> Dictionary:
 var state: Dictionary = RPGState.profile.get("sanctuary",{})
 if state.is_empty():
  state = {"level":1,"facilities":{"training_ground":1,"cosmos_well":1,"armor_forge":1},"last_collect":Time.get_unix_time_from_system(),"visits":0}
  RPGState.profile["sanctuary"] = state
 return state
func get_state() -> Dictionary:
 return _state().duplicate(true)
func get_offline_rewards() -> Dictionary:
 var state := _state()
 var elapsed := maxf(0.0,float(Time.get_unix_time_from_system()-int(state.get("last_collect",Time.get_unix_time_from_system()))))
 var hours := minf(OFFLINE_CAP_HOURS,elapsed/3600.0)
 var facilities: Dictionary = state.get("facilities",{})
 var exp := 0
 var coins := 0
 for facility_id in FACILITIES:
  var level := int(facilities.get(facility_id,1))
  var data: Dictionary = FACILITIES[facility_id]
  exp += int(float(data.get("exp_per_hour",0))*level*hours)
  coins += int(float(data.get("coins_per_hour",0))*level*hours)
 return {"hours":hours,"exp":exp,"coins":coins}
func collect_offline_rewards() -> Dictionary:
 var rewards := get_offline_rewards()
 var state := _state()
 state["last_collect"] = Time.get_unix_time_from_system()
 RPGState.profile["sanctuary"] = state
 if int(rewards.get("exp",0)) > 0: RPGState.add_exp(int(rewards["exp"]))
 if int(rewards.get("coins",0)) > 0: RPGState.add_currency(int(rewards["coins"]))
 _save()
 return rewards
func upgrade_facility(facility_id: String) -> bool:
 if not FACILITIES.has(facility_id): return false
 var state := _state()
 var facilities: Dictionary = state.get("facilities",{})
 var level := int(facilities.get(facility_id,1))
 if level >= MAX_FACILITY_LEVEL: return false
 var cost := int(FACILITIES[facility_id]["base_cost"])*level
 if int(RPGState.profile.get("currency",0)) < cost: return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency",0))-cost
 facilities[facility_id] = level+1
 state["facilities"] = facilities
 RPGState.profile["sanctuary"] = state
 _save()
 return true
func upgrade_sanctuary() -> bool:
 var state := _state()
 var level := int(state.get("level",1))
 if level >= 10: return false
 var cost := level*1500
 if int(RPGState.profile.get("currency",0)) < cost: return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency",0))-cost
 state["level"] = level+1
 RPGState.profile["sanctuary"] = state
 _save()
 return true
func record_visit() -> void:
 var state := _state()
 state["visits"] = int(state.get("visits",0))+1
 RPGState.profile["sanctuary"] = state
 _save()
func _save() -> void:
 RPGState.state_changed.emit()
 RPGState.save_slot(RPGState.active_slot)
 sanctuary_changed.emit()
