import importlib.util
import unittest
from pathlib import Path
from types import SimpleNamespace

SCRIPT = Path(__file__).with_name("inventory_angelica_pck.py")
SPEC = importlib.util.spec_from_file_location("inventory_angelica_pck", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


class AngelicaPckInventoryTests(unittest.TestCase):
    def test_normalizes_entry_metadata_and_windows_paths(self):
        entry = SimpleNamespace(
            path="Models\\Pegasus\\body.ski",
            size=1234,
            compressed_size=456,
            hash=987654,
        )
        result = MODULE._normalize_entry(entry)
        self.assertEqual(result["path"], "Models/Pegasus/body.ski")
        self.assertEqual(result["extension"], ".ski")
        self.assertEqual(result["size_bytes"], 1234)
        self.assertEqual(result["compressed_size_bytes"], 456)

    def test_builds_sorted_report_and_extension_counts(self):
        package = SimpleNamespace(file_list=lambda: [
            SimpleNamespace(path="z/idle.stck", size=10, compressed_size=8, hash=1),
            SimpleNamespace(path="a/body.ski", size=20, compressed_size=12, hash=2),
            SimpleNamespace(path="a/head.ski", size=5, compressed_size=4, hash=3),
        ])
        report = MODULE.build_report(Path("/tmp/sample.pck"), [], package)
        self.assertEqual(report["file_count"], 3)
        self.assertEqual(report["files"][0]["path"], "a/body.ski")
        self.assertEqual(report["extension_counts"][".ski"], 2)
        self.assertIn("Read-only", report["safety"])


    def test_reads_real_entry_metadata_when_scan_api_is_available(self):
        package = SimpleNamespace(
            file_list=lambda: ["models/body.ski", "motions/idle.stck"],
            scan_entries=lambda *, paths, on_chunk: on_chunk([
                SimpleNamespace(path=paths[0], size=2048, compressed_size=1024, hash=123),
                SimpleNamespace(path=paths[1], size=4096, compressed_size=2048, hash=456),
            ]),
        )
        report = MODULE.build_report(Path("/tmp/models.pck"), [], package)
        self.assertEqual(report["files"][0]["size_bytes"], 2048)
        self.assertEqual(report["files"][1]["compressed_size_bytes"], 2048)
        self.assertEqual(report["files"][1]["archive_hash"], 456)

    def test_accepts_string_entries_from_library(self):
        result = MODULE._normalize_entry("textures/bronze.dds")
        self.assertEqual(result["path"], "textures/bronze.dds")
        self.assertEqual(result["extension"], ".dds")
        self.assertIsNone(result["size_bytes"])


if __name__ == "__main__":
    unittest.main()
