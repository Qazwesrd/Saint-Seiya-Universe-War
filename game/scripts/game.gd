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

func on_enemy_defeated(enemy: Node3D) -> void:
    QuestManager.on_enemy_defeated(bool(enemy.get("is_boss")))
    CollectionSystem.record_enemy_defeat(bool(enemy.get("is_boss")) )
    enemies.erase(enemy)
    var exp_reward := 90 if enemy.get("is_boss") else 30
    var coin_reward := 120 if enemy.get("is_boss") else 40
    var level_gains: int = RPGState.add_exp(exp_reward)
    RPGState.add_currency(coin_reward)
    refresh_player_stats()
    var reward_text := "获得经验 %d、星币 %d" % [exp_reward, coin_reward]
    if level_gains > 0:
        reward_text += "，等级提升 %d 级！" % level_gains
    show_notice(reward_text)
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
