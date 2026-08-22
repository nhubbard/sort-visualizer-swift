# Compression formats

`ZstdKit` (`Modules/ZstdKit/`) is a Zstandard codec written in Swift: a decoder and an encoder,
with no C/C++ interop. It backs two unrelated binary formats, used by two unrelated features. This
page explains why both codec directions exist, documents each format, and covers the performance
work and scope decisions behind the implementation.

## Why a decoder and an encoder

A module containing both a decoder and an encoder can look like unused scope. It is not. The two
directions were built at different times, for different consumers, and neither could substitute
for the other.

| | Decoder | Encoder |
|---|---|---|
| Consumes or produces | `AlgorithmDetails.algz`: every algorithm's description and syntax-highlighted code samples | An exported `.tape` file: a user's recorded sort or shuffle run |
| Built | First (`ZstdKit`'s original scope) | Later, on request, after decode-only had already shipped |
| Where the bytes are produced | Offline, by a Python pipeline (`manage.py pack`, using the `zstandard` PyPI package) | On-device, at export time, by the app itself |
| Where the bytes are consumed | On-device, at runtime, by `AlgorithmDetailStore` | On-device, at import time, by `Tape(archivedData:)` |

The archive the app ships (`AlgorithmDetails.algz`) only needs to be read by the running app. A
Python tool generates it once, offline, and the build bundles it as an ordinary resource.
Decode-only satisfied this requirement completely.

Binary tape export and import (`Tape.archived()`/`Tape(archivedData:)`, letting a user share a
recorded run out and import one back in) is a different problem. It must run on-device,
synchronously, with no Python interpreter or `zstandard` package available at runtime. This
requirement forced a Swift-native Zstandard encoder. No way exists to satisfy "export compressed
tapes with zero external toolchain dependency" using the decoder alone.

Summary: the decoder exists because the app only reads algorithm content. The encoder exists
because the app writes tape exports. Both share one Zstandard implementation because that was the
efficient way to build both, not because one format needed the other's capability.

### The encoder's correctness bar exceeds self-round-trip

The encoder writes bytes a real Zstandard decoder must accept — either someone importing an
exported `.tape` file, or `ZstdKit`'s own decoder reading it back. For this reason,
`Zstd.decompress(try Zstd.compress(x)) == x` is necessary but not sufficient. A writer and reader
can agree on an internally consistent bit convention that is still wrong relative to what a real,
independent Zstandard implementation produces or accepts. Self-round-trip cannot distinguish that
case from a correct encoding. Verification instead cross-checks against the real `zstandard` PyPI
package, and for diagnostics beyond a generic "data corruption detected," against a debug build of
the real C `zstd` library with verbose internal tracing enabled.

This extra rigor caught two real bugs that neither self-round-trip nor early unit tests exposed:

- An FSE table encoder wrote one extra padding byte beyond the exact bit count consumed, silently
  desynchronizing whichever table description came next in the same buffer. This bug was invisible
  until a test exercised multiple tables back to back; the first single-table tests had no "next
  table" for the desync to corrupt.
- A bit writer placed a required sentinel bit and end-of-stream padding in a different byte
  arrangement than real zstd's own bit writer. This arrangement was internally self-consistent —
  every round-trip test passed, every decoded value was correct — but it violated a real decoder's
  exact end-of-stream check. It reproduced only with a complete block containing genuine
  variable-width payload data, not a small hand-built test case.

Both bug classes are now caught unconditionally by the Swift test suite. A strict end-of-stream
check runs after every decode, rather than relying on a one-time comparison against the C oracle.

## `AlgorithmDetails.algz`: `ALGZ` / `ADTL`

One file, `App/Resources/AlgorithmDetails/AlgorithmDetails.algz`, built as one whole-corpus zstd
frame rather than per-algorithm files. A whole-corpus frame measurably beats every per-algorithm
framing option, including per-algorithm-plus-trained-dictionary: the entire corpus fits inside
zstd's window, so the token-vocabulary redundancy across every algorithm's content compresses away
for free. All multibyte integers in the format are unsigned little-endian.

**Outer envelope** (96 bytes, outside the zstd frame):

| Field | Type | Meaning |
|---|---|---|
| Magic | 8 bytes | `41 4C 47 5A 0D 0A 1A 0A` (`ALGZ` plus CR LF SUB LF, mirroring PNG's corruption-detecting magic) |
| Major / minor version | `UInt16` × 2 | Breaking / compatible format version |
| Header length | `UInt32` | Total outer-header length, including extension bytes |
| Flags | `UInt32` | In v1, bit 2 (payload SHA-256 present) is set; all other bits are clear |
| Codec | `UInt16` | `1` for Zstandard |
| Dictionary offset / length | `UInt64` × 2 | Always zero in v1; this archive never uses a dictionary |
| Frame offset / length | `UInt64` × 2 | Location of the zstd frame |
| Decompressed length | `UInt64` | Expected full payload size |
| Payload SHA-256 | 32 bytes | Digest of the complete decompressed payload |

**Inner payload header** (56 bytes, the first bytes of the decompressed zstd output):

| Field | Type | Meaning |
|---|---|---|
| Payload magic | 8 bytes | `41 44 54 4C 0D 0A 1A 0A` (`ADTL` plus CR LF SUB LF) |
| Schema major / minor | `UInt16` × 2 | Manifest version |
| Algorithm count | `UInt32` | The exact directory-record count the parser walks; it never scans to the end of the buffer |
| Directory offset / length | `UInt64` × 2 | |
| Content offset / length | `UInt64` × 2 | |

**Algorithm directory records** (12-byte fixed header per record, records placed back to back,
followed by their variable-length data):

| Field | Type | Meaning |
|---|---|---|
| Record length | `UInt32` | Full record length, including this header, the algorithm ID, and all content entries |
| Algorithm ID length | `UInt16` | Byte length of the UTF-8 algorithm ID that follows |
| Entry count | `UInt16` | Number of content entries that follow the algorithm ID |
| Algorithm flags | `UInt32` | Reserved, always `0` in v1 |
| Algorithm ID | variable, `Algorithm ID length` bytes | UTF-8, unique, nonempty, compared as exact bytes with no Unicode normalization |
| Content entries | variable, `Entry count` × 24 bytes | See "Content entries" below |

Algorithm IDs are deterministically sorted; the packer emits directory records in that sorted
order.

**Content entries** (24 bytes fixed, one per entry, placed back to back inside a directory
record):

| Field | Type | Meaning |
|---|---|---|
| Content kind | `UInt16` | See the content-kind table below |
| Entry flags | `UInt16` | Bit 0: required (an unrecognized kind with this bit set is an error, not a skip). All other bits reserved |
| Content offset | `UInt64` | Byte offset, relative to the start of the content section |
| Content length | `UInt64` | Byte length of this entry's content |
| Reserved | `UInt32` | Always `0` in v1 |

Content-kind values are stable once assigned:

| Kind | Content |
|---:|---|
| `0` | Description Markdown |
| `1` | Highlighted Markdown, Python |
| `2` | Highlighted Markdown, JavaScript |
| `3` | Highlighted Markdown, Go |
| `4` | Highlighted Markdown, Java |
| `5` | Highlighted Markdown, C |
| `6` | Highlighted Markdown, C++ |
| `7` | Highlighted Markdown, C# |
| `8` | Highlighted Markdown, Ruby |
| `9` | Highlighted Markdown, Kotlin |
| `10` | Highlighted Markdown, Swift |

Kinds `1`–`10` match `CodeLanguage.all`'s index order exactly (kind `k` corresponds to
`CodeLanguage.all[k-1]`). A language an algorithm doesn't have simply has no content entry for
that kind; the manifest never stores a zero-length placeholder.

**Content section**: the exact concatenation of every entry's UTF-8 bytes, in one fixed order:

| Ordering rule | Detail |
|---|---|
| 1. Algorithm order | Algorithms appear in the same sorted order as their directory records |
| 2. Within one algorithm | The description (kind `0`) comes first, if present |
| 3. Remaining content | Languages follow, sorted by content-kind ID (`1` through `10`) |

All content-entry offsets in the manifest are relative to the start of this section, not to the
start of the file or the decompressed payload.

The `App/Resources/AlgorithmDetails/manage.py pack` command builds this archive in Python, using
the `zstandard` package; see [Managing algorithm content](../guides/algorithm-content.md).
`AlgorithmDetailStore` (`Modules/SortFeature/Sources/`) reads it: an actor singleton that decodes
the archive once per app launch and caches the result. The measured result: roughly 17.36 MB of
loose files compress into one archive of roughly 294 KB (level 19, no dictionary), a reduction of
roughly 98.3%. Measurement showed a trained dictionary would not beat this whole-corpus,
no-dictionary result for this corpus. `ZstdKit` still implements generic dictionary support as a
decoder capability, useful for other, future archives; this archive does not use it.

## Exported `.tape` files: `STAP` / `TAPE`

`Modules/SortEngineKit/Sources/{TapeArchiveEnvelope,TapeArchivePayload,TapeArchiveError,
Tape+Archive}.swift` implement this format. It follows `AlgorithmDetails.algz`'s envelope shape
directly, but drops fields that turned out vestigial there — this format has no dictionary
section, since that archive's dictionary offset and length fields are always zero in practice — and
uses the Swift encoder described above instead of the Python pipeline.

**Outer envelope** (80 bytes, all little-endian, assembled with the same plain shift-loop technique
as `AlgorithmDetails.algz`'s reader, never a typed or aligned load):

| Field | Meaning |
|---|---|
| Magic (8 bytes) | `"STAP\r\n\x1a\n"`, the same text-mode-safety trick as `ALGZ`'s magic |
| Major / minor version (2 + 2 bytes) | Minor is ignored |
| Header length (4 bytes) | |
| Flags (4 bytes) | Must be `0` |
| Codec (2 bytes) | Must be `1`, for zstd |
| Reserved (2 bytes) | Ignored |
| Frame offset (8 bytes) | Always exactly `80`, since no dictionary section exists to offset around |
| Frame length (8 bytes) | |
| Decompressed length (8 bytes) | |
| SHA-256 (32 bytes) | Digest of the decompressed payload |

**Inner payload** (decompressed through `Zstd.decompress`, hash-verified before parsing): a
`"TAPE"` magic (4 bytes), followed by `TapeHeader`'s 13 fields in declaration order, followed by
the `operations` array. Field widths are fixed except where a field is itself variable-length
(a string or an array), never a fixed-max-width record.

`TapeHeader` fields, in order:

| Field | Type on the wire | Meaning |
|---|---|---|
| `algorithmID` | `UInt16` length + UTF-8 bytes | The recorded algorithm's raw ID string |
| `initialValues` | `UInt32` count + that many `Int32` elements | The array's values before the shuffle ran |
| `visualSeed` | `UInt64` | Raw seed for deterministic per-run color choices |
| `compareCount` | `Int32` | ArrayV-parity counter |
| `swapCount` | `Int32` | ArrayV-parity counter |
| `mainWriteCount` | `Int32` | ArrayV-parity counter |
| `auxWriteCount` | `Int32` | ArrayV-parity counter |
| `reversalCount` | `Int32` | ArrayV-parity counter |
| `recordingDuration` | `Double`, raw bit pattern | Wall-clock recording time in seconds |
| `recordedAt` | `Double`, raw bit pattern | Recording timestamp |
| `shuffleID` | 1-byte presence flag, then (if present) `UInt16` length + UTF-8 bytes | `nil` when the tape has no recorded shuffle |
| `sortStartIndex` | `Int32` | Index into `operations` where the sort's own operations begin |
| `uniqueValueCount` | 1-byte presence flag, then (if present) `Int32` | Distinct value count after the shuffle, when known |

`operations`, following the header fields:

| Field | Type on the wire | Meaning |
|---|---|---|
| Operation count | `UInt32` | Number of entries in the array that follows |
| Operations | that many variable-length entries | See the per-operation encoding below |

Each operation encodes as one tag byte, identifying which `SortOperation` case it is, followed by
that case's own `Int32` payload fields:

| Tag | Case | `Int32` fields |
|---:|---|---:|
| `0` | `.swap(Int, Int)` | 2 |
| `1` | `.setValue(Int, Int)` | 2 |
| `2` | `.mark(marker:index:)` | 2 |
| `3` | `.unmark(marker:)` | 1 |
| `4` | `.unmarkAll` | 0 |
| `5` | `.unmarkIndex(marker:index:)` | 2 |
| `6` | `.compare(Int, Int)` | 2 |
| `7` | `.markSorted(Int)` | 1 |
| `8` | `.auxCreate(handle:length:)` | 2 |
| `9` | `.auxWrite(handle:index:value:)` | 3 |
| `10` | `.auxDelete(handle:)` | 1 |
| `11` | `.reversal` | 0 |

Tag values follow `SortOperation`'s declaration order exactly. This table is a direct structural
mirror of the enum; a change to `SortOperation`'s case order or associated values is a breaking
format change.

The app builds and reads this format entirely on-device, through the Swift encoder and decoder.
`Tape.archived()` produces the bytes for `ShareLink`. `Tape(archivedData:)` parses them back into a
plain `Tape` with no opinion about its origin, so nothing downstream needs to distinguish a tape
loaded from a file from one produced by a live recording.

## Shared design principles

Both formats follow the same safety model:

- Every structural check — buffer bounds, integer conversions and arithmetic, allocation sizes,
  manifest self-consistency, checksums, unsupported versions and flags — is a throwing check in
  release builds, never a debug-only `assert`. The overflow-safe range-check pattern used
  throughout is `guard offset <= count; guard length <= count - offset`, never
  `offset + length <= count`, which can silently overflow before the comparison runs.
- Every `UInt64` field converts to `Int` with `Int(exactly:)`, never a truncating cast.
- Unsafe Swift APIs — `withUnsafeBytes`, unaligned loads — are scoped to `ZstdKit`'s internal
  decoder and encoder core. The outer envelope and manifest parsers for both formats use ordinary,
  bounds-checked, safe Swift throughout.
- UTF-8 validation uses the non-repairing `String(validating:as:)`, never `String(decoding:
  as:)`, which silently substitutes replacement characters for invalid bytes. A packing or
  encoding bug produces a loud decode-time error, not silently corrupted content.

## Decoder feature completeness

`ZstdKit`'s decoder supports every normal encoding a standard compressor may produce, not only what
this project's own level-19 encoder emits. This includes:

- The standard frame format: single-segment and windowed frames, every frame-content-size field
  width, content checksums.
- Raw, RLE, and compressed blocks.
- Every literals encoding: raw, RLE, Huffman-compressed, and treeless literals that reuse a
  previous Huffman table, with both one-stream and four-stream Huffman decoding.
- The full sequence-decoding machinery: all three symbol streams in predefined, RLE,
  FSE-compressed, or repeat mode; normalized-count parsing; FSE table construction; the three
  repeat offsets, including the literal-length-zero swap special case.
- Dictionary support, including standard formatted zstd dictionaries with pretrained entropy
  tables and initial repeat offsets, implemented as a generic capability. Neither shipped archive
  format uses it.

The decoder rejects concatenated frames, skippable frames, legacy formats, and magicless framing
with specific unsupported-format errors. It never misclassifies these as generic corruption.

## Performance work

The codebase keeps correctness-first scalar paths as the oracle every optimized routine is checked
against. Three optimizations sit on top of that baseline:

- **Bulk match copying.** `MatchCopier` uses a single append for non-overlapping matches, a plain
  fill for offset-1 matches, and periodic offset-sized chunk tiling for other overlapping offsets,
  copying each chunk into its own independent array first. This replaces one array append per
  matched byte. Appending directly from a slice of the same output array would alias the array's
  own storage into the append call, defeating copy-on-write's uniqueness check and forcing a full
  copy of the buffer so far on every match. This fix alone took decoding the full 17.36 MB
  algorithm-content archive from roughly 37 seconds to roughly 1.5 seconds. The aliasing bug shows
  up only at real content scale; every smaller fixture decoded fine either way.
- **A word-at-a-time bit-reader refill.** `BackwardBitReader` assembles an 8-byte big-endian window
  through a shift-and-mask, active only when at least 7 real bytes remain below the current read
  position. This depth guarantees the original scalar loop, kept unchanged as both the
  near-boundary fallback and the correctness oracle, remains safe.
- **A SIMD row-hash match finder for the encoder** (`RowHashMatchFinder`), a second `MatchFinding`
  conformer alongside the original hash-chain finder. It is not a line-for-line port of real
  zstd's row-hash code, which relies on SSE2/NEON compiler intrinsics this project's
  no-C-interop constraint excludes. Instead it is an original design inspired by the same idea: a
  circular 16-entry tag row per hash bucket, searched by broadcasting a hash tag into a
  `SIMD16<UInt8>` and comparing against the row in one vectorized operation. The compiler lowers
  this comparison to genuine vector instructions on both arm64 and x86_64.

## Feature-complete encoder: lazy matching and parallel encoding

After binary tape export shipped, the encoder's scope grew beyond "sufficient for tape export"
toward a feature-complete Zstandard implementation, on the premise that `ZstdKit` might become
useful as a standalone dependency outside this app. Two additions:

- **Lazy and lazy2 match-finder depth** (`ZstdEncodingOptions.searchDepth`, default `2`), ported
  from real zstd's lazy compression strategy. After finding a baseline candidate, the encoder
  re-searches one position ahead, then, one level deeper, one position further, for as long as the
  new candidate's estimated coding cost beats the one currently held. `searchDepth: 0` preserves
  the original greedy path unchanged.
- **Chunked parallel encoding** (`ZstdEncodingOptions.maximumConcurrency`, default `1`). The one
  genuine cross-block dependency in the encoder is the running repeat-offset state, threaded
  through every block in a frame. Every other component is block-independent. Each parallel chunk
  gets a fresh repeat-offset state and, past the first chunk, a raw-content prefix (the previous
  chunk's tail) fed into the match finder as searchable context, so matches can reference across
  the chunk boundary without re-emitting that content. `Zstd.compress` remains a synchronous,
  non-`async` API: making it `async` would force a real redesign of already-shipped UI code that
  calls it from a SwiftUI view body. Parallel chunks dispatch through GCD's synchronous
  `concurrentPerform`, not Swift concurrency's `TaskGroup`, so the API shape did not need to
  change. The default of `1` reproduces today's exact sequential behavior; no existing caller is
  affected unless it opts in.

## Standalone package

`Modules/ZstdKit/Package.swift` makes the same source tree a self-contained, independently
buildable and testable Swift package, alongside Tuist's own glob-based consumption of it in the
app's `Project.swift`. The two build systems coexist without either reading the other's
configuration. `Package.swift` sets broad platform minimums (iOS 13, macOS 10.15, watchOS 6, tvOS
13), well below what this app requires, since a package intended for other projects should not
inherit this app's newer platform floor. Publishing this package as an externally consumable
dependency, with its own git remote and version tags, is not part of the current scope. The
packaging only makes that step possible later, if `ZstdKit` proves useful enough elsewhere.

## Explicitly out of scope

- Rewriting git history to reclaim space spent on the old, loose `.md` files this archive
  replaced. This is a separate, destructive operation, undertaken only on explicit request.
- Build-time generation of `AlgorithmDetails.algz` from raw source during Xcode Cloud builds. This
  would require Python, Pygments, and the `zstandard` package in the build image, with no benefit
  over the existing manual regeneration workflow.
- A Swift-side dictionary trainer. If a future archive needs a dictionary, training happens in
  Python, using the `zstandard` package's trainer, as an explicit, committed maintenance step.

## Fallback if the pure-Swift decoder had proven infeasible

This fallback was never needed; `ZstdKit` shipped successfully. It is recorded here because the
outer envelope's codec field exists specifically to make a future codec swap explicit, rather than
an undocumented format change. The fallback would have used Apple's `Compression` framework, with
raw DEFLATE per RFC 1951, not the RFC 1950 zlib-wrapped format some tooling expects. Raw DEFLATE's
fixed 32 KB window cannot see redundancy across the whole 17 MB algorithm-content corpus the way
zstd can. The compression ratio would have dropped from a measured 59.7:1 to approximately 26.6:1
— still a large improvement over the original uncompressed size, but a meaningfully smaller one.
