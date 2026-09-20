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
(`RecordingEngine.defaultOperationCap`) as the "any real recording above this is stale" line.
All 177 algorithms have a computed value at that cap (checked directly — no fallback needed).

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

```sh
uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord
```

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
entirely and reuses the cached eligible list. Pass `--refresh` to ignore any cached/resumable
state and force a fully fresh fetch. `--execute` removes each successfully-deleted record from
the cache as it goes too, so a delete run that dies partway through can also just be re-invoked —
it'll only retry the stragglers.

Three invocations total, development first (`CD_RecordingCapExceededRecord` doesn't exist in
production — see above):

```sh
uv run cleanup_stale_sizes.py --environment development --record-type CD_BigORecord --execute
uv run cleanup_stale_sizes.py --environment development --record-type CD_RecordingCapExceededRecord --execute
uv run cleanup_stale_sizes.py --environment production --record-type CD_BigORecord --execute
```
