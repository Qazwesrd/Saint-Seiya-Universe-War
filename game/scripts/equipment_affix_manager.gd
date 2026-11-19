extends Node
## Offline equipment affixes and bronze-set resonance. Rolls are stored per equipment slot.

const AFFIX_POOL := [
    {"id":"might","name":"强袭","attack":3.0,"defense":0.0,"max_health":0.0,"speed":0.0,"max_cosmos":0.0},
    {"id":"guard","name":"坚壁","attack":0.0,"defense":3.0,"max_health":0.0,"speed":0.0,"max_cosmos":0.0},
    {"id":"vitality","name":"生命","attack":0.0,"defense":0.0,"max_health":35.0,"speed":0.0,"max_cosmos":0.0},
    {"id":"swiftness","name":"迅捷","attack":0.0,"defense":0.0,"max_health":0.0,"speed":1.5,"max_cosmos":0.0},
    {"id":"cosmos","name":"小宇宙","attack":0.0,"defense":0.0,"max_health":0.0,"speed":0.0,"max_cosmos":18.0}
]

const EMPTY_STATS := {"attack":0.0,"defense":0.0,"max_health":0.0,"speed":0.0,"max_cosmos":0.0}

func roll_affixes(slot: String, tier: int = 1) -> bool:
    var equipment: Dictionary = RPGState.profile.get("equipment", {})
    var item_id := str(equipment.get(slot, ""))
    if item_id == "" or not RPGState.ITEM_DATA.has(item_id):
        return false
    var count := clampi(tier, 1, 3)
    var pool: Array = AFFIX_POOL.duplicate(true)
    var rolled: Array = []
    for index in range(count):
        if pool.is_empty():
            break
        var chosen_index := randi_range(0, pool.size() - 1)
        rolled.append(pool[chosen_index].duplicate(true))
        pool.remove_at(chosen_index)
    var previous: Dictionary = RPGState.profile.get("equipment_affixes", {}).duplicate(true)
    var affixes: Dictionary = previous.duplicate(true)
    affixes[slot] = rolled
    RPGState.profile["equipment_affixes"] = affixes
    if not RPGState.save_slot(RPGState.active_slot):
        RPGState.profile["equipment_affixes"] = previous
        return false
    RPGState.state_changed.emit()
    return true

func clear_affixes(slot: String) -> bool:
    var previous: Dictionary = RPGState.profile.get("equipment_affixes", {}).duplicate(true)
    if not previous.has(slot):
        return false
    var affixes := previous.duplicate(true)
    affixes.erase(slot)
    RPGState.profile["equipment_affixes"] = affixes
    if not RPGState.save_slot(RPGState.active_slot):
        RPGState.profile["equipment_affixes"] = previous
        return false
    RPGState.state_changed.emit()
    return true

func get_bonus_stats() -> Dictionary:
    var result: Dictionary = EMPTY_STATS.duplicate(true)
    var equipped: Dictionary = RPGState.profile.get("equipment", {})
    var affixes: Dictionary = RPGState.profile.get("equipment_affixes", {})
    for slot in affixes:
        if str(equipped.get(slot, "")) == "":
            continue
        for affix in affixes[slot]:
            for stat in result:
                result[stat] = float(result[stat]) + float(affix.get(stat, 0.0))
    var bronze_count := 0
    for slot in ["head", "chest", "arms", "legs"]:
        var item_id := str(equipped.get(slot, ""))
        if item_id.begins_with("bronze_") or item_id in ["pegasus_bracer", "dragon_shield", "cygnus_claw", "andromeda_chain", "phoenix_fist", "tenmou_armor"]:
            bronze_count += 1
    if bronze_count >= 2:
        result["defense"] += 3.0
    if bronze_count >= 3:
        result["max_health"] += 45.0
    if bronze_count >= 4:
        result["attack"] += 8.0
        result["max_cosmos"] += 20.0
    return result

func get_equipped_affixes() -> Dictionary:
    return RPGState.profile.get("equipment_affixes", {}).duplicate(true)
