#!/usr/bin/env python3
"""Offline prompt builder and local ComfyUI bridge for the Saint Seiya art factory.

No cloud endpoints, paid APIs, telemetry, or third-party Python packages are used.
The ComfyUI bridge accepts localhost/loopback URLs only.

Examples (run from repository root):
  python tools/art_pipeline/prompt_engine.py --self-test
  python tools/art_pipeline/prompt_engine.py --kind characters --id pegasus
  python tools/art_pipeline/prompt_engine.py --kind armors --id glory_heavenly_standard
  python tools/art_pipeline/prompt_engine.py --kind enemies --id pope_saga
  python tools/art_pipeline/prompt_engine.py --kind characters --id pegasus --generate
  python tools/art_pipeline/prompt_engine.py --kind all --generate --checkpoint sd15.safetensors

Prompt files are written to build/art_prompts by default. Generated images are
written to build/art_generated. A compatible local checkpoint must already be
installed in ComfyUI/models/checkpoints; this script never downloads model files.
"""
from __future__ import annotations

import argparse
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROMPT_DIR = ROOT / "build" / "art_prompts"
IMAGE_DIR = ROOT / "build" / "art_generated"

NEGATIVE = (
    "low quality, low resolution, blurry, jpeg artifacts, flat lighting, "
    "unfinished blockout, low-poly toy, capsule body, primitive shapes, "
    "sphere joints, disconnected limbs, cylindrical torso, oversized head, "
    "childlike proportions, deformed anatomy, asymmetrical eyes, malformed face, "
    "missing nose, missing ears, fused fingers, mitten hands, missing fingers, "
    "broken wrists, extra arms, extra legs, floating armor, paper-thin armor, "
    "random spikes, noisy details, plastic material, muddy metal, flat colors, "
    "unreadable silhouette, text, logo, watermark, signature, cropped feet, "
    "cropped head, out of frame, duplicate character, busy background"
)

SILHOUETTE = {
    "swift": "lean athletic proportions, forward-flowing lines and compact aerodynamic armor",
    "guard": "powerful defensive silhouette, broad shield-like forms and stable stance",
    "frost": "elegant angular silhouette, crystalline ice motifs and feather-like armor edges",
    "grace": "slender balanced silhouette, flowing lines and refined ornamental details",
    "flare": "dynamic flame-shaped silhouette, swept-back forms and dramatic layered accents",
    "tidal": "fluid marine silhouette, wave curves, scale-inspired plates and fin motifs",
    "radiant": "radiant heroic silhouette, symmetrical sunburst geometry and luminous trim",
    "resonance": "slender resonant silhouette, sound-wave arcs and instrument-inspired details",
    "flow": "streamlined flowing silhouette, curved fin shapes and light armor",
    "solar": "majestic solar silhouette, radiant crest and large but articulated wing motifs",
    "guardian": "regal guardian silhouette, balanced protective armor and ceremonial crest",
    "reaper": "ominous elongated silhouette, sharp layered armor and restrained spectral ornaments",
    "ocean": "commanding oceanic silhouette, trident geometry and flowing tidal fins",
    "storm": "powerful storm silhouette, angular lightning forms and sweeping mantle",
    "lunar": "elegant lunar silhouette, crescent geometry and fine silver-blue details",
    "dream": "ethereal silhouette, soft sweeping contours and dreamlike wing motifs",
    "rune": "northern rune-warrior silhouette, engraved geometric motifs and cold-metal layers",
    "war": "battle-hardened silhouette, strong angular plates and disciplined weapon motifs",
    "chaos": "irregular but coherent silhouette, thorn motifs and controlled asymmetry",
    "fallen": "dark celestial silhouette, swept-back broken-wing motifs and layered armor",
    "chrono": "time-themed silhouette, concentric rings and precise clockwork engravings",
    "titan": "towering titan silhouette, monumental layered plates and ancient geometric detail",
    "royal": "royal ceremonial silhouette, crown motifs and elegant layered armor",
    "nature": "organic guardian silhouette, leaf-like curves and natural engraved patterns",
    "hearth": "warm flame-guardian silhouette, ember motifs and protective layered plates",
    "forge": "massive forged silhouette, hammer/anvil motifs and heavy articulated armor",
    "elegant": "refined elegant silhouette, rose and petal geometry with precise fine details",
    "celestial": "celestial winged silhouette, halo geometry and luminous layered armor",
    "balanced": "balanced heroic silhouette with a distinct readable outline",
}

ORNAMENT = {
    "comet": "comet-tail engraving and wing-shaped helmet crest",
    "shield": "dragon-scale shield motifs and protective crest",
    "feather": "layered feather engravings and ice-feather motifs",
    "chain": "interlocking chain motifs integrated into the armor",
    "radiant": "radial sunburst engravings and luminous insets",
    "sound": "resonance-wave engravings and instrument-inspired filigree",
    "fin": "marine fin motifs and flowing scale patterns",
    "solar_wings": "solar wing plates and sun-disc engravings",
    "aegis": "ceremonial aegis motifs and protective layered geometry",
    "soul_wings": "spectral wing motifs and restrained underworld engravings",
    "tidal_fins": "tidal fin plates, wave grooves and sea-glass insets",
    "storm_wings": "storm-wing plates and lightning-channel engravings",
    "moon_wings": "crescent plates and lunar filigree",
    "dream_wings": "dreamlike wing arcs and soft luminous insets",
    "rune_wings": "rune-etched wing plates and northern geometric patterns",
    "war_spikes": "purposeful spear-like ridges integrated into forged armor",
    "thorn_wings": "thorned wing plates and controlled organic geometry",
    "fallen_wings": "dark feathered wing plates and fractured celestial motifs",
    "time_rings": "concentric chronometer rings and precise time engravings",
    "royal_wings": "royal wing filigree and symmetrical ceremonial details",
    "leaf_wings": "leaf-shaped plates and organic engraved veins",
    "flame_wings": "layered flame-shaped plates and ember insets",
    "swift_wings": "compact aerodynamic wing motifs and speed-line engravings",
    "forge_plates": "forged layered plates, hammer marks and heat-treated metal",
    "petal_wings": "petal-shaped plates and rose-like engraved details",
    "crest": "distinctive heraldic crest and engraved armor borders",
    "dark_aura": "darkened metal, restrained violet energy channels and sharp void motifs",
}

def parse_entries(source: str, marker: str, indent: int) -> dict[str, str]:
    marker_at = source.find(marker)
    if marker_at < 0:
        raise ValueError(f"Missing GDScript catalog marker: {marker}")
    body = source[marker_at + len(marker):]
    closing = re.search(r"^\\}", body, re.M)
    if closing:
        body = body[:closing.start()]
    pattern = re.compile(rf"^{r' ' * indent}\"([A-Za-z0-9_]+)\"\s*:\s*\{{", re.M)
    matches = list(pattern.finditer(body))
    entries: dict[str, str] = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        entries[match.group(1)] = body[match.end():end]
    return entries

def quoted_field(entry: str, field: str, default: str = "") -> str:
    match = re.search(rf'"{re.escape(field)}"\s*:\s*"([^"]*)"', entry)
    return match.group(1) if match else default

def load_catalogs() -> dict[str, dict[str, str]]:
    character_source = (ROOT / "game/scripts/character_visual_catalog.gd").read_text(encoding="utf-8")
    equipment_source = (ROOT / "game/scripts/equipment_database.gd").read_text(encoding="utf-8")
    enemy_source = (ROOT / "game/scripts/enemy_database.gd").read_text(encoding="utf-8")
    return {
        "characters": parse_entries(character_source, "const PROFILES := {", 4),
        "armors": parse_entries(equipment_source, "const EQUIPMENT := {", 1),
        "enemies": parse_entries(enemy_source, "const ARCHETYPES := {", 4),
    }

def character_prompt(asset_id: str, entry: str) -> tuple[str, str]:
    crest = quoted_field(entry, "crest", "star")
    ornament = quoted_field(entry, "ornament", "crest")
    silhouette = quoted_field(entry, "silhouette", "balanced")
    positive = (
        "Premium original anime MMORPG 3D game character, full-body adult heroic warrior, "
        "approximately eight-head-tall realistic stylized anatomy, mature expressive face "
        "with sculpted eyelids, brows, nose, lips and ears, individually modeled layered hair "
        "strands, athletic anatomical torso, clearly shaped elbows and knees, articulated "
        "hands with five separated fingers and modeled boots. "
        f"Profession identity: {asset_id.replace('_', ' ')}. "
        f"Helmet crest: {crest}. Armor ornament: {ORNAMENT.get(ornament, ornament)}. "
        f"Silhouette direction: {SILHOUETTE.get(silhouette, SILHOUETTE['balanced'])}. "
        "Original coherent armor design with physically layered metal plates, real thickness, "
        "beveled edges, engraved filigree, inset gemstones, articulated joints and cloth "
        "undersuit. High quality PBR metallic materials, controlled roughness, subtle enamel, "
        "realistic reflections, detailed face and hair, clean topology appearance, "
        "three-quarter front character showcase, neutral A-pose, entire body visible, "
        "professional game-art studio lighting, dark uncluttered background, no text. "
        "Design must be original and must not reproduce any existing game's proprietary model."
    )
    return positive, NEGATIVE

def armor_prompt(asset_id: str, entry: str) -> tuple[str, str]:
    name = quoted_field(entry, "name", asset_id.replace("_", " "))
    category = quoted_field(entry, "category", "fantasy armor")
    faction = quoted_field(entry, "faction", "cosmic knights")
    canon = quoted_field(entry, "canon_status", "original game design")
    positive = (
        "Premium original anime MMORPG modular armor set, isolated complete wearable armor "
        "display on an invisible neutral mannequin, front three-quarter view. "
        f"Equipment identity: {name} ({asset_id}). Category: {category}. Faction: {faction}. "
        f"Continuity note: {canon}. Design a coherent helmet, chest cuirass, paired shoulder "
        "guards, forearm bracers, waist fauld, thigh and shin guards, and articulated boots. "
        "Every plate has real volume and thickness, curved anatomical fit, layered construction, "
        "beveled metal edges, precise engraved motifs, gemstone settings and readable attachment "
        "interfaces. Distinctive silhouette, premium physically based metal, enamel and gemstone "
        "materials, controlled highlights, fine craftsmanship, game-ready concept presentation, "
        "neutral studio lighting, uncluttered dark background, no text. Create an original "
        "interpretation; do not trace proprietary game assets."
    )
    return positive, NEGATIVE

def enemy_prompt(asset_id: str, entry: str) -> tuple[str, str]:
    name = quoted_field(entry, "name", asset_id.replace("_", " "))
    boss = quoted_field(entry, "is_boss", "false").lower() == "true"
    role = "major boss antagonist" if boss else "distinctive campaign enemy"
    positive = (
        f"Premium original anime MMORPG 3D {role}, full-body adult humanoid fantasy combatant. "
        f"Identity: {name} ({asset_id}). Strong readable silhouette, believable anatomy, "
        "sculpted face, detailed hair or helmet, articulated hands and boots, layered faction "
        "armor with real thickness, purposeful asymmetry, fine engravings, physically based "
        "metal, leather and cloth materials. Distinct equipment language and color identity, "
        "high-end game character presentation, dramatic but readable studio lighting, "
        "three-quarter front view, entire figure visible, neutral background, no text. "
        "Original design; do not reproduce proprietary game models."
    )
    return positive, NEGATIVE

def build_workflow(prompt: str, negative: str, checkpoint: str, seed: int,
                   width: int, height: int, steps: int) -> dict:
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": checkpoint}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": steps, "cfg": 7.0, "sampler_name": "dpmpp_2m",
            "scheduler": "karras", "denoise": 1.0, "model": ["1", 0],
            "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": "saint_seiya_art", "images": ["6", 0]}},
    }

def local_url(base: str, suffix: str = "") -> str:
    parsed = urllib.parse.urlparse(base)
    if parsed.scheme != "http" or parsed.hostname not in {"127.0.0.1", "localhost", "::1"}:
        raise ValueError("Offline safety: ComfyUI URL must be localhost/loopback HTTP.")
    return base.rstrip("/") + suffix

def request_json(url: str, payload: dict | None = None, timeout: int = 30) -> dict:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))

def queue_and_save(base: str, workflow: dict, output: Path, timeout: int = 1800) -> Path:
    client_id = "saint-seiya-offline-art-factory"
    queued = request_json(local_url(base, "/prompt"), {"prompt": workflow, "client_id": client_id})
    prompt_id = queued.get("prompt_id")
    if not prompt_id:
        raise RuntimeError(f"ComfyUI did not return prompt_id: {queued}")
    deadline = time.monotonic() + timeout
    history: dict = {}
    while time.monotonic() < deadline:
        time.sleep(2)
        history = request_json(local_url(base, f"/history/{prompt_id}"))
        if prompt_id in history and history[prompt_id].get("outputs"):
            break
    else:
        raise TimeoutError(f"Local image generation timed out: {prompt_id}")
    outputs = history[prompt_id]["outputs"]
    images = [item for node in outputs.values() for item in node.get("images", [])]
    if not images:
        raise RuntimeError(f"ComfyUI completed without an image: {history[prompt_id]}")
    image_info = images[0]
    query = urllib.parse.urlencode({
        "filename": image_info["filename"],
        "subfolder": image_info.get("subfolder", ""),
        "type": image_info.get("type", "output"),
    })
    image_url = local_url(base, "/view?" + query)
    output.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(image_url, timeout=60) as response:
        output.write_bytes(response.read())
    return output

def safe_filename(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("._") or "asset"

def run_self_test(catalogs: dict[str, dict[str, str]]) -> None:
    expected = {"characters": 32, "armors": 82, "enemies": 57}
    for kind, count in expected.items():
        actual = len(catalogs[kind])
        if actual != count:
            raise AssertionError(f"{kind}: expected {count}, found {actual}")
    prompt = build_workflow("positive", "negative", "test.safetensors", 1, 512, 768, 20)
    if prompt["5"]["inputs"]["positive"] != ["2", 0]:
        raise AssertionError("ComfyUI positive conditioning link is invalid")
    if "capsule body" not in NEGATIVE or "five separated fingers" not in character_prompt(
        "pegasus", catalogs["characters"]["pegasus"])[0]:
        raise AssertionError("Character anatomy quality constraints are missing")
    print("PROMPT_ENGINE_SELF_TEST_PASS characters=32 armors=82 enemies=57 local_only=true")

def main() -> int:
    parser = argparse.ArgumentParser(description="Offline prompt engine and localhost ComfyUI bridge.")
    parser.add_argument("--kind", choices=("characters", "armors", "enemies", "all"), default="characters")
    parser.add_argument("--id", help="Generate one asset prompt by catalog ID.")
    parser.add_argument("--out", type=Path, default=PROMPT_DIR)
    parser.add_argument("--generate", action="store_true", help="Send prompts to a running local ComfyUI only.")
    parser.add_argument("--comfyui", default="http://127.0.0.1:8188")
    parser.add_argument("--checkpoint", default="v1-5-pruned-emaonly.safetensors")
    parser.add_argument("--width", type=int, default=512)
    parser.add_argument("--height", type=int, default=768)
    parser.add_argument("--steps", type=int, default=24)
    parser.add_argument("--seed", type=int, default=20261121)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    catalogs = load_catalogs()
    if args.self_test:
        run_self_test(catalogs)
        return 0
    kinds = list(catalogs) if args.kind == "all" else [args.kind]
    assets: list[tuple[str, str, str, str]] = []
    builders = {"characters": character_prompt, "armors": armor_prompt, "enemies": enemy_prompt}
    for kind in kinds:
        entries = catalogs[kind]
        if args.id:
            if args.id not in entries:
                raise SystemExit(f"Unknown {kind} ID: {args.id}")
            selected = [(args.id, entries[args.id])]
        else:
            selected = sorted(entries.items())
        for asset_id, entry in selected:
            positive, negative = builders[kind](asset_id, entry)
            assets.append((kind, asset_id, positive, negative))

    args.out.mkdir(parents=True, exist_ok=True)
    if args.generate:
        local_url(args.comfyui)
    for index, (kind, asset_id, positive, negative) in enumerate(assets):
        stem = f"{kind}_{safe_filename(asset_id)}"
        payload = {
            "kind": kind, "id": asset_id, "positive_prompt": positive,
            "negative_prompt": negative, "generation": "local_only",
        }
        (args.out / f"{stem}.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        (args.out / f"{stem}.txt").write_text(
            "POSITIVE PROMPT\n" + positive + "\n\nNEGATIVE PROMPT\n" + negative + "\n",
            encoding="utf-8")
        print(f"PROMPT_READY {kind}/{asset_id}")
        if args.generate:
            workflow = build_workflow(positive, negative, args.checkpoint,
                                      args.seed + index, args.width, args.height, args.steps)
            destination = IMAGE_DIR / kind / f"{safe_filename(asset_id)}.png"
            saved = queue_and_save(args.comfyui, workflow, destination, args.timeout)
            print(f"IMAGE_SAVED {saved}")
    print(f"PROMPT_BATCH_COMPLETE count={len(assets)} directory={args.out}")
    if args.generate:
        print("GENERATION_MODE=LOCAL_COMFYUI_NO_CLOUD")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
