import unittest

from validate_angelica_rig_json import validate_payload


def track(keys, frames=None):
    return {
        "frame_rate": 30,
        "track_length_ms": 1000,
        "keys": keys,
        "key_frame_ids": frames,
    }


def animation():
    return {
        "anim_start": 0,
        "anim_end": 30,
        "anim_fps": 30,
        "bone_tracks": [{
            "bone_id": 0,
            "position": track([[0.0, 0.0, 0.0]], [0]),
            "rotation": track([[0.0, 0.0, 0.0, 1.0]], [0]),
        }],
    }


class AngelicaRigJsonValidationTests(unittest.TestCase):
    def test_valid_stck(self):
        payload = {"schema_version": 1, "kind": "stck", "animation": animation()}
        self.assertEqual(validate_payload(payload), {"tracks": 1, "keys": 2})

    def test_rejects_mismatched_key_frame_ids(self):
        payload = {"schema_version": 1, "kind": "stck", "animation": animation()}
        payload["animation"]["bone_tracks"][0]["position"]["key_frame_ids"] = []
        with self.assertRaisesRegex(ValueError, "count must match"):
            validate_payload(payload)

    def test_rejects_unsorted_frames(self):
        payload = {"schema_version": 1, "kind": "stck", "animation": animation()}
        payload["animation"]["bone_tracks"][0]["position"] = track([[0], [1]], [4, 2])
        with self.assertRaisesRegex(ValueError, "non-decreasing"):
            validate_payload(payload)

    def test_rejects_duplicate_bone_tracks(self):
        payload = {"schema_version": 1, "kind": "stck", "animation": animation()}
        payload["animation"]["bone_tracks"].append(payload["animation"]["bone_tracks"][0])
        with self.assertRaisesRegex(ValueError, "duplicate bone track"):
            validate_payload(payload)

    def test_rejects_non_finite_key_data(self):
        payload = {"schema_version": 1, "kind": "stck", "animation": animation()}
        payload["animation"]["bone_tracks"][0]["position"]["keys"] = [[float("nan")]]
        with self.assertRaisesRegex(ValueError, "non-finite"):
            validate_payload(payload)

    def test_valid_bon_without_embedded_animation(self):
        matrix = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
        payload = {
            "schema_version": 1,
            "kind": "bon",
            "bones": [{
                "name": "Root",
                "parent": -1,
                "mat_relative": matrix,
                "mat_bone_init": matrix,
            }],
            "embedded_animation": None,
        }
        self.assertEqual(validate_payload(payload), {"bones": 1, "tracks": 0, "keys": 0})


if __name__ == "__main__":
    unittest.main()
