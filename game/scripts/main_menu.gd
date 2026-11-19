extends Control
## Android 横屏主菜单；只负责入口导航和基础设置，不持有角色/任务数据。

var status_label: Label
var settings_panel: PanelContainer

func _ready() -> void:
	_build_interface()
	_update_status()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color(0.018, 0.028, 0.075, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(520, 0)
	layout.add_theme_constant_override("separation", 14)
	center.add_child(layout)

	var title := Label.new()
	title.text = "圣斗士：宇宙之战"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "离线动作角色扮演 · Android 横屏版"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	layout.add_child(subtitle)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

	_add_button(layout, "开始游戏", _on_start_pressed)
	_add_button(layout, "继续游戏", _on_continue_pressed)
	_add_button(layout, "游戏设置", _on_settings_pressed)
	_add_button(layout, "退出游戏", _on_exit_pressed)

	settings_panel = _build_settings_panel()
	settings_panel.visible = false
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-230, -170)
	settings_panel.custom_minimum_size = Vector2(460, 340)
	add_child(settings_panel)

func _add_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)

func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var heading := Label.new()
	heading.text = "游戏设置"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)

	var quality := OptionButton.new()
	quality.add_item("低画质", 0)
	quality.add_item("中画质", 1)
	quality.add_item("高画质", 2)
	var current_quality := str(SettingsManager.get_value("graphics", "quality", "medium"))
	quality.select(0 if current_quality == "low" else (2 if current_quality == "high" else 1))
	quality.item_selected.connect(_on_quality_selected)
	column.add_child(_labeled_control("画质", quality))

	var fps := OptionButton.new()
	fps.add_item("30 FPS", 30)
	fps.add_item("45 FPS", 45)
	fps.add_item("60 FPS", 60)
	fps.add_item("90 FPS", 90)
	var current_fps := int(SettingsManager.get_value("graphics", "fps_limit", 60))
	fps.select(0 if current_fps <= 30 else (1 if current_fps <= 45 else (2 if current_fps <= 60 else 3)))
	fps.item_selected.connect(_on_fps_selected.bind(fps))
	column.add_child(_labeled_control("帧率上限", fps))

	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(SettingsManager.get_value("audio", "master", 1.0))
	volume.value_changed.connect(_on_master_volume_changed)
	column.add_child(_labeled_control("主音量", volume))

	var close := Button.new()
	close.text = "返回主菜单"
	close.custom_minimum_size.y = 46
	close.pressed.connect(func() -> void: settings_panel.visible = false)
	column.add_child(close)
	return panel

func _labeled_control(caption: String, control: Control) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 110
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row

func _update_status() -> void:
	if status_label == null:
		return
	var profile: Dictionary = RPGState.profile
	status_label.text = "本地离线模式  ·  存档槽位 %d  ·  %s Lv.%d" % [
		RPGState.active_slot,
		str(RPGState.CLASS_DATA.get(str(profile.get("class_id", "pegasus")), {}).get("name", "天马座")),
		int(profile.get("level", 1))
	]

func _on_start_pressed() -> void:
	SceneFlowManager.change_scene("res://scenes/main.tscn")

func _on_continue_pressed() -> void:
	var slot := RPGState.active_slot
	if not RPGState.load_slot(slot):
		status_label.text = "当前存档无法读取，将进入当前新角色"
	SceneFlowManager.change_scene("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_quality_selected(index: int) -> void:
	var values := ["low", "medium", "high"]
	SettingsManager.set_value("graphics", "quality", values[clampi(index, 0, 2)])

func _on_fps_selected(index: int, option: OptionButton) -> void:
	SettingsManager.set_value("graphics", "fps_limit", int(option.get_item_id(index)))
	SettingsManager.apply_settings()

func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_value("audio", "master", value)
