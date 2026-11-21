extends Node3D
## Reusable authored look-dev scene for signature Saint Seiya combat VFX.
@export_enum("meteor_fist", "comet_burst", "rising_dragon") var effect_style := "meteor_fist"
@export var auto_play := true
var elapsed := 0.0
var rotating: Array[Node3D] = []

func _ready() -> void:
    _build_effect()

func _process(delta: float) -> void:
    elapsed += delta
    for node in rotating:
        if is_instance_valid(node):
            node.rotate_z(delta * 0.8)
            node.rotate_y(delta * 0.35)

func _build_effect() -> void:
    var gold := Color(1.0, 0.58, 0.16)
    var blue := Color(0.22, 0.58, 1.0)
    var white := Color(0.82, 0.92, 1.0)
    var red := Color(1.0, 0.16, 0.12)
    match effect_style:
        "meteor_fist":
            _add_ring(blue, 0.58, 0.035, Vector3(0.0, 0.0, -0.8))
            _add_ring(white, 0.92, 0.018, Vector3(0.0, 0.0, -1.1))
            _add_particle_burst(blue, 64, 7.0, 0.9)
            _add_meteor_cluster(blue, gold, 9)
        "comet_burst":
            _add_ring(gold, 0.9, 0.06, Vector3(0.0, 0.0, -1.0))
            _add_ring(white, 1.25, 0.025, Vector3(0.0, 0.0, -1.2))
            _add_particle_burst(gold, 96, 10.0, 0.72)
            _add_meteor_cluster(white, red, 15)
        "rising_dragon":
            _add_dragon_coils(blue, gold)
            _add_particle_burst(blue, 72, 6.0, 1.1)
            _add_ring(gold, 0.72, 0.035, Vector3(0.0, 0.0, -0.6))

func _glow_material(color: Color, energy: float = 2.8) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    material.metallic = 0.25
    material.roughness = 0.22
    return material

func _add_ring(color: Color, radius: float, thickness: float, position: Vector3) -> void:
    var ring := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = maxf(0.01, radius - thickness)
    mesh.outer_radius = radius + thickness
    mesh.rings = 48
    mesh.ring_segments = 12
    ring.mesh = mesh
    ring.position = position
    ring.material_override = _glow_material(color)
    add_child(ring)
    rotating.append(ring)

func _add_particle_burst(color: Color, amount: int, speed: float, lifetime_value: float) -> void:
    var particles := GPUParticles3D.new()
    particles.amount = amount
    particles.lifetime = lifetime_value
    particles.one_shot = false
    particles.emitting = true
    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius = 0.18
    process.direction = Vector3(0.0, 0.0, -1.0)
    process.spread = 32.0
    process.initial_velocity_min = speed * 0.35
    process.initial_velocity_max = speed
    process.gravity = Vector3(0.0, 0.0, 0.0)
    process.scale_min = 0.035
    process.scale_max = 0.11
    process.color = color
    particles.process_material = process
    var dot := SphereMesh.new()
    dot.radius = 0.045
    dot.height = 0.09
    particles.draw_pass_1 = dot
    particles.material_override = _glow_material(color, 3.6)
    add_child(particles)

func _add_meteor_cluster(primary: Color, secondary: Color, count: int) -> void:
    for index in range(count):
        var meteor := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.07 + float(index % 3) * 0.018
        sphere.height = sphere.radius * 2.0
        meteor.mesh = sphere
        var angle := TAU * float(index) / float(count)
        meteor.position = Vector3(cos(angle) * 0.38, sin(angle) * 0.38, -0.7 - float(index % 4) * 0.16)
        meteor.material_override = _glow_material(primary if index % 2 == 0 else secondary, 3.4)
        add_child(meteor)
        rotating.append(meteor)

func _add_dragon_coils(primary: Color, secondary: Color) -> void:
    for index in range(5):
        var coil := MeshInstance3D.new()
        var torus := TorusMesh.new()
        torus.inner_radius = 0.025
        torus.outer_radius = 0.38 + float(index) * 0.09
        torus.rings = 40
        torus.ring_segments = 10
        coil.mesh = torus
        coil.position = Vector3(0.0, -0.45 + float(index) * 0.28, -0.55 - float(index) * 0.12)
        coil.rotation = Vector3(deg_to_rad(68.0), 0.0, deg_to_rad(float(index) * 26.0))
        coil.material_override = _glow_material(primary if index % 2 == 0 else secondary, 3.0)
        add_child(coil)
        rotating.append(coil)
