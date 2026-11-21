import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

SCRIPT = Path(__file__).with_name("export_angelica_rig_json.py")
SPEC = importlib.util.spec_from_file_location("export_angelica_rig_json", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


class AngelicaRigJsonTests(unittest.TestCase):

    def test_normalizes_autoangel_lookup_paths(self):
        self.assertEqual(MODULE.normalize_package_lookup_path("Models/Pegasus/Body.SKI"), r"models\pegasus\body.ski")

    def test_normalizes_windows_archive_paths(self):
        self.assertEqual(MODULE.normalize_entry_path(r"Models\Pegasus\idle.stck"), "Models/Pegasus/idle.stck")

    def test_writes_valid_json_with_real_newline(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "nested" / "rig.json"
            MODULE.write_payload(output, {"ok": True})
            raw = output.read_bytes()
            self.assertTrue(raw.endswith(b"\\n"))
            self.assertFalse(raw.endswith(b"\\\\n"))
            self.assertEqual(json.loads(raw.decode("utf-8")), {"ok": True})

    def test_serializes_bon_bones_hooks_and_embedded_animation(self):
        track = SimpleNamespace(
            frame_rate=30,
            track_length_ms=1000,
            keys=[0.0, 1.0, 2.0],
            key_frame_ids=[0],
        )
        animation = SimpleNamespace(
            anim_start=0,
            anim_end=30,
            anim_fps=30,
            bone_tracks=[SimpleNamespace(bone_id=0, position=track, rotation=track)],
        )
        bone = SimpleNamespace(
            name="Bip01",
            parent=-1,
            children=[1],
            mat_relative=[1.0] * 16,
            mat_bone_init=[2.0] * 16,
            is_fake=False,
            is_flipped=False,
        )
        hook = SimpleNamespace(name="HH_weapon", hook_type=1, bone_index=0, transform=[1.0] * 16)
        skeleton = SimpleNamespace(version=5, bones=[bone], hooks=[hook], embedded_animation=animation)
        payload = MODULE.build_payload("models/hero.bon", skeleton, "bon")
        self.assertEqual(payload["bones"][0]["name"], "Bip01")
        self.assertEqual(payload["hooks"][0]["bone_index"], 0)
        self.assertEqual(payload["embedded_animation"]["bone_tracks"][0]["bone_id"], 0)

    def test_serializes_stck_track_keyframe_ids(self):
        track = SimpleNamespace(
            frame_rate=24,
            track_length_ms=2000,
            keys=[0.0, 0.0, 0.0],
            key_frame_ids=None,
        )
        animation = SimpleNamespace(
            anim_start=0,
            anim_end=48,
            anim_fps=24,
            bone_tracks=[SimpleNamespace(bone_id=2, position=track, rotation=track)],
        )
        payload = MODULE.build_payload("motions/run.stck", animation, "stck")
        self.assertEqual(payload["animation"]["anim_fps"], 24)
        self.assertIsNone(payload["animation"]["bone_tracks"][0]["position"]["key_frame_ids"])

    def test_rejects_unknown_kind(self):
        with self.assertRaisesRegex(ValueError, "Unsupported resource kind"):
            MODULE.build_payload("file.dat", SimpleNamespace(), "dat")


if __name__ == "__main__":
    unittest.main()
