# 2026-10-04 coverage baseline

`baseline.json` and `baseline.md` are the merged output of `report.py` for the production
snapshot in `source-manifest.json`. The snapshot was taken on `dev` at
`af3fee65c7f617474335fde196840b1da722d459` after `tuist generate`, using Xcode 27.0
(27A266a) and Tuist 4.210.0. Its Git dirty flag reflects the existing untracked shuffle
analysis; the report verified every production-source hash before merging coverage.

The 24 measured result bundles comprise 19 passing Mac Catalyst module suites, a passing
Mac Catalyst AUv3 extension component suite, two focused iPad UI suites, and two focused
iOS 27 App Intents suites. Their verified summaries report **759 passing tests, six skips,
and no failures**. The temporary `.xcresult` locations and individual test counts are in
`baseline.json`; the bundles are not checked into Git. The one-off shuffle similarity probe
was explicitly skipped in the BuiltInAlgorithms suite.

The app-owned source-line union is **35,641/37,779 (94.34%)**. The extension UI files now
have coverage records: AUv3Extension is 101/159 (63.52%). Fourteen production Swift files
have no records. The iOS-only total is partial because module suites ran on Catalyst.
The 860/1,262 changed executable lines covered (68.15%) are relative to the prior baseline's
revision, `1f3837138d6c003e37af65566f740546a96b5f36`. This changed-line result is a
diagnostic for the focused lanes, not a full platform regression gate.

The [2026-10-02 baseline](../2026-10-02/README.md) used broader UI and App Intents selections
and measured a smaller source tree. Its 95.13% union cannot be compared directly with 94.34%
as a coverage regression. The 2026-10-04 full iPad UI attempt stalled before finalizing a
result bundle. The full App Intents log showed 20 passing tests but Xcode did not finalize its
bundle. Two Catalyst UI attempts failed while enabling automation, before executing tests.
Those attempts are excluded from the measured report. Earlier contract result bundles remain
the behavioral evidence for the 35 completed functional contracts.

To regenerate this report from the saved bundles, take a fresh `report.py snapshot` of the
same production sources and call `report.py report --manifest ... --verify-tests
--changed-base 1f3837138d6c003e37af65566f740546a96b5f36`, passing each
`PLATFORM/LANE=XCRESULT` entry under `results` in `baseline.json` as `--result`. The source
snapshot and passing summaries are mandatory; the reporter rejects stale source or failed
bundles. Run `python3 -m unittest test_report.py` from `Tools/TestCoverage` to check the
reporter's merge and target-mapping rules.
