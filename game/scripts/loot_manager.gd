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
	]
}

func roll_enemy_drops(is_boss: bool, enemy_level: int = 1) -> Array[Dictionary]:
	var table: Array = DROP_TABLES["boss" if is_boss else "normal"]
	var level_bonus := clampf(float(maxi(1, enemy_level) - 1) * 0.002, 0.0, 0.12)
	var awarded: Array[Dictionary] = []
	for entry in table:
		var item_id := str(entry.get("item_id", ""))
		if not RPGState.ITEM_DATA.has(item_id):
			continue
		var chance := clampf(float(entry.get("chance", 0.0)) + level_bonus, 0.0, 0.95)
		if randf() > chance:
			continue
		var quantity := randi_range(maxi(1, int(entry.get("min", 1))), maxi(1, int(entry.get("max", 1))))
		if grant_drop(item_id, quantity):
			awarded.append({
				"item_id": item_id,
				"name": str(RPGState.ITEM_DATA[item_id].get("name", item_id)),
				"quantity": quantity
			})
	if not awarded.is_empty():
		loot_awarded.emit(awarded)
		EventBus.inventory_changed.emit(RPGState.profile.get("inventory", {}).duplicate(true))
	return awarded

func grant_drop(item_id: String, quantity: int = 1) -> bool:
	if not RPGState.ITEM_DATA.has(item_id) or quantity <= 0:
		return false
	return RPGState.add_item(item_id, quantity)

func get_drop_table(is_boss: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in DROP_TABLES["boss" if is_boss else "normal"]:
		result.append(entry.duplicate(true))
	return result
