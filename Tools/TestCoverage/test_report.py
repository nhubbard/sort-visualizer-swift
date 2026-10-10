import argparse
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import report as coverage


class CoverageReportTests(unittest.TestCase):
    def test_only_extension_sources_accept_hostless_component_test_target(self):
        component = "AUv3ExtensionComponentTests.xctest"
        self.assertTrue(coverage.valid_coverage_target(
            "App/AUv3Extension/Sources/SortAudioUnitParameterView.swift", component
        ))
        self.assertFalse(coverage.valid_coverage_target(
            "App/Sources/ContentView.swift", component
        ))
        self.assertFalse(coverage.valid_coverage_target(
            "App/AUv3Extension/Sources/SortAudioUnitParameterView.swift", "OtherTests.xctest"
        ))

    def test_changed_production_source_rejects_snapshot(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            manifest = folder / "sources.json"
            manifest.write_text(json.dumps({
                "root": str(coverage.ROOT),
                "sources": {"App/Sources/ContentView.swift": "old-hash"},
            }))
            args = argparse.Namespace(
                manifest=manifest,
                result=[], behavioral_result=[], changed_base=None,
                verify_tests=False, markdown=None, output=folder / "coverage.json",
            )
            with patch.object(coverage, "source_files", return_value={
                "App/Sources/ContentView.swift": "new-hash",
            }):
                with self.assertRaisesRegex(RuntimeError, "sources changed"):
                    coverage.report(args)

    def test_changed_lines_use_uncolored_diff_hunks(self):
        relative = "Modules/SortEngineKit/Sources/ReplayEngine.swift"
        patch_text = (
            f"diff --git a/{relative} b/{relative}\n"
            f"+++ b/{relative}\n"
            "@@ -41,2 +41,3 @@\n"
            "+one\n+two\n+three\n"
        )

        def git(*args):
            if args[0] == "diff":
                self.assertIn("--no-color", args)
                return patch_text
            return ""

        with patch.object(coverage, "git", side_effect=git):
            changed = coverage.changed_source_lines("HEAD", {relative: "hash"})
        self.assertEqual(changed[relative], {41, 42, 43})

    def test_unions_line_identities_and_separates_platforms(self):
        source = str(coverage.ROOT / "Modules/SortEngineKit/Sources/ReplayEngine.swift")
        dependency = str(coverage.ROOT / "Tuist/.build/checkouts/Example/Sources/Other.swift")

        def xccov(*args):
            is_first = "first.xcresult" in args[-1]
            if args[0] == "--report":
                return {
                    "targets": [{
                        "name": "SortEngineKit.framework",
                        "files": [{"path": source, "functions": []}],
                    }]
                }
            rows = [
                {"line": 10, "isExecutable": True, "executionCount": 1},
                {"line": 11, "isExecutable": True, "executionCount": 0 if is_first else 1},
                {"line": 12, "isExecutable": True, "executionCount": 1 if is_first else 0},
            ]
            return {source: rows, dependency: [{"line": 1, "isExecutable": True, "executionCount": 1}]}

        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            (folder / "first.xcresult").mkdir()
            (folder / "second.xcresult").mkdir()
            output = folder / "coverage.json"
            args = argparse.Namespace(
                manifest=None,
                result=[
                    f"ios/first={folder / 'first.xcresult'}",
                    f"catalyst/second={folder / 'second.xcresult'}",
                ],
                behavioral_result=[],
                changed_base=None,
                verify_tests=False,
                markdown=None,
                output=output,
            )
            with patch.object(coverage, "command_json", side_effect=xccov):
                coverage.report(args)
            data = json.loads(output.read_text())

        file = data["files"]["Modules/SortEngineKit/Sources/ReplayEngine.swift"]
        self.assertEqual((file["covered"], file["executable"]), (3, 3))
        self.assertEqual(data["platforms"]["ios"]["covered"], 2)
        self.assertEqual(data["platforms"]["catalyst"]["covered"], 2)
        self.assertEqual(data["excluded"]["nonAppOwnedFiles"], 2)

    def test_missing_archive_fails_instead_of_reporting_zero(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "empty.xcresult"
            path.mkdir()
            args = argparse.Namespace(
                manifest=None,
                result=[f"catalyst/ui={path}"],
                behavioral_result=[],
                changed_base=None,
                verify_tests=False,
                markdown=None,
                output=Path(temporary) / "coverage.json",
            )
            with patch.object(coverage, "command_json", return_value={}):
                with self.assertRaisesRegex(RuntimeError, "no readable coverage archive"):
                    coverage.report(args)

    def test_behavioral_only_result_is_recorded_without_inventing_coverage(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "catalyst-ui.xcresult"
            path.mkdir()
            output = Path(temporary) / "coverage.json"
            args = argparse.Namespace(
                manifest=None,
                result=[],
                behavioral_result=[f"catalyst/ui={path}"],
                changed_base=None,
                verify_tests=False,
                markdown=None,
                output=output,
            )
            with patch.object(coverage, "test_summary", return_value={
                "result": "Passed", "passed": 3, "skipped": 0, "failed": 0,
            }):
                coverage.report(args)
            data = json.loads(output.read_text())
        self.assertIsNone(data["overall"]["percent"])
        self.assertEqual(data["behavioralOnlyResults"]["catalyst/ui"]["passed"], 3)


if __name__ == "__main__":
    unittest.main()
