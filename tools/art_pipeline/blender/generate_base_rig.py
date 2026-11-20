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
    "victory", "defeat",
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

def make_animation_library(rig):
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
        else:
            key_pose(rig, 24, {"Spine": (0, 0, 0)})
        scene.frame_start, scene.frame_end = 1, 25 if clip in ("walk", "run") else 24
        track = rig.animation_data.nla_tracks.new()
        track.name = clip
        strip = track.strips.new(clip, 1, action)
        strip.name = clip
        rig.animation_data.action = None
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
    print("Validated GLB:", path.name, "nodes=", len(node_names), "meshes=", len(document.get("meshes", [])), "clips=", len(clip_names))

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

    print("ART_PROTOTYPE_EXPORT_PASS")
    print("Character rigged GLB:", character_model)
    print("Separate animation library GLB:", animation_library)
    print("Modular armor GLB:", armor_model)
    print("Detachable armor mesh objects:", len(armor_parts))
    print("Armor objects:", ", ".join(obj.name for obj in armor_parts))
    print("Animation actions:", len(REQUIRED_CLIPS))
    print("Prototype geometry only; not final profession-specific art.")

if __name__ == "__main__":
    main()
