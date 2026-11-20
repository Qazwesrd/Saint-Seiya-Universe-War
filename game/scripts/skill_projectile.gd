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

func _ready() -> void:
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
    add_child(orb)
    add_to_group("skill_projectiles")

func _physics_process(delta: float) -> void:
    age += delta
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

func _hit_target(hit_target: Node3D) -> void:
    if hit_target.has_method("take_damage"):
        hit_target.call("take_damage", damage)
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
