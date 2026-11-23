#!/usr/bin/env python3
"""Unit tests for the read-only five-Bronze-Saint asset discovery pipeline."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from find_saint_seiya_candidates import entries_from
from build_character_asset_bundles import build_bundle, load_candidates


class CandidateInventoryTests(unittest.TestCase):
    def test_accepts_pck_inventory_schema_and_preserves_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "pck_inventory.json"
            source.write_text(json.dumps({
                "files": [
                    {"path": "models/pegasus/seiya.ski", "extension": ".ski",
                     "size_bytes": 123, "compressed_size_bytes": 45},
                    {"path": "models/pegasus/seiya.txt", "extension": ".txt"},
                ]
            }), encoding="utf-8")
            rows = entries_from(source)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["size_bytes"], 123)
        self.assertEqual(rows[0]["extension"], ".ski")

    def test_accepts_client_inventory_relative_path_and_chinese_names(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "client_inventory.json"
            source.write_text(json.dumps({"files": [
                {"relative_path": "角色/紫龙/天龙.ski"},
                {"relative_path": "角色/冰河/白鸟.stck"},
                {"relative_path": "角色/一辉/凤凰.dds"},
            ]}, ensure_ascii=False), encoding="utf-8")
            rows = entries_from(source)
        self.assertEqual([row["extension"] for row in rows], [".ski", ".stck", ".dds"])
        self.assertIn("紫龙", rows[0]["path"])

    def test_filters_to_supported_asset_extensions(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "inventory.json"
            source.write_text(json.dumps({"files": [
                "models/pegasus/seiya.ski",
                "models/pegasus/seiya.txt",
            ]}), encoding="utf-8")
            rows = entries_from(source)
        accepted = [row for row in rows if row["extension"] in {
            ".ski", ".smd", ".bon", ".stck", ".ecm", ".gfx", ".dds", ".tga", ".anm"
        }]
        self.assertEqual([row["path"] for row in accepted], ["models/pegasus/seiya.ski"])


class AssetBundleTests(unittest.TestCase):
    def test_groups_same_folder_and_stem_but_marks_unverified(self):
        bundles = build_bundle([
            {"path": "models/seiya/body.ski", "extension": ".ski"},
            {"path": "models/seiya/body.bon", "extension": ".bon"},
            {"path": "models/seiya/body.dds", "extension": ".dds"},
        ])
        self.assertEqual(len(bundles), 1)
        self.assertEqual(bundles[0]["relationship"], "same_folder_and_stem")
        self.assertEqual(set(bundles[0]["asset_kinds"]), {"mesh", "skeleton", "texture"})
        self.assertFalse(bundles[0]["verified"])

    def test_does_not_merge_different_folders_or_stems(self):
        bundles = build_bundle([
            {"path": "models/seiya/body.ski", "extension": ".ski"},
            {"path": "models/ikki/body.bon", "extension": ".bon"},
            {"path": "models/seiya/head.ski", "extension": ".ski"},
        ])
        self.assertEqual(len(bundles), 3)
        self.assertTrue(all(item["relationship"] == "single_file_candidate" for item in bundles))

    def test_load_candidates_rejects_unexpected_schema(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "bad.json"
            source.write_text(json.dumps({"files": []}), encoding="utf-8")
            with self.assertRaises(ValueError):
                load_candidates(source)


if __name__ == "__main__":
    unittest.main()
