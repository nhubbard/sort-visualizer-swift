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
}
