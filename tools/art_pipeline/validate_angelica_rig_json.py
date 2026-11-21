#!/usr/bin/env python3
"""Validate exported Angelica BON/STCK JSON without needing a game client.

This checks the neutral interchange contract only. It cannot prove that source
coordinates, quaternion conventions, or animation playback match the original game.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any


def _finite_numbers(value: Any, path: str = "$") -> None:
    if isinstance(value, bool) or value is None or isinstance(value, (str, int)):
        return
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError(f"{path}: non-finite number")
        return
    if isinstance(value, list):
        for index, item in enumerate(value):
            _finite_numbers(item, f"{path}[{index}]")
        return
    if isinstance(value, dict):
        for key, item in value.items():
            _finite_numbers(item, f"{path}.{key}")
        return
    raise ValueError(f"{path}: unsupported JSON value type {type(value).__name__}")


def validate_track(track: dict[str, Any], path: str) -> int:
    if not isinstance(track, dict):
        raise ValueError(f"{path}: expected object")
    rate = track.get("frame_rate")
    length = track.get("track_length_ms")
    keys = track.get("keys")
    if not isinstance(rate, int) or isinstance(rate, bool) or rate <= 0:
        raise ValueError(f"{path}.frame_rate: expected positive integer")
    if not isinstance(length, int) or isinstance(length, bool) or length < 0:
        raise ValueError(f"{path}.track_length_ms: expected non-negative integer")
    if not isinstance(keys, list):
        raise ValueError(f"{path}.keys: expected array")
    frame_ids = track.get("key_frame_ids")
    if frame_ids is not None:
        if not isinstance(frame_ids, list):
            raise ValueError(f"{path}.key_frame_ids: expected array or null")
        if len(frame_ids) != len(keys):
            raise ValueError(f"{path}: key_frame_ids count must match keys count")
        if any(not isinstance(frame, int) or isinstance(frame, bool) or frame < 0 for frame in frame_ids):
            raise ValueError(f"{path}.key_frame_ids: expected non-negative integers")
        if frame_ids != sorted(frame_ids):
            raise ValueError(f"{path}.key_frame_ids: frames must be non-decreasing")
    _finite_numbers(keys, f"{path}.keys")
    return len(keys)


def validate_animation(animation: dict[str, Any]) -> dict[str, int]:
    if not isinstance(animation, dict):
        raise ValueError("$.animation: expected object")
    start = animation.get("anim_start")
    end = animation.get("anim_end")
    fps = animation.get("anim_fps")
    tracks = animation.get("bone_tracks")
    if not isinstance(start, int) or isinstance(start, bool) or start < 0:
        raise ValueError("$.animation.anim_start: expected non-negative integer")
    if end is not None and (not isinstance(end, int) or isinstance(end, bool) or end < start):
        raise ValueError("$.animation.anim_end: expected null or integer >= anim_start")
    if not isinstance(fps, int) or isinstance(fps, bool) or fps <= 0:
        raise ValueError("$.animation.anim_fps: expected positive integer")
    if not isinstance(tracks, list):
        raise ValueError("$.animation.bone_tracks: expected array")
    total_keys = 0
    seen_bones: set[int] = set()
    for index, item in enumerate(tracks):
        path = f"$.animation.bone_tracks[{index}]"
        if not isinstance(item, dict):
            raise ValueError(f"{path}: expected object")
        bone_id = item.get("bone_id")
        if not isinstance(bone_id, int) or isinstance(bone_id, bool) or bone_id < 0:
            raise ValueError(f"{path}.bone_id: expected non-negative integer")
        if bone_id in seen_bones:
            raise ValueError(f"{path}.bone_id: duplicate bone track {bone_id}")
        seen_bones.add(bone_id)
        total_keys += validate_track(item.get("position"), f"{path}.position")
        total_keys += validate_track(item.get("rotation"), f"{path}.rotation")
    return {"tracks": len(tracks), "keys": total_keys}


def validate_payload(payload: dict[str, Any]) -> dict[str, int]:
    if not isinstance(payload, dict) or payload.get("schema_version") != 1:
        raise ValueError("$: unsupported or missing schema_version (expected 1)")
    kind = payload.get("kind")
    if kind == "stck":
        return validate_animation(payload.get("animation"))
    if kind == "bon":
        bones = payload.get("bones")
        if not isinstance(bones, list) or not bones:
            raise ValueError("$.bones: expected non-empty array")
        for index, bone in enumerate(bones):
            if not isinstance(bone, dict):
                raise ValueError(f"$.bones[{index}]: expected object")
            if not isinstance(bone.get("name"), str) or not bone["name"]:
                raise ValueError(f"$.bones[{index}].name: expected non-empty string")
            parent = bone.get("parent")
            if not isinstance(parent, int) or isinstance(parent, bool) or parent < -1 or parent >= len(bones) or parent == index:
                raise ValueError(f"$.bones[{index}].parent: invalid parent index")
            for matrix_name in ("mat_relative", "mat_bone_init"):
                matrix = bone.get(matrix_name)
                if not isinstance(matrix, list) or len(matrix) != 16:
                    raise ValueError(f"$.bones[{index}].{matrix_name}: expected 16 values")
                _finite_numbers(matrix, f"$.bones[{index}].{matrix_name}")
        embedded = payload.get("embedded_animation")
        if embedded is not None:
            return validate_animation(embedded)
        return {"bones": len(bones), "tracks": 0, "keys": 0}
    raise ValueError("$.kind: expected 'bon' or 'stck'")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_file", type=Path)
    args = parser.parse_args()
    try:
        payload = json.loads(args.json_file.read_text(encoding="utf-8"))
        stats = validate_payload(payload)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        parser.error(str(exc))
    summary = " ".join(f"{key}={value}" for key, value in stats.items())
    print(f"ANGELICA_RIG_JSON_VALIDATION_PASS kind={payload['kind']} {summary}")
    print("NOTE: structural validation only; real-client coordinate and playback verification remains outstanding.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
