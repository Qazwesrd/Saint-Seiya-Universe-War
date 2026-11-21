import unittest

from audit_unit_roster import audit_sources


class UnitRosterAuditTests(unittest.TestCase):
    def test_audit_checks_dark_and_platinum_passive_coverage_and_unique_names(self):
        armor = '''const DARK_CLASS_PASSIVES := {
    "pegasus": {"name":"暗影流星"},
    "dragon": {"name":"黑曜龙盾"},
}
const PLATINUM_CLASS_PASSIVES := {
    "pegasus": {"name":"星辉流星"},
    "dragon": {"name":"天穹龙壁"},
}'''
        report = audit_sources(
            'const CLASS_DATA := {\n "pegasus": {"name":"天马座"},\n "dragon": {"name":"天龙座"},\n}',
            'const PROFILES := {\n    "pegasus": {"crest":"wing"},\n    "dragon": {"crest":"horn"},\n}',
            'const CLASS_SKILLS := {\n}\nconst DIVINE_CLASS_SKILLS := {\n}\nconst EXTENDED_DIVINE_CLASS_SKILLS := {\n}\nconst HEAVENLY_CLASS_SKILLS := {\n}\nconst ADVANCED_CLASS_SKILLS := {\n}\nconst DIVINE_ADVANCED_SKILLS := {\n}\nconst EXTENDED_DIVINE_ADVANCED_SKILLS := {\n}\nconst HEAVENLY_ADVANCED_SKILLS := {\n}',
            'const ARCHETYPES := {\n    "guard": {"is_boss": false},\n}',
            armor,
        )
        self.assertEqual(report["dark_cloth_passives"]["missing"], [])
        self.assertEqual(report["platinum_cloth_passives"]["missing"], [])
        self.assertEqual(report["dark_cloth_passives"]["registered"], 2)
        self.assertEqual(report["platinum_cloth_passives"]["registered"], 2)

    def test_audit_detects_duplicate_platinum_passive_names(self):
        armor = '''const DARK_CLASS_PASSIVES := {
    "pegasus": {"name":"暗影流星"},
    "dragon": {"name":"黑曜龙盾"},
}
const PLATINUM_CLASS_PASSIVES := {
    "pegasus": {"name":"星辉流星"},
    "dragon": {"name":"星辉流星"},
}'''
        report = audit_sources(
            'const CLASS_DATA := {\n "pegasus": {"name":"天马座"},\n "dragon": {"name":"天龙座"},\n}',
            'const PROFILES := {\n    "pegasus": {"crest":"wing"},\n    "dragon": {"crest":"horn"},\n}',
            'const CLASS_SKILLS := {\n}\nconst DIVINE_CLASS_SKILLS := {\n}\nconst EXTENDED_DIVINE_CLASS_SKILLS := {\n}\nconst HEAVENLY_CLASS_SKILLS := {\n}\nconst ADVANCED_CLASS_SKILLS := {\n}\nconst DIVINE_ADVANCED_SKILLS := {\n}\nconst EXTENDED_DIVINE_ADVANCED_SKILLS := {\n}\nconst HEAVENLY_ADVANCED_SKILLS := {\n}',
            'const ARCHETYPES := {\n    "guard": {"is_boss": false},\n}',
            armor,
        )
        self.assertEqual(report["platinum_cloth_passives"]["duplicate_names"], ["星辉流星"])
        self.assertEqual(report["status"], "incomplete")

    def test_audit_merges_base_and_advanced_skill_catalogs(self):
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
}
const DIVINE_CLASS_SKILLS := {
}
const EXTENDED_DIVINE_CLASS_SKILLS := {
}
const HEAVENLY_CLASS_SKILLS := {
}
const ADVANCED_CLASS_SKILLS := {
    "pegasus": [
        {"id":"p3"}, {"id":"p4"}
    ],
}
const DIVINE_ADVANCED_SKILLS := {
}
const EXTENDED_DIVINE_ADVANCED_SKILLS := {
}
const HEAVENLY_ADVANCED_SKILLS := {
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
        self.assertEqual(report["skill_counts_by_class"]["pegasus"], 4)
        self.assertEqual(report["skill_deficits_by_class"], {"pegasus": 20, "dragon": 24})
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

    def test_audit_counts_24_distinct_skills_across_all_skill_tables(self):
        base = ", ".join('{"id":"skill_%d"}' % i for i in range(1, 7))
        advanced = ", ".join('{"id":"advanced_%d"}' % i for i in range(1, 19))
        skill_source = f'''const CLASS_SKILLS := {{
    "pegasus": {{"abilities": [{base}], "passive": {{}}}},
}}
const DIVINE_CLASS_SKILLS := {{
}}
const EXTENDED_DIVINE_CLASS_SKILLS := {{
}}
const HEAVENLY_CLASS_SKILLS := {{
}}
const ADVANCED_CLASS_SKILLS := {{
    "pegasus": [{advanced}],
}}
const DIVINE_ADVANCED_SKILLS := {{
}}
const EXTENDED_DIVINE_ADVANCED_SKILLS := {{
}}
const HEAVENLY_ADVANCED_SKILLS := {{
}}'''
        report = audit_sources(
            'const CLASS_DATA := {\n "pegasus": {"name":"天马座"},\n}',
            'const PROFILES := {\n    "pegasus": {"crest":"wing"},\n}',
            skill_source,
            'const ARCHETYPES := {\n    "guard": {"is_boss": false},\n}',
        )
        self.assertEqual(report["skill_counts_by_class"]["pegasus"], 24)
        self.assertEqual(report["skill_deficits_by_class"], {})


    def test_audit_includes_divine_advanced_skills_with_four_space_catalog_indent(self):
        base = ", ".join('{"id":"divine_%d"}' % i for i in range(1, 7))
        advanced = ", ".join('{"id":"divine_advanced_%d"}' % i for i in range(1, 19))
        skill_source = f'''const CLASS_SKILLS := {{
}}
const DIVINE_CLASS_SKILLS := {{
    "apollo": {{"abilities": [{base}], "passive": {{}}}},
}}
const EXTENDED_DIVINE_CLASS_SKILLS := {{
}}
const HEAVENLY_CLASS_SKILLS := {{
}}
const ADVANCED_CLASS_SKILLS := {{
}}
const DIVINE_ADVANCED_SKILLS := {{
    "apollo": [{advanced}],
}}
const EXTENDED_DIVINE_ADVANCED_SKILLS := {{
}}
const HEAVENLY_ADVANCED_SKILLS := {{
}}'''
        report = audit_sources(
            'const CLASS_DATA := {\n "apollo": {"name":"阿波罗"},\n}',
            'const PROFILES := {\n    "apollo": {"crest":"sun"},\n}',
            skill_source,
            'const ARCHETYPES := {\n    "guard": {"is_boss": false},\n}',
        )
        self.assertEqual(report["skill_counts_by_class"]["apollo"], 24)
        self.assertEqual(report["skill_deficits_by_class"], {})


if __name__ == "__main__":
    unittest.main()
