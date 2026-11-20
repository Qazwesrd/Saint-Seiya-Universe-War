extends Node3D

var animation_clock := 0.0
var rings: Array[MeshInstance3D] = []
var beam_material: StandardMaterial3D
var portal_light: OmniLight3D

func _ready() -> void:
	for index in range(3):
		var ring_node := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.1 + float(index) * 0.22
		torus.outer_radius = torus.inner_radius + 0.08
		ring_node.mesh = torus
		ring_node.position.y = 0.08 + float(index) * 0.13
		ring_node.rotation_degrees.x = 90.0 + float(index) * 14.0
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = [Color(0.18, 0.72, 1.0), Color(0.42, 0.88, 1.0), Color(0.2, 0.42, 1.0)][index]
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.5
		ring_node.material_override = material
		add_child(ring_node)
		rings.append(ring_node)

	var beam := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.08
	cylinder.bottom_radius = 0.55
	cylinder.height = 2.8
	beam.mesh = cylinder
	beam.position.y = 1.4
	beam_material = StandardMaterial3D.new()
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.albedo_color = Color(0.12, 0.55, 1.0, 0.22)
	beam_material.emission_enabled = true
	beam_material.emission = Color(0.05, 0.32, 1.0)
	beam_material.emission_energy_multiplier = 1.8
	beam.material_override = beam_material
	add_child(beam)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.3
	core_mesh.height = 1.0
	core.mesh = core_mesh
	core.position.y = 1.4
	var core_material := StandardMaterial3D.new()
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.albedo_color = Color(0.55, 0.88, 1.0, 0.8)
	core_material.emission_enabled = true
	core_material.emission = Color(0.18, 0.58, 1.0)
	core.material_override = core_material
	add_child(core)

	portal_light = OmniLight3D.new()
	portal_light.light_color = Color(0.16, 0.55, 1.0)
	portal_light.light_energy = 1.3
	portal_light.omni_range = 7.0
	portal_light.position.y = 1.6
	add_child(portal_light)

	var label := Label3D.new()
	label.text = "竞技场传送阵"
	label.position.y = 3.1
	label.font_size = 30
	label.outline_size = 7
	label.modulate = Color(0.45, 0.82, 1.0)
	add_child(label)

func _process(delta: float) -> void:
	animation_clock += delta
	for index in range(rings.size()):
		var ring_node := rings[index]
		if not is_instance_valid(ring_node):
			continue
		ring_node.rotate_y(delta * (0.45 if index % 2 == 0 else -0.65))
		ring_node.position.y = 0.08 + float(index) * 0.13 + sin(animation_clock * 2.0 + float(index)) * 0.035
	if is_instance_valid(beam_material):
		beam_material.albedo_color.a = 0.14 + (sin(animation_clock * 2.4) + 1.0) * 0.055
	if is_instance_valid(portal_light):
		portal_light.light_energy = 0.9 + (sin(animation_clock * 2.2) + 1.0) * 0.45
