extends Control
## Android 横屏主菜单：负责导航、设置与三槽本地存档入口。

var status_label: Label
var settings_panel: PanelContainer
var slots_panel: PanelContainer
var slots_list: VBoxContainer
var slot_notice: Label
var pending_delete_slot: int = 0
var delete_dialog: ConfirmationDialog
var character_creation_panel: PanelContainer
var character_name_input: LineEdit
var character_class_picker: OptionButton
var creation_notice: Label
var pending_creation_slot := 0
var download_button: Button
var download_in_progress := false
var game_entry_buttons: Array[Button] = []

func _ready() -> void:
	_build_interface()
	_apply_menu_theme()
	_update_status()
	ResourcePackManager.pack_download_progress.connect(_on_pack_download_progress)
	_refresh_download_controls()
	if ResourcePackManager.has_download_source():
		_download_game_data()

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

	download_button = Button.new()
	download_button.text = "下载 / 修复完整离线数据"
	download_button.custom_minimum_size = Vector2(0, 50)
	download_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	download_button.pressed.connect(_download_game_data)
	layout.add_child(download_button)
	if not ResourcePackManager.has_download_source():
		download_button.disabled = true
		download_button.tooltip_text = "等待配置国内主线路和海外备用线路"

	game_entry_buttons.append(_add_button(layout, "开始新游戏 / 新建存档", _on_new_game_pressed))
	game_entry_buttons.append(_add_button(layout, "继续游戏 / 存档管理", _on_continue_pressed))
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

	character_creation_panel = _build_character_creation_panel()
	character_creation_panel.visible = false
	character_creation_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	character_creation_panel.position = Vector2(-310, -230)
	character_creation_panel.custom_minimum_size = Vector2(620, 460)
	add_child(character_creation_panel)

	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "删除存档"
	delete_dialog.dialog_text = "删除前会自动创建备份。确定删除这个存档槽吗？"
	delete_dialog.confirmed.connect(_confirm_delete_slot)
	add_child(delete_dialog)

func _add_button(parent: VBoxContainer, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color(0.91, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.55))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.82))
	button.add_theme_color_override("font_outline_color", Color(0.015, 0.025, 0.07, 0.9))
	button.add_theme_stylebox_override("normal", _make_menu_button_style(Color(0.045, 0.085, 0.18), Color(0.24, 0.48, 0.82)))
	button.add_theme_stylebox_override("hover", _make_menu_button_style(Color(0.075, 0.14, 0.27), Color(0.92, 0.72, 0.32)))
	button.add_theme_stylebox_override("pressed", _make_menu_button_style(Color(0.025, 0.055, 0.12), Color(0.96, 0.78, 0.4)))
	button.add_theme_stylebox_override("disabled", _make_menu_button_style(Color(0.08, 0.09, 0.12), Color(0.25, 0.29, 0.36)))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _refresh_download_controls() -> void:
	var ready := _all_story_packs_installed()
	for button in game_entry_buttons:
		button.disabled = download_in_progress or not ready
		button.tooltip_text = "" if ready else "请先下载并校验完整游戏数据"
	if download_button != null:
		download_button.disabled = download_in_progress or not ResourcePackManager.has_download_source()

func _all_story_packs_installed() -> bool:
	# 尚未配置正式下载线路时，保留开发原型入口；正式线路配置后强制完整数据就绪。
	if not ResourcePackManager.has_download_source():
		return true
	var story_pack_count := 0
	for pack_id in ResourcePackManager.catalog.get("packs", {}):
		var info := ResourcePackManager.get_pack_info(str(pack_id))
		if not bool(info.get("auto_download", false)):
			continue
		story_pack_count += 1
		var status := ResourcePackManager.get_pack_mount_status(str(pack_id))
		if not bool(status.get("valid", false)) or not bool(status.get("mounted", false)):
			return false
	return story_pack_count > 0

func _make_menu_button_style(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.015, 0.06, 0.38)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)
	style.anti_aliasing = true
	return style

func _apply_menu_theme() -> void:
	for panel in [settings_panel, slots_panel, character_creation_panel]:
		if not is_instance_valid(panel):
			continue
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.018, 0.035, 0.09, 0.97)
		panel_style.border_color = Color(0.42, 0.66, 0.98, 0.9)
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(18)
		panel_style.content_margin_left = 18.0
		panel_style.content_margin_right = 18.0
		panel_style.content_margin_top = 16.0
		panel_style.content_margin_bottom = 16.0
		panel_style.shadow_color = Color(0.0, 0.0, 0.025, 0.65)
		panel_style.shadow_size = 18
		panel_style.shadow_offset = Vector2(0.0, 6.0)
		panel.add_theme_stylebox_override("panel", panel_style)
	for label in find_children("*", "Label", true, false):
		(label as Label).add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))
		(label as Label).add_theme_color_override("font_shadow_color", Color(0.0, 0.015, 0.06, 0.9))
		(label as Label).add_theme_constant_override("shadow_offset_x", 1)
		(label as Label).add_theme_constant_override("shadow_offset_y", 2)

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
	_add_slider_setting(content, "环境音量", "audio", "ambience", 0.0, 1.0, 0.05)
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
func _build_character_creation_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	panel.add_child(outer)
	var heading := Label.new()
	heading.text = "创建你的圣斗士"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	outer.add_child(heading)
	var description := Label.new()
	description.text = "选择角色名称与初始职业。神明职业和天斗士将在达到解锁条件后开放。"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(description)
	var name_label := Label.new()
	name_label.text = "角色名称"
	outer.add_child(name_label)
	character_name_input = LineEdit.new()
	character_name_input.placeholder_text = "请输入1至16个字符"
	character_name_input.max_length = 16
	character_name_input.text = "星之战士"
	outer.add_child(character_name_input)
	var class_label := Label.new()
	class_label.text = "初始职业（九大基础职业）"
	outer.add_child(class_label)
	character_class_picker = OptionButton.new()
	for class_id in RPGState.CLASS_DATA:
		var class_data: Dictionary = RPGState.CLASS_DATA[class_id]
		var tier := str(class_data.get("tier", ""))
		if tier in ["神明", "天斗士"]:
			continue
		character_class_picker.add_item(str(class_data.get("name", class_id)))
		character_class_picker.set_item_metadata(character_class_picker.item_count - 1, str(class_id))
	outer.add_child(character_class_picker)
	creation_notice = Label.new()
	creation_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	creation_notice.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	outer.add_child(creation_notice)
	var actions := HBoxContainer.new()
	var confirm := Button.new()
	confirm.text = "创建角色并开始"
	confirm.custom_minimum_size.y = 54
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(_confirm_character_creation)
	actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "返回存档槽"
	cancel.custom_minimum_size.y = 54
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_cancel_character_creation)
	actions.add_child(cancel)
	outer.add_child(actions)
	return panel

func _open_character_creation(slot: int) -> void:
	pending_creation_slot = slot
	character_name_input.text = ""
	creation_notice.text = ""
	if character_class_picker.item_count > 0:
		character_class_picker.select(0)
	slots_panel.visible = false
	character_creation_panel.visible = true
	character_name_input.grab_focus()

func _cancel_character_creation() -> void:
	character_creation_panel.visible = false
	slots_panel.visible = true
	_refresh_slots()

func _confirm_character_creation() -> void:
	var character_name := character_name_input.text.strip_edges()
	if character_name.is_empty() or character_name.length() > 16:
		creation_notice.text = "角色名称必须为1至16个字符。"
		return
	if pending_creation_slot < 1 or pending_creation_slot > 3:
		creation_notice.text = "存档槽选择无效，请返回重新选择。"
		return
	var selected_class := str(character_class_picker.get_item_metadata(character_class_picker.selected))
	if not RPGState.create_new_slot(pending_creation_slot):
		slot_notice.text = "创建失败：存档槽可能已被占用。"
		character_creation_panel.visible = false
		slots_panel.visible = true
		_refresh_slots()
		return
	if not RPGState.select_class(selected_class):
		slot_notice.text = "初始职业设置失败；已保留新存档，请重新读取后再试。"
		character_creation_panel.visible = false
		slots_panel.visible = true
		_refresh_slots()
		return
	var previous_name := str(RPGState.profile.get("character_name", "星之战士"))
	RPGState.profile["character_name"] = character_name
	if not RPGState.save_slot(pending_creation_slot):
		RPGState.profile["character_name"] = previous_name
		RPGState.save_slot(pending_creation_slot)
		slot_notice.text = "角色名称保存失败；存档已保留，请检查本地存储空间。"
		character_creation_panel.visible = false
		slots_panel.visible = true
		_refresh_slots()
		return
	_enter_game("欢迎，%s！已创建%s。" % [character_name, str(RPGState.CLASS_DATA.get(selected_class, {}).get("name", selected_class))])

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
	status_label.text = "本地离线模式  ·  当前槽位 %d  ·  %s（%s）Lv.%d" % [
		RPGState.active_slot,
		str(profile.get("character_name", "星之战士")),
		str(RPGState.CLASS_DATA.get(str(profile.get("class_id", "pegasus")), {}).get("name", "天马座")),
		int(profile.get("level", 1))
	]

func _show_slots(message: String = "选择一个存档槽进行新建、读取或管理。") -> void:
	slot_notice.text = message
	_refresh_slots()
	settings_panel.visible = false
	character_creation_panel.visible = false
	slots_panel.visible = true

func _on_new_game_pressed() -> void:
	if not _all_story_packs_installed():
		status_label.text = "请先下载并校验全部章节数据。"
		return
	_show_slots("新建角色只允许使用空槽位；已有进度不会被覆盖。")

func _on_continue_pressed() -> void:
	if not _all_story_packs_installed():
		status_label.text = "请先下载并校验全部章节数据。"
		return
	_show_slots("选择已有存档读取，或管理备份。")

func _create_slot(slot: int) -> void:
	_open_character_creation(slot)

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
	if not _all_story_packs_installed():
		status_label.text = "完整游戏数据尚未下载完成，暂时不能进入游戏。"
		return
	status_label.text = message
	slots_panel.visible = false
	character_creation_panel.visible = false
	_update_status()
	SceneFlowManager.change_scene("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	slots_panel.visible = false
	character_creation_panel.visible = false
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

func _on_pack_download_progress(pack_id: String, downloaded_bytes: int, total_bytes: int, current_file: String) -> void:
	if status_label == null:
		return
	var percent := 100.0 if total_bytes <= 0 else float(downloaded_bytes) * 100.0 / float(total_bytes)
	status_label.text = "正在下载 %s：%s  %.1f%%" % [str(ResourcePackManager.get_pack_info(pack_id).get("name", pack_id)), current_file, percent]

func _download_game_data() -> void:
	if download_in_progress:
		return
	if not ResourcePackManager.has_download_source():
		status_label.text = "国内主线路和海外备用线路尚未配置，暂时不能下载完整数据。"
		return
	download_in_progress = true
	_refresh_download_controls()
	status_label.text = "正在检查并下载完整游戏数据；国内线路失败时将自动切换备用线路……"
	var success: bool = await ResourcePackManager.download_all_missing_packs()
	download_in_progress = false
	_refresh_download_controls()
	if success:
		status_label.text = "完整离线数据已校验。现在可以断网游玩。"
	else:
		status_label.text = "数据下载未完成；已保留可续传文件，可重试并自动切换下载线路。"
