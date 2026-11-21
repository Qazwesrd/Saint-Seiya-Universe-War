#!/usr/bin/env python3
"""Validate Angelica ECM JSON files and their composite attachment graph."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from angelica_ecm import validate_ecm_graph, validate_ecm_payload


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ecm_json", nargs="+", type=Path, help="One or more exported ECM JSON files")
    parser.add_argument("--bon-json", type=Path, help="Optional matching BON JSON to validate parent hook names")
    parser.add_argument("--require-all-children", action="store_true", help="Fail when a referenced child ECM is not included")
    args = parser.parse_args()

    known_hooks = None
    if args.bon_json:
        bon = json.loads(args.bon_json.read_text(encoding="utf-8"))
        if not isinstance(bon, dict) or bon.get("kind") != "bon" or not isinstance(bon.get("hooks"), list):
            parser.error("--bon-json must be a BON export JSON containing a hooks array")
        known_hooks = {
            hook.get("name") for hook in bon["hooks"]
            if isinstance(hook, dict) and isinstance(hook.get("name"), str)
        }

    payloads = []
    for path in args.ecm_json:
        payload = json.loads(path.read_text(encoding="utf-8"))
        stats = validate_ecm_payload(payload, known_parent_hooks=known_hooks)
        print(f"ECM_VALID {path} " + " ".join(f"{key}={value}" for key, value in stats.items()))
        payloads.append(payload)

    graph = validate_ecm_graph(payloads, require_all_children=args.require_all_children)
    print("ANGELICA_ECM_VALIDATION_PASS " + " ".join(f"{key}={value}" for key, value in graph.items()))
    print("NOTE: structural validation only; real-client hook transforms and visual attachment remain unverified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
