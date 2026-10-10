#!/usr/bin/env python3
"""Bounded, resumable Xcode 27 Instruments compatibility survey for this Mac.

The finite inventory is exhaustive for selected matrix families. Numeric
ranges, arbitrary instrument subsets, and target apps are not finite here;
the report explicitly states which dimensions were sampled.
"""

from __future__ import annotations

import argparse
import atexit
from collections import Counter
import copy
import fcntl
import hashlib
import itertools
import json
import os
import platform
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from pathlib import Path


HERE = Path(__file__).resolve().parent
DEFAULT_RESULTS = HERE / "CompatibilityResults.jsonl"
DEFAULT_WORK = Path("/private/tmp/instruments-compatibility-harness")
SENSITIVE = {"Foundation Models", "Network", "HTTP Traffic"}
RESOURCE_UNSAFE_ADDITIONS = {"Processor Trace"}
RESOURCE_UNSAFE_PAIRS = {("Game Performance", "VM Tracker")}
PLATFORM_FAILURE = re.compile(
    r"(?:not supported on macOS|macOS does not have|requires? (?:an? )?(?:iOS|iPadOS|visionOS)"
    r"|record on (?:iOS|iPadOS|visionOS))", re.IGNORECASE
)
ERROR_ISSUE = re.compile(r"\* \[Error\] ([^\n]+)")
MATRICES = ("templates", "instruments", "template-additions", "instrument-pairs", "options")


class ScratchLimitExceeded(RuntimeError):
    pass


def load_catalog(name: str, key: str) -> dict:
    return json.loads((HERE / name).read_text())[key]


def case_id(case: dict) -> str:
    identity = {key: value for key, value in case.items() if key != "options"}
    return hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()[:16]


def cases(selected: set[str], full_booleans: bool) -> list[dict]:
    templates = load_catalog("OptionsCatalog.json", "templates")
    instruments = load_catalog("InstrumentCapabilities.json", "instruments")
    compositions = load_catalog("TemplateComposition.json", "templates")
    names = sorted(templates)
    instrument_items = sorted(instruments.items(), key=lambda item: item[1]["displayName"])
    output: list[dict] = []

    if "templates" in selected:
        output += [{"kind": "template", "template": name, "instruments": []} for name in names]
    if "instruments" in selected:
        output += [{"kind": "instrument", "template": "Blank", "instruments": [name],
                    "instrumentIDs": [identifier]}
                   for identifier, entry in instrument_items
                   for name in [entry["displayName"]]]
    if "template-additions" in selected:
        for template in names:
            existing = {item["identifier"] for item in compositions[template]["instruments"]}
            for identifier, entry in instrument_items:
                output.append({"kind": "template-addition", "template": template,
                               "instruments": [entry["displayName"]],
                               "instrumentIDs": [identifier],
                               "alreadyPresent": identifier in existing})
    if "instrument-pairs" in selected:
        for (left_id, left), (right_id, right) in itertools.combinations(instrument_items, 2):
            output.append({"kind": "instrument-pair", "template": "Blank",
                           "instruments": [left["displayName"], right["displayName"]],
                           "instrumentIDs": [left_id, right_id]})
    if "options" in selected:
        for template in names:
            defaults = templates[template].get("options") or {}
            boolean_paths = sorted((group, key) for group, values in defaults.items()
                                   for key, value in values.items() if isinstance(value, bool))
            if full_booleans:
                selections = (combination for size in range(1, len(boolean_paths) + 1)
                              for combination in itertools.combinations(boolean_paths, size))
            else:
                selections = ((path,) for path in boolean_paths)
            for selection in selections:
                variant = copy.deepcopy(defaults)
                for group, key in selection:
                    variant[group][key] = not variant[group][key]
                output.append({"kind": "boolean-options", "template": template,
                               "instruments": [], "changed": [list(path) for path in selection],
                               "options": variant})
            for group, values in defaults.items():
                for key, value in values.items():
                    if isinstance(value, (int, float)) and not isinstance(value, bool):
                        # A single nondefault magnitude checks the setter path;
                        # NumericValidation.json contains separate boundary probes.
                        sample = value + 1 if value >= 0 else 0
                        variant = copy.deepcopy(defaults)
                        variant[group][key] = sample
                        output.append({"kind": "numeric-sample", "template": template,
                                       "instruments": [], "changed": [group, key, sample],
                                       "options": variant})
    for case in output:
        case["id"] = case_id(case)
    return output


def terminate_group(process: subprocess.Popen, grace: float = 2) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=grace)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=grace)


def directory_bytes(root: Path) -> int:
    total = 0
    for directory, _, filenames in os.walk(root):
        for filename in filenames:
            try:
                total += (Path(directory) / filename).stat().st_size
            except FileNotFoundError:
                pass
    return total


def scratch_files(root: Path) -> dict[Path, int]:
    found = {}
    for path in root.glob("instruments*.ktrace"):
        try:
            found[path] = path.stat().st_size
        except FileNotFoundError:
            pass
    return found


def deleted_open_instruments_scratch() -> dict[int, int]:
    """Return deleted ktrace bytes still retained by each DTServiceHub."""
    found: dict[int, int] = {}
    pgrep = subprocess.run(
        ["pgrep", "-f", "DVTInstrumentsFoundation.framework/Resources/DTServiceHub"],
        capture_output=True, text=True, check=False
    )
    for text_pid in pgrep.stdout.split():
        pid = int(text_pid)
        try:
            listing = subprocess.run(
                ["lsof", "-a", "-p", str(pid), "+L1", "-F", "psn"],
                capture_output=True, text=True, check=False, timeout=10
            )
        except subprocess.TimeoutExpired:
            continue
        size = 0
        total = 0
        for line in listing.stdout.splitlines():
            if line.startswith("s") and line[1:].isdigit():
                size = int(line[1:])
            elif line.startswith("n"):
                path = Path(line[1:])
                if path.name.startswith("instruments") and path.name.endswith(".ktrace"):
                    total += size
                size = 0
        if total:
            found[pid] = total
    return found


def guard_deleted_scratch(result: dict, args: argparse.Namespace) -> bool:
    """Detect the case where unlink succeeded but DTServiceHub retained storage."""
    retained = deleted_open_instruments_scratch()
    total = sum(retained.values())
    if total:
        result["deletedOpenScratchBytes"] = total
    exceeded = total > args.max_deleted_scratch_mib * 1024**2
    unsafe = exceeded or (result.get("status") == "scratch-limit" and total > 0)
    if unsafe and args.reclaim_deleted_scratch:
        terminated = []
        for pid in retained:
            try:
                os.kill(pid, signal.SIGTERM)
                terminated.append(pid)
            except ProcessLookupError:
                pass
        result["dtServiceHubsTerminated"] = terminated
        deadline = time.monotonic() + 5
        while terminated and time.monotonic() < deadline:
            still_running = []
            for pid in terminated:
                try:
                    os.kill(pid, 0)
                    still_running.append(pid)
                except ProcessLookupError:
                    pass
            terminated = still_running
            if terminated:
                time.sleep(0.05)
    return unsafe


def command(argv: list[str], timeout: float, *, full_output: bool = False,
            scratch: Path | None = None, max_scratch_bytes: int = 0,
            global_scratch: Path | None = None,
            global_baseline: dict[Path, int] | None = None) -> tuple[int | None, str, bool]:
    environment = os.environ.copy()
    if scratch is not None:
        scratch.mkdir(exist_ok=True)
        environment.update(TMPDIR=str(scratch), TMP=str(scratch), TEMP=str(scratch))
    process = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, start_new_session=True, env=environment)
    deadline = time.monotonic() + timeout
    try:
        while True:
            try:
                output, _ = process.communicate(timeout=min(0.05, max(0.01, deadline - time.monotonic())))
                scoped_bytes = directory_bytes(scratch) if scratch is not None else 0
                global_bytes = 0
                if global_scratch is not None and global_baseline is not None:
                    current = scratch_files(global_scratch)
                    global_bytes = sum(max(0, size - global_baseline.get(path, 0))
                                       for path, size in current.items())
                if max_scratch_bytes and scoped_bytes + global_bytes > max_scratch_bytes:
                    raise ScratchLimitExceeded(
                        f"Instruments scratch grew to {(scoped_bytes + global_bytes) / 1024**2:.1f} MiB"
                    )
                return process.returncode, output if full_output else output[-12000:], False
            except subprocess.TimeoutExpired:
                scoped_bytes = directory_bytes(scratch) if scratch is not None else 0
                global_bytes = 0
                if global_scratch is not None and global_baseline is not None:
                    current = scratch_files(global_scratch)
                    global_bytes = sum(max(0, size - global_baseline.get(path, 0))
                                       for path, size in current.items())
                if max_scratch_bytes and scoped_bytes + global_bytes > max_scratch_bytes:
                    raise ScratchLimitExceeded(
                        f"Instruments scratch grew to {(scoped_bytes + global_bytes) / 1024**2:.1f} MiB"
                    )
                if time.monotonic() >= deadline:
                    terminate_group(process)
                    output, _ = process.communicate()
                    return process.returncode, output if full_output else output[-12000:], True
    except BaseException:
        terminate_group(process)
        raise


def classify(case: dict, record_code: int | None, record_text: str,
             timed_out: bool, export_code: int | None, export_text: str) -> str:
    if PLATFORM_FAILURE.search(record_text):
        return "platform-unsupported"
    if "Record Anyway" in record_text and timed_out:
        return "privacy-prompt"
    if timed_out:
        return "timeout"
    if "Run issues were detected" in record_text and ERROR_ISSUE.search(record_text):
        return "recording-error"
    if record_code == 57:
        return "option-rejected"
    if export_code == 0:
        return "valid-with-warning" if "[Warning]" in record_text else "valid"
    if "Fatal error reported" in export_text:
        return "fatal-run"
    return "unverified"


def run_case(case: dict, args: argparse.Namespace, fixture: Path,
             capabilities: dict, platform_templates: dict,
             platform_instruments: dict) -> dict:
    result = {key: value for key, value in case.items() if key != "options"}
    result["recordedAt"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    if case.get("alreadyPresent"):
        result.update(status="duplicate-instrument", reason="Already in selected template")
        return result
    if case["template"] in platform_templates:
        result.update(status="platform-derived", reason=platform_templates[case["template"]])
        return result
    platform_ids = set(case.get("instrumentIDs", [])) & platform_instruments.keys()
    if platform_ids:
        result.update(status="platform-derived",
                      reason="; ".join(platform_instruments[identifier]
                                       for identifier in sorted(platform_ids)))
        return result
    if not args.include_resource_unsafe and (
        (case["template"] == "Processor Trace" and case["kind"] != "template")
        or
        (case["kind"] in {"template-addition", "instrument-pair"}
         and set(case["instruments"]) & RESOURCE_UNSAFE_ADDITIONS)
        or (case["template"], case["instruments"][0] if case["instruments"] else "")
        in RESOURCE_UNSAFE_PAIRS
    ):
        result.update(status="resource-derived",
                      reason="Repeated Processor Trace timeouts or observed excessive ktrace scratch use")
        return result
    if not args.include_sensitive and ({case["template"]} | set(case["instruments"])) & SENSITIVE:
        result.update(status="privacy-skipped", reason="Requires --include-sensitive")
        return result
    if any(not capabilities[identifier]["targetTypeSupport"]["2"]
           for identifier in case.get("instrumentIDs", [])):
        result.update(status="target-unsupported", reason="Instrument rejects private attach target type 2")
        return result

    with tempfile.TemporaryDirectory(prefix="case-", dir=args.work_dir) as directory:
        work = Path(directory)
        scratch = work / "scratch"
        global_scratch = Path(tempfile.gettempdir())
        global_baseline = scratch_files(global_scratch)
        output = work / "recording.trace"
        target = subprocess.Popen([str(fixture)], stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL, start_new_session=True)
        try:
            argv = ["xcrun", "xctrace", "record", "--template", case["template"]]
            if args.include_sensitive:
                argv.append("--no-prompt")
            for name in case["instruments"]:
                argv += ["--instrument", name]
            if "options" in case:
                options_path = work / "recording-options.json"
                options_path.write_text(json.dumps(case["options"], separators=(",", ":")))
                argv += ["--recording-options", str(options_path)]
            argv += ["--time-limit", f"{args.duration_ms}ms", "--output", str(output),
                     "--attach", str(target.pid)]
            try:
                record_code, record_text, timed_out = command(
                    argv, args.case_timeout, scratch=scratch,
                    max_scratch_bytes=args.max_scratch_mib * 1024**2,
                    global_scratch=global_scratch, global_baseline=global_baseline)
            except ScratchLimitExceeded as error:
                result.update(status="scratch-limit", reason=str(error))
                return result
            export_code: int | None = None
            export_text = ""
            schemas: list[str] = []
            if output.exists():
                try:
                    export_code, export_text, export_timeout = command(
                        ["xcrun", "xctrace", "export", "--input", str(output), "--toc"],
                        args.export_timeout, full_output=True, scratch=scratch,
                        max_scratch_bytes=args.max_scratch_mib * 1024**2,
                        global_scratch=global_scratch, global_baseline=global_baseline)
                except ScratchLimitExceeded as error:
                    result.update(status="scratch-limit", reason=str(error))
                    return result
                if export_timeout:
                    export_text += "\nExport timed out"
                if export_code == 0:
                    try:
                        root = ET.fromstring(export_text)
                        schemas = sorted({element.attrib["schema"] for element in root.iter("table")
                                          if "schema" in element.attrib})
                    except ET.ParseError:
                        export_code = None
                        export_text += "\nCould not parse TOC XML"
            result.update(status=classify(case, record_code, record_text, timed_out,
                                          export_code, export_text),
                          recordExitCode=record_code, exportExitCode=export_code,
                          timedOut=timed_out, schemas=schemas,
                          issues=ERROR_ISSUE.findall(record_text),
                          recordMessage=record_text[-3000:], exportMessage=export_text[-800:])
            return result
        finally:
            terminate_group(target)
            created = scratch_files(global_scratch).keys() - global_baseline.keys()
            removed_bytes = 0
            for path in created:
                try:
                    removed_bytes += path.stat().st_size
                    path.unlink()
                except FileNotFoundError:
                    pass
            if created:
                result["globalScratchFilesRemoved"] = len(created)
                result["globalScratchBytesRemoved"] = removed_bytes


def read_results(path: Path) -> list[dict]:
    if not path.exists():
        return []
    records = []
    raw = path.read_bytes()
    lines = raw.decode().splitlines()
    for index, line in enumerate(lines):
        if line.strip():
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                # A running writer or interrupted append may leave a partial
                # final line. Readers never truncate a writer's file.
                if index != len(lines) - 1 or raw.endswith(b"\n"):
                    raise
    return records


def lock_and_repair_results(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lock = path.with_suffix(".lock").open("w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        lock.close()
        raise RuntimeError(f"Another compatibility survey is writing {path}")
    atexit.register(lock.close)
    if path.exists():
        raw = path.read_bytes()
        if raw and not raw.endswith(b"\n"):
            with path.open("rb+") as stream:
                stream.truncate(raw.rfind(b"\n") + 1)


def check_environment(results: Path, should_write: bool) -> None:
    manifest = results.with_suffix(".environment.json")
    current = {
        "xcode": subprocess.check_output(["xcodebuild", "-version"], text=True).strip(),
        "macOS": subprocess.check_output(["sw_vers", "-productVersion"], text=True).strip(),
        "architecture": platform.machine(),
    }
    version_lines = current["xcode"].splitlines()
    catalog_version = f"{version_lines[0].removeprefix('Xcode ')} " \
                      f"({version_lines[1].removeprefix('Build version ')})"
    for catalog_name in ("OptionsCatalog.json", "InstrumentCapabilities.json",
                         "TemplateComposition.json", "TemplateArchiveCatalog.json"):
        catalog_build = json.loads((HERE / catalog_name).read_text()).get("xcode")
        if catalog_build != catalog_version:
            raise RuntimeError(f"{catalog_name} describes Xcode {catalog_build}; "
                               f"selected Xcode is {catalog_version}")
    if manifest.exists():
        recorded = json.loads(manifest.read_text())
        if recorded != current:
            raise RuntimeError(f"Xcode or macOS changed since {results.name} was recorded; "
                               "choose a new --results file for this installation")
    elif should_write:
        manifest.write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")


def macos_failures(results: list[dict]) -> tuple[dict[str, str], dict[str, str]]:
    templates: dict[str, str] = {}
    instruments: dict[str, str] = {}
    for result in {item["id"]: item for item in results}.values():
        if result.get("status") != "platform-unsupported":
            continue
        reason = "; ".join(result.get("issues", [])) or result.get("recordMessage", "")[-300:]
        if result["kind"] == "template":
            templates[result["template"]] = reason
        elif result["kind"] == "instrument" and result.get("instrumentIDs"):
            instruments[result["instrumentIDs"][0]] = reason
    return templates, instruments


def incompatible_additions(results: list[dict]) -> tuple[dict[str, dict[str, str]], dict[str, dict[str, str]]]:
    windowed: dict[str, dict[str, str]] = {}
    persistent: dict[str, dict[str, str]] = {}
    grouped: dict[str, list[dict]] = {}
    for result in results:
        grouped.setdefault(result["id"], []).append(result)
    for attempts in grouped.values():
        result = attempts[-1]
        if result.get("kind") != "template-addition":
            continue
        if result.get("status") == "scratch-limit":
            persistent.setdefault(result["template"], {})[result["instrumentIDs"][0]] = result.get(
                "reason", "Exceeded per-case scratch limit")
            continue
        if result.get("status") != "recording-error":
            continue
        issues = result.get("issues", [])
        if any("doesn't support Windowed Mode" in issue for issue in issues):
            windowed.setdefault(result["template"], {})[result["instrumentIDs"][0]] = "; ".join(issues)
        elif len([attempt for attempt in attempts if attempt.get("status") == "recording-error"]) >= 2 and any(
            "Unsupported configuration of Instruments" in issue
            or "unable to find matching kpc configuration" in issue for issue in issues
        ):
            persistent.setdefault(result["template"], {})[result["instrumentIDs"][0]] = "; ".join(issues)
    return windowed, persistent


def incompatible_instrument_pairs(results: list[dict]) -> dict[str, str]:
    grouped: dict[str, list[dict]] = {}
    for result in results:
        grouped.setdefault(result["id"], []).append(result)
    incompatible = {}
    for attempts in grouped.values():
        result = attempts[-1]
        if result.get("kind") != "instrument-pair":
            continue
        issues = result.get("issues", [])
        if any("No counting mode selected" in issue for issue in issues):
            continue
        persistent_error = (result.get("status") == "recording-error" and
                            sum(item.get("status") == "recording-error" for item in attempts) >= 2)
        if result.get("status") == "scratch-limit" or persistent_error:
            key = "|".join(sorted(result["instrumentIDs"]))
            incompatible[key] = result.get("reason") or "; ".join(issues)
    return incompatible


def write_macos_filter(results: list[dict], path: Path, source: Path) -> None:
    expected = {case["id"] for case in cases({"templates", "instruments"}, False)}
    observed = {item["id"] for item in results}
    missing = expected - observed
    if missing:
        raise RuntimeError(f"Cannot generate macOS filter until all 88 baseline cases are recorded "
                           f"({len(missing)} missing)")
    templates, instruments = macos_failures(results)
    windowed_conflicts, persistent_conflicts = incompatible_additions(results)
    pair_conflicts = incompatible_instrument_pairs(results)
    catalog = {"source": str(source.name), "templates": dict(sorted(templates.items())),
               "instruments": dict(sorted(instruments.items())),
               "windowedAdditions": {name: dict(sorted(items.items()))
                                     for name, items in sorted(windowed_conflicts.items())},
               "incompatibleAdditions": {name: dict(sorted(items.items()))
                                        for name, items in sorted(persistent_conflicts.items())},
               "incompatibleInstrumentPairs": dict(sorted(pair_conflicts.items()))}
    path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n")
    swift = HERE / "MacCompatibility.generated.swift"
    quoted_templates = ", ".join(json.dumps(name) for name in sorted(templates))
    quoted_instruments = ", ".join(json.dumps(name) for name in sorted(instruments))
    compositions = load_catalog("TemplateComposition.json", "templates")
    archives = load_catalog("TemplateArchiveCatalog.json", "archives")
    windowed = []
    for name, entry in sorted(compositions.items()):
        selected = next((archive for relative, archive in archives.items()
                         if entry["templatePath"].endswith(relative)), None)
        if selected and any(mode["supportsWindowedMode"]
                            for mode in selected["recordingModes"]):
            windowed.append(name)
    rows = []
    for name, entry in sorted(compositions.items()):
        identifiers = ", ".join(json.dumps(item["identifier"])
                                for item in entry["instruments"])
        rows.append(f"        {json.dumps(name)}: [{identifiers}],")
    def swift_conflicts(conflicts: dict[str, dict[str, str]]) -> list[str]:
        rows = []
        for name, items in sorted(conflicts.items()):
            identifiers = ", ".join(json.dumps(identifier) for identifier in sorted(items))
            rows.append(f"        {json.dumps(name)}: [{identifiers}],")
        return rows
    swift.write_text("".join([
        "// Generated by compatibility_harness.py from recorded failures and installed template archives.\n",
        "enum MacCompatibility {\n",
        f"    static let unsupportedTemplates: Set<String> = [{quoted_templates}]\n",
        f"    static let unsupportedInstrumentIDs: Set<String> = [{quoted_instruments}]\n",
        f"    static let windowedTemplates: Set<String> = [{', '.join(json.dumps(name) for name in windowed)}]\n",
        "    static let windowedAdditions: [String: Set<String>] = [\n",
        "\n".join(swift_conflicts(windowed_conflicts)), "\n",
        "    ]\n",
        "    static let incompatibleAdditions: [String: Set<String>] = [\n",
        "\n".join(swift_conflicts(persistent_conflicts)), "\n",
        "    ]\n",
        f"    static let incompatibleInstrumentPairs: Set<String> = [{', '.join(json.dumps(key) for key in sorted(pair_conflicts))}]\n",
        "    static let templateInstrumentIDs: [String: Set<String>] = [\n",
        "\n".join(rows), "\n",
        "    ]\n",
        "}\n",
    ]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--matrix", nargs="+", choices=[*MATRICES, "all"], default=["templates"])
    parser.add_argument("--only-template", action="append", default=[],
                        help="Limit generated cases to a template name; repeatable")
    parser.add_argument("--only-instrument", action="append", default=[],
                        help="Limit generated cases to an added instrument name; repeatable")
    parser.add_argument("--cross-template-order", action="store_true",
                        help="Visit the same added instrument across templates first")
    parser.add_argument("--run", action="store_true", help="Record selected cases; default prints the plan")
    parser.add_argument("--max-cases", type=int, default=0, help="New cases this invocation; 0 means all")
    parser.add_argument("--duration-ms", type=int, default=100)
    parser.add_argument("--case-timeout", type=float, default=20)
    parser.add_argument("--export-timeout", type=float, default=15)
    parser.add_argument("--max-scratch-mib", type=int, default=128,
                        help="Stop the survey if one case creates more scratch than this")
    parser.add_argument("--min-free-gib", type=int, default=40,
                        help="Stop the survey before a case if free disk falls below this")
    parser.add_argument("--max-deleted-scratch-mib", type=int, default=512,
                        help="Stop if DTServiceHub retains this much deleted ktrace storage")
    parser.add_argument("--reclaim-deleted-scratch", action="store_true",
                        help="TERM DTServiceHub when deleted ktrace storage exceeds its cap")
    parser.add_argument("--continue-after-scratch-limit", action="store_true",
                        help="Record and clean an over-limit case, then continue under the free-space floor")
    parser.add_argument("--full-booleans", action="store_true", help="Every Boolean combination per template")
    parser.add_argument("--include-sensitive", action="store_true",
                        help="Allow Foundation Models and Network privacy prompts/capture")
    parser.add_argument("--include-resource-unsafe", action="store_true",
                        help="Run Processor Trace combinations and known high-scratch pairs")
    parser.add_argument("--results", type=Path, default=DEFAULT_RESULTS)
    parser.add_argument("--retry-status", nargs="*", default=[],
                        help="Recheck completed cases with these recorded statuses")
    parser.add_argument("--confirm-errors", action="store_true",
                        help="Immediately rerun new hard recording errors once, except missing CPU counting mode")
    parser.add_argument("--work-dir", type=Path, default=DEFAULT_WORK)
    parser.add_argument("--write-macos-filter", action="store_true",
                        help="Generate Swift exclusions from baseline platform failures")
    parser.add_argument("--summary", action="store_true",
                        help="Print latest status counts for selected matrix families")
    args = parser.parse_args()
    if (args.duration_ms <= 0 or args.duration_ms > 5000 or args.case_timeout <= 0
            or args.max_scratch_mib <= 0 or args.min_free_gib <= 0
            or args.max_deleted_scratch_mib <= 0):
        parser.error("duration must be 1...5000 ms; timeouts and disk limits must be positive")
    if args.run:
        lock_and_repair_results(args.results)
    check_environment(args.results, args.run or args.write_macos_filter)
    selected = set(MATRICES) if "all" in args.matrix else set(args.matrix)
    planned = cases(selected, args.full_booleans)
    if args.only_template:
        planned = [case for case in planned if case["template"] in args.only_template]
    if args.only_instrument:
        planned = [case for case in planned if set(case["instruments"]) & set(args.only_instrument)]
    if args.cross_template_order:
        planned.sort(key=lambda case: (case["instruments"][0], case["template"])
                     if case["kind"] == "template-addition" else (case["kind"], case["template"]))
    previous = read_results(args.results)
    corrections = []
    for result in {item["id"]: item for item in previous}.values():
        updated = dict(result)
        if result["status"] == "recording-error" and PLATFORM_FAILURE.search(result.get("recordMessage", "")):
            updated["status"] = "platform-unsupported"
        elif result["status"] == "timeout" and "Record Anyway" in result.get("recordMessage", ""):
            updated["status"] = "privacy-prompt"
        if updated["status"] != result["status"]:
            corrections.append(updated)
    if corrections:
        with args.results.open("a", buffering=1) as stream:
            for correction in corrections:
                stream.write(json.dumps(correction, sort_keys=True) + "\n")
        previous += corrections
        print(f"Reclassified {len(corrections)} existing results from their recorded issues")
    latest = {item["id"]: item for item in previous}
    pending = [case for case in planned if case["id"] not in latest
               or latest[case["id"]]["status"] in args.retry_status]
    print(json.dumps({"planned": len(planned), "complete": len(planned) - len(pending),
                      "pending": len(pending), "matrices": sorted(selected),
                      "fullBooleans": args.full_booleans,
                      "limits": "Numeric samples only; instrument subsets of size >=3 omitted"}))
    if args.summary:
        case_ids = {case["id"] for case in planned}
        observed = [result for identifier, result in latest.items() if identifier in case_ids]
        print(json.dumps({"observed": len(observed),
                          "statuses": dict(sorted(Counter(result["status"] for result in observed).items())),
                          "byKind": {kind: dict(sorted(Counter(result["status"] for result in observed
                                                                 if result["kind"] == kind).items()))
                                     for kind in sorted({result["kind"] for result in observed})}},
                         sort_keys=True))
    if not args.run:
        for case in pending[:5]:
            print(json.dumps({key: value for key, value in case.items() if key != "options"}))
        if args.write_macos_filter:
            write_macos_filter(previous, HERE / "MacCompatibility.json", args.results)
        return 0

    args.work_dir.mkdir(parents=True, exist_ok=True)
    capabilities = load_catalog("InstrumentCapabilities.json", "instruments")
    platform_templates, platform_instruments = macos_failures(previous)
    fixture = args.work_dir / "instruments-busy-target"
    subprocess.run(["clang", "-O0", str(HERE / "busy_target.c"), "-o", str(fixture)], check=True)
    limit = args.max_cases or len(pending)
    try:
        with args.results.open("a", buffering=1) as stream:
            for index, case in enumerate(pending[:limit], 1):
                free = shutil.disk_usage(args.work_dir).free
                if free < args.min_free_gib * 1024**3:
                    raise RuntimeError(f"Free disk {free / 1024**3:.1f} GiB is below "
                                       f"the {args.min_free_gib} GiB floor; survey stopped")
                result = run_case(case, args, fixture, capabilities,
                                  platform_templates, platform_instruments)
                deleted_cap_hit = guard_deleted_scratch(result, args)
                stream.write(json.dumps(result, sort_keys=True) + "\n")
                stream.flush()
                os.fsync(stream.fileno())
                print(f"{index}/{min(limit, len(pending))} {case['kind']} "
                      f"{case['template']} + {','.join(case['instruments'])}: {result['status']}", flush=True)
                if result["status"] == "scratch-limit" and not args.continue_after_scratch_limit:
                    raise RuntimeError(f"{result['reason']}; survey stopped before next case")
                if deleted_cap_hit and not args.reclaim_deleted_scratch:
                    raise RuntimeError(
                        f"DTServiceHub retains {result['deletedOpenScratchBytes'] / 1024**2:.1f} MiB "
                        "of deleted ktrace storage; survey stopped. Quit Instruments or pass "
                        "--reclaim-deleted-scratch to restart that service automatically."
                    )
                if (args.confirm_errors and result["status"] == "recording-error"
                        and not any("No counting mode selected" in issue
                                    for issue in result.get("issues", []))):
                    confirmation = run_case(case, args, fixture, capabilities,
                                            platform_templates, platform_instruments)
                    confirmation["confirmation"] = True
                    confirmation_cap_hit = guard_deleted_scratch(confirmation, args)
                    stream.write(json.dumps(confirmation, sort_keys=True) + "\n")
                    stream.flush()
                    os.fsync(stream.fileno())
                    print(f"  confirmation: {confirmation['status']}", flush=True)
                    if confirmation_cap_hit and not args.reclaim_deleted_scratch:
                        raise RuntimeError(
                            f"DTServiceHub retains {confirmation['deletedOpenScratchBytes'] / 1024**2:.1f} "
                            "MiB of deleted ktrace storage; survey stopped."
                        )
    finally:
        fixture.unlink(missing_ok=True)
    if args.write_macos_filter:
        write_macos_filter(read_results(args.results), HERE / "MacCompatibility.json", args.results)
    return 0


if __name__ == "__main__":
    sys.exit(main())
