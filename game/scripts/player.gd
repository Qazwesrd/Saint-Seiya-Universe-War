extends CharacterBody3D
const CombatTargeting = preload("res://scripts/combat_targeting.gd")
const CharacterVisualCatalog = preload("res://scripts/character_visual_catalog.gd")
var game: Variant
var move_input := Vector2.ZERO
var auto_move_target := Vector3.ZERO
var auto_moving := false
var health := 100.0
var max_health := 100.0
var cosmos := 100.0
var max_cosmos := 100.0
var cosmos_regen_rate := 3.0
var attack_cd := 0.0
var basic_combo_step := 0
var basic_combo_reset := 0.0
var skill_cd := 0.0
var combo_window := 0.0
var burst_cd := 0.0
var dodge_time := 0.0
var invulnerable := 0.0
var knockback_velocity := Vector3.ZERO
var locked_target: Node3D
var pivot: Node3D
var camera_arm: SpringArm3D
var camera_node: Camera3D
var camera_pitch := -9.0
var visual_root: Node3D
var visual_pose_tween: Tween
var auto_target_timer := 0.0
var body_mat: StandardMaterial3D
var armor_root: Node3D
var armor_base_color := Color(0.18, 0.52, 0.95)
var visual_class_id := ""
var is_mounted := false
var tenkishi_flight_active := false
var mount_indicator: MeshInstance3D
var temporary_damage_bonus := 0.0
var temporary_damage_reduction := 0.0
var temporary_buff_timer := 0.0
var divine_guard_shield := 0.0
var divine_guard_timer := 0.0
var class_passive_guard_cooldown := 0.0
var ability_cooldowns: Dictionary = {}
var custom_combo_index := 0
var custom_combo_timer := 0.0
var custom_combo_auto_running := false
var custom_combo_run_id := 0
func _ready() -> void:
    add_to_group("player")
    var rpg_stats: Dictionary = RPGState.get_combat_stats()
    max_health = float(rpg_stats.get("max_health", 110.0))
    max_cosmos = float(rpg_stats.get("max_cosmos", 100.0))
    cosmos_regen_rate = float(RPGState.get_cosmos_profile().get("regen_rate", 3.0))
    health = max_health
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.43
    shape.height = 1.8
    col.shape = shape
    col.position.y = 0.9
    add_child(col)
    visual_root = Node3D.new()
    visual_root.name = "PlayerVisualRoot"
    add_child(visual_root)
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
    visual_root.add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head.mesh = head_mesh
    head.position.y = 1.95
    head.material_override = body_mat
    visual_root.add_child(head)
    _build_armor_visuals()
    RPGState.state_changed.connect(_on_rpg_state_changed)
    mount_indicator = MeshInstance3D.new()
    var mount_ring := TorusMesh.new()
    mount_ring.inner_radius = 0.48
    mount_ring.outer_radius = 0.62
    mount_indicator.mesh = mount_ring
    mount_indicator.position = Vector3(0, 0.12, 0)
    mount_indicator.visible = false
    var mount_material := StandardMaterial3D.new()
    mount_material.albedo_color = Color(0.2, 0.85, 1.0)
    mount_material.emission_enabled = true
    mount_material.emission = Color(0.05, 0.45, 1.0)
    mount_indicator.material_override = mount_material
    visual_root.add_child(mount_indicator)
    pivot = Node3D.new()
    pivot.global_position = global_position + Vector3(0, 1.5, 0)
    game.add_child(pivot)
    camera_arm = SpringArm3D.new()
    pivot.add_child(camera_arm)
    camera_node = Camera3D.new()
    camera_node.rotation_degrees.x = camera_pitch
    camera_arm.add_child(camera_node)
    camera_node.current = true
    SettingsManager.settings_changed.connect(_on_camera_setting_changed)
    _apply_camera_settings()
func _animate_visual_motion(delta: float) -> void:
    if not is_instance_valid(visual_root):
        return
    var planar_speed := Vector2(velocity.x, velocity.z).length()
    var movement_ratio := clampf(planar_speed / 7.0, 0.0, 1.0)
    var clock := float(Time.get_ticks_msec()) * 0.012
    var bob := sin(clock) * 0.035 * movement_ratio
    if tenkishi_flight_active:
        bob += sin(clock * 0.72) * 0.045
    visual_root.position.y = lerpf(visual_root.position.y, bob, minf(1.0, delta * 9.0))
    var target_roll := -move_input.x * 0.10
    var target_pitch := move_input.y * 0.055
    visual_root.rotation.z = lerp_angle(visual_root.rotation.z, target_roll, minf(1.0, delta * 8.0))
    visual_root.rotation.x = lerp_angle(visual_root.rotation.x, target_pitch, minf(1.0, delta * 8.0))

func _play_attack_pose(intensity: float = 1.0) -> void:
    if not is_instance_valid(visual_root):
        return
    if is_instance_valid(visual_pose_tween):
        visual_pose_tween.kill()
    visual_root.scale = Vector3.ONE
    visual_pose_tween = create_tween()
    var recoil := Vector3(1.0 + 0.055 * intensity, 1.0 - 0.075 * intensity, 1.0 + 0.055 * intensity)
    visual_pose_tween.tween_property(visual_root, "scale", recoil, 0.065)
    visual_pose_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.15)

func _on_rpg_state_changed() -> void:
    var current_class := str(RPGState.profile.get("class_id", "pegasus"))
    if current_class != visual_class_id:
        _build_armor_visuals()

func _add_armor_piece(mesh: Mesh, piece_position: Vector3, piece_scale: Vector3, piece_color: Color, metallic: float = 0.72) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.mesh = mesh
    piece.position = piece_position
    piece.scale = piece_scale
    var material := StandardMaterial3D.new()
    material.albedo_color = piece_color
    material.metallic = metallic
    material.roughness = 0.24
    material.emission_enabled = true
    material.emission = piece_color * 0.06
    piece.material_override = material
    armor_root.add_child(piece)
    return piece

func _build_armor_visuals() -> void:
    if not is_instance_valid(visual_root):
        return
    if is_instance_valid(armor_root):
        armor_root.queue_free()
    armor_root = Node3D.new()
    armor_root.name = "ProceduralSaintArmor"
    visual_root.add_child(armor_root)

    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var visual_profile := CharacterVisualCatalog.get_profile(class_id)
    armor_base_color = class_data.get("color", Color(0.22, 0.52, 0.92))
    visual_class_id = class_id
    var accent: Color = visual_profile.get("accent", Color(1.0, 0.78, 0.28))
    var bright := armor_base_color.lightened(0.32)
    var dark := armor_base_color.darkened(0.42)
    var stage_state: Dictionary = ArmorSystem.get_state()
    var stage_id := str(stage_state.get("current_stage", "bronze"))
    var stage_data: Dictionary = ArmorSystem.STAGES.get(stage_id, ArmorSystem.STAGES["bronze"])
    var stage_metallic := clampf(float(visual_profile.get("metallic", 0.82)) + (0.08 if stage_id in ["gold", "god_cloth", "god_armor"] else 0.0), 0.0, 1.0)
    var stage_glow := float(visual_profile.get("glow", 0.1)) + (0.12 if stage_id in ["god_cloth", "god_armor"] else 0.0)

    if is_instance_valid(body_mat):
        body_mat.albedo_color = armor_base_color
        body_mat.metallic = stage_metallic
        body_mat.emission = armor_base_color * 0.08

    # Layered torso plates: chest, abdomen, collar and a raised central crest.
    var chest := BoxMesh.new()
    chest.size = Vector3(0.72, 0.54, 0.20)
    _add_armor_piece(chest, Vector3(0.0, 1.28, -0.32), Vector3.ONE, bright, stage_metallic)
    var abdomen := BoxMesh.new()
    abdomen.size = Vector3(0.56, 0.28, 0.18)
    _add_armor_piece(abdomen, Vector3(0.0, 0.88, -0.30), Vector3.ONE, dark, stage_metallic * 0.94)
    var collar := BoxMesh.new()
    collar.size = Vector3(0.82, 0.12, 0.24)
    _add_armor_piece(collar, Vector3(0.0, 1.58, -0.24), Vector3.ONE, accent.darkened(0.12), stage_metallic)

    # Class-specific shoulder silhouette and forearm guards.
    var shoulder_mesh := SphereMesh.new()
    shoulder_mesh.radius = 0.28
    shoulder_mesh.height = 0.42
    var shoulder_scale: Vector3 = visual_profile.get("shoulder_scale", Vector3.ONE)
    _add_armor_piece(shoulder_mesh, Vector3(-0.48, 1.55, 0.0), shoulder_scale, bright, stage_metallic)
    _add_armor_piece(shoulder_mesh, Vector3(0.48, 1.55, 0.0), shoulder_scale, bright, stage_metallic)
    var shoulder_spike := PrismMesh.new()
    shoulder_spike.size = Vector3(0.24, 0.42, 0.22)
    var left_spike := _add_armor_piece(shoulder_spike, Vector3(-0.58, 1.76, 0.0), Vector3.ONE, accent, stage_metallic)
    left_spike.rotation.z = 0.48
    var right_spike := _add_armor_piece(shoulder_spike, Vector3(0.58, 1.76, 0.0), Vector3.ONE, accent, stage_metallic)
    right_spike.rotation.z = -0.48
    var arm_mesh := CylinderMesh.new()
    arm_mesh.top_radius = 0.13
    arm_mesh.bottom_radius = 0.17
    arm_mesh.height = 0.48
    _add_armor_piece(arm_mesh, Vector3(-0.47, 0.98, 0.0), Vector3.ONE, dark, stage_metallic)
    _add_armor_piece(arm_mesh, Vector3(0.47, 0.98, 0.0), Vector3.ONE, dark, stage_metallic)
    var bracer_mesh := BoxMesh.new()
    bracer_mesh.size = Vector3(0.22, 0.38, 0.25)
    _add_armor_piece(bracer_mesh, Vector3(-0.48, 0.98, -0.13), Vector3.ONE, bright, stage_metallic)
    _add_armor_piece(bracer_mesh, Vector3(0.48, 0.98, -0.13), Vector3.ONE, bright, stage_metallic)

    # Waist guard, layered thigh/shin plates and knee caps.
    var belt_mesh := TorusMesh.new()
    belt_mesh.inner_radius = 0.29
    belt_mesh.outer_radius = 0.36
    _add_armor_piece(belt_mesh, Vector3(0.0, 0.72, 0.0), Vector3(1.0, 0.65, 1.0), accent, stage_metallic)
    var waist_plate := BoxMesh.new()
    waist_plate.size = Vector3(0.72, 0.22, 0.16)
    _add_armor_piece(waist_plate, Vector3(0.0, 0.61, -0.28), Vector3.ONE, bright, stage_metallic)
    var shin_mesh := BoxMesh.new()
    shin_mesh.size = Vector3(0.24, 0.48, 0.18)
    _add_armor_piece(shin_mesh, Vector3(-0.22, 0.34, -0.22), Vector3.ONE, bright, stage_metallic)
    _add_armor_piece(shin_mesh, Vector3(0.22, 0.34, -0.22), Vector3.ONE, bright, stage_metallic)
    var knee_mesh := SphereMesh.new()
    knee_mesh.radius = 0.15
    knee_mesh.height = 0.12
    _add_armor_piece(knee_mesh, Vector3(-0.22, 0.57, -0.27), Vector3(1.0, 0.7, 0.65), accent, stage_metallic)
    _add_armor_piece(knee_mesh, Vector3(0.22, 0.57, -0.27), Vector3(1.0, 0.7, 0.65), accent, stage_metallic)

    # Every class receives its own heraldic crest and chest sigil.
    var crest_mesh: Mesh
    match str(visual_profile.get("crest", "star")):
        "horn", "spear", "trident", "ice", "flame", "anvil":
            var crest_prism := PrismMesh.new()
            crest_prism.size = Vector3(0.20, 0.42, 0.16)
            crest_mesh = crest_prism
        "halo", "crescent", "clock", "dream", "aegis", "rune", "rose", "lyre":
            var crest_ring := TorusMesh.new()
            crest_ring.inner_radius = 0.09
            crest_ring.outer_radius = 0.15
            crest_mesh = crest_ring
        _:
            var crest_cone := CylinderMesh.new()
            crest_cone.bottom_radius = 0.13
            crest_cone.top_radius = 0.015
            crest_cone.height = 0.34
            crest_mesh = crest_cone
    var crest := _add_armor_piece(crest_mesh, Vector3(0.0, 2.12, -0.02), Vector3.ONE, accent, stage_metallic)
    if str(visual_profile.get("crest", "")) in ["horn", "spear", "trident", "ice", "flame", "anvil"]:
        crest.rotation.x = -0.18
    var emblem_mesh := SphereMesh.new()
    emblem_mesh.radius = 0.11
    emblem_mesh.height = 0.18
    _add_armor_piece(emblem_mesh, Vector3(0.0, 1.30, -0.445), Vector3(1.0, 1.0, 0.42), accent, 0.96)

    # Back ornaments are built as low-poly feather/fin plates, scaled per class.
    var wing_span := float(visual_profile.get("wing_span", 0.0))
    if wing_span > 0.0:
        var feather_mesh := PrismMesh.new()
        feather_mesh.size = Vector3(0.16, 0.72, 0.10)
        for side in [-1.0, 1.0]:
            for feather_index in range(3):
                var feather_scale := Vector3(1.0, wing_span * (1.0 - float(feather_index) * 0.14), 1.0)
                var feather_position := Vector3(side * (0.46 + float(feather_index) * 0.18), 1.72 - float(feather_index) * 0.08, 0.26 + float(feather_index) * 0.045)
                var feather := _add_armor_piece(feather_mesh, feather_position, feather_scale, bright if feather_index == 0 else accent, stage_metallic)
                feather.rotation.z = -side * (0.38 + float(feather_index) * 0.18)
                feather.rotation.x = -0.22
    if str(visual_profile.get("ornament", "")) in ["time_rings", "aegis", "radiant", "solar_wings", "storm_wings", "heaven_wings"]:
        var aura_ring := TorusMesh.new()
        aura_ring.inner_radius = 0.68
        aura_ring.outer_radius = 0.73
        var aura := _add_armor_piece(aura_ring, Vector3(0.0, 1.55, 0.34), Vector3.ONE, accent, 0.92)
        aura.rotation.x = deg_to_rad(72.0)
    if stage_glow > 0.0:
        var glow_mesh := SphereMesh.new()
        glow_mesh.radius = 0.13
        glow_mesh.height = 0.26
        var glow_piece := _add_armor_piece(glow_mesh, Vector3(0.0, 1.31, -0.50), Vector3.ONE, accent, 0.55)
        var glow_material := glow_piece.material_override as StandardMaterial3D
        glow_material.emission_enabled = true
        glow_material.emission = accent * stage_glow
        glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _on_camera_setting_changed(section: String, _key: String, _value: Variant) -> void:
    if section == "camera":
        _apply_camera_settings()

func _apply_camera_settings() -> void:
    if is_instance_valid(camera_arm):
        camera_arm.spring_length = clampf(float(SettingsManager.get_value("camera", "distance", 7.5)), 3.0, 14.0)

func rotate_camera(screen_delta: Vector2) -> void:
    if not is_instance_valid(pivot) or not is_instance_valid(camera_node):
        return
    var sensitivity := clampf(float(SettingsManager.get_value("camera", "sensitivity", 1.0)), 0.2, 3.0)
    var invert_y := bool(SettingsManager.get_value("camera", "invert_y", false))
    pivot.rotation.y -= screen_delta.x * 0.005 * sensitivity
    var vertical_sign := -1.0 if invert_y else 1.0
    camera_pitch = clampf(camera_pitch - screen_delta.y * 0.10 * sensitivity * vertical_sign, -35.0, 18.0)
    camera_node.rotation_degrees.x = camera_pitch

func set_move_input(value: Vector2) -> void:
    move_input = value.limit_length(1.0)

func set_auto_move_target(target: Vector3) -> void:
    auto_move_target = target
    auto_moving = true

func cancel_auto_move() -> void:
    auto_moving = false
func _physics_process(delta: float) -> void:
    pivot.global_position = global_position + Vector3(0, 1.5, 0)
    _animate_visual_motion(delta)
    attack_cd = maxf(0.0, attack_cd - delta)
    basic_combo_reset = maxf(0.0, basic_combo_reset - delta)
    if basic_combo_reset <= 0.0:
        basic_combo_step = 0
    skill_cd = maxf(0.0, skill_cd - delta)
    combo_window = maxf(0.0, combo_window - delta)
    custom_combo_timer = maxf(0.0, custom_combo_timer - delta)
    if custom_combo_timer <= 0.0:
        custom_combo_index = 0
    burst_cd = maxf(0.0, burst_cd - delta)
    dodge_time = maxf(0.0, dodge_time - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    temporary_buff_timer = maxf(0.0, temporary_buff_timer - delta)
    divine_guard_timer = maxf(0.0, divine_guard_timer - delta)
    class_passive_guard_cooldown = maxf(0.0, class_passive_guard_cooldown - delta)
    auto_target_timer = maxf(0.0, auto_target_timer - delta)
    if auto_target_timer <= 0.0:
        auto_target_timer = 0.25
        if bool(SettingsManager.get_value("gameplay", "auto_target", false)):
            var should_retarget := not is_instance_valid(locked_target)
            if not should_retarget:
                should_retarget = float(locked_target.get("health")) <= 0.0 or global_position.distance_to(locked_target.global_position) > 32.0
            if should_retarget:
                locked_target = CombatTargeting.select_target(self, locked_target, false)
    if divine_guard_timer <= 0.0:
        divine_guard_shield = 0.0
    for ability_id in ability_cooldowns.keys():
        ability_cooldowns[ability_id] = maxf(0.0, float(ability_cooldowns[ability_id]) - delta)
    if temporary_buff_timer <= 0.0:
        temporary_damage_bonus = 0.0
        temporary_damage_reduction = 0.0
    cosmos = minf(max_cosmos, cosmos + delta * cosmos_regen_rate)
    var input_vec := move_input
    if input_vec.length() < 0.05:
        input_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := Vector3.ZERO
    if input_vec.length() >= 0.05:
        auto_moving = false
        var basis := pivot.global_transform.basis
        direction = basis.x * input_vec.x + (-basis.z) * -input_vec.y
        direction.y = 0
        direction = direction.normalized()
    elif auto_moving:
        var target_offset := auto_move_target - global_position
        target_offset.y = 0
        if target_offset.length() <= 1.25:
            auto_moving = false
        else:
            direction = target_offset.normalized()
    var base_speed := float(RPGState.get_combat_stats().get("speed",12.0)) * 0.52
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    if class_id != "tenkishi":
        tenkishi_flight_active = false
    var passive_speed: float = SkillSystem.get_passive_speed_multiplier(class_id)
    var speed: float = base_speed * passive_speed * (2.2 if dodge_time > 0.0 else (1.45 if is_mounted else 1.0))
    knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 24.0 * delta)
    velocity.x = direction.x * speed + knockback_velocity.x
    velocity.z = direction.z * speed + knockback_velocity.z
    if class_id == "tenkishi" and tenkishi_flight_active:
        velocity.y = move_toward(velocity.y, 0.0, 5.5 * delta)
        if global_position.y >= 12.0 and velocity.y > 0.0:
            velocity.y = 0.0
        if global_position.y <= 0.25 and velocity.y < 0.0:
            velocity.y = 0.0
    else:
        var gravity_scale := 0.82 if class_id == "tenkishi" else 1.0
        velocity.y -= 22.0 * gravity_scale * delta
    move_and_slide()
    if direction.length() > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 12.0)
    elif is_instance_valid(locked_target):
        var toward := locked_target.global_position - global_position
        rotation.y = lerp_angle(rotation.y, atan2(-toward.x, -toward.z), delta * 5.0)
    if Input.is_action_just_pressed("ui_accept"): attack()
    if Input.is_action_just_pressed("ui_cancel"): dodge()
    game.call("update_hud")
func toggle_tenkishi_flight() -> void:
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    if class_id != "tenkishi":
        tenkishi_flight_active = false
        if is_instance_valid(game):
            game.call("show_notice", "只有天斗士职业可以展开天翼飞行")
        return
    tenkishi_flight_active = not tenkishi_flight_active
    if tenkishi_flight_active:
        velocity.y = maxf(velocity.y, 3.5)
        if is_instance_valid(game):
            game.call("show_notice", "天翼展开：飞行模式已开启")
    else:
        if is_instance_valid(game):
            game.call("show_notice", "天翼收拢：恢复地面战斗")
            
func tenkishi_flight_step(direction: float) -> void:
    if str(RPGState.profile.get("class_id", "pegasus")) != "tenkishi" or not tenkishi_flight_active:
        return
    velocity.y = clampf(velocity.y + signf(direction) * 4.5, -5.0, 5.0)
    if is_instance_valid(game):
        game.call("show_notice", "天翼上升" if direction > 0.0 else "天翼俯冲")

func attack() -> void:
    if attack_cd > 0.0:
        return
    if basic_combo_reset <= 0.0:
        basic_combo_step = 0
    basic_combo_step = (basic_combo_step % 3) + 1
    basic_combo_reset = 0.95
    attack_cd = 0.28 if basic_combo_step < 3 else 0.52
    _play_attack_pose(0.85 if basic_combo_step < 3 else 1.15)
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var skill_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var attack_stat := float(RPGState.get_combat_stats().get("attack", 14.0))
    var multipliers := [0.85, 1.0, 1.45]
    var passive_multiplier: float = SkillSystem.get_skill_damage_multiplier(class_id)
    var aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile(class_id, tenkishi_flight_active)
    var damages: float = (8.0 + attack_stat * float(multipliers[basic_combo_step - 1])) * passive_multiplier * (1.0 + temporary_damage_bonus) * float(aerial_profile.get("damage_multiplier", 1.0))
    var push_forces := [1.8, 2.8, float(skill_data.get("knockback", 3.5)) * 1.7]
    var lift_forces := [0.0, 0.0, float(skill_data.get("launch", 1.2)) * 1.5]
    if tenkishi_flight_active and class_id == "tenkishi":
        lift_forces = [0.55, 0.9, float(skill_data.get("launch", 1.2)) * 1.5 + float(aerial_profile.get("launch_bonus", 1.0))]
    var basic_names: Array = skill_data.get("basic_attacks", ["第一段", "第二段", "第三段"])
    _flash(skill_data.get("color", Color(1.0, 0.82, 0.35)))
    var attack_reach: float = (2.8 if basic_combo_step < 3 else 3.2) + float(aerial_profile.get("range_bonus", 0.0))
    game.call("damage_nearby_combat", damages, attack_reach, 150.0 if tenkishi_flight_active else 125.0, push_forces[basic_combo_step - 1] + float(aerial_profile.get("knockback_bonus", 0.0)), lift_forces[basic_combo_step - 1], 0.18 if basic_combo_step < 3 else float(skill_data.get("stagger", 0.55)) * 0.6)
    game.call("show_notice", str(basic_names[basic_combo_step - 1]) + "！")
    _register_custom_combo_input("basic_attack_%d" % basic_combo_step)
func skill() -> void:
    if skill_cd > 0.0:
        game.call("show_notice", "职业技能冷却中")
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var skill_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var skill_cost := float(skill_data.get("cost", 18))
    if not SkillSystem.can_afford_class_skill(class_id, cosmos):
        game.call("show_notice", "小宇宙不足，需要 %.0f 点" % skill_cost)
        return
    cosmos -= skill_cost
    _play_attack_pose(1.05)
    CombatSessionManager.record_skill_cast()
    skill_cd = float(skill_data.get("cooldown", 3.0))
    combo_window = 1.6
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var skill_level: int = SkillSystem.get_skill_level(class_id)
    var aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile(class_id, tenkishi_flight_active)
    var damage_multiplier: float = float(skill_data.get("damage", 1.5)) * (1.0 + float(skill_level - 1) * 0.08) * SkillSystem.get_skill_damage_multiplier(class_id) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))) * (1.0 + temporary_damage_bonus) * float(aerial_profile.get("damage_multiplier", 1.0))
    var skill_color: Color = skill_data.get("color", Color(0.18, 0.72, 1.0))
    var skill_reach: float = float(skill_data.get("range", 7.0)) + float(aerial_profile.get("range_bonus", 0.0))
    _flash(skill_color)
    game.call("damage_nearby_combat", 18.0 + attack_power * damage_multiplier, skill_reach, float(skill_data.get("cone", 150.0)), float(skill_data.get("knockback", 3.5)) + float(aerial_profile.get("knockback_bonus", 0.0)), float(skill_data.get("launch", 1.2)) + float(aerial_profile.get("launch_bonus", 0.0)), float(skill_data.get("stagger", 0.55)))
    game.call("apply_class_skill_effect", class_id, skill_reach)
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 3.0) + Vector3.UP, skill_color, 2.8)
    game.call("show_notice", str(skill_data.get("name", "职业技能")) + "！")
    _register_custom_combo_input(class_id + "_skill_1")
func combo_skill() -> void:
    if combo_window <= 0.0:
        game.call("show_notice", "先施放职业技能，才能衔接连招")
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var skill_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var cost := float(skill_data.get("cost", 18)) * 1.35
    if cosmos < cost:
        game.call("show_notice", "小宇宙不足，无法施展连招")
        return
    cosmos -= cost
    _play_attack_pose(1.35)
    CombatSessionManager.record_skill_cast(true)
    combo_window = 0.0
    skill_cd = maxf(skill_cd, 1.0)
    var skill_level: int = SkillSystem.get_skill_level(class_id)
    var aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile(class_id, tenkishi_flight_active)
    var damage: float = float(RPGState.get_combat_stats().get("attack", 14.0)) * float(skill_data.get("combo_damage", 2.5)) * (1.0 + float(skill_level - 1) * 0.1) * SkillSystem.get_skill_damage_multiplier(class_id) * SkillSystem.get_combo_damage_multiplier(class_id) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))) * (1.0 + temporary_damage_bonus) * float(aerial_profile.get("damage_multiplier", 1.0))
    var skill_color: Color = skill_data.get("color", Color(0.2, 0.7, 1.0))
    var combo_range: float = float(skill_data.get("combo_range", 8.5)) + float(aerial_profile.get("range_bonus", 0.0))
    _flash(Color(1.0, 0.9, 0.55))
    game.call("damage_nearby_combat", damage, combo_range, 180.0, float(skill_data.get("combo_knockback", 9.0)) + float(aerial_profile.get("knockback_bonus", 0.0)), float(skill_data.get("combo_launch", 3.8)) + float(aerial_profile.get("launch_bonus", 0.0)), float(skill_data.get("stagger", 0.85)) * 1.2)
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 3.5) + Vector3.UP, skill_color, 4.0)
    game.call("show_notice", str(skill_data.get("combo", "职业连招")) + "！")
func cosmos_burst() -> void:
    if burst_cd > 0.0 or cosmos < 35.0:
        game.call("show_notice", "小宇宙能量不足或正在冷却")
        return
    cosmos -= 35.0
    _play_attack_pose(1.45)
    burst_cd = 8.0
    _flash(Color(1.0, 0.4, 0.12))
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var skill_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile(class_id, tenkishi_flight_active)
    var burst_damage: float = (24.0 + float(RPGState.get_combat_stats().get("attack", 14.0)) * 2.0) * SkillSystem.get_skill_damage_multiplier(class_id) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))) * (1.0 + temporary_damage_bonus) * float(aerial_profile.get("damage_multiplier", 1.0))
    var burst_range: float = float(skill_data.get("burst_range", 5.0)) + float(aerial_profile.get("range_bonus", 0.0))
    game.call("damage_nearby_combat", burst_damage, burst_range, 360.0, float(skill_data.get("burst_knockback", 12.0)) + float(aerial_profile.get("knockback_bonus", 0.0)), float(skill_data.get("burst_launch", 4.5)) + float(aerial_profile.get("launch_bonus", 0.0)), float(skill_data.get("stagger", 1.0)))
    game.call("spawn_effect", global_position + Vector3.UP, Color(1.0, 0.42, 0.12), 4.0)
    game.call("show_notice", str(skill_data.get("burst_name", "小宇宙爆发")) + "！")
func dodge() -> void:
    if dodge_time > 0.0: return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var heavenly_wings := class_id == "tenkishi"
    dodge_time = 0.32 if not heavenly_wings else 0.38
    invulnerable = 0.4 if not heavenly_wings else 0.48
    var direction := pivot.global_transform.basis.x * move_input.x + (-pivot.global_transform.basis.z) * -move_input.y
    direction.y = 0
    if direction.length() < 0.1: direction = -global_transform.basis.z
    velocity = direction.normalized() * (15.0 if not heavenly_wings else 18.0)
    _play_attack_pose(0.7)
    game.call("show_notice", "闪避！短暂无敌" if not heavenly_wings else "光翼闪身！天衣短暂无敌")
    _register_custom_combo_input("dodge")
func toggle_lock() -> void:
    var next_target: Node3D = CombatTargeting.select_target(self, locked_target, true)
    if not is_instance_valid(next_target):
        locked_target = null
        game.call("show_notice", "附近没有可锁定目标")
        return
    locked_target = next_target
    var target_name := str(locked_target.get("display_name")) if locked_target.get("display_name") != null else "敌人"
    game.call("show_notice", "已锁定：" + target_name)

func receive_damage(amount: float, attacker_position: Vector3 = Vector3.ZERO) -> void:
    if invulnerable > 0.0: return
    custom_combo_run_id += 1
    custom_combo_auto_running = false
    custom_combo_index = 0
    custom_combo_timer = 0.0
    var defense: float = float(RPGState.get_combat_stats().get("defense", 0.0))
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var facing_dot := 1.0
    if attacker_position != Vector3.ZERO:
        var toward_attacker := attacker_position - global_position
        toward_attacker.y = 0.0
        if toward_attacker.length_squared() > 0.001:
            facing_dot = (-global_transform.basis.z).dot(toward_attacker.normalized())
    var passive_reduction: float = SkillSystem.get_damage_reduction(class_id, facing_dot)
    var final_damage := maxf(1.0, (amount - defense * 0.25) * (1.0 - passive_reduction) * (1.0 - clampf(temporary_damage_reduction, 0.0, 0.65)))
    var class_guard_ratio: float = SkillSystem.get_passive_guard_ratio(str(RPGState.profile.get("class_id", "pegasus")))
    if class_guard_ratio > 0.0 and class_passive_guard_cooldown <= 0.0 and divine_guard_shield <= 0.0 and health - final_damage <= max_health * 0.35:
        apply_divine_guard(class_guard_ratio, 4.0)
        class_passive_guard_cooldown = 18.0
        game.call("show_notice", "星云守护：生命危急，自动展开12%生命护盾")
    var absorbed_damage := minf(divine_guard_shield, final_damage)
    var health_damage := absorb_divine_guard_damage(final_damage)
    health = maxf(0.0, health - health_damage)
    CombatSessionManager.record_damage_taken(health_damage)
    if health_damage > 0.0:
        ArmorSystem.damage_random_part(1)
        _flash(Color(1.0, 0.12, 0.12))
        if bool(SettingsManager.get_value("controls", "vibration", true)):
            Input.vibrate_handheld(45, 0.35)
    elif absorbed_damage > 0.0:
        _flash(Color(0.35, 0.8, 1.0))
    if health <= 0.0:
        health = max_health
        global_position = Vector3(0, 0.2, 7)
        game.call("show_notice", "角色倒地，已在训练场复位")
func absorb_divine_guard_damage(incoming_damage: float) -> float:
    var absorbed_damage := minf(divine_guard_shield, maxf(0.0, incoming_damage))
    divine_guard_shield = maxf(0.0, divine_guard_shield - absorbed_damage)
    return maxf(0.0, incoming_damage - absorbed_damage)

func apply_divine_guard(shield_ratio: float = 0.18, duration: float = 6.0) -> void:
    var shield_capacity := max_health * clampf(shield_ratio, 0.0, 0.25)
    if divine_guard_shield <= 0.0:
        divine_guard_shield = shield_capacity
    divine_guard_timer = maxf(divine_guard_timer, maxf(0.1, duration))

func apply_temporary_buff(damage_bonus: float, damage_reduction: float, duration: float) -> void:
    temporary_damage_bonus = maxf(temporary_damage_bonus, damage_bonus)
    temporary_damage_reduction = maxf(temporary_damage_reduction, damage_reduction)
    temporary_buff_timer = maxf(temporary_buff_timer, duration)

func _flash(color: Color) -> void:
    body_mat.albedo_color = color
    get_tree().create_timer(0.16).timeout.connect(func():
        if is_instance_valid(body_mat):
            body_mat.albedo_color = armor_base_color
    )

func toggle_mount() -> void:
 var state: Dictionary = CollectionSystem.get_state()
 var mount_id := str(state.get("active_mount",""))
 if mount_id == "":
  game.call("show_notice","尚未拥有或装备坐骑，请先到伙伴图鉴查看")
  return
 is_mounted = not is_mounted
 if is_instance_valid(mount_indicator):
  mount_indicator.visible = is_mounted
 game.call("show_notice","已骑乘：" + str(CollectionSystem.MOUNTS.get(mount_id,{}).get("name","坐骑")) if is_mounted else "已下马")

func apply_enemy_knockback(direction: Vector3, force: float) -> void:
    var flat_direction := direction
    flat_direction.y = 0.0
    if flat_direction.length_squared() <= 0.001:
        flat_direction = -global_transform.basis.z
    knockback_velocity = flat_direction.normalized() * force

func guard() -> void:
    apply_temporary_buff(0.0, 0.35, 1.2)
    game.call("show_notice", "架势防御！")
    _register_custom_combo_input("guard")

func _register_custom_combo_input(action_id: String) -> void:
    if custom_combo_auto_running:
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var preset := ComboPresetManager.get_active_preset(class_id)
    var steps: Array = preset.get("steps", [])
    if steps.is_empty():
        return
    if custom_combo_timer <= 0.0:
        custom_combo_index = 0
    if str(steps[custom_combo_index]) == action_id:
        custom_combo_index += 1
    elif str(steps[0]) == action_id:
        custom_combo_index = 1
    else:
        custom_combo_index = 0
    custom_combo_timer = float(preset.get("input_window", 0.65))
    if custom_combo_index >= steps.size():
        _execute_custom_combo_finisher(preset)
        custom_combo_index = 0
        custom_combo_timer = 0.0
        return
    if str(preset.get("trigger_mode", "")) == "自动衔接" and custom_combo_index == 1:
        _run_custom_combo_auto(preset)

func _run_custom_combo_auto(preset: Dictionary) -> void:
    if custom_combo_auto_running:
        return
    custom_combo_auto_running = true
    custom_combo_run_id += 1
    var run_id := custom_combo_run_id
    var steps: Array = preset.get("steps", [])
    for i in range(1, steps.size()):
        await get_tree().create_timer(0.32).timeout
        if not is_inside_tree() or run_id != custom_combo_run_id:
            return
        var action_id := str(steps[i])
        if not _execute_custom_combo_step(action_id):
            custom_combo_auto_running = false
            custom_combo_index = 0
            custom_combo_timer = 0.0
            game.call("show_notice", "连招中断：动作冷却中或小宇宙不足")
            return
    if run_id != custom_combo_run_id:
        return
    custom_combo_auto_running = false
    _execute_custom_combo_finisher(preset)
    custom_combo_index = 0
    custom_combo_timer = 0.0


func _execute_custom_combo_step(action_id: String) -> bool:
    if action_id.begins_with("basic_attack_"):
        if attack_cd > 0.0:
            return false
        var requested_step := clampi(int(action_id.get_slice("_", 2)), 1, 3)
        basic_combo_step = requested_step - 1
        basic_combo_reset = 0.95
        attack()
        return basic_combo_step == requested_step
    if action_id == "dodge":
        if dodge_time > 0.0:
            return false
        dodge()
        return true
    if action_id == "guard":
        guard()
        return true
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var ability: Dictionary = SkillSystem.get_ability_data(class_id, action_id)
    if ability.is_empty() or not SkillSystem.is_ability_learned(class_id, action_id):
        return false
    if float(ability_cooldowns.get(action_id, 0.0)) > 0.0 or cosmos < float(ability.get("cost", 12)):
        return false
    return cast_ability(action_id)

func _execute_custom_combo_finisher(preset: Dictionary) -> void:
    var steps: Array = preset.get("steps", [])
    if steps.is_empty():
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var skill_level: int = SkillSystem.get_skill_level(class_id)
    var damage: float = attack_power * (1.1 + float(steps.size()) * 0.42) * (1.0 + float(skill_level - 1) * 0.05) * SkillSystem.get_skill_damage_multiplier(class_id) * SkillSystem.get_combo_damage_multiplier(class_id) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0)))
    var reach := float(class_data.get("combo_range", 8.5))
    var color: Color = class_data.get("color", Color(0.35, 0.75, 1.0))
    CombatSessionManager.record_skill_cast(true)
    _flash(Color(1.0, 0.88, 0.42))
    game.call("damage_nearby_combat", damage, reach, 180.0, float(class_data.get("combo_knockback", 7.0)), float(class_data.get("combo_launch", 2.8)), float(class_data.get("stagger", 0.7)))
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 3.0) + Vector3.UP, color, 3.2)
    game.call("show_notice", str(preset.get("name", "自定义连招")) + " · 连携终结！")

func cast_skill_slot(slot_index: int) -> void:
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var slots: Array = SkillSystem.get_equipped_abilities(class_id)
    if slot_index < 0 or slot_index >= slots.size():
        return
    var ability_id := str(slots[slot_index])
    if ability_id == "":
        game.call("show_notice", "技能栏第 %d 格尚未装备技能" % (slot_index + 1))
        return
    cast_ability(ability_id)
func cast_ability(ability_id: String) -> bool:
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var ability: Dictionary = SkillSystem.get_ability_data(class_id, ability_id)
    if ability.is_empty() or not SkillSystem.is_ability_learned(class_id, ability_id):
        game.call("show_notice", "技能尚未学习")
        return false
    var remaining := float(ability_cooldowns.get(ability_id, 0.0))
    if remaining > 0.0:
        game.call("show_notice", "技能冷却中：%.1f 秒" % remaining)
        return false
    var cost := float(ability.get("cost", 12))
    if cosmos < cost:
        game.call("show_notice", "小宇宙不足，需要 %.0f 点" % cost)
        return false
    cosmos -= cost
    _play_attack_pose(1.2)
    CombatSessionManager.record_skill_cast()
    ability_cooldowns[ability_id] = float(ability.get("cooldown", 6))
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var ability_type := str(ability.get("type", "攻击"))
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var level_scale := 1.0 + float(SkillSystem.get_skill_level(class_id) - 1) * 0.06
    var type_scale := 1.25 if ("奥义" in ability_type or "终结" in ability_type) else (0.72 if ("防御" in ability_type or "治疗" in ability_type or "守护" in ability_type) else 1.0)
    var aerial_profile: Dictionary = SkillSystem.get_aerial_combat_profile(class_id, tenkishi_flight_active)
    var damage: float = (10.0 + attack_power * float(class_data.get("damage", 1.5)) * type_scale * level_scale) * SkillSystem.get_skill_damage_multiplier(class_id) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))) * (1.0 + temporary_damage_bonus) * float(aerial_profile.get("damage_multiplier", 1.0))
    var reach := float(class_data.get("range", 7.0)) + float(aerial_profile.get("range_bonus", 0.0))
    if "远程" in ability_type or "次元" in ability_type or "音波" in ability_type:
        reach += 2.0
    var cone := 360.0 if ("范围" in str(ability.get("role", "")) or "领域" in ability_type or "震地" in ability_type) else float(class_data.get("cone", 145.0))
    var ability_profile: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var projectile_action := str(ability_profile.get("action", "")) in ["projectile", "homing_projectile"]
    _flash(class_data.get("color", Color(0.25, 0.72, 1.0)))
    if not SkillSystem.is_support_ability(ability) and not projectile_action:
        game.call("damage_nearby_combat", damage, reach, cone, float(class_data.get("knockback", 3.5)) * 1.15 + float(aerial_profile.get("knockback_bonus", 0.0)), float(class_data.get("launch", 1.0)) + float(aerial_profile.get("launch_bonus", 0.0)), float(class_data.get("stagger", 0.5)))
    game.call("apply_ability_effect", class_id, ability, reach)
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 2.5) + Vector3.UP, class_data.get("color", Color(0.25, 0.72, 1.0)), 2.2)
    game.call("show_notice", str(ability.get("name", "职业技能")) + "！")
    _register_custom_combo_input(ability_id)
    return true
