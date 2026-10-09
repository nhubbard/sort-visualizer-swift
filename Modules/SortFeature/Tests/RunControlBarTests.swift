import Testing

@testable import SortFeature

@Suite
struct RunControlBarTests {
  @Test
  func zeroElapsedDurationReturnsZeroInsteadOfDividingByZero() {
    #expect(opsPerSecond(significantOperationCount: 500, elapsedPlaybackDuration: 0) == 0)
  }

  @Test
  func positiveElapsedDurationDividesOperationCountByIt() {
    #expect(
      opsPerSecond(significantOperationCount: 100, elapsedPlaybackDuration: 2) == 50)
  }

  @Test
  func manualStepDescriptionsDistinguishPositionsFromValues() {
    #expect(accessibilityDescription(for: .swap(0, 3)) == "Swapped positions 1 and 4")
    #expect(accessibilityDescription(for: .setValue(2, 17)) == "Set position 3 to 17")
    #expect(
      accessibilityDescription(for: .compareValues(4, 9)) == "Compared values 4 and 9")
  }
}
