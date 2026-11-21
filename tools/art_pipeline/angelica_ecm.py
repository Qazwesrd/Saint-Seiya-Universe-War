#!/usr/bin/env python3
"""Neutral JSON export and structural validation for Angelica ECM composites."""
from __future__ import annotations

import math
import re
from typing import Any, Iterable


def _plain_path(value: Any) -> str:
    return str(value or "").replace("\\", "/").strip()


def _validate_relative_resource_path(value: Any, field: str) -> str:
    path = _plain_path(value)
    if not path:
        raise ValueError(f"{field}: expected non-empty resource path")
    if path.startswith("/") or re.match(r"^[A-Za-z]:", path):
        raise ValueError(f"{field}: absolute paths are not allowed")
    parts = [part for part in path.split("/") if part not in ("", ".")]
    if not parts or any(part == ".." for part in parts):
        raise ValueError(f"{field}: parent traversal is not allowed")
    return "/".join(parts)


def _finite_vector(values: Any, length: int, field: str) -> list[float]:
    if not isinstance(values, (list, tuple)) or len(values) != length:
        raise ValueError(f"{field}: expected {length} numeric values")
    result: list[float] = []
    for index, value in enumerate(values):
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise ValueError(f"{field}[{index}]: expected finite number")
        result.append(float(value))
    return result


def _event_payload(event: Any) -> dict[str, Any]:
    result: dict[str, Any] = {}
    names = (
        "event_type", "fx_file_path", "hook_name", "hook_offset", "hook_pitch",
        "hook_yaw", "hook_rot", "start_time", "time_span", "fade_out", "once",
        "bind_parent", "use_model_alpha", "gfx_scale", "gfx_speed", "volume",
        "min_dist", "max_dist", "force_2d", "is_loop",
    )
    for name in names:
        value = getattr(event, name, None)
        if isinstance(value, tuple):
            value = list(value)
        result[name] = value
    return result


def build_ecm_payload(entry_path: str, parsed: Any) -> dict[str, Any]:
    """Convert an AutoAngel EcmModel-like object into JSON-safe neutral data."""
    children = []
    for index in range(int(parsed.child_count)):
        child = parsed.get_child(index)
        if child is None:
            raise ValueError(f"ECM child entry {index} is missing")
        children.append({
            "slot": str(child.name),
            "path": _plain_path(child.path),
            "parent_hook": str(child.hh_name),
            "child_hook": str(child.cc_name),
        })

    bone_scales = []
    for index in range(int(parsed.bone_scale_count)):
        entry = parsed.get_bone_scale(index)
        if entry is None:
            raise ValueError(f"ECM bone scale entry {index} is missing")
        bone_scales.append({
            "bone_index": int(entry.bone_index),
            "scale": list(entry.scale),
            "scale_type": entry.scale_type,
        })

    actions = []
    for action_index in range(int(parsed.combine_action_count)):
        events = []
        for event_index in range(int(parsed.combine_action_event_count(action_index))):
            event = parsed.get_event(action_index, event_index)
            if event is None:
                raise ValueError(f"ECM action {action_index} event {event_index} is missing")
            events.append(_event_payload(event))
        actions.append({
            "name": str(parsed.combine_action_name(action_index)),
            "loop_count": int(parsed.combine_action_loop_count(action_index)),
            "events": events,
        })

    co_gfx = [
        _plain_path(parsed.co_gfx_fx_file_path(index))
        for index in range(int(parsed.co_gfx_count))
    ]
    return {
        "schema_version": 1,
        "kind": "ecm",
        "source_entry": _plain_path(entry_path),
        "ecm_version": int(parsed.version),
        "skin_model_path": _plain_path(parsed.skin_model_path),
        "additional_skins": list(parsed.additional_skins),
        "children": children,
        "bone_scales": bone_scales,
        "bone_scale_format": "extended" if bool(parsed.new_bone_scale) else "legacy",
        "org_color_argb": int(parsed.org_color),
        "default_play_speed": float(parsed.def_play_speed),
        "co_gfx": co_gfx,
        "combine_actions": actions,
        "safety": "Neutral metadata export only; source archives and client files were not modified.",
    }


def validate_ecm_payload(payload: dict[str, Any], known_parent_hooks: Iterable[str] | None = None) -> dict[str, int]:
    if not isinstance(payload, dict) or payload.get("schema_version") != 1 or payload.get("kind") != "ecm":
        raise ValueError("$: expected ECM schema_version 1 payload")
    _validate_relative_resource_path(payload.get("source_entry"), "$.source_entry")
    _validate_relative_resource_path(payload.get("skin_model_path"), "$.skin_model_path")

    children = payload.get("children")
    if not isinstance(children, list):
        raise ValueError("$.children: expected array")
    seen_slots: set[str] = set()
    hook_set = set(known_parent_hooks) if known_parent_hooks is not None else None
    for index, child in enumerate(children):
        field = f"$.children[{index}]"
        if not isinstance(child, dict):
            raise ValueError(f"{field}: expected object")
        slot = child.get("slot")
        if not isinstance(slot, str) or not slot.strip():
            raise ValueError(f"{field}.slot: expected non-empty string")
        if slot in seen_slots:
            raise ValueError(f"{field}.slot: duplicate slot {slot!r}")
        seen_slots.add(slot)
        _validate_relative_resource_path(child.get("path"), f"{field}.path")
        parent_hook = child.get("parent_hook")
        child_hook = child.get("child_hook")
        if not isinstance(parent_hook, str) or not parent_hook.strip():
            raise ValueError(f"{field}.parent_hook: expected non-empty string")
        if not isinstance(child_hook, str) or not child_hook.strip():
            raise ValueError(f"{field}.child_hook: expected non-empty string")
        if hook_set is not None and parent_hook not in hook_set:
            raise ValueError(f"{field}.parent_hook: hook {parent_hook!r} not found in parent BON")

    scales = payload.get("bone_scales")
    if not isinstance(scales, list):
        raise ValueError("$.bone_scales: expected array")
    seen_bones: set[int] = set()
    for index, scale in enumerate(scales):
        field = f"$.bone_scales[{index}]"
        if not isinstance(scale, dict):
            raise ValueError(f"{field}: expected object")
        bone_index = scale.get("bone_index")
        if not isinstance(bone_index, int) or isinstance(bone_index, bool) or bone_index < 0:
            raise ValueError(f"{field}.bone_index: expected non-negative integer")
        if bone_index in seen_bones:
            raise ValueError(f"{field}.bone_index: duplicate bone scale")
        seen_bones.add(bone_index)
        _finite_vector(scale.get("scale"), 3, f"{field}.scale")
        scale_type = scale.get("scale_type")
        if scale_type is not None and (not isinstance(scale_type, int) or isinstance(scale_type, bool)):
            raise ValueError(f"{field}.scale_type: expected integer or null")

    actions = payload.get("combine_actions")
    if not isinstance(actions, list):
        raise ValueError("$.combine_actions: expected array")
    event_count = 0
    for action_index, action in enumerate(actions):
        field = f"$.combine_actions[{action_index}]"
        if not isinstance(action, dict) or not isinstance(action.get("name"), str):
            raise ValueError(f"{field}: expected action object with name")
        if not isinstance(action.get("loop_count"), int) or isinstance(action.get("loop_count"), bool):
            raise ValueError(f"{field}.loop_count: expected integer")
        events = action.get("events")
        if not isinstance(events, list):
            raise ValueError(f"{field}.events: expected array")
        for event_index, event in enumerate(events):
            event_field = f"{field}.events[{event_index}]"
            if not isinstance(event, dict):
                raise ValueError(f"{event_field}: expected object")
            event_type = event.get("event_type")
            if not isinstance(event_type, int) or isinstance(event_type, bool):
                raise ValueError(f"{event_field}.event_type: expected integer")
            path = event.get("fx_file_path")
            if path:
                _validate_relative_resource_path(path, f"{event_field}.fx_file_path")
            offset = event.get("hook_offset")
            if offset is not None:
                _finite_vector(offset, 3, f"{event_field}.hook_offset")
            event_count += 1

    co_gfx = payload.get("co_gfx")
    if not isinstance(co_gfx, list):
        raise ValueError("$.co_gfx: expected array")
    for index, path in enumerate(co_gfx):
        _validate_relative_resource_path(path, f"$.co_gfx[{index}]")

    return {
        "children": len(children),
        "bone_scales": len(scales),
        "actions": len(actions),
        "events": event_count,
    }


def validate_ecm_graph(payloads: Iterable[dict[str, Any]], require_all_children: bool = False) -> dict[str, int]:
    """Check duplicate ECM identities, unresolved child references and cycles."""
    by_path: dict[str, dict[str, Any]] = {}
    for payload in payloads:
        validate_ecm_payload(payload)
        path = _validate_relative_resource_path(payload["source_entry"], "$.source_entry").casefold()
        if path in by_path:
            raise ValueError(f"duplicate ECM source entry: {path}")
        by_path[path] = payload

    edges: dict[str, list[str]] = {}
    unresolved: set[tuple[str, str]] = set()
    for path, payload in by_path.items():
        edges[path] = []
        for child in payload["children"]:
            target = _validate_relative_resource_path(child["path"], f"{path}.children.path").casefold()
            if target in by_path:
                edges[path].append(target)
            else:
                unresolved.add((path, target))

    state: dict[str, int] = {}
    def visit(node: str, trail: list[str]) -> None:
        marker = state.get(node, 0)
        if marker == 1:
            cycle = " -> ".join(trail + [node])
            raise ValueError(f"ECM child reference cycle: {cycle}")
        if marker == 2:
            return
        state[node] = 1
        for target in edges[node]:
            visit(target, trail + [node])
        state[node] = 2

    for node in edges:
        visit(node, [])

    if require_all_children and unresolved:
        parent, child = sorted(unresolved)[0]
        raise ValueError(f"unresolved ECM child reference: {parent} -> {child}")
    return {
        "models": len(by_path),
        "resolved_edges": sum(len(items) for items in edges.values()),
        "unresolved_edges": len(unresolved),
    }
