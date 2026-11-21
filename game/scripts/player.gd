extends CharacterBody3D
const CombatTargeting = preload("res://scripts/combat_targeting.gd")
const CharacterVisualCatalog = preload("res://scripts/character_visual_catalog.gd")
const SkillAnimationCatalog = preload("res://scripts/skill_animation_catalog.gd")
const SkillVisualCatalog = preload("res://scripts/skill_visual_catalog.gd")
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
var upper_arm_nodes: Array[MeshInstance3D] = []
var forearm_nodes: Array[MeshInstance3D] = []
var leg_nodes: Array[MeshInstance3D] = []
var armor_wing_nodes: Array[MeshInstance3D] = []
var armor_wing_base_angles: Array[float] = []
var armor_skirt_nodes: Array[MeshInstance3D] = []
var armor_skirt_base_angles: Array[float] = []
var armor_aura_node: MeshInstance3D
var armor_gem_nodes: Array[MeshInstance3D] = []
var combat_pose_timer := 0.0
var combat_pose_duration := 0.0
var combat_pose_strength := 0.0
var combat_pose_motion := "strike"
var combat_feedback_node: MeshInstance3D
var combat_feedback_material: StandardMaterial3D
var combat_feedback_timer := 0.0
var combat_feedback_duration := 0.0
var combat_feedback_color := Color.WHITE
var guard_shield_node: MeshInstance3D
var guard_shield_material: StandardMaterial3D
var guard_shield_timer := 0.0
var guard_shield_duration := 0.0
var auto_target_timer := 0.0
var body_mat: StandardMaterial3D
var visual_flash_timer := 0.0
var visual_flash_color := Color.WHITE
var armor_root: Node3D
var armor_visual_wear_profile: Dictionary = {}
var armor_base_color := Color(0.18, 0.52, 0.95)
var visual_class_id := ""
var visual_armor_signature := ""
var authored_character_model: Node3D
var authored_animation_player: AnimationPlayer
var authored_animation_state := ""
var authored_action_animation_timer := 0.0
var training_down_timer := 0.0
var authored_was_on_floor := true
var authored_armor_model: Node3D
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

    # A lightweight humanoid fallback mesh keeps the character readable before
    # authored skeletal rigs are imported.
    var skin_material := StandardMaterial3D.new()
    skin_material.albedo_color = Color(0.78, 0.58, 0.46)
    skin_material.roughness = 0.72
    var hair_material := StandardMaterial3D.new()
    hair_material.albedo_color = Color(0.055, 0.065, 0.11)
    hair_material.roughness = 0.42
    var limb_mesh := CapsuleMesh.new()
    limb_mesh.radius = 0.14
    limb_mesh.height = 0.68
    for side in [-1.0, 1.0]:
        var upper_arm := MeshInstance3D.new()
        upper_arm.mesh = limb_mesh
        upper_arm.position = Vector3(side * 0.49, 1.17, 0.0)
        upper_arm.rotation.z = -side * 0.18
        upper_arm.material_override = skin_material
        visual_root.add_child(upper_arm)
        upper_arm_nodes.append(upper_arm)
        var forearm := MeshInstance3D.new()
        forearm.mesh = limb_mesh
        forearm.scale = Vector3(0.88, 0.82, 0.88)
        forearm.position = Vector3(side * 0.54, 0.76, -0.015)
        forearm.rotation.z = -side * 0.10
        forearm.material_override = skin_material
        visual_root.add_child(forearm)
        forearm_nodes.append(forearm)
        var leg_mesh := CapsuleMesh.new()
        leg_mesh.radius = 0.16
        leg_mesh.height = 0.76
        var leg := MeshInstance3D.new()
        leg.mesh = leg_mesh
        leg.position = Vector3(side * 0.21, 0.40, 0.015)
        leg.material_override = skin_material
        visual_root.add_child(leg)
        leg_nodes.append(leg)
        var boot := MeshInstance3D.new()
        var boot_mesh := BoxMesh.new()
        boot_mesh.size = Vector3(0.28, 0.16, 0.42)
        boot.mesh = boot_mesh
        boot.position = Vector3(side * 0.21, 0.09, -0.075)
        boot.material_override = hair_material
        visual_root.add_child(boot)

    var hair := MeshInstance3D.new()
    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.25
    hair_mesh.height = 0.24
    hair.mesh = hair_mesh
    hair.scale = Vector3(1.12, 0.72, 1.12)
    hair.position = Vector3(0.0, 2.12, 0.035)
    hair.material_override = hair_material
    visual_root.add_child(hair)
    var eye_band := MeshInstance3D.new()
    var eye_mesh := BoxMesh.new()
    eye_mesh.size = Vector3(0.24, 0.035, 0.035)
    eye_band.mesh = eye_mesh
    eye_band.position = Vector3(0.0, 1.98, -0.218)
    var eye_material := StandardMaterial3D.new()
    eye_material.albedo_color = Color(0.10, 0.12, 0.18)
    eye_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    eye_band.material_override = eye_material
    visual_root.add_child(eye_band)

    _build_armor_visuals()
    _load_authored_character_model(str(RPGState.profile.get("class_id", "pegasus")))
    _load_authored_armor_model()
    _build_combat_feedback_visual()
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
    if is_instance_valid(combat_feedback_node):
        combat_feedback_timer = maxf(0.0, combat_feedback_timer - delta)
        var feedback_ratio := combat_feedback_timer / maxf(0.001, combat_feedback_duration)
        combat_feedback_node.visible = combat_feedback_timer > 0.0
        if combat_feedback_timer > 0.0:
            var feedback_progress := 1.0 - feedback_ratio
            var feedback_scale := lerpf(0.72, 1.55, feedback_progress)
            combat_feedback_node.scale = Vector3.ONE * feedback_scale
            combat_feedback_material.albedo_color = Color(combat_feedback_color.r, combat_feedback_color.g, combat_feedback_color.b, 0.42 * feedback_ratio)
            combat_feedback_material.emission = combat_feedback_color * (0.45 + feedback_ratio * 1.8)
    guard_shield_timer = maxf(0.0, guard_shield_timer - delta)
    if is_instance_valid(guard_shield_node) and is_instance_valid(guard_shield_material):
        guard_shield_node.visible = guard_shield_timer > 0.0
        if guard_shield_timer > 0.0:
            var shield_ratio := guard_shield_timer / maxf(0.001, guard_shield_duration)
            var shield_pulse := 1.0 + sin(float(Time.get_ticks_msec()) * 0.018) * 0.045
            guard_shield_node.scale = Vector3(0.58, 0.78, 0.12) * shield_pulse
            guard_shield_material.albedo_color = Color(1.0, 0.72, 0.24, 0.18 + shield_ratio * 0.24)
            guard_shield_material.emission_energy_multiplier = 0.8 + shield_ratio * 1.8
    var planar_speed := Vector2(velocity.x, velocity.z).length()
    authored_action_animation_timer = maxf(0.0, authored_action_animation_timer - delta)
    if authored_action_animation_timer <= 0.0:
        var animation_name := "run" if planar_speed >= 5.0 else ("walk" if planar_speed >= 0.35 else "idle")
        if not is_on_floor():
            animation_name = "jump" if velocity.y > 0.5 else "fall"
        _play_authored_animation(animation_name)
    var movement_ratio := clampf(planar_speed / 7.0, 0.0, 1.0)
    var clock := float(Time.get_ticks_msec()) * 0.012
    var idle_breath := sin(clock * 0.72) * 0.012
    var bob := idle_breath + sin(clock) * 0.035 * movement_ratio
    if tenkishi_flight_active:
        bob += sin(clock * 0.72) * 0.045
    if is_instance_valid(body_mat):
        var breath_glow := 0.92 + (sin(clock * 0.72) * 0.5 + 0.5) * 0.12
        body_mat.emission = armor_base_color * 0.035 * breath_glow
    visual_root.position.y = lerpf(visual_root.position.y, bob, minf(1.0, delta * 9.0))
    var wing_motion := sin(clock * (1.35 if tenkishi_flight_active else 0.82)) * (0.16 + movement_ratio * 0.18)
    if tenkishi_flight_active:
        wing_motion *= 1.65
    var cloth_sway := sin(clock * 1.35) * (0.045 + movement_ratio * 0.09)
    if tenkishi_flight_active:
        cloth_sway *= 1.7
    for skirt_index in range(armor_skirt_nodes.size()):
        var skirt_side := -1.0 if skirt_index % 2 == 0 else 1.0
        var skirt_base := armor_skirt_base_angles[skirt_index] if skirt_index < armor_skirt_base_angles.size() else 0.0
        var skirt_target := skirt_base + skirt_side * cloth_sway
        armor_skirt_nodes[skirt_index].rotation.z = lerp_angle(armor_skirt_nodes[skirt_index].rotation.z, skirt_target, minf(1.0, delta * 6.0))
    for wing_index in range(armor_wing_nodes.size()):
        var wing_side := -1.0 if wing_index % 2 == 0 else 1.0
        var wing_base := armor_wing_base_angles[wing_index] if wing_index < armor_wing_base_angles.size() else 0.0
        var wing_target := wing_base + wing_side * wing_motion
        armor_wing_nodes[wing_index].rotation.z = lerp_angle(armor_wing_nodes[wing_index].rotation.z, wing_target, minf(1.0, delta * 5.5))
    if is_instance_valid(armor_aura_node):
        armor_aura_node.rotation.y += delta * (0.28 + movement_ratio * 0.42)
        var aura_pulse := 1.0 + sin(clock * 1.7) * 0.035
        armor_aura_node.scale = Vector3.ONE * aura_pulse
    var gem_pulse := 0.72 + (sin(clock * 2.6) * 0.5 + 0.5) * 0.38
    for gem in armor_gem_nodes:
        if not is_instance_valid(gem):
            continue
        var gem_material := gem.material_override as StandardMaterial3D
        if is_instance_valid(gem_material):
            gem_material.emission_energy_multiplier = gem_pulse
        gem.scale = Vector3.ONE * (0.96 + gem_pulse * 0.08)
    var target_roll := -move_input.x * 0.10
    var target_pitch := move_input.y * 0.055
    visual_root.rotation.z = lerp_angle(visual_root.rotation.z, target_roll, minf(1.0, delta * 8.0))
    visual_root.rotation.x = lerp_angle(visual_root.rotation.x, target_pitch, minf(1.0, delta * 8.0))
    combat_pose_timer = maxf(0.0, combat_pose_timer - delta)
    var pose_progress := 1.0 - combat_pose_timer / maxf(0.001, combat_pose_duration)
    var pose_weight := sin(clampf(pose_progress, 0.0, 1.0) * PI) * combat_pose_strength
    for limb_index in range(2):
        var side := -1.0 if limb_index == 0 else 1.0
        var gait := sin(clock + (PI if limb_index == 1 else 0.0)) * 0.42 * movement_ratio
        var arm_target := gait
        var forearm_target := -0.12 * movement_ratio
        var leg_target := -gait * 0.9
        if combat_pose_motion == "dash":
            arm_target = lerpf(arm_target, 0.52 if limb_index == 1 else 0.34, pose_weight)
            forearm_target = lerpf(forearm_target, -0.62, pose_weight)
            leg_target = lerpf(leg_target, -0.28 if limb_index == 1 else 0.48, pose_weight)
        elif combat_pose_motion == "heavy":
            arm_target = lerpf(arm_target, -1.18 if limb_index == 1 else -0.62, pose_weight)
            forearm_target = lerpf(forearm_target, -0.58 if limb_index == 1 else -0.30, pose_weight)
        elif combat_pose_motion in ["strike", "leap", "aerial_strike"]:
            arm_target = lerpf(arm_target, -0.95 if limb_index == 1 else -0.28, pose_weight)
            forearm_target = lerpf(forearm_target, -0.42 if limb_index == 1 else -0.18, pose_weight)
        elif combat_pose_motion == "guard":
            arm_target = lerpf(arm_target, -0.82 if limb_index == 1 else -0.48, pose_weight)
            forearm_target = lerpf(forearm_target, -0.88, pose_weight)
        elif combat_pose_motion == "hit":
            arm_target = lerpf(arm_target, 0.42 if limb_index == 1 else 0.18, pose_weight)
            forearm_target = lerpf(forearm_target, -0.12, pose_weight)
        elif combat_pose_motion == "chain":
            arm_target = lerpf(arm_target, -1.02 if limb_index == 1 else -0.72, pose_weight)
            forearm_target = lerpf(forearm_target, -0.82 if limb_index == 1 else -0.48, pose_weight)
        elif combat_pose_motion == "bow":
            arm_target = lerpf(arm_target, -0.22 if limb_index == 1 else -1.12, pose_weight)
            forearm_target = lerpf(forearm_target, -0.18 if limb_index == 1 else -0.72, pose_weight)
        elif combat_pose_motion == "instrument":
            arm_target = lerpf(arm_target, -0.62 if limb_index == 1 else -0.48, pose_weight)
            forearm_target = lerpf(forearm_target, -0.52 if limb_index == 1 else -0.36, pose_weight)
        elif combat_pose_motion in ["divine", "cast", "summon"]:
            arm_target = lerpf(arm_target, -0.92 if limb_index == 1 else -0.88, pose_weight)
            forearm_target = lerpf(forearm_target, -0.68, pose_weight)
        elif combat_pose_motion == "shield_strike":
            arm_target = lerpf(arm_target, -1.08 if limb_index == 1 else -0.42, pose_weight)
            forearm_target = lerpf(forearm_target, -0.96 if limb_index == 1 else -0.28, pose_weight)
        elif combat_pose_motion == "axe":
            arm_target = lerpf(arm_target, -1.34 if limb_index == 1 else -0.74, pose_weight)
            forearm_target = lerpf(forearm_target, -0.72 if limb_index == 1 else -0.42, pose_weight)
        elif combat_pose_motion == "throw":
            arm_target = lerpf(arm_target, -1.22 if limb_index == 1 else 0.12, pose_weight)
            forearm_target = lerpf(forearm_target, -0.86 if limb_index == 1 else -0.12, pose_weight)
        elif combat_pose_motion in ["cast", "spin"]:
            arm_target = lerpf(arm_target, -0.38, pose_weight)
            forearm_target = lerpf(forearm_target, -0.24, pose_weight)
        if limb_index < upper_arm_nodes.size():
            upper_arm_nodes[limb_index].rotation.x = lerp_angle(upper_arm_nodes[limb_index].rotation.x, arm_target, minf(1.0, delta * 12.0))
            upper_arm_nodes[limb_index].rotation.z = lerp_angle(upper_arm_nodes[limb_index].rotation.z, -side * (0.18 + pose_weight * 0.08), minf(1.0, delta * 10.0))
        if limb_index < forearm_nodes.size():
            forearm_nodes[limb_index].rotation.x = lerp_angle(forearm_nodes[limb_index].rotation.x, forearm_target, minf(1.0, delta * 12.0))
        if limb_index < leg_nodes.size():
            leg_nodes[limb_index].rotation.x = lerp_angle(leg_nodes[limb_index].rotation.x, leg_target, minf(1.0, delta * 10.0))

func _build_combat_feedback_visual() -> void:
    if not is_instance_valid(visual_root):
        return
    combat_feedback_node = MeshInstance3D.new()
    combat_feedback_node.name = "CombatFeedbackRing"
    var ring := TorusMesh.new()
    ring.inner_radius = 0.56
    ring.outer_radius = 0.72
    combat_feedback_node.mesh = ring
    combat_feedback_node.position = Vector3(0.0, 0.12, 0.0)
    combat_feedback_node.rotation.x = PI * 0.5
    combat_feedback_material = StandardMaterial3D.new()
    combat_feedback_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    combat_feedback_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    combat_feedback_material.albedo_color = Color(0.25, 0.8, 1.0, 0.0)
    combat_feedback_material.emission_enabled = true
    combat_feedback_material.emission = Color(0.25, 0.8, 1.0)
    combat_feedback_material.emission_energy_multiplier = 1.4
    combat_feedback_node.material_override = combat_feedback_material
    combat_feedback_node.visible = false
    visual_root.add_child(combat_feedback_node)
    guard_shield_node = MeshInstance3D.new()
    guard_shield_node.name = "GuardShieldFlash"
    var shield_mesh := SphereMesh.new()
    shield_mesh.radius = 0.5
    shield_mesh.height = 1.0
    guard_shield_node.mesh = shield_mesh
    guard_shield_node.position = Vector3(0.0, 1.05, -0.52)
    guard_shield_node.visible = false
    guard_shield_material = StandardMaterial3D.new()
    guard_shield_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    guard_shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    guard_shield_material.albedo_color = Color(1.0, 0.72, 0.24, 0.3)
    guard_shield_material.emission_enabled = true
    guard_shield_material.emission = Color(1.0, 0.62, 0.12)
    guard_shield_material.emission_energy_multiplier = 1.4
    guard_shield_node.material_override = guard_shield_material
    guard_shield_node.scale = Vector3(0.58, 0.78, 0.12)
    visual_root.add_child(guard_shield_node)

func _play_combat_feedback(color: Color, duration: float = 0.34) -> void:
    if not is_instance_valid(combat_feedback_node):
        return
    combat_feedback_color = color
    combat_feedback_duration = maxf(0.12, duration)
    combat_feedback_timer = combat_feedback_duration
    combat_feedback_node.visible = true
    combat_feedback_node.scale = Vector3.ONE * 0.72

func _play_skill_pose(profile: Dictionary) -> void:
    if not is_instance_valid(visual_root):
        return
    if is_instance_valid(visual_pose_tween):
        visual_pose_tween.kill()
    var base_scale: Vector3 = visual_root.scale
    var base_yaw := visual_root.rotation.y
    var pose_scale := clampf(float(profile.get("pose_scale", 1.08)), 1.0, 1.24)
    combat_pose_duration = maxf(0.24, float(profile.get("total_duration", 0.7)))
    combat_pose_timer = combat_pose_duration
    combat_pose_strength = 1.0
    combat_pose_motion = str(profile.get("motion", "strike"))
    var rotation_target := base_yaw + deg_to_rad(float(profile.get("rotation_degrees", 0.0)))
    var startup := clampf(float(profile.get("startup", 0.2)), 0.1, 0.8)
    var active := clampf(float(profile.get("active", 0.2)), 0.18, 1.0)
    var recovery := clampf(float(profile.get("recovery", 0.3)), 0.18, 0.9)
    visual_pose_tween = create_tween()
    visual_pose_tween.tween_property(visual_root, "scale", base_scale * pose_scale, startup)
    visual_pose_tween.parallel().tween_property(visual_root, "rotation:y", rotation_target, startup)
    visual_pose_tween.tween_interval(active)
    visual_pose_tween.tween_property(visual_root, "scale", base_scale, recovery)
    visual_pose_tween.parallel().tween_property(visual_root, "rotation:y", base_yaw, minf(0.22, recovery))

func _play_attack_pose(intensity: float = 1.0, motion: String = "strike") -> void:
    if not is_instance_valid(visual_root):
        return
    if is_instance_valid(visual_pose_tween):
        visual_pose_tween.kill()
    visual_root.scale = Vector3.ONE
    combat_pose_duration = 0.22
    combat_pose_timer = combat_pose_duration
    combat_pose_strength = clampf(intensity, 0.35, 1.4)
    combat_pose_motion = motion
    visual_pose_tween = create_tween()
    var recoil := Vector3(1.0 + 0.055 * intensity, 1.0 - 0.075 * intensity, 1.0 + 0.055 * intensity)
    visual_pose_tween.tween_property(visual_root, "scale", recoil, 0.065)
    visual_pose_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.15)

func _get_visual_armor_signature() -> String:
    return JSON.stringify({
        "class_id": RPGState.profile.get("class_id", "pegasus"),
        "equipped_relic": RPGState.profile.get("equipped_relic", ""),
        "equipment": RPGState.profile.get("equipment", {}),
        "armor_state": RPGState.profile.get("armor_state", {})
    })

func _on_rpg_state_changed() -> void:
    if _get_visual_armor_signature() != visual_armor_signature:
        _build_armor_visuals()
        _load_authored_character_model(str(RPGState.profile.get("class_id", "pegasus")))
        _load_authored_armor_model()

func _get_armor_visual_part(piece_position: Vector3) -> String:
    var height := piece_position.y
    if height >= 1.82:
        return "head"
    if absf(piece_position.x) >= 0.40 and height >= 0.68 and height < 1.82:
        return "arms"
    if height >= 0.86:
        return "chest"
    if height >= 0.56:
        return "waist"
    return "legs"

func _add_armor_piece(mesh: Mesh, piece_position: Vector3, piece_scale: Vector3, piece_color: Color, metallic: float = 0.72, part_id: String = "") -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.mesh = mesh
    piece.position = piece_position
    piece.scale = piece_scale
    var resolved_part := part_id if part_id in ArmorSystem.PARTS else _get_armor_visual_part(piece_position)
    var part_wear: Dictionary = ArmorSystem.get_part_visual_wear_profile(resolved_part)
    var material := StandardMaterial3D.new()
    var wear_tint: Color = part_wear.get("tint", Color.WHITE)
    material.albedo_color = piece_color * wear_tint
    material.metallic = clampf(metallic * float(part_wear.get("metallic_multiplier", 1.0)), 0.0, 1.0)
    material.roughness = clampf(float(part_wear.get("roughness", 0.24)), 0.18, 0.72)
    material.emission_enabled = true
    material.emission = piece_color * 0.06 * float(part_wear.get("condition", 1.0))
    piece.material_override = material
    armor_root.add_child(piece)
    return piece

func _build_armor_wear_cracks() -> void:
    # Crack anchors follow the visible front-facing plates for each durability part.
    var crack_layout := {
        "head": [Vector3(-0.14, 2.03, -0.255), Vector3(0.13, 1.94, -0.255), Vector3(0.0, 2.12, -0.13)],
        "chest": [Vector3(-0.22, 1.42, -0.445), Vector3(0.18, 1.25, -0.445), Vector3(0.0, 1.12, -0.405)],
        "arms": [Vector3(-0.49, 1.08, -0.205), Vector3(0.49, 1.08, -0.205), Vector3(-0.55, 1.48, -0.16), Vector3(0.55, 1.48, -0.16)],
        "waist": [Vector3(-0.20, 0.66, -0.365), Vector3(0.20, 0.66, -0.365), Vector3(0.0, 0.59, -0.365)],
        "legs": [Vector3(-0.22, 0.38, -0.325), Vector3(0.22, 0.38, -0.325), Vector3(-0.22, 0.55, -0.29), Vector3(0.22, 0.55, -0.29)]
    }
    for part_id in ArmorSystem.PARTS:
        var wear: Dictionary = ArmorSystem.get_part_visual_wear_profile(str(part_id))
        var condition := float(wear.get("condition", 1.0))
        if condition > 0.35:
            continue
        var severity := clampf((0.35 - condition) / 0.35, 0.0, 1.0)
        var anchors: Array = crack_layout.get(part_id, [])
        for anchor_index in range(anchors.size()):
            var anchor: Vector3 = anchors[anchor_index]
            for segment_index in range(3):
                var crack_mesh := BoxMesh.new()
                crack_mesh.size = Vector3(0.014 + severity * 0.006, 0.075 + severity * 0.09, 0.014)
                var crack := MeshInstance3D.new()
                crack.mesh = crack_mesh
                crack.position = anchor + Vector3((float(segment_index) - 1.0) * 0.026, -float(segment_index) * 0.035, 0.0)
                crack.rotation.z = (-0.42 if (anchor_index + segment_index) % 2 == 0 else 0.42)
                var crack_material := StandardMaterial3D.new()
                crack_material.albedo_color = Color(0.055, 0.025, 0.035, 0.5 + severity * 0.45)
                crack_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
                crack_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                crack_material.emission_enabled = true
                crack_material.emission = Color(0.16, 0.025, 0.035) * severity
                crack.material_override = crack_material
                armor_root.add_child(crack)

func _build_armor_visuals() -> void:
    if not is_instance_valid(visual_root):
        return
    if is_instance_valid(armor_root):
        armor_root.queue_free()
    armor_wing_nodes.clear()
    armor_wing_base_angles.clear()
    armor_skirt_nodes.clear()
    armor_skirt_base_angles.clear()
    armor_aura_node = null
    armor_gem_nodes.clear()
    armor_root = Node3D.new()
    armor_root.name = "ProceduralSaintArmor"
    visual_root.add_child(armor_root)

    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var visual_profile := CharacterVisualCatalog.get_profile(class_id)
    var relic_visual_profile := CharacterVisualCatalog.get_equipment_profile(EquipmentDatabase.get_equipped_relic())
    var ornament_id := str(relic_visual_profile.get("ornament", visual_profile.get("ornament", "")))
    armor_base_color = class_data.get("color", Color(0.22, 0.52, 0.92))
    visual_class_id = class_id
    var accent: Color = relic_visual_profile.get("accent", visual_profile.get("accent", Color(1.0, 0.78, 0.28)))
    var stage_state: Dictionary = ArmorSystem.get_state()
    armor_visual_wear_profile = ArmorSystem.get_visual_wear_profile(ArmorSystem.get_condition_ratio())
    var stage_id := str(stage_state.get("current_stage", "bronze"))
    var stage_palette: Dictionary = CharacterVisualCatalog.get_stage_palette(stage_id, bool(stage_state.get("awakened", false)))
    var stage_metal_color: Color = stage_palette.get("metal", armor_base_color)
    var stage_trim_color: Color = stage_palette.get("trim", accent)
    var bright: Color = stage_metal_color.lightened(0.22).lerp(armor_base_color, 0.16)
    var dark: Color = stage_metal_color.darkened(0.38)
    var stage_metallic := clampf(float(stage_palette.get("metallic", 0.8)) + float(visual_profile.get("metallic", 0.82)) * 0.06, 0.0, 1.0)
    var stage_glow := minf(0.6, float(visual_profile.get("glow", 0.1)) + float(stage_palette.get("glow", 0.0)))
    var silhouette_id := str(visual_profile.get("silhouette", "balanced"))
    var silhouette_width := 1.0
    var silhouette_height := 1.0
    var silhouette_waist := 1.0
    match silhouette_id:
        "swift", "flow", "elegant", "grace":
            silhouette_width = 0.92
            silhouette_height = 0.96
            silhouette_waist = 0.94
        "guard", "guardian", "war", "forge", "titan":
            silhouette_width = 1.16
            silhouette_height = 1.08
            silhouette_waist = 1.12
        "frost", "tidal", "ocean", "lunar":
            silhouette_width = 1.04
            silhouette_height = 1.02
        "flare", "solar", "storm", "celestial", "radiant":
            silhouette_width = 1.12
            silhouette_height = 1.12
        "reaper", "fallen", "chaos":
            silhouette_width = 1.10
            silhouette_height = 1.08
            silhouette_waist = 1.08
        "chrono", "dream", "rune", "resonance", "nature", "hearth", "royal":
            silhouette_width = 1.02
            silhouette_height = 1.06
    var stage_structure := 1.0
    match stage_id:
        "silver":
            stage_structure = 1.04
        "gold", "sea_scale", "surplice":
            stage_structure = 1.10
        "god_cloth":
            stage_structure = 1.18
        "god_armor":
            stage_structure = 1.24
    visual_armor_signature = _get_visual_armor_signature()

    if is_instance_valid(body_mat):
        body_mat.albedo_color = armor_base_color
        body_mat.metallic = stage_metallic
        body_mat.emission = armor_base_color * 0.08

    # Layered torso plates: chest, abdomen, collar and a raised central crest.
    var chest := BoxMesh.new()
    chest.size = Vector3(0.72 * silhouette_width * stage_structure, 0.54 * silhouette_height, 0.20)
    _add_armor_piece(chest, Vector3(0.0, 1.28, -0.32), Vector3.ONE, bright, stage_metallic, "chest")
    var abdomen := BoxMesh.new()
    abdomen.size = Vector3(0.56 * silhouette_width, 0.28 * silhouette_height, 0.18)
    _add_armor_piece(abdomen, Vector3(0.0, 0.88, -0.30), Vector3.ONE, dark, stage_metallic * 0.94, "chest")
    var collar := BoxMesh.new()
    collar.size = Vector3(0.82 * silhouette_width * stage_structure, 0.12 * silhouette_height, 0.24)
    _add_armor_piece(collar, Vector3(0.0, 1.58, -0.24), Vector3.ONE, accent.darkened(0.12), stage_metallic, "chest")
    if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"]:
        var chest_side_plate := PrismMesh.new()
        chest_side_plate.size = Vector3(0.18 * stage_structure, 0.42 * silhouette_height, 0.16)
        for side in [-1.0, 1.0]:
            var side_plate := _add_armor_piece(chest_side_plate, Vector3(side * 0.34 * silhouette_width, 1.28, -0.25), Vector3.ONE, stage_trim_color, stage_metallic, "chest")
            side_plate.rotation.z = -side * 0.12
    # Raised breastplate contours vary with the class motif and evolve by armor tier.
    var chest_contour := PrismMesh.new()
    chest_contour.size = Vector3(0.22, 0.34, 0.075)
    match ornament_id:
        "war_spikes", "thorn_wings", "forge_plates", "fallen_wings", "soul_wings":
            chest_contour.size = Vector3(0.26, 0.40, 0.09)
        "tidal_fins", "fin", "scale", "moon_wings":
            chest_contour.size = Vector3(0.18, 0.42, 0.075)
        "royal_wings", "heaven_wings", "solar_wings", "radiant", "aegis":
            chest_contour.size = Vector3(0.30, 0.36, 0.10)
        "chain", "sound", "time_rings", "dream_wings":
            chest_contour.size = Vector3(0.16, 0.30, 0.07)
    chest_contour.size.y *= stage_structure
    for chest_side in [-1.0, 1.0]:
        var pectoral_plate := _add_armor_piece(chest_contour, Vector3(chest_side * 0.22 * silhouette_width, 1.34, -0.425), Vector3(1.0, 1.0, 0.72), stage_trim_color if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"] else bright, stage_metallic, "chest")
        pectoral_plate.rotation.z = -chest_side * (0.12 if ornament_id in ["tidal_fins", "fin", "scale", "moon_wings"] else 0.06)
    if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"]:
        var sternum_ridge := BoxMesh.new()
        sternum_ridge.size = Vector3(0.075, 0.40 * stage_structure, 0.065)
        _add_armor_piece(sternum_ridge, Vector3(0.0, 1.28, -0.445), Vector3.ONE, stage_trim_color, stage_metallic, "chest")
    if stage_id in ["god_cloth", "god_armor"]:
        var chest_halo_mesh := TorusMesh.new()
        chest_halo_mesh.inner_radius = 0.20
        chest_halo_mesh.outer_radius = 0.235
        var chest_halo := _add_armor_piece(chest_halo_mesh, Vector3(0.0, 1.30, -0.43), Vector3(1.0, 1.0, 0.42), stage_trim_color, 1.0, "chest")
        chest_halo.rotation.x = deg_to_rad(90.0)
    if stage_id in ["god_cloth", "god_armor"]:
        var divine_collar := PrismMesh.new()
        divine_collar.size = Vector3(0.16, 0.34 * stage_structure, 0.18)
        for side in [-1.0, 1.0]:
            var collar_fin := _add_armor_piece(divine_collar, Vector3(side * 0.39, 1.62, 0.0), Vector3.ONE, stage_trim_color, stage_metallic, "chest")
            collar_fin.rotation.z = -side * 0.48
    if stage_id == "god_armor":
        var divine_core := TorusMesh.new()
        divine_core.inner_radius = 0.13
        divine_core.outer_radius = 0.18
        var core_ring := _add_armor_piece(divine_core, Vector3(0.0, 1.28, -0.49), Vector3.ONE, stage_trim_color, 1.0, "chest")
        core_ring.rotation.x = deg_to_rad(90.0)

    # Class-specific shoulder silhouette and forearm guards.
    var shoulder_mesh := SphereMesh.new()
    shoulder_mesh.radius = 0.28
    shoulder_mesh.height = 0.42
    var shoulder_scale: Vector3 = relic_visual_profile.get("shoulder_scale", visual_profile.get("shoulder_scale", Vector3.ONE))
    shoulder_scale = Vector3(shoulder_scale.x * silhouette_width * stage_structure, shoulder_scale.y * silhouette_height, shoulder_scale.z)
    _add_armor_piece(shoulder_mesh, Vector3(-0.48 * silhouette_width, 1.55, 0.0), shoulder_scale, bright, stage_metallic, "arms")
    _add_armor_piece(shoulder_mesh, Vector3(0.48 * silhouette_width, 1.55, 0.0), shoulder_scale, bright, stage_metallic, "arms")
    # Shoulder plates now use the class heraldry and armor tier, not one generic spike.
    var shoulder_plate_mesh := PrismMesh.new()
    var shoulder_plate_width := 0.34
    var shoulder_plate_height := 0.30
    match ornament_id:
        "war_spikes", "thorn_wings", "forge_plates":
            shoulder_plate_width = 0.26
            shoulder_plate_height = 0.48
        "tidal_fins", "fin", "scale":
            shoulder_plate_width = 0.20
            shoulder_plate_height = 0.42
        "royal_wings", "heaven_wings", "solar_wings", "radiant":
            shoulder_plate_width = 0.42
            shoulder_plate_height = 0.34
        "time_rings", "dream_wings", "sound", "aegis":
            shoulder_plate_width = 0.36
            shoulder_plate_height = 0.26
        "chain", "comet", "swift_wings", "feather":
            shoulder_plate_width = 0.30
            shoulder_plate_height = 0.24
    shoulder_plate_mesh.size = Vector3(shoulder_plate_width * stage_structure, shoulder_plate_height * silhouette_height, 0.18)
    for shoulder_side in [-1.0, 1.0]:
        var shoulder_plate := _add_armor_piece(shoulder_plate_mesh, Vector3(shoulder_side * 0.56 * silhouette_width, 1.64, -0.12), Vector3(1.0, 1.0, 0.9), stage_trim_color if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"] else bright, stage_metallic, "arms")
        shoulder_plate.rotation.z = -shoulder_side * (0.22 if ornament_id in ["war_spikes", "thorn_wings", "forge_plates", "tidal_fins", "fin"] else 0.08)
    var shoulder_spike := PrismMesh.new()
    shoulder_spike.size = Vector3(0.24, 0.42, 0.22)
    if ornament_id in ["time_rings", "sound", "aegis", "dream_wings"]:
        shoulder_spike.size = Vector3(0.12, 0.22, 0.12)
    elif ornament_id in ["war_spikes", "thorn_wings", "forge_plates"]:
        shoulder_spike.size = Vector3(0.20, 0.54, 0.18)
    elif ornament_id in ["tidal_fins", "fin", "scale"]:
        shoulder_spike.size = Vector3(0.12, 0.40, 0.10)
    var left_spike := _add_armor_piece(shoulder_spike, Vector3(-0.58, 1.76, 0.0), Vector3.ONE, accent, stage_metallic, "arms")
    left_spike.rotation.z = 0.48
    var right_spike := _add_armor_piece(shoulder_spike, Vector3(0.58, 1.76, 0.0), Vector3.ONE, accent, stage_metallic, "arms")
    right_spike.rotation.z = -0.48
    if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"]:
        var shoulder_ridge_mesh := BoxMesh.new()
        shoulder_ridge_mesh.size = Vector3(0.30 * stage_structure, 0.07, 0.20)
        for shoulder_side in [-1.0, 1.0]:
            var shoulder_ridge := _add_armor_piece(shoulder_ridge_mesh, Vector3(shoulder_side * 0.55, 1.52, -0.12), Vector3.ONE, stage_trim_color, stage_metallic, "arms")
            shoulder_ridge.rotation.z = -shoulder_side * 0.18
    var arm_mesh := CylinderMesh.new()
    arm_mesh.top_radius = 0.13
    arm_mesh.bottom_radius = 0.17
    arm_mesh.height = 0.48
    _add_armor_piece(arm_mesh, Vector3(-0.47, 0.98, 0.0), Vector3.ONE, dark, stage_metallic, "arms")
    _add_armor_piece(arm_mesh, Vector3(0.47, 0.98, 0.0), Vector3.ONE, dark, stage_metallic, "arms")
    var bracer_mesh := PrismMesh.new()
    bracer_mesh.size = Vector3(0.24, 0.40, 0.24)
    match ornament_id:
        "shield", "aegis", "war_spikes":
            bracer_mesh.size = Vector3(0.28, 0.42, 0.28)
        "chain", "sound", "time_rings":
            bracer_mesh.size = Vector3(0.20, 0.34, 0.20)
        "tidal_fins", "fin", "scale":
            bracer_mesh.size = Vector3(0.18, 0.42, 0.22)
    for bracer_side in [-1.0, 1.0]:
        var bracer := _add_armor_piece(bracer_mesh, Vector3(bracer_side * 0.48, 0.98, -0.14), Vector3.ONE, bright, stage_metallic, "arms")
        bracer.rotation.z = -bracer_side * 0.05
        var cuff_mesh := TorusMesh.new()
        cuff_mesh.inner_radius = 0.12
        cuff_mesh.outer_radius = 0.17 if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"] else 0.15
        var cuff := _add_armor_piece(cuff_mesh, Vector3(bracer_side * 0.48, 0.78, -0.02), Vector3(1.0, 0.82, 0.82), stage_trim_color, stage_metallic, "arms")
        cuff.rotation.x = deg_to_rad(90.0)

    # Starter relics and signature bracers get distinct readable silhouettes.
    var equipped_arms_id := str(RPGState.profile.get("equipment", {}).get("arms", ""))
    match equipped_arms_id:
        "dragon_shield":
            var shield_mesh := CylinderMesh.new()
            shield_mesh.top_radius = 0.29
            shield_mesh.bottom_radius = 0.29
            shield_mesh.height = 0.12
            var shield := _add_armor_piece(shield_mesh, Vector3(-0.68, 1.0, -0.19), Vector3.ONE, accent, 0.94, "arms")
            shield.rotation.x = PI * 0.5
            var shield_boss := SphereMesh.new()
            shield_boss.radius = 0.12
            shield_boss.height = 0.16
            _add_armor_piece(shield_boss, Vector3(-0.68, 1.0, -0.275), Vector3.ONE, bright, 0.98, "arms")
        "andromeda_chain":
            for chain_index in range(3):
                var chain_mesh := TorusMesh.new()
                chain_mesh.inner_radius = 0.12 + float(chain_index) * 0.025
                chain_mesh.outer_radius = chain_mesh.inner_radius + 0.035
                var chain := _add_armor_piece(chain_mesh, Vector3(0.58, 0.82 - float(chain_index) * 0.10, -0.22), Vector3.ONE, accent, 0.92, "arms")
                chain.rotation.x = deg_to_rad(70.0)
                chain.rotation.z = deg_to_rad(float(chain_index) * 24.0)
        "lyra_harp":
            var harp_frame := PrismMesh.new()
            harp_frame.size = Vector3(0.32, 0.58, 0.12)
            var harp := _add_armor_piece(harp_frame, Vector3(-0.66, 1.03, -0.18), Vector3.ONE, accent, 0.88, "arms")
            harp.rotation.z = -0.18
            for string_index in range(4):
                var string_mesh := CylinderMesh.new()
                string_mesh.top_radius = 0.008
                string_mesh.bottom_radius = 0.008
                string_mesh.height = 0.42
                var harp_string := _add_armor_piece(string_mesh, Vector3(-0.66 + float(string_index) * 0.065, 1.03, -0.26), Vector3.ONE, bright, 0.72, "arms")
                harp_string.rotation.z = PI * 0.5
        "phoenix_fist":
            var flame_glove := SphereMesh.new()
            flame_glove.radius = 0.19
            flame_glove.height = 0.28
            for side in [-1.0, 1.0]:
                var glove := _add_armor_piece(flame_glove, Vector3(side * 0.58, 0.72, -0.16), Vector3.ONE, accent, 0.68, "arms")
                var glove_material := glove.material_override as StandardMaterial3D
                glove_material.emission_enabled = true
                glove_material.emission = accent * 0.42
        "cygnus_claw":
            var ice_claw := PrismMesh.new()
            ice_claw.size = Vector3(0.10, 0.34, 0.12)
            for side in [-1.0, 1.0]:
                for claw_index in range(3):
                    var claw := _add_armor_piece(ice_claw, Vector3(side * 0.58 + float(claw_index - 1) * 0.10, 0.78, -0.28), Vector3.ONE, accent, 0.94, "arms")
                    claw.rotation.x = -0.35
        "sea_dragon_scale", "swallow_scale":
            var scale_mesh := SphereMesh.new()
            scale_mesh.radius = 0.17
            scale_mesh.height = 0.12
            for side in [-1.0, 1.0]:
                for scale_index in range(3):
                    _add_armor_piece(scale_mesh, Vector3(side * (0.48 + float(scale_index) * 0.08), 1.55 - float(scale_index) * 0.12, -0.18), Vector3(1.25, 0.72, 0.72), accent, 0.96, "arms")
        "tenmou_armor":
            var horn_mesh := PrismMesh.new()
            horn_mesh.size = Vector3(0.16, 0.48, 0.16)
            for side in [-1.0, 1.0]:
                var horn := _add_armor_piece(horn_mesh, Vector3(side * 0.55, 1.82, 0.0), Vector3.ONE, accent, 0.9, "head")
                horn.rotation.z = -side * 0.42

    # Waist guard, layered thigh/shin plates and knee caps.
    var belt_mesh := TorusMesh.new()
    belt_mesh.inner_radius = 0.29
    belt_mesh.outer_radius = 0.36
    _add_armor_piece(belt_mesh, Vector3(0.0, 0.72, 0.0), Vector3(1.0, 0.65, 1.0), accent, stage_metallic, "waist")
    var waist_plate := BoxMesh.new()
    waist_plate.size = Vector3(0.72 * silhouette_waist * stage_structure, 0.22, 0.16)
    _add_armor_piece(waist_plate, Vector3(0.0, 0.61, -0.28), Vector3.ONE, bright, stage_metallic, "waist")
    var skirt_plate := PrismMesh.new()
    skirt_plate.size = Vector3(0.28 * silhouette_waist * stage_structure, 0.42 * silhouette_height, 0.16)
    for skirt_side in [-1.0, 1.0]:
        for skirt_offset in [-1.0, 1.0]:
            var skirt_piece := _add_armor_piece(skirt_plate, Vector3(skirt_side * 0.22 * silhouette_waist, 0.48, skirt_offset * 0.16), Vector3(1.0, 1.0, 0.72), dark if skirt_offset > 0.0 else bright, stage_metallic, "waist")
            skirt_piece.rotation.z = -skirt_side * 0.12
            armor_skirt_nodes.append(skirt_piece)
            armor_skirt_base_angles.append(skirt_piece.rotation.z)
    # Tier-specific tassets and side guards give each armor family a different waist profile.
    var tasset_mesh := PrismMesh.new()
    tasset_mesh.size = Vector3(0.24, 0.38, 0.14)
    match stage_id:
        "silver":
            tasset_mesh.size = Vector3(0.22, 0.34, 0.13)
        "gold":
            tasset_mesh.size = Vector3(0.30, 0.44, 0.18)
        "sea_scale":
            tasset_mesh.size = Vector3(0.20, 0.48, 0.16)
        "surplice":
            tasset_mesh.size = Vector3(0.28, 0.46, 0.16)
        "god_cloth":
            tasset_mesh.size = Vector3(0.32, 0.52, 0.18)
        "god_armor":
            tasset_mesh.size = Vector3(0.36, 0.58, 0.20)
    if ornament_id in ["tidal_fins", "fin", "scale"]:
        tasset_mesh.size.x *= 0.78
        tasset_mesh.size.y *= 1.18
    elif ornament_id in ["royal_wings", "heaven_wings", "solar_wings", "radiant"]:
        tasset_mesh.size.x *= 1.18
    elif ornament_id in ["war_spikes", "thorn_wings", "forge_plates"]:
        tasset_mesh.size.z *= 1.22
    for tasset_side in [-1.0, 1.0]:
        var side_tasset := _add_armor_piece(tasset_mesh, Vector3(tasset_side * 0.38 * silhouette_waist, 0.49, -0.18), Vector3.ONE, stage_trim_color if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"] else bright, stage_metallic, "waist")
        side_tasset.rotation.z = -tasset_side * 0.18
    if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"]:
        var waist_side_mesh := BoxMesh.new()
        waist_side_mesh.size = Vector3(0.12, 0.34 * stage_structure, 0.18)
        for waist_side in [-1.0, 1.0]:
            var waist_guard := _add_armor_piece(waist_side_mesh, Vector3(waist_side * 0.43 * silhouette_waist, 0.61, 0.0), Vector3.ONE, dark, stage_metallic, "waist")
            waist_guard.rotation.z = -waist_side * 0.12
    var thigh_mesh := PrismMesh.new()
    thigh_mesh.size = Vector3(0.25 * silhouette_waist, 0.30 * silhouette_height, 0.17)
    var shin_mesh := BoxMesh.new()
    shin_mesh.size = Vector3(0.24 * stage_structure, 0.48 * silhouette_height, 0.18)
    for leg_side in [-1.0, 1.0]:
        var thigh_plate := _add_armor_piece(thigh_mesh, Vector3(leg_side * 0.22, 0.54, -0.17), Vector3.ONE, dark, stage_metallic, "legs")
        thigh_plate.rotation.z = -leg_side * 0.08
        _add_armor_piece(shin_mesh, Vector3(leg_side * 0.22, 0.34, -0.22), Vector3.ONE, bright, stage_metallic, "legs")
    # Tiered greave ridges and class-shaped knee guards reinforce the leg silhouette.
    if stage_id in ["gold", "sea_scale", "surplice", "god_cloth", "god_armor"]:
        var greave_ridge := BoxMesh.new()
        greave_ridge.size = Vector3(0.055, 0.34 * stage_structure, 0.045)
        for ridge_side in [-1.0, 1.0]:
            _add_armor_piece(greave_ridge, Vector3(ridge_side * 0.22, 0.34, -0.322), Vector3.ONE, stage_trim_color, stage_metallic, "legs")
    var knee_mesh := SphereMesh.new()
    knee_mesh.radius = 0.15
    knee_mesh.height = 0.12
    for leg_side in [-1.0, 1.0]:
        _add_armor_piece(knee_mesh, Vector3(leg_side * 0.22, 0.57, -0.27), Vector3(1.0, 0.7, 0.65), accent, stage_metallic, "legs")
    var ankle_mesh := TorusMesh.new()
    ankle_mesh.inner_radius = 0.105
    ankle_mesh.outer_radius = 0.145
    for leg_side in [-1.0, 1.0]:
        var ankle_guard := _add_armor_piece(ankle_mesh, Vector3(leg_side * 0.22, 0.105, 0.0), Vector3(1.0, 0.72, 1.0), stage_trim_color, stage_metallic, "legs")
        ankle_guard.rotation.x = deg_to_rad(90.0)

    # Every class receives its own heraldic crest and chest sigil.
    var crest_mesh: Mesh
    var crest_scale := Vector3.ONE
    var crest_id := str(relic_visual_profile.get("crest", visual_profile.get("crest", "star")))
    match crest_id:
        "horn", "spear", "trident", "ice", "flame", "anvil", "bolt", "scythe", "thorn", "wave", "fin", "harvest":
            var crest_prism := PrismMesh.new()
            crest_prism.size = Vector3(0.20, 0.42, 0.16)
            if crest_id in ["bolt", "scythe", "thorn"]:
                crest_prism.size = Vector3(0.16, 0.50, 0.13)
            elif crest_id in ["wave", "fin", "harvest"]:
                crest_prism.size = Vector3(0.26, 0.30, 0.12)
            crest_mesh = crest_prism
        "halo", "crescent", "clock", "dream", "aegis", "rune", "rose", "lyre":
            var crest_ring := TorusMesh.new()
            crest_ring.inner_radius = 0.09
            crest_ring.outer_radius = 0.15
            if crest_id in ["crescent", "aegis"]:
                crest_ring.inner_radius = 0.075
                crest_ring.outer_radius = 0.18
            crest_mesh = crest_ring
        "sun", "crown", "wing":
            var crest_crown := PrismMesh.new()
            crest_crown.size = Vector3(0.34, 0.30, 0.12)
            crest_mesh = crest_crown
        _:
            var crest_cone := CylinderMesh.new()
            crest_cone.bottom_radius = 0.13
            crest_cone.top_radius = 0.015
            crest_cone.height = 0.34
            crest_mesh = crest_cone
    if crest_id in ["sun", "crown", "wing"]:
        crest_scale = Vector3(1.0, 0.92, 0.82)
    var crest := _add_armor_piece(crest_mesh, Vector3(0.0, 2.12, -0.02), crest_scale, accent, stage_metallic, "head")
    if crest_id in ["horn", "spear", "trident", "ice", "flame", "anvil", "bolt", "scythe", "thorn", "wave", "fin", "harvest"]:
        crest.rotation.x = -0.18
    elif crest_id == "crescent":
        crest.rotation.z = PI * 0.5
    var helmet_cap := SphereMesh.new()
    helmet_cap.radius = 0.245
    helmet_cap.height = 0.20
    _add_armor_piece(helmet_cap, Vector3(0.0, 2.075, 0.015), Vector3(1.0, 0.62, 0.88), bright, stage_metallic, "head")
    var helmet_brow := BoxMesh.new()
    helmet_brow.size = Vector3(0.54 * silhouette_width, 0.11, 0.12)
    _add_armor_piece(helmet_brow, Vector3(0.0, 2.02, -0.225), Vector3.ONE, stage_trim_color, stage_metallic, "head")
    var helmet_guard := PrismMesh.new()
    helmet_guard.size = Vector3(0.16, 0.34 * silhouette_height, 0.20)
    for helmet_side in [-1.0, 1.0]:
        var helmet_guard_piece := _add_armor_piece(helmet_guard, Vector3(helmet_side * 0.24 * silhouette_width, 1.84, -0.04), Vector3.ONE, bright, stage_metallic, "head")
        helmet_guard_piece.rotation.z = -helmet_side * 0.12
    var helmet_temple := BoxMesh.new()
    helmet_temple.size = Vector3(0.10, 0.24, 0.18)
    for temple_side in [-1.0, 1.0]:
        var temple_plate := _add_armor_piece(helmet_temple, Vector3(temple_side * 0.205, 1.91, -0.12), Vector3.ONE, dark, stage_metallic, "head")
        temple_plate.rotation.z = temple_side * 0.16
    var emblem_mesh := SphereMesh.new()
    emblem_mesh.radius = 0.11
    emblem_mesh.height = 0.18
    _add_armor_piece(emblem_mesh, Vector3(0.0, 1.30, -0.445), Vector3(1.0, 1.0, 0.42), accent, 0.96, "chest")

    # Faceted cosmos gems and engraved trim make armor tiers visually distinct.
    var chest_gem_mesh := PrismMesh.new()
    chest_gem_mesh.size = Vector3(0.17, 0.22, 0.075)
    var chest_gem := _add_armor_piece(chest_gem_mesh, Vector3(0.0, 1.31, -0.505), Vector3.ONE, stage_trim_color.lightened(0.18), 0.98, "chest")
    chest_gem.rotation.z = PI
    armor_gem_nodes.append(chest_gem)
    var belt_gem_mesh := PrismMesh.new()
    belt_gem_mesh.size = Vector3(0.13, 0.16, 0.06)
    var belt_gem := _add_armor_piece(belt_gem_mesh, Vector3(0.0, 0.72, -0.39), Vector3.ONE, accent.lightened(0.2), 0.96, "waist")
    armor_gem_nodes.append(belt_gem)
    var chest_trim_mesh := BoxMesh.new()
    chest_trim_mesh.size = Vector3(0.055, 0.38, 0.035)
    var left_trim := _add_armor_piece(chest_trim_mesh, Vector3(-0.29, 1.29, -0.432), Vector3.ONE, stage_trim_color, stage_metallic, "chest")
    left_trim.rotation.z = -0.12
    var right_trim := _add_armor_piece(chest_trim_mesh, Vector3(0.29, 1.29, -0.432), Vector3.ONE, stage_trim_color, stage_metallic, "chest")
    right_trim.rotation.z = 0.12
    var shin_gem_mesh := SphereMesh.new()
    shin_gem_mesh.radius = 0.055
    shin_gem_mesh.height = 0.11
    for side in [-1.0, 1.0]:
        var shin_gem := _add_armor_piece(shin_gem_mesh, Vector3(side * 0.22, 0.36, -0.325), Vector3.ONE, accent, 0.94, "legs")
        armor_gem_nodes.append(shin_gem)

    # Back ornaments are built as low-poly feather/fin plates, scaled per class.
    var wing_span := float(relic_visual_profile.get("wing_span", visual_profile.get("wing_span", 0.0)))
    if wing_span > 0.0:
        var feather_mesh := PrismMesh.new()
        var feather_width := 0.16
        var feather_height := 0.72
        if ornament_id in ["tidal_fins", "fin", "rune_wings", "moon_wings"]:
            feather_width = 0.12
            feather_height = 0.82
        elif ornament_id in ["leaf_wings", "petal_wings", "royal_wings", "heaven_wings", "solar_wings"]:
            feather_width = 0.22
            feather_height = 0.68
        elif ornament_id in ["fallen_wings", "soul_wings", "thorn_wings", "war_spikes", "storm_wings", "flame_wings"]:
            feather_width = 0.14
            feather_height = 0.88
        feather_mesh.size = Vector3(feather_width, feather_height, 0.10)
        for side in [-1.0, 1.0]:
            for feather_index in range(4):
                var spread := float(feather_index) * (0.15 if ornament_id in ["tidal_fins", "fin"] else 0.18)
                var feather_scale := Vector3(1.0, wing_span * (1.0 - float(feather_index) * 0.12), 1.0)
                var feather_position := Vector3(side * (0.42 + spread), 1.70 - float(feather_index) * 0.07, 0.25 + float(feather_index) * 0.05)
                var feather := _add_armor_piece(feather_mesh, feather_position, feather_scale, bright if feather_index == 0 else accent, stage_metallic, "chest")
                feather.rotation.z = -side * (0.34 + float(feather_index) * 0.17)
                feather.rotation.x = -0.22
                armor_wing_nodes.append(feather)
                armor_wing_base_angles.append(feather.rotation.z)
    if ornament_id in ["war_spikes", "thorn_wings", "forge_plates"]:
        var side_plate_mesh := PrismMesh.new()
        side_plate_mesh.size = Vector3(0.20, 0.48, 0.16)
        for side in [-1.0, 1.0]:
            var side_plate := _add_armor_piece(side_plate_mesh, Vector3(side * 0.68, 1.42, -0.02), Vector3(1.0, 1.0, 0.9), accent, stage_metallic, "arms")
            side_plate.rotation.z = -side * 0.52

    # Signature ornaments that are not wings receive their own readable geometry.
    match ornament_id:
        "comet":
            var comet_tail_mesh := PrismMesh.new()
            comet_tail_mesh.size = Vector3(0.12, 0.42, 0.10)
            for comet_index in range(3):
                var comet_tail := _add_armor_piece(comet_tail_mesh, Vector3(float(comet_index - 1) * 0.14, 1.56 - float(comet_index) * 0.12, 0.34), Vector3(1.0, 1.0 - float(comet_index) * 0.12, 1.0), accent if comet_index == 0 else stage_trim_color, stage_metallic, "chest")
                comet_tail.rotation.z = -0.32 + float(comet_index) * 0.32
        "shield":
            var class_shield_mesh := CylinderMesh.new()
            class_shield_mesh.top_radius = 0.22
            class_shield_mesh.bottom_radius = 0.22
            class_shield_mesh.height = 0.09
            var class_shield := _add_armor_piece(class_shield_mesh, Vector3(-0.66, 1.02, -0.22), Vector3.ONE, accent, 0.96, "arms")
            class_shield.rotation.x = PI * 0.5
            var class_shield_boss_mesh := SphereMesh.new()
            class_shield_boss_mesh.radius = 0.085
            class_shield_boss_mesh.height = 0.12
            _add_armor_piece(class_shield_boss_mesh, Vector3(-0.66, 1.02, -0.285), Vector3.ONE, stage_trim_color, 0.98, "arms")
        "chain":
            var signature_chain_mesh := TorusMesh.new()
            signature_chain_mesh.inner_radius = 0.105
            signature_chain_mesh.outer_radius = 0.145
            for chain_link_index in range(3):
                var signature_link := _add_armor_piece(signature_chain_mesh, Vector3(0.57, 1.08 - float(chain_link_index) * 0.16, -0.20), Vector3(1.0, 1.0, 0.72), accent, 0.94, "arms")
                signature_link.rotation.x = deg_to_rad(72.0)
                signature_link.rotation.z = deg_to_rad(float(chain_link_index) * 28.0)
        "scale":
            var signature_scale_mesh := SphereMesh.new()
            signature_scale_mesh.radius = 0.14
            signature_scale_mesh.height = 0.10
            for scale_side in [-1.0, 1.0]:
                for scale_layer in range(3):
                    var signature_scale := _add_armor_piece(signature_scale_mesh, Vector3(scale_side * (0.32 + float(scale_layer) * 0.10), 1.48 - float(scale_layer) * 0.12, -0.23), Vector3(1.25, 0.82, 0.72), accent if scale_layer == 0 else bright, stage_metallic, "chest")
                    signature_scale.rotation.z = -scale_side * 0.18
        "sound":
            var sound_ring_mesh := TorusMesh.new()
            sound_ring_mesh.inner_radius = 0.12
            sound_ring_mesh.outer_radius = 0.16
            for sound_ring_index in range(3):
                var sound_ring := _add_armor_piece(sound_ring_mesh, Vector3(0.0, 1.48 + float(sound_ring_index) * 0.16, 0.34 + float(sound_ring_index) * 0.025), Vector3(1.0 + float(sound_ring_index) * 0.18, 0.72 + float(sound_ring_index) * 0.12, 0.72), accent, 0.92, "chest")
                sound_ring.rotation.x = deg_to_rad(72.0)
        "fin":
            var signature_fin_mesh := PrismMesh.new()
            signature_fin_mesh.size = Vector3(0.16, 0.52, 0.12)
            for fin_side in [-1.0, 1.0]:
                var signature_fin := _add_armor_piece(signature_fin_mesh, Vector3(fin_side * 0.58, 1.56, 0.08), Vector3(1.0, 0.9, 0.85), accent, stage_metallic, "arms")
                signature_fin.rotation.z = -fin_side * 0.62
    if ornament_id in ["time_rings", "aegis", "radiant", "solar_wings", "storm_wings", "heaven_wings", "tidal_fins", "rune_wings", "soul_wings", "moon_wings", "dream_wings", "royal_wings", "leaf_wings", "flame_wings", "fallen_wings", "swift_wings", "petal_wings", "thorn_wings", "chain", "sound"]:
        var aura_ring := TorusMesh.new()
        aura_ring.inner_radius = 0.68
        aura_ring.outer_radius = 0.73
        var aura := _add_armor_piece(aura_ring, Vector3(0.0, 1.55, 0.34), Vector3.ONE, accent, 0.92)
        armor_aura_node = aura
        aura.rotation.x = deg_to_rad(72.0)
    if stage_id in ["god_cloth", "god_armor"] or bool(stage_state.get("awakened", false)):
        var awakening_ring_mesh := TorusMesh.new()
        awakening_ring_mesh.inner_radius = 0.76 if stage_id != "god_armor" else 0.88
        awakening_ring_mesh.outer_radius = awakening_ring_mesh.inner_radius + 0.045
        var awakening_ring := _add_armor_piece(awakening_ring_mesh, Vector3(0.0, 1.68, 0.30), Vector3.ONE, stage_trim_color, 1.0)
        awakening_ring.rotation.x = deg_to_rad(72.0)
        var ring_material := awakening_ring.material_override as StandardMaterial3D
        ring_material.emission_enabled = true
        ring_material.emission = stage_trim_color * (0.18 if bool(stage_state.get("awakened", false)) else 0.10)
    if stage_glow > 0.0:
        var glow_mesh := SphereMesh.new()
        glow_mesh.radius = 0.13
        glow_mesh.height = 0.26
        var glow_piece := _add_armor_piece(glow_mesh, Vector3(0.0, 1.31, -0.50), Vector3.ONE, accent, 0.55)
        var glow_material := glow_piece.material_override as StandardMaterial3D
        glow_material.emission_enabled = true
        glow_material.emission = accent * stage_glow
        glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    _build_armor_wear_cracks()


func _load_authored_character_model(class_id: String) -> void:
    if is_instance_valid(authored_character_model):
        authored_character_model.queue_free()
        authored_character_model = null
    authored_animation_player = null
    authored_animation_state = ""
    var model_path := "res://assets/characters/%s/model/character.glb" % class_id
    if not ResourceLoader.exists(model_path):
        return
    var packed := load(model_path) as PackedScene
    if packed == null:
        push_warning("Profession model could not be loaded; keeping procedural fallback: " + model_path)
        return
    var instance := packed.instantiate()
    if instance == null:
        push_warning("Profession model could not be instantiated; keeping procedural fallback: " + model_path)
        return
    authored_character_model = instance
    authored_character_model.name = "AuthoredProfessionModel"
    authored_animation_player = _find_animation_player(authored_character_model)
    authored_animation_state = ""
    authored_character_model.position = Vector3.ZERO
    authored_character_model.scale = Vector3.ONE
    visual_root.add_child(authored_character_model)
    # Keep gameplay feedback nodes and modular armor; hide only the base mannequin meshes.
    for child in visual_root.get_children():
        if child is MeshInstance3D and child not in [combat_feedback_node, guard_shield_node, mount_indicator]:
            child.visible = false

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root as AnimationPlayer
    for child in root.get_children():
        var found := _find_animation_player(child)
        if is_instance_valid(found):
            return found
    return null

func _play_authored_animation(animation_name: String, blend_time: float = 0.12) -> void:
    if not is_instance_valid(authored_animation_player):
        return
    if not authored_animation_player.has_animation(animation_name):
        return
    if authored_animation_state == animation_name and authored_animation_player.is_playing():
        return
    authored_animation_state = animation_name
    authored_animation_player.play(animation_name, blend_time)

func _play_authored_action_animation(animation_name: String, blend_time: float = 0.06) -> void:
    if not is_instance_valid(authored_animation_player):
        return
    if not authored_animation_player.has_animation(animation_name):
        return
    var clip := authored_animation_player.get_animation(animation_name)
    authored_action_animation_timer = clampf(clip.length, 0.2, 1.0)
    authored_animation_state = ""
    authored_animation_player.play(animation_name, blend_time)

func _load_authored_armor_model() -> void:
    if is_instance_valid(authored_armor_model):
        authored_armor_model.queue_free()
        authored_armor_model = null
    if is_instance_valid(armor_root):
        armor_root.visible = true
    var relic: Dictionary = EquipmentDatabase.get_equipped_relic()
    var equipment_id := str(relic.get("id", ""))
    if equipment_id.is_empty():
        return
    var model_path := "res://assets/armors/%s/model/armor.glb" % equipment_id
    if not ResourceLoader.exists(model_path):
        return
    var packed := load(model_path) as PackedScene
    if packed == null:
        push_warning("Armor model could not be loaded; keeping modular armor fallback: " + model_path)
        return
    var instance := packed.instantiate()
    if instance == null:
        push_warning("Armor model could not be instantiated; keeping modular armor fallback: " + model_path)
        return
    authored_armor_model = instance
    authored_armor_model.name = "AuthoredArmorModel"
    authored_armor_model.position = Vector3.ZERO
    authored_armor_model.scale = Vector3.ONE
    visual_root.add_child(authored_armor_model)
    if is_instance_valid(armor_root):
        armor_root.visible = false

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
    if training_down_timer > 0.0:
        training_down_timer = maxf(0.0, training_down_timer - delta)
        velocity = Vector3.ZERO
        move_and_slide()
        if training_down_timer <= 0.0:
            global_position = Vector3(0, 0.2, 7)
            game.call("show_notice", "角色已恢复，继续战斗！")
        return
    visual_flash_timer = maxf(0.0, visual_flash_timer - delta)
    if is_instance_valid(body_mat):
        var flash_strength := clampf(visual_flash_timer / 0.16, 0.0, 1.0)
        body_mat.albedo_color = armor_base_color.lerp(visual_flash_color, flash_strength)
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
    var on_floor_after_move := is_on_floor()
    if not authored_was_on_floor and on_floor_after_move:
        _play_authored_action_animation("land", 0.05)
    authored_was_on_floor = on_floor_after_move
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
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var combo_profile: Dictionary = SkillAnimationCatalog.get_basic_combo_profile(class_id, basic_combo_step)
    if combo_profile.is_empty():
        combo_profile = {"motion": "strike", "startup": 0.1, "active": 0.18, "recovery": 0.24, "total_duration": 0.52, "combo_cancel_at": 0.23, "pose_scale": 1.08, "rotation_degrees": 0.0}
    _play_skill_pose(combo_profile)
    var authored_combo_clip := "%s_basic_attack_%d" % [class_id, basic_combo_step]
    if is_instance_valid(authored_animation_player) and authored_animation_player.has_animation(authored_combo_clip):
        _play_authored_action_animation(authored_combo_clip, 0.045)
    else:
        var profile_clip := str(combo_profile.get("authored_clip", ""))
        if is_instance_valid(authored_animation_player) and authored_animation_player.has_animation(profile_clip):
            _play_authored_action_animation(profile_clip, 0.045)
        else:
            _play_authored_action_animation("basic_attack_%d" % basic_combo_step, 0.045)
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
    var attack_color: Color = skill_data.get("color", Color(1.0, 0.82, 0.35))
    _flash(attack_color)
    _play_combat_feedback(attack_color.lightened(0.12), 0.30 if basic_combo_step < 3 else 0.52)
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
    _play_authored_action_animation("skill_cast", 0.06)
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
    _play_attack_pose(0.7, "dash")
    _play_authored_action_animation("dodge", 0.035)
    _play_combat_feedback(Color(0.28, 0.88, 1.0) if not heavenly_wings else Color(0.72, 0.94, 1.0), 0.42)
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
        combat_pose_motion = "hit"
        combat_pose_duration = 0.26
        combat_pose_timer = combat_pose_duration
        combat_pose_strength = 0.9
        _play_authored_action_animation("hit_heavy" if amount >= 25.0 else "hit_light", 0.04)
        _play_combat_feedback(Color(1.0, 0.18, 0.12), 0.28)
        if bool(SettingsManager.get_value("controls", "vibration", true)):
            Input.vibrate_handheld(45, 0.35)
    elif absorbed_damage > 0.0:
        _flash(Color(0.35, 0.8, 1.0))
    if health <= 0.0:
        health = max_health
        training_down_timer = 0.9
        velocity = Vector3.ZERO
        _play_authored_action_animation("defeat", 0.06)
        game.call("show_notice", "角色倒地，正在恢复……")
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
    if not is_instance_valid(body_mat):
        return
    visual_flash_color = color
    visual_flash_timer = 0.16
    body_mat.albedo_color = color

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
    _play_authored_action_animation("block", 0.05)
    combat_pose_motion = "guard"
    combat_pose_duration = 0.42
    combat_pose_timer = combat_pose_duration
    combat_pose_strength = 1.0
    guard_shield_duration = 0.48
    guard_shield_timer = guard_shield_duration
    if is_instance_valid(guard_shield_node):
        guard_shield_node.visible = true
    _play_combat_feedback(Color(1.0, 0.72, 0.24), 0.48)
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
    _play_attack_pose(1.42, "heavy")
    _play_authored_action_animation("skill_cast", 0.05)
    _play_combat_feedback(Color(1.0, 0.82, 0.3), 0.68)
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
    var ability_profile: Dictionary = SkillSystem.get_ability_effect_profile(ability)
    var animation_profile: Dictionary = SkillAnimationCatalog.get_profile(class_id, ability)
    var visual_profile: Dictionary = SkillVisualCatalog.get_profile(class_id, ability)
    var class_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var visual_color: Color = visual_profile.get("color", class_data.get("color", Color(0.3, 0.72, 1.0)))
    _play_skill_pose(animation_profile)
    _play_authored_action_animation("skill_cast", 0.06)
    var feedback_duration := clampf(float(animation_profile.get("startup", 0.2)) + float(animation_profile.get("active", 0.2)) * 0.55, 0.32, 0.9)
    _play_combat_feedback(visual_color, feedback_duration)
    CombatSessionManager.record_skill_cast()
    ability_cooldowns[ability_id] = float(ability.get("cooldown", 6))
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
    var projectile_action := str(ability_profile.get("action", "")) in ["projectile", "homing_projectile"]
    _flash(visual_color)
    if not SkillSystem.is_support_ability(ability) and not projectile_action:
        game.call("damage_nearby_combat", damage, reach, cone, float(class_data.get("knockback", 3.5)) * 1.15 + float(aerial_profile.get("knockback_bonus", 0.0)), float(class_data.get("launch", 1.0)) + float(aerial_profile.get("launch_bonus", 0.0)), float(class_data.get("stagger", 0.5)))
    game.call("apply_ability_effect", class_id, ability, reach)
    var vfx_anchor := str(animation_profile.get("vfx_anchor", "upper_body"))
    var effect_position := global_position + (-global_transform.basis.z * 2.5) + Vector3.UP
    if vfx_anchor == "ground":
        effect_position = global_position + Vector3.UP * 0.12
    elif vfx_anchor == "target" and is_instance_valid(locked_target):
        effect_position = locked_target.global_position + Vector3.UP
    elif vfx_anchor == "upper_body":
        effect_position = global_position + Vector3.UP * 1.15 + (-global_transform.basis.z * 1.4)
    var impact_scale := clampf(float(visual_profile.get("impact_scale", 1.0)), 0.5, 1.5)
    game.call("spawn_effect", effect_position, visual_color, clampf(2.2 * impact_scale, 1.2, 3.3), str(visual_profile.get("shape", "star")), float(visual_profile.get("glow", 0.4)))
    game.call("show_notice", str(ability.get("name", "职业技能")) + "！")
    _register_custom_combo_input(ability_id)
    return true
