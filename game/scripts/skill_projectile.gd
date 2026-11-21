extends Node3D

var game: Node3D
var owner_player: Node3D
var target: Node3D
var speed := 12.0
var damage := 18.0
var lifetime := 4.0
var turn_rate := 5.0
var homing_enabled := true
var projectile_color := Color(0.45, 0.8, 1.0)
var projectile_shape := "star"
var impact_scale := 1.0
var status := "slow"
var status_duration := 1.2
var status_power := 0.12
var age := 0.0
var visual_root: Node3D
var halo_node: MeshInstance3D
var halo_material: StandardMaterial3D
var orbit_nodes: Array[MeshInstance3D] = []
var trail_nodes: Array[MeshInstance3D] = []
var trail_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
    add_to_group("skill_projectiles")
    visual_root = Node3D.new()
    add_child(visual_root)
    var orb := MeshInstance3D.new()
    match projectile_shape:
        "shard", "bolt":
            var shard := PrismMesh.new()
            shard.size = Vector3(0.22, 0.48, 0.18) if projectile_shape == "shard" else Vector3(0.12, 0.58, 0.12)
            orb.mesh = shard
        "ring", "halo", "pulse", "wave", "crescent":
            var ring := TorusMesh.new()
            ring.inner_radius = 0.13
            ring.outer_radius = 0.24
            orb.mesh = ring
        _:
            var sphere := SphereMesh.new()
            sphere.radius = 0.22
            sphere.height = 0.44
            orb.mesh = sphere
    orb.scale = Vector3.ONE * clampf(impact_scale, 0.5, 1.5)
    var material := StandardMaterial3D.new()
    material.albedo_color = projectile_color
    material.emission_enabled = true
    material.emission = projectile_color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    orb.material_override = material
    visual_root.add_child(orb)

    halo_node = MeshInstance3D.new()
    var halo_mesh := TorusMesh.new()
    halo_mesh.inner_radius = 0.28
    halo_mesh.outer_radius = 0.34
    halo_node.mesh = halo_mesh
    halo_node.rotation_degrees.x = 90.0
    halo_node.scale = Vector3.ONE * clampf(impact_scale, 0.65, 1.35)
    halo_material = StandardMaterial3D.new()
    halo_material.albedo_color = Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.72)
    halo_material.emission_enabled = true
    halo_material.emission = projectile_color * 0.85
    halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    halo_node.material_override = halo_material
    visual_root.add_child(halo_node)

    for orbit_index in range(2):
        var mote := MeshInstance3D.new()
        var mote_mesh := SphereMesh.new()
        mote_mesh.radius = 0.055
        mote_mesh.height = 0.11
        mote.mesh = mote_mesh
        mote.material_override = material
        orbit_nodes.append(mote)
        visual_root.add_child(mote)

    # Three lightweight afterimages give fast projectiles a readable direction cue.
    for trail_index in range(3):
        var trail := MeshInstance3D.new()
        var trail_mesh := SphereMesh.new()
        trail_mesh.radius = 0.13 - float(trail_index) * 0.022
        trail_mesh.height = trail_mesh.radius * 2.0
        trail.mesh = trail_mesh
        var trail_material := StandardMaterial3D.new()
        trail_material.albedo_color = Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.34 - float(trail_index) * 0.08)
        trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        trail_material.emission_enabled = true
        trail_material.emission = projectile_color * 0.45
        trail.material_override = trail_material
        trail.position.z = 0.24 + float(trail_index) * 0.2
        trail_nodes.append(trail)
        trail_materials.append(trail_material)
        visual_root.add_child(trail)

func _physics_process(delta: float) -> void:
    age += delta
    _animate_projectile(delta)
    if age >= lifetime or not is_instance_valid(owner_player) or not is_instance_valid(game):
        queue_free()
        return
    if not homing_enabled:
        var direction := -global_transform.basis.z.normalized()
        global_position += direction * speed * delta
        for candidate in game.get("enemies"):
            if not is_instance_valid(candidate) or float(candidate.get("health")) <= 0.0:
                continue
            if global_position.distance_to(candidate.global_position + Vector3.UP * 0.8) <= 0.72:
                _hit_target(candidate)
                return
        return
    if not is_instance_valid(target) or float(target.get("health")) <= 0.0:
        target = _find_target()
    if not is_instance_valid(target):
        global_position += -owner_player.global_transform.basis.z * speed * delta
        return
    var offset := target.global_position + Vector3.UP * 0.8 - global_position
    if offset.length() <= 0.65:
        _hit_target(target)
        return
    var direction := offset.normalized()
    var current := (-global_transform.basis.z).normalized()
    var steering := current.lerp(direction, minf(1.0, turn_rate * delta)).normalized()
    look_at(global_position + steering, Vector3.UP)
    global_position += steering * speed * delta

func _animate_projectile(delta: float) -> void:
    if not is_instance_valid(visual_root):
        return
    var pulse := 1.0 + sin(age * 13.0) * 0.09
    visual_root.scale = Vector3.ONE * pulse
    visual_root.rotate_y(delta * 4.2)
    if is_instance_valid(halo_node):
        halo_node.rotate_z(delta * 5.5)
        halo_node.scale = Vector3.ONE * (1.0 + sin(age * 9.0) * 0.12)
    for index in range(orbit_nodes.size()):
        var angle := age * (5.0 if index == 0 else -4.0) + float(index) * PI
        orbit_nodes[index].position = Vector3(cos(angle) * 0.38, sin(angle * 1.3) * 0.12, sin(angle) * 0.38)
    for index in range(trail_nodes.size()):
        var trail := trail_nodes[index]
        if not is_instance_valid(trail):
            continue
        var fade := 1.0 - float(index) * 0.22
        var shimmer := 0.82 + sin(age * 16.0 - float(index) * 0.8) * 0.12
        trail.scale = Vector3.ONE * shimmer * fade
        trail.position.z = 0.24 + float(index) * 0.2 + sin(age * 8.0 - float(index)) * 0.025
        if index < trail_materials.size() and is_instance_valid(trail_materials[index]):
            trail_materials[index].albedo_color.a = (0.34 - float(index) * 0.08) * (0.85 + sin(age * 12.0 - float(index)) * 0.15)

func _hit_target(hit_target: Node3D) -> void:
    if hit_target.has_method("take_damage"):
        hit_target.call("take_damage", damage, owner_player.global_position if is_instance_valid(owner_player) else global_position)
    if status != "" and hit_target.has_method("apply_status_effect"):
        hit_target.call("apply_status_effect", status, status_duration, status_power)
    if game.has_method("spawn_effect"):
        game.call("spawn_effect", hit_target.global_position + Vector3.UP, projectile_color, impact_scale)
    queue_free()

func _find_target() -> Node3D:
    var best: Node3D
    var best_distance := 22.0
    for candidate in game.get("enemies"):
        if not is_instance_valid(candidate) or float(candidate.get("health")) <= 0.0:
            continue
        var distance := global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best = candidate
            best_distance = distance
    return best
