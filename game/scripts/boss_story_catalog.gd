extends RefCounted
class_name BossStoryCatalog
const CHAPTER_TITLES := {"galaxy_wars":"银河战争篇 · 银河竞技场","sanctuary_twelve_houses":"圣域十二宫篇 · 十二宫之战","asgard":"北欧仙宫篇 · 奥丁神域","poseidon":"海界篇 · 七大洋之柱","hades":"冥界篇 · 极乐净土","heaven":"天界篇 · 众神之域","original_final":"原创终章 · 宇宙之战"}
const SIGNATURE_SCENES := {
"galaxy_wars":{"intro":[{"speaker":"旁白","text":"银河竞技场的欢呼声渐渐远去。训练场中央，一股强大的小宇宙正在苏醒。"},{"speaker":"训练首领","text":"想证明自己的力量？先让我看看，你能否在真正的强敌面前守住信念。"},{"speaker":"星矢","text":"无论对手是谁，我都会为了伙伴和雅典娜战斗！"}],"outro":[{"speaker":"训练首领","text":"原来如此……你已经不再是刚踏入竞技场的新手了。"},{"speaker":"星矢","text":"这只是开始。真正的战斗，还在前方等着我们。"},{"speaker":"旁白","text":"竞技场的试炼落下帷幕，通往圣域的道路由此开启。"}]},
"sanctuary_twelve_houses":{"intro":[{"speaker":"旁白","text":"十二宫的尽头，教皇厅的大门缓缓开启。雅典娜的生命正被时间一点点吞噬。"},{"speaker":"教皇撒加","text":"凡人竟敢挑战我所掌握的力量？你们的意志，终究无法撼动神的领域。"},{"speaker":"星矢","text":"我们一路突破十二宫，不是为了在这里停下！雅典娜就在我们的身后！"}],"outro":[{"speaker":"撒加","text":"这股小宇宙……竟能照亮被黑暗吞噬的心吗？"},{"speaker":"旁白","text":"教皇厅的真相终于揭晓。黄金圣斗士们的信念汇聚，雅典娜迎来新的希望。"},{"speaker":"星矢","text":"圣域的战斗结束了，但守护世界的使命不会结束。"}]},
"asgard":{"intro":[{"speaker":"旁白","text":"极北之地风雪呼啸，奥丁神像前，最后的神斗士挡住了通往希露达的道路。"},{"speaker":"齐格弗里德","text":"为了仙宫与希露达大人，我绝不会让你们继续前进！"},{"speaker":"星矢","text":"如果她被邪恶力量控制，我们就必须让她恢复清醒！"}],"outro":[{"speaker":"齐格弗里德","text":"这份守护的意志……就托付给你们了。"},{"speaker":"旁白","text":"仙宫的寒风渐渐平息，奥丁蓝宝石的光芒指向海洋深处。"},{"speaker":"冰河","text":"新的小宇宙正在海底苏醒。我们必须立刻赶往那里。"}]},
"poseidon":{"intro":[{"speaker":"旁白","text":"海底神殿震动，七根海界支柱之间，海皇的神威逐渐笼罩整个大地。"},{"speaker":"海皇波塞冬","text":"被洪水洗净的世界，将迎来新的秩序。你们无法阻止神的意志。"},{"speaker":"星矢","text":"人类的未来不该由任何神明独自决定！我们会救出雅典娜！"}],"outro":[{"speaker":"波塞冬","text":"人类……竟再次以微弱的生命之火，抵挡了神的洪流。"},{"speaker":"旁白","text":"海界的危机暂时解除，但更深沉的黑暗已从冥界伸向现世。"},{"speaker":"紫龙","text":"这一次，我们要面对的恐怕是超越以往的敌人。"}]},
"hades":{"intro":[{"speaker":"旁白","text":"极乐净土的花海寂静无声，冥王的神殿前，死亡与永眠的气息交织。"},{"speaker":"冥王哈迪斯","text":"生命终将归于死亡。为何还要为短暂的尘世继续挣扎？"},{"speaker":"星矢","text":"正因为生命短暂，才更值得被守护！我们绝不会放弃雅典娜和这个世界！"}],"outro":[{"speaker":"哈迪斯","text":"人类的意志……竟能抵达连神也无法轻视的高度。"},{"speaker":"旁白","text":"冥界的黑暗退去，但众神的目光已经投向人间。"},{"speaker":"雅典娜","text":"真正的和平仍需守护。我们必须面对来自天界的审判。"}]},
"heaven":{"intro":[{"speaker":"旁白","text":"云海之上的天界神门开启，神圣的光辉化作无形压力，阻挡凡人的脚步。"},{"speaker":"天界守护者","text":"凡人擅闯神域，便要接受天界的裁断。"},{"speaker":"星矢","text":"即使面对众神，我们也要守护自己珍视的人与世界！"}],"outro":[{"speaker":"天界守护者","text":"你们的意志，已经超越了凡人所能抵达的界限。"},{"speaker":"旁白","text":"天界试炼结束，然而宇宙深处出现了不属于任何神域的裂隙。"},{"speaker":"雅典娜","text":"那股力量正在吞噬秩序。最后的答案，就在那里。"}]},
"original_final":{"intro":[{"speaker":"旁白","text":"七大篇章的命运在此交汇。原初虚空深处，宇宙裁决者已经苏醒。"},{"speaker":"宇宙裁决者","text":"秩序与混沌都将归于寂静。你们所守护的一切，不过是宇宙中的短暂回声。"},{"speaker":"星矢","text":"只要还有同伴并肩，只要心中的小宇宙仍在燃烧，我们就不会接受这样的结局！"}],"outro":[{"speaker":"宇宙裁决者","text":"原来如此……无数生命彼此连接的意志，才是宇宙真正的答案。"},{"speaker":"旁白","text":"最后的战斗结束，星辰重新闪耀。七大篇章的旅程在此迎来新的黎明。"},{"speaker":"雅典娜","text":"感谢你守护了这个世界。未来的故事，将由新的希望继续书写。"}]}}
const BOSS_BATTLE_LINES := {"gold_taurus":{"phase_two":"黄金圣衣的力量，现在才真正开始！","enrage":"巨型号角将粉碎一切阻挡我的力量！","special_attack":"巨型号角——正面承受我的全力一击！"},"gold_cancer":{"phase_two":"亡者的世界已经向你敞开！","enrage":"积尸气冥界波，带你坠入死亡深渊！","special_attack":"积尸气冥界波！接受亡者的召唤吧！"},"gold_leo_controlled":{"phase_two":"闪电般的攻击，你连我的身影都看不清！","enrage":"等离子光速拳——这就是狮子的真正速度！","special_attack":"雷光电闪，连续攻击不会给你喘息机会！"},"gold_virgo":{"phase_two":"六感即将被剥夺，你还能凭什么战斗？","enrage":"天舞宝轮，封闭你的感官与退路！","special_attack":"天舞宝轮——在寂静中感受恐惧吧！"},"gold_scorpio":{"phase_two":"猩红毒针已经瞄准，你还能坚持几次？","enrage":"安达里士！最后一针将决定你的命运！","special_attack":"猩红毒针，逐一刻下死亡倒数！"},"gold_capricorn":{"phase_two":"圣剑的锋芒不会因你的勇气而迟钝！","enrage":"圣剑·飞跃巨石，斩断你的防御！","special_attack":"看清楚了，这就是圣剑的真正威力！"},"gold_aquarius":{"phase_two":"绝对零度的寒意正在冻结你的行动！","enrage":"曙光女神之宽恕，冻结一切生命！","special_attack":"冰结晶之拳，温度已经接近绝对零度！"},"gold_pisces":{"phase_two":"红色玫瑰的芬芳，将成为你的葬礼！","enrage":"血腥玫瑰，贯穿心脏的最后一击！","special_attack":"玫瑰花雨已经封锁你的退路！"},"pope_saga":{"phase_two":"善与恶的力量，都将在我手中屈服！","enrage":"银河星爆！让整个空间都为之崩裂！","special_attack":"异次元空间，迷失在无尽的黑暗中吧！"},"god_warrior_hagen":{"phase_two":"冰与火的力量将在这里彻底爆发！","enrage":"烈焰与寒冰交错，绝不会给你第二次机会！","special_attack":"冰火双重奏，接下这股极寒与烈焰！"},"god_warrior_mime":{"phase_two":"听见了吗？这段旋律将成为你的终曲！","enrage":"安魂曲已经奏响，你的生命即将落幕！","special_attack":"弦音化作冲击，无法逃离我的乐章！"},"god_warrior_alberich":{"phase_two":"紫水晶封印会吞噬你的力量！","enrage":"自然幻影剑与封印之力，一同将你埋葬！","special_attack":"紫水晶封印——你的行动到此为止！"},"mariner_io":{"phase_two":"六只圣兽的力量还远远没有展现完毕！","enrage":"六圣兽全部出击，接受海皇的审判！","special_attack":"六圣兽·猛虎突袭！下一击来自另一个方向！"},"mariner_kasa":{"phase_two":"你所珍视之人的模样，也会成为你的弱点！","enrage":"镜像幻术将吞噬你的意志与小宇宙！","special_attack":"看清楚吧——你面对的究竟是谁？"},"mariner_sorrento":{"phase_two":"我的笛声将穿透你的防御与意志！","enrage":"死亡交响曲，奏响最后的乐章！","special_attack":"音波冲击已经抵达，你无法躲开这段旋律！"},"god_warrior_siegfried":{"phase_two":"我的不死之身，不会被普通攻击击倒！","enrage":"神圣力量已经觉醒，迎接最强一击！","special_attack":"神斗士的骄傲，将化作毁灭性的审判！"},"hypnos_guardian":{"phase_two":"沉睡吧，凡人的意志无法抵抗永恒长眠！","enrage":"永恒睡眠，连你的梦境也将被封闭！","special_attack":"睡眠领域已经展开，放弃无谓的挣扎吧！"},"thanatos_reaper":{"phase_two":"死亡已经注视着你，无处可逃！","enrage":"死亡的印记即将收割灵魂！","special_attack":"死亡印记已落下，迎接灵魂的终结！"},"hades_emperor":{"phase_two":"冥王的力量绝不会被人类意志击溃！","enrage":"冥界之门已经开启，万物都将归于黑暗！","special_attack":"灵魂汲取——你的生命与希望都归我所有！"},"poseidon_emperor":{"phase_two":"海皇之怒将淹没大地，凡人无法阻挡！","enrage":"大海的意志已经苏醒，接受潮汐的制裁！","special_attack":"海皇三叉戟引动巨浪，退无可退！"},"apollo_trial":{"phase_two":"太阳的光辉不会被凡人的双手遮蔽！","enrage":"太阳神的审判，将让一切归于光芒！","special_attack":"太阳耀斑——在神圣烈焰中消失吧！"},"zeus_trial":{"phase_two":"雷霆已经回应我的召唤！","enrage":"众神之王的雷霆，将贯穿你的灵魂！","special_attack":"天雷连锁，逃不出我的神罚！"},"universe_arbiter":{"phase_two":"宇宙的秩序正在崩解，你们的抵抗毫无意义！","enrage":"终极裁决启动，所有星辰都将归于虚无！","special_attack":"宇宙坍缩——让一切存在回到原初！"}}

static func get_scene(chapter_id: String, boss_id: String, event_name: String, boss_name: String = "强敌") -> Dictionary:
    if not event_name in ["intro","outro"]:
        return {}
    var title := str(CHAPTER_TITLES.get(chapter_id,"圣斗士星矢 · 宇宙之战")) + " · " + boss_name
    var chapter_data: Dictionary = SIGNATURE_SCENES.get(chapter_id,{})
    var lines: Array = chapter_data.get(event_name,[]).duplicate(true)
    if lines.is_empty():
        if event_name == "intro":
            lines = [{"speaker":"旁白","text":"战场的气氛骤然改变，一股强大的小宇宙从前方逼近。"},{"speaker":boss_name,"text":"想要继续前进，就先证明你拥有直面我的觉悟。"},{"speaker":"星矢","text":"我们不会退缩。为了守护重要的人，战斗现在开始！"}]
        else:
            lines = [{"speaker":boss_name,"text":"你的意志……确实配得上这场战斗。"},{"speaker":"旁白","text":"强敌倒下，战场逐渐恢复平静，前方的道路再次显现。"},{"speaker":"星矢","text":"我们继续前进。还有需要守护的人在等着我们。"}]
    return {"title":title,"event":event_name,"boss_id":boss_id,"lines":lines}
static func get_battle_line(boss_id: String, event_name: String, boss_name: String = "强敌") -> Dictionary:
    if not event_name in ["phase_two", "enrage", "special_attack", "break"]:
        return {}
    var boss_lines: Dictionary = BOSS_BATTLE_LINES.get(boss_id, {})
    var line_text := str(boss_lines.get(event_name, ""))
    if line_text.is_empty():
        match event_name:
            "phase_two": line_text = "你已经见识过我的力量，现在才是真正的战斗！"
            "enrage": line_text = "逼我使出最后的力量，你将为此付出代价！"
            "special_attack": line_text = "接下我的必杀攻击！"
            "break": line_text = "可恶……竟然突破了我的防御！但战斗还没有结束！"
    return {"speaker": boss_name, "text": line_text, "event": event_name, "boss_id": boss_id}


static func validate_catalog() -> Dictionary:
    var errors: Array[String] = []
    for chapter_id in CHAPTER_TITLES:
        var chapter_data: Dictionary = SIGNATURE_SCENES.get(chapter_id,{})
        for event_name in ["intro","outro"]:
            var lines: Array = chapter_data.get(event_name,[])
            if lines.size() < 2:
                errors.append("missing boss story scene: " + chapter_id + "/" + event_name)
            for line in lines:
                if str(line.get("speaker","")).is_empty() or str(line.get("text","")).is_empty():
                    errors.append("invalid boss story line: " + chapter_id + "/" + event_name)
    if get_scene("unknown","unknown","intro","测试首领").get("lines",[]).size() < 2:
        errors.append("generic boss story fallback is unavailable")
    return {"valid":errors.is_empty(),"chapter_count":CHAPTER_TITLES.size(),"scene_count":CHAPTER_TITLES.size()*2,"errors":errors}
