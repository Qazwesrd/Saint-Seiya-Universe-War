extends Node3D

var target: Node3D
var follow_distance := 1.8
var orbit_offset := Vector3.ZERO
var follow_speed := 5.5
var bob_time := 0.0
var visual_root: Node3D
var core_material: StandardMaterial3D
var ring_nodes: Array[MeshInstance3D] = []

func _ready() -> void:
	visual_root = Node3D.new()
	visual_root.name = "CompanionVisual"
	add_child(visual_root)

	var core := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	core.mesh = mesh
	core_material = StandardMaterial3D.new()
	core_material.albedo_color = Color(0.35, 0.72, 1.0)
	core_material.emission_enabled = true
	core_material.emission = Color(0.08, 0.28, 0.85)
	core_material.emission_energy_multiplier = 1.6
	core_material.metallic = 0.55
	core_material.roughness = 0.2
	core.material_override = core_material
	core.position.y = 0.68
	visual_root.add_child(core)

	for index in range(3):
		var ring_node := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.34 + float(index) * 0.075
		ring.outer_radius = ring.inner_radius + 0.035
		ring_node.mesh = ring
		ring_node.position.y = 0.68
		ring_node.rotation_degrees = Vector3(68.0 + float(index) * 23.0, float(index) * 48.0, float(index) * 31.0)
		var ring_material := core_material.duplicate() as StandardMaterial3D
		ring_material.albedo_color = [Color(0.25, 0.8, 1.0), Color(0.7, 0.9, 1.0), Color(0.35, 0.48, 1.0)][index]
		ring_material.emission = ring_material.albedo_color * 1.4
		ring_node.material_override = ring_material
		visual_root.add_child(ring_node)
		ring_nodes.append(ring_node)

	var light := OmniLight3D.new()
	light.name = "CompanionGlow"
	light.light_color = Color(0.22, 0.58, 1.0)
	light.light_energy = 0.65
	light.omni_range = 3.2
	light.position.y = 0.7
	visual_root.add_child(light)

func _process(delta: float) -> void:
	bob_time += delta
	if is_instance_valid(target):
		var desired := target.global_position + target.global_transform.basis * orbit_offset
		desired.y += 0.78 + sin(bob_time * 3.0) * 0.14
		var distance := global_position.distance_to(desired)
		if distance > follow_distance:
			global_position = global_position.move_toward(desired, follow_speed * delta)
		elif distance > 0.08:
			global_position = global_position.move_toward(desired, follow_speed * 0.25 * delta)
	if is_instance_valid(visual_root):
		visual_root.rotation.y += delta * 0.7
		visual_root.rotation.z = sin(bob_time * 1.4) * 0.08
	for index in range(ring_nodes.size()):
		if is_instance_valid(ring_nodes[index]):
			ring_nodes[index].rotation.y += delta * (0.8 if index % 2 == 0 else -1.05)
	if is_instance_valid(core_material):
		core_material.emission_energy_multiplier = 1.25 + (sin(bob_time * 3.2) + 1.0) * 0.45
