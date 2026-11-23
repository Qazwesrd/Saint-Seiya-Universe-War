extends Node
## Data-driven faction selection and first-nine-level onboarding.
## Faction-specific character rigs and authored scenes remain separate art deliverables.

const FACTIONS := {
	"sanctuary": {"name":"圣域","region":"sanctuary","mentor":"圣域训练导师","class_ids":["pegasus","dragon","cygnus","andromeda","phoenix","lyra"],"intro":"从圣域修炼场开始，接受圣衣训练并点燃小宇宙。"},
	"dark_saints": {"name":"暗黑圣斗士","region":"death_queen_island","mentor":"死亡皇后岛试炼导师","class_ids":["pegasus","dragon","cygnus","andromeda","phoenix"],"intro":"从死亡皇后岛开始，接受暗黑圣衣与生存试炼。"},
	"sea": {"name":"海界","region":"poseidon_temple","mentor":"海界引导官","class_ids":["sea_dragon","sea_swallow","poseidon"],"intro":"从海底神殿开始，接受鳞衣试炼并巡查海界支柱。"},
	"underworld": {"name":"冥界","region":"underworld","mentor":"冥界引导官","class_ids":["tenmou","hades","hypnos","thanatos"],"intro":"从冥界入口开始，接受冥衣试炼与魔星考验。"},
	"divine": {"name":"神界 / 天界","region":"olympus","mentor":"神域引导者","class_ids":["tenkishi","athena","apollo","zeus","artemis","ares","eris","abel","saturn","pallas","hera","demeter","hestia","hermes","hephaestus","aphrodite"],"intro":"从神域试炼场开始，学习神力控制与神圣装备共鸣。"},
	"asgard": {"name":"北欧仙宫","region":"asgard","mentor":"仙宫试炼官","class_ids":["odin","cygnus","dragon"],"intro":"从仙宫训练场开始，接受冰雪与神斗衣试炼。"},
	"steel": {"name":"钢铁圣斗士","region":"steel_base","mentor":"钢铁基地教官","class_ids":["pegasus","dragon","cygnus"],"intro":"从钢铁基地开始，接受机械装甲与战术训练。"},
	"bluegrad": {"name":"蓝冰战士","region":"bluegrad","mentor":"蓝格拉德导师","class_ids":["cygnus","tenmou"],"intro":"从蓝格拉德冰原开始，接受极寒环境试炼。"},
	"fallen": {"name":"堕天使","region":"fallen_domain","mentor":"堕天领域引导者","class_ids":["lucifer"],"intro":"从堕天领域开始，接受黑翼与堕天力量试炼。"},
	"titans": {"name":"泰坦神族","region":"titan_domain","mentor":"泰坦试炼者","class_ids":["chronos"],"intro":"从泰坦神域开始，接受古神力量与时序试炼。"},
	"giants": {"name":"巨人族","region":"gigantes_domain","mentor":"巨人族战斗导师","class_ids":["tenmou","ares"],"intro":"从巨人领域开始，接受巨力与重装战斗试炼。"},
	"hongmeng": {"name":"鸿蒙神域","region":"zixiao_palace","mentor":"紫霄宫接引仙官","class_ids":["chronos","apollo"],"intro":"从紫霄宫开始，接受混沌法则与创世试炼。"}
}
const WORLD_PROFILES := {
	"sanctuary":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.055,0.075,0.14),"ambient_color":Color(0.32,0.38,0.62),"accent_color":Color(0.16,0.42,0.92),"structure":"columns"},
	"dark_saints":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.075,0.045,0.055),"ambient_color":Color(0.28,0.18,0.24),"accent_color":Color(0.55,0.16,0.18),"structure":"ruins"},
	"sea":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.025,0.12,0.19),"ambient_color":Color(0.12,0.36,0.52),"accent_color":Color(0.12,0.72,0.9),"structure":"coral"},
	"underworld":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.045,0.025,0.09),"ambient_color":Color(0.22,0.13,0.32),"accent_color":Color(0.48,0.18,0.72),"structure":"ruins"},
	"divine":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.16,0.15,0.2),"ambient_color":Color(0.58,0.55,0.68),"accent_color":Color(0.94,0.82,0.48),"structure":"columns"},
	"asgard":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.12,0.19,0.25),"ambient_color":Color(0.35,0.55,0.72),"accent_color":Color(0.48,0.82,1.0),"structure":"crystals"},
	"steel":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.09,0.12,0.15),"ambient_color":Color(0.34,0.4,0.46),"accent_color":Color(0.45,0.72,0.86),"structure":"machines"},
	"bluegrad":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.09,0.16,0.25),"ambient_color":Color(0.28,0.52,0.75),"accent_color":Color(0.62,0.88,1.0),"structure":"crystals"},
	"fallen":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.06,0.035,0.075),"ambient_color":Color(0.3,0.15,0.28),"accent_color":Color(0.72,0.22,0.42),"structure":"wings"},
	"titans":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.13,0.105,0.09),"ambient_color":Color(0.48,0.36,0.26),"accent_color":Color(0.86,0.62,0.32),"structure":"columns"},
	"giants":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.12,0.09,0.075),"ambient_color":Color(0.42,0.32,0.24),"accent_color":Color(0.72,0.48,0.28),"structure":"giants"},
	"hongmeng":{"spawn_position":Vector3(0.0,0.15,7.0),"ground_color":Color(0.045,0.035,0.12),"ambient_color":Color(0.3,0.25,0.58),"accent_color":Color(0.72,0.55,1.0),"structure":"orbs"}
}

const TUTORIAL_NORMAL_TARGET := 2


func get_world_profile(faction_id: String = "") -> Dictionary:
	var resolved_id := faction_id
	if resolved_id.is_empty():
		resolved_id = str(RPGState.profile.get("faction_id", "sanctuary"))
	var result: Dictionary = WORLD_PROFILES.get(resolved_id, WORLD_PROFILES["sanctuary"]).duplicate(true)
	result["faction_id"] = resolved_id
	return result

func get_tutorial_enemy_name() -> String:
	var faction_id := str(RPGState.profile.get("faction_id", "sanctuary"))
	match faction_id:
		"dark_saints": return "暗黑岛守卫"
		"sea": return "海界巡逻兵"
		"underworld": return "冥界巡逻者"
		"divine": return "神域试炼守卫"
		"asgard": return "仙宫神斗士"
		"steel": return "钢铁训练机兵"
		"bluegrad": return "蓝冰战士"
		"fallen": return "堕天卫士"
		"titans": return "泰坦先锋"
		"giants": return "巨人先锋"
		"hongmeng": return "混沌幻影"
		_: return "圣域训练对手"

func get_tutorial_boss_name() -> String:
	var faction_id := str(RPGState.profile.get("faction_id", "sanctuary"))
	match faction_id:
		"dark_saints": return "暗黑骑士统领"
		"sea": return "海将军试炼官"
		"underworld": return "冥界魔星守卫"
		"divine": return "神域审判者"
		"asgard": return "神斗士试炼者"
		"steel": return "钢铁重装机甲"
		"bluegrad": return "冰原巨人"
		"fallen": return "堕天使审判官"
		"titans": return "泰坦神将"
		"giants": return "巨人族统领"
		"hongmeng": return "鸿蒙守护者"
		_: return "圣域试炼官"

func get_factions() -> Array:
	var result: Array = []
	for faction_id in FACTIONS:
		var faction: Dictionary = FACTIONS[faction_id]
		result.append({"id":faction_id,"name":str(faction["name"]),"region":str(faction["region"]),"intro":str(faction["intro"])})
	return result

func get_faction(faction_id: String) -> Dictionary:
	return FACTIONS.get(faction_id, FACTIONS["sanctuary"]).duplicate(true)

func get_class_options(faction_id: String) -> Array:
	var faction: Dictionary = FACTIONS.get(faction_id, FACTIONS["sanctuary"])
	var result: Array = []
	if faction_id == "hongmeng":
		result.append({"id":"hongjun","class_id":"apollo","preset_id":"hongjun","name":"鸿钧老祖 · 至高神","title":"鸿蒙神域至高神"})
	for class_id in faction.get("class_ids", []):
		if not RPGState.CLASS_DATA.has(str(class_id)):
			continue
		var class_data: Dictionary = RPGState.CLASS_DATA[str(class_id)]
		var display_name := str(class_data.get("name", class_id))
		match faction_id:
			"dark_saints": display_name = "暗黑" + display_name
			"underworld": display_name = "冥界·" + display_name
			"divine": display_name = "神界·" + display_name
			"asgard": display_name = "神斗士·" + display_name
			"steel": display_name = "钢铁·" + display_name
			"bluegrad": display_name = "蓝冰·" + display_name
			"fallen": display_name = "堕天·" + display_name
			"titans": display_name = "泰坦·" + display_name
			"giants": display_name = "巨人·" + display_name
			"hongmeng": display_name = "鸿蒙·" + display_name
		result.append({"id":str(class_id),"class_id":str(class_id),"preset_id":"","name":display_name,"title":str(class_data.get("name", class_id))})
	return result

func initialize_character_profile(profile: Dictionary, faction_id: String, preset_id: String = "") -> void:
	var faction: Dictionary = get_faction(faction_id)
	profile["faction_id"] = faction_id if FACTIONS.has(faction_id) else "sanctuary"
	profile["spawn_region"] = str(faction.get("region", "sanctuary"))
	profile["character_preset_id"] = preset_id
	profile["character_title"] = "宇宙之战至高神" if preset_id == "hongjun" else str(faction.get("name", "圣域战士"))
	profile["is_supreme_deity"] = preset_id == "hongjun"
	profile["power_mode"] = "story_balanced" if preset_id == "hongjun" else "normal"
	profile["story_balanced"] = true
	profile["faction_tutorial_enabled"] = true
	profile["faction_tutorial"] = {"version":1,"faction_id":str(profile["faction_id"]),"status":"not_started","defeated_normal":0,"boss_defeated":false}
	profile["quest_progress"] = {}
	profile["campaign_progress"] = {"version":1,"unlocked_chapters":["galaxy_wars"],"completed_missions":[],"active_mission":"gw_001","objective_counts":{},"claimed_rewards":[]}

func validate_catalog() -> bool:
	if FACTIONS.size() != 12:
		return false
	var seen: Dictionary = {}
	for faction_id in FACTIONS:
		var faction: Dictionary = FACTIONS[faction_id]
		if str(faction.get("name", "")).is_empty() or str(faction.get("region", "")).is_empty() or faction.get("class_ids", []).is_empty():
			return false
		for class_id in faction.get("class_ids", []):
			if not RPGState.CLASS_DATA.has(str(class_id)):
				return false
			seen[str(class_id)] = true
	for class_id in RPGState.CLASS_DATA:
		if not seen.has(str(class_id)):
			return false
	var hongjun_found := false
	for option in get_class_options("hongmeng"):
		if str(option.get("preset_id", "")) == "hongjun":
			hongjun_found = true
	return hongjun_found

func get_tutorial_entry_points() -> Array:
	if str(RPGState.profile.get("character_preset_id", "")) == "hongjun":
		return ["sanctuary", "hongmeng"]
	return [str(RPGState.profile.get("faction_id", "sanctuary"))]

func can_interact_with_mentor(entry_faction_id: String) -> bool:
	return entry_faction_id in get_tutorial_entry_points()

func get_tutorial_mentor_name() -> String:
	var faction_id := str(RPGState.profile.get("faction_id", "sanctuary"))
	if str(RPGState.profile.get("character_preset_id", "")) == "hongjun":
		return "紫霄宫 / 圣域双入口引导者"
	return str(get_faction(faction_id).get("mentor", "阵营引导者"))

func interact_with_mentor(entry_faction_id: String = "") -> Dictionary:
	if not entry_faction_id.is_empty() and not can_interact_with_mentor(entry_faction_id):
		return {"speaker":get_tutorial_mentor_name(),"text":"该任务入口不属于当前角色的阵营权限。","action":"denied"}
	var progress: Dictionary = RPGState.profile.get("faction_tutorial", {}).duplicate(true)
	var speaker := get_tutorial_mentor_name()
	if progress.is_empty():
		return {"speaker":speaker,"text":"当前存档没有阵营新手任务记录。","action":"error"}
	var status := str(progress.get("status", "not_started"))
	if status == "not_started":
		progress["status"] = "active"
		RPGState.profile["faction_tutorial"] = progress
		if not RPGState.save_slot(RPGState.active_slot):
			progress["status"] = "not_started"
			RPGState.profile["faction_tutorial"] = progress
			return {"speaker":speaker,"text":"任务接取失败，存档写入失败。","action":"error"}
		var faction_name := str(get_faction(str(progress.get("faction_id","sanctuary"))).get("name","本阵营"))
		return {"speaker":speaker,"text":"欢迎来到%s。请击败两名训练对手，再战胜训练首领，完成1至9级阵营试炼。"%faction_name,"action":"accept"}
	if status == "active":
		var normal_count := int(progress.get("defeated_normal", 0))
		if normal_count < TUTORIAL_NORMAL_TARGET:
			return {"speaker":speaker,"text":"新手试炼进行中：还需要击败%d名训练对手。"%(TUTORIAL_NORMAL_TARGET-normal_count),"action":"progress"}
		if not bool(progress.get("boss_defeated", false)):
			return {"speaker":speaker,"text":"训练对手已击败。请前往试炼场挑战阵营训练首领。","action":"progress"}
		progress["status"] = "ready_to_return"
	if str(progress.get("status", "")) == "ready_to_return":
		var previous: Dictionary = RPGState.profile.duplicate(true)
		progress["status"] = "completed"
		RPGState.profile["faction_tutorial"] = progress
		RPGState.profile["exp"] = int(RPGState.profile.get("exp", 0)) + 3400
		RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) + 1200
		while int(RPGState.profile.get("level", 1)) < RPGState.MAX_LEVEL and int(RPGState.profile.get("exp", 0)) >= RPGState.exp_to_next_level():
			RPGState.profile["exp"] = int(RPGState.profile.get("exp", 0)) - RPGState.exp_to_next_level()
			RPGState.profile["level"] = int(RPGState.profile.get("level", 1)) + 1
			RPGState.profile["skill_points"] = int(RPGState.profile.get("skill_points", 0)) + 1
		if not RPGState.save_slot(RPGState.active_slot):
			RPGState.profile = previous
			return {"speaker":speaker,"text":"奖励保存失败，请再次交谈领取。","action":"error"}
		RPGState._emit_change()
		return {"speaker":speaker,"text":"阵营新手试炼完成！获得3400经验与1200星币。达到10级后将接入动漫主线剧情。","action":"complete"}
	return {"speaker":speaker,"text":"阵营试炼已经完成。达到10级后可继续动漫主线。","action":"completed"}

func record_training_defeat(is_boss: bool) -> void:
	var progress: Dictionary = RPGState.profile.get("faction_tutorial", {}).duplicate(true)
	if str(progress.get("status", "")) != "active":
		return
	if is_boss:
		progress["boss_defeated"] = true
	else:
		progress["defeated_normal"] = mini(TUTORIAL_NORMAL_TARGET, int(progress.get("defeated_normal", 0)) + 1)
	if int(progress.get("defeated_normal", 0)) >= TUTORIAL_NORMAL_TARGET and bool(progress.get("boss_defeated", false)):
		progress["status"] = "ready_to_return"
	RPGState.profile["faction_tutorial"] = progress
	if not RPGState.save_slot(RPGState.active_slot):
		SystemHealthManager.report_error("save", "阵营新手任务进度保存失败", "slot=%d" % RPGState.active_slot)
	elif has_node("/root/EventBus"):
		EventBus.player_profile_changed.emit(RPGState.profile.duplicate(true))

func get_tutorial_tracker_text() -> String:
	var progress: Dictionary = RPGState.profile.get("faction_tutorial", {})
	var faction: Dictionary = get_faction(str(progress.get("faction_id", RPGState.profile.get("faction_id", "sanctuary"))))
	var status := str(progress.get("status", "not_started"))
	var title := str(faction.get("name", "阵营")) + "新手试炼"
	if status == "not_started":
		return "主线：%s\n目标：与%s交谈接取任务" % [title, get_tutorial_mentor_name()]
	if status == "active":
		if int(progress.get("defeated_normal", 0)) < TUTORIAL_NORMAL_TARGET:
			return "主线：%s\n目标：击败训练对手 %d/%d" % [title, int(progress.get("defeated_normal", 0)), TUTORIAL_NORMAL_TARGET]
		if not bool(progress.get("boss_defeated", false)):
			return "主线：%s\n目标：击败阵营训练首领" % title
		return "主线：%s\n目标：返回导师交付任务" % title
	if status == "ready_to_return":
		return "主线：%s\n目标：返回导师领取奖励" % title
	return "阵营试炼完成 · 等级 %d/10 · 达到10级后进入动漫主线" % int(RPGState.profile.get("level", 1))
