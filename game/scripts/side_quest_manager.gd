extends Node
## Optional chapter side quests and automatically discovered hidden quests.
signal quests_changed

const QUESTS := [
	{"id":"side_galaxy_boss","chapter_id":"galaxy_wars","kind":"side","name":"竞技场强敌挑战","description":"在银河竞技场击败一名首领。","trigger":"boss_defeated","target":1,"exp":180,"coins":160},
	{"id":"hidden_galaxy_stands","chapter_id":"galaxy_wars","kind":"hidden","name":"观战席的星之碎片","description":"探索观战席，寻找被遗落的星之碎片。","trigger":"landmark_discovered","landmark_id":"gw_stands","target":1,"exp":120,"coins":120},
	{"id":"npc_galaxy_guide","chapter_id":"galaxy_wars","kind":"npc","name":"引导员的入门委托","description":"接取后再次与引导员交谈，确认训练记录。","trigger":"talk_to_guide","target":1,"exp":100,"coins":90},
	{"id":"npc_sanctuary_report","chapter_id":"sanctuary_twelve_houses","kind":"npc","name":"圣域联络委托","description":"向圣域联络员报告十二宫的探索情况。","trigger":"talk_to_guide","target":1,"exp":180,"coins":150},
	{"id":"npc_asgard_message","chapter_id":"asgard","kind":"npc","name":"仙宫传令委托","description":"向北欧传令员确认神斗士区域的情报。","trigger":"talk_to_guide","target":1,"exp":220,"coins":180},
	{"id":"npc_poseidon_report","chapter_id":"poseidon","kind":"npc","name":"海界遗迹报告","description":"向海界联络员报告七大支柱的探索情况。","trigger":"talk_to_guide","target":1,"exp":260,"coins":220},
	{"id":"npc_hades_intel","chapter_id":"hades","kind":"npc","name":"冥界情报委托","description":"向冥界记录员报告审判庭的发现。","trigger":"talk_to_guide","target":1,"exp":300,"coins":250},
	{"id":"npc_heaven_observation","chapter_id":"heaven","kind":"npc","name":"天界观测报告","description":"向天界观察者确认神域试炼记录。","trigger":"talk_to_guide","target":1,"exp":360,"coins":300},
	{"id":"npc_final_record","chapter_id":"original_final","kind":"npc","name":"宇宙记录者的最后请求","description":"与宇宙记录者交谈，提交终章探索记录。","trigger":"talk_to_guide","target":1,"exp":500,"coins":420},
	{"id":"side_sanctuary_boss","chapter_id":"sanctuary_twelve_houses","kind":"side","name":"黄金宫殿的试炼","description":"在圣域十二宫击败一名首领。","trigger":"boss_defeated","target":1,"exp":360,"coins":300},
	{"id":"hidden_sanctuary_aries","chapter_id":"sanctuary_twelve_houses","kind":"hidden","name":"白羊宫的修复笔记","description":"探索白羊宫，找到穆留下的圣衣修复笔记。","trigger":"landmark_discovered","landmark_id":"s12_aries","target":1,"exp":240,"coins":220},
	{"id":"side_asgard_boss","chapter_id":"asgard","kind":"side","name":"神斗士的荣誉","description":"在北欧仙宫击败一名首领。","trigger":"boss_defeated","target":1,"exp":420,"coins":360},
	{"id":"hidden_asgard_tree","chapter_id":"asgard","kind":"hidden","name":"世界之树的回响","description":"探索世界之树遗迹，寻找古老的回响。","trigger":"landmark_discovered","landmark_id":"asgard_tree","target":1,"exp":280,"coins":250},
	{"id":"side_poseidon_boss","chapter_id":"poseidon","kind":"side","name":"海界守护者","description":"在海皇神殿击败一名首领。","trigger":"boss_defeated","target":1,"exp":480,"coins":400},
	{"id":"hidden_poseidon_pillars","chapter_id":"poseidon","kind":"hidden","name":"七柱铭文","description":"调查七大支柱，收集海界铭文。","trigger":"landmark_discovered","landmark_id":"poseidon_pillars","target":1,"exp":320,"coins":280},
	{"id":"side_hades_boss","chapter_id":"hades","kind":"side","name":"冥界审判者","description":"在冥界击败一名首领。","trigger":"boss_defeated","target":1,"exp":560,"coins":460},
	{"id":"hidden_hades_judgement","chapter_id":"hades","kind":"hidden","name":"审判庭的秘密","description":"探索审判庭，发现被封存的冥界记录。","trigger":"landmark_discovered","landmark_id":"hades_judgement","target":1,"exp":360,"coins":320},
	{"id":"side_heaven_boss","chapter_id":"heaven","kind":"side","name":"天界试炼者","description":"在天界击败一名首领。","trigger":"boss_defeated","target":1,"exp":680,"coins":560},
	{"id":"hidden_heaven_temple","chapter_id":"heaven","kind":"hidden","name":"神殿的星辉","description":"探索天空神殿，发现神域留下的星辉。","trigger":"landmark_discovered","landmark_id":"heaven_temple","target":1,"exp":420,"coins":380},
	{"id":"side_final_boss","chapter_id":"original_final","kind":"side","name":"原初强敌挑战","description":"在宇宙终章击败一名首领。","trigger":"boss_defeated","target":1,"exp":900,"coins":760},
	{"id":"hidden_final_primordial","chapter_id":"original_final","kind":"hidden","name":"原初虚空的记忆","description":"探索原初虚空，找回宇宙最初的记忆。","trigger":"landmark_discovered","landmark_id":"final_primordial","target":1,"exp":600,"coins":520},
	{"id":"side_dark_knight_trial","chapter_id":"galaxy_wars","kind":"side","name":"暗黑圣衣：黑暗统领讨伐","description":"接取挑战，击败银河战争篇的黑暗圣斗士统领，证明自己能够驾驭黑暗圣衣。","trigger":"dark_boss_defeated","required_archetype_id":"dark_black_knight_champion","target":1,"exp":620,"coins":520},
	{"id":"side_dark_patrol","chapter_id":"galaxy_wars","kind":"side","name":"黑暗军团：清剿巡逻队","description":"接取挑战，击败三名黑暗圣斗士巡逻兵，阻止他们集结军团。","trigger":"dark_patrol_defeated","target":3,"exp":420,"coins":360}
]
const STATE_KEY := "side_quest_state"
var state: Dictionary = {}

func _ready() -> void:
	if not RPGState.slot_loaded.is_connected(_on_slot_loaded):
		RPGState.slot_loaded.connect(_on_slot_loaded)
	load_state()

func _on_slot_loaded(_slot: int) -> void:
	load_state()

func _default_state() -> Dictionary:
	return {"version":1,"accepted":[],"progress":{},"discovered_hidden":[],"claimed":[]}

func load_state() -> void:
	var loaded: Variant = RPGState.profile.get(STATE_KEY, {})
	state = _default_state()
	if typeof(loaded) == TYPE_DICTIONARY and int(loaded.get("version", 0)) == 1:
		state["accepted"] = loaded.get("accepted", []).duplicate()
		state["progress"] = loaded.get("progress", {}).duplicate(true)
		state["discovered_hidden"] = loaded.get("discovered_hidden", []).duplicate()
		state["claimed"] = loaded.get("claimed", []).duplicate()
	quests_changed.emit()

func get_quest_overview() -> Array[Dictionary]:
	var unlocked: Dictionary = {}
	for chapter in CampaignManager.get_chapter_overview():
		unlocked[str(chapter.get("id", ""))] = bool(chapter.get("unlocked", false))
	var result: Array[Dictionary] = []
	for quest in QUESTS:
		var quest_id := str(quest.get("id", ""))
		var chapter_id := str(quest.get("chapter_id", ""))
		if not bool(unlocked.get(chapter_id, false)):
			continue
		var is_hidden := str(quest.get("kind", "")) == "hidden"
		if is_hidden and not state["discovered_hidden"].has(quest_id):
			continue
		var current := clampi(int(state["progress"].get(quest_id, 0)), 0, int(quest.get("target", 1)))
		var claimed: bool = state["claimed"].has(quest_id)
		var accepted: bool = state["accepted"].has(quest_id) or is_hidden
		var status := "claimed" if claimed else ("completed" if accepted and current >= int(quest.get("target", 1)) else ("in_progress" if accepted else "available"))
		var entry: Dictionary = quest.duplicate(true)
		entry["current"] = current
		entry["status"] = status
		result.append(entry)
	return result

func accept_quest(quest_id: String) -> bool:
	var quest := _get_quest(quest_id)
	if quest.is_empty() or str(quest.get("kind", "")) not in ["side", "npc"]:
		return false
	if state["accepted"].has(quest_id) or state["claimed"].has(quest_id):
		return false
	if not _chapter_unlocked(str(quest.get("chapter_id", ""))):
		return false
	var previous := state.duplicate(true)
	state["accepted"].append(quest_id)
	state["progress"][quest_id] = 0
	return _commit_or_restore(previous)

func record_event(event_type: String, context: Dictionary = {}) -> int:
	var changed_count := 0
	var previous := state.duplicate(true)
	var chapter_id := str(context.get("chapter_id", ""))
	for quest in QUESTS:
		if str(quest.get("chapter_id", "")) != chapter_id or str(quest.get("trigger", "")) != event_type:
			continue
		var required_archetype := str(quest.get("required_archetype_id", ""))
		if not required_archetype.is_empty() and str(context.get("archetype_id", "")) != required_archetype:
			continue
		var quest_id := str(quest.get("id", ""))
		if state["claimed"].has(quest_id):
			continue
		if str(quest.get("kind", "")) == "hidden":
			if str(context.get("landmark_id", "")) != str(quest.get("landmark_id", "")):
				continue
			if not state["discovered_hidden"].has(quest_id):
				state["discovered_hidden"].append(quest_id)
				state["progress"][quest_id] = 1
				changed_count += 1
		elif state["accepted"].has(quest_id):
			var current := int(state["progress"].get(quest_id, 0))
			var target := maxi(1, int(quest.get("target", 1)))
			if current < target:
				state["progress"][quest_id] = mini(target, current + 1)
				changed_count += 1
	if changed_count > 0 and not _commit_or_restore(previous):
		return 0
	return changed_count

func claim_reward(quest_id: String) -> Dictionary:
	var quest := _get_quest(quest_id)
	if quest.is_empty() or state["claimed"].has(quest_id):
		return {"success":false,"reason":"任务不存在或奖励已经领取"}
	var is_hidden := str(quest.get("kind", "")) == "hidden"
	if not is_hidden and not state["accepted"].has(quest_id):
		return {"success":false,"reason":"请先接取支线任务"}
	if int(state["progress"].get(quest_id, 0)) < int(quest.get("target", 1)):
		return {"success":false,"reason":"任务目标尚未完成"}
	var previous_state := state.duplicate(true)
	var previous_profile := RPGState.profile.duplicate(true)
	state["claimed"].append(quest_id)
	RPGState.profile[STATE_KEY] = state.duplicate(true)
	RPGState.profile["exp"] = int(RPGState.profile.get("exp", 0)) + int(quest.get("exp", 0))
	RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) + int(quest.get("coins", 0))
	while int(RPGState.profile.get("level", 1)) < RPGState.MAX_LEVEL and int(RPGState.profile["exp"]) >= RPGState.exp_to_next_level():
		RPGState.profile["exp"] = int(RPGState.profile["exp"]) - RPGState.exp_to_next_level()
		RPGState.profile["level"] = int(RPGState.profile["level"]) + 1
		RPGState.profile["skill_points"] = int(RPGState.profile.get("skill_points", 0)) + 1
	if not RPGState.save_slot(RPGState.active_slot):
		state = previous_state
		RPGState.profile = previous_profile
		return {"success":false,"reason":"奖励保存失败，奖励未发放，请重试"}
	RPGState._emit_change()
	quests_changed.emit()
	return {"success":true,"exp":int(quest.get("exp",0)),"coins":int(quest.get("coins",0)),"name":str(quest.get("name","任务"))}

func _get_quest(quest_id: String) -> Dictionary:
	for quest in QUESTS:
		if str(quest.get("id", "")) == quest_id:
			return quest.duplicate(true)
	return {}

func _chapter_unlocked(chapter_id: String) -> bool:
	for chapter in CampaignManager.get_chapter_overview():
		if str(chapter.get("id", "")) == chapter_id:
			return bool(chapter.get("unlocked", false))
	return false

func _commit_or_restore(previous: Dictionary) -> bool:
	var previous_profile: Dictionary = RPGState.profile.duplicate(true)
	RPGState.profile[STATE_KEY] = state.duplicate(true)
	if not RPGState.save_slot(RPGState.active_slot):
		state = previous
		RPGState.profile = previous_profile
		SystemHealthManager.report_error("save", "支线任务进度保存失败", "slot=%d" % RPGState.active_slot)
		return false
	RPGState._emit_change()
	quests_changed.emit()
	return true
