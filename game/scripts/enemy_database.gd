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
    },
    "gold_taurus": {"boss_windup":1.25,"boss_heavy_interval":2,"boss_heavy_multiplier":1.9,"boss_range_multiplier":1.8,"boss_recovery":0.95,"name":"金牛座阿鲁迪巴","is_boss":true,"health":520.0,"speed":1.9,"attack_damage":24.0,"attack_range":3.0,"attack_interval":2.0,"exp_reward":180,"coin_reward":150,"drop_tier":"boss","color":Color(0.72,0.48,0.12)},
    "gemini_illusion": {"name":"双子宫异次元幻象","is_boss":false,"health":110.0,"speed":2.7,"attack_damage":13.0,"attack_range":2.2,"attack_interval":1.35,"exp_reward":45,"coin_reward":35,"drop_tier":"normal","color":Color(0.28,0.32,0.72)},
    "gold_cancer": {"boss_windup":0.9,"boss_heavy_interval":3,"boss_heavy_multiplier":1.45,"boss_range_multiplier":1.7,"boss_recovery":0.65,"name":"巨蟹座迪斯马斯克","is_boss":true,"health":560.0,"speed":2.15,"attack_damage":26.0,"attack_range":2.7,"attack_interval":1.85,"exp_reward":210,"coin_reward":170,"drop_tier":"boss","color":Color(0.22,0.58,0.42)},
    "gold_leo_controlled": {"boss_windup":0.62,"boss_heavy_interval":3,"boss_heavy_multiplier":1.35,"boss_range_multiplier":1.25,"boss_recovery":0.42,"name":"受控制的狮子座艾欧里亚","is_boss":true,"health":610.0,"speed":3.0,"attack_damage":28.0,"attack_range":2.8,"attack_interval":1.45,"exp_reward":230,"coin_reward":180,"drop_tier":"boss","color":Color(0.86,0.62,0.16)},
    "gold_virgo": {"boss_windup":1.4,"boss_heavy_interval":2,"boss_heavy_multiplier":1.65,"boss_range_multiplier":1.9,"boss_recovery":1.0,"name":"处女座沙加","is_boss":true,"health":640.0,"speed":2.1,"attack_damage":30.0,"attack_range":3.2,"attack_interval":2.1,"exp_reward":250,"coin_reward":190,"drop_tier":"boss","color":Color(0.78,0.72,0.38)},
    "gold_scorpio": {"boss_windup":0.55,"boss_heavy_interval":4,"boss_heavy_multiplier":1.25,"boss_range_multiplier":1.1,"boss_recovery":0.38,"name":"天蝎座米罗","is_boss":true,"health":660.0,"speed":2.85,"attack_damage":29.0,"attack_range":2.5,"attack_interval":1.35,"exp_reward":270,"coin_reward":205,"drop_tier":"boss","color":Color(0.72,0.12,0.22)},
    "gold_capricorn": {"boss_windup":0.82,"boss_heavy_interval":2,"boss_heavy_multiplier":1.75,"boss_range_multiplier":1.65,"boss_recovery":0.68,"name":"摩羯座修罗","is_boss":true,"health":690.0,"speed":2.6,"attack_damage":33.0,"attack_range":3.4,"attack_interval":1.7,"exp_reward":290,"coin_reward":220,"drop_tier":"boss","color":Color(0.58,0.62,0.68)},
    "gold_aquarius": {"boss_windup":1.35,"boss_heavy_interval":3,"boss_heavy_multiplier":1.6,"boss_range_multiplier":1.75,"boss_recovery":0.88,"name":"水瓶座卡妙","is_boss":true,"health":710.0,"speed":2.0,"attack_damage":32.0,"attack_range":3.1,"attack_interval":2.0,"exp_reward":310,"coin_reward":235,"drop_tier":"boss","color":Color(0.24,0.72,0.88)},
    "gold_pisces": {"boss_windup":0.95,"boss_heavy_interval":3,"boss_heavy_multiplier":1.5,"boss_range_multiplier":1.45,"boss_recovery":0.6,"name":"双鱼座阿布罗狄","is_boss":true,"health":730.0,"speed":2.35,"attack_damage":34.0,"attack_range":2.9,"attack_interval":1.8,"exp_reward":330,"coin_reward":250,"drop_tier":"boss","color":Color(0.82,0.36,0.68)},
    "pope_saga": {"boss_windup":1.15,"boss_heavy_interval":2,"boss_heavy_multiplier":1.85,"boss_range_multiplier":1.9,"boss_recovery":0.9,"name":"教皇撒加","is_boss":true,"health":980.0,"speed":2.4,"attack_damage":42.0,"attack_range":3.6,"attack_interval":1.65,"exp_reward":500,"coin_reward":380,"drop_tier":"boss","color":Color(0.48,0.22,0.72)}
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
