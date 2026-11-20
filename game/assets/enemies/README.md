# Enemy and Boss Art Assets

This directory is the authored-art delivery root scanned by `ArtAssetAudit`.
Runtime procedural enemy silhouettes are fallbacks and do not count as delivered models.

Each `EnemyDatabase.ARCHETYPES` ID must receive its own folder:

```
<enemy_id>/
  model/enemy.glb
  materials/*.tres
  animations/animation_library.tres
  portraits/portrait.png
  lod/lod0/...
  lod/lod1/...
  manifest.json
```

The manifest must record the archetype ID, display name, boss flag, source/licence,
model scale, skeleton version, material set, animation clips, LOD policy, texture
formats, and Android memory budget. Bosses additionally need phase-specific
materials or animation events, entrance/death presentation, and readable attack
telegraphs.

Use original or properly licensed assets only. Do not copy extracted game assets,
unlicensed character models, or copyrighted promotional artwork. Keep model and
texture budgets appropriate for Android ARM64; provide reduced LODs and compressed
textures. The audit only marks a model or portrait present when the expected file
exists; a README or procedural fallback never counts as a finished asset.
