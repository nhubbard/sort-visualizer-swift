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

Local management-token and schema reference files sit alongside this script and are git-ignored
(see `.gitignore` here). A private-database CLI user token expires and must be refreshed from
CloudKit Console's Settings > Tokens > User Token. Save the freshly copied value in `.user-token`
and run `chmod 600 .user-token`; never commit it. On a fresh machine, `cktool` can alternatively
save tokens in the keychain:

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
groups were cleared. A fresh complete scan found 819 remaining cap-exceeded records and zero
above current maxima; a fresh Production Big-O scan found zero records. All 180 approved
Development Big-O groups were re-queried empty. The subsequent full scan fetched 128,457
records and found one new above-maximum `adaptivegrailsort` record outside the frozen approved
set, apparently uploaded later from old local history. After separate approval, that exact
record was deleted. A normal Catalyst relaunch and a second complete scan found 128,456 Big-O
records with zero above maximum; a delayed-upload query remained empty. The fresh Development
cap-exceeded scan found 819 records with zero above maximum, and Production Big-O had zero
records. See the dated review for the record's timestamps and verification details. Refresh
`.user-token` from the Console when CloudKit reports token expiry.

The approved candidate sets can be resumed with `execute_reviewed_cleanup.py`. It checks the
frozen cache fingerprint, compares each algorithm's current matching record names to the
approved set, deletes that group, and re-queries until empty. The first run copies each
reviewed cache to the ignored `.cache/approved/` directory so a later `--refresh` scan cannot
erase the approved record-name list. It is safe to re-run after a partial deletion or an
ambiguous `retry-needed` response. The runner defaults to one worker because CloudKit
throttled parallel deletion.

The durable log in `.cache/development-bigo-cleanup.log` verifies the first 137 groups as a
contiguous successful prefix and the subsequent 43 groups as a successful resumed pass.
`--start-at` avoids spending a refreshed token's lifetime rechecking that prefix. A full fresh
scan still covers every algorithm after deletion.

```sh
uv run execute_reviewed_cleanup.py --record-type CD_BigORecord --token-file .user-token
```

The 2026-10-04 resumed pass used the verified 137-group prefix:

```sh
uv run execute_reviewed_cleanup.py --record-type CD_BigORecord --token-file .user-token --start-at simplifiedlibrarysort
```

```sh
uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord
```

If `cktool` still reports an expired session after `save-token`, pass the fresh CLI user token
through `--token-file .user-token`. The script passes it directly to each `cktool` invocation
and redacts it from command diagnostics.

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

For final verification, refresh the two Development scans and the Production Big-O scan after
the reviewed cleanup finishes. The `--execute` option on `cleanup_stale_sizes.py` is a slower
one-record-at-a-time fallback; use the fingerprint-checked runner above for the approved
Development candidate sets.

```sh
uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord --token-file .user-token --refresh
uv run cleanup_stale_sizes.py --environment development --record-type CD_RecordingCapExceededRecord --token-file .user-token --refresh
uv run cleanup_stale_sizes.py --environment production --record-type CD_BigORecord --token-file .user-token --refresh
```
