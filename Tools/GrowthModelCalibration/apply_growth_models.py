#!/usr/bin/env python3
"""Bakes each algorithm's real, measured operation-count growth curve into its Swift source file.

Dev-tool only, run by hand after `sort-growth-models.json` is (re-)generated. Reads that report and,
per algorithm, Taylor-expands its fitted growth curve into a single general form -- a plain
polynomial in `(n - anchorSize)` -- via the already-running `bridge_server.py` (the same Taylor
machinery it already used for the `powerLog` family, now used for all six). This is deliberately
*not* six different closed-form/Newton inversions baked into the runtime: every algorithm ends up
represented the same way (`OperationGrowthModel` in `AlgorithmKit`), so the shipped app never needs
to know which of the six growth families an algorithm actually belongs to.

The polynomial order starts at 1 (a straight line -- exact for genuinely linear or constant growth,
so those algorithms just get a 2-coefficient model) and escalates only as far as needed: each
candidate order is checked against the real fitted curve's own answer at five operation-cap
checkpoints spanning the app's full `recordingOperationCap` range (50,000 to 5,000,000), and the
first order whose worst relative error across those checkpoints is within `TOLERANCE` wins. This
means a single fixed-order Taylor expansion is never forced onto a curve it doesn't fit well -- the
100x cap range is exactly why a fixed low order isn't safe to assume up front.

Usage:
    uv run bridge_server.py &          # in another terminal, or already running
    uv run apply_growth_models.py [--only algorithmID,algorithmID,...] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Callable

_BRIDGE_URL = "http://127.0.0.1:8765"
_REPORT_PATH = Path(__file__).parent / "output" / "sort-growth-models.json"
_SOURCES_DIR = Path(__file__).parents[2] / "Modules" / "BuiltInAlgorithms" / "Sources"

_SAFETY_MARGIN = 0.8
_CAP_CHECKPOINTS = [50_000, 100_000, 300_000, 1_000_000, 5_000_000]
_MAX_ORDER = 6
_TOLERANCE = 0.05


# -- Real family formulas (mirrors CurveFitting.swift's `predict`) -----------------------------


def _family_function(family: str, coefficients: list[float]) -> Callable[[float], float]:
    if family == "powerLaw":
        a, k = coefficients
        return lambda n: a * n**k
    if family == "powerLog":
        a, k = coefficients
        return lambda n: a * n**k * math.log(n)
    if family == "polynomialIntercept":
        a, b, c = coefficients
        return lambda n: a * n * n + b * n + c
    if family == "exponential":
        a, b = coefficients
        return lambda n: a * b**n
    if family == "nToTheNLike":
        a, c = coefficients
        return lambda n: a * math.exp(c * n * math.log(n))
    if family == "factorial":
        a, c = coefficients
        return lambda n: a * math.exp(c * (n * math.log(n) - n))
    raise ValueError(f"unknown growth family: {family}")


def _family_expression(family: str, coefficients: list[float]) -> str:
    if family == "powerLaw":
        a, k = coefficients
        return f"{a!r}*n**{k!r}"
    if family == "powerLog":
        a, k = coefficients
        return f"{a!r}*n**{k!r}*log(n)"
    if family == "polynomialIntercept":
        a, b, c = coefficients
        return f"{a!r}*n**2 + {b!r}*n + {c!r}"
    if family == "exponential":
        a, b = coefficients
        return f"{a!r}*{b!r}**n"
    if family == "nToTheNLike":
        a, c = coefficients
        return f"{a!r}*exp({c!r}*n*log(n))"
    if family == "factorial":
        a, c = coefficients
        return f"{a!r}*exp({c!r}*(n*log(n) - n))"
    raise ValueError(f"unknown growth family: {family}")


# -- Generic monotonic-increasing solver, used for both the "ground truth" family curve and the --
# -- candidate Taylor polynomial -- avoids needing a second, closed-form inverse per family. ------


def _safe_evaluate(f: Callable[[float], float], n: float) -> float:
    try:
        value = f(n)
    except (OverflowError, ValueError):
        return math.inf
    if math.isnan(value):
        return math.inf
    return value


def solve_for_n(f: Callable[[float], float], target: float) -> float | None:
    """Largest real root isn't needed here -- `f` is monotonically increasing by construction
    (calibration's own guarantee, see REPORT_FORMAT.md), so plain bisection finds the one crossing.
    Returns `None` if `f` never reaches `target` within a domain wide enough to trust (the curve is
    too flat/negligible), matching `safeMaxSizeByCap`'s "no entry for a cap" convention.
    """
    lo, hi = 1.0, 1_000.0
    if _safe_evaluate(f, lo) > target:
        return None
    while _safe_evaluate(f, hi) < target:
        hi *= 4
        if hi > 1e15:
            return None
    for _ in range(200):
        mid = (lo + hi) / 2
        if _safe_evaluate(f, mid) < target:
            lo = mid
        else:
            hi = mid
    return lo


# -- Bridge client ---------------------------------------------------------------------------


def taylor_coefficients(expr: str, n0: float, order: int) -> list[float]:
    body = json.dumps({"expr": expr, "n0": n0, "order": order}).encode("utf-8")
    request = urllib.request.Request(
        f"{_BRIDGE_URL}/taylor-invert", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read())
    return payload["coefficients"]


def _taylor_function(coefficients: list[float], anchor: float) -> Callable[[float], float]:
    def evaluate(n: float) -> float:
        x = n - anchor
        return sum(c * x**i for i, c in enumerate(coefficients))

    return evaluate


# -- Per-algorithm pipeline -------------------------------------------------------------------


class ConvergenceWarning(Exception):
    def __init__(self, subject_id: str, worst_error: float):
        super().__init__(f"{subject_id}: best achievable relative error {worst_error:.1%}")
        self.subject_id = subject_id
        self.worst_error = worst_error


def fit_taylor_model(entry: dict) -> tuple[float, list[float], float, bool]:
    """Returns (anchorSize, coefficients, worstRelativeError, converged). `converged` is `False`
    only if no order up to `_MAX_ORDER` hit `_TOLERANCE` -- the best attempt is still returned so
    every algorithm gets a model, just flagged for a human to look at.
    """
    family = entry["winningFamily"]
    real_fn = _family_function(family, entry["coefficients"])
    expr = _family_expression(family, entry["coefficients"])

    cap_pairs = entry["safeMaxSizeByCap"]
    anchor = next(
        (cap_pairs[i + 1] for i in range(0, len(cap_pairs), 2) if cap_pairs[i] == 300_000), None)
    if anchor is None:
        anchor = float(max(entry["sampleSizes"]))
    anchor = max(anchor, 2.0)  # log(n) needs n > 1; every real fit is measured well above this

    ground_truths: dict[int, float] = {}
    for cap in _CAP_CHECKPOINTS:
        truth = solve_for_n(real_fn, cap * _SAFETY_MARGIN)
        if truth is not None:
            ground_truths[cap] = truth

    best: tuple[float, list[float], float] | None = None
    for order in range(1, _MAX_ORDER + 1):
        coefficients = taylor_coefficients(expr, anchor, order)
        taylor_fn = _taylor_function(coefficients, anchor)

        errors = []
        for cap, truth in ground_truths.items():
            candidate = solve_for_n(taylor_fn, cap * _SAFETY_MARGIN)
            if candidate is None:
                errors.append(1.0)  # Taylor fit lost the crossing entirely -- treat as 100% off
                continue
            errors.append(abs(candidate - truth) / truth)
        worst = max(errors) if errors else 0.0

        if best is None or worst < best[2]:
            best = (anchor, coefficients, worst)
        if worst <= _TOLERANCE:
            return anchor, coefficients, worst, True

    assert best is not None
    return best[0], best[1], best[2], False


def measured_safe_ceiling(entry: dict) -> int | None:
    unsafe_at = entry.get("unsafeAtSize")
    if unsafe_at is None:
        return None
    below = [s for s in entry["sampleSizes"] if s < unsafe_at]
    return max(below) if below else None


def find_source_file(algorithm_id: str) -> Path | None:
    needle = f'AlgorithmID(rawValue: "{algorithm_id}")'
    # Recursive -- algorithm sources live under per-category subdirectories (`Merge/`, `Quick/`,
    # ...), not flat directly in `Sources/` (mirrors `apply_detected_models.py`'s own fix).
    for path in _SOURCES_DIR.rglob("*.swift"):
        if needle in path.read_text():
            return path
    return None


_SIZE_RANGE_LINE = re.compile(r"^(?P<indent>[ \t]*)sizeRange:\s*\d+\.\.\.\d+,$", re.MULTILINE)


_SIGNIFICANT_DIGITS = 6


def format_double(value: float) -> str:
    # `repr(value)` would round-trip the bridge's full double precision, which is mostly
    # floating-point noise past a handful of digits (e.g. an exact `T(n) = 3n` fit comes back as
    # `3.000000000000001` from sympy's numeric evaluation) -- `%.6g` keeps only the significant
    # digits an empirical curve fit can actually claim.
    if value == 0:
        return "0"
    rounded = float(f"{value:.{_SIGNIFICANT_DIGITS}g}")
    if rounded == int(rounded) and abs(rounded) < 1e15:
        return str(int(rounded))
    return f"{value:.{_SIGNIFICANT_DIGITS}g}"


def insert_growth_model(path: Path, anchor: float, coefficients: list[float], ceiling: int | None):
    text = path.read_text()
    match = _SIZE_RANGE_LINE.search(text)
    if match is None:
        raise ValueError(f"{path}: no `sizeRange: N...M,` line found")

    indent = match.group("indent")
    coefficients_literal = ", ".join(format_double(c) for c in coefficients)
    ceiling_literal = str(ceiling) if ceiling is not None else "nil"
    new_block = (
        f"{indent}growthModel: OperationGrowthModel(\n"
        f"{indent}  anchorSize: {format_double(anchor)}, coefficients: [{coefficients_literal}],\n"
        f"{indent}  measuredSafeCeiling: {ceiling_literal}),")

    # A re-calibration run (recalibrating an algorithm that already has a `growthModel:` field,
    # not the initial bulk pass) needs to *replace* the existing block, not insert a second
    # `growthModel:` argument alongside it -- the naive always-insert-after-`sizeRange:` version
    # of this function silently produced a duplicate-keyword-argument Swift file (a compile
    # error) the first time it was asked to recalibrate a single already-calibrated algorithm
    # (ShoveSort) rather than run once across every algorithm fresh.
    existing_block = re.compile(
        rf"{re.escape(indent)}growthModel: OperationGrowthModel\(\n"
        rf".*?\n{re.escape(indent)}  measuredSafeCeiling: .*?\),",
        re.DOTALL)
    if existing_block.search(text):
        text = existing_block.sub(new_block, text, count=1)
    else:
        # No trailing newline on this block -- `text[match.end():]` already starts with the
        # original sizeRange line's own newline, which becomes this block's terminator.
        text = text[: match.end()] + "\n" + new_block + text[match.end() :]
    path.write_text(text)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help="comma-separated algorithmIDs to process (spot-check)")
    parser.add_argument("--dry-run", action="store_true", help="fit and report, but don't write")
    args = parser.parse_args()

    try:
        urllib.request.urlopen(f"{_BRIDGE_URL}/health", timeout=5)
    except urllib.error.URLError:
        sys.exit(f"bridge not reachable at {_BRIDGE_URL} -- start it with `uv run bridge_server.py`")

    entries = json.loads(_REPORT_PATH.read_text())
    only = set(args.only.split(",")) if args.only else None

    warnings: list[ConvergenceWarning] = []
    order_counts: dict[int, int] = {}
    updated = 0
    for entry in entries:
        algorithm_id = entry["subjectID"].split("+")[0]
        if only is not None and algorithm_id not in only:
            continue

        anchor, coefficients, worst_error, converged = fit_taylor_model(entry)
        if not converged:
            warnings.append(ConvergenceWarning(entry["subjectID"], worst_error))

        order_counts[len(coefficients) - 1] = order_counts.get(len(coefficients) - 1, 0) + 1
        ceiling = measured_safe_ceiling(entry)

        path = find_source_file(algorithm_id)
        if path is None:
            print(f"warning: no source file found for algorithmID {algorithm_id!r}", file=sys.stderr)
            continue

        print(f"{algorithm_id}: order {len(coefficients) - 1}, anchor {anchor:.0f} -> {path.name}")
        if not args.dry_run:
            insert_growth_model(path, anchor, coefficients, ceiling)
            updated += 1

    print(f"\n{updated} file(s) updated. Order distribution: {order_counts}")
    if warnings:
        print(f"\n{len(warnings)} algorithm(s) never hit {_TOLERANCE:.0%} tolerance:")
        for warning in warnings:
            print(f"  {warning}")


if __name__ == "__main__":
    main()
