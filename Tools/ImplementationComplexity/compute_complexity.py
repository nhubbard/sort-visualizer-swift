#!/usr/bin/env python3
"""Computes a McCabe-style cyclomatic complexity score for each algorithm's Swift port and bakes
it into that algorithm's `AlgorithmMetadata(...)` literal as `implementationComplexity: N`.

Dev-tool only, never built into or shipped with the app -- mirrors the shape of
`Tools/GrowthModelCalibration/apply_growth_models.py` (regex-locate an algorithm's metadata
literal, patch a new field into it), but needs no calibration report or external service: the
score is computed directly from each algorithm's own source text.

Measuring only `record(into:)`'s own file would make an algorithm that's a thin wrapper around a
shared template (`QuadSortingTemplate`, `GrailSortingTemplate`, etc. -- see
`Modules/BuiltInAlgorithms/Sources/Templates/`) look artificially simple even when the real
branching lives in the template it calls. So this walks the call graph starting at `record`:
same-file calls to sibling functions (bare `helperName(...)`) and calls into a known template
(`TemplateName.functionName(...)`) both recurse into that callee's own body and add its
complexity, memoized per (file, function name) so a template shared by many algorithms
(`QuadSortingTemplate` is used by both `QuadSort` and `FluxSort`) is only walked once per run and
so self-recursive helpers (`swapFive` -> `swapSix` -> `swapSeven`...) can't loop forever.

This is a text/regex approximation, not a real Swift parse (no SwiftSyntax dependency, consistent
with the rest of this pipeline's tooling style):
- Comments and string literals are masked to spaces before anything else runs, so a stray "for"
  or "if" in prose/doc-comments/messages never inflates a count.
- Decision points counted per function: `if`, `guard`, `for`, `while`, `catch`, `case`, `where`,
  `&&`, `||`, each +1, plus a baseline of 1 per function (standard McCabe convention) -- ternary
  `?:`
  is deliberately NOT counted, since a bare `?` is indistinguishable from Optional-type/chaining
  syntax (`Int?`, `foo?.bar`) by regex alone and those vastly outnumber real ternaries here.
- A same-file call is only followed if the callee name is actually a function defined in that
  same file (arbitrary calls like `pow(...)`/`AuxBuffer(...)` are never mistaken for local
  helpers); a qualified call is only followed if the receiver is one of the known template types.
  Everything else (engine.compare/.swap/.setValue, Foundation calls, ...) is intentionally never
  walked into -- this measures the algorithm's own port plus the shared sorting-template code it
  actually calls, not `RecordingEngine`/Foundation.

Usage:
    uv run compute_complexity.py [--only algorithmID,algorithmID,...] [--dry-run]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

_SOURCES_DIR = Path(__file__).parents[2] / "Modules" / "BuiltInAlgorithms" / "Sources"
_TEMPLATES_DIR = _SOURCES_DIR / "Templates"

_TEMPLATE_TYPE_NAMES = [
    "UnstableGrailSortingTemplate",
    "BinaryQuickSortingTemplate",
    "ShatterSortingTemplate",
    "TwinSortingTemplate",
    "QuadSortingTemplate",
    "PDQSortingTemplate",
    "GrailSortingTemplate",
]


# -- Comment/string masking -- keeps text length and line structure intact so every later regex's
# -- match positions stay valid, just blanks out anything that isn't real code. ------------------


def mask_comments_and_strings(text: str) -> str:
    out = list(text)
    n = len(text)
    i = 0

    def blank(lo: int, hi: int) -> None:
        for k in range(lo, hi):
            if out[k] != "\n":
                out[k] = " "

    while i < n:
        if text[i : i + 2] == "//":
            j = text.find("\n", i)
            j = n if j == -1 else j
            blank(i, j)
            i = j
        elif text[i : i + 2] == "/*":
            j = text.find("*/", i + 2)
            j = n if j == -1 else j + 2
            blank(i, j)
            i = j
        elif text[i : i + 3] == '"""':
            j = text.find('"""', i + 3)
            j = n if j == -1 else j + 3
            blank(i, j)
            i = j
        elif text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
            blank(i, j)
            i = j
        else:
            i += 1
    return "".join(out)


# -- Function extraction: name -> list of "own" body texts. Several algorithms (HanoiSort is the
# -- extreme case) define every helper as a local function nested directly inside `record(into:)`
# -- rather than as sibling private funcs in the file -- a flat, non-scope-aware scan would count
# -- a nested function's decision points twice: once inline, as plain substring of its enclosing
# -- function's own body text, and once again when the call-graph walk below separately resolves
# -- a call to it -- and the double-counting compounds further if that nested function is called
# -- more than once. So this walks the file recursively: each function's registered "own" body has
# -- every *direct* child function's span blanked out (transitively excluding grandchildren too,
# -- since they're nested inside the child's own span), and each child is registered separately
# -- under its own name for the call-graph walk to find. A name can still repeat across unrelated
# -- entries (overloads, or same-named locals nested in different outer functions) -- both are
# -- folded together, a known approximation for a metric that's already only approximate. --------

_FUNC_DEF = re.compile(r"\bfunc\s+(\w+)\s*(?:<[^>]*>)?\s*\(")


def _parse_functions(
    text: str, start: int, end: int, functions: dict[str, list[str]]
) -> list[tuple[int, int]]:
    """Registers every `func` definition whose keyword lies in text[start:end) -- and, via
    recursion, every function nested inside one of those -- into `functions`. Returns the
    (span_start, span_end) of each function found directly at this level (not descendants), so
    the caller can blank those spans out of its own counted body text.
    """
    spans: list[tuple[int, int]] = []
    pos = start
    while True:
        match = _FUNC_DEF.search(text, pos, end)
        if match is None:
            return spans
        name = match.group(1)

        depth = 1
        i = match.end()
        while depth > 0 and i < end:
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
            i += 1
        params_end = i

        brace_pos = text.find("{", params_end, end)
        if brace_pos == -1:
            pos = match.end()  # a protocol requirement / bodyless reference -- not a definition
            continue

        depth = 1
        i = brace_pos + 1
        while depth > 0 and i < end:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        body_start, body_end = brace_pos + 1, i - 1

        child_spans = _parse_functions(text, body_start, body_end, functions)
        own_body = list(text[body_start:body_end])
        for child_start, child_end in child_spans:
            for k in range(child_start - body_start, child_end - body_start):
                if own_body[k] != "\n":
                    own_body[k] = " "
        functions.setdefault(name, []).append("".join(own_body))

        spans.append((match.start(), i))
        pos = i


def extract_functions(masked_text: str) -> dict[str, list[str]]:
    functions: dict[str, list[str]] = {}
    _parse_functions(masked_text, 0, len(masked_text), functions)
    return functions


# -- Per-function local complexity and outgoing-call resolution -----------------------------------

_DECISION_KEYWORDS = re.compile(r"\b(if|guard|for|while|catch|case|where)\b")
_BARE_CALL = re.compile(r"(?<!\.)\b([A-Za-z_]\w*)\s*\(")
_TEMPLATE_CALL = re.compile(
    r"\b(" + "|".join(re.escape(name) for name in _TEMPLATE_TYPE_NAMES) + r")\.(\w+)\s*\(")


def local_complexity(body: str) -> int:
    count = len(_DECISION_KEYWORDS.findall(body))
    count += body.count("&&")
    count += body.count("||")
    return 1 + count


def resolve_calls(body: str, current_file: Path, local_functions: dict[str, list[str]]
                   ) -> list[tuple[Path, str]]:
    # A `set`, not a list: calling the same helper 3 times over doesn't make the caller 3x as
    # complex to reason about -- it's the same branching, read once. Each distinct callee
    # contributes its complexity to a given caller exactly once, however many times it's invoked.
    calls: set[tuple[Path, str]] = set()
    for match in _BARE_CALL.finditer(body):
        name = match.group(1)
        if name in local_functions:
            calls.add((current_file, name))
    for match in _TEMPLATE_CALL.finditer(body):
        type_name, func_name = match.group(1), match.group(2)
        calls.add((_TEMPLATES_DIR / f"{type_name}.swift", func_name))
    return list(calls)


# -- File-level cache + recursive, memoized complexity walk ---------------------------------------

_FileFunctions = dict[str, list[str]]


def get_functions(path: Path, file_cache: dict[Path, _FileFunctions]) -> _FileFunctions:
    cached = file_cache.get(path)
    if cached is not None:
        return cached
    masked = mask_comments_and_strings(path.read_text())
    parsed = extract_functions(masked)
    file_cache[path] = parsed
    return parsed


def complexity_of(
    file: Path, name: str, file_cache: dict[Path, _FileFunctions],
    memo: dict[tuple[Path, str], int], visiting: set[tuple[Path, str]]
) -> int:
    key = (file, name)
    if key in memo:
        return memo[key]
    if key in visiting:
        return 0  # cycle guard -- a recursive helper chain contributes 0 on the repeat edge

    visiting.add(key)
    functions = get_functions(file, file_cache)
    total = 0
    for body in functions.get(name, []):
        total += local_complexity(body)
        for callee_file, callee_name in resolve_calls(body, file, functions):
            total += complexity_of(callee_file, callee_name, file_cache, memo, visiting)
    visiting.discard(key)
    memo[key] = total
    return total


# -- Algorithm discovery + metadata literal patching -----------------------------------------------

_ALGORITHM_ID = re.compile(r'AlgorithmID\(rawValue:\s*"([^"]+)"\)')


def find_algorithm_files() -> list[Path]:
    files = []
    for path in _SOURCES_DIR.rglob("*.swift"):
        if _TEMPLATES_DIR in path.parents:
            continue
        if _ALGORITHM_ID.search(path.read_text()):
            files.append(path)
    return sorted(files)


_STABLE_LINE = re.compile(r"^(?P<indent>[ \t]*)stable:\s*(?:true|false),$", re.MULTILINE)
_COMPLEXITY_LINE = re.compile(r"^(?P<indent>[ \t]*)implementationComplexity:\s*\d+,$", re.MULTILINE)


def insert_or_update_complexity(path: Path, value: int) -> None:
    text = path.read_text()

    existing = _COMPLEXITY_LINE.search(text)
    if existing is not None:
        indent = existing.group("indent")
        text = text[: existing.start()] + f"{indent}implementationComplexity: {value}," + text[existing.end() :]
        path.write_text(text)
        return

    match = _STABLE_LINE.search(text)
    if match is None:
        raise ValueError(f"{path}: no `stable: true/false,` line found")
    indent = match.group("indent")
    text = text[: match.start()] + f"{indent}implementationComplexity: {value},\n" + text[match.start() :]
    path.write_text(text)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help="comma-separated algorithmIDs to process (spot-check)")
    parser.add_argument("--dry-run", action="store_true", help="compute and report, but don't write")
    args = parser.parse_args()

    only = set(args.only.split(",")) if args.only else None

    file_cache: dict[Path, _FileFunctions] = {}
    memo: dict[tuple[Path, str], int] = {}
    visiting: set[tuple[Path, str]] = set()

    updated = 0
    for path in find_algorithm_files():
        match = _ALGORITHM_ID.search(path.read_text())
        assert match is not None
        algorithm_id = match.group(1)
        if only is not None and algorithm_id not in only:
            continue

        score = complexity_of(path, "record", file_cache, memo, visiting)
        print(f"{algorithm_id}: {score} -> {path.relative_to(_SOURCES_DIR)}")
        if not args.dry_run:
            insert_or_update_complexity(path, score)
            updated += 1

    if not args.dry_run:
        print(f"\n{updated} file(s) updated.")


if __name__ == "__main__":
    main()
