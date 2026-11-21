extends CharacterBody3D

const EnemyVisualCatalog = preload("res://scripts/enemy_visual_catalog.gd")

enum BrainState { CHASE, WINDUP, RECOVERY, STAGGER, DEAD }

var game: Variant
var is_boss := false
var archetype_id := "arena_guard"
var enemy_level := 1
var exp_reward := 30
var coin_reward := 40
var drop_tier := "normal"
var health := 65.0
var max_health := 65.0
var speed := 2.5
var attack_damage := 7.0
var attack_range := 2.0
var attack_interval := 1.6
var boss_windup := 1.05
var boss_heavy_interval := 3
var boss_heavy_multiplier := 1.55
var boss_range_multiplier := 1.5
var boss_recovery := 0.72
var boss_special := "none"
var state: BrainState = BrainState.CHASE
var state_timer := 0.0
var attack_cooldown := 0.8
var knockback_velocity := Vector3.ZERO
var display_name := "训练对手"
var body_material: StandardMaterial3D
var enemy_arm_nodes: Array[MeshInstance3D] = []
var enemy_leg_nodes: Array[MeshInstance3D] = []
var telegraph_mesh: MeshInstance3D
var telegraph_material: StandardMaterial3D
var authored_enemy_model: Node3D
var authored_enemy_animation_player: AnimationPlayer
var authored_enemy_animation_state := ""
var authored_enemy_action_timer := 0.0
var authored_enemy_death_timer := 0.0
var boss_aura_ring: MeshInstance3D
var enemy_accent_nodes: Array[MeshInstance3D] = []
var enemy_wing_nodes: Array[MeshInstance3D] = []
var enemy_wing_base_angles: Array[float] = []
var hit_flash_timer := 0.0
var boss_phase_burst_timer := 0.0
var boss_phase_transition_timer := 0.0
var _boss_phase_two := false
var _boss_attack_count := 0
var _boss_heavy_attack := false
var _base_color := Color(0.72, 0.16, 0.22)
var freeze_timer := 0.0
var slow_timer := 0.0
var slow_factor := 0.55
var burn_timer := 0.0
var burn_tick_timer := 0.0
var burn_damage := 0.0
var weaken_timer := 0.0
var weaken_factor := 0.7
var divine_mark := ""
var divine_mark_timer := 0.0
var divine_mark_power := 0.0
var boss_control_pressure := 0.0
var boss_control_resist_timer := 0.0
var boss_control_resistance := 0.72

func _ready() -> void:
    add_to_group("enemies")
    var archetype: Dictionary = EnemyDatabase.get_archetype(archetype_id)
    is_boss = bool(archetype.get("is_boss", is_boss))
    enemy_level = maxi(1, int(RPGState.profile.get("level", 1)))
    var level_scale := 1.0 + float(enemy_level - 1) * 0.035
    display_name = str(archetype.get("name", "训练对手"))
    max_health = float(archetype.get("health", 65.0)) * level_scale
    health = max_health
    speed = float(archetype.get("speed", 2.5)) * (1.0 + float(enemy_level - 1) * 0.006)
    attack_damage = float(archetype.get("attack_damage", 7.0)) * level_scale
    attack_range = float(archetype.get("attack_range", 2.0))
    attack_interval = float(archetype.get("attack_interval", 1.6))
    boss_windup = float(archetype.get("boss_windup", 1.05))
    boss_heavy_interval = maxi(1, int(archetype.get("boss_heavy_interval", 3)))
    boss_heavy_multiplier = float(archetype.get("boss_heavy_multiplier", 1.55))
    boss_range_multiplier = float(archetype.get("boss_range_multiplier", 1.5))
    boss_recovery = float(archetype.get("boss_recovery", 0.72))
    boss_special = str(archetype.get("boss_special", "none"))
    exp_reward = int(archetype.get("exp_reward", 30)) + maxi(0, enemy_level - 1) * 2
    coin_reward = int(archetype.get("coin_reward", 40)) + maxi(0, enemy_level - 1) * 3
    drop_tier = str(archetype.get("drop_tier", "normal"))
    _base_color = archetype.get("color", Color(0.72, 0.16, 0.22))

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

    var head := MeshInstance3D.new()
    var head_shape := SphereMesh.new()
    head_shape.radius = radius * 0.46
    head_shape.height = radius * 0.92
    head.mesh = head_shape
    head.position.y = height * 0.84
    head.material_override = body_material
    add_child(head)

    var arm_mesh := CapsuleMesh.new()
    arm_mesh.radius = radius * 0.17
    arm_mesh.height = height * 0.27
    var leg_mesh := CapsuleMesh.new()
    leg_mesh.radius = radius * 0.19
    leg_mesh.height = height * 0.25
    for side in [-1.0, 1.0]:
        var arm := MeshInstance3D.new()
        arm.mesh = arm_mesh
        arm.position = Vector3(side * radius * 0.78, height * 0.45, 0.0)
        arm.material_override = body_material
        add_child(arm)
        enemy_arm_nodes.append(arm)
        var leg := MeshInstance3D.new()
        leg.mesh = leg_mesh
        leg.position = Vector3(side * radius * 0.28, height * 0.15, 0.0)
        leg.material_override = body_material
        add_child(leg)
        enemy_leg_nodes.append(leg)

    var chest_plate := MeshInstance3D.new()
    var chest_mesh := BoxMesh.new()
    chest_mesh.size = Vector3(radius * 1.35, height * 0.22, radius * 0.42)
    chest_plate.mesh = chest_mesh
    chest_plate.position = Vector3(0.0, height * 0.61, -radius * 0.72)
    var armor_material := StandardMaterial3D.new()
    armor_material.albedo_color = _base_color.lightened(0.28)
    armor_material.metallic = 0.78
    armor_material.roughness = 0.22
    armor_material.emission_enabled = true
    armor_material.emission = _base_color * 0.10
    chest_plate.material_override = armor_material
    add_child(chest_plate)

    var shoulder_mesh := SphereMesh.new()
    shoulder_mesh.radius = radius * 0.34
    shoulder_mesh.height = radius * 0.68
    for side in [-1.0, 1.0]:
        var shoulder := MeshInstance3D.new()
        shoulder.mesh = shoulder_mesh
        shoulder.position = Vector3(side * radius * 0.82, height * 0.68, 0.0)
        shoulder.material_override = armor_material
        add_child(shoulder)

    var visual_profile: Dictionary = EnemyVisualCatalog.get_profile(archetype_id, is_boss, _base_color)
    _build_enemy_armor_visuals(visual_profile, radius, height)

    if is_boss:
        var crown_mesh := CylinderMesh.new()
        crown_mesh.top_radius = 0.025
        crown_mesh.bottom_radius = radius * 0.18
        crown_mesh.height = radius * 0.72
        for side in [-1.0, 1.0]:
            var crown := MeshInstance3D.new()
            crown.mesh = crown_mesh
            crown.position = Vector3(side * radius * 0.30, height * 1.02, 0.02)
            crown.rotation.z = -side * 0.38
            crown.material_override = armor_material
            add_child(crown)
        boss_aura_ring = MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = radius * 0.92
        ring_mesh.outer_radius = radius * 1.06
        boss_aura_ring.mesh = ring_mesh
        boss_aura_ring.position.y = 0.10
        var ring_material := StandardMaterial3D.new()
        ring_material.albedo_color = _base_color
        ring_material.emission_enabled = true
        ring_material.emission = _base_color * 0.65
        ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        boss_aura_ring.material_override = ring_material
        add_child(boss_aura_ring)
        if archetype_id in ["hypnos_guardian", "apollo_trial", "zeus_trial", "universe_arbiter", "hades_emperor"]:
            var wing_mesh := BoxMesh.new()
            wing_mesh.size = Vector3(radius * 0.22, height * 0.46, radius * 0.16)
            for side in [-1.0, 1.0]:
                var wing := MeshInstance3D.new()
                wing.mesh = wing_mesh
                wing.position = Vector3(side * radius * 0.92, height * 0.76, radius * 0.22)
                wing.rotation.z = -side * 0.42
                wing.material_override = armor_material
                add_child(wing)

    telegraph_mesh = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = attack_range * 0.72
    ring.outer_radius = attack_range
    telegraph_mesh.mesh = ring
    telegraph_mesh.position.y = 0.06
    telegraph_material = StandardMaterial3D.new()
    telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    telegraph_material.albedo_color = Color(1.0, 0.18, 0.12, 0.72)
    telegraph_material.emission_enabled = true
    telegraph_material.emission = Color(1.0, 0.06, 0.02)
    telegraph_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    telegraph_mesh.material_override = telegraph_material
    telegraph_mesh.visible = false
    add_child(telegraph_mesh)
    _load_authored_enemy_model()

func _load_authored_enemy_model() -> void:
    # Optional GLB bundle; a clean source checkout remains playable via procedural visuals.
    var model_path := "res://assets/enemies/%s/model/enemy.glb" % archetype_id
    if not ResourceLoader.exists(model_path):
        return
    var packed := load(model_path) as PackedScene
    if packed == null:
        push_warning("Enemy model could not be loaded; using procedural fallback: " + model_path)
        return
    var authored_model := packed.instantiate()
    if authored_model == null:
        push_warning("Enemy model could not be instantiated; using procedural fallback: " + model_path)
        return
    authored_model.name = "AuthoredEnemyModel"
    authored_enemy_model = authored_model
    authored_enemy_animation_player = _find_enemy_animation_player(authored_model)
    authored_enemy_animation_state = ""
    authored_enemy_action_timer = 0.0
    authored_model.scale = Vector3.ONE * (1.12 if is_boss else 1.0)
    for child in get_children():
        if child is MeshInstance3D and child != telegraph_mesh:
            (child as MeshInstance3D).visible = false
    add_child(authored_model)
    _play_authored_enemy_animation("idle")

func _find_enemy_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root as AnimationPlayer
    for child in root.get_children():
        var found := _find_enemy_animation_player(child)
        if is_instance_valid(found):
            return found
    return null

func _play_authored_enemy_animation(animation_name: String, blend_time: float = 0.12) -> void:
    if not is_instance_valid(authored_enemy_animation_player):
        return
    if not authored_enemy_animation_player.has_animation(animation_name):
        return
    if authored_enemy_animation_state == animation_name and authored_enemy_animation_player.is_playing():
        return
    authored_enemy_animation_state = animation_name
    authored_enemy_animation_player.play(animation_name, blend_time)

func _play_authored_enemy_action(animation_name: String, blend_time: float = 0.05) -> void:
    if not is_instance_valid(authored_enemy_animation_player):
        return
    if not authored_enemy_animation_player.has_animation(animation_name):
        return
    var clip := authored_enemy_animation_player.get_animation(animation_name)
    authored_enemy_action_timer = clampf(clip.length, 0.18, 1.0)
    authored_enemy_animation_state = ""
    authored_enemy_animation_player.play(animation_name, blend_time)

func _update_authored_enemy_animation(delta: float, planar_speed: float) -> void:
    if not is_instance_valid(authored_enemy_animation_player):
        return
    authored_enemy_action_timer = maxf(0.0, authored_enemy_action_timer - delta)
    if authored_enemy_action_timer > 0.0:
        return
    var animation_name := "walk" if planar_speed >= 0.25 else "idle"
    if state == BrainState.WINDUP:
        animation_name = "skill_cast" if _boss_heavy_attack or _boss_phase_two else "basic_attack_1"
    elif state == BrainState.STAGGER:
        animation_name = "hit_heavy" if is_boss else "hit_light"
    elif state == BrainState.RECOVERY:
        animation_name = "idle"
    _play_authored_enemy_animation(animation_name)

func _add_enemy_visual(mesh: Mesh, local_position: Vector3, local_scale: Vector3, color: Color, metallic: float) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.mesh = mesh
    part.position = local_position
    part.scale = local_scale
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = clampf(metallic, 0.0, 1.0)
    material.roughness = 0.24
    material.emission_enabled = true
    material.emission = color * 0.055
    part.material_override = material
    add_child(part)
    enemy_accent_nodes.append(part)
    return part

func _build_enemy_armor_visuals(profile: Dictionary, radius: float, height: float) -> void:
    var accent: Color = profile.get("accent", _base_color.lightened(0.3))
    var secondary: Color = profile.get("secondary", _base_color.darkened(0.3))
    var metallic := float(profile.get("metallic", 0.72))
    var width := float(profile.get("shoulder_width", 1.0))
    var helmet := SphereMesh.new()
    helmet.radius = radius * 0.52
    helmet.height = radius * 0.72
    _add_enemy_visual(helmet, Vector3(0.0, height * 0.84, -radius * 0.08), Vector3(1.0, 0.82, 0.92), accent, metallic)
    var waist := BoxMesh.new()
    waist.size = Vector3(radius * 1.32, height * 0.12, radius * 0.68)
    _add_enemy_visual(waist, Vector3(0.0, height * 0.39, -radius * 0.18), Vector3.ONE, secondary, metallic * 0.9)
    var forearm := CylinderMesh.new()
    forearm.top_radius = radius * 0.19
    forearm.bottom_radius = radius * 0.25
    forearm.height = height * 0.2
    for side in [-1.0, 1.0]:
        var guard := _add_enemy_visual(forearm, Vector3(side * radius * 0.72, height * 0.43, -radius * 0.42), Vector3.ONE, accent, metallic)
        guard.rotation.z = side * 0.12
        var greave := BoxMesh.new()
        greave.size = Vector3(radius * 0.34, height * 0.22, radius * 0.48)
        _add_enemy_visual(greave, Vector3(side * radius * 0.28, height * 0.15, -radius * 0.12), Vector3.ONE, secondary, metallic * 0.82)
        var shoulder_scale := Vector3(width, 1.0, 1.0)
        var shoulder_cap := SphereMesh.new()
        shoulder_cap.radius = radius * 0.38
        shoulder_cap.height = radius * 0.62
        _add_enemy_visual(shoulder_cap, Vector3(side * radius * 0.82, height * 0.69, 0.0), shoulder_scale, accent, metallic)
    var crest := str(profile.get("crest", "crest"))
    var crest_mesh: Mesh
    match crest:
        "horn":
            var horn := PrismMesh.new()
            horn.size = Vector3(radius * 0.2, radius * 0.72, radius * 0.2)
            crest_mesh = horn
        "fin":
            var fin := PrismMesh.new()
            fin.size = Vector3(radius * 0.22, radius * 0.82, radius * 0.16)
            crest_mesh = fin
        "rune":
            var rune := TorusMesh.new()
            rune.inner_radius = radius * 0.12
            rune.outer_radius = radius * 0.22
            crest_mesh = rune
        "halo":
            var crest_halo := TorusMesh.new()
            crest_halo.inner_radius = radius * 0.28
            crest_halo.outer_radius = radius * 0.36
            crest_mesh = crest_halo
        "void":
            var void_spike := PrismMesh.new()
            void_spike.size = Vector3(radius * 0.34, radius * 0.9, radius * 0.3)
            crest_mesh = void_spike
        _:
            var crest_plate := PrismMesh.new()
            crest_plate.size = Vector3(radius * 0.48, radius * 0.56, radius * 0.18)
            crest_mesh = crest_plate
    var crest_node := _add_enemy_visual(crest_mesh, Vector3(0.0, height * 1.04, -radius * 0.05), Vector3.ONE, accent, metallic)
    if crest in ["horn", "fin", "void"]:
        crest_node.rotation.z = PI
    elif crest == "rune":
        crest_node.rotation.x = deg_to_rad(90.0)

    # Glowing eye slits and a layered chest insignia give each enemy a
    # readable face and faction identity, including on small mobile screens.
    var eye_mesh := BoxMesh.new()
    eye_mesh.size = Vector3(radius * 0.46, radius * 0.055, radius * 0.035)
    var eye_node := _add_enemy_visual(eye_mesh, Vector3(0.0, height * 0.85, -radius * 0.49), Vector3.ONE, accent.lightened(0.22), metallic)
    var eye_material := eye_node.material_override as StandardMaterial3D
    eye_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    eye_material.emission = accent * 0.42
    var emblem_mesh := TorusMesh.new()
    emblem_mesh.inner_radius = radius * 0.12
    emblem_mesh.outer_radius = radius * 0.19
    var emblem_node := _add_enemy_visual(emblem_mesh, Vector3(0.0, height * 0.61, -radius * 0.76), Vector3(1.0, 1.0, 0.28), accent, metallic)
    emblem_node.rotation.x = deg_to_rad(90.0)
    if bool(profile.get("winged", false)):
        var wing := PrismMesh.new()
        wing.size = Vector3(radius * 0.72, height * 0.48, radius * 0.18)
        for side in [-1.0, 1.0]:
            var wing_node := _add_enemy_visual(wing, Vector3(side * radius * 0.88, height * 0.76, radius * 0.24), Vector3(1.0, 1.0, 0.62), accent, metallic)
            wing_node.rotation.z = -side * 0.42
            enemy_wing_nodes.append(wing_node)
            enemy_wing_base_angles.append(wing_node.rotation.z)
    if bool(profile.get("halo", false)):
        var halo_mesh := TorusMesh.new()
        halo_mesh.inner_radius = radius * 0.72
        halo_mesh.outer_radius = radius * 0.84
        var halo_node := _add_enemy_visual(halo_mesh, Vector3(0.0, height * 1.12, 0.0), Vector3.ONE, accent, metallic)
        halo_node.rotation.x = deg_to_rad(72.0)
        var halo_material := halo_node.material_override as StandardMaterial3D
        halo_material.emission = accent * float(profile.get("glow", 0.2))
        halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func is_targetable() -> bool:
    return state != BrainState.DEAD and health > 0.0 and is_inside_tree()

func _physics_process(delta: float) -> void:
    if state == BrainState.DEAD:
        authored_enemy_death_timer = maxf(0.0, authored_enemy_death_timer - delta)
        if authored_enemy_death_timer <= 0.0:
            queue_free()
        return
    _animate_enemy_limbs(delta)
    _update_authored_enemy_animation(delta, Vector2(velocity.x, velocity.z).length())
    if boss_phase_transition_timer > 0.0:
        boss_phase_transition_timer = maxf(0.0, boss_phase_transition_timer - delta)
        velocity.x = move_toward(velocity.x, 0.0, 36.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 36.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta * get_divine_mark_attack_rate_multiplier())
    state_timer = maxf(0.0, state_timer - delta)
    freeze_timer = maxf(0.0, freeze_timer - delta)
    slow_timer = maxf(0.0, slow_timer - delta)
    weaken_timer = maxf(0.0, weaken_timer - delta)
    divine_mark_timer = maxf(0.0, divine_mark_timer - delta)
    boss_control_resist_timer = maxf(0.0, boss_control_resist_timer - delta)
    boss_control_pressure = maxf(0.0, boss_control_pressure - delta * 0.12)
    if divine_mark_timer <= 0.0:
        divine_mark = ""
        divine_mark_power = 0.0
    burn_timer = maxf(0.0, burn_timer - delta)
    if burn_timer > 0.0:
        burn_tick_timer -= delta
        if burn_tick_timer <= 0.0:
            burn_tick_timer = 1.0
            var burn_class_id := str(RPGState.profile.get("class_id", "pegasus"))
            var burn_tick_damage: float = burn_damage * get_divine_mark_burn_multiplier() * SkillSystem.get_passive_burn_multiplier(burn_class_id)
            take_damage(burn_tick_damage)
            var burn_sustain: float = SkillSystem.get_passive_burn_sustain_ratio(burn_class_id)
            if burn_sustain > 0.0 and is_instance_valid(game):
                var burn_owner: Node = game.get("player")
                if is_instance_valid(burn_owner):
                    burn_owner.health = minf(float(burn_owner.max_health), float(burn_owner.health) + burn_tick_damage * burn_sustain)
            if state == BrainState.DEAD:
                return
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

    if freeze_timer > 0.0:
        telegraph_mesh.visible = false
        velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if distance > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)

    match state:
        BrainState.CHASE:
            telegraph_mesh.visible = false
            if distance <= attack_range and attack_cooldown <= 0.0:
                _begin_attack()
            else:
                var effective_speed := speed * (slow_factor if slow_timer > 0.0 else 1.0)
                velocity.x = direction.x * effective_speed + knockback_velocity.x
                velocity.z = direction.z * effective_speed + knockback_velocity.z
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

func _animate_enemy_limbs(delta: float) -> void:
    var planar_speed := Vector2(velocity.x, velocity.z).length()
    var movement := clampf(planar_speed / maxf(1.0, speed), 0.0, 1.0)
    var clock := float(Time.get_ticks_msec()) * 0.009 * maxf(0.6, speed)
    var windup_pose := 1.0 if state == BrainState.WINDUP else 0.0
    var stagger_pose := 1.0 if state == BrainState.STAGGER else 0.0
    if is_instance_valid(telegraph_mesh):
        if telegraph_mesh.visible:
            telegraph_mesh.rotation.y += delta * 0.9
            var warning_pulse := 0.78 + (sin(clock * 3.2) * 0.5 + 0.5) * 0.42
            telegraph_mesh.scale = Vector3.ONE * warning_pulse * (boss_range_multiplier if _boss_heavy_attack else 1.0)
        else:
            telegraph_mesh.rotation.y = lerp_angle(telegraph_mesh.rotation.y, 0.0, minf(1.0, delta * 4.0))
    hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
    boss_phase_burst_timer = maxf(0.0, boss_phase_burst_timer - delta)
    if is_instance_valid(body_material):
        var flash_weight := clampf(hit_flash_timer / 0.14, 0.0, 1.0)
        body_material.albedo_color = _base_color.lerp(Color(1.0, 0.82, 0.64), flash_weight)
        var state_glow := 0.22 + windup_pose * (0.28 + (sin(clock * 3.2) * 0.5 + 0.5) * 0.18) + stagger_pose * 0.12
        body_material.emission = _base_color * state_glow
    rotation.z = lerpf(rotation.z, -0.12 * stagger_pose + 0.035 * windup_pose, minf(1.0, delta * 5.0))
    if is_instance_valid(boss_aura_ring):
        boss_aura_ring.rotation.y += delta * (0.42 if _boss_phase_two else 0.24)
        var ring_pulse := 1.0 + sin(clock * 1.5) * (0.055 if _boss_phase_two else 0.025)
        var phase_burst := clampf(boss_phase_burst_timer / 1.35, 0.0, 1.0)
        boss_aura_ring.scale = Vector3.ONE * ring_pulse * (1.0 + (1.0 - phase_burst) * 0.42)
        var aura_material := boss_aura_ring.material_override as StandardMaterial3D
        if is_instance_valid(aura_material):
            aura_material.emission_energy_multiplier = 1.0 + phase_burst * 3.2 + (0.45 if _boss_phase_two else 0.0)
    var accent_pulse := 0.72 + (sin(clock * (4.8 if _boss_phase_two else 2.8)) * 0.5 + 0.5) * (0.22 if is_boss else 0.1)
    for accent_node in enemy_accent_nodes:
        if not is_instance_valid(accent_node):
            continue
        var accent_material := accent_node.material_override as StandardMaterial3D
        if is_instance_valid(accent_material):
            accent_material.emission_energy_multiplier = accent_pulse * (1.55 if _boss_phase_two else 1.0)
    for wing_index in range(enemy_wing_nodes.size()):
        var wing_node := enemy_wing_nodes[wing_index]
        if not is_instance_valid(wing_node):
            continue
        var wing_side := -1.0 if wing_index % 2 == 0 else 1.0
        var base_angle := enemy_wing_base_angles[wing_index] if wing_index < enemy_wing_base_angles.size() else 0.0
        var flap := sin(clock * (1.8 if _boss_phase_two else 1.1)) * (0.09 if is_boss else 0.035)
        wing_node.rotation.z = lerp_angle(wing_node.rotation.z, base_angle + wing_side * flap, minf(1.0, delta * 5.0))
    for limb_index in range(2):
        var gait := sin(clock + (PI if limb_index == 1 else 0.0)) * 0.48 * movement
        var arm_target := lerpf(gait, -0.92, windup_pose)
        arm_target = lerpf(arm_target, 0.58, stagger_pose)
        var leg_target := -gait * (1.0 - windup_pose)
        if limb_index < enemy_arm_nodes.size():
            enemy_arm_nodes[limb_index].rotation.x = lerp_angle(enemy_arm_nodes[limb_index].rotation.x, arm_target, minf(1.0, delta * 10.0))
        if limb_index < enemy_leg_nodes.size():
            enemy_leg_nodes[limb_index].rotation.x = lerp_angle(enemy_leg_nodes[limb_index].rotation.x, leg_target, minf(1.0, delta * 10.0))

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = minf(velocity.y, 0.0)

func _begin_attack() -> void:
    state = BrainState.WINDUP
    _boss_heavy_attack = false
    if is_boss:
        _boss_attack_count += 1
        var heavy_interval := maxi(1, boss_heavy_interval - (1 if _boss_phase_two else 0))
        _boss_heavy_attack = _boss_attack_count % heavy_interval == 0
    state_timer = (boss_windup if _boss_heavy_attack else boss_windup * 0.64) if is_boss else 0.48
    _play_authored_enemy_action("basic_attack_3" if _boss_heavy_attack else "basic_attack_1", 0.045)
    telegraph_mesh.scale = Vector3.ONE * (boss_range_multiplier if _boss_heavy_attack else 1.0)
    telegraph_mesh.visible = true
    if is_instance_valid(game):
        var warning := "重击范围预警！及时闪避" if _boss_heavy_attack else "正在蓄力攻击！"
        game.call("show_notice", display_name + "：" + warning)

func _resolve_attack(target: Node3D) -> void:
    telegraph_mesh.visible = false
    telegraph_mesh.scale = Vector3.ONE
    var current_distance := global_position.distance_to(target.global_position)
    var attack_reach := attack_range * (boss_range_multiplier if _boss_heavy_attack else 1.0) + 0.35
    if current_distance <= attack_reach:
        var player_invulnerable := float(target.get("invulnerable")) > 0.0
        var damage_multiplier := boss_heavy_multiplier if _boss_heavy_attack else 1.0
        var outgoing_attack := attack_damage * damage_multiplier * (weaken_factor if weaken_timer > 0.0 else 1.0)
        target.call("receive_damage", outgoing_attack, global_position)
        if not player_invulnerable and target.has_method("apply_enemy_knockback"):
            var push := target.global_position - global_position
            push.y = 0.0
            if push.length_squared() > 0.001:
                target.call("apply_enemy_knockback", push.normalized(), 9.0 if _boss_heavy_attack else (7.0 if is_boss else 4.5))
        if is_boss and _boss_heavy_attack and not player_invulnerable:
            _apply_boss_attack_signature(target, outgoing_attack)
    attack_cooldown = attack_interval * (0.78 if _boss_phase_two else 1.0)
    state = BrainState.RECOVERY
    state_timer = boss_recovery if _boss_heavy_attack else (0.5 if is_boss else 0.34)
    _boss_heavy_attack = false

func _drain_target_cosmos(target: Node, amount: float) -> void:
    if not is_instance_valid(target):
        return
    for property_info in target.get_property_list():
        if str(property_info.get("name", "")) == "cosmos":
            target.set("cosmos", maxf(0.0, float(target.get("cosmos")) - maxf(0.0, amount)))
            return

func _apply_boss_attack_signature(target: Node3D, base_damage: float) -> void:
    if not is_instance_valid(target):
        return
    match boss_special:
        "dream_drain":
            _drain_target_cosmos(target, 8.0)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "发动梦境侵蚀：小宇宙减少")
        "soul_leech":
            health = minf(max_health, health + base_damage * 0.08)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "汲取生命，恢复了部分体力")
        "death_burst":
            if target.has_method("receive_damage"):
                target.call("receive_damage", base_damage * 0.18, global_position)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "发动死亡追加斩击")
        "tidal_pull":
            if target.has_method("apply_enemy_knockback"):
                var pull_direction := global_position - target.global_position
                pull_direction.y = 0.0
                if pull_direction.length_squared() > 0.001:
                    target.call("apply_enemy_knockback", pull_direction.normalized(), 8.5)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "掀起潮汐，将目标拉向自身")
        "solar_flare":
            if target.has_method("receive_damage"):
                target.call("receive_damage", base_damage * 0.16, global_position)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "释放太阳神追加光爆")
        "lightning_followup":
            if target.has_method("receive_damage"):
                target.call("receive_damage", base_damage * 0.22, global_position)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "召来雷霆追击")
        "void_drain":
            _drain_target_cosmos(target, 12.0)
            health = minf(max_health, health + base_damage * 0.06)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "吞噬小宇宙并恢复体力")
        "rift_drain":
            _drain_target_cosmos(target, 10.0)
            if is_instance_valid(game):
                game.call("show_notice", display_name + "撕裂小宇宙护盾")
        "gravity_crush":
            _drain_target_cosmos(target, 6.0)
            if target.has_method("receive_damage"):
                target.call("receive_damage", base_damage * 0.10, global_position)
        "judge_combo":
            if target.has_method("receive_damage"):
                target.call("receive_damage", base_damage * 0.16, global_position)
        "judgment_combo":
            if target.has_method("receive_damage"):
                target.call("receive_damage", base_damage * 0.20, global_position)
        "wing_slam":
            if target.has_method("apply_enemy_knockback"):
                var slam_direction := target.global_position - global_position
                slam_direction.y = 0.0
                if slam_direction.length_squared() > 0.001:
                    target.call("apply_enemy_knockback", slam_direction.normalized(), 12.0)
        _:
            return

func take_damage(amount: float) -> void:
    if state == BrainState.DEAD or health <= 0.0:
        return
    var mark_multiplier := 1.0 + divine_mark_power if divine_mark_timer > 0.0 else 1.0
    mark_multiplier *= get_divine_mark_damage_multiplier()
    var applied_damage := minf(health, maxf(0.0, amount) * mark_multiplier)
    health = maxf(0.0, health - applied_damage)
    var lifesteal_ratio := get_divine_mark_lifesteal_ratio()
    if lifesteal_ratio > 0.0 and is_instance_valid(game):
        var marked_attacker: Node = game.get("player")
        if is_instance_valid(marked_attacker):
            marked_attacker.health = minf(float(marked_attacker.max_health), float(marked_attacker.health) + applied_damage * lifesteal_ratio)
    CombatSessionManager.record_damage_dealt(applied_damage)
    if is_instance_valid(game):
        game.call("spawn_effect", global_position + Vector3(0, 1.0, 0), Color(0.25, 0.78, 1.0), 1.1 if is_boss else 0.65)
        if game.has_method("spawn_damage_number"):
            game.call("spawn_damage_number", global_position + Vector3.UP * 2.0, applied_damage, is_boss)

    if is_boss and not _boss_phase_two and health <= max_health * 0.5:
        _boss_phase_two = true
        _play_authored_enemy_action("phase_shift", 0.08)
        boss_phase_transition_timer = maxf(0.85, authored_enemy_action_timer)
        boss_phase_burst_timer = 1.35
        speed *= 1.25
        attack_damage *= 1.25
        _base_color = Color(0.72, 0.12, 0.18)
        body_material.albedo_color = _base_color
        body_material.emission = Color(0.42, 0.025, 0.02)
        if is_instance_valid(game):
            game.call("spawn_effect", global_position + Vector3.UP * 1.5, Color(1.0, 0.16, 0.08), 2.1)
        if is_instance_valid(game):
            game.call("show_notice", "Boss 进入第二阶段！攻击速度与伤害提升")

    if health <= 0.0:
        state = BrainState.DEAD
        velocity = Vector3.ZERO
        collision_layer = 0
        collision_mask = 0
        telegraph_mesh.visible = false
        _play_authored_enemy_action("defeat", 0.06)
        authored_enemy_death_timer = maxf(0.7, authored_enemy_action_timer)
        if is_instance_valid(game):
            game.call("on_enemy_defeated", self)
        return

    var attacker: Node3D = game.get("player") if is_instance_valid(game) else null
    if is_instance_valid(attacker):
        var push := global_position - attacker.global_position
        push.y = 0.0
        if push.length_squared() > 0.001:
            knockback_velocity = push.normalized() * (3.5 if is_boss else 7.0) * get_divine_mark_knockback_multiplier()
    # Damage alone must not cancel a boss's clearly telegraphed attack or recovery.
    if not is_boss or (state != BrainState.WINDUP and state != BrainState.RECOVERY):
        state = BrainState.STAGGER
        state_timer = 0.12 if is_boss else 0.3
        _play_authored_enemy_action("hit_heavy" if is_boss else "hit_light", 0.04)
    hit_flash_timer = 0.14
    body_material.albedo_color = Color(1.0, 0.78, 0.55)


func _register_boss_control(duration: float) -> float:
    if not is_boss:
        return 1.0
    if boss_control_resist_timer > 0.0:
        return 0.12
    boss_control_pressure = minf(1.0, boss_control_pressure + 0.22)
    if boss_control_pressure >= 0.66:
        boss_control_resist_timer = 3.0
        boss_control_pressure = 0.0
        if is_instance_valid(game):
            game.call("show_notice", display_name + "：强韧意志，暂时抵抗控制！")
    return boss_control_resistance


func apply_hit_reaction(direction: Vector3, force: float, lift: float, stagger_duration: float) -> void:
    if state == BrainState.DEAD:
        return
    if is_boss and state == BrainState.WINDUP:
        _register_boss_control(stagger_duration)
        return
    var control_scale := _register_boss_control(stagger_duration)
    var flat := direction
    flat.y = 0.0
    if flat.length_squared() > 0.001:
        var resistance := 0.22 * control_scale if is_boss else 1.0
        knockback_velocity = flat.normalized() * force * resistance
    if not is_boss and lift > 0.0:
        velocity.y = maxf(velocity.y, lift)
    if is_boss:
        if state != BrainState.RECOVERY and control_scale > 0.2:
            state = BrainState.STAGGER
            state_timer = maxf(state_timer, minf(0.16, stagger_duration * 0.22))
    else:
        state = BrainState.STAGGER
        state_timer = maxf(state_timer, stagger_duration)
    _play_authored_enemy_action("hit_heavy" if is_boss else "hit_light", 0.04)


func apply_status_effect(effect: String, duration: float, power: float = 0.0) -> void:
    if state == BrainState.DEAD:
        return
    match effect:
        "freeze":
            var freeze_control_scale := _register_boss_control(duration)
            var effective_duration := duration * (0.35 * freeze_control_scale if is_boss else 1.0)
            freeze_timer = maxf(freeze_timer, effective_duration)
            if not is_boss:
                state = BrainState.STAGGER
                state_timer = maxf(state_timer, freeze_timer)
        "slow":
            var slow_control_scale := _register_boss_control(duration)
            slow_timer = maxf(slow_timer, duration * (0.55 * slow_control_scale if is_boss else 1.0))
            slow_factor = clampf(1.0 - power * (0.45 if is_boss else 1.0), 0.25, 0.9)
        "burn":
            burn_timer = maxf(burn_timer, duration)
            burn_damage = maxf(burn_damage, power)
            burn_tick_timer = minf(burn_tick_timer, 0.2) if burn_tick_timer > 0.0 else 0.2
        "weaken":
            weaken_timer = maxf(weaken_timer, duration)
            weaken_factor = clampf(1.0 - power, 0.35, 0.95)

func is_controlled() -> bool:
    return freeze_timer > 0.0 or slow_timer > 0.0 or state == BrainState.STAGGER

func get_divine_mark_lifesteal_ratio() -> float:
    return 0.025 if divine_mark in ["soul", "death"] else 0.0

func get_divine_mark_burn_multiplier() -> float:
    if divine_mark_timer <= 0.0:
        return 1.0
    match divine_mark:
        "solar":
            return 0.75 if is_boss else 1.2
        "forge":
            return 1.08 if is_boss else 1.15
        "storm":
            return 1.04 if is_boss else 1.10
    return 1.0

func get_divine_mark_damage_multiplier() -> float:
    if divine_mark_timer <= 0.0:
        return 1.0
    match divine_mark:
        "lunar":
            return 1.05 if is_boss else 1.12
        "rune", "discord":
            return 1.04 if is_boss else 1.08
        "harvest", "forge":
            return 1.03 if is_boss else 1.06
        "command", "aegis":
            return 1.03 if is_boss else 1.05
        "tidal", "storm":
            return 1.02 if is_boss else 1.04
    return 1.0

func get_divine_mark_attack_rate_multiplier() -> float:
    if divine_mark_timer <= 0.0:
        return 1.0
    match divine_mark:
        "dream":
            return 0.9 if is_boss else 0.75
        "time":
            return 0.92 if is_boss else 0.82
    return 1.0

func get_divine_mark_knockback_multiplier() -> float:
    match divine_mark:
        "tidal":
            return 1.35
        "storm", "swift":
            return 1.15
    return 1.0

func apply_divine_mark(mark: String, duration: float, power: float) -> void:
    if state == BrainState.DEAD:
        return
    divine_mark = mark
    divine_mark_timer = maxf(divine_mark_timer, duration * (0.55 if is_boss else 1.0))
    divine_mark_power = maxf(divine_mark_power, clampf(power * (0.55 if is_boss else 1.0), 0.0, 0.18))
