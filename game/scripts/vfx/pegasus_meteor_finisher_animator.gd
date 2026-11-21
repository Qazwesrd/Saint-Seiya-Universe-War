extends Node3D
## Timed three-beat animation for the Pegasus signature finisher preview.
@export var loop_preview := true
@export var duration := 1.15
var elapsed := 0.0
var fist: MeshInstance3D
var halo: MeshInstance3D
var outer_halo: MeshInstance3D
var afterimages: Array[MeshInstance3D] = []
var streaks: Array[MeshInstance3D] = []
var shards: Array[MeshInstance3D] = []

func _ready() -> void:
    fist = get_node_or_null("MainFistCore") as MeshInstance3D
    halo = get_node_or_null("ImpactHalo") as MeshInstance3D
    outer_halo = get_node_or_null("ImpactHaloOuter") as MeshInstance3D
    for index in range(1, 4):
        var afterimage := get_node_or_null("Afterimage_%02d" % index) as MeshInstance3D
        if afterimage != null:
            afterimages.append(afterimage)
        var streak := get_node_or_null("MeteorStreak_%02d" % index) as MeshInstance3D
        if streak != null:
            streaks.append(streak)
        var shard := get_node_or_null("ImpactShard_%02d" % index) as MeshInstance3D
        if shard != null:
            shards.append(shard)
    _apply_phase(0.0)

func _process(delta: float) -> void:
    elapsed += delta
    if not loop_preview and elapsed >= duration:
        _apply_phase(1.0)
        set_process(false)
        return
    _apply_phase(fposmod(elapsed, duration) / duration)

func _apply_phase(progress: float) -> void:
    var rush := clampf(progress / 0.62, 0.0, 1.0)
    var impact := clampf((progress - 0.48) / 0.52, 0.0, 1.0)
    if fist != null:
        fist.position = Vector3(-1.35 + rush * 1.35, 0.0, -0.25 + rush * 0.2)
        var fist_scale := 0.58 + sin(progress * PI) * 0.72
        fist.scale = Vector3.ONE * fist_scale
    for index in range(afterimages.size()):
        var ghost := afterimages[index]
        var fade := 1.0 - clampf(progress * 1.5 + float(index) * 0.16, 0.0, 1.0)
        ghost.scale = Vector3.ONE * (0.82 - float(index) * 0.13) * (0.55 + fade * 0.45)
        ghost.position.x = -1.55 + float(index) * 0.42 + rush * 0.45
    for index in range(streaks.size()):
        var streak := streaks[index]
        streak.position.x = -1.2 + float(index) * 0.43 + rush * 0.9
        streak.scale = Vector3.ONE * (0.35 + (1.0 - progress) * 0.75)
    if halo != null:
        var ring_scale := 0.25 + impact * 1.5
        halo.scale = Vector3.ONE * ring_scale
        halo.rotation.z += 0.025
    if outer_halo != null:
        outer_halo.scale = Vector3.ONE * (0.2 + impact * 1.8)
        outer_halo.rotation.z -= 0.018
    for index in range(shards.size()):
        var shard := shards[index]
        var burst := impact * (0.45 + float(index) * 0.16)
        shard.scale = Vector3.ONE * burst
        shard.position += Vector3(0.0, 0.0, 0.0)
