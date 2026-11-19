extends CharacterBody3D
var game: Variant
var is_boss := false
var health := 65.0
var max_health := 65.0
var speed := 2.5
var attack_timer := 0.0
func _ready() -> void:
    add_to_group("enemies")
    if is_boss:
        health = 260.0
        max_health = 260.0
        speed = 1.8
    var radius := 0.55 if not is_boss else 0.9
    var height := 1.9 if not is_boss else 3.0
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = radius
    shape.height = height
    col.shape = shape
    col.position.y = height * 0.5
    add_child(col)
    var model := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = radius
    capsule.height = height
    model.mesh = capsule
    model.position.y = height * 0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.72, 0.16, 0.22) if not is_boss else Color(0.36, 0.08, 0.55)
    mat.metallic = 0.4
    mat.roughness = 0.3
    mat.emission_enabled = true
    mat.emission = Color(0.16, 0.015, 0.04) if not is_boss else Color(0.12, 0.015, 0.25)
    model.material_override = mat
    add_child(model)
func _physics_process(delta: float) -> void:
    var target: Node3D = game.get("player")
    if not is_instance_valid(target): return
    attack_timer = maxf(0.0, attack_timer - delta)
    var offset: Vector3 = target.global_position - global_position
    var distance := offset.length()
    if distance > (2.0 if not is_boss else 2.8):
        var dir := offset.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 5.0 * delta)
        if attack_timer <= 0.0:
            attack_timer = 1.6 if not is_boss else 2.2
            target.call("receive_damage", 7.0 if not is_boss else 16.0)
    velocity.y -= 22.0 * delta
    move_and_slide()
    if distance > 0.1: rotation.y = atan2(-offset.x, -offset.z)
func take_damage(amount: float) -> void:
    health = maxf(0.0, health - amount)
    if is_boss: game.call("show_notice", "Boss 生命：" + str(roundi(health)) + "/" + str(roundi(max_health)))
    if health <= 0.0:
        game.call("on_enemy_defeated", self)
        queue_free()
