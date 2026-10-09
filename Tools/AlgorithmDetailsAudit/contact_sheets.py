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
    parser.add_argument("--equations", action="store_true",
                        help="review 320-point equation captures instead of full detail pages")
    parser.add_argument("--narrow", action="store_true",
                        help="review 360-point full-detail captures instead of 900-point pages")
    parser.add_argument("--additional-export", action="append", type=Path, default=[],
                        help="merge a second result export when corpus shards ran separately")
    args = parser.parse_args()
    if sum((args.growth, args.compact_bigo, args.equations, args.narrow)) > 1:
        parser.error("--growth, --compact-bigo, --equations, and --narrow are mutually exclusive")
    if args.expected_count < 1:
        parser.error("--expected-count must be positive")
    args.output.mkdir(parents=True, exist_ok=True)
    tiles = args.output / "tiles"
    tiles.mkdir(exist_ok=True)

    by_kind: dict[str, list[tuple[int, Path]]] = defaultdict(list)
    captured: dict[str, dict[int, str]] = defaultdict(dict)
    records: list[tuple[int, str, str, Path, bool]] = []
    for exported in [args.exported, *args.additional_export]:
        for test in json.loads((exported / "manifest.json").read_text()):
            # Full class runs may include the two-page smoke case as well as the eight
            # exhaustive shards. Keep exactly one capture for each corpus page.
            if test.get("testIdentifier", "").endswith("/testSmoke()"):
                continue
            for attachment in test["attachments"]:
                name = attachment["suggestedHumanReadableName"]
                if args.growth:
                    pattern = r"growth-360-(\d{3})-(.+)_\d+_[A-Fa-f0-9-]+\.png$"
                elif args.compact_bigo:
                    pattern = r"compact-bigo-360-(\d{3})-(.+)_\d+_[A-Fa-f0-9-]+\.png$"
                elif args.equations:
                    pattern = r"equations-320-(\d{3})-(.+)_\d+_[A-Fa-f0-9-]+\.png$"
                elif args.narrow:
                    pattern = r"narrow-(\d{3})-(.+)-(top|charts|expanded)_"
                else:
                    pattern = r"(\d{3})-(.+)-(top|charts|expanded)_"
                match = re.match(pattern, name)
                if not match:
                    continue
                if args.growth or args.compact_bigo or args.equations:
                    number, algorithm_id = match.groups()
                    kind = "growth" if args.growth else "compact-bigo" if args.compact_bigo else "equations"
                else:
                    number, algorithm_id, kind = match.groups()
                page = int(number)
                if page in captured[kind]:
                    raise ValueError(f"duplicate {kind} screenshot for page {page}")
                captured[kind][page] = algorithm_id
                source = exported / attachment["exportedFileName"]
                records.append((page, algorithm_id, kind, source,
                                attachment.get("deviceName") == "My Mac"))

    expected_pages = set(range(1, args.expected_count + 1))
    expected_kinds = ({"growth"} if args.growth else {"compact-bigo"}
                      if args.compact_bigo else {"equations"}
                      if args.equations else {"top", "charts", "expanded"})
    if set(captured) != expected_kinds:
        raise ValueError(f"missing screenshot states: {set(captured)}")
    for kind, pages in captured.items():
        if set(pages) != expected_pages:
            raise ValueError(
                f"{kind}: missing {sorted(expected_pages - set(pages))}; "
                f"unexpected {sorted(set(pages) - expected_pages)}"
            )
        if not args.growth and not args.compact_bigo and not args.equations and pages != captured["top"]:
            raise ValueError(f"{kind}: algorithm IDs do not match top screenshots")
        if len(set(pages.values())) != args.expected_count:
            raise ValueError(f"{kind}: algorithm IDs are repeated across pages")

    for page, algorithm_id, kind, source, is_catalyst in records:
        tile = tiles / f"{page:03d}-{algorithm_id}-{kind}.png"
        if args.narrow and kind == "expanded" and is_catalyst:
            crop = ["-gravity", "north", "-crop", "1400x2000+0+0", "+repage"]
        elif args.equations:
            crop = ["-gravity", "north", "-crop", "850x1500+0+0", "+repage"]
        elif args.growth or args.compact_bigo or (args.narrow and kind != "expanded"):
            crop = ["-gravity", "north", "-crop", "850x1100+0+0", "+repage"]
        else:
            crop = []
        tile_size = "300x530" if args.equations else "300x430"
        subprocess.run(
            ["magick", str(source), "-auto-orient", *crop, "-resize", tile_size,
             "-background", "white", "-gravity", "center", "-extent", tile_size,
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
