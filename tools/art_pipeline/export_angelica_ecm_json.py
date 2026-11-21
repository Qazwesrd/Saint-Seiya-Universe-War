#!/usr/bin/env python3
"""Export one Angelica ECM composite model from a PCK/PKX archive to JSON."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from angelica_ecm import build_ecm_payload, validate_ecm_payload


def normalize_lookup_path(value: str) -> str:
    return str(value).replace("/", "\\").lower()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path, help="PCK archive path")
    parser.add_argument("--pkx", action="append", default=[], help="Matching PKX part; repeat when needed")
    parser.add_argument("--entry", required=True, help="Exact .ecm path inside the archive")
    parser.add_argument("--output", type=Path, required=True, help="JSON output path outside source archive directories")
    args = parser.parse_args(argv)

    pck = args.pck.expanduser().resolve(strict=True)
    pkx = [Path(item).expanduser().resolve(strict=True) for item in args.pkx]
    output = args.output.expanduser().resolve()
    if not pck.is_file() or any(not item.is_file() for item in pkx):
        parser.error("PCK and PKX inputs must be regular files")
    if Path(args.entry).suffix.lower() != ".ecm":
        parser.error("--entry must point to a .ecm resource")
    if any(path.parent == output.parent or path.parent in output.parents for path in [pck, *pkx]):
        parser.error("--output must be outside every source archive directory")

    try:
        import autoangel
    except ImportError:
        print("Missing optional dependency 'autoangel'. Install with: py -m pip install autoangel", file=sys.stderr)
        return 2

    try:
        package = autoangel.read_pck(str(pck), [str(item) for item in pkx] or None)
        raw = package.get_file(normalize_lookup_path(args.entry))
        if raw is None:
            print(f"ENTRY_NOT_FOUND: {args.entry}", file=sys.stderr)
            return 1
        payload = build_ecm_payload(args.entry, autoangel.read_ecm(raw))
        stats = validate_ecm_payload(payload)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\\n", encoding="utf-8")
    except Exception as exc:
        print(f"ANGELICA_ECM_EXPORT_FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1

    print("ANGELICA_ECM_EXPORT_PASS " + " ".join(f"{key}={value}" for key, value in stats.items()))
    print(f"JSON {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
