from __future__ import annotations

import unittest

from angelica_ecm import validate_ecm_payload, validate_ecm_graph


def sample(path: str = "models/character.ecm", child_path: str = "models/armor.ecm") -> dict:
    return {
        "schema_version": 1,
        "kind": "ecm",
        "source_entry": path,
        "ecm_version": 1,
        "skin_model_path": "models/character.smd",
        "children": [{
            "slot": "body_armor",
            "path": child_path,
            "parent_hook": "HH_body",
            "child_hook": "CC_body",
        }],
        "bone_scales": [{"bone_index": 2, "scale": [1.0, 1.0, 1.0], "scale_type": 0}],
        "combine_actions": [{"name": "idle", "loop_count": 0, "events": [{
            "event_type": 100, "fx_file_path": "gfx/idle.gfx", "hook_offset": [0.0, 0.0, 0.0]
        }]}],
        "co_gfx": ["gfx/aura.gfx"],
    }


class AngelicaEcmTests(unittest.TestCase):
    def test_valid_payload(self):
        self.assertEqual(validate_ecm_payload(sample()), {
            "children": 1, "bone_scales": 1, "actions": 1, "events": 1
        })

    def test_parent_hook_must_exist_when_bon_hooks_supplied(self):
        with self.assertRaisesRegex(ValueError, "not found"):
            validate_ecm_payload(sample(), known_parent_hooks={"HH_head"})

    def test_duplicate_attachment_slot_rejected(self):
        data = sample()
        data["children"].append(dict(data["children"][0], path="models/other.ecm"))
        with self.assertRaisesRegex(ValueError, "duplicate slot"):
            validate_ecm_payload(data)

    def test_parent_path_traversal_rejected(self):
        data = sample()
        data["children"][0]["path"] = "../outside.ecm"
        with self.assertRaisesRegex(ValueError, "traversal"):
            validate_ecm_payload(data)

    def test_absolute_resource_path_rejected(self):
        data = sample()
        data["skin_model_path"] = "C:/private/model.smd"
        with self.assertRaisesRegex(ValueError, "absolute"):
            validate_ecm_payload(data)

    def test_non_finite_bone_scale_rejected(self):
        data = sample()
        data["bone_scales"][0]["scale"][1] = float("nan")
        with self.assertRaisesRegex(ValueError, "finite"):
            validate_ecm_payload(data)

    def test_duplicate_bone_scale_rejected(self):
        data = sample()
        data["bone_scales"].append(dict(data["bone_scales"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate bone scale"):
            validate_ecm_payload(data)

    def test_missing_event_asset_path_is_allowed(self):
        data = sample()
        data["combine_actions"][0]["events"][0]["fx_file_path"] = ""
        self.assertEqual(validate_ecm_payload(data)["events"], 1)

    def test_graph_reports_unresolved_child(self):
        result = validate_ecm_graph([sample()])
        self.assertEqual(result["unresolved_edges"], 1)

    def test_graph_resolves_child_reference(self):
        root = sample()
        child = sample("models/armor.ecm", "models/material.ecm")
        result = validate_ecm_graph([root, child])
        self.assertEqual(result["resolved_edges"], 1)

    def test_graph_detects_cycles(self):
        first = sample("models/a.ecm", "models/b.ecm")
        second = sample("models/b.ecm", "models/a.ecm")
        with self.assertRaisesRegex(ValueError, "cycle"):
            validate_ecm_graph([first, second])

    def test_strict_graph_rejects_unresolved_child(self):
        with self.assertRaisesRegex(ValueError, "unresolved"):
            validate_ecm_graph([sample()], require_all_children=True)


if __name__ == "__main__":
    unittest.main()
