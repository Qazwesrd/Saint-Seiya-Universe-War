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

func _ready() -> void:
    var visual := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.12
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.24)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.emission_enabled = true
    material.emission = field_color * 0.35
    visual.material_override = material
    visual.position.y = 0.08
    add_child(visual)
    add_to_group("skill_fields")

func _physics_process(delta: float) -> void:
    elapsed += delta
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

func _apply_to_enemy(enemy: Node3D, is_trap: bool) -> void:
    if enemy.has_method("take_damage"):
        enemy.call("take_damage", damage * (1.5 if is_trap else 1.0))
    if status != "" and enemy.has_method("apply_status_effect"):
        enemy.call("apply_status_effect", status, status_duration * (1.25 if is_trap else 1.0), status_power)
    if is_trap and game.has_method("spawn_effect"):
        game.call("spawn_effect", global_position + Vector3.UP * 0.5, field_color, radius * 0.55)
