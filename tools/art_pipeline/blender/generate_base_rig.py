"""Generate a rigged stylized humanoid blockout and modular armor kit.
Run with Blender 4.x:
blender --background --python tools/art_pipeline/blender/generate_base_rig.py
Outputs are prototypes, not final profession-specific art.
"""
import json
import math
import os
import struct
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "game" / "assets" / "_source_templates"
CHARACTER = OUT / "humanoid_base"
ARMOR = OUT / "modular_armor_kit"
ANIMATIONS = OUT / "humanoid_animation_library"
REQUIRED_CLIPS = (
    "idle", "walk", "run", "jump", "fall", "land",
    "basic_attack_1", "basic_attack_2", "basic_attack_3",
    "skill_cast", "hit_light", "hit_heavy", "dodge", "block",
    "victory", "defeat", "phase_shift",
)

def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.actions):
        for item in list(datablocks):
            if item.users == 0:
                datablocks.remove(item)

def material(name, color, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

SKIN = material("Prototype_Skin", (0.48, 0.29, 0.20), 0.0, 0.68)
CLOTH = material("Prototype_Undersuit", (0.075, 0.10, 0.16), 0.05, 0.78)
ARMOR_MAT = material("Prototype_Armor_Silver", (0.48, 0.58, 0.68), 0.78, 0.28)
GOLD = material("Prototype_Armor_Gold", (0.78, 0.48, 0.12), 0.82, 0.24)
ACCENT = material("Prototype_Accent", (0.12, 0.48, 0.72), 0.45, 0.3)
HAIR = material("Prototype_Hair_Midnight", (0.035, 0.055, 0.11), 0.08, 0.42)
EYE_WHITE = material("Prototype_Eye_White", (0.88, 0.91, 0.96), 0.02, 0.3)
EYE_IRIS = material("Prototype_Eye_Cosmic_Blue", (0.025, 0.28, 0.72), 0.28, 0.22)
EYE_PUPIL = material("Prototype_Eye_Pupil", (0.008, 0.012, 0.025), 0.0, 0.18)

def create_rig():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.object
    rig.name = "Humanoid_Base_Rig"
    rig.data.name = "Humanoid_Base_Skeleton"
    edit = rig.data.edit_bones
    for bone in list(edit):
        edit.remove(bone)

    bones = {
        "Root": ((0, 0, 0.05), (0, 0, 0.25), None),
        "Hips": ((0, 0, 0.88), (0, 0, 1.08), "Root"),
        "Spine": ((0, 0, 1.08), (0, 0, 1.34), "Hips"),
        "Chest": ((0, 0, 1.34), (0, 0, 1.55), "Spine"),
        "Neck": ((0, 0, 1.55), (0, 0, 1.68), "Chest"),
        "Head": ((0, 0, 1.68), (0, 0, 1.91), "Neck"),
        "LeftShoulder": ((0.17, 0, 1.48), (0.34, 0, 1.48), "Chest"),
        "RightShoulder": ((-0.17, 0, 1.48), (-0.34, 0, 1.48), "Chest"),
        "LeftUpperArm": ((0.34, 0, 1.48), (0.48, 0, 1.22), "LeftShoulder"),
        "RightUpperArm": ((-0.34, 0, 1.48), (-0.48, 0, 1.22), "RightShoulder"),
        "LeftForearm": ((0.48, 0, 1.22), (0.50, 0, 0.98), "LeftUpperArm"),
        "RightForearm": ((-0.48, 0, 1.22), (-0.50, 0, 0.98), "RightUpperArm"),
        "LeftHand": ((0.50, 0, 0.98), (0.50, 0, 0.87), "LeftForearm"),
        "RightHand": ((-0.50, 0, 0.98), (-0.50, 0, 0.87), "RightForearm"),
        "LeftThigh": ((0.13, 0, 0.88), (0.15, 0, 0.49), "Hips"),
        "RightThigh": ((-0.13, 0, 0.88), (-0.15, 0, 0.49), "Hips"),
        "LeftShin": ((0.15, 0, 0.49), (0.15, 0, 0.12), "LeftThigh"),
        "RightShin": ((-0.15, 0, 0.49), (-0.15, 0, 0.12), "RightThigh"),
        "LeftFoot": ((0.15, 0, 0.12), (0.15, -0.18, 0.07), "LeftShin"),
        "RightFoot": ((-0.15, 0, 0.12), (-0.15, -0.18, 0.07), "RightShin"),
    }
    for name, (head, tail, parent) in bones.items():
        bone = edit.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = edit[parent]
            bone.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    rig.data.display_type = "OCTAHEDRAL"
    return rig

def add_weighted_ellipsoid(name, location, scale, bone_name, mat, rig, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Armature", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    return obj

def add_weighted_limb(name, start, end, radius, bone_name, mat, rig, vertices=12):
    a, b = Vector(start), Vector(end)
    direction = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=direction.length, location=(a + b) / 2)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    bevel = obj.modifiers.new("Soft_Edges", "BEVEL")
    bevel.width = radius * 0.22
    bevel.segments = 2
    obj.data.materials.append(mat)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Armature", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    return obj

def join_meshes(objects, name, rig):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    merged = bpy.context.object
    merged.name = name
    for mod in list(merged.modifiers):
        if mod.type == "ARMATURE":
            merged.modifiers.remove(mod)
    mod = merged.modifiers.new("Humanoid_Skin", "ARMATURE")
    mod.object = rig
    return merged

def build_body(rig):
    parts = []
    parts.append(add_weighted_ellipsoid("Pelvis", (0, 0, 0.91), (0.22, 0.14, 0.17), "Hips", CLOTH, rig))
    parts.append(add_weighted_ellipsoid("Torso", (0, 0, 1.31), (0.27, 0.15, 0.39), "Chest", CLOTH, rig))
    parts.append(add_weighted_ellipsoid("NeckMesh", (0, 0, 1.61), (0.075, 0.075, 0.11), "Neck", SKIN, rig))
    parts.append(add_weighted_ellipsoid("HeadMesh", (0, 0, 1.79), (0.14, 0.13, 0.19), "Head", SKIN, rig))
    # Stylized anime-hero face and hair details. All pieces follow the Head bone.
    # The face looks toward -Y, matching the game's forward-facing character convention.
    parts.append(add_weighted_ellipsoid("Hair_Cap", (0, 0.012, 1.925), (0.153, 0.145, 0.105), "Head", HAIR, rig, 20, 12))
    parts.append(add_weighted_ellipsoid("Hair_Front_Sweep", (0, -0.105, 1.875), (0.145, 0.075, 0.075), "Head", HAIR, rig, 20, 12))
    parts.append(add_weighted_ellipsoid("Hair_Left_Lock", (0.105, -0.075, 1.82), (0.055, 0.065, 0.13), "Head", HAIR, rig, 14, 10))
    parts.append(add_weighted_ellipsoid("Hair_Right_Lock", (-0.105, -0.075, 1.82), (0.055, 0.065, 0.13), "Head", HAIR, rig, 14, 10))
    # Three swept crown locks create a recognizable silhouette instead of a smooth sphere.
    parts.append(add_weighted_ellipsoid("Hair_Crown_Lock_Center", (0, 0.005, 2.015), (0.045, 0.075, 0.12), "Head", HAIR, rig, 14, 10))
    parts.append(add_weighted_ellipsoid("Hair_Crown_Lock_Left", (0.075, 0.015, 1.995), (0.045, 0.07, 0.095), "Head", HAIR, rig, 14, 10))
    parts.append(add_weighted_ellipsoid("Hair_Crown_Lock_Right", (-0.075, 0.015, 1.995), (0.045, 0.07, 0.095), "Head", HAIR, rig, 14, 10))
    for side, sign in (("Left", 1), ("Right", -1)):
        parts.append(add_weighted_ellipsoid(side + "Eye_White", (sign * 0.052, -0.119, 1.815), (0.031, 0.018, 0.019), "Head", EYE_WHITE, rig, 16, 10))
        parts.append(add_weighted_ellipsoid(side + "Eye_Iris", (sign * 0.052, -0.135, 1.815), (0.014, 0.008, 0.015), "Head", EYE_IRIS, rig, 12, 8))
        parts.append(add_weighted_ellipsoid(side + "Eye_Pupil", (sign * 0.052, -0.142, 1.815), (0.006, 0.004, 0.010), "Head", EYE_PUPIL, rig, 10, 8))
        parts.append(add_weighted_ellipsoid(side + "Eyebrow", (sign * 0.053, -0.119, 1.85), (0.038, 0.012, 0.009), "Head", HAIR, rig, 14, 8))
        parts.append(add_weighted_ellipsoid(side + "Ear", (sign * 0.143, -0.005, 1.79), (0.026, 0.035, 0.052), "Head", SKIN, rig, 12, 8))
    parts.append(add_weighted_ellipsoid("Nose_Bridge", (0, -0.132, 1.79), (0.018, 0.026, 0.042), "Head", SKIN, rig, 12, 8))
    parts.append(add_weighted_ellipsoid("Nose_Tip", (0, -0.151, 1.772), (0.022, 0.019, 0.016), "Head", SKIN, rig, 12, 8))
    for side, sign in (("Left", 1), ("Right", -1)):
        x = lambda v: v * sign
        parts.append(add_weighted_ellipsoid(side + "ShoulderMesh", (x(0.31), 0, 1.47), (0.14, 0.14, 0.14), side + "Shoulder", CLOTH, rig))
        parts.append(add_weighted_limb(side + "UpperArmMesh", (x(0.34), 0, 1.45), (x(0.48), 0, 1.22), 0.075, side + "UpperArm", SKIN, rig))
        parts.append(add_weighted_limb(side + "ForearmMesh", (x(0.48), 0, 1.22), (x(0.50), 0, 0.98), 0.062, side + "Forearm", SKIN, rig))
        parts.append(add_weighted_ellipsoid(side + "HandMesh", (x(0.50), -0.01, 0.92), (0.065, 0.045, 0.09), side + "Hand", SKIN, rig))
        parts.append(add_weighted_limb(side + "ThighMesh", (x(0.13), 0, 0.88), (x(0.15), 0, 0.49), 0.105, side + "Thigh", CLOTH, rig))
        parts.append(add_weighted_limb(side + "ShinMesh", (x(0.15), 0, 0.49), (x(0.15), 0, 0.12), 0.075, side + "Shin", CLOTH, rig))
        parts.append(add_weighted_ellipsoid(side + "FootMesh", (x(0.15), -0.10, 0.08), (0.075, 0.15, 0.065), side + "Foot", CLOTH, rig))
    return join_meshes(parts, "Humanoid_Base_Mesh", rig)

def armor_piece(name, location, scale, bone_name, rig, mat=ARMOR_MAT):
    obj = add_weighted_ellipsoid(name, location, scale, bone_name, mat, rig, segments=12, rings=8)
    return obj

def build_armor(rig):
    # Keep every armor component as its own mesh object. Joining these objects
    # would make the exported kit impossible to equip/remove piece by piece.
    parts = []
    parts.append(armor_piece("Armor_Helmet", (0, -0.005, 1.83), (0.16, 0.145, 0.19), "Head", rig, GOLD))
    parts.append(armor_piece("Armor_Chest", (0, -0.13, 1.36), (0.29, 0.075, 0.27), "Chest", rig, GOLD))
    for side, sign in (("Left", 1), ("Right", -1)):
        x = lambda v: v * sign
        parts.append(armor_piece("Armor_" + side + "_Shoulder", (x(0.33), -0.02, 1.48), (0.17, 0.16, 0.12), side + "Shoulder", rig, GOLD))
        parts.append(armor_piece("Armor_" + side + "_Forearm", (x(0.49), -0.01, 1.10), (0.075, 0.085, 0.17), side + "Forearm", rig, ARMOR_MAT))
        parts.append(armor_piece("Armor_" + side + "_Leg", (x(0.15), -0.01, 0.34), (0.095, 0.105, 0.20), side + "Shin", rig, ARMOR_MAT))
    parts.append(armor_piece("Armor_Waist", (0, -0.11, 0.94), (0.25, 0.09, 0.12), "Hips", rig, GOLD))
    return parts
def key_pose(rig, frame, values):
    for bone_name, rotation in values.items():
        bone = rig.pose.bones[bone_name]
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = rotation
        bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)

PROFESSION_COMBO_STYLES = {
    "pegasus": "rush", "dragon": "guard_break", "cygnus": "frost",
    "andromeda": "chain", "phoenix": "flame", "sea_dragon": "tidal",
    "tenmou": "heavy", "lyra": "resonance", "sea_swallow": "flow",
    "tenkishi": "aerial", "apollo": "solar", "abel": "solar",
    "athena": "guard", "hades": "reaper", "poseidon": "tidal",
    "zeus": "storm", "artemis": "ranged", "hypnos": "dream",
    "thanatos": "reaper", "odin": "rune", "ares": "heavy",
    "eris": "chaos", "lucifer": "fallen", "saturn": "chrono",
    "pallas": "chrono", "chronos": "chrono", "hera": "royal",
    "demeter": "nature", "hestia": "flame", "hermes": "rush",
    "hephaestus": "heavy", "aphrodite": "grace",
}

# Arm swing, forearm fold, torso twist, hip twist, support-arm pose, leg drive.
COMBO_STYLE_POSES = {
    "rush": (0.98, -0.34, -0.22, 0.16, -0.30, 0.15),
    "guard_break": (1.12, -0.72, -0.30, 0.24, -0.86, 0.30),
    "frost": (0.78, -0.52, -0.42, 0.20, 0.45, -0.18),
    "chain": (0.56, -1.08, -0.50, 0.28, 0.95, -0.20),
    "flame": (1.25, -0.65, -0.55, 0.35, -0.75, 0.35),
    "tidal": (0.90, -0.35, 0.50, -0.32, 0.55, -0.22),
    "heavy": (1.42, -0.20, -0.28, 0.20, -0.25, 0.50),
    "resonance": (0.65, -0.88, 0.45, -0.25, 1.10, -0.12),
    "flow": (0.82, -0.50, 0.65, -0.40, -0.40, 0.10),
    "aerial": (1.05, -0.42, -0.15, 0.10, 0.82, -0.60),
    "solar": (1.18, -0.56, -0.40, 0.25, 0.86, 0.10),
    "guard": (0.52, -0.92, -0.20, 0.10, -1.12, 0.25),
    "reaper": (1.36, -0.16, 0.60, -0.40, -0.92, 0.35),
    "storm": (1.30, -0.42, -0.60, 0.40, 0.65, 0.25),
    "ranged": (0.62, -1.12, 0.20, -0.10, 0.96, -0.10),
    "dream": (0.56, -0.72, 0.35, -0.25, 0.82, -0.20),
    "rune": (0.86, -0.62, -0.35, 0.20, 0.72, 0.20),
    "chaos": (1.12, -0.92, 0.70, -0.50, -0.62, 0.35),
    "fallen": (1.22, -0.56, 0.60, -0.45, -0.72, 0.40),
    "chrono": (0.92, -0.72, 0.10, 0.35, 0.72, -0.25),
    "royal": (0.86, -0.82, -0.30, 0.15, 1.02, -0.10),
    "nature": (0.72, -0.76, 0.35, -0.20, 0.82, 0.10),
    "grace": (0.76, -0.92, 0.55, -0.35, 1.06, -0.12),
}

def make_profession_combo_animations(rig, profession_id):
    """Author three genuinely different skeletal combo clips for one profession."""
    import hashlib
    import json

    style = PROFESSION_COMBO_STYLES.get(profession_id, "rush")
    arm, forearm, torso, hips, support, leg = COMBO_STYLE_POSES[style]
    signatures = {}
    scene = bpy.context.scene
    for step, step_scale in enumerate((0.86, 1.0, 1.24), start=1):
        clip_name = f"{profession_id}_basic_attack_{step}"
        action = bpy.data.actions.new(name=clip_name)
        if rig.animation_data is None:
            rig.animation_data_create()
        rig.animation_data.action = action
        scene.frame_set(1)
        neutral = {bone.name: (0.0, 0.0, 0.0) for bone in rig.pose.bones}
        key_pose(rig, 1, neutral)
        # Blender 5 layered Actions do not expose the legacy Action.fcurves API.
        authored_keyframes = [{"frame": 1, "pose": neutral}]

        primary = "Right" if step in (1, 3) else "Left"
        secondary = "Left" if primary == "Right" else "Right"
        mirror = 1.0 if primary == "Right" else -1.0
        # Profession index gives each member of a shared archetype a small,
        # deterministic articulation signature without changing its identity.
        seed = sum((index + 1) * ord(char) for index, char in enumerate(profession_id))
        variation = 1.0 + ((seed % 9) - 4) * 0.012
        a = arm * step_scale * variation
        f = forearm * step_scale
        t = torso * step_scale
        h = hips * step_scale
        s = support * step_scale
        l = leg * step_scale

        windup = {
            primary + "UpperArm": (-0.62 * step_scale, 0.0, 0.12 * mirror),
            primary + "Forearm": (-0.48 * step_scale, 0.0, 0.0),
            "Chest": (-0.12 * step_scale, 0.0, -0.08 * mirror),
            "Hips": (0.08 * step_scale, 0.0, -0.05 * mirror),
        }
        impact = {
            primary + "UpperArm": (a, 0.0, 0.10 * mirror * step_scale),
            primary + "Forearm": (f, 0.0, -0.06 * mirror),
            secondary + "UpperArm": (s, 0.0, 0.08 * mirror),
            secondary + "Forearm": (-0.22 * step_scale, 0.0, 0.0),
            "Chest": (0.08 * step_scale, 0.0, t),
            "Spine": (0.0, 0.0, t * 0.28),
            "Hips": (0.0, 0.0, h),
            primary + "Thigh": (-l, 0.0, 0.0),
            secondary + "Thigh": (l * 0.42, 0.0, 0.0),
        }
        follow = {
            primary + "UpperArm": (a * 0.42, 0.0, 0.06 * mirror),
            primary + "Forearm": (f * 0.34, 0.0, 0.0),
            secondary + "UpperArm": (s * 0.52, 0.0, 0.0),
            "Chest": (0.04, 0.0, t * 0.48),
            "Hips": (0.0, 0.0, h * 0.45),
            primary + "Thigh": (-l * 0.35, 0.0, 0.0),
        }
        key_pose(rig, 6, windup)
        authored_keyframes.append({"frame": 6, "pose": windup})
        key_pose(rig, 11, impact)
        authored_keyframes.append({"frame": 11, "pose": impact})
        key_pose(rig, 17, follow)
        authored_keyframes.append({"frame": 17, "pose": follow})
        key_pose(rig, 24, neutral)
        authored_keyframes.append({"frame": 24, "pose": neutral})

        scene.frame_start, scene.frame_end = 1, 24
        track = rig.animation_data.nla_tracks.new()
        track.name = clip_name
        strip = track.strips.new(clip_name, 1, action)
        strip.name = clip_name
        # Fingerprint the authored skeletal keyframe payload, not the clip name.
        # This remains compatible with Blender 4.x and Blender 5 layered Actions.
        payload = {
            "profession": profession_id,
            "clip": clip_name,
            "keyframes": authored_keyframes,
        }
        signatures[clip_name] = hashlib.sha256(
            json.dumps(payload, sort_keys=True).encode("utf-8")
        ).hexdigest()
        rig.animation_data.action = None
    scene.frame_set(1)
    if len(set(signatures.values())) != 3:
        raise RuntimeError(f"{profession_id}: combo clips do not contain distinct keyframe data")
    return signatures

def profession_ability_ids(profession_id):
    """Read the exact 24 ability IDs per profession from the gameplay catalog."""
    import re
    source_path = ROOT / "game" / "scripts" / "skill_system.gd"
    source = source_path.read_text(encoding="utf-8")
    all_ids = re.findall(r'"id"\s*:\s*"([^"]+)"', source)
    prefix = profession_id + "_"
    ability_ids = list(dict.fromkeys(ability_id for ability_id in all_ids if ability_id.startswith(prefix)))
    if len(ability_ids) != 24:
        raise RuntimeError(
            f"{profession_id}: expected 24 catalog abilities, found {len(ability_ids)}: {ability_ids}"
        )
    return ability_ids


def make_profession_skill_animations(rig, profession_id):
    """Author seven profession-styled skeletal skill archetypes for runtime ability routing."""
    style = PROFESSION_COMBO_STYLES.get(profession_id, "rush")
    arm, forearm, torso, hips, support, leg = COMBO_STYLE_POSES[style]
    seed = sum((index + 1) * ord(char) for index, char in enumerate(profession_id))
    variation = 1.0 + ((seed % 11) - 5) * 0.009
    archetypes = {
        "melee": {
            "windup": {"RightUpperArm": (-0.72, 0.0, -0.12), "RightForearm": (-0.42, 0.0, 0.0), "Chest": (-0.12, 0.0, 0.12)},
            "impact": {"RightUpperArm": (arm * variation, 0.0, 0.12), "RightForearm": (forearm, 0.0, -0.08), "LeftUpperArm": (support, 0.0, 0.06), "Chest": (0.10, 0.0, torso), "Hips": (0.0, 0.0, hips)},
        },
        "projectile": {
            "windup": {"RightUpperArm": (-1.35, 0.0, -0.18), "LeftUpperArm": (-0.95, 0.0, 0.18), "Chest": (-0.18, 0.0, 0.0)},
            "impact": {"RightUpperArm": (-0.22 * variation, 0.0, -0.08), "RightForearm": (-1.18, 0.0, 0.0), "LeftUpperArm": (-0.42, 0.0, 0.08), "LeftForearm": (-0.92, 0.0, 0.0), "Chest": (0.12, 0.0, torso * 0.55)},
        },
        "defense": {
            "windup": {"LeftUpperArm": (-0.65, 0.0, -0.22), "RightUpperArm": (-0.65, 0.0, 0.22), "Hips": (0.18, 0.0, 0.0)},
            "impact": {"LeftUpperArm": (-1.25, 0.0, -0.28), "LeftForearm": (-0.82, 0.0, 0.0), "RightUpperArm": (-1.18, 0.0, 0.28), "RightForearm": (-0.78, 0.0, 0.0), "Chest": (0.18, 0.0, -0.08), "Hips": (0.24, 0.0, 0.0)},
        },
        "heal": {
            "windup": {"LeftUpperArm": (-0.72, 0.0, -0.35), "RightUpperArm": (-0.72, 0.0, 0.35), "Head": (-0.12, 0.0, 0.0)},
            "impact": {"LeftUpperArm": (-1.62, 0.0, -0.42), "LeftForearm": (-0.58, 0.0, 0.0), "RightUpperArm": (-1.62, 0.0, 0.42), "RightForearm": (-0.58, 0.0, 0.0), "Chest": (-0.18, 0.0, 0.0), "Head": (0.10, 0.0, 0.0)},
        },
        "area": {
            "windup": {"LeftUpperArm": (-0.92, 0.0, -0.58), "RightUpperArm": (-0.92, 0.0, 0.58), "Chest": (-0.12, 0.0, 0.0)},
            "impact": {"LeftUpperArm": (-1.62, 0.0, -0.82), "RightUpperArm": (-1.62, 0.0, 0.82), "LeftForearm": (-0.35, 0.0, 0.0), "RightForearm": (-0.35, 0.0, 0.0), "Chest": (0.12, 0.0, torso), "Hips": (0.0, 0.0, hips * 0.7)},
        },
        "mobility": {
            "windup": {"RightUpperArm": (-0.42, 0.0, -0.18), "LeftUpperArm": (0.22, 0.0, 0.12), "RightThigh": (-0.42, 0.0, 0.0)},
            "impact": {"RightUpperArm": (0.68 * variation, 0.0, -0.18), "LeftUpperArm": (-0.62, 0.0, 0.12), "RightThigh": (-leg * 1.35, 0.0, 0.0), "LeftThigh": (leg * 0.72, 0.0, 0.0), "Chest": (0.18, 0.0, torso * 0.6), "Hips": (0.0, 0.0, hips)},
        },
        "ultimate": {
            "windup": {"LeftUpperArm": (-1.75, 0.0, -0.62), "RightUpperArm": (-1.75, 0.0, 0.62), "Chest": (-0.28, 0.0, 0.0), "Hips": (-0.16, 0.0, 0.0)},
            "impact": {"LeftUpperArm": (-2.05, 0.0, -0.88), "RightUpperArm": (-2.05, 0.0, 0.88), "LeftForearm": (-0.72, 0.0, -0.18), "RightForearm": (-0.72, 0.0, 0.18), "Chest": (-0.18, 0.0, torso * 1.25), "Spine": (-0.10, 0.0, torso * 0.45), "Hips": (0.0, 0.0, hips * 0.8), "LeftThigh": (-leg * 0.55, 0.0, 0.0), "RightThigh": (-leg * 0.55, 0.0, 0.0)},
        },
    }
    scene = bpy.context.scene
    for category, poses in archetypes.items():
        clip_name = f"{profession_id}_skill_{category}"
        action = bpy.data.actions.new(name=clip_name)
        if rig.animation_data is None:
            rig.animation_data_create()
        rig.animation_data.action = action
        scene.frame_set(1)
        neutral = {bone.name: (0.0, 0.0, 0.0) for bone in rig.pose.bones}
        key_pose(rig, 1, neutral)
        windup = {name: tuple(value * variation for value in rotation) for name, rotation in poses["windup"].items()}
        impact = {name: tuple(value * variation for value in rotation) for name, rotation in poses["impact"].items()}
        key_pose(rig, 6, windup)
        key_pose(rig, 12, impact)
        follow = {name: tuple(value * 0.42 for value in rotation) for name, rotation in impact.items()}
        key_pose(rig, 18, follow)
        key_pose(rig, 24, neutral)
        scene.frame_start, scene.frame_end = 1, 24
        track = rig.animation_data.nla_tracks.new()
        track.name = clip_name
        strip = track.strips.new(clip_name, 1, action)
        strip.name = clip_name
        rig.animation_data.action = None
    # Generate one separate skeletal action for every real ability ID in SkillSystem.
    ability_ids = profession_ability_ids(profession_id)
    category_names = tuple(archetypes.keys())
    for ability_index, ability_id in enumerate(ability_ids):
        category = category_names[ability_index % len(category_names)]
        poses = archetypes[category]
        ability_seed = sum((index + 1) * ord(char) for index, char in enumerate(ability_id))
        ability_variation = 1.0 + ((ability_seed % 19) - 9) * 0.012
        mirrored = -1.0 if ability_seed % 2 else 1.0
        clip_name = ability_id
        action = bpy.data.actions.new(name=clip_name)
        if rig.animation_data is None:
            rig.animation_data_create()
        rig.animation_data.action = action
        scene.frame_set(1)
        neutral = {bone.name: (0.0, 0.0, 0.0) for bone in rig.pose.bones}
        key_pose(rig, 1, neutral)
        windup = {
            name: tuple(value * variation * ability_variation for value in rotation)
            for name, rotation in poses["windup"].items()
        }
        impact = {
            name: tuple(value * variation * ability_variation for value in rotation)
            for name, rotation in poses["impact"].items()
        }
        # ID-seeded asymmetry, torso torque and stance shifts make each clip's
        # skeletal curves distinct instead of merely assigning different names.
        windup["Chest"] = (
            windup.get("Chest", (0.0, 0.0, 0.0))[0] - 0.035 * (ability_index % 4),
            0.025 * mirrored,
            0.045 * mirrored,
        )
        impact["Chest"] = (
            impact.get("Chest", (0.0, 0.0, 0.0))[0] + 0.025 * (ability_index % 5),
            0.035 * mirrored,
            impact.get("Chest", (0.0, 0.0, 0.0))[2] + 0.055 * mirrored,
        )
        impact["Hips"] = (
            impact.get("Hips", (0.0, 0.0, 0.0))[0] + 0.018 * (ability_index % 6),
            0.0,
            0.04 * mirrored,
        )
        key_pose(rig, 5, windup)
        key_pose(rig, 11 + (ability_index % 3), impact)
        follow = {
            name: tuple(value * (0.30 + (ability_index % 4) * 0.045) for value in rotation)
            for name, rotation in impact.items()
        }
        key_pose(rig, 18, follow)
        key_pose(rig, 24, neutral)
        scene.frame_start, scene.frame_end = 1, 24
        track = rig.animation_data.nla_tracks.new()
        track.name = clip_name
        strip = track.strips.new(clip_name, 1, action)
        strip.name = clip_name
        rig.animation_data.action = None
    scene.frame_set(1)


def make_animation_library(rig, profession_id=""):

    scene = bpy.context.scene
    for clip in REQUIRED_CLIPS:
        if rig.animation_data is None:
            rig.animation_data_create()
        action = bpy.data.actions.new(name=clip)
        rig.animation_data.action = action
        scene.frame_set(1)
        # Reset and key every bone so a clip never inherits the previous
        # action's pose on bones that this clip does not animate.
        neutral_pose = {bone.name: (0, 0, 0) for bone in rig.pose.bones}
        key_pose(rig, 1, neutral_pose)
        if clip == "idle":
            for frame, breath in ((1, 0.0), (12, -0.025), (24, 0.0)):
                key_pose(rig, frame, {"Spine": (breath, 0, 0), "Chest": (breath * 0.6, 0, 0)})
        elif clip in ("walk", "run"):
            amount = 0.42 if clip == "walk" else 0.78
            for frame, sign in ((1, 1), (7, -1), (13, 1), (19, -1), (25, 1)):
                key_pose(rig, frame, {
                    "LeftThigh": (amount * sign, 0, 0),
                    "RightThigh": (-amount * sign, 0, 0),
                    "LeftUpperArm": (-amount * sign * 0.7, 0, 0),
                    "RightUpperArm": (amount * sign * 0.7, 0, 0),
                    "Chest": (0.035 if sign > 0 else -0.035, 0, 0),
                })
        elif clip == "jump":
            key_pose(rig, 1, {})
            key_pose(rig, 7, {"LeftThigh": (-0.55, 0, 0), "RightThigh": (-0.55, 0, 0), "LeftUpperArm": (0.45, 0, 0), "RightUpperArm": (0.45, 0, 0)})
            key_pose(rig, 16, {"LeftThigh": (-0.25, 0, 0), "RightThigh": (-0.25, 0, 0), "LeftUpperArm": (0.7, 0, 0), "RightUpperArm": (0.7, 0, 0)})
            key_pose(rig, 24, {})
        elif clip == "fall":
            key_pose(rig, 6, {"Chest": (0.65, 0, 0), "Head": (0.25, 0, 0), "LeftUpperArm": (-0.8, 0, 0), "RightUpperArm": (-0.8, 0, 0)})
            key_pose(rig, 24, {"Chest": (1.1, 0, 0), "Head": (0.45, 0, 0), "LeftUpperArm": (-1.1, 0, 0), "RightUpperArm": (-1.1, 0, 0)})
        elif clip == "land":
            key_pose(rig, 5, {"LeftThigh": (-0.65, 0, 0), "RightThigh": (-0.65, 0, 0), "Chest": (0.25, 0, 0)})
            key_pose(rig, 12, {"LeftThigh": (-0.25, 0, 0), "RightThigh": (-0.25, 0, 0), "Chest": (0.12, 0, 0)})
            key_pose(rig, 24, {})
        elif clip.startswith("basic_attack"):
            factor = (0.55, 0.9, 1.25)[int(clip[-1]) - 1]
            key_pose(rig, 1, {"RightUpperArm": (-0.8, 0, 0)})
            key_pose(rig, 8, {"RightUpperArm": (factor, 0, 0), "Chest": (0, 0, -0.12)})
            key_pose(rig, 16, {"RightUpperArm": (-0.25, 0, 0)})
            key_pose(rig, 24, {"RightUpperArm": (0, 0, 0), "Chest": (0, 0, 0)})
        elif clip == "skill_cast":
            key_pose(rig, 1, {"LeftUpperArm": (-0.2, 0, 0), "RightUpperArm": (-0.2, 0, 0)})
            key_pose(rig, 12, {"LeftUpperArm": (-1.5, 0, 0), "RightUpperArm": (-1.5, 0, 0), "Chest": (-0.1, 0, 0)})
            key_pose(rig, 24, {})
        elif clip in ("hit_light", "hit_heavy"):
            kick = 0.25 if clip == "hit_light" else 0.55
            key_pose(rig, 7, {"Chest": (kick, 0, 0), "Head": (kick * 0.5, 0, 0)})
            key_pose(rig, 24, {})
        elif clip == "dodge":
            key_pose(rig, 8, {"Hips": (0, 0, -0.5), "Chest": (0, 0, -0.25)})
            key_pose(rig, 18, {"Hips": (0, 0, 0.3)})
            key_pose(rig, 24, {})
        elif clip == "block":
            key_pose(rig, 10, {"LeftUpperArm": (-1.0, 0, 0), "RightUpperArm": (-1.0, 0, 0)})
            key_pose(rig, 24, {"LeftUpperArm": (-1.0, 0, 0), "RightUpperArm": (-1.0, 0, 0)})
        elif clip == "victory":
            key_pose(rig, 12, {"LeftUpperArm": (-2.4, 0, 0), "RightUpperArm": (-2.4, 0, 0)})
            key_pose(rig, 24, {"LeftUpperArm": (-2.4, 0, 0), "RightUpperArm": (-2.4, 0, 0)})
        elif clip == "defeat":
            key_pose(rig, 18, {"Chest": (0.8, 0, 0), "Head": (0.4, 0, 0), "Hips": (0.3, 0, 0)})
            key_pose(rig, 24, {"Chest": (0.8, 0, 0), "Head": (0.4, 0, 0), "Hips": (0.3, 0, 0)})
        elif clip == "phase_shift":
            key_pose(rig, 8, {"LeftUpperArm": (-1.1, 0, -0.55), "RightUpperArm": (-1.1, 0, 0.55), "Chest": (-0.22, 0, 0)})
            key_pose(rig, 16, {"LeftUpperArm": (-2.0, 0, -0.85), "RightUpperArm": (-2.0, 0, 0.85), "Chest": (-0.12, 0, 0), "Head": (-0.18, 0, 0)})
            key_pose(rig, 24, {"LeftUpperArm": (-0.4, 0, -0.2), "RightUpperArm": (-0.4, 0, 0.2)})
        else:
            key_pose(rig, 24, {"Spine": (0, 0, 0)})
        scene.frame_start, scene.frame_end = 1, 25 if clip in ("walk", "run") else 24
        track = rig.animation_data.nla_tracks.new()
        track.name = clip
        strip = track.strips.new(clip, 1, action)
        strip.name = clip
        rig.animation_data.action = None
    if profession_id:
        make_profession_combo_animations(rig, profession_id)
        make_profession_skill_animations(rig, profession_id)
    scene.frame_set(1)
def export_glb(path, objects):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB",
        use_selection=True, export_apply=True,
        export_animations=True, export_animation_mode="NLA_TRACKS",
        export_nla_strips=True, export_skins=True,
        export_materials="EXPORT", export_cameras=False, export_lights=False,
    )
    if not path.is_file() or path.stat().st_size < 1024:
        raise RuntimeError("GLB export missing or unexpectedly small: " + str(path))

def validate_glb(path, required_nodes=(), require_skin=False, required_clips=(),
                 require_independent_skinned_nodes=()):
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise RuntimeError("Invalid GLB header: " + str(path))
    version, declared_length = struct.unpack_from("<II", data, 4)
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if version != 2 or declared_length != len(data) or chunk_type != 0x4E4F534A or 20 + chunk_length > len(data):
        raise RuntimeError("Invalid GLB v2 JSON chunk: " + str(path))
    document = json.loads(data[20:20 + chunk_length].decode("utf-8").rstrip(" \\t\\r\\n\\0"))
    node_names = {str(node.get("name", "")) for node in document.get("nodes", [])}
    missing_nodes = sorted(set(required_nodes) - node_names)
    if missing_nodes:
        raise RuntimeError("GLB is missing required nodes: " + ", ".join(missing_nodes))
    if require_skin and not document.get("meshes"):
        raise RuntimeError("Rigged character/armor GLB has no meshes: " + str(path))
    nodes = document.get("nodes", [])
    meshes = document.get("meshes", [])
    skins = document.get("skins", [])
    if require_skin:
        if not skins:
            raise RuntimeError("Rigged character/armor GLB has no skin: " + str(path))
        for node_index, node in enumerate(nodes):
            if "mesh" not in node:
                continue
            mesh_index = node.get("mesh")
            skin_index = node.get("skin")
            if not isinstance(mesh_index, int) or not 0 <= mesh_index < len(meshes):
                raise RuntimeError(f"Mesh node {node_index} references an invalid mesh: {path}")
            if not isinstance(skin_index, int) or not 0 <= skin_index < len(skins):
                raise RuntimeError(f"Mesh node {node_index} is not bound to a valid skin: {path}")
            joints = skins[skin_index].get("joints", [])
            if not joints or any(not isinstance(joint, int) or not 0 <= joint < len(nodes) for joint in joints):
                raise RuntimeError(f"Mesh node {node_index} has invalid skin joints: {path}")
    if require_independent_skinned_nodes:
        by_name = {str(node.get("name", "")): node for node in nodes}
        mesh_indices = []
        for node_name in require_independent_skinned_nodes:
            node = by_name.get(node_name, {})
            mesh_index = node.get("mesh")
            skin_index = node.get("skin")
            if not isinstance(mesh_index, int) or not 0 <= mesh_index < len(meshes):
                raise RuntimeError(f"Armor part is not an independent mesh node: {node_name}")
            if not isinstance(skin_index, int) or not 0 <= skin_index < len(skins):
                raise RuntimeError(f"Armor part is not bound to a valid skin: {node_name}")
            mesh_indices.append(mesh_index)
        if len(set(mesh_indices)) != len(require_independent_skinned_nodes):
            raise RuntimeError("Armor parts do not have unique independent mesh data")
    animations = document.get("animations", [])
    by_clip_name = {str(clip.get("name", "")): clip for clip in animations}
    missing_clips = sorted(set(required_clips) - set(by_clip_name))
    if missing_clips:
        raise RuntimeError("GLB is missing animation clips: " + ", ".join(missing_clips))
    accessors = document.get("accessors", [])
    for clip_name in required_clips:
        clip = by_clip_name[clip_name]
        if not clip.get("channels") or not clip.get("samplers"):
            raise RuntimeError(f"Animation clip has no tracks: {clip_name}")
        for sampler in clip["samplers"]:
            for accessor_key in ("input", "output"):
                accessor_index = sampler.get(accessor_key)
                if not isinstance(accessor_index, int) or not 0 <= accessor_index < len(accessors):
                    raise RuntimeError(f"Animation clip has invalid {accessor_key} accessor: {clip_name}")
        for channel in clip["channels"]:
            target = channel.get("target", {})
            node_index = target.get("node")
            sampler_index = channel.get("sampler")
            if not isinstance(node_index, int) or not 0 <= node_index < len(nodes):
                raise RuntimeError(f"Animation clip has invalid target node: {clip_name}")
            if not isinstance(sampler_index, int) or not 0 <= sampler_index < len(clip["samplers"]):
                raise RuntimeError(f"Animation clip has invalid sampler: {clip_name}")
            if target.get("path") not in ("translation", "rotation", "scale", "weights"):
                raise RuntimeError(f"Animation clip has invalid target path: {clip_name}")
    clip_names = sorted(by_clip_name)
    print("Validated GLB:", path.name, "nodes=", len(node_names), "meshes=", len(document.get("meshes", [])), "clips=", len(clip_names))


CHAPTER_THEMES = (
    "galaxy_wars", "sanctuary_twelve_houses", "asgard",
    "poseidon", "hades", "heaven", "original_final",
)

def build_chapter_environment(theme_id, index):
    """Create a distinct, loadable environment blockout for each campaign chapter."""
    palettes = {
        "galaxy_wars": ((0.10, 0.14, 0.24), (0.72, 0.48, 0.20)),
        "sanctuary_twelve_houses": ((0.48, 0.39, 0.25), (0.92, 0.72, 0.34)),
        "asgard": ((0.28, 0.48, 0.62), (0.72, 0.88, 1.0)),
        "poseidon": ((0.04, 0.25, 0.42), (0.18, 0.72, 0.86)),
        "hades": ((0.16, 0.10, 0.24), (0.58, 0.34, 0.72)),
        "heaven": ((0.42, 0.48, 0.62), (0.96, 0.84, 0.56)),
        "original_final": ((0.12, 0.12, 0.20), (0.92, 0.30, 0.22)),
    }
    ground_color, accent_color = palettes[theme_id]
    ground_mat = material("ENV_" + theme_id + "_Ground", ground_color, 0.22, 0.72)
    accent_mat = material("ENV_" + theme_id + "_Architecture", accent_color, 0.58, 0.32)
    trim_mat = material("ENV_" + theme_id + "_Trim", (0.72, 0.76, 0.82), 0.72, 0.25)
    created = []

    def cube(name, location, scale, mat, bevel=0.0):
        bpy.ops.mesh.primitive_cube_add(size=1, location=location)
        obj = bpy.context.object
        obj.name = name
        obj.dimensions = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        obj.data.materials.append(mat)
        if bevel:
            mod = obj.modifiers.new("Architectural_Edges", "BEVEL")
            mod.width = bevel
            mod.segments = 2
        created.append(obj)
        return obj

    def cylinder(name, location, radius, depth, mat, vertices=16):
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
        obj = bpy.context.object
        obj.name = name
        obj.data.materials.append(mat)
        created.append(obj)
        return obj

    cube(theme_id + "_Ground", (0, 0, -0.28), (24, 24, 0.5), ground_mat, 0.12)
    # A central combat plaza and radial approach paths form a navigable greybox.
    cube(theme_id + "_Central_Arena", (0, 0, 0.02), (8, 8, 0.22), accent_mat, 0.18)
    for arm in range(4):
        angle = arm * math.pi / 2
        obj = cube(theme_id + "_Approach_" + str(arm), (math.sin(angle) * 6.2, math.cos(angle) * 6.2, -0.02), (3.2, 8.0, 0.16), trim_mat, 0.08)
        obj.rotation_euler[2] = -angle

    # Theme-specific landmark silhouette: arena pylons, sanctuary columns,
    # Asgard towers, sea pillars, underworld gates, celestial spires, or a rift.
    for side in (-1, 1):
        for row in range(3):
            x = side * (5.2 + (row % 2) * 0.45)
            y = (row - 1) * 4.0
            height = 2.8 + ((row + index) % 3) * 0.8
            if theme_id == "poseidon":
                cylinder(theme_id + "_Sea_Pillar_" + str(side) + "_" + str(row), (x, y, height / 2), 0.72, height, accent_mat, 12)
                cylinder(theme_id + "_Pillar_Capital_" + str(side) + "_" + str(row), (x, y, height), 1.0, 0.28, trim_mat, 12)
            elif theme_id in ("heaven", "original_final"):
                cylinder(theme_id + "_Spire_" + str(side) + "_" + str(row), (x, y, height / 2), 0.62, height, accent_mat, 8)
                cylinder(theme_id + "_Spire_Crown_" + str(side) + "_" + str(row), (x, y, height + 0.5), 0.22, 1.0, trim_mat, 6)
            else:
                cube(theme_id + "_Landmark_" + str(side) + "_" + str(row), (x, y, height / 2), (1.25, 1.25, height), accent_mat, 0.12)
                cube(theme_id + "_Landmark_Cap_" + str(side) + "_" + str(row), (x, y, height + 0.12), (1.6, 1.6, 0.24), trim_mat, 0.06)

    # A chapter-specific focal structure anchors navigation and boss staging.
    if theme_id == "galaxy_wars":
        for radius in (2.8, 3.3):
            bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=0.10, location=(0, 0, 0.45))
            obj = bpy.context.object
            obj.name = theme_id + "_Tournament_Ring"
            obj.data.materials.append(trim_mat)
            created.append(obj)
    elif theme_id == "sanctuary_twelve_houses":
        for step in range(5):
            cube(theme_id + "_Sanctuary_Stair_" + str(step), (0, -5.0 + step * 0.8, 0.18 + step * 0.28), (5.0 - step * 0.45, 1.0, 0.35), trim_mat, 0.05)
    elif theme_id == "asgard":
        for x in (-1.8, 1.8):
            cylinder(theme_id + "_Odin_Tower", (x, 5.5, 2.6), 0.42, 5.2, accent_mat, 8)
    elif theme_id == "hades":
        cube(theme_id + "_Underworld_Gate", (0, 7.0, 2.4), (5.0, 0.7, 4.8), accent_mat, 0.15)
        cube(theme_id + "_Gate_Opening", (0, 6.58, 1.5), (2.1, 0.18, 3.0), ground_mat)
    else:
        cylinder(theme_id + "_Boss_Podium", (0, 0, 0.55), 2.2, 0.8, trim_mat, 32)

    return created

def export_chapter_environments():
    output_root = ROOT / "game" / "assets" / "environments"
    for index, theme_id in enumerate(CHAPTER_THEMES):
        reset_scene()
        objects = build_chapter_environment(theme_id, index)
        destination = output_root / theme_id / "environment.glb"
        export_glb(destination, objects)
        print("CHAPTER_ENVIRONMENT_EXPORTED", theme_id, destination.stat().st_size)


def catalog_ids(gd_path, marker):
    import re
    source = gd_path.read_text(encoding="utf-8")
    start = source.find(marker)
    if start < 0:
        raise RuntimeError("catalog marker missing: " + marker)
    match = re.search(r"\n(.*?)^\}", source[start:], re.S | re.M)
    if not match:
        raise RuntimeError("catalog block malformed: " + marker)
    return re.findall(r'^\s*"([^"]+)"\s*:\s*\{', match.group(1), re.M)

def render_profession_turntable(profession_id, index):
    """Render three evidence views from the exact generated in-project GLB scene."""
    preview_root = ROOT / "game" / "art_previews" / "characters"
    preview_root.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 960
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_depth = "8"
    scene.render.filepath = str(preview_root / (profession_id + "_front.png"))
    scene.render.image_settings.compression = 15
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "AgX - Medium High Contrast"

    world = bpy.data.worlds.new("Preview_World_" + profession_id) if not bpy.data.worlds else bpy.data.worlds[0]
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.018, 0.026, 0.055, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35

    floor_mat = material("Preview_Floor_" + profession_id, (0.025, 0.035, 0.065), 0.28, 0.42)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.035))
    floor = bpy.context.object
    floor.name = "Preview_Studio_Floor"
    floor.data.materials.append(floor_mat)

    def area_light(name, location, energy, color, size):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.color = color
        data.shape = "DISK"
        data.size = size
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = location
        obj.rotation_euler = (Vector((0, 0, 1.0)) - obj.location).to_track_quat("-Z", "Y").to_euler()
        return obj

    area_light("Preview_Key", (4.2, -4.5, 5.2), 850, (0.78, 0.86, 1.0), 4.0)
    area_light("Preview_Fill", (-4.0, -2.0, 2.8), 520, (0.35, 0.58, 1.0), 3.5)
    area_light("Preview_Rim", (0.5, 3.0, 4.0), 1000, (1.0, 0.58, 0.25), 3.0)

    camera_data = bpy.data.cameras.new("Preview_Camera_" + profession_id)
    camera = bpy.data.objects.new("Preview_Camera_" + profession_id, camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.65
    camera_data.lens = 55
    views = (
        ("front", (0.0, -6.5, 2.0)),
        ("side", (6.5, 0.0, 2.0)),
        ("back", (0.0, 6.5, 2.0)),
    )
    for view_name, position in views:
        camera.location = position
        camera.rotation_euler = (Vector((0, 0, 1.0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(preview_root / (profession_id + "_" + view_name + ".png"))
        bpy.ops.render.render(write_still=True)
    # Keep preview-only studio objects out of subsequent GLB exports.
    for obj in [floor, camera] + [obj for obj in scene.objects if obj.type == "LIGHT"]:
        bpy.data.objects.remove(obj, do_unlink=True)
    if world.users == 0:
        bpy.data.worlds.remove(world)


def build_profession_models():
    """Export one distinct rigged silhouette per playable profession (prototype quality)."""
    classes = catalog_ids(ROOT / "game/scripts/character_visual_catalog.gd", "const PROFILES := {")
    animation_source = ANIMATIONS / "animation_library.glb"
    if not animation_source.is_file():
        raise RuntimeError("shared animation library must be exported before profession models")
    output_root = ROOT / "game/assets/characters"
    for index, class_id in enumerate(classes):
        reset_scene()
        rig = create_rig()
        body = build_body(rig)
        # Profession-specific proportions are baked into each mesh, not merely a tint.
        width = 0.88 + (index % 5) * 0.075
        height = 0.94 + ((index * 3) % 7) * 0.035
        body.scale = (width, 1.0 + (index % 3) * 0.045, height)
        # Preserve the skin, hair, eye and undersuit material slots authored by build_body.
        # Profession colors are applied to signature armor ornaments below, not flattened over the face.
        profession_mat = material("Profession_" + class_id, (
            0.25 + ((index * 37) % 65) / 100.0,
            0.22 + ((index * 19) % 60) / 100.0,
            0.30 + ((index * 29) % 60) / 100.0
        ), 0.38 + (index % 5) * 0.1, 0.34)
        ornaments = []
        shoulder_factor = 1.0 + (index % 6) * 0.12
        for side, sign in (("Left", 1), ("Right", -1)):
            ornaments.append(add_weighted_ellipsoid(
                class_id + "_" + side + "_Signature_Pauldron",
                (sign * (0.34 * shoulder_factor), -0.015, 1.48),
                (0.13 * shoulder_factor, 0.14, 0.12 + (index % 4) * 0.025),
                side + "Shoulder", profession_mat, rig, segments=12, rings=8
            ))
        # Every profession receives a unique crest; winged archetypes receive
        # additional back silhouettes with geometry and bone weights.
        crest_radius = 0.045 + (index % 4) * 0.018
        ornaments.append(add_weighted_ellipsoid(
            class_id + "_Signature_Crest",
            (0, -0.12, 1.96 + (index % 3) * 0.025),
            (crest_radius, crest_radius * 0.7, 0.11 + (index % 4) * 0.035),
            "Head", profession_mat, rig, segments=10, rings=8
        ))
        if index % 3 != 0:
            span = 0.34 + (index % 6) * 0.10
            for side, sign in (("Left", 1), ("Right", -1)):
                ornaments.append(add_weighted_ellipsoid(
                    class_id + "_" + side + "_Back_Wing",
                    (sign * span * 0.52, 0.10, 1.40),
                    (span * 0.52, 0.055, 0.22 + (index % 4) * 0.04),
                    "Chest", profession_mat, rig, segments=12, rings=8
                ))
        make_animation_library(rig, class_id)
        merged = join_meshes([body] + ornaments, "Humanoid_Base_Mesh", rig)
        destination = output_root / class_id / "model/character.glb"
        export_glb(destination, [rig, merged])
        required_profession_clips = tuple(f"{class_id}_basic_attack_{step}" for step in (1, 2, 3))
        validate_glb(destination, required_nodes=("Humanoid_Base_Rig", "Humanoid_Base_Mesh"),
                      require_skin=True, required_clips=REQUIRED_CLIPS + required_profession_clips)
        animation_dest = output_root / class_id / "animations/animation_library.glb"
        export_glb(animation_dest, [rig])
        required_profession_clips = tuple(f"{class_id}_basic_attack_{step}" for step in (1, 2, 3))
        validate_glb(animation_dest, required_clips=REQUIRED_CLIPS + required_profession_clips)
        print("PROFESSION_MODEL_EXPORTED", class_id, destination.stat().st_size,
              "combo_clips=" + ",".join(required_profession_clips),
              "skill_archetypes=7")
        render_profession_turntable(class_id, index)
        print("PROFESSION_PREVIEW_RENDERED", class_id, "views=front,side,back")

def build_equipment_models():
    """Export 49 independent nine-piece skinned armor kits (stylized prototypes)."""
    equipment_ids = catalog_ids(ROOT / "game/scripts/equipment_database.gd", "const EQUIPMENT := {")
    output_root = ROOT / "game/assets/armors"
    for index, equipment_id in enumerate(equipment_ids):
        reset_scene()
        rig = create_rig()
        pieces = build_armor(rig)
        variation = 0.88 + (index % 7) * 0.045
        accent_mat = material("Armor_" + equipment_id + "_Accent", (
            0.36 + ((index * 31) % 55) / 100.0,
            0.30 + ((index * 17) % 58) / 100.0,
            0.24 + ((index * 23) % 62) / 100.0
        ), 0.82, 0.28)
        for part_index, piece in enumerate(pieces):
            factor = variation + (part_index % 3) * 0.035
            piece.scale = (factor, 0.92 + (index % 4) * 0.035, factor)
            if part_index % 2 == index % 2:
                piece.data.materials.clear()
                piece.data.materials.append(accent_mat)
        destination = output_root / equipment_id / "model/armor.glb"
        export_glb(destination, [rig] + pieces)
        validate_glb(
            destination,
            required_nodes=("Humanoid_Base_Rig",) + tuple(piece.name for piece in pieces),
            require_skin=True,
            require_independent_skinned_nodes=tuple(piece.name for piece in pieces),
        )
        print("EQUIPMENT_MODEL_EXPORTED", equipment_id, destination.stat().st_size)


def build_enemy_models():
    """Export a skinned silhouette prototype for every enemy and boss archetype."""
    import re
    source_path = ROOT / "game/scripts/enemy_database.gd"
    source = source_path.read_text(encoding="utf-8")
    enemy_ids = catalog_ids(source_path, "const ARCHETYPES := {")
    output_root = ROOT / "game/assets/enemies"
    for index, enemy_id in enumerate(enemy_ids):
        block_match = re.search(r'"' + re.escape(enemy_id) + r'"' + r'\s*:\s*\{([^}]*)\}', source)
        if not block_match:
            raise RuntimeError("enemy archetype block missing: " + enemy_id)
        is_boss = bool(re.search(r'"is_boss"\s*:\s*true', block_match.group(1)))
        reset_scene()
        rig = create_rig()
        body = build_body(rig)
        make_animation_library(rig)
        # Archetype-specific body scale and metallic palette create readable
        # silhouettes while keeping a shared, animation-compatible skeleton.
        width = (1.18 if is_boss else 0.94) + (index % 5) * 0.045
        height = (1.18 if is_boss else 0.96) + (index % 4) * 0.055
        body.scale = (width, 1.0, height)
        base_color = (
            0.24 + ((index * 29) % 64) / 100.0,
            0.20 + ((index * 17) % 62) / 100.0,
            0.28 + ((index * 37) % 60) / 100.0
        )
        shell = material("Enemy_" + enemy_id + "_Shell", base_color, 0.76 if is_boss else 0.48, 0.26)
        body.data.materials.clear()
        body.data.materials.append(shell)
        crest = material("Enemy_" + enemy_id + "_Crest", (
            min(1.0, base_color[0] + 0.28),
            min(1.0, base_color[1] + 0.24),
            min(1.0, base_color[2] + 0.30)
        ), 0.9, 0.2)
        shoulder = 0.38 if is_boss else 0.31
        for side, sign in (("Left", 1), ("Right", -1)):
            add_weighted_ellipsoid(
                "Enemy_" + enemy_id + "_" + side + "_ShoulderGuard",
                (sign * shoulder, -0.035, 1.48 * height),
                (0.17 * width, 0.16, 0.14 * height),
                side + "Shoulder", crest, rig, segments=12, rings=8
            )
        # Every archetype has a signature head crest; boss archetypes get
        # additional horns, back fins or wings with valid skeleton weights.
        add_weighted_ellipsoid(
            "Enemy_" + enemy_id + "_Crest",
            (0, -0.13, 1.98 * height),
            (0.07 + (index % 4) * 0.018, 0.055, 0.15 if is_boss else 0.10),
            "Head", crest, rig, segments=12, rings=8
        )
        if is_boss:
            for side, sign in (("Left", 1), ("Right", -1)):
                add_weighted_ellipsoid(
                    "Enemy_" + enemy_id + "_" + side + "_Boss_Horn",
                    (sign * (0.18 + (index % 3) * 0.025), -0.04, 1.88 * height),
                    (0.055, 0.065, 0.22 + (index % 4) * 0.035),
                    "Head", crest, rig, segments=12, rings=8
                )
                if index % 3 != 1:
                    span = 0.42 + (index % 5) * 0.07
                    add_weighted_ellipsoid(
                        "Enemy_" + enemy_id + "_" + side + "_Wing",
                        (sign * span * 0.52, 0.10, 1.42 * height),
                        (span * 0.55, 0.07, 0.25 + (index % 4) * 0.045),
                        "Chest", shell, rig, segments=14, rings=8
                    )
        destination = output_root / enemy_id / "model/enemy.glb"
        export_glb(destination, [rig, body] + [
            obj for obj in bpy.context.scene.objects
            if obj.type == "MESH" and obj != body and obj.parent == rig
        ])
        validate_glb(
            destination,
            required_nodes=("Humanoid_Base_Rig", "Humanoid_Base_Mesh"),
            require_skin=True,
            required_clips=REQUIRED_CLIPS,
        )
        print("ENEMY_MODEL_EXPORTED", enemy_id, "boss=" + str(is_boss), "clips=" + str(len(REQUIRED_CLIPS)), destination.stat().st_size)
    print("ENEMY_MODEL_TOTAL", len(enemy_ids))

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    reset_scene()
    rig = create_rig()
    body = build_body(rig)
    make_animation_library(rig)

    character_model = CHARACTER / "humanoid_base.glb"
    export_glb(character_model, [rig, body])
    validate_glb(
        character_model,
        required_nodes=("Humanoid_Base_Rig", "Humanoid_Base_Mesh"),
        require_skin=True,
        required_clips=REQUIRED_CLIPS,
    )

    animation_library = ANIMATIONS / "animation_library.glb"
    export_glb(animation_library, [rig])
    validate_glb(
        animation_library,
        required_nodes=("Humanoid_Base_Rig",),
        required_clips=REQUIRED_CLIPS,
    )

    armor_parts = build_armor(rig)
    armor_model = ARMOR / "modular_armor_kit.glb"
    export_glb(armor_model, [rig] + armor_parts)
    validate_glb(
        armor_model,
        required_nodes=("Humanoid_Base_Rig",) + tuple(obj.name for obj in armor_parts),
        require_skin=True,
        require_independent_skinned_nodes=tuple(obj.name for obj in armor_parts),
    )

    export_chapter_environments()
    build_profession_models()
    build_equipment_models()
    build_enemy_models()
    print("ART_PROTOTYPE_EXPORT_PASS")
    print("Character rigged GLB:", character_model)
    print("Separate animation library GLB:", animation_library)
    print("Modular armor GLB:", armor_model)
    print("Detachable armor mesh objects:", 9)
    print("Animation actions:", len(REQUIRED_CLIPS))
    print("Prototype geometry only; not final profession-specific art.")

if __name__ == "__main__":
    main()
