import Foundation
import AlgorithmKit
import SortEngineKit

public struct SmartGuessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "smartguesssort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Smart Guess Sort", bundle: .module),
    category: .impractical,
    sizeRange: 4...8,
    growthModel: OperationGrowthModel(
      anchorSize: 8, coefficients: [69143.1, 89999.5, 60400.2, 27715.5, 9747.18, 2795.05],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .nToTheNLike, coefficients: [61.0868, 0.422688], rSquared: 0.99677),
    implementationComplexity: 12,
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
      let increasing = engine.compare(loops[i], loops[i + 1], by: (<))
      engine.annotateLastOperation(
        stageID: "candidateCheck", decisionID: "smartguesssort.strictOrder",
        outcome: increasing ? "acceptPair" : "checkTie",
        roles: ["left": .arrayIndex(loops[i]), "right": .arrayIndex(loops[i + 1])],
        explanationKey: "smartguesssort.strictOrder",
        explanation: increasing
          ? String(localized: "This mapped pair increases, so the candidate suffix remains valid.", bundle: .module)
          : String(localized: "This mapped pair does not increase, so check whether its values tie.", bundle: .module))
      if increasing { return true }
      let equal = engine.compare(loops[i], loops[i + 1], by: (==))
      let stableTie = equal && loops[i] < loops[i + 1]
      engine.annotateLastOperation(
        stageID: "candidateCheck", decisionID: "smartguesssort.stableTie",
        outcome: stableTie ? "acceptPair" : "rejectCandidate",
        roles: ["left": .arrayIndex(loops[i]), "right": .arrayIndex(loops[i + 1])],
        explanationKey: "smartguesssort.stableTie",
        explanation: stableTie
          ? String(localized: "Equal values retain their source order, so this suffix pair is valid.", bundle: .module)
          : String(localized: "This pair is descending or breaks stable tie order, so advance the candidate mapping.", bundle: .module))
      return stableTie
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

    let mapped = loops.map { engine.readValue(at: $0) }
    for i in 0..<n {
      engine.setValue(i, mapped[i])
      engine.annotateLastOperation(
        stageID: "candidatePlacement", decisionID: "smartguesssort.candidatePlacement",
        outcome: "place", roles: ["destination": .arrayIndex(i)],
        explanationKey: "smartguesssort.candidatePlacement",
        explanation: String(localized: "This candidate permutation satisfies the ordering check and is placed here.", bundle: .module))
    }
  }
}
