extends Area3D

var game: Node3D
var item_id := ""
var item_name := "战利品"
var quantity := 1
var remaining_lifetime := 90.0
var pickup_color := Color(0.35, 0.85, 1.0)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var shape_node := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 1.15
	shape_node.shape = sphere_shape
	add_child(shape_node)
	var visual := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	visual.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = pickup_color
	material.emission_enabled = true
	material.emission = pickup_color
	material.metallic = 0.25
	visual.material_override = material
	visual.position.y = 0.48
	add_child(visual)
	var label := Label3D.new()
	label.text = "%s ×%d" % [item_name, quantity]
	label.position.y = 1.05
	label.font_size = 24
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	body_entered.connect(_on_body_entered)
	add_to_group("loot_pickups")

func _process(delta: float) -> void:
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()
		return
	if get_child_count() > 1:
		var visual := get_child(1) as Node3D
		if is_instance_valid(visual):
			visual.rotate_y(delta * 1.8)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or item_id.is_empty():
		return
	if LootManager.grant_drop(item_id, quantity):
		if is_instance_valid(game) and game.has_method("show_notice"):
			game.call("show_notice", "拾取成功：" + item_name + " ×" + str(quantity))
		queue_free()
