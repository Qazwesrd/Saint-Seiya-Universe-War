extends Node
## 离线战利品表。所有奖励均为游戏内物品，不涉及真实货币。
signal loot_awarded(items: Array)

const DROP_TABLES := {
	"normal": [
		{"item_id": "cosmos_potion", "chance": 0.22, "min": 1, "max": 1},
		{"item_id": "bronze_helmet", "chance": 0.025, "min": 1, "max": 1},
		{"item_id": "bronze_greaves", "chance": 0.012, "min": 1, "max": 1}
	],
	"boss": [
		{"item_id": "cosmos_potion", "chance": 0.70, "min": 1, "max": 2},
		{"item_id": "bronze_helmet", "chance": 0.28, "min": 1, "max": 1},
		{"item_id": "bronze_chest", "chance": 0.16, "min": 1, "max": 1},
		{"item_id": "bronze_greaves", "chance": 0.22, "min": 1, "max": 1}
	],
	"dark": [
		{"item_id": "cosmos_potion", "chance": 0.32, "min": 1, "max": 1},
		{"item_id": "dark_cosmos_fragment", "chance": 0.18, "min": 1, "max": 1}
	],
	"dark_elite": [
		{"item_id": "cosmos_potion", "chance": 0.58, "min": 1, "max": 2},
		{"item_id": "dark_cosmos_fragment", "chance": 0.52, "min": 1, "max": 2},
		{"item_id": "platinum_star_shard", "chance": 0.12, "min": 1, "max": 1}
	],
	"dark_boss": [
		{"item_id": "cosmos_potion", "chance": 0.72, "min": 1, "max": 2},
		{"item_id": "dark_cosmos_fragment", "chance": 0.78, "min": 1, "max": 2},
		{"item_id": "platinum_star_shard", "chance": 0.28, "min": 1, "max": 2}
	]
}

func roll_enemy_drops(is_boss: bool, enemy_level: int = 1, auto_pickup: bool = true, archetype_id: String = "") -> Array[Dictionary]:
	var dark_boss_ids := ["dark_phoenix_revenant", "dark_dragon_wraith", "dark_black_knight_champion"]
	var dark_elite_ids := ["dark_saint_elite", "dark_saint_captain"]
	var dark_scout_ids := ["dark_saint_scout", "dark_saint_raider"]
	var table_key := "dark_boss" if dark_boss_ids.has(archetype_id) else ("dark_elite" if dark_elite_ids.has(archetype_id) else ("dark" if dark_scout_ids.has(archetype_id) else ("boss" if is_boss else "normal")))
	var table: Array = DROP_TABLES[table_key]
	var level_bonus := clampf(float(maxi(1, enemy_level) - 1) * 0.002, 0.0, 0.12)
	var awarded: Array[Dictionary] = []
	var batch: Dictionary = {}
	for entry in table:
		var item_id := str(entry.get("item_id", ""))
		if not RPGState.ITEM_DATA.has(item_id):
			continue
		var chance := clampf(float(entry.get("chance", 0.0)) + level_bonus, 0.0, 0.95)
		if randf() > chance:
			continue
		var quantity := randi_range(maxi(1, int(entry.get("min", 1))), maxi(1, int(entry.get("max", 1))))
		batch[item_id] = int(batch.get(item_id, 0)) + quantity
		awarded.append({
				"item_id": item_id,
				"name": str(RPGState.ITEM_DATA[item_id].get("name", item_id)),
				"quantity": quantity
			})
	if not awarded.is_empty() and auto_pickup:
		if not RPGState.add_items(batch):
			SystemHealthManager.report_error("loot", "战利品入账失败", JSON.stringify(batch))
			return []
		loot_awarded.emit(awarded)
	return awarded

func grant_drop(item_id: String, quantity: int = 1) -> bool:
	if not RPGState.ITEM_DATA.has(item_id) or quantity <= 0:
		return false
	if not RPGState.add_item(item_id, quantity):
		return false
	loot_awarded.emit([{"item_id": item_id, "name": str(RPGState.ITEM_DATA[item_id].get("name", item_id)), "quantity": quantity}])
	return true

func get_drop_table(is_boss: bool, archetype_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dark_boss_ids := ["dark_phoenix_revenant", "dark_dragon_wraith", "dark_black_knight_champion"]
	var dark_elite_ids := ["dark_saint_elite", "dark_saint_captain"]
	var dark_scout_ids := ["dark_saint_scout", "dark_saint_raider"]
	var table_key := "dark_boss" if dark_boss_ids.has(archetype_id) else ("dark_elite" if dark_elite_ids.has(archetype_id) else ("dark" if dark_scout_ids.has(archetype_id) else ("boss" if is_boss else "normal")))
	for entry in DROP_TABLES[table_key]:
		result.append(entry.duplicate(true))
	return result
