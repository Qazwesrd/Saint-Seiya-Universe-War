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
        "class_name": "天猛", "faction": "冥界·哈迪斯军", "faction_id": "hades_specters", "canon_status": "原作明确", "canon_reference": "天猛星拉达曼迪斯", "style": "重型近战压制",
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
        "class_name": "天琴", "faction": "圣域·雅典娜军", "faction_id": "athena_sanctuary", "canon_status": "原作明确", "canon_reference": "天琴座奥路菲", "style": "音波中距离牵制",
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
        "class_name": "海燕", "faction": "待核实（暂不归属）", "faction_id": "unverified", "canon_status": "尚未确认对应原作角色", "style": "高速机动突袭",
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

# Divine classes are deliberately above mortal combat tiers; unlocks and story gates are handled by progression.
const DIVINE_CLASS_SKILLS := {
    "apollo": {
        "class_name":"阿波罗","tier":"神明","faction":"奥林匹斯·阿波罗","faction_id":"apollo","canon_status":"原作神明角色；可操作职业技能为游戏化扩展","style":"太阳神·远程毁灭与神域压制","basic_attacks":["日轮神拳","太阳追击","神焰终结"],"name":"太阳神裁决","combo":"日轮焚天","burst_name":"阿波罗·太阳终焉","description":"神明职业拥有远超凡人战士的神格、神力与神域，技能数值定位为最高战力层。","cost":50,"cooldown":2.2,"damage":6.8,"combo_damage":9.5,"range":16,"cone":210,"knockback":18,"launch":7,"stagger":1.8,"combo_range":18,"combo_knockback":22,"combo_launch":9,"burst_range":17,"burst_knockback":26,"burst_launch":10,"color":Color(1.0, 0.72, 0.18),"abilities":[
            {"id":"apollo_skill_1","name":"神焰降临","description":"召唤太阳神焰轰击目标区域。","type":"灼烧","role":"范围","unlock_level":1,"cost":48,"cooldown":5},
            {"id":"apollo_skill_2","name":"日轮光矢","description":"凝聚太阳光束贯穿直线敌人。","type":"远程","role":"群体","unlock_level":5,"cost":56,"cooldown":7},
            {"id":"apollo_skill_3","name":"太阳神盾","description":"展开日轮屏障，大幅减伤并反震近身攻击。","type":"护盾","role":"防御","unlock_level":10,"cost":64,"cooldown":12},
            {"id":"apollo_skill_4","name":"光之审判","description":"释放高热光环，持续灼烧并削弱敌人。","type":"领域","role":"群体","unlock_level":18,"cost":72,"cooldown":14},
            {"id":"apollo_skill_5","name":"神速日行","description":"化作光芒瞬移追击，短暂免疫伤害。","type":"闪避","role":"机动","unlock_level":28,"cost":78,"cooldown":16},
            {"id":"apollo_skill_6","name":"太阳终焉","description":"释放神级太阳爆发，对大范围敌人造成毁灭打击。","type":"奥义","role":"范围","unlock_level":40,"cost":95,"cooldown":32}
        ],
        "passive":{"name":"日轮神格","description":"太阳神域持续灼烧周围敌人，神级奥义伤害进一步提高。","effect":"damage","value":0.38},"resource_name":"太阳神力"
    },
    "athena": {
        "class_name":"雅典娜","tier":"神明","faction":"奥林匹斯·雅典娜","faction_id":"athena","canon_status":"原作神明角色；可操作职业技能为游戏化扩展","style":"智慧与战争女神·神圣守护及统御","basic_attacks":["神圣长矛","胜利追击","女神裁决"],"name":"胜利女神之矛","combo":"雅典娜神圣裁决","burst_name":"雅典娜·大地守护","description":"神明职业拥有远超凡人战士的神格、神力与神域，技能数值定位为最高战力层。","cost":46,"cooldown":2.2,"damage":5.8,"combo_damage":8.8,"range":14,"cone":230,"knockback":13,"launch":5,"stagger":2.1,"combo_range":16,"combo_knockback":17,"combo_launch":7,"burst_range":15,"burst_knockback":21,"burst_launch":8,"color":Color(0.55, 0.82, 1.0),"abilities":[
            {"id":"athena_skill_1","name":"胜利女神之矛","description":"以神圣之矛贯穿敌阵并击退目标。","type":"冲击","role":"群体","unlock_level":1,"cost":45,"cooldown":5},
            {"id":"athena_skill_2","name":"雅典娜神盾","description":"展开女神结界，吸收大量伤害。","type":"护盾","role":"防御","unlock_level":5,"cost":52,"cooldown":8},
            {"id":"athena_skill_3","name":"神圣净化","description":"净化自身负面状态并恢复生命与神力。","type":"治疗","role":"恢复","unlock_level":10,"cost":60,"cooldown":12},
            {"id":"athena_skill_4","name":"战争女神号令","description":"神威压制敌人，降低其攻击并使其迟缓。","type":"削弱","role":"群体","unlock_level":18,"cost":68,"cooldown":14},
            {"id":"athena_skill_5","name":"大地守护结界","description":"建立持续神域，强化防御并恢复生命。","type":"领域","role":"群体","unlock_level":28,"cost":76,"cooldown":18},
            {"id":"athena_skill_6","name":"女神最终审判","description":"召唤神圣力量审判大范围敌人并施加强力硬直。","type":"奥义","role":"范围","unlock_level":40,"cost":92,"cooldown":32}
        ],
        "passive":{"name":"胜利女神庇护","description":"神圣结界持续减伤，净化与守护技能获得额外效果。","effect":"damage_reduction","value":0.42},"resource_name":"雅典娜神力"
    },
    "hades": {
        "class_name":"哈迪斯","tier":"神明","faction":"冥界·哈迪斯","faction_id":"hades","canon_status":"原作神明角色；可操作职业技能为游戏化扩展","style":"冥界之神·灵魂侵蚀与死亡领域","basic_attacks":["冥王剑斩","亡魂追击","黑暗终结"],"name":"冥界之剑","combo":"冥王审判","burst_name":"哈迪斯·永恒黑暗","description":"神明职业拥有远超凡人战士的神格、神力与神域，技能数值定位为最高战力层。","cost":50,"cooldown":2.2,"damage":7.2,"combo_damage":10.2,"range":15,"cone":220,"knockback":16,"launch":6,"stagger":2,"combo_range":17,"combo_knockback":20,"combo_launch":8,"burst_range":16,"burst_knockback":24,"burst_launch":9,"color":Color(0.62, 0.28, 0.78),"abilities":[
            {"id":"hades_skill_1","name":"冥界之剑","description":"挥出冥王剑气，斩裂前方敌人。","type":"冲击","role":"范围","unlock_level":1,"cost":48,"cooldown":5},
            {"id":"hades_skill_2","name":"亡者召引","description":"召来亡魂缠绕目标，造成持续侵蚀与减速。","type":"领域","role":"群体","unlock_level":5,"cost":56,"cooldown":8},
            {"id":"hades_skill_3","name":"冥王黑翼","description":"展开黑翼突进并击飞路径上的敌人。","type":"突进","role":"群体","unlock_level":10,"cost":64,"cooldown":11},
            {"id":"hades_skill_4","name":"灵魂剥夺","description":"侵蚀目标灵魂，削弱其攻击与防御。","type":"削弱","role":"单体","unlock_level":18,"cost":72,"cooldown":14},
            {"id":"hades_skill_5","name":"冥界不灭体","description":"短时间获得强力护盾并恢复生命。","type":"复苏","role":"生存","unlock_level":28,"cost":80,"cooldown":18},
            {"id":"hades_skill_6","name":"永恒黑暗","description":"降下冥界终焉，对大范围敌人造成毁灭性伤害。","type":"奥义","role":"范围","unlock_level":40,"cost":100,"cooldown":34}
        ],
        "passive":{"name":"冥王不灭","description":"冥界领域侵蚀敌人并强化自身，生命低时获得额外神力护体。","effect":"damage","value":0.42},"resource_name":"冥王神力"
    },
    "poseidon": {
        "class_name":"波塞冬","tier":"神明","faction":"海界·波塞冬","faction_id":"poseidon","canon_status":"原作神明角色；可操作职业技能为游戏化扩展","style":"海皇·海啸统御与三叉戟神罚","basic_attacks":["三叉戟横斩","海潮追击","海皇神罚"],"name":"海皇三叉戟","combo":"深海海啸","burst_name":"波塞冬·天地洪流","description":"神明职业拥有远超凡人战士的神格、神力与神域，技能数值定位为最高战力层。","cost":50,"cooldown":2.2,"damage":6.7,"combo_damage":9.6,"range":16,"cone":225,"knockback":19,"launch":6,"stagger":1.9,"combo_range":18,"combo_knockback":23,"combo_launch":8,"burst_range":17,"burst_knockback":27,"burst_launch":9,"color":Color(0.18, 0.72, 0.92),"abilities":[
            {"id":"poseidon_skill_1","name":"三叉戟神罚","description":"挥动三叉戟释放贯穿海潮。","type":"冲击","role":"群体","unlock_level":1,"cost":48,"cooldown":5},
            {"id":"poseidon_skill_2","name":"深海漩涡","description":"制造巨型漩涡牵引并压制敌人。","type":"牵引","role":"群体","unlock_level":5,"cost":56,"cooldown":8},
            {"id":"poseidon_skill_3","name":"海皇壁垒","description":"召唤海流护盾，抵挡攻击并反击。","type":"护盾","role":"防御","unlock_level":10,"cost":64,"cooldown":12},
            {"id":"poseidon_skill_4","name":"海啸天罚","description":"召唤海啸冲击大范围敌人。","type":"范围","role":"群体","unlock_level":18,"cost":72,"cooldown":14},
            {"id":"poseidon_skill_5","name":"海界统御","description":"进入海皇领域，提升攻击、防御与移动。","type":"增益","role":"自身","unlock_level":28,"cost":80,"cooldown":18},
            {"id":"poseidon_skill_6","name":"天地洪流","description":"释放海皇神力形成终极洪流，席卷战场。","type":"奥义","role":"范围","unlock_level":40,"cost":100,"cooldown":34}
        ],
        "passive":{"name":"海皇统御","description":"海皇领域强化水流攻击，并降低受到的远程伤害。","effect":"damage_reduction","value":0.36},"resource_name":"海皇神力"
    }
}

# Advanced class skill branches: 18 additional skills per class, in three six-skill branches.
const ADVANCED_CLASS_SKILLS := {
    "pegasus": [
        {"id":"pegasus_advanced_1","name":"彗星突刺","description":"向目标高速穿刺，命中后追加追击拳。","branch":"进攻","type":"突进","role":"突进","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"pegasus_advanced_2","name":"流星散华","description":"向扇形区域连续轰出密集拳影。","branch":"进攻","type":"群攻","role":"群攻","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"pegasus_advanced_3","name":"天马冲天击","description":"上勾拳挑飞目标，可衔接空中追击。","branch":"进攻","type":"挑空","role":"挑空","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"pegasus_advanced_4","name":"音速回旋踢","description":"旋身踢击周围目标并拉开距离。","branch":"进攻","type":"击退","role":"击退","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"pegasus_advanced_5","name":"彗星爆裂","description":"消耗斗志强化下一次重击，提升破防能力。","branch":"进攻","type":"强化","role":"强化","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"pegasus_advanced_6","name":"天马幻影连袭","description":"留下残影连续攻击锁定目标。","branch":"进攻","type":"多段","role":"多段","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"pegasus_advanced_7","name":"疾风闪避","description":"快速侧移并短暂获得闪避窗口。","branch":"机动","type":"闪避","role":"闪避","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"pegasus_advanced_8","name":"星云追猎","description":"锁定目标后快速贴近并造成硬直。","branch":"机动","type":"追击","role":"追击","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"pegasus_advanced_9","name":"天马翔跃","description":"跃向空中躲避地面攻击并发动下劈。","branch":"机动","type":"位移","role":"位移","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"pegasus_advanced_10","name":"斗志昂扬","description":"短时间提高攻击速度与连击伤害。","branch":"机动","type":"增益","role":"增益","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"pegasus_advanced_11","name":"不屈反击","description":"成功闪避后下一击获得额外伤害。","branch":"机动","type":"反击","role":"反击","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"pegasus_advanced_12","name":"彗星步法","description":"连续移动后强化下一次突进距离。","branch":"机动","type":"强化","role":"强化","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"pegasus_advanced_13","name":"天马守势","description":"短暂降低正面受到的伤害。","branch":"守护","type":"减伤","role":"减伤","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"pegasus_advanced_14","name":"逆境爆发","description":"生命较低时回复少量小宇宙并提高韧性。","branch":"守护","type":"恢复","role":"恢复","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"pegasus_advanced_15","name":"星辰护体","description":"生成短暂护盾抵挡一次轻型攻击。","branch":"守护","type":"护盾","role":"护盾","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"pegasus_advanced_16","name":"流星反击","description":"受到近战攻击后快速反击周围敌人。","branch":"守护","type":"反制","role":"反制","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"pegasus_advanced_17","name":"天马意志","description":"提高连击窗口持续时间。","branch":"守护","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"pegasus_advanced_18","name":"银河彗星终结","description":"聚集斗志发动直线终结冲击。","branch":"守护","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "dragon": [
        {"id":"dragon_advanced_1","name":"龙牙破阵","description":"以盾击破开敌方防御并造成硬直。","branch":"攻防","type":"破防","role":"破防","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"dragon_advanced_2","name":"升龙连破","description":"连续上挑后以重拳击落目标。","branch":"攻防","type":"挑空","role":"挑空","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"dragon_advanced_3","name":"庐山崩拳","description":"集中力量轰击单体并降低其防御。","branch":"攻防","type":"破甲","role":"破甲","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"dragon_advanced_4","name":"苍龙裂地","description":"盾拳砸地形成直线冲击波。","branch":"攻防","type":"范围","role":"范围","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"dragon_advanced_5","name":"龙尾旋击","description":"转身横扫周围敌人。","branch":"攻防","type":"群攻","role":"群攻","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"dragon_advanced_6","name":"逆鳞重击","description":"消耗龙魂强化下一次攻击与击退。","branch":"攻防","type":"强化","role":"强化","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"dragon_advanced_7","name":"龙盾壁垒","description":"举盾大幅降低正面伤害。","branch":"守护","type":"格挡","role":"格挡","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"dragon_advanced_8","name":"苍龙守护阵","description":"为自身生成持续护盾。","branch":"守护","type":"护盾","role":"护盾","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"dragon_advanced_9","name":"不动如山","description":"短时间免疫普通击退与硬直。","branch":"守护","type":"霸体","role":"霸体","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"dragon_advanced_10","name":"龙之反震","description":"格挡成功后释放震荡反击。","branch":"守护","type":"反击","role":"反击","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"dragon_advanced_11","name":"守护誓约","description":"短时间吸引附近敌人注意。","branch":"守护","type":"牵制","role":"牵制","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"dragon_advanced_12","name":"龙魂复苏","description":"恢复生命并提升防御，长冷却。","branch":"守护","type":"恢复","role":"恢复","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"dragon_advanced_13","name":"飞龙在天","description":"向前跃进并以升龙击开路。","branch":"机动","type":"突进","role":"突进","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"dragon_advanced_14","name":"苍龙摆尾","description":"快速横移后扫击敌人。","branch":"机动","type":"位移","role":"位移","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"dragon_advanced_15","name":"龙翔九天","description":"跃空后向地面发动俯冲攻击。","branch":"机动","type":"空袭","role":"空袭","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"dragon_advanced_16","name":"龙行步","description":"短时间提高移动速度。","branch":"机动","type":"增益","role":"增益","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"dragon_advanced_17","name":"龙鳞韧性","description":"受到连续攻击时逐步提高减伤。","branch":"机动","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"dragon_advanced_18","name":"庐山真龙奥义","description":"凝聚龙魂释放贯穿前方的终极龙击。","branch":"机动","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "cygnus": [
        {"id":"cygnus_advanced_1","name":"冰晶飞刃","description":"凝结冰刃远程穿刺单体目标。","branch":"冰霜输出","type":"远程","role":"远程","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"cygnus_advanced_2","name":"寒冰连射","description":"连续发射冰晶造成多段伤害。","branch":"冰霜输出","type":"多段","role":"多段","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"cygnus_advanced_3","name":"冰河冲击","description":"释放直线冻气击退敌人。","branch":"冰霜输出","type":"击退","role":"击退","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"cygnus_advanced_4","name":"极光冰爆","description":"引爆目标身上的寒霜标记。","branch":"冰霜输出","type":"爆发","role":"爆发","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"cygnus_advanced_5","name":"冰棱穿心","description":"集中冰枪攻击单体弱点。","branch":"冰霜输出","type":"单体","role":"单体","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"cygnus_advanced_6","name":"寒霜风暴","description":"召唤环形冰风暴持续伤害。","branch":"冰霜输出","type":"范围","role":"范围","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"cygnus_advanced_7","name":"绝对零度领域","description":"扩大寒气领域并持续减速敌人。","branch":"冻结控制","type":"领域","role":"领域","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"cygnus_advanced_8","name":"冰封枷锁","description":"冻结普通敌人并打断其动作。","branch":"冻结控制","type":"冻结","role":"冻结","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"cygnus_advanced_9","name":"寒冰地牢","description":"在指定区域形成冰牢限制敌人移动。","branch":"冻结控制","type":"禁锢","role":"禁锢","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"cygnus_advanced_10","name":"冰镜反射","description":"短暂生成冰镜抵挡正面攻击。","branch":"冻结控制","type":"反制","role":"反制","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"cygnus_advanced_11","name":"霜冻标记","description":"标记目标，使其受到更多冰霜伤害。","branch":"冻结控制","type":"易伤","role":"易伤","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"cygnus_advanced_12","name":"永冻连锁","description":"将寒霜效果扩散至附近敌人。","branch":"冻结控制","type":"扩散","role":"扩散","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"cygnus_advanced_13","name":"冰晶铠甲","description":"凝结冰甲降低受到的伤害。","branch":"寒冰守护","type":"减伤","role":"减伤","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"cygnus_advanced_14","name":"寒气屏障","description":"生成冰墙阻挡敌方接近。","branch":"寒冰守护","type":"屏障","role":"屏障","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"cygnus_advanced_15","name":"冰雪回息","description":"恢复少量生命与小宇宙。","branch":"寒冰守护","type":"恢复","role":"恢复","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"cygnus_advanced_16","name":"冰步闪身","description":"向后滑步并短暂提高闪避。","branch":"寒冰守护","type":"闪避","role":"闪避","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"cygnus_advanced_17","name":"冻气共鸣","description":"提高对减速与冻结目标的伤害。","branch":"寒冰守护","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"cygnus_advanced_18","name":"极光终焉","description":"凝聚极寒冻气发动终极范围攻击。","branch":"寒冰守护","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "andromeda": [
        {"id":"andromeda_advanced_1","name":"锁链穿星","description":"锁链直线突刺并穿透多个目标。","branch":"锁链攻击","type":"穿透","role":"穿透","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"andromeda_advanced_2","name":"旋转锁链阵","description":"环绕自身高速旋转锁链攻击。","branch":"锁链攻击","type":"范围","role":"范围","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"andromeda_advanced_3","name":"雷霆锁链·追击","description":"锁链自动追踪标记目标。","branch":"锁链攻击","type":"追踪","role":"追踪","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"andromeda_advanced_4","name":"星云飞瀑","description":"向前方释放多段锁链打击。","branch":"锁链攻击","type":"多段","role":"多段","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"andromeda_advanced_5","name":"锁链绞杀","description":"束缚单体目标并持续造成伤害。","branch":"锁链攻击","type":"束缚","role":"束缚","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"andromeda_advanced_6","name":"星云爆裂链","description":"引爆锁链标记造成范围伤害。","branch":"锁链攻击","type":"爆发","role":"爆发","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"andromeda_advanced_7","name":"圆锁反制","description":"锁链形成防御圆环，反弹轻型攻击。","branch":"守护辅助","type":"反制","role":"反制","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"andromeda_advanced_8","name":"星云结界","description":"为自身与附近友方提供防护效果。","branch":"守护辅助","type":"护盾","role":"护盾","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"andromeda_advanced_9","name":"生命链接","description":"将部分受到的伤害转化为小宇宙消耗。","branch":"守护辅助","type":"减伤","role":"减伤","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"andromeda_advanced_10","name":"治愈星云","description":"恢复自身生命并清除轻微异常状态。","branch":"守护辅助","type":"治疗","role":"治疗","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"andromeda_advanced_11","name":"守护之链","description":"短时间降低附近敌人的攻击能力。","branch":"守护辅助","type":"削弱","role":"削弱","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"andromeda_advanced_12","name":"星云庇护","description":"生命危急时自动触发一次护盾。","branch":"守护辅助","type":"保命","role":"保命","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"andromeda_advanced_13","name":"锁链牵引","description":"将自身拉向目标或将普通敌人拉近。","branch":"控制机动","type":"牵引","role":"牵引","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"andromeda_advanced_14","name":"星云回环步","description":"快速绕到目标侧面。","branch":"控制机动","type":"位移","role":"位移","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"andromeda_advanced_15","name":"锁链封路","description":"在地面布置锁链区域限制敌人。","branch":"控制机动","type":"陷阱","role":"陷阱","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"andromeda_advanced_16","name":"雷电束缚","description":"电击并短暂打断目标动作。","branch":"控制机动","type":"打断","role":"打断","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"andromeda_advanced_17","name":"星云感知","description":"扩大锁定与索敌距离。","branch":"控制机动","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"andromeda_advanced_18","name":"银河锁链审判","description":"召唤多重锁链覆盖战场。","branch":"控制机动","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "phoenix": [
        {"id":"phoenix_advanced_1","name":"烈焰连环拳","description":"连续火焰拳击并叠加灼烧。","branch":"烈焰爆发","type":"多段","role":"多段","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"phoenix_advanced_2","name":"凤凰火羽","description":"向扇形区域发射火羽。","branch":"烈焰爆发","type":"远程","role":"远程","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"phoenix_advanced_3","name":"赤炎冲天","description":"火柱从地面爆发击飞敌人。","branch":"烈焰爆发","type":"挑空","role":"挑空","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"phoenix_advanced_4","name":"焚天烈火","description":"在前方留下持续燃烧区域。","branch":"烈焰爆发","type":"持续","role":"持续","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"phoenix_advanced_5","name":"炎爆印记","description":"标记目标并在数秒后引爆。","branch":"烈焰爆发","type":"延迟爆发","role":"延迟爆发","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"phoenix_advanced_6","name":"凤凰焚世","description":"引爆附近所有灼烧效果。","branch":"烈焰爆发","type":"引爆","role":"引爆","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"phoenix_advanced_7","name":"幻魔侵袭","description":"精神冲击使普通敌人短暂混乱。","branch":"幻魔控制","type":"混乱","role":"混乱","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"phoenix_advanced_8","name":"梦魇火牢","description":"制造幻象火牢限制目标行动。","branch":"幻魔控制","type":"禁锢","role":"禁锢","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"phoenix_advanced_9","name":"暗黑幻影","description":"召唤凤凰幻影协同攻击。","branch":"幻魔控制","type":"召唤","role":"召唤","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"phoenix_advanced_10","name":"心神震荡","description":"打断目标蓄力并造成硬直。","branch":"幻魔控制","type":"打断","role":"打断","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"phoenix_advanced_11","name":"涅槃印记","description":"记录当前生命，短时间内获得复苏机会。","branch":"幻魔控制","type":"复苏","role":"复苏","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"phoenix_advanced_12","name":"不灭意志","description":"短暂免疫一次致命伤害，长冷却。","branch":"幻魔控制","type":"保命","role":"保命","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"phoenix_advanced_13","name":"浴火护身","description":"生成火焰护盾并灼烧近身敌人。","branch":"不死重生","type":"护盾","role":"护盾","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"phoenix_advanced_14","name":"凤凰回生","description":"恢复生命并清除控制效果。","branch":"不死重生","type":"治疗","role":"治疗","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"phoenix_advanced_15","name":"焚身反击","description":"受击后向周围释放火焰冲击。","branch":"不死重生","type":"反击","role":"反击","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"phoenix_advanced_16","name":"不死鸟之翼","description":"向后跃开并留下火焰轨迹。","branch":"不死重生","type":"闪避","role":"闪避","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"phoenix_advanced_17","name":"不灭火种","description":"击败敌人后恢复少量生命。","branch":"不死重生","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"phoenix_advanced_18","name":"凤凰涅槃·天火","description":"化身烈焰凤凰发动终极俯冲。","branch":"不死重生","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "sea_dragon": [
        {"id":"sea_dragon_advanced_1","name":"次元裂斩","description":"撕开空间对直线敌人造成斩击。","branch":"次元炮击","type":"直线","role":"直线","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"sea_dragon_advanced_2","name":"异界光矛","description":"发射穿透空间的能量矛。","branch":"次元炮击","type":"穿透","role":"穿透","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"sea_dragon_advanced_3","name":"空间坍缩","description":"压缩指定区域并造成爆炸。","branch":"次元炮击","type":"范围","role":"范围","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"sea_dragon_advanced_4","name":"次元连爆","description":"连续开启小型裂隙轰击目标。","branch":"次元炮击","type":"多段","role":"多段","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"sea_dragon_advanced_5","name":"海龙吐息","description":"释放海潮能量冲击前方敌人。","branch":"次元炮击","type":"击退","role":"击退","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"sea_dragon_advanced_6","name":"黄金三角·崩坏","description":"扩大次元裂隙造成强力终结伤害。","branch":"次元炮击","type":"终结","role":"终结","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"sea_dragon_advanced_7","name":"幻胧迷阵","description":"制造幻象干扰敌人索敌。","branch":"精神次元","type":"干扰","role":"干扰","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"sea_dragon_advanced_8","name":"精神锁定","description":"压制目标，使其短时间攻击下降。","branch":"精神次元","type":"削弱","role":"削弱","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"sea_dragon_advanced_9","name":"异次元放逐","description":"将普通敌人短暂困入次元裂隙。","branch":"精神次元","type":"控制","role":"控制","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"sea_dragon_advanced_10","name":"空间封锁","description":"封闭区域限制敌人移动。","branch":"精神次元","type":"禁锢","role":"禁锢","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"sea_dragon_advanced_11","name":"次元标记","description":"标记目标，后续空间技能追踪增强。","branch":"精神次元","type":"标记","role":"标记","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"sea_dragon_advanced_12","name":"幻影替身","description":"制造替身吸引一次攻击。","branch":"精神次元","type":"替身","role":"替身","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"sea_dragon_advanced_13","name":"空间跃迁","description":"瞬间短距离位移。","branch":"机动生存","type":"位移","role":"位移","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"sea_dragon_advanced_14","name":"次元闪避","description":"短暂进入无敌闪避状态。","branch":"机动生存","type":"闪避","role":"闪避","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"sea_dragon_advanced_15","name":"深海护体","description":"海流形成护盾吸收伤害。","branch":"机动生存","type":"护盾","role":"护盾","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"sea_dragon_advanced_16","name":"潮汐回能","description":"恢复小宇宙并缩短突袭技能冷却。","branch":"机动生存","type":"恢复","role":"恢复","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"sea_dragon_advanced_17","name":"空间掌控","description":"提高对被控制目标的伤害。","branch":"机动生存","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"sea_dragon_advanced_18","name":"异次元海皇裁决","description":"展开黄金三角次元终极领域。","branch":"机动生存","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "tenmou": [
        {"id":"tenmou_advanced_1","name":"碎骨重拳","description":"强力重拳降低目标防御。","branch":"重装破坏","type":"破甲","role":"破甲","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"tenmou_advanced_2","name":"地裂冲锋","description":"冲锋撞击路径上的所有敌人。","branch":"重装破坏","type":"冲锋","role":"冲锋","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"tenmou_advanced_3","name":"崩山连砸","description":"连续砸击地面造成震荡。","branch":"重装破坏","type":"多段","role":"多段","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"tenmou_advanced_4","name":"陨石坠击","description":"跃起砸向目标区域。","branch":"重装破坏","type":"范围","role":"范围","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"tenmou_advanced_5","name":"钢铁碎颅","description":"蓄力后对单体发动高硬直重击。","branch":"重装破坏","type":"蓄力","role":"蓄力","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"tenmou_advanced_6","name":"毁灭震波","description":"向四周释放环形冲击波。","branch":"重装破坏","type":"击退","role":"击退","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"tenmou_advanced_7","name":"铁壁防御","description":"架起防御姿态，大幅降低伤害。","branch":"铁壁狂怒","type":"格挡","role":"格挡","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"tenmou_advanced_8","name":"不屈钢躯","description":"短时间获得霸体抵抗控制。","branch":"铁壁狂怒","type":"霸体","role":"霸体","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"tenmou_advanced_9","name":"反震护甲","description":"受到近战攻击时反弹部分伤害。","branch":"铁壁狂怒","type":"反伤","role":"反伤","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"tenmou_advanced_10","name":"战吼威慑","description":"降低周围敌人的攻击与移动速度。","branch":"铁壁狂怒","type":"削弱","role":"削弱","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"tenmou_advanced_11","name":"怒意回流","description":"受到伤害时积累怒气。","branch":"铁壁狂怒","type":"资源","role":"资源","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"tenmou_advanced_12","name":"钢铁意志","description":"生命较低时获得额外防御。","branch":"铁壁狂怒","type":"被动强化","role":"被动强化","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"tenmou_advanced_13","name":"狂战突进","description":"向目标冲锋并造成撞击。","branch":"狂战突击","type":"突进","role":"突进","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"tenmou_advanced_14","name":"旋风重锤","description":"旋转身体攻击周围敌人。","branch":"狂战突击","type":"范围","role":"范围","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"tenmou_advanced_15","name":"血怒爆发","description":"消耗生命换取短时间攻击提升。","branch":"狂战突击","type":"增益","role":"增益","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"tenmou_advanced_16","name":"震地追击","description":"击倒目标后追加地面重击。","branch":"狂战突击","type":"追击","role":"追击","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"tenmou_advanced_17","name":"狂暴连打","description":"短时间连续挥拳压制目标。","branch":"狂战突击","type":"连击","role":"连击","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"tenmou_advanced_18","name":"天猛终极粉碎","description":"凝聚怒气发动毁灭性砸地攻击。","branch":"狂战突击","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "lyra": [
        {"id":"lyra_advanced_1","name":"弦刃飞音","description":"发射高速音刃攻击远处目标。","branch":"音律攻击","type":"远程","role":"远程","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"lyra_advanced_2","name":"黄金音波","description":"释放扇形音波造成多段伤害。","branch":"音律攻击","type":"范围","role":"范围","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"lyra_advanced_3","name":"弦音穿刺","description":"集中音束穿透直线敌人。","branch":"音律攻击","type":"穿透","role":"穿透","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"lyra_advanced_4","name":"破军协奏","description":"连续音波打击并打断敌人。","branch":"音律攻击","type":"打断","role":"打断","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"lyra_advanced_5","name":"终曲震荡","description":"高频音波造成范围硬直。","branch":"音律攻击","type":"控制","role":"控制","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"lyra_advanced_6","name":"死亡乐章","description":"持续演奏造成范围音波伤害。","branch":"音律攻击","type":"持续","role":"持续","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"lyra_advanced_7","name":"镇魂安魂曲","description":"降低敌人攻击与移动速度。","branch":"控制辅助","type":"削弱","role":"削弱","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"lyra_advanced_8","name":"催眠旋律","description":"使普通敌人短暂陷入迟缓状态。","branch":"控制辅助","type":"控制","role":"控制","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"lyra_advanced_9","name":"封音结界","description":"形成音障阻挡敌人接近。","branch":"控制辅助","type":"屏障","role":"屏障","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"lyra_advanced_10","name":"破魔和弦","description":"驱散自身控制并短暂提高抗性。","branch":"控制辅助","type":"净化","role":"净化","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"lyra_advanced_11","name":"共鸣标记","description":"标记敌人，使其受到音波伤害提高。","branch":"控制辅助","type":"易伤","role":"易伤","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"lyra_advanced_12","name":"终止音符","description":"打断敌方蓄力并造成硬直。","branch":"控制辅助","type":"打断","role":"打断","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"lyra_advanced_13","name":"治愈小夜曲","description":"恢复自身生命。","branch":"黄金协奏","type":"治疗","role":"治疗","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"lyra_advanced_14","name":"回能前奏","description":"恢复小宇宙。","branch":"黄金协奏","type":"回能","role":"回能","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"lyra_advanced_15","name":"守护交响","description":"生成音律护盾。","branch":"黄金协奏","type":"护盾","role":"护盾","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"lyra_advanced_16","name":"战意协奏","description":"短时间提高攻击与移动速度。","branch":"黄金协奏","type":"增益","role":"增益","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"lyra_advanced_17","name":"和弦共鸣","description":"控制技能命中后缩短其他技能冷却。","branch":"黄金协奏","type":"被动强化","role":"被动强化","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"lyra_advanced_18","name":"黄金终章·安魂","description":"奏响终极乐章震荡全场。","branch":"黄金协奏","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ],
    "sea_swallow": [
        {"id":"sea_swallow_advanced_1","name":"疾风刺","description":"快速突刺目标并穿过其身侧。","branch":"疾风连击","type":"突刺","role":"突刺","unlock_level":45,"cost":38,"cooldown":7},
        {"id":"sea_swallow_advanced_2","name":"双旋风刃","description":"释放两道交叉风刃。","branch":"疾风连击","type":"远程","role":"远程","unlock_level":48,"cost":38,"cooldown":9},
        {"id":"sea_swallow_advanced_3","name":"海燕连环踢","description":"快速连续踢击单体目标。","branch":"疾风连击","type":"多段","role":"多段","unlock_level":51,"cost":38,"cooldown":11},
        {"id":"sea_swallow_advanced_4","name":"旋风破阵","description":"旋身冲入敌群造成范围伤害。","branch":"疾风连击","type":"范围","role":"范围","unlock_level":54,"cost":45,"cooldown":13},
        {"id":"sea_swallow_advanced_5","name":"疾风追猎","description":"连续追击锁定目标。","branch":"疾风连击","type":"追击","role":"追击","unlock_level":57,"cost":45,"cooldown":15},
        {"id":"sea_swallow_advanced_6","name":"风暴终结踢","description":"跃起后发动强力下劈。","branch":"疾风连击","type":"终结","role":"终结","unlock_level":60,"cost":45,"cooldown":17},
        {"id":"sea_swallow_advanced_7","name":"潮汐闪身","description":"快速侧移并获得短暂闪避。","branch":"身法游击","type":"闪避","role":"闪避","unlock_level":63,"cost":52,"cooldown":7},
        {"id":"sea_swallow_advanced_8","name":"风行步","description":"短时间大幅提高移动速度。","branch":"身法游击","type":"增益","role":"增益","unlock_level":66,"cost":52,"cooldown":9},
        {"id":"sea_swallow_advanced_9","name":"回旋脱身","description":"击退近身敌人并向后撤离。","branch":"身法游击","type":"脱身","role":"脱身","unlock_level":69,"cost":52,"cooldown":11},
        {"id":"sea_swallow_advanced_10","name":"空中翻越","description":"跃过敌人并在落地时反击。","branch":"身法游击","type":"位移","role":"位移","unlock_level":72,"cost":59,"cooldown":13},
        {"id":"sea_swallow_advanced_11","name":"残影替身","description":"留下残影诱导敌人攻击落空。","branch":"身法游击","type":"替身","role":"替身","unlock_level":75,"cost":59,"cooldown":15},
        {"id":"sea_swallow_advanced_12","name":"疾风连势","description":"连续命中提高下一次技能伤害。","branch":"身法游击","type":"被动强化","role":"被动强化","unlock_level":78,"cost":59,"cooldown":17},
        {"id":"sea_swallow_advanced_13","name":"风刃乱舞","description":"向前方扇形发射密集风刃。","branch":"风暴控制","type":"范围","role":"范围","unlock_level":81,"cost":66,"cooldown":7},
        {"id":"sea_swallow_advanced_14","name":"龙卷束缚","description":"小型龙卷牵引并限制敌人。","branch":"风暴控制","type":"牵引","role":"牵引","unlock_level":84,"cost":66,"cooldown":9},
        {"id":"sea_swallow_advanced_15","name":"旋流屏障","description":"风流环绕自身抵挡轻型攻击。","branch":"风暴控制","type":"护盾","role":"护盾","unlock_level":87,"cost":66,"cooldown":11},
        {"id":"sea_swallow_advanced_16","name":"海潮震荡","description":"释放气浪打断敌人蓄力。","branch":"风暴控制","type":"打断","role":"打断","unlock_level":90,"cost":73,"cooldown":13},
        {"id":"sea_swallow_advanced_17","name":"风压领域","description":"持续降低领域内敌人的移动速度。","branch":"风暴控制","type":"领域","role":"领域","unlock_level":93,"cost":73,"cooldown":15},
        {"id":"sea_swallow_advanced_18","name":"海燕风神击","description":"化作龙卷高速穿梭战场。","branch":"风暴控制","type":"终结","role":"终结","unlock_level":96,"cost":73,"cooldown":17}
    ]
}


const DIVINE_ADVANCED_SKILLS := {
    "apollo": [
        {"id":"apollo_advanced_1","name":"日冕爆裂","description":"阿波罗施展日冕爆裂，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"突进","role":"单体","unlock_level":45,"cost":52,"cooldown":7},
        {"id":"apollo_advanced_2","name":"耀斑贯星","description":"阿波罗施展耀斑贯星，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"远程","role":"群体","unlock_level":48,"cost":52,"cooldown":9},
        {"id":"apollo_advanced_3","name":"神火连环","description":"阿波罗施展神火连环，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"冲击","role":"范围","unlock_level":51,"cost":56,"cooldown":11},
        {"id":"apollo_advanced_4","name":"日轮坠落","description":"阿波罗施展日轮坠落，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"奥义","role":"范围","unlock_level":54,"cost":56,"cooldown":13},
        {"id":"apollo_advanced_5","name":"光矛穿云","description":"阿波罗施展光矛穿云，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"连击","role":"单体","unlock_level":57,"cost":60,"cooldown":15},
        {"id":"apollo_advanced_6","name":"太阳风暴","description":"阿波罗施展太阳风暴，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"终结","role":"范围","unlock_level":60,"cost":60,"cooldown":17},
        {"id":"apollo_advanced_7","name":"光域禁锢","description":"阿波罗施展光域禁锢，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"领域","role":"群体","unlock_level":63,"cost":60,"cooldown":7},
        {"id":"apollo_advanced_8","name":"神光灼魂","description":"阿波罗施展神光灼魂，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"削弱","role":"单体","unlock_level":66,"cost":60,"cooldown":9},
        {"id":"apollo_advanced_9","name":"日蚀领域","description":"阿波罗施展日蚀领域，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"牵引","role":"群体","unlock_level":69,"cost":64,"cooldown":11},
        {"id":"apollo_advanced_10","name":"烈阳屏障","description":"阿波罗施展烈阳屏障，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"护盾","role":"防御","unlock_level":72,"cost":64,"cooldown":13},
        {"id":"apollo_advanced_11","name":"光速裁断","description":"阿波罗施展光速裁断，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"打断","role":"控制","unlock_level":75,"cost":68,"cooldown":15},
        {"id":"apollo_advanced_12","name":"日轮锁链","description":"阿波罗施展日轮锁链，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"范围","role":"群体","unlock_level":78,"cost":68,"cooldown":17},
        {"id":"apollo_advanced_13","name":"不灭日辉","description":"阿波罗施展不灭日辉，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"复苏","role":"生存","unlock_level":81,"cost":68,"cooldown":7},
        {"id":"apollo_advanced_14","name":"太阳复苏","description":"阿波罗施展太阳复苏，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"治疗","role":"恢复","unlock_level":84,"cost":68,"cooldown":9},
        {"id":"apollo_advanced_15","name":"神躯护佑","description":"阿波罗施展神躯护佑，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"护盾","role":"防御","unlock_level":87,"cost":72,"cooldown":11},
        {"id":"apollo_advanced_16","name":"神威反震","description":"阿波罗施展神威反震，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"增益","role":"自身","unlock_level":90,"cost":72,"cooldown":13},
        {"id":"apollo_advanced_17","name":"神格共鸣","description":"阿波罗施展神格共鸣，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"被动强化","role":"自身","unlock_level":93,"cost":76,"cooldown":15},
        {"id":"apollo_advanced_18","name":"宇宙日冕","description":"阿波罗施展宇宙日冕，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"奥义","role":"范围","unlock_level":96,"cost":76,"cooldown":17}
    ],
    "athena": [
        {"id":"athena_advanced_1","name":"圣矛连刺","description":"雅典娜施展圣矛连刺，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"突进","role":"单体","unlock_level":45,"cost":52,"cooldown":7},
        {"id":"athena_advanced_2","name":"胜利突击","description":"雅典娜施展胜利突击，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"远程","role":"群体","unlock_level":48,"cost":52,"cooldown":9},
        {"id":"athena_advanced_3","name":"神圣震荡","description":"雅典娜施展神圣震荡，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"冲击","role":"范围","unlock_level":51,"cost":56,"cooldown":11},
        {"id":"athena_advanced_4","name":"女神回旋击","description":"雅典娜施展女神回旋击，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"奥义","role":"范围","unlock_level":54,"cost":56,"cooldown":13},
        {"id":"athena_advanced_5","name":"战争裁断","description":"雅典娜施展战争裁断，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"连击","role":"单体","unlock_level":57,"cost":60,"cooldown":15},
        {"id":"athena_advanced_6","name":"胜利终结","description":"雅典娜施展胜利终结，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"终结","role":"范围","unlock_level":60,"cost":60,"cooldown":17},
        {"id":"athena_advanced_7","name":"和平结界","description":"雅典娜施展和平结界，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"领域","role":"群体","unlock_level":63,"cost":60,"cooldown":7},
        {"id":"athena_advanced_8","name":"神圣净化阵","description":"雅典娜施展神圣净化阵，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"削弱","role":"单体","unlock_level":66,"cost":60,"cooldown":9},
        {"id":"athena_advanced_9","name":"智慧预判","description":"雅典娜施展智慧预判，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"牵引","role":"群体","unlock_level":69,"cost":64,"cooldown":11},
        {"id":"athena_advanced_10","name":"守护光环","description":"雅典娜施展守护光环，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"护盾","role":"防御","unlock_level":72,"cost":64,"cooldown":13},
        {"id":"athena_advanced_11","name":"敌意消解","description":"雅典娜施展敌意消解，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"打断","role":"控制","unlock_level":75,"cost":68,"cooldown":15},
        {"id":"athena_advanced_12","name":"圣域封锁","description":"雅典娜施展圣域封锁，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"范围","role":"群体","unlock_level":78,"cost":68,"cooldown":17},
        {"id":"athena_advanced_13","name":"女神恩典","description":"雅典娜施展女神恩典，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"复苏","role":"生存","unlock_level":81,"cost":68,"cooldown":7},
        {"id":"athena_advanced_14","name":"神力复苏","description":"雅典娜施展神力复苏，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"治疗","role":"恢复","unlock_level":84,"cost":68,"cooldown":9},
        {"id":"athena_advanced_15","name":"神盾反击","description":"雅典娜施展神盾反击，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"护盾","role":"防御","unlock_level":87,"cost":72,"cooldown":11},
        {"id":"athena_advanced_16","name":"不屈神格","description":"雅典娜施展不屈神格，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"增益","role":"自身","unlock_level":90,"cost":72,"cooldown":13},
        {"id":"athena_advanced_17","name":"守护共鸣","description":"雅典娜施展守护共鸣，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"被动强化","role":"自身","unlock_level":93,"cost":76,"cooldown":15},
        {"id":"athena_advanced_18","name":"奥林匹斯庇护","description":"雅典娜施展奥林匹斯庇护，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"奥义","role":"范围","unlock_level":96,"cost":76,"cooldown":17}
    ],
    "hades": [
        {"id":"hades_advanced_1","name":"冥剑乱舞","description":"哈迪斯施展冥剑乱舞，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"突进","role":"单体","unlock_level":45,"cost":52,"cooldown":7},
        {"id":"hades_advanced_2","name":"黑暗裂斩","description":"哈迪斯施展黑暗裂斩，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"远程","role":"群体","unlock_level":48,"cost":52,"cooldown":9},
        {"id":"hades_advanced_3","name":"亡魂穿刺","description":"哈迪斯施展亡魂穿刺，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"冲击","role":"范围","unlock_level":51,"cost":56,"cooldown":11},
        {"id":"hades_advanced_4","name":"深渊震荡","description":"哈迪斯施展深渊震荡，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"奥义","role":"范围","unlock_level":54,"cost":56,"cooldown":13},
        {"id":"hades_advanced_5","name":"冥河斩击","description":"哈迪斯施展冥河斩击，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"连击","role":"单体","unlock_level":57,"cost":60,"cooldown":15},
        {"id":"hades_advanced_6","name":"死亡终章","description":"哈迪斯施展死亡终章，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"终结","role":"范围","unlock_level":60,"cost":60,"cooldown":17},
        {"id":"hades_advanced_7","name":"灵魂枷锁","description":"哈迪斯施展灵魂枷锁，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"领域","role":"群体","unlock_level":63,"cost":60,"cooldown":7},
        {"id":"hades_advanced_8","name":"冥河漩涡","description":"哈迪斯施展冥河漩涡，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"削弱","role":"单体","unlock_level":66,"cost":60,"cooldown":9},
        {"id":"hades_advanced_9","name":"死亡领域","description":"哈迪斯施展死亡领域，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"牵引","role":"群体","unlock_level":69,"cost":64,"cooldown":11},
        {"id":"hades_advanced_10","name":"暗影侵蚀","description":"哈迪斯施展暗影侵蚀，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"护盾","role":"防御","unlock_level":72,"cost":64,"cooldown":13},
        {"id":"hades_advanced_11","name":"亡者哀嚎","description":"哈迪斯施展亡者哀嚎，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"打断","role":"控制","unlock_level":75,"cost":68,"cooldown":15},
        {"id":"hades_advanced_12","name":"冥界封印","description":"哈迪斯施展冥界封印，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"范围","role":"群体","unlock_level":78,"cost":68,"cooldown":17},
        {"id":"hades_advanced_13","name":"不死冥躯","description":"哈迪斯施展不死冥躯，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"复苏","role":"生存","unlock_level":81,"cost":68,"cooldown":7},
        {"id":"hades_advanced_14","name":"灵魂回收","description":"哈迪斯施展灵魂回收，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"治疗","role":"恢复","unlock_level":84,"cost":68,"cooldown":9},
        {"id":"hades_advanced_15","name":"黑翼守护","description":"哈迪斯施展黑翼守护，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"护盾","role":"防御","unlock_level":87,"cost":72,"cooldown":11},
        {"id":"hades_advanced_16","name":"死亡反噬","description":"哈迪斯施展死亡反噬，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"增益","role":"自身","unlock_level":90,"cost":72,"cooldown":13},
        {"id":"hades_advanced_17","name":"冥王威压","description":"哈迪斯施展冥王威压，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"被动强化","role":"自身","unlock_level":93,"cost":76,"cooldown":15},
        {"id":"hades_advanced_18","name":"永夜神格","description":"哈迪斯施展永夜神格，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"奥义","role":"范围","unlock_level":96,"cost":76,"cooldown":17}
    ],
    "poseidon": [
        {"id":"poseidon_advanced_1","name":"三叉戟连斩","description":"波塞冬施展三叉戟连斩，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"突进","role":"单体","unlock_level":45,"cost":52,"cooldown":7},
        {"id":"poseidon_advanced_2","name":"海流贯穿","description":"波塞冬施展海流贯穿，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"远程","role":"群体","unlock_level":48,"cost":52,"cooldown":9},
        {"id":"poseidon_advanced_3","name":"怒涛冲拳","description":"波塞冬施展怒涛冲拳，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"冲击","role":"范围","unlock_level":51,"cost":56,"cooldown":11},
        {"id":"poseidon_advanced_4","name":"海皇震击","description":"波塞冬施展海皇震击，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"奥义","role":"范围","unlock_level":54,"cost":56,"cooldown":13},
        {"id":"poseidon_advanced_5","name":"深海龙卷","description":"波塞冬施展深海龙卷，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"连击","role":"单体","unlock_level":57,"cost":60,"cooldown":15},
        {"id":"poseidon_advanced_6","name":"海神终结","description":"波塞冬施展海神终结，以神级力量强化神威进攻，产生专属战斗效果。","branch":"神威进攻","type":"终结","role":"范围","unlock_level":60,"cost":60,"cooldown":17},
        {"id":"poseidon_advanced_7","name":"潮汐束缚","description":"波塞冬施展潮汐束缚，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"领域","role":"群体","unlock_level":63,"cost":60,"cooldown":7},
        {"id":"poseidon_advanced_8","name":"海界结界","description":"波塞冬施展海界结界，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"削弱","role":"单体","unlock_level":66,"cost":60,"cooldown":9},
        {"id":"poseidon_advanced_9","name":"深海压制","description":"波塞冬施展深海压制，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"牵引","role":"群体","unlock_level":69,"cost":64,"cooldown":11},
        {"id":"poseidon_advanced_10","name":"海啸领域","description":"波塞冬施展海啸领域，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"护盾","role":"防御","unlock_level":72,"cost":64,"cooldown":13},
        {"id":"poseidon_advanced_11","name":"水龙卷锁敌","description":"波塞冬施展水龙卷锁敌，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"打断","role":"控制","unlock_level":75,"cost":68,"cooldown":15},
        {"id":"poseidon_advanced_12","name":"海皇封域","description":"波塞冬施展海皇封域，以神级力量强化神域掌控，产生专属战斗效果。","branch":"神域掌控","type":"范围","role":"群体","unlock_level":78,"cost":68,"cooldown":17},
        {"id":"poseidon_advanced_13","name":"海神复苏","description":"波塞冬施展海神复苏，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"复苏","role":"生存","unlock_level":81,"cost":68,"cooldown":7},
        {"id":"poseidon_advanced_14","name":"潮汐护体","description":"波塞冬施展潮汐护体，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"治疗","role":"恢复","unlock_level":84,"cost":68,"cooldown":9},
        {"id":"poseidon_advanced_15","name":"三叉戟反击","description":"波塞冬施展三叉戟反击，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"护盾","role":"防御","unlock_level":87,"cost":72,"cooldown":11},
        {"id":"poseidon_advanced_16","name":"海皇威严","description":"波塞冬施展海皇威严，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"增益","role":"自身","unlock_level":90,"cost":72,"cooldown":13},
        {"id":"poseidon_advanced_17","name":"海洋共鸣","description":"波塞冬施展海洋共鸣，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"被动强化","role":"自身","unlock_level":93,"cost":76,"cooldown":15},
        {"id":"poseidon_advanced_18","name":"万流归海","description":"波塞冬施展万流归海，以神级力量强化不朽神格，产生专属战斗效果。","branch":"不朽神格","type":"奥义","role":"范围","unlock_level":96,"cost":76,"cooldown":17}
    ]
}

const ARMOR_STAGES := ["青铜圣衣", "白银圣衣", "黄金圣衣", "海界鳞衣", "冥衣", "神圣衣", "主神圣衣"]
const ARMOR_PARTS := ["头盔", "胸甲", "护腕", "腰甲", "腿甲"]

func get_class_skill(class_id: String) -> Dictionary:
    return DIVINE_CLASS_SKILLS.get(class_id, CLASS_SKILLS.get(class_id, CLASS_SKILLS["pegasus"])).duplicate(true)

func get_class_skill_catalog() -> Array:
    var result: Array = []
    for class_id in CLASS_SKILLS:
        var entry: Dictionary = get_class_skill(class_id)
        entry["id"] = class_id
        result.append(entry)
    for class_id in DIVINE_CLASS_SKILLS:
        var entry: Dictionary = get_class_skill(class_id)
        entry["id"] = class_id
        result.append(entry)
    return result

func get_skill_level(class_id: String) -> int:
    var levels: Dictionary = RPGState.profile.get("skill_levels", {})
    return clampi(int(levels.get(class_id, 1)), 1, 10)

func upgrade_skill(class_id: String) -> bool:
    if not CLASS_SKILLS.has(class_id) and not DIVINE_CLASS_SKILLS.has(class_id):
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
    if (not CLASS_SKILLS.has(class_id) and not DIVINE_CLASS_SKILLS.has(class_id)) or level < 1 or level > 10:
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
    var result: Array = data.get("abilities", []).duplicate(true)
    result.append_array(DIVINE_ADVANCED_SKILLS.get(class_id, ADVANCED_CLASS_SKILLS.get(class_id, ADVANCED_CLASS_SKILLS["pegasus"])).duplicate(true))
    return result

func get_skill_branches(class_id: String) -> Array:
    var branches: Array = []
    for ability in get_ability_catalog(class_id):
        var branch := str(ability.get("branch", "基础技能"))
        if not branches.has(branch):
            branches.append(branch)
    return branches

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

func reset_skill_tree(class_id: String) -> bool:
    if (not CLASS_SKILLS.has(class_id) and not DIVINE_CLASS_SKILLS.has(class_id)) or int(RPGState.profile.get("currency", 0)) < 500:
        return false
    var learned: Dictionary = RPGState.profile.get("learned_skills", {})
    var current: Array = learned.get(class_id, [class_id + "_skill_1"])
    learned[class_id] = [class_id + "_skill_1"]
    RPGState.profile["learned_skills"] = learned
    RPGState.profile["skill_points"] = int(RPGState.profile.get("skill_points", 0)) + maxi(0, current.size() - 1)
    var branches: Dictionary = RPGState.profile.get("skill_branches", {})
    branches.erase(class_id)
    RPGState.profile["skill_branches"] = branches
    var slots: Dictionary = RPGState.profile.get("skill_slots", {})
    slots[class_id] = [class_id + "_skill_1", "", "", ""]
    RPGState.profile["skill_slots"] = slots
    RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - 500
    RPGState.state_changed.emit()
    RPGState.save_slot(RPGState.active_slot)
    return true
func get_ability_data(class_id: String, ability_id: String) -> Dictionary:
    for ability in get_ability_catalog(class_id):
        if str(ability.get("id", "")) == ability_id:
            return ability.duplicate(true)
    return {}
func get_learned_skills(class_id: String) -> Array:
    var learned: Dictionary = RPGState.profile.get("learned_skills", {})
    return learned.get(class_id, [class_id + "_skill_1"]).duplicate()
func is_ability_learned(class_id: String, ability_id: String) -> bool:
    return get_learned_skills(class_id).has(ability_id)
func get_selected_branch(class_id: String) -> String:
    var branches: Dictionary = RPGState.profile.get("skill_branches", {})
    return str(branches.get(class_id, ""))
func choose_skill_branch(class_id: String, branch: String) -> bool:
    if (not CLASS_SKILLS.has(class_id) and not DIVINE_CLASS_SKILLS.has(class_id)) or not get_skill_branches(class_id).has(branch):
        return false
    var selected := get_selected_branch(class_id)
    if selected != "" and selected != branch:
        return false
    var choices: Dictionary = RPGState.profile.get("skill_branches", {})
    choices[class_id] = branch
    RPGState.profile["skill_branches"] = choices
    RPGState.state_changed.emit()
    RPGState.save_slot(RPGState.active_slot)
    return true
func learn_ability(class_id: String, ability_id: String) -> bool:
    if is_ability_learned(class_id, ability_id):
        return false
    var ability := get_ability_data(class_id, ability_id)
    if ability.is_empty() or int(RPGState.profile.get("level", 1)) < int(ability.get("unlock_level", 1)):
        return false
    if int(RPGState.profile.get("skill_points", 0)) < 1:
        return false
    var branch := str(ability.get("branch", "基础技能"))
    if branch != "基础技能":
        var selected := get_selected_branch(class_id)
        if selected == "" or selected != branch:
            return false
    var learned: Dictionary = RPGState.profile.get("learned_skills", {})
    var class_learned: Array = learned.get(class_id, [class_id + "_skill_1"])
    class_learned.append(ability_id)
    learned[class_id] = class_learned
    RPGState.profile["learned_skills"] = learned
    RPGState.profile["skill_points"] = int(RPGState.profile.get("skill_points", 0)) - 1
    RPGState.state_changed.emit()
    RPGState.save_slot(RPGState.active_slot)
    return true
func equip_ability(class_id: String, ability_id: String, slot_index: int) -> bool:
    if slot_index < 0 or slot_index > 3 or not is_ability_learned(class_id, ability_id):
        return false
    var all_slots: Dictionary = RPGState.profile.get("skill_slots", {})
    var slots: Array = all_slots.get(class_id, [class_id + "_skill_1", "", "", ""])
    while slots.size() < 4:
        slots.append("")
    for i in range(4):
        if i != slot_index and str(slots[i]) == ability_id:
            slots[i] = ""
    slots[slot_index] = ability_id
    all_slots[class_id] = slots
    RPGState.profile["skill_slots"] = all_slots
    RPGState.state_changed.emit()
    RPGState.save_slot(RPGState.active_slot)
    return true
func get_equipped_abilities(class_id: String) -> Array:
    var all_slots: Dictionary = RPGState.profile.get("skill_slots", {})
    var slots: Array = all_slots.get(class_id, [class_id + "_skill_1", "", "", ""]).duplicate()
    while slots.size() < 4:
        slots.append("")
    return slots
