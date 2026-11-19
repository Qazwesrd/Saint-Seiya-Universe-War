extends Node
const CLASS_SKILLS := {
 "pegasus":{"name":"天马流星拳","combo":"天马彗星拳","cost":18,"cooldown":3.0,"damage":1.5,"color":Color(0.18,0.72,1.0)},
 "dragon":{"name":"庐山升龙霸","combo":"庐山亢龙霸","cost":22,"cooldown":4.0,"damage":1.9,"color":Color(0.25,0.85,0.55)},
 "cygnus":{"name":"钻石星尘拳","combo":"曙光女神之宽恕","cost":20,"cooldown":3.6,"damage":1.7,"color":Color(0.55,0.85,1.0)},
 "andromeda":{"name":"星云锁链","combo":"星云风暴","cost":20,"cooldown":3.8,"damage":1.65,"color":Color(0.85,0.55,1.0)},
 "phoenix":{"name":"凤翼天翔","combo":"凤凰幻魔拳","cost":24,"cooldown":4.2,"damage":2.0,"color":Color(1.0,0.35,0.18)},
 "sea_dragon":{"name":"黄金三角次元","combo":"海龙怒涛","cost":23,"cooldown":4.0,"damage":1.85,"color":Color(0.2,0.75,0.9)},
 "tenmou":{"name":"天猛重击","combo":"钢铁冲击","cost":21,"cooldown":4.0,"damage":1.8,"color":Color(0.8,0.45,0.25)},
 "lyra":{"name":"弦乐幻境","combo":"死亡交响曲","cost":19,"cooldown":3.7,"damage":1.7,"color":Color(0.9,0.8,0.35)},
 "sea_swallow":{"name":"海燕疾风","combo":"旋流突袭","cost":18,"cooldown":3.2,"damage":1.6,"color":Color(0.25,0.9,0.8)}
}
const ARMOR_STAGES := ["青铜圣衣","白银圣衣","黄金圣衣","海界鳞衣","冥衣","神圣衣","主神圣衣"]
const ARMOR_PARTS := ["头盔","胸甲","护腕","腰甲","腿甲"]
func get_class_skill(class_id: String) -> Dictionary:
 return CLASS_SKILLS.get(class_id,CLASS_SKILLS["pegasus"]).duplicate(true)
func get_armor_catalog() -> Array:
 var result: Array = []
 for stage in ARMOR_STAGES:
  result.append({"stage":stage,"parts":ARMOR_PARTS.duplicate(),"repairable":true,"awakening":stage in ["黄金圣衣","神圣衣","主神圣衣"]})
 return result
