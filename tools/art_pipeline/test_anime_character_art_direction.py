#!/usr/bin/env python3
"""Regression checks for anime identity, unique presentation poses and armor palettes."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VISUAL = ROOT / "game/scripts/character_visual_catalog.gd"
GENERATOR = ROOT / "tools/art_pipeline/blender/generate_base_rig.py"
WORKFLOW = ROOT / ".github/workflows/blender-art-pipeline.yml"
DIRECTION = ROOT / "docs/ANIME_CHARACTER_ART_DIRECTION.md"
MANIFEST_BUILDER = ROOT / "tools/art_pipeline/build_manifests.py"


def dictionary_ids(source: str, marker: str, indent: int) -> set[str]:
    start = source.index(marker) + len(marker)
    end = source.index("\n}", start)
    body = source[start:end]
    return set(re.findall(rf'^ {{{indent}}}"([^"]+)"\s*:', body, re.M))


class AnimeCharacterArtDirectionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.visual = VISUAL.read_text(encoding="utf-8")
        cls.generator = GENERATOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.direction = DIRECTION.read_text(encoding="utf-8")
        cls.manifest_builder = MANIFEST_BUILDER.read_text(encoding="utf-8")

    def test_every_playable_visual_profile_has_a_signature_pose_style(self):
        profiles = dictionary_ids(self.visual, "const PROFILES := {", 4)
        style_block = re.search(
            r"PROFESSION_COMBO_STYLES = \{(.*?)^\}",
            self.generator, re.S | re.M,
        )
        self.assertIsNotNone(style_block)
        style_ids = set(re.findall(r'"([^"]+)"\s*:', style_block.group(1)))
        self.assertEqual(profiles, style_ids)

    def test_surplice_and_dark_cloth_use_distinct_material_families(self):
        self.assertIn('"surplice": {"metal": Color(0.045, 0.025, 0.085)', self.visual)
        self.assertIn('"dark_cloth": {"metal": Color(0.025, 0.030, 0.050)', self.visual)
        self.assertIn('"trim": Color(0.30, 0.16, 0.48)', self.visual)
        self.assertIn('"trim": Color(0.22, 0.28, 0.38)', self.visual)
        self.assertIn('is_surplice = ("surplice" in equipment_id', self.generator)
        self.assertIn('is_dark_cloth = ("dark_cloth" in equipment_id', self.generator)
        self.assertIn('Surplice_Black_Purple', self.generator)
        self.assertIn('Dark_Cloth_Steel_Blue', self.generator)

    def test_hades_character_uses_black_purple_armor_accent(self):
        self.assertIn('"hades": {"accent": Color(0.38, 0.20, 0.58)', self.visual)
        self.assertIn('(0.045, 0.025, 0.085) if class_id == "hades"', self.generator)

    def test_each_profession_exports_a_full_body_signature_idle_clip(self):
        self.assertIn("def make_signature_idle_pose(rig, profession_id):", self.generator)
        self.assertIn('action_name = profession_id + "_signature_idle"', self.generator)
        self.assertIn('make_signature_idle_pose(rig, class_id)', self.generator)
        self.assertIn('f"{class_id}_signature_idle"', self.generator)
        self.assertIn('"signature_idle"', self.workflow)
        self.assertIn('len(signature_pose.get("channels", [])) < 10', self.workflow)

    def test_delivery_manifests_block_prototypes_from_final_release(self):
        self.assertIn('"tier": "prototype_blockout"', self.manifest_builder)
        self.assertIn('"canon_identity_verified": False', self.manifest_builder)
        self.assertIn('"visual_review_required": True', self.manifest_builder)
        self.assertIn('"approved_for_final_release": False', self.manifest_builder)
        self.assertIn('"signature_idle"', self.manifest_builder)
        self.assertIn('"{asset_id}_signature_idle"', self.manifest_builder)
        self.assertIn('def migrate_manifest(current: dict, expected_data: dict)', self.manifest_builder)
        self.assertIn('animation.get("required_clips") != expected_animation["required_clips"]', self.manifest_builder)

    def test_all_five_bronze_saints_have_individual_review_previews(self):
        core_heroes = ("pegasus", "dragon", "cygnus", "andromeda", "phoenix")
        for hero in core_heroes:
            self.assertIn(f'"{hero}"', self.generator)
        self.assertIn("expected_heroes", self.workflow)
        for hero in core_heroes:
            self.assertIn(f'"{hero}"', self.workflow)
        self.assertIn("CORE_BRONZE_SAINT_PREVIEW_RENDERED", self.generator)
        self.assertIn("CORE_BRONZE_SAINT_PREVIEW_VALIDATED", self.workflow)

    def test_core_bronze_saints_have_distinct_skinned_signature_equipment(self):
        required_parts = (
            "Dragon_Ancient_Shield",
            "Dragon_Shield_Silver_Dragon_Ridge",
            "Cygnus_Ice_Crystal_Helm_Crest",
            '"Cygnus_" + side + "_Frost_Wing_Pauldron"',
            "Andromeda_Chain_Link_",
            "Andromeda_Chain_Wrist_Anchor",
            '"Phoenix_" + side + "_Flame_Feather_"',
            "Phoenix_Fire_Cosmos_Gem",
        )
        for part in required_parts:
            self.assertIn(part, self.generator)
        self.assertIn('"LeftForearm"', self.generator)
        self.assertIn('"RightForearm"', self.generator)
        self.assertIn('"Head"', self.generator)
        self.assertIn('"Chest"', self.generator)

    def test_runtime_weapon_sockets_support_skeleton_and_fallback_rigs(self):
        player = (ROOT / "game/scripts/player.gd").read_text(encoding="utf-8")
        self.assertIn("func _build_weapon_sockets() -> void:", player)
        self.assertIn("func _find_skeleton_recursive(root: Node) -> Skeleton3D:", player)
        self.assertIn("BoneAttachment3D.new()", player)
        self.assertIn("forearm_nodes[forearm_index].add_child(socket)", player)
        self.assertIn("socket.position = Vector3(0.0, -0.34, 0.0)", player)
        self.assertIn('"right_hand", "weapon_hand", "instrument_anchor", "chain_anchor"', player)
        self.assertIn('"left_hand", "shield_hand", "bow_hand"', player)
        self.assertIn('"shield_hand": {"bone": "LeftForearm"', player)
        self.assertIn('"chain_anchor": {"bone": "RightForearm"', player)
        self.assertIn('"aerial_core": {"bone": "Chest"', player)
        self.assertIn("func get_weapon_socket(socket_id: String) -> Node3D:", player)
        self.assertIn("func get_skill_weapon_socket(ability: Dictionary) -> Node3D:", player)
        self.assertIn("SkillAnimationCatalog.get_profile(class_id, ability)", player)
        self.assertIn("_build_weapon_sockets()", player)

    def test_art_direction_requires_canon_fidelity_and_no_default_capes(self):
        self.assertIn("不得由随机职业色或通用装饰替代", self.direction)
        self.assertIn("冥衣", self.direction)
        self.assertIn("暗黑圣衣", self.direction)
        self.assertIn("默认不带披风", self.direction)
        self.assertIn("原创扩展", self.direction)


if __name__ == "__main__":
    unittest.main()
