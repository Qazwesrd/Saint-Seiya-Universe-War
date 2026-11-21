extends Node3D

var marker: MeshInstance3D
var marker_material: StandardMaterial3D
var robe_material: StandardMaterial3D
var animation_clock := 0.0
var visual_root: Node3D

func _ready() -> void:
	visual_root = Node3D.new()
	visual_root.name = "GuideVisual"
	add_child(visual_root)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48
	capsule.height = 1.8
	body.mesh = capsule
	body.position.y = 0.9
	robe_material = StandardMaterial3D.new()
	robe_material.albedo_color = Color(0.72, 0.62, 0.32)
	robe_material.metallic = 0.35
	robe_material.roughness = 0.32
	robe_material.emission_enabled = true
	robe_material.emission = Color(0.12, 0.08, 0.015)
	body.material_override = robe_material
	visual_root.add_child(body)

	var mantle := MeshInstance3D.new()
	var mantle_mesh := SphereMesh.new()
	mantle_mesh.radius = 0.57
	mantle_mesh.height = 0.65
	mantle.mesh = mantle_mesh
	mantle.position = Vector3(0, 1.35, 0)
	mantle.scale = Vector3(1.0, 0.8, 0.72)
	mantle.material_override = robe_material
	visual_root.add_child(mantle)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	head.mesh = sphere
	head.position.y = 2.0
	var face_material := StandardMaterial3D.new()
	face_material.albedo_color = Color(0.88, 0.76, 0.58)
	face_material.roughness = 0.8
	head.material_override = face_material
	visual_root.add_child(head)

	for side in [-1.0, 1.0]:
		var shoulder := MeshInstance3D.new()
		var shoulder_mesh := SphereMesh.new()
		shoulder_mesh.radius = 0.2
		shoulder.mesh = shoulder_mesh
		shoulder.position = Vector3(side * 0.48, 1.58, 0)
		shoulder.scale = Vector3(1.2, 0.72, 0.9)
		shoulder.material_override = robe_material
		visual_root.add_child(shoulder)

	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.48
	ring.outer_radius = 0.58
	marker.mesh = ring
	marker.position.y = 2.55
	marker_material = StandardMaterial3D.new()
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.albedo_color = Color(1.0, 0.78, 0.18)
	marker_material.emission_enabled = true
	marker_material.emission = Color(1.0, 0.52, 0.05)
	marker.material_override = marker_material
	visual_root.add_child(marker)

	var label := Label3D.new()
	label.text = "！ " + FactionDatabase.get_tutorial_mentor_name()
	label.position.y = 2.9
	label.font_size = 36
	label.outline_size = 8
	label.modulate = Color(1.0, 0.88, 0.48)
	visual_root.add_child(label)

	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.68, 0.2)
	glow.light_energy = 0.45
	glow.omni_range = 3.5
	glow.position.y = 1.6
	visual_root.add_child(glow)

func _process(delta: float) -> void:
	animation_clock += delta
	if is_instance_valid(marker):
		marker.rotation.y += delta * 0.9
		marker.position.y = 2.55 + sin(animation_clock * 2.2) * 0.09
	if is_instance_valid(marker_material):
		marker_material.emission_energy_multiplier = 1.0 + (sin(animation_clock * 3.0) + 1.0) * 0.5
	if is_instance_valid(visual_root):
		visual_root.position.y = sin(animation_clock * 1.4) * 0.025
