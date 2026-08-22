import Testing

@testable import ZstdKit

/// A pure bit-at-a-time reimplementation of `BackwardBitReader`'s original algorithm (before the
/// word-refill fast path), kept only as this test's correctness oracle — every `count` here is
/// bounded the same way, but there is no fast path to go wrong.
private struct ScalarBackwardBitReader {
  private let bytes: [UInt8]
  private var bytePosition: Int
  private var bitPosition: Int

  init(_ bytes: [UInt8]) {
    self.bytes = bytes
    self.bytePosition = bytes.count - 1
    let last = bytes[bytePosition]
    var sentinelBit = 7
    while (last & (1 << sentinelBit)) == 0 { sentinelBit -= 1 }
    self.bitPosition = sentinelBit - 1
  }

  var hasBitsRemaining: Bool {
    bytePosition > 0 || bitPosition >= 0
  }

  mutating func readBits(_ count: Int) -> UInt32 {
    guard count > 0 else { return 0 }
    var result: UInt32 = 0
    var remaining = count
    while remaining > 0 {
      if bitPosition < 0 {
        bytePosition -= 1
        guard bytePosition >= 0 else {
          return result << UInt32(remaining)
        }
        bitPosition = 7
      }
      let bit = (bytes[bytePosition] >> bitPosition) & 1
      result = (result << 1) | UInt32(bit)
      bitPosition -= 1
      remaining -= 1
    }
    return result
  }
}

/// Differential tests for `BackwardBitReader`'s word-refill fast path against the scalar
/// bit-at-a-time oracle above. This is the exact area that hid a real bug once (the FSE
/// weight-decode tail loop, fixed in `HuffmanTable.swift`) so coverage here is deliberately
/// systematic: several buffer sizes, several fixed read-count sequences (including ones designed
/// to walk the fast-path/scalar-path boundary at `bytePosition == 7` repeatedly), read until the
/// stream is exhausted, and cross-check every single call plus `hasBitsRemaining` at every step —
/// not just the final decoded value.
@Suite
struct BackwardBitReaderTests {
  /// Deterministic, non-zero-heavy filler so every byte plausibly contributes to the fast path's
  /// window assembly (an all-zero buffer would still be legal but wouldn't exercise much).
  private func makeBuffer(count: Int) -> [UInt8] {
    var bytes = (0..<count).map { UInt8(truncatingIfNeeded: $0 &* 37 &+ 11) }
    if bytes[bytes.count - 1] == 0 { bytes[bytes.count - 1] = 0x80 }
    return bytes
  }

  private func assertMatchesOracle(bufferSize: Int, readCounts: [Int]) throws {
    let bytes = makeBuffer(count: bufferSize)
    var optimized = try BackwardBitReader(bytes)
    var oracle = ScalarBackwardBitReader(bytes)

    var callIndex = 0
    while oracle.hasBitsRemaining {
      #expect(
        optimized.hasBitsRemaining == oracle.hasBitsRemaining,
        "bufferSize=\(bufferSize) callIndex=\(callIndex): hasBitsRemaining disagreement"
      )
      let count = readCounts[callIndex % readCounts.count]
      let optimizedValue = optimized.readBits(count)
      let oracleValue = oracle.readBits(count)
      #expect(
        optimizedValue == oracleValue,
        "bufferSize=\(bufferSize) callIndex=\(callIndex) count=\(count): optimized=\(optimizedValue) oracle=\(oracleValue)"
      )
      callIndex += 1
      // Guard against an infinite loop if a real mismatch ever desyncs termination.
      #expect(callIndex < bufferSize * 8 + 64)
      if callIndex >= bufferSize * 8 + 64 { break }
    }
  }

  private static let bufferSizes = [1, 2, 6, 7, 8, 9, 15, 16, 17, 32, 63, 64, 65, 100, 257]
  private static let readCountPatterns: [[Int]] = [
    [1],
    [7],
    [8],
    [9],
    [16],
    [32],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 32],
    [31, 3, 1, 17, 9],
    [5, 5, 5, 5, 5]
  ]

  @Test func differentialAcrossBufferSizesAndReadPatterns() throws {
    for bufferSize in Self.bufferSizes {
      for pattern in Self.readCountPatterns {
        try assertMatchesOracle(bufferSize: bufferSize, readCounts: pattern)
      }
    }
  }

  @Test func peekBitsDoesNotConsume() throws {
    let bytes = makeBuffer(count: 32)
    var reader = try BackwardBitReader(bytes)
    let peeked = reader.peekBits(9)
    let read = reader.readBits(9)
    #expect(peeked == read)
    // The peek must not have advanced `reader` — reading two more 9-bit chunks from it should
    // match a fresh reader's second and third reads, not its third and fourth.
    let next = reader.readBits(9)
    var control = try BackwardBitReader(bytes)
    let controlFirst = control.readBits(9)
    let controlSecond = control.readBits(9)
    #expect(controlFirst == read)
    #expect(controlSecond == next)
  }

  @Test func fastPathBoundaryExactlySevenBytesRemaining() throws {
    // `bytePosition == 7` is the exact threshold where the fast path stops applying — walk right
    // across it with single-bit reads to make sure the two paths hand off cleanly.
    try assertMatchesOracle(bufferSize: 20, readCounts: [1])
  }
}
