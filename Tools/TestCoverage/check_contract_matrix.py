#!/usr/bin/env python3
"""Check that the versioned functional contract matrix still points to real evidence."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MATRIX = ROOT / "Documentation/docs/guides/functional-contract-matrix.md"
BASELINE = ROOT / "Tools/TestCoverage/baselines/2026-10-02/baseline.json"
ROW = re.compile(r"^\| ([A-Z]{3}-\d{2}) \|(.+)\|$")
LANE = re.compile(r"`((?:ios|catalyst)/[^`]+)`")
LINK = re.compile(r"\]\(([^)]+)\)")
STATUS = re.compile(r"\*\*(?:Complete|Partial|Open)(?:\*\*|:)")


def main() -> None:
    text = MATRIX.read_text()
    baseline = json.loads(BASELINE.read_text())
    lanes = set(baseline["results"])
    verified = set(baseline["verifiedTestResults"]) | set(
        baseline["behavioralOnlyResults"]
    )
    assert lanes == verified, "baseline lanes are missing a verified result"

    rows = [match for line in text.splitlines() if (match := ROW.fullmatch(line))]
    assert rows, "contract matrix has no rows"
    ids = [match.group(1) for match in rows]
    assert len(ids) == len(set(ids)), "contract IDs must be unique"
    for match in rows:
        row = match.group(0)
        assert row.count("|") == 7, f"wrong number of columns: {match.group(1)}"
        assert STATUS.search(row), f"missing status: {match.group(1)}"
        assert LANE.search(row), f"missing result-bundle lane: {match.group(1)}"
        assert LINK.search(row), f"missing linked test evidence: {match.group(1)}"
    for lane in set(LANE.findall(text)):
        assert lane in lanes, f"unknown result-bundle lane: {lane}"
    for target in LINK.findall(text):
        if target.startswith(("https://", "http://")):
            continue
        assert (MATRIX.parent / target).exists(), f"broken matrix link: {target}"
    print(f"Validated {len(rows)} contracts and {len(lanes)} result-bundle lanes")


if __name__ == "__main__":
    main()
