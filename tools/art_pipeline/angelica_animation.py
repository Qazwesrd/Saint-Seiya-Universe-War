"""Pure-Python helpers for mapping Angelica STCK tracks to timeline samples.

Coordinate basis and interpolation semantics still require calibration against
an authentic client animation. This module only handles scalar layout/timing.
"""
from __future__ import annotations

from typing import Any


def unpack_track_keys(track: dict[str, Any], components: int, label: str) -> list[tuple[int, tuple[float, ...]]]:
    values = track.get("keys")
    if not isinstance(values, list) or len(values) % components:
        raise ValueError(f"{label}.keys must contain a multiple of {components} floats")
    count = len(values) // components
    frames = track.get("key_frame_ids")
    if frames is None:
        frames = list(range(count))
    if not isinstance(frames, list) or len(frames) != count:
        raise ValueError(f"{label}.key_frame_ids count does not match key count")
    if any(not isinstance(frame, int) or isinstance(frame, bool) or frame < 0 for frame in frames):
        raise ValueError(f"{label}.key_frame_ids must contain non-negative integers")
    if frames != sorted(frames):
        raise ValueError(f"{label}.key_frame_ids must be non-decreasing")
    result = []
    for index, frame in enumerate(frames):
        chunk = tuple(float(value) for value in values[index * components:(index + 1) * components])
        result.append((frame, chunk))
    return result


def frame_for_key(
    key_frame_id: int,
    *,
    anim_start: int,
    anim_fps: int,
    track_fps: int,
    scene_fps: float,
) -> float:
    if anim_fps <= 0 or track_fps <= 0 or scene_fps <= 0:
        raise ValueError("animation, track and scene frame rates must be positive")
    # anim_start is expressed in animation frames; key_frame_id is expressed
    # in the track's frame domain. Convert both through seconds to Blender frames.
    seconds = anim_start / float(anim_fps) + key_frame_id / float(track_fps)
    return 1.0 + seconds * float(scene_fps)


def xyzw_to_wxyz(values: tuple[float, ...]) -> tuple[float, float, float, float]:
    if len(values) != 4:
        raise ValueError("Angelica rotation key must contain XYZW")
    x, y, z, w = values
    return (w, x, y, z)
