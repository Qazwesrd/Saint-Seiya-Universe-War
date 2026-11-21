import importlib.util
import unittest
from pathlib import Path
from types import SimpleNamespace

SCRIPT = Path(__file__).with_name("export_angelica_ski_json.py")
SPEC = importlib.util.spec_from_file_location("export_angelica_ski_json", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


def mesh(weighted=True):
    base = {
        "name": "chest",
        "positions": [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0],
        "normals": [0.0, 0.0, 1.0] * 3,
        "uvs": [0.0, 0.0, 1.0, 0.0, 0.0, 1.0],
        "indices": [0, 1, 2],
        "texture_index": 0,
        "material_index": 0,
    }
    if weighted:
        base.update({"bone_weights": [1.0, 0.0, 0.0, 0.0] * 3, "bone_indices": [0, 0, 0, 0] * 3})
    else:
        base["bone_index"] = 0
    return SimpleNamespace(**base)


class AngelicaSkiJsonTests(unittest.TestCase):
    def test_exports_mesh_geometry_and_skinning_data(self):
        payload = MODULE._mesh_payload(mesh(), weighted=True)
        self.assertEqual(len(payload["positions"]), 9)
        self.assertEqual(payload["indices"], [0, 1, 2])
        self.assertEqual(len(payload["bone_weights"]), 12)

    def test_rejects_out_of_range_triangle_index(self):
        invalid = mesh()
        invalid.indices = [0, 1, 9]
        with self.assertRaisesRegex(ValueError, "Triangle index out of range"):
            MODULE._mesh_payload(invalid, weighted=True)

    def test_builds_complete_skin_payload(self):
        material = SimpleNamespace(
            name="bronze",
            ambient=(0.1, 0.1, 0.1, 1.0),
            diffuse=(0.8, 0.5, 0.2, 1.0),
            emissive=(0.0, 0.0, 0.0, 1.0),
            specular=(1.0, 1.0, 1.0, 1.0),
            power=24.0,
            two_sided=False,
        )
        skin = SimpleNamespace(
            version=9,
            textures=["textures/bronze.dds"],
            bone_names=["Bip01"],
            num_ske_bone=1,
            materials=[material],
            skin_meshes=[mesh(True)],
            rigid_meshes=[mesh(False)],
        )
        payload = MODULE.build_payload("models/pegasus.ski", skin)
        self.assertEqual(payload["ski_version"], 9)
        self.assertEqual(payload["materials"][0]["name"], "bronze")
        self.assertEqual(payload["rigid_meshes"][0]["bone_index"], 0)
        self.assertEqual(payload["source_entry"], "models/pegasus.ski")


if __name__ == "__main__":
    unittest.main()
