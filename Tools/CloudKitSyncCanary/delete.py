#!/usr/bin/env python3
"""Delete exactly one named HIS-02 canary from the private CloudKit database."""

import argparse
import json
import subprocess
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("marker", help="Full his02-canary-* algorithm ID")
    parser.add_argument("--environment", choices=("development", "production"), default="development")
    parser.add_argument(
        "--token-file", type=Path,
        default=Path(__file__).resolve().parent.parent / "CloudKitCleanup" / ".user-token",
    )
    args = parser.parse_args()
    if not args.marker.startswith("his02-canary-"):
        parser.error("marker must start with his02-canary-")
    token = args.token_file.read_text().strip()
    common = [
        "--token", token,
        "--container-id", "iCloud.com.nhubbard.Sort2.mobile",
        "--environment", args.environment,
        "--database-type", "private",
        "--zone-name", "com.apple.coredata.cloudkit.zone",
    ]
    query = subprocess.run(
        ["xcrun", "cktool", "query-records", *common, "--team-id", "676UP3S3AH",
         "--record-type", "CD_BigORecord", "--filters", f"CD_algorithmID == {args.marker}",
         "--limit", "2"],
        capture_output=True, text=True, timeout=120,
    )
    if query.returncode:
        raise SystemExit(query.stderr.replace(token, "[redacted]")[:1200])
    records = json.loads(query.stdout).get("records", [])
    if len(records) != 1:
        raise SystemExit(f"Expected exactly one disposable canary; found {len(records)}")
    record_name = records[0]["recordName"]
    deletion = subprocess.run(
        ["xcrun", "cktool", "delete-record", *common,
         "--record-name", record_name, "--yes"],
        capture_output=True, text=True, timeout=120,
    )
    if deletion.returncode:
        raise SystemExit(deletion.stderr.replace(token, "[redacted]")[:1200])
    print(json.dumps({"marker": args.marker, "deletedRecordName": record_name}, indent=2))


if __name__ == "__main__":
    main()
