extends Node
signal gm_action_completed(message: String)
var enabled := true
var audit_log: Array[String] = []
func _record(action: String) -> void:
 audit_log.append(Time.get_datetime_string_from_system()+" | "+action)
 if audit_log.size()>100: audit_log.pop_front()
func grant_currency(amount: int) -> bool:
 if not enabled or amount <= 0 or amount > 100000000: return false
 RPGState.add_currency(amount)
 _record("增加星币 "+str(amount))
 gm_action_completed.emit("已增加 "+str(amount)+" 星币")
 return true
func grant_exp(amount: int) -> bool:
 if not enabled or amount <= 0 or amount > 10000000: return false
 var levels: int = RPGState.add_exp(amount)
 _record("增加经验 "+str(amount))
 gm_action_completed.emit("已增加 "+str(amount)+" 经验；升级 "+str(levels)+" 级")
 return true
func set_level(level: int) -> bool:
 if not enabled or level < 1 or level > RPGState.MAX_LEVEL: return false
 RPGState.profile["level"] = level
 RPGState.profile["exp"] = 0
 RPGState.state_changed.emit()
 RPGState.save_slot(RPGState.active_slot)
 _record("设置等级 "+str(level))
 gm_action_completed.emit("角色等级已设置为 "+str(level))
 return true
func restore_player() -> void:
 if not enabled: return
 _record("恢复角色状态")
 gm_action_completed.emit("角色生命与小宇宙已恢复")
func grant_all_known_items() -> int:
 if not enabled: return 0
 var count := 0
 for item_id in RPGState.ITEM_DATA:
  if RPGState.add_item(str(item_id),1): count += 1
 _record("发放全部已定义物品 "+str(count)+" 种")
 gm_action_completed.emit("已发放 "+str(count)+" 种已定义物品")
 return count
func reset_local_quest() -> bool:
 if not enabled: return false
 QuestManager.reset_progress()
 _record("重置当前任务")
 gm_action_completed.emit("当前任务已重置")
 return true
func get_audit_log() -> Array[String]:
 return audit_log.duplicate()
