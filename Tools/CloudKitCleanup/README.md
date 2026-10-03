# CloudKit stale-size cleanup

Dev-tool only, one-time use — not shipped, not run by CI.

Before the `RecordingEngine`-bypass fix (git commit `7389974`), several algorithms' growth
models badly underestimated their real cost, so `AlgorithmMetadata.effectiveSizeRange(operationCap:)`
returned safe-looking sizes far larger than the algorithm's own declared `sizeRange` — e.g.
`asynchronoussort` at n=8192 instead of a sane few hundred. Real recordings made at those sizes
got synced to CloudKit via `AnalyticsService` (`BigORecord`/`RecordingCapExceededRecord`, private
database, `iCloud.com.nhubbard.Sort2.mobile`), so that stale history now needs a one-time
cleanup in both the Development and Production CloudKit environments.

## Threshold

Per-algorithm, not a flat cutoff: `cleanup_stale_sizes.py` reads
`Tools/GrowthModelCalibration/output/sort-growth-models.json` and, for each algorithm, takes its
`safeMaxSizeByCap` entry at the app's default 300,000-operation cap
(`RecordingEngine.defaultOperationCap`), then applies the same 8,192-element clamp and
step-size rounding as `AlgorithmMetadata.effectiveSizeRange(operationCap:)`. This is the actual
maximum a user can select. All 196 current algorithms have a computed value at that cap; the tool
refuses to run if calibration or source metadata is missing.

## Setup (one-time, per machine)

Already done on this machine — `.management-token`/`.user-token` (save-token output, keychain-
backed) and `.team-id`/`.dev-schema`/`.prod-schema` (reference dotfiles) sit alongside this
script, all git-ignored (see `.gitignore` here — never commit these). On a fresh machine:

```sh
xcrun cktool save-token --type management   # CloudKit Console > your team > API Access
xcrun cktool save-token --type user         # CloudKit Console > container > Tokens (web sign-in
                                             # as the same iCloud account the app syncs under)
xcrun cktool get-teams                      # confirm --team-id (676UP3S3AH), already the script default
```

## Schema — confirmed against `.dev-schema`/`.prod-schema`

`CD_BigORecord` / `CD_algorithmID` (STRING) / `CD_arraySize` (INT64) / zone
`com.apple.coredata.cloudkit.zone` are all confirmed correct (script defaults match). One real
asymmetry: **`CD_RecordingCapExceededRecord` exists in Development only** — it's absent from the
Production schema export entirely, so don't run this script against it in production (nothing to
clean up there; the record type doesn't exist). Both schemas also list `RunRecord`/`Users`
record types that no current code path writes to — legacy, out of scope for this cleanup.

## Usage

The complete read-only scans from 2026-10-02 are recorded in the
[Development dry-run review](reports/2026-10-02-development-dry-run.md). They found 262,700
Big-O and 5,479 cap-exceeded entries above current selectable maxima in Development, and no
Big-O entries in Production. After explicit approval, all 69 Development cap-exceeded algorithm
groups were cleared and verified empty. Development Big-O cleanup is partly complete; CloudKit
began returning `too-many-requests` and the CLI user token expired. A fresh token and final
scan are still required. The older `.user-token` file dated 2026-08-29 is rejected by CloudKit;
replace it with a newly copied Console CLI User Token before resuming.

The approved candidate sets can be resumed with `execute_reviewed_cleanup.py`. It checks the
frozen cache fingerprint, compares each algorithm's current matching record names to the
approved set, deletes that group, and re-queries until empty. The first run copies each
reviewed cache to the ignored `.cache/approved/` directory so a later `--refresh` scan cannot
erase the approved record-name list. It is safe to re-run after a partial deletion or an
ambiguous `retry-needed` response. The runner defaults to one worker because CloudKit
throttled parallel deletion.

```sh
uv run execute_reviewed_cleanup.py --record-type CD_BigORecord --token-file .user_token
```

```sh
uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord
```

If `cktool` still reports an expired session after `save-token`, use a fresh CloudKit Console
CLI user token in a private local file and pass `--token-file .user_token`. The script passes it
directly to each `cktool` invocation and redacts it from command diagnostics. Keep the file out
of Git and restrict its permissions (`chmod 600 .user_token`).

Defaults to a dry run: fetches every record of the given type (first run only — see caching
below), prints a diff-style summary of what would be deleted (grouped by algorithm, with counts
and the threshold each exceeded), and does **not** delete anything. Review that output. Only then
add `--execute` to actually delete, one `delete-record` call per matching record (not
`delete-records --filters`, since the per-algorithm threshold table can't be expressed as a
single CloudKit filter predicate).

**Caching**: the full fetch is slow (tens of thousands of records, ~200/page, one `cktool`
subprocess call per page — not a stream) and shows a live `tqdm` progress counter (indeterminate
total, since cktool has no count-only query). Progress is written to
`.cache/<environment>__<record-type>.json` after **every page**, not just once at the end —
each write includes CloudKit's `continuationToken` alongside the eligible-for-deletion list found
so far. If the script is killed or crashes mid-fetch (114k+ records took a while to page through
the first time this was tried), just re-invoke it with the same arguments: it resumes from the
last saved `continuationToken` instead of restarting from page 1. Once a fetch actually finishes
(`continuationToken` reaches `null`), a later invocation for the same pair skips the network
entirely and reuses the cached eligible list. A cache made before the current threshold digest
safeguard, or after any threshold changes, is rejected. Pass `--refresh` to force a fresh fetch.
`--execute` removes each successfully-deleted record from
the cache as it goes too, so a delete run that dies partway through can also just be re-invoked —
it'll only retry the stragglers.

Three invocations total, development first (`CD_RecordingCapExceededRecord` doesn't exist in
production — see above):

```sh
uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord --execute
uv run cleanup_stale_sizes.py --environment development --record-type CD_RecordingCapExceededRecord --execute
uv run cleanup_stale_sizes.py --environment production --record-type CD_BigORecord --execute
```
