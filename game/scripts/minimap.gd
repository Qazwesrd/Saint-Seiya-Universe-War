extends Control

var game: Variant
var animation_clock := 0.0

func _process(delta: float) -> void:
	animation_clock += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	draw_circle(center, radius + 9.0, Color(0.015, 0.025, 0.07, 0.94))
	draw_circle(center, radius + 4.0, Color(0.08, 0.2, 0.34, 0.9))
	draw_circle(center, radius, Color(0.025, 0.065, 0.12, 0.92))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.3, 0.72, 1.0, 0.95), 2.2, true)
	draw_arc(center, radius * 0.66, 0.0, TAU, 64, Color(0.2, 0.48, 0.72, 0.38), 1.0, true)
	draw_arc(center, radius * 0.33, 0.0, TAU, 64, Color(0.2, 0.48, 0.72, 0.28), 1.0, true)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.22, 0.42, 0.65, 0.38), 1.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.22, 0.42, 0.65, 0.38), 1.0)
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var inner := center + Vector2(cos(angle), sin(angle)) * (radius - (8.0 if index % 4 == 0 else 4.0))
		var outer := center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, Color(0.48, 0.72, 0.92, 0.7), 1.2)
	var font := get_theme_default_font()
	if font:
		draw_string(font, center + Vector2(0, -radius - 7.0), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.8, 0.9, 1.0))
		draw_string(font, center + Vector2(0, radius + 18.0), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.5, 0.7, 0.9))
	if not is_instance_valid(game):
		return
	var player: Node3D = game.get("player")
	if not is_instance_valid(player):
		return
	var origin: Vector3 = player.global_position
	var scale_factor := radius / 22.0
	for enemy in game.get("enemies"):
		if not is_instance_valid(enemy):
			continue
		var offset: Vector3 = enemy.global_position - origin
		var marker := Vector2(offset.x, offset.z) * scale_factor
		marker = marker.limit_length(radius - 7.0)
		draw_circle(center + marker, 5.0, Color(0.35, 0.04, 0.035, 0.9))
		draw_circle(center + marker, 3.2, Color(1.0, 0.25, 0.18))
	var portal: Node3D = game.get("teleport_point")
	if is_instance_valid(portal):
		var offset: Vector3 = portal.global_position - origin
		var marker := (Vector2(offset.x, offset.z) * scale_factor).limit_length(radius - 7.0)
		draw_circle(center + marker, 6.0, Color(0.08, 0.3, 0.6, 0.8))
		draw_circle(center + marker, 3.6, Color(0.2, 0.78, 1.0))
	var guide: Node3D = game.get("guide_npc")
	if is_instance_valid(guide) and QuestManager.status in ["not_started", "ready_to_return"]:
		var offset: Vector3 = guide.global_position - origin
		var marker := (Vector2(offset.x, offset.z) * scale_factor).limit_length(radius - 7.0)
		draw_circle(center + marker, 6.0, Color(0.55, 0.34, 0.04, 0.9))
		draw_circle(center + marker, 3.5, Color(1.0, 0.78, 0.18))
	var facing := -player.global_transform.basis.z
	var direction := Vector2(facing.x, facing.z).normalized()
	var tip := center + direction * 10.0
	var side := Vector2(-direction.y, direction.x) * 5.0
	draw_colored_polygon(PackedVector2Array([tip, center - direction * 5.0 + side, center - direction * 5.0 - side]), Color(0.35, 1.0, 0.78))
	draw_circle(center, 3.0, Color(0.04, 0.16, 0.13))
