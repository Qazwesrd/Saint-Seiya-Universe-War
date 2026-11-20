#!/usr/bin/env python3
"""Validate art manifests and the structure of assets explicitly marked complete."""
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_manifests import ELEMENTS, expected

ARMOR_PART_NODES = {
    "helmet": "Armor_Helmet",
    "chest": "Armor_Chest",
    "left_shoulder": "Armor_Left_Shoulder",
    "right_shoulder": "Armor_Right_Shoulder",
    "left_forearm": "Armor_Left_Forearm",
    "right_forearm": "Armor_Right_Forearm",
    "waist": "Armor_Waist",
    "left_leg": "Armor_Left_Leg",
    "right_leg": "Armor_Right_Leg",
}
QUALITY_TIERS = ("low", "medium", "high")
SUPPORTED_EFFECT_SHAPES = {
    "flare", "shard", "bolt", "halo", "void", "wave",
    "crescent", "ring", "wisp", "pulse", "star",
}

def safe_path(base: Path, relative: str) -> Path:
    item = Path(relative)
    if item.is_absolute() or ".." in item.parts:
        raise ValueError("asset path must be relative and may not contain '..'")
    result = (base / item).resolve()
    if not result.is_relative_to(base.resolve()):
        raise ValueError("asset path escapes asset directory")
    return result

def read_glb(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise ValueError("invalid GLB header")
    version, declared_length = struct.unpack_from("<II", data, 4)
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if version != 2 or declared_length != len(data) or chunk_type != 0x4E4F534A or 20 + chunk_length > len(data):
        raise ValueError("invalid GLB v2 structure")
    return json.loads(data[20:20 + chunk_length].decode("utf-8").rstrip(" \t\r\n\0"))

def check_glb(path: Path, require_skin: bool = False, clips: list[str] | None = None,
              required_nodes: tuple[str, ...] = (), require_meshes: bool = True) -> dict:
    doc = read_glb(path)
    if require_meshes and not doc.get("meshes"):
        raise ValueError("GLB has no meshes")
    nodes = doc.get("nodes", [])
    meshes = doc.get("meshes", [])
    skins = doc.get("skins", [])
    if require_skin:
        if not skins:
            raise ValueError("character GLB has no skin/skeleton")
        skinned_mesh_count = 0
        for node_index, node in enumerate(nodes):
            if "mesh" not in node:
                continue
            mesh_index = node.get("mesh")
            if not isinstance(mesh_index, int) or not 0 <= mesh_index < len(meshes):
                raise ValueError(f"mesh node {node_index} references an invalid mesh")
            skin_index = node.get("skin")
            if not isinstance(skin_index, int) or not 0 <= skin_index < len(skins):
                raise ValueError(f"mesh node {node_index} is not bound to a valid skin")
            joints = skins[skin_index].get("joints", [])
            if not joints or any(not isinstance(joint, int) or not 0 <= joint < len(nodes) for joint in joints):
                raise ValueError(f"mesh node {node_index} references a skin with invalid joints")
            skinned_mesh_count += 1
        if skinned_mesh_count == 0:
            raise ValueError("character GLB has no skinned mesh nodes")
    if clips:
        animations = doc.get("animations", [])
        names = {str(item.get("name", "")) for item in animations}
        missing = sorted(set(clips) - names)
        if missing:
            raise ValueError("missing animation clips: " + ", ".join(missing))
        by_name = {str(item.get("name", "")): item for item in animations}
        for clip_name in clips:
            clip = by_name[clip_name]
            if not clip.get("channels") or not clip.get("samplers"):
                raise ValueError(f"animation clip '{clip_name}' has no animation tracks")
            accessors = doc.get("accessors", [])
            for sampler in clip["samplers"]:
                for accessor_key in ("input", "output"):
                    accessor_index = sampler.get(accessor_key)
                    if not isinstance(accessor_index, int) or not 0 <= accessor_index < len(accessors):
                        raise ValueError(f"animation clip '{clip_name}' has an invalid {accessor_key} accessor")
                if sampler.get("interpolation", "LINEAR") not in ("LINEAR", "STEP", "CUBICSPLINE"):
                    raise ValueError(f"animation clip '{clip_name}' has an unsupported interpolation")
            for channel in clip["channels"]:
                target = channel.get("target", {})
                node_index = target.get("node")
                sampler_index = channel.get("sampler")
                if not isinstance(node_index, int) or not 0 <= node_index < len(nodes):
                    raise ValueError(f"animation clip '{clip_name}' has an invalid track node")
                if not isinstance(sampler_index, int) or not 0 <= sampler_index < len(clip["samplers"]):
                    raise ValueError(f"animation clip '{clip_name}' has an invalid sampler reference")
                if target.get("path") not in ("translation", "rotation", "scale", "weights"):
                    raise ValueError(f"animation clip '{clip_name}' has an invalid track path")
    if required_nodes:
        names = {str(item.get("name", "")) for item in doc.get("nodes", [])}
        names.update(str(item.get("name", "")) for item in doc.get("meshes", []))
        missing = sorted(set(required_nodes) - names)
        if missing:
            raise ValueError("missing required mesh/node objects: " + ", ".join(missing))
    return doc

def validate_character_visual_catalog() -> list[str]:
    path = ROOT / "game/scripts/character_visual_catalog.gd"
    source = path.read_text(encoding="utf-8")
    start = source.find("const PROFILES := {")
    end = source.find("\n}", start)
    if start < 0 or end < 0:
        return ["character visual catalog PROFILES block is missing or malformed"]
    block = source[start:end]
    entries = re.findall(r'^\s*"([^"]+)"\s*:\s*\{([^}]+)\}', block, re.M)
    errors = []
    if len(entries) != 32:
        errors.append(f"expected 32 profession visual profiles, found {len(entries)}")
    signatures = {}
    required = ("crest", "ornament", "shoulder_scale", "wing_span", "silhouette")
    for class_id, body in entries:
        values = {}
        for key in required:
            match = re.search(rf'"{key}"\s*:\s*(?:"([^"]+)"|Vector3\(([^)]*)\)|([0-9.]+))', body)
            if not match:
                errors.append(f"{class_id}: missing geometry identity field {key}")
                continue
            values[key] = next((value for value in match.groups() if value is not None), "")
        if all(key in values for key in required):
            signature = tuple(values[key] for key in required)
            if signature in signatures:
                errors.append(f"{class_id}: geometry identity duplicates {signatures[signature]}")
            else:
                signatures[signature] = class_id
    return errors


def validate_skill_visual_catalog() -> list[str]:
    path = ROOT / "game/scripts/skill_visual_catalog.gd"
    source = path.read_text(encoding="utf-8")
    errors = []
    for element in ELEMENTS:
        pattern = (
            rf'"{re.escape(element)}"\s*:\s*\{{\s*"color"\s*:\s*Color\([^)]*\),'
            rf'\s*"shape"\s*:\s*"([^"]+)",\s*"glow"\s*:\s*([0-9.]+),'
            rf'\s*"impact_scale"\s*:\s*([0-9.]+)'
        )
        match = re.search(pattern, source)
        if not match:
            errors.append(f"{element}: missing color/shape/glow/impact_scale profile")
            continue
        shape, glow_text, scale_text = match.groups()
        if shape not in SUPPORTED_EFFECT_SHAPES:
            errors.append(f"{element}: unsupported effect shape '{shape}'")
        glow, impact_scale = float(glow_text), float(scale_text)
        if not 0.0 <= glow <= 0.6:
            errors.append(f"{element}: glow must be between 0.0 and 0.6")
        if not 0.5 <= impact_scale <= 1.5:
            errors.append(f"{element}: impact_scale must be between 0.5 and 1.5")
    return errors

def validate_armor_manifest(data: dict, model: Path) -> None:
    parts = data.get("parts")
    if not isinstance(parts, dict) or set(parts) != set(ARMOR_PART_NODES):
        raise ValueError("armor parts must declare exactly the nine required detachable pieces")
    if any(parts[name] != "complete" for name in ARMOR_PART_NODES):
        raise ValueError("not all nine armor parts are marked complete")
    doc = check_glb(model, require_skin=True, required_nodes=tuple(ARMOR_PART_NODES.values()))
    nodes = {str(item.get("name", "")): item for item in doc.get("nodes", [])}
    mesh_indices = []
    for part_name, node_name in ARMOR_PART_NODES.items():
        node = nodes.get(node_name, {})
        if not isinstance(node.get("mesh"), int):
            raise ValueError(f"armor part '{part_name}' is not an independent mesh node")
        if not isinstance(node.get("skin"), int):
            raise ValueError(f"armor part '{part_name}' is not bound to the character skeleton")
        mesh_indices.append(node["mesh"])
    if len(set(mesh_indices)) != len(ARMOR_PART_NODES):
        raise ValueError("each detachable armor part must use its own mesh")

def validate_vfx_manifest(data: dict, scene: Path) -> None:
    tiers = data.get("quality_tiers")
    if not isinstance(tiers, dict) or set(tiers) != set(QUALITY_TIERS):
        raise ValueError("VFX must declare low, medium and high quality tiers")
    if any(tiers[tier] != "complete" for tier in QUALITY_TIERS):
        raise ValueError("all three VFX quality tiers must be complete")
    budget = data.get("performance_budget")
    if not isinstance(budget, dict):
        raise ValueError("VFX performance_budget is missing")
    particles = int(budget.get("max_particles", 0))
    layers = int(budget.get("max_transparent_layers", 0))
    lifetime = float(budget.get("max_lifetime_seconds", 0))
    if not 1 <= particles <= 96:
        raise ValueError("VFX max_particles must be between 1 and 96")
    if not 1 <= layers <= 3:
        raise ValueError("VFX max_transparent_layers must be between 1 and 3")
    if not 0.0 < lifetime <= 2.5:
        raise ValueError("VFX max_lifetime_seconds must be greater than 0 and at most 2.5")
    if scene.suffix == ".glb":
        check_glb(scene)
    elif scene.suffix == ".tscn":
        source = scene.read_text(encoding="utf-8")
        if not any(token in source for token in ("GPUParticles3D", "CPUParticles3D", "MeshInstance3D")):
            raise ValueError("VFX scene has no particle or mesh node")
    else:
        raise ValueError("VFX scene must be .glb or .tscn")

def main() -> int:
    errors = validate_character_visual_catalog() + validate_skill_visual_catalog()
    specs = expected()
    for manifest_path, spec in specs.items():
        if not manifest_path.is_file():
            errors.append(f"missing manifest: {manifest_path.relative_to(ROOT)}")
            continue
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            if data.get("schema_version") != 1 or data.get("asset_id") != spec["asset_id"] or data.get("asset_kind") != spec["asset_kind"]:
                raise ValueError("schema_version, asset_id or asset_kind mismatch")
            if not isinstance(data.get("authored_asset"), bool):
                raise ValueError("authored_asset must be boolean")
            status = data.get("delivery_status")
            if status not in ("pending", "in_progress", "complete"):
                raise ValueError("invalid delivery_status")
            if data["authored_asset"] != (status == "complete"):
                raise ValueError("authored_asset must be true exactly when delivery_status is complete")
            if status != "complete":
                continue
            base = manifest_path.parent
            kind = data["asset_kind"]
            if kind == "character":
                model = safe_path(base, data["model"]["path"])
                anim = safe_path(base, data["animation_library"]["path"])
                portrait = safe_path(base, data["portrait"]["path"])
                if not model.is_file() or not anim.is_file() or not portrait.is_file():
                    raise ValueError("character model, animation library or portrait is missing")
                check_glb(model, require_skin=True)
                check_glb(anim, clips=data["animation_library"]["required_clips"], require_meshes=False)
            elif kind == "armor":
                model = safe_path(base, data["model"]["path"])
                icon = safe_path(base, data["icon"]["path"])
                if not model.is_file() or not icon.is_file():
                    raise ValueError("armor model or icon is missing")
                validate_armor_manifest(data, model)
            else:
                scene = safe_path(base, data["effect_scene"]["path"])
                if not scene.is_file():
                    raise ValueError("VFX scene is missing")
                validate_vfx_manifest(data, scene)
        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
            errors.append(f"{manifest_path.relative_to(ROOT)}: {exc}")
    print(f"美术资产验收：检查 {len(specs)} 个角色/装备/特效条目")
    if errors:
        print(f"发现 {len(errors)} 个问题：")
        for error in errors:
            print("  [FAIL] " + error)
        return 1
    print("清单结构与技能元素配置通过；正式完成项还必须通过模型节点、动画、场景和性能预算验收。")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
