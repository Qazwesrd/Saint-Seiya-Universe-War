extends Node3D
## Runtime anchor and quest-trigger interface for the Galaxy Wars arena blockout.
## This scene is a gameplay graybox; final environment art is delivered separately.

signal quest_triggered(trigger_id: StringName, actor: Node3D)

const SPAWN_PATHS := {
	&"player": NodePath("SpawnPoints/PlayerSpawn"),
	&"bronze_arrival": NodePath("SpawnPoints/BronzeSaintsArrival"),
}
const NPC_ANCHOR_PATHS := {
	&"tournament_guide": NodePath("NpcAnchors/TournamentGuideAnchor"),
}
const ENEMY_ANCHOR_PATHS := {
	&"opening_duel": NodePath("EnemyAnchors/OpeningDuelEnemyAnchor"),
}

@onready var _quest_trigger: Area3D = $QuestTrigger

func _ready() -> void:
	_quest_trigger.body_entered.connect(_on_quest_trigger_body_entered)

func get_spawn_transform(spawn_id: StringName) -> Transform3D:
	return _get_anchor_transform(SPAWN_PATHS, spawn_id)

func get_npc_anchor_transform(npc_id: StringName) -> Transform3D:
	return _get_anchor_transform(NPC_ANCHOR_PATHS, npc_id)

func get_enemy_anchor_transform(enemy_id: StringName) -> Transform3D:
	return _get_anchor_transform(ENEMY_ANCHOR_PATHS, enemy_id)

func _get_anchor_transform(anchor_paths: Dictionary, anchor_id: StringName) -> Transform3D:
	var anchor_path: NodePath = anchor_paths.get(anchor_id, NodePath())
	if anchor_path.is_empty():
		push_warning("Unknown Galaxy Wars anchor id: " + String(anchor_id))
		return global_transform
	var anchor := get_node_or_null(anchor_path) as Node3D
	if anchor == null:
		push_warning("Galaxy Wars anchor node is missing: " + String(anchor_path))
		return global_transform
	return anchor.global_transform

func _on_quest_trigger_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		quest_triggered.emit(&"tournament_guide_intro", body)
