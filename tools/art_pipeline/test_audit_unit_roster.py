import unittest

from audit_unit_roster import audit_sources


class UnitRosterAuditTests(unittest.TestCase):
    def test_audit_reports_class_skill_and_enemy_gaps_without_count_inflation(self):
        class_data = '''const CLASS_DATA := {
 "pegasus": {"name":"天马座"},
 "dragon": {"name":"天龙座"},
}'''
        visuals = '''const PROFILES := {
    "pegasus": {"crest":"wing"},
    "dragon": {"crest":"horn"},
}'''
        skills = '''const CLASS_SKILLS := {
    "pegasus": {"abilities": [
        {"id":"p1"}, {"id":"p2"}
    ], "passive": {}},
}'''
        enemies = '''const ARCHETYPES := {
    "guard": {"is_boss": false},
    "boss": {"is_boss": true},
}'''
        report = audit_sources(class_data, visuals, skills, enemies)
        self.assertEqual(report["playable_classes_registered"], 2)
        self.assertEqual(report["playable_classes_missing_from_target"], 74)
        self.assertEqual(report["visual_profiles"], 2)
        self.assertEqual(report["class_skill_profiles"], 1)
        self.assertEqual(report["classes_missing_skill_profiles"], ["dragon"])
        self.assertEqual(report["skill_counts_by_class"], {"pegasus": 2})
        self.assertEqual(report["skill_deficits_by_class"], {"pegasus": 22})
        self.assertEqual(report["enemy_archetypes"], 2)
        self.assertEqual(report["boss_archetypes"], 1)
        self.assertEqual(report["non_boss_archetypes"], 1)
        self.assertEqual(report["status"], "incomplete")

    def test_audit_detects_visual_profiles_not_backed_by_playable_classes(self):
        report = audit_sources(
            'const CLASS_DATA := {\n "pegasus": {"name":"天马座"},\n}',
            'const PROFILES := {\n    "dragon": {"crest":"horn"},\n}',
            'const CLASS_SKILLS := {\n}',
            'const ARCHETYPES := {\n    "guard": {"is_boss": false},\n}',
        )
        self.assertEqual(report["visual_profiles_missing"], ["pegasus"])
        self.assertEqual(report["orphan_visual_profiles"], ["dragon"])


if __name__ == "__main__":
    unittest.main()
