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
    root.add_child(hp_bar)
    cosmos_bar = ProgressBar.new()
    cosmos_bar.position = Vector2(36, 84)
    cosmos_bar.size = Vector2(255, 12)
    cosmos_bar.max_value = 100
    cosmos_bar.show_percentage = false
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
    _button(root, "角色", Vector2(22, 224), Vector2(112, 284), func(): _open_character(root), Color(0.18, 0.25, 0.48))
    _button(root, "闪避", Vector2(-370, -176), Vector2(-278, -104), func(): _call_player("dodge"), Color(0.12, 0.32, 0.55))
    _button(root, "锁定", Vector2(-270, -176), Vector2(-178, -104), func(): _call_player("toggle_lock"), Color(0.16, 0.22, 0.42))
    burst_button = _button(root, "小宇宙", Vector2(-180, -278), Vector2(-70, -198), func(): _call_player("cosmos_burst"), Color(0.45, 0.18, 0.08))
    skill_button = _button(root, "流星拳\n技能", Vector2(-292, -98), Vector2(-166, -4), func(): _call_player("skill"), Color(0.08, 0.35, 0.68))
    _button(root, "普攻", Vector2(-150, -166), Vector2(-24, -34), func(): _call_player("attack"), Color(0.62, 0.15, 0.12))
    get_viewport().size_changed.connect(_on_resize)
func _style_panel(panel: Panel, color: Color, border: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    panel.add_theme_stylebox_override("panel", style)
func _button(root: Control, label: String, tl: Vector2, br: Vector2, action: Callable, color: Color) -> Button:
    var b := Button.new()
    b.text = label
    b.anchor_left = 1.0
    b.anchor_right = 1.0
    b.anchor_top = 1.0
    b.anchor_bottom = 1.0
    b.offset_left = tl.x
    b.offset_top = tl.y
    b.offset_right = br.x
    b.offset_bottom = br.y
    b.add_theme_font_size_override("font_size", 18)
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.65, 0.82, 1.0, 0.85)
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    b.add_theme_stylebox_override("normal", style)
    b.add_theme_stylebox_override("pressed", style)
    b.pressed.connect(action)
    root.add_child(b)
    return b
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed and t.position.x < 230.0 and t.position.y > get_viewport().size.y * 0.55 and finger_id == -1:
            finger_id = t.index
            _move_stick(t.position)
        elif not t.pressed and t.index == finger_id:
            finger_id = -1
            stick_value = Vector2.ZERO
            _send_move(Vector2.ZERO)
            stick_knob.position = stick_base.position + Vector2(46, 46)
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        if d.index == finger_id: _move_stick(d.position)
func _move_stick(pos: Vector2) -> void:
    var center := stick_base.position + stick_base.size * 0.5
    stick_value = ((pos - center).limit_length(58.0)) / 58.0
    stick_knob.position = center + stick_value * 58.0 - stick_knob.size * 0.5
    _send_move(stick_value)
func _send_move(value: Vector2) -> void:
    if is_instance_valid(game.player): game.player.set_move_input(value)
func _call_player(method: String) -> void:
    if is_instance_valid(game.player): game.player.call(method)
func set_status(hp: float, hp_max: float, cosmos: float, cosmos_max: float, skill_cd: float, burst_cd: float) -> void:
    if not is_instance_valid(status_label): return
    var profile: Dictionary = RPGState.profile
    var class_id := str(profile.get("class_id", "pegasus"))
    var class_label := str(RPGState.CLASS_DATA.get(class_id, {}).get("name", "天马座"))
    status_label.text = class_label + " Lv." + str(profile.get("level", 1)) + "  星币 " + str(profile.get("currency", 0))
    hp_bar.max_value = hp_max
    hp_bar.value = hp
    cosmos_bar.max_value = cosmos_max
    cosmos_bar.value = cosmos
    if is_instance_valid(skill_button):
        var skill_name := str(SkillSystem.get_class_skill(str(RPGState.profile.get("class_id", "pegasus"))).get("name", "职业技能"))
        skill_button.text = skill_name + "\n" + (str(snappedf(skill_cd, 0.1)) + "s" if skill_cd > 0.0 else "技能")
    if is_instance_valid(burst_button):
        burst_button.text = "小宇宙\n" + (str(snappedf(burst_cd, 0.1)) + "s" if burst_cd > 0.0 else "爆发")
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

func set_boss_status(hp: float, hp_max: float) -> void:
    var visible_boss := hp_max > 1.0
    boss_label.visible = visible_boss
    boss_bar.visible = visible_boss
    if visible_boss:
        boss_label.text = "训练 Boss"
        boss_bar.max_value = hp_max
        boss_bar.value = hp
func set_notice(message: String) -> void:
    if is_instance_valid(notice_label): notice_label.text = message
func _on_resize() -> void:
    stick_base.position = Vector2(42, get_viewport().size.y - 200)
    stick_knob.position = stick_base.position + Vector2(46, 46)

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
    var info := Label.new()
    info.text = "%s  Lv.%d    经验 %d/%d    星币 %d\n生命 %.0f    攻击 %.0f    防御 %.0f    速度 %.0f\n小宇宙培养：%d级" % [class_label, int(profile.get("level",1)), int(profile.get("exp",0)), RPGState.exp_to_next_level(), int(profile.get("currency",0)), stats["max_health"], stats["attack"], stats["defense"], stats["speed"], int(profile.get("cosmos_level",1))]
    box.add_child(info)

    var upgrade := Button.new()
    upgrade.text = "提升小宇宙等级（消耗当前等级 × 250 星币）"
    upgrade.pressed.connect(func():
        var success: bool = RPGState.upgrade_cosmos()
        if success:
            game.call("refresh_player_stats")
        set_notice("小宇宙培养成功" if success else "星币不足或已达到培养上限")
        popup.queue_free()
    )
    box.add_child(upgrade)

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
        save_button.text = "槽%d 保存" % slot_id
        save_button.pressed.connect(func():
            set_notice("存档已保存" if RPGState.save_slot(slot_id) else "存档保存失败")
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
