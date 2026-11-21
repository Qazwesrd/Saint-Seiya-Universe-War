#!/usr/bin/env python3
"""Read-only inventory of a locally owned Angelica / Saint Seiya Online client.

This tool never extracts, modifies, renames, or uploads client files. It records
paths, sizes, SHA-256 hashes, and likely Angelica asset extensions so a client
build can be assessed before any parser is run.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
from datetime import datetime, timezone

KNOWN_EXTENSIONS = {
    ".pck": "Angelica package archive",
    ".pkx": "Angelica split package continuation",
    ".ski": "Angelica mesh",
    ".smd": "Angelica model descriptor",
    ".bon": "Angelica skeleton",
    ".stck": "Angelica animation",
    ".ecm": "Angelica entity/model container",
    ".anm": "Angelica cutscene animation",
    ".dds": "DirectDraw texture",
    ".tga": "Targa texture",
    ".data": "Angelica game data (format varies)",
}
MAGIC_HINTS = {
    b"\x89PNG\r\n\x1a\n": "PNG image",
    b"DDS ": "DDS texture",
    b"LANG": "LANG text table",
}


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(chunk_size), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_file(path: Path, root: Path, do_hash: bool) -> dict:
    stat = path.stat()
    try:
        with path.open("rb") as stream:
            header = stream.read(16)
    except OSError as exc:
        header = b""
        read_error = str(exc)
    else:
        read_error = ""
    suffix = path.suffix.lower()
    magic = next((label for signature, label in MAGIC_HINTS.items()
                  if header.startswith(signature)), "")
    if suffix == ".pck" and not magic:
        magic = "PCK signature requires full format validation"
    record = {
        "relative_path": path.relative_to(root).as_posix(),
        "name": path.name,
        "extension": suffix,
        "type_hint": KNOWN_EXTENSIONS.get(suffix, magic or "unclassified file"),
        "size_bytes": stat.st_size,
        "modified_utc": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        "header_hex": header.hex(),
        "magic_hint": magic,
        "sha256": sha256_file(path) if do_hash and not read_error else "",
        "read_error": read_error,
    }
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("client_dir", type=Path, help="Root of the local client folder (read-only)")
    parser.add_argument("--output", type=Path, required=True, help="Output directory, outside client_dir")
    parser.add_argument("--no-hash", action="store_true", help="Skip SHA-256 for a faster first pass")
    args = parser.parse_args()

    root = args.client_dir.expanduser().resolve(strict=True)
    output = args.output.expanduser().resolve()
    if not root.is_dir():
        parser.error(f"client_dir is not a directory: {root}")
    if output == root or root in output.parents:
        parser.error("--output must be outside the client directory; source files are read-only")

    records = []
    errors = []
    for current, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = sorted(d for d in dirs if not (Path(current) / d).is_symlink())
        for filename in sorted(files):
            path = Path(current) / filename
            if path.is_symlink() or not path.is_file():
                continue
            try:
                records.append(inspect_file(path, root, not args.no_hash))
            except OSError as exc:
                errors.append({"relative_path": path.relative_to(root).as_posix(), "error": str(exc)})

    records.sort(key=lambda item: item["relative_path"].casefold())
    counts = {}
    for record in records:
        ext = record["extension"] or "[no extension]"
        counts[ext] = counts.get(ext, 0) + 1

    output.mkdir(parents=True, exist_ok=True)
    report = {
        "schema_version": 1,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "client_root_name": root.name,
        "hashes_included": not args.no_hash,
        "file_count": len(records),
        "read_error_count": len(errors),
        "extension_counts": dict(sorted(counts.items())),
        "files": records,
        "read_errors": errors,
        "safety": "Inventory only: no extraction, modification, execution, or network access.",
    }
    json_path = output / "client_inventory.json"
    csv_path = output / "client_inventory.csv"
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with csv_path.open("w", newline="", encoding="utf-8-sig") as stream:
        fields = ["relative_path", "extension", "type_hint", "size_bytes",
                  "modified_utc", "header_hex", "magic_hint", "sha256", "read_error"]
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(records)

    print(f"CLIENT_INVENTORY_PASS files={len(records)} read_errors={len(errors)}")
    for ext in (".pck", ".pkx", ".ski", ".smd", ".bon", ".stck", ".ecm", ".anm", ".data"):
        if counts.get(ext):
            print(f"ASSET_TYPE {ext} count={counts[ext]}")
    print(f"JSON {json_path}")
    print(f"CSV  {csv_path}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
