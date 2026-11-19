extends Node3D

func _ready() -> void:
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.72, 0.62, 0.32)
    material.metallic = 0.35
    material.roughness = 0.32
    material.emission_enabled = true
    material.emission = Color(0.12, 0.08, 0.015)
    body.material_override = material
    add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.28
    head.mesh = sphere
    head.position.y = 2.0
    head.material_override = material
    add_child(head)

    var marker := MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.48
    ring.outer_radius = 0.58
    marker.mesh = ring
    marker.position.y = 2.55
    var marker_material := StandardMaterial3D.new()
    marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    marker_material.albedo_color = Color(1.0, 0.78, 0.18)
    marker_material.emission_enabled = true
    marker_material.emission = Color(1.0, 0.52, 0.05)
    marker.material_override = marker_material
    add_child(marker)

    var label := Label3D.new()
    label.text = "！ 圣域训练引导员"
    label.position.y = 2.9
    label.font_size = 36
    label.modulate = Color(1.0, 0.88, 0.48)
    add_child(label)
