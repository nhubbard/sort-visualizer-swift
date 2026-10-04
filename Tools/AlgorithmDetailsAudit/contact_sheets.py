#!/usr/bin/env python3
"""Make reviewable contact sheets from detail corpus and narrow chart UI audits.

Export first with ``xcrun xcresulttool export attachments --path RESULT.xcresult
--output-path EXPORTED``. Then run this script with EXPORTED and an output directory.
Pass ``--growth`` for GrowthModelNarrowCorpusUITests and ``--additional-export`` when shards
are in separate result bundles. ImageMagick's ``magick`` command is
required. All sheets are review artifacts; the source screenshots and the xcresult bundle
remain the full-resolution evidence.
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
    parser.add_argument("--growth", action="store_true",
                        help="review 360-point Growth Model captures instead of full detail pages")
    parser.add_argument("--compact-bigo", action="store_true",
                        help="review 360-point compact Big-O captures instead of full detail pages")
    parser.add_argument("--additional-export", action="append", type=Path, default=[],
                        help="merge a second result export when corpus shards ran separately")
    args = parser.parse_args()
    if args.growth and args.compact_bigo:
        parser.error("--growth and --compact-bigo are mutually exclusive")
    if args.expected_count < 1:
        parser.error("--expected-count must be positive")
    args.output.mkdir(parents=True, exist_ok=True)
    tiles = args.output / "tiles"
    tiles.mkdir(exist_ok=True)

    by_kind: dict[str, list[tuple[int, Path]]] = defaultdict(list)
    captured: dict[str, dict[int, str]] = defaultdict(dict)
    records: list[tuple[int, str, str, Path]] = []
    for exported in [args.exported, *args.additional_export]:
        for test in json.loads((exported / "manifest.json").read_text()):
            for attachment in test["attachments"]:
                name = attachment["suggestedHumanReadableName"]
                pattern = (r"growth-360-(\d{3})-(.+)_\d+_[A-Fa-f0-9-]+\.png$" if args.growth
                           else r"compact-bigo-360-(\d{3})-(.+)_\d+_[A-Fa-f0-9-]+\.png$"
                           if args.compact_bigo else r"(\d{3})-(.+)-(top|charts|expanded)_")
                match = re.match(pattern, name)
                if not match:
                    continue
                if args.growth or args.compact_bigo:
                    number, algorithm_id = match.groups()
                    kind = "growth" if args.growth else "compact-bigo"
                else:
                    number, algorithm_id, kind = match.groups()
                page = int(number)
                if page in captured[kind]:
                    raise ValueError(f"duplicate {kind} screenshot for page {page}")
                captured[kind][page] = algorithm_id
                source = exported / attachment["exportedFileName"]
                records.append((page, algorithm_id, kind, source))

    expected_pages = set(range(1, args.expected_count + 1))
    expected_kinds = ({"growth"} if args.growth else {"compact-bigo"}
                      if args.compact_bigo else {"top", "charts", "expanded"})
    if set(captured) != expected_kinds:
        raise ValueError(f"missing screenshot states: {set(captured)}")
    for kind, pages in captured.items():
        if set(pages) != expected_pages:
            raise ValueError(
                f"{kind}: missing {sorted(expected_pages - set(pages))}; "
                f"unexpected {sorted(set(pages) - expected_pages)}"
            )
        if not args.growth and not args.compact_bigo and pages != captured["top"]:
            raise ValueError(f"{kind}: algorithm IDs do not match top screenshots")
        if len(set(pages.values())) != args.expected_count:
            raise ValueError(f"{kind}: algorithm IDs are repeated across pages")

    for page, algorithm_id, kind, source in records:
        tile = tiles / f"{page:03d}-{algorithm_id}-{kind}.png"
        crop = (["-gravity", "north", "-crop", "850x1100+0+0", "+repage"]
                if args.growth or args.compact_bigo else [])
        subprocess.run(
            ["magick", str(source), "-auto-orient", *crop, "-resize", "300x430",
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
