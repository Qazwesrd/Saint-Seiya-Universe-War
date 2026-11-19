extends Node3D
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HUDScript = preload("res://scripts/hud.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var enemies: Array[Node3D] = []
func _ready() -> void:
    _build_world()
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.game = self
    player.position = Vector3(0, 0.15, 7)
    add_child(player)
    _spawn_enemy(Vector3(-4, 0.1, -3), false)
    _spawn_enemy(Vector3(4, 0.1, -4), false)
    _spawn_enemy(Vector3(0, 0.1, -9), true)
    hud = HUDScript.new()
    hud.game = self
    add_child(hud)
    hud.set_notice("训练开始：移动并击败两名敌人与 Boss。")
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
func _spawn_enemy(at: Vector3, boss: bool) -> void:
    var enemy := CharacterBody3D.new()
    enemy.set_script(EnemyScript)
    enemy.game = self
    enemy.is_boss = boss
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
            enemy.take_damage(damage)
func on_enemy_defeated(enemy: Node3D) -> void:
    enemies.erase(enemy)
    show_notice("目标已击败，剩余：" + str(enemies.size()) if not enemies.is_empty() else "训练完成！所有敌人和 Boss 均已击败。")
func update_hud() -> void:
    if is_instance_valid(hud) and is_instance_valid(player):
        hud.set_status(player.health, player.max_health, player.cosmos, player.max_cosmos)
        hud.set_enemy_count(enemies.size())
func show_notice(message: String) -> void:
    if is_instance_valid(hud):
        hud.set_notice(message)
