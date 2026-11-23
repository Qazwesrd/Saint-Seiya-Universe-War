#!/usr/bin/env python3
"""Find likely Saint Seiya character assets in read-only Angelica inventory reports.

This ranks path-name candidates only. It does not extract assets or claim that a
match is the canonical character model; every candidate requires visual review.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

CHARACTERS = {
    "seiya": ["seiya", "pegasus", "星矢", "天马"],
    "shiryu": ["shiryu", "shiryuu", "dragon", "紫龙", "紫龍", "天龙", "天龍"],
    "hyoga": ["hyoga", "cygnus", "冰河", "白鸟", "白鳥"],
    "shun": ["shun", "andromeda", "瞬", "仙女"],
    "ikki": ["ikki", "phoenix", "一辉", "一輝", "凤凰", "鳳凰"],
}
ASSET_EXTENSIONS = {".ski", ".smd", ".bon", ".stck", ".ecm", ".gfx", ".dds", ".tga", ".anm"}


def entries_from(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    entries = data.get("files", [])
    normalized = []
    for item in entries:
        if isinstance(item, str):
            normalized.append({"path": item, "extension": Path(item).suffix.lower()})
        elif isinstance(item, dict):
            name = item.get("path") or item.get("relative_path") or item.get("name") or ""
            normalized.append({**item, "path": str(name), "extension": str(item.get("extension") or Path(str(name)).suffix).lower()})
    return normalized


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inventory", type=Path, help="client_inventory.json or pck_inventory.json")
    parser.add_argument("--output", type=Path, required=True, help="Separate JSON report path")
    args = parser.parse_args()
    source = args.inventory.expanduser().resolve(strict=True)
    output = args.output.expanduser().resolve()
    if output == source:
        parser.error("--output must not overwrite the input inventory")

    entries = entries_from(source)
    results = {}
    for character, aliases in CHARACTERS.items():
        hits = []
        for item in entries:
            path = item["path"]
            folded = path.casefold()
            matched = [alias for alias in aliases if alias.casefold() in folded]
            if matched and item["extension"] in ASSET_EXTENSIONS:
                hits.append({
                    "path": path,
                    "extension": item["extension"],
                    "matched_aliases": matched,
                    "size_bytes": item.get("size_bytes"),
                    "compressed_size_bytes": item.get("compressed_size_bytes"),
                })
        results[character] = sorted(hits, key=lambda row: (row["extension"], row["path"].casefold()))

    report = {
        "schema_version": 1,
        "source_inventory": str(source),
        "candidate_count": sum(len(rows) for rows in results.values()),
        "characters": results,
        "interpretation": "Filename/path candidates only. Names can be absent, abbreviated, encrypted, or shared; verify each candidate by opening the actual asset.",
        "next_validation": ["confirm SKI mesh visually", "pair matching BON skeleton", "locate ECM equipment composition", "test STCK animation tracks", "resolve referenced textures and GFX effects"],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"CHARACTER_CANDIDATE_SCAN_PASS candidates={report['candidate_count']}")
    for character, rows in results.items():
        print(f"{character}: {len(rows)} candidates")
    print(f"JSON {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
