extends SceneTree

const CORE_HEROES := ["pegasus", "dragon", "cygnus", "andromeda", "phoenix"]
const REQUIRED_CLIPS := ["idle", "walk", "run"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	for hero_id in CORE_HEROES:
		var model_path := "res://assets/characters/%s/model/character.glb" % hero_id
		var packed := ResourceLoader.load(model_path) as PackedScene
		if packed == null:
			failures.append("%s: missing or unloadable model %s" % [hero_id, model_path])
			continue
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		var skeleton := _find_skeleton(instance)
		var player := _find_animation_player(instance)
		if skeleton == null or player == null:
			failures.append("%s: imported Skeleton3D or AnimationPlayer missing" % hero_id)
			instance.queue_free()
			await process_frame
			continue
		var clips := REQUIRED_CLIPS.duplicate()
		clips.append("%s_basic_attack_1" % hero_id)
		for clip_name in clips:
			var result := _verify_clip(player, skeleton, clip_name)
			if not bool(result.get("valid", false)):
				failures.append("%s/%s: %s" % [hero_id, clip_name, str(result.get("reason", "invalid"))])
		instance.queue_free()
		await process_frame
	if failures.is_empty():
		print("CHARACTER_ANIMATION_RUNTIME_PASS heroes=%d" % CORE_HEROES.size())
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("CHARACTER_ANIMATION_RUNTIME_FAIL count=%d" % failures.size())
	quit(1)

func _verify_clip(player: AnimationPlayer, skeleton: Skeleton3D, clip_name: String) -> Dictionary:
	if not player.has_animation(clip_name):
		return {"valid": false, "reason": "required clip missing"}
	var clip := player.get_animation(clip_name)
	if clip == null or clip.length <= 0.0 or clip.get_track_count() == 0:
		return {"valid": false, "reason": "clip has no duration or tracks"}
	var animation_root := player.get_node_or_null(player.root_node)
	if animation_root == null:
		return {"valid": false, "reason": "AnimationPlayer root_node does not resolve"}
	var bone_tracks: Array[int] = []
	for track_index in range(clip.get_track_count()):
		if clip.track_get_key_count(track_index) == 0:
			continue
		var track_path := clip.track_get_path(track_index)
		var target := animation_root.get_node_or_null(NodePath(track_path.get_concatenated_names()))
		if target == null:
			return {"valid": false, "reason": "track target does not resolve: %s" % str(track_path)}
		if target == skeleton:
			for subname_index in range(track_path.get_subname_count()):
				var bone_name := str(track_path.get_subname(subname_index))
				var bone_index := skeleton.find_bone(bone_name)
				if bone_index >= 0:
					bone_tracks.append(bone_index)
	if bone_tracks.is_empty():
		return {"valid": false, "reason": "clip has no keyed tracks targeting this skeleton's bones"}
	var original_animation := player.current_animation
	var original_position := player.current_animation_position
	var before: Dictionary = {}
	for bone_index in bone_tracks:
		before[bone_index] = skeleton.get_bone_pose_rotation(bone_index)
	player.play(clip_name)
	player.seek(clip.length * 0.5, true)
	skeleton.force_update_all_bone_transforms()
	var changed := false
	for bone_index in bone_tracks:
		var after := skeleton.get_bone_pose_rotation(bone_index)
		if not before[bone_index].is_equal_approx(after):
			changed = true
			break
	if not original_animation.is_empty() and player.has_animation(original_animation):
		player.play(original_animation)
		player.seek(original_position, true)
	else:
		player.stop()
	if not changed:
		return {"valid": false, "reason": "bone pose did not change at clip midpoint"}
	return {"valid": true}

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
