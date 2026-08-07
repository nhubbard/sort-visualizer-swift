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

  public init(
    hashLog: Int = 17,
    maximumSearchAttempts: Int = 32,
    minimumMatchLength: Int = 4,
    searchDepth: Int = 2,
    checksum: Bool = true,
    maximumInputSize: Int = 1 << 30
  ) {
    self.hashLog = hashLog
    self.maximumSearchAttempts = maximumSearchAttempts
    self.minimumMatchLength = minimumMatchLength
    self.searchDepth = searchDepth
    self.checksum = checksum
    self.maximumInputSize = maximumInputSize
  }

  public static let `default` = ZstdEncodingOptions()
}
