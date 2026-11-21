#!/usr/bin/env python3
"""Generate/check art delivery manifests. Manifests are not completed art assets."""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "game"
ELEMENTS = ("fire", "ice", "lightning", "light", "dark", "water", "wind", "time", "soul", "sound", "cosmos")
CHARACTER_REQUIRED_CLIPS = [
    "idle", "walk", "run", "jump", "fall", "land",
    "basic_attack_1", "basic_attack_2", "basic_attack_3", "signature_idle",
    "skill_cast", "hit_light", "hit_heavy", "dodge", "block",
    "victory", "defeat", "phase_shift",
]


def catalog_ids(path: Path, marker: str) -> list[str]:
    source = path.read_text(encoding="utf-8")
    start = source.find(marker)
    if start < 0:
        raise ValueError(f"catalog marker not found: {marker}")
    match = re.search(r"\n(.*?)^}", source[start:], re.S | re.M)
    if not match:
        raise ValueError(f"catalog block is not closed: {marker}")
    return re.findall(r'^\s*"([^"]+)"\s*:\s*\{', match.group(1), re.M)


def manifest(kind: str, asset_id: str) -> dict:
    data = {
        "schema_version": 1, "asset_id": asset_id, "asset_kind": kind,
        "delivery_status": "pending", "authored_asset": False,
        "source_license": "pending_review",
        "quality_gate": {
            "tier": "prototype_blockout",
            "canon_identity_verified": False,
            "visual_review_required": True,
            "approved_for_final_release": False,
        },
        "notes": "Requirement manifest only; generated blockouts are prototypes, not final canon-accurate art."
    }
    if kind == "character":
        data.update({
            "model": {"path": "model/character.glb", "status": "not_created", "format": "glTF 2.0 binary"},
            "skeleton": {"path": "model/character_skeleton", "status": "not_created", "root_bone": "Root"},
            "animation_library": {
                "path": "animations/animation_library.glb", "status": "not_created",
                "required_clips": CHARACTER_REQUIRED_CLIPS,
                "profession_specific_clip_patterns": [
                    "{asset_id}_signature_idle",
                    "{asset_id}_basic_attack_1",
                    "{asset_id}_basic_attack_2",
                    "{asset_id}_basic_attack_3",
                ],
            },
            "portrait": {"path": "portraits/portrait.png", "status": "not_created"},
            "attachment_points": ["Head", "Chest", "LeftShoulder", "RightShoulder", "LeftHand", "RightHand", "Waist", "LeftFoot", "RightFoot"]
        })
    elif kind == "armor":
        data.update({
            "model": {"path": "model/armor.glb", "status": "not_created", "format": "glTF 2.0 binary"},
            "parts": {part: "not_created" for part in ("helmet", "chest", "left_shoulder", "right_shoulder", "left_forearm", "right_forearm", "waist", "left_leg", "right_leg")},
            "icon": {"path": "icons/icon.png", "status": "not_created"},
            "rig_compatibility": "character_skeleton"
        })
    elif kind == "enemy":
        data.update({
            "model": {"path": "model/enemy.glb", "status": "not_created", "format": "glTF 2.0 binary"},
            "portrait": {"path": "portraits/portrait.png", "status": "not_created"},
            "skeleton_compatibility": "humanoid_base"
        })
    else:
        data.update({
            "effect_scene": {"path": "effect.tscn", "status": "not_created"},
            "trigger": "impact_or_cast_as_defined_by_skill",
            "quality_tiers": {"low": "not_created", "medium": "not_created", "high": "not_created"},
            "performance_budget": {"max_particles": 96, "max_transparent_layers": 3, "max_lifetime_seconds": 2.5}
        })
    return data


def expected() -> dict[Path, dict]:
    classes = catalog_ids(GAME / "scripts/character_visual_catalog.gd", "const PROFILES := {")
    equipment = catalog_ids(GAME / "scripts/equipment_database.gd", "const EQUIPMENT := {")
    result = {}
    for asset_id in classes:
        result[GAME / "assets/characters" / asset_id / "manifest.json"] = manifest("character", asset_id)
    for asset_id in equipment:
        result[GAME / "assets/armors" / asset_id / "manifest.json"] = manifest("armor", asset_id)
    enemies = catalog_ids(GAME / "scripts/enemy_database.gd", "const ARCHETYPES := {")
    for asset_id in enemies:
        result[GAME / "assets/enemies" / asset_id / "manifest.json"] = manifest("enemy", asset_id)
    for asset_id in ELEMENTS:
        result[GAME / "assets/vfx" / asset_id / "manifest.json"] = manifest("vfx", asset_id)
    return result


def migrate_manifest(current: dict, expected_data: dict) -> bool:
    """Update only pipeline-owned quality metadata; preserve user review/status fields."""
    changed = False
    if current.get("quality_gate") != expected_data["quality_gate"]:
        current["quality_gate"] = expected_data["quality_gate"]
        changed = True
    if expected_data["asset_kind"] == "character":
        expected_animation = expected_data["animation_library"]
        animation = current.setdefault("animation_library", {})
        if animation.get("required_clips") != expected_animation["required_clips"]:
            animation["required_clips"] = expected_animation["required_clips"]
            changed = True
        if animation.get("profession_specific_clip_patterns") != expected_animation["profession_specific_clip_patterns"]:
            animation["profession_specific_clip_patterns"] = expected_animation["profession_specific_clip_patterns"]
            changed = True
    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    specs = expected()
    missing, invalid, migrated = [], [], []
    for path, data in specs.items():
        if not path.is_file():
            missing.append(path)
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            continue
        try:
            current = json.loads(path.read_text(encoding="utf-8"))
            if (current.get("schema_version") != 1
                    or current.get("asset_id") != data["asset_id"]
                    or current.get("asset_kind") != data["asset_kind"]):
                invalid.append(path)
                continue
            changed = migrate_manifest(current, data)
            if changed:
                if args.check:
                    invalid.append(path)
                else:
                    path.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                    migrated.append(path)
        except (json.JSONDecodeError, UnicodeDecodeError):
            invalid.append(path)
    if args.check and missing:
        print(f"缺少 {len(missing)} 个交付清单；请运行 python3 tools/art_pipeline/build_manifests.py")
        return 1
    if invalid:
        label = "过期或无效清单：" if args.check else "无效清单："
        print(label + ", ".join(p.relative_to(ROOT).as_posix() for p in invalid))
        return 1
    print(f"美术交付清单：{len(specs)} 项检查完成；新增 {len(missing)} 项，迁移 {len(migrated)} 项。")
    print("原型占位不会被计为最终美术资产。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
