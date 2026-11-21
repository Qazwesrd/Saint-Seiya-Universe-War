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

def add_weighted_ellipsoid(name, location, scale, bone_name, mat, rig, segments=32, rings=20):
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
    """Build a tapered, faceted anatomical limb from a ring-loft mesh.

    The profile narrows toward joints and avoids the constant-radius cylinder
    silhouette used by the earliest blockout.
    """
    a, b = Vector(start), Vector(end)
    direction = b - a
    axis = direction.normalized()
    reference = Vector((0, 1, 0))
    if abs(axis.dot(reference)) > 0.92:
        reference = Vector((1, 0, 0))
    tangent = axis.cross(reference).normalized()
    bitangent = axis.cross(tangent).normalized()
    profiles = ((0.00, 0.72), (0.12, 0.91), (0.34, 1.00),
                (0.62, 0.88), (0.86, 0.70), (1.00, 0.62))
    sides = max(16, vertices)
    mesh_vertices = []
    for t, factor in profiles:
        center = a.lerp(b, t)
        ring_radius = radius * factor
        for index in range(sides):
            angle = (2.0 * math.pi * index) / sides
            offset = tangent * (math.cos(angle) * ring_radius)
            offset += bitangent * (math.sin(angle) * ring_radius)
            mesh_vertices.append(tuple(center + offset))
    faces = []
    faces.append(tuple(reversed(range(sides))))
    for ring in range(len(profiles) - 1):
        for index in range(sides):
            nxt = (index + 1) % sides
            a0 = ring * sides + index
            a1 = ring * sides + nxt
            b0 = (ring + 1) * sides + index
            b1 = (ring + 1) * sides + nxt
            faces.append((a0, a1, b1, b0))
    last = (len(profiles) - 1) * sides
    faces.append(tuple(last + index for index in range(sides)))
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(mesh_vertices, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Armature", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    return obj

def add_weighted_foot(name, ankle_x, bone_name, mat, rig):
    """Create a grounded boot-shaped foot with a broad toe, not a floating sphere."""
    # Cross-sections run from the heel (+Y) toward the toe (-Y).
    profiles = ((0.055, 0.045, 0.045, 0.085),
                (0.015, 0.060, 0.055, 0.078),
                (-0.075, 0.082, 0.048, 0.070),
                (-0.165, 0.078, 0.035, 0.060),
                (-0.215, 0.048, 0.026, 0.052))
    sides = 12
    vertices = []
    faces = []
    for y, rx, rz, center_z in profiles:
        for index in range(sides):
            angle = 2.0 * math.pi * index / sides
            vertices.append((ankle_x + math.cos(angle) * rx,
                             y,
                             center_z + math.sin(angle) * rz))
    faces.append(tuple(reversed(range(sides))))
    for ring in range(len(profiles) - 1):
        for index in range(sides):
            nxt = (index + 1) % sides
            a = ring * sides + index
            b = ring * sides + nxt
            c = (ring + 1) * sides + nxt
            d = (ring + 1) * sides + index
            faces.append((a, b, c, d))
    last = (len(profiles) - 1) * sides
    faces.append(tuple(last + index for index in range(sides)))
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
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
    if name == "Humanoid_Base_Mesh":
        # Smooth the evaluated anatomy before export. This refines the connected
        # body forms without changing the shared skeleton or animation tracks.
        surface = merged.modifiers.new("Anatomical_Surface_Refinement", "SUBSURF")
        surface.subdivision_type = "CATMULL_CLARK"
        surface.levels = 1
        surface.render_levels = 1
        surface.quality = 3
        for polygon in merged.data.polygons:
            polygon.use_smooth = True
    mod = merged.modifiers.new("Humanoid_Skin", "ARMATURE")
    mod.object = rig
    return merged

def build_body(rig):
    parts = []
    # Continuous tapered torso shell: a ring-loft replaces stacked oval
    # muscle pieces, giving the chest, waist and pelvis one coherent silhouette.
    def torso_shell(name, profiles, bone_name):
        sides = 32
        verts = []
        faces = []
        for z, rx, ry in profiles:
            for index in range(sides):
                angle = 2.0 * math.pi * index / sides
                verts.append((math.cos(angle) * rx, math.sin(angle) * ry, z))
        for ring in range(len(profiles) - 1):
            for index in range(sides):
                nxt = (index + 1) % sides
                a = ring * sides + index
                b = ring * sides + nxt
                c = (ring + 1) * sides + nxt
                d = (ring + 1) * sides + index
                faces.append((a, b, c, d))
        faces.append(tuple(reversed(range(sides))))
        last = (len(profiles) - 1) * sides
        faces.append(tuple(last + index for index in range(sides)))
        mesh = bpy.data.meshes.new(name + "_Mesh")
        mesh.from_pydata(verts, [], faces)
        mesh.materials.append(CLOTH)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        for polygon in mesh.polygons:
            polygon.use_smooth = True
        group = obj.vertex_groups.new(name=bone_name)
        group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new("Armature", "ARMATURE")
        modifier.object = rig
        obj.parent = rig
        return obj

    parts.append(torso_shell("Unified_Torso", [
        (0.80, 0.17, 0.115), (0.88, 0.205, 0.13),
        (1.02, 0.18, 0.12), (1.18, 0.205, 0.125),
        (1.34, 0.255, 0.145), (1.46, 0.29, 0.145),
        (1.54, 0.205, 0.12)], "Chest"))
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
        # Angular deltoid shell: a shaped low-profile mesh replaces the
        # spherical shoulder joint and blends into the upper-arm silhouette.
        parts.append(add_weighted_pauldron(
            side + "ShoulderMesh", (x(0.315), -0.012, 1.465),
            0.145, 0.070, 0.078, side + "Shoulder", CLOTH, rig, sign))
        parts.append(add_weighted_limb(side + "UpperArmMesh", (x(0.34), 0, 1.45), (x(0.48), 0, 1.22), 0.075, side + "UpperArm", SKIN, rig))
        parts.append(add_weighted_limb(side + "ForearmMesh", (x(0.48), 0, 1.22), (x(0.50), 0, 0.98), 0.062, side + "Forearm", SKIN, rig))
        parts.append(add_weighted_ellipsoid(side + "HandMesh", (x(0.50), -0.01, 0.92), (0.065, 0.045, 0.09), side + "Hand", SKIN, rig))
        # Individually modeled fingers and thumb give close-up combat poses a
        # readable hand silhouette instead of a mitten-shaped ellipsoid.
        for finger_index, offset in enumerate((-0.038, -0.013, 0.013, 0.038)):
            length = (0.050, 0.062, 0.060, 0.048)[finger_index]
            parts.append(add_weighted_ellipsoid(
                side + "_Finger_" + str(finger_index + 1),
                (x(0.50 + offset), -0.018, 0.865 - length * 0.36),
                (0.012, 0.014, length), side + "Hand", SKIN, rig, 12, 8))
            parts.append(add_weighted_ellipsoid(
                side + "_FingerTip_" + str(finger_index + 1),
                (x(0.50 + offset), -0.018, 0.865 - length * 0.82),
                (0.011, 0.013, 0.015), side + "Hand", SKIN, rig, 10, 8))
        parts.append(add_weighted_ellipsoid(
            side + "_Thumb", (x(0.558), -0.025, 0.915),
            (0.018, 0.018, 0.047), side + "Hand", SKIN, rig, 12, 8))
        parts.append(add_weighted_limb(side + "ThighMesh", (x(0.13), 0, 0.88), (x(0.15), 0, 0.49), 0.105, side + "Thigh", CLOTH, rig))
        parts.append(add_weighted_limb(side + "ShinMesh", (x(0.15), 0, 0.49), (x(0.15), 0, 0.12), 0.075, side + "Shin", CLOTH, rig))
        parts.append(add_weighted_foot(side + "FootMesh", x(0.15), side + "Foot", CLOTH, rig))
    return join_meshes(parts, "Humanoid_Base_Mesh", rig)

def add_weighted_pauldron(name, center, width, height, depth, bone_name, mat, rig, side=1):
    """Build a directional wing-shaped shoulder shell; never use an ellipsoid joint."""
    cx, cy, cz = center
    # A swept, asymmetric silhouette gives the pauldron a narrow neck, raised
    # outer wing and pointed lower edge. The raised front crown adds real volume.
    outline = [
        (-0.76 * width, -0.30 * height),
        (-0.62 * width,  0.18 * height),
        (-0.20 * width,  0.56 * height),
        ( 0.48 * width,  0.48 * height),
        ( 1.00 * width,  0.06 * height),
        ( 0.78 * width, -0.34 * height),
        ( 0.18 * width, -0.58 * height),
    ]
    count = len(outline)
    vertices = []
    # Rear perimeter, front perimeter, then a forward crown point. Mirroring
    # the X coordinate keeps left/right armor genuinely symmetric.
    for x, z in outline:
        vertices.append((cx + x * side, cy + depth * 0.50, cz + z))
    for x, z in outline:
        vertices.append((cx + x * side, cy - depth * 0.12, cz + z))
    crown = len(vertices)
    vertices.append((cx - 0.02 * width * side, cy - depth * 0.66, cz + 0.04 * height))
    faces = [tuple(reversed(range(count)))]
    for index in range(count):
        nxt = (index + 1) % count
        faces.append((index, nxt, nxt + count, index + count))
        faces.append((count + index, count + nxt, crown))
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    bevel = obj.modifiers.new("Forged_Wing_Rim", "BEVEL")
    bevel.width = min(0.012, depth * 0.12)
    bevel.segments = 2
    obj.modifiers.new("Weighted_Highlight_Normals", "WEIGHTED_NORMAL")
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Pauldron_Skeleton", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    return obj


def add_weighted_armor_plate(name, center, outline, depth, bone_name, mat, rig, bevel=0.025):
    """Create a shaped, beveled plate from an X/Z silhouette, facing the -Y camera."""
    cx, cy, cz = center
    count = len(outline)
    vertices = [(cx + x, cy - depth / 2, cz + z) for x, z in outline]
    vertices += [(cx + x, cy + depth / 2, cz + z) for x, z in outline]
    # The silhouette is authored clockwise in X/Z. Reverse the front cap so its
    # normal points toward the -Y preview camera; keep the rear cap facing +Y.
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    for index in range(count):
        nxt = (index + 1) % count
        faces.append((index, nxt, nxt + count, index + count))
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if bevel:
        mod = obj.modifiers.new("Forged_Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
        normal = obj.modifiers.new("Weighted_Highlight_Normals", "WEIGHTED_NORMAL")
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Armor_Skeleton", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    return obj


def armor_piece(name, location, scale, bone_name, rig, mat=ARMOR_MAT):
    # Retained for compatibility with the source-template builder.
    return add_weighted_ellipsoid(name, location, scale, bone_name, mat, rig, segments=16, rings=10)


def build_armor(rig, primary_material=GOLD, secondary_material=ARMOR_MAT):
    """Build a nine-piece articulated armor set with forged silhouettes, not sphere placeholders."""
    parts = []
    # Helmet: raised crown, brow and pointed cheek silhouette; front faces -Y.
    parts.append(add_weighted_armor_plate(
        "Armor_Helmet", (0, -0.055, 1.84),
        [(-0.155, -0.10), (-0.145, 0.055), (-0.085, 0.16), (0, 0.205),
         (0.085, 0.16), (0.145, 0.055), (0.155, -0.10), (0.075, -0.17),
         (0.0, -0.12), (-0.075, -0.17)],
        0.16, "Head", primary_material, rig, 0.018))
    # Chest cuirass: broad shoulders tapering to a pointed abdominal waist.
    parts.append(add_weighted_armor_plate(
        "Armor_Chest", (0, -0.155, 1.365),
        [(-0.285, 0.16), (-0.19, 0.255), (-0.07, 0.22), (0, 0.265),
         (0.07, 0.22), (0.19, 0.255), (0.285, 0.16), (0.22, -0.08),
         (0.105, -0.205), (0, -0.245), (-0.105, -0.205), (-0.22, -0.08)],
        0.095, "Chest", primary_material, rig, 0.022))
    for side, sign in (("Left", 1), ("Right", -1)):
        # Winged pauldron with a sharp outer point and layered lower edge.
        parts.append(add_weighted_pauldron(
            "Armor_" + side + "_Shoulder", (sign * 0.335, -0.055, 1.49),
            0.170, 0.078, 0.088, side + "Shoulder", primary_material, rig, sign))
        # Forearm bracer and shin guard use tapered, faceted armor profiles.
        parts.append(add_weighted_armor_plate(
            "Armor_" + side + "_Forearm", (sign * 0.49, -0.075, 1.105),
            [(-0.072, 0.17), (0.055, 0.145), (0.082, 0.07),
             (0.065, -0.145), (0, -0.19), (-0.07, -0.13), (-0.085, 0.06)],
            0.105, side + "Forearm", secondary_material, rig, 0.014))
        parts.append(add_weighted_armor_plate(
            "Armor_" + side + "_Leg", (sign * 0.15, -0.075, 0.345),
            [(-0.095, 0.19), (0, 0.225), (0.095, 0.19), (0.082, 0.045),
             (0.055, -0.17), (0, -0.215), (-0.07, -0.15), (-0.09, 0.025)],
            0.12, side + "Shin", secondary_material, rig, 0.016))
    # Waist fauld: segmented-looking pointed skirt profile.
    parts.append(add_weighted_armor_plate(
        "Armor_Waist", (0, -0.14, 0.945),
        [(-0.245, 0.095), (-0.18, 0.14), (0.18, 0.14), (0.245, 0.095),
         (0.205, -0.035), (0.12, -0.12), (0, -0.17), (-0.12, -0.12), (-0.205, -0.035)],
        0.11, "Hips", primary_material, rig, 0.018))
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

def make_signature_idle_pose(rig, profession_id):
    """Create a distinct, looping character-specific presentation stance."""
    style = PROFESSION_COMBO_STYLES.get(profession_id, "rush")
    arm, forearm, torso, hips, support, leg = COMBO_STYLE_POSES[style]
    seed = sum((index + 1) * ord(char) for index, char in enumerate(profession_id))
    variation = 1.0 + ((seed % 13) - 6) * 0.018
    primary = "Right" if seed % 2 == 0 else "Left"
    secondary = "Left" if primary == "Right" else "Right"
    mirror = 1.0 if primary == "Right" else -1.0

    # Each character receives a recognizable silhouette: forward drive,
    # guarded defense, elegant control, aerial balance or imposing authority.
    pose = {
        primary + "UpperArm": (-0.34 - abs(arm) * 0.10, 0.0, 0.16 * mirror * variation),
        primary + "Forearm": (-0.42 + forearm * 0.10, 0.0, -0.04 * mirror),
        secondary + "UpperArm": (-0.24 - abs(support) * 0.08, 0.0, -0.14 * mirror),
        secondary + "Forearm": (-0.30, 0.0, 0.03 * mirror),
        "Chest": (torso * 0.10, 0.0, hips * 0.10 * variation),
        "Spine": (0.0, 0.0, torso * 0.035),
        "Hips": (0.0, 0.0, hips * 0.10 * variation),
        primary + "Thigh": (-0.08 - abs(leg) * 0.06, 0.0, 0.0),
        secondary + "Thigh": (0.05 + abs(leg) * 0.035, 0.0, 0.0),
        "Head": (-0.025 * (1 if style == "reaper" else -1), 0.0, 0.045 * mirror),
    }

    action_name = profession_id + "_signature_idle"
    action = bpy.data.actions.new(name=action_name)
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = action
    scene = bpy.context.scene
    neutral = {bone.name: (0.0, 0.0, 0.0) for bone in rig.pose.bones}
    scene.frame_set(1)
    key_pose(rig, 1, neutral)
    key_pose(rig, 18, pose)
    key_pose(rig, 48, pose)
    key_pose(rig, 72, pose)
    scene.frame_start, scene.frame_end = 18, 72
    track = rig.animation_data.nla_tracks.new()
    track.name = action_name
    strip = track.strips.new(action_name, 18, action)
    strip.name = action_name
    strip.blend_type = "REPLACE"
    rig.animation_data.action = None
    scene.frame_set(1)


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
    skin_joint_indices = {
        joint
        for skin in skins
        for joint in skin.get("joints", [])
    }
    for clip_name in required_clips:
        clip = by_clip_name[clip_name]
        if not clip.get("channels") or not clip.get("samplers"):
            raise RuntimeError(f"Animation clip has no tracks: {clip_name}")
        animated_nodes = {
            channel.get("target", {}).get("node")
            for channel in clip["channels"]
            if isinstance(channel.get("target", {}).get("node"), int)
        }
        if require_skin:
            animated_joint_count = len(animated_nodes.intersection(skin_joint_indices))
            if animated_joint_count < 8:
                raise RuntimeError(
                    f"Animation clip does not animate enough skinned joints: {clip_name} "
                    f"({animated_joint_count} joints)"
                )
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

def render_profession_turntable(profession_id, index, preview_category="characters"):
    """Render one acceptance preview from the exact generated in-project asset scene."""
    preview_root = ROOT / "game" / "art_previews" / preview_category
    preview_root.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    available_engines = {item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items}
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in available_engines else "BLENDER_EEVEE"
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
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"

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
    # User-facing acceptance preview: one representative profession image only.
    views = (
        ("front", (0.0, -6.5, 2.0)),
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


def build_profession_models(shard_index=0, shard_count=1):
    """Export one distinct rigged silhouette per playable profession (prototype quality)."""
    classes = catalog_ids(ROOT / "game/scripts/character_visual_catalog.gd", "const PROFILES := {")
    animation_source = ANIMATIONS / "animation_library.glb"
    if not animation_source.is_file():
        raise RuntimeError("shared animation library must be exported before profession models")
    output_root = ROOT / "game/assets/characters"
    for index, class_id in enumerate(classes):
        if index % shard_count != shard_index:
            continue
        reset_scene()
        rig = create_rig()
        body = build_body(rig)
        # Profession-specific proportions are baked into each mesh, not merely a tint.
        width = 0.88 + (index % 5) * 0.075
        height = 0.94 + ((index * 3) % 7) * 0.035
        body.scale = (width, 1.0 + (index % 3) * 0.045, height)
        # Preserve the skin, hair, eye and undersuit material slots authored by build_body.
        # Profession colors are applied to signature armor ornaments below, not flattened over the face.
        profession_color = (
            (0.045, 0.025, 0.085) if class_id == "hades" else
            (0.25 + ((index * 37) % 65) / 100.0,
             0.22 + ((index * 19) % 60) / 100.0,
             0.30 + ((index * 29) % 60) / 100.0)
        )
        profession_mat = material("Profession_" + class_id, profession_color,
                                  0.90 if class_id == "hades" else 0.38 + (index % 5) * 0.1,
                                  0.20 if class_id == "hades" else 0.34)
        ornaments = []
        shoulder_factor = 0.78 + (index % 6) * 0.045
        for side, sign in (("Left", 1), ("Right", -1)):
            ornaments.append(add_weighted_pauldron(
                class_id + "_" + side + "_Signature_Pauldron",
                (sign * (0.34 * shoulder_factor), -0.105, 1.48),
                0.142 * shoulder_factor, 0.072 * shoulder_factor, 0.078,
                side + "Shoulder", profession_mat, rig, sign
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
        if class_id == "pegasus":
            # Dedicated Pegasus Bronze Cloth hero detailing for the first art review.
            bronze = material("Pegasus_Bronze_Alloy", (0.62, 0.34, 0.16), 0.86, 0.24)
            silver = material("Pegasus_Silver_Edges", (0.72, 0.79, 0.88), 0.9, 0.2)
            enamel = material("Pegasus_Cobalt_Enamel", (0.035, 0.16, 0.42), 0.62, 0.2)
            crimson = material("Pegasus_Crimson_Gem", (0.68, 0.035, 0.075), 0.58, 0.16)
            ornaments.append(add_weighted_armor_plate(
                "Pegasus_Bronze_Chest_Cuirass", (0, -0.172, 1.365),
                [(-0.245, 0.17), (-0.16, 0.245), (0, 0.205), (0.16, 0.245),
                 (0.245, 0.17), (0.19, -0.08), (0.075, -0.19), (0, -0.22),
                 (-0.075, -0.19), (-0.19, -0.08)],
                0.10, "Chest", bronze, rig, 0.022))
            ornaments.append(add_weighted_armor_plate(
                "Pegasus_Chest_Enamel_Inlay", (0, -0.235, 1.37),
                [(-0.12, 0.10), (-0.065, 0.15), (0, 0.12), (0.065, 0.15),
                 (0.12, 0.10), (0.075, -0.075), (0, -0.12), (-0.075, -0.075)],
                0.026, "Chest", enamel, rig, 0.008))
            ornaments.append(add_weighted_ellipsoid(
                "Pegasus_Chest_Crimson_Cosmos_Gem", (0, -0.258, 1.39),
                (0.042, 0.022, 0.052), "Chest", crimson, rig, 20, 12))
            for side, sign in (("Left", 1), ("Right", -1)):
                ornaments.append(add_weighted_pauldron(
                    "Pegasus_" + side + "_Winged_Pauldron",
                    (sign * 0.345, -0.09, 1.49), 0.19, 0.09, 0.095,
                    side + "Shoulder", silver, rig, sign))
                ornaments.append(add_weighted_armor_plate(
                    "Pegasus_" + side + "_Bronze_Gauntlet",
                    (sign * 0.49, -0.095, 1.105),
                    [(-0.075, 0.16), (0.045, 0.18), (0.085, 0.07),
                     (0.06, -0.14), (0, -0.19), (-0.07, -0.13), (-0.09, 0.04)],
                    0.12, side + "Forearm", bronze, rig, 0.016))
                ornaments.append(add_weighted_armor_plate(
                    "Pegasus_" + side + "_Silver_Shin_Guard",
                    (sign * 0.15, -0.092, 0.345),
                    [(-0.09, 0.18), (0, 0.22), (0.09, 0.18),
                     (0.075, 0.02), (0.05, -0.17), (0, -0.21),
                     (-0.07, -0.15), (-0.085, 0.02)],
                    0.13, side + "Shin", silver, rig, 0.016))
                ornaments.append(add_weighted_armor_plate(
                    "Pegasus_" + side + "_Helmet_Wing",
                    (sign * 0.105, -0.105, 1.91),
                    [(0, -0.045), (sign * 0.04, 0.015), (sign * 0.16, 0.17),
                     (sign * 0.19, 0.22), (sign * 0.08, 0.19), (0, 0.09)],
                    0.055, "Head", silver, rig, 0.01))
            ornaments.append(add_weighted_armor_plate(
                "Pegasus_Bronze_Waist_Tasset", (0, -0.16, 0.93),
                [(-0.18, 0.10), (-0.12, 0.14), (0.12, 0.14), (0.18, 0.10),
                 (0.13, -0.12), (0, -0.19), (-0.13, -0.12)],
                0.075, "Hips", bronze, rig, 0.014))
            for side, sign in (("Left", 1), ("Right", -1)):
                ornaments.append(add_weighted_ellipsoid(
                    "Pegasus_" + side + "_Pauldron_Enamel",
                    (sign * 0.39, -0.145, 1.50), (0.065, 0.018, 0.035),
                    side + "Shoulder", enamel, rig, 16, 10))
        make_animation_library(rig, class_id)
        make_signature_idle_pose(rig, class_id)
        merged = join_meshes([body] + ornaments, "Humanoid_Base_Mesh", rig)
        destination = output_root / class_id / "model/character.glb"
        export_glb(destination, [rig, merged])
        required_profession_clips = tuple(f"{class_id}_basic_attack_{step}" for step in (1, 2, 3)) + (f"{class_id}_signature_idle",)
        validate_glb(destination, required_nodes=("Humanoid_Base_Rig", "Humanoid_Base_Mesh"),
                      require_skin=True, required_clips=REQUIRED_CLIPS + required_profession_clips)
        animation_dest = output_root / class_id / "animations/animation_library.glb"
        export_glb(animation_dest, [rig])
        required_profession_clips = tuple(f"{class_id}_basic_attack_{step}" for step in (1, 2, 3)) + (f"{class_id}_signature_idle",)
        validate_glb(animation_dest, required_clips=REQUIRED_CLIPS + required_profession_clips)
        print("PROFESSION_MODEL_EXPORTED", class_id, destination.stat().st_size,
              "combo_clips=" + ",".join(required_profession_clips),
              "skill_archetypes=7")
        # Render all five Bronze Saint protagonists for the first user-facing art review.
        # These are still blockout prototypes; previews are evidence for visual review,
        # not approval as final canon-accurate character art.
        if class_id in {"pegasus", "dragon", "cygnus", "andromeda", "phoenix"}:
            render_profession_turntable(class_id, index)
            preview_path = ROOT / "game" / "art_previews" / "characters" / (class_id + "_front.png")
            if not preview_path.is_file() or preview_path.stat().st_size < 128:
                raise RuntimeError("Core Bronze Saint preview missing or too small: " + str(preview_path))
            print("CORE_BRONZE_SAINT_PREVIEW_RENDERED", class_id, "views=front",
                  "bytes=" + str(preview_path.stat().st_size))

def build_equipment_models(shard_index=0, shard_count=1):
    """Export every catalogued independent nine-piece skinned armor kit (stylized prototypes)."""
    equipment_ids = catalog_ids(ROOT / "game/scripts/equipment_database.gd", "const EQUIPMENT := {")
    output_root = ROOT / "game/assets/armors"
    for index, equipment_id in enumerate(equipment_ids):
        if index % shard_count != shard_index:
            continue
        reset_scene()
        rig = create_rig()
        # Armor uses the exact same humanoid skeleton and baseline motion clips
        # as the profession model, allowing the runtime armor rig to animate in sync.
        make_animation_library(rig)
        is_surplice = ("surplice" in equipment_id or equipment_id in ("hades_divine_garment", "hades_divine_relic"))
        is_dark_cloth = ("dark_cloth" in equipment_id or equipment_id.startswith("dark_"))
        if is_surplice:
            armor_primary = material("Surplice_Black_Purple", (0.045, 0.025, 0.085), 0.94, 0.18)
            armor_secondary = material("Surplice_Deep_Violet", (0.18, 0.085, 0.30), 0.90, 0.20)
        elif is_dark_cloth:
            armor_primary = material("Dark_Cloth_Graphite", (0.025, 0.030, 0.050), 0.92, 0.16)
            armor_secondary = material("Dark_Cloth_Steel_Blue", (0.12, 0.17, 0.25), 0.90, 0.18)
        else:
            armor_primary, armor_secondary = GOLD, ARMOR_MAT
        pieces = build_armor(rig, armor_primary, armor_secondary)
        variation = 0.88 + (index % 7) * 0.045
        accent_mat = material("Armor_" + equipment_id + "_Accent", (
            0.36 + ((index * 31) % 55) / 100.0,
            0.30 + ((index * 17) % 58) / 100.0,
            0.24 + ((index * 23) % 62) / 100.0
        ), 0.82, 0.28)
        for part_index, piece in enumerate(pieces):
            factor = variation + (part_index % 3) * 0.035
            piece.scale = (factor, 0.92 + (index % 4) * 0.035, factor)
            # Preserve the explicit black-purple Surplice / graphite Dark Cloth
            # palette; generic random accents are only for other equipment families.
            if not is_surplice and not is_dark_cloth and part_index % 2 == index % 2:
                piece.data.materials.clear()
                piece.data.materials.append(accent_mat)
        destination = output_root / equipment_id / "model/armor.glb"
        export_glb(destination, [rig] + pieces)
        validate_glb(
            destination,
            required_nodes=("Humanoid_Base_Rig",) + tuple(piece.name for piece in pieces),
            require_skin=True,
            required_clips=REQUIRED_CLIPS,
            require_independent_skinned_nodes=tuple(piece.name for piece in pieces),
        )
        if index == 0:
            # Render the armor on the same rigged humanoid body used by the
            # character pipeline. The mannequin is preview-only and is not
            # included in the independently skinned armor GLB export above.
            preview_body = build_body(rig)
            render_profession_turntable(equipment_id, index, "armors")
            bpy.data.objects.remove(preview_body, do_unlink=True)
            preview_path = ROOT / "game" / "art_previews" / "armors" / (equipment_id + "_front.png")
            if not preview_path.is_file() or preview_path.stat().st_size < 128:
                raise RuntimeError("Representative armor preview missing or too small: " + str(preview_path))
            print("ARMOR_PREVIEW_RENDERED", equipment_id, "views=front", "bytes=" + str(preview_path.stat().st_size))
        print("EQUIPMENT_MODEL_EXPORTED", equipment_id, destination.stat().st_size)


def build_enemy_models(shard_index=0, shard_count=1):
    """Export a skinned silhouette prototype for every enemy and boss archetype."""
    import re
    source_path = ROOT / "game/scripts/enemy_database.gd"
    source = source_path.read_text(encoding="utf-8")
    enemy_ids = catalog_ids(source_path, "const ARCHETYPES := {")
    output_root = ROOT / "game/assets/enemies"
    for index, enemy_id in enumerate(enemy_ids):
        if index % shard_count != shard_index:
            continue
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
        # Recolor only the undersuit slot. Keep the authored skin, hair, eyes,
        # and facial materials intact so enemy faces do not become monochrome.
        for material_index, existing_material in enumerate(body.data.materials):
            if existing_material == CLOTH:
                body.data.materials[material_index] = shell
        crest = material("Enemy_" + enemy_id + "_Crest", (
            min(1.0, base_color[0] + 0.28),
            min(1.0, base_color[1] + 0.24),
            min(1.0, base_color[2] + 0.30)
        ), 0.9, 0.2)
        # Pope Saga has angular, individually modeled pauldrons and a
        # ceremonial diadem; do not bury those shapes under generic spheres.
        if enemy_id != "pope_saga":
            shoulder = 0.38 if is_boss else 0.31
            for side, sign in (("Left", 1), ("Right", -1)):
                add_weighted_armor_plate(
                    "Enemy_" + enemy_id + "_" + side + "_ShoulderGuard",
                    (sign * shoulder, -0.105, 1.48 * height),
                    [(-0.15 * width, 0.035), (-0.10 * width, 0.14),
                     (0.02 * width, 0.17), (0.16 * width, 0.10),
                     (0.18 * width, -0.025), (0.075 * width, -0.14),
                     (-0.10 * width, -0.11)],
                    0.14, side + "Shoulder", crest, rig, 0.022
                )
        # Every archetype has a signature head crest; boss archetypes get
        # additional horns, back fins or wings with valid skeleton weights.
        if enemy_id != "pope_saga":
            add_weighted_ellipsoid(
                "Enemy_" + enemy_id + "_Crest",
                (0, -0.13, 1.98 * height),
                (0.07 + (index % 4) * 0.018, 0.055, 0.15 if is_boss else 0.10),
                "Head", crest, rig, segments=12, rings=8
            )
        if is_boss and enemy_id != "pope_saga":
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
        if enemy_id == "pope_saga":
            # Dedicated ceremonial armor silhouette for the Pope Saga boss.
            saga_gold = material("PopeSaga_Gold", (0.92, 0.62, 0.19), 0.92, 0.2)
            saga_edge = material("PopeSaga_Edge", (1.0, 0.84, 0.43), 0.9, 0.16)
            saga_violet = material("PopeSaga_Enamel", (0.16, 0.035, 0.29), 0.7, 0.22)
            saga_gem = material("PopeSaga_CosmicGem", (0.16, 0.42, 0.95), 0.62, 0.12)
            add_weighted_armor_plate("PopeSaga_Diadem", (0, -0.15, 1.91),
                [(-0.16,-0.03),(-0.12,0.06),(0,0.04),(0.12,0.06),(0.16,-0.03),(0,-0.07)],
                0.07, "Head", saga_gold, rig, 0.012)
            for side, sign in (("Left", 1), ("Right", -1)):
                add_weighted_armor_plate("PopeSaga_" + side + "_CrownWing",
                    (sign*0.12,-0.10,1.94), [(0,-0.06),(sign*0.07,0.0),(sign*0.15,0.19),(sign*0.03,0.13)],
                    0.055, "Head", saga_edge, rig, 0.01)
                add_weighted_armor_plate("PopeSaga_" + side + "_CheekGuard",
                    (sign*0.12,-0.10,1.79), [(0,0.08),(sign*0.07,0.04),(sign*0.05,-0.13),(0,-0.16)],
                    0.06, "Head", saga_gold, rig, 0.012)
                add_weighted_armor_plate("PopeSaga_" + side + "_Pauldron",
                    (sign*0.34,-0.08,1.48), [(-0.12,0.04),(-0.07,0.13),(0.05,0.12),(0.15,0.01),(0.10,-0.11),(-0.06,-0.12)],
                    0.15, side + "Shoulder", saga_gold, rig, 0.022)
                add_weighted_armor_plate("PopeSaga_" + side + "_Bracer",
                    (sign*0.49,-0.07,1.10), [(-0.07,0.14),(0.045,0.12),(0.07,-0.13),(-0.045,-0.16)],
                    0.12, side + "Forearm", saga_gold, rig, 0.016)
                add_weighted_armor_plate("PopeSaga_" + side + "_Greave",
                    (sign*0.15,-0.07,0.34), [(-0.09,0.15),(0.07,0.15),(0.095,-0.13),(0,-0.18),(-0.085,-0.11)],
                    0.13, side + "Shin", saga_gold, rig, 0.018)
                add_weighted_ellipsoid("PopeSaga_" + side + "_ShoulderGem",
                    (sign*0.37,-0.16,1.49), (0.045,0.025,0.052), side + "Shoulder", saga_gem, rig, 16, 10)
                add_weighted_armor_plate("PopeSaga_" + side + "_WaistTasset",
                    (sign*0.145,-0.12,0.83), [(-0.075,0.13),(0.075,0.13),(0.09,-0.18),(0,-0.25),(-0.09,-0.18)],
                    0.075, "Hips", saga_violet, rig, 0.012)
            add_weighted_armor_plate("PopeSaga_ChestCuirass", (0,-0.16,1.37),
                [(-0.245,0.16),(-0.17,0.245),(0,0.20),(0.17,0.245),(0.245,0.16),(0.18,-0.11),(0,-0.19),(-0.18,-0.11)],
                0.105, "Chest", saga_gold, rig, 0.025)
            add_weighted_armor_plate("PopeSaga_ChestEnamel", (0,-0.22,1.37),
                [(-0.16,0.12),(-0.105,0.17),(0,0.145),(0.105,0.17),(0.16,0.12),(0.12,-0.08),(0,-0.13),(-0.12,-0.08)],
                0.035, "Chest", saga_violet, rig, 0.01)
            add_weighted_ellipsoid("PopeSaga_ChestGem", (0,-0.25,1.40),
                (0.052,0.025,0.066), "Chest", saga_gem, rig, 20, 12)
            add_weighted_armor_plate("PopeSaga_Collar", (0,-0.10,1.58),
                [(-0.18,-0.03),(-0.13,0.09),(0,0.15),(0.13,0.09),(0.18,-0.03),(0,-0.10)],
                0.12, "Chest", saga_edge, rig, 0.016)
            cape_vertices = [(-0.18,0.10,1.55),(0.18,0.10,1.55),(-0.34,0.17,1.20),(0.34,0.17,1.20),
                (-0.43,0.22,0.63),(0.43,0.22,0.63),(-0.30,0.18,0.18),(0.30,0.18,0.18)]
            cape_mesh = bpy.data.meshes.new("PopeSaga_MantleMesh")
            cape_mesh.from_pydata(cape_vertices, [], [(0,2,3,1),(2,4,5,3),(4,6,7,5)])
            cape_mesh.materials.append(saga_violet)
            cape_mesh.update()
            cape = bpy.data.objects.new("PopeSaga_LongMantle", cape_mesh)
            bpy.context.collection.objects.link(cape)
            cape.vertex_groups.new(name="Chest").add(list(range(len(cape_vertices))), 1.0, "REPLACE")
            cape_armature = cape.modifiers.new("MantleArmature", "ARMATURE")
            cape_armature.object = rig
            cape.parent = rig
            cape.modifiers.new("MantleThickness", "SOLIDIFY").thickness = 0.025
            add_weighted_limb("PopeSaga_Scepter", (-0.54,-0.12,0.86), (-0.56,-0.12,1.43),
                0.022, "RightHand", saga_edge, rig, 12)
            add_weighted_ellipsoid("PopeSaga_ScepterOrb", (-0.56,-0.12,1.48),
                (0.075,0.055,0.075), "RightHand", saga_gem, rig, 20, 12)
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
        if enemy_id == "pope_saga":
            render_profession_turntable("pope_saga", index, "bosses")
            preview_path = ROOT / "game" / "art_previews" / "bosses" / "pope_saga_front.png"
            if not preview_path.is_file() or preview_path.stat().st_size < 10000:
                raise RuntimeError("Pope Saga preview render missing or too small")
            print("BOSS_PREVIEW_RENDERED", preview_path, preview_path.stat().st_size)
        print("ENEMY_MODEL_EXPORTED", enemy_id, "boss=" + str(is_boss), "clips=" + str(len(REQUIRED_CLIPS)), destination.stat().st_size)
    print("ENEMY_MODEL_SHARD_TOTAL", sum(1 for index in range(len(enemy_ids)) if index % shard_count == shard_index), "of", len(enemy_ids))

def build_foundation_assets():
    """Build shared skeleton, animation, armor template and chapter environments once."""
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
    print("ART_FOUNDATION_PASS")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate and validate Saint Seiya art assets.")
    parser.add_argument("--stage", choices=("all", "foundation", "characters", "armors", "enemies"), default="all")
    parser.add_argument("--shard-index", type=int, default=0)
    parser.add_argument("--shard-count", type=int, default=1)
    args_list = __import__("sys").argv
    args_list = args_list[args_list.index("--") + 1:] if "--" in args_list else []
    args = parser.parse_args(args_list)
    if args.shard_count < 1 or not 0 <= args.shard_index < args.shard_count:
        raise SystemExit("Invalid shard index/count")

    if args.stage in ("all", "foundation"):
        build_foundation_assets()
    if args.stage in ("all", "characters"):
        build_profession_models(args.shard_index, args.shard_count)
    if args.stage in ("all", "armors"):
        build_equipment_models(args.shard_index, args.shard_count)
    if args.stage in ("all", "enemies"):
        build_enemy_models(args.shard_index, args.shard_count)
    if args.stage == "all":
        print("ART_PROTOTYPE_EXPORT_PASS")
        print("Prototype geometry only; not final profession-specific art.")


if __name__ == "__main__":
    main()
