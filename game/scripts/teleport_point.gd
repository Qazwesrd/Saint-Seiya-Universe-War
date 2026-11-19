extends Node3D

func _ready() -> void:
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 1.1
    torus.outer_radius = 1.28
    ring.mesh = torus
    ring.position.y = 0.08
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(0.18, 0.72, 1.0)
    material.emission_enabled = true
    material.emission = Color(0.04, 0.35, 1.0)
    ring.material_override = material
    add_child(ring)

    var beam := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.08
    cylinder.bottom_radius = 0.55
    cylinder.height = 2.8
    beam.mesh = cylinder
    beam.position.y = 1.4
    var beam_material := StandardMaterial3D.new()
    beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    beam_material.albedo_color = Color(0.12, 0.55, 1.0, 0.22)
    beam_material.emission_enabled = true
    beam_material.emission = Color(0.05, 0.32, 1.0)
    beam.material_override = beam_material
    add_child(beam)

    var label := Label3D.new()
    label.text = "竞技场传送阵"
    label.position.y = 3.1
    label.font_size = 30
    label.modulate = Color(0.45, 0.82, 1.0)
    add_child(label)
