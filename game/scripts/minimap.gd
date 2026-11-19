extends Control
var game: Variant
func _process(_delta: float) -> void:
    queue_redraw()
func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.38
    draw_circle(center, radius + 5.0, Color(0.02, 0.04, 0.1, 0.88))
    draw_arc(center, radius, 0.0, TAU, 48, Color(0.28, 0.62, 0.95, 0.9), 2.0)
    draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.22, 0.42, 0.65, 0.45), 1.0)
    draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.22, 0.42, 0.65, 0.45), 1.0)
    if not is_instance_valid(game):
        return
    var player: Node3D = game.get("player")
    if not is_instance_valid(player):
        return
    var origin: Vector3 = player.global_position
    for enemy in game.get("enemies"):
        if not is_instance_valid(enemy):
            continue
        var delta: Vector3 = enemy.global_position - origin
        var marker := Vector2(delta.x, delta.z) / 22.0 * radius
        marker = marker.limit_length(radius - 6.0)
        draw_circle(center + marker, 4.5, Color(1.0, 0.28, 0.2))
    draw_circle(center, 5.5, Color(0.25, 1.0, 0.72))
    draw_circle(center, 2.0, Color(0.04, 0.12, 0.1))
    var portal: Node3D = game.get("teleport_point")
    if is_instance_valid(portal):
        var portal_delta: Vector3 = portal.global_position - origin
        var portal_marker := Vector2(portal_delta.x, portal_delta.z) / 22.0 * radius
        portal_marker = portal_marker.limit_length(radius - 6.0)
        draw_circle(center + portal_marker, 4.5, Color(0.18, 0.72, 1.0))
    var guide: Node3D = game.get("guide_npc")
    if is_instance_valid(guide) and QuestManager.status in ["not_started", "ready_to_return"]:
        var guide_delta: Vector3 = guide.global_position - origin
        var guide_marker := Vector2(guide_delta.x, guide_delta.z) / 22.0 * radius
        guide_marker = guide_marker.limit_length(radius - 6.0)
        draw_circle(center + guide_marker, 5.0, Color(1.0, 0.78, 0.18))
        draw_line(center + guide_marker + Vector2(-4, 0), center + guide_marker + Vector2(4, 0), Color(0.15, 0.08, 0.01), 2.0)
        draw_line(center + guide_marker + Vector2(0, -4), center + guide_marker + Vector2(0, 4), Color(0.15, 0.08, 0.01), 2.0)
