extends Node
const CLASS_SKILLS := {
 "pegasus":{"name":"天马流星拳","combo":"天马彗星拳","cost":18,"cooldown":3.0,"damage":1.5,"combo_damage":2.5,"color":Color(0.18,0.72,1.0)},
 "dragon":{"name":"庐山升龙霸","combo":"庐山亢龙霸","cost":22,"cooldown":4.0,"damage":1.9,"combo_damage":2.8,"color":Color(0.25,0.85,0.55)},
 "cygnus":{"name":"钻石星尘拳","combo":"曙光女神之宽恕","cost":20,"cooldown":3.6,"damage":1.7,"combo_damage":2.6,"color":Color(0.55,0.85,1.0)},
 "andromeda":{"name":"星云锁链","combo":"星云风暴","cost":20,"cooldown":3.8,"damage":1.65,"combo_damage":2.6,"color":Color(0.85,0.55,1.0)},
 "phoenix":{"name":"凤翼天翔","combo":"凤凰幻魔拳","cost":24,"cooldown":4.2,"damage":2.0,"combo_damage":3.0,"color":Color(1.0,0.35,0.18)},
 "sea_dragon":{"name":"黄金三角次元","combo":"海龙怒涛","cost":23,"cooldown":4.0,"damage":1.85,"combo_damage":2.8,"color":Color(0.2,0.75,0.9)},
 "tenmou":{"name":"天猛重击","combo":"钢铁冲击","cost":21,"cooldown":4.0,"damage":1.8,"combo_damage":2.7,"color":Color(0.8,0.45,0.25)},
 "lyra":{"name":"弦乐幻境","combo":"死亡交响曲","cost":19,"cooldown":3.7,"damage":1.7,"combo_damage":2.6,"color":Color(0.9,0.8,0.35)},
 "sea_swallow":{"name":"海燕疾风","combo":"旋流突袭","cost":18,"cooldown":3.2,"damage":1.6,"combo_damage":2.5,"color":Color(0.25,0.9,0.8)}
}
const ARMOR_STAGES := ["青铜圣衣","白银圣衣","黄金圣衣","海界鳞衣","冥衣","神圣衣","主神圣衣"]
const ARMOR_PARTS := ["头盔","胸甲","护腕","腰甲","腿甲"]
func get_class_skill(class_id: String) -> Dictionary:
 return CLASS_SKILLS.get(class_id,CLASS_SKILLS["pegasus"]).duplicate(true)
func get_skill_level(class_id: String) -> int:
 var levels: Dictionary = RPGState.profile.get("skill_levels",{})
 return clampi(int(levels.get(class_id,1)),1,10)
func upgrade_skill(class_id: String) -> bool:
 if not CLASS_SKILLS.has(class_id): return false
 var levels: Dictionary = RPGState.profile.get("skill_levels",{})
 var level := get_skill_level(class_id)
 if level >= 10: return false
 var cost := level*350
 if int(RPGState.profile.get("currency",0)) < cost: return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency",0))-cost
 levels[class_id] = level+1
 RPGState.profile["skill_levels"] = levels
 RPGState.state_changed.emit()
 RPGState.save_slot(RPGState.active_slot)
 return true
func set_skill_level(class_id: String, level: int) -> bool:
 if not CLASS_SKILLS.has(class_id) or level < 1 or level > 10: return false
 var levels: Dictionary = RPGState.profile.get("skill_levels",{})
 levels[class_id] = level
 RPGState.profile["skill_levels"] = levels
 RPGState.state_changed.emit()
 RPGState.save_slot(RPGState.active_slot)
 return true
func get_armor_catalog() -> Array:
 var result: Array = []
 for stage in ARMOR_STAGES:
  result.append({"stage":stage,"parts":ARMOR_PARTS.duplicate(),"repairable":true,"awakening":stage in ["黄金圣衣","神圣衣","主神圣衣"]})
 return result
