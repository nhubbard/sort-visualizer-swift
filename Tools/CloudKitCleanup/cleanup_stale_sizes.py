#!/usr/bin/env python3
# /// script
# dependencies = ["tqdm"]
# ///
"""One-time cleanup: delete CloudKit BigORecord/RecordingCapExceededRecord entries whose
arraySize exceeds the algorithm's current growth-model-derived safe max at the app's default
300,000-operation cap. See this directory's README for the full "why" and setup steps.

Dry run by default -- prints what WOULD be deleted, grouped by algorithm, and changes nothing.
Pass --execute to actually delete (one delete-record call per matching record; the per-algorithm
threshold table can't be expressed as a single CloudKit query filter, so there's no bulk
delete-records shortcut here).

The full-database fetch (tens of thousands of records, ~200/page, one `cktool` subprocess call
per page -- not a stream) is the slow part, so progress is persisted to disk
(.cache/<environment>__<record-type>.json) after EVERY page, not just once at the end: each write
includes the CloudKit continuationToken alongside the eligible-for-deletion list found so far. A
run that's killed or crashes mid-fetch can just be re-invoked -- it resumes from the last saved
continuationToken instead of re-fetching everything from page 1. Once a fetch actually finishes
(continuationToken goes to null), a later invocation for the same (environment, record-type)
skips the network entirely and reuses the cached eligible list -- pass --refresh to force a fully
fresh fetch regardless of what's cached. --execute removes each successfully-deleted record from
the cache as it goes, so a run that fails partway through deleting can also just be re-run.

Requires `xcrun cktool save-token --type user` to already have been run for the iCloud account
the app syncs analytics under (see README).

Usage (uv run, not plain python3 -- this script declares its own tqdm dependency inline (PEP
723) and uv installs it into an ephemeral env automatically, no venv/pip setup needed):
    uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord
    uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord --execute
    uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord --refresh
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from tqdm import tqdm

REPO_ROOT = Path(__file__).resolve().parents[2]
GROWTH_MODEL_REPORT = (
    REPO_ROOT / "Tools" / "GrowthModelCalibration" / "output" / "sort-growth-models.json"
)
CACHE_DIR = Path(__file__).resolve().parent / ".cache"
CONTAINER_ID = "iCloud.com.nhubbard.Sort2.mobile"
DEFAULT_OPERATION_CAP = 300_000.0


def load_thresholds() -> dict[str, float]:
    """algorithmID -> safe max array size at the 300,000-op cap, per the most recent growth-model
    calibration. Every algorithm currently has a value at this cap (checked directly when this
    script was written); if a future re-calibration ever leaves one without one, it's skipped
    with a warning rather than guessed at -- better to under-delete than to invent a threshold."""
    entries = json.loads(GROWTH_MODEL_REPORT.read_text())
    thresholds: dict[str, float] = {}
    missing: list[str] = []
    for entry in entries:
        algorithm_id = entry["subjectID"].split("+")[0]
        pairs = entry["safeMaxSizeByCap"]
        value = None
        for i in range(0, len(pairs), 2):
            if pairs[i] == DEFAULT_OPERATION_CAP:
                value = pairs[i + 1]
                break
        if value is None:
            missing.append(algorithm_id)
        else:
            thresholds[algorithm_id] = value
    if missing:
        print(
            f"warning: {len(missing)} algorithm(s) have no safe-max at the 300,000 cap, "
            f"skipping (their records won't be touched): {', '.join(sorted(missing))}",
            file=sys.stderr,
        )
    return thresholds


def run_cktool(args: list[str]) -> dict:
    result = subprocess.run(
        ["xcrun", "cktool", *args], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        print(f"cktool {' '.join(args)} failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print(f"cktool returned non-JSON output:\n{result.stdout}", file=sys.stderr)
        sys.exit(1)


def field_value(fields: dict, key: str):
    """cktool's JSON wraps each field as {"value": ..., "type": "..."} -- tolerate a bare
    scalar too, in case that assumption is wrong for this cktool version."""
    raw = fields.get(key)
    if isinstance(raw, dict):
        return raw.get("value")
    return raw


def cache_path(environment: str, record_type: str) -> Path:
    return CACHE_DIR / f"{environment}__{record_type}.json"


def load_cache(path: Path) -> dict | None:
    """Returns the full persisted payload (continuationToken, totalFetched, eligible), or None if
    no cache exists yet. A non-None `continuationToken` means a previous fetch was interrupted
    partway through -- the caller should resume from it, not treat this as a finished result."""
    if not path.exists():
        return None
    return json.loads(path.read_text())


def save_cache(
    path: Path, *, environment: str, record_type: str, eligible: list[dict],
    continuation_token: str | None, total_fetched: int,
) -> None:
    """Atomic write (temp file + rename) so a crash mid-write can never leave a half-written,
    unparseable cache file behind -- important here since this is called after every single page
    during a multi-minute fetch, not just once at the end."""
    CACHE_DIR.mkdir(exist_ok=True)
    payload = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "environment": environment,
        "recordType": record_type,
        "continuationToken": continuation_token,
        "totalFetched": total_fetched,
        "eligible": eligible,
    }
    tmp_path = path.with_suffix(".json.tmp")
    tmp_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    tmp_path.replace(path)


def fetch_and_filter(
    *, container_id: str, environment: str, database_type: str, zone_name: str,
    record_type: str, team_id: str | None, thresholds: dict[str, float],
    algorithm_field: str, size_field: str, cache_file: Path, resume_from: dict | None,
) -> tuple[list[dict], int]:
    """Fetches every page of `record_type`, filtering each record against `thresholds` as it
    arrives, and persists (eligible list + continuationToken) to `cache_file` after every page --
    not a stream, each page is its own `cktool query-records` subprocess call/network round trip
    (200 records/call), and cktool has no "give me the total count first" query, hence the
    indeterminate-total tqdm bar (a live count + rate, no percentage) rather than a classic 0-100%
    one. `resume_from`, if given, is a previously-saved cache payload to continue from -- its
    `continuationToken` becomes the first page requested and its `eligible`/`totalFetched` seed
    the running totals, so an interrupted run picks up where it left off instead of restarting."""
    eligible: list[dict] = list(resume_from["eligible"]) if resume_from else []
    total_fetched = resume_from["totalFetched"] if resume_from else 0
    continuation_token: str | None = resume_from["continuationToken"] if resume_from else None
    unknown_algorithms: set[str] = set()

    desc = f"Fetching {record_type} ({environment})"
    with tqdm(initial=total_fetched, desc=desc, unit=" records", file=sys.stderr) as pbar:
        while True:
            # Deliberately NOT passing --requested-fields: empirically, cktool only honors the
            # *last* occurrence when it's repeated (confirmed live -- two flags silently dropped
            # the first field from the response), so asking for both algorithm_field and
            # size_field would silently lose one. Fetching full records is simpler and reliable.
            args = [
                "query-records",
                "--container-id", container_id,
                "--environment", environment,
                "--database-type", database_type,
                "--zone-name", zone_name,
                "--record-type", record_type,
                "--limit", "200",
            ]
            if team_id:
                args += ["--team-id", team_id]
            if continuation_token:
                args += ["--continuation-token", continuation_token]
            response = run_cktool(args)
            page = response.get("records", [])
            continuation_token = response.get("continuationToken")
            total_fetched += len(page)

            for record in page:
                fields = record.get("fields", {})
                algorithm_id = field_value(fields, algorithm_field)
                array_size = field_value(fields, size_field)
                record_name = record.get("recordName")
                if algorithm_id is None or array_size is None or record_name is None:
                    tqdm.write(f"warning: record missing expected fields, skipping: {record}")
                    continue
                threshold = thresholds.get(algorithm_id)
                if threshold is None:
                    unknown_algorithms.add(algorithm_id)
                    continue
                if array_size > threshold:
                    eligible.append({
                        "recordName": record_name, "algorithmID": algorithm_id,
                        "arraySize": array_size, "threshold": threshold,
                    })

            pbar.update(len(page))
            save_cache(
                cache_file, environment=environment, record_type=record_type, eligible=eligible,
                continuation_token=continuation_token, total_fetched=total_fetched,
            )
            if not continuation_token:
                break

    if unknown_algorithms:
        print(
            f"note: {len(unknown_algorithms)} algorithmID(s) in the data have no known threshold "
            f"(renamed/removed algorithm?), left untouched: {', '.join(sorted(unknown_algorithms))}\n",
            file=sys.stderr,
        )
    print(f"Fetched {total_fetched} total.\n", file=sys.stderr)
    return eligible, total_fetched


def print_summary(eligible: list[dict], *, executing: bool) -> None:
    by_algorithm: dict[str, list[dict]] = {}
    for entry in eligible:
        by_algorithm.setdefault(entry["algorithmID"], []).append(entry)

    print(f"=== {'DELETING' if executing else 'WOULD DELETE'} ({len(eligible)} records) ===")
    for algorithm_id in sorted(by_algorithm):
        entries = by_algorithm[algorithm_id]
        threshold = entries[0]["threshold"]
        sizes = sorted(e["arraySize"] for e in entries)
        print(f"  {algorithm_id}: {len(entries)} record(s) above threshold {threshold:g} -- sizes {sizes}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--environment", required=True, choices=["development", "production"])
    parser.add_argument("--record-type", required=True, help="e.g. CD_BigORecord")
    parser.add_argument("--database-type", default="private")
    parser.add_argument("--zone-name", default="com.apple.coredata.cloudkit.zone")
    parser.add_argument("--algorithm-field", default="CD_algorithmID")
    parser.add_argument("--size-field", default="CD_arraySize")
    parser.add_argument("--team-id", default="676UP3S3AH", help="required by query-records; not by delete-record")
    parser.add_argument("--execute", action="store_true", help="actually delete (default: dry run)")
    parser.add_argument("--refresh", action="store_true", help="ignore any cached/resumable state and start a fully fresh fetch")
    args = parser.parse_args()

    path = cache_path(args.environment, args.record_type)
    existing = None if args.refresh else load_cache(path)

    if existing is not None and existing["continuationToken"] is None:
        print(f"Using cached eligible-list from {path} (pass --refresh to re-fetch from CloudKit).\n", file=sys.stderr)
        eligible = existing["eligible"]
        total_fetched = existing["totalFetched"]
    else:
        if existing is not None:
            print(
                f"Resuming interrupted fetch from {path} "
                f"({existing['totalFetched']} record(s) already fetched)...\n", file=sys.stderr,
            )
        thresholds = load_thresholds()
        eligible, total_fetched = fetch_and_filter(
            container_id=CONTAINER_ID, environment=args.environment, database_type=args.database_type,
            zone_name=args.zone_name, record_type=args.record_type, team_id=args.team_id,
            thresholds=thresholds, algorithm_field=args.algorithm_field, size_field=args.size_field,
            cache_file=path, resume_from=existing,
        )
        print(f"Cached {len(eligible)} eligible record(s) to {path}.\n", file=sys.stderr)

    print_summary(eligible, executing=args.execute)

    if not eligible:
        print("\nNothing to delete.")
        return

    if not args.execute:
        print(f"\nDry run only -- re-run with --execute to actually delete these {len(eligible)} record(s).")
        return

    print()
    remaining = list(eligible)
    deleted = 0
    for entry in eligible:
        delete_args = [
            "delete-record",
            "--container-id", CONTAINER_ID,
            "--environment", args.environment,
            "--database-type", args.database_type,
            "--zone-name", args.zone_name,
            "--record-name", entry["recordName"],
            "--yes",
        ]
        result = subprocess.run(["xcrun", "cktool", *delete_args], capture_output=True, text=True)
        if result.returncode != 0:
            print(
                f"  FAILED to delete {entry['recordName']} ({entry['algorithmID']}, "
                f"size {entry['arraySize']}): {result.stderr}", file=sys.stderr,
            )
        else:
            deleted += 1
            remaining.remove(entry)
            # Rewrite after every deletion, not just at the end -- a crash/interrupt partway
            # through should still leave the cache reflecting exactly what's left to retry.
            # continuationToken is always None here -- only a fully-completed fetch ever reaches
            # the execute step, never a resumable partial one.
            save_cache(
                path, environment=args.environment, record_type=args.record_type,
                eligible=remaining, continuation_token=None, total_fetched=total_fetched,
            )

    print(f"Deleted {deleted}/{len(eligible)} record(s).")
    if remaining:
        print(f"{len(remaining)} record(s) failed and are still cached in {path} for retry.")


if __name__ == "__main__":
    main()
