#!/usr/bin/env python3
"""Bakes each algorithm's *detected* growth family (before Taylor expansion) into its Swift
source file, as a second, display-only literal next to the existing `growthModel:` block.

Standalone and deliberately separate from `apply_growth_models.py` -- this needs none of that
script's SymPy-bridge machinery, since the detected family + its own fitted coefficients are
already sitting in `output/sort-growth-models.json` (`winningFamily`/`coefficients`/
`winningRSquared`); only the Taylor-expansion step ever needed the bridge, and it already ran
for every algorithm that has a `growthModel:` block on disk today.

Every entry's algorithm ID is derived from `subjectID` and looked up by searching for an existing
`growthModel: OperationGrowthModel(...)` block in that algorithm's source file -- an algorithm
with no such block yet (never calibrated, e.g. one just added and not yet run through
`GrowthModelCalibrationTests`) is skipped with a warning rather than guessed at. This is what
keeps this script from ever touching a brand-new, not-yet-calibrated algorithm's file.

Usage:
    uv run apply_detected_models.py [--only algorithmID,algorithmID,...] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

_REPORT_PATH = Path(__file__).parent / "output" / "sort-growth-models.json"
_SOURCES_DIR = Path(__file__).parents[2] / "Modules" / "BuiltInAlgorithms" / "Sources"

_SIGNIFICANT_DIGITS = 6


def format_double(value: float) -> str:
    # Mirrors `apply_growth_models.py`'s own `format_double` -- keeps only the significant digits
    # an empirical fit can actually claim, and matches the Swift side's
    # `.formatted(.number.precision(.significantDigits(1...6)).grouping(.never))` rendering.
    if value == 0:
        return "0"
    rounded = float(f"{value:.{_SIGNIFICANT_DIGITS}g}")
    if rounded == int(rounded) and abs(rounded) < 1e15:
        return str(int(rounded))
    return f"{value:.{_SIGNIFICANT_DIGITS}g}"


def find_source_file(algorithm_id: str) -> Path | None:
    needle = f'AlgorithmID(rawValue: "{algorithm_id}")'
    # Recursive, unlike `apply_growth_models.py`'s own `find_source_file` -- algorithm sources now
    # live under per-category subdirectories (`Exchange/`, `Insertion/`, ...), not flat directly
    # in `Sources/`, so a non-recursive glob would silently find nothing.
    for path in _SOURCES_DIR.rglob("*.swift"):
        if needle in path.read_text():
            return path
    return None


# Always exactly this 3-line shape -- `apply_growth_models.py`'s `insert_growth_model` never
# varies it regardless of polynomial order, so this can match the whole block structurally
# instead of anchoring on just one line within it.
_GROWTH_MODEL_BLOCK = re.compile(
    r"^(?P<indent>[ \t]*)growthModel: OperationGrowthModel\(\n"
    r"[ \t]*anchorSize:.*,\n"
    r"[ \t]*measuredSafeCeiling:.*\),$",
    re.MULTILINE,
)

# Always exactly this 3-line shape too -- mirrors `_GROWTH_MODEL_BLOCK` above, so a re-calibration
# run can find and replace a previously-applied `detectedGrowthModel:` block the same
# structural way `apply_growth_models.py` now replaces an existing `growthModel:` block, instead
# of silently no-op'ing on every algorithm that was ever calibrated before (the original
# behavior here: unconditionally skip whenever the keyword was already present at all, which
# meant a corrected re-calibration -- e.g. ShoveSort's real family, fixed after its first
# calibration mis-detected `exponential` from too narrow a sampled range -- could never actually
# reach the source file through this script).
_DETECTED_MODEL_BLOCK = re.compile(
    r"^(?P<indent>[ \t]*)detectedGrowthModel: DetectedGrowthModel\(\n"
    r"[ \t]*family:.*rSquared:.*\),$",
    re.MULTILINE,
)


def insert_detected_model(path: Path, family: str, coefficients: list[float], r_squared: float) -> bool:
    text = path.read_text()
    coefficients_literal = ", ".join(format_double(c) for c in coefficients)
    new_block = (
        f"{{indent}}detectedGrowthModel: DetectedGrowthModel(\n"
        f"{{indent}}  family: .{family}, coefficients: [{coefficients_literal}], "
        f"rSquared: {format_double(r_squared)}),")

    existing = _DETECTED_MODEL_BLOCK.search(text)
    if existing is not None:
        text = text[: existing.start()] + new_block.format(indent=existing.group("indent")) + text[existing.end() :]
        path.write_text(text)
        return True

    match = _GROWTH_MODEL_BLOCK.search(text)
    if match is None:
        return False
    text = text[: match.end()] + "\n" + new_block.format(indent=match.group("indent")) + text[match.end() :]
    path.write_text(text)
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help="comma-separated algorithmIDs to process (spot-check)")
    parser.add_argument("--dry-run", action="store_true", help="report, but don't write")
    args = parser.parse_args()

    entries = json.loads(_REPORT_PATH.read_text())
    only = set(args.only.split(",")) if args.only else None

    updated = 0
    skipped_no_source: list[str] = []
    skipped_no_growth_model: list[str] = []
    for entry in entries:
        algorithm_id = entry["subjectID"].split("+")[0]
        if only is not None and algorithm_id not in only:
            continue

        path = find_source_file(algorithm_id)
        if path is None:
            skipped_no_source.append(algorithm_id)
            continue

        print(
            f"{algorithm_id}: {entry['winningFamily']} "
            f"(R²={entry['winningRSquared']:.4f}) -> {path.name}")
        if args.dry_run:
            continue
        if insert_detected_model(
            path, entry["winningFamily"], entry["coefficients"], entry["winningRSquared"]
        ):
            updated += 1
        else:
            skipped_no_growth_model.append(algorithm_id)

    print(f"\n{updated} file(s) updated (inserted new or replaced an existing detectedGrowthModel:).")
    if skipped_no_source:
        print(
            f"{len(skipped_no_source)} algorithm(s) skipped -- no source file found: "
            f"{', '.join(sorted(skipped_no_source))}", file=sys.stderr)
    if skipped_no_growth_model:
        print(
            f"{len(skipped_no_growth_model)} algorithm(s) skipped -- no growthModel: block found "
            f"yet (not calibrated): {', '.join(sorted(skipped_no_growth_model))}", file=sys.stderr)


if __name__ == "__main__":
    main()
