#!/usr/bin/env python3
"""Build deterministic SHA-256-pinned CDN manifests for seven Godot chapter PCKs."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path
from urllib.parse import urlparse

CHAPTERS = ("galaxy_wars", "sanctuary_twelve_houses", "asgard", "poseidon", "hades", "heaven", "original_final")
PCK_MAGIC = b"GDPC"
MIN_PCK_BYTES = 32


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_pck(path: Path) -> int:
    if not path.is_file():
        raise ValueError(f"Missing chapter PCK: {path}")
    size = path.stat().st_size
    if size <= MIN_PCK_BYTES:
        raise ValueError(f"PCK is too small to be valid: {path} ({size} bytes)")
    with path.open("rb") as stream:
        if stream.read(4) != PCK_MAGIC:
            raise ValueError(f"Invalid Godot PCK header: {path}")
    return size


def build_manifest(chapter_id: str, pck_path: Path, version: int) -> dict:
    if chapter_id not in CHAPTERS:
        raise ValueError(f"Unsupported chapter ID: {chapter_id}")
    size = validate_pck(pck_path)
    return {
        "id": chapter_id,
        "manifest_version": 1,
        "version": version,
        "size_bytes": size,
        "dependencies": [],
        "files": [{
            "path": f"{chapter_id}.pck",
            "size_bytes": size,
            "sha256": sha256_file(pck_path),
        }],
    }


def validate_cdn_url(value: str, label: str) -> str:
    if not value:
        return ""
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.netloc or not value.endswith("/"):
        raise ValueError(f"{label} must be an HTTPS base URL ending in '/': {value}")
    return value


def build_release(input_dir: Path, output_dir: Path, catalog_template: Path, version: int,
                  primary_cdn: str = "", fallback_cdn: str = "") -> dict:
    if version < 1:
        raise ValueError("Version must be >= 1")
    primary_cdn = validate_cdn_url(primary_cdn, "Primary CDN")
    fallback_cdn = validate_cdn_url(fallback_cdn, "Fallback CDN")
    if fallback_cdn and not primary_cdn:
        raise ValueError("A fallback CDN cannot be configured without a primary CDN")
    template = json.loads(catalog_template.read_text(encoding="utf-8"))
    if set(CHAPTERS) - set(template.get("packs", {})):
        raise ValueError("Catalog template does not contain all seven campaign packs")

    # Validate every source first. Never emit a partial seven-chapter release.
    source_pcks = {chapter: input_dir / f"{chapter}.pck" for chapter in CHAPTERS}
    for pck in source_pcks.values():
        validate_pck(pck)

    output_dir.mkdir(parents=True, exist_ok=True)
    for chapter, source_pck in source_pcks.items():
        chapter_dir = output_dir / chapter
        chapter_dir.mkdir(parents=True, exist_ok=True)
        target_pck = chapter_dir / source_pck.name
        shutil.copy2(source_pck, target_pck)
        manifest = build_manifest(chapter, target_pck, version)
        manifest_bytes = (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
        (chapter_dir / "pack.json").write_bytes(manifest_bytes)
        pack_info = template["packs"][chapter]
        pack_info["manifest_sha256"] = hashlib.sha256(manifest_bytes).hexdigest()
        pack_info["manifest_size_bytes"] = len(manifest_bytes)
        pack_info["version"] = version
        pack_info["install_state"] = "built_not_published" if not primary_cdn else "ready_to_publish"

    template["cdn_base_url"] = primary_cdn
    template["cdn_base_urls"] = [url for url in (primary_cdn, fallback_cdn) if url] or ["", ""]
    template["cdn_failover"] = "try_in_order_per_request"
    catalog_path = output_dir / "pack_catalog.release.json"
    catalog_path.write_text(json.dumps(template, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {
        "chapters": len(CHAPTERS),
        "output_dir": str(output_dir),
        "catalog": str(catalog_path),
        "cdn_configured": bool(primary_cdn),
        "packs": {
            chapter: {
                "pck_bytes": (output_dir / chapter / f"{chapter}.pck").stat().st_size,
                "manifest_sha256": template["packs"][chapter]["manifest_sha256"],
                "manifest_size_bytes": template["packs"][chapter]["manifest_size_bytes"],
            }
            for chapter in CHAPTERS
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, required=True, help="Directory containing all seven <chapter_id>.pck files")
    parser.add_argument("--output-dir", type=Path, required=True, help="CDN upload directory to create")
    parser.add_argument("--catalog", type=Path, default=Path("game/content/pack_catalog.json"))
    parser.add_argument("--version", type=int, required=True)
    parser.add_argument("--primary-cdn", default="", help="Optional HTTPS mainland CDN base URL ending in /")
    parser.add_argument("--fallback-cdn", default="", help="Optional HTTPS overseas backup CDN base URL ending in /")
    args = parser.parse_args()
    try:
        report = build_release(args.input_dir, args.output_dir, args.catalog, args.version, args.primary_cdn, args.fallback_cdn)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        parser.error(str(error))
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if not report["cdn_configured"]:
        print("NOTICE: downloads remain disabled until a real primary CDN URL is supplied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
