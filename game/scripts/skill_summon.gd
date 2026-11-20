extends Node3D

var game: Node3D
var owner_player: Node3D
var summon_damage := 12.0
var life_time := 9.0
var summon_color := Color(0.35, 0.8, 1.0)
var age := 0.0
var attack_timer := 0.35
var follow_angle := 0.0
var target: Node3D

func _ready() -> void:
    add_to_group("skill_summons")
    var orb := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    sphere.height = 0.68
    orb.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = summon_color
    material.emission_enabled = true
    material.emission = summon_color * 0.75
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    orb.material_override = material
    add_child(orb)
    var halo := MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.42
    ring.outer_radius = 0.48
    halo.mesh = ring
    halo.rotation_degrees.x = 90.0
    halo.material_override = material
    add_child(halo)

func _physics_process(delta: float) -> void:
    age += delta
    attack_timer = maxf(0.0, attack_timer - delta)
    follow_angle += delta * 1.8
    if age >= life_time or not is_instance_valid(owner_player) or not is_instance_valid(game):
        queue_free()
        return
    if not is_instance_valid(target) or float(target.get("health")) <= 0.0:
        target = _find_target()
    if is_instance_valid(target):
        var offset := target.global_position + Vector3.UP * 1.0 - global_position
        if offset.length() > 1.8:
            global_position += offset.normalized() * minf(7.0 * delta, offset.length() - 1.8)
        elif attack_timer <= 0.0:
            if target.has_method("take_damage"):
                target.call("take_damage", summon_damage)
            if game.has_method("spawn_effect"):
                game.call("spawn_effect", target.global_position + Vector3.UP, summon_color, 0.75)
            attack_timer = 1.15
    else:
        var orbit_offset := Vector3(cos(follow_angle) * 1.35, 1.8 + sin(follow_angle * 1.4) * 0.25, sin(follow_angle) * 1.35)
        var desired := owner_player.global_position + orbit_offset
        global_position = global_position.lerp(desired, minf(1.0, delta * 5.0))

func _find_target() -> Node3D:
    var best: Node3D
    var best_distance := 18.0
    var enemy_list: Array = game.get("enemies")
    for candidate in enemy_list:
        if not is_instance_valid(candidate) or not candidate is Node3D:
            continue
        if float(candidate.get("health")) <= 0.0:
            continue
        var distance := global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            best = candidate
    return best
