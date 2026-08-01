# ZstdKit and AlgorithmDetails.algz — design reference

Status: implemented and shipped. This documents the design of two things: `ZstdKit`
(`Modules/ZstdKit/`), a from-scratch pure-Swift Zstandard decoder with no C/C++ interop, and
`AlgorithmDetails.algz`, the compressed archive it decodes for `App/Resources/AlgorithmDetails/`'s
content (`AlgorithmDetailStore` in `Modules/SortFeature/Sources/`). Referenced by name from code
comments across both areas — see those files for pointers back into the specific sections below.

## Why this exists

`App/Resources/AlgorithmDetails/` holds every algorithm's description and per-language code
samples: previously ~17.36 MB across 1,180 loose files (108 algorithms × a `description.md` plus up
to 10 per-language highlighted-Markdown files each). The highlighted-Markdown format uses a verbose
`^[text](code: 'Token.X')` syntax `CodeAttributes.swift` parses directly — every space becomes a
30+ byte span, inflating ~12-20x over raw source. That cost twice: ~17 MB shipped in every build,
and thousands of changed text lines in git on every content edit.

Measured compression options (whole 17.36 MB corpus):

| Approach | Total size | Ratio |
|---|---:|---:|
| Whole-corpus, single frame, no dictionary | 290,961 B | 59.7:1 |
| Per-algorithm frames, no dictionary | 570,142 B | 30.5:1 |
| Per-algorithm + 64 KB trained dictionary, best found | 481,108 B | 36.1:1 |

One whole-corpus zstd frame beats every per-algorithm configuration, including
per-algorithm-plus-trained-dictionary, because the whole corpus fits inside zstd's window and the
same token-vocabulary redundancy across all 108 algorithms compresses away for free. Per-algorithm
framing only mattered for git-diff isolation between concurrent contributors, which is moot for a
single-contributor repo — so `AlgorithmDetails.algz` is **one combined archive**, not per-algorithm
files, using **one whole-corpus zstd frame, no dictionary**. `ZstdKit` still implements dictionary
support as a generic decoder capability (useful for other, future archives), but it is not required
by `AlgorithmDetails.algz`.

Accepted tradeoff: every algorithm-content edit now changes the same one binary file (`git diff
--stat` collapses to `Bin XXX -> YYY bytes`), and two branches both touching content can't be
3-way merged — regenerate from the still-tracked source files and recommit is the recovery path.
Fine for a single-contributor repo.

Result: ~17.36 MB → ~294 KB (measured, level 19, no dictionary), a ~98.3% reduction.
`Module.algorithmDetailCopyFiles()`'s 108 generated Tuist `CopyFilesAction`s collapsed into one
resource entry.

## Container format: `ALGZ` / `ADTL`

One file, `App/Resources/AlgorithmDetails/AlgorithmDetails.algz`. All multibyte integers are
**unsigned little-endian**, reconstructed from raw bytes via bounds-checked bit-shift assembly —
never an aligned typed load without a preceding bounds check.

### Outer envelope (outside the zstd frame, 96 bytes fixed)

| Field | Type | Meaning |
|---|---|---|
| Magic | 8 bytes | `41 4C 47 5A 0D 0A 1A 0A` (`ALGZ` + CR LF SUB LF, mirrors PNG's corruption-detecting magic) |
| Major version | `UInt16` | Breaking format version (`1`) |
| Minor version | `UInt16` | Backward-compatible revision |
| Header length | `UInt32` | Total outer-header byte length, including any extension bytes |
| Flags | `UInt32` | Declared optional features (see below) |
| Codec | `UInt16` | `1` = Zstandard |
| Reserved | `UInt16` | Must be zero in v1 |
| Dictionary offset | `UInt64` | Zero when absent (always zero in v1) |
| Dictionary length | `UInt64` | Zero when absent (always zero in v1) |
| Frame offset | `UInt64` | Absolute byte offset of the zstd frame |
| Frame length | `UInt64` | Exact compressed frame length |
| Decompressed length | `UInt64` | Expected complete payload length |
| Payload SHA-256 | 32 bytes | Digest of the full decompressed payload |
| Extension bytes | variable | Skipped per `Header length` |

Flags (v1): bit 0 = embedded dictionary present, bit 1 = dictionary is a standard formatted Zstd
dictionary, bit 2 = payload SHA-256 present and required, all remaining bits reserved. v1 always has
bits 0/1 clear and bit 2 set (`flags == 0x4` exactly); anything else is an unsupported-format error.

### Inner payload header (first bytes of the decompressed zstd output, 56 bytes fixed)

| Field | Type | Meaning |
|---|---|---|
| Payload magic | 8 bytes | `41 44 54 4C 0D 0A 1A 0A` (`ADTL` + CR LF SUB LF) |
| Schema major | `UInt16` | Breaking manifest version |
| Schema minor | `UInt16` | Compatible manifest revision |
| Header length | `UInt32` | Inner header length including extension bytes |
| Flags | `UInt32` | Payload features, reserved in v1 |
| Algorithm count | `UInt32` | Number of directory records — the parser walks exactly this many, never scans to end of buffer |
| Directory offset | `UInt64` | Offset from start of decompressed payload |
| Directory length | `UInt64` | Exact directory length |
| Content offset | `UInt64` | Offset from start of decompressed payload |
| Content length | `UInt64` | Exact concatenated content length |

### Algorithm directory records (12-byte header, back-to-back within the directory range)

| Field | Type | Meaning |
|---|---|---|
| Record length | `UInt32` | Full record length including this header |
| Algorithm ID length | `UInt16` | UTF-8 identifier byte length |
| Entry count | `UInt16` | Number of content entries that follow |
| Algorithm flags | `UInt32` | Reserved, zero in v1 |
| Algorithm ID | variable | Valid UTF-8, e.g. `"quicksort"` |
| Content entries | variable | Fixed-size records, see below |
| Extension bytes | variable | Skipped via `Record length` |

Algorithm IDs are nonempty, valid UTF-8, unique, deterministically sorted by the packer, and
compared as exact byte/string identifiers with no Unicode normalization.

### Content entries (24 bytes fixed, inside each directory record)

| Field | Type | Meaning |
|---|---|---|
| Content kind | `UInt16` | See table below |
| Entry flags | `UInt16` | Bit 0 = required (an unrecognized kind with this set is an error, not a skip); rest reserved |
| Content offset | `UInt64` | Relative to the start of the content section |
| Content length | `UInt64` | Byte length |
| Reserved | `UInt32` | Must be zero in v1 |

Content-kind IDs (stable once v1 shipped): `0` = description Markdown; `1`-`10` = highlighted
Markdown for py/js/go/java/c/cpp/cs/rb/kt/swift respectively, in that fixed order — matching
`DesignSystemKit`'s `CodeLanguage.all` array order exactly (kind `k` → `CodeLanguage.all[k-1]`). A
missing optional language is an **absent** content-entry record, not a zero-length one, preserving
"file doesn't exist for this language" semantics.

### Content section

The exact concatenation of every entry's UTF-8 bytes, in this order: algorithms sorted by stable
algorithm ID, then within each algorithm description first, then languages sorted by stable numeric
content-kind ID. All content-entry offsets are relative to the start of this section. The manifest
(payload header + directory) and the content section must not overlap.

This custom manifest, not tar, is the right call for this fixed, self-contained domain: no ustar
512-byte header blocks, octal ASCII size fields, self-referential checksum, PAX/GNU extensions, or
path-traversal concerns to worry about. The manifest parser (`AlgorithmDetailsEnvelope.swift`/
`AlgorithmDetailsManifest.swift`) is implemented with ordinary bounds-checked safe Swift; unsafe
code is reserved for `ZstdKit`'s optimized decoder core, never this parsing layer.

## UTF-8 handling

Every byte range the manifest describes is guaranteed UTF-8 by construction — `manage.py highlight`
and `description.md` both originate as UTF-8 text, and `manage.py pack` never touches the bytes,
just concatenates and compresses them. Manifest offsets and lengths are **byte** offsets, never
character/Unicode-scalar/`String.Index` values. The Swift loader validates UTF-8 again on load using
the non-repairing initializer (`String(validating: bytes, as: UTF8.self)`), never
`String(decoding:as:)` (which silently substitutes U+FFFD for invalid bytes) — a `manage.py
pack`/Pygments regression should be a loud decode-time error, not a silently corrupted code sample.

## Safety model

Every structural and memory-safety condition is a **throwing check in release builds**, never a
debug-only `assert`/`precondition`:

- Buffer bounds, integer conversions, integer addition/multiplication, allocation sizes, offsets,
  lengths.
- Manifest self-consistency (entry-length sums match total decompressed size, algorithm count
  matches the directory, no overlapping records/content ranges).
- Dictionary fields (checked independently of the flag bits — a corrupted packer run could clear
  the flag while leaving garbage in the offset/length fields), frame/window limits, UTF-8 validity,
  checksums, duplicate algorithm IDs, duplicate content kinds per algorithm, unsupported
  versions/flags.

Overflow-safe range-check pattern, used throughout (never `offset + length <= count` before
separately proving the addition can't overflow):

```swift
guard offset <= buffer.count else { throw Error.outOfBounds }
guard length <= buffer.count - offset else { throw Error.outOfBounds }
```

Every `UInt64` field is converted to `Int` with `Int(exactly:)`, never a truncating cast. Explicit,
configurable resource limits (`ZstdDecodingLimits`) are sized comfortably above the measured
~17.36 MB corpus but low enough to reject absurd/corrupted declarations: `maximumOutputSize`,
`maximumWindowSize`, `maximumDictionarySize`, `maximumBlockCount`, `maximumFrameSize`.

Zero C/C++ interop is a hard requirement. Scoped Swift unsafe APIs (`withUnsafeBytes`/
`withUnsafeMutableBytes`, unaligned loads after explicit bounds checks) are used only:

- Internal to `ZstdKit`'s optimized decoder core — never in the outer `ALGZ`/manifest parser.
- Small and auditable, each documented with the invariant that makes its load/store valid.
- Protected by release-mode range validation before the unsafe access, not after.
- Covered by scalar differential tests.

## `ZstdKit`: pure-Swift Zstd decoder, decode-only

Public API:

```swift
public enum Zstd {
    public static func decompress(
        _ frame: Data,
        using dictionary: ZstdPreparedDictionary? = nil,
        limits: ZstdDecodingLimits = .default
    ) throws -> Data

    public static func prepareDictionary(
        _ dictionary: Data,
        limits: ZstdDecodingLimits = .default
    ) throws -> ZstdPreparedDictionary
}
```

No `compress` API, no encoder stub, no match finder/optimal parser/Huffman encoder/FSE encoder, no
Swift-side dictionary trainer, and none planned — a real zstd encoder's match-finding and
from-scratch entropy-table construction is more work than decoding, and is permanently unnecessary
here since the Python pipeline (`zstandard` PyPI package) already does it well.

**Decoder completeness** — supports every normal encoding a standard compressor may produce, not
just what the project's own level-19 encoder happens to emit:

- **Frame**: standard zstd magic, frame header descriptor, single-segment and windowed frames,
  every frame-content-size field width, window descriptor parsing, dictionary ID fields, content
  checksum flag, reserved-bit validation, configurable maximum output/window sizes. Concatenated
  frames, skippable frames, legacy formats, and magicless framing are rejected with specific
  unsupported-format errors, never misclassified as generic corruption.
- **Block**: raw, RLE, and compressed blocks; reserved block type 3 rejected.
- **Literals**: raw, RLE, Huffman-compressed, and treeless (previous-table-reusing) literals; both
  directly-encoded and FSE-compressed Huffman weights; one-stream and four-stream Huffman literals
  (the four streams decoded as four interleaved independent scalar states in one round-robin loop,
  for instruction-level parallelism, rather than four sequential decodes — `LiteralsSectionDecoder.
  decodeFourStreams`).
- **Sequences**: zero-sequence blocks, all valid sequence-count encodings, the three symbol streams
  (literal lengths, offsets, match lengths) in Predefined/RLE/FSE_Compressed/Repeat mode, normalized-
  count parsing, FSE table construction, baseline+extra-bit tables, the three repeat offsets
  including the literal-length-zero swap special case, cross-block history references, overlapping
  match copies, exact sequence-bitstream termination.
- **Dictionary support** (generic capability, not required by `AlgorithmDetails.algz`): raw-content
  dictionaries, standard formatted zstd dictionaries, dictionary magic/ID, dictionary-provided
  Huffman/LL-FSE/offset-FSE/ML-FSE tables, dictionary-provided initial repeat offsets, dictionary
  history content, frame-dictionary-ID matching. A trained dictionary carries pretrained entropy
  tables and initial repeat offsets, not just raw history bytes prepended to output.
- **Checksum**: XXH64 content checksum, transcribed field-for-field from the reference
  `xxHash`/`zstd` source and verified against real vectors independently via the `xxhsum` CLI before
  wiring it into frame decoding. A checksum mismatch is a release-mode error.

**Performance**: correctness-first scalar paths are kept as the oracle every optimized routine is
checked against.

- **Wildcopy** (`MatchCopier`): bulk match-copy instead of one `Array.append` per byte — a single
  append for nonoverlapping matches, a plain fill for offset 1, and periodic offset-sized chunk
  tiling for other overlapping offsets, each chunk copied into its own independent array first
  (never `output.append(contentsOf: output[someRange])` directly — that aliases `output`'s own
  storage into the append call, defeating copy-on-write's uniqueness check and forcing a full copy
  of the entire buffer so far on every single match).
- **Bit-reader word refill** (`BackwardBitReader`): an 8-byte big-endian window assembled via
  shift+mask, active only when at least 7 real bytes remain below the current read position — deep
  enough that no "ran past the start, pad with zero" case applies, so the original scalar loop
  (kept, unchanged, as both the near-boundary fallback and the correctness oracle) never needed
  touching for this to be safe to add.
- **FSE weight-stream tail loop** (`FSEContainerBitReader`, used only for Huffman weight decoding,
  where the symbol count isn't known in advance): a faithful port of the reference decoder's actual
  `BIT_reloadDStream`/`FSE_decodeSymbol` container semantics — a simplified bit-position heuristic
  was tried first and was wrong (matched one real fixture's tail parity by chance, was short by 2
  symbols on a different weight table elsewhere in the same archive); this port replicates the
  reference's specific termination condition instead of approximating it.
- Accelerate/vDSP is not an architectural dependency — zstd decoding is dominated by variable-width
  bit parsing and irregular lookups, which vDSP doesn't naturally accelerate.

**Error model**:

```swift
public enum ZstdError: Error, Sendable, Equatable {
    case invalidMagic, unsupportedFrameFeature(String), unsupportedWindowSize(requested: Int, limit: Int)
    case frameSizeExceeded(requested: Int, limit: Int), outputLimitExceeded(requested: Int, limit: Int)
    case blockCountExceeded(limit: Int), truncatedInput, invalidFrameHeader, invalidBlockHeader
    case contentSizeMismatch(expected: Int, actual: Int), invalidLiteralsSection, invalidHuffmanTable
    case invalidFSETable, invalidBitstream, invalidSequenceStream, invalidMatchOffset
    case dictionaryRequired(id: UInt32), dictionaryIDMismatch(expected: UInt32, actual: UInt32)
    case checksumMismatch, trailingData
}

enum AlgorithmDetailsArchiveError: Error, Sendable, Equatable {
    case invalidMagic, unsupportedVersion, unsupportedFlags, invalidHeader, invalidSectionRange
    case hashMismatch, invalidManifest, duplicateAlgorithmID, duplicateContentKind
    case overlappingContent, invalidUTF8, missingRequiredContent, archiveResourceNotFound
}
```

## Encoder: Python, not Swift

`App/Resources/AlgorithmDetails/manage.py` (a Click CLI, `scaffold`/`highlight`/`test`/`pack`/
`decode` subcommands) implements `pack` using the `zstandard` PyPI package: one whole-corpus frame,
level 19 unless a fresh benchmark supports another level, no dictionary, content size enabled,
**zstd content checksum enabled** (`write_checksum=True` — required regardless of whether this
specific archive strictly needs it, since a real zstd decoder has to support checksummed frames
anyway; no verification layer is saved by skipping it), deterministic single-threaded compression,
standard frame magic. `manage.py pack` fails before compression if a required description is
missing, a highlighted-Markdown input can't be found or is malformed, any text isn't valid UTF-8, an
ID or content kind is duplicated, or any length exceeds its field width. It self-verifies by default
after writing: read the archive back, verify the outer header and SHA-256, decompress with
`python-zstandard` (which verifies the zstd checksum), parse with a Python reference parser, and
byte-compare every extracted range against its source file. `manage.py decode [name ...]` prints the
parsed envelope/manifest structure for manual inspection.

Reproducibility: the Python version range, `zstandard`/Pygments/other generation dependency
versions, compression level, threading configuration, and format/content-kind version numbers are
all pinned via the checked-in `pyproject.toml`/`uv.lock` pair.

## Runtime: `AlgorithmDetailStore`, a lazily-decoded singleton

```swift
actor AlgorithmDetailStore {
  static let shared = AlgorithmDetailStore()
  private let bundle: Bundle
  private var loadTask: Task<[String: AlgorithmDetailContent], Error>?
  init(bundle: Bundle = .main) { self.bundle = bundle }
  func content(for algorithmID: String) async -> AlgorithmDetailContent? { ... }
}
```

Locates `AlgorithmDetails.algz` via `bundle.url(forResource:withExtension:)`, parses and validates
the outer envelope, decompresses the single zstd frame via `Zstd.decompress`, verifies the zstd
content checksum then the declared decompressed length then the outer SHA-256, parses and validates
the inner manifest, and builds an immutable `[String: AlgorithmDetailContent]` dictionary. `if let
loadTask`/`loadTask = task` both happen before the only suspension point, so concurrent callers
either start the one decode or await the same already-in-flight `Task` — never a duplicate
decompression. `bundle` is injectable (default `.main`) so tests can point it at their own test
bundle instead of `.shared`'s production bundle, mirroring `ZstdKit`'s own `Fixture.bundle =
Bundle(for: FixtureBundleMarker.self)` pattern. `AlgorithmDetailContent.load(for:)` is `async`,
delegating to the store; `AlgorithmDetailSection` loads content in its `.task` block rather than
synchronously in `init`. A fire-and-forget `prewarmAlgorithmDetails()`, called from `Sort2App.init()`,
gives the ~1.5s first-ever decode (measured, full 17.36 MB corpus) a head start before the user
reaches a detail view — decode is cached for the rest of the session after that.

Measured decode-time impact of the performance work above: ~1.95s → ~1.62s for the `ZstdKit`
benchmark corpus before the wildcopy/bit-reader/Huffman-ILP work, and the `MatchCopier` aliasing fix
alone took the full 17.36 MB archive from 37 seconds to ~1.5 seconds (the aliasing bug only shows up
at real-world content scale; every fixture up to a few hundred KB decoded fine either way).

## Git tracking

Tracked: every hand-authored `description.md`, every canonical per-language source file
`manage.py highlight` reads, `manage.py` itself, `pyproject.toml`/`uv.lock`, and the generated
`AlgorithmDetails.algz` itself (a derived build artifact, same as a compiled asset catalog).
Gitignored: the 10 per-algorithm generated highlighted-language `.md` files (`py.md`, `js.md`,
`go.md`, `java.md`, `c.md`, `cpp.md`, `cs.md`, `rb.md`, `kt.md`, `swift.md`) — reproducible
intermediates, never hand-edited, regenerated by `uv run manage.py highlight` from the canonical
source that stays tracked (`App/Resources/AlgorithmDetails/.gitignore`).

To regenerate after editing a `description.md` or canonical source file:

```sh
cd App/Resources/AlgorithmDetails
uv run manage.py highlight && uv run manage.py pack
```

`pack` self-verifies by default; a binary conflict on `AlgorithmDetails.algz` between branches is
resolved by regenerating from the still-tracked sources and recommitting, not by merging the binary.

## Explicitly out of scope

- **Rewriting git history** to reclaim space already spent on the old loose `.md` files — a
  separate, destructive operation, only worth doing on explicit request.
- **Build-time (Xcode Cloud) generation** from raw source — would need Python+Pygments+zstandard in
  the Xcode Cloud image for no benefit over the existing manual-regen workflow.
- **Dictionary support for `AlgorithmDetails.algz` itself** — the measurements above show it
  wouldn't beat the whole-corpus no-dictionary result for this corpus. `ZstdKit`'s generic
  dictionary support (for other, future archives) and this archive's format are independent.
- **A Swift-side dictionary trainer** — if a dictionary is ever wanted for some other archive,
  training happens in Python (`zstandard`'s trainer) as an explicit, committed maintenance step.

## Contingency: if the pure-Swift decoder had proven infeasible

Not needed — `ZstdKit` shipped — but recorded here since the outer envelope's `Codec` field exists
specifically to make this swap explicit rather than an undocumented format change: fall back to
Apple's `Compression` framework (`Data.compressed/decompressed(using: .zlib)`, i.e. raw DEFLATE per
RFC 1951, confirmed via Apple DTS — *not* the RFC 1950 zlib-wrapped format some tooling expects).
`Codec` `2` = DEFLATE; container format, manifest, store, and Tuist wiring otherwise unchanged. Raw
DEFLATE's fixed 32 KB window can't see redundancy across the whole 17 MB corpus the way zstd can, so
ratio would drop from measured 59.7:1 to 26.6:1 (290,961 B vs. 652,881 B) — still a huge win over the
original 17.36 MB, just a meaningfully smaller one.
