#!/usr/bin/env python3
"""Parallel coordinator for the Saint Seiya Blender asset factory.

Run from repository root:
  python3 tools/art_pipeline/batch_asset_factory.py
Optional environment:
  BLENDER_BIN=blender
  ART_FACTORY_WORKERS=3
  ART_FACTORY_SHARDS=1
"""
from __future__ import annotations

import concurrent.futures
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GENERATOR = ROOT / "tools" / "art_pipeline" / "blender" / "generate_base_rig.py"
BLENDER = os.environ.get("BLENDER_BIN", "blender")
WORKERS = max(1, int(os.environ.get("ART_FACTORY_WORKERS", "3")))
SHARDS = max(1, int(os.environ.get("ART_FACTORY_SHARDS", "1")))
RETRIES = max(0, int(os.environ.get("ART_FACTORY_RETRIES", "2")))
STAGES = ("characters", "armors", "enemies")


def run_task(stage: str, shard: int, shard_count: int) -> tuple[str, int, float, str, int]:
    log_dir = ROOT / "build" / "art_factory_logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    suffix = f"{stage}-{shard + 1}-of-{shard_count}"
    command = [
        BLENDER, "--background", "--python", str(GENERATOR), "--",
        "--stage", stage, "--shard-index", str(shard), "--shard-count", str(shard_count),
    ]
    started = time.monotonic()
    result_code = 1
    log_path = log_dir / f"{suffix}-attempt-{RETRIES + 1}.log"
    attempts_used = 0
    for attempt in range(1, RETRIES + 2):
        attempts_used = attempt
        log_path = log_dir / f"{suffix}-attempt-{attempt}.log"
        with log_path.open("w", encoding="utf-8") as log:
            result = subprocess.run(
                command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=False
            )
        result_code = result.returncode
        if result_code == 0:
            break
        if attempt <= RETRIES:
            print(f"RETRY {stage} shard={shard + 1}/{shard_count} next_attempt={attempt + 1}", flush=True)
    elapsed = time.monotonic() - started
    return stage, result_code, elapsed, str(log_path), attempts_used


def main() -> int:
    if not GENERATOR.is_file():
        print(f"Missing Blender generator: {GENERATOR}", file=sys.stderr)
        return 2
    print("SAINT_SEIYA_ART_FACTORY")
    print(f"Blender: {BLENDER}")
    print(f"Parallel workers: {WORKERS}; shards per category: {SHARDS}; retries per batch: {RETRIES}")
    print("Phase 1/2: build shared rig, animation library, armor template and environments")
    foundation = subprocess.run(
        [BLENDER, "--background", "--python", str(GENERATOR), "--", "--stage", "foundation"],
        cwd=ROOT, check=False,
    )
    if foundation.returncode:
        print("FOUNDATION_FAILED; category workers were not started", file=sys.stderr)
        return foundation.returncode

    tasks = [(stage, shard, SHARDS) for stage in STAGES for shard in range(SHARDS)]
    print(f"Phase 2/2: dispatch {len(tasks)} independent asset batches")
    failures = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = [pool.submit(run_task, *task) for task in tasks]
        for future in concurrent.futures.as_completed(futures):
            stage, code, elapsed, log_path, attempts = future.result()
            status = "PASS" if code == 0 else "FAIL"
            print(f"{status} {stage} attempts={attempts} in {elapsed / 60:.1f} min; log={log_path}", flush=True)
            if code:
                failures.append((stage, code, log_path))
    if failures:
        for stage, code, log_path in failures:
            print(f"FAILED_BATCH {stage} exit={code} log={log_path}", file=sys.stderr)
        return 1
    print("ART_FACTORY_BATCHES_PASS")
    print("Note: this validates generated prototype assets; visual art still requires review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
