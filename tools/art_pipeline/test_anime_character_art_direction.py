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
PLAYER = ROOT / "game/scripts/player.gd"


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
        cls.player = PLAYER.read_text(encoding="utf-8")

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

    def test_profession_review_cameras_fit_full_character_silhouettes(self):
        self.assertIn("bounds = []", self.generator)
        self.assertIn('obj.type != "MESH" or obj.name == "Preview_Studio_Floor"', self.generator)
        self.assertIn("obj.matrix_world @ Vector(corner)", self.generator)
        self.assertIn("preview_target = (min_corner + max_corner) * 0.5", self.generator)
        self.assertIn("max(dimensions.x, dimensions.y, dimensions.z, 1.0) * 1.14", self.generator)
        self.assertIn("(preview_target - camera.location).to_track_quat", self.generator)
        self.assertIn("Cannot frame empty profession preview", self.generator)

    def test_all_five_bronze_saints_require_front_side_back_review_views(self):
        for view in ('("front", (0.0, -6.5, 2.0))',
                     '("side", (6.5, 0.0, 2.0))',
                     '("back", (0.0, 6.5, 2.0))'):
            self.assertIn(view, self.generator)
        self.assertIn('for view_name in ("front", "side", "back")', self.generator)
        self.assertIn('expected_views = ("front", "side", "back")', self.workflow)
        self.assertIn("CORE_BRONZE_SAINT_THREE_VIEW_SET_PASS", self.workflow)

    def test_core_bronze_saints_have_individual_head_bone_weighted_hair_silhouettes(self):
        self.assertIn("def add_core_hero_hair(rig, hero_id):", self.generator)
        self.assertIn('"pegasus": {', self.generator)
        self.assertIn('"dragon": {', self.generator)
        self.assertIn('"cygnus": {', self.generator)
        self.assertIn('"andromeda": {', self.generator)
        self.assertIn('"phoenix": {', self.generator)
        self.assertIn('strand.name = hero_id + "_Hair_Strand_"', self.generator)
        self.assertIn('group = strand.vertex_groups.new(name="Head")', self.generator)
        self.assertIn('add_core_hero_hair(rig, class_id)', self.generator)
        self.assertIn('Long_Hair_Lock', self.generator)


    def test_core_bronze_saints_have_individual_iris_palettes_and_eye_glints(self):
        self.assertIn("def add_core_hero_eyes(rig, hero_id):", self.generator)
        palettes = ("pegasus", "dragon", "cygnus", "andromeda", "phoenix")
        for hero in palettes:
            self.assertIn(f'"{hero}": (', self.generator)
        self.assertIn('hero_id + "_" + side + "_Signature_Iris"', self.generator)
        self.assertIn('hero_id + "_" + side + "_Signature_Pupil"', self.generator)
        self.assertIn('hero_id + "_" + side + "_Eye_Glint"', self.generator)
        self.assertIn("add_core_hero_eyes(rig, class_id)", self.generator)
        self.assertIn('group = strand.vertex_groups.new(name="Head")', self.generator)


    def test_core_bronze_saints_have_distinct_brow_and_cheek_face_profiles(self):
        self.assertIn("def add_core_hero_face_identity(rig, hero_id):", self.generator)
        for hero in ("pegasus", "dragon", "cygnus", "andromeda", "phoenix"):
            self.assertIn(f'"{hero}": {{"brow":', self.generator)
        self.assertIn("brow.rotation_euler.y = profile[\"tilt\"] * sign", self.generator)
        self.assertIn('hero_id + "_" + side + "_Signature_Brow"', self.generator)
        self.assertIn('hero_id + "_" + side + "_Cheek_Contour"', self.generator)
        self.assertIn("add_core_hero_face_identity(rig, class_id)", self.generator)

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


    def test_all_five_bronze_saints_receive_layered_skinned_armor_assemblies(self):
        self.assertIn("def add_core_hero_armor_layers(rig, hero_id):", self.generator)
        profile_block = re.search(
            r"def add_core_hero_armor_layers\(rig, hero_id\):(.*?)^def build_profession_models",
            self.generator, re.S | re.M,
        )
        self.assertIsNotNone(profile_block)
        for hero in ("pegasus", "dragon", "cygnus", "andromeda", "phoenix"):
            self.assertIn(f'"{hero}": {{', profile_block.group(1))
            title = hero.title()
            for suffix in ("_Armor_Chest_Base", "_Armor_Chest_", "_Armor_Outer_Pauldron",
                           "_Armor_Pauldron_Ridge", "_Armor_Forearm_Bracer",
                           "_Armor_Shin_Greave", "_Armor_Waist_Faulds"):
                self.assertIn(suffix, profile_block.group(1))
            self.assertIn(f'ornaments.extend(add_core_hero_armor_layers(rig, class_id))', self.generator)
        for bone in ('"Chest"', '"LeftForearm"', '"RightForearm"', '"Hips"'):
            self.assertIn(bone, profile_block.group(1))
        # Side-specific bones are selected dynamically from the loop's side label.
        self.assertIn('side + "Shoulder"', profile_block.group(1))
        self.assertIn('side + "Forearm"', profile_block.group(1))
        self.assertIn('side + "Shin"', profile_block.group(1))
        self.assertIn('0.90, 0.19', profile_block.group(1))
        self.assertIn('0.78, 0.17', profile_block.group(1))


    def test_core_hero_helmets_knee_armor_boots_and_side_tassets_are_skinned(self):
        profile_block = re.search(
            r"def add_core_hero_armor_layers\(rig, hero_id\):(.*?)^def build_profession_models",
            self.generator, re.S | re.M,
        )
        self.assertIsNotNone(profile_block)
        block = profile_block.group(1)
        for suffix in ("_Armor_Signature_Helm_Crown", "_Armor_Signature_Helm_Crest",
                       "_Armor_Knee_Cop", "_Armor_Boot_Sabatons", "_Armor_Waist_Side_Tasset",
                       "_Armor_Helm_Cheek_Guard"):
            self.assertIn(suffix, block)
        for bone in ('"Head"', '"Hips"'):
            self.assertIn(bone, block)
        # Left/right armor uses the same loop-driven bone mapping.
        self.assertIn('side + "Shin"', block)
        self.assertIn('side + "Foot"', block)
        for hero in ("pegasus", "dragon", "cygnus", "andromeda", "phoenix"):
            self.assertIn(f'"{hero}": [', block)
        self.assertIn('add_weighted_limb(', block)

    def test_glb_export_requires_real_skin_attributes_and_valid_material_slots(self):
        self.assertIn('export_format="GLB"', self.generator)
        self.assertIn('export_skins=True', self.generator)
        self.assertIn('export_animations=True', self.generator)
        self.assertIn('export_animation_mode="NLA_TRACKS"', self.generator)
        self.assertIn('export_materials="EXPORT"', self.generator)
        for semantic in ('"POSITION"', '"JOINTS_0"', '"WEIGHTS_0"'):
            self.assertIn(semantic, self.generator)
        self.assertIn('primitive.get("material")', self.generator)
        self.assertIn('not primitives', self.generator)
        self.assertIn('validate_glb(destination, required_nodes=("Humanoid_Base_Rig", "Humanoid_Base_Mesh")', self.generator)
        self.assertIn('export_glb(destination, [rig, merged])', self.generator)

    def test_godot_only_replaces_fallback_after_validating_imported_character_rig(self):
        self.assertIn('var imported_skeleton := _find_skeleton_recursive(instance)', self.player)
        self.assertIn('var imported_animation_player := _find_animation_player(instance)', self.player)
        self.assertIn('imported_skeleton.find_bone(required_bone) < 0', self.player)
        self.assertIn('var required_bones := ["Head", "Chest", "LeftForearm", "RightForearm", "LeftHand", "RightHand"]', self.player)
        self.assertIn('var required_clips := ["idle", "walk", "run", "%s_basic_attack_1" % class_id]', self.player)
        self.assertIn('_validate_authored_animation_clip(imported_animation_player, imported_skeleton, required_clip)', self.player)
        self.assertIn('var invalid_clips: Array[String] = []', self.player)
        self.assertIn('instance.free()', self.player)
        self.assertIn('keeping procedural fallback:', self.player)
        self.assertIn('child.visible = false', self.player)

    def test_animation_tracks_must_target_the_character_skeleton(self):
        validator = (ROOT / "tools/art_pipeline/validate_authored_assets.py").read_text(encoding="utf-8")
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("compatible_joint_names: set[str] | None = None", validator)
        self.assertIn("skin_joint_names.update", validator)
        self.assertIn("targets node", validator)
        self.assertIn("target_name not in allowed_joint_names", validator)
        self.assertIn("model_joint_names = {", workflow)
        self.assertIn("compatible_joint_names=model_joint_names", workflow)

    def test_glb_skin_accessors_match_vertex_layout_and_valid_component_types(self):
        for check in (
            'position_accessor.get("type") != "VEC3"',
            'joints_accessor.get("type") != "VEC4"',
            'weights_accessor.get("type") != "VEC4"',
            'joints_accessor.get("count") != vertex_count',
            'weights_accessor.get("count") != vertex_count',
            'joints_accessor.get("componentType") not in (5121, 5123)',
            'weights_accessor.get("componentType") not in (5121, 5123, 5126)',
            'not weights_accessor.get("normalized", False)',
        ):
            self.assertIn(check, self.generator)

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


    def test_five_bronze_saints_concept_quality_baseline_is_enforced(self):
        self.assertIn("五小强概念图质量基准", self.direction)
        self.assertIn("必须达到或高于该概念图", self.direction)
        for requirement in ("正面、侧面、背面", "魅族 21 Pro", "脸部/发型",
                            "圣衣结构", "专属装备", "骨骼绑定", "移动端性能"):
            self.assertIn(requirement, self.direction)
        self.assertIn('"prototype_blockout"', self.direction)
        self.assertIn('"approved_for_final_release"', self.direction)

if __name__ == "__main__":
    unittest.main()
