extends Node
## Headless scene-based smoke test so project AutoLoads are initialized normally.

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
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
	assert(load("res://scripts/loot_pickup.gd") != null, "manual offline loot pickup actor is present")
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
		assert(world_theme_test.decor_root.get_child_count() >= 16, "chapter environment builds visible structures: " + theme_id)
	assert(test_world_environment.environment.background_mode == Environment.BG_COLOR, "chapter theme configures its own sky background")
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
	assert(ArmorSystem.get_state().get("unlocked_stages", []).size() == 7, "all seven armor stages unlocked")
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
	var payload_reader := FileAccess.open(payload_path, FileAccess.READ)
	assert(payload_reader != null, "read package payload")
	var payload_size := int(payload_reader.get_length())
	payload_reader.close()
	var manifest := {
		"id": "galaxy_wars",
		"manifest_version": 1,
		"version": 1,
		"size_bytes": payload_size,
		"dependencies": [],
		"files": [{"path": "payload.txt", "size_bytes": payload_size, "sha256": FileAccess.get_sha256(payload_path)}]
	}
	var manifest_file := FileAccess.open(source_dir.path_join("pack.json"), FileAccess.WRITE)
	assert(manifest_file != null, "create package manifest")
	manifest_file.store_string(JSON.stringify(manifest))
	manifest_file.close()
	assert(bool(ResourcePackManager.preflight_install(source_dir, "galaxy_wars").get("allowed", false)), "resource package preflight")
	assert(ResourcePackManager.install_from_directory(source_dir, "galaxy_wars"), "resource package staged install")
	assert(bool(ResourcePackManager.validate_pack("galaxy_wars").get("valid", false)), "resource package installed validation")
	assert(ResourcePackManager.remove_pack("galaxy_wars"), "resource package safe removal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(payload_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_dir.path_join("pack.json")))
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
	var campaign_catalog_audit: Dictionary = CampaignDatabase.validate_catalog()
	assert(bool(campaign_catalog_audit.get("valid", false)) and int(campaign_catalog_audit.get("chapter_count", 0)) == 7 and int(campaign_catalog_audit.get("mission_count", 0)) == 55, "all seven campaign arcs and 55 missions pass catalog validation: " + str(campaign_catalog_audit.get("errors", [])))
	var enemy_catalog_audit: Dictionary = EnemyDatabase.validate_archetypes()
	assert(bool(enemy_catalog_audit.get("valid", false)) and int(enemy_catalog_audit.get("archetype_count", 0)) >= 50, "all enemy archetypes pass combat-stat validation: " + str(enemy_catalog_audit.get("errors", [])))
	var expected_boss_specials := {
		"hypnos_guardian": "dream_drain",
		"thanatos_reaper": "death_burst",
		"hades_emperor": "soul_leech",
		"poseidon_emperor": "tidal_pull",
		"apollo_trial": "solar_flare",
		"zeus_trial": "lightning_followup",
		"universe_arbiter": "void_drain",
		"judge_griffin": "gravity_crush",
		"judge_garuda": "judge_combo",
		"judge_wyvern": "wing_slam"
	}
	for boss_id in expected_boss_specials:
		assert(str(EnemyDatabase.get_archetype(boss_id).get("boss_special", "")) == str(expected_boss_specials[boss_id]), "major boss has a unique heavy-attack signature: " + boss_id)
	var skill_audit: Dictionary = SkillSystem.validate_all_class_skill_catalogs()
	assert(bool(skill_audit.get("valid", false)), "all 32 classes must expose 24 complete unique skills: " + str(skill_audit.get("errors", [])))
	assert(int(skill_audit.get("class_count", 0)) == 32, "all base, divine and heavenly classes are registered")
	assert(int(skill_audit.get("ability_count", 0)) == 768, "all class ability catalogs contain 768 entries")
	var profiled_ability_count := 0
	var field_action_count := 0
	var trap_action_count := 0
	var homing_action_count := 0
	var ranged_action_count := 0
	for class_profile in SkillSystem.get_class_skill_catalog():
		var profile_class_id := str(class_profile.get("id", ""))
		for catalog_ability in SkillSystem.get_ability_catalog(profile_class_id):
			var combat_profile: Dictionary = SkillSystem.get_ability_effect_profile(catalog_ability)
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
	assert(is_equal_approx(SkillSystem.get_combo_damage_multiplier("pegasus"), 1.08), "Pegasus combo passive applies to combo finishers")
	assert(is_equal_approx(SkillSystem.get_combo_damage_multiplier("dragon"), 1.0), "classes without combo passive keep neutral combo damage")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("dragon"), 0.12), "Dragon defensive passive exposes its damage reduction")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("pegasus"), 0.0), "classes without defensive passive have no passive damage reduction")
	assert(is_equal_approx(SkillSystem.get_passive_speed_multiplier("tenkishi"), 1.22), "Heavenly Warrior wing mobility increases movement speed")
	assert(is_equal_approx(SkillSystem.get_damage_reduction("tenkishi"), 0.14), "Heavenly Warrior celestial armor reduces incoming damage")

	test_boss.apply_hit_reaction(Vector3.RIGHT, 10.0, 4.0, 0.8)
	assert(float(test_boss.boss_control_resist_timer) > 0.0, "repeated control builds boss poise resistance")
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
	assert(boss_visual_test.get_child_count() >= 10, "boss enemy builds armor, crown, aura and combat telegraph visuals")
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
