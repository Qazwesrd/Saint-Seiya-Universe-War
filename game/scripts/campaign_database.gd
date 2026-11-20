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
            {"id":"s12_001","name":"通往圣域的道路","type":"main","level":5,"description":"在教皇厅危机爆发后，青铜圣斗士赶赴圣域；沿途调查入口与守卫留下的线索。","story_beat":"抵达圣域外围，确认雅典娜正处于危机之中。","objectives":[{"id":"find_sanctuary_route","text":"调查圣域入口线索","target":3}],"rewards":{"exp":400,"coins":300}},
            {"id":"s12_002","name":"白羊宫的修复者","type":"story","level":8,"description":"白羊座穆说明圣衣修复与十二宫试炼的关键；此段以交谈和圣衣修复教学为主，不强行与穆战斗。","story_beat":"穆帮助青铜圣衣恢复，并说明通过十二宫的时间限制。","objectives":[{"id":"talk_to_mu","text":"与白羊座穆交谈并完成圣衣修复指引","target":1}],"rewards":{"exp":650,"coins":480}},
            {"id":"s12_003","name":"金牛宫：黄金野牛","type":"boss","level":10,"description":"突破金牛宫防线，在阿鲁迪巴面前证明青铜圣斗士的决心。","story_beat":"与金牛座阿鲁迪巴交锋，战斗结果保留其认可与放行的剧情走向。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_taurus","count":1,"boss":true}]}]},"objectives":[{"id":"defeat_taurus_trial","text":"通过金牛宫的阿鲁迪巴试炼","target":1}],"rewards":{"exp":900,"coins":650}},
            {"id":"s12_004","name":"双子宫：迷失的异次元","type":"story_battle","level":12,"description":"在双子宫遭遇空间与幻象阻隔，寻找正确道路；本段先处理幻象，不提前揭露教皇真实身份。","story_beat":"双子宫的异次元迷宫阻断前进路线。","encounter":{"waves":[{"spawns":[{"archetype_id":"gemini_illusion","count":2}]}]},"objectives":[{"id":"break_gemini_illusion","text":"击破双子宫幻象","target":2}],"rewards":{"exp":1050,"coins":760}},
            {"id":"s12_005","name":"巨蟹宫：黄泉比良坂","type":"boss","level":14,"description":"面对巨蟹座迪斯马斯克，以战斗与剧情演出表现其残酷作风及紫龙的反抗。","story_beat":"紫龙与迪斯马斯克的冲突推动巨蟹宫剧情。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_cancer","count":1,"boss":true}]}]},"objectives":[{"id":"defeat_cancer_mask","text":"击败巨蟹宫的迪斯马斯克","target":1}],"rewards":{"exp":1200,"coins":850}},
            {"id":"s12_006","name":"狮子宫：黄金之拳","type":"story_battle","level":16,"description":"面对被操纵的狮子座艾欧里亚；剧情重点是解除控制并恢复其意志，而非将其作为反派处决。","story_beat":"星矢在激战中唤醒艾欧里亚的意志。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_leo_controlled","count":1,"boss":true}]}]},"objectives":[{"id":"awaken_leo_aiolia","text":"在狮子宫战斗中唤醒艾欧里亚","target":1}],"rewards":{"exp":1350,"coins":950}},
            {"id":"s12_007","name":"处女宫：第八感的试炼","type":"boss","level":18,"description":"挑战处女座沙加的强大感官与防御；以阶段机制表现感官剥夺和小宇宙压迫。","story_beat":"沙加展示黄金圣斗士与第七感层次的差距。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_virgo","count":1,"boss":true}]}]},"objectives":[{"id":"survive_virgo_trial","text":"完成处女宫的沙加试炼","target":1}],"rewards":{"exp":1500,"coins":1050}},
            {"id":"s12_008","name":"天秤宫：老师的遗产","type":"story","level":19,"description":"天秤座童虎通过远程指引与天秤武器的选择帮助青铜圣斗士继续前进；不虚构与童虎的正面对决。","story_beat":"天秤武器成为突破后续危机的重要助力。","objectives":[{"id":"receive_libra_weapons","text":"取得天秤武器的支援","target":1}],"rewards":{"exp":900,"coins":700}},
            {"id":"s12_009","name":"天蝎宫：猩红毒针","type":"boss","level":20,"description":"面对天蝎座米罗的猩红毒针，战斗机制强调连续命中、倒计时压力与最后一击的抉择。","story_beat":"米罗以猩红毒针检验青铜圣斗士的意志。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_scorpio","count":1,"boss":true}]}]},"objectives":[{"id":"pass_scorpio_trial","text":"通过米罗的猩红毒针试炼","target":1}],"rewards":{"exp":1650,"coins":1150}},
            {"id":"s12_010","name":"人马宫：黄金箭的托付","type":"story","level":21,"description":"在射手座遗迹中接受艾俄洛斯留下的考验与托付；这是剧情试炼，不安排艾俄洛斯作为存活敌人登场。","story_beat":"艾俄洛斯留下的遗志指引众人守护雅典娜。","objectives":[{"id":"claim_sagittarius_legacy","text":"完成射手座遗迹试炼","target":1}],"rewards":{"exp":1000,"coins":750}},
            {"id":"s12_011","name":"摩羯宫：圣剑断钢","type":"boss","level":22,"description":"与摩羯座修罗交战，突出圣剑攻击的直线预警、格挡与反击窗口。","story_beat":"修罗与紫龙的战斗导向其立场转变与圣剑传承。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_capricorn","count":1,"boss":true}]}]},"objectives":[{"id":"resolve_capricorn_shura","text":"完成修罗的圣剑试炼","target":1}],"rewards":{"exp":1800,"coins":1250}},
            {"id":"s12_012","name":"宝瓶宫：冰之师徒","type":"boss","level":23,"description":"与水瓶座卡妙交战，以冰冻、解冻窗口和极光处刑的蓄力预警表现师徒对决。","story_beat":"冰河在卡妙的试炼中直面自己的道路。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_aquarius","count":1,"boss":true}]}]},"objectives":[{"id":"resolve_aquarius_camus","text":"完成卡妙的冰之试炼","target":1}],"rewards":{"exp":1950,"coins":1350}},
            {"id":"s12_013","name":"双鱼宫：玫瑰的尽头","type":"boss","level":24,"description":"突破双鱼宫的玫瑰防线，与双鱼座阿布罗狄交战，推进通往教皇厅的最后道路。","story_beat":"青铜圣斗士穿过双鱼宫，直面教皇厅的最终危机。","encounter":{"waves":[{"spawns":[{"archetype_id":"gold_pisces","count":1,"boss":true}]}]},"objectives":[{"id":"defeat_pisces_aphrodite","text":"突破阿布罗狄的玫瑰防线","target":1}],"rewards":{"exp":2100,"coins":1450}},
            {"id":"s12_014","name":"教皇厅：双子座的真相","type":"final_boss","level":26,"description":"抵达教皇厅，揭开教皇背后的真相并阻止其伤害雅典娜；战斗分阶段呈现幻象、黄金圣衣力量与最终决战。","story_beat":"撒加的双重人格与雅典娜的危机在教皇厅迎来高潮。","encounter":{"waves":[{"spawns":[{"archetype_id":"pope_saga","count":1,"boss":true}]}]},"objectives":[{"id":"defeat_pope_saga","text":"阻止教皇厅的最终危机","target":1}],"rewards":{"exp":3000,"coins":2200}}
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
