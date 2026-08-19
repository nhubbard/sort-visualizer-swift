/// A second `MatchFinding` conformer, inspired by (not transcribed from) real zstd's row-based
/// match finder (`ZSTD_row_getMatchMask`, `zstd_lazy.c`) — real zstd's own "genuine SIMD" only
/// exists via SSE2/NEON *compiler intrinsics*, which this project's no-C-interop constraint rules
/// out, and its portable fallback (used when neither intrinsic is available) is itself a wide-
/// scalar SWAR bit-gather trick on a `size_t`, not a vector type at all. So there is no reference
/// implementation of "row-hash matching via a portable, non-intrinsic SIMD type" to port line for
/// line; this design (Swift's `SIMD16<UInt8>` `.==` compare + `.replacing(where:)` select, which
/// the compiler genuinely lowers to vector instructions on both arm64/NEON and x86_64/SSE) captures
/// the same underlying idea — broadcast-compare a hash tag against many candidates in one op — with
/// an original layout. See Documentation/docs/reference/compression.md.
final class RowHashMatchFinder: MatchFinding {
  private static let rowWidth = 16

  private let input: [UInt8]
  private let hashLog: Int
  private let rowMask: Int
  private var tags: [UInt8]
  private var positions: [Int32]
  private var rowHead: [UInt8]
  private var nextToInsert = 0

  init(input: [UInt8], hashLog: Int) {
    self.input = input
    self.hashLog = hashLog
    self.rowMask = (1 << hashLog) - 1
    let slotCount = (1 << hashLog) * Self.rowWidth
    self.tags = [UInt8](repeating: 0, count: slotCount)
    self.positions = [Int32](repeating: -1, count: slotCount)
    self.rowHead = [UInt8](repeating: 0, count: 1 << hashLog)
  }

  /// The same multiplicative Fibonacci hash `MatchFinder.hash(at:)` uses, computed at `hashLog + 8`
  /// bits instead of just `hashLog` — the extra 8 low bits become the row's tag (real zstd's
  /// `ZSTD_ROW_HASH_TAG_BITS`), the remaining `hashLog` bits select which row. One hash, not two
  /// independent ones.
  private func hashAndTag(at position: Int) -> (row: Int, tag: UInt8) {
    let value =
      UInt32(input[position]) | (UInt32(input[position + 1]) << 8) | (UInt32(input[position + 2]) << 16)
      | (UInt32(input[position + 3]) << 24)
    let hashed = (value &* 2_654_435_761) >> (32 - (hashLog + 8))
    let row = Int(hashed >> 8) & rowMask
    let tag = UInt8(truncatingIfNeeded: hashed)
    return (row, tag)
  }

  /// Each row is a plain circular buffer of `rowWidth` slots with its own head cursor in
  /// `rowHead` — deliberately simpler than real zstd's in-row head-pointer trick (which exists for
  /// C cache-locality reasons that don't apply the same way here): no reserved slot-0 sentinel,
  /// since the head pointer lives in its own array instead of being packed into the tag row.
  private func insert(_ position: Int) {
    guard position + 4 <= input.count else { return }
    let (row, tag) = hashAndTag(at: position)
    let slot = row * Self.rowWidth + Int(rowHead[row])
    tags[slot] = tag
    positions[slot] = Int32(position)
    rowHead[row] = (rowHead[row] &+ 1) & UInt8(Self.rowWidth - 1)
  }

  private func insertUpTo(_ position: Int) {
    while nextToInsert < position {
      insert(nextToInsert)
      nextToInsert += 1
    }
  }

  /// The "genuine SIMD" step: broadcast `tag` across a `SIMD16<UInt8>` and compare against the
  /// row's 16 tag bytes in one vectorized op, then a vector select (`.replacing(with:where:)`)
  /// turning matched lanes into `1`s — both real, compiler-lowered vector operations, no
  /// intrinsics or `import simd` needed (`SIMDn` has shipped in the standard library since Swift
  /// 5.0). Only the final "which of these 16 lanes is set" reduction falls back to a small,
  /// fixed-16-iteration scalar loop building a `UInt16` bitmask — deliberately not replicating
  /// real zstd's SWAR magic-multiply bit-gather trick (exactly the kind of subtle, easy-to-get-
  /// silently-wrong bit arithmetic `BackwardBitWriter`'s real Phase 1 bug already cost real
  /// debugging time on) — the value proposition (one vector compare instead of 16 sequential
  /// branchy ones) is already captured without it.
  private func matchMask(forRow row: Int, tag: UInt8) -> UInt16 {
    let base = row * Self.rowWidth
    let rowTags = SIMD16<UInt8>(tags[base..<(base + Self.rowWidth)])
    let tagVector = SIMD16<UInt8>(repeating: tag)
    let equal = rowTags .== tagVector
    let selected = SIMD16<UInt8>.zero.replacing(with: SIMD16<UInt8>(repeating: 1), where: equal)
    var mask: UInt16 = 0
    for lane in 0..<Self.rowWidth where selected[lane] == 1 {
      mask |= UInt16(1) << lane
    }
    return mask
  }

  func findBestMatch(at ip: Int, minMatch: Int, maxAttempts: Int) -> (position: Int, length: Int)? {
    defer {
      insert(ip)
      nextToInsert = max(nextToInsert, ip + 1)
    }
    guard ip + 4 <= input.count else { return nil }
    insertUpTo(ip)

    let (row, tag) = hashAndTag(at: ip)
    var mask = matchMask(forRow: row, tag: tag)
    let base = row * Self.rowWidth
    var attempts = 0
    var bestLength = 0
    var bestPosition = -1
    // `mask &= mask - 1` clears the lowest set bit each round — the same `ZSTD_VecMask_next`
    // iteration idiom real zstd uses, a direct, safe port (unlike the mask's own construction
    // above).
    while mask != 0, attempts < maxAttempts {
      let lane = mask.trailingZeroBitCount
      mask &= mask - 1
      let candidate = Int(positions[base + lane])
      guard candidate >= 0, candidate < ip else { continue }
      let length = wideWordMatchLength(in: input, ip, candidate)
      if length > bestLength {
        bestLength = length
        bestPosition = candidate
      }
      attempts += 1
    }
    guard bestLength >= minMatch else { return nil }
    return (bestPosition, bestLength)
  }
}
