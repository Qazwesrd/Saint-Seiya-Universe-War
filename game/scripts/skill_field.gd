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
var triggered := false
var field_color := Color(0.35, 0.75, 1.0)
var field_shape := "ring"
var primary_visual: MeshInstance3D
var secondary_visual: MeshInstance3D
var primary_material: StandardMaterial3D

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
    var secondary_material := StandardMaterial3D.new()
    secondary_material.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.48)
    secondary_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    secondary_material.emission_enabled = true
    secondary_material.emission = field_color * 0.72
    secondary_visual.material_override = secondary_material
    secondary_visual.position.y = 0.11
    add_child(secondary_visual)

func _physics_process(delta: float) -> void:
    elapsed += delta
    _animate_field()
    tick_timer = maxf(0.0, tick_timer - delta)
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
    if hits > 0 and game.has_method("show_notice"):
        game.call("show_notice", "领域持续命中 %d 名敌人" % hits)

func _animate_field() -> void:
    var life_ratio := clampf(1.0 - elapsed / maxf(0.01, lifetime), 0.0, 1.0)
    var pulse := 1.0 + sin(elapsed * 5.5) * 0.035
    if is_instance_valid(primary_visual):
        primary_visual.scale = Vector3.ONE * pulse
    if is_instance_valid(secondary_visual):
        secondary_visual.rotation.y += 0.025
        secondary_visual.scale = Vector3.ONE * (0.94 + sin(elapsed * 3.8) * 0.1)
    if is_instance_valid(primary_material):
        primary_material.albedo_color.a = 0.08 + life_ratio * 0.2

func _apply_to_enemy(enemy: Node3D, is_trap: bool) -> void:
    if enemy.has_method("take_damage"):
        enemy.call("take_damage", damage * (1.5 if is_trap else 1.0))
    if status != "" and enemy.has_method("apply_status_effect"):
        enemy.call("apply_status_effect", status, status_duration * (1.25 if is_trap else 1.0), status_power)
    if is_trap and game.has_method("spawn_effect"):
        game.call("spawn_effect", global_position + Vector3.UP * 0.5, field_color, radius * 0.55)
