extends Node3D
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HUDScript = preload("res://scripts/hud.gd")
const GuideNpcScript = preload("res://scripts/guide_npc.gd")
const TeleportPointScript = preload("res://scripts/teleport_point.gd")
const FollowerScript = preload("res://scripts/follower_actor.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var enemies: Array[Node3D] = []
var guide_npc: Node3D
var teleport_point: Node3D
var sanctuary_active := false
var sanctuary_origin := Vector3(0, 0.15, 7)
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
    _spawn_enemy(Vector3(-4, 0.1, -3), false)
    _spawn_enemy(Vector3(4, 0.1, -4), false)
    _spawn_enemy(Vector3(0, 0.1, -9), true)
    _spawn_guide_npc()
    _spawn_teleport_point()
    hud = HUDScript.new()
    hud.set("game", self)
    add_child(hud)
    hud.call("set_notice", "训练开始：移动并击败两名敌人与 Boss。")
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
        add_child(ring)
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
    if str(campaign_mission.get("id", "")) == "gw_001":
        CampaignManager.add_objective_progress("talk_guide", 1)
        if CampaignManager.can_complete_active_mission():
            var campaign_result: Dictionary = CampaignManager.complete_active_mission()
            if bool(campaign_result.get("success", false)):
                show_notice("剧情任务完成：" + str(campaign_mission.get("name", "")))
    if is_instance_valid(hud):
        hud.call("show_dialogue", dialogue)
    show_notice(str(dialogue.get("action", "")))

func _spawn_enemy(at: Vector3, boss: bool) -> void:
    var enemy := CharacterBody3D.new()
    enemy.set_script(EnemyScript)
    enemy.set("game", self)
    enemy.set("is_boss", boss)
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
            enemy.call("take_damage", damage)
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
        enemy.call("take_damage", damage)
        if is_instance_valid(enemy) and enemy.has_method("apply_hit_reaction"):
            enemy.call("apply_hit_reaction", offset.normalized(), knockback, launch, stagger)


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
    var campaign_mission: Dictionary = CampaignManager.get_active_mission()
    var campaign_id := str(campaign_mission.get("id", ""))
    if campaign_id == "gw_002" and not defeated_boss:
        CampaignManager.add_objective_progress("defeat_training_enemy", 1)
    elif campaign_id == "gw_003" and defeated_boss:
        CampaignManager.add_objective_progress("defeat_training_boss", 1)
    if CampaignManager.can_complete_active_mission():
        var campaign_result: Dictionary = CampaignManager.complete_active_mission()
        if bool(campaign_result.get("success", false)):
            show_notice("剧情任务完成：" + str(campaign_mission.get("name", "")))
    QuestManager.on_enemy_defeated(defeated_boss)
    CollectionSystem.record_enemy_defeat(bool(enemy.get("is_boss")) )
    CombatSessionManager.record_enemy_defeated(defeated_boss)
    enemies.erase(enemy)
    var exp_reward := 90 if enemy.get("is_boss") else 30
    var coin_reward := 120 if enemy.get("is_boss") else 40
    var level_gains: int = RPGState.add_exp(exp_reward)
    RPGState.add_currency(coin_reward)
    var drops: Array[Dictionary] = LootManager.roll_enemy_drops(defeated_boss, int(RPGState.profile.get("level", 1)))
    refresh_player_stats()
    var reward_text := "获得经验 %d、星币 %d" % [exp_reward, coin_reward]
    for drop in drops:
        reward_text += "、%s×%d" % [str(drop.get("name", "物品")), int(drop.get("quantity", 1))]
    if level_gains > 0:
        reward_text += "，等级提升 %d 级！" % level_gains
    show_notice(reward_text)
    if defeated_boss:
        var battle_summary: Dictionary = CombatSessionManager.finish_encounter()
        if is_instance_valid(hud) and hud.has_method("show_battle_result"):
            hud.call("show_battle_result", battle_summary, {"exp": exp_reward, "coins": coin_reward})
func update_hud() -> void:
    if is_instance_valid(hud) and is_instance_valid(player):
        hud.call("set_status", player.get("health"), player.get("max_health"), player.get("cosmos"), player.get("max_cosmos"), player.get("skill_cd"), player.get("burst_cd"))
        hud.call("set_enemy_count", enemies.size())
        hud.call("set_quest_text", QuestManager.get_tracker_text())
        var boss_hp := 0.0
        var boss_max := 1.0
        for enemy in enemies:
            if is_instance_valid(enemy) and enemy.get("is_boss"):
                boss_hp = enemy.get("health")
                boss_max = enemy.get("max_health")
                break
        hud.call("set_boss_status", boss_hp, boss_max)
func spawn_effect(at: Vector3, effect_color: Color, radius: float) -> void:
    var effect := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.5
    sphere.height = 1.0
    effect.mesh = sphere
    effect.position = at
    effect.scale = Vector3.ONE * 0.15
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(effect_color.r, effect_color.g, effect_color.b, 0.48)
    material.emission_enabled = true
    material.emission = effect_color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    effect.material_override = material
    add_child(effect)
    var tween := create_tween()
    tween.tween_property(effect, "scale", Vector3.ONE * radius, 0.22)
    get_tree().create_timer(0.32).timeout.connect(func():
        if is_instance_valid(effect):
            effect.queue_free()
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
    var ability_type := str(ability.get("type", ""))
    var ability_role := str(ability.get("role", ""))
    var ability_name := str(ability.get("name", ""))
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var affected := 0
    var status := ""
    var status_duration := 3.0
    var status_power := 0.0

    if "冻结" in ability_type or "冰" in ability_type or "冰结" in ability_name:
        status = "freeze"
        status_duration = 2.6
    elif "灼烧" in ability_type or "火" in ability_type or "烈焰" in ability_name:
        status = "burn"
        status_duration = 5.0
        status_power = maxf(2.0, attack_power * 0.16)
    elif "削弱" in ability_type or "精神" in ability_type or "虚弱" in ability_name:
        status = "weaken"
        status_duration = 4.5
        status_power = 0.3
    elif "领域" in ability_type or "控场" in ability_type or "音波" in ability_type:
        status = "slow"
        status_duration = 3.5
        status_power = 0.32

    var is_support_ability := "防御" in ability_type or "护盾" in ability_type or "守护" in ability_type or "格挡" in ability_type or "霸体" in ability_type or "治疗" in ability_type or "恢复" in ability_type or "复苏" in ability_type or "回能" in ability_type or "资源" in ability_type or "净化" in ability_type
    # 天猛：冥斗士重击压制；天琴：以音律迟缓并打断敌人。辅助技能不附带敌方控制。
    if not is_support_ability and class_id == "tenmou":
        status = "weaken"
        status_duration = maxf(status_duration, 2.8)
        status_power = maxf(status_power, 0.18)
    elif not is_support_ability and class_id == "lyra":
        status = "slow"
        status_duration = maxf(status_duration, 3.0)
        status_power = maxf(status_power, 0.22)

    var is_area := "范围" in ability_role or "群体" in ability_role or "领域" in ability_type or "震地" in ability_type or "奥义" in ability_type
    var max_distance := reach + (1.5 if is_area else 0.5)
    for enemy in enemies.duplicate():
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

        if "牵引" in ability_type or "拉拽" in ability_name:
            var pull: Vector3 = player.global_position - enemy.global_position
            pull.y = 0.0
            if enemy.has_method("apply_hit_reaction"):
                enemy.call("apply_hit_reaction", pull.normalized(), 6.0, 0.0, 0.45)
                impacted = true
        elif "击退" in ability_type or "冲击" in ability_type or "震地" in ability_type:
            var push: Vector3 = enemy.global_position - player.global_position
            push.y = 0.0
            if enemy.has_method("apply_hit_reaction"):
                enemy.call("apply_hit_reaction", push.normalized(), 7.0, 1.2, 0.5)
                impacted = true
        elif ("打断" in ability_type or (class_id == "lyra" and not is_support_ability)) and enemy.has_method("apply_hit_reaction"):
            var stagger := 0.9 if "打断" in ability_type else 0.55
            enemy.call("apply_hit_reaction", offset.normalized(), 1.5, 0.0, stagger)
            impacted = true
        elif class_id == "tenmou" and enemy.has_method("apply_hit_reaction"):
            enemy.call("apply_hit_reaction", offset.normalized(), 2.8, 0.0, 0.65)
            impacted = true

        if impacted:
            affected += 1

    if "防御" in ability_type or "护盾" in ability_type or "守护" in ability_type or "格挡" in ability_type or "霸体" in ability_type:
        player.call("apply_temporary_buff", 0.0, 0.42 if "霸体" not in ability_type else 0.28, 5.0)
    if "治疗" in ability_type or "恢复" in ability_type or "复苏" in ability_type:
        player.health = minf(player.max_health, player.health + player.max_health * 0.32)
        player.cosmos = minf(player.max_cosmos, player.cosmos + 15.0)
    if "回能" in ability_type or "资源" in ability_type:
        player.cosmos = minf(player.max_cosmos, player.cosmos + 28.0)
    if "增益" in ability_type or "狂怒" in ability_type or "召唤" in ability_type or "被动强化" in ability_type:
        player.call("apply_temporary_buff", 0.25, 0.0, 5.5)
    if "闪避" in ability_type or "替身" in ability_type:
        player.invulnerable = maxf(player.invulnerable, 0.85)
        player.velocity = -player.global_transform.basis.z * 7.0
    if "冲锋" in ability_type or "突进" in ability_type or "机动" in ability_type or "位移" in ability_type:
        player.velocity = -player.global_transform.basis.z * 10.0
        player.invulnerable = maxf(player.invulnerable, 0.3)

    if affected > 0:
        show_notice("%s生效：影响 %d 名敌人" % [ability_name, affected])
    elif "防御" in ability_type or "护盾" in ability_type or "守护" in ability_type or "治疗" in ability_type or "恢复" in ability_type or "增益" in ability_type or "闪避" in ability_type or "突进" in ability_type or "位移" in ability_type or "回能" in ability_type or "资源" in ability_type or "霸体" in ability_type:
        show_notice(ability_name + "：自身效果已生效")
    if str(RPGState.CLASS_DATA.get(class_id, {}).get("tier", "")) == "神明":
        _apply_divine_signature(class_id, ability, max_distance)

func _apply_divine_signature(class_id: String, ability: Dictionary, max_distance: float) -> void:
    var ability_id := str(ability.get("id", ""))
    var ability_type := str(ability.get("type", ""))
    var ability_name := str(ability.get("name", "神权技能"))
    var is_support := "防御" in ability_type or "护盾" in ability_type or "治疗" in ability_type or "复苏" in ability_type or "增益" in ability_type
    var mark := ""
    var status := ""
    var duration := 4.0
    var power := 0.18
    match class_id:
        "apollo", "abel":
            mark = "solar"
            status = "burn"
            duration = 6.0
            power = 0.32
        "athena":
            mark = "aegis"
            status = "weaken"
            duration = 4.5
            power = 0.18
        "artemis", "pallas":
            mark = "lunar"
            status = "slow"
            duration = 4.5
            power = 0.42
        "hades", "lucifer":
            mark = "soul"
            status = "weaken"
            duration = 5.0
            power = 0.28
        "poseidon":
            mark = "tidal"
            status = "slow"
            duration = 4.0
            power = 0.30
        "zeus", "ares":
            mark = "storm"
            status = "burn"
            duration = 4.0
            power = 0.24
        "hypnos":
            mark = "dream"
            status = "slow"
            duration = 5.0
            power = 0.48
        "thanatos":
            mark = "death"
            status = "weaken"
            duration = 5.0
            power = 0.32
        "odin":
            mark = "rune"
            status = "weaken"
            duration = 3.5
            power = 0.18
        "eris":
            mark = "discord"
            status = "weaken"
            duration = 4.5
            power = 0.24
        "saturn", "chronos":
            mark = "time"
            status = "slow"
            duration = 4.0
            power = 0.38
        "hera":
            mark = "command"
            status = "weaken"
            duration = 4.0
            power = 0.20
        "demeter":
            mark = "harvest"
            status = "slow"
            duration = 4.0
            power = 0.26
        "hestia", "hephaestus":
            mark = "forge"
            status = "burn"
            duration = 4.0
            power = 0.20
        "hermes":
            mark = "swift"
            status = "slow"
            duration = 2.5
            power = 0.20
        "aphrodite":
            mark = "charm"
            status = "weaken"
            duration = 4.5
            power = 0.26
    if is_support:
        if class_id in ["hestia", "athena", "hera"]:
            player.health = minf(player.max_health, player.health + player.max_health * 0.08)
        if class_id in ["zeus", "ares", "hermes"]:
            player.velocity += -player.global_transform.basis.z * 2.5
        return
    var affected := 0
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy) or float(enemy.get("health")) <= 0.0:
            continue
        if enemy.global_position.distance_to(player.global_position) > max_distance:
            continue
        if status != "" and enemy.has_method("apply_status_effect"):
            enemy.call("apply_status_effect", status, duration, power)
        if enemy.has_method("apply_divine_mark"):
            enemy.call("apply_divine_mark", mark, duration, 0.12 if ability_id.ends_with("_6") or "奥义" in ability_type else 0.06)
        affected += 1
    if affected > 0:
        show_notice("%s：%s神印命中 %d 个目标" % [ability_name, mark, affected])
