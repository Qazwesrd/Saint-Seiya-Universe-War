extends Control
## Android 横屏主菜单：负责导航、设置与三槽本地存档入口。

var status_label: Label
var settings_panel: PanelContainer
var slots_panel: PanelContainer
var slots_list: VBoxContainer
var slot_notice: Label
var pending_delete_slot: int = 0
var delete_dialog: ConfirmationDialog

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

	_add_button(layout, "开始新游戏 / 新建存档", _on_new_game_pressed)
	_add_button(layout, "继续游戏 / 存档管理", _on_continue_pressed)
	_add_button(layout, "游戏设置", _on_settings_pressed)
	_add_button(layout, "退出游戏", _on_exit_pressed)

	settings_panel = _build_settings_panel()
	settings_panel.visible = false
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-340, -305)
	settings_panel.custom_minimum_size = Vector2(680, 610)
	add_child(settings_panel)

	slots_panel = _build_slots_panel()
	slots_panel.visible = false
	slots_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	slots_panel.position = Vector2(-410, -330)
	slots_panel.custom_minimum_size = Vector2(820, 660)
	add_child(slots_panel)

	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "删除存档"
	delete_dialog.dialog_text = "删除前会自动创建备份。确定删除这个存档槽吗？"
	delete_dialog.confirmed.connect(_confirm_delete_slot)
	add_child(delete_dialog)

func _add_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)

func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	var heading := Label.new()
	heading.text = "完整游戏设置"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	outer.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	_add_settings_section(content, "画面与性能")
	_add_option_setting(content, "画质", "graphics", "quality", ["low", "medium", "high"], ["低", "中", "高"])
	_add_option_setting(content, "帧率上限", "graphics", "fps_limit", [30, 45, 60, 90, 120], ["30 FPS", "45 FPS", "60 FPS", "90 FPS", "120 FPS"])
	_add_slider_setting(content, "渲染比例", "graphics", "render_scale", 0.5, 1.0, 0.05)
	_add_check_setting(content, "显示阴影", "graphics", "shadows")
	_add_check_setting(content, "显示战斗特效", "graphics", "effects")
	_add_settings_section(content, "声音")
	_add_slider_setting(content, "总音量", "audio", "master", 0.0, 1.0, 0.05)
	_add_slider_setting(content, "音乐音量", "audio", "music", 0.0, 1.0, 0.05)
	_add_slider_setting(content, "战斗音效", "audio", "sfx", 0.0, 1.0, 0.05)
	_add_slider_setting(content, "界面音效", "audio", "ui", 0.0, 1.0, 0.05)
	_add_settings_section(content, "镜头")
	_add_slider_setting(content, "镜头距离", "camera", "distance", 3.0, 14.0, 0.5)
	_add_slider_setting(content, "镜头灵敏度", "camera", "sensitivity", 0.2, 3.0, 0.1)
	_add_check_setting(content, "反转垂直镜头", "camera", "invert_y")
	_add_settings_section(content, "触控与操作")
	_add_check_setting(content, "战斗震动反馈", "controls", "vibration")
	_add_check_setting(content, "自动拾取物品", "controls", "auto_pickup")
	_add_check_setting(content, "左手操作布局", "controls", "left_handed")
	_add_slider_setting(content, "虚拟按键大小", "controls", "button_scale", 0.75, 1.5, 0.05)
	_add_settings_section(content, "玩法辅助")
	_add_check_setting(content, "自动锁定目标", "gameplay", "auto_target")
	_add_check_setting(content, "显示伤害数字", "gameplay", "damage_numbers")
	_add_check_setting(content, "显示新手提示", "gameplay", "show_tutorials")
	_add_settings_section(content, "系统")
	_add_option_setting(content, "界面语言", "system", "language", ["zh_CN", "en_US"], ["简体中文", "English"])
	var actions := HBoxContainer.new()
	var reset := Button.new()
	reset.text = "恢复默认设置"
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(_on_reset_settings)
	actions.add_child(reset)
	var close := Button.new()
	close.text = "返回主菜单"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(func() -> void: settings_panel.visible = false)
	actions.add_child(close)
	outer.add_child(actions)
	panel.custom_minimum_size = Vector2(680, 610)
	return panel

func _add_settings_section(parent: VBoxContainer, caption: String) -> void:
	var label := Label.new()
	label.text = "— " + caption + " —"
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)

func _add_option_setting(parent: VBoxContainer, caption: String, section: String, key: String, values: Array, labels: Array) -> void:
	var option := OptionButton.new()
	for index in range(values.size()):
		option.add_item(str(labels[index]))
	var current: Variant = SettingsManager.get_value(section, key)
	var selected := values.find(current)
	option.select(maxi(0, selected))
	option.item_selected.connect(_on_option_setting_changed.bind(section, key, values))
	parent.add_child(_labeled_control(caption, option))

func _add_slider_setting(parent: VBoxContainer, caption: String, section: String, key: String, minimum: float, maximum: float, step: float) -> void:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(SettingsManager.get_value(section, key, minimum))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_setting_changed.bind(section, key))
	parent.add_child(_labeled_control(caption, slider))

func _add_check_setting(parent: VBoxContainer, caption: String, section: String, key: String) -> void:
	var check := CheckBox.new()
	check.text = caption
	check.button_pressed = bool(SettingsManager.get_value(section, key, false))
	check.toggled.connect(_on_check_setting_changed.bind(section, key))
	parent.add_child(check)

func _on_option_setting_changed(index: int, section: String, key: String, values: Array) -> void:
	SettingsManager.set_value(section, key, values[index])

func _on_slider_setting_changed(value: float, section: String, key: String) -> void:
	SettingsManager.set_value(section, key, value)

func _on_check_setting_changed(value: bool, section: String, key: String) -> void:
	SettingsManager.set_value(section, key, value)

func _on_reset_settings() -> void:
	if SettingsManager.reset_all():
		settings_panel.queue_free()
		settings_panel = _build_settings_panel()
		settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		settings_panel.position = Vector2(-340, -305)
		add_child(settings_panel)
		settings_panel.visible = true
func _build_slots_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var heading := Label.new()
	heading.text = "本地存档管理（最多三个角色）"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	outer.add_child(heading)

	slot_notice = Label.new()
	slot_notice.text = "存档只保存在本机，不需要登录或联网。"
	slot_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(slot_notice)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 470)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	slots_list = VBoxContainer.new()
	slots_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_list.add_theme_constant_override("separation", 12)
	scroll.add_child(slots_list)

	var close := Button.new()
	close.text = "返回主菜单"
	close.custom_minimum_size.y = 46
	close.pressed.connect(func() -> void: slots_panel.visible = false)
	outer.add_child(close)
	return panel

func _refresh_slots() -> void:
	for child in slots_list.get_children():
		child.queue_free()
	for slot in range(1, 4):
		var summary: Dictionary = RPGState.get_slot_summary(slot)
		var card := PanelContainer.new()
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		card.add_child(column)

		var heading := Label.new()
		heading.text = "存档槽 %d  ·  %s" % [slot, str(summary.get("label", "未知"))]
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(heading)

		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 6)
		column.add_child(actions)
		if bool(summary.get("exists", false)):
			_add_slot_button(actions, "读取", _load_slot.bind(slot), true)
			_add_slot_button(actions, "备份", _backup_slot.bind(slot), true)
			_add_slot_button(actions, "恢复备份", _restore_slot.bind(slot), RPGState.has_backup_slot(slot))
			_add_slot_button(actions, "删除", _request_delete_slot.bind(slot), true)
		else:
			_add_slot_button(actions, "新建角色", _create_slot.bind(slot), true)
			_add_slot_button(actions, "从备份恢复", _restore_slot.bind(slot), RPGState.has_backup_slot(slot))
		slots_list.add_child(card)

func _add_slot_button(parent: HBoxContainer, caption: String, action: Callable, enabled: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(130, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)

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
	status_label.text = "本地离线模式  ·  当前槽位 %d  ·  %s Lv.%d" % [
		RPGState.active_slot,
		str(RPGState.CLASS_DATA.get(str(profile.get("class_id", "pegasus")), {}).get("name", "天马座")),
		int(profile.get("level", 1))
	]

func _show_slots(message: String = "选择一个存档槽进行新建、读取或管理。") -> void:
	slot_notice.text = message
	_refresh_slots()
	settings_panel.visible = false
	slots_panel.visible = true

func _on_new_game_pressed() -> void:
	_show_slots("新建角色只允许使用空槽位；已有进度不会被覆盖。")

func _on_continue_pressed() -> void:
	_show_slots("选择已有存档读取，或管理备份。")

func _create_slot(slot: int) -> void:
	if RPGState.create_new_slot(slot):
		_enter_game("已在存档槽 %d 创建新角色。" % slot)
	else:
		slot_notice.text = "创建失败：槽位可能已有存档，或本地存储不可写。"
		_refresh_slots()

func _load_slot(slot: int) -> void:
	if RPGState.load_slot(slot):
		_enter_game("已读取存档槽 %d。" % slot)
	else:
		slot_notice.text = "读取失败：存档损坏或版本不兼容。"
		_refresh_slots()

func _backup_slot(slot: int) -> void:
	slot_notice.text = "备份成功。" if RPGState.backup_slot(slot) else "备份失败，请检查存储空间。"
	_refresh_slots()

func _restore_slot(slot: int) -> void:
	if RPGState.restore_backup(slot):
		_enter_game("已从备份恢复存档槽 %d。" % slot)
	else:
		slot_notice.text = "恢复失败：没有可用备份，或备份文件损坏。"
		_refresh_slots()

func _request_delete_slot(slot: int) -> void:
	pending_delete_slot = slot
	delete_dialog.dialog_text = "删除存档槽 %d？删除前会自动备份，可在空槽位中恢复。" % slot
	delete_dialog.popup_centered()

func _confirm_delete_slot() -> void:
	var slot := pending_delete_slot
	pending_delete_slot = 0
	slot_notice.text = "存档已删除并备份。" if RPGState.delete_slot(slot) else "删除失败：备份或文件操作未成功。"
	_refresh_slots()

func _enter_game(message: String) -> void:
	status_label.text = message
	slots_panel.visible = false
	_update_status()
	SceneFlowManager.change_scene("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	slots_panel.visible = false
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
