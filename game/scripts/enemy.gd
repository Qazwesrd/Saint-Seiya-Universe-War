extends CharacterBody3D

enum BrainState { CHASE, WINDUP, RECOVERY, STAGGER, DEAD }

var game: Variant
var is_boss := false
var health := 65.0
var max_health := 65.0
var speed := 2.5
var attack_damage := 7.0
var attack_range := 2.0
var attack_interval := 1.6
var state: BrainState = BrainState.CHASE
var state_timer := 0.0
var attack_cooldown := 0.8
var knockback_velocity := Vector3.ZERO
var display_name := "训练对手"
var body_material: StandardMaterial3D
var telegraph_mesh: MeshInstance3D
var _boss_phase_two := false
var _base_color := Color(0.72, 0.16, 0.22)

func _ready() -> void:
    add_to_group("enemies")
    if is_boss:
        display_name = "竞技场训练 Boss"
        health = 260.0
        max_health = 260.0
        speed = 1.8
        attack_damage = 16.0
        attack_range = 2.8
        attack_interval = 2.2
        _base_color = Color(0.36, 0.08, 0.55)

    var radius := 0.55 if not is_boss else 0.9
    var height := 1.9 if not is_boss else 3.0
    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = radius
    capsule_shape.height = height
    collision.shape = capsule_shape
    collision.position.y = height * 0.5
    add_child(collision)

    var body := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = radius
    capsule_mesh.height = height
    body.mesh = capsule_mesh
    body.position.y = height * 0.5
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = _base_color
    body_material.metallic = 0.4
    body_material.roughness = 0.3
    body_material.emission_enabled = true
    body_material.emission = _base_color * 0.22
    body.material_override = body_material
    add_child(body)

    telegraph_mesh = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = attack_range * 0.72
    ring.outer_radius = attack_range
    telegraph_mesh.mesh = ring
    telegraph_mesh.position.y = 0.06
    var telegraph_material := StandardMaterial3D.new()
    telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    telegraph_material.albedo_color = Color(1.0, 0.18, 0.12, 0.72)
    telegraph_material.emission_enabled = true
    telegraph_material.emission = Color(1.0, 0.06, 0.02)
    telegraph_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    telegraph_mesh.material_override = telegraph_material
    telegraph_mesh.visible = false
    add_child(telegraph_mesh)

func is_targetable() -> bool:
    return state != BrainState.DEAD and health > 0.0 and is_inside_tree()

func _physics_process(delta: float) -> void:
    if state == BrainState.DEAD:
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    state_timer = maxf(0.0, state_timer - delta)
    knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 18.0 * delta)

    var target: Node3D = game.get("player") if is_instance_valid(game) else null
    if not is_instance_valid(target):
        _apply_gravity(delta)
        move_and_slide()
        return

    var offset := target.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO

    if distance > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)

    match state:
        BrainState.CHASE:
            telegraph_mesh.visible = false
            if distance <= attack_range and attack_cooldown <= 0.0:
                _begin_attack()
            else:
                velocity.x = direction.x * speed + knockback_velocity.x
                velocity.z = direction.z * speed + knockback_velocity.z
        BrainState.WINDUP:
            telegraph_mesh.visible = true
            velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
            if state_timer <= 0.0:
                _resolve_attack(target)
        BrainState.RECOVERY:
            telegraph_mesh.visible = false
            velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
            if state_timer <= 0.0:
                state = BrainState.CHASE
        BrainState.STAGGER:
            telegraph_mesh.visible = false
            velocity.x = knockback_velocity.x
            velocity.z = knockback_velocity.z
            if state_timer <= 0.0:
                state = BrainState.CHASE
                body_material.albedo_color = _base_color

    _apply_gravity(delta)
    move_and_slide()

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = minf(velocity.y, 0.0)

func _begin_attack() -> void:
    state = BrainState.WINDUP
    state_timer = 0.68 if is_boss else 0.48
    telegraph_mesh.visible = true
    if is_instance_valid(game):
        game.call("show_notice", display_name + " 正在蓄力攻击！")

func _resolve_attack(target: Node3D) -> void:
    telegraph_mesh.visible = false
    var current_distance := global_position.distance_to(target.global_position)
    if current_distance <= attack_range + 0.35:
        var player_invulnerable := float(target.get("invulnerable")) > 0.0
        target.call("receive_damage", attack_damage)
        if not player_invulnerable and target.has_method("apply_enemy_knockback"):
            var push := target.global_position - global_position
            push.y = 0.0
            if push.length_squared() > 0.001:
                target.call("apply_enemy_knockback", push.normalized(), 7.0 if is_boss else 4.5)
    attack_cooldown = attack_interval * (0.78 if _boss_phase_two else 1.0)
    state = BrainState.RECOVERY
    state_timer = 0.5 if is_boss else 0.34

func take_damage(amount: float) -> void:
    if state == BrainState.DEAD or health <= 0.0:
        return
    health = maxf(0.0, health - maxf(0.0, amount))
    if is_instance_valid(game):
        game.call("spawn_effect", global_position + Vector3(0, 1.0, 0), Color(0.25, 0.78, 1.0), 1.1 if is_boss else 0.65)

    if is_boss and not _boss_phase_two and health <= max_health * 0.5:
        _boss_phase_two = true
        speed *= 1.25
        attack_damage *= 1.25
        _base_color = Color(0.72, 0.12, 0.18)
        body_material.albedo_color = _base_color
        body_material.emission = Color(0.42, 0.025, 0.02)
        if is_instance_valid(game):
            game.call("show_notice", "Boss 进入第二阶段！攻击速度与伤害提升")

    if health <= 0.0:
        state = BrainState.DEAD
        telegraph_mesh.visible = false
        if is_instance_valid(game):
            game.call("on_enemy_defeated", self)
        queue_free()
        return

    var attacker: Node3D = game.get("player") if is_instance_valid(game) else null
    if is_instance_valid(attacker):
        var push := global_position - attacker.global_position
        push.y = 0.0
        if push.length_squared() > 0.001:
            knockback_velocity = push.normalized() * (5.0 if is_boss else 7.0)
    state = BrainState.STAGGER
    state_timer = 0.22 if is_boss else 0.3
    body_material.albedo_color = Color(1.0, 0.78, 0.55)


func apply_hit_reaction(direction: Vector3, force: float, lift: float, stagger_duration: float) -> void:
    if state == BrainState.DEAD:
        return
    # Bosses retain their wind-up armor so their telegraphed attacks cannot be
    # cancelled by every light hit. Heavy finishers still deal normal damage.
    if is_boss and state == BrainState.WINDUP:
        return
    var flat := direction
    flat.y = 0.0
    if flat.length_squared() > 0.001:
        var resistance := 0.28 if is_boss else 1.0
        knockback_velocity = flat.normalized() * force * resistance
    if not is_boss and lift > 0.0:
        velocity.y = maxf(velocity.y, lift)
    state = BrainState.STAGGER
    state_timer = maxf(state_timer, stagger_duration * (1.5 if is_boss else 1.0))
