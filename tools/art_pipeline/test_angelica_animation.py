import unittest

from angelica_animation import frame_for_key, unpack_track_keys, xyzw_to_wxyz


class AngelicaAnimationTests(unittest.TestCase):
    def test_unpack_flat_position_keys(self):
        track = {"keys": [0, 1, 2, 3, 4, 5], "key_frame_ids": [0, 12]}
        self.assertEqual(unpack_track_keys(track, 3, "position"), [
            (0, (0.0, 1.0, 2.0)), (12, (3.0, 4.0, 5.0))
        ])

    def test_v1_without_frame_ids_uses_order(self):
        track = {"keys": [1, 2, 3, 4, 5, 6], "key_frame_ids": None}
        self.assertEqual([frame for frame, _ in unpack_track_keys(track, 3, "position")], [0, 1])

    def test_rejects_misaligned_values(self):
        with self.assertRaisesRegex(ValueError, "multiple of 3"):
            unpack_track_keys({"keys": [1, 2], "key_frame_ids": None}, 3, "position")

    def test_rejects_frame_count_mismatch(self):
        with self.assertRaisesRegex(ValueError, "does not match"):
            unpack_track_keys({"keys": [1, 2, 3], "key_frame_ids": [0, 1]}, 3, "position")

    def test_converts_xyzw_to_blender_wxyz(self):
        self.assertEqual(xyzw_to_wxyz((0.1, 0.2, 0.3, 0.9)), (0.9, 0.1, 0.2, 0.3))

    def test_converts_track_time_to_scene_frames(self):
        self.assertAlmostEqual(
            frame_for_key(15, anim_start=30, anim_fps=30, track_fps=30, scene_fps=60),
            91.0,
        )


if __name__ == "__main__":
    unittest.main()
