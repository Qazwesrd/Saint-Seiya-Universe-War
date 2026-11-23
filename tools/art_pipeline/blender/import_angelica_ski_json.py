#!/usr/bin/env python3
"""Run inside Blender to create a static inspection scene from SKI JSON.

Usage:
  blender --background --python tools/art_pipeline/blender/import_angelica_ski_json.py -- --input model.json --output model_preview.blend
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--saint-seiya-basis", action="store_true", help="Convert Angelica left-handed Y-up vertices to Blender coordinates")
    return parser.parse_args(argv)


def angelica_to_blender(vector: list[float] | tuple[float, ...]) -> tuple[float, float, float]:
    """Convert the Saint Seiya Angelica basis (left-handed, Y-up) to Blender."""
    x, y, z = (float(value) for value in vector)
    return (-x, -z, y)


def make_material(data: dict) -> bpy.types.Material:
    material = bpy.data.materials.new(name=data.get("name") or "AngelicaMaterial")
    material.diffuse_color = tuple(data.get("diffuse", [0.8, 0.8, 0.8, 1.0]))
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled:
        principled.inputs["Base Color"].default_value = material.diffuse_color
        principled.inputs["Metallic"].default_value = 0.35
        principled.inputs["Roughness"].default_value = 0.42
    material["angelica_specular_power"] = float(data.get("power", 0.0))
    material["angelica_two_sided"] = bool(data.get("two_sided", False))
    return material


def make_mesh_object(data: dict, collection: bpy.types.Collection,
                     materials: list[bpy.types.Material], bone_names: list[str], *,
                     saint_seiya_basis: bool = False) -> bpy.types.Object:
    positions = data["positions"]
    source_vertices = [tuple(positions[i:i + 3]) for i in range(0, len(positions), 3)]
    vertices = [angelica_to_blender(vertex) for vertex in source_vertices] if saint_seiya_basis else source_vertices
    indices = data["indices"]
    if len(indices) % 3:
        raise ValueError(f"Mesh {data.get('name')} index count is not divisible by three")
    faces = [tuple(indices[i:i + 3]) for i in range(0, len(indices), 3)]
    # The basis conversion has a negative determinant, so reverse triangle winding.
    if saint_seiya_basis:
        faces = [(face[0], face[2], face[1]) for face in faces]
    mesh = bpy.data.meshes.new(data.get("name") or "AngelicaMesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(data.get("name") or "AngelicaMesh", mesh)
    collection.objects.link(obj)

    uv_values = data.get("uvs", [])
    if len(uv_values) == len(vertices) * 2:
        uv_layer = mesh.uv_layers.new(name="AngelicaUV")
        for polygon in mesh.polygons:
            for loop_index in polygon.loop_indices:
                vertex_index = mesh.loops[loop_index].vertex_index
                uv_layer.data[loop_index].uv = (
                    uv_values[vertex_index * 2],
                    1.0 - uv_values[vertex_index * 2 + 1],
                )

    material_index = int(data.get("material_index", -1))
    for material in materials:
        mesh.materials.append(material)
    if 0 <= material_index < len(materials):
        for polygon in mesh.polygons:
            polygon.material_index = material_index

    normals = data.get("normals", [])
    if len(normals) == len(vertices) * 3:
        for polygon in mesh.polygons:
            polygon.use_smooth = True
        try:
            mesh.normals_split_custom_set_from_vertices(
                ([angelica_to_blender(normals[i:i + 3]) for i in range(0, len(normals), 3)]
                 if saint_seiya_basis else
                 [tuple(normals[i:i + 3]) for i in range(0, len(normals), 3)])
            )
        except (AttributeError, RuntimeError):
            pass

    weights = data.get("bone_weights", [])
    bone_indices = data.get("bone_indices", [])
    if weights and bone_indices and bone_names:
        groups = [obj.vertex_groups.new(name=name or f"Bone_{i}") for i, name in enumerate(bone_names)]
        for vertex_index in range(len(vertices)):
            for slot in range(4):
                offset = vertex_index * 4 + slot
                bone_index = int(bone_indices[offset])
                weight = float(weights[offset])
                if 0 <= bone_index < len(groups) and weight > 0.0001:
                    groups[bone_index].add([vertex_index], weight, "REPLACE")

    if "bone_index" in data:
        obj["angelica_rigid_bone_index"] = int(data["bone_index"])
    obj["angelica_texture_index"] = int(data.get("texture_index", -1))
    obj["angelica_material_index"] = material_index
    return obj


def main() -> int:
    args = parse_args()
    source = args.input.expanduser().resolve(strict=True)
    output = args.output.expanduser().resolve()
    payload = json.loads(source.read_text(encoding="utf-8"))
    if payload.get("schema_version") != 1:
        raise ValueError("Unsupported Angelica SKI JSON schema version")

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.users == 0:
            bpy.data.collections.remove(collection)

    root = bpy.context.scene.collection
    collection = bpy.data.collections.new("Angelica_SKIN")
    root.children.link(collection)
    materials = [make_material(item) for item in payload.get("materials", [])]
    bone_names = payload.get("bone_names", [])

    objects = []
    for item in payload.get("skin_meshes", []):
        objects.append(make_mesh_object(
            item, collection, materials, bone_names,
            saint_seiya_basis=args.saint_seiya_basis,
        ))
    for item in payload.get("rigid_meshes", []):
        objects.append(make_mesh_object(
            item, collection, materials, bone_names,
            saint_seiya_basis=args.saint_seiya_basis,
        ))

    if objects:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]

    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    print(
        "ANGELICA_SKI_BLEND_PASS "
        f"objects={len(objects)} materials={len(materials)} bones={len(bone_names)}"
    )
    print(f"BLEND {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
