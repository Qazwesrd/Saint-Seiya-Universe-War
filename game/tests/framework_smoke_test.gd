extends Node
const SkillAnimationCatalog = preload("res://scripts/skill_animation_catalog.gd")
const CharacterVisualCatalog = preload("res://scripts/character_visual_catalog.gd")
const EnemyVisualCatalog = preload("res://scripts/enemy_visual_catalog.gd")
const ArtAssetAudit = preload("res://scripts/art_asset_audit.gd")
const BossChapterCombatCatalog = preload("res://scripts/boss_chapter_combat_catalog.gd")
## Headless scene-based smoke test so project AutoLoads are initialized normally.

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var growth_original_profile: Dictionary = RPGState.profile.duplicate(true)
	assert(FactionDatabase.validate_catalog(), "all playable classes are assigned to selectable faction starts and Hongjun is selectable")
	assert(FactionDatabase.get_factions().size() == 12, "twelve faction starts are registered")
	var appearance_profile_backup: Dictionary = RPGState.profile.duplicate(true)
	var armor_family_validation: Dictionary = CharacterVisualCatalog.validate_faction_armor_families()
	assert(bool(armor_family_validation.get("valid", false)), "all twelve factions have complete armor-family profiles")
	var underworld_armor: Dictionary = CharacterVisualCatalog.get_faction_armor_profile("underworld", "hades")
	var dark_saint_armor: Dictionary = CharacterVisualCatalog.get_faction_armor_profile("dark_saints", "pegasus")
	assert(str(underworld_armor.get("family", "")) == "surplice" and str(underworld_armor.get("palette_family", "")) == "black_violet", "Underworld uses a black-violet Surplice identity")
	assert(str(dark_saint_armor.get("family", "")) == "dark_cloth" and str(dark_saint_armor.get("palette_family", "")) == "graphite_steel_blue", "Dark Saints use graphite and steel-blue Dark Cloth, not purple Surplice")
	assert(underworld_armor.get("metal", Color.BLACK) != dark_saint_armor.get("metal", Color.BLACK), "Surplice and Dark Cloth base metals are visually distinct")
	var dark_cloth_item_profile: Dictionary = CharacterVisualCatalog.get_equipment_profile({"id":"dark_cloth_catalog_item","category":"黑暗圣衣 Dark Cloth"})
	var surplice_item_profile: Dictionary = CharacterVisualCatalog.get_equipment_profile({"id":"surplice_catalog_item","category":"冥衣 Surplice"})
	assert(str(dark_cloth_item_profile.get("palette_family", "")) == "graphite_steel_blue", "Dark Cloth equipment category resolves to graphite steel-blue palette")
	assert(dark_cloth_item_profile.get("accent", Color.BLACK) != surplice_item_profile.get("accent", Color.BLACK), "equipment category lookup cannot accidentally recolor Dark Cloth purple")

	assert(str(CharacterVisualCatalog.get_faction_armor_profile("sea").get("chest", "")) == "overlapping_scales", "Sea faction armor uses layered scale construction")
	assert(str(CharacterVisualCatalog.get_faction_armor_profile("asgard").get("family", "")) == "god_robe", "Asgard faction armor uses the God Robe family")
	assert(str(CharacterVisualCatalog.get_faction_armor_profile("steel").get("family", "")) == "steel_armor", "Steel faction armor uses a mechanical armor family")
	var school_costume: Dictionary = CharacterVisualCatalog.get_costume_profile("school")
	assert(not school_costume.is_empty() and not bool(school_costume.get("cape", true)) and not bool(school_costume.get("armor_overlay", true)), "costumes are standalone clothing and never add a cape or armor overlay")
	assert(RPGState.equip_costume("school"), "school costume can be equipped independently of armor")
	assert(str(RPGState.get_appearance_state().get("equipped_costume", "")) == "school", "equipped costume is stored in its own appearance slot")
	assert(RPGState.equip_costume(""), "costume appearance can be independently unequipped")
	RPGState.profile = appearance_profile_backup
	assert(RPGState.save_slot(RPGState.active_slot), "restore character appearance state after costume smoke tests")

	for faction_entry in FactionDatabase.get_factions():
		var tutorial_faction_id := str(faction_entry.get("id", ""))
		var tutorial_guard_id := EnemyDatabase.get_tutorial_archetype_id(tutorial_faction_id, false)
		var tutorial_boss_id := EnemyDatabase.get_tutorial_archetype_id(tutorial_faction_id, true)
		assert(EnemyDatabase.has_archetype(tutorial_guard_id), "faction has its own tutorial guard archetype: " + tutorial_faction_id)
		assert(EnemyDatabase.has_archetype(tutorial_boss_id), "faction has its own tutorial boss archetype: " + tutorial_faction_id)
		var tutorial_guard_data: Dictionary = EnemyDatabase.get_archetype(tutorial_guard_id)
		var tutorial_boss_data: Dictionary = EnemyDatabase.get_archetype(tutorial_boss_id)
		assert(not bool(tutorial_guard_data.get("is_boss", true)) and bool(tutorial_boss_data.get("is_boss", false)), "faction guard and boss roles are distinct: " + tutorial_faction_id)
		assert(str(tutorial_guard_data.get("name", "")) != str(EnemyDatabase.get_archetype("arena_guard").get("name", "")), "faction guard has a distinct identity: " + tutorial_faction_id)
		assert(str(tutorial_boss_data.get("name", "")) != str(EnemyDatabase.get_archetype("arena_boss").get("name", "")), "faction boss has a distinct identity: " + tutorial_faction_id)

	for faction in FactionDatabase.get_factions():
		var faction_id := str(faction.get("id", ""))
		assert(str(FactionDatabase.get_world_profile(faction_id).get("faction_id", "")) == faction_id, "world profile retains its faction identity: " + faction_id)
	assert(FactionDatabase.get_world_profile("hongmeng").get("structure", "") == "orbs", "Hongmeng starting region has a distinct environment profile")
	assert(FactionDatabase.get_world_profile("underworld").get("accent_color", Color.BLACK) != FactionDatabase.get_world_profile("sea").get("accent_color", Color.BLACK), "underworld and sea starter zones have distinct visual palettes")
	var hongmeng_options: Array = FactionDatabase.get_class_options("hongmeng")
	var hongjun_selectable := false
	for hongmeng_option in hongmeng_options:
		if str(hongmeng_option.get("preset_id", "")) == "hongjun":
			hongjun_selectable = true
	assert(hongjun_selectable, "Hongjun is directly selectable from character creation")
	var original_onboarding_profile: Dictionary = RPGState.profile.duplicate(true)
	var hongjun_test_profile: Dictionary = original_onboarding_profile.duplicate(true)
	FactionDatabase.initialize_character_profile(hongjun_test_profile, "hongmeng", "hongjun")
	RPGState.profile = hongjun_test_profile
	assert(bool(RPGState.profile.get("is_supreme_deity", false)), "Hongjun profile is marked as the game's supreme deity")
	assert(str(RPGState.profile.get("spawn_region", "")) == "zixiao_palace", "Hongjun starts in the Zixiao Palace region")
	assert(FactionDatabase.can_interact_with_mentor("sanctuary"), "Hongjun tutorial accepts the Sanctuary entry")
	assert(FactionDatabase.can_interact_with_mentor("hongmeng"), "Hongjun tutorial accepts the Hongmeng entry")
	assert(not FactionDatabase.can_interact_with_mentor("underworld"), "Hongjun tutorial does not accept unrelated faction entries")
	assert(CampaignManager.get_active_mission().is_empty(), "anime campaign missions stay locked below level 10 for new faction characters")
	RPGState.profile["level"] = 10
	assert(not CampaignManager.get_active_mission().is_empty(), "anime campaign missions become available at level 10")
	RPGState.profile = original_onboarding_profile
	var balanced_test_profile: Dictionary = original_onboarding_profile.duplicate(true)
	balanced_test_profile["class_id"] = "apollo"
	balanced_test_profile["level"] = 1
	balanced_test_profile["story_balanced"] = true
	balanced_test_profile["power_mode"] = "story_balanced"
	balanced_test_profile["equipment"] = {}
	RPGState.profile = balanced_test_profile
	var balanced_divine_stats: Dictionary = RPGState.get_combat_stats()
	assert(float(balanced_divine_stats.get("max_health", 9999.0)) <= 300.0, "level-one selectable divine characters use story-balanced health")
	assert(float(balanced_divine_stats.get("attack", 9999.0)) <= 60.0, "level-one selectable divine characters use story-balanced attack")
	RPGState.profile = original_onboarding_profile
	assert(GrowthSystems.get_wing_catalog().size() == 8, "eight offline wing appearances are catalogued")
	assert(GrowthSystems.get_cosmos_star_map().get("nodes", []).size() == 6, "cosmos star map exposes six upgrade nodes")
	RPGState.profile["currency"] = 50000
	RPGState.profile["level"] = 60
	var growth_class_id := str(RPGState.profile.get("class_id", "pegasus"))
	var growth_cosmos_levels: Dictionary = RPGState.profile.get("cosmos_levels", {}).duplicate(true)
	growth_cosmos_levels[growth_class_id] = 20
	RPGState.profile["cosmos_levels"] = growth_cosmos_levels
	RPGState.profile["cosmos_level"] = 20
	assert(GrowthSystems.allocate_cosmos_node("star_attack"), "cosmos star node can be upgraded when points and currency are available")
	for sense_stage_id in GrowthSystems.SENSE_STAGES.keys():
		assert(GrowthSystems.breakthrough_sense(str(sense_stage_id)), "sense awakening stage unlocks in progression order: " + str(sense_stage_id))
	assert(int(GrowthSystems.get_sense_profile().get("unlocked_count", 0)) == 8, "five senses, sixth, seventh and eighth senses are all persisted")
	assert(float(GrowthSystems.get_growth_stat_bonus().get("critical_rate", 0.0)) > 0.0, "sense awakening contributes combat critical rate")
	assert(float(GrowthSystems.get_growth_stat_bonus().get("attack", 0.0)) >= 2.0, "cosmos star node contributes to combat attack")
	assert(GrowthSystems.unlock_wing("star_wing"), "first wing can be unlocked with offline game currency")
	assert(str(GrowthSystems.get_wing_profile().get("equipped", "")) == "star_wing", "newly unlocked wing is equipped")
	assert(GrowthSystems.upgrade_wing(), "equipped wing can be enhanced with offline currency")
	assert(float(GrowthSystems.get_growth_stat_bonus().get("max_health", 0.0)) > 0.0, "wing growth profile returns valid combat bonuses")
	assert(int(GrowthSystems.get_power_breakdown().get("total", 0)) > 0, "combat power is calculated from character progression")
	assert(int(GrowthSystems.get_power_breakdown().get("breakdown", {}).get("感官觉醒", 0)) > 0, "sense awakening is represented in combat power breakdown")
	assert(GrowthSystems.set_wing_visible(false) and not bool(GrowthSystems.get_wing_profile().get("visible", true)), "wing appearance visibility can be toggled")
	RPGState.profile = growth_original_profile
	assert(RPGState.save_slot(RPGState.active_slot), "restore original save after growth-system smoke tests")
	assert(BossChapterCombatCatalog.validate_catalog(), "all seven campaign chapters have complete boss combat profiles")
	var downloadable_chapter_count := 0
	for resource_pack_id in ResourcePackManager.catalog.get("packs", {}):
		var resource_pack_info := ResourcePackManager.get_pack_info(str(resource_pack_id))
		if bool(resource_pack_info.get("auto_download", false)):
			downloadable_chapter_count += 1
	assert(downloadable_chapter_count == 7, "resource catalog includes all seven auto-download campaign packs")
	var resource_pack_mount_status := ResourcePackManager.get_pack_mount_status("galaxy_wars")
	assert(resource_pack_mount_status.has("installed") and resource_pack_mount_status.has("valid") and resource_pack_mount_status.has("mounted"), "resource pack exposes separate installed, validation and runtime mount states")
	var resource_pack_mount_report: Dictionary = ResourcePackManager.mount_all_installed_packs()
	assert(resource_pack_mount_report.has("mounted_count") and resource_pack_mount_report.has("failed"), "startup pack mount pass returns a structured report")
	for dark_enemy_id in ["dark_phoenix_revenant", "dark_dragon_wraith", "dark_black_knight_champion"]:
		assert(EnemyDatabase.has_archetype(dark_enemy_id), "Dark Saint encounter archetype exists: " + dark_enemy_id)
		assert(bool(EnemyDatabase.get_archetype(dark_enemy_id).get("is_boss", false)), "Dark Saint encounter archetype is a boss: " + dark_enemy_id)
	var dark_commander_quest: Dictionary = {}
	for dark_quest_entry in SideQuestManager.QUESTS:
		if str(dark_quest_entry.get("id", "")) == "side_dark_knight_trial":
			dark_commander_quest = dark_quest_entry
	assert(str(dark_commander_quest.get("required_archetype_id", "")) == "dark_black_knight_champion", "Dark Saint challenge requires defeating its named commander")
	var dark_boss_drops: Array[Dictionary] = LootManager.get_drop_table(true, "dark_black_knight_champion")
	var has_dark_fragment_drop := false
	for dark_drop in dark_boss_drops:
		if str(dark_drop.get("item_id", "")) == "dark_cosmos_fragment":
			has_dark_fragment_drop = true
	assert(has_dark_fragment_drop and RPGState.ITEM_DATA.has("dark_cosmos_fragment"), "Dark Saint bosses have a dedicated Dark Cosmos Fragment material drop")
	assert(RPGState.ITEM_DATA.has("platinum_star_shard"), "Platinum awakening has its own Star Shard material")
	for dark_rank_id in ["dark_saint_scout", "dark_saint_raider", "dark_saint_elite", "dark_saint_captain"]:
		assert(EnemyDatabase.has_archetype(dark_rank_id), "Dark Saint faction rank is registered: " + dark_rank_id)
		assert(str(EnemyDatabase.get_archetype(dark_rank_id).get("faction", "")) == "dark_saints", "Dark Saint rank belongs to its faction: " + dark_rank_id)
	var dark_trial_waves: Array[Dictionary] = EncounterDirector.get_dark_faction_trial_waves()
	assert(dark_trial_waves.size() == 3, "Dark Saint faction trial contains three ordered waves")
	assert(str(dark_trial_waves[0]["spawns"][0].get("archetype_id", "")) == "dark_saint_scout", "Dark Saint trial opens with scout patrols")
	assert(str(dark_trial_waves[1]["spawns"][1].get("archetype_id", "")) == "dark_saint_elite", "Dark Saint trial escalates to elite officers")
	assert(str(dark_trial_waves[2]["spawns"][1].get("archetype_id", "")) == "dark_black_knight_champion", "Dark Saint trial ends with the Black Knight commander")
	var dark_elite_drops: Array[Dictionary] = LootManager.get_drop_table(false, "dark_saint_elite")
	var has_platinum_shard_drop := false
	for dark_elite_drop in dark_elite_drops:
		if str(dark_elite_drop.get("item_id", "")) == "platinum_star_shard":
			has_platinum_shard_drop = true
	assert(has_platinum_shard_drop, "Dark Saint elite enemies can drop Platinum Star Shards")
	var dark_patrol_quest_found := false
	for dark_quest_entry in SideQuestManager.QUESTS:
		if str(dark_quest_entry.get("id", "")) == "side_dark_patrol" and int(dark_quest_entry.get("target", 0)) == 3:
			dark_patrol_quest_found = true
	assert(dark_patrol_quest_found, "Dark Saint patrol quest tracks three enemy defeats")
	var dark_awakening_cost: Dictionary = ArmorSystem.get_awakening_requirements("dark_cloth")
	var platinum_awakening_cost: Dictionary = ArmorSystem.get_awakening_requirements("platinum")
	assert(str(dark_awakening_cost.get("material_id", "")) == "dark_cosmos_fragment" and int(dark_awakening_cost.get("material_count", 0)) == 5, "Dark Cloth awakening consumes five Dark Cosmos Fragments")
	assert(str(platinum_awakening_cost.get("material_id", "")) == "platinum_star_shard" and int(platinum_awakening_cost.get("material_count", 0)) == 5, "Platinum awakening consumes five distinct Star Shards")
	const WorldExplorationCatalog = preload("res://scripts/world_exploration_catalog.gd")
	assert(WorldExplorationCatalog.validate_catalog(), "world atlas contains seven unique regions with at least three landmarks each")
	var bond_before: Dictionary = CollectionSystem.get_active_companion_bond()
	assert(not bond_before.is_empty(), "new profiles receive a starter companion")
	var bond_gain: Dictionary = CollectionSystem.record_companion_bond_xp(25)
	assert(bool(bond_gain.get("success", false)), "active companion gains bond experience from combat")
	var bond_after: Dictionary = CollectionSystem.get_active_companion_bond()
	assert(int(bond_after.get("exp", 0)) >= int(bond_before.get("exp", 0)) or int(bond_after.get("level", 1)) > int(bond_before.get("level", 1)), "companion bond progress persists")
	assert(WorldExplorationManager.get_regions().size() == 7, "world map exposes all seven campaign regions")
	assert(SideQuestManager.QUESTS.size() == 23, "seven chapters plus Dark Saint patrol and commander challenges define optional quest content")
	var available_side_quests: Array[Dictionary] = SideQuestManager.get_quest_overview()
	var has_starting_side_quest := false
	var hidden_quest_visible := false
	for quest_entry in available_side_quests:
		if str(quest_entry.get("id", "")) == "side_galaxy_boss":
			has_starting_side_quest = true
		if str(quest_entry.get("id", "")) == "hidden_galaxy_stands":
			hidden_quest_visible = true
	assert(has_starting_side_quest, "starting chapter exposes its optional side quest")
	assert(not hidden_quest_visible, "undiscovered hidden quests remain concealed")
	assert(bool(WorldExplorationManager.get_regions()[0].get("unlocked", false)), "Galaxy Wars starting region is unlocked for a new profile")
	var chapter_profile_ids := {}
	for boss_id in ["arena_boss", "gold_taurus", "god_warrior_siegfried", "poseidon_emperor", "hades_emperor", "zeus_trial", "primordial_void"]:
		var chapter_profile: Dictionary = BossChapterCombatCatalog.get_profile(boss_id)
		chapter_profile_ids[str(chapter_profile.get("chapter_id", ""))] = true
	assert(chapter_profile_ids.size() == 7, "boss archetypes map to all seven chapter combat identities")
	var guard_test_player = preload("res://scripts/player.gd").new()
	guard_test_player.max_health = 100.0
	guard_test_player.apply_divine_guard(0.18, 6.0)
	assert(is_equal_approx(guard_test_player.divine_guard_shield, 18.0), "Athena divine guard grants 18% max-health shield")
	assert(is_equal_approx(guard_test_player.divine_guard_timer, 6.0), "Athena divine guard lasts six seconds")
	guard_test_player.apply_divine_guard(0.5, 2.0)
	assert(is_equal_approx(guard_test_player.divine_guard_shield, 18.0), "divine guard refresh cannot exceed existing shield capacity")
	assert(is_equal_approx(guard_test_player.divine_guard_timer, 6.0), "divine guard refresh cannot shorten duration")
	assert(is_equal_approx(guard_test_player.absorb_divine_guard_damage(10.0), 0.0), "divine guard fully absorbs incoming damage")
	assert(is_equal_approx(guard_test_player.divine_guard_shield, 8.0), "divine guard capacity decreases by absorbed damage")
	assert(is_equal_approx(guard_test_player.absorb_divine_guard_damage(20.0), 12.0), "damage exceeding divine guard spills over to health")
	assert(is_equal_approx(guard_test_player.divine_guard_shield, 0.0), "divine guard is depleted after absorbing its capacity")
	var saved_transform_armor_state: Dictionary = RPGState.profile.get("armor_state", {}).duplicate(true)
	var bronze_transform_key := guard_test_player._get_armor_transform_key()
	RPGState.profile["armor_state"] = {"current_stage":"dark_cloth","awakened":false}
	var dark_transform_key := guard_test_player._get_armor_transform_key()
	assert(bronze_transform_key != dark_transform_key, "changing armor tier triggers a distinct transformation identity")
	RPGState.profile["armor_state"]["awakened"] = true
	assert(dark_transform_key != guard_test_player._get_armor_transform_key(), "awakening a cloth triggers its own transformation identity")
	RPGState.profile["armor_state"] = saved_transform_armor_state
	guard_test_player.free()
	var solar_test_enemy = preload("res://scripts/enemy.gd").new()
	solar_test_enemy.divine_mark = "solar"
	solar_test_enemy.divine_mark_timer = 5.0
	assert(is_equal_approx(solar_test_enemy.get_divine_mark_burn_multiplier(), 1.2), "Apollo solar mark amplifies burn ticks against normal enemies")
	solar_test_enemy.is_boss = true
	assert(is_equal_approx(solar_test_enemy.get_divine_mark_burn_multiplier(), 0.75), "Apollo solar burn is reduced against bosses")
	solar_test_enemy.divine_mark_timer = 0.0
	assert(is_equal_approx(solar_test_enemy.get_divine_mark_burn_multiplier(), 1.0), "expired solar mark no longer amplifies burn")
	solar_test_enemy.free()
	var lunar_test_enemy = preload("res://scripts/enemy.gd").new()
	lunar_test_enemy.divine_mark = "lunar"
	lunar_test_enemy.divine_mark_timer = 4.0
	assert(is_equal_approx(lunar_test_enemy.get_divine_mark_damage_multiplier(), 1.12), "Artemis lunar mark grants 12% precision damage against normal enemies")
	lunar_test_enemy.is_boss = true
	assert(is_equal_approx(lunar_test_enemy.get_divine_mark_damage_multiplier(), 1.05), "lunar precision damage is reduced against bosses")
	lunar_test_enemy.divine_mark_timer = 0.0
	assert(is_equal_approx(lunar_test_enemy.get_divine_mark_damage_multiplier(), 1.0), "expired lunar mark grants no precision damage")
	lunar_test_enemy.free()
	var dream_test_enemy = preload("res://scripts/enemy.gd").new()
	dream_test_enemy.divine_mark = "dream"
	dream_test_enemy.divine_mark_timer = 5.0
	assert(is_equal_approx(dream_test_enemy.get_divine_mark_attack_rate_multiplier(), 0.75), "Hypnos dream mark slows normal enemy attack cadence by 25%")
	dream_test_enemy.is_boss = true
	assert(is_equal_approx(dream_test_enemy.get_divine_mark_attack_rate_multiplier(), 0.9), "Hypnos dream mark has reduced attack cadence effect against bosses")
	dream_test_enemy.divine_mark_timer = 0.0
	assert(is_equal_approx(dream_test_enemy.get_divine_mark_attack_rate_multiplier(), 1.0), "expired dream mark no longer slows attack cadence")
	dream_test_enemy.free()
	var time_test_enemy = preload("res://scripts/enemy.gd").new()
	time_test_enemy.divine_mark = "time"
	time_test_enemy.divine_mark_timer = 4.0
	assert(is_equal_approx(time_test_enemy.get_divine_mark_attack_rate_multiplier(), 0.82), "Chronos time mark slows normal enemy attack cadence by 18%")
	time_test_enemy.is_boss = true
	assert(is_equal_approx(time_test_enemy.get_divine_mark_attack_rate_multiplier(), 0.92), "time mark has reduced attack cadence effect against bosses")
	time_test_enemy.divine_mark_timer = 0.0
	assert(is_equal_approx(time_test_enemy.get_divine_mark_attack_rate_multiplier(), 1.0), "expired time mark restores attack cadence")
	time_test_enemy.free()
	var forge_test_enemy = preload("res://scripts/enemy.gd").new()
	forge_test_enemy.divine_mark = "forge"
	forge_test_enemy.divine_mark_timer = 3.0
	assert(is_equal_approx(forge_test_enemy.get_divine_mark_burn_multiplier(), 1.15), "Hephaestus forge mark strengthens burn damage")
	forge_test_enemy.is_boss = true
	assert(is_equal_approx(forge_test_enemy.get_divine_mark_burn_multiplier(), 1.08), "forge burn amplification is reduced against bosses")
	forge_test_enemy.free()
	assert(str(SettingsManager.get_value("system", "language", "zh_CN")) in ["zh_CN", "en_US"], "settings service")
	assert(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "Android ETC2 ASTC texture compression is enabled")
	assert(load("res://scripts/loot_pickup.gd") != null, "manual offline loot pickup actor is present")
	var armor_palette_ids := ["bronze", "silver", "gold", "sea_scale", "surplice", "dark_cloth", "platinum", "god_cloth", "god_armor"]
	for armor_palette_id in armor_palette_ids:
		var armor_palette: Dictionary = CharacterVisualCatalog.get_stage_palette(armor_palette_id)
		assert(armor_palette.has("metal") and armor_palette.has("trim"), "armor stage has metal and trim colors: " + armor_palette_id)
		assert(float(armor_palette.get("metallic", -1.0)) >= 0.0 and float(armor_palette.get("metallic", 1.1)) <= 1.0, "armor stage metallic value is bounded: " + armor_palette_id)
		var awakened_palette: Dictionary = CharacterVisualCatalog.get_stage_palette(armor_palette_id, true)
		assert(float(awakened_palette.get("glow", 0.0)) >= float(armor_palette.get("glow", 0.0)), "awakening increases or preserves armor glow: " + armor_palette_id)
	assert(armor_palette_ids.size() == ArmorSystem.get_stage_ids().size(), "visual palettes cover every armor progression stage")
	var pristine_armor_wear: Dictionary = ArmorSystem.get_visual_wear_profile(1.0)
	var damaged_armor_wear: Dictionary = ArmorSystem.get_visual_wear_profile(0.35)
	var broken_armor_wear: Dictionary = ArmorSystem.get_visual_wear_profile(0.1)
	assert(is_equal_approx(float(pristine_armor_wear.get("wear", 1.0)), 0.0), "pristine armor has no visible wear")
	assert(float(damaged_armor_wear.get("wear", 0.0)) > 0.0, "damaged armor exposes visible wear")
	assert(float(damaged_armor_wear.get("roughness", 0.0)) > float(pristine_armor_wear.get("roughness", 1.0)), "damaged armor becomes rougher")
	assert(bool(broken_armor_wear.get("cracked", false)), "critically damaged armor is marked cracked")
	assert(float(broken_armor_wear.get("metallic_multiplier", 1.1)) < float(pristine_armor_wear.get("metallic_multiplier", 0.0)), "damaged armor loses metallic finish")
	assert(str(pristine_armor_wear.get("condition_tier", "")) == "pristine", "intact armor is classified as pristine")
	assert(str(ArmorSystem.get_visual_wear_profile(0.6).get("condition_tier", "")) == "worn", "moderately worn armor has its own condition tier")
	assert(str(ArmorSystem.get_visual_wear_profile(0.4).get("condition_tier", "")) == "damaged", "damaged armor has its own condition tier")
	assert(str(ArmorSystem.get_visual_wear_profile(0.1).get("condition_tier", "")) == "critical", "critically damaged armor has its own condition tier")
	assert(str(ArmorSystem.get_visual_wear_profile(0.0).get("condition_tier", "")) == "broken", "zero durability armor is classified as broken")
	var saved_wear_state: Dictionary = RPGState.profile.get("armor_state", {}).duplicate(true)
	RPGState.profile["armor_state"] = {"current_stage":"bronze","durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100}}
	assert(is_equal_approx(ArmorSystem.get_damage_reduction(), 0.08), "intact armor grants up to eight percent damage mitigation")
	RPGState.profile["armor_state"]["durability"]["chest"] = 0
	assert(is_equal_approx(ArmorSystem.get_damage_reduction(), 0.064), "a broken armor piece reduces defensive mitigation proportionally")
	assert(ArmorSystem.get_part_condition_tier("chest") == "broken", "individual armor parts expose their broken state")
	RPGState.profile["armor_state"] = {"current_stage":"bronze","durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100}}
	var armor_hit_result: Dictionary = ArmorSystem.damage_part("head", 35)
	assert(bool(armor_hit_result.get("changed", false)) and int(armor_hit_result.get("before", 0)) == 100 and int(armor_hit_result.get("after", 100)) == 65, "armor impact reports the exact damaged part and durability change")
	assert(str(armor_hit_result.get("tier", "")) == "worn", "armor impact reports the resulting visual condition tier")
	assert(ArmorSystem.get_part_durability("head") == 65, "targeted armor damage is committed to the selected part")
	assert(ArmorSystem.damage_part("invalid_part", 10).is_empty(), "invalid armor part damage is safely rejected")
	var armor_detail_classes: Array = CharacterVisualCatalog.PROFILES.keys()
	assert(armor_detail_classes.size() == 32, "armor detail profiles cover all 32 classes")
	for armor_class_id in armor_detail_classes:
		var armor_detail: Dictionary = CharacterVisualCatalog.get_class_armor_detail_profile(str(armor_class_id))
		assert(not armor_detail.is_empty(), "each class has a dedicated armor detail profile")
		assert(str(armor_detail.get("shoulder_form", "")).length() > 0 and str(armor_detail.get("helmet_form", "")).length() > 0, "each class defines shoulder and helmet silhouette forms")
	RPGState.profile["armor_state"] = saved_wear_state
	assert(SkillAnimationCatalog.validate_catalog(), "animation style catalog covers all 32 playable classes")
	assert(SkillAnimationCatalog.get_profile("unknown_class", {"id": "ghost_skill"}).is_empty(), "unknown classes cannot receive fallback animation profiles")
	assert(SkillVisualCatalog.get_profile("unknown_class", {"id": "ghost_skill"}).is_empty(), "unknown classes cannot receive fallback visual profiles")
	assert(SkillAnimationCatalog.get_profile("pegasus", {}).is_empty(), "empty abilities cannot produce animation profiles")
	assert(SkillVisualCatalog.get_profile("pegasus", {}).is_empty(), "empty abilities cannot produce visual profiles")
	var art_coverage_report: Dictionary = ArtAssetAudit.build_report()
	assert(int(art_coverage_report.get("class_count", 0)) == 32, "art asset audit scans all 32 playable classes")
	for coverage_key in ["model_coverage", "portrait_coverage", "animation_coverage", "armor_model_coverage", "armor_icon_coverage", "armor_manifest_coverage", "enemy_model_coverage", "enemy_portrait_coverage", "chapter_scene_coverage", "skill_effect_coverage", "authored_asset_coverage"]:
		assert(float(art_coverage_report.get(coverage_key, -1.0)) >= 0.0 and float(art_coverage_report.get(coverage_key, 1.1)) <= 1.0, "art asset coverage is a valid ratio: " + coverage_key)
	assert(art_coverage_report.has("missing_models") and art_coverage_report.has("missing_portraits") and art_coverage_report.has("missing_animations"), "art asset audit reports missing deliverables explicitly")
	var equipment_art_count := EquipmentDatabase.get_catalog().size()
	assert(int(art_coverage_report.get("equipment_count", -1)) == equipment_art_count, "art audit covers every catalogued armor and garment")
	assert(art_coverage_report.has("missing_armor_models") and art_coverage_report.has("missing_armor_icons") and art_coverage_report.has("missing_armor_manifests"), "armor audit reports every missing deliverable")
	assert(int(art_coverage_report.get("enemy_count", -1)) == EnemyDatabase.ARCHETYPES.size(), "art audit covers every enemy and boss")
	assert(art_coverage_report.has("missing_enemy_models") and art_coverage_report.has("missing_enemy_portraits"), "enemy audit reports missing authored assets")
	assert(int(art_coverage_report.get("chapter_count", 0)) == 7 and art_coverage_report.has("missing_chapter_scenes"), "art audit covers all seven campaign environment themes")
	assert(int(art_coverage_report.get("skill_count", 0)) == 768, "art audit counts all 768 class abilities")
	assert(int(art_coverage_report.get("skill_element_count", 0)) == 11, "art audit covers all 11 elemental VFX families, including sound")
	assert(art_coverage_report.has("missing_skill_effects"), "skill VFX audit reports missing authored element effects")
	assert(int(art_coverage_report.get("authored_asset_total", 0)) > 0, "art audit reports the total authored asset scope")
	assert(int(art_coverage_report.get("authored_asset_found", -1)) + int(art_coverage_report.get("authored_asset_missing", -1)) == int(art_coverage_report.get("authored_asset_total", 0)), "art audit found and missing counts reconcile")
	assert(typeof(art_coverage_report.get("authored_art_complete", null)) == TYPE_BOOL, "art audit exposes an explicit completion gate")
	var animation_profile_count := 0
	for class_entry in SkillSystem.get_class_skill_catalog():
		var animation_class_id := str(class_entry.get("id", ""))
		for animation_ability in SkillSystem.get_ability_catalog(animation_class_id):
			var animation_profile: Dictionary = SkillAnimationCatalog.get_profile(animation_class_id, animation_ability)
			assert(float(animation_profile.get("startup", 0.0)) > 0.0, "skill animation has startup timing")
			assert(float(animation_profile.get("active", 0.0)) > 0.0, "skill animation has active timing")
			assert(float(animation_profile.get("recovery", 0.0)) > 0.0, "skill animation has recovery timing")
			assert(float(animation_profile.get("total_duration", 0.0)) >= float(animation_profile.get("startup", 0.0)), "skill animation total duration is consistent")
			assert(str(animation_profile.get("weapon_socket", "")) != "", "skill animation has an attachment socket")
			assert(SkillAnimationCatalog.validate_profile(animation_profile), "skill animation timeline and hit windows are valid: " + str(animation_ability.get("id", "")))
			assert(animation_profile.get("hit_windows", []).size() == int(animation_profile.get("hit_count", 0)), "skill hit windows match hit count")
			assert(not animation_profile.get("timeline", []).is_empty(), "skill animation exposes ordered event markers")
			animation_profile_count += 1
	assert(animation_profile_count == 768, "animation profiles generated for all 768 abilities")
	var enemy_visual_profile_count := 0
	for enemy_id in EnemyDatabase.ARCHETYPES:
		var enemy_data: Dictionary = EnemyDatabase.get_archetype(str(enemy_id))
		var enemy_visual_profile: Dictionary = EnemyVisualCatalog.get_profile(str(enemy_id), bool(enemy_data.get("is_boss", false)), enemy_data.get("color", Color.WHITE))
		assert(EnemyVisualCatalog.validate_profile(enemy_visual_profile), "enemy armor visual profile is valid: " + str(enemy_id))
		enemy_visual_profile_count += 1
	assert(enemy_visual_profile_count == EnemyDatabase.ARCHETYPES.size(), "every enemy and boss has a visual profile")
	assert(load("res://scripts/world_theme_manager.gd") != null, "procedural chapter world theme manager is present")
	var world_theme_test_root := Node3D.new()
	add_child(world_theme_test_root)
	var test_world_environment := WorldEnvironment.new()
	test_world_environment.environment = Environment.new()
	world_theme_test_root.add_child(test_world_environment)
	var test_world_sun := DirectionalLight3D.new()
	world_theme_test_root.add_child(test_world_sun)
	var test_floor_material := StandardMaterial3D.new()
	var test_ring_root := Node3D.new()
	world_theme_test_root.add_child(test_ring_root)
	var test_ring := MeshInstance3D.new()
	test_ring_root.add_child(test_ring)
	var world_theme_test = preload("res://scripts/world_theme_manager.gd").new()
	world_theme_test.world_environment = test_world_environment
	world_theme_test.sun = test_world_sun
	world_theme_test.floor_material = test_floor_material
	world_theme_test.ring_root = test_ring_root
	world_theme_test_root.add_child(world_theme_test)
	for theme_id in ["galaxy_wars", "sanctuary_twelve_houses", "asgard", "poseidon", "hades", "heaven", "original_final"]:
		assert(world_theme_test.apply_theme(theme_id), "campaign world theme applies: " + theme_id)
		assert(world_theme_test.decor_root.get_child_count() >= 20, "chapter environment builds visible structures: " + theme_id)
	assert(test_world_environment.environment.background_mode == Environment.BG_SKY, "chapter theme configures a procedural sky")
	assert(test_world_environment.environment.glow_enabled, "chapter theme enables controlled cosmic glow")
	var medium_glow_intensity := test_world_environment.environment.glow_intensity
	assert(medium_glow_intensity > 0.0, "medium quality keeps a restrained cosmic glow")
	SettingsManager.set_value("graphics", "effects", false, false)
	assert(not test_world_environment.environment.glow_enabled, "disabling effects turns off environment glow")
	SettingsManager.set_value("graphics", "effects", true, false)
	SettingsManager.set_value("graphics", "quality", "low", false)
	assert(test_world_environment.environment.glow_enabled, "low quality retains reduced glow when effects are enabled")
	assert(test_world_environment.environment.glow_intensity < medium_glow_intensity, "low quality reduces glow intensity")
	SettingsManager.set_value("graphics", "quality", "medium", false)
	world_theme_test_root.queue_free()
	var hud_layout_test = preload("res://scripts/hud.gd").new()
	var hud_layout_root := Control.new()
	var left_layout_button: Button = hud_layout_test._button(hud_layout_root, "left", Vector2(20, 20), Vector2(120, 80), func() -> void: pass, Color.WHITE)
	var right_layout_button: Button = hud_layout_test._button(hud_layout_root, "right", Vector2(-120, -80), Vector2(-20, -20), func() -> void: pass, Color.WHITE)
	assert(is_equal_approx(left_layout_button.anchor_left, 0.0) and is_equal_approx(left_layout_button.anchor_top, 0.0), "positive HUD coordinates anchor from top-left")
	assert(is_equal_approx(right_layout_button.anchor_left, 1.0) and is_equal_approx(right_layout_button.anchor_top, 1.0), "negative HUD coordinates anchor from bottom-right")
	hud_layout_test.free()
	hud_layout_root.free()
	assert(SettingsManager.set_value("graphics", "quality", "low", false), "low graphics preset can be applied")
	assert(is_equal_approx(get_viewport().scaling_3d_scale, 0.75), "low graphics preset caps render scale")
	assert(SettingsManager.set_value("graphics", "quality", "high", false), "high graphics preset can be applied")
	assert(is_equal_approx(get_viewport().scaling_3d_scale, 1.0), "high graphics preset restores full render scale")
	assert(SettingsManager.set_value("graphics", "quality", "medium", false), "restore medium graphics preset")
	assert(SettingsManager.set_value("graphics", "render_scale", 1.0, false), "restore default render scale")
	assert(str(LocalizationManager.text_for("ui.attack")) != "", "localization service")
	assert(AudioManager != null, "audio service")
	assert(SystemHealthManager != null, "system health service")
	assert(ApplicationLifecycleManager != null, "application lifecycle service")
	assert(CombatSessionManager != null, "combat session service")
	assert(DailyBossManager != null, "offline daily boss service")
	assert(EncounterDirector != null, "encounter director service")
	assert(not EncounterDirector.start("invalid_empty_wave", [{"spawns": []}]), "reject encounters containing empty waves")
	assert(not EncounterDirector.start("invalid_unknown_enemy", [{"spawns": [{"archetype_id": "missing_enemy", "count": 1}]}]), "reject unknown enemy archetypes")
	assert(not EncounterDirector.start("invalid_zero_spawn", [{"spawns": [{"archetype_id": "arena_guard", "count": 0}]}]), "reject zero-count waves that could stall progression")
	assert(not EncounterDirector.active, "invalid encounter definitions do not activate the director")
	var test_waves: Array[Dictionary] = [{"spawns": [{"archetype_id": "arena_guard", "count": 1}]}, {"spawns": [{"archetype_id": "arena_elite", "count": 1}]}]
	assert(EncounterDirector.start("smoke_two_wave", test_waves), "start two-wave encounter")
	assert(int(EncounterDirector.get_current_wave().get("wave_number", 0)) == 1, "first wave begins")
	EncounterDirector.register_enemy(1)
	EncounterDirector.report_enemy_defeated()
	var second_wave := EncounterDirector.advance_wave()
	assert(int(second_wave.get("wave_number", 0)) == 2, "advance to second wave after clear")
	EncounterDirector.register_enemy(1)
	EncounterDirector.report_enemy_defeated()
	assert(EncounterDirector.advance_wave().is_empty() and not EncounterDirector.active, "finish encounter after final wave")
	assert(DailyBossManager.get_rotation_catalog().size() == 7, "seven-day daily boss rotation")
	assert(str(DailyBossManager.get_state().get("boss_id", "")) != "", "daily boss cycle initialized")
	assert(int(DailyBossManager.get_state().get("reset_hour_local", -1)) == 5, "daily boss reset at local 05:00")
	var daily_profile_snapshot: Dictionary = RPGState.profile.duplicate(true)
	var daily_state_snapshot: Dictionary = DailyBossManager.state.duplicate(true)
	var daily_slot_snapshot := RPGState.active_slot
	DailyBossManager.state = {
		"version": 1,
		"cycle_id": "2099-01-01",
		"boss_id": "daily_celestial_guardian",
		"defeated": true,
		"reward_claimed": false
	}
	RPGState.active_slot = 0
	var rejected_daily_claim: Dictionary = DailyBossManager.claim_reward()
	assert(not bool(rejected_daily_claim.get("success", false)), "daily reward claim rejects an unavailable save slot")
	assert(RPGState.profile == daily_profile_snapshot, "failed daily reward claim rolls back all profile rewards")
	assert(not bool(DailyBossManager.state.get("reward_claimed", false)), "failed daily reward claim rolls back claim marker")
	RPGState.profile = daily_profile_snapshot
	RPGState.active_slot = daily_slot_snapshot
	DailyBossManager.state = daily_state_snapshot
	var local_date := Time.get_datetime_dict_from_system()
	var before_reset := {"year": local_date.year, "month": local_date.month, "day": local_date.day, "hour": 4, "minute": 59, "second": 0}
	var after_reset := {"year": local_date.year, "month": local_date.month, "day": local_date.day, "hour": 5, "minute": 1, "second": 0}
	assert(DailyBossManager._cycle_id_from_local(before_reset) != DailyBossManager._cycle_id_from_local(after_reset), "daily boss cycle changes across local reset boundary")
	assert(LootManager != null, "offline loot service")
	assert(EnemyDatabase.has_archetype("arena_guard") and EnemyDatabase.has_archetype("arena_boss"), "enemy archetype catalog")
	assert(float(EnemyDatabase.get_archetype("arena_boss").get("health", 0.0)) > float(EnemyDatabase.get_archetype("arena_guard").get("health", 0.0)), "boss archetype stronger than normal enemy")
	assert(EquipmentAffixManager != null, "equipment affix service")
	var skill_state: Dictionary = SkillSystem.get_skill_state("pegasus")
	assert(str(skill_state.get("class_id", "")) == "pegasus", "skill tree state class binding")
	assert(not skill_state.get("abilities", []).is_empty(), "skill tree catalog state")
	var phoenix_skill_cost := float(SkillSystem.get_class_skill("phoenix").get("cost", 18))
	assert(phoenix_skill_cost > 18.0, "Phoenix class skill has a higher resource cost")
	assert(not SkillSystem.can_afford_class_skill("phoenix", 18.0), "class skill affordability rejects insufficient cosmos")
	assert(SkillSystem.can_afford_class_skill("phoenix", phoenix_skill_cost), "class skill affordability accepts exact cost")
	for class_entry in SkillSystem.get_class_skill_catalog():
		var catalog_class_id := str(class_entry.get("id", ""))
		assert(SkillSystem.get_ability_catalog(catalog_class_id).size() == 24, "24 skills configured for " + catalog_class_id)
	assert(ArmorSystem.unlock_all_stages(), "unlock all armor stages saves successfully")
	assert(ArmorSystem.get_state().get("unlocked_stages", []).size() == ArmorSystem.get_stage_ids().size() and ArmorSystem.get_stage_ids().size() == 9, "all nine armor progression stages unlocked")
	assert(ArmorSystem.equip_stage("gold"), "equip unlocked gold cloth stage")
	assert(ArmorSystem.get_current_stage_name() == "黄金圣衣", "armor stage selection reflected")
	assert(ArmorSystem.equip_stage("bronze"), "restore bronze cloth stage")
	assert(RPGState.select_class("dragon"), "switch to dragon class")
	assert(str(RPGState.profile.get("class_id", "")) == "dragon", "class switch persisted")
	assert(RPGState.select_class("pegasus"), "switch back to pegasus class")
	for class_id in RPGState.CLASS_DATA:
		var class_data: Dictionary = RPGState.CLASS_DATA[class_id]
		if str(class_data.get("tier", "")) in ["神明", "天斗士"]:
			assert(EquipmentDatabase.EQUIPMENT.has(str(class_data.get("starter", ""))), "divine/heavenly starter relic exists for " + str(class_id))
	var previous_level := int(RPGState.profile.get("level", 1))
	RPGState.profile["level"] = 70
	assert(RPGState.save_slot(RPGState.active_slot), "prepare divine class unlock test")
	assert(RPGState.select_class("zeus"), "unlock Zeus class at level 70")
	assert(str(RPGState.profile.get("equipped_relic", "")) == "zeus_divine_relic", "divine class auto-equips its own relic")
	assert(EquipmentDatabase.get_bonus_stats().get("attack", 0.0) > 0.0, "divine starter relic stats apply")
	RPGState.profile["level"] = previous_level
	assert(RPGState.select_class("pegasus"), "return to mortal class")
	assert(str(RPGState.profile.get("equipped_relic", "")) == "", "mortal class does not retain divine relic bonuses")
	assert(bool(SkillSystem.can_learn_ability("pegasus", "pegasus_skill_2").get("allowed", false)) == (int(RPGState.profile.get("level", 1)) >= 5 and int(RPGState.profile.get("skill_points", 0)) > 0), "skill learn requirements are explicit")
	assert(EquipmentAffixManager.roll_affixes("arms", 2), "roll and persist equipment affixes")
	assert(not EquipmentAffixManager.get_equipped_affixes().get("arms", []).is_empty(), "equipment affixes persisted")
	assert(EquipmentAffixManager.clear_affixes("arms"), "clear equipment affixes")
	CombatSessionManager.begin_encounter("smoke_combat")
	CombatSessionManager.record_damage_dealt(125.0)
	CombatSessionManager.record_damage_taken(15.0)
	CombatSessionManager.record_skill_cast(true)
	CombatSessionManager.record_enemy_defeated(true)
	var combat_summary: Dictionary = CombatSessionManager.finish_encounter()
	assert(float(combat_summary.get("damage_dealt", 0.0)) == 125.0, "combat damage statistics")
	assert(float(combat_summary.get("damage_taken", 0.0)) == 15.0, "combat damage taken statistics")
	assert(int(combat_summary.get("bosses_defeated", 0)) == 1 and int(combat_summary.get("combos_used", 0)) == 1, "combat encounter summary")
	assert(str(combat_summary.get("grade", "")) in ["S", "A", "B", "C"], "combat result grade")
	assert(LootManager.grant_drop("cosmos_potion", 1), "grant valid offline loot")
	assert(not LootManager.grant_drop("unknown_item", 1), "reject unknown loot item")
	var inventory_before: Dictionary = RPGState.profile.get("inventory", {}).duplicate(true)
	assert(not RPGState.add_items({"cosmos_potion": 2, "invalid_item": 1}), "reject invalid inventory transaction")
	assert(RPGState.profile.get("inventory", {}) == inventory_before, "inventory transaction rollback")
	assert(RPGState.profile.get("quest_progress", {}) is Dictionary and RPGState.profile.get("campaign_progress", {}) is Dictionary, "slot progress containers")


	var original_fps := int(SettingsManager.get_value("graphics", "fps_limit", 60))
	assert(SettingsManager.set_value("graphics", "fps_limit", 999), "settings write")
	assert(int(SettingsManager.get_value("graphics", "fps_limit", 60)) == 120, "settings clamp")
	assert(SettingsManager.set_value("graphics", "fps_limit", original_fps), "settings restore")
	LocalizationManager.set_locale("en_US")
	assert(str(LocalizationManager.text_for("ui.attack")) == "Attack", "locale switch")
	LocalizationManager.set_locale("zh_CN")
	assert(not SceneFlowManager.change_scene("res://" + "scenes/not_a_real_scene.tscn"), "reject invalid scene path")
	assert(not ResourcePackManager.validate_source_directory("user://missing_pack", "galaxy_wars").get("valid", false), "reject missing pack source")
	var source_dir := "user://framework_pack_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_dir))
	var payload_path := source_dir.path_join("payload.txt")
	var payload := FileAccess.open(payload_path, FileAccess.WRITE)
	assert(payload != null, "create package payload")
	payload.store_string("offline package test")
	payload.close()
	var pck_resource_path := "res://" + "content/framework_pack_probe.txt"
	var pck_path := source_dir.path_join("chapter_test.pck")
	var pck_packer := PCKPacker.new()
	assert(pck_packer.pck_start(ProjectSettings.globalize_path(pck_path)) == OK, "create real Godot PCK container")
	assert(pck_packer.add_file(pck_resource_path, ProjectSettings.globalize_path(payload_path)) == OK, "add test resource to PCK")
	assert(pck_packer.flush() == OK, "write complete Godot PCK")
	var pck_reader := FileAccess.open(pck_path, FileAccess.READ)
	assert(pck_reader != null, "read generated PCK")
	var pck_size := int(pck_reader.get_length())
	pck_reader.close()
	var manifest := {
		"id": "galaxy_wars",
		"manifest_version": 1,
		"version": 1,
		"size_bytes": pck_size,
		"dependencies": [],
		"files": [{"path": "chapter_test.pck", "size_bytes": pck_size, "sha256": FileAccess.get_sha256(pck_path)}]
	}
	var manifest_file := FileAccess.open(source_dir.path_join("pack.json"), FileAccess.WRITE)
	assert(manifest_file != null, "create package manifest")
	manifest_file.store_string(JSON.stringify(manifest))
	manifest_file.close()
	assert(bool(ResourcePackManager.preflight_install(source_dir, "galaxy_wars").get("allowed", false)), "real PCK resource package preflight")
	assert(ResourcePackManager.install_from_directory(source_dir, "galaxy_wars"), "real PCK staged install and runtime mount")
	var installed_status: Dictionary = ResourcePackManager.get_pack_mount_status("galaxy_wars")
	assert(bool(installed_status.get("installed", false)) and bool(installed_status.get("valid", false)) and bool(installed_status.get("mounted", false)), "real PCK reports installed, verified and mounted")
	assert(FileAccess.file_exists(pck_resource_path), "mounted PCK exposes its file through the virtual filesystem")
	var mounted_probe := FileAccess.open(pck_resource_path, FileAccess.READ)
	assert(mounted_probe != null and mounted_probe.get_as_text() == "offline package test", "read resource content from mounted PCK")
	mounted_probe.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(payload_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_dir.path_join("pack.json")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pck_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_dir))

	assert(int(ResourcePackManager.get_storage_summary().get("installed_count", -1)) >= 0, "pack storage summary")
	SystemHealthManager.report_error("smoke_test", "诊断日志测试")
	assert(not SystemHealthManager.get_recent_errors().is_empty(), "diagnostic error record")
	assert(SystemHealthManager.clear_log(), "diagnostic log cleanup")
	assert(bool(SaveManager.save_document("ci_framework_smoke", {"passed": true, "value": 42})), "save document")
	var loaded: Dictionary = SaveManager.load_document("ci_framework_smoke")
	assert(bool(loaded.get("passed", false)) and int(loaded.get("value", 0)) == 42, "save/load roundtrip")
	SaveManager.delete_document("ci_framework_smoke")
	assert(bool(DialogueManager.start_dialogue("ci_smoke", [{"text": "第一句"}, {"text": "第二句"}])), "dialogue start")
	assert(str(DialogueManager.get_current_line().get("text", "")) == "第一句", "dialogue first line")
	assert(str(DialogueManager.advance().get("text", "")) == "第二句", "dialogue advance")
	DialogueManager.advance()
	assert(not DialogueManager.is_active, "dialogue completion")
	assert(not ResourcePackManager.get_pack_info("galaxy_wars").is_empty(), "offline pack catalog")
	assert(RPGState.create_new_slot(3), "create empty character slot")
	var slot_summary: Dictionary = RPGState.get_slot_summary(3)
	assert(bool(slot_summary.get("exists", false)) and bool(slot_summary.get("valid", false)), "slot summary")
	RPGState.profile["currency"] = 9876
	assert(RPGState.save_slot(3), "save created slot")
	assert(not RPGState.create_new_slot(3), "do not overwrite occupied slot")
	assert(RPGState.load_slot(3) and int(RPGState.profile.get("currency", 0)) == 9876, "occupied slot data preserved")
	QuestManager.status = "active"
	QuestManager.defeated_normal = 1
	QuestManager._save_progress()
	var first_mission_id := CampaignDatabase.get_first_mission_id()
	var sanctuary_chapter: Dictionary = CampaignDatabase.get_chapter("sanctuary_twelve_houses")
	assert(sanctuary_chapter.get("missions", []).size() == 14, "Sanctuary arc has ordered story missions")
	assert(str(CampaignDatabase.get_mission("s12_002").get("type", "")) == "story", "Mu chapter is a story interaction, not a forced boss fight")
	assert(str(CampaignDatabase.get_mission("s12_008").get("type", "")) == "story", "Libra chapter is support story, not a forced boss fight")
	assert(str(CampaignDatabase.get_mission("s12_010").get("type", "")) == "story", "Sagittarius legacy is a story trial, not a living boss fight")
	for archetype_id in ["gold_taurus", "gemini_illusion", "gold_cancer", "gold_leo_controlled", "gold_virgo", "gold_scorpio", "gold_capricorn", "gold_aquarius", "gold_pisces", "pope_saga"]:
		assert(EnemyDatabase.has_archetype(archetype_id), "Sanctuary encounter archetype: " + archetype_id)
	var taurus_profile: Dictionary = EnemyDatabase.get_archetype("gold_taurus")
	var scorpio_profile: Dictionary = EnemyDatabase.get_archetype("gold_scorpio")
	assert(float(taurus_profile.get("boss_heavy_multiplier", 0.0)) > float(scorpio_profile.get("boss_heavy_multiplier", 0.0)), "Taurus heavy strike has a distinct impact profile")
	assert(float(scorpio_profile.get("boss_windup", 1.0)) < float(taurus_profile.get("boss_windup", 0.0)), "Scorpio attacks use a faster warning cadence")
	var test_boss: Node = load("res://scripts/enemy.gd").new()
	test_boss.archetype_id = "gold_taurus"
	add_child(test_boss)
	assert(bool(test_boss.is_boss), "boss test instance resolves its boss archetype")
	test_boss.state = 1
	test_boss.state_timer = 1.0
	test_boss.take_damage(10.0)
	assert(int(test_boss.state) == 1, "ordinary damage does not cancel a boss wind-up")
	test_boss.apply_hit_reaction(Vector3.RIGHT, 10.0, 5.0, 0.8)
	assert(int(test_boss.state) == 1 and float(test_boss.velocity.y) <= 0.0, "boss wind-up resists stagger and launch")
	test_boss.state = 0
	test_boss.apply_status_effect("freeze", 2.0, 0.0)
	assert(float(test_boss.freeze_timer) < 2.0, "boss freeze duration is resisted")
	test_boss.apply_status_effect("slow", 2.0, 0.5)
	assert(is_equal_approx(SkillSystem.get_target_condition_multiplier("cygnus", test_boss), 1.12), "Cygnus passive increases damage against controlled targets")
	var boss_story_audit: Dictionary = BossStoryCatalog.validate_catalog()
	assert(bool(boss_story_audit.get("valid", false)) and int(boss_story_audit.get("chapter_count", 0)) == 7 and int(boss_story_audit.get("scene_count", 0)) == 14, "seven chapters have authored boss intro and outro story scenes: " + str(boss_story_audit.get("errors", [])))
	var fallback_boss_scene: Dictionary = BossStoryCatalog.get_scene("unknown", "unknown", "intro", "测试首领")
	assert(fallback_boss_scene.get("lines", []).size() >= 2, "boss story catalog provides generic scenes for non-final bosses")
	var saga_battle_line: Dictionary = BossStoryCatalog.get_battle_line("pope_saga", "enrage", "教皇撒加")
	assert(str(saga_battle_line.get("speaker", "")) == "教皇撒加" and str(saga_battle_line.get("text", "")).contains("银河星爆"), "major bosses have unique phase dialogue")
	var generic_battle_line: Dictionary = BossStoryCatalog.get_battle_line("unknown_boss", "special_attack", "测试首领")
	assert(not str(generic_battle_line.get("text", "")).is_empty(), "unlisted bosses receive safe fallback combat dialogue")
	var break_battle_line: Dictionary = BossStoryCatalog.get_battle_line("pope_saga", "break", "教皇撒加")
	assert(str(break_battle_line.get("speaker", "")) == "教皇撒加" and not str(break_battle_line.get("text", "")).is_empty(), "boss break events provide combat dialogue")
	var break_test_enemy = preload("res://scripts/enemy.gd").new()
	break_test_enemy.is_boss = true
	break_test_enemy.archetype_id = "pope_saga"
	break_test_enemy._register_boss_control(0.4)
	break_test_enemy._register_boss_control(0.4)
	break_test_enemy._register_boss_control(0.4)
	assert(bool(break_test_enemy.boss_break_active), "repeated control pressure breaks boss poise")
	assert(is_equal_approx(float(break_test_enemy.state_timer), 1.8), "boss break creates a readable vulnerability window")
	break_test_enemy.free()
	var campaign_catalog_audit: Dictionary = CampaignDatabase.validate_catalog()
	assert(bool(campaign_catalog_audit.get("valid", false)) and int(campaign_catalog_audit.get("chapter_count", 0)) == 7 and int(campaign_catalog_audit.get("mission_count", 0)) == 55, "all seven campaign arcs and 55 missions pass catalog validation: " + str(campaign_catalog_audit.get("errors", [])))
	var enemy_catalog_audit: Dictionary = EnemyDatabase.validate_archetypes()
	assert(bool(enemy_catalog_audit.get("valid", false)) and int(enemy_catalog_audit.get("archetype_count", 0)) >= 50, "all enemy archetypes pass combat-stat validation: " + str(enemy_catalog_audit.get("errors", [])))
	var expected_boss_specials := {
		"hypnos_guardian": "sleeping_field",
		"thanatos_reaper": "death_mark",
		"hades_emperor": "soul_leech",
		"poseidon_emperor": "tidal_pull",
		"apollo_trial": "solar_flare",
		"zeus_trial": "storm_chain",
		"universe_arbiter": "cosmic_collapse",
		"judge_griffin": "gravity_crush",
		"judge_garuda": "judge_combo",
		"judge_wyvern": "wing_slam",
		"gold_taurus": "gravity_crush",
		"gold_cancer": "soul_leech",
		"gold_leo_controlled": "lightning_followup",
		"gold_virgo": "dream_drain",
		"gold_scorpio": "death_burst",
		"gold_capricorn": "wing_slam",
		"gold_aquarius": "rift_drain",
		"gold_pisces": "tidal_pull",
		"pope_saga": "void_drain",
		"god_warrior_thor": "gravity_crush",
		"god_warrior_fenrir": "wing_slam",
		"god_warrior_hagen": "frostfire",
		"god_warrior_mime": "sonic_wave",
		"god_warrior_alberich": "crystal_seal",
		"god_warrior_syd": "lightning_followup",
		"god_warrior_bud": "death_burst",
		"god_warrior_siegfried": "judge_combo",
		"mariner_baian": "tidal_pull",
		"mariner_io": "six_beasts",
		"mariner_krishna": "gravity_crush",
		"mariner_kasa": "mirror_feint",
		"mariner_isaac": "rift_drain",
		"mariner_sorrento": "sonic_wave",
		"mariner_kanon": "void_drain"
	}
	for boss_id in expected_boss_specials:
		assert(str(EnemyDatabase.get_archetype(boss_id).get("boss_special", "")) == str(expected_boss_specials[boss_id]), "major boss has a unique heavy-attack signature: " + boss_id)
	var skill_audit: Dictionary = SkillSystem.validate_all_class_skill_catalogs()
	assert(bool(skill_audit.get("valid", false)), "all 32 classes must expose 24 complete unique skills: " + str(skill_audit.get("errors", [])))
	assert(int(skill_audit.get("class_count", 0)) == 32, "all base, divine and heavenly classes are registered")
	assert(int(skill_audit.get("ability_count", 0)) == 768, "all class ability catalogs contain 768 entries")
	var visual_catalog_script = preload("res://scripts/character_visual_catalog.gd")
	var visual_audit: Dictionary = visual_catalog_script.validate_catalog()
	assert(bool(visual_audit.get("valid", false)), "all 32 classes have validated visual identity profiles: " + str(visual_audit.get("errors", [])))
	assert(int(visual_audit.get("class_count", 0)) == 32, "visual catalog covers all 32 playable classes")
	for visual_class in SkillSystem.get_class_skill_catalog():
		var visual_class_id := str(visual_class.get("id", ""))
		var visual_profile: Dictionary = visual_catalog_script.get_profile(visual_class_id)
		assert(visual_profile.has("accent") and visual_profile.has("crest") and visual_profile.has("ornament"), visual_class_id + " has complete visual identity")
		var part_profiles: Dictionary = visual_catalog_script.get_class_armor_part_profiles(visual_class_id, "gold", true)
		for armor_part_id in ["head", "chest", "arms", "waist", "legs"]:
			var part_profile: Dictionary = part_profiles.get(armor_part_id, {})
			assert(not str(part_profile.get("form", "")).is_empty(), visual_class_id + " has a distinct " + armor_part_id + " armor part profile")
			var part_scale: Vector3 = part_profile.get("scale", Vector3.ZERO)
			assert(part_scale.x > 0.0 and part_scale.y > 0.0 and part_scale.z > 0.0, visual_class_id + " has valid " + armor_part_id + " armor part dimensions")
		assert(str(part_profiles.get("head", {}).get("crest", "")) == str(visual_profile.get("crest", "")), visual_class_id + " helmet profile retains the class crest")
		assert(str(part_profiles.get("chest", {}).get("ornament", "")) == str(visual_profile.get("ornament", "")), visual_class_id + " chest profile retains the class ornament")
		var dark_visual_profile: Dictionary = visual_catalog_script.get_equipment_profile({"id": "dark_" + visual_class_id + "_cloth", "class_id": visual_class_id})
		assert(str(dark_visual_profile.get("crest", "")) == str(visual_profile.get("crest", "")), visual_class_id + " Dark Cloth preserves its profession crest")
		assert(str(dark_visual_profile.get("ornament", "")) == "dark_aura", visual_class_id + " Dark Cloth uses the void ornament treatment")
		assert(str(dark_visual_profile.get("class_ornament", "")) == str(visual_profile.get("ornament", "")) and str(dark_visual_profile.get("class_silhouette", "")) == str(visual_profile.get("silhouette", "")), visual_class_id + " Dark Cloth retains its class-specific ornament and silhouette")
		var platinum_visual_profile: Dictionary = visual_catalog_script.get_equipment_profile({"id": "platinum_cloth_archive", "class_id": visual_class_id, "category": "白金圣衣 Platinum Cloth"})
		assert(str(platinum_visual_profile.get("crest", "")) == str(visual_profile.get("crest", "")), visual_class_id + " Platinum Cloth preserves its profession crest")
		assert(str(platinum_visual_profile.get("class_ornament", "")) == str(visual_profile.get("ornament", "")) and str(platinum_visual_profile.get("class_silhouette", "")) == str(visual_profile.get("silhouette", "")), visual_class_id + " Platinum Cloth retains its class-specific ornament and silhouette")
		assert(str(platinum_visual_profile.get("stage_variant", "")) == "platinum" and float(platinum_visual_profile.get("metallic", 0.0)) == 1.0, visual_class_id + " Platinum Cloth applies its radiant metal stage")
	var apollo_armor_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "apollo_divine_relic", "category": "神明专属神衣"})
	assert(str(apollo_armor_visual.get("ornament", "")) == "solar_wings", "Apollo divine relic selects solar armor ornaments")
	var poseidon_armor_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "poseidon_divine_relic", "category": "鳞衣 Scale"})
	assert(str(poseidon_armor_visual.get("ornament", "")) == "tidal_fins", "Poseidon scale armor selects tidal ornaments")
	var chronos_armor_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "chronos_divine_relic", "category": "神明专属神衣"})
	assert(str(chronos_armor_visual.get("ornament", "")) == "time_rings", "Chronos divine relic selects time-ring ornaments")
	var unknown_armor_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "unlisted_visual_item", "category": "unlisted"})
	assert(unknown_armor_visual.is_empty(), "unknown equipment does not invent a visual identity")
	var gold_cloth_count := 0
	for equipment_id in EquipmentDatabase.EQUIPMENT:
		var equipment_entry: Dictionary = EquipmentDatabase.EQUIPMENT[equipment_id]
		if str(equipment_entry.get("category", "")) == "黄金圣衣 Gold Cloth":
			gold_cloth_count += 1
	assert(gold_cloth_count == 12, "equipment archive contains all twelve zodiac Gold Cloths")
	var dark_cloth_count := 0
	var dark_cloth_classes: Dictionary = {}
	for equipment_id in EquipmentDatabase.EQUIPMENT:
		var dark_equipment_entry: Dictionary = EquipmentDatabase.EQUIPMENT[equipment_id]
		if str(dark_equipment_entry.get("category", "")) != "黑暗圣衣 Dark Cloth":
			continue
		dark_cloth_count += 1
		var dark_class_id := str(dark_equipment_entry.get("class_id", ""))
		assert(RPGState.CLASS_DATA.has(dark_class_id), "Dark Cloth maps to a playable profession: " + dark_class_id)
		assert(not dark_cloth_classes.has(dark_class_id), "each profession has one dedicated Dark Cloth: " + dark_class_id)
		dark_cloth_classes[dark_class_id] = true
		assert(str(dark_equipment_entry.get("required_chapter", "")) == "galaxy_wars", "Dark Cloth is tied to the Dark Saints story arc: " + dark_class_id)
		var dark_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": equipment_id, "class_id": dark_class_id, "category": "黑暗圣衣 Dark Cloth"})
		assert(str(dark_visual.get("ornament", "")) == "dark_aura" and dark_visual.has("shoulder_scale"), "Dark Cloth preserves class silhouette with dark aura: " + dark_class_id)
	assert(dark_cloth_count == RPGState.CLASS_DATA.size() and dark_cloth_count == 32, "all 32 playable professions have a dedicated Dark Cloth")
	assert(dark_cloth_classes.size() == RPGState.CLASS_DATA.size(), "Dark Cloth coverage has no missing playable profession")
	assert(EquipmentDatabase.EQUIPMENT.has("platinum_cloth_archive"), "Platinum Cloth is present in the equipment archive")
	var platinum_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "platinum_cloth_archive", "category": "白金圣衣 Platinum Cloth"})
	assert(str(platinum_visual.get("ornament", "")) == "radiant", "Platinum Cloth uses its own radiant visual identity")
	var zodiac_gold_ids := ["aries_gold_cloth", "taurus_gold_cloth", "gemini_gold_cloth", "cancer_gold_cloth", "leo_gold_cloth", "virgo_gold_cloth", "libra_gold_cloth", "scorpio_gold_cloth", "sagittarius_gold_cloth", "capricorn_gold_cloth", "aquarius_gold_cloth", "pisces_gold_cloth"]
	for zodiac_gold_id in zodiac_gold_ids:
		var zodiac_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": zodiac_gold_id, "category": "黄金圣衣 Gold Cloth"})
		assert(zodiac_visual.has("crest") and zodiac_visual.has("shoulder_scale"), zodiac_gold_id + " has a dedicated armor silhouette")
	var gold_cloth_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "aries_gold_cloth", "category": "黄金圣衣 Gold Cloth"})
	assert(str(gold_cloth_visual.get("ornament", "")) == "royal_wings", "Gold Cloth uses the royal armor visual family")
	var silver_cloth_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "silver_cloth_archive", "category": "白银圣衣 Silver Cloth"})
	assert(str(silver_cloth_visual.get("ornament", "")) == "feather", "Silver Cloth uses the silver armor visual family")
	var surplice_visual: Dictionary = visual_catalog_script.get_equipment_profile({"id": "surplice_general", "category": "冥衣 Surplice"})
	assert(str(surplice_visual.get("ornament", "")) == "soul_wings", "Surplice uses the underworld armor visual family")
	var skill_visual_script = preload("res://scripts/skill_visual_catalog.gd")
	var skill_visual_audit: Dictionary = skill_visual_script.validate_catalog()
	assert(bool(skill_visual_audit.get("valid", false)), "elemental skill VFX catalog is valid: " + str(skill_visual_audit.get("errors", [])))
	assert(int(skill_visual_audit.get("element_count", 0)) >= 10, "skill VFX covers all elemental families")
	var skill_visual_count := 0
	for visual_class in SkillSystem.get_class_skill_catalog():
		var visual_class_id := str(visual_class.get("id", ""))
		for visual_ability in SkillSystem.get_ability_catalog(visual_class_id):
			var ability_visual: Dictionary = skill_visual_script.get_profile(visual_class_id, visual_ability)
			assert(typeof(ability_visual.get("color")) == TYPE_COLOR, visual_class_id + " ability has a valid VFX color")
			assert(str(ability_visual.get("shape", "")).strip_edges() != "", visual_class_id + " ability has a visible VFX shape")
			assert(float(ability_visual.get("glow", -1.0)) >= 0.0 and float(ability_visual.get("glow", 1.0)) <= 0.6, visual_class_id + " ability VFX glow stays within mobile budget")
			assert(float(ability_visual.get("impact_scale", 0.0)) >= 0.5 and float(ability_visual.get("impact_scale", 2.0)) <= 1.5, visual_class_id + " ability impact scale is bounded")
			skill_visual_count += 1
	assert(skill_visual_count == 768, "all 768 abilities resolve a visual effect profile")
	var profiled_ability_count := 0
	var field_action_count := 0
	var trap_action_count := 0
	var homing_action_count := 0
	var ranged_action_count := 0
	for class_profile in SkillSystem.get_class_skill_catalog():
		var profile_class_id := str(class_profile.get("id", ""))
		for catalog_ability in SkillSystem.get_ability_catalog(profile_class_id):
			var combat_profile: Dictionary = SkillSystem.get_ability_effect_profile(catalog_ability)
			var combat_action := str(combat_profile.get("action", ""))
			assert(combat_action in ["strike", "summon", "field", "trap", "homing_projectile", "projectile", "multi_hit", "combo_strike", "pursuit", "throw", "heavy_strike"], profile_class_id + " ability resolves to a supported combat action")
			assert(str(combat_profile.get("action", "")).strip_edges() != "", profile_class_id + " ability has a normalized combat action")
			assert(int(combat_profile.get("extra_hits", -1)) >= 0 and int(combat_profile.get("extra_hits", 99)) <= 3, profile_class_id + " ability follow-up hit count is bounded")
			assert(float(combat_profile.get("extra_hit_ratio", -1.0)) >= 0.0 and float(combat_profile.get("extra_hit_ratio", 1.0)) <= 0.60, profile_class_id + " ability follow-up damage is bounded")
			match str(combat_profile.get("action", "")):
				"field":
					field_action_count += 1
				"trap":
					trap_action_count += 1
				"homing_projectile":
					homing_action_count += 1
				"projectile":
					ranged_action_count += 1
			profiled_ability_count += 1
	assert(profiled_ability_count == 768, "all 768 abilities resolve to a combat profile")
	assert(field_action_count > 0 and trap_action_count > 0 and homing_action_count > 0 and ranged_action_count > 0, "catalog includes real field, trap, ranged and homing actions")
	assert(SkillSystem.is_valid_class_ability("pegasus", "pegasus_skill_1"), "a registered class ability resolves for its owning class")
	assert(not SkillSystem.is_valid_class_ability("dragon", "pegasus_skill_1"), "a class cannot resolve another class's ability")
	assert(not SkillSystem.is_valid_class_ability("unknown_class", "pegasus_skill_1"), "unknown classes cannot resolve registered abilities")
	assert(not SkillSystem.is_valid_class_ability("pegasus", ""), "empty ability ids are rejected")
	assert(SkillSystem.is_ability_available_for_cast("pegasus", "pegasus_skill_1"), "the starter ability remains available for casting")
	assert(not SkillSystem.is_ability_available_for_cast("pegasus", "pegasus_skill_2"), "unlearned abilities cannot enter the cast pipeline")
	assert(SkillSystem.get_ability_effect_profile({}).is_empty(), "empty ability data cannot fall through to a default strike")
	var multi_hit_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "多段"})
	assert(str(multi_hit_profile.get("action", "")) == "multi_hit" and int(multi_hit_profile.get("extra_hits", 0)) == 2, "multi-hit skills resolve two follow-up strikes")
	var pursuit_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "追击"})
	assert(float(pursuit_profile.get("controlled_bonus", 0.0)) > 0.0, "pursuit skills gain damage against controlled targets")
	var finisher_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "终结"})
	assert(float(finisher_profile.get("execute_threshold", 0.0)) == 0.30 and float(finisher_profile.get("execute_bonus", 0.0)) > 0.0, "finishers gain a bounded low-health execution bonus")
	var throw_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "投技"})
	assert(str(throw_profile.get("action", "")) == "throw" and float(throw_profile.get("stagger_bonus", 0.0)) > 0.0, "throw skills resolve a dedicated hit reaction")
	var summon_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "召唤"})
	assert(str(summon_profile.get("action", "")) == "summon", "summon skills resolve an autonomous combat actor")
	assert(float(summon_profile.get("summon_lifetime", 0.0)) >= 5.0 and float(summon_profile.get("summon_damage_ratio", 0.0)) > 0.0, "summon duration and damage are configured")
	assert(load("res://scripts/skill_summon.gd") != null, "offline summon actor script is present")
	var field_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "领域"})
	assert(str(field_profile.get("action", "")) == "field" and float(field_profile.get("field_lifetime", 0.0)) >= 4.0, "area skills create persistent damage fields")
	assert(float(field_profile.get("field_radius", 0.0)) >= 3.0 and float(field_profile.get("field_tick_interval", 0.0)) > 0.0, "field radius and tick cadence are configured")
	var trap_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "陷阱"})
	assert(str(trap_profile.get("action", "")) == "trap" and float(trap_profile.get("field_lifetime", 0.0)) >= 8.0, "trap skills create timed trigger actors")
	var homing_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "追踪"})
	assert(str(homing_profile.get("action", "")) == "homing_projectile" and float(homing_profile.get("projectile_damage_ratio", 0.0)) > 0.0, "tracking skills create homing projectiles")
	var ranged_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "远程"})
	assert(str(ranged_profile.get("action", "")) == "projectile" and float(ranged_profile.get("projectile_speed", 0.0)) > 0.0, "ranged skills create straight projectiles")
	var sustained_profile: Dictionary = SkillSystem.get_ability_effect_profile({"type": "持续"})
	assert(str(sustained_profile.get("action", "")) == "field" and float(sustained_profile.get("field_lifetime", 0.0)) >= 3.0, "sustained skills create timed field actors")
	assert(load("res://scripts/skill_field.gd") != null, "field and trap actor script is present")
	assert(load("res://scripts/skill_projectile.gd") != null, "homing projectile actor script is present")
	assert(is_equal_approx(SkillSystem.get_passive_speed_multiplier("tenkishi"), 1.22), "Tenkishi flight profession retains its movement passive")
	assert(SkillSystem.uses_delayed_actor_delivery({"type": "召唤"}), "summon skills apply target effects through their summoned actor")
	assert(SkillSystem.uses_delayed_actor_delivery({"type": "领域"}), "field skills apply damage and control on field ticks, not at cast time")
	assert(SkillSystem.uses_delayed_actor_delivery({"type": "陷阱"}), "trap skills apply effects only when triggered")
	assert(SkillSystem.uses_delayed_actor_delivery({"type": "追踪"}), "homing skills apply effects only on projectile impact")
	assert(SkillSystem.uses_delayed_actor_delivery({"type": "远程"}), "ranged skills apply effects only on projectile impact")
	assert(not SkillSystem.uses_delayed_actor_delivery({"type": "多段"}), "instant multi-hit skills retain immediate hit resolution")
	assert(not SkillSystem.uses_delayed_actor_delivery({"type": "投技"}), "instant throw skills retain immediate hit resolution")
	var grounded_aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile("tenkishi", false)
	assert(is_equal_approx(float(grounded_aerial_profile.get("damage_multiplier", 0.0)), 1.0), "grounded Tenkishi combat receives no aerial bonus")
	var active_aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile("tenkishi", true)
	assert(float(active_aerial_profile.get("damage_multiplier", 1.0)) > 1.0 and float(active_aerial_profile.get("range_bonus", 0.0)) > 0.0 and float(active_aerial_profile.get("launch_bonus", 0.0)) > 0.0, "Tenkishi flight enables bounded aerial combat bonuses")
	var other_class_aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile("pegasus", true)
	assert(is_equal_approx(float(other_class_aerial_profile.get("damage_multiplier", 0.0)), 1.0), "non-Tenkishi classes cannot receive aerial combat bonuses")
	var divine_signature_effects: Dictionary = {}
	var divine_signature_count := 0
	for divine_class in SkillSystem.get_class_skill_catalog():
		if str(divine_class.get("tier", "")) != "神明":
			continue
		var signature_id := str(divine_class.get("id", ""))
		var signature_profile: Dictionary = SkillSystem.get_divine_signature_profile(signature_id)
		var signature_effect := str(signature_profile.get("effect", ""))
		assert(not signature_effect.is_empty() and not divine_signature_effects.has(signature_effect), signature_id + " has a distinct divine signature effect")
		assert(not str(signature_profile.get("mark", "")).is_empty() and not str(signature_profile.get("status", "")).is_empty(), signature_id + " divine signature defines mark and status")
		assert(float(signature_profile.get("damage_ratio", -1.0)) >= 0.0 and float(signature_profile.get("damage_ratio", 1.0)) <= 0.20, signature_id + " divine signature direct damage is bounded")
		assert(float(signature_profile.get("execute_ratio", -1.0)) >= 0.0 and float(signature_profile.get("execute_ratio", 1.0)) <= 0.20, signature_id + " divine execute damage is bounded")
		divine_signature_effects[signature_effect] = true
		divine_signature_count += 1
	assert(divine_signature_count == 22 and divine_signature_effects.size() == 22, "all 22 divine professions have distinct signature combat effects")
	var divine_support_count := 0
	for class_profile in SkillSystem.get_class_skill_catalog():
		if str(class_profile.get("tier", "")) != "神明":
			continue
		var divine_id := str(class_profile.get("id", ""))
		var support_profile: Dictionary = SkillSystem.get_divine_support_profile(divine_id)
		assert(not support_profile.is_empty(), divine_id + " divine support profile exists")
		assert(float(support_profile.get("damage_bonus", -1.0)) >= 0.0 and float(support_profile.get("damage_bonus", 1.0)) <= 0.25, divine_id + " support damage buff is bounded")
		assert(float(support_profile.get("damage_reduction", -1.0)) >= 0.0 and float(support_profile.get("damage_reduction", 1.0)) <= 0.20, divine_id + " support mitigation is bounded")
		assert(float(support_profile.get("heal_ratio", -1.0)) >= 0.0 and float(support_profile.get("heal_ratio", 1.0)) <= 0.20, divine_id + " support healing is bounded")
		assert(float(support_profile.get("shield_ratio", -1.0)) >= 0.0 and float(support_profile.get("shield_ratio", 1.0)) <= 0.25, divine_id + " support shield is bounded")
		divine_support_count += 1
	assert(divine_support_count == 22, "all 22 divine professions have a tested support combat profile")
	assert(is_equal_approx(SkillSystem.get_passive_guard_ratio("andromeda"), 0.12), "Andromeda passive emergency guard ratio is defined")
	assert(is_equal_approx(SkillSystem.get_passive_guard_ratio("pegasus"), 0.0), "non-Andromeda classes do not receive the emergency guard")
	assert(is_equal_approx(SkillSystem.get_passive_burn_multiplier("phoenix"), 1.12), "Phoenix passive amplifies burn ticks")
	assert(is_equal_approx(SkillSystem.get_passive_burn_sustain_ratio("phoenix"), 0.04), "Phoenix passive restores a small amount of health from burn ticks")
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("phoenix"), 1.1), "Phoenix passive increases its direct skill damage")
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("tenmou"), 1.12), "Specter warrior passive increases direct damage")
	assert(is_equal_approx(SkillSystem.get_combo_damage_multiplier("pegasus"), 1.08), "Pegasus passive is scoped to combo finishers")
	assert(is_equal_approx(SkillSystem.get_passive_stagger_multiplier("lyra"), 1.15), "Lyra passive increases hit-reaction stagger")
	assert(is_equal_approx(SkillSystem.get_passive_speed_multiplier("sea_swallow"), 1.12), "Sea Swallow passive affects player movement speed")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("dragon", 1.0), 0.12), "Dragon Shield reduces frontal incoming damage")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("dragon", 0.0), 0.0), "Dragon Shield does not reduce rear or flank attacks")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("andromeda", 0.0), 0.08), "Andromeda passive guard remains omnidirectional")
	for class_id in ["pegasus", "dragon", "apollo", "athena", "hades", "poseidon", "zeus", "tenkishi"]:
		for ability in SkillSystem.get_ability_catalog(class_id):
			assert(not str(ability.get("branch", "")).is_empty(), class_id + " skill branch is normalized")
	assert(SkillSystem.is_support_ability({"type": "护盾", "role": "防御"}), "shield abilities are classified as support")
	assert(SkillSystem.is_support_ability({"type": "治疗", "role": "恢复"}), "healing abilities are classified as support")
	assert(SkillSystem.is_support_ability({"type": "回能", "role": "资源"}), "resource abilities are classified as support")
	assert(SkillSystem.is_support_ability({"type": "闪避", "role": "生存"}), "evasion abilities are classified as support")
	assert(not SkillSystem.is_support_ability({"type": "爆发", "role": "单体"}), "damage abilities remain offensive")

	assert(is_equal_approx(SkillSystem.get_target_condition_multiplier("pegasus", test_boss), 1.0), "unconditional passives are not applied twice per target")
	assert(is_equal_approx(SkillSystem.get_passive_stagger_multiplier("lyra"), 1.15), "Lyra stagger passive affects hit reactions")
	assert(is_equal_approx(SkillSystem.get_passive_speed_multiplier("sea_swallow"), 1.12), "Sea Swallow speed passive affects movement")
	assert(is_equal_approx(SkillSystem.get_position_damage_multiplier("sea_dragon", 0.0, false), 1.1), "Sea Dragon gains its full flank and rear attack bonus against normal enemies")
	assert(is_equal_approx(SkillSystem.get_position_damage_multiplier("sea_dragon", -1.0, true), 1.05), "Sea Dragon positional bonus is reduced against bosses")
	assert(is_equal_approx(SkillSystem.get_position_damage_multiplier("sea_dragon", 0.8, false), 1.0), "Sea Dragon receives no positional bonus when striking the front")
	assert(is_equal_approx(SkillSystem.get_position_damage_multiplier("pegasus", 0.0, false), 1.0), "Other classes do not receive Sea Dragon positional bonus")
	var clash_test_boss = preload("res://scripts/enemy.gd").new()
	clash_test_boss.is_boss = true
	clash_test_boss.max_health = 1000.0
	clash_test_boss.state = 1
	clash_test_boss._boss_heavy_attack = true
	assert(clash_test_boss.is_ultimate_telegraph_active(), "boss heavy windup exposes an ultimate clash window")
	assert(clash_test_boss.resolve_ultimate_clash(1000.0), "sufficient player power wins the boss ultimate clash")
	assert(clash_test_boss.state == 2 and not clash_test_boss._boss_heavy_attack, "winning the clash interrupts the boss ultimate into recovery")
	clash_test_boss.free()
	var guard_test_boss = preload("res://scripts/enemy.gd").new()
	guard_test_boss.is_boss = true
	guard_test_boss.state = 3
	assert(is_equal_approx(guard_test_boss.get_boss_guard_damage_multiplier(), 0.42), "boss guard stance reduces incoming damage by 58 percent")
	guard_test_boss.state = 0
	assert(is_equal_approx(guard_test_boss.get_boss_guard_damage_multiplier(), 1.0), "boss receives normal damage outside guard stance")
	guard_test_boss.free()
	var weakpoint_test_boss = preload("res://scripts/enemy.gd").new()
	weakpoint_test_boss.is_boss = true
	assert(is_equal_approx(weakpoint_test_boss.get_boss_weakpoint_multiplier(Vector3(0.0, 0.0, 3.0)), 1.22), "boss rear weakpoint grants 22% precision damage")
	assert(is_equal_approx(weakpoint_test_boss.get_boss_weakpoint_multiplier(Vector3(3.0, 0.0, 0.0)), 1.08), "boss flank weakpoint grants 8% precision damage")
	assert(is_equal_approx(weakpoint_test_boss.get_boss_weakpoint_multiplier(Vector3(0.0, 0.0, -3.0)), 1.0), "boss front armor does not grant weakpoint bonus")
	var armor_test_boss = preload("res://scripts/enemy.gd").new()
	armor_test_boss.is_boss = true
	armor_test_boss.max_health = 1000.0
	var armor_test_node := MeshInstance3D.new()
	armor_test_boss._register_boss_armor_node(armor_test_node, "helmet")
	var armor_hit_one: Dictionary = armor_test_boss.damage_boss_armor(1000.0)
	assert(str(armor_hit_one.get("zone", "")) == "helmet" and float(armor_hit_one.get("integrity", 1.0)) < 1.0, "boss armor integrity decreases by named zone")
	armor_test_boss.damage_boss_armor(1000.0)
	var armor_hit_three: Dictionary = armor_test_boss.damage_boss_armor(1000.0)
	assert(bool(armor_hit_three.get("broken", false)) and not armor_test_node.visible, "depleted boss armor zone visibly breaks away")
	armor_test_boss.free()
	weakpoint_test_boss.boss_break_active = true
	assert(is_equal_approx(weakpoint_test_boss.get_boss_weakpoint_multiplier(Vector3(0.0, 0.0, 3.0)), 1.0), "break vulnerability does not stack with positional weakpoint damage")
	weakpoint_test_boss.free()
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("sea_dragon"), 1.0), "Sea Dragon positional passive is not double-counted as permanent damage")
	for class_profile in SkillSystem.get_class_skill_catalog():
		var audited_class_id := str(class_profile.get("id", ""))
		assert(not audited_class_id.is_empty(), "every class has a stable combat profile id")
		assert(is_finite(SkillSystem.get_skill_damage_multiplier(audited_class_id)), audited_class_id + " passive damage multiplier is finite")
		assert(is_finite(SkillSystem.get_damage_reduction(audited_class_id)), audited_class_id + " passive damage reduction is finite")
		assert(is_finite(SkillSystem.get_passive_speed_multiplier(audited_class_id)), audited_class_id + " passive movement multiplier is finite")
		assert(is_finite(SkillSystem.get_passive_stagger_multiplier(audited_class_id)), audited_class_id + " passive stagger multiplier is finite")
	assert(is_equal_approx(SkillSystem.get_passive_stagger_multiplier("pegasus"), 1.0), "classes without stagger passives keep neutral stagger")
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("pegasus"), 1.0), "combo-only passive does not increase basic or ordinary skill damage")
	var saved_armor_state: Dictionary = RPGState.profile.get("armor_state", {}).duplicate(true)
	var saved_armor_currency := int(RPGState.profile.get("currency", 0))
	RPGState.profile["currency"] = 1000
	RPGState.profile["armor_state"] = {"unlocked_stages":["bronze"],"current_stage":"bronze","durability":{"head":65,"chest":100,"arms":100,"waist":100,"legs":100},"levels":{},"awakened":false}
	var helmet_repair_quote: Dictionary = ArmorSystem.get_repair_quote("head")
	assert(int(helmet_repair_quote.get("missing_durability", 0)) == 35 and int(helmet_repair_quote.get("currency_cost", 0)) == 70, "individual armor repair quote scales with missing durability")
	assert(bool(helmet_repair_quote.get("can_repair", false)), "individual armor repair quote checks available currency")
	var helmet_repair_result: Dictionary = ArmorSystem.repair_part("head")
	assert(bool(helmet_repair_result.get("repaired", false)) and int(helmet_repair_result.get("after", 0)) == 100, "individual armor repair restores only the selected piece")
	assert(int(RPGState.profile.get("currency", 0)) == 930 and ArmorSystem.get_part_durability("chest") == 100, "individual armor repair charges the quoted cost without damaging other pieces")
	var player_script = preload("res://scripts/player.gd")
	var head_contact: Vector3 = player_script.get_capsule_contact_point_local(Vector3(0.0, 3.0, 0.0))
	var leg_contact: Vector3 = player_script.get_capsule_contact_point_local(Vector3(0.0, -1.0, 0.0))
	var arm_contact: Vector3 = player_script.get_capsule_contact_point_local(Vector3(2.0, 1.1, 0.0))
	var waist_contact: Vector3 = player_script.get_capsule_contact_point_local(Vector3(0.0, 0.7, -2.0))
	var chest_contact: Vector3 = player_script.get_capsule_contact_point_local(Vector3(0.0, 1.2, -2.0))
	assert(is_equal_approx(head_contact.distance_to(Vector3(0.0, 1.37, 0.0)), 0.43), "head-side contact lies on the capsule surface")
	assert(player_script.get_armor_hit_zone_from_local_position(head_contact) == "head", "upper capsule contact is classified as a helmet hit")
	assert(player_script.get_armor_hit_zone_from_local_position(leg_contact) == "legs", "low capsule contact is classified as a leg hit")
	assert(player_script.get_armor_hit_zone_from_local_position(arm_contact) == "arms", "side capsule contact is classified as an arm hit")
	assert(player_script.get_armor_hit_zone_from_local_position(waist_contact) == "waist", "mid-low capsule contact is classified as a waist hit")
	assert(player_script.get_armor_hit_zone_from_local_position(chest_contact) == "chest", "center capsule contact is classified as a chest hit")
	assert(is_equal_approx(ArmorSystem.get_damage_reduction("head"), 0.08), "intact helmet applies its dedicated eight-percent hit-zone protection")
	assert(is_equal_approx(ArmorSystem.get_damage_reduction("chest"), 0.10), "intact chest plate applies its dedicated ten-percent hit-zone protection")
	RPGState.profile["armor_state"]["durability"]["head"] = 50
	assert(is_equal_approx(ArmorSystem.get_damage_reduction("head"), 0.04), "helmet protection falls proportionally as its durability drops")
	RPGState.profile["armor_state"]["durability"]["head"] = 0
	assert(is_equal_approx(ArmorSystem.get_damage_reduction("head"), 0.0), "a broken helmet no longer protects the head hit zone")
	RPGState.profile["armor_state"]["durability"]["head"] = 100
	ArmorSystem.damage_ticks = 0
	for wear_tick in range(4):
		assert(not bool(ArmorSystem.damage_hit_part("head", 4).get("changed", false)), "targeted armor wear waits for the five-hit interval")
	var targeted_wear: Dictionary = ArmorSystem.damage_hit_part("head", 4)
	assert(bool(targeted_wear.get("changed", false)) and int(targeted_wear.get("after", 100)) == 96, "the fifth targeted hit wears the struck armor part rather than a random piece")
	RPGState.profile["armor_state"]["durability"]["head"] = 100
	RPGState.profile["currency"] = saved_armor_currency
	RPGState.profile["armor_state"] = saved_armor_state.duplicate(true)
	RPGState.profile["armor_state"] = {"unlocked_stages":["bronze","dark_cloth"],"current_stage":"dark_cloth","durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100},"levels":{},"awakened":false}
	var dark_armor_bonus: Dictionary = ArmorSystem.get_bonus_stats()
	var dark_palette: Dictionary = CharacterVisualCatalog.get_stage_palette("dark_cloth", false)
	var dark_awakened_palette: Dictionary = CharacterVisualCatalog.get_stage_palette("dark_cloth", true)
	assert(dark_palette.get("metal", Color.WHITE).get_luminance() < 0.08, "Dark Cloth keeps its near-black armor identity")
	assert(float(dark_awakened_palette.get("glow", 0.0)) > float(dark_palette.get("glow", 0.0)), "Dark Cloth awakening intensifies its purple aura palette")
	assert(is_equal_approx(float(dark_armor_bonus.get("dark_resonance", 1.0)), 1.10), "Dark Cloth grants a ten-percent skill resonance to every profession")
	assert(int(dark_armor_bonus.get("dark_set_tier", 0)) == 2, "five intact Dark Cloth pieces activate the complete set bonus")
	var dark_passive_names: Dictionary = {}
	for dark_class_profile in SkillSystem.get_class_skill_catalog():
		var dark_class_id := str(dark_class_profile.get("id", ""))
		var dark_passive: Dictionary = ArmorSystem.get_dark_class_passive(dark_class_id)
		assert(not dark_passive.is_empty(), "every profession has a dedicated Dark Cloth passive: " + dark_class_id)
		var dark_passive_name := str(dark_passive.get("name", ""))
		assert(not dark_passive_name.is_empty() and not dark_passive_names.has(dark_passive_name), "Dark Cloth passive names are unique across professions")
		dark_passive_names[dark_passive_name] = true
	assert(dark_passive_names.size() == 32, "all 32 registered classes have individually named Dark Cloth passives")
	assert(str(dark_armor_bonus.get("dark_class_passive", {}).get("name", "")) == ArmorSystem.get_dark_class_passive("pegasus").get("name", ""), "equipped Dark Cloth exposes the selected class specialization")
	var damaged_dark_state: Dictionary = RPGState.profile["armor_state"].duplicate(true)
	damaged_dark_state["durability"]["legs"] = 0
	RPGState.profile["armor_state"] = damaged_dark_state
	assert(int(ArmorSystem.get_bonus_stats().get("dark_set_tier", 0)) == 1, "three or four intact Dark Cloth pieces retain the partial set bonus")
	RPGState.profile["armor_state"] = { "unlocked_stages":["bronze","dark_cloth"], "current_stage":"dark_cloth", "durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100}, "levels":{}, "awakened":false }
	assert(float(dark_armor_bonus.get("max_cosmos", 0.0)) > 0.0 and float(dark_armor_bonus.get("speed", 0.0)) > 0.0, "Dark Cloth adds Cosmos capacity and movement speed")
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("phoenix"), 1.21), "Dark Cloth resonance stacks multiplicatively with the Phoenix skill passive")
	var awakened_dark_state: Dictionary = RPGState.profile["armor_state"].duplicate(true)
	awakened_dark_state["awakened"] = true
	RPGState.profile["armor_state"] = awakened_dark_state
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("phoenix"), 1.265), "awakened Dark Cloth raises skill resonance to fifteen percent")
	RPGState.profile["armor_state"] = {"unlocked_stages":["bronze","platinum"],"current_stage":"platinum","durability":{"head":100,"chest":100,"arms":100,"waist":100,"legs":100},"levels":{},"awakened":false}
	var platinum_base_bonus: Dictionary = ArmorSystem.get_bonus_stats()
	var platinum_palette: Dictionary = CharacterVisualCatalog.get_stage_palette("platinum", false)
	var platinum_awakened_palette: Dictionary = CharacterVisualCatalog.get_stage_palette("platinum", true)
	assert(float(platinum_palette.get("metallic", 0.0)) >= 0.98, "Platinum Cloth uses a high-metallic silver alloy finish")
	assert(float(platinum_awakened_palette.get("glow", 0.0)) > float(platinum_palette.get("glow", 0.0)), "Platinum awakening intensifies its star halo palette")
	assert(is_equal_approx(float(platinum_base_bonus.get("platinum_star_resonance", 0.0)), 1.12), "Platinum Cloth has its own star-radiance skill multiplier")
	var platinum_passive_names: Dictionary = {}
	for platinum_class_profile in SkillSystem.get_class_skill_catalog():
		var platinum_class_id := str(platinum_class_profile.get("id", ""))
		var platinum_passive: Dictionary = ArmorSystem.get_platinum_class_passive(platinum_class_id)
		assert(not platinum_passive.is_empty(), "every profession has a dedicated Platinum Cloth passive: " + platinum_class_id)
		var platinum_passive_name := str(platinum_passive.get("name", ""))
		assert(not platinum_passive_name.is_empty() and not platinum_passive_names.has(platinum_passive_name), "Platinum Cloth passive names are unique across professions")
		platinum_passive_names[platinum_passive_name] = true
	assert(platinum_passive_names.size() == 32, "all 32 registered classes have individually named Platinum Cloth passives")
	assert(str(platinum_base_bonus.get("platinum_class_passive", {}).get("name", "")) == ArmorSystem.get_platinum_class_passive("pegasus").get("name", ""), "equipped Platinum Cloth exposes the selected class specialization")
	assert(float(platinum_base_bonus.get("speed", 0.0)) > 0.0, "Platinum Cloth class specialization can grant its distinct mobility bonus")
	assert(float(platinum_base_bonus.get("max_cosmos", 0.0)) > 0.0, "Platinum Cloth grants star-radiance Cosmos capacity")
	RPGState.profile["armor_state"]["awakened"] = true
	var platinum_awakened_bonus: Dictionary = ArmorSystem.get_bonus_stats()
	assert(is_equal_approx(float(platinum_awakened_bonus.get("platinum_star_resonance", 0.0)), 1.18), "Platinum awakening strengthens its own star-radiance multiplier")
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("phoenix"), 1.298), "Platinum awakening independently strengthens profession skill damage through star radiance")
	RPGState.profile["armor_state"] = saved_armor_state
	assert(is_equal_approx(SkillSystem.get_skill_damage_multiplier("phoenix"), 1.1), "removing Dark Cloth restores the class skill multiplier")
	assert(is_equal_approx(SkillSystem.get_combo_damage_multiplier("pegasus"), 1.08), "Pegasus combo passive applies to combo finishers")
	assert(is_equal_approx(SkillSystem.get_combo_damage_multiplier("dragon"), 1.0), "classes without combo passive keep neutral combo damage")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("dragon"), 0.12), "Dragon defensive passive exposes its damage reduction")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("pegasus"), 0.0), "classes without defensive passive have no passive damage reduction")
	assert(is_equal_approx(SkillSystem.get_passive_speed_multiplier("tenkishi"), 1.22), "Heavenly Warrior wing mobility increases movement speed")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("tenkishi"), 0.14), "Heavenly Warrior celestial armor reduces incoming damage")

	test_boss.apply_hit_reaction(Vector3.RIGHT, 10.0, 4.0, 0.8)
	assert(float(test_boss.boss_control_resist_timer) > 0.0, "repeated control builds boss poise resistance")
	test_boss.boss_break_active = false
	test_boss.boss_break_getup_timer = 0.0
	var boss_health_before_mark := float(test_boss.health)
	test_boss.divine_mark = "soul"
	assert(is_equal_approx(float(test_boss.get_divine_mark_lifesteal_ratio()), 0.025), "Hades soul marks grant a small life-steal effect")
	test_boss.divine_mark = "death"
	assert(is_equal_approx(float(test_boss.get_divine_mark_lifesteal_ratio()), 0.025), "Thanatos death marks grant a small life-steal effect")
	test_boss.divine_mark = "tidal"
	assert(is_equal_approx(float(test_boss.get_divine_mark_knockback_multiplier()), 1.35), "Poseidon tidal marks increase knockback")
	test_boss.divine_mark = "storm"
	assert(is_equal_approx(float(test_boss.get_divine_mark_knockback_multiplier()), 1.15), "storm marks add a lighter knockback bonus")
	test_boss.divine_mark = "solar"
	test_boss.apply_divine_mark("solar", 6.0, 0.12)
	assert(str(test_boss.divine_mark) == "solar", "divine mark identity is retained")
	assert(float(test_boss.divine_mark_timer) < 6.0, "boss divine mark duration is resisted")
	assert(float(test_boss.divine_mark_power) <= 0.066, "boss divine mark damage amplification is resisted")
	test_boss.take_damage(10.0)
	assert(is_equal_approx(boss_health_before_mark - float(test_boss.health), 10.66), "divine mark amplifies incoming damage within boss resistance cap")
	test_boss.queue_free()
	var asgard_chapter: Dictionary = CampaignDatabase.get_chapter("asgard")
	var poseidon_chapter: Dictionary = CampaignDatabase.get_chapter("poseidon")
	assert(asgard_chapter.get("missions", []).size() == 8, "anime Asgard arc is inserted before Poseidon")
	assert(poseidon_chapter.get("missions", []).size() == 10, "Poseidon arc contains Athena rescue, seven generals, pillars and final battle")
	assert(int(asgard_chapter.get("order", 0)) < int(poseidon_chapter.get("order", 0)), "Asgard precedes Poseidon in anime chronology")
	var hades_chapter: Dictionary = CampaignDatabase.get_chapter("hades")
	var heaven_chapter: Dictionary = CampaignDatabase.get_chapter("heaven")
	var original_chapter: Dictionary = CampaignDatabase.get_chapter("original_final")
	assert(str(CampaignDatabase.get_chapter_for_mission("ha_007").get("id", "")) == "hades", "Hades mission resolves to its correct world chapter")
	assert(str(CampaignDatabase.get_chapter_for_mission("he_007").get("id", "")) == "heaven", "Heaven mission resolves to its correct world chapter")
	assert(int(poseidon_chapter.get("order", 0)) < int(hades_chapter.get("order", 0)), "Hades follows Poseidon in story chronology")
	assert(int(hades_chapter.get("order", 0)) < int(heaven_chapter.get("order", 0)) and int(heaven_chapter.get("order", 0)) < int(original_chapter.get("order", 0)), "Heaven and original finale follow Hades in order")
	assert(hades_chapter.get("missions", []).size() >= 7 and heaven_chapter.get("missions", []).size() >= 7 and original_chapter.get("missions", []).size() >= 5, "Hades, Heaven and original finale have complete mission arcs")
	for mission_id in ["ha_003", "ha_006", "ha_007", "he_002", "he_004", "he_005", "he_006", "he_007", "of_002", "of_004", "of_005"]:
		assert(not CampaignDatabase.get_mission(mission_id).get("encounter", {}).get("waves", []).is_empty(), "late story boss encounter is configured: " + mission_id)
	for archetype_id in ["hades_specter", "hades_wraith", "judge_griffin", "judge_garuda", "judge_wyvern", "cocytus_guard", "wailing_wall_guard", "hypnos_guardian", "thanatos_reaper", "hades_emperor", "heaven_gatekeeper", "heavenly_angel", "heavenly_warden", "celestial_trial", "apollo_trial", "zeus_trial", "cosmos_warden", "divine_echo", "primordial_void", "universe_arbiter"]:
		assert(EnemyDatabase.has_archetype(archetype_id), "late campaign enemy archetype exists: " + archetype_id)
	var enemy_visual_test_root := Node3D.new()
	add_child(enemy_visual_test_root)
	var boss_visual_test = preload("res://scripts/enemy.gd").new()
	boss_visual_test.game = enemy_visual_test_root
	boss_visual_test.archetype_id = "hades_emperor"
	enemy_visual_test_root.add_child(boss_visual_test)
	assert(bool(boss_visual_test.is_boss) and str(boss_visual_test.display_name) == "冥王哈迪斯", "Hades boss archetype initializes its combat identity")
	assert(is_instance_valid(boss_visual_test.enemy_visual_root) and boss_visual_test.enemy_visual_root.get_child_count() >= 10 and is_instance_valid(boss_visual_test.telegraph_mesh), "boss enemy builds armor, crown, aura and combat telegraph visuals")
	assert(boss_visual_test.enemy_arm_nodes.size() == 2 and boss_visual_test.enemy_leg_nodes.size() == 2, "boss enemy has animated arm and leg meshes")
	enemy_visual_test_root.queue_free()
	var campaign_order_ids: Dictionary = {}
	for chapter_entry in CampaignDatabase.get_chapters():
		var chapter_order := int(chapter_entry.get("order", 0))
		assert(chapter_order > 0 and not campaign_order_ids.has(chapter_order), "campaign chapter order is positive and unique")
		campaign_order_ids[chapter_order] = true
		for campaign_mission_entry in chapter_entry.get("missions", []):
			for campaign_wave in campaign_mission_entry.get("encounter", {}).get("waves", []):
				for campaign_spawn in campaign_wave.get("spawns", []):
					var campaign_archetype := str(campaign_spawn.get("archetype_id", ""))
					assert(EnemyDatabase.has_archetype(campaign_archetype), "campaign spawn resolves to an offline enemy archetype: " + campaign_archetype)
	for archetype_id in ["god_warrior_thor", "god_warrior_fenrir", "god_warrior_hagen", "god_warrior_mime", "god_warrior_alberich", "god_warrior_syd", "god_warrior_bud", "god_warrior_siegfried", "mariner_baian", "mariner_io", "mariner_krishna", "mariner_kasa", "mariner_isaac", "mariner_sorrento", "mariner_kanon", "poseidon_emperor"]:
		assert(EnemyDatabase.has_archetype(archetype_id), "Asgard/Poseidon boss archetype: " + archetype_id)
	for mission_id in ["po_002", "po_003", "po_004", "po_005", "po_006", "po_007", "po_008", "po_010"]:
		assert(not CampaignDatabase.get_mission(mission_id).get("encounter", {}).get("waves", []).is_empty(), "Poseidon boss mission encounter: " + mission_id)
	assert(str(CampaignDatabase.get_mission("po_010").get("encounter", {}).get("waves", [])[0].get("spawns", [])[0].get("archetype_id", "")) == "poseidon_emperor", "Poseidon final encounter configured")
	assert(CampaignDatabase.get_mission("po_009").get("objectives", [])[0].get("target", 0) == 7, "seven pillar story objective")
	var taurus_mission: Dictionary = CampaignDatabase.get_mission("s12_003")
	assert(not taurus_mission.get("encounter", {}).get("waves", []).is_empty(), "Taurus story mission has a data-driven encounter")
	assert(str(taurus_mission["encounter"]["waves"][0]["spawns"][0]["archetype_id"]) == "gold_taurus", "Taurus encounter resolves its configured archetype")
	assert(CampaignDatabase.get_mission("s12_002").get("encounter", {}).is_empty(), "Mu story mission remains interaction-only")
	assert(not CampaignManager.accept_mission("gw_002"), "cannot skip the first story mission")
	assert(CampaignManager.accept_mission(first_mission_id), "save campaign progress to character slot")
	assert(RPGState.create_new_slot(2), "create second isolated character slot")
	assert(str(RPGState.profile.get("character_name", "")) == "星之战士", "new character profile includes a default display name")
	assert(str(RPGState.get_slot_summary(2).get("character_name", "")) == "星之战士", "save slot summary exposes the character display name")
	assert(RPGState.select_class("dragon"), "new character can select a basic starter profession")
	assert(str(RPGState.profile.get("class_id", "")) == "dragon" and str(RPGState.profile.get("character_name", "")) == "星之战士", "starter class selection preserves character name")
	var character_menu_test = preload("res://scripts/main_menu.gd").new()
	add_child(character_menu_test)
	assert(character_menu_test.character_class_picker.item_count == 9, "new character wizard offers exactly nine starter professions")
	character_menu_test.queue_free()
	assert(QuestManager.status == "not_started", "quest state isolated on new slot")
	assert(str(CampaignManager.progress.get("active_mission", "")) == first_mission_id, "campaign defaults on new slot")
	assert(not RPGState.save_slot(3), "cannot overwrite a different occupied save slot")
	assert(RPGState.active_slot == 2, "failed cross-slot save does not switch active slot")
	assert(RPGState.load_slot(3), "switch back to first character slot")
	assert(QuestManager.status == "active" and QuestManager.defeated_normal == 1, "restore quest progress from selected slot")
	assert(str(CampaignManager.progress.get("active_mission", "")) == first_mission_id, "restore campaign progress from selected slot")
	assert(RPGState.load_slot(2), "load isolated slot for tutorial reward test")
	CampaignManager.progress["unlocked_chapters"] = ["galaxy_wars", "sanctuary_twelve_houses", "asgard", "poseidon", "hades"]
	var prior_campaign_missions: Array[String] = []
	var found_hades_judges := false
	for chapter_entry in CampaignDatabase.get_chapters():
		for mission_entry in chapter_entry.get("missions", []):
			var prior_mission_id := str(mission_entry.get("id", ""))
			if prior_mission_id == "ha_003":
				found_hades_judges = true
				break
			prior_campaign_missions.append(prior_mission_id)
		if found_hades_judges:
			break
	CampaignManager.progress["completed_missions"] = prior_campaign_missions.duplicate()
	CampaignManager.progress["claimed_rewards"] = prior_campaign_missions.duplicate()
	CampaignManager.progress["active_mission"] = "ha_003"
	CampaignManager.progress["objective_counts"] = {}
	assert(CampaignManager._save(), "prepare Hades three-judge encounter mission")
	assert(CampaignManager.add_objective_progress("defeat_three_judges", 3), "record all three judge defeats")
	assert(CampaignManager.can_complete_active_mission(), "encounter objective completion is recognized")
	var judge_mission_result: Dictionary = CampaignManager.complete_active_mission()
	assert(bool(judge_mission_result.get("success", false)) and str(judge_mission_result.get("next_mission", {}).get("id", "")) == "ha_004", "completed Hades boss mission advances and grants its reward")
	QuestManager.status = "ready_to_return"
	QuestManager.defeated_normal = 2
	QuestManager.boss_defeated = true
	assert(QuestManager._save_progress(), "save tutorial quest ready state")
	var tutorial_level_before := int(RPGState.profile.get("level", 1))
	var tutorial_exp_before := int(RPGState.profile.get("exp", 0))
	var tutorial_coins_before := int(RPGState.profile.get("currency", 0))
	assert(str(QuestManager.interact_with_guide().get("action", "")) == "complete", "complete tutorial quest and grant rewards")
	assert(int(RPGState.profile.get("level", 1)) > tutorial_level_before or int(RPGState.profile.get("exp", 0)) > tutorial_exp_before, "tutorial experience reward committed even when it triggers a level-up reset")
	assert(int(RPGState.profile.get("currency", 0)) == tutorial_coins_before + 300, "tutorial currency reward committed")
	var completed_level := int(RPGState.profile.get("level", 1))
	var completed_exp := int(RPGState.profile.get("exp", 0))
	var completed_coins := int(RPGState.profile.get("currency", 0))
	assert(str(QuestManager.interact_with_guide().get("action", "")) == "completed", "completed tutorial does not grant rewards again")
	assert(int(RPGState.profile.get("level", 1)) == completed_level and int(RPGState.profile.get("exp", 0)) == completed_exp and int(RPGState.profile.get("currency", 0)) == completed_coins, "tutorial reward cannot be claimed twice")
	assert(RPGState.load_slot(3), "restore original character after tutorial reward test")
	assert(RPGState.delete_slot(2), "remove second isolated slot")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://backup_slot_2.json"))

	assert(RPGState.backup_slot(3) and RPGState.has_backup_slot(3), "backup character slot")
	assert(RPGState.delete_slot(3), "delete slot after backup")
	assert(not RPGState.has_slot(3), "deleted save slot is no longer visible")
	assert(RPGState.active_slot == 0, "deleting the active slot clears the active character")
	assert(RPGState.restore_backup(3) and RPGState.has_slot(3), "restore character slot backup")
	assert(RPGState.active_slot == 3, "restoring a backup reloads its character slot")

	assert(not SkillSystem.has_class("unknown_class"), "unknown class ids are rejected")
	assert(SkillSystem.get_class_skill("unknown_class").is_empty(), "unknown class does not silently receive Pegasus skill data")
	assert(SkillSystem.get_ability_catalog("unknown_class").is_empty(), "unknown class has no inherited ability catalog")
	assert(not SkillSystem.can_afford_class_skill("unknown_class", 999.0), "unknown class cannot pass skill affordability checks")
	assert(SkillSystem.get_skill_level("unknown_class") == 0, "unknown class has no skill level")
	assert(SkillSystem.get_learned_skills("unknown_class").is_empty(), "unknown class has no learned skills")
	assert(not SkillSystem.is_ability_learned("unknown_class", "unknown_class_skill_1"), "unknown class cannot inherit a default learned skill")
	assert(SkillSystem.get_equipped_abilities("unknown_class").is_empty(), "unknown class has no equipped skill slots")
	assert(SkillSystem.get_skill_state("unknown_class").get("abilities", []).is_empty(), "unknown class skill state is empty")
	assert(SkillAnimationCatalog.get_profile("unknown_class", {"id": "fake_skill", "type": "攻击"}).is_empty(), "unknown class has no fallback animation profile")
	assert(not ComboPresetManager.save_preset("unknown_class", "invalid_class_combo", "非法职业连招", ["basic_attack_1"]), "reject combo presets for unknown classes")
	var combo_steps: Array = ["basic_attack_1", "pegasus_skill_1", "dodge"]
	assert(ComboPresetManager.save_preset("pegasus", "smoke_combo", "测试连招", combo_steps), "save player combo preset")
	assert(ComboPresetManager.get_active_preset("pegasus").get("steps", []) == combo_steps, "read active combo preset")
	assert(ComboPresetManager.set_active_preset("pegasus", "smoke_combo"), "switch active combo preset")
	assert(ComboPresetManager.delete_preset("pegasus", "smoke_combo"), "delete combo preset")
	assert(not ComboPresetManager.save_preset("pegasus", "invalid_combo", "非法连招", ["not_unlocked"]), "reject unlearned skill in combo")
	assert(RPGState.delete_slot(3), "clean up restored test character slot")
	assert(not RPGState.has_slot(3), "test character cleanup removes active slot")
	print("FRAMEWORK_SMOKE_TEST_PASS")
	get_tree().quit(0)
