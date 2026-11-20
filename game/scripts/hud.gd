extends CanvasLayer
var game: Variant
var status_label: Label
var notice_label: Label
var enemy_label: Label
var quest_label: Label
var dialogue_panel: Panel
var hp_bar: ProgressBar
var cosmos_bar: ProgressBar
var skill_button: Button
var burst_button: Button
var minimap_control: Control
var boss_label: Label
var boss_bar: ProgressBar
var stick_base: Panel
var stick_knob: Panel
var finger_id := -1
var stick_value := Vector2.ZERO
var skill_slot_buttons: Array[Button] = []
var flight_button: Button
var flight_up_button: Button
var flight_down_button: Button
var camera_finger_id := -1
var camera_last_position := Vector2.ZERO
var stick_default_position := Vector2(42, 520)
func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var card := Panel.new()
    card.position = Vector2(20, 18)
    card.size = Vector2(300, 112)
    _style_panel(card, Color(0.015, 0.025, 0.08, 0.86), Color(0.18, 0.48, 0.9))
    root.add_child(card)
    status_label = Label.new()
    status_label.position = Vector2(36, 24)
    status_label.add_theme_font_size_override("font_size", 21)
    status_label.text = "天马座 Lv.1"
    root.add_child(status_label)
    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(36, 60)
    hp_bar.size = Vector2(255, 17)
    hp_bar.max_value = 100
    hp_bar.show_percentage = false
    _style_resource_bar(hp_bar, Color(0.92, 0.20, 0.24), Color(0.035, 0.045, 0.09, 0.92), Color(1.0, 0.48, 0.42))
    root.add_child(hp_bar)
    cosmos_bar = ProgressBar.new()
    cosmos_bar.position = Vector2(36, 84)
    cosmos_bar.size = Vector2(255, 12)
    cosmos_bar.max_value = 100
    cosmos_bar.show_percentage = false
    _style_resource_bar(cosmos_bar, Color(0.18, 0.68, 1.0), Color(0.025, 0.055, 0.12, 0.92), Color(0.36, 0.82, 1.0))
    root.add_child(cosmos_bar)
    enemy_label = Label.new()
    enemy_label.position = Vector2(26, 140)
    enemy_label.add_theme_font_size_override("font_size", 18)
    root.add_child(enemy_label)

    var quest_panel := Panel.new()
    quest_panel.position = Vector2(22, 365)
    quest_panel.size = Vector2(330, 94)
    _style_panel(quest_panel, Color(0.015, 0.025, 0.08, 0.82), Color(0.82, 0.62, 0.2))
    root.add_child(quest_panel)
    quest_label = Label.new()
    quest_label.position = Vector2(12, 8)
    quest_label.size = Vector2(306, 78)
    quest_label.add_theme_font_size_override("font_size", 17)
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_label.text = "主线：银河竞技场试炼"
    quest_panel.add_child(quest_label)

    _button(root, "交谈 / 接任务", Vector2(22, 294), Vector2(190, 350), func(): game.call("interact_with_guide"), Color(0.38, 0.28, 0.08))
    _button(root, "任务导航", Vector2(202, 294), Vector2(330, 350), func(): game.call("navigate_to_objective"), Color(0.12, 0.32, 0.42))
    _button(root, "传送", Vector2(22, 470), Vector2(140, 520), func(): game.call("use_teleport_point"), Color(0.08, 0.28, 0.48))
    var map := Panel.new()
    map.anchor_left = 1.0
    map.anchor_right = 1.0
    map.offset_left = -190
    map.offset_right = -22
    map.offset_top = 18
    map.offset_bottom = 142
    _style_panel(map, Color(0.015, 0.025, 0.08, 0.8), Color(0.22, 0.55, 0.95))
    root.add_child(map)
    minimap_control = Control.new()
    minimap_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    minimap_control.set_script(load("res://scripts/minimap.gd"))
    minimap_control.set("game", game)
    map.add_child(minimap_control)
    notice_label = Label.new()
    notice_label.anchor_left = 0.5
    notice_label.anchor_right = 0.5
    notice_label.offset_left = -270
    notice_label.offset_right = 270
    notice_label.offset_top = 24
    notice_label.offset_bottom = 76
    notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice_label.add_theme_font_size_override("font_size", 20)
    root.add_child(notice_label)
    boss_label = Label.new()
    boss_label.anchor_left = 0.5
    boss_label.anchor_right = 0.5
    boss_label.offset_left = -170
    boss_label.offset_right = 170
    boss_label.offset_top = 150
    boss_label.offset_bottom = 178
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_label.add_theme_font_size_override("font_size", 17)
    root.add_child(boss_label)
    boss_bar = ProgressBar.new()
    boss_bar.anchor_left = 0.5
    boss_bar.anchor_right = 0.5
    boss_bar.offset_left = -170
    boss_bar.offset_right = 170
    boss_bar.offset_top = 180
    boss_bar.offset_bottom = 195
    boss_bar.max_value = 100
    boss_bar.show_percentage = false
    _style_resource_bar(boss_bar, Color(0.88, 0.16, 0.24), Color(0.045, 0.018, 0.04, 0.96), Color(1.0, 0.58, 0.36))
    root.add_child(boss_bar)
    stick_base = Panel.new()
    stick_base.position = Vector2(42, 520)
    stick_base.size = Vector2(148, 148)
    _style_panel(stick_base, Color(0.2, 0.35, 0.62, 0.34), Color(0.45, 0.7, 1.0))
    root.add_child(stick_base)
    stick_knob = Panel.new()
    stick_knob.position = Vector2(88, 566)
    stick_knob.size = Vector2(56, 56)
    _style_panel(stick_knob, Color(0.5, 0.75, 1.0, 0.82), Color(0.8, 0.92, 1.0))
    root.add_child(stick_knob)
    _button(root, "GM管理", Vector2(-190, 18), Vector2(-22, 72), func(): _open_gm(root), Color(0.42, 0.12, 0.28))
    _button(root, "商城", Vector2(22, 154), Vector2(112, 214), func(): _open_shop(root), Color(0.28, 0.22, 0.08))
    _button(root, "每日首领", Vector2(118, 154), Vector2(230, 214), func(): _open_daily_boss(root), Color(0.42, 0.16, 0.12))
    _button(root, "角色", Vector2(22, 224), Vector2(112, 284), func(): _open_character(root), Color(0.18, 0.25, 0.48))
    _button(root, "伙伴图鉴", Vector2(118, 224), Vector2(230, 284), func(): _open_collection(root), Color(0.28, 0.18, 0.45))
    flight_button = _button(root, "天翼飞行", Vector2(-520, -190), Vector2(-410, -126), func(): _call_player("toggle_tenkishi_flight"), Color(0.08, 0.38, 0.52))
    flight_up_button = _button(root, "上升", Vector2(-520, -260), Vector2(-410, -196), func(): _call_player("tenkishi_flight_step", 1.0), Color(0.12, 0.42, 0.58))
    flight_down_button = _button(root, "俯冲", Vector2(-520, -330), Vector2(-410, -266), func(): _call_player("tenkishi_flight_step", -1.0), Color(0.12, 0.32, 0.48))
    flight_button.visible = false
    flight_up_button.visible = false
    flight_down_button.visible = false
    _button(root, "闪避", Vector2(-370, -176), Vector2(-278, -104), func(): _call_player("dodge"), Color(0.12, 0.32, 0.55))
    _button(root, "防御", Vector2(-370, -94), Vector2(-278, -22), func(): _call_player("guard"), Color(0.16, 0.34, 0.38))
    _button(root, "锁定", Vector2(-270, -176), Vector2(-178, -104), func(): _call_player("toggle_lock"), Color(0.16, 0.22, 0.42))
    burst_button = _button(root, "小宇宙", Vector2(-180, -278), Vector2(-70, -198), func(): _call_player("cosmos_burst"), Color(0.45, 0.18, 0.08))
    skill_button = _button(root, "流星拳\n技能", Vector2(-292, -98), Vector2(-166, -4), func(): _call_player("skill"), Color(0.08, 0.35, 0.68))
    for slot_index in range(4):
        var slot := slot_index
        var left := -570.0 + float(slot_index) * 92.0
        var top := -270.0
        var slot_button := _button(root, "技能 %d\n未装备" % (slot + 1), Vector2(left, top), Vector2(left + 86.0, top + 72.0), func(): _cast_skill_slot(slot), Color(0.16, 0.28, 0.52))
        skill_slot_buttons.append(slot_button)
    _button(root, "连招", Vector2(-420, -98), Vector2(-300, -4), func(): _call_player("combo_skill"), Color(0.48, 0.2, 0.58))
    _button(root, "连招设置", Vector2(-548, -98), Vector2(-428, -4), func(): _open_combo_editor(root), Color(0.28, 0.22, 0.52))
    _button(root, "普攻", Vector2(-150, -166), Vector2(-24, -34), func(): _call_player("attack"), Color(0.62, 0.15, 0.12))
    _button(root, "个人圣域", Vector2(236, 154), Vector2(350, 214), func(): _open_sanctuary(root), Color(0.22, 0.16, 0.42))
    _button(root, "骑乘 / 下马", Vector2(354, 154), Vector2(488, 214), func(): _call_player("toggle_mount"), Color(0.12, 0.34, 0.38))
    SettingsManager.settings_changed.connect(_on_hud_setting_changed)
    get_viewport().size_changed.connect(_on_resize)
    _on_resize()
func _cast_skill_slot(slot_index: int) -> void:
    if is_instance_valid(game.player):
        game.player.call("cast_skill_slot", slot_index)

func _style_panel(panel: Panel, color: Color, border: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    style.shadow_color = Color(0.0, 0.015, 0.06, 0.42)
    style.shadow_size = 10
    style.shadow_offset = Vector2(0.0, 4.0)
    style.anti_aliasing = true
    style.anti_aliasing_size = 1.2
    panel.add_theme_stylebox_override("panel", style)

func _style_resource_bar(bar: ProgressBar, fill_color: Color, background_color: Color, border_color: Color) -> void:
    var background := StyleBoxFlat.new()
    background.bg_color = background_color
    background.border_color = border_color.darkened(0.35)
    background.set_border_width_all(1)
    background.set_corner_radius_all(7)
    background.content_margin_left = 2.0
    background.content_margin_right = 2.0
    background.content_margin_top = 2.0
    background.content_margin_bottom = 2.0
    background.anti_aliasing = true
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.set_corner_radius_all(6)
    fill.anti_aliasing = true
    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)

func _make_button_style(base_color: Color, border_color: Color, pressed: bool = false, disabled: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = base_color
    style.border_color = border_color
    style.set_border_width_all(2 if not disabled else 1)
    style.set_corner_radius_all(16)
    style.anti_aliasing = true
    style.anti_aliasing_size = 1.2
    if not disabled and not pressed:
        style.shadow_color = Color(0.0, 0.015, 0.06, 0.34)
        style.shadow_size = 5
        style.shadow_offset = Vector2(0.0, 2.0)
    return style

func _button(root: Control, label: String, tl: Vector2, br: Vector2, action: Callable, color: Color) -> Button:
    var b := Button.new()
    b.text = label
    b.anchor_left = 1.0 if tl.x < 0.0 else 0.0
    b.anchor_right = 1.0 if br.x < 0.0 else 0.0
    b.anchor_top = 1.0 if tl.y < 0.0 else 0.0
    b.anchor_bottom = 1.0 if br.y < 0.0 else 0.0
    b.offset_left = tl.x
    b.offset_top = tl.y
    b.offset_right = br.x
    b.offset_bottom = br.y
    b.add_theme_font_size_override("font_size", 18)
    b.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
    b.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.72))
    b.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.62))
    b.add_theme_color_override("font_disabled_color", Color(0.58, 0.62, 0.7, 0.72))
    b.add_theme_color_override("font_outline_color", Color(0.015, 0.025, 0.07, 0.9))
    b.add_theme_constant_override("outline_size", 2)
    b.add_to_group("hud_mirror_buttons")
    b.set_meta("default_anchor_left", b.anchor_left)
    b.set_meta("default_anchor_right", b.anchor_right)
    b.set_meta("default_offset_left", b.offset_left)
    b.set_meta("default_offset_right", b.offset_right)
    var border := Color(0.72, 0.86, 1.0, 0.92)
    b.add_theme_stylebox_override("normal", _make_button_style(color, border))
    b.add_theme_stylebox_override("hover", _make_button_style(color.lightened(0.14), Color(1.0, 0.88, 0.52, 0.98)))
    b.add_theme_stylebox_override("pressed", _make_button_style(color.darkened(0.18), Color(1.0, 0.78, 0.38, 0.98), true))
    b.add_theme_stylebox_override("disabled", _make_button_style(color.darkened(0.38), Color(0.42, 0.48, 0.58, 0.55), false, true))
    b.add_theme_stylebox_override("focus", _make_button_style(color.lightened(0.08), Color(1.0, 0.84, 0.42, 1.0)))
    b.pressed.connect(action)
    root.add_child(b)
    return b
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        var viewport_width := get_viewport().get_visible_rect().size.x
        var viewport_height := get_viewport().get_visible_rect().size.y
        var left_handed := bool(SettingsManager.get_value("controls", "left_handed", false))
        var stick_rect := stick_base.get_global_rect().grow(24.0) if is_instance_valid(stick_base) else Rect2()
        if touch.pressed and stick_rect.has_point(touch.position) and touch.position.y > viewport_height * 0.55 and finger_id == -1:
            finger_id = touch.index
            _move_stick(touch.position)
        elif touch.pressed and not _is_touch_over_button(touch.position) and camera_finger_id == -1:
            var camera_side := touch.position.x < viewport_width * 0.55 if left_handed else touch.position.x > viewport_width * 0.45
            if camera_side:
                camera_finger_id = touch.index
                camera_last_position = touch.position
        elif not touch.pressed:
            if touch.index == finger_id:
                finger_id = -1
                stick_value = Vector2.ZERO
                _send_move(Vector2.ZERO)
                _reset_stick_knob()
            if touch.index == camera_finger_id:
                camera_finger_id = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == finger_id:
            _move_stick(drag.position)
        elif drag.index == camera_finger_id:
            var delta_position := drag.position - camera_last_position
            camera_last_position = drag.position
            if is_instance_valid(game.player):
                game.player.call("rotate_camera", delta_position)

func _is_touch_over_button(position: Vector2) -> bool:
    for control in get_tree().get_nodes_in_group("hud_mirror_buttons"):
        if is_instance_valid(control) and control is Control and control.get_global_rect().has_point(position):
            return true
    return false

func _reset_stick_knob() -> void:
    var center := stick_base.position + stick_base.size * stick_base.scale.x * 0.5
    stick_knob.position = center - stick_knob.size * stick_knob.scale.x * 0.5

func _on_hud_setting_changed(section: String, key: String, _value: Variant) -> void:
    if section == "controls" and key in ["left_handed", "button_scale"]:
        _apply_touch_layout()

func _apply_touch_layout() -> void:
    var viewport_width := get_viewport().get_visible_rect().size.x
    var left_handed := bool(SettingsManager.get_value("controls", "left_handed", false))
    var button_scale := clampf(float(SettingsManager.get_value("controls", "button_scale", 1.0)), 0.75, 1.5)
    for button in get_tree().get_nodes_in_group("hud_mirror_buttons"):
        if not is_instance_valid(button) or not button is Control:
            continue
        button.anchor_left = float(button.get_meta("default_anchor_left", 0.0))
        button.anchor_right = float(button.get_meta("default_anchor_right", 0.0))
        button.offset_left = float(button.get_meta("default_offset_left", 0.0))
        button.offset_right = float(button.get_meta("default_offset_right", 0.0))
        button.scale = Vector2.ONE
        if left_handed:
            var original_rect: Rect2 = (button as Control).get_global_rect()
            button.anchor_left = 0.0
            button.anchor_right = 0.0
            button.offset_left = viewport_width - original_rect.position.x - original_rect.size.x
            button.offset_right = viewport_width - original_rect.position.x
        button.scale = Vector2.ONE * button_scale
    if is_instance_valid(stick_base) and is_instance_valid(stick_knob):
        stick_base.position = Vector2(viewport_width - stick_default_position.x - stick_base.size.x, stick_default_position.y) if left_handed else stick_default_position
        stick_base.scale = Vector2.ONE * button_scale
        stick_knob.scale = Vector2.ONE * button_scale
        _reset_stick_knob()

func _move_stick(pos: Vector2) -> void:
    var scale := stick_base.scale.x
    var center := stick_base.position + stick_base.size * scale * 0.5
    var radius := 58.0 * scale
    stick_value = ((pos - center).limit_length(radius)) / radius
    stick_knob.position = center + stick_value * radius - stick_knob.size * stick_knob.scale.x * 0.5
    _send_move(stick_value)
func _send_move(value: Vector2) -> void:
    if is_instance_valid(game.player): game.player.set_move_input(value)
func _call_player(method: String, argument: Variant = null) -> void:
    if not is_instance_valid(game.player):
        return
    if argument == null:
        game.player.call(method)
    else:
        game.player.call(method, argument)
func set_status(hp: float, hp_max: float, cosmos: float, cosmos_max: float, skill_cd: float, burst_cd: float) -> void:
    if not is_instance_valid(status_label): return
    var profile: Dictionary = RPGState.profile
    var class_id := str(profile.get("class_id", "pegasus"))
    var class_label := str(RPGState.CLASS_DATA.get(class_id, {}).get("name", "天马座"))
    var cosmos_info: Dictionary = RPGState.get_cosmos_profile()
    status_label.text = str(profile.get("character_name", "星之战士")) + " · " + class_label + " Lv." + str(profile.get("level", 1)) + "  小宇宙 " + str(cosmos_info.get("level", 1)) + "/" + str(cosmos_info.get("max_level", 20)) + "  星币 " + str(profile.get("currency", 0))
    var is_tenkishi := class_id == "tenkishi"
    if is_instance_valid(flight_button):
        flight_button.visible = is_tenkishi
        flight_button.text = "收拢天翼" if is_tenkishi and is_instance_valid(game.player) and bool(game.player.get("tenkishi_flight_active")) else "天翼飞行"
    if is_instance_valid(flight_up_button):
        flight_up_button.visible = is_tenkishi
    if is_instance_valid(flight_down_button):
        flight_down_button.visible = is_tenkishi
    hp_bar.max_value = hp_max
    hp_bar.value = hp
    var health_ratio := clampf(hp / maxf(1.0, hp_max), 0.0, 1.0)
    if health_ratio <= 0.25:
        var warning_pulse := 0.78 + (sin(float(Time.get_ticks_msec()) * 0.012) * 0.5 + 0.5) * 0.32
        hp_bar.modulate = Color(1.0, warning_pulse, warning_pulse)
    elif health_ratio <= 0.5:
        hp_bar.modulate = Color(1.0, 0.86, 0.72)
    else:
        hp_bar.modulate = Color.WHITE
    cosmos_bar.max_value = cosmos_max
    cosmos_bar.value = cosmos
    if is_instance_valid(skill_button):
        var current_class_id := str(RPGState.profile.get("class_id", "pegasus"))
        var skill_name := str(SkillSystem.get_class_skill(current_class_id).get("name", "职业技能")) + " Lv." + str(SkillSystem.get_skill_level(current_class_id))
        skill_button.text = skill_name + "\n" + (str(snappedf(skill_cd, 0.1)) + "s" if skill_cd > 0.0 else "技能")
    if is_instance_valid(burst_button):
        burst_button.text = "小宇宙\n" + (str(snappedf(burst_cd, 0.1)) + "s" if burst_cd > 0.0 else "爆发")
func refresh_skill_slots() -> void:
    if skill_slot_buttons.is_empty():
        return
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var slots := SkillSystem.get_equipped_abilities(class_id)
    for i in range(mini(4, skill_slot_buttons.size())):
        var ability_id := str(slots[i])
        var ability := SkillSystem.get_ability_data(class_id, ability_id) if ability_id != "" else {}
        skill_slot_buttons[i].text = "技能 %d\n%s" % [i + 1, str(ability.get("name", "未装备"))]

func set_enemy_count(count: int) -> void:
    enemy_label.text = "剩余目标：" + str(count)

func set_quest_text(value: String) -> void:
    if is_instance_valid(quest_label):
        quest_label.text = value

func show_dialogue(data: Dictionary) -> void:
    var root := get_child(0) as Control
    if str(data.get("action", "")) in ["accept", "complete"]:
        _show_cinematic_dialogue(root, data)
    else:
        _show_compact_dialogue(root, data)

func _show_compact_dialogue(root: Control, data: Dictionary) -> void:
    if is_instance_valid(dialogue_panel):
        dialogue_panel.queue_free()
    dialogue_panel = Panel.new()
    dialogue_panel.anchor_left = 0.5
    dialogue_panel.anchor_right = 0.5
    dialogue_panel.anchor_top = 1.0
    dialogue_panel.anchor_bottom = 1.0
    dialogue_panel.offset_left = -300
    dialogue_panel.offset_right = 300
    dialogue_panel.offset_top = -250
    dialogue_panel.offset_bottom = -88
    _style_panel(dialogue_panel, Color(0.015, 0.025, 0.08, 0.96), Color(0.82, 0.62, 0.2))
    root.add_child(dialogue_panel)
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    box.add_theme_constant_override("separation", 8)
    dialogue_panel.add_child(box)
    var speaker := Label.new()
    speaker.text = str(data.get("speaker", "NPC"))
    speaker.add_theme_font_size_override("font_size", 20)
    box.add_child(speaker)
    var message := Label.new()
    message.text = str(data.get("text", ""))
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(message)
    var actions := HBoxContainer.new()
    var story_button := Button.new()
    story_button.text = "展开剧情"
    story_button.pressed.connect(func():
        _show_cinematic_dialogue(root, data)
    )
    actions.add_child(story_button)
    var close := Button.new()
    close.text = "继续"
    close.pressed.connect(func():
        if is_instance_valid(dialogue_panel):
            dialogue_panel.queue_free()
        dialogue_panel = null
    )
    actions.add_child(close)
    box.add_child(actions)

func _show_cinematic_dialogue(root: Control, data: Dictionary) -> void:
    if is_instance_valid(dialogue_panel):
        dialogue_panel.queue_free()
    dialogue_panel = Panel.new()
    dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _style_panel(dialogue_panel, Color(0.008, 0.012, 0.035, 0.98), Color(0.82, 0.62, 0.2))
    root.add_child(dialogue_panel)
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    box.add_theme_constant_override("separation", 20)
    dialogue_panel.add_child(box)
    var chapter := Label.new()
    chapter.text = "银河战争篇 · 银河竞技场"
    chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter.add_theme_font_size_override("font_size", 28)
    box.add_child(chapter)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(spacer)
    var speaker := Label.new()
    speaker.text = str(data.get("speaker", "NPC"))
    speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    speaker.add_theme_font_size_override("font_size", 30)
    speaker.add_theme_color_override("font_color", Color(1.0, 0.82, 0.38))
    box.add_child(speaker)
    var message := Label.new()
    message.text = str(data.get("text", ""))
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size", 23)
    message.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(message)
    var close := Button.new()
    close.text = "继续"
    close.custom_minimum_size = Vector2(180, 58)
    close.pressed.connect(func():
        if is_instance_valid(dialogue_panel):
            dialogue_panel.queue_free()
        dialogue_panel = null
    )
    box.add_child(close)
    var bottom_spacer := Control.new()
    bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(bottom_spacer)

func set_boss_status(hp: float, hp_max: float, boss_name: String = "训练 Boss", phase_two: bool = false) -> void:
    var visible_boss := hp_max > 1.0
    boss_label.visible = visible_boss
    boss_bar.visible = visible_boss
    if visible_boss:
        var health_ratio := clampf(hp / maxf(1.0, hp_max), 0.0, 1.0)
        var phase_text := " · 第二阶段" if phase_two else " · 第一阶段"
        boss_label.text = "%s%s  ·  %.0f%%" % [boss_name, phase_text, health_ratio * 100.0]
        boss_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.32) if phase_two else Color(1.0, 0.82, 0.48))
        boss_bar.max_value = hp_max
        boss_bar.value = clampf(hp, 0.0, hp_max)
func set_notice(message: String) -> void:
    if is_instance_valid(notice_label): notice_label.text = message
func _on_resize() -> void:
    stick_default_position = Vector2(42, get_viewport().get_visible_rect().size.y - 200.0)
    _apply_touch_layout()


func _open_combo_editor(root: Control) -> void:
    var class_id := str(RPGState.profile.get("class_id", "pegasus"))
    var popup := PopupPanel.new()
    popup.size = Vector2(620, 620)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(600, 590)
    popup.add_child(scroll)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    scroll.add_child(box)
    var title := Label.new()
    title.text = "自定义连招 · " + str(RPGState.CLASS_DATA.get(class_id, {}).get("name", class_id))
    title.add_theme_font_size_override("font_size", 23)
    box.add_child(title)
    var presets := ComboPresetManager.get_presets(class_id)
    var preset_picker := OptionButton.new()
    preset_picker.add_item("新建连招方案")
    for preset in presets:
        preset_picker.add_item(str(preset.get("name", "未命名连招")))
        preset_picker.set_item_metadata(preset_picker.item_count - 1, str(preset.get("id", "")))
    box.add_child(preset_picker)
    var name_input := LineEdit.new()
    name_input.placeholder_text = "连招名称（最多24字）"
    name_input.text = "我的连招"
    box.add_child(name_input)
    var mode_picker := OptionButton.new()
    for mode in ComboPresetManager.VALID_MODES:
        mode_picker.add_item(mode)
    box.add_child(mode_picker)
    var window_picker := SpinBox.new()
    window_picker.min_value = ComboPresetManager.MIN_WINDOW
    window_picker.max_value = ComboPresetManager.MAX_WINDOW
    window_picker.step = 0.05
    window_picker.value = 0.65
    box.add_child(_gm_labeled_row("技能衔接窗口（秒）", window_picker))
    var available := OptionButton.new()
    available.add_item("选择要加入的动作 / 已学习技能")
    for action_id in ComboPresetManager.BUILTIN_STEPS:
        available.add_item("动作：" + action_id)
        available.set_item_metadata(available.item_count - 1, action_id)
    for ability in SkillSystem.get_ability_catalog(class_id):
        var ability_id := str(ability.get("id", ""))
        if SkillSystem.is_ability_learned(class_id, ability_id):
            available.add_item(str(ability.get("name", ability_id)))
            available.set_item_metadata(available.item_count - 1, ability_id)
    box.add_child(available)
    var steps: Array[String] = []
    var step_list := ItemList.new()
    step_list.custom_minimum_size = Vector2(560, 190)
    step_list.select_mode = ItemList.SELECT_SINGLE
    box.add_child(step_list)
    var refresh_steps := func() -> void:
        step_list.clear()
        for i in range(steps.size()):
            step_list.add_item("%d. %s" % [i + 1, steps[i]])
    var edit_row := HBoxContainer.new()
    var add_step := Button.new()
    add_step.text = "添加动作"
    add_step.pressed.connect(func():
        if available.selected <= 0 or available.get_item_metadata(available.selected) == null:
            set_notice("请先选择一个动作或已学习技能")
            return
        var chosen := str(available.get_item_metadata(available.selected))
        if steps.size() >= ComboPresetManager.MAX_STEPS or steps.has(chosen):
            set_notice("连招最多8步，且不能重复同一动作")
            return
        steps.append(chosen)
        refresh_steps.call()
    )
    edit_row.add_child(add_step)
    var up := Button.new()
    up.text = "上移"
    up.pressed.connect(func():
        var selected := step_list.get_selected_items()
        if selected.is_empty() or selected[0] <= 0:
            return
        var index := selected[0]
        var temp := steps[index - 1]
        steps[index - 1] = steps[index]
        steps[index] = temp
        refresh_steps.call()
        step_list.select(index - 1)
    )
    edit_row.add_child(up)
    var down := Button.new()
    down.text = "下移"
    down.pressed.connect(func():
        var selected := step_list.get_selected_items()
        if selected.is_empty() or selected[0] >= steps.size() - 1:
            return
        var index := selected[0]
        var temp := steps[index + 1]
        steps[index + 1] = steps[index]
        steps[index] = temp
        refresh_steps.call()
        step_list.select(index + 1)
    )
    edit_row.add_child(down)
    var remove := Button.new()
    remove.text = "删除选中"
    remove.pressed.connect(func():
        var selected := step_list.get_selected_items()
        if selected.is_empty():
            return
        steps.remove_at(selected[0])
        refresh_steps.call()
    )
    edit_row.add_child(remove)
    box.add_child(edit_row)
    preset_picker.item_selected.connect(func(index: int):
        steps.clear()
        if index > 0:
            var preset_id := str(preset_picker.get_item_metadata(index))
            for preset in ComboPresetManager.get_presets(class_id):
                if str(preset.get("id", "")) == preset_id:
                    name_input.text = str(preset.get("name", ""))
                    steps.assign(preset.get("steps", []))
                    var mode_index := ComboPresetManager.VALID_MODES.find(str(preset.get("trigger_mode", "")))
                    if mode_index >= 0:
                        mode_picker.select(mode_index)
                    window_picker.value = float(preset.get("input_window", 0.65))
                    break
        refresh_steps.call()
    )
    var save := Button.new()
    save.text = "保存连招方案"
    save.pressed.connect(func():
        if steps.is_empty():
            set_notice("请至少添加一个连招步骤")
            return
        var selected_index := preset_picker.selected
        var preset_id := str(preset_picker.get_item_metadata(selected_index)) if selected_index > 0 else "custom_" + str(Time.get_ticks_msec())
        var ok := ComboPresetManager.save_preset(class_id, preset_id, name_input.text, steps, mode_picker.get_item_text(mode_picker.selected), window_picker.value)
        set_notice("连招方案已保存" if ok else "保存失败：检查方案数量、技能解锁和步骤设置")
        if ok:
            popup.queue_free()
    )
    box.add_child(save)
    var activate := Button.new()
    activate.text = "设为当前职业使用方案"
    activate.pressed.connect(func():
        if preset_picker.selected <= 0:
            set_notice("请先选择已保存的方案")
            return
        var preset_id := str(preset_picker.get_item_metadata(preset_picker.selected))
        var ok := ComboPresetManager.set_active_preset(class_id, preset_id)
        set_notice("当前连招方案已切换" if ok else "切换失败")
        popup.queue_free()
    )
    box.add_child(activate)
    var close := Button.new()
    close.text = "关闭"
    close.pressed.connect(func(): popup.queue_free())
    box.add_child(close)
    root.add_child(popup)
    popup.popup_centered()

func _open_daily_boss(root: Control) -> void:
    var state: Dictionary = DailyBossManager.get_state()
    var popup := PopupPanel.new()
    popup.size = Vector2(480, 360)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    popup.add_child(box)
    var title := Label.new()
    title.text = "每日首领挑战"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 26)
    box.add_child(title)
    var boss_name := Label.new()
    boss_name.text = str(state.get("boss_name", "今日首领"))
    boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_name.add_theme_font_size_override("font_size", 22)
    box.add_child(boss_name)
    var remaining := int(state.get("seconds_until_refresh", 0))
    var countdown := Label.new()
    countdown.text = "每日 05:00 刷新    下次刷新倒计时：%02d:%02d:%02d" % [remaining / 3600, (remaining % 3600) / 60, remaining % 60]
    countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(countdown)
    var status := Label.new()
    if bool(state.get("reward_claimed", false)):
        status.text = "今日挑战已完成，奖励已领取"
    elif bool(state.get("defeated", false)):
        status.text = "首领已击败，可以领取今日奖励"
    else:
        status.text = "尚未击败今日首领"
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(status)
    var challenge := Button.new()
    challenge.text = "挑战今日首领"
    challenge.disabled = not DailyBossManager.can_challenge()
    challenge.custom_minimum_size = Vector2(220, 48)
    challenge.pressed.connect(func():
        popup.queue_free()
        game.call("start_daily_boss_challenge")
    )
    box.add_child(challenge)
    var claim := Button.new()
    claim.text = "领取每日奖励"
    claim.disabled = not bool(state.get("defeated", false)) or bool(state.get("reward_claimed", false))
    claim.custom_minimum_size = Vector2(220, 48)
    claim.pressed.connect(func():
        var result: Dictionary = DailyBossManager.claim_reward()
        if bool(result.get("success", false)):
            set_notice("每日奖励已领取：经验 %d，星币 %d" % [int(result.get("exp", 0)), int(result.get("coins", 0))])
        else:
            set_notice(str(result.get("reason", "领取失败")))
        popup.queue_free()
        _open_daily_boss(root)
    )
    box.add_child(claim)
    var close := Button.new()
    close.text = "关闭"
    close.pressed.connect(func(): popup.queue_free())
    box.add_child(close)
    root.add_child(popup)
    popup.popup_centered()

func _open_shop(root: Control) -> void:
    var popup := PopupPanel.new()
    popup.size = Vector2(430, 430)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    popup.add_child(box)
    var title := Label.new()
    title.text = "离线商城  |  星币：" + str(RPGState.profile.get("currency", 0))
    title.add_theme_font_size_override("font_size", 22)
    box.add_child(title)
    for item_id in ["bronze_helmet", "bronze_chest", "bronze_greaves", "cosmos_potion"]:
        var item: Dictionary = RPGState.ITEM_DATA[item_id]
        var button := Button.new()
        button.text = str(item["name"]) + "  -  " + str(item["price"]) + " 星币"
        var selected_id: String = item_id
        var selected_name: String = str(item["name"])
        button.pressed.connect(func():
            var success: bool = RPGState.buy_item(selected_id)
            set_notice("购买成功：" + selected_name if success else "星币不足，无法购买")
            popup.queue_free()
        )
        box.add_child(button)
    var close := Button.new()
    close.text = "关闭"
    close.pressed.connect(func(): popup.queue_free())
    box.add_child(close)
    root.add_child(popup)
    popup.popup_centered()

func _open_character(root: Control) -> void:
    var popup := PopupPanel.new()
    popup.size = Vector2(560, 620)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(540, 600)
    popup.add_child(scroll)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    scroll.add_child(box)

    var title := Label.new()
    title.text = "角色成长、职业、装备与存档"
    title.add_theme_font_size_override("font_size", 23)
    box.add_child(title)

    var profile: Dictionary = RPGState.profile
    var current_class := str(profile.get("class_id", "pegasus"))
    var class_picker := OptionButton.new()
    var class_index := 0
    var index := 0
    for class_id in RPGState.CLASS_DATA:
        class_picker.add_item(str(RPGState.CLASS_DATA[class_id]["name"]))
        class_picker.set_item_metadata(index, class_id)
        if class_id == current_class:
            class_index = index
        index += 1
    class_picker.select(class_index)
    class_picker.item_selected.connect(func(selected_index: int):
        var chosen_id: String = str(class_picker.get_item_metadata(selected_index))
        RPGState.select_class(chosen_id)
        game.call("refresh_player_stats")
        set_notice("已切换职业：" + str(RPGState.CLASS_DATA[chosen_id]["name"]))
        popup.queue_free()
    )
    box.add_child(class_picker)

    var stats: Dictionary = RPGState.get_combat_stats()
    var class_label := str(RPGState.CLASS_DATA.get(current_class, {}).get("name", "天马座"))
    var cosmos_info: Dictionary = RPGState.get_cosmos_profile()
    var info := Label.new()
    info.text = "%s  Lv.%d    经验 %d/%d    星币 %d\n生命 %.0f    攻击 %.0f    防御 %.0f    速度 %.0f\n小宇宙：%s Lv.%d/%d（%s）" % [class_label, int(profile.get("level",1)), int(profile.get("exp",0)), RPGState.exp_to_next_level(), int(profile.get("currency",0)), stats["max_health"], stats["attack"], stats["defense"], stats["speed"], "神明" if cosmos_info.get("divine", false) else "凡人", cosmos_info.get("level",1), cosmos_info.get("max_level",20), cosmos_info.get("rank","初识小宇宙")]
    box.add_child(info)

    var upgrade := Button.new()
    upgrade.text = "提升小宇宙等级（%d/%d，消耗 %d 星币）" % [cosmos_info.get("level", 1), cosmos_info.get("max_level", 20), cosmos_info.get("upgrade_cost", 250)]
    upgrade.pressed.connect(func():
        var success: bool = RPGState.upgrade_cosmos()
        if success:
            game.call("refresh_player_stats")
        set_notice("小宇宙培养成功" if success else "星币不足或已达到培养上限")
        popup.queue_free()
    )
    box.add_child(upgrade)
    var skill_upgrade := Button.new()
    var current_class_id := str(profile.get("class_id","pegasus"))
    skill_upgrade.text = "升级职业技能（当前 Lv.%d，消耗 %d 星币）" % [SkillSystem.get_skill_level(current_class_id), SkillSystem.get_skill_level(current_class_id)*350]
    skill_upgrade.pressed.connect(func():
        var success: bool = SkillSystem.upgrade_skill(current_class_id)
        set_notice("职业技能升级成功" if success else "星币不足或技能已达 10 级")
        popup.queue_free()
    )
    box.add_child(skill_upgrade)
    var skill_book_title := Label.new()
    skill_book_title.text = "职业技能图鉴 · " + str(SkillSystem.get_class_skill(current_class_id).get("resource_name", "小宇宙"))
    skill_book_title.add_theme_font_size_override("font_size", 18)
    box.add_child(skill_book_title)
    var class_skill_data: Dictionary = SkillSystem.get_class_skill(current_class_id)
    var passive_data: Dictionary = class_skill_data.get("passive", {})
    var passive_label := Label.new()
    passive_label.text = "职业被动【%s】：%s" % [str(passive_data.get("name", "职业被动")), str(passive_data.get("description", ""))]
    passive_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(passive_label)
    var skill_points_label := Label.new()
    skill_points_label.text = "可用技能点：%d（角色每升 1 级获得 1 点）" % int(profile.get("skill_points", 0))
    box.add_child(skill_points_label)
    var selected_branch := SkillSystem.get_selected_branch(current_class_id)
    var branch_picker := OptionButton.new()
    branch_picker.add_item("选择专精分支（进阶技能需要先选）")
    for branch in SkillSystem.get_skill_branches(current_class_id):
        if str(branch) != "基础技能":
            branch_picker.add_item(str(branch))
    var branch_button := Button.new()
    branch_button.text = "确认专精分支"
    branch_button.disabled = selected_branch != ""
    branch_button.pressed.connect(func():
        if branch_picker.selected > 0:
            var branch_name := branch_picker.get_item_text(branch_picker.selected)
            var ok := SkillSystem.choose_skill_branch(current_class_id, branch_name)
            set_notice("已选择专精：" + branch_name if ok else "专精已锁定，无法更改")
            popup.queue_free()
    )
    box.add_child(branch_picker)
    box.add_child(branch_button)
    if selected_branch != "":
        var branch_info := Label.new()
        branch_info.text = "当前专精：" + selected_branch + "（本职业专精选择后锁定）"
        box.add_child(branch_info)
    var reset_tree := Button.new()
    reset_tree.text = "重置本职业技能树（消耗 500 星币，返还技能点）"
    reset_tree.pressed.connect(func():
        var ok := SkillSystem.reset_skill_tree(current_class_id)
        set_notice("技能树已重置" if ok else "需要 500 星币")
        popup.queue_free()
    )
    box.add_child(reset_tree)
    for ability in SkillSystem.get_ability_catalog(current_class_id):
        var ability_id := str(ability.get("id", ""))
        var ability_branch := str(ability.get("branch", "基础技能"))
        var learned := SkillSystem.is_ability_learned(current_class_id, ability_id)
        var level_ok := int(profile.get("level", 1)) >= int(ability.get("unlock_level", 1))
        var branch_ok := ability_branch == "基础技能" or selected_branch == ability_branch
        var row := HBoxContainer.new()
        var ability_label := Label.new()
        ability_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        ability_label.custom_minimum_size.x = 290
        ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ability_label.text = "%s [%s] Lv.%d %s\n%s" % [str(ability.get("name", "技能")), ability_branch, int(ability.get("unlock_level", 1)), ("已学习" if learned else ("可学习" if level_ok and branch_ok else "未解锁/未选分支")), str(ability.get("description", ""))]
        row.add_child(ability_label)
        var learn_button := Button.new()
        learn_button.text = "学习"
        learn_button.disabled = learned or not level_ok or not branch_ok or int(profile.get("skill_points", 0)) < 1
        learn_button.pressed.connect(func():
            var ok := SkillSystem.learn_ability(current_class_id, ability_id)
            set_notice("技能学习成功" if ok else "技能点、等级或专精条件不足")
            popup.queue_free()
        )
        row.add_child(learn_button)
        var slot_picker := OptionButton.new()
        for slot_number in range(1, 5):
            slot_picker.add_item("栏位 %d" % slot_number)
        row.add_child(slot_picker)
        var equip_button := Button.new()
        equip_button.text = "装备"
        equip_button.disabled = not learned
        equip_button.pressed.connect(func():
            var target_slot := slot_picker.selected
            var ok := SkillSystem.equip_ability(current_class_id, ability_id, target_slot)
            set_notice("已装备到技能栏第 %d 格" % (target_slot + 1) if ok else "请先学习技能")
            popup.queue_free()
        )
        row.add_child(equip_button)
        box.add_child(row)

    var armor_info := Label.new()
    var armor_state: Dictionary = ArmorSystem.get_state()
    var armor_durability: Dictionary = armor_state.get("durability",{})
    armor_info.text = "当前圣衣：" + ArmorSystem.get_current_stage_name() + "\n耐久：头盔 %d / 胸甲 %d / 护腕 %d / 腰甲 %d / 腿甲 %d" % [int(armor_durability.get("head",100)),int(armor_durability.get("chest",100)),int(armor_durability.get("arms",100)),int(armor_durability.get("waist",100)),int(armor_durability.get("legs",100))]
    box.add_child(armor_info)

    var armor_condition := ArmorSystem.get_condition_ratio()
    var condition_label := Label.new()
    condition_label.text = "圣衣完整度：%d%% · %s" % [roundi(armor_condition * 100.0), "状态完好" if armor_condition >= 0.8 else ("需要修复" if armor_condition > 0.25 else "严重破损")]
    condition_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.68) if armor_condition >= 0.8 else (Color(1.0, 0.78, 0.32) if armor_condition > 0.25 else Color(1.0, 0.38, 0.32)))
    box.add_child(condition_label)
    var armor_part_grid := GridContainer.new()
    armor_part_grid.columns = 2
    armor_part_grid.add_theme_constant_override("h_separation", 12)
    armor_part_grid.add_theme_constant_override("v_separation", 6)
    for armor_part in ArmorSystem.PARTS:
        var part_row := HBoxContainer.new()
        var part_label := Label.new()
        part_label.text = str(ArmorSystem.PART_NAMES.get(armor_part, armor_part))
        part_label.custom_minimum_size = Vector2(58, 26)
        part_row.add_child(part_label)
        var part_bar := ProgressBar.new()
        part_bar.custom_minimum_size = Vector2(132, 22)
        part_bar.max_value = 100
        part_bar.value = float(armor_durability.get(armor_part, 100))
        part_bar.show_percentage = true
        part_row.add_child(part_bar)
        armor_part_grid.add_child(part_row)
    box.add_child(armor_part_grid)

    var armor_section := Label.new()
    armor_section.text = "圣衣成长与形态解锁"
    armor_section.add_theme_font_size_override("font_size", 18)
    box.add_child(armor_section)
    var unlocked_armor_stages: Array = armor_state.get("unlocked_stages", ["bronze"])
    for raw_stage_id in ArmorSystem.get_stage_ids():
        var stage_id := str(raw_stage_id)
        var stage_data: Dictionary = ArmorSystem.STAGES[stage_id]
        var stage_unlocked := stage_id in unlocked_armor_stages
        var stage_current := str(armor_state.get("current_stage", "bronze")) == stage_id
        var stage_row := HBoxContainer.new()
        var stage_label := Label.new()
        stage_label.text = str(stage_data.get("name", stage_id))
        stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        stage_row.add_child(stage_label)
        var stage_button := Button.new()
        stage_button.text = "当前穿戴" if stage_current else ("穿戴" if stage_unlocked else "解锁（等级/剧情）")
        stage_button.disabled = stage_current
        var selected_stage_id := stage_id
        var selected_stage_unlocked := stage_unlocked
        stage_button.pressed.connect(func():
            var ok := ArmorSystem.equip_stage(selected_stage_id) if selected_stage_unlocked else ArmorSystem.unlock_stage(selected_stage_id)
            if ok:
                game.call("refresh_player_stats")
            set_notice(("已穿戴：" if selected_stage_unlocked else "已解锁：") + str(ArmorSystem.STAGES[selected_stage_id].get("name", selected_stage_id)) if ok else "尚未满足该圣衣的等级或剧情解锁条件")
            popup.queue_free()
        )
        stage_row.add_child(stage_button)
        box.add_child(stage_row)

    var armor_actions := HBoxContainer.new()
    var repair_button := Button.new()
    repair_button.text = "修复全部部件"
    repair_button.pressed.connect(func():
        var ok := ArmorSystem.repair_all()
        if ok:
            game.call("refresh_player_stats")
        set_notice("圣衣部件已全部修复" if ok else "无需修复或星币不足")
        popup.queue_free()
    )
    armor_actions.add_child(repair_button)
    var awaken_button := Button.new()
    awaken_button.text = "圣衣觉醒（满足条件时）"
    awaken_button.disabled = bool(armor_state.get("awakened", false)) or not str(armor_state.get("current_stage", "bronze")) in ["gold", "god_cloth", "god_armor"]
    awaken_button.pressed.connect(func():
        var ok := ArmorSystem.awaken_current()
        if ok:
            game.call("refresh_player_stats")
        set_notice("圣衣觉醒成功" if ok else "当前形态不可觉醒或星币不足")
        popup.queue_free()
    )
    armor_actions.add_child(awaken_button)
    box.add_child(armor_actions)

    var armor_levels: Dictionary = armor_state.get("levels", {})
    var armor_upgrade_title := Label.new()
    armor_upgrade_title.text = "圣衣部件强化（每件最高 +10）"
    box.add_child(armor_upgrade_title)
    for raw_part in ArmorSystem.PARTS:
        var part_id := str(raw_part)
        var part_level := int(armor_levels.get(part_id, 0))
        var part_row := HBoxContainer.new()
        var part_label := Label.new()
        part_label.text = str(ArmorSystem.PART_NAMES.get(part_id, part_id)) + " +" + str(part_level)
        part_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        part_row.add_child(part_label)
        var part_button := Button.new()
        part_button.text = "强化（%d 星币）" % ((part_level + 1) * 180)
        part_button.disabled = part_level >= 10 or int(profile.get("currency", 0)) < (part_level + 1) * 180
        part_button.pressed.connect(func():
            var ok := ArmorSystem.enhance_part(part_id)
            if ok:
                game.call("refresh_player_stats")
            set_notice("圣衣部件强化成功" if ok else "星币不足或部件已达强化上限")
            popup.queue_free()
        )
        part_row.add_child(part_button)
        box.add_child(part_row)

    var inventory_title := Label.new()
    inventory_title.text = "背包与装备（点击装备即可穿戴）"
    inventory_title.add_theme_font_size_override("font_size", 19)
    box.add_child(inventory_title)
    var inventory: Dictionary = profile.get("inventory", {})
    if inventory.is_empty():
        var empty_label := Label.new()
        empty_label.text = "背包暂时为空"
        box.add_child(empty_label)
    else:
        for item_id in inventory:
            var item_count: int = int(inventory[item_id])
            if item_count <= 0 or not RPGState.ITEM_DATA.has(item_id):
                continue
            var item: Dictionary = RPGState.ITEM_DATA[item_id]
            var item_slot: String = str(item.get("slot", ""))
            var item_name: String = str(item.get("name", item_id))
            var selected_item_id: String = str(item_id)
            var item_button := Button.new()
            if item_slot == "consumable":
                item_button.text = "使用：" + item_name + " ×" + str(item_count)
                item_button.pressed.connect(func():
                    var used: bool = RPGState.use_item(selected_item_id)
                    if used and is_instance_valid(game.player):
                        game.player.cosmos = minf(game.player.max_cosmos, game.player.cosmos + 45.0)
                    set_notice("已使用：" + item_name if used else "无法使用该物品")
                    popup.queue_free()
                )
            else:
                item_button.text = "穿戴：" + item_name + " ×" + str(item_count)
                item_button.pressed.connect(func():
                    var equipped: bool = RPGState.equip_item(selected_item_id)
                    if equipped:
                        game.call("refresh_player_stats")
                    set_notice("装备成功：" + item_name if equipped else "装备失败")
                    popup.queue_free()
                )
            box.add_child(item_button)

    var equipment_label := Label.new()
    equipment_label.text = "当前装备：" + str(profile.get("equipment", {}))
    box.add_child(equipment_label)
    var equipped_items: Dictionary = profile.get("equipment", {})
    for equipment_slot in equipped_items:
        var equipped_id: String = str(equipped_items[equipment_slot])
        if equipped_id == "":
            continue
        var selected_slot: String = str(equipment_slot)
        var enhance_button := Button.new()
        var enhance_level: int = int(profile.get("equipment_levels", {}).get(equipped_id, 0))
        enhance_button.text = "强化 " + str(RPGState.ITEM_DATA.get(equipped_id, {}).get("name", equipped_id)) + "（当前 +" + str(enhance_level) + "）"
        enhance_button.pressed.connect(func():
            var success: bool = RPGState.enhance_equipment(selected_slot)
            game.call("refresh_player_stats")
            set_notice("装备强化成功" if success else "星币不足或已达到强化上限")
            popup.queue_free()
        )
        box.add_child(enhance_button)

    var save_title := Label.new()
    save_title.text = "本地存档管理（3 个独立存档槽）"
    save_title.add_theme_font_size_override("font_size", 19)
    box.add_child(save_title)
    for slot in [1, 2, 3]:
        var slot_id: int = slot
        var row := HBoxContainer.new()
        var save_button := Button.new()
        save_button.text = "槽%d 保存当前角色" % slot_id if slot_id == RPGState.active_slot else "槽%d（需先读取）" % slot_id
        save_button.disabled = slot_id != RPGState.active_slot
        save_button.pressed.connect(func():
            set_notice("当前角色存档已安全保存" if RPGState.save_slot(slot_id) else "保存失败：只能保存当前已读取的存档槽")
            popup.queue_free()
        )
        row.add_child(save_button)
        var load_button := Button.new()
        load_button.text = "读取"
        load_button.pressed.connect(func():
            var loaded: bool = RPGState.load_slot(slot_id)
            if loaded:
                game.call("refresh_player_stats")
            set_notice("存档读取成功" if loaded else "该槽没有有效存档")
            popup.queue_free()
        )
        row.add_child(load_button)
        var backup_button := Button.new()
        backup_button.text = "备份"
        backup_button.pressed.connect(func():
            set_notice("备份成功" if RPGState.backup_slot(slot_id) else "备份失败")
            popup.queue_free()
        )
        row.add_child(backup_button)
        var restore_button := Button.new()
        restore_button.text = "恢复备份"
        restore_button.pressed.connect(func():
            var restored: bool = RPGState.restore_backup(slot_id)
            if restored:
                game.call("refresh_player_stats")
            set_notice("备份恢复成功" if restored else "没有可用备份")
            popup.queue_free()
        )
        row.add_child(restore_button)
        box.add_child(row)

    var close := Button.new()
    close.text = "关闭"
    close.pressed.connect(func(): popup.queue_free())
    box.add_child(close)
    root.add_child(popup)
    popup.popup_centered()

func _open_gm(root: Control) -> void:
    if not GMManager.enabled:
        set_notice("GM 管理当前已关闭")
        return
    var popup := PopupPanel.new()
    popup.size = Vector2(500, 560)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(480, 540)
    popup.add_child(scroll)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    scroll.add_child(box)
    var title := Label.new()
    title.text = "本地 GM 管理面板"
    title.add_theme_font_size_override("font_size", 24)
    box.add_child(title)
    var warning := Label.new()
    warning.text = "仅本机离线调试使用；修改会写入当前本地存档。"
    warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(warning)
    var coin_input := SpinBox.new()
    coin_input.min_value = 1
    coin_input.max_value = 100000000
    coin_input.value = 10000
    coin_input.step = 100
    box.add_child(_gm_labeled_row("增加星币", coin_input))
    var coin_button := Button.new()
    coin_button.text = "执行：增加星币"
    coin_button.pressed.connect(func():
        var ok: bool = GMManager.grant_currency(int(coin_input.value))
        set_notice("星币已增加" if ok else "操作失败")
        popup.queue_free()
    )
    box.add_child(coin_button)
    var exp_input := SpinBox.new()
    exp_input.min_value = 1
    exp_input.max_value = 10000000
    exp_input.value = 5000
    exp_input.step = 100
    box.add_child(_gm_labeled_row("增加经验", exp_input))
    var exp_button := Button.new()
    exp_button.text = "执行：增加经验"
    exp_button.pressed.connect(func():
        var ok: bool = GMManager.grant_exp(int(exp_input.value))
        if ok: game.call("refresh_player_stats")
        set_notice("经验已增加" if ok else "操作失败")
        popup.queue_free()
    )
    box.add_child(exp_button)
    var level_input := SpinBox.new()
    level_input.min_value = 1
    level_input.max_value = RPGState.MAX_LEVEL
    level_input.value = int(RPGState.profile.get("level", 1))
    box.add_child(_gm_labeled_row("设置等级（1-100）", level_input))
    var level_button := Button.new()
    level_button.text = "执行：设置等级"
    level_button.pressed.connect(func():
        var ok: bool = GMManager.set_level(int(level_input.value))
        if ok: game.call("refresh_player_stats")
        set_notice("等级设置完成" if ok else "等级设置失败")
        popup.queue_free()
    )
    box.add_child(level_button)
    var heal_button := Button.new()
    heal_button.text = "恢复角色生命与小宇宙"
    heal_button.pressed.connect(func():
        if is_instance_valid(game.player):
            game.player.health = game.player.max_health
            game.player.cosmos = game.player.max_cosmos
        GMManager.restore_player()
        set_notice("角色状态已恢复")
        popup.queue_free()
    )
    box.add_child(heal_button)
    var items_button := Button.new()
    items_button.text = "发放全部已定义物品"
    items_button.pressed.connect(func():
        GMManager.grant_all_known_items()
        set_notice("已发放物品；可在角色背包查看")
        popup.queue_free()
    )
    box.add_child(items_button)
    var armor_title := Label.new()
    armor_title.text = "圣衣管理"
    armor_title.add_theme_font_size_override("font_size", 20)
    box.add_child(armor_title)
    var armor_state: Dictionary = ArmorSystem.get_state()
    var stage_picker := OptionButton.new()
    var stage_ids := ["bronze","silver","gold","sea_scale","surplice","god_cloth","god_armor"]
    var stage_names := ["青铜圣衣","白银圣衣","黄金圣衣","海界鳞衣","冥衣","神圣衣","主神圣衣"]
    for i in range(stage_ids.size()):
        stage_picker.add_item(stage_names[i])
        stage_picker.set_item_metadata(i,stage_ids[i])
        if stage_ids[i] == str(armor_state.get("current_stage","bronze")):
            stage_picker.select(i)
    box.add_child(_gm_labeled_row("当前圣衣阶段",stage_picker))
    var equip_stage_button := Button.new()
    equip_stage_button.text = "切换到选定圣衣"
    equip_stage_button.pressed.connect(func():
        var stage_id: String = str(stage_picker.get_item_metadata(stage_picker.selected))
        var ok: bool = ArmorSystem.equip_stage(stage_id)
        game.call("refresh_player_stats")
        set_notice("已切换圣衣：" + str(stage_picker.get_item_text(stage_picker.selected)) if ok else "该圣衣尚未解锁")
        popup.queue_free()
    )
    box.add_child(equip_stage_button)
    var unlock_armor_button := Button.new()
    unlock_armor_button.text = "GM：解锁全部圣衣阶段"
    unlock_armor_button.pressed.connect(func():
        GMManager.grant_all_armor_stages()
        set_notice("全部圣衣阶段已解锁")
        popup.queue_free()
    )
    box.add_child(unlock_armor_button)
    var repair_button := Button.new()
    repair_button.text = "修复全部圣衣部件（消耗星币）"
    repair_button.pressed.connect(func():
        var ok: bool = GMManager.repair_armor()
        game.call("refresh_player_stats")
        set_notice("圣衣修复完成" if ok else "无需修复或星币不足")
        popup.queue_free()
    )
    box.add_child(repair_button)
    for part_id in ["head","chest","arms","waist","legs"]:
        var selected_part: String = part_id
        var part_button := Button.new()
        part_button.text = "强化圣衣：" + str({"head":"头盔","chest":"胸甲","arms":"护腕","waist":"腰甲","legs":"腿甲"}[part_id])
        part_button.pressed.connect(func():
            var ok: bool = GMManager.enhance_armor_part(selected_part)
            game.call("refresh_player_stats")
            set_notice("圣衣部件强化成功" if ok else "强化失败：星币不足或已达上限")
            popup.queue_free()
        )
        box.add_child(part_button)
    var awaken_button := Button.new()
    awaken_button.text = "圣衣觉醒（黄金/神圣/主神圣衣）"
    awaken_button.pressed.connect(func():
        var ok: bool = GMManager.awaken_armor()
        game.call("refresh_player_stats")
        set_notice("圣衣觉醒成功" if ok else "当前圣衣无法觉醒或条件不足")
        popup.queue_free()
    )
    box.add_child(awaken_button)
    var skill_title := Label.new()
    skill_title.text = "职业技能成长"
    skill_title.add_theme_font_size_override("font_size", 20)
    box.add_child(skill_title)
    var skill_level_input := SpinBox.new()
    skill_level_input.min_value = 1
    skill_level_input.max_value = 10
    skill_level_input.value = SkillSystem.get_skill_level(str(RPGState.profile.get("class_id","pegasus")))
    box.add_child(_gm_labeled_row("当前职业技能等级",skill_level_input))
    var set_skill_button := Button.new()
    set_skill_button.text = "GM：设置当前职业技能等级"
    set_skill_button.pressed.connect(func():
        var class_id := str(RPGState.profile.get("class_id","pegasus"))
        var ok: bool = GMManager.set_skill_level(class_id,int(skill_level_input.value))
        set_notice("职业技能等级已更新" if ok else "技能等级设置失败")
        popup.queue_free()
    )
    box.add_child(set_skill_button)
    var unlock_collection_button := Button.new()
    unlock_collection_button.text = "GM：解锁全部伙伴、宠物与坐骑"
    unlock_collection_button.pressed.connect(func():
        GMManager.unlock_all_collections()
        game.call("refresh_player_stats")
        set_notice("伙伴、宠物和坐骑图鉴已全部解锁")
        popup.queue_free()
    )
    box.add_child(unlock_collection_button)
    var reset_button := Button.new()
    reset_button.text = "重置当前任务（危险操作）"
    reset_button.pressed.connect(func():
        var confirm := ConfirmationDialog.new()
        confirm.dialog_text = "确定重置当前任务进度吗？此操作会覆盖本地任务记录。"
        confirm.confirmed.connect(func():
            GMManager.reset_local_quest()
            set_notice("当前任务已重置")
            popup.queue_free()
        )
        root.add_child(confirm)
        confirm.popup_centered()
    )
    box.add_child(reset_button)
    var close := Button.new()
    close.text = "关闭 GM 面板"
    close.pressed.connect(func(): popup.queue_free())
    box.add_child(close)
    root.add_child(popup)
    popup.popup_centered()

func _gm_labeled_row(caption: String, control: Control) -> Control:
    var row := HBoxContainer.new()
    var label := Label.new()
    label.text = caption
    label.custom_minimum_size = Vector2(190, 36)
    row.add_child(label)
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(control)
    return row

func _open_collection(root: Control) -> void:
    var popup := PopupPanel.new()
    popup.size = Vector2(560, 560)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(540, 540)
    popup.add_child(scroll)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    scroll.add_child(box)
    var title := Label.new()
    title.text = "伙伴 · 宠物 · 坐骑 · 成就图鉴"
    title.add_theme_font_size_override("font_size", 22)
    box.add_child(title)
    var data: Dictionary = CollectionSystem.get_state()
    var defeat_label := Label.new()
    defeat_label.text = "累计击败敌人：" + str(data.get("enemy_defeats",0)) + "    Boss：" + str(data.get("boss_defeats",0))
    box.add_child(defeat_label)
    var sections := [
        {"kind":"companion","title":"伙伴","catalog":CollectionSystem.COMPANIONS,"owned":data.get("companions",[]),"active":data.get("active_companion","")},
        {"kind":"pet","title":"宠物","catalog":CollectionSystem.PETS,"owned":data.get("pets",[]),"active":data.get("active_pet","")},
        {"kind":"mount","title":"坐骑","catalog":CollectionSystem.MOUNTS,"owned":data.get("mounts",[]),"active":data.get("active_mount","")}
    ]
    for section in sections:
        var heading := Label.new()
        heading.text = str(section["title"])
        heading.add_theme_font_size_override("font_size",19)
        box.add_child(heading)
        var catalog: Dictionary = section["catalog"]
        var owned: Array = section["owned"]
        for item_id in catalog:
            var item: Dictionary = catalog[item_id]
            var item_key: String = str(item_id)
            var kind: String = str(section["kind"])
            var button := Button.new()
            var is_owned := item_key in owned
            button.text = str(item["name"]) + ("  · 已拥有" if is_owned else "  · 未解锁")
            if is_owned and item_key != str(section["active"]):
                button.pressed.connect(func():
                    CollectionSystem.equip(kind,item_key)
                    game.call("refresh_player_stats")
                    set_notice("已装备：" + str(item["name"]))
                    popup.queue_free()
                )
            else:
                button.disabled = true
            box.add_child(button)
            var detail := Label.new()
            detail.text = str(item.get("description",""))
            box.add_child(detail)
    var achievements_title := Label.new()
    achievements_title.text = "成就"
    achievements_title.add_theme_font_size_override("font_size",19)
    box.add_child(achievements_title)
    var achievements: Dictionary = data.get("achievements",{})
    for achievement_id in CollectionSystem.ACHIEVEMENTS:
        var achievement: Dictionary = CollectionSystem.ACHIEVEMENTS[achievement_id]
        var done := bool(achievements.get(achievement_id,false))
        var claimed: Array = data.get("claimed_achievements",[])
        var achievement_button := Button.new()
        achievement_button.text = ("已领取 · " if achievement_id in claimed else ("领取奖励 · " if done else "未完成 · ")) + str(achievement["name"]) + "： " + str(achievement["description"])
        achievement_button.disabled = not done or achievement_id in claimed
        var selected_achievement := str(achievement_id)
        achievement_button.pressed.connect(func():
            var ok: bool = CollectionSystem.claim_achievement(selected_achievement)
            set_notice("成就奖励已领取" if ok else "该成就尚未完成或奖励已领取")
            popup.queue_free()
        )
        box.add_child(achievement_button)
    var close := Button.new()
    close.text = "关闭"
    close.pressed.connect(func(): popup.queue_free())
    box.add_child(close)
    root.add_child(popup)
    popup.popup_centered()

func _open_sanctuary(root: Control) -> void:
 var popup := PopupPanel.new()
 popup.size = Vector2(560,520)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(540,500)
 popup.add_child(scroll)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",10)
 scroll.add_child(box)
 var title := Label.new()
 title.text = "个人圣域 · 离线经营"
 title.add_theme_font_size_override("font_size",23)
 box.add_child(title)
 var state: Dictionary = SanctuarySystem.get_state()
 var rewards: Dictionary = SanctuarySystem.get_offline_rewards()
 var summary := Label.new()
 summary.text = "圣域等级：%d / 10    离线累计：%.1f 小时（最多 24 小时）\n可领取：经验 %d    星币 %d" % [int(state.get("level",1)),float(rewards.get("hours",0.0)),int(rewards.get("exp",0)),int(rewards.get("coins",0))]
 summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(summary)
 var collect := Button.new()
 collect.text = "领取离线收益"
 collect.pressed.connect(func():
  var result: Dictionary = SanctuarySystem.collect_offline_rewards()
  game.call("refresh_player_stats")
  set_notice("离线收益：经验 %d，星币 %d" % [int(result.get("exp",0)),int(result.get("coins",0))])
  popup.queue_free()
 )
 box.add_child(collect)
 var upgrade_home := Button.new()
 upgrade_home.text = "升级个人圣域（消耗 %d 星币）" % (int(state.get("level",1))*1500)
 upgrade_home.pressed.connect(func():
  var ok: bool = SanctuarySystem.upgrade_sanctuary()
  set_notice("圣域等级提升成功" if ok else "星币不足或圣域已达上限")
  popup.queue_free()
 )
 box.add_child(upgrade_home)
 var facilities: Dictionary = state.get("facilities",{})
 for facility_id in SanctuarySystem.FACILITIES:
  var facility: Dictionary = SanctuarySystem.FACILITIES[facility_id]
  var level := int(facilities.get(facility_id,1))
  var button := Button.new()
  button.text = "%s Lv.%d → Lv.%d（消耗 %d 星币）" % [str(facility.get("name","设施")),level,level+1,int(facility.get("base_cost",300))*level]
  button.disabled = level >= SanctuarySystem.MAX_FACILITY_LEVEL
  var selected_id := str(facility_id)
  button.pressed.connect(func():
   var ok: bool = SanctuarySystem.upgrade_facility(selected_id)
   set_notice("设施升级成功" if ok else "星币不足或设施已达上限")
   popup.queue_free()
  )
  box.add_child(button)
 var leave := Button.new()
 leave.text = "进入圣域 / 返回竞技场"
 leave.pressed.connect(func():
  popup.queue_free()
  if bool(game.get("sanctuary_active")): game.call("leave_sanctuary")
  else: game.call("enter_sanctuary")
 )
 box.add_child(leave)
 var close := Button.new()
 close.text = "关闭"
 close.pressed.connect(func(): popup.queue_free())
 box.add_child(close)
 root.add_child(popup)
 popup.popup_centered()


func show_battle_result(summary: Dictionary, rewards: Dictionary = {}) -> void:
    var root := get_child(0) as Control
    var panel := Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.offset_left = -290
    panel.offset_right = 290
    panel.offset_top = -265
    panel.offset_bottom = 265
    panel.z_index = 30
    _style_panel(panel, Color(0.012, 0.02, 0.065, 0.985), Color(0.9, 0.68, 0.22))
    root.add_child(panel)
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    var encounter := Label.new()
    encounter.text = str(summary.get("encounter_id", "自由战斗")).replace("_", " ")
    encounter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    encounter.add_theme_font_size_override("font_size", 14)
    encounter.add_theme_color_override("font_color", Color(0.55, 0.72, 0.9))
    box.add_child(encounter)
    var title := Label.new()
    title.text = "战斗结算"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.38))
    box.add_child(title)
    var grade_value := str(summary.get("grade", "未完成"))
    var grade := Label.new()
    grade.text = "战斗评价：%s" % grade_value
    grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    grade.add_theme_font_size_override("font_size", 27)
    var grade_colors := {"S": Color(1.0, 0.82, 0.28), "A": Color(0.35, 0.92, 0.65), "B": Color(0.38, 0.72, 1.0), "C": Color(0.82, 0.72, 0.62), "未完成": Color(0.68, 0.72, 0.8)}
    grade.add_theme_color_override("font_color", grade_colors.get(grade_value, Color.WHITE))
    box.add_child(grade)
    var duration := maxi(0, int(summary.get("duration_seconds", 0)))
    var minutes := int(duration / 60)
    var seconds := duration % 60
    var damage := float(summary.get("damage_dealt", 0.0))
    var dps := damage / maxf(1.0, float(duration))
    var stats := Label.new()
    stats.text = "造成伤害：%.0f    平均秒伤：%.1f\n承受伤害：%.0f    治疗恢复：%.0f\n击败敌人：%d（Boss：%d）\n技能释放：%d    连招：%d    暴击：%d\n战斗时长：%02d:%02d" % [
        damage,
        dps,
        float(summary.get("damage_taken", 0.0)),
        float(summary.get("healing_received", 0.0)),
        int(summary.get("enemies_defeated", 0)),
        int(summary.get("bosses_defeated", 0)),
        int(summary.get("skills_cast", 0)),
        int(summary.get("combos_used", 0)),
        int(summary.get("critical_hits", 0)),
        minutes,
        seconds
    ]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 17)
    stats.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
    box.add_child(stats)
    var divider := HSeparator.new()
    divider.add_theme_color_override("separator", Color(0.55, 0.42, 0.2, 0.8))
    box.add_child(divider)
    var reward := Label.new()
    reward.text = "本场奖励：经验 %d    星币 %d" % [int(rewards.get("exp", 0)), int(rewards.get("coins", 0))]
    reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward.add_theme_font_size_override("font_size", 18)
    reward.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42))
    box.add_child(reward)
    var close := Button.new()
    close.text = "返回战场"
    close.custom_minimum_size = Vector2(190, 50)
    close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    close.pressed.connect(func():
        if is_instance_valid(panel):
            panel.queue_free()
    )
    box.add_child(close)
