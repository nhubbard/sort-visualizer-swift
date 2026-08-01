import Foundation
import Testing

@testable import ZstdKit

/// Known-vector tests, independent of anything Zstd-specific: every vector here was cross-checked
/// against the real `xxhsum` CLI (Homebrew's build of the reference `xxHash` implementation), not
/// just re-derived from the same transcription used to write `XXH64.swift`.
@Suite
struct XXH64Tests {
  @Test func emptyInput() {
    #expect(XXH64.digest([]) == 0xEF46_DB37_51D8_E999)
  }

  @Test func singleByte() {
    #expect(XXH64.digest(Array("a".utf8)) == 0xD24E_C4F1_A98C_6E5B)
  }

  @Test func threeBytes() {
    #expect(XXH64.digest(Array("abc".utf8)) == 0x44BC_2CF5_AD77_0999)
  }

  @Test func fortyThreeBytesSpanningTheMainLoopAndTail() {
    let input = Array("The quick brown fox jumps over the lazy dog".utf8)
    #expect(input.count == 43)
    #expect(XXH64.digest(input) == 0x0B24_2D36_1FDA_71BC)
  }

  @Test func twoHundredFiftySixBytesMultipleMainLoopIterations() {
    let input = (0...255).map { UInt8($0) }
    #expect(XXH64.digest(input) == 0x1FAC_BE84_06CD_904B)
  }

  @Test func fortyBytesExactEightByteFinalizeTail() {
    let input = [UInt8](repeating: 0x41, count: 40)
    #expect(XXH64.digest(input) == 0xD40B_C8B3_932B_7190)
  }

  @Test func checksum32TruncatesToLowBits() {
    let digest = XXH64.digest(Array("abc".utf8))
    #expect(XXH64.checksum32(Array("abc".utf8)) == UInt32(truncatingIfNeeded: digest))
    #expect(XXH64.checksum32(Array("abc".utf8)) == 0xAD77_0999)
  }
}
