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

func grant_all_armor_stages() -> bool:
 if not enabled:
  return false
 var ok: bool = ArmorSystem.unlock_all_stages()
 if ok:
  _record("解锁全部圣衣阶段")
 gm_action_completed.emit("全部圣衣阶段已解锁" if ok else "圣衣阶段解锁失败：存档写入未完成")
 return ok
func repair_armor() -> bool:
 if not enabled: return false
 var ok: bool = ArmorSystem.repair_all()
 if ok: _record("修复全部圣衣部件")
 gm_action_completed.emit("圣衣修复成功" if ok else "圣衣无需修复或星币不足")
 return ok
func enhance_armor_part(part: String) -> bool:
 if not enabled: return false
 var ok: bool = ArmorSystem.enhance_part(part)
 if ok: _record("强化圣衣部件 "+part)
 gm_action_completed.emit("圣衣部件强化成功" if ok else "强化失败：星币不足或已达上限")
 return ok
func awaken_armor() -> bool:
 if not enabled: return false
 var ok: bool = ArmorSystem.awaken_current()
 if ok: _record("圣衣觉醒")
 gm_action_completed.emit("圣衣觉醒成功" if ok else "当前圣衣不能觉醒或条件不足")
 return ok
func set_skill_level(class_id: String, level: int) -> bool:
 if not enabled: return false
 var ok: bool = SkillSystem.set_skill_level(class_id,level)
 if ok: _record("设置技能等级 "+class_id+" Lv."+str(level))
 gm_action_completed.emit("技能等级设置成功" if ok else "技能等级设置失败")
 return ok

func unlock_all_collections() -> void:
 if not enabled: return
 CollectionSystem.unlock_all()
 _record("解锁全部伙伴宠物坐骑")
 gm_action_completed.emit("伙伴、宠物和坐骑图鉴已全部解锁")
