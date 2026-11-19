extends RefCounted
class_name CampaignDatabase

# Original mission structure organized around the six planned story arcs.
# Story summaries are concise design notes; final dialogue and licensed assets
# must be authored/cleared separately.
const CHAPTERS := [
    {
        "id": "galaxy_wars",
        "name": "银河战争篇",
        "order": 1,
        "description": "从训练与初次试炼开始，逐步进入银河竞技场的争夺。",
        "missions": [
            {"id":"gw_001","name":"竞技场的召集","type":"main","level":1,"description":"与竞技场引导员交谈，了解试炼规则。","objectives":[{"id":"talk_guide","text":"与引导员交谈","target":1}] ,"rewards":{"exp":80,"coins":80}},
            {"id":"gw_002","name":"初次交锋","type":"main","level":1,"description":"在竞技场完成基础战斗训练。","objectives":[{"id":"defeat_training_enemy","text":"击败训练对手","target":2}],"rewards":{"exp":160,"coins":140}},
            {"id":"gw_003","name":"强敌现身","type":"boss","level":2,"description":"观察强敌攻击预警，抓住攻击后摇反击。","objectives":[{"id":"defeat_training_boss","text":"击败训练首领","target":1}],"rewards":{"exp":260,"coins":220}}
        ]
    },
    {
        "id": "sanctuary_twelve_houses",
        "name": "圣域十二宫篇",
        "order": 2,
        "description": "踏上通往圣域的道路，逐宫挑战强敌并揭开危机。",
        "missions": [
            {"id":"s12_001","name":"通往圣域的道路","type":"main","level":5,"description":"寻找通往圣域的入口并收集线索。","objectives":[{"id":"find_sanctuary_route","text":"调查圣域入口线索","target":3}],"rewards":{"exp":400,"coins":300}},
            {"id":"s12_002","name":"黄金之试","type":"boss","level":8,"description":"挑战守宫者，学习识别范围攻击与破绽。","objectives":[{"id":"defeat_gold_guardian","text":"战胜守宫者","target":1}],"rewards":{"exp":650,"coins":480}}
        ]
    },
    {
        "id": "poseidon",
        "name": "海皇篇",
        "order": 3,
        "description": "探索海界遗迹，突破海将军的防线。",
        "missions": [
            {"id":"po_001","name":"海界异象","type":"main","level":18,"description":"调查海界能量异常并寻找入口。","objectives":[{"id":"investigate_sea_ruins","text":"调查海界遗迹","target":3}],"rewards":{"exp":900,"coins":700}},
            {"id":"po_002","name":"海将军的试炼","type":"boss","level":22,"description":"击败海界守卫，阻止能量核心失控。","objectives":[{"id":"defeat_mariner_guard","text":"击败海界守卫","target":1}],"rewards":{"exp":1300,"coins":950}}
        ]
    },
    {
        "id": "hades",
        "name": "冥王篇",
        "order": 4,
        "description": "深入冥界区域，面对冥斗士与冥界首领。",
        "missions": [
            {"id":"ha_001","name":"冥界入口","type":"main","level":35,"description":"寻找冥界通路并突破守卫。","objectives":[{"id":"clear_underworld_gate","text":"清理冥界入口守卫","target":4}],"rewards":{"exp":1800,"coins":1300}},
            {"id":"ha_002","name":"冥界决战","type":"boss","level":42,"description":"在多阶段战斗中击败冥界首领。","objectives":[{"id":"defeat_underworld_boss","text":"击败冥界首领","target":1}],"rewards":{"exp":2600,"coins":1900}}
        ]
    },
    {
        "id": "heaven",
        "name": "天界篇",
        "order": 5,
        "description": "进入天界领域，挑战更高阶的试炼。",
        "missions": [
            {"id":"he_001","name":"天界之门","type":"main","level":55,"description":"寻找开启天界之门的方法。","objectives":[{"id":"activate_heaven_gate","text":"激活天界装置","target":3}],"rewards":{"exp":3500,"coins":2500}},
            {"id":"he_002","name":"神域试炼","type":"boss","level":62,"description":"完成神域首领战，掌握高强度战斗节奏。","objectives":[{"id":"defeat_divine_trial","text":"完成神域试炼","target":1}],"rewards":{"exp":4800,"coins":3400}}
        ]
    },
    {
        "id": "original_final",
        "name": "原创终极篇",
        "order": 6,
        "description": "围绕九大职业的命运展开原创终局故事。",
        "missions": [
            {"id":"of_001","name":"九星共鸣","type":"class","level":75,"description":"完成当前职业的专属试炼，唤醒九星共鸣。","objectives":[{"id":"complete_class_trial","text":"完成职业专属试炼","target":1}],"rewards":{"exp":6000,"coins":4200}},
            {"id":"of_002","name":"宇宙之战","type":"final_boss","level":85,"description":"迎战原创终极敌人，完成最终挑战。","objectives":[{"id":"defeat_final_boss","text":"击败终极敌人","target":1}],"rewards":{"exp":10000,"coins":8000}}
        ]
    }
]

static func get_chapters() -> Array:
    return CHAPTERS.duplicate(true)

static func get_chapter(chapter_id: String) -> Dictionary:
    for chapter in CHAPTERS:
        if str(chapter.get("id", "")) == chapter_id:
            return chapter.duplicate(true)
    return {}

static func get_mission(mission_id: String) -> Dictionary:
    for chapter in CHAPTERS:
        for mission in chapter.get("missions", []):
            if str(mission.get("id", "")) == mission_id:
                return mission.duplicate(true)
    return {}

static func get_first_mission_id() -> String:
    return str(CHAPTERS[0]["missions"][0]["id"])
