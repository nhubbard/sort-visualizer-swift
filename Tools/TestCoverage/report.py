#!/usr/bin/env python3
"""Report app-owned source-line coverage from one or more Xcode result bundles.

`xccov`'s top-level percentage includes dependencies and test targets, and adding target
percentages from separate runs counts the same source line more than once. This tool instead
unions executable and covered line *numbers* for each production source file.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PLATFORMS = {"ios", "catalyst"}


def production_target(relative: str) -> str | None:
    if relative.startswith("App/Sources/") and relative.endswith(".swift"):
        return "SortSymphony.app"
    if relative.startswith("App/AUv3Extension/Sources/") and relative.endswith(".swift"):
        return "AUv3Extension"
    parts = relative.split("/")
    if len(parts) >= 4 and parts[0] == "Modules" and parts[2] == "Sources":
        return parts[1]
    return None


def source_files() -> dict[str, str]:
    paths = list((ROOT / "App/Sources").rglob("*.swift"))
    paths += list((ROOT / "App/AUv3Extension/Sources").rglob("*.swift"))
    paths += list((ROOT / "Modules").glob("*/Sources/**/*.swift"))
    return {
        str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(paths)
    }


def command_json(*args: str) -> object:
    result = subprocess.run(
        ["xcrun", "xccov", "view", *args], capture_output=True, text=True, check=False
    )
    if result.returncode:
        raise RuntimeError(f"xccov {' '.join(args)} failed:\n{result.stderr.strip()}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"xccov did not return JSON: {error}") from error


def test_summary(path: Path) -> dict:
    result = subprocess.run(
        ["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(path),
         "--format", "json"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode:
        raise RuntimeError(f"cannot read test summary for {path}: {result.stderr.strip()}")
    summary = json.loads(result.stdout)
    if summary.get("result") != "Passed" or summary.get("failedTests", 0):
        raise RuntimeError(f"test bundle is not passing: {path}")
    return {
        "result": summary["result"],
        "passed": summary.get("passedTests", 0),
        "skipped": summary.get("skippedTests", 0),
        "failed": summary.get("failedTests", 0),
    }


def relative_source(path: str) -> str | None:
    try:
        relative = str(Path(path).resolve().relative_to(ROOT))
    except ValueError:
        return None
    return relative if production_target(relative) else None


def ratio(covered: int, executable: int) -> float | None:
    return round(100 * covered / executable, 2) if executable else None


def percent_label(percent: float | None) -> str:
    return f"{percent}%" if percent is not None else "n/a"


def git(*args: str) -> str:
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, check=True)
    return result.stdout.strip()


def changed_source_lines(base: str, current_sources: dict[str, str]) -> dict[str, set[int]]:
    """Find added/modified working-tree line numbers relative to a Git commit."""
    patch = git("diff", "--no-color", "--no-ext-diff", "--unified=0", base, "--", "App", "Modules")
    changed: dict[str, set[int]] = defaultdict(set)
    current: str | None = None
    for line in patch.splitlines():
        if line.startswith("+++ b/"):
            candidate = line[6:]
            current = candidate if candidate in current_sources else None
        elif current and line.startswith("@@ "):
            match = re.search(r"\+(\d+)(?:,(\d+))?", line)
            if match:
                first = int(match.group(1))
                count = int(match.group(2) or 1)
                changed[current].update(range(first, first + count))
    untracked = git("ls-files", "--others", "--exclude-standard", "--", "App", "Modules")
    for relative in untracked.splitlines():
        if relative in current_sources:
            changed[relative].update(range(1, len((ROOT / relative).read_text().splitlines()) + 1))
    return changed


def snapshot(output: Path) -> None:
    data = {
        "schema": 1,
        "root": str(ROOT),
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "gitRevision": git("rev-parse", "HEAD"),
        "gitDirty": bool(git("status", "--porcelain")),
        "xcodeVersion": subprocess.run(
            ["xcodebuild", "-version"], capture_output=True, text=True, check=True
        ).stdout.strip(),
        "tuistVersion": subprocess.run(
            ["tuist", "version"], capture_output=True, text=True, check=True
        ).stdout.strip(),
        "sources": source_files(),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print(f"Captured {len(data['sources'])} production Swift sources in {output}")


def markdown_report(data: dict) -> str:
    overall = data["overall"]
    lines = [
        "# App-owned coverage",
        "",
        f"Source-line union: **{overall['covered']}/{overall['executable']} "
        f"({percent_label(overall['percent'])})**",
        "",
        f"Source snapshot verified: **{'yes' if data['sourceIdentityVerified'] else 'no'}**. "
        f"Measured result test summaries verified: **{'yes' if data['testResultsVerified'] else 'no'}**.",
        "",
        "Platform totals are separate; the source-line union can include both platform builds.",
        "",
        "## Platforms",
        "",
        "| Platform | Covered | Executable | Percent |",
        "| --- | ---: | ---: | ---: |",
    ]
    for platform, row in data["platforms"].items():
        lines.append(
            f"| {platform} | {row['covered']} | {row['executable']} | {percent_label(row['percent'])} |"
        )
    lines += ["", "## Targets", "", "| Target | Covered | Executable | Percent |", "| --- | ---: | ---: | ---: |"]
    for target, row in data["targets"].items():
        lines.append(
            f"| {target} | {row['covered']} | {row['executable']} | {percent_label(row['percent'])} |"
        )
    lines += ["", "## Largest measured gaps", ""]
    gaps = sorted(
        data["files"].items(),
        key=lambda pair: pair[1]["executable"] - pair[1]["covered"],
        reverse=True,
    )[:20]
    lines += ["| File | Uncovered lines |", "| --- | ---: |"]
    for file, row in gaps:
        lines.append(f"| `{file}` | {row['executable'] - row['covered']} |")
    if data["changedLines"]:
        changed = data["changedLines"]
        lines += [
            "", "## Changed executable lines", "",
            f"{changed['covered']}/{changed['executable']} ({percent_label(changed['percent'])}) "
            f"since `{changed['base']}`; {len(changed['unmeasuredFiles'])} changed source files have no coverage records.",
        ]
    lines += [
        "", "## Unmeasured production sources", "",
        f"{len(data['unmeasuredSources'])} source files have no coverage records. A file here may "
        "contain declarations only, belong to an unrun platform target, or represent a real test gap.",
        f"AUv3 extension files without records: **{len(data['unmeasuredExtensionSources'])}**.",
    ]
    lines += [f"- `{file}`" for file in data["unmeasuredSources"]]
    if data["behavioralOnlyResults"]:
        lines += ["", "## Behavioral-only results", ""]
        for lane, row in data["behavioralOnlyResults"].items():
            lines.append(f"- `{lane}`: {row['passed']} passed, {row['skipped']} skipped; no line coverage attributed")
    return "\n".join(lines) + "\n"


def report(args: argparse.Namespace) -> None:
    current_sources = source_files()
    manifest = None
    if args.manifest:
        manifest = json.loads(args.manifest.read_text())
        if manifest.get("root") != str(ROOT):
            raise RuntimeError("snapshot was made in a different source checkout")
        if manifest.get("sources") != current_sources:
            raise RuntimeError("production sources changed since the coverage snapshot")

    names: set[str] = set()
    line_sets: dict[str, dict[str, set[int]]] = defaultdict(
        lambda: {"executable": set(), "covered": set()}
    )
    lanes: dict[str, dict[str, dict[str, set[int]]]] = {}
    lane_platforms: dict[str, str] = {}
    functions: dict[tuple[str, str, int], dict[str, int]] = {}
    result_paths: dict[str, str] = {}
    behavioral_results: dict[str, dict] = {}
    verified_test_results: dict[str, dict] = {}
    excluded: dict[str, int] = defaultdict(int)

    for specification in args.result + args.behavioral_result:
        if "=" not in specification:
            raise RuntimeError("--result must be PLATFORM/LANE=/absolute/path/to/result.xcresult")
        qualified_lane, raw_path = specification.split("=", 1)
        if "/" not in qualified_lane:
            raise RuntimeError("--result must include ios/ or catalyst/ before the lane name")
        platform, lane = qualified_lane.split("/", 1)
        path = Path(raw_path).resolve()
        if platform not in PLATFORMS or not lane or qualified_lane in names or not path.exists():
            raise RuntimeError(f"duplicate lane, empty lane, or missing result: {specification}")
        if manifest and path.stat().st_mtime < datetime.fromisoformat(manifest["createdAt"]).timestamp():
            raise RuntimeError(f"{qualified_lane} predates the source snapshot: {path}")
        names.add(qualified_lane)
        result_paths[qualified_lane] = str(path)

        if specification in args.behavioral_result:
            behavioral_results[qualified_lane] = test_summary(path)
            continue
        lane_platforms[qualified_lane] = platform
        if args.verify_tests:
            verified_test_results[qualified_lane] = test_summary(path)

        archive = command_json("--archive", "--json", str(path))
        xccov_report = command_json("--report", "--json", str(path))
        if not isinstance(archive, dict) or not archive:
            raise RuntimeError(f"{lane} has no readable coverage archive: {path}")
        if not isinstance(xccov_report, dict) or not xccov_report.get("targets"):
            raise RuntimeError(f"{lane} has no readable coverage report: {path}")

        lane_lines: dict[str, dict[str, set[int]]] = defaultdict(
            lambda: {"executable": set(), "covered": set()}
        )
        file_to_target = {}
        for target in xccov_report["targets"]:
            for file in target.get("files", []):
                relative = relative_source(file["path"])
                if relative:
                    file_to_target[file["path"]] = target["name"]
                    for function in file.get("functions", []):
                        key = (relative, function["name"], function["lineNumber"])
                        state = functions.setdefault(key, {"executions": 0, "lines": 0})
                        state["executions"] += function.get("executionCount", 0)
                        state["lines"] = max(state["lines"], function.get("executableLines", 0))

        for absolute, records in archive.items():
            relative = relative_source(absolute)
            if not relative:
                excluded["nonAppOwnedFiles"] += 1
                continue
            if relative not in current_sources:
                raise RuntimeError(f"coverage source no longer exists: {relative}")
            if absolute not in file_to_target:
                raise RuntimeError(f"archive file is absent from report target mapping: {relative}")
            expected = production_target(relative)
            actual = file_to_target[absolute]
            if not actual.startswith(expected + ".") and actual != expected:
                raise RuntimeError(f"unexpected target for {relative}: {actual}")
            for row in records:
                if row.get("isExecutable"):
                    number = row["line"]
                    lane_lines[relative]["executable"].add(number)
                    if row.get("executionCount", 0) > 0:
                        lane_lines[relative]["covered"].add(number)
        if not lane_lines:
            raise RuntimeError(f"{lane} has no app-owned production source coverage")
        lanes[qualified_lane] = lane_lines
        for relative, row in lane_lines.items():
            line_sets[relative]["executable"].update(row["executable"])
            line_sets[relative]["covered"].update(row["covered"])

    files = {}
    totals: dict[str, dict[str, int]] = defaultdict(lambda: {"covered": 0, "executable": 0})
    for relative, row in sorted(line_sets.items()):
        covered = len(row["covered"])
        executable = len(row["executable"])
        target = production_target(relative)
        assert target is not None
        totals[target]["covered"] += covered
        totals[target]["executable"] += executable
        files[relative] = {
            "target": target,
            "covered": covered,
            "executable": executable,
            "percent": ratio(covered, executable),
            "uncoveredLines": sorted(row["executable"] - row["covered"]),
        }

    summary = {
        target: {**numbers, "percent": ratio(numbers["covered"], numbers["executable"])}
        for target, numbers in sorted(totals.items())
    }
    overall_covered = sum(item["covered"] for item in summary.values())
    overall_executable = sum(item["executable"] for item in summary.values())
    platform_totals = {}
    for platform in sorted(set(lane_platforms.values())):
        platform_files: dict[str, dict[str, set[int]]] = defaultdict(
            lambda: {"executable": set(), "covered": set()}
        )
        for lane, rows in lanes.items():
            if lane_platforms[lane] != platform:
                continue
            for relative, row in rows.items():
                platform_files[relative]["executable"].update(row["executable"])
                platform_files[relative]["covered"].update(row["covered"])
        covered = sum(len(row["covered"]) for row in platform_files.values())
        executable = sum(len(row["executable"]) for row in platform_files.values())
        by_target: dict[str, dict[str, int]] = defaultdict(lambda: {"covered": 0, "executable": 0})
        for relative, row in platform_files.items():
            target = production_target(relative)
            assert target is not None
            by_target[target]["covered"] += len(row["covered"])
            by_target[target]["executable"] += len(row["executable"])
        platform_totals[platform] = {
            "covered": covered,
            "executable": executable,
            "percent": ratio(covered, executable),
            "targets": {
                target: {**numbers, "percent": ratio(numbers["covered"], numbers["executable"])}
                for target, numbers in sorted(by_target.items())
            },
        }

    unmeasured_sources = sorted(set(current_sources) - set(line_sets))
    unmeasured_extension_sources = [
        file for file in unmeasured_sources if file.startswith("App/AUv3Extension/Sources/")
    ]
    changed_line_report = None
    if args.changed_base:
        changed = changed_source_lines(args.changed_base, current_sources)
        executable_changed = {
            (file, number)
            for file, numbers in changed.items()
            for number in numbers & line_sets[file]["executable"]
        }
        covered_changed = {
            (file, number)
            for file, number in executable_changed
            if number in line_sets[file]["covered"]
        }
        changed_line_report = {
            "base": args.changed_base,
            "covered": len(covered_changed),
            "executable": len(executable_changed),
            "percent": ratio(len(covered_changed), len(executable_changed)),
            "uncovered": [
                {"file": file, "line": number}
                for file, number in sorted(executable_changed - covered_changed)
            ],
            "unmeasuredFiles": sorted(file for file in changed if file in unmeasured_sources),
        }

    output = {
        "schema": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "sourceSnapshot": str(args.manifest) if args.manifest else None,
        "sourceIdentityVerified": bool(manifest),
        "testResultsVerified": args.verify_tests,
        "gitRevision": manifest.get("gitRevision") if manifest else git("rev-parse", "HEAD"),
        "results": result_paths,
        "behavioralOnlyResults": behavioral_results,
        "verifiedTestResults": verified_test_results,
        "overall": {
            "covered": overall_covered,
            "executable": overall_executable,
            "percent": ratio(overall_covered, overall_executable),
        },
        "platforms": platform_totals,
        "changedLines": changed_line_report,
        "targets": summary,
        "files": files,
        "unmeasuredSources": unmeasured_sources,
        "unmeasuredExtensionSources": unmeasured_extension_sources,
        "uncoveredFunctions": [
            {"file": file, "name": name, "line": line, "executableLines": state["lines"]}
            for (file, name, line), state in sorted(functions.items())
            if state["lines"] and not state["executions"]
        ],
        "excluded": dict(excluded),
        "lanes": {
            lane: {
                "covered": sum(len(item["covered"]) for item in rows.values()),
                "executable": sum(len(item["executable"]) for item in rows.values()),
            }
            for lane, rows in lanes.items()
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n")
    if args.markdown:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(markdown_report(output))
    print(f"App-owned source-line union: {overall_covered}/{overall_executable} ({percent_label(output['overall']['percent'])})")
    for platform, item in platform_totals.items():
        print(f"  {platform}: {item['covered']}/{item['executable']} ({percent_label(item['percent'])})")
    for target, item in summary.items():
        print(f"  {target}: {item['covered']}/{item['executable']} ({percent_label(item['percent'])})")
    for lane, item in behavioral_results.items():
        print(f"  behavioral-only {lane}: {item['passed']} passed, {item['skipped']} skipped")
    print(f"Report: {args.output}")
    if args.markdown:
        print(f"Summary: {args.markdown}")
    if unmeasured_sources:
        print(f"WARNING: {len(unmeasured_sources)} production Swift files have no coverage records", file=sys.stderr)
    if unmeasured_extension_sources:
        print("WARNING: AUv3 extension source coverage is incomplete", file=sys.stderr)
    if not manifest:
        print("WARNING: no source snapshot; result/source identity is unverified", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    snapshot_parser = sub.add_parser("snapshot", help="capture source hashes before a test run")
    snapshot_parser.add_argument("--output", type=Path, required=True)
    report_parser = sub.add_parser("report", help="union app-owned line coverage from result bundles")
    report_parser.add_argument("--result", action="append", default=[], metavar="PLATFORM/LANE=XCRESULT")
    report_parser.add_argument("--behavioral-result", action="append", default=[], metavar="PLATFORM/LANE=XCRESULT")
    report_parser.add_argument("--manifest", type=Path)
    report_parser.add_argument("--changed-base", help="Git commit/ref for changed executable lines")
    report_parser.add_argument("--verify-tests", action="store_true", help="require every result bundle to report passing tests")
    report_parser.add_argument("--output", type=Path, required=True)
    report_parser.add_argument("--markdown", type=Path, help="write a human-readable summary")
    args = parser.parse_args()
    try:
        if args.action == "report" and not args.result and not args.behavioral_result:
            raise RuntimeError("report requires --result or --behavioral-result")
        snapshot(args.output) if args.action == "snapshot" else report(args)
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"coverage: {error}\n")


if __name__ == "__main__":
    main()
