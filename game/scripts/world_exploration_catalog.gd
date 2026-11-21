extends RefCounted
class_name WorldExplorationCatalog

static func get_regions() -> Array[Dictionary]:
	return [
		{"id":"galaxy_wars","name":"银河竞技场","description":"竞技场外围、训练场与银河擂台。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"gw_arena","name":"银河擂台","description":"主线试炼与竞技场决战地点。"},{"id":"gw_training","name":"训练场","description":"基础战斗与连招训练区域。"},{"id":"gw_stands","name":"观战席","description":"竞技场外围探索区域。"}]},
		{"id":"sanctuary_twelve_houses","name":"圣域十二宫","description":"沿山道攀登十二宫，探索黄金圣斗士的殿堂。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"s12_aries","name":"白羊宫","description":"圣衣修复与旅途指引。"},{"id":"s12_twelve_houses","name":"黄道十二宫","description":"逐宫挑战黄金圣斗士。"},{"id":"s12_pope_chamber","name":"教皇厅","description":"十二宫篇最终剧情区域。"}]},
		{"id":"asgard","name":"北欧仙宫","description":"冰雪山脉、神斗士据点与极光遗迹。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"asgard_bluegrad","name":"蓝冰之地","description":"北欧篇探索起点。"},{"id":"asgard_valhalla","name":"仙宫神殿","description":"神斗士剧情与决战区域。"},{"id":"asgard_tree","name":"世界之树遗迹","description":"隐藏探索与收集区域。"}]},
		{"id":"poseidon","name":"海皇神殿","description":"海底神殿、七根海界支柱与海皇神殿。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"poseidon_sanctuary","name":"海底神殿","description":"海界探索入口。"},{"id":"poseidon_pillars","name":"七大支柱","description":"海将军守护的支柱群。"},{"id":"poseidon_throne","name":"海皇神殿","description":"海皇波塞冬最终决战区域。"}]},
		{"id":"hades","name":"冥界","description":"冥界入口、审判庭、叹息之墙与极乐净土。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"hades_river","name":"冥河入口","description":"进入冥界的第一道关口。"},{"id":"hades_judgement","name":"审判庭","description":"冥界三巨头与审判剧情区域。"},{"id":"hades_elisium","name":"极乐净土","description":"冥王篇最终战场。"}]},
		{"id":"heaven","name":"天界","description":"天界神域、天空神殿与诸神试炼。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"heaven_gate","name":"天界之门","description":"天界篇入口与守卫试炼。"},{"id":"heaven_temple","name":"天空神殿","description":"神明试炼与剧情探索区域。"},{"id":"heaven_summit","name":"神域高台","description":"天界篇核心决战地点。"}]},
		{"id":"original_final","name":"宇宙终章","description":"原创终章的星海遗迹、原初空间与宇宙核心。","spawn_position":Vector3(0.0,0.15,7.0),"landmarks":[{"id":"final_starfield","name":"星海回廊","description":"终章探索起点。"},{"id":"final_primordial","name":"原初虚空","description":"原初力量与隐藏挑战区域。"},{"id":"final_core","name":"宇宙核心","description":"全篇终极决战地点。"}]}
	]

static func validate_catalog() -> bool:
	var regions := get_regions()
	if regions.size() != 7:
		return false
	var ids: Dictionary = {}
	for region in regions:
		var region_id := str(region.get("id", ""))
		if region_id.is_empty() or ids.has(region_id) or region.get("landmarks", []).size() < 3:
			return false
		ids[region_id] = true
		for landmark in region.get("landmarks", []):
			if str(landmark.get("id", "")).is_empty() or str(landmark.get("name", "")).is_empty():
				return false
	return true
