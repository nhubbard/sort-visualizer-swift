#!/usr/bin/env python3
"""Import one locale JSON file into Xcode catalogs and the algorithm archive sources.

Usage: python3 Tools/LocalizationAudit/import_locale.py Translations/es.json
The input is {"locale": "es", "catalogs": {"SortFeature": {"Key": "Value"}},
"descriptions": {"algorithm-id": "Markdown"}}. Existing translations must match.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from sync_catalogs import CATALOGS, ROOT


def import_locale(path: Path, *, check: bool) -> None:
    source = json.loads(path.read_text(encoding="utf-8"))
    locale = source.get("locale")
    if not isinstance(locale, str) or not re.fullmatch(r"[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*", locale) or locale == "en":
        raise ValueError("locale must be a non-English language tag such as es or fr-CA")
    catalogs = source.get("catalogs", {})
    descriptions = source.get("descriptions", {})
    if not isinstance(catalogs, dict) or not isinstance(descriptions, dict):
        raise ValueError("catalogs and descriptions must be objects")
    for target, translations in catalogs.items():
        if target not in CATALOGS or not isinstance(translations, dict):
            raise ValueError(f"unknown target or invalid translations: {target}")
        catalog_path = CATALOGS[target]
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        changed = False
        for key, translated in translations.items():
            if key not in catalog["strings"]:
                raise ValueError(f"{target}: unknown extracted key {key!r}")
            if not isinstance(translated, str) or not translated.strip():
                raise ValueError(f"{target}: empty translation for {key!r}")
            localizations = catalog["strings"][key].setdefault("localizations", {})
            existing = localizations.get(locale, {}).get("stringUnit", {}).get("value")
            if existing is not None and existing != translated:
                raise ValueError(f"{target}: conflicting {locale} translation for {key!r}")
            if existing is None:
                if check:
                    raise ValueError(f"{target}: missing {locale} translation for {key!r}")
                localizations[locale] = {"stringUnit": {"state": "translated", "value": translated}}
                changed = True
        if changed:
            catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    details_root = ROOT / "App/Resources/AlgorithmDetails"
    output = details_root / f"descriptions.{locale}.json"
    existing_descriptions = json.loads(output.read_text(encoding="utf-8")) if output.exists() else {}
    descriptions_changed = False
    for algorithm_id, markdown in descriptions.items():
        if not isinstance(algorithm_id, str) or not (details_root / algorithm_id / "description.md").is_file():
            raise ValueError(f"unknown algorithm description ID: {algorithm_id!r}")
        if not isinstance(markdown, str) or not markdown.strip():
            raise ValueError(f"empty description for {algorithm_id!r}")
        if algorithm_id in existing_descriptions and existing_descriptions[algorithm_id] != markdown:
            raise ValueError(f"conflicting {locale} description for {algorithm_id!r}")
        if algorithm_id not in existing_descriptions and check:
            raise ValueError(f"missing {locale} description for {algorithm_id!r}")
        if algorithm_id not in existing_descriptions:
            descriptions_changed = True
        existing_descriptions[algorithm_id] = markdown
    if descriptions_changed:
        output.write_text(json.dumps(existing_descriptions, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{locale}: {sum(map(len, catalogs.values()))} catalog strings, {len(descriptions)} descriptions verified")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path)
    parser.add_argument("--check", action="store_true", help="verify that the locale is already imported")
    args = parser.parse_args()
    import_locale(args.path, check=args.check)


if __name__ == "__main__":
    main()
