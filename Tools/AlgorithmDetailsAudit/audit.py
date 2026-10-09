#!/usr/bin/env python3
"""Check every bundled algorithm description against the prose contract."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DETAILS = ROOT / "App/Resources/AlgorithmDetails"
SOURCES = ROOT / "Modules/BuiltInAlgorithms/Sources"
ID_RE = re.compile(r'AlgorithmID\(rawValue:\s*"([^"]+)"\)')
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
BAD_WORDS = re.compile(
    r"\b(?:delve|landscape|groundbreaking|seamless|crucial|showcases|highlights|"
    r"you|your|we|our|codebase)\b", re.IGNORECASE
)
SELF_REFERENCE = re.compile(
    r"\b(?:the app|this app|app implementation|app's implementation|"
    r"reference examples|native implementation)\b", re.IGNORECASE
)
CONTRACTION = re.compile(r"\b(?:it's|doesn't|can't|won't|isn't|aren't|didn't|wouldn't|shouldn't)\b", re.IGNORECASE)
BLOCK_MARKUP = re.compile(r"(?m)^\s*(?:#{1,6}\s|[-*+]\s|\d+\.\s|>\s|```|~~~|---+$)")
PROGRAMMING_OPERATOR = re.compile(r"\b[nmkd]\s*(?:\^|\*|/)\s*(?:[nmkd]|\d)")


def algorithm_ids() -> set[str]:
    ids: set[str] = set()
    for path in SOURCES.rglob("*.swift"):
        if "Shuffles" in path.parts or "Templates" in path.parts:
            continue
        match = ID_RE.search(path.read_text())
        if match:
            ids.add(match.group(1))
    return ids


def check_description(path: Path, *, scaffold: bool) -> list[str]:
    text = path.read_text()
    problems: list[str] = []
    if not text.strip():
        problems.append("empty description")
    if not scaffold and len(re.findall(r"\b[\w-]+\b", text)) < 100:
        problems.append("fewer than 100 words")
    if BLOCK_MARKUP.search(text):
        problems.append("block Markdown")
    if re.search(r"<[^>]+>|!\[|\]\[|`", text):
        problems.append("unsupported inline Markdown or HTML")
    if "—" in text:
        problems.append("em dash")
    if "?" in text:
        problems.append("question mark")
    if any(line.rstrip() != line for line in text.splitlines()):
        problems.append("trailing whitespace")
    for name, expression in (("prohibited wording", BAD_WORDS),
                             ("self-reference", SELF_REFERENCE),
                             ("contraction", CONTRACTION)):
        if expression.search(text):
            problems.append(name)
    for _, url in LINK_RE.findall(text):
        if not url.startswith("https://en.wikipedia.org/wiki/"):
            problems.append("non-Wikipedia link")
    if text.count("*") % 2:
        problems.append("unbalanced emphasis")
    if text.count("\u201c") != text.count("\u201d"):
        problems.append("unbalanced quotation marks")
    if text.count('"') % 2:
        problems.append("unbalanced straight quotation marks")
    prose_without_links = LINK_RE.sub(r"\1", text)
    if PROGRAMMING_OPERATOR.search(prose_without_links):
        problems.append("programming-style formula operator")
    return problems


def main() -> int:
    ids = algorithm_ids()
    descriptions = {path.parent.name: path for path in DETAILS.glob("*/description.md")}
    errors: list[str] = []
    for missing in sorted(ids - descriptions.keys()):
        errors.append(f"{missing}: missing description")
    for extra in sorted(descriptions.keys() - ids - {"template"}):
        errors.append(f"{extra}: no matching built-in algorithm")
    for name, path in sorted(descriptions.items()):
        for problem in check_description(path, scaffold=name == "template"):
            errors.append(f"{name}: {problem}")
    print(f"Checked {len(ids)} algorithms and {len(descriptions)} descriptions")
    for error in errors:
        print(error)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
