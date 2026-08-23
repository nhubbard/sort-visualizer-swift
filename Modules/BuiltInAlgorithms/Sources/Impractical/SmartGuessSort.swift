import AlgorithmKit
import SortEngineKit

public struct SmartGuessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "smartguesssort")
  public let metadata = AlgorithmMetadata(
    displayName: "Smart Guess Sort",
    category: .impractical,
    sizeRange: 4...8,
    growthModel: OperationGrowthModel(
      anchorSize: 8, coefficients: [69216.4, 90169.4, 60562.7, 27811.9, 9788.65, 2809.08],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .nToTheNLike, coefficients: [60.7972, 0.423037], rSquared: 0.996733),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^n)", worst: "O(n^n)"),
    spaceComplexity: "O(n)",
    iconName: "questionmark.circle"
  )
  public init() {}

  /// Already fully deterministic in ArrayV. Same base-`n` odometer as `OptimizedGuessSort`, but
  /// the validity check scans adjacent pairs from the END toward the start, and — the "smart"
  /// part — once it finds the first (rightmost, scanning backward) failing pair at position `i`,
  /// the next odometer step only resets positions `0..<i` to zero and increments starting from
  /// `i`, instead of always restarting the increment from position 0. This skips re-trying
  /// digit combinations that share the same already-confirmed-good suffix, which is what lets
  /// this variant tolerate a much larger `sizeRange` than the plain odometer.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var loops = [Int](repeating: 0, count: n)

    func isPairOK(_ i: Int) -> Bool {
      if engine.compare(loops[i], loops[i + 1], by: (<)) { return true }
      if engine.compare(loops[i], loops[i + 1], by: (==)), loops[i] < loops[i + 1] { return true }
      return false
    }

    /// -1 once every adjacent pair is OK; otherwise the position of the first pair (scanning
    /// from the end) that fails — everything after `i + 1` is already a verified-good suffix.
    func firstFailureScanningBackward() -> Int {
      var i = n - 2
      while i >= 0, isPairOK(i) {
        i -= 1
      }
      return i
    }

    while true {
      let i = firstFailureScanningBackward()
      if i < 0 { break }
      for pos in 0..<n {
        if pos >= i, loops[pos] < n - 1 {
          loops[pos] += 1
          break
        } else {
          loops[pos] = 0
        }
      }
    }

    let mapped = loops.map { engine.values[$0] }
    for i in 0..<n {
      engine.setValue(i, mapped[i])
    }
  }
}
