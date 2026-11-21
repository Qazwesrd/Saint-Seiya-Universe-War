extends Node3D

var game: Node3D
var owner_player: Node3D
var radius := 3.8
var lifetime := 5.0
var tick_interval := 0.8
var damage := 8.0
var status := "slow"
var status_duration := 1.4
var status_power := 0.22
var mode := "field"
var elapsed := 0.0
var tick_timer := 0.0
var impact_pulse_timer := 0.0
var triggered := false
var field_color := Color(0.35, 0.75, 1.0)
var field_shape := "ring"
var primary_visual: MeshInstance3D
var secondary_visual: MeshInstance3D
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var field_light: OmniLight3D
var outer_visual: MeshInstance3D

func _ready() -> void:
    add_to_group("skill_fields")
    primary_visual = MeshInstance3D.new()
    if field_shape in ["ring", "halo", "pulse", "wave", "crescent", "time"]:
        var ring := TorusMesh.new()
        ring.inner_radius = maxf(0.1, radius - 0.16)
        ring.outer_radius = radius
        primary_visual.mesh = ring
        primary_visual.rotation.x = deg_to_rad(90.0)
    else:
        var mesh := CylinderMesh.new()
        mesh.top_radius = radius
        mesh.bottom_radius = radius
        mesh.height = 0.12
        primary_visual.mesh = mesh
    primary_material = StandardMaterial3D.new()
    primary_material.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.24)
    primary_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    primary_material.emission_enabled = true
    primary_material.emission = field_color * 0.48
    primary_visual.material_override = primary_material
    primary_visual.position.y = 0.08
    add_child(primary_visual)

    secondary_visual = MeshInstance3D.new()
    var secondary_ring := TorusMesh.new()
    secondary_ring.inner_radius = radius * 0.68
    secondary_ring.outer_radius = radius * 0.72
    secondary_visual.mesh = secondary_ring
    secondary_visual.rotation.x = deg_to_rad(90.0)
    secondary_material = StandardMaterial3D.new()
    secondary_material.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.48)
    secondary_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    secondary_material.emission_enabled = true
    secondary_material.emission = field_color * 0.72
    secondary_visual.material_override = secondary_material
    secondary_visual.position.y = 0.11
    add_child(secondary_visual)

    outer_visual = MeshInstance3D.new()
    var outer_ring := TorusMesh.new()
    outer_ring.inner_radius = radius * 1.12
    outer_ring.outer_radius = radius * 1.15
    outer_visual.mesh = outer_ring
    outer_visual.rotation.x = deg_to_rad(90.0)
    outer_visual.position.y = 0.07
    var outer_material := StandardMaterial3D.new()
    outer_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    outer_material.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.2)
    outer_material.emission_enabled = true
    outer_material.emission = field_color * 0.9
    outer_visual.material_override = outer_material
    add_child(outer_visual)

    field_light = OmniLight3D.new()
    field_light.light_color = field_color
    field_light.light_energy = 0.55
    field_light.omni_range = minf(radius * 2.0, 9.0)
    field_light.position.y = 0.65
    add_child(field_light)

func _physics_process(delta: float) -> void:
    elapsed += delta
    _animate_field(delta)
    tick_timer = maxf(0.0, tick_timer - delta)
    impact_pulse_timer = maxf(0.0, impact_pulse_timer - delta)
    if elapsed >= lifetime or not is_instance_valid(owner_player) or not is_instance_valid(game):
        queue_free()
        return
    if mode == "trap":
        if triggered:
            return
        for enemy in game.get("enemies"):
            if not is_instance_valid(enemy) or float(enemy.get("health")) <= 0.0:
                continue
            if enemy.global_position.distance_to(global_position) <= radius:
                _apply_to_enemy(enemy, true)
                triggered = true
                queue_free()
                return
        return
    if tick_timer > 0.0:
        return
    var hits := 0
    for enemy in game.get("enemies"):
        if not is_instance_valid(enemy) or float(enemy.get("health")) <= 0.0:
            continue
        if enemy.global_position.distance_to(global_position) > radius:
            continue
        _apply_to_enemy(enemy, false)
        hits += 1
    tick_timer = tick_interval
    if hits > 0:
        impact_pulse_timer = 0.34
        if game.has_method("show_notice"):
            game.call("show_notice", "领域持续命中 %d 名敌人" % hits)

func _animate_field(delta: float) -> void:
    var life_ratio := clampf(1.0 - elapsed / maxf(0.01, lifetime), 0.0, 1.0)
    var pulse := 1.0 + sin(elapsed * 5.5) * 0.045
    var secondary_pulse := 0.94 + sin(elapsed * 3.8) * 0.1
    var impact_ratio := clampf(impact_pulse_timer / 0.34, 0.0, 1.0)
    if is_instance_valid(primary_visual):
        primary_visual.scale = Vector3.ONE * pulse * (1.0 + impact_ratio * 0.12)
    if is_instance_valid(secondary_visual):
        secondary_visual.rotation.y += delta * 0.8
        secondary_visual.scale = Vector3.ONE * (secondary_pulse + impact_ratio * 0.16)
    if is_instance_valid(outer_visual):
        outer_visual.rotation.y -= delta * 0.42
        outer_visual.scale = Vector3.ONE * (1.0 + sin(elapsed * 2.6) * 0.035)
    if is_instance_valid(primary_material):
        primary_material.albedo_color.a = 0.06 + life_ratio * 0.22
        primary_material.emission_energy_multiplier = 0.65 + (sin(elapsed * 4.8) + 1.0) * 0.35
    if is_instance_valid(secondary_material):
        secondary_material.albedo_color.a = 0.18 + life_ratio * 0.3
        secondary_material.emission_energy_multiplier = 0.8 + (sin(elapsed * 5.7 + 1.0) + 1.0) * 0.35
    if is_instance_valid(field_light):
        field_light.light_energy = life_ratio * (0.35 + (sin(elapsed * 4.0) + 1.0) * 0.28 + impact_ratio * 0.85)

func _apply_to_enemy(enemy: Node3D, is_trap: bool) -> void:
    if enemy.has_method("take_damage"):
        enemy.call("take_damage", damage * (1.5 if is_trap else 1.0), owner_player.global_position if is_instance_valid(owner_player) else global_position)
    if status != "" and enemy.has_method("apply_status_effect"):
        enemy.call("apply_status_effect", status, status_duration * (1.25 if is_trap else 1.0), status_power)
    if is_trap and game.has_method("spawn_effect"):
        game.call("spawn_effect", global_position + Vector3.UP * 0.5, field_color, radius * 0.55)
