#!/usr/bin/env python3
"""Build a read-only Angelica character dependency report directly from PCK/PKX.

The report follows ECM -> SMD -> SKI/BON/STCK references and records texture,
child-model, hook, and GFX references. It never extracts files or modifies archives.
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path, PurePosixPath
from typing import Any


def norm(path: str, base: str = "") -> str:
    raw = str(path or "").replace("\\", "/").strip()
    if not raw:
        return ""
    if raw.startswith("/"):
        return str(PurePosixPath(raw.lstrip("/")))
    parent = PurePosixPath(base).parent if base else PurePosixPath()
    return str(parent.joinpath(raw))


def attr(obj: Any, name: str, default: Any = None) -> Any:
    if isinstance(obj, dict):
        return obj.get(name, default)
    return getattr(obj, name, default)


def strings(values: Any) -> list[str]:
    return [str(value) for value in (values or []) if value]


def build_report(package: Any, autoangel: Any, roots: list[str]) -> dict[str, Any]:
    available = set(package.file_list())
    queue = deque((norm(root), "root") for root in roots)
    visited: set[str] = set()
    nodes: list[dict[str, Any]] = []
    missing: set[str] = set()

    folded_paths = {item.casefold(): item for item in available}

    def enqueue(reference: str, parent: str, relation: str) -> None:
        raw = str(reference or "").strip()
        if not raw:
            return
        # Angelica references are commonly archive-root-relative. Prefer that
        # exact path; fall back to the referencing file's directory.
        direct = norm(raw)
        relative = norm(raw, parent)
        target = (folded_paths.get(direct.casefold()) or
                  folded_paths.get(relative.casefold()) or direct)
        queue.append((target, relation))

    while queue:
        path, relation = queue.popleft()
        if not path or path in visited:
            continue
        visited.add(path)
        path = folded_paths.get(path.casefold(), path)
        blob = package.get_file(path)
        if blob is None:
            missing.add(path)
            continue

        ext = Path(path).suffix.lower()
        node: dict[str, Any] = {"path": path, "extension": ext, "discovered_via": relation}
        try:
            if ext == ".ecm":
                model = autoangel.read_ecm(blob)
                smd = attr(model, "skin_model_path", "")
                node["skin_model_path"] = smd
                enqueue(smd, path, "ecm_skin_model")
                children = []
                for index in range(int(attr(model, "child_count", 0))):
                    child = model.get_child(index)
                    if child is None:
                        continue
                    item = {
                        "name": attr(child, "name", ""),
                        "path": attr(child, "path", ""),
                        "parent_hook": attr(child, "hh_name", ""),
                        "child_hook": attr(child, "cc_name", ""),
                    }
                    children.append(item)
                    enqueue(item["path"], path, "ecm_child_model")
                node["children"] = children
                effects = []
                for index in range(int(attr(model, "co_gfx_count", 0))):
                    effect = model.co_gfx_fx_file_path(index)
                    if effect:
                        effects.append(str(effect))
                        enqueue(effect, path, "ecm_persistent_gfx")
                node["persistent_gfx"] = effects
                node["combine_actions"] = [
                    str(model.combine_action_name(i))
                    for i in range(int(attr(model, "combine_action_count", 0)))
                ]
            elif ext == ".smd":
                model = autoangel.read_smd(blob)
                skeleton = str(attr(model, "skeleton_path", "") or "")
                skins = strings(attr(model, "skin_paths", []))
                actions = []
                for action in attr(model, "actions", []) or []:
                    tck = str(attr(action, "tck_file", "") or "")
                    item = {
                        "name": attr(action, "name", ""),
                        "start_frame": attr(action, "start_frame"),
                        "end_frame": attr(action, "end_frame"),
                        "tck_file": tck or None,
                    }
                    actions.append(item)
                    if tck:
                        enqueue(tck, path, "smd_animation_track")
                node["skeleton_path"] = skeleton
                node["skin_paths"] = skins
                node["actions"] = actions
                enqueue(skeleton, path, "smd_skeleton")
                for skin in skins:
                    enqueue(skin, path, "smd_skin")
            elif ext == ".ski":
                model = autoangel.read_skin(blob)
                node["version"] = attr(model, "version")
                node["bone_names"] = strings(attr(model, "bone_names", []))
                node["textures"] = strings(attr(model, "textures", []))
                node["materials"] = [
                    {"name": attr(material, "name", ""),
                     "two_sided": attr(material, "two_sided")}
                    for material in (attr(model, "materials", []) or [])
                ]
                for texture in node["textures"]:
                    enqueue(texture, path, "ski_texture")
            elif ext == ".bon":
                model = autoangel.read_skeleton(blob)
                node["version"] = attr(model, "version")
                node["bones"] = [
                    {"name": attr(bone, "name", ""), "parent": attr(bone, "parent"),
                     "children": attr(bone, "children", [])}
                    for bone in (attr(model, "bones", []) or [])
                ]
                node["hooks"] = [
                    {"name": attr(hook, "name", ""),
                     "bone_index": attr(hook, "bone_index")}
                    for hook in (attr(model, "hooks", []) or [])
                ]
            elif ext == ".stck":
                model = autoangel.read_animation(blob)
                tracks = attr(model, "bone_tracks", []) or []
                node["fps"] = attr(model, "anim_fps")
                node["frame_range"] = [attr(model, "anim_start"), attr(model, "anim_end")]
                node["track_count"] = len(tracks)
                node["bone_track_ids"] = [attr(track, "bone_id") for track in tracks]
            elif ext == ".gfx":
                model = autoangel.read_gfx(blob)
                node["effect_type"] = str(type(model).__name__)
            else:
                node["note"] = "Referenced file recorded; no parser selected for this extension."
        except Exception as exc:
            node["parse_error"] = f"{type(exc).__name__}: {exc}"
        nodes.append(node)

    return {
        "schema_version": 1,
        "roots": [norm(item) for item in roots],
        "node_count": len(nodes),
        "nodes": nodes,
        "missing_references": sorted(missing, key=str.casefold),
        "parse_errors": [
            {"path": item["path"], "error": item["parse_error"]}
            for item in nodes if "parse_error" in item
        ],
        "safety": "Read-only PCK/PKX access. Files are parsed in memory; no archive extraction or modification.",
        "verification": "References are parser-reported paths. Confirm character identity, coordinate basis, visual fit, and animation playback in Blender before treating a bundle as verified.",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path)
    parser.add_argument("--pkx", action="append", default=[])
    parser.add_argument("--root", action="append", required=True,
                        help="Root ECM/SMD path inside the archive; repeat for multiple roots")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    pck = args.pck.expanduser().resolve(strict=True)
    pkx = [Path(item).expanduser().resolve(strict=True) for item in args.pkx]
    output = args.output.expanduser().resolve()
    if not pck.is_file() or any(not item.is_file() for item in pkx):
        parser.error("PCK and PKX inputs must be regular files")
    if any(output == item or item.parent == output or item.parent in output.parents
           for item in [pck, *pkx]):
        parser.error("--output must be outside source archive directories")
    try:
        import autoangel
    except ImportError:
        print("Missing dependency: py -m pip install autoangel", file=sys.stderr)
        return 2
    try:
        package = autoangel.read_pck(str(pck), [str(item) for item in pkx] or None)
        report = build_report(package, autoangel, args.root)
    except Exception as exc:
        print(f"DEPENDENCY_SCAN_FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"CHARACTER_DEPENDENCY_SCAN_PASS nodes={report['node_count']} missing={len(report['missing_references'])} errors={len(report['parse_errors'])}")
    print(f"JSON {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
