extends CharacterBody3D
var game: Variant
var move_input := Vector2.ZERO
var health := 100.0
var max_health := 100.0
var cosmos := 100.0
var max_cosmos := 100.0
var attack_cd := 0.0
var skill_cd := 0.0
var burst_cd := 0.0
var dodge_time := 0.0
var invulnerable := 0.0
var locked_target: Node3D
var pivot: Node3D
var body_mat: StandardMaterial3D
func _ready() -> void:
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.43
    shape.height = 1.8
    col.shape = shape
    col.position.y = 0.9
    add_child(col)
    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.4
    mesh.height = 1.75
    body.mesh = mesh
    body.position.y = 0.9
    body_mat = StandardMaterial3D.new()
    body_mat.albedo_color = Color(0.18, 0.52, 0.95)
    body_mat.metallic = 0.55
    body_mat.roughness = 0.28
    body_mat.emission_enabled = true
    body_mat.emission = Color(0.03, 0.12, 0.35)
    body.material_override = body_mat
    add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head.mesh = head_mesh
    head.position.y = 1.95
    head.material_override = body_mat
    add_child(head)
    pivot = Node3D.new()
    pivot.global_position = global_position + Vector3(0, 1.5, 0)
    game.add_child(pivot)
    var arm := SpringArm3D.new()
    arm.spring_length = 7.5
    pivot.add_child(arm)
    var cam := Camera3D.new()
    cam.rotation_degrees.x = -9
    arm.add_child(cam)
    cam.current = true
func set_move_input(value: Vector2) -> void:
    move_input = value.limit_length(1.0)
func _physics_process(delta: float) -> void:
    pivot.global_position = global_position + Vector3(0, 1.5, 0)
    attack_cd = maxf(0.0, attack_cd - delta)
    skill_cd = maxf(0.0, skill_cd - delta)
    burst_cd = maxf(0.0, burst_cd - delta)
    dodge_time = maxf(0.0, dodge_time - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    cosmos = minf(max_cosmos, cosmos + delta * 3.0)
    var input_vec := move_input
    if input_vec.length() < 0.05:
        input_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var basis := pivot.global_transform.basis
    var direction := (basis.x * input_vec.x + (-basis.z) * -input_vec.y)
    direction.y = 0
    direction = direction.normalized()
    var speed := 6.2 * (2.2 if dodge_time > 0.0 else 1.0)
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    velocity.y -= 22.0 * delta
    move_and_slide()
    if direction.length() > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 12.0)
    elif is_instance_valid(locked_target):
        var toward := locked_target.global_position - global_position
        rotation.y = lerp_angle(rotation.y, atan2(-toward.x, -toward.z), delta * 5.0)
    if Input.is_action_just_pressed("ui_accept"): attack()
    if Input.is_action_just_pressed("ui_cancel"): dodge()
    game.call("update_hud")
func attack() -> void:
    if attack_cd > 0.0: return
    attack_cd = 0.42
    _flash(Color(1.0, 0.82, 0.35))
    game.call("damage_nearby", 12.0, 2.8, 120.0)
    game.call("show_notice", "普通攻击！")
func skill() -> void:
    if skill_cd > 0.0 or cosmos < 18.0:
        game.call("show_notice", "小宇宙不足或技能冷却中")
        return
    cosmos -= 18.0
    skill_cd = 3.0
    _flash(Color(0.2, 0.8, 1.0))
    game.call("damage_nearby", 28.0, 7.0, 150.0)
    game.call("show_notice", "天马流星拳！")
func cosmos_burst() -> void:
    if burst_cd > 0.0 or cosmos < 35.0:
        game.call("show_notice", "小宇宙能量不足或正在冷却")
        return
    cosmos -= 35.0
    burst_cd = 8.0
    _flash(Color(1.0, 0.4, 0.12))
    game.call("damage_nearby", 42.0, 5.0, 360.0)
    game.call("show_notice", "小宇宙爆发！")
func dodge() -> void:
    if dodge_time > 0.0: return
    dodge_time = 0.32
    invulnerable = 0.4
    var direction := pivot.global_transform.basis.x * move_input.x + (-pivot.global_transform.basis.z) * -move_input.y
    direction.y = 0
    if direction.length() < 0.1: direction = -global_transform.basis.z
    velocity = direction.normalized() * 15.0
    game.call("show_notice", "闪避！短暂无敌")
func toggle_lock() -> void:
    if is_instance_valid(locked_target):
        locked_target = null
        game.call("show_notice", "已解除锁定")
        return
    var best := 999.0
    for target in get_tree().get_nodes_in_group("enemies"):
        var distance: float = global_position.distance_to(target.global_position)
        if distance < best:
            best = distance
            locked_target = target
    game.call("show_notice", "已锁定最近目标" if is_instance_valid(locked_target) else "附近没有目标")
func receive_damage(amount: float) -> void:
    if invulnerable > 0.0: return
    health = maxf(0.0, health - amount)
    _flash(Color(1.0, 0.12, 0.12))
    if health <= 0.0:
        health = max_health
        global_position = Vector3(0, 0.2, 7)
        game.call("show_notice", "角色倒地，已在训练场复位")
func _flash(color: Color) -> void:
    body_mat.albedo_color = color
    get_tree().create_timer(0.16).timeout.connect(func():
        if is_instance_valid(body_mat):
            body_mat.albedo_color = Color(0.18, 0.52, 0.95)
    )
