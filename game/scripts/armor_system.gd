extends Node
const STAGES := {
 "bronze":{"name":"青铜圣衣","attack":1.0,"defense":2.0,"hp":8.0},
 "silver":{"name":"白银圣衣","attack":2.0,"defense":4.0,"hp":16.0},
 "gold":{"name":"黄金圣衣","attack":4.0,"defense":7.0,"hp":28.0},
 "sea_scale":{"name":"海界鳞衣","attack":4.0,"defense":6.0,"hp":24.0},
 "surplice":{"name":"冥衣","attack":5.0,"defense":6.0,"hp":22.0},
 "dark_cloth":{"name":"黑暗圣衣","attack":5.5,"defense":4.5,"hp":26.0},
 "platinum":{"name":"白金圣衣","attack":8.0,"defense":8.0,"hp":48.0},
 "god_cloth":{"name":"神圣衣","attack":7.0,"defense":9.0,"hp":40.0},
 "god_armor":{"name":"主神圣衣","attack":9.0,"defense":12.0,"hp":55.0}
}
const DARK_CLASS_PASSIVES := {
 "pegasus":{"name":"暗影流星","focus":"attack","attack_rate":0.075,"defense_rate":0.02,"health_rate":0.02,"speed_rate":0.035,"cosmos_rate":0.0},
 "dragon":{"name":"黑曜龙盾","focus":"defense","attack_rate":0.02,"defense_rate":0.08,"health_rate":0.055,"speed_rate":0.0,"cosmos_rate":0.0},
 "cygnus":{"name":"极夜冰晶","focus":"control","attack_rate":0.04,"defense_rate":0.04,"health_rate":0.025,"speed_rate":0.015,"cosmos_rate":1.0},
 "andromeda":{"name":"暗链缚魂","focus":"control","attack_rate":0.045,"defense_rate":0.035,"health_rate":0.03,"speed_rate":0.01,"cosmos_rate":1.0},
 "phoenix":{"name":"不灭黑炎","focus":"attack","attack_rate":0.08,"defense_rate":0.015,"health_rate":0.035,"speed_rate":0.02,"cosmos_rate":0.0},
 "sea_dragon":{"name":"深渊逆潮","focus":"cosmos","attack_rate":0.05,"defense_rate":0.025,"health_rate":0.04,"speed_rate":0.01,"cosmos_rate":2.0},
 "tenmou":{"name":"天猛壁垒","focus":"defense","attack_rate":0.025,"defense_rate":0.07,"health_rate":0.06,"speed_rate":0.0,"cosmos_rate":0.0},
 "lyra":{"name":"幽冥弦刃","focus":"attack","attack_rate":0.07,"defense_rate":0.02,"health_rate":0.02,"speed_rate":0.025,"cosmos_rate":0.0},
 "sea_swallow":{"name":"暗流迅羽","focus":"mobility","attack_rate":0.04,"defense_rate":0.025,"health_rate":0.035,"speed_rate":0.045,"cosmos_rate":0.0},
 "tenkishi":{"name":"堕天黑翼","focus":"mobility","attack_rate":0.045,"defense_rate":0.045,"health_rate":0.04,"speed_rate":0.04,"cosmos_rate":1.0},
 "apollo":{"name":"黑日裁决","focus":"attack","attack_rate":0.08,"defense_rate":0.02,"health_rate":0.04,"speed_rate":0.01,"cosmos_rate":1.0},
 "athena":{"name":"暗夜神佑","focus":"defense","attack_rate":0.025,"defense_rate":0.075,"health_rate":0.07,"speed_rate":0.0,"cosmos_rate":2.0},
 "hades":{"name":"冥渊侵蚀","focus":"attack","attack_rate":0.075,"defense_rate":0.035,"health_rate":0.045,"speed_rate":0.0,"cosmos_rate":1.0},
 "poseidon":{"name":"黑潮统御","focus":"cosmos","attack_rate":0.05,"defense_rate":0.045,"health_rate":0.04,"speed_rate":0.01,"cosmos_rate":2.0},
 "zeus":{"name":"暗雷神罚","focus":"attack","attack_rate":0.085,"defense_rate":0.04,"health_rate":0.035,"speed_rate":0.015,"cosmos_rate":2.0},
 "artemis":{"name":"月蚀守望","focus":"defense","attack_rate":0.035,"defense_rate":0.065,"health_rate":0.055,"speed_rate":0.02,"cosmos_rate":1.0},
 "hypnos":{"name":"永夜梦境","focus":"defense","attack_rate":0.02,"defense_rate":0.075,"health_rate":0.05,"speed_rate":0.0,"cosmos_rate":2.0},
 "thanatos":{"name":"终焉黑镰","focus":"attack","attack_rate":0.085,"defense_rate":0.02,"health_rate":0.035,"speed_rate":0.02,"cosmos_rate":0.0},
 "odin":{"name":"黑曜神域","focus":"defense","attack_rate":0.035,"defense_rate":0.07,"health_rate":0.055,"speed_rate":0.01,"cosmos_rate":1.0},
 "ares":{"name":"黑暗战意","focus":"attack","attack_rate":0.09,"defense_rate":0.015,"health_rate":0.03,"speed_rate":0.02,"cosmos_rate":0.0},
 "eris":{"name":"纷争暗潮","focus":"attack","attack_rate":0.065,"defense_rate":0.025,"health_rate":0.05,"speed_rate":0.02,"cosmos_rate":1.0},
 "abel":{"name":"日蚀圣焰","focus":"attack","attack_rate":0.08,"defense_rate":0.03,"health_rate":0.04,"speed_rate":0.015,"cosmos_rate":1.0},
 "lucifer":{"name":"堕天疾翼","focus":"mobility","attack_rate":0.065,"defense_rate":0.02,"health_rate":0.035,"speed_rate":0.05,"cosmos_rate":0.0},
 "saturn":{"name":"暗时领域","focus":"control","attack_rate":0.055,"defense_rate":0.055,"health_rate":0.04,"speed_rate":0.015,"cosmos_rate":2.0},
 "pallas":{"name":"黑曜时刃","focus":"control","attack_rate":0.06,"defense_rate":0.045,"health_rate":0.035,"speed_rate":0.02,"cosmos_rate":1.0},
 "chronos":{"name":"混沌时序","focus":"cosmos","attack_rate":0.06,"defense_rate":0.06,"health_rate":0.05,"speed_rate":0.01,"cosmos_rate":3.0},
 "hera":{"name":"暗曜王权","focus":"defense","attack_rate":0.025,"defense_rate":0.08,"health_rate":0.06,"speed_rate":0.0,"cosmos_rate":2.0},
 "demeter":{"name":"幽冥丰饶","focus":"health","attack_rate":0.02,"defense_rate":0.055,"health_rate":0.085,"speed_rate":0.0,"cosmos_rate":1.0},
 "hestia":{"name":"幽冥圣焰","focus":"health","attack_rate":0.025,"defense_rate":0.075,"health_rate":0.075,"speed_rate":0.0,"cosmos_rate":1.0},
 "hermes":{"name":"暗影疾行","focus":"mobility","attack_rate":0.065,"defense_rate":0.015,"health_rate":0.025,"speed_rate":0.055,"cosmos_rate":0.0},
 "hephaestus":{"name":"黑曜神锻","focus":"defense","attack_rate":0.04,"defense_rate":0.085,"health_rate":0.065,"speed_rate":0.0,"cosmos_rate":1.0},
 "aphrodite":{"name":"暗影魅惑","focus":"control","attack_rate":0.05,"defense_rate":0.04,"health_rate":0.04,"speed_rate":0.025,"cosmos_rate":2.0}
}
const PLATINUM_CLASS_PASSIVES := {
 "pegasus":{"name":"星辉流星","focus":"attack","attack_rate":0.055,"defense_rate":0.015,"health_rate":0.015,"speed_rate":0.025,"cosmos_rate":1.0},
 "dragon":{"name":"天穹龙壁","focus":"defense","attack_rate":0.015,"defense_rate":0.06,"health_rate":0.045,"speed_rate":0.0,"cosmos_rate":1.0},
 "cygnus":{"name":"极光冰环","focus":"control","attack_rate":0.03,"defense_rate":0.03,"health_rate":0.02,"speed_rate":0.015,"cosmos_rate":2.0},
 "andromeda":{"name":"星链回响","focus":"control","attack_rate":0.035,"defense_rate":0.025,"health_rate":0.025,"speed_rate":0.01,"cosmos_rate":2.0},
 "phoenix":{"name":"涅槃日轮","focus":"attack","attack_rate":0.06,"defense_rate":0.01,"health_rate":0.025,"speed_rate":0.015,"cosmos_rate":1.0},
 "sea_dragon":{"name":"沧海星潮","focus":"cosmos","attack_rate":0.035,"defense_rate":0.025,"health_rate":0.03,"speed_rate":0.01,"cosmos_rate":3.0},
 "tenmou":{"name":"天穹壁垒","focus":"defense","attack_rate":0.02,"defense_rate":0.055,"health_rate":0.05,"speed_rate":0.0,"cosmos_rate":1.0},
 "lyra":{"name":"天籁星弦","focus":"attack","attack_rate":0.05,"defense_rate":0.015,"health_rate":0.015,"speed_rate":0.02,"cosmos_rate":2.0},
 "sea_swallow":{"name":"流星迅羽","focus":"mobility","attack_rate":0.03,"defense_rate":0.02,"health_rate":0.025,"speed_rate":0.04,"cosmos_rate":1.0},
 "tenkishi":{"name":"天界辉翼","focus":"mobility","attack_rate":0.035,"defense_rate":0.035,"health_rate":0.03,"speed_rate":0.035,"cosmos_rate":2.0},
 "apollo":{"name":"太阳圣冕","focus":"attack","attack_rate":0.06,"defense_rate":0.025,"health_rate":0.03,"speed_rate":0.01,"cosmos_rate":3.0},
 "athena":{"name":"智慧星盾","focus":"defense","attack_rate":0.02,"defense_rate":0.055,"health_rate":0.055,"speed_rate":0.0,"cosmos_rate":3.0},
 "hades":{"name":"冥界星蚀","focus":"attack","attack_rate":0.055,"defense_rate":0.03,"health_rate":0.035,"speed_rate":0.0,"cosmos_rate":3.0},
 "poseidon":{"name":"海皇星潮","focus":"cosmos","attack_rate":0.035,"defense_rate":0.035,"health_rate":0.03,"speed_rate":0.01,"cosmos_rate":3.0},
 "zeus":{"name":"雷霆星裁","focus":"attack","attack_rate":0.065,"defense_rate":0.03,"health_rate":0.025,"speed_rate":0.015,"cosmos_rate":3.0},
 "artemis":{"name":"月华星守","focus":"defense","attack_rate":0.025,"defense_rate":0.05,"health_rate":0.04,"speed_rate":0.015,"cosmos_rate":2.0},
 "hypnos":{"name":"永昼安眠","focus":"defense","attack_rate":0.015,"defense_rate":0.055,"health_rate":0.04,"speed_rate":0.0,"cosmos_rate":3.0},
 "thanatos":{"name":"终焉星镰","focus":"attack","attack_rate":0.065,"defense_rate":0.015,"health_rate":0.025,"speed_rate":0.015,"cosmos_rate":1.0},
 "odin":{"name":"神域星壁","focus":"defense","attack_rate":0.025,"defense_rate":0.05,"health_rate":0.045,"speed_rate":0.01,"cosmos_rate":2.0},
 "ares":{"name":"战神辉锋","focus":"attack","attack_rate":0.07,"defense_rate":0.01,"health_rate":0.02,"speed_rate":0.015,"cosmos_rate":1.0},
 "eris":{"name":"纷争星环","focus":"control","attack_rate":0.045,"defense_rate":0.02,"health_rate":0.04,"speed_rate":0.015,"cosmos_rate":2.0},
 "abel":{"name":"真红日耀","focus":"attack","attack_rate":0.06,"defense_rate":0.025,"health_rate":0.03,"speed_rate":0.01,"cosmos_rate":2.0},
 "lucifer":{"name":"晨星天翼","focus":"mobility","attack_rate":0.045,"defense_rate":0.015,"health_rate":0.025,"speed_rate":0.045,"cosmos_rate":1.0},
 "saturn":{"name":"时轮星域","focus":"control","attack_rate":0.04,"defense_rate":0.04,"health_rate":0.03,"speed_rate":0.01,"cosmos_rate":3.0},
 "pallas":{"name":"圣剑星辉","focus":"control","attack_rate":0.045,"defense_rate":0.03,"health_rate":0.025,"speed_rate":0.015,"cosmos_rate":2.0},
 "chronos":{"name":"创世时序","focus":"cosmos","attack_rate":0.045,"defense_rate":0.045,"health_rate":0.04,"speed_rate":0.01,"cosmos_rate":4.0},
 "hera":{"name":"天后星冠","focus":"defense","attack_rate":0.015,"defense_rate":0.06,"health_rate":0.045,"speed_rate":0.0,"cosmos_rate":3.0},
 "demeter":{"name":"大地丰星","focus":"health","attack_rate":0.015,"defense_rate":0.04,"health_rate":0.065,"speed_rate":0.0,"cosmos_rate":2.0},
 "hestia":{"name":"圣火恒星","focus":"health","attack_rate":0.02,"defense_rate":0.055,"health_rate":0.055,"speed_rate":0.0,"cosmos_rate":2.0},
 "hermes":{"name":"神行星轨","focus":"mobility","attack_rate":0.045,"defense_rate":0.01,"health_rate":0.02,"speed_rate":0.05,"cosmos_rate":1.0},
 "hephaestus":{"name":"神锻星炉","focus":"defense","attack_rate":0.03,"defense_rate":0.065,"health_rate":0.05,"speed_rate":0.0,"cosmos_rate":2.0},
 "aphrodite":{"name":"爱神星辉","focus":"control","attack_rate":0.035,"defense_rate":0.03,"health_rate":0.03,"speed_rate":0.02,"cosmos_rate":3.0}
}
const PARTS := ["head","chest","arms","waist","legs"]
const PART_NAMES := {"head":"头盔","chest":"胸甲","arms":"护腕","waist":"腰甲","legs":"腿甲"}
var damage_ticks := 0
func _ensure_data() -> Dictionary:
 var data: Dictionary = RPGState.profile.get("armor_state", {})
 if data.is_empty():
  data = {"unlocked_stages":["bronze"],"current_stage":"bronze","durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100},"levels":{},"awakened":false}
  RPGState.profile["armor_state"] = data
 return data
func get_stage_ids() -> Array:
 return STAGES.keys()
func get_state() -> Dictionary:
 return _ensure_data().duplicate(true)
func get_current_stage_name() -> String:
 var data := _ensure_data()
 return str(STAGES.get(str(data.get("current_stage","bronze")),STAGES["bronze"])["name"])

func unlock_stage(stage_id: String) -> bool:
 if not STAGES.has(stage_id):
  return false
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 if stage_id in data.get("unlocked_stages", []):
  return false
 var requirements := {
  "silver": {"level": 20, "chapter": "sanctuary_twelve_houses"},
  "gold": {"level": 25, "chapter": "sanctuary_twelve_houses", "requires_completion": true},
  "sea_scale": {"level": 30, "chapter": "poseidon"},
  "surplice": {"level": 40, "chapter": "hades"},
  "dark_cloth": {"level": 12, "chapter": "galaxy_wars", "requires_completion": true},
  "platinum": {"level": 55, "chapter": "original_final", "requires_completion": true},
  "god_cloth": {"level": 45, "chapter": "hades"},
  "god_armor": {"level": 70, "chapter": "heaven"}
 }
 var requirement: Dictionary = requirements.get(stage_id, {})
 if requirement.is_empty() or int(RPGState.profile.get("level", 1)) < int(requirement.get("level", 1)):
  return false
 var chapter_unlocked := false
 for chapter in CampaignManager.get_chapter_overview():
  if str(chapter.get("id", "")) != str(requirement.get("chapter", "")):
   continue
  if bool(requirement.get("requires_completion", false)):
   chapter_unlocked = bool(chapter.get("completed", false))
  else:
   chapter_unlocked = bool(chapter.get("unlocked", false))
  break
 if not chapter_unlocked:
  return false
 var unlocked: Array = data.get("unlocked_stages", []).duplicate()
 unlocked.append(stage_id)
 data["unlocked_stages"] = unlocked
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func unlock_all_stages() -> bool:
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 data["unlocked_stages"] = STAGES.keys()
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func equip_stage(stage_id: String) -> bool:
 if not STAGES.has(stage_id):
  return false
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 if not (stage_id in data.get("unlocked_stages", [])):
  return false
 data["current_stage"] = stage_id
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func get_repair_quote(part: String = "") -> Dictionary:
    if not part.is_empty() and not (part in PARTS):
        return {}
    var durability: Dictionary = _ensure_data().get("durability", {})
    var missing := 0
    if part.is_empty():
        for armor_part in PARTS:
            missing += 100 - clampi(int(durability.get(armor_part, 100)), 0, 100)
    else:
        missing = 100 - clampi(int(durability.get(part, 100)), 0, 100)
    var cost := missing * 2
    return {
        "part": part,
        "missing_durability": missing,
        "currency_cost": cost,
        "can_repair": missing > 0 and int(RPGState.profile.get("currency", 0)) >= cost
    }

func repair_part(part: String) -> Dictionary:
    if not (part in PARTS):
        return {}
    var quote := get_repair_quote(part)
    var cost := int(quote.get("currency_cost", 0))
    if int(quote.get("missing_durability", 0)) <= 0 or not bool(quote.get("can_repair", false)):
        return {"part": part, "repaired": false, "reason": "already_intact" if int(quote.get("missing_durability", 0)) <= 0 else "insufficient_currency", "currency_cost": cost}
    var previous: Dictionary = RPGState.profile.duplicate(true)
    var data := _ensure_data()
    var durability: Dictionary = data.get("durability", {}).duplicate(true)
    var before := clampi(int(durability.get(part, 100)), 0, 100)
    durability[part] = 100
    data["durability"] = durability
    RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
    RPGState.profile["armor_state"] = data
    if not _commit(previous):
        return {"part": part, "repaired": false, "reason": "save_failed", "currency_cost": cost}
    return {"part": part, "repaired": true, "before": before, "after": 100, "currency_cost": cost}

func repair_all() -> bool:
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var durability: Dictionary = data.get("durability", {}).duplicate(true)
 var missing := 0
 for part in PARTS:
  missing += 100 - int(durability.get(part, 100))
 if missing <= 0:
  return false
 var cost := missing * 2
 if int(RPGState.profile.get("currency", 0)) < cost:
  return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
 for part in PARTS:
  durability[part] = 100
 data["durability"] = durability
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func damage_part(part: String, amount: int = 8) -> Dictionary:
 if not (part in PARTS):
  return {}
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var durability: Dictionary = data.get("durability", {}).duplicate(true)
 var before := clampi(int(durability.get(part, 100)), 0, 100)
 var after := maxi(0, before - maxi(1, amount))
 if after == before:
  return {"part": part, "before": before, "after": after, "changed": false}
 durability[part] = after
 data["durability"] = durability
 RPGState.profile["armor_state"] = data
 _commit(previous)
 return {"part": part, "before": before, "after": after, "changed": true, "tier": get_part_condition_tier(part)}

func damage_random_part(amount: int = 8) -> Dictionary:
 damage_ticks += 1
 if damage_ticks % 5 != 0:
  return {}
 var part: String = PARTS[randi_range(0, PARTS.size() - 1)]
 return damage_part(part, amount)
func enhance_part(part: String) -> bool:
 if not (part in PARTS):
  return false
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var levels: Dictionary = data.get("levels", {}).duplicate(true)
 var level := int(levels.get(part, 0))
 if level >= 10:
  return false
 var cost := (level + 1) * 180
 if int(RPGState.profile.get("currency", 0)) < cost:
  return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
 levels[part] = level + 1
 data["levels"] = levels
 RPGState.profile["armor_state"] = data
 return _commit(previous)
func awaken_current() -> bool:
 var previous: Dictionary = RPGState.profile.duplicate(true)
 var data := _ensure_data()
 var stage := str(data.get("current_stage", "bronze"))
 if not ["gold", "dark_cloth", "platinum", "god_cloth", "god_armor"].has(stage) or bool(data.get("awakened", false)):
  return false
 var cost := 3500 if stage == "dark_cloth" else (9000 if stage == "platinum" else (5000 if stage == "gold" else 12000))
 var material_id := "dark_cosmos_fragment" if stage == "dark_cloth" else ("platinum_star_shard" if stage == "platinum" else "")
 var material_cost := 5 if stage in ["dark_cloth", "platinum"] else 0
 var inventory: Dictionary = RPGState.profile.get("inventory", {}).duplicate(true)
 if int(RPGState.profile.get("currency", 0)) < cost or (not material_id.is_empty() and int(inventory.get(material_id, 0)) < material_cost):
  return false
 RPGState.profile["currency"] = int(RPGState.profile.get("currency", 0)) - cost
 if material_cost > 0:
  inventory[material_id] = int(inventory.get(material_id, 0)) - material_cost
  if int(inventory[material_id]) <= 0:
   inventory.erase(material_id)
  RPGState.profile["inventory"] = inventory
 data["awakened"] = true
 data["awakening_stage"] = 1
 RPGState.profile["armor_state"] = data
 return _commit(previous)

func get_awakening_requirements(stage_id: String = "") -> Dictionary:
 var selected := stage_id if not stage_id.is_empty() else str(_ensure_data().get("current_stage", "bronze"))
 if selected == "dark_cloth":
  return {"currency":3500,"material_id":"dark_cosmos_fragment","material_count":5}
 if selected == "platinum":
  return {"currency":9000,"material_id":"platinum_star_shard","material_count":5}
 if selected == "gold":
  return {"currency":5000,"material_id":"","material_count":0}
 if selected in ["god_cloth", "god_armor"]:
  return {"currency":12000,"material_id":"","material_count":0}
 return {}

func get_part_condition(part: String) -> float:
    if not (part in PARTS):
        return 0.0
    var durability: Dictionary = _ensure_data().get("durability", {})
    return clampf(float(durability.get(part, 100)) / 100.0, 0.0, 1.0)

func get_condition_ratio() -> float:
    var durability: Dictionary = _ensure_data().get("durability", {})
    var total := 0.0
    for part in PARTS:
        total += clampf(float(durability.get(part, 100)) / 100.0, 0.0, 1.0)
    return total / float(PARTS.size())

static func get_visual_wear_profile(condition_ratio: float) -> Dictionary:
    var condition := clampf(condition_ratio, 0.0, 1.0)
    var wear := 1.0 - condition
    return {
        "condition": condition,
        "wear": wear,
        "metallic_multiplier": lerpf(0.58, 1.0, condition),
        "roughness": lerpf(0.62, 0.22, condition),
        "tint": Color(0.22, 0.18, 0.16).lerp(Color.WHITE, condition),
        "cracked": condition <= 0.35,
        "condition_tier": "pristine" if condition >= 0.8 else ("worn" if condition >= 0.5 else ("damaged" if condition >= 0.25 else ("critical" if condition > 0.0 else "broken")))
    }

func get_part_visual_wear_profile(part: String) -> Dictionary:
    return get_visual_wear_profile(get_part_condition(part))

func get_part_durability(part: String) -> int:
    if not (part in PARTS):
        return 0
    var durability: Dictionary = _ensure_data().get("durability", {})
    return clampi(int(durability.get(part, 100)), 0, 100)

func get_part_condition_tier(part: String) -> String:
    if not (part in PARTS):
        return "unknown"
    return str(get_part_visual_wear_profile(part).get("condition_tier", "pristine"))

func get_damage_reduction(part: String = "") -> float:
    # Targeted hits use the protection of the struck armor piece; legacy callers
    # without a hit zone retain the balanced whole-set mitigation.
    if part in PARTS:
        var protection_by_part := {"head": 0.08, "chest": 0.10, "arms": 0.045, "waist": 0.07, "legs": 0.06}
        return clampf(float(protection_by_part.get(part, 0.0)) * float(get_part_durability(part)) / 100.0, 0.0, 0.10)
    return clampf(get_condition_ratio() * 0.08, 0.0, 0.08)

func damage_hit_part(part: String, amount: int = 8) -> Dictionary:
    if not (part in PARTS):
        return {}
    damage_ticks += 1
    if damage_ticks % 5 != 0:
        return {"part": part, "changed": false, "reason": "wear_interval"}
    return damage_part(part, amount)

func get_dark_class_passive(class_id: String = "") -> Dictionary:
 var selected_class := class_id if not class_id.is_empty() else str(RPGState.profile.get("class_id", "pegasus"))
 return DARK_CLASS_PASSIVES.get(selected_class, {}).duplicate(true)

func get_platinum_class_passive(class_id: String = "") -> Dictionary:
 var selected_class := class_id if not class_id.is_empty() else str(RPGState.profile.get("class_id", "pegasus"))
 return PLATINUM_CLASS_PASSIVES.get(selected_class, {}).duplicate(true)

func get_bonus_stats() -> Dictionary:
 var data := _ensure_data()
 var stage_id := str(data.get("current_stage","bronze"))
 var base: Dictionary = STAGES.get(stage_id,STAGES["bronze"])
 var levels: Dictionary = data.get("levels",{})
 var durability: Dictionary = data.get("durability",{})
 var condition := 0.0
 for part in PARTS: condition += float(durability.get(part,100))/500.0
 var level_sum := 0
 for part in PARTS: level_sum += int(levels.get(part,0))
 var awaken := 1.25 if bool(data.get("awakened",false)) else 1.0
 var attack_bonus := (float(base["attack"])+float(level_sum))*condition*awaken
 var defense_bonus := (float(base["defense"])+float(level_sum)*0.8)*condition*awaken
 var health_bonus := float(base["hp"])*condition*awaken
 var dark_cosmos_bonus := 0.0
 var dark_speed_bonus := 0.0
 var intact_parts := 0
 if stage_id == "dark_cloth":
  # Dark Cosmos resonance reinforces aggressive combat while retaining class identity.
  var class_data: Dictionary = RPGState.CLASS_DATA.get(str(RPGState.profile.get("class_id", "pegasus")), RPGState.CLASS_DATA.get("pegasus", {}))
  attack_bonus += float(class_data.get("attack", 0.0)) * 0.10 * condition * awaken
  defense_bonus += float(class_data.get("defense", 0.0)) * 0.05 * condition * awaken
  health_bonus += float(class_data.get("hp", 0.0)) * 0.04 * condition * awaken
  dark_cosmos_bonus = 12.0 * condition * awaken
  dark_speed_bonus = 0.08 * condition * awaken
  # Each of the 32 professions receives a distinct Dark Cloth specialization.
  var class_passive := get_dark_class_passive()
  attack_bonus += float(class_data.get("attack", 0.0)) * float(class_passive.get("attack_rate", 0.0)) * condition * awaken
  defense_bonus += float(class_data.get("defense", 0.0)) * float(class_passive.get("defense_rate", 0.0)) * condition * awaken
  health_bonus += float(class_data.get("hp", 0.0)) * float(class_passive.get("health_rate", 0.0)) * condition * awaken
  dark_speed_bonus += float(class_passive.get("speed_rate", 0.0)) * condition * awaken
  dark_cosmos_bonus += float(class_passive.get("cosmos_rate", 0.0)) * condition * awaken
  # The five armor pieces form a real set: three intact pieces grant Cosmos,
  # while all five intact pieces grant a small defensive/offensive set bonus.
  for part in PARTS:
   if int(durability.get(part, 100)) > 0:
    intact_parts += 1
  if intact_parts >= 3:
   dark_cosmos_bonus += 8.0 * condition * awaken
  if intact_parts == PARTS.size():
   attack_bonus += float(base["attack"]) * 0.05 * condition * awaken
   defense_bonus += float(base["defense"]) * 0.05 * condition * awaken
   health_bonus += float(base["hp"]) * 0.05 * condition * awaken
 var platinum_resonance := 1.0
 var platinum_star_bonus := 0.0
 var platinum_speed_bonus := 0.0
 if stage_id == "platinum":
  var platinum_awakened := bool(data.get("awakened", false))
  platinum_resonance = 1.18 if platinum_awakened else 1.12
  platinum_star_bonus = (22.0 if platinum_awakened else 14.0) * condition
  attack_bonus += float(base["attack"]) * (0.18 if platinum_awakened else 0.10) * condition
  defense_bonus += float(base["defense"]) * (0.16 if platinum_awakened else 0.08) * condition
  health_bonus += float(base["hp"]) * (0.15 if platinum_awakened else 0.08) * condition
  var class_data: Dictionary = RPGState.CLASS_DATA.get(str(RPGState.profile.get("class_id", "pegasus")), RPGState.CLASS_DATA.get("pegasus", {}))
  var class_passive := get_platinum_class_passive()
  var awakening_factor := 1.25 if platinum_awakened else 1.0
  attack_bonus += float(class_data.get("attack", 0.0)) * float(class_passive.get("attack_rate", 0.0)) * condition * awakening_factor
  defense_bonus += float(class_data.get("defense", 0.0)) * float(class_passive.get("defense_rate", 0.0)) * condition * awakening_factor
  health_bonus += float(class_data.get("hp", 0.0)) * float(class_passive.get("health_rate", 0.0)) * condition * awakening_factor
  platinum_speed_bonus = float(class_passive.get("speed_rate", 0.0)) * condition * awakening_factor
  platinum_star_bonus += float(class_passive.get("cosmos_rate", 0.0)) * condition * awakening_factor
 return {"attack":attack_bonus,"defense":defense_bonus,"max_health":health_bonus,"max_cosmos":dark_cosmos_bonus + platinum_star_bonus,"speed":dark_speed_bonus + platinum_speed_bonus,"dark_resonance":(1.15 if bool(data.get("awakened", false)) else 1.10) if stage_id == "dark_cloth" else 1.0,"platinum_star_resonance":platinum_resonance,"platinum_awakened":bool(data.get("awakened", false)) if stage_id == "platinum" else false,"dark_class_passive":get_dark_class_passive(),"platinum_class_passive":get_platinum_class_passive() if stage_id == "platinum" else {},"dark_set_tier":(2 if stage_id == "dark_cloth" and intact_parts == PARTS.size() else (1 if stage_id == "dark_cloth" and intact_parts >= 3 else 0))}
func _commit(previous: Dictionary) -> bool:
 if RPGState.save_slot(RPGState.active_slot):
  RPGState.state_changed.emit()
  return true
 RPGState.profile = previous
 return false
