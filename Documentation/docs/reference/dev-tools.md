# Dev tools

Every tool on this page is developer-only. None is built into or shipped with the app. None runs
automatically as part of a normal build. Each is a separate `uv`-managed Python project with its
own pinned `pyproject.toml`/`uv.lock`.

## `Tools/GenerateThemes`

This tool regenerates all 56 of `DesignSystemKit`'s syntax-highlighting themes
(`Modules/DesignSystemKit/Sources/Themes/*.swift`) directly from Pygments style data. No theme is
hand-written.

```sh
cd Tools/GenerateThemes
uv run generate_themes.py
```

The original hand-copied themes had drifted from upstream Pygments over time. For example,
Monokai's actual operator color is `#FF4689`, not the `#F92672` every hand-copied theme had
hard-coded. This script reads each style's fully cascaded token colors from Pygments' public
export mechanism (`HtmlFormatter(style:).get_style_defs()`), then prunes any token whose resolved
color matches its parent's. This produces the sparse, cascade-friendly table
`CodeAttributes.Value.parent`'s runtime lookup expects (see
[Services → DesignSystemKit](../architecture/services.md#designsystemkit-shared-ui-and-the-syntax-highlighting-theme-system)).
A theme declares only the tokens it diverges on, instead of listing every leaf that shares a
parent's color.

One performance detail matters if you edit the generator: colors are emitted as references to a
`private static let` hex constant, never as a runtime `Color(fromHex: "...")!` string parse. A
profiling pass found that string-parsing path dominating CPU during a full Showcase or Full Sweep
run, from the same handful of hex literals being re-parsed on every per-token style lookup.

This tool is separate from `App/Resources/AlgorithmDetails/manage.py` by design. That pipeline
scopes to per-algorithm content; this one scopes to app-wide styling. The two tools share no CLI,
even though both use Pygments.

## `Tools/SoundCoverageAudit`

This tool answers "how much of this algorithm's recorded tape is actually audible, and where are
the longest silent gaps?" by parsing exported `.tape` archives directly, offline. It requires no
live app interaction once the tapes exist.

To populate a directory of tapes:

1. Set `SORT_TAPE_EXPORT_DIR` as an environment variable on the app's run scheme. Use a bare name,
   not an absolute path. The app is sandboxed with no broad filesystem entitlement, so only the
   last path component is honored, as a subfolder of the app's own Documents directory.
2. Run a full Showcase pass, either in-app or through the "Run Showcase" Shortcut.
   `SortSession.exportTapeForAuditIfRequested` writes one `<algorithmID>.tape` file per completed
   run, so a full Showcase pass produces one file per registered algorithm.

If an expected export does not appear on disk, check `Console.app`'s `com.nhubbard.Sort2.mobile`
subsystem, `TapeExport` category.

To run the audit:

```sh
cd Tools/SoundCoverageAudit
uv sync
uv run audit_sound_coverage.py                    # defaults to the app's container path
uv run audit_sound_coverage.py --speed 30          # override ops/sec used to convert gaps to seconds
uv run audit_sound_coverage.py --include-shuffle   # audit the full tape, not just the sort portion
```

The output prints one row per tape: total operations, audible percentage, and the longest silent
streak in both operation count and seconds, sorted worst (longest gap) first.

This tool reimplements the `.tape` binary format (see
[Compression formats](compression.md#exported-tape-files-stap-tape)) directly in Python. It does
not depend on the Swift app. If that format changes, update this parser by hand to match.

## Full Sweep (`CoverageSweepDriver`)

This is not a separate Python tool. It runs inside the app itself, in Swift. Full Sweep drives
every registered algorithm against every shuffle and every visualizer at least once: the full
cross product, 115,230 combinations at current registry sizes (167 algorithms × 46 shuffles × 15
visualizers; see [Content layer](../architecture/content.md)), with real animated playback. Use it
to generate a large, uniform batch of analytics data, or to soak-test a change that could affect
many combinations at once, such as a shared Metal shader change or a `RecordingEngine` change.

An append-only TSV log makes the sweep resumable, so it does not need to run start to finish in one
sitting. `CoverageSweepEnumerator` — the pure, registry-agnostic enumeration logic, factored out
specifically for unit testing against small synthetic ID lists instead of the full real registries
— finds the first combination not yet present in the log and continues from there. Start it from
the in-app automation menu or the "Run Full Size Sweep" Shortcut/App Intent.
