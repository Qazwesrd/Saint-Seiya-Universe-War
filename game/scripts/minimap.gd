extends Control

var game: Variant
var animation_clock := 0.0

const MAP_RANGE := 22.0
const MAP_BACKGROUND := Color(0.015, 0.025, 0.07, 0.94)
const MAP_GRID := Color(0.2, 0.48, 0.72, 0.34)
const ENEMY_COLOR := Color(1.0, 0.25, 0.18)
const BOSS_COLOR := Color(1.0, 0.42, 0.12)
const OBJECTIVE_COLOR := Color(1.0, 0.82, 0.28)

func _process(delta: float) -> void:
	animation_clock = fposmod(animation_clock + delta, TAU * 4.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	draw_circle(center, radius + 9.0, MAP_BACKGROUND)
	draw_circle(center, radius + 4.0, Color(0.08, 0.2, 0.34, 0.9))
	draw_circle(center, radius, Color(0.025, 0.065, 0.12, 0.92))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.3, 0.72, 1.0, 0.95), 2.2, true)
	draw_arc(center, radius * 0.66, 0.0, TAU, 64, MAP_GRID, 1.0, true)
	draw_arc(center, radius * 0.33, 0.0, TAU, 64, MAP_GRID, 1.0, true)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), MAP_GRID, 1.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), MAP_GRID, 1.0)
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var inner := center + Vector2(cos(angle), sin(angle)) * (radius - (8.0 if index % 4 == 0 else 4.0))
		var outer := center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, Color(0.48, 0.72, 0.92, 0.7), 1.2)
	var sweep_angle := animation_clock * 0.72
	var sweep_end := center + Vector2(cos(sweep_angle), sin(sweep_angle)) * (radius - 2.0)
	draw_line(center, sweep_end, Color(0.22, 0.82, 1.0, 0.36), 2.0, true)
	draw_arc(center, radius - 2.0, sweep_angle - 0.28, sweep_angle, 24, Color(0.28, 0.88, 1.0, 0.42), 3.0, true)
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
	var scale_factor := radius / MAP_RANGE
	var objective: Node3D = _get_objective_target()
	var objective_marker := Vector2.ZERO
	var has_objective := is_instance_valid(objective)
	if has_objective:
		var objective_offset: Vector3 = objective.global_position - origin
		objective_marker = _world_to_map(objective_offset, center, scale_factor, radius)
		var pulse := 1.0 + 0.22 * sin(animation_clock * 4.0)
		draw_line(center, objective_marker, Color(1.0, 0.78, 0.24, 0.28), 1.5, true)
		draw_circle(objective_marker, 8.0 * pulse, Color(1.0, 0.72, 0.16, 0.2))
		draw_arc(objective_marker, 7.0 * pulse, 0.0, TAU, 32, OBJECTIVE_COLOR, 1.8, true)
	for enemy in game.get("enemies"):
		if not is_instance_valid(enemy):
			continue
		var offset: Vector3 = enemy.global_position - origin
		var marker := _world_to_map(offset, center, scale_factor, radius)
		if bool(enemy.get("is_boss")):
			var boss_pulse := 1.0 + 0.18 * sin(animation_clock * 5.0)
			draw_circle(marker, 8.0 * boss_pulse, Color(1.0, 0.16, 0.06, 0.22))
			draw_arc(marker, 7.0 * boss_pulse, 0.0, TAU, 24, BOSS_COLOR, 2.0, true)
			draw_circle(marker, 4.2, BOSS_COLOR)
		else:
			draw_circle(marker, 5.0, Color(0.35, 0.04, 0.035, 0.9))
			draw_circle(marker, 3.2, ENEMY_COLOR)
	var portal: Node3D = game.get("teleport_point")
	if is_instance_valid(portal):
		var offset: Vector3 = portal.global_position - origin
		var marker := _world_to_map(offset, center, scale_factor, radius)
		draw_circle(marker, 6.0, Color(0.08, 0.3, 0.6, 0.8))
		draw_circle(marker, 3.6, Color(0.2, 0.78, 1.0))
	var guide: Node3D = game.get("guide_npc")
	if is_instance_valid(guide) and QuestManager.status in ["not_started", "ready_to_return"]:
		var offset: Vector3 = guide.global_position - origin
		var marker := _world_to_map(offset, center, scale_factor, radius)
		draw_circle(marker, 6.0, Color(0.55, 0.34, 0.04, 0.9))
		draw_circle(marker, 3.5, OBJECTIVE_COLOR)
	var facing := -player.global_transform.basis.z
	var direction := Vector2(facing.x, facing.z).normalized()
	var tip := center + direction * 10.0
	var side := Vector2(-direction.y, direction.x) * 5.0
	draw_colored_polygon(PackedVector2Array([tip, center - direction * 5.0 + side, center - direction * 5.0 - side]), Color(0.35, 1.0, 0.78))
	draw_circle(center, 3.0, Color(0.04, 0.16, 0.13))
	if font:
		var objective_text := QuestManager.get_map_objective()
		draw_string(font, Vector2(5.0, size.y - 5.0), objective_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 10.0, 11, Color(1.0, 0.86, 0.52, 0.95))

func _world_to_map(offset: Vector3, center: Vector2, scale_factor: float, radius: float) -> Vector2:
	return center + (Vector2(offset.x, offset.z) * scale_factor).limit_length(radius - 7.0)

func _get_objective_target() -> Node3D:
	if not is_instance_valid(game):
		return null
	var status := str(QuestManager.status)
	if status in ["not_started", "ready_to_return"]:
		var guide: Node3D = game.get("guide_npc")
		return guide if is_instance_valid(guide) else null
	if status == "active":
		var enemies: Array = game.get("enemies")
		var want_boss := QuestManager.defeated_normal >= 2 and not QuestManager.boss_defeated
		var nearest: Node3D
		var nearest_distance := INF
		var player: Node3D = game.get("player")
		if not is_instance_valid(player):
			return null
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if bool(enemy.get("is_boss")) != want_boss:
				continue
			var distance := player.global_position.distance_squared_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = enemy
		if is_instance_valid(nearest):
			return nearest
		if want_boss:
			var guide: Node3D = game.get("guide_npc")
			return guide if is_instance_valid(guide) else null
	return null
