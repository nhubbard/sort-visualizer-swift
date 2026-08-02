#!/usr/bin/env python3
"""Algorithm content pipeline: scaffold, highlight, test, lint, format, pack, and decode
`AlgorithmDetails/`.

One CLI sharing a single algorithm-discovery/logging setup, replacing the former
`scaffold.sh` + `highlight.py` + `test.py` trio. Run via `uv run manage.py <command> --help`.
"""

from __future__ import annotations

import ast
import functools
import hashlib
import logging
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import threading
from collections.abc import Callable, Iterable, Sequence
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

import click
import coloredlogs
import zstandard
from pygments import highlight as pygments_highlight
from pygments.formatter import Formatter
from pygments.lexers import get_lexer_for_filename

ROOT = Path(__file__).resolve().parent
TEMPLATE_DIR = ROOT / "template"

# Canonical order — must match `CodeLanguage.all` in
# `Modules/DesignSystemKit/Sources/CodeLanguage.swift`. `pack`'s content-kind IDs are derived from
# this order (1-indexed, description is kind 0), so changing it is a breaking archive-format change.
LANGUAGE_EXTENSIONS = ("py", "js", "go", "java", "c", "cpp", "cs", "rb", "kt", "swift")

EXCLUDED_DIRECTORY_NAMES = {"template", "__pycache__"}

logger = logging.getLogger("algcontent")


def discover_algorithms() -> list[str]:
    return sorted(
        entry.name
        for entry in os.scandir(ROOT)
        if entry.is_dir()
        and entry.name not in EXCLUDED_DIRECTORY_NAMES
        and not entry.name.startswith(".")
    )


def resolve_targets(names: Sequence[str]) -> list[str]:
    return sorted(set(names)) if names else discover_algorithms()


class AlgorithmContentError(click.ClickException):
    """Base for user-facing errors — Click prints `Error: {message}` and exits 1."""


# --------------------------------------------------------------------------------------------
# scaffold
# --------------------------------------------------------------------------------------------


def scaffold_algorithm(name: str) -> None:
    folder = ROOT / name
    if folder.exists():
        raise AlgorithmContentError(f"{folder} already exists")
    folder.mkdir()
    shutil.copy(TEMPLATE_DIR / "description.md", folder / "description.md")
    for ext in LANGUAGE_EXTENSIONS:
        shutil.copy(TEMPLATE_DIR / f"template.{ext}", folder / f"{name}.{ext}")
    logger.info(
        f"Scaffolded {name}/. Fill in the source files and description.md, then run "
        f"'uv run manage.py highlight {name}' followed by 'uv run manage.py test {name}'."
    )


# --------------------------------------------------------------------------------------------
# highlight
# --------------------------------------------------------------------------------------------


class AttributedTextFormatter(Formatter):
    """Emits the `^[text](code: 'Token.X')` markdown `CodeAttributes.swift` parses."""

    def __init__(self) -> None:
        super().__init__()
        self.output = ""

    def format(self, tokensource, _outfile) -> None:
        for token_type, value in tokensource:
            value = (
                value.replace("[", "\\[")
                .replace("]", "\\]")
                .replace("^", "\\^")
                .replace("_", "\\_")
                .replace("-", "\\-")
                .replace("*", "\\*")
            )
            if value == "\n":
                self.output += "\n"
            else:
                self.output += f"^[{value}](code: '{token_type!s}')"

    def result(self) -> str:
        return self.output


def highlight_algorithms(targets: Iterable[str]) -> None:
    highlighted, algorithm_count = 0, 0
    for algorithm in targets:
        algorithm_count += 1
        for ext in LANGUAGE_EXTENSIONS:
            source_path = ROOT / algorithm / f"{algorithm}.{ext}"
            output_path = ROOT / algorithm / f"{ext}.md"
            if not source_path.exists():
                logger.warning(f"skipping {source_path} highlighting (file not found)")
                continue
            code = source_path.read_text(encoding="utf-8").rstrip("\n")
            lexer = get_lexer_for_filename(str(source_path))
            formatter = AttributedTextFormatter()
            pygments_highlight(code, lexer, formatter)
            output_path.write_text(formatter.result(), encoding="utf-8")
            highlighted += 1
    logger.info(
        f"Highlighted {highlighted} file(s) across {algorithm_count} algorithm(s)."
    )


# --------------------------------------------------------------------------------------------
# test
# --------------------------------------------------------------------------------------------


@functools.cache
def get_expected(algorithm: str) -> str:
    """Derives the expected sorted-output string from the literal `array = [...]` declared in
    that algorithm's own Python reference implementation.

    Some algorithms (mostly bogosort-family combinatorial ones) use a shortened input array so
    they finish in reasonable time, so there's no single expected output shared across all
    algorithms; each one's expected value is whatever its own array sorts to.
    """
    py_path = ROOT / algorithm / f"{algorithm}.py"
    source = py_path.read_text(encoding="utf-8")
    match = re.search(r"array\s*=\s*(\[[^\]]*\])", source)
    if not match:
        raise AlgorithmContentError(
            f"Could not find an `array = [...]` literal in {py_path}"
        )
    values = ast.literal_eval(match.group(1))
    return "[" + ", ".join(str(v) for v in sorted(values)) + "]"


def _run(
    cmd: list[str], cwd: Path, timeout: float = 60.0
) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd, cwd=cwd, check=True, capture_output=True, timeout=timeout
    )


def _log_subprocess_failure(
    stage: str,
    filename: str,
    error: subprocess.CalledProcessError | subprocess.TimeoutExpired,
) -> None:
    logger.error(f"{stage} of {filename} failed! See next entry for error message(s).")
    if isinstance(error, subprocess.TimeoutExpired):
        logger.error(
            f"Timed out after {error.timeout}s — check for an infinite loop in the source."
        )
        return
    logger.error(error.stdout.decode("utf-8", "replace").strip())
    logger.error(error.stderr.decode("utf-8", "replace").strip())


def _check_output(
    filename: str,
    algorithm: str,
    output: str,
    normalize: Callable[[str], str] | None = None,
) -> bool:
    expected = get_expected(algorithm)
    if normalize is not None:
        expected = normalize(expected)
        output = normalize(output)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        return False
    logger.info(f"{filename}: Passed!")
    return True


def _cleanup(paths: Iterable[Path]) -> None:
    for path in paths:
        if path.is_dir():
            shutil.rmtree(path, ignore_errors=True)
        elif path.exists():
            path.unlink()


def _strip_ext(basename: str, ext: str) -> str:
    return basename[: -(len(ext) + 1)]


def _kt_class_name(basename: str) -> str:
    # kotlinc compiles top-level functions in "Foo.kt" into a class named "FooKt".
    return basename.capitalize().replace(".kt", "Kt")


def _kt_artifacts(algo_dir: Path, basename: str) -> list[Path]:
    outfile = _kt_class_name(basename)
    return [
        algo_dir / f"{outfile}.class",
        algo_dir
        / "BogosortKt$isSorted$1.class",  # bogosort's impl produces 2 class files
        algo_dir / "META-INF",
    ]


@dataclass(frozen=True)
class LanguageTest:
    compile: Callable[[Path, str], list[str]] | None
    run: Callable[[Path, str], list[str]]
    artifacts: Callable[[Path, str], list[Path]]
    normalize: Callable[[str], str] | None = None


LANGUAGE_TESTS: dict[str, LanguageTest] = {
    "c": LanguageTest(
        compile=lambda d, b: ["clang", "-o", _strip_ext(b, "c"), b],
        run=lambda d, b: [f"./{_strip_ext(b, 'c')}"],
        artifacts=lambda d, b: [d / _strip_ext(b, "c")],
    ),
    "cpp": LanguageTest(
        compile=lambda d, b: ["clang++", "-o", _strip_ext(b, "cpp"), b],
        run=lambda d, b: [f"./{_strip_ext(b, 'cpp')}"],
        artifacts=lambda d, b: [d / _strip_ext(b, "cpp")],
    ),
    "cs": LanguageTest(
        compile=None,
        run=lambda d, b: ["dotnet", "run", "--file", b],
        artifacts=lambda d, b: [],
    ),
    "go": LanguageTest(
        compile=None,
        run=lambda d, b: ["go", "run", b],
        artifacts=lambda d, b: [],
        normalize=lambda output: output.replace(",", ""),
    ),
    "java": LanguageTest(
        compile=lambda d, b: ["javac", b],
        run=lambda d, b: ["java", "-cp", ".", _strip_ext(b, "java")],
        artifacts=lambda d, b: [d / f"{_strip_ext(b, 'java')}.class"],
    ),
    "js": LanguageTest(
        compile=None,
        run=lambda d, b: ["node", b],
        artifacts=lambda d, b: [],
    ),
    "kt": LanguageTest(
        compile=lambda d, b: ["kotlinc", b],
        run=lambda d, b: ["kotlin", _kt_class_name(b)],
        artifacts=_kt_artifacts,
    ),
    "py": LanguageTest(
        compile=None,
        run=lambda d, b: ["python3", b],
        artifacts=lambda d, b: [],
    ),
    "rb": LanguageTest(
        compile=None,
        run=lambda d, b: ["/opt/homebrew/opt/ruby/bin/ruby", b],
        artifacts=lambda d, b: [],
    ),
    "swift": LanguageTest(
        compile=lambda d, b: ["swiftc", "-o", _strip_ext(b, "swift"), b],
        run=lambda d, b: [f"./{_strip_ext(b, 'swift')}"],
        artifacts=lambda d, b: [d / _strip_ext(b, "swift")],
    ),
}


def run_language_test(spec: LanguageTest, filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = ROOT / algorithm
    artifacts = spec.artifacts(algo_dir, basename)
    logger.debug(f"Testing {filename}")
    if spec.compile is not None:
        try:
            _run(spec.compile(algo_dir, basename), algo_dir)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            _log_subprocess_failure("Compilation", filename, e)
            _cleanup(artifacts)
            return False
    try:
        output = (
            _run(spec.run(algo_dir, basename), algo_dir).stdout.decode("utf-8").strip()
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        _log_subprocess_failure("Execution", filename, e)
        _cleanup(artifacts)
        return False
    passed = _check_output(filename, algorithm, output, spec.normalize)
    _cleanup(artifacts)
    return passed


def _run_algorithm_tests(algorithm: str, languages: Sequence[str]) -> list[bool]:
    """Runs every requested language's test for a single algorithm, in order.

    This must stay sequential *within* an algorithm: the C, C++, and Swift files for one
    algorithm all compile to the same output filename in that algorithm's directory, so running
    two of them at once would let one clobber the other's binary mid-run. Parallelism is applied
    across algorithms instead, since each algorithm's directory is otherwise self-contained.
    """
    results = []
    for ext in languages:
        source_path = ROOT / algorithm / f"{algorithm}.{ext}"
        if not source_path.exists():
            logger.warning(
                f"skipping {algorithm}/{algorithm}.{ext} testing (file not found)"
            )
            continue
        results.append(
            run_language_test(LANGUAGE_TESTS[ext], f"{algorithm}/{algorithm}.{ext}")
        )
    return results


def test_algorithms(targets: Sequence[str], languages: Sequence[str]) -> bool:
    max_workers = min(12, os.cpu_count() or 4)
    results: list[bool] = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(_run_algorithm_tests, algorithm, languages): algorithm
            for algorithm in targets
        }
        for future in as_completed(futures):
            algorithm = futures[future]
            try:
                results.extend(future.result())
            except Exception:
                logger.exception(f"Unhandled exception while testing {algorithm}")
                results.append(False)
    return all(results)


# --------------------------------------------------------------------------------------------
# setup — install missing test/lint/format dependencies via Homebrew
# --------------------------------------------------------------------------------------------

# Every Homebrew-installable dependency `test`/`lint`/`format` need: both the lint/format add-on
# tools AND each language's base compiler/runtime, maps binary name to the Homebrew formula that
# provides it. `llvm` is keg-only (provides clang-tidy without symlinking it onto PATH), so its
# presence is checked via `brew --prefix` rather than a plain `shutil.which` — `openjdk` is
# sometimes keg-only too depending on what else manages Java on a given machine, so the same
# fallback covers it for free.
#
# Deliberately NOT covered: Swift's and C/C++'s own compilers (swiftc/clang/clang++). Those come
# from Xcode's Command Line Tools, which this whole repository already requires to build the app
# itself — Homebrew doesn't manage Apple's toolchain in a way that integrates with what's already
# selected via `xcode-select`, so installing an alternate one via brew would risk *more* confusion
# about which compiler is actually in use, not less.
BREW_FORMULAS: dict[str, str] = {
    "clang-format": "clang-format",
    "clang-tidy": "llvm",
    "ktlint": "ktlint",
    "checkstyle": "checkstyle",
    "google-java-format": "google-java-format",
    "ruff": "ruff",
    "eslint": "eslint",
    "prettier": "prettier",
    "swiftformat": "swiftformat",
    "swiftlint": "swiftlint",
    "go": "go",
    "javac": "openjdk",
    "node": "node",
    "kotlinc": "kotlin",
    "ruby": "ruby",
}

# The .NET SDK ships as a Homebrew cask, not a formula — casks aren't queryable via `brew --prefix`,
# but `shutil.which` finds a cask-installed binary exactly the same way it finds a formula's, so no
# separate presence-check path is needed, only a separate *install* invocation (`--cask`).
BREW_CASKS: dict[str, str] = {
    "dotnet": "dotnet-sdk",
}

# The "standard" gem installs its `standardrb` executable into the Homebrew Ruby's own gem
# bindir, not onto PATH — resolved dynamically below rather than hardcoding a Ruby version.
RUBY_BIN = "/opt/homebrew/opt/ruby/bin/ruby"
GEM_BIN = "/opt/homebrew/opt/ruby/bin/gem"

ESLINT_CONFIG = ROOT / "eslint.config.js"
CHECKSTYLE_CONFIG = ROOT / "checkstyle.xml"
CLANG_TIDY_CONFIG = ROOT / ".clang-tidy"


def _find_brew_tool(name: str, formula: str) -> str | None:
    found = shutil.which(name)
    if found:
        return found
    try:
        prefix = subprocess.run(
            ["brew", "--prefix", formula],
            capture_output=True,
            text=True,
            check=True,
            timeout=15,
        ).stdout.strip()
    except subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired:
        return None
    candidate = Path(prefix) / "bin" / name
    return str(candidate) if candidate.exists() else None


@functools.cache
def _resolve_brew_tool(name: str) -> str:
    found = _find_brew_tool(name, BREW_FORMULAS[name])
    if found is None:
        raise AlgorithmContentError(
            f"{name!r} not found. Run 'uv run manage.py setup' to install it."
        )
    return found


def _find_standardrb() -> str | None:
    try:
        gemdir = subprocess.run(
            [GEM_BIN, "environment", "gemdir"],
            capture_output=True,
            text=True,
            check=True,
            timeout=15,
        ).stdout.strip()
    except subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired:
        return None
    candidate = Path(gemdir) / "bin" / "standardrb"
    return str(candidate) if candidate.exists() else None


@functools.cache
def _resolve_standardrb() -> str:
    found = _find_standardrb()
    if found is None:
        raise AlgorithmContentError(
            "'standardrb' not found. Run 'uv run manage.py setup' to install it."
        )
    return found


def _find_brew_cask(name: str) -> str | None:
    # Cask-installed binaries land on PATH exactly like formula-installed ones (confirmed for
    # dotnet-sdk: `which dotnet` finds it directly) — no `brew --prefix`-style fallback needed.
    return shutil.which(name)


def setup_tools() -> None:
    missing_formulas: list[str] = []
    for name, formula in BREW_FORMULAS.items():
        if _find_brew_tool(name, formula) is not None:
            logger.info(f"{name}: already present.")
        else:
            logger.info(f"{name}: missing, will install '{formula}' via Homebrew.")
            if formula not in missing_formulas:
                missing_formulas.append(formula)

    if missing_formulas:
        logger.info(f"Running: brew install {' '.join(missing_formulas)}")
        try:
            _run(["brew", "install", *missing_formulas], ROOT, timeout=900.0)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            _log_subprocess_failure("Homebrew install", " ".join(missing_formulas), e)
            raise AlgorithmContentError(
                "Homebrew install failed, see log above."
            ) from e

    missing_casks: list[str] = []
    for name, cask in BREW_CASKS.items():
        if _find_brew_cask(name) is not None:
            logger.info(f"{name}: already present.")
        else:
            logger.info(f"{name}: missing, will install '{cask}' via Homebrew (cask).")
            if cask not in missing_casks:
                missing_casks.append(cask)

    if missing_casks:
        logger.info(f"Running: brew install --cask {' '.join(missing_casks)}")
        try:
            _run(["brew", "install", "--cask", *missing_casks], ROOT, timeout=900.0)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            _log_subprocess_failure("Homebrew cask install", " ".join(missing_casks), e)
            raise AlgorithmContentError(
                "Homebrew cask install failed, see log above."
            ) from e

    if _find_standardrb() is not None:
        logger.info("standardrb: already present.")
    else:
        logger.info("standardrb: missing, will install the 'standard' gem.")
        try:
            _run([GEM_BIN, "install", "standard"], ROOT, timeout=300.0)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            _log_subprocess_failure("gem install", "standard", e)
            raise AlgorithmContentError(
                "'gem install standard' failed, see log above."
            ) from e

    logger.info(
        "Setup complete. Swift's and C/C++'s own compilers (swiftc/clang/clang++) come from "
        "Xcode's Command Line Tools, not Homebrew, and are assumed already installed — same "
        "precondition this whole repository already has to build the app itself."
    )


# --------------------------------------------------------------------------------------------
# lint / format
# --------------------------------------------------------------------------------------------

# C#, Go's format-check, and Swift's format (lock + persistent backup, see below) are special-
# cased directly in `run_language_lint`/`run_language_format` rather than living in these tables —
# each needs behavior a plain `(dir, basename) -> argv` lambda can't express. Every other language
# is a straightforward CLI invocation, exactly like `LANGUAGE_TESTS`.
#
# Every underlying tool's *default* invocation already does the right thing for one axis of
# lint/format's two axes — reporting-only (all lint checks; format's `--check`) exits nonzero on
# any finding, and applying (lint `--fix`; format's default) mutates in place — verified
# empirically against a real install of each tool rather than assumed from documentation, since
# two genuinely don't follow that convention: `gofmt -l` always exits 0 regardless of findings,
# and bare `clang-tidy` also exits 0 on warnings unless `--warnings-as-errors` is passed.


@dataclass(frozen=True)
class LanguageLint:
    check: Callable[[Path, str], list[str]]
    fix: Callable[[Path, str], list[str]] | None = None


@dataclass(frozen=True)
class LanguageFormat:
    check: Callable[[Path, str], list[str]]
    apply: Callable[[Path, str], list[str]]


LANGUAGE_LINTS: dict[str, LanguageLint] = {
    "c": LanguageLint(
        check=lambda d, b: [
            _resolve_brew_tool("clang-tidy"),
            "--warnings-as-errors=*",
            b,
            "--",
        ],
        fix=lambda d, b: [_resolve_brew_tool("clang-tidy"), "-fix", b, "--"],
    ),
    "cpp": LanguageLint(
        check=lambda d, b: [
            _resolve_brew_tool("clang-tidy"),
            "--warnings-as-errors=*",
            b,
            "--",
        ],
        fix=lambda d, b: [_resolve_brew_tool("clang-tidy"), "-fix", b, "--"],
    ),
    "go": LanguageLint(check=lambda d, b: ["go", "vet", b]),  # no autofix
    "java": LanguageLint(
        check=lambda d, b: [
            _resolve_brew_tool("checkstyle"),
            "-c",
            str(CHECKSTYLE_CONFIG),
            b,
        ],
        # google_checks.xml's violations are all WARN severity, which checkstyle doesn't treat as
        # a failure (exit 0 regardless); checkstyle.xml (ours, pruned from sun_checks.xml — see
        # that file's own header comment for the full audit) uses ERROR severity, which does.
    ),  # no autofix
    "js": LanguageLint(
        check=lambda d, b: [
            _resolve_brew_tool("eslint"),
            "--config",
            str(ESLINT_CONFIG),
            b,
        ],
        fix=lambda d, b: [
            _resolve_brew_tool("eslint"),
            "--config",
            str(ESLINT_CONFIG),
            "--fix",
            b,
        ],
    ),
    "kt": LanguageLint(
        check=lambda d, b: [_resolve_brew_tool("ktlint"), b],
        fix=lambda d, b: [_resolve_brew_tool("ktlint"), "-F", b],
    ),
    "py": LanguageLint(
        check=lambda d, b: ["ruff", "check", b],
        fix=lambda d, b: ["ruff", "check", "--fix", b],
    ),
    "rb": LanguageLint(
        check=lambda d, b: [RUBY_BIN, _resolve_standardrb(), b],
        fix=lambda d, b: [RUBY_BIN, _resolve_standardrb(), "--fix", b],
    ),
    "swift": LanguageLint(
        check=lambda d, b: [_resolve_brew_tool("swiftlint"), "lint", b],
    ),  # no autofix in v1 — swiftlint's autocorrect story is separate from swiftformat's
}

LANGUAGE_FORMATS: dict[str, LanguageFormat] = {
    "c": LanguageFormat(
        check=lambda d, b: ["clang-format", "--dry-run", "--Werror", b],
        apply=lambda d, b: ["clang-format", "-i", b],
    ),
    "cpp": LanguageFormat(
        check=lambda d, b: ["clang-format", "--dry-run", "--Werror", b],
        apply=lambda d, b: ["clang-format", "-i", b],
    ),
    "java": LanguageFormat(
        check=lambda d, b: [
            _resolve_brew_tool("google-java-format"),
            "--dry-run",
            "--set-exit-if-changed",
            b,
        ],
        apply=lambda d, b: [_resolve_brew_tool("google-java-format"), "--replace", b],
    ),
    "js": LanguageFormat(
        check=lambda d, b: ["prettier", "--check", b],
        apply=lambda d, b: ["prettier", "--write", b],
    ),
    "kt": LanguageFormat(
        check=lambda d, b: [_resolve_brew_tool("ktlint"), b],
        apply=lambda d, b: [_resolve_brew_tool("ktlint"), "-F", b],
    ),
    "py": LanguageFormat(
        check=lambda d, b: ["ruff", "format", "--check", b],
        apply=lambda d, b: ["ruff", "format", b],
    ),
    "rb": LanguageFormat(
        check=lambda d, b: [RUBY_BIN, _resolve_standardrb(), b],
        apply=lambda d, b: [RUBY_BIN, _resolve_standardrb(), "--fix", b],
    ),
}

_CSPROJ_TEMPLATE = """<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="{source}" />
  </ItemGroup>
</Project>
"""


def _dotnet_format(
    algo_dir: Path, basename: str, *, verify_only: bool, raise_on_error: bool
) -> subprocess.CompletedProcess:
    """`dotnet format` only operates on a project/solution, not a single file directly, unlike
    `dotnet run --file` (which `LANGUAGE_TESTS["cs"]` uses). Generates a throwaway SDK-style
    project in a temp directory that `<Compile Include>`s the real file by absolute path —
    verified empirically that this lets `dotnet format` read/report/fix the file at its original
    location with no copying, and that the temp project (and any `obj/`/`bin/` it creates) can be
    discarded afterward without a trace. Deliberately not kept per-algorithm: it exists purely to
    drive the formatter over one file and would just be 124 near-identical tracked files.
    """
    source = (algo_dir / basename).resolve()
    with tempfile.TemporaryDirectory(prefix="algcontent-dotnet-") as tmp:
        scratch = Path(tmp) / "scratch.csproj"
        scratch.write_text(_CSPROJ_TEMPLATE.format(source=source), encoding="utf-8")
        cmd = ["dotnet", "format", str(scratch)]
        if verify_only:
            cmd.append("--verify-no-changes")
        return subprocess.run(
            cmd, cwd=tmp, check=raise_on_error, capture_output=True, timeout=120.0
        )


# A prior real-world run of `swiftformat` across many Swift files *in parallel* produced
# non-deterministic file corruption in this repo. Every invocation — check or apply — goes
# through this one global lock, so at most one swiftformat process ever runs at a time no matter
# how many algorithms `lint`/`format` are otherwise processing concurrently. swiftlint is a
# separate tool and isn't implicated, so it stays in the normal parallel pool.
_SWIFT_FORMAT_LOCK = threading.Lock()


def _run_swiftformat(
    algo_dir: Path, basename: str, *, check: bool, raise_on_error: bool
) -> subprocess.CompletedProcess:
    tool = _resolve_brew_tool("swiftformat")
    cmd = [tool, "--lint", basename] if check else [tool, basename]
    with _SWIFT_FORMAT_LOCK:
        return subprocess.run(
            cmd, cwd=algo_dir, check=raise_on_error, capture_output=True, timeout=60.0
        )


def _run_allow_nonzero(
    cmd: list[str], cwd: Path, timeout: float = 60.0
) -> subprocess.CompletedProcess:
    """Like `_run`, but doesn't raise on a nonzero exit — used for fixers/formatters, which
    legitimately exit nonzero when they fix everything they can but issues remain (e.g. eslint
    --fix on a non-autofixable rule). `_run_mutation` below decides what that means."""
    return subprocess.run(
        cmd, cwd=cwd, check=False, capture_output=True, timeout=timeout
    )


def _run_mutation(
    stage: str,
    filename: str,
    algo_dir: Path,
    basename: str,
    ext: str,
    runner: Callable[[], subprocess.CompletedProcess],
) -> bool:
    """Runs a mutating fixer/formatter, then re-verifies the file against its own `test` before
    keeping the change — restoring the pre-mutation bytes if the retest fails.

    This is a direct response to a real incident in this repo: `standardrb --fix` once silently
    deleted a loop-init line in two `.rb` files, turning them into genuine infinite loops that the
    old bespoke test runner (no timeout) never caught. `_run`'s current 60s timeout means a repeat
    of that specific failure mode can no longer hang forever, but a silent correctness regression
    is still unacceptable — so every mutating operation, for every language, gets this same
    snapshot-run-reverify-or-restore treatment, not just Ruby's.

    Swift gets one more layer on top: a persistent `<file>.swift.bak` (see `.gitignore`), since a
    prior real run of the Swift formatter across many files in parallel produced non-deterministic
    corruption — this in-memory `original` alone wouldn't survive a crash mid-run the way a
    written-to-disk backup does.
    """
    path = algo_dir / basename
    original = path.read_bytes()
    if ext == "swift":
        backup_path = algo_dir / f"{basename}.bak"
        backup_path.write_bytes(original)
        logger.info(f"{filename}: backed up to {backup_path.name} before formatting.")

    try:
        result = runner()
    except (subprocess.TimeoutExpired, OSError) as e:
        _log_subprocess_failure(stage, filename, e)
        if path.read_bytes() != original:
            path.write_bytes(original)
        return False

    test_spec = LANGUAGE_TESTS.get(ext)
    if test_spec is not None and not run_language_test(test_spec, filename):
        logger.error(
            f"{filename}: autofix broke the test — restoring the original file."
        )
        path.write_bytes(original)
        return False

    if result.returncode != 0:
        detail = (
            result.stdout.decode("utf-8", "replace").strip()
            + "\n"
            + result.stderr.decode("utf-8", "replace").strip()
        ).strip()
        logger.warning(
            f"{filename}: fixed what it could, but issues remain (kept the applied fixes):\n{detail}"
        )
        return False

    logger.info(f"{filename}: Fixed and re-verified.")
    return True


def run_language_lint(ext: str, filename: str, *, fix: bool) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = ROOT / algorithm
    logger.debug(f"Linting {filename}")

    if ext == "cs":
        if not fix:
            try:
                _dotnet_format(
                    algo_dir, basename, verify_only=True, raise_on_error=True
                )
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                _log_subprocess_failure("Lint", filename, e)
                return False
            logger.info(f"{filename}: Passed!")
            return True
        return _run_mutation(
            "Lint",
            filename,
            algo_dir,
            basename,
            ext,
            lambda: _dotnet_format(
                algo_dir, basename, verify_only=False, raise_on_error=False
            ),
        )

    spec = LANGUAGE_LINTS[ext]
    if not fix:
        try:
            _run(spec.check(algo_dir, basename), algo_dir)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            _log_subprocess_failure("Lint", filename, e)
            return False
        logger.info(f"{filename}: Passed!")
        return True

    if spec.fix is None:
        logger.warning(
            f"{filename}: no autofix available for lint, running check instead"
        )
        return run_language_lint(ext, filename, fix=False)

    return _run_mutation(
        "Lint",
        filename,
        algo_dir,
        basename,
        ext,
        lambda: _run_allow_nonzero(spec.fix(algo_dir, basename), algo_dir),
    )


def run_language_format(ext: str, filename: str, *, check: bool) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = ROOT / algorithm
    logger.debug(f"Formatting {filename}")

    if ext == "cs":
        if check:
            try:
                _dotnet_format(
                    algo_dir, basename, verify_only=True, raise_on_error=True
                )
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                _log_subprocess_failure("Format", filename, e)
                return False
            logger.info(f"{filename}: Passed!")
            return True
        return _run_mutation(
            "Format",
            filename,
            algo_dir,
            basename,
            ext,
            lambda: _dotnet_format(
                algo_dir, basename, verify_only=False, raise_on_error=False
            ),
        )

    if ext == "go":
        if check:
            # `gofmt -l` always exits 0, even when it lists a file needing reformatting — a
            # needs-reformatting file is signaled by non-empty stdout instead.
            try:
                result = _run(["gofmt", "-l", basename], algo_dir)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                _log_subprocess_failure("Format", filename, e)
                return False
            if result.stdout.strip():
                logger.error(f"{filename}: Failed! Needs gofmt formatting.")
                return False
            logger.info(f"{filename}: Passed!")
            return True
        return _run_mutation(
            "Format",
            filename,
            algo_dir,
            basename,
            ext,
            lambda: _run_allow_nonzero(["gofmt", "-w", basename], algo_dir),
        )

    if ext == "swift":
        if check:
            try:
                _run_swiftformat(algo_dir, basename, check=True, raise_on_error=True)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                _log_subprocess_failure("Format", filename, e)
                return False
            logger.info(f"{filename}: Passed!")
            return True
        return _run_mutation(
            "Format",
            filename,
            algo_dir,
            basename,
            ext,
            lambda: _run_swiftformat(
                algo_dir, basename, check=False, raise_on_error=False
            ),
        )

    spec = LANGUAGE_FORMATS[ext]
    if check:
        try:
            _run(spec.check(algo_dir, basename), algo_dir)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            _log_subprocess_failure("Format", filename, e)
            return False
        logger.info(f"{filename}: Passed!")
        return True

    return _run_mutation(
        "Format",
        filename,
        algo_dir,
        basename,
        ext,
        lambda: _run_allow_nonzero(spec.apply(algo_dir, basename), algo_dir),
    )


def _run_algorithm_lints(
    algorithm: str, languages: Sequence[str], *, fix: bool
) -> list[bool]:
    """Sequential within one algorithm, same reasoning as `_run_algorithm_tests`: c/cpp/swift
    share one compiled-artifact filename per algorithm directory."""
    results = []
    for ext in languages:
        source_path = ROOT / algorithm / f"{algorithm}.{ext}"
        if not source_path.exists():
            logger.warning(
                f"skipping {algorithm}/{algorithm}.{ext} linting (file not found)"
            )
            continue
        results.append(
            run_language_lint(ext, f"{algorithm}/{algorithm}.{ext}", fix=fix)
        )
    return results


def _run_algorithm_formats(
    algorithm: str, languages: Sequence[str], *, check: bool
) -> list[bool]:
    results = []
    for ext in languages:
        source_path = ROOT / algorithm / f"{algorithm}.{ext}"
        if not source_path.exists():
            logger.warning(
                f"skipping {algorithm}/{algorithm}.{ext} formatting (file not found)"
            )
            continue
        results.append(
            run_language_format(ext, f"{algorithm}/{algorithm}.{ext}", check=check)
        )
    return results


def _run_corpus(targets: Sequence[str], run_one: Callable[[str], list[bool]]) -> bool:
    """Shared per-algorithm-parallel driver for `lint`/`format`, mirroring `test_algorithms`."""
    max_workers = min(12, os.cpu_count() or 4)
    results: list[bool] = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(run_one, algorithm): algorithm for algorithm in targets
        }
        for future in as_completed(futures):
            algorithm = futures[future]
            try:
                results.extend(future.result())
            except Exception:
                logger.exception(f"Unhandled exception while processing {algorithm}")
                results.append(False)
    return all(results)


def lint_algorithms(
    targets: Sequence[str], languages: Sequence[str], *, fix: bool
) -> bool:
    return _run_corpus(targets, lambda a: _run_algorithm_lints(a, languages, fix=fix))


def format_algorithms(
    targets: Sequence[str], languages: Sequence[str], *, check: bool
) -> bool:
    return _run_corpus(
        targets, lambda a: _run_algorithm_formats(a, languages, check=check)
    )


# --------------------------------------------------------------------------------------------
# pack / decode — the ALGZ v1 container format
# (COMPRESSION_DESIGN.md, "Container format")
# --------------------------------------------------------------------------------------------

MAGIC_ALGZ = bytes([0x41, 0x4C, 0x47, 0x5A, 0x0D, 0x0A, 0x1A, 0x0A])
MAGIC_ADTL = bytes([0x41, 0x44, 0x54, 0x4C, 0x0D, 0x0A, 0x1A, 0x0A])

_OUTER_HEADER_FORMAT = "<8sHHIIHHQQQQQ32s"
_INNER_HEADER_FORMAT = "<8sHHIIIQQQQ"
_DIRECTORY_RECORD_HEADER_FORMAT = "<IHHI"
_CONTENT_ENTRY_FORMAT = "<HHQQI"

OUTER_HEADER_SIZE = struct.calcsize(_OUTER_HEADER_FORMAT)
INNER_HEADER_SIZE = struct.calcsize(_INNER_HEADER_FORMAT)
DIRECTORY_RECORD_HEADER_SIZE = struct.calcsize(_DIRECTORY_RECORD_HEADER_FORMAT)
CONTENT_ENTRY_SIZE = struct.calcsize(_CONTENT_ENTRY_FORMAT)

FLAG_DICTIONARY_PRESENT = 1 << 0
FLAG_DICTIONARY_FORMATTED = 1 << 1
FLAG_SHA256_PRESENT = 1 << 2

CONTENT_KIND_DESCRIPTION = 0
CONTENT_KIND_BY_EXTENSION = {
    ext: index + 1 for index, ext in enumerate(LANGUAGE_EXTENSIONS)
}
EXTENSION_BY_CONTENT_KIND = {
    kind: ext for ext, kind in CONTENT_KIND_BY_EXTENSION.items()
}
KIND_LABELS = {CONTENT_KIND_DESCRIPTION: "description", **EXTENSION_BY_CONTENT_KIND}


class PackError(AlgorithmContentError):
    pass


class ArchiveFormatError(AlgorithmContentError):
    pass


def _read_utf8_optional(path: Path) -> bytes | None:
    if not path.exists():
        return None
    data = path.read_bytes()
    try:
        data.decode("utf-8")
    except UnicodeDecodeError as e:
        raise PackError(f"{path} is not valid UTF-8") from e
    return data


@dataclass(frozen=True)
class ContentEntry:
    kind: int
    data: bytes


def _algorithm_entries(algorithm: str) -> list[ContentEntry]:
    algo_dir = ROOT / algorithm
    entries = []
    description = _read_utf8_optional(algo_dir / "description.md")
    if description is not None:
        entries.append(ContentEntry(CONTENT_KIND_DESCRIPTION, description))
    for ext in LANGUAGE_EXTENSIONS:
        data = _read_utf8_optional(algo_dir / f"{ext}.md")
        if data is not None:
            entries.append(ContentEntry(CONTENT_KIND_BY_EXTENSION[ext], data))
    return entries


def _build_payload(algorithms: Sequence[str]) -> tuple[bytes, list[str]]:
    directory = bytearray()
    content = bytearray()
    packed_ids: list[str] = []

    for algorithm in algorithms:
        if not (ROOT / algorithm).is_dir():
            raise PackError(f"no such algorithm directory: {algorithm!r}")
        id_bytes = algorithm.encode("utf-8")
        if not id_bytes or len(id_bytes) > 0xFFFF:
            raise PackError(f"invalid algorithm ID {algorithm!r}")

        entries = _algorithm_entries(algorithm)
        if not entries:
            logger.warning(
                f"skipping {algorithm}: no description.md or highlighted content found"
            )
            continue

        entry_bytes = bytearray()
        for entry in entries:
            offset = len(content)
            content += entry.data
            entry_bytes += struct.pack(
                _CONTENT_ENTRY_FORMAT, entry.kind, 0, offset, len(entry.data), 0
            )

        record_body = (
            struct.pack("<HHI", len(id_bytes), len(entries), 0)
            + id_bytes
            + bytes(entry_bytes)
        )
        directory += struct.pack("<I", len(record_body) + 4) + record_body
        packed_ids.append(algorithm)

    header = struct.pack(
        _INNER_HEADER_FORMAT,
        MAGIC_ADTL,
        1,
        0,
        INNER_HEADER_SIZE,
        0,
        len(packed_ids),
        INNER_HEADER_SIZE,
        len(directory),
        INNER_HEADER_SIZE + len(directory),
        len(content),
    )
    return bytes(header) + bytes(directory) + bytes(content), packed_ids


def _build_outer_envelope(
    frame: bytes, decompressed_length: int, payload_sha256: bytes
) -> bytes:
    return struct.pack(
        _OUTER_HEADER_FORMAT,
        MAGIC_ALGZ,
        1,
        0,
        OUTER_HEADER_SIZE,
        FLAG_SHA256_PRESENT,
        1,
        0,  # codec = zstandard, reserved
        0,
        0,  # no dictionary in v1
        OUTER_HEADER_SIZE,
        len(frame),
        decompressed_length,
        payload_sha256,
    )


@dataclass(frozen=True)
class PackResult:
    archive: bytes
    packed_ids: list[str]
    payload_size: int


def pack_archive(algorithms: Sequence[str], level: int) -> PackResult:
    """Builds an in-memory `.algz` archive from `algorithms`."""
    payload, packed_ids = _build_payload(algorithms)
    compressor = zstandard.ZstdCompressor(
        level=level, write_checksum=True, write_content_size=True, threads=0
    )
    frame = compressor.compress(payload)
    payload_sha256 = hashlib.sha256(payload).digest()
    envelope = _build_outer_envelope(frame, len(payload), payload_sha256)
    return PackResult(envelope + frame, packed_ids, len(payload))


@dataclass(frozen=True)
class OuterEnvelope:
    major: int
    minor: int
    flags: int
    codec: int
    dictionary_offset: int
    dictionary_length: int
    frame_offset: int
    frame_length: int
    decompressed_length: int
    payload_sha256: bytes


@dataclass(frozen=True)
class ContentEntryInfo:
    kind: int
    flags: int
    offset: int  # relative to the start of the content section
    length: int
    reserved: int


@dataclass(frozen=True)
class AlgorithmRecord:
    algorithm_id: str
    flags: int
    entries: tuple[ContentEntryInfo, ...]
    directory_offset: int  # relative to the start of the directory
    record_length: int


@dataclass(frozen=True)
class InnerHeader:
    schema_major: int
    schema_minor: int
    flags: int
    algorithm_count: int
    directory_offset: int
    directory_length: int
    content_offset: int
    content_length: int


@dataclass(frozen=True)
class ParsedArchive:
    envelope: OuterEnvelope
    header: InnerHeader
    payload: bytes
    records: tuple[AlgorithmRecord, ...]

    def content_bytes(self, entry: ContentEntryInfo) -> bytes:
        offset = self.header.content_offset + entry.offset
        return self.payload[offset : offset + entry.length]


def _parse_outer_envelope(raw: bytes) -> OuterEnvelope:
    if len(raw) < OUTER_HEADER_SIZE:
        raise ArchiveFormatError("file shorter than the outer header")
    (
        magic,
        major,
        minor,
        header_length,
        flags,
        codec,
        _reserved,
        dictionary_offset,
        dictionary_length,
        frame_offset,
        frame_length,
        decompressed_length,
        payload_sha256,
    ) = struct.unpack_from(_OUTER_HEADER_FORMAT, raw, 0)
    if magic != MAGIC_ALGZ:
        raise ArchiveFormatError("bad outer magic")
    if major != 1:
        raise ArchiveFormatError(f"unsupported major version {major}")
    if header_length != OUTER_HEADER_SIZE:
        raise ArchiveFormatError("unexpected outer header length")
    if codec != 1:
        raise ArchiveFormatError(f"unsupported codec {codec}")
    if not flags & FLAG_SHA256_PRESENT:
        raise ArchiveFormatError("SHA-256 flag not set")
    return OuterEnvelope(
        major,
        minor,
        flags,
        codec,
        dictionary_offset,
        dictionary_length,
        frame_offset,
        frame_length,
        decompressed_length,
        payload_sha256,
    )


def _decompress_payload(raw: bytes, envelope: OuterEnvelope) -> bytes:
    if envelope.dictionary_offset != 0 or envelope.dictionary_length != 0:
        raise ArchiveFormatError("v1 archive must not declare a dictionary")
    frame = raw[envelope.frame_offset : envelope.frame_offset + envelope.frame_length]
    if len(frame) != envelope.frame_length:
        raise ArchiveFormatError("frame extends past end of file")
    decompressed = zstandard.decompress(
        frame
    )  # raises zstandard.ZstdError on checksum mismatch
    if len(decompressed) != envelope.decompressed_length:
        raise ArchiveFormatError("decompressed length mismatch")
    if hashlib.sha256(decompressed).digest() != envelope.payload_sha256:
        raise ArchiveFormatError("payload SHA-256 mismatch")
    return decompressed


def _parse_directory(directory: bytes) -> tuple[AlgorithmRecord, ...]:
    records = []
    pos = 0
    while pos < len(directory):
        record_length, id_length, entry_count, algorithm_flags = struct.unpack_from(
            _DIRECTORY_RECORD_HEADER_FORMAT, directory, pos
        )
        record = directory[pos : pos + record_length]
        algorithm_id = record[
            DIRECTORY_RECORD_HEADER_SIZE : DIRECTORY_RECORD_HEADER_SIZE + id_length
        ].decode("utf-8")
        entries_bytes = record[DIRECTORY_RECORD_HEADER_SIZE + id_length :]
        entries = tuple(
            ContentEntryInfo(
                *struct.unpack_from(
                    _CONTENT_ENTRY_FORMAT, entries_bytes, i * CONTENT_ENTRY_SIZE
                )
            )
            for i in range(entry_count)
        )
        records.append(
            AlgorithmRecord(algorithm_id, algorithm_flags, entries, pos, record_length)
        )
        pos += record_length
    return tuple(records)


def _parse_inner_payload(
    payload: bytes,
) -> tuple[InnerHeader, tuple[AlgorithmRecord, ...]]:
    if len(payload) < INNER_HEADER_SIZE:
        raise ArchiveFormatError("payload shorter than the inner header")
    (
        magic,
        schema_major,
        schema_minor,
        header_length,
        flags,
        algorithm_count,
        directory_offset,
        directory_length,
        content_offset,
        content_length,
    ) = struct.unpack_from(_INNER_HEADER_FORMAT, payload, 0)
    if magic != MAGIC_ADTL:
        raise ArchiveFormatError("bad inner payload magic")
    if header_length != INNER_HEADER_SIZE:
        raise ArchiveFormatError("unexpected inner header length")
    if content_offset + content_length > len(payload):
        raise ArchiveFormatError("content section extends past payload end")

    header = InnerHeader(
        schema_major,
        schema_minor,
        flags,
        algorithm_count,
        directory_offset,
        directory_length,
        content_offset,
        content_length,
    )
    directory = payload[directory_offset : directory_offset + directory_length]
    return header, _parse_directory(directory)


def parse_archive(path: Path) -> ParsedArchive:
    """Reads, decompresses, and structurally parses an `.algz` archive.

    Verifies the outer header, zstd checksum (via `zstandard.decompress`), and outer SHA-256, but
    does not compare content against the algorithm sources on disk — see `verify_archive` for that.
    """
    raw = path.read_bytes()
    envelope = _parse_outer_envelope(raw)
    payload = _decompress_payload(raw, envelope)
    header, records = _parse_inner_payload(payload)
    return ParsedArchive(envelope, header, payload, records)


def _expected_content_bytes(algorithm: str, kind: int) -> bytes:
    if kind == CONTENT_KIND_DESCRIPTION:
        return (ROOT / algorithm / "description.md").read_bytes()
    ext = EXTENSION_BY_CONTENT_KIND.get(kind)
    if ext is None:
        raise ArchiveFormatError(f"unknown content kind {kind}")
    return (ROOT / algorithm / f"{ext}.md").read_bytes()


def verify_archive(path: Path, expected_algorithms: Sequence[str]) -> None:
    """Re-parses `path` and checks every extracted byte range against the source `.md` files."""
    archive = parse_archive(path)
    seen_ids = [record.algorithm_id for record in archive.records]
    if len(seen_ids) != len(set(seen_ids)):
        raise ArchiveFormatError("duplicate algorithm ID in manifest")
    if seen_ids != list(expected_algorithms):
        raise ArchiveFormatError("manifest algorithm set doesn't match the packed set")
    if archive.header.algorithm_count != len(seen_ids):
        raise ArchiveFormatError("declared algorithm count doesn't match the directory")

    for record in archive.records:
        seen_kinds: set[int] = set()
        for entry in record.entries:
            if entry.kind in seen_kinds:
                raise ArchiveFormatError(
                    f"duplicate content kind {entry.kind} for {record.algorithm_id!r}"
                )
            seen_kinds.add(entry.kind)
            actual = archive.content_bytes(entry)
            expected = _expected_content_bytes(record.algorithm_id, entry.kind)
            if actual != expected:
                raise ArchiveFormatError(
                    f"content kind {entry.kind} for {record.algorithm_id!r} doesn't match source"
                )


def preview_line(data: bytes, limit: int) -> str:
    """First line of `data`, decoded permissively and truncated to `limit` characters."""
    text = data.decode("utf-8", errors="replace")
    first_line = text.splitlines()[0] if text else ""
    if len(first_line) > limit:
        first_line = first_line[: limit - 1] + "…"
    return first_line


OUTER_FLAG_NAMES = {
    FLAG_DICTIONARY_PRESENT: "dictionary",
    FLAG_DICTIONARY_FORMATTED: "dictionary-formatted",
    FLAG_SHA256_PRESENT: "sha256",
}


def describe_flags(flags: int, known: dict[int, str]) -> str:
    """Renders a bitmask as `0x0004 (sha256)`, calling out any bit `known` doesn't name."""
    names = [name for bit, name in known.items() if flags & bit]
    unknown = flags & ~functools.reduce(lambda acc, bit: acc | bit, known, 0)
    if unknown:
        names.append(f"unknown=0x{unknown:x}")
    return f"0x{flags:04x} ({', '.join(names) if names else 'none'})"


def bar(fraction: float, width: int = 24) -> str:
    """A `width`-character block-drawing bar filled to `fraction` (clamped to [0, 1])."""
    filled = round(max(0.0, min(1.0, fraction)) * width)
    return "█" * filled + "░" * (width - filled)


def content_kind_totals(records: Iterable[AlgorithmRecord]) -> dict[int, int]:
    """Total decompressed bytes per content kind, across every record — independent of any
    algorithm-name filter the caller applies for display, since it describes the whole archive.
    """
    totals: dict[int, int] = {}
    for record in records:
        for entry in record.entries:
            totals[entry.kind] = totals.get(entry.kind, 0) + entry.length
    return totals


# --------------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------------


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
def cli() -> None:
    """Algorithm content pipeline: scaffold, highlight, test, lint, format, pack, and decode
    `AlgorithmDetails/`."""
    logger.setLevel(logging.INFO)
    coloredlogs.install(
        level="INFO", logger=logger, fmt="%(asctime)s %(levelname)s %(message)s"
    )


@cli.command("scaffold")
@click.argument("name")
def scaffold_command(name: str) -> None:
    """Create NAME/ from template/."""
    scaffold_algorithm(name)


@cli.command("highlight")
@click.argument("names", nargs=-1)
def highlight_command(names: tuple[str, ...]) -> None:
    """Run Pygments over source, writing <lang>.md files. Defaults to every algorithm."""
    highlight_algorithms(resolve_targets(names))


@cli.command("test")
@click.argument("names", nargs=-1)
@click.option(
    "--languages",
    "-l",
    "languages",
    multiple=True,
    type=click.Choice(LANGUAGE_EXTENSIONS),
    help="Restrict to these languages (default: all).",
)
def test_command(names: tuple[str, ...], languages: tuple[str, ...]) -> None:
    """Compile/run each algorithm's source per language and check output.

    Defaults to every algorithm and every language. Needs the actual toolchains installed
    (clang, javac/java, kotlinc, python3, ruby, swiftc, node, go, dotnet) for whichever
    languages are selected.
    """
    targets = resolve_targets(names)
    passed = test_algorithms(targets, languages or LANGUAGE_EXTENSIONS)
    if passed:
        logger.info("All files compiled and/or run successfully with correct outputs.")
    else:
        logger.error(
            "One or more files compiled and/or run unsuccessfully. Check the log for errors."
        )
        sys.exit(1)


@cli.command("lint")
@click.argument("names", nargs=-1)
@click.option(
    "--languages",
    "-l",
    "languages",
    multiple=True,
    type=click.Choice(LANGUAGE_EXTENSIONS),
    help="Restrict to these languages (default: all).",
)
@click.option(
    "--fix", is_flag=True, help="Apply each language's autofix where one exists."
)
def lint_command(names: tuple[str, ...], languages: tuple[str, ...], fix: bool) -> None:
    """Lint each algorithm's source per language and report findings.

    Defaults to check-only (report, nonzero exit on any finding) across every algorithm and
    language. --fix applies each language's autofix where one exists (clang-tidy, dotnet format,
    eslint, ktlint, ruff, standardrb); languages with no autofix (go vet, swiftlint) just run the
    check instead, with a warning. Every fix is re-verified against 'test' before being kept —
    see manage.py's own 'lint'/'format' section for why. Needs 'uv run manage.py setup' to have
    installed the extra lint/format tooling first.
    """
    targets = resolve_targets(names)
    passed = lint_algorithms(targets, languages or LANGUAGE_EXTENSIONS, fix=fix)
    if passed:
        logger.info("No lint issues found.")
    else:
        logger.error("One or more files have lint issues. Check the log for details.")
        sys.exit(1)


@cli.command("format")
@click.argument("names", nargs=-1)
@click.option(
    "--languages",
    "-l",
    "languages",
    multiple=True,
    type=click.Choice(LANGUAGE_EXTENSIONS),
    help="Restrict to these languages (default: all).",
)
@click.option(
    "--check",
    is_flag=True,
    help="Verify formatting without changing files (nonzero exit if reformatting is needed).",
)
def format_command(
    names: tuple[str, ...], languages: tuple[str, ...], check: bool
) -> None:
    """Format each algorithm's source per language, in place.

    Defaults to applying each language's formatter in place across every algorithm and language.
    --check verifies without changing anything (nonzero exit if a file would be reformatted).
    Every applied change is re-verified against 'test' before being kept, and Swift files
    additionally get a persistent '<file>.swift.bak' backup first — see manage.py's own
    'lint'/'format' section for why. Needs 'uv run manage.py setup' to have installed the extra
    lint/format tooling first.
    """
    targets = resolve_targets(names)
    passed = format_algorithms(targets, languages or LANGUAGE_EXTENSIONS, check=check)
    if passed:
        logger.info(
            "All files are already formatted." if check else "All files formatted."
        )
    else:
        logger.error(
            "One or more files need formatting."
            if check
            else "One or more files could not be cleanly formatted. Check the log for details."
        )
        sys.exit(1)


@cli.command("setup")
def setup_command() -> None:
    """Install every Homebrew-installable dependency 'test'/'lint'/'format' need.

    Covers both the lint/format add-on tools (clang-tidy, checkstyle, google-java-format, ruff,
    eslint, prettier, ktlint, swiftformat, swiftlint) and each language's base compiler/runtime
    that Homebrew can reasonably provide (go, java, node, kotlin, ruby, dotnet via its cask), plus
    the 'standard' Ruby gem. Deliberately excludes Swift's and C/C++'s own compilers
    (swiftc/clang/clang++), which come from Xcode's Command Line Tools — already a precondition
    for building this repository's app at all, and not something Homebrew should manage a second
    copy of. Safe to re-run: already-installed tools (from Homebrew or anywhere else on PATH) are
    skipped.
    """
    setup_tools()


@cli.command("pack")
@click.argument("names", nargs=-1)
@click.option(
    "--output",
    type=click.Path(dir_okay=False, path_type=Path),
    default=ROOT / "AlgorithmDetails.algz",
    show_default=True,
    help="Where to write the archive.",
)
@click.option(
    "--level", type=int, default=19, show_default=True, help="Zstd compression level."
)
@click.option(
    "--no-verify", is_flag=True, help="Skip the post-write self-verification pass."
)
def pack_command(
    names: tuple[str, ...], output: Path, level: int, no_verify: bool
) -> None:
    """Compress description.md + highlighted code into AlgorithmDetails.algz.

    Implements the ALGZ v1 container format (one whole-corpus zstd frame, no dictionary,
    versioned manifest, outer SHA-256 + zstd content checksum) — see
    COMPRESSION_DESIGN.md. Self-verifies by default after writing.
    """
    algorithms = resolve_targets(names)
    result = pack_archive(algorithms, level)
    output.write_bytes(result.archive)

    ratio = result.payload_size / len(result.archive) if result.archive else 0.0
    logger.info(
        f"Wrote {output} ({len(result.archive):,} B from {result.payload_size:,} B payload, "
        f"{ratio:.1f}:1) covering {len(result.packed_ids)} algorithm(s)."
    )

    if not no_verify:
        verify_archive(output, result.packed_ids)
        logger.info(
            "Verification passed: outer header, SHA-256, zstd checksum, and manifest all match source."
        )


@cli.command("decode")
@click.argument("names", nargs=-1)
@click.option(
    "--input",
    "archive_path",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    default=None,
    help="Archive to decode (default: AlgorithmDetails.algz next to this script).",
)
@click.option(
    "--preview-length",
    type=int,
    default=80,
    show_default=True,
    help="Max characters of each content entry's first line to print.",
)
def decode_command(
    names: tuple[str, ...], archive_path: Path | None, preview_length: int
) -> None:
    """Print a packed archive's structure: envelope, manifest, and every content entry's
    internal header fields, with a size bar and a one-line preview instead of full content.

    A low-level sanity check that `pack` produced the expected byte layout — not just that the
    content matches, but where every section, record, and entry actually lives in the file.
    Defaults to every algorithm in the archive.
    """
    path = archive_path or (ROOT / "AlgorithmDetails.algz")
    archive = parse_archive(path)
    envelope, header = archive.envelope, archive.header
    wanted = set(names) or None

    archive_size = OUTER_HEADER_SIZE + envelope.frame_length
    compression_ratio = (
        envelope.decompressed_length / archive_size if archive_size else 0.0
    )
    click.secho(f"{path.name} — ALGZ v{envelope.major}.{envelope.minor}", bold=True)
    click.echo(
        f"  outer header     {OUTER_HEADER_SIZE:>10,} B  flags={describe_flags(envelope.flags, OUTER_FLAG_NAMES)}  codec={envelope.codec} (zstd)"
    )
    if envelope.dictionary_length:
        click.echo(
            f"  dictionary       {envelope.dictionary_length:>10,} B  @ offset {envelope.dictionary_offset:,}"
        )
    else:
        click.echo("  dictionary                   —  (none)")
    click.echo(
        f"  frame            {envelope.frame_length:>10,} B  @ offset {envelope.frame_offset:,}"
    )
    click.echo(
        f"  decompressed     {envelope.decompressed_length:>10,} B  sha256={envelope.payload_sha256.hex()}"
    )
    click.echo(
        f"  compression      {envelope.decompressed_length:,} B -> {archive_size:,} B  ({compression_ratio:.1f}:1)"
    )

    click.secho(
        f"\ninner payload — ADTL v{header.schema_major}.{header.schema_minor}",
        bold=True,
    )
    click.echo(
        f"  header           {INNER_HEADER_SIZE:>10,} B  flags={describe_flags(header.flags, {})}"
    )
    click.echo(
        f"  algorithms       {header.algorithm_count:>10,}    declared ({len(archive.records)} record(s) found)"
    )
    click.echo(
        f"  directory        {header.directory_length:>10,} B  @ offset {header.directory_offset:,}"
    )
    click.echo(
        f"  content          {header.content_length:>10,} B  @ offset {header.content_offset:,}"
    )

    totals = content_kind_totals(archive.records)
    total_bytes = sum(totals.values()) or 1
    click.secho("\nContent composition (decompressed bytes, by kind):", bold=True)
    for kind in sorted(totals, key=lambda k: -totals[k]):
        label = KIND_LABELS.get(kind, f"kind {kind}")
        size = totals[kind]
        click.echo(
            f"  {label:<12} {bar(size / total_bytes)}  {size:>12,} B  ({size / total_bytes:.1%})"
        )

    shown = 0
    for record in archive.records:
        if wanted is not None and record.algorithm_id not in wanted:
            continue
        shown += 1
        click.secho(f"\n{record.algorithm_id}", fg="cyan", bold=True)
        click.echo(
            f"  record {record.record_length:,} B @ directory offset {record.directory_offset:,}, "
            f"{len(record.entries)} entr{'y' if len(record.entries) == 1 else 'ies'}, "
            f"flags={describe_flags(record.flags, {})}"
        )
        largest = max((entry.length for entry in record.entries), default=1) or 1
        for entry in record.entries:
            label = KIND_LABELS.get(entry.kind, f"kind {entry.kind}")
            preview = preview_line(archive.content_bytes(entry), preview_length)
            click.echo(
                f"  [{entry.kind:>2}] {label:<12} flags={describe_flags(entry.flags, {})}  "
                f"content_offset={entry.offset:>10,}  length={entry.length:>9,} B  "
                f"reserved={entry.reserved}"
            )
            click.echo(f"       {bar(entry.length / largest)}  {preview}")

    if wanted is not None and shown == 0:
        raise AlgorithmContentError(f"none of {sorted(wanted)!r} were found in {path}")


if __name__ == "__main__":
    cli()
