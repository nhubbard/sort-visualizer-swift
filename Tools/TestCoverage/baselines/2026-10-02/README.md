# 2026-10-02 coverage baseline

`baseline.json` and `baseline.md` are the output of `report.py` for one production-source
snapshot (`source-manifest.json`). The 22 result bundles were generated with Xcode 27.0 and Tuist
4.210.0 on the current dirty checkout: 19 Mac Catalyst module test bundles, the iPad UI bundle,
the iOS 27 App Intents system bundle, and a full Mac Catalyst UI bundle. They contain 755 passing
tests and 11 platform or configuration skips. The original `.xcresult` paths are recorded in the
JSON; they remain under `/private/tmp` and are not checked into Git. The full runner logged no
failed lanes; this baseline is its direct output from one source snapshot.

The measured app-owned source-line union is **34,995/36,785 (95.13%)**. Of 63 changed
executable lines relative to `HEAD`, 58 are covered (92.06%). This percentage describes files that Xcode
instrumented in these lanes. Sixteen production Swift files have no coverage record, including
both AUv3 extension view files. The extension is therefore an explicit measurement and functional
gap, even though the measured aggregate exceeds 90%. The iOS-only platform total is partial
because module test suites ran on Catalyst. Read the per-target and unmeasured lists in the
report before using the aggregate as a release gate.

The UI and App Intents suites verify user-facing behavior, while the module suites supply most
of the app-owned line coverage. Mac Catalyst UI results are behavioral only because Xcode 27
does not produce a readable coverage archive for that UI runner (`Metadata.plist` is missing).
The Catalyst suite passes its native tape save/import/replay and corrupt-import journeys. The
five uncovered changed lines are the `ContentView` file-importer callback, which is exercised by
those Catalyst UI tests but cannot be attributed without the missing coverage archive.
