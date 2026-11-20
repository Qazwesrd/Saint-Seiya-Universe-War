import json
import struct
import tempfile
import unittest
from pathlib import Path

from validate_authored_assets import (
    ARMOR_PART_NODES,
    check_glb,
    safe_path,
    validate_armor_manifest,
    validate_vfx_manifest,
    validate_character_visual_catalog,
)

def write_glb(path: Path, nodes: list[str]) -> None:
    document = {
        "asset": {"version": "2.0"},
        "meshes": [{"name": name} for name in nodes],
        "skins": [{"joints": [0]}],
        "nodes": [{"name": name, "mesh": index, "skin": 0} for index, name in enumerate(nodes)],
    }
    payload = json.dumps(document).encode("utf-8")
    payload += b" " * ((4 - len(payload) % 4) % 4)
    total = 12 + 8 + len(payload)
    path.write_bytes(b"glTF" + struct.pack("<II", 2, total) +
                     struct.pack("<II", len(payload), 0x4E4F534A) + payload)

class ArtValidatorTests(unittest.TestCase):
    def test_glb_requires_all_declared_nodes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "armor.glb"
            write_glb(path, list(ARMOR_PART_NODES.values()))
            check_glb(path, required_nodes=tuple(ARMOR_PART_NODES.values()))

    def test_glb_rejects_missing_detachable_armor_piece(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "armor.glb"
            names = list(ARMOR_PART_NODES.values())[:-1]
            write_glb(path, names)
            with self.assertRaisesRegex(ValueError, "missing required"):
                check_glb(path, required_nodes=tuple(ARMOR_PART_NODES.values()))

    def test_armor_manifest_requires_exact_nine_parts(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "armor.glb"
            write_glb(path, list(ARMOR_PART_NODES.values()))
            data = {"parts": {key: "complete" for key in ARMOR_PART_NODES}}
            validate_armor_manifest(data, path)
            data["parts"]["helmet"] = "pending"
            with self.assertRaisesRegex(ValueError, "not all nine"):
                validate_armor_manifest(data, path)

    def test_armor_parts_must_be_independent_skinned_meshes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "armor.glb"
            write_glb(path, list(ARMOR_PART_NODES.values()))
            document = json.loads((path.read_bytes()[20:]).decode("utf-8").rstrip(" \t\r\n\0"))
            document["nodes"][1]["mesh"] = document["nodes"][0]["mesh"]
            payload = json.dumps(document).encode("utf-8")
            payload += b" " * ((4 - len(payload) % 4) % 4)
            total = 12 + 8 + len(payload)
            path.write_bytes(b"glTF" + struct.pack("<II", 2, total) +
                             struct.pack("<II", len(payload), 0x4E4F534A) + payload)
            data = {"parts": {key: "complete" for key in ARMOR_PART_NODES}}
            with self.assertRaisesRegex(ValueError, "own mesh"):
                validate_armor_manifest(data, path)

    def test_vfx_manifest_requires_three_quality_tiers_and_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            scene = Path(directory) / "effect.tscn"
            scene.write_text('[gd_scene format=3]\n[node name="Particles" type="GPUParticles3D"]\n', encoding="utf-8")
            data = {
                "quality_tiers": {"low": "complete", "medium": "complete", "high": "complete"},
                "performance_budget": {"max_particles": 96, "max_transparent_layers": 3, "max_lifetime_seconds": 2.5},
            }
            validate_vfx_manifest(data, scene)
            data["quality_tiers"]["high"] = "not_created"
            with self.assertRaisesRegex(ValueError, "all three"):
                validate_vfx_manifest(data, scene)

    def test_character_catalog_has_32_distinct_geometry_identities(self):
        self.assertEqual(validate_character_visual_catalog(), [])

    def test_animation_clip_must_contain_real_tracks(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "animations.glb"
            document = {
                "asset": {"version": "2.0"},
                "animations": [{"name": "idle", "channels": [], "samplers": []}],
            }
            payload = json.dumps(document).encode("utf-8")
            payload += b" " * ((4 - len(payload) % 4) % 4)
            total = 12 + 8 + len(payload)
            path.write_bytes(b"glTF" + struct.pack("<II", 2, total) +
                             struct.pack("<II", len(payload), 0x4E4F534A) + payload)
            with self.assertRaisesRegex(ValueError, "no animation tracks"):
                check_glb(path, clips=["idle"], require_meshes=False)

    def test_glb_rejects_mesh_without_skin_binding(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "character.glb"
            write_glb(path, ["Body"])
            document = json.loads(path.read_bytes()[20:].decode("utf-8").rstrip(" \t\r\n\0"))
            document["nodes"][0].pop("skin")
            payload = json.dumps(document).encode("utf-8")
            payload += b" " * ((4 - len(payload) % 4) % 4)
            total = 12 + 8 + len(payload)
            path.write_bytes(b"glTF" + struct.pack("<II", 2, total) +
                             struct.pack("<II", len(payload), 0x4E4F534A) + payload)
            with self.assertRaisesRegex(ValueError, "not bound to a valid skin"):
                check_glb(path, require_skin=True)

    def test_animation_rejects_out_of_range_target_node(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "animations.glb"
            document = {
                "asset": {"version": "2.0"},
                "nodes": [{}],
                "accessors": [{"count": 2}, {"count": 2}],
                "animations": [{
                    "name": "idle",
                    "samplers": [{"input": 0, "output": 1}],
                    "channels": [{"sampler": 0, "target": {"node": 9, "path": "rotation"}}],
                }],
            }
            payload = json.dumps(document).encode("utf-8")
            payload += b" " * ((4 - len(payload) % 4) % 4)
            total = 12 + 8 + len(payload)
            path.write_bytes(b"glTF" + struct.pack("<II", 2, total) +
                             struct.pack("<II", len(payload), 0x4E4F534A) + payload)
            with self.assertRaisesRegex(ValueError, "invalid track node"):
                check_glb(path, clips=["idle"], require_meshes=False)

    def test_safe_path_rejects_traversal(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                safe_path(Path(directory), "../outside.glb")

if __name__ == "__main__":
    unittest.main()
