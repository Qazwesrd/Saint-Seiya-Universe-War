extends Node
## 本地离线成长系统：小宇宙星盘、翅膀养成与综合战力。
## 所有进度保存在 RPGState.profile，不依赖网络或付费服务。

const WING_DATA := {
	"star_wing": {"name": "星辰之翼", "description": "以星座星辉凝聚的初阶羽翼", "attack": 2.0, "defense": 1.0, "health": 12.0, "cosmos": 8.0, "unlock_cost": 300},
	"holy_wing": {"name": "圣光之翼", "description": "圣域试炼中获得的光辉羽翼", "attack": 4.0, "defense": 3.0, "health": 24.0, "cosmos": 12.0, "unlock_cost": 1800},
	"shadow_wing": {"name": "暗影之翼", "description": "蕴含暗影小宇宙的双翼", "attack": 6.0, "defense": 2.0, "health": 18.0, "cosmos": 16.0, "unlock_cost": 2600},
	"phoenix_wing": {"name": "凤凰之翼", "description": "浴火重生的烈焰羽翼", "attack": 7.0, "defense": 2.0, "health": 28.0, "cosmos": 14.0, "unlock_cost": 3600},
	"ocean_wing": {"name": "海皇之翼", "description": "潮汐与海洋力量凝成的羽翼", "attack": 3.0, "defense": 6.0, "health": 36.0, "cosmos": 18.0, "unlock_cost": 4200},
	"underworld_wing": {"name": "冥界之翼", "description": "冥界试炼奖励的幽冥羽翼", "attack": 8.0, "defense": 4.0, "health": 20.0, "cosmos": 20.0, "unlock_cost": 5200},
	"heaven_wing": {"name": "天界之翼", "description": "天界试炼奖励的神圣羽翼", "attack": 6.0, "defense": 7.0, "health": 42.0, "cosmos": 24.0, "unlock_cost": 6800},
	"divine_wing": {"name": "神域之翼", "description": "终章挑战中获得的神域羽翼", "attack": 12.0, "defense": 9.0, "health": 60.0, "cosmos": 32.0, "unlock_cost": 10000}
}

const COSMOS_NODES := {
	"star_attack": {"name": "星辉攻击", "attribute": "attack", "value": 2.0, "max_rank": 5, "level_required": 1, "cost": 120},
	"star_guard": {"name": "星辰守护", "attribute": "defense", "value": 2.0, "max_rank": 5, "level_required": 2, "cost": 120},
	"life_force": {"name": "生命源泉", "attribute": "max_health", "value": 18.0, "max_rank": 5, "level_required": 3, "cost": 150},
	"cosmos_capacity": {"name": "小宇宙扩容", "attribute": "max_cosmos", "value": 12.0, "max_rank": 5, "level_required": 5, "cost": 180},
	"cosmos_recovery": {"name": "燃烧回响", "attribute": "cosmos_regen", "value": 0.4, "max_rank": 5, "level_required": 7, "cost": 220},
	"critical_force": {"name": "星爆临界", "attribute": "critical_rate", "value": 0.005, "max_rank": 5, "level_required": 10, "cost": 300}
}

func _ready() -> void:
	_ensure_profile_data()

func _ensure_profile_data() -> void:
	if RPGState.profile.is_empty():
		return
	if not RPGState.profile.has("growth_wings"):
		RPGState.profile["growth_wings"] = {
			"owned": [],
			"equipped": "",
			"levels": {},
			"ranks": {},
			"visible": true
		}
	if not RPGState.profile.has("cosmos_star_nodes"):
		RPGState.profile["cosmos_star_nodes"] = {}
	if not RPGState.profile.has("cosmos_node_points"):
		RPGState.profile["cosmos_node_points"] = 0
	if not RPGState.profile.has("growth_data_version"):
		RPGState.profile["growth_data_version"] = 1

func _save_change(previous: Dictionary) -> bool:
	if not RPGState._commit_profile(previous):
		return false
	return true

func get_wing_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for wing_id in WING_DATA:
		var item: Dictionary = WING_DATA[wing_id].duplicate(true)
		item["id"] = wing_id
		result.append(item)
	return result

func get_wing_profile() -> Dictionary:
	_ensure_profile_data()
	var data: Dictionary = RPGState.profile.get("growth_wings", {})
	var owned: Array = data.get("owned", [])
	var equipped := str(data.get("equipped", ""))
	var level_map: Dictionary = data.get("levels", {})
	var rank_map: Dictionary = data.get("ranks", {})
	var wing: Dictionary = WING_DATA.get(equipped, {})
	var level := int(level_map.get(equipped, 1)) if not equipped.is_empty() else 0
	var rank := int(rank_map.get(equipped, 1)) if not equipped.is_empty() else 0
	var multiplier := float(maxi(0, rank - 1) * 0.35 + maxi(0, level - 1) * 0.08)
	return {
		"owned": owned.duplicate(),
		"equipped": equipped,
		"name": str(wing.get("name", "未装备翅膀")),
		"level": level,
		"rank": rank,
		"visible": bool(data.get("visible", true)),
		"attack_bonus": float(wing.get("attack", 0.0)) * (1.0 + multiplier),
		"defense_bonus": float(wing.get("defense", 0.0)) * (1.0 + multiplier),
		"health_bonus": float(wing.get("health", 0.0)) * (1.0 + multiplier),
		"cosmos_bonus": float(wing.get("cosmos", 0.0)) * (1.0 + multiplier)
	}

func unlock_wing(wing_id: String) -> bool:
	_ensure_profile_data()
	if not WING_DATA.has(wing_id):
		return false
	var wings: Dictionary = RPGState.profile.get("growth_wings", {}).duplicate(true)
	var owned: Array = wings.get("owned", []).duplicate()
	if owned.has(wing_id):
		return equip_wing(wing_id)
	var cost := int(WING_DATA[wing_id].get("unlock_cost", 0))
	if int(RPGState.profile.get("currency", 0)) < cost:
		return false
	var previous: Dictionary = RPGState.profile.duplicate(true)
	RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
	owned.append(wing_id)
	wings["owned"] = owned
	var levels: Dictionary = wings.get("levels", {}).duplicate(true)
	var ranks: Dictionary = wings.get("ranks", {}).duplicate(true)
	levels[wing_id] = 1
	ranks[wing_id] = 1
	wings["levels"] = levels
	wings["ranks"] = ranks
	wings["equipped"] = wing_id
	RPGState.profile["growth_wings"] = wings
	return _save_change(previous)

func equip_wing(wing_id: String) -> bool:
	_ensure_profile_data()
	if not WING_DATA.has(wing_id):
		return false
	var wings: Dictionary = RPGState.profile.get("growth_wings", {}).duplicate(true)
	if not (wings.get("owned", []) as Array).has(wing_id):
		return false
	var previous: Dictionary = RPGState.profile.duplicate(true)
	wings["equipped"] = wing_id
	RPGState.profile["growth_wings"] = wings
	return _save_change(previous)

func upgrade_wing() -> bool:
	_ensure_profile_data()
	var wings: Dictionary = RPGState.profile.get("growth_wings", {}).duplicate(true)
	var wing_id := str(wings.get("equipped", ""))
	if wing_id.is_empty() or not WING_DATA.has(wing_id):
		return false
	var levels: Dictionary = wings.get("levels", {}).duplicate(true)
	var ranks: Dictionary = wings.get("ranks", {}).duplicate(true)
	var level := int(levels.get(wing_id, 1))
	var rank := int(ranks.get(wing_id, 1))
	if rank >= 5 and level >= 10:
		return false
	var cost := level * 180 + rank * 250
	if int(RPGState.profile.get("currency", 0)) < cost:
		return false
	var previous: Dictionary = RPGState.profile.duplicate(true)
	RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
	if level < 10:
		levels[wing_id] = level + 1
	else:
		levels[wing_id] = 1
		ranks[wing_id] = rank + 1
	wings["levels"] = levels
	wings["ranks"] = ranks
	RPGState.profile["growth_wings"] = wings
	return _save_change(previous)

func set_wing_visible(visible: bool) -> bool:
	_ensure_profile_data()
	var wings: Dictionary = RPGState.profile.get("growth_wings", {}).duplicate(true)
	if bool(wings.get("visible", true)) == visible:
		return true
	var previous: Dictionary = RPGState.profile.duplicate(true)
	wings["visible"] = visible
	RPGState.profile["growth_wings"] = wings
	return _save_change(previous)

func get_cosmos_star_map() -> Dictionary:
	_ensure_profile_data()
	var allocated: Dictionary = RPGState.profile.get("cosmos_star_nodes", {})
	var unlocked_points := clampi(int(RPGState.profile.get("level", 1)) / 3 + int(RPGState.get_cosmos_profile().get("level", 1)) / 5, 0, 30)
	var used_points := 0
	var bonuses := {"attack": 0.0, "defense": 0.0, "max_health": 0.0, "max_cosmos": 0.0, "cosmos_regen": 0.0, "critical_rate": 0.0}
	var nodes: Array[Dictionary] = []
	for node_id in COSMOS_NODES:
		var definition: Dictionary = COSMOS_NODES[node_id]
		var rank := int(allocated.get(node_id, 0))
		used_points += rank
		var attribute := str(definition.get("attribute", ""))
		if bonuses.has(attribute):
			bonuses[attribute] = float(bonuses[attribute]) + float(definition.get("value", 0.0)) * rank
		var item: Dictionary = definition.duplicate(true)
		item["id"] = node_id
		item["rank"] = rank
		item["unlocked"] = int(RPGState.profile.get("level", 1)) >= int(definition.get("level_required", 1))
		nodes.append(item)
	return {"nodes": nodes, "allocated": allocated.duplicate(true), "available_points": maxi(0, unlocked_points - used_points), "used_points": used_points, "unlocked_points": unlocked_points, "bonuses": bonuses}

func allocate_cosmos_node(node_id: String) -> bool:
	_ensure_profile_data()
	if not COSMOS_NODES.has(node_id):
		return false
	var definition: Dictionary = COSMOS_NODES[node_id]
	if int(RPGState.profile.get("level", 1)) < int(definition.get("level_required", 1)):
		return false
	var star_map: Dictionary = get_cosmos_star_map()
	if int(star_map.get("available_points", 0)) <= 0:
		return false
	var allocated: Dictionary = RPGState.profile.get("cosmos_star_nodes", {}).duplicate(true)
	var rank := int(allocated.get(node_id, 0))
	if rank >= int(definition.get("max_rank", 5)):
		return false
	var cost := int(definition.get("cost", 100)) * (rank + 1)
	if int(RPGState.profile.get("currency", 0)) < cost:
		return false
	var previous: Dictionary = RPGState.profile.duplicate(true)
	RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
	allocated[node_id] = rank + 1
	RPGState.profile["cosmos_star_nodes"] = allocated
	return _save_change(previous)

func reset_cosmos_star_map() -> bool:
	_ensure_profile_data()
	var allocated: Dictionary = RPGState.profile.get("cosmos_star_nodes", {})
	if allocated.is_empty():
		return false
	var previous: Dictionary = RPGState.profile.duplicate(true)
	RPGState.profile["cosmos_star_nodes"] = {}
	return _save_change(previous)

func get_growth_stat_bonus() -> Dictionary:
	var wings: Dictionary = get_wing_profile()
	var star_map: Dictionary = get_cosmos_star_map()
	var nodes: Dictionary = star_map.get("bonuses", {})
	return {
		"attack": float(wings.get("attack_bonus", 0.0)) + float(nodes.get("attack", 0.0)),
		"defense": float(wings.get("defense_bonus", 0.0)) + float(nodes.get("defense", 0.0)),
		"max_health": float(wings.get("health_bonus", 0.0)) + float(nodes.get("max_health", 0.0)),
		"max_cosmos": float(wings.get("cosmos_bonus", 0.0)) + float(nodes.get("max_cosmos", 0.0)),
		"cosmos_regen": float(nodes.get("cosmos_regen", 0.0)),
		"critical_rate": float(nodes.get("critical_rate", 0.0))
	}

func get_power_breakdown() -> Dictionary:
	var stats: Dictionary = RPGState.get_combat_stats()
	var cosmos: Dictionary = RPGState.get_cosmos_profile()
	var wings: Dictionary = get_wing_profile()
	var star_map: Dictionary = get_cosmos_star_map()
	var nodes: Dictionary = star_map.get("bonuses", {})
	var class_power := float(RPGState.profile.get("level", 1)) * 18.0
	var attribute_power := float(stats.get("max_health", 0.0)) * 0.12 + float(stats.get("attack", 0.0)) * 5.0 + float(stats.get("defense", 0.0)) * 3.0 + float(stats.get("speed", 0.0)) * 2.0
	var cosmos_power := float(cosmos.get("level", 1)) * 22.0
	var wing_power := float(wings.get("rank", 0)) * 85.0 + float(wings.get("level", 0)) * 12.0
	var star_power := float(star_map.get("used_points", 0)) * 45.0
	var total := int(round(class_power + attribute_power + cosmos_power + wing_power + star_power))
	return {
		"total": total,
		"breakdown": {
			"等级与职业": int(round(class_power)),
			"基础属性与装备": int(round(attribute_power)),
			"小宇宙境界": int(round(cosmos_power)),
			"翅膀成长": int(round(wing_power)),
			"小宇宙星盘": int(round(star_power))
		},
		"stats": stats,
		"cosmos": cosmos,
		"wings": wings,
		"star_map": star_map
	}
