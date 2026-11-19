extends CanvasLayer
var game: Variant
var status_label: Label
var notice_label: Label
var enemy_label: Label
var hp_bar: ProgressBar
var cosmos_bar: ProgressBar
var skill_button: Button
var burst_button: Button
var minimap_control: Control
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
    _button(root, "商城", Vector2(22, 154), Vector2(112, 214), func(): set_notice("离线商城将在后续 RPG 系统阶段接入"), Color(0.28, 0.22, 0.08))
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
    status_label.text = "天马座 Lv.1    HP " + str(roundi(hp)) + "/" + str(roundi(hp_max))
    hp_bar.max_value = hp_max
    hp_bar.value = hp
    cosmos_bar.max_value = cosmos_max
    cosmos_bar.value = cosmos
    if is_instance_valid(skill_button):
        skill_button.text = "流星拳\\n" + (str(snappedf(skill_cd, 0.1)) + "s" if skill_cd > 0.0 else "技能")
    if is_instance_valid(burst_button):
        burst_button.text = "小宇宙\\n" + (str(snappedf(burst_cd, 0.1)) + "s" if burst_cd > 0.0 else "爆发")
func set_enemy_count(count: int) -> void:
    enemy_label.text = "剩余目标：" + str(count)
func set_notice(message: String) -> void:
    if is_instance_valid(notice_label): notice_label.text = message
func _on_resize() -> void:
    stick_base.position = Vector2(42, get_viewport().size.y - 200)
    stick_knob.position = stick_base.position + Vector2(46, 46)
