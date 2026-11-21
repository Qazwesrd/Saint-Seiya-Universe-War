extends Node3D
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HUDScript = preload("res://scripts/hud.gd")
const GuideNpcScript = preload("res://scripts/guide_npc.gd")
const TeleportPointScript = preload("res://scripts/teleport_point.gd")
const FollowerScript = preload("res://scripts/follower_actor.gd")
const SkillSummonScript = preload("res://scripts/skill_summon.gd")
const SkillFieldScript = preload("res://scripts/skill_field.gd")
const SkillProjectileScript = preload("res://scripts/skill_projectile.gd")
const SkillVisualCatalogScript = preload("res://scripts/skill_visual_catalog.gd")
const BossStoryCatalogScript = preload("res://scripts/boss_story_catalog.gd")
const LootPickupScript = preload("res://scripts/loot_pickup.gd")
const WorldThemeManagerScript = preload("res://scripts/world_theme_manager.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var enemies: Array[Node3D] = []
var world_theme_manager: Node3D
var active_world_chapter_id := ""
var guide_npc: Node3D
var teleport_point: Node3D
var sanctuary_active := false
var sanctuary_origin := Vector3(0, 0.15, 7)
var _daily_boss_challenge_active := false
var _daily_boss_challenge_id := ""
func _ready() -> void:
    CombatSessionManager.begin_encounter("galaxy_arena_trial")
    _build_world()
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.set("game", self)
    player.position = Vector3(0, 0.15, 7)
    add_child(player)
    _spawn_followers()
    CollectionSystem.collection_changed.connect(_spawn_followers)
    _build_sanctuary()
    _spawn_guide_npc()
    _spawn_teleport_point()
    hud = HUDScript.new()
    hud.set("game", self)
    add_child(hud)
    if bool(SettingsManager.get_value("gameplay", "show_tutorials", true)):
        hud.call("set_notice", "左侧摇杆移动，右侧拖动镜头；使用普攻、技能和闪避战斗。当前目标：" + str(CampaignManager.get_active_mission().get("name", "与引导员交谈")))
    else:
        hud.call("set_notice", "当前主线目标：" + str(CampaignManager.get_active_mission().get("name", "与引导员交谈")))
    _refresh_story_encounter()
func _build_world() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.32, 0.38, 0.62)
    env.ambient_light_energy = 0.7
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env_node.environment = env
    add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_energy = 1.3
    sun.shadow_enabled = bool(SettingsManager.get_value("graphics", "shadows", true)) and str(SettingsManager.get_value("graphics", "quality", "medium")) != "low"
    SettingsManager.settings_changed.connect(_on_graphics_setting_changed)
    add_child(sun)
    var floor_body := StaticBody3D.new()
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(70, 70)
    floor_mesh.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.055, 0.075, 0.14)
    mat.metallic = 0.2
    floor_mesh.material_override = mat
    floor_body.add_child(floor_mesh)
    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(70, 0.5, 70)
    col.shape = box
    col.position.y = -0.25
    floor_body.add_child(col)
    add_child(floor_body)
    var ring_root := Node3D.new()
    ring_root.name = "WorldRings"
    add_child(ring_root)
    for radius in [5.0, 10.0, 16.0]:
        var ring := MeshInstance3D.new()
        var torus := TorusMesh.new()
        torus.inner_radius = radius - 0.04
        torus.outer_radius = radius + 0.04
        ring.mesh = torus
        ring.position.y = 0.02
        var ring_mat := StandardMaterial3D.new()
        ring_mat.albedo_color = Color(0.08, 0.28, 0.65)
        ring_mat.emission_enabled = true
        ring_mat.emission = Color(0.03, 0.12, 0.5)
        ring.material_override = ring_mat
        ring_root.add_child(ring)
    world_theme_manager = Node3D.new()
    world_theme_manager.set_script(WorldThemeManagerScript)
    world_theme_manager.set("world_environment", env_node)
    world_theme_manager.set("sun", sun)
    world_theme_manager.set("floor_material", mat)
    world_theme_manager.set("ring_root", ring_root)
    add_child(world_theme_manager)
    _apply_campaign_world_theme()

func _apply_campaign_world_theme() -> void:
    if not is_instance_valid(world_theme_manager):
        return
    var mission := CampaignManager.get_active_mission()
    var mission_id := str(mission.get("id", ""))
    var chapter := CampaignDatabase.get_chapter_for_mission(mission_id)
    var chapter_id := str(chapter.get("id", "galaxy_wars"))
    if chapter_id == active_world_chapter_id:
        return
    if bool(world_theme_manager.call("apply_theme", chapter_id)):
        active_world_chapter_id = chapter_id
        show_notice("已进入篇章区域：" + str(chapter.get("name", "银河战争篇")))

func _spawn_guide_npc() -> void:
    guide_npc = Node3D.new()
    guide_npc.set_script(GuideNpcScript)
    guide_npc.position = Vector3(0, 0, 2)
    add_child(guide_npc)

func _spawn_teleport_point() -> void:
    teleport_point = Node3D.new()
    teleport_point.set_script(TeleportPointScript)
    teleport_point.position = Vector3(0, 0, -16)
    add_child(teleport_point)

func use_teleport_point() -> void:
    if not is_instance_valid(player) or not is_instance_valid(teleport_point):
        return
    if player.global_position.distance_to(teleport_point.global_position) > 3.8:
        show_notice("靠近蓝色传送阵后才能使用")
        return
    player.call("cancel_auto_move")
    player.velocity = Vector3.ZERO
    player.global_position = Vector3(0, 0.15, 7)
    show_notice("已传送回银河竞技场入口")

func navigate_to_objective() -> void:
    if not is_instance_valid(player):
        return
    var target: Node3D
    if QuestManager.status == "not_started" or QuestManager.status == "ready_to_return" or QuestManager.status == "completed":
        target = guide_npc
    elif QuestManager.defeated_normal < 2:
        var nearest_distance := INF
        for enemy in enemies:
            if is_instance_valid(enemy) and not bool(enemy.get("is_boss")):
                var distance: float = player.global_position.distance_to(enemy.global_position)
                if distance < nearest_distance:
                    nearest_distance = distance
                    target = enemy
    elif not QuestManager.boss_defeated:
        for enemy in enemies:
            if is_instance_valid(enemy) and bool(enemy.get("is_boss")):
                target = enemy
                break
    else:
        target = guide_npc
    if is_instance_valid(target):
        player.call("set_auto_move_target", target.global_position)
        show_notice("任务导航已启动；手动摇杆可随时接管")
    else:
        show_notice("当前没有可导航的任务目标")

func interact_with_guide() -> void:
    if not is_instance_valid(player) or not is_instance_valid(guide_npc):
        return
    if player.global_position.distance_to(guide_npc.global_position) > 4.8:
        show_notice("靠近圣域训练引导员后再交谈")
        return
    var dialogue: Dictionary = QuestManager.interact_with_guide()
    var campaign_mission: Dictionary = CampaignManager.get_active_mission()
    if not campaign_mission.is_empty() and campaign_mission.get("encounter", {}).is_empty():
        var campaign_state := CampaignManager.get_mission_progress(str(campaign_mission.get("id", "")))
        for objective in campaign_state.get("objectives", []):
            if not bool(objective.get("completed", false)):
                CampaignManager.add_objective_progress(str(objective.get("id", "")), 1)
                break
        if CampaignManager.can_complete_active_mission():
            var campaign_result: Dictionary = CampaignManager.complete_active_mission()
            if bool(campaign_result.get("success", false)):
                show_notice("剧情任务完成：" + str(campaign_mission.get("name", "")))
    if is_instance_valid(hud):
        hud.call("show_dialogue", dialogue)
    _refresh_story_encounter()
    show_notice(str(dialogue.get("action", "")))

func _refresh_story_encounter() -> void:
    _apply_campaign_world_theme()
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
    if not enemies.is_empty():
        return
    if EncounterDirector.active:
        var next_wave := EncounterDirector.advance_wave()
        if not next_wave.is_empty():
            _spawn_encounter_wave(next_wave)
            return
    var mission := CampaignManager.get_active_mission()
    var mission_id := str(mission.get("id", ""))
    var mission_state := CampaignManager.get_mission_progress(mission_id)
    var objectives: Array = mission_state.get("objectives", [])
    if mission_id == "gw_002":
        var remaining := 0
        for objective in objectives:
            if str(objective.get("id", "")) == "defeat_training_enemy":
                remaining = maxi(0, int(objective.get("target", 0)) - int(objective.get("current", 0)))
        if remaining > 0:
            var waves: Array[Dictionary] = [
                {"spawns": [{"archetype_id": "arena_guard", "count": 1, "position": Vector3(-4, 0.1, -3)}]},
                {"spawns": [{"archetype_id": "arena_elite", "count": 1, "position": Vector3(4, 0.1, -4)}]}
            ]
            if EncounterDirector.start("story_gw_002", waves):
                _spawn_encounter_wave(EncounterDirector.get_current_wave())
                show_notice("剧情战斗：第一波训练对手出现")
    elif mission_id == "gw_003":
        var remaining_boss := 0
        for objective in objectives:
            if str(objective.get("id", "")) == "defeat_training_boss":
                remaining_boss = maxi(0, int(objective.get("target", 0)) - int(objective.get("current", 0)))
        if remaining_boss > 0:
            var boss_waves: Array[Dictionary] = [
                {"spawns": [{"archetype_id": "arena_boss", "count": 1, "boss": true, "position": Vector3(0, 0.1, -9)}]}
            ]
            if EncounterDirector.start("story_gw_003", boss_waves):
                _show_boss_story_scene("intro", mission, "arena_boss")
                _spawn_encounter_wave(EncounterDirector.get_current_wave())
                show_notice("剧情推进：训练首领登场")
    elif not mission.is_empty():
        _start_data_driven_campaign_encounter(mission, mission_state)

func _start_data_driven_campaign_encounter(mission: Dictionary, mission_state: Dictionary) -> void:
    var encounter: Dictionary = mission.get("encounter", {})
    var waves: Array = encounter.get("waves", [])
    if waves.is_empty() or EncounterDirector.active:
        return
    if bool(mission_state.get("completed", false)):
        return
    var definitions: Array[Dictionary] = []
    for wave in waves:
        if wave is Dictionary:
            definitions.append(wave.duplicate(true))
    if definitions.is_empty():
        return
    var encounter_id := "story_" + str(mission.get("id", "unknown"))
    if EncounterDirector.start(encounter_id, definitions):
        var first_boss_id := ""
        for spawn in definitions[0].get("spawns", []):
            if bool(spawn.get("boss", false)):
                first_boss_id = str(spawn.get("archetype_id", ""))
                break
        if not first_boss_id.is_empty():
            _show_boss_story_scene("intro", mission, first_boss_id)
        _spawn_encounter_wave(EncounterDirector.get_current_wave())
        show_notice("剧情遭遇开始：" + str(mission.get("name", "章节战斗")))

func _show_boss_story_scene(event_name: String, mission: Dictionary, boss_id: String) -> void:
    if not is_instance_valid(hud) or mission.is_empty():
        return
    var chapter_id := str(CampaignDatabase.get_chapter_for_mission(str(mission.get("id", ""))).get("id", ""))
    var archetype: Dictionary = EnemyDatabase.get_archetype(boss_id)
    var boss_name := str(archetype.get("name", boss_id))
    var scene: Dictionary = BossStoryCatalogScript.get_scene(chapter_id, boss_id, event_name, boss_name)
    if not scene.is_empty() and hud.has_method("show_story_sequence"):
        hud.call("show_story_sequence", scene)


func _record_campaign_encounter_progress(enemy: Node3D) -> void:
    var mission: Dictionary = CampaignManager.get_active_mission()
    if mission.is_empty():
        return
    var encounter: Dictionary = mission.get("encounter", {})
    var expected_ids: Array[String] = []
    for wave in encounter.get("waves", []):
        for spawn in wave.get("spawns", []):
            var archetype_id := str(spawn.get("archetype_id", ""))
            if not archetype_id.is_empty() and not expected_ids.has(archetype_id):
                expected_ids.append(archetype_id)
    var defeated_archetype := str(enemy.get("archetype_id"))
    if expected_ids.is_empty() or not expected_ids.has(defeated_archetype):
        return
    var state := CampaignManager.get_mission_progress(str(mission.get("id", "")))
    for objective in state.get("objectives", []):
        if not bool(objective.get("completed", false)):
            CampaignManager.add_objective_progress(str(objective.get("id", "")), 1)
            return

func _spawn_encounter_wave(wave: Dictionary) -> void:
    var spawns: Array = wave.get("spawns", [])
    var total_spawned := 0
    for spawn in spawns:
        var count := maxi(0, int(spawn.get("count", 1)))
        var archetype_id := str(spawn.get("archetype_id", "arena_guard"))
        var is_boss := bool(spawn.get("boss", archetype_id == "arena_boss"))
        var position: Vector3 = spawn.get("position", Vector3(0, 0.1, -5))
        for index in range(count):
            var offset := Vector3(float(index % 3) * 1.5, 0.0, float(index / 3) * 1.5)
            _spawn_enemy(position + offset, is_boss, archetype_id)
            total_spawned += 1
    EncounterDirector.register_enemy(total_spawned)
    if total_spawned > 0:
        show_notice("第 %d/%d 波：敌人 %d 名" % [int(wave.get("wave_number", 1)), int(wave.get("wave_total", 1)), total_spawned])

func start_daily_boss_challenge() -> void:
    var daily_state: Dictionary = DailyBossManager.get_state()
    if not DailyBossManager.can_challenge():
        show_notice("今日首领已经击败，请领取奖励或等待明日刷新")
        return
    if not enemies.is_empty():
        show_notice("请先完成当前战斗，再挑战每日首领")
        return
    _daily_boss_challenge_active = true
    _daily_boss_challenge_id = str(daily_state.get("boss_id", ""))
    CombatSessionManager.begin_encounter(_daily_boss_challenge_id)
    _spawn_enemy(Vector3(0, 0.1, -9), true)
    var daily_enemy: Node3D = enemies.back()
    var level_bonus := int(daily_state.get("level_offset", 0))
    daily_enemy.set("display_name", str(daily_state.get("boss_name", "每日首领")))
    daily_enemy.set("max_health", float(daily_enemy.get("max_health")) * (1.0 + float(level_bonus) * 0.035))
    daily_enemy.set("health", daily_enemy.get("max_health"))
    daily_enemy.set("attack_damage", float(daily_enemy.get("attack_damage")) * (1.0 + float(level_bonus) * 0.025))
    daily_enemy.set("exp_reward", 0)
    daily_enemy.set("coin_reward", 0)
    show_notice("每日挑战开始：" + str(daily_state.get("boss_name", "每日首领")))

func _spawn_enemy(at: Vector3, boss: bool, requested_archetype_id: String = "") -> void:
    var enemy := CharacterBody3D.new()
    enemy.set_script(EnemyScript)
    enemy.set("game", self)
    enemy.set("is_boss", boss)
    enemy.set("archetype_id", requested_archetype_id if not requested_archetype_id.is_empty() else ("arena_boss" if boss else "arena_guard"))
    enemy.position = at
    add_child(enemy)
    enemies.append(enemy)
func damage_nearby(damage: float, reach: float, cone_degrees: float = 120.0) -> void:
    var forward := -player.global_transform.basis.z
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var offset: Vector3 = enemy.global_position - player.global_position
        if offset.length() <= reach and (offset.length() < 0.1 or forward.dot(offset.normalized()) >= cos(deg_to_rad(cone_degrees * 0.5))):
            var class_id := str(RPGState.profile.get("class_id", "pegasus"))
            var target_multiplier: float = SkillSystem.get_target_condition_multiplier(class_id, enemy)
            var target_forward: Vector3 = -enemy.global_transform.basis.z
            var toward_attacker: Vector3 = player.global_position - enemy.global_position
            toward_attacker.y = 0.0
            var target_facing_dot := target_forward.dot(toward_attacker.normalized()) if toward_attacker.length_squared() > 0.001 else 1.0
            var position_multiplier: float = SkillSystem.get_position_damage_multiplier(class_id, target_facing_dot, bool(enemy.get("is_boss")))
            enemy.call("take_damage", damage * target_multiplier * position_multiplier, player.global_position)
func try_resolve_boss_ultimate_clash(player_power: float) -> bool:
    if not is_instance_valid(player):
        return false
    var nearest_boss: Node3D
    var nearest_distance := INF
    for enemy in enemies:
        if not is_instance_valid(enemy) or not bool(enemy.get("is_boss")) or not enemy.has_method("is_ultimate_telegraph_active"):
            continue
        if not bool(enemy.call("is_ultimate_telegraph_active")):
            continue
        var distance := player.global_position.distance_to(enemy.global_position)
        if distance <= 11.0 and distance < nearest_distance:
            nearest_boss = enemy
            nearest_distance = distance
    if not is_instance_valid(nearest_boss):
        return false
    var won := bool(nearest_boss.call("resolve_ultimate_clash", player_power))
    var accent := Color(1.0, 0.72, 0.2) if won else Color(0.55, 0.22, 1.0)
    spawn_effect((player.global_position + nearest_boss.global_position) * 0.5 + Vector3.UP, accent, 5.0 if won else 4.0, "wave", 0.85)
    if won:
        nearest_boss.call("take_damage", player_power * 1.5, player.global_position)
        show_notice("必杀技对抗胜利！压制首领并造成额外伤害！")
    else:
        player.cosmos = maxf(0.0, player.cosmos - 18.0)
        show_notice("必杀技对抗失败！小宇宙被压制，注意闪避首领攻击！")
    return true

func damage_nearby_combat(damage: float, reach: float, cone_degrees: float, knockback: float, launch: float, stagger: float) -> void:
    if not is_instance_valid(player):
        return
    var forward := -player.global_transform.basis.z
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var offset: Vector3 = enemy.global_position - player.global_position
        var distance := offset.length()
        if distance > reach:
            continue
        if distance >= 0.1 and forward.dot(offset.normalized()) < cos(deg_to_rad(cone_degrees * 0.5)):
            continue
        var class_id := str(RPGState.profile.get("class_id", "pegasus"))
        var target_multiplier: float = SkillSystem.get_target_condition_multiplier(class_id, enemy)
        var target_forward: Vector3 = -enemy.global_transform.basis.z
        var toward_attacker: Vector3 = player.global_position - enemy.global_position
        toward_attacker.y = 0.0
        var target_facing_dot := target_forward.dot(toward_attacker.normalized()) if toward_attacker.length_squared() > 0.001 else 1.0
        var position_multiplier := SkillSystem.get_position_damage_multiplier(class_id, target_facing_dot, bool(enemy.get("is_boss")))
        enemy.call("take_damage", damage * target_multiplier * position_multiplier, player.global_position)
        if is_instance_valid(enemy) and enemy.has_method("apply_hit_reaction"):
            var passive_stagger: float = SkillSystem.get_passive_stagger_multiplier(class_id)
            enemy.call("apply_hit_reaction", offset.normalized(), knockback, launch, stagger * passive_stagger)


func apply_class_skill_effect(class_id: String, reach: float) -> void:
    if not is_instance_valid(player):
        return
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var applied := 0
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy) or enemy.get("health") <= 0.0:
            continue
        var distance: float = enemy.global_position.distance_to(player.global_position)
        if distance > reach + 1.5:
            continue
        match class_id:
            "pegasus":
                enemy.call("apply_status_effect", "slow", 2.5, 0.18)
            "dragon":
                enemy.call("apply_hit_reaction", (enemy.global_position - player.global_position).normalized(), 2.0, 0.0, 0.35)
            "cygnus":
                enemy.call("apply_status_effect", "freeze", 1.8, 0.0)
                enemy.call("apply_status_effect", "slow", 3.0, 0.4)
            "andromeda":
                var pull_direction: Vector3 = player.global_position - enemy.global_position
                pull_direction.y = 0.0
                enemy.call("apply_hit_reaction", pull_direction.normalized(), 5.5, 0.0, 0.45)
                enemy.call("apply_status_effect", "slow", 2.0, 0.25)
            "phoenix":
                enemy.call("apply_status_effect", "burn", 5.0, maxf(2.0, attack_power * 0.14))
            "sea_dragon":
                enemy.call("apply_status_effect", "weaken", 4.0, 0.28)
                enemy.call("apply_status_effect", "slow", 2.0, 0.2)
            "tenmou":
                enemy.call("apply_status_effect", "slow", 2.0, 0.15)
            "lyra":
                enemy.call("apply_status_effect", "weaken", 4.5, 0.22)
                enemy.call("apply_status_effect", "slow", 3.0, 0.3)
            "sea_swallow":
                enemy.call("apply_status_effect", "burn", 3.5, maxf(1.5, attack_power * 0.09))
                enemy.call("apply_status_effect", "slow", 1.5, 0.12)
        applied += 1
    match class_id:
        "pegasus":
            player.call("apply_temporary_buff", 0.18, 0.0, 4.0)
        "dragon":
            player.call("apply_temporary_buff", 0.0, 0.32, 5.0)
        "andromeda":
            player.call("apply_temporary_buff", 0.0, 0.16, 4.0)
        "phoenix":
            player.call("apply_temporary_buff", 0.12, 0.0, 5.0)
        "sea_dragon":
            player.call("apply_temporary_buff", 0.16, 0.08, 4.0)
        "tenmou":
            player.call("apply_temporary_buff", 0.12, 0.25, 5.0)
        "lyra":
            player.call("apply_temporary_buff", 0.08, 0.08, 4.0)
        "sea_swallow":
            player.call("apply_temporary_buff", 0.15, 0.0, 3.5)
    if applied > 0:
        var class_label := str(SkillSystem.get_class_skill(class_id).get("class_name", "职业"))
        show_notice(class_label + "专属状态生效：影响敌人 %d 名" % applied)


func on_enemy_defeated(enemy: Node3D) -> void:
    var defeated_boss := bool(enemy.get("is_boss"))
    var completed_story_mission: Dictionary = {}
    var is_daily_boss := _daily_boss_challenge_active and defeated_boss
    if is_daily_boss:
        if DailyBossManager.mark_boss_defeated(_daily_boss_challenge_id):
            show_notice("每日首领已击败！请打开每日挑战领取奖励")
        _daily_boss_challenge_active = false
        _daily_boss_challenge_id = ""
    else:
        var campaign_mission: Dictionary = CampaignManager.get_active_mission()
        var campaign_id := str(campaign_mission.get("id", ""))
        if campaign_id == "gw_002" and not defeated_boss:
            CampaignManager.add_objective_progress("defeat_training_enemy", 1)
        elif campaign_id == "gw_003" and defeated_boss:
            CampaignManager.add_objective_progress("defeat_training_boss", 1)
        if CampaignManager.can_complete_active_mission():
            var campaign_result: Dictionary = CampaignManager.complete_active_mission()
            if bool(campaign_result.get("success", false)):
                completed_story_mission = campaign_mission
                show_notice("剧情任务完成：" + str(campaign_mission.get("name", "")))
    if not is_daily_boss:
        _record_campaign_encounter_progress(enemy)
        if CampaignManager.can_complete_active_mission():
            var encounter_mission: Dictionary = CampaignManager.get_active_mission()
            var encounter_result: Dictionary = CampaignManager.complete_active_mission()
            if bool(encounter_result.get("success", false)):
                completed_story_mission = encounter_mission
                show_notice("剧情任务完成：" + str(encounter_mission.get("name", "")))
        QuestManager.on_enemy_defeated(defeated_boss)
        EncounterDirector.report_enemy_defeated()

    CollectionSystem.record_enemy_defeat(bool(enemy.get("is_boss")) )
    CombatSessionManager.record_enemy_defeated(defeated_boss)
    enemies.erase(enemy)
    var exp_reward := int(enemy.get("exp_reward"))
    var coin_reward := int(enemy.get("coin_reward"))
    var level_gains: int = RPGState.add_exp(exp_reward)
    RPGState.add_currency(coin_reward)
    var auto_pickup := bool(SettingsManager.get_value("controls", "auto_pickup", true))
    var drops: Array[Dictionary] = LootManager.roll_enemy_drops(defeated_boss, int(RPGState.profile.get("level", 1)), auto_pickup)
    if not auto_pickup:
        for drop in drops:
            _spawn_loot_pickup(enemy.global_position, drop)
    refresh_player_stats()
    var reward_text := "获得经验 %d、星币 %d" % [exp_reward, coin_reward]
    for drop in drops:
        var drop_prefix := "" if auto_pickup else "掉落"
        reward_text += "、%s%s×%d" % [drop_prefix, str(drop.get("name", "物品")), int(drop.get("quantity", 1))]
    if level_gains > 0:
        reward_text += "，等级提升 %d 级！" % level_gains
    show_notice(reward_text)
    if defeated_boss:
        if is_instance_valid(player) and player.has_method("_play_authored_action_animation"):
            player.call("_play_authored_action_animation", "victory", 0.08)
        var battle_summary: Dictionary = CombatSessionManager.finish_encounter()
        if is_instance_valid(hud) and hud.has_method("show_battle_result"):
            hud.call("show_battle_result", battle_summary, {"exp": exp_reward, "coins": coin_reward})
    if defeated_boss and not completed_story_mission.is_empty():
        _show_boss_story_scene("outro", completed_story_mission, str(enemy.get("archetype_id")))
    else:
        _refresh_story_encounter()


func on_story_sequence_closed(event_name: String) -> void:
    if event_name == "outro":
        _refresh_story_encounter()


func update_hud() -> void:
    if is_instance_valid(hud) and is_instance_valid(player):
        hud.call("set_status", player.get("health"), player.get("max_health"), player.get("cosmos"), player.get("max_cosmos"), player.get("skill_cd"), player.get("burst_cd"))
        hud.call("set_enemy_count", enemies.size())
        hud.call("set_quest_text", QuestManager.get_tracker_text())
        var boss_hp := 0.0
        var boss_max := 1.0
        var boss_name := "训练 Boss"
        var boss_phase_two := false
        for enemy in enemies:
            if is_instance_valid(enemy) and bool(enemy.get("is_boss")):
                boss_hp = float(enemy.get("health"))
                boss_max = float(enemy.get("max_health"))
                boss_name = str(enemy.get("display_name"))
                boss_phase_two = bool(enemy.get("_boss_phase_two"))
                break
        hud.call("set_boss_status", boss_hp, boss_max, boss_name, boss_phase_two)
func _spawn_loot_pickup(at: Vector3, drop: Dictionary) -> void:
    var pickup := Area3D.new()
    pickup.set_script(LootPickupScript)
    pickup.set("game", self)
    pickup.set("item_id", str(drop.get("item_id", "")))
    pickup.set("item_name", str(drop.get("name", "战利品")))
    pickup.set("quantity", maxi(1, int(drop.get("quantity", 1))))
    pickup.global_position = at + Vector3(randf_range(-0.8, 0.8), 0.15, randf_range(-0.8, 0.8))
    add_child(pickup)

func _on_graphics_setting_changed(section: String, key: String, value: Variant) -> void:
    if section == "graphics" and key in ["shadows", "quality"]:
        var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
        if is_instance_valid(sun):
            sun.shadow_enabled = bool(SettingsManager.get_value("graphics", "shadows", true)) and str(SettingsManager.get_value("graphics", "quality", "medium")) != "low"

func show_boss_battle_line(boss: Node3D, event_name: String) -> void:
    if not is_instance_valid(boss) or not bool(boss.get("is_boss")) or not is_instance_valid(hud):
        return
    var boss_id := str(boss.get("archetype_id")) if boss.get("archetype_id") != null else ""
    var boss_name := str(boss.get("display_name")) if boss.get("display_name") != null else "强敌"
    var line: Dictionary = BossStoryCatalogScript.get_battle_line(boss_id, event_name, boss_name)
    if not line.is_empty() and hud.has_method("show_boss_callout"):
        hud.call("show_boss_callout", line)


func play_boss_presentation(boss: Node3D, event_name: String) -> void:
    if not is_instance_valid(boss) or not bool(boss.get("is_boss")):
        return
    var special := str(boss.get("boss_special"))
    var accent := Color(0.56, 0.72, 1.0)
    match special:
        "frostfire": accent = Color(0.36, 0.78, 1.0)
        "sonic_wave": accent = Color(0.78, 0.56, 1.0)
        "crystal_seal": accent = Color(0.52, 0.38, 0.92)
        "six_beasts": accent = Color(0.28, 0.82, 0.62)
        "mirror_feint": accent = Color(0.82, 0.48, 1.0)
        "sleeping_field": accent = Color(0.68, 0.72, 1.0)
        "death_mark": accent = Color(1.0, 0.22, 0.3)
        "storm_chain": accent = Color(0.52, 0.72, 1.0)
        "cosmic_collapse": accent = Color(0.82, 0.72, 1.0)
        "solar_flare": accent = Color(1.0, 0.68, 0.18)
        "tidal_pull": accent = Color(0.16, 0.68, 1.0)
        "void_drain", "soul_leech", "rift_drain": accent = Color(0.78, 0.24, 0.62)
    var effect_radius := 2.2
    var effect_shape := "halo"
    match event_name:
        "break":
            effect_radius = 2.8
            effect_shape = "ring"
        "entrance":
            effect_radius = 3.0
            effect_shape = "ring"
        "phase_two":
            effect_radius = 3.4
            effect_shape = "flare"
        "enrage":
            effect_radius = 4.0
            effect_shape = "star"
        "ultimate":
            effect_radius = 3.6
            effect_shape = "wave"
        "hit":
            effect_radius = 1.35
            effect_shape = "shard"
        "defeat":
            effect_radius = 4.2
            effect_shape = "void"
    spawn_effect(boss.global_position + Vector3.UP * (2.0 if event_name != "hit" else 1.4), accent, effect_radius, effect_shape, 0.58)
    if is_instance_valid(player) and player.has_method("play_boss_camera_presentation"):
        player.call("play_boss_camera_presentation", event_name)
    if event_name == "entrance":
        show_notice("强敌来袭：" + str(boss.get("display_name")))
    elif event_name == "defeat":
        show_notice("首领战结束：" + str(boss.get("display_name")))


func spawn_skill_effect(at: Vector3, visual_profile: Dictionary) -> void:
    if visual_profile.is_empty() or not bool(SettingsManager.get_value("graphics", "effects", true)):
        return
    var effect_color: Color = visual_profile.get("color", Color(0.42, 0.66, 1.0))
    var impact_scale := clampf(float(visual_profile.get("impact_scale", 1.0)), 0.5, 1.5)
    var shape := str(visual_profile.get("shape", "star"))
    var glow := clampf(float(visual_profile.get("glow", 0.4)), 0.0, 0.6)
    var layers := clampi(int(visual_profile.get("effect_layers", 1)), 1, 3)
    var signature := int(visual_profile.get("signature", 0))
    spawn_effect(at, effect_color, clampf(2.2 * impact_scale, 1.2, 3.8), shape, glow)
    if layers >= 2:
        var secondary_shape := str(visual_profile.get("secondary_shape", "ring"))
        var offset := Vector3(float((signature % 3) - 1) * 0.34, 0.08, float(((signature / 3) % 3) - 1) * 0.34)
        spawn_effect(at + offset, effect_color.lightened(0.12), clampf(1.45 * impact_scale, 0.9, 2.4), secondary_shape, glow * 0.82)
    if layers >= 3:
        # Ultimate techniques receive a third, larger delayed-looking outer
        # impact layer; low graphics quality still limits each effect's shards.
        spawn_effect(at + Vector3.UP * 0.16, effect_color, clampf(2.85 * impact_scale, 1.8, 4.2), "halo", glow)


func spawn_effect(at: Vector3, effect_color: Color, radius: float, effect_shape: String = "star", glow: float = 0.4) -> void:
    if not bool(SettingsManager.get_value("graphics", "effects", true)):
        return
    var element := "cosmos"
    for candidate in SkillVisualCatalogScript.ELEMENTS:
        var profile: Dictionary = SkillVisualCatalogScript.ELEMENTS[candidate]
        if str(profile.get("shape", "")) == effect_shape:
            element = str(candidate)
            break
    var authored_path := "res://assets/vfx/%s/effect.tscn" % element
    if ResourceLoader.exists(authored_path):
        var packed_effect := load(authored_path) as PackedScene
        if packed_effect != null:
            var authored_root := packed_effect.instantiate() as Node3D
            if authored_root != null:
                authored_root.name = "CosmosImpact_" + element
                authored_root.position = at
                authored_root.scale = Vector3.ONE * 0.16
                var quality := str(SettingsManager.get_value("graphics", "quality", "medium"))
                var visible_shards := 2 if quality == "low" else (5 if quality == "medium" else 8)
                for child in authored_root.get_children():
                    if str(child.name).begins_with("Shard_"):
                        var shard_index := int(str(child.name).trim_prefix("Shard_"))
                        child.visible = shard_index <= visible_shards
                add_child(authored_root)
                var safe_radius := clampf(radius, 0.35, 5.0)
                var authored_tween := create_tween()
                authored_tween.set_parallel(true)
                authored_tween.tween_property(authored_root, "scale", Vector3.ONE * safe_radius, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
                authored_tween.tween_property(authored_root, "rotation:y", TAU * (0.12 if effect_shape in ["ring", "halo", "time"] else 0.2), 0.34)
                authored_tween.tween_property(authored_root, "position:y", at.y + 0.22, 0.34)
                authored_tween.finished.connect(func() -> void:
                    if is_instance_valid(authored_root):
                        authored_root.queue_free()
                )
                return

    var effect_root := Node3D.new()
    effect_root.name = "CosmosImpact_" + effect_shape
    effect_root.position = at
    effect_root.scale = Vector3.ONE * 0.16
    add_child(effect_root)

    var core := MeshInstance3D.new()
    match effect_shape:
        "shard", "bolt":
            var core_prism := PrismMesh.new()
            core_prism.size = Vector3(0.34, 0.9, 0.24) if effect_shape == "bolt" else Vector3(0.46, 0.72, 0.3)
            core.mesh = core_prism
            core.rotation.z = -0.18 if effect_shape == "bolt" else 0.0
        "ring", "halo", "pulse":
            var core_ring := TorusMesh.new()
            core_ring.inner_radius = 0.22
            core_ring.outer_radius = 0.48
            core.mesh = core_ring
        "wave", "crescent":
            var core_wave := CylinderMesh.new()
            core_wave.top_radius = 0.12
            core_wave.bottom_radius = 0.58
            core_wave.height = 0.12
            core.mesh = core_wave
            core.rotation.x = deg_to_rad(90.0)
        "flare":
            var core_flare := CapsuleMesh.new()
            core_flare.radius = 0.24
            core_flare.height = 0.92
            core.mesh = core_flare
            core.rotation.z = deg_to_rad(42.0)
        "void":
            var core_void := SphereMesh.new()
            core_void.radius = 0.46
            core_void.height = 0.92
            core.mesh = core_void
            core.scale = Vector3(0.72, 1.18, 0.72)
        "wisp":
            var core_wisp := CapsuleMesh.new()
            core_wisp.radius = 0.14
            core_wisp.height = 0.88
            core.mesh = core_wisp
            core.rotation.z = deg_to_rad(-28.0)
        "star":
            var core_star := PrismMesh.new()
            core_star.size = Vector3(0.62, 0.62, 0.22)
            core.mesh = core_star
        _:
            var core_sphere := SphereMesh.new()
            core_sphere.radius = 0.48
            core_sphere.height = 0.96
            core.mesh = core_sphere
    var core_material := StandardMaterial3D.new()
    core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    core_material.albedo_color = Color(effect_color.r, effect_color.g, effect_color.b, 0.58)
    core_material.emission_enabled = true
    core_material.emission = effect_color * (0.8 + clampf(glow, 0.0, 0.6) * 1.6)
    core.material_override = core_material
    effect_root.add_child(core)

    var shock_ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.56
    ring_mesh.outer_radius = 0.68
    shock_ring.mesh = ring_mesh
    shock_ring.rotation.x = deg_to_rad(90.0)
    var ring_material := StandardMaterial3D.new()
    ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring_material.albedo_color = effect_color.lightened(0.22)
    ring_material.emission_enabled = true
    ring_material.emission = effect_color * (1.0 + clampf(glow, 0.0, 0.6))
    shock_ring.material_override = ring_material
    effect_root.add_child(shock_ring)

    var quality := str(SettingsManager.get_value("graphics", "quality", "medium"))
    var shard_count := 2 if quality == "low" else (5 if quality == "medium" else 8)
    if effect_shape in ["ring", "halo", "pulse"]:
        shard_count = maxi(1, shard_count - 2)
    for shard_index in range(shard_count):
        var shard := MeshInstance3D.new()
        var shard_mesh := PrismMesh.new()
        shard_mesh.size = Vector3(0.12, 0.46, 0.10)
        shard.mesh = shard_mesh
        var angle := TAU * float(shard_index) / float(shard_count)
        shard.position = Vector3(cos(angle) * 0.42, 0.0, sin(angle) * 0.42)
        shard.rotation.y = -angle
        shard.rotation.z = -0.48
        var shard_material := StandardMaterial3D.new()
        shard_material.albedo_color = effect_color.lightened(0.3)
        shard_material.emission_enabled = true
        shard_material.emission = effect_color * 0.8
        shard.material_override = shard_material
        effect_root.add_child(shard)

    var safe_radius := clampf(radius, 0.35, 5.0)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(effect_root, "scale", Vector3.ONE * safe_radius, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(effect_root, "rotation:y", TAU * (0.12 if effect_shape in ["ring", "halo", "time"] else 0.2), 0.34)
    tween.tween_property(effect_root, "position:y", at.y + 0.22, 0.34)
    tween.finished.connect(func() -> void:
        if is_instance_valid(effect_root):
            effect_root.queue_free()
    )

func spawn_damage_number(at: Vector3, damage: float, critical: bool = false) -> void:
    if not bool(SettingsManager.get_value("gameplay", "damage_numbers", true)):
        return
    var number := Label3D.new()
    number.text = str(maxi(1, roundi(damage)))
    number.font_size = 34 if critical else 28
    number.outline_size = 6
    number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    number.modulate = Color(1.0, 0.72, 0.22) if critical else Color(1.0, 0.94, 0.78)
    number.position = at
    number.scale = Vector3.ONE * (0.72 if critical else 0.62)
    add_child(number)
    var tween := create_tween()
    tween.tween_property(number, "scale", Vector3.ONE * (1.22 if critical else 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(number, "scale", Vector3.ONE * (1.05 if critical else 0.9), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(number, "position:y", at.y + (1.55 if critical else 1.3), 0.68)
    tween.parallel().tween_property(number, "modulate:a", 0.0, 0.68)
    tween.finished.connect(func() -> void:
        if is_instance_valid(number):
            number.queue_free()
    )

func show_notice(message: String) -> void:
    if is_instance_valid(hud):
        hud.call("set_notice", message)

func refresh_player_stats() -> void:
    if not is_instance_valid(player):
        return
    var stats: Dictionary = RPGState.get_combat_stats()
    player.max_health = float(stats.get("max_health", player.max_health))
    player.max_cosmos = float(stats.get("max_cosmos", player.max_cosmos))
    player.cosmos_regen_rate = float(RPGState.get_cosmos_profile().get("regen_rate", player.cosmos_regen_rate))
    player.health = minf(player.health, player.max_health)
    player.cosmos = minf(player.cosmos, player.max_cosmos)

func _spawn_followers() -> void:
 for existing in get_tree().get_nodes_in_group("player_followers"):
  if is_instance_valid(existing): existing.queue_free()
 var state: Dictionary = CollectionSystem.get_state()
 var companion_id := str(state.get("active_companion",""))
 var pet_id := str(state.get("active_pet",""))
 if companion_id != "":
  var companion := Node3D.new()
  companion.set_script(FollowerScript)
  companion.set("target",player)
  companion.set("orbit_offset",Vector3(-1.6,0,1.1))
  companion.add_to_group("player_followers")
  add_child(companion)
 if pet_id != "":
  var pet := Node3D.new()
  pet.set_script(FollowerScript)
  pet.set("target",player)
  pet.set("orbit_offset",Vector3(1.6,0,1.1))
  pet.set("follow_speed",6.5)
  pet.add_to_group("player_followers")
  add_child(pet)

func _build_sanctuary() -> void:
 var ground := StaticBody3D.new()
 ground.position = Vector3(100, -0.35, 100)
 var floor_mesh := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(42,42)
 floor_mesh.mesh = plane
 var floor_mat := StandardMaterial3D.new()
 floor_mat.albedo_color = Color(0.12,0.09,0.2)
 floor_mat.metallic = 0.35
 floor_mesh.material_override = floor_mat
 ground.add_child(floor_mesh)
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(42,0.5,42)
 collision.shape = shape
 collision.position.y = -0.25
 ground.add_child(collision)
 add_child(ground)
 for i in range(3):
  var building := MeshInstance3D.new()
  var block := BoxMesh.new()
  block.size = Vector3(5.0,3.0,4.0)
  building.mesh = block
  building.position = Vector3(88.0 + float(i)*12.0,1.5,91.0)
  var material := StandardMaterial3D.new()
  material.albedo_color = [Color(0.28,0.35,0.58),Color(0.35,0.22,0.48),Color(0.18,0.42,0.48)][i]
  material.emission_enabled = true
  material.emission = material.albedo_color * 0.18
  building.material_override = material
  add_child(building)
 var portal := MeshInstance3D.new()
 var ring := TorusMesh.new()
 ring.inner_radius = 2.0
 ring.outer_radius = 2.25
 portal.mesh = ring
 portal.position = Vector3(100,0.08,112)
 var portal_mat := StandardMaterial3D.new()
 portal_mat.albedo_color = Color(0.15,0.7,1.0)
 portal_mat.emission_enabled = true
 portal_mat.emission = Color(0.05,0.35,1.0)
 portal.material_override = portal_mat
 add_child(portal)

func enter_sanctuary() -> void:
 if sanctuary_active: return
 sanctuary_origin = player.global_position
 player.call("cancel_auto_move")
 player.velocity = Vector3.ZERO
 player.global_position = Vector3(100,0.15,100)
 sanctuary_active = true
 SanctuarySystem.record_visit()
 show_notice("已进入个人圣域：可通过圣域面板领取离线收益、升级设施")

func leave_sanctuary() -> void:
 if not sanctuary_active: return
 player.call("cancel_auto_move")
 player.velocity = Vector3.ZERO
 player.global_position = sanctuary_origin
 sanctuary_active = false
 show_notice("已返回银河竞技场")

func apply_ability_effect(class_id: String, ability: Dictionary, reach: float) -> void:
    if not is_instance_valid(player):
        return
    var ability_id := str(ability.get("id", ""))
    if not SkillSystem.is_ability_available_for_cast(class_id, ability_id):
        return
    var ability_type := str(ability.get("type", ""))
    var ability_role := str(ability.get("role", ""))
    var ability_name := str(ability.get("name", ""))
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var affected := 0
    var status := ""
    var status_duration := 3.0
    var status_power := 0.0

    # Resolve combat behavior from authored skill type/role instead of relying
    # on a small handful of hard-coded skill names.
    if "冻结" in ability_type or "冰" in ability_type or "冰结" in ability_name or "禁锢" in ability_type or "束缚" in ability_type:
        status = "freeze"
        status_duration = 2.2
    elif "灼烧" in ability_type or "火" in ability_type or "烈焰" in ability_name or "引爆" in ability_type:
        status = "burn"
        status_duration = 4.5
        status_power = maxf(2.0, attack_power * 0.14)
    elif "削弱" in ability_type or "精神" in ability_type or "虚弱" in ability_name or "破防" in ability_type or "破甲" in ability_type or "易伤" in ability_type:
        status = "weaken"
        status_duration = 4.0
        status_power = 0.26 if ("易伤" in ability_type or "破甲" in ability_type) else 0.20
    elif "领域" in ability_type or "控场" in ability_type or "音波" in ability_type or "陷阱" in ability_type or "牵制" in ability_type or "减速" in ability_role or "混乱" in ability_type or "干扰" in ability_type:
        status = "slow"
        status_duration = 3.5
        status_power = 0.30
    elif "控制" in ability_role or "打断" in ability_type:
        status = "slow"
        status_duration = 2.0
        status_power = 0.18

    var is_support_ability: bool = SkillSystem.is_support_ability(ability)
    var effect_profile: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var delayed_actor_delivery := SkillSystem.uses_delayed_actor_delivery(ability)

    # Core classes retain their signature control identities.
    if not is_support_ability and class_id == "tenmou":
        status = "weaken"
        status_duration = maxf(status_duration, 2.8)
        status_power = maxf(status_power, 0.18)
    elif not is_support_ability and class_id == "lyra":
        status = "slow"
        status_duration = maxf(status_duration, 3.0)
        status_power = maxf(status_power, 0.22)

    var is_area := (
        "范围" in ability_role or "群体" in ability_role or "群攻" in ability_role or
        "领域" in ability_type or "震地" in ability_type or "奥义" in ability_type or
        "扩散" in ability_type or "弹射" in ability_type or "直线" in ability_role
    )
    var max_distance := reach + (1.5 if is_area else 0.5)
    for enemy in enemies.duplicate():
        if delayed_actor_delivery:
            continue
        if not is_instance_valid(enemy) or float(enemy.get("health")) <= 0.0:
            continue
        var offset: Vector3 = enemy.global_position - player.global_position
        var distance := offset.length()
        if distance > max_distance:
            continue
        if not is_area and distance > 0.1:
            var forward := -player.global_transform.basis.z
            if forward.dot(offset.normalized()) < -0.05:
                continue

        var impacted := false
        if status != "" and enemy.has_method("apply_status_effect"):
            enemy.call("apply_status_effect", status, status_duration, status_power)
            impacted = true

        if ("牵引" in ability_type or "拉拽" in ability_name) and enemy.has_method("apply_hit_reaction"):
            var pull: Vector3 = player.global_position - enemy.global_position
            pull.y = 0.0
            if pull.length_squared() > 0.001:
                enemy.call("apply_hit_reaction", pull.normalized(), 6.0, 0.0, 0.45)
                impacted = true
        elif ("击退" in ability_type or "冲击" in ability_type or "震地" in ability_type) and enemy.has_method("apply_hit_reaction"):
            var push: Vector3 = enemy.global_position - player.global_position
            push.y = 0.0
            if push.length_squared() > 0.001:
                enemy.call("apply_hit_reaction", push.normalized(), 7.0, 1.2, 0.5)
                impacted = true
        elif ("挑空" in ability_type or "空袭" in ability_type) and enemy.has_method("apply_hit_reaction"):
            enemy.call("apply_hit_reaction", offset.normalized(), 4.0, 3.2, 0.55)
            impacted = true
        elif ("打断" in ability_type or class_id == "lyra") and not is_support_ability and enemy.has_method("apply_hit_reaction"):
            enemy.call("apply_hit_reaction", offset.normalized(), 1.5, 0.0, 0.65)
            impacted = true
        elif class_id == "tenmou" and not is_support_ability and enemy.has_method("apply_hit_reaction"):
            enemy.call("apply_hit_reaction", offset.normalized(), 2.8, 0.0, 0.65)
            impacted = true

        if not is_support_ability:
            var extra_hits: int = int(effect_profile.get("extra_hits", 0))
            var extra_hit_ratio: float = float(effect_profile.get("extra_hit_ratio", 0.0))
            var follow_up_multiplier: float = 1.0
            if enemy.has_method("is_controlled") and bool(enemy.call("is_controlled")):
                follow_up_multiplier += float(effect_profile.get("controlled_bonus", 0.0))
            var max_enemy_health: float = maxf(1.0, float(enemy.get("max_health")))
            var enemy_health: float = float(enemy.get("health"))
            var execute_threshold: float = float(effect_profile.get("execute_threshold", 0.0))
            if execute_threshold > 0.0 and enemy_health / max_enemy_health <= execute_threshold:
                follow_up_multiplier += float(effect_profile.get("execute_bonus", 0.0))
            var follow_up_damage: float = attack_power * extra_hit_ratio * follow_up_multiplier * SkillSystem.get_skill_damage_multiplier(class_id)
            for hit_index in range(extra_hits):
                if float(enemy.get("health")) <= 0.0:
                    break
                if follow_up_damage > 0.0 and enemy.has_method("take_damage"):
                    enemy.call("take_damage", follow_up_damage, player.global_position)
                    impacted = true
            var stagger_bonus: float = float(effect_profile.get("stagger_bonus", 0.0))
            if stagger_bonus > 0.0 and enemy.has_method("apply_hit_reaction"):
                enemy.call("apply_hit_reaction", offset.normalized(), 3.5 + stagger_bonus * 4.0, 0.8 if str(effect_profile.get("action", "")) == "throw" else 0.0, 0.35 + stagger_bonus)
                impacted = true

        if impacted:
            affected += 1

    if "防御" in ability_type or "护盾" in ability_type or "屏障" in ability_type or "守护" in ability_type or "格挡" in ability_type or "霸体" in ability_type or "减伤" in ability_type or "保命" in ability_type:
        player.call("apply_temporary_buff", 0.0, 0.42 if "霸体" not in ability_type else 0.28, 5.0)
    if "治疗" in ability_type or "恢复" in ability_type or "复苏" in ability_type or "治疗" in ability_role or "恢复" in ability_role:
        player.health = minf(player.max_health, player.health + player.max_health * (0.38 if "复苏" in ability_type else 0.28))
        player.cosmos = minf(player.max_cosmos, player.cosmos + 15.0)
    if "回能" in ability_type or "资源" in ability_type:
        player.cosmos = minf(player.max_cosmos, player.cosmos + 28.0)
    if "增益" in ability_type or "狂怒" in ability_type or "被动强化" in ability_type or "强化" in ability_type or "蓄力" in ability_type:
        player.call("apply_temporary_buff", 0.25, 0.0, 5.5)
    if "闪避" in ability_type or "替身" in ability_type or "脱身" in ability_type:
        player.invulnerable = maxf(player.invulnerable, 0.85)
        player.velocity = -player.global_transform.basis.z * 7.0
    if "冲锋" in ability_type or "突进" in ability_type or "机动" in ability_type or "位移" in ability_type or "突刺" in ability_type:
        player.velocity = -player.global_transform.basis.z * 10.0
        player.invulnerable = maxf(player.invulnerable, 0.3)
    if "反击" in ability_type or "反制" in ability_type:
        player.call("apply_temporary_buff", 0.12, 0.35, 2.5)

    match str(effect_profile.get("action", "strike")):
        "summon":
            _spawn_skill_summon(class_id, ability)
        "field":
            _spawn_skill_field(class_id, ability, false)
        "trap":
            _spawn_skill_field(class_id, ability, true)
        "homing_projectile":
            _spawn_skill_projectile(class_id, ability, true)
        "projectile":
            _spawn_skill_projectile(class_id, ability, false)
    if affected > 0:
        show_notice("%s生效：影响 %d 名敌人" % [ability_name, affected])
    elif is_support_ability or "增益" in ability_type or "突进" in ability_type or "位移" in ability_type or "冲锋" in ability_type or "蓄力" in ability_type or "反击" in ability_type or "反制" in ability_type:
        show_notice(ability_name + "：自身效果已生效")
    if not delayed_actor_delivery and str(RPGState.CLASS_DATA.get(class_id, {}).get("tier", "")) == "神明":
        _apply_divine_signature(class_id, ability, max_distance)

func _get_ability_actor_damage(class_id: String, damage_ratio: float) -> float:
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var level_scale := 1.0 + float(SkillSystem.get_skill_level(class_id) - 1) * 0.06
    var cosmos_scale := 1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))
    var temporary_bonus := float(player.get("temporary_damage_bonus")) if is_instance_valid(player) else 0.0
    var base_damage := 10.0 + attack_power * float(class_data.get("damage", 1.5)) * level_scale
    return maxf(1.0, base_damage * damage_ratio * SkillSystem.get_skill_damage_multiplier(class_id) * cosmos_scale * (1.0 + temporary_bonus))

func _spawn_skill_summon(class_id: String, ability: Dictionary) -> void:
    if not is_instance_valid(player):
        return
    var existing := get_tree().get_nodes_in_group("skill_summons")
    if existing.size() >= 2:
        var oldest: Node = existing[0]
        var oldest_age := float(oldest.get("age"))
        for summon in existing:
            if float(summon.get("age")) > oldest_age:
                oldest = summon
                oldest_age = float(summon.get("age"))
        oldest.queue_free()
    var summon := Node3D.new()
    summon.set_script(SkillSummonScript)
    summon.set("game", self)
    summon.set("owner_player", player)
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var visual_profile: Dictionary = SkillVisualCatalogScript.get_profile(class_id, ability)
    var summon_profile: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var summon_power := _get_ability_actor_damage(class_id, float(summon_profile.get("summon_damage_ratio", 0.72)))
    summon.set("summon_damage", maxf(4.0, summon_power))
    summon.set("life_time", float(summon_profile.get("summon_lifetime", 9.0)))
    summon.set("summon_color", visual_profile.get("color", class_data.get("color", Color(0.35, 0.8, 1.0))))
    summon.global_position = player.global_position + (-player.global_transform.basis.z * 1.5) + Vector3.UP * 1.8
    add_child(summon)
    show_notice(str(ability.get("name", "召唤技能")) + "：召唤灵体加入战斗")

func _spawn_skill_field(class_id: String, ability: Dictionary, is_trap: bool) -> void:
    if not is_instance_valid(player):
        return
    var active_fields := get_tree().get_nodes_in_group("skill_fields")
    if active_fields.size() >= 3:
        active_fields[0].queue_free()
    var field := Node3D.new()
    field.set_script(SkillFieldScript)
    var profile: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var visual_profile: Dictionary = SkillVisualCatalogScript.get_profile(class_id, ability)
    field.set("game", self)
    field.set("owner_player", player)
    field.set("radius", float(profile.get("field_radius", 4.0)))
    field.set("lifetime", float(profile.get("field_lifetime", 5.0)))
    field.set("tick_interval", float(profile.get("field_tick_interval", 0.8)))
    field.set("damage", _get_ability_actor_damage(class_id, float(profile.get("field_damage_ratio", 0.3))))
    field.set("mode", "trap" if is_trap else "field")
    field.set("field_color", visual_profile.get("color", class_data.get("color", Color(0.35, 0.75, 1.0))))
    field.set("field_shape", visual_profile.get("shape", "ring"))
    var ability_type := str(ability.get("type", ""))
    field.set("status", "freeze" if "冰" in ability_type or "冻结" in ability_type else ("burn" if "灼烧" in ability_type or "火" in ability_type else "slow"))
    field.set("status_duration", 1.8 if is_trap else 1.35)
    field.set("status_power", 0.24 if is_trap else 0.18)
    field.global_position = player.global_position + (-player.global_transform.basis.z * (2.2 if is_trap else 1.5))
    add_child(field)
    show_notice(str(ability.get("name", "领域技能")) + ("：陷阱已布置" if is_trap else "：领域已展开"))

func _spawn_skill_projectile(class_id: String, ability: Dictionary, homing: bool = true) -> void:
    if not is_instance_valid(player):
        return
    var active_projectiles := get_tree().get_nodes_in_group("skill_projectiles")
    if active_projectiles.size() >= 6:
        active_projectiles[0].queue_free()
    var projectile := Node3D.new()
    projectile.set_script(SkillProjectileScript)
    var profile: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var visual_profile: Dictionary = SkillVisualCatalogScript.get_profile(class_id, ability)
    projectile.set("game", self)
    projectile.set("owner_player", player)
    projectile.set("speed", float(profile.get("projectile_speed", 12.0)))
    projectile.set("homing_enabled", homing)
    var ability_type := str(ability.get("type", ""))
    projectile.set("status", "slow" if homing else "")
    if "火" in ability_type or "灼烧" in ability_type or "烈焰" in str(ability.get("name", "")):
        projectile.set("status", "burn")
        projectile.set("status_duration", 3.0)
        projectile.set("status_power", maxf(1.5, float(RPGState.get_combat_stats().get("attack", 14.0)) * 0.08))
    elif "冻结" in ability_type or "冰" in ability_type:
        projectile.set("status", "freeze")
        projectile.set("status_duration", 1.2)
        projectile.set("status_power", 0.0)
    elif "削弱" in ability_type or "破甲" in ability_type or "易伤" in ability_type:
        projectile.set("status", "weaken")
        projectile.set("status_duration", 2.5)
        projectile.set("status_power", 0.14)
    projectile.set("damage", _get_ability_actor_damage(class_id, float(profile.get("projectile_damage_ratio", 1.15))))
    projectile.set("projectile_color", visual_profile.get("color", class_data.get("color", Color(0.45, 0.8, 1.0))))
    projectile.set("projectile_shape", visual_profile.get("shape", "star"))
    projectile.set("impact_scale", visual_profile.get("impact_scale", 1.0))
    projectile.global_position = player.global_position + (-player.global_transform.basis.z * 1.2) + Vector3.UP * 1.2
    add_child(projectile)
    projectile.look_at(projectile.global_position - player.global_transform.basis.z, Vector3.UP)
    show_notice(str(ability.get("name", "技能")) + ("：追踪攻击已发射" if homing else "：远程攻击已发射"))

func _apply_divine_signature(class_id: String, ability: Dictionary, max_distance: float) -> void:
    var ability_id := str(ability.get("id", ""))
    var ability_type := str(ability.get("type", ""))
    var ability_name := str(ability.get("name", "神权技能"))
    var is_support: bool = SkillSystem.is_support_ability(ability) or "增益" in ability_type
    var signature_profile: Dictionary = SkillSystem.get_divine_signature_profile(class_id)
    var mark := str(signature_profile.get("mark", ""))
    var status := str(signature_profile.get("status", ""))
    var duration := float(signature_profile.get("duration", 4.0))
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var power := maxf(2.0, attack_power * float(signature_profile.get("status_power", 0.18))) if class_id == "apollo" else float(signature_profile.get("status_power", 0.18))
    if is_support:
        var support_profile: Dictionary = SkillSystem.get_divine_support_profile(class_id)
        if not support_profile.is_empty():
            var shield_ratio := float(support_profile.get("shield_ratio", 0.0))
            var heal_ratio := float(support_profile.get("heal_ratio", 0.0))
            var damage_bonus := float(support_profile.get("damage_bonus", 0.0))
            var damage_reduction := float(support_profile.get("damage_reduction", 0.0))
            var support_duration := float(support_profile.get("duration", 5.0))
            var mobility := float(support_profile.get("mobility", 0.0))
            if shield_ratio > 0.0:
                player.call("apply_divine_guard", shield_ratio, support_duration)
            if heal_ratio > 0.0:
                player.health = minf(player.max_health, player.health + player.max_health * heal_ratio)
            player.call("apply_temporary_buff", damage_bonus, damage_reduction, support_duration)
            if mobility > 0.0:
                player.velocity += -player.global_transform.basis.z * mobility
            show_notice("%s：神权支援效果已激活" % str(RPGState.CLASS_DATA.get(class_id, {}).get("name", class_id)))
        return
    var affected := 0
    var chain_applied := false
    var damage_ratio := float(signature_profile.get("damage_ratio", 0.0))
    var execute_threshold := float(signature_profile.get("execute_threshold", 0.0))
    var execute_ratio := float(signature_profile.get("execute_ratio", 0.0))
    var secondary_status := str(signature_profile.get("secondary_status", ""))
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy) or float(enemy.get("health")) <= 0.0:
            continue
        if enemy.global_position.distance_to(player.global_position) > max_distance:
            continue
        if status != "" and enemy.has_method("apply_status_effect"):
            enemy.call("apply_status_effect", status, duration, power)
        if secondary_status != "" and enemy.has_method("apply_status_effect"):
            enemy.call("apply_status_effect", secondary_status, float(signature_profile.get("secondary_duration", 1.0)), float(signature_profile.get("secondary_power", 0.0)))
        if enemy.has_method("apply_divine_mark"):
            var mark_power := float(signature_profile.get("mark_power", 0.06))
            if ability_id.ends_with("_6") or "奥义" in ability_type:
                mark_power = minf(0.18, mark_power + 0.03)
            enemy.call("apply_divine_mark", mark, duration, mark_power)
        var bonus_ratio := damage_ratio
        if execute_threshold > 0.0 and float(enemy.get("health")) / maxf(1.0, float(enemy.get("max_health"))) <= execute_threshold:
            bonus_ratio += execute_ratio
        if bonus_ratio > 0.0 and enemy.has_method("take_damage"):
            enemy.call("take_damage", attack_power * bonus_ratio, player.global_position)
        var pull_force := float(signature_profile.get("pull_force", 0.0))
        var knockback_force := float(signature_profile.get("knockback_force", 0.0))
        var stagger_force := float(signature_profile.get("stagger_force", 0.0))
        if enemy.has_method("apply_hit_reaction"):
            if pull_force > 0.0:
                var pull_direction: Vector3 = player.global_position - enemy.global_position
                pull_direction.y = 0.0
                if pull_direction.length_squared() > 0.001:
                    enemy.call("apply_hit_reaction", pull_direction.normalized(), pull_force, 0.0, 0.45)
            elif knockback_force > 0.0:
                var push_direction: Vector3 = enemy.global_position - player.global_position
                push_direction.y = 0.0
                if push_direction.length_squared() > 0.001:
                    enemy.call("apply_hit_reaction", push_direction.normalized(), knockback_force, 0.7, 0.45)
            elif stagger_force > 0.0:
                enemy.call("apply_hit_reaction", Vector3.ZERO, stagger_force, 0.0, 0.5)
        if not chain_applied and float(signature_profile.get("chain_ratio", 0.0)) > 0.0:
            var nearest_chain_target: Node3D
            var nearest_chain_distance := max_distance
            for candidate in enemies:
                if not is_instance_valid(candidate) or candidate == enemy or float(candidate.get("health")) <= 0.0:
                    continue
                var chain_distance := candidate.global_position.distance_to(enemy.global_position)
                if chain_distance < nearest_chain_distance:
                    nearest_chain_target = candidate
                    nearest_chain_distance = chain_distance
            if is_instance_valid(nearest_chain_target) and nearest_chain_target.has_method("take_damage"):
                nearest_chain_target.call("take_damage", attack_power * float(signature_profile.get("chain_ratio", 0.0)), player.global_position)
                chain_applied = true
        affected += 1
    if affected > 0:
        var heal_ratio := float(signature_profile.get("heal_ratio", 0.0))
        if heal_ratio > 0.0:
            player.health = minf(player.max_health, player.health + player.max_health * heal_ratio)
        var buff_damage := float(signature_profile.get("buff_damage", 0.0))
        var buff_reduction := float(signature_profile.get("buff_reduction", 0.0))
        if buff_damage > 0.0 or buff_reduction > 0.0:
            player.call("apply_temporary_buff", buff_damage, buff_reduction, float(signature_profile.get("buff_duration", 4.0)))
        var mobility := float(signature_profile.get("mobility", 0.0))
        if mobility > 0.0:
            player.velocity += -player.global_transform.basis.z * mobility
        show_notice("%s：%s神权效果命中 %d 个目标" % [ability_name, str(signature_profile.get("effect", mark)), affected])
