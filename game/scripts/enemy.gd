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
var telegraph_mesh: MeshInstance3D
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
        var boss_ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = radius * 0.92
        ring_mesh.outer_radius = radius * 1.06
        boss_ring.mesh = ring_mesh
        boss_ring.position.y = 0.10
        var ring_material := StandardMaterial3D.new()
        ring_material.albedo_color = _base_color
        ring_material.emission_enabled = true
        ring_material.emission = _base_color * 0.65
        ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        boss_ring.material_override = ring_material
        add_child(boss_ring)
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
    var telegraph_material := StandardMaterial3D.new()
    telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    telegraph_material.albedo_color = Color(1.0, 0.18, 0.12, 0.72)
    telegraph_material.emission_enabled = true
    telegraph_material.emission = Color(1.0, 0.06, 0.02)
    telegraph_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    telegraph_mesh.material_override = telegraph_material
    telegraph_mesh.visible = false
    add_child(telegraph_mesh)

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
	if bool(profile.get("winged", false)):
		var wing := PrismMesh.new()
		wing.size = Vector3(radius * 0.72, height * 0.48, radius * 0.18)
		for side in [-1.0, 1.0]:
			var wing_node := _add_enemy_visual(wing, Vector3(side * radius * 0.88, height * 0.76, radius * 0.24), Vector3(1.0, 1.0, 0.62), accent, metallic)
			wing_node.rotation.z = -side * 0.42
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
            knockback_velocity = push.normalized() * (3.5 if is_boss else 7.0) * get_divine_mark_knockback_multiplier()
    # Damage alone must not cancel a boss's clearly telegraphed attack or recovery.
    if not is_boss or (state != BrainState.WINDUP and state != BrainState.RECOVERY):
        state = BrainState.STAGGER
        state_timer = 0.12 if is_boss else 0.3
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
