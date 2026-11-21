extends Node

# 独立装备图鉴：类别、作品连续性和神明神衣分开记录。
const EQUIPMENT := {
 "glory_heavenly_standard":{"name":"天衣·天斗士通用制式","category":"天衣 Glory","faction":"天界","source_work":"游戏原创通用装备","canon_status":"原创，不代表原作人物专属天衣","rank":"天界级","attack":18,"defense":22,"max_health":120,"unlock_level":45},
 "god_cloth_archive":{"name":"青铜圣衣·神圣衣形态档案","category":"神圣衣 God Cloth","faction":"雅典娜军","source_work":"原作漫画/动画对应角色形态","canon_status":"形态分类档案，具体装备按角色版本建档","rank":"神圣级","attack":22,"defense":18,"max_health":90,"unlock_level":60},
 "athena_divine_garment":{"name":"雅典娜神衣","category":"神明专属神衣","faction":"雅典娜","source_work":"原作相关作品","canon_status":"神明装备，与圣斗士神圣衣区分","rank":"主神级","attack":20,"defense":32,"max_health":220,"unlock_level":70},
 "poseidon_scale":{"name":"波塞冬海皇鳞衣","category":"鳞衣 Scale","faction":"海界","source_work":"原作海皇篇","canon_status":"海皇装备体系","rank":"主神级","attack":30,"defense":24,"max_health":160,"unlock_level":70},
 "hades_divine_garment":{"name":"哈迪斯冥王神衣","category":"神明专属神衣","faction":"冥界","source_work":"原作冥王篇","canon_status":"神明装备，与冥斗士冥衣分开","rank":"主神级","attack":34,"defense":26,"max_health":170,"unlock_level":70},
 "odin_god_robe":{"name":"奥丁神斗衣","category":"神斗衣 God Robe","faction":"北欧仙宫","source_work":"北欧篇","canon_status":"独立于雅典娜圣衣体系","rank":"神斗级","attack":24,"defense":28,"max_health":150,"unlock_level":65},
 "saturn_chronotector":{"name":"刻衣·萨图恩系列档案","category":"刻衣 Chronotector","faction":"时间之神","source_work":"圣斗士星矢Ω","canon_status":"衍生作品独立装备体系","rank":"刻衣级","attack":28,"defense":26,"max_health":150,"unlock_level":70},
 "glory_unverified_archive":{"name":"天斗士专属天衣档案（待逐件核实）","category":"天衣 Glory","faction":"天界","source_work":"天界篇相关作品","canon_status":"系列档案；具体名称、持有者与造型待核实","rank":"未定","attack":0,"defense":0,"max_health":0,"unlock_level":45},
 "unknown_88_archive":{"name":"未登场星座圣衣档案","category":"雅典娜圣衣·未公开","faction":"雅典娜军","source_work":"88星座设定框架","canon_status":"未公开条目，不生成官方名称、持有者或外观","rank":"未公开","attack":0,"defense":0,"max_health":0,"unlock_level":1},
 "heavenly_glory":{"name":"天斗士制式天衣","category":"天衣 Glory","faction":"天界","source_work":"天界篇相关设定","canon_status":"游戏通用装备档案；不代表特定原作人物造型","rank":"天界级","attack":18,"defense":22,"max_health":120,"unlock_level":45},
 "apollo_divine_relic":{"name":"阿波罗神衣","category":"神明专属神衣","faction":"太阳神系","source_work":"真红少年传说相关扩展","canon_status":"游戏职业装备数据；具体造型以授权美术为准","rank":"主神级","attack":38,"defense":30,"max_health":240,"unlock_level":70},
 "athena_divine_relic":{"name":"雅典娜神衣","category":"神明专属神衣","faction":"雅典娜军","source_work":"圣斗士系列相关作品","canon_status":"神明装备，与圣斗士神圣衣区分","rank":"主神级","attack":28,"defense":42,"max_health":300,"unlock_level":70},
 "hades_divine_relic":{"name":"哈迪斯冥王神衣","category":"神明专属神衣","faction":"冥界","source_work":"冥王篇","canon_status":"神明装备，与冥斗士冥衣区分","rank":"主神级","attack":42,"defense":36,"max_health":270,"unlock_level":70},
 "poseidon_divine_relic":{"name":"波塞冬海皇鳞衣","category":"鳞衣 Scale","faction":"海界","source_work":"海皇篇","canon_status":"海皇装备体系","rank":"主神级","attack":40,"defense":34,"max_health":260,"unlock_level":70},
 "zeus_divine_relic":{"name":"宙斯神衣档案","category":"神明专属神衣","faction":"奥林匹斯","source_work":"原作提及，未正式正面登场","canon_status":"概念档案；游戏原创数值，不宣称官方造型","rank":"至高神级","attack":48,"defense":44,"max_health":320,"unlock_level":70},
 "artemis_divine_relic":{"name":"阿尔忒弥斯神衣","category":"神明专属神衣","faction":"月之女神","source_work":"天界篇相关作品","canon_status":"游戏职业装备数据；具体造型以授权美术为准","rank":"主神级","attack":38,"defense":40,"max_health":280,"unlock_level":70},
 "hypnos_divine_relic":{"name":"修普诺斯神衣","category":"神明专属神衣","faction":"睡神","source_work":"冥王篇","canon_status":"神明装备；与双子神设定对应","rank":"主神级","attack":34,"defense":44,"max_health":280,"unlock_level":70},
 "thanatos_divine_relic":{"name":"达纳托斯神衣","category":"神明专属神衣","faction":"死神","source_work":"冥王篇","canon_status":"神明装备；与双子神设定对应","rank":"主神级","attack":44,"defense":36,"max_health":270,"unlock_level":70},
 "odin_divine_relic":{"name":"奥丁神斗衣","category":"神斗衣 God Robe","faction":"北欧仙宫","source_work":"北欧篇","canon_status":"独立于雅典娜圣衣体系","rank":"主神级","attack":38,"defense":42,"max_health":290,"unlock_level":70},
 "ares_divine_relic":{"name":"阿瑞斯战神衣","category":"神明专属神衣","faction":"战神","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":48,"defense":34,"max_health":280,"unlock_level":70},
 "eris_divine_relic":{"name":"厄里斯神衣","category":"神明专属神衣","faction":"纷争女神","source_work":"邪神厄里斯","canon_status":"游戏职业装备数据；具体造型以授权美术为准","rank":"主神级","attack":40,"defense":32,"max_health":250,"unlock_level":70},
 "abel_divine_relic":{"name":"亚伯太阳神衣","category":"神明专属神衣","faction":"太阳神","source_work":"真红少年传说","canon_status":"游戏职业装备数据；具体造型以授权美术为准","rank":"主神级","attack":46,"defense":38,"max_health":290,"unlock_level":70},
 "lucifer_divine_relic":{"name":"路西法堕天神衣","category":"神明专属神衣","faction":"堕天使","source_work":"最终圣战的战士们","canon_status":"游戏职业装备数据；具体造型以授权美术为准","rank":"主神级","attack":46,"defense":34,"max_health":280,"unlock_level":70},
 "saturn_divine_relic":{"name":"萨图恩刻衣","category":"刻衣 Chronotector","faction":"时间之神","source_work":"圣斗士星矢Ω","canon_status":"衍生作品独立装备体系","rank":"主神级","attack":48,"defense":44,"max_health":310,"unlock_level":70},
 "pallas_divine_relic":{"name":"帕拉斯刻衣","category":"刻衣 Chronotector","faction":"帕拉斯军","source_work":"圣斗士星矢Ω","canon_status":"衍生作品独立装备体系","rank":"主神级","attack":40,"defense":38,"max_health":280,"unlock_level":70},
 "chronos_divine_relic":{"name":"柯罗诺斯神衣","category":"神明专属神衣","faction":"时间神","source_work":"Episode G 系列相关扩展","canon_status":"与泰坦克洛诺斯区分；游戏职业装备数据","rank":"至高神级","attack":50,"defense":46,"max_health":330,"unlock_level":70},
 "hera_divine_relic":{"name":"赫拉神衣","category":"神明专属神衣","faction":"天后","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":34,"defense":46,"max_health":300,"unlock_level":70},
 "demeter_divine_relic":{"name":"德墨忒尔神衣","category":"神明专属神衣","faction":"丰饶女神","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":30,"defense":44,"max_health":310,"unlock_level":70},
 "hestia_divine_relic":{"name":"赫斯提亚神衣","category":"神明专属神衣","faction":"炉灶女神","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":32,"defense":48,"max_health":320,"unlock_level":70},
 "hermes_divine_relic":{"name":"赫尔墨斯神衣","category":"神明专属神衣","faction":"神使","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":44,"defense":32,"max_health":250,"unlock_level":70},
 "hephaestus_divine_relic":{"name":"赫淮斯托斯神衣","category":"神明专属神衣","faction":"锻造之神","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":40,"defense":50,"max_health":330,"unlock_level":70},
 "aphrodite_divine_relic":{"name":"阿佛洛狄忒神衣","category":"神明专属神衣","faction":"爱与美之神","source_work":"希腊神话扩展","canon_status":"游戏原创职业装备，不代表原作正式造型","rank":"扩展神级","attack":36,"defense":38,"max_health":280,"unlock_level":70},
 "aries_gold_cloth":{"name":"白羊座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":18,"defense":17,"max_health":105,"unlock_level":30},
 "taurus_gold_cloth":{"name":"金牛座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":19,"defense":20,"max_health":113,"unlock_level":30},
 "gemini_gold_cloth":{"name":"双子座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":20,"defense":18,"max_health":121,"unlock_level":30},
 "cancer_gold_cloth":{"name":"巨蟹座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":21,"defense":21,"max_health":129,"unlock_level":30},
 "leo_gold_cloth":{"name":"狮子座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":18,"defense":19,"max_health":105,"unlock_level":30},
 "virgo_gold_cloth":{"name":"处女座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":19,"defense":17,"max_health":113,"unlock_level":30},
 "libra_gold_cloth":{"name":"天秤座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":20,"defense":20,"max_health":121,"unlock_level":30},
 "scorpio_gold_cloth":{"name":"天蝎座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":21,"defense":18,"max_health":129,"unlock_level":30},
 "sagittarius_gold_cloth":{"name":"射手座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":18,"defense":21,"max_health":105,"unlock_level":30},
 "capricorn_gold_cloth":{"name":"摩羯座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":19,"defense":19,"max_health":113,"unlock_level":30},
 "aquarius_gold_cloth":{"name":"水瓶座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":20,"defense":17,"max_health":121,"unlock_level":30},
 "pisces_gold_cloth":{"name":"双鱼座黄金圣衣","category":"黄金圣衣 Gold Cloth","faction":"雅典娜军","source_work":"十二宫篇","canon_status":"黄金圣衣星座体系；游戏装备数值，不代表具体角色模型","rank":"黄金级","attack":21,"defense":20,"max_health":129,"unlock_level":30},
 "bronze_cloth_archive":{"name":"青铜圣衣通用档案","category":"青铜圣衣 Bronze Cloth","faction":"雅典娜军","source_work":"银河战争篇","canon_status":"通用档案；各星座外观由独立资源定义","rank":"青铜级","attack":4,"defense":5,"max_health":35,"unlock_level":1},
 "silver_cloth_archive":{"name":"白银圣衣通用档案","category":"白银圣衣 Silver Cloth","faction":"雅典娜军","source_work":"圣域篇","canon_status":"通用档案；不虚构未确认持有者","rank":"白银级","attack":10,"defense":11,"max_health":65,"unlock_level":20},
 "surplice_general":{"name":"冥斗士通用冥衣","category":"冥衣 Surplice","faction":"冥界","source_work":"冥王篇","canon_status":"冥衣体系通用装备档案","rank":"冥界级","attack":18,"defense":17,"max_health":100,"unlock_level":40},
 "mariner_scale_general":{"name":"海斗士通用鳞衣","category":"鳞衣 Scale","faction":"海界","source_work":"海皇篇","canon_status":"鳞衣体系通用装备档案","rank":"海界级","attack":17,"defense":18,"max_health":105,"unlock_level":35},
 "god_robe_general":{"name":"神斗士通用神斗衣","category":"神斗衣 God Robe","faction":"北欧仙宫","source_work":"北欧篇","canon_status":"神斗衣体系通用装备档案","rank":"神斗级","attack":20,"defense":20,"max_health":120,"unlock_level":45},
 "dark_pegasus_cloth":{"name":"暗黑天马座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"银河战争篇·暗黑圣斗士","canon_status":"原作暗黑天马座圣衣；本作数值与强化效果为游戏设定","rank":"暗黑青铜级","class_id":"pegasus","attack":16,"defense":10,"max_health":76,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"流星突袭：攻击属性强化"},
 "dark_dragon_cloth":{"name":"暗黑天龙座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"银河战争篇·暗黑圣斗士","canon_status":"原作暗黑天龙座圣衣；本作数值与强化效果为游戏设定","rank":"暗黑青铜级","class_id":"dragon","attack":12,"defense":17,"max_health":102,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"暗黑龙盾：防御与生命强化"},
 "dark_cygnus_cloth":{"name":"暗黑白鸟座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"银河战争篇·暗黑圣斗士","canon_status":"原作暗黑白鸟座圣衣；本作数值与强化效果为游戏设定","rank":"暗黑青铜级","class_id":"cygnus","attack":15,"defense":13,"max_health":88,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"黑冰共鸣：攻防均衡强化"},
 "dark_andromeda_cloth":{"name":"暗黑仙女座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"银河战争篇·暗黑圣斗士","canon_status":"原作暗黑仙女座圣衣；本作数值与强化效果为游戏设定","rank":"暗黑青铜级","class_id":"andromeda","attack":15,"defense":12,"max_health":86,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"暗黑锁链：攻防均衡强化"},
 "dark_phoenix_cloth":{"name":"暗黑凤凰座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"游戏原创扩展·暗黑凤凰试炼","canon_status":"游戏原创扩展装备，并非原作暗黑四天王正式成员装备","rank":"暗黑青铜级","class_id":"phoenix","attack":18,"defense":10,"max_health":82,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"黑炎重燃：攻击强化"},
 "dark_sea_dragon_cloth":{"name":"暗黑海龙圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"游戏原创扩展·暗黑海龙试炼","canon_status":"游戏原创扩展装备；与海皇七将军海龙鳞衣区分","rank":"暗黑青铜级","class_id":"sea_dragon","attack":17,"defense":12,"max_health":90,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"深渊潮汐：攻击与生命强化"},
 "dark_tenmou_cloth":{"name":"暗黑天猛座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"游戏原创扩展·暗黑天猛试炼","canon_status":"游戏原创扩展职业装备，不宣称为原作正式圣衣","rank":"暗黑青铜级","class_id":"tenmou","attack":14,"defense":15,"max_health":98,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"暗影壁垒：防御强化"},
 "dark_lyra_cloth":{"name":"暗黑天琴座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"游戏原创扩展·暗黑天琴试炼","canon_status":"游戏原创扩展职业装备，不宣称为原作正式圣衣","rank":"暗黑青铜级","class_id":"lyra","attack":18,"defense":9,"max_health":78,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"幽冥音波：攻击强化"},
 "dark_sea_swallow_cloth":{"name":"暗黑海燕座圣衣","category":"黑暗圣衣 Dark Cloth","faction":"黑暗圣斗士","source_work":"游戏原创扩展·暗黑海燕试炼","canon_status":"游戏原创扩展职业装备，不宣称为原作正式圣衣","rank":"暗黑青铜级","class_id":"sea_swallow","attack":15,"defense":11,"max_health":86,"unlock_level":12,"required_chapter":"galaxy_wars","special_effect":"暗流疾行：生命与攻防均衡强化"},
 "platinum_cloth_archive":{"name":"白金圣衣·星辉制式","category":"白金圣衣 Platinum Cloth","faction":"星辉圣域","source_work":"游戏原创高阶圣衣体系","canon_status":"本作原创装备等级，不属于原作已确认的官方圣衣等级","rank":"白金级","attack":34,"defense":32,"max_health":220,"unlock_level":55,"required_chapter":"original_final","special_effect":"星辉共鸣：全面提升攻防与生命"} ,
}

func get_catalog() -> Array:
    var result: Array = []
    for item_id in EQUIPMENT:
        var entry: Dictionary = EQUIPMENT[item_id].duplicate(true)
        entry["id"] = item_id
        result.append(entry)
    return result

func _meets_story_requirement(data: Dictionary) -> bool:
    var required_chapter := str(data.get("required_chapter", ""))
    if required_chapter.is_empty():
        return true
    for chapter in CampaignManager.get_chapter_overview():
        if str(chapter.get("id", "")) == required_chapter:
            return bool(chapter.get("completed", false))
    return false

func _matches_current_class(data: Dictionary) -> bool:
    var required_class := str(data.get("class_id", ""))
    return required_class.is_empty() or required_class == str(RPGState.profile.get("class_id", "pegasus"))

func unlock_equipment(item_id: String) -> bool:
    if not EQUIPMENT.has(item_id):
        return false
    var data: Dictionary = EQUIPMENT[item_id]
    if int(RPGState.profile.get("level", 1)) < int(data.get("unlock_level", 1)) or not _meets_story_requirement(data) or not _matches_current_class(data):
        return false
    var previous: Dictionary = RPGState.profile.duplicate(true)
    var owned: Array = RPGState.profile.get("owned_relics", []).duplicate()
    if owned.has(item_id):
        return false
    owned.append(item_id)
    RPGState.profile["owned_relics"] = owned
    if not RPGState.save_slot(RPGState.active_slot):
        RPGState.profile = previous
        return false
    RPGState.state_changed.emit()
    EventBus.player_profile_changed.emit(RPGState.profile.duplicate(true))
    return true

func equip_relic(item_id: String) -> bool:
    if not EQUIPMENT.has(item_id):
        return false
    var owned: Array = RPGState.profile.get("owned_relics", [])
    if not owned.has(item_id) or int(RPGState.profile.get("level", 1)) < int(EQUIPMENT[item_id].get("unlock_level", 1)) or not _meets_story_requirement(EQUIPMENT[item_id]) or not _matches_current_class(EQUIPMENT[item_id]):
        return false
    var previous: Dictionary = RPGState.profile.duplicate(true)
    RPGState.profile["equipped_relic"] = item_id
    if not RPGState.save_slot(RPGState.active_slot):
        RPGState.profile = previous
        return false
    RPGState.state_changed.emit()
    EventBus.player_profile_changed.emit(RPGState.profile.duplicate(true))
    return true

func get_bonus_stats() -> Dictionary:
    var item_id := str(RPGState.profile.get("equipped_relic", ""))
    var empty := {"attack":0.0,"defense":0.0,"max_health":0.0}
    if not EQUIPMENT.has(item_id) or not RPGState.profile.get("owned_relics", []).has(item_id):
        return empty
    var item: Dictionary = EQUIPMENT[item_id]
    return {"attack":float(item.get("attack",0)),"defense":float(item.get("defense",0)),"max_health":float(item.get("max_health",0))}

func get_equipped_relic() -> Dictionary:
    var item_id := str(RPGState.profile.get("equipped_relic", ""))
    if not EQUIPMENT.has(item_id):
        return {}
    var result: Dictionary = EQUIPMENT[item_id].duplicate(true)
    result["id"] = item_id
    return result
