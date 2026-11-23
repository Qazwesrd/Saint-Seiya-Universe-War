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
    "gold_taurus": {"boss_special":"gravity_crush","boss_windup":1.25,"boss_heavy_interval":2,"boss_heavy_multiplier":1.9,"boss_range_multiplier":1.8,"boss_recovery":0.95,"name":"金牛座阿鲁迪巴","is_boss":true,"health":520.0,"speed":1.9,"attack_damage":24.0,"attack_range":3.0,"attack_interval":2.0,"exp_reward":180,"coin_reward":150,"drop_tier":"boss","color":Color(0.72,0.48,0.12)},
    "gemini_illusion": {"name":"双子宫异次元幻象","is_boss":false,"health":110.0,"speed":2.7,"attack_damage":13.0,"attack_range":2.2,"attack_interval":1.35,"exp_reward":45,"coin_reward":35,"drop_tier":"normal","color":Color(0.28,0.32,0.72)},
    "gold_cancer": {"boss_special":"soul_leech","boss_windup":0.9,"boss_heavy_interval":3,"boss_heavy_multiplier":1.45,"boss_range_multiplier":1.7,"boss_recovery":0.65,"name":"巨蟹座迪斯马斯克","is_boss":true,"health":560.0,"speed":2.15,"attack_damage":26.0,"attack_range":2.7,"attack_interval":1.85,"exp_reward":210,"coin_reward":170,"drop_tier":"boss","color":Color(0.22,0.58,0.42)},
    "gold_leo_controlled": {"boss_special":"lightning_followup","boss_windup":0.62,"boss_heavy_interval":3,"boss_heavy_multiplier":1.35,"boss_range_multiplier":1.25,"boss_recovery":0.42,"name":"受控制的狮子座艾欧里亚","is_boss":true,"health":610.0,"speed":3.0,"attack_damage":28.0,"attack_range":2.8,"attack_interval":1.45,"exp_reward":230,"coin_reward":180,"drop_tier":"boss","color":Color(0.86,0.62,0.16)},
    "gold_virgo": {"boss_special":"dream_drain","boss_windup":1.4,"boss_heavy_interval":2,"boss_heavy_multiplier":1.65,"boss_range_multiplier":1.9,"boss_recovery":1.0,"name":"处女座沙加","is_boss":true,"health":640.0,"speed":2.1,"attack_damage":30.0,"attack_range":3.2,"attack_interval":2.1,"exp_reward":250,"coin_reward":190,"drop_tier":"boss","color":Color(0.78,0.72,0.38)},
    "gold_scorpio": {"boss_special":"death_burst","boss_windup":0.55,"boss_heavy_interval":4,"boss_heavy_multiplier":1.25,"boss_range_multiplier":1.1,"boss_recovery":0.38,"name":"天蝎座米罗","is_boss":true,"health":660.0,"speed":2.85,"attack_damage":29.0,"attack_range":2.5,"attack_interval":1.35,"exp_reward":270,"coin_reward":205,"drop_tier":"boss","color":Color(0.72,0.12,0.22)},
    "gold_capricorn": {"boss_special":"wing_slam","boss_windup":0.82,"boss_heavy_interval":2,"boss_heavy_multiplier":1.75,"boss_range_multiplier":1.65,"boss_recovery":0.68,"name":"摩羯座修罗","is_boss":true,"health":690.0,"speed":2.6,"attack_damage":33.0,"attack_range":3.4,"attack_interval":1.7,"exp_reward":290,"coin_reward":220,"drop_tier":"boss","color":Color(0.58,0.62,0.68)},
    "gold_aquarius": {"boss_special":"rift_drain","boss_windup":1.35,"boss_heavy_interval":3,"boss_heavy_multiplier":1.6,"boss_range_multiplier":1.75,"boss_recovery":0.88,"name":"水瓶座卡妙","is_boss":true,"health":710.0,"speed":2.0,"attack_damage":32.0,"attack_range":3.1,"attack_interval":2.0,"exp_reward":310,"coin_reward":235,"drop_tier":"boss","color":Color(0.24,0.72,0.88)},
    "gold_pisces": {"boss_special":"tidal_pull","boss_windup":0.95,"boss_heavy_interval":3,"boss_heavy_multiplier":1.5,"boss_range_multiplier":1.45,"boss_recovery":0.6,"name":"双鱼座阿布罗狄","is_boss":true,"health":730.0,"speed":2.35,"attack_damage":34.0,"attack_range":2.9,"attack_interval":1.8,"exp_reward":330,"coin_reward":250,"drop_tier":"boss","color":Color(0.82,0.36,0.68)},
    "pope_saga": {"boss_special":"void_drain","boss_windup":1.15,"boss_heavy_interval":2,"boss_heavy_multiplier":1.85,"boss_range_multiplier":1.9,"boss_recovery":0.9,"name":"教皇撒加","is_boss":true,"health":980.0,"speed":2.4,"attack_damage":42.0,"attack_range":3.6,"attack_interval":1.65,"exp_reward":500,"coin_reward":380,"drop_tier":"boss","color":Color(0.48,0.22,0.72)},
    "god_warrior_thor": {"boss_special":"gravity_crush","boss_windup":1.3,"boss_heavy_interval":2,"boss_heavy_multiplier":2.0,"boss_range_multiplier":2.0,"boss_recovery":1.0,"name":"阿尔法星神斗士托尔","is_boss":true,"health":820.0,"speed":1.85,"attack_damage":38.0,"attack_range":3.8,"attack_interval":2.2,"exp_reward":360,"coin_reward":260,"drop_tier":"boss","color":Color(0.48,0.68,0.86)},
    "asgard_wolf": {"name":"北欧冰原狼","is_boss":false,"health":125.0,"speed":3.2,"attack_damage":16.0,"attack_range":1.8,"attack_interval":1.2,"exp_reward":45,"coin_reward":30,"drop_tier":"normal","color":Color(0.55,0.62,0.72)},
    "god_warrior_fenrir": {"boss_special":"wing_slam","boss_windup":0.55,"boss_heavy_interval":4,"boss_heavy_multiplier":1.35,"boss_range_multiplier":1.25,"boss_recovery":0.4,"name":"贝塔星神斗士芬里尔","is_boss":true,"health":760.0,"speed":3.0,"attack_damage":34.0,"attack_range":2.5,"attack_interval":1.3,"exp_reward":370,"coin_reward":270,"drop_tier":"boss","color":Color(0.48,0.72,0.82)},
    "god_warrior_hagen": {"boss_special":"frostfire","boss_windup":0.9,"boss_heavy_interval":3,"boss_heavy_multiplier":1.65,"boss_range_multiplier":1.6,"boss_recovery":0.7,"name":"伽马星神斗士哈根","is_boss":true,"health":790.0,"speed":2.3,"attack_damage":36.0,"attack_range":3.0,"attack_interval":1.8,"exp_reward":380,"coin_reward":280,"drop_tier":"boss","color":Color(0.28,0.68,0.92)},
    "god_warrior_mime": {"boss_special":"sonic_wave","boss_windup":0.75,"boss_heavy_interval":3,"boss_heavy_multiplier":1.45,"boss_range_multiplier":1.5,"boss_recovery":0.55,"name":"德尔塔星神斗士米伊美","is_boss":true,"health":800.0,"speed":2.7,"attack_damage":37.0,"attack_range":2.8,"attack_interval":1.6,"exp_reward":390,"coin_reward":290,"drop_tier":"boss","color":Color(0.7,0.42,0.8)},
    "god_warrior_alberich": {"boss_special":"crystal_seal","boss_windup":1.0,"boss_heavy_interval":3,"boss_heavy_multiplier":1.6,"boss_range_multiplier":1.7,"boss_recovery":0.75,"name":"艾普西隆星神斗士阿鲁贝利西","is_boss":true,"health":830.0,"speed":2.25,"attack_damage":39.0,"attack_range":3.1,"attack_interval":1.9,"exp_reward":400,"coin_reward":300,"drop_tier":"boss","color":Color(0.46,0.32,0.68)},
    "god_warrior_syd": {"boss_special":"lightning_followup","boss_windup":0.7,"boss_heavy_interval":3,"boss_heavy_multiplier":1.5,"boss_range_multiplier":1.4,"boss_recovery":0.5,"name":"捷克弗里德","is_boss":true,"health":850.0,"speed":2.65,"attack_damage":40.0,"attack_range":2.9,"attack_interval":1.55,"exp_reward":410,"coin_reward":305,"drop_tier":"boss","color":Color(0.58,0.7,0.86)},
    "god_warrior_bud": {"boss_special":"death_burst","boss_windup":0.58,"boss_heavy_interval":4,"boss_heavy_multiplier":1.4,"boss_range_multiplier":1.35,"boss_recovery":0.42,"name":"巴度","is_boss":true,"health":790.0,"speed":3.0,"attack_damage":38.0,"attack_range":2.7,"attack_interval":1.35,"exp_reward":410,"coin_reward":305,"drop_tier":"boss","color":Color(0.42,0.56,0.78)},
    "god_warrior_siegfried": {"boss_special":"judge_combo","boss_windup":1.25,"boss_heavy_interval":2,"boss_heavy_multiplier":2.1,"boss_range_multiplier":1.9,"boss_recovery":0.95,"name":"阿尔法星神斗士齐格弗里德","is_boss":true,"health":1120.0,"speed":2.5,"attack_damage":46.0,"attack_range":3.7,"attack_interval":1.7,"exp_reward":520,"coin_reward":390,"drop_tier":"boss","color":Color(0.62,0.78,0.92)},
    "mariner_baian": {"boss_special":"tidal_pull","boss_windup":0.95,"boss_heavy_interval":3,"boss_heavy_multiplier":1.65,"boss_range_multiplier":1.7,"boss_recovery":0.72,"name":"海马座海将军拜安","is_boss":true,"health":1050.0,"speed":2.45,"attack_damage":44.0,"attack_range":3.3,"attack_interval":1.8,"exp_reward":560,"coin_reward":420,"drop_tier":"boss","color":Color(0.2,0.62,0.86)},
    "mariner_io": {"boss_special":"six_beasts","boss_windup":0.62,"boss_heavy_interval":4,"boss_heavy_multiplier":1.4,"boss_range_multiplier":1.4,"boss_recovery":0.45,"name":"六圣兽海将军伊奥","is_boss":true,"health":1080.0,"speed":2.9,"attack_damage":45.0,"attack_range":2.8,"attack_interval":1.4,"exp_reward":580,"coin_reward":430,"drop_tier":"boss","color":Color(0.22,0.68,0.72)},
    "mariner_krishna": {"boss_special":"gravity_crush","boss_windup":1.1,"boss_heavy_interval":2,"boss_heavy_multiplier":1.9,"boss_range_multiplier":1.8,"boss_recovery":0.88,"name":"海皇子克修拉","is_boss":true,"health":1120.0,"speed":2.15,"attack_damage":48.0,"attack_range":3.5,"attack_interval":2.0,"exp_reward":600,"coin_reward":445,"drop_tier":"boss","color":Color(0.82,0.62,0.22)},
    "mariner_kasa": {"boss_special":"mirror_feint","boss_windup":0.72,"boss_heavy_interval":3,"boss_heavy_multiplier":1.5,"boss_range_multiplier":1.5,"boss_recovery":0.55,"name":"海魔女卡萨","is_boss":true,"health":1090.0,"speed":2.7,"attack_damage":46.0,"attack_range":3.0,"attack_interval":1.55,"exp_reward":610,"coin_reward":450,"drop_tier":"boss","color":Color(0.58,0.34,0.76)},
    "mariner_isaac": {"boss_special":"rift_drain","boss_windup":0.9,"boss_heavy_interval":3,"boss_heavy_multiplier":1.7,"boss_range_multiplier":1.65,"boss_recovery":0.7,"name":"海魔兽艾萨克","is_boss":true,"health":1150.0,"speed":2.35,"attack_damage":49.0,"attack_range":3.2,"attack_interval":1.75,"exp_reward":630,"coin_reward":465,"drop_tier":"boss","color":Color(0.28,0.7,0.9)},
    "mariner_sorrento": {"boss_special":"sonic_wave","boss_windup":1.25,"boss_heavy_interval":2,"boss_heavy_multiplier":1.75,"boss_range_multiplier":1.8,"boss_recovery":0.9,"name":"海妖苏兰特","is_boss":true,"health":1110.0,"speed":2.0,"attack_damage":47.0,"attack_range":3.6,"attack_interval":2.1,"exp_reward":640,"coin_reward":470,"drop_tier":"boss","color":Color(0.72,0.5,0.82)},
    "mariner_kanon": {"boss_special":"void_drain","boss_windup":0.68,"boss_heavy_interval":3,"boss_heavy_multiplier":1.85,"boss_range_multiplier":1.7,"boss_recovery":0.52,"name":"海龙加隆","is_boss":true,"health":1280.0,"speed":2.8,"attack_damage":52.0,"attack_range":3.4,"attack_interval":1.5,"exp_reward":700,"coin_reward":520,"drop_tier":"boss","color":Color(0.16,0.48,0.82)},
    "poseidon_emperor": {"boss_special":"tidal_pull","boss_windup":1.45,"boss_heavy_interval":2,"boss_heavy_multiplier":2.2,"boss_range_multiplier":2.1,"boss_recovery":1.1,"name":"海皇波塞冬","is_boss":true,"health":1680.0,"speed":2.1,"attack_damage":62.0,"attack_range":4.0,"attack_interval":1.9,"exp_reward":900,"coin_reward":700,"drop_tier":"boss","color":Color(0.12,0.38,0.78)},
    "hades_specter": {"name":"冥界冥斗士","is_boss":false,"health":520.0,"speed":2.8,"attack_damage":38.0,"attack_range":2.5,"attack_interval":1.45,"exp_reward":180,"coin_reward":120,"drop_tier":"normal","color":Color(0.32,0.22,0.48)},
    "hades_wraith": {"name":"冥界怨灵","is_boss":false,"health":430.0,"speed":3.2,"attack_damage":34.0,"attack_range":2.0,"attack_interval":1.3,"exp_reward":150,"coin_reward":105,"drop_tier":"normal","color":Color(0.48,0.42,0.62)},
    "judge_griffin": {"boss_special":"gravity_crush","boss_windup":0.85,"boss_heavy_interval":3,"boss_heavy_multiplier":1.8,"boss_range_multiplier":1.7,"boss_recovery":0.7,"name":"天贵星米诺斯","is_boss":true,"health":2850.0,"speed":2.6,"attack_damage":88.0,"attack_range":3.4,"attack_interval":1.55,"exp_reward":900,"coin_reward":620,"drop_tier":"boss","color":Color(0.62,0.42,0.72)},
    "judge_garuda": {"boss_special":"judge_combo","boss_windup":0.72,"boss_heavy_interval":3,"boss_heavy_multiplier":1.9,"boss_range_multiplier":1.6,"boss_recovery":0.58,"name":"天雄星艾亚哥斯","is_boss":true,"health":2700.0,"speed":3.1,"attack_damage":84.0,"attack_range":3.1,"attack_interval":1.4,"exp_reward":880,"coin_reward":600,"drop_tier":"boss","color":Color(0.72,0.32,0.22)},
    "judge_wyvern": {"boss_special":"wing_slam","boss_windup":0.95,"boss_heavy_interval":2,"boss_heavy_multiplier":2.1,"boss_range_multiplier":1.8,"boss_recovery":0.8,"name":"天猛星拉达曼迪斯","is_boss":true,"health":3200.0,"speed":2.7,"attack_damage":96.0,"attack_range":3.6,"attack_interval":1.65,"exp_reward":1050,"coin_reward":720,"drop_tier":"boss","color":Color(0.42,0.16,0.24)},
    "cocytus_guard": {"name":"冰狱守卫","is_boss":false,"health":760.0,"speed":2.1,"attack_damage":48.0,"attack_range":2.6,"attack_interval":1.7,"exp_reward":220,"coin_reward":155,"drop_tier":"normal","color":Color(0.28,0.62,0.82)},
    "wailing_wall_guard": {"name":"叹息之墙守卫","is_boss":false,"health":920.0,"speed":1.8,"attack_damage":56.0,"attack_range":2.8,"attack_interval":1.9,"exp_reward":260,"coin_reward":180,"drop_tier":"normal","color":Color(0.52,0.48,0.68)},
    "hypnos_guardian": {"boss_special":"sleeping_field","boss_windup":1.35,"boss_heavy_interval":2,"boss_heavy_multiplier":2.0,"boss_range_multiplier":1.9,"boss_recovery":0.95,"name":"睡神修普诺斯","is_boss":true,"health":3900.0,"speed":2.0,"attack_damage":105.0,"attack_range":3.8,"attack_interval":2.0,"exp_reward":1250,"coin_reward":850,"drop_tier":"boss","color":Color(0.72,0.72,0.92)},
    "thanatos_reaper": {"boss_special":"death_mark","boss_windup":0.72,"boss_heavy_interval":2,"boss_heavy_multiplier":2.3,"boss_range_multiplier":1.8,"boss_recovery":0.62,"name":"死神达纳托斯","is_boss":true,"health":4200.0,"speed":2.9,"attack_damage":118.0,"attack_range":3.6,"attack_interval":1.55,"exp_reward":1400,"coin_reward":950,"drop_tier":"boss","color":Color(0.42,0.12,0.22)},
    "hades_emperor": {"boss_special":"soul_leech","boss_windup":1.5,"boss_heavy_interval":2,"boss_heavy_multiplier":2.5,"boss_range_multiplier":2.2,"boss_recovery":1.15,"name":"冥王哈迪斯","is_boss":true,"health":5600.0,"speed":2.35,"attack_damage":138.0,"attack_range":4.2,"attack_interval":1.85,"exp_reward":1800,"coin_reward":1200,"drop_tier":"boss","color":Color(0.28,0.12,0.42)},
    "heaven_gatekeeper": {"boss_special":"wing_slam","boss_windup":0.95,"boss_heavy_interval":3,"boss_heavy_multiplier":2.0,"boss_range_multiplier":1.9,"boss_recovery":0.8,"name":"天界守门者","is_boss":true,"health":6200.0,"speed":2.8,"attack_damage":150.0,"attack_range":3.8,"attack_interval":1.6,"exp_reward":1900,"coin_reward":1300,"drop_tier":"boss","color":Color(0.62,0.78,0.96)},
    "heavenly_angel": {"name":"天界光翼战士","is_boss":false,"health":1450.0,"speed":3.0,"attack_damage":88.0,"attack_range":2.8,"attack_interval":1.4,"exp_reward":360,"coin_reward":240,"drop_tier":"normal","color":Color(0.72,0.84,1.0)},
    "heavenly_warden": {"boss_special":"judgment_combo","boss_windup":0.82,"boss_heavy_interval":2,"boss_heavy_multiplier":2.15,"boss_range_multiplier":1.8,"boss_recovery":0.72,"name":"天界审判者","is_boss":true,"health":7000.0,"speed":2.65,"attack_damage":165.0,"attack_range":4.0,"attack_interval":1.65,"exp_reward":2100,"coin_reward":1450,"drop_tier":"boss","color":Color(0.56,0.72,0.96)},
    "celestial_trial": {"boss_special":"judgment_combo","boss_windup":1.25,"boss_heavy_interval":2,"boss_heavy_multiplier":2.25,"boss_range_multiplier":2.0,"boss_recovery":1.0,"name":"神域试炼化身","is_boss":true,"health":7600.0,"speed":2.2,"attack_damage":172.0,"attack_range":4.2,"attack_interval":1.9,"exp_reward":2250,"coin_reward":1550,"drop_tier":"boss","color":Color(0.82,0.72,0.42)},
    "apollo_trial": {"boss_special":"solar_flare","boss_windup":0.9,"boss_heavy_interval":2,"boss_heavy_multiplier":2.4,"boss_range_multiplier":2.1,"boss_recovery":0.82,"name":"太阳神试炼化身","is_boss":true,"health":8400.0,"speed":2.75,"attack_damage":185.0,"attack_range":4.0,"attack_interval":1.65,"exp_reward":2400,"coin_reward":1650,"drop_tier":"boss","color":Color(1.0,0.68,0.18)},
    "zeus_trial": {"boss_special":"storm_chain","boss_windup":1.45,"boss_heavy_interval":2,"boss_heavy_multiplier":2.6,"boss_range_multiplier":2.2,"boss_recovery":1.1,"name":"天界终极守护者","is_boss":true,"health":9800.0,"speed":2.5,"attack_damage":205.0,"attack_range":4.4,"attack_interval":1.8,"exp_reward":2800,"coin_reward":1900,"drop_tier":"boss","color":Color(0.68,0.62,1.0)},
    "cosmos_warden": {"boss_special":"rift_drain","boss_windup":1.1,"boss_heavy_interval":2,"boss_heavy_multiplier":2.35,"boss_range_multiplier":2.0,"boss_recovery":0.9,"name":"宇宙裂隙守卫","is_boss":true,"health":10800.0,"speed":2.6,"attack_damage":218.0,"attack_range":4.2,"attack_interval":1.75,"exp_reward":3000,"coin_reward":2100,"drop_tier":"boss","color":Color(0.24,0.58,0.82)},
    "divine_echo": {"name":"失控的神明回响","is_boss":false,"health":2600.0,"speed":2.9,"attack_damage":125.0,"attack_range":3.0,"attack_interval":1.45,"exp_reward":520,"coin_reward":350,"drop_tier":"normal","color":Color(0.62,0.42,0.86)},
    "primordial_void": {"boss_special":"void_drain","boss_windup":1.4,"boss_heavy_interval":2,"boss_heavy_multiplier":2.6,"boss_range_multiplier":2.2,"boss_recovery":1.1,"name":"原初虚空意志","is_boss":true,"health":12800.0,"speed":2.2,"attack_damage":245.0,"attack_range":4.5,"attack_interval":1.9,"exp_reward":3500,"coin_reward":2400,"drop_tier":"boss","color":Color(0.12,0.12,0.2)},
    "universe_arbiter": {"boss_special":"cosmic_collapse","boss_windup":1.6,"boss_heavy_interval":2,"boss_heavy_multiplier":2.8,"boss_range_multiplier":2.3,"boss_recovery":1.2,"name":"宇宙裁决者","is_boss":true,"health":16000.0,"speed":2.4,"attack_damage":280.0,"attack_range":4.8,"attack_interval":1.8,"exp_reward":4500,"coin_reward":3200,"drop_tier":"boss","color":Color(0.82,0.76,0.92)},
    "dark_saint_scout": {"name":"暗黑圣斗士斥候","is_boss":false,"health":180.0,"speed":3.25,"attack_damage":17.0,"attack_range":2.0,"attack_interval":1.15,"exp_reward":72,"coin_reward":58,"drop_tier":"dark","faction":"dark_saints","rank":"scout","color":Color(0.12,0.10,0.16)},
    "dark_saint_raider": {"name":"暗黑圣斗士突袭者","is_boss":false,"health":245.0,"speed":2.75,"attack_damage":23.0,"attack_range":2.35,"attack_interval":1.45,"exp_reward":96,"coin_reward":76,"drop_tier":"dark","faction":"dark_saints","rank":"raider","color":Color(0.20,0.08,0.16)},
    "dark_saint_elite": {"name":"暗黑圣斗士精英队长","is_boss":false,"health":520.0,"speed":2.55,"attack_damage":34.0,"attack_range":2.8,"attack_interval":1.55,"exp_reward":185,"coin_reward":145,"drop_tier":"dark_elite","faction":"dark_saints","rank":"elite","color":Color(0.30,0.10,0.22)},
    "dark_saint_captain": {"name":"暗黑圣斗士百夫长","is_boss":false,"health":680.0,"speed":2.35,"attack_damage":41.0,"attack_range":3.0,"attack_interval":1.7,"exp_reward":240,"coin_reward":190,"drop_tier":"dark_elite","faction":"dark_saints","rank":"captain","color":Color(0.24,0.12,0.30)},
    "dark_phoenix_revenant": {"boss_special":"death_mark","boss_windup":0.72,"boss_heavy_interval":3,"boss_heavy_multiplier":1.7,"boss_range_multiplier":1.55,"boss_recovery":0.62,"name":"暗黑凤凰复仇者","is_boss":true,"health":980.0,"speed":3.0,"attack_damage":38.0,"attack_range":2.9,"attack_interval":1.35,"exp_reward":360,"coin_reward":280,"drop_tier":"boss","color":Color(0.16,0.035,0.12)},
    "dark_dragon_wraith": {"boss_special":"gravity_crush","boss_windup":1.0,"boss_heavy_interval":2,"boss_heavy_multiplier":1.85,"boss_range_multiplier":1.8,"boss_recovery":0.82,"name":"暗黑天龙幻影","is_boss":true,"health":1120.0,"speed":2.0,"attack_damage":42.0,"attack_range":3.5,"attack_interval":1.85,"exp_reward":390,"coin_reward":300,"drop_tier":"boss","color":Color(0.08,0.16,0.22)},
    "dark_black_knight_champion": {"boss_special":"void_drain","boss_windup":1.2,"boss_heavy_interval":2,"boss_heavy_multiplier":2.0,"boss_range_multiplier":1.9,"boss_recovery":0.9,"name":"黑暗圣斗士统领","is_boss":true,"health":1450.0,"speed":2.35,"attack_damage":48.0,"attack_range":3.8,"attack_interval":1.7,"exp_reward":520,"coin_reward":420,"drop_tier":"boss","color":Color(0.12,0.08,0.2)}
}


const FACTION_TUTORIAL_ENEMIES := {
    "sanctuary": {"normal_name":"圣域青铜训练守卫","boss_name":"圣域白银试炼官","color":Color(0.22,0.48,0.86),"boss_color":Color(0.82,0.68,0.28),"boss_special":"gravity_crush"},
    "dark_saints": {"normal_name":"死亡皇后岛暗黑斗士","boss_name":"暗黑凤凰统领","color":Color(0.16,0.17,0.22),"boss_color":Color(0.12,0.08,0.18),"boss_special":"death_burst"},
    "sea": {"normal_name":"海界巡逻兵","boss_name":"海将军试炼官","color":Color(0.08,0.48,0.68),"boss_color":Color(0.08,0.32,0.78),"boss_special":"tidal_pull"},
    "underworld": {"normal_name":"冥界骷髅斗士","boss_name":"冥界魔星守卫","color":Color(0.28,0.22,0.38),"boss_color":Color(0.38,0.12,0.58),"boss_special":"soul_leech"},
    "divine": {"normal_name":"奥林匹斯神域侍卫","boss_name":"神域审判者","color":Color(0.68,0.58,0.32),"boss_color":Color(0.92,0.78,0.42),"boss_special":"solar_flare"},
    "asgard": {"normal_name":"仙宫冰原神斗士","boss_name":"仙宫冰霜试炼者","color":Color(0.38,0.62,0.78),"boss_color":Color(0.48,0.78,0.96),"boss_special":"frostfire"},
    "steel": {"normal_name":"钢铁基地训练机兵","boss_name":"钢铁重装机甲","color":Color(0.38,0.48,0.56),"boss_color":Color(0.28,0.62,0.78),"boss_special":"lightning_followup"},
    "bluegrad": {"normal_name":"蓝格拉德冰原战士","boss_name":"冰原巨人","color":Color(0.42,0.72,0.9),"boss_color":Color(0.62,0.88,1.0),"boss_special":"rift_drain"},
    "fallen": {"normal_name":"堕天领域黑翼卫士","boss_name":"堕天使审判官","color":Color(0.36,0.12,0.28),"boss_color":Color(0.62,0.12,0.38),"boss_special":"void_drain"},
    "titans": {"normal_name":"泰坦神域石像先锋","boss_name":"泰坦神将","color":Color(0.52,0.38,0.22),"boss_color":Color(0.78,0.52,0.22),"boss_special":"gravity_crush"},
    "giants": {"normal_name":"巨人领域重装先锋","boss_name":"巨人族统领","color":Color(0.48,0.32,0.2),"boss_color":Color(0.72,0.42,0.22),"boss_special":"wing_slam"},
    "hongmeng": {"normal_name":"鸿蒙混沌幻影","boss_name":"鸿蒙法则守护者","color":Color(0.34,0.24,0.62),"boss_color":Color(0.68,0.48,0.96),"boss_special":"cosmic_collapse"}
}

func get_tutorial_archetype_id(faction_id: String, is_boss: bool) -> String:
    if not FACTION_TUTORIAL_ENEMIES.has(faction_id):
        faction_id = "sanctuary"
    return "faction_%s_%s" % [faction_id, "boss" if is_boss else "guard"]

func get_archetype(archetype_id: String) -> Dictionary:
    if archetype_id.begins_with("faction_"):
        var parts := archetype_id.split("_")
        if parts.size() >= 3:
            var kind := str(parts[parts.size() - 1])
            var faction_id := "_".join(parts.slice(1, parts.size() - 1))
            if FACTION_TUTORIAL_ENEMIES.has(faction_id) and kind in ["guard", "boss"]:
                var faction_data: Dictionary = FACTION_TUTORIAL_ENEMIES[faction_id]
                var is_faction_boss := kind == "boss"
                var data: Dictionary = ARCHETYPES["arena_boss" if is_faction_boss else "arena_guard"].duplicate(true)
                data["name"] = str(faction_data["boss_name" if is_faction_boss else "normal_name"])
                data["color"] = faction_data["boss_color" if is_faction_boss else "color"]
                data["is_boss"] = is_faction_boss
                if is_faction_boss:
                    data["boss_special"] = str(faction_data["boss_special"])
                    data["health"] = 340.0
                    data["attack_damage"] = 19.0
                    data["exp_reward"] = 120
                    data["coin_reward"] = 160
                    data["drop_tier"] = "boss"
                else:
                    data["health"] = 78.0
                    data["attack_damage"] = 8.0
                    data["exp_reward"] = 38
                    data["coin_reward"] = 48
                return data
    return ARCHETYPES.get(archetype_id, ARCHETYPES["arena_guard"]).duplicate(true)

func get_catalog() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for archetype_id in ARCHETYPES:
        var entry: Dictionary = ARCHETYPES[archetype_id].duplicate(true)
        entry["id"] = archetype_id
        result.append(entry)
    return result


func validate_archetypes() -> Dictionary:
    var errors: Array[String] = []
    for archetype_id in ARCHETYPES:
        var data: Dictionary = ARCHETYPES[archetype_id]
        if str(data.get("name", "")).is_empty():
            errors.append("missing enemy name: " + str(archetype_id))
        if float(data.get("health", 0.0)) <= 0.0:
            errors.append("non-positive enemy health: " + str(archetype_id))
        if float(data.get("speed", -1.0)) < 0.0:
            errors.append("negative enemy speed: " + str(archetype_id))
        if float(data.get("attack_damage", -1.0)) < 0.0:
            errors.append("negative enemy attack damage: " + str(archetype_id))
        if float(data.get("attack_range", 0.0)) <= 0.0 or float(data.get("attack_interval", 0.0)) <= 0.0:
            errors.append("invalid enemy attack range or interval: " + str(archetype_id))
        if bool(data.get("is_boss", false)):
            var allowed_specials := ["none", "dream_drain", "soul_leech", "death_burst", "tidal_pull", "solar_flare", "lightning_followup", "void_drain", "rift_drain", "gravity_crush", "judge_combo", "judgment_combo", "wing_slam", "six_beasts", "mirror_feint", "sonic_wave", "frostfire", "crystal_seal", "sleeping_field", "death_mark", "storm_chain", "cosmic_collapse"]
            if not str(data.get("boss_special", "none")) in allowed_specials:
                errors.append("unknown boss special attack: " + str(archetype_id))
            if float(data.get("boss_windup", 1.05)) <= 0.0:
                errors.append("boss has no windup: " + str(archetype_id))
            if int(data.get("boss_heavy_interval", 3)) < 1:
                errors.append("boss heavy interval is invalid: " + str(archetype_id))
            if float(data.get("boss_heavy_multiplier", 1.55)) < 1.0:
                errors.append("boss heavy multiplier is invalid: " + str(archetype_id))
            if float(data.get("boss_range_multiplier", 1.5)) < 1.0:
                errors.append("boss range multiplier is invalid: " + str(archetype_id))
            if float(data.get("boss_recovery", 0.72)) < 0.0:
                errors.append("boss recovery is invalid: " + str(archetype_id))
    return {"valid": errors.is_empty(), "archetype_count": ARCHETYPES.size(), "errors": errors}

func has_archetype(archetype_id: String) -> bool:
    if ARCHETYPES.has(archetype_id):
        return true
    if archetype_id.begins_with("faction_"):
        for faction_id in FACTION_TUTORIAL_ENEMIES:
            if archetype_id == get_tutorial_archetype_id(str(faction_id), false) or archetype_id == get_tutorial_archetype_id(str(faction_id), true):
                return true
    return false
