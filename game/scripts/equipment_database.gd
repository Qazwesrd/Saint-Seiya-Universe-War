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
 "unknown_88_archive":{"name":"未登场星座圣衣档案","category":"雅典娜圣衣·未公开","faction":"雅典娜军","source_work":"88星座设定框架","canon_status":"未公开条目，不生成官方名称、持有者或外观","rank":"未公开","attack":0,"defense":0,"max_health":0,"unlock_level":1}
}

func get_catalog() -> Array:
    var result: Array = []
    for item_id in EQUIPMENT:
        var entry: Dictionary = EQUIPMENT[item_id].duplicate(true)
        entry["id"] = item_id
        result.append(entry)
    return result

func unlock_equipment(item_id: String) -> bool:
    if not EQUIPMENT.has(item_id):
        return false
    var data: Dictionary = EQUIPMENT[item_id]
    if int(RPGState.profile.get("level", 1)) < int(data.get("unlock_level", 1)):
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
    if not owned.has(item_id) or int(RPGState.profile.get("level", 1)) < int(EQUIPMENT[item_id].get("unlock_level", 1)):
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
