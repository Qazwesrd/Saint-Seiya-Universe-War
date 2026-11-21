#!/usr/bin/env python3
"""Export one Angelica SKI entry from a PCK archive to a neutral JSON mesh file.

This is a local conversion step for Blender/Godot inspection. It does not modify
or repack the source PCK/PKX archive.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def normalize_entry_path(entry_path: str) -> str:
    return str(entry_path).replace("\\", "/").lstrip("/")

def _mesh_payload(mesh: Any, *, weighted: bool) -> dict[str, Any]:
    payload = {
        "name": str(mesh.name),
        "positions": list(mesh.positions),
        "normals": list(mesh.normals),
        "uvs": list(mesh.uvs),
        "indices": list(mesh.indices),
        "texture_index": int(mesh.texture_index),
        "material_index": int(mesh.material_index),
    }
    if weighted:
        payload["bone_weights"] = list(mesh.bone_weights)
        payload["bone_indices"] = list(mesh.bone_indices)
    else:
        payload["bone_index"] = int(mesh.bone_index)
    vertex_count = len(payload["positions"]) // 3
    if len(payload["positions"]) % 3 or len(payload["normals"]) != vertex_count * 3:
        raise ValueError(f"Invalid position/normal array lengths in mesh {payload['name']!r}")
    if len(payload["uvs"]) != vertex_count * 2:
        raise ValueError(f"Invalid UV array length in mesh {payload['name']!r}")
    if any(index < 0 or index >= vertex_count for index in payload["indices"]):
        raise ValueError(f"Triangle index out of range in mesh {payload['name']!r}")
    if weighted and (
        len(payload["bone_weights"]) != vertex_count * 4
        or len(payload["bone_indices"]) != vertex_count * 4
    ):
        raise ValueError(f"Invalid skinning arrays in mesh {payload['name']!r}")
    return payload


def build_payload(entry_path: str, skin: Any) -> dict[str, Any]:
    skin_meshes = [_mesh_payload(mesh, weighted=True) for mesh in skin.skin_meshes]
    rigid_meshes = [_mesh_payload(mesh, weighted=False) for mesh in skin.rigid_meshes]
    return {
        "schema_version": 1,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "source_entry": normalize_entry_path(entry_path),
        "ski_version": int(skin.version),
        "textures": list(skin.textures),
        "bone_names": list(skin.bone_names),
        "num_ske_bone": int(skin.num_ske_bone),
        "materials": [
            {
                "name": str(material.name),
                "ambient": list(material.ambient),
                "diffuse": list(material.diffuse),
                "emissive": list(material.emissive),
                "specular": list(material.specular),
                "power": float(material.power),
                "two_sided": bool(material.two_sided),
            }
            for material in skin.materials
        ],
        "skin_meshes": skin_meshes,
        "rigid_meshes": rigid_meshes,
        "safety": "Converted mesh data only; source archive was not modified.",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path, help="PCK archive path")
    parser.add_argument("--pkx", action="append", default=[], help="Matching PKX part; repeat for multiple parts")
    parser.add_argument("--entry", required=True, help="Exact SKI entry path inside the archive")
    parser.add_argument("--output", type=Path, required=True, help="Output JSON file outside source archive directory")
    args = parser.parse_args(argv)

    pck_path = args.pck.expanduser().resolve(strict=True)
    pkx_paths = [Path(item).expanduser().resolve(strict=True) for item in args.pkx]
    output = args.output.expanduser().resolve()
    if not pck_path.is_file() or any(not path.is_file() for path in pkx_paths):
        parser.error("PCK and PKX inputs must be regular files")
    if Path(args.entry).suffix.lower() != ".ski":
        parser.error("--entry must point to a .ski resource")
    source_files = [pck_path, *pkx_paths]
    if any(path.parent == output.parent or path.parent in output.parents for path in source_files):
        parser.error("--output must be outside every source archive directory")

    try:
        import autoangel
    except ImportError:
        print("Missing optional dependency 'autoangel'. Install it with: py -m pip install autoangel", file=sys.stderr)
        return 2

    try:
        package = autoangel.read_pck(str(pck_path), [str(path) for path in pkx_paths] or None)
        raw = package.get_file(args.entry)
        if raw is None:
            print(f"ENTRY_NOT_FOUND: {args.entry}", file=sys.stderr)
            return 1
        skin = autoangel.read_skin(raw)
        payload = build_payload(args.entry, skin)
    except Exception as exc:
        print(f"SKI_CONVERSION_FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "SKI_JSON_EXPORT_PASS "
        f"skin_meshes={len(payload['skin_meshes'])} "
        f"rigid_meshes={len(payload['rigid_meshes'])} "
        f"materials={len(payload['materials'])} "
        f"bones={len(payload['bone_names'])}"
    )
    print(f"JSON {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
