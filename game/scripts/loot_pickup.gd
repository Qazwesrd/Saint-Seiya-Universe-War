extends Area3D

var game: Node3D
var item_id := ""
var item_name := "战利品"
var quantity := 1
var remaining_lifetime := 90.0
var pickup_color := Color(0.35, 0.85, 1.0)
var animation_clock := 0.0
var visual: MeshInstance3D
var glow_light: OmniLight3D
var pickup_material: StandardMaterial3D
var label: Label3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var shape_node := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 1.15
	shape_node.shape = sphere_shape
	add_child(shape_node)

	visual = MeshInstance3D.new()
	var crystal := PrismMesh.new()
	crystal.size = Vector3(0.52, 0.72, 0.52)
	visual.mesh = crystal
	pickup_material = StandardMaterial3D.new()
	pickup_material.albedo_color = pickup_color
	pickup_material.emission_enabled = true
	pickup_material.emission = pickup_color
	pickup_material.emission_energy_multiplier = 1.8
	pickup_material.metallic = 0.35
	pickup_material.roughness = 0.18
	visual.material_override = pickup_material
	visual.position.y = 0.55
	add_child(visual)

	var ring_node := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.38
	ring.outer_radius = 0.43
	ring_node.mesh = ring
	ring_node.position.y = 0.28
	ring_node.rotation_degrees.x = 90
	ring_node.material_override = pickup_material
	add_child(ring_node)

	glow_light = OmniLight3D.new()
	glow_light.light_color = pickup_color
	glow_light.light_energy = 0.8
	glow_light.omni_range = 3.0
	glow_light.position.y = 0.6
	add_child(glow_light)

	label = Label3D.new()
	label.text = "%s ×%d" % [item_name, quantity]
	label.position.y = 1.2
	label.font_size = 24
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	body_entered.connect(_on_body_entered)
	add_to_group("loot_pickups")

func _process(delta: float) -> void:
	animation_clock += delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()
		return
	if is_instance_valid(visual):
		visual.rotation.y += delta * 1.35
		visual.rotation.z = sin(animation_clock * 1.8) * 0.12
		visual.position.y = 0.55 + sin(animation_clock * 2.6) * 0.12
	if is_instance_valid(pickup_material):
		pickup_material.emission_energy_multiplier = 1.2 + (sin(animation_clock * 3.4) + 1.0) * 0.55
	if is_instance_valid(glow_light):
		glow_light.light_energy = 0.55 + (sin(animation_clock * 2.8) + 1.0) * 0.3

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or item_id.is_empty():
		return
	if LootManager.grant_drop(item_id, quantity):
		if is_instance_valid(game) and game.has_method("show_notice"):
			game.call("show_notice", "拾取成功：" + item_name + " ×" + str(quantity))
		queue_free()
