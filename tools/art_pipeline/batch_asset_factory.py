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
import queue
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GENERATOR = ROOT / "tools" / "art_pipeline" / "blender" / "generate_base_rig.py"
BLENDER = os.environ.get("BLENDER_BIN", "blender")
WORKERS = max(1, int(os.environ.get("ART_FACTORY_WORKERS", "3")))
SHARDS = max(1, int(os.environ.get("ART_FACTORY_SHARDS", "1")))
RETRIES = max(0, int(os.environ.get("ART_FACTORY_RETRIES", "2")))
TASK_TIMEOUT_SECONDS = max(60, int(os.environ.get("ART_FACTORY_TASK_TIMEOUT_SECONDS", "1800")))
HEARTBEAT_SECONDS = max(10, int(os.environ.get("ART_FACTORY_HEARTBEAT_SECONDS", "60")))
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
        env = os.environ.copy()
        env["PYTHONUNBUFFERED"] = "1"
        with log_path.open("w", encoding="utf-8") as log:
            process = subprocess.Popen(
                command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, encoding="utf-8", errors="replace", bufsize=1, env=env,
            )
            assert process.stdout is not None
            output_queue: queue.Queue[str | None] = queue.Queue()

            def forward_output() -> None:
                try:
                    for output_line in process.stdout:
                        output_queue.put(output_line)
                finally:
                    output_queue.put(None)

            reader = threading.Thread(target=forward_output, name=f"{suffix}-output", daemon=True)
            reader.start()
            task_started = time.monotonic()
            last_heartbeat = task_started
            stream_closed = False
            while not stream_closed or process.poll() is None:
                now = time.monotonic()
                elapsed = now - task_started
                if elapsed >= TASK_TIMEOUT_SECONDS and process.poll() is None:
                    print(
                        f"TIMEOUT {stage} shard={shard + 1}/{shard_count} "
                        f"elapsed={elapsed:.0f}s limit={TASK_TIMEOUT_SECONDS}s; terminating Blender",
                        flush=True,
                    )
                    process.terminate()
                    try:
                        process.wait(timeout=15)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                try:
                    item = output_queue.get(timeout=1)
                    if item is None:
                        stream_closed = True
                    else:
                        log.write(item)
                        log.flush()
                        print(f"[{stage}:{shard + 1}/{shard_count}] {item}", end="", flush=True)
                except queue.Empty:
                    pass
                now = time.monotonic()
                if now - last_heartbeat >= HEARTBEAT_SECONDS and process.poll() is None:
                    print(
                        f"ART_FACTORY_HEARTBEAT stage={stage} shard={shard + 1}/{shard_count} "
                        f"elapsed_seconds={int(now - task_started)}",
                        flush=True,
                    )
                    last_heartbeat = now
            reader.join(timeout=5)
            result_code = process.wait()
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
    print(f"Parallel workers: {WORKERS}; shards per category: {SHARDS}; retries per batch: {RETRIES}; task timeout: {TASK_TIMEOUT_SECONDS}s; heartbeat: {HEARTBEAT_SECONDS}s")
    print("Phase 1/2: build shared rig, animation library, armor template and environments")
    try:
        foundation = subprocess.run(
            [BLENDER, "--background", "--python", str(GENERATOR), "--", "--stage", "foundation"],
            cwd=ROOT, check=False, timeout=900,
        )
    except subprocess.TimeoutExpired:
        print("FOUNDATION_TIMEOUT after 900 seconds; category workers were not started", file=sys.stderr)
        return 124
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
