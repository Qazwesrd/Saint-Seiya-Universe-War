#!/usr/bin/env python3
"""Build an experimental Blender armature preview from Angelica SKI/BON JSON.

The importer preserves source matrices as custom bone properties. BON matrix
coordinate conventions and animation retargeting must still be calibrated
against a real client sample before this preview is considered production-ready.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ski", required=True, type=Path, help="SKI JSON from export_angelica_ski_json.py")
    parser.add_argument("--bon", required=True, type=Path, help="BON JSON from export_angelica_rig_json.py")
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args(argv)


def matrix_from_angelica(values: list[float]) -> Matrix:
    if len(values) != 16 or not all(math.isfinite(float(value)) for value in values):
        raise ValueError("BON matrix must contain 16 finite values")
    rows = [values[index:index + 4] for index in range(0, 16, 4)]
    # Angelica stores the Direct3D row-vector matrix as 16 sequential floats.
    # Transpose into Blender's column-vector convention; verify axes with real data.
    return Matrix(rows).transposed()


def build_world_matrices(bones: list[dict]) -> list[Matrix]:
    matrices: list[Matrix | None] = [None] * len(bones)
    visiting: set[int] = set()

    def resolve(index: int) -> Matrix:
        if index < 0 or index >= len(bones):
            raise ValueError(f"Invalid BON bone index: {index}")
        if matrices[index] is not None:
            return matrices[index]
        if index in visiting:
            raise ValueError("BON hierarchy contains a parent cycle")
        visiting.add(index)
        bone = bones[index]
        local = matrix_from_angelica(bone["mat_relative"])
        parent_index = int(bone.get("parent", -1))
        world = resolve(parent_index) @ local if parent_index >= 0 else local
        visiting.remove(index)
        matrices[index] = world
        return world

    for bone_index in range(len(bones)):
        resolve(bone_index)
    return [item for item in matrices if item is not None]


def create_armature(bon: dict, collection: bpy.types.Collection) -> bpy.types.Object:
    bones = bon.get("bones", [])
    if not bones:
        raise ValueError("BON file contains no bones")
    world_matrices = build_world_matrices(bones)

    armature_data = bpy.data.armatures.new("AngelicaArmature")
    armature_object = bpy.data.objects.new("AngelicaArmature", armature_data)
    collection.objects.link(armature_object)
    bpy.context.view_layer.objects.active = armature_object
    armature_object.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    edit_bones = []
    for index, source_bone in enumerate(bones):
        name = str(source_bone.get("name") or f"Bone_{index}")
        edit_bone = armature_data.edit_bones.new(name)
        head = world_matrices[index].translation
        child_indices = [
            int(child) for child in source_bone.get("children", [])
            if 0 <= int(child) < len(bones) and int(child) != index
        ]
        tail = None
        for child_index in child_indices:
            candidate = world_matrices[child_index].translation
            if (candidate - head).length > 0.0001:
                tail = candidate
                break
        if tail is None:
            tail = head + (world_matrices[index].to_3x3() @ Vector((0.0, 0.05, 0.0)))
        if (tail - head).length < 0.0001:
            tail = head + Vector((0.0, 0.05, 0.0))
        edit_bone.head = head
        edit_bone.tail = tail
        edit_bones.append(edit_bone)

    for index, source_bone in enumerate(bones):
        parent_index = int(source_bone.get("parent", -1))
        if parent_index >= 0:
            if parent_index >= len(edit_bones) or parent_index == index:
                raise ValueError(f"Invalid parent index for BON bone {index}: {parent_index}")
            edit_bones[index].parent = edit_bones[parent_index]
            edit_bones[index].use_connect = False

    bpy.ops.object.mode_set(mode="OBJECT")
    for index, source_bone in enumerate(bones):
        data_bone = armature_data.bones[edit_bones[index].name]
        data_bone["angelica_index"] = index
        data_bone["angelica_parent_index"] = int(source_bone.get("parent", -1))
        data_bone["angelica_mat_relative"] = [float(v) for v in source_bone["mat_relative"]]
        data_bone["angelica_mat_bone_init"] = [float(v) for v in source_bone["mat_bone_init"]]
        data_bone["angelica_is_fake"] = bool(source_bone.get("is_fake", False))
        data_bone["angelica_is_flipped"] = bool(source_bone.get("is_flipped", False))
    armature_object["angelica_skeleton_version"] = int(bon.get("skeleton_version", 0))
    return armature_object


def attach_meshes(objects: list[bpy.types.Object], armature: bpy.types.Object,
                  bone_names: list[str]) -> None:
    for obj in objects:
        if "angelica_rigid_bone_index" in obj:
            bone_index = int(obj["angelica_rigid_bone_index"])
            if 0 <= bone_index < len(bone_names):
                group = obj.vertex_groups.get(bone_names[bone_index])
                if group is None:
                    group = obj.vertex_groups.new(name=bone_names[bone_index])
                if len(obj.data.vertices):
                    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new(name="AngelicaArmature", type="ARMATURE")
        modifier.object = armature
        obj.parent = armature


def main() -> int:
    args = parse_args()
    ski_path = args.ski.expanduser().resolve(strict=True)
    bon_path = args.bon.expanduser().resolve(strict=True)
    output = args.output.expanduser().resolve()
    ski = json.loads(ski_path.read_text(encoding="utf-8"))
    bon = json.loads(bon_path.read_text(encoding="utf-8"))
    if ski.get("schema_version") != 1 or bon.get("schema_version") != 1:
        raise ValueError("Unsupported SKI/BON JSON schema version")

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    collection = bpy.data.collections.new("Angelica_Rigged_Character")
    bpy.context.scene.collection.children.link(collection)

    materials = []
    for item in ski.get("materials", []):
        material = bpy.data.materials.new(name=item.get("name") or "AngelicaMaterial")
        material.diffuse_color = tuple(item.get("diffuse", [0.8, 0.8, 0.8, 1.0]))
        material.use_nodes = True
        principled = material.node_tree.nodes.get("Principled BSDF")
        if principled:
            principled.inputs["Base Color"].default_value = material.diffuse_color
        materials.append(material)

    bone_names = [str(item.get("name") or f"Bone_{index}") for index, item in enumerate(bon.get("bones", []))]
    objects = []
    # Reuse the validated mesh construction path from the static importer.
    from import_angelica_ski_json import make_mesh_object

    for item in ski.get("skin_meshes", []):
        objects.append(make_mesh_object(item, collection, materials, bone_names))
    for item in ski.get("rigid_meshes", []):
        objects.append(make_mesh_object(item, collection, materials, bone_names))

    armature = create_armature(bon, collection)
    attach_meshes(objects, armature, bone_names)

    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    print(
        "ANGELICA_RIGGED_PREVIEW_CREATED "
        f"bones={len(bone_names)} meshes={len(objects)} materials={len(materials)}"
    )
    print("NOTE: BON coordinate axes and bind-pose accuracy require validation with a real client sample.")
    print(f"BLEND {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
