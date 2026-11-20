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
var core_node: MeshInstance3D
var halo_node: MeshInstance3D
var summon_material: StandardMaterial3D
var summon_light: OmniLight3D
var outer_halo_node: MeshInstance3D

func _ready() -> void:
    add_to_group("skill_summons")
    core_node = MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    sphere.height = 0.68
    core_node.mesh = sphere
    summon_material = StandardMaterial3D.new()
    summon_material.albedo_color = summon_color
    summon_material.emission_enabled = true
    summon_material.emission = summon_color * 0.75
    summon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    core_node.material_override = summon_material
    add_child(core_node)

    halo_node = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.42
    ring.outer_radius = 0.48
    halo_node.mesh = ring
    halo_node.rotation_degrees.x = 90.0
    halo_node.material_override = summon_material
    add_child(halo_node)

    outer_halo_node = MeshInstance3D.new()
    var outer_ring := TorusMesh.new()
    outer_ring.inner_radius = 0.62
    outer_ring.outer_radius = 0.66
    outer_halo_node.mesh = outer_ring
    outer_halo_node.rotation_degrees = Vector3(32.0, 0.0, 18.0)
    outer_halo_node.material_override = summon_material
    add_child(outer_halo_node)

    summon_light = OmniLight3D.new()
    summon_light.light_color = summon_color
    summon_light.light_energy = 0.7
    summon_light.omni_range = 3.5
    add_child(summon_light)

func _physics_process(delta: float) -> void:
    age += delta
    attack_timer = maxf(0.0, attack_timer - delta)
    follow_angle += delta * 1.8
    _animate_summon(delta)
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

func _animate_summon(delta: float) -> void:
    var pulse := 1.0 + sin(age * 7.0) * 0.12
    if is_instance_valid(core_node):
        core_node.scale = Vector3.ONE * pulse
    if is_instance_valid(halo_node):
        halo_node.rotate_y(delta * 1.8)
        halo_node.rotate_z(delta * 0.9)
    if is_instance_valid(outer_halo_node):
        outer_halo_node.rotate_y(-delta * 1.1)
        outer_halo_node.rotate_x(delta * 0.45)
    if is_instance_valid(summon_material):
        var energy := 0.58 + (sin(age * 5.0) + 1.0) * 0.22
        summon_material.emission = summon_color * energy
        summon_material.emission_energy_multiplier = 1.0 + energy
    if is_instance_valid(summon_light):
        summon_light.light_energy = 0.4 + (sin(age * 5.0) + 1.0) * 0.4

func _find_target() -> Node3D:
    var best: Node3D
    var best_distance := 18.0
    var enemy_list: Array = game.get("enemies")
    for candidate in enemy_list:
        if not is_instance_valid(candidate):
            continue
        var candidate_node := candidate as Node3D
        if candidate_node == null or float(candidate_node.get("health")) <= 0.0:
            continue
        var distance := global_position.distance_to(candidate_node.global_position)
        if distance < best_distance:
            best_distance = distance
            best = candidate_node
    return best
