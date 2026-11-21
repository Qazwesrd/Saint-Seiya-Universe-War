import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("inventory_angelica_client.py")
SPEC = importlib.util.spec_from_file_location("inventory_angelica_client", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


class AngelicaInventoryTests(unittest.TestCase):
    def test_detects_known_extensions_and_hashes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "client"
            root.mkdir()
            (root / "sample.ski").write_bytes(b"mesh-data")
            (root / "sample.pck").write_bytes(b"PCK\x00sample")
            ski = MODULE.inspect_file(root / "sample.ski", root, True)
            pck = MODULE.inspect_file(root / "sample.pck", root, True)
            self.assertEqual(ski["type_hint"], "Angelica mesh")
            self.assertEqual(len(ski["sha256"]), 64)
            self.assertEqual(pck["type_hint"], "Angelica package archive")
            self.assertTrue(pck["sha256"])

    def test_detects_texture_magic(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            image = root / "texture.bin"
            image.write_bytes(b"DDS " + b"\x00" * 20)
            record = MODULE.inspect_file(image, root, False)
            self.assertEqual(record["magic_hint"], "DDS texture")
            self.assertEqual(record["sha256"], "")

    def test_refuses_output_inside_client_tree(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "client"
            root.mkdir()
            output = root / "inventory"
            output.mkdir()
            self.assertEqual(output, root / "inventory")
            self.assertTrue(output == root or root in output.parents)

    def test_split_archive_and_animation_extensions_are_catalogued(self):
        for extension, expected in (
            (".pkx", "Angelica split package continuation"),
            (".bon", "Angelica skeleton"),
            (".stck", "Angelica animation"),
            (".ecm", "Angelica entity/model container"),
            (".anm", "Angelica cutscene animation"),
        ):
            with self.subTest(extension=extension):
                self.assertEqual(MODULE.KNOWN_EXTENSIONS[extension], expected)


if __name__ == "__main__":
    unittest.main()
