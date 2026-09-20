#!/usr/bin/env python3
"""Fail when built-in Swift algorithms read RecordingEngine.values directly.

The engine's setter is private, so live-array writes already require an engine method.
Reads must use readValue(at:), readValues(in:), or readAllValues() so they enter the tape.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2] / "Modules/BuiltInAlgorithms/Sources"
DIRECT_READ = re.compile(r"\bengine\s*\.\s*values\b")


def code_lines(source: str):
    """Yield line numbers and text after removing Swift comments and string literals."""
    block = False
    string = False
    escaped = False
    line = 1
    cleaned = []
    i = 0
    while i < len(source):
        char = source[i]
        next_char = source[i + 1] if i + 1 < len(source) else ""
        if char == "\n":
            yield line, "".join(cleaned)
            line += 1
            cleaned = []
            if not block:
                string = False
            escaped = False
            i += 1
            continue
        if block:
            if char == "*" and next_char == "/":
                block = False
                i += 2
            else:
                i += 1
            continue
        if string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                string = False
            i += 1
            continue
        if char == "/" and next_char == "/":
            while i < len(source) and source[i] != "\n":
                i += 1
            continue
        if char == "/" and next_char == "*":
            block = True
            i += 2
            continue
        if char == '"':
            string = True
            i += 1
            continue
        cleaned.append(char)
        i += 1
    if cleaned:
        yield line, "".join(cleaned)


def main() -> int:
    problems = []
    for path in sorted(ROOT.rglob("*.swift")):
        for line, code in code_lines(path.read_text()):
            if DIRECT_READ.search(code):
                problems.append(f"{path}:{line}: direct engine.values read")
    for problem in problems:
        print(problem)
    print(f"Checked {len(list(ROOT.rglob('*.swift')))} Swift sources; {len(problems)} direct reads.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
