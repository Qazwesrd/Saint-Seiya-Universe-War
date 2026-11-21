import hashlib
import tempfile
import unittest
from pathlib import Path

from build_chapter_manifests import CHAPTERS, build_manifest, validate_cdn_url, validate_pck


class ChapterManifestTests(unittest.TestCase):
    def test_manifest_contains_real_pck_size_and_sha256(self):
        with tempfile.TemporaryDirectory() as directory:
            pck = Path(directory) / "galaxy_wars.pck"
            pck.write_bytes(b"GDPC" + bytes(range(64)))
            manifest = build_manifest("galaxy_wars", pck, 3)
            self.assertEqual(manifest["size_bytes"], pck.stat().st_size)
            self.assertEqual(manifest["files"][0]["size_bytes"], pck.stat().st_size)
            self.assertEqual(manifest["files"][0]["sha256"], hashlib.sha256(pck.read_bytes()).hexdigest())
            self.assertEqual(manifest["files"][0]["path"], "galaxy_wars.pck")

    def test_manifest_rejects_invalid_pck_magic(self):
        with tempfile.TemporaryDirectory() as directory:
            pck = Path(directory) / "hades.pck"
            pck.write_bytes(b"NOPE" + bytes(64))
            with self.assertRaisesRegex(ValueError, "Invalid Godot PCK header"):
                validate_pck(pck)

    def test_manifest_rejects_missing_chapter_pck(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "Missing chapter PCK"):
                build_manifest("asgard", Path(directory) / "asgard.pck", 1)

    def test_manifest_rejects_unknown_chapter_id(self):
        with tempfile.TemporaryDirectory() as directory:
            pck = Path(directory) / "custom.pck"
            pck.write_bytes(b"GDPC" + bytes(64))
            with self.assertRaisesRegex(ValueError, "Unsupported chapter ID"):
                build_manifest("unknown", pck, 1)

    def test_cdn_urls_must_be_https_and_end_with_slash(self):
        self.assertEqual(validate_cdn_url("", "Primary"), "")
        self.assertEqual(validate_cdn_url("https://cdn.example.com/game/", "Primary"), "https://cdn.example.com/game/")
        with self.assertRaisesRegex(ValueError, "HTTPS base URL"):
            validate_cdn_url("http://cdn.example.com/game/", "Primary")
        with self.assertRaisesRegex(ValueError, "ending in"):
            validate_cdn_url("https://cdn.example.com/game", "Primary")

    def test_all_seven_chapter_ids_are_covered(self):
        self.assertEqual(len(CHAPTERS), 7)
        self.assertEqual(len(set(CHAPTERS)), 7)


if __name__ == "__main__":
    unittest.main()
