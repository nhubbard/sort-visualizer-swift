#!/usr/bin/env python3
# /// script
# dependencies = ["tqdm"]
# ///
"""Delete only the Development candidate sets reviewed on 2026-10-02.

The frozen cache fingerprints identify the approved records. For each algorithm, query the
current matching record names and refuse the group if any name is outside that set. A
filtered CloudKit deletion handles the verified group. Re-running is safe: already deleted
records simply disappear from the query, while a partially completed group is checked again.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from cleanup_stale_sizes import (
    CONTAINER_ID,
    cache_path,
    load_cache,
    load_thresholds,
    threshold_digest,
)

EXPECTED = {
    "CD_BigORecord": (262_700, "22b4950bc5741cd56934c729a58274aad3efa82d4a485f03d6ba91d9d2232928"),
    "CD_RecordingCapExceededRecord": (5_479, "9b8046f938707dc771c6922165ff3555fc8f80b7e7f85c760f6a1b4ec1eb19da"),
}
ZONE = "com.apple.coredata.cloudkit.zone"
TEAM = "676UP3S3AH"


def approved_cache_path(record_type: str) -> Path:
    original = cache_path("development", record_type)
    return original.parent / "approved" / original.name


def fingerprint(record_type: str, entries: list[dict]) -> str:
    result = hashlib.sha256()
    for entry in sorted(entries, key=lambda item: item["recordName"]):
        payload = [record_type, entry["recordName"], entry["algorithmID"], entry["arraySize"], entry["threshold"]]
        result.update(json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode() + b"\n")
    return result.hexdigest()


def cktool(subcommand: str, token: str, *args: str) -> str:
    command = ["xcrun", "cktool", subcommand, "--token", token, *args]
    for attempt in range(6):
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=600)
        except subprocess.TimeoutExpired:
            raise RuntimeError(f"cktool {subcommand} timed out") from None
        if not result.returncode:
            return result.stdout.replace(token, "[redacted]")
        if subcommand == "query-records" and "too-many-requests" in result.stderr and attempt < 5:
            time.sleep(min(300, 30 * 2 ** attempt))
            continue
        raise RuntimeError(f"cktool {subcommand} failed: {result.stderr.replace(token, '[redacted]')[:1200]}")
    raise AssertionError("unreachable")


def common_args(record_type: str) -> list[str]:
    return [
        "--container-id", CONTAINER_ID,
        "--environment", "development",
        "--database-type", "private",
        "--zone-name", ZONE,
        "--record-type", record_type,
    ]


def matching_names(record_type: str, algorithm_id: str, threshold: int, token: str) -> set[str]:
    args = [
        "--team-id", TEAM, *common_args(record_type),
        "--filters", f"CD_algorithmID == {algorithm_id}", f"CD_arraySize > {threshold}",
        "--limit", "200",
    ]
    names: set[str] = set()
    cursor: str | None = None
    while True:
        response = json.loads(cktool("query-records", token, *args, *(["--continuation-token", cursor] if cursor else [])))
        page = response.get("records", [])
        page_names = {entry["recordName"] for entry in page}
        if len(page_names) != len(page) or names.intersection(page_names):
            raise RuntimeError("duplicate record name returned by CloudKit")
        names.update(page_names)
        cursor = response.get("continuationToken")
        if not cursor:
            return names


def clean_group(record_type: str, algorithm_id: str, entries: list[dict], token: str) -> tuple[str, int]:
    threshold = entries[0]["threshold"]
    approved = {entry["recordName"] for entry in entries}
    deleted = 0
    retries = 0
    while True:
        current = matching_names(record_type, algorithm_id, threshold, token)
        unexpected = current - approved
        if unexpected:
            raise RuntimeError(f"{algorithm_id}: {len(unexpected)} unreviewed matching record(s); group left untouched")
        if not current:
            return algorithm_id, deleted
        try:
            output = cktool(
                "delete-records", token, *common_args(record_type),
                "--filters", f"CD_algorithmID == {algorithm_id}", f"CD_arraySize > {threshold}",
                "--dry-run", "false", "--yes",
            )
        except RuntimeError as error:
            if not any(message in str(error) for message in ("retry-needed", "too-many-requests")) or retries >= 5:
                raise
            retries += 1
            base = 30 if "too-many-requests" in str(error) else 5
            time.sleep(min(300, base * 2 ** (retries - 1)))
            continue
        match = re.search(r"Deleted (\d+) matching records?\. \((\d+) errors\)", output)
        if match and int(match.group(2)) > 0 and retries < 5:
            retries += 1
            time.sleep(min(60, 5 * 2 ** (retries - 1)))
            continue
        if not match or int(match.group(2)) != 0:
            raise RuntimeError(f"{algorithm_id}: unexpected delete response: {output[:500]}")
        count = int(match.group(1))
        if count == 0 or count > len(current):
            raise RuntimeError(f"{algorithm_id}: deletion count {count} is inconsistent with {len(current)} reviewed matches")
        deleted += count
        retries = 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record-type", required=True, choices=EXPECTED)
    parser.add_argument("--token-file", required=True, type=Path)
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument("--algorithm-id", help="run one reviewed algorithm group")
    args = parser.parse_args()
    if not 1 <= args.workers <= 2:
        parser.error("workers must be one or two to avoid CloudKit throttling")
    token = args.token_file.read_text().strip()
    if not token:
        parser.error("token file is empty")
    frozen_path = approved_cache_path(args.record_type)
    source_path = frozen_path if frozen_path.exists() else cache_path("development", args.record_type)
    cache = load_cache(source_path)
    if cache is None or cache["continuationToken"] is not None:
        parser.error("requires a complete Development scan cache")
    if cache["thresholdsDigest"] != threshold_digest(load_thresholds()):
        parser.error("cache thresholds no longer match current algorithm maxima")
    entries = cache["eligible"]
    count, expected_hash = EXPECTED[args.record_type]
    if len(entries) != count or fingerprint(args.record_type, entries) != expected_hash:
        parser.error("cache differs from the approved candidate set")
    if not frozen_path.exists():
        frozen_path.parent.mkdir(exist_ok=True)
        temporary = frozen_path.with_suffix(".json.tmp")
        temporary.write_bytes(source_path.read_bytes())
        temporary.replace(frozen_path)
    groups: dict[str, list[dict]] = defaultdict(list)
    for entry in entries:
        groups[entry["algorithmID"]].append(entry)
    if args.algorithm_id:
        if args.algorithm_id not in groups:
            parser.error("algorithm is not in the approved candidate set")
        groups = {args.algorithm_id: groups[args.algorithm_id]}
    print(f"Verified frozen {args.record_type} cache: {len(entries)} candidates in {len(groups)} algorithms", flush=True)
    failures: list[str] = []
    deleted = 0
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(clean_group, args.record_type, algorithm_id, group, token): algorithm_id
            for algorithm_id, group in sorted(groups.items())
        }
        for future in as_completed(futures):
            algorithm_id = futures[future]
            try:
                _, count = future.result()
                deleted += count
                print(f"OK {algorithm_id}: {count} deleted in this run", flush=True)
            except Exception as error:
                failures.append(algorithm_id)
                print(f"FAILED {algorithm_id}: {error}", file=sys.stderr, flush=True)
    print(f"Run result: {deleted} deleted; {len(failures)} algorithm groups failed", flush=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
