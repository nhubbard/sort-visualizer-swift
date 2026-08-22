/// Common interface for this encoder's match finders (`MatchFinder`'s plain hash-chain search,
/// `RowHashMatchFinder`'s SIMD row-hash search) — lets `BlockParser`'s lazy-lookahead driver loop
/// (see `ZSTD_compressBlock_lazy_generic`'s doc comment in `SequenceStore.swift`) be written once,
/// against this protocol, regardless of which concrete finder is active.
protocol MatchFinding {
  init(input: [UInt8], hashLog: Int)

  /// Searches for the best (longest) match at `ip` among up to `maxAttempts` candidates, then
  /// inserts `ip` itself for future searches — every implementation inserts on search
  /// unconditionally, whether or not a match was found or ultimately used, matching real zstd's
  /// own insert-on-search behavior (this is what makes lazy lookahead correct without any special
  /// casing: positions searched-but-not-chosen during lookahead are still in the table for later
  /// searches). Returns `nil` if nothing found meeting `minMatch`.
  mutating func findBestMatch(at ip: Int, minMatch: Int, maxAttempts: Int) -> (position: Int, length: Int)?
}
