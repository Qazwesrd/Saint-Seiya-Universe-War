#!/usr/bin/env python3
"""Build a read-only inventory of an Angelica PCK/PKX archive using autoangel.

The archive is opened for parsing only. No package builder, save, or extraction
operation is used. Reports are written to a separate output directory.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _entry_value(entry: Any, name: str, default: Any = None) -> Any:
    if isinstance(entry, dict):
        return entry.get(name, default)
    return getattr(entry, name, default)


def _normalize_entry(entry: Any) -> dict[str, Any]:
    if isinstance(entry, str):
        path = entry
        size = compressed_size = checksum = None
    else:
        path = _entry_value(entry, "path", "")
        size = _entry_value(entry, "size")
        compressed_size = _entry_value(entry, "compressed_size")
        checksum = _entry_value(entry, "hash")
    path = str(path).replace("\\", "/").lstrip("/")
    suffix = Path(path).suffix.lower()
    return {
        "path": path,
        "extension": suffix,
        "size_bytes": size,
        "compressed_size_bytes": compressed_size,
        "archive_hash": checksum,
    }


def _read_entries(package: Any) -> list[dict[str, Any]]:
    paths = list(package.file_list())
    metadata: list[Any] = []
    scanner = getattr(package, "scan_entries", None)
    if callable(scanner) and paths:
        scanner(paths=paths, on_chunk=lambda chunk: metadata.extend(chunk))
    source = metadata if metadata else paths
    entries = [_normalize_entry(item) for item in source]
    entries.sort(key=lambda item: item["path"].casefold())
    return entries


def build_report(pck_path: Path, pkx_paths: list[Path], package: Any) -> dict[str, Any]:
    entries = _read_entries(package)
    counts = Counter(item["extension"] or "[no extension]" for item in entries)
    return {
        "schema_version": 1,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "archive": str(pck_path),
        "split_archives": [str(path) for path in pkx_paths],
        "file_count": len(entries),
        "extension_counts": dict(sorted(counts.items())),
        "files": entries,
        "safety": "Read-only archive inventory. No extraction or archive modification.",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path, help="PCK archive path")
    parser.add_argument("--pkx", action="append", default=[], help="Matching PKX part; repeat for multiple parts")
    parser.add_argument("--output", type=Path, required=True, help="Output directory, separate from source archive")
    args = parser.parse_args(argv)

    pck_path = args.pck.expanduser().resolve(strict=True)
    pkx_paths = [Path(item).expanduser().resolve(strict=True) for item in args.pkx]
    output = args.output.expanduser().resolve()
    if not pck_path.is_file() or any(not path.is_file() for path in pkx_paths):
        parser.error("PCK and PKX inputs must be regular files")
    source_files = [pck_path, *pkx_paths]
    if any(
        output == path or path.parent == output or path.parent in output.parents
        for path in source_files
    ):
        parser.error("--output must be outside every source archive directory")

    try:
        import autoangel
    except ImportError:
        print(
            "Missing optional dependency 'autoangel'. Install it with: py -m pip install autoangel",
            file=sys.stderr,
        )
        return 2

    try:
        package = autoangel.read_pck(str(pck_path), [str(path) for path in pkx_paths] or None)
        report = build_report(pck_path, pkx_paths, package)
    except Exception as exc:
        print(f"PCK_PARSE_FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1

    output.mkdir(parents=True, exist_ok=True)
    json_path = output / "pck_inventory.json"
    csv_path = output / "pck_inventory.csv"
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    fields = ["path", "extension", "size_bytes", "compressed_size_bytes", "archive_hash"]
    with csv_path.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(report["files"])

    print(f"PCK_INVENTORY_PASS entries={report['file_count']}")
    for extension, count in report["extension_counts"].items():
        print(f"EXTENSION {extension} count={count}")
    print(f"JSON {json_path}")
    print(f"CSV  {csv_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
