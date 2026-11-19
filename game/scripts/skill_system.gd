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
        "color": Color(0.18, 0.72, 1.0),
        "abilities": [
            {"id":"pegasus_skill_1","name":"流星突袭","description":"高速突进并连续打击，命中后短暂减速目标。","type":"突进","role":"单体","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"pegasus_skill_2","name":"星辰乱坠","description":"跃起后向前方区域连续轰击，适合追击与清场。","type":"范围","role":"群体","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"pegasus_skill_3","name":"流星爆裂拳","description":"短时间内快速打出多段拳击，积累斗志。","type":"连击","role":"单体","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"pegasus_skill_4","name":"回旋碎击拳","description":"抓取近身目标并重击摔落，造成倒地硬直。","type":"投技","role":"控制","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"pegasus_skill_5","name":"裂风踢","description":"旋身踢击周围敌人并获得短暂移速提升。","type":"机动","role":"群体","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"pegasus_skill_6","name":"闪影流星拳","description":"高速残影突袭，终段造成强力击倒。","type":"终结","role":"单体","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"不屈斗志","description":"连续命中积累斗志；斗志满时下一次技能伤害提高。","effect":"combo_damage","value":0.08},
        "resource_name": "斗志",
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
        "color": Color(0.25, 0.85, 0.55),
        "abilities": [
            {"id":"dragon_skill_1","name":"龙纹之盾","description":"举盾格挡正面攻击，成功防御时恢复小宇宙。","type":"防御","role":"减伤","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"dragon_skill_2","name":"升龙阵","description":"向前方跃起挑击，击飞并打断普通敌人。","type":"挑空","role":"控制","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"dragon_skill_3","name":"真龙连牙","description":"连续重拳压制单体，末击破防。","type":"破防","role":"单体","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"dragon_skill_4","name":"庐山龙飞翔","description":"旋身冲锋撞开周围敌人。","type":"冲锋","role":"群体","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"dragon_skill_5","name":"龙之咆哮","description":"短时间提高防御与仇恨吸引能力。","type":"守护","role":"增益","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"dragon_skill_6","name":"庐山百龙霸","description":"召唤群龙之力轰击大范围敌人。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"龙盾守护","description":"受到正面伤害时获得额外减伤，格挡后强化下一次重击。","effect":"damage_reduction","value":0.12},
        "resource_name": "龙魂",
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
        "color": Color(0.55, 0.85, 1.0),
        "abilities": [
            {"id":"cygnus_skill_1","name":"冰晶之环","description":"释放寒气环绕自身，减缓近身敌人。","type":"控场","role":"减速","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"cygnus_skill_2","name":"冰结晶束缚","description":"凝结冰晶封锁目标，短暂冻结普通敌人。","type":"冻结","role":"控制","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"cygnus_skill_3","name":"钻石星尘拳","description":"向前方扇形释放冻气，多段远程伤害。","type":"远程","role":"群体","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"cygnus_skill_4","name":"冰封领域","description":"在地面形成持续寒冰区域，持续减速并伤害。","type":"领域","role":"持续","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"cygnus_skill_5","name":"寒冰护体","description":"凝结冰甲，短暂降低受到的伤害。","type":"防御","role":"减伤","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"cygnus_skill_6","name":"曙光女神之宽恕","description":"释放极寒终极冻气，对范围敌人造成重击。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"绝对零度","description":"对被减速或冻结的敌人造成额外伤害。","effect":"control_damage","value":0.12},
        "resource_name": "冻气",
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
        "color": Color(0.85, 0.55, 1.0),
        "abilities": [
            {"id":"andromeda_skill_1","name":"星云锁链·圆锁","description":"锁链环绕自身，拦截近身敌人。","type":"防御","role":"反制","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"andromeda_skill_2","name":"星云锁链·角锁","description":"远距离锁定并刺击单个目标。","type":"牵制","role":"单体","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"andromeda_skill_3","name":"雷电锁链","description":"锁链在多个敌人间弹射，造成连锁伤害。","type":"弹射","role":"群体","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"andromeda_skill_4","name":"星云气流","description":"以锁链牵引自身快速位移并击退敌人。","type":"机动","role":"位移","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"andromeda_skill_5","name":"星云防御阵","description":"展开锁链防御阵，短时间提高防御。","type":"守护","role":"减伤","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"andromeda_skill_6","name":"星云风暴","description":"释放大范围锁链风暴，持续压制敌人。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"星云守护","description":"生命较低时获得锁链护盾，控制技能效果增强。","effect":"damage_reduction","value":0.08},
        "resource_name": "神恩",
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
        "color": Color(1.0, 0.35, 0.18),
        "abilities": [
            {"id":"phoenix_skill_1","name":"凤翼天翔","description":"向前方释放烈焰冲击，造成高额爆发伤害。","type":"爆发","role":"范围","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"phoenix_skill_2","name":"凤凰幻魔拳","description":"精神冲击扰乱目标，使普通敌人短暂失衡。","type":"精神","role":"控制","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"phoenix_skill_3","name":"不死鸟烈焰","description":"在目标区域留下持续燃烧的火焰。","type":"灼烧","role":"持续","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"phoenix_skill_4","name":"暗黑凤凰召唤","description":"召唤幻影协同攻击，短时间追加伤害。","type":"召唤","role":"持续","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"phoenix_skill_5","name":"浴火重生","description":"濒危时触发一次短暂护盾与生命恢复，长冷却。","type":"复苏","role":"生存","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"phoenix_skill_6","name":"不死鸟涅槃","description":"爆发小宇宙，对周围敌人造成火焰终结伤害。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"不死之炎","description":"技能命中可叠加焰力，焰力提高持续伤害与终结技伤害。","effect":"damage","value":0.1},
        "resource_name": "焰力",
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
        "color": Color(0.2, 0.75, 0.9),
        "abilities": [
            {"id":"sea_dragon_skill_1","name":"黄金三角次元","description":"开启次元裂隙，对前方敌人造成空间冲击。","type":"次元","role":"范围","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"sea_dragon_skill_2","name":"幻胧魔皇拳","description":"精神压制目标，降低其攻击威胁。","type":"精神","role":"控制","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"sea_dragon_skill_3","name":"海龙突袭","description":"快速突进至目标附近并造成穿刺伤害。","type":"突袭","role":"单体","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"sea_dragon_skill_4","name":"次元迷踪","description":"短暂进入空间闪避状态，提高机动性。","type":"闪避","role":"生存","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"sea_dragon_skill_5","name":"深海漩涡","description":"制造漩涡牵引并减速周围敌人。","type":"牵引","role":"群体","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"sea_dragon_skill_6","name":"海龙怒涛","description":"召唤海潮与次元力量进行大范围轰击。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"异次元掌控","description":"从目标侧后方攻击时伤害提高，突袭后短暂提高闪避。","effect":"damage","value":0.1},
        "resource_name": "次元",
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
        "color": Color(0.8, 0.45, 0.25),
        "abilities": [
            {"id":"tenmou_skill_1","name":"天猛重击","description":"沉重打击正面敌人，造成高硬直。","type":"重击","role":"破防","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"tenmou_skill_2","name":"钢铁冲击","description":"蓄力冲锋，撞开路径上的敌人。","type":"冲锋","role":"群体","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"tenmou_skill_3","name":"碎岩震地","description":"重击地面产生冲击波。","type":"震地","role":"范围","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"tenmou_skill_4","name":"铁壁架势","description":"进入防御架势，降低伤害并抵抗击退。","type":"防御","role":"减伤","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"tenmou_skill_5","name":"狂战怒意","description":"生命降低时提升攻击，持续一段时间。","type":"狂怒","role":"增益","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"tenmou_skill_6","name":"天猛陨星破","description":"跃起砸地，对大范围敌人造成重击。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"冥斗士战意","description":"生命越低攻击越高，重击对霸体目标更有效。","effect":"damage","value":0.12},
        "resource_name": "怒气",
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
        "color": Color(0.9, 0.8, 0.35),
        "abilities": [
            {"id":"lyra_skill_1","name":"弦乐幻境","description":"演奏音波扰乱敌人并造成持续伤害。","type":"音波","role":"持续","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"lyra_skill_2","name":"死亡交响曲","description":"释放高强度音波，对扇形区域造成伤害与硬直。","type":"控制","role":"群体","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"lyra_skill_3","name":"弦音屏障","description":"音律形成护盾，短时间降低受到的伤害。","type":"护盾","role":"防御","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"lyra_skill_4","name":"镇魂曲","description":"持续音波削弱敌人攻击与移动。","type":"削弱","role":"减益","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"lyra_skill_5","name":"治愈旋律","description":"演奏恢复乐章，为自身恢复生命与小宇宙。","type":"治疗","role":"恢复","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"lyra_skill_6","name":"黄金弦乐终章","description":"奏响终曲，对范围敌人造成高额音波伤害。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"黄金和弦","description":"治疗与音波技能命中后积累和弦，强化下一次控制。","effect":"stagger","value":0.15},
        "resource_name": "音律",
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
        "color": Color(0.25, 0.9, 0.8),
        "abilities": [
            {"id":"sea_swallow_skill_1","name":"海燕疾风","description":"高速向前突刺并快速撤步。","type":"突进","role":"机动","unlock_level":1,"cost":12,"cooldown":4},
            {"id":"sea_swallow_skill_2","name":"旋流突袭","description":"连续旋身攻击周围敌人。","type":"连击","role":"群体","unlock_level":5,"cost":18,"cooldown":8},
            {"id":"sea_swallow_skill_3","name":"疾风回旋踢","description":"回旋踢击退近身目标。","type":"击退","role":"控制","unlock_level":10,"cost":22,"cooldown":10},
            {"id":"sea_swallow_skill_4","name":"潮汐步","description":"短时间提高移动与闪避能力。","type":"身法","role":"增益","unlock_level":18,"cost":25,"cooldown":14},
            {"id":"sea_swallow_skill_5","name":"风刃连射","description":"向前方快速释放多道风刃。","type":"远程","role":"多段","unlock_level":28,"cost":28,"cooldown":18},
            {"id":"sea_swallow_skill_6","name":"海燕龙卷风","description":"制造高速龙卷，对范围敌人连续打击。","type":"奥义","role":"范围","unlock_level":40,"cost":35,"cooldown":28}
        ],
        "passive": {"name":"疾风步","description":"连续闪避后获得短暂攻速与移动速度提升。","effect":"speed","value":0.12},
        "resource_name": "疾风",
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


func get_ability_catalog(class_id: String) -> Array:
    var data := get_class_skill(class_id)
    return data.get("abilities", []).duplicate(true)

func get_passive(class_id: String) -> Dictionary:
    return get_class_skill(class_id).get("passive", {}).duplicate(true)

func get_skill_damage_multiplier(class_id: String, target: Node = null) -> float:
    var passive := get_passive(class_id)
    var effect := str(passive.get("effect", ""))
    var value := float(passive.get("value", 0.0))
    if effect == "damage":
        return 1.0 + value
    if effect == "combo_damage":
        return 1.0 + value
    if effect == "control_damage" and is_instance_valid(target):
        if target.has_method("is_controlled") and bool(target.call("is_controlled")):
            return 1.0 + value
    return 1.0

func get_damage_reduction(class_id: String) -> float:
    var passive := get_passive(class_id)
    if str(passive.get("effect", "")) == "damage_reduction":
        return clampf(float(passive.get("value", 0.0)), 0.0, 0.35)
    return 0.0

func get_skill_unlock_level(class_id: String, ability_id: String) -> int:
    for ability in get_ability_catalog(class_id):
        if str(ability.get("id", "")) == ability_id:
            return int(ability.get("unlock_level", 1))
    return 999
