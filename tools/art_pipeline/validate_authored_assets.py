#!/usr/bin/env python3
"""Validate generated art manifests and any asset explicitly marked complete."""
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_manifests import expected

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

def check_glb(path: Path, require_skin: bool = False, clips: list[str] | None = None) -> None:
    doc = read_glb(path)
    if not doc.get("meshes"):
        raise ValueError("GLB has no meshes")
    if require_skin and not doc.get("skins"):
        raise ValueError("character GLB has no skin/skeleton")
    if clips:
        names = {str(item.get("name", "")) for item in doc.get("animations", [])}
        missing = sorted(set(clips) - names)
        if missing:
            raise ValueError("missing animation clips: " + ", ".join(missing))

def main() -> int:
    errors = []
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
                check_glb(anim, clips=data["animation_library"]["required_clips"])
            elif kind == "armor":
                model = safe_path(base, data["model"]["path"])
                icon = safe_path(base, data["icon"]["path"])
                if not model.is_file() or not icon.is_file():
                    raise ValueError("armor model or icon is missing")
                check_glb(model)
                if any(value != "complete" for value in data["parts"].values()):
                    raise ValueError("not all armor parts are complete")
            else:
                scene = safe_path(base, data["effect_scene"]["path"])
                if not scene.is_file():
                    raise ValueError("VFX scene is missing")
                if scene.suffix == ".glb":
                    check_glb(scene)
                elif scene.suffix == ".tscn":
                    source = scene.read_text(encoding="utf-8")
                    if "Particles3D" not in source and "MeshInstance3D" not in source:
                        raise ValueError("VFX scene has no particle or mesh node")
        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
            errors.append(f"{manifest_path.relative_to(ROOT)}: {exc}")
    print(f"美术资产验收：检查 {len(specs)} 个角色/装备/特效条目")
    if errors:
        print(f"发现 {len(errors)} 个问题：")
        for error in errors:
            print("  [FAIL] " + error)
        return 1
    print("清单结构通过；只有真实文件通过验收后才能标记为正式完成。")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
