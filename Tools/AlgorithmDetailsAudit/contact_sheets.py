#!/usr/bin/env python3
"""Make reviewable contact sheets from AlgorithmDetailCorpusUITests attachments.

Export first with ``xcrun xcresulttool export attachments --path RESULT.xcresult
--output-path EXPORTED``. Then run this script with EXPORTED and an output directory.
ImageMagick's ``magick`` command is required. All sheets are review artifacts; the source
screenshots and the xcresult bundle remain the full-resolution evidence.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("exported", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--expected-count", type=int, default=196,
                        help="number of algorithm pages required in each screenshot state")
    args = parser.parse_args()
    if args.expected_count < 1:
        parser.error("--expected-count must be positive")
    args.output.mkdir(parents=True, exist_ok=True)
    tiles = args.output / "tiles"
    tiles.mkdir(exist_ok=True)

    by_kind: dict[str, list[tuple[int, Path]]] = defaultdict(list)
    captured: dict[str, dict[int, str]] = defaultdict(dict)
    records: list[tuple[int, str, str, Path]] = []
    for test in json.loads((args.exported / "manifest.json").read_text()):
        for attachment in test["attachments"]:
            name = attachment["suggestedHumanReadableName"]
            match = re.match(r"(\d{3})-(.+)-(top|charts|expanded)_", name)
            if not match:
                continue
            number, algorithm_id, kind = match.groups()
            page = int(number)
            if page in captured[kind]:
                raise ValueError(f"duplicate {kind} screenshot for page {page}")
            captured[kind][page] = algorithm_id
            source = args.exported / attachment["exportedFileName"]
            records.append((page, algorithm_id, kind, source))

    expected_pages = set(range(1, args.expected_count + 1))
    if set(captured) != {"top", "charts", "expanded"}:
        raise ValueError(f"missing screenshot states: {set(captured)}")
    for kind, pages in captured.items():
        if set(pages) != expected_pages:
            raise ValueError(
                f"{kind}: missing {sorted(expected_pages - set(pages))}; "
                f"unexpected {sorted(set(pages) - expected_pages)}"
            )
        if pages != captured["top"]:
            raise ValueError(f"{kind}: algorithm IDs do not match top screenshots")
        if len(set(pages.values())) != args.expected_count:
            raise ValueError(f"{kind}: algorithm IDs are repeated across pages")

    for page, algorithm_id, kind, source in records:
        tile = tiles / f"{page:03d}-{algorithm_id}-{kind}.png"
        subprocess.run(
            ["magick", str(source), "-auto-orient", "-resize", "300x430",
             "-background", "white", "-gravity", "center", "-extent", "300x430",
             "-gravity", "south", "-splice", "0x24", "-fill", "black",
             "-font", "/System/Library/Fonts/Supplemental/Arial.ttf",
             "-pointsize", "12", "-annotate", "+0+4",
             f"{page:03d} {algorithm_id}", "-strip", str(tile)],
            check=True,
        )
        by_kind[kind].append((page, tile))

    for kind, numbered in sorted(by_kind.items()):
        ordered = [path for _, path in sorted(numbered)]
        for page, start in enumerate(range(0, len(ordered), 20), start=1):
            destination = args.output / f"{kind}-{page:02d}.png"
            subprocess.run(
                ["magick", "montage", *map(str, ordered[start:start + 20]),
                 "-font", "/System/Library/Fonts/Supplemental/Arial.ttf",
                 "-tile", "4x5", "-geometry", "+4+4", str(destination)],
                check=True,
            )
    print("Created", ", ".join(f"{kind}: {len(items)}" for kind, items in sorted(by_kind.items())))


if __name__ == "__main__":
    main()
