#!/usr/bin/env python3
# /// script
# dependencies = ["tree-sitter", "tree-sitter-c"]
# ///
"""Flags `App/Resources/AlgorithmDetails/<id>/<id>.c` reference implementations that look
oversimplified relative to the real algorithm, by comparing a McCabe-style complexity score
against the live Swift port's own `implementationComplexity` (`Tools/ImplementationComplexity`).

Dev-tool only, diagnostic -- this does NOT feed back into anything shipped. It exists because a
manual spot-check (FluxSort, QuadSort) found the "Implementations" tab's reference C/Python/etc.
samples are hand-authored per algorithm with wildly inconsistent fidelity: some (PDQBranchedSort)
are complete, faithful ports; others (FluxSort, QuadSort) are simplified teaching demos that share
only the algorithm's name and a superficial resemblance. Every algorithm's 10 per-language files
are 1:1 translations of each other (confirmed: FluxSort's .py is a line-by-line mirror of its .c),
so auditing just the .c file per algorithm stands in for all 10.

Every reference file scaffolds from `App/Resources/AlgorithmDetails/template/template.c`, which
fixes the entry point's name to `sort(int arr[], int n)` -- the walk always starts there.

This is a *ratio*, not an absolute judgment: the Swift port's own complexity includes
`RecordingEngine` instrumentation overhead (`engine.compare`/`.setValue` calls, aux-array
bookkeeping) that a plain reference implementation never has, so even a fully faithful reference
is expected to score meaningfully lower than its Swift counterpart -- the useful signal is
*relative* standing across all 180 algorithms, not any single ratio value in isolation.

Usage:
    uv run audit_fidelity.py [--only algorithmID,algorithmID,...] [--limit N]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import tree_sitter_c as tsc
from tree_sitter import Language, Node, Parser

_DETAILS_DIR = Path(__file__).parents[2] / "App" / "Resources" / "AlgorithmDetails"
_SOURCES_DIR = Path(__file__).parents[2] / "Modules" / "BuiltInAlgorithms" / "Sources"

_C_LANGUAGE = Language(tsc.language())

_DECISION_TYPES = {
    "if_statement", "for_statement", "while_statement", "do_statement", "conditional_expression"
}
_BOOLEAN_OPERATORS = {"&&", "||"}


def parse_c(source: bytes) -> Node:
    parser = Parser(_C_LANGUAGE)
    return parser.parse(source).root_node


def find_function_definitions(root: Node) -> dict[str, list[Node]]:
    """All `function_definition` nodes in the file, keyed by name. C has no overloading and no
    real nested functions, so this is a flat top-level walk -- unlike the Swift-side tool, no
    scope-aware blanking is needed."""
    functions: dict[str, list[Node]] = {}

    def declarator_name(node: Node) -> str | None:
        # `function_declarator` is the direct child holding the name, but pointer/array return
        # types wrap it in extra declarator layers (`pointer_declarator`, etc.) -- search down for
        # the first `function_declarator`, then take its own first `identifier` child (not a
        # deeper one, which would belong to a function-pointer parameter instead).
        target = node if node.type == "function_declarator" else None
        if target is None:
            for child in node.children:
                found = declarator_name(child)
                if found is not None:
                    return found
            return None
        for child in target.children:
            if child.type == "identifier":
                return child.text.decode()
        return None

    def visit(node: Node) -> None:
        if node.type == "function_definition":
            name = declarator_name(node)
            if name is not None:
                functions.setdefault(name, []).append(node)
        for child in node.children:
            visit(child)

    visit(root)
    return functions


def local_complexity(node: Node) -> int:
    count = 0

    def visit(n: Node) -> None:
        if n.type in _DECISION_TYPES:
            count_ref[0] += 1
        elif n.type == "case_statement" and n.children and n.children[0].type == "case":
            count_ref[0] += 1
        elif n.type == "binary_expression":
            for child in n.children:
                if child.type in _BOOLEAN_OPERATORS:
                    count_ref[0] += 1
        for child in n.children:
            visit(child)

    count_ref = [count]
    visit(node)
    return 1 + count_ref[0]


def resolve_calls(node: Node, local_functions: dict[str, list[Node]]) -> set[str]:
    calls: set[str] = set()

    def visit(n: Node) -> None:
        if n.type == "call_expression":
            callee = n.children[0] if n.children else None
            if callee is not None and callee.type == "identifier":
                name = callee.text.decode()
                if name in local_functions:
                    calls.add(name)
        for child in n.children:
            visit(child)

    visit(node)
    return calls


def complexity_of(
    name: str, functions: dict[str, list[Node]], memo: dict[str, int], visiting: set[str]
) -> int:
    if name in memo:
        return memo[name]
    if name in visiting:
        return 0
    visiting.add(name)

    bodies = functions.get(name, [])
    total = sum(local_complexity(body) for body in bodies)
    calls: set[str] = set()
    for body in bodies:
        calls.update(resolve_calls(body, functions))
    for callee in calls:
        total += complexity_of(callee, functions, memo, visiting)

    visiting.discard(name)
    memo[name] = total
    return total


def reference_complexity(algorithm_id: str) -> tuple[int, int] | None:
    """Returns (complexity, line count), or `None` if there's no `sort` entry point to walk from
    (either no raw `.c` source at all, or a template stub that was never filled in)."""
    path = _DETAILS_DIR / algorithm_id / f"{algorithm_id}.c"
    if not path.exists():
        return None
    text = path.read_text()
    root = parse_c(text.encode())
    functions = find_function_definitions(root)
    if "sort" not in functions:
        return None
    complexity = complexity_of("sort", functions, {}, set())
    line_count = len([line for line in text.splitlines() if line.strip()])
    return complexity, line_count


_IMPLEMENTATION_COMPLEXITY = re.compile(r"implementationComplexity:\s*(\d+)")
_ALGORITHM_ID = re.compile(r'AlgorithmID\(rawValue:\s*"([^"]+)"\)')


def swift_complexities() -> dict[str, int]:
    result: dict[str, int] = {}
    for path in _SOURCES_DIR.rglob("*.swift"):
        if "Templates" in path.parts:
            continue
        text = path.read_text()
        id_match = _ALGORITHM_ID.search(text)
        complexity_match = _IMPLEMENTATION_COMPLEXITY.search(text)
        if id_match and complexity_match:
            result[id_match.group(1)] = int(complexity_match.group(1))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help="comma-separated algorithmIDs to process (spot-check)")
    parser.add_argument("--limit", type=int, help="only print the N lowest-ratio rows")
    args = parser.parse_args()
    only = set(args.only.split(",")) if args.only else None

    swift_scores = swift_complexities()
    rows: list[tuple[float, str, int, int, int]] = []
    skipped: list[str] = []

    for algorithm_id, swift_score in sorted(swift_scores.items()):
        if only is not None and algorithm_id not in only:
            continue
        result = reference_complexity(algorithm_id)
        if result is None:
            skipped.append(algorithm_id)
            continue
        c_complexity, line_count = result
        ratio = c_complexity / max(swift_score, 1)
        rows.append((ratio, algorithm_id, c_complexity, swift_score, line_count))

    rows.sort(key=lambda row: row[0])
    limited = rows[: args.limit] if args.limit else rows

    print(f"{'ratio':>7}  {'c':>5}  {'swift':>6}  {'c-lines':>7}  algorithmID")
    for ratio, algorithm_id, c_complexity, swift_score, line_count in limited:
        print(f"{ratio:7.3f}  {c_complexity:5d}  {swift_score:6d}  {line_count:7d}  {algorithm_id}")

    if skipped:
        print(f"\n{len(skipped)} algorithm(s) skipped (no `sort` entry point found): "
              f"{', '.join(skipped)}", file=sys.stderr)


if __name__ == "__main__":
    main()
