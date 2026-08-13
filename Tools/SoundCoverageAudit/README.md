# Sound Coverage Audit

Dev-tool only — **never built into or shipped with the app**. Answers "how much of this
algorithm's recorded tape is silence?" by parsing exported `.tape` archives directly, offline.

## Setup

```sh
cd Tools/SoundCoverageAudit
uv sync
```

## Populating a directory of tapes

Set `SORT_TAPE_EXPORT_DIR=sort-tape-audit` (a bare name, **not** an absolute path — see below) as
an environment variable on the app's run scheme (Xcode → Edit Scheme → Run → Arguments →
Environment Variables), then run a full Showcase pass — the in-app Showcase button, or the "Run
Showcase" Shortcut (`RunShowcaseIntent`). `SortSession.exportTapeForAuditIfRequested`
(`Modules/SortFeature/Sources/SortSession.swift`) writes one `<algorithmID>.tape` file per
completed run into that directory; a full Showcase pass produces one file per registered
algorithm. The hook is a no-op (a single environment lookup) whenever the variable isn't set, so
it costs nothing in normal use.

**Why a bare name, not a path**: the app is sandboxed (`com.apple.security.app-sandbox`) with no
broad file-system entitlement, so it can only ever write inside its own container — an arbitrary
absolute path (`/tmp/...`, a path under your home directory, anywhere outside the container) is
silently denied regardless of whether it exists. Only the *last path component* of whatever you
set is honored, as a subfolder of the app's own Documents directory — which resolves to
`~/Library/Containers/com.nhubbard.Sort2.mobile/Data/Documents/<name>` on disk. If exports seem to
be missing, check `Console.app` for the `com.nhubbard.Sort2.mobile` subsystem, `TapeExport`
category — every export logs its outcome (success with the full path, or the specific error).

## Running

```sh
uv run audit_sound_coverage.py
```

(defaults to the container path above; pass a directory explicitly to audit anything else)

Prints one row per tape — total operations, audible percentage (`.compare`/`.swap`/`.setValue`
only, matching `SortOperation.isAudible`), and the longest silent streak in both operation-count
and seconds (at `--speed` ops/sec, default 30 — matches `AppSettings`/`ReplayEngine`'s own
default) — sorted worst (longest gap) first.

Options:

- `--speed <ops/sec>` — override the default 30 ops/sec used to convert gaps to seconds.
- `--include-shuffle` — audit the full shuffle+sort tape instead of just the sort portion (the
  default, since "how does *the algorithm* sound" is about the sort, not the shuffle preceding it).

## Format

Reimplements `Modules/SortEngineKit/Sources/{Tape+Archive,TapeArchiveEnvelope,
TapeArchivePayload}.swift`'s binary format directly (the "STAP" envelope, zstd frame, SHA-256
check, "TAPE" payload) rather than depending on anything from the app — see
`audit_sound_coverage.py`'s own comments for the byte-level mapping. If that Swift format ever
changes, this parser needs the equivalent update by hand.
