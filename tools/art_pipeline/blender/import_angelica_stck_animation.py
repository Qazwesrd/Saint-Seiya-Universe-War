#!/usr/bin/env python3
"""Apply an experimental Angelica STCK JSON animation to a Blender rig preview.

Run with Blender:
  blender --background rigged_preview.blend --python import_angelica_stck_animation.py -- \
    --bon skeleton.json --stck idle.json --output animated_preview.blend

This imports key samples only. Coordinate basis, interpolation modes, bind pose,
and animation event timing need authentic game samples before production use.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Quaternion

from angelica_animation import frame_for_key, unpack_track_keys, xyzw_to_wxyz


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bon", required=True, type=Path, help="Matching BON JSON used to map bone indices")
    parser.add_argument("--stck", required=True, type=Path, help="STCK JSON from export_angelica_rig_json.py")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--action-name", default="", help="Optional Blender action name")
    return parser.parse_args(argv)


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict) or value.get("schema_version") != 1:
        raise ValueError(f"Unsupported JSON schema: {path}")
    return value


def main() -> int:
    args = parse_args()
    bon = load_json(args.bon.expanduser().resolve(strict=True))
    stck = load_json(args.stck.expanduser().resolve(strict=True))
    if bon.get("kind") != "bon" or stck.get("kind") != "stck":
        raise ValueError("--bon must be BON JSON and --stck must be STCK JSON")
    bones = bon.get("bones", [])
    animation = stck.get("animation", {})
    tracks = animation.get("bone_tracks", [])
    if not bones or not tracks:
        raise ValueError("BON skeleton and STCK bone_tracks must not be empty")

    armature = next((obj for obj in bpy.data.objects if obj.type == "ARMATURE"), None)
    if armature is None:
        raise RuntimeError("No Armature found in the opened .blend file")
    if len(bones) != len(armature.data.bones):
        raise ValueError("BON bone count does not match the Armature in the opened .blend file")

    pose_by_index = {}
    for bone in armature.data.bones:
        if "angelica_index" in bone:
            pose_by_index[int(bone["angelica_index"])] = armature.pose.bones.get(bone.name)
    if not pose_by_index:
        pose_by_index = {index: armature.pose.bones.get(str(item.get("name") or f"Bone_{index}"))
                         for index, item in enumerate(bones)}

    scene = bpy.context.scene
    scene_fps = scene.render.fps / scene.render.fps_base
    anim_start = int(animation.get("anim_start", 0))
    anim_fps = int(animation.get("anim_fps", 0))
    if anim_fps <= 0:
        raise ValueError("STCK anim_fps must be positive")

    action_name = args.action_name.strip() or Path(stck.get("source_entry", "Angelica_STCK")).stem
    action = bpy.data.actions.new(action_name)
    armature.animation_data_create()
    armature.animation_data.action = action
    scene.frame_start = 1

    inserted = 0
    max_frame = 1.0
    for track_index, track in enumerate(tracks):
        bone_index = int(track.get("bone_id", -1))
        pose_bone = pose_by_index.get(bone_index)
        if pose_bone is None:
            raise ValueError(f"STCK references missing BON bone index {bone_index}")
        position_keys = unpack_track_keys(track.get("position", {}), 3, f"bone[{bone_index}].position")
        rotation_keys = unpack_track_keys(track.get("rotation", {}), 4, f"bone[{bone_index}].rotation")

        pose_bone.rotation_mode = "QUATERNION"
        for key_id, values in position_keys:
            frame = frame_for_key(
                key_id, anim_start=anim_start, anim_fps=anim_fps,
                track_fps=int(track["position"]["frame_rate"]), scene_fps=scene_fps,
            )
            if not all(math.isfinite(value) for value in values):
                raise ValueError(f"Non-finite position value in bone {bone_index}")
            pose_bone.location = values
            pose_bone.keyframe_insert(data_path="location", frame=frame, group=pose_bone.name)
            max_frame = max(max_frame, frame)
            inserted += 1

        for key_id, values in rotation_keys:
            frame = frame_for_key(
                key_id, anim_start=anim_start, anim_fps=anim_fps,
                track_fps=int(track["rotation"]["frame_rate"]), scene_fps=scene_fps,
            )
            if not all(math.isfinite(value) for value in values):
                raise ValueError(f"Non-finite rotation value in bone {bone_index}")
            wxyz = xyzw_to_wxyz(values)
            quaternion = Quaternion(wxyz)
            if quaternion.length < 1e-8:
                raise ValueError(f"Zero-length rotation quaternion in bone {bone_index}")
            pose_bone.rotation_quaternion = quaternion.normalized()
            pose_bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=pose_bone.name)
            max_frame = max(max_frame, frame)
            inserted += 1

    scene.frame_end = max(scene.frame_start, math.ceil(max_frame))
    scene.frame_set(scene.frame_start)
    args.output.expanduser().resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.expanduser().resolve()))
    print(f"ANGELICA_STCK_ACTION_CREATED action={action.name} bones={len(tracks)} keys={inserted}")
    print("NOTE: key samples imported; coordinate basis and playback fidelity are not validated against original client data.")
    print(f"BLEND {args.output.expanduser().resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
