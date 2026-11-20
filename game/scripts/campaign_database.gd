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
        "id": "asgard",
        "name": "北欧仙宫篇（动画篇章）",
        "order": 3,
        "description": "承接圣域篇后的动画原创北欧篇章：调查希路达与奥丁圣衣危机，依次面对七名神斗士。",
        "missions": [
            {"id":"as_001","name":"北欧的异变","type":"main","level":28,"description":"前往北欧调查希路达祈祷异常与冰雪灾变。","objectives":[{"id":"asgard_investigate","text":"调查北欧异变线索","target":1}],"rewards":{"exp":1500,"coins":1100}},
            {"id":"as_002","name":"神斗士托尔","type":"boss","level":29,"description":"与阿尔法星神斗士托尔交战，躲避巨斧重击。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_thor","count":1,"boss":true}]}]},"objectives":[{"id":"asgard_thor","text":"通过托尔的巨斧试炼","target":1}],"rewards":{"exp":1700,"coins":1250}},
            {"id":"as_003","name":"芬里尔的狼群","type":"boss","level":30,"description":"面对贝塔星神斗士芬里尔与狼群协同攻击。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_fenrir","count":1,"boss":true},{"archetype_id":"asgard_wolf","count":2}]}]},"objectives":[{"id":"asgard_fenrir","text":"击退芬里尔与狼群","target":1}],"rewards":{"exp":1800,"coins":1300}},
            {"id":"as_004","name":"冰河与哈根","type":"boss","level":31,"description":"面对伽马星神斗士哈根的冰火双重攻势。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_hagen","count":1,"boss":true}]}]},"objectives":[{"id":"asgard_hagen","text":"通过哈根的冰火试炼","target":1}],"rewards":{"exp":1900,"coins":1380}},
            {"id":"as_005","name":"琴声与野心","type":"boss","level":32,"description":"与德尔塔星神斗士米伊美交战，识破音律与幻影。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_mime","count":1,"boss":true}]}]},"objectives":[{"id":"asgard_mime","text":"破解米伊美的音律攻击","target":1}],"rewards":{"exp":2000,"coins":1450}},
            {"id":"as_006","name":"仙宫的阴谋","type":"boss","level":33,"description":"面对艾普西隆星神斗士阿鲁贝利西的紫水晶封印。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_alberich","count":1,"boss":true}]}]},"objectives":[{"id":"asgard_alberich","text":"突破阿鲁贝利西的封印","target":1}],"rewards":{"exp":2100,"coins":1520}},
            {"id":"as_007","name":"双子神斗士","type":"boss","level":34,"description":"依次面对齐格弗里德麾下的捷克弗里德与巴度，揭开双子星的秘密。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_syd","count":1,"boss":true}]},{"spawns":[{"archetype_id":"god_warrior_bud","count":1,"boss":true}]}]},"objectives":[{"id":"asgard_syd_bud","text":"通过捷克弗里德与巴度的双重试炼","target":2}],"rewards":{"exp":2300,"coins":1650}},
            {"id":"as_008","name":"奥丁神斗士齐格弗里德","type":"final_boss","level":35,"description":"迎战最强神斗士齐格弗里德，终结北欧仙宫危机并承接海界篇。","encounter":{"waves":[{"spawns":[{"archetype_id":"god_warrior_siegfried","count":1,"boss":true}]}]},"objectives":[{"id":"asgard_siegfried","text":"击败齐格弗里德","target":1}],"rewards":{"exp":2600,"coins":1900}}
        ]
    },
    {
        "id": "poseidon",
        "name": "海皇篇",
        "order": 4,
        "description": "承接北欧仙宫篇，救援被海皇势力带走的雅典娜，突破海底神殿七大支柱与七位海将军，最终迎战波塞冬。",
        "missions": [
            {"id":"po_001","name":"雅典娜被囚与海界入口","type":"main","level":38,"description":"调查海皇势力的行动，确认雅典娜被带往海底神殿，寻找海界入口。","objectives":[{"id":"poseidon_find_entry","text":"找到海底神殿入口","target":1}],"rewards":{"exp":2600,"coins":1850}},
            {"id":"po_002","name":"海马将军：拜安","type":"boss","level":39,"description":"挑战海马座巴尔安的神风攻击，突破北太平洋之柱防线。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_baian","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_baian","text":"击败海马将军拜安","target":1}],"rewards":{"exp":2800,"coins":2000}},
            {"id":"po_003","name":"六圣兽：伊奥","type":"boss","level":40,"description":"应对海魔女伊奥的六圣兽组合攻击，逐一破解不同形态。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_io","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_io","text":"击败六圣兽伊奥","target":1}],"rewards":{"exp":3000,"coins":2150}},
            {"id":"po_004","name":"海皇子：克修拉","type":"boss","level":41,"description":"面对海皇子克修拉的黄金枪与昆达里尼小宇宙防御。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_krishna","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_krishna","text":"击败海皇子克修拉","target":1}],"rewards":{"exp":3200,"coins":2300}},
            {"id":"po_005","name":"海魔女：卡萨","type":"boss","level":42,"description":"识破卡萨变换外形与读取内心弱点的幻术。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_kasa","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_kasa","text":"识破并击败卡萨","target":1}],"rewards":{"exp":3400,"coins":2450}},
            {"id":"po_006","name":"海魔兽：艾萨克","type":"boss","level":43,"description":"与海魔兽座艾萨克交锋，躲避冰系突进与寒流攻击。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_isaac","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_isaac","text":"击败海魔兽艾萨克","target":1}],"rewards":{"exp":3600,"coins":2600}},
            {"id":"po_007","name":"海妖：苏兰特","type":"boss","level":44,"description":"面对海妖座苏兰特的笛声控制与音波压制。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_sorrento","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_sorrento","text":"击败海妖苏兰特","target":1}],"rewards":{"exp":3800,"coins":2750}},
            {"id":"po_008","name":"海龙：加隆","type":"boss","level":45,"description":"揭开海龙将军加隆的真实身份，经历与其的决战。","encounter":{"waves":[{"spawns":[{"archetype_id":"mariner_kanon","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_kanon","text":"击败海龙将军加隆","target":1}],"rewards":{"exp":4100,"coins":2950}},
            {"id":"po_009","name":"七大支柱的最终防线","type":"main","level":46,"description":"在海将军防线被突破后，完成七大支柱与主支柱的剧情目标，为最终决战开路。","objectives":[{"id":"poseidon_pillars","text":"完成七大支柱剧情目标","target":7}],"rewards":{"exp":4400,"coins":3200}},
            {"id":"po_010","name":"海皇波塞冬","type":"final_boss","level":48,"description":"面对觉醒的海皇波塞冬，阻止海水淹没大地并救出雅典娜。","encounter":{"waves":[{"spawns":[{"archetype_id":"poseidon_emperor","count":1,"boss":true}]}]},"objectives":[{"id":"poseidon_final","text":"击败海皇波塞冬并完成海界决战","target":1}],"rewards":{"exp":6000,"coins":4500}}
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
