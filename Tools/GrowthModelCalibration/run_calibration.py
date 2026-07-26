#!/usr/bin/env python3
"""Wrapper for running the growth-model calibration Swift Testing suite without hand-typing long
`TEST_RUNNER_*`-prefixed `xcodebuild` invocations every time.

`GrowthModelCalibrationTests` (Modules/BuiltInAlgorithms/Tests/) is gated behind the
`RUN_GROWTH_CALIBRATION` environment variable so it never runs as part of a plain `xcodebuild
test`. xcodebuild only forwards environment variables to the actual test process when they're
prefixed `TEST_RUNNER_` on the invoking shell, which is what made hand-running this fiddly enough
to be worth wrapping.

Usage:
    uv run run_calibration.py [--algorithm SUBSTR] [--shuffle SUBSTR] [--no-bridge] [--verbose]

Starts the Python/SymPy bridge server automatically (unless --no-bridge is passed, e.g. because
you already have one running in another terminal), runs the suite via `xcodebuild` on Mac
Catalyst (a native process — no simulator boot needed), streams a filtered view of the output
(pass/fail lines and the report summary — pass --verbose for the raw xcodebuild log instead), and
tears the bridge server back down afterward.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BRIDGE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BRIDGE_DIR / "output"
BRIDGE_HEALTH_URL = "http://127.0.0.1:8765/health"

_INTERESTING_LINE = re.compile(
    r"(\[calibration\]|Test Suite|Test run|passed after|failed after|error:|Expectation failed|"
    r"^===|R²|safe max|BUILD FAILED|\*\* TEST (SUCCEEDED|FAILED) \*\*)"
)


def bridge_is_healthy(timeout: float = 1.0) -> bool:
    try:
        with urllib.request.urlopen(BRIDGE_HEALTH_URL, timeout=timeout) as response:
            return response.status == 200
    except Exception:
        return False


def start_bridge() -> subprocess.Popen | None:
    if bridge_is_healthy():
        print("[calibration] bridge already running, reusing it")
        return None

    print("[calibration] starting bridge server...")
    process = subprocess.Popen(
        ["uv", "run", "bridge_server.py"],
        cwd=BRIDGE_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    for _ in range(30):
        if bridge_is_healthy():
            print("[calibration] bridge is up")
            return process
        time.sleep(0.2)

    process.terminate()
    raise RuntimeError("bridge server did not become healthy within 6 seconds")


def run_tests(
    algorithm_filter: str | None, shuffle_filter: str | None, verbose: bool,
    log_file: Path | None,
) -> int:
    env = os.environ.copy()
    env["TEST_RUNNER_RUN_GROWTH_CALIBRATION"] = "1"
    if algorithm_filter:
        env["TEST_RUNNER_GROWTH_CALIBRATION_ALGORITHM_FILTER"] = algorithm_filter
    if shuffle_filter:
        env["TEST_RUNNER_GROWTH_CALIBRATION_SHUFFLE_FILTER"] = shuffle_filter

    command = [
        "xcodebuild",
        "-workspace", str(REPO_ROOT / "Sort Symphony.xcworkspace"),
        "-scheme", "BuiltInAlgorithms",
        "-destination", "platform=macOS,variant=Mac Catalyst",
        "test",
        "-only-testing:BuiltInAlgorithmsTests/GrowthModelCalibrationTests",
    ]

    print(f"[calibration] algorithm filter: {algorithm_filter or '(none -- every algorithm)'}")
    print(f"[calibration] shuffle filter:   {shuffle_filter or '(none -- every shuffle)'}")
    print("[calibration] this can take a while for an unfiltered run -- streaming progress below")

    log_handle = log_file.open("w") if log_file else None
    if log_file:
        print(f"[calibration] full (unfiltered-view) log: {log_file}")

    process = subprocess.Popen(
        command, cwd=REPO_ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1,
    )
    assert process.stdout is not None
    try:
        for line in process.stdout:
            line = line.rstrip()
            if log_handle:
                log_handle.write(line + "\n")
                log_handle.flush()
            if verbose or _INTERESTING_LINE.search(line):
                print(line, flush=True)
    finally:
        if log_handle:
            log_handle.close()
    return process.wait()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--algorithm", help="substring filter against AlgorithmID.rawValue (e.g. 'guesssort')")
    parser.add_argument("--shuffle", help="substring filter against ShuffleID.rawValue (e.g. 'random')")
    parser.add_argument("--no-bridge", action="store_true", help="assume a bridge server is already running")
    parser.add_argument("--verbose", action="store_true", help="print the raw xcodebuild output instead of a filtered view")
    parser.add_argument("--log-file", type=Path, help="also write the complete (unfiltered) xcodebuild output here")
    args = parser.parse_args()

    bridge_process = None if args.no_bridge else start_bridge()
    try:
        exit_code = run_tests(args.algorithm, args.shuffle, args.verbose, args.log_file)
    finally:
        if bridge_process is not None:
            print("[calibration] stopping bridge server")
            bridge_process.terminate()
            try:
                bridge_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                bridge_process.kill()

    if OUTPUT_DIR.exists():
        reports = sorted(OUTPUT_DIR.glob("*.json"))
        if reports:
            print("[calibration] report files:")
            for report in reports:
                print(f"  {report}")

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
