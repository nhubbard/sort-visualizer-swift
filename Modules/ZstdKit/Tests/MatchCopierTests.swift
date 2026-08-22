import Testing

@testable import ZstdKit

/// Differential tests: `MatchCopier.copy`'s bulk-copy path must produce byte-identical output to
/// `scalarCopy`'s byte-at-a-time reference loop for every offset/length shape a real sequence
/// stream can produce — nonoverlapping, exactly-at-the-boundary, and every overlapping period.
@Suite
struct MatchCopierTests {
  private func assertMatches(prefix: [UInt8], matchLength: Int, offset: Int) {
    var optimized = prefix
    var scalar = prefix
    let matchStart = optimized.count - offset
    MatchCopier.copy(into: &optimized, matchStart: matchStart, matchLength: matchLength, offset: offset)
    MatchCopier.scalarCopy(into: &scalar, matchStart: matchStart, matchLength: matchLength, offset: offset)
    #expect(
      optimized == scalar,
      "offset=\(offset) matchLength=\(matchLength): optimized \(optimized) != scalar \(scalar)"
    )
  }

  @Test func offsetOneRunLengthFill() {
    assertMatches(prefix: [0xAA], matchLength: 50, offset: 1)
  }

  @Test func nonOverlappingOffsetEqualsMatchLength() {
    assertMatches(prefix: (0..<10).map(UInt8.init), matchLength: 4, offset: 4)
  }

  @Test func nonOverlappingOffsetGreaterThanMatchLength() {
    assertMatches(prefix: (0..<10).map(UInt8.init), matchLength: 3, offset: 7)
  }

  @Test func overlappingOffsetTwoEvenMultiple() {
    assertMatches(prefix: [1, 2], matchLength: 10, offset: 2)
  }

  @Test func overlappingOffsetTwoWithRemainder() {
    assertMatches(prefix: [1, 2], matchLength: 11, offset: 2)
  }

  @Test func overlappingOffsetFour() {
    assertMatches(prefix: [1, 2, 3, 4], matchLength: 17, offset: 4)
  }

  @Test func overlappingOffsetEight() {
    assertMatches(prefix: (1...8).map(UInt8.init), matchLength: 33, offset: 8)
  }

  @Test func overlappingOddOffsetThree() {
    assertMatches(prefix: [9, 8, 7], matchLength: 22, offset: 3)
  }

  @Test func overlappingOddOffsetFive() {
    assertMatches(prefix: [5, 4, 3, 2, 1], matchLength: 47, offset: 5)
  }

  @Test func overlappingOffsetOneLessThanMatchLength() {
    assertMatches(prefix: (0..<9).map(UInt8.init), matchLength: 10, offset: 9)
  }

  @Test func matchLengthOfOne() {
    assertMatches(prefix: [42, 7, 3], matchLength: 1, offset: 3)
  }

  @Test func exhaustiveSmallOffsetsAndLengths() {
    for offset in 1...16 {
      for matchLength in 1...40 {
        let prefix = (0..<offset).map { UInt8($0 &+ 1) }
        assertMatches(prefix: prefix, matchLength: matchLength, offset: offset)
      }
    }
  }
}
