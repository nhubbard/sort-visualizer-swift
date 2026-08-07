/// Direct knobs for the encoder, rather than reproducing real zstd's 22-level parameter table —
/// this encoder implements one strategy (`greedy`, see `COMPRESSION_DESIGN.md`), so one well-tuned
/// default is enough; nobody asked for 22 levels.
public struct ZstdEncodingOptions: Sendable, Equatable {
  /// `1 << hashLog` entries in the match finder's hash table.
  public var hashLog: Int
  /// How many chained candidates `MatchFinder` will examine per position before giving up and
  /// emitting a literal.
  public var maximumSearchAttempts: Int
  /// Minimum match length the hash function is built around (4 bytes — `MatchFinder`'s hash reads
  /// a 4-byte little-endian window per position, matching the reference's `mls` floor for the
  /// greedy/lazy family).
  public var minimumMatchLength: Int
  /// How many extra lookahead rounds `BlockParser.parse` tries beyond the initial greedy match at
  /// `ip`, mirroring real zstd's `lazy`/`lazy2` strategies (`ZSTD_compressBlock_lazy_generic`'s
  /// `depth` parameter) — `0` is plain greedy (this encoder's original Phase 1 behavior, unchanged
  /// bit-for-bit at this setting), `1` is `lazy` (one extra round at `ip+1`), `2` is `lazy2` (a
  /// second nested round at `ip+2`). Defaults to `2`: real zstd uses `lazy2` at its well-tested
  /// default compression levels (8-12 of 22), not the cheapest option.
  public var searchDepth: Int
  /// Whether to append the 4-byte XXH64 content checksum trailer.
  public var checksum: Bool
  /// Sanity ceiling — this encoder holds the whole input in memory (no streaming), so there's no
  /// architectural reason to refuse a larger input beyond "did the caller mean to do this."
  public var maximumInputSize: Int
  /// How many chunks `FrameEncoder.encode` may compress concurrently via
  /// `DispatchQueue.concurrentPerform`, mirroring (in spirit, not mechanism — see
  /// `COMPRESSION_DESIGN.md`) real zstd's multithreaded mode's per-job structure: each chunk gets
  /// its own fresh `EncodeRepeatOffsets` (matching real zstdmt's per-job reset) and, past the
  /// first chunk, a raw-content "prefix" loaded from the previous chunk's tail so matches can
  /// still reference across the boundary. Defaults to `1` — today's exact sequential behavior,
  /// byte-for-byte, so every existing caller is unaffected unless they opt in explicitly.
  public var maximumConcurrency: Int
  /// Use `RowHashMatchFinder` (a `SIMD16<UInt8>`-based row-hash search) instead of `MatchFinder`
  /// (plain hash-chain search) — see `COMPRESSION_DESIGN.md` for why this is an original design
  /// inspired by, not transcribed from, real zstd's own row-hash matcher. Defaults to `true`:
  /// `RowHashMatchFinderTests` (self round-trip + a real `zstandard`-oracle cross-check on the
  /// exact corpus `EncoderRoundTripTests` exercises for the plain hash-chain finder) is green, so
  /// both finders produce spec-valid, interchangeable output — this is purely a speed/dispatch
  /// choice, not a compatibility one. Set `false` to force the plain hash-chain finder instead.
  public var useRowHashMatchFinder: Bool

  public init(
    hashLog: Int = 17,
    maximumSearchAttempts: Int = 32,
    minimumMatchLength: Int = 4,
    searchDepth: Int = 2,
    checksum: Bool = true,
    maximumInputSize: Int = 1 << 30,
    maximumConcurrency: Int = 1,
    useRowHashMatchFinder: Bool = true
  ) {
    self.hashLog = hashLog
    self.maximumSearchAttempts = maximumSearchAttempts
    self.minimumMatchLength = minimumMatchLength
    self.searchDepth = searchDepth
    self.checksum = checksum
    self.maximumInputSize = maximumInputSize
    self.maximumConcurrency = maximumConcurrency
    self.useRowHashMatchFinder = useRowHashMatchFinder
  }

  public static let `default` = ZstdEncodingOptions()
}
