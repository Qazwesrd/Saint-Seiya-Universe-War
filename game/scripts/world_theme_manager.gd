extends Node3D

var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var floor_material: StandardMaterial3D
var ring_root: Node3D
var decor_root: Node3D
var active_theme_id := ""

const THEMES := {
    "galaxy_wars": {"background": Color(0.025, 0.045, 0.12), "ambient": Color(0.28, 0.36, 0.62), "sun": Color(0.72, 0.82, 1.0), "floor": Color(0.055, 0.075, 0.14), "ring": Color(0.12, 0.42, 0.95), "fog": Color(0.06, 0.10, 0.24), "height": 3.2, "metallic": 0.42},
    "sanctuary_twelve_houses": {"background": Color(0.16, 0.12, 0.12), "ambient": Color(0.72, 0.58, 0.42), "sun": Color(1.0, 0.82, 0.58), "floor": Color(0.30, 0.27, 0.24), "ring": Color(0.95, 0.66, 0.22), "fog": Color(0.22, 0.16, 0.12), "height": 5.2, "metallic": 0.24},
    "asgard": {"background": Color(0.10, 0.22, 0.34), "ambient": Color(0.48, 0.70, 0.88), "sun": Color(0.72, 0.88, 1.0), "floor": Color(0.12, 0.23, 0.32), "ring": Color(0.38, 0.78, 1.0), "fog": Color(0.18, 0.36, 0.50), "height": 4.8, "metallic": 0.58},
    "poseidon": {"background": Color(0.015, 0.10, 0.20), "ambient": Color(0.12, 0.42, 0.68), "sun": Color(0.28, 0.78, 1.0), "floor": Color(0.025, 0.13, 0.23), "ring": Color(0.12, 0.78, 0.96), "fog": Color(0.02, 0.20, 0.34), "height": 5.8, "metallic": 0.72},
    "hades": {"background": Color(0.055, 0.015, 0.09), "ambient": Color(0.30, 0.12, 0.42), "sun": Color(0.62, 0.30, 0.72), "floor": Color(0.075, 0.035, 0.10), "ring": Color(0.68, 0.18, 0.78), "fog": Color(0.14, 0.035, 0.18), "height": 6.2, "metallic": 0.64},
    "heaven": {"background": Color(0.34, 0.46, 0.66), "ambient": Color(0.86, 0.80, 0.66), "sun": Color(1.0, 0.91, 0.68), "floor": Color(0.48, 0.47, 0.43), "ring": Color(1.0, 0.82, 0.36), "fog": Color(0.54, 0.62, 0.76), "height": 7.0, "metallic": 0.86},
    "original_final": {"background": Color(0.012, 0.008, 0.045), "ambient": Color(0.30, 0.20, 0.55), "sun": Color(0.64, 0.48, 1.0), "floor": Color(0.025, 0.018, 0.075), "ring": Color(0.72, 0.30, 1.0), "fog": Color(0.055, 0.025, 0.12), "height": 6.8, "metallic": 0.78}
}

func apply_theme(chapter_id: String) -> bool:
    if not THEMES.has(chapter_id):
        chapter_id = "galaxy_wars"
    if active_theme_id == chapter_id:
        return true
    active_theme_id = chapter_id
    var theme: Dictionary = THEMES[chapter_id]
    if is_instance_valid(world_environment) and is_instance_valid(world_environment.environment):
        var environment := world_environment.environment
        environment.background_mode = Environment.BG_COLOR
        environment.background_color = theme["background"]
        environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        environment.ambient_light_color = theme["ambient"]
        environment.ambient_light_energy = 0.82
        environment.fog_enabled = true
        environment.fog_light_color = theme["fog"]
        environment.fog_density = 0.006 if chapter_id in ["asgard", "poseidon"] else 0.003
        environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    if is_instance_valid(sun):
        sun.light_color = theme["sun"]
        sun.light_energy = 1.18 if chapter_id == "hades" else 1.35
    if is_instance_valid(floor_material):
        floor_material.albedo_color = theme["floor"]
        floor_material.metallic = float(theme["metallic"])
    if is_instance_valid(ring_root):
        for ring in ring_root.get_children():
            if ring is MeshInstance3D:
                var ring_material := StandardMaterial3D.new()
                ring_material.albedo_color = theme["ring"]
                ring_material.emission_enabled = true
                ring_material.emission = theme["ring"] * 0.45
                ring.material_override = ring_material
    _rebuild_decorations(theme, chapter_id)
    return true

func _rebuild_decorations(theme: Dictionary, chapter_id: String) -> void:
    if is_instance_valid(decor_root):
        decor_root.queue_free()
    decor_root = Node3D.new()
    decor_root.name = "ChapterDecorations"
    add_child(decor_root)
    var primary: Color = theme["ring"]
    var secondary: Color = theme["floor"].lightened(0.42)
    var pillar_height := float(theme["height"])
    for index in range(8):
        var angle := TAU * float(index) / 8.0
        var radius := 13.0 if chapter_id != "sanctuary_twelve_houses" else 11.0
        var position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        _add_column(position, pillar_height, primary, secondary, chapter_id)
    if chapter_id == "heaven" or chapter_id == "original_final":
        for ring_index in range(3):
            var halo := MeshInstance3D.new()
            var halo_mesh := TorusMesh.new()
            halo_mesh.inner_radius = 5.0 + float(ring_index) * 2.2
            halo_mesh.outer_radius = halo_mesh.inner_radius + 0.07
            halo.mesh = halo_mesh
            halo.position.y = 3.0 + float(ring_index) * 1.35
            halo.rotation.x = deg_to_rad(18.0 + float(ring_index) * 17.0)
            var halo_material := StandardMaterial3D.new()
            halo_material.albedo_color = primary
            halo_material.emission_enabled = true
            halo_material.emission = primary * 0.52
            halo.material_override = halo_material
            decor_root.add_child(halo)
    if chapter_id == "original_final":
        for star_index in range(42):
            var star := MeshInstance3D.new()
            var star_mesh := SphereMesh.new()
            star_mesh.radius = 0.045 + float(star_index % 3) * 0.018
            star_mesh.height = star_mesh.radius * 2.0
            star.mesh = star_mesh
            var angle := float(star_index) * 2.399
            var distance := 8.0 + float((star_index * 7) % 19)
            star.position = Vector3(cos(angle) * distance, 2.0 + float((star_index * 11) % 14) * 0.42, sin(angle) * distance)
            var star_material := StandardMaterial3D.new()
            star_material.albedo_color = Color(0.82, 0.76, 1.0)
            star_material.emission_enabled = true
            star_material.emission = Color(0.52, 0.42, 1.0)
            star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            star.material_override = star_material
            decor_root.add_child(star)

func _add_column(at: Vector3, column_height: float, primary: Color, secondary: Color, chapter_id: String) -> void:
    var column := MeshInstance3D.new()
    var column_mesh := CylinderMesh.new()
    column_mesh.top_radius = 0.34
    column_mesh.bottom_radius = 0.52
    column_mesh.height = column_height
    column.mesh = column_mesh
    column.position = at + Vector3.UP * column_height * 0.5
    var column_material := StandardMaterial3D.new()
    column_material.albedo_color = secondary if chapter_id == "sanctuary_twelve_houses" or chapter_id == "heaven" else primary.darkened(0.28)
    column_material.metallic = 0.48
    column_material.roughness = 0.3
    column_material.emission_enabled = true
    column_material.emission = primary * 0.06
    column.material_override = column_material
    decor_root.add_child(column)
    var capital := MeshInstance3D.new()
    var capital_mesh := CylinderMesh.new()
    capital_mesh.top_radius = 0.62
    capital_mesh.bottom_radius = 0.62
    capital_mesh.height = 0.22
    capital.mesh = capital_mesh
    capital.position = at + Vector3.UP * (column_height + 0.12)
    capital.material_override = column_material
    decor_root.add_child(capital)
