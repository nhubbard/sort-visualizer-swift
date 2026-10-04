#!/usr/bin/env python3
"""Read only: locate one HIS-02 marker in the authenticated private CloudKit database."""

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
    command = [
        "xcrun", "cktool", "query-records", "--token", token,
        "--team-id", "676UP3S3AH",
        "--container-id", "iCloud.com.nhubbard.Sort2.mobile",
        "--environment", args.environment,
        "--database-type", "private",
        "--zone-name", "com.apple.coredata.cloudkit.zone",
        "--record-type", "CD_BigORecord",
        "--filters", f"CD_algorithmID == {args.marker}",
        "--limit", "20",
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=120)
    if result.returncode:
        raise SystemExit(result.stderr.replace(token, "[redacted]")[:1200])
    records = json.loads(result.stdout).get("records", [])
    print(json.dumps({
        "environment": args.environment,
        "marker": args.marker,
        "count": len(records),
        "recordNames": [record["recordName"] for record in records],
    }, indent=2))


if __name__ == "__main__":
    main()
