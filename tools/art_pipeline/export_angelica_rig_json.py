#!/usr/bin/env python3
"""Export Angelica BON skeleton or STCK animation data from a PCK to JSON."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def track_payload(track: Any) -> dict[str, Any]:
    frame_ids = getattr(track, "key_frame_ids", None)
    return {
        "frame_rate": int(track.frame_rate),
        "track_length_ms": int(track.track_length_ms),
        "keys": list(track.keys),
        "key_frame_ids": list(frame_ids) if frame_ids is not None else None,
    }


def animation_payload(animation: Any) -> dict[str, Any]:
    return {
        "anim_start": int(animation.anim_start),
        "anim_end": int(animation.anim_end) if animation.anim_end is not None else None,
        "anim_fps": int(animation.anim_fps),
        "bone_tracks": [
            {
                "bone_id": int(item.bone_id),
                "position": track_payload(item.position),
                "rotation": track_payload(item.rotation),
            }
            for item in animation.bone_tracks
        ],
    }


def build_payload(entry_path: str, parsed: Any, kind: str) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "schema_version": 1,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "source_entry": entry_path.replace("\\\\", "/"),
        "kind": kind,
    }
    if kind == "bon":
        payload.update({
            "skeleton_version": int(parsed.version),
            "bones": [
                {
                    "name": str(bone.name),
                    "parent": int(bone.parent),
                    "children": list(bone.children),
                    "mat_relative": list(bone.mat_relative),
                    "mat_bone_init": list(bone.mat_bone_init),
                    "is_fake": bool(bone.is_fake),
                    "is_flipped": bool(bone.is_flipped),
                }
                for bone in parsed.bones
            ],
            "hooks": [
                {
                    "name": str(hook.name),
                    "hook_type": int(hook.hook_type),
                    "bone_index": int(hook.bone_index),
                    "transform": list(hook.transform),
                }
                for hook in parsed.hooks
            ],
            "embedded_animation": (
                animation_payload(parsed.embedded_animation)
                if parsed.embedded_animation is not None else None
            ),
        })
    elif kind == "stck":
        payload["animation"] = animation_payload(parsed)
    else:
        raise ValueError(f"Unsupported resource kind: {kind}")
    payload["safety"] = "Converted skeleton/animation data only; source archive was not modified."
    return payload


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path, help="PCK archive path")
    parser.add_argument("--pkx", action="append", default=[], help="Matching PKX part; repeat for multiple parts")
    parser.add_argument("--entry", required=True, help="Exact .bon or .stck path inside the archive")
    parser.add_argument("--output", type=Path, required=True, help="Output JSON file outside source archive directory")
    args = parser.parse_args(argv)

    pck_path = args.pck.expanduser().resolve(strict=True)
    pkx_paths = [Path(item).expanduser().resolve(strict=True) for item in args.pkx]
    output = args.output.expanduser().resolve()
    if not pck_path.is_file() or any(not path.is_file() for path in pkx_paths):
        parser.error("PCK and PKX inputs must be regular files")
    kind = Path(args.entry).suffix.lower().lstrip(".")
    if kind not in {"bon", "stck"}:
        parser.error("--entry must point to a .bon or .stck resource")
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
        parsed = autoangel.read_skeleton(raw) if kind == "bon" else autoangel.read_animation(raw)
        payload = build_payload(args.entry, parsed, kind)
    except Exception as exc:
        print(f"RIG_DATA_EXPORT_FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\\n", encoding="utf-8")
    if kind == "bon":
        print(f"ANGELICA_BON_EXPORT_PASS bones={len(payload['bones'])} hooks={len(payload['hooks'])}")
    else:
        print(f"ANGELICA_STCK_EXPORT_PASS tracks={len(payload['animation']['bone_tracks'])}")
    print(f"JSON {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
