extends CharacterBody3D
const CombatTargeting = preload("res://scripts/combat_targeting.gd")
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
var body_mat: StandardMaterial3D
var is_mounted := false
var mount_indicator: MeshInstance3D
var temporary_damage_bonus := 0.0
var temporary_damage_reduction := 0.0
var temporary_buff_timer := 0.0
var ability_cooldowns: Dictionary = {}
var custom_combo_index := 0
var custom_combo_timer := 0.0
var custom_combo_auto_running := false
func _ready() -> void:
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
    add_child(mount_indicator)
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

func set_auto_move_target(target: Vector3) -> void:
    auto_move_target = target
    auto_moving = true

func cancel_auto_move() -> void:
    auto_moving = false
func _physics_process(delta: float) -> void:
    pivot.global_position = global_position + Vector3(0, 1.5, 0)
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
    var speed := base_speed * (2.2 if dodge_time > 0.0 else (1.45 if is_mounted else 1.0))
    knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 24.0 * delta)
    velocity.x = direction.x * speed + knockback_velocity.x
    velocity.z = direction.z * speed + knockback_velocity.z
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
    if attack_cd > 0.0:
        return
    if basic_combo_reset <= 0.0:
        basic_combo_step = 0
    basic_combo_step = (basic_combo_step % 3) + 1
    basic_combo_reset = 0.95
    attack_cd = 0.28 if basic_combo_step < 3 else 0.52
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var skill_data: Dictionary = SkillSystem.get_class_skill(class_id)
    var attack_stat := float(RPGState.get_combat_stats().get("attack", 14.0))
    var multipliers := [0.85, 1.0, 1.45]
    var passive_multiplier := SkillSystem.get_skill_damage_multiplier(class_id)
    var damages := (8.0 + attack_stat * float(multipliers[basic_combo_step - 1])) * passive_multiplier * (1.0 + temporary_damage_bonus)
    var push_forces := [1.8, 2.8, float(skill_data.get("knockback", 3.5)) * 1.7]
    var lift_forces := [0.0, 0.0, float(skill_data.get("launch", 1.2)) * 1.5]
    var basic_names: Array = skill_data.get("basic_attacks", ["第一段", "第二段", "第三段"])
    _flash(skill_data.get("color", Color(1.0, 0.82, 0.35)))
    game.call("damage_nearby_combat", damages, 2.8 if basic_combo_step < 3 else 3.2, 125.0, push_forces[basic_combo_step - 1], lift_forces[basic_combo_step - 1], 0.18 if basic_combo_step < 3 else float(skill_data.get("stagger", 0.55)) * 0.6)
    game.call("show_notice", str(basic_names[basic_combo_step - 1]) + "！")
    _register_custom_combo_input("basic_attack_%d" % basic_combo_step)
func skill() -> void:
    if skill_cd > 0.0 or cosmos < 18.0:
        game.call("show_notice", "小宇宙不足或技能冷却中")
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var skill_data: Dictionary = SkillSystem.get_class_skill(class_id)
    cosmos -= float(skill_data.get("cost", 18))
    CombatSessionManager.record_skill_cast()
    skill_cd = float(skill_data.get("cooldown", 3.0))
    combo_window = 1.6
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var skill_level := SkillSystem.get_skill_level(class_id)
    var damage_multiplier := float(skill_data.get("damage", 1.5)) * (1.0 + float(skill_level - 1) * 0.08) * SkillSystem.get_skill_damage_multiplier(class_id) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))) * (1.0 + temporary_damage_bonus)
    var skill_color: Color = skill_data.get("color", Color(0.18, 0.72, 1.0))
    _flash(skill_color)
    game.call("damage_nearby_combat", 18.0 + attack_power * damage_multiplier, float(skill_data.get("range", 7.0)), float(skill_data.get("cone", 150.0)), float(skill_data.get("knockback", 3.5)), float(skill_data.get("launch", 1.2)), float(skill_data.get("stagger", 0.55)))
    game.call("apply_class_skill_effect", class_id, float(skill_data.get("range", 7.0)))
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
    CombatSessionManager.record_skill_cast(true)
    combo_window = 0.0
    skill_cd = maxf(skill_cd, 1.0)
    var skill_level := SkillSystem.get_skill_level(class_id)
    var damage := float(RPGState.get_combat_stats().get("attack", 14.0)) * float(skill_data.get("combo_damage", 2.5)) * (1.0 + float(skill_level - 1) * 0.1) * (1.0 + temporary_damage_bonus)
    var skill_color: Color = skill_data.get("color", Color(0.2, 0.7, 1.0))
    _flash(Color(1.0, 0.9, 0.55))
    game.call("damage_nearby_combat", damage, float(skill_data.get("combo_range", 8.5)), 180.0, float(skill_data.get("combo_knockback", 9.0)), float(skill_data.get("combo_launch", 3.8)), float(skill_data.get("stagger", 0.85)) * 1.2)
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 3.5) + Vector3.UP, skill_color, 4.0)
    game.call("show_notice", str(skill_data.get("combo", "职业连招")) + "！")
func cosmos_burst() -> void:
    if burst_cd > 0.0 or cosmos < 35.0:
        game.call("show_notice", "小宇宙能量不足或正在冷却")
        return
    cosmos -= 35.0
    burst_cd = 8.0
    _flash(Color(1.0, 0.4, 0.12))
    var skill_data: Dictionary = SkillSystem.get_class_skill(str(RPGState.profile.get("class_id", "pegasus")))
    game.call("damage_nearby_combat", 24.0 + float(RPGState.get_combat_stats().get("attack", 14.0)) * 2.0, float(skill_data.get("burst_range", 5.0)), 360.0, float(skill_data.get("burst_knockback", 12.0)), float(skill_data.get("burst_launch", 4.5)), float(skill_data.get("stagger", 1.0)))
    game.call("spawn_effect", global_position + Vector3.UP, Color(1.0, 0.42, 0.12), 4.0)
    game.call("show_notice", str(skill_data.get("burst_name", "小宇宙爆发")) + "！")
func dodge() -> void:
    if dodge_time > 0.0: return
    dodge_time = 0.32
    invulnerable = 0.4
    var direction := pivot.global_transform.basis.x * move_input.x + (-pivot.global_transform.basis.z) * -move_input.y
    direction.y = 0
    if direction.length() < 0.1: direction = -global_transform.basis.z
    velocity = direction.normalized() * 15.0
    game.call("show_notice", "闪避！短暂无敌")
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

func receive_damage(amount: float) -> void:
    if invulnerable > 0.0: return
    var defense: float = float(RPGState.get_combat_stats().get("defense", 0.0))
    var passive_reduction := SkillSystem.get_damage_reduction(str(RPGState.profile.get("class_id", "pegasus")))
    var final_damage := maxf(1.0, (amount - defense * 0.25) * (1.0 - passive_reduction) * (1.0 - clampf(temporary_damage_reduction, 0.0, 0.65)))
    health = maxf(0.0, health - final_damage)
    CombatSessionManager.record_damage_taken(final_damage)
    ArmorSystem.damage_random_part(1)
    _flash(Color(1.0, 0.12, 0.12))
    if health <= 0.0:
        health = max_health
        global_position = Vector3(0, 0.2, 7)
        game.call("show_notice", "角色倒地，已在训练场复位")
func apply_temporary_buff(damage_bonus: float, damage_reduction: float, duration: float) -> void:
    temporary_damage_bonus = maxf(temporary_damage_bonus, damage_bonus)
    temporary_damage_reduction = maxf(temporary_damage_reduction, damage_reduction)
    temporary_buff_timer = maxf(temporary_buff_timer, duration)

func _flash(color: Color) -> void:
    body_mat.albedo_color = color
    get_tree().create_timer(0.16).timeout.connect(func():
        if is_instance_valid(body_mat):
            body_mat.albedo_color = Color(0.18, 0.52, 0.95)
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
    var steps: Array = preset.get("steps", [])
    for i in range(1, steps.size()):
        await get_tree().create_timer(0.32).timeout
        var action_id := str(steps[i])
        if action_id.begins_with("basic_attack_"):
            attack()
        elif action_id == "dodge":
            dodge()
        elif action_id == "guard":
            guard()
        else:
            cast_ability(action_id)
    custom_combo_auto_running = false
    _execute_custom_combo_finisher(preset)
    custom_combo_index = 0
    custom_combo_timer = 0.0

func _execute_custom_combo_finisher(preset: Dictionary) -> void:
    var steps: Array = preset.get("steps", [])
    if steps.is_empty():
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var class_data := SkillSystem.get_class_skill(class_id)
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var skill_level := SkillSystem.get_skill_level(class_id)
    var damage := attack_power * (1.1 + float(steps.size()) * 0.42) * (1.0 + float(skill_level - 1) * 0.05)
    var reach := float(class_data.get("combo_range", 8.5))
    var color: Color = class_data.get("color", Color(0.35, 0.75, 1.0))
    CombatSessionManager.record_skill_cast(true)
    _flash(Color(1.0, 0.88, 0.42))
    game.call("damage_nearby_combat", damage, reach, 180.0, float(class_data.get("combo_knockback", 7.0)), float(class_data.get("combo_launch", 2.8)), float(class_data.get("stagger", 0.7)))
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 3.0) + Vector3.UP, color, 3.2)
    game.call("show_notice", str(preset.get("name", "自定义连招")) + " · 连携终结！")

func cast_skill_slot(slot_index: int) -> void:
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var slots := SkillSystem.get_equipped_abilities(class_id)
    if slot_index < 0 or slot_index >= slots.size():
        return
    var ability_id := str(slots[slot_index])
    if ability_id == "":
        game.call("show_notice", "技能栏第 %d 格尚未装备技能" % (slot_index + 1))
        return
    cast_ability(ability_id)
func cast_ability(ability_id: String) -> void:
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var ability := SkillSystem.get_ability_data(class_id, ability_id)
    if ability.is_empty() or not SkillSystem.is_ability_learned(class_id, ability_id):
        game.call("show_notice", "技能尚未学习")
        return
    var remaining := float(ability_cooldowns.get(ability_id, 0.0))
    if remaining > 0.0:
        game.call("show_notice", "技能冷却中：%.1f 秒" % remaining)
        return
    var cost := float(ability.get("cost", 12))
    if cosmos < cost:
        game.call("show_notice", "小宇宙不足，需要 %.0f 点" % cost)
        return
    cosmos -= cost
    CombatSessionManager.record_skill_cast()
    ability_cooldowns[ability_id] = float(ability.get("cooldown", 6))
    var class_data := SkillSystem.get_class_skill(class_id)
    var ability_type := str(ability.get("type", "攻击"))
    var attack_power := float(RPGState.get_combat_stats().get("attack", 14.0))
    var level_scale := 1.0 + float(SkillSystem.get_skill_level(class_id) - 1) * 0.06
    var type_scale := 1.25 if ("奥义" in ability_type or "终结" in ability_type) else (0.72 if ("防御" in ability_type or "治疗" in ability_type or "守护" in ability_type) else 1.0)
    var damage := (10.0 + attack_power * float(class_data.get("damage", 1.5)) * type_scale * level_scale) * (1.0 + float(RPGState.get_cosmos_profile().get("skill_power_multiplier", 0.0))) * (1.0 + temporary_damage_bonus)
    var reach := float(class_data.get("range", 7.0))
    if "远程" in ability_type or "次元" in ability_type or "音波" in ability_type:
        reach += 2.0
    var cone := 360.0 if ("范围" in str(ability.get("role", "")) or "领域" in ability_type or "震地" in ability_type) else float(class_data.get("cone", 145.0))
    _flash(class_data.get("color", Color(0.25, 0.72, 1.0)))
    if not ("防御" in ability_type or "护盾" in ability_type or "治疗" in ability_type or "恢复" in ability_type or "复苏" in ability_type or "回能" in ability_type or "资源" in ability_type or "增益" in ability_type or "守护" in ability_type or "格挡" in ability_type or "霸体" in ability_type or "净化" in ability_type or "闪避" in ability_type):
        game.call("damage_nearby_combat", damage, reach, cone, float(class_data.get("knockback", 3.5)) * 1.15, float(class_data.get("launch", 1.0)), float(class_data.get("stagger", 0.5)))
    game.call("apply_ability_effect", class_id, ability, reach)
    game.call("spawn_effect", global_position + (-global_transform.basis.z * 2.5) + Vector3.UP, class_data.get("color", Color(0.25, 0.72, 1.0)), 2.2)
    game.call("show_notice", str(ability.get("name", "职业技能")) + "！")
    _register_custom_combo_input(ability_id)
