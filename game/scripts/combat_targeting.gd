extends RefCounted
## Shared target selection for the player's lock-on system.
## Keeps target selection independent from HUD and combat presentation.

const DEFAULT_MAX_DISTANCE := 32.0

static func select_target(owner: Node3D, current_target: Node3D = null, cycle_forward: bool = false, max_distance: float = DEFAULT_MAX_DISTANCE) -> Node3D:
    if not is_instance_valid(owner) or not owner.is_inside_tree():
        return null

    var candidates: Array[Node3D] = []
    for node in owner.get_tree().get_nodes_in_group("enemies"):
        if not node is Node3D:
            continue
        var candidate := node as Node3D
        if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
            continue
        if not candidate.is_inside_tree():
            continue
        if candidate.has_method("is_targetable") and not bool(candidate.call("is_targetable")):
            continue
        if candidate.get("health") != null and float(candidate.get("health")) <= 0.0:
            continue
        if owner.global_position.distance_squared_to(candidate.global_position) > max_distance * max_distance:
            continue
        candidates.append(candidate)

    if candidates.is_empty():
        return null

    candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
        return owner.global_position.distance_squared_to(a.global_position) < owner.global_position.distance_squared_to(b.global_position)
    )

    if not cycle_forward or not is_instance_valid(current_target) or not candidates.has(current_target):
        return candidates[0]

    if candidates.size() == 1:
        return candidates[0]

    var current_index := candidates.find(current_target)
    return candidates[(current_index + 1) % candidates.size()]
