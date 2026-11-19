extends Node3D
var target: Node3D
var follow_distance := 1.8
var orbit_offset := Vector3.ZERO
var follow_speed := 5.5
var bob_time := 0.0
func _ready() -> void:
 var mesh_node := MeshInstance3D.new()
 var mesh := SphereMesh.new()
 mesh.radius = 0.32
 mesh.height = 0.64
 mesh_node.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.35,0.72,1.0)
 material.emission_enabled = true
 material.emission = Color(0.08,0.28,0.85)
 material.metallic = 0.35
 mesh_node.material_override = material
 mesh_node.position.y = 0.65
 add_child(mesh_node)
 var ring_node := MeshInstance3D.new()
 var ring := TorusMesh.new()
 ring.inner_radius = 0.38
 ring.outer_radius = 0.44
 ring_node.mesh = ring
 ring_node.rotation_degrees.x = 90
 ring_node.position.y = 0.65
 ring_node.material_override = material
 add_child(ring_node)
func _process(delta: float) -> void:
 if not is_instance_valid(target): return
 bob_time += delta
 var desired := target.global_position + target.global_transform.basis * orbit_offset
 desired.y += 0.75 + sin(bob_time*3.0)*0.12
 var distance := global_position.distance_to(desired)
 if distance > follow_distance:
  global_position = global_position.move_toward(desired,follow_speed*delta)
