#!/usr/bin/env python3
"""Audit the real playable-unit, skill-profile and enemy catalogs without inflating counts."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET_PLAYABLE_CLASSES = 76
MIN_CLASS_SKILLS = 24


def dictionary_body(source: str, marker: str) -> str:
    """Extract only the dictionary belonging to marker, excluding later constants."""
    start = source.find(marker)
    if start < 0:
        raise ValueError(f"catalog marker not found: {marker}")
    opening = source.find("{", start + len(marker) - 1)
    if opening < 0:
        raise ValueError(f"catalog dictionary not opened: {marker}")
    depth = 0
    in_string = False
    escaped = False
    for index in range(opening, len(source)):
        char = source[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[opening + 1:index]
    raise ValueError(f"catalog dictionary is not closed: {marker}")


def top_level_entries(source: str, marker: str, indent: int) -> dict[str, str]:
    body = dictionary_body(source, marker)
    entry_re = re.compile(rf'^ {{{indent}}}"([^"]+)"\s*:\s*\{{', re.M)
    matches = list(entry_re.finditer(body))
    result: dict[str, str] = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        result[match.group(1)] = body[match.start():end]
    return result


def audit_sources(class_data: str, visual_catalog: str, skill_catalog: str,
                  enemy_catalog: str) -> dict:
    classes = top_level_entries(class_data, "const CLASS_DATA := {", 1)
    visuals = top_level_entries(visual_catalog, "const PROFILES := {", 4)
    skills = top_level_entries(skill_catalog, "const CLASS_SKILLS := {", 4)
    enemies = top_level_entries(enemy_catalog, "const ARCHETYPES := {", 4)

    class_ids = set(classes)
    visual_ids = set(visuals)
    skill_ids = set(skills)
    missing_visuals = sorted(class_ids - visual_ids)
    orphan_visuals = sorted(visual_ids - class_ids)
    missing_skill_profiles = sorted(class_ids - skill_ids)
    boss_ids = sorted(
        enemy_id for enemy_id, body in enemies.items()
        if re.search(r'"is_boss"\s*:\s*true', body)
    )
    normal_ids = sorted(set(enemies) - set(boss_ids))

    skill_counts: dict[str, int] = {}
    for class_id, body in skills.items():
        match = re.search(r'"abilities"\s*:\s*\[(.*?)\]\s*,\s*"passive"', body, re.S)
        skill_counts[class_id] = len(re.findall(r'"id"\s*:', match.group(1))) if match else 0

    deficits = {
        class_id: max(0, MIN_CLASS_SKILLS - count)
        for class_id, count in skill_counts.items()
        if count < MIN_CLASS_SKILLS
    }
    return {
        "playable_class_target": TARGET_PLAYABLE_CLASSES,
        "playable_classes_registered": len(classes),
        "playable_classes_missing_from_target": max(0, TARGET_PLAYABLE_CLASSES - len(classes)),
        "class_ids": sorted(class_ids),
        "visual_profiles": len(visuals),
        "visual_profiles_missing": missing_visuals,
        "orphan_visual_profiles": orphan_visuals,
        "class_skill_profiles": len(skills),
        "classes_missing_skill_profiles": missing_skill_profiles,
        "minimum_unique_skills_per_class": MIN_CLASS_SKILLS,
        "skill_counts_by_class": dict(sorted(skill_counts.items())),
        "skill_deficits_by_class": dict(sorted(deficits.items())),
        "enemy_archetypes": len(enemies),
        "boss_archetypes": len(boss_ids),
        "non_boss_archetypes": len(normal_ids),
        "boss_ids": boss_ids,
        "non_boss_ids": normal_ids,
        "status": "complete" if (
            len(classes) == TARGET_PLAYABLE_CLASSES
            and not missing_visuals and not orphan_visuals
            and not missing_skill_profiles and not deficits
        ) else "incomplete",
    }


def audit_repository(root: Path = ROOT) -> dict:
    read = lambda path: (root / path).read_text(encoding="utf-8")
    return audit_sources(
        read("game/scripts/rpg_state.gd"),
        read("game/scripts/character_visual_catalog.gd"),
        read("game/scripts/skill_system.gd"),
        read("game/scripts/enemy_database.gd"),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="print the full machine-readable audit")
    parser.add_argument("--strict", action="store_true", help="exit non-zero while the 76-class target is incomplete")
    args = parser.parse_args()
    report = audit_repository()
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(
            "UNIT_ROSTER_AUDIT "
            f"classes={report['playable_classes_registered']}/{report['playable_class_target']} "
            f"visual_profiles={report['visual_profiles']} "
            f"skill_profiles={report['class_skill_profiles']} "
            f"classes_missing_skill_profiles={len(report['classes_missing_skill_profiles'])} "
            f"classes_below_{MIN_CLASS_SKILLS}_skills={len(report['skill_deficits_by_class'])} "
            f"enemies={report['enemy_archetypes']} "
            f"bosses={report['boss_archetypes']} "
            f"non_bosses={report['non_boss_archetypes']} "
            f"status={report['status']}"
        )
        if report["playable_classes_missing_from_target"]:
            print(f"  playable class registrations still needed: {report['playable_classes_missing_from_target']}")
        if report["classes_missing_skill_profiles"]:
            print("  classes without skill profiles: " + ", ".join(report["classes_missing_skill_profiles"]))
        if report["skill_deficits_by_class"]:
            print("  classes below 24 unique skills: " + ", ".join(
                f"{name}(-{count})" for name, count in report["skill_deficits_by_class"].items()
            ))
        if report["visual_profiles_missing"] or report["orphan_visual_profiles"]:
            print("  visual catalog/class catalog mismatch detected")
    return 1 if args.strict and report["status"] != "complete" else 0


if __name__ == "__main__":
    raise SystemExit(main())
