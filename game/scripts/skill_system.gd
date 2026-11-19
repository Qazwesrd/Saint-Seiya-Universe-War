extends Node

# Per-class combat identity. Values tune the existing hit-query combat system;
# animation clips and authored character rigs are integrated in a later asset phase.
const CLASS_SKILLS := {
    "pegasus": {
        "class_name": "天马座", "style": "高速近身连击",
        "basic_attacks": ["流星突拳", "疾风追击", "天马终结拳"],
        "name": "天马流星拳", "combo": "天马彗星拳", "burst_name": "天马回旋碎击拳",
        "description": "高速连续拳击，适合快速压制单体敌人。",
        "cost": 18, "cooldown": 3.0, "damage": 1.5, "combo_damage": 2.5,
        "range": 7.0, "cone": 150.0, "knockback": 3.5, "launch": 1.2, "stagger": 0.55,
        "combo_range": 8.5, "combo_knockback": 9.0, "combo_launch": 3.8,
        "burst_range": 5.0, "burst_knockback": 12.0, "burst_launch": 4.5,
        "color": Color(0.18, 0.72, 1.0)
    },
    "dragon": {
        "class_name": "天龙座", "style": "强力破防与挑空",
        "basic_attacks": ["龙爪重拳", "升龙追击", "庐山挑空击"],
        "name": "庐山升龙霸", "combo": "庐山亢龙霸", "burst_name": "庐山百龙霸",
        "description": "重击破防并将敌人挑向空中，连招爆发力强。",
        "cost": 22, "cooldown": 4.0, "damage": 1.9, "combo_damage": 2.8,
        "range": 6.2, "cone": 125.0, "knockback": 5.0, "launch": 3.6, "stagger": 0.72,
        "combo_range": 7.8, "combo_knockback": 11.0, "combo_launch": 5.0,
        "burst_range": 6.5, "burst_knockback": 13.0, "burst_launch": 5.5,
        "color": Color(0.25, 0.85, 0.55)
    },
    "cygnus": {
        "class_name": "白鸟座", "style": "中距离冰霜范围控制",
        "basic_attacks": ["冰晶直拳", "寒风连打", "冰霜终结击"],
        "name": "钻石星尘拳", "combo": "曙光女神之宽恕", "burst_name": "极光雷电击",
        "description": "冰霜冲击覆盖中距离区域，强调控制与稳定输出。",
        "cost": 20, "cooldown": 3.6, "damage": 1.7, "combo_damage": 2.6,
        "range": 8.0, "cone": 170.0, "knockback": 2.8, "launch": 0.8, "stagger": 0.9,
        "combo_range": 9.0, "combo_knockback": 8.0, "combo_launch": 2.0,
        "burst_range": 7.0, "burst_knockback": 10.0, "burst_launch": 3.0,
        "color": Color(0.55, 0.85, 1.0)
    },
    "andromeda": {
        "class_name": "仙女座", "style": "长距离锁链牵制",
        "basic_attacks": ["锁链刺击", "回旋链击", "星云锁链终结"],
        "name": "星云锁链", "combo": "星云风暴", "burst_name": "星云电光链",
        "description": "锁链延伸攻击距离，适合牵制多个方向的敌人。",
        "cost": 20, "cooldown": 3.8, "damage": 1.65, "combo_damage": 2.6,
        "range": 9.5, "cone": 115.0, "knockback": 2.5, "launch": 0.4, "stagger": 0.8,
        "combo_range": 10.0, "combo_knockback": 7.5, "combo_launch": 1.5,
        "burst_range": 8.5, "burst_knockback": 9.0, "burst_launch": 2.5,
        "color": Color(0.85, 0.55, 1.0)
    },
    "phoenix": {
        "class_name": "凤凰座", "style": "高爆发火焰突袭",
        "basic_attacks": ["烈焰突拳", "凤凰追击", "不死鸟重击"],
        "name": "凤翼天翔", "combo": "凤凰幻魔拳", "burst_name": "不死鸟烈焰冲击",
        "description": "高伤害火焰冲击，擅长爆发输出与强力终结。",
        "cost": 24, "cooldown": 4.2, "damage": 2.0, "combo_damage": 3.0,
        "range": 7.2, "cone": 145.0, "knockback": 6.0, "launch": 1.8, "stagger": 0.65,
        "combo_range": 8.5, "combo_knockback": 12.0, "combo_launch": 4.0,
        "burst_range": 6.8, "burst_knockback": 15.0, "burst_launch": 5.0,
        "color": Color(1.0, 0.35, 0.18)
    },
    "sea_dragon": {
        "class_name": "海龙", "style": "次元远程与范围冲击",
        "basic_attacks": ["海流拳", "次元追击", "海龙冲击"],
        "name": "黄金三角次元", "combo": "海龙怒涛", "burst_name": "深海次元风暴",
        "description": "次元能量攻击覆盖较大区域，兼顾距离与范围伤害。",
        "cost": 23, "cooldown": 4.0, "damage": 1.85, "combo_damage": 2.8,
        "range": 9.0, "cone": 165.0, "knockback": 4.0, "launch": 1.4, "stagger": 0.7,
        "combo_range": 10.0, "combo_knockback": 10.0, "combo_launch": 3.5,
        "burst_range": 8.0, "burst_knockback": 14.0, "burst_launch": 4.2,
        "color": Color(0.2, 0.75, 0.9)
    },
    "tenmou": {
        "class_name": "天猛", "style": "重型近战压制",
        "basic_attacks": ["钢铁重拳", "猛击追打", "天猛碎地击"],
        "name": "天猛重击", "combo": "钢铁冲击", "burst_name": "天猛陨星破",
        "description": "重型打击拥有较强硬直和击退，攻击节奏偏沉稳。",
        "cost": 21, "cooldown": 4.0, "damage": 1.8, "combo_damage": 2.7,
        "range": 5.8, "cone": 110.0, "knockback": 7.0, "launch": 1.0, "stagger": 0.95,
        "combo_range": 7.0, "combo_knockback": 13.0, "combo_launch": 3.0,
        "burst_range": 6.0, "burst_knockback": 16.0, "burst_launch": 4.0,
        "color": Color(0.8, 0.45, 0.25)
    },
    "lyra": {
        "class_name": "天琴", "style": "音波中距离牵制",
        "basic_attacks": ["音刃拨弦", "旋律连击", "终曲震荡"],
        "name": "弦乐幻境", "combo": "死亡交响曲", "burst_name": "黄金弦乐终章",
        "description": "音波攻击拥有较宽范围与较长硬直，适合控场。",
        "cost": 19, "cooldown": 3.7, "damage": 1.7, "combo_damage": 2.6,
        "range": 8.8, "cone": 180.0, "knockback": 1.8, "launch": 0.2, "stagger": 1.05,
        "combo_range": 9.5, "combo_knockback": 6.0, "combo_launch": 1.0,
        "burst_range": 8.0, "burst_knockback": 8.0, "burst_launch": 2.0,
        "color": Color(0.9, 0.8, 0.35)
    },
    "sea_swallow": {
        "class_name": "海燕", "style": "高速机动突袭",
        "basic_attacks": ["旋流快拳", "疾风连刺", "海燕回旋击"],
        "name": "海燕疾风", "combo": "旋流突袭", "burst_name": "海燕龙卷风",
        "description": "高速短冷却攻击，适合快速切入和连续追击。",
        "cost": 18, "cooldown": 3.2, "damage": 1.6, "combo_damage": 2.5,
        "range": 7.8, "cone": 135.0, "knockback": 3.0, "launch": 1.0, "stagger": 0.5,
        "combo_range": 9.0, "combo_knockback": 8.5, "combo_launch": 3.0,
        "burst_range": 6.0, "burst_knockback": 10.0, "burst_launch": 3.8,
        "color": Color(0.25, 0.9, 0.8)
    }
}

const ARMOR_STAGES := ["青铜圣衣", "白银圣衣", "黄金圣衣", "海界鳞衣", "冥衣", "神圣衣", "主神圣衣"]
const ARMOR_PARTS := ["头盔", "胸甲", "护腕", "腰甲", "腿甲"]

func get_class_skill(class_id: String) -> Dictionary:
    return CLASS_SKILLS.get(class_id, CLASS_SKILLS["pegasus"]).duplicate(true)

func get_class_skill_catalog() -> Array:
    var result: Array = []
    for class_id in CLASS_SKILLS:
        var entry: Dictionary = CLASS_SKILLS[class_id].duplicate(true)
        entry["id"] = class_id
        result.append(entry)
    return result

func get_skill_level(class_id: String) -> int:
    var levels: Dictionary = RPGState.profile.get("skill_levels", {})
    return clampi(int(levels.get(class_id, 1)), 1, 10)

func upgrade_skill(class_id: String) -> bool:
    if not CLASS_SKILLS.has(class_id):
        return false
    var levels: Dictionary = RPGState.profile.get("skill_levels", {})
    var level := get_skill_level(class_id)
    if level >= 10:
        return false
    var cost := level * 350
    if int(RPGState.profile.get("currency", 0)) < cost:
        return false
    RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
    levels[class_id] = level + 1
    RPGState.profile["skill_levels"] = levels
    RPGState.state_changed.emit()
    RPGState.save_slot(RPGState.active_slot)
    return true

func set_skill_level(class_id: String, level: int) -> bool:
    if not CLASS_SKILLS.has(class_id) or level < 1 or level > 10:
        return false
    var levels: Dictionary = RPGState.profile.get("skill_levels", {})
    levels[class_id] = level
    RPGState.profile["skill_levels"] = levels
    RPGState.state_changed.emit()
    RPGState.save_slot(RPGState.active_slot)
    return true

func get_armor_catalog() -> Array:
    var result: Array = []
    for stage in ARMOR_STAGES:
        result.append({"stage": stage, "parts": ARMOR_PARTS.duplicate(), "repairable": true, "awakening": stage in ["黄金圣衣", "神圣衣", "主神圣衣"]})
    return result
