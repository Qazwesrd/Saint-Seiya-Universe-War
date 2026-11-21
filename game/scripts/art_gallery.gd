extends Control
## Standalone art review room for generated GLB models and skill-effect look-dev.
## Open res://scenes/art_gallery.tscn from the Godot editor after the art bundle is installed.

const ITEMS := {
	"人物": [
		{"id": "pegasus", "name": "天马座人物原型", "path": "res://assets/characters/pegasus/model/character.glb"},
		{"id": "dragon", "name": "天龙座人物原型", "path": "res://assets/characters/dragon/model/character.glb"},
		{"id": "cygnus", "name": "天鹅座人物原型", "path": "res://assets/characters/cygnus/model/character.glb"},
		{"id": "phoenix", "name": "凤凰座人物原型", "path": "res://assets/characters/phoenix/model/character.glb"}
	],
	"圣衣": [
		{"id": "aries_gold_cloth", "name": "白羊座黄金圣衣", "path": "res://assets/armors/aries_gold_cloth/model/armor.glb"},
		{"id": "taurus_gold_cloth", "name": "金牛座黄金圣衣", "path": "res://assets/armors/taurus_gold_cloth/model/armor.glb"},
		{"id": "gemini_gold_cloth", "name": "双子座黄金圣衣", "path": "res://assets/armors/gemini_gold_cloth/model/armor.glb"},
		{"id": "pegasus_bronze_cloth", "name": "天马座青铜圣衣", "path": "res://assets/armors/pegasus_bronze_cloth/model/armor.glb"}
	],
	"BOSS": [
		{"id": "pope_saga", "name": "教皇撒加", "path": "res://assets/enemies/pope_saga/model/enemy.glb"},
		{"id": "gold_taurus", "name": "金牛座阿鲁迪巴", "path": "res://assets/enemies/gold_taurus/model/enemy.glb"},
		{"id": "god_warrior_thor", "name": "阿尔法星神斗士托尔", "path": "res://assets/enemies/god_warrior_thor/model/enemy.glb"},
		{"id": "hades_emperor", "name": "冥王哈迪斯", "path": "res://assets/enemies/hades_emperor/model/enemy.glb"}
	],
	"技能特效": [
		{"id": "cosmos", "name": "小宇宙星辰", "element": "cosmos", "color": Color(0.35, 0.68, 1.0)},
		{"id": "ice", "name": "冰霜星尘", "element": "ice", "color": Color(0.45, 0.86, 1.0)},
		{"id": "fire", "name": "凤凰烈焰", "element": "fire", "color": Color(1.0, 0.28, 0.08)},
		{"id": "lightning", "name": "黄金雷霆", "element": "lightning", "color": Color(1.0, 0.88, 0.25)},
		{"id": "dark", "name": "冥界暗影", "element": "dark", "color": Color(0.62, 0.28, 0.9)},
		{"id": "water", "name": "海皇潮汐", "element": "water", "color": Color(0.18, 0.72, 1.0)}
	]
}

var category := "人物"
var item_index := 0
var preview_root: Node3D
var camera: Camera3D
var status_label: Label
var title_label: Label
var viewport: SubViewport
var drag_active := false
var last_pointer := Vector2.ZERO

func _ready() -> void:
	_build_gallery()
	_show_item()

func _process(delta: float) -> void:
	if is_instance_valid(preview_root) and not drag_active:
		preview_root.rotate_y(delta * 0.22)

func _build_gallery() -> void:
	var background := ColorRect.new()
	background.color = Color(0.012, 0.02, 0.055, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.add_theme_constant_override("margin_left", 20)
	root.add_theme_constant_override("margin_right", 20)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_bottom", 14)
	add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var heading := Label.new()
	heading.text = "美术模型展厅  /  ART REVIEW"
	heading.add_theme_font_size_override("font_size", 25)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	header.add_child(back)

	var categories := HBoxContainer.new()
	root.add_child(categories)
	for name in ITEMS.keys():
		var button := Button.new()
		button.text = name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): _select_category(name))
		categories.add_child(button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var stage_panel := PanelContainer.new()
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(stage_panel)

	viewport = SubViewport.new()
	viewport.size = Vector2i(1000, 700)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage_panel.add_child(viewport)

	var world := World3D.new()
	viewport.world_3d = world
	var stage := Node3D.new()
	viewport.add_child(stage)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.015, 0.035, 0.12)
	sky_material.sky_horizon_color = Color(0.08, 0.12, 0.24)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.82)
	env.ambient_light_energy = 0.8
	environment.environment = env
	stage.add_child(environment)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -25, 0)
	key_light.light_energy = 1.7
	stage.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-15, 145, 0)
	fill_light.light_color = Color(0.35, 0.55, 1.0)
	fill_light.light_energy = 0.75
	stage.add_child(fill_light)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(18, 18)
	floor.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.035, 0.055, 0.11)
	floor_material.metallic = 0.45
	floor_material.roughness = 0.32
	floor.material_override = floor_material
	floor.position.y = -0.04
	stage.add_child(floor)

	var plinth := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.35
	cylinder.bottom_radius = 1.5
	cylinder.height = 0.18
	plinth.mesh = cylinder
	var plinth_mat := StandardMaterial3D.new()
	plinth_mat.albedo_color = Color(0.16, 0.2, 0.32)
	plinth_mat.metallic = 0.72
	plinth_mat.roughness = 0.26
	plinth.material_override = plinth_mat
	plinth.position.y = 0.05
	stage.add_child(plinth)

	camera = Camera3D.new()
	camera.position = Vector3(0, 2.2, 6.8)
	camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
	camera.current = true
	stage.add_child(camera)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(260, 0)
	body.add_child(side)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(title_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(status_label)

	var controls := HBoxContainer.new()
	root.add_child(controls)
	var previous := Button.new()
	previous.text = "上一个"
	previous.pressed.connect(func(): _step_item(-1))
	controls.add_child(previous)
	var next := Button.new()
	next.text = "下一个"
	next.pressed.connect(func(): _step_item(1))
	controls.add_child(next)
	var reset := Button.new()
	reset.text = "重置视角"
	reset.pressed.connect(func():
		camera.position = Vector3(0, 2.2, 6.8)
		camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
	)
	controls.add_child(reset)
	var hint := Label.new()
	hint.text = "模型可自动旋转；鼠标/触屏拖动可转动展台"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_child(hint)

func _select_category(value: String) -> void:
	category = value
	item_index = 0
	_show_item()

func _step_item(direction: int) -> void:
	item_index = wrapi(item_index + direction, 0, ITEMS[category].size())
	_show_item()

func _show_item() -> void:
	if not is_instance_valid(preview_root):
		preview_root = Node3D.new()
		viewport.add_child(preview_root)
	else:
		for child in preview_root.get_children():
			child.queue_free()
	preview_root.rotation = Vector3.ZERO
	var item: Dictionary = ITEMS[category][item_index]
	title_label.text = "%s\n%s  (%d/%d)" % [category, item.name, item_index + 1, ITEMS[category].size()]
	if category == "技能特效":
		_build_effect_preview(item)
		status_label.text = "这是展厅内的程序化特效预览，用于先确认元素色彩、层次和尺度。正式技能还需制作专属动画、粒子、命中和终结段。"
		return
	var path := str(item.path)
	if not ResourceLoader.exists(path):
		status_label.text = "模型资源尚未安装：\n%s\n\n当前分支中的模型由 Blender 美术流水线生成并作为 Actions artifact 输出。安装对应美术资源包后即可在这里查看。\n\n注意：目录数量或角色数据不等于最终模型完成。" % path
		return
	var packed := load(path) as PackedScene
	if packed == null:
		status_label.text = "模型文件存在，但 Godot 无法将其作为 PackedScene 加载：\n%s" % path
		return
	var model := packed.instantiate()
	preview_root.add_child(model)
	var bounds := _calculate_bounds(model)
	if bounds.size.length() > 0.001:
		var scale_factor := 2.6 / maxf(bounds.size.y, 0.1)
		model.scale = Vector3.ONE * scale_factor
		model.position.y = -bounds.position.y * scale_factor
	status_label.text = "模型已加载。可旋转检查轮廓、比例、材质和模型细节。\n\n文件：%s\n\n正式验收还需检查骨骼、动画、贴图、LOD 和移动端表现。" % path

func _calculate_bounds(root_node: Node) -> AABB:
	var found := false
	var result := AABB()
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root_node, meshes)
	for mesh_instance in meshes:
		var bounds := mesh_instance.get_aabb()
		var global_transform := mesh_instance.global_transform
		var transformed := global_transform * bounds
		result = transformed if not found else result.merge(transformed)
		found = true
	return result if found else AABB(Vector3.ZERO, Vector3(1, 2, 1))

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node)
	for child in node.get_children():
		_collect_meshes(child, output)

func _build_effect_preview(item: Dictionary) -> void:
	var color: Color = item.color
	for index in range(3):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.035 + float(index) * 0.012
		torus.outer_radius = 0.72 + float(index) * 0.28
		ring.mesh = torus
		ring.position.y = 0.8 + float(index) * 0.18
		ring.rotation_degrees = Vector3(90 + index * 22, index * 31, 0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color.r, color.g, color.b, 0.78)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.2
		ring.material_override = material
		preview_root.add_child(ring)
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.68
	core.mesh = sphere
	core.position.y = 0.9
	var core_material := StandardMaterial3D.new()
	core_material.albedo_color = color
	core_material.emission_enabled = true
	core_material.emission = color
	core_material.emission_energy_multiplier = 3.0
	core.material_override = core_material
	preview_root.add_child(core)
