#!/usr/bin/env python3
"""Unit tests for the read-only Angelica dependency tracer."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from trace_character_dependencies import build_report


class FakePackage:
    def __init__(self, files):
        self.files = files

    def file_list(self):
        return list(self.files)

    def get_file(self, path):
        return self.files.get(path)


class FakeAngelica:
    @staticmethod
    def read_ecm(_blob):
        return SimpleNamespace(
            skin_model_path="models/seiya.smd",
            child_count=0, co_gfx_count=0, combine_action_count=0,
            get_child=lambda _index: None,
            co_gfx_fx_file_path=lambda _index: "",
            combine_action_name=lambda _index: "",
        )

    @staticmethod
    def read_smd(_blob):
        return SimpleNamespace(
            skeleton_path="skeletons/seiya.bon",
            skin_paths=["skins/seiya.ski"],
            actions=[SimpleNamespace(name="idle", start_frame=0, end_frame=30,
                                     tck_file="anims/seiya_idle.stck")],
        )

    @staticmethod
    def read_skin(_blob):
        return SimpleNamespace(version=9, bone_names=["root", "spine"],
                               textures=["textures/seiya.dds"], materials=[])

    @staticmethod
    def read_skeleton(_blob):
        return SimpleNamespace(version=6, bones=[
            SimpleNamespace(name="root", parent=-1, children=[1]),
            SimpleNamespace(name="spine", parent=0, children=[]),
        ], hooks=[SimpleNamespace(name="HH_lefthandweapon", bone_index=1)])

    @staticmethod
    def read_animation(_blob):
        return SimpleNamespace(anim_fps=30, anim_start=0, anim_end=30,
                               bone_tracks=[SimpleNamespace(bone_id=0)])


class DependencyTracerTests(unittest.TestCase):
    def test_walks_ecm_smd_ski_bon_stck_and_texture_references(self):
        package = FakePackage({
            "characters/seiya.ecm": b"ecm",
            # These are archive-root-relative, not relative to characters/.
            "models/seiya.smd": b"smd",
            "skeletons/seiya.bon": b"bon",
            "skins/seiya.ski": b"ski",
            "anims/seiya_idle.stck": b"stck",
            "textures/seiya.dds": b"dds",
        })
        report = build_report(package, FakeAngelica, ["characters/seiya.ecm"])
        paths = {node["path"] for node in report["nodes"]}
        self.assertEqual(paths, set(package.files))
        self.assertEqual(report["missing_references"], [])
        self.assertEqual(report["parse_errors"], [])
        ski = next(node for node in report["nodes"] if node["extension"] == ".ski")
        self.assertEqual(ski["textures"], ["textures/seiya.dds"])
        bon = next(node for node in report["nodes"] if node["extension"] == ".bon")
        self.assertEqual(bon["hooks"][0]["name"], "HH_lefthandweapon")

    def test_reports_missing_references_without_failing(self):
        package = FakePackage({"characters/seiya.ecm": b"ecm"})
        report = build_report(package, FakeAngelica, ["characters/seiya.ecm"])
        self.assertIn("models/seiya.smd", report["missing_references"])
        self.assertEqual(report["parse_errors"], [])


if __name__ == "__main__":
    unittest.main()
