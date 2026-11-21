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
