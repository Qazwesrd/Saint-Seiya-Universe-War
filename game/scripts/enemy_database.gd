extends Node
## Offline enemy archetype definitions. All combat tuning lives here rather than in scene code.

const ARCHETYPES := {
    "arena_guard": {
        "name": "银河竞技场守卫",
        "is_boss": false,
        "health": 65.0,
        "speed": 2.5,
        "attack_damage": 7.0,
        "attack_range": 2.0,
        "attack_interval": 1.6,
        "exp_reward": 30,
        "coin_reward": 40,
        "drop_tier": "normal",
        "color": Color(0.72, 0.16, 0.22)
    },
    "arena_elite": {
        "name": "银河竞技场精英",
        "is_boss": false,
        "health": 145.0,
        "speed": 2.15,
        "attack_damage": 11.0,
        "attack_range": 2.35,
        "attack_interval": 1.45,
        "exp_reward": 55,
        "coin_reward": 75,
        "drop_tier": "normal",
        "color": Color(0.78, 0.36, 0.12)
    },
    "arena_boss": {
        "name": "银河竞技场训练 Boss",
        "is_boss": true,
        "health": 260.0,
        "speed": 1.8,
        "attack_damage": 16.0,
        "attack_range": 2.8,
        "attack_interval": 2.2,
        "exp_reward": 90,
        "coin_reward": 120,
        "drop_tier": "boss",
        "color": Color(0.36, 0.08, 0.55)
    }
}

func get_archetype(archetype_id: String) -> Dictionary:
    return ARCHETYPES.get(archetype_id, ARCHETYPES["arena_guard"]).duplicate(true)

func get_catalog() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for archetype_id in ARCHETYPES:
        var entry: Dictionary = ARCHETYPES[archetype_id].duplicate(true)
        entry["id"] = archetype_id
        result.append(entry)
    return result

func has_archetype(archetype_id: String) -> bool:
    return ARCHETYPES.has(archetype_id)
