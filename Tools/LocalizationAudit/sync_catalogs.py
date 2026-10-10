#!/usr/bin/env python3
"""Check or merge compiler-extracted Localizable keys into checked-in catalogs.

Build SortSymphony for an iOS simulator first, then pass the generated
`Sort Symphony.build/Debug-iphonesimulator` directory with --build-dir.
Existing translations are never replaced or removed.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CATALOGS = {
    "SortSymphony": ROOT / "App/Resources/Localizable.xcstrings",
    **{
        target: ROOT / f"Modules/{target}/Resources/Localizable.xcstrings"
        for target in (
            "AlgorithmKit",
            "AudioEngineKit",
            "BuiltInAlgorithms",
            "BuiltInVisualizers",
            "DesignSystemKit",
            "HomeFeature",
            "IntentsKit",
            "MathRenderingKit",
            "SettingsFeature",
            "SettingsKit",
            "SortFeature",
        )
    },
}


def extracted_keys(build_dir: Path, target: str) -> set[str]:
    objects = build_dir / f"{target}.build/Objects-normal/arm64"
    if not objects.is_dir():
        raise FileNotFoundError(f"Missing build output for {target}: {objects}")
    keys: set[str] = set()
    for artifact in objects.glob("*.stringsdata"):
        data = json.loads(artifact.read_text())
        source = data.get("source", "")
        if not source.startswith(str(ROOT) + "/"):
            continue
        for item in data.get("tables", {}).get("Localizable", []):
            keys.add(item["key"])
    return keys


def append_missing(catalog: Path, missing: set[str]) -> None:
    original = catalog.read_text()
    current = json.loads(original)["strings"]
    marker = '\n  },\n  "version"'
    if marker not in original:
        raise ValueError(f"Unexpected catalog layout: {catalog}")
    head, tail = original.split(marker, 1)
    if current:
        closing = head.rfind("}")
        head = head[:closing] + "}," + head[closing + 1 :]
    entries = [
        "    " + json.dumps(key, ensure_ascii=False) + " : {\n\n    }"
        for key in sorted(missing)
    ]
    updated = head + "\n" + ",\n".join(entries) + marker + tail
    json.loads(updated)
    catalog.write_text(updated)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", required=True, type=Path)
    parser.add_argument("--write", action="store_true", help="append missing keys")
    args = parser.parse_args()
    missing_total = 0
    for target, catalog in CATALOGS.items():
        extracted = extracted_keys(args.build_dir, target)
        existing = set(json.loads(catalog.read_text())["strings"])
        missing = extracted - existing
        if missing:
            missing_total += len(missing)
            print(f"{target}: {len(missing)} missing keys")
            if args.write:
                append_missing(catalog, missing)
    if not missing_total:
        print("All compiler-extracted Localizable keys are in source catalogs.")
    return 0 if args.write or not missing_total else 1


if __name__ == "__main__":
    raise SystemExit(main())
