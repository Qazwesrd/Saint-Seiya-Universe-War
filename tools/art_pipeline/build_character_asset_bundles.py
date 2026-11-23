#!/usr/bin/env python3
"""Group five-Bronze-Saint path candidates into reviewable asset bundles.

Only filename and folder relationships are used. No asset association is treated
as verified until the mesh, rig, animation, and texture are opened and inspected.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

KINDS = {
    ".ski": "mesh", ".smd": "model_descriptor", ".bon": "skeleton",
    ".stck": "animation", ".ecm": "equipment_composition",
    ".dds": "texture", ".tga": "texture", ".gfx": "effect", ".anm": "cutscene_animation",
}


def stem_key(path: str) -> str:
    stem = Path(path.replace("\\", "/")).stem.casefold()
    return re.sub(r"[^a-z0-9\u4e00-\u9fff]+", "", stem)


def load_candidates(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data.get("characters"), dict):
        raise ValueError("input must be a five-Bronze-Saint candidate report")
    return data["characters"]


def build_bundle(rows: list[dict]) -> dict:
    grouped = defaultdict(list)
    for row in rows:
        path = str(row.get("path", ""))
        ext = str(row.get("extension") or Path(path).suffix).lower()
        if ext not in KINDS:
            continue
        parent = str(Path(path.replace("\\", "/")).parent).casefold()
        key = (parent, stem_key(path))
        grouped[key].append({"path": path, "kind": KINDS[ext], "extension": ext})

    bundles = []
    for (parent, stem), files in sorted(grouped.items()):
        kinds = sorted({item["kind"] for item in files})
        strength = "same_folder_and_stem" if len(kinds) > 1 else "single_file_candidate"
        bundles.append({
            "folder": parent,
            "normalized_stem": stem,
            "relationship": strength,
            "asset_kinds": kinds,
            "files": sorted(files, key=lambda item: item["path"].casefold()),
            "verified": False,
        })
    return bundles


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidates", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = args.candidates.expanduser().resolve(strict=True)
    output = args.output.expanduser().resolve()
    if output == source:
        parser.error("--output must not overwrite input")

    characters = load_candidates(source)
    result = {}
    for character, rows in characters.items():
        result[character] = build_bundle(rows if isinstance(rows, list) else [])

    report = {
        "schema_version": 1,
        "source_candidates": str(source),
        "characters": result,
        "verification_policy": "same folder/stem is a discovery hint only; verify mesh geometry, BON hierarchy, SMD references, STCK tracks, ECM attachments and texture appearance before marking any asset as matched",
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    total = sum(len(items) for items in result.values())
    print(f"ASSET_BUNDLE_GROUPING_PASS bundles={total}")
    for character, bundles in result.items():
        print(f"{character}: {len(bundles)} bundles")
    print(f"JSON {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
