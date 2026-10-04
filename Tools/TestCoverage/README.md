# Coverage runner

`run.sh` runs selected Xcode test lanes and saves `.xcresult` bundles, a production-source hash
snapshot, `coverage.json`, and a readable `coverage.md` in one output directory. Use a new output
directory for each run.
It records failed test lanes in `failed-lanes.txt`, continues the remaining lanes, and exits
nonzero if any lane failed. Mac Catalyst UI tests are a known
Xcode exception: they can pass while their `.xcresult` lacks `Metadata.plist` for the coverage
archive. The runner records that lane as a passing **behavioral-only** result, never as zero
coverage or as a valid measured lane.

```sh
Tools/TestCoverage/run.sh --output /private/tmp/sort-coverage-2026-10-02 \
  --modules --ipad <iPad-simulator-ID> \
  --catalyst-ui --development-team <Apple-team-ID> \
  --intents <iOS-27-iPad-simulator-ID> \
  --signing-identity <Apple-Development-identity-SHA1>
```

The Catalyst UI lane needs a local Apple Development identity and macOS UI automation permission.
The App Intents lane additionally needs the signed iOS 27 runner described in
`Documentation/docs/guides/building.md`. A complete run can take a long time; specify only the
lanes needed for local diagnosis, then run all required lanes for a release baseline.

For saved bundles, `report.py report` can merge app-owned *source-line identities* directly:

```sh
python3 Tools/TestCoverage/report.py report \
  --result catalyst/engine=/path/to/SortEngineKit.xcresult \
  --result ios/ipad-ui=/path/to/ipad-ui.xcresult \
  --output /private/tmp/coverage.json
```

Use `report.py snapshot --output /path/to/sources.json` before testing, then pass
`--manifest /path/to/sources.json` to the report command. It verifies that production source
hashes have not changed. A report without the snapshot is explicitly marked unverified. The
snapshot establishes source identity for the runner's own result bundles; Xcode results imported
from elsewhere cannot independently prove which uncommitted source tree built them.
`run.sh` also passes `--verify-tests`, which rejects a result bundle unless Xcode reports that
its tests passed. Use the same flag when making a release report from saved bundles.

The JSON provides a cross-platform source-line union, separate iOS and Catalyst totals, per-target
and per-file totals, uncovered line numbers and functions, and result provenance. These values use
unique source lines, so they need not equal `xccov`'s target summary, which can count repeated
instrumented regions on the same source line. Production Swift files under `App/Sources/`,
`App/AUv3Extension/Sources/`, and `Modules/*/Sources/` form the app-owned scope. Dependency,
generated, tooling, and test files are excluded. Read each platform total alongside the union:
conditional code at the same line may compile differently on iOS and Catalyst.
`unmeasuredSources` lists production Swift files with no coverage records, including a platform
extension that has not yet been exercised by a host test.

The [2026-10-04 baseline](baselines/2026-10-04/README.md) records the latest source-verified
measurement and its lane limits. The [2026-10-02 baseline](baselines/2026-10-02/README.md)
retains the earlier full UI and App Intents run for comparison.
